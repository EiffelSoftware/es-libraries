note
	description: "[
		Contiguous sequence of changed cells on a single row to be output
		to the terminal backend as a single batched operation.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	DIFF_SPAN

create
	make

feature {NONE} -- Initialization

	make (a_row, a_start_col: INTEGER; a_capacity: INTEGER)
			-- Initialize span at (`a_row`, `a_start_col`).
		require
			non_negative_row: a_row >= 0
			non_negative_col: a_start_col >= 0
			positive_capacity: a_capacity > 0
		do
			row := a_row
			start_col := a_start_col
			create cells.make (a_capacity)
		ensure
			row_set: row = a_row
			start_col_set: start_col = a_start_col
			empty_initially: cells.is_empty
		end

feature -- Access

	row: INTEGER
			-- 0-based screen row

	start_col: INTEGER
			-- 0-based start column

	cells: ARRAYED_LIST [TERMINAL_CELL]
			-- Sequence of cells in this span

	count: INTEGER
			-- Number of cells in span
		do
			Result := cells.count
		end

	end_col: INTEGER
			-- 0-based end column (inclusive)
		require
			not_empty: count > 0
		do
			Result := start_col + count - 1
		end

feature -- Element change

	reset (a_row, a_start_col: INTEGER)
			-- Reset span location and clear cell storage for reuse.
		require
			non_negative_row: a_row >= 0
			non_negative_col: a_start_col >= 0
		do
			row := a_row
			start_col := a_start_col
			cells.wipe_out
		ensure
			row_set: row = a_row
			start_col_set: start_col = a_start_col
			empty_cells: cells.is_empty
		end

	extend (a_cell: TERMINAL_CELL)
			-- Append `a_cell` to span.
		do
			cells.extend (a_cell)
		ensure
			count_increased: count = old count + 1
		end

invariant
	non_negative_row: row >= 0
	non_negative_col: start_col >= 0

end
