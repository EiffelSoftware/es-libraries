note
	description: "[
		Represents a complete PDF document.
		Provides high-level interface for reading, modifying, and writing PDFs.
		Implements lazy loading strategy per ISO 32000-1:2008.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_DOCUMENT

inherit
	PDF_WITH_LOGGING

create
	make,
	make_from_source

feature -- Initialization

	make
			-- Create empty PDF document.
		do
			create xref_table.make
			create object_cache.make
			create object_stream_cache.make (10)
			create new_objects.make (10)
			create modified_objects.make (10)
			strict_mode := False
		ensure
			xref_created: xref_table /= Void
			cache_created: object_cache /= Void
			stm_cache_created: object_stream_cache /= Void
			stm_cache_created: object_stream_cache /= Void
			new_objects_created: new_objects /= Void
			modified_objects_created: modified_objects /= Void
			permissive_mode: not strict_mode
		end

	make_from_source (a_source: PDF_BYTE_SOURCE)
			-- Create document by parsing from byte source.
		require
			source_valid: a_source.is_valid
		do
			make
			source := a_source
			parse_document
		ensure
			source_set: source = a_source
		end

feature -- Access

	source: detachable PDF_BYTE_SOURCE
			-- Byte source for this document.

	xref_table: PDF_XREF_TABLE
			-- Cross-reference table.

	trailer: detachable PDF_TRAILER
			-- Document trailer.

	object_cache: PDF_OBJECT_CACHE
			-- Cache ensuring object identity.

	last_startxref: INTEGER
			-- Byte offset of the last cross-reference section read.
			-- Used for incremental updates to link back via /Prev.

	security_handler: detachable PDF_SECURITY_HANDLER
			-- Security handler for this document.

	original_security_handler: detachable PDF_SECURITY_HANDLER
			-- Original security handler used to decrypt objects from the loaded source.

	is_originally_encrypted: BOOLEAN
			-- Was this document encrypted when loaded from source?

	object_stream_cache: HASH_TABLE [PDF_OBJECT_STREAM, INTEGER]
			-- Cache for parsed object streams (prevent re-parsing/re-decoding).

	new_objects: ARRAYED_LIST [PDF_INDIRECT_OBJECT]
			-- List of new objects created during modification.

	modified_objects: HASH_TABLE [PDF_OBJECT, INTEGER]
			-- Objects from the original file that have been modified.
			-- Table maps Object Number -> PDF_OBJECT.

	next_object_number: INTEGER
			-- Next available object number.

	strict_mode: BOOLEAN
			-- Is strict ISO compliance mode enabled?

	version: STRING_8
			-- PDF version string (e.g., "1.7").
		do
			if attached internal_version as v then
				Result := v
			else
				Result := "1.7"
			end
		end

feature -- Status Report

	is_loaded: BOOLEAN
			-- Has document been successfully loaded?
		do
			Result := attached trailer as t and then t.is_valid
		ensure
			definition: Result = (attached trailer as t and then t.is_valid)
		end

	is_encrypted: BOOLEAN
			-- Is this document encrypted?
		do
			Result := security_handler /= Void
		end

feature -- Modification

	mark_modified (a_object_id: PDF_OBJECT_ID)
			-- Mark an existing object as modified so it's included in incremental updates.
		require
			valid_id: a_object_id /= Void
		do
			if attached object_cache.object (a_object_id) as obj then
				modified_objects.force (obj, a_object_id.object_number)
			end
		ensure
			marked: modified_objects.has (a_object_id.object_number)
		end

feature -- Element Change

	set_strict_mode (a_strict: BOOLEAN)
			-- Set strict ISO compliance mode.
		do
			strict_mode := a_strict
		ensure
			strict_mode_set: strict_mode = a_strict
		end

	set_security_handler (a_handler: detachable PDF_SECURITY_HANDLER)
			-- Set security handler manually (e.g. for testing or creation).
		do
			security_handler := a_handler
		ensure
			handler_set: security_handler = a_handler
		end

	set_trailer (a_trailer: PDF_TRAILER)
			-- Set trailer manually (e.g. for testing or document creation).
		require
			trailer_valid: a_trailer /= Void
		do
			trailer := a_trailer
		ensure
			trailer_set: trailer = a_trailer
		end

	add_object (a_object: PDF_OBJECT): PDF_OBJECT_ID
			-- Add a new object to the document.
		require
			object_valid: a_object /= Void
		local
			id: PDF_OBJECT_ID
			indirect: PDF_INDIRECT_OBJECT
		do
			if next_object_number = 0 then
				update_next_object_number
			end

			create id.make (next_object_number, 0)
			create indirect.make (id, a_object)
			new_objects.extend (indirect)

				-- Also cache it so get_object finds it
			object_cache.put (id, a_object)

			next_object_number := next_object_number + 1
			Result := id
		ensure
			object_added: new_objects.count = old new_objects.count + 1
			result_valid: Result.object_number = next_object_number - 1
		end

feature -- Basic Operations

	get_object (obj_id: PDF_OBJECT_ID): PDF_OBJECT
			-- Get object with given ID, loading lazily if needed.
			-- Returns PDF_NULL for undefined references per ISO 32000-1:2008 §7.3.9.
		require
			loaded: is_loaded
		local
			entry: detachable PDF_XREF_ENTRY
			loaded_obj: detachable PDF_OBJECT
		do
			loaded_obj := object_cache.object (obj_id)

			if loaded_obj = Void then
				entry := xref_table.entry (obj_id.object_number)
				if entry /= Void and then entry.is_in_use then
					if entry.is_compressed then
						loaded_obj := load_compressed_object (obj_id, entry.object_stream_number, entry.index_in_stream)
					else
						loaded_obj := load_object (obj_id, entry.offset)
					end

					if loaded_obj /= Void then
						decrypt_object (loaded_obj, obj_id)
						object_cache.put (obj_id, loaded_obj)
					end
				end
			end

			if loaded_obj /= Void then
				Result := loaded_obj
			else
					-- Per ISO 32000-1:2008 §7.3.9:
					-- "An indirect reference to an undefined object shall not be considered
					-- an error; it shall be treated as a reference to the null object."
				create {PDF_NULL} Result
			end
		ensure
			result_attached: Result /= Void
		end

feature -- Output

	write_to_file (file_path: READABLE_STRING_GENERAL)
			-- Write document to file.
			-- Uses READABLE_STRING_GENERAL to support Unicode file paths.
		require
			loaded: is_loaded
			path_valid: file_path /= Void and then not file_path.is_empty
		local
			file: RAW_FILE
		do
			create file.make_open_write (file_path)
			file.put_string (to_bytes)
			file.close
		end

	to_bytes: STRING_8
			-- Serialize document to bytes.
		require
			loaded: is_loaded
		local
			writer: PDF_DOCUMENT_WRITER
		do
			create writer.make
			writer.logger := logger
			writer.write_document (Current)
			Result := writer.last_output
		ensure
			result_not_empty: Result /= Void and then not Result.is_empty
		end

	catalog: detachable PDF_DICTIONARY
			-- Document catalog (root object).
		require
			loaded: is_loaded
		do
			if attached trailer as t then
				if attached t.root as root_ref then
					if attached {PDF_DICTIONARY} get_object (root_ref.object_id) as dict then
						Result := dict
					end
				end
			end
		end

feature {NONE} -- Implementation: Parsing

	internal_version: detachable STRING_8
			-- Internal storage for PDF version.

	parse_document
			-- Parse document structure from source.
		require
			source_attached: source /= Void
		local
			startxref_pos: INTEGER
		do
			if attached source as src then
				parse_version (src)
				startxref_pos := find_startxref (src)
				if startxref_pos > 0 then
					last_startxref := startxref_pos
					parse_xref_and_trailer (src, startxref_pos)
					update_next_object_number
					initialize_security
				end
			end
		end

	initialize_security
			-- Initialize security handler if document is encrypted.
		local
			file_id: detachable PDF_ARRAY
			handler: PDF_STANDARD_SECURITY_HANDLER
			encrypt_dict: detachable PDF_DICTIONARY
			ref: detachable PDF_REFERENCE
			trail: detachable PDF_TRAILER

		do
			trail := trailer
			if trail /= Void then
					-- Check for /Encrypt
				if attached trail.dictionary.item ("Encrypt") as enc then
					if attached {PDF_REFERENCE} enc as r then
						ref := r
						if attached {PDF_DICTIONARY} get_object (r.object_id) as d then
							encrypt_dict := d
						end
					elseif attached {PDF_DICTIONARY} enc as d then
						encrypt_dict := d
					end
				end

					-- Check for /ID
				if attached {PDF_ARRAY} trail.dictionary.item ("ID") as arr then
					file_id := arr
				end

				if encrypt_dict /= Void then
					-- Create standard security handler (default password empty)
					create handler.make (encrypt_dict, file_id, "")
					security_handler := handler
					original_security_handler := handler
					is_originally_encrypted := True
				end
			end
		end

	update_next_object_number
			-- Update next_object_number based on xref table.
		local
			max: INTEGER
		do
			if xref_table /= Void and then xref_table.entries /= Void then
				across xref_table.entries as cursor loop
					if @ cursor.key > max then
						max := @ cursor.key
					end
				end
			end
			next_object_number := max + 1
		end

	parse_version (src: PDF_BYTE_SOURCE)
			-- Parse PDF version from header.
		local
			header: STRING_8
			i: INTEGER
		do
			src.set_position (0)
			create header.make (20)

			from
				i := 1
			until
				i > 20 or src.end_of_source or src.peek_byte = 0x0A or src.peek_byte = 0x0D
			loop
				header.append_character (src.read_byte.to_character_8)
				i := i + 1
			end

			if header.starts_with ("%%PDF-") then
				internal_version := header.substring (6, header.count)
			else
				internal_version := "1.7"
			end
		end

	find_startxref (src: PDF_BYTE_SOURCE): INTEGER
			-- Find byte offset of xref table by reading startxref from end of file.
		local
			tail: STRING_8
			startxref_idx: INTEGER
			num_str: STRING_8
			i: INTEGER
		do
			if src.byte_count > 1024 then
				src.set_position (src.byte_count - 1024)
			else
				src.set_position (0)
			end

			create tail.make (1024)
			from
			until
				src.end_of_source
			loop
				tail.append_character (src.read_byte.to_character_8)
			end

			startxref_idx := tail.substring_index ("startxref", 1)
			if startxref_idx > 0 then
				from
					i := startxref_idx + 9
					create num_str.make (10)
				until
					i > tail.count or else (tail [i].is_digit)
				loop
					i := i + 1
				end

				from
				until
					i > tail.count or else not tail [i].is_digit
				loop
					num_str.append_character (tail [i])
					i := i + 1
				end

				if not num_str.is_empty then
					Result := num_str.to_integer
				end
			end
		end

	parse_xref_and_trailer (src: PDF_BYTE_SOURCE; xref_offset: INTEGER)
			-- Parse xref table and trailer starting at given offset.
			-- Supports both traditional xref tables and xref streams (PDF 1.5+).
			-- Follows /Prev chain recursively to load all xref entries.
		require
			valid_offset: xref_offset >= 0 and xref_offset < src.byte_count
		local
			lexer: PDF_LEXER
			parser: PDF_PARSER
			token: PDF_TOKEN
			obj_num, count: INTEGER
			i: INTEGER
			offset, generation: INTEGER
			flag: STRING_8
			trailer_dict: detachable PDF_DICTIONARY
			prev_offset: INTEGER
		do
			log_info ("[parse_xref_and_trailer] Parsing at offset " + xref_offset.out + "%N")
			create lexer.make (src)
			src.set_position (xref_offset)

			token := lexer.next_token
			log_info ("[parse_xref_and_trailer] First token: type=" + token.token_type.out + " value=" + token.value + "%N")

			if token.token_type = {PDF_TOKEN}.type_xref then
					-- Traditional xref table
				from
					token := lexer.next_token
				until
					token.token_type = {PDF_TOKEN}.type_trailer or token.is_eof
				loop
					if token.token_type = {PDF_TOKEN}.type_number then
						obj_num := token.value.to_integer
						token := lexer.next_token

						if token.token_type = {PDF_TOKEN}.type_number then
							count := token.value.to_integer
							token := lexer.next_token

							from
								i := 0
							until
								i >= count or token.is_eof
							loop
								if token.token_type = {PDF_TOKEN}.type_number then
									offset := token.value.to_integer
									token := lexer.next_token

									if token.token_type = {PDF_TOKEN}.type_number then
										generation := token.value.to_integer
										token := lexer.next_token

										flag := token.value

										if flag.is_equal ("n") then
											xref_table.add_in_use (obj_num + i, offset, generation)
										elseif flag.is_equal ("f") then
											xref_table.add_free (obj_num + i, offset, generation)
										end

										token := lexer.next_token
									end
								end

								i := i + 1
							end
						end
					else
						token := lexer.next_token
					end
				end

				if token.token_type = {PDF_TOKEN}.type_trailer then
						-- Re-synchronize parser after manual lexer traversal.
					create parser.make (lexer)
					parser.logger := logger
					if attached {PDF_DICTIONARY} parser.parse_object as dict then
						trailer_dict := dict

							-- Set main trailer only if not yet set (latest takes precedence)
						if trailer = Void then
							create trailer.make (trailer_dict)
						end

							-- Check for /Prev
						if attached {PDF_NUMBER} trailer_dict.item ("Prev") as p then
							prev_offset := p.int_value
							log_info ("%NTraditional xref /Prev: " + prev_offset.out + "%N")
							if prev_offset > 0 then
								log_info ("Following /Prev to offset " + prev_offset.out + "%N")
								parse_xref_and_trailer (src, prev_offset)
							end
						else
							log_info ("No /Prev in traditional xref trailer%N")
						end

							-- Check for hybrid PDF (xref table + xref stream)
							-- Per ISO 32000-1:2008 §7.5.8.4: XRef stream entries override table entries
						if attached {PDF_NUMBER} trailer_dict.item ("XRefStm") as xref_stm then
							log_info ("[parse_xref_and_trailer] Hybrid PDF detected, XRefStm at " + xref_stm.int_value.out + "%N")
							parse_xref_stream (src, xref_stm.int_value)
						end
					end
				end
			elseif token.token_type = {PDF_TOKEN}.type_number then
					-- XRef stream (PDF 1.5+) - startxref points to an indirect object
				parse_xref_stream (src, xref_offset)
			end
		end

	parse_xref_stream (src: PDF_BYTE_SOURCE; xref_offset: INTEGER)
			-- Parse cross-reference stream at given offset.
			-- Per ISO 32000-1:2008 §7.5.8.
		require
			valid_offset: xref_offset >= 0 and xref_offset < src.byte_count
		local
			lexer: PDF_LEXER
			parser: PDF_PARSER
			indirect: detachable PDF_INDIRECT_OBJECT
			xref_stream: detachable PDF_XREF_STREAM
			decoder: PDF_FLATE_DECODER
			entries: detachable ARRAY [TUPLE [type: INTEGER; field2: INTEGER; field3: INTEGER]]
			i: INTEGER
			obj_num: INTEGER
			idx: detachable ARRAY [INTEGER]
			subsection_start, subsection_count: INTEGER
			subsection_idx: INTEGER
			trailer_dict: PDF_DICTIONARY
			prev_offset: INTEGER
		do
			log_info ("[parse_xref_stream] Parsing XRef at offset " + xref_offset.out + "%N")
			create lexer.make (src)
			src.set_position (xref_offset)
			create parser.make (lexer)
			parser.logger := logger

				-- Parse the indirect object at this position
			indirect := parser.parse_indirect_object

			if indirect /= Void then
				if attached {PDF_STREAM} indirect.value as stream then
						-- This is an XRef stream
					create xref_stream.make (stream)
					xref_stream.logger := logger

					if xref_stream.is_xref_stream then
							-- Parse xref data from stream
						create decoder.make
						entries := xref_stream.parse_xref_data (decoder)
						log_info ("[parse_xref_stream] Parsed " + (if entries /= Void then entries.count.out + " entries from obj " + indirect.object_id.object_number.out else "Void" end) + "%N")

						if entries /= Void then
								-- Determine object numbering from /Index or default [0, Size]
							idx := xref_stream.index
							if idx = Void then
									-- Default: [0, Size]
								create idx.make_filled (0, 1, 2)
								idx [1] := 0
								idx [2] := xref_stream.size
							end

								-- Process each subsection
							from
								subsection_idx := idx.lower
								i := entries.lower
							until
								subsection_idx > idx.upper - 1 or i > entries.upper
							loop
								subsection_start := idx [subsection_idx]
								subsection_count := idx [subsection_idx + 1]

									-- Add entries for this subsection
								from
									obj_num := subsection_start
								until
									obj_num >= (subsection_start + subsection_count) or i > entries.upper
								loop
									if entries [i].type = 0 then
											-- Free entry
										xref_table.add_free (obj_num, entries [i].field2, entries [i].field3)
									elseif entries [i].type = 1 then
											-- In-use entry
										xref_table.add_in_use (obj_num, entries [i].field2, entries [i].field3)
									elseif entries [i].type = 2 then
											-- Compressed object (Type 2)
											-- field2 = object stream number
											-- field3 = index in stream
										xref_table.add_compressed (obj_num, entries [i].field2, entries [i].field3)
									end

									obj_num := obj_num + 1
									i := i + 1
								end

								subsection_idx := subsection_idx + 2
							end
						end

							-- Extract trailer from stream dictionary
						trailer_dict := xref_stream.dictionary

							-- Set main trailer only if not yet set (latest takes precedence)
						if trailer = Void then
							create trailer.make (trailer_dict)
						end

							-- Check for /Prev
						prev_offset := xref_stream.prev
						log_info ("%NXRef stream /Prev: " + prev_offset.out + "%N")
						if prev_offset > 0 then
							log_info ("Following /Prev to offset " + prev_offset.out + "%N")
							parse_xref_and_trailer (src, prev_offset)
						else
							log_info ("No /Prev chain%N")
						end
					end
				end
			end
		end

	load_compressed_object (obj_id: PDF_OBJECT_ID; stm_num: INTEGER; index: INTEGER): detachable PDF_OBJECT
			-- Load object from object stream.
		require
			stm_num_valid: stm_num >= 0
			index_valid: index >= 0
		local
			stm_id: PDF_OBJECT_ID
			stm_obj: detachable PDF_OBJECT
			obj_stm: detachable PDF_OBJECT_STREAM
			decoder: PDF_FLATE_DECODER
		do
			if object_stream_cache.has (stm_num) then
				obj_stm := object_stream_cache.item (stm_num)
			else
				create stm_id.make (stm_num, 0)
				stm_obj := get_object (stm_id)

				if attached {PDF_STREAM} stm_obj as stream then
					create decoder.make
					create obj_stm.make (stream, decoder)
					obj_stm.logger := logger
					object_stream_cache.force (obj_stm, stm_num)
				end
			end

			if attached obj_stm as s then
				if index < s.count then
					Result := s.object_at (index)
				end
			end
		end

	load_object (obj_id: PDF_OBJECT_ID; offset: INTEGER): detachable PDF_OBJECT
			-- Load object from given byte offset.
		require
			source_attached: source /= Void
			valid_offset: offset >= 0
		local
			lexer: PDF_LEXER
			parser: PDF_PARSER
			indirect: detachable PDF_INDIRECT_OBJECT
		do
			if attached source as src then
				log_info ("[load_object] Loading obj " + obj_id.object_number.out + " at offset " + offset.out + "%N")
				create lexer.make (src)
				src.set_position (offset)
				create parser.make (lexer)
				parser.logger := logger

				indirect := parser.parse_indirect_object
				if indirect /= Void then
					Result := indirect.value
					log_info ("[load_object] ✓ Loaded obj " + obj_id.object_number.out + " type: " + Result.generator + "%N")
				else
					log_info ("[load_object] ✗ FAILED to load obj " + obj_id.object_number.out + " at offset " + offset.out + "%N")
				end
			else
				log_info ("[load_object] ✗ No source attached%N")
			end
		end

feature {NONE} -- Implementation: Decryption

	is_encrypt_dict (obj_id: PDF_OBJECT_ID): BOOLEAN
			-- Is `obj_id` the /Encrypt dictionary?
		do
			if attached trailer as t and then attached t.dictionary.item ("Encrypt") as enc then
				if attached {PDF_REFERENCE} enc as ref then
					Result := (ref.object_id.object_number = obj_id.object_number)
				end
			end
		end

	decrypt_object (a_object: PDF_OBJECT; obj_id: PDF_OBJECT_ID)
			-- Decrypt strings/streams in `a_object` recursively.
		require
			object_attached: a_object /= Void
			id_attached: obj_id /= Void
		do
			if is_originally_encrypted and then attached original_security_handler as handler and then not is_encrypt_dict (obj_id) then
				decrypt_object_recursive (a_object, handler, obj_id)
			end
		end

	decrypt_object_recursive (a_object: PDF_OBJECT; handler: PDF_SECURITY_HANDLER; obj_id: PDF_OBJECT_ID)
			-- Recursively traverse and decrypt `a_object`.
		do
			if attached {PDF_STRING} a_object as str then
				str.set_value (handler.decrypt_string (str.value, obj_id.object_number, obj_id.generation))
			elseif attached {PDF_STREAM} a_object as stm then
				stm.set_content (handler.decrypt_stream (stm.content, obj_id.object_number, obj_id.generation))
			elseif attached {PDF_ARRAY} a_object as arr then
				across arr.items as item loop
					decrypt_object_recursive (item, handler, obj_id)
				end
			elseif attached {PDF_DICTIONARY} a_object as dict then
				across dict.entries as entry loop
					decrypt_object_recursive (entry, handler, obj_id)
				end
			elseif attached {PDF_INDIRECT_OBJECT} a_object as ind then
				decrypt_object_recursive (ind.value, handler, obj_id)
			end
		end

end
