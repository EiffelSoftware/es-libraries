note
	description: "[
		Windows-only driver tests (this cluster is selected by the ECF on Windows):
		UTF-16 console input re-encoded as UTF-8 bytes, and exact mode restoration.
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
		local
			l_probe: WIN32_DRIVER_PROBE
			l_before, l_raw: TUPLE [input, output: NATURAL_32]
			l_type: NATURAL_32
		do
			create l_probe
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
					assert ("modes changed " + l_type.out, (l_probe.console_modes.input | 0x80) /= (l_before.input | 0x80))
					assert ("chains to the next handler " + l_type.out, not l_probe.invoke_ctrl_handler (l_type))
					assert ("input mode restored " + l_type.out, (l_probe.console_modes.input | 0x80) = (l_before.input | 0x80))
					assert ("output mode restored " + l_type.out, l_probe.console_modes.output = l_before.output)
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
