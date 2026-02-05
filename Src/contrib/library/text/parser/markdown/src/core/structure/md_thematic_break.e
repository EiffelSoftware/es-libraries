note
	description: "Markdown thematic break (horizontal rule)."

class
	MD_THEMATIC_BREAK

inherit
	MD_BLOCK

create
	make

feature -- Initialization

	make
			-- Create a thematic break.
		do
		end

feature -- Visitor

	process (a_visitor: MD_VISITOR)
			-- Process `Current` using `a_visitor`.
		do
			a_visitor.visit_thematic_break (Current)
		end

end

