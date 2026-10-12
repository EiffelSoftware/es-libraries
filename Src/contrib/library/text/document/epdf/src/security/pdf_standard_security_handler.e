note
	description: "[
		Standard Security Handler with RC4 (Rev 2/3) and AES (Rev 4+) support.
		Per ISO 32000-1:2008 Section 7.6.
		
		Supported revisions:
		  Rev 2: RC4-40
		  Rev 3: RC4-128 (variable key length)
		  Rev 4: AES-128 or RC4-128 via CryptFilter (/CF, /StmF, /StrF)
		  Rev 5/6: AES-256 with SHA-256 key derivation (ISO 32000-1 ext level 3)
	]"

class
	PDF_STANDARD_SECURITY_HANDLER

inherit
	PDF_SECURITY_HANDLER

create
	make

feature -- Initialization

	make (a_encrypt_dict: PDF_DICTIONARY; a_file_id: detachable PDF_ARRAY; a_password: STRING_8)
			-- Initialize with encryption dictionary, file ID, and password.
		do
			encrypt_dict := a_encrypt_dict
			file_id := a_file_id

				-- Extract P value (Permissions)
			if attached {PDF_NUMBER} encrypt_dict.item ("P") as l_p then
				permissions_flags := l_p.int_value
			else
				permissions_flags := -1 -- Default
			end

				-- Extract Length (Key length in bits)
			if attached {PDF_NUMBER} encrypt_dict.item ("Length") as l_len then
				encryption_key_length := l_len.int_value
			else
				encryption_key_length := 40 -- Default
			end

				-- Extract V (Version)
			if attached {PDF_NUMBER} encrypt_dict.item ("V") as l_v then
				version := l_v.int_value
			else
				version := 0
			end

				-- Extract R (Revision)
			if attached {PDF_NUMBER} encrypt_dict.item ("R") as l_r then
				revision := l_r.int_value
			else
				revision := 0
			end

				-- Extract O (Owner Key)
			if attached {PDF_STRING} encrypt_dict.item ("O") as l_o then
				owner_key := l_o.value
			else
				owner_key := "" -- Should not happen in valid dictionary
			end

				-- Extract U (User Key)
			if attached {PDF_STRING} encrypt_dict.item ("U") as l_u then
				user_key := l_u.value
			else
				user_key := "" -- Should not happen
			end

				-- Extract UE and OE entries (Rev 5/6 only)
			if attached {PDF_STRING} encrypt_dict.item ("UE") as l_ue then
				user_encryption_key := l_ue.value
			else
				create user_encryption_key.make_empty
			end
			if attached {PDF_STRING} encrypt_dict.item ("OE") as l_oe then
				owner_encryption_key := l_oe.value
			else
				create owner_encryption_key.make_empty
			end

				-- Check if metadata is encrypted (default true)
			encrypt_metadata := True
			if attached {PDF_BOOLEAN} encrypt_dict.item ("EncryptMetadata") as l_em then
				encrypt_metadata := l_em.value
			end

				-- Parse CryptFilter entries (Rev 4+)
			parse_crypt_filters

				-- Initialize encryption_key before authorize
			create encryption_key.make_empty
			authorize (a_password)
		end

feature -- Access

	filter_name: STRING_8
		do
			Result := "Standard"
		end

	encryption_key_length: INTEGER

	permissions_flags: INTEGER

	is_authorized: BOOLEAN

	u_entry: STRING_8
			-- User password entry computed U value for writing to encrypt dictionary.
		do
			Result := user_key
		end

	o_entry: STRING_8
			-- Owner password entry computed O value for writing to encrypt dictionary.
		do
			Result := owner_key
		end

	current_revision: INTEGER
			-- Current revision for debugging.
		do
			Result := revision
		end

feature -- Operations

	authorize (a_password: STRING_8)
			-- Attempt to authorize with the given password (Algorithm 6 & 7).
			-- Uses STRING_8 as PDF passwords are byte sequences per ISO 32000-1:2008.
		local
			is_user_valid: BOOLEAN
			is_owner_valid: BOOLEAN
		do
			if revision >= 5 then
					-- Try as user password (Rev 5/6)
				is_user_valid := verify_user_password_rev5 (a_password)

					-- Try as owner password (Rev 5/6)
				if not is_user_valid then
					is_owner_valid := verify_owner_password_rev5 (a_password)
				end

				is_authorized := is_user_valid or is_owner_valid

				if is_authorized then
					if is_user_valid then
						encryption_key := compute_encryption_key_user_rev5 (a_password)
					else
						encryption_key := compute_encryption_key_owner_rev5 (a_password)
					end
				end
			else
					-- Try as user password (Algorithm 6)
				is_user_valid := verify_user_password (a_password)

					-- Try as owner password (Algorithm 7)
				if not is_user_valid then
					is_owner_valid := verify_owner_password (a_password)
				end

				is_authorized := is_user_valid or is_owner_valid

				if is_authorized then
					if is_user_valid then
						encryption_key := compute_encryption_key (a_password)
					else
							-- Owner password: derive user password first, then encryption key
						encryption_key := compute_encryption_key (recover_user_password_from_owner (a_password))
					end
				end
			end
		end

	compute_password_entries (user_password, owner_password: STRING_8)
			-- Compute U and O entries for creating a new encrypted PDF.
			-- This implements the forward direction of Algorithms 3, 4, and 5.
			-- Call this BEFORE adding U and O to the encrypt dictionary.
		require
			user_password_not_void: user_password /= Void
			owner_password_not_void: owner_password /= Void
		local
			enc_key: STRING_8
		do
				-- Compute O entry (Algorithm 3 - forward direction)
			owner_key := compute_o_value (owner_password, user_password)

				-- Compute encryption key from user password (Algorithm 2)
			enc_key := compute_encryption_key (user_password)

				-- Compute U entry (Algorithm 4 or 5 depending on revision)
			if revision >= 3 then
				user_key := compute_u_value_rev3 (enc_key)
			else
				user_key := compute_u_value_rev2 (enc_key)
			end

				-- Store encryption key for later use
			encryption_key := enc_key
			is_authorized := True
		ensure
			authorized: is_authorized
			user_key_set: user_key /= Void and then not user_key.is_empty
			owner_key_set: owner_key /= Void and then not owner_key.is_empty
		end

	encrypt_string (a_string: STRING_8; obj_num, gen_num: INTEGER): STRING_8
			-- Encrypt a string for the given object and generation number.
			-- Uses STRING_8 for binary byte sequences in cryptographic operations.
		local
			l_key: STRING_8
			rc4: PDF_RC4
		do
			l_key := compute_object_key (obj_num, gen_num)
			if is_aes_encryption then
				-- AES encryption with random IV prepended
				Result := aes_handler.encrypt_pdf_string (a_string, l_key)
			else
				-- RC4 encryption
				create rc4.make (l_key)
				Result := rc4.process_string (a_string)
			end
		end

	decrypt_string (a_string: STRING_8; obj_num, gen_num: INTEGER): STRING_8
			-- Decrypt a string for the given object and generation number.
			-- Uses the string CryptFilter (/StrF) per ISO 32000-1:2008 §7.6.3.2.
		local
			l_key: STRING_8
			rc4: PDF_RC4
		do
			l_key := compute_object_key (obj_num, gen_num)
			if is_aes_string_encryption then
				-- AES decryption with IV extracted from first 16 bytes
				if a_string.count >= 16 then
					Result := aes_handler.decrypt_pdf_string (a_string, l_key)
				else
					-- Too short for AES, return empty
					create Result.make_empty
				end
			else
				-- RC4 is symmetric
				create rc4.make (l_key)
				Result := rc4.process_string (a_string)
			end
		end

	encrypt_stream (a_data: STRING_8; obj_num, gen_num: INTEGER): STRING_8
			-- Encrypt a stream for the given object and generation number.
			-- Uses the stream CryptFilter (/StmF) per ISO 32000-1:2008 §7.6.3.2.
		local
			l_key: STRING_8
			rc4: PDF_RC4
		do
			l_key := compute_object_key (obj_num, gen_num)
			if is_aes_stream_encryption then
				Result := aes_handler.encrypt_pdf_stream (a_data, l_key)
			else
				create rc4.make (l_key)
				Result := rc4.process_string (a_data)
			end
		end

	decrypt_stream (a_data: STRING_8; obj_num, gen_num: INTEGER): STRING_8
			-- Decrypt a stream for the given object and generation number.
			-- Uses the stream CryptFilter (/StmF) per ISO 32000-1:2008 §7.6.3.2.
		local
			l_key: STRING_8
			rc4: PDF_RC4
		do
			l_key := compute_object_key (obj_num, gen_num)
			if is_aes_stream_encryption then
				if a_data.count >= 16 then
					Result := aes_handler.decrypt_pdf_stream (a_data, l_key)
				else
					create Result.make_empty
				end
			else
				create rc4.make (l_key)
				Result := rc4.process_string (a_data)
			end
		end

feature -- Status Report

	is_aes_encryption: BOOLEAN
			-- Is AES used for either strings or streams (Revision 4+)?
		do
			Result := is_aes_string_encryption or is_aes_stream_encryption
		end

	is_aes_string_encryption: BOOLEAN
			-- Is AES used for string encryption?
			-- Checks CryptFilter method first, falls back to revision.
		do
			if not string_crypt_method.is_empty then
				Result := string_crypt_method.is_equal ("AESV2") or string_crypt_method.is_equal ("AESV3")
			else
				Result := revision >= 4
			end
		end

	is_aes_stream_encryption: BOOLEAN
			-- Is AES used for stream encryption?
			-- Checks CryptFilter method first, falls back to revision.
		do
			if not stream_crypt_method.is_empty then
				Result := stream_crypt_method.is_equal ("AESV2") or stream_crypt_method.is_equal ("AESV3")
			else
				Result := revision >= 4
			end
		end

	is_rev5_or_later: BOOLEAN
			-- Is this revision 5 or later (AES-256 with SHA-256 key derivation)?
		do
			Result := revision >= 5
		end

feature {NONE} -- Implementation

	encrypt_dict: PDF_DICTIONARY
	file_id: detachable PDF_ARRAY
	version: INTEGER
	revision: INTEGER
	owner_key: STRING_8
	user_key: STRING_8
	encryption_key: STRING_8
	encrypt_metadata: BOOLEAN
	user_encryption_key: STRING_8
			-- /UE entry: intermediate file encryption key encrypted with user password (Rev 5/6).
	owner_encryption_key: STRING_8
			-- /OE entry: intermediate file encryption key encrypted with owner password (Rev 5/6).
	string_crypt_method: STRING_8
			-- CryptFilter method for strings (/StrF -> /CFM), e.g. "AESV2", "AESV3", "V2".
			-- Empty if no CryptFilter dictionary present.
	stream_crypt_method: STRING_8
			-- CryptFilter method for streams (/StmF -> /CFM), e.g. "AESV2", "AESV3", "V2".
			-- Empty if no CryptFilter dictionary present.

	aes_handler: PDF_AES_HANDLER
			-- AES encryption handler (used for Revision 4+).
		do
			if attached internal_aes_handler as l_handler then
				Result := l_handler
			else
				if encryption_key_length = 256 then
					create Result.make_256
				else
					create Result.make_128
				end
				internal_aes_handler := Result
			end
		end

	internal_aes_handler: detachable PDF_AES_HANDLER
			-- Cached AES handler instance.

	padding_string: STRING_8
		once
			Result := "%/0x28/%/0xBF/%/0x4E/%/0x5E/%/0x4E/%/0x75/%/0x8A/%/0x41/%/0x64/%/0x00/%/0x4E/%/0x56/%/0xFF/%/0xFA/%/0x01/%/0x08/%/0x2E/%/0x2E/%/0x00/%/0xB6/%/0xD0/%/0x68/%/0x3E/%/0x80/%/0x2F/%/0x0C/%/0xA9/%/0xFE/%/0x64/%/0x53/%/0x69/%/0x7A/"
		end

	parse_crypt_filters
			-- Parse CryptFilter entries (/CF, /StmF, /StrF) from encrypt dictionary.
			-- Per ISO 32000-1:2008 Section 7.6.3.2.
			-- Sets `stream_crypt_method` and `string_crypt_method` attributes.
		local
			l_stm_filter_name: STRING_8
			l_str_filter_name: STRING_8
		do
				-- Initialize to empty (no CryptFilter specified)
			create string_crypt_method.make_empty
			create stream_crypt_method.make_empty

				-- Extract /StmF and /StrF filter names
			if attached {PDF_NAME} encrypt_dict.item ("StmF") as l_stmf then
				l_stm_filter_name := l_stmf.value
			else
				create l_stm_filter_name.make_empty
			end

			if attached {PDF_NAME} encrypt_dict.item ("StrF") as l_strf then
				l_str_filter_name := l_strf.value
			else
				create l_str_filter_name.make_empty
			end

				-- Resolve filter names to /CFM values via /CF dictionary
			if attached {PDF_DICTIONARY} encrypt_dict.item ("CF") as l_cf then
				if not l_stm_filter_name.is_empty then
					stream_crypt_method := resolve_crypt_filter_method (l_cf, l_stm_filter_name)
				end
				if not l_str_filter_name.is_empty then
					string_crypt_method := resolve_crypt_filter_method (l_cf, l_str_filter_name)
				end
			end
		end

	resolve_crypt_filter_method (a_cf_dict: PDF_DICTIONARY; a_filter_name: STRING_8): STRING_8
			-- Resolve the /CFM value for the named CryptFilter.
			-- Returns the method name (e.g. "AESV2", "AESV3", "V2", "None"),
			-- or empty string if not found.
		require
			cf_dict_attached: a_cf_dict /= Void
			filter_name_not_empty: not a_filter_name.is_empty
		do
			if attached {PDF_DICTIONARY} a_cf_dict.item (a_filter_name) as l_filter_dict then
				if attached {PDF_NAME} l_filter_dict.item ("CFM") as l_cfm then
					Result := l_cfm.value
				else
					create Result.make_empty
				end
			else
				create Result.make_empty
			end
		ensure
			result_attached: Result /= Void
		end

	compute_encryption_key (a_password: STRING_8): STRING_8
			-- Algorithm 2: Computing the encryption key.
			-- Uses STRING_8 for binary byte sequences in cryptographic operations.
		local
			md5: PDF_MD5
			tmp: STRING_8
			l_key_len_bytes: INTEGER
			i: INTEGER
		do
			create md5.make
			l_key_len_bytes := encryption_key_length // 8

				-- 1. Pad or truncate password to 32 bytes
			tmp := pad_password (a_password)

				-- 2. Pass to MD5
			md5.update (tmp)

				-- 3. Pass O entry
			md5.update (owner_key)

				-- 4. Pass P entry (as 4 byte/32-bit integer, low-order byte first)
			tmp := int_to_bytes (permissions_flags)
			md5.update (tmp)

				-- 5. Pass first element of ID array
			if attached file_id as l_file_id and then l_file_id.count > 0 then
				if attached {PDF_STRING} l_file_id.item (1) as l_id then
					md5.update (l_id.value)
				end
			end

				-- 6. (Revision 4) If metadata not encrypted, pass 4 bytes of -1
			if revision >= 4 and not encrypt_metadata then
				md5.update ("%/0xFF/%/0xFF/%/0xFF/%/0xFF/")
			end

				-- 7. Finish hash
			md5.finish
			tmp := md5.digest_as_string

				-- 8. (Revision 3 or greater) Repeat 50 times
			if revision >= 3 then
				from
					i := 0
				until
					i >= 50
				loop
					md5.reset
					md5.update (tmp.substring (1, l_key_len_bytes))
					md5.finish
					tmp := md5.digest_as_string
					i := i + 1
				end
			end

				-- 9. Set encryption key to first n bytes
			Result := tmp.substring (1, l_key_len_bytes)
		end

	compute_object_key (obj_num, gen_num: INTEGER): STRING_8
			-- Algorithm 1: Computing the encryption key for an object.
			-- Uses STRING_8 for binary byte sequences in cryptographic operations.
			-- For AES, appends "sAlT" per ISO 32000-1:2008 Section 7.6.2.
		local
			md5: PDF_MD5
			tmp: STRING_8
			len: INTEGER
		do
			create md5.make
			md5.update (encryption_key)

				-- Append object number (3 bytes, low byte first)
			tmp := int_to_bytes_3 (obj_num)
			md5.update (tmp)

				-- Append generation number (2 bytes, low byte first)
			tmp := int_to_bytes_2 (gen_num)
			md5.update (tmp)

				-- For AES encryption, append "sAlT" (4 bytes)
			if is_aes_encryption then
				md5.update ("sAlT")
			end

			md5.finish
			tmp := md5.digest_as_string

			if is_aes_encryption then
				-- AES-128 uses 16-byte key
				len := 16
			else
				-- RC4: key length + 5, max 16
				len := (encryption_key_length // 8) + 5
				if len > 16 then
					len := 16
				end
			end

			Result := tmp.substring (1, len)
		end

	pad_password (pwd: STRING_8): STRING_8
			-- Pad or truncate password to 32 bytes.
			-- Uses STRING_8 for binary byte sequences.
		local
			res: STRING_8
		do
			res := pwd.twin
			if res.count < 32 then
				res.append (padding_string.substring (1, 32 - res.count))
			elseif res.count > 32 then
				res := res.substring (1, 32)
			end
			Result := res
		end

	int_to_bytes (val: INTEGER): STRING_8
			-- 4 bytes, little endian.
			-- Uses STRING_8 for binary byte sequences.
		local
			res: STRING_8
			v: INTEGER
		do
			v := val
			create res.make (4)
			res.append_character ((v.bit_and (0xFF)).to_character_8)
			res.append_character ((v.bit_shift_right (8).bit_and (0xFF)).to_character_8)
			res.append_character ((v.bit_shift_right (16).bit_and (0xFF)).to_character_8)
			res.append_character ((v.bit_shift_right (24).bit_and (0xFF)).to_character_8)
			Result := res
		end

	int_to_bytes_3 (val: INTEGER): STRING_8
			-- 3 bytes, little endian.
			-- Uses STRING_8 for binary byte sequences.
		local
			res: STRING_8
			v: INTEGER
		do
			v := val
			create res.make (3)
			res.append_character ((v.bit_and (0xFF)).to_character_8)
			res.append_character ((v.bit_shift_right (8).bit_and (0xFF)).to_character_8)
			res.append_character ((v.bit_shift_right (16).bit_and (0xFF)).to_character_8)
			Result := res
		end

	int_to_bytes_2 (val: INTEGER): STRING_8
			-- 2 bytes, little endian.
			-- Uses STRING_8 for binary byte sequences.
		local
			res: STRING_8
			v: INTEGER
		do
			v := val
			create res.make (2)
			res.append_character ((v.bit_and (0xFF)).to_character_8)
			res.append_character ((v.bit_shift_right (8).bit_and (0xFF)).to_character_8)
			Result := res
		end

feature {NONE} -- Password Verification

	verify_user_password (a_password: STRING_8): BOOLEAN
			-- Verify user password (Algorithm 6, ISO 32000-1:2008).
			-- Uses STRING_8 for binary byte sequences.
		local
			test_key: STRING_8
			computed_u: STRING_8
		do
			if user_key.is_empty then
				Result := False
			else
					-- Compute encryption key with provided password
				test_key := compute_encryption_key (a_password)

					-- Compute what U should be with this key
				if revision >= 3 then
					computed_u := compute_u_value_rev3 (test_key)
				else
					computed_u := compute_u_value_rev2 (test_key)
				end

					-- Compare with stored U value
				if revision >= 3 then
					-- Rev 3+: Compare first 16 bytes only
					if user_key.count >= 16 then
						Result := strings_equal_first_n (computed_u, user_key, 16)
					else
						Result := False
					end
				else
					-- Rev 2: Compare all 32 bytes
					Result := computed_u.is_equal (user_key)
				end
			end
		end

	verify_owner_password (a_password: STRING_8): BOOLEAN
			-- Verify owner password (Algorithm 7, ISO 32000-1:2008).
			-- Uses STRING_8 for binary byte sequences.
		local
			user_pwd: STRING_8
		do
			if owner_key.is_empty then
				Result := False
			else
					-- Derive user password from owner password and O entry
				user_pwd := recover_user_password_from_owner (a_password)

					-- Verify using user password
				Result := verify_user_password (user_pwd)
			end
		end

	compute_u_value_rev2 (enc_key: STRING_8): STRING_8
			-- Algorithm 4: Computing U (Revision 2).
			-- Uses STRING_8 for binary byte sequences.
		local
			rc4: PDF_RC4
		do
			create rc4.make (enc_key)
			Result := rc4.process_string (padding_string)
		end

	compute_u_value_rev3 (enc_key: STRING_8): STRING_8
			-- Algorithm 5: Computing U (Revision 3 or greater).
			-- Uses STRING_8 for binary byte sequences.
		local
			md5: PDF_MD5
			tmp: STRING_8
			rc4: PDF_RC4
			i, j: INTEGER
			key: STRING_8
		do
				-- 1. MD5 hash of padding string
			create md5.make
			md5.update (padding_string)

				-- 2. Pass first element of file ID array
			if attached file_id as l_file_id and then l_file_id.count > 0 then
				if attached {PDF_STRING} l_file_id.item (1) as l_id then
					md5.update (l_id.value)
				end
			end

			md5.finish
			tmp := md5.digest_as_string

				-- 3. Encrypt with RC4 using encryption key
			create rc4.make (enc_key)
			tmp := rc4.process_string (tmp)

				-- 4. Do 19 times: encrypt with new key (key XOR iteration number)
			from i := 1 until i > 19 loop
				create key.make (enc_key.count)
				from j := 1 until j > enc_key.count loop
					key.append_character ((enc_key.code (j).bit_xor (i.to_natural_32)).to_character_8)
					j := j + 1
				end
				create rc4.make (key)
				rc4.transform_in_place (tmp)
				i := i + 1
			end

				-- 5. Result is tmp (concatenate arbitrary 16 bytes per spec)
				-- Spec says: "Append 16 bytes of arbitrary data"
				-- We'll use zeros for consistency
			Result := tmp + "%U%U%U%U%U%U%U%U%U%U%U%U%U%U%U%U"
		end

	recover_user_password_from_owner (owner_pwd: STRING_8): STRING_8
			-- Algorithm 3 (reverse): Recover user password from owner password.
			-- Uses STRING_8 for binary byte sequences.
		local
			md5: PDF_MD5
			key: STRING_8
			rc4: PDF_RC4
			tmp: STRING_8
			i, j, key_len: INTEGER
			derived_key: STRING_8
		do
				-- 1-3: Compute hash of owner password
			create md5.make
			tmp := pad_password (owner_pwd)
			md5.update (tmp)
			md5.finish
			key := md5.digest_as_string

				-- 4: (Rev 3+) Hash 50 times
			if revision >= 3 then
				key_len := encryption_key_length // 8
				from i := 0 until i >= 50 loop
					md5.reset
					md5.update (key.substring (1, key_len))
					md5.finish
					key := md5.digest_as_string
					i := i + 1
				end
			end

				-- Extract first n bytes as key
			if revision >= 3 then
				key := key.substring (1, encryption_key_length // 8)
			else
				key := key.substring (1, 5)
			end

				-- Decrypt O entry
			tmp := owner_key.twin

			if revision >= 3 then
					-- Do 19 times: decrypt with modified key
				from i := 19 until i < 0 loop
					create derived_key.make (key.count)
					from j := 1 until j > key.count loop
						derived_key.append_character ((key.code (j).bit_xor (i.to_natural_32)).to_character_8)
						j := j + 1
					end
					create rc4.make (derived_key)
					rc4.transform_in_place (tmp)
					i := i - 1
				end
			else
					-- Rev 2: Single RC4 decryption
				create rc4.make (key)
				tmp := rc4.process_string (tmp)
			end

				-- Result is the decrypted user password (may have padding)
			Result := tmp
		end

	compute_o_value (owner_password, user_password: STRING_8): STRING_8
			-- Algorithm 3: Computing the owner password value (forward direction).
			-- This is the forward version - for creating encrypted PDFs.
			-- Uses STRING_8 for binary byte sequences.
		local
			md5: PDF_MD5
			key: STRING_8
			rc4: PDF_RC4
			tmp: STRING_8
			i, j, key_len: INTEGER
			derived_key: STRING_8
		do
				-- 1. Pad or truncate owner password to 32 bytes
			create md5.make
			tmp := pad_password (owner_password)

				-- 2-3. MD5 hash of padded owner password
			md5.update (tmp)
			md5.finish
			key := md5.digest_as_string

				-- 4. (Rev 3+) Hash 50 times
			if revision >= 3 then
				key_len := encryption_key_length // 8
				from i := 0 until i >= 50 loop
					md5.reset
					md5.update (key.substring (1, key_len))
					md5.finish
					key := md5.digest_as_string
					i := i + 1
				end
			end

				-- 5. Extract first n bytes as RC4 key
			if revision >= 3 then
				key := key.substring (1, encryption_key_length // 8)
			else
				key := key.substring (1, 5)
			end

				-- 6. Pad or truncate user password
			tmp := pad_password (user_password)

				-- 7. Encrypt padded user password with RC4
			if revision >= 3 then
				-- Rev 3+: Encrypt 20 times with modified keys
				create rc4.make (key)
				tmp := rc4.process_string (tmp)

					-- Do 19 more times with XORed keys
				from i := 1 until i > 19 loop
					create derived_key.make (key.count)
					from j := 1 until j > key.count loop
						derived_key.append_character ((key.code (j).bit_xor (i.to_natural_32)).to_character_8)
						j := j + 1
					end
					create rc4.make (derived_key)
					rc4.transform_in_place (tmp)
					i := i + 1
				end
			else
					-- Rev 2: Single RC4 encryption
				create rc4.make (key)
				tmp := rc4.process_string (tmp)
			end

				-- Result is the encrypted O value
			Result := tmp
		end

	strings_equal_first_n (s1, s2: STRING_8; n: INTEGER): BOOLEAN
			-- Are first n bytes of s1 and s2 equal?
			-- Uses STRING_8 for binary byte sequences.
		require
			n_valid: n >= 0
			s1_long_enough: s1.count >= n
			s2_long_enough: s2.count >= n
		local
			i: INTEGER
		do
			Result := True
			from i := 1 until i > n or not Result loop
				Result := s1.code (i) = s2.code (i)
				i := i + 1
			end
		end

feature {NONE} -- Revision 5/6 Password Verification

	verify_user_password_rev5 (a_password: STRING_8): BOOLEAN
			-- Verify user password (Revision 5/6).
		local
			pwd: STRING_8
			salt1: STRING_8
			hash1: STRING_8
			derived_key: STRING_8
		do
			if user_key.count >= 40 then
				pwd := a_password.substring (1, a_password.count.min (127))
				salt1 := user_key.substring (33, 40)
				hash1 := calculate_hash (revision, pwd, salt1, "")
				if hash1.is_equal (user_key.substring (1, 32)) then
					derived_key := compute_encryption_key_user_rev5 (a_password)
					Result := verify_perms_rev5 (derived_key)
				end
			end
		end

	verify_owner_password_rev5 (a_password: STRING_8): BOOLEAN
			-- Verify owner password (Revision 5/6).
		local
			pwd: STRING_8
			salt1: STRING_8
			hash1: STRING_8
			derived_key: STRING_8
		do
			if owner_key.count >= 40 and then user_key.count >= 48 then
				pwd := a_password.substring (1, a_password.count.min (127))
				salt1 := owner_key.substring (33, 40)
				hash1 := calculate_hash (revision, pwd, salt1, user_key.substring (1, 48))
				if hash1.is_equal (owner_key.substring (1, 32)) then
					derived_key := compute_encryption_key_owner_rev5 (a_password)
					Result := verify_perms_rev5 (derived_key)
				end
			end
		end

	compute_encryption_key_user_rev5 (a_password: STRING_8): STRING_8
			-- Compute encryption key using user password (Revision 5/6).
		local
			pwd: STRING_8
			salt2: STRING_8
			tmp_key: STRING_8
			zero_iv: STRING_8
		do
			if user_key.count >= 48 and then not user_encryption_key.is_empty then
				pwd := a_password.substring (1, a_password.count.min (127))
				salt2 := user_key.substring (41, 48)
				tmp_key := calculate_hash (revision, pwd, salt2, "")
				create zero_iv.make_filled ('%/0/', 16)
				Result := aes_cbc_decrypt_raw (user_encryption_key, tmp_key, zero_iv)
			else
				create Result.make_empty
			end
		ensure
			result_attached: Result /= Void
		end

	compute_encryption_key_owner_rev5 (a_password: STRING_8): STRING_8
			-- Compute encryption key using owner password (Revision 5/6).
		local
			pwd: STRING_8
			salt2: STRING_8
			tmp_key: STRING_8
			zero_iv: STRING_8
		do
			if owner_key.count >= 48 and then user_key.count >= 48 and then not owner_encryption_key.is_empty then
				pwd := a_password.substring (1, a_password.count.min (127))
				salt2 := owner_key.substring (41, 48)
				tmp_key := calculate_hash (revision, pwd, salt2, user_key.substring (1, 48))
				create zero_iv.make_filled ('%/0/', 16)
				Result := aes_cbc_decrypt_raw (owner_encryption_key, tmp_key, zero_iv)
			else
				create Result.make_empty
			end
		ensure
			result_attached: Result /= Void
		end

	calculate_hash (a_revision: INTEGER; a_password, a_salt, a_udata: STRING_8): STRING_8
			-- Calculate the Revision 5/6 hash value.
		local
			sha256: SHA256
			sha384: PDF_SHA512
			sha512: PDF_SHA512
			k, k1, e: STRING_8
			count_val: INTEGER
			aes_key, aes_iv: STRING_8
			sum_e: INTEGER
			i: INTEGER
			e_last: INTEGER
			stop: BOOLEAN
		do
			create sha256.make
			sha256.update_from_string (a_password + a_salt + a_udata)
			k := sha256.digest_as_byte_string

			if a_revision >= 6 then
				from
					count_val := 0
					stop := False
				until
					stop
				loop
					count_val := count_val + 1

					-- k1 * 64
					create k1.make ((a_password.count + k.count + a_udata.count) * 64)
					from i := 1 until i > 64 loop
						k1.append (a_password)
						k1.append (k)
						k1.append (a_udata)
						i := i + 1
					end

					-- Encrypt k1 with AES-128 key=k[1..16], iv=k[17..32]
					aes_key := k.substring (1, 16)
					aes_iv := k.substring (17, 32)
					e := aes_cbc_encrypt_raw (k1, aes_key, aes_iv)

					-- Select hash function based on first 16 bytes of e
					sum_e := 0
					from i := 1 until i > 16 loop
						sum_e := sum_e + e.code (i).to_integer_32
						i := i + 1
					end

					if sum_e \\ 3 = 0 then
						sha256.reset
						sha256.update_from_string (e)
						k := sha256.digest_as_byte_string
					elseif sum_e \\ 3 = 1 then
						create sha384.make_384
						sha384.update (e)
						k := sha384.digest
					else
						create sha512.make
						sha512.update (e)
						k := sha512.digest
					end

					e_last := e.code (e.count).to_integer_32
					if count_val >= 64 and then e_last <= count_val - 32 then
						stop := True
					end
				end
			end

			Result := k.substring (1, 32)
		ensure
			result_attached: Result /= Void
			result_length: Result.count = 32
		end

	verify_perms_rev5 (a_key: STRING_8): BOOLEAN
			-- Verify the decrypted key using the /Perms string.
		local
			perms_entry: detachable PDF_OBJECT
			perms_str: STRING_8
			decrypted: STRING_8
			expected_p: STRING_8
			b8: CHARACTER_8
		do
			perms_entry := encrypt_dict.item ("Perms")
			if attached {PDF_STRING} perms_entry as p_str then
				perms_str := p_str.value
				if perms_str.count = 16 then
					decrypted := aes_ecb_decrypt_raw (perms_str, a_key)
					if decrypted.count = 16 then
						expected_p := int_to_bytes (permissions_flags)
						if encrypt_metadata then
							b8 := 'T'
						else
							b8 := 'F'
						end
						Result := decrypted.substring (1, 4).is_equal (expected_p)
							and then decrypted.substring (5, 8).is_equal ("%/0xFF/%/0xFF/%/0xFF/%/0xFF/")
							and then decrypted.item (9) = b8
							and then decrypted.substring (10, 12).is_equal ("adb")
					end
				end
			end
		end

feature {NONE} -- Raw AES Helpers

	aes_cbc_decrypt_raw (a_data, a_key, a_iv: STRING_8): STRING_8
			-- Decrypt a_data using AES CBC mode with a_key and a_iv.
		local
			l_aes: AES
			key_bytes, iv_bytes, data_bytes: ARRAY [NATURAL_8]
		do
			if a_key.count = 32 then
				create l_aes.make_with_params (create {AES_256_PARAMETERS})
			else
				create l_aes.make_with_params (create {AES_128_PARAMETERS})
			end
			key_bytes := string_to_bytes (a_key)
			iv_bytes := string_to_bytes (a_iv)
			data_bytes := string_to_bytes (a_data)

			l_aes.init_ctx_iv (key_bytes, iv_bytes)
			l_aes.cbc_decrypt_buffer (data_bytes)

			Result := bytes_to_string (data_bytes)
		ensure
			result_attached: Result /= Void
		end

	aes_cbc_encrypt_raw (a_data, a_key, a_iv: STRING_8): STRING_8
			-- Encrypt a_data using AES CBC mode with a_key and a_iv.
		local
			l_aes: AES
			key_bytes, iv_bytes, data_bytes: ARRAY [NATURAL_8]
		do
			if a_key.count = 32 then
				create l_aes.make_with_params (create {AES_256_PARAMETERS})
			else
				create l_aes.make_with_params (create {AES_128_PARAMETERS})
			end
			key_bytes := string_to_bytes (a_key)
			iv_bytes := string_to_bytes (a_iv)
			data_bytes := string_to_bytes (a_data)

			l_aes.init_ctx_iv (key_bytes, iv_bytes)
			l_aes.cbc_encrypt_buffer (data_bytes)

			Result := bytes_to_string (data_bytes)
		ensure
			result_attached: Result /= Void
		end

	aes_ecb_decrypt_raw (a_data, a_key: STRING_8): STRING_8
			-- Decrypt a_data using AES ECB mode with a_key.
		local
			l_aes: AES
			key_bytes, data_bytes: ARRAY [NATURAL_8]
		do
			if a_key.count = 32 then
				create l_aes.make_with_params (create {AES_256_PARAMETERS})
			else
				create l_aes.make_with_params (create {AES_128_PARAMETERS})
			end
			key_bytes := string_to_bytes (a_key)
			data_bytes := string_to_bytes (a_data)

			l_aes.init_ctx (key_bytes)
			l_aes.ecb_decrypt (data_bytes)

			Result := bytes_to_string (data_bytes)
		ensure
			result_attached: Result /= Void
		end

	aes_ecb_encrypt_raw (a_data, a_key: STRING_8): STRING_8
			-- Encrypt a_data using AES ECB mode with a_key.
		local
			l_aes: AES
			key_bytes, data_bytes: ARRAY [NATURAL_8]
		do
			if a_key.count = 32 then
				create l_aes.make_with_params (create {AES_256_PARAMETERS})
			else
				create l_aes.make_with_params (create {AES_128_PARAMETERS})
			end
			key_bytes := string_to_bytes (a_key)
			data_bytes := string_to_bytes (a_data)

			l_aes.init_ctx (key_bytes)
			l_aes.ecb_encrypt (data_bytes)

			Result := bytes_to_string (data_bytes)
		ensure
			result_attached: Result /= Void
		end

	string_to_bytes (a_string: STRING_8): ARRAY [NATURAL_8]
			-- Convert STRING_8 to byte array.
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
			result_attached: Result /= Void
			same_count: Result.count = a_string.count
		end

	bytes_to_string (a_bytes: ARRAY [NATURAL_8]): STRING_8
			-- Convert byte array to STRING_8.
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
			result_attached: Result /= Void
			same_count: Result.count = a_bytes.count
		end

end
