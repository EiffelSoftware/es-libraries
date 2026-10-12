note
	description: "Test suite for Phase 2B: Cross-Reference Streams support."
	testing: "type/manual/expert"

class
	TEST_OTHER_PHASE2B_XREF_STREAM
inherit
	EQA_TEST_SET
	TEST_PATH_HELPER



feature -- Test: Integration

	test_read_probable_provable_pdf
			-- Test reading probable-provable.pdf which uses XRef streams.
		local
			doc: PDF_DOCUMENT
			source: PDF_FILE_BYTE_SOURCE
			pdf_path: PATH
		do
			pdf_path := test_other_pdf_path ("probable-provable.pdf")

			create source.make_from_file (pdf_path.name)
			create doc.make_from_source (source)

			assert ("document loaded", doc.is_loaded)
			assert ("has trailer", doc.trailer /= Void)

				-- Debug: Check if trailer has root
			if attached doc.trailer as t then
				if attached t.root as root_ref then
					print ("%NRoot reference found: " + root_ref.object_id.object_number.out + " " + root_ref.object_id.generation.out + " R%N")
				else
					print ("%NNo root reference in trailer!%N")
				end
			end

			assert ("has catalog", doc.catalog /= Void)
		end

end
