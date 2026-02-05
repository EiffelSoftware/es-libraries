note
	description: "Markdown table row."

class
	MD_TABLE_ROW

inherit
	MD_BOX [MD_TABLE_CELL]
		redefine
			process
		end

create
	make

feature -- Initialization

	make
			-- Create an empty table row.
		do
			initialize
		ensure
			is_empty: count = 0
		end

feature -- Visitor

	process (a_visitor: MD_VISITOR)
			-- Process `Current` using `a_visitor`.
		do
			a_visitor.visit_table_row (Current)
		end

end
