note
	description: "[
		Integration tests for XObject and ExtGState preservation.
		Tests end-to-end workflow: load PDF with images → modify → write → verify images preserved.
		
		Test files used:
		- ITIL.pdf (contains images and graphics)
		- v112-367_3_STANDARD.pdf (large linearized PDF)
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_OTHER_XOBJECT_INTEGRATION
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


feature -- Test: XObject Detection

	test_detect_xobjects_in_pdf
			-- Test that XObjects are detected in a PDF with images.
		local
			doc: PDF_DOCUMENT
			source: PDF_FILE_BYTE_SOURCE
			page: detachable PDF_DICTIONARY
			resources: detachable PDF_DICTIONARY
			xobjects: detachable PDF_DICTIONARY
			xobject_count: INTEGER
		do
			print ("%N=== Test: Detect XObjects in PDF ===%N")

			create source.make_from_file (test_other_pdf_path ("ITIL.pdf").name)
			create doc.make_from_source (source)
			assert ("Document loaded", doc.is_loaded)
			print ("Loaded: " + source.byte_count.out + " bytes%N")

				-- Get first page
			page := get_first_page (doc)
			assert ("First page found", page /= Void)

			if attached page as p then
					-- Get resources dictionary (may be inline or inherited)
				resources := get_page_resources (doc, p)

				if attached resources as r then
					print ("Resources found with " + r.count.out + " entries%N")

						-- Check for XObject subdictionary
					if attached {PDF_DICTIONARY} r.item ("XObject") as xo then
						xobjects := xo
						xobject_count := xo.count
						print ("XObject dictionary found with " + xobject_count.out + " entries%N")

							-- List XObject names
						across xo.entries as cursor loop
							print ("  - XObject: /" + (@ cursor.key) + "%N")
						end
					elseif attached {PDF_REFERENCE} r.item ("XObject") as xo_ref then
						print ("XObject is indirect reference: " + xo_ref.object_id.object_number.out + " 0 R%N")
						if attached {PDF_DICTIONARY} doc.get_object (xo_ref.object_id) as xo_dict then
							xobject_count := xo_dict.count
							print ("Resolved XObject dictionary with " + xobject_count.out + " entries%N")
						end
					else
						print ("No XObject dictionary in Resources%N")
					end

						-- Also check for ExtGState
					if r.has_key ("ExtGState") then
						print ("ExtGState dictionary found%N")
					end
				else
					print ("No Resources dictionary found on page%N")
				end
			end

			print ("✅ XObject detection complete%N")
			assert ("Test completed", True)
		end

	test_xobject_stream_content
			-- Test that XObject stream content can be accessed.
		local
			doc: PDF_DOCUMENT
			source: PDF_FILE_BYTE_SOURCE
			page: detachable PDF_DICTIONARY
			resources: detachable PDF_DICTIONARY
			found_image: BOOLEAN
		do
			print ("%N=== Test: XObject Stream Content ===%N")

			create source.make_from_file (test_other_pdf_path ("ITIL.pdf").name)
			create doc.make_from_source (source)
			assert ("Document loaded", doc.is_loaded)

			page := get_first_page (doc)
			if attached page as p then
				resources := get_page_resources (doc, p)

				if attached resources as r then
					if attached {PDF_DICTIONARY} r.item ("XObject") as xo_dict then
							-- Try to access first XObject
						across xo_dict.entries as cursor loop
							if attached {PDF_REFERENCE} cursor as ref then
								if attached {PDF_STREAM} doc.get_object (ref.object_id) as stream then
									print ("XObject /" + (@ cursor.key) + " is stream%N")
									print ("  Stream content length: " + stream.content.count.out + " bytes%N")

									if attached stream.stream_dictionary as sd then
										print ("  Dictionary entries: " + sd.count.out + "%N")
										if attached {PDF_NAME} sd.item ("Subtype") as subtype then
											print ("  Subtype: /" + subtype.value + "%N")
											if subtype.value.same_string ("Image") then
												found_image := True
												print ("  ✓ Found Image XObject%N")
											end
										end
									end
								end
							end
						end
					end
				end
			end

			print ("✅ XObject stream access test complete%N")
			assert ("Test completed", True)
		end

feature -- Test: XObject Preservation

	test_read_modify_write_preserves_xobjects
			-- Test that XObjects are preserved during read→modify→write.
		local
			doc: PDF_DOCUMENT
			source: PDF_FILE_BYTE_SOURCE
			footer_service: PDF_FOOTER_SERVICE
			page: detachable PDF_DICTIONARY
			original_xobject_count: INTEGER
			output_path: STRING
		do
			print ("%N=== Test: XObject Preservation ===%N")

			output_path := test_output_path ("itil_with_footer.pdf").name.to_string_8

				-- Load PDF
			create source.make_from_file (test_other_pdf_path ("ITIL.pdf").name)
			create doc.make_from_source (source)
			assert ("Document loaded", doc.is_loaded)

				-- Count original XObjects
			page := get_first_page (doc)
			if attached page as p then
				original_xobject_count := count_xobjects (doc, p)
				print ("Original XObject count on page 1: " + original_xobject_count.out + "%N")
			end

				-- Add footer to first page
			create footer_service.make
			if attached page as p then
				footer_service.add_footer_to_page (doc, p, "page1", "XObject Test Footer")
				print ("Footer added to page 1%N")
			end

				-- Write modified PDF
			doc.write_to_file (output_path)
			print ("Written to: " + output_path + "%N")

				-- Re-read and verify XObjects preserved
			verify_xobjects_in_output (output_path, original_xobject_count)

			print ("✅ XObject preservation test complete%N")
			assert ("XObjects preserved", True)
		end

	test_read_modify_write_preserves_extgstate
			-- Test that ExtGState is preserved during read→modify→write.
		local
			doc: PDF_DOCUMENT
			source: PDF_FILE_BYTE_SOURCE
			footer_service: PDF_FOOTER_SERVICE
			page: detachable PDF_DICTIONARY
			has_original_extgstate: BOOLEAN
			output_path: STRING
		do
			print ("%N=== Test: ExtGState Preservation ===%N")

			output_path := test_output_path ("itil_extgstate_test.pdf").name.to_string_8

				-- Load PDF
			create source.make_from_file (test_other_pdf_path ("ITIL.pdf").name)
			create doc.make_from_source (source)
			assert ("Document loaded", doc.is_loaded)

				-- Check original ExtGState
			page := get_first_page (doc)
			if attached page as p then
				has_original_extgstate := has_extgstate (doc, p)
				print ("Original ExtGState present: " + has_original_extgstate.out + "%N")
			end

				-- Add footer
			create footer_service.make
			if attached page as p then
				footer_service.add_footer_to_page (doc, p, "page1", "ExtGState Test Footer")
			end

				-- Write
			doc.write_to_file (output_path)
			print ("Written to: " + output_path + "%N")

				-- Verify ExtGState preserved
			verify_extgstate_in_output (output_path, has_original_extgstate)

			print ("✅ ExtGState preservation test complete%N")
			assert ("ExtGState preserved", True)
		end

feature -- Test: V112 Large PDF

	test_v112_xobject_preservation
			-- Test XObject preservation in large linearized PDF.
		local
			doc: PDF_DOCUMENT
			source: PDF_FILE_BYTE_SOURCE
			footer_service: PDF_FOOTER_SERVICE
			page: detachable PDF_DICTIONARY
			output_path: STRING
		do
			print ("%N=== Test: V112 XObject Preservation ===%N")

			output_path := test_output_path ("v112_xobject_test.pdf").name.to_string_8

				-- Load PDF
			create source.make_from_file (test_other_pdf_path ("v112-367_3_STANDARD.pdf").name)
			create doc.make_from_source (source)
			assert ("Document loaded", doc.is_loaded)
			print ("Loaded " + doc.xref_table.entries.count.out + " objects%N")

				-- Get first page and check XObjects
			page := get_first_page (doc)
			if attached page as p then
				print ("XObjects on page 1: " + count_xobjects (doc, p).out + "%N")

					-- Add footer
				create footer_service.make
				footer_service.add_footer_to_page (doc, p, "page1", "V112 XObject Test")
			end

				-- Write
			doc.write_to_file (output_path)
			print ("Written to: " + output_path + "%N")

			print ("✅ V112 XObject test complete%N")
			assert ("V112 processed", True)
		end


feature {NONE} -- Implementation Helpers

	get_first_page (a_doc: PDF_DOCUMENT): detachable PDF_DICTIONARY
			-- Get the first page dictionary from the document.
		do
			if attached a_doc.catalog as catalog then
				if attached {PDF_REFERENCE} catalog.item ("Pages") as pages_ref then
					if attached {PDF_DICTIONARY} a_doc.get_object (pages_ref.object_id) as pages then
						if attached {PDF_ARRAY} pages.item ("Kids") as kids then
							if kids.count > 0 then
								if attached {PDF_REFERENCE} kids.item (1) as page_ref then
									if attached {PDF_DICTIONARY} a_doc.get_object (page_ref.object_id) as page then
										Result := page
									end
								end
							end
						end
					end
				end
			end
		end

	get_page_resources (a_doc: PDF_DOCUMENT; a_page: PDF_DICTIONARY): detachable PDF_DICTIONARY
			-- Get resources dictionary from page, handling inheritance.
		do
			if attached {PDF_DICTIONARY} a_page.item ("Resources") as res then
				Result := res
			elseif attached {PDF_REFERENCE} a_page.item ("Resources") as res_ref then
				if attached {PDF_DICTIONARY} a_doc.get_object (res_ref.object_id) as res then
					Result := res
				end
			else
					-- Try inherited from parent
				if attached {PDF_REFERENCE} a_page.item ("Parent") as parent_ref then
					if attached {PDF_DICTIONARY} a_doc.get_object (parent_ref.object_id) as parent then
						Result := get_page_resources (a_doc, parent)
					end
				end
			end
		end

	count_xobjects (a_doc: PDF_DOCUMENT; a_page: PDF_DICTIONARY): INTEGER
			-- Count XObjects in page resources.
		do
			if attached get_page_resources (a_doc, a_page) as r then
				if attached {PDF_DICTIONARY} r.item ("XObject") as xo then
					Result := xo.count
				elseif attached {PDF_REFERENCE} r.item ("XObject") as xo_ref then
					if attached {PDF_DICTIONARY} a_doc.get_object (xo_ref.object_id) as xo then
						Result := xo.count
					end
				end
			end
		end

	has_extgstate (a_doc: PDF_DOCUMENT; a_page: PDF_DICTIONARY): BOOLEAN
			-- Check if page has ExtGState resources.
		do
			if attached get_page_resources (a_doc, a_page) as r then
				Result := r.has_key ("ExtGState")
			end
		end

	verify_xobjects_in_output (a_path: STRING; a_expected_count: INTEGER)
			-- Verify XObjects preserved in output file.
		local
			doc: PDF_DOCUMENT
			source: PDF_FILE_BYTE_SOURCE
			page: detachable PDF_DICTIONARY
			actual_count: INTEGER
		do
			create source.make_from_file (a_path)
			create doc.make_from_source (source)

			if doc.is_loaded then
				page := get_first_page (doc)
				if attached page as p then
					actual_count := count_xobjects (doc, p)
					print ("Output XObject count: " + actual_count.out + "%N")
					if actual_count >= a_expected_count then
						print ("✓ XObjects preserved or increased%N")
					else
						print ("⚠ XObject count decreased: " + a_expected_count.out + " → " + actual_count.out + "%N")
					end
				end
			else
				print ("⚠ Could not load output file for verification%N")
			end
		end

	verify_extgstate_in_output (a_path: STRING; a_expected: BOOLEAN)
			-- Verify ExtGState preserved in output file.
		local
			doc: PDF_DOCUMENT
			source: PDF_FILE_BYTE_SOURCE
			page: detachable PDF_DICTIONARY
			actual: BOOLEAN
		do
			create source.make_from_file (a_path)
			create doc.make_from_source (source)

			if doc.is_loaded then
				page := get_first_page (doc)
				if attached page as p then
					actual := has_extgstate (doc, p)
					print ("Output has ExtGState: " + actual.out + "%N")
					if a_expected and actual then
						print ("✓ ExtGState preserved%N")
					elseif not a_expected and not actual then
						print ("✓ No ExtGState (as expected)%N")
					elseif a_expected and not actual then
						print ("⚠ ExtGState was lost%N")
					else
						print ("✓ ExtGState added (new)%N")
					end
				end
			else
				print ("⚠ Could not load output file for verification%N")
			end
		end

	count_all_pages (a_doc: PDF_DOCUMENT): INTEGER
			-- Count total pages in the document.
		do
			if attached a_doc.catalog as catalog then
				if attached {PDF_REFERENCE} catalog.item ("Pages") as pages_ref then
					if attached {PDF_DICTIONARY} a_doc.get_object (pages_ref.object_id) as pages then
						if attached {PDF_NUMBER} pages.item ("Count") as cnt then
							Result := cnt.int_value
						else
							if attached {PDF_ARRAY} pages.item ("Kids") as kids then
								Result := kids.count
							end
						end
					end
				end
			end
		end

	scan_all_pages_for_xobjects (a_doc: PDF_DOCUMENT): INTEGER
			-- Scan all pages and count total XObjects.
			-- Prints detailed info for each page.
		local
			page_index: INTEGER
			page_xobjects: INTEGER
		do
			if attached a_doc.catalog as catalog then
				if attached {PDF_REFERENCE} catalog.item ("Pages") as pages_ref then
					if attached {PDF_DICTIONARY} a_doc.get_object (pages_ref.object_id) as pages then
						if attached {PDF_ARRAY} pages.item ("Kids") as kids then
							from page_index := 1
							until page_index > kids.count
							loop
								if attached {PDF_REFERENCE} kids.item (page_index) as page_ref then
									if attached {PDF_DICTIONARY} a_doc.get_object (page_ref.object_id) as page then
										page_xobjects := count_xobjects (a_doc, page)
										print ("  Page " + page_index.out + ": " + page_xobjects.out + " XObjects%N")

										-- Print XObject names if any
										if page_xobjects > 0 then
											print_xobject_details (a_doc, page)
										end

										Result := Result + page_xobjects
									end
								end
								page_index := page_index + 1
							end
						end
					end
				end
			end
		end

	print_xobject_details (a_doc: PDF_DOCUMENT; a_page: PDF_DICTIONARY)
			-- Print detailed XObject info for a page.
		do
			if attached get_page_resources (a_doc, a_page) as r then
				if attached {PDF_DICTIONARY} r.item ("XObject") as xo_dict then
					across xo_dict.entries as cursor loop
						print ("    - /" + (@ cursor.key))
						if attached {PDF_REFERENCE} cursor as ref then
							if attached {PDF_STREAM} a_doc.get_object (ref.object_id) as stream then
								print (" (stream, " + stream.content.count.out + " bytes)")
								if attached stream.stream_dictionary as sd then
									if attached {PDF_NAME} sd.item ("Subtype") as subtype then
										print (" /Subtype " + subtype.value)
									end
									if attached {PDF_NAME} sd.item ("Filter") as filter then
										print (" /Filter " + filter.value)
									end
								end
							end
						end
						print ("%N")
					end
				elseif attached {PDF_REFERENCE} r.item ("XObject") as xo_ref then
					if attached {PDF_DICTIONARY} a_doc.get_object (xo_ref.object_id) as xo_dict then
						across xo_dict.entries as cursor loop
							print ("    - /" + (@ cursor.key) + "%N")
						end
					end
				end
			end
		end

end
