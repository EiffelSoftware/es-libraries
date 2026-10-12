note
	description: "[
		Phase 4B integration tests using simple hello_world.pdf.
		Tests encryption with various permission settings on a small, simple PDF.
		
		PDF Security uses two passwords:
		- User password: Required to OPEN the document. Empty = no password needed.
		- Owner password: Required to CHANGE permissions. Must be set for restrictions.
	]"

class
	TEST_PHASE4B_SIMPLE

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

	test_encrypt_hello_world_full_permissions
			-- Encrypt hello_world.pdf with full permissions.
			-- User can open without password and do everything.
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
			pdf_path := test_pdf_path ("hello_world.pdf")
			create source.make_from_file (pdf_path.name)
			create doc.make_from_source (source)
			
			assert ("Document loaded", doc.is_loaded)
			
			-- Create permissions with all allowed
			create permissions.make_all_permitted
			
			-- Create file ID
			create file_id.make_empty
			file_id.add (create {PDF_STRING}.make_literal ("HelloWorldTest123"))
			file_id.add (create {PDF_STRING}.make_literal ("HelloWorldTest123"))
			
			-- Create encrypt dictionary (manually for testing)
			-- Note: put_name(value, key) - value first, then key
			create encrypt_dict.make_empty
			encrypt_dict.put_name ("Standard", "Filter")  -- /Filter /Standard
			encrypt_dict.put_number (1, "V")  -- /V 1
			encrypt_dict.put_number (2, "R")  -- /R 2
			encrypt_dict.put_number (40, "Length")  -- /Length 40
			encrypt_dict.put_number (permissions.flags, "P")
			
			-- Create security handler
			-- User password = "" (empty) so no password needed to open
			-- Owner password = non-empty to set restrictions
			create handler.make (encrypt_dict, file_id, "")
			handler.compute_password_entries ("", "owner_secret")
			
			-- Compute and set U and O values as hex strings (they contain binary data)
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
			
			-- Set security handler
			doc.set_security_handler (handler)
			
			-- Write encrypted PDF
			doc.write_to_file (test_output_path ("hello_world_encrypted_full.pdf").name)
			
			assert ("Encrypted PDF created", True)
		end

	test_encrypt_hello_world_read_only
			-- Encrypt hello_world.pdf with read-only permissions.
			-- User can open without password but cannot print/copy/modify.
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
			create source.make_from_file (test_pdf_path ("hello_world.pdf").name)
			create doc.make_from_source (source)
			
			assert ("Document loaded", doc.is_loaded)
			
			-- Create restricted permissions (no print, no copy, no modify)
			create permissions.make_all_restricted
			
			-- Create file ID
			create file_id.make_empty
			file_id.add (create {PDF_STRING}.make_literal ("HelloReadOnly123"))
			file_id.add (create {PDF_STRING}.make_literal ("HelloReadOnly123"))
			
			-- Create encrypt dictionary
			create encrypt_dict.make_empty
			encrypt_dict.put_name ("Standard", "Filter")
			encrypt_dict.put_number (1, "V")
			encrypt_dict.put_number (2, "R")
			encrypt_dict.put_number (40, "Length")
			encrypt_dict.put_number (permissions.flags, "P")
			
			-- Create security handler
			-- User password = "" (empty) so no password needed to open
			-- Owner password = non-empty for permission enforcement
			create handler.make (encrypt_dict, file_id, "")
			handler.compute_password_entries ("", "readonly_owner_pass")
			
			-- Compute and set U and O values as hex strings
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
			
			-- Set security handler
			doc.set_security_handler (handler)
			
			-- Write encrypted PDF
			doc.write_to_file (test_output_path ("hello_world_encrypted_readonly.pdf").name)
			
			assert ("Read-only encrypted PDF created", True)
		end

	test_encrypt_hello_world_print_only
			-- Encrypt hello_world.pdf with print-only permissions.
			-- User can open without password and print, but cannot copy/modify.
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
			create source.make_from_file (test_pdf_path ("hello_world.pdf").name)
			create doc.make_from_source (source)
			
			assert ("Document loaded", doc.is_loaded)
			
			-- Create permissions with only print allowed
			create permissions.make_all_restricted
			permissions.enable_print
			permissions.enable_print_high_quality
			
			-- Create file ID
			create file_id.make_empty
			file_id.add (create {PDF_STRING}.make_literal ("HelloPrintOnly123"))
			file_id.add (create {PDF_STRING}.make_literal ("HelloPrintOnly123"))
			
			-- Create encrypt dictionary
			create encrypt_dict.make_empty
			encrypt_dict.put_name ("Standard", "Filter")
			encrypt_dict.put_number (1, "V")
			encrypt_dict.put_number (2, "R")
			encrypt_dict.put_number (40, "Length")
			encrypt_dict.put_number (permissions.flags, "P")
			
			-- Create security handler
			-- User password = "" (empty) so no password needed to open
			-- Owner password = non-empty for permission enforcement
			create handler.make (encrypt_dict, file_id, "")
			handler.compute_password_entries ("", "print_owner_pass")
			
			-- Compute and set U and O values as hex strings
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
			
			-- Set security handler
			doc.set_security_handler (handler)
			
			-- Write encrypted PDF
			doc.write_to_file (test_output_path ("hello_world_encrypted_print.pdf").name)
			
			assert ("Print-only encrypted PDF created", True)
		end

	test_encrypt_hello_world_password_required
			-- Encrypt hello_world.pdf requiring a password to open.
			-- This tests user password functionality.
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
			create source.make_from_file (test_pdf_path ("hello_world.pdf").name)
			create doc.make_from_source (source)
			
			assert ("Document loaded", doc.is_loaded)
			
			-- Create permissions with all allowed (but password required to open)
			create permissions.make_all_permitted
			
			-- Create file ID
			create file_id.make_empty
			file_id.add (create {PDF_STRING}.make_literal ("HelloPassword123"))
			file_id.add (create {PDF_STRING}.make_literal ("HelloPassword123"))
			
			-- Create encrypt dictionary
			create encrypt_dict.make_empty
			encrypt_dict.put_name ("Standard", "Filter")
			encrypt_dict.put_number (1, "V")
			encrypt_dict.put_number (2, "R")
			encrypt_dict.put_number (40, "Length")
			encrypt_dict.put_number (permissions.flags, "P")
			
			-- Create security handler
			-- User password = "secret123" - REQUIRED to open the document
			-- Owner password = different from user password
			create handler.make (encrypt_dict, file_id, "")
			handler.compute_password_entries ("secret123", "owner_master_key")
			
			-- Compute and set U and O values as hex strings
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
			
			-- Set security handler
			doc.set_security_handler (handler)
			
			-- Write encrypted PDF
			doc.write_to_file (test_output_path ("hello_world_password_required.pdf").name)
			
			assert ("Password-protected PDF created", True)
		end

end
