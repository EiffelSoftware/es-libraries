note
	description: "Mock security handler for testing integration."

class
	MOCK_SECURITY_HANDLER

inherit
	PDF_SECURITY_HANDLER

feature -- Access

	filter_name: STRING_8
		do
			Result := "Mock"
		end

	encryption_key_length: INTEGER
		do
			Result := 40
		end

feature -- Status Report

	is_authorized: BOOLEAN
		do
			Result := True
		end

feature -- Operations

	authorize (a_password: STRING_8)
		do
			-- Always authorized
		end

	encrypt_string (a_string: STRING_8; obj_num, gen_num: INTEGER): STRING_8
		do
			-- Simple Mock Encryption: Prepend "ENC_"
			-- Real encryption would change bytes.
			Result := "ENC_" + a_string
		end

	decrypt_string (a_string: STRING_8; obj_num, gen_num: INTEGER): STRING_8
		do
			if a_string.starts_with ("ENC_") then
				Result := a_string.substring (5, a_string.count)
			else
				Result := a_string
			end
		end

	encrypt_stream (a_data: STRING_8; obj_num, gen_num: INTEGER): STRING_8
		do
			Result := encrypt_string (a_data, obj_num, gen_num)
		end

	decrypt_stream (a_data: STRING_8; obj_num, gen_num: INTEGER): STRING_8
		do
			Result := decrypt_string (a_data, obj_num, gen_num)
		end

end
