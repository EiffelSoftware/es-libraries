note
	description: "Tests for Markdown block-level: Blockquotes, nested blockquotes (FEATURES.md Block-Level)."

class
	TEST_MD_BLOCKQUOTES

inherit
	TEST_MD_PARSER_BASE

feature -- Tests (Blockquotes)

	test_blockquote
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("> quoted%N> line%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.same_string ("<blockquote>%N<p>quoted%Nline</p>%N</blockquote>%N"))
		end

	test_nested_blockquote
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("> First level%N> > Second level%N> > > Third level%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.has_substring ("<blockquote>") and o.has_substring ("Second level") and o.has_substring ("Third level"))
		end

end
