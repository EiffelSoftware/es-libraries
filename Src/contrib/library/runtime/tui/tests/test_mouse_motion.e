note
	description: "[
		P2 item W6, mouse motion (review/p2_terminal_widgets_plan.md):
		  * the parser: an SGR report with the motion bit (32) and no button (low bits 3) is
		    a move, crossterm's `MouseEventKind::Moved`, with or without modifiers; reports
		    with the motion bit and a button (32 + 0 .. 2) stay drags;
		  * coalescing: a burst of parsed motion reports reaches the application as its newest
		    move (SYNCHRONIZED_EVENT_QUEUE, review finding M5);
		  * motion reporting: the exact bytes that turn mode 1003 on and off (with mouse capture,
		    before the console modes are restored, in `run`), and what VIRTUAL_TERMINAL records.
		    The handlers' reset strings are checked in TEST_PLATFORM_DRIVER, the order around a
		    stop in TEST_SUSPEND_RESUME.
		Mode 1003 (any-event tracking, `CSI ? 1003 h` / `l`) and the SGR button codes are xterm's (ctlseqs, "Mouse Tracking"), as crossterm's
		`parse_cb` reads them: 32 + 3 is `Moved`, 32 + 0 .. 2 is `Drag (button)`. Checked
		against crossterm's documentation and the xterm control sequences, not against the
		crossterm source (not in the repository).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_MOUSE_MOTION

inherit
	EQA_TEST_SET

feature -- Parser

	test_motion_report_is_a_move
			-- `CSI < 35 ; 10 ; 5 M` is a move at column 9, row 4 (0-based), not a drag with
			-- button 3; the same with `m` stays a move (crossterm turns only a press into a
			-- release).
		local
			l_parser: ANSI_INPUT_PARSER
		do
			create l_parser.make
			l_parser.parse_code (27)
			l_parser.parse_string ("[<35;10;5M")
			assert ("one event", l_parser.events.count = 1)
			assert ("a move at 9, 4", attached {MOUSE_EVENT} l_parser.events.first as m and then
				(m.is_move and not m.is_drag and m.column = 9 and m.row = 4 and m.button = {MOUSE_EVENT}.Button_none))
			assert ("no modifiers", attached {MOUSE_EVENT} l_parser.events.first as m2 and then
				not (m2.modifiers.is_shift or m2.modifiers.is_alt or m2.modifiers.is_control))
			l_parser.wipe_out
			l_parser.parse_code (27)
			l_parser.parse_string ("[<35;1;1m")
			assert ("final m: still a move", attached {MOUSE_EVENT} l_parser.events.first as m3 and then
				(m3.is_move and m3.column = 0 and m3.row = 0))
		end

	test_motion_report_with_modifiers
			-- The modifier bits of a motion report: Shift (4), Alt (8), Ctrl (16), all three.
		local
			l_parser: ANSI_INPUT_PARSER
		do
			create l_parser.make
			l_parser.parse_code (27)
			l_parser.parse_string ("[<39;2;3M")
			assert ("shift move", attached {MOUSE_EVENT} l_parser.events.last as m1 and then
				(m1.is_move and m1.modifiers.is_shift and not m1.modifiers.is_alt and not m1.modifiers.is_control))
			l_parser.parse_code (27)
			l_parser.parse_string ("[<43;2;3M")
			assert ("alt move", attached {MOUSE_EVENT} l_parser.events.last as m2 and then
				(m2.is_move and m2.modifiers.is_alt and not m2.modifiers.is_shift and not m2.modifiers.is_control))
			l_parser.parse_code (27)
			l_parser.parse_string ("[<51;2;3M")
			assert ("ctrl move", attached {MOUSE_EVENT} l_parser.events.last as m3 and then
				(m3.is_move and m3.modifiers.is_control and not m3.modifiers.is_shift and not m3.modifiers.is_alt))
			l_parser.parse_code (27)
			l_parser.parse_string ("[<63;80;24M")
			assert ("all three", attached {MOUSE_EVENT} l_parser.events.last as m4 and then
				(m4.is_move and m4.modifiers.is_control and m4.modifiers.is_shift and m4.modifiers.is_alt
				and m4.column = 79 and m4.row = 23))
			assert ("four events", l_parser.events.count = 4)
		end

	test_drag_reports_unchanged
			-- The motion bit with a button is still a drag with that button, also with Ctrl.
		local
			l_parser: ANSI_INPUT_PARSER
		do
			create l_parser.make
			l_parser.parse_code (27)
			l_parser.parse_string ("[<32;5;5M")
			assert ("left drag", attached {MOUSE_EVENT} l_parser.events.last as m1 and then
				(m1.is_drag and not m1.is_move and m1.button = {MOUSE_EVENT}.Button_left))
			l_parser.parse_code (27)
			l_parser.parse_string ("[<33;5;5M")
			assert ("middle drag", attached {MOUSE_EVENT} l_parser.events.last as m2 and then
				(m2.is_drag and m2.button = {MOUSE_EVENT}.Button_middle))
			l_parser.parse_code (27)
			l_parser.parse_string ("[<34;5;5M")
			assert ("right drag", attached {MOUSE_EVENT} l_parser.events.last as m3 and then
				(m3.is_drag and m3.button = {MOUSE_EVENT}.Button_right))
			l_parser.parse_code (27)
			l_parser.parse_string ("[<48;5;5M")
			assert ("ctrl left drag", attached {MOUSE_EVENT} l_parser.events.last as m4 and then
				(m4.is_drag and m4.button = {MOUSE_EVENT}.Button_left and m4.modifiers.is_control))
			l_parser.parse_code (27)
			l_parser.parse_string ("[<0;5;5M")
			assert ("a press stays a press", attached {MOUSE_EVENT} l_parser.events.last as m5 and then m5.is_down)
		end

feature -- Coalescing

	test_motion_burst_coalesced
			-- Ten motion reports parsed in one read reach the consumer as the newest move; a
			-- move with other modifiers and a press break the run, and are kept.
		local
			l_parser: ANSI_INPUT_PARSER
			l_queue: SYNCHRONIZED_EVENT_QUEUE
			i: INTEGER
		do
			create l_parser.make
			create l_queue.make
			from i := 1 until i > 10 loop
				l_parser.parse_code (27)
				l_parser.parse_string ("[<35;" + i.out + ";3M")
				i := i + 1
			end
			l_parser.parse_code (27)
			l_parser.parse_string ("[<51;20;3M")
			l_parser.parse_code (27)
			l_parser.parse_string ("[<0;20;3M")
			l_parser.parse_code (27)
			l_parser.parse_string ("[<35;21;3M")
			l_parser.parse_code (27)
			l_parser.parse_string ("[<35;22;3M")
			across l_parser.events as e loop
				l_queue.push (e)
			end
			assert ("14 pushed", l_queue.count = 14)
			assert ("newest of the burst", attached {MOUSE_EVENT} l_queue.poll as m1 and then
				(m1.is_move and m1.column = 9))
			assert ("ctrl move kept", attached {MOUSE_EVENT} l_queue.poll as m2 and then
				(m2.is_move and m2.modifiers.is_control and m2.column = 19))
			assert ("press kept", attached {MOUSE_EVENT} l_queue.poll as m3 and then m3.is_down)
			assert ("newest after the press", attached {MOUSE_EVENT} l_queue.poll as m4 and then
				(m4.is_move and m4.column = 21))
			assert ("empty", l_queue.is_empty)
			assert ("ten merged away", l_queue.coalesced_count = 10)
		end

feature -- Motion reporting

	test_ansi_backend_motion_sequences
			-- `enable_mouse_motion` writes exactly `CSI ? 1003 h` and `disable_mouse_motion`
			-- `CSI ? 1003 l`. `disable_mouse_capture` turns motion off too, in crossterm's
			-- `DisableMouseCapture` order (`?1006l ?1003l ?1002l ?1000l`), and writes no `?1003l`
			-- when motion was off. Motion needs capture.
		local
			l_backend: ANSI_TERMINAL_BACKEND
			l_sink: STRING_32
		do
			create l_sink.make_empty
			create l_backend.make_with_driver_and_sink (create {FAKE_CONSOLE_DRIVER}, l_sink)
			assert ("off at first", not l_backend.is_mouse_motion_enabled)
			assert ("needs capture", precondition_raised (agent l_backend.enable_mouse_motion, "mouse_captured"))
			l_backend.enable_mouse_capture
			assert ("capture bytes unchanged", l_sink.same_string_general ("%/27/[?1000h%/27/[?1002h%/27/[?1006h"))
			l_sink.wipe_out
			l_backend.enable_mouse_motion
			assert ("CSI ? 1003 h", l_sink.same_string_general ("%/27/[?1003h"))
			assert ("on", l_backend.is_mouse_motion_enabled and l_backend.is_mouse_captured)
			l_sink.wipe_out
			l_backend.disable_mouse_motion
			assert ("CSI ? 1003 l", l_sink.same_string_general ("%/27/[?1003l"))
			assert ("off, still captured", not l_backend.is_mouse_motion_enabled and l_backend.is_mouse_captured)
			l_sink.wipe_out
			l_backend.disable_mouse_capture
			assert ("no ?1003l when off", l_sink.same_string_general ("%/27/[?1006l%/27/[?1002l%/27/[?1000l"))
			l_backend.enable_mouse_capture
			l_backend.enable_mouse_motion
			l_sink.wipe_out
			l_backend.disable_mouse_capture
			assert ("crossterm order", l_sink.same_string_general ("%/27/[?1006l%/27/[?1003l%/27/[?1002l%/27/[?1000l"))
			assert ("both off", not l_backend.is_mouse_motion_enabled and not l_backend.is_mouse_captured)
		end

	test_leave_raw_mode_turns_motion_off_first
			-- `leave_raw_mode` writes and flushes `?1003l` with the other resets before the
			-- driver restores the console modes.
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_sink: STRING_32
			l_backend: ANSI_TERMINAL_BACKEND
		do
			create l_driver
			create l_sink.make_empty
			l_driver.watch_sink (l_sink)
			create l_backend.make_with_driver_and_sink (l_driver, l_sink)
			l_backend.enter_raw_mode
			l_backend.enable_mouse_capture
			l_backend.enable_mouse_motion
			l_backend.leave_raw_mode
			assert ("restored once", l_driver.restore_count = 1)
			assert ("motion off before the restore", attached l_driver.output_at_restore as l_out and then
				l_out.has_substring ("%/27/[?1006l%/27/[?1003l%/27/[?1002l%/27/[?1000l"))
			assert ("off", not l_backend.is_mouse_motion_enabled)
		end

	test_virtual_terminal_records_motion
			-- VIRTUAL_TERMINAL records motion reporting and logs it; releasing the mouse turns
			-- it off.
		local
			l_vt: VIRTUAL_TERMINAL
		do
			create l_vt.make (10, 3)
			l_vt.enable_mouse_capture
			l_vt.enable_mouse_motion
			assert ("on", l_vt.is_mouse_motion_enabled)
			assert ("logged", l_vt.operations.last.same_string ("enable_mouse_motion"))
			l_vt.disable_mouse_motion
			assert ("off", not l_vt.is_mouse_motion_enabled and l_vt.is_mouse_captured)
			assert ("logged off", l_vt.operations.last.same_string ("disable_mouse_motion"))
			l_vt.enable_mouse_motion
			l_vt.disable_mouse_capture
			assert ("off with the capture", not l_vt.is_mouse_motion_enabled and not l_vt.is_mouse_captured)
		end

	test_app_motion_enable_and_disable
			-- `set_mouse_motion` (after `set_mouse_capture`): `run` writes `?1003h` right after
			-- the capture modes and `?1003l` with them on the way out, once each. Without it
			-- no 1003 is written. Motion needs capture, and turning capture off turns it off.
		local
			l_app: TEST_TUI_APP_IMPL
			l_sink: STRING_32
		do
			l_app := new_app ("q")
			assert ("needs capture", precondition_raised (agent l_app.set_mouse_motion (True), "capture_requested"))
			l_app.set_mouse_capture (True)
			l_app.set_mouse_motion (True)
			assert ("requested", l_app.is_mouse_motion_requested)
			l_sink := app_sink (l_app)
			l_app.run
			assert ("on after capture", occurrences (l_sink, "%/27/[?1000h%/27/[?1002h%/27/[?1006h%/27/[?1003h") = 1)
			assert ("off with capture", occurrences (l_sink, "%/27/[?1006l%/27/[?1003l%/27/[?1002l%/27/[?1000l") = 1)
			assert ("once each", occurrences (l_sink, "?1003h") = 1 and occurrences (l_sink, "?1003l") = 1)
			assert ("backend off", not l_app.backend.is_mouse_motion_enabled)
			l_app.set_mouse_capture (False)
			assert ("off with capture request", not l_app.is_mouse_motion_requested)

			l_app := new_app ("q")
			l_app.set_mouse_capture (True)
			l_sink := app_sink (l_app)
			l_app.run
			assert ("capture without motion", occurrences (l_sink, "%/27/[?1000h%/27/[?1002h%/27/[?1006h") = 1)
			assert ("no 1003", occurrences (l_sink, "1003") = 0)
		end

	test_app_motion_toggled_while_running
			-- `set_mouse_motion` while running writes the mode at once: a turns it on, b off, c
			-- on again, q quits; the exit turns it off with the capture. Turning it on twice
			-- writes it once.
		local
			l_app: TEST_TUI_APP_IMPL
			l_sink: STRING_32
		do
			l_app := new_app ("abcq")
			l_app.set_mouse_capture (True)
			l_app.set_key_hook (agent toggle_motion (?, l_app))
			l_sink := app_sink (l_app)
			l_app.run
			assert ("on twice", occurrences (l_sink, "%/27/[?1003h") = 2)
			assert ("off at b and at the exit", occurrences (l_sink, "?1003l") = 2)
			assert ("in order", l_sink.substring_index ("?1003h", 1) < l_sink.substring_index ("?1003l", 1)
				and l_sink.substring_index ("?1003l", 1) < l_sink.substring_index ("?1003h", l_sink.substring_index ("?1003l", 1)))
			assert ("off at the exit with the capture", occurrences (l_sink, "%/27/[?1006l%/27/[?1003l%/27/[?1002l%/27/[?1000l") = 1)
			assert ("still requested", l_app.is_mouse_motion_requested)
			assert ("backend off", not l_app.backend.is_mouse_motion_enabled)
		end

feature {NONE} -- Helpers

	toggle_motion (a_key: KEY_EVENT; a_app: TEST_TUI_APP_IMPL)
			-- a or c: motion on (twice for c); b: off.
		do
			if a_key.code.is_char then
				inspect a_key.code.character
				when 'a' then
					a_app.set_mouse_motion (True)
				when 'b' then
					a_app.set_mouse_motion (False)
				when 'c' then
					a_app.set_mouse_motion (True)
					a_app.set_mouse_motion (True)
				else
				end
			end
		end

	new_app (a_input: READABLE_STRING_8): TEST_TUI_APP_IMPL
			-- Fullscreen application on a fake console replaying `a_input`, output captured.
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

	app_sink (a_app: TEST_TUI_APP_IMPL): STRING_32
			-- The output capture of `a_app`.
		do
			check attached a_app.backend.output_sink as s then
				Result := s
			end
		end

	occurrences (a_text: READABLE_STRING_32; a_part: READABLE_STRING_GENERAL): INTEGER
			-- Number of non-overlapping occurrences of `a_part` in `a_text`
		local
			i: INTEGER
		do
			from
				i := a_text.substring_index (a_part, 1)
			until
				i = 0
			loop
				Result := Result + 1
				i := a_text.substring_index (a_part, i + a_part.count)
			end
		end

	precondition_raised (a_action: ROUTINE; a_tag: STRING): BOOLEAN
			-- Does `a_action` raise a precondition violation tagged `a_tag`?
		local
			l_retried: BOOLEAN
		do
			if not l_retried then
				a_action.call
			end
		rescue
			if not l_retried then
				l_retried := True
				Result := attached (create {EXCEPTION_MANAGER}).last_exception as e and then
					(attached {PRECONDITION_VIOLATION} e.original as pv and then
					(attached pv.description as d and then d.same_string (a_tag)))
				retry
			end
		end

end
