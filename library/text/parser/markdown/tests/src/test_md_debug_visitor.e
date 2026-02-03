note
	description: "Tests for MD_DEBUG_VISITOR."

class
	TEST_MD_DEBUG_VISITOR

inherit
	EQA_TEST_SET

feature -- Tests

	test_debug_visitor_basic
		local
			t: MD_CONTENT_TEXT
			visitor: MD_DEBUG_VISITOR
		do
			create t.make_from_string ("# Heading%NParagraph with *emphasis* and **strong**.%N")
			create visitor.make
			t.document.process (visitor)
			assert ("visitor level reset", visitor.level = 0)
		end

	test_debug_visitor_heading
		local
			t: MD_CONTENT_TEXT
			visitor: MD_DEBUG_VISITOR
		do
			create t.make_from_string ("# Heading 1%N## Heading 2%N")
			create visitor.make
			t.document.process (visitor)
			assert ("visitor level reset", visitor.level = 0)
		end

	test_debug_visitor_list
		local
			t: MD_CONTENT_TEXT
			visitor: MD_DEBUG_VISITOR
		do
			create t.make_from_string ("- Item 1%N- Item 2%N")
			create visitor.make
			t.document.process (visitor)
			assert ("visitor level reset", visitor.level = 0)
		end

	test_debug_visitor_nested_structure
		local
			t: MD_CONTENT_TEXT
			visitor: MD_DEBUG_VISITOR
		do
			create t.make_from_string ("> Blockquote%N> > Nested%N")
			create visitor.make
			t.document.process (visitor)
			assert ("visitor level reset", visitor.level = 0)
		end

	test_debug_visitor_table
		local
			t: MD_CONTENT_TEXT
			visitor: MD_DEBUG_VISITOR
		do
			create t.make_from_string ("| Header |%N|--------|%N| Cell   |%N")
			create visitor.make
			t.document.process (visitor)
			assert ("visitor level reset", visitor.level = 0)
		end

	test_debug_visitor_indent_exdent
		local
			visitor: MD_DEBUG_VISITOR
		do
			create visitor.make
			assert ("initial level", visitor.level = 0)
			visitor.indent
			assert ("after indent", visitor.level = 1)
			visitor.indent
			assert ("after second indent", visitor.level = 2)
			visitor.exdent
			assert ("after exdent", visitor.level = 1)
			visitor.exdent
			assert ("after second exdent", visitor.level = 0)
		end

end
