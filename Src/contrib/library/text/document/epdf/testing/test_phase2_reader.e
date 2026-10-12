note
	description: "[
		Test suite for Phase 2: Reader components.
		Tests lexer, parser, xref parsing, and lazy loading functionality.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_PHASE2_READER

inherit
	EQA_TEST_SET

feature -- Test: Lexer

	test_lexer_whitespace
			-- Test lexer whitespace handling.
		local
			source: PDF_STRING_BYTE_SOURCE
			lexer: PDF_LEXER
			token: PDF_TOKEN
		do
			create source.make ("   %T%N  null")
			create lexer.make (source)

			token := lexer.next_token
			assert ("token is null", token.token_type = {PDF_TOKEN}.type_null)
		end

	test_lexer_numbers
			-- Test lexer number tokenization.
		local
			source: PDF_STRING_BYTE_SOURCE
			lexer: PDF_LEXER
			token: PDF_TOKEN
		do
			create source.make ("123 -456 3.14 -2.5")
			create lexer.make (source)

			token := lexer.next_token
			assert ("first is number", token.token_type = {PDF_TOKEN}.type_number)
			assert ("first value is 123", token.value.is_equal ("123"))

			token := lexer.next_token
			assert ("second is number", token.token_type = {PDF_TOKEN}.type_number)
			assert ("second value is -456", token.value.is_equal ("-456"))

			token := lexer.next_token
			assert ("third is number", token.token_type = {PDF_TOKEN}.type_number)
			assert ("third value is 3.14", token.value.is_equal ("3.14"))

			token := lexer.next_token
			assert ("fourth is number", token.token_type = {PDF_TOKEN}.type_number)
			assert ("fourth value is -2.5", token.value.is_equal ("-2.5"))
		end

	test_lexer_names
			-- Test lexer name tokenization.
		local
			source: PDF_STRING_BYTE_SOURCE
			lexer: PDF_LEXER
			token: PDF_TOKEN
		do
			create source.make ("/Type /Page /Parent")
			create lexer.make (source)

			token := lexer.next_token
			assert ("first is name", token.token_type = {PDF_TOKEN}.type_name)
				-- Per ISO 32000-1:2008, the slash is a delimiter, not part of the name value
			assert ("first value is Type", token.value.is_equal ("Type"))

			token := lexer.next_token
			assert ("second is name", token.token_type = {PDF_TOKEN}.type_name)
			assert ("second value is Page", token.value.is_equal ("Page"))

			token := lexer.next_token
			assert ("third is name", token.token_type = {PDF_TOKEN}.type_name)
			assert ("third value is Parent", token.value.is_equal ("Parent"))
		end

	test_lexer_strings
			-- Test lexer string tokenization.
		local
			source: PDF_STRING_BYTE_SOURCE
			lexer: PDF_LEXER
			token: PDF_TOKEN
		do
			create source.make ("(Hello World) <48656C6C6F>")
			create lexer.make (source)

			token := lexer.next_token
			assert ("first is string", token.token_type = {PDF_TOKEN}.type_string)
			assert ("first is literal", token.value.is_equal ("Hello World"))

			token := lexer.next_token
			assert ("second is hex_string", token.token_type = {PDF_TOKEN}.type_hex_string)
			assert ("second is hex", token.value.is_equal ("48656C6C6F"))
		end

	test_lexer_string_escapes
			-- Test lexer string escape decoding (including octal, backslash, and newline escapes).
		local
			source: PDF_STRING_BYTE_SOURCE
			lexer: PDF_LEXER
			token: PDF_TOKEN
		do
				-- 1. Standard escape sequences: \n, \r, \t, \b, \f, \(\)\\, and invalid escape \c
			create source.make ("(Hello%HnWorld%Hr%Ht%Hb%Hf%H(%H)%H%H%Hc)")
			create lexer.make (source)
			token := lexer.next_token
			assert ("is_string_1", token.token_type = {PDF_TOKEN}.type_string)
			assert ("escapes_decoded", token.value.is_equal ("Hello%NWorld%R%T%B%F()%Hc"))

				-- 2. Octal escapes: \123 (S), \45 (%%), \6 (code 6), \377 (code 255)
			create source.make ("(%H123%H45%H6%H377)")
			create lexer.make (source)
			token := lexer.next_token
			assert ("is_string_2", token.token_type = {PDF_TOKEN}.type_string)
			assert ("octal_decoded", token.value.is_equal ("S%%%/6/%/255/"))

				-- 3. Ignored newlines (backslash followed by CR, LF, or CRLF)
			create source.make ("(Line 1 %H%NLine 2 %H%RLine 3 %H%R%NLine 4)")
			create lexer.make (source)
			token := lexer.next_token
			assert ("is_string_3", token.token_type = {PDF_TOKEN}.type_string)
			assert ("newlines_ignored", token.value.is_equal ("Line 1 Line 2 Line 3 Line 4"))
		end

	test_lexer_keywords
			-- Test lexer keyword tokenization.
		local
			source: PDF_STRING_BYTE_SOURCE
			lexer: PDF_LEXER
			token: PDF_TOKEN
		do
			create source.make ("null true false obj endobj stream endstream R xref trailer startxref")
			create lexer.make (source)

			token := lexer.next_token
			assert ("null keyword", token.token_type = {PDF_TOKEN}.type_null)

			token := lexer.next_token
			assert ("true keyword", token.token_type = {PDF_TOKEN}.type_boolean)

			token := lexer.next_token
			assert ("false keyword", token.token_type = {PDF_TOKEN}.type_boolean)

			token := lexer.next_token
			assert ("obj keyword", token.token_type = {PDF_TOKEN}.type_obj_start)

			token := lexer.next_token
			assert ("endobj keyword", token.token_type = {PDF_TOKEN}.type_obj_end)

			token := lexer.next_token
			assert ("stream keyword", token.token_type = {PDF_TOKEN}.type_stream_start)

			token := lexer.next_token
			assert ("endstream keyword", token.token_type = {PDF_TOKEN}.type_stream_end)

			token := lexer.next_token
			assert ("R keyword", token.token_type = {PDF_TOKEN}.type_ref)

			token := lexer.next_token
			assert ("xref keyword", token.token_type = {PDF_TOKEN}.type_xref)

			token := lexer.next_token
			assert ("trailer keyword", token.token_type = {PDF_TOKEN}.type_trailer)

			token := lexer.next_token
			assert ("startxref keyword", token.token_type = {PDF_TOKEN}.type_startxref)
		end

	test_lexer_delimiters
			-- Test lexer delimiter tokenization.
		local
			source: PDF_STRING_BYTE_SOURCE
			lexer: PDF_LEXER
			token: PDF_TOKEN
		do
			create source.make ("[ ] << >>")
			create lexer.make (source)

			token := lexer.next_token
			assert ("array start", token.token_type = {PDF_TOKEN}.type_array_start)

			token := lexer.next_token
			assert ("array end", token.token_type = {PDF_TOKEN}.type_array_end)

			token := lexer.next_token
			assert ("dict start", token.token_type = {PDF_TOKEN}.type_dict_start)

			token := lexer.next_token
			assert ("dict end", token.token_type = {PDF_TOKEN}.type_dict_end)
		end

	test_lexer_comments
			-- Test lexer comment handling.
		local
			source: PDF_STRING_BYTE_SOURCE
			lexer: PDF_LEXER
			token: PDF_TOKEN
		do
			create source.make ("123 %% This is a comment%N456")
			create lexer.make (source)

			token := lexer.next_token
			assert ("first number", token.token_type = {PDF_TOKEN}.type_number)
			assert ("first value", token.value.is_equal ("123"))

			token := lexer.next_token
			assert ("second number", token.token_type = {PDF_TOKEN}.type_number)
			assert ("second value", token.value.is_equal ("456"))
		end

feature -- Test: Parser

	test_parser_null
			-- Test parsing null object.
		local
			source: PDF_STRING_BYTE_SOURCE
			lexer: PDF_LEXER
			parser: PDF_PARSER
		do
			create source.make ("null")
			create lexer.make (source)
			create parser.make (lexer)

			if attached {PDF_NULL} parser.parse_object as null_obj then
				assert ("parsed null", True)
			else
				assert ("parsed null", False)
			end
		end

	test_parser_boolean
			-- Test parsing boolean objects.
		local
			source: PDF_STRING_BYTE_SOURCE
			lexer: PDF_LEXER
			parser: PDF_PARSER
		do
			create source.make ("true false")
			create lexer.make (source)
			create parser.make (lexer)

			if attached {PDF_BOOLEAN} parser.parse_object as bool_obj then
				assert ("parsed true", bool_obj.value)
			else
				assert ("parsed true failed", False)
			end

			if attached {PDF_BOOLEAN} parser.parse_object as bool_obj then
				assert ("parsed false", not bool_obj.value)
			else
				assert ("parsed false failed", False)
			end
		end

	test_parser_number
			-- Test parsing number objects.
		local
			source: PDF_STRING_BYTE_SOURCE
			lexer: PDF_LEXER
			parser: PDF_PARSER
		do
			create source.make ("42 3.14")
			create lexer.make (source)
			create parser.make (lexer)

			if attached {PDF_NUMBER} parser.parse_object as num_obj then
				assert ("parsed integer", num_obj.real_value = 42.0)
			else
				assert ("parsed integer failed", False)
			end

			if attached {PDF_NUMBER} parser.parse_object as num_obj then
				assert ("parsed real", (num_obj.real_value - 3.14).abs < 0.001)
			else
				assert ("parsed real failed", False)
			end
		end

	test_parser_string
			-- Test parsing string objects.
		local
			source: PDF_STRING_BYTE_SOURCE
			lexer: PDF_LEXER
			parser: PDF_PARSER
		do
			create source.make ("(Hello World)")
			create lexer.make (source)
			create parser.make (lexer)

			if attached {PDF_STRING} parser.parse_object as str_obj then
				assert ("parsed string", True)
			else
				assert ("parsed string", False)
			end
		end

	test_parser_name
			-- Test parsing name objects.
		local
			source: PDF_STRING_BYTE_SOURCE
			lexer: PDF_LEXER
			parser: PDF_PARSER
		do
			create source.make ("/Type")
			create lexer.make (source)
			create parser.make (lexer)

			if attached {PDF_NAME} parser.parse_object as name_obj then
					-- Per ISO 32000-1:2008, name value does not include leading slash
				assert ("parsed name", name_obj.value.is_equal ("Type"))
			else
				assert ("parsed name", False)
			end
		end

	test_parser_array
			-- Test parsing array objects.
		local
			source: PDF_STRING_BYTE_SOURCE
			lexer: PDF_LEXER
			parser: PDF_PARSER
		do
			create source.make ("[ 1 2 3 ]")
			create lexer.make (source)
			create parser.make (lexer)

			if attached {PDF_ARRAY} parser.parse_object as array_obj then
				assert ("parsed array", array_obj.count = 3)
			else
				assert ("parsed array", False)
			end
		end

	test_parser_dictionary
			-- Test parsing dictionary objects.
		local
			source: PDF_STRING_BYTE_SOURCE
			lexer: PDF_LEXER
			parser: PDF_PARSER
		do
			create source.make ("<< /Type /Page /Count 1 >>")
			create lexer.make (source)
			create parser.make (lexer)

			if attached {PDF_DICTIONARY} parser.parse_object as dict_obj then
				assert ("parsed dictionary", dict_obj.count = 2)
			else
				assert ("parsed dictionary", False)
			end
		end

	test_parser_reference
			-- Test parsing indirect references.
		local
			source: PDF_STRING_BYTE_SOURCE
			lexer: PDF_LEXER
			parser: PDF_PARSER
		do
			create source.make ("1 0 R")
			create lexer.make (source)
			create parser.make (lexer)

			if attached {PDF_REFERENCE} parser.parse_object as ref_obj then
				assert ("parsed reference", True)
				assert ("correct object number", ref_obj.object_id.object_number = 1)
				assert ("correct generation", ref_obj.object_id.generation = 0)
			else
				assert ("parsed reference", False)
			end
		end

	test_parser_indirect_object
			-- Test parsing indirect objects.
		local
			source: PDF_STRING_BYTE_SOURCE
			lexer: PDF_LEXER
			parser: PDF_PARSER
		do
			create source.make ("1 0 obj << /Type /Catalog >> endobj")
			create lexer.make (source)
			create parser.make (lexer)

			if attached parser.parse_indirect_object as indirect then
				assert ("parsed indirect object", True)
				assert ("correct object number", indirect.object_id.object_number = 1)
				assert ("correct generation", indirect.object_id.generation = 0)
			else
				assert ("parsed indirect object", False)
			end
		end

feature -- Test: XRef

	test_xref_entry
			-- Test xref entry creation.
		local
			entry: PDF_XREF_ENTRY
		do
			create entry.make_in_use (1234, 0)
			assert ("in use", entry.is_in_use)
			assert ("offset correct", entry.offset = 1234)
			assert ("generation correct", entry.generation = 0)

			create entry.make_free (5, 65535)
			assert ("free", entry.is_free)
			assert ("next free correct", entry.offset = 5)
			assert ("generation correct", entry.generation = 65535)
		end

	test_xref_table
			-- Test xref table operations.
		local
			table: PDF_XREF_TABLE
		do
			create table.make

			table.add_in_use (1, 100, 0)
			table.add_in_use (2, 200, 0)
			table.add_free (3, 0, 65535)

			assert ("has entry 1", table.has_entry (1))
			assert ("has entry 2", table.has_entry (2))
			assert ("has entry 3", table.has_entry (3))
			assert ("count is 3", table.count = 3)

			if attached table.entry (1) as entry then
				assert ("entry 1 in use", entry.is_in_use)
				assert ("entry 1 offset", entry.offset = 100)
			else
				assert ("entry 1 exists", False)
			end

			if attached table.entry (3) as entry then
				assert ("entry 3 free", entry.is_free)
			else
				assert ("entry 3 exists", False)
			end
		end

	test_trailer
			-- Test trailer dictionary.
		local
			dict: PDF_DICTIONARY
			trailer: PDF_TRAILER
			size_num: PDF_NUMBER
			root_ref: PDF_REFERENCE
			obj_id: PDF_OBJECT_ID
		do
			create dict.make_empty
			create size_num.make (10.0)
				-- Keys should not include leading slash (it's a delimiter, not part of the name)
			dict.put (size_num, "Size")

			create obj_id.make (1, 0)
			create root_ref.make (obj_id)
			dict.put (root_ref, "Root")

			create trailer.make (dict)

			assert ("size is 10", trailer.size = 10)
			assert ("has root", trailer.root /= Void)
			assert ("is valid", trailer.is_valid)
		end

feature -- Test: Document

	test_document_creation
			-- Test document creation.
		local
			doc: PDF_DOCUMENT
		do
			create doc.make
			assert ("not loaded initially", not doc.is_loaded)
			assert ("permissive mode by default", not doc.strict_mode)

			doc.set_strict_mode (True)
			assert ("strict mode set", doc.strict_mode)
		end

end
