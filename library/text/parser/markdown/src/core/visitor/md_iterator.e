note
	description: "Iterator visitor over Markdown AST."

class
	MD_ITERATOR

inherit
	MD_VISITOR

feature -- Processing

	visit_composite (a_composite: MD_COMPOSITE [MD_ITEM])
		local
			elts: like {MD_COMPOSITE [MD_ITEM]}.elements
		do
			elts := a_composite.elements
			if elts.count > 0 then
				across
					elts as e
				loop
					e.process (Current)
				end
			end
		end

	visit_document (a_document: MD_DOCUMENT)
		do
			visit_composite (a_document)
		end

	visit_paragraph (a_paragraph: MD_PARAGRAPH)
		do
			visit_composite (a_paragraph)
		end

	visit_heading (a_heading: MD_HEADING)
		do
			visit_composite (a_heading)
		end

	visit_list (a_list: MD_LIST)
		do
			visit_composite (a_list)
		end

	visit_list_item (a_item: MD_LIST_ITEM)
		do
			visit_composite (a_item)
		end

	visit_blockquote (a_blockquote: MD_BLOCKQUOTE)
		do
			visit_composite (a_blockquote)
		end

	visit_code_block (a_code_block: MD_CODE_BLOCK)
		do
			-- Code content is raw, no inline parsing inside.
		end

	visit_raw_html (a_raw_html: MD_RAW_HTML)
		do
			-- Raw HTML has no child nodes.
		end

	visit_thematic_break (a_break: MD_THEMATIC_BREAK)
		do
		end

feature -- Inline

	visit_text (a_text: MD_TEXT)
		do
		end

	visit_emphasis (a_emphasis: MD_EMPHASIS)
		do
			visit_composite (a_emphasis)
		end

	visit_strong (a_strong: MD_STRONG)
		do
			visit_composite (a_strong)
		end

	visit_code_span (a_code: MD_CODE_SPAN)
		do
		end

	visit_link (a_link: MD_LINK)
		do
			visit_composite (a_link)
		end

	visit_image (a_image: MD_IMAGE)
		do
			visit_composite (a_image)
		end

	visit_strikethrough (a_strikethrough: MD_STRIKETHROUGH)
		do
			visit_composite (a_strikethrough)
		end

	visit_line_break (a_line_break: MD_LINE_BREAK)
		do
			-- Line breaks have no children
		end

	visit_soft_break (a_soft_break: MD_SOFT_BREAK)
		do
			-- Soft breaks have no children
		end

	visit_footnote_reference (a_footnote: MD_FOOTNOTE_REFERENCE)
		do
			-- Footnote references have no children
		end

feature -- Block

	visit_footnote_definition (a_footnote: MD_FOOTNOTE_DEFINITION)
		do
			visit_composite (a_footnote)
		end

feature -- Table

	visit_table (a_table: MD_TABLE)
		do
			visit_composite (a_table)
		end

	visit_table_row (a_row: MD_TABLE_ROW)
		do
			visit_composite (a_row)
		end

	visit_table_cell (a_cell: MD_TABLE_CELL)
		do
			visit_composite (a_cell)
		end

	visit_table_header_cell (a_cell: MD_TABLE_HEADER_CELL)
		do
			visit_composite (a_cell)
		end

end

