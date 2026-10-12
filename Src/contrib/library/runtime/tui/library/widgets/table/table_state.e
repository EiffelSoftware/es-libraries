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
			-- Automatically adjust `offset` so that `selected` is within the visible window.
		require
			positive_height: a_visible_height > 0
		do
			if a_total_count <= 0 then
				offset := 1
			else
				if has_selection then
					if selected < offset then
						offset := selected
					elseif selected >= offset + a_visible_height then
						offset := selected - a_visible_height + 1
					end
				end
				offset := offset.max (1).min (a_total_count)
			end
		ensure
			offset_valid: offset >= 1
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

invariant
	valid_selection_state: has_selection implies selected >= 1
	offset_positive: offset >= 1
	valid_column_selection_state: has_column_selection implies selected_column >= 1
	column_offset_positive: column_offset >= 1

end
