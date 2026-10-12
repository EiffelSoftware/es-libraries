note
	description: "[
		ASCIIHexDecode filter implementation.
		Decodes hexadecimal-encoded data per ISO 32000-1:2008 §7.4.2.
		
		Format:
		- Pairs of hexadecimal digits (0-9, A-F, a-f) represent bytes
		- Whitespace is ignored between hex digits
		- '>' marks end of data
		- If odd number of hex digits, final digit is assumed to be 0
		
		Example: '48656C6C6F>' decodes to 'Hello'
	]"
	spec_reference: "ISO 32000-1:2008 §7.4.2 (ASCIIHexDecode Filter)"
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_ASCIIHEX_DECODER

feature -- Basic Operations

	decode (a_data: STRING_8): STRING_8
			-- Decode ASCIIHex-encoded data to bytes.
			-- Per ISO 32000-1:2008 §7.4.2.
		require
			data_valid: a_data /= Void
		local
			i: INTEGER
			ch: CHARACTER_8
			high_nibble, low_nibble: INTEGER
			have_high: BOOLEAN
			byte_val: INTEGER
		do
			create Result.make (a_data.count // 2)
			
			from
				i := 1
				have_high := False
				high_nibble := 0
			until
				i > a_data.count
			loop
				ch := a_data.item (i)
				
				if ch = '>' then
					-- End of data marker
					if have_high then
						-- Odd number of digits - assume trailing 0
						byte_val := high_nibble * 16
						Result.append_character (byte_val.to_character_8)
					end
					i := a_data.count + 1 -- Exit loop
				elseif is_hex_digit (ch) then
					if have_high then
						-- We have a complete byte
						low_nibble := hex_digit_value (ch)
						byte_val := high_nibble * 16 + low_nibble
						Result.append_character (byte_val.to_character_8)
						have_high := False
					else
						-- Store high nibble
						high_nibble := hex_digit_value (ch)
						have_high := True
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
			
			-- Handle case where '>' was not found
			if have_high then
				byte_val := high_nibble * 16
				Result.append_character (byte_val.to_character_8)
			end
		ensure
			result_attached: Result /= Void
		end

feature -- Status

	is_hex_digit (ch: CHARACTER_8): BOOLEAN
			-- Is character a valid hexadecimal digit?
		do
			Result := (ch >= '0' and ch <= '9')
				or (ch >= 'A' and ch <= 'F')
				or (ch >= 'a' and ch <= 'f')
		end

	is_whitespace (ch: CHARACTER_8): BOOLEAN
			-- Is character PDF whitespace per ISO 32000-1:2008 Table 1?
		do
			Result := ch = ' ' or ch = '%T' or ch = '%N' 
				or ch = '%R' or ch = '%/0x0C/' or ch = '%/0x00/'
		end

feature {NONE} -- Implementation

	hex_digit_value (ch: CHARACTER_8): INTEGER
			-- Convert hex digit to integer value (0-15).
		require
			is_hex: is_hex_digit (ch)
		do
			if ch >= '0' and ch <= '9' then
				Result := ch.code - ('0').code
			elseif ch >= 'A' and ch <= 'F' then
				Result := ch.code - ('A').code + 10
			elseif ch >= 'a' and ch <= 'f' then
				Result := ch.code - ('a').code + 10
			end
		ensure
			valid_range: Result >= 0 and Result <= 15
		end

end
