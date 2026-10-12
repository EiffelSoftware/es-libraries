note
	description: "[
		UTF-16BE (Big-Endian) encoding implementation for PDF text strings.
		
		Per ISO 32000-1:2008 §7.9.2.2, UTF-16BE encoded text strings are identified
		by a byte order marker (BOM) at the start: 0xFE 0xFF.
		
		This implementation leverages UTF_CONVERTER from EiffelBase for the core
		UTF-16 conversion, then swaps bytes to convert between little-endian
		(native EiffelBase format) and big-endian (PDF format).
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_UTF16BE_ENCODING

inherit
	PDF_TEXT_ENCODING

feature -- Encoding

	encode_text (text: READABLE_STRING_GENERAL): STRING_8
			-- Encode `text' to UTF-16BE byte sequence with BOM.
		local
			converter: UTF_CONVERTER
			utf16le: STRING_8
		do
				-- Convert to UTF-16LE using EiffelBase
			utf16le := converter.utf_32_string_to_utf_16le_string_8 (text)
			
				-- Prepend BOM and swap bytes to get big-endian
			create Result.make (utf16le.count + 2)
			Result.append (Bom_utf16be)
			Result.append (swap_byte_pairs (utf16le))
		ensure then
			has_bom: Result.count >= 2 and then 
				Result.code (1) = 0xFE and Result.code (2) = 0xFF
		end

feature -- Decoding

	decode_bytes (bytes: STRING_8): STRING_32
			-- Decode UTF-16BE bytes to Unicode STRING_32.
		local
			converter: UTF_CONVERTER
			utf16le: STRING_8
			start_pos: INTEGER
		do
				-- Check for and skip BOM
			if has_utf16be_bom (bytes) then
				start_pos := 3
			else
				start_pos := 1
			end
			
				-- Swap bytes to convert BE → LE
			utf16le := swap_byte_pairs (bytes.substring (start_pos, bytes.count))
			
				-- Convert UTF-16LE to STRING_32
			Result := converter.utf_16le_string_8_to_string_32 (utf16le)
		end

feature -- Status

	can_encode (text: READABLE_STRING_GENERAL): BOOLEAN
			-- Can all characters in `text' be encoded in UTF-16BE?
			-- UTF-16 can encode all Unicode code points.
		do
			Result := True
		end

	encoding_name: STRING_8
			-- Name of this encoding.
		do
			Result := "UTF-16BE"
		end

feature -- BOM Detection

	has_utf16be_bom (bytes: STRING_8): BOOLEAN
			-- Does `bytes' start with UTF-16BE BOM (0xFE 0xFF)?
		do
			Result := bytes.count >= 2 and then
				bytes.code (1) = 0xFE and bytes.code (2) = 0xFF
		end

	Bom_utf16be: STRING_8
			-- UTF-16BE Byte Order Mark.
		once
			create Result.make (2)
			Result.extend ('%/0xFE/')
			Result.extend ('%/0xFF/')
		ensure
			class
			correct_length: Result.count = 2
			correct_bytes: Result.code (1) = 0xFE and Result.code (2) = 0xFF
		end

feature {NONE} -- Implementation

	swap_byte_pairs (s: STRING_8): STRING_8
			-- Swap each pair of bytes to convert between LE and BE.
			-- Example: "AB CD" becomes "BA DC"
		require
			even_length: (s.count \\ 2) = 0
		local
			i: INTEGER
		do
			create Result.make (s.count)
			from
				i := 1
			until
				i > s.count
			loop
					-- Swap bytes: put high byte first (BE order)
				Result.extend (s [i + 1])
				Result.extend (s [i])
				i := i + 2
			end
		ensure
			same_length: Result.count = s.count
		end

end
