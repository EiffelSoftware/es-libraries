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

	test_raw_html_comment_block_end
			-- An HTML comment block ends with the line of its `-->`, not at the next blank line.
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("<!-- a comment -->%N---%NText.%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("comment kept", o.has_substring ("<!-- a comment -->"))
			assert ("thematic break", o.has_substring ("<hr"))
			assert ("paragraph", o.has_substring ("<p>Text.</p>"))
		end

	test_raw_html_comment_block_multi_line
			-- A comment on several lines (with a blank line) is one block.
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("<!--%Nfirst%N%Nsecond -->%NText.%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("comment kept", o.has_substring ("<!--%Nfirst%N%Nsecond -->"))
			assert ("paragraph", o.has_substring ("<p>Text.</p>"))
		end

	test_raw_html_pre_block_end
			-- A `pre' block ends with the line of its closing tag.
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("<pre>%Ncode%N%Nmore</pre>%NText.%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("pre kept", o.has_substring ("<pre>%Ncode%N%Nmore</pre>"))
			assert ("paragraph", o.has_substring ("<p>Text.</p>"))
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
