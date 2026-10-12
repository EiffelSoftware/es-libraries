note
	description: "[
		Runner for tests requiring pdf/other samples.
		Inherits TEST_RUNNER (base suite) and runs the other cases as well.
	]"

class
	TEST_OTHER_RUNNER

inherit
	TEST_RUNNER
		redefine
			make
		end

create
	make

feature -- Initialization

	make
			-- Run base suite, then other (external PDF) suites.
		do
			Precursor
			run_other_phase13_aes_tests
			test_phase2_linearized_pdf
			test_other_phase4b_part3
		end

feature -- Other automated suites

	run_other_phase13_aes_tests
			-- Run Phase 13 AES tests requiring pdf/other samples.
		local
			other_aes_tests: TEST_OTHER_PHASE13_AES_INTEGRATION
		do
			print ("%N========================================%N")
			print ("Phase 13 (other): AES tests with external PDFs%N")
			print ("========================================%N")

			create other_aes_tests.default_create
			other_aes_tests.on_prepare

			print ("Running test_create_aes128_encrypted_pdf...%N")
			other_aes_tests.test_create_aes128_encrypted_pdf

			print ("Running test_read_back_aes128_encrypted_pdf...%N")
			other_aes_tests.test_read_back_aes128_encrypted_pdf

			print ("Running test_aes128_footer_and_encrypt...%N")
			other_aes_tests.test_aes128_footer_and_encrypt

			print ("Running test_aes128_wrong_password_fails...%N")
			other_aes_tests.test_aes128_wrong_password_fails

			print ("Running test_aes128_string_decryption...%N")
			other_aes_tests.test_aes128_string_decryption

			print ("Running test_aes128_stream_decryption...%N")
			other_aes_tests.test_aes128_stream_decryption

			print ("All Phase 13 (other) AES tests passed (6 tests)%N")
		end

	test_phase2_linearized_pdf
		local
			t2: TEST_OTHER_PHASE2D_LINEARIZED_PDF
		do
			print ("Running Phase 2D Linearized PDF Tests...%N")
			create t2

			print ("%N=== Test 1: XRef Entry Counts ===%N")
			t2.test_xref_entry_counts

			print ("%N=== Test 2: /Prev Chain Parsing ===%N")
			t2.test_prev_chain_parsing

			print ("%N=== Test 3: Object Loading Success Rate ===%N")
			t2.test_object_loading_success_rate

			print ("%N=== Test 4: Catalog and Pages Accessible ===%N")
			t2.test_catalog_and_pages_accessible

			print ("%NPhase 2D Tests Complete%N")
		end


	test_other_phase4b_part3
			-- Run Phase 4B Part 3 integration tests requiring pdf/other/ITIL.pdf.
		local
			integration: TEST_OTHER_PHASE4B_INTEGRATION
		do
			print ("%N=== Part 3 (other): Full Integration Tests ===%N")
			if has_other_test_pdf ("ITIL.pdf") then
				create integration
				print ("  - Testing ITIL footer only... ")
				integration.test_footer_only_ITIL
				print ("PASS%N")

				print ("  - Testing ITIL footer + encryption... ")
				integration.test_sign_and_encrypt_ITIL_view_only
				print ("PASS%N")
			else
				print ("  - SKIPPED: sample %"ITIL.pdf%" is not available in testing/pdf/other (see README.md)%N")
			end
		end

feature -- Other manual workflows (moved from TEST_RUNNER)

	test_eth_stamper_workflow
			-- Test adding ETH footer to "The_viterbi_algorithm-1.pdf".
		local
			source: PDF_FILE_BYTE_SOURCE
			doc: PDF_DOCUMENT
			footer_service: PDF_FOOTER_SERVICE
			output_path: PATH
			output_source: PDF_FILE_BYTE_SOURCE
		do
			print ("%N========================================%N")
			print ("ETH Stamper Workflow Test%N")
			print ("========================================%N%N")

			print ("Step 1: Loading source PDF...%N")
			create source.make_from_file (test_pdf_path ("The_viterbi_algorithm-1.pdf").name)
			create doc.make_from_source (source)

			if doc.is_loaded then
				print ("  ✓ PDF loaded successfully%N")

				print ("Step 2: Stamping footer...%N")
				create footer_service.make
				footer_service.set_font_size (7.0) -- Small font as seen in inspection
				footer_service.set_margin (22.0) -- Approx y position from inspection (21.908)
				footer_service.add_footer_to_document (doc, "Authorized licensed use limited to: ETH BIBLIOTHEK ZURICH. Downloaded on December 29,2025 at 15:09:04 UTC from IEEE Xplore. Restrictions apply.")
				print ("  ✓ Footer stamped%N")

				print ("Step 3: Writing output...%N")
				output_path := test_output_path ("eth_stamped.pdf")
				ensure_test_output_directory_exists
				doc.write_to_file (output_path.name)
				print ("  ✓ Written to " + output_path.name + "%N")

				create output_source.make_from_file (output_path.name)
				print ("  Output size: " + output_source.byte_count.out + " bytes%N")
			else
				print ("  ✗ FAILED: Could not load PDF%N")
			end

			print ("%N========================================%N")
		end


	test_v112_footer_injection
			-- Test footer injection on V112-367_3_STANDARD.pdf (linearized PDF with XRef streams).
			-- Verifies end-to-end workflow: load, inject footer, write, validate size.
		local
			source: PDF_FILE_BYTE_SOURCE
			doc: PDF_DOCUMENT
			footer_service: PDF_FOOTER_SERVICE
			output_path: PATH
			output_source: PDF_FILE_BYTE_SOURCE
			original_size, output_size: INTEGER
			source_file: RAW_FILE
		do
			print ("%N========================================%N")
			print ("V112 Linearized PDF Footer Injection Test%N")
			print ("========================================%N%N")

				-- Step 1: Load V112 PDF
			print ("Step 1: Loading v112-367_3_STANDARD.pdf...%N")

			-- Diagnostic check for file existence
			if attached test_other_pdf_path ("v112-367_3_STANDARD.pdf") as l_path then
				print ("  Looking for file at: " + l_path.absolute_path.name + "%N")
				create source_file.make_with_path (l_path)
				if not source_file.exists then
					print ("  [CRITICAL] File DOES NOT EXIST at this path.%N")
					print ("  Current Working Directory: " + (create {PATH}.make_current).absolute_path.name + "%N")
					print ("%N  PLEASE RUN THE APPLICATION FROM THE PROJECT ROOT DIRECTORY.%N")
					print ("  Expected working directory should contain 'testing/pdf/' folder.%N")
					check file_exists: False then end
				end
				create source.make_from_file (l_path.name)
				original_size := source.byte_count
				print ("  Original file size: " + original_size.out + " bytes%N")

				create doc.make_from_source (source)

				if doc.is_loaded then
					print ("  ✓ PDF loaded successfully%N")
					print ("  XRef entries: " + doc.xref_table.entries.count.out + "%N")
				else
					print ("  ✗ FAILED: PDF not loaded%N")
					check pdf_loaded: False then end
				end

					-- Step 2: Inject footer to all pages
				print ("%NStep 2: Injecting footer to all pages...%N")
				create footer_service.make
				footer_service.set_font_size (7.0)
				footer_service.set_margin (22.0)
				footer_service.add_footer_to_document (doc, "Sign to JV 29-12-2025")
				print ("  ✓ Footer injection complete%N")
					-- Step 3: Write output PDF
				output_path := test_output_path ("v112_with_footer.pdf")
				print ("%NStep 3: Writing output to " + output_path.name + "...%N")
				ensure_test_output_directory_exists
				doc.write_to_file (output_path.name)
				print ("  ✓ Output file written%N")

					-- Step 4: Validate output
				print ("%NStep 4: Validating output...%N")
				create output_source.make_from_file (output_path.name)
				output_size := output_source.byte_count
				print ("  Output file size: " + output_size.out + " bytes%N")

					-- Size check: output should be reasonable (not 10x larger or much smaller)
				if output_size > original_size // 10 and output_size < original_size * 5 then
					print ("  ✓ Output size is reasonable%N")
				else
					print ("  ⚠ WARNING: Output size may indicate issues%N")
				end

				print ("%N========================================%N")
				print ("✓ V112 FOOTER INJECTION TEST COMPLETE%N")
				print ("========================================%N")
				print ("%NPlease open " + output_path.name + " in a PDF reader to verify:%N")
				print ("  - Document opens without errors%N")
				print ("  - Footer text appears at bottom of pages%N")
				print ("  - No garbage characters or corruption%N")
			end
		end


	test_object_stream_writing
			-- Test Object Stream writing compresses output significantly.
			-- Compares file sizes between traditional and Object Stream modes.
		local
			source: PDF_FILE_BYTE_SOURCE
			doc: PDF_DOCUMENT
			writer: PDF_DOCUMENT_WRITER
			traditional_output, objstm_output: STRING_8
			traditional_size, objstm_size: INTEGER
			reduction_percent: REAL_64
			traditional_file: RAW_FILE
		do
			print ("%N========================================%N")
			print ("Phase 5A: Object Stream Writing Test%N")
			print ("========================================%N%N")

			-- Load a complex PDF with many objects
			print ("Step 1: Loading v112-367_3_STANDARD.pdf...%N")
			create source.make_from_file (test_other_pdf_path ("v112-367_3_STANDARD.pdf").name)
			create doc.make_from_source (source)

			if doc.is_loaded then
				print ("  ✓ PDF loaded (%N" + doc.xref_table.entries.count.out + " xref entries)%N")

				-- Test traditional writing
				print ("%NStep 2: Writing with traditional mode...%N")
				create writer.make
				writer.write_document (doc)
				traditional_output := writer.last_output
				traditional_size := traditional_output.count
				print ("  Traditional output size: " + traditional_size.out + " bytes%N")

				-- Re-load for Object Stream test (to ensure fresh state)
				create source.make_from_file (test_other_pdf_path ("v112-367_3_STANDARD.pdf").name)
				create doc.make_from_source (source)

				-- Test Object Stream writing
				print ("%NStep 3: Writing with Object Stream mode...%N")
				create writer.make
				writer.set_use_object_streams (True)
				writer.write_document_with_objstm (doc)
				objstm_output := writer.last_output
				objstm_size := objstm_output.count
				print ("  Object Stream output size: " + objstm_size.out + " bytes%N")

				-- Compare sizes
				print ("%NStep 4: Comparing sizes...%N")
				if traditional_size > 0 then
					reduction_percent := ((traditional_size - objstm_size) / traditional_size) * 100
					print ("  Size reduction: " + reduction_percent.out + "%%%N")

					if objstm_size < traditional_size then
						print ("  ✓ Object Stream mode produced smaller output%N")
					else
						print ("  ⚠ Object Stream mode did not reduce size (may be normal for some PDFs)%N")
					end
				end

				-- Write files for manual inspection
				print ("%NStep 5: Writing output files...%N")
				ensure_test_output_directory_exists

				-- Write traditional output
				create traditional_file.make_create_read_write (test_output_path ("v112_traditional.pdf").name)
				traditional_file.put_string (traditional_output)
				traditional_file.close
				print ("  Written: " + test_output_path ("v112_traditional.pdf").name + "%N")

				-- Write objstm output (may fail if file is locked by Adobe)
				write_objstm_output (objstm_output)

				print ("%N========================================%N")
				print ("✓ OBJECT STREAM TEST COMPLETE%N")
				print ("========================================%N")
				print ("%NPlease verify both PDFs open correctly in a PDF reader.%N")
			else
				print ("  ✗ FAILED: Could not load PDF%N")
			end
		end


	write_objstm_output (content: STRING_8)
			-- Write Object Stream output, handling potential file lock errors.
		local
			objstm_file: RAW_FILE
			retried: BOOLEAN
			output_path: PATH
		do
			if not retried then
				output_path := test_output_path ("v112_objstm.pdf")
				create objstm_file.make_create_read_write (output_path.name)
				objstm_file.put_string (content)
				objstm_file.close
				print ("  Written: " + output_path.name + "%N")
			else
				print ("  ⚠ Could not write v112_objstm.pdf (file may be locked by Adobe)%N")
				print ("    Close Adobe Acrobat and run test again.%N")
			end
		rescue
			retried := True
			retry
		end


	test_xref_stream_writing
			-- Test standalone XRef stream writing (Phase 5B).
			-- Uses XRef stream instead of traditional xref table.
		local
			source: PDF_FILE_BYTE_SOURCE
			doc: PDF_DOCUMENT
			writer: PDF_DOCUMENT_WRITER
			traditional_output, xrefstm_output: STRING_8
			traditional_size, xrefstm_size: INTEGER
			reduction_bytes: INTEGER
			xrefstm_file: RAW_FILE
		do
			print ("%N========================================%N")
			print ("Phase 5B: XRef Stream Writing Test%N")
			print ("========================================%N%N")

			-- Load PDF
			print ("Step 1: Loading v112-367_3_STANDARD.pdf...%N")
			create source.make_from_file (test_other_pdf_path ("v112-367_3_STANDARD.pdf").name)
			create doc.make_from_source (source)

			if doc.is_loaded then
				print ("  ✓ PDF loaded%N")

				-- Test traditional writing
				print ("%NStep 2: Writing with traditional xref table...%N")
				create writer.make
				writer.write_document (doc)
				traditional_output := writer.last_output
				traditional_size := traditional_output.count
				print ("  Traditional output size: " + traditional_size.out + " bytes%N")

				-- Re-load for XRef stream test
				create source.make_from_file (test_other_pdf_path ("v112-367_3_STANDARD.pdf").name)
				create doc.make_from_source (source)

				-- Test XRef stream writing
				print ("%NStep 3: Writing with XRef stream...%N")
				create writer.make
				writer.set_use_xref_stream (True)
				writer.write_document (doc)
				xrefstm_output := writer.last_output
				xrefstm_size := xrefstm_output.count
				print ("  XRef stream output size: " + xrefstm_size.out + " bytes%N")

				-- Compare sizes
				print ("%NStep 4: Comparing sizes...%N")
				reduction_bytes := traditional_size - xrefstm_size
				print ("  Size difference: " + reduction_bytes.out + " bytes%N")

				if xrefstm_size < traditional_size then
					print ("  ✓ XRef stream mode produced smaller output%N")
				elseif xrefstm_size = traditional_size then
					print ("  ~ XRef stream output same size (xref may be small)%N")
				else
					print ("  ⚠ XRef stream larger (expected for simple PDFs)%N")
				end

				-- Write for manual inspection
				print ("%NStep 5: Writing output file...%N")
				ensure_test_output_directory_exists

				create xrefstm_file.make_create_read_write (test_output_path ("v112_xrefstm.pdf").name)
				xrefstm_file.put_string (xrefstm_output)
				xrefstm_file.close
				print ("  Written: " + test_output_path ("v112_xrefstm.pdf").name + "%N")

				print ("%N========================================%N")
				print ("✓ XREF STREAM TEST COMPLETE%N")
				print ("========================================%N")
			else
				print ("  ✗ FAILED: Could not load PDF%N")
			end
		end


	test_incremental_update
			-- Test incremental update (Phase 5C).
			-- Modifies a document and appends changes.
		local
			source: PDF_FILE_BYTE_SOURCE
			doc: PDF_DOCUMENT
			writer: PDF_INCREMENTAL_WRITER
			original_size, new_size: INTEGER
			delta: INTEGER
			string_obj: PDF_STRING
		do
			print ("%N========================================%N")
			print ("Phase 5C: Incremental Update Test%N")
			print ("========================================%N%N")

			-- Load PDF
			print ("Step 1: Loading v112-367_3_STANDARD.pdf...%N")
			create source.make_from_file (test_other_pdf_path ("v112-367_3_STANDARD.pdf").name)
			create doc.make_from_source (source)

			if doc.is_loaded then
				print ("  ✓ PDF loaded%N")
				original_size := source.byte_count
				print ("  Original size: " + original_size.out + " bytes%N")

				-- Modify Info dictionary
				print ("%NStep 2: Modifying Info dictionary...%N")
				if attached doc.trailer as t and then attached t.dictionary.item ("Info") as info_obj then
					if attached {PDF_REFERENCE} info_obj as info_ref then
						-- We need the actual dictionary object, not just the reference
						if attached {PDF_DICTIONARY} doc.get_object (info_ref.object_id) as info_dict then
							print ("  Found Info dictionary (Obj " + info_ref.object_id.object_number.out + ")%N")

							-- Add a custom key
							create string_obj.make_literal ("Incremental Update Test")
							info_dict.put (string_obj, "CustomMod")

							-- Mark as modified
							doc.mark_modified (info_ref.object_id)
							print ("  Marked Info dictionary as modified%N")

							-- Write incremental update
							print ("%NStep 3: Writing incremental update...%N")
							ensure_test_output_directory_exists
							create writer.make
							writer.write_incremental_update (doc, test_other_pdf_path ("v112-367_3_STANDARD.pdf").name, test_output_path ("v112_inc_v3.pdf").name)

							-- Verify
							print ("%NStep 4: Verifying output...%N")
							create source.make_from_file (test_output_path ("v112_inc_v3.pdf").name)
							new_size := source.byte_count
							print ("  New size: " + new_size.out + " bytes%N")

							delta := new_size - original_size
							print ("  Delta: " + delta.out + " bytes%N")

							if delta > 0 and delta < 5000 then
								print ("  ✓ Incremental update successful (small delta)%N")
							else
								print ("  ⚠ Delta unexpected: " + delta.out + " (too large for partial update?)%N")
							end

							-- Parse verification
							create doc.make_from_source (source)
							check incremental_update_parsed: doc.is_loaded end
							print ("  ✓ Incremental update PDF parsed and validated successfully%N")
						else
							print ("  ✗ FAILED: Could not resolve Info dictionary%N")
						end
					else
						print ("  ✗ FAILED: Info entry is not a reference (Object streams not supported yet)%N")
					end
				else
					print ("  ✗ FAILED: No Info dictionary in trailer%N")
				end

				print ("%N========================================%N")
				print ("✓ INCREMENTAL UPDATE TEST COMPLETE%N")
				print ("========================================%N")
			else
				print ("  ✗ FAILED: Could not load PDF%N")
			end
		end


	test_incremental_with_footer
			-- Test incremental update with footer injection (Phase 5C).
			-- Adds footer via incremental update instead of full rewrite.
		local
			source: PDF_FILE_BYTE_SOURCE
			doc: PDF_DOCUMENT
			writer: PDF_INCREMENTAL_WRITER
			footer_service: PDF_FOOTER_SERVICE
			original_size, new_size: INTEGER
			delta: INTEGER
		do
			print ("%N========================================%N")
			print ("Phase 5C: Incremental Update with Footer%N")
			print ("========================================%N%N")

				-- Load PDF
			print ("Step 1: Loading v112-367_3_STANDARD.pdf...%N")
			create source.make_from_file (test_other_pdf_path ("v112-367_3_STANDARD.pdf").name)
			create doc.make_from_source (source)

			if doc.is_loaded then
				print ("  ✓ PDF loaded%N")
				original_size := source.byte_count
				print ("  Original size: " + original_size.out + " bytes%N")

					-- Add footer to all pages
				print ("%NStep 2: Adding footer to pages...%N")
				create footer_service.make
				footer_service.set_font_size (7.0)
				footer_service.set_margin (22.0)
				footer_service.add_footer_to_document (doc, "Incremental Footer Test - 30-12-2025")
				print ("  ✓ Footer added to document%N")
				print ("  Modified objects count: " + doc.modified_objects.count.out + "%N")
				print ("  New objects count: " + doc.new_objects.count.out + "%N")

					-- Write incremental update
				print ("%NStep 3: Writing incremental update...%N")
				ensure_test_output_directory_exists
				create writer.make
				writer.write_incremental_update (doc, test_other_pdf_path ("v112-367_3_STANDARD.pdf").name, test_output_path ("v112_inc_footer_v3.pdf").name)

					-- Verify
				print ("%NStep 4: Verifying output...%N")
				create source.make_from_file (test_output_path ("v112_inc_footer_v3.pdf").name)
				new_size := source.byte_count
				print ("  New size: " + new_size.out + " bytes%N")

				delta := new_size - original_size
				print ("  Delta: " + delta.out + " bytes%N")

				if delta > 0 and delta < 10000 then
					print ("  ✓ Incremental update with footer successful%N")
				else
					print ("  ⚠ Delta unexpected: " + delta.out + " bytes%N")
				end

				-- Parse verification
				create doc.make_from_source (source)
				check incremental_footer_parsed: doc.is_loaded end
				print ("  ✓ Incremental footer PDF parsed and validated successfully%N")

				print ("%N========================================%N")
				print ("✓ INCREMENTAL FOOTER TEST COMPLETE%N")
				print ("========================================%N")
			else
				print ("  ✗ FAILED: Could not load PDF%N")
			end
		end


	test_incremental_with_permissions
			-- Test incremental update with permission changes (Phase 5C).
			-- Applies encryption/permissions via incremental update.
		local
			source: PDF_FILE_BYTE_SOURCE
			doc: PDF_DOCUMENT
			writer: PDF_INCREMENTAL_WRITER
			handler: PDF_STANDARD_SECURITY_HANDLER
			permissions: PDF_PERMISSIONS
			encrypt_dict: PDF_DICTIONARY
			file_id: PDF_ARRAY
			encrypt_ref: PDF_REFERENCE
			encrypt_id: PDF_OBJECT_ID
			original_size, new_size: INTEGER
			delta: INTEGER
		do
			print ("%N========================================%N")
			print ("Phase 5C: Incremental Update with Permissions%N")
			print ("========================================%N%N")

				-- Load PDF
			print ("Step 1: Loading v112-367_3_STANDARD.pdf...%N")
			create source.make_from_file (test_other_pdf_path ("v112-367_3_STANDARD.pdf").name)
			create doc.make_from_source (source)

			if doc.is_loaded then
				print ("  ✓ PDF loaded%N")
				original_size := source.byte_count
				print ("  Original size: " + original_size.out + " bytes%N")

					-- Apply permissions (view-only)
				print ("%NStep 2: Applying permissions (view-only)...%N")
				create permissions.make_all_restricted

					-- Create file ID
				create file_id.make_empty
				file_id.add (create {PDF_STRING}.make_literal ("v112IncPerm"))
				file_id.add (create {PDF_STRING}.make_literal ("v112IncPerm"))

					-- Create encrypt dictionary
				create encrypt_dict.make_empty
				encrypt_dict.put_name ("Standard", "Filter")
				encrypt_dict.put_number (1, "V")
				encrypt_dict.put_number (2, "R")
				encrypt_dict.put_number (40, "Length")
				encrypt_dict.put_number (permissions.flags, "P")

					-- Create security handler
				create handler.make (encrypt_dict, file_id, "")
				handler.compute_password_entries ("", "owner123")

					-- Add computed U and O values
				encrypt_dict.put_hex_string (handler.u_entry, "U")
				encrypt_dict.put_hex_string (handler.o_entry, "O")

					-- Add encrypt dictionary to document
				encrypt_id := doc.add_object (encrypt_dict)
				create encrypt_ref.make (encrypt_id)

					-- Add /Encrypt and /ID to trailer
				if attached doc.trailer as t then
					t.dictionary.put (encrypt_ref, "Encrypt")
					t.dictionary.put (file_id, "ID")
				end

				doc.set_security_handler (handler)
				print ("  ✓ Permissions applied%N")

					-- Write incremental update
				print ("%NStep 3: Writing incremental update...%N")
				ensure_test_output_directory_exists
				create writer.make
				writer.write_incremental_update (doc, test_other_pdf_path ("v112-367_3_STANDARD.pdf").name, test_output_path ("v112_inc_permissions_v3.pdf").name)

					-- Verify
				print ("%NStep 4: Verifying output...%N")
				create source.make_from_file (test_output_path ("v112_inc_permissions_v3.pdf").name)
				new_size := source.byte_count
				print ("  New size: " + new_size.out + " bytes%N")

				delta := new_size - original_size
				print ("  Delta: " + delta.out + " bytes%N")

				if delta > 0 and delta < 10000 then
					print ("  ✓ Incremental update with permissions successful%N")
				else
					print ("  ⚠ Delta unexpected: " + delta.out + " bytes%N")
				end

				-- Parse verification
				create doc.make_from_source (source)
				check incremental_permissions_parsed: doc.is_loaded end
				print ("  ✓ Incremental permissions PDF parsed and validated successfully%N")

				print ("%N========================================%N")
				print ("✓ INCREMENTAL PERMISSIONS TEST COMPLETE%N")
				print ("========================================%N")
			else
				print ("  ✗ FAILED: Could not load PDF%N")
			end
		end


	test_incremental_with_footer_and_permissions
			-- Test incremental update with both footer and permissions (Phase 5C).
			-- Combines footer injection and encryption in a single incremental update.
		local
			source: PDF_FILE_BYTE_SOURCE
			doc: PDF_DOCUMENT
			writer: PDF_INCREMENTAL_WRITER
			footer_service: PDF_FOOTER_SERVICE
			handler: PDF_STANDARD_SECURITY_HANDLER
			permissions: PDF_PERMISSIONS
			encrypt_dict: PDF_DICTIONARY
			file_id: PDF_ARRAY
			encrypt_ref: PDF_REFERENCE
			encrypt_id: PDF_OBJECT_ID
			original_size, new_size: INTEGER
			delta: INTEGER
		do
			print ("%N========================================%N")
			print ("Phase 5C: Incremental Update with Footer & Permissions%N")
			print ("========================================%N%N")

				-- Load PDF
			print ("Step 1: Loading v112-367_3_STANDARD.pdf...%N")
			create source.make_from_file (test_other_pdf_path ("v112-367_3_STANDARD.pdf").name)
			create doc.make_from_source (source)

			if doc.is_loaded then
				print ("  ✓ PDF loaded%N")
				original_size := source.byte_count
				print ("  Original size: " + original_size.out + " bytes%N")

					-- Add footer to all pages
				print ("%NStep 2: Adding footer to pages...%N")
				create footer_service.make
				footer_service.set_font_size (7.0)
				footer_service.set_margin (22.0)
				footer_service.add_footer_to_document (doc, "Authorized - View Only - 30-12-2025")
				print ("  ✓ Footer added to document%N")

					-- Apply permissions (print-only)
				print ("%NStep 3: Applying permissions (print-only)...%N")
				create permissions.make_all_restricted
				permissions.enable_print
				permissions.enable_print_high_quality

					-- Create file ID
				create file_id.make_empty
				file_id.add (create {PDF_STRING}.make_literal ("v112IncFootPerm"))
				file_id.add (create {PDF_STRING}.make_literal ("v112IncFootPerm"))

					-- Create encrypt dictionary
				create encrypt_dict.make_empty
				encrypt_dict.put_name ("Standard", "Filter")
				encrypt_dict.put_number (1, "V")
				encrypt_dict.put_number (2, "R")
				encrypt_dict.put_number (40, "Length")
				encrypt_dict.put_number (permissions.flags, "P")

					-- Create security handler
				create handler.make (encrypt_dict, file_id, "")
				handler.compute_password_entries ("", "owner123")

					-- Add computed U and O values
				encrypt_dict.put_hex_string (handler.u_entry, "U")
				encrypt_dict.put_hex_string (handler.o_entry, "O")

					-- Add encrypt dictionary to document
				encrypt_id := doc.add_object (encrypt_dict)
				create encrypt_ref.make (encrypt_id)

					-- Add /Encrypt and /ID to trailer
				if attached doc.trailer as t then
					t.dictionary.put (encrypt_ref, "Encrypt")
					t.dictionary.put (file_id, "ID")
				end

				doc.set_security_handler (handler)
				print ("  ✓ Permissions applied%N")

					-- Write incremental update
				print ("%NStep 4: Writing incremental update...%N")
				ensure_test_output_directory_exists
				create writer.make
				writer.write_incremental_update (doc, test_other_pdf_path ("v112-367_3_STANDARD.pdf").name, test_output_path ("v112_inc_footer_permissions_v3.pdf").name)

					-- Verify
				print ("%NStep 5: Verifying output...%N")
				create source.make_from_file (test_output_path ("v112_inc_footer_permissions_v3.pdf").name)
				new_size := source.byte_count
				print ("  New size: " + new_size.out + " bytes%N")

				delta := new_size - original_size
				print ("  Delta: " + delta.out + " bytes%N")

				if delta > 0 and delta < 15000 then
					print ("  ✓ Incremental update with footer & permissions successful%N")
				else
					print ("  ⚠ Delta unexpected: " + delta.out + " bytes%N")
				end

				-- Parse verification
				create doc.make_from_source (source)
				check incremental_footer_permissions_parsed: doc.is_loaded end
				print ("  ✓ Incremental footer & permissions PDF parsed and validated successfully%N")

				print ("%N========================================%N")
				print ("✓ INCREMENTAL FOOTER & PERMISSIONS TEST COMPLETE%N")
				print ("========================================%N")
			else
				print ("  ✗ FAILED: Could not load PDF%N")
			end
		end


end