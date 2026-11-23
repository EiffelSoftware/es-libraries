note
	description: "[
		Milestone H Autotest: CUSTOM_EVENT + TUI_APPLICATION.post_event,
		FOCUS_MANAGER / HIT_MAP, and related interaction wiring.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_MILESTONE_H

inherit
	EQA_TEST_SET

feature -- Custom events

	test_custom_event_flags
			-- CUSTOM_EVENT reports is_custom and carries an optional payload.
		local
			l_empty: CUSTOM_EVENT
			l_with: CUSTOM_EVENT
			l_token: STRING_8
		do
			create l_empty.make
			assert ("empty is custom", l_empty.is_custom)
			assert ("empty not key", not l_empty.is_key)
			assert ("empty payload void", l_empty.payload = Void)

			l_token := "done"
			create l_with.make_with_payload (l_token)
			assert ("with is custom", l_with.is_custom)
			assert ("payload attached", attached {STRING_8} l_with.payload as p and then p.same_string (l_token))
		end

	test_post_event_from_worker_thread
			-- A worker thread posts CUSTOM_EVENT via post_event; the loop processes it.
		local
			l_app: TEST_TUI_APP_IMPL
			l_worker: WORKER_THREAD
			l_payload: STRING_8
		do
			l_app := new_scripted_app ("")
			l_app.set_tick_rate (20)
			l_payload := "worker_ok"
			create l_worker.make (agent (a: TEST_TUI_APP_IMPL; p: STRING_8)
				do
					(create {EXECUTION_ENVIRONMENT}).sleep (30_000_000)
					a.post_event (create {CUSTOM_EVENT}.make_with_payload (p))
					a.post_event (create {KEY_EVENT}.make_char ('q'))
				end (l_app, l_payload))
			l_worker.launch
			l_app.run
			assert ("worker finished", l_worker.join_with_timeout (3000))
			assert ("custom received", l_app.custom_count >= 1)
			assert ("payload kept", attached {STRING_8} l_app.last_custom_payload as p and then p.same_string (l_payload))
			assert ("quit processed", l_app.key_count >= 1)
		end

	test_post_event_wakes_poll
			-- post_event pushes through the synchronized queue (same path as input).
		local
			l_queue: SYNCHRONIZED_EVENT_QUEUE
			l_event: detachable EVENT
			l_token: STRING_8
		do
			l_token := "queued"
			create l_queue.make
			l_queue.push (create {CUSTOM_EVENT}.make_with_payload (l_token))
			l_event := l_queue.poll
			assert ("dequeued", attached l_event)
			assert ("is custom", attached l_event and then l_event.is_custom)
			assert ("payload", attached {CUSTOM_EVENT} l_event as c and then attached {STRING_8} c.payload as p and then p.same_string (l_token))
		end

feature -- Focus manager

	test_focus_tab_cycle
			-- Tab / Shift-Tab cycle through registered ids.
		local
			l_focus: FOCUS_MANAGER
			l_a, l_b, l_c: WIDGET_ID
		do
			create l_focus.make
			create l_a.make (1)
			create l_b.make (2)
			create l_c.make (3)
			l_focus.register (l_a)
			l_focus.register (l_b)
			l_focus.register (l_c)
			assert ("starts on first", l_focus.is_focused (l_a))
			l_focus.focus_next
			assert ("tab to second", l_focus.is_focused (l_b))
			l_focus.focus_next
			assert ("tab to third", l_focus.is_focused (l_c))
			l_focus.focus_next
			assert ("wrap to first", l_focus.is_focused (l_a))
			l_focus.focus_previous
			assert ("shift-tab to third", l_focus.is_focused (l_c))
		end

	test_hit_map_topmost
			-- Later registrations win; wipe_out clears for the next frame.
		local
			l_map: HIT_MAP
			l_under, l_over: WIDGET_ID
			l_rect: RECT
		do
			create l_map.make
			create l_under.make (1)
			create l_over.make (2)
			create l_rect.make (2, 2, 10, 5)
			l_map.register (l_under, l_rect)
			l_map.register (l_over, l_rect)
			assert ("topmost", attached l_map.hit (5, 3) as id and then id ~ l_over)
			assert ("miss", l_map.hit (0, 0) = Void)
			l_map.wipe_out
			assert ("cleared", l_map.is_empty)
			assert ("no hit after wipe", l_map.hit (5, 3) = Void)
		end

	test_modal_scope_traps_focus
			-- Modal push_scope / pop_scope isolates Tab targets.
		local
			l_focus: FOCUS_MANAGER
			l_a, l_b, l_ok, l_cancel: WIDGET_ID
			l_popup: TUI_POPUP
		do
			create l_focus.make
			create l_a.make (1)
			create l_b.make (2)
			create l_ok.make (10)
			create l_cancel.make (11)
			l_focus.register (l_a)
			l_focus.register (l_b)
			l_focus.set_focus (l_b)
			create l_popup.make
			l_popup.begin_modal_with (l_focus, <<l_ok, l_cancel>>)
			assert ("modal depth", l_focus.scope_depth = 2)
			assert ("modal focus ok", l_focus.is_focused (l_ok))
			l_focus.focus_next
			assert ("modal tab cancel", l_focus.is_focused (l_cancel))
			l_focus.focus_next
			assert ("modal wrap ok", l_focus.is_focused (l_ok))
			assert ("outer not in scope", not l_focus.contains (l_a))
			l_popup.end_modal (l_focus)
			assert ("restored depth", l_focus.scope_depth = 1)
			assert ("outer focus kept", l_focus.is_focused (l_b))
		end

	test_form_snapshot_diagram
			-- Architecture form diagram fields are focusable and hit-testable.
		local
			l_focus: FOCUS_MANAGER
			l_user, l_pass, l_submit, l_cancel: WIDGET_ID
			l_buf: BUFFER
			l_frame: FRAME
			l_user_area, l_pass_area, l_submit_area: RECT
		do
			create l_focus.make
			create l_user.make (1)
			create l_pass.make (2)
			create l_submit.make (3)
			create l_cancel.make (4)
			l_focus.register (l_user)
			l_focus.register (l_pass)
			l_focus.register (l_submit)
			l_focus.register (l_cancel)

			create l_buf.make (20, 5)
			create l_frame.make (l_buf)
			create l_user_area.make (1, 1, 18, 1)
			create l_pass_area.make (1, 2, 18, 1)
			create l_submit_area.make (1, 3, 9, 1)
			l_frame.register_hit (l_user, l_user_area)
			l_frame.register_hit (l_pass, l_pass_area)
			l_frame.register_hit (l_submit, l_submit_area)
			l_frame.buffer.put_string (1, 1, "Username: admin_", create {STYLE})
			l_frame.buffer.put_string (1, 2, "Password: *****", create {STYLE})
			l_frame.buffer.put_string (1, 3, "[ Submit ]", create {STYLE})

			assert ("hit user", attached l_frame.hit_map.hit (5, 1) as id and then id ~ l_user)
			assert ("hit pass", attached l_frame.hit_map.hit (5, 2) as id and then id ~ l_pass)
			assert ("hit submit", attached l_frame.hit_map.hit (3, 3) as id and then id ~ l_submit)
			l_focus.set_focus (l_pass)
			assert ("password focused", l_focus.is_focused (l_pass))
			l_focus.focus_next
			assert ("submit focused", l_focus.is_focused (l_submit))
		end

feature {NONE} -- Helpers

	new_scripted_app (a_input: READABLE_STRING_8): TEST_TUI_APP_IMPL
			-- Application on an ANSI backend whose driver replays `a_input`.
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

end
