note
	description: "[
		Test XRef stream parsing for probable-provable.pdf.
		This verifies Phase 2B: Cross-Reference Stream support.
	]"
	testing: "type/manual/expert"

class
	TEST_OTHER_DEBUG_XREF_STREAM
inherit
	EQA_TEST_SET
	TEST_PATH_HELPER

feature -- Test

	test_debug_probable_provable
			-- Verify XRef stream parsing works for probable-provable.pdf.
		local
			doc: PDF_DOCUMENT
			source: PDF_FILE_BYTE_SOURCE
			pdf_path: PATH
		do
			pdf_path := test_other_pdf_path ("probable-provable.pdf")

			create source.make_from_file (pdf_path.name)
			create doc.make_from_source (source)

				-- Verify document loaded
			assert ("document loaded", doc.is_loaded)
			assert ("has trailer", doc.trailer /= Void)

				-- Verify XRef stream was parsed and catalog is accessible
			assert ("has catalog", doc.catalog /= Void)

				-- Verify trailer has correct size (298 objects in this PDF)
			if attached doc.trailer as t then
				assert ("trailer has correct size", t.size = 298)
			end
		end

end

