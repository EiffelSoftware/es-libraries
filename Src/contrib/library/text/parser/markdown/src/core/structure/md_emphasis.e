note
	description: "Emphasis inline node (typically `*...*` or `_..._`)."

class
	MD_EMPHASIS

inherit
	MD_BOX [MD_INLINE]
		redefine
			process
		end

	MD_INLINE

create
	make

feature -- Initialization

	make
			-- Create an empty emphasis.
		do
			initialize
		ensure
			is_empty: count = 0
		end

feature -- Visitor

	process (a_visitor: MD_VISITOR)
			-- Process `Current` using `a_visitor`.
		do
			a_visitor.visit_emphasis (Current)
		end

end

