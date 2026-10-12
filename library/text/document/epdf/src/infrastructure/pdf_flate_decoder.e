note
	description: "[
		FlateDecode filter implementation for PDF streams.
		Implements zlib/DEFLATE decompression per ISO 32000-1:2008 §7.4.4.
	]"
	spec_reference: "ISO 32000-1:2008 Section 7.4.4 (LZWDecode and FlateDecode Filters)"
	date: "$Date$"
	revision: "2025-12-26 - Added PNG predictors 3,4 and error reporting"

class
	PDF_FLATE_DECODER

create
	make

feature -- Initialization

	make
			-- Create a new FlateDecode decoder.
		do
			-- Nothing to initialize
		end

feature -- Status

	last_error_message: detachable STRING_8
			-- Error message from last decode operation (Void if successful)

	has_error_message: BOOLEAN
			-- Is an error message available?
		do
			Result := last_error_message /= Void
		end

feature -- Basic Operations

	decode (compressed_data: STRING_8): detachable STRING_8
			-- Decode FlateDecode compressed data.
			-- Returns Void if decompression fails.
			-- Check `last_error_message` for failure details.
		require
			data_not_empty: not compressed_data.is_empty
			reasonable_size: compressed_data.count < 100_000_000  -- 100MB limit
		local
			decompressor: ZLIB_UNCOMPRESS
		do
			last_error_message := Void
			
			create decompressor
			decompressor.uncompress_string (compressed_data)
			if decompressor.is_last_operation_ok then
				Result := decompressor.last_uncompressed_string
			else
					-- Capture error details
				Result := Void
				if attached decompressor.last_error_message as err then
					last_error_message := err.twin
				else
					last_error_message := "ZLIB decompression failed (unknown reason)"
				end
			end
		ensure
			failure_means_error: (Result = Void) implies has_error_message
		end

	decode_with_predictor (compressed_data: STRING_8; predictor: INTEGER; columns: INTEGER): detachable STRING_8
			-- Decode FlateDecode compressed data with PNG predictor.
			-- Predictor values per ISO 32000-1:2008 Table 8:
			--   1 = No prediction
			--   2 = TIFF Predictor 2
			--   10-15 = PNG predictors (10=None, 11=Sub, 12=Up, 13=Average, 14=Paeth, 15=Optimum)
			-- Returns Void if decompression fails.
		require
			data_not_empty: not compressed_data.is_empty
			valid_predictor: predictor >= 1 and predictor <= 15
			valid_columns: columns > 0
		local
			decompressed: detachable STRING_8
		do
			decompressed := decode (compressed_data)

			if decompressed /= Void then
					-- Successfully decompressed, now apply predictor if needed
				if predictor = 1 then
						-- No prediction
					Result := decompressed
				elseif predictor = 2 then
						-- TIFF Predictor 2 (treat as no prediction for now)
					Result := decompressed
				elseif predictor >= 10 and predictor <= 15 then
						-- PNG predictor (supports all 5 types)
					Result := decode_png_predictor (decompressed, columns)
				else
						-- Invalid predictor value
					Result := Void
					last_error_message := "Unsupported predictor value: " + predictor.out
				end
			else
					-- Decompression failed - error already set by decode()
				Result := Void
			end
		ensure
			failure_means_error: (Result = Void) implies has_error_message
		end

feature {NONE} -- Implementation

	decode_png_predictor (data: STRING_8; columns: INTEGER): STRING_8
			-- Decode PNG predictor from decompressed data.
			-- Each row starts with a predictor byte (algorithm selector).
			-- Supports all 5 PNG predictor types (0=None, 1=Sub, 2=Up, 3=Average, 4=Paeth).
		require
			data_not_empty: not data.is_empty
			valid_columns: columns > 0
		local
			row_size: INTEGER
			num_rows: INTEGER
			i, j: INTEGER
			predictor_byte: NATURAL_8
			current_byte, left_byte, up_byte, up_left_byte: NATURAL_8
			pos: INTEGER
			a, b, c: INTEGER  -- For Paeth predictor
			p, pa, pb, pc: INTEGER
		do
			row_size := columns + 1  -- +1 for predictor byte
			num_rows := data.count // row_size
			
			create Result.make (num_rows * columns)
			
			from
				i := 0
			until
				i >= num_rows
			loop
				pos := i * row_size + 1
				predictor_byte := data [pos].natural_32_code.to_natural_8
				
				from
					j := 1
				until
					j > columns
				loop
					current_byte := data [pos + j].natural_32_code.to_natural_8
					
					inspect predictor_byte
					when 0 then
							-- None: no operation
						Result.append_character (current_byte.to_character_8)
					when 1 then
							-- Sub: add left byte
						if j > 1 then
							left_byte := Result [Result.count].natural_32_code.to_natural_8
							current_byte := (current_byte + left_byte).to_natural_8
						end
						Result.append_character (current_byte.to_character_8)
					when 2 then
							-- Up: add upper byte
						if i > 0 then
							up_byte := Result [(i - 1) * columns + j].natural_32_code.to_natural_8
							current_byte := (current_byte + up_byte).to_natural_8
						end
						Result.append_character (current_byte.to_character_8)
					when 3 then
							-- Average: add average of left and up
						left_byte := 0
						up_byte := 0
						if j > 1 then
							left_byte := Result [Result.count].natural_32_code.to_natural_8
						end
						if i > 0 then
							up_byte := Result [(i - 1) * columns + j].natural_32_code.to_natural_8
						end
						current_byte := (current_byte + ((left_byte.to_integer_32 + up_byte.to_integer_32) // 2).to_natural_8).to_natural_8
						Result.append_character (current_byte.to_character_8)
					when 4 then
							-- Paeth: complex predictor
						left_byte := 0
						up_byte := 0
						up_left_byte := 0
						if j > 1 then
							left_byte := Result [Result.count].natural_32_code.to_natural_8
						end
						if i > 0 then
							up_byte := Result [(i - 1) * columns + j].natural_32_code.to_natural_8
							if j > 1 then
								up_left_byte := Result [(i - 1) * columns + j - 1].natural_32_code.to_natural_8
							end
						end
						
							-- Paeth algorithm (per PNG specification)
						a := left_byte.to_integer_32
						b := up_byte.to_integer_32
						c := up_left_byte.to_integer_32
						p := a + b - c
						pa := (p - a).abs
						pb := (p - b).abs
						pc := (p - c).abs
						
						if pa <= pb and pa <= pc then
							current_byte := (current_byte + a.to_natural_8).to_natural_8
						elseif pb <= pc then
							current_byte := (current_byte + b.to_natural_8).to_natural_8
						else
							current_byte := (current_byte + c.to_natural_8).to_natural_8
						end
						Result.append_character (current_byte.to_character_8)
					else
							-- Invalid predictor type
						check valid_png_predictor: False then
								-- This should never happen if data is valid
							Result.append_character (current_byte.to_character_8)
						end
					end
					
					j := j + 1
				end
				
				i := i + 1
			end
		ensure
			result_not_void: Result /= Void
		end

end
