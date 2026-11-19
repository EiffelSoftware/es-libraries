note
	description: "[
		Mutable state for TUI_TABLE, tracking selected row (1-based index),
		vertical row scroll offset, selected column (1-based index), and horizontal column scroll offset.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TABLE_STATE

inherit
	WIDGET_STATE
		redefine
			default_create
		end

create
	default_create,
	make

feature {NONE} -- Initialization

	default_create
			-- Initialize table state with no selection and offsets at 1.
		do
			has_selection := False
			selected := 0
			offset := 1
			has_column_selection := False
			selected_column := 0
			column_offset := 1
		ensure then
			no_selection: not has_selection
			zero_selected: selected = 0
			offset_at_start: offset = 1
			no_column_selection: not has_column_selection
			zero_selected_column: selected_column = 0
			column_offset_at_start: column_offset = 1
		end

	make
			-- Synonym for `default_create`.
		do
			default_create
		end

feature -- Access: Row Selection & Scrolling

	has_selection: BOOLEAN
			-- Is any row currently selected?

	selected: INTEGER
			-- 1-based index of the currently selected row, or 0 if none

	offset: INTEGER
			-- 1-based index of the first row visible in the viewport

feature -- Access: Column Selection & Scrolling

	has_column_selection: BOOLEAN
			-- Is any column currently selected?

	selected_column: INTEGER
			-- 1-based index of the currently selected column, or 0 if none

	column_offset: INTEGER
			-- 1-based index of the first column visible in the viewport

feature -- Element change: Row

	select_index (a_index: INTEGER)
			-- Select row at 1-based `a_index`.
		require
			positive_index: a_index > 0
		do
			has_selection := True
			selected := a_index
		ensure
			has_selection: has_selection
			selected_set: selected = a_index
		end

	unselect
			-- Deselect current row selection.
		do
			has_selection := False
			selected := 0
		ensure
			no_selection: not has_selection
			selected_zero: selected = 0
		end

	set_offset (a_offset: INTEGER)
			-- Set vertical row scroll offset.
		require
			positive_offset: a_offset >= 1
		do
			offset := a_offset
		ensure
			offset_set: offset = a_offset
		end

feature -- Element change: Column

	select_column (a_index: INTEGER)
			-- Select column at 1-based `a_index`.
		require
			positive_index: a_index > 0
		do
			has_column_selection := True
			selected_column := a_index
		ensure
			has_column_selection: has_column_selection
			selected_column_set: selected_column = a_index
		end

	unselect_column
			-- Deselect current column selection.
		do
			has_column_selection := False
			selected_column := 0
		ensure
			no_column_selection: not has_column_selection
			selected_column_zero: selected_column = 0
		end

	set_column_offset (a_offset: INTEGER)
			-- Set horizontal column scroll offset.
		require
			positive_offset: a_offset >= 1
		do
			column_offset := a_offset
		ensure
			column_offset_set: column_offset = a_offset
		end

feature -- Navigation: Row

	select_next (a_total_count: INTEGER)
			-- Move row selection down to the next row, clamping at `a_total_count`.
		do
			if a_total_count > 0 then
				if not has_selection then
					select_index (1)
				elseif selected < a_total_count then
					selected := selected + 1
				end
			end
		ensure
			selection_valid: has_selection implies (selected >= 1 and selected <= a_total_count)
		end

	select_previous (a_total_count: INTEGER)
			-- Move row selection up to the previous row, clamping at 1.
		do
			if a_total_count > 0 then
				if not has_selection then
					select_index (a_total_count)
				elseif selected > 1 then
					selected := selected - 1
				end
			end
		ensure
			selection_valid: has_selection implies (selected >= 1 and selected <= a_total_count)
		end

	select_first
			-- Select the first row.
		do
			select_index (1)
		ensure
			selected_first: selected = 1
		end

	select_last (a_total_count: INTEGER)
			-- Select the last row.
		require
			positive_count: a_total_count > 0
		do
			select_index (a_total_count)
		ensure
			selected_last: selected = a_total_count
		end

feature -- Navigation: Column

	select_next_column (a_total_columns: INTEGER)
			-- Move column selection right to next column, clamping at `a_total_columns`.
		do
			if a_total_columns > 0 then
				if not has_column_selection then
					select_column (1)
				elseif selected_column < a_total_columns then
					selected_column := selected_column + 1
				end
			end
		ensure
			selection_valid: has_column_selection implies (selected_column >= 1 and selected_column <= a_total_columns)
		end

	select_previous_column (a_total_columns: INTEGER)
			-- Move column selection left to previous column, clamping at 1.
		do
			if a_total_columns > 0 then
				if not has_column_selection then
					select_column (a_total_columns)
				elseif selected_column > 1 then
					selected_column := selected_column - 1
				end
			end
		ensure
			selection_valid: has_column_selection implies (selected_column >= 1 and selected_column <= a_total_columns)
		end

	select_first_column
			-- Select first column.
		do
			select_column (1)
		ensure
			selected_first_column: selected_column = 1
		end

	select_last_column (a_total_columns: INTEGER)
			-- Select last column.
		require
			positive_columns: a_total_columns > 0
		do
			select_column (a_total_columns)
		ensure
			selected_last_column: selected_column = a_total_columns
		end

feature -- Viewport Scrolling

	adjust_viewport (a_visible_height: INTEGER; a_total_count: INTEGER)
			-- Automatically adjust `offset` so that `selected` is within the visible window
			-- of `a_visible_height` one-line rows.
		require
			positive_height: a_visible_height > 0 and a_visible_height < {INTEGER}.max_value
		do
			adjust_viewport_with_padding (a_visible_height, a_total_count, 0)
		ensure
			offset_valid: offset >= 1
		end

	adjust_viewport_with_padding (a_visible_height: INTEGER; a_total_count: INTEGER; a_padding: INTEGER)
			-- Adjust `offset` for `a_total_count` one-line rows shown in `a_visible_height` rows,
			-- keeping up to `a_padding` rows visible before and after the selection.
		require
			positive_height: a_visible_height > 0 and a_visible_height < {INTEGER}.max_value
			non_negative_padding: a_padding >= 0
		do
			adjust_viewport_by_heights (a_total_count.max (0), agent (i: INTEGER): INTEGER do Result := 1 end,
				a_visible_height, a_padding)
		ensure
			offset_valid: offset >= 1
		end

	adjust_viewport_by_heights (a_count: INTEGER; a_height: FUNCTION [INTEGER, INTEGER]; a_visible_rows: INTEGER; a_padding: INTEGER)
			-- `adjust_viewport_for_rows` for `a_count` rows, row `i` taking `a_height (i)` lines
			-- (at least 1, margins included). Only the heights around the selection are read, so
			-- the cost does not grow with `a_count` (`{ROW_VIEWPORT}.adjusted_offset_by`).
		require
			height_not_void: a_height /= Void
			non_negative_count: a_count >= 0
			positive_rows: a_visible_rows > 0 and a_visible_rows < {INTEGER}.max_value
			non_negative_padding: a_padding >= 0
		do
			offset := {ROW_VIEWPORT}.adjusted_offset_by (a_count, a_height, offset, selected, a_visible_rows, a_padding, False)
		ensure
			offset_valid: offset >= 1
			offset_in_table: a_count > 0 implies offset <= a_count
		end

	adjust_viewport_for_rows (a_heights: ARRAYED_LIST [INTEGER]; a_visible_rows: INTEGER; a_padding: INTEGER)
			-- Adjust `offset` for rows of `a_heights` lines each (margins included) shown in
			-- `a_visible_rows` lines: the selected row is fully visible with up to `a_padding` rows
			-- around it (the padding is reduced when that block would not fit). Unlike LIST_STATE,
			-- an offset near the end is kept even when it leaves blank lines (Ratatui `Table`);
			-- see `{ROW_VIEWPORT}.adjusted_offset`.
		require
			positive_rows: a_visible_rows > 0 and a_visible_rows < {INTEGER}.max_value
			non_negative_padding: a_padding >= 0
			positive_heights: across a_heights as h all h >= 1 end
		do
			offset := {ROW_VIEWPORT}.adjusted_offset (a_heights, offset, selected, a_visible_rows, a_padding, False)
		ensure
			offset_valid: offset >= 1
			offset_in_table: a_heights.count > 0 implies offset <= a_heights.count
		end

	adjust_column_viewport (a_visible_columns: INTEGER; a_total_columns: INTEGER)
			-- Automatically adjust `column_offset` so that `selected_column` is within the visible window.
		require
			positive_columns: a_visible_columns > 0
		do
			if a_total_columns <= 0 then
				column_offset := 1
			else
				if has_column_selection then
					if selected_column < column_offset then
						column_offset := selected_column
					elseif selected_column >= column_offset + a_visible_columns then
						column_offset := selected_column - a_visible_columns + 1
					end
				end
				column_offset := column_offset.max (1).min (a_total_columns)
			end
		ensure
			column_offset_valid: column_offset >= 1
		end

feature -- Scrolling

	scroll_down_by (a_amount: INTEGER; a_total_count: INTEGER)
			-- Move the row selection down by `a_amount` rows, saturating at `a_total_count`; with
			-- no row selected, start from row 1 (Ratatui `TableState::scroll_down_by`).
			-- Nothing happens when the table has no rows.
		require
			non_negative_amount: a_amount >= 0
		do
			if a_total_count > 0 then
				select_index ({ROW_VIEWPORT}.index_down_by (selected, a_amount, a_total_count))
			end
		ensure
			selected_when_not_empty: a_total_count > 0 implies has_selection
			selection_valid: a_total_count > 0 implies (selected >= 1 and selected <= a_total_count)
			unchanged_when_empty: a_total_count <= 0 implies (selected = old selected and has_selection = old has_selection)
			column_unchanged: selected_column = old selected_column
		end

	scroll_up_by (a_amount: INTEGER; a_total_count: INTEGER)
			-- Move the row selection up by `a_amount` rows, saturating at row 1; with no row
			-- selected, select row 1 (Ratatui `TableState::scroll_up_by`).
			-- Nothing happens when the table has no rows.
		require
			non_negative_amount: a_amount >= 0
		do
			if a_total_count > 0 then
				select_index ({ROW_VIEWPORT}.index_up_by (selected, a_amount, a_total_count))
			end
		ensure
			selected_when_not_empty: a_total_count > 0 implies has_selection
			selection_valid: a_total_count > 0 implies (selected >= 1 and selected <= a_total_count)
			unchanged_when_empty: a_total_count <= 0 implies (selected = old selected and has_selection = old has_selection)
			column_unchanged: selected_column = old selected_column
		end

	scroll_right_by (a_amount: INTEGER; a_total_columns: INTEGER)
			-- Move the column selection right by `a_amount` columns, saturating at
			-- `a_total_columns`; with no column selected, start from column 1
			-- (Ratatui `TableState::scroll_right_by`). Nothing happens when there are no columns.
		require
			non_negative_amount: a_amount >= 0
		do
			if a_total_columns > 0 then
				select_column ({ROW_VIEWPORT}.index_down_by (selected_column, a_amount, a_total_columns))
			end
		ensure
			selected_when_not_empty: a_total_columns > 0 implies has_column_selection
			selection_valid: a_total_columns > 0 implies (selected_column >= 1 and selected_column <= a_total_columns)
			unchanged_when_empty: a_total_columns <= 0 implies (selected_column = old selected_column and has_column_selection = old has_column_selection)
			row_unchanged: selected = old selected
		end

	scroll_left_by (a_amount: INTEGER; a_total_columns: INTEGER)
			-- Move the column selection left by `a_amount` columns, saturating at column 1; with
			-- no column selected, select column 1 (Ratatui `TableState::scroll_left_by`).
			-- Nothing happens when there are no columns.
		require
			non_negative_amount: a_amount >= 0
		do
			if a_total_columns > 0 then
				select_column ({ROW_VIEWPORT}.index_up_by (selected_column, a_amount, a_total_columns))
			end
		ensure
			selected_when_not_empty: a_total_columns > 0 implies has_column_selection
			selection_valid: a_total_columns > 0 implies (selected_column >= 1 and selected_column <= a_total_columns)
			unchanged_when_empty: a_total_columns <= 0 implies (selected_column = old selected_column and has_column_selection = old has_column_selection)
			row_unchanged: selected = old selected
		end

invariant
	valid_selection_state: has_selection implies selected >= 1
	offset_positive: offset >= 1
	valid_column_selection_state: has_column_selection implies selected_column >= 1
	column_offset_positive: column_offset >= 1

end
