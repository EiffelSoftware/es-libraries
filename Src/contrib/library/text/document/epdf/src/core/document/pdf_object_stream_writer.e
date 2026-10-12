note
	description: "[
		Writes PDF Object Streams per ISO 32000-1:2008 §7.5.7.
		Groups multiple compatible objects into compressed streams for file size reduction.
		
		Object Stream format:
		- Stream dictionary: /Type /ObjStm, /N (count), /First (offset to first object)
		- Stream content: N pairs of (object_number, byte_offset), then object data
		- Objects stored WITHOUT obj/endobj wrappers
	]"
	spec_reference: "ISO 32000-1:2008 §7.5.7 (Object Streams)"
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_OBJECT_STREAM_WRITER

inherit
	PDF_WITH_LOGGING

create
	make

feature -- Initialization

	make (a_max_objects: INTEGER)
			-- Create object stream writer with maximum objects per stream.
		require
			positive_max: a_max_objects > 0
		do
			max_objects_per_stream := a_max_objects
			create serializer.make
			serializer.logger := logger
			create current_objects.make (a_max_objects)
			create current_header.make_empty
			create current_content.make_empty
			create compressor
		ensure
			max_set: max_objects_per_stream = a_max_objects
			objects_empty: current_objects.is_empty
		end

feature -- Access

	max_objects_per_stream: INTEGER
			-- Maximum number of objects per stream.

	object_count: INTEGER
			-- Number of objects currently buffered.
		do
			Result := current_objects.count
		end

	is_full: BOOLEAN
			-- Is current stream at capacity?
		do
			Result := current_objects.count >= max_objects_per_stream
		end

	is_empty: BOOLEAN
			-- Is current stream empty?
		do
			Result := current_objects.is_empty
		end

feature -- Status

	can_add (obj: PDF_OBJECT): BOOLEAN
			-- Can this object be added to an Object Stream?
			-- Per §7.5.7: streams and objects with generation > 0 cannot be compressed.
		do
				-- Objects that CAN be compressed:
				--   - Dictionaries (except special types)
				--   - Arrays
				--   - Strings
				--   - Names
				--   - Numbers
				--   - Booleans
				--   - Null
				-- Objects that CANNOT be compressed:
				--   - Streams (have separate stream data)
				--   - Objects with generation number > 0 (per §7.5.7)

			if attached {PDF_STREAM} obj then
				Result := False
			elseif attached {PDF_DICTIONARY} obj as dict then
					-- Check for special dictionary types that shouldn't be in ObjStm
				Result := not is_special_dictionary (dict)
			else
				Result := True
			end
		end

feature -- Operations

	add_object (obj: PDF_OBJECT; obj_id: PDF_OBJECT_ID)
			-- Add object to current stream.
		require
			can_add_object: can_add (obj)
			not_full: not is_full
			generation_zero: obj_id.generation = 0
		local
			offset: INTEGER
		do
				-- Serialize object WITHOUT obj/endobj wrapper
			serializer.reset
			obj.accept (serializer)

				-- Record offset relative to start of object data section
			offset := current_content.count

				-- Store for later
			current_objects.extend ([obj_id, offset, serializer.last_output.twin])

				-- Append serialized content
			current_content.append (serializer.last_output)
			current_content.append (" ")  -- Whitespace separator per spec
		ensure
			object_added: object_count = old object_count + 1
		end

	finalize_stream (stream_object_id: PDF_OBJECT_ID): PDF_STREAM
			-- Finalize current stream and return it.
			-- Caller is responsible for assigning the returned stream an object ID.
		require
			not_empty: not is_empty
		local
			dict: PDF_DICTIONARY
			header_content: STRING_8
			full_content: STRING_8
			compressed: detachable STRING_8
			first_offset: INTEGER
			i: INTEGER
			entry: TUPLE [id: PDF_OBJECT_ID; offset: INTEGER; data: STRING_8]
		do
				-- Build header: N pairs of (object_number, byte_offset)
			create header_content.make (current_objects.count * 10)
			from
				i := 1
			until
				i > current_objects.count
			loop
				entry := current_objects [i]
				if i > 1 then
					header_content.append_character (' ')
				end
				header_content.append_integer (entry.id.object_number)
				header_content.append_character (' ')
				header_content.append_integer (entry.offset)
				i := i + 1
			end
			header_content.append (" ")  -- Trailing space before object data

				-- Calculate /First (offset to first object data)
			first_offset := header_content.count

				-- Combine header and content
			create full_content.make (header_content.count + current_content.count)
			full_content.append (header_content)
			full_content.append (current_content)

				-- Compress
			compressor.compress_string (full_content)
			if compressor.is_last_operation_ok then
				compressed := compressor.last_compressed_string
			end

				-- Create stream dictionary
			create dict.make (5)
			dict.put_name ("ObjStm", "Type")
			dict.put_number (current_objects.count, "N")
			dict.put_number (first_offset, "First")

				-- Create stream with compressed or original content
			if attached compressed as comp then
				dict.put_name ("FlateDecode", "Filter")
				dict.put_number (comp.count, "Length")
				create Result.make_with_dictionary (dict, comp)
			else
				dict.put_number (full_content.count, "Length")
				create Result.make_with_dictionary (dict, full_content)
			end
			Result.logger := logger

				-- Clear for next stream
			clear
		ensure
			cleared: is_empty
			result_is_objstm: attached {PDF_NAME} Result.stream_dictionary.item ("Type") as t and then t.value.is_equal ("ObjStm")
		end

	get_compressed_entries: ARRAYED_LIST [TUPLE [obj_id: PDF_OBJECT_ID; stream_num: INTEGER; index: INTEGER]]
			-- Get list of objects that were added, with their stream location.
			-- Call this BEFORE finalize_stream to get the entries.
		require
			not_empty: not is_empty
		local
			i: INTEGER
			entry: TUPLE [id: PDF_OBJECT_ID; offset: INTEGER; data: STRING_8]
		do
			create Result.make (current_objects.count)
			from
				i := 1
			until
				i > current_objects.count
			loop
				entry := current_objects [i]
					-- Index is 0-based per spec
				Result.extend ([entry.id, 0, i - 1])  -- stream_num will be set by caller
				i := i + 1
			end
		ensure
			correct_count: Result.count = object_count
		end

	clear
			-- Clear current stream buffer for reuse.
		do
			current_objects.wipe_out
			current_header.wipe_out
			current_content.wipe_out
		ensure
			cleared: is_empty
		end

feature {NONE} -- Implementation

	serializer: PDF_SERIALIZER
			-- Serializer for objects.

	compressor: ZLIB_COMPRESS
			-- Compressor for stream content.

	current_objects: ARRAYED_LIST [TUPLE [id: PDF_OBJECT_ID; offset: INTEGER; data: STRING_8]]
			-- Objects in current stream with their offsets.

	current_header: STRING_8
			-- Current header being built.

	current_content: STRING_8
			-- Current object content being accumulated.

	is_special_dictionary (dict: PDF_DICTIONARY): BOOLEAN
			-- Is this a special dictionary type that shouldn't go in ObjStm?
		do
				-- These types need to be standalone objects:
				-- - /Type /Catalog (document root)
				-- - /Type /Pages (page tree nodes)
				-- - /Type /Page (page objects - often needed for linearization)
				-- - /Type /Encrypt (encryption dictionary)
				-- - /Type /XRef (xref stream - obviously)
				-- - /Type /ObjStm (cannot nest object streams)
				-- - /Linearized dictionary

			if dict.has_key ("Linearized") then
				Result := True
			elseif attached {PDF_NAME} dict.item ("Type") as type_name then
				Result := type_name.value.is_equal ("Catalog") or
				          type_name.value.is_equal ("Encrypt") or
				          type_name.value.is_equal ("XRef") or
				          type_name.value.is_equal ("ObjStm")
			else
				Result := False
			end
		end

invariant
	objects_capacity: current_objects.count <= max_objects_per_stream
	serializer_exists: serializer /= Void
	compressor_exists: compressor /= Void

end
