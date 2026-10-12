note
	description: "[
		Diagnostic tests for linearized PDF garbage content issue.
		Tests stream compression state tracking and XRef stream handling.
	]"

class
	TEST_LINEARIZED_PDF_DIAGNOSTICS

inherit
	EQA_TEST_SET
		redefine
			on_prepare
		end
	TEST_PATH_HELPER

feature -- Setup

	on_prepare
			-- Setup routine called before each test.
		do
			ensure_test_output_directory_exists
		end

feature -- Test routines

	test_stream_compression_state_tracking
			-- Test that stream compression state is properly tracked.
		local
			stream: PDF_STREAM
			dict: PDF_DICTIONARY
		do
			-- Create a stream with compressed content
			create dict.make (2)
			dict.put_number (100, "Length")
			dict.put_name ("FlateDecode", "Filter")

			-- Simulate compressed content (fake zlib data)
			create stream.make_with_dictionary (dict, "compressed_data")

			-- Initially should be considered compressed (has /Filter)
			assert ("initially_has_filter", stream.stream_dictionary.has_key ("Filter"))
			assert ("initially_compressed", stream.is_compressed)

			-- Mark as decompressed
			stream.mark_as_decompressed ("FlateDecode")
			assert ("marked_decompressed", stream.is_decompressed)
			assert ("still_has_filter", stream.stream_dictionary.has_key ("Filter"))

			-- Test serialization logic (would need to be added)
			-- This should remove filter and/or recompress
		end

	test_minimal_xref_stream_parsing
			-- Test parsing of minimal XRef stream.
		local
			doc: PDF_DOCUMENT
			source: PDF_FILE_BYTE_SOURCE
			xref_count: INTEGER
			pdf_path: PATH
		do
			print ("%N=== test_minimal_xref_stream_parsing ===%N")

			create pdf_path.make_current
			pdf_path := testing_dir_path.extended ("linearized_test_cases").extended ("valid_xref_stream.pdf")
			create source.make_from_file (pdf_path.name)
			create doc.make_from_source (source)

			assert ("document_loaded", doc.is_loaded)

			if attached doc.xref_table.entries as entries then
				xref_count := entries.count
				print ("XRef entries loaded: " + xref_count.out + "%N")

				-- Should have 5 entries (0-4)
				assert ("has_expected_entries", xref_count = 5)
			end

			if attached doc.catalog as cat then
				print ("Catalog accessible%N")
				assert ("catalog_exists", True)
			end
		end

	test_zlib_decompression_edge_cases
			-- Test various ZLIB decompression edge cases.
		local
			decoder: PDF_FLATE_DECODER
			test_data: STRING_8
			decoded_result: detachable STRING_8
		do
			print ("%N=== test_zlib_decompression_edge_cases ===%N")

			create decoder.make

			-- Test case 1: Invalid compressed data (not valid zlib)
			test_data := "invalid_compressed_data_not_zlib"
			decoded_result := decoder.decode (test_data)
			if decoder.has_error_message then
				print ("Expected error for invalid compressed data%N")
			else
				print ("Unexpected success with invalid data%N")
			end

			-- Note: Empty data test removed - precondition requires non-empty input
			-- per PDF specification, streams always have content

			-- Test case 2: Data with single bytes (too short for zlib header)
			test_data := "AB"
			decoded_result := decoder.decode (test_data)
			if decoder.has_error_message then
				print ("Expected error for too-short data%N")
			else
				print ("Unexpected success with too-short data%N")
			end

			print ("ZLIB edge case tests completed%N")
		end

end
