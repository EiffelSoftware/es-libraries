note
	description: "[
		Writes incremental updates to an existing PDF document.
		Appends modified objects and a new cross-reference section to the original file.
		Implements ISO 32000-1:2008 §7.5.6 (Incremental Updates).
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_INCREMENTAL_WRITER

inherit
	PDF_WITH_LOGGING

create
	make

feature -- Initialization

	make
			-- Initialize writer.
		do
			create serializer.make
			create last_output.make_empty
		end

feature -- Access

	last_output: STRING_8
			-- Output message or result.

feature -- Operations

	write_incremental_update (a_doc: PDF_DOCUMENT; a_original_path: READABLE_STRING_GENERAL; a_output_path: READABLE_STRING_GENERAL)
			-- Write incremental update to a_output_path.
			-- Copies a_original_path and appends changes from a_doc.
		require
			doc_loaded: a_doc.is_loaded
			original_exists: a_original_path /= Void and not a_original_path.is_empty
			output_valid: a_output_path /= Void and not a_output_path.is_empty
		local
			input_file: RAW_FILE
			output_file: RAW_FILE
			offsets: HASH_TABLE [INTEGER, INTEGER]
			obj_id: INTEGER
			start_xref: INTEGER
			max_id: INTEGER
		do
			log_info ("[PDF_INCREMENTAL_WRITER] Starting incremental update (Original: " + a_doc.last_startxref.out + ")%N")
			document := a_doc
			serializer.set_security_handler (a_doc.security_handler)

				-- Copy original file to output
			create input_file.make_open_read (a_original_path)
			create output_file.make_create_read_write (a_output_path)

			input_file.read_stream (input_file.count)
			output_file.put_string (input_file.last_string)
			input_file.close

			log_info ("[PDF_INCREMENTAL_WRITER] Copied " + output_file.count.out + " bytes%N")

				-- Prepare offsets map
			create offsets.make (a_doc.modified_objects.count + a_doc.new_objects.count)
			max_id := a_doc.next_object_number - 1

				-- Append modified objects
			from
				a_doc.modified_objects.start
			until
				a_doc.modified_objects.after
			loop
				offsets.put (output_file.count, a_doc.modified_objects.key_for_iteration)
				write_object (a_doc.modified_objects.item_for_iteration, a_doc.modified_objects.key_for_iteration, output_file)
				a_doc.modified_objects.forth
			end

				-- Append new objects
			across a_doc.new_objects as cursor loop
				obj_id := cursor.object_id.object_number
				offsets.put (output_file.count, obj_id)
				write_object (cursor.value, obj_id, output_file)
			end

				-- Write new XRef section (using XRef Stream for compactness)
				-- We use PDF_DOCUMENT_WRITER's logic but tailored for incremental
				-- For now, let's implement a simple XRef stream writer here or reuse

			start_xref := output_file.count
			write_incremental_xref (a_doc, offsets, output_file, max_id + 1)

			output_file.put_string (start_xref.out)
			output_file.put_string ("%N%%%%EOF%N")

			output_file.close
			log_info ("[PDF_INCREMENTAL_WRITER] StartXRef at " + start_xref.out + "%N")
		end

feature {NONE} -- Implementation

	serializer: PDF_SERIALIZER

	document: detachable PDF_DOCUMENT

	write_object (a_obj: PDF_OBJECT; a_id: INTEGER; a_file: RAW_FILE)
		local
			obj_id: PDF_OBJECT_ID
			is_encrypt: BOOLEAN
		do
			if attached document as doc and then attached doc.trailer as t and then attached t.dictionary.item ("Encrypt") as enc then
				if attached {PDF_REFERENCE} enc as ref and then ref.object_id.object_number = a_id then
					is_encrypt := True
				end
			end

			a_file.put_string (a_id.out)
			a_file.put_string (" 0 obj")
			a_file.put_string ("%N")

			serializer.reset
			create obj_id.make (a_id, 0)
			serializer.set_current_object_id (obj_id)
			if is_encrypt then
					-- Per ISO 32000-1:2008 §7.6.1, strings and streams in the
					-- /Encrypt dictionary must not be encrypted. We temporarily
					-- bypass the security handler for this object.
				serializer.set_security_handler (Void)
			end
			a_obj.accept (serializer)
			if is_encrypt and then attached document as doc then
				serializer.set_security_handler (doc.security_handler)
			end
			serializer.set_current_object_id (Void)
			a_file.put_string (serializer.last_output)

			a_file.put_string ("%Nendobj%N")
		end

	write_incremental_xref (a_doc: PDF_DOCUMENT; offsets: HASH_TABLE [INTEGER, INTEGER]; a_file: RAW_FILE; size: INTEGER)
			-- Write incremental XRef stream
		local
			writer: PDF_DOCUMENT_WRITER
			buffer: STRING_8
		do
			create writer.make
			writer.set_use_xref_stream (True)

				-- We need to construct a trailer that includes /Prev
			if attached a_doc.trailer as t then
				t.dictionary.put_number (a_doc.last_startxref, "Prev")
				-- Ensure Size is correct
				t.dictionary.put_number (size, "Size")
			end

				-- Using the standalone writer from Phase 5B
				-- Note: offsets only contains NEW/MODIFIED objects.
				-- The writer needs to handle sparse offsets if we pass them.
				-- write_xref_stream_standalone iterates 0..size-1.
				-- If entry is missing in 'offsets', it writes Type 0 (free).
				-- BUT for incremental update, valid objects that are NOT modified should NOT be marked as free.
				-- They should just be omitted from the stream if we use a simplified stream,
				-- OR we need to write a stream that only updates specific objects (using /Index).

				-- Current write_xref_stream_standalone writes ALL entries 0..size.
				-- This is NOT efficient for incremental updates if size is large.
				-- We should write a partial XRef stream using /Index.

				-- Let's implement a specific incremental xref stream writer here.

			buffer := write_partial_xref_stream (a_doc, offsets, size)
			a_file.put_string (buffer)
		end

	write_partial_xref_stream (a_doc: PDF_DOCUMENT; offsets: HASH_TABLE [INTEGER, INTEGER]; size: INTEGER): STRING_8
		local
			dict: PDF_DICTIONARY
			stream: PDF_STREAM
			xref_data: STRING_8
			w1, w2, w3: INTEGER
			max_offset: INTEGER
			keys: ARRAYED_LIST [INTEGER]
			comp: detachable STRING_8
			compressor: ZLIB_COMPRESS
			res: STRING_8
			start_xref: INTEGER
			index_array: PDF_ARRAY
		do
			create res.make (1024)

				-- Calculate W widths
			max_offset := 0
			across offsets as cursor loop
				if cursor.item > max_offset then max_offset := cursor.item end
			end
			w1 := 1
			w2 := bytes_needed (max_offset)
			w3 := bytes_needed (0) -- Generation always 0 for now

				-- Sort keys for /Index
			create keys.make (offsets.count)
			from
				offsets.start
			until
				offsets.after
			loop
				keys.extend (offsets.key_for_iteration)
				offsets.forth
			end
				-- Need to sort keys... simpler to just write all if small?
				-- No, for incremental we must use /Index to skip unchanged objects.
				-- Let's rely on simple bubble sort for now or implement shell sort.
			sort_integers (keys)

				-- Build data and Index
			create xref_data.make (offsets.count * (w1 + w2 + w3))
			create index_array.make_empty

				-- Simple run-length encoding for /Index would be better, but listing singletons is safe.
				-- Let's just do singletons for now: [obj_num 1 obj_num 1 ...]
				-- Or try to group contiguous ranges.
			build_index_and_data (keys, offsets, w1, w2, w3, index_array, xref_data)

				-- Create stream dictionary
			create dict.make (10)
			dict.put_name ("XRef", "Type")
			dict.put (index_array, "Index")
			dict.put (create {PDF_ARRAY}.make_with_integers (<<w1, w2, w3>>), "W")
			dict.put_number (size, "Size")
			dict.put_number (a_doc.last_startxref, "Prev")

			if attached a_doc.trailer as t then
				if attached t.root as r then dict.put (r, "Root") end
				if attached t.dictionary.item ("Encrypt") as enc then dict.put (enc, "Encrypt") end
				if attached t.dictionary.item ("Info") as i then dict.put (i, "Info") end
				if attached t.dictionary.item ("ID") as id then dict.put (id, "ID") end
			end

				-- Compress
			create compressor
			compressor.compress_string (xref_data)
			if compressor.is_last_operation_ok then
				comp := compressor.last_compressed_string
			end

			if attached comp as c then
				dict.put_name ("FlateDecode", "Filter")
				dict.put_number (c.count, "Length")
				create stream.make_with_dictionary (dict, c)
			else
				dict.put_number (xref_data.count, "Length")
				create stream.make_with_dictionary (dict, xref_data)
			end

				-- Serialize XRef Object
				-- Incremental XRef is usually written as an indirect object, but which ID?
				-- It doesn't strictly need one if it's the trailer, but XRef streams ARE objects.
				-- Usually they take the next available ID? Or can be any free ID.
				-- But wait, if we add a new object, we need to know its ID to put in startxref?
				-- No, startxref points to byte offset.
				-- Only the object itself needs an ID.
				-- We can give it ID = size (if we assume we are appending).
				-- Or we can skip giving it an ID if we just validly format it?
				-- No, XRef stream MUST be an indirect object (obj ... endobj).
				-- So we use `size` as the object ID? Or `max_id + 1`?
				-- Let's use `size` (which is usually next_free).

				-- Note: We must NOT add this XRef stream object to the XRef stream itself!
				-- (Unless we want self-reference, which is allowed but not required).

			res.append_integer (size) -- Use size as ID
			res.append (" 0 obj%N")
			serializer.reset
			stream.accept (serializer)
			res.append (serializer.last_output)
			res.append ("%Nendobj%N")

			start_xref := a_doc.last_startxref -- This is PREV.
				-- Current startxref position is needed for %%EOF

			res.append ("startxref%N")
				-- We don't know the absolute offset here easily inside this function
				-- The caller should handle startxref calculation.
				-- But wait, I'm returning string. Caller appends it.

			Result := res
		end

	build_index_and_data (keys: ARRAYED_LIST [INTEGER]; offsets: HASH_TABLE [INTEGER, INTEGER];
		w1, w2, w3: INTEGER; index_arr: PDF_ARRAY; data: STRING_8)
		local
			i: INTEGER
			curr_num: INTEGER
		do
			from i := 1 until i > keys.count loop
				curr_num := keys [i]

					-- Add to Index (simple 1-item range for now)
				index_arr.add (create {PDF_NUMBER}.make (curr_num))
				index_arr.add (create {PDF_NUMBER}.make (1))

					-- Add data (Type 1 for modified objects)
				write_xref_field (data, 1, w1)
				write_xref_field (data, offsets.item (curr_num), w2)
				write_xref_field (data, 0, w3)

				i := i + 1
			end
		end

	write_xref_field (buffer: STRING_8; value: INTEGER; width: INTEGER)
		local
			i: INTEGER
			byte: INTEGER
		do
			from i := width - 1 until i < 0 loop
				byte := (value |>> (8 * i)) & 0xFF
				buffer.append_character (byte.to_character_8)
				i := i - 1
			end
		end

	bytes_needed (val: INTEGER): INTEGER
		do
			if val <= 255 then Result := 1
			elseif val <= 65535 then Result := 2
			elseif val <= 16777215 then Result := 3
			else Result := 4
			end
		end

	sort_integers (list: ARRAYED_LIST [INTEGER])
		local
			i, j, temp: INTEGER
		do
			from i := 1 until i > list.count loop
				from j := i + 1 until j > list.count loop
					if list [i] > list [j] then
						temp := list [i]
						list [i] := list [j]
						list [j] := temp
					end
					j := j + 1
				end
				i := i + 1
			end
		end

end
