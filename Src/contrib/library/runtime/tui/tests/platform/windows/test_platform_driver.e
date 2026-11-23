note
	description: "[
		Windows-only driver tests (this cluster is selected by the ECF on Windows):
		UTF-16 console input re-encoded as UTF-8 bytes, and exact mode restoration.
		The `test_win32_vt_*' tests inject console records with ENABLE_VIRTUAL_TERMINAL_INPUT
		on. They run only in a classic console (conhost): a console hosted by ConPTY, as in
		Windows Terminal, drops injected key-up records, and there they are not run and print
		a [NOTE] line (`vt_injection_works').
		The native clipboard read (P2b K4) is tested by TEST_WIN32_CLIPBOARD, run from `tests';
		it touches the developer's clipboard and puts its text back.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_PLATFORM_DRIVER

inherit
	EQA_TEST_SET

feature -- Registry

	tests: ARRAYED_LIST [TUPLE [name: STRING; routine: PROCEDURE]]
			-- Tests of this platform, for TEST_APP.
		do
			create Result.make (3)
			Result.extend (["test_win32_utf16_to_utf8", agent test_win32_utf16_to_utf8])
			Result.extend (["test_win32_utf16_feeds_parser", agent test_win32_utf16_feeds_parser])
			Result.extend (["test_win32_restores_exact_modes", agent test_win32_restores_exact_modes])
			Result.extend (["test_win32_ctrl_handler_restores_console", agent test_win32_ctrl_handler_restores_console])
			Result.extend (["test_win32_ctrl_handler_defers_to_loop", agent test_win32_ctrl_handler_defers_to_loop])
			Result.extend (["test_win32_key_release_records_bridged", agent test_win32_key_release_records_bridged])
			Result.extend (["test_win32_astral_key_release", agent test_win32_astral_key_release])
			Result.extend (["test_win32_held_key_repeats", agent test_win32_held_key_repeats])
			Result.extend (["test_win32_two_held_keys_tracked_apart", agent test_win32_two_held_keys_tracked_apart])
			Result.extend (["test_win32_focus_loss_forgets_held_keys", agent test_win32_focus_loss_forgets_held_keys])
			Result.extend (["test_win32_repeat_count_gives_repeats", agent test_win32_repeat_count_gives_repeats])
			Result.extend (["test_win32_no_repeats_without_enhancement", agent test_win32_no_repeats_without_enhancement])
			Result.extend (["test_win32_vt_held_key_repeats", agent test_win32_vt_held_key_repeats])
			Result.extend (["test_win32_vt_sequences_never_repeat", agent test_win32_vt_sequences_never_repeat])
			Result.extend (["test_win32_vt_focus_loss_forgets_held_keys", agent test_win32_vt_focus_loss_forgets_held_keys])
			Result.extend (["test_win32_vt_key_sequences_repeat", agent test_win32_vt_key_sequences_repeat])
			Result.extend (["test_win32_vt_paste_state_reset", agent test_win32_vt_paste_state_reset])
			Result.extend (["test_win32_vt_osc_reply_never_repeats", agent test_win32_vt_osc_reply_never_repeats])
			Result.extend (["test_win32_vt_osc_unterminated_ends", agent test_win32_vt_osc_unterminated_ends])
			Result.extend (["test_win32_vt_osc_alt_bracket_kept", agent test_win32_vt_osc_alt_bracket_kept])
			Result.extend (["test_win32_driver_provides_keyboard_enhancement", agent test_win32_driver_provides_keyboard_enhancement])
			Result.extend (["test_win32_suspend_is_noop", agent test_win32_suspend_is_noop])
				-- The clipboard read (P2b K4), kept in one class: it touches the clipboard
			Result.append ((create {TEST_WIN32_CLIPBOARD}).tests)
		end

feature -- Tests

	test_win32_utf16_to_utf8
			-- BMP characters, surrogate pairs and repeat counts become the right UTF-8 bytes.
		local
			l_probe: WIN32_DRIVER_PROBE
		do
			create l_probe
			-- U+00F1 'ñ' -> C3 B1
			l_probe.enqueue_utf16_unit (0x00F1, 1)
			assert_bytes (l_probe, <<0xC3, 0xB1>>, "n tilde")
			-- U+65E5 -> E6 97 A5
			l_probe.enqueue_utf16_unit (0x65E5, 1)
			assert_bytes (l_probe, <<0xE6, 0x97, 0xA5>>, "nichi")
			-- U+1F600 as surrogate pair D83D DE00 -> F0 9F 98 80
			l_probe.enqueue_utf16_unit (0xD83D, 1)
			l_probe.enqueue_utf16_unit (0xDE00, 1)
			assert_bytes (l_probe, <<0xF0, 0x9F, 0x98, 0x80>>, "surrogate pair")
			-- Auto-repeat count 3
			l_probe.enqueue_utf16_unit (('a').code, 3)
			assert_bytes (l_probe, <<0x61, 0x61, 0x61>>, "repeat")
			-- A lone low surrogate is dropped
			l_probe.enqueue_utf16_unit (0xDE00, 1)
			l_probe.enqueue_utf16_unit (('z').code, 1)
			assert_bytes (l_probe, <<0x7A>>, "lone low surrogate dropped")
		end

	test_win32_utf16_feeds_parser
			-- Bytes produced from UTF-16 decode back to the same character in ANSI_INPUT_PARSER.
		local
			l_probe: WIN32_DRIVER_PROBE
			l_parser: ANSI_INPUT_PARSER
			i: INTEGER
		do
			create l_probe
			create l_parser.make
			l_probe.enqueue_utf16_unit (0x00F1, 1)
			from
				i := 1
			until
				i > 2
			loop
				l_parser.parse_code (l_probe.read_char_with_timeout (0).to_natural_32)
				i := i + 1
			end
			assert ("one event", l_parser.events.count = 1)
			assert ("n tilde key", attached {KEY_EVENT} l_parser.events.first as k and then
				(k.code.is_char and then k.code.character.natural_32_code = 0xF1))
		end

	test_win32_restores_exact_modes
			-- After VT, raw and mouse changes, restore_modes puts back the exact original modes.
		local
			l_probe: WIN32_DRIVER_PROBE
			l_before, l_after: TUPLE [input, output: NATURAL_32]
		do
			create l_probe
			if l_probe.has_console_modes then
				l_before := l_probe.console_modes
				assert ("vt", l_probe.enable_vt_mode)
				assert ("raw", l_probe.enable_raw_mode)
				assert ("mouse", l_probe.enable_mouse)
				l_probe.restore_modes
				l_after := l_probe.console_modes
				-- ENABLE_EXTENDED_FLAGS (0x80) is always set on restore so quick-edit bits apply
				assert ("input mode restored", (l_after.input | 0x80) = (l_before.input | 0x80))
				assert ("output mode restored", l_after.output = l_before.output)
			else
				-- No console attached (redirected run): modes cannot be compared,
				-- but the driver state must still be reset
				assert ("raw without console", l_probe.enable_raw_mode)
				l_probe.restore_modes
				assert ("not raw after restore", not l_probe.is_raw)
			end
		end

	test_win32_ctrl_handler_restores_console
			-- The Ctrl handler is registered with the system, restores the exact original modes
			-- for the termination events, ignores other events, and chains to the next handler.
			-- What it writes includes the default cursor shape (`reset_sequence`), and the
			-- title pop only after a push (`handler_output`).
		local
			l_probe: WIN32_DRIVER_PROBE
			l_before, l_raw: TUPLE [input, output: NATURAL_32]
			l_type: NATURAL_32
		do
			create l_probe
			-- P2 T1: the reset gives the default cursor shape back, DECSCUSR 0 (crossterm
			-- `SetCursorStyle::DefaultUserShape`, from its documentation; not checked against
			-- the crossterm source), before the cursor is shown
			assert ("reset has the default cursor shape", l_probe.reset_sequence.has_substring ("%/27/[0 q%/27/[?25h"))
			-- P2 W6: motion reporting (any-event tracking, mode 1003) is turned off with the
			-- other mouse modes
			assert ("reset turns motion reporting off", l_probe.reset_sequence.has_substring ("%/27/[?1002l%/27/[?1003l%/27/[?1006l"))
			-- P2 T2: the title pop (XTWINOPS `CSI 23 ; 0 t`) follows the reset only while a
			-- title is pushed, and the handler then clears the push
			l_probe.set_title_pushed (False)
			assert ("no pop without a push", l_probe.handler_output.same_string (l_probe.reset_sequence))
			l_probe.set_title_pushed (True)
			assert ("pop after the reset after a push", l_probe.handler_output.same_string (l_probe.reset_sequence + "%/27/[23;0t"))
			assert ("push cleared by the handler", not l_probe.is_title_pushed)
			assert ("no second pop", l_probe.handler_output.same_string (l_probe.reset_sequence))
			l_probe.install_ctrl_handler
			assert ("handler registered", l_probe.ctrl_handler_registered)
			l_probe.install_ctrl_handler
			assert ("still registered after a second install", l_probe.ctrl_handler_registered)

			if l_probe.has_console_modes then
				l_before := l_probe.console_modes
				-- CTRL_C, CTRL_BREAK, CTRL_CLOSE, CTRL_LOGOFF, CTRL_SHUTDOWN
				across {ARRAY [NATURAL_32]} <<0, 1, 2, 5, 6>> as t loop
					l_type := t
					assert ("raw " + l_type.out, l_probe.enable_raw_mode)
					assert ("mouse " + l_type.out, l_probe.enable_mouse)
					l_probe.set_title_pushed (l_type = 0)
					assert ("modes changed " + l_type.out, (l_probe.console_modes.input | 0x80) /= (l_before.input | 0x80))
					assert ("chains to the next handler " + l_type.out, not l_probe.invoke_ctrl_handler (l_type))
					assert ("input mode restored " + l_type.out, (l_probe.console_modes.input | 0x80) = (l_before.input | 0x80))
					assert ("output mode restored " + l_type.out, l_probe.console_modes.output = l_before.output)
					assert ("title popped by the handler " + l_type.out, not l_probe.is_title_pushed)
				end

				-- An unrelated event leaves the console alone
				assert ("raw", l_probe.enable_raw_mode)
				l_raw := l_probe.console_modes
				assert ("other event chains", not l_probe.invoke_ctrl_handler (99))
				assert ("other event leaves modes", l_probe.console_modes.input = l_raw.input)
				l_probe.restore_modes
			else
				-- No console attached: the handler must still run and chain without failing
				assert ("chains without console", not l_probe.invoke_ctrl_handler (0))
			end
		end

	test_win32_ctrl_handler_defers_to_loop
			-- While deferring (an application loop runs), the real handler records Ctrl+C and
			-- leaves the console alone; a second event is handled at once; a close event with no
			-- loop to answer is restored by the handler after its wait (review finding C5).
		local
			l_probe: WIN32_DRIVER_PROBE
			l_before: TUPLE [input, output: NATURAL_32]
			l_start: INTEGER_64
		do
			create l_probe
			l_probe.install_ctrl_handler
			if l_probe.has_console_modes then
				l_before := l_probe.console_modes
				assert ("raw", l_probe.enable_raw_mode)
				l_probe.set_deferring_termination (True)
				assert ("Ctrl+C handled (recorded)", l_probe.invoke_ctrl_handler (0))
				assert ("request pending", l_probe.has_termination_request and l_probe.termination_request_code = 0)
				assert ("console left to the loop", (l_probe.console_modes.input | 0x80) /= (l_before.input | 0x80))

				assert ("second event chains", not l_probe.invoke_ctrl_handler (1))
				assert ("second event restored at once", (l_probe.console_modes.input | 0x80) = (l_before.input | 0x80))
				assert ("first request kept", l_probe.termination_request_code = 0)
				l_probe.discard_termination_request

				assert ("raw again", l_probe.enable_raw_mode)
				l_start := {MONOTONIC_CLOCK}.milliseconds
				assert ("close chains", not l_probe.invoke_ctrl_handler (2))
				assert ("waited for the loop", {MONOTONIC_CLOCK}.milliseconds - l_start >= 2900)
				assert ("then restored by the handler", (l_probe.console_modes.input | 0x80) = (l_before.input | 0x80))
				l_probe.discard_termination_request
				l_probe.set_deferring_termination (False)
				assert ("not pending", not l_probe.has_termination_request)
			else
				l_probe.set_deferring_termination (True)
				assert ("records without console", l_probe.invoke_ctrl_handler (0))
				l_probe.discard_termination_request
				l_probe.set_deferring_termination (False)
			end
		end

	test_win32_key_release_records_bridged
			-- Real KEY_EVENT records read by the driver: with keyboard enhancement, key-up records
			-- become Kitty release sequences (character, Ctrl+letter, arrow, F3); without it they
			-- are skipped. Key-down records stay presses.
		local
			l_probe: WIN32_DRIVER_PROBE
			l_parser: ANSI_INPUT_PARSER
			l_events: ARRAYED_LIST [KEY_EVENT]
		do
			create l_probe
			if l_probe.has_console_modes then
				l_probe.flush_console_input
				l_probe.enable_keyboard_enhancement
				assert ("down a", l_probe.inject_key (True, 0x41, ('a').natural_32_code.to_natural_16, 0))
				assert ("up a", l_probe.inject_key (False, 0x41, ('a').natural_32_code.to_natural_16, 0))
				assert ("up ctrl+b", l_probe.inject_key (False, 0x42, 2, 0x0008))
				assert ("up arrow", l_probe.inject_key (False, 0x26, 0, 0))
				assert ("up F3", l_probe.inject_key (False, 0x72, 0, 0x0010))
				create l_parser.make
				l_events := read_key_events (l_probe, l_parser)
				assert ("five events", l_events.count = 5)
				if l_events.count = 5 then
					assert ("press a", l_events [1].is_press and l_events [1].code.is_char and then l_events [1].code.character = 'a')
					assert ("release a", l_events [2].is_release and l_events [2].code.is_char and then l_events [2].code.character = 'a')
					assert ("release ctrl+b", l_events [3].is_release and l_events [3].modifiers.is_control and
						l_events [3].code.is_char and then l_events [3].code.character = 'b')
					assert ("release up", l_events [4].is_release and l_events [4].code.is_up)
					assert ("release shift+F3", l_events [5].is_release and l_events [5].modifiers.is_shift and
						l_events [5].code.is_function and l_events [5].code.function_number = 3)
				end

				l_probe.disable_keyboard_enhancement
				assert ("up a again", l_probe.inject_key (False, 0x41, ('a').natural_32_code.to_natural_16, 0))
				create l_parser.make
				assert ("key-up skipped without enhancement", read_key_events (l_probe, l_parser).is_empty)
				l_probe.flush_console_input
			else
				-- No console attached: records cannot be injected
				assert ("no console", not l_probe.has_console_modes)
			end
		end

	test_win32_astral_key_release
			-- A key-up of a character above U+FFFF comes as two records (its UTF-16 halves): the
			-- driver reports one release of the code point (review finding U10; each half used to
			-- become a Kitty code the parser rejects). A half without its partner is dropped.
		local
			l_probe: WIN32_DRIVER_PROBE
			l_parser: ANSI_INPUT_PARSER
			l_events: ARRAYED_LIST [KEY_EVENT]
		do
			create l_probe
			if l_probe.has_console_modes then
				l_probe.flush_console_input
				l_probe.enable_keyboard_enhancement
				-- U+1F600 = D83D DE00, sent with VK_PACKET (0xE7) as an IME or touch keyboard does
				assert ("up high", l_probe.inject_key (False, 0xE7, 0xD83D, 0))
				assert ("up low", l_probe.inject_key (False, 0xE7, 0xDE00, 0))
				-- A lone low half, then a lone high half followed by a plain key
				assert ("up lone low", l_probe.inject_key (False, 0xE7, 0xDE00, 0))
				assert ("up lone high", l_probe.inject_key (False, 0xE7, 0xD83D, 0))
				assert ("up a", l_probe.inject_key (False, 0x41, ('a').natural_32_code.to_natural_16, 0))
				create l_parser.make
				l_events := read_key_events (l_probe, l_parser)
				l_probe.disable_keyboard_enhancement
				l_probe.flush_console_input
				assert ("two events", l_events.count = 2)
				if l_events.count = 2 then
					assert ("release U+1F600", l_events [1].is_release and l_events [1].code.is_char and then
						l_events [1].code.character.natural_32_code = 0x1F600)
					assert ("release a", l_events [2].is_release and l_events [2].code.is_char and then l_events [2].code.character = 'a')
				end
			else
				-- No console attached: records cannot be injected
				assert ("no console", not l_probe.has_console_modes)
			end
		end

	test_win32_held_key_repeats
			-- P2 T5: with keyboard enhancement, a key-down record of a key already down (an
			-- auto-repeat) becomes a Kitty repeat (`:2`), so `is_repeat` is true on Windows:
			-- down, down, down, up gives press, repeat, repeat, release. Also for Ctrl+B (whose
			-- records carry a control character) and Enter.
			-- The console folds equal key-down records written next to each other into one
			-- record with a larger `wRepeatCount` (seen on Windows 11 conhost), so the three
			-- downs are first written apart (a MENU_EVENT record between them, which the driver
			-- ignores), then next to each other: both give the same events.
		local
			l_probe: WIN32_DRIVER_PROBE
		do
			create l_probe
			if l_probe.has_console_modes then
				start_enhanced (l_probe)
				assert ("down a 1", l_probe.inject_key (True, 0x41, 97, 0))
				assert ("apart 1", l_probe.inject_menu_record)
				assert ("down a 2", l_probe.inject_key (True, 0x41, 97, 0))
				assert ("apart 2", l_probe.inject_menu_record)
				assert ("down a 3", l_probe.inject_key (True, 0x41, 97, 0))
				assert ("up a", l_probe.inject_key (False, 0x41, 97, 0))
				assert ("six records", l_probe.pending_record_count = 6)
				assert_trace (l_probe, "p:a r:a r:a x:a", "held a, records apart")
				assert ("down a 1 next", l_probe.inject_key (True, 0x41, 97, 0))
				assert ("down a 2 next", l_probe.inject_key (True, 0x41, 97, 0))
				assert ("down a 3 next", l_probe.inject_key (True, 0x41, 97, 0))
				assert ("up a next", l_probe.inject_key (False, 0x41, 97, 0))
				assert_trace (l_probe, "p:a r:a r:a x:a", "held a, records next to each other")
				-- Ctrl+B: VK 0x42, character 2, LEFT_CTRL_PRESSED
				assert ("down ctrl+b 1", l_probe.inject_key (True, 0x42, 2, 0x0008))
				assert ("down ctrl+b 2", l_probe.inject_key (True, 0x42, 2, 0x0008))
				assert ("up ctrl+b", l_probe.inject_key (False, 0x42, 2, 0x0008))
				assert_trace (l_probe, "p:^b r:^b x:^b", "held ctrl+b")
				-- Enter: VK_RETURN, character 13
				assert ("down enter 1", l_probe.inject_key (True, 0x0D, 13, 0))
				assert ("down enter 2", l_probe.inject_key (True, 0x0D, 13, 0))
				assert ("up enter", l_probe.inject_key (False, 0x0D, 13, 0))
				assert_trace (l_probe, "p:<enter> r:<enter> x:<enter>", "held enter")
				stop_enhanced (l_probe)
			else
				-- No console attached: records cannot be injected
				assert ("no console", not l_probe.has_console_modes)
			end
		end

	test_win32_two_held_keys_tracked_apart
			-- P2 T5: two keys held together are tracked each on its own: a key-up of one does
			-- not end the other. The modifier keys' own records (Shift held, which repeats too)
			-- give no event and do not make the next key a repeat.
		local
			l_probe: WIN32_DRIVER_PROBE
		do
			create l_probe
			if l_probe.has_console_modes then
				start_enhanced (l_probe)
				assert ("down a", l_probe.inject_key (True, 0x41, 97, 0))
				assert ("down b", l_probe.inject_key (True, 0x42, 98, 0))
				assert ("down a again", l_probe.inject_key (True, 0x41, 97, 0))
				assert ("down b again", l_probe.inject_key (True, 0x42, 98, 0))
				assert ("up a", l_probe.inject_key (False, 0x41, 97, 0))
				assert ("down b third", l_probe.inject_key (True, 0x42, 98, 0))
				assert ("down a after its up", l_probe.inject_key (True, 0x41, 97, 0))
				assert ("up b", l_probe.inject_key (False, 0x42, 98, 0))
				assert ("up a 2", l_probe.inject_key (False, 0x41, 97, 0))
				assert_trace (l_probe, "p:a p:b r:a r:b x:a r:b p:a x:b x:a", "two keys")
				-- Shift held (VK_SHIFT, no character, SHIFT_PRESSED), repeating, then A
				assert ("down shift 1", l_probe.inject_key (True, 0x10, 0, 0x0010))
				assert ("down shift 2", l_probe.inject_key (True, 0x10, 0, 0x0010))
				assert ("down shift+a 1", l_probe.inject_key (True, 0x41, 65, 0x0010))
				assert ("down shift+a 2", l_probe.inject_key (True, 0x41, 65, 0x0010))
				assert ("up shift", l_probe.inject_key (False, 0x10, 0, 0))
				-- Shift let go while A is still held: still a repeat of the same key
				assert ("down a 3", l_probe.inject_key (True, 0x41, 97, 0))
				assert ("up a 3", l_probe.inject_key (False, 0x41, 97, 0))
				assert_trace (l_probe, "p:A r:S-A r:a x:a", "shift and a")
				stop_enhanced (l_probe)
			else
				-- No console attached: records cannot be injected
				assert ("no console", not l_probe.has_console_modes)
			end
		end

	test_win32_focus_loss_forgets_held_keys
			-- P2 T5: a key let go in another window sends no key-up here. A focus loss forgets
			-- the keys held, so the next key-down is a press. Turning enhancement off and on
			-- forgets them too.
		local
			l_probe: WIN32_DRIVER_PROBE
		do
			create l_probe
			if l_probe.has_console_modes then
				start_enhanced (l_probe)
				assert ("down a", l_probe.inject_key (True, 0x41, 97, 0))
				assert ("down b", l_probe.inject_key (True, 0x42, 98, 0))
				assert ("focus lost", l_probe.inject_focus (False))
				assert ("focus gained", l_probe.inject_focus (True))
				assert ("down a after focus", l_probe.inject_key (True, 0x41, 97, 0))
				assert ("down b after focus", l_probe.inject_key (True, 0x42, 98, 0))
				assert ("down a held", l_probe.inject_key (True, 0x41, 97, 0))
				assert_trace (l_probe, "p:a p:b p:a p:b r:a", "focus loss")
				-- Enhancement off and on again between two reads
				l_probe.disable_keyboard_enhancement
				l_probe.enable_keyboard_enhancement
				assert ("down a after toggle", l_probe.inject_key (True, 0x41, 97, 0))
				assert ("down a held after toggle", l_probe.inject_key (True, 0x41, 97, 0))
				assert_trace (l_probe, "p:a r:a", "enhancement toggled")
				stop_enhanced (l_probe)
			else
				-- No console attached: records cannot be injected
				assert ("no console", not l_probe.has_console_modes)
			end
		end

	test_win32_repeat_count_gives_repeats
			-- P2 T5: a record with `wRepeatCount` 3 for a key not down gives one press and two
			-- repeats; for a key already down, all of its strokes are repeats.
		local
			l_probe: WIN32_DRIVER_PROBE
		do
			create l_probe
			if l_probe.has_console_modes then
				start_enhanced (l_probe)
				assert ("down a x3", l_probe.inject_key_repeated (True, 0x41, 97, 0, 3))
				-- Apart, so that the console does not fold the two into one record of 5
				assert ("apart", l_probe.inject_menu_record)
				assert ("down a x2", l_probe.inject_key_repeated (True, 0x41, 97, 0, 2))
				assert ("up a", l_probe.inject_key (False, 0x41, 97, 0))
				assert ("four records", l_probe.pending_record_count = 4)
				assert_trace (l_probe, "p:a r:a r:a r:a r:a x:a", "repeat count")
				-- A count of 0 counts as 1 (records apart: the console would fold them into one
				-- record whose count is still 0)
				assert ("down b x0", l_probe.inject_key_repeated (True, 0x42, 98, 0, 0))
				assert ("apart", l_probe.inject_menu_record)
				assert ("down b x0 again", l_probe.inject_key_repeated (True, 0x42, 98, 0, 0))
				assert ("up b", l_probe.inject_key (False, 0x42, 98, 0))
				assert_trace (l_probe, "p:b r:b x:b", "repeat count 0")
				stop_enhanced (l_probe)
			else
				-- No console attached: records cannot be injected
				assert ("no console", not l_probe.has_console_modes)
			end
		end

	test_win32_no_repeats_without_enhancement
			-- P2 T5: without keyboard enhancement nothing changes: every key-down record is a
			-- press (a count of 3 gives three), key-up and focus records give nothing, and the
			-- bytes are the legacy text. A key held while enhancement was off gives a press at
			-- its first key-down once enhancement is on.
		local
			l_probe: WIN32_DRIVER_PROBE
		do
			create l_probe
			if l_probe.has_console_modes then
				l_probe.flush_console_input
				l_probe.disable_keyboard_enhancement
				assert ("down a 1", l_probe.inject_key (True, 0x41, 97, 0))
				assert ("down a 2", l_probe.inject_key (True, 0x41, 97, 0))
				assert ("focus lost", l_probe.inject_focus (False))
				assert ("down a x3", l_probe.inject_key_repeated (True, 0x41, 97, 0, 3))
				assert ("down ctrl+b 1", l_probe.inject_key (True, 0x42, 2, 0x0008))
				assert ("down ctrl+b 2", l_probe.inject_key (True, 0x42, 2, 0x0008))
				assert ("up a", l_probe.inject_key (False, 0x41, 97, 0))
				assert ("up ctrl+b", l_probe.inject_key (False, 0x42, 2, 0x0008))
				assert ("bytes unchanged", read_bytes (l_probe).same_string ("aaaaa%/2/%/2/"))
				-- Held while enhancement was off
				assert ("down a held", l_probe.inject_key (True, 0x41, 97, 0))
				assert ("legacy press", read_bytes (l_probe).same_string ("a"))
				l_probe.enable_keyboard_enhancement
				assert ("down a enhanced", l_probe.inject_key (True, 0x41, 97, 0))
				assert ("down a enhanced 2", l_probe.inject_key (True, 0x41, 97, 0))
				assert ("up a enhanced", l_probe.inject_key (False, 0x41, 97, 0))
				assert_trace (l_probe, "p:a r:a x:a", "turned on while held")
				stop_enhanced (l_probe)
			else
				-- No console attached: records cannot be injected
				assert ("no console", not l_probe.has_console_modes)
			end
		end

	test_win32_vt_held_key_repeats
			-- P2 T5 with ENABLE_VIRTUAL_TERMINAL_INPUT on (raw mode, the path of a real
			-- application): the console replaces each key-down record by records of its VT
			-- characters, with no key code (seen on Windows 11 conhost), and keeps key-up
			-- records as they are. A lone character typed again with no key-up between is a
			-- repeat. Shift's own records do not end it; letting go of Shift does not either,
			-- but the character then changes, so it is a press. A repeat carries Shift while
			-- it is held, as the key's release does (Shift followed from its own records).
		local
			l_probe: WIN32_DRIVER_PROBE
			l_mode: NATURAL_32
		do
			create l_probe
			if vt_injection_works (l_probe, "test_win32_vt_held_key_repeats") then
				l_mode := start_vt_input (l_probe)
				see_a_key_up (l_probe)
				-- Apart: the console folds equal records next to each other into one, and the
				-- VT translation then gives the character once (its count is lost)
				assert ("down a 1", l_probe.inject_key (True, 0x41, 97, 0))
				assert ("apart 1", l_probe.inject_menu_record)
				assert ("down a 2", l_probe.inject_key (True, 0x41, 97, 0))
				assert ("apart 2", l_probe.inject_menu_record)
				assert ("down a 3", l_probe.inject_key (True, 0x41, 97, 0))
				assert ("up a", l_probe.inject_key (False, 0x41, 97, 0))
				assert_trace (l_probe, "p:a r:a r:a x:a", "held a")
				assert ("down ctrl+b 1", l_probe.inject_key (True, 0x42, 2, 0x0008))
				assert ("apart 3", l_probe.inject_menu_record)
				assert ("down ctrl+b 2", l_probe.inject_key (True, 0x42, 2, 0x0008))
				assert ("up ctrl+b", l_probe.inject_key (False, 0x42, 2, 0x0008))
				assert_trace (l_probe, "p:^b r:^b x:^b", "held ctrl+b")
				assert ("down enter 1", l_probe.inject_key (True, 0x0D, 13, 0))
				assert ("apart 4", l_probe.inject_menu_record)
				assert ("down enter 2", l_probe.inject_key (True, 0x0D, 13, 0))
				assert ("up enter", l_probe.inject_key (False, 0x0D, 13, 0))
				assert_trace (l_probe, "p:<enter> r:<enter> x:<enter>", "held enter")
				-- Typing "aa": a key-up between, so two presses
				assert ("type a", l_probe.inject_key (True, 0x41, 97, 0))
				assert ("type a up", l_probe.inject_key (False, 0x41, 97, 0))
				assert ("type a again", l_probe.inject_key (True, 0x41, 97, 0))
				assert ("type a up again", l_probe.inject_key (False, 0x41, 97, 0))
				assert_trace (l_probe, "p:a x:a p:a x:a", "typed twice")
				-- Shift held and repeating, then A held, Shift let go, A still held
				assert ("down shift 1", l_probe.inject_key (True, 0x10, 0, 0x0010))
				assert ("apart 5", l_probe.inject_menu_record)
				assert ("down shift 2", l_probe.inject_key (True, 0x10, 0, 0x0010))
				assert ("down shift+a 1", l_probe.inject_key (True, 0x41, 65, 0x0010))
				assert ("apart 6", l_probe.inject_menu_record)
				assert ("down shift+a 2", l_probe.inject_key (True, 0x41, 65, 0x0010))
				assert ("up shift", l_probe.inject_key (False, 0x10, 0, 0))
				assert ("down a 4", l_probe.inject_key (True, 0x41, 97, 0))
				assert ("apart 7", l_probe.inject_menu_record)
				assert ("down a 5", l_probe.inject_key (True, 0x41, 97, 0))
				assert ("up a 2", l_probe.inject_key (False, 0x41, 97, 0))
				assert_trace (l_probe, "p:A r:S-A p:a r:a x:a", "shift and a")
				-- Two keys: only the last one pressed repeats (as Windows repeats it). Letting
				-- go of the first gives one press of the second (its repeats as before T5)
				assert ("down a 6", l_probe.inject_key (True, 0x41, 97, 0))
				assert ("down b 1", l_probe.inject_key (True, 0x42, 98, 0))
				assert ("apart 8", l_probe.inject_menu_record)
				assert ("down b 2", l_probe.inject_key (True, 0x42, 98, 0))
				assert ("up a 3", l_probe.inject_key (False, 0x41, 97, 0))
				assert ("down b 3", l_probe.inject_key (True, 0x42, 98, 0))
				assert ("apart 9", l_probe.inject_menu_record)
				assert ("down b 4", l_probe.inject_key (True, 0x42, 98, 0))
				assert ("up b", l_probe.inject_key (False, 0x42, 98, 0))
				assert_trace (l_probe, "p:a p:b r:b x:a p:b r:b x:b", "two keys")
				stop_vt_input (l_probe, l_mode)
			else
				-- No console attached, or a host that drops injected key-ups: not run (`vt_injection_works`)
				assert ("not runnable here", not last_vt_injection_works)
			end
		end

	test_win32_vt_sequences_never_repeat
			-- P2 T5 with ENABLE_VIRTUAL_TERMINAL_INPUT on: the characters of escape sequences
			-- (a mouse report with "11;11") and of a bracketed paste ("aa") come as key-down
			-- records with no key code and no key-up between, and none of them is taken for a
			-- repeat. Review fix #2: before the console has sent a key-up, nothing repeats,
			-- neither the keys' sequences (arrows, F1, Alt+a) nor lone text.
		local
			l_probe: WIN32_DRIVER_PROBE
			l_mode: NATURAL_32
		do
			create l_probe
			if vt_injection_works (l_probe, "test_win32_vt_sequences_never_repeat") then
				l_mode := start_vt_input (l_probe)
				assert ("mouse", l_probe.inject_chars ({STRING_32} "%/27/[<0;11;11M%/27/[<0;11;11m"))
				assert_trace (l_probe, "mouse:10,10 mouse:10,10", "mouse reports")
				assert ("paste", l_probe.inject_chars ({STRING_32} "%/27/[200~aab%/27/[201~"))
				assert_trace (l_probe, "paste:aab", "paste")
				assert ("arrows", l_probe.inject_chars ({STRING_32} "%/27/[A%/27/[A"))
				assert_trace (l_probe, "p:<up> p:<up>", "arrows")
				assert ("f1", l_probe.inject_chars ({STRING_32} "%/27/OP%/27/OP"))
				assert_trace (l_probe, "p:<f1> p:<f1>", "F1")
				assert ("alt+a", l_probe.inject_chars ({STRING_32} "%/27/a%/27/a"))
				assert_trace (l_probe, "p:A-a p:A-a", "alt+a")
				-- Lone text: no key-up seen yet, so no repeat either
				assert ("text", l_probe.inject_chars ({STRING_32} "cc"))
				assert_trace (l_probe, "p:c p:c", "lone text, no key-up seen")
				-- A modifier's key-up does not count; another key's does
				assert ("up shift", l_probe.inject_key (False, 0x10, 0, 0))
				assert ("text 2", l_probe.inject_chars ({STRING_32} "cc"))
				assert_trace (l_probe, "p:c p:c", "lone text, a modifier's key-up")
				see_a_key_up (l_probe)
				assert ("text 3", l_probe.inject_chars ({STRING_32} "cc"))
				assert_trace (l_probe, "p:c r:c", "lone text, a key-up seen")
				assert ("mouse 2", l_probe.inject_chars ({STRING_32} "%/27/[<0;11;11M%/27/[<0;11;11M"))
				assert_trace (l_probe, "mouse:10,10 mouse:10,10", "mouse reports, a key-up seen")
				assert ("paste 2", l_probe.inject_chars ({STRING_32} "%/27/[200~aab%/27/[201~"))
				assert_trace (l_probe, "paste:aab", "paste, a key-up seen")
				-- The seen key-up is forgotten when enhancement is turned off
				l_probe.disable_keyboard_enhancement
				l_probe.enable_keyboard_enhancement
				assert ("text 4", l_probe.inject_chars ({STRING_32} "cc"))
				assert_trace (l_probe, "p:c p:c", "lone text, enhancement turned off and on")
				stop_vt_input (l_probe, l_mode)
			else
				-- No console attached, or a host that drops injected key-ups: not run (`vt_injection_works`)
				assert ("not runnable here", not last_vt_injection_works)
			end
		end

	test_win32_vt_focus_loss_forgets_held_keys
			-- P2 T5 with ENABLE_VIRTUAL_TERMINAL_INPUT on: a FOCUS_EVENT record of a focus loss,
			-- or the focus-out report `CSI O` (mode 1004), forgets the key held, so the next
			-- key-down is a press. Without enhancement nothing changes: "aa" stays two presses.
		local
			l_probe: WIN32_DRIVER_PROBE
			l_mode: NATURAL_32
		do
			create l_probe
			if vt_injection_works (l_probe, "test_win32_vt_focus_loss_forgets_held_keys") then
				l_mode := start_vt_input (l_probe)
				see_a_key_up (l_probe)
				assert ("down a 1", l_probe.inject_key (True, 0x41, 97, 0))
				assert ("focus lost", l_probe.inject_focus (False))
				assert ("down a 2", l_probe.inject_key (True, 0x41, 97, 0))
				assert ("apart", l_probe.inject_menu_record)
				assert ("down a 3", l_probe.inject_key (True, 0x41, 97, 0))
				assert ("focus out report", l_probe.inject_chars ({STRING_32} "%/27/[O"))
				assert ("down a 4", l_probe.inject_key (True, 0x41, 97, 0))
				assert_trace (l_probe, "p:a p:a r:a focus- p:a", "focus loss")
				l_probe.disable_keyboard_enhancement
				assert ("down a off 1", l_probe.inject_key (True, 0x41, 97, 0))
				assert ("apart off", l_probe.inject_menu_record)
				assert ("down a off 2", l_probe.inject_key (True, 0x41, 97, 0))
				assert ("up a off", l_probe.inject_key (False, 0x41, 97, 0))
				assert ("bytes unchanged", read_bytes (l_probe).same_string ("aa"))
				stop_vt_input (l_probe, l_mode)
			else
				-- No console attached, or a host that drops injected key-ups: not run (`vt_injection_works`)
				assert ("not runnable here", not last_vt_injection_works)
			end
		end

	test_win32_vt_key_sequences_repeat
			-- Review fix #3, with ENABLE_VIRTUAL_TERMINAL_INPUT on: a held key whose VT
			-- translation is an escape sequence (arrow, Ctrl+arrow, F5, F1 as SS3, Alt+a,
			-- Shift+Tab, F3 as SS3) comes as the same sequence again with no key-up between
			-- (seen under ConPTY for a held Up arrow, `tools/conpty_probe`): the first is a
			-- press, the next ones Kitty repeats. A key-up or a mouse report between ends it.
			-- Bytes for Shift+Tab and F3, whose names the trace does not show.
		local
			l_probe: WIN32_DRIVER_PROBE
			l_mode: NATURAL_32
		do
			create l_probe
			if vt_injection_works (l_probe, "test_win32_vt_key_sequences_repeat") then
				l_mode := start_vt_input (l_probe)
				see_a_key_up (l_probe)
				assert ("up held", l_probe.inject_chars ({STRING_32} "%/27/[A%/27/[A%/27/[A"))
				assert ("up let go", l_probe.inject_key (False, 0x26, 0, 0))
				assert_trace (l_probe, "p:<up> r:<up> r:<up> x:<up>", "held up")
				assert ("ctrl+up held", l_probe.inject_chars ({STRING_32} "%/27/[1;5A%/27/[1;5A"))
				assert ("ctrl+up let go", l_probe.inject_key (False, 0x26, 0, 0x0008))
				assert_trace (l_probe, "p:^<up> r:^<up> x:^<up>", "held ctrl+up")
				assert ("f5 held", l_probe.inject_chars ({STRING_32} "%/27/[15~%/27/[15~"))
				assert ("f5 let go", l_probe.inject_key (False, 0x74, 0, 0))
				assert_trace (l_probe, "p:<f5> r:<f5> x:<f5>", "held f5")
				assert ("f1 held", l_probe.inject_chars ({STRING_32} "%/27/OP%/27/OP"))
				assert ("f1 let go", l_probe.inject_key (False, 0x70, 0, 0))
				assert_trace (l_probe, "p:<f1> r:<f1> x:<f1>", "held f1")
				assert ("alt+a held", l_probe.inject_chars ({STRING_32} "%/27/a%/27/a"))
				assert ("alt+a let go", l_probe.inject_key (False, 0x41, 97, 0x0002))
				assert_trace (l_probe, "p:A-a r:A-a x:A-a", "held alt+a")
				assert ("shift+tab held", l_probe.inject_chars ({STRING_32} "%/27/[Z%/27/[Z"))
				assert ("shift+tab bytes", read_bytes (l_probe).same_string ("%/27/[Z%/27/[9;2:2u"))
				assert ("shift+tab let go", l_probe.inject_key (False, 0x09, 9, 0x0010))
				assert ("shift+tab release read", not read_bytes (l_probe).is_empty)
				assert ("f3 held", l_probe.inject_chars ({STRING_32} "%/27/OR%/27/OR"))
				assert ("f3 bytes", read_bytes (l_probe).same_string ("%/27/OR%/27/[13;1:2~"))
				assert ("f3 let go", l_probe.inject_key (False, 0x72, 0, 0))
				assert ("f3 release read", not read_bytes (l_probe).is_empty)
				-- Ended by a key-up and by a mouse report
				assert ("up, key-up, up", l_probe.inject_chars ({STRING_32} "%/27/[A"))
				assert ("key-up between", l_probe.inject_key (False, 0x26, 0, 0))
				assert ("up again", l_probe.inject_chars ({STRING_32} "%/27/[A%/27/[<0;11;11M%/27/[A"))
				assert ("up let go 2", l_probe.inject_key (False, 0x26, 0, 0))
				assert_trace (l_probe, "p:<up> x:<up> p:<up> mouse:10,10 p:<up> x:<up>", "ended")
				-- A sequence that is not complete is read as before, as a press
				assert ("alt+[ alone", l_probe.inject_chars ({STRING_32} "%/27/["))
				assert ("alt+[ bytes", read_bytes (l_probe).same_string ("%/27/["))
				stop_vt_input (l_probe, l_mode)
			else
				-- No console attached, or a host that drops injected key-ups: not run (`vt_injection_works`)
				assert ("not runnable here", not last_vt_injection_works)
			end
		end

	test_win32_vt_paste_state_reset
			-- Review fix #4, with ENABLE_VIRTUAL_TERMINAL_INPUT on: a bracketed paste whose end
			-- `ESC [ 201 ~` never comes no longer turns repeats off for good. Turning
			-- enhancement off (as restoring the modes does, at the end of a run or a stop)
			-- forgets it, and so does a second of no input.
		local
			l_probe: WIN32_DRIVER_PROBE
			l_mode: NATURAL_32
		do
			create l_probe
			if vt_injection_works (l_probe, "test_win32_vt_paste_state_reset") then
				l_mode := start_vt_input (l_probe)
				see_a_key_up (l_probe)
				assert ("open paste 1", l_probe.inject_chars ({STRING_32} "%/27/[200~ab"))
				assert ("paste read 1", not read_bytes (l_probe).is_empty)
				l_probe.disable_keyboard_enhancement
				l_probe.enable_keyboard_enhancement
				see_a_key_up (l_probe)
				assert ("text after the reset", l_probe.inject_chars ({STRING_32} "cc"))
				assert_trace (l_probe, "p:c r:c", "paste forgotten with enhancement off")
				assert ("open paste 2", l_probe.inject_chars ({STRING_32} "%/27/[200~ab"))
				assert ("paste read 2", not read_bytes (l_probe).is_empty)
				(create {EXECUTION_ENVIRONMENT}).sleep (1_200_000_000)
				assert ("text after a second", l_probe.inject_chars ({STRING_32} "cc"))
				assert_trace (l_probe, "p:c r:c", "paste forgotten after a second of no input")
				stop_vt_input (l_probe, l_mode)
			else
				-- No console attached, or a host that drops injected key-ups: not run (`vt_injection_works`)
				assert ("not runnable here", not last_vt_injection_works)
			end
		end

	test_win32_vt_osc_reply_never_repeats
			-- P2b K5, with ENABLE_VIRTUAL_TERMINAL_INPUT on: the characters of an OSC reply
			-- (OSC 52 ended by BEL or by ST, OSC 11) come as key-down records with no key code
			-- and no key-up between. None of them is lone text: its doubled characters (`==`,
			-- `00`) give no Kitty repeat, `ESC ]` is not taken for Alt+`]` (two replies in a
			-- row do not repeat it), and the bytes reach the parser as they came. A key held
			-- around a reply gives a press after it, never a repeat.
		local
			l_probe: WIN32_DRIVER_PROBE
			l_mode: NATURAL_32
			l_bel, l_st, l_osc11: STRING_32
		do
			create l_probe
			if vt_injection_works (l_probe, "test_win32_vt_osc_reply_never_repeats") then
				l_bel := {STRING_32} "%/27/]52;c;YWFhYQ==%/7/"
				l_st := {STRING_32} "%/27/]52;p;YWFhYQ==%/27/\"
				l_osc11 := {STRING_32} "%/27/]11;rgb:0000/0000/0000%/7/"
				l_mode := start_vt_input (l_probe)
				see_a_key_up (l_probe)
					-- The bytes as they came: no Kitty repeat sequence inside
				assert ("bel reply", l_probe.inject_chars (l_bel))
				assert ("bel bytes", read_bytes (l_probe).same_string_general (l_bel))
				assert ("st reply", l_probe.inject_chars (l_st))
				assert ("st bytes", read_bytes (l_probe).same_string_general (l_st))
				assert ("osc 11", l_probe.inject_chars (l_osc11))
				assert ("osc 11 bytes", read_bytes (l_probe).same_string_general (l_osc11))
				assert ("two replies", l_probe.inject_chars (l_bel + l_bel))
				assert ("two replies bytes", read_bytes (l_probe).same_string_general (l_bel + l_bel))
					-- Split right after `ESC ]': nothing follows the `]' when the ESC is read,
					-- and the rest of the reply comes in a later read
				assert ("split head", l_probe.inject_chars ({STRING_32} "%/27/]"))
				assert ("split head bytes", read_bytes (l_probe).same_string_general ({STRING_32} "%/27/]"))
				assert ("split tail", l_probe.inject_chars ({STRING_32} "52;c;YWFhYQ==%/7/"))
				assert ("split tail bytes", read_bytes (l_probe).same_string_general ({STRING_32} "52;c;YWFhYQ==%/7/"))
					-- A held a, a reply ended by BEL, a held a
				assert ("down a 1", l_probe.inject_key (True, 0x41, 97, 0))
				assert ("apart 1", l_probe.inject_menu_record)
				assert ("down a 2", l_probe.inject_key (True, 0x41, 97, 0))
				assert ("reply by bel", l_probe.inject_chars (l_bel))
				assert ("down a 3", l_probe.inject_key (True, 0x41, 97, 0))
				assert ("apart 2", l_probe.inject_menu_record)
				assert ("down a 4", l_probe.inject_key (True, 0x41, 97, 0))
				assert ("up a 1", l_probe.inject_key (False, 0x41, 97, 0))
				assert_trace (l_probe, "p:a r:a clip(c):aaaa p:a r:a x:a", "reply by BEL between held a")
					-- The same with ST
				assert ("down a 5", l_probe.inject_key (True, 0x41, 97, 0))
				assert ("apart 3", l_probe.inject_menu_record)
				assert ("down a 6", l_probe.inject_key (True, 0x41, 97, 0))
				assert ("reply by st", l_probe.inject_chars (l_st))
				assert ("down a 7", l_probe.inject_key (True, 0x41, 97, 0))
				assert ("apart 4", l_probe.inject_menu_record)
				assert ("down a 8", l_probe.inject_key (True, 0x41, 97, 0))
				assert ("up a 2", l_probe.inject_key (False, 0x41, 97, 0))
				assert_trace (l_probe, "p:a r:a clip(p):aaaa p:a r:a x:a", "reply by ST between held a")
					-- Two replies and an OSC 11 report in a row, then lone text
				assert ("replies in a row", l_probe.inject_chars (l_bel + l_st + l_osc11 + l_bel))
				assert ("text after", l_probe.inject_chars ({STRING_32} "cc"))
				assert_trace (l_probe, "clip(c):aaaa clip(p):aaaa clip(c):aaaa p:c r:c", "replies in a row")
					-- A held key's sequence (Up) is ended by a reply: the next Up is a press
				assert ("up, reply, up", l_probe.inject_chars ({STRING_32} "%/27/[A" + l_bel + "%/27/[A"))
				assert ("up let go", l_probe.inject_key (False, 0x26, 0, 0))
				assert_trace (l_probe, "p:<up> clip(c):aaaa p:<up> x:<up>", "reply between two Up")
				stop_vt_input (l_probe, l_mode)
			else
				-- No console attached, or a host that drops injected key-ups: not run (`vt_injection_works`)
				assert ("not runnable here", not last_vt_injection_works)
			end
		end

	test_win32_vt_osc_unterminated_ends
			-- P2b K5, with ENABLE_VIRTUAL_TERMINAL_INPUT on: an OSC whose end (BEL or ST) never
			-- comes does not turn repeats off for good. A second of no input ends it (the
			-- paste-idle rule of review fix #4), and so does turning enhancement off (as
			-- restoring the modes does). An ESC inside it that is not ST, or CAN / SUB, ends it
			-- at once, and the character after the ESC is read as after a new one.
		local
			l_probe: WIN32_DRIVER_PROBE
			l_mode: NATURAL_32
		do
			create l_probe
			if vt_injection_works (l_probe, "test_win32_vt_osc_unterminated_ends") then
				l_mode := start_vt_input (l_probe)
				see_a_key_up (l_probe)
				assert ("open osc 1", l_probe.inject_chars ({STRING_32} "%/27/]52;c;YWFh"))
				assert ("osc read 1", not read_bytes (l_probe).is_empty)
				(create {EXECUTION_ENVIRONMENT}).sleep (1_200_000_000)
				assert ("text after a second", l_probe.inject_chars ({STRING_32} "cc"))
				assert_trace (l_probe, "p:c r:c", "osc forgotten after a second of no input")
				assert ("open osc 2", l_probe.inject_chars ({STRING_32} "%/27/]11;rgb:00"))
				assert ("osc read 2", not read_bytes (l_probe).is_empty)
				l_probe.disable_keyboard_enhancement
				l_probe.enable_keyboard_enhancement
				see_a_key_up (l_probe)
				assert ("text after the reset", l_probe.inject_chars ({STRING_32} "cc"))
				assert_trace (l_probe, "p:c r:c", "osc forgotten with enhancement off")
					-- Cut by ESC: `ESC [ A' after it is Up (read by the follower, so a press;
					-- the next Up from ground state is a press too: no key sequence before it)
				assert ("cut by esc", l_probe.inject_chars ({STRING_32} "%/27/]52;c;YW%/27/[A%/27/[A"))
				assert ("up let go", l_probe.inject_key (False, 0x26, 0, 0))
				assert_trace (l_probe, "p:<up> p:<up> x:<up>", "osc cut by ESC")
				assert ("text after esc", l_probe.inject_chars ({STRING_32} "cc"))
				assert_trace (l_probe, "p:c r:c", "ground after ESC")
					-- Cut by CAN: Ctrl+X typed, and held
				assert ("cut by can", l_probe.inject_chars ({STRING_32} "%/27/]52;c;YW%/24/%/24/"))
				assert_trace (l_probe, "p:^x r:^x", "osc cut by CAN")
				stop_vt_input (l_probe, l_mode)
			else
				-- No console attached, or a host that drops injected key-ups: not run (`vt_injection_works`)
				assert ("not runnable here", not last_vt_injection_works)
			end
		end

	test_win32_vt_osc_alt_bracket_kept
			-- P2b K5, with ENABLE_VIRTUAL_TERMINAL_INPUT on: `ESC ]` not followed by
			-- `<digits> ;` is Alt+`]`, as ANSI_INPUT_PARSER reads it (P2b K2): held, it
			-- repeats; a letter after it is lone text. `ESC ] 1 x` is Alt+`]`, 1, x, and the
			-- follower is back in ground state at x. Inside a bracketed paste `ESC ] 52 ;` is
			-- pasted text and opens no OSC.
		local
			l_probe: WIN32_DRIVER_PROBE
			l_mode: NATURAL_32
		do
			create l_probe
			if vt_injection_works (l_probe, "test_win32_vt_osc_alt_bracket_kept") then
				l_mode := start_vt_input (l_probe)
				see_a_key_up (l_probe)
				assert ("alt+] held", l_probe.inject_chars ({STRING_32} "%/27/]%/27/]"))
				assert ("alt+] let go", l_probe.inject_key (False, 0xDD, 93, 0x0002))
				assert_trace (l_probe, "p:A-] r:A-] x:A-]", "held alt+]")
				assert ("alt+] then a", l_probe.inject_chars ({STRING_32} "%/27/]aa"))
				assert_trace (l_probe, "p:A-] p:a r:a", "alt+] then a")
				assert ("alt+] 1 x", l_probe.inject_chars ({STRING_32} "%/27/]1xx"))
				assert_trace (l_probe, "p:A-] p:1 p:x r:x", "alt+] 1 x")
				assert ("paste", l_probe.inject_chars ({STRING_32} "%/27/[200~%/27/]52;c;YWFh%/27/[201~"))
				assert ("text after paste", l_probe.inject_chars ({STRING_32} "cc"))
				assert_trace (l_probe, "paste:%/27/]52;c;YWFh p:c r:c", "osc inside a paste")
				stop_vt_input (l_probe, l_mode)
			else
				-- No console attached, or a host that drops injected key-ups: not run (`vt_injection_works`)
				assert ("not runnable here", not last_vt_injection_works)
			end
		end

	test_win32_driver_provides_keyboard_enhancement
			-- Review fix #1: the Win32 driver builds the release and repeat events itself, so
			-- {TUI_APPLICATION}.set_keyboard_enhancement_if_supported does not ask the terminal.
		local
			l_driver: WIN32_CONSOLE_DRIVER
		do
			create l_driver
			assert ("provides", l_driver.provides_keyboard_enhancement)
		end

	test_win32_suspend_is_noop
			-- Suspend/resume is a documented no-op on Windows.
		local
			l_driver: WIN32_CONSOLE_DRIVER
		do
			create l_driver
			assert ("no suspend", not l_driver.supports_suspend_resume)
			assert ("no resume flag", not l_driver.has_resume_request)
			l_driver.suspend_process
			l_driver.clear_resume_request
			assert ("still no resume", not l_driver.has_resume_request)
		end

feature {NONE} -- Helpers

	read_key_events (a_probe: WIN32_DRIVER_PROBE; a_parser: ANSI_INPUT_PARSER): ARRAYED_LIST [KEY_EVENT]
			-- Key events parsed from everything the driver delivers until a 50 ms timeout.
		local
			b: INTEGER
		do
			from
				b := a_probe.read_char_with_timeout (50)
			until
				b < 0
			loop
				a_parser.parse_code (b.to_natural_32)
				b := a_probe.read_char_with_timeout (50)
			end
			create Result.make (4)
			across a_parser.events as e loop
				if attached {KEY_EVENT} e as k then
					Result.extend (k)
				end
			end
		end


	start_enhanced (a_probe: WIN32_DRIVER_PROBE)
			-- Empty the console input and turn enhancement on with no key held (turning it off
			-- first forgets keys a previous test left down).
		do
			a_probe.flush_console_input
			a_probe.disable_keyboard_enhancement
			a_probe.enable_keyboard_enhancement
		end

	stop_enhanced (a_probe: WIN32_DRIVER_PROBE)
			-- Turn enhancement off and empty the console input.
		do
			a_probe.disable_keyboard_enhancement
			a_probe.flush_console_input
		end

	read_bytes (a_probe: WIN32_DRIVER_PROBE): STRING_8
			-- Everything the driver delivers until a 50 ms timeout, as bytes.
		local
			b: INTEGER
		do
			create Result.make (16)
			from
				b := a_probe.read_char_with_timeout (50)
			until
				b < 0
			loop
				Result.append_code (b.to_natural_32)
				b := a_probe.read_char_with_timeout (50)
			end
		end

	event_trace (a_events: LIST [EVENT]): STRING_8
			-- The events separated by spaces. A key as "kind:key": kind p (press), r (repeat)
			-- or x (release); key with "^" for Ctrl, "A-" for Alt and "S-" for Shift, then the
			-- character, "<enter>", "<up>" or "<f1>". A mouse event as "mouse:column,row", a
			-- paste as "paste:text", a focus change as "focus+" or "focus-", a clipboard reply
			-- as "clip(selection):text" (or "clip(selection)#status" without text).
		do
			create Result.make (32)
			across a_events as e loop
				if not Result.is_empty then
					Result.append_character (' ')
				end
				if attached {KEY_EVENT} e as k then
					if k.is_repeat then
						Result.append ("r:")
					elseif k.is_release then
						Result.append ("x:")
					else
						Result.append ("p:")
					end
					if k.modifiers.is_control then
						Result.append_character ('^')
					end
					if k.modifiers.is_alt then
						Result.append ("A-")
					end
					if k.modifiers.is_shift then
						Result.append ("S-")
					end
					if k.code.is_char then
						Result.append_character (k.code.character.to_character_8)
					elseif k.code.is_enter then
						Result.append ("<enter>")
					elseif k.code.is_up then
						Result.append ("<up>")
					elseif k.code.is_function then
						Result.append ("<f" + k.code.function_number.out + ">")
					else
						Result.append ("<?>")
					end
				elseif attached {MOUSE_EVENT} e as m then
					Result.append ("mouse:" + m.column.out + "," + m.row.out)
				elseif attached {PASTE_EVENT} e as l_paste then
					Result.append ("paste:" + l_paste.text.to_string_8)
				elseif attached {CLIPBOARD_EVENT} e as l_clip then
					Result.append ("clip(" + l_clip.selection.out + ")")
					if l_clip.status = {CLIPBOARD_EVENT}.Status_text then
						Result.append (":" + l_clip.text.to_string_8)
					else
						Result.append ("#" + l_clip.status.out)
					end
				elseif attached {FOCUS_EVENT} e as f then
					if f.has_focus then
						Result.append ("focus+")
					else
						Result.append ("focus-")
					end
				else
					Result.append ("<event>")
				end
			end
		end

	trace_now (a_probe: WIN32_DRIVER_PROBE): STRING_8
			-- The events read now from `a_probe` (until a 50 ms timeout), as `event_trace`.
		local
			l_parser: ANSI_INPUT_PARSER
			b: INTEGER
		do
			create l_parser.make
			from
				b := a_probe.read_char_with_timeout (50)
			until
				b < 0
			loop
				l_parser.parse_code (b.to_natural_32)
				b := a_probe.read_char_with_timeout (50)
			end
			Result := event_trace (l_parser.events)
		end

	last_vt_injection_works: BOOLEAN
			-- Result of the last `vt_injection_works`

	vt_injection_works (a_probe: WIN32_DRIVER_PROBE; a_test: STRING_8): BOOLEAN
			-- Can the `test_win32_vt_*` tests (named `a_test`) run in this console? They need
			-- a console, and injected key-up records that reach the driver with
			-- ENABLE_VIRTUAL_TERMINAL_INPUT on. A console hosted by ConPTY (Windows Terminal,
			-- and so `cmd` started from it) drops them: an injected x down and up gives "p:x",
			-- not "p:x x:x". Then the test is not run, and a [NOTE] line says so: run the suite
			-- in a classic console (`conhost.exe cmd /c eiffeltui_tests.exe`).
		local
			l_mode: NATURAL_32
		do
			if a_probe.has_console_modes then
				l_mode := start_vt_input (a_probe)
				if a_probe.inject_key (True, 0x58, 120, 0) and a_probe.inject_key (False, 0x58, 120, 0) then
					Result := trace_now (a_probe).same_string ("p:x x:x")
				end
				stop_vt_input (a_probe, l_mode)
				if not Result then
					print ("  [NOTE] " + a_test + " not run: this console host drops injected key-up records (ConPTY, as in Windows Terminal); run the suite under conhost.exe%N")
				end
			end
			last_vt_injection_works := Result
		end

	assert_trace (a_probe: WIN32_DRIVER_PROBE; a_expected, a_tag: STRING_8)
			-- Assert the events read now from `a_probe` are `a_expected` (`event_trace`).
		local
			l_trace: STRING_8
		do
			l_trace := trace_now (a_probe)
			assert (a_tag + ": expected %"" + a_expected + "%", got %"" + l_trace + "%"", l_trace.same_string (a_expected))
		end

	start_vt_input (a_probe: WIN32_DRIVER_PROBE): NATURAL_32
			-- Turn ENABLE_VIRTUAL_TERMINAL_INPUT on, as raw mode does, so that the console
			-- turns injected key-down records into their VT characters as it does for real
			-- keys; the input mode before, for `stop_vt_input`.
		do
			Result := a_probe.input_mode
			assert ("vt input on", a_probe.set_input_mode (Result | 0x0200))
			start_enhanced (a_probe)
		end

	see_a_key_up (a_probe: WIN32_DRIVER_PROBE)
			-- Type x (a key-down and its key-up), so that the driver has seen a key-up and
			-- records without a key code may give repeats (review fix #2).
		do
			assert ("x down", a_probe.inject_key (True, 0x58, 120, 0))
			assert ("x up", a_probe.inject_key (False, 0x58, 120, 0))
			assert_trace (a_probe, "p:x x:x", "a key-up seen")
		end

	stop_vt_input (a_probe: WIN32_DRIVER_PROBE; a_mode: NATURAL_32)
			-- Undo `start_vt_input`: enhancement off, the input mode `a_mode` again.
		do
			stop_enhanced (a_probe)
			assert ("input mode back", a_probe.set_input_mode (a_mode) and a_probe.input_mode = a_mode)
		end

	assert_bytes (a_probe: WIN32_DRIVER_PROBE; a_expected: ARRAY [INTEGER]; a_tag: STRING)
			-- Assert the next bytes read from `a_probe` (without touching the console) are `a_expected`.
		local
			i: INTEGER
		do
			from
				i := a_expected.lower
			until
				i > a_expected.upper
			loop
				assert (a_tag + " byte " + i.out, a_probe.read_char_with_timeout (0) = a_expected [i])
				i := i + 1
			end
		end

end
