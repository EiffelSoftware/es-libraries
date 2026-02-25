note
	description: "Tests for YAML_WRITER class."
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_YAML_WRITER

inherit
	EQA_TEST_SET

feature -- Test routines

	test_write_scalar
			-- Test writing a scalar.
		local
			writer: YAML_WRITER
			scalar: YAML_STRING
		do
			create writer.make
			create scalar.make ("hello")
			writer.write_value (scalar)
			assert ("output_not_empty", not writer.output.is_empty)
			assert ("contains_hello", writer.output.has_substring ("hello"))
		end

	test_write_integer
			-- Test writing an integer.
		local
			writer: YAML_WRITER
			scalar: YAML_SCALAR
		do
			create writer.make
			create scalar.make_integer (42)
			writer.write_value (scalar)
			assert ("contains_42", writer.output.has_substring ("42"))
		end

	test_write_boolean
			-- Test writing a boolean.
		local
			writer: YAML_WRITER
			scalar: YAML_SCALAR
		do
			create writer.make
			create scalar.make_boolean (True)
			writer.write_value (scalar)
			assert ("contains_true", writer.output.has_substring ("true"))
		end

	test_write_null
			-- Test writing null.
		local
			writer: YAML_WRITER
			scalar: YAML_SCALAR
		do
			create writer.make
			create scalar.make_null
			writer.write_value (scalar)
			assert ("contains_null", writer.output.has_substring ("null"))
		end

	test_write_quoted_string
			-- Test writing a quoted string.
		local
			writer: YAML_WRITER
			str: YAML_STRING
		do
			create writer.make
			create str.make_string ("hello: world")
			writer.write_value (str)
			assert ("is_quoted", writer.output.has_substring ("%""))
		end

	test_write_sequence
			-- Test writing a sequence.
		local
			writer: YAML_WRITER
			seq: YAML_SEQUENCE
		do
			create writer.make
			create seq.make
			seq.extend (create {YAML_STRING}.make ("item1"))
			seq.extend (create {YAML_STRING}.make ("item2"))
			writer.write_value (seq)
			assert ("has_dash", writer.output.has_substring ("- "))
		end

	test_write_flow_sequence
			-- Test writing a flow sequence.
		local
			writer: YAML_WRITER
			seq: YAML_SEQUENCE
		do
			create writer.make
			create seq.make
			seq.set_flow_style (True)
			seq.extend (create {YAML_STRING}.make ("a"))
			seq.extend (create {YAML_STRING}.make ("b"))
			writer.write_value (seq)
			assert ("starts_bracket", writer.output.has_substring ("["))
			assert ("ends_bracket", writer.output.has_substring ("]"))
		end

	test_write_mapping
			-- Test writing a mapping.
		local
			writer: YAML_WRITER
			mapping: YAML_MAPPING
		do
			create writer.make
			create mapping.make
			mapping.put_string ("John", "name")
			mapping.put (create {YAML_SCALAR}.make_integer (30), "age")
			writer.write_value (mapping)
			assert ("has_colon", writer.output.has_substring (": "))
			assert ("has_name", writer.output.has_substring ("name"))
		end

	test_write_flow_mapping
			-- Test writing a flow mapping.
		local
			writer: YAML_WRITER
			mapping: YAML_MAPPING
		do
			create writer.make
			create mapping.make
			mapping.set_flow_style (True)
			mapping.put_string ("1", "a")
			writer.write_value (mapping)
			assert ("starts_brace", writer.output.has_substring ("{"))
			assert ("ends_brace", writer.output.has_substring ("}"))
		end

	test_write_document
			-- Test writing a document.
		local
			writer: YAML_WRITER
			doc: YAML_DOCUMENT
			mapping: YAML_MAPPING
		do
			create writer.make
			create mapping.make
			mapping.put_string ("value", "key")
			create doc.make (mapping)
			writer.write_document (doc)
			assert ("has_doc_marker", writer.output.has_substring ("---"))
		end

	test_reset
			-- Test resetting writer.
		local
			writer: YAML_WRITER
		do
			create writer.make
			writer.write_value (create {YAML_STRING}.make ("test"))
			assert ("not_empty", not writer.output.is_empty)
			writer.reset
			assert ("empty_after_reset", writer.output.is_empty)
		end

	test_indent_size
			-- Test setting indent size.
		local
			writer: YAML_WRITER
		do
			create writer.make
			assert ("default_indent", writer.indent_size = 2)
			writer.set_indent_size (4)
			assert ("indent_changed", writer.indent_size = 4)
		end

	test_flow_style_setting
			-- Test flow style setting.
		local
			writer: YAML_WRITER
		do
			create writer.make
			assert ("default_block", not writer.use_flow_style)
			writer.set_use_flow_style (True)
			assert ("now_flow", writer.use_flow_style)
		end

	test_write_nested_structure
			-- Test writing nested structures.
		local
			writer: YAML_WRITER
			outer: YAML_MAPPING
			inner: YAML_SEQUENCE
		do
			create writer.make
			create outer.make
			create inner.make
			inner.extend (create {YAML_STRING}.make ("a"))
			inner.extend (create {YAML_STRING}.make ("b"))
			outer.put (inner, "items")
			writer.write_value (outer)
			assert ("has_items", writer.output.has_substring ("items"))
		end

	test_escape_special_chars
			-- Test escaping special characters.
		local
			writer: YAML_WRITER
			scalar: YAML_STRING
		do
			create writer.make
			create scalar.make ("line1%Nline2")
			scalar.set_style ({YAML_SCALAR}.Style_double_quoted)
			writer.write_value (scalar)
			assert ("has_escaped_newline", writer.output.has_substring ("\n"))
		end

end
