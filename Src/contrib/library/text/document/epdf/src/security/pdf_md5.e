note
	description: "MD5 Message-Digest Algorithm (RFC 1321)."

class
	PDF_MD5

create
	make

feature -- Initialization

	make
			-- Initialize MD5 state.
		do
			reset
		end

feature -- Access

	digest_string (a_string: STRING_8): STRING_8
			-- Compute MD5 digest of a string.
			-- Uses STRING_8 as MD5 operates on byte sequences.
		do
			reset
			update (a_string)
			finish
			Result := digest_as_string
		end

feature -- Element Change

	reset
			-- Reset state to initial values.
		do
			state_a := 0x67452301
			state_b := 0xEFCDAB89
			state_c := 0x98BADCFE
			state_d := 0x10325476
			count := 0
			create buffer.make_filled (0, 64)
		end

	update (a_data: STRING_8)
			-- Update digest with new data.
			-- Uses STRING_8 for binary byte sequences.
		local
			i, index, part_len: INTEGER
			l_input_len: INTEGER
		do
			l_input_len := a_data.count

				-- Compute index of current block
			index := ((count.bit_shift_right (3)) \\ 64).to_integer_32

				-- Update number of bits
			count := count + l_input_len.to_natural_64 * 8

			part_len := 64 - index

				-- Transform as many times as possible
			if l_input_len >= part_len then
				from
					i := 0
				until
					i >= part_len
				loop
					buffer [index + i] := a_data.code (i + 1).to_natural_8
					i := i + 1
				end

				transform (buffer)

				from
					i := part_len
				until
					i + 63 >= l_input_len
				loop
					transform_start_index (a_data, i)
					i := i + 64
				end

				index := 0
			else
				i := 0
			end

				-- Buffer remaining input
			from
				-- i is already set
			until
				i >= l_input_len
			loop
				buffer [index + i] := a_data.code (i + 1).to_natural_8
				i := i + 1
			end
		end

	finish
			-- Finalize digest.
		local
			bits: SPECIAL [NATURAL_8]
			index, pad_len: INTEGER
			l_count: NATURAL_64
			i: INTEGER
		do
			create bits.make_filled (0, 8)
			l_count := count

				-- Save number of bits (Little Endian)
			from i := 0 until i > 7 loop
				bits [i] := (l_count.bit_and (0xFF)).to_natural_8
				l_count := l_count.bit_shift_right (8)
				i := i + 1
			end

				-- Pad out to 56 mod 64.
			index := ((count.bit_shift_right (3)) \\ 64).to_integer_32
			if index < 56 then
				pad_len := 56 - index
			else
				pad_len := 120 - index
			end

			pad (pad_len)
			append_length (bits)
		end

feature -- Access

	digest_as_string: STRING_8
			-- Current digest as a raw string (16-byte MD5 hash).
			-- Uses STRING_8 for binary byte sequence.
		local
			res: STRING_8
			v: NATURAL_32
		do
			create res.make (16)

			v := state_a
			res.append_character ((v.bit_and (0xFF)).to_character_8)
			res.append_character ((v.bit_shift_right(8).bit_and (0xFF)).to_character_8)
			res.append_character ((v.bit_shift_right(16).bit_and (0xFF)).to_character_8)
			res.append_character ((v.bit_shift_right(24).bit_and (0xFF)).to_character_8)

			v := state_b
			res.append_character ((v.bit_and (0xFF)).to_character_8)
			res.append_character ((v.bit_shift_right(8).bit_and (0xFF)).to_character_8)
			res.append_character ((v.bit_shift_right(16).bit_and (0xFF)).to_character_8)
			res.append_character ((v.bit_shift_right(24).bit_and (0xFF)).to_character_8)

			v := state_c
			res.append_character ((v.bit_and (0xFF)).to_character_8)
			res.append_character ((v.bit_shift_right(8).bit_and (0xFF)).to_character_8)
			res.append_character ((v.bit_shift_right(16).bit_and (0xFF)).to_character_8)
			res.append_character ((v.bit_shift_right(24).bit_and (0xFF)).to_character_8)

			v := state_d
			res.append_character ((v.bit_and (0xFF)).to_character_8)
			res.append_character ((v.bit_shift_right(8).bit_and (0xFF)).to_character_8)
			res.append_character ((v.bit_shift_right(16).bit_and (0xFF)).to_character_8)
			res.append_character ((v.bit_shift_right(24).bit_and (0xFF)).to_character_8)

			Result := res
		end

feature {NONE} -- Implementation

	state_a: NATURAL_32
	state_b: NATURAL_32
	state_c: NATURAL_32
	state_d: NATURAL_32
	count: NATURAL_64
	buffer: SPECIAL [NATURAL_8]

	pad (len: INTEGER)
		local
			i: INTEGER
			l_buffer_idx: INTEGER
		do
			l_buffer_idx := ((count.bit_shift_right (3)) \\ 64).to_integer_32

				-- Append 0x80
			buffer [l_buffer_idx] := 0x80
			l_buffer_idx := l_buffer_idx + 1
			if l_buffer_idx >= 64 then
				transform (buffer)
				l_buffer_idx := 0
			end

			from
				i := 1
			until
				i >= len
			loop
				buffer [l_buffer_idx] := 0
				l_buffer_idx := l_buffer_idx + 1
				if l_buffer_idx >= 64 then
					transform (buffer)
					l_buffer_idx := 0
				end
				i := i + 1
			end
		end

	append_length (len_bytes: SPECIAL [NATURAL_8])
		local
			i, j: INTEGER
		do
			j := 56
			from i := 0 until i >= 8 loop
				buffer [j] := len_bytes [i]
				i := i + 1
				j := j + 1
			end
			transform (buffer)
		end

	transform_start_index (a_data: STRING_8; start_index: INTEGER)
			-- Transform helper for string source.
			-- Uses STRING_8 for binary byte sequences.
		local
			block: SPECIAL [NATURAL_8]
			i: INTEGER
		do
			create block.make_filled (0, 64)
			from i := 0 until i >= 64 loop
				block [i] := a_data.code (start_index + i + 1).to_natural_8
				i := i + 1
			end
			transform (block)
		end

	transform (a_block: SPECIAL [NATURAL_8])
		local
			a, b, c, d: NATURAL_32
			x: SPECIAL [NATURAL_32]
		do
			a := state_a
			b := state_b
			c := state_c
			d := state_d

			create x.make_filled (0, 16)
			decode (x, a_block)

				-- Round 1
			a := ff (a, b, c, d, x[0], 7, 0xd76aa478)
			d := ff (d, a, b, c, x[1], 12, 0xe8c7b756)
			c := ff (c, d, a, b, x[2], 17, 0x242070db)
			b := ff (b, c, d, a, x[3], 22, 0xc1bdceee)
			a := ff (a, b, c, d, x[4], 7, 0xf57c0faf)
			d := ff (d, a, b, c, x[5], 12, 0x4787c62a)
			c := ff (c, d, a, b, x[6], 17, 0xa8304613)
			b := ff (b, c, d, a, x[7], 22, 0xfd469501)
			a := ff (a, b, c, d, x[8], 7, 0x698098d8)
			d := ff (d, a, b, c, x[9], 12, 0x8b44f7af)
			c := ff (c, d, a, b, x[10], 17, 0xffff5bb1)
			b := ff (b, c, d, a, x[11], 22, 0x895cd7be)
			a := ff (a, b, c, d, x[12], 7, 0x6b901122)
			d := ff (d, a, b, c, x[13], 12, 0xfd987193)
			c := ff (c, d, a, b, x[14], 17, 0xa679438e)
			b := ff (b, c, d, a, x[15], 22, 0x49b40821)

				-- Round 2
			a := gg (a, b, c, d, x[1], 5, 0xf61e2562)
			d := gg (d, a, b, c, x[6], 9, 0xc040b340)
			c := gg (c, d, a, b, x[11], 14, 0x265e5a51)
			b := gg (b, c, d, a, x[0], 20, 0xe9b6c7aa)
			a := gg (a, b, c, d, x[5], 5, 0xd62f105d)
			d := gg (d, a, b, c, x[10], 9, 0x02441453)
			c := gg (c, d, a, b, x[15], 14, 0xd8a1e681)
			b := gg (b, c, d, a, x[4], 20, 0xe7d3fbc8)
			a := gg (a, b, c, d, x[9], 5, 0x21e1cde6)
			d := gg (d, a, b, c, x[14], 9, 0xc33707d6)
			c := gg (c, d, a, b, x[3], 14, 0xf4d50d87)
			b := gg (b, c, d, a, x[8], 20, 0x455a14ed)
			a := gg (a, b, c, d, x[13], 5, 0xa9e3e905)
			d := gg (d, a, b, c, x[2], 9, 0xfcefa3f8)
			c := gg (c, d, a, b, x[7], 14, 0x676f02d9)
			b := gg (b, c, d, a, x[12], 20, 0x8d2a4c8a)

				-- Round 3
			a := hh (a, b, c, d, x[5], 4, 0xfffa3942)
			d := hh (d, a, b, c, x[8], 11, 0x8771f681)
			c := hh (c, d, a, b, x[11], 16, 0x6d9d6122)
			b := hh (b, c, d, a, x[14], 23, 0xfde5380c)
			a := hh (a, b, c, d, x[1], 4, 0xa4beea44)
			d := hh (d, a, b, c, x[4], 11, 0x4bdecfa9)
			c := hh (c, d, a, b, x[7], 16, 0xf6bb4b60)
			b := hh (b, c, d, a, x[10], 23, 0xbebfbc70)
			a := hh (a, b, c, d, x[13], 4, 0x289b7ec6)
			d := hh (d, a, b, c, x[0], 11, 0xeaa127fa)
			c := hh (c, d, a, b, x[3], 16, 0xd4ef3085)
			b := hh (b, c, d, a, x[6], 23, 0x04881d05)
			a := hh (a, b, c, d, x[9], 4, 0xd9d4d039)
			d := hh (d, a, b, c, x[12], 11, 0xe6db99e5)
			c := hh (c, d, a, b, x[15], 16, 0x1fa27cf8)
			b := hh (b, c, d, a, x[2], 23, 0xc4ac5665)

				-- Round 4
			a := ii (a, b, c, d, x[0], 6, 0xf4292244)
			d := ii (d, a, b, c, x[7], 10, 0x432aff97)
			c := ii (c, d, a, b, x[14], 15, 0xab9423a7)
			b := ii (b, c, d, a, x[5], 21, 0xfc93a039)
			a := ii (a, b, c, d, x[12], 6, 0x655b59c3)
			d := ii (d, a, b, c, x[3], 10, 0x8f0ccc92)
			c := ii (c, d, a, b, x[10], 15, 0xffeff47d)
			b := ii (b, c, d, a, x[1], 21, 0x85845dd1)
			a := ii (a, b, c, d, x[8], 6, 0x6fa87e4f)
			d := ii (d, a, b, c, x[15], 10, 0xfe2ce6e0)
			c := ii (c, d, a, b, x[6], 15, 0xa3014314)
			b := ii (b, c, d, a, x[13], 21, 0x4e0811a1)
			a := ii (a, b, c, d, x[4], 6, 0xf7537e82)
			d := ii (d, a, b, c, x[11], 10, 0xbd3af235)
			c := ii (c, d, a, b, x[2], 15, 0x2ad7d2bb)
			b := ii (b, c, d, a, x[9], 21, 0xeb86d391)

			state_a := state_a + a
			state_b := state_b + b
			state_c := state_c + c
			state_d := state_d + d
		end

	decode (output: SPECIAL [NATURAL_32]; input: SPECIAL [NATURAL_8])
		local
			i, j: INTEGER
		do
			from
				i := 0
				j := 0
			until
				j >= 64
			loop
				output [i] := input [j].to_natural_32.bit_or (
					input [j+1].to_natural_32.bit_shift_left (8)).bit_or (
					input [j+2].to_natural_32.bit_shift_left (16)).bit_or (
					input [j+3].to_natural_32.bit_shift_left (24))
				i := i + 1
				j := j + 4
			end
		end

feature	-- Basic MD5 functions

	f (x, y, z: NATURAL_32): NATURAL_32
		do
			Result := (x.bit_and (y)).bit_or (x.bit_not.bit_and (z))
		end

	g (x, y, z: NATURAL_32): NATURAL_32
		do
			Result := (x.bit_and (z)).bit_or (y.bit_and (z.bit_not))
		end

	h (x, y, z: NATURAL_32): NATURAL_32
		do
			Result := x.bit_xor (y).bit_xor (z)
		end

	i_func (x, y, z: NATURAL_32): NATURAL_32
		do
			Result := y.bit_xor (x.bit_or (z.bit_not))
		end

	rotate_left (x: NATURAL_32; n: INTEGER): NATURAL_32
		do
			Result := x.bit_shift_left (n).bit_or (x.bit_shift_right (32 - n))
		end

	ff (a, b, c, d, x: NATURAL_32; s: INTEGER; ac: NATURAL_32): NATURAL_32
		do
			Result := a + f (b, c, d) + x + ac
			Result := rotate_left (Result, s)
			Result := Result + b
		end

	gg (a, b, c, d, x: NATURAL_32; s: INTEGER; ac: NATURAL_32): NATURAL_32
		do
			Result := a + g (b, c, d) + x + ac
			Result := rotate_left (Result, s)
			Result := Result + b
		end

	hh (a, b, c, d, x: NATURAL_32; s: INTEGER; ac: NATURAL_32): NATURAL_32
		do
			Result := a + h (b, c, d) + x + ac
			Result := rotate_left (Result, s)
			Result := Result + b
		end

	ii (a, b, c, d, x: NATURAL_32; s: INTEGER; ac: NATURAL_32): NATURAL_32
		do
			Result := a + i_func (b, c, d) + x + ac
			Result := rotate_left (Result, s)
			Result := Result + b
		end

end
