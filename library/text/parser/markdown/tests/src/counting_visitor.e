note
	description: "Visitor that counts different node types for testing MD_ITERATOR."

class
	COUNTING_VISITOR

inherit
	MD_ITERATOR
		redefine
			visit_document,
			visit_heading,
			visit_paragraph,
			visit_list,
			visit_list_item,
			visit_emphasis,
			visit_strong,
			visit_code_span,
			visit_link,
			visit_image,
			visit_blockquote,
			visit_code_block,
			visit_table,
			visit_table_row
		end

create
	make

feature -- Initialization

	make
		do
			count := 0
			heading_count := 0
			paragraph_count := 0
			list_count := 0
			list_item_count := 0
			emphasis_count := 0
			strong_count := 0
			code_span_count := 0
			link_count := 0
			image_count := 0
			blockquote_count := 0
			code_block_count := 0
			table_count := 0
			table_row_count := 0
		end

feature -- Access

	count: INTEGER
	heading_count: INTEGER
	paragraph_count: INTEGER
	list_count: INTEGER
	list_item_count: INTEGER
	emphasis_count: INTEGER
	strong_count: INTEGER
	code_span_count: INTEGER
	link_count: INTEGER
	image_count: INTEGER
	blockquote_count: INTEGER
	code_block_count: INTEGER
	table_count: INTEGER
	table_row_count: INTEGER

feature -- Visitor

	visit_document (a_document: MD_DOCUMENT)
		do
			-- Don't count document itself, only its children
			Precursor (a_document)
		end

	visit_heading (a_heading: MD_HEADING)
		do
			count := count + 1
			heading_count := heading_count + 1
			Precursor (a_heading)
		end

	visit_paragraph (a_paragraph: MD_PARAGRAPH)
		do
			count := count + 1
			paragraph_count := paragraph_count + 1
			Precursor (a_paragraph)
		end

	visit_list (a_list: MD_LIST)
		do
			count := count + 1
			list_count := list_count + 1
			Precursor (a_list)
		end

	visit_list_item (a_item: MD_LIST_ITEM)
		do
			count := count + 1
			list_item_count := list_item_count + 1
			Precursor (a_item)
		end

	visit_emphasis (a_emphasis: MD_EMPHASIS)
		do
			count := count + 1
			emphasis_count := emphasis_count + 1
			Precursor (a_emphasis)
		end

	visit_strong (a_strong: MD_STRONG)
		do
			count := count + 1
			strong_count := strong_count + 1
			Precursor (a_strong)
		end

	visit_code_span (a_code: MD_CODE_SPAN)
		do
			count := count + 1
			code_span_count := code_span_count + 1
			Precursor (a_code)
		end

	visit_link (a_link: MD_LINK)
		do
			count := count + 1
			link_count := link_count + 1
			Precursor (a_link)
		end

	visit_image (a_image: MD_IMAGE)
		do
			count := count + 1
			image_count := image_count + 1
			Precursor (a_image)
		end

	visit_blockquote (a_blockquote: MD_BLOCKQUOTE)
		do
			count := count + 1
			blockquote_count := blockquote_count + 1
			Precursor (a_blockquote)
		end

	visit_code_block (a_code_block: MD_CODE_BLOCK)
		do
			count := count + 1
			code_block_count := code_block_count + 1
			Precursor (a_code_block)
		end

	visit_table (a_table: MD_TABLE)
		do
			count := count + 1
			table_count := table_count + 1
			Precursor (a_table)
		end

	visit_table_row (a_row: MD_TABLE_ROW)
		do
			count := count + 1
			table_row_count := table_row_count + 1
			Precursor (a_row)
		end

end
