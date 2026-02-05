note
	description: "Markdown visitor generating CommonMark XML AST (http://commonmark.org/xml/1.0)."

class
	MD_AST_GENERATOR

inherit
	MD_VISITOR

create
	make

feature {NONE} -- Constants

	Xml_namespace: STRING = "http://commonmark.org/xml/1.0"
			-- CommonMark XML 1.0 namespace.

feature {NONE} -- Initialization

	make (a_buffer: like buffer)
			-- Initialize generator writing into `a_buffer`.
		require
			a_buffer_attached: a_buffer /= Void
		do
			buffer := a_buffer
		ensure
			buffer_set: buffer = a_buffer
		end

feature -- Output

	buffer: STRING
			-- Output buffer.

feature {NONE} -- Indentation

	indent_level: INTEGER
			-- Current depth for indentation (0 = root).

	Indent_width: INTEGER = 2
			-- Number of spaces per level.

	newline_indent
			-- Append newline then spaces for current `indent_level'.
		do
			buffer.append ("%N")
			append_indent (indent_level)
		end

	append_indent (a_level: INTEGER)
			-- Append `Indent_width' * `a_level' spaces to `buffer'.
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > a_level * Indent_width
			loop
				buffer.append_character (' ')
				i := i + 1
			end
		end

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
			output ("<?xml version=%"1.0%" encoding=%"UTF-8%"?>%N")
			output ("<!DOCTYPE document SYSTEM %"CommonMark.dtd%">%N%N")

			output ("<document xmlns=%"")
			output (Xml_namespace)
			output ("%">")
			indent_level := 1
			visit_composite (a_document)
			indent_level := 0
			newline_indent
			output ("</document>%N")
		end

	visit_paragraph (a_paragraph: MD_PARAGRAPH)
		do
			if a_paragraph.count > 0 then
				newline_indent
				output ("<paragraph>")
				indent_level := indent_level + 1
				visit_composite (a_paragraph)
				indent_level := indent_level - 1
				newline_indent
				output ("</paragraph>")
			end
		end

	visit_heading (a_heading: MD_HEADING)
		do
			newline_indent
			output ("<heading level=%"")
			output (a_heading.level.out)
			output ("%">")
			indent_level := indent_level + 1
			visit_composite (a_heading)
			indent_level := indent_level - 1
			newline_indent
			output ("</heading>")
		end

	visit_list (a_list: MD_LIST)
		do
			newline_indent
			if a_list.is_ordered then
				output ("<list type=%"ordered%" start=%"")
				output (a_list.start_number.out)
				output ("%">")
			else
				output ("<list type=%"bullet%">")
			end
			indent_level := indent_level + 1
			visit_composite (a_list)
			indent_level := indent_level - 1
			newline_indent
			output ("</list>")
		end

	visit_list_item (a_item: MD_LIST_ITEM)
		local
			elts: like {MD_LIST_ITEM}.elements
		do
			newline_indent
			if a_item.is_task then
				output ("<item task=%"true%" checked=%"")
				if a_item.task_checked then
					output ("true")
				else
					output ("false")
				end
				output ("%">")
				elts := a_item.elements
				indent_level := indent_level + 1
				if elts.count = 1 and then attached {MD_PARAGRAPH} elts.first as p then
					visit_composite (p)
				else
					visit_composite (a_item)
				end
				indent_level := indent_level - 1
			else
				output ("<item>")
				indent_level := indent_level + 1
				visit_composite (a_item)
				indent_level := indent_level - 1
			end
			newline_indent
			output ("</item>")
		end

	visit_blockquote (a_blockquote: MD_BLOCKQUOTE)
		do
			newline_indent
			output ("<block_quote>")
			indent_level := indent_level + 1
			visit_composite (a_blockquote)
			indent_level := indent_level - 1
			newline_indent
			output ("</block_quote>")
		end

	visit_code_block (a_code_block: MD_CODE_BLOCK)
		do
			newline_indent
			if a_code_block.has_info_string and then attached a_code_block.info_string as s then
				output ("<code_block info=%"")
				output_xml_attribute_escaped (s)
				output ("%">")
			else
				output ("<code_block>")
			end
			output_xml_escaped (a_code_block.code)
			newline_indent
			output ("</code_block>")
		end

	visit_raw_html (a_raw_html: MD_RAW_HTML)
		do
			newline_indent
			output ("<html_block>")
			output_xml_escaped (a_raw_html.content)
			newline_indent
			output ("</html_block>")
		end

	visit_thematic_break (a_break: MD_THEMATIC_BREAK)
		do
			newline_indent
			output ("<thematic_break/>")
		end

feature -- Table

	visit_table (a_table: MD_TABLE)
		do
			newline_indent
			output ("<table>")
			indent_level := indent_level + 1
			visit_composite (a_table)
			indent_level := indent_level - 1
			newline_indent
			output ("</table>")
		end

	visit_table_row (a_row: MD_TABLE_ROW)
		do
			newline_indent
			output ("<table_row>")
			indent_level := indent_level + 1
			visit_composite (a_row)
			indent_level := indent_level - 1
			newline_indent
			output ("</table_row>")
		end

	visit_table_cell (a_cell: MD_TABLE_CELL)
		do
			newline_indent
			if attached a_cell.alignment as align and then not align.is_empty then
				output ("<table_cell alignment=%"")
				output_xml_attribute_escaped (align)
				output ("%">")
			else
				output ("<table_cell>")
			end
			indent_level := indent_level + 1
			visit_composite (a_cell)
			indent_level := indent_level - 1
			newline_indent
			output ("</table_cell>")
		end

	visit_table_header_cell (a_cell: MD_TABLE_HEADER_CELL)
		do
			newline_indent
			if attached a_cell.alignment as align and then not align.is_empty then
				output ("<table_header_cell alignment=%"")
				output_xml_attribute_escaped (align)
				output ("%">")
			else
				output ("<table_header_cell>")
			end
			indent_level := indent_level + 1
			visit_composite (a_cell)
			indent_level := indent_level - 1
			newline_indent
			output ("</table_header_cell>")
		end

feature -- Inline

	visit_text (a_text: MD_TEXT)
		do
			newline_indent
			output ("<text>")
			output_xml_escaped (a_text.text)
			output ("</text>")
		end

	visit_emphasis (a_emphasis: MD_EMPHASIS)
		do
			newline_indent
			output ("<emph>")
			indent_level := indent_level + 1
			visit_composite (a_emphasis)
			indent_level := indent_level - 1
			newline_indent
			output ("</emph>")
		end

	visit_strong (a_strong: MD_STRONG)
		do
			newline_indent
			output ("<strong>")
			indent_level := indent_level + 1
			visit_composite (a_strong)
			indent_level := indent_level - 1
			newline_indent
			output ("</strong>")
		end

	visit_code_span (a_code: MD_CODE_SPAN)
		do
			newline_indent
			output ("<code>")
			output_xml_escaped (a_code.code)
			output ("</code>")
		end

	visit_link (a_link: MD_LINK)
		do
			newline_indent
			output ("<link destination=%"")
			output_xml_attribute_escaped (a_link.url)
			output ("%"")
			if attached a_link.title as t and then not t.is_empty then
				output (" title=%"")
				output_xml_attribute_escaped (t)
				output ("%"")
			end
			output (">")
			indent_level := indent_level + 1
			visit_composite (a_link)
			indent_level := indent_level - 1
			newline_indent
			output ("</link>")
		end

	visit_image (a_image: MD_IMAGE)
		do
			newline_indent
			output ("<image destination=%"")
			output_xml_attribute_escaped (a_image.url)
			output ("%"")
			if attached a_image.title as t and then not t.is_empty then
				output (" title=%"")
				output_xml_attribute_escaped (t)
				output ("%"")
			end
			output (">")
			indent_level := indent_level + 1
			visit_composite (a_image)
			indent_level := indent_level - 1
			newline_indent
			output ("</image>")
		end

	visit_strikethrough (a_strikethrough: MD_STRIKETHROUGH)
		do
			newline_indent
			output ("<strikethrough>")
			indent_level := indent_level + 1
			visit_composite (a_strikethrough)
			indent_level := indent_level - 1
			newline_indent
			output ("</strikethrough>")
		end

	visit_line_break (a_line_break: MD_LINE_BREAK)
		do
			newline_indent
			output ("<linebreak/>")
		end

	visit_soft_break (a_soft_break: MD_SOFT_BREAK)
		do
			newline_indent
			output ("<softbreak/>")
		end

	visit_footnote_reference (a_footnote: MD_FOOTNOTE_REFERENCE)
		do
			newline_indent
			output ("<footnote_reference label=%"")
			output_xml_attribute_escaped (a_footnote.label)
			output ("%"/>")
		end

feature -- Block

	visit_footnote_definition (a_footnote: MD_FOOTNOTE_DEFINITION)
		do
			newline_indent
			output ("<footnote_definition label=%"")
			output_xml_attribute_escaped (a_footnote.label)
			output ("%">")
			indent_level := indent_level + 1
			visit_composite (a_footnote)
			indent_level := indent_level - 1
			newline_indent
			output ("</footnote_definition>")
		end

feature {NONE} -- Output helpers

	output (s: READABLE_STRING_8)
		do
			buffer.append (s)
		end

	output_xml_escaped (s: READABLE_STRING_8)
		do
			append_xml_escaped_to (s, buffer)
		end

	output_xml_attribute_escaped (s: READABLE_STRING_8)
			-- Append `s` escaped for XML attribute values.
		do
			append_xml_attribute_escaped_to (s, buffer)
		end

	append_xml_escaped_to (s: READABLE_STRING_8; a_output: STRING_8)
		local
			i, n: INTEGER
			c: CHARACTER
		do
			from
				i := 1
				n := s.count
			until
				i > n
			loop
				c := s [i]
				inspect c
				when '<' then
					a_output.append ("&lt;")
				when '>' then
					a_output.append ("&gt;")
				when '&' then
					a_output.append ("&amp;")
				else
					a_output.append_character (c)
				end
				i := i + 1
			end
		end

	append_xml_attribute_escaped_to (s: READABLE_STRING_8; a_output: STRING_8)
		local
			i, n: INTEGER
			c: CHARACTER
		do
			from
				i := 1
				n := s.count
			until
				i > n
			loop
				c := s [i]
				inspect c
				when '<' then
					a_output.append ("&lt;")
				when '>' then
					a_output.append ("&gt;")
				when '&' then
					a_output.append ("&amp;")
				when '%"' then
					a_output.append ("&quot;")
				when '%'' then
					a_output.append ("&apos;")
				else
					a_output.append_character (c)
				end
				i := i + 1
			end
		end

	collect_text_from_inlines (a_container: MD_COMPOSITE [MD_INLINE]; a_output: STRING_8)
			-- Collect plain text from inline content into `a_output`.
		require
			a_container_attached: a_container /= Void
			a_output_attached: a_output /= Void
		do
			across
				a_container as inline_item
			loop
				if attached {MD_TEXT} inline_item as txt then
					a_output.append (txt.text)
				elseif attached {MD_EMPHASIS} inline_item as emp then
					collect_text_from_inlines (emp, a_output)
				elseif attached {MD_STRONG} inline_item as str then
					collect_text_from_inlines (str, a_output)
				elseif attached {MD_CODE_SPAN} inline_item as code then
					a_output.append (code.code)
				elseif attached {MD_LINK} inline_item as lnk then
					collect_text_from_inlines (lnk, a_output)
				elseif attached {MD_IMAGE} inline_item as img then
					collect_text_from_inlines (img, a_output)
				elseif attached {MD_STRIKETHROUGH} inline_item as strike then
					collect_text_from_inlines (strike, a_output)
				end
			end
		end

end
