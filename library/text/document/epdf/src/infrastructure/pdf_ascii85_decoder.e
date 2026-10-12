note
	description: "[
		ASCII85Decode filter implementation.
		Decodes base-85 encoded data per ISO 32000-1:2008 §7.4.3.
		
		Format:
		- Encodes 4 bytes as 5 ASCII characters (base-85)
		- Characters from '!' (33) to 'u' (117) represent values 0-84
		- 'z' represents 4 zero bytes (compression shortcut)
		- '~>' marks end of data
		- Whitespace is ignored
		- More efficient than ASCIIHexDecode (25% vs 100% overhead)
		
		Example: '87cURDZ' decodes to 'Hello'
	]"
	spec_reference: "ISO 32000-1:2008 §7.4.3 (ASCII85Decode Filter)"
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_ASCII85_DECODER

feature -- Basic Operations

	decode (a_data: STRING_8): STRING_8
			-- Decode ASCII85-encoded data to bytes.
			-- Per ISO 32000-1:2008 §7.4.3.
		require
			data_valid: a_data /= Void
		local
			i: INTEGER
			ch: CHARACTER_8
			tuple: STRING_8
			tuple_value: NATURAL_64
			byte_val: NATURAL_8
			finished: BOOLEAN
		do
			create Result.make (a_data.count * 4 // 5)
			create tuple.make (5)

			from
				i := 1
				finished := False
			until
				i > a_data.count or finished
			loop
				ch := a_data.item (i)

				if ch = '~' then
						-- Check for end marker '~>'
					if i + 1 <= a_data.count and then a_data.item (i + 1) = '>' then
							-- Process any remaining characters in tuple
						if not tuple.is_empty then
							process_partial_tuple (tuple, Result)
						end
						finished := True
					end
					i := i + 1
				elseif ch = 'z' then
						-- 'z' represents 4 zero bytes
					if not tuple.is_empty then
							-- 'z' should only appear between complete groups
							-- Handle gracefully by processing pending tuple first
						process_partial_tuple (tuple, Result)
						tuple.wipe_out
					end
					Result.append_character ('%U')
					Result.append_character ('%U')
					Result.append_character ('%U')
					Result.append_character ('%U')
					i := i + 1
				elseif is_ascii85_digit (ch) then
						-- Valid base-85 character ('!' to 'u')
					tuple.append_character (ch)
					if tuple.count = 5 then
							-- Complete 5-character tuple - decode to 4 bytes
						tuple_value := decode_tuple (tuple)
						byte_val := ((tuple_value |>> 24) & 0xFF).to_natural_8
						Result.append_character (byte_val.to_character_8)
						byte_val := ((tuple_value |>> 16) & 0xFF).to_natural_8
						Result.append_character (byte_val.to_character_8)
						byte_val := ((tuple_value |>> 8) & 0xFF).to_natural_8
						Result.append_character (byte_val.to_character_8)
						byte_val := (tuple_value & 0xFF).to_natural_8
						Result.append_character (byte_val.to_character_8)
						tuple.wipe_out
					end
					i := i + 1
				elseif is_whitespace (ch) then
						-- Skip whitespace per spec
					i := i + 1
				else
						-- Invalid character - skip (permissive mode)
					i := i + 1
				end
			end

				-- Handle case where '~>' was not found (non-compliant but handle gracefully)
			if not finished and not tuple.is_empty then
				process_partial_tuple (tuple, Result)
			end
		ensure
			result_attached: Result /= Void
		end

feature -- Status

	is_ascii85_digit (ch: CHARACTER_8): BOOLEAN
			-- Is character a valid ASCII85 digit ('!' to 'u')?
			-- Values 33-117 represent base-85 digits 0-84.
		do
			Result := ch >= '!' and ch <= 'u'
		ensure
			definition: Result = (ch >= '!' and ch <= 'u')
		end

	is_whitespace (ch: CHARACTER_8): BOOLEAN
			-- Is character PDF whitespace per ISO 32000-1:2008 Table 1?
		do
			Result := ch = ' ' or ch = '%T' or ch = '%N'
				or ch = '%R' or ch = '%/0x0C/' or ch = '%/0x00/'
		end

feature {NONE} -- Implementation

	decode_tuple (tuple: STRING_8): NATURAL_64
			-- Decode 5 ASCII85 characters to 32-bit value.
			-- Formula: c1*85^4 + c2*85^3 + c3*85^2 + c4*85 + c5
		require
			tuple_full: tuple.count = 5
		local
			i: INTEGER
			digit_value: NATURAL_64
		do
			Result := 0
			from
				i := 1
			until
				i > 5
			loop
				digit_value := (tuple.item (i).code - ('!').code).to_natural_64
				Result := Result * 85 + digit_value
				i := i + 1
			end
		ensure
			valid_range: Result <= 0xFFFFFFFF
		end

	process_partial_tuple (tuple: STRING_8; output: STRING_8)
			-- Process a partial tuple (1-4 characters) at end of data.
			-- Pad with 'u' characters (value 84) to 5 characters,
			-- decode, then output only (count) bytes.
		require
			tuple_not_empty: not tuple.is_empty
			tuple_not_full: tuple.count < 5
		local
			padded: STRING_8
			tuple_value: NATURAL_64
			byte_val: NATURAL_8
			bytes_to_output: INTEGER
			i: INTEGER
		do
			bytes_to_output := tuple.count - 1
			if bytes_to_output < 1 then
				bytes_to_output := 1
			end

				-- Pad tuple with 'u' (value 84 = highest digit)
			create padded.make_from_string (tuple)
			from
			until
				padded.count >= 5
			loop
				padded.append_character ('u')
			end

				-- Decode padded tuple
			tuple_value := decode_tuple (padded)

				-- Output only the significant bytes
			from
				i := 1
			until
				i > bytes_to_output
			loop
				inspect i
				when 1 then
					byte_val := ((tuple_value |>> 24) & 0xFF).to_natural_8
				when 2 then
					byte_val := ((tuple_value |>> 16) & 0xFF).to_natural_8
				when 3 then
					byte_val := ((tuple_value |>> 8) & 0xFF).to_natural_8
				else
					byte_val := (tuple_value & 0xFF).to_natural_8
				end
				output.append_character (byte_val.to_character_8)
				i := i + 1
			end
		end

	Base_85: NATURAL_64 = 85
			-- Base for ASCII85 encoding.

end
