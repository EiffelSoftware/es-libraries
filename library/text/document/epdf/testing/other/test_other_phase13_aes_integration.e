note
	description: "Integration tests for Phase 13 (AES Hardening & Interop)."

class
	TEST_OTHER_PHASE13_AES_INTEGRATION
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

	test_create_aes128_encrypted_pdf
			-- Create a PDF encrypted with AES-128 and write it to disk.
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
			file_id.add (create {PDF_STRING}.make_literal ("AES128TestID123"))
			file_id.add (create {PDF_STRING}.make_literal ("AES128TestID123"))

			-- Create encrypt dictionary
			encrypt_dict := create_aes128_encrypt_dict (permissions)

			-- Create security handler and compute password entries
			create handler.make (encrypt_dict, file_id, "")
			handler.compute_password_entries ("user_password", "owner_password")

			-- Add computed U and O values as hex strings
			encrypt_dict.put_hex_string (handler.u_entry, "U")
			encrypt_dict.put_hex_string (handler.o_entry, "O")

			-- Add encrypt dictionary to document as indirect object
			encrypt_id := doc.add_object (encrypt_dict)
			create encrypt_ref.make (encrypt_id)

			-- Add /Encrypt to trailer
			if attached doc.trailer as t then
				t.dictionary.put (encrypt_ref, "Encrypt")
				t.dictionary.put (file_id, "ID")
			end

			doc.set_security_handler (handler)

			-- Write encrypted PDF
			doc.write_to_file (test_output_path ("aes128_encrypted_basic.pdf").name)
			assert ("AES-128 basic encrypted PDF written", True)
		end

	test_read_back_aes128_encrypted_pdf
			-- Create AES-128 PDF, write to disk, and re-read with correct password.
		local
			doc_write: PDF_DOCUMENT
			source_write: PDF_FILE_BYTE_SOURCE
			handler_write: PDF_STANDARD_SECURITY_HANDLER
			permissions: PDF_PERMISSIONS
			encrypt_dict: PDF_DICTIONARY
			file_id: PDF_ARRAY
			encrypt_ref: PDF_REFERENCE
			encrypt_id: PDF_OBJECT_ID
			pdf_path: PATH
			out_path: PATH

			doc_read: PDF_DOCUMENT
			source_read: PDF_FILE_BYTE_SOURCE
		do
			-- Step 1: Create and write the encrypted PDF
			pdf_path := test_other_pdf_path ("probable-provable.pdf")
			create source_write.make_from_file (pdf_path.name)
			create doc_write.make_from_source (source_write)

			create permissions.make_all_permitted
			create file_id.make_empty
			file_id.add (create {PDF_STRING}.make_literal ("AESReadBackID123"))
			file_id.add (create {PDF_STRING}.make_literal ("AESReadBackID123"))

			encrypt_dict := create_aes128_encrypt_dict (permissions)

			create handler_write.make (encrypt_dict, file_id, "")
			handler_write.compute_password_entries ("user_pass", "owner_pass")

			encrypt_dict.put_hex_string (handler_write.u_entry, "U")
			encrypt_dict.put_hex_string (handler_write.o_entry, "O")

			encrypt_id := doc_write.add_object (encrypt_dict)
			create encrypt_ref.make (encrypt_id)

			if attached doc_write.trailer as t then
				t.dictionary.put (encrypt_ref, "Encrypt")
				t.dictionary.put (file_id, "ID")
			end

			doc_write.set_security_handler (handler_write)
			out_path := test_output_path ("aes128_read_back.pdf")
			doc_write.write_to_file (out_path.name)

			-- Step 2: Read back and authorize with user password
			create source_read.make_from_file (out_path.name)
			create doc_read.make_from_source (source_read)

			assert ("Read back document loaded", doc_read.is_loaded)
			assert ("Read back document is encrypted", doc_read.is_originally_encrypted)

			if attached {PDF_STANDARD_SECURITY_HANDLER} doc_read.original_security_handler as handler_read then
				handler_read.authorize ("user_pass")
				assert ("Authorized with user password", handler_read.is_authorized)
				assert ("Catalog not void after authorization", doc_read.catalog /= Void)
			else
				assert ("Security handler present and of standard type", False)
			end
		end

	test_aes128_footer_and_encrypt
			-- Add a footer to a document, encrypt it with AES-128, write, read back, and verify.
		local
			doc_write: PDF_DOCUMENT
			source_write: PDF_FILE_BYTE_SOURCE
			handler_write: PDF_STANDARD_SECURITY_HANDLER
			permissions: PDF_PERMISSIONS
			encrypt_dict: PDF_DICTIONARY
			file_id: PDF_ARRAY
			encrypt_ref: PDF_REFERENCE
			encrypt_id: PDF_OBJECT_ID
			footer_service: PDF_FOOTER_SERVICE
			out_path: PATH

			doc_read: PDF_DOCUMENT
			source_read: PDF_FILE_BYTE_SOURCE
		do
			-- Step 1: Create, stamp footer, and encrypt
			create source_write.make_from_file (test_other_pdf_path ("probable-provable.pdf").name)
			create doc_write.make_from_source (source_write)

			create footer_service.make
			footer_service.set_margin (20.0)
			footer_service.set_font_size (8.0)
			footer_service.add_footer_to_document (doc_write, "Signed by Antigravity AES-128")

			create permissions.make_all_permitted
			create file_id.make_empty
			file_id.add (create {PDF_STRING}.make_literal ("AESFooterTestID"))
			file_id.add (create {PDF_STRING}.make_literal ("AESFooterTestID"))

			encrypt_dict := create_aes128_encrypt_dict (permissions)

			create handler_write.make (encrypt_dict, file_id, "")
			handler_write.compute_password_entries ("user123", "owner123")

			encrypt_dict.put_hex_string (handler_write.u_entry, "U")
			encrypt_dict.put_hex_string (handler_write.o_entry, "O")

			encrypt_id := doc_write.add_object (encrypt_dict)
			create encrypt_ref.make (encrypt_id)

			if attached doc_write.trailer as t then
				t.dictionary.put (encrypt_ref, "Encrypt")
				t.dictionary.put (file_id, "ID")
			end

			doc_write.set_security_handler (handler_write)
			out_path := test_output_path ("aes128_footer_encrypted.pdf")
			doc_write.write_to_file (out_path.name)

			-- Step 2: Read back and verify
			create source_read.make_from_file (out_path.name)
			create doc_read.make_from_source (source_read)

			if attached {PDF_STANDARD_SECURITY_HANDLER} doc_read.original_security_handler as handler_read then
				handler_read.authorize ("user123")
				assert ("Authorized read back footer", handler_read.is_authorized)
				assert ("Catalog not void footer", doc_read.catalog /= Void)
			else
				assert ("Standard security handler present footer", False)
			end
		end

	test_aes128_wrong_password_fails
			-- Create AES-128 PDF, and verify authorization fails with wrong password.
		local
			doc_write: PDF_DOCUMENT
			source_write: PDF_FILE_BYTE_SOURCE
			handler_write: PDF_STANDARD_SECURITY_HANDLER
			permissions: PDF_PERMISSIONS
			encrypt_dict: PDF_DICTIONARY
			file_id: PDF_ARRAY
			encrypt_ref: PDF_REFERENCE
			encrypt_id: PDF_OBJECT_ID
			out_path: PATH

			doc_read: PDF_DOCUMENT
			source_read: PDF_FILE_BYTE_SOURCE
		do
			-- Step 1: Create and write
			create source_write.make_from_file (test_other_pdf_path ("probable-provable.pdf").name)
			create doc_write.make_from_source (source_write)

			create permissions.make_all_permitted
			create file_id.make_empty
			file_id.add (create {PDF_STRING}.make_literal ("AESWrongPassID"))
			file_id.add (create {PDF_STRING}.make_literal ("AESWrongPassID"))

			encrypt_dict := create_aes128_encrypt_dict (permissions)

			create handler_write.make (encrypt_dict, file_id, "")
			handler_write.compute_password_entries ("correct_user", "correct_owner")

			encrypt_dict.put_hex_string (handler_write.u_entry, "U")
			encrypt_dict.put_hex_string (handler_write.o_entry, "O")

			encrypt_id := doc_write.add_object (encrypt_dict)
			create encrypt_ref.make (encrypt_id)

			if attached doc_write.trailer as t then
				t.dictionary.put (encrypt_ref, "Encrypt")
				t.dictionary.put (file_id, "ID")
			end

			doc_write.set_security_handler (handler_write)
			out_path := test_output_path ("aes128_wrong_password.pdf")
			doc_write.write_to_file (out_path.name)

			-- Step 2: Read back and attempt wrong password
			create source_read.make_from_file (out_path.name)
			create doc_read.make_from_source (source_read)

			if attached {PDF_STANDARD_SECURITY_HANDLER} doc_read.original_security_handler as handler_read then
				handler_read.authorize ("wrong_user_pass")
				assert ("Authorization failed with wrong user password", not handler_read.is_authorized)

				handler_read.authorize ("correct_user")
				assert ("Authorization succeeded with correct user password", handler_read.is_authorized)
			else
				assert ("Standard security handler present", False)
			end
		end

	test_aes128_string_decryption
			-- Write known string values to encrypted document, read back, and verify they are decrypted correctly.
		local
			doc_write: PDF_DOCUMENT
			source_write: PDF_FILE_BYTE_SOURCE
			handler_write: PDF_STANDARD_SECURITY_HANDLER
			permissions: PDF_PERMISSIONS
			encrypt_dict: PDF_DICTIONARY
			file_id: PDF_ARRAY
			encrypt_ref: PDF_REFERENCE
			encrypt_id: PDF_OBJECT_ID
			out_path: PATH

			doc_read: PDF_DOCUMENT
			source_read: PDF_FILE_BYTE_SOURCE
		do
			-- Step 1: Create and write document with specific Info dictionary string
			create source_write.make_from_file (test_other_pdf_path ("probable-provable.pdf").name)
			create doc_write.make_from_source (source_write)

			if attached doc_write.trailer as t and then attached {PDF_REFERENCE} t.dictionary.item ("Info") as info_ref then
				if attached {PDF_DICTIONARY} doc_write.get_object (info_ref.object_id) as info then
					info.put_string ("AES-128 Encrypted Title", "Title")
				end
			end

			create permissions.make_all_permitted
			create file_id.make_empty
			file_id.add (create {PDF_STRING}.make_literal ("AESStringID"))
			file_id.add (create {PDF_STRING}.make_literal ("AESStringID"))

			encrypt_dict := create_aes128_encrypt_dict (permissions)

			create handler_write.make (encrypt_dict, file_id, "")
			handler_write.compute_password_entries ("user_string", "owner_string")

			encrypt_dict.put_hex_string (handler_write.u_entry, "U")
			encrypt_dict.put_hex_string (handler_write.o_entry, "O")

			encrypt_id := doc_write.add_object (encrypt_dict)
			create encrypt_ref.make (encrypt_id)

			if attached doc_write.trailer as t then
				t.dictionary.put (encrypt_ref, "Encrypt")
				t.dictionary.put (file_id, "ID")
			end

			doc_write.set_security_handler (handler_write)
			out_path := test_output_path ("aes128_string_test.pdf")
			doc_write.write_to_file (out_path.name)

			-- Step 2: Read back and verify the string is decrypted correctly
			create source_read.make_from_file (out_path.name)
			create doc_read.make_from_source (source_read)

			if attached {PDF_STANDARD_SECURITY_HANDLER} doc_read.original_security_handler as handler_read then
				handler_read.authorize ("user_string")
				assert ("Authorized string read", handler_read.is_authorized)

				if attached doc_read.trailer as t and then attached {PDF_REFERENCE} t.dictionary.item ("Info") as info_ref then
					if attached {PDF_DICTIONARY} doc_read.get_object (info_ref.object_id) as info then
						if attached {PDF_STRING} info.item ("Title") as title then
							assert ("String value decrypted successfully", title.value.is_equal ("AES-128 Encrypted Title"))
						else
							assert ("Title key is present and is a string", False)
						end
					else
						assert ("Info object loaded as dictionary", False)
					end
				else
					assert ("Info reference present in trailer", False)
				end
			else
				assert ("Standard security handler present", False)
			end
		end

	test_aes128_stream_decryption
			-- Write known stream content to encrypted document, read back, and verify stream is decrypted correctly.
		local
			doc_write: PDF_DOCUMENT
			source_write: PDF_FILE_BYTE_SOURCE
			handler_write: PDF_STANDARD_SECURITY_HANDLER
			permissions: PDF_PERMISSIONS
			encrypt_dict: PDF_DICTIONARY
			file_id: PDF_ARRAY
			encrypt_ref: PDF_REFERENCE
			encrypt_id: PDF_OBJECT_ID
			out_path: PATH
			new_stream: PDF_STREAM
			new_stream_ref: PDF_REFERENCE
			new_stream_id: PDF_OBJECT_ID

			doc_read: PDF_DOCUMENT
			source_read: PDF_FILE_BYTE_SOURCE
		do
			-- Step 1: Create and write document with a custom stream
			create source_write.make_from_file (test_other_pdf_path ("probable-provable.pdf").name)
			create doc_write.make_from_source (source_write)

			create new_stream.make ("BT /F1 12 Tf 72 712 Td (Hello Antigravity AES Stream) Tj ET")
			new_stream_id := doc_write.add_object (new_stream)
			create new_stream_ref.make (new_stream_id)

			-- Attach it to the catalog or trailer for preservation, or just keep it in document objects
			-- We will put it in trailer under /TempStream so it is written and indexed
			if attached doc_write.trailer as t then
				t.dictionary.put (new_stream_ref, "TempStream")
			end

			create permissions.make_all_permitted
			create file_id.make_empty
			file_id.add (create {PDF_STRING}.make_literal ("AESStreamID"))
			file_id.add (create {PDF_STRING}.make_literal ("AESStreamID"))

			encrypt_dict := create_aes128_encrypt_dict (permissions)

			create handler_write.make (encrypt_dict, file_id, "")
			handler_write.compute_password_entries ("user_stream", "owner_stream")

			encrypt_dict.put_hex_string (handler_write.u_entry, "U")
			encrypt_dict.put_hex_string (handler_write.o_entry, "O")

			encrypt_id := doc_write.add_object (encrypt_dict)
			create encrypt_ref.make (encrypt_id)

			if attached doc_write.trailer as t then
				t.dictionary.put (encrypt_ref, "Encrypt")
				t.dictionary.put (file_id, "ID")
			end

			doc_write.set_security_handler (handler_write)
			out_path := test_output_path ("aes128_stream_test.pdf")
			doc_write.write_to_file (out_path.name)

			-- Step 2: Read back and verify the stream is decrypted correctly
			create source_read.make_from_file (out_path.name)
			create doc_read.make_from_source (source_read)

			if attached {PDF_STANDARD_SECURITY_HANDLER} doc_read.original_security_handler as handler_read then
				handler_read.authorize ("user_stream")
				assert ("Authorized stream read", handler_read.is_authorized)

				if attached doc_read.trailer as t and then attached {PDF_REFERENCE} t.dictionary.item ("TempStream") as ts_ref then
					if attached {PDF_STREAM} doc_read.get_object (ts_ref.object_id) as ts then
						assert ("Stream content decrypted successfully", ts.content.is_equal ("BT /F1 12 Tf 72 712 Td (Hello Antigravity AES Stream) Tj ET"))
					else
						assert ("TempStream loaded as stream", False)
					end
				else
					assert ("TempStream reference present in trailer", False)
				end
			else
				assert ("Standard security handler present", False)
			end
		end

feature {NONE} -- Helper Functions

	create_aes128_encrypt_dict (a_permissions: PDF_PERMISSIONS): PDF_DICTIONARY
			-- Create an AES-128 encrypt dictionary with the given permissions.
		local
			cf_dict: PDF_DICTIONARY
			std_cf: PDF_DICTIONARY
		do
			create Result.make_empty
			Result.put_name ("Standard", "Filter")
			Result.put_number (4, "V")
			Result.put_number (4, "R")
			Result.put_number (128, "Length")
			Result.put_number (a_permissions.flags, "P")
			Result.put_name ("StdCF", "StmF")
			Result.put_name ("StdCF", "StrF")

			create std_cf.make_empty
			std_cf.put_name ("AESV2", "CFM")
			std_cf.put_name ("DocOpen", "AuthEvent")
			std_cf.put_number (16, "Length")

			create cf_dict.make_empty
			cf_dict.put (std_cf, "StdCF")
			Result.put (cf_dict, "CF")
		end

end
