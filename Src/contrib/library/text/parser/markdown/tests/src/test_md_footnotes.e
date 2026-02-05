note
	description: "Tests for Markdown footnotes: references and definitions (FEATURES.md Advanced)."

class
	TEST_MD_FOOTNOTES

inherit
	TEST_MD_PARSER_BASE

feature -- Tests (Footnotes)

	test_footnote_reference
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("This is a footnote reference[^1].%N%N[^1]: This is the footnote definition.%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.has_substring ("<sup id=%"fnref1%"><a href=%"#fn1%">1</a></sup>"))
			assert ("xhtml", o.has_substring ("<div class=%"footnote%" id=%"fn1%">"))
			assert ("xhtml", o.has_substring ("This is the footnote definition"))
		end

	test_footnote_multiple_references
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("First[^1] and second[^2] footnotes.%N%N[^1]: First definition.%N[^2]: Second definition.%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.has_substring ("fnref1"))
			assert ("xhtml", o.has_substring ("fnref2"))
			assert ("xhtml", o.has_substring ("fn1"))
			assert ("xhtml", o.has_substring ("fn2"))
		end

	test_footnote_definition_with_blocks
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("Text[^note].%N%N[^note]: Definition with **bold** text.%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.has_substring ("<strong>bold</strong>"))
		end

end
