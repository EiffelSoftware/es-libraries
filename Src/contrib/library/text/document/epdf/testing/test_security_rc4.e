note
	description: "Test RC4 implementation."

class
	TEST_SECURITY_RC4

inherit
	EQA_TEST_SET

feature -- Tests

	test_rc4_basic_encryption
			-- Test basic RC4 encryption/decryption.
		local
			rc4: PDF_RC4
			plaintext, ciphertext, decrypted: STRING
		do
			plaintext := "Hello, World!"
			
			-- Encrypt
			create rc4.make ("SecretKey")
			ciphertext := rc4.process_string (plaintext)
			
			-- Decrypt (RC4 is symmetric)
			create rc4.make ("SecretKey")
			decrypted := rc4.process_string (ciphertext)
			
			assert ("RC4 decryption matches plaintext", decrypted.is_equal (plaintext))
		end

	test_rc4_empty_string
			-- RC4 should handle empty strings.
		local
			rc4: PDF_RC4
			result_str: STRING
		do
			create rc4.make ("Key")
			result_str := rc4.process_string ("")
			assert ("RC4 empty string", result_str.is_empty)
		end

	test_rc4_in_place_transform
			-- Test in-place transformation.
		local
			rc4_enc, rc4_dec: PDF_RC4
			data, original: STRING
		do
			original := "Test Data 123"
			data := original.twin
			
			-- Encrypt in place
			create rc4_enc.make ("TestKey")
			rc4_enc.transform_in_place (data)
			
			-- Should be different now
			assert ("RC4 in-place changed data", not data.is_equal (original))
			
			-- Decrypt in place
			create rc4_dec.make ("TestKey")
			rc4_dec.transform_in_place (data)
			
			-- Should match original
			assert ("RC4 in-place round-trip", data.is_equal (original))
		end

end
