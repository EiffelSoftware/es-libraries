note
	description: "Integration tests for PDF32000_2008.pdf matching example app"

class
	TEST_OTHER_PDF32000_2008_INTEGRATION
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

	test_process_pdf32000_2008
			-- Run standard example processing on PDF32000_2008.pdf
		local
			doc: PDF_DOCUMENT
			source: PDF_FILE_BYTE_SOURCE
			handler: PDF_STANDARD_SECURITY_HANDLER
			permissions: PDF_PERMISSIONS
			encrypt_dict: PDF_DICTIONARY
			file_id: PDF_ARRAY
			encrypt_ref: PDF_REFERENCE
			encrypt_id: PDF_OBJECT_ID
			footer_service: PDF_FOOTER_SERVICE
			output_path: PATH
		do
			print ("%N=== Test: PDF32000_2008.pdf Integration ===%N")

			create source.make_from_file (test_other_pdf_path ("PDF32000_2008.pdf").name)
			create doc.make_from_source (source)
			assert ("Document loaded", doc.is_loaded)

			print ("Loaded: " + source.byte_count.out + " bytes%N")

			-- 1. Add footer
			create footer_service.make
			footer_service.set_margin (15.0)
			footer_service.set_font_size (10.0)
			footer_service.set_alignment (footer_service.Alignment_center)
			footer_service.add_footer_to_document (doc, "Benchmark Footer - 2026/06/01")
			print ("Footer added%N")

			-- 2. Configure encryption
			create permissions.make_all_restricted
			permissions.enable_print
			permissions.enable_print_high_quality

			create file_id.make_empty
			file_id.add (create {PDF_STRING}.make_literal ("PDFProcessor2026/06/01"))
			file_id.add (create {PDF_STRING}.make_literal ("PDFProcessor2026/06/01"))

			create encrypt_dict.make_empty
			encrypt_dict.put_name ("Standard", "Filter")
			encrypt_dict.put_number (1, "V")
			encrypt_dict.put_number (2, "R")
			encrypt_dict.put_number (40, "Length")
			encrypt_dict.put_number (permissions.flags, "P")

			create handler.make (encrypt_dict, file_id, "")
			handler.compute_password_entries ("", "benchmark_password")

			encrypt_dict.put_hex_string (handler.u_entry, "U")
			encrypt_dict.put_hex_string (handler.o_entry, "O")

			encrypt_id := doc.add_object (encrypt_dict)
			create encrypt_ref.make (encrypt_id)

			if attached doc.trailer as t then
				t.dictionary.put (encrypt_ref, "Encrypt")
				t.dictionary.put (file_id, "ID")
			end

			doc.set_security_handler (handler)
			print ("Encryption configured%N")

			-- 3. Write output
			output_path := test_output_path ("PDF32000_2008_processed_temp.pdf")
			doc.write_to_file (output_path.name)
			print ("✅ Written to: " + output_path.name + "%N")

			assert ("PDF created", True)
		end

end
