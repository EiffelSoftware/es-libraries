note
	description: "[
		Test reading an existing PDF and writing it with modifications.
		
		KNOWN LIMITATIONS:
		- PDFs using Object Streams (ObjStm) are not fully supported for write-back.
		  Objects stored in Object Streams will be missing from the output.
		- Linearized PDFs will lose their linearization optimization.
		- The generated PDF can be re-read by this library but may not open
		  correctly in all PDF viewers (e.g., Adobe Acrobat) due to missing objects.
		
		This is a Phase 2B limitation that requires implementing Object Stream
		decompression/extraction for full support.
	]"
	testing: "type/integration"

class
	TEST_OTHER_PDF_READ_WRITE
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

feature -- Test

	test_read_and_modify_xref_stream_pdf
			-- Test reading probable-provable.pdf (uses XRef streams) and writing with modifications.
			-- This tests Phase 2B: XRef stream support for READING.
			-- NOTE: The output PDF has known limitations - see class note.
		local
			doc: PDF_DOCUMENT
			source: PDF_FILE_BYTE_SOURCE
			footer_service: PDF_FOOTER_SERVICE
			path_in, path_out: PATH
			file_out: RAW_FILE
			doc2: PDF_DOCUMENT
			source2: PDF_FILE_BYTE_SOURCE
		do
			path_in := test_other_pdf_path ("probable-provable.pdf")
			path_out := test_output_path ("probable_provable_signed.pdf")

				-- 1. Read the existing PDF (uses XRef streams)
			create source.make_from_file (path_in.name)
			create doc.make_from_source (source)
			assert ("document loaded", doc.is_loaded)

				-- Verify XRef stream was parsed correctly
			assert ("has catalog", doc.catalog /= Void)

				-- 2. Modify - add a "SIGNED" footer
			create footer_service.make
			footer_service.add_footer_to_document (doc, "SIGNED")
			
				-- 3. Write to new file
			doc.write_to_file (path_out.name)

				-- Verify output file was created
			create file_out.make_open_read (path_out.name)
			assert ("output file exists", file_out.exists)
			assert ("output file has size", file_out.count > 0)
			file_out.close

				-- 4. Verify by reading back the modified PDF
				-- Note: This verifies our library can read it, not that Acrobat can.
			create source2.make_from_file (path_out.name)
			create doc2.make_from_source (source2)
			assert ("modified document loaded", doc2.is_loaded)
			assert ("has trailer", doc2.trailer /= Void)
		end

end

