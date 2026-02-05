note
	description: "Tests for Markdown block-level: Thematic breaks (FEATURES.md Block-Level)."

class
	TEST_MD_THEMATIC_BREAKS

inherit
	TEST_MD_PARSER_BASE

feature -- Tests (Thematic breaks)

	test_thematic_break
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("---%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.same_string ("<hr/>%N"))

			create t.make_from_string ("***%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.same_string ("<hr/>%N"))

			create t.make_from_string ("___%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.same_string ("<hr/>%N"))
		end

end
