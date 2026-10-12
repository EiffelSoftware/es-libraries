note
	description: "[
		Portable JPEG decompression wrapper using inline C with stb_image.
		Implements DCTDecode filter per ISO 32000-1:2008 §7.4.9.
	]"
	author: "EiffelPDF"
	date: "$Date$"
	revision: "$Revision$"
	spec_reference: "ISO 32000-1:2008 Section 7.4.9 (DCTDecode Filter)"

class
	JPEG_WRAPPER

feature -- Status

	last_error_code: INTEGER
			-- Error code from last operation (0 = success, negative = error)

	has_error: BOOLEAN
			-- Did the last operation have an error?
		do
			Result := last_error_code < 0
		end

	error_message: STRING_8
			-- Human-readable error message for last operation
		do
			inspect last_error_code
			when 0 then Result := "Success"
			when -1 then Result := "Invalid or corrupt JPEG data"
			when -2 then Result := "Memory allocation failed"
			when -3 then Result := "Image too large"
			when -4 then Result := "Invalid input parameters"
			else Result := "Unknown JPEG error (code " + last_error_code.out + ")"
			end
		ensure
			result_not_empty: not Result.is_empty
		end

feature -- Access

	image_width: INTEGER
			-- Width of last successfully decoded image

	image_height: INTEGER
			-- Height of last successfully decoded image

	image_components: INTEGER
			-- Number of color components (1=grayscale, 3=RGB, 4=RGBA)

feature -- Decompression

	decompress (compressed_data: ARRAY [NATURAL_8]): detachable ARRAY [NATURAL_8]
			-- Decompress JPEG data.
			-- Returns decompressed raw pixel data (RGB or grayscale), or Void if decompression fails.
			-- Check `last_error_code` and `error_message` for failure details.
			-- Check `image_width`, `image_height`, `image_components` for image metadata.
		require
			data_not_empty: compressed_data.count > 0
		local
			l_in_ptr: MANAGED_POINTER
			l_out_ptr: MANAGED_POINTER
			i: INTEGER
			out_size: INTEGER
			max_out_size: INTEGER
			width, height, components: INTEGER
		do
			last_error_code := 0
			image_width := 0
			image_height := 0
			image_components := 0

			if compressed_data.count >= 2 then
					-- Allocate input buffer
				create l_in_ptr.make (compressed_data.count)

					-- Copy input data
				from i := compressed_data.lower until i > compressed_data.upper loop
					l_in_ptr.put_natural_8 (compressed_data [i], i - compressed_data.lower)
					i := i + 1
				end

					-- Estimate output size
					-- JPEG images can decompress to large sizes (width * height * components)
					-- Start with a reasonable estimate, will be resized if needed
				max_out_size := compressed_data.count * 10
				if max_out_size < 1_000_000 then
					max_out_size := 1_000_000  -- At least 1MB
				end
				if max_out_size > 100_000_000 then
					max_out_size := 100_000_000  -- Cap at 100MB
				end
				create l_out_ptr.make (max_out_size)

					-- Decompress JPEG
				out_size := c_jpeg_decompress (
					l_in_ptr.item, compressed_data.count,
					l_out_ptr.item, max_out_size,
					$width, $height, $components
				)

				if out_size > 0 then
						-- Success: create result array and copy data
					image_width := width
					image_height := height
					image_components := components

					create Result.make_filled (0, 1, out_size)
					from i := 1 until i > out_size loop
						Result [i] := l_out_ptr.read_natural_8 (i - 1)
						i := i + 1
					end
				elseif out_size = 0 then
						-- Edge case: zero-length output (unlikely for JPEG)
					create Result.make_filled (0, 1, 0)
				else
						-- Error: negative code
					last_error_code := out_size
					Result := Void
				end
			else
					-- Input too short
				last_error_code := -4  -- Invalid input
				Result := Void
			end
		ensure
			error_state_consistent: (Result = Void) = has_error
			success_means_no_error: (Result /= Void) implies (not has_error)
			success_means_metadata: (Result /= Void) implies (image_width > 0 and image_height > 0)
		end

feature {NONE} -- Inline C: Using external header

	c_jpeg_decompress (ptr_in: POINTER; in_len: INTEGER; 
	                   ptr_out: POINTER; out_max: INTEGER;
	                   width_ptr: POINTER; height_ptr: POINTER; 
	                   components_ptr: POINTER): INTEGER
			-- Decompress JPEG data using stb_image.
			-- Returns: positive = success (output size), negative = error code
		external
			"C inline use %"jpeg_impl.h%""
		alias
			"[
				unsigned char *output = NULL;
				int output_len = 0;
				int width = 0, height = 0, components = 0;
				int result;
				
				result = jpeg_decompress(
					(const unsigned char *)$ptr_in, 
					$in_len,
					&output,
					&output_len,
					&width, 
					&height, 
					&components
				);
				
				if (result == 0 && output != NULL) {
					/* Success - copy to output buffer */
					if (output_len <= $out_max) {
						memcpy($ptr_out, output, output_len);
						*((int*)$width_ptr) = width;
						*((int*)$height_ptr) = height;
						*((int*)$components_ptr) = components;
						jpeg_free(output);
						return output_len;
					} else {
						/* Output buffer too small */
						jpeg_free(output);
						return -3;
					}
				} else {
					/* Error */
					return result;
				}
			]"
		end

end
