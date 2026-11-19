note
	description: "[
		Reads the theme file format (review/p2_terminal_widgets_plan.md, Q1): a small,
		line-based subset of TOML 1.0, so every text it accepts is a valid TOML document with
		the same meaning. Anything outside the subset is an error with its line and column,
		reported by queries (`has_error`, `error_line`, `error_column`, `error_message`), not
		by an exception. A failed read gives no document, not a part of one.

		The subset, one construct per line (TOML 1.0 rules followed in brackets):
		* Lines end with LF or CR LF ("Spec": a newline is LF or CRLF). The last line may
		  have no line end.
		* Whitespace is space and tab ("Spec"). It is ignored around names, keys, `=`,
		  values, `,` and brackets.
		* A blank line, or a line that holds only a comment, is skipped. A comment starts
		  with `#` and runs to the end of the line ("Comment"); it may also follow a header
		  or a value.
		* `[name]` starts a section ("Table"). `name` is a bare key: ASCII letters, digits,
		  "_" and "-" ("Keys"). A name may appear only once ("Table": defining a table more
		  than once is invalid).
		* `key = value` adds a key to the current section ("Keys", "Key/Value Pair"). `key`
		  is a bare key, at most once per section ("Keys": defining a key multiple times is
		  invalid). A key before the first section is an error: TOML allows such root keys,
		  but the theme format has none, so a misplaced line is reported.
		* A value is a basic string `"..."` ("String"), or an array of basic strings on the
		  same line, `["a", "b"]`, `[]` when empty, with an optional trailing comma
		  ("Array").
		* In a basic string, `\b`, `\t`, `\n`, `\f`, `\r`, `\"`, `\\`, `\uXXXX` and
		  `\UXXXXXXXX` (hex digits, a Unicode scalar value) are the escapes, all of TOML 1.0's
		  ("String"). A control character other than tab (U+0000 .. U+0008, U+000A .. U+001F,
		  U+007F) is an error anywhere in a line, in a string or a comment too ("String",
		  "Comment").
		Errors, everything else: quoted and dotted keys, nested tables (`[a.b]`), arrays of
		tables (`[[a]]`), literal and multi-line strings, numbers, booleans, dates, inline
		tables, nested and multi-line arrays, a bad escape, an unterminated string or array,
		text after a header or a value, a duplicate section or key.

		The text is read as Unicode (READABLE_STRING_GENERAL); decoding a file's UTF-8 is the
		caller's. Columns count characters from 1, a tab as one.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TOML_SUBSET_READER

create
	make

feature {NONE} -- Initialization

	make
			-- A reader that has read nothing yet.
		do
			create error_message.make_empty
		ensure
			no_document: document = Void
			no_error: not has_error
		end

feature -- Basic operations

	read (a_text: READABLE_STRING_GENERAL)
			-- Read `a_text`: make `document`, or set the error of the first line that is not
			-- in the subset and leave `document` Void.
		local
			l_line: STRING_32
			l_start, l_end, l_number: INTEGER
			l_done: BOOLEAN
		do
			document := Void
			has_error := False
			error_line := 0
			error_column := 0
			create error_message.make_empty
			create building.default_create
			current_section := Void
			from
				l_start := 1
				l_number := 1
			until
				l_done or has_error
			loop
				l_end := l_start
				from
				until
					l_end > a_text.count or else a_text.code (l_end) = Line_feed
				loop
					l_end := l_end + 1
				end
				create l_line.make (l_end - l_start)
				l_line.append_substring_general (a_text, l_start, l_end - 1)
				if l_end <= a_text.count and then not l_line.is_empty and then l_line.code (l_line.count) = Carriage_return then
						-- CR LF: the CR is part of the line end
					l_line.remove_tail (1)
				end
				read_line (l_line, l_number)
				if l_end > a_text.count then
					l_done := True
				else
					l_start := l_end + 1
					l_number := l_number + 1
				end
			end
			if not has_error then
				document := building
			end
			building := Void
			current_section := Void
		ensure
			document_or_error: has_error = (document = Void)
		end

	parsed (a_text: READABLE_STRING_GENERAL): detachable TOML_SUBSET_DOCUMENT
			-- `read (a_text)`, then `document`
		do
			read (a_text)
			Result := document
		ensure
			document_or_error: has_error = (Result = Void)
			is_document: Result = document
		end

feature -- Access

	document: detachable TOML_SUBSET_DOCUMENT
			-- The document the last `read` made, or Void after an error or before any `read`

	error_line: INTEGER
			-- Line of the error (from 1), or 0

	error_column: INTEGER
			-- Column of the error in `error_line` (from 1, in characters), or 0

	error_message: STRING_32
			-- What the error is (empty when there is none)

	error_description: STRING_32
			-- "line N, column M: message", or empty when there is no error
		do
			create Result.make_empty
			if has_error then
				Result.append ({STRING_32} "line ")
				Result.append_integer (error_line)
				Result.append ({STRING_32} ", column ")
				Result.append_integer (error_column)
				Result.append ({STRING_32} ": ")
				Result.append (error_message)
			end
		end

feature -- Status report

	has_error: BOOLEAN
			-- Did the last `read` find text outside the subset?

feature {NONE} -- Reading

	building: detachable TOML_SUBSET_DOCUMENT
			-- The document being read

	current_section: detachable TOML_SUBSET_SECTION
			-- The section the next keys go to

	read_line (a_line: STRING_32; a_number: INTEGER)
			-- Read line `a_number`, `a_line` without its line end.
		require
			no_error: not has_error
			reading: building /= Void
		local
			i: INTEGER
		do
			from
				i := 1
			until
				has_error or i > a_line.count
			loop
				if is_control (a_line.code (i)) then
					set_error (a_number, i, {STRING_32} "control character U+" + code_text (a_line.code (i)) + " is not allowed (write it as an escape in a string)")
				end
				i := i + 1
			end
			if not has_error then
				i := after_space (a_line, 1)
				if i > a_line.count or else a_line [i] = '#' then
						-- blank or comment line
				elseif a_line [i] = '[' then
					read_header (a_line, a_number, i)
				else
					read_key_value (a_line, a_number, i)
				end
			end
		end

	read_header (a_line: STRING_32; a_number, a_start: INTEGER)
			-- Read the section header at `a_start` (on its `[`).
		require
			no_error: not has_error
			on_bracket: a_line [a_start] = '['
		local
			i, l_name_start: INTEGER
			l_name: STRING_32
		do
			i := a_start + 1
			if i <= a_line.count and then a_line [i] = '[' then
				set_error (a_number, a_start, "arrays of tables ([[name]]) are not supported")
			else
				i := after_space (a_line, i)
				l_name_start := i
				i := after_bare_key (a_line, i)
				l_name := a_line.substring (l_name_start, i - 1)
				if l_name.is_empty then
					error_at_key (a_line, a_number, i, "expected a section name after '['")
				else
					i := after_space (a_line, i)
					if i <= a_line.count and then a_line [i] = '.' then
						set_error (a_number, i, "nested tables (dotted section names) are not supported")
					elseif i > a_line.count or else a_line [i] /= ']' then
						set_error (a_number, i, "expected ']' after the section name")
					else
						i := after_space (a_line, i + 1)
						if i <= a_line.count and then a_line [i] /= '#' then
							set_error (a_number, i, "unexpected text after the section header")
						elseif attached building as l_document then
							if l_document.has_section (l_name) then
								set_error (a_number, l_name_start, {STRING_32} "duplicate section [" + l_name + "]")
							else
								current_section := l_document.put_new (l_name)
								if attached current_section as l_new then
									l_new.set_line (a_number)
								end
							end
						end
					end
				end
			end
		end

	read_key_value (a_line: STRING_32; a_number, a_start: INTEGER)
			-- Read the `key = value` line whose key starts at `a_start`.
		require
			no_error: not has_error
		local
			i: INTEGER
			l_key: STRING_32
			l_value: detachable TOML_SUBSET_VALUE
		do
			i := after_bare_key (a_line, a_start)
			l_key := a_line.substring (a_start, i - 1)
			if l_key.is_empty then
				error_at_key (a_line, a_number, i, "expected a key or a section header")
			elseif not attached current_section as l_section then
				set_error (a_number, a_start, {STRING_32} "key '" + l_key + "' is outside a section (start with a [name] header)")
			else
				i := after_space (a_line, i)
				if i <= a_line.count and then a_line [i] = '.' then
					set_error (a_number, i, "dotted keys are not supported")
				elseif i > a_line.count or else a_line [i] /= '=' then
					set_error (a_number, i, "expected '=' after the key")
				else
					i := after_space (a_line, i + 1)
					if i > a_line.count or else a_line [i] = '#' then
						set_error (a_number, i, "missing value after '='")
					elseif a_line [i] = '"' then
						i := read_string (a_line, a_number, i)
						if not has_error then
							create l_value.make_string (last_string)
						end
					elseif a_line [i] = '[' then
						i := read_array (a_line, a_number, i)
						if not has_error then
							create l_value.make_array (last_array)
						end
					else
						error_at_value (a_line, a_number, i, "a value must be a double-quoted string or an array of strings")
					end
					if not has_error then
						i := after_space (a_line, i)
						if i <= a_line.count and then a_line [i] /= '#' then
							set_error (a_number, i, "unexpected text after the value")
						elseif l_section.has_key (l_key) then
							set_error (a_number, a_start, {STRING_32} "duplicate key '" + l_key + "' in section [" + l_section.name + "]")
						elseif attached l_value then
							l_section.put (l_key, l_value)
							l_section.set_key_line (l_section.count, a_number)
						end
					end
				end
			end
		end

	read_string (a_line: STRING_32; a_number, a_start: INTEGER): INTEGER
			-- Read the basic string that starts at `a_start` (on its `"`) into `last_string`;
			-- the index after its closing `"`.
		require
			no_error: not has_error
			on_quote: a_line [a_start] = '"'
		local
			i, l_digits: INTEGER
			l_code: INTEGER_64
			l_closed: BOOLEAN
		do
			create internal_last_string.make (16)
			if a_start + 2 <= a_line.count and then a_line [a_start + 1] = '"' and then a_line [a_start + 2] = '"' then
				set_error (a_number, a_start, "multi-line strings (%"%"%") are not supported")
			else
				from
					i := a_start + 1
				until
					l_closed or has_error
				loop
					if i > a_line.count then
						set_error (a_number, a_start, "unterminated string (a string ends with %" on the same line)")
					elseif a_line [i] = '"' then
						l_closed := True
						i := i + 1
					elseif a_line [i] = '\' then
						if i = a_line.count then
							set_error (a_number, i, "unterminated string (a line cannot end with \ in a basic string)")
						else
							inspect a_line [i + 1]
							when 'b' then
								last_string.append_code (0x08)
								i := i + 2
							when 't' then
								last_string.append_code (0x09)
								i := i + 2
							when 'n' then
								last_string.append_code (0x0A)
								i := i + 2
							when 'f' then
								last_string.append_code (0x0C)
								i := i + 2
							when 'r' then
								last_string.append_code (0x0D)
								i := i + 2
							when '"' then
								last_string.append_character ('"')
								i := i + 2
							when '\' then
								last_string.append_character ('\')
								i := i + 2
							when 'u', 'U' then
								if a_line [i + 1] = 'u' then
									l_digits := 4
								else
									l_digits := 8
								end
								l_code := hex_value (a_line, i + 2, l_digits)
								if l_code < 0 then
									set_error (a_number, i, {STRING_32} "invalid escape: \" + a_line.substring (i + 1, i + 1) + " needs " + l_digits.out + " hex digits")
								elseif l_code > 0x10FFFF or (l_code >= 0xD800 and l_code <= 0xDFFF) then
									set_error (a_number, i, {STRING_32} "invalid escape: " + a_line.substring (i, i + 1 + l_digits) + " is not a Unicode scalar value")
								else
									last_string.append_code (l_code.to_natural_32)
									i := i + 2 + l_digits
								end
							else
								set_error (a_number, i, {STRING_32} "invalid escape \" + a_line.substring (i + 1, i + 1) + " (the escapes are \b \t \n \f \r \%" \\ \uXXXX \UXXXXXXXX)")
							end
						end
					else
						last_string.append_character (a_line [i])
						i := i + 1
					end
				end
			end
			Result := i
		end

	read_array (a_line: STRING_32; a_number, a_start: INTEGER): INTEGER
			-- Read the array of strings that starts at `a_start` (on its `[`) into
			-- `last_array`; the index after its closing `]`.
		require
			no_error: not has_error
			on_bracket: a_line [a_start] = '['
		local
			i: INTEGER
			l_closed: BOOLEAN
		do
			create internal_last_array.make (4)
			from
				i := after_space (a_line, a_start + 1)
				if i <= a_line.count and then a_line [i] = ']' then
					l_closed := True
					i := i + 1
				end
			until
				l_closed or has_error
			loop
					-- an item
				if i > a_line.count or else a_line [i] = '#' then
					set_error (a_number, a_start, "unterminated array (an array ends with ] on the same line)")
				elseif a_line [i] = '"' then
					i := read_string (a_line, a_number, i)
					if not has_error then
						last_array.extend (last_string)
						i := after_space (a_line, i)
							-- then "," or "]"
						if i > a_line.count or else a_line [i] = '#' then
							set_error (a_number, a_start, "unterminated array (an array ends with ] on the same line)")
						elseif a_line [i] = ']' then
							l_closed := True
							i := i + 1
						elseif a_line [i] = ',' then
							i := after_space (a_line, i + 1)
							if i <= a_line.count and then a_line [i] = ']' then
									-- trailing comma
								l_closed := True
								i := i + 1
							end
						else
							set_error (a_number, i, "expected ',' or ']' in the array")
						end
					end
				elseif a_line [i] = '[' then
					set_error (a_number, i, "nested arrays are not supported")
				else
					error_at_value (a_line, a_number, i, "an array item must be a double-quoted string")
				end
			end
			Result := i
		end

	last_string: STRING_32
			-- The string `read_string` read
		do
			if attached internal_last_string as l_last_string then
				Result := l_last_string
			else
				create Result.make_empty
				internal_last_string := Result
			end
		end

	internal_last_string: detachable STRING_32
			-- Storage of `last_string`, created on first use (rather than a self-initializing
			-- attribute, which is not initialized when the library is compiled without void safety)

	last_array: ARRAYED_LIST [STRING_32]
			-- The strings `read_array` read
		do
			if attached internal_last_array as l_last_array then
				Result := l_last_array
			else
				create Result.make (0)
				internal_last_array := Result
			end
		end

	internal_last_array: detachable ARRAYED_LIST [STRING_32]
			-- Storage of `last_array`, created on first use (rather than a self-initializing
			-- attribute, which is not initialized when the library is compiled without void safety)

feature {NONE} -- Errors

	set_error (a_line, a_column: INTEGER; a_message: READABLE_STRING_GENERAL)
			-- Record the error `a_message` at `a_line`, `a_column`.
		require
			no_error: not has_error
			valid_line: a_line >= 1
			valid_column: a_column >= 1
			has_message: not a_message.is_empty
		do
			has_error := True
			error_line := a_line
			error_column := a_column
			create error_message.make_from_string_general (a_message)
		ensure
			has_error: has_error
			line_set: error_line = a_line
			column_set: error_column = a_column
		end

	error_at_key (a_line: STRING_32; a_number, i: INTEGER; a_message: READABLE_STRING_GENERAL)
			-- An error at `i`, where a bare key was expected: a quoted key is named as such,
			-- else `a_message`.
		require
			no_error: not has_error
		do
			if i <= a_line.count and then (a_line [i] = '"' or a_line [i] = '%'') then
				set_error (a_number, i, "quoted keys are not supported (use letters, digits, _ and -)")
			else
				set_error (a_number, i, a_message)
			end
		end

	error_at_value (a_line: STRING_32; a_number, i: INTEGER; a_message: READABLE_STRING_GENERAL)
			-- An error at `i`, where a string was expected: a literal string or an inline
			-- table is named as such, else `a_message`.
		require
			no_error: not has_error
			in_line: 1 <= i and i <= a_line.count
		do
			if a_line [i] = '%'' then
				set_error (a_number, i, "literal strings ('...') are not supported (use a double-quoted string)")
			elseif a_line [i] = '{' then
				set_error (a_number, i, "inline tables are not supported")
			else
				set_error (a_number, i, a_message)
			end
		end

feature {NONE} -- Scanning

	after_space (a_line: STRING_32; a_start: INTEGER): INTEGER
			-- First index from `a_start` that is not a space or a tab
		do
			from
				Result := a_start
			until
				Result > a_line.count or else (a_line [Result] /= ' ' and a_line [Result] /= '%T')
			loop
				Result := Result + 1
			end
		end

	after_bare_key (a_line: STRING_32; a_start: INTEGER): INTEGER
			-- First index from `a_start` that is not a bare key character
		do
			from
				Result := a_start
			until
				Result > a_line.count or else not {TOML_SUBSET_SECTION}.is_valid_key (a_line.substring (Result, Result))
			loop
				Result := Result + 1
			end
		end

	hex_value (a_line: STRING_32; a_start, a_count: INTEGER): INTEGER_64
			-- Value of the `a_count` hex digits from `a_start`, or -1 when they are not all hex
			-- digits
		require
			valid_count: a_count = 4 or a_count = 8
		local
			i, l_digit: INTEGER
		do
			if a_start + a_count - 1 > a_line.count then
				Result := -1
			else
				from
					i := a_start
				until
					Result < 0 or i >= a_start + a_count
				loop
					l_digit := Hex_digits.index_of (a_line [i].as_upper, 1) - 1
					if l_digit < 0 then
						Result := -1
					else
						Result := Result * 16 + l_digit
					end
					i := i + 1
				end
			end
		end

	is_control (a_code: NATURAL_32): BOOLEAN
			-- Is `a_code` a control character TOML does not allow unescaped (all but tab)?
		do
			Result := (a_code < 0x20 and a_code /= 0x09) or a_code = 0x7F
		end

	code_text (a_code: NATURAL_32): STRING_32
			-- `a_code` as four hex digits
		do
			Result := a_code.to_hex_string
			Result.keep_tail (4)
		end

	Hex_digits: STRING_32 = "0123456789ABCDEF"
			-- The hex digits, by value

	Line_feed: NATURAL_32 = 10
			-- LF

	Carriage_return: NATURAL_32 = 13
			-- CR

invariant
	error_has_position: has_error implies (error_line >= 1 and error_column >= 1 and not error_message.is_empty)
	error_has_no_document: has_error implies document = Void
	no_error_no_position: not has_error implies (error_line = 0 and error_column = 0 and error_message.is_empty)

end
