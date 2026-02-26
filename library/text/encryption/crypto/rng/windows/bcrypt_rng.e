note
    description: "[
        Cryptographically secure RNG using BCryptGenRandom (Windows CNG API).
        
        This class provides cryptographically secure random bytes suitable for:
        - Encryption key generation
        - IV/nonce generation
        - Salt generation
        
        Only available on Windows - use URANDOM_RNG on Unix systems.
        
        Note: This is BCryptGenRandom (Windows CNG), NOT bcrypt password hashing.
        
        Error codes:
        -  0: Success
        - -1: Failed to open device/provider
        - -2: Failed to read from device
        - -3: API call failed
        - -4: Unsupported platform
        - -5: Buffer too large (>4GB on Windows)
        
        Security: On any error, the output buffer is automatically zeroed
        to prevent information leakage.
        
        Thread-safe. BCryptGenRandom with BCRYPT_USE_SYSTEM_PREFERRED_RNG is thread-safe.
        
      
        Implements CSPRNG recommendation from Practical Cryptography for Developers:
        'In Windows, random numbers for cryptographic purposes can be securely
        generated using the BCryptGenRandom function from the Cryptography API:
        Next Generation (CNG)
        See: https://learn.microsoft.com/en-us/windows/win32/seccng/cng-portal
        See: https://cryptobook.nakov.com/secure-random-generators/secure-random-generators-csprng
    ]"
    revision: "$Revision$"
    EIS: "name= csprng", "src=https://cryptobook.nakov.com/secure-random-generators/secure-random-generators-csprng", "protocol=uri"
    EIS: "name= cng-portal", "src=https://learn.microsoft.com/en-us/windows/win32/seccng/cng-portal", "protocol=uri"

class
    BCRYPT_RNG

inherit
    CSPRNG
        redefine
            fill_bytes
        end

create
    make

feature -- Initialization

    make
            -- Initialize BCrypt RNG.
        do
            -- No initialization needed - uses BCRYPT_USE_SYSTEM_PREFERRED_RNG
        end

feature -- Status

    last_error_code: INTEGER
            -- Error code from last operation (0 = success).

    has_error: BOOLEAN
            -- Has the last operation failed?
        do
            Result := last_error_code < 0
        end

    error_message: STRING_8
            -- Human-readable error message for last error.
        do
            inspect last_error_code
            when Error_success then
                Result := "Success"
            when Error_open then
                Result := "Failed to open provider"
            when Error_read then
                Result := "Failed to read random data"
            when Error_api then
                Result := "BCryptGenRandom API call failed"
            when Error_unsupported then
                Result := "Platform not supported (not Windows)"
            when Error_too_big then
                Result := "Buffer too large (>4GB)"
            else
                Result := "Unknown error: " + last_error_code.out
            end
        end



feature -- Core primitive

    next_u32: NATURAL_32
            -- Next cryptographically secure 32-bit random number.
        local
            l_buffer: MANAGED_POINTER
        do
            create l_buffer.make (Bytes_per_u32)
            last_error_code := c_fill_bytes_bcrypt (l_buffer.item, Bytes_per_u32)

            if last_error_code = Error_success then
                Result := l_buffer.read_natural_32 (0)
            end
        end

feature -- Bulk generation

    fill_bytes (a_buffer: SPECIAL [NATURAL_8])
            -- Fill `a_buffer` with cryptographically secure random bytes.
        local
            l_ptr: MANAGED_POINTER
            i: INTEGER
        do
            if a_buffer.count > 0 then
                create l_ptr.make (a_buffer.count)
                last_error_code := c_fill_bytes_bcrypt (l_ptr.item, a_buffer.count)

                if last_error_code = Error_success then
                    from i := 0 until i >= a_buffer.count loop
                        a_buffer [i] := l_ptr.read_natural_8 (i)
                        i := i + 1
                    end
                end
            end
        end

    fill_secure_bytes (a_buffer: SPECIAL [NATURAL_8])
            -- Fill `a_buffer` with cryptographically secure random bytes.
        require
            buffer_exists: a_buffer /= Void
        do
            fill_bytes (a_buffer)
        end

feature -- Information

    entropy_source: STRING_8
            -- Human-readable description of entropy source.
        do
            Result := "Windows CNG BCryptGenRandom (BCRYPT_USE_SYSTEM_PREFERRED_RNG)"
        end

feature {NONE} -- Constants

    Bytes_per_u32: INTEGER = 4
            -- Size of NATURAL_32 in bytes.

    Error_success: INTEGER = 0
            -- Operation successful.

    Error_open: INTEGER = -1
            -- Failed to open device/provider.

    Error_read: INTEGER = -2
            -- Failed to read from device.

    Error_api: INTEGER = -3
            -- API call failed.

    Error_unsupported: INTEGER = -4
            -- Platform not supported.

    Error_too_big: INTEGER = -5
            -- Buffer too large.

feature {NONE} -- External C

    c_fill_bytes_bcrypt (ptr: POINTER; size: INTEGER): INTEGER
            -- Fill buffer with random bytes using BCryptGenRandom.
            -- Returns 0 on success, negative on error.
            -- Buffer is zeroed on any error for security.
        external
            "C inline use %"csprng_impl.h%""
        alias
            "[
                return csprng_fill_bytes_win32(
                    (unsigned char *)$ptr,
                    (size_t)$size
                );
            ]"
        end

note
	copyright: "Copyright (c) 1984-2026, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"
end
