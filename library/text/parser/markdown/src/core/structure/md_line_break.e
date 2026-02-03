note
	description: "Hard line break."

class
	MD_LINE_BREAK

inherit
	MD_INLINE

create
	make

feature -- Initialization

	make
			-- Create a line break.
		do
		end

feature -- Visitor

	process (a_visitor: MD_VISITOR)
			-- Process `Current` using `a_visitor`.
		do
			a_visitor.visit_line_break (Current)
		end

end
