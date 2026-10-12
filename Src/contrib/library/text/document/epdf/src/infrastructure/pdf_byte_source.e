note
	description: "[
		Abstraction for reading bytes from various sources (files, strings, streams).
		Provides consistent interface for parser to read PDF content without knowing the source.
		Supports both sequential reading and random access needed for PDF parsing.
	]"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	PDF_BYTE_SOURCE

feature -- Access

	byte_at (a_position: INTEGER): NATURAL_8
			-- Byte at given position (0-based).
		require
			valid_position: a_position >= 0 and a_position < byte_count
		deferred
		ensure
			valid_byte: Result >= 0
		end

	byte_count: INTEGER
			-- Total number of bytes in source.
		deferred
		ensure
			non_negative: Result >= 0
		end

	position: INTEGER
			-- Current reading position (0-based).
		deferred
		ensure
			valid_position: Result >= 0 and Result <= byte_count
		end

feature -- Status Report

	is_valid: BOOLEAN
			-- Is the byte source valid and ready to read?
		deferred
		end

	end_of_source: BOOLEAN
			-- Has the end of the source been reached?
		do
			Result := position >= byte_count
		ensure
			definition: Result = (position >= byte_count)
		end

feature -- Element Change

	set_position (a_position: INTEGER)
			-- Set current reading position.
		require
			valid_position: a_position >= 0 and a_position <= byte_count
		deferred
		ensure
			position_set: position = a_position
		end

	advance (offset: INTEGER)
			-- Move position forward by offset bytes.
		require
			valid_offset: offset >= 0
			valid_new_position: position + offset <= byte_count
		do
			set_position (position + offset)
		ensure
			position_advanced: position = old position + offset
		end

feature -- Basic Operations

	read_byte: NATURAL_8
			-- Read byte at current position and advance.
		require
			not_at_end: not end_of_source
		do
			Result := byte_at (position)
			advance (1)
		ensure
			position_advanced: position = old position + 1
		end

	read_bytes (count: INTEGER): ARRAY [NATURAL_8]
			-- Read count bytes starting at current position.
		require
			valid_count: count > 0
			enough_bytes: position + count <= byte_count
		local
			i: INTEGER
		do
			create Result.make_filled (0, 1, count)
			from
				i := 1
			until
				i > count
			loop
				Result [i] := read_byte
				i := i + 1
			end
		ensure
			correct_size: Result.count = count
			position_advanced: position = old position + count
		end

	peek_byte: NATURAL_8
			-- Look at byte at current position without advancing.
		require
			not_at_end: not end_of_source
		do
			Result := byte_at (position)
		ensure
			position_unchanged: position = old position
		end

end
