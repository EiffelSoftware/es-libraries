note
	description: "Tests for MD_ITERATOR using a counting visitor."

class
	TEST_MD_ITERATOR

inherit
	EQA_TEST_SET

feature -- Tests

	test_iterator_basic
		local
			t: MD_CONTENT_TEXT
			counter: COUNTING_VISITOR
		do
			create t.make_from_string ("# Heading%NParagraph text.%N")
			create counter.make
			t.document.process (counter)
			-- Should have at least 1 heading and 1 paragraph
			assert ("nodes visited", counter.count >= 2)
			assert ("heading visited", counter.heading_count >= 1)
			assert ("paragraph visited", counter.paragraph_count >= 1)
		end

	test_iterator_heading
		local
			t: MD_CONTENT_TEXT
			counter: COUNTING_VISITOR
		do
			create t.make_from_string ("# Heading 1%N## Heading 2%N")
			create counter.make
			t.document.process (counter)
			assert ("at least headings visited", counter.heading_count >= 2)
		end

	test_iterator_paragraph
		local
			t: MD_CONTENT_TEXT
			counter: COUNTING_VISITOR
		do
			create t.make_from_string ("First paragraph.%N%NSecond paragraph.%N")
			create counter.make
			t.document.process (counter)
			assert ("at least paragraphs visited", counter.paragraph_count >= 2)
		end

	test_iterator_list
		local
			t: MD_CONTENT_TEXT
			counter: COUNTING_VISITOR
		do
			create t.make_from_string ("- Item 1%N- Item 2%N")
			create counter.make
			t.document.process (counter)
			assert ("list visited", counter.list_count >= 1)
			assert ("list items visited", counter.list_item_count >= 2)
			-- Note: list items contain paragraphs, so paragraph_count will also be >= 2
		end

	test_iterator_inline_formatting
		local
			t: MD_CONTENT_TEXT
			counter: COUNTING_VISITOR
		do
			create t.make_from_string ("Text with *emphasis* and **strong** and `code`.%N")
			create counter.make
			t.document.process (counter)
			assert ("emphasis visited", counter.emphasis_count >= 1)
			assert ("strong visited", counter.strong_count >= 1)
			assert ("code span visited", counter.code_span_count >= 1)
		end

	test_iterator_link_and_image
		local
			t: MD_CONTENT_TEXT
			counter: COUNTING_VISITOR
		do
			create t.make_from_string ("[Link](url) and ![Image](img.png)%N")
			create counter.make
			t.document.process (counter)
			assert ("link visited", counter.link_count >= 1)
			assert ("image visited", counter.image_count >= 1)
		end

	test_iterator_nested_structure
		local
			t: MD_CONTENT_TEXT
			counter: COUNTING_VISITOR
		do
			create t.make_from_string ("> Blockquote%N> > Nested%N")
			create counter.make
			t.document.process (counter)
			assert ("blockquote visited", counter.blockquote_count >= 1)
		end

	test_iterator_code_block
		local
			t: MD_CONTENT_TEXT
			counter: COUNTING_VISITOR
		do
			create t.make_from_string ("```eiffel%Ncode%N```%N")
			create counter.make
			t.document.process (counter)
			assert ("code block visited", counter.code_block_count >= 1)
		end

	test_iterator_table
		local
			t: MD_CONTENT_TEXT
			counter: COUNTING_VISITOR
		do
			create t.make_from_string ("| Header |%N|--------|%N| Cell   |%N")
			create counter.make
			t.document.process (counter)
			assert ("table visited", counter.table_count >= 1)
			-- Table has header row and data row (separator is not a row)
			assert ("table rows visited", counter.table_row_count >= 2)
		end

end
