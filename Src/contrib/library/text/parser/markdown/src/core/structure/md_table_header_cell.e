note
	description: "Markdown table header cell."

class
	MD_TABLE_HEADER_CELL

inherit
	MD_TABLE_CELL
		redefine
			process
		end

create
	make

feature -- Visitor

	process (a_visitor: MD_VISITOR)
			-- Process `Current` using `a_visitor`.
		do
			a_visitor.visit_table_header_cell (Current)
		end

end
