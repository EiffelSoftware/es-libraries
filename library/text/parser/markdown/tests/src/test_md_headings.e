note
	description: "Tests for Markdown block-level: ATX and Setext headings (FEATURES.md Block-Level)."

class
	TEST_MD_HEADINGS

inherit
	TEST_MD_PARSER_BASE

feature -- Tests (Headings)

	test_heading_and_inline
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("# Hello *world* and **Eiffel**%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.same_string ("<h1>Hello <em>world</em> and <strong>Eiffel</strong></h1>%N"))
		end

	test_setext_heading_h1
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("Heading 1%N====%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.same_string ("<h1>Heading 1</h1>%N"))
		end

	test_setext_heading_h2
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("Heading 2%N----%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.same_string ("<h2>Heading 2</h2>%N"))
		end

	test_setext_heading_with_inline
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("Heading with *emphasis*%N====%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.same_string ("<h1>Heading with <em>emphasis</em></h1>%N"))
		end

	test_setext_heading_not_confused_with_thematic_break
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("---%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.same_string ("<hr/>%N"))
		end

end
