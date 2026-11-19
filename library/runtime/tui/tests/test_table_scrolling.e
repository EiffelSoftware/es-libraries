note
	description: "[
		P1 item V10, TUI_TABLE `highlight_spacing` and `scroll_padding`, and the `scroll_*_by`
		commands of TABLE_STATE and LIST_STATE (review/p1_visualization_plan.md).
		The `test_ratatui_*` cases are tests of Ratatui ratatui-widgets/src/table.rs,
		table/state.rs and list/state.rs, as row-exact buffer snapshots or state assertions.
		Ratatui indexes rows and columns from 0 (`Option<usize>`); here they are 1-based, with
		`has_selection` for `Some`: Ratatui's offset 4 and selection `Some (2)` are offset 5 and
		row 3 here. Ratatui's state commands do not know the row count (the render clamps the
		selection); here they take it, as `select_next` does.
		The older table and list tests (TEST_TABLE_WIDGET, TEST_MILESTONE_F, TEST_MILESTONE_F_REVIEW,
		TEST_STATEFUL_WIDGETS) are unchanged.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_TABLE_SCROLLING

inherit
	BUFFER_TEST_HELPER

feature -- Ratatui table.rs: highlight spacing

	test_ratatui_highlight_spacing_excess_area
			-- Ratatui `excess_area_highlight_symbol_and_column_spacing_allocation`: the symbol
			-- column (">>>") is reserved with `Always`, and with `When_selected` only while a row
			-- is selected; `Never` reserves and draws nothing. The columns are Length (5) here
			-- (Ratatui's default widths split the area; see the plan's V10 deviations).
		do
			assert_buffer_lines ("never, none", spacing_buffer ({HIGHLIGHT_SPACING}.never, 15, 0, False),
				<<"ABCDE12345     ", "               ", "               ">>)
			assert_buffer_lines ("never, selected", spacing_buffer ({HIGHLIGHT_SPACING}.never, 15, 0, True),
				<<"ABCDE12345     ", "               ", "               ">>)
			assert_buffer_lines ("when selected, none", spacing_buffer ({HIGHLIGHT_SPACING}.when_selected, 15, 0, False),
				<<"ABCDE12345     ", "               ", "               ">>)
			assert_buffer_lines ("when selected, selected", spacing_buffer ({HIGHLIGHT_SPACING}.when_selected, 15, 0, True),
				<<">>>ABCDE12345  ", "               ", "               ">>)
			assert_buffer_lines ("always, none", spacing_buffer ({HIGHLIGHT_SPACING}.always, 15, 0, False),
				<<"   ABCDE12345  ", "               ", "               ">>)
			assert_buffer_lines ("always, selected", spacing_buffer ({HIGHLIGHT_SPACING}.always, 15, 0, True),
				<<">>>ABCDE12345  ", "               ", "               ">>)
			assert_buffer_lines ("always, spacing 1", spacing_buffer ({HIGHLIGHT_SPACING}.always, 15, 1, False),
				<<"   ABCDE 12345 ", "               ", "               ">>)
			assert_buffer_lines ("never, spacing 1", spacing_buffer ({HIGHLIGHT_SPACING}.never, 15, 1, True),
				<<"ABCDE 12345    ", "               ", "               ">>)
		end

	test_ratatui_highlight_spacing_insufficient_area
			-- Ratatui `insufficient_area_highlight_symbol_allocation_with_no_column_spacing` and
			-- `insufficient_area_highlight_symbol_and_column_spacing_allocation`: the symbol
			-- column is taken from the area before the columns are laid out. EiffelTUI shows the
			-- columns that fit at their width (the second column is hidden, not shrunk as in
			-- Ratatui: ">>>ABCD123" there).
		do
			assert_buffer_lines ("never, none", spacing_buffer ({HIGHLIGHT_SPACING}.never, 10, 0, False),
				<<"ABCDE12345", "          ", "          ">>)
			assert_buffer_lines ("when selected, none", spacing_buffer ({HIGHLIGHT_SPACING}.when_selected, 10, 0, False),
				<<"ABCDE12345", "          ", "          ">>)
			assert_buffer_lines ("never, selected", spacing_buffer ({HIGHLIGHT_SPACING}.never, 10, 0, True),
				<<"ABCDE12345", "          ", "          ">>)
			assert_buffer_lines ("always, none", spacing_buffer ({HIGHLIGHT_SPACING}.always, 10, 0, False),
				<<"   ABCDE  ", "          ", "          ">>)
			assert_buffer_lines ("when selected, selected", spacing_buffer ({HIGHLIGHT_SPACING}.when_selected, 10, 0, True),
				<<">>>ABCDE  ", "          ", "          ">>)
			assert_buffer_lines ("always, selected", spacing_buffer ({HIGHLIGHT_SPACING}.always, 10, 0, True),
				<<">>>ABCDE  ", "          ", "          ">>)
			assert_buffer_lines ("always, width 7", spacing_buffer ({HIGHLIGHT_SPACING}.always, 7, 1, False),
				<<"   ABCD", "       ", "       ">>)
			assert_buffer_lines ("always, symbol wider than the area", spacing_buffer ({HIGHLIGHT_SPACING}.always, 2, 0, True),
				<<">>", "  ", "  ">>)
		end

feature -- Ratatui table.rs: offset and selection

	test_ratatui_render_with_selection_and_offset
			-- Ratatui `render_with_selection_and_offset` (with the #1179 regression case): 100
			-- rows at offset 50 in a 2 x 5 buffer.
		do
			assert_offset_case ("no selection", 0, 51, <<"50", "51", "52", "53", "54">>)
			assert_offset_case ("selection before offset", 21, 21, <<"20", "21", "22", "23", "24">>)
			assert_offset_case ("selection immediately before offset", 50, 50, <<"49", "50", "51", "52", "53">>)
			assert_offset_case ("selection at start of offset", 51, 51, <<"50", "51", "52", "53", "54">>)
			assert_offset_case ("selection at end of offset", 55, 51, <<"50", "51", "52", "53", "54">>)
			assert_offset_case ("selection immediately after offset", 56, 52, <<"51", "52", "53", "54", "55">>)
			assert_offset_case ("selection after offset", 81, 77, <<"76", "77", "78", "79", "80">>)
		end

feature -- Ratatui table.rs: scroll padding

	test_ratatui_scroll_padding_with_padding
			-- Ratatui `scroll_padding_tests::with_padding`: six one-line rows; the offset after
			-- the render for each area height, offset, padding and selection. The selection is
			-- never changed by the render.
		do
			assert_padding_case ("padding scroll down", 4, 1, 1, 4, 2)
			assert_padding_case ("padding scroll up", 4, 5, 1, 3, 2)
			assert_padding_case ("no padding offset behavior", 5, 3, 0, 4, 3)
			assert_padding_case ("padding two before", 5, 3, 2, 4, 2)
			assert_padding_case ("padding keep selected visible", 4, 1, 4, 2, 1)
			assert_padding_case ("no selection no padding", 4, 3, 1, 0, 3)
			assert_padding_case ("maximum padding when all rows fit", 6, 1, {INTEGER}.max_value, 4, 1)
			assert_padding_case ("maximum padding when rows do not fit", 4, 1, {INTEGER}.max_value, 4, 2)
		end

	test_ratatui_scroll_padding_render
			-- Ratatui `scroll_padding_tests::render_with_padding`: the rows shown.
		local
			l_buf: BUFFER
			l_state: TABLE_STATE
		do
			create l_state.make
			l_state.select_index (4)
			l_buf := padding_buffer (4, l_state, 1)
			assert_buffer_lines ("basic padding", l_buf, <<"Row 1     ", "Row 2     ", "Row 3     ", "Row 4     ">>)

			create l_state.make
			l_state.set_offset (5)
			l_state.select_index (3)
			l_buf := padding_buffer (4, l_state, 1)
			assert_buffer_lines ("padding at top", l_buf, <<"Row 1     ", "Row 2     ", "Row 3     ", "Row 4     ">>)

			create l_state.make
			l_state.select_index (6)
			l_buf := padding_buffer (4, l_state, 0)
			assert_buffer_lines ("no padding", l_buf, <<"Row 2     ", "Row 3     ", "Row 4     ", "Row 5     ">>)
		end

	test_ratatui_scroll_padding_flicker
			-- Ratatui `padding_flicker`: when the selection and its padding do not fit, the
			-- offset stays the same from one render to the next.
		local
			l_table: TUI_TABLE
			l_state: TABLE_STATE
			l_buf: BUFFER
			l_first: INTEGER
		do
			l_table := numbered_table (8, "Row ", 10).with_scroll_padding (3)
			create l_state.make
			l_state.set_offset (3)
			l_state.select_index (5)
			create l_buf.make (10, 5)
			l_table.render_table (l_buf.area, l_buf, l_state)
			l_first := l_state.offset
			l_table.render_table (l_buf.area, l_buf, l_state)
			assert ("offset stable across renders", l_state.offset = l_first)
			assert ("offset", l_first = 3)
			assert_buffer_lines ("rows 2 to 6", l_buf, <<"Row 2     ", "Row 3     ", "Row 4     ", "Row 5     ", "Row 6     ">>)
		end

	test_ratatui_scroll_padding_row_heights_and_margins
			-- Ratatui `padding_inconsistent_row_heights` and `padding_with_row_margins`: the
			-- viewport is measured in lines, margins included, and the padding shrinks when the
			-- selection and its neighbours do not fit. Ratatui asserts a bound (0-based offset at
			-- most 3); the exact offsets are Ratatui's too.
		local
			l_table: TUI_TABLE
			l_state: TABLE_STATE
			l_buf: BUFFER
			i: INTEGER
		do
			l_table := numbered_table (6, "Row ", 10).with_scroll_padding (1)
			l_table.rows.i_th (5).set_height (3)
			create l_state.make
			l_state.select_index (4)
			create l_buf.make (10, 3)
			l_table.render_table (l_buf.area, l_buf, l_state)
			assert ("tall row: padding dropped, selection visible", l_state.offset = 2)
			assert_buffer_lines ("tall row", l_buf, <<"Row 1     ", "Row 2     ", "Row 3     ">>)

			l_table := numbered_table (6, "Row ", 10).with_scroll_padding (1)
			from i := 1 until i > 5 loop
				l_table.rows.i_th (i).set_bottom_margin (1)
				i := i + 1
			end
			create l_state.make
			l_state.select_index (5)
			create l_buf.make (10, 6)
			l_table.render_table (l_buf.area, l_buf, l_state)
			assert ("margins: row 3 kept above row 4", l_state.offset = 4)
			assert_buffer_lines ("margins", l_buf, <<"Row 3     ", "          ", "Row 4     ", "          ", "Row 5     ", "          ">>)
		end

feature -- Ratatui table/state.rs and list/state.rs: scroll_*_by

	test_ratatui_table_state_scroll_by
			-- The `scroll_*_by` part of Ratatui `test_table_state_navigation`, in a table of 10
			-- rows and 200 columns, then the saturation at the ends that Ratatui leaves to the
			-- render.
		local
			l_state: TABLE_STATE
		do
			create l_state.make
			l_state.select_index (3)
			l_state.scroll_down_by (4, 10)
			assert ("down 4 from 3", l_state.selected = 7)

			create l_state.make
			l_state.scroll_up_by (3, 10)
			assert ("up from none selects 1", l_state.has_selection and l_state.selected = 1)
			l_state.select_index (7)
			l_state.scroll_up_by (4, 10)
			assert ("up 4 from 7", l_state.selected = 3)
			l_state.scroll_up_by (4, 10)
			assert ("up saturates at 1", l_state.selected = 1)

			create l_state.make
			l_state.select_column (13)
			l_state.scroll_right_by (4, 200)
			assert ("right 4 from 13", l_state.selected_column = 17)
			l_state.scroll_left_by (20, 200)
			assert ("left saturates at 1", l_state.selected_column = 1)
			l_state.scroll_right_by (100, 200)
			assert ("right 100", l_state.selected_column = 101)
			l_state.scroll_left_by (20, 200)
			assert ("left 20", l_state.selected_column = 81)
			assert ("rows untouched by column scrolling", not l_state.has_selection)

			-- Saturation and edge cases
			create l_state.make
			l_state.scroll_down_by (4, 10)
			assert ("down from none starts at row 1", l_state.selected = 5)
			l_state.scroll_down_by (100, 10)
			assert ("down saturates at the last row", l_state.selected = 10)
			l_state.scroll_down_by ({INTEGER}.max_value, 10)
			assert ("no overflow", l_state.selected = 10)
			l_state.scroll_down_by (0, 10)
			assert ("down 0 keeps the row", l_state.selected = 10)
			l_state.select_index (15)
			l_state.scroll_up_by (4, 10)
			assert ("a selection past the end counts as the last row", l_state.selected = 6)
			l_state.select_index (15)
			l_state.scroll_down_by (1, 10)
			assert ("down from past the end clamps", l_state.selected = 10)
			l_state.scroll_right_by ({INTEGER}.max_value, 3)
			assert ("right from none saturates", l_state.has_column_selection and l_state.selected_column = 3)
			assert ("row untouched by column scrolling", l_state.selected = 10)

			create l_state.make
			l_state.scroll_down_by (2, 0)
			l_state.scroll_up_by (2, 0)
			l_state.scroll_right_by (2, 0)
			l_state.scroll_left_by (2, 0)
			assert ("empty table: nothing selected", not l_state.has_selection and not l_state.has_column_selection)
		end

	test_ratatui_list_state_scroll_by
			-- The `scroll_*_by` part of Ratatui `list::state::state_navigation`, in a list of 10
			-- items, then the saturation at the ends.
		local
			l_state: LIST_STATE
		do
			create l_state.make
			l_state.select_index (3)
			l_state.scroll_down_by (4, 10)
			assert ("down 4 from 3", l_state.selected = 7)

			create l_state.make
			l_state.scroll_up_by (3, 10)
			assert ("up from none selects 1", l_state.has_selection and l_state.selected = 1)
			l_state.select_index (7)
			l_state.scroll_up_by (4, 10)
			assert ("up 4 from 7", l_state.selected = 3)
			l_state.scroll_up_by (4, 10)
			assert ("up saturates at 1", l_state.selected = 1)

			l_state.scroll_down_by (100, 10)
			assert ("down saturates at the last item", l_state.selected = 10)
			l_state.scroll_up_by ({INTEGER}.max_value, 10)
			assert ("up saturates without overflow", l_state.selected = 1)

			create l_state.make
			l_state.scroll_down_by (3, 0)
			assert ("empty list: nothing selected", not l_state.has_selection)
		end

feature -- EiffelTUI cases

	test_table_scrolls_by_lines
			-- Rows taller than one line: the viewport is measured in lines, so the selected last
			-- row is shown (the old count-based viewport scrolled by rows and hid it).
		local
			l_table: TUI_TABLE
			l_state: TABLE_STATE
			l_buf: BUFFER
			i: INTEGER
		do
			l_table := numbered_table (5, "R", 4)
			from i := 1 until i > 5 loop
				l_table.rows.i_th (i).set_height (2)
				i := i + 1
			end
			create l_state.make
			l_state.select_index (5)
			create l_buf.make (4, 4)
			l_table.render_table (l_buf.area, l_buf, l_state)
			assert ("offset 4", l_state.offset = 4)
			assert_buffer_lines ("rows 4 and 5", l_buf, <<"R3  ", "    ", "R4  ", "    ">>)
		end

	test_table_padding_with_header_symbol_and_column_selection
			-- Padding counts body lines only (header and footer stay), the symbol column is
			-- reserved, and the selected column still scrolls into view.
		local
			l_table: TUI_TABLE
			l_state: TABLE_STATE
			l_buf: BUFFER
			i: INTEGER
		do
			create l_table.make_empty
			from i := 0 until i > 9 loop
				l_table.append_row (create {TABLE_ROW}.make_raw (<<"r" + i.out, "c" + i.out>>))
				i := i + 1
			end
			l_table.set_widths (<<{CONSTRAINTS}.fixed (2), {CONSTRAINTS}.fixed (2)>>)
			l_table.set_header (create {TABLE_ROW}.make_raw (<<"H1", "H2">>))
			l_table.set_footer (create {TABLE_ROW}.make_raw (<<"F1", "F2">>))
			l_table.set_highlight_symbol (">")
			l_table := l_table.with_scroll_padding (1).with_highlight_spacing ({HIGHLIGHT_SPACING}.always)
			create l_state.make
			l_state.scroll_down_by (5, l_table.count)
			l_state.scroll_right_by (1, l_table.column_count)
			create l_buf.make (6, 5)
			l_table.render_table (l_buf.area, l_buf, l_state)
			assert ("row 6 selected", l_state.selected = 6)
			assert ("column 2 selected", l_state.selected_column = 2)
			assert ("offset 5: one row before, one after", l_state.offset = 5)
			assert_buffer_lines ("padded rows", l_buf, <<" H1 H2", " r4 c4", ">r5 c5", " r6 c6", " F1 F2">>)

			-- Without a selection the column is still reserved
			l_state.unselect
			l_state.unselect_column
			create l_buf.make (6, 5)
			l_table.render_table (l_buf.area, l_buf, l_state)
			assert_buffer_lines ("always reserved", l_buf, <<" H1 H2", " r4 c4", " r5 c5", " r6 c6", " F1 F2">>)
		end

	test_table_offset_kept_near_end
			-- Unlike TUI_LIST, the table keeps an offset near the end (Ratatui), and a selection
			-- past the last row scrolls to the last row.
		local
			l_table: TUI_TABLE
			l_state: TABLE_STATE
			l_buf: BUFFER
		do
			l_table := numbered_table (6, "Row ", 10)
			create l_state.make
			l_state.set_offset (5)
			create l_buf.make (10, 4)
			l_table.render_table (l_buf.area, l_buf, l_state)
			assert ("offset kept", l_state.offset = 5)
			assert_buffer_lines ("blank lines at the end", l_buf, <<"Row 4     ", "Row 5     ", "          ", "          ">>)

			create l_state.make
			l_state.select_index (20)
			create l_buf.make (10, 4)
			l_table.render_table (l_buf.area, l_buf, l_state)
			assert ("selection past the end shows the last rows", l_state.offset = 3)
			assert ("selection unchanged", l_state.selected = 20)

			-- The state's own feature with one-line rows
			create l_state.make
			l_state.select_index (8)
			l_state.adjust_viewport_with_padding (4, 10, 2)
			assert ("padding 2 below row 8 does not fit, 1 does", l_state.offset = 6)
			l_state.select_index (3)
			l_state.adjust_viewport_with_padding (4, 10, 2)
			assert ("padding 2 above row 3, reduced to 1", l_state.offset = 2)
		end

	test_row_viewport_arithmetic
			-- ROW_VIEWPORT, shared by LIST_STATE and TABLE_STATE.
		local
			l_heights: ARRAYED_LIST [INTEGER]
		do
			create l_heights.make (6)
			l_heights.extend (1)
			l_heights.extend (1)
			l_heights.extend (1)
			l_heights.extend (1)
			l_heights.extend (3)
			l_heights.extend (1)
			assert ("rows between", {ROW_VIEWPORT}.rows_between (l_heights, 2, 5) = 6)
			assert ("empty range", {ROW_VIEWPORT}.rows_between (l_heights, 4, 3) = 0)
			assert ("padding reduced to 0", {ROW_VIEWPORT}.fitting_padding (l_heights, 4, 3, 1) = 0)
			assert ("padding kept", {ROW_VIEWPORT}.fitting_padding (l_heights, 2, 3, 1) = 1)
			assert ("huge padding fits all", {ROW_VIEWPORT}.fitting_padding (l_heights, 3, 8, {INTEGER}.max_value) = 6)
			assert ("no selection keeps the offset", {ROW_VIEWPORT}.adjusted_offset (l_heights, 5, 0, 3, 1, False) = 5)
			assert ("fill end moves back", {ROW_VIEWPORT}.adjusted_offset (l_heights, 5, 0, 5, 0, True) = 4)
			assert ("offset past the end clamps", {ROW_VIEWPORT}.adjusted_offset (l_heights, 50, 0, 3, 0, False) = 6)
			assert ("tall selection at offset", {ROW_VIEWPORT}.adjusted_offset (l_heights, 1, 5, 2, 0, False) = 5)
			l_heights.wipe_out
			assert ("empty: offset 1", {ROW_VIEWPORT}.adjusted_offset (l_heights, 7, 3, 3, 1, True) = 1)

			assert ("down", {ROW_VIEWPORT}.index_down_by (2, 3, 10) = 5)
			assert ("down from none", {ROW_VIEWPORT}.index_down_by (0, 3, 10) = 4)
			assert ("down saturates", {ROW_VIEWPORT}.index_down_by (9, {INTEGER}.max_value, 10) = 10)
			assert ("up", {ROW_VIEWPORT}.index_up_by (5, 3, 10) = 2)
			assert ("up from none", {ROW_VIEWPORT}.index_up_by (0, 3, 10) = 1)
			assert ("up from past the end", {ROW_VIEWPORT}.index_up_by (30, 3, 10) = 7)
			assert ("up saturates", {ROW_VIEWPORT}.index_up_by (5, {INTEGER}.max_value, 10) = 1)
		end

	test_row_viewport_matches_reference
			-- Review fix #4: `adjusted_offset` walks back from the last item that must show
			-- instead of stepping the offset and summing the rows again at each step. It must give
			-- exactly the offsets of the old loops (`reference_offset`), for every small case:
			-- 0 to 8 items of mixed heights, every offset and selection (with one past each end),
			-- viewports of 1 to 6 rows, paddings 0 to 3 and a huge one, with and without fill end.
		local
			l_heights: ARRAYED_LIST [INTEGER]
			n, l_seed, l_offset, l_selected, l_rows, l_pad_index, l_pad, l_cases: INTEGER
			l_fill: BOOLEAN
			l_ok: BOOLEAN
		do
			l_ok := True
			from l_seed := 1 until l_seed > 4 or not l_ok loop
				from n := 0 until n > 8 or not l_ok loop
					create l_heights.make (n)
					across 1 |..| n as i loop
						l_heights.extend (1 + (i * l_seed + l_seed // 2) \\ 3)
					end
					from l_offset := 0 until l_offset > n + 1 or not l_ok loop
						from l_selected := 0 until l_selected > n + 1 or not l_ok loop
							from l_rows := 1 until l_rows > 6 or not l_ok loop
								from l_pad_index := 0 until l_pad_index > 4 or not l_ok loop
									if l_pad_index = 4 then l_pad := {INTEGER}.max_value else l_pad := l_pad_index end
									across <<False, True>> as f loop
										l_fill := f
										l_cases := l_cases + 1
										if {ROW_VIEWPORT}.adjusted_offset (l_heights, l_offset, l_selected, l_rows, l_pad, l_fill)
											/= reference_offset (l_heights, l_offset, l_selected, l_rows, l_pad, l_fill)
										then
											l_ok := False
											assert ("same offset as the reference: seed " + l_seed.out + " n " + n.out + " offset " + l_offset.out
												+ " selected " + l_selected.out + " rows " + l_rows.out + " padding " + l_pad.out + " fill " + l_fill.out, False)
										end
									end
									l_pad_index := l_pad_index + 1
								end
								l_rows := l_rows + 1
							end
							l_selected := l_selected + 1
						end
						l_offset := l_offset + 1
					end
					n := n + 1
				end
				l_seed := l_seed + 1
			end
				-- 4 seeds x (2^2 + ... + 10^2 offset and selection pairs) x 6 viewports x 5 paddings x 2
			assert ("all 92 160 cases compared", l_ok and l_cases = 92_160)
		end

	test_row_viewport_cost_does_not_grow_with_rows
			-- Review fix #4: jumping from row 1 to the last of 1 000 000 rows reads only the
			-- heights near the end (the old code built a list of every height each frame and
			-- stepped the offset down one row at a time, summing the rows again at each step).
			-- A real 50 000-row TUI_TABLE renders its last row after such a jump, fast.
		local
			l_reads: CELL [INTEGER]
			l_offset: INTEGER
			l_table: TUI_TABLE
			l_state: TABLE_STATE
			l_buf: BUFFER
			l_start, l_elapsed: INTEGER_64
		do
			create l_reads.put (0)
			l_offset := {ROW_VIEWPORT}.adjusted_offset_by (1_000_000, agent counted_height (l_reads, ?), 1, 1_000_000, 10, 2, False)
			assert ("last ten rows shown", l_offset = 999_991)
			assert ("few heights read", l_reads.item <= 40)
			l_reads.put (0)
			l_offset := {ROW_VIEWPORT}.adjusted_offset_by (1_000_000, agent counted_height (l_reads, ?), 999_991, 0, 10, 0, True)
			assert ("fill end near the end", l_offset = 999_991 and l_reads.item <= 20)

			l_table := numbered_table (50_000, "", 6)
			create l_state.make
			l_state.select_index (50_000)
			create l_buf.make (6, 4)
			l_start := {MONOTONIC_CLOCK}.milliseconds
			l_table.render_table (l_buf.area, l_buf, l_state)
			l_elapsed := {MONOTONIC_CLOCK}.milliseconds - l_start
			assert ("offset at the end", l_state.offset = 49_997)
			assert_buffer_lines ("last rows", l_buf, <<"49996 ", "49997 ", "49998 ", "49999 ">>)
			assert ("render under 1 s", l_elapsed < 1000)
		end

	test_table_spacing_and_padding_equality_and_copy
			-- Defaults keep the old behaviour; the `with_*` builders return changed twins and
			-- leave the original alone; `is_equal` and `copy` include both settings;
			-- HIGHLIGHT_SPACING.should_add.
		local
			l_table, l_other: TUI_TABLE
		do
			l_table := numbered_table (3, "x", 3)
			assert ("default spacing", l_table.highlight_spacing = {HIGHLIGHT_SPACING}.when_selected)
			assert ("default padding", l_table.scroll_padding = 0)

			l_other := l_table.with_highlight_spacing ({HIGHLIGHT_SPACING}.never)
			assert ("twin spacing", l_other.highlight_spacing = {HIGHLIGHT_SPACING}.never)
			assert ("original spacing", l_table.highlight_spacing = {HIGHLIGHT_SPACING}.when_selected)
			assert ("spacing in is_equal", not l_other.is_equal (l_table))
			l_other.set_highlight_spacing ({HIGHLIGHT_SPACING}.when_selected)
			assert ("equal again", l_other.is_equal (l_table))

			l_other := l_table.with_scroll_padding (2)
			assert ("twin padding", l_other.scroll_padding = 2)
			assert ("original padding", l_table.scroll_padding = 0)
			assert ("padding in is_equal", not l_other.is_equal (l_table))
			l_table.copy (l_other)
			assert ("copy takes padding", l_table.scroll_padding = 2 and l_table.is_equal (l_other))

			assert ("always", {HIGHLIGHT_SPACING}.should_add ({HIGHLIGHT_SPACING}.always, False))
			assert ("when selected, none", not {HIGHLIGHT_SPACING}.should_add ({HIGHLIGHT_SPACING}.when_selected, False))
			assert ("when selected, selected", {HIGHLIGHT_SPACING}.should_add ({HIGHLIGHT_SPACING}.when_selected, True))
			assert ("never", not {HIGHLIGHT_SPACING}.should_add ({HIGHLIGHT_SPACING}.never, True))
		end

	test_table_preconditions
			-- A negative padding or amount and an unknown spacing are refused.
		local
			l_table: TUI_TABLE
			l_state: TABLE_STATE
			l_list_state: LIST_STATE
		do
			create l_table.make_empty
			assert ("negative padding refused", raises (agent l_table.set_scroll_padding (-1)))
			assert ("negative padding refused by the builder", raises (agent (t: TUI_TABLE) do t.with_scroll_padding (-1).do_nothing end (l_table)))
			assert ("spacing 0 refused", raises (agent l_table.set_highlight_spacing (0)))
			assert ("spacing 4 refused", raises (agent (t: TUI_TABLE) do t.with_highlight_spacing (4).do_nothing end (l_table)))
			create l_state.make
			assert ("negative amount refused", raises (agent l_state.scroll_down_by (-1, 5)))
			assert ("negative column amount refused", raises (agent l_state.scroll_left_by (-1, 5)))
			assert ("negative state padding refused", raises (agent l_state.adjust_viewport_with_padding (3, 5, -1)))
			create l_list_state.make
			assert ("negative list amount refused", raises (agent l_list_state.scroll_up_by (-1, 5)))
		end

feature {NONE} -- Helpers

	spacing_buffer (a_spacing, a_width: INTEGER; a_column_spacing: NATURAL_16; a_selected: BOOLEAN): BUFFER
			-- Ratatui `test_table_with_selection`: one row "ABCDE" | "12345" (Length (5) columns)
			-- with symbol ">>>", rendered in `a_width` x 3
		local
			l_table: TUI_TABLE
			l_state: TABLE_STATE
		do
			create l_table.make_empty
			l_table.append_row (create {TABLE_ROW}.make_raw (<<"ABCDE", "12345">>))
			l_table.set_widths (<<{CONSTRAINTS}.fixed (5), {CONSTRAINTS}.fixed (5)>>)
			l_table.set_highlight_symbol (">>>")
			l_table.set_column_spacing (a_column_spacing)
			l_table := l_table.with_highlight_spacing (a_spacing)
			create l_state.make
			if a_selected then
				l_state.select_index (1)
			end
			create Result.make (a_width, 3)
			l_table.render_table (Result.area, Result, l_state)
		end

	numbered_table (a_count: INTEGER; a_prefix: STRING; a_width: INTEGER): TUI_TABLE
			-- Table of `a_count` one-column rows `a_prefix` + 0, 1, ... in a Length (`a_width`) column
		local
			i: INTEGER
		do
			create Result.make_empty
			from i := 0 until i >= a_count loop
				Result.append_row (create {TABLE_ROW}.make_raw (<<a_prefix + i.out>>))
				i := i + 1
			end
			Result.set_widths (<<{CONSTRAINTS}.fixed (a_width.to_natural_16)>>)
		end

	assert_offset_case (a_tag: STRING; a_selected, a_expected_offset: INTEGER; a_expected: ARRAY [STRING])
			-- 100 rows "0" .. "99" at offset 51, row `a_selected` selected (0: none), in a 2 x 5
			-- buffer: the rows shown and the offset after the render
		local
			l_table: TUI_TABLE
			l_state: TABLE_STATE
			l_buf: BUFFER
		do
			l_table := numbered_table (100, "", 2)
			create l_state.make
			l_state.set_offset (51)
			if a_selected > 0 then
				l_state.select_index (a_selected)
			end
			create l_buf.make (2, 5)
			l_table.render_table (l_buf.area, l_buf, l_state)
			assert_buffer_lines (a_tag, l_buf, a_expected)
			assert (a_tag + ": offset", l_state.offset = a_expected_offset)
		end

	assert_padding_case (a_tag: STRING; a_height, a_offset, a_padding, a_selected, a_expected_offset: INTEGER)
			-- Ratatui `with_padding`: six rows, the offset after one render
		local
			l_state: TABLE_STATE
			l_buf: BUFFER
		do
			create l_state.make
			l_state.set_offset (a_offset)
			if a_selected > 0 then
				l_state.select_index (a_selected)
			end
			l_buf := padding_buffer (a_height, l_state, a_padding)
			assert (a_tag + ": offset", l_state.offset = a_expected_offset)
			if a_selected > 0 then
				assert (a_tag + ": selection kept", l_state.has_selection and l_state.selected = a_selected)
			else
				assert (a_tag + ": still no selection", not l_state.has_selection)
			end
		end

	padding_buffer (a_height: INTEGER; a_state: TABLE_STATE; a_padding: INTEGER): BUFFER
			-- Six rows "Row 0" .. "Row 5" (Length (10)) with `a_padding`, rendered in 10 x `a_height`
		do
			create Result.make (10, a_height)
			numbered_table (6, "Row ", 10).with_scroll_padding (a_padding).render_table (Result.area, Result, a_state)
		end

	counted_height (a_reads: CELL [INTEGER]; a_index: INTEGER): INTEGER
			-- Height 1 for every item, counting the reads in `a_reads`
		do
			a_reads.put (a_reads.item + 1)
			Result := 1
		end

	reference_offset (a_heights: ARRAYED_LIST [INTEGER]; a_offset, a_selected, a_visible_rows, a_padding: INTEGER;
			a_fill_end: BOOLEAN): INTEGER
			-- `{ROW_VIEWPORT}.adjusted_offset` as it was before review fix #4: the padding reduced
			-- one step at a time, then the offset stepped down and the rows summed again each step.
		local
			n, s, l_pad, l_first, l_last: INTEGER
		do
			n := a_heights.count
			if n = 0 then
				Result := 1
			else
				Result := a_offset.max (1).min (n)
				if a_selected > 0 then
					s := a_selected.min (n)
					from
						l_pad := a_padding.min (n)
					until
						l_pad = 0 or else {ROW_VIEWPORT}.rows_between (a_heights, (s - l_pad).max (1), (s + l_pad).min (n)) <= a_visible_rows
					loop
						l_pad := l_pad - 1
					end
					l_first := (s - l_pad).max (1)
					l_last := (s + l_pad).min (n)
					if Result > l_first then
						Result := l_first
					end
					from
					until
						Result >= s or else {ROW_VIEWPORT}.rows_between (a_heights, Result, l_last) <= a_visible_rows
					loop
						Result := Result + 1
					end
				end
				if a_fill_end then
					from
					until
						Result <= 1 or else {ROW_VIEWPORT}.rows_between (a_heights, Result - 1, n) > a_visible_rows
					loop
						Result := Result - 1
					end
				end
			end
		end

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

end
