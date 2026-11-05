note
	description: "SSL context,  loads up the algorithms that OpenSSL will be using and also loads the errors Strings."
	legal: "See notice at end of class"
	status: "See notice at end of class"
	date: "$Date$"
	revision: "$Revision$"

class
	SSL_SHARED

feature {NONE} -- Initialization

	initialize_ssl
			-- Initialize the SSL Library.
			-- with libcrypto.
			--| OPENSSL_init_ssl is thread safe, and cheap once the library is initialized,
			--| so there is no need for any Eiffel side once or exclusive access.
		note
			EIS: "name=Library Initialization", "src=https://wiki.openssl.org/index.php/Library_Initialization", "protocol=uri"
		do
			c_openssl_init_ssl
		end

feature {NONE} -- External

	c_ssl_load_error_strings
			-- External call to SSL_load_error_strings.
		external
			"C use %"eif_openssl.h%""
		alias
			"SSL_load_error_strings"
		end

	c_openssl_init_ssl
			-- External call to OPENSSL_init_ssl.
		external
			"C inline use %"eif_openssl.h%""
		alias
			"OPENSSL_init_ssl(OPENSSL_INIT_LOAD_SSL_STRINGS | OPENSSL_INIT_LOAD_CRYPTO_STRINGS, NULL)"
		end

	c_openssl_add_ssl_algorithms
			-- External call to OpenSSL_add_ssl_algorithms();.
		external
			"C use %"eif_openssl.h%""
		alias
			"OpenSSL_add_ssl_algorithms"
		end


	c_openssl_add_all_algorithms
			-- External call to OPENSSL_add_all_algorithm.
		external "C use %"eif_openssl.h%""
		alias
			"OpenSSL_add_all_algorithms"
		end

	c_err_load_crypto_strings
			-- External call to ERR_load_crypto_strings
		external
			"C use %"eif_openssl.h%""
		alias
			"ERR_load_crypto_strings"
		end

	c_ssl_get_ctx (a_ssl: POINTER): POINTER
			-- External call to SSL_get_SSL_CTX.
		external
			"C use %"eif_openssl.h%""
		alias
			"SSL_get_SSL_CTX"
		end


	c_version_number: INTEGER
		external
			"C inline use %"eif_openssl.h%""
		alias
			"OpenSSL_version_num()"
		end


	ssl_api_version: INTEGER = 269484032
			-- Defined as  0x10100000L

note
	copyright: "Copyright (c) 1984-2019, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"

end
