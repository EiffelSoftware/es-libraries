note
	description: "[
		Eiffel tests for PDF_WRITER that can be executed by testing tool.
	]"
	author: "EiffelStudio test wizard"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_HELLO_WORLD

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

	test_hello_world_pdf
			-- Test: Generate a Hello World PDF.
		note
			testing: "covers/{PDF_WRITER}.create_hello_world_pdf"
		local
			writer: PDF_WRITER
			pdf_content: STRING_8
			file: RAW_FILE
			output_path: PATH
		do
				-- Create the PDF writer
			create writer.make

				-- Generate the Hello World PDF
			pdf_content := writer.create_hello_world_pdf

				-- Verify we got content
			assert ("pdf_content_not_empty", not pdf_content.is_empty)
			assert ("pdf_has_header", pdf_content.starts_with ("%%PDF-"))
			assert ("pdf_has_eof", pdf_content.has_substring ("%%EOF"))

				-- Write to file for manual inspection
			output_path := test_output_path ("hello_world.pdf")
			create {RAW_FILE} file.make_create_read_write (output_path.name)
			file.put_string (pdf_content)
			file.flush
			file.close

			print ("Generated hello_world.pdf - open it in a PDF reader to verify.%N")
		end

end
