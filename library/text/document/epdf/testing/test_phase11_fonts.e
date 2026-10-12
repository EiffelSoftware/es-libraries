note
	description: "[
		Unit tests for Phase 11 TrueType Font Preservation classes.
		Tests PDF_TYPE1_FONT, PDF_TRUETYPE_FONT, and PDF_FONT_DESCRIPTOR.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_PHASE11_FONTS

inherit
	EQA_TEST_SET

feature -- Test: Type 1 Fonts

	test_type1_font_creation
			-- Test creating a Type 1 font.
		local
			font: PDF_TYPE1_FONT
		do
			create font.make ("Helvetica")
			assert ("base_font set", attached font.base_font as bf and then bf ~ "Helvetica")
			assert ("subtype is Type1", font.font_subtype ~ "Type1")
			assert ("not embedded", not font.is_embedded)
		end

	test_type1_standard_fonts
			-- Test standard 14 Type 1 fonts.
		local
			font: PDF_TYPE1_FONT
		do
			create font.make_standard ("Helvetica")
			assert ("is standard", font.is_standard)
			assert ("is standard font name", font.is_standard_font ("Courier"))
			assert ("is standard font name 2", font.is_standard_font ("Times-Roman"))
			assert ("not standard font", not font.is_standard_font ("Arial"))
		end

	test_type1_from_dictionary
			-- Test creating Type 1 font from dictionary.
		local
			font: PDF_TYPE1_FONT
			dict: PDF_DICTIONARY
		do
			create dict.make_empty
			dict.put_name ("Font", "Type")
			dict.put_name ("Type1", "Subtype")
			dict.put_name ("Courier-Bold", "BaseFont")
			dict.put_number (32, "FirstChar")
			dict.put_number (126, "LastChar")
			
			create font.make_from_dictionary (dict)
			assert ("base_font extracted", attached font.base_font as bf and then bf ~ "Courier-Bold")
			assert ("first_char extracted", font.first_char = 32)
			assert ("last_char extracted", font.last_char = 126)
		end

feature -- Test: TrueType Fonts

	test_truetype_font_creation
			-- Test creating a TrueType font.
		local
			font: PDF_TRUETYPE_FONT
		do
			create font.make ("ArialMT")
			assert ("base_font set", attached font.base_font as bf and then bf ~ "ArialMT")
			assert ("subtype is TrueType", font.font_subtype ~ "TrueType")
			assert ("not subset", not font.is_subset)
		end

	test_truetype_subset_font
			-- Test TrueType subset font detection.
		local
			font: PDF_TRUETYPE_FONT
			dict: PDF_DICTIONARY
		do
			create dict.make_empty
			dict.put_name ("Font", "Type")
			dict.put_name ("TrueType", "Subtype")
			dict.put_name ("ABCDEF+ArialMT", "BaseFont")
			
			create font.make_from_dictionary (dict)
			assert ("is subset", font.is_subset)
			assert ("subset prefix", attached font.subset_prefix as sp and then sp ~ "ABCDEF")
			assert ("actual name", font.actual_font_name ~ "ArialMT")
		end

	test_truetype_from_dictionary
			-- Test creating TrueType font from dictionary.
		local
			font: PDF_TRUETYPE_FONT
			dict: PDF_DICTIONARY
		do
			create dict.make_empty
			dict.put_name ("Font", "Type")
			dict.put_name ("TrueType", "Subtype")
			dict.put_name ("TimesNewRomanPSMT", "BaseFont")
			dict.put_number (32, "FirstChar")
			dict.put_number (255, "LastChar")
			
			create font.make_from_dictionary (dict)
			assert ("base_font extracted", attached font.base_font as bf and then bf ~ "TimesNewRomanPSMT")
			assert ("first_char extracted", font.first_char = 32)
			assert ("last_char extracted", font.last_char = 255)
		end

feature -- Test: Font Descriptor

	test_font_descriptor_creation
			-- Test creating a font descriptor.
		local
			desc: PDF_FONT_DESCRIPTOR
		do
			create desc.make ("ArialMT")
			assert ("font_name set", desc.font_name ~ "ArialMT")
			assert ("no font file", not desc.has_font_file)
		end

	test_font_descriptor_metrics
			-- Test font descriptor metrics.
		local
			desc: PDF_FONT_DESCRIPTOR
		do
			create desc.make ("ArialMT")
			desc.set_ascent (905.0)
			desc.set_descent (-212.0)
			desc.set_cap_height (716.0)
			desc.set_flags (32)
			
			assert ("ascent set", desc.has_ascent and then desc.ascent = 905.0)
			assert ("descent set", desc.has_descent and then desc.descent = -212.0)
			assert ("cap_height set", desc.has_cap_height and then desc.cap_height = 716.0)
			assert ("flags set", desc.has_flags and then desc.flags = 32)
		end

	test_font_descriptor_from_dictionary
			-- Test creating font descriptor from dictionary.
		local
			desc: PDF_FONT_DESCRIPTOR
			dict: PDF_DICTIONARY
		do
			create dict.make_empty
			dict.put_name ("FontDescriptor", "Type")
			dict.put_name ("ArialMT", "FontName")
			dict.put_number (905, "Ascent")
			dict.put_number (-212, "Descent")
			dict.put_number (716, "CapHeight")
			dict.put_number (32, "Flags")
			dict.put_number (0, "ItalicAngle")
			dict.put_number (88, "StemV")
			
			create desc.make_from_dictionary (dict)
			assert ("font_name extracted", desc.font_name ~ "ArialMT")
			assert ("ascent extracted", desc.has_ascent and then desc.ascent = 905.0)
			assert ("descent extracted", desc.has_descent and then desc.descent = -212.0)
			assert ("flags extracted", desc.has_flags and then desc.flags = 32)
		end

	test_font_descriptor_flags
			-- Test font descriptor flag queries.
		local
			desc: PDF_FONT_DESCRIPTOR
		do
			create desc.make ("Courier")
			
			-- Flags: FixedPitch=1, Serif=2, Symbolic=4, Italic=64
			desc.set_flags (1)
			assert ("fixed pitch", desc.is_fixed_pitch)
			assert ("not serif", not desc.is_serif)
			
			desc.set_flags (2)
			assert ("serif", desc.is_serif)
			assert ("not fixed pitch", not desc.is_fixed_pitch)
			
			desc.set_flags (64)
			assert ("italic", desc.is_italic)
			
			desc.set_flags (4)
			assert ("symbolic", desc.is_symbolic)
		end

feature -- Test: Font with Descriptor

	test_truetype_with_descriptor
			-- Test TrueType font with embedded descriptor.
		local
			font: PDF_TRUETYPE_FONT
			desc: PDF_FONT_DESCRIPTOR
			stream: PDF_STREAM
		do
			create font.make ("ArialMT")
			create desc.make ("ArialMT")
			
			-- Add metrics
			desc.set_ascent (905.0)
			desc.set_descent (-212.0)
			desc.set_flags (32)
			
			-- Simulate embedded font (FontFile2)
			create stream.make ("dummy font data")
			desc.set_font_file2 (stream)
			
			font.set_font_descriptor (desc)
			
			assert ("has descriptor", attached font.font_descriptor)
			assert ("is embedded", font.is_embedded)
		end

feature -- Test: Edge Cases (Subset Prefix Robustness)

	test_subset_prefix_invalid_too_short
			-- Test subset detection rejects prefix shorter than 6 chars.
		local
			font: PDF_TRUETYPE_FONT
			dict: PDF_DICTIONARY
		do
			create dict.make_empty
			dict.put_name ("TrueType", "Subtype")
			dict.put_name ("ABC+Arial", "BaseFont")  -- Only 3 chars before +
			
			create font.make_from_dictionary (dict)
			assert ("not subset (too short)", not font.is_subset)
		end

	test_subset_prefix_invalid_lowercase
			-- Test subset detection rejects lowercase prefixes.
		local
			font: PDF_TRUETYPE_FONT
			dict: PDF_DICTIONARY
		do
			create dict.make_empty
			dict.put_name ("TrueType", "Subtype")
			dict.put_name ("abcdef+Arial", "BaseFont")  -- Lowercase
			
			create font.make_from_dictionary (dict)
			assert ("not subset (lowercase)", not font.is_subset)
		end

	test_subset_prefix_invalid_numbers
			-- Test subset detection rejects numeric prefixes.
		local
			font: PDF_TRUETYPE_FONT
			dict: PDF_DICTIONARY
		do
			create dict.make_empty
			dict.put_name ("TrueType", "Subtype")
			dict.put_name ("123456+Arial", "BaseFont")  -- Numbers
			
			create font.make_from_dictionary (dict)
			assert ("not subset (numbers)", not font.is_subset)
		end

feature -- Test: Edge Cases (Widths Array)

	test_widths_array_extraction
			-- Test extraction of the Widths array from a font dictionary.
		local
			font: PDF_TRUETYPE_FONT
			dict: PDF_DICTIONARY
			widths_arr: PDF_ARRAY
		do
			create dict.make_empty
			create widths_arr.make_empty
			widths_arr.add (create {PDF_NUMBER}.make_integer (500))
			widths_arr.add (create {PDF_NUMBER}.make_integer (250))
			
			dict.put_name ("TrueType", "Subtype")
			dict.put_name ("ArialMT", "BaseFont")
			dict.put_number (32, "FirstChar")
			dict.put_number (33, "LastChar")
			dict.put (widths_arr, "Widths")
			
			create font.make_from_dictionary (dict)
			assert ("widths extracted", attached font.widths as w and then w.count = 2)
			assert ("first_char correct", font.first_char = 32)
			assert ("last_char correct", font.last_char = 33)
		end

feature -- Test: Edge Cases (Missing FontDescriptor)

	test_truetype_missing_descriptor
			-- Test TrueType font with missing FontDescriptor (Void safety).
		local
			font: PDF_TRUETYPE_FONT
			dict: PDF_DICTIONARY
		do
			create dict.make_empty
			dict.put_name ("TrueType", "Subtype")
			dict.put_name ("ArialMT", "BaseFont")
			-- No FontDescriptor
			
			create font.make_from_dictionary (dict)
			assert ("no descriptor", not attached font.font_descriptor)
			assert ("not embedded", not font.is_embedded)
		end

feature -- Test: Edge Cases (Encoding Dictionary)

	test_font_with_encoding_differences
			-- Test /Encoding as dictionary with /Differences array.
		local
			font: PDF_TYPE1_FONT
			dict: PDF_DICTIONARY
			encoding_dict: PDF_DICTIONARY
			differences: PDF_ARRAY
		do
			create dict.make_empty
			dict.put_name ("Type1", "Subtype")
			dict.put_name ("Helvetica", "BaseFont")
			
			-- Create encoding dictionary with Differences
			create encoding_dict.make_empty
			encoding_dict.put_name ("Encoding", "Type")
			encoding_dict.put_name ("WinAnsiEncoding", "BaseEncoding")
			
			create differences.make_empty
			differences.add (create {PDF_NUMBER}.make_integer (33))
			differences.add (create {PDF_NAME}.make ("exclamdown"))
			encoding_dict.put (differences, "Differences")
			
			dict.put (encoding_dict, "Encoding")
			
			create font.make_from_dictionary (dict)
			assert ("encoding is dictionary", attached {PDF_DICTIONARY} font.encoding)
		end

feature -- Test: Edge Cases (ToUnicode CMap)

	test_tounicode_cmap_creation
			-- Test creating ToUnicode CMap from raw content.
		local
			cmap: PDF_TOUNICODE_CMAP
			content: STRING_8
		do
			content := "/CIDInit /ProcSet findresource begin%N12 dict begin%Nbegincmap%N"
			content.append ("/CIDSystemInfo << /Registry (Adobe) /Ordering (UCS) /Supplement 0 >> def%N")
			content.append ("/CMapName /Adobe-Identity-UCS def%N")
			content.append ("1 beginbfchar%N<0041> <0041>%Nendbfchar%N")
			content.append ("endcmap%N")
			
			create cmap.make (content)
			assert ("content preserved", cmap.raw_content ~ content)
		end

	test_tounicode_stream_preservation
			-- Test that ToUnicode stream content is preserved exactly.
		local
			cmap: PDF_TOUNICODE_CMAP
			stream: PDF_STREAM
			output_stream: PDF_STREAM
			original_content: STRING_8
		do
			original_content := "/CIDInit /ProcSet begin%N1 beginbfchar%N<20> <0020>%Nendbfchar%Nendcmap"
			create stream.make (original_content)
			
			create cmap.make_from_stream (stream)
			output_stream := cmap.to_stream
			
			assert ("content byte-for-byte", output_stream.content ~ original_content)
		end

feature -- Test: Edge Cases (Font Validation)

	test_font_is_valid_check
			-- Test font validation (is_valid feature).
		local
			font: PDF_TRUETYPE_FONT
		do
			-- Valid font with BaseFont
			create font.make ("ArialMT")
			assert ("is valid", font.is_valid)
			
			-- Font without proper widths range should still be valid if no widths
			assert ("base_font present", attached font.base_font)
		end

end

