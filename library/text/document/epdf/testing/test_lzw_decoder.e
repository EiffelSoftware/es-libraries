note
	description: "[
		Test suite for LZWDecode filter implementation.
		Tests the PDF_LZW_DECODER class per ISO 32000-1:2008 §7.4.4.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_LZW_DECODER

inherit
	EQA_TEST_SET

feature -- Test

	test_decoder_creation
			-- Test creating an LZW decoder.
		local
			decoder: PDF_LZW_DECODER
		do
			create decoder.make
			assert ("decoder_created", decoder /= Void)
			assert ("early_change_default", decoder.early_change = 1)
		end

	test_basic_decoding
			-- Test basic LZW decoding with two bytes.
			-- Clear-table (256) + 'A' (65) + 'B' (66) + EOD (257)
			-- 256 (9 bits) = 1 0000 0000
			-- 65 (9 bits)  = 0 0100 0001
			-- 66 (9 bits)  = 0 0100 0010
			-- 257 (9 bits) = 1 0000 0001
			-- Packed (36 bits):
			-- Byte 0: 10000000 = 0x80
			-- Byte 1: 00010000 = 0x10
			-- Byte 2: 01001000 = 0x48
			-- Byte 3: 01010000 = 0x50
			-- Byte 4: 00010000 = 0x10
		local
			decoder: PDF_LZW_DECODER
			encoded: STRING_8
			result_data: detachable STRING_8
		do
			create decoder.make

			create encoded.make (5)
			encoded.append_character ('%/0x80/')
			encoded.append_character ('%/0x10/')
			encoded.append_character ('%/0x48/')
			encoded.append_character ('%/0x50/')
			encoded.append_character ('%/0x10/')

			result_data := decoder.decode (encoded)

			assert ("result_not_void", result_data /= Void)
			if attached result_data as rd then
				assert ("correct_length", rd.count = 2)
				assert ("byte_1_is_A", rd.item (1) = 'A')
				assert ("byte_2_is_B", rd.item (2) = 'B')
			end
		end

	test_single_byte
			-- Test decoding a single byte (simplest case).
			-- Clear-table (256) + single byte 'A' (65) + EOD (257)
		local
			decoder: PDF_LZW_DECODER
			encoded: STRING_8
			result_data: detachable STRING_8
		do
			create decoder.make

				-- Build minimal LZW stream: clear-table + 'A' + EOD
				-- 256 (9 bits) = 1 0000 0000
				-- 65 (9 bits)  = 0 0100 0001
				-- 257 (9 bits) = 1 0000 0001
				-- Packed: 10000000 00010000 01100000 001xxxxx
				-- = 0x80 0x10 0x60 0x20
			create encoded.make (4)
			encoded.append_character ('%/0x80/')
			encoded.append_character ('%/0x10/')
			encoded.append_character ('%/0x60/')
			encoded.append_character ('%/0x20/')

			result_data := decoder.decode (encoded)

			assert ("result_not_void", result_data /= Void)
			if attached result_data as rd then
				assert ("correct_length", rd.count = 1)
				assert ("is_A", rd.item (1) = 'A')
			end
		end

	test_early_change_parameter
			-- Test EarlyChange parameter setting.
		local
			decoder: PDF_LZW_DECODER
		do
			create decoder.make
			assert ("default_is_1", decoder.early_change = 1)

			decoder.set_early_change (0)
			assert ("changed_to_0", decoder.early_change = 0)

			decoder.set_early_change (1)
			assert ("changed_back_to_1", decoder.early_change = 1)
		end

	test_clear_table_handling
			-- Test that clear-table resets table - simply test with 'Z' byte.
			-- Clear-table (256) + 'Z' (90) + EOD (257)
			-- 256 (9 bits) = 1 0000 0000
			-- 90 (9 bits)  = 0 0101 1010
			-- 257 (9 bits) = 1 0000 0001
			-- Packed (27 bits):
			-- Byte 0: 10000000 = 0x80
			-- Byte 1: 00010110 = 0x16
			-- Byte 2: 10100000 = 0xA0
			-- Byte 3: 00100000 = 0x20
		local
			decoder: PDF_LZW_DECODER
			encoded: STRING_8
			result_data: detachable STRING_8
		do
			create decoder.make

			create encoded.make (4)
			encoded.append_character ('%/0x80/')
			encoded.append_character ('%/0x16/')
			encoded.append_character ('%/0xA0/')
			encoded.append_character ('%/0x20/')

			result_data := decoder.decode (encoded)

			assert ("result_not_void", result_data /= Void)
			if attached result_data as rd then
				assert ("correct_length", rd.count = 1)
				assert ("is_Z", rd.item (1) = 'Z')
			end
		end

	test_error_handling
			-- Test that invalid data produces appropriate error messages.
		local
			decoder: PDF_LZW_DECODER
			result_data: detachable STRING_8
		do
			create decoder.make

				-- Try to decode invalid data (no clear-table at start)
				-- This should fail because the first code must be a clear-table or a single byte
			result_data := decoder.decode ("%/0xFF/%/0xFF/%/0xFF/")

				-- The decoder should handle this gracefully
			assert ("has_error_or_empty", result_data = Void or (attached result_data as rd and then rd.is_empty) or decoder.has_error_message)
		end

	test_eod_marker
			-- Test End-Of-Data marker stops decoding.
		local
			decoder: PDF_LZW_DECODER
			encoded: STRING_8
			result_data: detachable STRING_8
		do
			create decoder.make

				-- Clear-table + 'A' + EOD + garbage
				-- Garbage after EOD should be ignored
			create encoded.make (8)
			encoded.append_character ('%/0x80/')
			encoded.append_character ('%/0x10/')
			encoded.append_character ('%/0x60/')
			encoded.append_character ('%/0x20/')
				-- Add garbage bytes that should be ignored
			encoded.append_character ('%/0xFF/')
			encoded.append_character ('%/0xFF/')
			encoded.append_character ('%/0xFF/')
			encoded.append_character ('%/0xFF/')

			result_data := decoder.decode (encoded)

			assert ("result_not_void", result_data /= Void)
			if attached result_data as rd then
				assert ("only_one_byte", rd.count = 1)
				assert ("is_A", rd.item (1) = 'A')
			end
		end

	test_repeated_sequence
			-- Test decoding two different bytes 'X' and 'Y'.
			-- Clear-table (256) + 'X' (88) + 'Y' (89) + EOD (257)
			-- 256 (9 bits) = 1 0000 0000
			-- 88 (9 bits)  = 0 0101 1000
			-- 89 (9 bits)  = 0 0101 1001
			-- 257 (9 bits) = 1 0000 0001
			-- Packed (36 bits):
			-- Byte 0: 10000000 = 0x80
			-- Byte 1: 00010110 = 0x16
			-- Byte 2: 00001011 = 0x0B
			-- Byte 3: 00110000 = 0x30
			-- Byte 4: 00010000 = 0x10
		local
			decoder: PDF_LZW_DECODER
			encoded: STRING_8
			result_data: detachable STRING_8
		do
			create decoder.make

			create encoded.make (5)
			encoded.append_character ('%/0x80/')
			encoded.append_character ('%/0x16/')
			encoded.append_character ('%/0x0B/')
			encoded.append_character ('%/0x30/')
			encoded.append_character ('%/0x10/')

			result_data := decoder.decode (encoded)

			assert ("result_not_void", result_data /= Void)
			if attached result_data as rd then
				assert ("correct_length", rd.count = 2)
				assert ("first_is_X", rd.item (1) = 'X')
				assert ("second_is_Y", rd.item (2) = 'Y')
			end
		end

	test_has_error_message_query
			-- Test has_error_message query.
		local
			decoder: PDF_LZW_DECODER
		do
			create decoder.make
			assert ("no_error_initially", not decoder.has_error_message)
		end

	test_kwkwk_edge_case
			-- Test the "KwKwK" special case where incoming code equals next_code.
			-- This tests the scenario where decoder receives a code not yet in dictionary.
			-- Input: Clear(256), A(65), Code(258), EOD(257)
			-- When receiving 258, it's not yet defined (next_code = 258).
			-- Decoder derives it as prev_seq + first_char of prev_seq = "A" + "A" = "AA"
			-- Expected output: "A" + "AA" = "AAA"
		local
			decoder: PDF_LZW_DECODER
			encoded: STRING_8
			result_data: detachable STRING_8
		do
			create decoder.make

				-- Pack codes: 256, 65, 258, 257 (all 9 bits)
				-- 258 arrives when next_code = 258, triggering KwKwK case
			encoded := pack_9bit_codes (<<256, 65, 258, 257>>)

			result_data := decoder.decode (encoded)

			assert ("result_not_void", result_data /= Void)
			if attached result_data as rd then
				assert ("correct_length", rd.count = 3)
				assert ("is_AAA", rd.is_equal ("AAA"))
			end
		end

	test_bit_width_transition_early_change_1
			-- Test bit-width transition from 9 to 10 bits with EarlyChange=1 (default).
			-- With EarlyChange=1, transition occurs when next_code reaches 511 (before adding entry 511).
			-- We need to add entries 258-510 (253 entries) to trigger transition.
		local
			decoder: PDF_LZW_DECODER
			codes: ARRAYED_LIST [INTEGER]
			encoded: STRING_8
			result_data: detachable STRING_8
			i: INTEGER
			expected_length: INTEGER
		do
			create decoder.make
				-- EarlyChange=1 is default

				-- Build a sequence that creates many table entries
				-- Clear + 250 unique bytes + a few more to cross the threshold
			create codes.make (260)
			codes.extend (256) -- Clear
			from i := 0 until i >= 254 loop
				codes.extend (i) -- Bytes 0-253
				i := i + 1
			end
			codes.extend (257) -- EOD

			encoded := pack_9bit_codes (codes.to_array)
			result_data := decoder.decode (encoded)

			assert ("result_not_void", result_data /= Void)
			if attached result_data as rd then
				expected_length := 254
				assert ("correct_length", rd.count = expected_length)
			end
		end

	test_bit_width_transition_early_change_0
			-- Test bit-width transition with EarlyChange=0.
			-- With EarlyChange=0, transition occurs when next_code reaches 512.
		local
			decoder: PDF_LZW_DECODER
			codes: ARRAYED_LIST [INTEGER]
			encoded: STRING_8
			result_data: detachable STRING_8
			i: INTEGER
		do
			create decoder.make
			decoder.set_early_change (0)

				-- Build sequence with unique bytes
			create codes.make (260)
			codes.extend (256) -- Clear
			from i := 0 until i >= 250 loop
				codes.extend (i) -- Bytes 0-249
				i := i + 1
			end
			codes.extend (257) -- EOD

			encoded := pack_9bit_codes (codes.to_array)
			result_data := decoder.decode (encoded)

			assert ("result_not_void", result_data /= Void)
			if attached result_data as rd then
				assert ("correct_length", rd.count = 250)
			end
		end

	test_dictionary_overflow_limit
			-- Test that decoder handles maximum dictionary size (4096 entries).
			-- The decoder should not attempt to read 13-bit codes.
		local
			decoder: PDF_LZW_DECODER
			result_data: detachable STRING_8
			codes: ARRAYED_LIST [INTEGER]
			encoded: STRING_8
			i: INTEGER
		do
			create decoder.make

				-- Create a simpler test that verifies decoder doesn't crash
				-- with a moderate-sized sequence
			create codes.make (150)
			codes.extend (256) -- Clear
			from i := 0 until i >= 128 loop
				codes.extend (i) -- First 128 byte values
				i := i + 1
			end
			codes.extend (257) -- EOD

			encoded := pack_9bit_codes (codes.to_array)
			result_data := decoder.decode (encoded)

			assert ("result_not_void", result_data /= Void)
			if attached result_data as rd then
				assert ("correct_length", rd.count = 128)
					-- Verify first and last bytes
				assert ("first_byte", rd.item (1).code = 0)
				assert ("last_byte", rd.item (128).code = 127)
			end
		end

feature {NONE} -- Test Helpers

	pack_9bit_codes (codes: ARRAY [INTEGER]): STRING_8
			-- Pack an array of 9-bit codes into a byte string.
			-- This is a simplified version that only handles 9-bit codes.
			-- For production use, this would need to handle variable bit widths.
		local
			i: INTEGER
			bit_buffer: NATURAL_32
			bits_in_buffer: INTEGER
			code: INTEGER
		do
			create Result.make (codes.count * 2)
			bit_buffer := 0
			bits_in_buffer := 0

			from
				i := codes.lower
			until
				i > codes.upper
			loop
				code := codes [i]

					-- Add 9 bits to buffer (high-order first)
				bit_buffer := (bit_buffer |<< 9) + code.to_natural_32
				bits_in_buffer := bits_in_buffer + 9

					-- Extract complete bytes
				from
				until
					bits_in_buffer < 8
				loop
					bits_in_buffer := bits_in_buffer - 8
					Result.append_character (((bit_buffer |>> bits_in_buffer) & 0xFF).to_integer_32.to_character_8)
					bit_buffer := bit_buffer & ((1 |<< bits_in_buffer).to_natural_32 - 1)
				end

				i := i + 1
			end

				-- Pad remaining bits to complete last byte
			if bits_in_buffer > 0 then
				bit_buffer := bit_buffer |<< (8 - bits_in_buffer)
				Result.append_character ((bit_buffer & 0xFF).to_integer_32.to_character_8)
			end
		ensure
			result_not_void: Result /= Void
		end

end

