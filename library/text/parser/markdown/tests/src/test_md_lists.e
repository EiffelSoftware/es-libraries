note
	description: "Tests for Markdown block-level: Unordered/ordered lists, nested, multiple paragraphs, code/blockquote in list (FEATURES.md Block-Level)."

class
	TEST_MD_LISTS

inherit
	TEST_MD_PARSER_BASE

feature -- Tests (Lists)

	test_unordered_list
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("- one%N- two%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.same_string ("<ul>%N<li><p>one</p>%N</li>%N<li><p>two</p>%N</li>%N</ul>%N"))
		end

	test_unordered_list_different_markers
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
				-- Same marker: one list (CommonMark 5.3)
			create t.make_from_string ("* Asterisk item%N* Another asterisk item%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml asterisk", o.same_string ("<ul>%N<li><p>Asterisk item</p>%N</li>%N<li><p>Another asterisk item</p>%N</li>%N</ul>%N"))
				-- Same marker: one list
			create t.make_from_string ("+ Plus item%N+ Another plus item%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml plus", o.same_string ("<ul>%N<li><p>Plus item</p>%N</li>%N<li><p>Another plus item</p>%N</li>%N</ul>%N"))
				-- Different markers: new list per marker (CommonMark example 301)
			create t.make_from_string ("- foo%N- bar%N+ baz%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml mixed", o.same_string ("<ul>%N<li><p>foo</p>%N</li>%N<li><p>bar</p>%N</li>%N</ul>%N<ul>%N<li><p>baz</p>%N</li>%N</ul>%N"))
				-- Three different markers: three lists
			create t.make_from_string ("* First%N+ Second%N- Third%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml three markers", o.same_string ("<ul>%N<li><p>First</p>%N</li>%N</ul>%N<ul>%N<li><p>Second</p>%N</li>%N</ul>%N<ul>%N<li><p>Third</p>%N</li>%N</ul>%N"))
		end

	test_ordered_list
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("1. one%N2. two%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.same_string ("<ol>%N<li><p>one</p>%N</li>%N<li><p>two</p>%N</li>%N</ol>%N"))
		end

	test_nested_list_indentation
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("- Block%N  - ATX%N  - Paragraph%N- Inline%N  - Text%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.same_string ("<ul>%N<li><p>Block</p>%N<ul>%N<li><p>ATX</p>%N</li>%N<li><p>Paragraph</p>%N</li>%N</ul>%N</li>%N<li><p>Inline</p>%N<ul>%N<li><p>Text</p>%N</li>%N</ul>%N</li>%N</ul>%N"))
		end

	test_list_with_multiple_paragraphs
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("- First paragraph%N%N  Second paragraph%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.has_substring ("<ul>") and o.has_substring ("First paragraph") and o.has_substring ("Second paragraph"))
		end

	test_list_with_code_block
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("- Item with code:%N%N  ```%N  code here%N  ```%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.has_substring ("<ul>") and o.has_substring ("<pre><code>") and o.has_substring ("code here"))
		end

	test_list_with_blockquote
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("- Item with quote:%N%N  > quoted text%N")

			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.has_substring ("<ul>") and o.has_substring ("<blockquote>") and o.has_substring ("quoted text")
				and o.substring_index ("</ul>", 1) > o.substring_index ("<blockquote>", 1) )
		end

end
