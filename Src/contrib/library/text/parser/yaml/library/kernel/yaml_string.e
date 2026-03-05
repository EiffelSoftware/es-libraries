note
	description: "Summary description for {YAML_STRING}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	YAML_STRING

inherit
	YAML_SCALAR
		rename
			to_string_32 as value
		redefine
			is_equal,
			is_string,
			value,
			same_string,
			same_caseless_string
		end

	HASHABLE
		redefine
			is_equal
		end

create
	make,
	make_plain,
	make_double_quoted,
	make_single_quoted,
	make_folded,
	make_literal

convert
	make ({READABLE_STRING_8, STRING_8, IMMUTABLE_STRING_8, READABLE_STRING_GENERAL, STRING_GENERAL, IMMUTABLE_STRING_GENERAL})

feature {NONE} -- Initialization

	make (a_value: READABLE_STRING_GENERAL)
			-- Initialize with string `a_value`.
		require
			value_attached: a_value /= Void
		do
			make_plain (a_value)
		ensure
			value_set: value.same_string (a_value)
		end

	make_plain (a_value: READABLE_STRING_GENERAL)
			-- Initialize with string `a_value`.
		require
			value_attached: a_value /= Void
		do
			value := a_value.to_string_32
			style := Style_plain
		ensure
			value_set: value.same_string (a_value)
			style_plain: style = Style_plain
		end

	make_double_quoted (a_value: READABLE_STRING_GENERAL)
			-- Initialize with string `a_value`, explicitly marked as string.
		require
			value_attached: a_value /= Void
		do
			value := a_value.to_string_32
			style := Style_double_quoted
		ensure
			is_string: is_string
			value_set: value.same_string (a_value)
		end

	make_single_quoted (a_value: READABLE_STRING_GENERAL)
			-- Initialize with string `a_value`, explicitly marked as string.
		require
			value_attached: a_value /= Void
		do
			value := a_value.to_string_32
			style := Style_single_quoted
		ensure
			is_string: is_string
			value_set: value.same_string (a_value)
		end

	make_folded (a_value: READABLE_STRING_GENERAL)
			-- Initialize with string `a_value`, explicitly marked as string.
		require
			value_attached: a_value /= Void
		do
			value := a_value.to_string_32
			style := Style_folded
		ensure
			is_string: is_string
			value_set: value.same_string (a_value)
		end

	make_literal (a_value: READABLE_STRING_GENERAL)
			-- Initialize with string `a_value`, explicitly marked as string.
		require
			value_attached: a_value /= Void
		do
			value := a_value.to_string_32
			style := Style_literal
		ensure
			is_string: is_string
			value_set: value.same_string (a_value)
		end

feature -- Access

	value: STRING_32

	value_as_string_8: STRING_8
		require
			is_valid_as_string_8
		do
			Result := value.to_string_8
		end

feature -- Conversion

	to_string_value: STRING_32
		do
			Result := value
		end

feature -- Status report

	is_string: BOOLEAN = True

	is_valid_as_string_8: BOOLEAN
		do
			Result := value.is_valid_as_string_8
		end

	hash_code: INTEGER
			-- Hash code value
		do
			Result := value.hash_code
		end

feature -- Comparison

	is_equal (other: like Current): BOOLEAN
			-- Is YAML_STRING  made of same character sequence as `other'
			-- (possibly with a different capacity)?
		do
			Result := value.same_string (other.value)
		end

feature -- Status report

	same_string (a_string: READABLE_STRING_GENERAL): BOOLEAN
			-- Current value is a string value, and same content as `a_string`?
		do
			Result := a_string.same_string (value)
		end

	same_caseless_string (a_string: READABLE_STRING_GENERAL): BOOLEAN
			-- Current value is a string value, and same caseless content as `a_string`?	
		do
			Result := a_string.is_case_insensitive_equal (value)
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
