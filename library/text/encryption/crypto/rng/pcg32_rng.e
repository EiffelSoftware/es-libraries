note
    description: "[
        PCG-XSH-RR implementation (32-bit output, 64-bit state).
        
        SECURITY WARNING: NOT CRYPTOGRAPHICALLY SECURE!
        This is a high-quality PRNG for simulations, games, and testing,
        but the internal state can be recovered from observed outputs.
        
        Per Practical Cryptography for Developers, a CSPRNG must:
        - Satisfy the next-bit test (this PRNG does NOT)
        - Withstand state compromise extensions (this PRNG does NOT)
        
        For cryptographic key generation, IV generation, or any security-sensitive
        application, use BCRYPT_RNG (Windows) or URANDOM_RNG (Unix).
        See: https://cryptobook.nakov.com/secure-random-generators#csprng-cryptography-secure-random-number-generators
    ]"
    revision: "$Revision$"
    EIS: "name=pcg-rangom.org", "src=https://www.pcg-random.org/", "protocol=uri"

class
    PCG32_RNG

inherit
    SEEDED_RNG

create
    make,
    make_with_seed

feature {NONE} -- State

    state: NATURAL_64
            -- RNG internal state.

    inc: NATURAL_64
            -- Stream selector (must be odd).

feature {NONE} -- Constants

    Multiplier: NATURAL_64 = 0x5851F42D4C957F2D
            -- PCG default multiplier (6364136223846793005).

    Default_stream: NATURAL_64 = 1
            -- Default stream selector.

feature -- Initialization

    make (a_seed, a_stream: NATURAL_64)
            -- Initialize with `a_seed` and stream selector `a_stream`.
        do
            inc := (a_stream.bit_shift_left (1)).bit_or ({NATURAL_64} 1)  -- Ensure odd
            state := 0
            state := state * Multiplier + inc
            state := state + a_seed
            state := state * Multiplier + inc
        ensure
            inc_is_odd: inc.bit_and ({NATURAL_64} 1) = {NATURAL_64} 1
        end

    make_with_seed (a_seed: NATURAL_64)
            -- Initialize with `a_seed` and default stream.
        do
            make (a_seed, Default_stream)
        end

    set_seed (a_seed: NATURAL_64)
            -- Reset with new seed and default stream.
        do
            state := 0
            inc := ({NATURAL_64} 1).bit_shift_left (1).bit_or ({NATURAL_64} 1) -- Reset inc to default sequence 1
            state := state * Multiplier + inc
            state := state + a_seed
            state := state * Multiplier + inc
        end

feature -- Core primitive

    next_u32: NATURAL_32
            -- Next 32-bit random number.
        local
            oldstate: NATURAL_64
            xorshifted: NATURAL_32
            rot: INTEGER
        do
            oldstate := state
            state := oldstate * Multiplier + inc
            xorshifted := (((oldstate.bit_shift_right (18)).bit_xor (oldstate)).bit_shift_right (27)).as_natural_32
            rot := (oldstate.bit_shift_right (59)).as_integer_32
            Result := (xorshifted.bit_shift_right (rot)).bit_or (xorshifted.bit_shift_left ((-rot).bit_and (31)))
        end



invariant
    inc_is_odd: inc.bit_and ({NATURAL_64} 1) = {NATURAL_64} 1

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

