note
	description: "Summary description for {YAML_INTEGER}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	YAML_INTEGER

inherit
	YAML_SCALAR
		rename
			to_integer_64 as value
		redefine
			is_integer,
			value,
			same_string,
			same_caseless_string
		end

create
	make_from_string,
	make_integer_64,
	make_integer_32

convert
	make_integer_64 ({INTEGER_64}),
	make_integer_32 ({INTEGER_32})

feature {NONE} -- Initialization

	make_from_string (s: READABLE_STRING_GENERAL)
		local
			hex: HEXADECIMAL_STRING_TO_INTEGER_CONVERTER
		do
			text := s.to_string_8
			if s.is_integer_64 then
				value := s.to_integer_64
			else
				if s.starts_with ("0x") then
					create hex.make
					hex.parse_string_with_type (s, hex.type_integer_64)
					value := hex.parsed_integer_64
				elseif s.starts_with ("0b") then
					-- TODO: add support for Octal
				end
			end
			style := Style_plain
		ensure
			is_integer: is_integer
		end

	make_integer_64 (a_value: INTEGER_64)
			-- Initialize with integer `a_value`.
		do
			value := a_value
			text := a_value.out
			style := Style_plain
		ensure
			is_integer: is_integer
		end

	make_integer_32 (a_value: INTEGER_32)
			-- Initialize with integer `a_value`.
		do
			make_integer_64 (a_value.to_integer_32)
		ensure
			is_integer: is_integer
		end

feature -- Access

	text: STRING_8

	value: INTEGER_64

feature -- Conversion	

	value_as_integer_64: INTEGER_64
		do
			Result := value
		end

	value_as_integer_32: INTEGER_32
		require
			is_integer_32
		do
			Result := value.to_integer_32
		end

	value_as_natural_32: NATURAL_32
		require
			is_natural_32_value: is_natural_32
		do
			Result := value.to_natural_32
		end

	value_as_natural_64: NATURAL_64
		require
			is_natural_64_value: is_natural_64
		do
			Result := value.to_natural_64
		end

	to_string_value: STRING_32
		do
			create Result.make_from_string_general (text)
		end

feature -- Status report

	is_integer: BOOLEAN = True

	is_integer_32: BOOLEAN
		do
			Result :=   value >= {INTEGER_32}.min_value.to_integer_64
					and value <= {INTEGER_32}.max_value.to_integer_64
		end

	is_natural_32: BOOLEAN
		do
			Result :=   value >= {NATURAL_32}.min_value.to_integer_64
					and value <= {NATURAL_32}.max_value.to_integer_64
		end

	is_natural_64: BOOLEAN
		do
			Result :=   value >= 0
		end

feature -- Status report

	same_string (a_string: READABLE_STRING_GENERAL): BOOLEAN
			-- Current value is a string value, and same content as `a_string`?
		do
			Result := a_string.same_string (to_string_value)
		end

	same_caseless_string (a_string: READABLE_STRING_GENERAL): BOOLEAN
			-- Current value is a string value, and same caseless content as `a_string`?	
		do
			Result := a_string.is_case_insensitive_equal (to_string_value)
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

