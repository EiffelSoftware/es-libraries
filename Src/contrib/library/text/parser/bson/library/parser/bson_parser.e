note
	description: "BSON parser for parsing binary BSON data into Eiffel objects."
	date: "$Date$"
	revision: "$Revision$"

class BSON_PARSER

inherit
	BSON_CONSTANTS
		export
			{NONE} all
		end

create
	make

feature -- Initialization

	make
		do
			create last_error.make_empty
			create {NULL_NATURAL_8_INPUT_STREAM} input
		end

feature -- Access

	has_error: BOOLEAN
		do
			Result := not last_error.is_empty
		ensure
			has_error_implies_error_not_empty: has_error implies not last_error.is_empty
		end

	last_error: STRING_32

feature -- Parsing

	parse (a_bytes: ARRAY [NATURAL_8]): like parse_input
		require
			bytes_not_void: a_bytes /= Void
		do
			Result := parse_input (create {BYTE_ARRAY_INPUT_STREAM}.make (a_bytes))
		end

	parse_file (fn: READABLE_STRING_GENERAL): like parse_input
		require
			fn_set: fn /= Void
		do
			Result := parse_input (create {FILE_NATURAL_8_INPUT_STREAM}.make_with_filename (fn))
		end

	parse_string_8 (in: READABLE_STRING_8): like parse_input
		require
			input_set: in /= Void
		do
			Result := parse_input (create {STRING_8_NATURAL_8_INPUT_STREAM}.make (in))
		end

	parse_input (in: NATURAL_8_INPUT_STREAM): detachable BSON_DOCUMENT
		require
			input_set: in /= Void
		local
			l_doc: like parse_input
		do
			last_error.make_empty
			input := in
			l_doc := parse_document
			if not has_error then
				Result := l_doc
			end
		end

feature {NONE} -- Implementation

	bson_min_document_length: INTEGER
		do
			Result := 4 -- FIXME: what is that?
		end

	parse_document: detachable BSON_DOCUMENT
		local
			l_int32: INTEGER_32
		do
			l_int32 := read_int32
			if l_int32 < bson_min_document_length then --or byte_index - 1 + l_int32 - 4 > bytes_count then
				set_error ({BSON_MESSAGES}.document_length_invalid)
--				byte_index := bytes_count + 1
			else
				create Result.make_empty
				parse_elements_into (Result, byte_index - 4 + l_int32 - 1)
			end
		end

	read_key: detachable READABLE_STRING_32
		do
			Result := read_cstring
		end

	parse_elements_into (a_container: BSON_DOCUMENT; a_end_index: INTEGER)
		require
			container_not_void: a_container /= Void
--			a_end_index <= bytes_count
--			null_terminated: bytes [a_end_index] = 0
		local
			l_type: INTEGER_8
			l_key: detachable READABLE_STRING_32
			l_value: detachable BSON_VALUE
			l_end_reached: BOOLEAN
		do
			from
				l_end_reached := False
			until
				l_end_reached or byte_index > a_end_index or has_error
			loop
				l_type := read_int8
				if l_type = 0 then
					-- End of document/array
					l_end_reached := True
				else
					l_key := read_key
					if l_key /= Void then
						l_value := parse_value (l_type)
						if l_value /= Void then
							a_container.put (l_value, l_key)
						end
					else
						set_error ({BSON_MESSAGES}.key_invalid)
					end
				end
			end
		end

	parse_elements_into_array (a_container: BSON_ARRAY; a_end_index: INTEGER)
		require
			container_not_void: a_container /= Void
--			a_end_index <= bytes_count
--			null_terminated: bytes [a_end_index] = 0
		local
			l_type: INTEGER_8
			l_value: detachable BSON_VALUE
			l_key: detachable READABLE_STRING_32
			l_end_reached: BOOLEAN
		do
			from
				l_end_reached := False
			until
				l_end_reached or byte_index > a_end_index or has_error
			loop
				l_type := read_int8
				if l_type = 0 then
					-- End of document/array
					l_end_reached := True
				else
					l_key := read_key
					if l_key /= Void then
						l_value := parse_value (l_type)
						if l_value /= Void then
							a_container.extend (l_value)
						end
					end
				end
			end
		end

	parse_null: BSON_NULL
		do
			create {BSON_NULL} Result
		end

	parse_value (a_type: INTEGER_8): detachable BSON_VALUE
		require
			type_in_range: a_type >= bson_type_min_key and a_type <= bson_type_max_key
		do
			inspect a_type
			when bson_type_double then
				Result := parse_double
			when bson_type_string then
				Result := parse_string
			when bson_type_document then
				Result := parse_document
			when bson_type_array then
				Result := parse_array
			when bson_type_binary then
				Result := parse_binary
			when bson_type_object_id then
				Result := parse_object_id
			when bson_type_boolean then
				Result := parse_boolean
			when bson_type_datetime then
				Result := parse_datetime
			when bson_type_null then
				Result := parse_null
			when bson_type_regex then
				Result := parse_regex
			when bson_type_javascript then
				Result := parse_javascript
			when bson_type_int32 then
				Result := parse_int32
			when bson_type_timestamp then
				Result := parse_timestamp
			when bson_type_int64 then
				Result := parse_int64
			when bson_type_min_key then
				create {BSON_MIN_KEY} Result
			when bson_type_max_key then
				create {BSON_MAX_KEY} Result
			else
				set_error ({BSON_MESSAGES}.type_unsupported (a_type))
			end
		ensure
			value_created_or_error: (Result /= Void) /= has_error
		end

	parse_double: detachable BSON_DOUBLE
		do
			if check_remaining_bytes (8) then
				create Result.make (read_real_64)
			end
		end

	parse_string: detachable BSON_STRING
		local
			l_len: INTEGER_32
			l_str: STRING_32
		do
			if check_remaining_bytes (4) then
				l_len := read_int32
				if l_len > 0 and check_remaining_bytes (l_len) then
					l_str := read_utf8_string (l_len)
					l_str.remove_tail (1)
					create Result.make_from_string_general (l_str)
				end
			end
		end

	parse_array: detachable BSON_ARRAY
		local
			l_start: INTEGER_32
			l_size: INTEGER_32
		do
			l_start := byte_index
			l_size := read_int32
			create Result.make_empty
			parse_elements_into_array (Result, l_start + l_size - 1)
			check
				byte_index = l_start + l_size --+ 1
			end
		end

	parse_binary: detachable BSON_BINARY
		local
			l_len: INTEGER_32
			l_subtype: NATURAL_8
			l_data: ARRAY [NATURAL_8]
		do
			if check_remaining_bytes (5) then
				l_len := read_int32
				l_subtype := read_natural_8
				if check_remaining_bytes (l_len.to_integer_32) then
					l_data := read_bytes (l_len.to_integer_32)
					create Result.make_with_subtype (l_data, l_subtype)
				end
			end
		end

	parse_object_id: detachable BSON_OBJECT_ID
		do
			if check_remaining_bytes (12) then
				create Result.make_from_bytes (read_bytes (12))
			end
		end

	parse_boolean: detachable BSON_BOOLEAN
		do
			if check_remaining_bytes (1) then
				create Result.make (read_natural_8 /= 0)
			end
		end

	parse_datetime: detachable BSON_DATETIME
		do
			if check_remaining_bytes (8) then
				create Result.make (read_int64)
			end
		end

	parse_regex: detachable BSON_REGEX
		local
			l_pattern: detachable STRING_32
			l_options: detachable STRING_32
		do
			l_pattern := read_cstring
			if l_pattern /= Void then
				l_options := read_cstring
				if l_options /= Void and then l_options.is_valid_as_string_8 then
					create Result.make_with_options (l_pattern, l_options.to_string_8)
				end
			end
		end

	parse_javascript: detachable BSON_JAVASCRIPT
		local
			l_js: detachable BSON_STRING
		do
			l_js := parse_string
			if attached l_js then
				create Result.make (l_js.value)
			end
		end

	parse_int32: detachable BSON_INT32
		do
			if check_remaining_bytes (4) then
				create Result.make (read_int32)
			end
		end

	parse_timestamp: detachable BSON_TIMESTAMP
		do
			if check_remaining_bytes (8) then
				create Result.make_from_raw (read_natural64)
			end
		end

	parse_int64: detachable BSON_INT64
		do
			if check_remaining_bytes (8) then
				create Result.make (read_int64)
			end
		end

feature {NONE} -- Reading primitives

	input: NATURAL_8_INPUT_STREAM

--	bytes: ARRAY [NATURAL_8]

	byte_index: INTEGER
		do
			Result := input.index
		end

	end_of_input: BOOLEAN
		do
--			Result := byte_index > bytes.count
			Result := input.end_of_input
		end

	next
		do
--			byte_index := byte_index + 1
			input.next
		end

	current_byte: NATURAL_8
		do
--			Result := bytes [byte_index]
			Result := input.last_byte
		end

	read_bytes (n: INTEGER): ARRAY [NATURAL_8]
		require
			n_non_negative: n >= 0
			check_remaining_bytes (n)
		local
			i: INTEGER
		do
			create Result.make_filled (0, 1, n)
			Result.compare_objects
			from
				i := 1
			until
				i > n or end_of_input
			loop
				next
				Result[i] := current_byte
				i := i + 1
			end
		ensure
			result_not_void: Result /= Void
			result_count: Result.count = n
		end

	check_remaining_bytes (n: INTEGER): BOOLEAN
		do
			Result := True--byte_index + n - 1 <= bytes_count
		ensure
--			bytes_attached_implies_check: (byte_index + n - 1 <= bytes_count) = Result
		end

	read_natural_8: NATURAL_8
		require
			check_remaining_bytes (1)
		do
			next
			Result := current_byte
		end

	read_int8: INTEGER_8
		require
			check_remaining_bytes (1)
		do
			Result := read_natural_8.to_integer_8
		end

	read_int16: INTEGER_16
		require
			check_remaining_bytes (2)
		local
			l_low, l_high: NATURAL_8
		do
			l_low := read_natural_8
			l_high := read_natural_8
			Result := (l_high.to_integer_16 * 256 + l_low.to_integer_16).to_integer_16
		end

	read_int32: INTEGER_32
		require
			check_remaining_bytes (4)
		local
			mp: MANAGED_POINTER
		do
			create mp.make_from_array (read_bytes (4))
			Result := mp.read_integer_32 (0)
		end

	read_int64: INTEGER_64
		require
			check_remaining_bytes (8)
		local
			mp: MANAGED_POINTER
		do
			create mp.make_from_array (read_bytes (8))
			Result := mp.read_integer_64 (0)
		end

	read_natural64: NATURAL_64
		require
			check_remaining_bytes (8)
		local
			mp: MANAGED_POINTER
		do
			create mp.make_from_array (read_bytes (8))
			Result := mp.read_natural_64 (0)
		end

	read_real_64: REAL_64
		require
			check_remaining_bytes (8)
		local
			mp: MANAGED_POINTER
		do
			create mp.make_from_array (read_bytes (8))
			Result := mp.read_real_64_le (0)
		end

	read_cstring: detachable STRING_32
		local
			s: STRING_8
		do
			create s.make (3)
			from
				next
			until
				end_of_input or else current_byte = 0
			loop
				s.append_code (current_byte)
				next
			end
			if end_of_input then
				set_error ({BSON_MESSAGES}.cstring_unterminated)
			else
				Result := {UTF_CONVERTER}.utf_8_string_8_to_string_32 (s)
--				next
			end
		end

	read_utf8_string (n: INTEGER): STRING_32
		require
			n_non_negative: n >= 0
			check_remaining_bytes (n)
		local
			l_ba: ARRAY [NATURAL_8]
			s: STRING_8
		do
			l_ba := read_bytes (n)
			create s.make (n)
			across
				l_ba as b
			loop
				s.append_character (b.to_character_8)
			end
			Result := {UTF_CONVERTER}.utf_8_string_8_to_string_32 (s)
		end

	bytes_into_string (arr: ITERABLE [NATURAL_8]; str: STRING_8)
		do
			across
				arr as c
			loop
				str.append_code (c)
			end
		end

	set_error (a_message: READABLE_STRING_GENERAL)
		require
			message_not_void: a_message /= Void
		do
			last_error.append_string_general (a_message)
		ensure
			has_error
			last_error_set: last_error.has_substring (a_message)
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
