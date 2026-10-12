note
	description: "[
		Base class for PDF fonts.
		Per ISO 32000-1:2008 §9.5, fonts are specified by font dictionaries.
		This deferred class provides common structure for all font types.
	]"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	PDF_FONT

inherit
	PDF_OBJECT

feature -- Access

	base_font: detachable STRING_8
			-- The PostScript name of the font (BaseFont entry).
			-- Required for all font types per ISO 32000-1:2008 §9.6.

	encoding: detachable PDF_OBJECT
			-- Encoding dictionary or name.
			-- Per ISO 32000-1:2008 §9.6.1.

	first_char: INTEGER
			-- First character code in the Widths array.

	last_char: INTEGER
			-- Last character code in the Widths array.

	widths: detachable PDF_ARRAY
			-- Character widths for codes FirstChar to LastChar.

	to_unicode: detachable PDF_STREAM
			-- ToUnicode CMap stream for text extraction.
			-- Per ISO 32000-1:2008 §9.10.3.

	dictionary: PDF_DICTIONARY
			-- The underlying font dictionary.

feature -- Font Type

	font_subtype: STRING_8
			-- PDF font subtype: "Type1", "TrueType", "Type0", etc.
		deferred
		ensure
			result_not_empty: not Result.is_empty
		end

	is_embedded: BOOLEAN
			-- Does this font have an embedded font program?
		do
			Result := False
		end

	is_valid: BOOLEAN
			-- Is this font valid per ISO 32000-1:2008?
			-- Checks: BaseFont present, FirstChar <= LastChar (if widths present).
		do
			Result := attached base_font as bf and then not bf.is_empty
			if Result and attached widths then
				Result := first_char <= last_char
			end
		end

feature -- Element Change

	set_base_font (a_name: STRING_8)
			-- Set the BaseFont name.
		require
			name_not_empty: not a_name.is_empty
		do
			base_font := a_name
		ensure
			base_font_set: base_font = a_name
		end

	set_encoding (a_encoding: PDF_OBJECT)
			-- Set encoding (name or dictionary).
		do
			encoding := a_encoding
		ensure
			encoding_set: encoding = a_encoding
		end

	set_widths (a_first, a_last: INTEGER; a_widths: PDF_ARRAY)
			-- Set character widths.
		require
			valid_range: a_first <= a_last
			widths_match: a_widths.count = a_last - a_first + 1
		do
			first_char := a_first
			last_char := a_last
			widths := a_widths
		ensure
			first_set: first_char = a_first
			last_set: last_char = a_last
			widths_set: widths = a_widths
		end

	set_to_unicode (a_cmap: PDF_STREAM)
			-- Set ToUnicode CMap stream.
		do
			to_unicode := a_cmap
		ensure
			to_unicode_set: to_unicode = a_cmap
		end

	set_dictionary (a_dict: PDF_DICTIONARY)
			-- Set the underlying font dictionary.
		require
			dict_not_void: a_dict /= Void
		do
			dictionary := a_dict
		ensure
			dictionary_set: dictionary = a_dict
		end

feature -- Visitor

	accept (a_visitor: PDF_VISITOR)
			-- Accept visitor for font object.
		do
			a_visitor.visit_dictionary (dictionary)
		end

feature -- Conversion

	to_pdf_string: STRING_8
			-- Convert to PDF representation.
		local
			serializer: PDF_SERIALIZER
		do
			create serializer.make
			dictionary.accept (serializer)
			Result := serializer.last_output
		end

feature {NONE} -- Implementation

	initialize_from_dictionary (a_dict: PDF_DICTIONARY)
			-- Initialize font from dictionary.
		require
			dict_not_void: a_dict /= Void
		do
			dictionary := a_dict

			-- Extract BaseFont
			if attached {PDF_NAME} a_dict.item ("BaseFont") as bf then
				base_font := bf.value
			end

			-- Extract Encoding
			encoding := a_dict.item ("Encoding")

			-- Extract FirstChar/LastChar/Widths
			if attached {PDF_NUMBER} a_dict.item ("FirstChar") as fc then
				first_char := fc.int_value
			end
			if attached {PDF_NUMBER} a_dict.item ("LastChar") as lc then
				last_char := lc.int_value
			end
			if attached {PDF_ARRAY} a_dict.item ("Widths") as w then
				widths := w
			end

			-- Extract ToUnicode
			if attached {PDF_STREAM} a_dict.item ("ToUnicode") as tu then
				to_unicode := tu
			end
		end

invariant
	dictionary_attached: dictionary /= Void

end
