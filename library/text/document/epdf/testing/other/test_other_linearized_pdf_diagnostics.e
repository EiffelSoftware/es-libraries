note
	description: "[
		Diagnostic tests for linearized PDF garbage content issue.
		Tests stream compression state tracking and XRef stream handling.
	]"

class
	TEST_OTHER_LINEARIZED_PDF_DIAGNOSTICS
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

	test_linearized_pdf_stream_content_integrity
			-- Test that stream content integrity is maintained through read/write cycle.
		local
			doc: PDF_DOCUMENT
			source: PDF_FILE_BYTE_SOURCE
			output_path: STRING_32
			original_size, output_size: INTEGER
		do
			print ("%N=== test_linearized_pdf_stream_content_integrity ===%N")

			-- Load the problematic PDF
			create source.make_from_file (test_other_pdf_path ("v112-367_3_STANDARD.pdf").name)
			create doc.make_from_source (source)

			assert ("document_loaded", doc.is_loaded)

			-- Get original file size
			create source.make_from_file (test_other_pdf_path ("v112-367_3_STANDARD.pdf").name)
			original_size := source.byte_count
			print ("Original file size: " + original_size.out + " bytes%N")

			-- Write to output
			output_path := test_output_path ("linearized.pdf").name
			doc.write_to_file (output_path)

			-- Check output size
			create source.make_from_file (output_path)
			output_size := source.byte_count
			print ("Output file size: " + output_size.out + " bytes%N")

			-- Output should be reasonable (not 5-10x larger)
			assert ("reasonable_output_size", output_size < original_size * 3)
		end

	test_xref_prev_chain_diagnostic
			-- Diagnostic test for XRef /Prev chain traversal.
		local
			doc: PDF_DOCUMENT
			source: PDF_FILE_BYTE_SOURCE
			xref_count: INTEGER
		do
			print ("%N=== test_xref_prev_chain_diagnostic ===%N")

			create source.make_from_file (test_other_pdf_path ("v112-367_3_STANDARD.pdf").name)
			create doc.make_from_source (source)

			assert ("document_loaded", doc.is_loaded)

			if attached doc.xref_table.entries as entries then
				xref_count := entries.count
				print ("Total XRef entries: " + xref_count.out + "%N")

				-- Should have loaded multiple XRef sections via /Prev chain
				-- For v112-367_3_STANDARD.pdf: ~42k entries expected
				assert ("has_full_xref_chain", xref_count > 1000)
			end
		end

end
