note
	description: "[
		Win32 console driver interfacing directly with the Windows Console API via inlined C.
		Supports Virtual Terminal Processing, non-blocking UTF-16 input re-encoded as UTF-8 bytes,
		quick-edit disabling, exact restoration of the original console modes and code pages,
		and a console Ctrl handler that restores the console on unexpected termination.

		With keyboard enhancement on, key-up records become Kitty release sequences, and a
		key-down record of a key already down (an auto-repeat) becomes Kitty repeats (`:2`);
		the first key-down of a key stays a legacy press (P2 T5). Without enhancement every
		key-down record is text (repeats are presses) and key-up records are dropped.
		The characters of escape sequences, of a bracketed paste and of an OSC reply (such
		as an OSC 52 clipboard reply, ended by BEL or ST; P2b K5) are never taken for typed
		keys, so they never become repeats.

		Clipboard read (P2b K4, decision Q1): the driver reads the Win32 clipboard itself
		(`read_clipboard_text', `provides_clipboard_read'), since Windows Terminal does not
		answer an OSC 52 read and conhost has no OSC 52. Windows has no primary selection:
		{TUI_APPLICATION}.read_selection reads the clipboard too. The write stays OSC 52 (P2
		T3). Over SSH to a Windows host this reads the host's clipboard, not the client's.

		Shared native state (cached console handles and the original modes) lives in
		file-scope C globals defined once by `c_win32_define_runtime', so that the
		Ctrl handler, which runs on a system thread, can restore the console.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	WIN32_CONSOLE_DRIVER

inherit
	CONSOLE_DRIVER
		redefine
			default_create,
			input_claim,
			provides_keyboard_enhancement,
			is_title_pushed,
			set_title_pushed,
			provides_clipboard_read,
			read_clipboard_text
		end

create
	default_create

feature {NONE} -- Initialization

	default_create
			-- Initialize driver and cache the console input/output handles.
		do
			c_win32_define_runtime
			c_win32_init
			create pending_bytes.make (8)
		end

feature -- Queries

	console_width: INTEGER
			-- Current console width in columns, or default if unavailable.
		local
			w, h: INTEGER
		do
			if c_win32_get_console_size ($w, $h) and w > 0 then
				Result := w
			else
				Result := Default_width
			end
		end

	console_height: INTEGER
			-- Current console height in rows, or default if unavailable.
		local
			w, h: INTEGER
		do
			if c_win32_get_console_size ($w, $h) and h > 0 then
				Result := h
			else
				Result := Default_height
			end
		end

	is_raw: BOOLEAN
			-- Is raw input mode currently active?

	is_vt_enabled: BOOLEAN
			-- Is virtual terminal escape processing active?

	is_mouse_enabled: BOOLEAN
			-- Is mouse event reporting enabled in driver?

feature -- Mode Commands

	enable_vt_mode: BOOLEAN
			-- Enable Virtual Terminal processing for ANSI escape sequences.
		do
			Result := c_win32_enable_vt_mode
			if Result then
				is_vt_enabled := True
			end
		end

	enable_raw_mode: BOOLEAN
			-- Enable raw terminal input mode (disable echo and line buffering).
		do
			Result := c_win32_enable_raw_mode
			if Result then
				is_raw := True
			end
		end

	disable_raw_mode: BOOLEAN
			-- Restore normal cooked terminal input mode.
		do
			Result := c_win32_disable_raw_mode
			if Result then
				is_raw := False
			end
		end

	enable_mouse: BOOLEAN
			-- Enable mouse event capture (disabling quick-edit mode).
		do
			Result := c_win32_enable_mouse
			if Result then
				is_mouse_enabled := True
			end
		end

	disable_mouse: BOOLEAN
			-- Restore the original mouse and quick-edit behavior.
		do
			Result := c_win32_disable_mouse
			if Result then
				is_mouse_enabled := False
			end
		end

	is_keyboard_enhancement_enabled: BOOLEAN
			-- Is extended keyboard reporting (key release and repeat) active?

	provides_keyboard_enhancement: BOOLEAN = True
			-- The release and repeat events are built here from the console's key records
			-- (`c_win32_read_unit`), whatever the terminal answers to `ESC [ ? u`.

	enable_keyboard_enhancement
			-- Enable extended keyboard reporting.
		do
			is_keyboard_enhancement_enabled := True
		end

	disable_keyboard_enhancement
			-- Disable extended keyboard reporting. The keys the reader holds as down are
			-- forgotten (P2 T5), so after enhancement is on again a key-down is a press.
		do
			is_keyboard_enhancement_enabled := False
			c_win32_forget_keys_down
		end

	restore_modes
			-- Restore original console modes and code pages saved before the first change.
		do
			c_win32_restore_modes
			is_raw := False
			is_mouse_enabled := False
			is_vt_enabled := False
			is_keyboard_enhancement_enabled := False
			c_win32_forget_keys_down
		end

feature -- Input & Resize

	input_claim: CONSOLE_INPUT_CLAIM
			-- One claim for the whole process: every WIN32_CONSOLE_DRIVER reads the same
			-- console, and they share the key sequence state kept in C statics
			-- (`l_seq_buf`, `l_seq_pos`, `l_seq_len`) and the keys held down (P2 T5,
			-- `eiffeltui_w32_keys_down`, `eiffeltui_w32_last_char`, the VT stream state):
			-- only the claim's holder reads input, so only it touches them.
		once ("PROCESS")
			create Result.make
		end

	read_char_with_timeout (a_timeout_ms: INTEGER): INTEGER
			-- Read next input byte (UTF-8 encoded) from console with timeout in milliseconds.
			-- Returns byte value (0..255), or -1 if timeout expired or error.
		local
			l_record, l_unit: INTEGER
			l_done: BOOLEAN
		do
			from
				l_done := not pending_bytes.is_empty
			until
				l_done
			loop
				l_record := c_win32_read_unit (a_timeout_ms, is_keyboard_enhancement_enabled)
				if l_record < 0 then
					l_done := True
				else
					l_unit := l_record & 0xFFFF
					enqueue_utf16_unit (l_unit, (l_record |>> 16).max (1))
					l_done := not pending_bytes.is_empty
				end
			end
			if pending_bytes.is_empty then
				Result := -1
			else
				Result := pending_bytes.item
				pending_bytes.remove
			end
		end

	poll_resize (a_cols, a_rows: TYPED_POINTER [INTEGER]): BOOLEAN
			-- Query if console size has changed since last poll.
		local
			w, h: INTEGER
		do
			if c_win32_get_console_size ($w, $h) and then w > 0 and then h > 0 then
				if last_polled_width = 0 and last_polled_height = 0 then
					last_polled_width := w
					last_polled_height := h
					Result := False
				elseif w /= last_polled_width or h /= last_polled_height then
					last_polled_width := w
					last_polled_height := h
					set_integer_pointer (a_cols, w)
					set_integer_pointer (a_rows, h)
					Result := True
				end
			end
		end

	install_ctrl_handler
			-- Install console Ctrl handler that restores the console on unexpected termination.
		do
			c_win32_install_ctrl_handler
		end

feature -- Window title

	is_title_pushed: BOOLEAN
			-- Did the backend push the console's title without popping it since, and the
			-- Ctrl handler did not pop it either? Kept in C (`eiffeltui_w32_title_pushed`),
			-- where the handler reads and clears it.
		do
			Result := c_win32_title_pushed
		end

	set_title_pushed (a_pushed: BOOLEAN)
			-- Record whether the console's title is pushed, for the Ctrl handler.
		do
			c_win32_set_title_pushed (a_pushed)
		end

feature -- Clipboard read

	provides_clipboard_read: BOOLEAN
			-- The driver reads the Win32 clipboard itself (`read_clipboard_text`).
		do
			Result := True
		end

	read_clipboard_text (a_max_count: INTEGER): detachable STRING_32
			-- The clipboard's CF_UNICODETEXT text, or Void (see `last_clipboard_status`): Void
			-- with `Status_text` for an empty clipboard or one with no text, with
			-- `Status_unavailable` when another program held it for the whole retry time
			-- (`OpenClipboard` tried for about 100 ms), with `Status_too_large` when it holds
			-- more than `a_max_count` UTF-16 code units (nothing is copied then). Line breaks
			-- (CR LF) and other controls are kept; a lone surrogate becomes U+FFFD.
			-- Takes no input claim: it does not read the console.
		local
			l_buffer: POINTER
			l_status, l_count, i, l_unit, l_next: INTEGER
			l_units: MANAGED_POINTER
			l_text: STRING_32
		do
			l_buffer := c_win32_clipboard_read (a_max_count, $l_status, $l_count)
			last_clipboard_status := l_status
			if l_buffer /= default_pointer then
				create l_units.share_from_pointer (l_buffer, l_count * 2)
				create l_text.make (l_count)
				from
					i := 0
				until
					i >= l_count
				loop
					l_unit := l_units.read_natural_16 (i * 2).to_integer_32
					i := i + 1
					if l_unit >= 0xD800 and l_unit <= 0xDBFF and i < l_count then
						l_next := l_units.read_natural_16 (i * 2).to_integer_32
						if l_next >= 0xDC00 and l_next <= 0xDFFF then
							i := i + 1
							l_text.append_code ((0x10000 + ((l_unit - 0xD800) |<< 10) + (l_next - 0xDC00)).to_natural_32)
						else
							l_text.append_code (Replacement_code)
						end
					elseif l_unit >= 0xD800 and l_unit <= 0xDFFF then
						l_text.append_code (Replacement_code)
					else
						l_text.append_code (l_unit.to_natural_32)
					end
				end
				c_free (l_buffer)
				Result := l_text
			end
		end

feature -- Termination requests

	is_deferring_termination: BOOLEAN
			-- Are Ctrl events recorded for the application loop instead of handled at once?
		do
			Result := c_win32_is_deferring
		end

	set_deferring_termination (a_on: BOOLEAN)
			-- Record Ctrl events for the application loop (`a_on`), or handle them at once.
		do
			c_win32_set_deferring (a_on)
		end

	has_termination_request: BOOLEAN
			-- Is a deferred Ctrl event waiting?
		do
			Result := c_win32_pending >= 0
		end

	termination_request_code: INTEGER
			-- Type of the pending Ctrl event (CTRL_C_EVENT = 0, CTRL_BREAK_EVENT = 1,
			-- CTRL_CLOSE_EVENT = 2, CTRL_LOGOFF_EVENT = 5, CTRL_SHUTDOWN_EVENT = 6)
		do
			Result := c_win32_pending
		end

	discard_termination_request
			-- Forget the pending Ctrl event.
		do
			c_win32_discard
		end

	finish_termination
			-- End the process with STATUS_CONTROL_C_EXIT, as the default Ctrl handler does. For a
			-- close, logoff or shutdown, first release the handler thread waiting for the
			-- restore. Does not return.
		do
			c_win32_finish
		end

feature {NONE} -- UTF-16 to UTF-8 conversion

	pending_bytes: ARRAYED_QUEUE [INTEGER]
			-- UTF-8 bytes decoded from the last console record, not yet returned

	pending_high_surrogate: INTEGER
			-- High surrogate waiting for its low surrogate, or 0

	Max_repeat: INTEGER = 64

	Replacement_code: NATURAL_32 = 0xFFFD
			-- U+FFFD, for a lone surrogate in the clipboard's text
			-- Upper bound on honoured key auto-repeat count per record

	enqueue_utf16_unit (a_unit, a_repeat: INTEGER)
			-- Decode UTF-16 code unit `a_unit` (repeated `a_repeat` times) into `pending_bytes`.
		require
			valid_unit: a_unit >= 0 and a_unit <= 0xFFFF
			positive_repeat: a_repeat >= 1
		do
			if a_unit >= 0xD800 and a_unit <= 0xDBFF then
				pending_high_surrogate := a_unit
			elseif a_unit >= 0xDC00 and a_unit <= 0xDFFF then
				if pending_high_surrogate /= 0 then
					enqueue_code_point (0x10000 + ((pending_high_surrogate - 0xD800) |<< 10) + (a_unit - 0xDC00), a_repeat)
				end
				pending_high_surrogate := 0
			else
				pending_high_surrogate := 0
				enqueue_code_point (a_unit, a_repeat)
			end
		end

	enqueue_code_point (a_code: INTEGER; a_repeat: INTEGER)
			-- Append the UTF-8 encoding of `a_code` to `pending_bytes`, `a_repeat` times.
		require
			valid_code_point: a_code >= 0 and a_code <= 0x10FFFF
			positive_repeat: a_repeat >= 1
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > a_repeat.min (Max_repeat)
			loop
				if a_code <= 0x7F then
					pending_bytes.extend (a_code)
				elseif a_code <= 0x7FF then
					pending_bytes.extend (0xC0 | (a_code |>> 6))
					pending_bytes.extend (0x80 | (a_code & 0x3F))
				elseif a_code <= 0xFFFF then
					pending_bytes.extend (0xE0 | (a_code |>> 12))
					pending_bytes.extend (0x80 | ((a_code |>> 6) & 0x3F))
					pending_bytes.extend (0x80 | (a_code & 0x3F))
				else
					pending_bytes.extend (0xF0 | (a_code |>> 18))
					pending_bytes.extend (0x80 | ((a_code |>> 12) & 0x3F))
					pending_bytes.extend (0x80 | ((a_code |>> 6) & 0x3F))
					pending_bytes.extend (0x80 | (a_code & 0x3F))
				end
				i := i + 1
			end
		end

feature {NONE} -- Implementation Helpers

	last_polled_width: INTEGER
	last_polled_height: INTEGER

	set_integer_pointer (a_ptr: TYPED_POINTER [INTEGER]; a_val: INTEGER)
		external
			"C inline"
		alias
			"[
				*(EIF_INTEGER *)$a_ptr = (EIF_INTEGER)$a_val;
			]"
		end

feature {NONE} -- Inlined C Implementation

	c_win32_define_runtime
			-- Define the file-scope C state and helpers shared by the other externals.
			-- The body closes the generated wrapper function, emits file-scope
			-- definitions, and reopens an unused function for the generated epilogue.
		external
			"C inline use <windows.h>, <stdio.h>, <stdlib.h>"
		alias
			"[
				}

				HANDLE eiffeltui_w32_in = INVALID_HANDLE_VALUE;
				HANDLE eiffeltui_w32_out = INVALID_HANDLE_VALUE;
				int eiffeltui_w32_saved = 0;
				int eiffeltui_w32_in_saved = 0;
				int eiffeltui_w32_out_saved = 0;
				DWORD eiffeltui_w32_orig_in_mode = 0;
				DWORD eiffeltui_w32_orig_out_mode = 0;
				UINT eiffeltui_w32_orig_in_cp = 0;
				UINT eiffeltui_w32_orig_out_cp = 0;
				int eiffeltui_w32_handler_installed = 0;

					/* Deferred termination (review finding C5): while an application loop draws,
					 * the handler records the event (type + 1, 0: none) and the loop restores the
					 * console. `eiffeltui_w32_restored' is set when the loop is done, for a
					 * handler thread waiting on a close event. */
				volatile LONG eiffeltui_w32_deferring = 0;
				volatile LONG eiffeltui_w32_pending = 0;
				HANDLE eiffeltui_w32_restored = NULL;

					/* What the Ctrl handler writes when it restores the console itself: keyboard
					 * flags popped, mouse reporting (motion, mode 1003, too), paste and focus
					 * reporting off, attributes reset, the default cursor shape (DECSCUSR 0), the
					 * cursor shown, the main screen.
					 * Not static, so that the driver tests can read it. */
				const char eiffeltui_w32_reset [] =
					"\x1b[<u\x1b[?1000l\x1b[?1002l\x1b[?1003l\x1b[?1006l\x1b[?2004l\x1b[?1004l\x1b[0m\x1b[0 q\x1b[?25h\x1b[?1049l";

					/* Did the application push the console's window title (XTWINOPS 22, P2 T2)
					 * without popping it? The Ctrl handler then writes the pop after the reset. */
				volatile LONG eiffeltui_w32_title_pushed = 0;
				const char eiffeltui_w32_pop_title [] = "\x1b[23;0t";

					/* Put what the Ctrl handler writes into `a_buf' (room for the reset and the
					 * pop) and return its length: the reset, then the title pop if a title is
					 * pushed, which it then no longer is. Not static: the driver tests call it. */
				DWORD eiffeltui_w32_reset_output (char *a_buf)
				{
					DWORD l_len = (DWORD) (sizeof (eiffeltui_w32_reset) - 1);
					CopyMemory (a_buf, eiffeltui_w32_reset, l_len);
					if (InterlockedExchange (&eiffeltui_w32_title_pushed, 0) != 0) {
						CopyMemory (a_buf + l_len, eiffeltui_w32_pop_title, sizeof (eiffeltui_w32_pop_title) - 1);
						l_len += (DWORD) (sizeof (eiffeltui_w32_pop_title) - 1);
					}
					return l_len;
				}

					/* Keys held down (P2 T5), for Kitty repeats. All of this state but the epoch
					 * belongs to the one reader of console input (`c_win32_read_unit', run by the
					 * holder of the input claim); no other thread touches it.
					 *
					 * Two kinds of key-down records reach the reader:
					 * - Records that name their key (`wVirtualKeyCode' /= 0): the console keeps
					 *   them when ENABLE_VIRTUAL_TERMINAL_INPUT is off. The set of keys down is
					 *   kept by virtual-key code (`eiffeltui_w32_keys_down').
					 * - With ENABLE_VIRTUAL_TERMINAL_INPUT on (raw mode), the console replaces each
					 *   key-down record by records of the characters of its VT translation, with
					 *   no key code, no scan code and no modifier state (`wVirtualKeyCode' = 0;
					 *   seen on Windows 11 conhost, and under ConPTY, which Windows Terminal uses:
					 *   `tools/conpty_probe'). Key-up records still come as they are, also for
					 *   text written to ConPTY as plain text (typed or pasted: each character is a
					 *   key-down without a key code, then a key-up with one). Only the last key
					 *   typed can repeat (Windows repeats the last key pressed), so it is kept
					 *   until a key-up of a key that is not a modifier, any key-down that names
					 *   its key, or input that is not a key: a lone character
					 *   (`eiffeltui_w32_last_char') or a whole key sequence, an arrow, Home, End,
					 *   PgUp, PgDn, Insert, Delete, an F-key, Shift+Tab or Alt+key
					 *   (`eiffeltui_w32_last_seq', review fix #3; read ahead with
					 *   PeekConsoleInputW, `eiffeltui_w32_take_key_seq'). The VT stream is
					 *   followed (`eiffeltui_w32_vt_step') so that the characters of other escape
					 *   sequences (mouse reports, CSI replies, OSC replies such as OSC 52: P2b K5)
					 *   and of a bracketed paste are never taken for typed keys.
					 * - Review fix #2: records without a key code give repeats only once this
					 *   console has sent a key-up of a key that is not a modifier since enhancement
					 *   was turned on (`eiffeltui_w32_keyups_seen'). A host that sends no key-ups
					 *   would otherwise turn every doubled letter ("ee") into a press and a
					 *   repeat; there every key-down stays a press, as before T5.
					 *
					 * Turning keyboard enhancement off (or restoring the modes) bumps the epoch from
					 * any thread; the reader forgets its keys when it sees a new epoch, and also
					 * the VT stream state, an open bracketed paste included (review fix #4). */
				volatile LONG eiffeltui_w32_keys_epoch = 0;
				LONG eiffeltui_w32_keys_seen = 0;
				unsigned char eiffeltui_w32_keys_down [256];
				int eiffeltui_w32_keys_down_count = 0;
				unsigned int eiffeltui_w32_last_char = 0;
				char eiffeltui_w32_last_seq [16];
				int eiffeltui_w32_last_seq_len = 0;
				int eiffeltui_w32_keyups_seen = 0;
					/* Is Shift held? Followed from the records that keep their key code with VT
					 * input on (the modifier keys' own records, every key-up), so that a repeat
					 * of a character without a key code carries Shift as the key's release does. */
				int eiffeltui_w32_shift_down = 0;
					/* Tick of the last character read inside a bracketed paste: a paste that
					 * stays open with no input for `Paste_idle_ms' (its end `ESC [ 201 ~' was
					 * lost) is taken as ended (review fix #4). */
				ULONGLONG eiffeltui_w32_vt_paste_tick = 0;
					/* The VT stream of characters without a key code: 0 ground, 1 after ESC,
					 * 2 in a CSI sequence, 3 after ESC O, 4 in the three bytes of an X10 mouse
					 * report, 5 in an OSC sequence (`ESC ]', P2b K5), 6 after ESC inside an OSC
					 * sequence; whether a bracketed paste is open; the CSI parameters so far. */
				int eiffeltui_w32_vt_state = 0;
				int eiffeltui_w32_vt_skip = 0;
				int eiffeltui_w32_vt_in_paste = 0;
				char eiffeltui_w32_vt_params [8];
				int eiffeltui_w32_vt_params_len = 0;
					/* P2b K5, state 5: the digits of the OSC number so far, and whether its `;'
					 * came (the OSC is committed). Until then, as in ANSI_INPUT_PARSER, a character
					 * that cannot continue `ESC ] <digits> ;' shows that `ESC ]' was Alt+`]'. */
				int eiffeltui_w32_vt_osc_digits = 0;
				int eiffeltui_w32_vt_osc_committed = 0;
					/* Tick of the last character read inside an OSC sequence: one still open
					 * after `Paste_idle_ms' with no input (its end was lost) is taken as ended,
					 * as a bracketed paste is (review fix #4). */
				ULONGLONG eiffeltui_w32_vt_osc_tick = 0;

				void eiffeltui_w32_forget_keys (void)
				{
					ZeroMemory (eiffeltui_w32_keys_down, sizeof (eiffeltui_w32_keys_down));
					eiffeltui_w32_keys_down_count = 0;
					eiffeltui_w32_last_char = 0;
					eiffeltui_w32_last_seq_len = 0;
					eiffeltui_w32_shift_down = 0;
				}

					/* Forget the VT stream state: no sequence (an OSC included) and no bracketed
					 * paste open. */
				void eiffeltui_w32_vt_reset (void)
				{
					eiffeltui_w32_vt_state = 0;
					eiffeltui_w32_vt_skip = 0;
					eiffeltui_w32_vt_in_paste = 0;
					eiffeltui_w32_vt_params_len = 0;
					eiffeltui_w32_vt_osc_digits = 0;
					eiffeltui_w32_vt_osc_committed = 0;
				}

					/* Forget the keys down when enhancement is off or was turned off since. A new
					 * epoch (enhancement turned off, modes restored: the end of a run, a stop) also
					 * forgets the VT stream state and whether key-ups were seen (review fix #4). */
				void eiffeltui_w32_check_keys (int a_enhanced)
				{
					LONG l_epoch = InterlockedCompareExchange (&eiffeltui_w32_keys_epoch, 0, 0);
					if (!a_enhanced || l_epoch != eiffeltui_w32_keys_seen) {
						if (eiffeltui_w32_keys_down_count > 0 || eiffeltui_w32_last_char != 0 || eiffeltui_w32_last_seq_len != 0) {
							eiffeltui_w32_forget_keys ();
						}
						if (l_epoch != eiffeltui_w32_keys_seen) {
							eiffeltui_w32_vt_reset ();
							eiffeltui_w32_keyups_seen = 0;
						}
						eiffeltui_w32_keys_seen = l_epoch;
					}
				}

					/* Follow character `a_c' of the VT stream; 1 if it is lone text typed on the
					 * keyboard (outside an escape sequence, an OSC sequence and a bracketed
					 * paste), else 0.
					 * P2b K5: an OSC sequence (`ESC ] <digits> ; ...', a terminal's reply such as
					 * OSC 52 or an OSC 11 colour report) is followed to its end, BEL or ST
					 * (`ESC \'), and none of its characters is lone text, so none is taken for a
					 * typed key or a repeat. It is read as ANSI_INPUT_PARSER reads it (P2b K2):
					 * - `ESC ]' is not taken for an OSC inside a bracketed paste (it is pasted text);
					 * - before the `;' that ends the number, a character other than a digit (or a
					 *   65th digit, or `;' right after `ESC ]') shows that `ESC ]' was Alt+`]': that
					 *   character is read again in ground state (the digits are not lone text);
					 * - ESC inside the OSC followed by anything but `\' ends it, and that character
					 *   is read as the one after a new ESC (`ESC [ A' is Up);
					 * - CAN (18) and SUB (1A) cancel it and are then lone text (Ctrl+X, Ctrl+Z);
					 * - an OSC still open after `Paste_idle_ms' with no input is taken as ended,
					 *   and the character is read in ground state (review fix #4 for OSC). */
				int eiffeltui_w32_vt_step (unsigned int a_c)
				{
					int l_len = eiffeltui_w32_vt_params_len;
					if (eiffeltui_w32_vt_in_paste) {
						ULONGLONG l_now = GetTickCount64 ();
						if (l_now - eiffeltui_w32_vt_paste_tick > 1000) { /* `Paste_idle_ms' */
								/* A paste arrives as one burst: its end was lost (review fix #4) */
							eiffeltui_w32_vt_in_paste = 0;
						} else {
							eiffeltui_w32_vt_paste_tick = l_now;
						}
					}
					if (eiffeltui_w32_vt_state == 5 || eiffeltui_w32_vt_state == 6) {
						ULONGLONG l_now = GetTickCount64 ();
						if (l_now - eiffeltui_w32_vt_osc_tick > 1000) { /* `Paste_idle_ms' */
								/* A reply arrives as one burst: its end was lost (P2b K5) */
							eiffeltui_w32_vt_state = 0;
						} else {
							eiffeltui_w32_vt_osc_tick = l_now;
						}
					}
					switch (eiffeltui_w32_vt_state) {
						case 0:
							if (a_c == 27) {
								eiffeltui_w32_vt_state = 1;
								return 0;
							}
							return !eiffeltui_w32_vt_in_paste;
						case 1:
							if (a_c == '[') {
								eiffeltui_w32_vt_state = 2;
								eiffeltui_w32_vt_params_len = 0;
							} else if (a_c == 'O') {
								eiffeltui_w32_vt_state = 3;
							} else if (a_c == ']' && !eiffeltui_w32_vt_in_paste) {
									/* OSC (P2b K5), or Alt+`]' if no `<digits> ;' follows */
								eiffeltui_w32_vt_state = 5;
								eiffeltui_w32_vt_osc_digits = 0;
								eiffeltui_w32_vt_osc_committed = 0;
								eiffeltui_w32_vt_osc_tick = GetTickCount64 ();
							} else if (a_c != 27) {
									/* ESC + character: Alt held */
								eiffeltui_w32_vt_state = 0;
							}
							return 0;
						case 2:
							if (a_c >= 0x30 && a_c <= 0x3F) {
								if (l_len < (int) sizeof (eiffeltui_w32_vt_params)) {
									eiffeltui_w32_vt_params [l_len] = (char) a_c;
								}
								eiffeltui_w32_vt_params_len = l_len + 1;
							} else if (a_c >= 0x40 && a_c <= 0x7E) {
								eiffeltui_w32_vt_state = 0;
								if (a_c == '~' && l_len == 3 && eiffeltui_w32_vt_params [0] == '2' && eiffeltui_w32_vt_params [1] == '0') {
									if (eiffeltui_w32_vt_params [2] == '0') {
										eiffeltui_w32_vt_in_paste = 1;
										eiffeltui_w32_vt_paste_tick = GetTickCount64 ();
									} else if (eiffeltui_w32_vt_params [2] == '1') {
										eiffeltui_w32_vt_in_paste = 0;
									}
								} else if (a_c == 'M' && l_len == 0) {
										/* X10 mouse report: three raw bytes follow */
									eiffeltui_w32_vt_state = 4;
									eiffeltui_w32_vt_skip = 3;
								} else if (a_c == 'O' && l_len == 0 && !eiffeltui_w32_vt_in_paste) {
										/* Focus lost (mode 1004): keys let go elsewhere send no key-up */
									eiffeltui_w32_forget_keys ();
								}
							} else if (a_c == 27) {
								eiffeltui_w32_vt_state = 1;
							} else if (!(a_c >= 0x20 && a_c <= 0x2F)) {
								eiffeltui_w32_vt_state = 0;
							}
							return 0;
						case 3:
							eiffeltui_w32_vt_state = 0;
							return 0;
						case 5:
							if (!eiffeltui_w32_vt_osc_committed) {
								if (a_c >= '0' && a_c <= '9' && eiffeltui_w32_vt_osc_digits < 64) {
									eiffeltui_w32_vt_osc_digits++;
									return 0;
								} else if (a_c == ';' && eiffeltui_w32_vt_osc_digits > 0) {
									eiffeltui_w32_vt_osc_committed = 1;
									return 0;
								}
									/* Not an OSC: `ESC ]' was Alt+`]'; this character starts over */
								eiffeltui_w32_vt_state = 0;
								return eiffeltui_w32_vt_step (a_c);
							}
							if (a_c == 7) {
									/* BEL: the end */
								eiffeltui_w32_vt_state = 0;
							} else if (a_c == 27) {
								eiffeltui_w32_vt_state = 6;
							} else if (a_c == 0x18 || a_c == 0x1A) {
									/* CAN / SUB cancel the OSC: typed (Ctrl+X, Ctrl+Z) */
								eiffeltui_w32_vt_state = 0;
								return !eiffeltui_w32_vt_in_paste;
							}
							return 0;
						case 6:
							if (a_c == '\\') {
									/* ST: the end */
								eiffeltui_w32_vt_state = 0;
								return 0;
							}
								/* The OSC was cut off: this character follows a new ESC */
							eiffeltui_w32_vt_state = 1;
							return eiffeltui_w32_vt_step (a_c);
						default:
							if (--eiffeltui_w32_vt_skip <= 0) {
								eiffeltui_w32_vt_state = 0;
							}
							return 0;
					}
				}

					/* Is `a_vk' a modifier or lock key? Their records give no event of their own. */
				int eiffeltui_w32_is_modifier_key (WORD a_vk)
				{
					switch (a_vk) {
						case VK_SHIFT: case VK_CONTROL: case VK_MENU:
						case VK_LSHIFT: case VK_RSHIFT: case VK_LCONTROL: case VK_RCONTROL: case VK_LMENU: case VK_RMENU:
						case VK_LWIN: case VK_RWIN: case VK_CAPITAL: case VK_NUMLOCK: case VK_SCROLL:
							return 1;
						default:
							return 0;
					}
				}

					/* Is `a_vk' a key whose key-down records are tracked by key code? Not 0 and
					 * not VK_PACKET (characters sent by an IME or a touch keyboard, which name
					 * no physical key), and not a modifier or lock key. */
				int eiffeltui_w32_is_tracked_key (WORD a_vk)
				{
					return a_vk != 0 && a_vk != 0xE7 && a_vk < 256 && !eiffeltui_w32_is_modifier_key (a_vk);
				}

					/* Write into `a_buf' (room for 32 bytes) the Kitty sequence with event type
					 * `a_type' for character `a_code' of a record without a key code (its VT
					 * translation) and return its length, or 0 when it has no Kitty form here. The
					 * key is read from the character as ANSI_INPUT_PARSER reads legacy text, with
					 * no modifier but Ctrl for the control characters, and Shift (`a_shift') for
					 * the printable ones, as `eiffeltui_w32_kitty_key' writes the key's release. */
				int eiffeltui_w32_kitty_char (char *a_buf, unsigned int a_code, int a_type, int a_shift)
				{
					if (a_code == 10 || a_code == 13) {
						return sprintf (a_buf, "\x1b[13;1:%du", a_type);
					} else if (a_code == 9) {
						return sprintf (a_buf, "\x1b[9;1:%du", a_type);
					} else if (a_code == 8 || a_code == 127) {
						return sprintf (a_buf, "\x1b[127;1:%du", a_type);
					} else if (a_code >= 1 && a_code <= 26) {
						return sprintf (a_buf, "\x1b[%u;5:%du", a_code + 96, a_type);
					} else if (a_code >= 32) {
						return sprintf (a_buf, "\x1b[%u;%d:%du", a_code, a_shift ? 2 : 1, a_type);
					}
					return 0;
				}

					/* Write into `a_buf' (room for 32 bytes) the Kitty sequence for the key of
					 * `a_kev' with event type `a_type' (2 repeat, 3 release) and return its length,
					 * or 0 when the key has no Kitty form here. `a_code' is the record's character
					 * (a code point, its surrogates already joined), or 0. */
				int eiffeltui_w32_kitty_key (char *a_buf, const KEY_EVENT_RECORD *a_kev, unsigned int a_code, int a_type)
				{
					int shift = (a_kev->dwControlKeyState & 0x0010) ? 1 : 0;
					int alt = (a_kev->dwControlKeyState & (0x0001 | 0x0002)) ? 2 : 0;
					int ctrl = (a_kev->dwControlKeyState & (0x0004 | 0x0008)) ? 4 : 0;
					int mod = 1 + shift + alt + ctrl;
					WORD vk = a_kev->wVirtualKeyCode;
					if (a_code >= 32) {
						return sprintf (a_buf, "\x1b[%u;%d:%du", a_code, mod, a_type);
					} else if (vk >= 'A' && vk <= 'Z') {
							/* With Ctrl held the record carries a control character: report the letter */
						return sprintf (a_buf, "\x1b[%d;%d:%du", (int) (vk - 'A' + 'a'), mod, a_type);
					} else if (vk >= '0' && vk <= '9') {
						return sprintf (a_buf, "\x1b[%d;%d:%du", (int) vk, mod, a_type);
					} else if (vk == VK_RETURN) {
						return sprintf (a_buf, "\x1b[13;%d:%du", mod, a_type);
					} else if (vk == VK_TAB) {
						return sprintf (a_buf, "\x1b[9;%d:%du", mod, a_type);
					} else if (vk == VK_BACK) {
						return sprintf (a_buf, "\x1b[127;%d:%du", mod, a_type);
					} else if (vk == VK_ESCAPE) {
						return sprintf (a_buf, "\x1b[27;%d:%du", mod, a_type);
					} else if (vk == VK_UP) {
						return sprintf (a_buf, "\x1b[1;%d:%dA", mod, a_type);
					} else if (vk == VK_DOWN) {
						return sprintf (a_buf, "\x1b[1;%d:%dB", mod, a_type);
					} else if (vk == VK_RIGHT) {
						return sprintf (a_buf, "\x1b[1;%d:%dC", mod, a_type);
					} else if (vk == VK_LEFT) {
						return sprintf (a_buf, "\x1b[1;%d:%dD", mod, a_type);
					} else if (vk == VK_HOME) {
						return sprintf (a_buf, "\x1b[1;%d:%dH", mod, a_type);
					} else if (vk == VK_END) {
						return sprintf (a_buf, "\x1b[1;%d:%dF", mod, a_type);
					} else if (vk == VK_INSERT) {
						return sprintf (a_buf, "\x1b[2;%d:%d~", mod, a_type);
					} else if (vk == VK_DELETE) {
						return sprintf (a_buf, "\x1b[3;%d:%d~", mod, a_type);
					} else if (vk == VK_PRIOR) {
						return sprintf (a_buf, "\x1b[5;%d:%d~", mod, a_type);
					} else if (vk == VK_NEXT) {
						return sprintf (a_buf, "\x1b[6;%d:%d~", mod, a_type);
					} else if (vk >= VK_F1 && vk <= VK_F12) {
							/* Tilde forms for all of F1..F12 (Kitty's F3 is 13~, never ambiguous with a DSR reply) */
						static const int fn_codes[] = {11, 12, 13, 14, 15, 17, 18, 19, 20, 21, 23, 24};
						return sprintf (a_buf, "\x1b[%d;%d:%d~", fn_codes[vk - VK_F1], mod, a_type);
					}
					return 0;
				}

					/* Is `a_rec' the key-down record, without a key code, of one character of a
					 * VT translation (ENABLE_VIRTUAL_TERMINAL_INPUT)? Then its character. */
				static unsigned int eiffeltui_w32_vt_char_of (const INPUT_RECORD *a_rec)
				{
					if (a_rec->EventType == KEY_EVENT && a_rec->Event.KeyEvent.bKeyDown
						&& a_rec->Event.KeyEvent.wVirtualKeyCode == 0)
					{
						return (unsigned int) a_rec->Event.KeyEvent.uChar.UnicodeChar;
					}
					return 0;
				}

					/* Review fix #3. Called after the reader took an ESC that starts a sequence
					 * (VT stream in ground state, no paste open). Look at the records that follow,
					 * without taking them (PeekConsoleInputW): when they complete the VT translation
					 * of a key, take them, put that sequence, ESC first, in `a_seq' (its length in
					 * `a_seq_len', at most 15) and its Kitty repeat form (event type 2) in `a_kitty'
					 * (`a_kitty_len', at most 31), and return 1. Otherwise take nothing and return
					 * 0: the records are read one by one as before (mouse reports, replies, focus,
					 * a sequence not complete yet, an Esc key on its own).
					 * Keys: CSI A B C D H F (arrows, Home, End), CSI P Q R S (F1-F4 with modifiers),
					 * plain or as `1 ; m'; CSI n ~ and CSI n ; m ~ (Insert, Delete, PgUp, PgDn,
					 * F-keys), but not the paste marks 200 and 201; CSI Z (Shift+Tab); SS3 A-D, H,
					 * F, P-S; ESC + an ASCII character (Alt+key), but not `]' followed by a digit,
					 * the start of an OSC reply (P2b K5). CSI 1 ; m R is not taken: it reads
					 * the same as a cursor position report. F1-F4 repeat in the tilde forms 11-14 ~,
					 * as `eiffeltui_w32_kitty_key' writes their releases. */
				int eiffeltui_w32_take_key_seq (char *a_seq, int *a_seq_len, char *a_kitty, int *a_kitty_len)
				{
					INPUT_RECORD l_recs [16];
					DWORD l_n = 0, l_taken = 0, i;
					char l_params [12];
					int l_plen = 0;
					unsigned int c, l_final = 0;
					int l_mod = 1, l_num = 0, l_kind = 0; /* 1 CSI, 2 SS3, 3 Alt */
					if (!PeekConsoleInputW (eiffeltui_w32_in, l_recs, 16, &l_n) || l_n == 0) return 0;
					c = eiffeltui_w32_vt_char_of (&l_recs [0]);
					if (c == ']') {
							/* P2b K5: `ESC ] <digit>' starts an OSC sequence (a terminal's reply),
							 * followed by `eiffeltui_w32_vt_step', not the key Alt+`]'. With
							 * nothing queued after the `]' yet (a reply split between two reads),
							 * it is not known: left to the follower too, which takes it for
							 * Alt+`]' if no `<digits> ;' follows (only that Alt+`]' is then not
							 * tracked as a held key sequence). */
						unsigned int d;
						if (l_n < 2) return 0;
						d = eiffeltui_w32_vt_char_of (&l_recs [1]);
						if (d >= '0' && d <= '9') return 0;
					}
					if (c == '[') {
						for (i = 1; i < l_n; i++) {
							unsigned int d = eiffeltui_w32_vt_char_of (&l_recs [i]);
							if (d >= 0x30 && d <= 0x3F) {
								if (l_plen >= (int) sizeof (l_params)) return 0;
								l_params [l_plen++] = (char) d;
							} else if (d >= 0x40 && d <= 0x7E) {
								l_final = d;
								l_taken = i + 1;
								break;
							} else {
								return 0;
							}
						}
						if (l_final == 0) return 0;
						l_kind = 1;
					} else if (c == 'O') {
						if (l_n < 2) return 0;
						l_final = eiffeltui_w32_vt_char_of (&l_recs [1]);
						l_taken = 2;
						l_kind = 2;
					} else if (c >= 1 && c <= 0x7F && c != 27) {
						l_final = c;
						l_taken = 1;
						l_kind = 3;
					} else {
						return 0;
					}
					if (l_kind == 1 || l_kind == 2) {
							/* The parameters: empty, `n', `n ; m' or `1 ; m', digits only */
						int l_semi = -1, j, l_first = 0, l_second = 0;
						for (j = 0; j < l_plen; j++) {
							if (l_params [j] == ';' && l_semi < 0) {
								l_semi = j;
							} else if (l_params [j] < '0' || l_params [j] > '9') {
								return 0;
							} else if (l_semi < 0) {
								l_first = l_first * 10 + (l_params [j] - '0');
								if (l_first > 999) return 0;
							} else {
								l_second = l_second * 10 + (l_params [j] - '0');
								if (l_second > 999) return 0;
							}
						}
						if (l_semi >= 0 && (l_semi == 0 || l_semi == l_plen - 1)) return 0;
						if (l_semi >= 0) l_mod = l_second;
						if (l_mod < 1) return 0;
						if (l_final == '~') {
							if (l_kind != 1 || l_plen == 0 || l_first == 200 || l_first == 201) return 0;
							l_num = l_first;
						} else if (l_final == 'A' || l_final == 'B' || l_final == 'C' || l_final == 'D'
							|| l_final == 'H' || l_final == 'F')
						{
							if (l_plen > 0 && !(l_semi >= 0 && l_first == 1)) return 0;
						} else if (l_final == 'P' || l_final == 'Q' || l_final == 'S' || (l_final == 'R' && l_kind == 2)) {
							if (l_plen > 0 && !(l_semi >= 0 && l_first == 1)) return 0;
							l_num = (l_final == 'P') ? 11 : (l_final == 'Q') ? 12 : (l_final == 'R') ? 13 : 14;
							l_final = '~';
						} else if (l_final == 'Z' && l_kind == 1 && l_plen == 0) {
							l_num = 9;
							l_mod = 2;
							l_final = 'u';
						} else {
							return 0;
						}
						if (l_final == '~' || l_final == 'u') {
							*a_kitty_len = sprintf (a_kitty, "\x1b[%d;%d:2%c", l_num, l_mod, (char) l_final);
						} else {
							*a_kitty_len = sprintf (a_kitty, "\x1b[1;%d:2%c", l_mod, (char) l_final);
						}
					} else {
							/* Alt+key: the character's Kitty form with Alt (2) added */
						if (l_final == 9 || l_final == 13) {
							*a_kitty_len = sprintf (a_kitty, "\x1b[%u;3:2u", l_final);
						} else if (l_final == 8 || l_final == 127) {
							*a_kitty_len = sprintf (a_kitty, "\x1b[127;3:2u");
						} else if (l_final >= 1 && l_final <= 26) {
							*a_kitty_len = sprintf (a_kitty, "\x1b[%u;7:2u", l_final + 96);
						} else if (l_final >= 32) {
							*a_kitty_len = sprintf (a_kitty, "\x1b[%u;3:2u", l_final);
						} else {
							return 0;
						}
					}
						/* A key: take its records, now that nothing can fail */
					if (!ReadConsoleInputW (eiffeltui_w32_in, l_recs, l_taken, &l_n) || l_n != l_taken) return 0;
					a_seq [0] = 27;
					for (i = 0; i < l_taken; i++) {
						a_seq [i + 1] = (char) eiffeltui_w32_vt_char_of (&l_recs [i]);
					}
					*a_seq_len = (int) l_taken + 1;
						/* The sequence is complete: the VT stream is in ground state again */
					eiffeltui_w32_vt_state = 0;
					eiffeltui_w32_vt_params_len = 0;
					return 1;
				}

				static HANDLE eiffeltui_w32_open (DWORD a_std, LPCWSTR a_name)
				{
					DWORD l_mode = 0;
					HANDLE h = GetStdHandle (a_std);
					if (h != INVALID_HANDLE_VALUE && h != NULL && GetConsoleMode (h, &l_mode)) {
						return h;
					}
					h = CreateFileW (a_name, GENERIC_READ | GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL);
					if (h != INVALID_HANDLE_VALUE && GetConsoleMode (h, &l_mode)) {
						return h;
					}
					if (h != INVALID_HANDLE_VALUE) {
						CloseHandle (h);
					}
					return INVALID_HANDLE_VALUE;
				}

				void eiffeltui_w32_init (void)
				{
					DWORD l_mode = 0;
						/* A kept handle may not be a console any more: the standard handle it was
						 * may have been closed by a redirection of the standard output (`_dup2'),
						 * its value then reused. Such a handle is not closed (it is not ours any
						 * more), the console is opened again. */
					if (eiffeltui_w32_in != INVALID_HANDLE_VALUE && !GetConsoleMode (eiffeltui_w32_in, &l_mode)) {
						eiffeltui_w32_in = INVALID_HANDLE_VALUE;
					}
					if (eiffeltui_w32_out != INVALID_HANDLE_VALUE && !GetConsoleMode (eiffeltui_w32_out, &l_mode)) {
						eiffeltui_w32_out = INVALID_HANDLE_VALUE;
					}
					if (eiffeltui_w32_in == INVALID_HANDLE_VALUE) {
						eiffeltui_w32_in = eiffeltui_w32_open (STD_INPUT_HANDLE, L"CONIN$");
					}
					if (eiffeltui_w32_out == INVALID_HANDLE_VALUE) {
						eiffeltui_w32_out = eiffeltui_w32_open (STD_OUTPUT_HANDLE, L"CONOUT$");
					}
				}

				void eiffeltui_w32_save (void)
				{
					DWORD l_mode = 0;
					if (eiffeltui_w32_saved) return;
					if (eiffeltui_w32_in != INVALID_HANDLE_VALUE && GetConsoleMode (eiffeltui_w32_in, &l_mode)) {
						eiffeltui_w32_orig_in_mode = l_mode;
						eiffeltui_w32_in_saved = 1;
					}
					if (eiffeltui_w32_out != INVALID_HANDLE_VALUE && GetConsoleMode (eiffeltui_w32_out, &l_mode)) {
						eiffeltui_w32_orig_out_mode = l_mode;
						eiffeltui_w32_out_saved = 1;
					}
					eiffeltui_w32_orig_in_cp = GetConsoleCP ();
					eiffeltui_w32_orig_out_cp = GetConsoleOutputCP ();
					eiffeltui_w32_saved = 1;
				}

				void eiffeltui_w32_restore_modes (void)
				{
					if (!eiffeltui_w32_saved) return;
					if (eiffeltui_w32_in_saved) {
							/* ENABLE_EXTENDED_FLAGS makes the quick-edit/insert bits take effect. */
						SetConsoleMode (eiffeltui_w32_in, eiffeltui_w32_orig_in_mode | 0x0080);
					}
					if (eiffeltui_w32_out_saved) {
						SetConsoleMode (eiffeltui_w32_out, eiffeltui_w32_orig_out_mode);
					}
					if (eiffeltui_w32_orig_in_cp != 0) SetConsoleCP (eiffeltui_w32_orig_in_cp);
					if (eiffeltui_w32_orig_out_cp != 0) SetConsoleOutputCP (eiffeltui_w32_orig_out_cp);
				}

				static BOOL WINAPI eiffeltui_w32_ctrl_handler (DWORD a_type)
				{
					DWORD l_written = 0;
					char l_output [sizeof (eiffeltui_w32_reset) + sizeof (eiffeltui_w32_pop_title)];
					switch (a_type) {
						case CTRL_C_EVENT:
						case CTRL_BREAK_EVENT:
						case CTRL_CLOSE_EVENT:
						case CTRL_LOGOFF_EVENT:
						case CTRL_SHUTDOWN_EVENT:
							if (eiffeltui_w32_deferring
								&& InterlockedCompareExchange (&eiffeltui_w32_pending, (LONG) a_type + 1, 0) == 0
									/* Check again: if the loop stopped deferring meanwhile, it may
									 * have looked for a request before this one was recorded. */
								&& InterlockedCompareExchange (&eiffeltui_w32_deferring, 0, 0)) {
								if (a_type == CTRL_C_EVENT || a_type == CTRL_BREAK_EVENT) {
										/* Handled: the loop restores the console, then ends the process. */
									return TRUE;
								}
									/* The process ends when this handler returns: give the loop a
									 * moment to restore the console first (the system allows 5 s). */
								if (eiffeltui_w32_restored != NULL
									&& WaitForSingleObject (eiffeltui_w32_restored, 3000) == WAIT_OBJECT_0) {
									return FALSE;
								}
							}
								/* Not deferred, a second request, or the loop did not answer: restore here. */
							if (eiffeltui_w32_out != INVALID_HANDLE_VALUE) {
								WriteConsoleA (eiffeltui_w32_out, l_output, eiffeltui_w32_reset_output (l_output), &l_written, NULL);
							}
							eiffeltui_w32_restore_modes ();
							break;
						default:
							break;
					}
						/* Chain to the next handler (default termination / Eiffel runtime). */
					return FALSE;
				}

				void eiffeltui_w32_set_deferring (int a_on)
				{
					if (a_on && eiffeltui_w32_restored == NULL) {
						eiffeltui_w32_restored = CreateEventW (NULL, TRUE, FALSE, NULL);
					}
					InterlockedExchange (&eiffeltui_w32_deferring, a_on ? 1 : 0);
				}

				void eiffeltui_w32_finish (void)
				{
					if (eiffeltui_w32_restored != NULL) {
						SetEvent (eiffeltui_w32_restored);
					}
						/* The exit status of the default Ctrl handler. */
					ExitProcess ((UINT) 0xC000013AL);
				}

				void eiffeltui_w32_install_ctrl_handler (void)
				{
					if (!eiffeltui_w32_handler_installed) {
						if (SetConsoleCtrlHandler (eiffeltui_w32_ctrl_handler, TRUE)) {
							eiffeltui_w32_handler_installed = 1;
						}
					}
				}

					/* Test hooks: is the handler in the process handler list, and run it as the
					 * system would for `a_type` (without delivering a real Ctrl event, which would
					 * reach every process attached to the console). */
				int eiffeltui_w32_ctrl_handler_registered (void)
				{
						/* Removing succeeds only for a registered handler; put it back at once. */
					if (SetConsoleCtrlHandler (eiffeltui_w32_ctrl_handler, FALSE)) {
						SetConsoleCtrlHandler (eiffeltui_w32_ctrl_handler, TRUE);
						return 1;
					}
					return 0;
				}

				int eiffeltui_w32_invoke_ctrl_handler (DWORD a_type)
				{
					return (int) eiffeltui_w32_ctrl_handler (a_type);
				}

					/* Clipboard read (P2b K4). Open the clipboard (another program may hold it:
					 * try again every 10 ms, 10 times, about 100 ms in all), take its
					 * CF_UNICODETEXT text, copy it into a malloc'd buffer (no terminator) and close
					 * it. `*a_status': 1 text (a NULL result with `*a_count' 0 for an empty
					 * clipboard or one with no text), 2 not opened, 3 more than `a_max' UTF-16
					 * units (nothing copied). The CLIPBOARD_EVENT status constants. Only the first
					 * `a_max' + 1 units are scanned for the terminator, so a huge text costs
					 * nothing. The caller frees the result with free (). */
				WCHAR *eiffeltui_w32_clipboard_read (int a_max, int *a_status, int *a_count)
				{
					int l_try;
					BOOL l_open = FALSE;
					HANDLE l_data;
					const WCHAR *l_text;
					SIZE_T l_units, l_len;
					WCHAR *l_copy = NULL;

					*a_count = 0;
					for (l_try = 0; l_try <= 10; l_try++) {
						if (l_try > 0) {
							Sleep (10);
						}
						l_open = OpenClipboard (NULL);
						if (l_open) {
							break;
						}
					}
					if (!l_open) {
						*a_status = 2;
						return NULL;
					}
					*a_status = 1;
					l_data = GetClipboardData (CF_UNICODETEXT);
					if (l_data != NULL) {
						l_text = (const WCHAR *) GlobalLock (l_data);
						if (l_text != NULL) {
							l_units = GlobalSize (l_data) / sizeof (WCHAR);
							for (l_len = 0; l_len < l_units && l_len <= (SIZE_T) a_max && l_text [l_len] != 0; l_len++) {
							}
							if (l_len > (SIZE_T) a_max) {
								*a_status = 3;
							} else if (l_len > 0) {
								l_copy = (WCHAR *) malloc (l_len * sizeof (WCHAR));
								if (l_copy != NULL) {
									CopyMemory (l_copy, l_text, l_len * sizeof (WCHAR));
									*a_count = (int) l_len;
								} else {
									*a_status = 2;
								}
							}
							GlobalUnlock (l_data);
						}
					}
					CloseClipboard ();
					return l_copy;
				}

				static void eiffeltui_w32_runtime_epilogue (void)
				{
			]"
		end

	c_win32_init
			-- Cache console handles (opening CONIN$/CONOUT$ once when std handles are redirected).
		external
			"C inline use <windows.h>"
		alias
			"[
				extern void eiffeltui_w32_init (void);
				eiffeltui_w32_init ();
			]"
		end

	c_win32_enable_vt_mode: BOOLEAN
			-- Enable ENABLE_VIRTUAL_TERMINAL_PROCESSING and UTF-8 code pages, saving originals first
			-- (opening the console again if the handle kept is not a console any more).
		external
			"C inline use <windows.h>"
		alias
			"[
				extern HANDLE eiffeltui_w32_out;
				extern void eiffeltui_w32_save (void);
				extern void eiffeltui_w32_init (void);
				DWORD l_mode = 0;
					/* (Open the console again if the handle kept is not a console any more.) */
				eiffeltui_w32_init ();
				if (eiffeltui_w32_out == INVALID_HANDLE_VALUE || !GetConsoleMode (eiffeltui_w32_out, &l_mode)) {
					return EIF_TRUE; /* Not a console: nothing to enable. */
				}
				eiffeltui_w32_save ();
				l_mode |= 0x0004; /* ENABLE_VIRTUAL_TERMINAL_PROCESSING */
				l_mode |= 0x0008; /* DISABLE_NEWLINE_AUTO_RETURN */
				SetConsoleOutputCP (65001); /* CP_UTF8 */
				SetConsoleCP (65001);
				return (EIF_BOOLEAN) (SetConsoleMode (eiffeltui_w32_out, l_mode) != 0);
			]"
		end

	c_win32_get_console_size (a_cols, a_rows: TYPED_POINTER [INTEGER]): BOOLEAN
			-- Query current console window dimensions.
		external
			"C inline use <windows.h>"
		alias
			"[
				extern HANDLE eiffeltui_w32_out;
				CONSOLE_SCREEN_BUFFER_INFO csbi;
				if (eiffeltui_w32_out == INVALID_HANDLE_VALUE || !GetConsoleScreenBufferInfo (eiffeltui_w32_out, &csbi)) {
					return EIF_FALSE;
				}
				*(EIF_INTEGER *)$a_cols = csbi.srWindow.Right - csbi.srWindow.Left + 1;
				*(EIF_INTEGER *)$a_rows = csbi.srWindow.Bottom - csbi.srWindow.Top + 1;
				return EIF_TRUE;
			]"
		end

	c_win32_enable_raw_mode: BOOLEAN
			-- Disable line input, echo and processed input; enable VT input. Saves originals first.
		external
			"C inline use <windows.h>"
		alias
			"[
				extern HANDLE eiffeltui_w32_in;
				extern void eiffeltui_w32_save (void);
				DWORD l_mode = 0;
				if (eiffeltui_w32_in == INVALID_HANDLE_VALUE || !GetConsoleMode (eiffeltui_w32_in, &l_mode)) {
					return EIF_TRUE; /* Not a console: nothing to change. */
				}
				eiffeltui_w32_save ();
				l_mode &= ~(0x0001 | 0x0002 | 0x0004); /* PROCESSED | LINE | ECHO */
				l_mode |= 0x0200; /* ENABLE_VIRTUAL_TERMINAL_INPUT */
				return (EIF_BOOLEAN) (SetConsoleMode (eiffeltui_w32_in, l_mode) != 0);
			]"
		end

	c_win32_disable_raw_mode: BOOLEAN
			-- Restore the raw-mode bits (processed, line, echo, VT input) to their original values.
		external
			"C inline use <windows.h>"
		alias
			"[
				extern HANDLE eiffeltui_w32_in;
				extern int eiffeltui_w32_in_saved;
				extern DWORD eiffeltui_w32_orig_in_mode;
				const DWORD l_mask = 0x0001 | 0x0002 | 0x0004 | 0x0200;
				DWORD l_mode = 0;
				if (eiffeltui_w32_in == INVALID_HANDLE_VALUE || !GetConsoleMode (eiffeltui_w32_in, &l_mode)) {
					return EIF_TRUE;
				}
				if (eiffeltui_w32_in_saved) {
					l_mode = (l_mode & ~l_mask) | (eiffeltui_w32_orig_in_mode & l_mask);
				} else {
					l_mode = (l_mode | 0x0001 | 0x0002 | 0x0004) & ~0x0200;
				}
				return (EIF_BOOLEAN) (SetConsoleMode (eiffeltui_w32_in, l_mode) != 0);
			]"
		end

	c_win32_enable_mouse: BOOLEAN
			-- Enable mouse input and disable quick-edit mode. Saves originals first.
		external
			"C inline use <windows.h>"
		alias
			"[
				extern HANDLE eiffeltui_w32_in;
				extern void eiffeltui_w32_save (void);
				DWORD l_mode = 0;
				if (eiffeltui_w32_in == INVALID_HANDLE_VALUE || !GetConsoleMode (eiffeltui_w32_in, &l_mode)) {
					return EIF_TRUE;
				}
				eiffeltui_w32_save ();
				l_mode |= 0x0080;  /* ENABLE_EXTENDED_FLAGS */
				l_mode &= ~0x0040; /* ENABLE_QUICK_EDIT_MODE */
				l_mode |= 0x0010;  /* ENABLE_MOUSE_INPUT */
				return (EIF_BOOLEAN) (SetConsoleMode (eiffeltui_w32_in, l_mode) != 0);
			]"
		end

	c_win32_disable_mouse: BOOLEAN
			-- Restore the original quick-edit and mouse-input bits.
		external
			"C inline use <windows.h>"
		alias
			"[
				extern HANDLE eiffeltui_w32_in;
				extern int eiffeltui_w32_in_saved;
				extern DWORD eiffeltui_w32_orig_in_mode;
				const DWORD l_mask = 0x0040 | 0x0010;
				DWORD l_mode = 0;
				if (eiffeltui_w32_in == INVALID_HANDLE_VALUE || !GetConsoleMode (eiffeltui_w32_in, &l_mode)) {
					return EIF_TRUE;
				}
				if (eiffeltui_w32_in_saved) {
					l_mode = (l_mode & ~l_mask) | (eiffeltui_w32_orig_in_mode & l_mask);
				} else {
					l_mode = (l_mode | 0x0040) & ~0x0010;
				}
				l_mode |= 0x0080; /* ENABLE_EXTENDED_FLAGS */
				return (EIF_BOOLEAN) (SetConsoleMode (eiffeltui_w32_in, l_mode) != 0);
			]"
		end

	c_win32_restore_modes
			-- Restore the exact original input/output modes and code pages.
		external
			"C inline use <windows.h>"
		alias
			"[
				extern void eiffeltui_w32_restore_modes (void);
				eiffeltui_w32_restore_modes ();
			]"
		end

	c_win32_read_unit (a_timeout_ms: INTEGER; a_enhanced: BOOLEAN): INTEGER
			-- Wait up to `a_timeout_ms` for a console event record.
			-- In enhanced mode, synthesizes Kitty escape sequences for key-up (!bKeyDown)
			-- records and for key-down records of a key already down (repeats, P2 T5),
			-- streaming them as byte units. The keys down are tracked only while `a_enhanced`
			-- (see `eiffeltui_w32_keys_epoch` in `c_win32_define_runtime`).
			-- Returns (repeat_count << 16) | utf16_unit, or -1 when timeout expires.
		external
			"C blocking inline use <windows.h>, <stdio.h>"
		alias
			"[
				extern HANDLE eiffeltui_w32_in;
				extern unsigned char eiffeltui_w32_keys_down [256];
				extern int eiffeltui_w32_keys_down_count;
				extern unsigned int eiffeltui_w32_last_char;
				extern void eiffeltui_w32_forget_keys (void);
				extern void eiffeltui_w32_check_keys (int a_enhanced);
				extern int eiffeltui_w32_vt_step (unsigned int a_c);
				extern int eiffeltui_w32_is_tracked_key (WORD a_vk);
				extern int eiffeltui_w32_is_modifier_key (WORD a_vk);
				extern int eiffeltui_w32_kitty_key (char *a_buf, const KEY_EVENT_RECORD *a_kev, unsigned int a_code, int a_type);
				extern int eiffeltui_w32_kitty_char (char *a_buf, unsigned int a_code, int a_type, int a_shift);
				extern int eiffeltui_w32_shift_down;
				extern char eiffeltui_w32_last_seq [16];
				extern int eiffeltui_w32_last_seq_len;
				extern int eiffeltui_w32_keyups_seen;
				extern int eiffeltui_w32_vt_state;
				extern int eiffeltui_w32_vt_in_paste;
				extern int eiffeltui_w32_take_key_seq (char *a_seq, int *a_seq_len, char *a_kitty, int *a_kitty_len);
					/* Room for 64 repeats (`Max_repeat') of the longest repeat sequence of a
					 * key-down record (12 bytes: a BMP code point, one modifier digit). */
				static char l_seq_buf[1024];
				static int l_seq_pos = 0;
				static int l_seq_len = 0;
					/* High surrogate of a key-up record, waiting for its low surrogate. */
				static unsigned int l_up_high = 0;

				if (l_seq_pos < l_seq_len) {
					unsigned char c = (unsigned char) l_seq_buf[l_seq_pos++];
					return (1 << 16) | (EIF_INTEGER) c;
				}
				l_seq_pos = 0;
				l_seq_len = 0;
				eiffeltui_w32_check_keys ($a_enhanced ? 1 : 0);

				ULONGLONG l_deadline = GetTickCount64 () + (ULONGLONG) $a_timeout_ms;
				for (;;) {
					DWORD l_count = 0;
					ULONGLONG l_now;
					if (eiffeltui_w32_in == INVALID_HANDLE_VALUE || !GetNumberOfConsoleInputEvents (eiffeltui_w32_in, &l_count)) {
							/* Not a console (redirected stdin): honour the timeout instead of spinning. */
						if ($a_timeout_ms > 0) Sleep ((DWORD) $a_timeout_ms);
						return -1;
					}
					while (l_count > 0) {
						INPUT_RECORD l_rec;
						DWORD l_read = 0;
						if (!ReadConsoleInputW (eiffeltui_w32_in, &l_rec, 1, &l_read) || l_read == 0) {
							return -1;
						}
						l_count--;
						if (l_rec.EventType == KEY_EVENT) {
							KEY_EVENT_RECORD* kev = &l_rec.Event.KeyEvent;
							if (kev->wVirtualKeyCode == VK_SHIFT || kev->wVirtualKeyCode == VK_LSHIFT || kev->wVirtualKeyCode == VK_RSHIFT) {
								eiffeltui_w32_shift_down = kev->bKeyDown ? 1 : 0;
							} else if (kev->wVirtualKeyCode != 0) {
								eiffeltui_w32_shift_down = (kev->dwControlKeyState & SHIFT_PRESSED) ? 1 : 0;
							}
							if (kev->bKeyDown) {
								WORD vk = kev->wVirtualKeyCode;
								unsigned int l_unit = (unsigned int) kev->uChar.UnicodeChar;
								EIF_INTEGER l_repeat = (EIF_INTEGER) kev->wRepeatCount;
								int l_lone = 0;
								int l_esc_start = 0;
								if (l_repeat < 1) l_repeat = 1;
								if (l_repeat > 0x7FFF) l_repeat = 0x7FFF;
								if (vk == 0 && l_unit != 0) {
										/* The VT stream is followed also without enhancement, so that
										 * turning it on inside a sequence does not misread the rest */
									int l_was_ground = (eiffeltui_w32_vt_state == 0);
									l_lone = eiffeltui_w32_vt_step (l_unit);
									l_esc_start = (l_unit == 27 && l_was_ground && !eiffeltui_w32_vt_in_paste);
								}
								if ($a_enhanced) {
										/* P2 T5: a key-down record of a key already down is an
										 * auto-repeat, sent as Kitty repeats (`:2'). A record of a key
										 * not down yet gives one press (the legacy text below) and its
										 * other `wRepeatCount' strokes as repeats. */
									int l_was_down = -1; /* -1: not a key tracked here */
									if (vk == 0 && l_esc_start) {
											/* Review fix #3: the VT translation of a whole key (arrow,
											 * F-key, Alt+key...) is one key: a second one with no key-up
											 * between is its auto-repeat, sent in its Kitty form */
										char l_tok [16];
										char l_kitty [32];
										int l_tok_len = 0, l_kitty_len = 0;
										if (eiffeltui_w32_take_key_seq (l_tok, &l_tok_len, l_kitty, &l_kitty_len)) {
											int l_same = eiffeltui_w32_keyups_seen && eiffeltui_w32_last_seq_len == l_tok_len;
											int j;
											for (j = 0; l_same && j < l_tok_len; j++) {
												l_same = (eiffeltui_w32_last_seq [j] == l_tok [j]);
											}
											eiffeltui_w32_last_char = 0;
											l_seq_pos = 0;
											if (l_same) {
												CopyMemory (l_seq_buf, l_kitty, l_kitty_len);
												l_seq_len = l_kitty_len;
												return (1 << 16) | (EIF_INTEGER) (unsigned char) l_seq_buf[l_seq_pos++];
											}
											CopyMemory (eiffeltui_w32_last_seq, l_tok, l_tok_len);
											eiffeltui_w32_last_seq_len = l_tok_len;
												/* The press: the sequence as it came, ESC now, the rest next */
											CopyMemory (l_seq_buf, l_tok + 1, l_tok_len - 1);
											l_seq_len = l_tok_len - 1;
											return (1 << 16) | 27;
										}
											/* Not a key (mouse report, reply, focus, an Esc key alone) */
										eiffeltui_w32_last_char = 0;
										eiffeltui_w32_last_seq_len = 0;
									} else if (vk == 0) {
										if (l_lone && !(l_unit >= 0xD800 && l_unit <= 0xDFFF)) {
												/* Review fix #2: repeats only from a console that sends key-ups */
											if (eiffeltui_w32_keyups_seen) {
												l_was_down = (eiffeltui_w32_last_char == l_unit);
											}
											eiffeltui_w32_last_char = l_unit;
										} else {
											eiffeltui_w32_last_char = 0;
										}
										eiffeltui_w32_last_seq_len = 0;
									} else {
											/* Another key: the last character typed no longer repeats */
										eiffeltui_w32_last_char = 0;
										eiffeltui_w32_last_seq_len = 0;
										if (eiffeltui_w32_is_tracked_key (vk)) {
											l_was_down = eiffeltui_w32_keys_down [vk];
											if (!l_was_down) {
												eiffeltui_w32_keys_down [vk] = 1;
												eiffeltui_w32_keys_down_count++;
											}
										}
									}
									if (l_was_down >= 0 && l_unit != 0 && !(l_unit >= 0xD800 && l_unit <= 0xDFFF)) {
										int l_repeats = l_was_down ? l_repeat : l_repeat - 1;
										if (l_repeats > 64) l_repeats = 64; /* `Max_repeat' */
										if (l_repeats > 0) {
											char l_one [32];
											int l_len;
											if (vk == 0) {
												l_len = eiffeltui_w32_kitty_char (l_one, l_unit, 2, eiffeltui_w32_shift_down);
											} else {
												l_len = eiffeltui_w32_kitty_key (l_one, kev, l_unit, 2);
											}
											if (l_len > 0) {
												int i;
												for (i = 0; i < l_repeats; i++) {
													CopyMemory (l_seq_buf + i * l_len, l_one, l_len);
												}
												l_seq_len = l_repeats * l_len;
												l_seq_pos = 0;
												if (l_was_down) {
													return (1 << 16) | (EIF_INTEGER) (unsigned char) l_seq_buf[l_seq_pos++];
												}
													/* The press first; the next calls return the repeats */
												return (1 << 16) | (EIF_INTEGER) l_unit;
											}
												/* No Kitty form for this key: the legacy text, as before */
										}
									}
								}
									/* Key-down records keep the legacy text path: like a Kitty terminal
									 * without "report all keys as escape codes", text keys arrive as text.
									 * Without enhancement auto-repeats arrive the same way, as presses. */
								if (l_unit != 0) {
									return (l_repeat << 16) | (EIF_INTEGER) (unsigned short) l_unit;
								}
							} else if ($a_enhanced) {
								WORD vk = kev->wVirtualKeyCode;
								unsigned int l_unit = (unsigned int) kev->uChar.UnicodeChar;
								unsigned int l_high = l_up_high;
								if (eiffeltui_w32_is_tracked_key (vk) && eiffeltui_w32_keys_down [vk]) {
									eiffeltui_w32_keys_down [vk] = 0;
									eiffeltui_w32_keys_down_count--;
								}
								if (vk != 0 && !eiffeltui_w32_is_modifier_key (vk)) {
										/* A key let go: the last key typed was that one, or another key
										 * was pressed since. Letting go of a modifier keeps it (a held key
										 * goes on repeating). This console sends key-ups: records
										 * without a key code may give repeats (review fix #2). */
									eiffeltui_w32_last_char = 0;
									eiffeltui_w32_last_seq_len = 0;
									eiffeltui_w32_keyups_seen = 1;
								}
								l_up_high = 0;
								l_seq_len = 0;
								if (l_unit >= 0xD800 && l_unit <= 0xDBFF) {
										/* A character above U+FFFF is released as two records (its UTF-16 halves):
										 * keep the high half, and report the code point with the low half. A half
										 * without its partner is dropped. */
									l_up_high = l_unit;
									continue;
								}
								if (l_unit >= 0xDC00 && l_unit <= 0xDFFF) {
									if (l_high != 0) {
										l_seq_len = eiffeltui_w32_kitty_key (l_seq_buf, kev, 0x10000 + ((l_high - 0xD800) << 10) + (l_unit - 0xDC00), 3);
									}
								} else {
									l_seq_len = eiffeltui_w32_kitty_key (l_seq_buf, kev, l_unit, 3);
								}
								if (l_seq_len > 0) {
									l_seq_pos = 0;
									return (1 << 16) | (EIF_INTEGER) (unsigned char) l_seq_buf[l_seq_pos++];
								}
							}
						} else if (l_rec.EventType == FOCUS_EVENT && !l_rec.Event.FocusEvent.bSetFocus) {
								/* P2 T5: keys let go while another window has the focus send no
								 * key-up here: forget them, so that the next key-down is a press. */
							eiffeltui_w32_forget_keys ();
						}
					}
					l_now = GetTickCount64 ();
					if (l_now >= l_deadline) {
						return -1;
					}
					if (WaitForSingleObject (eiffeltui_w32_in, (DWORD) (l_deadline - l_now)) != WAIT_OBJECT_0) {
						return -1;
					}
				}
			]"
		end

	c_win32_forget_keys_down
			-- Make the reader of console input forget the keys it holds as down, at its next
			-- read (P2 T5). Safe from any thread: only the reader touches its set of keys.
		external
			"C inline use <windows.h>"
		alias
			"[
				extern volatile LONG eiffeltui_w32_keys_epoch;
				InterlockedIncrement (&eiffeltui_w32_keys_epoch);
			]"
		end

	c_win32_is_deferring: BOOLEAN
			-- Are Ctrl events deferred?
		external
			"C inline use <windows.h>"
		alias
			"[
				extern volatile LONG eiffeltui_w32_deferring;
				return (EIF_BOOLEAN) (eiffeltui_w32_deferring != 0);
			]"
		end

	c_win32_set_deferring (a_on: BOOLEAN)
			-- Defer Ctrl events (`a_on`) or not.
		external
			"C inline use <windows.h>"
		alias
			"[
				extern void eiffeltui_w32_set_deferring (int a_on);
				eiffeltui_w32_set_deferring ($a_on ? 1 : 0);
			]"
		end

	c_win32_title_pushed: BOOLEAN
			-- Is the console's title pushed, for the Ctrl handler?
		external
			"C inline use <windows.h>"
		alias
			"[
				extern volatile LONG eiffeltui_w32_title_pushed;
				return (EIF_BOOLEAN) (InterlockedCompareExchange (&eiffeltui_w32_title_pushed, 0, 0) != 0);
			]"
		end

	c_win32_set_title_pushed (a_pushed: BOOLEAN)
			-- Record whether the console's title is pushed (`a_pushed`).
		external
			"C inline use <windows.h>"
		alias
			"[
				extern volatile LONG eiffeltui_w32_title_pushed;
				InterlockedExchange (&eiffeltui_w32_title_pushed, $a_pushed ? 1 : 0);
			]"
		end

	c_win32_pending: INTEGER
			-- Type of the deferred Ctrl event, or -1
		external
			"C inline use <windows.h>"
		alias
			"[
				extern volatile LONG eiffeltui_w32_pending;
				return (EIF_INTEGER) (InterlockedCompareExchange (&eiffeltui_w32_pending, 0, 0) - 1);
			]"
		end

	c_win32_discard
			-- Forget the deferred Ctrl event.
		external
			"C inline use <windows.h>"
		alias
			"[
				extern volatile LONG eiffeltui_w32_pending;
				InterlockedExchange (&eiffeltui_w32_pending, 0);
			]"
		end

	c_win32_finish
			-- Release a waiting handler and end the process.
		external
			"C inline use <windows.h>"
		alias
			"[
				extern void eiffeltui_w32_finish (void);
				eiffeltui_w32_finish ();
			]"
		end

	c_win32_clipboard_read (a_max: INTEGER; a_status, a_count: TYPED_POINTER [INTEGER]): POINTER
			-- The clipboard's text as `a_count` UTF-16 units in a buffer to `c_free`, or NULL;
			-- `a_status` 1 text, 2 not opened, 3 too large (see `eiffeltui_w32_clipboard_read`).
		external
			"C inline use <windows.h>"
		alias
			"[
				extern WCHAR *eiffeltui_w32_clipboard_read (int a_max, int *a_status, int *a_count);
				return (EIF_POINTER) eiffeltui_w32_clipboard_read ((int) $a_max, (int *) $a_status, (int *) $a_count);
			]"
		end

	c_free (a_buffer: POINTER)
			-- Free `a_buffer`, allocated by malloc in C.
		external
			"C inline use <stdlib.h>"
		alias
			"[
				free ($a_buffer);
			]"
		end

	c_win32_install_ctrl_handler
			-- Register the console Ctrl handler (once per process).
		external
			"C inline use <windows.h>"
		alias
			"[
				extern void eiffeltui_w32_install_ctrl_handler (void);
				eiffeltui_w32_install_ctrl_handler ();
			]"
		end

invariant
	valid_pending_surrogate: pending_high_surrogate = 0 or (pending_high_surrogate >= 0xD800 and pending_high_surrogate <= 0xDBFF)

end
