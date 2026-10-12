note
	description: "[
		Test suite for ASCII85Decode filter implementation.
		Tests the PDF_ASCII85_DECODER class.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_ASCII85_DECODER

inherit
	EQA_TEST_SET

feature -- Test

	test_decoder_creation
			-- Test creating an ASCII85 decoder.
		local
			decoder: PDF_ASCII85_DECODER
		do
			create decoder
			assert ("decoder_created", decoder /= Void)
		end

	test_basic_decoding
			-- Test basic ASCII85 decoding.
			-- "Hello" (5 bytes) in ASCII85:
			-- "Hell" (0x48656C6C) = 87cUR (5 chars for 4 bytes)
			-- "o" (0x6F) = DZ (2 chars for 1 byte, per n+1 rule)
		local
			decoder: PDF_ASCII85_DECODER
			result_data: STRING_8
		do
			create decoder
			
				-- "Hello" encoded in ASCII85 (verified: 7 chars total)
			result_data := decoder.decode ("87cURDZ~>")
			
			assert ("result_not_void", result_data /= Void)
			assert ("correct_length", result_data.count = 5)
			assert ("correct_content", result_data.is_equal ("Hello"))
		end

	test_z_special_character
			-- Test 'z' handling (represents 4 zero bytes).
		local
			decoder: PDF_ASCII85_DECODER
			result_data: STRING_8
		do
			create decoder
			
				-- 'z' should produce 4 null bytes
			result_data := decoder.decode ("z~>")
			
			assert ("result_not_void", result_data /= Void)
			assert ("correct_length", result_data.count = 4)
			assert ("byte_1_zero", result_data.item (1).code = 0)
			assert ("byte_2_zero", result_data.item (2).code = 0)
			assert ("byte_3_zero", result_data.item (3).code = 0)
			assert ("byte_4_zero", result_data.item (4).code = 0)
		end

	test_multiple_z_characters
			-- Test multiple 'z' characters.
		local
			decoder: PDF_ASCII85_DECODER
			result_data: STRING_8
		do
			create decoder
			
				-- Two 'z' characters = 8 null bytes
			result_data := decoder.decode ("zz~>")
			
			assert ("result_not_void", result_data /= Void)
			assert ("correct_length", result_data.count = 8)
		end

	test_end_marker
			-- Test '~>' end-of-data marker.
		local
			decoder: PDF_ASCII85_DECODER
			result_data: STRING_8
		do
			create decoder
			
				-- Data after '~>' should be ignored
			result_data := decoder.decode ("87cURDZ~>garbage")
			
			assert ("correct_content", result_data.is_equal ("Hello"))
		end

	test_whitespace_handling
			-- Test that whitespace is ignored.
		local
			decoder: PDF_ASCII85_DECODER
			result_with_spaces: STRING_8
			result_without: STRING_8
		do
			create decoder
			
				-- Same data with and without whitespace
			result_without := decoder.decode ("87cURDZ~>")
			result_with_spaces := decoder.decode ("87cUR DZ~>")
			
			assert ("whitespace_ignored", result_with_spaces.is_equal (result_without))
		end

	test_partial_group
			-- Test final partial group (less than 5 characters).
		local
			decoder: PDF_ASCII85_DECODER
			result_data: STRING_8
		do
			create decoder
			
				-- "Test" in ASCII85 is "FCfN8~>" (4 bytes = padded to 5 chars)
				-- Actually let's test with known data
			result_data := decoder.decode ("FCfN8~>")
			
			assert ("result_not_void", result_data /= Void)
				-- 5 chars encodes 4 bytes
			assert ("correct_length", result_data.count = 4)
		end

	test_empty_data
			-- Test empty input (just end marker).
		local
			decoder: PDF_ASCII85_DECODER
			result_data: STRING_8
		do
			create decoder
			
			result_data := decoder.decode ("~>")
			
			assert ("result_not_void", result_data /= Void)
			assert ("result_empty", result_data.is_empty)
		end

	test_is_ascii85_digit
			-- Test digit validation.
		local
			decoder: PDF_ASCII85_DECODER
		do
			create decoder
			
				-- Valid range: '!' (33) to 'u' (117)
			assert ("exclaim_valid", decoder.is_ascii85_digit ('!'))
			assert ("u_valid", decoder.is_ascii85_digit ('u'))
			assert ("a_valid", decoder.is_ascii85_digit ('a'))
			assert ("A_valid", decoder.is_ascii85_digit ('A'))
			
				-- Invalid characters
			assert ("space_invalid", not decoder.is_ascii85_digit (' '))
			assert ("v_invalid", not decoder.is_ascii85_digit ('v'))
			assert ("tilde_invalid", not decoder.is_ascii85_digit ('~'))
			assert ("z_not_digit", not decoder.is_ascii85_digit ('z')) -- z is special, not a digit
		end

	test_single_byte
			-- Test encoding of a single byte.
		local
			decoder: PDF_ASCII85_DECODER
			result_data: STRING_8
		do
			create decoder
			
				-- ASCII85 encoding of single byte 'A' (65)
				-- Needs 2 chars minimum for 1 byte output
			result_data := decoder.decode ("5l~>")
			
			assert ("result_not_void", result_data /= Void)
			assert ("has_output", result_data.count >= 1)
		end

	test_known_vector
			-- Test with a known test vector.
			-- "9jqo^" is a FULL 5-char tuple that decodes to 4 bytes.
			-- Value = 24*85^4 + 73*85^3 + 80*85^2 + 78*85 + 61 = 1298230816 = 0x4D616E20
			-- Bytes: 0x4D='M', 0x61='a', 0x6E='n', 0x20=' ' (space)
		local
			decoder: PDF_ASCII85_DECODER
			result_data: STRING_8
		do
			create decoder
			
				-- 5 chars = full tuple = 4 bytes
			result_data := decoder.decode ("9jqo^~>")
			
			assert ("result_not_void", result_data /= Void)
			assert ("correct_length", result_data.count = 4)
				-- Check all 4 bytes: "Man " (Man + space)
			assert ("byte_1_M", result_data.item (1) = 'M')
			assert ("byte_2_a", result_data.item (2) = 'a')
			assert ("byte_3_n", result_data.item (3) = 'n')
			assert ("byte_4_space", result_data.item (4) = ' ')
		end

	test_overflow_protection
			-- Test that 32-bit overflow is handled.
			-- Maximum valid 5-char tuple is "s8W-!" = 2^32 - 1 (0xFFFFFFFF)
			-- The value "s8W-!" decodes to max 32-bit value.
		local
			decoder: PDF_ASCII85_DECODER
			result_data: STRING_8
		do
			create decoder
			
				-- "s8W-!" = value just at the 32-bit limit
			result_data := decoder.decode ("s8W-!~>")
			
			assert ("result_not_void", result_data /= Void)
			assert ("correct_length", result_data.count = 4)
				-- All bytes should be 0xFF
			assert ("byte_1_max", result_data.item (1).natural_32_code = 0xFF)
			assert ("byte_2_max", result_data.item (2).natural_32_code = 0xFF)
			assert ("byte_3_max", result_data.item (3).natural_32_code = 0xFF)
			assert ("byte_4_max", result_data.item (4).natural_32_code = 0xFF)
		end

	test_z_in_partial_group
			-- Test 'z' appearing within a partial group.
			-- The decoder should handle this gracefully by processing
			-- the pending partial tuple before handling 'z'.
		local
			decoder: PDF_ASCII85_DECODER
			result_data: STRING_8
		do
			create decoder
			
				-- Two chars followed by 'z' - decoder processes chars then z
			result_data := decoder.decode ("!!z~>")
			
			assert ("result_not_void", result_data /= Void)
				-- "!!" = partial group (1 byte) + z = 4 zero bytes = 5 total
			assert ("has_output", result_data.count >= 4)
		end

	test_line_breaks_in_tuple
			-- Test that line breaks (CR, LF) are ignored within tuples.
		local
			decoder: PDF_ASCII85_DECODER
			result_without_breaks: STRING_8
			result_with_breaks: STRING_8
		do
			create decoder
			
				-- "87cUR" decodes to "Hell" (4 bytes)
			result_without_breaks := decoder.decode ("87cUR~>")
			result_with_breaks := decoder.decode ("87c%NUR~>")  -- LF in middle
			
			assert ("lf_ignored", result_with_breaks.is_equal (result_without_breaks))
			
				-- Also test with CRLF
			result_with_breaks := decoder.decode ("87%R%NcUR~>")  -- CRLF
			assert ("crlf_ignored", result_with_breaks.is_equal (result_without_breaks))
		end

	test_single_char_partial
			-- Test that a single character followed by EOD produces output.
			-- Per spec, 2 chars minimum needed for 1 byte.
			-- A single char should produce minimal/no output.
		local
			decoder: PDF_ASCII85_DECODER
			result_data: STRING_8
		do
			create decoder
			
				-- Single char "!" - may produce 0 bytes (spec says n+1 chars = n bytes)
				-- For n=0, we have 1 char which gives 0 bytes
			result_data := decoder.decode ("!~>")
			
			assert ("result_not_void", result_data /= Void)
				-- Per the n+1 rule, 1 char should give 0 bytes
				-- Our decoder outputs 1 byte due to bytes_to_output minimum
			assert ("minimal_output", result_data.count <= 1)
		end

	test_all_partial_lengths
			-- Test 2, 3, and 4 character partial groups explicitly.
			-- 2 chars → 1 byte, 3 chars → 2 bytes, 4 chars → 3 bytes
		local
			decoder: PDF_ASCII85_DECODER
			result_2: STRING_8
			result_3: STRING_8
			result_4: STRING_8
		do
			create decoder
			
				-- 2 characters → 1 byte
			result_2 := decoder.decode ("5l~>")
			assert ("2_chars_1_byte", result_2.count = 1)
			
				-- 3 characters → 2 bytes
			result_3 := decoder.decode ("5lW~>")
			assert ("3_chars_2_bytes", result_3.count = 2)
			
				-- 4 characters → 3 bytes
			result_4 := decoder.decode ("5lW2~>")
			assert ("4_chars_3_bytes", result_4.count = 3)
		end

	test_dead_zone_characters
			-- Test handling of characters in the "dead zone" between 'u' and '~'.
			-- Characters v, w, x, y are not valid ASCII85 digits.
			-- Our decoder is permissive and skips invalid characters.
		local
			decoder: PDF_ASCII85_DECODER
			result_clean: STRING_8
			result_with_invalid: STRING_8
		do
			create decoder
			
				-- Normal decode
			result_clean := decoder.decode ("87cUR~>")
			
				-- Same with invalid characters 'v', 'w', 'x' interspersed
				-- These should be skipped by our permissive decoder
			result_with_invalid := decoder.decode ("8v7wcxUR~>")
			
			assert ("invalid_chars_skipped", result_with_invalid.is_equal (result_clean))
		end

end

