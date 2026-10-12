note
	description: "[
		Abstract base class for PDF security handlers.
		Provides deferred operations for encrypting and decrypting
		strings and streams per ISO 32000-1:2008 Section 7.6.
		
		AES Rev 4+ may use different CryptFilters for streams (/StmF)
		vs strings (/StrF), so both pairs must be implemented.
	]"

deferred class
	PDF_SECURITY_HANDLER

feature -- Access

	filter_name: STRING_8
			-- The name of the security handler (e.g., "Standard").
			-- Uses STRING_8 as PDF security handler names are ASCII byte sequences.
		deferred
		end

	encryption_key_length: INTEGER
			-- Length of the encryption key in bits.
		deferred
		end

feature -- Status Report

	is_authorized: BOOLEAN
			-- Has the user been authorized (e.g., password verified)?
		deferred
		end

feature -- Basic Operations

	authorize (a_password: STRING_8)
			-- Attempt to authorize with the given password.
			-- Uses STRING_8 as PDF passwords are byte sequences per ISO 32000-1:2008.
		deferred
		ensure
			authorized_if_correct: is_authorized implies True -- (Specifics depend on implementation)
		end

	encrypt_string (a_string: STRING_8; obj_num, gen_num: INTEGER): STRING_8
			-- Encrypt a string for the given object and generation number.
			-- Uses STRING_8 for binary byte sequences in cryptographic operations.
		deferred
		end

	decrypt_string (a_string: STRING_8; obj_num, gen_num: INTEGER): STRING_8
			-- Decrypt a string for the given object and generation number.
			-- Uses STRING_8 for binary byte sequences in cryptographic operations.
		deferred
		end

	encrypt_stream (a_data: STRING_8; obj_num, gen_num: INTEGER): STRING_8
			-- Encrypt a stream for the given object and generation number.
			-- May use a different CryptFilter than `encrypt_string` (AES Rev 4+: /StmF).
		deferred
		end

	decrypt_stream (a_data: STRING_8; obj_num, gen_num: INTEGER): STRING_8
			-- Decrypt a stream for the given object and generation number.
			-- May use a different CryptFilter than `decrypt_string` (AES Rev 4+: /StmF).
		deferred
		end

end
