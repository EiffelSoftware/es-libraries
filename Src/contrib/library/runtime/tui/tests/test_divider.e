note
	description: "[
		P2 item W1, the TUI_DIVIDER widget (review/p2_terminal_widgets_plan.md).
		Ratatui has no divider widget, so these are EiffelTUI's own row-exact buffer snapshots:
		each line set in both directions, each label alignment, label clipping and dropping
		(a wide character at the clipping edge included), zero-size and one-cell areas, areas
		cut by the buffer, styles, and the `with_*` builders.
		Glyphs: plain U+2500 / U+2502, thick U+2501 / U+2503, double U+2550 / U+2551,
		dashed U+254C / U+254E.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_DIVIDER

inherit
	BUFFER_TEST_HELPER

feature -- Line sets

	test_divider_line_sets
			-- Each line set, horizontal on the top row of a 6 x 3 area and vertical down the
			-- left column of an area starting at column 1. Nothing else of the area is drawn.
		do
			check_line_set ("plain", {DIVIDER_LINE_SET}.plain, {STRING_32} "%/0x2500/", {STRING_32} "%/0x2502/")
			check_line_set ("thick", {DIVIDER_LINE_SET}.thick, {STRING_32} "%/0x2501/", {STRING_32} "%/0x2503/")
			check_line_set ("double", {DIVIDER_LINE_SET}.double, {STRING_32} "%/0x2550/", {STRING_32} "%/0x2551/")
			check_line_set ("dashed", {DIVIDER_LINE_SET}.dashed, {STRING_32} "%/0x254C/", {STRING_32} "%/0x254E/")
			assert ("plain is BORDER_TYPE's", {DIVIDER_LINE_SET}.horizontal ({DIVIDER_LINE_SET}.plain) = {BORDER_TYPE}.horizontal ({BORDER_TYPE}.plain))
			assert ("double is BORDER_TYPE's", {DIVIDER_LINE_SET}.vertical ({DIVIDER_LINE_SET}.double) = {BORDER_TYPE}.vertical ({BORDER_TYPE}.double))
			assert ("rounded is not a line set", not {DIVIDER_LINE_SET}.is_valid ({BORDER_TYPE}.rounded))
			assert ("zero is not a line set", not {DIVIDER_LINE_SET}.is_valid (0))
		end

feature -- Label

	test_divider_label_alignments
			-- "ab" with one blank on each side on a 12-column rule: left starts after the first
			-- line cell, right ends before the last, centre is centred between them (the odd
			-- cell goes right, as TUI_BLOCK centres a title). Padding 0 and 2.
		do
			check_label ("left", "ab", {TEXT_ALIGNMENT}.left, 1, 12, h (1) + " ab " + h (7))
			check_label ("center", "ab", {TEXT_ALIGNMENT}.center, 1, 12, h (4) + " ab " + h (4))
			check_label ("right", "ab", {TEXT_ALIGNMENT}.right, 1, 12, h (7) + " ab " + h (1))
			check_label ("center odd", "abc", {TEXT_ALIGNMENT}.center, 1, 12, h (3) + " abc " + h (4))
			check_label ("center no padding", "ab", {TEXT_ALIGNMENT}.center, 0, 12, h (5) + "ab" + h (5))
			check_label ("right padding 2", "ab", {TEXT_ALIGNMENT}.right, 2, 12, h (5) + "  ab  " + h (1))
			check_label ("left padding 0", "ab", {TEXT_ALIGNMENT}.left, 0, 12, h (1) + "ab" + h (9))
		end

	test_divider_label_clipped_and_dropped
			-- A label too long is clipped per grapheme cluster to the columns left between the
			-- padding, with one line cell kept at each end. It is dropped, and the line drawn
			-- whole, when the padding and its first cluster do not fit. An empty label draws
			-- nothing.
		do
			check_label ("clipped", "abcdefgh", {TEXT_ALIGNMENT}.left, 1, 8, h (1) + " abcd " + h (1))
			check_label ("clipped right", "abcdefgh", {TEXT_ALIGNMENT}.right, 1, 8, h (1) + " abcd " + h (1))
			check_label ("one cluster", "ab", {TEXT_ALIGNMENT}.center, 1, 5, h (1) + " a " + h (1))
			check_label ("dropped: no room", "ab", {TEXT_ALIGNMENT}.center, 1, 4, h (4))
			check_label ("dropped: padding", "ab", {TEXT_ALIGNMENT}.left, 3, 8, h (8))
			check_label ("dropped: two cells", "ab", {TEXT_ALIGNMENT}.left, 0, 2, h (2))
			check_label ("no padding fits", "ab", {TEXT_ALIGNMENT}.left, 0, 3, h (1) + "a" + h (1))
			check_label ("empty", "", {TEXT_ALIGNMENT}.center, 1, 8, h (8))
				-- A wide first cluster that does not fit drops the label
			check_label ("dropped: wide first", {STRING_32} "%/0x4E16/x", {TEXT_ALIGNMENT}.left, 1, 5, h (5))
		end

	test_divider_wide_label_at_clipping_edge
			-- A wide character that would cross the clipping edge is left out, with the rest
			-- of the label; the padding stays next to the last cluster drawn, and the line
			-- fills the rest. A wide character that ends on the edge is drawn. An area cut by
			-- the buffer's right edge is placed on the part inside the buffer. Each row stays
			-- continuation-consistent.
		local
			l_w: STRING_32
			l_buf: BUFFER
		do
			l_w := {STRING_32} "%/0x4E16/"
				-- 7 columns: room for 3 between the padding
			check_label ("wide ends on the edge", {STRING_32} "a" + l_w + "b", {TEXT_ALIGNMENT}.left, 1, 7, h (1) + " a" + l_w + " " + h (1))
			check_label ("wide crosses the edge", {STRING_32} "ab" + l_w, {TEXT_ALIGNMENT}.left, 1, 7, h (1) + " ab " + h (2))
			check_label ("wide crosses, right", {STRING_32} "ab" + l_w, {TEXT_ALIGNMENT}.right, 1, 7, h (2) + " ab " + h (1))
			check_label ("wide crosses, centre", {STRING_32} "ab" + l_w, {TEXT_ALIGNMENT}.center, 1, 7, h (1) + " ab " + h (2))
			check_label ("wide fits whole", {STRING_32} "ab" + l_w, {TEXT_ALIGNMENT}.center, 1, 8, h (1) + " ab" + l_w + " " + h (1))
				-- Area running past the buffer: the label is placed on the 7 columns inside it
			create l_buf.make (7, 1)
			(create {TUI_DIVIDER}.make).with_label ({STRING_32} "ab" + l_w).with_label_alignment ({TEXT_ALIGNMENT}.right)
				.render (create {RECT}.make (0, 0, 30, 1), l_buf)
			assert_buffer_lines ("cut by the buffer", l_buf, <<h (2) + " ab " + h (1)>>)
			assert ("cut consistent", l_buf.is_consistent)
				-- A styled label of two spans: clipping goes on across spans
			create l_buf.make (8, 1)
			(create {TUI_DIVIDER}.make).with_label_line (create {TEXT_LINE}.make (<<
					create {TEXT_SPAN}.make_raw ("ab"),
					create {TEXT_SPAN}.make ({STRING_32} "c" + l_w, create {STYLE}.make_fg ({COLOR}.Red))>>))
				.render (create {RECT}.make (0, 0, 8, 1), l_buf)
			assert_buffer_lines ("two spans", l_buf, <<h (1) + " abc " + h (2)>>)
			assert_cell_style ("second span styled", l_buf, 0, 4, create {STYLE}.make_fg ({COLOR}.Red))
		end

feature -- Areas

	test_divider_zero_and_one_cell_areas
			-- Zero-size areas and areas outside the buffer draw nothing; a one-cell area draws
			-- one line cell (no label); an area running past the buffer is cut to it.
		local
			l_buf: BUFFER
			l_div, l_vert: TUI_DIVIDER
		do
			l_div := (create {TUI_DIVIDER}.make).with_label ("label")
			l_vert := (create {TUI_DIVIDER}.make_vertical).with_label ("label")
			create l_buf.make (4, 3)
			across <<create {RECT}.make (0, 0, 0, 0), create {RECT}.make (1, 1, 0, 2), create {RECT}.make (1, 1, 2, 0),
					create {RECT}.make (4, 0, 2, 2), create {RECT}.make (0, 3, 4, 2), create {RECT}.make (40, 40, 3, 3)>> as a loop
				l_div.render (a, l_buf)
				l_vert.render (a, l_buf)
			end
			assert_buffer_lines ("nothing drawn", l_buf, <<"    ", "    ", "    ">>)

			l_div.render (create {RECT}.make (2, 1, 1, 1), l_buf)
			assert_buffer_lines ("one cell", l_buf, <<"    ", {STRING_32} "  " + h (1) + " ", "    ">>)
			create l_buf.make (4, 3)
			l_vert.render (create {RECT}.make (2, 1, 1, 1), l_buf)
			assert_buffer_lines ("one cell vertical", l_buf, <<"    ", {STRING_32} "  %/0x2502/ ", "    ">>)

				-- Past the bottom and the right
			create l_buf.make (4, 3)
			l_div.render (create {RECT}.make (1, 2, 9, 9), l_buf)
			l_vert.render (create {RECT}.make (3, 1, 1, 9), l_buf)
			assert_buffer_lines ("cut", l_buf, <<"    ", {STRING_32} "   %/0x2502/", {STRING_32} " " + h (2) + {STRING_32} "%/0x2502/">>)
				-- Two cells: no label
			create l_buf.make (4, 1)
			l_div.render (create {RECT}.make (0, 0, 2, 1), l_buf)
			assert_buffer_lines ("two cells", l_buf, <<h (2) + "  ">>)
			assert ("consistent", l_buf.is_consistent)
		end

	test_divider_over_wide_characters
			-- A rule over wide characters cuts those it crosses; their halves outside become
			-- blanks, and every row stays continuation-consistent.
		local
			l_buf: BUFFER
			l_w: STRING_32
		do
			l_w := {STRING_32} "%/0x5BBD/"
			create l_buf.make (6, 2)
			l_buf.put_string (0, 0, l_w + l_w + l_w, create {STYLE})
			(create {TUI_DIVIDER}.make).render (create {RECT}.make (1, 0, 4, 2), l_buf)
			assert_buffer_lines ("cut", l_buf, <<{STRING_32} " " + h (4) + " ", "      ">>)
			assert ("horizontal consistent", l_buf.is_consistent)
			create l_buf.make (4, 2)
			l_buf.put_string (0, 0, l_w + l_w, create {STYLE})
			l_buf.put_string (1, 0, l_w + l_w, create {STYLE})
			(create {TUI_DIVIDER}.make_vertical).render (create {RECT}.make (1, 0, 2, 2), l_buf)
			assert_buffer_lines ("vertical cut", l_buf, <<{STRING_32} " %/0x2502/" + l_w, {STRING_32} " %/0x2502/" + l_w>>)
			assert ("vertical consistent", l_buf.is_consistent)
		end

feature -- Styles

	test_divider_patches_cell_style
			-- `style` is patched over each line cell's style, so the backgrounds under the rule
			-- stay. The label's base style is the line cell's style under it, patched by the
			-- label's own styles. Cells outside the rule keep their styles.
		local
			l_buf: BUFFER
			l_yb, l_gk: STYLE
		do
			create l_yb.make_with_colors ({COLOR}.Yellow, {COLOR}.Blue)
			create l_gk.make_with_colors ({COLOR}.Green, {COLOR}.Black)
			create l_buf.make (6, 2)
			l_buf.put_string (0, 0, "abc", l_yb)
			l_buf.put_string (0, 3, "def", l_gk)
			l_buf.put_string (1, 0, "ghijkl", l_yb)
			(create {TUI_DIVIDER}.make)
				.with_style (create {STYLE}.make_fg ({COLOR}.Red))
				.with_label_line (create {TEXT_LINE}.make_styled ("x", create {STYLE}.make_bg ({COLOR}.White)))
				.with_label_padding (0)
				.with_label_alignment ({TEXT_ALIGNMENT}.center)
				.render (create {RECT}.make (0, 0, 6, 2), l_buf)
			assert_buffer_lines ("drawn", l_buf, <<h (2) + "x" + h (3), "ghijkl">>)
			assert_cell_style ("over blue", l_buf, 0, 0, create {STYLE}.make_with_colors ({COLOR}.Red, {COLOR}.Blue))
			assert_cell_style ("over black", l_buf, 0, 4, create {STYLE}.make_with_colors ({COLOR}.Red, {COLOR}.Black))
			assert_cell_style ("label", l_buf, 0, 2, create {STYLE}.make_with_colors ({COLOR}.Red, {COLOR}.White))
			assert_cell_style ("next row", l_buf, 1, 0, l_yb)
				-- Padding cells take the line cell's style
			create l_buf.make (6, 1)
			l_buf.put_string (0, 0, "abcdef", l_yb)
			(create {TUI_DIVIDER}.make).with_style (create {STYLE}.make_fg ({COLOR}.Red)).with_label ("x")
				.render (create {RECT}.make (0, 0, 6, 1), l_buf)
			assert_buffer_lines ("padded", l_buf, <<h (1) + " x " + h (2)>>)
			assert_cell_style ("padding", l_buf, 0, 1, create {STYLE}.make_with_colors ({COLOR}.Red, {COLOR}.Blue))
			assert_cell_style ("label plain", l_buf, 0, 2, create {STYLE}.make_with_colors ({COLOR}.Red, {COLOR}.Blue))
				-- A vertical rule patches too
			create l_buf.make (2, 2)
			l_buf.put_string (0, 0, "ab", l_gk)
			(create {TUI_DIVIDER}.make_vertical).with_style (create {STYLE}.make_fg ({COLOR}.Red)).render (create {RECT}.make (1, 0, 1, 2), l_buf)
			assert_cell_style ("vertical over black", l_buf, 0, 1, create {STYLE}.make_with_colors ({COLOR}.Red, {COLOR}.Black))
			assert_cell_style ("vertical over default", l_buf, 1, 1, create {STYLE}.make_fg ({COLOR}.Red))
		end

feature -- Builders

	test_divider_builders_equality_and_copy
			-- Defaults; each `with_*` sets its attribute on a copy and leaves the original as it
			-- was; `is_equal` compares every attribute; a copy has its own label.
		local
			l_a, l_b, l_c: TUI_DIVIDER
			l_red: STYLE
			l_line: TEXT_LINE
		do
			create l_a.make
			assert ("horizontal", l_a.direction = {DIVIDER_DIRECTION}.horizontal and l_a.is_horizontal)
			assert ("plain", l_a.line_set = {DIVIDER_LINE_SET}.plain)
			assert ("no label", l_a.label = Void)
			assert ("left", l_a.label_alignment = {TEXT_ALIGNMENT}.left)
			assert ("padding 1", l_a.label_padding = 1)
			assert ("default style", l_a.style.is_equal (create {STYLE}))
			assert ("glyph", l_a.glyph = (0x2500).to_character_32)
			assert ("vertical glyph", (create {TUI_DIVIDER}.make_vertical).with_line_set ({DIVIDER_LINE_SET}.thick).glyph = (0x2503).to_character_32)
			assert ("default equal", l_a ~ (create {TUI_DIVIDER}))

			create l_red.make_fg ({COLOR}.Red)
			l_b := l_a.with_direction ({DIVIDER_DIRECTION}.vertical)
			assert ("direction set", l_b.direction = {DIVIDER_DIRECTION}.vertical and not l_b.is_horizontal)
			assert ("direction differs", not (l_a ~ l_b))
			assert ("make_vertical", l_b ~ (create {TUI_DIVIDER}.make_vertical))
			assert ("line set", l_a.with_line_set ({DIVIDER_LINE_SET}.dashed).line_set = {DIVIDER_LINE_SET}.dashed)
			assert ("line set differs", not (l_a ~ l_a.with_line_set ({DIVIDER_LINE_SET}.double)))
			assert ("style", l_a.with_style (l_red).style = l_red)
			assert ("style differs", not (l_a ~ l_a.with_style (l_red)))
			assert ("equal styles", l_a.with_style (l_red) ~ l_a.with_style (create {STYLE}.make_fg ({COLOR}.Red)))
			assert ("alignment", l_a.with_label_alignment ({TEXT_ALIGNMENT}.right).label_alignment = {TEXT_ALIGNMENT}.right)
			assert ("alignment differs", not (l_a ~ l_a.with_label_alignment ({TEXT_ALIGNMENT}.center)))
			assert ("padding", l_a.with_label_padding (3).label_padding = 3)
			assert ("padding differs", not (l_a ~ l_a.with_label_padding (0)))
			assert ("original kept", l_a ~ (create {TUI_DIVIDER}))

			l_b := l_a.with_label ("x")
			assert ("label set", attached l_b.label as l1 and then l1.width = 1)
			assert ("label differs", not (l_a ~ l_b))
			assert ("equal labels", l_b ~ l_a.with_label ("x"))
			assert ("other label differs", not (l_b ~ l_a.with_label ("y")))
			assert ("without label", l_b.without_label ~ l_a and l_b.label /= Void)
			create l_line.make_raw ("z")
			assert ("label line", l_a.with_label_line (l_line).label = l_line)

				-- A copy has its own label
			l_c := l_b.twin
			assert ("twin equal", l_c ~ l_b)
			if attached l_c.label as l2 then
				l2.append_span (create {TEXT_SPAN}.make_raw ("more"))
			end
			assert ("original label kept", attached l_b.label as l3 and then l3.width = 1)
			l_c := l_b.with_style (l_red)
			if attached l_c.label as l4 then
				l4.append_span (create {TEXT_SPAN}.make_raw ("more"))
			end
			assert ("builder copy has its own label", attached l_b.label as l5 and then l5.width = 1)
		end

	test_divider_preconditions
			-- Invalid direction, line set and alignment are refused.
		local
			l_div: TUI_DIVIDER
		do
			create l_div
			assert ("direction", precondition_raised (agent l_div.set_direction (0), "valid_direction"))
			assert ("line set", precondition_raised (agent l_div.set_line_set (2), "valid_set"))
			assert ("alignment", precondition_raised (agent l_div.set_label_alignment (7), "valid_align"))
			assert ("with line set", precondition_raised (agent with_line_set_call (9), "valid_set"))
			assert ("unchanged", l_div ~ (create {TUI_DIVIDER}))
		end

feature {NONE} -- Helpers

	h (a_count: INTEGER): STRING_32
			-- `a_count` plain horizontal line glyphs
		do
			create Result.make_filled ((0x2500).to_character_32, a_count)
		end

	check_line_set (a_tag: STRING; a_set: NATURAL_8; a_h, a_v: STRING_32)
			-- A horizontal and a vertical divider drawn with `a_set` give `a_h` and `a_v`.
		local
			l_buf: BUFFER
			l_row: STRING_32
		do
			create l_buf.make (6, 3)
			(create {TUI_DIVIDER}.make).with_line_set (a_set).render (create {RECT}.make (0, 0, 6, 3), l_buf)
			create l_row.make (6)
			l_row.append (a_h); l_row.append (a_h); l_row.append (a_h)
			l_row.append (a_h); l_row.append (a_h); l_row.append (a_h)
			assert_buffer_lines (a_tag + " horizontal", l_buf, <<l_row, "      ", "      ">>)
			create l_buf.make (6, 3)
			(create {TUI_DIVIDER}.make_vertical).with_line_set (a_set).render (create {RECT}.make (1, 0, 5, 3), l_buf)
			assert_buffer_lines (a_tag + " vertical", l_buf, <<{STRING_32} " " + a_v + "    ", {STRING_32} " " + a_v + "    ", {STRING_32} " " + a_v + "    ">>)
		end

	check_label (a_tag: STRING; a_label: READABLE_STRING_GENERAL; a_align: NATURAL_8; a_padding: NATURAL_16; a_width: INTEGER; a_expected: STRING_32)
			-- A plain divider labelled `a_label` on a 1-row buffer `a_width` wide gives `a_expected`.
		local
			l_buf: BUFFER
		do
			create l_buf.make (a_width, 1)
			(create {TUI_DIVIDER}.make).with_label (a_label).with_label_alignment (a_align).with_label_padding (a_padding)
				.render (create {RECT}.make (0, 0, a_width.to_natural_16, 1), l_buf)
			assert_buffer_lines (a_tag, l_buf, <<a_expected>>)
			assert (a_tag + " consistent", l_buf.is_consistent)
		end

	with_line_set_call (a_set: NATURAL_8)
			-- Call `with_line_set` (for `precondition_raised`).
		local
			l_div: TUI_DIVIDER
		do
			l_div := (create {TUI_DIVIDER}).with_line_set (a_set)
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
					(attached {PRECONDITION_VIOLATION} e.original as v and then
					(attached v.description as d and then d.same_string (a_tag)))
				retry
			end
		end

end
