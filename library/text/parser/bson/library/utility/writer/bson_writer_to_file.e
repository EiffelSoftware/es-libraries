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

class
	BSON_WRITER_TO_FILE

inherit
	BSON_WRITER
		redefine
			write_cstring,
			write_string
		end

create
	make

feature {NONE} -- Initialization

	make (f: RAW_FILE)
			-- Initialize writer.
		do
			output := f
		end

feature {NONE} -- Implementation

	output: RAW_FILE
			-- Output file.

feature {NONE} -- Writing primitives

	write_byte (b: NATURAL_8)
			-- Write a single byte.
		do
			output.extend (b.to_character_8)
		end

feature {NONE} -- Document writing

	write_document (a_doc: BSON_DOCUMENT)
			-- Write a BSON document.
		local
			l_start: INTEGER
			l_curr: INTEGER
			l_size: INTEGER_32
		do
			l_start := output.position + 1
			write_int32 (0) -- Placeholder for size

			across a_doc as c loop
				write_element (@c.key, c)
			end

			write_byte (0) -- Document terminator
			l_size := (output.position - l_start + 1).to_integer_32
			-- Patch the size
			l_curr := output.position
			output.go (l_start)
			write_byte ((l_size & 0xFF).to_natural_8)
			write_byte (((l_size |>> 8) & 0xFF).to_natural_8)
			write_byte (((l_size |>> 16) & 0xFF).to_natural_8)
			write_byte (((l_size |>> 24) & 0xFF).to_natural_8)
			output.go (l_curr)
		end

	write_array (a_array: BSON_ARRAY)
			-- Write a BSON array as a document with numeric keys.
		local
			l_start: INTEGER
			l_curr: INTEGER
			l_size: INTEGER_32
			l_index: INTEGER
		do
			l_start := output.position + 1
			write_int32 (0) -- Placeholder for size

			from
				l_index := 0
			until
				l_index >= a_array.count
			loop
				write_element (l_index.out, a_array [l_index + 1])
				l_index := l_index + 1
			end

			write_byte (0) -- Document terminator

			l_size := (output.position - l_start + 1).to_integer_32

			-- Patch the size
			l_curr := output.position
			output.go (l_start)
			write_byte ((l_size & 0xFF).to_natural_8)
			write_byte (((l_size |>> 8) & 0xFF).to_natural_8)
			write_byte (((l_size |>> 16) & 0xFF).to_natural_8)
			write_byte (((l_size |>> 24) & 0xFF).to_natural_8)
			output.go (l_curr)
		end

	write_cstring (s: READABLE_STRING_GENERAL)
			-- Write a null-terminated UTF-8 C string.
		local
			l_utf8: STRING_8
		do
			l_utf8 := {UTF_CONVERTER}.utf_32_string_to_utf_8_string_8 (s)
			output.put_string (l_utf8)
			write_byte (0)
		end

	write_string (s: READABLE_STRING_GENERAL)
			-- Write a BSON string (length-prefixed UTF-8 with null terminator).
		local
			l_utf8: STRING_8
		do
			l_utf8 := {UTF_CONVERTER}.utf_32_string_to_utf_8_string_8 (s)
			write_int32 (l_utf8.count + 1) -- +1 for null terminator
			output.put_string (l_utf8)
			write_byte (0)
		end

note
	copyright: "2026, Jocelyn Fiat and Eiffel Software"
	license: "MIT License"
end
