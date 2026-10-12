note
	description: "[
		Byte source that reads from a STRING.
		Useful for testing and for processing PDF content already loaded in memory.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_STRING_BYTE_SOURCE

inherit
	PDF_BYTE_SOURCE

create
	make

feature -- Initialization

	make (a_content: READABLE_STRING_GENERAL)
			-- Initialize with string content.
			-- Converts to STRING_8 for byte-level access.
		do
			content := a_content.to_string_8
			current_position := 0
		ensure
			content_set: content.same_string_general (a_content)
			position_at_start: position = 0
		end

feature -- Access

	byte_at (a_position: INTEGER): NATURAL_8
			-- Byte at given position (0-based).
		do
			Result := content.item (a_position + 1).natural_32_code.to_natural_8
		end

	byte_count: INTEGER
			-- Total number of bytes in source.
		do
			Result := content.count
		end

	position: INTEGER
			-- Current reading position (0-based).
		do
			Result := current_position
		end

feature -- Status Report

	is_valid: BOOLEAN
			-- Is the byte source valid and ready to read?
		do
			Result := True
		end

feature -- Element Change

	set_position (a_position: INTEGER)
			-- Set current reading position.
		do
			current_position := a_position
		end

feature {NONE} -- Implementation

	content: STRING_8
			-- String content being read (byte sequence).

	current_position: INTEGER
			-- Current reading position (0-based).

invariant
	valid_position: current_position >= 0 and current_position <= content.count

end
