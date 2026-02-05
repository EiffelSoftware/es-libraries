note
	description: "Tests for Markdown block-level: Raw HTML blocks (FEATURES.md Block-Level)."

class
	TEST_MD_RAW_HTML

inherit
	TEST_MD_PARSER_BASE

feature -- Tests (Raw HTML blocks)

	test_raw_html_block_single_line
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("<div>Hello</div>%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.same_string ("<div>Hello</div>%N"))
		end

	test_raw_html_block_multi_line
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("<div>%N  <p>Hello</p>%N</div>%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.same_string ("<div>%N  <p>Hello</p>%N</div>%N"))
		end

end
