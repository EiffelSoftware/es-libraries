note
	description: "Comprehensive test suite for AES encryption/decryption (PDF security)."

class
	TEST_SECURITY_AES

inherit
	EQA_TEST_SET

feature -- Basic Round-Trip Tests

	test_aes_128_basic_encryption
			-- Test basic AES-128 encryption/decryption.
		local
			aes: PDF_AES_HANDLER
			key, iv: STRING_8
			plaintext, ciphertext, decrypted: STRING_8
		do
			create aes.make_128
			key := "0123456789ABCDEF" -- 16 bytes for AES-128
			iv := "FEDCBA9876543210"  -- 16 bytes IV

			plaintext := "Hello, World!123" -- 16 bytes (one block)

			-- Encrypt
			ciphertext := aes.encrypt_bytes (plaintext, key, iv)

			-- Decrypt
			decrypted := aes.decrypt_bytes (ciphertext, key, iv)

			assert ("AES-128 decryption matches plaintext", decrypted.is_equal (plaintext))
		end

	test_aes_256_basic_encryption
			-- Test basic AES-256 encryption/decryption.
		local
			aes: PDF_AES_HANDLER
			key, iv: STRING_8
			plaintext, ciphertext, decrypted: STRING_8
		do
			create aes.make_256
			key := "0123456789ABCDEF0123456789ABCDEF" -- 32 bytes for AES-256
			iv := "FEDCBA9876543210"  -- 16 bytes IV

			plaintext := "Hello, World!123" -- 16 bytes (one block)

			-- Encrypt
			ciphertext := aes.encrypt_bytes (plaintext, key, iv)

			-- Decrypt
			decrypted := aes.decrypt_bytes (ciphertext, key, iv)

			assert ("AES-256 decryption matches plaintext", decrypted.is_equal (plaintext))
		end

feature -- NIST Known-Answer Tests (Must-Have)

	test_aes_128_nist_known_vector
			-- AES-128 CBC known-answer test using NIST test vector.
			-- Source: NIST SP 800-38A, F.2.1 CBC-AES128.Encrypt
		local
			aes: PDF_AES_HANDLER
			key, iv, plaintext, expected_ciphertext, actual_ciphertext: STRING_8
		do
			create aes.make_128

			-- NIST test vector (hex values converted to bytes)
			key := hex_to_bytes ("2b7e151628aed2a6abf7158809cf4f3c")
			iv := hex_to_bytes ("000102030405060708090a0b0c0d0e0f")
			plaintext := hex_to_bytes ("6bc1bee22e409f96e93d7e117393172a")
			expected_ciphertext := hex_to_bytes ("7649abac8119b246cee98e9b12e9197d")

			-- Encrypt (note: we need to handle padding separately for exact comparison)
			actual_ciphertext := aes.encrypt_bytes (plaintext, key, iv)

			-- The first 16 bytes should match expected (before padding)
			assert ("NIST AES-128 CBC ciphertext first block",
				actual_ciphertext.count >= 16 and then
				actual_ciphertext.substring (1, 16).is_equal (expected_ciphertext))
		end

	test_aes_256_nist_known_vector
			-- AES-256 CBC known-answer test using NIST test vector.
			-- Source: NIST SP 800-38A, F.2.5 CBC-AES256.Encrypt
		local
			aes: PDF_AES_HANDLER
			key, iv, plaintext, expected_ciphertext, actual_ciphertext: STRING_8
		do
			create aes.make_256

			-- NIST test vector for AES-256 CBC
			key := hex_to_bytes ("603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4")
			iv := hex_to_bytes ("000102030405060708090a0b0c0d0e0f")
			plaintext := hex_to_bytes ("6bc1bee22e409f96e93d7e117393172a")
			expected_ciphertext := hex_to_bytes ("f58c4c04d6e5f1ba779eabfb5f7bfbd6")

			-- Encrypt
			actual_ciphertext := aes.encrypt_bytes (plaintext, key, iv)

			-- First 16 bytes should match expected
			assert ("NIST AES-256 CBC ciphertext first block",
				actual_ciphertext.count >= 16 and then
				actual_ciphertext.substring (1, 16).is_equal (expected_ciphertext))
		end

feature -- Binary Safety Tests (Must-Have)

	test_aes_binary_safety_zero_bytes
			-- Test encryption with zero bytes (null characters).
		local
			aes: PDF_AES_HANDLER
			key, plaintext, encrypted, decrypted: STRING_8
		do
			create aes.make_128
			key := "BinarySafeKey123"

			-- Plaintext with zero bytes
			plaintext := "Before%UMiddle%UAfter"

			encrypted := aes.encrypt_pdf_stream (plaintext, key)
			decrypted := aes.decrypt_pdf_stream (encrypted, key)

			assert ("Binary round-trip with zero bytes", decrypted.is_equal (plaintext))
			assert ("Zero byte preserved", decrypted.has ('%U'))
		end

	test_aes_binary_safety_high_bytes
			-- Test encryption with high byte values (>= 0x80).
		local
			aes: PDF_AES_HANDLER
			key, plaintext, encrypted, decrypted: STRING_8
			i: INTEGER
		do
			create aes.make_128
			key := "HighByteTestKey1"

			-- Create plaintext with bytes 0x80 to 0xFF
			create plaintext.make (128)
			from i := 128 until i > 255 loop
				plaintext.append_character (i.to_character_8)
				i := i + 1
			end

			encrypted := aes.encrypt_pdf_stream (plaintext, key)
			decrypted := aes.decrypt_pdf_stream (encrypted, key)

			assert ("Binary round-trip with high bytes", decrypted.is_equal (plaintext))
			assert ("Length preserved", decrypted.count = plaintext.count)
		end

	test_aes_binary_safety_all_byte_values
			-- Test encryption with all possible byte values (0x00 to 0xFF).
		local
			aes: PDF_AES_HANDLER
			key, plaintext, encrypted, decrypted: STRING_8
			i: INTEGER
		do
			create aes.make_128
			key := "AllBytesTestKey1"

			-- Create plaintext with all 256 byte values
			create plaintext.make (256)
			from i := 0 until i > 255 loop
				plaintext.append_character (i.to_character_8)
				i := i + 1
			end

			encrypted := aes.encrypt_pdf_stream (plaintext, key)
			decrypted := aes.decrypt_pdf_stream (encrypted, key)

			assert ("Binary round-trip with all byte values", decrypted.is_equal (plaintext))
			assert ("All 256 bytes preserved", decrypted.count = 256)
		end

feature -- Padding Validation Tests (Must-Have)

	test_aes_padding_exact_block
			-- Test PKCS#7 padding when plaintext is exact multiple of block size.
			-- Should add a full padding block (16 bytes of 0x10).
		local
			aes: PDF_AES_HANDLER
			key, iv, plaintext, encrypted: STRING_8
		do
			create aes.make_128
			key := "PaddingTestKey16"
			iv := "1234567890123456"

			-- Exactly 16 bytes (one block)
			plaintext := "ExactlyOneBlock!"
			assert ("Plaintext is 16 bytes", plaintext.count = 16)

			encrypted := aes.encrypt_bytes (plaintext, key, iv)

			-- Ciphertext should be 32 bytes (original block + padding block)
			assert ("Padding adds full block", encrypted.count = 32)
		end

	test_aes_padding_various_lengths
			-- Test padding for plaintext of lengths 1 to 17 bytes.
		local
			aes: PDF_AES_HANDLER
			key, iv, plaintext, encrypted, decrypted: STRING_8
			i: INTEGER
			expected_ciphertext_len: INTEGER
		do
			create aes.make_128
			key := "PaddingLenTest16"
			iv := "IVForPaddingTest"

			from i := 1 until i > 17 loop
				-- Create plaintext of length i
				create plaintext.make_filled ('X', i)

				encrypted := aes.encrypt_bytes (plaintext, key, iv)
				decrypted := aes.decrypt_bytes (encrypted, key, iv)

				-- Expected: round up to next multiple of 16
				if i \\ 16 = 0 then
					expected_ciphertext_len := i + 16 -- Full padding block
				else
					expected_ciphertext_len := ((i // 16) + 1) * 16
				end

				assert ("Correct ciphertext length for size " + i.out,
					encrypted.count = expected_ciphertext_len)
				assert ("Round-trip for size " + i.out, decrypted.is_equal (plaintext))

				i := i + 1
			end
		end

feature -- Tamper Detection Tests (Must-Have)

	test_aes_tamper_ciphertext_modification
			-- Test that modifying ciphertext produces different/invalid decryption.
		local
			aes: PDF_AES_HANDLER
			key, plaintext, encrypted, tampered, decrypted_tampered: STRING_8
			byte_pos: INTEGER
		do
			create aes.make_128
			key := "TamperTestKey123"
			plaintext := "Sensitive data that should be protected"

			encrypted := aes.encrypt_pdf_stream (plaintext, key)

			-- Tamper with a byte in the ciphertext (after IV, in encrypted data)
			tampered := encrypted.twin
			byte_pos := 20 -- Position in encrypted data (after 16-byte IV)
			if byte_pos <= tampered.count then
				tampered.put ((tampered.code (byte_pos).bit_xor (0xFF)).to_character_8, byte_pos)
			end

			-- Decryption should produce different result
			decrypted_tampered := aes.decrypt_pdf_stream (tampered, key)

			assert ("Tampered ciphertext produces different result",
				not decrypted_tampered.is_equal (plaintext))
		end

	test_aes_tamper_iv_modification
			-- Test that modifying IV produces different decryption.
		local
			aes: PDF_AES_HANDLER
			key, plaintext, encrypted, tampered, decrypted_tampered: STRING_8
		do
			create aes.make_128
			key := "IVTamperTestKey1"
			plaintext := "Test data for IV tampering"

			encrypted := aes.encrypt_pdf_stream (plaintext, key)

			-- Tamper with first byte of IV
			tampered := encrypted.twin
			tampered.put ((tampered.code (1).bit_xor (0x01)).to_character_8, 1)

			-- Decryption should produce different result (IV affects first block)
			decrypted_tampered := aes.decrypt_pdf_stream (tampered, key)

			assert ("IV tampering affects decryption",
				not decrypted_tampered.is_equal (plaintext))
		end

feature -- IV Randomness Tests (Strongly Recommended)

	test_aes_iv_randomness
			-- Test that encrypting same plaintext twice produces different ciphertext.
		local
			aes: PDF_AES_HANDLER
			key, plaintext, encrypted1, encrypted2: STRING_8
		do
			create aes.make_128
			key := "IVRandomnessKey1"
			plaintext := "Same content encrypted twice"

			encrypted1 := aes.encrypt_pdf_stream (plaintext, key)
			encrypted2 := aes.encrypt_pdf_stream (plaintext, key)

			-- Ciphertexts should differ (different random IVs)
			assert ("Different IVs produce different ciphertext",
				not encrypted1.is_equal (encrypted2))

			-- First 16 bytes (IV) should differ
			assert ("IVs are different",
				not encrypted1.substring (1, 16).is_equal (encrypted2.substring (1, 16)))
		end

	test_aes_iv_exactly_16_bytes
			-- Test that prepended IV is exactly 16 bytes.
		local
			aes: PDF_AES_HANDLER
			key, plaintext, encrypted: STRING_8
		do
			create aes.make_128
			key := "IVLengthTestKey1"
			plaintext := "Test content"

			encrypted := aes.encrypt_pdf_stream (plaintext, key)

			-- Must have at least IV (16) + encrypted data
			assert ("IV present (at least 16 bytes)", encrypted.count >= 16)

			-- Encrypted length should be IV + padded plaintext
			assert ("Correct total length",
				encrypted.count = 16 + (((plaintext.count // 16) + 1) * 16))
		end

feature -- AES-256 Parity Tests (Strongly Recommended)

	test_aes_256_pdf_stream_round_trip
			-- Test PDF stream encryption with AES-256.
		local
			aes: PDF_AES_HANDLER
			key, plaintext, encrypted, decrypted: STRING_8
		do
			create aes.make_256
			key := "0123456789ABCDEF0123456789ABCDEF" -- 32 bytes

			plaintext := "PDF stream for AES-256 encryption test"

			encrypted := aes.encrypt_pdf_stream (plaintext, key)
			decrypted := aes.decrypt_pdf_stream (encrypted, key)

			assert ("AES-256 PDF stream round-trip", decrypted.is_equal (plaintext))
		end

	test_aes_256_multi_block
			-- Test AES-256 with multi-block data.
		local
			aes: PDF_AES_HANDLER
			key, plaintext, encrypted, decrypted: STRING_8
			i: INTEGER
		do
			create aes.make_256
			key := "MultiBlock256BitKeyForAES256Test" -- 32 bytes

			-- Create 256-byte plaintext
			create plaintext.make (256)
			from i := 1 until i > 256 loop
				plaintext.append_character ((('A').code.to_integer_32 + (i \\ 26)).to_character_8)
				i := i + 1
			end

			encrypted := aes.encrypt_pdf_stream (plaintext, key)
			decrypted := aes.decrypt_pdf_stream (encrypted, key)

			assert ("AES-256 multi-block round-trip", decrypted.is_equal (plaintext))
		end

	test_aes_256_binary_safety
			-- Test AES-256 with all byte values.
		local
			aes: PDF_AES_HANDLER
			key, plaintext, encrypted, decrypted: STRING_8
			i: INTEGER
		do
			create aes.make_256
			key := "BinarySafe256BitKeyForTesting!XY" -- 32 bytes

			-- All 256 byte values
			create plaintext.make (256)
			from i := 0 until i > 255 loop
				plaintext.append_character (i.to_character_8)
				i := i + 1
			end

			encrypted := aes.encrypt_pdf_stream (plaintext, key)
			decrypted := aes.decrypt_pdf_stream (encrypted, key)

			assert ("AES-256 binary safety", decrypted.is_equal (plaintext))
		end

feature -- Error Contract Tests (Strongly Recommended)

	test_aes_key_length_validation
			-- Verify key length constants are correct.
		local
			aes_128, aes_256: PDF_AES_HANDLER
		do
			create aes_128.make_128
			create aes_256.make_256

			assert ("AES-128 key length", aes_128.key_length = 16)
			assert ("AES-256 key length", aes_256.key_length = 32)
			assert ("Block length is 16", aes_128.block_length = 16)
			assert ("Block length same for 256", aes_256.block_length = 16)
		end

	test_aes_truncated_ciphertext
			-- Test validation of truncated or malformed ciphertext.
			-- Uses `is_valid_encrypted_stream` to verify input validation.
		local
			aes: PDF_AES_HANDLER
			iv_only, too_short, misaligned, valid_minimal: STRING_8
		do
			create aes.make_128

			-- Case 1: Exactly 16 bytes = IV only, no encrypted data
			iv_only := "1234567890123456"
			assert ("IV-only data is 16 bytes", iv_only.count = 16)
			assert ("IV-only is invalid", not aes.is_valid_encrypted_stream (iv_only))

			-- Case 2: Less than 16 bytes
			too_short := "short"
			assert ("Too short is invalid", not aes.is_valid_encrypted_stream (too_short))

			-- Case 3: Misaligned (17 bytes after IV would be misaligned)
			misaligned := "1234567890123456" + "X"
			assert ("Misaligned is invalid", not aes.is_valid_encrypted_stream (misaligned))

			-- Case 4: 31 bytes (IV + 15 bytes = not block-aligned)
			assert ("31 bytes is invalid", not aes.is_valid_encrypted_stream (create {STRING_8}.make_filled ('X', 31)))

			-- Case 5: Valid minimal (IV + one block = 32 bytes)
			valid_minimal := create {STRING_8}.make_filled ('Y', 32)
			assert ("32 bytes is valid", aes.is_valid_encrypted_stream (valid_minimal))
		end

feature -- PDF Stream/String Tests

	test_aes_pdf_stream_round_trip
			-- Test PDF stream encryption where IV is prepended.
		local
			aes: PDF_AES_HANDLER
			key, plaintext, encrypted, decrypted: STRING_8
		do
			create aes.make_128
			key := "0123456789ABCDEF" -- 16 bytes

			plaintext := "This is a PDF stream content that will be encrypted using AES."

			encrypted := aes.encrypt_pdf_stream (plaintext, key)

			assert ("Encrypted has IV", encrypted.count >= 16 + plaintext.count)

			decrypted := aes.decrypt_pdf_stream (encrypted, key)

			assert ("PDF stream round-trip", decrypted.is_equal (plaintext))
		end

	test_aes_pdf_string_round_trip
			-- Test PDF string encryption where IV is prepended.
		local
			aes: PDF_AES_HANDLER
			key, plaintext, encrypted, decrypted: STRING_8
		do
			create aes.make_128
			key := "TestSecretKey123" -- 16 bytes

			plaintext := "PDF String Value"

			encrypted := aes.encrypt_pdf_string (plaintext, key)
			decrypted := aes.decrypt_pdf_string (encrypted, key)

			assert ("PDF string round-trip", decrypted.is_equal (plaintext))
		end

	test_aes_empty_stream_padding
			-- Test encryption of empty content (produces padding block).
		local
			aes: PDF_AES_HANDLER
			key, encrypted, decrypted: STRING_8
		do
			create aes.make_128
			key := "0123456789ABCDEF"

			encrypted := aes.encrypt_pdf_stream ("", key)

			-- Should have IV (16 bytes) + padding block (16 bytes)
			assert ("Empty encrypts with IV and padding", encrypted.count = 32)

			decrypted := aes.decrypt_pdf_stream (encrypted, key)
			assert ("Empty decryption", decrypted.is_empty)
		end

feature {NONE} -- Helper Functions

	hex_to_bytes (hex: STRING): STRING_8
			-- Convert hexadecimal string to byte string.
		local
			i: INTEGER
			byte_val: INTEGER
		do
			create Result.make (hex.count // 2)
			from i := 1 until i > hex.count loop
				byte_val := hex_char_to_int (hex.item (i)) * 16 + hex_char_to_int (hex.item (i + 1))
				Result.append_character (byte_val.to_character_8)
				i := i + 2
			end
		end

	hex_char_to_int (c: CHARACTER): INTEGER
			-- Convert hex character to integer value.
		do
			if c >= '0' and c <= '9' then
				Result := c.code - ('0').code
			elseif c >= 'a' and c <= 'f' then
				Result := c.code - ('a').code + 10
			elseif c >= 'A' and c <= 'F' then
				Result := c.code - ('A').code + 10
			end
		end

end
