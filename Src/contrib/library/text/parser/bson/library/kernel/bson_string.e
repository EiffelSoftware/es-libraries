note
	description: "[
		BSON_STRING represents a UTF-8 string in BSON.
		
		In BSON, a string is serialized as:
		int32 (byte*) unsigned_byte(0)
		where int32 is the number of bytes in the string plus one for the trailing null.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	BSON_STRING

inherit
	BSON_VALUE
		redefine
			is_equal,
			is_string
		end

	BSON_CONSTANTS
		undefine
			is_equal
		end

create
	make_from_string,
	make_from_string_32,
	make_from_string_general

convert
	make_from_string ({READABLE_STRING_8, STRING_8, IMMUTABLE_STRING_8}),
	make_from_string_32 ({READABLE_STRING_32, STRING_32, IMMUTABLE_STRING_32}),
	make_from_string_general ({READABLE_STRING_GENERAL})

feature {NONE} -- Initialization

	make_from_string (s: READABLE_STRING_8)
			-- Initialize from ASCII string `s'.
		require
			s_not_void: s /= Void
		do
			create value.make_from_string_general (s)
		ensure
			value_set: value.same_string_general (s)
		end

	make_from_string_32 (s: READABLE_STRING_32)
			-- Initialize from Unicode string `s'.
		require
			s_not_void: s /= Void
		do
			create value.make_from_string (s)
		ensure
			value_set: value.same_string (s)
		end

	make_from_string_general (s: READABLE_STRING_GENERAL)
			-- Initialize from string `s'.
		require
			s_not_void: s /= Void
		do
			if attached {READABLE_STRING_8} s as s8 then
				make_from_string (s8)
			elseif attached {READABLE_STRING_32} s as s32 then
				make_from_string_32 (s32)
			else
				make_from_string_32 (s.as_string_32)
			end
		end

feature -- Status report

	is_string: BOOLEAN = True
			-- <Precursor>

feature -- Access

	bson_type: INTEGER_8
			-- <Precursor>
		do
			Result := bson_type_string
		end

	value: STRING_32
			-- String content.

	item: STRING_32
			-- Alias for `value'.
		do
			Result := value
		end

feature -- Conversion

	to_utf8: STRING_8
			-- UTF-8 encoded representation of `value'.
		do
			Result := {UTF_CONVERTER}.utf_32_string_to_utf_8_string_8 (value)
		ensure
			result_not_void: Result /= Void
		end

feature -- Comparison

	is_equal (other: like Current): BOOLEAN
			-- Is BSON_STRING made of same character sequence as `other'?
		do
			Result := value.same_string (other.value)
		end

	same_string (a_string: READABLE_STRING_GENERAL): BOOLEAN
			-- Is `value' same as `a_string'?
		do
			Result := value.same_string_general (a_string)
		end

	same_caseless_string (a_string: READABLE_STRING_GENERAL): BOOLEAN
			-- Is `value' same as `a_string' (case insensitive)?
		do
			Result := value.is_case_insensitive_equal_general (a_string)
		end

feature -- Visitor pattern

	accept (a_visitor: BSON_VISITOR)
			-- Accept `a_visitor'.
		do
			a_visitor.visit_bson_string (Current)
		end

feature -- Report

	hash_code: INTEGER
			-- Hash code value.
		do
			Result := value.hash_code
		end

feature -- Status report

	debug_output: READABLE_STRING_GENERAL
			-- String that should be displayed in debugger.
		do
			Result := value
		end

invariant
	value_not_void: value /= Void

note
	copyright: "2026, Jocelyn Fiat and Eiffel Software"
	license: "MIT License"
end
