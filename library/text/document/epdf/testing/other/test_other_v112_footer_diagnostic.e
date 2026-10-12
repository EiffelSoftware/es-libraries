note
	description: "[
		Diagnostic test for v112 footer issue
		Compares v112 structure before and after footer injection
	]"

class
	TEST_OTHER_V112_FOOTER_DIAGNOSTIC

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

	test_v112_structure_before_footer
			-- Analyze v112 structure before adding footer
		local
			doc: PDF_DOCUMENT
			source: PDF_FILE_BYTE_SOURCE
			catalog: detachable PDF_DICTIONARY
			pages_dict: detachable PDF_DICTIONARY
			first_page: detachable PDF_DICTIONARY
			contents_obj: detachable PDF_OBJECT
			pdf_path: PATH
		do
			print ("%N=== v112 Structure BEFORE Footer ===%N")

			pdf_path := test_other_pdf_path ("v112-367_3_STANDARD.pdf")
			create source.make_from_file (pdf_path.name)
			create doc.make_from_source (source)
			assert ("Document loaded", doc.is_loaded)

			print ("XRef entries: " + doc.xref_table.entries.count.out + "%N")
			print ("New objects: " + doc.new_objects.count.out + "%N")

			catalog := doc.catalog
			if catalog /= Void then
				print ("Catalog entries: " + catalog.count.out + "%N")

				if attached {PDF_REFERENCE} catalog.item ("Pages") as pages_ref then
					if attached {PDF_DICTIONARY} doc.get_object (pages_ref.object_id) as pd then
						pages_dict := pd
						print ("Pages dictionary found%N")

						    -- Check first page structure
						if attached {PDF_ARRAY} pages_dict.item ("Kids") as kids then
							print ("Kids array count: " + kids.count.out + "%N")

							if attached {PDF_REFERENCE} kids.item (1) as first_page_ref then
								if attached {PDF_DICTIONARY} doc.get_object (first_page_ref.object_id) as fp then
									first_page := fp
									print ("First page object: " + first_page_ref.object_id.object_number.out + "%N")

									    -- Check Contents type
									contents_obj := first_page.item ("Contents")
									if attached {PDF_REFERENCE} contents_obj as cont_ref then
										print ("Contents is PDF_REFERENCE: " + cont_ref.object_id.object_number.out + "%N")
									elseif attached {PDF_ARRAY} contents_obj as cont_array then
										print ("Contents is PDF_ARRAY with " + cont_array.count.out + " items%N")
									elseif attached {PDF_STREAM} contents_obj as cont_stream then
										print ("Contents is PDF_STREAM (direct)%N")
									else
										print ("Contents type: " + (if contents_obj /= Void then contents_obj.generator else "Void" end) + "%N")
									end
								end
							end
						end
					end
				end
			end

			assert ("Structure analyzed", True)
		end

	test_v112_footer_step_by_step
			-- Add footer step by step with detailed logging
		local
			doc: PDF_DOCUMENT
			source: PDF_FILE_BYTE_SOURCE
			footer_service: PDF_FOOTER_SERVICE
		do
			print ("%N=== v112 Footer Step-by-Step ===%N")

			create source.make_from_file (test_other_pdf_path ("v112-367_3_STANDARD.pdf").name)
			create doc.make_from_source (source)
			assert ("Document loaded", doc.is_loaded)

			print ("Step 1: Document loaded%N")
			print ("  XRef entries: " + doc.xref_table.entries.count.out + "%N")
			print ("  New objects (before): " + doc.new_objects.count.out + "%N")

			print ("%NStep 2: Creating footer service%N")
			create footer_service.make
			footer_service.set_margin (20.0)
			footer_service.set_font_size (8.0)
			print ("  Footer service configured%N")

			print ("%NStep 3: Adding footer to document%N")
			footer_service.add_footer_to_document (doc, "Test Footer - 2025/12/26")
			print ("  Footer added%N")
			print ("  New objects (after): " + doc.new_objects.count.out + "%N")

			print ("%NStep 4: Writing to file%N")
			doc.write_to_file (test_output_path ("v112_footer_diagnostic.pdf").name)
			print ("  Written to: " + test_output_path ("v112_footer_diagnostic.pdf").name + "%N")

			assert ("Footer added with logging", True)
		end

	test_compare_bodea_vs_v112_footer
			-- Compare how footer works on Bodea vs v112
		local
			bodea_doc, v112_doc: PDF_DOCUMENT
			bodea_source, v112_source: PDF_FILE_BYTE_SOURCE
			footer_service: PDF_FOOTER_SERVICE
		do
			print ("%N=== Comparing Bodea vs v112 Footer ===%N")

			    -- Bodea
			print ("%N--- Bodea Brochure ---%N")
			create bodea_source.make_from_file (test_other_pdf_path ("Bodea Brochure - Linearized.pdf").name)
			create bodea_doc.make_from_source (bodea_source)
			print ("Loaded: " + bodea_source.byte_count.out + " bytes%N")
			print ("Objects: " + bodea_doc.xref_table.entries.count.out + "%N")
			print ("New objects before: " + bodea_doc.new_objects.count.out + "%N")

			create footer_service.make
			footer_service.set_margin (20.0)
			footer_service.set_font_size (8.0)
			footer_service.add_footer_to_document (bodea_doc, "Bodea Test")
			print ("New objects after: " + bodea_doc.new_objects.count.out + "%N")

			    -- v112
			print ("%N--- v112 Standard ---%N")
			create v112_source.make_from_file (test_other_pdf_path("v112-367_3_STANDARD.pdf").name)
			create v112_doc.make_from_source (v112_source)
			print ("Loaded: " + v112_source.byte_count.out + " bytes%N")
			print ("Objects: " + v112_doc.xref_table.entries.count.out + "%N")
			print ("New objects before: " + v112_doc.new_objects.count.out + "%N")

			create footer_service.make
			footer_service.add_footer_to_document (v112_doc, "v112 Test")
			print ("New objects after: " + v112_doc.new_objects.count.out + "%N")

			assert ("Comparison done", True)
		end

end
