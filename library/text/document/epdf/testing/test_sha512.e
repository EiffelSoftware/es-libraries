note
	description: "Unit tests for PDF_SHA512 (SHA-512 and SHA-384). %
	             %Known-answer vectors from FIPS 180-4 and RFC 6234."

class
	TEST_SHA512

inherit
	EQA_TEST_SET

feature -- SHA-512 tests

	test_sha512_empty
			-- SHA-512("") = cf83e1357eefb8bdf1542850d66d8007...
		local
			sha: PDF_SHA512
			l_result: STRING_8
		do
			create sha.make
			l_result := sha.hex_digest
			assert ("sha512_empty",
				l_result ~ "cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e")
		end

	test_sha512_abc
			-- SHA-512("abc") = ddaf35a193617abacc417349ae204131...
		local
			sha: PDF_SHA512
			l_result: STRING_8
		do
			create sha.make
			sha.update ("abc")
			l_result := sha.hex_digest
			assert ("sha512_abc",
				l_result ~ "ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f")
		end

	test_sha512_448bit
			-- SHA-512("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq")
			-- This message is exactly 448 bits -- tests the two-block padding path.
		local
			sha: PDF_SHA512
			l_result: STRING_8
		do
			create sha.make
			sha.update ("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq")
			l_result := sha.hex_digest
			assert ("sha512_448bit",
				l_result ~ "204a8fc6dda82f0a0ced7beb8e08a41657c16ef468b228a8279be331a703c33596fd15c13b1b07f9aa1d3bea57789ca031ad85c7a71dd70354ec631238ca3445")
		end

	test_sha512_896bit
			-- SHA-512("abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmn%
			--         %hijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu")
			-- 896-bit input, tests a different block-boundary scenario.
		local
			sha: PDF_SHA512
			l_result: STRING_8
		do
			create sha.make
			sha.update ("abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmn")
			sha.update ("hijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu")
			l_result := sha.hex_digest
			assert ("sha512_896bit",
				l_result ~ "8e959b75dae313da8cf4f72814fc143f8f7779c6eb9f7fa17299aeadb6889018501d289e4900f7e4331b99dec4b5433ac7d329eeb6dd26545e96e55b874be909")
		end

	test_sha512_million_a
			-- SHA-512(1,000,000 x "a") -- stress test for multi-block hashing.
		local
			sha: PDF_SHA512
			l_result: STRING_8
			i: INTEGER
			chunk: STRING_8
		do
			create sha.make
			create chunk.make_filled ('a', 1000)
			from i := 1 until i > 1000 loop
				sha.update (chunk)
				i := i + 1
			end
			l_result := sha.hex_digest
			assert ("sha512_million_a",
				l_result ~ "e718483d0ce769644e2e42c7bc15b4638e1f98b13b2044285632a803afa973ebde0ff244877ea60a4cb0432ce577c31beb009c5c2c49aa2e4eadb217ad8cc09b")
		end

	test_sha512_reset_and_reuse
			-- After reset, the same object must produce correct results again.
		local
			sha: PDF_SHA512
			first, second: STRING_8
		do
			create sha.make
			sha.update ("abc")
			first := sha.hex_digest
			sha.reset
			sha.update ("abc")
			second := sha.hex_digest
			assert ("sha512_reuse", first ~ second)
		end

feature -- SHA-384 tests

	test_sha384_empty
			-- SHA-384("") = 38b060a751ac96384cd9327eb1b1e36a...
		local
			sha: PDF_SHA512
			l_result: STRING_8
		do
			create sha.make_384
			l_result := sha.hex_digest
			assert ("sha384_empty",
				l_result ~ "38b060a751ac96384cd9327eb1b1e36a21fdb71114be07434c0cc7bf63f6e1da274edebfe76f65fbd51ad2f14898b95b")
		end

	test_sha384_abc
			-- SHA-384("abc") = cb00753f45a35e8bb5a03d699ac65007...
		local
			sha: PDF_SHA512
			l_result: STRING_8
		do
			create sha.make_384
			sha.update ("abc")
			l_result := sha.hex_digest
			assert ("sha384_abc",
				l_result ~ "cb00753f45a35e8bb5a03d699ac65007272c32ab0eded1631a8b605a43ff5bed8086072ba1e7cc2358baeca134c825a7")
		end

	test_sha384_448bit
			-- SHA-384("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq")
		local
			sha: PDF_SHA512
			l_result: STRING_8
		do
			create sha.make_384
			sha.update ("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq")
			l_result := sha.hex_digest
			assert ("sha384_448bit",
				l_result ~ "3391fdddfc8dc7393707a65b1b4709397cf8b1d162af05abfe8f450de5f36bc6b0455a8520bc4e6f5fe95b1fe3c8452b")
		end

	test_sha384_896bit
			-- SHA-384 of the 896-bit two-part message.
		local
			sha: PDF_SHA512
			l_result: STRING_8
		do
			create sha.make_384
			sha.update ("abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmn")
			sha.update ("hijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu")
			l_result := sha.hex_digest
			assert ("sha384_896bit",
				l_result ~ "09330c33f71147e83d192fc782cd1b4753111b173b3b05d22fa08086e3b0f712fcc7c71a557e2db966c3e9fa91746039")
		end

	test_sha384_reset_and_reuse
			-- After reset, the same SHA-384 object must produce correct results again.
		local
			sha: PDF_SHA512
			first, second: STRING_8
		do
			create sha.make_384
			sha.update ("abc")
			first := sha.hex_digest
			sha.reset
			sha.update ("abc")
			second := sha.hex_digest
			assert ("sha384_reuse", first ~ second)
		end

feature -- update_bytes tests

	test_update_bytes_matches_update_string
			-- update_bytes and update must produce identical results for "abc".
		local
			sha_str, sha_bytes: PDF_SHA512
			raw: SPECIAL [NATURAL_8]
			result_str, result_bytes: STRING_8
		do
			-- String path
			create sha_str.make
			sha_str.update ("abc")
			result_str := sha_str.hex_digest

			-- Bytes path
			create sha_bytes.make
			create raw.make_filled (0, 3)
			raw [0] := 0x61  -- 'a'
			raw [1] := 0x62  -- 'b'
			raw [2] := 0x63  -- 'c'
			sha_bytes.update_bytes (raw, 0, 2)
			result_bytes := sha_bytes.hex_digest

			assert ("update_bytes_equals_update_string", result_str ~ result_bytes)
		end

feature {NONE} -- Helpers

	bytes_to_hex (bytes: STRING_8): STRING_8
			-- Convert raw byte string to lowercase hex representation.
		local
			i: INTEGER
			code: NATURAL_32
			hex: STRING_8
		do
			create Result.make (bytes.count * 2)
			from i := 1 until i > bytes.count loop
				code := bytes.code (i)
				hex := code.to_hex_string
				Result.append (hex.substring (7, 8).as_lower)
				i := i + 1
			end
		end

end
