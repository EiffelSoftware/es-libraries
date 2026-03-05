note
	description: "Parser for YAML 1.2.2 content."

class
	YAML_PARSER

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize parser.
		do
			create anchors.make (10)
		ensure
			no_errors: not has_error
		end

feature -- Access

	parsed_document: detachable YAML_DOCUMENT
			-- Last parsed document.

	errors: detachable ARRAYED_LIST [STRING_32]
			-- Parse errors encountered.

feature -- Status report

	has_error: BOOLEAN
			-- Were there any parse errors?
		do
			Result := attached errors as lst and then not lst.is_empty
		end

feature -- Parsing

	parse_string (a_yaml: READABLE_STRING_GENERAL): detachable YAML_VALUE
			-- Parse YAML string `a_yaml` and return root value.
		require
			yaml_attached: a_yaml /= Void
		do
			reset
			content := a_yaml.to_string_32
			position := 1
			line := 1
			column := 1
			Result := parse_value (0)
			if Result /= Void then
				create parsed_document.make (Result)
			end
		end

	parse_document (a_yaml: READABLE_STRING_GENERAL): detachable YAML_DOCUMENT
			-- Parse YAML string `a_yaml` and return document.
		require
			yaml_attached: a_yaml /= Void
		do
			reset
			content := a_yaml.to_string_32
			position := 1
			line := 1
			column := 1
			Result := parse_yaml_document
		end

feature {NONE} -- Implementation

	content: detachable STRING_32
			-- Content being parsed.

	position: INTEGER
			-- Current position in content.

	line: INTEGER
			-- Current line number.

	column: INTEGER
			-- Current column number.

	anchors: HASH_TABLE [YAML_VALUE, STRING_32]
			-- Anchors defined in document.

	reset
			-- Reset parser state.
		do
			errors := Void
			anchors.wipe_out
			parsed_document := Void
		end

	parse_yaml_document: detachable YAML_DOCUMENT
			-- Parse a YAML document.
		local
			root_value: detachable YAML_VALUE
		do
			skip_blanks_and_comments
				-- Handle optional directives
			if looking_at ("%%YAML") then
				skip_yaml_directive
			end
			across 1 |..| 10 as i until not looking_at ("%%TAG") loop
				skip_tag_directive
			end
				-- Handle document start marker
			if looking_at ("---") then
				advance (3)
				skip_blanks_and_comments
			end
			root_value := parse_value (0)
			if root_value /= Void then
				create Result.make (root_value)
			end
				-- Handle document end marker
			skip_blanks_and_comments
			if looking_at ("...") then
				advance (3)
			end
		end

	parse_value (a_indent: INTEGER): detachable YAML_VALUE
			-- Parse a YAML value at indentation level `a_indent`.
		local
			c: CHARACTER_32
		do
			skip_blanks_and_comments
			if not at_end then
				c := current_char
				if c = '-' and then peek_char (1) = ' ' then
						-- Block sequence
					Result := parse_block_sequence (a_indent)
				elseif c = '[' then
						-- Flow sequence
					Result := parse_flow_sequence
				elseif c = '{' then
						-- Flow mapping
					Result := parse_flow_mapping
				elseif c = '|' then
						-- Literal scalar
					Result := parse_literal_scalar (a_indent)
				elseif c = '>' then
						-- Folded scalar
					Result := parse_folded_scalar (a_indent)
				elseif c = '%'' then
						-- Single-quoted scalar
					Result := parse_single_quoted_scalar
				elseif c = '"' then
						-- Double-quoted scalar
					Result := parse_double_quoted_scalar
				elseif c = '*' then
						-- Alias
					Result := parse_alias
				elseif c = '&' then
						-- Anchor
					Result := parse_anchor_and_value (a_indent)
				elseif c = '!' then
						-- Tag
					Result := parse_tag_and_value (a_indent)
				else
						-- Check if this starts a mapping or plain scalar
					Result := parse_plain_or_mapping (a_indent)
				end
			end
		end

	parse_block_sequence (a_indent: INTEGER): YAML_SEQUENCE
			-- Parse a block sequence starting at current position.
		local
			item_value: detachable YAML_VALUE
			item_indent: INTEGER
			done: BOOLEAN
		do
			create Result.make
			from
				done := False
			until
				done or at_end
			loop
				skip_blanks_and_comments
				if at_end then
					done := True
				else
					item_indent := current_indent
					if item_indent < a_indent then
						done := True
					elseif current_char = '-' and then peek_char (1) = ' ' then
						advance (2) -- Skip "- "
						item_value := parse_value (item_indent + 1)
						if item_value /= Void then
							Result.extend (item_value)
						else
							Result.extend (create {YAML_NULL})
						end
					else
						done := True
					end
				end
			end
		end

	parse_flow_sequence: YAML_SEQUENCE
			-- Parse a flow sequence [item1, item2, ...].
		local
			item_value: detachable YAML_VALUE
		do
			create Result.make
			Result.set_flow_style (True)
			advance (1) -- Skip '['
			skip_blanks_and_comments
			from
			until
				at_end or else current_char = ']'
			loop
				item_value := parse_value (0)
				if item_value /= Void then
					Result.extend (item_value)
				end
				skip_blanks_and_comments
				if not at_end and then current_char = ',' then
					advance (1)
					skip_blanks_and_comments
				end
			end
			if not at_end and then current_char = ']' then
				advance (1)
			else
				add_error ("Expected ']' to close flow sequence")
			end
		end

	parse_flow_mapping: YAML_MAPPING
			-- Parse a flow mapping {key1: value1, key2: value2, ...}.
		local
			key_value: YAML_STRING
			value_value: detachable YAML_VALUE
		do
			create Result.make
			Result.set_flow_style (True)
			advance (1) -- Skip '{'
			skip_blanks_and_comments
			from
			until
				at_end or else current_char = '}'
			loop
				key_value := parse_flow_key
				skip_blanks_and_comments
				if not at_end and then current_char = ':' then
					advance (1)
					skip_blanks_and_comments
					value_value := parse_value (0)
					if key_value /= Void then
						if value_value /= Void then
							Result.put (value_value, key_value)
						else
							Result.put (create {YAML_NULL}, key_value)
						end
					end
				end
				skip_blanks_and_comments
				if not at_end and then current_char = ',' then
					advance (1)
					skip_blanks_and_comments
				end
			end
			if not at_end and then current_char = '}' then
				advance (1)
			else
				add_error ("Expected '}' to close flow mapping")
			end
		end

	parse_flow_key: detachable YAML_STRING
			-- Parse a key in flow context.
		local
			c: CHARACTER_32
		do
			skip_blanks_and_comments
			if not at_end then
				c := current_char
				if c = '%'' then
					Result := parse_single_quoted_scalar
				elseif c = '"' then
					Result := parse_double_quoted_scalar
				else
					Result := {YAML_STRING} / parse_plain_scalar_flow
				end
			end
		end

	parse_literal_scalar (a_indent: INTEGER): YAML_STRING
			-- Parse a literal scalar |.
		local
			text: STRING_32
			chomping: INTEGER -- 0=clip, 1=strip, 2=keep
			explicit_indent: INTEGER
			l_current_indent: INTEGER
			content_indent: INTEGER
			first_content_line: BOOLEAN
			done: BOOLEAN
		do
			advance (1) -- Skip '|'
			chomping := 0
			explicit_indent := 0
			if not at_end then
				if current_char = '-' then
					chomping := 1
					advance (1)
				elseif current_char = '+' then
					chomping := 2
					advance (1)
				end
				if not at_end and then current_char.is_digit then
					explicit_indent := current_char.code - ('0').code
					advance (1)
				end
			end
			skip_to_end_of_line
			advance_line
			create text.make (100)
			content_indent := 0
			first_content_line := True
			from
				done := False
			until
				done or at_end
			loop
				if is_blank_line then
					text.append_character ('%N')
					advance_line
				else
					l_current_indent := current_indent
					if first_content_line then
						content_indent := l_current_indent
						if explicit_indent > 0 then
							content_indent := a_indent + explicit_indent
						end
						first_content_line := False
					end
					if l_current_indent >= content_indent then
						-- Add spaces for extra indentation
--						text.append (create {STRING_8}.make_filled (' ', l_current_indent - content_indent))
						advance (content_indent)
						text.append (read_rest_of_line)
						text.append_character ('%N')
						advance_line
					else
						-- End of literal block
						if chomping = 1 then
							text.right_adjust
						elseif chomping = 0 then
							-- Clip: keep single trailing newline
							text.right_adjust
							text.append_character ('%N')
						end
						-- chomping = 2: keep all trailing newlines
						create Result.make_literal (text)
						done := True
					end
				end
			end
			if Result = Void then
				if chomping = 1 then
					text.right_adjust
				elseif chomping = 0 then
					text.right_adjust
					if not text.is_empty then
						text.append_character ('%N')
					end
				end
				create Result.make_plain (text)
				Result.set_style ({YAML_SCALAR}.Style_literal)
			end
		end

	parse_folded_scalar (a_indent: INTEGER): YAML_STRING
			-- Parse a folded scalar >.
		local
			text: STRING_32
			chomping: INTEGER
			explicit_indent: INTEGER
			content_indent: INTEGER
			first_content_line: BOOLEAN
			line_text: STRING_32
			prev_blank: BOOLEAN
			done: BOOLEAN
		do
			advance (1) -- Skip '>'
			chomping := 0
			explicit_indent := 0
			if not at_end then
				if current_char = '-' then
					chomping := 1
					advance (1)
				elseif current_char = '+' then
					chomping := 2
					advance (1)
				end
				if not at_end and then current_char.is_digit then
					explicit_indent := current_char.code - ('0').code
					advance (1)
				end
			end
			skip_to_end_of_line
			advance_line
			create text.make (100)
			content_indent := 0
			first_content_line := True
			prev_blank := False
			from
				done := False
			until
				done or at_end
			loop
				if is_blank_line then
					text.append_character ('%N')
					prev_blank := True
					advance_line
				else
					if first_content_line then
						content_indent := current_indent
						if explicit_indent > 0 then
							content_indent := a_indent + explicit_indent
						end
						first_content_line := False
					end
					if current_indent >= content_indent then
						if current_indent > content_indent then
							-- More indented line: preserve newline
							if not text.is_empty and then text [text.count] /= '%N' then
								text.append_character ('%N')
							end
							across 1 |..| (current_indent - content_indent) as i loop
								text.append_character (' ')
							end
							text.append (read_rest_of_line)
							text.append_character ('%N')
						else
							-- Normal line: fold to space
							if not text.is_empty and not prev_blank then
								if text [text.count] /= '%N' then
									text.append_character (' ')
								end
							end
							line_text := read_rest_of_line
							line_text.left_adjust
							text.append (line_text)
						end
						prev_blank := False
						advance_line
					else
						-- End of folded block
						if chomping = 1 then
							text.right_adjust
						elseif chomping = 0 then
							text.right_adjust
							text.append_character ('%N')
						end
						create Result.make_folded (text)
						done := True
					end
				end
			end
			if Result = Void then
				if chomping = 1 then
					text.right_adjust
				elseif chomping = 0 then
					text.right_adjust
					if not text.is_empty then
						text.append_character ('%N')
					end
				end
				create Result.make_plain (text)
				Result.set_style ({YAML_SCALAR}.Style_folded)
			end
		end

	parse_single_quoted_scalar: YAML_STRING
			-- Parse a single-quoted scalar 'text'.
		local
			text: STRING_32
			c: CHARACTER_32
			done: BOOLEAN
		do
			advance (1) -- Skip opening quote
			create text.make (50)
			from
				done := False
			until
				done or at_end
			loop
				c := current_char
				if c = '%'' then
					if peek_char (1) = '%'' then
						-- Escaped single quote
						text.append_character ('%'')
						advance (2)
					else
						-- End of string
						advance (1)
						create Result.make_single_quoted (text)
						done := True
					end
				else
					text.append_character (c)
					advance (1)
				end
			end
			if Result = Void then
				add_error ("Unterminated single-quoted string")
				create Result.make_single_quoted (text)
			end
		end

	parse_double_quoted_scalar: YAML_STRING
			-- Parse a double-quoted scalar "text".
		local
			text: STRING_32
			c: CHARACTER_32
			done: BOOLEAN
		do
			advance (1) -- Skip opening quote
			create text.make (50)
			from
				done := False
			until
				done or at_end
			loop
				c := current_char
				if c = '"' then
					advance (1)
					create Result.make_double_quoted (text)
					done := True
				elseif c = '\' then
					text.append_character (parse_escape_sequence)
				else
					text.append_character (c)
					advance (1)
				end
			end
			if Result = Void then
				add_error ("Unterminated double-quoted string")
				create Result.make_double_quoted (text)
			end
		end

	parse_escape_sequence: CHARACTER_32
			-- Parse an escape sequence and return the character.
		local
			c: CHARACTER_32
			hex_str: STRING_32
		do
			advance (1) -- Skip backslash
			if not at_end then
				c := current_char
				advance (1)
				inspect c
				when 'n' then
					Result := '%N'
				when 'r' then
					Result := '%R'
				when 't' then
					Result := '%T'
				when '\' then
					Result := '\'
				when '"' then
					Result := '"'
				when '/' then
					Result := '/'
				when 'b' then
					Result := '%B'
				when 'f' then
					Result := '%F'
				when '0' then
					Result := '%U'
				when 'x' then
					-- \xXX hex escape
					create hex_str.make (2)
					if not at_end then
						hex_str.append_character (current_char)
						advance (1)
					end
					if not at_end then
						hex_str.append_character (current_char)
						advance (1)
					end
					Result := hex_to_char (hex_str)
				when 'u' then
					-- \uXXXX unicode escape
					create hex_str.make (4)
					across 1 |..| 4 as i loop
						if not at_end then
							hex_str.append_character (current_char)
							advance (1)
						end
					end
					Result := hex_to_char (hex_str)
				else
					Result := c
				end
			else
				Result := '\'
			end
		end

	parse_alias: detachable YAML_VALUE
			-- Parse an alias *name.
		local
			alias_name: STRING_32
		do
			advance (1) -- Skip '*'
			alias_name := read_identifier
			if anchors.has (alias_name) then
				Result := anchors [alias_name]
			else
				add_error ({STRING_32} "Unknown alias: " + alias_name)
			end
		end

	parse_anchor_and_value (a_indent: INTEGER): detachable YAML_VALUE
			-- Parse &anchor and following value.
		local
			anchor_name: STRING_32
		do
			advance (1) -- Skip '&'
			anchor_name := read_identifier
			skip_blanks
			Result := parse_value (a_indent)
			if Result /= Void then
				Result.set_anchor (anchor_name)
				anchors.put (Result, anchor_name)
			end
		end

	parse_tag_and_value (a_indent: INTEGER): detachable YAML_VALUE
			-- Parse !tag and following value.
		local
			tag_name: STRING_32
		do
			tag_name := read_tag
			skip_blanks
			Result := parse_value (a_indent)
			if Result /= Void then
				Result.set_tag (tag_name)
			end
		end

	parse_plain_or_mapping (a_indent: INTEGER): detachable YAML_VALUE
			-- Parse plain scalar or mapping.
		local
			scalar_text: STRING_32
			key_scalar: YAML_STRING
			value_value: detachable YAML_VALUE
			mapping: YAML_MAPPING
			done: BOOLEAN
			current_key_indent: INTEGER
			value_indent: INTEGER
			first_key_indent: INTEGER
		do
			-- Use actual column position (0-indexed) as indent, not line's leading spaces
			first_key_indent := column - 1
			scalar_text := read_plain_scalar
			skip_blanks
			if not at_end and then current_char = ':' and then (peek_char (1) = ' ' or peek_char (1) = '%T' or peek_char (1) = '%N' or peek_char (1) = '%R' or at_position (position + 1)) then
				-- This is a mapping key
				advance (1) -- Skip ':'
				skip_blanks
				create mapping.make
				create key_scalar.make_plain (scalar_text)
				if at_end or else current_char = '%N' or else current_char = '%R' then
					-- Value on next line - use actual indent of next content
					skip_blanks_and_comments
					value_indent := current_indent
					value_value := parse_value (value_indent)
				else
					value_value := parse_value (a_indent)
				end
				if value_value /= Void then
					mapping.put (value_value, key_scalar)
				else
					mapping.put (create {YAML_NULL}, key_scalar)
				end
				-- Continue reading more key-value pairs at same indent as first key
				from
					done := False
				until
					done or at_end
				loop
					skip_blanks_and_comments
					if at_end then
						done := True
					else
						-- Use column position for accurate indent comparison
						current_key_indent := column - 1
						if current_key_indent < first_key_indent then
							-- Dedented: end of this mapping
							done := True
						elseif current_key_indent = first_key_indent then
							-- Same indent as first key: another key-value pair
							scalar_text := read_plain_scalar
							skip_blanks
							if not at_end and then current_char = ':' and then (peek_char (1) = ' ' or peek_char (1) = '%T' or peek_char (1) = '%N' or peek_char (1) = '%R' or at_position (position + 1)) then
								advance (1)
								skip_blanks
								create key_scalar.make_plain (scalar_text)
								if at_end or else current_char = '%N' or else current_char = '%R' then
									-- Value on next line - use actual indent of next content
									skip_blanks_and_comments
									value_indent := current_indent
									value_value := parse_value (value_indent)
								else
									value_value := parse_value (current_key_indent)
								end
								if value_value /= Void then
									mapping.put (value_value, key_scalar)
								else
									mapping.put (create {YAML_NULL}, key_scalar)
								end
							else
								-- Not a key: end of mapping
								done := True
							end
						else
							-- More indented: shouldn't happen at mapping level, end mapping
							done := True
						end
					end
				end
				Result := mapping
			else
				-- Plain scalar
				Result := resolve_scalar (scalar_text, False)
			end
		end

	parse_plain_scalar_flow: YAML_SCALAR
			-- Parse a plain scalar in flow context for a key.
		local
			text: STRING_32
			c: CHARACTER_32
			done: BOOLEAN
		do
			create text.make (50)
			from
				done := False
			until
				done or at_end
			loop
				c := current_char
				if c = ':' or c = ',' or c = ']' or c = '}' or c = '%N' or c = '%R' then
					-- End of plain scalar in flow context
					text.right_adjust
					Result := resolve_scalar (text, True)
					done := True
				else
					text.append_character (c)
					advance (1)
				end
			end
			if Result = Void then
				text.right_adjust
				Result := resolve_scalar (text, True)
			end
		end

	read_plain_scalar: STRING_32
			-- Read a plain scalar value.
		local
			c: CHARACTER_32
			done: BOOLEAN
		do
			create Result.make (50)
			from
				done := False
			until
				done or at_end
			loop
				c := current_char
				if c = ':' and then (peek_char (1) = ' ' or peek_char (1) = '%T' or peek_char (1) = '%N' or peek_char (1) = '%R' or at_position (position + 1)) then
					done := True
				elseif c = '%N' or c = '%R' or c = '#' then
					done := True
				elseif c = '[' or c = ']' or c = '{' or c = '}' or c = ',' then
					done := True
				else
					Result.append_character (c)
					advance (1)
				end
			end
			Result.right_adjust
		end

	resolve_scalar (a_text: STRING_32; for_key: BOOLEAN): YAML_SCALAR
			-- Resolve plain scalar `a_text` to appropriate type.
		local
			lower_text: STRING_32
		do
			if for_key then
				create {YAML_STRING} Result.make_plain (a_text)
			else
				lower_text := a_text.as_lower
				if lower_text.same_string_general ("null") or lower_text.same_string_general ("~") or a_text.is_empty then
					create {YAML_NULL} Result
				elseif lower_text.same_string_general ("true") or lower_text.same_string_general ("yes") or lower_text.same_string_general ("on") then
					create {YAML_BOOLEAN} Result.make (True)
				elseif lower_text.same_string_general ("false") or lower_text.same_string_general ("no") or lower_text.same_string_general ("off") then
					create {YAML_BOOLEAN} Result.make (False)
				elseif is_integer_string (a_text) then
					create {YAML_INTEGER} Result.make_from_string (a_text)
				elseif is_real_string (a_text) then
					if lower_text.same_string_general (".inf") or lower_text.same_string_general ("+.inf") then
						create {YAML_REAL} Result.make_positive_infinity
					elseif lower_text.same_string_general ("-.inf") then
						create {YAML_REAL} Result.make_negative_infinity
					elseif lower_text.same_string_general (".nan") then
						create {YAML_REAL} Result.make_nan
					else
						create {YAML_REAL} Result.make_from_string (a_text)
					end
				else
					create {YAML_STRING} Result.make_plain (a_text)
				end
			end
		end

	is_integer_string (a_text: STRING_32): BOOLEAN
			-- Is `a_text` an integer?
		local
			i: INTEGER
			c: CHARACTER_32
		do
			if a_text.count > 0 then
				Result := True
				i := 1
				if a_text [1] = '+' or a_text [1] = '-' then
					i := 2
				end
				if i <= a_text.count and then a_text [i] = '0' and then a_text.count > i then
					c := a_text [i + 1]
					if c = 'x' or c = 'X' then
							-- Hexadecimal
						i := i + 2
						from
						until
							i > a_text.count or not Result
						loop
							c := a_text [i]
							Result := c.is_hexa_digit
							i := i + 1
						end
					elseif c = 'o' or c = 'O' then
							-- Octal
						i := i + 2
						from
						until
							i > a_text.count or not Result
						loop
							c := a_text [i]
							Result := c >= '0' and c <= '7'
							i := i + 1
						end
					else
							-- Regular integer starting with 0
						from
						until
							i > a_text.count or not Result
						loop
							Result := a_text [i].is_digit
							i := i + 1
						end
					end
				else
						-- Regular integer
					from
					until
						i > a_text.count or not Result
					loop
						Result := a_text [i].is_digit
						i := i + 1
					end
				end
				if i = 1 then
					Result := False
				end
			end
		end

	is_real_string (a_text: STRING_32): BOOLEAN
			-- Is `a_text` a real number?
		local
			lower_text: STRING_32
		do
			lower_text := a_text.as_lower
			if lower_text.same_string (".inf") or lower_text.same_string ("+.inf") or lower_text.same_string ("-.inf") or lower_text.same_string (".nan") then
				Result := True
			elseif a_text.has ('.') or a_text.has ('e') or a_text.has ('E') then
				Result := a_text.is_real
			end
		end

	read_identifier: STRING_32
			-- Read an identifier (anchor name, alias name).
		local
			c: CHARACTER_32
			done: BOOLEAN
		do
			create Result.make (20)
			from
				done := False
			until
				done or at_end
			loop
				c := current_char
				if c.is_alpha_numeric or c = '_' or c = '-' then
					Result.append_character (c)
					advance (1)
				else
					done := True
				end
			end
		end

	read_tag: STRING_32
			-- Read a tag.
		local
			c: CHARACTER_32
			done: BOOLEAN
		do
			create Result.make (20)
			from
				done := False
			until
				done or at_end
			loop
				c := current_char
				if c = ' ' or c = '%N' or c = '%R' or c = '%T' then
					done := True
				else
					Result.append_character (c)
					advance (1)
				end
			end
		end

	read_rest_of_line: STRING_32
			-- Read rest of current line.
		do
			create Result.make (80)
			from
			until
				at_end or else current_char = '%N' or else current_char = '%R'
			loop
				Result.append_character (current_char)
				advance (1)
			end
		end

	skip_yaml_directive
			-- Skip %YAML directive.
		do
			skip_to_end_of_line
			advance_line
		end

	skip_tag_directive
			-- Skip %TAG directive.
		do
			skip_to_end_of_line
			advance_line
		end

	skip_blanks
			-- Skip spaces and tabs.
		do
			from
			until
				at_end or else (current_char /= ' ' and current_char /= '%T')
			loop
				advance (1)
			end
		end

	skip_blanks_and_comments
			-- Skip blanks, newlines, and comments.
		local
			done: BOOLEAN
		do
			from
				done := False
			until
				done or at_end
			loop
				if current_char = ' ' or current_char = '%T' then
					advance (1)
				elseif current_char = '%N' then
					advance (1)
					line := line + 1
					column := 1
				elseif current_char = '%R' then
					advance (1)
					if not at_end and then current_char = '%N' then
						advance (1)
					end
					line := line + 1
					column := 1
				elseif current_char = '#' then
					-- Skip comment to end of line
					from
					until
						at_end or else current_char = '%N' or else current_char = '%R'
					loop
						advance (1)
					end
				else
					done := True
				end
			end
		end

	skip_to_end_of_line
			-- Skip to end of current line (without advancing past newline).
		local
			pos: INTEGER
		do
			if attached content as c then
				pos := c.index_of ('%N', position)
				if pos > position then
					advance (pos - position)
--					column := column + pos - position
--					position := pos
				end
			else
				from
				until
					at_end or else current_char = '%N' or else current_char = '%R'
				loop
					advance (1)
				end
			end
		end

	advance_line
			-- Advance past current line ending.
		local
			pos: INTEGER
		do
			if not at_end then
				if attached content as c then
					pos := c.index_of ('%N', position)
					if pos > position then
						advance (pos - position)
					end
				end
				if current_char = '%R' then
					advance (1)
					if not at_end and then current_char = '%N' then
						advance (1)
					end
				elseif current_char = '%N' then
					advance (1)
				end
			end
			line := line + 1
			column := 1
		end

	is_blank_line: BOOLEAN
			-- Is current line blank?
		local
			saved_pos: INTEGER
			saved_column: INTEGER
			c: CHARACTER_32
		do
			saved_pos := position
			saved_column := column
			Result := True
			from
			until
				at_end or else current_char = '%N' or else current_char = '%R' or not Result
			loop
				c := current_char
				if c /= ' ' and c /= '%T' then
					Result := False
				end
				advance (1)
			end
			position := saved_pos
			column := saved_column
		end

	current_indent: INTEGER
			-- Indentation of current position (spaces from line start).
		local
			saved_pos: INTEGER
			p: INTEGER
		do
			if attached content as c then
				saved_pos := position
				-- Go back to start of line
				p := position
				from
				until
					p <= 1 or else c [p - 1] = '%N' or else c [p - 1] = '%R'
				loop
					p := p - 1
				end
				-- Count leading spaces
				from
				until
					p > c.count or else c [p] /= ' '
				loop
					Result := Result + 1
					p := p + 1
				end
				position := saved_pos
			end
		end

	current_char: CHARACTER_32
			-- Current character.
		require
			not_at_end: not at_end
		do
			if attached content as c then
				Result := c [position]
			end
		end

	peek_char (offset: INTEGER): CHARACTER_32
			-- Character at `offset` from current position.
		do
			if attached content as c then
				if position + offset >= 1 and position + offset <= c.count then
					Result := c [position + offset]
				end
			end
		end

	advance (n: INTEGER)
			-- Advance position by `n` characters.
		do
			position := position + n
			column := column + n
		end

	at_end: BOOLEAN
			-- Are we at end of content?
		do
			if attached content as c then
				Result := position > c.count
			else
				Result := True
			end
		end

	at_position (p: INTEGER): BOOLEAN
			-- Is position `p` at or past end of content?
		do
			if attached content as c then
				Result := p > c.count
			else
				Result := True
			end
		end

	looking_at (s: STRING): BOOLEAN
			-- Does content at current position start with `s`?
		local
			i: INTEGER
		do
			if attached content as c then
				if position + s.count - 1 <= c.count then
					Result := True
					from
						i := 1
					until
						i > s.count or not Result
					loop
						Result := c [position + i - 1] = s [i]
						i := i + 1
					end
				end
			end
		end

	hex_to_char (hex: STRING_32): CHARACTER_32
			-- Convert hex string to character.
		local
			code: NATURAL_32
			i: INTEGER
			c: CHARACTER_32
			digit: NATURAL_32
		do
			from
				i := 1
			until
				i > hex.count
			loop
				c := hex [i]
				if c >= '0' and c <= '9' then
					digit := c.code.to_natural_32 - ('0').code.to_natural_32
				elseif c >= 'a' and c <= 'f' then
					digit := c.code.to_natural_32 - ('a').code.to_natural_32 + 10
				elseif c >= 'A' and c <= 'F' then
					digit := c.code.to_natural_32 - ('A').code.to_natural_32 + 10
				else
					digit := 0
				end
				code := code * 16 + digit
				i := i + 1
			end
			Result := code.to_character_32
		end

	add_error (a_message: STRING_32)
			-- Add error message.
		local
			full_message: STRING_32
			errs: like errors
		do
			create full_message.make (100)
			full_message.append ("Line ")
			full_message.append_integer (line)
			full_message.append (", column ")
			full_message.append_integer (column)
			full_message.append (": ")
			full_message.append (a_message)
			errs := errors
			if errs = Void then
				create errs.make (1)
				errors := errs
			end

			errs.extend (full_message)
		end

note
	copyright: "Copyright (c) 1984-2026, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"
end
