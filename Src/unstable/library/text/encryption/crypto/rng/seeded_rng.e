note
    description: "[
        Abstract interface for Deterministic (Seeded) Random Number Generators.
        
        SECURITY WARNING: NOT CRYPTOGRAPHICALLY SECURE!
        Seeded RNGs are deterministic: same seed produces the same sequence.
        This is useful for testing and reproducibility but DANGEROUS for
        cryptographic applications.
        
        Per Practical Cryptography for Developers: 'It is obvious that the same
        time in the initial seed causes the same (predictable) pseudo-random
        numbers to be generated in the output.'
        
        For cryptographic purposes, use BCRYPT_RNG (Windows) or URANDOM_RNG (Unix).
        See: https://cryptobook.nakov.com/secure-random-generators#insecure-randomness
    ]"
    revision: "$Revision$"
    EIS: "name:insecure-randomness", "src=https://cryptobook.nakov.com/secure-random-generators#insecure-randomness", "protocol=uri"

deferred class
    SEEDED_RNG

inherit
    RNG

feature -- Initialization

    set_seed (a_seed: NATURAL_64)
            -- Reset generator to a known state derived from `a_seed`.
            -- Semantics: Resets generator state using `a_seed` with a default
            -- stream selector of 1. Same seed will always produce same sequence.
        deferred
        ensure
            reproducible: True -- Same seed MUST result in same sequence (verified by tests)
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
