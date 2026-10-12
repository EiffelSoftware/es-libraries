note
	description: "Integration tests for Phase 13 (AES Hardening & Interop)."

class
	TEST_PHASE13_AES_INTEGRATION

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

	test_read_external_aes_protected_pdf
			-- Read externally-produced AES_protected.pdf and authenticate with owner password.
		local
			pdf_path: PATH
			source_read: PDF_FILE_BYTE_SOURCE
			doc_read: PDF_DOCUMENT
		do
			pdf_path := test_pdf_path ("AES_protected.pdf")
			create source_read.make_from_file (pdf_path.name)
			create doc_read.make_from_source (source_read)

			assert ("External document loaded", doc_read.is_loaded)
			assert ("External document is encrypted", doc_read.is_originally_encrypted)

			if attached {PDF_STANDARD_SECURITY_HANDLER} doc_read.original_security_handler as handler_read then
				-- Authorize with owner password "test"
				handler_read.authorize ("test")
				assert ("Authorized with owner password", handler_read.is_authorized)
				assert ("Catalog not void after authorization", doc_read.catalog /= Void)
			else
				assert ("Standard security handler present in external PDF", False)
			end
		end

	test_csprng_factory_availability
			-- Confirm that CSPRNG_FACTORY is available and can generate random data.
		local
			factory: CSPRNG_FACTORY
			rng: CSPRNG
			random_bytes: STRING_8
		do
			create factory
			assert ("CSPRNG is available on this platform", factory.is_csprng_available)
			rng := factory.new_csprng
			random_bytes := rng.fill_bytes_string (16)
			assert ("Generated random bytes are of correct length", random_bytes.count = 16)
			assert ("RNG has no errors", not rng.has_error)
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
