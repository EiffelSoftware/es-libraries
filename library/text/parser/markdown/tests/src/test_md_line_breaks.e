note
	description: "Tests for Markdown block-level: Hard line breaks - trailing spaces, backslash (FEATURES.md Block-Level)."

class
	TEST_MD_LINE_BREAKS

inherit
	TEST_MD_PARSER_BASE

feature -- Tests (Hard line breaks)

	test_hard_line_break_trailing_spaces
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("Line with two spaces  %NNext line%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.has_substring ("<br/>"))
		end

	test_hard_line_break_backslash
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("Line with backslash\%NNext line%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.has_substring ("<br/>"))
		end

end
