note
	description: "[
		Scanner of Markdown text, for syntax highlighting.
		Each line is scanned on its own; fenced code blocks (``` or ~~~) are handled as verbatim strings
		covering several lines (see `in_verbatim_string').
		Tokens: headings and strong emphasis as keywords, emphasis as characters, code (spans, fenced and
		indented blocks) as strings, links and images as numbers, block quotes, HTML and strikethrough as
		comments, markers (lists, tables, rules) as operators, highlighted text (`==text==') as text on a
		yellow background.
	]"
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date$"
	revision: "$Revision$"

class
	EDITOR_MARKDOWN_SCANNER

inherit
	EDITOR_SCANNER
		redefine
			execute
		end

create
	make

feature -- Access

	start_condition: INTEGER
			-- <Precursor>

feature -- Status setting

	set_start_condition (a_condition: INTEGER)
			-- <Precursor>
		do
			start_condition := a_condition
		end

feature -- Basic operations

	execute (a_string: STRING)
			-- <Precursor>
		local
			u: UTF_CONVERTER
		do
			end_of_verbatim_string := False
			start_of_verbatim_string := False
			if in_verbatim_string then
				set_start_condition (verbatim_st)
			else
				set_start_condition (initial_st)
			end
			end_token := Void
			first_token := Void
			scan_line (u.utf_8_string_8_to_string_32 (a_string))
		end

	scan
			-- <Precursor>
		do
				-- The lines are scanned by `execute'.
		end

feature {NONE} -- Line scanning

	scan_line (s: STRING_32)
			-- Produce the tokens of line `s'.
		local
			i, n, l_indent: INTEGER
			l_rest: STRING_32
		do
			n := s.count
			from
				i := 1
			until
				i > n or else not (s [i] = ' ' or s [i] = '%T')
			loop
				if s [i] = '%T' then
					l_indent := l_indent + 4
				else
					l_indent := l_indent + 1
				end
				i := i + 1
			end
			l_rest := s.substring (i, n)
			if start_condition = verbatim_st then
					-- Inside a fenced code block.
				append_text (s, Kind_code)
				if is_fence (l_rest) then
					end_of_verbatim_string := True
					in_verbatim_string := False
					set_start_condition (initial_st)
				end
			elseif l_rest.is_empty then
				append_text (s, Kind_text)
			elseif is_fence (l_rest) then
				append_text (s, Kind_code)
				start_of_verbatim_string := True
				in_verbatim_string := True
				set_start_condition (verbatim_st)
			elseif l_indent >= 4 then
					-- Indented code block (or continuation of a list item).
				append_text (s, Kind_code)
			elseif is_heading (l_rest) then
				append_text (s, Kind_strong)
			elseif is_rule (l_rest) or is_table_of_contents_marker (l_rest) then
				append_text (s, Kind_marker)
			elseif l_rest [1] = '>' then
				append_text (s, Kind_comment)
			elseif l_rest.starts_with ({STRING_32} "<!--") or else (l_rest [1] = '<' and then l_rest.count > 1 and then (l_rest [2].is_alpha or l_rest [2] = '/')) then
				append_text (s, Kind_comment)
			else
				append_text (s.substring (1, i - 1), Kind_text)
				scan_block (l_rest)
			end
		end

	scan_block (s: STRING_32)
			-- Produce the tokens of `s', the text of a line after its indentation (list item, table row or paragraph).
		require
			not_empty: not s.is_empty
		local
			i, n: INTEGER
		do
			n := s.count
			i := list_marker_end (s)
			if i > 0 then
				append_text (s.substring (1, i), Kind_marker)
				i := i + 1
					-- Task box.
				if
					i + 2 <= n and then s [i] = '[' and then s [i + 2] = ']' and then
					(s [i + 1] = ' ' or s [i + 1] = 'x' or s [i + 1] = 'X')
				then
					append_text (s.substring (i, i + 2), Kind_marker)
					i := i + 3
				end
				scan_inline (s, i, False)
			else
				scan_inline (s, 1, s [1] = '|')
			end
		end

	scan_inline (s: STRING_32; a_start: INTEGER; a_is_table: BOOLEAN)
			-- Produce the tokens of the inline text of `s' from `a_start', with `|' as separator if `a_is_table'.
		local
			i, j, n, l_start: INTEGER
			c: CHARACTER_32
			l_escaped: BOOLEAN
		do
			n := s.count
			from
				i := a_start
				l_start := i
			until
				i > n
			loop
				c := s [i]
				j := 0
				l_escaped := False
				if c = '\' and then i < n then
						-- Escaped character: not a delimiter.
					i := i + 2
					l_escaped := True
				elseif c = '`' then
					j := code_span_end (s, i)
					if j > 0 then
						append_text (s.substring (l_start, i - 1), Kind_text)
						append_text (s.substring (i, j), Kind_code)
					end
				elseif c = '*' or else (c = '_' and then (i = 1 or else not s [i - 1].is_alpha_numeric)) then
					j := emphasis_end (s, i)
					if j > 0 then
						append_text (s.substring (l_start, i - 1), Kind_text)
						if i < n and then s [i + 1] = c then
							append_text (s.substring (i, j), Kind_strong)
						else
							append_text (s.substring (i, j), Kind_emphasis)
						end
					end
				elseif c = '~' and then i < n and then s [i + 1] = '~' then
					j := s.substring_index ({STRING_32} "~~", i + 2)
					if j > 0 then
						j := j + 1
						append_text (s.substring (l_start, i - 1), Kind_text)
						append_text (s.substring (i, j), Kind_comment)
					end
				elseif c = '=' then
					j := highlight_end (s, i)
					if j > 0 then
						append_text (s.substring (l_start, i - 1), Kind_text)
						append_text (s.substring (i, j), Kind_highlight)
					end
				elseif c = '[' or else (c = '!' and then i < n and then s [i + 1] = '[') then
					j := link_end (s, i)
					if j > 0 then
						append_text (s.substring (l_start, i - 1), Kind_text)
						append_text (s.substring (i, j), Kind_link)
					end
				elseif c = '<' then
					j := s.index_of ('>', i + 1)
					if j > 0 then
						append_text (s.substring (l_start, i - 1), Kind_text)
						if s.substring (i + 1, j - 1).has_substring ({STRING_32} "://") or else s.substring (i + 1, j - 1).has ('@') then
							append_text (s.substring (i, j), Kind_link)
						else
							append_text (s.substring (i, j), Kind_comment)
						end
					end
				elseif c = '|' and a_is_table then
					j := i
					append_text (s.substring (l_start, i - 1), Kind_text)
					append_text (s.substring (i, i), Kind_marker)
				end
				if j > 0 then
					i := j + 1
					l_start := i
				elseif not l_escaped then
					i := i + 1
				end
			end
			append_text (s.substring (l_start, n), Kind_text)
		end

feature {NONE} -- Line analysis

	is_fence (s: STRING_32): BOOLEAN
			-- Does `s' start a code fence?
		do
			Result := s.starts_with ({STRING_32} "```") or else s.starts_with ({STRING_32} "~~~")
		end

	is_heading (s: STRING_32): BOOLEAN
			-- Is `s' an ATX heading (1 to 6 `#' followed by a space or nothing)?
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > s.count or else s [i] /= '#'
			loop
				i := i + 1
			end
			Result := i > 1 and then i <= 7 and then (i > s.count or else s [i] = ' ' or else s [i] = '%T')
		end

	is_rule (s: STRING_32): BOOLEAN
			-- Is `s' a thematic break or a setext heading underline (at least three `-', `*', `_' or `=')?
		local
			i, l_count: INTEGER
			c: CHARACTER_32
		do
			c := s [1]
			if c = '-' or c = '*' or c = '_' or c = '=' then
				Result := True
				from
					i := 1
				until
					i > s.count or not Result
				loop
					if s [i] = c then
						l_count := l_count + 1
					elseif s [i] /= ' ' and s [i] /= '%T' then
						Result := False
					end
					i := i + 1
				end
				Result := Result and l_count >= 3
			end
		end

	list_marker_end (s: STRING_32): INTEGER
			-- Index of the end of the list marker (and its space) starting `s', or 0 if none.
		local
			i: INTEGER
		do
			if s.count >= 2 and then (s [1] = '-' or s [1] = '*' or s [1] = '+') and then s [2] = ' ' then
				Result := 2
			else
				from
					i := 1
				until
					i > s.count or else not s [i].is_digit
				loop
					i := i + 1
				end
				if
					i > 1 and then i <= 10 and then i < s.count and then
					(s [i] = '.' or s [i] = ')') and then s [i + 1] = ' '
				then
					Result := i + 1
				end
			end
		end

	code_span_end (s: STRING_32; i: INTEGER): INTEGER
			-- Index of the end of the code span starting at `i' in `s' (with as many backticks), or 0 if none.
		local
			l_count, j, k: INTEGER
		do
			from
				j := i
			until
				j > s.count or else s [j] /= '`'
			loop
				j := j + 1
			end
			l_count := j - i
			from
			until
				Result > 0 or else j > s.count
			loop
				if s [j] = '`' then
					from
						k := j
					until
						k > s.count or else s [k] /= '`'
					loop
						k := k + 1
					end
					if k - j = l_count then
						Result := k - 1
					end
					j := k
				else
					j := j + 1
				end
			end
		end

	emphasis_end (s: STRING_32; i: INTEGER): INTEGER
			-- Index of the end of the emphasis starting at `i' in `s' (closed by the same delimiters), or 0 if none.
		local
			l_delimiter: STRING_32
			c: CHARACTER_32
			j: INTEGER
		do
			c := s [i]
			from
				j := i
			until
				j > s.count or else j - i = 3 or else s [j] /= c
			loop
				j := j + 1
			end
			l_delimiter := s.substring (i, j - 1)
				-- The emphasized text cannot start with a space.
			if j <= s.count and then s [j] /= ' ' then
				Result := s.substring_index (l_delimiter, j + 1)
				if Result > 0 and then s [Result - 1] /= ' ' then
					Result := Result + l_delimiter.count - 1
				else
					Result := 0
				end
			end
		end

	link_end (s: STRING_32; i: INTEGER): INTEGER
			-- Index of the end of the link (or image) starting at `i' in `s', or 0 if none.
		local
			j, k: INTEGER
		do
			j := s.index_of (']', i + 1)
			if j > 0 then
				if j < s.count and then s [j + 1] = '(' then
					k := s.index_of (')', j + 2)
					if k > 0 then
						Result := k
					end
				elseif j < s.count and then s [j + 1] = '[' then
					k := s.index_of (']', j + 2)
					if k > 0 then
						Result := k
					end
				elseif j < s.count and then s [j + 1] = ':' then
						-- Link reference definition.
					Result := s.count
				else
					Result := j
				end
			end
		end

feature {NONE} -- Tokens

	append_text (s: READABLE_STRING_32; a_kind: INTEGER)
			-- Append the tokens of `s' (words, spaces and tabulations), words of kind `a_kind'.
		local
			i, j, n: INTEGER
			c: CHARACTER_32
			l_token: EDITOR_TOKEN
		do
			n := s.count
			from
				i := 1
			until
				i > n
			loop
				c := s [i]
				from
					j := i + 1
				until
					j > n or else not same_class (s [j], c)
				loop
					j := j + 1
				end
				if c = ' ' then
					l_token := create {EDITOR_TOKEN_SPACE}.make (j - i)
				elseif c = '%T' then
					l_token := create {EDITOR_TOKEN_TABULATION}.make (j - i)
				else
					l_token := new_token (s.substring (i, j - 1), a_kind)
				end
				if a_kind = Kind_highlight then
						-- (The spaces too, for a continuous background.)
					l_token.set_background_color (highlight_background_color (l_token.background_color))
				end
				curr_token := l_token
				update_token_list
				i := j
			end
		end

	is_table_of_contents_marker (s: READABLE_STRING_32): BOOLEAN
			-- Is `s' (a line without its indentation) a table of contents marker: `[TOC]' (any letter case)
			-- or `[[_TOC_]]', as for the table of contents extension of the markdown library?
		local
			l_text: STRING_32
		do
			create l_text.make_from_string (s)
			l_text.to_lower
			l_text.right_adjust
			Result := l_text.same_string_general ("[toc]") or l_text.same_string_general ("[[_toc_]]")
		end

	highlight_end (s: READABLE_STRING_32; i: INTEGER): INTEGER
			-- Index of the end of the highlighted text `==text==' starting at `i' in `s', or 0 if none
			-- (as the highlight extension of the markdown library: no space after the opening `==' nor
			-- before the closing one, and neither next to another `=').
		local
			n: INTEGER
		do
			n := s.count
			if
				i + 2 <= n and then s [i] = '=' and then s [i + 1] = '=' and then s [i + 2] /= '=' and then
				not s [i + 2].is_space and then (i = 1 or else s [i - 1] /= '=')
			then
				from
					Result := s.substring_index ({STRING_32} "==", i + 3)
				until
					Result = 0 or else (not s [Result - 1].is_space and then s [Result - 1] /= '=' and then (Result + 2 > n or else s [Result + 2] /= '='))
				loop
					Result := s.substring_index ({STRING_32} "==", Result + 1)
				end
				if Result > 0 then
					Result := Result + 1
				end
			end
		end

	highlight_background_color (a_background: EV_COLOR): EV_COLOR
			-- Background color of highlighted text, over the background `a_background': a dark yellow
			-- on a dark background, a light yellow otherwise.
		do
			if 299 * a_background.red_8_bit + 587 * a_background.green_8_bit + 114 * a_background.blue_8_bit < 128000 then
				Result := Dark_highlight_color
			else
				Result := Light_highlight_color
			end
		end

	Light_highlight_color: EV_COLOR
			-- Background of highlighted text on a light background.
		once
			create Result.make_with_8_bit_rgb (255, 242, 168)
		end

	Dark_highlight_color: EV_COLOR
			-- Background of highlighted text on a dark background.
		once
			create Result.make_with_8_bit_rgb (107, 91, 0)
		end

	same_class (a, b: CHARACTER_32): BOOLEAN
			-- Do `a' and `b' belong to the same token (both spaces, both tabulations or both neither)?
		do
			if a = ' ' or b = ' ' then
				Result := a = b
			elseif a = '%T' or b = '%T' then
				Result := a = b
			else
				Result := True
			end
		end

	new_token (s: STRING_32; a_kind: INTEGER): EDITOR_TOKEN
			-- New token for word `s' of kind `a_kind'.
		require
			not_empty: not s.is_empty
		do
			inspect
				a_kind
			when Kind_strong then
				create {EDITOR_TOKEN_KEYWORD} Result.make (s)
			when Kind_emphasis then
				create {EDITOR_TOKEN_CHARACTER} Result.make (s)
			when Kind_code then
				create {EDITOR_TOKEN_STRING} Result.make (s)
			when Kind_link then
				create {EDITOR_TOKEN_NUMBER} Result.make (s)
			when Kind_comment then
				create {EDITOR_TOKEN_COMMENT} Result.make (s)
			when Kind_marker then
				create {EDITOR_TOKEN_OPERATOR} Result.make (s)
			else
				create {EDITOR_TOKEN_TEXT} Result.make (s)
			end
		end

feature {NONE} -- Constants

	Kind_text: INTEGER = 0
	Kind_strong: INTEGER = 1
	Kind_emphasis: INTEGER = 2
	Kind_code: INTEGER = 3
	Kind_link: INTEGER = 4
	Kind_comment: INTEGER = 5
	Kind_marker: INTEGER = 6
	Kind_highlight: INTEGER = 7
			-- Kinds of text.

note
	copyright:	"Copyright (c) 1984-2026, Eiffel Software and others"
	license:	"Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"

end
