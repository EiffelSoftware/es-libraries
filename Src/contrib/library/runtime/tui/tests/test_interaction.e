note
	description: "[
		Hit testing and focus for mouse interaction (review p0_interaction_review.md,
		findings M6, M7, L5 and T1): blocker regions, `focus_at`, TUI_POPUP blocking clicks
		on the background, widgets registering their own hit regions, `hit_test` in screen coordinates on an inline viewport, and a
		VIRTUAL_TERMINAL snapshot of the form diagram in spec/architecture.md driven by
		clicks, Tab and a modal popup.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_INTERACTION

inherit
	EQA_TEST_SET

feature -- Hit map

	test_blocker_hides_what_is_below
			-- A blocker region hits nothing, but what is registered after it stays reachable.
		local
			l_map: HIT_MAP
			l_below, l_above: WIDGET_ID
		do
			create l_map.make
			create l_below.make (1)
			create l_above.make (2)
			l_map.register (l_below, create {RECT}.make (0, 0, 10, 5))
			l_map.register_blocker (create {RECT}.make (0, 0, 20, 10))
			l_map.register (l_above, create {RECT}.make (2, 2, 3, 1))
			assert ("below is hidden", l_map.hit (1, 1) = Void)
			assert ("above is reachable", attached l_map.hit (3, 2) as id and then id ~ l_above)
			assert ("blocker alone hits nothing", l_map.hit (15, 8) = Void)
			assert ("outside everything", l_map.hit (30, 30) = Void)
		end

	test_focus_at_stays_in_scope
			-- M7: `focus_at` focuses only ids of the active scope and reports whether it did.
		local
			l_focus: FOCUS_MANAGER
			l_a, l_b, l_ok, l_cancel: WIDGET_ID
		do
			create l_focus.make
			create l_a.make (1)
			create l_b.make (2)
			create l_ok.make (10)
			create l_cancel.make (11)
			l_focus.register (l_a)
			l_focus.register (l_b)
			assert ("click on b", l_focus.focus_at (l_b) and l_focus.is_focused (l_b))
			assert ("click on nothing", not l_focus.focus_at (Void) and l_focus.is_focused (l_b))
			l_focus.enter_modal (<<l_ok, l_cancel>>)
			assert ("click behind the modal is refused", not l_focus.focus_at (l_a))
			assert ("modal focus kept", l_focus.is_focused (l_ok))
			assert ("click in the modal", l_focus.focus_at (l_cancel) and l_focus.is_focused (l_cancel))
			l_focus.pop_scope
			assert ("outer focus back", l_focus.is_focused (l_b))
		end

	test_focus_at_nested_scopes
			-- M7: with nested modal scopes, `focus_at` reaches only the innermost scope;
			-- Void, unknown ids and ids of every outer scope are not consumed.
		local
			l_focus: FOCUS_MANAGER
			l_a, l_b, l_c, l_d, l_unknown: WIDGET_ID
		do
			create l_focus.make
			create l_a.make (1)
			create l_b.make (2)
			create l_c.make (3)
			create l_d.make (4)
			create l_unknown.make (99)
			l_focus.register (l_a)
			l_focus.enter_modal (<<l_b, l_c>>)
			l_focus.enter_modal (<<l_d>>)
			assert ("depth 3", l_focus.scope_depth = 3)
			assert ("Void not consumed", not l_focus.focus_at (Void))
			assert ("root id not consumed", not l_focus.focus_at (l_a))
			assert ("middle scope id not consumed", not l_focus.focus_at (l_b))
			assert ("unknown id not consumed", not l_focus.focus_at (l_unknown))
			assert ("innermost focus kept", l_focus.is_focused (l_d) and l_focus.scope_depth = 3)
			assert ("click on the focused control is consumed", l_focus.focus_at (l_d) and l_focus.is_focused (l_d))
			l_focus.pop_scope
			assert ("middle focus restored", l_focus.is_focused (l_b))
			assert ("middle scope now reachable", l_focus.focus_at (l_c) and l_focus.is_focused (l_c))
			assert ("root still out of reach", not l_focus.focus_at (l_a) and l_focus.is_focused (l_c))
			l_focus.pop_scope
			assert ("root reachable after the modals close", l_focus.focus_at (l_a) and l_focus.is_focused (l_a))
		end

	test_popup_blocks_background_hits
			-- M7: a modal TUI_POPUP rendered through the frame blocks, by itself, every
			-- region registered before it: outside the popup and under it. The dialog's
			-- control, registered after it, stays reachable. Once `end_modal` closes it, the
			-- background is clickable again, even with the popup still rendered.
		local
			l_frame: FRAME
			l_focus: FOCUS_MANAGER
			l_outside, l_under, l_ok: WIDGET_ID
			l_popup: TUI_POPUP
		do
			create l_focus.make
			create l_outside.make (1)
			create l_under.make (2)
			create l_ok.make (10)
			l_focus.register (l_outside)
			l_focus.register (l_under)
			l_focus.set_focus (l_under)
			create l_popup.make
			assert ("not modal before begin_modal", not l_popup.blocks_hits and not l_popup.is_modal_open)
			l_popup.begin_modal_with (l_focus, <<l_ok>>)
			assert ("modal", l_popup.blocks_hits and l_popup.is_modal_open)

			l_frame := background_frame (l_outside, l_under)
			l_frame.render_widget (l_popup, create {RECT}.make (5, 1, 10, 4))
			assert ("popup registers a blocker", l_frame.hit_map.count = 3)
			l_frame.register_hit (l_ok, create {RECT}.make (7, 3, 4, 1))
			assert ("outside the popup hits nothing", l_frame.hit_map.hit (0, 0) = Void)
			assert ("under the popup hits nothing", l_frame.hit_map.hit (7, 2) = Void)
			assert ("background left of the popup still blocked", l_frame.hit_map.hit (3, 2) = Void)
			assert ("dialog control reachable", attached l_frame.hit_map.hit (8, 3) as id and then id ~ l_ok)
			assert ("click outside not consumed", not l_focus.focus_at (l_frame.hit_map.hit (0, 0)))
			assert ("click outside keeps modal focus", l_focus.is_focused (l_ok))
			assert ("background id out of scope anyway", not l_focus.focus_at (l_outside))
			assert ("click on dialog control consumed", l_focus.focus_at (l_frame.hit_map.hit (8, 3)) and l_focus.is_focused (l_ok))

				-- Popup closed: the next frame does not render it
			l_popup.end_modal (l_focus)
			assert ("no longer blocking", not l_popup.blocks_hits)
			assert ("focus back under", l_focus.is_focused (l_under))
			l_frame := background_frame (l_outside, l_under)
			l_frame.render_widget (l_popup, create {RECT}.make (5, 1, 10, 4))
			assert ("outside reachable again", attached l_frame.hit_map.hit (0, 0) as id and then id ~ l_outside)
			assert ("click outside consumed", l_focus.focus_at (l_frame.hit_map.hit (0, 0)) and l_focus.is_focused (l_outside))
			assert ("formerly covered control reachable", l_focus.focus_at (l_frame.hit_map.hit (7, 2)) and l_focus.is_focused (l_under))
		end

	test_non_modal_popup_does_not_block
			-- Item 2 of the M6/M7 review: a popup without `begin_modal` is non-modal and
			-- registers nothing, so the background stays clickable outside it and under it.
		local
			l_frame: FRAME
			l_outside, l_under: WIDGET_ID
			l_popup: TUI_POPUP
		do
			create l_outside.make (1)
			create l_under.make (2)
			create l_popup.make
			l_frame := background_frame (l_outside, l_under)
			l_frame.render_widget (l_popup, create {RECT}.make (5, 1, 10, 4))
			assert ("not blocking", not l_popup.blocks_hits)
			assert ("nothing registered", l_frame.hit_map.count = 2)
			assert ("outside reachable", attached l_frame.hit_map.hit (0, 0) as id and then id ~ l_outside)
			assert ("under reachable", attached l_frame.hit_map.hit (7, 2) as id and then id ~ l_under)
		end

	test_popup_blocking_follows_focus_scope
			-- Item 2 of the M6/M7 review: mouse blocking and the keyboard trap follow the
			-- same focus scope. A `with_*` copy made while the popup is open blocks too;
			-- popping the scope directly on the focus manager ends the blocking of the popup
			-- and of its copies, with no `end_modal`.
		local
			l_frame: FRAME
			l_focus: FOCUS_MANAGER
			l_outside, l_under, l_ok: WIDGET_ID
			l_popup, l_copy: TUI_POPUP
		do
			create l_focus.make
			create l_outside.make (1)
			create l_under.make (2)
			create l_ok.make (10)
			l_focus.register (l_outside)
			create l_popup.make
			l_popup.begin_modal_with (l_focus, <<l_ok>>)
			l_copy := l_popup.with_clear_background (False)
			assert ("copy is modal", l_copy.is_modal_open and l_copy.blocks_hits)
			l_frame := background_frame (l_outside, l_under)
			l_frame.render_widget (l_copy, create {RECT}.make (5, 1, 10, 4))
			assert ("copy blocks", l_frame.hit_map.hit (0, 0) = Void)
			l_focus.pop_scope
			assert ("popup closed with its scope", not l_popup.is_modal_open and not l_popup.blocks_hits)
			assert ("copy closed with its scope", not l_copy.blocks_hits)
			l_frame := background_frame (l_outside, l_under)
			l_frame.render_widget (l_copy, create {RECT}.make (5, 1, 10, 4))
			assert ("background reachable", attached l_frame.hit_map.hit (0, 0) as id and then id ~ l_outside)
		end

	test_popup_registers_inner_widget_hits
			-- Item 1 of the M6/M7 review: the `inner_widget` of a popup rendered through a
			-- frame registers its `hit_id` on the inner area, above the popup's blocker, so a
			-- control drawn by the popup itself is clickable. Without a `hit_id`, nothing is
			-- registered for it.
		local
			l_frame: FRAME
			l_focus: FOCUS_MANAGER
			l_outside, l_under, l_name: WIDGET_ID
			l_popup: TUI_POPUP
			l_block: TUI_BLOCK
			l_input: TUI_TEXT_INPUT
		do
			create l_focus.make
			create l_outside.make (1)
			create l_under.make (2)
			create l_name.make (10)
			l_focus.register (l_outside)
			create l_input.make
			create l_block.make
			create l_popup.make
				-- Popup on (5, 1, 10, 4): with all borders, its inner area is (6, 2, 8, 2)
			l_popup := l_popup.with_block (l_block.with_borders ({BORDERS}.all_borders)).
				with_inner_widget (l_input.with_hit_id (l_name))

				-- Modal: the field sits above the blocker
			l_popup.begin_modal_with (l_focus, <<l_name>>)
			l_frame := background_frame (l_outside, l_under)
			l_frame.render_widget (l_popup, create {RECT}.make (5, 1, 10, 4))
			assert ("field hit", attached l_frame.hit_map.hit (6, 2) as id and then id ~ l_name)
			assert ("field hit, last cell", attached l_frame.hit_map.hit (13, 3) as id and then id ~ l_name)
			assert ("border blocked", l_frame.hit_map.hit (5, 2) = Void)
			assert ("background blocked", l_frame.hit_map.hit (0, 0) = Void)
			assert ("click on field consumed", l_focus.focus_at (l_frame.hit_map.hit (7, 2)) and l_focus.is_focused (l_name))
			l_popup.end_modal (l_focus)

				-- Non-modal: the field and the background are both reachable
			l_frame := background_frame (l_outside, l_under)
			l_frame.render_widget (l_popup, create {RECT}.make (5, 1, 10, 4))
			assert ("field hit, non-modal", attached l_frame.hit_map.hit (6, 2) as id and then id ~ l_name)
			assert ("background reachable", attached l_frame.hit_map.hit (0, 0) as id and then id ~ l_outside)
			assert ("under, beside the field", attached l_frame.hit_map.hit (3, 2) as id and then id ~ l_under)

				-- No id: only the background
			l_frame := background_frame (l_outside, l_under)
			l_frame.render_widget (l_popup.with_inner_widget (l_input), create {RECT}.make (5, 1, 10, 4))
			assert ("no id, no region", l_frame.hit_map.count = 2)
		end

	test_modal_clips_later_regions
			-- Item 3 of the M6/M7 review: after `register_modal`, every region registered later
			-- is clipped to the dialog area. A background control registered after the dialog
			-- (out of drawing order) is not reachable through it, and one crossing the dialog
			-- is reachable only inside it. A nested modal replaces the clip; `wipe_out` drops it.
		local
			l_map: HIT_MAP
			l_bg, l_late, l_ok, l_wide, l_inner_ok: WIDGET_ID
		do
			create l_map.make
			create l_bg.make (1)
			create l_late.make (2)
			create l_ok.make (10)
			create l_wide.make (11)
			create l_inner_ok.make (20)
			l_map.register (l_bg, create {RECT}.make (0, 0, 20, 1))
			l_map.register_modal (create {RECT}.make (0, 0, 20, 10), create {RECT}.make (5, 2, 10, 4))
			l_map.register (l_late, create {RECT}.make (0, 8, 20, 1))
			l_map.register (l_ok, create {RECT}.make (7, 4, 4, 1))
			l_map.register (l_wide, create {RECT}.make (0, 3, 20, 1))
			assert ("background blocked", l_map.hit (1, 0) = Void)
			assert ("late control outside the dialog blocked", l_map.hit (1, 8) = Void)
			assert ("dialog control reachable", attached l_map.hit (8, 4) as id and then id ~ l_ok)
			assert ("crossing control reachable inside", attached l_map.hit (6, 3) as id and then id ~ l_wide)
			assert ("crossing control blocked left", l_map.hit (2, 3) = Void)
			assert ("crossing control blocked right", l_map.hit (16, 3) = Void)

				-- A nested modal on (6, 3, 6, 2)
			l_map.register_modal (create {RECT}.make (0, 0, 20, 10), create {RECT}.make (6, 3, 6, 2))
			l_map.register (l_inner_ok, create {RECT}.make (0, 4, 20, 1))
			assert ("inner dialog control", attached l_map.hit (8, 4) as id and then id ~ l_inner_ok)
			assert ("outer dialog blocked", l_map.hit (6, 3) = Void and l_map.hit (13, 4) = Void)

			l_map.wipe_out
			assert ("no modal after wipe_out", l_map.modal_area = Void)
			l_map.register (l_late, create {RECT}.make (0, 8, 20, 1))
			assert ("unclipped again", attached l_map.hit (1, 8) as id and then id ~ l_late)
		end

	test_modal_popup_blocks_controls_drawn_after_it
			-- Item 3 of the M6/M7 review, on a frame: with a modal popup rendered, a background
			-- widget with a `hit_id` and a `register_hit` region, both drawn after the popup
			-- and outside it, are not reachable; the dialog control is. A non-modal popup clips
			-- nothing.
		local
			l_frame: FRAME
			l_focus: FOCUS_MANAGER
			l_outside, l_under, l_late, l_field, l_ok: WIDGET_ID
			l_popup: TUI_POPUP
			l_input: TUI_TEXT_INPUT
		do
			create l_focus.make
			create l_outside.make (1)
			create l_under.make (2)
			create l_late.make (3)
			create l_field.make (4)
			create l_ok.make (10)
			create l_input.make
			create l_popup.make
			l_popup.begin_modal_with (l_focus, <<l_ok>>)

			l_frame := background_frame (l_outside, l_under)
			l_frame.render_widget (l_popup, create {RECT}.make (5, 1, 10, 4))
			l_frame.render_stateful_widget (l_input.with_hit_id (l_field), create {RECT}.make (0, 5, 20, 1), create {TEXT_INPUT_STATE})
			l_frame.register_hit (l_late, create {RECT}.make (0, 0, 4, 1))
			l_frame.register_hit (l_ok, create {RECT}.make (7, 3, 4, 1))
			assert ("field drawn after the popup blocked", l_frame.hit_map.hit (2, 5) = Void)
			assert ("region registered after the popup blocked", l_frame.hit_map.hit (1, 0) = Void)
			assert ("dialog control reachable", attached l_frame.hit_map.hit (8, 3) as id and then id ~ l_ok)
			l_popup.end_modal (l_focus)

			l_frame := background_frame (l_outside, l_under)
			l_frame.render_widget (l_popup, create {RECT}.make (5, 1, 10, 4))
			l_frame.render_stateful_widget (l_input.with_hit_id (l_field), create {RECT}.make (0, 5, 20, 1), create {TEXT_INPUT_STATE})
			l_frame.register_hit (l_late, create {RECT}.make (0, 0, 4, 1))
			assert ("non-modal: field reachable", attached l_frame.hit_map.hit (2, 5) as id and then id ~ l_field)
			assert ("non-modal: late region reachable", attached l_frame.hit_map.hit (1, 0) as id and then id ~ l_late)
		end

	test_shown_area_follows_the_screen
			-- Item 4 of the M6/M7 review: {TERMINAL}.shown_area is Void before the first draw,
			-- the viewport's screen area after a draw, and Void again after anything that
			-- erases the viewport (`force_full_redraw`, `clear_screen`, `resize`).
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_sink: STRING_32
			l_backend: ANSI_TERMINAL_BACKEND
			l_term: TERMINAL [ANSI_TERMINAL_BACKEND]
		do
			create l_driver
			create l_sink.make_empty
			l_driver.watch_sink (l_sink)
			create l_backend.make_with_driver_and_sink (l_driver, l_sink)
			create l_term.make_with_viewport (l_backend, create {VIEWPORT}.make_fixed (create {RECT}.make (10, 3, 20, 6)))
			assert ("nothing shown before a draw", l_term.shown_area = Void)
			l_term.draw (agent (f: FRAME) do end)
			assert ("shown at the viewport", attached l_term.shown_area as s and then
				(s.x = 10 and s.y = 3 and s.width = 20 and s.height = 6))
			l_term.force_full_redraw
			assert ("forgotten by force_full_redraw", l_term.shown_area = Void)
			l_term.draw (agent (f: FRAME) do end)
			l_term.clear_screen
			assert ("forgotten by clear_screen", l_term.shown_area = Void)
			l_term.draw (agent (f: FRAME) do end)
			l_term.resize (create {RECT}.make (2, 1, 8, 4))
			assert ("forgotten by resize", l_term.shown_area = Void)
			l_term.draw (agent (f: FRAME) do end)
			assert ("shown at the new area", attached l_term.shown_area as s and then
				(s.x = 2 and s.y = 1 and s.width = 8 and s.height = 4))
		end

	test_hit_test_after_insert_before
			-- Item 4 of the M6/M7 review: an inline viewport of 3 rows on screen row 4. On the
			-- first press, `insert_before` moves the viewport down a row and blanks it: until
			-- the next frame, the press position and the moved position both hit nothing. On
			-- the next frame, a press on the moved position hits the control.
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_app: TEST_TUI_APP_IMPL
		do
			create l_driver
				-- Cursor report for the viewport, then a press at screen (3, 5): frame row 1
			l_driver.script (Esc + "[5;1R" + Esc + "[<0;4;6M")
			l_app := new_app_on (l_driver, create {VIEWPORT}.make_inline (3))
			create shift_hits.make (4)
			is_second_press_pending := False
			l_app.set_draw_hook (agent draw_shift_scene (?, l_driver, Esc + "[<0;4;7M"))
			l_app.set_mouse_hook (agent record_insert_press (?, l_app))
			l_app.run
			assert ("four hits recorded", shift_hits.count = 4)
			assert ("hit before insert_before", attached shift_hits [1] as id and then id ~ Hit_id)
			assert ("old position after insert_before", shift_hits [2] = Void)
			assert ("moved position before the next frame", shift_hits [3] = Void)
			assert ("not on screen until the next frame", not was_on_screen)
			assert ("moved position after the next frame", attached shift_hits [4] as id and then id ~ Hit_id)
			assert ("viewport moved", l_app.terminal.viewport_origin_row = 5)
		end

	test_hit_test_after_resize_event
			-- Item 4 of the M6/M7 review: after a RESIZE_EVENT is dispatched, the hit map is out
			-- of date until the next frame: the same press hits nothing, then hits again once
			-- a frame was drawn.
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_app: TEST_TUI_APP_IMPL
		do
			create l_driver
			l_driver.script (Esc + "[<0;4;2M")
			l_app := new_app_on (l_driver, create {VIEWPORT}.make_fullscreen)
			create shift_hits.make (3)
			is_second_press_pending := False
			l_app.set_draw_hook (agent draw_shift_scene (?, l_driver, Esc + "[<0;4;2M"))
			l_app.set_mouse_hook (agent record_resize_press (?, l_app))
			l_app.run
			assert ("three hits recorded", shift_hits.count = 3)
			assert ("hit before the resize", attached shift_hits [1] as id and then id ~ Hit_id)
			assert ("nothing after the resize", shift_hits [2] = Void and not was_on_screen)
			assert ("hit after the next frame", attached shift_hits [3] as id and then id ~ Hit_id)
		end

	test_modal_clicks_in_fixed_viewport
			-- M7 with M6: a fixed viewport at screen column 10, row 3. While the popup is open,
			-- presses on the background outside it, on a background control partly under it,
			-- and outside the viewport hit nothing and are not consumed; a press on the
			-- dialog control is. It closes the popup, and a press on the background then
			-- focuses the background control.
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_app: TEST_TUI_APP_IMPL
		do
			create l_driver
				-- Frame (1, 0) on the top control; frame (3, 2) on the side control left of
				-- the popup; frame (5, 2) on it under the popup; screen (7, 2) outside the
				-- viewport; frame (7, 2) on OK. SGR positions are 1-based screen positions.
			l_driver.script (Esc + "[<0;12;4M" + Esc + "[<0;14;6M" + Esc + "[<0;16;6M"
				+ Esc + "[<0;8;3M" + Esc + "[<0;18;6M")
			l_app := new_app_on (l_driver, create {VIEWPORT}.make_fixed (create {RECT}.make (10, 3, 20, 6)))
			create modal_focus.make
			modal_focus.register (id_top)
			modal_focus.register (id_side)
			modal_focus.set_focus (id_side)
			create modal_popup.make
			modal_popup.begin_modal_with (modal_focus, <<id_ok>>)
			is_after_close_press_sent := False
			create modal_presses.make (6)
			l_app.set_draw_hook (agent draw_modal_scene (?, l_driver))
			l_app.set_mouse_hook (agent record_modal_press (?, l_app))
			l_app.run
			assert ("six presses", modal_presses.count = 6)
			assert ("top control blocked", modal_presses [1].hit = Void and not modal_presses [1].consumed)
			assert ("side control blocked", modal_presses [2].hit = Void and not modal_presses [2].consumed)
			assert ("side control under popup blocked", modal_presses [3].hit = Void and not modal_presses [3].consumed)
			assert ("outside viewport", modal_presses [4].hit = Void and not modal_presses [4].consumed)
			assert ("OK hit and consumed", attached modal_presses [5].hit as id and then id ~ id_ok and modal_presses [5].consumed)
			assert ("after close: top control", attached modal_presses [6].hit as id and then id ~ id_top and modal_presses [6].consumed)
			assert ("top focused", modal_focus.is_focused (id_top) and modal_focus.scope_depth = 1)
		end

	test_widgets_register_their_hit_region
			-- L5: a TUI_TEXT_AREA (or TUI_TEXT_INPUT) with a `hit_id` registers the area it was
			-- rendered into; without one, nothing is registered.
		local
			l_frame: FRAME
			l_area_id, l_input_id: WIDGET_ID
			l_area: TUI_TEXT_AREA
			l_input: TUI_TEXT_INPUT
		do
			create l_frame.make (create {BUFFER}.make (20, 6))
			create l_area_id.make (7)
			create l_input_id.make (8)
			create l_area.make
			l_frame.render_stateful_widget (l_area, create {RECT}.make (0, 0, 20, 1), create {TEXT_AREA_STATE})
			assert ("no id, no region", l_frame.hit_map.is_empty)
			l_frame.render_stateful_widget (l_area.with_hit_id (l_area_id), create {RECT}.make (0, 1, 20, 3), create {TEXT_AREA_STATE})
			create l_input.make
			l_frame.render_stateful_widget (l_input.with_hit_id (l_input_id), create {RECT}.make (0, 4, 20, 1), create {TEXT_INPUT_STATE})
			assert ("text area hit", attached l_frame.hit_map.hit (5, 2) as id and then id ~ l_area_id)
			assert ("text input hit", attached l_frame.hit_map.hit (5, 4) as id and then id ~ l_input_id)
			assert ("outside", l_frame.hit_map.hit (5, 5) = Void)
			assert ("with_hit_id copies", l_area.hit_id = Void)
		end

	test_hit_test_uses_screen_coordinates
			-- M6: on an inline viewport placed on screen row 4, a click on screen (3, 5) is on
			-- frame row 1. `hit_test` finds the control there; the frame's own map, queried
			-- with the screen position as the example used to, does not.
		local
			l_app: TEST_TUI_APP_IMPL
			l_id: WIDGET_ID
			l_hit, l_raw: CELL [detachable WIDGET_ID]
		do
				-- Cursor report for the viewport, a press at screen column 3 row 5 (SGR is 1-based), q
			l_app := new_app (Esc + "[5;1R" + Esc + "[<0;4;6M" + "q", create {VIEWPORT}.make_inline (3))
			create l_id.make (7)
			create l_hit.put (Void)
			create l_raw.put (Void)
			l_app.set_draw_hook (agent (f: FRAME; a_id: WIDGET_ID)
				do
					f.register_hit (a_id, create {RECT}.make (2, 1, 5, 1))
				end (?, l_id))
			l_app.set_mouse_hook (agent (m: MOUSE_EVENT; a: TEST_TUI_APP_IMPL; h, r: CELL [detachable WIDGET_ID])
				do
					if m.is_down then
						h.put (a.hit_test (m))
						r.put (a.last_hit_map.hit (m.column, m.row))
					end
				end (?, l_app, l_hit, l_raw))
			l_app.run
			assert ("viewport on row 4", l_app.terminal.viewport_origin_row = 4)
			assert ("hit_test finds the control", attached l_hit.item as id and then id ~ l_id)
			assert ("screen position in frame coordinates misses", l_raw.item = Void)
			assert ("q processed", l_app.key_count = 1)
		end

	test_hit_test_fullscreen
			-- M6: in a fullscreen viewport, screen and frame coordinates are the same.
		local
			l_hits: like hits_of_presses
		do
				-- Presses at screen (3, 1) and (3, 2), then q
			l_hits := hits_of_presses (Esc + "[<0;4;2M" + Esc + "[<0;4;3M" + "q",
				create {VIEWPORT}.make_fullscreen, create {RECT}.make (2, 1, 5, 1))
			assert ("two presses", l_hits.count = 2)
			assert ("on the control", attached l_hits [1] as id and then id ~ Hit_id)
			assert ("below the control", l_hits [2] = Void)
		end

	test_hit_test_fixed_viewport
			-- M6: a fixed viewport at screen column 10, row 3. The control at frame (2, 1)
			-- is at screen (12, 4); a click at the frame position on screen misses.
		local
			l_hits: like hits_of_presses
		do
				-- Presses at screen (13, 4) and (3, 1), then q
			l_hits := hits_of_presses (Esc + "[<0;14;5M" + Esc + "[<0;4;2M" + "q",
				create {VIEWPORT}.make_fixed (create {RECT}.make (10, 3, 20, 5)), create {RECT}.make (2, 1, 5, 1))
			assert ("two presses", l_hits.count = 2)
			assert ("control found at its screen position", attached l_hits [1] as id and then id ~ Hit_id)
			assert ("frame position on screen misses", l_hits [2] = Void)
		end

	test_hit_test_outside_viewport_is_void
			-- M6: a click outside the viewport hits nothing, even when a region registered in
			-- the frame is larger than the frame and would cover that position.
		local
			l_hits: like hits_of_presses
			l_blanket: RECT
		do
			create l_blanket.make (0, 0, 200, 50)
				-- Fixed viewport covering screen columns 10..29 and rows 3..7. Presses left of
				-- it (5, 4), right of it (30, 4), above it (12, 2), below it (12, 8), inside (12, 3)
			l_hits := hits_of_presses (Esc + "[<0;6;5M" + Esc + "[<0;31;5M" + Esc + "[<0;13;3M"
				+ Esc + "[<0;13;9M" + Esc + "[<0;13;4M" + "q",
				create {VIEWPORT}.make_fixed (create {RECT}.make (10, 3, 20, 5)), l_blanket)
			assert ("five presses", l_hits.count = 5)
			assert ("left", l_hits [1] = Void)
			assert ("right", l_hits [2] = Void)
			assert ("above", l_hits [3] = Void)
			assert ("below", l_hits [4] = Void)
			assert ("inside", attached l_hits [5] as id and then id ~ Hit_id)
				-- Inline viewport of 3 rows on screen row 4: presses on rows 3, 7 and 6
			l_hits := hits_of_presses (Esc + "[5;1R" + Esc + "[<0;1;4M" + Esc + "[<0;1;8M" + Esc + "[<0;1;7M" + "q",
				create {VIEWPORT}.make_inline (3), l_blanket)
			assert ("three presses", l_hits.count = 3)
			assert ("above inline", l_hits [1] = Void)
			assert ("below inline", l_hits [2] = Void)
			assert ("last inline row", attached l_hits [3] as id and then id ~ Hit_id)
		end

	test_hit_map_replaced_after_each_frame
			-- M6: `last_hit_map` is the map of the frame now on screen. Each frame registers
			-- its own id until the first press; the frames after it register nothing, so a
			-- second press on the same cell hits nothing.
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_app: TEST_TUI_APP_IMPL
		do
			create l_driver
				-- Press at screen (3, 1); the second press is scripted by the next frame
			l_driver.script (Esc + "[<0;4;2M")
			l_app := new_app_on (l_driver, create {VIEWPORT}.make_fullscreen)
			create presses.make (2)
			is_second_press_sent := False
			l_app.set_draw_hook (agent draw_until_press (?, l_app, l_driver))
			l_app.set_mouse_hook (agent record_press (?, l_app))
			l_app.run
			assert ("two presses", presses.count = 2)
			assert ("first press hits the id of the frame on screen",
				attached presses [1].hit as id and then id.value = presses [1].frame)
			assert ("a frame was drawn between the presses", presses [2].frame > presses [1].frame)
			assert ("map replaced", presses [2].map /= presses [1].map)
			assert ("second press sees the newer, empty map", presses [2].hit = Void and presses [2].map.is_empty)
		end

feature {NONE} -- Modal support

	background_frame (a_outside, a_under: WIDGET_ID): FRAME
			-- New 20x6 frame with `a_outside` on (0, 0, 5, 1) and `a_under` on (2, 2, 6, 1).
		do
			create Result.make (create {BUFFER}.make (20, 6))
			Result.register_hit (a_outside, create {RECT}.make (0, 0, 5, 1))
			Result.register_hit (a_under, create {RECT}.make (2, 2, 6, 1))
		end

	modal_focus: FOCUS_MANAGER
			-- Focus of `test_modal_clicks_in_fixed_viewport`
		attribute
			create Result.make
		end

	id_top: WIDGET_ID
			-- Background control on frame row 0
		attribute
			create Result.make (21)
		end

	id_side: WIDGET_ID
			-- Background control on frame row 2, partly under the popup
		attribute
			create Result.make (22)
		end

	modal_popup: TUI_POPUP
			-- Popup of `test_modal_clicks_in_fixed_viewport`, rendered while it is modal
		attribute
			create Result.make
		end

	is_after_close_press_sent: BOOLEAN
			-- Has `draw_modal_scene` scripted the press after the popup closed?

	modal_presses: ARRAYED_LIST [TUPLE [hit: detachable WIDGET_ID; consumed: BOOLEAN]]
			-- Presses seen by `record_modal_press`
		attribute
			create Result.make (0)
		end

	draw_modal_scene (a_frame: FRAME; a_driver: FAKE_CONSOLE_DRIVER)
			-- Background controls, then, while `modal_popup` is modal, the popup on frame
			-- (4, 1, 12, 4) with OK on (6, 2, 6, 1). The first frame after it closes scripts a
			-- press on the top control (screen (11, 3)) and q.
		do
			a_frame.register_hit (id_top, create {RECT}.make (0, 0, 20, 1))
			a_frame.register_hit (id_side, create {RECT}.make (2, 2, 5, 1))
			if modal_popup.is_modal_open then
				a_frame.render_widget (modal_popup, create {RECT}.make (4, 1, 12, 4))
				a_frame.register_hit (id_ok, create {RECT}.make (6, 2, 6, 1))
			elseif not is_after_close_press_sent then
				is_after_close_press_sent := True
				a_driver.script (Esc + "[<0;12;4M" + "q")
			end
		end

	record_modal_press (a_mouse: MOUSE_EVENT; a_app: TEST_TUI_APP_IMPL)
			-- Record the hit of a press and whether `focus_at` consumed it; a press on OK
			-- closes the popup.
		local
			l_hit: detachable WIDGET_ID
		do
			if a_mouse.is_down then
				l_hit := a_app.hit_test (a_mouse)
				modal_presses.extend ([l_hit, modal_focus.focus_at (l_hit)])
				if attached l_hit as id and then id ~ id_ok then
					modal_popup.end_modal (modal_focus)
				end
			end
		end

feature {NONE} -- Viewport shift support

	shift_hits: ARRAYED_LIST [detachable WIDGET_ID]
			-- Hits recorded by `record_insert_press` and `record_resize_press`
		attribute
			create Result.make (0)
		end

	was_on_screen: BOOLEAN
			-- `is_hit_map_on_screen` right after the viewport was shifted or resized

	is_second_press_pending: BOOLEAN
			-- Should the next frame script the second press?

	draw_shift_scene (a_frame: FRAME; a_driver: FAKE_CONSOLE_DRIVER; a_second_press: STRING)
			-- Register `Hit_id` on frame (2, 1, 5, 1); script `a_second_press` when pending,
			-- so it is read only after this frame is on screen.
		do
			a_frame.register_hit (Hit_id, create {RECT}.make (2, 1, 5, 1))
			if is_second_press_pending then
				is_second_press_pending := False
				a_driver.script (a_second_press)
			end
		end

	record_insert_press (a_mouse: MOUSE_EVENT; a_app: TEST_TUI_APP_IMPL)
			-- First press: hit, `insert_before` one row, hits at the press and one row lower.
			-- Second press: hit, then stop.
		do
			if a_mouse.is_down then
				shift_hits.extend (a_app.hit_test (a_mouse))
				if shift_hits.count = 1 then
					a_app.terminal.insert_before (1, agent (b: BUFFER) do end)
					shift_hits.extend (a_app.hit_test (a_mouse))
					shift_hits.extend (a_app.hit_test (create {MOUSE_EVENT}.make (a_mouse.kind, a_mouse.button,
						a_mouse.column, a_mouse.row + 1, a_mouse.modifiers)))
					was_on_screen := a_app.is_hit_map_on_screen
					is_second_press_pending := True
				else
					a_app.stop
				end
			end
		end

	record_resize_press (a_mouse: MOUSE_EVENT; a_app: TEST_TUI_APP_IMPL)
			-- First press: hit, dispatch a resize, hit again. Second press: hit, then stop.
		do
			if a_mouse.is_down then
				shift_hits.extend (a_app.hit_test (a_mouse))
				if shift_hits.count = 1 then
					a_app.dispatch_now (create {RESIZE_EVENT}.make (80, 24))
					shift_hits.extend (a_app.hit_test (a_mouse))
					was_on_screen := a_app.is_hit_map_on_screen
					is_second_press_pending := True
				else
					a_app.stop
				end
			end
		end

feature {NONE} -- Hit test support

	Hit_id: WIDGET_ID
			-- Id registered by `hits_of_presses`
		once
			create Result.make (7)
		end

	hits_of_presses (a_input: READABLE_STRING_8; a_viewport: VIEWPORT; a_region: RECT): ARRAYED_LIST [detachable WIDGET_ID]
			-- `hit_test` of every mouse press in `a_input` (which must end the run with q),
			-- on an application whose frames register `Hit_id` on `a_region`.
		local
			l_app: TEST_TUI_APP_IMPL
			l_result: ARRAYED_LIST [detachable WIDGET_ID]
		do
			create l_result.make (4)
			l_app := new_app (a_input, a_viewport)
			l_app.set_draw_hook (agent (f: FRAME; r: RECT)
				do
					f.register_hit (Hit_id, r)
				end (?, a_region))
			l_app.set_mouse_hook (agent (m: MOUSE_EVENT; a: TEST_TUI_APP_IMPL; l: ARRAYED_LIST [detachable WIDGET_ID])
				do
					if m.is_down then
						l.extend (a.hit_test (m))
					end
				end (?, l_app, l_result))
			l_app.run
			Result := l_result
		end

	presses: ARRAYED_LIST [TUPLE [hit: detachable WIDGET_ID; frame: INTEGER; map: HIT_MAP]]
			-- Presses seen by `record_press`: hit, frame number on screen, and its hit map
		attribute
			create Result.make (0)
		end

	is_second_press_sent: BOOLEAN
			-- Has `draw_until_press` scripted the second press?

	draw_until_press (a_frame: FRAME; a_app: TEST_TUI_APP_IMPL; a_driver: FAKE_CONSOLE_DRIVER)
			-- Before the first press, register the frame number as id over the whole frame.
			-- On the first frame after it, script a second press on the same cell.
		do
			if presses.is_empty then
				a_frame.register_hit (create {WIDGET_ID}.make (a_app.draw_pass_count), a_frame.area)
			elseif not is_second_press_sent then
				is_second_press_sent := True
				a_driver.script (Esc + "[<0;4;2M")
			end
		end

	record_press (a_mouse: MOUSE_EVENT; a_app: TEST_TUI_APP_IMPL)
			-- Record the hit of a press in `presses`; stop after the second.
		do
			if a_mouse.is_down then
				presses.extend ([a_app.hit_test (a_mouse), a_app.draw_pass_count, a_app.last_hit_map])
				if presses.count = 2 then
					a_app.stop
				end
			end
		end

feature -- Form snapshot

	test_form_snapshot_with_clicks_and_modal
			-- T1: the form diagram of spec/architecture.md, rendered by real widgets on a
			-- VIRTUAL_TERMINAL, row-exact. Clicks focus fields through the frame's hit map,
			-- Tab moves on, and a modal popup blocks clicks on the form behind it (M7).
		local
			l_vt: VIRTUAL_TERMINAL
			l_term: TERMINAL [VIRTUAL_TERMINAL]
			l_map: CELL [detachable HIT_MAP]
			l_popup_on: CELL [detachable TUI_POPUP]
			l_popup: TUI_POPUP
			l_block: TUI_BLOCK
			l_ok: TUI_PARAGRAPH
		do
			create l_vt.make (21, 5)
			create l_term.make (l_vt)
			create form_focus.make
			create id_user.make (1)
			create id_pass.make (2)
			create id_submit.make (3)
			create id_cancel.make (4)
			create id_ok.make (10)
			form_focus.register (id_user)
			form_focus.register (id_pass)
			form_focus.register (id_submit)
			form_focus.register (id_cancel)
			create user_state.make_with_text ("admin")
			create pass_state.make_with_text ("abcde")
			create l_map.put (Void)
			create l_popup_on.put (Void)

			l_term.draw (agent draw_form (?, l_map, l_popup_on))
			assert_lines ("form", l_vt, <<
				{STRING_32} "%/0x250C/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2510/",
				{STRING_32} "%/0x2502/Username: admin    %/0x2502/",
				{STRING_32} "%/0x2502/Password: *****    %/0x2502/",
				{STRING_32} "%/0x2502/[ Submit ] [Cancel]%/0x2502/",
				{STRING_32} "%/0x2514/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2518/">>)
			assert ("cursor after admin", l_vt.cursor_row = 1 and l_vt.cursor_column = 16)
			check attached l_map.item as m then
				assert ("user field", attached m.hit (12, 1) as id and then id ~ id_user)
				assert ("password field", attached m.hit (12, 2) as id and then id ~ id_pass)
				assert ("submit", attached m.hit (3, 3) as id and then id ~ id_submit)
				assert ("cancel", attached m.hit (14, 3) as id and then id ~ id_cancel)
				assert ("gap between buttons", m.hit (11, 3) = Void)
				assert ("border", m.hit (0, 0) = Void)
					-- Click on the password field
				assert ("click focuses password", form_focus.focus_at (m.hit (12, 2)))
			end
			l_term.draw (agent draw_form (?, l_map, l_popup_on))
			assert ("cursor after the mask", l_vt.cursor_row = 2 and l_vt.cursor_column = 16)
			assert ("mask kept", l_vt.line (2).same_string ({STRING_32} "%/0x2502/Password: *****    %/0x2502/"))
			form_focus.focus_next
			assert ("tab to submit", form_focus.is_focused (id_submit))

				-- A modal confirmation over the form
			create l_popup.make
			create l_block.make
			l_popup := l_popup.with_block (l_block.with_borders ({BORDERS}.all_borders))
			l_ok := para ("[ OK ]")
			l_popup.set_inner_widget (l_ok.with_alignment ({TEXT_ALIGNMENT}.center))
			l_popup.begin_modal_with (form_focus, <<id_ok>>)
			l_popup_on.put (l_popup)
			l_term.draw (agent draw_form (?, l_map, l_popup_on))
			assert_lines ("popup", l_vt, <<
				{STRING_32} "%/0x250C/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2510/",
				{STRING_32} "%/0x2502/Us%/0x250C/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2510/   %/0x2502/",
				{STRING_32} "%/0x2502/Pa%/0x2502/   [ OK ]   %/0x2502/   %/0x2502/",
				{STRING_32} "%/0x2502/[ %/0x2514/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2518/el]%/0x2502/",
				{STRING_32} "%/0x2514/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2518/">>)
			check attached l_map.item as m then
				assert ("user field visible but blocked", m.hit (19, 1) = Void)
				assert ("cancel visible but blocked", m.hit (18, 3) = Void)
				assert ("click behind changes nothing", not form_focus.focus_at (m.hit (19, 1)))
				assert ("ok reachable", attached m.hit (8, 2) as id and then id ~ id_ok)
				assert ("modal focus", form_focus.is_focused (id_ok))
			end
			l_popup.end_modal (form_focus)
			assert ("focus back on submit", form_focus.is_focused (id_submit))
		end

	test_modal_dialog_example_snapshot
			-- Item 5 of the M6/M7 review: the real EXAMPLE_MODAL_DIALOG on a 60x16
			-- VIRTUAL_TERMINAL, row-exact, with its hit map: the background, the confirmation
			-- opened with d (the files and Delete still visible around it but not clickable;
			-- Yes and No clickable; No focused, Tab moves to Yes), and the list after y.
			-- P2b U3: the confirmation is a TUI_DIALOG, laid out by its rules: the box fits its
			-- content (the 22-column message + 4 = 26 wide; 2 message rows + 4 = 6 high) and is
			-- centred in the frame at ((60 - 26) // 2, (16 - 6) // 2) = (17, 5); "[ Yes ]  [ No ]"
			-- is centred on the last row inside it, and each button's hit region is the button
			-- as drawn, under the ids made by DIALOG_STATE.
		local
			l_vt: VIRTUAL_TERMINAL
			l_term: TERMINAL [VIRTUAL_TERMINAL]
			l_app: MODAL_DIALOG_SCRIPTED_APP
			l_driver: FAKE_CONSOLE_DRIVER
			l_sink: STRING_32
			l_backend: ANSI_TERMINAL_BACKEND
			l_map: CELL [detachable HIT_MAP]
		do
			create l_vt.make (60, 16)
			create l_term.make (l_vt)
			create l_driver
			create l_sink.make_empty
			create l_backend.make_with_driver_and_sink (l_driver, l_sink)
			create l_app.make_scripted (l_driver,
				create {TERMINAL [ANSI_TERMINAL_BACKEND]}.make_with_viewport (l_backend, create {VIEWPORT}.make_fullscreen),
				{ARRAY [READABLE_STRING_8]} <<>>)
			create l_map.put (Void)

			l_term.draw (agent render_example (?, l_app, l_map))
			assert_lines ("background", l_vt, <<
				{STRING_32} "Click or Tab: focus | Enter: press | d: delete | h: hint | q",
				{STRING_32} "                                                            ",
				{STRING_32} "      [ > report.txt ]                                      ",
				{STRING_32} "        [ notes.md ]                                        ",
				{STRING_32} "         [ todo.e ]                                         ",
				{STRING_32} "                                                            ",
				{STRING_32} "   [ Delete ]    [ Help ]    [ Quit ]                       ",
				{STRING_32} "                                                            ",
				{STRING_32} "                                                            ",
				{STRING_32} "                                                            ",
				{STRING_32} "                                                            ",
				{STRING_32} "                                                            ",
				{STRING_32} "                                                            ",
				{STRING_32} "                                                            ",
				{STRING_32} "                                                            ",
				{STRING_32} "Click a file, then Delete. Clicks behind the dialog are bloc">>)
			check attached l_map.item as m then
				assert ("file clickable", attached m.hit (10, 2) as id and then id.value = 1)
				assert ("Delete clickable", attached m.hit (5, 6) as id and then id.value = 11)
			end

			l_app.process_now (create {KEY_EVENT}.make_char ('d'))
			l_term.draw (agent render_example (?, l_app, l_map))
			assert_lines ("dialog", l_vt, <<
				{STRING_32} "Click or Tab: focus | Enter: press | d: delete | h: hint | q",
				{STRING_32} "                                                            ",
				{STRING_32} "      [ > report.txt ]                                      ",
				{STRING_32} "        [ notes.md ]                                        ",
				{STRING_32} "         [ todo.e ]                                         ",
				{STRING_32} "                 %/0x2554/%/0x2550/%/0x2550/%/0x2550/%/0x2550/%/0x2550/%/0x2550/%/0x2550/ Confirm %/0x2550/%/0x2550/%/0x2550/%/0x2550/%/0x2550/%/0x2550/%/0x2550/%/0x2550/%/0x2557/                 ",
				{STRING_32} "   [ Delete ]    %/0x2551/  Delete %"report.txt%"?  %/0x2551/                 ",
				{STRING_32} "                 %/0x2551/ This cannot be undone. %/0x2551/                 ",
				{STRING_32} "                 %/0x2551/                        %/0x2551/                 ",
				{STRING_32} "                 %/0x2551/    [ Yes ]  [ No ]     %/0x2551/                 ",
				{STRING_32} "                 %/0x255A/%/0x2550/%/0x2550/%/0x2550/%/0x2550/%/0x2550/%/0x2550/%/0x2550/%/0x2550/%/0x2550/%/0x2550/%/0x2550/%/0x2550/%/0x2550/%/0x2550/%/0x2550/%/0x2550/%/0x2550/%/0x2550/%/0x2550/%/0x2550/%/0x2550/%/0x2550/%/0x2550/%/0x2550/%/0x255D/                 ",
				{STRING_32} "                                                            ",
				{STRING_32} "                                                            ",
				{STRING_32} "                                                            ",
				{STRING_32} "                                                            ",
				{STRING_32} "Delete report.txt? Tab / click Yes or No.                   ">>)
			check attached l_map.item as m then
				assert ("file above the dialog blocked", m.hit (10, 2) = Void)
				assert ("Delete beside the dialog blocked", m.hit (5, 6) = Void)
				assert ("Help under the dialog blocked", m.hit (20, 6) = Void)
				assert ("dialog border blocked", m.hit (17, 5) = Void)
				assert ("Yes clickable", attached m.hit (24, 9) as id and then id ~ l_app.dialog_button_id (1))
				assert ("No clickable", attached m.hit (33, 9) as id and then id ~ l_app.dialog_button_id (2))
				assert ("beside the buttons blocked", m.hit (30, 9) = Void)
				assert ("outside everything", m.hit (55, 13) = Void)
			end
			assert ("No focused first", l_app.is_dialog_button_focused (2))
			l_app.process_now (create {KEY_EVENT}.make_special ({KEY_CODE}.Tab))
			assert ("Tab moves to Yes", l_app.is_dialog_button_focused (1))
			l_app.process_now (create {KEY_EVENT}.make_special ({KEY_CODE}.Tab))
			assert ("Tab stays in the dialog", l_app.is_dialog_button_focused (2))

			l_app.process_now (create {KEY_EVENT}.make_char ('y'))
			l_term.draw (agent render_example (?, l_app, l_map))
			assert_lines ("deleted", l_vt, <<
				{STRING_32} "Click or Tab: focus | Enter: press | d: delete | h: hint | q",
				{STRING_32} "                                                            ",
				{STRING_32} "       [ > notes.md ]                                       ",
				{STRING_32} "         [ todo.e ]                                         ",
				{STRING_32} "                                                            ",
				{STRING_32} "                                                            ",
				{STRING_32} "   [ Delete ]    [ Help ]    [ Quit ]                       ",
				{STRING_32} "                                                            ",
				{STRING_32} "                                                            ",
				{STRING_32} "                                                            ",
				{STRING_32} "                                                            ",
				{STRING_32} "                                                            ",
				{STRING_32} "                                                            ",
				{STRING_32} "                                                            ",
				{STRING_32} "                                                            ",
				{STRING_32} "Deleted report.txt.                                         ">>)
			assert ("report.txt deleted", l_app.file_names.count = 2 and not l_app.file_names.has ({STRING_32} "report.txt"))
			check attached l_map.item as m then
				assert ("background clickable again", attached m.hit (5, 6) as id and then id.value = 11)
			end
		end

	test_input_form_example_snapshot
			-- T1: the real EXAMPLE_INPUT_FORM on a 64x18 VIRTUAL_TERMINAL, row-exact, in three
			-- states: First Name focused (cursor after "Ada"), Last Name after Tab (cursor
			-- after "Lovelace"), and Age after a second Tab and Down (35, no cursor). The
			-- border colours follow the focus, and each field is a hit region.
		local
			l_vt: VIRTUAL_TERMINAL
			l_term: TERMINAL [VIRTUAL_TERMINAL]
			l_app: INPUT_FORM_SNAPSHOT_APP
			l_backend: ANSI_TERMINAL_BACKEND
			l_buf: BUFFER
			l_frame: FRAME
		do
			create l_vt.make (64, 18)
			create l_term.make (l_vt)
			create l_backend.make_with_driver_and_sink (create {FAKE_CONSOLE_DRIVER}, create {STRING_32}.make_empty)
			create l_app.make_on (create {TERMINAL [ANSI_TERMINAL_BACKEND]}.make_with_viewport (l_backend, create {VIEWPORT}.make_fullscreen))

			l_term.draw (agent l_app.render_now)
			assert_lines ("first name", l_vt, input_form_rows (" First Name [Focused] ", " Last Name ", " Age ", "36"))
			assert ("cursor after Ada", l_vt.cursor_row = 4 and l_vt.cursor_column = 5 and l_vt.is_cursor_visible)
			create l_buf.make (64, 18)
			create l_frame.make (l_buf)
			l_app.render_now (l_frame)
			assert ("outer border cyan", l_buf.cell (0, 0).style.foreground ~ {COLOR}.Bright_cyan)
			assert ("focused border yellow", l_buf.cell (3, 1).style.foreground ~ {COLOR}.Bright_yellow)
			assert ("other borders gray", l_buf.cell (6, 1).style.foreground ~ {COLOR}.Dark_gray
				and l_buf.cell (9, 1).style.foreground ~ {COLOR}.Dark_gray)
			assert ("first name region", attached l_frame.hit_map.hit (10, 4) as id and then id.value = 1)
			assert ("last name region", attached l_frame.hit_map.hit (10, 7) as id and then id.value = 2)
			assert ("age region", attached l_frame.hit_map.hit (10, 10) as id and then id.value = 3)
			assert ("header is no region", l_frame.hit_map.hit (10, 1) = Void)

			l_app.process_now (create {KEY_EVENT}.make_special ({KEY_CODE}.Tab))
			l_term.draw (agent l_app.render_now)
			assert_lines ("last name", l_vt, input_form_rows (" First Name ", " Last Name [Focused] ", " Age ", "36"))
			assert ("cursor after Lovelace", l_vt.cursor_row = 7 and l_vt.cursor_column = 10 and l_vt.is_cursor_visible)

			l_app.process_now (create {KEY_EVENT}.make_special ({KEY_CODE}.Tab))
			l_app.process_now (create {KEY_EVENT}.make_special ({KEY_CODE}.Down))
			l_term.draw (agent l_app.render_now)
			assert_lines ("age", l_vt, input_form_rows (" First Name ", " Last Name ", " Age [Focused] ",
				"35  (Up/Down or Digits, max 130)"))
			assert ("no cursor on the age field", not l_vt.is_cursor_visible)
			create l_buf.make (64, 18)
			create l_frame.make (l_buf)
			l_app.render_now (l_frame)
			assert ("age border yellow", l_buf.cell (9, 1).style.foreground ~ {COLOR}.Bright_yellow)
			assert ("first name border gray again", l_buf.cell (3, 1).style.foreground ~ {COLOR}.Dark_gray)
		end

	test_demo2_ping_sparkline_absent_and_bar_styles
			-- The real EXAMPLE_DEMO2 Traceroute tab (tab 4, which the batch run never shows) on a
			-- 120 x 40 frame: the ping sparkline draws a lost packet (0) as a bold red cross in
			-- every row of its column (absent value), a slow ping (7 or 8) in yellow (its own
			-- SPARKLINE_BAR style over the green bar style), and the other pings in green.
		local
			l_app: DEMO2_SNAPSHOT_APP
			l_backend: ANSI_TERMINAL_BACKEND
			l_buf: BUFFER
			l_frame: FRAME
			r, c, l_code: INTEGER
			l_rows: ARRAYED_SET [INTEGER]
			l_crosses, l_yellow, l_green: INTEGER
			l_style: STYLE
		do
			create l_backend.make_with_driver_and_sink (create {FAKE_CONSOLE_DRIVER}, create {STRING_32}.make_empty)
			create l_app.make_on_terminal (create {TERMINAL [ANSI_TERMINAL_BACKEND]}.make_with_viewport (l_backend, create {VIEWPORT}.make_fullscreen))
			assert ("the wave has lost packets", l_app.ping_values.has (0))
			l_app.show_tab (4)
			create l_buf.make (120, 40)
			create l_frame.make (l_buf)
			l_app.render_now (l_frame)
			assert ("buffer consistent", l_buf.is_consistent)

				-- The rows of the sparkline are the rows with a red cross (the title's
				-- "x lost" cross is in the title style, not red)
			create l_rows.make (8)
			from r := 0 until r >= l_buf.height loop
				from c := 0 until c >= l_buf.width loop
					l_style := l_buf.cell (r, c).style
					if l_buf.cell (r, c).symbol.same_string ({STRING_32} "%/0xD7/") then
						if l_style.foreground ~ {COLOR}.Bright_red then
							assert ("cross is bold", l_style.is_bold)
							l_crosses := l_crosses + 1
							l_rows.put (r)
						else
							assert ("other cross is the title's", l_buf.line (r).has_substring ({STRING_32} "%/0xD7/ lost, yellow slow"))
						end
					end
					c := c + 1
				end
				r := r + 1
			end
			assert ("lost packets drawn", l_crosses > 0 and not l_rows.is_empty)
			assert ("a cross in every row of its column", l_crosses \\ l_rows.count = 0)

			across l_rows as l_row loop
				from c := 0 until c >= l_buf.width loop
					if l_buf.cell (l_row, c).symbol.count = 1 then
						l_code := l_buf.cell (l_row, c).symbol.code (1).to_integer_32
						if l_code >= 0x2581 and l_code <= 0x2588 then
							l_style := l_buf.cell (l_row, c).style
							if l_style.foreground ~ {COLOR}.Bright_yellow then
								l_yellow := l_yellow + 1
							elseif l_style.foreground ~ {COLOR}.Bright_green then
								l_green := l_green + 1
							end
						end
					end
					c := c + 1
				end
			end
			assert ("slow pings in yellow", l_yellow > 0)
			assert ("other pings in green", l_green > 0)
		end

	input_form_rows (a_first, a_last, a_age, a_age_value: STRING): ARRAY [STRING_32]
			-- The 18 rows of EXAMPLE_INPUT_FORM on a 64x18 screen, with these field titles and
			-- age text: a rounded box with a centred title, the centred help line, three plain
			-- field boxes 62 wide, and the centred status line (47 wide, so at 62 / 2 - 47 / 2 = 8,
			-- as Ratatui's paragraph centres; review fix #7).
		local
			l_side, l_blank: STRING_32
		do
			l_side := {STRING_32} "%/0x2502/"
			l_blank := l_side + spaces (62) + l_side
			Result := <<
				{STRING_32} "%/0x256D/" + rule (21) + {STRING_32} " User Profile Form " + rule (22) + {STRING_32} "%/0x256E/",
				l_side + spaces (4) + {STRING_32} "Tab/Shift-Tab/Click: Focus | Enter: Submit | Esc: Exit" + spaces (4) + l_side,
				l_blank,
				field_top (a_first), field_value ("Ada"), field_bottom,
				field_top (a_last), field_value ("Lovelace"), field_bottom,
				field_top (a_age), field_value (a_age_value), field_bottom,
				l_side + spaces (8) + {STRING_32} "Status: Filling form... Press Enter when ready." + spaces (7) + l_side,
				l_blank, l_blank, l_blank, l_blank,
				{STRING_32} "%/0x2570/" + rule (62) + {STRING_32} "%/0x256F/">>
		end

	field_top (a_title: STRING): STRING_32
			-- Top border of a 62-wide field box titled `a_title`, inside the outer box.
		do
			Result := {STRING_32} "%/0x2502/%/0x250C/" + a_title.to_string_32 + rule (60 - a_title.count) + {STRING_32} "%/0x2510/%/0x2502/"
		end

	field_value (a_text: STRING): STRING_32
			-- Content row of a field box showing `a_text`.
		do
			Result := {STRING_32} "%/0x2502/%/0x2502/" + a_text.to_string_32 + spaces (60 - a_text.count) + {STRING_32} "%/0x2502/%/0x2502/"
		end

	field_bottom: STRING_32
			-- Bottom border of a field box.
		do
			Result := {STRING_32} "%/0x2502/%/0x2514/" + rule (60) + {STRING_32} "%/0x2518/%/0x2502/"
		end

	rule (n: INTEGER): STRING_32
			-- `n` horizontal box-drawing lines.
		do
			create Result.make_filled ('%/0x2500/', n)
		end

	spaces (n: INTEGER): STRING_32
			-- `n` spaces.
		do
			create Result.make_filled (' ', n)
		end

	render_example (a_frame: FRAME; a_app: MODAL_DIALOG_SCRIPTED_APP; a_map: CELL [detachable HIT_MAP])
			-- Render `a_app` into `a_frame` and keep the frame's hit map in `a_map`.
		do
			a_app.render_now (a_frame)
			a_map.put (a_frame.hit_map)
		end

feature {NONE} -- Form

	-- Self-initializing, so that the test set's `default_create` leaves them attached;
	-- `test_form_snapshot_with_clicks_and_modal` creates the ones it uses.

	form_focus: FOCUS_MANAGER
			-- Focus of the form's controls
		attribute
			create Result.make
		end

	id_user: WIDGET_ID
			-- Username field
		attribute
			create Result.make (1)
		end

	id_pass: WIDGET_ID
			-- Password field
		attribute
			create Result.make (2)
		end

	id_submit: WIDGET_ID
			-- Submit button
		attribute
			create Result.make (3)
		end

	id_cancel: WIDGET_ID
			-- Cancel button
		attribute
			create Result.make (4)
		end

	id_ok: WIDGET_ID
			-- OK button of the modal popup
		attribute
			create Result.make (10)
		end

	user_state: TEXT_INPUT_STATE
			-- Username field content
		attribute
			create Result
		end

	pass_state: TEXT_INPUT_STATE
			-- Password field content
		attribute
			create Result
		end

	draw_form (a_frame: FRAME; a_map: CELL [detachable HIT_MAP]; a_popup: CELL [detachable TUI_POPUP])
			-- The form diagram: a bordered box with two labelled inputs and two buttons,
			-- plus the popup `a_popup.item`, if any, with its OK button. Keeps the frame's hit
			-- map in `a_map`.
		local
			l_block: TUI_BLOCK
			l_user, l_pass: TUI_TEXT_INPUT
			l_rect: RECT
		do
			create l_block.make
			a_frame.render_widget (l_block.with_borders ({BORDERS}.all_borders), a_frame.area)
			a_frame.render_widget (para ("Username: "), create {RECT}.make (1, 1, 10, 1))
			a_frame.render_widget (para ("Password: "), create {RECT}.make (1, 2, 10, 1))
			create l_user.make
			l_user := l_user.with_shows_cursor (form_focus.is_focused (id_user)).with_hit_id (id_user)
			create l_rect.make (11, 1, 9, 1)
			a_frame.render_stateful_widget (l_user, l_rect, user_state)
			if form_focus.is_focused (id_user) and then attached l_user.cursor_screen_position (l_rect, user_state) as c then
				a_frame.set_cursor_position (c.col, c.row)
			end
			create l_pass.make
			l_pass.set_mask_char ('*')
			l_pass := l_pass.with_shows_cursor (form_focus.is_focused (id_pass)).with_hit_id (id_pass)
			create l_rect.make (11, 2, 9, 1)
			a_frame.render_stateful_widget (l_pass, l_rect, pass_state)
			if form_focus.is_focused (id_pass) and then attached l_pass.cursor_screen_position (l_rect, pass_state) as c then
				a_frame.set_cursor_position (c.col, c.row)
			end
			create l_rect.make (1, 3, 10, 1)
			a_frame.render_widget (para ("[ Submit ]"), l_rect)
			a_frame.register_hit (id_submit, l_rect)
			create l_rect.make (12, 3, 8, 1)
			a_frame.render_widget (para ("[Cancel]"), l_rect)
			a_frame.register_hit (id_cancel, l_rect)
			if attached a_popup.item as l_popup then
				create l_rect.make (3, 1, 14, 3)
				a_frame.render_widget (l_popup, l_rect)
				a_frame.register_hit (id_ok, create {RECT}.make (4, 2, 12, 1))
			end
			a_map.put (a_frame.hit_map)
		end

feature {NONE} -- Helpers

	para (a_text: STRING): TUI_PARAGRAPH
			-- Paragraph showing `a_text` in the default style.
		do
			create Result.make (create {TEXT}.make_raw (a_text))
		end

	new_app (a_input: READABLE_STRING_8; a_viewport: VIEWPORT): TEST_TUI_APP_IMPL
			-- Application on a fake console replaying `a_input`, output captured.
		local
			l_driver: FAKE_CONSOLE_DRIVER
		do
			create l_driver
			l_driver.script (a_input)
			Result := new_app_on (l_driver, a_viewport)
		end

	new_app_on (a_driver: FAKE_CONSOLE_DRIVER; a_viewport: VIEWPORT): TEST_TUI_APP_IMPL
			-- Application on `a_driver`, output captured.
		local
			l_sink: STRING_32
			l_backend: ANSI_TERMINAL_BACKEND
		do
			create l_sink.make_empty
			a_driver.watch_sink (l_sink)
			create l_backend.make_with_driver_and_sink (a_driver, l_sink)
			create Result.make_with_terminal (create {TERMINAL [ANSI_TERMINAL_BACKEND]}.make_with_viewport (l_backend, a_viewport))
			Result.event_thread.set_poll_interval (5)
		end

	assert_lines (a_tag: STRING; a_vt: VIRTUAL_TERMINAL; a_lines: ARRAY [STRING_32])
			-- Check that the rows of `a_vt` are exactly `a_lines`.
		local
			i: INTEGER
		do
			from
				i := a_lines.lower
			until
				i > a_lines.upper
			loop
				assert (a_tag + ": row " + (i - a_lines.lower).out + " is ["
					+ {UTF_CONVERTER}.string_32_to_utf_8_string_8 (a_vt.line (i - a_lines.lower)) + "]",
					a_vt.line (i - a_lines.lower).same_string (a_lines [i]))
				i := i + 1
			end
		end

	Esc: STRING_8 = "%/27/"
			-- ESC, for scripted input

end
