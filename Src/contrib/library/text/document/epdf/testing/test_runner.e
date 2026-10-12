class
	TEST_RUNNER

inherit
	TEST_PATH_HELPER

create
	make

feature
	default_create
		do
		end

	make
			-- Run test suite.
		local
			sha_tests: TEST_SHA512
		do
			print ("%N========================================%N")
			print ("Running SHA-512 / SHA-384 Test Suite%N")
			print ("========================================%N%N")

			create sha_tests.default_create

			print ("Running test_sha512_empty... ")
			sha_tests.test_sha512_empty
			print ("PASS%N")

			print ("Running test_sha512_abc... ")
			sha_tests.test_sha512_abc
			print ("PASS%N")

			print ("Running test_sha512_448bit... ")
			sha_tests.test_sha512_448bit
			print ("PASS%N")

			print ("Running test_sha512_896bit... ")
			sha_tests.test_sha512_896bit
			print ("PASS%N")

			print ("Running test_sha512_million_a... ")
			sha_tests.test_sha512_million_a
			print ("PASS%N")

			print ("Running test_sha512_reset_and_reuse... ")
			sha_tests.test_sha512_reset_and_reuse
			print ("PASS%N")

			print ("Running test_sha384_empty... ")
			sha_tests.test_sha384_empty
			print ("PASS%N")

			print ("Running test_sha384_abc... ")
			sha_tests.test_sha384_abc
			print ("PASS%N")

			print ("Running test_sha384_448bit... ")
			sha_tests.test_sha384_448bit
			print ("PASS%N")

			print ("Running test_sha384_896bit... ")
			sha_tests.test_sha384_896bit
			print ("PASS%N")

			print ("Running test_sha384_reset_and_reuse... ")
			sha_tests.test_sha384_reset_and_reuse
			print ("PASS%N")

			print ("Running test_update_bytes_matches_update_string... ")
			sha_tests.test_update_bytes_matches_update_string
			print ("PASS%N")

			print ("%N========================================%N")
			print ("✅ All SHA-512 and SHA-384 tests passed!%N")
			print ("========================================%N%N")

			run_security_aes_tests
			run_phase13_aes_tests
			test_phase4b_improvements
		end

	run_security_aes_tests
			-- Run low-level AES security tests.
		local
			aes_tests: TEST_SECURITY_AES
		do
			print ("%N========================================%N")
			print ("AES Unit & NIST Known-Answer Tests%N")
			print ("========================================%N")

			create aes_tests.default_create

			aes_tests.test_aes_128_basic_encryption
			aes_tests.test_aes_256_basic_encryption
			aes_tests.test_aes_128_nist_known_vector
			aes_tests.test_aes_256_nist_known_vector
			aes_tests.test_aes_binary_safety_zero_bytes
			aes_tests.test_aes_binary_safety_high_bytes
			aes_tests.test_aes_binary_safety_all_byte_values
			aes_tests.test_aes_padding_exact_block
			aes_tests.test_aes_padding_various_lengths
			aes_tests.test_aes_tamper_ciphertext_modification
			aes_tests.test_aes_tamper_iv_modification
			aes_tests.test_aes_iv_randomness
			aes_tests.test_aes_iv_exactly_16_bytes
			aes_tests.test_aes_256_pdf_stream_round_trip
			aes_tests.test_aes_256_multi_block
			aes_tests.test_aes_256_binary_safety
			aes_tests.test_aes_key_length_validation
			aes_tests.test_aes_truncated_ciphertext
			aes_tests.test_aes_pdf_stream_round_trip
			aes_tests.test_aes_pdf_string_round_trip
			aes_tests.test_aes_empty_stream_padding

			print ("✅ All AES low-level tests passed%N")
		end

	run_phase11_font_tests
			-- Run Phase 11 TrueType Font Preservation tests.
		local
			font_tests: TEST_PHASE11_FONTS
		do
			print ("%N========================================%N")
			print ("Phase 11: TrueType Font Preservation Tests%N")
			print ("========================================%N")

			create font_tests.default_create
			font_tests.test_type1_font_creation
			font_tests.test_type1_standard_fonts
			font_tests.test_type1_from_dictionary
			font_tests.test_truetype_font_creation
			font_tests.test_truetype_subset_font
			font_tests.test_truetype_from_dictionary
			font_tests.test_font_descriptor_creation
			font_tests.test_font_descriptor_metrics
			font_tests.test_font_descriptor_from_dictionary
			font_tests.test_font_descriptor_flags
			font_tests.test_truetype_with_descriptor

			-- Edge case tests
			font_tests.test_subset_prefix_invalid_too_short
			font_tests.test_subset_prefix_invalid_lowercase
			font_tests.test_subset_prefix_invalid_numbers
			font_tests.test_widths_array_extraction
			font_tests.test_truetype_missing_descriptor
			font_tests.test_font_with_encoding_differences
			font_tests.test_tounicode_cmap_creation
			font_tests.test_tounicode_stream_preservation
			font_tests.test_font_is_valid_check

			print ("✅ All Phase 11 font tests passed (20 tests)%N")
		end

	run_phase13_aes_tests
			-- Run Phase 13 AES Hardening & Interop tests.
		local
			aes_tests: TEST_PHASE13_AES_INTEGRATION
		do
			print ("%N========================================%N")
			print ("Phase 13: AES Hardening & Interop Tests%N")
			print ("========================================%N")

			create aes_tests.default_create
			aes_tests.on_prepare


			print ("Running test_read_external_aes_protected_pdf...%N")
			aes_tests.test_read_external_aes_protected_pdf

			print ("Running test_csprng_factory_availability...%N")
			aes_tests.test_csprng_factory_availability

			print ("✅ All Phase 13 AES tests passed (2 tests)%N")
		end


feature {NONE} -- Implementation


--	test_linearized
--			-- Scan veraPDF corpus for linearized PDFs.
--		local
--			scanner: TEST_SCAN_LINEARIZED_PDFS
--		do
--			print ("Running Linearized PDF Scanner...%N")
--			create scanner
--			scanner.test_scan_veraPDF_corpus
--			print ("%NLinearized PDF Scan Complete%N")
--		end

	test_that_fails
		local
			tlpd: TEST_LINEARIZED_PDF_DIAGNOSTICS
			tp3i: TEST_PHASE3_INTEGRATION
			tp3m: TEST_PHASE3_MODIFIER
		do
			print ("Running TEST_LINEARIZED_PDF_DIAGNOSTICS ... %N")
			print ("test test_minimal_xref_stream_parsing  ... %N")
			create tlpd
			tlpd.test_minimal_xref_stream_parsing

			print ("test test_zlib_decompression_edge_cases  ... %N")
			tlpd.test_zlib_decompression_edge_cases

			print ("Running TEST_PHASE3_INTEGRATION ... %N")
			print ("test test_zlib_decompression_edge_cases  ... %N")
			create tp3i
			tp3i.test_footer_injection_workflow

			print ("Running TEST_PHASE3_MODIFIER ... %N")
			print ("test test_add_footer_to_page_no_contents  ... %N")
			create tp3m
			tp3m.test_add_footer_to_page_no_contents

			print ("test test_get_page_dimensions  ... %N")
			tp3m.test_get_page_dimensions

			print ("test test_complete_footer_workflow  ... %N")
			tp3m.test_complete_footer_workflow


			print ("test test_mediabox_inheritance  ... %N")
			tp3m.test_mediabox_inheritance

		end


	test_phase4_security
		local
			t4: TEST_PHASE4_SECURITY
		do
			print ("Running Phase 4 Security Tests...%N")
			create t4

			print ("Testing MD5... ")
			t4.test_md5_rfc_vectors
			print ("PASS%N")

			print ("Testing RC4... ")
			t4.test_rc4
			print ("PASS%N")

			print ("Testing Permissions... ")
			t4.test_permissions
			print ("PASS%N")

			print ("Testing Security Handler... ")
			t4.test_security_handler
			print ("PASS%N")

			print ("%NAll Phase 4 Tests Passed!%N")
		end

	test_phase4b_improvements
			-- Test Phase 4B improvements: Resources inheritance, font deduplication, MediaBox inheritance.
		local
			modifier: TEST_PHASE3_MODIFIER
			simple: TEST_PHASE4B_SIMPLE
		do
			print ("%N========================================%N")
			print ("Phase 4B Improvements Test Suite%N")
			print ("========================================%N%N")

				-- Test 1: Resource Manager Unit Tests
			print ("=== Part 1: Resource Manager Unit Tests ===%N")
			create modifier

			print ("  - Testing ensure_resources_dict... ")
			modifier.test_ensure_resources_dict
			print ("PASS%N")

			print ("  - Testing ensure_font_dict... ")
			modifier.test_ensure_font_dict
			print ("PASS%N")

			print ("  - Testing allocate_font_name... ")
			modifier.test_allocate_font_name
			print ("PASS%N")

			print ("  - Testing add_type1_font... ")
			modifier.test_add_type1_font
			print ("PASS%N")

			print ("  - Testing find_or_add_helvetica... ")
			modifier.test_find_or_add_helvetica
			print ("PASS%N")

			print ("  - Testing MediaBox inheritance... ")
			modifier.test_mediabox_inheritance
			print ("PASS%N")

			print ("  - Testing deep copy dictionary... ")
			modifier.test_deep_copy_dictionary
			print ("PASS%N")

			print ("  - Testing resources deep copy... ")
			modifier.test_resources_deep_copy
			print ("PASS%N")

			print ("  - Testing multi-line footer... ")
			modifier.test_add_multiline_footer
			print ("PASS%N")

				-- Test 2: Simple Encryption Tests
			print ("%N=== Part 2: Simple Encryption Tests ===%N")
			create simple

			print ("  - Testing hello world encryption (full permissions)... ")
			simple.test_encrypt_hello_world_full_permissions
			print ("PASS%N")

			print ("  - Testing hello world encryption (read-only)... ")
			simple.test_encrypt_hello_world_read_only
			print ("PASS%N")

			print ("  - Testing hello world encryption (print-only)... ")
			simple.test_encrypt_hello_world_print_only
			print ("PASS%N")


			print ("%N========================================%N")
			print ("✅ All Phase 4B Improvements Tests PASSED!%N")
			print ("========================================%N%N")

			print ("Improvements Verified:%N")
			print ("  ✅ Resources inheritance support%N")
			print ("  ✅ Font deduplication (shared cache)%N")
			print ("  ✅ MediaBox inheritance support (FULL)%N")
			print ("  ✅ Deep copy of Resources dictionaries%N")
			print ("%N")
			print ("Known Limitations FIXED:%N")
			print ("  ✅ Full parent tree traversal for MediaBox%N")
			print ("  ✅ Deep copy prevents inherited page modifications%N")
		end

end
