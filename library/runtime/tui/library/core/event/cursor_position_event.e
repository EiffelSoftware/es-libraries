note
	description: "[
		Cursor position report `ESC [ row ; col R` sent by the terminal in answer
		to a Device Status Report request `ESC [ 6 n`. Coordinates are 0-based.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	CURSOR_POSITION_EVENT

inherit
	EVENT
		redefine
			is_cursor_position
		end

create
	make

feature {NONE} -- Initialization

	make (a_row, a_column: NATURAL_16)
			-- Initialize report for 0-based (`a_row`, `a_column`).
		do
			row := a_row
			column := a_column
		ensure
			row_set: row = a_row
			column_set: column = a_column
		end

feature -- Access

	row: NATURAL_16
			-- 0-based cursor row

	column: NATURAL_16
			-- 0-based cursor column

feature -- Status report

	is_cursor_position: BOOLEAN = True

end
