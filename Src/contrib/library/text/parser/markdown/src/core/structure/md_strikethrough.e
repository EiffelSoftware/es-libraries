note
	description: "Strikethrough text (GitHub Flavored Markdown)."

class
	MD_STRIKETHROUGH

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
			-- Create strikethrough node.
		do
			initialize
		end

feature -- Visitor

	process (a_visitor: MD_VISITOR)
			-- Process `Current` using `a_visitor`.
		do
			a_visitor.visit_strikethrough (Current)
		end

end
