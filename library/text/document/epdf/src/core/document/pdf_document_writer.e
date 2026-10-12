note
	description: "Writer for PDF_DOCUMENT, implementing full serialization per ISO 32000-1:2008."
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_DOCUMENT_WRITER

inherit
	PDF_WITH_LOGGING

create
	make

feature -- Initialization

	make
			-- Initialize writer.
		do
			create serializer.make
			serializer.logger := logger
			create newline.make_from_string ("%R%N")
			create last_output.make_empty
		ensure
			serializer_created: serializer /= Void
			last_output_initialized: last_output /= Void
		end

feature -- Access

	serializer: PDF_SERIALIZER
			-- Object serializer.

	last_output: STRING_8
			-- Last generated PDF output.

	use_object_streams: BOOLEAN
			-- Should compatible objects be grouped into Object Streams?
			-- When True, produces smaller output files per §7.5.7.

	use_xref_stream: BOOLEAN
			-- Should XRef stream be used instead of traditional xref table?
			-- When True, produces compressed cross-reference data per §7.5.8.

feature -- Element Change

	set_use_object_streams (a_value: BOOLEAN)
			-- Enable or disable Object Stream grouping.
		do
			use_object_streams := a_value
		ensure
			value_set: use_object_streams = a_value
		end

	set_use_xref_stream (a_value: BOOLEAN)
			-- Enable or disable XRef stream writing.
		do
			use_xref_stream := a_value
		ensure
			value_set: use_xref_stream = a_value
		end

feature -- Operations

	write_document (a_doc: PDF_DOCUMENT)
			-- Serialize document to string.
		require
			doc_loaded: a_doc.is_loaded
		local
			offsets: HASH_TABLE [INTEGER, INTEGER]
			max_id: INTEGER
			start_xref: INTEGER

			obj: detachable PDF_OBJECT
			id: PDF_OBJECT_ID

			buffer: STRING_8
			keys: ARRAYED_LIST [INTEGER]
			skip_object: BOOLEAN
			written_count: INTEGER
		do
			document := a_doc
			create buffer.make (10000)
			create offsets.make (100)
			written_count := 0

				-- Set security handler for encryption
			serializer.set_security_handler (a_doc.security_handler)

				-- Header
			buffer.append ("%%PDF-1.7")
			buffer.append (newline)
			buffer.append ("%%%/228/%/240/%/211/%/250/")
			buffer.append (newline)

				--  Serialize existing objects
			if attached a_doc.xref_table.entries as entries then
				across entries as cursor loop
						-- Skip object 0 (free list head, ISO 32000-1:2008 §7.5.4)
					if @ cursor.key > 0 then
						create id.make (@ cursor.key, (@ cursor.item).generation)
						obj := a_doc.get_object (id)
						if attached obj then
								-- Check if we should skip this object
							skip_object := should_skip_object (obj)

							if not skip_object then
								offsets.put (buffer.count, @ cursor.key)
								write_object (obj, id, buffer)
								written_count := written_count + 1
							else
								log_info ("%NSkipping object " + @ cursor.key.out + " (type: " + obj.generator + ")%N")
							end
						else
							log_info ("%NWarning: Failed to load object " + @ cursor.key.out + "%N")
						end
					end
				end
			end

				-- Serialize new objects
			across a_doc.new_objects as cursor loop
				id := (@ cursor.item).object_id
				offsets.put (buffer.count, id.object_number)
				write_object ((@ cursor.item).value, id, buffer)
				written_count := written_count + 1
			end

			log_info ("%NWriter: Wrote " + written_count.out + " objects total%N")
			log_info ("Trailer Size should be: " + (max_id + 1).out + "%N")

				-- Compute max ID for trailer Size
			max_id := 0
			create keys.make (offsets.count)
			across offsets as cursor loop
				if @ cursor.key > max_id then
					max_id := @ cursor.key
				end
				keys.extend (@ cursor.key)
			end

				-- Write Xref Table or XRef Stream
			start_xref := buffer.count
			if use_xref_stream then
				write_xref_stream_standalone (a_doc, offsets, buffer, max_id + 1)
				-- startxref and %%EOF already written by write_xref_stream_standalone
			else
				write_xref_table (offsets, keys, buffer)
				-- Write Trailer
				write_trailer (a_doc, max_id + 1, start_xref, buffer)
			end

			last_output := buffer
		ensure
			output_generated: last_output /= Void and then not last_output.is_empty
		end

	write_document_with_objstm (a_doc: PDF_DOCUMENT)
			-- Serialize document using Object Streams for compatible objects.
			-- Per ISO 32000-1:2008 §7.5.7, reduces file size by 20-50%.
		require
			doc_loaded: a_doc.is_loaded
		local
			offsets: HASH_TABLE [INTEGER, INTEGER]
			max_id: INTEGER
			start_xref: INTEGER
			obj: detachable PDF_OBJECT
			id: PDF_OBJECT_ID
			buffer: STRING_8
			keys: ARRAYED_LIST [INTEGER]
			written_count: INTEGER
			objstm_writer: PDF_OBJECT_STREAM_WRITER
			objstm: PDF_STREAM
			objstm_id: PDF_OBJECT_ID
			compressed_entries: ARRAYED_LIST [TUPLE [obj_id: PDF_OBJECT_ID; stream_num: INTEGER; index: INTEGER]]
			type2_entries: HASH_TABLE [TUPLE [stream_num: INTEGER; idx: INTEGER], INTEGER]
			next_objstm_num: INTEGER
		do
			document := a_doc
			create buffer.make (10000)
			create offsets.make (100)
			create type2_entries.make (100)
			written_count := 0

				-- Set security handler for encryption
			serializer.set_security_handler (a_doc.security_handler)

				-- Header
			buffer.append ("%%PDF-1.5")  -- Object Streams require 1.5+
			buffer.append (newline)
			buffer.append ("%%%/228/%/240/%/211/%/250/")
			buffer.append (newline)

				-- Find max object number to allocate new Object Stream IDs
			max_id := 0
			if attached a_doc.xref_table.entries as entries then
				across entries as cursor loop
					if @ cursor.key > max_id then
						max_id := @ cursor.key
					end
				end
			end
			across a_doc.new_objects as cursor loop
				if (@ cursor.item).object_id.object_number > max_id then
					max_id := (@ cursor.item).object_id.object_number
				end
			end
			next_objstm_num := max_id + 1

				-- Create Object Stream writer with max 200 objects per stream
			create objstm_writer.make (200)
			objstm_writer.logger := logger

				-- First pass: add compatible objects to Object Stream, write others directly
			if attached a_doc.xref_table.entries as entries then
				across entries as cursor loop
					if @ cursor.key > 0 then
						create id.make (@ cursor.key, (@ cursor.item).generation)
						obj := a_doc.get_object (id)

						if attached obj then
							if should_skip_object (obj) then
								-- Skip (linearization dict, XRef stream, etc.)
							elseif objstm_writer.can_add (obj) and id.generation = 0 then
								-- Add to Object Stream
								objstm_writer.add_object (obj, id)

									-- If stream is full, finalize it
								if objstm_writer.is_full then
										-- Record Type 2 entries before finalizing
									compressed_entries := objstm_writer.get_compressed_entries
									across compressed_entries as ce loop
										type2_entries.put ([next_objstm_num, ce.index], ce.obj_id.object_number)
									end

										-- Create Object Stream object
									create objstm_id.make (next_objstm_num, 0)
									objstm := objstm_writer.finalize_stream (objstm_id)

										-- Write Object Stream as regular object
									offsets.put (buffer.count, next_objstm_num)
									write_object (objstm, objstm_id, buffer)
									written_count := written_count + 1

									next_objstm_num := next_objstm_num + 1
								end
							else
									-- Write directly (streams, special dictionaries)
								offsets.put (buffer.count, @ cursor.key)
								write_object (obj, id, buffer)
								written_count := written_count + 1
							end
						end
					end
				end
			end

				-- Handle new objects
			across a_doc.new_objects as cursor loop
				id := (@ cursor.item).object_id
				obj := (@ cursor.item).value

				if objstm_writer.can_add (obj) and id.generation = 0 then
					objstm_writer.add_object (obj, id)

					if objstm_writer.is_full then
						compressed_entries := objstm_writer.get_compressed_entries
						across compressed_entries as ce loop
							type2_entries.put ([next_objstm_num, ce.index], ce.obj_id.object_number)
						end

						create objstm_id.make (next_objstm_num, 0)
						objstm := objstm_writer.finalize_stream (objstm_id)
						offsets.put (buffer.count, next_objstm_num)
						write_object (objstm, objstm_id, buffer)
						written_count := written_count + 1
						next_objstm_num := next_objstm_num + 1
					end
				else
					offsets.put (buffer.count, id.object_number)
					write_object (obj, id, buffer)
					written_count := written_count + 1
				end
			end

				-- Finalize remaining objects in Object Stream
			if not objstm_writer.is_empty then
				compressed_entries := objstm_writer.get_compressed_entries
				across compressed_entries as ce loop
					type2_entries.put ([next_objstm_num, ce.index], ce.obj_id.object_number)
				end

				create objstm_id.make (next_objstm_num, 0)
				objstm := objstm_writer.finalize_stream (objstm_id)
				offsets.put (buffer.count, next_objstm_num)
				write_object (objstm, objstm_id, buffer)
				written_count := written_count + 1
			end

			log_info ("%NWriter (ObjStm mode): Wrote " + written_count.out + " objects%N")
			log_info ("Objects in ObjStm: " + type2_entries.count.out + "%N")

				-- Compute max ID for trailer Size
			max_id := next_objstm_num - 1
			create keys.make (offsets.count + type2_entries.count)
			across offsets as cursor loop
				if @ cursor.key > max_id then
					max_id := @ cursor.key
				end
				keys.extend (@ cursor.key)
			end
				-- Also include Type 2 entries in size calculation
			across type2_entries as cursor loop
				if @ cursor.key > max_id then
					max_id := @ cursor.key
				end
			end

				-- Write Xref Table (traditional for now, could be XRef stream later)
			start_xref := buffer.count
			write_xref_table_with_objstm (a_doc, offsets, type2_entries, keys, buffer, max_id + 1)

				-- When XRef stream is used (type2_entries not empty), trailer is embedded
				-- Otherwise write traditional trailer
			if type2_entries.is_empty then
				write_trailer (a_doc, max_id + 1, start_xref, buffer)
			else
				-- XRef stream already written, just add startxref and EOF
				buffer.append ("startxref")
				buffer.append (newline)
				buffer.append_integer (start_xref)
				buffer.append (newline)
				buffer.append ("%%%%EOF")
				buffer.append (newline)
			end

			last_output := buffer
		ensure
			output_generated: last_output /= Void and then not last_output.is_empty
		end

	should_skip_object (obj: PDF_OBJECT): BOOLEAN
			-- Should this object be skipped when writing?
			-- We skip linearization dictionaries, XRef stream objects, and object streams
			-- since they are not valid when converting to traditional xref format.
			-- Objects contained within object streams are extracted and written
			-- as individual objects, so we don't skip them.
		do
			if attached {PDF_DICTIONARY} obj as dict then
					-- Skip linearization dictionary - its offsets become invalid when rewriting
				if dict.has_key ("Linearized") then
					log_info ("[skip_check] Skipping Linearized dictionary%N")
					Result := True
				end
			elseif attached {PDF_STREAM} obj as stream then
					-- Check stream type and decide whether to skip
				if attached {PDF_NAME} stream.stream_dictionary.item ("Type") as type_name then
					if type_name.value.is_equal ("XRef") then
						log_info ("[skip_check] Skipping XRef stream%N")
						Result := True
					elseif type_name.value.is_equal ("ObjStm") then
						log_info ("[skip_check] Skipping ObjStm stream%N")
						Result := True
					elseif type_name.value.is_equal ("Hint") then
						log_info ("[skip_check] Skipping Hint stream%N")
						Result := True
					end
				end
			end
		end

feature {NONE} -- Implementation

	newline: STRING_8

	document: detachable PDF_DOCUMENT

	is_encrypt_dict (a_doc: PDF_DOCUMENT; obj_id: PDF_OBJECT_ID): BOOLEAN
			-- Is `obj_id` the /Encrypt dictionary?
		do
			if attached a_doc.trailer as t and then attached t.dictionary.item ("Encrypt") as enc then
				if attached {PDF_REFERENCE} enc as ref then
					Result := (ref.object_id.object_number = obj_id.object_number)
				end
			end
		end

	write_object (obj: PDF_OBJECT; id: PDF_OBJECT_ID; buffer: STRING_8)
			-- Write a single indirect object.
		local
			is_encrypt: BOOLEAN
		do
			if attached document as doc and then is_encrypt_dict (doc, id) then
				is_encrypt := True
			end

			buffer.append_integer (id.object_number)
			buffer.append_character (' ')
			buffer.append_integer (id.generation)
			buffer.append (" obj")
			buffer.append (newline)

			serializer.reset
			serializer.set_current_object_id (id)
			if is_encrypt then
					-- Per ISO 32000-1:2008 §7.6.1, strings and streams in the
					-- /Encrypt dictionary must not be encrypted. We temporarily
					-- bypass the security handler for this object.
				serializer.set_security_handler (Void)
			end
			obj.accept (serializer)
			if is_encrypt and then attached document as doc then
				serializer.set_security_handler (doc.security_handler)
			end
			serializer.set_current_object_id (Void)
			buffer.append (serializer.last_output)
			buffer.append (newline)

			buffer.append ("endobj")
			buffer.append (newline)
		end

	write_xref_table (offsets: HASH_TABLE [INTEGER, INTEGER]; keys: ARRAYED_LIST [INTEGER]; buffer: STRING_8)
			-- Write xref table with subsections.
		local
			sorted_keys: ARRAYED_LIST [INTEGER]
			section_start: INTEGER
			section_count: INTEGER
			current_key: INTEGER
			prev_key: INTEGER
			i: INTEGER
		do
			buffer.append ("xref")
			buffer.append (newline)

				-- Sort keys to find ranges
				-- keys contains all object numbers (except 0 if not present, but 0 is special)
			create sorted_keys.make_from_array (keys.to_array)
			sorted_keys.compare_objects
				-- Simple bubblesort or use library sort if available.
				-- ARRAYED_LIST doesn't have sort? It creates a temporary array?
				-- Wait, ARRAYED_LIST doesn't have built-in sort in all versions.
				-- I'll implement simple sort.
				--| TODO update manually.
			sort_integers (sorted_keys)

				-- Ensure 0 is handled. If 0 is not in offsets (usually it isn't), we act as if it's there for the free entry.
			if not sorted_keys.has (0) then
				sorted_keys.put_front (0)
			end

			from
				i := 1
				section_start := sorted_keys [1]
				section_count := 1
				prev_key := sorted_keys [1]
				i := 2 -- Start from second element
			until
				i > sorted_keys.count + 1 -- +1 to force write of last section
			loop
				if i <= sorted_keys.count then
					current_key := sorted_keys [i]
				else
					current_key := -1 -- End marker
				end

				if current_key = prev_key + 1 then
					section_count := section_count + 1
					prev_key := current_key
				else
						-- End of contiguous section
					write_xref_subsection (section_start, section_count, offsets, buffer)

					if i <= sorted_keys.count then
						section_start := current_key
						section_count := 1
						prev_key := current_key
					end
				end
				i := i + 1
			end
		end

	write_xref_subsection (start_obj, count: INTEGER; offsets: HASH_TABLE [INTEGER, INTEGER]; buffer: STRING_8)
			-- Write a single xref subsection.
		local
			i: INTEGER
			obj_num: INTEGER
			offset: INTEGER
		do
			buffer.append_integer (start_obj)
			buffer.append_character (' ')
			buffer.append_integer (count)
			buffer.append (newline)

			from
				i := 0
			until
				i >= count
			loop
				obj_num := start_obj + i
				if obj_num = 0 then
						-- Object 0 is always free head of list
					buffer.append ("0000000000 65535 f")
				else
					if offsets.has (obj_num) then
						offset := offsets.item (obj_num)
						buffer.append (format_offset (offset))
						buffer.append (" 00000 n")
					else
							-- Should not happen given how we built sections from existing keys
							-- Unless we had gaps in "sorted_keys" which we handled by closing section?
							-- Wait, my logic above assumes we ONLY write keys present in sorted_keys.
							-- So this else branch is unreachable if logic is correct.
						buffer.append ("0000000000 00000 f")
					end
				end
				buffer.append (newline)
				i := i + 1
			end
		end

	write_trailer (a_doc: PDF_DOCUMENT; size: INTEGER; start_xref: INTEGER; buffer: STRING_8)
			-- Write the file trailer.
		local
			root_ref: detachable PDF_REFERENCE
		do
			buffer.append ("trailer")
			buffer.append (newline)
			buffer.append ("<<")
			buffer.append (newline)

			buffer.append ("/Size ")
			buffer.append_integer (size)
			buffer.append (newline)

			if attached a_doc.trailer as t then
				if attached t.root as r then
					root_ref := r
				end
				-- Could also copy /Info, /ID if they exist
			end

			if root_ref /= Void then
				buffer.append ("/Root ")
				buffer.append (root_ref.to_pdf_string)
				buffer.append (newline)
			end

			if attached a_doc.trailer as t then
					-- Write /Encrypt if present
				if attached t.dictionary.item ("Encrypt") as enc then
					buffer.append ("/Encrypt ")
					serializer.reset
					enc.accept (serializer)
					buffer.append (serializer.last_output)
					buffer.append (newline)
				end

					-- Write /Info if present
				if attached t.dictionary.item ("Info") as info then
					buffer.append ("/Info ")
					serializer.reset
					info.accept (serializer)
					buffer.append (serializer.last_output)
					buffer.append (newline)
				end

					-- Write /ID if present
				if attached t.dictionary.item ("ID") as id then
					buffer.append ("/ID ")
					serializer.reset
					id.accept (serializer)
					buffer.append (serializer.last_output)
					buffer.append (newline)
				end

					-- Write other custom keys in trailer dictionary (e.g. /TempStream)
				across t.dictionary.entries as cursor loop
					if not (@ cursor.key).is_equal ("Size") and then
					   not (@ cursor.key).is_equal ("Root") and then
					   not (@ cursor.key).is_equal ("Encrypt") and then
					   not (@ cursor.key).is_equal ("Info") and then
					   not (@ cursor.key).is_equal ("ID") and then
					   not (@ cursor.key).is_equal ("Prev") and then
					   not (@ cursor.key).is_equal ("Type") and then
					   not (@ cursor.key).is_equal ("Filter") and then
					   not (@ cursor.key).is_equal ("DecodeParms") and then
					   not (@ cursor.key).is_equal ("Index") and then
					   not (@ cursor.key).is_equal ("W") and then
					   not (@ cursor.key).is_equal ("Length") then
						buffer.append ("/")
						buffer.append (@ cursor.key)
						buffer.append_character (' ')
						serializer.reset
						cursor.accept (serializer)
						buffer.append (serializer.last_output)
						buffer.append (newline)
					end
				end
			end

			buffer.append (">>")
			buffer.append (newline)

			buffer.append ("startxref")
			buffer.append (newline)
			buffer.append_integer (start_xref)
			buffer.append (newline)
			buffer.append ("%%%%EOF")
			buffer.append (newline)
		end

	format_offset (offset: INTEGER): STRING_8
			-- Format offset as 10-digit zero-padded string.
		require
			valid_offset: offset >= 0
		local
			s: STRING_8
			padding_needed: INTEGER
		do
			s := offset.out
			padding_needed := 10 - s.count
			create Result.make (10)
			from
			until
				padding_needed <= 0
			loop
				Result.append_character ('0')
				padding_needed := padding_needed - 1
			end
			Result.append (s)
		ensure
			correct_length: Result.count = 10
		end

	write_xref_stream_standalone (a_doc: PDF_DOCUMENT; offsets: HASH_TABLE [INTEGER, INTEGER];
		buffer: STRING_8; size: INTEGER)
			-- Write XRef stream without Type 2 entries (all objects are Type 1).
			-- Per ISO 32000-1:2008 §7.5.8, provides compressed cross-reference data.
		local
			obj_num: INTEGER
			w1, w2, w3: INTEGER
			max_offset: INTEGER
			xref_data: STRING_8
			xref_dict: PDF_DICTIONARY
			xref_stream: PDF_STREAM
			compressed: detachable STRING_8
			compressor: ZLIB_COMPRESS
			start_xref: INTEGER
		do
			log_info ("[write_xref_stream_standalone] Writing XRef stream for " + size.out + " entries%N")

				-- Record startxref position
			start_xref := buffer.count

				-- Calculate max offset for W array
			max_offset := 0
			across offsets as cursor loop
				if cursor > max_offset then
					max_offset := cursor
				end
			end

				-- Calculate W array field widths
			w1 := bytes_needed (1)  -- Type field: 0 or 1 only
			w2 := bytes_needed (max_offset)
			w3 := bytes_needed (65535)  -- generation is always 0-65535

				-- Build binary xref data for objects 0 to size-1
			create xref_data.make (size * (w1 + w2 + w3))
			from
				obj_num := 0
			until
				obj_num >= size
			loop
				if obj_num = 0 then
					-- Free entry (Type 0)
					write_xref_field (xref_data, 0, w1)
					write_xref_field (xref_data, 0, w2)
					write_xref_field (xref_data, 65535, w3)
				elseif offsets.has (obj_num) then
					-- In-use object (Type 1)
					write_xref_field (xref_data, 1, w1)
					write_xref_field (xref_data, offsets.item (obj_num), w2)
					write_xref_field (xref_data, 0, w3)
				else
					-- Free entry (object not present)
					write_xref_field (xref_data, 0, w1)
					write_xref_field (xref_data, 0, w2)
					write_xref_field (xref_data, 0, w3)
				end
				obj_num := obj_num + 1
			end

				-- Compress xref data
			create compressor
			compressor.compress_string (xref_data)
			if compressor.is_last_operation_ok then
				compressed := compressor.last_compressed_string
			end

				-- Build XRef stream dictionary
			create xref_dict.make (10)
			xref_dict.put_name ("XRef", "Type")
			xref_dict.put_number (size, "Size")

				-- /W array
			xref_dict.put (create {PDF_ARRAY}.make_with_integers (<<w1, w2, w3>>), "W")

				-- /Index array [0 size]
			xref_dict.put (create {PDF_ARRAY}.make_with_integers (<<0, size>>), "Index")

				-- Add trailer entries to XRef stream dictionary
			if attached a_doc.trailer as t then
				across t.dictionary.entries as cursor loop
					if not (@ cursor.key).is_equal ("Size") and then
					   not (@ cursor.key).is_equal ("Type") and then
					   not (@ cursor.key).is_equal ("W") and then
					   not (@ cursor.key).is_equal ("Index") and then
					   not (@ cursor.key).is_equal ("Prev") then
						xref_dict.put (cursor, @ cursor.key)
					end
				end
			end

			if attached compressed as comp then
				xref_dict.put_name ("FlateDecode", "Filter")
				xref_dict.put_number (comp.count, "Length")
				create xref_stream.make_with_dictionary (xref_dict, comp)
			else
				xref_dict.put_number (xref_data.count, "Length")
				create xref_stream.make_with_dictionary (xref_dict, xref_data)
			end
			xref_stream.logger := logger

				-- Write as indirect object (object number = size, generation = 0)
			buffer.append_integer (size)
			buffer.append (" 0 obj")
			buffer.append (newline)
			serializer.reset
			xref_stream.accept (serializer)
			buffer.append (serializer.last_output)
			buffer.append (newline)
			buffer.append ("endobj")
			buffer.append (newline)

				-- Write startxref and EOF
			buffer.append ("startxref")
			buffer.append (newline)
			buffer.append_integer (start_xref)
			buffer.append (newline)
			buffer.append ("%%%%EOF")
			buffer.append (newline)
		end

	sort_integers (list: ARRAYED_LIST [INTEGER])
			-- Sort list of integers using Shell Sort (more efficient than bubble sort).
		local
			i, j, gap: INTEGER
			temp: INTEGER
			count: INTEGER
		do
			count := list.count
			gap := count // 2

			from
			until
				gap = 0
			loop
				from
					i := gap + 1
				until
					i > count
				loop
					temp := list [i]
					from
						j := i
					until
						j <= gap or else list [j - gap] <= temp
					loop
						list [j] := list [j - gap]
						j := j - gap
					end
					list [j] := temp
					i := i + 1
				end
				gap := gap // 2
			end
		end

	write_xref_table_with_objstm (a_doc: PDF_DOCUMENT; offsets: HASH_TABLE [INTEGER, INTEGER];
		type2_entries: HASH_TABLE [TUPLE [stream_num: INTEGER; idx: INTEGER], INTEGER];
		keys: ARRAYED_LIST [INTEGER]; buffer: STRING_8; size: INTEGER)
			-- Write xref data supporting both Type 1 and Type 2 entries.
			-- If there are Type 2 entries, writes an XRef stream instead of traditional table.
			-- XRef stream includes trailer entries (/Root, /Info, /ID) per ISO 32000-1:2008 §7.5.8.
		local
			obj_num: INTEGER
			w1, w2, w3: INTEGER
			max_offset, max_stream_num, max_idx: INTEGER
			xref_data: STRING_8
			xref_dict: PDF_DICTIONARY
			xref_stream: PDF_STREAM
			compressed: detachable STRING_8
			compressor: ZLIB_COMPRESS
		do
			if type2_entries.is_empty then
					-- No Type 2 entries, use traditional xref table
				write_xref_table (offsets, keys, buffer)
			else
					-- Has Type 2 entries, must use XRef stream
				log_info ("[write_xref_table_with_objstm] Using XRef stream for Type 2 entries%N")

					-- Calculate W array field widths
				max_offset := 0
				max_stream_num := 0
				max_idx := 0
				across offsets as cursor loop
					if cursor > max_offset then
						max_offset := cursor
					end
				end
				across type2_entries as cursor loop
					if cursor.stream_num > max_stream_num then
						max_stream_num := cursor.stream_num
					end
					if cursor.idx > max_idx then
						max_idx := cursor.idx
					end
				end

				w1 := bytes_needed (2)  -- Type field: 0, 1, or 2
				w2 := bytes_needed (max_offset.max (max_stream_num))
				w3 := bytes_needed (max_idx.max (65535))  -- generation or index

					-- Build binary xref data for objects 0 to size-1
					-- Per spec, we need one entry for each object in the range
				create xref_data.make (size * (w1 + w2 + w3))
				from
					obj_num := 0
				until
					obj_num >= size
				loop
					if obj_num = 0 then
						-- Free entry (Type 0)
						write_xref_field (xref_data, 0, w1)
						write_xref_field (xref_data, 0, w2)
						write_xref_field (xref_data, 65535, w3)
					elseif type2_entries.has (obj_num) and then attached type2_entries.item (obj_num) as t2_entry then
							-- Compressed object (Type 2)
						write_xref_field (xref_data, 2, w1)
						write_xref_field (xref_data, t2_entry.stream_num, w2)
						write_xref_field (xref_data, t2_entry.idx, w3)
					elseif offsets.has (obj_num) then
							-- In-use object (Type 1)
						write_xref_field (xref_data, 1, w1)
						write_xref_field (xref_data, offsets.item (obj_num), w2)
						write_xref_field (xref_data, 0, w3)
					else
							-- Free entry (object not present)
						write_xref_field (xref_data, 0, w1)
						write_xref_field (xref_data, 0, w2)
						write_xref_field (xref_data, 0, w3)
					end
					obj_num := obj_num + 1
				end

					-- Compress xref data
				create compressor
				compressor.compress_string (xref_data)
				if compressor.is_last_operation_ok then
					compressed := compressor.last_compressed_string
				end

					-- Build XRef stream dictionary
				create xref_dict.make (8)
				xref_dict.put_name ("XRef", "Type")
				xref_dict.put_number (size, "Size")

					-- /W array
				xref_dict.put (create {PDF_ARRAY}.make_with_integers (<<w1, w2, w3>>), "W")

					-- /Index array [0 size] - entries for all objects 0 to size-1
				xref_dict.put (create {PDF_ARRAY}.make_with_integers (<<0, size>>), "Index")

					-- Add trailer entries to XRef stream dictionary
				if attached a_doc.trailer as t then
					across t.dictionary.entries as cursor loop
						if not (@ cursor.key).is_equal ("Size") and then
						   not (@ cursor.key).is_equal ("Type") and then
						   not (@ cursor.key).is_equal ("W") and then
						   not (@ cursor.key).is_equal ("Index") and then
						   not (@ cursor.key).is_equal ("Prev") then
							xref_dict.put (cursor, @ cursor.key)
						end
					end
				end

				if attached compressed as comp then
					xref_dict.put_name ("FlateDecode", "Filter")
					xref_dict.put_number (comp.count, "Length")
					create xref_stream.make_with_dictionary (xref_dict, comp)
				else
					xref_dict.put_number (xref_data.count, "Length")
					create xref_stream.make_with_dictionary (xref_dict, xref_data)
				end
				xref_stream.logger := logger

					-- Write as indirect object (object number = size, generation = 0)
				buffer.append_integer (size)
				buffer.append (" 0 obj")
				buffer.append (newline)
				serializer.reset
				xref_stream.accept (serializer)
				buffer.append (serializer.last_output)
				buffer.append (newline)
				buffer.append ("endobj")
				buffer.append (newline)
			end
		end

	bytes_needed (value: INTEGER): INTEGER
			-- Number of bytes needed to represent value.
		do
			if value <= 255 then
				Result := 1
			elseif value <= 65535 then
				Result := 2
			elseif value <= 16777215 then
				Result := 3
			else
				Result := 4
			end
		ensure
			positive: Result >= 1
		end

	write_xref_field (buffer: STRING_8; value: INTEGER; width: INTEGER)
			-- Write value as big-endian bytes with given width.
		local
			i: INTEGER
			byte_val: INTEGER
		do
			from
				i := width - 1
			until
				i < 0
			loop
				byte_val := (value |>> (i * 8)) \\ 256
				buffer.append_character (byte_val.to_character_8)
				i := i - 1
			end
		end

end

