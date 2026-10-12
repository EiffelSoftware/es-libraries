note
	description: "[
		Represents a PDF cross-reference table.
		Maps object numbers to their byte offsets in the file.
		Implements ISO 32000-1:2008 §7.5.4 (Cross-Reference Table).
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_XREF_TABLE

create
	make

feature -- Initialization

	make
			-- Create empty cross-reference table.
		do
			create entries.make (100)
		ensure
			entries_created: entries /= Void
		end

feature -- Access

	entries: HASH_TABLE [PDF_XREF_ENTRY, INTEGER]
			-- Map from object number to xref entry.

	entry (obj_num: INTEGER): detachable PDF_XREF_ENTRY
			-- Entry for given object number, if any.
		require
			valid_obj_num: obj_num >= 0
		do
			if entries.has (obj_num) then
				Result := entries.item (obj_num)
			end
		end

	count: INTEGER
			-- Number of entries in table.
		do
			Result := entries.count
		ensure
			definition: Result = entries.count
		end

feature -- Element Change

	add_entry (obj_num: INTEGER; a_entry: PDF_XREF_ENTRY)
			-- Add entry for given object number.
		require
			valid_obj_num: obj_num >= 0
		do
			if not entries.has (obj_num) then
				entries.put (a_entry, obj_num)
			end
		ensure
			entry_added: entries.has (obj_num)
		end

	add_in_use (obj_num: INTEGER; offset: INTEGER; generation: INTEGER)
			-- Add in-use entry for given object number.
		require
			valid_obj_num: obj_num >= 0
			valid_offset: offset >= 0
			valid_generation: generation >= 0 and generation <= 65535
		local
			new_entry: PDF_XREF_ENTRY
		do
			create new_entry.make_in_use (offset, generation)
			add_entry (obj_num, new_entry)
		ensure
			entry_added: entries.has (obj_num)
		end

	add_free (obj_num: INTEGER; next_free: INTEGER; generation: INTEGER)
			-- Add free entry for given object number.
		require
			valid_obj_num: obj_num >= 0
			valid_next_free: next_free >= 0
			valid_generation: generation >= 0 and generation <= 65535
		local
			new_entry: PDF_XREF_ENTRY
		do
			create new_entry.make_free (next_free, generation)
			add_entry (obj_num, new_entry)
		ensure
			entry_added: entries.has (obj_num)
		end

	add_compressed (obj_num: INTEGER; obj_stm_num: INTEGER; index: INTEGER)
			-- Add compressed entry (Type 2) for given object number.
		require
			valid_obj_num: obj_num >= 0
			valid_stm_num: obj_stm_num >= 0
			valid_index: index >= 0
		local
			new_entry: PDF_XREF_ENTRY
		do
			create new_entry.make_compressed (obj_stm_num, index)
			add_entry (obj_num, new_entry)
		ensure
			entry_added: entries.has (obj_num)
		end

feature -- Status Report

	has_entry (obj_num: INTEGER): BOOLEAN
			-- Is there an entry for given object number?
		require
			valid_obj_num: obj_num >= 0
		do
			Result := entries.has (obj_num)
		ensure
			definition: Result = entries.has (obj_num)
		end

end
