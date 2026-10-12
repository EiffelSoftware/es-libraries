note
	description: "[
		LZWDecode filter implementation for PDF streams.
		Implements LZW (Lempel-Ziv-Welch) decompression per ISO 32000-1:2008 §7.4.4.
		
		LZW Algorithm Details:
		- Variable-length codes from 9 to 12 bits
		- Code 256 = Clear-Table marker (resets dictionary)
		- Code 257 = End-Of-Data marker
		- Initial table contains entries 0-255 (single bytes) plus 256, 257
		- First code after clear-table is always 9 bits
		- Code length increases after table entry 511 (10 bits), 1023 (11 bits), 2047 (12 bits)
		- Maximum 4095 entries (code 4095 is last entry)
		
		Codes are packed high-order bit first into bytes.
	]"
	spec_reference: "ISO 32000-1:2008 §7.4.4.2 (Details of LZW Encoding)"
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_LZW_DECODER

create
	make

feature -- Initialization

	make
			-- Create a new LZWDecode decoder.
		do
			early_change := 1  -- Default per PDF spec
			create table.make_filled (create {STRING_8}.make_empty, 0, Max_table_size - 1)
			initialize_table
		ensure
			early_change_default: early_change = 1
		end

feature -- Access

	early_change: INTEGER
			-- When to increase code length.
			-- 0 = increase after creating entry that makes table overflow current code length
			-- 1 = increase one code early (default, standard PDF behavior)

feature -- Status

	last_error_message: detachable STRING_8
			-- Error message from last decode operation (Void if successful)

	has_error_message: BOOLEAN
			-- Is an error message available?
		do
			Result := last_error_message /= Void
		end

feature -- Element Change

	set_early_change (a_value: INTEGER)
			-- Set `early_change` parameter.
		require
			valid_value: a_value = 0 or a_value = 1
		do
			early_change := a_value
		ensure
			early_change_set: early_change = a_value
		end

feature -- Basic Operations

	decode (a_data: STRING_8): detachable STRING_8
			-- Decode LZW-encoded data to bytes.
			-- Returns Void if decompression fails.
			-- Check `last_error_message` for failure details.
		require
			data_not_empty: not a_data.is_empty
		do
			Result := decode_lzw (a_data)
		ensure
			failure_means_error: (Result = Void) implies has_error_message
		end

	decode_with_predictor (a_data: STRING_8; predictor: INTEGER; columns: INTEGER): detachable STRING_8
			-- Decode LZW-encoded data with predictor.
			-- Predictor values per ISO 32000-1:2008 Table 8:
			--   1 = No prediction
			--   2 = TIFF Predictor 2
			--   10-15 = PNG predictors (10=None, 11=Sub, 12=Up, 13=Average, 14=Paeth, 15=Optimum)
			-- Returns Void if decompression fails.
		require
			data_not_empty: not a_data.is_empty
			valid_predictor: predictor >= 1 and predictor <= 15
			valid_columns: columns > 0
		local
			decompressed: detachable STRING_8
		do
			decompressed := decode_lzw (a_data)

			if decompressed /= Void then
					-- Successfully decompressed, now apply predictor if needed
				if predictor = 1 then
						-- No prediction
					Result := decompressed
				elseif predictor = 2 then
						-- TIFF Predictor 2
					Result := decode_tiff_predictor (decompressed, columns)
				elseif predictor >= 10 and predictor <= 15 then
						-- PNG predictor (supports all 5 types)
					Result := decode_png_predictor (decompressed, columns)
				else
						-- Invalid predictor value
					Result := Void
					last_error_message := "Unsupported predictor value: " + predictor.out
				end
			else
					-- Decompression failed - error already set by decode_lzw
				Result := Void
			end
		ensure
			failure_means_error: (Result = Void) implies has_error_message
		end

feature {NONE} -- LZW Implementation

	decode_lzw (a_data: STRING_8): detachable STRING_8
			-- Core LZW decompression algorithm.
		local
			bit_pos: INTEGER  -- Current bit position in input
			code: INTEGER
			prev_code: INTEGER
			code_length: INTEGER
			next_code: INTEGER
			first_char: CHARACTER_8
			new_sequence: STRING_8
			finished: BOOLEAN
		do
			last_error_message := Void
			create Result.make (a_data.count * 2)  -- Estimate output size

			initialize_table
			code_length := 9
			next_code := First_code
			bit_pos := 0
			prev_code := -1

			from
				finished := False
			until
				finished
			loop
				code := read_code (a_data, bit_pos, code_length)
				bit_pos := bit_pos + code_length

				if code < 0 then
						-- No more data
					finished := True
				elseif code = Clear_table_code then
						-- Reset table
					initialize_table
					code_length := 9
					next_code := First_code
					prev_code := -1
				elseif code = Eod_code then
						-- End of data
					finished := True
				elseif prev_code = -1 then
					-- First code after clear-table
					if code < 256 and then attached Result as res then
						res.append_character (code.to_character_8)
						prev_code := code
					else
						last_error_message := "Invalid first code after clear-table: " + code.out
						Result := Void
						finished := True
					end
				else
						-- Normal code processing
					if attached Result as res then
						if code < next_code then
								-- Code is in table
							if attached table [code] as seq and then not seq.is_empty then
								res.append (seq)
								first_char := seq.item (1)

									-- Add new sequence to table
								if next_code < Max_table_size then
									if attached table [prev_code] as prev_seq then
										create new_sequence.make (prev_seq.count + 1)
										new_sequence.append (prev_seq)
										new_sequence.append_character (first_char)
										table [next_code] := new_sequence
										next_code := next_code + 1

											-- Check if we need to increase code length
										code_length := updated_code_length (next_code, code_length)
									end
								end
							else
								last_error_message := "Invalid code reference: " + code.out
								Result := Void
								finished := True
							end
						elseif code = next_code then
								-- Special case: code not yet in table
								-- Sequence is prev_sequence + first_char_of_prev_sequence
							if attached table [prev_code] as prev_seq and then not prev_seq.is_empty then
								first_char := prev_seq.item (1)
								create new_sequence.make (prev_seq.count + 1)
								new_sequence.append (prev_seq)
								new_sequence.append_character (first_char)

								res.append (new_sequence)

									-- Add to table
								if next_code < Max_table_size then
									table [next_code] := new_sequence
									next_code := next_code + 1

										-- Check if we need to increase code length
									code_length := updated_code_length (next_code, code_length)
								end
							else
								last_error_message := "Invalid prev_code reference: " + prev_code.out
								Result := Void
								finished := True
							end
						else
							last_error_message := "Code out of range: " + code.out + " (next_code=" + next_code.out + ")"
							Result := Void
							finished := True
						end

						prev_code := code
					end
				end
			end
		end

	read_code (a_data: STRING_8; bit_pos: INTEGER; code_length: INTEGER): INTEGER
			-- Read a code of `code_length` bits starting at `bit_pos`.
			-- Returns -1 if not enough data available.
			-- Codes are packed high-order bit first.
		local
			byte_pos: INTEGER
			bit_offset: INTEGER
			bits_remaining: INTEGER
			bits_from_byte: INTEGER
			byte_val: INTEGER
			mask: INTEGER
		do
			byte_pos := bit_pos // 8 + 1
			bit_offset := bit_pos \\ 8

			if byte_pos > a_data.count then
				Result := -1
			else
				Result := 0
				bits_remaining := code_length

				from
				until
					bits_remaining <= 0 or byte_pos > a_data.count
				loop
					byte_val := a_data.item (byte_pos).code

						-- How many bits can we get from this byte?
					bits_from_byte := (8 - bit_offset).min (bits_remaining)

						-- Extract bits (high-order first)
					mask := ((1 |<< bits_from_byte) - 1)
					Result := Result |<< bits_from_byte
					Result := Result + ((byte_val |>> (8 - bit_offset - bits_from_byte)) & mask)

					bits_remaining := bits_remaining - bits_from_byte
					byte_pos := byte_pos + 1
					bit_offset := 0
				end

				if bits_remaining > 0 then
						-- Not enough data
					Result := -1
				end
			end
		end

	updated_code_length (next_code: INTEGER; current_length: INTEGER): INTEGER
			-- Calculate new code length based on table size.
			-- Respects `early_change` parameter.
		local
			threshold: INTEGER
		do
			Result := current_length

			if current_length < 12 then
					-- Calculate threshold based on early_change
				threshold := (1 |<< current_length)
				if early_change = 1 then
					threshold := threshold - 1
				end

				if next_code >= threshold then
					Result := current_length + 1
				end
			end
		ensure
			valid_length: Result >= 9 and Result <= 12
		end

	initialize_table
			-- Initialize LZW table with single-byte entries.
		local
			i: INTEGER
			entry: STRING_8
		do
			from
				i := 0
			until
				i >= Max_table_size
			loop
				if i < 256 then
					create entry.make (1)
					entry.append_character (i.to_character_8)
					table [i] := entry
				else
					table [i] := create {STRING_8}.make_empty
				end
				i := i + 1
			end
		end

feature {NONE} -- Predictor Implementation

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
							-- Unknown predictor type - treat as None
						Result.append_character (current_byte.to_character_8)
					end

					j := j + 1
				end

				i := i + 1
			end
		ensure
			result_not_void: Result /= Void
		end

	decode_tiff_predictor (data: STRING_8; columns: INTEGER): STRING_8
			-- Decode TIFF Predictor 2 from decompressed data.
			-- Each color component of a sample is predicted to be the same
			-- as the corresponding color component of the sample to its left.
		require
			data_not_empty: not data.is_empty
			valid_columns: columns > 0
		local
			i: INTEGER
			current_byte, left_byte: NATURAL_8
		do
			create Result.make (data.count)

			from
				i := 1
			until
				i > data.count
			loop
				current_byte := data [i].natural_32_code.to_natural_8

					-- For TIFF Predictor 2, add the byte to the left (same row)
					-- Row boundary is at every `columns` bytes
				if ((i - 1) \\ columns) > 0 and i > 1 then
					left_byte := Result [Result.count].natural_32_code.to_natural_8
					current_byte := (current_byte + left_byte).to_natural_8
				end

				Result.append_character (current_byte.to_character_8)
				i := i + 1
			end
		ensure
			result_not_void: Result /= Void
			same_length: Result.count = data.count
		end

feature {NONE} -- Implementation

	table: ARRAY [STRING_8]
			-- LZW code table. Entries 0-255 are single bytes,
			-- 256 is clear-table, 257 is EOD, 258+ are sequences.

feature {NONE} -- Constants

	Clear_table_code: INTEGER = 256
			-- Code that signals table reset.

	Eod_code: INTEGER = 257
			-- End-of-data marker code.

	First_code: INTEGER = 258
			-- First code available for sequences.

	Max_table_size: INTEGER = 4096
			-- Maximum number of entries in LZW table (12-bit codes).

end
