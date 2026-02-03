note
	description: "Inline code span."

class
	MD_CODE_SPAN

inherit
	MD_INLINE

create
	make

feature -- Initialization

	make (a_code: READABLE_STRING_8)
			-- Create inline code span with code `a_code`.
		do
			create code.make_from_string (a_code)
		ensure
			code_set: code.same_string (a_code)
		end

feature -- Access

	code: STRING_8
			-- Code text (not escaped).

feature -- Visitor

	process (a_visitor: MD_VISITOR)
			-- Process `Current` using `a_visitor`.
		do
			a_visitor.visit_code_span (Current)
		end

invariant
	code_attached: code /= Void

end

