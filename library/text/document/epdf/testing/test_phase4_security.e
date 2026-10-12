note
    description: "Tests for Phase 4: Security (Encryption and Permissions)."

class
    TEST_PHASE4_SECURITY

inherit
    EQA_TEST_SET

feature -- Test MD5

    test_md5_rfc_vectors
            -- Verify MD5 implementation against RFC 1321 test vectors.
        local
            md5: PDF_MD5
            d: STRING
        do
            create md5.make
            
            -- Test ""
            d := md5.digest_string ("")
            assert ("MD5 empty string", bytes_to_hex(d).is_case_insensitive_equal ("d41d8cd98f00b204e9800998ecf8427e"))
            
            -- Test "a"
            d := md5.digest_string ("a")
            assert ("MD5 'a'", bytes_to_hex(d).is_case_insensitive_equal ("0cc175b9c0f1b6a831c399e269772661"))
            
            -- Test "abc"
            d := md5.digest_string ("abc")
            assert ("MD5 'abc'", bytes_to_hex(d).is_case_insensitive_equal ("900150983cd24fb0d6963f7d28e17f72"))
        end

feature -- Test RC4

    test_rc4
            -- Verify RC4 implementation.
        local
            rc4: PDF_RC4
            key, plain, cipher, decrypted: STRING
        do
            key := "Key"
            plain := "Plaintext"
            
            create rc4.make (key)
            cipher := rc4.process_string (plain)
            
            -- Verify against known RC4 vector output for "Key", "Plaintext"
            -- Key: 4B 65 79
            -- Plain: 50 6C 61 69 6E 74 65 78 74
            -- Cipher: BB F3 16 E8 D9 40 AF 0A D3
            assert ("RC4 encryption", bytes_to_hex(cipher).is_case_insensitive_equal ("BBF316E8D940AF0AD3"))
            
            -- Decrypt
            create rc4.make (key)
            decrypted := rc4.process_string (cipher)
            assert ("RC4 decryption", decrypted.is_equal (plain))
        end

feature -- Test Permissions

    test_permissions
            -- Test PDF_PERMISSIONS class.
        local
            perms: PDF_PERMISSIONS
        do
            create perms.make_all_restricted
            assert ("Modify restricted", not perms.is_modify_allowed)
            assert ("Print restricted", not perms.is_print_allowed)
            
            perms.enable_print
            assert ("Print allowed", perms.is_print_allowed)
            assert ("Bit set", perms.flags.bit_and ((1).bit_shift_left (2)) /= 0) -- Bit 3 is mask 4
        end

feature -- Test Security Handler

    test_security_handler
            -- Test standard security handler key derivation.
        local
            handler: PDF_STANDARD_SECURITY_HANDLER
            encrypt_dict: PDF_DICTIONARY
            file_id: PDF_ARRAY
            oid: PDF_STRING
            uid: PDF_STRING
            p: PDF_NUMBER
            len: PDF_NUMBER
            v: PDF_NUMBER
            r: PDF_NUMBER
            l_str, l_enc: STRING
        do
            -- Setup Mock Dictionary
            create encrypt_dict.make (6)
            create oid.make_literal ("O value") -- Placeholder
            create uid.make_literal ("U value") -- Placeholder
            create p.make (-64) -- Sample permission
            create len.make (40)
            create v.make (1)
            create r.make (2)
            
            encrypt_dict.put (oid, "O")
            encrypt_dict.put (uid, "U")
            encrypt_dict.put (p, "P")
            encrypt_dict.put (len, "Length")
            encrypt_dict.put (v, "V")
            encrypt_dict.put (r, "R")
            
            create file_id.make (2)
            file_id.add (create {PDF_STRING}.make_literal ("FileIDPart1"))
            
            create handler.make (encrypt_dict, file_id, "user_password")
            
            -- Check consistency (encrypt/decrypt round trip)
            l_str := "Hello World"
            l_enc := handler.encrypt_string (l_str, 1, 0)
            assert ("Encrypted string differs", not l_enc.is_equal (l_str))
            
            l_str := handler.decrypt_string (l_enc, 1, 0)
            assert ("Decrypted string matches original", l_str.is_equal ("Hello World"))
        end

feature {NONE} -- Helpers

    bytes_to_hex (s: STRING): STRING
        local
            i: INTEGER
            code: INTEGER
        do
            create Result.make (s.count * 2)
            from i := 1 until i > s.count loop
                code := s.code (i).to_integer_32
                Result.append (to_hex (code))
                i := i + 1
            end
        end

    to_hex (val: INTEGER): STRING
        local
            hex: STRING
        do
            hex := "0123456789ABCDEF"
            create Result.make (2)
            Result.append_character (hex.item ((val.bit_shift_right (4) \\ 16) + 1))
            Result.append_character (hex.item ((val \\ 16) + 1))
        end

end
