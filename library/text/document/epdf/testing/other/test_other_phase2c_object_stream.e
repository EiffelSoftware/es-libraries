note
	description: "Test suite for Phase 2C: Object Stream support (Type 2 XRef entries)."
	testing: "type/manual/expert"

class
	TEST_OTHER_PHASE2C_OBJECT_STREAM
inherit
	EQA_TEST_SET
	TEST_PATH_HELPER

feature -- Test: Integration

	test_read_probable_provable_objects
			-- Test reading probable-provable.pdf which uses XRef streams and Object Streams.
		local
			doc: PDF_DOCUMENT
			source: PDF_FILE_BYTE_SOURCE
			pdf_path: PATH
			catalog: detachable PDF_DICTIONARY
			pages: detachable PDF_DICTIONARY
			entry: detachable PDF_XREF_ENTRY
		do
			pdf_path := test_other_pdf_path ("probable-provable.pdf")

			create source.make_from_file (pdf_path.name)
			create doc.make_from_source (source)

			assert ("document loaded", doc.is_loaded)

				-- 1. Check Catalog (recursive load)
			catalog := doc.catalog
			assert ("has catalog", catalog /= Void)

			if attached catalog as cat then
				assert ("catalog type is Catalog", attached {PDF_NAME} cat.item ("Type") as t and then t.value.is_equal ("Catalog"))
				print ("%NCatalog loaded successfully.%N")

				-- 2. Check Pages (likely in object stream if catalog is, or just standard structure)
				if attached {PDF_REFERENCE} cat.item ("Pages") as pages_ref then
					print ("%NFound Pages reference: " + pages_ref.object_id.object_number.out + " " + pages_ref.object_id.generation.out + " R%N")

					entry := doc.xref_table.entry (pages_ref.object_id.object_number)
					if attached entry as e then
						print ("Pages XRef Entry: InUse=" + e.is_in_use.out + " Compressed=" + e.is_compressed.out + "%N")
						if e.is_compressed then
							print ("  Stream=" + e.object_stream_number.out + " Index=" + e.index_in_stream.out + "%N")
						else
							print ("  Offset=" + e.offset.out + "%N")
						end
					else
						print ("Pages XRef Entry NOT FOUND!%N")
					end

					if attached {PDF_DICTIONARY} doc.get_object (pages_ref.object_id) as p then
						pages := p
						assert ("pages dict found", pages /= Void)
						assert ("pages type is Pages", attached {PDF_NAME} pages.item ("Type") as t and then t.value.is_equal ("Pages"))

						-- Check count
						if attached {PDF_NUMBER} pages.item ("Count") as c then
							assert ("page count > 0", c.int_value > 0)
						end
						print ("Pages loaded successfully.%N")
					else
						print ("FAILED to load Pages object!%N")
						assert ("failed to load Pages object", False)
					end
				end
			end
		end

end
