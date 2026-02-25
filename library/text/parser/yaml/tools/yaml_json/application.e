note
	description: "YAML to JSON and JSON to YAML converter tool."
	date: "$Date$"
	revision: "$Revision$"

class
	APPLICATION

inherit
	ARGUMENTS_32

create
	make

feature {NONE} -- Initialization

	make
			-- Run the application.
		local
			converter: YAML_JSON_CONVERTER
		do
			create converter.make
			if argument_count < 1 then
				print_usage
			else
				process_arguments (converter)
			end
		end

feature {NONE} -- Implementation

	process_arguments (a_converter: YAML_JSON_CONVERTER)
			-- Process command-line arguments.
		local
			command: STRING_32
			input_file: detachable STRING_32
			output_file: detachable STRING_32
			pretty: BOOLEAN
			i: INTEGER
			arg: STRING_32
		do
			pretty := has_option ("pretty") or has_option ("p")

				-- Parse non-option arguments
			from
				i := 1
			until
				i > argument_count
			loop
				arg := argument (i)
				if not arg.starts_with ("-") then
					if command = Void then
						command := arg
					elseif input_file = Void then
						input_file := arg
					elseif output_file = Void then
						output_file := arg
					end
				end
				i := i + 1
			end

			if command = Void then
				print_usage
			elseif command.same_string ("yaml2json") or command.same_string ("y2j") then
				if input_file /= Void then
					convert_yaml_to_json (a_converter, input_file, output_file, pretty)
				else
					io.put_string ("Error: Input file required%N")
					print_usage
				end
			elseif command.same_string ("json2yaml") or command.same_string ("j2y") then
				if input_file /= Void then
					convert_json_to_yaml (a_converter, input_file, output_file, pretty)
				else
					io.put_string ("Error: Input file required%N")
					print_usage
				end
			elseif command.same_string ("yaml2yaml") or command.same_string ("y2y") or command.same_string ("yaml") then
				if input_file /= Void then
					convert_yaml_to_yaml (a_converter, input_file, output_file)
				else
					io.put_string ("Error: Input file required%N")
					print_usage
				end
			elseif command.same_string ("json2json") or command.same_string ("j2j") or command.same_string ("json") then
				if input_file /= Void then
					convert_json_to_json (a_converter, input_file, output_file, pretty)
				else
					io.put_string ("Error: Input file required%N")
					print_usage
				end
			elseif command.same_string ("--help") or command.same_string ("-h") or command.same_string ("help") then
				print_usage
			else
				io.put_string ("Unknown command: ")
				io.put_string_32 (command)
				io.put_new_line
				print_usage
			end
		end

	convert_yaml_to_json (a_converter: YAML_JSON_CONVERTER; a_input: STRING_32; a_output: detachable STRING_32; a_pretty: BOOLEAN)
			-- Convert YAML file to JSON.
		local
			yaml_content: detachable STRING_32
			json_output: detachable STRING
		do
			yaml_content := read_file (a_input)
			if yaml_content /= Void then
				a_converter.set_pretty_print (a_pretty)
				json_output := a_converter.yaml_to_json (yaml_content)
				if json_output /= Void then
					if a_output /= Void then
						write_file (a_output, json_output)
						io.put_string ("Converted ")
						io.put_string_32 (a_input)
						io.put_string (" to ")
						io.put_string_32 (a_output)
						io.put_new_line
					else
						io.put_string (json_output)
						io.put_new_line
					end
				else
					io.put_string ("Error converting YAML to JSON")
					io.put_new_line
					print_errors (a_converter)
				end
			else
				io.put_string ("Error: Cannot read file ")
				io.put_string_32 (a_input)
				io.put_new_line
			end
		end

	convert_json_to_yaml (a_converter: YAML_JSON_CONVERTER; a_input: STRING_32; a_output: detachable STRING_32; a_pretty: BOOLEAN)
			-- Convert JSON file to YAML.
		local
			json_content: detachable STRING_32
			yaml_output: detachable STRING_32
		do
			json_content := read_file (a_input)
			if json_content /= Void then
				a_converter.set_pretty_print (a_pretty)
				yaml_output := a_converter.json_to_yaml (json_content)
				if yaml_output /= Void then
					if a_output /= Void then
						write_file_32 (a_output, yaml_output)
						io.put_string ("Converted ")
						io.put_string_32 (a_input)
						io.put_string (" to ")
						io.put_string_32 (a_output)
						io.put_new_line
					else
						io.put_string_32 (yaml_output)
						io.put_new_line
					end
				else
					io.put_string ("Error converting JSON to YAML")
					io.put_new_line
					print_errors (a_converter)
				end
			else
				io.put_string ("Error: Cannot read file ")
				io.put_string_32 (a_input)
				io.put_new_line
			end
		end

	convert_yaml_to_yaml (a_converter: YAML_JSON_CONVERTER; a_input: STRING_32; a_output: detachable STRING_32)
			-- Reformat YAML file.
		local
			yaml_content: detachable STRING_32
			yaml_output: detachable STRING_32
		do
			yaml_content := read_file (a_input)
			if yaml_content /= Void then
				yaml_output := a_converter.yaml_to_yaml (yaml_content)
				if yaml_output /= Void then
					if a_output /= Void then
						write_file_32 (a_output, yaml_output)
						io.put_string ("Reformatted ")
						io.put_string_32 (a_input)
						io.put_string (" to ")
						io.put_string_32 (a_output)
						io.put_new_line
					else
						io.put_string_32 (yaml_output)
						io.put_new_line
					end
				else
					io.put_string ("Error reformatting YAML")
					io.put_new_line
					print_errors (a_converter)
				end
			else
				io.put_string ("Error: Cannot read file ")
				io.put_string_32 (a_input)
				io.put_new_line
			end
		end

	convert_json_to_json (a_converter: YAML_JSON_CONVERTER; a_input: STRING_32; a_output: detachable STRING_32; a_pretty: BOOLEAN)
			-- Reformat JSON file.
		local
			json_content: detachable STRING_32
			json_output: detachable STRING
		do
			json_content := read_file (a_input)
			if json_content /= Void then
				a_converter.set_pretty_print (a_pretty)
				json_output := a_converter.json_to_json (json_content)
				if json_output /= Void then
					if a_output /= Void then
						write_file (a_output, json_output)
						io.put_string ("Reformatted ")
						io.put_string_32 (a_input)
						io.put_string (" to ")
						io.put_string_32 (a_output)
						io.put_new_line
					else
						io.put_string (json_output)
						io.put_new_line
					end
				else
					io.put_string ("Error reformatting JSON")
					io.put_new_line
					print_errors (a_converter)
				end
			else
				io.put_string ("Error: Cannot read file ")
				io.put_string_32 (a_input)
				io.put_new_line
			end
		end

	read_file (a_path: STRING_32): detachable STRING_32
			-- Read content from file at `a_path`.
		local
			file: PLAIN_TEXT_FILE
			content: STRING
		do
			create file.make_with_name (a_path)
			if file.exists and then file.is_readable then
				file.open_read
				create content.make (file.count.to_integer_32)
				from
				until
					file.exhausted
				loop
					file.read_line
					content.append (file.last_string)
					content.append_character ('%N')
				end
				file.close
				create Result.make_from_string (content)
			end
		end

	write_file (a_path: STRING_32; a_content: STRING)
			-- Write `a_content` to file at `a_path`.
		local
			file: PLAIN_TEXT_FILE
		do
			create file.make_with_name (a_path)
			file.open_write
			file.put_string (a_content)
			file.close
		end

	write_file_32 (a_path: STRING_32; a_content: STRING_32)
			-- Write `a_content` to file at `a_path`.
		local
			file: PLAIN_TEXT_FILE
		do
			create file.make_with_name (a_path)
			file.open_write
			file.put_string_32 (a_content)
			file.close
		end

	has_option (a_option: STRING): BOOLEAN
			-- Does command line contain option `a_option`?
		local
			i: INTEGER
			arg: STRING_32
		do
			from
				i := 1
			until
				i > argument_count or Result
			loop
				arg := argument (i)
				if arg.same_string ("--" + a_option) or arg.same_string ("-" + a_option.substring (1, 1)) then
					Result := True
				end
				i := i + 1
			end
		end

	print_errors (a_converter: YAML_JSON_CONVERTER)
			-- Print converter errors.
		do
			across a_converter.errors as err loop
				io.put_string ("  - ")
				io.put_string_32 (err)
				io.put_new_line
			end
		end

	print_usage
			-- Print usage information.
		do
			io.put_string ("YAML/JSON Converter Tool%N")
			io.put_string ("========================%N%N")
			io.put_string ("Usage:%N")
			io.put_string ("  yaml_json <command> <input_file> [output_file] [options]%N%N")
			io.put_string ("Commands:%N")
			io.put_string ("  yaml2json, y2j    Convert YAML to JSON%N")
			io.put_string ("  json2yaml, j2y    Convert JSON to YAML%N")
			io.put_string ("  yaml2yaml, y2y    Reformat YAML (pretty print)%N")
			io.put_string ("  json2json, j2j    Reformat JSON%N")
			io.put_string ("  --help, -h        Show this help message%N%N")
			io.put_string ("Options:%N")
			io.put_string ("  --pretty, -p      Pretty print output (for JSON output)%N%N")
			io.put_string ("Examples:%N")
			io.put_string ("  yaml_json yaml2json config.yaml config.json --pretty%N")
			io.put_string ("  yaml_json json2yaml data.json data.yaml%N")
			io.put_string ("  yaml_json y2j input.yaml                   (output to stdout)%N")
			io.put_string ("  yaml_json yaml2yaml messy.yaml clean.yaml  (reformat YAML)%N")
			io.put_string ("  yaml_json json2json ugly.json pretty.json --pretty%N")
		end

end
