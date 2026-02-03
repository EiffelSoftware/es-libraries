note
	description: "Debug visitor for Markdown AST."

class
	MD_DEBUG_VISITOR

inherit
	MD_VISITOR

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize debug visitor.
		do
		end

feature -- Output

	level: INTEGER
			-- Indentation level.

	output (s: READABLE_STRING_GENERAL)
			-- Output `s` to standard output.
		local
			pad: STRING
		do
			create pad.make_filled (' ', level * 2)
			io.put_string (pad)
			io.put_string_32 (s.to_string_32)
			io.put_new_line
		end

	indent
		do
			level := level + 1
		ensure
			level_increased: level = old level + 1
		end

	exdent
		do
			level := level - 1
		ensure
			level_decreased: level = old level - 1
		end

feature -- Processing

	visit_composite (a_composite: MD_COMPOSITE [MD_ITEM])
		do
			indent
			across
				a_composite.elements as e
			loop
				e.process (Current)
			end
			exdent
		end

	visit_document (a_document: MD_DOCUMENT)
		do
			output ("DOCUMENT")
			visit_composite (a_document)
		end

	visit_paragraph (a_paragraph: MD_PARAGRAPH)
		do
			output ("PARAGRAPH")
			visit_composite (a_paragraph)
		end

	visit_heading (a_heading: MD_HEADING)
		do
			output ("HEADING(" + a_heading.level.out + ")")
			visit_composite (a_heading)
		end

	visit_list (a_list: MD_LIST)
		do
			if a_list.is_ordered then
				output ("LIST(ordered, start=" + a_list.start_number.out + ")")
			else
				output ("LIST(unordered)")
			end
			visit_composite (a_list)
		end

	visit_list_item (a_item: MD_LIST_ITEM)
		do
			output ("LIST_ITEM")
			visit_composite (a_item)
		end

	visit_blockquote (a_blockquote: MD_BLOCKQUOTE)
		do
			output ("BLOCKQUOTE")
			visit_composite (a_blockquote)
		end

	visit_code_block (a_code_block: MD_CODE_BLOCK)
		do
			if a_code_block.has_info_string and then attached a_code_block.info_string as s then
				output ("CODE_BLOCK(lang=" + s + ")")
			else
				output ("CODE_BLOCK")
			end
		end

	visit_raw_html (a_raw_html: MD_RAW_HTML)
		do
			output ("RAW_HTML")
		end

	visit_thematic_break (a_break: MD_THEMATIC_BREAK)
		do
			output ("THEMATIC_BREAK")
		end

feature -- Inline

	visit_text (a_text: MD_TEXT)
		do
			output ("TEXT(%"" + a_text.text + "%")")
		end

	visit_emphasis (a_emphasis: MD_EMPHASIS)
		do
			output ("EMPHASIS")
			visit_composite (a_emphasis)
		end

	visit_strong (a_strong: MD_STRONG)
		do
			output ("STRONG")
			visit_composite (a_strong)
		end

	visit_code_span (a_code: MD_CODE_SPAN)
		do
			output ("CODE_SPAN(%"" + a_code.code + "%")")
		end

	visit_link (a_link: MD_LINK)
		do
			output ("LINK(" + a_link.url)
			if attached a_link.title as t and then not t.is_empty then
				output (" title=%"" + t + "%"")
			end
			output (")")
			visit_composite (a_link)
		end

	visit_image (a_image: MD_IMAGE)
		do
			output ("IMAGE(" + a_image.url)
			if attached a_image.title as t then
				output (" title=" + t)
			end
			output (")")
			visit_composite (a_image)
		end

	visit_strikethrough (a_strikethrough: MD_STRIKETHROUGH)
		do
			output ("STRIKETHROUGH")
			visit_composite (a_strikethrough)
		end

	visit_line_break (a_line_break: MD_LINE_BREAK)
		do
			output ("LINE_BREAK")
		end

	visit_soft_break (a_soft_break: MD_SOFT_BREAK)
		do
			output ("SOFT_BREAK")
		end

	visit_footnote_reference (a_footnote: MD_FOOTNOTE_REFERENCE)
		do
			output ("FOOTNOTE_REFERENCE(" + a_footnote.label + ")")
		end

feature -- Block

	visit_footnote_definition (a_footnote: MD_FOOTNOTE_DEFINITION)
		do
			output ("FOOTNOTE_DEFINITION(" + a_footnote.label + ")")
			visit_composite (a_footnote)
		end

feature -- Table

	visit_table (a_table: MD_TABLE)
		do
			output ("TABLE")
			visit_composite (a_table)
		end

	visit_table_row (a_row: MD_TABLE_ROW)
		do
			output ("TABLE_ROW")
			visit_composite (a_row)
		end

	visit_table_cell (a_cell: MD_TABLE_CELL)
		do
			output ("TABLE_CELL")
			visit_composite (a_cell)
		end

	visit_table_header_cell (a_cell: MD_TABLE_HEADER_CELL)
		do
			output ("TABLE_HEADER_CELL")
			visit_composite (a_cell)
		end

invariant
	non_negative_level: level >= 0

end

