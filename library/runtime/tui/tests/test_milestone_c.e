note
	description: "[
		Unit tests for Milestone C:
		- Platform console driver contracts (TERMINAL_DRIVER)
		- UTF-8 streaming input decoder, including recovery from broken sequences
		- Lone ESC timeout flush and Alt+key
		- Mouse modifiers and horizontal scrolling
		- Focus gained/lost events
		- Bracketed paste events, including escape sequences inside the paste
		- Modified function keys and the xterm modifier bitmask
		- Cursor position reports (DSR answers)
		- Synchronized event queue: timeout and cross-thread wake-up
		- EVENT_THREAD with a scripted driver, and failure reporting
		- ANSI_TERMINAL_BACKEND restoration order and cursor position query
		- TERMINAL resize on draw, inline viewport setup / insert_before / restore
		- TUI_APPLICATION run loop: restoration, exception propagation, ticks under load

		Type checks are asserted, never guarded with `if attached', so a wrong event type fails.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_MILESTONE_C

inherit
	EQA_TEST_SET

feature -- Driver

	test_platform_console_driver
			-- TERMINAL_DRIVER (Win32 or POSIX, chosen by the ECF) mode lifecycle and contracts.
		local
			l_driver: TERMINAL_DRIVER
		do
			create l_driver
			assert ("width positive", l_driver.console_width > 0)
			assert ("height positive", l_driver.console_height > 0)
			assert ("vt enable", l_driver.enable_vt_mode)
			assert ("raw enable", l_driver.enable_raw_mode)
			assert ("is_raw", l_driver.is_raw)
			assert ("raw disable", l_driver.disable_raw_mode)
			assert ("not is_raw", not l_driver.is_raw)
			assert ("mouse enable", l_driver.enable_mouse)
			assert ("mouse active", l_driver.is_mouse_enabled)
			assert ("mouse disable", l_driver.disable_mouse)
			assert ("mouse inactive", not l_driver.is_mouse_enabled)
			l_driver.restore_modes
			assert ("restore not raw", not l_driver.is_raw)
			assert ("restore no mouse", not l_driver.is_mouse_enabled)
		end

feature -- Parser

	test_utf8_streaming_input
			-- UTF-8 multi-byte decoding in ANSI_INPUT_PARSER, including broken sequences.
		local
			l_parser: ANSI_INPUT_PARSER
		do
			create l_parser.make

			-- 1. Spanish 'ñ': 0xC3, 0xB1 -> U+00F1
			l_parser.parse_code (0xC3)
			assert ("waiting for continuation", l_parser.events.is_empty)
			l_parser.parse_code (0xB1)
			assert_single_char (l_parser, 0xF1, "n tilde")

			-- 2. Japanese '日': 0xE6, 0x97, 0xA5 -> U+65E5
			l_parser.parse_code (0xE6)
			l_parser.parse_code (0x97)
			assert ("waiting for third byte", l_parser.events.is_empty)
			l_parser.parse_code (0xA5)
			assert_single_char (l_parser, 0x65E5, "nichi")

			-- 3. 4-byte: 0xF0, 0x9F, 0x98, 0x80 -> U+1F600
			l_parser.parse_code (0xF0)
			l_parser.parse_code (0x9F)
			l_parser.parse_code (0x98)
			assert ("waiting 4th byte", l_parser.events.is_empty)
			l_parser.parse_code (0x80)
			assert_single_char (l_parser, 0x1F600, "emoji")

			-- 4. A lead byte interrupted by another lead byte: U+FFFD for the broken sequence
			-- (review finding U4: it used to vanish), then decoding restarts
			l_parser.parse_code (0xC3)
			l_parser.parse_code (0xE6)
			l_parser.parse_code (0x97)
			l_parser.parse_code (0xA5)
			assert_two_chars (l_parser, 0xFFFD, 0x65E5, "restart after broken sequence")

			-- 5. An interrupted sequence followed by ASCII: U+FFFD, then the ASCII key
			l_parser.parse_code (0xE6)
			l_parser.parse_code (('a').natural_32_code)
			assert_two_chars (l_parser, 0xFFFD, ('a').natural_32_code, "ascii after broken sequence")
		end

	test_lone_escape_flush
			-- Lone ESC is flushed as Escape; ESC+char is Alt+char; ESC ESC is Escape.
		local
			l_parser: ANSI_INPUT_PARSER
		do
			create l_parser.make
			l_parser.parse_code (27)
			assert ("escape pending", l_parser.events.is_empty)
			l_parser.flush_escape
			assert ("escape emitted on flush", l_parser.events.count = 1)
			assert ("is escape", attached {KEY_EVENT} l_parser.events.first as k and then k.code.is_escape)
			l_parser.wipe_out

			-- Alt+x
			l_parser.parse_code (27)
			l_parser.parse_string ("x")
			assert ("one alt event", l_parser.events.count = 1)
			assert ("alt x", attached {KEY_EVENT} l_parser.events.first as k2 and then
				(k2.code.is_char and then k2.code.character = 'x' and k2.modifiers.is_alt and not k2.modifiers.is_control))
			l_parser.wipe_out

			-- ESC ESC [A: Escape, then Up
			l_parser.parse_code (27)
			l_parser.parse_code (27)
			l_parser.parse_string ("[A")
			assert ("escape then up", l_parser.events.count = 2)
			assert ("first escape", attached {KEY_EVENT} l_parser.events.first as k3 and then k3.code.is_escape)
			assert ("second up", attached {KEY_EVENT} l_parser.events.last as k4 and then k4.code ~ {KEY_CODE}.up)
		end

	test_mouse_modifiers_and_horizontal_scroll
			-- SGR 1006 mouse modifier bits and horizontal wheel scrolling.
		local
			l_parser: ANSI_INPUT_PARSER
		do
			create l_parser.make

			-- Ctrl (16) + Left (0) at col 10, row 5
			l_parser.parse_code (27)
			l_parser.parse_string ("[<16;10;5M")
			assert ("mouse event parsed", l_parser.events.count = 1)
			assert ("ctrl left down at 9,4", attached {MOUSE_EVENT} l_parser.events.first as m1 and then
				(m1.is_down and m1.modifiers.is_control and m1.column = 9 and m1.row = 4))
			l_parser.wipe_out

			l_parser.parse_code (27)
			l_parser.parse_string ("[<66;15;8M")
			assert ("scroll left", attached {MOUSE_EVENT} l_parser.events.first as m2 and then
				(m2.is_scroll_left and not m2.is_scroll_right))
			l_parser.wipe_out

			l_parser.parse_code (27)
			l_parser.parse_string ("[<67;15;8M")
			assert ("scroll right", attached {MOUSE_EVENT} l_parser.events.first as m3 and then
				(m3.is_scroll_right and not m3.is_scroll_left))
		end

	test_focus_events
			-- Focus gained (\e[I) and focus lost (\e[O) parsing.
		local
			l_parser: ANSI_INPUT_PARSER
		do
			create l_parser.make
			l_parser.parse_code (27)
			l_parser.parse_string ("[I")
			assert ("one gained event", l_parser.events.count = 1)
			assert ("gained", attached {FOCUS_EVENT} l_parser.events.first as f1 and then f1.has_focus)
			l_parser.wipe_out

			l_parser.parse_code (27)
			l_parser.parse_string ("[O")
			assert ("one lost event", l_parser.events.count = 1)
			assert ("lost", attached {FOCUS_EVENT} l_parser.events.first as f2 and then not f2.has_focus)
		end

	test_bracketed_paste_event
			-- \e[200~ ... \e[201~ becomes one PASTE_EVENT; sequences inside are literal text.
		local
			l_parser: ANSI_INPUT_PARSER
			l_expected: STRING_32
		do
			create l_parser.make
			l_parser.parse_code (27)
			l_parser.parse_string ("[200~")
			assert ("in paste mode", l_parser.is_in_paste)
			l_parser.parse_string ("EiffelTUI Rocks")
			l_parser.parse_code (27)
			l_parser.parse_string ("[201~")
			assert ("paste ended", not l_parser.is_in_paste)
			assert ("single paste event", l_parser.events.count = 1)
			assert ("content matches", attached {PASTE_EVENT} l_parser.events.first as p and then p.text.same_string ("EiffelTUI Rocks"))
			l_parser.wipe_out

			-- Arrow-key, SS3 and mouse sequences inside the paste stay in the text
			l_parser.parse_code (27)
			l_parser.parse_string ("[200~a")
			l_parser.parse_code (27)
			l_parser.parse_string ("[Ab")
			l_parser.parse_code (27)
			l_parser.parse_string ("OPc")
			l_parser.parse_code (27)
			l_parser.parse_string ("[<0;1;1Md")
			l_parser.parse_code (27)
			l_parser.parse_string ("[201~")
			create l_expected.make_from_string ("a")
			l_expected.append_character ((27).to_character_32)
			l_expected.append ("[Ab")
			l_expected.append_character ((27).to_character_32)
			l_expected.append ("OPc")
			l_expected.append_character ((27).to_character_32)
			l_expected.append ("[<0;1;1Md")
			assert ("only the paste event", l_parser.events.count = 1)
			assert ("sequences kept verbatim", attached {PASTE_EVENT} l_parser.events.first as p2 and then p2.text.same_string (l_expected))
		end

	test_modified_function_keys
			-- Modified F1..F4 and the full xterm modifier bitmask (1 + Shift|Alt<<1|Ctrl<<2|Super<<3).
		local
			l_parser: ANSI_INPUT_PARSER
		do
			create l_parser.make
			l_parser.parse_code (27)
			l_parser.parse_string ("[1;5P")
			assert ("ctrl f1", attached {KEY_EVENT} l_parser.events.first as k1 and then
				(k1.code.is_function and then k1.code.function_number = 1 and k1.modifiers.is_control))
			l_parser.wipe_out

			l_parser.parse_code (27)
			l_parser.parse_string ("[1;2Q")
			assert ("shift f2", attached {KEY_EVENT} l_parser.events.first as k2 and then
				(k2.code.is_function and then k2.code.function_number = 2 and k2.modifiers.is_shift))
			l_parser.wipe_out

			-- 4 = 1 + (Shift | Alt)
			l_parser.parse_code (27)
			l_parser.parse_string ("[1;4A")
			assert ("shift alt up", attached {KEY_EVENT} l_parser.events.first as k3 and then
				(k3.code ~ {KEY_CODE}.up and k3.modifiers.is_shift and k3.modifiers.is_alt and not k3.modifiers.is_control))
			l_parser.wipe_out

			-- 8 = 1 + (Shift | Alt | Ctrl)
			l_parser.parse_code (27)
			l_parser.parse_string ("[1;8B")
			assert ("shift alt ctrl down", attached {KEY_EVENT} l_parser.events.first as k4 and then
				(k4.code ~ {KEY_CODE}.down and k4.modifiers.is_shift and k4.modifiers.is_alt and k4.modifiers.is_control))
			l_parser.wipe_out

			-- 9 = 1 + Super
			l_parser.parse_code (27)
			l_parser.parse_string ("[1;9C")
			assert ("super right", attached {KEY_EVENT} l_parser.events.first as k5 and then
				(k5.code ~ {KEY_CODE}.right and k5.modifiers.is_super and not k5.modifiers.is_shift))
		end

	test_cursor_position_report
			-- \e[row;colR is a cursor position report (0-based), never an F3 key.
		local
			l_parser: ANSI_INPUT_PARSER
		do
			create l_parser.make
			l_parser.parse_code (27)
			l_parser.parse_string ("[12;40R")
			assert ("one report", l_parser.events.count = 1)
			assert ("report at 11,39", attached {CURSOR_POSITION_EVENT} l_parser.events.first as r and then
				(r.row = 11 and r.column = 39))
			l_parser.wipe_out

			-- Plain \e[R (no parameters) is still F3
			l_parser.parse_code (27)
			l_parser.parse_string ("[R")
			assert ("f3", attached {KEY_EVENT} l_parser.events.first as k and then
				(k.code.is_function and then k.code.function_number = 3))
		end

feature -- Queue and input thread

	test_synchronized_queue_timeout
			-- poll_with_timeout times out when empty and wakes immediately on a cross-thread push.
		local
			l_queue: SYNCHRONIZED_EVENT_QUEUE
			l_ev: detachable EVENT
			l_pusher: WORKER_THREAD
			l_start, l_elapsed: INTEGER_64
		do
			create l_queue.make
			assert ("queue empty initially", l_queue.is_empty)

			l_start := {MONOTONIC_CLOCK}.milliseconds
			l_ev := l_queue.poll_with_timeout (30)
			l_elapsed := {MONOTONIC_CLOCK}.milliseconds - l_start
			assert ("timed out returns void", l_ev = Void)
			assert ("waited about the timeout", l_elapsed >= 20)

			l_queue.push (create {TICK_EVENT}.default_create)
			l_ev := l_queue.poll_with_timeout (10)
			assert ("event retrieved", attached l_ev as e and then e.is_tick)
			assert ("empty after dequeue", l_queue.is_empty)

			-- A push from another thread must wake a long wait early
			create l_pusher.make (agent push_after_delay (l_queue, 30))
			l_start := {MONOTONIC_CLOCK}.milliseconds
			l_pusher.launch
			l_ev := l_queue.poll_with_timeout (5000)
			l_elapsed := {MONOTONIC_CLOCK}.milliseconds - l_start
			l_pusher.join
			assert ("woken by push", attached l_ev as e2 and then e2.is_tick)
			assert ("woke well before the timeout", l_elapsed < 2000)
		end

	test_synchronized_queue_wake
			-- `wake` ends a long `poll_with_timeout` with no event, from another thread or when
			-- called before the wait; the next wait is a normal one again.
		local
			l_queue: SYNCHRONIZED_EVENT_QUEUE
			l_waker: WORKER_THREAD
			l_start, l_elapsed: INTEGER_64
		do
			create l_queue.make
			l_queue.wake
			l_start := {MONOTONIC_CLOCK}.milliseconds
			assert ("woken before the wait", l_queue.poll_with_timeout (5000) = Void)
			assert ("returned at once", {MONOTONIC_CLOCK}.milliseconds - l_start < 2000)

			l_start := {MONOTONIC_CLOCK}.milliseconds
			assert ("then a normal wait", l_queue.poll_with_timeout (30) = Void)
			assert ("waited about the timeout", {MONOTONIC_CLOCK}.milliseconds - l_start >= 20)

			create l_waker.make (agent (q: SYNCHRONIZED_EVENT_QUEUE)
				do
					(create {EXECUTION_ENVIRONMENT}).sleep (30_000_000)
					q.wake
				end (l_queue))
			l_start := {MONOTONIC_CLOCK}.milliseconds
			l_waker.launch
			assert ("woken with no event", l_queue.poll_with_timeout (5000) = Void)
			l_elapsed := {MONOTONIC_CLOCK}.milliseconds - l_start
			l_waker.join
			assert ("woke well before the timeout", l_elapsed < 2000)

			l_queue.wake
			l_queue.push (create {TICK_EVENT}.default_create)
			assert ("a queued event still comes first", attached l_queue.poll_with_timeout (5000) as e and then e.is_tick)
		end

	test_event_thread_with_fake_driver
			-- EVENT_THREAD reads scripted bytes, parses them and pushes events in order.
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_queue: SYNCHRONIZED_EVENT_QUEUE
			l_thread: EVENT_THREAD
			l_events: ARRAYED_LIST [EVENT]
		do
			create l_driver
			l_driver.script ("ab%/27/[A")
			create l_queue.make
			create l_thread.make (l_queue, l_driver)
			l_thread.set_poll_interval (5)
			l_thread.launch
			l_events := collect_events (l_queue, 3, 3000)
			l_thread.stop
			l_thread.join
			assert ("three events", l_events.count = 3)
			assert ("a", attached {KEY_EVENT} l_events.i_th (1) as k1 and then (k1.code.is_char and then k1.code.character = 'a'))
			assert ("b", attached {KEY_EVENT} l_events.i_th (2) as k2 and then (k2.code.is_char and then k2.code.character = 'b'))
			assert ("up", attached {KEY_EVENT} l_events.i_th (3) as k3 and then k3.code ~ {KEY_CODE}.up)
			assert ("not failed", not l_thread.has_failed)
		end

	test_event_thread_failure_reported
			-- A driver that keeps raising makes the thread give up and report it, not vanish.
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_queue: SYNCHRONIZED_EVENT_QUEUE
			l_thread: EVENT_THREAD
			l_deadline: INTEGER_64
		do
			create l_driver
			l_driver.set_failing_reads (True)
			create l_queue.make
			create l_thread.make (l_queue, l_driver)
			l_thread.launch
			from
				l_deadline := {MONOTONIC_CLOCK}.milliseconds + 3000
			until
				l_thread.has_failed or {MONOTONIC_CLOCK}.milliseconds > l_deadline
			loop
				sleep_ms (5)
			end
			l_thread.join
			assert ("failure reported", l_thread.has_failed)
			assert ("retried before giving up", l_driver.read_count >= {EVENT_THREAD}.Max_consecutive_failures)
			assert ("description set", not l_thread.failure_description.is_empty)
		end

feature -- Backend

	test_backend_restores_before_driver
			-- leave_raw_mode writes and flushes the reporting resets before restoring console modes.
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
			l_backend.enable_bracketed_paste
			l_backend.enable_focus_change
			l_backend.leave_raw_mode
			assert ("raw entered once", l_driver.raw_enable_count = 1)
			assert ("raw left once", l_driver.raw_disable_count = 1)
			assert ("modes restored once", l_driver.restore_count = 1)
			assert ("resets written before restore", attached l_driver.output_at_restore as l_out and then
				(l_out.has_substring (csi + "?1000l") and l_out.has_substring (csi + "?2004l") and l_out.has_substring (csi + "?1004l")))
			assert ("backend not raw", not l_backend.is_raw)
		end

	test_backend_cursor_position_query
			-- query_cursor_position sends DSR and parses the scripted answer.
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_sink: STRING_32
			l_backend: ANSI_TERMINAL_BACKEND
		do
			create l_driver
			create l_sink.make_empty
			create l_backend.make_with_driver_and_sink (l_driver, l_sink)
			l_driver.script ("x%/27/[6;11R")
			assert ("report parsed", attached l_backend.query_cursor_position as p and then (p.row = 5 and p.column = 10))
			assert ("dsr sent", l_sink.has_substring (csi + "6n"))
			assert ("cursor tracked", l_backend.cursor_row = 5 and l_backend.cursor_column = 10)

			-- No answer: Void, after a bounded wait
			assert ("no answer is void", l_backend.query_cursor_position = Void)
		end

feature -- Terminal

	test_terminal_resize_on_draw
			-- A backend size change is picked up by draw: new buffers, cleared screen, full repaint.
		local
			l_vt: VIRTUAL_TERMINAL
			l_term: TERMINAL [VIRTUAL_TERMINAL]
		do
			create l_vt.make (80, 24)
			create l_term.make (l_vt)
			l_term.draw (agent draw_label (?, "before"))
			assert ("drawn before", l_vt.line (0).starts_with ("before"))

			l_vt.set_size (40, 10)
			l_vt.operations.wipe_out
			l_term.draw (agent draw_label (?, "after"))
			assert ("width follows backend", l_term.width = 40)
			assert ("height follows backend", l_term.height = 10)
			assert ("screen cleared", l_vt.operations.has ("clear_screen"))
			assert ("repainted", l_vt.line (0).starts_with ("after"))
		end

	test_inline_viewport_setup_and_insert_before
			-- Inline viewport: placed at the cursor, scrolls when needed, insert_before writes
			-- rows above it and pushes older rows into the scrollback, restore leaves the cursor below.
		local
			l_vt: VIRTUAL_TERMINAL
			l_vp: VIEWPORT
			l_term: TERMINAL [VIRTUAL_TERMINAL]
		do
			create l_vt.make (40, 10)
			l_vt.move_cursor (7, 0)
			l_vt.put_string ("prompt")
			l_vt.move_cursor (8, 0)
			create l_vp.make_inline (4)
			create l_term.make_with_viewport (l_vt, l_vp)

			-- Cursor on row 8, 4 rows needed, 10 rows on screen: scroll by 2, origin 6
			l_term.setup_inline_viewport
			assert ("origin moved up", l_term.viewport_origin_row = 6)
			assert ("scrolled two rows", l_vt.scrollback.count = 2)
			assert ("prompt scrolled with the screen", l_vt.line (5).starts_with ("prompt"))

			l_term.draw (agent draw_label (?, "live"))
			assert ("viewport drawn at origin", l_vt.line (6).starts_with ("live"))
			assert ("not drawn at row 0", not l_vt.line (0).starts_with ("live"))

			-- No room below the viewport: the screen scrolls by 2, lines land on rows 4..5
			l_term.insert_before (2, agent draw_two_logs)
			assert ("log1 above viewport", l_vt.line (4).starts_with ("log1"))
			assert ("log2 above viewport", l_vt.line (5).starts_with ("log2"))
			assert ("prompt above the inserted lines", l_vt.line (3).starts_with ("prompt"))
			assert ("viewport stays at bottom", l_term.viewport_origin_row = 6)
			assert ("older rows in scrollback", l_vt.scrollback.count = 4)

			l_term.draw (agent draw_label (?, "live"))
			assert ("viewport repainted after insert", l_vt.line (6).starts_with ("live"))

			-- Viewport ends on the last row: restoring scrolls one line and parks the cursor there
			l_term.restore_inline_viewport
			assert ("cursor on last row", l_vt.cursor_row = 9 and l_vt.cursor_column = 0)
			assert ("viewport content kept", l_vt.line (5).starts_with ("live"))
		end

	test_inline_viewport_moves_down_while_room
			-- With free rows below, insert_before moves the viewport down instead of scrolling.
		local
			l_vt: VIRTUAL_TERMINAL
			l_vp: VIEWPORT
			l_term: TERMINAL [VIRTUAL_TERMINAL]
		do
			create l_vt.make (40, 10)
			create l_vp.make_inline (3)
			create l_term.make_with_viewport (l_vt, l_vp)
			l_term.setup_inline_viewport
			assert ("origin at cursor row 0", l_term.viewport_origin_row = 0)
			l_term.insert_before (2, agent draw_two_logs)
			assert ("no scrolling", l_vt.scrollback.is_empty)
			assert ("log1 on row 0", l_vt.line (0).starts_with ("log1"))
			assert ("log2 on row 1", l_vt.line (1).starts_with ("log2"))
			assert ("viewport moved down", l_term.viewport_origin_row = 2)
			l_term.restore_inline_viewport
			assert ("cursor below viewport", l_vt.cursor_row = 5 and l_vt.cursor_column = 0)
		end

feature -- Application

	test_tui_application_run_and_restore
			-- run: raw mode + alternate screen, processes input, stops on 'q', restores in order.
		local
			l_app: TEST_TUI_APP_IMPL
			l_driver: FAKE_CONSOLE_DRIVER
			l_sink: STRING_32
		do
			l_app := new_scripted_app ("q")
			l_driver := scripted_driver (l_app)
			l_sink := scripted_sink (l_app)
			l_app.run
			assert ("stopped", not l_app.is_running)
			assert ("terminal restored", not l_app.is_terminal_set_up)
			assert ("drew at least once", l_app.draw_pass_count >= 1)
			assert ("processed q", l_app.key_count = 1)
			assert ("raw entered and left once", l_driver.raw_enable_count = 1 and l_driver.raw_disable_count = 1)
			assert ("modes restored once", l_driver.restore_count = 1)
			assert ("alternate screen entered", l_sink.has_substring (csi + "?1049h"))
			assert ("frame content written", l_sink.has_substring ("frame"))
			assert ("screen and cursor restored before modes", attached l_driver.output_at_restore as l_out and then
				(l_out.has_substring (csi + "?1049l") and l_out.has_substring (csi + "?25h")))
			assert ("input thread finished", l_app.event_thread.terminated)
		end

	test_tui_application_exception_restores_terminal
			-- An exception from render restores the terminal and is then propagated.
		local
			l_app: TEST_TUI_APP_IMPL
			l_driver: FAKE_CONSOLE_DRIVER
			l_raised: BOOLEAN
		do
			if not l_raised then
				l_app := new_scripted_app ("")
				l_driver := scripted_driver (l_app)
				l_app.set_failing_frame (2)
				l_app.set_tick_rate (10)
				l_app.run
			end
			assert ("exception propagated", l_raised)
			assert ("app attached", attached l_app)
			if attached l_app as a and attached l_driver as d then
				assert ("stopped", not a.is_running)
				assert ("terminal restored", not a.is_terminal_set_up)
				assert ("modes restored once", d.restore_count = 1)
				assert ("raw left", d.raw_disable_count = 1)
				assert ("input thread finished", a.event_thread.terminated)
			end
		rescue
			-- Only the run failure is expected; a failing assertion above must propagate
			if not l_raised then
				l_raised := True
				retry
			end
		end

	test_tui_application_ticks_under_steady_input
			-- Ticks keep coming while input arrives faster than the tick rate.
		local
			l_app: TEST_TUI_APP_IMPL
		do
			l_app := new_scripted_app ("")
			scripted_driver (l_app).set_steady_input (('x').code, 60, 5, 'q')
			l_app.set_tick_rate (20)
			l_app.run
			assert ("all keys processed", l_app.key_count = 61)
			assert ("ticks not starved", l_app.tick_count >= 5)
		end

	test_tui_application_runs_twice
			-- A second `run` on the same application reads input on a new thread with the
			-- same settings (review finding C2: it used to fail the THREAD.launch precondition).
		local
			l_app: TEST_TUI_APP_IMPL
			l_driver: FAKE_CONSOLE_DRIVER
			l_first: EVENT_THREAD
		do
			l_app := new_scripted_app ("q")
			l_driver := scripted_driver (l_app)
			l_app.event_thread.set_paste_timeout (1234)
			l_app.event_thread.set_max_paste_size (77)
			l_first := l_app.event_thread
			l_app.run
			assert ("first run processed q", l_app.key_count = 1)
			assert ("first thread finished", l_first.terminated)
			assert ("can run again", l_app.is_input_thread_available)

			-- Left over from the first run: must not reach the second one
			l_app.event_queue.push (create {KEY_EVENT}.make_char ('x'))
			l_driver.script ("q")
			l_app.run
			assert ("second run processed only its own q", l_app.key_count = 2)
			assert ("new thread", l_app.event_thread /= l_first)
			assert ("second thread finished", l_app.event_thread.terminated)
			assert ("same queue", l_app.event_thread.queue = l_app.event_queue)
			assert ("poll interval kept", l_app.event_thread.poll_interval_ms = 5)
			assert ("raw entered and left twice", l_driver.raw_enable_count = 2 and l_driver.raw_disable_count = 2)
			assert ("modes restored twice", l_driver.restore_count = 2)
			assert ("terminal restored", not l_app.is_terminal_set_up)
		end

	test_tui_application_input_thread_timeout
			-- An input thread blocked in a read does not stop within the join timeout: `run`
			-- still restores the terminal, reports it, and refuses to start another reader until
			-- `wait_for_input_thread` sees the thread end (review finding C4).
		local
			l_app: TEST_TUI_APP_IMPL
			l_driver: FAKE_CONSOLE_DRIVER
		do
			l_app := new_scripted_app ("q")
			l_driver := scripted_driver (l_app)
			l_driver.set_idle_read_ms (1500)
			-- Let 'q' stop the application only once the input thread is inside its blocked
			-- read: otherwise it could see the stop request before starting that read
			l_app.set_key_hook (agent (k: KEY_EVENT; d: FAKE_CONSOLE_DRIVER)
				local
					l_deadline: INTEGER_64
				do
					from
						l_deadline := {MONOTONIC_CLOCK}.milliseconds + 3000
					until
						d.blocked_read_count > 0 or {MONOTONIC_CLOCK}.milliseconds > l_deadline
					loop
						sleep_ms (5)
					end
				end (?, l_driver))
			l_app.run
			assert ("the thread was blocked in a read", l_driver.blocked_read_count > 0)
			assert ("terminal restored anyway", not l_app.is_terminal_set_up and l_driver.restore_count = 1)
			assert ("timeout reported", l_app.input_thread_timed_out)
			assert ("no second reader", not l_app.is_input_thread_available)
			assert ("console input still claimed", l_app.backend.is_input_in_use)

			l_app.wait_for_input_thread (5000)
			assert ("thread ended", not l_app.input_thread_timed_out and l_app.is_input_thread_available)
			assert ("console input free", not l_app.backend.is_input_in_use)

			l_driver.set_idle_read_ms (0)
			l_app.set_key_hook (Void)
			l_driver.script ("q")
			l_app.run
			assert ("runs again", l_app.key_count = 2)
			assert ("stopped in time", not l_app.input_thread_timed_out)
		end

	test_termination_request_ends_run_after_restore
			-- A termination request during `run` is only recorded by the handler; the loop stops,
			-- restores the terminal, and only then ends the process, writing nothing after the
			-- restore (review finding C5).
		local
			l_app: TEST_TUI_APP_IMPL
			l_driver: FAKE_CONSOLE_DRIVER
			l_sink: STRING_32
			l_deferring: CELL [BOOLEAN]
		do
			l_app := new_scripted_app ("x")
			l_driver := scripted_driver (l_app)
			l_sink := scripted_sink (l_app)
			create l_deferring.put (False)
			l_app.set_key_hook (agent (k: KEY_EVENT; d: FAKE_CONSOLE_DRIVER; c: CELL [BOOLEAN])
				do
					c.put (d.is_deferring_termination)
					d.simulate_termination_request (2)
				end (?, l_driver, l_deferring))
			l_app.run
			assert ("deferring while running", l_deferring.item)
			assert ("request recorded, not handled at once", l_driver.immediate_request_count = 0)
			assert ("process ended once", l_driver.finish_count = 1)
			assert ("terminal restored first", l_driver.restore_count_at_finish = 1)
			assert ("nothing written after the restore", attached l_driver.output_at_restore as l_out and then
				(l_sink.same_string (l_out) and l_driver.sink_count_at_finish = l_sink.count))
			assert ("screen left before the modes were restored", l_sink.has_substring (csi + "?1049l"))
			assert ("no longer deferring", not l_driver.is_deferring_termination)
		end

	test_termination_request_wakes_slow_loop
			-- A request recorded on another thread ends `run` promptly even when the loop waits
			-- for a slow tick: the input thread wakes it (a close event gives the loop 3 s).
		local
			l_app: TEST_TUI_APP_IMPL
			l_driver: FAKE_CONSOLE_DRIVER
			l_start: INTEGER_64
		do
			l_app := new_scripted_app ("")
			l_driver := scripted_driver (l_app)
			l_app.set_tick_rate (10_000)
			l_driver.set_request_on_read (2, 3)
			l_start := {MONOTONIC_CLOCK}.milliseconds
			l_app.run
			assert ("ended well before the tick", {MONOTONIC_CLOCK}.milliseconds - l_start < 2000)
			assert ("recorded, not handled at once", l_driver.immediate_request_count = 0)
			assert ("process ended once, after the restore", l_driver.finish_count = 1 and l_driver.restore_count_at_finish = 1)
			assert ("no tick", l_app.tick_count = 0)
		end

	test_event_budget_redraws_during_flood
			-- 20 keys waiting, each taking 30 ms to process: with a 50 ms budget the screen is
			-- drawn every couple of keys (it used to be drawn only once all were processed).
		local
			l_app: TEST_TUI_APP_IMPL
		do
			l_app := new_scripted_app ("xxxxxxxxxxxxxxxxxxxxq")
			l_app.set_tick_rate (10_000)
			l_app.set_event_budget (50)
			l_app.set_key_hook (agent (k: KEY_EVENT)
				do
					(create {EXECUTION_ENVIRONMENT}).sleep (30_000_000)
				end)
			l_app.run
			assert ("every key processed", l_app.key_count = 21)
			assert ("drawn during the flood", l_app.draw_pass_count >= 6)
		end

	test_termination_request_outside_run_is_immediate
			-- Outside `run` nothing is deferred: the handler acts at once, as before.
		local
			l_driver: FAKE_CONSOLE_DRIVER
		do
			create l_driver
			assert ("not deferring", not l_driver.is_deferring_termination)
			l_driver.simulate_termination_request (2)
			assert ("handled at once", l_driver.immediate_request_count = 1 and not l_driver.has_termination_request)
		end

	test_second_termination_request_is_immediate
			-- A second request while one is pending is handled at once, so a stuck loop cannot
			-- keep the terminal from being restored; the process still ends once.
		local
			l_app: TEST_TUI_APP_IMPL
			l_driver: FAKE_CONSOLE_DRIVER
		do
			l_app := new_scripted_app ("x")
			l_driver := scripted_driver (l_app)
			l_app.set_key_hook (agent (k: KEY_EVENT; d: FAKE_CONSOLE_DRIVER)
				do
					d.simulate_termination_request (2)
					d.simulate_termination_request (15)
				end (?, l_driver))
			l_app.run
			assert ("second handled at once", l_driver.immediate_request_count = 1)
			assert ("first one ended the process", l_driver.finish_count = 1 and l_driver.pending_request = 2)
		end

	test_event_thread_renewed
			-- `renewed` gives a launchable thread with the same queue, driver and settings,
			-- and it reads input after the original has terminated.
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_queue: SYNCHRONIZED_EVENT_QUEUE
			l_thread, l_next: EVENT_THREAD
			l_events: ARRAYED_LIST [EVENT]
		do
			create l_driver
			create l_queue.make
			create l_thread.make (l_queue, l_driver)
			l_thread.set_poll_interval (5)
			l_thread.set_paste_timeout (1234)
			l_thread.set_max_paste_size (77)
			l_thread.launch
			l_thread.stop
			l_thread.join
			assert ("original not launchable", not l_thread.is_launchable)

			l_next := l_thread.renewed
			assert ("launchable", l_next.is_launchable and not l_next.should_stop)
			assert ("same queue and driver", l_next.queue = l_queue and l_next.driver = l_driver)
			assert ("poll interval kept", l_next.poll_interval_ms = 5)
			-- The paste settings are checked through behaviour: a 100-character paste
			-- comes in two parts of at most 77
			l_driver.script ("%/27/[200~" + create {STRING_8}.make_filled ('a', 100) + "%/27/[201~")
			l_next.launch
			l_events := collect_events (l_queue, 2, 3000)
			l_next.stop
			l_next.join
			assert ("two parts", l_events.count = 2)
			assert ("first part full", attached {PASTE_EVENT} l_events.i_th (1) as p1 and then (p1.is_continued and p1.text.count = 77))
			assert ("last part", attached {PASTE_EVENT} l_events.i_th (2) as p2 and then (not p2.is_continued and p2.text.count = 23))
		end

feature {NONE} -- Helpers

	csi: STRING_32
			-- Control Sequence Introducer
		do
			create Result.make_from_string ({STRING_32} "%/27/[")
		end

	assert_single_char (a_parser: ANSI_INPUT_PARSER; a_code: NATURAL_32; a_tag: STRING)
			-- Assert `a_parser` produced exactly one character key with code `a_code`, then clear it.
		do
			assert (a_tag + ": one event", a_parser.events.count = 1)
			assert (a_tag + ": char key", attached {KEY_EVENT} a_parser.events.first as k and then
				(k.code.is_char and then k.code.character.natural_32_code = a_code))
			a_parser.wipe_out
		end

	assert_two_chars (a_parser: ANSI_INPUT_PARSER; a_first, a_second: NATURAL_32; a_tag: STRING)
			-- Assert `a_parser` produced exactly two character keys, `a_first` then `a_second`, then clear it.
		do
			assert (a_tag + ": two events", a_parser.events.count = 2)
			assert (a_tag + ": first", attached {KEY_EVENT} a_parser.events.first as k and then
				(k.code.is_char and then k.code.character.natural_32_code = a_first))
			assert (a_tag + ": second", attached {KEY_EVENT} a_parser.events.last as k and then
				(k.code.is_char and then k.code.character.natural_32_code = a_second))
			a_parser.wipe_out
		end

	push_after_delay (a_queue: SYNCHRONIZED_EVENT_QUEUE; a_delay_ms: INTEGER)
			-- Sleep `a_delay_ms`, then push a tick into `a_queue` (runs on a worker thread).
		do
			sleep_ms (a_delay_ms)
			a_queue.push (create {TICK_EVENT}.default_create)
		end

	collect_events (a_queue: SYNCHRONIZED_EVENT_QUEUE; a_count, a_timeout_ms: INTEGER): ARRAYED_LIST [EVENT]
			-- Up to `a_count` events from `a_queue`, waiting at most `a_timeout_ms` overall.
		local
			l_deadline: INTEGER_64
		do
			create Result.make (a_count)
			from
				l_deadline := {MONOTONIC_CLOCK}.milliseconds + a_timeout_ms
			until
				Result.count >= a_count or {MONOTONIC_CLOCK}.milliseconds > l_deadline
			loop
				if attached a_queue.poll_with_timeout (20) as e then
					Result.extend (e)
				end
			end
		end

	sleep_ms (a_ms: INTEGER)
			-- Suspend the calling thread for `a_ms` milliseconds.
		do
			(create {EXECUTION_ENVIRONMENT}).sleep (a_ms.to_integer_64 * 1_000_000)
		end

	new_scripted_app (a_input: READABLE_STRING_8): TEST_TUI_APP_IMPL
			-- Application on an ANSI backend whose driver replays `a_input` and whose output is captured.
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

	scripted_driver (a_app: TEST_TUI_APP_IMPL): FAKE_CONSOLE_DRIVER
			-- The fake driver behind `a_app`.
		do
			check attached {FAKE_CONSOLE_DRIVER} a_app.backend.driver as d then
				Result := d
			end
		end

	scripted_sink (a_app: TEST_TUI_APP_IMPL): STRING_32
			-- The output capture of `a_app`.
		do
			check attached a_app.backend.output_sink as s then
				Result := s
			end
		end

	draw_label (a_frame: FRAME; a_text: STRING)
			-- Render `a_text` at the top-left of `a_frame`.
		do
			a_frame.buffer.put_string (0, 0, a_text, create {STYLE})
		end

	draw_two_logs (a_buffer: BUFFER)
			-- Render two log lines into `a_buffer`.
		do
			a_buffer.put_string (0, 0, "log1", create {STYLE})
			a_buffer.put_string (1, 0, "log2", create {STYLE})
		end

end
