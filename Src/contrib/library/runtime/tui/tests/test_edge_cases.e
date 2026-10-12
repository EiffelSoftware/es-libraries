note
	description: "[
		Edge-case test suite covering zero-size and oversized areas, wide characters in widgets,
		wide-over-wide buffer overwrites, combining marks/emoji, RECT boundary arithmetic,
		over-constrained layouts, Min/Max constraints, and malformed input sequences.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_EDGE_CASES

inherit
	BUFFER_TEST_HELPER

feature -- Test Routines

	test_zero_and_oversized_areas
			-- Test widgets rendering into zero-size and out-of-bounds areas without errors.
		local
			l_buf: BUFFER
			l_zero_w, l_zero_h, l_zero_both, l_oversized: RECT
			l_para: TUI_PARAGRAPH
			l_block: TUI_BLOCK
			l_list: TUI_LIST
			l_list_state: LIST_STATE
			l_table: TUI_TABLE
			l_table_state: TABLE_STATE
			l_tabs: TUI_TABS
			l_tabs_state: TABS_STATE
			l_scrollbar: TUI_SCROLLBAR
			l_scrollbar_state: SCROLLBAR_STATE
			l_gauge: TUI_GAUGE
			l_line_gauge: TUI_LINE_GAUGE
			l_sparkline: TUI_SPARKLINE
			l_barchart: TUI_BARCHART
			l_canvas: TUI_CANVAS
			l_clear: TUI_CLEAR
			l_text: TEXT
		do
			create l_buf.make (20, 10)
			create l_zero_w.make (0, 0, 0, 10)
			create l_zero_h.make (0, 0, 20, 0)
			create l_zero_both.make (0, 0, 0, 0)
			create l_oversized.make (15, 8, 15, 10) -- extends past (20, 10)

			-- Prepare widgets
			create l_text.make_raw ("Edge case test text")
			create l_para.make (l_text)
			create l_block.make
			l_block.set_title_string ("Zero Block")

			create l_list.make_empty
			l_list.append_raw_item ("Item 1")
			create l_list_state.make

			create l_table.default_create
			l_table.append_row (create {TABLE_ROW}.make_raw (<<"Cell 1">>))
			l_table.set_widths (<<{CONSTRAINTS}.fixed (10)>>)
			create l_table_state.make

			create l_tabs.make_from_strings (<<"Tab 1">>)
			create l_tabs_state.make

			create l_scrollbar.make ({SCROLLBAR_ORIENTATION}.vertical_right)
			create l_scrollbar_state.make (100)

			create l_gauge.make
			l_gauge.set_ratio (0.5)

			create l_line_gauge.make
			l_line_gauge.set_ratio (0.75)

			create l_sparkline.make_with_data (<<{NATURAL_64} 10, {NATURAL_64} 50, {NATURAL_64} 100>>)

			create l_barchart.make_with_data (<<create {BAR_ITEM}.make ("B1", 20)>>)

			create l_canvas.make
			create l_clear.default_create

			-- 1. Test rendering to zero-width area (should be safe no-op)
			l_para.render (l_zero_w, l_buf)
			l_block.render (l_zero_w, l_buf)
			l_list.render_stateful (l_zero_w, l_buf, l_list_state)
			l_table.render_stateful (l_zero_w, l_buf, l_table_state)
			l_tabs.render_stateful (l_zero_w, l_buf, l_tabs_state)
			l_scrollbar.render_stateful (l_zero_w, l_buf, l_scrollbar_state)
			l_gauge.render (l_zero_w, l_buf)
			l_line_gauge.render (l_zero_w, l_buf)
			l_sparkline.render (l_zero_w, l_buf)
			l_barchart.render (l_zero_w, l_buf)
			l_canvas.render (l_zero_w, l_buf)
			l_clear.render (l_zero_w, l_buf)

			-- 2. Test rendering to zero-height area
			l_para.render (l_zero_h, l_buf)
			l_block.render (l_zero_h, l_buf)
			l_list.render_stateful (l_zero_h, l_buf, l_list_state)
			l_table.render_stateful (l_zero_h, l_buf, l_table_state)
			l_tabs.render_stateful (l_zero_h, l_buf, l_tabs_state)
			l_scrollbar.render_stateful (l_zero_h, l_buf, l_scrollbar_state)
			l_gauge.render (l_zero_h, l_buf)
			l_line_gauge.render (l_zero_h, l_buf)
			l_sparkline.render (l_zero_h, l_buf)
			l_barchart.render (l_zero_h, l_buf)
			l_canvas.render (l_zero_h, l_buf)
			l_clear.render (l_zero_h, l_buf)

			-- 3. Test rendering to both-zero area
			l_para.render (l_zero_both, l_buf)
			l_block.render (l_zero_both, l_buf)
			l_list.render_stateful (l_zero_both, l_buf, l_list_state)

			-- Buffer should remain filled with initial spaces
			assert ("buffer still clean after zero areas", l_buf.cell (0, 0).symbol.is_equal ({STRING_32} " "))

			-- 4. Test rendering to oversized area (should clip gracefully within buffer bounds)
			l_clear.render (l_oversized, l_buf)
			l_para.render (l_oversized, l_buf)
			assert ("oversized render did not crash", True)
		end

	test_wide_characters_in_widgets
			-- Test widgets with Japanese / wide characters using buffer snapshot assertions.
		local
			l_buf: BUFFER
			l_area: RECT
			l_para: TUI_PARAGRAPH
			l_text: TEXT
			l_block: TUI_BLOCK
			l_list: TUI_LIST
			l_list_state: LIST_STATE
			l_tabs: TUI_TABS
			l_tabs_state: TABS_STATE
		do
			-- 1. Wide text in TUI_PARAGRAPH
			create l_buf.make (10, 3)
			create l_area.make (0, 0, 10, 3)
			create l_text.make_raw ({STRING_32} "%/0x65E5/%/0x672C/%/0x8A9E/%N%/0x30C6/%/0x30B9/%/0x30C8/")
			create l_para.make (l_text)
			l_para.render (l_area, l_buf)

			-- Row 0: "日本語" (3 wide chars = 6 cols) followed by 4 spaces
			assert_buffer_lines ("paragraph wide chars", l_buf, <<
				"%/0x65E5/%/0x672C/%/0x8A9E/    ",
				"%/0x30C6/%/0x30B9/%/0x30C8/    ",
				"          "
			>>)

			-- 2. Wide title in TUI_BLOCK
			create l_buf.make (12, 3)
			create l_area.make (0, 0, 12, 3)
			create l_block.make
			l_block.set_title_string ({STRING_32} "%/0x3010/%/0x8A2D/%/0x5B9A/%/0x3011/")
			l_block.set_borders ({BORDERS}.all_borders)
			l_block.set_border_type ({BORDER_TYPE}.plain)
			l_block.render (l_area, l_buf)

			-- Top border has title: '┌', '【', '設', '定', '】', '─', '─', '┐'
			assert_cell_symbol ("block top-left corner", l_buf, 0, 0, "%/0x250C/")
			assert_cell_symbol ("block title wide 1", l_buf, 0, 1, "%/0x3010/")
			assert_cell_symbol ("block title wide 2", l_buf, 0, 3, "%/0x8A2D/")
			assert_cell_symbol ("block title wide 3", l_buf, 0, 5, "%/0x5B9A/")
			assert_cell_symbol ("block title wide 4", l_buf, 0, 7, "%/0x3011/")
			assert_cell_symbol ("block top-right corner", l_buf, 0, 11, "%/0x2510/")

			-- 3. Wide items in TUI_LIST
			create l_buf.make (10, 2)
			create l_area.make (0, 0, 10, 2)
			create l_list.make_empty
			l_list.append_raw_item ({STRING_32} "%/0x9805/%/0x76EE/%/0x4E00/")
			l_list.append_raw_item ({STRING_32} "%/0x9805/%/0x76EE/%/0x4E8C/")
			create l_list_state.make
			l_list.render_stateful (l_area, l_buf, l_list_state)
			assert_buffer_lines ("list wide items", l_buf, <<
				"%/0x9805/%/0x76EE/%/0x4E00/    ",
				"%/0x9805/%/0x76EE/%/0x4E8C/    "
			>>)

			-- 4. Wide titles in TUI_TABS
			create l_buf.make (14, 1)
			create l_area.make (0, 0, 14, 1)
			create l_tabs.make_from_strings (<<{STRING_32} "%/0x30E1/%/0x30A4/%/0x30F3/", {STRING_32} "%/0x8A2D/%/0x5B9A/">>)
			create l_tabs_state.make
			l_tabs.render_stateful (l_area, l_buf, l_tabs_state)
			-- "メイン | 設定"
			assert_cell_symbol ("tab 1 char 1", l_buf, 0, 0, "%/0x30E1/")
			assert_cell_symbol ("tab 1 char 2", l_buf, 0, 2, "%/0x30A4/")
			assert_cell_symbol ("tab 1 char 3", l_buf, 0, 4, "%/0x30F3/")
			assert_cell_symbol ("tab divider", l_buf, 0, 7, "|")
		end

	test_wide_over_wide_overwrite
			-- Test buffer boundary repairs when overwriting wide characters.
		local
			l_buf: BUFFER
			l_style: STYLE
		do
			create l_buf.make (6, 2)
			create l_style.default_create

			-- 1. Place wide char 'あ' (U+3042 = 12354) at (0, 0) -> occupies cols 0 and 1
			l_buf.put_char (0, 0, (12354).to_character_32, l_style)
			assert ("wide char at 0", l_buf.cell (0, 0).symbol.code (1) = {NATURAL_32} 12354)
			assert ("wide char width 2", l_buf.cell (0, 0).width = 2)
			assert ("continuation cell at 1", l_buf.cell (0, 1).is_continuation)

			-- 2. Overwrite continuation cell at (0, 1) with single char 'X'
			-- Parent cell at (0, 0) must be repaired (reset to ' ')
			l_buf.put_char (0, 1, ('X').to_character_32, l_style)
			assert ("parent repaired to space", l_buf.cell (0, 0).symbol.code (1) = (' ').natural_32_code)
			assert ("parent width reset to 1", l_buf.cell (0, 0).width = 1)
			assert ("new char at 1", l_buf.cell (0, 1).symbol.code (1) = ('X').natural_32_code)
			assert ("col 1 not continuation", not l_buf.cell (0, 1).is_continuation)

			-- 3. Place wide char 'い' (12356) at (0, 2) -> occupies cols 2 and 3
			l_buf.put_char (0, 2, (12356).to_character_32, l_style)
			assert ("wide char at 2", l_buf.cell (0, 2).symbol.code (1) = {NATURAL_32} 12356)
			assert ("continuation cell at 3", l_buf.cell (0, 3).is_continuation)

			-- 4. Overwrite wide char at (0, 2) with wide char 'う' (12358) at (0, 3)
			-- This overwrites the continuation cell at (0, 3) and occupies (0, 3) and (0, 4)
			l_buf.put_char (0, 3, (12358).to_character_32, l_style)
			assert ("col 2 repaired to space", l_buf.cell (0, 2).symbol.code (1) = (' ').natural_32_code)
			assert ("new wide char at 3", l_buf.cell (0, 3).symbol.code (1) = {NATURAL_32} 12358)
			assert ("continuation cell at 4", l_buf.cell (0, 4).is_continuation)

			-- 5. Place wide char at last column (col = 5 on width 6): cannot fit 2 columns
			-- Should blank cell with space
			l_buf.put_char (0, 5, (12360).to_character_32, l_style)
			assert ("last col blanked when wide does not fit", l_buf.cell (0, 5).symbol.code (1) = (' ').natural_32_code)
		end

	test_combining_marks_and_emoji
			-- Test display width calculations for ASCII, CJK, combining marks, and emoji.
		local
			l_width: UNICODE_WIDTH
		do
			create l_width

			-- Standard ASCII: width 1
			assert ("ascii 'A' width 1", l_width.width (65) = 1)
			assert ("ascii '0' width 1", l_width.width (48) = 1)
			assert ("ascii space width 1", l_width.width (32) = 1)

			-- Zero width characters
			assert ("null char width 0", l_width.width (0) = 0)
			assert ("zero width space width 0", l_width.width (8203) = 0) -- U+200B

			-- CJK fullwidth characters: width 2
			assert ("hiragana '%/0x3042/' width 2", l_width.width (12354) = 2) -- U+3042
			assert ("katakana '%/0x30A2/' width 2", l_width.width (12450) = 2) -- U+30A2
			assert ("cjk ideograph '%/0x65E5/' width 2", l_width.width (26085) = 2) -- U+65E5
			assert ("fullwidth exclamation width 2", l_width.width (65281) = 2) -- U+FF01

			-- Emoji in Supplementary Multilingual Plane
			assert ("grinning face emoji width 2", l_width.width (128512) = 2) -- U+1F600
			assert ("rocket emoji width 2", l_width.width (128640) = 2) -- U+1F680

			-- String width calculations
			assert ("string width ascii", l_width.string_width ("hello") = 5)
			assert ("string width japanese", l_width.string_width ({STRING_32} "%/0x3053/%/0x3093/%/0x306B/%/0x3061/%/0x306F/") = 10)
			assert ("string width mixed", l_width.string_width ({STRING_32} "Hi %/0x65E5/%/0x672C/") = 7)
		end

	test_rect_bounds_and_overflow
			-- Test RECT boundary arithmetic, margins, and geometric operations near 65535.
		local
			l_r1, l_r2, l_inner, l_inter, l_union: RECT
		do
			-- Standard boundary
			create l_r1.make (65530, 65530, 5, 5)
			assert ("r1 right is 65535", l_r1.right = 65535)
			assert ("r1 bottom is 65535", l_r1.bottom = 65535)

			-- Margin deflation larger than dimensions clamps to 0
			create l_r2.make (10, 10, 4, 4)
			l_inner := l_r2.inner (5, 5)
			assert ("clamped width is 0", l_inner.width = 0)
			assert ("clamped height is 0", l_inner.height = 0)

			-- Disjoint intersection returns 0-sized rect
			create l_r1.make (0, 0, 10, 10)
			create l_r2.make (20, 20, 10, 10)
			l_inter := l_r1.intersection (l_r2)
			assert ("disjoint intersection width 0", l_inter.width = 0)
			assert ("disjoint intersection height 0", l_inter.height = 0)

			-- Union of adjacent rects
			l_union := l_r1.union (l_r2)
			assert ("union x is 0", l_union.x = 0)
			assert ("union y is 0", l_union.y = 0)
			assert ("union width is 30", l_union.width = 30)
			assert ("union height is 30", l_union.height = 30)
		end

	test_overconstrained_and_min_max_layouts
			-- Test LAYOUT_SOLVER with over-constrained requests and Min/Max constraints.
		local
			l_solver: LAYOUT_SOLVER
			l_area: RECT
			l_chunks: ARRAYED_LIST [RECT]
		do
			create l_solver

			-- 1. Over-constrained layout: available width 20, requested 15 + 15 = 30
			create l_area.make (0, 0, 20, 5)
			l_chunks := l_solver.split (
				l_area,
				<<{CONSTRAINTS}.fixed (15), {CONSTRAINTS}.fixed (15)>>,
				{SPLIT_DIRECTION}.horizontal
			)
			assert ("two chunks returned", l_chunks.count = 2)
			-- Over-constrained layouts shrink proportionally
			assert ("first chunk shrunk proportionally to 10", l_chunks.i_th (1).width = 10)
			assert ("second chunk shrunk proportionally to 10", l_chunks.i_th (2).width = 10)
			assert ("total width does not exceed area", l_chunks.i_th (1).width + l_chunks.i_th (2).width <= 20)

			-- 2. Min / Max layout constraints
			create l_area.make (0, 0, 50, 10)
			l_chunks := l_solver.split (
				l_area,
				<<{CONSTRAINTS}.min_size (20), {CONSTRAINTS}.max_size (15), {CONSTRAINTS}.flex (1)>>,
				{SPLIT_DIRECTION}.horizontal
			)
			assert ("three chunks returned", l_chunks.count = 3)
			assert ("min chunk allocated", l_chunks.i_th (1).width >= 20)
			assert ("max chunk allocated within limit", l_chunks.i_th (2).width <= 15)
			assert ("flex chunk gets remainder", l_chunks.i_th (3).width > 0)
			assert ("sum of widths equals area width", l_chunks.i_th (1).width + l_chunks.i_th (2).width + l_chunks.i_th (3).width = 50)

			-- 3. Spacing with fixed constraints
			create l_area.make (0, 0, 30, 5)
			l_chunks := l_solver.split_with_spacing (
				l_area,
				<<{CONSTRAINTS}.fixed (10), {CONSTRAINTS}.fixed (10)>>,
				{SPLIT_DIRECTION}.horizontal,
				2
			)
			assert ("chunk 1 width 10", l_chunks.i_th (1).width = 10)
			assert ("chunk 2 starts after chunk 1 + spacing", l_chunks.i_th (2).x = 12)
			assert ("chunk 2 width 10", l_chunks.i_th (2).width = 10)
		end

	test_malformed_and_partial_input
			-- Test ANSI_INPUT_PARSER with malformed and incomplete escape sequences.
		local
			l_parser: ANSI_INPUT_PARSER
			l_events: ARRAYED_LIST [EVENT]
		do
			create l_parser.make

			-- 1. Malformed tilde without digits: `\e[~` (previously crashed on "".to_integer)
			l_parser.parse_string ("%/27/[~")
			l_events := l_parser.events
			assert ("malformed tilde handled safely", True)

			-- 2. Malformed CSI with empty parameters: `\e[;~`
			l_parser.wipe_out
			l_parser.parse_string ("%/27/[;~")
			l_events := l_parser.events
			assert ("empty semicolon parameter handled safely", True)

			-- 3. Malformed SGR mouse: `\e[<;M` and `\e[<1;2M` (missing parts)
			l_parser.wipe_out
			l_parser.parse_string ("%/27/[<;M")
			l_parser.parse_string ("%/27/[<1;2M")
			l_events := l_parser.events
			assert ("malformed mouse handled safely", True)

			-- 4. Partial escape sequence: `\e[` followed by normal key
			l_parser.wipe_out
			l_parser.parse_string ("%/27/[")
			-- Not yet complete, then valid ground char arrives
			l_parser.parse_code (65) -- 'A' -> CSI A (Up Arrow)
			l_events := l_parser.events
			assert ("one event from completed csi", l_events.count = 1)
			if attached {KEY_EVENT} l_events.first as ke then
				assert ("up arrow recognized", ke.code.is_up)
			end

			-- 5. ESC immediately followed by a character is Alt+character
			l_parser.wipe_out
			l_parser.parse_code (27)
			l_parser.parse_code (104) -- 'h'
			l_events := l_parser.events
			assert ("one alt event", l_events.count = 1)
			assert ("alt h", attached {KEY_EVENT} l_events.first as ke1 and then
				(ke1.code.is_char and then ke1.code.character = 'h' and ke1.modifiers.is_alt))

			-- 6. A lone ESC separated by the input timeout is Escape, then the character
			l_parser.wipe_out
			l_parser.parse_code (27)
			l_parser.flush_escape
			l_parser.parse_code (104) -- 'h'
			l_events := l_parser.events
			assert ("two events from isolated esc", l_events.count = 2)
			assert ("first is escape", attached {KEY_EVENT} l_events.first as ke2 and then ke2.code.is_escape)
			assert ("second is plain h", attached {KEY_EVENT} l_events.i_th (2) as ke3 and then
				(ke3.code.is_char and then ke3.code.character = 'h' and not ke3.modifiers.is_alt))
		end

end
