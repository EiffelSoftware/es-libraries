note
	description: "[
		Represents a PDF cross-reference stream (PDF 1.5+).
		Cross-reference streams are an alternative to traditional xref tables.
		Per ISO 32000-1:2008 Section 7.5.8.
	]"
	spec_reference: "ISO 32000-1:2008 Section 7.5.8 (Cross-Reference Streams)"
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_XREF_STREAM

inherit
	PDF_WITH_LOGGING

create
	make

feature -- Initialization

	make (a_stream: PDF_STREAM)
			-- Create xref stream from stream object.
		require
			stream_valid: a_stream /= Void
		do
			stream := a_stream
			dictionary := a_stream.stream_dictionary
		ensure
			stream_set: stream = a_stream
			dictionary_set: dictionary = a_stream.stream_dictionary
		end

feature -- Access

	stream: PDF_STREAM
			-- The stream object containing xref data.

	dictionary: PDF_DICTIONARY
			-- The stream dictionary (contains xref metadata and trailer entries).

	size: INTEGER
			-- Total number of entries in xref table (/Size entry).
		do
			if attached {PDF_NUMBER} dictionary.item ("Size") as num then
				Result := num.int_value
			end
		end

	index: detachable ARRAY [INTEGER]
			-- Subsection specification (/Index entry).
			-- Array of pairs [first_obj_num, count].
			-- Default is [0, Size] if not present.
		local
			arr: detachable PDF_ARRAY
			i: INTEGER
			result_list: ARRAYED_LIST [INTEGER]
		do
			if attached {PDF_ARRAY} dictionary.item ("Index") as idx_arr then
				arr := idx_arr
				create result_list.make (arr.count)

				from
					i := 1
				until
					i > arr.count
				loop
					if attached {PDF_NUMBER} arr.item (i) as num then
						result_list.extend (num.int_value)
					end
					i := i + 1
				end

				if result_list.count > 0 then
					create Result.make_from_array (result_list.to_array)
				end
			end
		end

	w_array: detachable ARRAY [INTEGER]
			-- Field widths array (/W entry).
			-- Array of 3 integers specifying byte width of each field.
		local
			arr: detachable PDF_ARRAY
			i: INTEGER
			result_list: ARRAYED_LIST [INTEGER]
		do
			if attached {PDF_ARRAY} dictionary.item ("W") as w_arr then
				arr := w_arr
				create result_list.make (3)

				from
					i := 1
				until
					i > arr.count or i > 3
				loop
					if attached {PDF_NUMBER} arr.item (i) as num then
						result_list.extend (num.int_value)
					end
					i := i + 1
				end

				if result_list.count = 3 then
					create Result.make_from_array (result_list.to_array)
				end
			end
		end

	prev: INTEGER
			-- Byte offset of previous xref section (/Prev entry).
			-- Returns 0 if not present.
		do
			if attached {PDF_NUMBER} dictionary.item ("Prev") as num then
				Result := num.int_value
			end
		end

	is_xref_stream: BOOLEAN
			-- Is this a valid xref stream?
			-- Must have /Type /XRef.
		do
			if attached {PDF_NAME} dictionary.item ("Type") as type_name then
				Result := type_name.value.is_equal ("XRef")
			end
		ensure
			definition: Result = (attached {PDF_NAME} dictionary.item ("Type") as n and then n.value.is_equal ("XRef"))
		end

feature -- Trailer Entries

	root: detachable PDF_REFERENCE
			-- Document catalog reference (/Root entry).
		do
			if attached {PDF_REFERENCE} dictionary.item ("Root") as ref then
				Result := ref
			end
		end

	info: detachable PDF_REFERENCE
			-- Document info dictionary reference (/Info entry).
		do
			if attached {PDF_REFERENCE} dictionary.item ("Info") as ref then
				Result := ref
			end
		end

	id_array: detachable PDF_ARRAY
			-- File identifier array (/ID entry).
		do
			if attached {PDF_ARRAY} dictionary.item ("ID") as arr then
				Result := arr
			end
		end

feature -- Parsing

	parse_xref_data (decoder: PDF_FLATE_DECODER): detachable ARRAY [TUPLE [type: INTEGER; field2: INTEGER; field3: INTEGER]]
			-- Parse xref data from stream content.
			-- Returns array of tuples: [type, field2, field3]
			-- Type 0: Free object (field2 = next free, field3 = generation)
			-- Type 1: In-use object (field2 = offset, field3 = generation)
			-- Type 2: Compressed object (field2 = object stream number, field3 = index)
		require
			is_valid: is_xref_stream
			has_w: w_array /= Void
		local
			raw_data: detachable STRING_8
			decompressed: detachable STRING_8
			w: ARRAY [INTEGER]
			entry_size: INTEGER
			num_entries: INTEGER
			idx: ARRAY [INTEGER]
			i, pos: INTEGER
			type_val, field2_val, field3_val: INTEGER
			result_list: ARRAYED_LIST [TUPLE [type: INTEGER; field2: INTEGER; field3: INTEGER]]
			predictor, columns: INTEGER
		do
			-- Debug: check dictionary contents if needed
			if attached w_array as w_arr then
				w := w_arr
				entry_size := w [1] + w [2] + w [3]
				log_info ("[parse_xref_data] W=[" + w [1].out + ", " + w [2].out + ", " + w [3].out + "] entry_size=" + entry_size.out + "%N")

					-- Get stream content
				raw_data := stream.content
				log_info ("[parse_xref_data] raw_data size=" + (if raw_data /= Void then raw_data.count.out else "VOID" end) + "%N")

					-- Check for /DecodeParms with Predictor and Columns
				predictor := 1  -- Default: no prediction
				columns := entry_size  -- Default: entry size
				if attached {PDF_DICTIONARY} dictionary.item ("DecodeParms") as parms then
					if attached {PDF_NUMBER} parms.item ("Predictor") as pred then
						predictor := pred.int_value
					end
					if attached {PDF_NUMBER} parms.item ("Columns") as cols then
						columns := cols.int_value
					end
				end

					-- Decompress if needed
				if attached {PDF_ARRAY} dictionary.item ("Filter") as filter_array then
					log_info ("[parse_xref_data] Filter array with " + filter_array.count.out + " filters%N")
					-- Process first filter
					if filter_array.count >= 1 and then attached {PDF_NAME} filter_array.item (1) as first_filter then
						log_info ("[parse_xref_data] First filter=" + first_filter.value + "%N")
						decompressed := decode_with_filter (first_filter.value, raw_data, decoder, predictor, columns)
					else
						log_info ("[parse_xref_data] Filter array doesn't contain names%N")
						decompressed := raw_data
					end
				elseif attached {PDF_NAME} dictionary.item ("Filter") as filter then
					log_info ("[parse_xref_data] Single Filter=" + filter.value + "%N")
					decompressed := decode_with_filter (filter.value, raw_data, decoder, predictor, columns)
				else
					log_info ("[parse_xref_data] No Filter%N")
					decompressed := raw_data
				end

				log_info ("[parse_xref_data] decompressed size=" + (if decompressed /= Void then decompressed.count.out else "VOID" end) + "%N")

					-- Fail-fast validation
				if decompressed = Void then
					log_failure ("[parse_xref_data] FATAL: Decompression returned Void%N")
					log_failure ("[parse_xref_data] This usually indicates:%N")
					log_failure ("[parse_xref_data]   1. Stream content was not fully read%N")
					log_failure ("[parse_xref_data]   2. /Length value is incorrect%N")
					log_failure ("[parse_xref_data]   3. Data corruption in the PDF%N")
					if decoder.has_error_message and then attached decoder.last_error_message as err then
						log_failure ("[parse_xref_data]   Error: " + err + "%N")
					end
					check decompression_succeeded: False end
				end

				if attached decompressed as decomp and then not decomp.is_empty then
						-- Determine number of entries
					if attached index as idx_arr then
						idx := idx_arr
							-- Sum all counts in index array
						from
							i := 2
							num_entries := 0
						until
							i > idx.count
						loop
							num_entries := num_entries + idx [i]
							i := i + 2
						end
					else
						num_entries := size
					end

					create result_list.make (num_entries)

						-- Parse entries
					from
						i := 0
						pos := 1
					until
						i >= num_entries or pos > decomp.count
					loop
							-- Read type field
							-- Per ISO 32000-1:2008 §7.5.8.3: "The default value for the type field is 1"
					if w [1] = 0 then
						type_val := 1
					else
						type_val := read_field (decomp, pos, w [1])
						pos := pos + w [1]
					end

							-- Read field 2
						field2_val := read_field (decomp, pos, w [2])
						pos := pos + w [2]

							-- Read field 3
						field3_val := read_field (decomp, pos, w [3])
						pos := pos + w [3]

						result_list.extend ([type_val, field2_val, field3_val])
						i := i + 1
					end

					if result_list.count > 0 then
						create Result.make_from_array (result_list.to_array)
					end
				end
			end
		end

feature {NONE} -- Implementation

	decode_with_filter (filter_name: STRING_8; raw_data: detachable STRING_8; 
			decoder: PDF_FLATE_DECODER; predictor: INTEGER; columns: INTEGER): detachable STRING_8
			-- Decode data using the specified filter.
			-- Supports FlateDecode, ASCII85Decode, and ASCIIHexDecode.
		do
			if raw_data = Void then
				Result := Void
			elseif filter_name.is_equal ("FlateDecode") then
				if predictor >= 10 then
					Result := decoder.decode_with_predictor (raw_data, predictor, columns)
				else
					Result := decoder.decode (raw_data)
				end
					-- Check for errors
				if Result = Void and then decoder.has_error_message then
					log_failure ("[parse_xref_data] FATAL: FlateDecode decompression failed%N")
					if attached decoder.last_error_message as err then
						log_failure ("[parse_xref_data] Error: " + err + "%N")
					end
					check flatedecode_succeeded: False then end
				end
			elseif filter_name.is_equal ("ASCII85Decode") then
				Result := (create {PDF_ASCII85_DECODER}).decode (raw_data)
			elseif filter_name.is_equal ("ASCIIHexDecode") then
				Result := (create {PDF_ASCIIHEX_DECODER}).decode (raw_data)
			elseif filter_name.is_equal ("LZWDecode") then
				-- LZWDecode filter (legacy PDFs per ISO 32000-1:2008 §7.4.4)
			Result := decode_lzw_data (raw_data, predictor, columns)
		else
			log_failure ("[parse_xref_data] FATAL: Unsupported filter: " + filter_name + "%N")
			log_failure ("[parse_xref_data] Supported filters: FlateDecode, ASCII85Decode, ASCIIHexDecode, LZWDecode%N")
			check supported_filter: False then end
		end
		end

	read_field (data: STRING_8; start_pos: INTEGER; width: INTEGER): INTEGER
			-- Read an integer field from data at given position with given width.
			-- Fields are big-endian unsigned integers.
		require
			valid_position: start_pos >= 1 and start_pos <= data.count
			valid_width: width >= 0 and width <= 8
		local
			i: INTEGER
			byte_val: NATURAL_8
		do
			if width = 0 then
				Result := 0
			else
				from
					i := 0
				until
					i >= width or (start_pos + i) > data.count
				loop
					byte_val := data [start_pos + i].natural_32_code.to_natural_8
					Result := Result * 256 + byte_val.to_integer_32
					i := i + 1
				end
			end
		ensure
			non_negative: Result >= 0
		end

	decode_lzw_data (raw_data: detachable STRING_8; predictor: INTEGER; columns: INTEGER): detachable STRING_8
			-- Decode LZW-compressed data with optional predictor.
		local
			lzw_decoder: PDF_LZW_DECODER
			early_change: INTEGER
		do
			if raw_data = Void then
				Result := Void
			else
					-- Check for EarlyChange parameter
				early_change := 1  -- Default
				if attached {PDF_DICTIONARY} dictionary.item ("DecodeParms") as parms then
					if attached {PDF_NUMBER} parms.item ("EarlyChange") as ec then
						early_change := ec.int_value
					end
				end

				create lzw_decoder.make
				lzw_decoder.set_early_change (early_change)

				if predictor >= 10 then
						-- PNG predictor
					Result := lzw_decoder.decode_with_predictor (raw_data, predictor, columns)
				elseif predictor = 2 then
						-- TIFF predictor
					Result := lzw_decoder.decode_with_predictor (raw_data, predictor, columns)
				else
						-- No predictor
					Result := lzw_decoder.decode (raw_data)
				end

				if Result = Void and then lzw_decoder.has_error_message then
					log_failure ("[parse_xref_data] LZWDecode failed: ")
					if attached lzw_decoder.last_error_message as err then
						log_failure (err)
					end
					log_failure ("%N")
				end
			end
		end

end
