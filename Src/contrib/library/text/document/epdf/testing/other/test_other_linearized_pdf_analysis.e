note
	description: "[
		Diagnostic test to analyze linearized PDF reading and writing.
		Used to identify why objects are lost during conversion.
	]"

class
	TEST_OTHER_LINEARIZED_PDF_ANALYSIS
inherit
	EQA_TEST_SET
	TEST_PATH_HELPER

feature -- Test routines

	test_xref_entry_counts
			-- Analyze xref entries for linearized PDF.
		local
			doc: PDF_DOCUMENT
			source: PDF_FILE_BYTE_SOURCE
			type0_count, type1_count, type2_count: INTEGER
			pdf_path: PATH
		do
			print ("%N=== XRef Entry Analysis for v112-367_3_STANDARD.pdf ===%N")

			pdf_path := test_other_pdf_path ("v112-367_3_STANDARD.pdf")
			create source.make_from_file (pdf_path.name)
			create doc.make_from_source (source)

			assert ("Document loaded", doc.is_loaded)

			-- Count entry types
			if attached doc.xref_table.entries as entries then
				print ("Total XRef entries: " + entries.count.out + "%N")

				across entries as c loop
					if (@ c.item).is_in_use then
						if (@ c.item).is_compressed then
							type2_count := type2_count + 1
						else
							type1_count := type1_count + 1
						end
					else
						type0_count := type0_count + 1
					end
				end

				print ("Type 0 (free): " + type0_count.out + "%N")
				print ("Type 1 (in-use): " + type1_count.out + "%N")
				print ("Type 2 (compressed): " + type2_count.out + "%N")
				print ("Total counted: " + (type0_count + type1_count + type2_count).out + "%N")
			end

			if attached doc.trailer as t then
				print ("%NTrailer /Size: " + t.size.out + "%N")
			end

			assert ("Analysis complete", True)
		end

	test_object_loading_stats
			-- Test how many objects can be successfully loaded.
		local
			doc: PDF_DOCUMENT
			source: PDF_FILE_BYTE_SOURCE
			loaded_count, failed_count: INTEGER
			obj_id: PDF_OBJECT_ID
		do
			print ("%N=== Object Loading Stats for v112-367_3_STANDARD.pdf ===%N")

			create source.make_from_file (test_other_pdf_path ("v112-367_3_STANDARD.pdf").name)
			create doc.make_from_source (source)

			assert ("Document loaded", doc.is_loaded)

			-- Try loading each object
			if attached doc.xref_table.entries as entries then
				across entries as c loop
					if @ c.key > 0 and (@ c.item).is_in_use then
						create obj_id.make (@ c.key, (@ c.item).generation)
						if doc.get_object (obj_id) /= Void then
							loaded_count := loaded_count + 1
						else
							failed_count := failed_count + 1
							if failed_count <= 10 then
								print ("Failed to load object " + (@ c.key).out + "%N")
							elseif failed_count = 11 then
								print ("... (more failures hidden)%N")
							end
						end
					end
				end
			end

			print ("%NSuccessfully loaded: " + loaded_count.out + "%N")
			print ("Failed to load: " + failed_count.out + "%N")
			print ("Success rate: " + ((loaded_count * 100) // (loaded_count + failed_count)).out + "%%%N")

			assert ("Analysis complete", True)
		end

	test_object_stream_analysis
			-- Analyze Object Streams in the PDF.
		local
			doc: PDF_DOCUMENT
			source: PDF_FILE_BYTE_SOURCE
			obj_id: PDF_OBJECT_ID
			objstm_count: INTEGER
			objstm_objects_total: INTEGER
		do
			print ("%N=== Object Stream Analysis for v112-367_3_STANDARD.pdf ===%N")

			create source.make_from_file (test_other_pdf_path ("v112-367_3_STANDARD.pdf").name)
			create doc.make_from_source (source)

			assert ("Document loaded", doc.is_loaded)

			-- Find all Type 2 entries and their object stream numbers
			if attached doc.xref_table.entries as entries then
				across entries as c loop
					if (@ c.item).is_compressed then
						-- Count which object streams are being used
						objstm_objects_total := objstm_objects_total + 1
					end
				end
			end

			print ("Objects stored in Object Streams: " + objstm_objects_total.out + "%N")

			-- Try to find ObjStm objects
			if attached doc.xref_table.entries as entries then
				across entries as c loop
					if (@ c.item).is_in_use and not (@ c.item).is_compressed then
						create obj_id.make (@ c.key, (@ c.item).generation)
						if attached doc.get_object (obj_id) as obj then
							if attached {PDF_STREAM} obj as stream then
								if attached {PDF_NAME} stream.stream_dictionary.item ("Type") as type_name then
									if type_name.value.is_equal ("ObjStm") then
										objstm_count := objstm_count + 1
										if attached {PDF_NUMBER} stream.stream_dictionary.item ("N") as n then
											print ("ObjStm " + (@ c.key).out + " contains " + n.int_value.out + " objects%N")
										end
									end
								end
							end
						end
					end
				end
			end

			print ("%NTotal Object Streams found: " + objstm_count.out + "%N")

			assert ("Analysis complete", True)
		end

end
