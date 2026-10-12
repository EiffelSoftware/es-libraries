note
	description: "SHA-512 and SHA-384 Message-Digest Algorithms (RFC 6234 / FIPS 180-4)."

class
	PDF_SHA512

create
	make,
	make_384

feature -- Initialization

	make
			-- Initialize for SHA-512.
		do
			is_sha384 := False
			create w.make_filled (0, 80)
			reset
		ensure
			not_sha384: not is_sha384
		end

	make_384
			-- Initialize for SHA-384.
		do
			is_sha384 := True
			create w.make_filled (0, 80)
			reset
		ensure
			is_sha384: is_sha384
		end

feature -- Access

	is_sha384: BOOLEAN
			-- Is this instance configured for SHA-384?

	is_finished: BOOLEAN
			-- Has `finish` been called? Must call `reset` before reuse.


	digest: STRING_8
			-- The computed message digest as raw bytes (48 bytes for SHA-384, 64 for SHA-512).
			-- Calls `finish` internally; call `reset` before computing another hash.
		require
			not_already_finished: not is_finished
		local
			res: STRING_8
			limit: INTEGER
		do
			finish
			if is_sha384 then
				limit := 6
			else
				limit := 8
			end
			create res.make (limit * 8)
			append_nat64_be (h0, res)
			append_nat64_be (h1, res)
			append_nat64_be (h2, res)
			append_nat64_be (h3, res)
			append_nat64_be (h4, res)
			append_nat64_be (h5, res)
			if not is_sha384 then
				append_nat64_be (h6, res)
				append_nat64_be (h7, res)
			end
			Result := res
		ensure
			result_attached: Result /= Void
			correct_length: Result.count = (if is_sha384 then 48 else 64 end)
			finished: is_finished
		end

	hex_digest: STRING_8
			-- The computed message digest as a lowercase hex string.
			-- Convenience wrapper around `digest`.
		require
			not_already_finished: not is_finished
		do
			Result := bytes_to_hex (digest)
		ensure
			result_attached: Result /= Void
			correct_length: Result.count = (if is_sha384 then 96 else 128 end)
			finished: is_finished
		end

feature -- Element Change

	reset
			-- Reset state to initial values so the object can compute a new hash.
		do
			if is_sha384 then
				h0 := 0xcbbb9d5dc1059ed8
				h1 := 0x629a292a367cd507
				h2 := 0x9159015a3070dd17
				h3 := 0x152fecd8f70e5939
				h4 := 0x67332667ffc00b31
				h5 := 0x8eb44a8768581511
				h6 := 0xdb0c2e0d64f98fa7
				h7 := 0x47b5481dbefa4fa4
			else
				h0 := 0x6a09e667f3bcc908
				h1 := 0xbb67ae8584caa73b
				h2 := 0x3c6ef372fe94f82b
				h3 := 0xa54ff53a5f1d36f1
				h4 := 0x510e527fade682d1
				h5 := 0x9b05688c2b3e6c1f
				h6 := 0x1f83d9abfb41bd6b
				h7 := 0x5be0cd19137e2179
			end
			count := 0
			buffer_offset := 0
			is_finished := False
			create buffer.make_filled (0, 128)
		ensure
			not_finished: not is_finished
			count_zeroed: count = 0
		end

	update (a_data: STRING_8)
			-- Feed string data into the digest.
			-- `count` accumulates the total message length in bits (8 bits per byte).
		require
			not_finished: not is_finished
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > a_data.count
			loop
				buffer [buffer_offset] := a_data.code (i).to_natural_8
				buffer_offset := buffer_offset + 1
				count := count + 8
				if buffer_offset = 128 then
					process_block
					buffer_offset := 0
				end
				i := i + 1
			end
		ensure
			not_finished: not is_finished
		end

	update_bytes (a_data: SPECIAL [NATURAL_8]; a_from: INTEGER; a_to: INTEGER)
			-- Feed raw bytes from a_data[a_from..a_to] into the digest.
			-- Use this for binary data to avoid STRING_8 encoding issues.
		require
			not_finished: not is_finished
			valid_range: a_from <= a_to + 1
			valid_from: a_from >= 0
			valid_to: a_to < a_data.count
		local
			i: INTEGER
		do
			from
				i := a_from
			until
				i > a_to
			loop
				buffer [buffer_offset] := a_data [i]
				buffer_offset := buffer_offset + 1
				count := count + 8
				if buffer_offset = 128 then
					process_block
					buffer_offset := 0
				end
				i := i + 1
			end
		ensure
			not_finished: not is_finished
		end

feature {NONE} -- Finalization

	finish
			-- Append padding and length, then process the final block.
			-- After this call `is_finished` is True; call `reset` to reuse.
		require
			not_already_finished: not is_finished
		local
			i: INTEGER
			bits: NATURAL_64
		do
			bits := count
			-- 1. Append the 0x80 pad byte
			buffer [buffer_offset] := 0x80
			buffer_offset := buffer_offset + 1

			-- 2. If no room for the 16-byte length field (bytes 112..127),
			--    fill this block with zeros, process it, and start a fresh one.
			if buffer_offset > 112 then
				from until buffer_offset = 128 loop
					buffer [buffer_offset] := 0
					buffer_offset := buffer_offset + 1
				end
				process_block
				buffer_offset := 0
			end

			-- 3. Zero-pad up to byte 112
			from until buffer_offset = 112 loop
				buffer [buffer_offset] := 0
				buffer_offset := buffer_offset + 1
			end

			-- 4. Append message length as a 128-bit big-endian integer.
			--    The upper 64 bits are always zero for messages < 2^64 bits.
			from i := 112 until i >= 120 loop
				buffer [i] := 0
				i := i + 1
			end
			-- Lower 64 bits of the bit-length, big-endian (bytes 120..127)
			buffer [120] := (bits.bit_shift_right (56).bit_and (0xFF)).to_natural_8
			buffer [121] := (bits.bit_shift_right (48).bit_and (0xFF)).to_natural_8
			buffer [122] := (bits.bit_shift_right (40).bit_and (0xFF)).to_natural_8
			buffer [123] := (bits.bit_shift_right (32).bit_and (0xFF)).to_natural_8
			buffer [124] := (bits.bit_shift_right (24).bit_and (0xFF)).to_natural_8
			buffer [125] := (bits.bit_shift_right (16).bit_and (0xFF)).to_natural_8
			buffer [126] := (bits.bit_shift_right (8).bit_and (0xFF)).to_natural_8
			buffer [127] := (bits.bit_and (0xFF)).to_natural_8

			process_block
			is_finished := True
		ensure
			finished: is_finished
		end

feature {NONE} -- Implementation

	h0: NATURAL_64
	h1: NATURAL_64
	h2: NATURAL_64
	h3: NATURAL_64
	h4: NATURAL_64
	h5: NATURAL_64
	h6: NATURAL_64
	h7: NATURAL_64
	count: NATURAL_64
			-- Total message length in bits fed so far.
	buffer: SPECIAL [NATURAL_8]
	buffer_offset: INTEGER
	w: SPECIAL [NATURAL_64]

	K: ARRAY [NATURAL_64]
			-- Round constants (cube roots of the first 80 primes, FIPS 180-4 §4.2.3).
			-- This array is 1-based (Eiffel default for <<...>> literals).
			-- The main loop uses K[i+1] with i in 0..79, mapping to K[1]..K[80].
		once
			Result := <<
				0x428a2f98d728ae22, 0x7137449123ef65cd, 0xb5c0fbcfec4d3b2f, 0xe9b5dba58189dbbc,
				0x3956c25bf348b538, 0x59f111f1b605d019, 0x923f82a4af194f9b, 0xab1c5ed5da6d8118,
				0xd807aa98a3030242, 0x12835b0145706fbe, 0x243185be4ee4b28c, 0x550c7dc3d5ffb4e2,
				0x72be5d74f27b896f, 0x80deb1fe3b1696b1, 0x9bdc06a725c71235, 0xc19bf174cf692694,
				0xe49b69c19ef14ad2, 0xefbe4786384f25e3, 0x0fc19dc68b8cd5b5, 0x240ca1cc77ac9c65,
				0x2de92c6f592b0275, 0x4a7484aa6ea6e483, 0x5cb0a9dcbd41fbd4, 0x76f988da831153b5,
				0x983e5152ee66dfab, 0xa831c66d2db43210, 0xb00327c898fb213f, 0xbf597fc7beef0ee4,
				0xc6e00bf33da88fc2, 0xd5a79147930aa725, 0x06ca6351e003826f, 0x142929670a0e6e70,
				0x27b70a8546d22ffc, 0x2e1b21385c26c926, 0x4d2c6dfc5ac42aed, 0x53380d139d95b3df,
				0x650a73548baf63de, 0x766a0abb3c77b2a8, 0x81c2c92e47edaee6, 0x92722c851482353b,
				0xa2bfe8a14cf10364, 0xa81a664bbc423001, 0xc24b8b70d0f89791, 0xc76c51a30654be30,
				0xd192e819d6ef5218, 0xd69906245565a910, 0xf40e35855771202a, 0x106aa07032bbd1b8,
				0x19a4c116b8d2d0c8, 0x1e376c085141ab53, 0x2748774cdf8eeb99, 0x34b0bcb5e19b48a8,
				0x391c0cb3c5c95a63, 0x4ed8aa4ae3418acb, 0x5b9cca4f7763e373, 0x682e6ff3d6b2b8a3,
				0x748f82ee5defb2fc, 0x78a5636f43172f60, 0x84c87814a1f0ab72, 0x8cc702081a6439ec,
				0x90befffa23631e28, 0xa4506cebde82bde9, 0xbef9a3f7b2c67915, 0xc67178f2e372532b,
				0xca273eceea26619c, 0xd186b8c721c0c207, 0xeada7dd6cde0eb1e, 0xf57d4f7fee6ed178,
				0x06f067aa72176fba, 0x0a637dc5a2c898a6, 0x113f9804bef90dae, 0x1b710b35131c471b,
				0x28db77f523047d84, 0x32caab7b40c72493, 0x3c9ebe0a15c9bebc, 0x431d67c49c100d4c,
				0x4cc5d4becb3e42b6, 0x597f299cfc657e2a, 0x5fcb6fab3ad6faec, 0x6c44198c4a475817
			>>
		end

	process_block
			-- Process the current 1024-bit (128-byte) block in `buffer`.
		local
			a, b, c, d, e, f, g, h_val: NATURAL_64
			t1, t2: NATURAL_64
			i: INTEGER
		do
			-- 1. Build message schedule W[0..79] from the 16 big-endian 64-bit words
			--    in the buffer, then extend to 80 words via the sigma recurrence.
			from i := 0 until i >= 16 loop
				w [i] := (buffer [i * 8].to_natural_64.bit_shift_left (56)).bit_or (
						 (buffer [i * 8 + 1].to_natural_64.bit_shift_left (48))).bit_or (
						 (buffer [i * 8 + 2].to_natural_64.bit_shift_left (40))).bit_or (
						 (buffer [i * 8 + 3].to_natural_64.bit_shift_left (32))).bit_or (
						 (buffer [i * 8 + 4].to_natural_64.bit_shift_left (24))).bit_or (
						 (buffer [i * 8 + 5].to_natural_64.bit_shift_left (16))).bit_or (
						 (buffer [i * 8 + 6].to_natural_64.bit_shift_left (8))).bit_or (
						 (buffer [i * 8 + 7].to_natural_64))
				i := i + 1
			end
			from i := 16 until i >= 80 loop
				w [i] := sigma1 (w [i - 2]) + w [i - 7] + sigma0 (w [i - 15]) + w [i - 16]
				i := i + 1
			end

			-- 2. Initialize working variables from current hash state
			a := h0
			b := h1
			c := h2
			d := h3
			e := h4
			f := h5
			g := h6
			h_val := h7

			-- 3. 80-round compression.
			--    K is 1-based, so K[i+1] with i in 0..79 gives K[1]..K[80].
			from i := 0 until i >= 80 loop
				t1 := h_val + big_sigma1 (e) + ch (e, f, g) + K [i + 1] + w [i]
				t2 := big_sigma0 (a) + maj (a, b, c)
				h_val := g
				g := f
				f := e
				e := d + t1
				d := c
				c := b
				b := a
				a := t1 + t2
				i := i + 1
			end

			-- 4. Add compressed chunk to current hash state
			h0 := h0 + a
			h1 := h1 + b
			h2 := h2 + c
			h3 := h3 + d
			h4 := h4 + e
			h5 := h5 + f
			h6 := h6 + g
			h7 := h7 + h_val
		end

	rotr (x: NATURAL_64; n: INTEGER): NATURAL_64
			-- Rotate x right by n bits.
		do
			Result := (x.bit_shift_right (n)).bit_or (x.bit_shift_left (64 - n))
		end

	shr (x: NATURAL_64; n: INTEGER): NATURAL_64
			-- Logical right shift of x by n bits.
		do
			Result := x.bit_shift_right (n)
		end

	sigma0 (x: NATURAL_64): NATURAL_64
			-- Message schedule σ0: ROTR(1) ⊕ ROTR(8) ⊕ SHR(7)  (FIPS 180-4 §4.1.3)
		do
			Result := rotr (x, 1).bit_xor (rotr (x, 8)).bit_xor (shr (x, 7))
		end

	sigma1 (x: NATURAL_64): NATURAL_64
			-- Message schedule σ1: ROTR(19) ⊕ ROTR(61) ⊕ SHR(6)  (FIPS 180-4 §4.1.3)
		do
			Result := rotr (x, 19).bit_xor (rotr (x, 61)).bit_xor (shr (x, 6))
		end

	big_sigma0 (x: NATURAL_64): NATURAL_64
			-- Compression Σ0: ROTR(28) ⊕ ROTR(34) ⊕ ROTR(39)  (FIPS 180-4 §4.1.3)
		do
			Result := rotr (x, 28).bit_xor (rotr (x, 34)).bit_xor (rotr (x, 39))
		end

	big_sigma1 (x: NATURAL_64): NATURAL_64
			-- Compression Σ1: ROTR(14) ⊕ ROTR(18) ⊕ ROTR(41)  (FIPS 180-4 §4.1.3)
		do
			Result := rotr (x, 14).bit_xor (rotr (x, 18)).bit_xor (rotr (x, 41))
		end

	ch (x, y, z: NATURAL_64): NATURAL_64
			-- Choice: (x AND y) XOR (NOT x AND z)  (FIPS 180-4 §4.1.3)
		do
			Result := (x.bit_and (y)).bit_xor ((x.bit_not).bit_and (z))
		end

	maj (x, y, z: NATURAL_64): NATURAL_64
			-- Majority: (x AND y) XOR (x AND z) XOR (y AND z)  (FIPS 180-4 §4.1.3)
		do
			Result := (x.bit_and (y)).bit_xor (x.bit_and (z)).bit_xor (y.bit_and (z))
		end

	append_nat64_be (val: NATURAL_64; target: STRING_8)
			-- Append the 8 bytes of `val` to `target` in big-endian order.
		do
			target.append_character (val.bit_shift_right (56).bit_and (0xFF).to_character_8)
			target.append_character (val.bit_shift_right (48).bit_and (0xFF).to_character_8)
			target.append_character (val.bit_shift_right (40).bit_and (0xFF).to_character_8)
			target.append_character (val.bit_shift_right (32).bit_and (0xFF).to_character_8)
			target.append_character (val.bit_shift_right (24).bit_and (0xFF).to_character_8)
			target.append_character (val.bit_shift_right (16).bit_and (0xFF).to_character_8)
			target.append_character (val.bit_shift_right (8).bit_and (0xFF).to_character_8)
			target.append_character (val.bit_and (0xFF).to_character_8)
		end

	bytes_to_hex (bytes: STRING_8): STRING_8
			-- Convert raw byte string to lowercase hex representation.
		local
			i: INTEGER
			code: NATURAL_32
			hex: STRING_8
		do
			create Result.make (bytes.count * 2)
			from i := 1 until i > bytes.count loop
				code := bytes.code (i)
				hex := code.to_hex_string
				Result.append (hex.substring (7, 8).as_lower)
				i := i + 1
			end
		ensure
			correct_length: Result.count = bytes.count * 2
		end

end
