note
	description: "[
		Lexical analyzer for PDF files.
		Tokenizes PDF byte streams according to ISO 32000-1:2008 §7.2 (Lexical Conventions).
		Handles whitespace, comments, delimiters, and all PDF object types.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_LEXER

create
	make

feature -- Initialization

	make (a_source: PDF_BYTE_SOURCE)
			-- Create lexer with given byte source.
			-- NOTE: Caller must set source position before using the lexer.
			-- The lexer does NOT reset the source position.
		require
			source_valid: a_source.is_valid
		do
			source := a_source
				-- Removed: source.set_position (0)
				-- Caller is responsible for setting position before calling next_token.
		ensure
			source_set: source = a_source
		end

feature -- Access

	source: PDF_BYTE_SOURCE
			-- Byte source being lexed.

feature -- Basic Operations

	next_token: PDF_TOKEN
			-- Read and return next token from source.
		local
			ch: NATURAL_8
		do
			skip_whitespace_and_comments

			if source.end_of_source then
				create Result.make ({PDF_TOKEN}.type_eof, "")
			else
				ch := source.peek_byte

					-- Check specific delimiters FIRST (before generic is_delimiter)
				if ch = Ascii_slash then
					Result := read_name
				elseif ch = Ascii_open_paren then
					Result := read_literal_string
				elseif ch = Ascii_less_than then
					Result := read_hex_string_or_dict_start
				elseif is_digit (ch) or ch = Ascii_plus or ch = Ascii_minus then
					Result := read_number_or_reference
				elseif is_alpha (ch) then
					Result := read_keyword
				elseif is_delimiter (ch) then
						-- Generic delimiters: [ ] >> { } %
					Result := read_delimiter
				else
					create Result.make ({PDF_TOKEN}.type_eof, "")
				end
			end
		end

feature {NONE} -- Implementation: ASCII Constants

	Ascii_null: NATURAL_8 = 0x00
	Ascii_tab: NATURAL_8 = 0x09
	Ascii_lf: NATURAL_8 = 0x0A
	Ascii_ff: NATURAL_8 = 0x0C
	Ascii_cr: NATURAL_8 = 0x0D
	Ascii_space: NATURAL_8 = 0x20

	Ascii_percent: NATURAL_8 = 0x25       -- %
	Ascii_open_paren: NATURAL_8 = 0x28    -- (
	Ascii_close_paren: NATURAL_8 = 0x29   -- )
	Ascii_plus: NATURAL_8 = 0x2B          -- +
	Ascii_minus: NATURAL_8 = 0x2D         -- -
	Ascii_period: NATURAL_8 = 0x2E        -- .
	Ascii_slash: NATURAL_8 = 0x2F         -- /

	Ascii_zero: NATURAL_8 = 0x30          -- 0
	Ascii_nine: NATURAL_8 = 0x39          -- 9

	Ascii_less_than: NATURAL_8 = 0x3C     -- <
	Ascii_greater_than: NATURAL_8 = 0x3E  -- >

	Ascii_upper_a: NATURAL_8 = 0x41       -- A
	Ascii_upper_f: NATURAL_8 = 0x46       -- F
	Ascii_upper_z: NATURAL_8 = 0x5A       -- Z

	Ascii_open_bracket: NATURAL_8 = 0x5B  -- [
	Ascii_backslash: NATURAL_8 = 0x5C     -- \
	Ascii_close_bracket: NATURAL_8 = 0x5D -- ]

	Ascii_lower_a: NATURAL_8 = 0x61       -- a
	Ascii_lower_f: NATURAL_8 = 0x66       -- f
	Ascii_lower_z: NATURAL_8 = 0x7A       -- z

	Ascii_open_brace: NATURAL_8 = 0x7B    -- {
	Ascii_close_brace: NATURAL_8 = 0x7D   -- }

feature {NONE} -- Implementation: Character Classification

	is_whitespace (ch: NATURAL_8): BOOLEAN
			-- Is character a PDF whitespace? (ISO 32000-1:2008 Table 1)
		do
			Result := ch = Ascii_null
				or ch = Ascii_tab
				or ch = Ascii_lf
				or ch = Ascii_ff
				or ch = Ascii_cr
				or ch = Ascii_space
		end

	is_delimiter (ch: NATURAL_8): BOOLEAN
			-- Is character a PDF delimiter? (ISO 32000-1:2008 Table 2)
		do
			Result := ch = Ascii_open_paren
				or ch = Ascii_close_paren
				or ch = Ascii_less_than
				or ch = Ascii_greater_than
				or ch = Ascii_open_bracket
				or ch = Ascii_close_bracket
				or ch = Ascii_open_brace
				or ch = Ascii_close_brace
				or ch = Ascii_slash
				or ch = Ascii_percent
		end

	is_digit (ch: NATURAL_8): BOOLEAN
			-- Is character a decimal digit?
		do
			Result := ch >= Ascii_zero and ch <= Ascii_nine
		end

	is_alpha (ch: NATURAL_8): BOOLEAN
			-- Is character alphabetic?
		do
			Result := (ch >= Ascii_lower_a and ch <= Ascii_lower_z)
				or (ch >= Ascii_upper_a and ch <= Ascii_upper_z)
		end

	is_hex_digit (ch: NATURAL_8): BOOLEAN
			-- Is character a hexadecimal digit?
		do
			Result := is_digit (ch)
				or (ch >= Ascii_lower_a and ch <= Ascii_lower_f)
				or (ch >= Ascii_upper_a and ch <= Ascii_upper_f)
		end

feature {NONE} -- Implementation: Whitespace and Comments

	skip_whitespace_and_comments
			-- Skip whitespace and comments.
		local
			ch: NATURAL_8
		do
			from
			until
				source.end_of_source or else (not is_whitespace (source.peek_byte) and source.peek_byte /= Ascii_percent)
			loop
				ch := source.peek_byte
				if is_whitespace (ch) then
					source.advance (1)
				elseif ch = Ascii_percent then
					skip_comment
				end
			end
		end

	skip_comment
			-- Skip comment (from % to end of line).
		require
			at_comment_start: not source.end_of_source and then source.peek_byte = Ascii_percent
		local
			ch: NATURAL_8
			done: BOOLEAN
		do
			from
				done := False
			until
				source.end_of_source or done
			loop
				ch := source.read_byte
				if ch = Ascii_lf or ch = Ascii_cr then
					done := True
				end
			end
		end

feature {NONE} -- Implementation: Token Reading

	read_delimiter: PDF_TOKEN
			-- Read delimiter token.
		require
			at_delimiter: not source.end_of_source and then is_delimiter (source.peek_byte)
		local
			ch: NATURAL_8
			val: STRING_8
		do
			ch := source.read_byte
			create val.make (2)
			val.append_character (ch.to_character_8)

			if ch = Ascii_open_bracket then
				create Result.make ({PDF_TOKEN}.type_array_start, val)
			elseif ch = Ascii_close_bracket then
				create Result.make ({PDF_TOKEN}.type_array_end, val)
			elseif ch = Ascii_greater_than then
					-- Check for dictionary end >>
				if not source.end_of_source and then source.peek_byte = Ascii_greater_than then
					source.advance (1)  -- Skip second '>'
					create Result.make ({PDF_TOKEN}.type_dict_end, ">>")
				else
					create Result.make ({PDF_TOKEN}.type_eof, val)
				end
			else
				create Result.make ({PDF_TOKEN}.type_eof, val)
			end
		end

	read_number_or_reference: PDF_TOKEN
			-- Read number or indirect reference (e.g., "123 0 R").
		local
			num_str: STRING_8
		do
			num_str := read_number_string
			create Result.make ({PDF_TOKEN}.type_number, num_str)
		end

	read_number_string: STRING_8
			-- Read numeric string.
		local
			ch: NATURAL_8
		do
			create Result.make (10)

			if not source.end_of_source then
				ch := source.peek_byte
				if ch = Ascii_plus or ch = Ascii_minus then
					Result.append_character (source.read_byte.to_character_8)
				end
			end

			from
			until
				source.end_of_source or else not (is_digit (source.peek_byte) or source.peek_byte = Ascii_period)
			loop
				Result.append_character (source.read_byte.to_character_8)
			end
		end

	read_name: PDF_TOKEN
			-- Read name object (starts with /).
			-- Per ISO 32000-1:2008 §7.3.5, the slash is a delimiter, not part of the name value.
		require
			at_name_start: not source.end_of_source and then source.peek_byte = Ascii_slash
		local
			name_str: STRING_8
			ch: NATURAL_8
		do
			source.advance (1)  -- Skip '/'
			create name_str.make (20)
				-- NOTE: Do NOT append '/' to name_str. The slash is a delimiter, not part of the name.

			from
			until
				source.end_of_source or else is_whitespace (source.peek_byte) or else is_delimiter (source.peek_byte)
			loop
				ch := source.read_byte
				name_str.append_character (ch.to_character_8)
			end

			create Result.make ({PDF_TOKEN}.type_name, name_str)
		end

	read_literal_string: PDF_TOKEN
			-- Read literal string (...).
		require
			at_string_start: not source.end_of_source and then source.peek_byte = Ascii_open_paren
		local
			str: STRING_8
			ch: NATURAL_8
			paren_depth: INTEGER
			octal_val: INTEGER
			digit_count: INTEGER
			next_ch: NATURAL_8
			is_octal: BOOLEAN
		do
			source.advance (1)  -- Skip '('
			create str.make (100)

			from
				paren_depth := 1
			until
				source.end_of_source or paren_depth = 0
			loop
				ch := source.read_byte

				if ch = Ascii_backslash then
					if not source.end_of_source then
						ch := source.read_byte
						inspect ch.to_character_8
						when 'n' then
							str.append_character ('%N')
						when 'r' then
							str.append_character ('%R')
						when 't' then
							str.append_character ('%T')
						when 'b' then
							str.append_character ('%B')
						when 'f' then
							str.append_character ('%F')
						when '(', ')', '\' then
							str.append_character (ch.to_character_8)
						when '0', '1', '2', '3', '4', '5', '6', '7' then
							-- Octal code: read up to 3 octal digits
							octal_val := (ch - Ascii_zero).to_integer_32
							digit_count := 1
							
							from
								is_octal := True
							until
								digit_count >= 3 or not is_octal or source.end_of_source
							loop
								next_ch := source.peek_byte
								if next_ch >= Ascii_zero and next_ch <= 0x37 then -- '0' to '7'
									source.advance (1)
									octal_val := octal_val * 8 + (next_ch - Ascii_zero).to_integer_32
									digit_count := digit_count + 1
								else
									is_octal := False
								end
							end
							str.append_character ((octal_val \\ 256).to_character_8)
						when '%R', '%N' then
							-- backslash followed by newline: ignore both
							-- If it was CR and next is LF, consume LF too
							if ch.to_character_8 = '%R' and then not source.end_of_source and then source.peek_byte = Ascii_lf then
								source.advance (1)
							end
						else
							-- Ignored backslash, append character as-is
							str.append_character (ch.to_character_8)
						end
					end
				elseif ch = Ascii_open_paren then
					paren_depth := paren_depth + 1
					str.append_character (ch.to_character_8)
				elseif ch = Ascii_close_paren then
					paren_depth := paren_depth - 1
					if paren_depth > 0 then
						str.append_character (ch.to_character_8)
					end
				else
					str.append_character (ch.to_character_8)
				end
			end

			create Result.make ({PDF_TOKEN}.type_string, str)
		end

	read_hex_string_or_dict_start: PDF_TOKEN
			-- Read hex string <...> or dictionary start <<.
		require
			at_less_than: not source.end_of_source and then source.peek_byte = Ascii_less_than
		do
			source.advance (1)  -- Skip first '<'

			if not source.end_of_source and then source.peek_byte = Ascii_less_than then
				source.advance (1)  -- Skip second '<'
				create Result.make ({PDF_TOKEN}.type_dict_start, "<<")
			else
				Result := read_hex_string_content
			end
		end

	read_hex_string_content: PDF_TOKEN
			-- Read hexadecimal string content (already consumed first '<').
		local
			str: STRING_8
			ch: NATURAL_8
		do
			create str.make (100)

			from
			until
				source.end_of_source or else source.peek_byte = Ascii_greater_than
			loop
				ch := source.read_byte
				if is_hex_digit (ch) then
					str.append_character (ch.to_character_8)
				end
			end

			if not source.end_of_source then
				source.advance (1)  -- Skip '>'
			end

			create Result.make ({PDF_TOKEN}.type_hex_string, str)
		end

	read_keyword: PDF_TOKEN
			-- Read keyword (alphabetic sequence).
		require
			at_keyword_start: not source.end_of_source and then is_alpha (source.peek_byte)
		local
			keyword: STRING_8
			ch: NATURAL_8
			token_type: INTEGER
		do
			create keyword.make (20)

			from
			until
				source.end_of_source or else not (is_alpha (source.peek_byte) or is_digit (source.peek_byte))
			loop
				ch := source.read_byte
				keyword.append_character (ch.to_character_8)
			end

			if keyword.is_equal ("null") then
				token_type := {PDF_TOKEN}.type_null
			elseif keyword.is_equal ("true") or keyword.is_equal ("false") then
				token_type := {PDF_TOKEN}.type_boolean
			elseif keyword.is_equal ("obj") then
				token_type := {PDF_TOKEN}.type_obj_start
			elseif keyword.is_equal ("endobj") then
				token_type := {PDF_TOKEN}.type_obj_end
			elseif keyword.is_equal ("stream") then
				token_type := {PDF_TOKEN}.type_stream_start
			elseif keyword.is_equal ("endstream") then
				token_type := {PDF_TOKEN}.type_stream_end
			elseif keyword.is_equal ("R") then
				token_type := {PDF_TOKEN}.type_ref
			elseif keyword.is_equal ("xref") then
				token_type := {PDF_TOKEN}.type_xref
			elseif keyword.is_equal ("trailer") then
				token_type := {PDF_TOKEN}.type_trailer
			elseif keyword.is_equal ("startxref") then
				token_type := {PDF_TOKEN}.type_startxref
			else
				token_type := {PDF_TOKEN}.type_eof
			end

			create Result.make (token_type, keyword)
		end

end
