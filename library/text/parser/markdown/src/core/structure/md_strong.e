note
	description: "Strong emphasis inline node (typically `**...**` or `__...__`)."

class
	MD_STRONG

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
			-- Create an empty strong emphasis.
		do
			initialize
		ensure
			is_empty: count = 0
		end

feature -- Visitor

	process (a_visitor: MD_VISITOR)
			-- Process `Current` using `a_visitor`.
		do
			a_visitor.visit_strong (Current)
		end

end

