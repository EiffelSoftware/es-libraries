note
	description: "[
		Test suite for DCTDecode (JPEG) filter implementation.
		Tests the PDF_DCT_DECODER, JPEG_UNCOMPRESS, and JPEG_WRAPPER classes.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_DCT_DECODER

inherit
	EQA_TEST_SET

feature -- Test

	test_decoder_creation
			-- Test creating a DCT decoder.
		local
			decoder: PDF_DCT_DECODER
		do
			create decoder.make
			assert ("decoder_created", decoder /= Void)
			assert ("no_error_initially", not decoder.has_error_message)
			assert ("width_initially_zero", decoder.image_width = 0)
			assert ("height_initially_zero", decoder.image_height = 0)
			assert ("components_initially_zero", decoder.image_components = 0)
		end

	test_invalid_data_error
			-- Test that invalid data produces an error.
		local
			decoder: PDF_DCT_DECODER
			result_data: detachable STRING_8
		do
			create decoder.make
			
				-- Try to decode invalid data (not JPEG format)
			result_data := decoder.decode ("This is not JPEG data")
			
			assert ("decode_failed", result_data = Void)
			assert ("has_error", decoder.has_error_message)
			assert ("error_message_set", attached decoder.last_error_message)
		end

	test_empty_data_precondition
			-- Test that empty data violates precondition.
		local
			decoder: PDF_DCT_DECODER
			result_data: detachable STRING_8
			failed: BOOLEAN
		do
			if not failed then
				create decoder.make
				result_data := decoder.decode ("")
					-- Should not reach here (precondition violation)
				assert ("should_not_reach", False)
			end
		rescue
			failed := True
			retry
		end

	test_uncompress_wrapper_creation
			-- Test creating the JPEG uncompress wrapper.
		local
			uncompress: JPEG_UNCOMPRESS
		do
			create uncompress
			assert ("uncompress_created", uncompress /= Void)
			assert ("not_last_ok_initially", not uncompress.is_last_operation_ok)
			assert ("no_data_initially", uncompress.last_uncompressed_data = Void)
		end

	test_wrapper_creation
			-- Test creating the low-level JPEG wrapper.
		local
			wrapper: JPEG_WRAPPER
		do
			create wrapper
			assert ("wrapper_created", wrapper /= Void)
			assert ("no_error_initially", not wrapper.has_error)
		end

	test_wrapper_error_message
			-- Test error message is available after decode failure.
		local
			wrapper: JPEG_WRAPPER
			result_data: detachable ARRAY [NATURAL_8]
			input_data: ARRAY [NATURAL_8]
		do
			create wrapper
			
				-- Create invalid input data
			create input_data.make_filled (0, 1, 10)
			input_data [1] := 0  -- Not a valid JPEG header (should start with 0xFF 0xD8)
			
				-- Attempt decode which should fail
			result_data := wrapper.decompress (input_data)
			
				-- Verify error state
			assert ("decode_failed", result_data = Void)
			assert ("has_error", wrapper.has_error)
			assert ("error_code_negative", wrapper.last_error_code < 0)
			assert ("error_message_not_empty", not wrapper.error_message.is_empty)
		end

feature -- Optional: Test with real JPEG data

	test_minimal_jpeg_bytes
			-- Test with minimal valid JPEG-like bytes.
			-- Note: This requires valid JPEG data to truly test decompression.
			-- This test verifies error handling with near-valid data.
		local
			decoder: PDF_DCT_DECODER
			result_data: detachable STRING_8
			jpeg_header: STRING_8
		do
			create decoder.make
			
				-- JPEG magic bytes: 0xFF 0xD8 0xFF (Start of Image + marker)
				-- This is incomplete but tests that we reach the decoder
			create jpeg_header.make (3)
			jpeg_header.append_character ('%/0xFF/')
			jpeg_header.append_character ('%/0xD8/')
			jpeg_header.append_character ('%/0xFF/')
			
				-- This should fail because it's an incomplete JPEG
			result_data := decoder.decode (jpeg_header)
			
			assert ("incomplete_jpeg_fails", result_data = Void)
			assert ("has_error_for_incomplete", decoder.has_error_message)
		end

end
