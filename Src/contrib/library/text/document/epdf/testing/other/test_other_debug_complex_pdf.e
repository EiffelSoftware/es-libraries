note
	description: "Debug program to analyze complex PDF structure"

class
	TEST_OTHER_DEBUG_COMPLEX_PDF
inherit
	EQA_TEST_SET
	TEST_PATH_HELPER

feature -- Test

	test_analyze_complex_pdf
		local
			source: PDF_FILE_BYTE_SOURCE
			doc: PDF_DOCUMENT
			load_count: INTEGER
			total_count: INTEGER
			id: PDF_OBJECT_ID
			obj: detachable PDF_OBJECT
			pdf_path: PATH
		do
			pdf_path := test_other_pdf_path ("v112-367_3_STANDARD.pdf")
			create source.make_from_file (pdf_path.name)
			create doc.make_from_source (source)

			assert ("document loaded", doc.is_loaded)

			if doc.is_loaded then
				print ("%N=== PDF Analysis ===%N")

				if attached doc.trailer as t then
					if attached {PDF_NUMBER} t.dictionary.item ("Size") as size then
						print ("Trailer /Size: " + size.int_value.out + "%N")
					end
				end

				if attached doc.xref_table.entries as entries then
					print ("XRef entries: " + entries.count.out + "%N")
					across entries as cursor loop
						if @ cursor.item.is_compressed then
							print ("  " + @ cursor.key.out + ": COMPRESSED (stream=" + (@ cursor.item).object_stream_number.out + ", index=" + (@ cursor.item).index_in_stream.out + ")%N")
						else
							print ("  " + @ cursor.key.out + ": REGULAR (offset=" + (@ cursor.item).offset.out + ")%N")
						end
					end
				end

				print ("%N=== Loading Test ===%N")
				load_count := 0
				total_count := 0
				if attached doc.xref_table.entries as entries then
					across entries as cursor loop
						if @ cursor.key > 0 then
							total_count := total_count + 1
							create id.make (@ cursor.key, (@ cursor.item).generation)
							obj := doc.get_object (id)
							if obj /= Void then
								load_count := load_count + 1
							else
								print ("FAILED to load object " + @ cursor.key.out + "%N")
							end
						end
					end
				end
				print ("Successfully loaded " + load_count.out + "/" + total_count.out + " objects%N")

				print ("%N=== Writing Test ===%N")
				-- Don't write for now, just check the structure
				print ("Skipping write for analysis%N")
			end
		end

end
