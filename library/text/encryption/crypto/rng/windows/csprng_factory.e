note
	description: "[
		Factory for creating CSPRNG instances on Windows.
		
		This Windows-specific implementation uses BCryptGenRandom (CNG API)
		for cryptographically secure random number generation.
		
		Usage:
			factory: CSPRNG_FACTORY
			rng: CSPRNG
			
			create factory
			if factory.is_csprng_available then
				rng := factory.new_csprng
				-- Use rng for cryptographic operations
			end
	
		See: https://cryptobook.nakov.com/secure-random-generators/secure-random-generators-csprng
	]"
	revision: "$Revision$"

class
	CSPRNG_FACTORY

feature -- Factory

	new_csprng: CSPRNG
			-- Create a new CSPRNG using Windows BCryptGenRandom.
		do
			create {BCRYPT_RNG} Result.make
		ensure
			result_attached: Result /= Void
		end

feature -- Status

	is_csprng_available: BOOLEAN
			-- Is a CSPRNG available and working on this platform?
		local
			l_rng: BCRYPT_RNG
		do
			create l_rng.make
			l_rng.next_u32.do_nothing
			Result := not l_rng.has_error
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
