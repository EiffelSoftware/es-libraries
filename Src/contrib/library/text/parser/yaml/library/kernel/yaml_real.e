note
	description: "Summary description for {YAML_REAL}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	YAML_REAL

inherit
	YAML_SCALAR
		rename
			to_real_64 as value
		redefine
			is_real,
			value
		end

create
	make_from_string,
	make_nan,
	make_positive_infinity,
	make_negative_infinity,
	make_real_64,
	make_real_32

convert
	make_real_64 ({REAL_64}),
	make_real_32 ({REAL_32})

feature {NONE} -- Initialization

	make_from_string (s: READABLE_STRING_GENERAL)
		do
			if s.is_case_insensitive_equal ("+.inf") then
				make_positive_infinity
			elseif s.is_case_insensitive_equal ("-.inf") then
				make_negative_infinity
			elseif s.is_case_insensitive_equal (".nan") then
				make_nan
			else
				text := s.to_string_8
				value := s.to_double
				style := Style_plain
			end
		ensure
			is_real: is_real
		end

	make_positive_infinity
		do
			text := "+.inf"
			value := {REAL_64}.positive_infinity
			style := Style_plain
		ensure
			is_real: is_real
		end

	make_negative_infinity
		do
			text := "-.inf"
			value := {REAL_64}.negative_infinity
			style := Style_plain
		ensure
			is_real: is_real
		end

	make_nan
		do
			text := ".nan"
			value := {REAL_64}.nan
			style := Style_plain
		ensure
			is_real: is_real
		end

	make_real_64 (a_value: REAL_64)
			-- Initialize with real `a_value`.
		do
			value := a_value
			text := a_value.out -- TODO: better formatting.
			style := Style_plain
		ensure
			is_real: is_real
		end

	make_real_32 (a_value: REAL_32)
			-- Initialize with real `a_value`.
		do
			make_real_64 (a_value.to_double)
		ensure
			is_real: is_real
		end

feature -- Access

	text: STRING_8

	value: REAL_64

feature -- Conversion

	value_as_real_64: REAL_64
		do
			Result := value
		end

	value_as_real_32: REAL_32
		require
			is_real_32
		do
			Result := value.truncated_to_real
		end

	to_string_value: STRING_32
		do
			create Result.make_from_string_general (text)
		end

feature -- Status report

	is_real: BOOLEAN = True

	is_real_32: BOOLEAN
		do
			Result :=   value >= {REAL_32}.min_value.to_double
					and value <= {REAL_32}.max_value.to_double
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

