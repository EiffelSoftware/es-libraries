note
    description: "[
    	Abstract interface for Cryptographically Secure Random Number Generators.
    
    	thread_safety: Thread-safe on all supported platforms:
        	- Windows: BCryptGenRandom is thread-safe
       		- Unix/Linux: /dev/urandom and getrandom() are thread-safe
        	- OpenBSD: arc4random_buf is thread-safe
        	
	
		CSPRNG Design Principles (per Practical Cryptography for Developers):
        	- Uses OS-provided entropy sources for unpredictable randomness
        	- Satisfies next-bit test: cannot predict bit k+1 from first k bits
        	- Withstands state compromise extensions
  	    
  	    See: https://cryptobook.nakov.com/secure-random-generators/secure-random-generators-csprng
   	]"
    revision: "$Revision$"
	EIS: "name= csprng", "src=https://cryptobook.nakov.com/secure-random-generators/secure-random-generators-csprng", "protocol=uri"
	
deferred class
    CSPRNG

inherit
    RNG

feature -- Status

    is_cryptographically_secure: BOOLEAN
            -- Is this RNG suitable for cryptographic key generation?
        do
            Result := True
        end

    has_error: BOOLEAN
            -- Has the last operation failed?
        deferred
        end

feature -- Information

    entropy_source: STRING_8
            -- Human-readable description of the entropy source.
        deferred
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
