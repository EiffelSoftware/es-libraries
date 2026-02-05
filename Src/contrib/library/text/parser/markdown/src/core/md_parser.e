note
	description: "Markdown parser producing a Markdown AST."

class
	MD_PARSER

inherit
	MD_HELPER

create
	make

feature -- Initialization

	make
			-- Create a parser instance.
		do
			using_github_extension := False
		end

feature -- GitHub Flavored Markdown

	using_github_extension: BOOLEAN
			-- Enable GitHub Flavored Markdown extensions (underscore emphasis, strikethrough, task lists).

	set_using_github_extension (a_enabled: BOOLEAN)
			-- Set `using_github_extension` to `a_enabled`.
		do
			using_github_extension := a_enabled
		ensure
			using_github_extension_set: using_github_extension = a_enabled
		end

feature {NONE} -- Link reference definitions

	link_definitions: detachable HASH_TABLE [TUPLE [url: READABLE_STRING_8; title: detachable READABLE_STRING_8], STRING_8]
			-- Link reference definitions: normalized label -> [url, optional title].

feature {NONE} -- Footnote definitions

	footnote_definitions: detachable HASH_TABLE [READABLE_STRING_8, STRING_8]
			-- Footnote definitions: normalized label -> definition text (to be parsed as blocks).
		local
			k: STRING_8
		do
			if attached link_definitions as defs then
				create Result.make (0)

				across
					defs as v
				loop
					k := @ v.key
					if k.starts_with ("^") then
						Result [k.substring (2, k.count)] := v.url
					end
				end
			end
		end

feature -- Parsing

	reset
		do
			link_definitions := Void
		end

	parse (a_text: READABLE_STRING_8): MD_DOCUMENT
			-- Parse Markdown `a_text` into a document AST.
		local
			doc: MD_DOCUMENT
			l_text: READABLE_STRING_8
			l_had_link_defs: BOOLEAN
		do
			if link_definitions = Void then
					-- Collect link reference definitions and strip them from the text (CommonMark reference-style links).
				link_definitions := Void
				l_text := preprocess_link_reference_definitions (a_text)
			else
				l_had_link_defs := True
				l_text := a_text
			end

			create doc.make
			parse_blocks_into (l_text, doc)

				-- Add footnote definitions to document (as blocks at the end).
			if attached footnote_definitions as defs then
				if not l_had_link_defs then
					add_footnote_definitions_to_document (defs, doc)
				end
			end

			if not l_had_link_defs then
				link_definitions := Void
			end
			Result := doc
		ensure
			result_attached: Result /= Void
		end

feature {NONE} -- Block parsing

	parse_blocks_into (a_text: READABLE_STRING_8; a_document: MD_DOCUMENT)
			-- Parse blocks from `a_text` and append to `a_document`.
		require
			a_document_attached: a_document /= Void
		local
			lines: ARRAYED_LIST [READABLE_STRING_8]
			k, n: INTEGER
			l_line: READABLE_STRING_8
			l_trim: READABLE_STRING_8
			l_indent: INTEGER
			l_para: detachable STRING_8
			list_stack: ARRAYED_STACK [TUPLE [list: MD_LIST; indent: INTEGER]]
			l_in_code_block: BOOLEAN
			l_fence: detachable STRING_8
			l_code_info: detachable STRING_8
			l_code_buf: detachable STRING_8
			l_code_block_list_indent: INTEGER
				-- Indentation to strip from code block lines when inside a list item (0 if not in list).
			l_quote_buf: detachable STRING_8
			l_target_list: MD_LIST
			l_last_item: detachable MD_LIST_ITEM
		do
			lines := split_lines (a_text)
			create list_stack.make (0)
			n := lines.count
			from
				k := 1
			until
				k > n
			loop
				l_line := lines [k]
				l_trim := trimmed (l_line)
				l_indent := indentation_width (l_line)

				if l_in_code_block then
					if attached l_fence as f and then is_fence_closing_line (l_trim, f) then
						if not list_stack.is_empty and then list_stack.item.list.count > 0 then
							l_last_item := list_stack.item.list.elements.last
							if l_last_item /= Void then
								create_code_block_into (l_code_info, l_code_buf, l_last_item)
							end
						else
							create_code_block_into (l_code_info, l_code_buf, a_document)
						end
						l_in_code_block := False
						l_fence := Void
						l_code_info := Void
						l_code_buf := Void
						l_code_block_list_indent := 0
					else
						if l_code_buf = Void then
							create l_code_buf.make_empty
						end
							-- Strip list item indentation if code block is inside a list item
						if l_code_block_list_indent > 0 and then l_indent >= l_code_block_list_indent then
							if l_line.count > l_code_block_list_indent then
								l_code_buf.append (l_line.substring (l_code_block_list_indent + 1, l_line.count))
							end
						else
							l_code_buf.append (l_line)
						end
						l_code_buf.append ("%N")
					end
				elseif l_trim.is_empty then
					if not list_stack.is_empty then
							-- Blank line in list: create new paragraph in list item (multiple paragraphs support)
						if l_para /= Void and then not l_para.is_empty then
							l_last_item := list_stack.item.list.elements.last
							if l_last_item /= Void then
								flush_paragraph_into_list_item (l_para, l_last_item)
							end
						end
						l_para := Void
					else
						flush_paragraph_into (l_para, a_document)
						l_para := Void
						list_stack.wipe_out
					end
				else
					if attached fence_opening (l_trim) as f and then (list_stack.is_empty or else l_indent <= list_stack.item.indent) then
							-- Top-level fenced code block only when not inside list item continuation
						flush_paragraph_into (l_para, a_document)
						l_para := Void
						list_stack.wipe_out

						l_in_code_block := True
						l_fence := f
						l_code_info := fence_info_string (l_trim, f)
						create l_code_buf.make_empty
						l_code_block_list_indent := 0
					elseif attached heading_from_line (l_trim) as h then
						flush_paragraph_into (l_para, a_document)
						l_para := Void
						list_stack.wipe_out
						a_document.add_element (h)
					elseif attached setext_heading_level_from_underline (l_trim) as level and then level > 0 and then l_para /= Void then
							-- Setext heading: convert pending paragraph to heading.
						create_setext_heading_from_paragraph (l_para, level, a_document)
						l_para := Void
						list_stack.wipe_out
					elseif is_thematic_break_line (l_trim) then
						flush_paragraph_into (l_para, a_document)
						l_para := Void
						list_stack.wipe_out
						a_document.add_element (create {MD_THEMATIC_BREAK}.make)
					elseif is_html_block_start_line (l_trim) and then list_stack.is_empty then
						flush_paragraph_into (l_para, a_document)
						l_para := Void
						list_stack.wipe_out
						create l_code_buf.make_empty
						from
						until
							k > n or else lines [k].is_whitespace
						loop
							l_line := lines [k]
							l_code_buf.append (l_line)
							l_code_buf.append ("%N")
							k := k + 1
						end
						a_document.add_element (create {MD_RAW_HTML}.make (l_code_buf))
						l_code_buf := Void
						k := k - 1
					elseif is_blockquote_line (l_trim) and then (list_stack.is_empty or else l_indent <= list_stack.item.indent) then
							-- Top-level blockquote only when not inside list item continuation
						flush_paragraph_into (l_para, a_document)
						l_para := Void
						list_stack.wipe_out

						create l_quote_buf.make_empty
						from
						until
							k > n or else not is_blockquote_line (trimmed (lines [k]))
						loop
							l_line := lines [k]
							append_blockquote_line_content_to (l_line, l_quote_buf)
							l_quote_buf.append ("%N")
							k := k + 1
						end
						create_blockquote_into (l_quote_buf, a_document)
						k := k - 1
					elseif is_table_line (l_trim) then
						flush_paragraph_into (l_para, a_document)
						l_para := Void
						list_stack.wipe_out
						k := create_table_from_lines (lines, k, a_document) - 1
					elseif attached list_item_from_indented_line (l_line) as li then
						if not list_stack.is_empty then
								-- Flush any pending paragraph in previous list item
							if list_stack.item.list.count > 0 then
								l_last_item := list_stack.item.list.elements.last
								if l_last_item /= Void then
									flush_paragraph_into_list_item (l_para, l_last_item)
									l_para := Void
								end
							end
						else
							flush_paragraph_into (l_para, a_document)
							l_para := Void
						end
						l_target_list := list_for_item (li, list_stack, a_document)
							-- Create list item with initial text
						create_list_item_into (li.text, l_target_list, li.is_task, li.task_checked)
					elseif is_indented_code_block_line (l_line) and then list_stack.is_empty then
							-- Indented code block (4 spaces or 1 tab) - only at top level
						flush_paragraph_into (l_para, a_document)
						l_para := Void
						create l_code_buf.make_empty
						from
						until
							k > n or else not is_indented_code_block_line (lines [k])
						loop
							l_line := lines [k]
							if l_code_buf = Void then
								create l_code_buf.make_empty
							end
							if l_line.count >= 5 and then (l_line [1] = ' ' and l_line [2] = ' ' and l_line [3] = ' ' and l_line [4] = ' ') then
								l_code_buf.append (l_line.substring (5, l_line.count))
							elseif l_line.count >= 2 and then l_line [1] = '%T' then
								l_code_buf.append (l_line.substring (2, l_line.count))
							else
								l_code_buf.append (l_line)
							end
							l_code_buf.append ("%N")
							k := k + 1
						end
						create_code_block_into (Void, l_code_buf, a_document)
						k := k - 1
					else
							-- Paragraph line (may be part of a list item if indented).
						if
							not list_stack.is_empty and then
							l_indent > list_stack.item.indent and then
							list_stack.item.list.count > 0
						then
								-- Check if this is a code block, blockquote, or just continuation
							if attached fence_opening (l_trim) as f then
									-- Code block in list item
								l_last_item := list_stack.item.list.elements.last
								if l_last_item /= Void then
									l_in_code_block := True
									l_fence := f
									l_code_info := fence_info_string (l_trim, f)
									create l_code_buf.make_empty
										-- Track list item indentation to strip from code content
									l_code_block_list_indent := l_indent
								end
							elseif is_blockquote_line (l_trim) then
									-- Blockquote in list item
								l_last_item := list_stack.item.list.elements.last
								if l_last_item /= Void then
									create l_quote_buf.make_empty
									from
									until
										k > n or else not is_blockquote_line (trimmed (lines [k]))
									loop
										l_line := lines [k]
											-- Strip leading spaces from list item indentation before processing blockquote
										l_line := trimmed (l_line)
										append_blockquote_line_content_to (l_line, l_quote_buf)
										l_quote_buf.append ("%N")
										k := k + 1
									end
									create_blockquote_into (l_quote_buf, l_last_item)
									k := k - 1
								end
							elseif is_indented_code_block_line (l_line) and then l_indent >= list_stack.item.indent + 4 then
									-- Indented code block in list item
								l_last_item := list_stack.item.list.elements.last
								if l_last_item /= Void then
									flush_paragraph_into_list_item (l_para, l_last_item)
									l_para := Void
									create l_code_buf.make_empty
									from
									until
										k > n or else not is_indented_code_block_line (lines [k])
									loop
										l_line := lines [k]
										if l_line.count >= 5 and then (l_line [1] = ' ' and l_line [2] = ' ' and l_line [3] = ' ' and l_line [4] = ' ') then
											l_code_buf.append (l_line.substring (5, l_line.count))
										elseif l_line.count >= 2 and then l_line [1] = '%T' then
											l_code_buf.append (l_line.substring (2, l_line.count))
										else
											l_code_buf.append (l_line)
										end
										l_code_buf.append ("%N")
										k := k + 1
									end
									create_code_block_into (Void, l_code_buf, l_last_item)
									k := k - 1
								end
							else
									-- Regular paragraph continuation in list item (indented content)
									-- Build paragraph buffer, will be flushed on blank line or list end
								if l_para = Void then
									create l_para.make_empty
								else
									l_para.append ("%N")
								end
									-- Strip list item indentation from paragraph continuation lines.
								if l_indent > list_stack.item.indent and then l_line.count > l_indent then
									l_para.append (l_line.substring (l_indent + 1, l_line.count))
								else
									l_para.append (l_line)
								end
							end
						else
								-- Not in list item context - end any current list
							if not list_stack.is_empty then
									-- Flush any pending paragraph in list items before ending list
								if l_para /= Void and then not l_para.is_empty then
									l_last_item := list_stack.item.list.elements.last
									if l_last_item /= Void then
										flush_paragraph_into_list_item (l_para, l_last_item)
										l_para := Void
									end
								end
							end
							list_stack.wipe_out
							if l_para = Void then
								create l_para.make_empty
							else
								l_para.append ("%N")
							end
							l_para.append (l_line)
						end
					end
				end
				k := k + 1
			end

			if l_in_code_block then
				create_code_block_into (l_code_info, l_code_buf, a_document)
			end
			if not list_stack.is_empty and then l_para /= Void and then not l_para.is_empty then
					-- Flush any remaining paragraph in list items
				l_last_item := list_stack.item.list.elements.last
				if l_last_item /= Void then
					flush_paragraph_into_list_item (l_para, l_last_item)
					l_para := Void
				end
			end
			flush_paragraph_into (l_para, a_document)
		end

feature {NONE} -- List nesting

	list_for_item (
		a_item: TUPLE [indent: INTEGER; is_ordered: BOOLEAN; start_number: INTEGER; text: STRING_8; is_task: BOOLEAN; task_checked: BOOLEAN; list_marker: CHARACTER];
		a_stack: ARRAYED_STACK [TUPLE [list: MD_LIST; indent: INTEGER]];
		a_document: MD_DOCUMENT
	): MD_LIST
			-- Target list to receive `a_item`, creating and nesting lists as needed.
			-- Per CommonMark: two list items are same type only if same bullet char (- * +) or same ordered delimiter (. )).
		require
			a_stack_attached: a_stack /= Void
			a_document_attached: a_document /= Void
		local
			l_indent: INTEGER
			l_top: detachable TUPLE [list: MD_LIST; indent: INTEGER]
			l_new: MD_LIST
			l_parent_item: detachable MD_LIST_ITEM
		do
			l_indent := a_item.indent
			from
			until
				a_stack.is_empty or else l_indent >= a_stack.item.indent
			loop
				a_stack.remove
			end

			if a_stack.is_empty then
				l_new := new_list_from_item (a_item)
				a_document.add_element (l_new)
				a_stack.extend ([l_new, l_indent])
				Result := l_new
			else
				l_top := a_stack.item
				check l_top /= Void end
				if l_indent > l_top.indent and then l_top.list.count > 0 then
						-- Nested list under last list item.
					l_parent_item := l_top.list.elements.last
					if l_parent_item = Void then
							-- Fallback: treat as same level.
						Result := l_top.list
					else
						l_new := new_list_from_item (a_item)
						l_parent_item.add_element (l_new)
						a_stack.extend ([l_new, l_indent])
						Result := l_new
					end
				else
						-- Same level list: same type only if same ordered flag and same list_marker (CommonMark 5.3).
					if l_top.list.is_ordered = a_item.is_ordered and then l_top.list.list_marker = a_item.list_marker then
						Result := l_top.list
					else
							-- Start a new list at the same indentation.
						a_stack.remove
						if a_stack.is_empty then
							l_new := new_list_from_item (a_item)
							a_document.add_element (l_new)
						else
							l_parent_item := a_stack.item.list.elements.last
							if l_parent_item /= Void then
								l_new := new_list_from_item (a_item)
								l_parent_item.add_element (l_new)
							else
								l_new := new_list_from_item (a_item)
								a_document.add_element (l_new)
							end
						end
						a_stack.extend ([l_new, l_indent])
						Result := l_new
					end
				end
			end
		ensure
			result_attached: Result /= Void
		end

	new_list_from_item (a_item: TUPLE [indent: INTEGER; is_ordered: BOOLEAN; start_number: INTEGER; text: STRING_8; is_task: BOOLEAN; task_checked: BOOLEAN; list_marker: CHARACTER]): MD_LIST
			-- New list with kind and marker from `a_item`.
		do
			if a_item.is_ordered then
				create Result.make_ordered (a_item.start_number, a_item.list_marker)
			else
				create Result.make_unordered (a_item.list_marker)
			end
		ensure
			result_attached: Result /= Void
		end

feature {NONE} -- Indentation helpers

	indentation_width (a_line: READABLE_STRING_8): INTEGER
			-- Leading indentation width for `a_line` (space=1, tab=4).
		local
			i, n: INTEGER
			c: CHARACTER
		do
			from
				i := 1
				n := a_line.count
			until
				i > n
			loop
				c := a_line [i]
				if c = ' ' then
					Result := Result + 1
				elseif c = '%T' then
					Result := Result + 4
				else
					i := n + 1
				end
				i := i + 1
			end
		ensure
			non_negative: Result >= 0
		end

feature {NONE} -- List detection

	list_item_from_indented_line (a_line: READABLE_STRING_8): detachable TUPLE [indent: INTEGER; is_ordered: BOOLEAN; start_number: INTEGER; text: STRING_8; is_task: BOOLEAN; task_checked: BOOLEAN; list_marker: CHARACTER]
			-- List item info if `a_line` starts a list item (taking indentation into account), otherwise Void.
		local
			i, n: INTEGER
			c: CHARACTER
			indent_width: INTEGER
			start_index: INTEGER
			s: READABLE_STRING_8
		do
			n := a_line.count
			from
				i := 1
				start_index := 1
			until
				i > n
			loop
				c := a_line [i]
				if c = ' ' then
					indent_width := indent_width + 1
				elseif c = '%T' then
					indent_width := indent_width + 4
				else
					start_index := i
					i := n + 1
				end
				i := i + 1
			end
			if start_index <= n then
				s := a_line.substring (start_index, n)
				if attached list_item_from_line (s) as li then
					Result := [indent_width, li.is_ordered, li.start_number, li.text, li.is_task, li.task_checked, li.list_marker]
				end
			end
		end

	split_lines (a_text: READABLE_STRING_8): ARRAYED_LIST [READABLE_STRING_8]
			-- Lines from `a_text` (without `%N`, without trailing `%R`).
		local
			i, n, eol: INTEGER
			l_line: READABLE_STRING_8
		do
			create Result.make (10)
			from
				i := 1
				n := a_text.count
			until
				i > n + 1
			loop
				if i > n then
					Result.extend (create {STRING_8}.make_empty)
					i := n + 2
				else
					eol := index_of_end_of_line (a_text, i)
					l_line := a_text.substring (i, eol)
					if not l_line.is_empty and then l_line [l_line.count] = '%R' then
						l_line := l_line.substring (1, l_line.count - 1)
					end
					Result.extend (l_line)
					i := eol + 2
				end
			end
		ensure
			result_attached: Result /= Void
		end

	flush_paragraph_into (a_para: detachable STRING_8; a_document: MD_DOCUMENT)
			-- If `a_para` is not empty, create a paragraph and append it to `a_document`.
		require
			a_document_attached: a_document /= Void
		local
			p: MD_PARAGRAPH
			processed: STRING_8
		do
			if a_para /= Void and then not a_para.is_empty then
				processed := process_hard_line_breaks (a_para)
				create p.make
				append_inlines_to (processed, p)
				a_document.add_element (p)
			end
		end

	flush_paragraph_into_list_item (a_para: detachable STRING_8; a_list_item: MD_LIST_ITEM)
			-- If `a_para` is not empty, create a paragraph and append it to `a_list_item`.
		require
			a_list_item_attached: a_list_item /= Void
		local
			p: MD_PARAGRAPH
			processed: STRING_8
		do
			if a_para /= Void and then not a_para.is_empty then
				processed := process_hard_line_breaks (a_para)
				create p.make
				append_inlines_to (processed, p)
				a_list_item.add_element (p)
			end
		end

	create_setext_heading_from_paragraph (a_para: STRING_8; a_level: INTEGER; a_document: MD_DOCUMENT)
			-- Create a Setext heading from paragraph text `a_para` at level `a_level` (1 or 2).
		require
			a_para_attached: a_para /= Void
			valid_level: a_level = 1 or a_level = 2
			a_document_attached: a_document /= Void
		local
			h: MD_HEADING
			content: READABLE_STRING_8
		do
			create h.make (a_level)
			content := trimmed (a_para)
			if not content.is_empty then
				append_inlines_to (content, h)
			end
			a_document.add_element (h)
		end

feature {NONE} -- Block factories

	create_code_block_into (a_info: detachable READABLE_STRING_8; a_code: detachable READABLE_STRING_8; a_container: MD_COMPOSITE [MD_BLOCK])
			-- Create a code block from `a_code` and add it to `a_container`.
		require
			a_container_attached: a_container /= Void
		local
			l_code: STRING_8
			cb: MD_CODE_BLOCK
		do
			if a_code = Void then
				create l_code.make_empty
			else
				create l_code.make_from_string (a_code)
			end
				-- Remove trailing newline, if any, to avoid extra blank line at end of code blocks.
			if l_code.count > 0 and then l_code [l_code.count] = '%N' then
				l_code.remove_tail (1)
			end
			create cb.make (a_info, l_code)
			a_container.add_element (cb)
		end

	create_blockquote_into (a_text: READABLE_STRING_8; a_container: MD_COMPOSITE [MD_BLOCK])
			-- Create a blockquote from `a_text` and add it to `a_container`.
		require
			a_container_attached: a_container /= Void
		local
			bq: MD_BLOCKQUOTE
			sub: MD_DOCUMENT
		do
			create bq.make
			sub := parse (a_text)
			across
				sub.elements as e
			loop
				bq.add_element (e)
			end
			a_container.add_element (bq)
		end

	create_list_item_into (a_text: READABLE_STRING_8; a_list: MD_LIST; a_is_task: BOOLEAN; a_task_checked: BOOLEAN)
			-- Create a list item with initial text (creates paragraph immediately).
		require
			a_list_attached: a_list /= Void
		local
			it: MD_LIST_ITEM
			p: MD_PARAGRAPH
			processed: STRING_8
		do
			create it.make
			if a_is_task then
				it.set_task (a_task_checked)
			end
			processed := process_hard_line_breaks (a_text)
			create p.make
			append_inlines_to (processed, p)
			it.add_element (p)
			a_list.add_element (it)
		end

	create_list_item_start (a_text: READABLE_STRING_8; a_list: MD_LIST; a_is_task: BOOLEAN; a_task_checked: BOOLEAN)
			-- Create a list item structure without adding initial paragraph (for continuation).
		require
			a_list_attached: a_list /= Void
		local
			it: MD_LIST_ITEM
		do
			create it.make
			if a_is_task then
				it.set_task (a_task_checked)
			end
			a_list.add_element (it)
		end

	create_table_from_lines (a_lines: ARRAYED_LIST [READABLE_STRING_8]; a_start: INTEGER; a_document: MD_DOCUMENT): INTEGER
			-- Parse table starting at line `a_start` and append to `a_document`.
			-- Returns the line index after the table.
			-- Supports: column alignment (from separator), tables without header row (separator first), empty cells.
		require
			a_lines_attached: a_lines /= Void
			valid_start: a_start >= 1 and a_start <= a_lines.count
			a_document_attached: a_document /= Void
		local
			tbl: MD_TABLE
			row: MD_TABLE_ROW
			cell: MD_TABLE_CELL
			header_cell: MD_TABLE_HEADER_CELL
			k, n, col: INTEGER
			l_line: READABLE_STRING_8
			l_trim: READABLE_STRING_8
			cells: ARRAYED_LIST [READABLE_STRING_8]
			is_header: BOOLEAN
			is_separator: BOOLEAN
			alignments: detachable ARRAY [detachable READABLE_STRING_8]
		do
			create tbl.make
			n := a_lines.count
			from
				k := a_start
				is_header := True
			until
				k > n
			loop
				l_line := a_lines [k]
				l_trim := trimmed (l_line)
				if l_trim.is_empty then
					Result := k
					k := n + 1
				elseif not is_table_line (l_trim) then
					Result := k
					k := n + 1
				else
					is_separator := is_table_separator_line (l_trim)
					if is_separator then
						alignments := parse_table_alignments (l_trim)
						if alignments /= Void then
							tbl.set_alignments (alignments)
							if tbl.count > 0 then
								apply_alignments_to_row (tbl.elements.first, alignments)
							end
						end
						is_header := False
					else
						create row.make
						cells := split_table_row (l_trim)
						alignments := tbl.alignments
						from
							col := 1
						until
							col > cells.count
						loop
							if is_header then
								create header_cell.make
								append_inlines_to (cells [col], header_cell)
								if alignments /= Void and then col <= alignments.upper and then alignments [col] /= Void then
									header_cell.set_alignment (alignments [col])
								end
								row.add_element (header_cell)
							else
								create cell.make
								append_inlines_to (cells [col], cell)
								if alignments /= Void and then col <= alignments.upper and then alignments [col] /= Void then
									cell.set_alignment (alignments [col])
								end
								row.add_element (cell)
							end
							col := col + 1
						end
						tbl.add_element (row)
					end
					k := k + 1
				end
			end
			if Result = 0 then
				Result := n + 1
			end
			if tbl.count > 0 then
				a_document.add_element (tbl)
			end
		ensure
			result_valid: Result >= a_start and Result <= a_lines.count + 1
		end

	apply_alignments_to_row (a_row: MD_TABLE_ROW; a_alignments: ARRAY [detachable READABLE_STRING_8])
			-- Set alignment on each cell of `a_row` from `a_alignments` (1-based column index).
		require
			a_row_attached: a_row /= Void
			a_alignments_attached: a_alignments /= Void
		local
			col: INTEGER
			c: MD_TABLE_CELL
		do
			from
				col := 1
			until
				col > a_row.count or col > a_alignments.upper
			loop
				if attached a_alignments [col] as align_val then
					c := a_row.elements [col]
					c.set_alignment (align_val)
				end
				col := col + 1
			end
		end

	parse_table_alignments (a_separator_line: READABLE_STRING_8): detachable ARRAY [detachable READABLE_STRING_8]
			-- Parse column alignments from separator line: :--- left, :---: center, ---: right, --- default.
			-- Split by `|`; each segment (trimmed) gives one column alignment.
		require
			a_separator_line_attached: a_separator_line /= Void
		local
			parts: ARRAYED_LIST [READABLE_STRING_8]
			seg: READABLE_STRING_8
			i, n: INTEGER
			align: detachable READABLE_STRING_8
		do
			parts := split_table_row (a_separator_line)
			if parts.count > 0 then
				create Result.make_filled (Void, 1, parts.count)
				from
					i := 1
					n := parts.count
				until
					i > n
				loop
					seg := trimmed (parts [i])
					if seg.count >= 1 then
						if seg.count >= 2 and then seg [1] = ':' and then seg [seg.count] = ':' then
							align := "center"
						elseif seg.count >= 1 and then seg [seg.count] = ':' then
							align := "right"
						elseif seg.count >= 1 and then seg [1] = ':' then
							align := "left"
						else
							align := Void
						end
					else
						align := Void
					end
					Result [i] := align
					i := i + 1
				end
			end
		end

feature {NONE} -- Block detection

	fence_opening (a_line: READABLE_STRING_8): detachable STRING_8
			-- Fence marker if `a_line` opens a fenced code block, otherwise Void.
			-- Supports backtick fence: ``` or tilde fence: ~~~
		local
			s: STRING_8
			i, n, count: INTEGER
			c: CHARACTER
		do
			create s.make_from_string (a_line)
			n := s.count
			if n >= 3 then
				c := s [1]
				if c = '`' or c = '~' then
					from
						i := 1
						count := 0
					until
						i > n or else s [i] /= c
					loop
						count := count + 1
						i := i + 1
					end
					if count >= 3 then
						Result := s.substring (1, count)
					end
				end
			end
		end

	fence_info_string (a_line: READABLE_STRING_8; a_fence: READABLE_STRING_8): detachable STRING_8
			-- Info string part of a fence opening line.
		local
			s: STRING_8
			p: INTEGER
		do
			create s.make_from_string (a_line)
			p := a_fence.count + 1
			if p <= s.count then
				s := left_trimmed (s.substring (p, s.count)).to_string_8
				if not s.is_empty then
					Result := s
				end
			end
		end

	is_fence_closing_line (a_line: READABLE_STRING_8; a_fence: READABLE_STRING_8): BOOLEAN
			-- Is `a_line` a closing fence line for `a_fence`?
		local
			s: STRING_8
		do
			create s.make_from_string (a_line)
			Result := s.starts_with (a_fence)
		end

	heading_from_line (a_line: READABLE_STRING_8): detachable MD_HEADING
			-- Heading node if `a_line` is an ATX heading, otherwise Void.
		local
			s: STRING_8
			i, n, lvl: INTEGER
			content: READABLE_STRING_8
			h: MD_HEADING
		do
			create s.make_from_string (a_line)
			from
				i := 1
				n := s.count
			until
				i > n or else s [i] /= '#'
			loop
				lvl := lvl + 1
				i := i + 1
			end
			if lvl >= 1 and lvl <= 6 then
				if i > n then
					create h.make (lvl)
					Result := h
				elseif s [i] = ' ' then
					create h.make (lvl)
					if i + 1 <= n then
						content := right_trimmed (s.substring (i + 1, n))
						append_inlines_to (content, h)
					end
					Result := h
				end
			end
		end

	setext_heading_level_from_underline (a_line: READABLE_STRING_8): INTEGER
			-- Heading level (1 or 2) if `a_line` is a Setext underline, otherwise 0.
			-- Setext underlines: `====` for H1, `----` for H2 (at least 3 characters).
		local
			s: STRING_8
			i, n, cnt: INTEGER
			ch: CHARACTER
		do
			create s.make_from_string (a_line)
			n := s.count
			from
				i := 1
			until
				i > n or else (s [i] /= ' ' and s [i] /= '%T')
			loop
				i := i + 1
			end
			if i <= n then
				ch := s [i]
				if ch = '=' or ch = '-' then
					from
					until
						i > n
					loop
						if s [i] = ch then
							cnt := cnt + 1
						elseif s [i] = ' ' or s [i] = '%T' then
								-- ignore spaces
						else
								-- Not a Setext underline
							cnt := 0
							i := n + 1
						end
						i := i + 1
					end
					if cnt >= 3 then
						if ch = '=' then
							Result := 1
						else
							Result := 2
						end
					end
				end
			end
		end

	is_thematic_break_line (a_line: READABLE_STRING_8): BOOLEAN
			-- Is `a_line` a thematic break line (---, ***, ___ with optional spaces)?
			-- Note: Does not match Setext underlines (which are handled separately).
		local
			s: STRING_8
			i, n, cnt: INTEGER
			ch: CHARACTER
		do
			create s.make_from_string (a_line)
			n := s.count
			Result := False
			from
				i := 1
			until
				i > n or else not (s [i]).is_space
			loop
				i := i + 1
			end
			if i <= n then
				ch := s [i]
				if ch = '-' or ch = '*' or ch = '_' then
					Result := True
					from
					until
						i > n or else not Result
					loop
						if s [i] = ch then
							cnt := cnt + 1
						elseif (s [i]).is_space then
								-- ignore
						else
							Result := False
						end
						i := i + 1
					end
					Result := Result and cnt >= 3
				end
			end
		end

	is_blockquote_line (a_line: READABLE_STRING_8): BOOLEAN
		do
			Result := not a_line.is_empty and then a_line [1] = '>'
		end

	html_block_element_name (a_trimmed_line: READABLE_STRING_8): detachable READABLE_STRING_8
			-- Is `a_trimmed_line` the start of a raw HTML block (CommonMark type 2-7)?
			-- Line must start with `<` followed by letter, `</`+letter, `<!--`, `<?`, or `<!`.
		local
			c: CHARACTER
			i, p, n: INTEGER
			l_is_left_trimming: BOOLEAN
			l_is_not_html_block_element: BOOLEAN
		do
			if a_trimmed_line.count >= 2 and then a_trimmed_line [1] = '<' then
				from
					i := 2
					p := i
					n := a_trimmed_line.count
					l_is_left_trimming := True
				until
					i > n or Result /= Void or l_is_not_html_block_element
				loop
					c := a_trimmed_line [i]
					if l_is_left_trimming then
						if c.is_space then
							-- Skip
						elseif c = '/' or c = '?' then
							-- Skip
						elseif c = '>' then
							Result := a_trimmed_line.substring (p, i - 1)
						elseif c = '!' then
							if a_trimmed_line.substring (i, i + 2).same_string ("!--") then
								Result := "!--"
							end
						else
							l_is_left_trimming := False
							p := i
						end
					end
					if Result = Void and not l_is_left_trimming then
						if c.is_space or c = '>' or c = '/' or c = '!' or c = '?' then
							Result := a_trimmed_line.substring (p, i - 1)
						elseif c.is_alpha then
								-- check next ...
						else
							l_is_not_html_block_element := True
						end
					end
					i := i + 1
				end
			end
		end

	is_html_block_start_line (a_trimmed_line: READABLE_STRING_8): BOOLEAN
			-- Is `a_trimmed_line` the start of a raw HTML block (CommonMark type 2-7)?
			-- Line must start with `<` followed by letter, `</`+letter, `<!--`, `<?`, or `<!`.
		local
--			c2: CHARACTER
		do
			Result := html_block_element_name (a_trimmed_line) /= Void
--			if a_trimmed_line.count >= 2 and then a_trimmed_line [1] = '<' then
--				c2 := a_trimmed_line [2]
--				Result := (c2 >= 'a' and c2 <= 'z') or (c2 >= 'A' and c2 <= 'Z')
--					or (c2 = '/' and then a_trimmed_line.count >= 3 and then ((a_trimmed_line [3] >= 'a' and a_trimmed_line [3] <= 'z') or (a_trimmed_line [3] >= 'A' and a_trimmed_line [3] <= 'Z')))
--					or (c2 = '!' and then a_trimmed_line.count >= 3)
--					or (c2 = '?')
--			end
		end

	is_indented_code_block_line (a_line: READABLE_STRING_8): BOOLEAN
			-- Is `a_line` an indented code block line (4 spaces or 1 tab)?
		do
			if not a_line.is_empty then
				if a_line.count >= 4 and then a_line [1] = ' ' and then a_line [2] = ' ' and then a_line [3] = ' ' and then a_line [4] = ' ' then
					Result := True
				elseif a_line.count >= 1 and then a_line [1] = '%T' then
					Result := True
				end
			end
		end

	is_table_line (a_line: READABLE_STRING_8): BOOLEAN
			-- Is `a_line` a table row line (contains `|`)?
		local
			p: INTEGER
		do
			if not a_line.is_empty then
				p := a_line.index_of ('|', 1)
				if p <= 0 then
					-- False
				elseif p = 1 then
					Result := True
				else
					if p > 1 and a_line [p - 1] /= '\' then
						Result := True
					end
				end
			end
		end

	is_table_separator_line (a_line: READABLE_STRING_8): BOOLEAN
			-- Is `a_line` a table separator row (|----|----|)?
		local
			s: STRING_8
			i, n: INTEGER
			c: CHARACTER
			has_pipe: BOOLEAN
			has_dash: BOOLEAN
		do
			create s.make_from_string (a_line)
			n := s.count
			Result := True
			from
				i := 1
			until
				i > n
			loop
				c := s [i]
				if c = '|' then
					has_pipe := True
				elseif c = '-' or c = ':' then
					has_dash := True
				elseif c /= ' ' and c /= '%T' then
					Result := False
					i := n + 1
				end
				i := i + 1
			end
			if Result then
				Result := has_pipe and has_dash
			end
		end

	split_table_row (a_line: READABLE_STRING_8): ARRAYED_LIST [READABLE_STRING_8]
			-- Split `a_line` into table cells (by `|`).
			-- Preserves empty cells between pipes (e.g. | A | | C | gives ["A","","C"]). Leading/trailing pipes optional.
		require
			a_line_attached: a_line /= Void
		local
			s: STRING_8
			i, n, start: INTEGER
			c: CHARACTER
			cell: READABLE_STRING_8
			first_pipe: BOOLEAN
		do
			create Result.make (5)
			create s.make_from_string (a_line)
			n := s.count
			first_pipe := True
			from
				i := 1
				start := 1
			until
				i > n
			loop
				c := s [i]
				if c = '|' then
					if first_pipe and start = i then
							-- Leading pipe (optional): skip empty segment.
						start := i + 1
					elseif start < i then
						cell := trimmed (s.substring (start, i - 1))
						Result.extend (cell)
						start := i + 1
					else
							-- Empty cell (consecutive pipes).
						Result.extend (create {STRING_8}.make_empty)
						start := i + 1
					end
					first_pipe := False
				end
				i := i + 1
			end
			if start <= n then
					-- Trailing content (no trailing pipe, or content before trailing pipe).
				cell := trimmed (s.substring (start, n))
				Result.extend (cell)
			end
		ensure
			result_attached: Result /= Void
		end

	append_blockquote_line_content_to (a_line: READABLE_STRING_8; a_output: STRING_8)
			-- Append line content after the blockquote marker(s) to `a_output`.
			-- Handles nested blockquotes: `> > nested` becomes `> nested` in output (one level removed).
		require
			a_output_attached: a_output /= Void
		local
			s: READABLE_STRING_8
			p, level, i: INTEGER
			content_start: INTEGER
		do
--			create s.make_from_string (a_line)
			s := left_trimmed (a_line)
			from
				p := 1
			until
				p > s.count or else s [p] /= '>'
			loop
				level := level + 1
				p := p + 1
				if p <= s.count and then s [p] = ' ' then
					p := p + 1
				end
			end
			content_start := p
			if level > 1 then
					-- Nested blockquote: remove one level (add level-1 `>` markers back)
				from
					i := 2
				until
					i > level
				loop
					a_output.append ("> ")
					i := i + 1
				end
			end
			if content_start <= s.count then
				a_output.append (s.substring (content_start, s.count))
			end
		end

	list_item_from_line (a_line: READABLE_STRING_8): detachable TUPLE [is_ordered: BOOLEAN; start_number: INTEGER; text: STRING_8; is_task: BOOLEAN; task_checked: BOOLEAN; list_marker: CHARACTER]
			-- List item info if `a_line` starts a list item, otherwise Void.
			-- For unordered: list_marker is bullet character ('-', '*', '+'). For ordered: delimiter ('.' or ')').
		local
			s: STRING_8
			n, i, p, num: INTEGER
			c: CHARACTER
			txt: STRING_8
			is_task: BOOLEAN
			task_checked: BOOLEAN
		do
			create s.make_from_string (a_line)
			n := s.count
			if n >= 2 then
				c := s [1]
				if (c = '-' or c = '*' or c = '+') and then s [2] = ' ' then
					txt := s.substring (3, n)
					if using_github_extension and then txt.count >= 4 and then txt [1] = '[' and then (txt [2] = ' ' or txt [2] = 'x' or txt [2] = 'X') and then txt [3] = ']' and then txt [4] = ' ' then
						is_task := True
						task_checked := (txt [2] = 'x' or txt [2] = 'X')
						txt := txt.substring (5, txt.count)
					end
					Result := [False, 1, txt, is_task, task_checked, c]
				else
						-- Ordered: 1. item
					from
						i := 1
					until
						i > n or else not s [i].is_digit
					loop
						num := num * 10 + (s [i].code - ('0').code)
						i := i + 1
					end
					if num > 0 and then i + 1 <= n then
						if (s [i] = '.' or s [i] = ')') and then s [i + 1] = ' ' then
							p := i + 2
							if p <= n then
								txt := s.substring (p, n)
							else
								create txt.make_empty
							end
							if using_github_extension and then txt.count >= 4 and then txt [1] = '[' and then (txt [2] = ' ' or txt [2] = 'x' or txt [2] = 'X') and then txt [3] = ']' and then txt [4] = ' ' then
								is_task := True
								task_checked := (txt [2] = 'x' or txt [2] = 'X')
								txt := txt.substring (5, txt.count)
							end
							Result := [True, num, txt, is_task, task_checked, s [i]]
						end
					end
				end
			end
		end

feature {NONE} -- Hard line breaks

	process_hard_line_breaks (a_text: READABLE_STRING_8): STRING_8
			-- Process hard line breaks in `a_text` (two trailing spaces or backslash at end of line).
			-- Returns text with hard line breaks replaced by a special marker.
		require
			a_text_attached: a_text /= Void
		local
			lines: ARRAYED_LIST [READABLE_STRING_8]
			line: READABLE_STRING_8
			i, n: INTEGER
		do
			create Result.make (a_text.count)
			lines := split_lines (a_text)
			from
				i := 1
				n := lines.count
			until
				i > n
			loop
				line := lines [i]
				if not line.is_empty then
					if line.count >= 2 and then line [line.count - 1] = ' ' and then line [line.count] = ' ' then
							-- Two trailing spaces: hard line break
						Result.append (line.substring (1, line.count - 2))
						Result.append ("%N<LINE_BREAK>%N")
					elseif line.count >= 1 and then line [line.count] = '\' then
							-- Trailing backslash: hard line break
						Result.append (line.substring (1, line.count - 1))
						Result.append ("%N<LINE_BREAK>%N")
					else
						Result.append (line)
						if i < n then
							Result.append ("%N")
						end
					end
				else
					Result.append (line)
					if i < n then
						Result.append ("%N")
					end
				end
				i := i + 1
			end
		ensure
			result_attached: Result /= Void
		end

feature {NONE} -- Link reference definition helpers

	preprocess_link_reference_definitions (a_text: READABLE_STRING_8): STRING_8
			-- Collect link reference definitions from `a_text` and return text without definition lines.
		local
			lines: ARRAYED_LIST [READABLE_STRING_8]
			l_line: READABLE_STRING_8
			i, n: INTEGER
			defs: HASH_TABLE [TUPLE [url: READABLE_STRING_8; title: detachable READABLE_STRING_8], STRING_8]
		do
			lines := split_lines (a_text)
			create Result.make (a_text.count)
			create defs.make (5)
			from
				i := 1
				n := lines.count
			until
				i > n
			loop
				l_line := lines [i]
				if not is_link_reference_definition_line (l_line, defs) then
					Result.append (l_line)
					if i < n then
						Result.append ("%N")
					end
				end
				i := i + 1
			end
			if defs.count > 0 then
				link_definitions := defs
			else
				link_definitions := Void
			end
		ensure
			result_attached: Result /= Void
		end

	is_link_reference_definition_line (
		a_line: READABLE_STRING_8;
		a_defs: HASH_TABLE [TUPLE [url: READABLE_STRING_8; title: detachable READABLE_STRING_8], STRING_8]
	): BOOLEAN
			-- Is `a_line` a link reference definition `[label]: url "title"`?
			-- If so, add it to `a_defs` and return True; otherwise False.
		require
			a_defs_attached: a_defs /= Void
		local
			s, url: READABLE_STRING_8
			title: detachable READABLE_STRING_8
			i, n, r: INTEGER
			label: READABLE_STRING_8
			normalized: STRING_8
			quote_pos: INTEGER
		do
			s := trimmed (a_line)
			n := s.count
			if n >= 5 and then s [1] = '[' then -- and then s [2] /= '^' then
				r := s.index_of (']', 2)
				if r > 2 and then r < n and then s [r + 1] = ':' then
						-- Label between [ and ]
					label := s.substring (2, r - 1)
						-- Skip spaces after colon
					from
						i := r + 2
					until
						i > n or else not (s [i]).is_space
					loop
						i := i + 1
					end
					if i <= n then
						url := s.substring (i, n)
							-- Extract optional title and strip it from `url` (reuse same logic as for images).
						title := extract_title_from_url_string (url)
						if title /= Void then
								-- Remove title from url: find space followed by quote
							from
								quote_pos := 1
							until
								quote_pos > url.count
							loop
								if (url [quote_pos] = ' ' or url [quote_pos] = '%T') and then
								   quote_pos < url.count and then
								   (url [quote_pos + 1] = '"' or url [quote_pos + 1] = '%'')
								then
										-- Found space before quote: URL ends before this space
									url := trimmed (url.substring (1, quote_pos - 1))
									quote_pos := url.count + 1
								else
									quote_pos := quote_pos + 1
								end
							end
						end
						url := trimmed (url)
						if not url.is_empty then
							normalized := normalize_reference_label (label)
							if not a_defs.has (normalized) then
								a_defs.force ([url, title], normalized)
							end
							Result := True
						end
					end
				end
			end
		end

	normalize_reference_label (a_label: READABLE_STRING_8): STRING_8
			-- Normalized reference label: trimmed, internal whitespace collapsed, case-folded.
		require
			a_label_attached: a_label /= Void
		local
			s: READABLE_STRING_8
			i, n: INTEGER
			c: CHARACTER
			in_space: BOOLEAN
		do
			s := trimmed (a_label)
			create Result.make (s.count)
			from
				i := 1
				n := s.count
			until
				i > n
			loop
				c := s [i]
				if c = ' ' or c = '%T' or c = '%N' or c = '%R' then
					if not in_space and then not Result.is_empty then
						Result.append_character (' ')
					end
					in_space := True
				else
					in_space := False
					Result.append_character (c.as_lower)
				end
				i := i + 1
			end
		ensure
			result_attached: Result /= Void
		end

feature {NONE} -- Footnote definition helpers

	add_footnote_definitions_to_document (
		a_defs: HASH_TABLE [READABLE_STRING_8, STRING_8];
		a_document: MD_DOCUMENT
	)
			-- Add footnote definitions from `a_defs` to `a_document` as MD_FOOTNOTE_DEFINITION blocks.
		require
			a_defs_attached: a_defs /= Void
			a_document_attached: a_document /= Void
		local
			fn_def: MD_FOOTNOTE_DEFINITION
			label: STRING_8
			def_text: READABLE_STRING_8
			sub_doc: MD_DOCUMENT
		do
			across
				a_defs as def
			loop
				label := @ def.key
				def_text := def
				create fn_def.make (label)
					-- Parse definition text as blocks and add to footnote definition.
					-- Use parse_blocks_into directly to avoid recursive preprocessing.
				create sub_doc.make
				parse_blocks_into (def_text, sub_doc)
				across
					sub_doc.elements as block
				loop
					fn_def.add_element (block)
				end
				a_document.add_element (fn_def)
			end
		end

feature {NONE} -- Inline parsing

	append_inlines_to (a_text: READABLE_STRING_8; a_container: MD_COMPOSITE [MD_INLINE])
			-- Parse `a_text` into inline items and append to `a_container`.
		require
			a_container_attached: a_container /= Void
		local
			items: ARRAYED_LIST [MD_INLINE]
		do
			items := parse_inlines (a_text)
			across
				items as e
			loop
				a_container.add_element (e)
			end
		end

	parse_inlines (a_text: READABLE_STRING_8): ARRAYED_LIST [MD_INLINE]
			-- Parse `a_text` into a list of inline nodes.
		local
			s: STRING_8
			i, n, j: INTEGER
			buf: STRING_8
			inner: STRING_8
			delim: STRING_8
			url: STRING_8
			img_title: detachable STRING_8
			tmp: INTEGER
			quote_pos: INTEGER
			em: MD_EMPHASIS
			st: MD_STRONG
			strike: MD_STRIKETHROUGH
			lnk: MD_LINK
			img: MD_IMAGE
			br: MD_LINE_BREAK
			run_len: INTEGER
			label_text, ref_label, norm: STRING_8
			label_end: INTEGER
			handled: BOOLEAN
		do
			create Result.make (5)
			create s.make_from_string (a_text)
			create buf.make_empty
			from
				i := 1
				n := s.count
			until
				i > n
			loop
				if i + 11 <= s.count and then s.substring (i, i + 11).same_string ("<LINE_BREAK>") then
						-- Hard line break marker (12 characters: <LINE_BREAK>)
					flush_text_buffer_to (buf, Result)
					create br.make
					Result.extend (br)
					i := i + 12
						-- Skip newline after marker if present
					if i <= n and then s [i] = '%N' then
						i := i + 1
					end
				elseif s [i] = '<' and then i + 1 <= n then
						-- Autolink: <url> or <email>
					j := s.index_of ('>', i + 1)
					if j > i + 1 then
						inner := s.substring (i + 1, j - 1)
						if is_autolink_url (inner) or is_autolink_email (inner) then
							flush_text_buffer_to (buf, Result)
							create lnk.make (inner)
								-- Add URL/email as text content for autolinks
							lnk.add_element (create {MD_TEXT}.make (inner))
							Result.extend (lnk)
							i := j + 1
						else
							buf.append_character ('<')
							i := i + 1
						end
					else
						buf.append_character ('<')
						i := i + 1
					end
				else
					inspect s [i]
					when '\' then
							-- Full backslash escapes: only escapable punctuation is unescaped.
						if i + 1 <= n then
							if is_escapable_punctuation (s [i + 1]) then
								buf.append_character (s [i + 1])
								i := i + 2
							else
									-- Backslash before non-escapable: keep the backslash.
								buf.append_character ('\')
								i := i + 1
							end
						else
								-- Lone trailing backslash.
							buf.append_character ('\')
							i := i + 1
						end
					when '`' then
							-- Code span with variable-length backtick delimiter (CommonMark-like).
						run_len := backtick_run_length (s, i)
						create delim.make_filled ('`', run_len)
						j := s.substring_index (delim, i + run_len)
						if j > 0 then
							flush_text_buffer_to (buf, Result)
							inner := s.substring (i + run_len, j - 1)
							inner := normalized_code_span_content (inner)
							Result.extend (create {MD_CODE_SPAN}.make (inner))
							i := j + run_len
						else
								-- No closing delimiter: treat as literal backticks.
							buf.append (delim)
							i := i + run_len
						end
					when '~' then
							-- Strikethrough (GitHub Flavored Markdown): ~~text~~
						if using_github_extension and then i + 1 <= n and then s [i + 1] = '~' then
							j := s.substring_index ("~~", i + 2)
							if j > 0 then
								flush_text_buffer_to (buf, Result)
								inner := s.substring (i + 2, j - 1)
								create strike.make
								append_inlines_to (inner, strike)
								Result.extend (strike)
								i := j + 2
							else
								buf.append_character ('~')
								i := i + 1
							end
						else
							buf.append_character ('~')
							i := i + 1
						end
					when '%N' then
							-- Soft line break inside a paragraph.
						flush_text_buffer_to (buf, Result)
						Result.extend (create {MD_SOFT_BREAK}.make)
						i := i + 1
					when '*' then
						if i + 1 <= n and then s [i + 1] = '*' then
							j := s.substring_index ("**", i + 2)
							if j > 0 and then j + 2 <= n and then s [j + 2] = '*' then
									-- Handle the triple *** for strong and emphasis
								j := j + 1
							end
							if j > 0 then
								flush_text_buffer_to (buf, Result)
								inner := s.substring (i + 2, j - 1)
								create st.make
								append_inlines_to (inner, st)
								Result.extend (st)
								i := j + 2
							else
								buf.append_character ('*')
								i := i + 1
							end
						else
							j := s.index_of ('*', i + 1)
							if j > 0 then
								flush_text_buffer_to (buf, Result)
								inner := s.substring (i + 1, j - 1)
								create em.make
								append_inlines_to (inner, em)
								Result.extend (em)
								i := j + 1
							else
								buf.append_character ('*')
								i := i + 1
							end
						end
					when '_' then
							-- Underscore emphasis/strong (CommonMark): _text_ or __text__ (word boundaries).
						if i + 1 <= n and then s [i + 1] = '_' then
								-- Strong: __text__
							j := s.substring_index ("__", i + 2)
							if j > 0 and then j + 2 <= n and then s [j + 2] = '_' then
									-- Handle the triple ___ for strong and emphasis
								j := j + 1
							end
							if j > 0 and then is_word_boundary_at (s, i) and then is_word_boundary_at (s, j + 2) then
								flush_text_buffer_to (buf, Result)
								inner := s.substring (i + 2, j - 1)
								create st.make
								append_inlines_to (inner, st)
								Result.extend (st)
								i := j + 2
							else
								buf.append_character ('_')
								i := i + 1
							end
						else
								-- Emphasis: _text_
							j := s.index_of ('_', i + 1)
							if j > 0 and then is_word_boundary_at (s, i) and then is_word_boundary_at (s, j + 1) then
								flush_text_buffer_to (buf, Result)
								inner := s.substring (i + 1, j - 1)
								create em.make
								append_inlines_to (inner, em)
								Result.extend (em)
								i := j + 1
							else
								buf.append_character ('_')
								i := i + 1
							end
						end
					when '&' then
							-- Entity reference: &name; or &#n; or &#xHH; (CommonMark).
						if attached parse_entity_at (s, i) as ent and then ent.next_pos > i then
							flush_text_buffer_to (buf, Result)
							buf.append (ent.decoded)
							i := ent.next_pos
						else
							buf.append_character ('&')
							i := i + 1
						end
					when '!' then
							-- Image: ![alt](url), ![alt](url "title"), ![alt][ref], ![alt][], or ![alt]
						if i + 1 <= n and then s [i + 1] = '[' then
							tmp := s.index_of (']', i + 2)
							if tmp > 0 then
								if tmp + 1 <= n and then s [tmp + 1] = '(' then
										-- 1) Inline image: ![alt](url) or ![alt](url "title")
									j := s.index_of (')', tmp + 2)
									if j > 0 then
										flush_text_buffer_to (buf, Result)
										inner := s.substring (i + 2, tmp - 1)
										url := s.substring (tmp + 2, j - 1)
											-- Check for title in quotes and extract it
										img_title := extract_title_from_url_string (url)
										if img_title /= Void then
												-- Remove title from url: find space followed by quote
											from
												quote_pos := 1
											until
												quote_pos > url.count
											loop
												if (url [quote_pos] = ' ' or url [quote_pos] = '%T') and then
												   quote_pos < url.count and then
												   (url [quote_pos + 1] = '"' or url [quote_pos + 1] = '%'')
												then
														-- Found space before quote: URL ends before this space
													url := trimmed (url.substring (1, quote_pos - 1)).to_string_8
													quote_pos := url.count + 1
												else
													quote_pos := quote_pos + 1
												end
											end
										end
										create img.make (trimmed (url).to_string_8, img_title)
										append_inlines_to (inner, img)
										Result.extend (img)
										i := j + 1
									else
										buf.append_character ('!')
										i := i + 1
									end
								else
										-- 2) Reference-style images: ![alt][ref], ![alt][], or ![alt]
									if attached link_definitions as defs then
										inner := s.substring (i + 2, tmp - 1)
										handled := False

											-- 2a) Explicit / collapsed: ![alt][ref] or ![alt][]
										if not handled and then tmp + 1 <= n and then s [tmp + 1] = '[' then
											label_end := s.index_of (']', tmp + 2)
											if label_end > 0 then
													-- Label inside second [] (may be empty for collapsed)
												ref_label := s.substring (tmp + 2, label_end - 1)
												if ref_label.is_empty then
														-- Collapsed: use alt text as label
													ref_label := inner
												end
												norm := normalize_reference_label (ref_label)
												if defs.has (norm) and then attached defs.item (norm) as def then
													flush_text_buffer_to (buf, Result)
													create img.make (def.url, def.title)
													append_inlines_to (inner, img)
													Result.extend (img)
													i := label_end + 1
													handled := True
												end
											end
										end

											-- 2b) Shortcut: ![alt] with implicit label = alt
										if not handled then
											norm := normalize_reference_label (inner)
											if defs.has (norm) and then attached defs.item (norm) as def then
												flush_text_buffer_to (buf, Result)
												create img.make (def.url, def.title)
												append_inlines_to (inner, img)
												Result.extend (img)
												i := tmp + 1
												handled := True
											end
										end

										if not handled then
											buf.append_character ('!')
											i := i + 1
										end
									else
										buf.append_character ('!')
										i := i + 1
									end
								end
							else
								buf.append_character ('!')
								i := i + 1
							end
						else
							buf.append_character ('!')
							i := i + 1
						end
					when '[' then
							-- Check for footnote reference: [^label]
						if i + 1 <= n and then s [i + 1] = '^' then
							tmp := s.index_of (']', i + 2)
							if tmp > 0 and then attached footnote_definitions as defs then
								inner := s.substring (i + 2, tmp - 1)
								norm := normalize_reference_label (inner)
								if defs.has (norm) then
									flush_text_buffer_to (buf, Result)
									Result.extend (create {MD_FOOTNOTE_REFERENCE}.make (inner))
									i := tmp + 1
								else
									buf.append_character ('[')
									i := i + 1
								end
							else
								buf.append_character ('[')
								i := i + 1
							end
						else
							tmp := s.index_of (']', i + 1)
							if tmp > 0 then
									-- 1) Inline link: [text](url)
								if tmp + 1 <= n and then s [tmp + 1] = '(' then
									j := s.index_of (')', tmp + 2)
									if j > 0 then
										flush_text_buffer_to (buf, Result)
										inner := s.substring (i + 1, tmp - 1)
										url := s.substring (tmp + 2, j - 1)
											-- Extract optional title (e.g. url "title" or url 'title')
										img_title := extract_title_from_url_string (url)
										if img_title /= Void then
												-- Remove title from url: find space followed by quote
											from
												quote_pos := 1
											until
												quote_pos > url.count
											loop
												if (url [quote_pos] = ' ' or url [quote_pos] = '%T') and then
													quote_pos < url.count and then
													(url [quote_pos + 1] = '"' or url [quote_pos + 1] = '%'')
												then
													url := trimmed (url.substring (1, quote_pos - 1)).to_string_8
													quote_pos := url.count + 1
												else
													quote_pos := quote_pos + 1
												end
											end
											create lnk.make_with_title (trimmed (url).to_string_8, img_title)
										else
											create lnk.make (trimmed (url).to_string_8)
										end
										append_inlines_to (inner, lnk)
										Result.extend (lnk)
										i := j + 1
									else
										buf.append_character ('[')
										i := i + 1
									end
								else
										-- 2) Reference-style links: [text][label], [text][], [text]
									if attached link_definitions as defs then
										-- Link text between [ and ]
									label_text := s.substring (i + 1, tmp - 1)
									handled := False

										-- 2a) Explicit / collapsed: [text][label] or [text][]
									if not handled and then tmp + 1 <= n and then s [tmp + 1] = '[' then
										label_end := s.index_of (']', tmp + 2)
										if label_end > 0 then
												-- Label inside second [] (may be empty for collapsed)
											ref_label := s.substring (tmp + 2, label_end - 1)
											if ref_label.is_empty then
													-- Collapsed: use link text as label
												ref_label := label_text
											end
											norm := normalize_reference_label (ref_label)
											if defs.has (norm) and then attached defs.item (norm) as def then
												flush_text_buffer_to (buf, Result)
												if attached def.title as link_title then
													create lnk.make_with_title (def.url, link_title)
												else
													create lnk.make (def.url)
												end
												append_inlines_to (label_text, lnk)
												Result.extend (lnk)
												i := label_end + 1
												handled := True
											end
										end
									end

										-- 2b) Shortcut: [text] with implicit label = text
									if not handled then
										norm := normalize_reference_label (label_text)
										if defs.has (norm) and then attached defs.item (norm) as def then
											flush_text_buffer_to (buf, Result)
											if attached def.title as link_title then
												create lnk.make_with_title (def.url, link_title)
											else
												create lnk.make (def.url)
											end
											append_inlines_to (label_text, lnk)
											Result.extend (lnk)
											i := tmp + 1
											handled := True
										end
									end

										if not handled then
											buf.append_character ('[')
											i := i + 1
										end
									else
										buf.append_character ('[')
										i := i + 1
									end
								end
							else
								buf.append_character ('[')
								i := i + 1
							end
						end
					else
							-- Any other character: append to buffer
						buf.append_character (s [i])
						i := i + 1
					end
				end
			end
			flush_text_buffer_to (buf, Result)
		ensure
			result_attached: Result /= Void
		end

	is_autolink_url (a_text: READABLE_STRING_8): BOOLEAN
			-- Is `a_text` a valid autolink URL (starts with http:// or https://)?
		require
			a_text_attached: a_text /= Void
		do
			Result := a_text.count >= 8 and then
				(a_text.starts_with ("http://") or
				 a_text.starts_with ("https://") or
				 a_text.starts_with ("ftp://") or
				 a_text.starts_with ("ftps://"))
		end

	is_escapable_punctuation (c: CHARACTER): BOOLEAN
			-- Is `c` an escapable punctuation character per CommonMark?
		do
				-- List from CommonMark spec: ! " # $ % & ' ( ) * + , - . / : ; < = > ? @ [ \ ] ^ _ ` { | } ~
			inspect
				c
			when
				'!' , '%"' , '#' , '$' , '%%' , '&' , '%'' ,
				'(' , ')' , '*' , '+' , ',' , '-' , '.' ,
				'/' , ':' , ';' , '<' , '=' , '>' , '?' ,
				'@' , '[' , '\' , ']' , '^' , '_' , '`' ,
				'{' , '|' , '}' , '~'
			then
				Result := True
			else
				Result := False
			end
		end

	is_autolink_email (a_text: READABLE_STRING_8): BOOLEAN
			-- Is `a_text` a valid autolink email (contains @ and valid email pattern)?
		require
			a_text_attached: a_text /= Void
		local
			has_at: BOOLEAN
			has_dot: BOOLEAN
			i, n: INTEGER
			c: CHARACTER
		do
			n := a_text.count
			if n >= 3 then
				from
					i := 1
				until
					i > n
				loop
					c := a_text [i]
					if c = '@' then
						has_at := True
					elseif c = '.' and has_at then
						has_dot := True
					elseif not (c.is_alpha_numeric or c = '.' or c = '-' or c = '_' or c = '+' or c = '@') then
						i := n + 1
					end
					i := i + 1
				end
				Result := has_at and has_dot
			end
		end

	backtick_run_length (s: READABLE_STRING_8; a_pos: INTEGER): INTEGER
			-- Length of the run of backticks starting at `a_pos`.
		require
			s_attached: s /= Void
			valid_pos: a_pos >= 1 and a_pos <= s.count
			is_backtick: s [a_pos] = '`'
		local
			i, n: INTEGER
		do
			from
				i := a_pos
				n := s.count
				Result := 0
			until
				i > n or else s [i] /= '`'
			loop
				Result := Result + 1
				i := i + 1
			end
		ensure
			positive: Result >= 1
		end

	parse_entity_at (s: READABLE_STRING_8; a_start: INTEGER): detachable TUPLE [decoded: STRING_8; next_pos: INTEGER]
			-- Parse entity reference at `a_start` in `s` (s [a_start] = '&').
			-- Returns [decoded, next_pos] if valid entity (named, &#n;, &#xHH;), Void otherwise.
			-- Decoded is the character(s) for output; next_pos is index after the entity.
		require
			s_attached: s /= Void
			valid_start: a_start >= 1 and a_start <= s.count
			is_ampersand: s [a_start] = '&'
		local
			i, n, code, next_pos: INTEGER
			c: CHARACTER
			name: READABLE_STRING_8
			decoded_str: STRING_32
		do
			n := s.count
			if a_start + 1 <= n then
				if s [a_start + 1] = '#' then
						-- Numeric: &#123; or &#x7B;
					if a_start + 2 <= n then
						if s [a_start + 2] = 'x' or s [a_start + 2] = 'X' then
								-- Hex: &#x7B; (1-6 hex digits)
							from
								i := a_start + 3
								code := 0
							until
								i > n or i > a_start + 8 or s [i] = ';'
							loop
								c := s [i]
								if c >= '0' and c <= '9' then
									code := code * 16 + (c.code - ('0').code)
									i := i + 1
								elseif c >= 'a' and c <= 'f' then
									code := code * 16 + (c.code - ('a').code + 10)
									i := i + 1
								elseif c >= 'A' and c <= 'F' then
									code := code * 16 + (c.code - ('A').code + 10)
									i := i + 1
								else
									i := n + 1
								end
							end
							if i <= n and then s [i] = ';' and then code <= 255 and then (i - (a_start + 3)) >= 1 then
								create decoded_str.make (1)
								decoded_str.append_code (code.to_natural_32)
								next_pos := i + 1
								Result := [{UTF_CONVERTER}.utf_32_string_to_utf_8_string_8 (decoded_str), next_pos]
							end
						else
								-- Decimal: &#123; (1-7 digits)
							from
								i := a_start + 2
								code := 0
							until
								i > n or i > a_start + 8 or s [i] = ';'
							loop
								c := s [i]
								if c >= '0' and c <= '9' then
									code := code * 10 + (c.code - ('0').code)
									i := i + 1
								else
									i := n + 1
								end
							end
							if i <= n and then s [i] = ';' and then code <= 255 and then (i - (a_start + 2)) >= 1 then
								create decoded_str.make (1)
								decoded_str.append_code (code.to_natural_32)
								next_pos := i + 1
								Result := [{UTF_CONVERTER}.utf_32_string_to_utf_8_string_8 (decoded_str), next_pos]
							end
						end
					end
				else
						-- Named entity: &amp; &lt; &gt; &quot; &apos; etc. (letters/digits, then ;)
					from
						i := a_start + 1
					until
						i > n or not (s [i].is_alpha or s [i].is_digit) or s [i] = ';'
					loop
						i := i + 1
					end
					if i > a_start + 1 and then i <= n and then s [i] = ';' then
						name := s.substring (a_start + 1, i - 1)
						if attached named_entity_to_character (name) as ch then
							create decoded_str.make (1)
							decoded_str.append_character (ch)
							next_pos := i + 1
							Result := [{UTF_CONVERTER}.utf_32_string_to_utf_8_string_8 (decoded_str), next_pos]
						end
					end
				end
			end
		end

	named_entity_to_character (a_name: READABLE_STRING_8): detachable CHARACTER_8
			-- Character for HTML named entity `a_name` (e.g. "amp" -> '&'); Void if unknown.
		require
			a_name_attached: a_name /= Void
		do
			if a_name.is_equal ("amp") then
				Result := '&'
			elseif a_name.is_equal ("lt") then
				Result := '<'
			elseif a_name.is_equal ("gt") then
				Result := '>'
			elseif a_name.is_equal ("quot") then
				Result := '%"'
			elseif a_name.is_equal ("apos") then
				Result := '%''
			elseif a_name.is_equal ("nbsp") then
				Result := '%/160/'
			elseif a_name.is_equal ("copy") then
				Result := '%/169/'
			elseif a_name.is_equal ("reg") then
				Result := '%/174/'
			end
		end

	is_word_boundary_at (s: STRING_8; pos: INTEGER): BOOLEAN
			-- Is there a word boundary at position `pos` in `s`?
			-- Word boundary: start/end of string, or transition between word and non-word character.
			-- For underscore emphasis, we need a word boundary before and after.
		require
			s_attached: s /= Void
			valid_pos: pos >= 1 and pos <= s.count + 1
		local
			prev_is_word, curr_is_word: BOOLEAN
		do
			if pos = 1 or pos > s.count then
				Result := True
			else
					-- For GFM underscore emphasis, underscore is NOT a word character
				prev_is_word := s [pos - 1].is_alpha_numeric
				curr_is_word := s [pos].is_alpha_numeric
				Result := not prev_is_word or not curr_is_word
			end
		end

	extract_title_from_url_string (a_url_string: READABLE_STRING_8): detachable STRING_8
			-- Extract title from URL string if present (e.g., `url "title"` or `url 'title'`).
			-- Returns Void if no title found.
			-- Format: URL followed by space and quoted title.
		require
			a_url_string_attached: a_url_string /= Void
		local
			s: STRING_8
			i, j, n, quote_start: INTEGER
			quote_char: CHARACTER
			found_space: BOOLEAN
		do
			create s.make_from_string (a_url_string)
			n := s.count
			from
				i := 1
			until
				i > n or quote_start > 0
			loop
				if s [i] = ' ' or s [i] = '%T' then
						-- Found space/tab: mark that we've seen space
					found_space := True
					i := i + 1
				elseif found_space and then i <= n and then (s [i] = '"' or s [i] = '%'') then
						-- Found quote after space: extract title
					quote_char := s [i]
					quote_start := i + 1
					from
						j := i + 1
					until
						j > n
					loop
						if s [j] = quote_char then
							if j > quote_start then
								Result := s.substring (quote_start, j - 1)
							end
							j := n + 1
						else
							j := j + 1
						end
					end
					i := n + 1
				else
						-- Non-space, non-quote (or quote without preceding space): part of URL
					i := i + 1
				end
			end
		end

	normalized_code_span_content (a_content: READABLE_STRING_8): STRING_8
			-- Normalized code span content.
			-- If it begins and ends with a space and contains at least one non-space character,
			-- remove exactly one leading and one trailing space.
		require
			a_content_attached: a_content /= Void
		local
			s: STRING_8
			i, n: INTEGER
			has_non_space: BOOLEAN
		do
			create s.make_from_string (a_content)
			n := s.count
			if n >= 2 and then s [1] = ' ' and then s [n] = ' ' then
				from
					i := 1
				until
					i > n or has_non_space
				loop
					if s [i] /= ' ' then
						has_non_space := True
					end
					i := i + 1
				end
				if has_non_space then
					Result := s.substring (2, n - 1)
				else
					Result := s
				end
			else
				Result := s
			end
		ensure
			result_attached: Result /= Void
		end

	flush_text_buffer_to (a_buf: STRING_8; a_out: ARRAYED_LIST [MD_INLINE])
			-- Flush accumulated plain text `a_buf` into `a_out`.
		require
			a_buf_attached: a_buf /= Void
			a_out_attached: a_out /= Void
		do
			if not a_buf.is_empty then
				a_out.extend (create {MD_TEXT}.make (a_buf))
				a_buf.wipe_out
			end
		ensure
			buffer_cleared: a_buf.is_empty
		end

end

