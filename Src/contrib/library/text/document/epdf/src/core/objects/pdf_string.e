note
	description: "[
		Represents a PDF string object. Strings can be literal (parentheses) or hexadecimal.
		
		Per ISO 32000-1:2008 §7.3.4, PDF strings are byte sequences that can represent:
		- Binary data (raw bytes)
		- Text encoded as PDFDocEncoding (default)
		- Text encoded as UTF-16BE (identified by BOM 0xFE 0xFF)
		
		This class provides encoding detection and text decoding capabilities.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_STRING

inherit
	PDF_OBJECT

create
	make_literal,
	make_hex,
	make_from_text

feature -- Initialization

	make_literal (a_value: READABLE_STRING_GENERAL)
			-- Create a PDF literal string.
			-- Per ISO 32000-1:2008 §7.3.4, PDF strings are byte sequences.
		do
			value := a_value.to_string_8
			is_hexadecimal := False
			detect_encoding
		ensure
			value_set: value.same_string_general (a_value)
			is_literal: not is_hexadecimal
		end

	make_hex (a_value: READABLE_STRING_GENERAL)
			-- Create a PDF hexadecimal string.
			-- Per ISO 32000-1:2008 §7.3.4, PDF strings are byte sequences.
		do
			value := a_value.to_string_8
			is_hexadecimal := True
			detect_encoding
		ensure
			value_set: value.same_string_general (a_value)
			is_hex: is_hexadecimal
		end

	make_from_text (text: READABLE_STRING_GENERAL)
			-- Create a PDF string from Unicode text.
			-- Automatically chooses encoding: PDFDocEncoding if possible, otherwise UTF-16BE.
		local
			pdfdoc: PDF_PDFDOC_ENCODING
			utf16be: PDF_UTF16BE_ENCODING
		do
			create pdfdoc
			if pdfdoc.can_encode (text) then
					-- Use PDFDocEncoding (more compact)
				value := pdfdoc.encode_text (text)
				encoding_type := Encoding_pdfdoc
			else
					-- Use UTF-16BE for full Unicode support
				create utf16be
				value := utf16be.encode_text (text)
				encoding_type := Encoding_utf16be
			end
			is_hexadecimal := False
		ensure
			encoding_detected: encoding_type = Encoding_pdfdoc or encoding_type = Encoding_utf16be
		end

feature -- Access

	value: STRING_8
			-- The string value (byte sequence).
			-- Per ISO 32000-1:2008 §7.3.4, strings are PDFDocEncoding or UTF-16BE bytes.

	set_value (a_value: STRING_8)
			-- Set the string value directly (used during decryption).
		do
			value := a_value
			detect_encoding
		ensure
			value_set: value = a_value
		end

	is_hexadecimal: BOOLEAN
			-- Is this a hexadecimal string?

	encoding_type: INTEGER
			-- Detected encoding type (see Encoding_* constants).

feature -- Text Decoding

	decoded_text: STRING_32
			-- Decode byte sequence to Unicode text.
			-- Uses detected encoding to properly decode the bytes.
		local
			pdfdoc: PDF_PDFDOC_ENCODING
			utf16be: PDF_UTF16BE_ENCODING
		do
			inspect encoding_type
			when Encoding_utf16be then
				create utf16be
				Result := utf16be.decode_bytes (value)
			when Encoding_pdfdoc then
				create pdfdoc
				Result := pdfdoc.decode_bytes (value)
			else
					-- Raw/unknown: treat as PDFDocEncoding
				create pdfdoc
				Result := pdfdoc.decode_bytes (value)
			end
		ensure
			result_not_void: Result /= Void
		end

	is_text_string: BOOLEAN
			-- Is this a text string (as opposed to raw binary)?
			-- Text strings are encoded as PDFDocEncoding or UTF-16BE.
		do
			Result := encoding_type = Encoding_pdfdoc or encoding_type = Encoding_utf16be
		end

	is_utf16be: BOOLEAN
			-- Is this string encoded as UTF-16BE?
		do
			Result := encoding_type = Encoding_utf16be
		end

feature -- Encoding Constants

	Encoding_raw: INTEGER = 0
			-- Raw bytes (not a text string).

	Encoding_pdfdoc: INTEGER = 1
			-- PDFDocEncoding (single-byte, default for text strings).

	Encoding_utf16be: INTEGER = 2
			-- UTF-16BE encoding (identified by BOM 0xFE 0xFF).

feature -- Visitor Pattern

	accept (a_visitor: PDF_VISITOR)
			-- Accept visitor for processing.
		do
			a_visitor.visit_string (Current)
		end

feature -- Conversion

	to_pdf_string: STRING_8
			-- Convert to PDF format.
			-- Per ISO 32000-1:2008 §7.3.4, strings serialize to byte sequences.
		do
			if is_hexadecimal then
				create Result.make (value.count * 2 + 2)
				Result.append_character ('<')
				Result.append (bytes_to_hex (value))
				Result.append_character ('>')
			else
				create Result.make (value.count + 2)
				Result.append_character ('(')
				Result.append (escape_literal_string (value))
				Result.append_character (')')
			end
		ensure
			result_not_empty: not Result.is_empty
		end

feature {NONE} -- Implementation

	detect_encoding
			-- Detect encoding type from byte sequence.
			-- Per ISO 32000-1:2008 §7.9.2.2, UTF-16BE is identified by BOM.
		do
			if has_utf16be_bom then
				encoding_type := Encoding_utf16be
			else
					-- Default to PDFDocEncoding for text strings
				encoding_type := Encoding_pdfdoc
			end
		end

	has_utf16be_bom: BOOLEAN
			-- Does `value' start with UTF-16BE BOM (0xFE 0xFF)?
		do
			Result := value.count >= 2 and then
				value.code (1) = 0xFE and value.code (2) = 0xFF
		end

	escape_literal_string (s: STRING_8): STRING_8
			-- Escape special characters in a literal string per ISO 32000-1:2008 §7.3.4.2.
			-- Handles: \\n (LF), \\r (CR), \\t (HT), \\b (BS), \\f (FF), \\(, \\), \\\\
			-- Non-printable characters are encoded using octal escape sequences.
		local
			i: INTEGER
			c: CHARACTER
			code: INTEGER
		do
			create Result.make (s.count)
			from
				i := 1
			until
				i > s.count
			loop
				c := s [i]
				code := c.code
				inspect c
				when '(' then
					Result.append ("%H(")
				when ')' then
					Result.append ("%H)")
				when '%H' then
						-- Backslash itself
					Result.append ("%H%H")
				when '%N' then
						-- Line feed (LF, 0x0A)
					Result.append ("%Hn")
				when '%R' then
						-- Carriage return (CR, 0x0D)
					Result.append ("%Hr")
				when '%T' then
						-- Horizontal tab (HT, 0x09)
					Result.append ("%Ht")
				when '%B' then
						-- Backspace (BS, 0x08)
					Result.append ("%Hb")
				when '%F' then
						-- Form feed (FF, 0x0C)
					Result.append ("%Hf")
				else
					if code < 32 or code > 126 then
							-- Non-printable or non-ASCII: use octal escape \\ddd
						Result.append ("%H")
						Result.append (octal_string (code))
					else
						Result.append_character (c)
					end
				end
				i := i + 1
			end
		end

	octal_string (code: INTEGER): STRING_8
			-- Convert byte value to 3-digit octal string for PDF escape sequence.
			-- Per ISO 32000-1:2008 §7.3.4.2, octal codes use 1-3 digits.
			-- We always use 3 digits for unambiguous encoding.
		require
			valid_byte: code >= 0 and code <= 255
		local
			d1, d2, d3: INTEGER
		do
			create Result.make (3)
			d1 := code // 64
			d2 := (code \\ 64) // 8
			d3 := code \\ 8
			Result.append_integer (d1)
			Result.append_integer (d2)
			Result.append_integer (d3)
		ensure
			three_digits: Result.count = 3
			valid_octal: Result.is_integer
		end

	bytes_to_hex (bytes: STRING_8): STRING_8
			-- Convert byte string to hexadecimal string.
		local
			i: INTEGER
			code: NATURAL_32
			hex: STRING_8
		do
			create Result.make (bytes.count * 2)
			from i := 1 until i > bytes.count loop
				code := bytes.code (i)
				hex := code.to_hex_string
				-- hex format from NATURAL_32 is 8 characters, we need last 2
				Result.append (hex.substring (7, 8))
				i := i + 1
			end
		ensure
			correct_length: Result.count = bytes.count * 2
		end

invariant
	valid_encoding: encoding_type >= 0 and encoding_type <= 2

end

