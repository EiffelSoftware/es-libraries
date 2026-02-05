note
	description: "Raw HTML block (passed through unescaped in HTML output)."

class
	MD_RAW_HTML

inherit
	MD_BLOCK

create
	make

feature -- Initialization

	make (a_content: READABLE_STRING_8)
			-- Create a raw HTML block with `a_content`.
		do
			create content.make_from_string (a_content)
		ensure
			content_set: content.same_string (a_content)
		end

feature -- Access

	content: STRING_8
			-- Raw HTML content (may include newlines).

feature -- Visitor

	process (a_visitor: MD_VISITOR)
			-- Process `Current` using `a_visitor`.
		do
			a_visitor.visit_raw_html (Current)
		end

invariant
	content_attached: content /= Void

end
