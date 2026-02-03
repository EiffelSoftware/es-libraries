note
	description: "Markdown blockquote block."

class
	MD_BLOCKQUOTE

inherit
	MD_BOX [MD_BLOCK]
		redefine
			process
		end

	MD_BLOCK

create
	make

feature -- Initialization

	make
			-- Create an empty blockquote.
		do
			initialize
		ensure
			is_empty: count = 0
		end

feature -- Visitor

	process (a_visitor: MD_VISITOR)
			-- Process `Current` using `a_visitor`.
		do
			a_visitor.visit_blockquote (Current)
		end

end

