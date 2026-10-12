note
	description: "[
		Font descriptor containing font metrics and embedded font program reference.
		Per ISO 32000-1:2008 §9.8, FontDescriptor provides detailed font metrics.
		Required for embedded fonts and highly recommended for all fonts.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_FONT_DESCRIPTOR

inherit
	PDF_OBJECT

create
	make,
	make_from_dictionary

feature -- Initialization

	make (a_font_name: STRING_8)
			-- Create font descriptor for given font.
		require
			name_not_empty: not a_font_name.is_empty
		do
			create dictionary.make_empty
			dictionary.put_name ("FontDescriptor", "Type")
			dictionary.put_name (a_font_name, "FontName")
			font_name := a_font_name
		ensure
			font_name_set: font_name ~ a_font_name
		end

	make_from_dictionary (a_dict: PDF_DICTIONARY)
			-- Create font descriptor from existing dictionary.
		require
			dict_not_void: a_dict /= Void
		do
			dictionary := a_dict

			-- Extract FontName
			if attached {PDF_NAME} a_dict.item ("FontName") as fn then
				font_name := fn.value
			else
				font_name := ""
			end

			-- Extract metrics
			if attached {PDF_NUMBER} a_dict.item ("Flags") as f then
				flags := f.int_value
				has_flags := True
			end
			if attached {PDF_NUMBER} a_dict.item ("Ascent") as a then
				ascent := a.real_value
				has_ascent := True
			end
			if attached {PDF_NUMBER} a_dict.item ("Descent") as d then
				descent := d.real_value
				has_descent := True
			end
			if attached {PDF_NUMBER} a_dict.item ("CapHeight") as ch then
				cap_height := ch.real_value
				has_cap_height := True
			end
			if attached {PDF_NUMBER} a_dict.item ("ItalicAngle") as ia then
				italic_angle := ia.real_value
				has_italic_angle := True
			end
			if attached {PDF_ARRAY} a_dict.item ("FontBBox") as bb then
				font_bbox := bb
			end
			if attached {PDF_NUMBER} a_dict.item ("StemV") as sv then
				stem_v := sv.real_value
				has_stem_v := True
			end

			-- Extract font file references
			font_file := a_dict.item ("FontFile")     -- Type 1
			font_file2 := a_dict.item ("FontFile2")   -- TrueType
			font_file3 := a_dict.item ("FontFile3")   -- CFF/OpenType
		end

feature -- Access

	dictionary: PDF_DICTIONARY
			-- The underlying font descriptor dictionary.

	font_name: STRING_8
			-- PostScript name of the font.

	flags: INTEGER
			-- Font flags (see Table 123 in ISO 32000-1:2008).
	has_flags: BOOLEAN

	ascent: REAL_64
			-- Maximum height above baseline.
	has_ascent: BOOLEAN

	descent: REAL_64
			-- Maximum depth below baseline (typically negative).
	has_descent: BOOLEAN

	cap_height: REAL_64
			-- Height of capital letters.
	has_cap_height: BOOLEAN

	italic_angle: REAL_64
			-- Italic angle in degrees.
	has_italic_angle: BOOLEAN

	font_bbox: detachable PDF_ARRAY
			-- Bounding box for all glyphs [llx lly urx ury].

	stem_v: REAL_64
			-- Width of vertical stems.
	has_stem_v: BOOLEAN

	font_file: detachable PDF_OBJECT
			-- Type 1 font program (stream or reference).

	font_file2: detachable PDF_OBJECT
			-- TrueType font program (stream or reference).

	font_file3: detachable PDF_OBJECT
			-- CFF/OpenType font program (stream or reference).

feature -- Query

	has_font_file: BOOLEAN
			-- Does this descriptor have an embedded font program?
		do
			Result := font_file /= Void or else font_file2 /= Void or else font_file3 /= Void
		end

	is_fixed_pitch: BOOLEAN
			-- Is this a fixed-pitch (monospace) font?
		do
			Result := (flags & 1) /= 0
		end

	is_serif: BOOLEAN
			-- Is this a serif font?
		do
			Result := (flags & 2) /= 0
		end

	is_symbolic: BOOLEAN
			-- Is this a symbolic font (non-standard encoding)?
		do
			Result := (flags & 4) /= 0
		end

	is_italic: BOOLEAN
			-- Is this an italic font?
		do
			Result := (flags & 64) /= 0
		end

feature -- Element Change

	set_ascent (a_value: REAL_64)
		do
			ascent := a_value
			has_ascent := True
			dictionary.put_real (a_value, "Ascent")
		end

	set_descent (a_value: REAL_64)
		do
			descent := a_value
			has_descent := True
			dictionary.put_real (a_value, "Descent")
		end

	set_cap_height (a_value: REAL_64)
		do
			cap_height := a_value
			has_cap_height := True
			dictionary.put_real (a_value, "CapHeight")
		end

	set_flags (a_value: INTEGER)
		do
			flags := a_value
			has_flags := True
			dictionary.put_number (a_value, "Flags")
		end

	set_font_file2 (a_stream: PDF_OBJECT)
			-- Set TrueType font program.
		do
			font_file2 := a_stream
			dictionary.put (a_stream, "FontFile2")
		end

feature -- Visitor

	accept (a_visitor: PDF_VISITOR)
		do
			a_visitor.visit_dictionary (dictionary)
		end

feature -- Conversion

	to_pdf_string: STRING_8
		local
			serializer: PDF_SERIALIZER
		do
			create serializer.make
			dictionary.accept (serializer)
			Result := serializer.last_output
		end

end
