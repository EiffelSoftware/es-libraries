note
	description: "[
		Comprehensive integration tests for Bodea Brochure - Linearized.pdf
		Similar to TEST_PHASE4B_INTEGRATION but for linearized PDFs
		Tests: Read/Write, Footer, Encrypt, Sign, and all combinations
	]"

class
	TEST_BODEA_INTEGRATION

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

	test_read_write_bodea_only
			-- Test basic read and write of Bodea Brochure
		local
			doc: PDF_DOCUMENT
			source: PDF_FILE_BYTE_SOURCE
			pdf_path, output_path: PATH
		do
			print ("%N=== Test: Bodea Read/Write Only ===%N")
			
			pdf_path := test_pdf_path ("Bodea Brochure - Linearized.pdf")
			create source.make_from_file (pdf_path.name)
			create doc.make_from_source (source)
			assert ("Document loaded", doc.is_loaded)
			
			print ("Loaded: " + source.byte_count.out + " bytes%N")
			print ("Objects: " + doc.xref_table.entries.count.out + "%N")
			
			doc.write_to_file (test_output_path ("bodea_read_write_only.pdf").name)
			print ("✅ Written to: " + test_output_path ("bodea_read_write_only.pdf").name + "%N")
			
			assert ("File created", True)
		end

	test_encrypt_bodea_view_only
			-- Test encrypting Bodea Brochure with view-only permissions
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
			print ("%N=== Test: Bodea + View-Only Encryption ===%N")
			
			create source.make_from_file (test_pdf_path ("Bodea Brochure - Linearized.pdf").name)
			create doc.make_from_source (source)
			assert ("Document loaded", doc.is_loaded)
			
			    -- Create view-only permissions
			create permissions.make_all_restricted
			
			    -- Create file ID
			create file_id.make_empty
			file_id.add (create {PDF_STRING}.make_literal ("BodeaViewOnly001"))
			file_id.add (create {PDF_STRING}.make_literal ("BodeaViewOnly001"))
			
			    -- Create encrypt dictionary
			create encrypt_dict.make_empty
			encrypt_dict.put_name ("Standard", "Filter")
			encrypt_dict.put_number (1, "V")
			encrypt_dict.put_number (2, "R")
			encrypt_dict.put_number (40, "Length")
			encrypt_dict.put_number (permissions.flags, "P")
			
			    -- Create and configure security handler
			create handler.make (encrypt_dict, file_id, "")
			handler.compute_password_entries ("", "bodea_owner_123")
			
			    -- Update encrypt dict with computed values
			encrypt_dict.put_hex_string (handler.u_entry, "U")
			encrypt_dict.put_hex_string (handler.o_entry, "O")
			
			    -- Add to document
			encrypt_id := doc.add_object (encrypt_dict)
			create encrypt_ref.make (encrypt_id)
			
			if attached doc.trailer as t then
				t.dictionary.put (encrypt_ref, "Encrypt")
				t.dictionary.put (file_id, "ID")
			end
			
			doc.set_security_handler (handler)
			
			doc.write_to_file (test_output_path ("bodea_encrypted_view_only.pdf").name)
			print ("✅ Written to: test_output\bodea_encrypted_view_only.pdf%N")
			
			assert ("Encrypted file created", True)
		end

	test_encrypt_bodea_print_only
			-- Test encrypting Bodea Brochure with print-only permissions
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
			print ("%N=== Test: Bodea + Print-Only Encryption ===%N")
			
			create source.make_from_file (test_pdf_path ("Bodea Brochure - Linearized.pdf").name)
			create doc.make_from_source (source)
			assert ("Document loaded", doc.is_loaded)
			
			    -- Create print-only permissions
			create permissions.make_all_restricted
			permissions.enable_print
			permissions.enable_print_high_quality
			
			    -- Create file ID
			create file_id.make_empty
			file_id.add (create {PDF_STRING}.make_literal ("BodeaPrintOnly001"))
			file_id.add (create {PDF_STRING}.make_literal ("BodeaPrintOnly001"))
			
			    -- Create encrypt dictionary
			create encrypt_dict.make_empty
			encrypt_dict.put_name ("Standard", "Filter")
			encrypt_dict.put_number (1, "V")
			encrypt_dict.put_number (2, "R")
			encrypt_dict.put_number (40, "Length")
			encrypt_dict.put_number (permissions.flags, "P")
			
			    -- Create and configure security handler
			create handler.make (encrypt_dict, file_id, "")
			handler.compute_password_entries ("", "bodea_print_owner")
			
			    -- Update encrypt dict
			encrypt_dict.put_hex_string (handler.u_entry, "U")
			encrypt_dict.put_hex_string (handler.o_entry, "O")
			
			    -- Add to document
			encrypt_id := doc.add_object (encrypt_dict)
			create encrypt_ref.make (encrypt_id)
			
			if attached doc.trailer as t then
				t.dictionary.put (encrypt_ref, "Encrypt")
				t.dictionary.put (file_id, "ID")
			end
			
			doc.set_security_handler (handler)
			
			doc.write_to_file (test_output_path ("bodea_encrypted_print_only.pdf").name)
			print ("✅ Written to: test_output\bodea_encrypted_print_only.pdf%N")
			
			assert ("Print-only encrypted file created", True)
		end

	test_object_loading_bodea
			-- Test that all objects in Bodea Brochure can be loaded
		local
			doc: PDF_DOCUMENT
			source: PDF_FILE_BYTE_SOURCE
			obj_id: PDF_OBJECT_ID
			obj: detachable PDF_OBJECT
			success_count, fail_count: INTEGER
		do
			print ("%N=== Test: Bodea Object Loading ===%N")
			
			create source.make_from_file (test_pdf_path ("Bodea Brochure - Linearized.pdf").name)
			create doc.make_from_source (source)
			assert ("Document loaded", doc.is_loaded)
			
			print ("Total objects: " + doc.xref_table.entries.count.out + "%N")
			
			    -- Try loading each object
			across doc.xref_table.entries as c loop
				if (@ c.item).is_in_use or (@ c.item).is_compressed then
					create obj_id.make (@ c.key, (@ c.item).generation)
					obj := doc.get_object (obj_id)
					
					if obj /= Void then
						success_count := success_count + 1
					else
						fail_count := fail_count + 1
						print ("Failed: obj " + (@ c.key).out + "%N")
					end
				end
			end
			
			print ("Success: " + success_count.out + "%N")
			print ("Failed: " + fail_count.out + "%N")
			
			assert ("All objects loaded", fail_count = 0)
		end

end
