note
	description: "Markdown fenced code block."

class
	MD_CODE_BLOCK

inherit
	MD_BLOCK

create
	make

feature -- Initialization

	make (a_info_string: detachable READABLE_STRING_8; a_code: READABLE_STRING_8)
			-- Create a fenced code block with optional info string (language) and code `a_code`.
		do
			info_string := a_info_string
			create code.make_from_string (a_code)
		ensure
			code_set: code.same_string (a_code)
		end

feature -- Access

	info_string: detachable READABLE_STRING_8
			-- Optional info string (often language).

	code: STRING_8
			-- Code content as-is (may include `%N`).

	has_info_string: BOOLEAN
			-- Does this code block have a non-empty info string?
		do
			Result := attached info_string as s and then not s.is_empty
		end

feature -- Visitor

	process (a_visitor: MD_VISITOR)
			-- Process `Current` using `a_visitor`.
		do
			a_visitor.visit_code_block (Current)
		end

invariant
	code_attached: code /= Void

end

