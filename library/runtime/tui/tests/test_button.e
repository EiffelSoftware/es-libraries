note
	description: "[
		P2b item U1, the TUI_BUTTON widget (review/p2b_clipboard_dialog_breadcrumb_plan.md).
		Ratatui has no button widget, so these are EiffelTUI's own row-exact buffer snapshots:
		the plain, focused and pressed looks (the style patched over the whole area); centre,
		left and right alignment; an area narrower than the content, clipped at a grapheme
		cluster boundary with wide characters; an area of height 3 (the middle row); `width`
		with and without brackets; the `with_*` builders; and the hit region (the whole area)
		registered through FRAME.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_BUTTON

inherit
	BUFFER_TEST_HELPER

feature -- Snapshots

	test_button_plain_focused_pressed
			-- "[ OK ]" centred on the row. Plain: `style` (default) over the whole area. Focused:
			-- reversed over the whole area, the cells beside the label too, and nothing outside
			-- it. Pressed: reversed and bold, focused or not. Own styles are patched in order:
			-- `style`, `focused_style`, `pressed_style`.
		local
			l_buf: BUFFER
			l_button: TUI_BUTTON
			l_reverse, l_pressed, l_red: STYLE
		do
			l_reverse := (create {STYLE}).with_reverse
			l_pressed := (create {STYLE}).with_reverse.with_bold
			create l_red.make_fg ({COLOR}.Red)
			create l_button.make ("OK")
				-- Plain
			create l_buf.make (12, 1)
			l_button.render (create {RECT}.make (1, 0, 10, 1), l_buf)
			assert_buffer_lines ("plain", l_buf, <<"   [ OK ]   ">>)
			assert_cell_style ("plain label", l_buf, 0, 5, create {STYLE})
			assert_cell_style ("plain beside", l_buf, 0, 1, create {STYLE})
				-- Focused
			create l_buf.make (12, 1)
			l_button.with_focused (True).render (create {RECT}.make (1, 0, 10, 1), l_buf)
			assert_buffer_lines ("focused", l_buf, <<"   [ OK ]   ">>)
			assert_cell_style ("focused first cell", l_buf, 0, 1, l_reverse)
			assert_cell_style ("focused bracket", l_buf, 0, 3, l_reverse)
			assert_cell_style ("focused label", l_buf, 0, 5, l_reverse)
			assert_cell_style ("focused last cell", l_buf, 0, 10, l_reverse)
			assert_cell_style ("left of the area", l_buf, 0, 0, create {STYLE})
			assert_cell_style ("right of the area", l_buf, 0, 11, create {STYLE})
				-- Pressed, with and without focus
			create l_buf.make (12, 1)
			l_button.with_pressed (True).render (create {RECT}.make (1, 0, 10, 1), l_buf)
			assert_buffer_lines ("pressed", l_buf, <<"   [ OK ]   ">>)
			assert_cell_style ("pressed first cell", l_buf, 0, 1, l_pressed)
			assert_cell_style ("pressed label", l_buf, 0, 5, l_pressed)
			assert_cell_style ("pressed outside", l_buf, 0, 11, create {STYLE})
			create l_buf.make (12, 1)
			l_button.with_focused (True).with_pressed (True).render (create {RECT}.make (1, 0, 10, 1), l_buf)
			assert_cell_style ("pressed and focused", l_buf, 0, 5, l_pressed)
				-- Own styles
			l_button := l_button.with_style (l_red).with_focused_style (create {STYLE}.make_bg ({COLOR}.Blue))
				.with_pressed_style (create {STYLE}.make_fg ({COLOR}.Green))
			create l_buf.make (12, 1)
			l_button.render (create {RECT}.make (1, 0, 10, 1), l_buf)
			assert_cell_style ("red", l_buf, 0, 1, l_red)
			create l_buf.make (12, 1)
			l_button.with_focused (True).render (create {RECT}.make (1, 0, 10, 1), l_buf)
			assert_cell_style ("red on blue", l_buf, 0, 5, create {STYLE}.make_with_colors ({COLOR}.Red, {COLOR}.Blue))
			create l_buf.make (12, 1)
			l_button.with_focused (True).with_pressed (True).render (create {RECT}.make (1, 0, 10, 1), l_buf)
			assert_cell_style ("green on blue", l_buf, 0, 5, create {STYLE}.make_with_colors ({COLOR}.Green, {COLOR}.Blue))
			assert ("effective style plain", l_button.effective_style = l_button.style)
				-- A styled label line is patched over the button's style
			create l_buf.make (8, 1)
			(create {TUI_BUTTON}.make_with_line (create {TEXT_LINE}.make_styled ("ab", create {STYLE}.make_bg ({COLOR}.Blue))))
				.with_focused (True).render (create {RECT}.make (0, 0, 8, 1), l_buf)
			assert_buffer_lines ("line label", l_buf, <<" [ ab ] ">>)
			assert_cell_style ("bracket reversed", l_buf, 0, 1, l_reverse)
			assert_cell_style ("label on blue", l_buf, 0, 3, (create {STYLE}.make_bg ({COLOR}.Blue)).with_reverse)
		end

	test_button_alignments
			-- Centre (the default) at `width // 2 - content // 2`, as Ratatui's paragraph
			-- centres, so "[ Yes ]" (7) in 14 columns starts at 4; left at the left edge; right
			-- ending on the right edge. Content as wide as the area fills it whatever the
			-- alignment.
		local
			l_button: TUI_BUTTON
		do
			create l_button.make ("OK")
			check_render ("centre", l_button, 10, "  [ OK ]  ")
			check_render ("centre odd", l_button, 9, " [ OK ]  ")
			check_render ("left", l_button.with_alignment ({TEXT_ALIGNMENT}.left), 10, "[ OK ]    ")
			check_render ("right", l_button.with_alignment ({TEXT_ALIGNMENT}.right), 10, "    [ OK ]")
			check_render ("right odd", l_button.with_alignment ({TEXT_ALIGNMENT}.right), 9, "   [ OK ]")
			check_render ("yes in 14", create {TUI_BUTTON}.make ("Yes"), 14, "    [ Yes ]   ")
			check_render ("exact centre", l_button, 6, "[ OK ]")
			check_render ("exact right", l_button.with_alignment ({TEXT_ALIGNMENT}.right), 6, "[ OK ]")
			assert ("offset centre", l_button.content_offset (10) = 2)
			assert ("offset left", l_button.with_alignment ({TEXT_ALIGNMENT}.left).content_offset (10) = 0)
			assert ("offset right", l_button.with_alignment ({TEXT_ALIGNMENT}.right).content_offset (10) = 4)
			assert ("offset too narrow", l_button.with_alignment ({TEXT_ALIGNMENT}.right).content_offset (3) = 0)
				-- The label line's own alignment is not used
			check_render ("line alignment ignored",
				create {TUI_BUTTON}.make_with_line ((create {TEXT_LINE}.make_raw ("OK")).right_aligned), 10, "  [ OK ]  ")
		end

	test_button_clipped_at_cluster_boundary
			-- Content wider than the area starts at the left edge (any alignment) and is cut at
			-- the right edge per grapheme cluster: a wide character that would cross it is left
			-- out with the rest, its cell keeps what it had; one that ends on the edge is drawn.
			-- A combining mark stays with its base. An area running past the buffer is cut to
			-- it. Every row stays continuation-consistent.
		local
			l_button: TUI_BUTTON
			l_w, l_e: STRING_32
			l_buf: BUFFER
		do
			l_w := {STRING_32} "%/0x4E16/"
			create l_button.make ({STRING_32} "a" + l_w + "b")
			assert ("wide width", l_button.width = 2 + 4 + 2)
			check_render ("whole", l_button, 8, {STRING_32} "[ a" + l_w + "b ]")
			check_render ("right bracket cut", l_button, 7, {STRING_32} "[ a" + l_w + "b ")
			check_render ("no right bracket", l_button, 6, {STRING_32} "[ a" + l_w + "b")
			check_render ("wide ends on the edge", l_button, 5, {STRING_32} "[ a" + l_w)
			check_render ("wide crosses the edge", l_button, 4, {STRING_32} "[ a ")
			check_render ("right aligned crosses", l_button.with_alignment ({TEXT_ALIGNMENT}.right), 4, {STRING_32} "[ a ")
			check_render ("only the bracket", l_button, 2, {STRING_32} "[ ")
			check_render ("one cell", l_button, 1, {STRING_32} "[")
				-- No brackets, a wide character first
			check_render ("bare wide cut", (create {TUI_BUTTON}.make (l_w + "x")).with_brackets (Void, Void), 1, {STRING_32} " ")
			check_render ("bare wide fits", (create {TUI_BUTTON}.make (l_w + "x")).with_brackets (Void, Void), 2, l_w)
				-- A base and its combining mark are one cluster, one column
			l_e := {STRING_32} "e%/0x301/"
			check_render ("combining kept", (create {TUI_BUTTON}.make (l_e + "f")).with_brackets (Void, Void), 1, l_e)
				-- The cell left out keeps its symbol
			create l_buf.make (6, 1)
			l_buf.put_string (0, 0, "######", create {STYLE})
			l_button.render (create {RECT}.make (0, 0, 4, 1), l_buf)
			assert_buffer_lines ("cut over text", l_buf, <<"[ a###">>)
				-- Area past the buffer
			create l_buf.make (5, 1)
			l_button.with_focused (True).render (create {RECT}.make (0, 0, 40, 3), l_buf)
			assert_buffer_lines ("cut by the buffer, row 0 is not the middle row", l_buf, <<"     ">>)
			create l_buf.make (5, 2)
			l_button.with_focused (True).render (create {RECT}.make (0, 0, 8, 3), l_buf)
			assert_buffer_lines ("cut by the buffer", l_buf, <<"     ", {STRING_32} "[ a" + l_w>>)
			assert ("cut consistent", l_buf.is_consistent)
			assert_cell_style ("cut area styled", l_buf, 0, 4, (create {STYLE}).with_reverse)
				-- Over wide characters already in the buffer
			create l_buf.make (10, 1)
			l_buf.put_string (0, 0, l_w + l_w + l_w + l_w + l_w, create {STYLE})
			(create {TUI_BUTTON}.make ("ab")).render (create {RECT}.make (1, 0, 6, 1), l_buf)
			assert_buffer_lines ("over wide", l_buf, <<{STRING_32} " [ ab ] " + l_w>>)
			assert ("over wide consistent", l_buf.is_consistent)
		end

	test_button_middle_row
			-- Height 3: the content on row 1, the style over all three rows. Height 2: the upper
			-- of the two middle rows. Height 4: row 1.
		local
			l_buf: BUFFER
			l_button: TUI_BUTTON
			l_reverse: STYLE
		do
			l_reverse := (create {STYLE}).with_reverse
			create l_button.make ("OK")
			create l_buf.make (8, 3)
			l_button.with_focused (True).render (create {RECT}.make (0, 0, 8, 3), l_buf)
			assert_buffer_lines ("height 3", l_buf, <<"        ", " [ OK ] ", "        ">>)
			assert_cell_style ("top row filled", l_buf, 0, 0, l_reverse)
			assert_cell_style ("bottom row filled", l_buf, 2, 7, l_reverse)
			assert ("content row 3", l_button.content_row (create {RECT}.make (0, 0, 8, 3)) = 1)
			create l_buf.make (8, 3)
			l_button.render (create {RECT}.make (0, 1, 8, 2), l_buf)
			assert_buffer_lines ("height 2", l_buf, <<"        ", " [ OK ] ", "        ">>)
			assert ("content row 2", l_button.content_row (create {RECT}.make (0, 1, 8, 2)) = 1)
			create l_buf.make (8, 4)
			l_button.render (create {RECT}.make (0, 0, 8, 4), l_buf)
			assert_buffer_lines ("height 4", l_buf, <<"        ", " [ OK ] ", "        ", "        ">>)
				-- Empty areas draw nothing
			create l_buf.make (8, 2)
			l_button.with_focused (True).render (create {RECT}.make (0, 0, 0, 2), l_buf)
			l_button.with_focused (True).render (create {RECT}.make (0, 0, 8, 0), l_buf)
			assert_buffer_lines ("empty areas", l_buf, <<"        ", "        ">>)
			assert_cell_style ("empty areas unstyled", l_buf, 0, 0, create {STYLE})
		end

feature -- Size and hits

	test_button_width
			-- `width` is the brackets and the label: "[ " + label + " ]" by default, the label
			-- alone without brackets, wide characters two columns each.
		local
			l_button: TUI_BUTTON
		do
			create l_button.make ("Cancel")
			assert ("default brackets", l_button.width = 10)
			assert ("no brackets", l_button.with_brackets (Void, Void).width = 6)
			assert ("left only", l_button.with_brackets ("<", Void).width = 7)
			assert ("right only", l_button.with_brackets (Void, ">").width = 7)
			assert ("own brackets", l_button.with_brackets ("< ", " >").width = 10)
			assert ("empty label", (create {TUI_BUTTON}).width = 4)
			assert ("empty bare", (create {TUI_BUTTON}).with_brackets (Void, Void).width = 0)
			assert ("wide label", (create {TUI_BUTTON}.make ({STRING_32} "%/0x4E16/%/0x754C/")).width = 8)
			assert ("wide bracket", l_button.with_brackets ({STRING_32} "%/0x3010/", {STRING_32} "%/0x3011/").width = 10)
			check_render ("own brackets drawn", (create {TUI_BUTTON}.make ("OK")).with_brackets ("<", ">"), 6, " <OK> ")
			check_render ("bare drawn", (create {TUI_BUTTON}.make ("OK")).with_brackets (Void, Void), 6, "  OK  ")
			assert ("valid bracket", {TUI_BUTTON}.is_valid_bracket ("[ "))
			assert ("control bracket", not {TUI_BUTTON}.is_valid_bracket ("%T"))
			assert ("C1 bracket", not {TUI_BUTTON}.is_valid_bracket ({STRING_32} "%/0x9B/"))
		end

	test_button_registers_its_hit_region
			-- With a `hit_id`, FRAME.render_widget registers the whole area: the label, the
			-- cells beside it and the other rows; without one, nothing is registered.
		local
			l_frame: FRAME
			l_id: WIDGET_ID
			l_button: TUI_BUTTON
		do
			create l_frame.make (create {BUFFER}.make (20, 5))
			create l_id.make (7)
			create l_button.make ("OK")
			l_frame.render_widget (l_button, create {RECT}.make (2, 0, 12, 1))
			assert ("no id, no region", l_frame.hit_map.is_empty)
			l_frame.render_widget (l_button.with_hit_id (l_id), create {RECT}.make (2, 1, 12, 3))
			assert ("label hit", attached l_frame.hit_map.hit (8, 2) as id and then id ~ l_id)
			assert ("left edge hit", attached l_frame.hit_map.hit (2, 2) as id and then id ~ l_id)
			assert ("right edge hit", attached l_frame.hit_map.hit (13, 2) as id and then id ~ l_id)
			assert ("top row hit", attached l_frame.hit_map.hit (2, 1) as id and then id ~ l_id)
			assert ("bottom corner hit", attached l_frame.hit_map.hit (13, 3) as id and then id ~ l_id)
			assert ("left of the area", l_frame.hit_map.hit (1, 2) = Void)
			assert ("right of the area", l_frame.hit_map.hit (14, 2) = Void)
			assert ("row below", l_frame.hit_map.hit (2, 4) = Void)
			assert ("with_hit_id copies", l_button.hit_id = Void)
			assert ("hit area is the area", l_button.hit_area (create {RECT}.make (2, 1, 12, 3), Void)
				~ create {RECT}.make (2, 1, 12, 3))
		end

	test_button_without_fill
			-- `with_fill (False)`: the focused style covers the brackets and the label only,
			-- on the content row; the other cells keep their style; the hit region is still
			-- the whole area.
		local
			l_frame: FRAME
			l_id: WIDGET_ID
			l_button: TUI_BUTTON
		do
			create l_frame.make (create {BUFFER}.make (20, 3))
			create l_id.make (7)
			create l_button.make ("OK")
			assert ("filled by default", l_button.fills_area and not l_button.with_fill (False).fills_area)
				-- "[ OK ]" is 6 wide, centred in 12 columns at 12 // 2 - 6 // 2 = 3: columns 5..10
			l_frame.render_widget (l_button.with_fill (False).with_focused (True).with_hit_id (l_id),
				create {RECT}.make (2, 0, 12, 3))
			assert_buffer_lines ("content", l_frame.buffer, <<"                    ", "     [ OK ]         ", "                    ">>)
			assert ("bracket reversed", l_frame.buffer.cell (1, 5).style.is_reversed)
			assert ("label reversed", l_frame.buffer.cell (1, 8).style.is_reversed)
			assert ("last bracket reversed", l_frame.buffer.cell (1, 10).style.is_reversed)
			assert ("left of content plain", not l_frame.buffer.cell (1, 4).style.is_reversed)
			assert ("right of content plain", not l_frame.buffer.cell (1, 11).style.is_reversed)
			assert ("other row plain", not l_frame.buffer.cell (0, 6).style.is_reversed)
			assert ("hit beside the label", attached l_frame.hit_map.hit (2, 0) as id and then id ~ l_id)
			assert ("not equal to a filled one", not (l_button.with_fill (False) ~ l_button))
		end

	test_button_builders_equality_and_copy
			-- Defaults; each `with_*` sets its attribute on a copy and leaves the original as it
			-- was; `is_equal` compares every attribute; a copy has its own label.
		local
			l_a, l_b: TUI_BUTTON
			l_red: STYLE
			l_line: TEXT_LINE
			l_id: WIDGET_ID
		do
			create l_a
			assert ("empty label", l_a.label.is_empty)
			assert ("not focused", not l_a.is_focused)
			assert ("not pressed", not l_a.is_pressed)
			assert ("default brackets", l_a.left_bracket.same_string_general ("[ ") and l_a.right_bracket.same_string_general (" ]"))
			assert ("centred", l_a.alignment = {TEXT_ALIGNMENT}.center)
			assert ("default style", l_a.style.is_equal (create {STYLE}))
			assert ("reversed focus", l_a.focused_style.is_equal ((create {STYLE}).with_reverse))
			assert ("reversed bold pressed", l_a.pressed_style.is_equal ((create {STYLE}).with_reverse.with_bold))
			assert ("no hit id", l_a.hit_id = Void)
			assert ("make", (create {TUI_BUTTON}.make ("x")).label.to_plain_string.same_string_general ("x"))
			assert ("default equal", l_a ~ (create {TUI_BUTTON}))

			create l_red.make_fg ({COLOR}.Red)
			create l_id.make (4)
			assert ("focused", l_a.with_focused (True).is_focused and not (l_a ~ l_a.with_focused (True)))
			assert ("pressed", l_a.with_pressed (True).is_pressed and not (l_a ~ l_a.with_pressed (True)))
			assert ("style", l_a.with_style (l_red).style = l_red and not (l_a ~ l_a.with_style (l_red)))
			assert ("equal styles", l_a.with_style (l_red) ~ l_a.with_style (create {STYLE}.make_fg ({COLOR}.Red)))
			assert ("focused style", l_a.with_focused_style (l_red).focused_style = l_red and not (l_a ~ l_a.with_focused_style (l_red)))
			assert ("pressed style", l_a.with_pressed_style (l_red).pressed_style = l_red and not (l_a ~ l_a.with_pressed_style (l_red)))
			assert ("alignment", l_a.with_alignment ({TEXT_ALIGNMENT}.left).alignment = {TEXT_ALIGNMENT}.left
				and not (l_a ~ l_a.with_alignment ({TEXT_ALIGNMENT}.left)))
			assert ("brackets", not (l_a ~ l_a.with_brackets ("<", ">")))
			assert ("no brackets", l_a.with_brackets (Void, Void).left_bracket.is_empty
				and l_a.with_brackets (Void, Void).right_bracket.is_empty)
			assert ("equal brackets", l_a.with_brackets ("<", ">") ~ l_a.with_brackets ({STRING_32} "<", {STRING_32} ">"))
			assert ("hit id", l_a.with_hit_id (l_id).hit_id = l_id and not (l_a ~ l_a.with_hit_id (l_id)))
			assert ("equal hit ids", l_a.with_hit_id (l_id) ~ l_a.with_hit_id (create {WIDGET_ID}.make (4)))
			assert ("original kept", l_a ~ (create {TUI_BUTTON}) and l_a.hit_id = Void)

			l_b := l_a.with_label ("x")
			assert ("label set", l_b.label.width = 1)
			assert ("label differs", not (l_a ~ l_b))
			assert ("equal labels", l_b ~ l_a.with_label ("x"))
			create l_line.make_raw ("z")
			assert ("label line", l_a.with_label_line (l_line).label = l_line)
			assert ("make_with_line", (create {TUI_BUTTON}.make_with_line (l_line)).label = l_line)
				-- A copy has its own label
			l_b := l_a.with_label ("x")
			l_b.with_focused (True).label.append_text ("y", create {STYLE})
			assert ("copy has its own label", l_b.label.to_plain_string.same_string_general ("x"))
		end

feature {NONE} -- Implementation

	check_render (a_tag: STRING; a_button: TUI_BUTTON; a_width: INTEGER; a_expected: STRING_32)
			-- `a_button` rendered into an area `a_width` columns wide, in a 1-row buffer two
			-- columns wider, gives `a_expected` and two untouched columns.
		local
			l_buf: BUFFER
		do
			create l_buf.make (a_width + 2, 1)
			a_button.render (create {RECT}.make (0, 0, a_width.to_natural_16, 1), l_buf)
			assert_buffer_lines (a_tag, l_buf, <<a_expected + "  ">>)
			assert (a_tag + " consistent", l_buf.is_consistent)
		end

end
