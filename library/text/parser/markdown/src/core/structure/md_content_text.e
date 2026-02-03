note
	description: "Markdown text from string content."

class
	MD_CONTENT_TEXT

create
	make_from_string

feature -- Initialization

	make_from_string (a_content: READABLE_STRING_8)
			-- Initialize with `a_content`.
		do
			content := a_content
			internal_document := Void
		ensure
			content_set: content = a_content
		end

feature -- Access

	content: READABLE_STRING_8
			-- Source markdown content.

	document: MD_DOCUMENT
			-- Parsed document.
		local
			l_internal_document: detachable MD_DOCUMENT
			p: MD_PARSER
		do
			l_internal_document := internal_document
			if l_internal_document = Void then
				create p.make
				p.set_using_github_extension (True)
				l_internal_document := p.parse (content)
				internal_document := l_internal_document
			end
			Result := l_internal_document
		ensure
			result_attached: Result /= Void
		end

feature {NONE} -- Implementation

	internal_document: detachable like document
			-- Cached parsed document.

end

