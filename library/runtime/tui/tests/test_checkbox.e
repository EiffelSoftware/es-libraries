note
	description: "[
		P2 item W2, the TUI_CHECKBOX widget (review/p2_terminal_widgets_plan.md).
		Ratatui has no checkbox widget, so these are EiffelTUI's own row-exact buffer snapshots:
		unchecked and checked, focused, a wide-character label at the clipping edge, the ASCII,
		Unicode (U+2611 / U+2610) and radio ("(" U+2022 ")") symbols, styles, the `with_*`
		builders; the hit region (symbol and label) with `hit_test` in a fixed viewport; and
		Space or a click toggling the application's boolean, with FOCUS_MANAGER choosing the
		box, as the class note of TUI_CHECKBOX shows.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_CHECKBOX

inherit
	BUFFER_TEST_HELPER

feature -- Snapshots

	test_checkbox_unchecked_and_checked
			-- The symbol, one blank and the label on the top row; the other rows untouched. An
			-- empty label has no blank. `width` is what the symbol and the label take.
		local
			l_buf: BUFFER
			l_box: TUI_CHECKBOX
		do
			create l_box.make ("Wrap")
			create l_buf.make (10, 2)
			l_box.render (create {RECT}.make (0, 0, 10, 2), l_buf)
			assert_buffer_lines ("unchecked", l_buf, <<"[ ] Wrap  ", "          ">>)
			create l_buf.make (10, 2)
			l_box.with_checked (True).render (create {RECT}.make (1, 1, 9, 1), l_buf)
			assert_buffer_lines ("checked", l_buf, <<"          ", " [x] Wrap ">>)
			assert ("width", l_box.width = 8)
			assert ("symbol", l_box.symbol.same_string_general ("[ ]") and l_box.with_checked (True).symbol.same_string_general ("[x]"))
			create l_buf.make (6, 1)
			(create {TUI_CHECKBOX}).with_checked (True).render (create {RECT}.make (0, 0, 6, 1), l_buf)
			assert_buffer_lines ("no label", l_buf, <<"[x]   ">>)
			assert ("no label width", (create {TUI_CHECKBOX}).width = 3)
				-- The blank before the label is drawn over what was there
			create l_buf.make (6, 1)
			l_buf.put_string (0, 0, "######", create {STYLE})
			(create {TUI_CHECKBOX}.make ("ab")).render (create {RECT}.make (0, 0, 6, 1), l_buf)
			assert_buffer_lines ("over text", l_buf, <<"[ ] ab">>)
		end

	test_checkbox_focused
			-- Focused: `focused_style` (reversed by default) is patched over `style` and over
			-- `content_area` only (the symbol, the blank and the label); the rest of the area,
			-- after the label and in the rows below, is left as it is. Not focused, the box
			-- gets `style` only.
		local
			l_buf: BUFFER
			l_box: TUI_CHECKBOX
			l_reverse, l_red: STYLE
		do
			l_reverse := (create {STYLE}).with_reverse
			create l_red.make_fg ({COLOR}.Red)
			l_box := (create {TUI_CHECKBOX}.make ("Wrap")).with_checked (True)
			create l_buf.make (12, 2)
			l_box.with_focused (True).render (create {RECT}.make (0, 0, 10, 2), l_buf)
			assert_buffer_lines ("focused", l_buf, <<"[x] Wrap    ", "            ">>)
			assert_cell_style ("symbol reversed", l_buf, 0, 0, l_reverse)
			assert_cell_style ("blank reversed", l_buf, 0, 3, l_reverse)
			assert_cell_style ("label reversed", l_buf, 0, 4, l_reverse)
			assert_cell_style ("label end reversed", l_buf, 0, 7, l_reverse)
			assert_cell_style ("rest of the row untouched", l_buf, 0, 8, create {STYLE})
			assert_cell_style ("rest of area untouched", l_buf, 0, 9, create {STYLE})
			assert_cell_style ("outside area", l_buf, 0, 10, create {STYLE})
			assert_cell_style ("row below untouched", l_buf, 1, 0, create {STYLE})
			assert ("content area", l_box.content_area (create {RECT}.make (0, 0, 10, 2)) ~ create {RECT}.make (0, 0, 8, 1))
			assert ("content area cut", l_box.content_area (create {RECT}.make (2, 1, 5, 3)) ~ create {RECT}.make (2, 1, 5, 1))
			assert ("content area empty", l_box.content_area (create {RECT}.make (2, 1, 0, 3)).is_empty)
				-- Not focused: the default style, no reverse
			create l_buf.make (12, 1)
			l_box.render (create {RECT}.make (0, 0, 10, 1), l_buf)
			assert_buffer_lines ("not focused", l_buf, <<"[x] Wrap    ">>)
			assert_cell_style ("plain", l_buf, 0, 0, create {STYLE})
				-- Own styles: the focused style is patched over `style`
			create l_buf.make (12, 1)
			l_box.with_style (l_red).with_focused_style (create {STYLE}.make_bg ({COLOR}.Blue)).with_focused (True)
				.render (create {RECT}.make (0, 0, 10, 1), l_buf)
			assert_cell_style ("red on blue", l_buf, 0, 1, create {STYLE}.make_with_colors ({COLOR}.Red, {COLOR}.Blue))
			assert ("effective style", l_box.with_style (l_red).effective_style.is_equal (l_red))
			create l_buf.make (12, 1)
			l_box.with_style (l_red).render (create {RECT}.make (0, 0, 10, 1), l_buf)
			assert_cell_style ("red unfocused", l_buf, 0, 5, l_red)
		end

	test_checkbox_wide_label_at_clipping_edge
			-- A wide character in the label that would cross the area's right edge is left
			-- out (with the rest of the label), its cell blank; one that ends on the edge is
			-- drawn. The symbol and the blank are clipped too. An area running past the
			-- buffer is cut to it. Every row stays continuation-consistent.
		local
			l_box: TUI_CHECKBOX
			l_w: STRING_32
			l_buf: BUFFER
		do
			l_w := {STRING_32} "%/0x4E16/"
			create l_box.make ({STRING_32} "a" + l_w + "b")
			assert ("wide width", l_box.width = 3 + 1 + 4)
			check_render ("whole", l_box, 8, {STRING_32} "[ ] a" + l_w + "b")
			check_render ("wide ends on the edge", l_box, 7, {STRING_32} "[ ] a" + l_w)
			check_render ("wide crosses the edge", l_box, 6, {STRING_32} "[ ] a ")
			check_render ("only the blank", l_box, 4, {STRING_32} "[ ] ")
			check_render ("only the symbol", l_box, 3, {STRING_32} "[ ]")
			check_render ("symbol cut", l_box, 2, {STRING_32} "[ ")
			check_render ("one cell", l_box, 1, {STRING_32} "[")
				-- A label starting with a wide character, cut right after the blank
			check_render ("wide first", (create {TUI_CHECKBOX}.make (l_w + "x")).with_checked (True), 5, {STRING_32} "[x]  ")
				-- Area past the buffer
			create l_buf.make (7, 1)
			l_box.with_focused (True).render (create {RECT}.make (0, 0, 40, 3), l_buf)
			assert_buffer_lines ("cut by the buffer", l_buf, <<{STRING_32} "[ ] a" + l_w>>)
			assert ("cut consistent", l_buf.is_consistent)
				-- Over wide characters already in the buffer
			create l_buf.make (10, 1)
			l_buf.put_string (0, 0, l_w + l_w + l_w + l_w + l_w, create {STYLE})
			(create {TUI_CHECKBOX}.make ("ab")).render (create {RECT}.make (1, 0, 6, 1), l_buf)
			assert_buffer_lines ("over wide", l_buf, <<{STRING_32} " [ ] ab " + l_w>>)
			assert ("over wide consistent", l_buf.is_consistent)
		end

	test_checkbox_symbol_presets
			-- ASCII by default; the Unicode preset U+2611 / U+2610 and the radio symbols, each
			-- one or three columns; any pair with `with_symbols`.
		local
			l_box: TUI_CHECKBOX
		do
			create l_box.make ("Wrap")
			check_render ("ascii unchecked", l_box, 8, "[ ] Wrap")
			check_render ("ascii checked", l_box.with_checked (True), 8, "[x] Wrap")
			l_box := l_box.with_unicode_symbols
			check_render ("unicode unchecked", l_box, 8, {STRING_32} "%/0x2610/ Wrap  ")
			check_render ("unicode checked", l_box.with_checked (True), 8, {STRING_32} "%/0x2611/ Wrap  ")
			assert ("unicode width", l_box.width = 6 and l_box.with_checked (True).width = 6)
			assert ("back to ascii", l_box.with_ascii_symbols ~ (create {TUI_CHECKBOX}.make ("Wrap")))
			l_box := l_box.with_symbols ({CHECKBOX_SYMBOLS}.radio_selected, {CHECKBOX_SYMBOLS}.radio_unselected)
			check_render ("radio unselected", l_box, 8, "( ) Wrap")
			check_render ("radio selected", l_box.with_checked (True), 8, {STRING_32} "(%/0x2022/) Wrap")
			l_box := l_box.with_checked_symbol ("<on>").with_unchecked_symbol ("-")
			check_render ("own checked", l_box.with_checked (True), 10, "<on> Wrap ")
			check_render ("own unchecked", l_box, 10, "-    Wrap ")
			assert ("own width", l_box.width = 9 and l_box.with_checked (True).width = 9)
		end

	test_checkbox_symbols_checked_and_aligned
			-- Symbols with a control character are refused (setters, builders, the pair); the
			-- label starts after the wider of the two symbols, so it does not move when the box
			-- is ticked: "<on>" / "-" puts the label at column 5 checked or not, the narrower
			-- symbol padded with blanks (in the box's style, inside `content_area`).
		local
			l_box: TUI_CHECKBOX
			l_buf: BUFFER
		do
			assert ("ascii valid", {TUI_CHECKBOX}.is_valid_symbol ("[x]"))
			assert ("unicode valid", {TUI_CHECKBOX}.is_valid_symbol ({CHECKBOX_SYMBOLS}.unicode_checked))
			assert ("empty valid", {TUI_CHECKBOX}.is_valid_symbol (""))
			assert ("tab refused", not {TUI_CHECKBOX}.is_valid_symbol ("[%T]"))
			assert ("newline refused", not {TUI_CHECKBOX}.is_valid_symbol ("[%N]"))
			assert ("escape refused", not {TUI_CHECKBOX}.is_valid_symbol ("%/27/[x]"))
			assert ("DEL refused", not {TUI_CHECKBOX}.is_valid_symbol ("%/127/"))
			assert ("C1 refused", not {TUI_CHECKBOX}.is_valid_symbol ({STRING_32} "%/0x9C/"))
			assert ("U+00A0 valid", {TUI_CHECKBOX}.is_valid_symbol ({STRING_32} "%/0xA0/"))
			create l_box.make ("Wrap")
			assert ("set checked refused", raises (agent l_box.set_checked_symbol ("%/27/x")))
			assert ("set unchecked refused", raises (agent l_box.set_unchecked_symbol ("%N")))
			assert ("pair refused", raises (agent l_box.set_symbols ("[x]", "%T")))
			assert ("builder refused", raises (agent (b: TUI_CHECKBOX) do b.with_checked_symbol ("%/127/").do_nothing end (l_box)))
			assert ("unchanged", l_box ~ create {TUI_CHECKBOX}.make ("Wrap"))
				-- Symbols of different widths: the label stays at the same column
			l_box := l_box.with_symbols ("<on>", "-")
			assert ("symbol width", l_box.symbol_width = 4)
			assert ("width the same checked or not", l_box.width = 9 and l_box.with_checked (True).width = 9)
			check_render ("narrow symbol padded", l_box, 10, "-    Wrap ")
			check_render ("wide symbol", l_box.with_checked (True), 10, "<on> Wrap ")
			create l_buf.make (12, 1)
			l_box.with_focused (True).render (create {RECT}.make (0, 0, 12, 1), l_buf)
			assert_cell_style ("padding highlighted", l_buf, 0, 2, (create {STYLE}).with_reverse)
			assert_cell_style ("after the label untouched", l_buf, 0, 9, create {STYLE})
				-- An empty label: the box is the wider symbol's columns
			check_render ("no label, narrow", (create {TUI_CHECKBOX}).with_symbols ("<on>", "-"), 6, "-     ")
		end

	test_checkbox_patches_cell_style
			-- `style` is patched over the cells, so a background under the box stays; the
			-- label's line and span styles are patched over the base style.
		local
			l_buf: BUFFER
			l_blue: STYLE
		do
			create l_blue.make_bg ({COLOR}.Blue)
			create l_buf.make (10, 1)
			l_buf.set_style (create {RECT}.make (0, 0, 10, 1), l_blue)
			(create {TUI_CHECKBOX}.make_with_line (create {TEXT_LINE}.make (<<
					create {TEXT_SPAN}.make_raw ("a"),
					create {TEXT_SPAN}.make ("b", create {STYLE}.make_fg ({COLOR}.Green))>>)))
				.with_style (create {STYLE}.make_fg ({COLOR}.Red))
				.render (create {RECT}.make (0, 0, 8, 1), l_buf)
			assert_buffer_lines ("drawn", l_buf, <<"[ ] ab    ">>)
			assert_cell_style ("symbol", l_buf, 0, 0, create {STYLE}.make_with_colors ({COLOR}.Red, {COLOR}.Blue))
			assert_cell_style ("blank", l_buf, 0, 3, create {STYLE}.make_with_colors ({COLOR}.Red, {COLOR}.Blue))
			assert_cell_style ("plain span", l_buf, 0, 4, create {STYLE}.make_with_colors ({COLOR}.Red, {COLOR}.Blue))
			assert_cell_style ("green span", l_buf, 0, 5, create {STYLE}.make_with_colors ({COLOR}.Green, {COLOR}.Blue))
			assert_cell_style ("area after label untouched", l_buf, 0, 7, l_blue)
			assert_cell_style ("outside area", l_buf, 0, 8, l_blue)
		end

	test_checkbox_zero_size_areas
			-- Zero-size areas and areas outside the buffer draw nothing.
		local
			l_buf: BUFFER
			l_box: TUI_CHECKBOX
		do
			l_box := (create {TUI_CHECKBOX}.make ("label")).with_focused (True)
			create l_buf.make (4, 2)
			across <<create {RECT}.make (0, 0, 0, 0), create {RECT}.make (1, 1, 0, 1), create {RECT}.make (1, 1, 2, 0),
					create {RECT}.make (4, 0, 2, 2), create {RECT}.make (0, 2, 4, 2), create {RECT}.make (40, 40, 3, 3)>> as a loop
				l_box.render (a, l_buf)
			end
			assert_buffer_lines ("nothing drawn", l_buf, <<"    ", "    ">>)
			assert_cell_style ("no style", l_buf, 0, 0, create {STYLE})
		end

feature -- Builders

	test_checkbox_builders_equality_and_copy
			-- Defaults; each `with_*` sets its attribute on a copy and leaves the original as it
			-- was; `is_equal` compares every attribute; a copy has its own label.
		local
			l_a, l_b, l_c: TUI_CHECKBOX
			l_red: STYLE
			l_line: TEXT_LINE
			l_id: WIDGET_ID
		do
			create l_a
			assert ("empty label", l_a.label.is_empty)
			assert ("unchecked", not l_a.is_checked)
			assert ("not focused", not l_a.is_focused)
			assert ("ascii", l_a.checked_symbol.same_string_general ("[x]") and l_a.unchecked_symbol.same_string_general ("[ ]"))
			assert ("default style", l_a.style.is_equal (create {STYLE}))
			assert ("reversed focus", l_a.focused_style.is_equal ((create {STYLE}).with_reverse))
			assert ("no hit id", l_a.hit_id = Void)
			assert ("make", (create {TUI_CHECKBOX}.make ("x")).label.to_plain_string.same_string_general ("x"))
			assert ("default equal", l_a ~ (create {TUI_CHECKBOX}))

			create l_red.make_fg ({COLOR}.Red)
			create l_id.make (4)
			assert ("checked", l_a.with_checked (True).is_checked and not (l_a ~ l_a.with_checked (True)))
			assert ("focused", l_a.with_focused (True).is_focused and not (l_a ~ l_a.with_focused (True)))
			assert ("style", l_a.with_style (l_red).style = l_red and not (l_a ~ l_a.with_style (l_red)))
			assert ("equal styles", l_a.with_style (l_red) ~ l_a.with_style (create {STYLE}.make_fg ({COLOR}.Red)))
			assert ("focused style", l_a.with_focused_style (l_red).focused_style = l_red and not (l_a ~ l_a.with_focused_style (l_red)))
			assert ("checked symbol", not (l_a ~ l_a.with_checked_symbol ("v")))
			assert ("unchecked symbol", not (l_a ~ l_a.with_unchecked_symbol ("o")))
			assert ("unicode", not (l_a ~ l_a.with_unicode_symbols))
			assert ("hit id", l_a.with_hit_id (l_id).hit_id = l_id and not (l_a ~ l_a.with_hit_id (l_id)))
			assert ("equal hit ids", l_a.with_hit_id (l_id) ~ l_a.with_hit_id (create {WIDGET_ID}.make (4)))
			assert ("original kept", l_a ~ (create {TUI_CHECKBOX}) and l_a.hit_id = Void)

			l_b := l_a.with_label ("x")
			assert ("label set", l_b.label.width = 1)
			assert ("label differs", not (l_a ~ l_b))
			assert ("equal labels", l_b ~ l_a.with_label ("x"))
			create l_line.make_raw ("z")
			assert ("label line", l_a.with_label_line (l_line).label = l_line)
			assert ("make_with_line", (create {TUI_CHECKBOX}.make_with_line (l_line)).label = l_line)

				-- A copy has its own label
			l_c := l_b.twin
			assert ("twin equal", l_c ~ l_b)
			l_c.label.append_span (create {TEXT_SPAN}.make_raw ("more"))
			assert ("original label kept", l_b.label.width = 1)
			l_c := l_b.with_checked (True)
			l_c.label.append_span (create {TEXT_SPAN}.make_raw ("more"))
			assert ("builder copy has its own label", l_b.label.width = 1)
				-- The presets are new strings each time
			assert ("fresh presets", {CHECKBOX_SYMBOLS}.unicode_checked /= {CHECKBOX_SYMBOLS}.unicode_checked)
			assert ("one-column presets", {UNICODE_WIDTH}.string_width ({CHECKBOX_SYMBOLS}.unicode_checked) = 1
				and {UNICODE_WIDTH}.string_width ({CHECKBOX_SYMBOLS}.unicode_unchecked) = 1
				and {UNICODE_WIDTH}.string_width ({CHECKBOX_SYMBOLS}.radio_selected) = 3)
		end

feature -- Hit region and input

	test_checkbox_registers_its_hit_region
			-- With a `hit_id`, FRAME.render_widget registers the area: the symbol and the label
			-- hit the box; without one, nothing is registered.
		local
			l_frame: FRAME
			l_id: WIDGET_ID
			l_box: TUI_CHECKBOX
		do
			create l_frame.make (create {BUFFER}.make (20, 3))
			create l_id.make (5)
			create l_box.make ("Wrap")
			l_frame.render_widget (l_box, create {RECT}.make (2, 0, l_box.width.to_natural_16, 1))
			assert ("no id, no region", l_frame.hit_map.is_empty)
			l_frame.render_widget (l_box.with_hit_id (l_id), create {RECT}.make (2, 1, l_box.width.to_natural_16, 1))
			assert ("symbol hit", attached l_frame.hit_map.hit (2, 1) as id and then id ~ l_id)
			assert ("blank hit", attached l_frame.hit_map.hit (5, 1) as id and then id ~ l_id)
			assert ("label end hit", attached l_frame.hit_map.hit (9, 1) as id and then id ~ l_id)
			assert ("left of the box", l_frame.hit_map.hit (1, 1) = Void)
			assert ("right of the label", l_frame.hit_map.hit (10, 1) = Void)
			assert ("row below", l_frame.hit_map.hit (2, 2) = Void)
			assert ("with_hit_id copies", l_box.hit_id = Void)
				-- Given a whole layout row (and a second row), only the box and its label are
				-- registered: a click beside the label or below it misses
			create l_frame.make (create {BUFFER}.make (20, 3))
			l_frame.render_widget (l_box.with_hit_id (l_id), create {RECT}.make (2, 1, 18, 2))
			assert ("wide area: symbol hit", attached l_frame.hit_map.hit (2, 1) as id and then id ~ l_id)
			assert ("wide area: label end hit", attached l_frame.hit_map.hit (9, 1) as id and then id ~ l_id)
			assert ("wide area: beside the label", l_frame.hit_map.hit (10, 1) = Void)
			assert ("wide area: end of the row", l_frame.hit_map.hit (19, 1) = Void)
			assert ("wide area: second row", l_frame.hit_map.hit (2, 2) = Void)
			assert ("hit area is the content", l_box.hit_area (create {RECT}.make (2, 1, 18, 2), Void)
				~ create {RECT}.make (2, 1, 8, 1))
		end

	test_checkbox_hit_test_fixed_viewport
			-- A fixed viewport at screen column 10, row 3, as `test_hit_test_fixed_viewport`. The
			-- box "[ ] Wrap" at frame (2, 1), `width` columns wide, is at screen columns 12..19
			-- of row 4: a click on its symbol and one on the last cell of its label hit it; one
			-- right of the label, and one at the frame position on screen, miss.
		local
			l_app: TEST_TUI_APP_IMPL
			l_hits: ARRAYED_LIST [detachable WIDGET_ID]
		do
			create l_hits.make (4)
				-- Presses at screen (12, 4), (19, 4), (20, 4) and (2, 1); SGR is 1-based
			l_app := new_app (Esc + "[<0;13;5M" + Esc + "[<0;20;5M" + Esc + "[<0;21;5M" + Esc + "[<0;3;2M" + "q",
				create {VIEWPORT}.make_fixed (create {RECT}.make (10, 3, 20, 5)))
			l_app.set_draw_hook (agent (f: FRAME)
				local
					b: TUI_CHECKBOX
				do
					create b.make ("Wrap")
					f.render_widget (b.with_hit_id (Box_id), create {RECT}.make (2, 1, b.width.to_natural_16, 1))
				end)
			l_app.set_mouse_hook (agent (m: MOUSE_EVENT; a: TEST_TUI_APP_IMPL; l: ARRAYED_LIST [detachable WIDGET_ID])
				do
					if m.is_down then
						l.extend (a.hit_test (m))
					end
				end (?, l_app, l_hits))
			l_app.run
			assert ("four presses", l_hits.count = 4)
			assert ("symbol", attached l_hits [1] as id and then id ~ Box_id)
			assert ("label end", attached l_hits [2] as id and then id ~ Box_id)
			assert ("right of the label", l_hits [3] = Void)
			assert ("frame position on screen misses", l_hits [4] = Void)
		end

	test_checkbox_toggled_by_space_and_click
			-- The application owns two booleans; FOCUS_MANAGER chooses the box. Space toggles
			-- the focused box; a click focuses the box under it (`hit_test`, `focus_at`) and
			-- toggles it; a click beside the boxes does nothing. The rows checked are those of
			-- the running application's own frame: the draw hook stops the application only
			-- after a frame drawn once all six events were handled, so that frame shows the final
			-- state (no 'q': it could be handled before that frame is drawn).
		local
			l_app: TEST_TUI_APP_IMPL
		do
			create toggle_focus.make
			toggle_ids := <<create {WIDGET_ID}.make (1), create {WIDGET_ID}.make (2)>>
			toggle_values := <<False, False>>
			toggle_focus.register (toggle_ids [1])
			toggle_focus.register (toggle_ids [2])
				-- Fixed viewport at screen (10, 3). Box 1 "[ ] Wrap" at frame (2, 1), box 2
				-- "[ ] Bold" at frame (2, 2). Space (box 1), click on the end of box 2's label
				-- (screen 19, 5), click right of it (20, 5), Space (box 2), click on box 1's
				-- symbol (12, 4), Space (box 1)
			l_app := new_app (" " + Esc + "[<0;20;6M" + Esc + "[<0;21;6M" + " " + Esc + "[<0;13;5M" + " ",
				create {VIEWPORT}.make_fixed (create {RECT}.make (10, 3, 20, 5)))
			last_toggle_rows := Void
			is_final_toggle_frame_drawn := False
			l_app.set_draw_hook (agent draw_toggles_and_stop (?, l_app))
			l_app.set_mouse_hook (agent (m: MOUSE_EVENT; a: TEST_TUI_APP_IMPL)
				local
					i: INTEGER
				do
					if m.is_down and then toggle_focus.focus_at (a.hit_test (m)) then
						toggle_log.extend ("click")
						from i := 1 until i > 2 loop
							if toggle_focus.is_focused (toggle_ids [i]) then
								toggle_values [i] := not toggle_values [i]
							end
							i := i + 1
						end
					elseif m.is_down then
						toggle_log.extend ("miss")
					end
				end (?, l_app))
			l_app.set_key_hook (agent (k: KEY_EVENT)
				local
					i: INTEGER
				do
					if k.is_press and then k.code.is_char and then k.code.character = ' ' then
						toggle_log.extend ("space")
						from i := 1 until i > 2 loop
							if toggle_focus.is_focused (toggle_ids [i]) then
								toggle_values [i] := not toggle_values [i]
							end
							i := i + 1
						end
					end
				end)
			l_app.run
			assert ("events in order", toggle_log.count = 6
				and toggle_log [1] ~ "space" and toggle_log [2] ~ "click" and toggle_log [3] ~ "miss"
				and toggle_log [4] ~ "space" and toggle_log [5] ~ "click" and toggle_log [6] ~ "space")
			assert ("box 1 checked", toggle_values [1])
			assert ("box 2 unchecked", not toggle_values [2])
			assert ("box 1 focused", toggle_focus.is_focused (toggle_ids [1]))
			assert ("the application drew the final state", is_final_toggle_frame_drawn)
			assert ("final frame rows", attached last_toggle_rows as r
				and then r [1].same_string_general ("  [x] Wrap          ")
				and then r [2].same_string_general ("  [ ] Bold          "))
			assert ("box 1 reversed in the final frame", last_toggle_focus_reversed)
		end

feature {NONE} -- Toggle support

	toggle_focus: FOCUS_MANAGER
			-- Focus ring of `test_checkbox_toggled_by_space_and_click`
		attribute
			create Result.make
		end

	toggle_ids: ARRAY [WIDGET_ID]
			-- Ids of the two boxes
		attribute
			Result := <<>>
		end

	toggle_values: ARRAY [BOOLEAN]
			-- The application's booleans
		attribute
			Result := <<>>
		end

	toggle_log: ARRAYED_LIST [STRING]
			-- Events that reached the hooks: "space", "click" (on a box) or "miss"
		attribute
			create Result.make (6)
		end

	last_toggle_rows: detachable ARRAYED_LIST [STRING_32]
			-- Rows 1 and 2 of the last frame draw_toggles drew

	last_toggle_focus_reversed: BOOLEAN
			-- Was the focused box drawn reversed, and the other one not, by the last draw_toggles?

	is_final_toggle_frame_drawn: BOOLEAN
			-- Did the application draw a frame after all six events were handled?

	draw_toggles_and_stop (a_frame: FRAME; a_app: TEST_TUI_APP_IMPL)
			-- `draw_toggles` as the application's draw hook; once all six events were handled
			-- before this frame, record that it shows the final state and stop. Stop anyway
			-- after 2000 frames, so that a lost event fails the test instead of hanging it.
		do
			draw_toggles (a_frame)
			if toggle_log.count = 6 then
				is_final_toggle_frame_drawn := True
				a_app.stop
			elseif a_app.draw_pass_count > 2000 then
				a_app.stop
			end
		end

	draw_toggles (a_frame: FRAME)
			-- Draw both boxes from the application's booleans, each `width` columns wide.
		local
			l_box: TUI_CHECKBOX
			l_rows: ARRAYED_LIST [STRING_32]
			i: INTEGER
		do
			from i := 1 until i > 2 loop
				if i = 1 then
					create l_box.make ("Wrap")
				else
					create l_box.make ("Bold")
				end
				l_box := l_box.with_checked (toggle_values [i]).with_focused (toggle_focus.is_focused (toggle_ids [i]))
					.with_hit_id (toggle_ids [i])
				a_frame.render_widget (l_box, create {RECT}.make (2, i.to_natural_16, l_box.width.to_natural_16, 1))
				i := i + 1
			end
			create l_rows.make (2)
			l_rows.extend (buffer_row_as_string (a_frame.buffer, 1))
			l_rows.extend (buffer_row_as_string (a_frame.buffer, 2))
			last_toggle_rows := l_rows
			last_toggle_focus_reversed := a_frame.buffer.cell (1, 2).style.is_equal ((create {STYLE}).with_reverse)
				and a_frame.buffer.cell (2, 2).style.is_equal (create {STYLE})
		end

feature {NONE} -- Helpers

	raises (a_action: PROCEDURE): BOOLEAN
			-- Does `a_action` raise an exception?
		local
			l_tried: BOOLEAN
		do
			if not l_tried then
				a_action.call
			end
		rescue
			l_tried := True
			Result := True
			retry
		end


	Box_id: WIDGET_ID
			-- Id of the box in `test_checkbox_hit_test_fixed_viewport`
		once
			create Result.make (9)
		end

	check_render (a_tag: STRING; a_box: TUI_CHECKBOX; a_width: INTEGER; a_expected: STRING_32)
			-- `a_box` rendered into an area `a_width` columns wide, in a 1-row buffer two
			-- columns wider, gives `a_expected` and two untouched columns.
		local
			l_buf: BUFFER
		do
			create l_buf.make (a_width + 2, 1)
			a_box.render (create {RECT}.make (0, 0, a_width.to_natural_16, 1), l_buf)
			assert_buffer_lines (a_tag, l_buf, <<a_expected + "  ">>)
			assert (a_tag + " consistent", l_buf.is_consistent)
		end

	new_app (a_input: READABLE_STRING_8; a_viewport: VIEWPORT): TEST_TUI_APP_IMPL
			-- Application on a fake console replaying `a_input`, output captured.
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_sink: STRING_32
			l_backend: ANSI_TERMINAL_BACKEND
		do
			create l_driver
			l_driver.script (a_input)
			create l_sink.make_empty
			l_driver.watch_sink (l_sink)
			create l_backend.make_with_driver_and_sink (l_driver, l_sink)
			create Result.make_with_terminal (create {TERMINAL [ANSI_TERMINAL_BACKEND]}.make_with_viewport (l_backend, a_viewport))
			Result.event_thread.set_poll_interval (5)
		end

	Esc: STRING_8 = "%/27/"
			-- ESC, for scripted input

end
