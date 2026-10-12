note
	description: "[
		AutoTest suite for Kitty Keyboard Protocol, Key Release/Repeat events,
		Insert key support, and backend keyboard enhancement mode.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_KEYBOARD_ENHANCEMENT

inherit
	EQA_TEST_SET

feature -- Test routines

	test_insert_key_code
			-- Test KEY_CODE.insert definition, status queries, and string representation.
		local
			l_k1, l_k2: KEY_CODE
		do
			l_k1 := {KEY_CODE}.insert
			assert ("is special", l_k1.is_special)
			assert ("is insert", l_k1.is_insert)
			assert ("not is delete", not l_k1.is_delete)
			assert ("not is char", not l_k1.is_char)

			create l_k2.default_create
			l_k2 := {KEY_CODE}.insert
			assert ("equals", l_k1.is_equal (l_k2))
			assert ("out is Insert", l_k1.out.same_string ("Insert"))
		end

	test_key_event_kinds
			-- Test KEY_EVENT press, repeat, and release status queries, equality, and output.
		local
			l_code: KEY_CODE
			l_mod: MODIFIERS
			l_press, l_repeat, l_release: KEY_EVENT
		do
			l_code := {KEY_CODE}.up
			create l_mod.default_create

			-- Default make produces press event
			create l_press.make (l_code, l_mod)
			assert ("is press", l_press.is_press)
			assert ("not repeat", not l_press.is_repeat)
			assert ("not release", not l_press.is_release)

			-- Explicit make_with_kind
			create l_repeat.make_with_kind (l_code, l_mod, {KEY_EVENT}.Kind_repeat)
			assert ("is repeat", l_repeat.is_repeat)
			assert ("not press", not l_repeat.is_press)
			assert ("not release", not l_repeat.is_release)

			create l_release.make_with_kind (l_code, l_mod, {KEY_EVENT}.Kind_release)
			assert ("is release", l_release.is_release)
			assert ("not press", not l_release.is_press)
			assert ("not repeat", not l_release.is_repeat)

			-- Equality distinguishes event kind
			assert ("press /= release", not l_press.is_equal (l_release))
			assert ("press /= repeat", not l_press.is_equal (l_repeat))

			-- Out reflects kind
			assert ("press out", l_press.out.has_substring ("(Press)"))
			assert ("repeat out", l_repeat.out.has_substring ("(Repeat)"))
			assert ("release out", l_release.out.has_substring ("(Release)"))
		end

	test_parser_insert_key
			-- Test parsing ANSI tilde Insert key (\e[2~).
		local
			l_parser: ANSI_INPUT_PARSER
		do
			create l_parser.make

			-- Plain Insert: \e[2~
			l_parser.parse_code (27)
			l_parser.parse_string ("[2~")
			assert ("1 event", l_parser.events.count = 1)
			if attached {KEY_EVENT} l_parser.events.first as ev then
				assert ("is insert", ev.code.is_insert)
				assert ("is press", ev.is_press)
				assert ("no mod", ev.modifiers.is_empty)
			else
				assert ("expected key event", False)
			end
			l_parser.wipe_out

			-- Ctrl+Insert: \e[2;5~
			l_parser.parse_code (27)
			l_parser.parse_string ("[2;5~")
			assert ("ctrl insert event", l_parser.events.count = 1)
			if attached {KEY_EVENT} l_parser.events.first as ev_ctrl then
				assert ("is insert", ev_ctrl.code.is_insert)
				assert ("has ctrl", ev_ctrl.modifiers.is_control)
				assert ("is press", ev_ctrl.is_press)
			else
				assert ("expected key event", False)
			end
		end

	test_kitty_csi_u_characters
			-- Test parsing Kitty CSI u printable characters with press, repeat, and release.
		local
			l_parser: ANSI_INPUT_PARSER
		do
			create l_parser.make

			-- Plain 'a': \e[97u
			l_parser.parse_code (27)
			l_parser.parse_string ("[97u")
			assert ("1 event", l_parser.events.count = 1)
			if attached {KEY_EVENT} l_parser.events.first as ev1 then
				assert ("is a", ev1.code.is_char and then ev1.code.character = 'a')
				assert ("is press", ev1.is_press)
				assert ("no mod", ev1.modifiers.is_empty)
			else
				assert ("expected key event", False)
			end
			l_parser.wipe_out

			-- Ctrl+'a': \e[97;5u
			l_parser.parse_code (27)
			l_parser.parse_string ("[97;5u")
			assert ("ctrl a event", l_parser.events.count = 1)
			if attached {KEY_EVENT} l_parser.events.first as ev2 then
				assert ("is a", ev2.code.is_char and then ev2.code.character = 'a')
				assert ("has ctrl", ev2.modifiers.is_control)
				assert ("is press", ev2.is_press)
			else
				assert ("expected key event", False)
			end
			l_parser.wipe_out

			-- Repeat 'a': \e[97;1:2u
			l_parser.parse_code (27)
			l_parser.parse_string ("[97;1:2u")
			assert ("repeat a event", l_parser.events.count = 1)
			if attached {KEY_EVENT} l_parser.events.first as ev3 then
				assert ("is a", ev3.code.is_char and then ev3.code.character = 'a')
				assert ("is repeat", ev3.is_repeat)
			else
				assert ("expected key event", False)
			end
			l_parser.wipe_out

			-- Release 'a': \e[97;1:3u
			l_parser.parse_code (27)
			l_parser.parse_string ("[97;1:3u")
			assert ("release a event", l_parser.events.count = 1)
			if attached {KEY_EVENT} l_parser.events.first as ev4 then
				assert ("is a", ev4.code.is_char and then ev4.code.character = 'a')
				assert ("is release", ev4.is_release)
			else
				assert ("expected key event", False)
			end
			l_parser.wipe_out

			-- Shift+Release 'z': \e[122;2:3u
			l_parser.parse_code (27)
			l_parser.parse_string ("[122;2:3u")
			if attached {KEY_EVENT} l_parser.events.first as ev5 then
				assert ("is z", ev5.code.is_char and then ev5.code.character = 'z')
				assert ("has shift", ev5.modifiers.is_shift)
				assert ("is release", ev5.is_release)
			else
				assert ("expected key event", False)
			end
		end

	test_kitty_csi_u_functional_keys
			-- Test parsing Kitty functional keys (Enter, Tab, Backspace, Esc, navigation, and F-keys).
		local
			l_parser: ANSI_INPUT_PARSER
		do
			create l_parser.make

			-- Enter release: \e[13;1:3u
			l_parser.parse_code (27)
			l_parser.parse_string ("[13;1:3u")
			assert ("enter release", attached {KEY_EVENT} l_parser.events.first as ev_ent and then
				(ev_ent.code.is_enter and ev_ent.is_release))
			l_parser.wipe_out

			-- Tab release: \e[9;1:3u
			l_parser.parse_code (27)
			l_parser.parse_string ("[9;1:3u")
			assert ("tab release", attached {KEY_EVENT} l_parser.events.first as ev_tab and then
				(ev_tab.code.is_tab and ev_tab.is_release))
			l_parser.wipe_out

			-- Backspace release: \e[127;1:3u
			l_parser.parse_code (27)
			l_parser.parse_string ("[127;1:3u")
			assert ("backspace release", attached {KEY_EVENT} l_parser.events.first as ev_bs and then
				(ev_bs.code.is_backspace and ev_bs.is_release))
			l_parser.wipe_out

			-- Escape release: \e[27;1:3u
			l_parser.parse_code (27)
			l_parser.parse_string ("[27;1:3u")
			assert ("escape release", attached {KEY_EVENT} l_parser.events.first as ev_esc and then
				(ev_esc.code.is_escape and ev_esc.is_release))
			l_parser.wipe_out

			-- Keypad Up (KP_UP 57419) press and keypad Down (KP_DOWN 57420) release
			l_parser.parse_code (27)
			l_parser.parse_string ("[57419;1:1u")
			assert ("kp up press", attached {KEY_EVENT} l_parser.events.first as ev_up and then
				(ev_up.code.is_up and ev_up.is_press))
			l_parser.wipe_out

			l_parser.parse_code (27)
			l_parser.parse_string ("[57420;1:3u")
			assert ("kp down release", attached {KEY_EVENT} l_parser.events.first as ev_dn and then
				(ev_dn.code.is_down and ev_dn.is_release))
			l_parser.wipe_out

			-- Keypad Insert (57425) and Delete (57426)
			l_parser.parse_code (27)
			l_parser.parse_string ("[57425;1:1u")
			assert ("kp insert press", attached {KEY_EVENT} l_parser.events.first as ev_ins and then
				(ev_ins.code.is_insert and ev_ins.is_press))
			l_parser.wipe_out

			l_parser.parse_code (27)
			l_parser.parse_string ("[57426;1:3u")
			assert ("kp delete release", attached {KEY_EVENT} l_parser.events.first as ev_del and then
				(ev_del.code.is_delete and ev_del.is_release))
			l_parser.wipe_out

			-- Keypad digit and Enter
			l_parser.parse_code (27)
			l_parser.parse_string ("[57404u")
			assert ("kp 5", attached {KEY_EVENT} l_parser.events.first as ev_kp5 and then
				(ev_kp5.code.is_char and then ev_kp5.code.character = '5'))
			l_parser.wipe_out

			l_parser.parse_code (27)
			l_parser.parse_string ("[57414u")
			assert ("kp enter", attached {KEY_EVENT} l_parser.events.first as ev_kpe and then ev_kpe.code.is_enter)
			l_parser.wipe_out

			-- F13 (57376) and Ctrl+F24 release (57387)
			l_parser.parse_code (27)
			l_parser.parse_string ("[57376;1:1u")
			assert ("f13 press", attached {KEY_EVENT} l_parser.events.first as ev_f13 and then
				(ev_f13.code.is_function and ev_f13.code.function_number = 13 and ev_f13.is_press))
			l_parser.wipe_out

			l_parser.parse_code (27)
			l_parser.parse_string ("[57387;5:3u")
			assert ("ctrl f24 release", attached {KEY_EVENT} l_parser.events.first as ev_f24 and then
				(ev_f24.code.is_function and ev_f24.code.function_number = 24 and ev_f24.modifiers.is_control and ev_f24.is_release))
			l_parser.wipe_out

			-- Caps Lock (57358) and Scroll Lock (57359) have no KEY_CODE: no event, no bogus key
			l_parser.parse_code (27)
			l_parser.parse_string ("[57358;1:1u")
			l_parser.parse_code (27)
			l_parser.parse_string ("[57359;1:3u")
			assert ("lock keys ignored", l_parser.events.is_empty)

			-- Alternate keys after ':' in the first field are ignored (Shift+a reported as 97:65)
			l_parser.parse_code (27)
			l_parser.parse_string ("[97:65;2u")
			assert ("alternate keys ignored", attached {KEY_EVENT} l_parser.events.first as ev_alt and then
				(ev_alt.code.is_char and then ev_alt.code.character = 'a' and ev_alt.modifiers.is_shift))
			l_parser.wipe_out

			-- Flags query reply (CSI ? flags u) is not a key
			l_parser.parse_code (27)
			l_parser.parse_string ("[?3u")
			assert ("flags reply is not a key", l_parser.events.is_empty)
		end

	test_tilde_function_keys
			-- F1..F4 in their tilde forms (Kitty sends F3 only as CSI 13~), and Home/End as 7~/8~.
		local
			l_parser: ANSI_INPUT_PARSER
			i: INTEGER
		do
			create l_parser.make
			from i := 1 until i > 4 loop
				l_parser.parse_code (27)
				l_parser.parse_string ("[" + (10 + i).out + "~")
				assert ("F" + i.out, attached {KEY_EVENT} l_parser.events.first as k and then
					(k.code.is_function and k.code.function_number = i and k.is_press))
				l_parser.wipe_out
				i := i + 1
			end
			l_parser.parse_code (27)
			l_parser.parse_string ("[13;2:3~")
			assert ("shift F3 release", attached {KEY_EVENT} l_parser.events.first as k3 and then
				(k3.code.function_number = 3 and k3.modifiers.is_shift and k3.is_release))
			l_parser.wipe_out
			l_parser.parse_code (27)
			l_parser.parse_string ("[7~")
			l_parser.parse_code (27)
			l_parser.parse_string ("[8~")
			assert ("home and end", l_parser.events.count = 2 and then
				(attached {KEY_EVENT} l_parser.events.first as h and then h.code.is_home) and then
				(attached {KEY_EVENT} l_parser.events.last as e and then e.code.is_end))
		end

	test_csi_event_types_legacy_keys
			-- Test legacy CSI navigation and editing sequences carrying event types.
		local
			l_parser: ANSI_INPUT_PARSER
		do
			create l_parser.make

			-- Ctrl+Up press: \e[1;5:1A
			l_parser.parse_code (27)
			l_parser.parse_string ("[1;5:1A")
			assert ("ctrl up press", attached {KEY_EVENT} l_parser.events.first as k1 and then
				(k1.code.is_up and k1.modifiers.is_control and k1.is_press))
			l_parser.wipe_out

			-- Ctrl+Up repeat: \e[1;5:2A
			l_parser.parse_code (27)
			l_parser.parse_string ("[1;5:2A")
			assert ("ctrl up repeat", attached {KEY_EVENT} l_parser.events.first as k2 and then
				(k2.code.is_up and k2.modifiers.is_control and k2.is_repeat))
			l_parser.wipe_out

			-- Ctrl+Up release: \e[1;5:3A
			l_parser.parse_code (27)
			l_parser.parse_string ("[1;5:3A")
			assert ("ctrl up release", attached {KEY_EVENT} l_parser.events.first as k3 and then
				(k3.code.is_up and k3.modifiers.is_control and k3.is_release))
			l_parser.wipe_out

			-- Insert release: \e[2;1:3~
			l_parser.parse_code (27)
			l_parser.parse_string ("[2;1:3~")
			assert ("insert release", attached {KEY_EVENT} l_parser.events.first as k4 and then
				(k4.code.is_insert and k4.is_release))
			l_parser.wipe_out

			-- Shift+F1 release: \e[1;2:3P
			l_parser.parse_code (27)
			l_parser.parse_string ("[1;2:3P")
			assert ("shift f1 release", attached {KEY_EVENT} l_parser.events.first as k5 and then
				(k5.code.is_function and k5.code.function_number = 1 and k5.modifiers.is_shift and k5.is_release))
		end

	test_modified_f3_disambiguation
			-- Test that modified F3 with event type is never misidentified as a cursor position report.
		local
			l_parser: ANSI_INPUT_PARSER
		do
			create l_parser.make

			-- Ambiguous plain DSR cursor report at row 1, col 2: \e[1;2R
			l_parser.parse_code (27)
			l_parser.parse_string ("[1;2R")
			assert ("cursor report parsed", attached {CURSOR_POSITION_EVENT} l_parser.events.first as r and then
				(r.row = 0 and r.column = 1))
			l_parser.wipe_out

			-- Shift+F3 Press with event type: \e[1;2:1R
			l_parser.parse_code (27)
			l_parser.parse_string ("[1;2:1R")
			assert ("shift f3 press parsed", attached {KEY_EVENT} l_parser.events.first as k1 and then
				(k1.code.is_function and k1.code.function_number = 3 and k1.modifiers.is_shift and k1.is_press))
			l_parser.wipe_out

			-- Shift+F3 Release with event type: \e[1;2:3R
			l_parser.parse_code (27)
			l_parser.parse_string ("[1;2:3R")
			assert ("shift f3 release parsed", attached {KEY_EVENT} l_parser.events.first as k2 and then
				(k2.code.is_function and k2.code.function_number = 3 and k2.modifiers.is_shift and k2.is_release))
			l_parser.wipe_out

			-- Kitty sends F3 as CSI 13~, never as CSI R: \e[13;2:1~
			l_parser.parse_code (27)
			l_parser.parse_string ("[13;2:1~")
			assert ("kitty f3 press parsed", attached {KEY_EVENT} l_parser.events.first as k3 and then
				(k3.code.is_function and k3.code.function_number = 3 and k3.modifiers.is_shift and k3.is_press))
		end

	test_backend_keyboard_enhancement
			-- Test enabling and disabling progressive keyboard enhancement on backends.
		local
			l_backend: ANSI_TERMINAL_BACKEND
			l_fake_driver: FAKE_CONSOLE_DRIVER
			l_sink: STRING_32
			l_vt: VIRTUAL_TERMINAL
		do
			-- ANSI_TERMINAL_BACKEND with capture sink
			create l_fake_driver.default_create
			create l_sink.make (64)
			create l_backend.make_with_driver_and_sink (l_fake_driver, l_sink)

			assert ("initially not enhanced", not l_backend.is_keyboard_enhancement_enabled)
			l_backend.enable_keyboard_enhancement
			assert ("enhanced active", l_backend.is_keyboard_enhancement_enabled)
			assert ("driver enhanced", l_fake_driver.is_keyboard_enhancement_enabled)
			assert ("emits push flags", l_sink.has_substring ("%/27/[>3u"))

			l_sink.wipe_out
			l_backend.disable_keyboard_enhancement
			assert ("enhanced disabled", not l_backend.is_keyboard_enhancement_enabled)
			assert ("driver disabled", not l_fake_driver.is_keyboard_enhancement_enabled)
			assert ("emits pop flags", l_sink.has_substring ("%/27/[<u"))

			-- VIRTUAL_TERMINAL operations
			create l_vt.make_default
			assert ("vt initially not enhanced", not l_vt.is_keyboard_enhancement_enabled)
			l_vt.enable_keyboard_enhancement
			assert ("vt enhanced", l_vt.is_keyboard_enhancement_enabled)
			assert ("vt logged enable", l_vt.operations.has ("enable_keyboard_enhancement"))
			l_vt.disable_keyboard_enhancement
			assert ("vt disabled", not l_vt.is_keyboard_enhancement_enabled)
			assert ("vt logged disable", l_vt.operations.has ("disable_keyboard_enhancement"))
		end

	test_application_pushes_and_pops_keyboard_flags
			-- TUI_APPLICATION.set_keyboard_enhancement pushes the flags after entering the alternate
			-- screen and pops them before leaving it; without the setting nothing is sent.
		local
			l_app: TEST_TUI_APP_IMPL
			l_sink: STRING_32
			l_push, l_pop, l_alt_on, l_alt_off: INTEGER
		do
			l_app := new_scripted_app ("q")
			l_app.set_keyboard_enhancement (True)
			l_sink := sink_of (l_app)
			l_app.run
			l_push := l_sink.substring_index ("%/27/[>3u", 1)
			l_pop := l_sink.substring_index ("%/27/[<u", 1)
			l_alt_on := l_sink.substring_index ("%/27/[?1049h", 1)
			l_alt_off := l_sink.substring_index ("%/27/[?1049l", 1)
			assert ("pushed", l_push > 0)
			assert ("pushed on the alternate screen", l_alt_on > 0 and l_alt_on < l_push)
			assert ("popped before leaving it", l_pop > l_push and l_pop < l_alt_off)
			assert ("backend restored", not l_app.backend.is_keyboard_enhancement_enabled)
			assert ("driver restored", not l_app.backend.driver.is_keyboard_enhancement_enabled)

			l_app := new_scripted_app ("q")
			l_sink := sink_of (l_app)
			l_app.run
			assert ("not requested: nothing pushed", not l_sink.has_substring ("%/27/[>3u"))
		end

feature {NONE} -- Helpers

	new_scripted_app (a_input: READABLE_STRING_8): TEST_TUI_APP_IMPL
			-- Application on an ANSI backend whose fake driver replays `a_input`; output is captured.
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_sink: STRING_32
			l_backend: ANSI_TERMINAL_BACKEND
		do
			create l_driver
			create l_sink.make_empty
			l_driver.watch_sink (l_sink)
			l_driver.script (a_input)
			create l_backend.make_with_driver_and_sink (l_driver, l_sink)
			create Result.make_with_terminal (create {TERMINAL [ANSI_TERMINAL_BACKEND]}.make (l_backend))
			Result.event_thread.set_poll_interval (5)
		end

	sink_of (a_app: TEST_TUI_APP_IMPL): STRING_32
			-- The output capture of `a_app`.
		do
			check attached a_app.backend.output_sink as l_s then
				Result := l_s
			end
		end

end
