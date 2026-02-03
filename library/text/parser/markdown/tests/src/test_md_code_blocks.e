note
	description: "Tests for Markdown block-level: Fenced/indented code blocks; inline code spans (FEATURES.md Block-Level, Inline)."

class
	TEST_MD_CODE_BLOCKS

inherit
	TEST_MD_PARSER_BASE

feature -- Tests (Code blocks)

	test_fenced_code_block
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("```eiffel%Nclass FOO%Nend%N```%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.same_string ("<pre><code lang=%"eiffel%">class FOO%Nend</code></pre>%N"))
		end

	test_fenced_code_block_tildes
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("~~~eiffel%Nclass FOO%Nend%N~~~%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.has_substring ("<pre><code lang=%"eiffel%">") and o.has_substring ("class FOO"))
		end

	test_indented_code_block
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("    code line 1%N    code line 2%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.has_substring ("<pre><code>") and o.has_substring ("code line 1") and o.has_substring ("code line 2"))
		end

feature -- Tests (Code spans - inline)

	test_code_span_with_double_backticks
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("Code span: `` `code` ``%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.same_string ("<p>Code span: <code class=%"inline%">`code`</code></p>%N"))
		end

	test_code_span_with_five_backticks_delimiter
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("Fenced code blocks: triple backticks ````` ``` ````` with optional info string (language)%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.same_string ("<p>Fenced code blocks: triple backticks <code class=%"inline%">```</code> with optional info string (language)</p>%N"))
		end

end
