note
	description: "Visitor interface for Markdown AST."

deferred class
	MD_VISITOR

feature -- Processing

	visit_composite (a_composite: MD_COMPOSITE [MD_ITEM])
		require
			a_composite_attached: a_composite /= Void
		deferred
		end

	visit_document (a_document: MD_DOCUMENT)
		require
			a_document_attached: a_document /= Void
		deferred
		end

	visit_paragraph (a_paragraph: MD_PARAGRAPH)
		require
			a_paragraph_attached: a_paragraph /= Void
		deferred
		end

	visit_heading (a_heading: MD_HEADING)
		require
			a_heading_attached: a_heading /= Void
		deferred
		end

	visit_list (a_list: MD_LIST)
		require
			a_list_attached: a_list /= Void
		deferred
		end

	visit_list_item (a_item: MD_LIST_ITEM)
		require
			a_item_attached: a_item /= Void
		deferred
		end

	visit_blockquote (a_blockquote: MD_BLOCKQUOTE)
		require
			a_blockquote_attached: a_blockquote /= Void
		deferred
		end

	visit_code_block (a_code_block: MD_CODE_BLOCK)
		require
			a_code_block_attached: a_code_block /= Void
		deferred
		end

	visit_raw_html (a_raw_html: MD_RAW_HTML)
		require
			a_raw_html_attached: a_raw_html /= Void
		deferred
		end

	visit_thematic_break (a_break: MD_THEMATIC_BREAK)
		require
			a_break_attached: a_break /= Void
		deferred
		end

feature -- Inline

	visit_text (a_text: MD_TEXT)
		require
			a_text_attached: a_text /= Void
		deferred
		end

	visit_emphasis (a_emphasis: MD_EMPHASIS)
		require
			a_emphasis_attached: a_emphasis /= Void
		deferred
		end

	visit_strong (a_strong: MD_STRONG)
		require
			a_strong_attached: a_strong /= Void
		deferred
		end

	visit_code_span (a_code: MD_CODE_SPAN)
		require
			a_code_attached: a_code /= Void
		deferred
		end

	visit_link (a_link: MD_LINK)
		require
			a_link_attached: a_link /= Void
		deferred
		end

	visit_image (a_image: MD_IMAGE)
		require
			a_image_attached: a_image /= Void
		deferred
		end

	visit_strikethrough (a_strikethrough: MD_STRIKETHROUGH)
		require
			a_strikethrough_attached: a_strikethrough /= Void
		deferred
		end

	visit_soft_break (a_soft_break: MD_SOFT_BREAK)
		require
			a_soft_break_attached: a_soft_break /= Void
		deferred
		end

	visit_line_break (a_line_break: MD_LINE_BREAK)
		require
			a_line_break_attached: a_line_break /= Void
		deferred
		end

	visit_footnote_reference (a_footnote: MD_FOOTNOTE_REFERENCE)
		require
			a_footnote_attached: a_footnote /= Void
		deferred
		end

feature -- Block

	visit_footnote_definition (a_footnote: MD_FOOTNOTE_DEFINITION)
		require
			a_footnote_attached: a_footnote /= Void
		deferred
		end

feature -- Table

	visit_table (a_table: MD_TABLE)
		require
			a_table_attached: a_table /= Void
		deferred
		end

	visit_table_row (a_row: MD_TABLE_ROW)
		require
			a_row_attached: a_row /= Void
		deferred
		end

	visit_table_cell (a_cell: MD_TABLE_CELL)
		require
			a_cell_attached: a_cell /= Void
		deferred
		end

	visit_table_header_cell (a_cell: MD_TABLE_HEADER_CELL)
		require
			a_cell_attached: a_cell /= Void
		deferred
		end

end

