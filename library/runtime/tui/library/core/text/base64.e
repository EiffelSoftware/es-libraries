note
	description: "[
		Base64 (RFC 4648 §4): the standard alphabet `A-Z a-z 0-9 + /`, with `=` padding,
		no line breaks.

		Encoding is used by OSC 52 clipboard writes ({TERMINAL}.copy_to_clipboard, P2 T3).
		Decoding (P2b K1) is for OSC 52 clipboard replies, and strict: `is_valid_encoding`
		accepts exactly what `encoded` writes (padding required, the unused bits of the
		last group zero, no line breaks or other characters), so `decoded` and `encoded`
		are inverse. `decoded_utf_8` reads the bytes as UTF-8 for display: each invalid
		sequence (a maximal subpart, Unicode §3.9 / WHATWG) becomes one U+FFFD.

		Written here rather than taken from Gobo (UT_BASE64_ENCODING_OUTPUT_STREAM) so that
		the library depends on `base` and `thread` only.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	BASE64

feature -- Encoding

	encoded (a_bytes: READABLE_STRING_8): STRING_8
			-- Base64 of `a_bytes`, each character of which is one byte (0 .. 255).
		require
			bytes_attached: a_bytes /= Void
		local
			i, l_count, l_group: INTEGER
		do
			l_count := a_bytes.count
			create Result.make (encoded_length (l_count))
			from
				i := 1
			until
				i > l_count
			loop
					-- Up to three bytes make a 24-bit group, missing bytes as zero bits
				l_group := a_bytes.code (i).to_integer_32 |<< 16
				if i + 1 <= l_count then
					l_group := l_group | (a_bytes.code (i + 1).to_integer_32 |<< 8)
				end
				if i + 2 <= l_count then
					l_group := l_group | a_bytes.code (i + 2).to_integer_32
				end
				Result.append_character (Alphabet [((l_group |>> 18) & 0x3F) + 1])
				Result.append_character (Alphabet [((l_group |>> 12) & 0x3F) + 1])
				if i + 1 <= l_count then
					Result.append_character (Alphabet [((l_group |>> 6) & 0x3F) + 1])
				else
					Result.append_character (Padding)
				end
				if i + 2 <= l_count then
					Result.append_character (Alphabet [(l_group & 0x3F) + 1])
				else
					Result.append_character (Padding)
				end
				i := i + 3
			end
		ensure
			instance_free: class
			padded_length: Result.count = encoded_length (a_bytes.count)
			valid: is_encoded (Result)
			strict: is_valid_encoding (Result)
		end

	encoded_utf_8 (a_text: READABLE_STRING_GENERAL): STRING_8
			-- Base64 of `a_text` encoded as UTF-8 (a STRING_8 is read as code points, Latin-1).
		require
			text_attached: a_text /= Void
		do
			Result := encoded ({UTF_CONVERTER}.utf_32_string_to_utf_8_string_8 (a_text))
		ensure
			instance_free: class
			padded_length: Result.count = encoded_length (utf_8_count (a_text))
		end

feature -- Decoding

	decoded (a_text: READABLE_STRING_8): STRING_8
			-- Bytes of the base64 `a_text`, one character (0 .. 255) per byte.
		require
			text_attached: a_text /= Void
			valid_encoding: is_valid_encoding (a_text)
		local
			i, l_group: INTEGER
		do
			create Result.make (a_text.count // 4 * 3)
			from
				i := 1
			until
				i > a_text.count
			loop
					-- Four characters make a 24-bit group; padding stands for zero bits
				l_group := (value (a_text [i]) |<< 18) | (value (a_text [i + 1]) |<< 12)
				if a_text [i + 2] /= Padding then
					l_group := l_group | (value (a_text [i + 2]) |<< 6)
				end
				if a_text [i + 3] /= Padding then
					l_group := l_group | value (a_text [i + 3])
				end
				Result.append_character (((l_group |>> 16) & 0xFF).to_character_8)
				if a_text [i + 2] /= Padding then
					Result.append_character (((l_group |>> 8) & 0xFF).to_character_8)
				end
				if a_text [i + 3] /= Padding then
					Result.append_character ((l_group & 0xFF).to_character_8)
				end
				i := i + 4
			end
		ensure
			instance_free: class
			three_per_group: Result.count = a_text.count // 4 * 3 - a_text.occurrences (Padding)
			inverse: encoded (Result).same_string (a_text)
		end

	decoded_utf_8 (a_text: READABLE_STRING_8): STRING_32
			-- Text of the base64 `a_text`, its bytes read as UTF-8, each invalid sequence
			-- replaced by one `Replacement_character` (for display; nothing is escaped).
		require
			text_attached: a_text /= Void
			valid_encoding: is_valid_encoding (a_text)
		do
			Result := utf_8_text (decoded (a_text))
		ensure
			instance_free: class
			from_bytes: Result.same_string (utf_8_text (decoded (a_text)))
		end

	utf_8_text (a_bytes: READABLE_STRING_8): STRING_32
			-- `a_bytes` (one character per byte) read as UTF-8, each invalid sequence
			-- replaced by one `Replacement_character`. Invalid: a byte that starts no
			-- sequence (80 .. C1, F5 .. FF), and the longest start of a well-formed
			-- sequence (Unicode Table 3-7) that another byte or the end cuts short. So
			-- overlong forms, surrogates (U+D800 .. U+DFFF) and code points past U+10FFFF
			-- are replaced, and decoding goes on at the byte that broke the sequence.
		require
			bytes_attached: a_bytes /= Void
		local
			i, j, l_count, l_byte, l_more, l_low, l_high, l_code: INTEGER
			l_broken: BOOLEAN
		do
			l_count := a_bytes.count
			create Result.make (l_count)
			from
				i := 1
			until
				i > l_count
			loop
				l_byte := a_bytes.code (i).to_integer_32
					-- `l_more` continuation bytes follow; the first in `l_low` .. `l_high`
				l_low := 0x80
				l_high := 0xBF
				l_code := 0
				inspect l_byte
				when 0x00 .. 0x7F then
					l_more := 0
				when 0xC2 .. 0xDF then
					l_more := 1
					l_code := l_byte & 0x1F
				when 0xE0 then
					l_more := 2
					l_low := 0xA0
				when 0xE1 .. 0xEC, 0xEE, 0xEF then
					l_more := 2
					l_code := l_byte & 0x0F
				when 0xED then
					l_more := 2
					l_code := 0x0D
					l_high := 0x9F
				when 0xF0 then
					l_more := 3
					l_low := 0x90
				when 0xF1 .. 0xF3 then
					l_more := 3
					l_code := l_byte & 0x07
				when 0xF4 then
					l_more := 3
					l_code := 4
					l_high := 0x8F
				else
						-- A continuation byte, C0, C1 or F5 .. FF: starts nothing
					l_more := -1
				end
				if l_more = 0 then
					Result.append_code (l_byte.to_natural_32)
					i := i + 1
				elseif l_more < 0 then
					Result.append_character (Replacement_character)
					i := i + 1
				else
					from
						j := 1
						l_broken := False
					until
						l_broken or j > l_more
					loop
						if i + j > l_count then
							l_broken := True
						else
							l_byte := a_bytes.code (i + j).to_integer_32
							if l_byte < l_low or l_byte > l_high then
								l_broken := True
							else
								l_code := (l_code |<< 6) | (l_byte & 0x3F)
								l_low := 0x80
								l_high := 0xBF
								j := j + 1
							end
						end
					end
					if l_broken then
							-- The lead and the `j - 1` bytes before the break: one maximal subpart
						Result.append_character (Replacement_character)
						i := i + j
					else
						Result.append_code (l_code.to_natural_32)
						i := i + l_more + 1
					end
				end
			end
		ensure
			instance_free: class
			no_longer: Result.count <= a_bytes.count
			ascii_kept: (across 1 |..| a_bytes.count as k all a_bytes.code (k) < 0x80 end) implies Result.same_string_general (a_bytes)
			valid_round_trip: not Result.has (Replacement_character) implies {UTF_CONVERTER}.utf_32_string_to_utf_8_string_8 (Result).same_string (a_bytes)
		end

feature -- Measurement

	encoded_length (a_byte_count: INTEGER): INTEGER
			-- Length of the base64 of `a_byte_count` bytes: 4 characters per 3 bytes or part of 3.
		require
			non_negative: a_byte_count >= 0
		do
			Result := 4 * ((a_byte_count + 2) // 3)
		ensure
			instance_free: class
			four_per_group: Result \\ 4 = 0
			enough: Result // 4 * 3 >= a_byte_count
			no_extra_group: Result // 4 * 3 < a_byte_count + 3
		end

	utf_8_count (a_text: READABLE_STRING_GENERAL): INTEGER
			-- Number of bytes of `a_text` encoded as UTF-8.
		require
			text_attached: a_text /= Void
		do
			Result := {UTF_CONVERTER}.utf_8_bytes_count (a_text, 1, a_text.count)
		ensure
			instance_free: class
			at_least_one_per_character: Result >= a_text.count
		end

feature -- Status report

	is_encoded (a_text: READABLE_STRING_8): BOOLEAN
			-- Is `a_text` padded base64: groups of four characters from `Alphabet`, with
			-- at most two `Padding` characters, at the end only? (The unused bits of the
			-- last group are not checked; `is_valid_encoding` checks them.)
		require
			text_attached: a_text /= Void
		local
			i, l_pad: INTEGER
		do
			Result := a_text.count \\ 4 = 0
			from
				i := 1
			until
				not Result or i > a_text.count
			loop
				if a_text [i] = Padding then
					l_pad := l_pad + 1
				else
					Result := l_pad = 0 and Alphabet.has (a_text [i])
				end
				i := i + 1
			end
			Result := Result and l_pad <= 2
		ensure
			instance_free: class
		end

	is_valid_encoding (a_text: READABLE_STRING_8): BOOLEAN
			-- Is `a_text` strict base64, exactly as `encoded` writes it (RFC 4648 §3.5): a
			-- length that is a multiple of four, characters from `Alphabet`, `Padding` only
			-- as the last one or two characters, and the unused bits of the last group zero?
			-- The empty string is valid; line breaks and blanks are not.
		require
			text_attached: a_text /= Void
		local
			i, l_count, l_pad: INTEGER
		do
			l_count := a_text.count
			Result := l_count \\ 4 = 0
			if Result and l_count > 0 then
				if a_text [l_count] = Padding then
					l_pad := 1
					if a_text [l_count - 1] = Padding then
						l_pad := 2
					end
				end
				from
					i := 1
				until
					not Result or i > l_count - l_pad
				loop
					Result := value (a_text [i]) >= 0
					i := i + 1
				end
				if Result and l_pad = 2 then
						-- "xy==": one byte; the low 4 bits of `y` are unused
					Result := (value (a_text [l_count - 2]) & 0x0F) = 0
				elseif Result and l_pad = 1 then
						-- "xyz=": two bytes; the low 2 bits of `z` are unused
					Result := (value (a_text [l_count - 1]) & 0x03) = 0
				end
			end
		ensure
			instance_free: class
			padded: Result implies is_encoded (a_text)
			empty_valid: a_text.is_empty implies Result
		end

feature -- Constants

	Alphabet: STRING_8 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
			-- RFC 4648 Table 1: the value of a character is its index minus one

	Padding: CHARACTER_8 = '='
			-- RFC 4648 pad character

	Replacement_character: CHARACTER_32 = '%/0xFFFD/'
			-- U+FFFD, written by `utf_8_text` for each invalid UTF-8 sequence

feature {NONE} -- Implementation

	value (c: CHARACTER_8): INTEGER
			-- Value (0 .. 63) of `c` in `Alphabet`, or -1 when `c` is not in it.
		do
			inspect c
			when 'A' .. 'Z' then
				Result := c.code - ('A').code
			when 'a' .. 'z' then
				Result := c.code - ('a').code + 26
			when '0' .. '9' then
				Result := c.code - ('0').code + 52
			when '+' then
				Result := 62
			when '/' then
				Result := 63
			else
				Result := -1
			end
		ensure
			instance_free: class
			in_alphabet: Result >= 0 implies Alphabet [Result + 1] = c
			not_in_alphabet: Result < 0 implies (Result = -1 and not Alphabet.has (c))
		end

end
