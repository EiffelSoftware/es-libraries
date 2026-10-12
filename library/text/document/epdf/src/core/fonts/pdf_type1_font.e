note
	description: "[
		Type 1 font representation.
		Per ISO 32000-1:2008 §9.6.2, Type 1 fonts are the original Adobe font format.
		Includes standard 14 built-in fonts (Helvetica, Times-Roman, Courier, etc.).
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_TYPE1_FONT

inherit
	PDF_FONT
		redefine
			is_embedded
		end

create
	make,
	make_from_dictionary,
	make_standard

feature -- Initialization

	make (a_base_font: STRING_8)
			-- Create Type 1 font with given base font name.
		require
			name_not_empty: not a_base_font.is_empty
		do
			create dictionary.make_empty
			dictionary.put_name ("Font", "Type")
			dictionary.put_name ("Type1", "Subtype")
			dictionary.put_name (a_base_font, "BaseFont")
			base_font := a_base_font
		ensure
			base_font_set: base_font ~ a_base_font
		end

	make_from_dictionary (a_dict: PDF_DICTIONARY)
			-- Create Type 1 font from existing dictionary.
		require
			dict_not_void: a_dict /= Void
			is_type1: attached {PDF_NAME} a_dict.item ("Subtype") as st implies st.value ~ "Type1"
		do
			initialize_from_dictionary (a_dict)
		end

	make_standard (a_font_name: STRING_8)
			-- Create standard Type 1 font (one of the 14 built-in fonts).
		require
			valid_standard_font: is_standard_font (a_font_name)
		do
			make (a_font_name)
			is_standard := True
		ensure
			is_standard_font: is_standard
		end

feature -- Access

	font_descriptor: detachable PDF_FONT_DESCRIPTOR
			-- Font descriptor (optional for standard fonts).

	is_standard: BOOLEAN
			-- Is this one of the 14 standard Type 1 fonts?

feature -- Font Type

	font_subtype: STRING_8
			-- Font subtype.
		do
			Result := "Type1"
		end

	is_embedded: BOOLEAN
			-- Type 1 fonts can have embedded font programs.
		do
			Result := attached font_descriptor as fd and then fd.has_font_file
		end

feature -- Element Change

	set_font_descriptor (a_descriptor: PDF_FONT_DESCRIPTOR)
			-- Set font descriptor.
		do
			font_descriptor := a_descriptor
		ensure
			descriptor_set: font_descriptor = a_descriptor
		end

feature -- Query

	is_standard_font (a_name: STRING_8): BOOLEAN
			-- Is this a standard Type 1 font name?
		do
			Result := a_name ~ "Courier" or else
				a_name ~ "Courier-Bold" or else
				a_name ~ "Courier-Oblique" or else
				a_name ~ "Courier-BoldOblique" or else
				a_name ~ "Helvetica" or else
				a_name ~ "Helvetica-Bold" or else
				a_name ~ "Helvetica-Oblique" or else
				a_name ~ "Helvetica-BoldOblique" or else
				a_name ~ "Times-Roman" or else
				a_name ~ "Times-Bold" or else
				a_name ~ "Times-Italic" or else
				a_name ~ "Times-BoldItalic" or else
				a_name ~ "Symbol" or else
				a_name ~ "ZapfDingbats"
		end

end
