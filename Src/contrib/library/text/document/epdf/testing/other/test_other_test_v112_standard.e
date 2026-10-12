note
	description: "[
			Test suite for v112-367_3_STANDARD.pdf
			Large linearized PDF (3.4 MB, ~42K objects)
			This was the PDF showing object loss issues before fixes
		]"

class
	TEST_OTHER_TEST_V112_STANDARD

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

	test_read_v112_standard
			-- Test reading v112-367_3_STANDARD.pdf
		local
			doc: PDF_DOCUMENT
			source: PDF_FILE_BYTE_SOURCE
			catalog: detachable PDF_DICTIONARY
			pdf_path: PATH
		do
			print ("%N=== Testing v112-367_3_STANDARD.pdf ===%N")

			pdf_path := test_other_pdf_path ("v112-367_3_STANDARD.pdf")
			create source.make_from_file (pdf_path.name)
			assert ("Source valid", source.is_valid)

			print ("File size: " + source.byte_count.out + " bytes%N")

			create doc.make_from_source (source)
			assert ("Document loaded", doc.is_loaded)

				-- Verify version
			print ("PDF version: " + doc.version + "%N")

				-- Verify catalog
			catalog := doc.catalog
			assert ("Catalog found", catalog /= Void)

			if catalog /= Void then
				print ("Catalog has " + catalog.count.out + " entries%N")
			end

				-- Check XRef table entries
			if attached doc.xref_table.entries as entries then
				print ("Total XRef entries: " + entries.count.out + "%N")
				assert ("Has XRef entries", entries.count > 0)

					-- Count entry types
				print_xref_statistics (doc)
			end
		end

	test_object_loading_v112
			-- Test loading objects from v112-367_3_STANDARD.pdf
		local
			doc: PDF_DOCUMENT
			source: PDF_FILE_BYTE_SOURCE
			obj_id: PDF_OBJECT_ID
			obj: detachable PDF_OBJECT
			success_count, fail_count, total_count: INTEGER
			pdf_path: PATH
		do
			print ("%N=== Testing Object Loading for v112-367_3_STANDARD.pdf ===%N")

			pdf_path := test_other_pdf_path ("v112-367_3_STANDARD.pdf")
			create source.make_from_file (pdf_path.name)
			create doc.make_from_source (source)

			if doc.is_loaded and then attached doc.xref_table.entries as entries then
				print ("Total objects in XRef: " + entries.count.out + "%N")
				print ("Attempting to load objects...%N")

					-- Try loading each object
				across entries as c loop
					if (@ c.item).is_in_use or (@ c.item).is_compressed then
						total_count := total_count + 1
						create obj_id.make (@ c.key, (@ c.item).generation)
						obj := doc.get_object (obj_id)

						if obj /= Void then
							success_count := success_count + 1
							if success_count \\ 5000 = 0 then
								print ("  Loaded " + success_count.out + " objects so far...%N")
							end
						else
							fail_count := fail_count + 1
							if fail_count <= 20 then
								print ("  Failed to load object " + (@ c.key).out +
									" (compressed=" + (@ c.item).is_compressed.out +
									" offset=" + (@ c.item).offset.out + ")%N")
							end
						end
					end
				end

				print ("%NLoad results:%N")
				print ("  Total attempted: " + total_count.out + "%N")
				print ("  Success: " + success_count.out + "%N")
				print ("  Failed: " + fail_count.out + "%N")

				if total_count > 0 then
					print ("  Success rate: " + ((success_count * 100) // total_count).out + "%%%N")
				end

				assert ("Most objects loaded", success_count > fail_count)
			end
		end

	test_write_v112_standard
			-- Test write operation on v112-367_3_STANDARD.pdf
		local
			doc: PDF_DOCUMENT
			source: PDF_FILE_BYTE_SOURCE
			output: STRING_8
			pdf_path, output_path: PATH
		do
			print ("%N=== Testing Write of v112-367_3_STANDARD.pdf ===%N")

			pdf_path := test_other_pdf_path ("v112-367_3_STANDARD.pdf")
			create source.make_from_file (pdf_path.name)
			create doc.make_from_source (source)
			assert ("Document loaded", doc.is_loaded)

				-- Serialize to bytes
			output := doc.to_bytes
			print ("Output size: " + output.count.out + " bytes%N")
			print ("Original size: " + source.byte_count.out + " bytes%N")

			if source.byte_count > 0 then
				print ("Size ratio: " + ((output.count * 100) // source.byte_count).out + "%%%N")
			end

				-- Write to file
			output_path := test_output_path ("v112_standard_output.pdf")
			doc.write_to_file (output_path.name)
			print ("Written to " + output_path.name + "%N")

				-- Basic validation
			assert ("Output not empty", output.count > 100000)
			assert ("Has PDF header", output.starts_with ("%%PDF-"))
			assert ("Has EOF", output.has_substring ("%%EOF"))

				-- Check if we lost objects (was 11% before fix)
			if source.byte_count > 0 then
				assert ("Output reasonable size", output.count > (source.byte_count // 5))
			end
		end

feature {NONE} -- Implementation

	print_xref_statistics (doc: PDF_DOCUMENT)
			-- Print statistics about XRef entries
		local
			in_use_count, compressed_count, free_count: INTEGER
			min_obj, max_obj: INTEGER
		do
			if attached doc.xref_table.entries as entries then
				min_obj := 999999
				max_obj := 0

				across entries as c loop
					if (@ c.item).is_in_use then
						in_use_count := in_use_count + 1
					elseif (@ c.item).is_compressed then
						compressed_count := compressed_count + 1
					else
						free_count := free_count + 1
					end

					if @ c.key < min_obj then
						min_obj := @ c.key
					end
					if @ c.key > max_obj then
						max_obj := @ c.key
					end
				end

				print ("%NXRef Entry Statistics:%N")
				print ("  In-use objects: " + in_use_count.out + "%N")
				print ("  Compressed objects: " + compressed_count.out + "%N")
				print ("  Free objects: " + free_count.out + "%N")
				print ("  Object number range: " + min_obj.out + " - " + max_obj.out + "%N")
			end
		end

end
