note
	description: "Integration tests for Phase 3B: Document Writer."
	testing: "type/integration"

class
	TEST_PHASE3_DOCUMENT_WRITER

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

	test_read_modify_write
			-- Test Read -> Modify -> Write workflow.
		local
			doc: PDF_DOCUMENT
			source: PDF_FILE_BYTE_SOURCE
			footer_service: PDF_FOOTER_SERVICE
			path_in, path_out: PATH
			file_out: RAW_FILE
			doc2: PDF_DOCUMENT
			source2: PDF_FILE_BYTE_SOURCE
		do
			path_in := test_pdf_path ("hello_world.pdf")
				-- Use a unique temporary filename to avoid locking issues
			path_out := test_output_path ("footer_new.pdf")

			-- 1. Read
			create source.make_from_file (path_in.name)
			create doc.make_from_source (source)
			assert ("document loaded", doc.is_loaded)

			-- 2. Modify
			create footer_service.make
			footer_service.add_footer_to_document (doc, "CONFIDENTIAL")

			-- 3. Write
			doc.write_to_file (path_out.name)

			create file_out.make_open_read (path_out.name)
			assert ("output file exists", file_out.exists)
			assert ("output file has size", file_out.count > 0)
			file_out.close

			-- 4. Verify (Read back)
			create source2.make_from_file (path_out.name)
			create doc2.make_from_source (source2)
			assert ("modified document loaded", doc2.is_loaded)
			assert ("has trailer", doc2.trailer /= Void)
		end

end
