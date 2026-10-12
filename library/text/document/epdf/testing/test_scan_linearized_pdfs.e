note
	description: "[
		Scans veraPDF corpus to find linearized PDFs.
		Checks each PDF for the /Linearized key in object dictionaries.
	]"

class
	TEST_SCAN_LINEARIZED_PDFS

inherit
	EQA_TEST_SET

feature -- Test routines

	test_scan_veraPDF_corpus
		do
			
		end
--			-- Scan all PDFs in veraPDF_corpus and report which are linearized.
--		local
--			linearized_files: ARRAYED_LIST [STRING]
--		do
--			create linearized_files.make (100)
--			linearized_count := 0
--			total_count := 0
--			error_count := 0
--			
--			print ("%N=== Scanning veraPDF Corpus for Linearized PDFs ===%N%N")
--			scan_directory ("veraPDF_corpus", linearized_files)
--			
--			print ("%N=== Summary ===%N")
--			print ("Total PDFs scanned: " + total_count.out + "%N")
--			print ("Linearized PDFs found: " + linearized_count.out + "%N")
--			print ("Errors: " + error_count.out + "%N")
--			
--			if linearized_count > 0 then
--				print ("%N=== Linearized PDFs ===%N")
--				across linearized_files as f loop
--					print (@ f.item + "%N")
--				end
--			else
--				print ("%NNo linearized PDFs found.%N")
--			end
--			
--			assert ("Scan complete", True)
--		end

--feature {NONE} -- Implementation

--	linearized_count: INTEGER
--			-- Count of linearized PDFs found.

--	total_count: INTEGER
--			-- Total count of PDFs scanned.

--	error_count: INTEGER
--			-- Count of errors encountered.

--	scan_directory (dir_path: STRING; linearized_files: ARRAYED_LIST [STRING])
--			-- Recursively scan directory for PDF files and check if they're linearized.
--		local
--			dir: DIRECTORY
--			entry_name: STRING
--			subdir_path: STRING
--			file_path: STRING
--			file: RAW_FILE
--		do
--			create dir.make (dir_path)
--			if dir.exists then
--				dir.open_read
--				
--				from
--					dir.readentry
--				until
--					not attached dir.last_entry_8 as last_entry or else last_entry.is_empty
--				loop
--					if attached dir.last_entry_8 as current_entry then
--						create entry_name.make_from_string (current_entry)
--						if not entry_name.is_equal (".") and then not entry_name.is_equal ("..") then
--								-- Check if it's a directory
--							create subdir_path.make_from_string (dir_path)
--							subdir_path.append_character (operating_environment.directory_separator)
--							subdir_path.append (entry_name)
--							create file.make_with_name (subdir_path)
--							if file.exists and then file.is_directory then
--									-- Recursively scan subdirectory
--								scan_directory (subdir_path, linearized_files)
--							elseif entry_name.ends_with (".pdf") or else entry_name.ends_with (".PDF") then
--									-- It's a PDF file
--								total_count := total_count + 1
--								if total_count \\ 100 = 0 then
--									print ("Scanned " + total_count.out + " PDFs...%N")
--								end
--								
--								create file_path.make_from_string (dir_path)
--								file_path.append_character (operating_environment.directory_separator)
--								file_path.append (entry_name)
--								if is_linearized_pdf (file_path) then
--									linearized_count := linearized_count + 1
--									linearized_files.extend (file_path)
--									print ("Found linearized PDF: " + file_path + "%N")
--								end
--							end
--						end
--					end
--					dir.readentry
--				end
--				
--				dir.close
--			end
--		rescue
--			error_count := error_count + 1
--			if attached dir as d and then d.exists and then d.is_open then
--				d.close
--			end
--		end

--	is_linearized_pdf (file_path: STRING): BOOLEAN
--			-- Check if PDF file is linearized by looking for /Linearized key.
--		local
--			doc: PDF_DOCUMENT
--			source: PDF_FILE_BYTE_SOURCE
--			obj_id: PDF_OBJECT_ID
--			obj: detachable PDF_OBJECT
--		do
--			create source.make_from_file (file_path)
--			if source.is_valid then
--				create doc.make_from_source (source)
--				if doc.is_loaded then
--						-- Check all objects for /Linearized key
--					if attached doc.xref_table.entries as entries then
--						across entries as c until Result loop
--							if (@ c.item).is_in_use then
--								create obj_id.make (@ c.key, (@ c.item).generation)
--								obj := doc.get_object (obj_id)
--								
--								if attached {PDF_DICTIONARY} obj as dict then
--									if dict.has_key ("Linearized") then
--										Result := True
--									end
--								elseif attached {PDF_STREAM} obj as stream then
--										-- Check stream dictionary
--									if stream.stream_dictionary.has_key ("Linearized") then
--										Result := True
--									end
--								end
--							end
--						end
--					end
--				end
--			end
--		rescue
--				-- If parsing fails, assume not linearized
--			Result := False
--		end

end

