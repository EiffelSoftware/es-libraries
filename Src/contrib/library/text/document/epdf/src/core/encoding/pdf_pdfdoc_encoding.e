note
	description: "[
		PDFDocEncoding implementation per ISO 32000-1:2008 Annex D.2.
		
		PDFDocEncoding is a single-byte encoding that is a superset of ISO Latin-1:
		- Bytes 0x00-0x7F: Standard ASCII
		- Bytes 0x80-0x9F: Special PDF characters (bullets, daggers, quotes, etc.)
		- Bytes 0xA0-0xFF: ISO Latin-1 characters
		
		This is the default encoding for text strings in PDF when no BOM is present.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_PDFDOC_ENCODING

inherit
	PDF_TEXT_ENCODING

feature -- Encoding

	encode_text (text: READABLE_STRING_GENERAL): STRING_8
			-- Encode `text' to PDFDocEncoding byte sequence.
		local
			i: INTEGER
			code: NATURAL_32
		do
			create Result.make (text.count)
			from
				i := 1
			until
				i > text.count
			loop
				code := text.code (i)
				if code <= 0x7F then
						-- ASCII range: direct mapping
					Result.extend (code.to_character_8)
				elseif code >= 0xA0 and code <= 0xFF then
						-- Latin-1 supplement: direct mapping
					Result.extend (code.to_character_8)
				else
						-- Try to find in special character mapping
					Result.extend (unicode_to_pdfdoc (code))
				end
				i := i + 1
			end
		end

feature -- Decoding

	decode_bytes (bytes: STRING_8): STRING_32
			-- Decode PDFDocEncoding bytes to Unicode STRING_32.
		local
			i: INTEGER
			byte: NATURAL_8
		do
			create Result.make (bytes.count)
			from
				i := 1
			until
				i > bytes.count
			loop
				byte := bytes.code (i).to_natural_8
				if byte <= 0x7F then
						-- ASCII range: direct mapping
					Result.extend (byte.to_character_32)
				elseif byte >= 0xA0 then
						-- Latin-1 supplement (0xA0-0xFF): direct mapping
					Result.extend (byte.to_character_32)
				else
						-- Special range (0x80-0x9F): use mapping table
					Result.extend (pdfdoc_to_unicode (byte))
				end
				i := i + 1
			end
		end

feature -- Status

	can_encode (text: READABLE_STRING_GENERAL): BOOLEAN
			-- Can all characters in `text' be encoded in PDFDocEncoding?
		local
			i: INTEGER
			code: NATURAL_32
		do
			Result := True
			from
				i := 1
			until
				i > text.count or not Result
			loop
				code := text.code (i)
				if code <= 0x7F then
						-- ASCII range: always encodable
					Result := True
				elseif code >= 0xA0 and code <= 0xFF then
						-- Latin-1 supplement: always encodable
					Result := True
				elseif is_special_unicode (code) then
						-- Special Unicode characters that map to 0x80-0x9F
					Result := True
				else
						-- Cannot encode this character
					Result := False
				end
				i := i + 1
			end
		end

	encoding_name: STRING_8
			-- Name of this encoding.
		do
			Result := "PDFDocEncoding"
		end

feature {NONE} -- Implementation

	pdfdoc_to_unicode (byte: NATURAL_8): CHARACTER_32
			-- Convert PDFDocEncoding byte (0x80-0x9F) to Unicode character.
			-- Per ISO 32000-1:2008 Table D.2.
		require
			in_special_range: byte >= 0x80 and byte <= 0x9F
		do
			inspect byte
			when 0x80 then Result := '%/0x2022/' -- BULLET
			when 0x81 then Result := '%/0x2020/' -- DAGGER
			when 0x82 then Result := '%/0x2021/' -- DOUBLE DAGGER
			when 0x83 then Result := '%/0x2026/' -- HORIZONTAL ELLIPSIS
			when 0x84 then Result := '%/0x2014/' -- EM DASH
			when 0x85 then Result := '%/0x2013/' -- EN DASH
			when 0x86 then Result := '%/0x0192/' -- LATIN SMALL LETTER F WITH HOOK
			when 0x87 then Result := '%/0x2044/' -- FRACTION SLASH
			when 0x88 then Result := '%/0x2039/' -- SINGLE LEFT-POINTING ANGLE QUOTATION MARK
			when 0x89 then Result := '%/0x203A/' -- SINGLE RIGHT-POINTING ANGLE QUOTATION MARK
			when 0x8A then Result := '%/0x2212/' -- MINUS SIGN
			when 0x8B then Result := '%/0x2030/' -- PER MILLE SIGN
			when 0x8C then Result := '%/0x201E/' -- DOUBLE LOW-9 QUOTATION MARK
			when 0x8D then Result := '%/0x201C/' -- LEFT DOUBLE QUOTATION MARK
			when 0x8E then Result := '%/0x201D/' -- RIGHT DOUBLE QUOTATION MARK
			when 0x8F then Result := '%/0x2018/' -- LEFT SINGLE QUOTATION MARK
			when 0x90 then Result := '%/0x2019/' -- RIGHT SINGLE QUOTATION MARK
			when 0x91 then Result := '%/0x201A/' -- SINGLE LOW-9 QUOTATION MARK
			when 0x92 then Result := '%/0x2122/' -- TRADE MARK SIGN
			when 0x93 then Result := '%/0xFB01/' -- LATIN SMALL LIGATURE FI
			when 0x94 then Result := '%/0xFB02/' -- LATIN SMALL LIGATURE FL
			when 0x95 then Result := '%/0x0141/' -- LATIN CAPITAL LETTER L WITH STROKE
			when 0x96 then Result := '%/0x0152/' -- LATIN CAPITAL LIGATURE OE
			when 0x97 then Result := '%/0x0160/' -- LATIN CAPITAL LETTER S WITH CARON
			when 0x98 then Result := '%/0x0178/' -- LATIN CAPITAL LETTER Y WITH DIAERESIS
			when 0x99 then Result := '%/0x017D/' -- LATIN CAPITAL LETTER Z WITH CARON
			when 0x9A then Result := '%/0x0131/' -- LATIN SMALL LETTER DOTLESS I
			when 0x9B then Result := '%/0x0142/' -- LATIN SMALL LETTER L WITH STROKE
			when 0x9C then Result := '%/0x0153/' -- LATIN SMALL LIGATURE OE
			when 0x9D then Result := '%/0x0161/' -- LATIN SMALL LETTER S WITH CARON
			when 0x9E then Result := '%/0x017E/' -- LATIN SMALL LETTER Z WITH CARON
			when 0x9F then Result := '%/0xFFFF/' -- REPLACEMENT (undefined in spec)
			else
					-- Should not happen due to precondition
				Result := '%/0xFFFD/' -- REPLACEMENT CHARACTER
			end
		end

	unicode_to_pdfdoc (code: NATURAL_32): CHARACTER_8
			-- Convert Unicode code point to PDFDocEncoding byte.
			-- Returns replacement character (0x3F = '?') if not encodable.
		do
			inspect code
			when 0x2022 then Result := '%/0x80/' -- BULLET
			when 0x2020 then Result := '%/0x81/' -- DAGGER
			when 0x2021 then Result := '%/0x82/' -- DOUBLE DAGGER
			when 0x2026 then Result := '%/0x83/' -- HORIZONTAL ELLIPSIS
			when 0x2014 then Result := '%/0x84/' -- EM DASH
			when 0x2013 then Result := '%/0x85/' -- EN DASH
			when 0x0192 then Result := '%/0x86/' -- LATIN SMALL LETTER F WITH HOOK
			when 0x2044 then Result := '%/0x87/' -- FRACTION SLASH
			when 0x2039 then Result := '%/0x88/' -- SINGLE LEFT-POINTING ANGLE QUOTATION MARK
			when 0x203A then Result := '%/0x89/' -- SINGLE RIGHT-POINTING ANGLE QUOTATION MARK
			when 0x2212 then Result := '%/0x8A/' -- MINUS SIGN
			when 0x2030 then Result := '%/0x8B/' -- PER MILLE SIGN
			when 0x201E then Result := '%/0x8C/' -- DOUBLE LOW-9 QUOTATION MARK
			when 0x201C then Result := '%/0x8D/' -- LEFT DOUBLE QUOTATION MARK
			when 0x201D then Result := '%/0x8E/' -- RIGHT DOUBLE QUOTATION MARK
			when 0x2018 then Result := '%/0x8F/' -- LEFT SINGLE QUOTATION MARK
			when 0x2019 then Result := '%/0x90/' -- RIGHT SINGLE QUOTATION MARK
			when 0x201A then Result := '%/0x91/' -- SINGLE LOW-9 QUOTATION MARK
			when 0x2122 then Result := '%/0x92/' -- TRADE MARK SIGN
			when 0xFB01 then Result := '%/0x93/' -- LATIN SMALL LIGATURE FI
			when 0xFB02 then Result := '%/0x94/' -- LATIN SMALL LIGATURE FL
			when 0x0141 then Result := '%/0x95/' -- LATIN CAPITAL LETTER L WITH STROKE
			when 0x0152 then Result := '%/0x96/' -- LATIN CAPITAL LIGATURE OE
			when 0x0160 then Result := '%/0x97/' -- LATIN CAPITAL LETTER S WITH CARON
			when 0x0178 then Result := '%/0x98/' -- LATIN CAPITAL LETTER Y WITH DIAERESIS
			when 0x017D then Result := '%/0x99/' -- LATIN CAPITAL LETTER Z WITH CARON
			when 0x0131 then Result := '%/0x9A/' -- LATIN SMALL LETTER DOTLESS I
			when 0x0142 then Result := '%/0x9B/' -- LATIN SMALL LETTER L WITH STROKE
			when 0x0153 then Result := '%/0x9C/' -- LATIN SMALL LIGATURE OE
			when 0x0161 then Result := '%/0x9D/' -- LATIN SMALL LETTER S WITH CARON
			when 0x017E then Result := '%/0x9E/' -- LATIN SMALL LETTER Z WITH CARON
			else
					-- Cannot encode: use '?' as replacement
				Result := '?'
			end
		end

	is_special_unicode (code: NATURAL_32): BOOLEAN
			-- Is `code' a Unicode character that maps to PDFDocEncoding special range?
		do
			Result := code = 0x2022 or code = 0x2020 or code = 0x2021 or code = 0x2026
				or code = 0x2014 or code = 0x2013 or code = 0x0192 or code = 0x2044
				or code = 0x2039 or code = 0x203A or code = 0x2212 or code = 0x2030
				or code = 0x201E or code = 0x201C or code = 0x201D or code = 0x2018
				or code = 0x2019 or code = 0x201A or code = 0x2122 or code = 0xFB01
				or code = 0xFB02 or code = 0x0141 or code = 0x0152 or code = 0x0160
				or code = 0x0178 or code = 0x017D or code = 0x0131 or code = 0x0142
				or code = 0x0153 or code = 0x0161 or code = 0x017E
		end

end
