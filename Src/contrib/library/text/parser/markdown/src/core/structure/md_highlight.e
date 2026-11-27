note
	description: "Highlighted (marked) text: `==text==` (extension, see {MD_PARSER}.using_highlight_extension)."

class
	MD_HIGHLIGHT

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
			-- Create highlight node.
		do
			initialize
		end

feature -- Visitor

	process (a_visitor: MD_VISITOR)
			-- Process `Current` using `a_visitor`.
		do
			a_visitor.visit_highlight (Current)
		end

end
