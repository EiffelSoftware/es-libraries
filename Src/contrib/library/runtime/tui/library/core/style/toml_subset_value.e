note
	description: "[
		A value in a theme file (review/p2_terminal_widgets_plan.md, Q1): a string, or an
		array of strings. These are the only two TOML value types the subset reads
		(TOML_SUBSET_READER); numbers, booleans, dates and inline tables are not.

		Immutable. The texts are Unicode scalar values only (`is_valid_text`), the same set
		that TOML strings can hold, so every value can be written and read back.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TOML_SUBSET_VALUE

inherit
	ANY
		redefine
			is_equal,
			out
		end

create
	make_string,
	make_array

feature {NONE} -- Initialization

	make_string (a_text: READABLE_STRING_GENERAL)
			-- A string value with the text `a_text` (TOML: `key = "text"`).
		require
			valid_text: is_valid_text (a_text)
		do
			create text.make_from_string_general (a_text)
			create strings.make (0)
		ensure
			is_string: is_string
			text_set: string_value.same_string_general (a_text)
		end

	make_array (a_items: ITERABLE [READABLE_STRING_GENERAL])
			-- An array value with the strings `a_items`, in order (TOML: `key = ["a", "b"]`).
			-- No items gives the empty array (`key = []`).
		require
			valid_items: across a_items as l_item all is_valid_text (l_item) end
		do
			is_array := True
			create text.make_empty
			create strings.make (4)
			across a_items as l_item loop
				strings.extend (create {STRING_32}.make_from_string_general (l_item))
			end
		ensure
			is_array: is_array
		end

feature -- Status report

	is_array: BOOLEAN
			-- Is this an array of strings (else a string)?

	is_string: BOOLEAN
			-- Is this a string?
		do
			Result := not is_array
		end

	is_valid_text (a_text: READABLE_STRING_GENERAL): BOOLEAN
			-- Can `a_text` be a string of a value? It holds Unicode scalar values only: no
			-- surrogate code (U+D800 .. U+DFFF) and nothing above U+10FFFF (TOML 1.0, "Strings":
			-- strings are valid UTF-8, so only scalar values). Control characters are allowed;
			-- the writer escapes them.
		local
			i: INTEGER
			l_code: NATURAL_32
		do
			from
				Result := True
				i := 1
			until
				not Result or i > a_text.count
			loop
				l_code := a_text.code (i)
				Result := l_code <= 0x10FFFF and not (l_code >= 0xD800 and l_code <= 0xDFFF)
				i := i + 1
			end
		ensure
			instance_free: class
		end

feature -- Access

	string_value: STRING_32
			-- The text of a string value (a new string)
		require
			is_string: is_string
		do
			Result := text.twin
		end

	count: INTEGER
			-- Number of strings in an array value
		require
			is_array: is_array
		do
			Result := strings.count
		end

	item alias "[]" (i: INTEGER): STRING_32
			-- The `i`-th string of an array value (a new string)
		require
			is_array: is_array
			valid_index: 1 <= i and i <= count
		do
			Result := strings.i_th (i).twin
		end

	array_value: ARRAYED_LIST [STRING_32]
			-- The strings of an array value, in order (a new list of new strings)
		require
			is_array: is_array
		do
			create Result.make (strings.count)
			across strings as l_item loop
				Result.extend (l_item.twin)
			end
		ensure
			same_count: Result.count = count
		end

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Same kind and the same text, or the same strings in the same order
		local
			i: INTEGER
		do
			if is_array = a_other.is_array then
				if is_array then
					Result := strings.count = a_other.strings.count
					from
						i := 1
					until
						not Result or i > strings.count
					loop
						Result := strings.i_th (i).same_string (a_other.strings.i_th (i))
						i := i + 1
					end
				else
					Result := text.same_string (a_other.text)
				end
			end
		end

feature -- Output

	out: STRING_8
			-- The value as the writer prints it (`TOML_SUBSET_WRITER.value_text`), UTF-8 encoded
		do
			Result := {UTF_CONVERTER}.string_32_to_utf_8_string_8 ({TOML_SUBSET_WRITER}.value_text (Current))
		end

feature {TOML_SUBSET_VALUE} -- Implementation

	text: STRING_32
			-- The text of a string value (empty for an array value)

	strings: ARRAYED_LIST [STRING_32]
			-- The strings of an array value (empty for a string value)

invariant
	string_has_no_items: is_string implies strings.is_empty
	array_has_no_text: is_array implies text.is_empty

end
