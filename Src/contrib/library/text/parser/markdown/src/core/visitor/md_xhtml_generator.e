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
			table_of_contents_min_level := 1
			table_of_contents_max_level := 6
			create heading_identifiers.make (0)
		ensure
			buffer_set: buffer = a_buffer
		end

feature -- Output

	buffer: STRING
			-- Output buffer.

feature -- Settings

	is_heading_identifier_enabled: BOOLEAN
			-- Do the headings have an identifier (`id' attribute, as on GitHub: "## Getting started" is
			-- "getting-started", see `heading_identifier')? Always the case in a document with a table of
			-- contents (its links use them).

	table_of_contents_min_level, table_of_contents_max_level: INTEGER
			-- Levels of the headings listed in a table of contents (1 to 6 by default).

	set_heading_identifier_enabled (b: BOOLEAN)
			-- Set `is_heading_identifier_enabled' to `b'.
		do
			is_heading_identifier_enabled := b
		ensure
			set: is_heading_identifier_enabled = b
		end

	set_table_of_contents_levels (a_min, a_max: INTEGER)
			-- List the headings of level `a_min' to `a_max' in a table of contents.
		require
			valid_levels: 1 <= a_min and a_min <= a_max and a_max <= 6
		do
			table_of_contents_min_level := a_min
			table_of_contents_max_level := a_max
		ensure
			min_set: table_of_contents_min_level = a_min
			max_set: table_of_contents_max_level = a_max
		end

feature -- Conversion

	heading_identifier (a_text: READABLE_STRING_8): STRING_8
			-- Identifier of a heading of plain text `a_text' (UTF-8), as on GitHub: in lower case, the
			-- spaces replaced by `-', the other characters removed except letters, digits, `-', `_'
			-- and the non-ASCII characters.
		local
			c: CHARACTER_8
		do
			create Result.make (a_text.count)
			across
				a_text as ic
			loop
				c := ic.item
				if c = ' ' then
					Result.append_character ('-')
				elseif c.code > 127 or c = '-' or c = '_' then
						-- (Bytes of the UTF-8 sequences kept as they are.)
					Result.append_character (c)
				elseif c.is_alpha_numeric then
					Result.append_character (c.as_lower)
				end
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
		local
			l_collector: MD_HEADINGS_COLLECTOR
			l_ids: STRING_TABLE [INTEGER]
			l_id: STRING_8
		do
			create l_collector.make
			a_document.process (l_collector)
			create heading_identifiers.make (0)
			if is_heading_identifier_enabled or not l_collector.tables_of_contents.is_empty then
					-- Unique identifiers ("-1", "-2"... added to the repeated ones).
				create l_ids.make (l_collector.headings.count)
				create heading_identifiers.make (l_collector.headings.count)
				across
					l_collector.headings as h
				loop
					l_id := heading_identifier (h.text)
					if l_ids.has (l_id) then
						l_ids.force (l_ids [l_id] + 1, l_id)
						l_id := l_id + "-" + l_ids [l_id].out
					else
						l_ids.force (0, l_id)
					end
					heading_identifiers.extend ([h, l_id])
				end
			end
			visit_composite (a_document)
		end

	visit_table_of_contents (a_toc: MD_TABLE_OF_CONTENTS)
			-- A navigation element with the nested list of the headings (of the levels to list),
			-- linked to their identifier.
		local
			l_base, l_depth, d: INTEGER
			l_headings: ARRAYED_LIST [MD_HEADING]
		do
			create l_headings.make (a_toc.headings.count)
			l_base := 7
			across
				a_toc.headings as h
			loop
				if h.level >= table_of_contents_min_level and h.level <= table_of_contents_max_level then
					l_headings.extend (h)
					l_base := l_base.min (h.level)
				end
			end
			if not l_headings.is_empty then
				output ("<nav class=%"toc%">")
				across
					l_headings as h
				loop
					d := h.level - l_base + 1
					if d > l_depth then
						from
						until
							l_depth >= d
						loop
							output ("<ul>")
							l_depth := l_depth + 1
							if l_depth < d then
								output ("<li>")
							end
						end
					else
						output ("</li>")
						from
						until
							l_depth <= d
						loop
							output ("</ul></li>")
							l_depth := l_depth - 1
						end
					end
					output ("<li><a href=%"#")
					if attached identifier_of (h) as l_id then
						output_attribute_escaped (l_id)
					end
					output ("%">")
					output_escaped (h.text)
					output ("</a>")
				end
				from
				until
					l_depth = 0
				loop
					output ("</li></ul>")
					l_depth := l_depth - 1
				end
				output ("</nav>%N")
			end
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
			if attached identifier_of (a_heading) as l_id then
				output ("<h" + a_heading.level.out + " id=%"")
				output_attribute_escaped (l_id)
				output ("%">")
			else
				output ("<h" + a_heading.level.out + ">")
			end
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

	visit_highlight (a_highlight: MD_HIGHLIGHT)
		do
			output ("<mark>")
			visit_composite (a_highlight)
			output ("</mark>")
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

feature {NONE} -- Headings

	heading_identifiers: ARRAYED_LIST [TUPLE [heading: MD_HEADING; id: STRING_8]]
			-- Identifiers of the headings of the document being generated, if any.

	identifier_of (a_heading: MD_HEADING): detachable STRING_8
			-- Identifier of `a_heading', if the headings have one.
		do
			across
				heading_identifiers as h
			until
				Result /= Void
			loop
				if h.heading = a_heading then
					Result := h.id
				end
			end
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
				elseif attached {MD_HIGHLIGHT} inline_item as l_highlight then
					collect_text_from_inlines (l_highlight, a_output)
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

