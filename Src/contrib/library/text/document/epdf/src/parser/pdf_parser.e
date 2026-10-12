note
	description: "[
		Parser for PDF objects.
		Converts token streams from PDF_LEXER into PDF object hierarchy.
		Implements ISO 32000-1:2008 §7.3 (Objects) parsing rules.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_PARSER

inherit
	PDF_WITH_LOGGING

create
	make

feature -- Initialization

	make (a_lexer: PDF_LEXER)
			-- Create parser with given lexer.
		do
			lexer := a_lexer
			current_token := lexer.next_token
		ensure
			lexer_set: lexer = a_lexer
		end

feature -- Access

	lexer: PDF_LEXER
			-- Lexer providing tokens.

	current_token: PDF_TOKEN
			-- Current token being processed.

feature -- Basic Operations

	parse_object: detachable PDF_OBJECT
			-- Parse next PDF object from token stream.
		do
			if current_token.token_type = {PDF_TOKEN}.type_null then
				Result := parse_null
			elseif current_token.token_type = {PDF_TOKEN}.type_boolean then
				Result := parse_boolean
			elseif current_token.token_type = {PDF_TOKEN}.type_number then
				Result := parse_number_or_reference
			elseif current_token.token_type = {PDF_TOKEN}.type_string then
				Result := parse_string
			elseif current_token.token_type = {PDF_TOKEN}.type_hex_string then
				Result := parse_hex_string
			elseif current_token.token_type = {PDF_TOKEN}.type_name then
				Result := parse_name
			elseif current_token.token_type = {PDF_TOKEN}.type_array_start then
				Result := parse_array
			elseif current_token.token_type = {PDF_TOKEN}.type_dict_start then
				Result := parse_dictionary
			end
		end

	parse_indirect_object: detachable PDF_INDIRECT_OBJECT
			-- Parse indirect object (obj_num gen_num obj ... endobj).
			-- Per ISO 32000-1:2008 §7.3.8, stream objects have the form:
			-- obj_num gen_num obj << dict >> stream ... endstream endobj
		local
			obj_num, gen_num: INTEGER
			obj_value: detachable PDF_OBJECT
			obj_id: PDF_OBJECT_ID
			stream_content: STRING_8
			stream_length: INTEGER
		do
			if current_token.token_type = {PDF_TOKEN}.type_number then
				obj_num := current_token.value.to_integer
				advance

				if current_token.token_type = {PDF_TOKEN}.type_number then
					gen_num := current_token.value.to_integer
					advance

					if current_token.token_type = {PDF_TOKEN}.type_obj_start then
						advance
						obj_value := parse_object

							-- Check if this is a stream object (dictionary followed by 'stream' keyword)
						if attached {PDF_DICTIONARY} obj_value as dict then
							if current_token.token_type = {PDF_TOKEN}.type_stream_start then
									-- This is a stream object - parse the stream content
								stream_length := get_stream_length (dict)
								
								if stream_length < 0 then
									-- Length is indirect reference, scan for endstream
									stream_content := read_stream_content_scanning
								else
									stream_content := read_stream_content (stream_length)
								end

									-- Create a PDF_STREAM with the dictionary and content
								create {PDF_STREAM} obj_value.make_with_dictionary (dict, stream_content)
								obj_value.logger := logger


									-- Advance past endstream token if present
								if current_token.token_type = {PDF_TOKEN}.type_stream_end then
									advance
								end
							end
						end

						if current_token.token_type = {PDF_TOKEN}.type_obj_end then
							advance
							if obj_value /= Void then
								create obj_id.make (obj_num, gen_num)
								create Result.make (obj_id, obj_value)
							end
						end
					end
				end
			end
		end

feature {NONE} -- Implementation: Parsing Primitives

	parse_null: PDF_NULL
			-- Parse null object.
		require
			at_null: current_token.token_type = {PDF_TOKEN}.type_null
		do
			create Result
			advance
		end

	parse_boolean: PDF_BOOLEAN
			-- Parse boolean object.
		require
			at_boolean: current_token.token_type = {PDF_TOKEN}.type_boolean
		do
			create Result.make (current_token.value.is_equal ("true"))
			advance
		end

	parse_number_or_reference: PDF_OBJECT
			-- Parse number or indirect reference.
			-- Indirect references have the form: obj_num gen_num R
		require
			at_number: current_token.token_type = {PDF_TOKEN}.type_number
		local
			first_num: STRING_8
			second_num: STRING_8
			obj_num, gen_num: INTEGER
			obj_id: PDF_OBJECT_ID
			num_val: REAL_64
			saved_token: PDF_TOKEN
		do
			first_num := current_token.value
			advance

			if current_token.token_type = {PDF_TOKEN}.type_number then
					-- Could be start of indirect reference: obj_num gen_num R
				second_num := current_token.value
				saved_token := current_token
				advance

				if current_token.token_type = {PDF_TOKEN}.type_ref then
						-- It IS an indirect reference
					obj_num := first_num.to_integer
					gen_num := second_num.to_integer
					create obj_id.make (obj_num, gen_num)
					create {PDF_REFERENCE} Result.make (obj_id)
					advance
				else
						-- NOT a reference - just two consecutive numbers
						-- Return first number, push saved_token back as pending
					pending_token := current_token
					current_token := saved_token
					if first_num.has ('.') then
						num_val := first_num.to_real_64
					else
						num_val := first_num.to_integer.to_double
					end
					create {PDF_NUMBER} Result.make (num_val)
				end
			else
					-- Just a single number
				if first_num.has ('.') then
					num_val := first_num.to_real_64
				else
					num_val := first_num.to_integer.to_double
				end
				create {PDF_NUMBER} Result.make (num_val)
			end
		end

	parse_string: PDF_STRING
			-- Parse string object.
		require
			at_string: current_token.token_type = {PDF_TOKEN}.type_string
		do
			create Result.make_literal (current_token.value)
			advance
		end

	parse_hex_string: PDF_STRING
			-- Parse hexadecimal string object.
		require
			at_hex_string: current_token.token_type = {PDF_TOKEN}.type_hex_string
		do
			create Result.make_hex (hex_to_bytes (current_token.value))
			advance
		end

	hex_to_bytes (hex_str: STRING_8): STRING_8
			-- Convert a hexadecimal string to raw binary bytes.
		local
			i: INTEGER
			val: INTEGER
			c1, c2: CHARACTER
		do
			create Result.make (hex_str.count // 2 + (hex_str.count \\ 2))
			from
				i := 1
			until
				i > hex_str.count
			loop
				c1 := hex_str.item (i)
				if i + 1 <= hex_str.count then
					c2 := hex_str.item (i + 1)
					val := hex_val (c1) * 16 + hex_val (c2)
					i := i + 2
				else
					val := hex_val (c1) * 16
					i := i + 1
				end
				Result.append_character (val.to_character_8)
			end
		end

	hex_val (c: CHARACTER): INTEGER
			-- Integer value of hexadecimal character.
		require
			valid_hex: (c >= '0' and c <= '9') or (c >= 'a' and c <= 'f') or (c >= 'A' and c <= 'F')
		do
			if c >= '0' and c <= '9' then
				Result := c.code - ('0').code
			elseif c >= 'a' and c <= 'f' then
				Result := c.code - ('a').code + 10
			else
				Result := c.code - ('A').code + 10
			end
		ensure
			valid_result: Result >= 0 and Result <= 15
		end

	parse_name: PDF_NAME
			-- Parse name object.
		require
			at_name: current_token.token_type = {PDF_TOKEN}.type_name
		do
			create Result.make (current_token.value)
			advance
		end

	parse_array: PDF_ARRAY
			-- Parse array object.
		require
			at_array_start: current_token.token_type = {PDF_TOKEN}.type_array_start
		local
			element: detachable PDF_OBJECT
		do
			create Result.make_empty
			advance  -- Skip '['

			from
			until
				current_token.token_type = {PDF_TOKEN}.type_array_end or current_token.is_eof
			loop
				element := parse_object
				if element /= Void then
					Result.add (element)
				end
			end

			if current_token.token_type = {PDF_TOKEN}.type_array_end then
				advance  -- Skip ']'
			end
		end

	parse_dictionary: PDF_DICTIONARY
			-- Parse dictionary object.
		require
			at_dict_start: current_token.token_type = {PDF_TOKEN}.type_dict_start
		local
			key: detachable PDF_NAME
			value: detachable PDF_OBJECT
		do
			create Result.make_empty
			advance  -- Skip '<<'

			from
			until
				current_token.token_type = {PDF_TOKEN}.type_dict_end or current_token.is_eof
			loop
				if current_token.token_type = {PDF_TOKEN}.type_name then
					key := parse_name

					if key /= Void then
						value := parse_object
						if value /= Void then
							Result.put (value, key.value)
						end
					end
				else
					advance
				end
			end

			if current_token.token_type = {PDF_TOKEN}.type_dict_end then
				advance  -- Skip '>>'
			end
		end

feature {NONE} -- Implementation: Token Management

	pending_token: detachable PDF_TOKEN
			-- Token pushed back during lookahead (for reference disambiguation).

	advance
			-- Move to next token.
		do
			if attached pending_token as pt then
				current_token := pt
				pending_token := Void
			else
				current_token := lexer.next_token
			end
		end

feature {NONE} -- Implementation: Stream Parsing

	get_stream_length (dict: PDF_DICTIONARY): INTEGER
			-- Get the /Length value from a stream dictionary.
			-- Per ISO 32000-1:2008 §7.3.8, Length is required.
			-- If Length is an indirect reference (common in PDFs), we scan for 'endstream'.
		local
			length_value: detachable PDF_OBJECT
		do
			length_value := dict.item ("Length")
			if attached {PDF_NUMBER} length_value as len then
				Result := len.real_value.truncated_to_integer
			elseif attached {PDF_REFERENCE} length_value as len_ref then
				-- Length is an indirect reference - we can't resolve it here
				-- Set Result to -1 to signal we need to scan for endstream
				log_info ("[get_stream_length] /Length is indirect reference " + len_ref.object_id.object_number.out + " 0 R, will scan for endstream%N")
				Result := -1
			else
				log_info ("[get_stream_length] No /Length found in stream dictionary%N")
				Result := 0
			end
		end

	read_stream_content_scanning: STRING_8
			-- Read stream content by scanning for 'endstream' keyword.
			-- Used when /Length is an indirect reference we can't resolve.
		local
			src: PDF_BYTE_SOURCE
			buffer: STRING_8
			ch: NATURAL_8
			endstream_found: BOOLEAN
		do
			src := lexer.source
			create buffer.make (4096)
			
			-- Skip EOL after 'stream' keyword
			if not src.end_of_source then
				ch := src.peek_byte
				if ch = 0x0D then
					ch := src.read_byte
					if not src.end_of_source and then src.peek_byte = 0x0A then
						ch := src.read_byte
					end
				elseif ch = 0x0A then
					ch := src.read_byte
				end
			end
			
			-- Read until we find 'endstream' keyword
			from
				endstream_found := False
			until
				src.end_of_source or endstream_found
			loop
				ch := src.read_byte
				buffer.append_character (ch.to_character_8)
				
				-- Check if buffer ends with 'endstream'
				if buffer.count >= 9 then
					if buffer.substring (buffer.count - 8, buffer.count).is_equal ("endstream") then
						endstream_found := True
						-- Remove 'endstream' from buffer
						buffer := buffer.substring (1, buffer.count - 9)
						-- Also remove trailing EOL if present
						if buffer.count > 0 and then (buffer.item (buffer.count) = '%N' or buffer.item (buffer.count) = '%R') then
							buffer := buffer.substring (1, buffer.count - 1)
						end
						if buffer.count > 0 and then buffer.item (buffer.count) = '%R' then
							buffer := buffer.substring (1, buffer.count - 1)
						end
					end
				end
			end
			
			Result := buffer
			log_info ("[read_stream_content_scanning] Scanned " + Result.count.out + " bytes until endstream%N")
			
			-- Re-sync the lexer: source position is now after 'endstream'
			-- Need to advance to get endstream token, then advance again for endobj
			advance  -- This should now pick up 'endobj' since we already consumed 'endstream'
		end

	read_stream_content (a_length: INTEGER): STRING_8
			-- Read stream content of given length from source.
			-- The source should be positioned right after the 'stream' keyword.
			-- Per ISO 32000-1:2008 §7.3.8.1, stream keyword is followed by EOL then content.
			-- EOL can be: CR (0x0D), LF (0x0A), or CR+LF (0x0D 0x0A).
		require
			length_valid: a_length >= 0
		local
			i: INTEGER
			ch: NATURAL_8
			src: PDF_BYTE_SOURCE
			available_bytes: INTEGER
			actual_length: INTEGER
		do
			src := lexer.source

				-- Calculate available bytes from current position
			available_bytes := src.byte_count - src.position

				-- Validate length against available bytes
			if a_length > available_bytes then
				log_info ("[read_stream_content] WARNING: Stream /Length (" + a_length.out +
					       ") exceeds available bytes (" + available_bytes.out + "). " +
					       "Reading " + available_bytes.out + " bytes instead.%N")
				actual_length := available_bytes
			else
				actual_length := a_length
			end

			create Result.make (actual_length)

				-- Skip exactly ONE EOL marker after 'stream' keyword
				-- Per ISO 32000-1:2008 §7.3.8.1, only one EOL should be skipped
			if not src.end_of_source then
				ch := src.peek_byte
				if ch = 0x0D then
						-- CR - check if followed by LF for CR+LF
					ch := src.read_byte
					if not src.end_of_source and then src.peek_byte = 0x0A then
							-- CR+LF - skip the LF too
						ch := src.read_byte
					end
				elseif ch = 0x0A then
						-- LF alone
					ch := src.read_byte
				end
					-- Note: We do NOT skip spaces (0x20) as they are part of stream content
			end

				-- Read the stream content based on validated length
			from
				i := 1
			until
				i > actual_length or src.end_of_source
			loop
				Result.append_character (src.read_byte.to_character_8)
				i := i + 1
			end

				-- Skip to 'endstream' token - advance lexer to next token
				-- after reading raw bytes
			advance
		end

end
