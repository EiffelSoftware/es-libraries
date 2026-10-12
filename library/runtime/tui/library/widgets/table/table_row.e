note
	description: "[
		A single row in a TUI_TABLE containing an ordered sequence of TABLE_CELLs,
		with configurable row height, margins, and row-level style.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TABLE_ROW

inherit
	ANY
		redefine
			default_create,
			copy,
			is_equal,
			out
		end

create
	default_create,
	make_empty,
	make,
	make_raw

feature -- Duplication

	copy (a_other: like Current)
			-- Re-create cells list on copy.
		local
			l_cells: ARRAYED_LIST [TABLE_CELL]
		do
			if a_other /= Current then
				standard_copy (a_other)
				create l_cells.make (a_other.cells.count)
				across a_other.cells as c loop
					l_cells.extend (c.twin)
				end
				cells := l_cells
			end
		end

	is_equal (a_other: like Current): BOOLEAN
			-- Is `a_other` content-equal to `Current`?
		local
			i: INTEGER
		do
			if a_other = Current then
				Result := True
			elseif standard_is_equal (a_other) then
				Result := True
			elseif height = a_other.height
				and top_margin = a_other.top_margin
				and bottom_margin = a_other.bottom_margin
				and style.is_equal (a_other.style)
				and cells.count = a_other.cells.count
			then
				Result := True
				from
					i := 1
				until
					i > cells.count or not Result
				loop
					Result := cells [i].is_equal (a_other.cells [i])
					i := i + 1
				end
			end
		end

feature {NONE} -- Initialization

	default_create
			-- Initialize as an empty row with default height 1.
		do
			create cells.make (4)
			create style.default_create
			height := 1
			top_margin := 0
			bottom_margin := 0
		ensure then
			cells_empty: cells.is_empty
			height_is_one: height = 1
			top_margin_zero: top_margin = 0
			bottom_margin_zero: bottom_margin = 0
		end

	make_empty
			-- Synonym for `default_create`.
		do
			default_create
		ensure
			cells_empty: cells.is_empty
		end

	make (a_cells: ITERABLE [TABLE_CELL])
			-- Initialize row with `a_cells`.
		require
			cells_not_void: a_cells /= Void
		do
			default_create
			across
				a_cells as c
			loop
				append_cell (c)
			end
		end

	make_raw (a_cells: ITERABLE [READABLE_STRING_GENERAL])
			-- Initialize row with cells created from plain strings `a_cells`.
		require
			cells_not_void: a_cells /= Void
		do
			default_create
			across
				a_cells as s
			loop
				append_raw_cell (s)
			end
		end

feature -- Access

	cells: ARRAYED_LIST [TABLE_CELL]
			-- Ordered sequence of cells in this row

	height: NATURAL_16
			-- Height of the row content area (default 1)

	top_margin: NATURAL_16
			-- Top margin spacing above row content (default 0)

	bottom_margin: NATURAL_16
			-- Bottom margin spacing below row content (default 0)

	style: STYLE
			-- Baseline style applied to the row

	total_height: NATURAL_16
			-- Total vertical lines occupied by row including margins
		do
			Result := top_margin + height + bottom_margin
		ensure
			correct_total: Result = top_margin + height + bottom_margin
		end

	count: INTEGER
			-- Number of cells in this row
		do
			Result := cells.count
		ensure
			correct_count: Result = cells.count
		end

	is_empty: BOOLEAN
			-- Is row empty?
		do
			Result := cells.is_empty
		ensure
			empty_definition: Result = cells.is_empty
		end

feature -- Element change

	append_cell (a_cell: TABLE_CELL)
			-- Add `a_cell` to row.
		require
			cell_not_void: a_cell /= Void
		do
			cells.extend (a_cell)
		ensure
			cell_added: cells.count = old cells.count + 1
			last_cell: cells.last = a_cell
		end

	append_raw_cell (a_text: READABLE_STRING_GENERAL)
			-- Add cell created from plain text `a_text`.
		require
			text_not_void: a_text /= Void
		local
			l_cell: TABLE_CELL
		do
			create l_cell.make_raw (a_text)
			append_cell (l_cell)
		ensure
			cell_added: cells.count = old cells.count + 1
		end

	set_height (a_height: NATURAL_16)
			-- Set content height.
		require
			positive_height: a_height >= 1
		do
			height := a_height
		ensure
			height_set: height = a_height
		end

	set_top_margin (a_margin: NATURAL_16)
			-- Set top margin.
		do
			top_margin := a_margin
		ensure
			top_margin_set: top_margin = a_margin
		end

	set_bottom_margin (a_margin: NATURAL_16)
			-- Set bottom margin.
		do
			bottom_margin := a_margin
		ensure
			bottom_margin_set: bottom_margin = a_margin
		end

	set_style (a_style: STYLE)
			-- Set row baseline style.
		require
			style_not_void: a_style /= Void
		do
			style := a_style
		ensure
			style_set: style = a_style
		end

feature -- Fluent Builders

	with_height (a_height: NATURAL_16): like Current
			-- Row with content `a_height`.
		require
			positive_height: a_height >= 1
		do
			Result := twin
			Result.set_height (a_height)
		ensure
			height_set: Result.height = a_height
		end

	with_top_margin (a_margin: NATURAL_16): like Current
			-- Row with `a_margin` top spacing.
		do
			Result := twin
			Result.set_top_margin (a_margin)
		ensure
			top_margin_set: Result.top_margin = a_margin
		end

	with_bottom_margin (a_margin: NATURAL_16): like Current
			-- Row with `a_margin` bottom spacing.
		do
			Result := twin
			Result.set_bottom_margin (a_margin)
		ensure
			bottom_margin_set: Result.bottom_margin = a_margin
		end

	with_style (a_style: STYLE): like Current
			-- Row with `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_style (a_style)
		ensure
			style_set: Result.style = a_style
		end

feature -- Output

	out: STRING
			-- String representation for debugging.
		local
			i: INTEGER
		do
			create Result.make_from_string ("TABLE_ROW([")
			from
				i := 1
			until
				i > cells.count
			loop
				Result.append (cells.i_th (i).out)
				if i < cells.count then
					Result.append_string (", ")
				end
				i := i + 1
			end
			Result.append_string ("])")
		end

invariant
	cells_not_void: cells /= Void
	style_not_void: style /= Void
	height_positive: height >= 1

end
