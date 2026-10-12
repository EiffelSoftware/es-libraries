note
	description: "Integration tests for Phase 3B: Document Writer."
	testing: "type/integration"

class
	TEST_OTHER_PHASE3_DOCUMENT_WRITER
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

feature -- Test

	test_read_complex_pdf
			-- Test reading a complex PDF with XRef streams and object streams.
		local
			source: PDF_FILE_BYTE_SOURCE
			doc: PDF_DOCUMENT
			doc2: PDF_DOCUMENT
			source2: PDF_FILE_BYTE_SOURCE
			path_in, path_out: PATH
			xref_count, load_count, total_count: INTEGER
		do
			path_in := test_other_pdf_path ("v112-367_3_STANDARD.pdf")
			path_out := test_output_path ("complex_output.pdf")

			-- Try to read the complex PDF
			create source.make_from_file (path_in.name)
			create doc.make_from_source (source)

			-- Check if it loaded successfully
			assert ("complex document loaded", doc.is_loaded)
			assert ("has trailer", doc.trailer /= Void)

			if doc.is_loaded then
				-- Check trailer size
				if attached doc.trailer as t then
					if attached {PDF_NUMBER} t.dictionary.item ("Size") as size then
						print ("%NTrailer /Size: " + size.int_value.out + "%N")
					end
				end

				-- Count XRef entries
				if attached doc.xref_table.entries as entries then
					xref_count := entries.count
				end

				-- Count how many objects we can load
				total_count := 0
				load_count := 0
				if attached doc.xref_table.entries as entries then
					across entries as cursor loop
						if @ cursor.key > 0 then
							total_count := total_count + 1
							-- Try to load the object
							if attached doc.get_object (create {PDF_OBJECT_ID}.make (@ cursor.key, (@ cursor.item).generation)) then
								load_count := load_count + 1
							end
						end
					end
				end

				print ("%NXRef entries: " + xref_count.out + ", Objects loadable: " + load_count.out + "/" + total_count.out + "%N")

				-- Try to access the catalog to ensure objects can be loaded
				assert ("has catalog", doc.catalog /= Void)

				-- Try to write it back
				doc.write_to_file (path_out.name)

				-- Try to read it back and check
				create source2.make_from_file (path_out.name)
				create doc2.make_from_source (source2)

				if doc2.is_loaded and then attached doc2.xref_table.entries as entries2 then
					print ("Output PDF: " + entries2.count.out + " XRef entries%N")
				end
			end
		end

end
