note
	description: "[
		Suspend / resume of TUI_APPLICATION on a scripted FAKE_CONSOLE_DRIVER that acts as a
		POSIX platform (review p0_interaction_review.md, findings M4, M5, M9, M10, L1, L2 and
		T1): the sequence written around the stop, the input thread stopped while stopped, the
		inline viewport placed again, paste and focus reporting re-enabled, one resume per
		continue, no setup while continued or started in the background, and the Ctrl+Z
		opt-out with the `suspend` command.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_SUSPEND_RESUME

inherit
	EQA_TEST_SET

feature -- Fullscreen

	test_ctrl_z_suspend_sequence
			-- Ctrl+Z: leave the alternate screen, show the cursor and pop the keyboard flags,
			-- stop with the console cooked and nobody reading it; then raw mode, alternate
			-- screen, clear, the same modes as before (L1) and a full redraw, on a new
			-- input thread. Ctrl+Z itself is not passed to `process`.
		local
			l_app: TEST_TUI_APP_IMPL
			l_driver: FAKE_CONSOLE_DRIVER
			l_sink, l_before, l_after: STRING_32
			l_first_thread: EVENT_THREAD
		do
			l_app := new_app ("p" + Ctrl_z, create {VIEWPORT}.make_fullscreen)
			l_driver := driver_of (l_app)
			l_sink := sink_of (l_app)
			l_app.set_keyboard_enhancement (True)
			l_app.set_mouse_capture (True)
			l_app.set_key_hook (agent enable_reporting_on_p (?, l_app))
			stop_after_resume (l_app, l_driver)
			l_first_thread := l_app.event_thread
			l_app.run
			assert ("suspended once", l_driver.suspend_count = 1)
			assert ("Ctrl+Z not processed", l_app.key_count = 1)
			assert ("cooked while stopped", not l_driver.raw_at_suspend)
			assert ("nobody reads the console while stopped", not l_driver.input_claimed_at_suspend)
			check attached l_driver.output_at_suspend as l_out then
				l_before := l_out
			end
			l_after := l_sink.substring (l_before.count + 1, l_sink.count)
			assert ("left the alternate screen", l_before.has_substring (Csi + "?1049l"))
			assert ("cursor shown before the stop", l_before.has_substring (Csi + "?25h"))
			assert ("keyboard flags popped before the stop", l_before.has_substring (Csi + "<u"))
			assert ("paste off before the stop", l_before.has_substring (Csi + "?2004l"))
			assert ("alternate screen again", l_after.has_substring (Csi + "?1049h"))
			assert ("cleared", l_after.has_substring (Csi + "2J"))
			assert ("cursor hidden", l_after.has_substring (Csi + "?25l"))
			assert ("keyboard flags pushed once", occurrences (l_after, Csi + ">3u") = 1)
			assert ("mouse again", l_after.has_substring (Csi + "?1000h"))
			assert ("paste again (L1)", l_after.has_substring (Csi + "?2004h"))
			assert ("focus again (L1)", l_after.has_substring (Csi + "?1004h"))
			assert ("full redraw", l_after.has_substring ("frame"))
			assert ("raw twice", l_driver.raw_enable_count = 2)
			assert ("new input thread", l_app.event_thread /= l_first_thread)
			assert ("restored at the end", not l_app.is_terminal_set_up and not l_app.backend.is_input_in_use)
		end

	test_late_continue_resumes_once
			-- L2: the continue that ends the stop is handled after `suspend_process` returned
			-- (its handler ran on another thread): the terminal is set up once, not twice.
		local
			l_app: TEST_TUI_APP_IMPL
			l_driver: FAKE_CONSOLE_DRIVER
			l_sink: STRING_32
		do
			l_app := new_app (Ctrl_z, create {VIEWPORT}.make_fullscreen)
			l_driver := driver_of (l_app)
			l_sink := sink_of (l_app)
			l_driver.set_late_continue (True)
			l_app.set_keyboard_enhancement (True)
				-- The loop looks for a resume request before it draws: stop at that draw
			stop_after_resume (l_app, l_driver)
			l_app.run
			assert ("suspended once", l_driver.suspend_count = 1)
			assert ("raw entered twice in all", l_driver.raw_enable_count = 2)
			assert ("alternate screen entered twice in all", occurrences (l_sink, Csi + "?1049h") = 2)
			assert ("keyboard flags pushed twice in all", occurrences (l_sink, Csi + ">3u") = 2)
		end

	test_external_stop_resumes_once
			-- `kill -TSTP` then `fg`: the signal handler restored the tty, the loop sets the
			-- terminal up again once, with paste reporting (L1), and redraws everything.
		local
			l_app: TEST_TUI_APP_IMPL
			l_driver: FAKE_CONSOLE_DRIVER
			l_sink: STRING_32
		do
			l_app := new_app ("px", create {VIEWPORT}.make_fullscreen)
			l_driver := driver_of (l_app)
			l_sink := sink_of (l_app)
			l_app.set_key_hook (agent (k: KEY_EVENT; a: TEST_TUI_APP_IMPL; d: FAKE_CONSOLE_DRIVER)
				do
					enable_reporting_on_p (k, a)
					if k.code.is_char and then k.code.character = 'x' then
						d.simulate_external_stop
					end
				end (?, l_app, l_driver))
			stop_after_resume (l_app, l_driver)
			l_app.run
			assert ("one external stop", l_driver.external_stop_count = 1)
			assert ("not stopped by the application", l_driver.suspend_count = 0)
			assert ("raw entered twice in all", l_driver.raw_enable_count = 2)
			assert ("alternate screen entered twice in all", occurrences (l_sink, Csi + "?1049h") = 2)
			assert ("paste enabled twice in all", occurrences (l_sink, Csi + "?2004h") = 2)
			check attached l_driver.output_at_raw_enable as l_out then
				assert ("full redraw after the resume", l_sink.substring (l_out.count + 1, l_sink.count).has_substring ("frame"))
			end
			assert ("all keys processed", l_app.key_count = 2)
		end

	test_external_stop_sets_title_again
			-- P2 T2: `kill -TSTP` then `fg` with a title set. The signal handler pops the
			-- terminal's title with its reset (FAKE_CONSOLE_DRIVER.simulate_external_stop, as
			-- the POSIX handler does once a title is pushed), so the resume pushes it again
			-- and sets the title again; the restore at the end pops once more.
		local
			l_app: TEST_TUI_APP_IMPL
			l_driver: FAKE_CONSOLE_DRIVER
			l_sink: STRING_32
		do
			l_app := new_app ("x", create {VIEWPORT}.make_fullscreen)
			l_driver := driver_of (l_app)
			l_sink := sink_of (l_app)
			l_app.set_window_title ("T2")
			l_app.set_key_hook (agent (k: KEY_EVENT; d: FAKE_CONSOLE_DRIVER)
				do
					if k.code.is_char and then k.code.character = 'x' then
						d.simulate_external_stop
					end
				end (?, l_driver))
			stop_after_resume (l_app, l_driver)
			l_app.run
			assert ("one external stop", l_driver.external_stop_count = 1)
			assert ("the handler popped the title", l_driver.external_title_pop_count = 1)
			assert ("pushed twice in all", occurrences (l_sink, Csi + "22;0t") = 2)
			assert ("title set twice in all", occurrences (l_sink, {STRING_32} "%/27/]0;T2%/7/") = 2)
			check attached l_driver.output_at_external_stop as l_out then
				assert ("pushed and set again after the resume", l_sink.substring (l_out.count + 1, l_sink.count).has_substring (
					Csi + "22;0t" + {STRING_32} "%/27/]0;T2%/7/"))
			end
			-- The handler's pop is not in the sink (it writes to the terminal itself)
			assert ("popped once by the restore at the end", occurrences (l_sink, Csi + "23;0t") = 1)
			assert ("nothing pushed after the run", not l_driver.is_title_pushed)
		end

	test_title_set_on_terminal_survives_ctrl_z
			-- P2 T2 review #1: a title set with {TERMINAL}.set_title, not the application's
			-- `set_title`, is the application's `title` too, so the resume after a Ctrl+Z
			-- pushes and sets it again. Before the fix the application kept its own copy, and
			-- after the resume the shell's title stayed for the rest of the run.
		local
			l_app: TEST_TUI_APP_IMPL
			l_driver: FAKE_CONSOLE_DRIVER
			l_sink: STRING_32
		do
			l_app := new_app ("t" + Ctrl_z, create {VIEWPORT}.make_fullscreen)
			l_driver := driver_of (l_app)
			l_sink := sink_of (l_app)
			l_app.set_key_hook (agent (k: KEY_EVENT; a: TEST_TUI_APP_IMPL)
				do
					if k.code.is_char and then k.code.character = 't' then
						a.terminal.set_title ("Direct")
					end
				end (?, l_app))
			stop_after_resume (l_app, l_driver)
			l_app.run
			assert ("suspended once", l_driver.suspend_count = 1)
			assert ("one title for both", attached l_app.window_title as t and then t.same_string ({STRING_32} "Direct"))
			check attached l_driver.output_at_suspend as l_out then
				assert ("pushed and set after the resume", l_sink.substring (l_out.count + 1, l_sink.count).has_substring (
					Csi + "22;0t" + {STRING_32} "%/27/]0;Direct%/7/"))
			end
			assert ("pushes and pops match", occurrences (l_sink, Csi + "22;0t") = occurrences (l_sink, Csi + "23;0t"))
			assert ("nothing pushed after the run", not l_driver.is_title_pushed)
		end

	test_title_set_while_stopped_waits_for_fg
			-- P2 T2 review #2: a title set after a stop from outside, while the job waits in
			-- the background, writes nothing there and leaves the "title pushed" record
			-- alone; `fg` pushes once and sets it, and the exit pops once. Before the fix,
			-- {TERMINAL}.set_title pushed at once: into the shell's terminal (or, inside the
			-- M11 window, into output that is dropped), with the record set, so the resume
			-- did not push and the exit popped a title that was never saved.
		local
			l_app: TEST_TUI_APP_IMPL
			l_driver: FAKE_CONSOLE_DRIVER
			l_sink: STRING_32
			l_drawn_in_background: CELL [BOOLEAN]
		do
			l_app := new_app ("x", create {VIEWPORT}.make_fullscreen)
			l_driver := driver_of (l_app)
			l_sink := sink_of (l_app)
			l_app.set_key_hook (agent (k: KEY_EVENT; a: TEST_TUI_APP_IMPL; d: FAKE_CONSOLE_DRIVER)
				do
					if k.code.is_char and then k.code.character = 'x' then
						d.simulate_external_stop
						d.set_background_for (3)
						a.terminal.set_title ("Late")
						assert ("not pushed while stopped", not d.is_title_pushed)
					end
				end (?, l_app, l_driver))
			create l_drawn_in_background.put (False)
			stop_after_resume_noting_background (l_app, l_driver, l_drawn_in_background)
			l_app.run
			assert ("one external stop", l_driver.external_stop_count = 1)
			assert ("nothing for the handler to pop", l_driver.external_title_pop_count = 0)
			check attached l_driver.output_at_external_stop as l_stop and attached l_driver.output_at_foreground as l_fg then
				assert ("nothing written in the background", l_fg.same_string (l_stop))
				assert ("pushed and set after fg", l_sink.substring (l_fg.count + 1, l_sink.count).has_substring (
					Csi + "22;0t" + {STRING_32} "%/27/]0;Late%/7/"))
			end
			assert ("one push", occurrences (l_sink, Csi + "22;0t") = 1)
			assert ("one pop", occurrences (l_sink, Csi + "23;0t") = 1)
			assert ("nothing pushed after the run", not l_driver.is_title_pushed)
		end

	test_external_stop_background_continue_waits_for_fg
			-- M9: `kill -TSTP`, then a plain `kill -CONT`: the job goes on in the background,
			-- where the terminal is the shell's. The loop keeps the resume request, draws
			-- nothing and leaves the modes alone until `fg` gives it the terminal (without a
			-- continue, the job already runs); then it sets the terminal up once and redraws.
		local
			l_app: TEST_TUI_APP_IMPL
			l_driver: FAKE_CONSOLE_DRIVER
			l_sink: STRING_32
			l_drawn_in_background: CELL [BOOLEAN]
		do
			l_app := new_app ("px", create {VIEWPORT}.make_fullscreen)
			l_driver := driver_of (l_app)
			l_sink := sink_of (l_app)
			l_app.set_key_hook (agent (k: KEY_EVENT; a: TEST_TUI_APP_IMPL; d: FAKE_CONSOLE_DRIVER)
				do
					enable_reporting_on_p (k, a)
					if k.code.is_char and then k.code.character = 'x' then
						d.simulate_external_stop
						d.set_background_for (3)
					end
				end (?, l_app, l_driver))
			create l_drawn_in_background.put (False)
			stop_after_resume_noting_background (l_app, l_driver, l_drawn_in_background)
			l_app.run
			assert ("one external stop", l_driver.external_stop_count = 1)
			assert ("waited for the terminal", l_driver.background_query_count = 3 and not l_driver.is_in_background)
			assert ("nothing drawn in the background", not l_drawn_in_background.item)
			assert ("raw mode left alone in the background", l_driver.raw_enable_count_at_foreground = 1)
			check attached l_driver.output_at_external_stop as l_stop and attached l_driver.output_at_foreground as l_fg then
				assert ("nothing written in the background", l_fg.same_string (l_stop))
				assert ("full redraw after fg", l_sink.substring (l_fg.count + 1, l_sink.count).has_substring ("frame"))
			end
			assert ("raw entered twice in all", l_driver.raw_enable_count = 2)
			assert ("alternate screen entered twice in all", occurrences (l_sink, Csi + "?1049h") = 2)
			assert ("paste enabled twice in all", occurrences (l_sink, Csi + "?2004h") = 2)
			assert ("request handled", not l_app.is_waiting_for_terminal)
		end

	test_ctrl_z_background_continue_waits_for_fg
			-- M9: Ctrl+Z, then `bg` (or `kill -CONT`): `suspend_process` returns in the
			-- background. The terminal stays restored and nothing reads or draws until `fg`
			-- gives it back; then raw mode, the alternate screen, the keyboard flags, paste and
			-- focus (L1) again, and a full redraw on a new input thread. A Ctrl+Z queued
			-- meanwhile does not stop the process again.
		local
			l_app: TEST_TUI_APP_IMPL
			l_driver: FAKE_CONSOLE_DRIVER
			l_sink, l_after: STRING_32
			l_drawn_in_background: CELL [BOOLEAN]
			l_first_thread: EVENT_THREAD
		do
			l_app := new_app ("p" + Ctrl_z, create {VIEWPORT}.make_fullscreen)
			l_driver := driver_of (l_app)
			l_sink := sink_of (l_app)
			l_app.set_keyboard_enhancement (True)
			l_app.set_key_hook (agent enable_reporting_on_p (?, l_app))
			l_driver.set_suspend_hook (agent (a: TEST_TUI_APP_IMPL; d: FAKE_CONSOLE_DRIVER)
				do
					d.set_background_for (3)
						-- Taken from the queue while the resume waits
					a.post_event (ctrl_z_event)
				end (l_app, l_driver))
			create l_drawn_in_background.put (False)
			stop_after_resume_noting_background (l_app, l_driver, l_drawn_in_background)
			l_first_thread := l_app.event_thread
			l_app.run
			assert ("suspended once", l_driver.suspend_count = 1)
			assert ("queued Ctrl+Z neither processed nor a second stop", l_app.key_count = 1)
			assert ("waited for the terminal", l_driver.background_query_count = 3 and not l_driver.is_in_background)
			assert ("nothing drawn in the background", not l_drawn_in_background.item)
			assert ("raw mode left alone in the background", l_driver.raw_enable_count_at_foreground = 1)
			check attached l_driver.output_at_suspend as l_stop and attached l_driver.output_at_foreground as l_fg then
				assert ("nothing written in the background", l_fg.same_string (l_stop))
				l_after := l_sink.substring (l_fg.count + 1, l_sink.count)
			end
			assert ("alternate screen again", l_after.has_substring (Csi + "?1049h"))
			assert ("keyboard flags pushed once", occurrences (l_after, Csi + ">3u") = 1)
			assert ("paste again (L1)", l_after.has_substring (Csi + "?2004h"))
			assert ("focus again (L1)", l_after.has_substring (Csi + "?1004h"))
			assert ("full redraw", l_after.has_substring ("frame"))
			assert ("raw twice", l_driver.raw_enable_count = 2)
			assert ("new input thread", l_app.event_thread /= l_first_thread)
			assert ("no resume left pending", not l_app.is_resume_pending)
			assert ("restored at the end", not l_app.is_terminal_set_up and not l_app.backend.is_input_in_use)
		end

	test_external_stop_quit_before_noticed_writes_nothing
			-- M9: `kill -TSTP`, a plain `kill -CONT`, and the application calls `suspend` and
			-- quits before the loop has looked at the continue. The handler restored the
			-- terminal, which is the shell's now: neither `suspend` nor the clean-up writes to
			-- it or changes its modes.
		local
			l_app: TEST_TUI_APP_IMPL
			l_driver: FAKE_CONSOLE_DRIVER
			l_sink: STRING_32
		do
			l_app := new_app ("px", create {VIEWPORT}.make_fullscreen)
			l_driver := driver_of (l_app)
			l_sink := sink_of (l_app)
			l_app.set_key_hook (agent (k: KEY_EVENT; a: TEST_TUI_APP_IMPL; d: FAKE_CONSOLE_DRIVER)
				do
					enable_reporting_on_p (k, a)
					if k.code.is_char and then k.code.character = 'x' then
						d.simulate_external_stop
						d.set_background_for (1000)
						a.suspend
						a.stop
					end
				end (?, l_app, l_driver))
			l_app.run
			assert ("one external stop", l_driver.external_stop_count = 1)
			assert ("suspend did nothing", l_driver.suspend_count = 0)
			check attached l_driver.output_at_external_stop as l_stop then
				assert ("nothing written after the stop", l_sink.same_string (l_stop))
			end
			assert ("modes left alone", l_driver.raw_disable_count = 0 and l_driver.restore_count = 0)
			assert ("raw entered once", l_driver.raw_enable_count = 1)
			assert ("recorded as restored", not l_app.is_terminal_set_up and not l_app.is_resume_pending)
		end

	test_external_stop_waiting_in_background_writes_nothing
			-- M9: `kill -TSTP` and a plain `kill -CONT`; the loop sees the continue in the
			-- background and waits for `fg` as after Ctrl+Z (`is_resume_pending`), with no input
			-- thread. While it waits, `suspend` and quitting (here from a worker's event) leave
			-- the shell's terminal alone.
		local
			l_app: TEST_TUI_APP_IMPL
			l_driver: FAKE_CONSOLE_DRIVER
			l_sink: STRING_32
			l_waited: CELL [BOOLEAN]
		do
			l_app := new_app ("px", create {VIEWPORT}.make_fullscreen)
			l_driver := driver_of (l_app)
			l_sink := sink_of (l_app)
			l_app.set_key_hook (agent (k: KEY_EVENT; a: TEST_TUI_APP_IMPL; d: FAKE_CONSOLE_DRIVER)
				do
					enable_reporting_on_p (k, a)
					if k.code.is_char and then k.code.character = 'x' then
						d.simulate_external_stop
						d.set_background_for (1000)
						a.post_event (create {CUSTOM_EVENT}.make)
					end
				end (?, l_app, l_driver))
			create l_waited.put (False)
			l_app.set_custom_hook (agent (e: CUSTOM_EVENT; a: TEST_TUI_APP_IMPL; c: CELL [BOOLEAN])
				do
					if a.is_resume_pending then
						c.put (not a.is_terminal_set_up and not a.backend.is_input_in_use)
						a.suspend
						a.stop
					else
							-- Until the loop has looked at the continue
						a.post_event (create {CUSTOM_EVENT}.make)
					end
				end (?, l_app, l_waited))
			l_app.run
			assert ("waited as after Ctrl+Z, input stopped", l_waited.item)
			assert ("suspend did nothing", l_driver.suspend_count = 0)
			check attached l_driver.output_at_external_stop as l_stop then
				assert ("nothing written after the stop", l_sink.same_string (l_stop))
			end
			assert ("modes left alone", l_driver.raw_disable_count = 0 and l_driver.restore_count = 0)
			assert ("raw entered once", l_driver.raw_enable_count = 1)
			assert ("restored at the end", not l_app.is_terminal_set_up and not l_app.is_resume_pending)
		end

feature -- Background start

	test_background_start_waits_for_fg
			-- M10: started in the background (`hello_tui &`), where the terminal is the shell's.
			-- `run` neither enters raw mode, writes, nor reads input until `fg` gives it the
			-- terminal (without a continue: the job already runs). Then it sets the terminal up
			-- once, draws a full frame, and reads the keys typed after `fg`.
		local
			l_app: TEST_TUI_APP_IMPL
			l_driver: FAKE_CONSOLE_DRIVER
			l_sink, l_after: STRING_32
			l_drawn_in_background: CELL [BOOLEAN]
		do
			l_app := new_app ("kq", create {VIEWPORT}.make_fullscreen)
			l_driver := driver_of (l_app)
			l_sink := sink_of (l_app)
			l_app.set_keyboard_enhancement (True)
			l_driver.set_background_for (3)
			create l_drawn_in_background.put (False)
			l_app.set_draw_hook (agent (f: FRAME; d: FAKE_CONSOLE_DRIVER; c: CELL [BOOLEAN])
				do
					if d.is_in_background then
						c.put (True)
					end
				end (?, l_driver, l_drawn_in_background))
			l_app.run
			assert ("waited for the terminal", l_driver.background_query_count = 3 and not l_driver.is_in_background)
			assert ("nothing drawn in the background", not l_drawn_in_background.item)
			assert ("raw mode not entered in the background", l_driver.raw_enable_count_at_foreground = 0)
			assert ("input not read in the background", l_driver.read_count_at_foreground = 0)
			check attached l_driver.output_at_foreground as l_fg then
				assert ("nothing written in the background", l_fg.is_empty)
				l_after := l_sink.substring (l_fg.count + 1, l_sink.count)
			end
			assert ("raw once", l_driver.raw_enable_count = 1)
			assert ("alternate screen once", occurrences (l_sink, Csi + "?1049h") = 1)
			assert ("cleared", l_after.has_substring (Csi + "2J"))
			assert ("keyboard flags pushed once", occurrences (l_sink, Csi + ">3u") = 1)
			assert ("full frame after fg", l_after.has_substring ("frame") and l_app.draw_pass_count >= 1)
			assert ("keys read after fg", l_app.key_count = 2)
			assert ("restored at the end", not l_app.is_terminal_set_up and not l_app.backend.is_input_in_use
				and l_driver.restore_count = 1)
			assert ("no start left pending", not l_app.is_start_pending)
		end

	test_quit_while_waiting_to_start_writes_nothing
			-- M10: started in the background, the application quits (here from a worker's
			-- event) before `fg`. Ticks are processed meanwhile; a Ctrl+Z posted and `suspend`
			-- do nothing, since nothing is set up. Nothing is read or written, and the shell's
			-- modes are left alone, also by the clean-up.
		local
			l_app: TEST_TUI_APP_IMPL
			l_driver: FAKE_CONSOLE_DRIVER
			l_waiting: CELL [BOOLEAN]
		do
			l_app := new_app ("q", create {VIEWPORT}.make_fullscreen)
			l_driver := driver_of (l_app)
			l_driver.set_background_for (1000)
			create l_waiting.put (False)
			l_app.set_custom_hook (agent (e: CUSTOM_EVENT; a: TEST_TUI_APP_IMPL; c: CELL [BOOLEAN])
				do
					if a.tick_count > 0 then
						c.put (a.is_start_pending and a.is_waiting_for_terminal and not a.is_terminal_set_up
							and not a.backend.is_input_in_use)
						a.suspend
						a.stop
					else
							-- Until a tick has come
						a.post_event (create {CUSTOM_EVENT}.make)
					end
				end (?, l_app, l_waiting))
			l_app.post_event (ctrl_z_event)
			l_app.post_event (create {CUSTOM_EVENT}.make)
			l_app.run
			assert ("waited to start, ticks processed", l_waiting.item)
			assert ("still in the background", l_driver.is_in_background)
			assert ("Ctrl+Z neither processed nor a stop", l_app.key_count = 0 and l_driver.suspend_count = 0)
			assert ("nothing written", sink_of (l_app).is_empty and l_app.draw_pass_count = 0)
			assert ("modes left alone", l_driver.raw_enable_count = 0 and l_driver.raw_disable_count = 0
				and l_driver.restore_count = 0)
			assert ("nothing read", l_driver.read_count = 0)
			assert ("no start left pending", not l_app.is_start_pending and not l_app.is_terminal_set_up)
		end

	test_termination_while_waiting_to_start_writes_nothing
			-- M10: started in the background, a termination request (`kill -INT`) comes
			-- before `fg`. The loop records it, ends, and lets it take its course without
			-- writing to the shell's terminal or changing its modes.
		local
			l_app: TEST_TUI_APP_IMPL
			l_driver: FAKE_CONSOLE_DRIVER
		do
			l_app := new_app ("q", create {VIEWPORT}.make_fullscreen)
			l_driver := driver_of (l_app)
			l_driver.set_background_for (1000)
			l_app.set_custom_hook (agent (e: CUSTOM_EVENT; d: FAKE_CONSOLE_DRIVER)
				do
					d.simulate_termination_request (2)
				end (?, l_driver))
			l_app.post_event (create {CUSTOM_EVENT}.make)
			l_app.run
			assert ("recorded for the loop", l_driver.immediate_request_count = 0)
			assert ("finished once", l_driver.finish_count = 1)
			assert ("nothing written", sink_of (l_app).is_empty and l_driver.sink_count_at_finish = 0)
			assert ("modes left alone", l_driver.raw_enable_count = 0 and l_driver.restore_count = 0
				and l_driver.restore_count_at_finish = 0)
			assert ("not deferring after the run", not l_driver.is_deferring_termination)
			assert ("no start left pending", not l_app.is_start_pending and not l_app.is_terminal_set_up)
		end

	test_inline_background_start_queries_cursor_after_fg
			-- M10: an inline viewport started in the background asks the terminal for the
			-- cursor only once `fg` gave the process the terminal, and is placed there.
		local
			l_app: TEST_TUI_APP_IMPL
			l_driver: FAKE_CONSOLE_DRIVER
			l_sink: STRING_32
		do
			l_app := new_app (Esc_8 + "[5;1R", create {VIEWPORT}.make_inline (3))
			l_driver := driver_of (l_app)
			l_sink := sink_of (l_app)
			l_driver.set_background_for (3)
			l_app.set_draw_hook (agent (f: FRAME; a: TEST_TUI_APP_IMPL) do a.stop end (?, l_app))
			l_app.run
			assert ("waited for the terminal", l_driver.background_query_count = 3 and not l_driver.is_in_background)
			assert ("nothing read in the background", l_driver.read_count_at_foreground = 0)
			check attached l_driver.output_at_foreground as l_fg then
				assert ("no cursor query in the background", l_fg.is_empty)
			end
			assert ("cursor queried once after fg", occurrences (l_sink, Csi + "6n") = 1)
			assert ("placed on row 4", l_app.terminal.viewport_origin_row = 4)
			assert ("frame drawn", l_sink.has_substring ("frame"))
		end

feature -- Output

	test_output_handed_to_driver_at_flush
			-- M11: where the driver writes the output (POSIX), the backend keeps it until
			-- `flush` and hands it over in one piece, UTF-8 encoded as `print` would, so the
			-- driver can drop what a stop from outside interrupted.
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_backend: ANSI_TERMINAL_BACKEND
		do
			create l_driver
			l_driver.set_writes_output (True)
			create l_backend.make_with_driver (l_driver)
			l_backend.put_string ({STRING_32} "x%/233/")
			l_backend.put_frame ("ab", Void)
			assert ("nothing written before the flush", l_driver.write_output_count = 0)
			l_backend.flush
			assert ("written once", l_driver.write_output_count = 1)
			assert ("UTF-8, in order", l_driver.written_output.same_string ("x%/195/%/169/ab"))
			l_backend.flush
			assert ("nothing left to write", l_driver.write_output_count = 1)
		end

feature -- Inline

	test_inline_viewport_resume
			-- M4: resuming an inline viewport asks the terminal for the cursor again. This
			-- works because the input thread is stopped around the suspend (the query used
			-- to fail its `input_not_in_use` precondition), and the viewport is placed where
			-- the shell left the cursor.
		local
			l_app: TEST_TUI_APP_IMPL
			l_driver: FAKE_CONSOLE_DRIVER
			l_sink: STRING_32
			l_origin_before: CELL [INTEGER]
		do
			l_app := new_app (Esc_8 + "[5;1R" + Ctrl_z, create {VIEWPORT}.make_inline (3))
			l_driver := driver_of (l_app)
			l_sink := sink_of (l_app)
			create l_origin_before.put (-1)
			l_driver.set_suspend_hook (agent (a: TEST_TUI_APP_IMPL; d: FAKE_CONSOLE_DRIVER; c: CELL [INTEGER])
				do
					c.put (a.terminal.viewport_origin_row)
						-- The shell printed a few lines: the cursor is now on row 10 (1-based)
					d.script (Esc_8 + "[10;1R")
				end (l_app, l_driver, l_origin_before))
			stop_after_resume (l_app, l_driver)
			l_app.run
			assert ("suspended once", l_driver.suspend_count = 1)
			assert ("nobody reads the console while stopped", not l_driver.input_claimed_at_suspend)
			assert ("first placed on row 4", l_origin_before.item = 4)
			assert ("placed again on row 9", l_app.terminal.viewport_origin_row = 9)
			assert ("no alternate screen", not l_sink.has_substring (Csi + "?1049h"))
			check attached l_driver.output_at_suspend as l_out then
				assert ("frame drawn again after the resume", l_sink.substring (l_out.count + 1, l_sink.count).has_substring ("frame"))
			end
			assert ("input read again by a new thread", l_app.event_thread.is_launchable or l_app.event_thread.terminated)
		end

feature -- Exact sequence

	test_suspend_sequence_order_fullscreen
			-- T1: the exact order of the terminal operations around a Ctrl+Z, from the last
			-- frame before the stop to the first one after it. Restore: pop the keyboard
			-- flags on the alternate screen, mouse off, the default cursor shape, cursor
			-- shown, leave the alternate screen, paste and focus off, then cooked mode, then
			-- the stop. Resume: raw mode first, the alternate screen, clear, the keyboard
			-- flags pushed on that screen, mouse, cursor hidden, paste and focus again, then a
			-- full redraw, which writes the frames' bar shape again.
			-- P2 T1: every frame asks for a steady bar. DECSCUSR `CSI n SP q` (here "0 q" and
			-- "6 q") as crossterm's `SetCursorStyle` documentation gives it (n = 0 .. 6);
			-- not checked against the crossterm source, which is not in this repository.
			-- P2 T2: the application has a title. The terminal's own title is popped
			-- ("23;0t", XTWINOPS) after leaving the alternate screen, so the shell's title
			-- shows while stopped; the resume pushes it again ("22;0t") and sets the title
			-- ("]0;T2", crossterm `SetTitle`, OSC 0 with BEL, from its documentation).
			-- P2 W6: motion reporting is on. Mode 1003 is turned off with the other mouse
			-- modes, in crossterm's `DisableMouseCapture` order ("?1006l ?1003l ?1002l
			-- ?1000l"), and on again after them on resume ("?1003h"). From crossterm's
			-- documentation and the xterm control sequences, not the crossterm source.
		local
			l_app: TEST_TUI_APP_IMPL
			l_driver: FAKE_CONSOLE_DRIVER
			l_window: STRING_8
		do
			l_app := new_app ("p", create {VIEWPORT}.make_fullscreen)
			l_driver := driver_of (l_app)
			l_app.set_keyboard_enhancement (True)
			l_app.set_mouse_capture (True)
			l_app.set_mouse_motion (True)
			l_app.set_window_title ("T2")
			suspend_after_p (l_app, l_driver, {CURSOR_SHAPE}.Steady_bar)
			l_app.run
			assert ("suspended once", l_driver.suspend_count = 1)
			l_window := suspend_window (mode_trace (sink_of (l_app), l_driver))
			assert ("sequence is [" + l_window + "]", l_window.same_string (
				"draw ?25l"
				+ " <u ?1006l ?1003l ?1002l ?1000l 0 q ?25h ?1049l 23;0t ?2004l ?1004l raw-off restore stop"
				+ " raw-on ?1049h 2J H >3u ?1000h ?1002h ?1006h ?1003h ?25l 22;0t ]0;T2 ?2004h ?1004h"
				+ " draw ?2026h 1;1H frame ?2026l 6 q ?25l"))
		end

	test_suspend_sequence_order_inline
			-- T1 / M4: the same for an inline viewport on screen row 4. Restore: the cursor
			-- goes below the viewport (row 7) instead of leaving an alternate screen. Resume:
			-- raw mode, a cursor query answered with row 10, the three viewport rows blanked
			-- there, the modes again, and the frame redrawn on its new first row. The bar
			-- shape is reset after the cursor moved below the viewport, and written again
			-- with the first frame (P2 T1), and the title popped after showing the cursor and
			-- pushed and set again after hiding it (P2 T2; sequences as in the fullscreen test).
		local
			l_app: TEST_TUI_APP_IMPL
			l_driver: FAKE_CONSOLE_DRIVER
			l_window: STRING_8
		do
			l_app := new_app (Esc_8 + "[5;1Rp", create {VIEWPORT}.make_inline (3))
			l_driver := driver_of (l_app)
			l_app.set_keyboard_enhancement (True)
			l_app.set_mouse_capture (True)
			l_driver.set_suspend_hook (agent (d: FAKE_CONSOLE_DRIVER) do d.script (Esc_8 + "[10;1R") end (l_driver))
			l_app.set_window_title ("T2")
			suspend_after_p (l_app, l_driver, {CURSOR_SHAPE}.Steady_bar)
			l_app.run
			assert ("suspended once", l_driver.suspend_count = 1)
			assert ("never on the alternate screen", not sink_of (l_app).has_substring (Csi + "?1049"))
			l_window := suspend_window (mode_trace (sink_of (l_app), l_driver))
			assert ("sequence is [" + l_window + "]", l_window.same_string (
				"draw ?25l"
				+ " <u ?1006l ?1002l ?1000l 8;1H 0 q ?25h 23;0t ?2004l ?1004l raw-off restore stop"
				+ " raw-on 6n 10;1H 2K 11;1H 2K 12;1H 2K >3u ?1000h ?1002h ?1006h ?25l 22;0t ]0;T2 ?2004h ?1004h"
				+ " draw ?2026h 10;1H frame ?2026l 6 q ?25l"))
		end

feature -- Policy

	test_ctrl_z_passed_through_when_disabled
			-- M5: with `set_suspend_on_ctrl_z (False)` Ctrl+Z reaches `process` (e.g. for
			-- undo), and the application can still suspend with the `suspend` command.
		local
			l_app: TEST_TUI_APP_IMPL
			l_driver: FAKE_CONSOLE_DRIVER
			l_seen: CELL [BOOLEAN]
		do
			l_app := new_app (Ctrl_z + "sq", create {VIEWPORT}.make_fullscreen)
			l_driver := driver_of (l_app)
			assert ("suspends on Ctrl+Z by default", l_app.is_suspend_on_ctrl_z)
			l_app.set_suspend_on_ctrl_z (False)
			create l_seen.put (False)
			l_app.set_key_hook (agent (k: KEY_EVENT; a: TEST_TUI_APP_IMPL; c: CELL [BOOLEAN])
				do
					if k.modifiers.is_control and k.code.is_char and then k.code.character = 'z' then
						c.put (True)
					elseif k.code.is_char and then k.code.character = 's' then
						a.suspend
					end
				end (?, l_app, l_seen))
			l_app.run
			assert ("Ctrl+Z processed", l_seen.item and l_app.key_count = 3)
			assert ("suspended by the command only", l_driver.suspend_count = 1)
			assert ("set up again after the command", l_driver.raw_enable_count = 2)
		end

	test_no_suspend_without_platform_support
			-- Where the platform cannot suspend (Windows), Ctrl+Z is an ordinary key and
			-- `suspend` does nothing.
		local
			l_app: TEST_TUI_APP_IMPL
			l_driver: FAKE_CONSOLE_DRIVER
		do
			l_app := new_app (Ctrl_z + "q", create {VIEWPORT}.make_fullscreen)
			l_driver := driver_of (l_app)
			l_driver.set_supports_suspend_resume (False)
			l_app.set_key_hook (agent (k: KEY_EVENT; a: TEST_TUI_APP_IMPL) do a.suspend end (?, l_app))
			l_app.run
			assert ("both keys processed", l_app.key_count = 2)
			assert ("never suspended", l_driver.suspend_count = 0 and l_driver.raw_enable_count = 1)
		end

feature {NONE} -- Helpers

	stop_after_resume (a_app: TEST_TUI_APP_IMPL; a_driver: FAKE_CONSOLE_DRIVER)
			-- Stop `a_app` right after the first frame drawn once the terminal was set up a
			-- second time, so that the tests see the redraw after a resume (a key queued
			-- behind the suspend could end the run before any draw).
		local
			l_resumed: CELL [BOOLEAN]
		do
			create l_resumed.put (False)
			a_driver.set_raw_enable_hook (agent (d: FAKE_CONSOLE_DRIVER; c: CELL [BOOLEAN])
				do
					if d.raw_enable_count = 2 then
						c.put (True)
					end
				end (a_driver, l_resumed))
			a_app.set_draw_hook (agent (f: FRAME; a: TEST_TUI_APP_IMPL; c: CELL [BOOLEAN])
				do
					if c.item then
						a.stop
					end
				end (?, a_app, l_resumed))
		end

	stop_after_resume_noting_background (a_app: TEST_TUI_APP_IMPL; a_driver: FAKE_CONSOLE_DRIVER; a_drawn: CELL [BOOLEAN])
			-- Put True in `a_drawn` if `a_app` draws while `a_driver` leaves the terminal to "the
			-- shell"; stop `a_app` at the first draw once the terminal was set up a second time.
		do
			a_app.set_draw_hook (agent (f: FRAME; a: TEST_TUI_APP_IMPL; d: FAKE_CONSOLE_DRIVER; c: CELL [BOOLEAN])
				do
					if d.is_in_background then
						c.put (True)
					end
					if d.raw_enable_count >= 2 then
						a.stop
					end
				end (?, a_app, a_driver, a_drawn))
		end

	ctrl_z_event: KEY_EVENT
			-- A Ctrl+Z press, as the parser makes it from `Ctrl_z`
		local
			l_modifiers: MODIFIERS
		do
			create l_modifiers
			l_modifiers.set_control (True)
			create Result.make (create {KEY_CODE}.make_char ('z'), l_modifiers)
		end

	suspend_after_p (a_app: TEST_TUI_APP_IMPL; a_driver: FAKE_CONSOLE_DRIVER; a_shape: CURSOR_SHAPE)
			-- Log every draw of `a_app` in `a_driver`'s `mode_log`, each frame asking for
			-- cursor shape `a_shape`. On 'p', turn paste and focus reporting on; at the next
			-- draw, script Ctrl+Z (so the last frame before the stop comes after 'p'); stop at
			-- the first draw after the resume.
		local
			l_phase: CELL [INTEGER]
		do
			create l_phase.put (0)
			a_app.set_key_hook (agent (k: KEY_EVENT; a: TEST_TUI_APP_IMPL; c: CELL [INTEGER])
				do
					enable_reporting_on_p (k, a)
					if k.code.is_char and then k.code.character = 'p' then
						c.put (1)
					end
				end (?, a_app, l_phase))
			a_app.set_draw_hook (agent (f: FRAME; a: TEST_TUI_APP_IMPL; d: FAKE_CONSOLE_DRIVER; c: CELL [INTEGER]; s: CURSOR_SHAPE)
				do
					f.set_cursor_shape (s)
					d.log_mark ("draw")
					if d.raw_enable_count >= 2 then
						a.stop
					elseif c.item = 1 then
						c.put (2)
						d.script (Ctrl_z)
					end
				end (?, a_app, a_driver, l_phase, a_shape))
		end

	mode_trace (a_sink: READABLE_STRING_32; a_driver: FAKE_CONSOLE_DRIVER): ARRAYED_LIST [STRING_8]
			-- The control sequences written to `a_sink` without their ESC [ (SGR colour
			-- changes left out), OSC sequences without ESC and BEL (such as "]0;title"), the
			-- text "frame", and the entries of `a_driver.mode_log` at
			-- the places they happened, in order.
		local
			i, j, k: INTEGER
			l_log: ARRAYED_LIST [TUPLE [name: STRING_8; position: INTEGER]]
		do
			create Result.make (64)
			l_log := a_driver.mode_log
			from
				i := 1
				k := 1
			until
				i > a_sink.count + 1
			loop
				from
				until
					k > l_log.count or else l_log.i_th (k).position > i - 1
				loop
					Result.extend (l_log.i_th (k).name)
					k := k + 1
				end
				if i > a_sink.count then
					i := i + 1
				elseif a_sink.code (i) = 27 and then i < a_sink.count and then a_sink.code (i + 1) = 91 then
					from
						j := i + 2
					until
						j > a_sink.count or else not (a_sink.code (j) >= 0x20 and a_sink.code (j) <= 0x3F)
					loop
						j := j + 1
					end
					if j <= a_sink.count and then a_sink.code (j) /= ('m').natural_32_code then
						Result.extend (a_sink.substring (i + 2, j).to_string_8)
					end
					i := j + 1
				elseif a_sink.code (i) = 27 and then i < a_sink.count and then a_sink.code (i + 1) = 93 then
					-- OSC (a window title): up to its BEL, kept without ESC and BEL
					from
						j := i + 2
					until
						j > a_sink.count or else a_sink.code (j) = 7
					loop
						j := j + 1
					end
					Result.extend (a_sink.substring (i + 1, j - 1).to_string_8)
					i := j + 1
				elseif a_sink.substring (i, (i + 4).min (a_sink.count)).same_string ({STRING_32} "frame") then
					Result.extend ("frame")
					i := i + 5
				else
					i := i + 1
				end
			end
		end

	suspend_window (a_trace: ARRAYED_LIST [STRING_8]): STRING_8
			-- The entries of `a_trace` from the last "draw" before the first "stop" to the
			-- first "?25l" after the next "draw", separated by spaces; or the whole trace,
			-- prefixed with "incomplete:", if one of them is missing.
		local
			l_stop, l_from, l_to, i: INTEGER
		do
			from i := 1 until i > a_trace.count or l_stop > 0 loop
				if a_trace.i_th (i).same_string ("stop") then
					l_stop := i
				end
				i := i + 1
			end
			from i := l_stop - 1 until i < 1 or l_from > 0 loop
				if a_trace.i_th (i).same_string ("draw") then
					l_from := i
				end
				i := i - 1
			end
			if l_stop > 0 then
				from i := l_stop until i > a_trace.count or else a_trace.i_th (i).same_string ("draw") loop
					i := i + 1
				end
				from until i > a_trace.count or l_to > 0 loop
					if a_trace.i_th (i).same_string ("?25l") then
						l_to := i
					end
					i := i + 1
				end
			end
			create Result.make (200)
			if l_from = 0 or l_to = 0 then
				Result.append ("incomplete:")
				l_from := 1
				l_to := a_trace.count
			end
			from i := l_from until i > l_to loop
				if not Result.is_empty then
					Result.append_character (' ')
				end
				Result.append (a_trace.i_th (i))
				i := i + 1
			end
		end

	new_app (a_input: READABLE_STRING_8; a_viewport: VIEWPORT): TEST_TUI_APP_IMPL
			-- Application on a fake POSIX-like console replaying `a_input`, output captured.
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_sink: STRING_32
			l_backend: ANSI_TERMINAL_BACKEND
		do
			create l_driver
			l_driver.set_supports_suspend_resume (True)
			create l_sink.make_empty
			l_driver.watch_sink (l_sink)
			l_driver.script (a_input)
			create l_backend.make_with_driver_and_sink (l_driver, l_sink)
			create Result.make_with_terminal (create {TERMINAL [ANSI_TERMINAL_BACKEND]}.make_with_viewport (l_backend, a_viewport))
			Result.event_thread.set_poll_interval (5)
		end

	enable_reporting_on_p (k: KEY_EVENT; a: TEST_TUI_APP_IMPL)
			-- On 'p', turn bracketed paste and focus reporting on, as an application would.
		do
			if k.code.is_char and then k.code.character = 'p' then
				a.terminal.enable_bracketed_paste
				a.terminal.enable_focus_change
			end
		end

	driver_of (a_app: TEST_TUI_APP_IMPL): FAKE_CONSOLE_DRIVER
			-- The fake driver behind `a_app`.
		do
			check attached {FAKE_CONSOLE_DRIVER} a_app.backend.driver as d then
				Result := d
			end
		end

	sink_of (a_app: TEST_TUI_APP_IMPL): STRING_32
			-- The output capture of `a_app`.
		do
			check attached a_app.backend.output_sink as s then
				Result := s
			end
		end

	occurrences (a_text, a_part: READABLE_STRING_32): INTEGER
			-- Number of non-overlapping occurrences of `a_part` in `a_text`.
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

	Ctrl_z: STRING_8 = "%/26/"
			-- The byte a raw console delivers for Ctrl+Z

	Esc_8: STRING_8 = "%/27/"
			-- ESC, for scripted input

	Csi: STRING_32
			-- Control Sequence Introducer, as written by the backend
		once
			Result := {STRING_32} "%/27/["
		end

end
