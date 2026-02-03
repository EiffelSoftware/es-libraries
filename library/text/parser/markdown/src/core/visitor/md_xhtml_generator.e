note
	description: "Markdown visitor generating XHTML."

class
	MD_XHTML_GENERATOR

inherit
	MD_VISITOR

create
	make

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
			if a_paragraph.count > 0 then
				output ("<p>")
				visit_composite (a_paragraph)
				output ("</p>%N")
			end
		end

	visit_heading (a_heading: MD_HEADING)
		do
			output ("<h" + a_heading.level.out + ">")
			visit_composite (a_heading)
			output ("</h" + a_heading.level.out + ">%N")
		end

	visit_list (a_list: MD_LIST)
		local
			tag: STRING
		do
			if a_list.is_ordered then
				tag := "ol"
			else
				tag := "ul"
			end
			output ("<" + tag + ">%N")
			visit_composite (a_list)
			output ("</" + tag + ">%N")
		end

	visit_list_item (a_item: MD_LIST_ITEM)
		local
			elts: like {MD_LIST_ITEM}.elements
		do
			if a_item.is_task then
				output ("<li><input type=%"checkbox%" disabled")
				if a_item.task_checked then
					output (" checked")
				end
				output ("/>")
					-- For task lists, output text directly without paragraph wrapper if single paragraph
				elts := a_item.elements
				if elts.count = 1 and then attached {MD_PARAGRAPH} elts.first as p then
						-- Visit paragraph content directly, not the paragraph itself
					visit_composite (p)
				else
					visit_composite (a_item)
				end
			else
				output ("<li>")
				visit_composite (a_item)
			end
			output ("</li>%N")
		end

	visit_blockquote (a_blockquote: MD_BLOCKQUOTE)
		do
			output ("<blockquote>%N")
			visit_composite (a_blockquote)
			output ("</blockquote>%N")
		end

	visit_code_block (a_code_block: MD_CODE_BLOCK)
		do
			output ("<pre><code")
			if a_code_block.has_info_string and then attached a_code_block.info_string as s then
				output (" lang=%"")
				output_attribute_escaped (s)
				output ("%"")
			end
			output (">")
			output_escaped (a_code_block.code)
			output ("</code></pre>%N")
		end

	visit_raw_html (a_raw_html: MD_RAW_HTML)
		do
			output (a_raw_html.content)
		end

	visit_thematic_break (a_break: MD_THEMATIC_BREAK)
		do
			output ("<hr/>%N")
		end

feature -- Table

	visit_table (a_table: MD_TABLE)
		do
			output ("<table>%N")
			visit_composite (a_table)
			output ("</table>%N")
		end

	visit_table_row (a_row: MD_TABLE_ROW)
		do
			output ("<tr>")
			visit_composite (a_row)
			output ("</tr>%N")
		end

	visit_table_cell (a_cell: MD_TABLE_CELL)
		do
			output ("<td")
			if attached a_cell.alignment as align and then not align.is_empty then
				output (" style=%"text-align: ")
				output (align)
				output ("%"")
			end
			output (">")
			visit_composite (a_cell)
			output ("</td>")
		end

	visit_table_header_cell (a_cell: MD_TABLE_HEADER_CELL)
		do
			output ("<th")
			if attached a_cell.alignment as align and then not align.is_empty then
				output (" style=%"text-align: ")
				output (align)
				output ("%"")
			end
			output (">")
			visit_composite (a_cell)
			output ("</th>")
		end

feature -- Inline

	visit_text (a_text: MD_TEXT)
		do
			output_escaped (a_text.text)
		end

	visit_emphasis (a_emphasis: MD_EMPHASIS)
		do
			output ("<em>")
			visit_composite (a_emphasis)
			output ("</em>")
		end

	visit_strong (a_strong: MD_STRONG)
		do
			output ("<strong>")
			visit_composite (a_strong)
			output ("</strong>")
		end

	visit_code_span (a_code: MD_CODE_SPAN)
		do
			output ("<code class=%"inline%">")
			output_escaped (a_code.code)
			output ("</code>")
		end

	visit_link (a_link: MD_LINK)
		do
			output ("<a href=%"")
			output_attribute_escaped (a_link.url)
			output ("%"")
			if attached a_link.title as t and then not t.is_empty then
				output (" title=%"")
				output_attribute_escaped (t)
				output ("%"")
			end
			output (">")
			visit_composite (a_link)
			output ("</a>")
		end

	visit_image (a_image: MD_IMAGE)
		local
			alt_text: STRING
		do
			create alt_text.make_empty
			collect_text_from_inlines (a_image, alt_text)
			output ("<img src=%"")
			output_attribute_escaped (a_image.url)
			output ("%" alt=%"")
			output_attribute_escaped (alt_text)
			output ("%"")
			if attached a_image.title as t and then not t.is_empty then
				output (" title=%"")
				output_attribute_escaped (t)
				output ("%"")
			end
			output ("/>")
		end

	visit_strikethrough (a_strikethrough: MD_STRIKETHROUGH)
		do
			output ("<del>")
			visit_composite (a_strikethrough)
			output ("</del>")
		end

	visit_line_break (a_line_break: MD_LINE_BREAK)
		do
			output ("<br/>")
		end

	visit_soft_break (a_soft_break: MD_SOFT_BREAK)
		do
				-- Render soft breaks as plain newlines; HTML collapses them as spaces.
			output ("%N")
		end

	visit_footnote_reference (a_footnote: MD_FOOTNOTE_REFERENCE)
		local
			fn_id, ref_id: STRING
		do
			fn_id := "fn" + a_footnote.label
			ref_id := "fnref" + a_footnote.label
			output ("<sup id=%"")
			output_attribute_escaped (ref_id)
			output ("%"><a href=%"#")
			output_attribute_escaped (fn_id)
			output ("%">")
			output_attribute_escaped (a_footnote.label)
			output ("</a></sup>")
		end

feature -- Block

	visit_footnote_definition (a_footnote: MD_FOOTNOTE_DEFINITION)
		local
			fn_id, ref_id: STRING
		do
			fn_id := "fn" + a_footnote.label
			ref_id := "fnref" + a_footnote.label
			output ("<div class=%"footnote%" id=%"")
			output_attribute_escaped (fn_id)
			output ("%">")
			output ("<em>")
			output_escaped (a_footnote.label)
			output ("</em>:")
			visit_composite (a_footnote)
			output (" <a href=%"#")
			output_attribute_escaped (ref_id)
			output ("%">↩</a></div>%N")
		end

feature {NONE} -- Output helpers

	output (s: READABLE_STRING_8)
		do
			buffer.append (s)
		end

	output_escaped (s: READABLE_STRING_8)
		do
			append_html_escaped_to (s, buffer)
		end

	output_attribute_escaped (s: READABLE_STRING_8)
			-- Append `s` escaped for usage in attribute values.
		do
			append_html_attribute_escaped_to (s, buffer)
		end

	append_html_escaped_to (s: READABLE_STRING_8; a_output: STRING_8)
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

	append_html_attribute_escaped_to (s: READABLE_STRING_8; a_output: STRING_8)
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
				else
					a_output.append_character (c)
				end
				i := i + 1
			end
		end

end

