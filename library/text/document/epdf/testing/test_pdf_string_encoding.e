note
	description: "[
		Test suite for PDF String encoding support.
		Tests PDFDocEncoding, UTF-16BE encoding, and automatic encoding detection.
	]"
	author: ""
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_PDF_STRING_ENCODING

inherit
	EQA_TEST_SET

feature -- Test routines: PDFDocEncoding

	test_pdfdoc_encoding_ascii
			-- Test: PDFDocEncoding handles ASCII characters correctly.
		note
			testing: "covers/{PDF_PDFDOC_ENCODING}.encode_text"
			testing: "covers/{PDF_PDFDOC_ENCODING}.decode_bytes"
		local
			encoder: PDF_PDFDOC_ENCODING
			text: STRING_32
			encoded: STRING_8
			decoded: STRING_32
		do
			create encoder
			text := "Hello, PDF World!"
			
				-- Encode
			encoded := encoder.encode_text (text)
			assert ("ascii_encoded_correctly", encoded.same_string ("Hello, PDF World!"))
			
				-- Decode
			decoded := encoder.decode_bytes (encoded)
			assert ("ascii_decoded_correctly", decoded.same_string_general (text))
		end

	test_pdfdoc_encoding_special_chars
			-- Test: PDFDocEncoding special characters (0x80-0x9F).
		note
			testing: "covers/{PDF_PDFDOC_ENCODING}.encode_text"
			testing: "covers/{PDF_PDFDOC_ENCODING}.decode_bytes"
		local
			encoder: PDF_PDFDOC_ENCODING
			text: STRING_32
			encoded: STRING_8
			decoded: STRING_32
		do
			create encoder
			
				-- Test bullet character (U+2022 → 0x80)
			text := "%/0x2022/"  -- BULLET
			encoded := encoder.encode_text (text)
			assert ("bullet_encoded", encoded.count = 1 and encoded.code (1) = 0x80)
			
			decoded := encoder.decode_bytes (encoded)
			assert ("bullet_decoded", decoded.count = 1 and decoded.code (1) = 0x2022)
			
				-- Test dagger (U+2020 → 0x81)
			text := "%/0x2020/"  -- DAGGER
			encoded := encoder.encode_text (text)
			assert ("dagger_encoded", encoded.count = 1 and encoded.code (1) = 0x81)
			
			decoded := encoder.decode_bytes (encoded)
			assert ("dagger_decoded", decoded.count = 1 and decoded.code (1) = 0x2020)
		end

	test_pdfdoc_encoding_latin1
			-- Test: PDFDocEncoding Latin-1 supplement (0xA0-0xFF).
		note
			testing: "covers/{PDF_PDFDOC_ENCODING}.encode_text"
		local
			encoder: PDF_PDFDOC_ENCODING
			text: STRING_32
			encoded: STRING_8
			decoded: STRING_32
		do
			create encoder
			
				-- Test Latin-1 characters (direct mapping)
			text := "Café"  -- Contains é (U+00E9)
			encoded := encoder.encode_text (text)
			decoded := encoder.decode_bytes (encoded)
			assert ("latin1_roundtrip", decoded.same_string_general (text))
		end

	test_pdfdoc_can_encode
			-- Test: can_encode correctly identifies encodable text.
		note
			testing: "covers/{PDF_PDFDOC_ENCODING}.can_encode"
		local
			encoder: PDF_PDFDOC_ENCODING
		do
			create encoder
			
				-- ASCII text
			assert ("can_encode_ascii", encoder.can_encode ("Hello"))
			
				-- Latin-1 text
			assert ("can_encode_latin1", encoder.can_encode ("Café"))
			
				-- Special PDFDoc characters
			assert ("can_encode_bullet", encoder.can_encode ("%/0x2022/"))
			
				-- Cannot encode CJK
			assert ("cannot_encode_cjk", not encoder.can_encode ("日本語"))
			
				-- Cannot encode emoji
			assert ("cannot_encode_emoji", not encoder.can_encode ("😀"))
		end

feature -- Test routines: UTF-16BE

	test_utf16be_encoding_bom
			-- Test: UTF-16BE encoding includes BOM.
		note
			testing: "covers/{PDF_UTF16BE_ENCODING}.encode_text"
		local
			encoder: PDF_UTF16BE_ENCODING
			text: STRING_32
			encoded: STRING_8
		do
			create encoder
			text := "Hello"
			
			encoded := encoder.encode_text (text)
			
				-- Check BOM (0xFE 0xFF)
			assert ("has_bom", encoded.count >= 2)
			assert ("bom_first_byte", encoded.code (1) = 0xFE)
			assert ("bom_second_byte", encoded.code (2) = 0xFF)
		end

	test_utf16be_encoding_roundtrip
			-- Test: UTF-16BE encode/decode roundtrip.
		note
			testing: "covers/{PDF_UTF16BE_ENCODING}.encode_text"
			testing: "covers/{PDF_UTF16BE_ENCODING}.decode_bytes"
		local
			encoder: PDF_UTF16BE_ENCODING
			text: STRING_32
			encoded: STRING_8
			decoded: STRING_32
		do
			create encoder
			text := "Hello, 世界!"  -- Mix of ASCII and CJK
			
			encoded := encoder.encode_text (text)
			decoded := encoder.decode_bytes (encoded)
			
			assert ("utf16be_roundtrip", decoded.same_string_general (text))
		end

	test_utf16be_can_encode_all
			-- Test: UTF-16BE can encode all Unicode.
		note
			testing: "covers/{PDF_UTF16BE_ENCODING}.can_encode"
		local
			encoder: PDF_UTF16BE_ENCODING
		do
			create encoder
			
				-- UTF-16 can encode everything
			assert ("can_encode_ascii", encoder.can_encode ("Hello"))
			assert ("can_encode_cjk", encoder.can_encode ("日本語"))
			assert ("can_encode_emoji", encoder.can_encode ("😀"))
			assert ("can_encode_cyrillic", encoder.can_encode ("Привет"))
		end

feature -- Test routines: PDF_STRING Integration

	test_pdf_string_auto_detection_pdfdoc
			-- Test: PDF_STRING detects PDFDocEncoding.
		note
			testing: "covers/{PDF_STRING}.make_literal"
			testing: "covers/{PDF_STRING}.detect_encoding"
		local
			str: PDF_STRING
		do
			create str.make_literal ("Hello, World!")
			
			assert ("detected_pdfdoc", str.encoding_type = str.Encoding_pdfdoc)
			assert ("is_text_string", str.is_text_string)
			assert ("not_utf16be", not str.is_utf16be)
		end

	test_pdf_string_auto_detection_utf16be
			-- Test: PDF_STRING detects UTF-16BE by BOM.
		note
			testing: "covers/{PDF_STRING}.make_literal"
			testing: "covers/{PDF_STRING}.detect_encoding"
		local
			str: PDF_STRING
			utf16_bytes: STRING_8
		do
				-- Create UTF-16BE bytes with BOM
			create utf16_bytes.make (10)
			utf16_bytes.append_character ('%/0xFE/')
			utf16_bytes.append_character ('%/0xFF/')
			utf16_bytes.append_character ('%/0x00/')
			utf16_bytes.append_character ('H')
			
			create str.make_literal (utf16_bytes)
			
			assert ("detected_utf16be", str.encoding_type = str.Encoding_utf16be)
			assert ("is_text_string", str.is_text_string)
			assert ("is_utf16be", str.is_utf16be)
		end

	test_pdf_string_make_from_text_ascii
			-- Test: make_from_text with ASCII uses PDFDocEncoding.
		note
			testing: "covers/{PDF_STRING}.make_from_text"
		local
			str: PDF_STRING
		do
			create str.make_from_text ("Hello, World!")
			
			assert ("uses_pdfdoc", str.encoding_type = str.Encoding_pdfdoc)
			assert ("value_correct", str.value.same_string ("Hello, World!"))
		end

	test_pdf_string_make_from_text_unicode
			-- Test: make_from_text with Unicode uses UTF-16BE.
		note
			testing: "covers/{PDF_STRING}.make_from_text"
		local
			str: PDF_STRING
		do
			create str.make_from_text ("Hello, 世界!")
			
			assert ("uses_utf16be", str.encoding_type = str.Encoding_utf16be)
			assert ("has_bom", str.value.count >= 2 and 
				str.value.code (1) = 0xFE and str.value.code (2) = 0xFF)
		end

	test_pdf_string_decoded_text
			-- Test: decoded_text returns correct Unicode.
		note
			testing: "covers/{PDF_STRING}.decoded_text"
		local
			str: PDF_STRING
			decoded: STRING_32
		do
				-- Test PDFDocEncoding
			create str.make_from_text ("Café")
			decoded := str.decoded_text
			assert ("pdfdoc_decoded", decoded.same_string ("Café"))
			
				-- Test UTF-16BE
			create str.make_from_text ("日本語")
			decoded := str.decoded_text
			assert ("utf16be_decoded", decoded.same_string ("日本語"))
		end

feature -- Test routines: Round-trip

	test_roundtrip_pdfdoc
			-- Test: PDFDocEncoding round-trip preserves text.
		note
			testing: "covers/{PDF_STRING}.make_from_text"
			testing: "covers/{PDF_STRING}.decoded_text"
		local
			str: PDF_STRING
			original: STRING_32
			decoded: STRING_32
		do
			original := "Hello, Café! • †"
			create str.make_from_text (original)
			decoded := str.decoded_text
			
			assert ("pdfdoc_roundtrip", decoded.same_string_general (original))
		end

	test_roundtrip_utf16be
			-- Test: UTF-16BE round-trip preserves text.
		note
			testing: "covers/{PDF_STRING}.make_from_text"
			testing: "covers/{PDF_STRING}.decoded_text"
		local
			str: PDF_STRING
			original: STRING_32
			decoded: STRING_32
		do
			original := "Hello, 世界! Привет! 😀"
			create str.make_from_text (original)
			decoded := str.decoded_text
			
			assert ("utf16be_roundtrip", decoded.same_string_general (original))
		end

feature -- Test routines: Serialization

	test_literal_string_serialization
			-- Test: Literal strings serialize with parentheses.
		note
			testing: "covers/{PDF_STRING}.to_pdf_string"
		local
			str: PDF_STRING
			serialized: STRING_8
		do
			create str.make_from_text ("Hello")
			serialized := str.to_pdf_string
			
			assert ("starts_with_paren", serialized.starts_with ("("))
			assert ("ends_with_paren", serialized.ends_with (")"))
		end

	test_hex_string_serialization
			-- Test: Hex strings serialize with angle brackets.
		note
			testing: "covers/{PDF_STRING}.to_pdf_string"
		local
			str: PDF_STRING
			serialized: STRING_8
		do
			create str.make_hex ("Hello")  -- expects raw bytes, will serialize as hex
			serialized := str.to_pdf_string
			
			assert ("starts_with_angle", serialized.starts_with ("<"))
			assert ("ends_with_angle", serialized.ends_with (">"))
			assert ("correct_hex", serialized.same_string ("<48656c6c6f>") or serialized.same_string ("<48656C6C6F>"))
		end

end
