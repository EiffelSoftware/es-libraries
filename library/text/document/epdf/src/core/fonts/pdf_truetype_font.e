note
	description: "[
		TrueType font representation.
		Per ISO 32000-1:2008 §9.6.3, TrueType fonts use the Microsoft TrueType format.
		These are the most common fonts in modern PDFs.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_TRUETYPE_FONT

inherit
	PDF_FONT
		redefine
			is_embedded
		end

create
	make,
	make_from_dictionary

feature -- Initialization

	make (a_base_font: STRING_8)
			-- Create TrueType font with given base font name.
		require
			name_not_empty: not a_base_font.is_empty
		do
			create dictionary.make_empty
			dictionary.put_name ("Font", "Type")
			dictionary.put_name ("TrueType", "Subtype")
			dictionary.put_name (a_base_font, "BaseFont")
			base_font := a_base_font
		ensure
			base_font_set: base_font ~ a_base_font
		end

	make_from_dictionary (a_dict: PDF_DICTIONARY)
			-- Create TrueType font from existing dictionary.
		require
			dict_not_void: a_dict /= Void
			is_truetype: attached {PDF_NAME} a_dict.item ("Subtype") as st implies st.value ~ "TrueType"
		do
			initialize_from_dictionary (a_dict)
			
			-- Extract FontDescriptor reference
			if attached {PDF_REFERENCE} a_dict.item ("FontDescriptor") as fd_ref then
				font_descriptor_ref := fd_ref
			elseif attached {PDF_DICTIONARY} a_dict.item ("FontDescriptor") as fd_dict then
				create font_descriptor.make_from_dictionary (fd_dict)
			end
		end

feature -- Access

	font_descriptor: detachable PDF_FONT_DESCRIPTOR
			-- Font descriptor with metrics and embedded font program.
			-- Per ISO 32000-1:2008 §9.8.

	font_descriptor_ref: detachable PDF_REFERENCE
			-- Reference to font descriptor (for lazy loading).

feature -- Font Type

	font_subtype: STRING_8
			-- Font subtype.
		do
			Result := "TrueType"
		end

	is_embedded: BOOLEAN
			-- Does this font have an embedded font program?
		do
			Result := attached font_descriptor as fd and then fd.has_font_file
		end

	is_subset: BOOLEAN
			-- Is this a subset font (BaseFont starts with 6 uppercase letters + '+')?
			-- Per ISO 32000-1:2008, subset prefix must be exactly 6 uppercase letters A-Z.
		local
			prefix: STRING_8
			i: INTEGER
			c: CHARACTER
		do
			if attached base_font as bf and then bf.count > 7 and then bf.item (7) = '+' then
				prefix := bf.substring (1, 6)
				Result := True
				from i := 1 until i > 6 or not Result loop
					c := prefix.item (i)
					-- Must be uppercase letter A-Z (codes 65-90)
					Result := c >= 'A' and c <= 'Z'
					i := i + 1
				end
			end
		end

	subset_prefix: detachable STRING_8
			-- The 6-letter subset prefix (e.g., "ABCDEF") if this is a subset font.
		do
			if is_subset and then attached base_font as bf then
				Result := bf.substring (1, 6)
			end
		end

	actual_font_name: STRING_8
			-- The actual font name without subset prefix.
		do
			if is_subset and then attached base_font as bf then
				Result := bf.substring (8, bf.count)
			elseif attached base_font as bf then
				Result := bf
			else
				Result := ""
			end
		end

feature -- Element Change

	set_font_descriptor (a_descriptor: PDF_FONT_DESCRIPTOR)
			-- Set font descriptor.
		do
			font_descriptor := a_descriptor
		ensure
			descriptor_set: font_descriptor = a_descriptor
		end

	set_font_descriptor_ref (a_ref: PDF_REFERENCE)
			-- Set reference to font descriptor.
		do
			font_descriptor_ref := a_ref
		ensure
			ref_set: font_descriptor_ref = a_ref
		end

end
