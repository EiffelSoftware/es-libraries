note
	description: "[
		Integration tests for Phase 4B (Security Integration).
		Creates encrypted PDFs with different permission settings
		that can be verified in Adobe Acrobat.
		
		PDF Security uses two passwords:
		- User password: Required to OPEN the document. Empty = no password needed.
		- Owner password: Required to CHANGE permissions. Must be set for restrictions.
	]"

class
	TEST_OTHER_PHASE4B_INTEGRATION
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

	test_read_and_encrypt_full_permissions
			-- Read PDF and write with encryption but full permissions.
			-- Opens without password, all actions allowed.
		local
			doc: PDF_DOCUMENT
			source: PDF_FILE_BYTE_SOURCE
			handler: PDF_STANDARD_SECURITY_HANDLER
			permissions: PDF_PERMISSIONS
			encrypt_dict: PDF_DICTIONARY
			file_id: PDF_ARRAY
			encrypt_ref: PDF_REFERENCE
			encrypt_id: PDF_OBJECT_ID
			pdf_path: PATH
		do
			pdf_path := test_other_pdf_path ("probable-provable.pdf")
			create source.make_from_file (pdf_path.name)
			create doc.make_from_source (source)

			assert ("Document loaded", doc.is_loaded)

			-- Create permissions with all allowed
			create permissions.make_all_permitted

			-- Create file ID
			create file_id.make_empty
			file_id.add (create {PDF_STRING}.make_literal ("TestFileID123"))
			file_id.add (create {PDF_STRING}.make_literal ("TestFileID123"))

			-- Create encrypt dictionary
			-- Note: put_name(value, key) - value first, then key
			create encrypt_dict.make_empty
			encrypt_dict.put_name ("Standard", "Filter")  -- /Filter /Standard
			encrypt_dict.put_number (1, "V")  -- /V 1
			encrypt_dict.put_number (2, "R")  -- /R 2
			encrypt_dict.put_number (40, "Length")  -- /Length 40
			encrypt_dict.put_number (permissions.flags, "P")

			-- Create security handler and compute U and O values
			-- User password = "" (empty) so no password needed to open
			-- Owner password = non-empty for permission management
			create handler.make (encrypt_dict, file_id, "")
			handler.compute_password_entries ("", "owner_password")

			-- Add computed U and O values as hex strings (they contain binary data)
			encrypt_dict.put_hex_string (handler.u_entry, "U")
			encrypt_dict.put_hex_string (handler.o_entry, "O")

			-- Add encrypt dictionary to document as indirect object
			encrypt_id := doc.add_object (encrypt_dict)
			create encrypt_ref.make (encrypt_id)

			-- Add /Encrypt to trailer
			if attached doc.trailer as t then
				t.dictionary.put (encrypt_ref, "Encrypt")
			end

			-- Add /ID to trailer
			if attached doc.trailer as t then
				t.dictionary.put (file_id, "ID")
			end

			doc.set_security_handler (handler)

			-- Write encrypted PDF
			doc.write_to_file (test_output_path ("encrypted_full_permissions.pdf").name)

			assert ("Encrypted PDF created", True)
		end

	test_read_and_encrypt_read_only
			-- Read PDF and write with encryption, read-only (no print, no modify, no copy).
			-- Opens without password, but actions are restricted.
		local
			doc: PDF_DOCUMENT
			source: PDF_FILE_BYTE_SOURCE
			handler: PDF_STANDARD_SECURITY_HANDLER
			permissions: PDF_PERMISSIONS
			encrypt_dict: PDF_DICTIONARY
			file_id: PDF_ARRAY
			encrypt_ref: PDF_REFERENCE
			encrypt_id: PDF_OBJECT_ID
		do
			create source.make_from_file (test_other_pdf_path ("probable-provable.pdf").name)
			create doc.make_from_source (source)

			assert ("Document loaded", doc.is_loaded)

			-- Create restricted permissions
			create permissions.make_all_restricted

			-- Create file ID
			create file_id.make_empty
			file_id.add (create {PDF_STRING}.make_literal ("ReadOnlyTest123"))
			file_id.add (create {PDF_STRING}.make_literal ("ReadOnlyTest123"))

			-- Create encrypt dictionary
			create encrypt_dict.make_empty
			encrypt_dict.put_name ("Standard", "Filter")
			encrypt_dict.put_number (1, "V")
			encrypt_dict.put_number (2, "R")
			encrypt_dict.put_number (40, "Length")
			encrypt_dict.put_number (permissions.flags, "P")

			-- Create security handler with password
			-- User password = "" (no password to open)
			-- Owner password = set for restriction enforcement
			create handler.make (encrypt_dict, file_id, "")
			handler.compute_password_entries ("", "secret_owner_123")

			-- Add computed U and O values as hex strings
			encrypt_dict.put_hex_string (handler.u_entry, "U")
			encrypt_dict.put_hex_string (handler.o_entry, "O")

			-- Add encrypt dictionary to document as indirect object
			encrypt_id := doc.add_object (encrypt_dict)
			create encrypt_ref.make (encrypt_id)

			-- Add /Encrypt to trailer
			if attached doc.trailer as t then
				t.dictionary.put (encrypt_ref, "Encrypt")
			end

			-- Add /ID to trailer
			if attached doc.trailer as t then
				t.dictionary.put (file_id, "ID")
			end

			doc.set_security_handler (handler)

			-- Write encrypted PDF
			doc.write_to_file (test_output_path ("encrypted_read_only.pdf").name)

			assert ("Read-only encrypted PDF created", True)
		end

	test_read_and_encrypt_print_only
			-- Read PDF and write with encryption, allowing only printing.
			-- Opens without password, can print but not copy/modify.
		local
			doc: PDF_DOCUMENT
			source: PDF_FILE_BYTE_SOURCE
			handler: PDF_STANDARD_SECURITY_HANDLER
			permissions: PDF_PERMISSIONS
			encrypt_dict: PDF_DICTIONARY
			file_id: PDF_ARRAY
			encrypt_ref: PDF_REFERENCE
			encrypt_id: PDF_OBJECT_ID
		do
			create source.make_from_file (test_other_pdf_path ("probable-provable.pdf").name)
			create doc.make_from_source (source)

			assert ("Document loaded", doc.is_loaded)

			-- Create permissions with only print allowed
			create permissions.make_all_restricted
			permissions.enable_print
			permissions.enable_print_high_quality

			-- Create file ID
			create file_id.make_empty
			file_id.add (create {PDF_STRING}.make_literal ("PrintOnlyTest123"))
			file_id.add (create {PDF_STRING}.make_literal ("PrintOnlyTest123"))

			-- Create encrypt dictionary
			create encrypt_dict.make_empty
			encrypt_dict.put_name ("Standard", "Filter")
			encrypt_dict.put_number (1, "V")
			encrypt_dict.put_number (2, "R")
			encrypt_dict.put_number (40, "Length")
			encrypt_dict.put_number (permissions.flags, "P")

			-- Create security handler and compute U and O values
			-- User password = "" (no password to open)
			-- Owner password = set for restriction enforcement
			create handler.make (encrypt_dict, file_id, "")
			handler.compute_password_entries ("", "printme_owner")

			-- Add computed U and O values as hex strings
			encrypt_dict.put_hex_string (handler.u_entry, "U")
			encrypt_dict.put_hex_string (handler.o_entry, "O")

			-- Add encrypt dictionary to document as indirect object
			encrypt_id := doc.add_object (encrypt_dict)
			create encrypt_ref.make (encrypt_id)

			-- Add /Encrypt to trailer
			if attached doc.trailer as t then
				t.dictionary.put (encrypt_ref, "Encrypt")
			end

			-- Add /ID to trailer
			if attached doc.trailer as t then
				t.dictionary.put (file_id, "ID")
			end

			doc.set_security_handler (handler)

			-- Write encrypted PDF
			doc.write_to_file (test_output_path ("encrypted_print_only.pdf").name)

			assert ("Print-only encrypted PDF created", True)
		end

	test_read_and_encrypt_copy_allowed
			-- Read PDF and write with encryption, allowing only copy/extract.
			-- Opens without password, can copy but not print/modify.
		local
			doc: PDF_DOCUMENT
			source: PDF_FILE_BYTE_SOURCE
			handler: PDF_STANDARD_SECURITY_HANDLER
			permissions: PDF_PERMISSIONS
			encrypt_dict: PDF_DICTIONARY
			file_id: PDF_ARRAY
			encrypt_ref: PDF_REFERENCE
			encrypt_id: PDF_OBJECT_ID
		do
			create source.make_from_file (test_other_pdf_path ("probable-provable.pdf").name)
			create doc.make_from_source (source)

			assert ("Document loaded", doc.is_loaded)

			-- Create permissions with only copy allowed
			create permissions.make_all_restricted
			permissions.enable_copy
			permissions.enable_extract_accessibility

			-- Create file ID
			create file_id.make_empty
			file_id.add (create {PDF_STRING}.make_literal ("CopyOnlyTest123"))
			file_id.add (create {PDF_STRING}.make_literal ("CopyOnlyTest123"))

			-- Create encrypt dictionary
			create encrypt_dict.make_empty
			encrypt_dict.put_name ("Standard", "Filter")
			encrypt_dict.put_number (1, "V")
			encrypt_dict.put_number (2, "R")
			encrypt_dict.put_number (40, "Length")
			encrypt_dict.put_number (permissions.flags, "P")

			-- Create security handler and compute U and O values
			-- User password = "" (no password to open)
			-- Owner password = set for restriction enforcement
			create handler.make (encrypt_dict, file_id, "")
			handler.compute_password_entries ("", "copyme_owner")

			-- Add computed U and O values as hex strings
			encrypt_dict.put_hex_string (handler.u_entry, "U")
			encrypt_dict.put_hex_string (handler.o_entry, "O")

			-- Add encrypt dictionary to document as indirect object
			encrypt_id := doc.add_object (encrypt_dict)
			create encrypt_ref.make (encrypt_id)

			-- Add /Encrypt to trailer
			if attached doc.trailer as t then
				t.dictionary.put (encrypt_ref, "Encrypt")
			end

			-- Add /ID to trailer
			if attached doc.trailer as t then
				t.dictionary.put (file_id, "ID")
			end

			doc.set_security_handler (handler)

			-- Write encrypted PDF
			doc.write_to_file (test_output_path ("encrypted_copy_only.pdf").name)

			assert ("Copy-only encrypted PDF created", True)
		end

	test_read_and_encrypt_forms_only
			-- Read PDF and write with encryption, allowing only form filling.
			-- Opens without password, can fill forms but not print/edit/copy.
		local
			doc: PDF_DOCUMENT
			source: PDF_FILE_BYTE_SOURCE
			handler: PDF_STANDARD_SECURITY_HANDLER
			permissions: PDF_PERMISSIONS
			encrypt_dict: PDF_DICTIONARY
			file_id: PDF_ARRAY
			encrypt_ref: PDF_REFERENCE
			encrypt_id: PDF_OBJECT_ID
		do
			create source.make_from_file (test_other_pdf_path ("probable-provable.pdf").name)
			create doc.make_from_source (source)

			assert ("Document loaded", doc.is_loaded)

			-- Create permissions with only form filling allowed
			create permissions.make_all_restricted
			permissions.enable_fill_forms
			permissions.enable_modify_annotations

			-- Create file ID
			create file_id.make_empty
			file_id.add (create {PDF_STRING}.make_literal ("FormsOnlyTest123"))
			file_id.add (create {PDF_STRING}.make_literal ("FormsOnlyTest123"))

			-- Create encrypt dictionary
			create encrypt_dict.make_empty
			encrypt_dict.put_name ("Standard", "Filter")
			encrypt_dict.put_number (1, "V")
			encrypt_dict.put_number (2, "R")
			encrypt_dict.put_number (40, "Length")
			encrypt_dict.put_number (permissions.flags, "P")

			-- Create security handler and compute U and O values
			-- User password = "" (no password to open)
			-- Owner password = set for restriction enforcement
			create handler.make (encrypt_dict, file_id, "")
			handler.compute_password_entries ("", "formpass_owner")

			-- Add computed U and O values as hex strings
			encrypt_dict.put_hex_string (handler.u_entry, "U")
			encrypt_dict.put_hex_string (handler.o_entry, "O")

			-- Add encrypt dictionary to document as indirect object
			encrypt_id := doc.add_object (encrypt_dict)
			create encrypt_ref.make (encrypt_id)

			-- Add /Encrypt to trailer
			if attached doc.trailer as t then
				t.dictionary.put (encrypt_ref, "Encrypt")
			end

			-- Add /ID to trailer
			if attached doc.trailer as t then
				t.dictionary.put (file_id, "ID")
			end

			doc.set_security_handler (handler)

			-- Write encrypted PDF
			doc.write_to_file (test_output_path ("encrypted_forms_only.pdf").name)

			assert ("Forms-only encrypted PDF created", True)
		end

	test_sign_and_encrypt_view_only
			-- Read probable-provable.pdf, add "Signed by JV" footer,
			-- then encrypt with view-only permissions (no print, no copy, no modify).
			-- Combines Phase 3 footer injection with Phase 4B encryption.
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
			-- Read the PDF
			create source.make_from_file (test_other_pdf_path ("probable-provable.pdf").name)
			create doc.make_from_source (source)

			assert ("Document loaded", doc.is_loaded)

			-- Add "Signed by JV" footer to all pages
			create footer_service.make
			footer_service.set_margin (20.0)  -- 20 points from bottom
			footer_service.set_font_size (8.0)  -- 8pt font for signature
			footer_service.add_footer_to_document (doc, "Signed by JV - " + current_date)

			-- Create view-only permissions (restricted - no print, no copy, no modify)
			create permissions.make_all_restricted

			-- Create file ID
			create file_id.make_empty
			file_id.add (create {PDF_STRING}.make_literal ("SignedByJV20241224"))
			file_id.add (create {PDF_STRING}.make_literal ("SignedByJV20241224"))

			-- Create encrypt dictionary
			create encrypt_dict.make_empty
			encrypt_dict.put_name ("Standard", "Filter")
			encrypt_dict.put_number (1, "V")
			encrypt_dict.put_number (2, "R")
			encrypt_dict.put_number (40, "Length")
			encrypt_dict.put_number (permissions.flags, "P")

			-- Create security handler
			-- User password = "" (empty) so no password needed to open
			-- Owner password = set for restriction enforcement
			create handler.make (encrypt_dict, file_id, "")
			handler.compute_password_entries ("", "jv_owner_secret_2024")

			-- Add computed U and O values as hex strings
			encrypt_dict.put_hex_string (handler.u_entry, "U")
			encrypt_dict.put_hex_string (handler.o_entry, "O")

			-- Add encrypt dictionary to document as indirect object
			encrypt_id := doc.add_object (encrypt_dict)
			create encrypt_ref.make (encrypt_id)

			-- Add /Encrypt to trailer
			if attached doc.trailer as t then
				t.dictionary.put (encrypt_ref, "Encrypt")
			end

			-- Add /ID to trailer
			if attached doc.trailer as t then
				t.dictionary.put (file_id, "ID")
			end

			doc.set_security_handler (handler)

			-- Write signed and encrypted PDF
			doc.write_to_file (test_output_path ("signed_by_jv_encrypted.pdf").name)

			assert ("Signed and encrypted PDF created", True)
		end

	test_sign_and_encrypt_ITIL_view_only
			-- Read probable-provable.pdf, add "Signed by JV" footer,
			-- then encrypt with view-only permissions (no print, no copy, no modify).
			-- Combines Phase 3 footer injection with Phase 4B encryption.
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
			-- Read the PDF
			create source.make_from_file (test_other_pdf_path ("ITIL.pdf").name)
			create doc.make_from_source (source)

			assert ("Document loaded", doc.is_loaded)

			-- Add "Signed by JV" footer to all pages
			create footer_service.make
			footer_service.set_margin (20.0)  -- 20 points from bottom
			footer_service.set_font_size (8.0)  -- 8pt font for signature
			footer_service.add_footer_to_document (doc, "Signed by JV - " + current_date)

			-- Create view-only permissions (restricted - no print, no copy, no modify)
			create permissions.make_all_restricted

			-- Create file ID
			create file_id.make_empty
			file_id.add (create {PDF_STRING}.make_literal ("SignedByJV20241224"))
			file_id.add (create {PDF_STRING}.make_literal ("SignedByJV20241224"))

			-- Create encrypt dictionary
			create encrypt_dict.make_empty
			encrypt_dict.put_name ("Standard", "Filter")
			encrypt_dict.put_number (1, "V")
			encrypt_dict.put_number (2, "R")
			encrypt_dict.put_number (40, "Length")
			encrypt_dict.put_number (permissions.flags, "P")

			-- Create security handler
			-- User password = "" (empty) so no password needed to open
			-- Owner password = set for restriction enforcement
			create handler.make (encrypt_dict, file_id, "")
			handler.compute_password_entries ("", "jv_owner_secret_2024")

			-- Add computed U and O values as hex strings
			encrypt_dict.put_hex_string (handler.u_entry, "U")
			encrypt_dict.put_hex_string (handler.o_entry, "O")

			-- Add encrypt dictionary to document as indirect object
			encrypt_id := doc.add_object (encrypt_dict)
			create encrypt_ref.make (encrypt_id)

			-- Add /Encrypt to trailer
			if attached doc.trailer as t then
				t.dictionary.put (encrypt_ref, "Encrypt")
			end

			-- Add /ID to trailer
			if attached doc.trailer as t then
				t.dictionary.put (file_id, "ID")
			end

			doc.set_security_handler (handler)

			-- Write signed and encrypted PDF
			doc.write_to_file (test_output_path ("ITIL_output_signed_by_jv_encrypted.pdf").name)

			assert ("Signed and encrypted PDF created", True)
		end

	test_encrypt_ITIL_only
			-- Test just encrypting ITIL.pdf without footer to isolate if issue is with ITIL.pdf itself.
		local
			doc: PDF_DOCUMENT
			source: PDF_FILE_BYTE_SOURCE
			handler: PDF_STANDARD_SECURITY_HANDLER
			permissions: PDF_PERMISSIONS
			encrypt_dict: PDF_DICTIONARY
			file_id: PDF_ARRAY
			encrypt_ref: PDF_REFERENCE
			encrypt_id: PDF_OBJECT_ID
		do
			-- Read the PDF
			create source.make_from_file (test_other_pdf_path ("ITIL.pdf").name)
			create doc.make_from_source (source)

			assert ("Document loaded", doc.is_loaded)

			-- Create permissions with all allowed
			create permissions.make_all_permitted

			-- Create file ID
			create file_id.make_empty
			file_id.add (create {PDF_STRING}.make_literal ("ITILTest123"))
			file_id.add (create {PDF_STRING}.make_literal ("ITILTest123"))

			-- Create encrypt dictionary
			create encrypt_dict.make_empty
			encrypt_dict.put_name ("Standard", "Filter")
			encrypt_dict.put_number (1, "V")
			encrypt_dict.put_number (2, "R")
			encrypt_dict.put_number (40, "Length")
			encrypt_dict.put_number (permissions.flags, "P")

			-- Create security handler
			create handler.make (encrypt_dict, file_id, "")
			handler.compute_password_entries ("", "owner_password")

			-- Add computed U and O values as hex strings
			encrypt_dict.put_hex_string (handler.u_entry, "U")
			encrypt_dict.put_hex_string (handler.o_entry, "O")

			-- Add encrypt dictionary to document as indirect object
			encrypt_id := doc.add_object (encrypt_dict)
			create encrypt_ref.make (encrypt_id)

			-- Add /Encrypt to trailer
			if attached doc.trailer as t then
				t.dictionary.put (encrypt_ref, "Encrypt")
			end

			-- Add /ID to trailer
			if attached doc.trailer as t then
				t.dictionary.put (file_id, "ID")
			end

			doc.set_security_handler (handler)

			-- Write encrypted PDF
			doc.write_to_file (test_output_path ("ITIL_encrypted_only.pdf").name)

			assert ("ITIL PDF encrypted without footer", True)
		end

	test_footer_only_ITIL
			-- Test just adding footer to ITIL.pdf without encryption to see if footer works.
		local
			doc: PDF_DOCUMENT
			source: PDF_FILE_BYTE_SOURCE
			footer_service: PDF_FOOTER_SERVICE
			doc2: PDF_DOCUMENT
			source2: PDF_FILE_BYTE_SOURCE
		do
			print ("%N=== test_footer_only_ITIL ===%N")

			-- Read the PDF
			create source.make_from_file (test_other_pdf_path ("ITIL.pdf").name)
			create doc.make_from_source (source)

			assert ("Document loaded", doc.is_loaded)

			print ("Before footer - new_objects count: " + doc.new_objects.count.out + "%N")

			-- Add "Signed by JV" footer to all pages
			create footer_service.make
			footer_service.set_margin (20.0)  -- 20 points from bottom
			footer_service.set_font_size (8.0)  -- 8pt font for signature
			footer_service.add_footer_to_document (doc, "Signed by JV - " + current_date)

			print ("After footer - new_objects count: " + doc.new_objects.count.out + "%N")

			-- Write with footer but no encryption
			doc.write_to_file (test_output_path ("ITIL_footer_only.pdf").name)

			assert ("ITIL PDF with footer but no encryption", True)

			-- Verify: Can we read back the modified PDF?
			print ("Verifying: Reading back ITIL_footer_only.pdf...%N")
			create source2.make_from_file (test_output_path ("ITIL_footer_only.pdf").name)
			create doc2.make_from_source (source2)
			assert ("Modified PDF can be read back", doc2.is_loaded)
			assert ("Modified PDF has catalog", doc2.catalog /= Void)
			print ("Verification: Modified PDF loads successfully in our parser%N")
		end

	test_sign_and_encrypt_ECMA_view_only
			-- Read probable-provable.pdf, add "Signed by JV" footer,
			-- then encrypt with view-only permissions (no print, no copy, no modify).
			-- Combines Phase 3 footer injection with Phase 4B encryption.
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
			-- Read the PDF
			create source.make_from_file (test_other_pdf_path("v112-367_3_STANDARD.pdf").name)
			create doc.make_from_source (source)

			assert ("Document loaded", doc.is_loaded)

			-- Add "Signed by JV" footer to all pages
			create footer_service.make
			footer_service.set_margin (20.0)  -- 20 points from bottom
			footer_service.set_font_size (8.0)  -- 8pt font for signature
			footer_service.add_footer_to_document (doc, "Signed by JV - " + current_date)

			-- Create view-only permissions (restricted - no print, no copy, no modify)
			create permissions.make_all_restricted

			-- Create file ID
			create file_id.make_empty
			file_id.add (create {PDF_STRING}.make_literal ("SignedByJV20241224"))
			file_id.add (create {PDF_STRING}.make_literal ("SignedByJV20241224"))

			-- Create encrypt dictionary
			create encrypt_dict.make_empty
			encrypt_dict.put_name ("Standard", "Filter")
			encrypt_dict.put_number (1, "V")
			encrypt_dict.put_number (2, "R")
			encrypt_dict.put_number (40, "Length")
			encrypt_dict.put_number (permissions.flags, "P")

			-- Create security handler
			-- User password = "" (empty) so no password needed to open
			-- Owner password = set for restriction enforcement
			create handler.make (encrypt_dict, file_id, "")
			handler.compute_password_entries ("", "jv_owner_secret_2024")

			-- Add computed U and O values as hex strings
			encrypt_dict.put_hex_string (handler.u_entry, "U")
			encrypt_dict.put_hex_string (handler.o_entry, "O")

			-- Add encrypt dictionary to document as indirect object
			encrypt_id := doc.add_object (encrypt_dict)
			create encrypt_ref.make (encrypt_id)

			-- Add /Encrypt to trailer
			if attached doc.trailer as t then
				t.dictionary.put (encrypt_ref, "Encrypt")
			end

			-- Add /ID to trailer
			if attached doc.trailer as t then
				t.dictionary.put (file_id, "ID")
			end

			doc.set_security_handler (handler)

			-- Write signed and encrypted PDF
			doc.write_to_file ("ecma2_output_signed_by_jv_encrypted.pdf")

			assert ("Signed and encrypted PDF created", True)
		end



	test_read_write_ITIL_only
			-- Test just reading and rewriting ITIL.pdf without encryption to isolate the issue.
		local
			doc: PDF_DOCUMENT
			source: PDF_FILE_BYTE_SOURCE
			pages_dict: detachable PDF_DICTIONARY
			kids_array: detachable PDF_ARRAY
			first_page: detachable PDF_DICTIONARY
			contents_obj: detachable PDF_OBJECT
		do
			print ("%N=== ITIL.pdf Structure Analysis ===%N")

			-- Read the PDF
			create source.make_from_file (test_other_pdf_path ("ITIL.pdf").name)
			create doc.make_from_source (source)

			assert ("Document loaded", doc.is_loaded)

			print ("Loaded: " + doc.is_loaded.out + "%N")
			print ("XRef entries: " + doc.xref_table.entries.count.out + "%N")

			if attached doc.catalog as cat then
				print ("Has catalog: True%N")
				if attached {PDF_REFERENCE} cat.item ("Pages") as pages_ref then
					print ("Pages is a reference: " + pages_ref.object_id.object_number.out + "%N")
					if attached {PDF_DICTIONARY} doc.get_object (pages_ref.object_id) as pd then
						pages_dict := pd
						print ("Pages dictionary loaded%N")

						-- Get first page
						if attached {PDF_REFERENCE} pages_dict.item ("Kids") as kids_ref then
							if attached {PDF_ARRAY} doc.get_object (kids_ref.object_id) as ka then
								kids_array := ka
								if attached {PDF_REFERENCE} kids_array.item (1) as first_page_ref then
									if attached {PDF_DICTIONARY} doc.get_object (first_page_ref.object_id) as fp then
										first_page := fp
										print ("First page loaded%N")

										-- Check Contents type
										contents_obj := first_page.item ("Contents")
										if attached {PDF_REFERENCE} contents_obj as cont_ref then
											print ("Contents is PDF_REFERENCE: " + cont_ref.object_id.object_number.out + "%N")
										elseif attached {PDF_STREAM} contents_obj as cont_stream then
											print ("Contents is PDF_STREAM (direct) - LENGTH: " + cont_stream.content.count.out + "%N")
										elseif attached {PDF_ARRAY} contents_obj as cont_array then
											print ("Contents is PDF_ARRAY with " + cont_array.count.out + " items%N")
										else
											print ("Contents type: " + (if contents_obj /= Void then contents_obj.generator else "Void" end) + "%N")
										end
									end
								end
							end
						end
					end
				end
			end

			-- Write without encryption
			doc.write_to_file (test_output_path ("ITIL_output_no_encryption.pdf").name)

			assert ("ITIL PDF rewritten without encryption", True)
		end

feature {NONE} -- Implementation

	current_date: STRING_8
			-- Get current date as string for signature.
		local
			l_date: DATE
		do
			create l_date.make_now
			Result := l_date.year.out + "/" + l_date.month.out + "/" + l_date.day.out
		end

end
