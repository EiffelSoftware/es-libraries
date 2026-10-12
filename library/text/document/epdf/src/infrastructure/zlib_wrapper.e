note
	description: "Portable zlib/DEFLATE compression wrapper using inline C with external header."
	author: "EiffelPDF"
	date: "2025-12-13"
	revision: "2025-12-26 - Added error reporting"

class
	ZLIB_WRAPPER

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
			when -1 then Result := "Output buffer too small"
			when -2 then Result := "Corrupt or invalid compressed data"
			when -3 then Result := "Invalid ZLIB header or unsupported format"
			when -4 then Result := "Invalid block type or structure"
			when -5 then Result := "Insufficient input data"
			when 0 then Result := "Success"
			else Result := "Unknown error (code " + last_error_code.out + ")"
			end
		ensure
			result_not_empty: not Result.is_empty
		end

feature -- Compression Detection

	is_zlib_compressed (data: ARRAY [NATURAL_8]): BOOLEAN
			-- Check if data appears to be zlib/deflate compressed.
			-- Zlib header: first byte usually 0x78 (CMF), second byte varies.
		do
			if data.count >= 2 then
					-- Common zlib headers: 78 01, 78 5E, 78 9C, 78 DA
				Result := data.item (data.lower) = 0x78
			end
		end

feature -- Decompression

	inflate (compressed_data: ARRAY [NATURAL_8]): detachable ARRAY [NATURAL_8]
			-- Decompress zlib/deflate data.
			-- Supports stored blocks, fixed Huffman, and dynamic Huffman.
			-- Returns decompressed data, or Void if decompression fails.
			-- Check `last_error_code` and `error_message` for failure details.
		require
			data_not_empty: compressed_data.count > 0
		local
			l_in_ptr: MANAGED_POINTER
			l_out_ptr: MANAGED_POINTER
			i: INTEGER
			out_size: INTEGER
			max_out_size: INTEGER
		do
			last_error_code := 0
			
			if compressed_data.count >= 2 then
					-- Allocate buffers
				create l_in_ptr.make (compressed_data.count)

					-- Estimate output size (compressed data can expand significantly)
					-- PDF XRef streams can have high expansion ratios (observed >20x)
					-- Use generous buffer to avoid ZLIB_ERR_BUFFER (-1)
				max_out_size := compressed_data.count * 100
				if max_out_size < 65536 then
					max_out_size := 65536
				end
				create l_out_ptr.make (max_out_size)

					-- Copy input data
				from i := compressed_data.lower until i > compressed_data.upper loop
					l_in_ptr.put_natural_8 (compressed_data [i], i - compressed_data.lower)
					i := i + 1
				end

					-- Decompress using full DEFLATE implementation
					-- Returns: positive = success (size), negative = error code
				out_size := c_inflate (l_in_ptr.item, compressed_data.count,
				                       l_out_ptr.item, max_out_size)

				if out_size > 0 then
						-- Success: create result array
					create Result.make_filled (0, 1, out_size)
					from i := 1 until i > out_size loop
						Result [i] := l_out_ptr.read_natural_8 (i - 1)
						i := i + 1
					end
				elseif out_size = 0 then
						-- Edge case: zero-length output (valid but rare)
					create Result.make_filled (0, 1, 0)
				else
						-- Error: negative code
					last_error_code := out_size
					Result := Void
				end
			else
					-- Input too short
				last_error_code := -5  -- Insufficient input
				Result := Void
			end
		ensure
			error_state_consistent: (Result = Void) = has_error
			success_means_no_error: (Result /= Void) implies (not has_error)
		end

feature -- Compression

	deflate (data: ARRAY [NATURAL_8]): detachable ARRAY [NATURAL_8]
			-- Compress data using zlib/deflate (stored blocks).
			-- Returns compressed data with valid zlib format.
		local
			l_in_ptr: MANAGED_POINTER
			l_out_ptr: MANAGED_POINTER
			i: INTEGER
			out_size: INTEGER
			max_out_size: INTEGER
		do
			if data.count > 0 then
					-- Allocate buffers
				create l_in_ptr.make (data.count)

					-- Output buffer for stored blocks (slightly larger than input)
				max_out_size := data.count + data.count // 100 + 256
				create l_out_ptr.make (max_out_size)

					-- Copy input data
				from i := data.lower until i > data.upper loop
					l_in_ptr.put_natural_8 (data [i], i - data.lower)
					i := i + 1
				end

					-- Compress using stored blocks
				out_size := c_deflate (l_in_ptr.item, data.count,
				                       l_out_ptr.item, max_out_size)

				if out_size > 0 then
					create Result.make_filled (0, 1, out_size)
					from i := 1 until i > out_size loop
						Result [i] := l_out_ptr.read_natural_8 (i - 1)
						i := i + 1
					end
				end
			end
		end

feature {NONE} -- Inline C: Using external header

	c_inflate (ptr_in: POINTER; in_len: INTEGER; ptr_out: POINTER; out_max: INTEGER): INTEGER
			-- Decompress zlib/deflate data using full DEFLATE implementation.
		external
			"C inline use %"zlib_impl.h%""
		alias
			"[
				return zlib_inflate(
					(const unsigned char *)$ptr_in, 
					$in_len,
					(unsigned char *)$ptr_out, 
					$out_max
				);
			]"
		end

	c_deflate (ptr_in: POINTER; in_len: INTEGER; ptr_out: POINTER; out_max: INTEGER): INTEGER
			-- Compress data to zlib format using stored blocks.
		external
			"C inline use %"zlib_impl.h%""
		alias
			"[
				return zlib_deflate_stored(
					(const unsigned char *)$ptr_in, 
					$in_len,
					(unsigned char *)$ptr_out, 
					$out_max
				);
			]"
		end

end
