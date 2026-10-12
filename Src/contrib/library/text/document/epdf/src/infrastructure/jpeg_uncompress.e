note
	description: "[
		JPEG decompression wrapper compatible with standard interface.
		Wraps JPEG_WRAPPER for use in PDF DCTDecode filter.
	]"
	date: "$Date$"
	revision: "$Revision$"
	spec_reference: "ISO 32000-1:2008 Section 7.4.9 (DCTDecode Filter)"

class
	JPEG_UNCOMPRESS

feature -- Status

	is_last_operation_ok: BOOLEAN
			-- Was the last operation successful?

	has_error_message: BOOLEAN
			-- Is an error message available?
		do
			Result := last_error_message /= Void
		end

feature -- Access

	last_uncompressed_data: detachable STRING_8
			-- Result of last decompression operation.

	last_error_message: detachable STRING_8
			-- Error message from last operation (Void if successful)

	last_error_code: INTEGER
			-- Error code from last operation (0 = success, negative = error)

	image_width: INTEGER
			-- Width of last successfully decoded image

	image_height: INTEGER
			-- Height of last successfully decoded image

	image_components: INTEGER
			-- Number of color components (1=grayscale, 3=RGB)

feature -- Basic Operations

	uncompress_jpeg (compressed_data: STRING_8)
			-- Decompress JPEG compressed data.
			-- Sets `last_uncompressed_data` and `is_last_operation_ok`.
			-- On failure, check `last_error_message` for details.
		require
			data_not_empty: not compressed_data.is_empty
			reasonable_size: compressed_data.count < 100_000_000  -- 100MB limit
		local
			wrapper: JPEG_WRAPPER
			input_array: ARRAY [NATURAL_8]
			output_array: detachable ARRAY [NATURAL_8]
			i: INTEGER
			l_result: STRING_8
		do
				-- Reset state
			last_error_message := Void
			last_error_code := 0
			image_width := 0
			image_height := 0
			image_components := 0

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

				-- Decompress using JPEG_WRAPPER
			create wrapper
			output_array := wrapper.decompress (input_array)

			if output_array /= Void then
					-- Success: Convert ARRAY [NATURAL_8] to STRING_8
				image_width := wrapper.image_width
				image_height := wrapper.image_height
				image_components := wrapper.image_components

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
					last_uncompressed_data := l_result
				else
						-- Zero-length output (rare but valid)
					create l_result.make_empty
					last_uncompressed_data := l_result
				end
				is_last_operation_ok := True
			else
					-- Failure: Capture error details
				last_uncompressed_data := Void
				is_last_operation_ok := False
				last_error_code := wrapper.last_error_code
				last_error_message := wrapper.error_message.twin + 
					" (input size: " + compressed_data.count.out + " bytes)"
			end
		ensure
			success_implies_result: is_last_operation_ok implies last_uncompressed_data /= Void
			failure_implies_error: not is_last_operation_ok implies has_error_message
			error_code_consistent: not is_last_operation_ok implies last_error_code < 0
			success_implies_metadata: is_last_operation_ok implies (image_width > 0 and image_height > 0)
		end

end
