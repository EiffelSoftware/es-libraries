note
	description: "Markdown paragraph block."

class
	MD_PARAGRAPH

inherit
	MD_BOX [MD_INLINE]
		redefine
			process
		end

	MD_BLOCK

create
	make

feature -- Initialization

	make
			-- Create an empty paragraph.
		do
			initialize
		ensure
			is_empty: count = 0
		end

feature -- Visitor

	process (a_visitor: MD_VISITOR)
			-- Process `Current` using `a_visitor`.
		do
			a_visitor.visit_paragraph (Current)
		end

end

