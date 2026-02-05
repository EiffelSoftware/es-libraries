note
	description: "Markdown table cell."

class
	MD_TABLE_CELL

inherit
	MD_BOX [MD_INLINE]
		redefine
			process
		end

create
	make

feature -- Initialization

	make
			-- Create an empty table cell.
		do
			initialize
		ensure
			is_empty: count = 0
		end

feature -- Access

	alignment: detachable READABLE_STRING_8
			-- Column alignment: "left", "center", or "right"; Void for default.

feature -- Element change

	set_alignment (a_align: detachable READABLE_STRING_8)
			-- Set `alignment` to `a_align`.
		do
			alignment := a_align
		ensure
			alignment_set: alignment = a_align
		end

feature -- Visitor

	process (a_visitor: MD_VISITOR)
			-- Process `Current` using `a_visitor`.
		do
			a_visitor.visit_table_cell (Current)
		end

end
