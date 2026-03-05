note
	description: "Tests for YAML_PARSER class."
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_YAML_PARSER

inherit
	EQA_TEST_SET

feature -- Test routines

	test_parse_simple_scalar
			-- Test parsing a simple scalar.
		local
			parser: YAML_PARSER
			parsed: detachable YAML_VALUE
		do
			create parser.make
			parsed := parser.parse_string ("hello")
			assert ("parsed_not_void", parsed /= Void)
			assert ("is_scalar", attached parsed as r and then r.is_scalar)
			assert ("value_correct", attached {YAML_SCALAR} parsed as s and then s.to_string_value.same_string ("hello"))
		end

	test_parse_integer
			-- Test parsing an integer.
		local
			parser: YAML_PARSER
			parsed: detachable YAML_VALUE
		do
			create parser.make
			parsed := parser.parse_string ("42")
			assert ("parsed_not_void", parsed /= Void)
			assert ("is_integer", attached {YAML_SCALAR} parsed as s and then s.is_integer)
			assert ("value_correct", attached {YAML_SCALAR} parsed as s and then s.to_integer_64 = 42)
		end

	test_parse_negative_integer
			-- Test parsing a negative integer.
		local
			parser: YAML_PARSER
			parsed: detachable YAML_VALUE
		do
			create parser.make
			parsed := parser.parse_string ("-123")
			assert ("parsed_not_void", parsed /= Void)
			assert ("is_integer", attached {YAML_SCALAR} parsed as s and then s.is_integer)
			assert ("value_correct", attached {YAML_SCALAR} parsed as s and then s.to_integer_64 = -123)
		end

	test_parse_real
			-- Test parsing a real number.
		local
			parser: YAML_PARSER
			parsed: detachable YAML_VALUE
		do
			create parser.make
			parsed := parser.parse_string ("3.14")
			assert ("parsed_not_void", parsed /= Void)
			assert ("is_real", attached {YAML_SCALAR} parsed as s and then s.is_real)
		end

	test_parse_boolean_true
			-- Test parsing true boolean.
		local
			parser: YAML_PARSER
			parsed: detachable YAML_VALUE
		do
			create parser.make
			parsed := parser.parse_string ("true")
			assert ("parsed_not_void", parsed /= Void)
			assert ("is_boolean", attached {YAML_SCALAR} parsed as s and then s.is_boolean)
			assert ("is_true", attached {YAML_SCALAR} parsed as s and then s.to_boolean = True)
		end

	test_parse_boolean_false
			-- Test parsing false boolean.
		local
			parser: YAML_PARSER
			parsed: detachable YAML_VALUE
		do
			create parser.make
			parsed := parser.parse_string ("false")
			assert ("parsed_not_void", parsed /= Void)
			assert ("is_boolean", attached {YAML_SCALAR} parsed as s and then s.is_boolean)
			assert ("is_false", attached {YAML_SCALAR} parsed as s and then s.to_boolean = False)
		end

	test_parse_null
			-- Test parsing null.
		local
			parser: YAML_PARSER
			parsed: detachable YAML_VALUE
		do
			create parser.make
			parsed := parser.parse_string ("null")
			assert ("parsed_not_void", parsed /= Void)
			assert ("is_null", attached {YAML_SCALAR} parsed as s and then s.is_null)
		end

	test_parse_single_quoted_string
			-- Test parsing a single-quoted string.
		local
			parser: YAML_PARSER
			parsed: detachable YAML_VALUE
		do
			create parser.make
			parsed := parser.parse_string ("'hello world'")
			assert ("parsed_not_void", parsed /= Void)
			assert ("is_string", attached {YAML_SCALAR} parsed as s and then s.is_string)
			assert ("value_correct", attached {YAML_SCALAR} parsed as s and then s.to_string_value.same_string ("hello world"))
		end

	test_parse_double_quoted_string
			-- Test parsing a double-quoted string.
		local
			parser: YAML_PARSER
			parsed: detachable YAML_VALUE
		do
			create parser.make
			parsed := parser.parse_string ("%"hello world%"")
			assert ("parsed_not_void", parsed /= Void)
			assert ("is_string", attached {YAML_SCALAR} parsed as s and then s.is_string)
			assert ("value_correct", attached {YAML_SCALAR} parsed as s and then s.to_string_value.same_string ("hello world"))
		end

	test_parse_double_quoted_escape_newline
			-- Test parsing escape sequences.
		local
			parser: YAML_PARSER
			parsed: detachable YAML_VALUE
		do
			create parser.make
			parsed := parser.parse_string ("%"hello\nworld%"")
			assert ("parsed_not_void", parsed /= Void)
			assert ("has_newline", attached {YAML_SCALAR} parsed as s and then s.to_string_value.has ('%N'))
		end

	test_parse_flow_sequence
			-- Test parsing a flow sequence.
		local
			parser: YAML_PARSER
			parsed: detachable YAML_VALUE
		do
			create parser.make
			parsed := parser.parse_string ("[a, b, c]")
			assert ("parsed_not_void", parsed /= Void)
			assert ("is_sequence", attached parsed as r and then r.is_sequence)
			assert ("count_three", attached {YAML_SEQUENCE} parsed as seq and then seq.count = 3)
		end

	test_parse_flow_sequence_numbers
			-- Test parsing a flow sequence of numbers.
		local
			parser: YAML_PARSER
			parsed: detachable YAML_VALUE
		do
			create parser.make
			parsed := parser.parse_string ("[1, 2, 3]")
			assert ("parsed_not_void", parsed /= Void)
			assert ("is_sequence", attached parsed as r and then r.is_sequence)
			assert ("first_is_integer", attached {YAML_SEQUENCE} parsed as seq and then seq.first.is_integer)
		end

	test_parse_flow_mapping
			-- Test parsing a flow mapping.
		local
			parser: YAML_PARSER
			parsed: detachable YAML_VALUE
		do
			create parser.make
			parsed := parser.parse_string ("{name: John, age: 30}")
			assert ("parsed_not_void", parsed /= Void)
			assert ("is_mapping", attached parsed as r and then r.is_mapping)
			assert ("has_name", attached {YAML_MAPPING} parsed as m and then m.has_key ("name"))
			assert ("has_age", attached {YAML_MAPPING} parsed as m and then m.has_key ("age"))
		end

	test_parse_block_sequence
			-- Test parsing a block sequence.
		local
			parser: YAML_PARSER
			parsed: detachable YAML_VALUE
			yaml: STRING
		do
			yaml := "[
- item1
- item2
- item3
]"
			create parser.make
			parsed := parser.parse_string (yaml)
			assert ("parsed_not_void", parsed /= Void)
			assert ("is_sequence", attached parsed as r and then r.is_sequence)
			assert ("count_three", attached {YAML_SEQUENCE} parsed as seq and then seq.count = 3)
		end

	test_parse_block_mapping
			-- Test parsing a block mapping.
		local
			parser: YAML_PARSER
			parsed: detachable YAML_VALUE
			yaml: STRING
		do
			yaml := "[
name: John
age: 30
city: NYC
]"
			create parser.make
			parsed := parser.parse_string (yaml)
			assert ("parsed_not_void", parsed /= Void)
			assert ("is_mapping", attached parsed as r and then r.is_mapping)
			assert ("count_three", attached {YAML_MAPPING} parsed as m and then m.count = 3)
		end

	test_parse_nested_mapping
			-- Test parsing nested mappings.
		local
			parser: YAML_PARSER
			parsed: detachable YAML_VALUE
			yaml: STRING
		do
			yaml := "[
person:
  name: John
  age: 30
]"
			create parser.make
			parsed := parser.parse_string (yaml)
			assert ("parsed_not_void", parsed /= Void)
			assert ("is_mapping", attached parsed as r and then r.is_mapping)
			if attached {YAML_MAPPING} parsed as m then
				assert ("has_person", m.has_key ("person"))
				if attached m ["person"] as person then
					assert ("person_is_mapping", person.is_mapping)
				end
			end
		end

	test_parse_sequence_of_mappings
			-- Test parsing sequence of mappings using flow style.
		local
			parser: YAML_PARSER
			parsed: detachable YAML_VALUE
			yaml: STRING
		do
				-- Using flow style for nested mappings in sequence
			yaml := "[{name: John, age: 30}, {name: Jane, age: 25}]"
			create parser.make
			parsed := parser.parse_string (yaml)
			assert ("parsed_not_void", parsed /= Void)
			assert ("is_sequence", attached parsed as r and then r.is_sequence)
			if attached {YAML_SEQUENCE} parsed as seq then
				assert ("count_two", seq.count = 2)
				assert ("first_is_mapping", seq.first.is_mapping)
				if attached {YAML_MAPPING} seq.first as first_map then
					assert ("first_has_name", first_map.has_key ("name"))
				end
			end
		end

	test_parse_with_comments
			-- Test parsing with comments.
		local
			parser: YAML_PARSER
			parsed: detachable YAML_VALUE
			yaml: STRING
		do
			yaml := "[
# This is a comment
name: John # inline comment
age: 30
]"
			create parser.make
			parsed := parser.parse_string (yaml)
			assert ("parsed_not_void", parsed /= Void)
			assert ("is_mapping", attached parsed as r and then r.is_mapping)
			assert ("has_name", attached {YAML_MAPPING} parsed as m and then m.has_key ("name"))
		end

	test_parse_document_marker
			-- Test parsing with document start marker.
		local
			parser: YAML_PARSER
			doc: detachable YAML_DOCUMENT
			yaml: STRING
		do
			yaml := "[
---
name: John
]"
			create parser.make
			doc := parser.parse_document (yaml)
			assert ("doc_not_void", doc /= Void)
			assert ("has_root", attached doc as d and then d.has_root)
		end

	test_parse_empty_sequence
			-- Test parsing empty flow sequence.
		local
			parser: YAML_PARSER
			parsed: detachable YAML_VALUE
		do
			create parser.make
			parsed := parser.parse_string ("[]")
			assert ("parsed_not_void", parsed /= Void)
			assert ("is_sequence", attached parsed as r and then r.is_sequence)
			assert ("is_empty", attached {YAML_SEQUENCE} parsed as seq and then seq.is_empty)
		end

	test_parse_empty_mapping
			-- Test parsing empty flow mapping.
		local
			parser: YAML_PARSER
			parsed: detachable YAML_VALUE
		do
			create parser.make
			parsed := parser.parse_string ("{}")
			assert ("parsed_not_void", parsed /= Void)
			assert ("is_mapping", attached parsed as r and then r.is_mapping)
			assert ("is_empty", attached {YAML_MAPPING} parsed as m and then m.is_empty)
		end

	test_parse_yes_no_booleans
			-- Test YAML 1.1 style yes/no booleans.
		local
			parser: YAML_PARSER
			parsed: detachable YAML_VALUE
		do
			create parser.make
			parsed := parser.parse_string ("yes")
			assert ("yes_is_true", attached {YAML_SCALAR} parsed as s and then s.is_boolean and then s.to_boolean)
			parsed := parser.parse_string ("no")
			assert ("no_is_false", attached {YAML_SCALAR} parsed as s and then s.is_boolean and then not s.to_boolean)
		end

	test_parse_hexadecimal
			-- Test parsing hexadecimal numbers.
		local
			parser: YAML_PARSER
			parsed: detachable YAML_VALUE
		do
			create parser.make
			parsed := parser.parse_string ("0xFF")
			assert ("parsed_not_void", parsed /= Void)
			assert ("is_integer", attached {YAML_SCALAR} parsed as s and then s.is_integer)
		end

	test_no_errors_on_valid_input
			-- Test that valid YAML produces no errors.
		local
			parser: YAML_PARSER
			parsed: detachable YAML_VALUE
		do
			create parser.make
			parsed := parser.parse_string ("key: value")
			assert ("no_errors", not parser.has_error)
		end

end
