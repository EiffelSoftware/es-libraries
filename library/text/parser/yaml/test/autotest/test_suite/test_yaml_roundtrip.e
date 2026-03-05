note
	description: "Roundtrip tests: parse YAML, write it back, parse again."
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_YAML_ROUNDTRIP

inherit
	EQA_TEST_SET

feature -- Test routines

	test_roundtrip_simple_mapping
			-- Test roundtrip of simple mapping.
		local
			parser: YAML_PARSER
			writer: YAML_WRITER
			original, reparsed: detachable YAML_VALUE
			yaml: STRING
		do
			yaml := "name: John"
			create parser.make
			original := parser.parse_string (yaml)
			assert ("original_parsed", original /= Void)
			create writer.make
			if attached original as o then
				writer.write_value (o)
				reparsed := parser.parse_string (writer.output)
				assert ("reparsed_not_void", reparsed /= Void)
				assert ("reparsed_is_mapping", attached reparsed as r and then r.is_mapping)
			end
		end

	test_roundtrip_sequence
			-- Test roundtrip of sequence.
		local
			parser: YAML_PARSER
			writer: YAML_WRITER
			original, reparsed: detachable YAML_VALUE
			yaml: STRING
		do
			yaml := "[a, b, c]"
			create parser.make
			original := parser.parse_string (yaml)
			assert ("original_parsed", original /= Void)
			create writer.make
			writer.set_use_flow_style (True)
			if attached original as o then
				writer.write_value (o)
				reparsed := parser.parse_string (writer.output)
				assert ("reparsed_not_void", reparsed /= Void)
				assert ("reparsed_is_sequence", attached reparsed as r and then r.is_sequence)
				if attached {YAML_SEQUENCE} original as orig_seq and attached {YAML_SEQUENCE} reparsed as rep_seq then
					assert ("same_count", orig_seq.count = rep_seq.count)
				end
			end
		end

	test_roundtrip_nested_structure
			-- Test roundtrip of nested structure.
		local
			parser: YAML_PARSER
			writer: YAML_WRITER
			original, reparsed: detachable YAML_VALUE
			yaml: STRING
		do
			yaml := "{person: {name: John, age: 30}}"
			create parser.make
			original := parser.parse_string (yaml)
			assert ("original_parsed", original /= Void)
			create writer.make
			writer.set_use_flow_style (True)
			if attached original as o then
				writer.write_value (o)
				reparsed := parser.parse_string (writer.output)
				assert ("reparsed_not_void", reparsed /= Void)
			end
		end

	test_roundtrip_types
			-- Test roundtrip preserves types.
		local
			parser: YAML_PARSER
			writer: YAML_WRITER
			original, reparsed: detachable YAML_VALUE
			yaml: STRING
		do
			yaml := "{int: 42, bool: true, null_val: null}"
			create parser.make
			original := parser.parse_string (yaml)
			assert ("original_parsed", original /= Void)
			create writer.make
			writer.set_use_flow_style (True)
			if attached original as o then
				writer.write_value (o)
				reparsed := parser.parse_string (writer.output)
				if attached {YAML_MAPPING} reparsed as m then
					assert ("has_int", m.has_key ("int"))
					if attached m ["int"] as v then
						assert ("int_is_integer", v.is_integer)
					end
					assert ("has_bool", m.has_key ("bool"))
					if attached m ["bool"] as v then
						assert ("bool_is_boolean", v.is_boolean)
					end
				end
			end
		end

	test_roundtrip_quoted_strings
			-- Test roundtrip of quoted strings.
		local
			parser: YAML_PARSER
			writer: YAML_WRITER
			original, reparsed: detachable YAML_VALUE
			yaml: STRING
		do
			yaml := "%"hello world%""
			create parser.make
			original := parser.parse_string (yaml)
			assert ("original_parsed", original /= Void)
			if attached {YAML_SCALAR} original as s then
				assert ("original_value", s.to_string_value.same_string ("hello world"))
				create writer.make
				writer.write_value (s)
				reparsed := parser.parse_string (writer.output)
				if attached {YAML_SCALAR} reparsed as rs then
					assert ("reparsed_value", rs.to_string_value.same_string ("hello world"))
				end
			end
		end

	test_roundtrip_quoted_reserved_strings
			-- Test roundtrip of quoted strings.
		local
			parser: YAML_PARSER
			writer: YAML_WRITER
			original, reparsed: detachable YAML_VALUE
			yaml: STRING
		do
			yaml := "{int: %"42%", bool: %"true%", null_val: %"null%", on: %"yes%" }"
			create parser.make
			original := parser.parse_string (yaml)
			assert ("original_parsed", original /= Void)
			create writer.make
			writer.set_use_flow_style (True)
			if attached original as o then
				writer.write_value (o)
				reparsed := parser.parse_string (writer.output)
				if attached {YAML_MAPPING} reparsed as m then
					assert ("has_int", m.has_key ("int"))
					if attached m ["int"] as v then
						assert ("int_is_string", v.is_string and then v.same_string ("42"))
					end
					assert ("has_bool", m.has_key ("bool"))
					if attached m ["bool"] as v then
						assert ("bool_is_string", v.is_string and then v.same_string ("true"))
					end
					assert ("has_on", m.has_key ("on"))
					if attached m ["on"] as v then
						assert ("on_is_string", v.is_string and then v.same_string ("yes"))
					end
				end
			end
		end

	test_programmatic_construction_and_parse
			-- Test programmatically building YAML and parsing it back.
		local
			parser: YAML_PARSER
			writer: YAML_WRITER
			mapping: YAML_MAPPING
			seq: YAML_SEQUENCE
			parsed: detachable YAML_VALUE
		do
				-- Build a YAML structure programmatically
			create mapping.make
			mapping.put_string ("Test", "name")
			mapping.put (create {YAML_INTEGER}.make_integer_64 (10), "count")
			mapping.put (create {YAML_BOOLEAN}.make (True), "enabled")
			create seq.make
			seq.extend (create {YAML_STRING}.make_plain ("item1"))
			seq.extend (create {YAML_STRING}.make_plain ("item2"))
			mapping.put (seq, "items")

				-- Write it
			create writer.make
			writer.set_use_flow_style (True)
			writer.write_value (mapping)

				-- Parse the output
			create parser.make
			parsed := parser.parse_string (writer.output)
			assert ("parsed_not_void", parsed /= Void)
			assert ("is_mapping", attached parsed as p and then p.is_mapping)
			if attached {YAML_MAPPING} parsed as m then
				assert ("has_name", m.has_key ("name"))
				assert ("has_count", m.has_key ("count"))
				assert ("has_enabled", m.has_key ("enabled"))
				assert ("has_items", m.has_key ("items"))
				if attached m ["items"] as items then
					assert ("items_is_sequence", items.is_sequence)
				end
			end
		end

end
