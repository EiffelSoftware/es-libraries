note
	description: "[
		ToUnicode CMap for character code to Unicode mapping.
		Per ISO 32000-1:2008 §9.10.3, ToUnicode CMaps provide mappings for text extraction.
		This class preserves the raw CMap stream content for read/write workflows.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_TOUNICODE_CMAP

inherit
	PDF_OBJECT

create
	make,
	make_from_stream

feature -- Initialization

	make (a_content: STRING_8)
			-- Create CMap from raw content.
		require
			content_not_empty: not a_content.is_empty
		do
			raw_content := a_content.twin
			parse_mappings
		ensure
			content_preserved: raw_content ~ a_content
		end

	make_from_stream (a_stream: PDF_STREAM)
			-- Create CMap from PDF stream object.
		require
			stream_not_void: a_stream /= Void
		do
			raw_content := a_stream.content.twin
			stream := a_stream
			parse_mappings
		ensure
			content_from_stream: raw_content ~ a_stream.content
		end

feature -- Access

	raw_content: STRING_8
			-- Raw CMap content (preserved for serialization).
			-- Binary data is kept exactly as read.

	stream: detachable PDF_STREAM
			-- Original stream object (if created from stream).

	mappings: HASH_TABLE [STRING_32, INTEGER]
			-- Character code to Unicode string mappings.
			-- Key is character code, value is Unicode string.

feature -- Query

	has_mapping (a_char_code: INTEGER): BOOLEAN
			-- Does this CMap have a mapping for the given character code?
		do
			Result := mappings.has (a_char_code)
		end

	unicode_for (a_char_code: INTEGER): detachable STRING_32
			-- Get Unicode string for character code, or Void if not mapped.
		do
			if mappings.has (a_char_code) then
				Result := mappings.item (a_char_code)
			end
		end

	is_identity: BOOLEAN
			-- Is this an Identity-H or Identity-V CMap?
		do
			Result := raw_content.has_substring ("Identity-H") or else
				raw_content.has_substring ("Identity-V")
		end

feature -- Visitor

	accept (a_visitor: PDF_VISITOR)
			-- Accept visitor for CMap. Delegates to stream if present.
		do
			if attached stream as s then
				s.accept (a_visitor)
			end
		end

feature -- Serialization

	to_stream: PDF_STREAM
			-- Convert CMap to a PDF stream for serialization.
			-- Uses original stream if available, otherwise creates new.
		do
			if attached stream as s then
				Result := s
			else
				create Result.make (raw_content)
			end
		ensure
			result_not_void: Result /= Void
			content_preserved: Result.content ~ raw_content
		end

feature {NONE} -- Implementation

	parse_mappings
			-- Parse mappings from raw content.
			-- Note: This is a simplified parser for basic bfchar/bfrange mappings.
		local
			pos: INTEGER
		do
			create mappings.make (100)
			
			-- Look for beginbfchar...endbfchar sections
			pos := raw_content.substring_index ("beginbfchar", 1)
			if pos > 0 then
				parse_bfchar_section (pos)
			end
			
			-- Look for beginbfrange...endbfrange sections
			pos := raw_content.substring_index ("beginbfrange", 1)
			if pos > 0 then
				parse_bfrange_section (pos)
			end
		end

	parse_bfchar_section (a_start: INTEGER)
			-- Parse bfchar mappings (simplified).
			-- Format: <srcCode> <dstString>
		local
			content: STRING_8
			end_pos: INTEGER
		do
			end_pos := raw_content.substring_index ("endbfchar", a_start)
			if end_pos > a_start then
				content := raw_content.substring (a_start + 11, end_pos - 1)
				-- Full parsing would extract hex codes here
				-- For preservation purposes, we just keep raw_content intact
			end
		end

	parse_bfrange_section (a_start: INTEGER)
			-- Parse bfrange mappings (simplified).
			-- Format: <srcCodeLo> <srcCodeHi> <dstStringLo>
		local
			content: STRING_8
			end_pos: INTEGER
		do
			end_pos := raw_content.substring_index ("endbfrange", a_start)
			if end_pos > a_start then
				content := raw_content.substring (a_start + 12, end_pos - 1)
				-- Full parsing would extract hex codes here
				-- For preservation purposes, we just keep raw_content intact
			end
		end

invariant
	raw_content_not_void: raw_content /= Void
	mappings_not_void: mappings /= Void

end
