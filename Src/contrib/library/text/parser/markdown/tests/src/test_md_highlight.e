note
	description: "Tests of the highlight extension: ==text== (see {MD_PARSER}.using_highlight_extension)."

class
	TEST_MD_HIGHLIGHT

inherit
	TEST_MD_PARSER_BASE

feature -- Tests

	test_highlight
			-- `==text==' is highlighted, with inline content.
		do
			assert ("simple", xhtml ("==highlighted text==%N").same_string ("<p><mark>highlighted text</mark></p>%N"))
			assert ("in text", xhtml ("Some ==marked== words.%N").same_string ("<p>Some <mark>marked</mark> words.</p>%N"))
			assert ("with inline content", xhtml ("==**bold** and `code`==%N").same_string ("<p><mark><strong>bold</strong> and <code class=%"inline%">code</code></mark></p>%N"))
			assert ("two", xhtml ("==a== and ==b==%N").same_string ("<p><mark>a</mark> and <mark>b</mark></p>%N"))
		end

	test_not_highlight
			-- Text with `=' that is not highlighted.
		do
			assert ("comparison", xhtml ("a == b == c%N").same_string ("<p>a == b == c</p>%N"))
			assert ("no closing", xhtml ("==open only%N").same_string ("<p>==open only</p>%N"))
			assert ("space after opening", xhtml ("== text==%N").same_string ("<p>== text==</p>%N"))
			assert ("space before closing", xhtml ("==text ==%N").same_string ("<p>==text ==</p>%N"))
			assert ("three", xhtml ("===text===%N").same_string ("<p>===text===</p>%N"))
			assert ("in code", xhtml ("`==code==`%N").same_string ("<p><code class=%"inline%">==code==</code></p>%N"))
			assert ("escaped", xhtml ("\==text==%N").same_string ("<p>==text==</p>%N"))
		end

	test_highlight_disabled
			-- Without the extension, `==text==' is text.
		local
			p: MD_PARSER
			o: STRING
		do
			create p.make
			create o.make_empty
			p.parse ("==text==%N").process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("text", o.same_string ("<p>==text==</p>%N"))
		end

	test_highlight_visitors
			-- The other visitors know the highlight.
		local
			p: MD_PARSER
			o: STRING
		do
			create p.make
			p.set_using_highlight_extension (True)
			create o.make_empty
			p.parse ("![==alt== text](x.png)%N").process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("alt text", o.has_substring ("alt=%"alt text%""))
			create o.make_empty
			p.parse ("==x==%N").process (create {MD_AST_GENERATOR}.make (o))
			assert ("ast", o.has_substring ("<highlight>"))
		end

feature {NONE} -- Implementation

	xhtml (a_text: STRING): STRING
			-- XHTML of `a_text', parsed with the highlight extension.
		local
			p: MD_PARSER
		do
			create p.make
			p.set_using_highlight_extension (True)
			create Result.make_empty
			p.parse (a_text).process (create {MD_XHTML_GENERATOR}.make (Result))
		end

end
