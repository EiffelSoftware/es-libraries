note
	description: "[
		BSON-JSON conversion tool application.
		Converts between BSON binary and JSON text formats.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	BSONJSON_APP

inherit
	ARGUMENTS_32

	BSON_CONSTANTS
		export
			{NONE} all
		end

create
	make

feature {NONE} -- Initialization

	make
			-- Main execution routine.
		local
			args_ok, is_pretty: BOOLEAN
			command, input_fn, output_fn: READABLE_STRING_GENERAL
			i,n: INTEGER
		do
--			command := "help"
			from
				i := 1
				n := argument_count
				args_ok := True
			until
				i > n or not args_ok
			loop
				if attached argument (i) as arg then
					if arg.starts_with ("-") then
						if arg.same_string ("--command") then
							i := i + 1
							if i > n then
								args_ok := False
							else
								command := argument (i)
							end
						elseif arg.same_string ("--help") or arg.same_string ("-h") then
							command := "help"
						elseif arg.same_string ("--pretty") then
							is_pretty := True
						elseif arg.same_string ("--debug") then
							is_debug := True
						elseif arg.starts_with ("--") then
							command := arg.substring (3, arg.count)
						else
							-- Ignore options ..
							io.error.put_string_32 ({STRING_32} "Ignoring " + arg + "%N")
						end
					elseif input_fn = Void then
						input_fn := arg
					elseif output_fn = Void then
						output_fn := arg
					else
						args_ok := False
					end
				end
				i := i + 1
			end
			if command = Void then
				if input_fn /= Void and output_fn /= Void then
					if input_fn.ends_with (".bson") then
						if output_fn.ends_with (".json") then
							command := "bson-to-json"
						else
							args_ok := False
						end
					elseif input_fn.ends_with (".json") then
						if output_fn.ends_with (".bson") then
							command := "json-to-bson"
						else
							args_ok := False
						end
					end
				end
			end
			if not args_ok or input_fn = Void or output_fn = Void or command = Void then
				display_usage
			elseif command.is_case_insensitive_equal ("help") then
				display_usage
			elseif command.is_case_insensitive_equal ("json-to-bson") then
				convert_json_to_bson (input_fn, output_fn)
			elseif command.is_case_insensitive_equal ("bson-to-json") then
				convert_bson_to_json (input_fn, output_fn, is_pretty)
			else
				display_usage
			end
		end

	is_debug: BOOLEAN

feature {NONE} -- Conversion

	convert_json_to_bson (a_json_file, a_bson_file: READABLE_STRING_GENERAL)
			-- Convert JSON file to BSON file.
		local
			json_parser: JSON_PARSER
			doc: BSON_DOCUMENT
			writer: BSON_WRITER
--			bytes: ARRAY [NATURAL_8]
			f, of: RAW_FILE
			j: STRING_8
			converter: BSONJSON_CONVERTER
			doc_count: INTEGER
		do
			create f.make_with_name (a_json_file)
			if f.exists then
				create j.make (f.count)
				from
					f.open_read
				until
					f.end_of_file or f.exhausted
				loop
					f.read_stream (1024)
					j.append (f.last_string)
				end
				f.close
			end
			if j /= Void then
				create json_parser.make
				json_parser.parse_string (j)
			end
			if json_parser = Void then
				io.error.put_string ("JSON not found%N")
			elseif json_parser.has_error then
				io.error.put_string ("JSON parsing error: " + json_parser.errors_as_string + "%N")
			else
				create converter.make
				if attached json_parser.parsed_json_value as jv then
					doc_count := 0
					create of.make_with_name (a_bson_file)
					of.create_read_write
					create {BSON_WRITER_TO_FILE} writer.make (of)
					if attached {JSON_ARRAY} jv as jarr then
						across
							jarr as e
						loop
							if attached {JSON_OBJECT} e as jo then
								create doc.make_empty
								converter.convert_json_to_bson (jv, doc)

								doc_count := doc_count + 1

								doc.accept (writer)
								io.put_string ("Converted JSON to BSON successfully (" + doc_count.out + "/" + jarr.count.out + ")%N")

--								create {BSON_WRITER_TO_FILE} writer.make
--								bytes := writer.to_bytes (doc)
--								save_bytes_to_file (a_bson_file.as_string_8, bytes)
--								io.put_string ("Converted JSON to BSON successfully.%N")
							end
						end
					else
						create doc.make_empty
						converter.convert_json_to_bson (jv, doc)

						doc_count := doc_count + 1

						doc.accept (writer)

--						create writer.make
--						bytes := writer.to_bytes (doc)
--						save_bytes_to_file (a_bson_file.as_string_8, bytes)
--						io.put_string ("Converted JSON to BSON successfully.%N")
					end
					of.close
					io.put_string ("Converted JSON to BSON successfully ("+ doc_count.out +" documents).%N")
				end
			end
		end

	convert_bson_to_json (a_bson_file, a_json_file: READABLE_STRING_GENERAL; is_pretty: BOOLEAN)
			-- Convert BSON file to JSON file.
		local
			doc: detachable BSON_DOCUMENT
			doc_count: INTEGER
			writer: JSON_STREAM_WRITER
			v: BSON_JSON_VISITOR
			s: STRING_8
			parser: BSON_PARSER
			in: FILE_NATURAL_8_INPUT_STREAM
		do
			create parser.make
			if is_debug then
				create {BSON_PARSER_DEBUG} parser.make
			end
			create in.make_with_filename (a_bson_file)

			from
				in.start
			until
				in.end_of_input
			loop
				doc := parser.parse_input (in)
				if attached doc and not parser.has_error then
					doc_count := doc_count + 1
					create s.make_empty
					if is_pretty then
						create {JSON_STREAM_TEXT_EXPANDED_WRITER} writer.make_with_text (s)
					else
						create {JSON_STREAM_TEXT_WRITER} writer.make_with_text (s)
					end
					create v.make_with_writer (writer)
					doc.accept (v)
					if doc_count = 1 then
						save_string_to_file (a_json_file, s)
					else
						if doc_count = 2 then
							prepend_string_to_file (a_json_file, "[%N")
						end
						append_string_to_file (a_json_file, ",%N")
						append_string_to_file (a_json_file, s)
					end

					io.put_string ("Converted BSON to JSON successfully.%N")
				else
					io.error.put_string ("BSON parsing error: " + parser.last_error.out + "%N")
				end
			end
			if doc_count > 1 then
				append_string_to_file (a_json_file, "%N]%N")
			end
		end

feature {NONE} -- File operations

	bytes_from_file (a_file: READABLE_STRING_GENERAL): ARRAY [NATURAL_8]
			-- Load bytes from file into `bytes'.
		local
			f: RAW_FILE
			count: INTEGER
		do
			create f.make_open_read (a_file)
			if f.exists and f.is_access_readable then
				count := f.count
				f.read_stream (count)
				-- For binary files, convert string to bytes
				create Result.make_filled (0, 1, count)
				bytes_make_from_string (f.last_string, Result)
				f.close
			else
				create Result.make_empty
			end
		rescue
			create Result.make_empty
		end

	bytes_make_from_string (s: STRING_8; bytes: ARRAY [NATURAL_8])
		local
			i: INTEGER
		do
			from i := 1 until i > s.count loop
				bytes.force (s [i].natural_32_code.to_natural_8, i)
				i := i + 1
			end
		end

	save_bytes_to_file (a_file: READABLE_STRING_8; bytes: ARRAY [NATURAL_8])
			-- Save bytes to file.
		local
			f: RAW_FILE
			mp: MANAGED_POINTER
		do
			create f.make_open_write (a_file)
			if f.exists and f.is_access_writable then
				create mp.make_from_array (bytes)
				f.put_managed_pointer (mp, 0, bytes.count)
			end
			f.close
		rescue
			io.error.put_string ("Failed to save file " + a_file + "%N")
		end

	save_string_to_file (a_file: READABLE_STRING_GENERAL; content: READABLE_STRING_8)
			-- Save string to file.
		local
			f: RAW_FILE
		do
			create f.make_open_write (a_file)
			if f.exists and f.is_access_writable then
				f.put_string (content)
			end
			f.close
		rescue
			io.error.put_string ("Failed to save file " + {UTF_CONVERTER}.utf_32_string_to_utf_8_string_8 (a_file) + "%N")
		end

	append_string_to_file (a_file: READABLE_STRING_GENERAL; content: READABLE_STRING_8)
			-- Save string to file.
		local
			f: RAW_FILE
		do
			create f.make_with_name (a_file)
			f.open_append
			if f.exists and f.is_access_writable then
				f.put_string (content)
			end
			f.close
		rescue
			io.error.put_string ("Failed to save file " + {UTF_CONVERTER}.utf_32_string_to_utf_8_string_8 (a_file) + "%N")
		end

	prepend_string_to_file (a_file: READABLE_STRING_GENERAL; content: READABLE_STRING_8)
			-- Save string to file.
		local
			oldf, f: RAW_FILE
		do
			create oldf.make_with_name (a_file)
			oldf.rename_file (oldf.path.appended ("-TMP").name)

			create f.make_with_name (a_file)
			f.create_read_write
			f.put_string (content)
			f.close

			f.append (oldf)
			oldf.delete
		rescue
			io.error.put_string ("Failed to save file " + {UTF_CONVERTER}.utf_32_string_to_utf_8_string_8 (a_file) + "%N")
		end

feature {NONE} -- Implementation

	display_usage
			-- Display usage information.
		do
			io.error.put_string ("Usage:%N")
			io.error.put_string ("  bsonjson <input.json> <output.bson>%N")
			io.error.put_string ("  bsonjson --json-to-bson <input.json> <output.bson>%N")
			io.error.put_string ("  bsonjson --command json-to-bson <input.json> <output.bson>%N")

			io.error.put_string ("  bsonjson <input.bson> <output.json> {--pretty}%N")
			io.error.put_string ("  bsonjson --bson-to-json <input.bson> <output.json> {--pretty}%N")
			io.error.put_string ("  bsonjson --command bson-to-json <input.bson> <output.json> {--pretty}%N")
		end

note
	copyright: "2026, Jocelyn Fiat and Eiffel Software"
	license: "MIT License"
end
