note
	description: "[
		Represents a single entry in a PDF cross-reference table.
		Each entry describes the location and status of an indirect object.
		Implements ISO 32000-1:2008 §7.5.4 (Cross-Reference Table).
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_XREF_ENTRY

create
	make_free,
	make_in_use,
	make_compressed

feature -- Initialization

	make_free (a_next_free: INTEGER; a_generation: INTEGER)
			-- Create free entry pointing to next free object.
		require
			valid_next_free: a_next_free >= 0
			valid_generation: a_generation >= 0 and a_generation <= 65535
		do
			offset := a_next_free
			generation := a_generation
			is_in_use := False
			is_compressed := False
			object_stream_number := 0
			index_in_stream := 0
		ensure
			not_in_use: not is_in_use
			not_compressed: not is_compressed
			offset_set: offset = a_next_free
			generation_set: generation = a_generation
		end

	make_in_use (a_offset: INTEGER; a_generation: INTEGER)
			-- Create in-use entry at given byte offset.
		require
			valid_offset: a_offset >= 0
			valid_generation: a_generation >= 0 and a_generation <= 65535
		do
			offset := a_offset
			generation := a_generation
			is_in_use := True
			is_compressed := False
			object_stream_number := 0
			index_in_stream := 0
		ensure
			in_use: is_in_use
			not_compressed: not is_compressed
			offset_set: offset = a_offset
			generation_set: generation = a_generation
		end

	make_compressed (a_obj_stm_num: INTEGER; a_index: INTEGER)
			-- Create compressed entry (Type 2).
			-- Located in object stream 'a_obj_stm_num' at index 'a_index'.
		require
			valid_stm_num: a_obj_stm_num >= 0
			valid_index: a_index >= 0
		do
			object_stream_number := a_obj_stm_num
			index_in_stream := a_index
			is_compressed := True
			is_in_use := True -- Compressed objects are implicitly in use
			offset := 0
			generation := 0
		ensure
			compressed: is_compressed
			in_use: is_in_use
			stm_num_set: object_stream_number = a_obj_stm_num
			index_set: index_in_stream = a_index
		end

feature -- Access

	offset: INTEGER
			-- Byte offset of object (if in use) or next free object number (if free).

	generation: INTEGER
			-- Generation number (0-65535).

	object_stream_number: INTEGER
			-- Object number of the object stream containing this object (for Type 2).

	index_in_stream: INTEGER
			-- Index of this object within the object stream (for Type 2).

	is_in_use: BOOLEAN
			-- Is this entry in use (true) or free (false)?

	is_compressed: BOOLEAN
			-- Is this a compressed object (Type 2)?

feature -- Status Report

	is_free: BOOLEAN
			-- Is this entry free?
		do
			Result := not is_in_use
		ensure
			definition: Result = not is_in_use
		end

end
