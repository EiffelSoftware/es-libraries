note
	description: "[
		Represents a PDF trailer dictionary.
		Contains document-level metadata and pointers to key structures.
		Implements ISO 32000-1:2008 §7.5.5 (File Trailer).
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_TRAILER

create
	make

feature -- Initialization

	make (a_dictionary: PDF_DICTIONARY)
			-- Create trailer from dictionary.
		do
			dictionary := a_dictionary
		ensure
			dictionary_set: dictionary = a_dictionary
		end

feature -- Access

	dictionary: PDF_DICTIONARY
			-- Trailer dictionary.

	size: INTEGER
			-- Total number of entries in xref table (required).
		do
				-- Per ISO 32000-1:2008, name keys do not include leading slash
			if attached {PDF_NUMBER} dictionary.item ("Size") as num_obj then
				Result := num_obj.real_value.truncated_to_integer
			end
		end

	root: detachable PDF_REFERENCE
			-- Reference to catalog dictionary (required).
		do
			if attached {PDF_REFERENCE} dictionary.item ("Root") as ref then
				Result := ref
			end
		end

	info: detachable PDF_REFERENCE
			-- Reference to info dictionary (optional).
		do
			if attached {PDF_REFERENCE} dictionary.item ("Info") as ref then
				Result := ref
			end
		end

	prev: INTEGER
			-- Byte offset of previous xref section (for incremental updates).
		do
			if attached {PDF_NUMBER} dictionary.item ("Prev") as num_obj then
				Result := num_obj.real_value.truncated_to_integer
			end
		end

feature -- Status Report

	has_prev: BOOLEAN
			-- Does this trailer have a previous xref section?
		do
			Result := dictionary.has_key ("Prev")
		end

	is_valid: BOOLEAN
			-- Is this trailer valid (has required entries)?
		do
			Result := size > 0 and root /= Void
		ensure
			definition: Result = (size > 0 and root /= Void)
		end

end
