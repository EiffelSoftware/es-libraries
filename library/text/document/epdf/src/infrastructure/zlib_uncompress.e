note
	description: "[
		ZLIB decompression wrapper compatible with standard ZLIB_UNCOMPRESS interface.
		Wraps ZLIB_WRAPPER for use in PDF FlateDecode filter.
	]"
	date: "$Date$"
	revision: "2025-12-26 - Added error reporting"

class
	ZLIB_UNCOMPRESS

feature -- Status

	is_last_operation_ok: BOOLEAN
			-- Was the last operation successful?

	has_error_message: BOOLEAN
			-- Is an error message available?
		do
			Result := last_error_message /= Void
		end

feature -- Access

	last_uncompressed_string: detachable STRING_8
			-- Result of last decompression operation.

	last_error_message: detachable STRING_8
			-- Error message from last operation (Void if successful)

	last_error_code: INTEGER
			-- Error code from last operation (0 = success, negative = error)

feature -- Basic Operations

	uncompress_string (compressed_data: STRING_8)
			-- Uncompress zlib/deflate compressed string.
			-- Sets `last_uncompressed_string` and `is_last_operation_ok`.
			-- On failure, check `last_error_message` for details.
		require
			data_not_empty: not compressed_data.is_empty
			reasonable_size: compressed_data.count < 100_000_000  -- 100MB limit
		local
			wrapper: ZLIB_WRAPPER
			input_array: ARRAY [NATURAL_8]
			output_array: detachable ARRAY [NATURAL_8]
			i: INTEGER
			l_result: STRING_8
		do
				-- Reset error state
			last_error_message := Void
			last_error_code := 0
			
				-- Convert STRING_8 to ARRAY [NATURAL_8]
			create input_array.make_filled (0, 1, compressed_data.count)
			from
				i := 1
			until
				i > compressed_data.count
			loop
				input_array [i] := compressed_data [i].natural_32_code.to_natural_8
				i := i + 1
			end
			
				-- Decompress using ZLIB_WRAPPER
			create wrapper
			output_array := wrapper.inflate (input_array)
			
			if output_array /= Void then
					-- Success: Convert ARRAY [NATURAL_8] to STRING_8
				if output_array.count > 0 then
					create l_result.make (output_array.count)
					from
						i := 1
					until
						i > output_array.count
					loop
						l_result.append_character (output_array [i].to_character_8)
						i := i + 1
					end
					last_uncompressed_string := l_result
				else
						-- Zero-length output (valid but rare)
					create l_result.make_empty
					last_uncompressed_string := l_result
				end
				is_last_operation_ok := True
			else
					-- Failure: Capture error details
				last_uncompressed_string := Void
				is_last_operation_ok := False
				last_error_code := wrapper.last_error_code
				last_error_message := wrapper.error_message.twin + " (input size: " + compressed_data.count.out + " bytes)"
			end
		ensure
			success_implies_result: is_last_operation_ok implies last_uncompressed_string /= Void
			failure_implies_error: not is_last_operation_ok implies has_error_message
			error_code_consistent: not is_last_operation_ok implies last_error_code < 0
		end

end
