note
	description: "[
		Autotest test set for Phase 7: TABLE_CELL, TABLE_ROW, TABLE_STATE, and TUI_TABLE.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_TABLE_WIDGET

inherit
	EQA_TEST_SET

feature -- Test routines

	test_table_cell_and_row_construction
			-- Test creation, attributes, and fluent builders of TABLE_CELL and TABLE_ROW.
		local
			l_cell1, l_cell2, l_cell3: TABLE_CELL
			l_row: TABLE_ROW
			l_style: STYLE
		do
			create l_style.default_create
			create l_cell1.make_raw ("PID")
			assert ("cell1 span is 1", l_cell1.column_span = 1)
			assert ("cell1 width is 3", l_cell1.width = 3)
			assert ("cell1 left aligned", l_cell1.alignment = {TEXT_ALIGNMENT}.left)

			create l_cell2.make_styled ("Command", l_style)
			l_cell2 := l_cell2.with_column_span (2).with_alignment ({TEXT_ALIGNMENT}.center)
			assert ("cell2 span is 2", l_cell2.column_span = 2)
			assert ("cell2 center aligned", l_cell2.alignment = {TEXT_ALIGNMENT}.center)

			create l_cell3.make_raw ("CPU%%")

			create l_row.make (<<l_cell1, l_cell2, l_cell3>>)
			assert ("row cell count 3", l_row.count = 3)
			assert ("default height 1", l_row.height = 1)
			assert ("default total height 1", l_row.total_height = 1)

			l_row := l_row.with_height (2).with_top_margin (1).with_bottom_margin (1)
			assert ("row height 2", l_row.height = 2)
			assert ("row top margin 1", l_row.top_margin = 1)
			assert ("row bottom margin 1", l_row.bottom_margin = 1)
			assert ("row total height 4", l_row.total_height = 4)
		end

	test_table_state_navigation
			-- Test row and column selection navigation and viewport adjustment in TABLE_STATE.
		local
			l_state: TABLE_STATE
		do
			create l_state.make
			assert ("no initial row selection", not l_state.has_selection)
			assert ("no initial col selection", not l_state.has_column_selection)
			assert ("initial offset 1", l_state.offset = 1)
			assert ("initial col offset 1", l_state.column_offset = 1)

			-- Row navigation
			l_state.select_next (5)
			assert ("selected row 1", l_state.has_selection and l_state.selected = 1)
			l_state.select_next (5)
			assert ("selected row 2", l_state.selected = 2)
			l_state.select_last (5)
			assert ("selected row 5", l_state.selected = 5)
			l_state.select_next (5)
			assert ("clamped row 5", l_state.selected = 5)
			l_state.select_previous (5)
			assert ("selected row 4", l_state.selected = 4)
			l_state.select_first
			assert ("selected row 1", l_state.selected = 1)
			l_state.unselect
			assert ("row unselected", not l_state.has_selection and l_state.selected = 0)

			-- Column navigation
			l_state.select_next_column (3)
			assert ("selected col 1", l_state.has_column_selection and l_state.selected_column = 1)
			l_state.select_next_column (3)
			assert ("selected col 2", l_state.selected_column = 2)
			l_state.select_last_column (3)
			assert ("selected col 3", l_state.selected_column = 3)
			l_state.select_next_column (3)
			assert ("clamped col 3", l_state.selected_column = 3)
			l_state.select_previous_column (3)
			assert ("selected col 2", l_state.selected_column = 2)
			l_state.select_first_column
			assert ("selected col 1", l_state.selected_column = 1)
			l_state.unselect_column
			assert ("col unselected", not l_state.has_column_selection and l_state.selected_column = 0)

			-- Viewport adjustment
			l_state.select_index (8)
			l_state.adjust_viewport (4, 10)
			-- Selected row 8 in window of height 4 => offset should be 8 - 4 + 1 = 5
			assert ("offset adjusted for selected 8", l_state.offset = 5)

			l_state.select_index (2)
			l_state.adjust_viewport (4, 10)
			-- Selected row 2 < offset 5 => offset moves to 2
			assert ("offset adjusted for selected 2", l_state.offset = 2)
		end

	test_tui_table_rendering_stateless
			-- Test stateless rendering of a basic table with header and rows into BUFFER.
		local
			l_table: TUI_TABLE
			l_header: TABLE_ROW
			l_row1, l_row2: TABLE_ROW
			l_buffer: BUFFER
			l_area: RECT
		do
			create l_header.make_raw (<<"ID", "NAME", "STATUS">>)
			create l_row1.make_raw (<<"101", "worker", "RUNNING">>)
			create l_row2.make_raw (<<"102", "master", "IDLE">>)

			create l_table.default_create
			l_table.set_header (l_header)
			l_table.append_row (l_row1)
			l_table.append_row (l_row2)
			l_table.set_widths (<<{CONSTRAINTS}.fixed (6), {CONSTRAINTS}.fixed (10), {CONSTRAINTS}.flex (1)>>)
			l_table.set_column_spacing (2)

			create l_buffer.make (30, 4)
			create l_area.make (0, 0, 30, 4)

			l_table.render (l_area, l_buffer)

			-- Row 0: Header
			assert ("header ID", l_buffer.cell (0, 0).symbol.same_string_general ("I"))
			assert ("header NAME", l_buffer.cell (0, 8).symbol.same_string_general ("N"))
			assert ("header STATUS", l_buffer.cell (0, 20).symbol.same_string_general ("S"))

			-- Row 1: Data Row 1
			assert ("row1 101", l_buffer.cell (1, 0).symbol.same_string_general ("1"))
			assert ("row1 worker", l_buffer.cell (1, 8).symbol.same_string_general ("w"))
			assert ("row1 RUNNING", l_buffer.cell (1, 20).symbol.same_string_general ("R"))

			-- Row 2: Data Row 2
			assert ("row2 102", l_buffer.cell (2, 0).symbol.same_string_general ("1"))
			assert ("row2 master", l_buffer.cell (2, 8).symbol.same_string_general ("m"))
			assert ("row2 IDLE", l_buffer.cell (2, 20).symbol.same_string_general ("I"))
		end

	test_tui_table_stateful_selection_and_highlight
			-- Test stateful rendering with highlight symbol and row/column selection.
		local
			l_table: TUI_TABLE
			l_header: TABLE_ROW
			l_row1, l_row2: TABLE_ROW
			l_state: TABLE_STATE
			l_buffer: BUFFER
			l_area: RECT
			l_hl_style: STYLE
		do
			create l_header.make_raw (<<"KEY", "VAL">>)
			create l_row1.make_raw (<<"alpha", "10">>)
			create l_row2.make_raw (<<"beta", "20">>)

			create l_hl_style.make_fg ({COLOR}.red)

			create l_table.make (<<l_row1, l_row2>>, <<{CONSTRAINTS}.fixed (8), {CONSTRAINTS}.fixed (6)>>)
			l_table.set_header (l_header)
			l_table.set_highlight_symbol ("> ")
			l_table.set_row_highlight_style (l_hl_style)

			create l_state.make
			l_state.select_index (2) -- select second row (beta)

			create l_buffer.make (20, 4)
			create l_area.make (0, 0, 20, 4)

			l_table.render_stateful (l_area, l_buffer, l_state)

			-- Row 0: Header (shifted by highlight symbol width 2: col 2)
			assert ("header KEY", l_buffer.cell (0, 2).symbol.same_string_general ("K"))

			-- Row 1: Unselected row (alpha) - no highlight symbol at col 0
			assert ("row1 no symbol", l_buffer.cell (1, 0).symbol.same_string_general (" "))
			assert ("row1 alpha", l_buffer.cell (1, 2).symbol.same_string_general ("a"))

			-- Row 2: Selected row (beta) - has highlight symbol "> "
			assert ("row2 sym char 1", l_buffer.cell (2, 0).symbol.same_string_general (">"))
			assert ("row2 sym char 2", l_buffer.cell (2, 1).symbol.same_string_general (" "))
			assert ("row2 beta", l_buffer.cell (2, 2).symbol.same_string_general ("b"))
			assert ("row2 highlight red", l_buffer.cell (2, 2).style.foreground.is_ansi and l_buffer.cell (2, 2).style.foreground.ansi_code = {COLOR}.red.ansi_code)
		end

	test_tui_table_column_spanning
			-- Test rendering a table row with column spanning.
		local
			l_table: TUI_TABLE
			l_cell_spanned: TABLE_CELL
			l_row: TABLE_ROW
			l_buffer: BUFFER
			l_area: RECT
		do
			create l_cell_spanned.make_raw ("Spanned Across Two Columns")
			l_cell_spanned := l_cell_spanned.with_column_span (2)

			create l_row.make (<<l_cell_spanned>>)
			create l_table.make (<<l_row>>, <<{CONSTRAINTS}.fixed (10), {CONSTRAINTS}.fixed (15)>>)
			l_table.set_column_spacing (1)

			create l_buffer.make (30, 2)
			create l_area.make (0, 0, 30, 2)

			l_table.render (l_area, l_buffer)

			-- Total spanned width is 10 + 1 (spacing) + 15 = 26 characters
			assert ("first char S", l_buffer.cell (0, 0).symbol.same_string_general ("S"))
			-- Check character around column 12 (in the second column's space)
			assert ("char in second span", l_buffer.cell (0, 15).symbol.same_string_general ("T"))
		end

	test_tui_table_with_block_and_footer
			-- Test table enclosed in TUI_BLOCK with both header and footer.
		local
			l_table: TUI_TABLE
			l_block: TUI_BLOCK
			l_header, l_footer, l_row: TABLE_ROW
			l_buffer: BUFFER
			l_area: RECT
		do
			create l_block.make
			l_block.set_title_string ("Processes")

			create l_header.make_raw (<<"PID", "NAME">>)
			create l_row.make_raw (<<"1", "init">>)
			create l_footer.make_raw (<<"Total", "1 process">>)

			create l_table.make (<<l_row>>, <<{CONSTRAINTS}.fixed (8), {CONSTRAINTS}.flex (1)>>)
			l_table.set_header (l_header)
			l_table.set_footer (l_footer)
			l_table.set_block (l_block)

			create l_buffer.make (25, 5)
			create l_area.make (0, 0, 25, 5)

			l_table.render (l_area, l_buffer)

			-- Border at top-left (code 9484: '┌')
			assert ("border top-left", l_buffer.cell (0, 0).symbol.code (1) = 9484)
			-- Header at row 1 inside block
			assert ("header PID at row 1", l_buffer.cell (1, 1).symbol.same_string_general ("P"))
			-- Data row at row 2 inside block
			assert ("row init at row 2", l_buffer.cell (2, 1).symbol.same_string_general ("1"))
			-- Footer at row 3 inside block
			assert ("footer Total at row 3", l_buffer.cell (3, 1).symbol.same_string_general ("T"))
			-- Border at bottom-left (code 9492: '└')
			assert ("border bottom-left", l_buffer.cell (4, 0).symbol.code (1) = 9492)
		end

end
