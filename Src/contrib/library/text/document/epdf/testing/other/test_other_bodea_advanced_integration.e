note
	description: "[
		Additional Bodea Brochure integration tests
		Includes: Footer-only and Footer+Encryption combinations
	]"

class
	TEST_OTHER_BODEA_ADVANCED_INTEGRATION
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

	test_footer_only_bodea
			-- Test adding footer to Bodea Brochure without encryption
		local
			doc: PDF_DOCUMENT
			source: PDF_FILE_BYTE_SOURCE
			footer_service: PDF_FOOTER_SERVICE
			pdf_path: PATH
		do
			print ("%N=== Test: Bodea + Footer Only ===%N")

			pdf_path := test_other_pdf_path ("Bodea Brochure - Linearized.pdf")
			create source.make_from_file (pdf_path.name)
			create doc.make_from_source (source)
			assert ("Document loaded", doc.is_loaded)

			print ("Loaded: " + source.byte_count.out + " bytes%N")
			print ("Before footer - new_objects: " + doc.new_objects.count.out + "%N")

			    -- Add footer to all pages
			create footer_service.make
			footer_service.set_margin (20.0)
			footer_service.set_font_size (8.0)
			footer_service.add_footer_to_document (doc, "Signed by JV - " + current_date)

			print ("After footer - new_objects: " + doc.new_objects.count.out + "%N")

			doc.write_to_file (test_output_path ("bodea_footer_only.pdf").name)
			print ("✅ Written to: " + test_output_path ("bodea_footer_only.pdf").name + "%N")

			assert ("Footer-only PDF created", True)
		end

	test_footer_and_encrypt_bodea_view_only
			-- Test adding footer + encryption (view-only) to Bodea Brochure
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
		do
			print ("%N=== Test: Bodea + Footer + Encryption (View Only) ===%N")

			create source.make_from_file (test_other_pdf_path ("Bodea Brochure - Linearized.pdf").name)
			create doc.make_from_source (source)
			assert ("Document loaded", doc.is_loaded)

			    -- Step 1: Add footer
			create footer_service.make
			footer_service.set_margin (20.0)
			footer_service.set_font_size (8.0)
			footer_service.add_footer_to_document (doc, "Signed by JV - " + current_date)
			print ("Footer added%N")

			    -- Step 2: Add encryption with view-only permissions
			create permissions.make_all_restricted

			create file_id.make_empty
			file_id.add (create {PDF_STRING}.make_literal ("BodeaSignedViewOnly"))
			file_id.add (create {PDF_STRING}.make_literal ("BodeaSignedViewOnly"))

			create encrypt_dict.make_empty
			encrypt_dict.put_name ("Standard", "Filter")
			encrypt_dict.put_number (1, "V")
			encrypt_dict.put_number (2, "R")
			encrypt_dict.put_number (40, "Length")
			encrypt_dict.put_number (permissions.flags, "P")

			create handler.make (encrypt_dict, file_id, "")
			handler.compute_password_entries ("", "bodea_jv_owner_2024")

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

			doc.write_to_file (test_output_path ("bodea_footer_encrypted_view_only.pdf").name)
			print ("✅ Written to: test_output\bodea_footer_encrypted_view_only.pdf%N")

			assert ("Footer + encrypted PDF created", True)
		end

	test_footer_and_encrypt_bodea_print_only
			-- Test adding footer + encryption (print-only) to Bodea Brochure
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
		do
			print ("%N=== Test: Bodea + Footer + Encryption (Print Only) ===%N")

			create source.make_from_file (test_other_pdf_path ("Bodea Brochure - Linearized.pdf").name)
			create doc.make_from_source (source)
			assert ("Document loaded", doc.is_loaded)

			    -- Step 1: Add footer
			create footer_service.make
			footer_service.set_margin (20.0)
			footer_service.set_font_size (8.0)
			footer_service.add_footer_to_document (doc, "Signed by JV - " + current_date)
			print ("Footer added%N")

			    -- Step 2: Add encryption with print-only permissions
			create permissions.make_all_restricted
			permissions.enable_print
			permissions.enable_print_high_quality

			create file_id.make_empty
			file_id.add (create {PDF_STRING}.make_literal ("BodeaSignedPrintOnly"))
			file_id.add (create {PDF_STRING}.make_literal ("BodeaSignedPrintOnly"))

			create encrypt_dict.make_empty
			encrypt_dict.put_name ("Standard", "Filter")
			encrypt_dict.put_number (1, "V")
			encrypt_dict.put_number (2, "R")
			encrypt_dict.put_number (40, "Length")
			encrypt_dict.put_number (permissions.flags, "P")

			create handler.make (encrypt_dict, file_id, "")
			handler.compute_password_entries ("", "bodea_print_owner_2024")

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

			doc.write_to_file (test_output_path ("bodea_footer_encrypted_print_only.pdf").name)
			print ("✅ Written to: test_output\bodea_footer_encrypted_print_only.pdf%N")

			assert ("Footer + print-only encrypted PDF created", True)
		end

feature {NONE} -- Implementation

	current_date: STRING_8
			-- Get current date as string for signature
		local
			l_date: DATE
		do
			create l_date.make_now
			Result := l_date.year.out + "/" + l_date.month.out + "/" + l_date.day.out
		end

end
