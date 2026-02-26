note
    description: "[
        Default RNG implementation that auto-seeds from system time.
        
        SECURITY WARNING: NOT CRYPTOGRAPHICALLY SECURE!
        This class uses time-based seeding which is predictable. Per Practical
        Cryptography for Developers: 'when the initial random seed is initialized
        with a predictable number like the current time, crackers can try all
        possibilities within the range of +/- 5 seconds and find the exact initial
        seed and then compromise the security.'
        
        For cryptographic purposes, use URANDOM_RNG (Unix) or BCRYPT_RNG (Windows).
        See: https://cryptobook.nakov.com/secure-random-generators#insecure-randomness
    ]"
    revision: "$Revision$"
    EIS: "name:insecure-randomness", "src=https://cryptobook.nakov.com/secure-random-generators#insecure-randomness", "protocol=uri"

class
    DEFAULT_RNG

inherit
    RNG

create
    make

feature {NONE} -- Implementation

    pcg: PCG32_RNG
            -- Underlying engine.

feature -- Initialization

    make
            -- Initialize and seed from current time.
        local
            l_time: TIME
            l_seed: NATURAL_64
        do
            create l_time.make_now
            l_seed := l_time.hour.to_natural_64 * Milliseconds_per_hour
                    + l_time.minute.to_natural_64 * Milliseconds_per_minute
                    + l_time.second.to_natural_64 * Milliseconds_per_second
                    + l_time.milli_second.to_natural_64

            create pcg.make (l_seed, Default_stream)
        end

feature -- Core primitive

    next_u32: NATURAL_32
            -- Next 32-bit random number.
        do
            Result := pcg.next_u32
        end

feature {NONE} -- Constants

    Milliseconds_per_hour: NATURAL_64 = 3600000
            -- Milliseconds in one hour.

    Milliseconds_per_minute: NATURAL_64 = 60000
            -- Milliseconds in one minute.

    Milliseconds_per_second: NATURAL_64 = 1000
            -- Milliseconds in one second.

    Default_stream: NATURAL_64 = 1
            -- Default PCG stream selector.

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
