note
	description: "Debug test to trace encryption value lengths."

class
	TEST_DEBUG_ENCRYPTION

inherit
	EQA_TEST_SET

feature -- Test routines

	test_u_o_value_lengths
			-- Debug U and O value lengths.
		local
			handler: PDF_STANDARD_SECURITY_HANDLER
			permissions: PDF_PERMISSIONS
			encrypt_dict: PDF_DICTIONARY
			file_id: PDF_ARRAY
		do
			-- Create permissions
			create permissions.make_all_permitted
			
			-- Create file ID
			create file_id.make_empty
			file_id.add (create {PDF_STRING}.make_literal ("TestID"))
			file_id.add (create {PDF_STRING}.make_literal ("TestID"))
			
			-- Create encrypt dictionary
			create encrypt_dict.make_empty
			encrypt_dict.put_name ("Standard", "Filter")
			encrypt_dict.put_number (1, "V")
			encrypt_dict.put_number (2, "R")
			encrypt_dict.put_number (40, "Length")
			encrypt_dict.put_number (permissions.flags, "P")
			
			-- Create security handler
			create handler.make (encrypt_dict, file_id, "")
			
			-- Debug: print revision
			print ("Revision: " + handler.current_revision.out + "%N")
			
			-- Compute password entries
			handler.compute_password_entries ("test", "test")
			
			-- Debug: print lengths
			print ("U entry length: " + handler.u_entry.count.out + " (expected 32)%N")
			print ("O entry length: " + handler.o_entry.count.out + " (expected 32)%N")
			
			-- Print padding string length via RC4 test
			-- The U value for rev2 is RC4(padding) so if U=64 bytes, padding=64 bytes
			print ("If U length is wrong, the padding_string is likely the issue%N")
			
			-- Assertions
			assert ("U entry is 32 bytes", handler.u_entry.count = 32)
			assert ("O entry is 32 bytes", handler.o_entry.count = 32)
		end

feature -- Access for testing
	
	revision_from_handler (h: PDF_STANDARD_SECURITY_HANDLER): INTEGER
		do
			-- Can't access this directly, need to check output
			Result := 0
		end

end
