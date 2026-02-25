note
	description: "[
		BSON_WRITER generates binary BSON data from BSON_VALUE objects.
		
		BSON format uses little-endian byte order for all multi-byte values.
		
		Usage:
			create writer.make
			binary_data := writer.to_bytes (document)
	]"
	date: "$Date$"
	revision: "$Revision$"
	EIS: "name=BSON Specification", "protocol=URI", "src=https://bsonspec.org/spec.html"

deferred class
	BSON_WRITER

inherit
	BSON_CONSTANTS

	BSON_VISITOR
	
feature {NONE} -- Implementation

	current_key: detachable STRING_32
			-- Current key being written (for elements).

feature {NONE} -- Writing primitives

	write_character_8_sequences (ch_arr: ITERABLE [CHARACTER_8])
		do
			across
				ch_arr as ch
			loop
				write_byte (ch.code.to_natural_8)
			end
		end

	write_byte (b: NATURAL_8)
			-- Write a single byte.
		deferred
		end

	write_int32 (v: INTEGER_32)
			-- Write a 32-bit integer in little-endian.
		do
			write_byte ((v & 0xFF).to_natural_8)
			write_byte (((v |>> 8) & 0xFF).to_natural_8)
			write_byte (((v |>> 16) & 0xFF).to_natural_8)
			write_byte (((v |>> 24) & 0xFF).to_natural_8)
		end

	write_int64 (v: INTEGER_64)
			-- Write a 64-bit integer in little-endian.
		do
			write_int32 ((v & 0xFFFFFFFF).to_integer_32)
			write_int32 (((v |>> 32) & 0xFFFFFFFF).to_integer_32)
		end

	write_uint64 (v: NATURAL_64)
			-- Write a 64-bit unsigned integer in little-endian.
		do
			write_int32 ((v & 0xFFFFFFFF).to_integer_32)
			write_int32 (((v |>> 32) & 0xFFFFFFFF).to_integer_32)
		end

	write_double (v: REAL_64)
			-- Write a 64-bit IEEE 754 double in little-endian.
		local
			l_mp: MANAGED_POINTER
		do
			create l_mp.make (8)
			l_mp.put_real_64_le (v, 0)
			write_uint64 (l_mp.read_natural_64_le (0))
		end

	write_cstring (s: READABLE_STRING_GENERAL)
			-- Write a null-terminated UTF-8 C string.
		local
			l_utf8: STRING_8
			i: INTEGER
		do
			l_utf8 := {UTF_CONVERTER}.utf_32_string_to_utf_8_string_8 (s)
			from
				i := 1
			until
				i > l_utf8.count
			loop
				write_byte (l_utf8[i].code.to_natural_8)
				i := i + 1
			end
			write_byte (0)
		end

	write_string (s: READABLE_STRING_GENERAL)
			-- Write a BSON string (length-prefixed UTF-8 with null terminator).
		local
			l_utf8: STRING_8
			i: INTEGER
		do
			l_utf8 := {UTF_CONVERTER}.utf_32_string_to_utf_8_string_8 (s)
			write_int32 (l_utf8.count + 1) -- +1 for null terminator
--			write_character_8_sequences (l_utf8.area)
			from
				i := 1
			until
				i > l_utf8.count
			loop
				write_byte (l_utf8[i].code.to_natural_8)
				i := i + 1
			end
			write_byte (0)
		end

feature {NONE} -- Document writing

	write_document (a_doc: BSON_DOCUMENT)
			-- Write a BSON document.
		deferred
		end

	write_array (a_array: BSON_ARRAY)
			-- Write a BSON array as a document with numeric keys.
		deferred
		end

	write_element (a_key: READABLE_STRING_GENERAL; a_value: BSON_VALUE)
			-- Write a BSON element (type + key + value).
		do
			write_byte (a_value.bson_type.to_natural_8)
			write_cstring (a_key)
			current_key := a_key.to_string_32
			a_value.accept (Current)
			current_key := Void
		end

feature -- Visitor implementation

	visit_bson_document (a_document: BSON_DOCUMENT)
			-- Write embedded document.
		do
			write_document (a_document)
		end

	visit_bson_array (an_array: BSON_ARRAY)
			-- Write array.
		do
			write_array (an_array)
		end

	visit_bson_string (a_string: BSON_STRING)
			-- Write string.
		do
			write_string (a_string.value)
		end

	visit_bson_double (a_double: BSON_DOUBLE)
			-- Write double.
		do
			write_double (a_double.value)
		end

	visit_bson_int32 (an_int32: BSON_INT32)
			-- Write int32.
		do
			write_int32 (an_int32.value)
		end

	visit_bson_int64 (an_int64: BSON_INT64)
			-- Write int64.
		do
			write_int64 (an_int64.value)
		end

	visit_bson_boolean (a_boolean: BSON_BOOLEAN)
			-- Write boolean.
		do
			if a_boolean.value then
				write_byte (1)
			else
				write_byte (0)
			end
		end

	visit_bson_null (a_null: BSON_NULL)
			-- Write null (no data).
		do
			-- Null has no data, only the type code
		end

	visit_bson_binary (a_binary: BSON_BINARY)
			-- Write binary data.
		local
			i: INTEGER
		do
			write_int32 (a_binary.count)
			write_byte (a_binary.subtype)
			from
				i := a_binary.data.lower
			until
				i > a_binary.data.upper
			loop
				write_byte (a_binary.data [i])
				i := i + 1
			end
		end

	visit_bson_object_id (an_object_id: BSON_OBJECT_ID)
			-- Write ObjectId (12 bytes).
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > 12
			loop
				write_byte (an_object_id.bytes [i])
				i := i + 1
			end
		end

	visit_bson_datetime (a_datetime: BSON_DATETIME)
			-- Write datetime.
		do
			write_int64 (a_datetime.milliseconds)
		end

	visit_bson_timestamp (a_timestamp: BSON_TIMESTAMP)
			-- Write timestamp.
		do
			write_uint64 (a_timestamp.to_raw)
		end

	visit_bson_regex (a_regex: BSON_REGEX)
			-- Write regex.
		do
			write_cstring (a_regex.pattern)
			write_cstring (a_regex.options)
		end

	visit_bson_javascript (a_javascript: BSON_JAVASCRIPT)
			-- Write JavaScript code.
		do
			write_string (a_javascript.code)
		end

	visit_bson_min_key (a_min_key: BSON_MIN_KEY)
			-- Write min key (no data).
		do
			-- MinKey has no data, only the type code
		end

	visit_bson_max_key (a_max_key: BSON_MAX_KEY)
			-- Write max key (no data).
		do
			-- MaxKey has no data, only the type code
		end

note
	copyright: "2026, Jocelyn Fiat and Eiffel Software"
	license: "MIT License"
end
