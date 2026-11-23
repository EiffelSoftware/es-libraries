note
	description: "[
		Prints a TOML_SUBSET_DOCUMENT in the theme file format (review/p2_terminal_widgets_plan.md,
		Q1), which TOML_SUBSET_READER reads back to an equal document.

		The output is deterministic:
		* the sections in order, each as `[name]` on its own line, then one line per key in
		  order: `key = "text"` or `key = ["a", "b"]` (`key = []` when empty);
		* one blank line between sections, LF line ends, a final LF (an empty document is
		  the empty text);
		* no comments, no trailing commas, single spaces exactly as above.
		Strings are TOML basic strings (`quoted`): `"` and `\` are escaped as `\"` and `\\`,
		backspace, tab, line feed, form feed and carriage return as `\b`, `\t`, `\n`, `\f`,
		`\r`, the other control characters (U+0000 .. U+001F, U+007F) as `\u00XX`; every
		other character is written as it is.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TOML_SUBSET_WRITER

feature -- Output

	text (a_document: TOML_SUBSET_DOCUMENT): STRING_32
			-- `a_document` in the theme file format
		local
			i, j: INTEGER
			l_section: TOML_SUBSET_SECTION
		do
			create Result.make (256)
			from
				i := 1
			until
				i > a_document.count
			loop
				l_section := a_document.section (i)
				if i > 1 then
					Result.append_character ('%N')
				end
				Result.append_character ('[')
				Result.append (l_section.name)
				Result.append_character (']')
				Result.append_character ('%N')
				from
					j := 1
				until
					j > l_section.count
				loop
					Result.append (l_section.key (j))
					Result.append ({STRING_32} " = ")
					Result.append (value_text (l_section.value (j)))
					Result.append_character ('%N')
					j := j + 1
				end
				i := i + 1
			end
		ensure
			instance_free: class
			reads_back: attached (create {TOML_SUBSET_READER}.make).parsed (Result) as l_document and then l_document.is_equal (a_document)
		end

	value_text (a_value: TOML_SUBSET_VALUE): STRING_32
			-- `a_value` as it is written after `key = `: a basic string, or the array of basic
			-- strings `["a", "b"]` (`[]` when empty)
		local
			i: INTEGER
		do
			if a_value.is_string then
				Result := quoted (a_value.string_value)
			else
				create Result.make (16)
				Result.append_character ('[')
				from
					i := 1
				until
					i > a_value.count
				loop
					if i > 1 then
						Result.append ({STRING_32} ", ")
					end
					Result.append (quoted (a_value [i]))
					i := i + 1
				end
				Result.append_character (']')
			end
		ensure
			instance_free: class
		end

	quoted (a_text: READABLE_STRING_GENERAL): STRING_32
			-- `a_text` as a TOML basic string: in double quotes, with `"`, `\` and the control
			-- characters escaped (see the class note)
		require
			valid_text: {TOML_SUBSET_VALUE}.is_valid_text (a_text)
		local
			i: INTEGER
			l_code: NATURAL_32
		do
			create Result.make (a_text.count + 2)
			Result.append_character ('"')
			from
				i := 1
			until
				i > a_text.count
			loop
				l_code := a_text.code (i)
				inspect l_code
				when 0x22 then
					Result.append ({STRING_32} "\%"")
				when 0x5C then
					Result.append ({STRING_32} "\\")
				when 0x08 then
					Result.append ({STRING_32} "\b")
				when 0x09 then
					Result.append ({STRING_32} "\t")
				when 0x0A then
					Result.append ({STRING_32} "\n")
				when 0x0C then
					Result.append ({STRING_32} "\f")
				when 0x0D then
					Result.append ({STRING_32} "\r")
				when 0x00 .. 0x07, 0x0B, 0x0E .. 0x1F, 0x7F then
					Result.append ({STRING_32} "\u00")
					Result.append_character (Hex_digits.item ((l_code // 16).to_integer_32 + 1))
					Result.append_character (Hex_digits.item ((l_code \\ 16).to_integer_32 + 1))
				else
					Result.append_code (l_code)
				end
				i := i + 1
			end
			Result.append_character ('"')
		ensure
			instance_free: class
			quoted: Result.count >= 2 and Result [1] = '"' and Result [Result.count] = '"'
		end

feature {NONE} -- Implementation

	Hex_digits: STRING_32 = "0123456789ABCDEF"
			-- Digits of the `\u00XX` escape

end
