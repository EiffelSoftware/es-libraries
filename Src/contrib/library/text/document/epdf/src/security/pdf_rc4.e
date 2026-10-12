note
	description: "RC4 Encryption Algorithm to support PDF encryption."

class
	PDF_RC4

create
	make

feature -- Initialization

	make (a_key: STRING_8)
			-- Initialize RC4 with the given key.
			-- Uses STRING_8 as RC4 keys are binary byte sequences.
		require
			key_not_empty: not a_key.is_empty
			key_length_valid: a_key.count >= 1 and a_key.count <= 256
		local
			i, j: INTEGER
			temp: INTEGER
			l_key_bytes: SPECIAL [INTEGER]
		do
			create s_box.make_filled (0, 256)
			create l_key_bytes.make_filled (0, a_key.count)

				-- Convert key to integer bytes
			from
				i := 0
			until
				i >= a_key.count
			loop
				l_key_bytes [i] := a_key.code (i + 1).to_integer_32
				i := i + 1
			end

				-- Initialize S-box
			from
				i := 0
			until
				i > 255
			loop
				s_box [i] := i
				i := i + 1
			end

				-- Key Scheduling Algorithm (KSA)
			j := 0
			from
				i := 0
			until
				i > 255
			loop
				j := (j + s_box [i] + l_key_bytes [i \\ a_key.count]) \\ 256

					-- Swap S[i] and S[j]
				temp := s_box [i]
				s_box [i] := s_box [j]
				s_box [j] := temp

				i := i + 1
			end

				-- Initialize indices for stream generation
			index_i := 0
			index_j := 0
		end

feature -- Access

	process_string (a_data: STRING_8): STRING_8
			-- Encrypt or decrypt the given string (operation is symmetric).
			-- Returns a new string.
			-- Uses STRING_8 for binary byte sequences in cryptographic operations.
		local
			i, k: INTEGER
			l_byte, l_cipher: INTEGER
			l_result: STRING_8
		do
			create l_result.make (a_data.count)

			from
				i := 1
			until
				i > a_data.count
			loop
					-- PRGA Step
				index_i := (index_i + 1) \\ 256
				index_j := (index_j + s_box [index_i]) \\ 256

					-- Swap
				swap (index_i, index_j)

					-- Generate keystream byte
				k := s_box [(s_box [index_i] + s_box [index_j]) \\ 256]

					-- XOR with data byte
				l_byte := a_data.code (i).to_integer_32
				l_cipher := l_byte.bit_xor (k)

				l_result.append_character (l_cipher.to_character_8)

				i := i + 1
			end

			Result := l_result
		end

	transform_in_place (a_data: STRING_8)
			-- Encrypt or decrypt the given string in place.
			-- Uses STRING_8 for binary byte sequences in cryptographic operations.
		local
			i, k: INTEGER
			l_byte, l_cipher: INTEGER
		do
			from
				i := 1
			until
				i > a_data.count
			loop
					-- PRGA Step
				index_i := (index_i + 1) \\ 256
				index_j := (index_j + s_box [index_i]) \\ 256

					-- Swap
				swap (index_i, index_j)

					-- Generate keystream byte
				k := s_box [(s_box [index_i] + s_box [index_j]) \\ 256]

					-- XOR with data byte
				l_byte := a_data.code (i).to_integer_32
				l_cipher := l_byte.bit_xor (k)

				a_data.put_code (l_cipher.to_natural_32, i)

				i := i + 1
			end
		end

feature {NONE} -- Implementation

	s_box: SPECIAL [INTEGER]
	index_i: INTEGER
	index_j: INTEGER

	swap (ai, aj: INTEGER)
		local
			temp: INTEGER
		do
			temp := s_box [ai]
			s_box [ai] := s_box [aj]
			s_box [aj] := temp
		end

end
