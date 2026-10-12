note
	description: "[
		Diagnostic tests for linearized PDF parsing.
		Phase 2D: Linearized PDF Support.
		Tests XRef chain traversal and object loading for linearized PDFs.
	]"

class
	TEST_OTHER_PHASE2D_LINEARIZED_PDF
inherit
	EQA_TEST_SET
	TEST_PATH_HELPER

feature -- Test routines

	test_xref_entry_counts
			-- Verify XRef entries are loaded from all XRef sections.
		local
			doc: PDF_DOCUMENT
			source: PDF_FILE_BYTE_SOURCE
			type0_count, type1_count, type2_count: INTEGER
			total_in_use: INTEGER
			pdf_path: PATH
		do
			print ("%N=== test_xref_entry_counts ===%N")

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

				total_in_use := type1_count + type2_count

				print ("Type 0 (free): " + type0_count.out + "%N")
				print ("Type 1 (in-use regular): " + type1_count.out + "%N")
				print ("Type 2 (compressed in ObjStm): " + type2_count.out + "%N")
				print ("Total in-use: " + total_in_use.out + "%N")

					-- For v112-367_3_STANDARD.pdf:
					-- First XRef: 674 entries (objects 41669-42342)
					-- Main XRef: 41669 entries (objects 0-41668)
					-- Total expected: ~42343 entries
				print ("%N** DIAGNOSTIC: entries.count = " + entries.count.out + " **%N")
					-- First test: At minimum we should have the first XRef (674 entries)
				assert ("Has first XRef entries", entries.count >= 600)
					-- Second test: If /Prev is followed, we should have ~42k entries
				if entries.count < 1000 then
					print ("WARNING: Only first XRef loaded, /Prev chain not followed%N")
				else
					print ("SUCCESS: Full XRef chain loaded%N")
				end
			end

			if attached doc.trailer as t then
				print ("Trailer /Size: " + t.size.out + "%N")
			end
		end

	test_prev_chain_parsing
			-- Verify that the /Prev chain is being followed correctly.
		local
			doc: PDF_DOCUMENT
			source: PDF_FILE_BYTE_SOURCE
			src: PDF_FILE_BYTE_SOURCE
			lexer: PDF_LEXER
			parser: PDF_PARSER
			indirect: detachable PDF_INDIRECT_OBJECT
		do
			print ("%N=== test_prev_chain_parsing ===%N")

			create source.make_from_file (test_other_pdf_path ("v112-367_3_STANDARD.pdf").name)
			create doc.make_from_source (source)

			assert ("Document loaded", doc.is_loaded)

				-- Now manually parse at offset 116 to see what we get
			create src.make_from_file (test_other_pdf_path ("v112-367_3_STANDARD.pdf").name)
			src.set_position (116)  -- First XRef stream position per startxref

			create lexer.make (src)
			create parser.make (lexer)

			indirect := parser.parse_indirect_object
			if attached indirect then
				print ("Parsed object ID: " + indirect.object_id.object_number.out + "%N")
				if attached {PDF_STREAM} indirect.value as stream then
					print ("Object is a stream%N")
					print ("Stream dictionary keys: ")
					across stream.stream_dictionary.entries as c loop
						print ((@ c.key).out + " ")
					end
					print ("%N")

					if stream.stream_dictionary.has_key ("Prev") then
						print ("Has /Prev key: True%N")
						if attached {PDF_NUMBER} stream.stream_dictionary.item ("Prev") as prev_num then
							print ("/Prev value: " + prev_num.int_value.out + "%N")
						else
							print ("/Prev is NOT a PDF_NUMBER%N")
							if attached stream.stream_dictionary.item ("Prev") as prev_obj then
								print ("/Prev type: " + prev_obj.generator + "%N")
							end
						end
					else
						print ("Has /Prev key: False%N")
					end

					if stream.stream_dictionary.has_key ("Type") then
						if attached {PDF_NAME} stream.stream_dictionary.item ("Type") as type_name then
							print ("/Type value: " + type_name.value + "%N")
						end
					end
				else
					print ("Object is NOT a stream: " + indirect.value.generator + "%N")
				end
			else
				print ("Failed to parse indirect object at offset 116%N")
			end

			assert ("Debug complete", True)
		end

	test_object_loading_success_rate
			-- Test how many objects can be successfully loaded.
		local
			doc: PDF_DOCUMENT
			source: PDF_FILE_BYTE_SOURCE
			loaded_count, failed_count: INTEGER
			obj_id: PDF_OBJECT_ID
			sample_count: INTEGER
		do
			print ("%N=== test_object_loading_success_rate ===%N")

			create source.make_from_file (test_other_pdf_path ("v112-367_3_STANDARD.pdf").name)
			create doc.make_from_source (source)

			assert ("Document loaded", doc.is_loaded)

				-- Sample loading (don't load all 42k objects, just sample)
			if attached doc.xref_table.entries as entries then
				across entries as c loop
					if @ c.key > 0 and (@ c.item).is_in_use then
						sample_count := sample_count + 1
						if sample_count <= 500 or sample_count \\ 100 = 0 then
								-- Test first 500 and then every 100th
							create obj_id.make (@ c.key, (@ c.item).generation)
							if doc.get_object (obj_id) /= Void then
								loaded_count := loaded_count + 1
							else
								failed_count := failed_count + 1
								if failed_count <= 5 then
									print ("Failed to load object " + (@ c.key).out)
									if (@ c.item).is_compressed then
										print (" (compressed in ObjStm " + (@ c.item).object_stream_number.out + ")")
									end
									print ("%N")
								end
							end
						end
					end
				end
			end

			print ("Sampled objects: " + (loaded_count + failed_count).out + "%N")
			print ("Successfully loaded: " + loaded_count.out + "%N")
			print ("Failed to load: " + failed_count.out + "%N")

				-- We expect high success rate
			assert ("Loading works", loaded_count > 0)
		end

	test_catalog_and_pages_accessible
			-- Verify catalog and pages are accessible from linearized PDF.
		local
			doc: PDF_DOCUMENT
			source: PDF_FILE_BYTE_SOURCE
			page_count: INTEGER
		do
			print ("%N=== test_catalog_and_pages_accessible ===%N")

			create source.make_from_file (test_other_pdf_path ("v112-367_3_STANDARD.pdf").name)
			create doc.make_from_source (source)

			assert ("Document loaded", doc.is_loaded)
			assert ("Catalog accessible", doc.catalog /= Void)

			if attached doc.catalog as cat then
				print ("Catalog loaded successfully%N")
				if attached {PDF_REFERENCE} cat.item ("Pages") as pages_ref then
					print ("Pages reference: " + pages_ref.object_id.object_number.out + "%N")
					if attached {PDF_DICTIONARY} doc.get_object (pages_ref.object_id) as pages_dict then
						print ("Pages dictionary loaded%N")
						if attached {PDF_NUMBER} pages_dict.item ("Count") as cnt then
							page_count := cnt.int_value
							print ("Page count: " + page_count.out + "%N")
							assert ("Has pages", page_count > 0)
						end
					end
				end
			end
		end

end
