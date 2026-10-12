note
	description: "Test MD5 implementation against RFC 1321 test vectors."

class
	TEST_SECURITY_MD5

inherit
	EQA_TEST_SET

feature -- Tests

	test_md5_empty_string
			-- MD5("") = d41d8cd98f00b204e9800998ecf8427e
		local
			md5: PDF_MD5
			digest: STRING
		do
			create md5.make
			digest := md5.digest_string ("")
			assert ("MD5 empty string", digest_to_hex (digest).is_equal ("d41d8cd98f00b204e9800998ecf8427e"))
		end

	test_md5_single_a
			-- MD5("a") = 0cc175b9c0f1b6a831c399e269772661
		local
			md5: PDF_MD5
			digest: STRING
		do
			create md5.make
			digest := md5.digest_string ("a")
			assert ("MD5 'a'", digest_to_hex (digest).is_equal ("0cc175b9c0f1b6a831c399e269772661"))
		end

	test_md5_abc
			-- MD5("abc") = 900150983cd24fb0d6963f7d28e17f72
		local
			md5: PDF_MD5
			digest: STRING
		do
			create md5.make
			digest := md5.digest_string ("abc")
			assert ("MD5 'abc'", digest_to_hex (digest).is_equal ("900150983cd24fb0d6963f7d28e17f72"))
		end

	test_md5_message_digest
			-- MD5("message digest") = f96b697d7cb7938d525a2f31aaf161d0
		local
			md5: PDF_MD5
			digest: STRING
		do
			create md5.make
			digest := md5.digest_string ("message digest")
			assert ("MD5 'message digest'", digest_to_hex (digest).is_equal ("f96b697d7cb7938d525a2f31aaf161d0"))
		end

feature {NONE} -- Helpers

	digest_to_hex (digest: STRING): STRING
			-- Convert binary digest to hex string.
		local
			i: INTEGER
			byte: INTEGER
		do
			create Result.make (32)
			from i := 1 until i > digest.count loop
				byte := digest.code (i).to_integer_32
				Result.append (byte_to_hex (byte))
				i := i + 1
			end
		end

	byte_to_hex (b: INTEGER): STRING
			-- Convert byte to 2-character hex string.
		local
			hex_chars: STRING
			high, low: INTEGER
		do
			hex_chars := "0123456789abcdef"
			high := b.bit_shift_right (4).bit_and (0x0F)
			low := b.bit_and (0x0F)
			create Result.make (2)
			Result.append_character (hex_chars [high + 1])
			Result.append_character (hex_chars [low + 1])
		end

end
