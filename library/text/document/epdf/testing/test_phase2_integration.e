note
	description: "[
		Integration test for Phase 2 Reader.
		Tests reading the hello_world.pdf file created in Phase 0.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_PHASE2_INTEGRATION

inherit
	EQA_TEST_SET
	TEST_PATH_HELPER

feature -- Test: Integration

	test_read_hello_world_pdf
			-- Test reading hello_world.pdf created in Phase 0.
		local
			file: RAW_FILE
			content: STRING
			source: PDF_STRING_BYTE_SOURCE
			doc: PDF_DOCUMENT
			cat: detachable PDF_DICTIONARY
			pdf_path: PATH
		do
			pdf_path := test_pdf_path ("hello_world.pdf")
			create file.make_open_read (pdf_path.name)
			if file.exists and then file.is_readable then
				file.read_stream (file.count)
				content := file.last_string.twin
				file.close

				create source.make (content)
				create doc.make_from_source (source)

				assert ("document loaded", doc.is_loaded)
				assert ("has trailer", doc.trailer /= Void)

				if attached doc.trailer as t then
					assert ("trailer valid", t.is_valid)
					assert ("has root", t.root /= Void)
					assert ("size > 0", t.size > 0)
				end

				cat := doc.catalog
				assert ("has catalog", cat /= Void)

				if attached cat as catalog then
						-- Per ISO 32000-1:2008, keys do not include leading slash
					if attached {PDF_REFERENCE} catalog.item ("Pages") as pages_ref then
						if attached {PDF_DICTIONARY} doc.get_object (pages_ref.object_id) as pages_dict then
							if attached {PDF_NUMBER} pages_dict.item ("Count") as count_num then
								assert ("page count is 1", count_num.real_value.truncated_to_integer = 1)
							end
						end
					end
				end
			else
				assert ("hello_world.pdf exists", False)
			end
		end

	test_document_version_detection
			-- Test PDF version detection.
		local
			source: PDF_STRING_BYTE_SOURCE
			doc: PDF_DOCUMENT
			pdf_content: STRING
		do
			pdf_content := "%%PDF-1.7%N"
			pdf_content.append ("%%EOF")

			create source.make (pdf_content)
			create doc.make_from_source (source)

			assert ("version is 1.7", doc.version.is_equal ("1.7"))
		end

	test_strict_mode_toggle
			-- Test strict mode configuration.
		local
			doc: PDF_DOCUMENT
		do
			create doc.make

			assert ("permissive by default", not doc.strict_mode)

			doc.set_strict_mode (True)
			assert ("strict mode enabled", doc.strict_mode)

			doc.set_strict_mode (False)
			assert ("strict mode disabled", not doc.strict_mode)
		end

end
