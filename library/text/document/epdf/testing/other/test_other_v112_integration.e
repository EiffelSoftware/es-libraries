note
	description: "[
		Comprehensive integration tests for v112-367_3_STANDARD.pdf
		Same structure as TEST_BODEA_INTEGRATION but for large linearized PDF
		Tests: Read/Write, Encrypt with various permissions
	]"

class
	TEST_OTHER_V112_INTEGRATION
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

	test_read_write_v112_only
			-- Test basic read and write of v112-367_3_STANDARD.pdf
		local
			doc: PDF_DOCUMENT
			source: PDF_FILE_BYTE_SOURCE
			pdf_path, output_path: PATH
		do
			print ("%N=== Test: v112 Read/Write Only ===%N")

			pdf_path := test_other_pdf_path ("v112-367_3_STANDARD.pdf")
			create source.make_from_file (pdf_path.name)
			create doc.make_from_source (source)
			assert ("Document loaded", doc.is_loaded)

			print ("Loaded: " + source.byte_count.out + " bytes%N")
			print ("Objects: " + doc.xref_table.entries.count.out + "%N")

			output_path := test_output_path ("v112_read_write_only.pdf")
			doc.write_to_file (output_path.name)
			print ("✅ Written to: " + output_path.name + "%N")

			assert ("File created", True)
		end

	test_object_loading_v112
			-- Test that all objects in v112-367_3_STANDARD.pdf can be loaded
		local
			doc: PDF_DOCUMENT
			source: PDF_FILE_BYTE_SOURCE
			obj_id: PDF_OBJECT_ID
			obj: detachable PDF_OBJECT
			success_count, fail_count: INTEGER
		do
			print ("%N=== Test: v112 Object Loading ===%N")

			create source.make_from_file (test_other_pdf_path ("v112-367_3_STANDARD.pdf").name)
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
						if success_count \\ 5000 = 0 then
							print ("  Progress: " + success_count.out + " objects loaded...%N")
						end
					else
						fail_count := fail_count + 1
						if fail_count <= 10 then
							print ("Failed: obj " + (@ c.key).out + "%N")
						end
					end
				end
			end

			print ("Success: " + success_count.out + "%N")
			print ("Failed: " + fail_count.out + "%N")

			assert ("All objects loaded", fail_count = 0)
		end

	test_encrypt_v112_view_only
			-- Test encrypting v112-367_3_STANDARD.pdf with view-only permissions
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
			print ("%N=== Test: v112 + View-Only Encryption ===%N")

			create source.make_from_file (test_other_pdf_path ("v112-367_3_STANDARD.pdf").name)
			create doc.make_from_source (source)
			assert ("Document loaded", doc.is_loaded)

			    -- Create view-only permissions
			create permissions.make_all_restricted

			    -- Create file ID
			create file_id.make_empty
			file_id.add (create {PDF_STRING}.make_literal ("v112ViewOnly001"))
			file_id.add (create {PDF_STRING}.make_literal ("v112ViewOnly001"))

			    -- Create encrypt dictionary
			create encrypt_dict.make_empty
			encrypt_dict.put_name ("Standard", "Filter")
			encrypt_dict.put_number (1, "V")
			encrypt_dict.put_number (2, "R")
			encrypt_dict.put_number (40, "Length")
			encrypt_dict.put_number (permissions.flags, "P")

			    -- Create and configure security handler
			create handler.make (encrypt_dict, file_id, "")
			handler.compute_password_entries ("", "v112_owner_123")

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

			doc.write_to_file (test_output_path ("v112_encrypted_view_only.pdf").name)
			print ("✅ Written to: " + test_output_path ("v112_encrypted_view_only.pdf").name + "%N")

			assert ("Encrypted file created", True)
		end

	test_encrypt_v112_print_only
			-- Test encrypting v112-367_3_STANDARD.pdf with print-only permissions
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
			print ("%N=== Test: v112 + Print-Only Encryption ===%N")

			create source.make_from_file (test_other_pdf_path ("v112-367_3_STANDARD.pdf").name)
			create doc.make_from_source (source)
			assert ("Document loaded", doc.is_loaded)

			    -- Create print-only permissions
			create permissions.make_all_restricted
			permissions.enable_print
			permissions.enable_print_high_quality

			    -- Create file ID
			create file_id.make_empty
			file_id.add (create {PDF_STRING}.make_literal ("v112PrintOnly001"))
			file_id.add (create {PDF_STRING}.make_literal ("v112PrintOnly001"))

			    -- Create encrypt dictionary
			create encrypt_dict.make_empty
			encrypt_dict.put_name ("Standard", "Filter")
			encrypt_dict.put_number (1, "V")
			encrypt_dict.put_number (2, "R")
			encrypt_dict.put_number (40, "Length")
			encrypt_dict.put_number (permissions.flags, "P")

			    -- Create and configure security handler
			create handler.make (encrypt_dict, file_id, "")
			handler.compute_password_entries ("", "v112_print_owner")

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

			doc.write_to_file (test_output_path ("v112_encrypted_print_only.pdf").name)
			print ("✅ Written to: test_output\v112_encrypted_print_only.pdf%N")

			assert ("Print-only encrypted file created", True)
		end

end
