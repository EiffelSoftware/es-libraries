note
	description: "[
		Byte source that reads from a file.
		Provides lazy loading of file contents for PDF parsing.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_FILE_BYTE_SOURCE

inherit
	PDF_BYTE_SOURCE

create
	make_from_file

feature -- Initialization

	make_from_file (a_file_path: READABLE_STRING_GENERAL)
			-- Initialize by loading file content.
			-- Uses READABLE_STRING_GENERAL to support Unicode file paths.
		require
			path_valid: a_file_path /= Void and then not a_file_path.is_empty
		local
			file: RAW_FILE
		do
			create file.make_open_read (a_file_path)
			create content.make (file.count)
			file.read_stream (file.count)
			content := file.last_string
			file.close
			current_position := 0
		ensure
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
			Result := content /= Void and then not content.is_empty
		end

feature -- Element Change

	set_position (a_position: INTEGER)
			-- Set current reading position.
		do
			current_position := a_position
		end

feature {NONE} -- Implementation

	content: STRING_8
			-- File content loaded into memory (byte sequence).

	current_position: INTEGER
			-- Current reading position (0-based).

invariant
	valid_content: content /= Void
	valid_position: current_position >= 0 and current_position <= content.count

end
