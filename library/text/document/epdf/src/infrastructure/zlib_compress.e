note
	description: "[
		ZLIB compression wrapper compatible with standard ZLIB_COMPRESS interface.
		Wraps ZLIB_WRAPPER for use in PDF tests and compression operations.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	ZLIB_COMPRESS

feature -- Status

	is_last_operation_ok: BOOLEAN
			-- Was the last operation successful?

feature -- Access

	last_compressed_string: detachable STRING_8
			-- Result of last compression operation.

feature -- Basic Operations

	compress_string (uncompressed_data: STRING_8)
			-- Compress string using zlib/deflate.
			-- Sets `last_compressed_string` and `is_last_operation_ok`.
		require
			data_not_empty: not uncompressed_data.is_empty
		local
			wrapper: ZLIB_WRAPPER
			input_array: ARRAY [NATURAL_8]
			output_array: detachable ARRAY [NATURAL_8]
			i: INTEGER
			l_result: STRING_8
		do
				-- Convert STRING_8 to ARRAY [NATURAL_8]
			create input_array.make_filled (0, 1, uncompressed_data.count)
			from
				i := 1
			until
				i > uncompressed_data.count
			loop
				input_array [i] := uncompressed_data [i].natural_32_code.to_natural_8
				i := i + 1
			end
			
				-- Compress using ZLIB_WRAPPER
			create wrapper
			output_array := wrapper.deflate (input_array)
			
			if output_array /= Void and then output_array.count > 0 then
					-- Convert ARRAY [NATURAL_8] to STRING_8 using local variable (CAP-compliant)
				create l_result.make (output_array.count)
				from
					i := 1
				until
					i > output_array.count
				loop
					l_result.append_character (output_array [i].to_character_8)
					i := i + 1
				end
				last_compressed_string := l_result
				is_last_operation_ok := True
			else
				last_compressed_string := Void
				is_last_operation_ok := False
			end
		ensure
			success_implies_result: is_last_operation_ok implies last_compressed_string /= Void
		end

end
