note
	description: "[
		Test suite for Bodea Brochure - Linearized.pdf
		This small linearized PDF serves as a reference test case for:
		- Reading linearized PDFs with XRef streams
		- Parsing /Prev chains
		- Handling PDF 2.0 format
		- Write operations on linearized PDFs
	]"

class
	TEST_BODEA_BROCHURE

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

	test_read_bodea_brochure
			-- Test reading Bodea Brochure - Linearized.pdf
		local
			doc: PDF_DOCUMENT
			source: PDF_FILE_BYTE_SOURCE
			catalog: detachable PDF_DICTIONARY
			pages_ref: detachable PDF_REFERENCE
			pages_dict: detachable PDF_DICTIONARY
			page_count: INTEGER
			pdf_path: PATH
		do
			print ("%N=== Testing Bodea Brochure - Linearized.pdf ===%N")
			
			pdf_path := test_pdf_path ("Bodea Brochure - Linearized.pdf")
			create source.make_from_file (pdf_path.name)
			assert ("Source valid", source.is_valid)
			
			create doc.make_from_source (source)
			assert ("Document loaded", doc.is_loaded)
			
			    -- Verify version (PDF 2.0)
			print ("PDF version: " + doc.version + "%N")
			assert ("PDF 2.0", doc.version.starts_with ("2.0"))
			
			    -- Verify catalog
			catalog := doc.catalog
			assert ("Catalog found", catalog /= Void)
			
			if catalog /= Void then
				print ("Catalog has " + catalog.count.out + " entries%N")
				
				    -- Get Pages
				if attached {PDF_REFERENCE} catalog.item ("Pages") as ref then
					pages_ref := ref
					print ("Pages reference: " + ref.object_id.object_number.out + " 0 R%N")
					
					if attached {PDF_DICTIONARY} doc.get_object (ref.object_id) as dict then
						pages_dict := dict
						
						    -- Get page count
						if attached {PDF_NUMBER} dict.item ("Count") as num then
							page_count := num.int_value
							print ("Page count: " + page_count.out + "%N")
							assert ("Has pages", page_count > 0)
						end
					end
				end
			end
			
			    -- Check XRef table entries
			if attached doc.xref_table.entries as entries then
				print ("Total XRef entries: " + entries.count.out + "%N")
				assert ("Has XRef entries", entries.count > 0)
				
				    -- Count entry types
				print_xref_statistics (doc)
			end
		end
	
	test_analyze_bodea_structure
			-- Analyze and report detailed structure of Bodea Brochure
		local
			doc: PDF_DOCUMENT
			source: PDF_FILE_BYTE_SOURCE
			obj_id: PDF_OBJECT_ID
			obj: detachable PDF_OBJECT
			success_count, fail_count: INTEGER
			pdf_path: PATH
		do
			print ("%N=== Analyzing Bodea Brochure Structure ===%N")
			
			pdf_path := test_pdf_path ("Bodea Brochure - Linearized.pdf")
			create source.make_from_file (pdf_path.name)
			create doc.make_from_source (source)
			
			if doc.is_loaded and then attached doc.xref_table.entries as entries then
				print ("%NTotal objects in XRef: " + entries.count.out + "%N")
				print ("Object number range: ")
				
				    -- Find range
				across entries as c loop
					if @ c.key > 0 then
						print (@ c.key.out + " ")
						if (@ c.key < 50) or (@ c.key > 400 and @ c.key < 450) then
								-- Print sample object numbers
						end
					end
				end
				
				print ("%N%NAttempting to load all objects...%N")
				
				    -- Try loading each object
				across entries as c loop
					if (@ c.item).is_in_use then
						create obj_id.make (@ c.key, (@ c.item).generation)
						obj := doc.get_object (obj_id)
						
						if obj /= Void then
							success_count := success_count + 1
						else
							fail_count := fail_count + 1
							if fail_count <= 10 then
								print ("  Failed to load object " + (@ c.key).out + " (offset=" + (@ c.item).offset.out + ")%N")
							end
						end
					end
				end
				
				print ("%NLoad results:%N")
				print ("  Success: " + success_count.out + "%N")
				print ("  Failed: " + fail_count.out + "%N")
				assert ("Most objects loaded", success_count > fail_count)
			end
		end
	
	test_write_bodea_brochure
			-- Test write operation on Bodea Brochure
		local
			doc: PDF_DOCUMENT
			source: PDF_FILE_BYTE_SOURCE
			output: STRING_8
			pdf_path, output_path: PATH
		do
			print ("%N=== Testing Write of Bodea Brochure ===%N")
			
			pdf_path := test_pdf_path ("Bodea Brochure - Linearized.pdf")
			create source.make_from_file (pdf_path.name)
			create doc.make_from_source (source)
			assert ("Document loaded", doc.is_loaded)
			
			    -- Serialize to bytes
			output := doc.to_bytes
			print ("Output size: " + output.count.out + " bytes%N")
			print ("Original size: " + source.byte_count.out + " bytes%N")
			
			    -- Write to file
			output_path := test_output_path ("bodea_brochure_output.pdf")
			doc.write_to_file (output_path.name)
			print ("Written to " + output_path.name + "%N")
			
			    -- Basic validation
			assert ("Output not empty", output.count > 1000)
			assert ("Has PDF header", output.starts_with ("%%PDF-"))
			assert ("Has EOF", output.has_substring ("%%EOF"))
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
