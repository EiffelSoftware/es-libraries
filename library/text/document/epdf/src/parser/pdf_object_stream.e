note
	description: "[
		Represents an Object Stream (Type 2) containing compressed objects.
		See ISO 32000-1:2008 §7.5.7 Object Streams.
	]"
	spec_reference: "ISO 32000-1:2008 §7.5.7 (Object Streams)"
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_OBJECT_STREAM

inherit
	PDF_WITH_LOGGING

create
	make

feature -- Initialization

	make (a_stream: PDF_STREAM; a_decoder: PDF_FLATE_DECODER)
			-- Create object stream from a stream object.
		require
			stream_valid: a_stream /= Void
			decoder_valid: a_decoder /= Void
		do
			stream := a_stream
			decoder := a_decoder
			parse_header
		end

feature -- Access

	count: INTEGER
			-- Number of objects in stream (/N).
		do
			if attached {PDF_NUMBER} stream.stream_dictionary.item ("N") as n then
				Result := n.int_value
			end
		end

	first_offset: INTEGER
			-- Byte offset of first object in decoded stream (/First).
		do
			if attached {PDF_NUMBER} stream.stream_dictionary.item ("First") as f then
				Result := f.int_value
			end
		end

	object_at (index: INTEGER): detachable PDF_OBJECT
			-- Get object at given index (0-based).
			-- Index refers to the position in the object stream (i.e., it's the i-th object in the stream).
			-- Note: 'index' corresponds to the index in the 'offsets' list (0-based externally, 1-based internal list).
		require
			valid_index: index >= 0 and index < count
		local
			obj_offset: INTEGER
			lexer: PDF_LEXER
			parser: PDF_PARSER
			byte_source: PDF_STRING_BYTE_SOURCE
			data: STRING_8
			absolute_offset: INTEGER

		do
			data := decoded_content
			if data = Void then
				decode_content
				data := decoded_content
			end

			if attached data as content then
					-- offsets is 1-based list, index is 0-based
				if index + 1 <= offsets.count then
					obj_offset := offsets [index + 1]

					absolute_offset := first_offset + obj_offset

					if absolute_offset < content.count then
						create byte_source.make (content)
						create lexer.make (byte_source)
						byte_source.set_position (absolute_offset)
						create parser.make (lexer)
						parser.logger := logger
						if attached parser.parse_object as obj then
							Result := obj
						end
					end
				end
			end
		end

feature {NONE} -- Implementation

	stream: PDF_STREAM
	decoder: PDF_FLATE_DECODER
	decoded_content: detachable STRING_8
	offsets: ARRAYED_LIST [INTEGER] -- Stores byte offsets relative to first_offset
	object_numbers: ARRAYED_LIST [INTEGER] -- Stores object numbers

	decode_content
			-- Decode stream content, handling FlateDecode, ASCII85Decode, ASCIIHexDecode with optional predictor.
			-- Per ISO 32000-1:2008 §7.4.4 and §7.5.7.
		local
			raw: STRING_8
			predictor, columns: INTEGER
			filter_name: detachable PDF_NAME
		do
			raw := stream.content
			if raw /= Void then
					-- Check for filter
				if attached {PDF_ARRAY} stream.stream_dictionary.item ("Filter") as filter_array then
					if filter_array.count >= 1 and then attached {PDF_NAME} filter_array.item (1) as first_filter then
						filter_name := first_filter
					end
				elseif attached {PDF_NAME} stream.stream_dictionary.item ("Filter") as single_filter then
					filter_name := single_filter
				end

				if attached filter_name as f and then f.value.is_equal ("FlateDecode") then
						-- Check for /DecodeParms with Predictor and Columns
					predictor := 1  -- Default: no prediction
					columns := 1    -- Default width
					if attached {PDF_DICTIONARY} stream.stream_dictionary.item ("DecodeParms") as parms then
						if attached {PDF_NUMBER} parms.item ("Predictor") as pred then
							predictor := pred.int_value
						end
						if attached {PDF_NUMBER} parms.item ("Columns") as cols then
							columns := cols.int_value
						end
					end

						-- Decode with or without predictor
					if predictor >= 10 then
							-- PNG predictor (10-15)
						decoded_content := decoder.decode_with_predictor (raw, predictor, columns)
					else
							-- No predictor or TIFF predictor 2 (handled as no predictor)
						decoded_content := decoder.decode (raw)
					end

						-- Mark stream as decompressed for proper serialization
					if decoded_content /= Void then
						stream.mark_as_decompressed ("FlateDecode")
					end

						-- Fail-fast: Check for decompression errors
					if decoded_content = Void and then decoder.has_error_message then
						log_info ("[PDF_OBJECT_STREAM] FATAL: FlateDecode decompression failed%N")
						if attached decoder.last_error_message as err then
							log_info ("[PDF_OBJECT_STREAM] Error: " + err + "%N")
						end
						check flatedecode_succeeded: False then
							-- Fail fast instead of silent corruption
						end
					end
				elseif attached filter_name as f and then f.value.is_equal ("ASCII85Decode") then
						-- ASCII85Decode filter
					decoded_content := (create {PDF_ASCII85_DECODER}).decode (raw)
					
						-- Mark stream as decompressed for proper serialization
					if decoded_content /= Void then
						stream.mark_as_decompressed ("ASCII85Decode")
					end
				elseif attached filter_name as f and then f.value.is_equal ("ASCIIHexDecode") then
						-- ASCIIHexDecode filter
					decoded_content := (create {PDF_ASCIIHEX_DECODER}).decode (raw)
					
						-- Mark stream as decompressed for proper serialization
					if decoded_content /= Void then
						stream.mark_as_decompressed ("ASCIIHexDecode")
					end
				elseif attached filter_name as f and then f.value.is_equal ("LZWDecode") then
					-- LZWDecode filter (legacy PDFs per ISO 32000-1:2008 §7.4.4)
				decoded_content := decode_lzw_content (raw, predictor, columns)
				
					-- Mark stream as decompressed for proper serialization
				if decoded_content /= Void then
					stream.mark_as_decompressed ("LZWDecode")
				end
				elseif attached filter_name as f then
						-- Unsupported filter
					log_info ("[PDF_OBJECT_STREAM] FATAL: Unsupported filter: " + f.value + "%N")
					log_info ("[PDF_OBJECT_STREAM] Supported filters: FlateDecode, ASCII85Decode, ASCIIHexDecode, LZWDecode%N")
					check supported_filter: False then
						-- Fail fast for unsupported filters
					end
				else
						-- No filter - use raw data
					decoded_content := raw
				end
			end
		end

	parse_header
			-- Parse the N pairs of integers at the beginning.
		local
			i: INTEGER
			num_objs: INTEGER
			obj_num, off: INTEGER
			lexer: PDF_LEXER
			byte_source: PDF_STRING_BYTE_SOURCE
			token: PDF_TOKEN
		do
			num_objs := count
			create offsets.make (num_objs)
			create object_numbers.make (num_objs)

			if decoded_content = Void then
				decode_content
			end

			if attached decoded_content as content then
				create byte_source.make (content)
				create lexer.make (byte_source)

				from
					i := 1
				until
					i > num_objs
				loop
						-- Read object number
					token := lexer.next_token
					if token.token_type = {PDF_TOKEN}.type_number then
						obj_num := token.value.to_integer
						object_numbers.extend (obj_num)

							-- Read offset
						token := lexer.next_token
						if token.token_type = {PDF_TOKEN}.type_number then
							off := token.value.to_integer
							offsets.extend (off)
						else
							i := num_objs + 1
						end
					else
						i := num_objs + 1
					end

					i := i + 1
				end
			end
		end

	decode_lzw_content (raw: STRING_8; predictor: INTEGER; columns: INTEGER): detachable STRING_8
			-- Decode LZW-compressed content with optional predictor.
		local
			lzw_decoder: PDF_LZW_DECODER
			early_change: INTEGER
		do
				-- Check for EarlyChange parameter
			early_change := 1  -- Default
			if attached {PDF_DICTIONARY} stream.stream_dictionary.item ("DecodeParms") as parms then
				if attached {PDF_NUMBER} parms.item ("EarlyChange") as ec then
					early_change := ec.int_value
				end
			end

			create lzw_decoder.make
			lzw_decoder.set_early_change (early_change)

			if predictor >= 10 then
					-- PNG predictor
				Result := lzw_decoder.decode_with_predictor (raw, predictor, columns)
			elseif predictor = 2 then
					-- TIFF predictor
				Result := lzw_decoder.decode_with_predictor (raw, predictor, columns)
			else
					-- No predictor
				Result := lzw_decoder.decode (raw)
			end

			if Result = Void and then lzw_decoder.has_error_message then
				log_info ("[PDF_OBJECT_STREAM] LZWDecode failed: ")
				if attached lzw_decoder.last_error_message as err then
					log_info (err)
				end
				log_info ("%N")
			end
		end

invariant
	offsets_match_count: offsets /= Void implies offsets.count <= count
	object_numbers_match_count: object_numbers /= Void implies object_numbers.count <= count

end

