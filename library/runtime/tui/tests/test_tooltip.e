note
	description: "[
		P2 item W6, TUI_TOOLTIP and HOVER_STATE (review/p2_terminal_widgets_plan.md).
		Ratatui has no tooltip widget, so these are EiffelTUI's own tests:
		  * placement (OVERLAY_PLACEMENT, shared with TUI_MENU): the four sides, the flip at
		    each edge, corners and cases where neither side fits (cut, or nothing drawn), a
		    box cut beside the anchor and wrapped again;
		  * row-exact buffer snapshots: short text, wrapped text, borderless, cut boxes;
		  * styles, the `with_*` builders and the preconditions;
		  * HOVER_STATE: the delay in ticks, moving to another control, leaving, dismissing;
		  * EXAMPLE_TOOLTIPS: the F1 tooltip of the focused control (shifted at the right edge,
		    flipped at the bottom), and hover in the real event loop from motion reports
		    scripted on the fake console (`CSI < 35 ; col ; row M`), as a terminal with mode
		    1003 sends them.
		Box glyphs (plain): U+250C, U+2500, U+2510, U+2502, U+2514, U+2518. Snapshots fill the
		buffer with '.' first, so the cleared underlay shows.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_TOOLTIP

inherit
	BUFFER_TEST_HELPER

feature -- Placement

	test_tooltip_placement_four_sides
			-- "Hi" (a 4 x 3 box) next to an anchor in the middle of 40 x 20 bounds, on each side.
		local
			t: TUI_TOOLTIP
			b, a: RECT
		do
			create b.make (0, 0, 40, 20)
			create a.make (10, 8, 6, 1)
			create t.make ("Hi", a)
			assert_rect ("below", t.placement (a, b), 10, 9, 4, 3)
			assert ("below kept", t.placed_side (a, b) = {OVERLAY_PLACEMENT}.below)
			assert_rect ("above", t.with_preferred_side ({OVERLAY_PLACEMENT}.above).placement (a, b), 10, 5, 4, 3)
			assert_rect ("right", t.with_preferred_side ({OVERLAY_PLACEMENT}.right).placement (a, b), 16, 8, 4, 3)
			assert_rect ("left", t.with_preferred_side ({OVERLAY_PLACEMENT}.left).placement (a, b), 6, 8, 4, 3)
			assert_rect ("borderless below", t.with_bordered (False).placement (a, b), 10, 9, 2, 1)
		end

	test_tooltip_flips_at_each_edge
			-- Each side flips to its opposite when the box does not fit whole at the edge.
		local
			t: TUI_TOOLTIP
			b, a: RECT
		do
			create b.make (0, 0, 40, 20)
			create t.make ("Hi", create {RECT}.make (0, 0, 1, 1))
			create a.make (10, 18, 6, 1)
			assert_rect ("bottom: above", t.placement (a, b), 10, 15, 4, 3)
			assert ("bottom side", t.placed_side (a, b) = {OVERLAY_PLACEMENT}.above)
			create a.make (10, 1, 6, 1)
			t.set_preferred_side ({OVERLAY_PLACEMENT}.above)
			assert_rect ("top: below", t.placement (a, b), 10, 2, 4, 3)
			assert ("top side", t.placed_side (a, b) = {OVERLAY_PLACEMENT}.below)
			create a.make (34, 8, 6, 1)
			t.set_preferred_side ({OVERLAY_PLACEMENT}.right)
			assert_rect ("right edge: left", t.placement (a, b), 30, 8, 4, 3)
			assert ("right edge side", t.placed_side (a, b) = {OVERLAY_PLACEMENT}.left)
			create a.make (1, 8, 6, 1)
			t.set_preferred_side ({OVERLAY_PLACEMENT}.left)
			assert_rect ("left edge: right", t.placement (a, b), 7, 8, 4, 3)
			assert ("left edge side", t.placed_side (a, b) = {OVERLAY_PLACEMENT}.right)
				-- Offset bounds: the edges are the bounds', not the buffer's
			create b.make (5, 5, 20, 10)
			create a.make (8, 13, 4, 1)
			t.set_preferred_side ({OVERLAY_PLACEMENT}.below)
			assert_rect ("offset bounds: above", t.placement (a, b), 8, 10, 4, 3)
		end

	test_tooltip_corners_and_neither_side
			-- Corners: shifted back along the edge and flipped; neither side fits: the side with
			-- more room, the preferred one on a tie, cut; no room for an inside: nothing.
		local
			t: TUI_TOOLTIP
			b, a: RECT
		do
			create b.make (0, 0, 20, 7)
			create t.make ("Hi", create {RECT}.make (0, 0, 1, 1))
				-- Bottom-right corner: flipped above, shifted left to end at the right edge
			create a.make (18, 6, 2, 1)
			assert_rect ("bottom-right", t.placement (a, b), 16, 3, 4, 3)
				-- Top-left corner, preferred left: flipped right
			create a.make (0, 0, 3, 1)
			assert_rect ("top-left", t.with_preferred_side ({OVERLAY_PLACEMENT}.left).placement (a, b), 3, 0, 4, 3)
				-- Top-right corner, preferred right: flipped left, from the top row
			create a.make (17, 0, 3, 1)
			assert_rect ("top-right", t.with_preferred_side ({OVERLAY_PLACEMENT}.right).placement (a, b), 13, 0, 4, 3)
				-- Bottom-left corner, preferred above: kept above
			create a.make (0, 6, 3, 1)
			assert_rect ("bottom-left", t.with_preferred_side ({OVERLAY_PLACEMENT}.above).placement (a, b), 0, 3, 4, 3)
				-- Three rows of text (5 high) with 3 rows on each side: a tie, so below, cut
			create a.make (5, 3, 4, 1)
			t.set_text ("one%Ntwo%Nthree")
			assert_rect ("tie: below, cut", t.placement (a, b), 5, 4, 7, 3)
			assert ("tie side", t.placed_side (a, b) = {OVERLAY_PLACEMENT}.below)
				-- More room above: above, cut
			create a.make (5, 4, 4, 1)
			assert_rect ("more room above", t.placement (a, b), 5, 0, 7, 4)
				-- One row below and none above: a bordered box has no inside, so nothing...
			create b.make (0, 0, 10, 5)
			create a.make (0, 0, 10, 4)
			t.set_text ("Hi")
			t.set_preferred_side ({OVERLAY_PLACEMENT}.above)
			assert ("no inside: empty", t.placement (a, b).is_empty)
				-- ...while a borderless one shows its row
			assert_rect ("borderless row", t.with_bordered (False).placement (a, b), 0, 4, 2, 1)
				-- The anchor covers the bounds: no room anywhere
			create a.make (0, 0, 10, 5)
			assert ("no room", t.placement (a, b).is_empty and t.with_bordered (False).placement (a, b).is_empty)
				-- Bounds narrower than a box: nothing
			assert ("narrow bounds", t.placement (create {RECT}.make (0, 0, 10, 5), create {RECT}.make (0, 6, 2, 9)).is_empty)
		end

	test_tooltip_cut_beside_anchor_wraps_again
			-- Neither side fits a one-row box beside a tall anchor: it goes left (more room),
			-- 8 columns wide, and the text wraps again to 6 columns, one word per row, so the box
			-- is placed again 6 rows high.
		local
			t: TUI_TOOLTIP
			b, a: RECT
			l_buf: BUFFER
			l_grid: ARRAYED_LIST [STRING_32]
		do
			create b.make (0, 0, 20, 6)
			create a.make (8, 0, 12, 6)
			create t.make ("aaa bbb ccc ddd", a)
			t.set_preferred_side ({OVERLAY_PLACEMENT}.right)
			assert_rect ("cut and taller", t.placement (a, b), 0, 0, 8, 6)
			assert ("left", t.placed_side (a, b) = {OVERLAY_PLACEMENT}.left)
			l_buf := dotted_buffer (20, 6)
			t.render (l_buf.area, l_buf)
			l_grid := dots (20, 6)
			put_box (l_grid, 0, 0, 6, <<"aaa", "bbb", "ccc", "ddd">>)
			assert_grid ("cut beside", l_buf, l_grid)
		end

feature -- Snapshots

	test_tooltip_short_text_snapshot
			-- "Save" below a 5-column anchor at (2, 1): a 6 x 3 box at (2, 2) over the dots; the
			-- anchor's own cells are not touched. The box's style is patched over the cleared
			-- cells, the border style over that on the border.
		local
			t: TUI_TOOLTIP
			l_buf: BUFFER
			l_grid: ARRAYED_LIST [STRING_32]
			l_style, l_border: STYLE
		do
			create l_style.make_fg ({COLOR}.yellow)
			create l_border.make_fg ({COLOR}.cyan)
			create t.make ("Save", create {RECT}.make (2, 1, 5, 1))
			l_buf := dotted_buffer (20, 6)
			t.with_style (l_style).with_border_style (l_border).render (l_buf.area, l_buf)
			l_grid := dots (20, 6)
			put_box (l_grid, 2, 2, 4, <<"Save">>)
			assert_grid ("short", l_buf, l_grid)
			assert_cell_style ("text", l_buf, 3, 3, l_style)
			assert_cell_style ("border", l_buf, 2, 2, l_style.patch (l_border))
			assert_cell_style ("outside untouched", l_buf, 1, 2, create {STYLE})
				-- Borderless: the text alone, in the style
			l_buf := dotted_buffer (20, 6)
			t.with_bordered (False).with_style (l_style).render (l_buf.area, l_buf)
			l_grid := dots (20, 6)
			l_grid [3].replace_substring ("Save", 3, 6)
			assert_grid ("borderless", l_buf, l_grid)
			assert_cell_style ("borderless text", l_buf, 2, 2, l_style)
		end

	test_tooltip_wrapped_text_snapshot
			-- At most 12 columns of box: "Wrap long lines at the edge" wraps to three rows of at
			-- most 10; the box is as wide as the widest (9) plus the border. %N starts a row, a
			-- long word is broken, and a wide character keeps its two columns.
		local
			t: TUI_TOOLTIP
			l_buf: BUFFER
			l_grid: ARRAYED_LIST [STRING_32]
		do
			create t.make ("Wrap long lines at the edge", create {RECT}.make (1, 0, 6, 1))
			t.set_max_width (12)
			l_buf := dotted_buffer (24, 7)
			t.render (l_buf.area, l_buf)
			l_grid := dots (24, 7)
			put_box (l_grid, 1, 1, 9, <<"Wrap long", "lines at", "the edge">>)
			assert_grid ("wrapped", l_buf, l_grid)

			l_buf := dotted_buffer (24, 7)
			t.with_text ("ab%Nabcdefghijklm").render (l_buf.area, l_buf)
			l_grid := dots (24, 7)
			put_box (l_grid, 1, 1, 10, <<"ab", "abcdefghij", "klm">>)
			assert_grid ("newline and long word", l_buf, l_grid)

			l_buf := dotted_buffer (24, 7)
			t.with_text ({STRING_32} "%/0x5BBD/ ok").render (l_buf.area, l_buf)
			assert ("wide box top", buffer_row_as_string (l_buf, 1).substring (2, 8).same_string (tl + h (5) + tr))
				-- The wide character's second cell reads as nothing
			assert ("wide character", buffer_row_as_string (l_buf, 2).substring (2, 7).same_string (
				v + {STRING_32} "%/0x5BBD/ ok" + v))
			assert ("consistent", l_buf.is_consistent)

				-- Below the anchor and cut at the bottom of the bounds: the first row only
			l_buf := dotted_buffer (20, 7)
			create t.make ("one%Ntwo%Nthree", create {RECT}.make (5, 3, 4, 1))
			t.render (l_buf.area, l_buf)
			l_grid := dots (20, 7)
			put_box (l_grid, 5, 4, 5, <<"one">>)
			assert_grid ("cut below", l_buf, l_grid)
		end

	test_tooltip_bounds_and_buffer
			-- The area given to `render` is the bounds, clipped to the buffer: a box flips inside
			-- a small area, and an area past the buffer's edge places the box in the buffer.
		local
			t: TUI_TOOLTIP
			l_buf: BUFFER
			l_grid: ARRAYED_LIST [STRING_32]
		do
			create t.make ("Hi", create {RECT}.make (2, 3, 3, 1))
				-- Bounds of 5 rows: no room below the anchor's row 3, so above
			l_buf := dotted_buffer (12, 8)
			t.render (create {RECT}.make (0, 0, 12, 5), l_buf)
			l_grid := dots (12, 8)
			put_box (l_grid, 2, 0, 2, <<"Hi">>)
			assert_grid ("above in the area", l_buf, l_grid)
				-- An area reaching past the buffer: the buffer's last rows are the edge
			l_buf := dotted_buffer (12, 5)
			t.render (create {RECT}.make (0, 0, 40, 40), l_buf)
			l_grid := dots (12, 5)
			put_box (l_grid, 2, 0, 2, <<"Hi">>)
			assert_grid ("above at the buffer's edge", l_buf, l_grid)
				-- An area the anchor is outside of
			l_buf := dotted_buffer (12, 8)
			t.render (create {RECT}.make (6, 0, 6, 8), l_buf)
			assert ("box in the area", buffer_row_as_string (l_buf, 4).substring (7, 10).same_string (tl + h (2) + tr))
		end

feature -- API

	test_tooltip_builders_and_equality
			-- Each `with_*` returns a changed copy and leaves the original alone; the text is
			-- the tooltip's own copy; `is_equal` compares every attribute; bad values refused.
		local
			t, u: TUI_TOOLTIP
			l_text: TEXT
			l_style: STYLE
		do
			create t.make ("Help", create {RECT}.make (1, 2, 3, 1))
			assert ("defaults", t.preferred_side = {OVERLAY_PLACEMENT}.below and t.max_width = {TUI_TOOLTIP}.Default_max_width
				and t.is_bordered and t.border_type = {BORDER_TYPE}.plain and t.border_size = 1)
			create l_style.make_fg ({COLOR}.red)
			u := t.with_preferred_side ({OVERLAY_PLACEMENT}.left).with_max_width (9).with_bordered (False)
				.with_border_type ({BORDER_TYPE}.rounded).with_style (l_style).with_border_style (l_style)
				.with_anchor (create {RECT}.make (4, 4, 1, 1))
			assert ("changed", u.preferred_side = {OVERLAY_PLACEMENT}.left and u.max_width = 9 and not u.is_bordered
				and u.border_type = {BORDER_TYPE}.rounded and u.style = l_style and u.border_style = l_style
				and u.anchor.x = 4 and u.border_size = 0)
			assert ("original kept", t.preferred_side = {OVERLAY_PLACEMENT}.below and t.max_width = {TUI_TOOLTIP}.Default_max_width
				and t.is_bordered and t.anchor.x = 1)
			assert ("differ", not t.is_equal (u))
			assert ("equal to a copy", t.is_equal (t.twin) and t.twin ~ t)
			assert ("text differs", not t.is_equal (t.with_text ("Other")))
			create l_text.make_raw ("Mine")
			u := t.with_text_value (l_text)
			l_text.append_line (create {TEXT_LINE}.make_raw ("more"))
			assert ("own copy", u.text.line_count = 1)
			create u.make_with_text (l_text, t.anchor)
			assert ("make copies", u.text ~ l_text and u.text /= l_text)
			assert ("width refused", precondition_raised (agent t.set_max_width (2), "room_for_text"))
			assert ("side refused", precondition_raised (agent t.set_preferred_side (0), "valid_side"))
			assert ("side refused 5", precondition_raised (agent t.set_preferred_side (5), "valid_side"))
			assert ("border type refused", precondition_raised (agent t.set_border_type (200), "valid_type"))
		end

feature -- Hover

	test_hover_state
			-- Shown after `delay_ticks` ticks on the same control; another control starts again,
			-- the same one does not; Void hides; `dismiss` hides until the pointer moves on.
		local
			s: HOVER_STATE
		do
			create s.make (3)
			assert ("nothing", s.hovered = Void and not s.is_shown and s.shown_id = Void)
			s.tick
			assert ("no count without hover", s.rested_ticks = 0)
			s.hover (id (1))
			s.tick
			s.tick
			assert ("2 ticks: not yet", not s.is_shown and s.rested_ticks = 2)
			s.hover (id (1))
			s.tick
			assert ("same control kept counting: shown at 3", s.is_shown and s.shown_id ~ id (1))
			s.tick
			assert ("capped", s.rested_ticks = 3 and s.is_shown)
			s.hover (id (2))
			assert ("another starts again", not s.is_shown and s.rested_ticks = 0 and s.hovered ~ id (2))
			s.tick
			s.tick
			s.tick
			assert ("second shown", s.shown_id ~ id (2))
			s.dismiss
			assert ("dismissed", not s.is_shown and s.is_dismissed)
			s.tick
			s.hover (id (2))
			assert ("same control: still dismissed", not s.is_shown)
			s.hover (Void)
			assert ("left: hidden, no count", not s.is_shown and s.rested_ticks = 0 and not s.is_dismissed)
			s.tick
			assert ("no count on nothing", s.rested_ticks = 0)
			s.hover (id (2))
			s.tick
			s.tick
			s.tick
			assert ("back: shown again", s.is_shown)
				-- No delay: shown at once
			s := (create {HOVER_STATE}).with_delay_ticks (0)
			s.hover (id (5))
			assert ("no delay", s.is_shown)
			assert ("default delay", (create {HOVER_STATE}).delay_ticks = {HOVER_STATE}.Default_delay_ticks)
			create s.make (5)
			s.hover (id (1))
			s.tick
			s.tick
			s.tick
			s.set_delay_ticks (2)
			assert ("lowered delay: shown", s.is_shown and s.rested_ticks = 2)
			assert ("negative refused", precondition_raised (agent s.set_delay_ticks (-1), "non_negative"))
		end

	test_tooltip_hit_region
			-- Without a `hit_id` the tooltip registers nothing (a click reaches what is under
			-- it); with one, its box is registered under it, and not the anchor.
		local
			t: TUI_TOOLTIP
			l_frame: FRAME
		do
			create t.make ("Save", create {RECT}.make (2, 1, 5, 1))
			l_frame := background_frame
			l_frame.render_widget (t, l_frame.area)
			assert ("no id: nothing", attached l_frame.hit_map.hit (3, 3) as l_hit and then l_hit ~ id (90))
			l_frame := background_frame
			l_frame.render_widget (t.with_hit_id (id (300)), l_frame.area)
			assert ("box", attached l_frame.hit_map.hit (3, 3) as l_hit and then l_hit ~ id (300))
			assert ("box corner", attached l_frame.hit_map.hit (7, 4) as l_hit and then l_hit ~ id (300))
			assert ("right of the box", attached l_frame.hit_map.hit (8, 3) as l_hit and then l_hit ~ id (90))
			assert ("anchor not covered", attached l_frame.hit_map.hit (2, 1) as l_hit and then l_hit ~ id (90))
			assert ("hit id in equality", not (t ~ t.with_hit_id (id (300))))
		end

	test_hover_state_tooltip_id
			-- The pointer moving onto the tooltip (`tooltip_id`) keeps the hover on its control;
			-- Void is never the tooltip.
		local
			s: HOVER_STATE
		do
			s := (create {HOVER_STATE}).with_delay_ticks (1).with_tooltip_id (id (300))
			s.hover (id (1))
			s.tick
			assert ("shown", s.shown_id ~ id (1))
			s.hover (id (300))
			assert ("on the tooltip: kept", s.hovered ~ id (1) and s.shown_id ~ id (1))
			s.dismiss
			s.hover (id (300))
			assert ("on the tooltip: still dismissed", s.is_dismissed and not s.is_shown)
			s.hover (Void)
			assert ("left: hidden", s.hovered = Void)
			s.hover (id (300))
			assert ("a stale tooltip region hovers nothing", s.hovered = Void and not s.is_shown)
			assert ("Void is not the tooltip", not s.is_tooltip (Void))
			s := (create {HOVER_STATE}).with_delay_ticks (1)
			s.hover (id (1))
			s.hover (Void)
			assert ("no tooltip id: Void still leaves", s.hovered = Void)
		end

	background_frame: FRAME
			-- A 20 x 6 frame whose whole area is registered under id 90
		do
			create Result.make (create {BUFFER}.make (20, 6))
			Result.register_hit (id (90), Result.area)
		end

feature -- Example

	test_tooltips_example_focus
			-- EXAMPLE_TOOLTIPS on a 60 x 16 frame, driven without `run`: F1 shows the tooltip of
			-- the focused "Wrap lines", wrapped to 28 columns below it; Tab twice: "Autosave" at
			-- the right edge, its box shifted left to end at the frame's edge; Tab: "Spell check"
			-- on the last rows, its box flipped above; F1 again hides it.
		local
			l_app: TOOLTIPS_SNAPSHOT_APP
			l_buf: BUFFER
			a: RECT
			x: INTEGER
		do
			l_app := new_snapshot_app
			l_buf := example_frame (l_app)
			assert ("help", buffer_row_as_string (l_buf, 1).has_substring ("Hover or F1: help"))
			assert ("no tooltip", l_app.shown_index = 0)
			l_app.process_now (f1)
			assert ("F1", l_app.is_help_shown and l_app.shown_index = 1)
			l_buf := example_frame (l_app)
			a := l_app.anchors [1]
			assert ("anchor", a.x = 2 and a.y = 3)
			assert_rows_at ("wrap lines tooltip", l_buf, 2, 4, <<
				tl + h (24) + tr,
				v + "Wrap long lines at the  " + v,
				v + "window's edge instead of" + v,
				v + "scrolling sideways.     " + v,
				bl + h (24) + br>>)
			assert_cell_style ("info border", l_buf, 4, 2, {TUI_THEME}.dark.base.patch ({TUI_THEME}.dark.info))
			l_app.process_now (create {KEY_EVENT}.make_special ({KEY_CODE}.Tab))
			l_app.process_now (create {KEY_EVENT}.make_special ({KEY_CODE}.Tab))
			assert ("autosave focused", l_app.is_focused_index (3) and l_app.shown_index = 3)
			l_buf := example_frame (l_app)
			a := l_app.anchors [3]
			x := a.x.to_integer_32.min (60 - 18)
			assert ("shifted left", x < a.x.to_integer_32)
			assert_rows_at ("autosave tooltip", l_buf, x, a.y.to_integer_32 + 1, <<
				tl + h (16) + tr,
				v + "Save every 30 s." + v,
				bl + h (16) + br>>)
			l_app.process_now (create {KEY_EVENT}.make_special ({KEY_CODE}.Tab))
			l_buf := example_frame (l_app)
			a := l_app.anchors [4]
			assert ("spell check on row 13", a.y = 13)
			assert_rows_at ("flipped above", l_buf, 2, 10, <<
				tl + h (24) + tr,
				v + "Underline unknown words." + v,
				bl + h (24) + br>>)
			l_app.process_now (f1)
			l_buf := example_frame (l_app)
			assert ("hidden", l_app.shown_index = 0 and not buffer_row_as_string (l_buf, 11).has_substring ("Underline"))
			assert ("consistent", l_buf.is_consistent)
		end

	test_tooltips_example_hover
			-- The real event loop on a fixed viewport at screen (10, 3), motion reporting on, a
			-- delay of 3 ticks of 5 ms. Motion reports (SGR button code 35, as a terminal sends
			-- them in mode 1003) are scripted on the fake console one step at a time, each once
			-- the previous step shows on screen:
			--   1. a move onto "Line numbers": after the delay its tooltip is drawn below it;
			--   2. a move to an empty cell: the tooltip goes, nothing is hovered;
			--   3. a move onto "Spell check": its tooltip flips above it;
			--   4. a click on it: the tooltip is dismissed and the box toggled;
			--   5. q quits.
			-- The output starts motion reporting after the mouse modes and stops it on exit.
		local
			l_app: TOOLTIPS_SNAPSHOT_APP
			l_driver: FAKE_CONSOLE_DRIVER
			l_sink: STRING_32
			l_backend: ANSI_TERMINAL_BACKEND
		do
			create l_driver
			create l_sink.make_empty
			l_driver.watch_sink (l_sink)
			create l_backend.make_with_driver_and_sink (l_driver, l_sink)
			create l_app.make_on (create {TERMINAL [ANSI_TERMINAL_BACKEND]}.make_with_viewport (l_backend,
				create {VIEWPORT}.make_fixed (create {RECT}.make (10, 3, 60, 16))))
			l_app.event_thread.set_poll_interval (5)
			l_app.set_tick_rate (5)
			l_app.hover.set_delay_ticks (3)
			hover_step := 0
			hover_frames := 0
			hover_shots.wipe_out
			l_app.set_frame_hook (agent hover_frame (?, l_app, l_driver))
			l_app.run
			assert ("frames capped", hover_frames < Hover_frame_cap)
			assert ("all steps", hover_step >= 5 and hover_shots.count = 4)
				-- 1. Line numbers' tooltip below it, at frame (2, 6)
			assert_shot ("line numbers", hover_shots [1], 2, 6, <<
				tl + h (24) + tr,
				v + "Show line numbers in the" + v,
				v + "gutter.                 " + v,
				bl + h (24) + br>>)
			assert ("status", hover_shots [1] [15].has_substring ("Hovered: Line numbers"))
				-- 2. Gone
			assert ("gone", not hover_shots [2] [8].has_substring ("Show line") and hover_shots [2] [15].has_substring ("Hovered: none"))
				-- 3. Spell check's above it, rows 10 .. 12
			assert_shot ("spell check", hover_shots [3], 2, 10, <<
				tl + h (24) + tr,
				v + "Underline unknown words." + v,
				bl + h (24) + br>>)
				-- 4. Dismissed by the click, which toggled the box
			assert ("dismissed", not hover_shots [4] [12].has_substring ("Underline"))
			assert ("toggled", l_app.checked [4])
			assert ("motion on once", occurrences (l_sink, "%/27/[?1006h%/27/[?1003h") = 1)
			assert ("motion off once", occurrences (l_sink, "%/27/[?1006l%/27/[?1003l%/27/[?1002l%/27/[?1000l") = 1)
		end

feature {NONE} -- Hover script

	hover_step: INTEGER
			-- Steps scripted so far

	hover_frames: INTEGER
			-- Frames drawn so far

	Hover_frame_cap: INTEGER = 5000
			-- Frames after which the test stops instead of hanging

	hover_shots: ARRAYED_LIST [ARRAYED_LIST [STRING_32]]
			-- Rows of the frame that showed each step's result
		attribute
			create Result.make (4)
		end

	hover_frame (a_frame: FRAME; a_app: TOOLTIPS_SNAPSHOT_APP; a_driver: FAKE_CONSOLE_DRIVER)
			-- Script the next step once the frame shows the previous one's result.
			-- SGR positions are 1-based screen cells: frame (c, r) is (c + 11; r + 4).
		do
			hover_frames := hover_frames + 1
			if hover_frames >= Hover_frame_cap then
				a_app.stop
			else
				inspect hover_step
				when 0 then
					hover_step := 1
					a_driver.script (motion (4, 5))
				when 1 then
					if a_app.shown_index = 2 then
						hover_shots.extend (buffer_as_lines (a_frame.buffer))
						hover_step := 2
						a_driver.script (motion (30, 8))
					end
				when 2 then
					if a_app.hovered_index = 0 and a_app.shown_index = 0 then
						hover_shots.extend (buffer_as_lines (a_frame.buffer))
						hover_step := 3
						a_driver.script (motion (4, 13))
					end
				when 3 then
					if a_app.shown_index = 4 then
						hover_shots.extend (buffer_as_lines (a_frame.buffer))
						hover_step := 4
						a_driver.script (Esc + "[<0;15;17M" + Esc + "[<0;15;17m")
					end
				when 4 then
					if a_app.checked [4] and a_app.shown_index = 0 then
						hover_shots.extend (buffer_as_lines (a_frame.buffer))
						hover_step := 5
						a_driver.script ("q")
					end
				else
					hover_step := 6
				end
			end
		end

	motion (a_column, a_row: INTEGER): STRING_8
			-- SGR motion report with no button at frame (`a_column`, `a_row`) of a viewport at
			-- screen (10, 3)
		do
			Result := Esc + "[<35;" + (a_column + 11).out + ";" + (a_row + 4).out + "M"
		end

	Esc: STRING_8 = "%/27/"
			-- The escape character

feature {NONE} -- Helpers

	new_snapshot_app: TOOLTIPS_SNAPSHOT_APP
			-- The example on a fake console, not running.
		local
			l_backend: ANSI_TERMINAL_BACKEND
		do
			create l_backend.make_with_driver_and_sink (create {FAKE_CONSOLE_DRIVER}, create {STRING_32}.make_empty)
			create Result.make_on (create {TERMINAL [ANSI_TERMINAL_BACKEND]}.make_with_viewport (l_backend, create {VIEWPORT}.make_fullscreen))
		end

	example_frame (a_app: TOOLTIPS_SNAPSHOT_APP): BUFFER
			-- A 60 x 16 frame drawn by `a_app`
		do
			create Result.make (60, 16)
			a_app.render_now (create {FRAME}.make (Result))
		end

	f1: KEY_EVENT
			-- Press of F1
		do
			create Result.make (create {KEY_CODE}.make_function (1), create {MODIFIERS})
		end

	id (a_value: INTEGER): WIDGET_ID
			-- Widget id `a_value`
		do
			create Result.make (a_value)
		end

	assert_rect (a_tag: STRING; a_rect: RECT; a_x, a_y, a_width, a_height: INTEGER)
			-- `a_rect` is (`a_x`, `a_y`, `a_width`, `a_height`).
		do
			assert (a_tag + " is " + a_rect.x.out + "," + a_rect.y.out + " " + a_rect.width.out + "x" + a_rect.height.out,
				a_rect.x = a_x and a_rect.y = a_y and a_rect.width = a_width and a_rect.height = a_height)
		end

	assert_rows_at (a_tag: STRING; a_buf: BUFFER; a_x, a_y: INTEGER; a_rows: ARRAY [READABLE_STRING_GENERAL])
			-- Rows `a_y` .. of `a_buf`, from column `a_x`, read `a_rows`.
		do
			assert_shot (a_tag, buffer_as_lines (a_buf), a_x, a_y, a_rows)
		end

	assert_shot (a_tag: STRING; a_lines: ARRAYED_LIST [STRING_32]; a_x, a_y: INTEGER; a_rows: ARRAY [READABLE_STRING_GENERAL])
			-- Rows `a_y` .. of `a_lines` (0-based), from column `a_x`, read `a_rows`.
		local
			i: INTEGER
			l_actual: STRING_32
		do
			from i := 1 until i > a_rows.count loop
				l_actual := a_lines [a_y + i].substring (a_x + 1, a_x + a_rows [i].count)
				assert (a_tag + " row " + (a_y + i - 1).out + ": " + printable (l_actual), l_actual.same_string_general (a_rows [i]))
				i := i + 1
			end
		end

	assert_grid (a_tag: STRING; a_buf: BUFFER; a_grid: LIST [STRING_32])
			-- `a_buf` reads `a_grid`, row for row.
		local
			r: INTEGER
		do
			from r := 1 until r > a_grid.count loop
				assert (a_tag + " row " + (r - 1).out + ": " + printable (buffer_row_as_string (a_buf, r - 1)),
					buffer_row_as_string (a_buf, r - 1).same_string (a_grid [r]))
				r := r + 1
			end
		end

	h (a_count: INTEGER): STRING_32
			-- `a_count` plain horizontal line glyphs
		do
			create Result.make_filled ((0x2500).to_character_32, a_count)
		end

	v: STRING_32
			-- Plain vertical line glyph
		do
			Result := {STRING_32} "%/0x2502/"
		end

	tl: STRING_32 do Result := {STRING_32} "%/0x250C/" end
	tr: STRING_32 do Result := {STRING_32} "%/0x2510/" end
	bl: STRING_32 do Result := {STRING_32} "%/0x2514/" end
	br: STRING_32 do Result := {STRING_32} "%/0x2518/" end

	dots (a_width, a_height: INTEGER): ARRAYED_LIST [STRING_32]
			-- `a_height` rows of `a_width` dots
		local
			r: INTEGER
		do
			create Result.make (a_height)
			from r := 1 until r > a_height loop
				Result.extend (create {STRING_32}.make_filled ('.', a_width))
				r := r + 1
			end
		end

	put_box (a_grid: ARRAYED_LIST [STRING_32]; a_x, a_y, a_inside: INTEGER; a_lines: ARRAY [READABLE_STRING_GENERAL])
			-- Draw in `a_grid` a plain box at (`a_x`, `a_y`), `a_inside` columns inside, holding
			-- `a_lines` left-aligned (one-column characters).
		local
			k: INTEGER
			l_row: STRING_32
		do
			a_grid [a_y + 1].replace_substring (tl + h (a_inside) + tr, a_x + 1, a_x + a_inside + 2)
			from k := 1 until k > a_lines.count loop
				create l_row.make_from_string_general (a_lines [k])
				from until l_row.count >= a_inside loop
					l_row.append_character (' ')
				end
				a_grid [a_y + 1 + k].replace_substring (v + l_row + v, a_x + 1, a_x + a_inside + 2)
				k := k + 1
			end
			a_grid [a_y + a_lines.count + 2].replace_substring (bl + h (a_inside) + br, a_x + 1, a_x + a_inside + 2)
		end

	dotted_buffer (a_width, a_height: INTEGER): BUFFER
			-- A buffer filled with dots
		local
			r: INTEGER
		do
			create Result.make (a_width, a_height)
			from r := 0 until r >= a_height loop
				Result.put_string (r, 0, create {STRING_32}.make_filled ('.', a_width), create {STYLE})
				r := r + 1
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
