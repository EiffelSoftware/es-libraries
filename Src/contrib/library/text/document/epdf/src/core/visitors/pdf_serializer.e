note
	description: "Serializes PDF objects to their textual PDF format representation."
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_SERIALIZER

inherit
	PDF_VISITOR

	PDF_WITH_LOGGING

create
	make

feature -- Access

	security_handler: detachable PDF_SECURITY_HANDLER
			-- Security handler for encryption.

	current_object_id: detachable PDF_OBJECT_ID
			-- Current object ID being serialized.

	make
			-- Initialize the serializer.
		do
			create output.make_empty
		end

feature -- Access

	output: STRING_8
			-- Serialized output (7-bit ASCII per ISO 32000-1:2008).

	last_output: STRING_8
			-- Last serialized output (query).
			-- Per ISO 32000-1:2008, PDF syntax is 7-bit ASCII.
		do
			Result := output
		ensure
			result_is_output: Result = output
		end

feature -- Element Change

	reset
			-- Reset the output buffer.
		do
			output.wipe_out
		ensure
			output_empty: output.is_empty
		end

	set_security_handler (a_handler: detachable PDF_SECURITY_HANDLER)
			-- Set security handler for encryption.
		do
			security_handler := a_handler
		ensure
			handler_set: security_handler = a_handler
		end

	set_current_object_id (an_id: detachable PDF_OBJECT_ID)
			-- Set current object ID for encryption context.
		do
			current_object_id := an_id
		ensure
			id_set: current_object_id = an_id
		end

feature -- Visiting

	visit_dictionary (a_dictionary: PDF_DICTIONARY)
			-- Serialize a PDF dictionary.
		do
			output.append ("<<")
			across a_dictionary.entries as entry loop
				output.append ("%N/")
				output.append (@ entry.key)
				output.append_character (' ')
				entry.accept (Current)
			end
			output.append ("%N>>")
		end

	visit_array (an_array: PDF_ARRAY)
			-- Serialize a PDF array.
		do
			output.append_character ('[')
			across an_array.items as obj loop
				if @ obj.cursor_index > 1 then
					output.append_character (' ')
				end
				obj.accept (Current)
			end
			output.append_character (']')
		end

	visit_name (a_name: PDF_NAME)
			-- Serialize a PDF name.
		do
			output.append (a_name.to_pdf_string)
		end

	visit_string (a_string: PDF_STRING)
			-- Serialize a PDF string.
			-- Per ISO 32000-1:2008 §7.6.1: strings in /Encrypt dictionary
			-- are NOT encrypted (handled by unsetting security handler).
		local
			encrypted: STRING_8
		do
			if attached security_handler as h and then attached current_object_id as id then
				-- Strings need encryption
				encrypted := h.encrypt_string (a_string.value, id.object_number, id.generation)
				output.append_character ('<')
				output.append (bytes_to_hex (encrypted))
				output.append_character ('>')
			else
				output.append (a_string.to_pdf_string)
			end
		end

	visit_number (a_number: PDF_NUMBER)
			-- Serialize a PDF number.
		do
			output.append (a_number.to_pdf_string)
		end

	visit_boolean (a_boolean: PDF_BOOLEAN)
			-- Serialize a PDF boolean.
		do
			output.append (a_boolean.to_pdf_string)
		end

	visit_indirect (an_indirect: PDF_INDIRECT_OBJECT)
			-- Serialize a PDF indirect object.
		do
			output.append (an_indirect.object_id.to_object_header_string)
			output.append ("%N")
			an_indirect.value.accept (Current)
			output.append ("%Nendobj")
		end

	visit_reference (a_reference: PDF_REFERENCE)
			-- Serialize a PDF indirect reference.
		do
			output.append (a_reference.to_pdf_string)
		end

	visit_stream (a_stream: PDF_STREAM)
			-- Serialize a PDF stream object.
			-- Handles compression state properly to prevent double decompression.
			-- Preserves DCTDecode (JPEG) streams unchanged (lossy compression).
		local
			l_content: STRING_8
			l_compressor: detachable ZLIB_COMPRESS
			l_compressed: detachable STRING_8
			l_use_compression: BOOLEAN
			l_is_dct: BOOLEAN
		do
				-- Check if this is a DCTDecode (JPEG) stream that should be preserved
			if attached {PDF_NAME} a_stream.stream_dictionary.item ("Filter") as filter then
				l_is_dct := filter.value.is_equal ("DCTDecode")
			elseif attached {PDF_ARRAY} a_stream.stream_dictionary.item ("Filter") as filters then
					-- Filter array: check if DCTDecode is present
				across filters.items as f loop
					if attached {PDF_NAME} f as fname and then fname.value.is_equal ("DCTDecode") then
						l_is_dct := True
					end
				end
			end
			
				-- Determine content to write (first determine decompressed/unencrypted content)
			l_content := a_stream.content

				-- Handle DCTDecode streams specially - preserve unchanged (JPEG is lossy)
			if l_is_dct then
					-- Keep DCTDecode stream as-is, no recompression
				l_use_compression := True  -- Keep existing /Filter
				log_info ("[visit_stream] Preserving DCTDecode (JPEG) stream unchanged%N")
			elseif a_stream.is_decompressed then
					-- Stream was decompressed during parsing, decide whether to recompress
				if l_content.count > 100 then
						-- Try recompression if beneficial
					create l_compressor
					l_compressor.compress_string (l_content)
					if l_compressor.is_last_operation_ok and then
					   attached l_compressor.last_compressed_string as comp and then
					   comp.count < (l_content.count * 9 // 10) then
							-- Recompression beneficial
						l_compressed := comp
						l_use_compression := True
						log_info ("[visit_stream] Recompressed stream (saved " + (l_content.count - comp.count).out + " bytes)%N")
					else
							-- Keep uncompressed
						l_use_compression := False
						log_info ("[visit_stream] Keeping decompressed stream (recompression not beneficial)%N")
					end
				else
						-- Too small for compression
					l_use_compression := False
				end
			else
					-- Stream was not decompressed during parsing
				if not a_stream.stream_dictionary.has_key ("Filter") and then l_content.count > 50 then
						-- NEW stream without compression - try to compress it
					create l_compressor
					l_compressor.compress_string (l_content)
					if l_compressor.is_last_operation_ok and then
					   attached l_compressor.last_compressed_string as comp and then
					   comp.count < l_content.count then
							-- Compression beneficial for new stream
						l_compressed := comp
						l_use_compression := True
					else
							-- Keep uncompressed
						l_use_compression := False
					end
				elseif a_stream.stream_dictionary.has_key ("Filter") then
						-- Stream has /Filter, keep as-is
					l_use_compression := True
				else
						-- Small stream without filter - keep uncompressed
					l_use_compression := False
				end
			end

				-- Update dictionary based on compression decision
			if l_use_compression then
					-- Ensure /Filter is set
				if attached l_compressed as comp then
					l_content := comp
				end
				if not a_stream.stream_dictionary.has_key ("Filter") then
					a_stream.stream_dictionary.put_name ("FlateDecode", "Filter")
				end
			else
					-- Remove /Filter for uncompressed content
				if a_stream.stream_dictionary.has_key ("Filter") then
					a_stream.stream_dictionary.entries.remove ("Filter")
					log_info ("[visit_stream] Removed /Filter from decompressed stream%N")
				end
			end

				-- Encrypt stream content after compression (Per PDF Spec)
			if attached security_handler as h and then attached current_object_id as id then
				l_content := h.encrypt_stream (l_content, id.object_number, id.generation)
			end

				-- Update /Length
			a_stream.stream_dictionary.put_number (l_content.count, "Length")

				-- Serialize dictionary first
			a_stream.stream_dictionary.accept (Current)

			output.append ("%Nstream%N")
			output.append (l_content)
			output.append ("%Nendstream")
		end

	visit_null
			-- Serialize a PDF null.
		do
			output.append ("null")
		end

feature {NONE} -- Implementation

	bytes_to_hex (bytes: STRING_8): STRING_8
			-- Convert byte string to hex string.
		local
			i: INTEGER
			code: NATURAL_32
			hex: STRING_8
		do
			create Result.make (bytes.count * 2)
			from i := 1 until i > bytes.count loop
				code := bytes.code (i)
				hex := code.to_hex_string
				-- hex format is 000000XX
				Result.append (hex.substring (7, 8))
				i := i + 1
			end
		end

invariant

end
