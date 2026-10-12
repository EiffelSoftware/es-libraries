note
	description: "Represents a PDF stream object. Streams contain binary or text data preceded by a dictionary."
	spec_reference: "ISO 32000-1:2008 Section 7.3.8 Stream Objects"
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_STREAM

inherit
	PDF_OBJECT

create
	make,
	make_with_dictionary

feature -- Initialization

	make (a_content: READABLE_STRING_GENERAL)
			-- Create a stream with the given content.
			-- Per ISO 32000-1:2008 §7.3.8, streams are byte sequences.
		do
			content := a_content.to_string_8
			create stream_dictionary.make (1)
			stream_dictionary.put_number (content.count, "Length")
			reset_compression_state
		ensure
			content_set: content.same_string_general (a_content)
			length_set: stream_dictionary.has_key ("Length")
			compression_state_reset: not is_decompressed and original_filter = Void
		end

	make_with_dictionary (a_dictionary: PDF_DICTIONARY; a_content: STRING_8)
			-- Create a stream with existing dictionary and content.
			-- Used when parsing streams from existing PDF files.
		do
			stream_dictionary := a_dictionary
			content := a_content
			reset_compression_state
		ensure
			dictionary_set: stream_dictionary = a_dictionary
			content_set: content = a_content
			compression_state_reset: not is_decompressed and original_filter = Void
		end

feature -- Access

	content: STRING_8
			-- The stream content (raw bytes/text).
			-- Per ISO 32000-1:2008 §7.3.8, stream content is a byte sequence.

	stream_dictionary: PDF_DICTIONARY
			-- The stream dictionary (contains /Length and optional filters)

	is_decompressed: BOOLEAN
			-- Has the stream content been decompressed after loading?
			-- Used to prevent double decompression on write.

	original_filter: detachable STRING_8
			-- Original filter name before decompression (e.g., "FlateDecode").
			-- Used to determine if recompression is needed on write.

	is_compressed: BOOLEAN
			-- Is the current content compressed?
			-- Based on presence of /Filter in dictionary and decompression state.
		do
			Result := stream_dictionary.has_key ("Filter") and not is_decompressed
		end

feature -- Element Change

	set_content (a_content: STRING_8)
			-- Set the stream content directly (used during decryption).
		do
			content := a_content
		ensure
			content_set: content = a_content
		end

	set_filter (a_filter: READABLE_STRING_GENERAL)
			-- Set the stream filter (e.g., "FlateDecode").
			-- Per ISO 32000-1:2008 §7.3.8, filter names are 7-bit ASCII.
		require
			filter_not_empty: not a_filter.is_empty
		do
			stream_dictionary.put_name (a_filter, "Filter")
		ensure
			has_filter: stream_dictionary.has_key ("Filter")
		end

	mark_as_decompressed (a_filter: READABLE_STRING_GENERAL)
			-- Mark stream as decompressed after loading.
			-- Used when stream content was decompressed during parsing.
		require
			filter_not_empty: not a_filter.is_empty
		do
			is_decompressed := True
			original_filter := a_filter.to_string_8
		ensure
			marked_decompressed: is_decompressed
			filter_recorded: attached original_filter as f and then f.same_string_general (a_filter)
		end

	set_decompressed_content (a_content: STRING_8; a_filter: READABLE_STRING_GENERAL)
			-- Set decompressed content and mark compression state.
			-- Called by parsers after decompressing stream content.
			-- Per ISO 32000-1:2008 §7.3.8, stream content is a byte sequence.
		require
			content_valid: a_content /= Void
			filter_valid: not a_filter.is_empty
		do
			content := a_content
			mark_as_decompressed (a_filter)
		ensure
			content_set: content = a_content
			marked: is_decompressed
			filter_recorded: attached original_filter as f and then f.same_string_general (a_filter)
		end

	reset_compression_state
			-- Reset compression state (used for fresh streams).
		do
			is_decompressed := False
			original_filter := Void
		ensure
			state_reset: not is_decompressed and original_filter = Void
		end

feature -- Visitor Pattern

	accept (a_visitor: PDF_VISITOR)
			-- Accept visitor for processing.
		do
			a_visitor.visit_stream (Current)
		end

feature -- Conversion

	to_pdf_string: STRING_8
			-- Convert to PDF format.
			-- Format: << dictionary >> stream ... endstream
			-- Per ISO 32000-1:2008 §7.3.8, streams serialize to byte sequences.
		local
			serializer: PDF_SERIALIZER
		do
			create serializer.make
			serializer.logger := logger
			stream_dictionary.accept (serializer)

			create Result.make (content.count + 50)
			Result.append (serializer.last_output)
			Result.append ("%Nstream%N")
			Result.append (content)
			Result.append ("%Nendstream")
		ensure
			result_not_empty: not Result.is_empty
			has_stream_keyword: Result.has_substring ("stream")
			has_endstream_keyword: Result.has_substring ("endstream")
		end

invariant

end
