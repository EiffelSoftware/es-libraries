note
	description: "Minimal PDF writer capable of generating simple PDF documents with text content."
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_WRITER

create
	make

feature -- Initialization

	make
			-- Initialize the PDF writer.
		do
			create objects.make (10)
			next_object_number := 1
			create serializer.make
		ensure
			next_object_valid: next_object_number = 1
		end

feature -- Access

	objects: ARRAYED_LIST [PDF_INDIRECT_OBJECT]
			-- List of indirect objects in the PDF

	next_object_number: INTEGER
			-- Next available object number

	serializer: PDF_SERIALIZER
			-- Object serializer

feature -- Building

	add_object (an_object: PDF_OBJECT): PDF_OBJECT_ID
			-- Add an object to the PDF and return its ID.
		local
			obj_id: PDF_OBJECT_ID
			indirect: PDF_INDIRECT_OBJECT
		do
			create obj_id.make (next_object_number, 0)
			create indirect.make (obj_id, an_object)
			objects.extend (indirect)
			next_object_number := next_object_number + 1
			Result := obj_id
		ensure
			object_number_incremented: next_object_number = old next_object_number + 1
			object_added: objects.count = old objects.count + 1
		end

	create_hello_world_pdf: STRING_8
			-- Create a minimal "Hello World" PDF document.
			-- Per ISO 32000-1:2008, PDF output is 7-bit ASCII + binary data.
			-- Uses explicit CRLF line breaks to keep byte offsets stable across platforms.
		local
			catalog_id, pages_id, page_id, font_id, content_id: PDF_OBJECT_ID
			catalog, pages, page, font, resources: PDF_DICTIONARY
			content_stream: PDF_STREAM
			kids_array: PDF_ARRAY
			media_box: PDF_ARRAY
			proc_set: PDF_ARRAY
			font_dict: PDF_DICTIONARY
			content_text: STRING_8
		do
				-- Create content stream with "Hello World" text
				-- Per ISO 32000-1:2008 §7.8.2, content streams contain graphics operators
			create content_text.make (80)
			content_text.append ("BT")
			content_text.append (newline)
			content_text.append ("/F1 24 Tf")
			content_text.append (newline)
			content_text.append ("100 700 Td")
			content_text.append (newline)
			content_text.append ("(Hello World!) Tj")
			content_text.append (newline)
			content_text.append ("ET")
			create content_stream.make (content_text)
			content_id := add_object (content_stream)

				-- Create font dictionary (Helvetica - standard Type1 font)
			create font.make (3)
			font.put_name ("Font", "Type")
			font.put_name ("Type1", "Subtype")
			font.put_name ("Helvetica", "BaseFont")
			font_id := add_object (font)

				-- Create resources dictionary
			create font_dict.make (1)
			font_dict.put (create_object_reference (font_id), "F1")

			create proc_set.make (1)
			proc_set.add_name ("PDF")
			proc_set.add_name ("Text")

			create resources.make (2)
			resources.put (font_dict, "Font")
			resources.put (proc_set, "ProcSet")

				-- Create page object
			create media_box.make (4)
			media_box.add_number (0)
			media_box.add_number (0)
			media_box.add_number (612)
			media_box.add_number (792)

			create page.make (5)
			page.put_name ("Page", "Type")
			page.put_name ("placeholder", "Parent")  -- Will be updated after pages created
			page.put (media_box, "MediaBox")
			page.put (create_object_reference (content_id), "Contents")
			page.put (resources, "Resources")
			page_id := add_object (page)

				-- Update parent reference in page
			if attached {PDF_DICTIONARY} objects [page_id.object_number].value as pg then
				-- We'll set this to pages_id after creating it
			end

				-- Create pages object
			create kids_array.make (1)
			kids_array.add (create_object_reference (page_id))

			create pages.make (3)
			pages.put_name ("Pages", "Type")
			pages.put (kids_array, "Kids")
			pages.put_number (1, "Count")
			pages_id := add_object (pages)

				-- Update parent reference in page to point to pages
			if attached {PDF_DICTIONARY} objects [page_id.object_number].value as pg then
				pg.put (create_object_reference (pages_id), "Parent")
			end

				-- Create catalog
			create catalog.make (2)
			catalog.put_name ("Catalog", "Type")
			catalog.put (create_object_reference (pages_id), "Pages")
			catalog_id := add_object (catalog)

				-- Generate the complete PDF
			Result := generate_pdf_output (catalog_id)
		ensure
			result_not_empty: not Result.is_empty
			has_pdf_header: Result.starts_with ("%%PDF-")
		end

feature {NONE} -- Implementation

	create_object_reference (obj_id: PDF_OBJECT_ID): PDF_REFERENCE
			-- Create an indirect reference to the object with given ID.
			-- Per ISO 32000-1:2008 §7.3.10, indirect references are "obj_num gen_num R"
		do
			create Result.make (obj_id)
		end

	generate_pdf_output (catalog_id: PDF_OBJECT_ID): STRING_8
			-- Generate the complete PDF file content.
			-- Per ISO 32000-1:2008, PDF file format is 7-bit ASCII + binary data.
		local
			xref_offsets: ARRAY [INTEGER]
			xref_offset: INTEGER
			i: INTEGER
		do
			create Result.make (4096)

				-- PDF header
			Result.append ("%%PDF-1.7")
			Result.append (newline)
				-- Binary comment (4 bytes > 127 to indicate binary file per ISO 32000-1 Section 7.5.2)
				-- Using bytes: 0xE4 (228), 0xF0 (240), 0xD3 (211), 0xFA (250)
			Result.append ("%%%/228/%/240/%/211/%/250/")
			Result.append (newline)

				-- Create xref table
			create xref_offsets.make_filled (0, 1, objects.count)

				-- Write objects and record offsets
			from
				i := 1
			until
				i > objects.count
			loop
				xref_offsets [i] := Result.count
				serializer.reset
				objects [i].accept (serializer)
				Result.append (serializer.last_output)
				Result.append (newline)
				i := i + 1
			end

				-- Record xref table offset
			xref_offset := Result.count

				-- Write xref table
			Result.append ("xref")
			Result.append (newline)
			Result.append ("0 ")
			Result.append ((objects.count + 1).out)
			Result.append (newline)
			Result.append ("0000000000 65535 f")
			Result.append (newline)

			from
				i := 1
			until
				i > objects.count
			loop
				Result.append (format_offset (xref_offsets [i]))
				Result.append (" 00000 n")
				Result.append (newline)
				i := i + 1
			end

				-- Write trailer
			Result.append ("trailer")
			Result.append (newline)
			Result.append ("<<")
			Result.append (newline)
			Result.append ("/Size ")
			Result.append ((objects.count + 1).out)
			Result.append (newline)
			Result.append ("/Root ")
			Result.append (catalog_id.to_reference_string)
			Result.append (newline)
			Result.append (">>")
			Result.append (newline)
			Result.append ("startxref")
			Result.append (newline)
			Result.append (xref_offset.out)
			Result.append (newline)
			Result.append ("%%EOF")
			Result.append (newline)
		ensure
			result_not_empty: not Result.is_empty
		end

	format_offset (offset: INTEGER): STRING_8
			-- Format offset as 10-digit zero-padded string.
			-- Per ISO 32000-1:2008 §7.5.4, xref offsets are 10-digit ASCII.
		require
			valid_offset: offset >= 0
		local
			s: STRING_8
			padding_needed: INTEGER
		do
			s := offset.out
			padding_needed := 10 - s.count
			create Result.make (10)
			from
			until
				padding_needed <= 0
			loop
				Result.append_character ('0')
				padding_needed := padding_needed - 1
			end
			Result.append (s)
		ensure
			correct_length: Result.count = 10
		end

feature {NONE} -- Constants

	newline: STRING_8 = "%R%N"
			-- Canonical CRLF line break for stable byte offsets across platforms.

invariant
	valid_object_number: next_object_number >= 1

end
