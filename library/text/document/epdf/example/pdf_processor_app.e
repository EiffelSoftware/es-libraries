note
	description: "PDF Processor Application - Adds footer and encryption to PDFs based on config.ini"

class
	PDF_PROCESSOR_APP

create
	make

feature -- Initialization

	make
			-- Main entry point
		local
			config: PDF_CONFIG_READER
			config_file: STRING
		do
			io.put_string ("PDF Processor Application%N")
			io.put_string ("===========================%N%N")
			
			    -- Determine config file path
			config_file := "config.ini"
			
			    -- Check if config file exists
			if not file_exists (config_file) then
				io.put_string ("ERROR: Configuration file not found: " + config_file + "%N")
				io.put_string ("Please create a config.ini file in the current directory.%N")
			else
				    -- Load configuration
				create config.make_from_file (config_file)
				
				    -- Validate configuration
				if validate_config (config) then
					    -- Process the PDF
					process_pdf (config)
				end
			end
			
			io.put_string ("%NDone.%N")
		end

feature {NONE} -- Implementation

	process_pdf (config: PDF_CONFIG_READER)
			-- Process PDF according to configuration
		require
			config_valid: config /= Void
		local
			doc: PDF_DOCUMENT
			source: PDF_FILE_BYTE_SOURCE
			footer_service: PDF_FOOTER_SERVICE
			handler: PDF_STANDARD_SECURITY_HANDLER
			permissions: PDF_PERMISSIONS
			encrypt_dict: PDF_DICTIONARY
			file_id: PDF_ARRAY
			encrypt_ref: PDF_REFERENCE
			encrypt_id: PDF_OBJECT_ID
			output_file: STRING
			footer_text_with_date: STRING
		do
			if attached config.input_file as input_path then
				io.put_string ("Loading PDF: " + input_path + "%N")
				
				    -- Check if input file exists
				if not file_exists (input_path) then
					io.put_string ("ERROR: Input PDF file not found: " + input_path + "%N")
				else
					    -- Load PDF document
					create source.make_from_file (input_path)
					create doc.make_from_source (source)
					
					if not doc.is_loaded then
						io.put_string ("ERROR: Failed to load PDF document%N")
					else
						io.put_string ("Document loaded successfully (" + source.byte_count.out + " bytes)%N")
						
						    -- Insert personalized message page after the front page
						if attached config.personalized_message as l_message and then not l_message.is_empty then
							io.put_string ("Inserting message page...%N")
							insert_message_page (doc, l_message, config.signature_text)
						end

						    -- Add footer if configured
						if attached config.footer_text as footer_text then
							io.put_string ("Adding footer...%N")
							
							    -- Replace {date} placeholder with current date
							footer_text_with_date := footer_text.twin
							footer_text_with_date.replace_substring_all ("{date}", current_date)
							
							create footer_service.make
							footer_service.set_margin (config.footer_margin)
							footer_service.set_font_size (config.footer_size)
							
							    -- Set alignment based on config
							if config.footer_alignment.is_equal ("left") then
								footer_service.set_alignment (footer_service.Alignment_left)
							elseif config.footer_alignment.is_equal ("right") then
								footer_service.set_alignment (footer_service.Alignment_right)
							else
								footer_service.set_alignment (footer_service.Alignment_center)
							end
							
							footer_service.add_footer_to_document (doc, footer_text_with_date)
							
							io.put_string ("Footer added (size: " + config.footer_size.out + 
							               ", margin: " + config.footer_margin.out + 
							               ", alignment: " + config.footer_alignment + ")%N")
						end
						
						    -- Add encryption if configured
						if attached config.owner_password as owner_pwd then
							io.put_string ("Configuring encryption...%N")
							
							    -- Create permissions based on config
							create permissions.make_all_restricted
							
							if config.allow_print then
								permissions.enable_print
								permissions.enable_print_high_quality
							end
							
							if config.allow_modify then
								permissions.enable_modify
							end
							
							if config.allow_copy then
								permissions.enable_copy
							end
							
							if config.allow_annotate then
								permissions.enable_modify_annotations
							end
							
							    -- Create file ID
							create file_id.make_empty
							file_id.add (create {PDF_STRING}.make_literal ("PDFProcessor" + current_date))
							file_id.add (create {PDF_STRING}.make_literal ("PDFProcessor" + current_date))
							
							    -- Create encryption dictionary
							create encrypt_dict.make_empty
							encrypt_dict.put_name ("Standard", "Filter")
							encrypt_dict.put_number (1, "V")
							encrypt_dict.put_number (2, "R")
							encrypt_dict.put_number (40, "Length")
							encrypt_dict.put_number (permissions.flags, "P")
							
							    -- Create security handler
							create handler.make (encrypt_dict, file_id, "")
							handler.compute_password_entries ("", owner_pwd)
							
							encrypt_dict.put_hex_string (handler.u_entry, "U")
							encrypt_dict.put_hex_string (handler.o_entry, "O")
							
							    -- Add encryption to document
							encrypt_id := doc.add_object (encrypt_dict)
							create encrypt_ref.make (encrypt_id)
							
							if attached doc.trailer as t then
								t.dictionary.put (encrypt_ref, "Encrypt")
								t.dictionary.put (file_id, "ID")
							end
							
							doc.set_security_handler (handler)
							
							io.put_string ("Encryption configured (Print: " + config.allow_print.out + 
							               ", Modify: " + config.allow_modify.out + 
							               ", Copy: " + config.allow_copy.out + 
							               ", Annotate: " + config.allow_annotate.out + ")%N")
						end
						
						    -- Generate output filename
						output_file := generate_output_filename (input_path)
						
						    -- Write output
						io.put_string ("Writing output: " + output_file + "%N")
						doc.write_to_file (output_file)
						io.put_string ("PDF processed successfully!%N")
					end
				end
			end
		end

	validate_config (config: PDF_CONFIG_READER): BOOLEAN
			-- Validate configuration and report errors
		do
			Result := True
			
			if not attached config.input_file as l_input or else l_input.is_empty then
				io.put_string ("ERROR: No input file specified in [Input] section%N")
				Result := False
			end
			
			if config.footer_size <= 0 then
				io.put_string ("ERROR: Invalid footer size (must be > 0)%N")
				Result := False
			end
			
			if config.footer_margin < 0 then
				io.put_string ("ERROR: Invalid footer margin (must be >= 0)%N")
				Result := False
			end
		end

	generate_output_filename (input_path: STRING): STRING
			-- Generate output filename with date: <name>_<date>.pdf
		local
			base_name: STRING
			dot_pos: INTEGER
		do
			base_name := input_path.twin
			
			    -- Remove .pdf extension if present
			if base_name.ends_with (".pdf") or base_name.ends_with (".PDF") then
				dot_pos := base_name.last_index_of ('.', base_name.count)
				if dot_pos > 0 then
					base_name := base_name.substring (1, dot_pos - 1)
				end
			end
			
			    -- Add date and extension
			Result := base_name + "_" + current_date_compact + ".pdf"
		ensure
			result_not_empty: not Result.is_empty
			result_ends_with_pdf: Result.ends_with (".pdf")
		end

	file_exists (path: STRING): BOOLEAN
			-- Check if file exists
		local
			file: PLAIN_TEXT_FILE
		do
			create file.make_with_name (path)
			Result := file.exists
		end

	current_date: STRING
			-- Get current date as string (YYYY/MM/DD)
		local
			l_date: DATE
		do
			create l_date.make_now
			Result := l_date.year.out + "/" + 
			          zero_pad (l_date.month) + "/" + 
			          zero_pad (l_date.day)
		ensure
			result_not_empty: not Result.is_empty
		end

	current_date_compact: STRING
			-- Get current date as compact string (YYYY-MM-DD)
		local
			l_date: DATE
		do
			create l_date.make_now
			Result := l_date.year.out + "-" + 
			          zero_pad (l_date.month) + "-" + 
			          zero_pad (l_date.day)
		ensure
			result_not_empty: not Result.is_empty
		end

	zero_pad (n: INTEGER): STRING
			-- Return `n` as string, zero-padded to 2 digits
		do
			if n < 10 then
				Result := "0" + n.out
			else
				Result := n.out
			end
		ensure
			result_length: Result.count >= 2
		end

	insert_message_page (a_doc: PDF_DOCUMENT; a_message: detachable STRING; a_signature: detachable STRING)
			-- Insert a new page after the front page with `a_message` and `a_signature`.
		require
			doc_attached: a_doc /= Void
			doc_loaded: a_doc.is_loaded
		local
			catalog: detachable PDF_DICTIONARY
			first_page_info: detachable TUPLE [page: PDF_DICTIONARY; parent: PDF_DICTIONARY; parent_id: PDF_OBJECT_ID; page_id: PDF_OBJECT_ID]
			new_page: PDF_DICTIONARY
			parent_reference: PDF_REFERENCE
			default_media_box: PDF_ARRAY
			resource_manager: PDF_RESOURCE_MANAGER
			stream_creator: PDF_CONTENT_STREAM_CREATOR
			font_name: STRING_8
			message_text: STRING_8
			signature_text_value: STRING_8
			message_lines: ARRAYED_LIST [STRING_8]
			message_stream: PDF_STREAM
			signature_stream: PDF_STREAM
			message_stream_id: PDF_OBJECT_ID
			signature_stream_id: PDF_OBJECT_ID
			new_page_id: PDF_OBJECT_ID
			new_page_reference: PDF_REFERENCE
			contents_array: PDF_ARRAY
			kids_array: detachable PDF_ARRAY
			index: INTEGER
			found_index: INTEGER
			signature_y: REAL_64
		do
			catalog := a_doc.catalog
			if catalog /= Void then
				if attached {PDF_REFERENCE} catalog.item ("Pages") as pages_ref then
					first_page_info := find_first_page (a_doc, pages_ref.object_id)
				end
			end
			
			if attached first_page_info as page_info then
				-- 1. Create a new page dictionary
				create new_page.make_empty
				new_page.put_name ("Page", "Type")
				
				-- 2. Set the Parent reference
				create parent_reference.make (page_info.parent_id)
				new_page.put (parent_reference, "Parent")
				
				-- 3. Copy MediaBox from the first page
				if attached {PDF_ARRAY} page_info.page.item ("MediaBox") as mb then
					new_page.put (mb, "MediaBox")
				else
					create default_media_box.make (4)
					default_media_box.add_real (0.0)
					default_media_box.add_real (0.0)
					default_media_box.add_real (612.0)
					default_media_box.add_real (792.0)
					new_page.put (default_media_box, "MediaBox")
				end
				
				-- 4. Register Helvetica font in the new page's Resources
				create resource_manager.make
				font_name := resource_manager.find_or_add_helvetica (new_page, a_doc, "inserted_page")
				
				-- 5. Prepare message and signature text
				if a_message /= Void and then not a_message.is_empty then
					message_text := a_message.to_string_8
				else
					message_text := "Current Date: " + current_date.to_string_8
				end
				message_lines := split_lines (message_text)
				
				if a_signature /= Void and then not a_signature.is_empty then
					signature_text_value := a_signature.to_string_8
				else
					signature_text_value := "Signed by Javier"
				end
				
				-- 6. Create text streams
				create stream_creator.make
				-- We place the personalized message at X=100 Y=500 with font size 16, using dark blue color (RGB: 0.1, 0.2, 0.6)
				message_stream := stream_creator.create_multiline_text_stream (message_lines, font_name, 16.0, 100.0, 500.0, 20.0, 0.1, 0.2, 0.6)
				
				-- Place signature below the last line of the message (using 20pt line spacing for message)
				signature_y := 500.0 - (message_lines.count.to_double * 20.0) - 20.0
				
				-- We place the signature text at X=100 Y=signature_y with font size 12, using grey color (RGB: 0.4, 0.4, 0.4)
				signature_stream := stream_creator.create_text_stream (signature_text_value, font_name, 12.0, 100.0, signature_y, 0.4, 0.4, 0.4)
				
				-- 7. Add streams to document and references to page's Contents
				message_stream_id := a_doc.add_object (message_stream)
				signature_stream_id := a_doc.add_object (signature_stream)
				
				create contents_array.make (2)
				contents_array.add (create {PDF_REFERENCE}.make (message_stream_id))
				contents_array.add (create {PDF_REFERENCE}.make (signature_stream_id))
				new_page.put (contents_array, "Contents")
				
				-- 8. Add the new page object to the document
				new_page_id := a_doc.add_object (new_page)
				create new_page_reference.make (new_page_id)
				
				-- 9. Insert the new page reference in the parent Pages node's Kids array
				if attached {PDF_ARRAY} page_info.parent.item ("Kids") as arr then
					kids_array := arr
				elseif attached {PDF_REFERENCE} page_info.parent.item ("Kids") as ref then
					if attached {PDF_ARRAY} a_doc.get_object (ref.object_id) as arr then
						kids_array := arr
					end
				end
				
				if kids_array /= Void then
					from
						index := 1
						found_index := 0
					until
						index > kids_array.count or found_index > 0
					loop
						if attached {PDF_REFERENCE} kids_array.item (index) as ref then
							if ref.object_id.object_number = page_info.page_id.object_number then
								found_index := index
							end
						end
						index := index + 1
					end
					
					if found_index > 0 then
						kids_array.insert_after (new_page_reference, found_index)
						a_doc.mark_modified (page_info.parent_id)
						
						-- 10. Recursively update pages Count throughout the page tree
						increment_pages_count (a_doc, page_info.parent, page_info.parent_id)
						io.put_string ("Successfully inserted new page after the front page.%N")
					else
						io.put_string ("ERROR: Could not find front page reference in Kids array.%N")
					end
				else
					io.put_string ("ERROR: Kids array not found in parent Pages node.%N")
				end
			else
				io.put_string ("ERROR: Could not find the front page of the document.%N")
			end
		end

	find_first_page (a_doc: PDF_DOCUMENT; a_node_id: PDF_OBJECT_ID): detachable TUPLE [page: PDF_DICTIONARY; parent: PDF_DICTIONARY; parent_id: PDF_OBJECT_ID; page_id: PDF_OBJECT_ID]
			-- Find the first leaf Page in the subtree starting at `a_node_id`.
		require
			doc_attached: a_doc /= Void
			node_id_attached: a_node_id /= Void
		local
			node: detachable PDF_DICTIONARY
			kids: detachable PDF_OBJECT
			kids_array: detachable PDF_ARRAY
			page_type: detachable PDF_OBJECT
		do
			if attached {PDF_DICTIONARY} a_doc.get_object (a_node_id) as dict then
				node := dict
				page_type := node.item ("Type")
				if attached {PDF_NAME} page_type as type_name then
					if type_name.value.is_equal ("Pages") then
						kids := node.item ("Kids")
						if attached {PDF_ARRAY} kids as arr then
							kids_array := arr
						elseif attached {PDF_REFERENCE} kids as ref then
							if attached {PDF_ARRAY} a_doc.get_object (ref.object_id) as arr then
								kids_array := arr
							end
						end
						
						if kids_array /= Void and then kids_array.count > 0 then
							if attached {PDF_REFERENCE} kids_array.item (1) as first_kid_ref then
								if attached {PDF_DICTIONARY} a_doc.get_object (first_kid_ref.object_id) as first_child then
									if attached {PDF_NAME} first_child.item ("Type") as first_child_type then
										if first_child_type.value.is_equal ("Page") then
											create Result
											Result.page := first_child
											Result.parent := node
											Result.parent_id := a_node_id
											Result.page_id := first_kid_ref.object_id
										elseif first_child_type.value.is_equal ("Pages") then
											Result := find_first_page (a_doc, first_kid_ref.object_id)
										end
									end
								end
							end
						end
					end
				end
			end
		end

	increment_pages_count (a_doc: PDF_DOCUMENT; a_pages_node: PDF_DICTIONARY; a_pages_node_id: PDF_OBJECT_ID)
			-- Recursively increment Count in `a_pages_node` and its parents.
		require
			doc_attached: a_doc /= Void
			pages_node_attached: a_pages_node /= Void
			pages_node_id_attached: a_pages_node_id /= Void
		local
			count_value: INTEGER
		do
			if attached {PDF_NUMBER} a_pages_node.item ("Count") as count_number then
				count_value := count_number.int_value
				a_pages_node.put_number (count_value + 1, "Count")
				a_doc.mark_modified (a_pages_node_id)
			end
			
			if attached {PDF_REFERENCE} a_pages_node.item ("Parent") as parent_reference then
				if attached {PDF_DICTIONARY} a_doc.get_object (parent_reference.object_id) as parent_dictionary then
					increment_pages_count (a_doc, parent_dictionary, parent_reference.object_id)
				end
			end
		end

	split_lines (a_text: STRING_8): ARRAYED_LIST [STRING_8]
			-- Split `a_text` by newlines.
		require
			text_attached: a_text /= Void
		local
			start_pos, end_pos: INTEGER
			line: STRING_8
		do
			create Result.make (5)
			from
				start_pos := 1
			until
				start_pos > a_text.count
			loop
				end_pos := a_text.index_of ('%N', start_pos)
				if end_pos > 0 then
					line := a_text.substring (start_pos, end_pos - 1)
					-- Remove carriage return if present
					if not line.is_empty and then line [line.count] = '%R' then
						line.remove_tail (1)
					end
					Result.extend (line)
					start_pos := end_pos + 1
				else
					line := a_text.substring (start_pos, a_text.count)
					if not line.is_empty and then line [line.count] = '%R' then
						line.remove_tail (1)
					end
					Result.extend (line)
					start_pos := a_text.count + 1
				end
			end
		ensure
			result_attached: Result /= Void
		end

end
