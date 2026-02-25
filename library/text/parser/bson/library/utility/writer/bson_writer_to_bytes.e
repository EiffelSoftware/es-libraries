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
	BSON_WRITER_TO_BYTES

inherit
	BSON_WRITER

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize writer.
		do
			create buffer.make (256)
		end

feature -- Conversion

	to_pointer (a_document: BSON_DOCUMENT): POINTER
			-- Convert document to binary BSON.
		require
			a_document_not_void: a_document /= Void
		local
			mp: MANAGED_POINTER
			arr: ARRAY [NATURAL_8]
		do
			buffer.wipe_out
			visit_bson_document (a_document)
			arr := buffer.to_array
			create mp.make_from_array (arr)
			Result := mp.item
		ensure
			result_not_void: Result /= Void
		end

	to_bytes (a_document: BSON_DOCUMENT): ARRAY [NATURAL_8]
			-- Convert document to binary BSON.
		require
			a_document_not_void: a_document /= Void
		do
			buffer.wipe_out
			visit_bson_document (a_document)
			Result := buffer.to_array
		ensure
			result_not_void: Result /= Void
		end

	to_string (a_document: BSON_DOCUMENT): STRING_8
			-- Convert document to raw string (each byte as character).
		require
			a_document_not_void: a_document /= Void
		local
			l_bytes: ARRAY [NATURAL_8]
			i: INTEGER
		do
			l_bytes := to_bytes (a_document)
			create Result.make (l_bytes.count)
			from
				i := l_bytes.lower
			until
				i > l_bytes.upper
			loop
				Result.append_code (l_bytes [i])
				i := i + 1
			end
		ensure
			result_not_void: Result /= Void
		end

feature {NONE} -- Implementation

	buffer: ARRAYED_LIST [NATURAL_8]
			-- Output buffer.

feature {NONE} -- Writing primitives

	write_byte (b: NATURAL_8)
			-- Write a single byte.
		do
			buffer.extend (b)
		end

feature {NONE} -- Document writing

	write_document (a_doc: BSON_DOCUMENT)
			-- Write a BSON document.
		local
			l_start: INTEGER
			l_size: INTEGER_32
		do
			l_start := buffer.count + 1
			write_int32 (0) -- Placeholder for size

			across a_doc as c loop
				write_element (@c.key, c)
			end

			write_byte (0) -- Document terminator

			l_size := (buffer.count - l_start + 1).to_integer_32
			-- Patch the size
			buffer [l_start] := (l_size & 0xFF).to_natural_8
			buffer [l_start + 1] := ((l_size |>> 8) & 0xFF).to_natural_8
			buffer [l_start + 2] := ((l_size |>> 16) & 0xFF).to_natural_8
			buffer [l_start + 3] := ((l_size |>> 24) & 0xFF).to_natural_8
		end

	write_array (a_array: BSON_ARRAY)
			-- Write a BSON array as a document with numeric keys.
		local
			l_start: INTEGER
			l_size: INTEGER_32
			l_index: INTEGER
		do
			l_start := buffer.count + 1
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

			l_size := (buffer.count - l_start + 1).to_integer_32
			-- Patch the size
			buffer [l_start] := (l_size & 0xFF).to_natural_8
			buffer [l_start + 1] := ((l_size |>> 8) & 0xFF).to_natural_8
			buffer [l_start + 2] := ((l_size |>> 16) & 0xFF).to_natural_8
			buffer [l_start + 3] := ((l_size |>> 24) & 0xFF).to_natural_8
		end

note
	copyright: "2026, Jocelyn Fiat and Eiffel Software"
	license: "MIT License"
end
