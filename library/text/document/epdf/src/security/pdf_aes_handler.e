note
	description: "[
		AES encryption/decryption handler for PDF documents (Revision 4+).
		Uses PKCS#7 padding as required by PDF AES encryption.
		
		Binary Data Representation:
		All STRING_8 parameters are treated as raw byte sequences where
		each CHARACTER_8 represents exactly one byte (0-255). This class
		does NOT interpret strings as text - no encoding is assumed.
		Internally, data can be converted to ARRAY [NATURAL_8] for explicit
		binary safety using the conversion helpers.
		
		Failure Semantics:
		- Decryption operations raise exceptions on malformed input.
		- Invalid padding or corrupted ciphertext will cause contract violations.
		- Callers should use preconditions or rescue clauses to handle failures.
		
		Security Note:
		- AES-CBC does NOT provide integrity protection.
		- Tampered ciphertext may decrypt to garbage without detection.
		- Random IVs use the unstable crypto library CSPRNG_FACTORY / OS CSPRNG.
	]"

class
	PDF_AES_HANDLER

create
	make_128, make_256

feature {NONE} -- Initialization

	make_128
			-- Initialize for AES-128 (16-byte key).
		do
			key_length := 16
			create aes.make_with_params (create {AES_128_PARAMETERS})
		ensure
			key_length_set: key_length = 16
		end

	make_256
			-- Initialize for AES-256 (32-byte key).
		do
			key_length := 32
			create aes.make_with_params (create {AES_256_PARAMETERS})
		ensure
			key_length_set: key_length = 32
		end

feature -- Access

	key_length: INTEGER
			-- Required key length in bytes (16 for AES-128, 32 for AES-256).

	block_length: INTEGER = 16
			-- AES block size in bytes.

feature -- Status Report

	is_valid_encrypted_stream (a_data: STRING_8): BOOLEAN
			-- Is `a_data` a valid encrypted PDF stream?
			-- Must have IV (16 bytes) + at least one block of ciphertext.
		do
			Result := a_data.count >= block_length * 2
				and then (a_data.count - block_length) \\ block_length = 0
		ensure
			definition: Result = (a_data.count >= block_length * 2
				and then (a_data.count - block_length) \\ block_length = 0)
		end

feature -- Operations

	encrypt_bytes (a_data, a_key, a_iv: STRING_8): STRING_8
			-- Encrypt `a_data` using AES-CBC mode with `a_key` and `a_iv`.
			-- PKCS#7 padding is applied to `a_data` before encryption.
		require
			key_valid: a_key.count = key_length
			iv_valid: a_iv.count = block_length
		do
			Result := aes.cbc_encoding_string (a_data, a_key, a_iv)
		ensure
			result_attached: Result /= Void
			result_padded: Result.count \\ block_length = 0
			result_not_empty: Result.count >= block_length
		end

	decrypt_bytes (a_data, a_key, a_iv: STRING_8): STRING_8
			-- Decrypt `a_data` using AES-CBC mode with `a_key` and `a_iv`.
			-- PKCS#7 padding is removed after decryption.
		require
			key_valid: a_key.count = key_length
			iv_valid: a_iv.count = block_length
			data_not_empty: a_data.count > 0
			data_multiple_of_block: a_data.count \\ block_length = 0
		do
			Result := aes.cbc_decoding_string (a_data, a_key, a_iv)
		ensure
			result_attached: Result /= Void
		end

	decrypt_pdf_stream (a_data, a_key: STRING_8): STRING_8
			-- Decrypt a PDF stream where IV is prepended to the data.
			-- Per ISO 32000-1:2008 Section 7.6.2: The first 16 bytes of the stream
			-- data are the initialization vector for the decryption.
			--
			-- Raises contract violation on malformed input.
			-- Use `is_valid_encrypted_stream` to check before calling.
		require
			key_valid: a_key.count = key_length
			data_long_enough: a_data.count >= block_length
			valid_stream_format: is_valid_encrypted_stream (a_data)
		local
			l_iv: STRING_8
			l_encrypted: STRING_8
		do
				-- Extract IV from first 16 bytes
			l_iv := a_data.substring (1, block_length)
				-- Extract remaining encrypted data
			l_encrypted := a_data.substring (block_length + 1, a_data.count)

			check
				valid_encrypted_length: l_encrypted.count > 0 and then l_encrypted.count \\ block_length = 0
			end
			Result := decrypt_bytes (l_encrypted, a_key, l_iv)
		ensure
			result_attached: Result /= Void
		end

	encrypt_pdf_stream (a_data, a_key: STRING_8): STRING_8
			-- Encrypt a PDF stream with random IV prepended.
			-- Per ISO 32000-1:2008 Section 7.6.2: A random 16-byte IV is
			-- generated and prepended to the encrypted data.
		require
			key_valid: a_key.count = key_length
		local
			l_iv: STRING_8
			l_encrypted: STRING_8
		do
				-- Generate random IV
			l_iv := generate_random_iv

				-- Encrypt data
			l_encrypted := encrypt_bytes (a_data, a_key, l_iv)

				-- Prepend IV to encrypted data
			create Result.make (l_iv.count + l_encrypted.count)
			Result.append (l_iv)
			Result.append (l_encrypted)
		ensure
			result_attached: Result /= Void
			result_has_iv: Result.count >= block_length
			result_valid_format: is_valid_encrypted_stream (Result)
		end

	decrypt_pdf_string (a_data, a_key: STRING_8): STRING_8
			-- Decrypt a PDF string where IV is prepended to the data.
			-- Same as stream decryption per ISO 32000-1:2008.
			--
			-- Raises contract violation on malformed input.
			-- Use `is_valid_encrypted_stream` to check before calling.
		require
			key_valid: a_key.count = key_length
			data_long_enough: a_data.count >= block_length
			valid_string_format: is_valid_encrypted_stream (a_data)
		do
			Result := decrypt_pdf_stream (a_data, a_key)
		ensure
			result_attached: Result /= Void
		end

	encrypt_pdf_string (a_data, a_key: STRING_8): STRING_8
			-- Encrypt a PDF string with random IV prepended.
		require
			key_valid: a_key.count = key_length
		do
			Result := encrypt_pdf_stream (a_data, a_key)
		ensure
			result_attached: Result /= Void
			result_valid_format: is_valid_encrypted_stream (Result)
		end

feature {NONE} -- Implementation

	aes: AES
			-- AES engine.

	generate_random_iv: STRING_8
			-- Generate a random 16-byte initialization vector from OS CSPRNG.
		require
			block_positive: block_length > 0
		local
			l_factory: CSPRNG_FACTORY
			l_rng: CSPRNG
		do
			create l_factory
			check
				csprng_available: l_factory.is_csprng_available
			end
			l_rng := l_factory.new_csprng
			Result := l_rng.fill_bytes_string (block_length)
			check
				csprng_fill_ok: not l_rng.has_error
			end
		ensure
			result_length: Result.count = block_length
		end

feature {NONE} -- Binary Conversion Helpers

	string_to_bytes (a_string: STRING_8): ARRAY [NATURAL_8]
			-- Convert STRING_8 to byte array.
			-- Each character code is treated as a byte value (0-255).
		local
			i: INTEGER
		do
			create Result.make_filled ({NATURAL_8} 0, 1, a_string.count)
			from
				i := 1
			until
				i > a_string.count
			loop
				Result [i] := a_string.code (i).to_natural_8
				i := i + 1
			end
		ensure
			same_count: Result.count = a_string.count
		end

	bytes_to_string (a_bytes: ARRAY [NATURAL_8]): STRING_8
			-- Convert byte array to STRING_8.
			-- Each byte value becomes a character with that code.
		local
			i: INTEGER
		do
			create Result.make (a_bytes.count)
			from
				i := a_bytes.lower
			until
				i > a_bytes.upper
			loop
				Result.append_character (a_bytes [i].to_character_8)
				i := i + 1
			end
		ensure
			same_count: Result.count = a_bytes.count
		end

invariant
	aes_attached: aes /= Void
	valid_key_length: key_length = 16 or key_length = 32
	block_length_valid: block_length = 16

end
