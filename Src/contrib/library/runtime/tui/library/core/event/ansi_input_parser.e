note
	description: "[
		Escape sequence parser and state machine.
		Translates raw input bytes into strongly-typed EVENT objects
		(Keys, Modifiers, Function keys, SGR 1006 mouse, Focus, and Bracketed Paste).
		Includes UTF-8 streaming decoder, bounded parameter buffer, and lone ESC timeout handling.
		The decoder is strict (Unicode 16.0 section 3.9, table 3-7): overlong forms, surrogates,
		values above U+10FFFF, stray continuation bytes and invalid lead bytes never reach the
		state machine; each maximal ill-formed subsequence becomes one U+FFFD, as UTF_CONVERTER
		and most terminals do. So no byte sequence other than 1B decodes to ESC.
		Pasted text is collected in a buffer of fewer than `max_paste_size` characters: a longer
		paste is delivered as several PASTE_EVENTs (see {PASTE_EVENT}.is_continued).
		OSC replies (P2b K2): `ESC ] <digits> ;` starts an operating system command, which
		ends on BEL or on `ESC \` (ST; the 8-bit ST 9C is not used, it is a UTF-8 continuation
		byte). The clipboard reply `52 ; <selection> ; <base64>` becomes a CLIPBOARD_EVENT;
		every other OSC (colour reports, hyperlink echoes, ...) is dropped without an event.
		No byte of an OSC becomes a key. Until the `;` after the number, the sequence may
		still be Alt+`]` followed by typed keys: a character that is not a digit (or a `;`
		right after `ESC ]`), or the lone-ESC timeout (`flush_escape`), emits Alt+`]` and
		processes the collected digits and that character again as keys. Accepted risk: a
		person who types `52;` after Alt+`]` faster than the escape timeout starts an OSC.
		Inside an OSC, an ESC not followed by `\` ends it without an event and starts a new
		sequence, and CAN (18) or SUB (1A) ends it without an event and is then a key
		(Ctrl+X, Ctrl+Z), so that a cut-off reply does not swallow what follows. An OSC whose
		end has not arrived after `paste_timeout_ms` of silence is dropped (`notify_idle`).
		The OSC 52 data kept is at most `max_osc_size` characters: a longer reply is followed
		to its end and gives `Status_too_large`. Inside a bracketed paste, `ESC ]` is text.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	ANSI_INPUT_PARSER

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize parser in ground state.
		do
			create events.make (16)
			create param_buffer.make (32)
			create paste_buffer.make (Initial_paste_capacity)
			state := State_ground
			utf8_codepoint := 0
			utf8_expected_bytes := 0
			is_in_paste := False
			paste_timeout_ms := Default_paste_timeout_ms
			max_paste_size := Default_max_paste_size
			max_osc_size := Default_max_paste_size
			create osc_buffer.make (Initial_osc_capacity)
			osc_selection := Default_selection
		ensure
			state_ground: state = State_ground
			events_empty: events.is_empty
			default_paste_timeout: paste_timeout_ms = Default_paste_timeout_ms
			default_max_paste_size: max_paste_size = Default_max_paste_size
			default_max_osc_size: max_osc_size = Default_max_paste_size
		end

feature -- Access

	events: ARRAYED_LIST [EVENT]
			-- Accumulated parsed events

	is_in_paste: BOOLEAN
			-- Is bracketed paste currently being accumulated?

	is_between_sequences: BOOLEAN
			-- Is no escape sequence or UTF-8 character part-way through?
		do
			Result := state = State_ground and utf8_expected_bytes = 0
		end

	paste_timeout_ms: INTEGER
			-- Input silence after which a bracketed paste whose end marker never arrived is
			-- ended anyway (see `notify_idle`)

	Default_paste_timeout_ms: INTEGER = 2000
			-- Default `paste_timeout_ms`

	max_paste_size: INTEGER
			-- Number of characters at which the pasted text collected so far is delivered as a
			-- PASTE_EVENT with `is_continued` set, and collecting starts again in a new buffer

	Default_max_paste_size: INTEGER = 1_048_576
			-- Default `max_paste_size` (4 MB of STRING_32), and of `max_osc_size`

	max_osc_size: INTEGER
			-- Most characters of OSC 52 data (the base64 text) kept for one reply: a longer
			-- reply is followed to its end and gives a CLIPBOARD_EVENT with `Status_too_large`

	is_in_osc: BOOLEAN
			-- Is an OSC (`ESC ] <digits> ;` seen) waiting for its end, BEL or `ESC \`?
		do
			Result := state = State_osc or state = State_osc_escape
		ensure
			not_between_sequences: Result implies not is_between_sequences
		end

	osc_data_count: INTEGER
			-- Number of characters of OSC 52 data kept so far for the reply being read
		do
			Result := osc_buffer.count
		ensure
			bounded: Result <= max_osc_size
		end

feature -- Settings

	set_paste_timeout (a_ms: INTEGER)
			-- Set `paste_timeout_ms` to `a_ms`.
		require
			positive_ms: a_ms > 0
		do
			paste_timeout_ms := a_ms
		ensure
			set: paste_timeout_ms = a_ms
		end

	set_max_paste_size (a_size: INTEGER)
			-- Set `max_paste_size` to `a_size`.
		require
			positive_size: a_size > 0
			not_in_paste: not is_in_paste
		do
			max_paste_size := a_size
		ensure
			set: max_paste_size = a_size
		end

	set_max_osc_size (a_size: INTEGER)
			-- Set `max_osc_size` to `a_size`.
		require
			positive_size: a_size > 0
			not_in_osc: not is_in_osc
		do
			max_osc_size := a_size
		ensure
			set: max_osc_size = a_size
		end

feature -- Operations

	parse_string (a_string: READABLE_STRING_GENERAL)
			-- Parse characters in `a_string`.
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > a_string.count
			loop
				parse_code (a_string.code (i))
				i := i + 1
			end
		end

	parse_code (a_code: NATURAL_32)
			-- Process one input byte (0..255) through the UTF-8 stream decoder. A code above 255
			-- is taken as an already decoded character (U+FFFD if it is not a scalar value).
			-- An ill-formed byte sequence is replaced by U+FFFD, one per maximal subpart: the
			-- bytes of an unfinished sequence give one U+FFFD, and the byte that broke it is
			-- decoded again.
		do
			if a_code > 0xFF then
				if utf8_expected_bytes > 0 then
					replace_utf_8_subpart
				end
				process_byte ({UNICODE_SCALAR}.scalar_value (a_code))
			elseif utf8_expected_bytes = 0 then
				if a_code <= 0x7F then
					process_byte (a_code)
				elseif a_code >= 0xC2 and a_code <= 0xDF then
					start_utf_8_sequence (a_code & 0x1F, 1, 0x80, 0xBF)
				elseif a_code = 0xE0 then
					-- E0 80..9F would be an overlong form of U+0000..U+07FF
					start_utf_8_sequence (a_code & 0x0F, 2, 0xA0, 0xBF)
				elseif a_code = 0xED then
					-- ED A0..BF would be a surrogate, U+D800..U+DFFF
					start_utf_8_sequence (a_code & 0x0F, 2, 0x80, 0x9F)
				elseif a_code >= 0xE1 and a_code <= 0xEF then
					start_utf_8_sequence (a_code & 0x0F, 2, 0x80, 0xBF)
				elseif a_code = 0xF0 then
					-- F0 80..8F would be an overlong form of U+0000..U+FFFF
					start_utf_8_sequence (a_code & 0x07, 3, 0x90, 0xBF)
				elseif a_code = 0xF4 then
					-- F4 90..BF would be above U+10FFFF
					start_utf_8_sequence (a_code & 0x07, 3, 0x80, 0x8F)
				elseif a_code >= 0xF1 and a_code <= 0xF3 then
					start_utf_8_sequence (a_code & 0x07, 3, 0x80, 0xBF)
				else
					-- A continuation byte without a lead (80..BF), or a byte that never occurs
					-- in UTF-8 (C0, C1, F5..FF)
					process_byte ({UNICODE_SCALAR}.Replacement_character)
				end
			elseif a_code >= utf8_next_min and a_code <= utf8_next_max then
				utf8_codepoint := (utf8_codepoint |<< 6) | (a_code & 0x3F)
				utf8_expected_bytes := utf8_expected_bytes - 1
				utf8_next_min := 0x80
				utf8_next_max := 0xBF
				if utf8_expected_bytes = 0 then
					process_byte (utf8_codepoint)
				end
			else
				-- The sequence is broken: replace what was read of it, then decode the current
				-- byte again, which may be ASCII or the lead byte of a new sequence.
				replace_utf_8_subpart
				parse_code (a_code)
			end
		ensure
			sequence_state: utf8_expected_bytes >= 0 and utf8_expected_bytes <= 3
		end

	flush_escape
			-- Flush pending Escape if timeout elapsed without subsequent sequence bytes, and
			-- replace an unfinished UTF-8 sequence by U+FFFD. `ESC ]` with digits and no `;`
			-- yet becomes Alt+`]` and the digits as keys; a committed OSC is kept.
			-- Inside a bracketed paste nothing is flushed: a pending sequence is either the
			-- paste end marker cut by a pause in the input or literal pasted text (a character
			-- split by the pause, for UTF-8), and both are completed by the bytes still to come.
		do
			if not is_in_paste then
				if utf8_expected_bytes > 0 then
					replace_utf_8_subpart
				end
				if state = State_escape then
					events.extend (create {KEY_EVENT}.make_special ({KEY_CODE}.escape))
					state := State_ground
				elseif state = State_csi or state = State_csi_param or state = State_ss3 or state = State_sgr_mouse then
					state := State_ground
					param_buffer.wipe_out
				elseif state = State_osc_number then
					-- `ESC ]` and digits without their `;`: Alt+`]` and typed digits
					end_osc_number_as_keys
				end
				-- A committed OSC (`is_in_osc`) waits for its end: the bytes of a reply may come
				-- in several reads. `notify_idle` drops it after `paste_timeout_ms`.
			end
		ensure
			osc_kept: old is_in_osc implies is_in_osc
		end

	notify_idle (a_idle_ms: INTEGER)
			-- No input has arrived for `a_idle_ms` milliseconds: flush a pending lone ESC, and
			-- end a bracketed paste whose end marker has not arrived within `paste_timeout_ms`,
			-- delivering the text collected so far (an unfinished escape sequence is dropped, an
			-- unfinished UTF-8 sequence becomes U+FFFD). An OSC whose end has not arrived within
			-- `paste_timeout_ms` is dropped without an event.
		require
			non_negative_idle: a_idle_ms >= 0
		do
			if is_in_osc and a_idle_ms >= paste_timeout_ms then
				-- A reply cut off: drop it, with a UTF-8 character it left unfinished, so
				-- that what is typed next is read from the ground state
				utf8_expected_bytes := 0
				drop_osc
			end
			if is_in_paste and a_idle_ms >= paste_timeout_ms then
				if utf8_expected_bytes > 0 and state = State_ground then
					replace_utf_8_subpart
				end
				deliver_paste (False)
				param_buffer.wipe_out
				is_in_paste := False
				state := State_ground
				utf8_expected_bytes := 0
			end
			flush_escape
		ensure
			paste_ended: (old is_in_paste and a_idle_ms >= paste_timeout_ms) implies not is_in_paste
			osc_dropped: a_idle_ms >= paste_timeout_ms implies not is_in_osc
		end

	wipe_out
			-- Clear accumulated events.
		do
			events.wipe_out
		ensure
			empty: events.is_empty
		end

	discard_pending
			-- Drop the escape sequence or UTF-8 character in progress and the events collected
			-- so far, after an exception left them in an unknown state. A bracketed paste goes
			-- on (the text collected so far is kept). Does not allocate, so it is safe in a
			-- rescue clause.
		do
			state := State_ground
			param_buffer.wipe_out
			utf8_codepoint := 0
			utf8_expected_bytes := 0
			osc_buffer.wipe_out
			osc_is_clipboard_reply := False
			osc_is_too_large := False
			events.wipe_out
		ensure
			between_sequences: is_between_sequences
			no_events: events.is_empty
			paste_kept: is_in_paste = old is_in_paste
		end

feature {NONE} -- State Processors

	process_byte (a_code: NATURAL_32)
			-- Process decoded Unicode code point through state machine.
		do
			if is_in_paste and state = State_ground and a_code /= 27 then
				append_to_paste (a_code.to_character_32)
			else
				inspect state
				when State_ground then
					process_ground (a_code)
				when State_escape then
					process_escape (a_code)
				when State_csi then
					process_csi (a_code)
				when State_csi_param then
					process_csi_param (a_code)
				when State_ss3 then
					process_ss3 (a_code)
				when State_sgr_mouse then
					process_sgr_mouse (a_code)
				when State_osc_number then
					process_osc_number (a_code)
				when State_osc then
					process_osc (a_code)
				when State_osc_escape then
					process_osc_escape (a_code)
				end
			end
		end

	process_ground (a_code: NATURAL_32)
			-- Process character in ground state.
		do
			if a_code = 27 then
				param_buffer.wipe_out
				state := State_escape
			else
				emit_key (a_code, False)
			end
		end

	emit_key (a_code: NATURAL_32; a_alt: BOOLEAN)
			-- Emit the key event for non-ESC character `a_code`, with Alt held if `a_alt`.
		require
			not_escape: a_code /= 27
		local
			l_code: KEY_CODE
			l_mod: MODIFIERS
		do
			create l_mod.default_create
			l_mod.set_alt (a_alt)
			if a_code = 13 then
				l_code := {KEY_CODE}.enter
			elseif a_code = 10 then
					-- Line feed: Ctrl+J, and Ctrl+Enter on Windows Terminal (Enter sends a carriage return).
				l_code := {KEY_CODE}.enter
				l_mod.set_control (True)
			elseif a_code = 9 then
				l_code := {KEY_CODE}.tab
			elseif a_code = 8 or a_code = 127 then
				l_code := {KEY_CODE}.backspace
			elseif a_code >= 1 and a_code <= 26 then
				-- Ctrl+A .. Ctrl+Z
				l_mod.set_control (True)
				create l_code.make_char ((a_code + 96).to_character_32)
			else
				create l_code.make_char (a_code.to_character_32)
			end
			events.extend (create {KEY_EVENT}.make (l_code, l_mod))
		end

	process_escape (a_code: NATURAL_32)
			-- Process character following ESC.
		do
			if a_code = 91 then -- '[' -> CSI
				param_buffer.wipe_out
				state := State_csi
			elseif a_code = 79 then -- 'O' -> SS3 (F1..F4)
				state := State_ss3
			elseif is_in_paste and a_code = 27 then
				-- The first ESC was pasted text; the second may start the end marker
				abandon_sequence_to_paste ("")
				state := State_escape
			elseif is_in_paste then
				append_to_paste ((27).to_character_32)
				append_to_paste (a_code.to_character_32)
				state := State_ground
			elseif a_code = 27 then
				-- ESC ESC: the first one is a plain Escape, the second may start a sequence
				events.extend (create {KEY_EVENT}.make_special ({KEY_CODE}.escape))
			elseif a_code = 93 then
				-- ']': an OSC reply if digits and ';' follow, otherwise Alt+']'
				param_buffer.wipe_out
				state := State_osc_number
			else
				-- ESC followed by a character is how terminals encode Alt+character
				state := State_ground
				emit_key (a_code, True)
			end
		end

	process_csi (a_code: NATURAL_32)
			-- Process first character after `\e[`.
		do
			if is_in_paste and a_code = 27 then
				abandon_sequence_to_paste ("[")
				state := State_escape
			elseif a_code = 60 then -- '<' -> SGR Mouse
				param_buffer.wipe_out
				state := State_sgr_mouse
			elseif (a_code >= 48 and a_code <= 58) or a_code = 59 or a_code = 63 then
				-- Digits '0'..'9', ':', ';', or '?'
				param_buffer.append_character (a_code.to_character_32)
				state := State_csi_param
			else
				dispatch_csi_command (a_code, "")
				state := State_ground
			end
		end

	process_csi_param (a_code: NATURAL_32)
			-- Process parameter characters until final command letter.
		do
			if is_in_paste and (a_code = 27 or param_buffer.count >= Max_param_count) then
				-- Pasted text that only looked like a sequence: keep it, and let an ESC
				-- start a new sequence (possibly the end marker)
				abandon_sequence_to_paste ("[")
				process_byte (a_code)
			elseif (a_code >= 48 and a_code <= 58) or a_code = 59 or a_code = 63 then
				if param_buffer.count < Max_param_count then
					param_buffer.append_character (a_code.to_character_32)
				end
			else
				dispatch_csi_command (a_code, param_buffer)
				state := State_ground
			end
		end

	process_osc_number (a_code: NATURAL_32)
			-- Process a character after `ESC ]` and the digits collected in `param_buffer`:
			-- a digit continues the number, `;` after at least one digit commits to an OSC,
			-- anything else makes it Alt+`]` and typed keys, then is processed again.
		require
			outside_paste: not is_in_paste
		do
			if a_code >= 48 and a_code <= 57 and param_buffer.count < Max_param_count then
				param_buffer.append_character (a_code.to_character_32)
			elseif a_code = 59 and not param_buffer.is_empty then
				begin_osc
			else
				end_osc_number_as_keys
				process_byte (a_code)
			end
		end

	process_osc (a_code: NATURAL_32)
			-- Process a character of a committed OSC.
		require
			outside_paste: not is_in_paste
		do
			if a_code = 7 then
				-- BEL ends it
				finish_osc
			elseif a_code = 27 then
				-- Maybe the start of ST (`ESC \`)
				state := State_osc_escape
			elseif a_code = 24 or a_code = 26 then
				-- CAN or SUB cancels it (ECMA-48). No terminal puts them in a reply, so they
				-- were typed: a key
				drop_osc
				process_byte (a_code)
			elseif osc_is_clipboard_reply then
				if osc_field = Field_selection then
					if a_code = 59 then
						osc_field := Field_data
					elseif not osc_is_selection_seen then
						osc_selection := a_code.to_character_32
						osc_is_selection_seen := True
					end
				else
					append_osc_data (a_code)
				end
			end
			-- Characters of other OSCs are dropped as they come
		end

	process_osc_escape (a_code: NATURAL_32)
			-- Process the character after an ESC inside a committed OSC: `\` ends the OSC;
			-- anything else drops it and continues as the character after a new ESC.
		require
			outside_paste: not is_in_paste
		do
			if a_code = 92 then
				finish_osc
			else
				drop_osc
				state := State_escape
				process_escape (a_code)
			end
		end

	process_ss3 (a_code: NATURAL_32)
			-- Process SS3 key sequence (`\eOP`..`\eOS` -> F1..F4).
		do
			if is_in_paste and a_code = 27 then
				abandon_sequence_to_paste ("O")
				state := State_escape
			elseif is_in_paste then
				append_to_paste ((27).to_character_32)
				append_to_paste ('O')
				append_to_paste (a_code.to_character_32)
				state := State_ground
			else
				emit_ss3_key (a_code)
			end
		end

	emit_ss3_key (a_code: NATURAL_32)
			-- Emit the key for SS3 final character `a_code`.
		local
			l_evt: KEY_EVENT
		do
			inspect a_code
			when 80 then create l_evt.make (create {KEY_CODE}.make_function (1), create {MODIFIERS}.default_create)
			when 81 then create l_evt.make (create {KEY_CODE}.make_function (2), create {MODIFIERS}.default_create)
			when 82 then create l_evt.make (create {KEY_CODE}.make_function (3), create {MODIFIERS}.default_create)
			when 83 then create l_evt.make (create {KEY_CODE}.make_function (4), create {MODIFIERS}.default_create)
			else
				create l_evt.make_special ({KEY_CODE}.escape)
			end
			events.extend (l_evt)
			state := State_ground
		end

	process_sgr_mouse (a_code: NATURAL_32)
			-- Process SGR 1006 mouse: `\e[<b;col;rowM` or `m`.
		local
			l_parts: LIST [STRING_32]
			l_btn, l_col, l_row: INTEGER
			l_kind: NATURAL_8
			l_mod: MODIFIERS
			l_evt: MOUSE_EVENT
		do
			if is_in_paste and not ((a_code >= 48 and a_code <= 57) or a_code = 59 or a_code = 77 or a_code = 109)
				or is_in_paste and param_buffer.count >= Max_param_count
			then
				-- Pasted text that is not a mouse report: keep it, and let an ESC start a new
				-- sequence (possibly the end marker)
				abandon_sequence_to_paste ("[<")
				process_byte (a_code)
			elseif (a_code = 77 or a_code = 109) and is_in_paste then
				-- Inside a bracketed paste this is literal text
				append_to_paste ((27).to_character_32)
				append_string_to_paste ("[<")
				append_string_to_paste (param_buffer)
				append_to_paste (a_code.to_character_32)
				state := State_ground
			elseif a_code = 77 or a_code = 109 then -- 'M' (press) or 'm' (release)
				l_parts := param_buffer.split (';')
				if l_parts.count >= 3 and then l_parts.i_th (1).is_integer and then l_parts.i_th (2).is_integer and then l_parts.i_th (3).is_integer then
					l_btn := l_parts.i_th (1).to_integer
					-- Clamped like the cursor position report: `to_natural_16` below requires it
					l_col := (l_parts.i_th (2).to_integer - 1).max (0).min (65535)
					l_row := (l_parts.i_th (3).to_integer - 1).max (0).min (65535)

					create l_mod.default_create
					if (l_btn & 4) /= 0 then
						l_mod.set_shift (True)
					end
					if (l_btn & 8) /= 0 then
						l_mod.set_alt (True)
					end
					if (l_btn & 16) /= 0 then
						l_mod.set_control (True)
					end

					if (l_btn & 32) /= 0 and (l_btn & 64) = 0 and (l_btn & 3) = 3 then
						-- Motion with no button (mode 1003): crossterm's `Moved`, also with a
						-- final `m` (crossterm turns only a press into a release). The button
						-- is `Button_none` (the low bits, 3).
						l_kind := {MOUSE_EVENT}.kind_move
					elseif a_code = 109 then
						l_kind := {MOUSE_EVENT}.kind_up
					elseif (l_btn & 32) /= 0 then
						-- Motion with a button held (modes 1002 and 1003)
						l_kind := {MOUSE_EVENT}.kind_drag
					elseif (l_btn & 64) /= 0 then
						inspect l_btn & 3
						when 0 then l_kind := {MOUSE_EVENT}.kind_scroll_up
						when 1 then l_kind := {MOUSE_EVENT}.kind_scroll_down
						when 2 then l_kind := {MOUSE_EVENT}.kind_scroll_left
						when 3 then l_kind := {MOUSE_EVENT}.kind_scroll_right
						else l_kind := {MOUSE_EVENT}.kind_scroll_up
						end
					else
						l_kind := {MOUSE_EVENT}.kind_down
					end

					create l_evt.make (l_kind, (l_btn & 3).to_natural_8, l_col.to_natural_16, l_row.to_natural_16, l_mod)
					events.extend (l_evt)
				end
				state := State_ground
			else
				if param_buffer.count < Max_param_count then
					param_buffer.append_character (a_code.to_character_32)
				end
			end
		end

	dispatch_csi_command (a_cmd: NATURAL_32; a_params: READABLE_STRING_GENERAL)
			-- Translate CSI final command character and parameter string into events.
		local
			l_mod: MODIFIERS
			l_parts: LIST [READABLE_STRING_GENERAL]
			l_mod_subparts: LIST [READABLE_STRING_GENERAL]
			l_mask: INTEGER
			l_kind: NATURAL_8
		do
			create l_mod.default_create
			l_kind := {KEY_EVENT}.Kind_press
			l_parts := a_params.split (';')

			-- Parse modifier parameter if present (e.g. 1;5C -> Ctrl, or 1;5:3C -> Ctrl Release).
			-- xterm encodes it as 1 + bitmask (1 Shift, 2 Alt, 4 Ctrl, 8 Super/Meta).
			-- Kitty progressive enhancement appends `:event_type` (1 Press, 2 Repeat, 3 Release).
			if l_parts.count >= 2 then
				l_mod_subparts := l_parts.i_th (2).split (':')
				if not l_mod_subparts.is_empty and then l_mod_subparts.i_th (1).is_integer then
					l_mask := l_mod_subparts.i_th (1).to_integer - 1
					if l_mask > 0 then
						l_mod.set_shift ((l_mask & 1) /= 0)
						l_mod.set_alt ((l_mask & 2) /= 0)
						l_mod.set_control ((l_mask & 4) /= 0)
						l_mod.set_super ((l_mask & 8) /= 0)
					end
				end
				if l_mod_subparts.count >= 2 and then l_mod_subparts.i_th (2).is_integer then
					inspect l_mod_subparts.i_th (2).to_integer
					when 1 then l_kind := {KEY_EVENT}.Kind_press
					when 2 then l_kind := {KEY_EVENT}.Kind_repeat
					when 3 then l_kind := {KEY_EVENT}.Kind_release
					else l_kind := {KEY_EVENT}.Kind_press
					end
				end
			end

			if is_in_paste and not (a_cmd = 126 and a_params.same_string ("201")) then
				-- Inside a bracketed paste every sequence except the end marker is pasted text
				append_to_paste ((27).to_character_32)
				append_to_paste ('[')
				append_string_to_paste (a_params)
				append_to_paste (a_cmd.to_character_32)
			elseif a_cmd = 82 and l_parts.count = 2 and then (l_parts.i_th (1).is_integer and l_parts.i_th (2).is_integer) then
				-- 'R' with row;col is a cursor position report (answer to DSR ESC[6n).
				-- Like crossterm, this takes precedence over the ambiguous modified F3 (ESC[1;<m>R).
				-- When an event-type is present (e.g. ESC[1;2:1R), l_parts.i_th (2).is_integer is
				-- False due to the colon, so it cleanly dispatches as modified F3!
				events.extend (create {CURSOR_POSITION_EVENT}.make (
					(l_parts.i_th (1).to_integer - 1).max (0).min (65535).to_natural_16,
					(l_parts.i_th (2).to_integer - 1).max (0).min (65535).to_natural_16))
			elseif (a_cmd = 117 or a_cmd = 99) and then (not a_params.is_empty and then a_params.code (1) = 63) then
				-- A reply with the private marker '?': 'u' is the Kitty flags reply (answer to
				-- ESC [ ? u), 'c' the primary device attributes (answer to DA1 ESC [ c).
				-- Neither is a key (P2 T4)
				dispatch_private_reply (a_cmd, a_params.substring (2, a_params.count))
			elseif a_cmd = 117 then
				-- 'u' -> Kitty keyboard protocol key event: ESC [ key-code ; modifiers : event-type u
				dispatch_kitty_key (l_parts, l_mod, l_kind)
			else
				dispatch_csi_key (a_cmd, l_parts, l_mod, l_kind)
			end
		end

	dispatch_private_reply (a_cmd: NATURAL_32; a_params: READABLE_STRING_GENERAL)
			-- Translate the terminal reply `ESC [ ? a_params a_cmd` (`a_params` without the '?').
			-- 'u': KEYBOARD_FLAGS_EVENT when `a_params` is one number 0 .. 255, otherwise no
			-- event (as before T4). 'c': DEVICE_ATTRIBUTES_EVENT with the numbers separated by
			-- ';', a part that is empty or not a decimal number counting as 0, so that any
			-- DA1 reply still ends a keyboard support query.
		require
			reply_command: a_cmd = 117 or a_cmd = 99
		local
			l_list: ARRAYED_LIST [INTEGER]
			l_value: INTEGER
		do
			if a_cmd = 117 then
				if a_params.is_natural_8 then
					events.extend (create {KEYBOARD_FLAGS_EVENT}.make (a_params.to_natural_8))
				end
			else
				create l_list.make (4)
				if not a_params.is_empty then
					across a_params.split (';') as p loop
						l_value := 0
						if p.is_integer then
							l_value := p.to_integer.max (0)
						end
						l_list.extend (l_value)
					end
				end
				events.extend (create {DEVICE_ATTRIBUTES_EVENT}.make (l_list))
			end
		end

	dispatch_csi_key (a_cmd: NATURAL_32; l_parts: LIST [READABLE_STRING_GENERAL]; l_mod: MODIFIERS; a_kind: NATURAL_8)
			-- Translate CSI final command `a_cmd` with split parameters `l_parts` into key/focus/paste events.
		local
			l_evt: KEY_EVENT
			l_code: detachable KEY_CODE
		do
			inspect a_cmd
			when 65 then l_code := {KEY_CODE}.up -- 'A'
			when 66 then l_code := {KEY_CODE}.down -- 'B'
			when 67 then l_code := {KEY_CODE}.right -- 'C'
			when 68 then l_code := {KEY_CODE}.left -- 'D'
			when 72 then l_code := {KEY_CODE}.home -- 'H'
			when 70 then l_code := {KEY_CODE}.end_key -- 'F'
			when 90 then l_code := {KEY_CODE}.back_tab -- 'Z' (Shift+Tab)
			when 73 then -- 'I' -> Focus gained
				events.extend (create {FOCUS_EVENT}.make_gained)
			when 79 then -- 'O' -> Focus lost
				events.extend (create {FOCUS_EVENT}.make_lost)
			when 80 then -- 'P' -> F1
				create l_code.make_function (1)
			when 81 then -- 'Q' -> F2
				create l_code.make_function (2)
			when 82 then -- 'R' -> F3
				create l_code.make_function (3)
			when 83 then -- 'S' -> F4
				create l_code.make_function (4)
			when 126 then -- '~' (tilde keys)
				if not l_parts.is_empty and then l_parts.i_th (1).is_integer then
					inspect l_parts.i_th (1).to_integer
					when 1 then l_code := {KEY_CODE}.home
					when 2 then l_code := {KEY_CODE}.insert
					when 3 then l_code := {KEY_CODE}.delete
					when 4 then l_code := {KEY_CODE}.end_key
					when 5 then l_code := {KEY_CODE}.page_up
					when 6 then l_code := {KEY_CODE}.page_down
					when 7 then l_code := {KEY_CODE}.home -- rxvt / Kitty alternative form
					when 8 then l_code := {KEY_CODE}.end_key
					when 11 then create l_code.make_function (1)
					when 12 then create l_code.make_function (2)
					when 13 then create l_code.make_function (3) -- Kitty's unambiguous F3
					when 14 then create l_code.make_function (4)
					when 15 then create l_code.make_function (5)
					when 17 then create l_code.make_function (6)
					when 18 then create l_code.make_function (7)
					when 19 then create l_code.make_function (8)
					when 20 then create l_code.make_function (9)
					when 21 then create l_code.make_function (10)
					when 23 then create l_code.make_function (11)
					when 24 then create l_code.make_function (12)
					when 200 then -- Bracketed paste start
						is_in_paste := True
						paste_buffer.wipe_out
					when 201 then -- Bracketed paste end
						-- Outside a paste (e.g. after `notify_idle` ended it) the marker is ignored
						if is_in_paste then
							is_in_paste := False
							deliver_paste (False)
						end
					else
					end
				end
			else
			end

			if l_code /= Void then
				create l_evt.make_with_kind (l_code, l_mod, a_kind)
				events.extend (l_evt)
			end
		end

	dispatch_kitty_key (l_parts: LIST [READABLE_STRING_GENERAL]; l_mod: MODIFIERS; a_kind: NATURAL_8)
			-- Translate a Kitty keyboard protocol key (`CSI key[:alternates] ; mods[:event] ; text u`)
			-- into a key event. `l_mod` and `a_kind` were decoded from the second field by the caller;
			-- alternate keys after the first `:` and associated text are ignored.
			-- Codes follow the Kitty specification: 27 Esc, 13 Enter, 9 Tab, 127 Backspace,
			-- 57376..57398 F13..F35, 57399..57427 the keypad; lock, media and modifier keys (other
			-- private-use codes) produce no event.
		local
			l_first: READABLE_STRING_GENERAL
			l_cp: INTEGER
			l_code: detachable KEY_CODE
		do
			if not l_parts.is_empty then
				l_first := l_parts.i_th (1)
				if l_first.has (':') then
					l_first := l_first.substring (1, l_first.index_of (':', 1) - 1)
				end
				if l_first.is_integer then
					l_cp := l_first.to_integer
				end
				inspect l_cp
				when 27 then l_code := {KEY_CODE}.escape
				when 13, 57414 then l_code := {KEY_CODE}.enter -- 57414 KP_ENTER
				when 9 then l_code := {KEY_CODE}.tab
				when 8, 127 then l_code := {KEY_CODE}.backspace
				when 57376 .. 57398 then create l_code.make_function ((l_cp - 57376 + 13).to_natural_8)
				when 57399 .. 57408 then create l_code.make_char ((48 + l_cp - 57399).to_natural_32.to_character_32) -- KP_0..KP_9
				when 57409 then create l_code.make_char ('.')
				when 57410 then create l_code.make_char ('/')
				when 57411 then create l_code.make_char ('*')
				when 57412 then create l_code.make_char ('-')
				when 57413 then create l_code.make_char ('+')
				when 57415 then create l_code.make_char ('=')
				when 57416 then create l_code.make_char (',')
				when 57417 then l_code := {KEY_CODE}.left
				when 57418 then l_code := {KEY_CODE}.right
				when 57419 then l_code := {KEY_CODE}.up
				when 57420 then l_code := {KEY_CODE}.down
				when 57421 then l_code := {KEY_CODE}.page_up
				when 57422 then l_code := {KEY_CODE}.page_down
				when 57423 then l_code := {KEY_CODE}.home
				when 57424 then l_code := {KEY_CODE}.end_key
				when 57425 then l_code := {KEY_CODE}.insert
				when 57426 then l_code := {KEY_CODE}.delete
				else
					-- Printable code points; Kitty's private-use keys (57344..63743) and invalid
					-- code points produce no event.
					if l_cp >= 32 and l_cp <= 0x10FFFF and not (l_cp >= 0xD800 and l_cp <= 0xDFFF)
						and not (l_cp >= 57344 and l_cp <= 63743)
					then
						create l_code.make_char (l_cp.to_natural_32.to_character_32)
					end
				end
				if l_code /= Void then
					events.extend (create {KEY_EVENT}.make_with_kind (l_code, l_mod, a_kind))
				end
			end
		end

feature {NONE} -- Implementation

	end_osc_number_as_keys
			-- `ESC ]` and the digits in `param_buffer` were not an OSC: emit Alt+`]`, then each
			-- digit as a typed key, and return to the ground state.
		require
			outside_paste: not is_in_paste
		local
			i: INTEGER
		do
			state := State_ground
			emit_key (93, True)
			from
				i := 1
			until
				i > param_buffer.count
			loop
				emit_key (param_buffer.code (i), False)
				i := i + 1
			end
			param_buffer.wipe_out
		ensure
			ground: state = State_ground
			keys_added: events.count = old events.count + old param_buffer.count + 1
		end

	begin_osc
			-- `ESC ] <digits> ;` read, digits in `param_buffer`: start reading the OSC's text.
		require
			number_read: state = State_osc_number and not param_buffer.is_empty
		do
			-- Compared as a number, as xterm does ("052" is 52); a number too long for an
			-- INTEGER is not 52
			osc_is_clipboard_reply := param_buffer.is_integer and then param_buffer.to_integer = 52
			param_buffer.wipe_out
			osc_field := Field_selection
			osc_selection := Default_selection
			osc_is_selection_seen := False
			osc_is_too_large := False
			osc_buffer.wipe_out
			state := State_osc
		ensure
			in_osc: is_in_osc
			no_data: osc_buffer.is_empty
		end

	append_osc_data (a_code: NATURAL_32)
			-- Keep `a_code` as the next character of the OSC 52 data, up to `max_osc_size`.
			-- A character outside ASCII is kept as `*`, which is not base64.
		do
			if osc_is_too_large then
				-- Followed to the end, not kept
			elseif osc_buffer.count >= max_osc_size then
				osc_is_too_large := True
				create osc_buffer.make (Initial_osc_capacity)
			else
				if osc_buffer.count = osc_buffer.capacity then
					-- Grow by doubling, never past the cap
					osc_buffer.resize ((osc_buffer.capacity * 2).min (max_osc_size).max (osc_buffer.count + 1))
				end
				if a_code <= 127 then
					osc_buffer.append_character (a_code.to_character_8)
				else
					osc_buffer.append_character ('*')
				end
			end
		ensure
			bounded: osc_buffer.count <= max_osc_size
		end

	finish_osc
			-- The OSC ended (BEL or ST): emit the CLIPBOARD_EVENT of an OSC 52 reply, and
			-- return to the ground state.
		require
			in_osc: is_in_osc
		local
			l_event: CLIPBOARD_EVENT
		do
			if osc_is_clipboard_reply then
				if osc_is_too_large then
					create l_event.make (osc_selection, {CLIPBOARD_EVENT}.Status_too_large)
				elseif osc_field = Field_selection then
					-- `52 ; <selection>` without a data field
					create l_event.make (osc_selection, {CLIPBOARD_EVENT}.Status_invalid)
				elseif osc_buffer.is_empty or osc_buffer.same_string ("?") then
					-- An empty clipboard, or the query echoed back
					create l_event.make_owned_text (osc_selection, create {STRING_32}.make_empty)
				elseif {BASE64}.is_valid_encoding (osc_buffer) then
					create l_event.make_owned_text (osc_selection, {BASE64}.decoded_utf_8 (osc_buffer))
				else
					create l_event.make (osc_selection, {CLIPBOARD_EVENT}.Status_invalid)
				end
				events.extend (l_event)
			end
			drop_osc
		ensure
			ground: state = State_ground
			one_event_per_reply: events.count = old events.count + (if old osc_is_clipboard_reply then 1 else 0 end)
		end

	drop_osc
			-- End the OSC being read without an event, release its data and return to the
			-- ground state.
		do
			if osc_buffer.capacity > Initial_osc_capacity then
				create osc_buffer.make (Initial_osc_capacity)
			else
				osc_buffer.wipe_out
			end
			osc_is_clipboard_reply := False
			osc_is_too_large := False
			param_buffer.wipe_out
			state := State_ground
		ensure
			ground: state = State_ground
			no_data: osc_buffer.is_empty
		end

	abandon_sequence_to_paste (a_introducer: STRING_32)
			-- Append the unfinished sequence (ESC, `a_introducer`, collected parameters) to the
			-- paste text and return to the ground state.
		require
			in_paste: is_in_paste
		do
			append_to_paste ((27).to_character_32)
			append_string_to_paste (a_introducer)
			append_string_to_paste (param_buffer)
			param_buffer.wipe_out
			state := State_ground
		ensure
			ground: state = State_ground
			still_in_paste: is_in_paste
		end

	append_to_paste (a_char: CHARACTER_32)
			-- Add `a_char` to the paste text; deliver the text as a continued PASTE_EVENT
			-- once it holds `max_paste_size` characters.
		require
			in_paste: is_in_paste
		do
			paste_buffer.append_character (a_char)
			if paste_buffer.count >= max_paste_size then
				deliver_paste (True)
			end
		ensure
			still_in_paste: is_in_paste
		end

	append_string_to_paste (a_string: READABLE_STRING_GENERAL)
			-- Add `a_string` to the paste text, one character at a time (see `append_to_paste`).
		require
			in_paste: is_in_paste
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > a_string.count
			loop
				append_to_paste (a_string [i])
				i := i + 1
			end
		ensure
			still_in_paste: is_in_paste
		end

	deliver_paste (a_continued: BOOLEAN)
			-- Hand the paste text over to a new PASTE_EVENT (continued if `a_continued`) and
			-- collect further text in a new small buffer, so the memory of a large paste is
			-- released with its event instead of staying with the parser.
		do
			events.extend (create {PASTE_EVENT}.make_owned (paste_buffer, a_continued))
			create paste_buffer.make (Initial_paste_capacity)
		ensure
			event_added: events.count = old events.count + 1
			buffer_empty: paste_buffer.is_empty
			buffer_replaced: paste_buffer /= old paste_buffer
		end

	Initial_paste_capacity: INTEGER = 64
			-- Initial capacity of a new paste buffer

	Max_param_count: INTEGER = 64
			-- Longest parameter string kept for a CSI or SGR mouse sequence

	State_ground: INTEGER = 0
	State_escape: INTEGER = 1
	State_csi: INTEGER = 2
	State_csi_param: INTEGER = 3
	State_ss3: INTEGER = 4
	State_sgr_mouse: INTEGER = 5
	State_osc_number: INTEGER = 6
			-- After `ESC ]`: digits until `;` commit to an OSC (`param_buffer` holds them)
	State_osc: INTEGER = 7
			-- Inside a committed OSC, until BEL or `ESC \`
	State_osc_escape: INTEGER = 8
			-- Inside a committed OSC, right after an ESC

	osc_buffer: STRING_8
			-- OSC 52 data (base64) of the reply being read, at most `max_osc_size` characters

	osc_is_clipboard_reply: BOOLEAN
			-- Is the OSC being read number 52 (its text is kept)?

	osc_field: INTEGER
			-- Field of an OSC 52 reply being read: `Field_selection` or `Field_data`

	Field_selection: INTEGER = 1
	Field_data: INTEGER = 2

	osc_selection: CHARACTER_32
			-- First character of the selection field of the OSC 52 reply being read

	osc_is_selection_seen: BOOLEAN
			-- Has the selection field had a character?

	osc_is_too_large: BOOLEAN
			-- Did the OSC 52 data pass `max_osc_size` (its data dropped)?

	Default_selection: CHARACTER_32 = 'c'
			-- Selection of a reply whose selection field is empty

	Initial_osc_capacity: INTEGER = 64
			-- Initial capacity of `osc_buffer`

	state: INTEGER
	param_buffer: STRING_32
	paste_buffer: STRING_32

	utf8_codepoint: NATURAL_32
			-- Bits of the UTF-8 sequence being decoded

	utf8_expected_bytes: INTEGER
			-- Continuation bytes still needed by the UTF-8 sequence being decoded (0: none pending)

	utf8_next_min, utf8_next_max: NATURAL_32
			-- Range of the next continuation byte: narrower than 80..BF right after the lead
			-- bytes E0, ED, F0 and F4, which rules out overlongs, surrogates and > U+10FFFF

	start_utf_8_sequence (a_bits: NATURAL_32; a_count: INTEGER; a_min, a_max: NATURAL_32)
			-- Start a sequence whose lead byte gave `a_bits` and that needs `a_count` continuation
			-- bytes, the first one in `a_min`..`a_max`.
		require
			valid_count: a_count >= 1 and a_count <= 3
			valid_range: 0x80 <= a_min and a_min <= a_max and a_max <= 0xBF
		do
			utf8_codepoint := a_bits
			utf8_expected_bytes := a_count
			utf8_next_min := a_min
			utf8_next_max := a_max
		ensure
			pending: utf8_expected_bytes = a_count
		end

	replace_utf_8_subpart
			-- Drop the unfinished UTF-8 sequence and process U+FFFD in its place.
		require
			pending: utf8_expected_bytes > 0
		do
			utf8_expected_bytes := 0
			process_byte ({UNICODE_SCALAR}.Replacement_character)
		ensure
			none_pending: utf8_expected_bytes = 0
		end

invariant
	utf_8_sequence_state: utf8_expected_bytes >= 0 and utf8_expected_bytes <= 3
	positive_max_paste_size: max_paste_size > 0
	paste_bounded: paste_buffer.count < max_paste_size
	no_paste_text_outside_paste: not is_in_paste implies paste_buffer.is_empty
	positive_max_osc_size: max_osc_size > 0
	osc_bounded: osc_buffer.count <= max_osc_size
	no_osc_in_paste: (state = State_osc_number or is_in_osc) implies not is_in_paste
	no_osc_data_outside_osc: not is_in_osc implies osc_buffer.is_empty

end
