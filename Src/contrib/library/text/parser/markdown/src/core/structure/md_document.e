note
	description: "Markdown document (root)."

class
	MD_DOCUMENT

inherit
	MD_COMPOSITE [MD_BLOCK]
		redefine
			process
		end

create
	make

feature -- Initialization

	make
			-- Create an empty document.
		do
			initialize
		ensure
			is_empty: count = 0
		end

feature -- Visitor

	process (a_visitor: MD_VISITOR)
			-- Process `Current` using `a_visitor`.
		do
			a_visitor.visit_document (Current)
		end

end

