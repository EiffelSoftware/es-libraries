note
	description: "Converter between YAML and JSON formats."
	date: "$Date$"
	revision: "$Revision$"

class
	YAML_JSON_CONVERTER

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize converter.
		do
			create errors.make (5)
			pretty_print := False
			indent_size := 2
		ensure
			no_errors: errors.is_empty
		end

feature -- Access

	errors: ARRAYED_LIST [STRING_32]
			-- Conversion errors.

	pretty_print: BOOLEAN
			-- Should output be pretty-printed?

	indent_size: INTEGER
			-- Indentation size for pretty printing.

feature -- Status report

	has_errors: BOOLEAN
			-- Were there any errors during conversion?
		do
			Result := not errors.is_empty
		end

feature -- Settings

	set_pretty_print (a_value: BOOLEAN)
			-- Set `pretty_print` to `a_value`.
		do
			pretty_print := a_value
		ensure
			pretty_print_set: pretty_print = a_value
		end

	set_indent_size (a_size: INTEGER)
			-- Set `indent_size` to `a_size`.
		require
			positive: a_size > 0
		do
			indent_size := a_size
		ensure
			indent_size_set: indent_size = a_size
		end

feature -- Conversion

	yaml_to_json (a_yaml: STRING_32): detachable STRING
			-- Convert YAML string to JSON string.
		local
			yaml_parser: YAML_PARSER
			yaml_value: detachable YAML_VALUE
			json_value: detachable JSON_VALUE
		do
			reset
			create yaml_parser.make
			yaml_value := yaml_parser.parse_string (a_yaml)
			if yaml_value /= Void then
				json_value := yaml_to_json_value (yaml_value)
				if json_value /= Void then
					Result := json_value_to_string (json_value)
				else
					errors.extend ({STRING_32} "Failed to convert YAML to JSON value")
				end
			else
				errors.extend ({STRING_32} "Failed to parse YAML")
				if attached yaml_parser.errors as errs then
					across errs as err loop
						errors.extend (err)
					end
				end
			end
		end

	json_to_yaml (a_json: STRING_32): detachable STRING_32
			-- Convert JSON string to YAML string.
		local
			json_parser: JSON_PARSER
			json_value: detachable JSON_VALUE
			yaml_value: detachable YAML_VALUE
			writer: YAML_WRITER
		do
			reset
			create json_parser.make_with_string (a_json.to_string_8)
			json_parser.parse_content
			if json_parser.is_valid then
				json_value := json_parser.parsed_json_value
				if json_value /= Void then
					yaml_value := json_to_yaml_value (json_value)
					if yaml_value /= Void then
						create writer.make
						writer.set_indent_size (indent_size)
						writer.write_value (yaml_value)
						Result := writer.output
					else
						errors.extend ({STRING_32} "Failed to convert JSON to YAML value")
					end
				else
					errors.extend ({STRING_32} "JSON parser returned no value")
				end
			else
				errors.extend ({STRING_32} "Failed to parse JSON")
				errors.extend (json_parser.errors_as_string.to_string_32)
			end
		end

	yaml_to_yaml (a_yaml: STRING_32): detachable STRING_32
			-- Reformat YAML string (parse and rewrite with standard formatting).
		local
			yaml_parser: YAML_PARSER
			yaml_value: detachable YAML_VALUE
			writer: YAML_WRITER
		do
			reset
			create yaml_parser.make
			yaml_value := yaml_parser.parse_string (a_yaml)
			if yaml_value /= Void then
				create writer.make
				writer.set_indent_size (indent_size)
				writer.write_value (yaml_value)
				Result := writer.output
			else
				errors.extend ({STRING_32} "Failed to parse YAML")
				if attached yaml_parser.errors as errs then
					across errs as err loop
						errors.extend (err)
					end
				end
			end
		end

	json_to_json (a_json: STRING_32): detachable STRING
			-- Reformat JSON string (parse and rewrite with standard formatting).
		local
			json_parser: JSON_PARSER
			json_value: detachable JSON_VALUE
		do
			reset
			create json_parser.make_with_string (a_json.to_string_8)
			json_parser.parse_content
			if json_parser.is_valid then
				json_value := json_parser.parsed_json_value
				if json_value /= Void then
					Result := json_value_to_string (json_value)
				else
					errors.extend ({STRING_32} "JSON parser returned no value")
				end
			else
				errors.extend ({STRING_32} "Failed to parse JSON")
				errors.extend (json_parser.errors_as_string.to_string_32)
			end
		end

feature {NONE} -- YAML to JSON Conversion

	yaml_to_json_value (a_yaml: YAML_VALUE): detachable JSON_VALUE
			-- Convert YAML value to JSON value.
		do
			if a_yaml.is_scalar and then attached {YAML_SCALAR} a_yaml as s then
				Result := yaml_scalar_to_json (s)
			elseif attached {YAML_SEQUENCE} a_yaml as seq then
				Result := yaml_sequence_to_json (seq)
			elseif attached {YAML_MAPPING} a_yaml as map then
				Result := yaml_mapping_to_json (map)
			else
				check known_value_type: False end
			end
		end

	yaml_scalar_to_json (a_scalar: YAML_SCALAR): JSON_VALUE
			-- Convert YAML scalar to JSON value.
		do
			if a_scalar.is_null then
				create {JSON_NULL} Result
			elseif a_scalar.is_boolean then
				create {JSON_BOOLEAN} Result.make (a_scalar.to_boolean)
			elseif a_scalar.is_integer then
				create {JSON_NUMBER} Result.make_integer (a_scalar.to_integer_64)
			elseif a_scalar.is_real then
				create {JSON_NUMBER} Result.make_real (a_scalar.to_real_64)
			else
				create {JSON_STRING} Result.make_from_string_32 (a_scalar.to_string_value)
			end
		ensure
			result_attached: Result /= Void
		end

	yaml_sequence_to_json (a_sequence: YAML_SEQUENCE): JSON_ARRAY
			-- Convert YAML sequence to JSON array.
		local
			json_item: detachable JSON_VALUE
		do
			create Result.make (a_sequence.count)
			across a_sequence as item loop
				json_item := yaml_to_json_value (item)
				if json_item /= Void then
					Result.extend (json_item)
				else
					Result.extend (create {JSON_NULL})
				end
			end
		ensure
			result_attached: Result /= Void
		end

	yaml_mapping_to_json (a_mapping: YAML_MAPPING): JSON_OBJECT
			-- Convert YAML mapping to JSON object.
		local
			key: YAML_VALUE
			key_string: STRING_32
			json_value: detachable JSON_VALUE
		do
			create Result.make_with_capacity (a_mapping.count)
			across
				a_mapping as value
			loop
				key := @value.key
				if attached {YAML_SCALAR} key as scalar_key then
					key_string := scalar_key.to_string_value
				else
					key_string := key.representation
				end
				json_value := yaml_to_json_value (value)
				if json_value /= Void then
					Result.put (json_value, key_string)
				else
					Result.put (create {JSON_NULL}, key_string)
				end
			end
		ensure
			result_attached: Result /= Void
		end

feature {NONE} -- JSON to YAML Conversion

	json_to_yaml_value (a_json: JSON_VALUE): detachable YAML_VALUE
			-- Convert JSON value to YAML value.
		do
			if attached {JSON_NULL} a_json then
				create {YAML_NULL} Result
			elseif attached {JSON_BOOLEAN} a_json as jb then
				create {YAML_BOOLEAN} Result.make (jb.item)
			elseif attached {JSON_NUMBER} a_json as jn then
				Result := json_number_to_yaml (jn)
			elseif attached {JSON_STRING} a_json as js then
				create {YAML_STRING} Result.make_plain (js.unescaped_string_32)
			elseif attached {JSON_ARRAY} a_json as ja then
				Result := json_array_to_yaml (ja)
			elseif attached {JSON_OBJECT} a_json as jo then
				Result := json_object_to_yaml (jo)
			end
		end

	json_number_to_yaml (a_number: JSON_NUMBER): YAML_SCALAR
			-- Convert JSON number to YAML scalar.
		local
			repr: STRING
		do
			repr := a_number.representation
			if repr.has ('.') or repr.has ('e') or repr.has ('E') then
				create {YAML_REAL} Result.make (a_number.real_64_item)
			else
				create {YAML_INTEGER} Result.make (a_number.integer_64_item)
			end
		ensure
			result_attached: Result /= Void
		end

	json_array_to_yaml (a_array: JSON_ARRAY): YAML_SEQUENCE
			-- Convert JSON array to YAML sequence.
		local
			yaml_item: detachable YAML_VALUE
		do
			create Result.make
			across a_array as item loop
				yaml_item := json_to_yaml_value (item)
				if yaml_item /= Void then
					Result.extend (yaml_item)
				else
					Result.extend (create {YAML_NULL})
				end
			end
		ensure
			result_attached: Result /= Void
		end

	json_object_to_yaml (a_object: JSON_OBJECT): YAML_MAPPING
			-- Convert JSON object to YAML mapping.
		local
			yaml_value: detachable YAML_VALUE
			key_scalar: YAML_STRING
		do
			create Result.make
			across a_object as entry loop
				create key_scalar.make_plain (@ entry.key.unescaped_string_32)
				yaml_value := json_to_yaml_value (entry)
				if yaml_value /= Void then
					Result.put (yaml_value, key_scalar)
				else
					Result.put (create {YAML_NULL}, key_scalar)
				end
			end
		ensure
			result_attached: Result /= Void
		end

feature {NONE} -- JSON Output

	json_value_to_string (a_json: JSON_VALUE): STRING
			-- Convert JSON value to string.
		do
			if pretty_print then
				Result := pretty_json_string (a_json)
			else
				Result := a_json.representation
			end
		ensure
			result_attached: Result /= Void
		end

	pretty_json_string (a_json: JSON_VALUE): STRING
			-- Pretty-print JSON value.
		local
			visitor: JSON_PRETTY_STRING_VISITOR
			output_string: STRING
			indentation_string: STRING
		do
			create output_string.make_empty
			create visitor.make (output_string)
				-- Create indentation string based on indent_size
			create indentation_string.make_filled (' ', indent_size)
			visitor.set_indentation_step (indentation_string)
			a_json.accept (visitor)
			Result := output_string
		ensure
			result_attached: Result /= Void
		end

feature {NONE} -- Implementation

	reset
			-- Reset converter state.
		do
			errors.wipe_out
		ensure
			no_errors: errors.is_empty
		end

invariant
	errors_attached: errors /= Void
	positive_indent: indent_size > 0

end
