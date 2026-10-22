note
	description: "SSL context"
	legal: "See notice at end of class"
	status: "See notice at end of class"
	date: "$Date$"
	revision: "$Revision$"

class
	SSL_CONTEXT

inherit

	SSL_SHARED

create
	make_as_sslv23_client,
	make_as_sslv23_server,
	make_as_tlsv10_client,
	make_as_tlsv10_server,
	make_as_tlsv11_client,
	make_as_tlsv11_server,
	make_as_tlsv12_client,
	make_as_tlsv12_server,
	make_as_dtlsv1_client,
	make_as_dtlsv1_server,
	make_from_context_pointer,
	make_from_retained_context_pointer,
	make_as_tls_server,
	make_as_tls_client


feature {NONE} -- Initialization

	make_as_sslv23_client
			-- Make an SSLv2 and SSLv3 capable client context.	
		local
			err: DEVELOPER_EXCEPTION
		do
			create err
			err.set_description ("Obsolete protocol, use Tlsv1_2")
			err.raise
		end

	make_as_tlsv10_client
			-- Make an TLSv1 capable client context.
		local
			method_pointer: POINTER
		do
				--| Initialize SSL, as this may be one of the entry points into SSL where it is
				--| useful to initialize the SSL Library
			initialize_ssl
			method_pointer := c_tlsv10_client_method
			ctx := c_ssl_ctx_new (method_pointer)
		end

	make_as_tlsv11_client
			-- Make an TLSv1_1 capable client context.
		local
			method_pointer: POINTER
		do
				--| Initialize SSL, as this may be one of the entry points into SSL where it is
				--| useful to initialize the SSL Library
			initialize_ssl
			method_pointer := c_tlsv11_client_method
			ctx := c_ssl_ctx_new (method_pointer)
		end

	make_as_dtlsv1_client
			-- Make an DTLSv1 capable client context.
		local
			method_pointer: POINTER
		do
				--| Initialize SSL, as this may be one of the entry points into SSL where it is
				--| useful to initialize the SSL Library
			initialize_ssl
			method_pointer := c_dtlsv1_client_method
			ctx := c_ssl_ctx_new (method_pointer)
		end

	make_as_tlsv12_client
			-- Make an TLSv1 capable client context.
		local
			method_pointer: POINTER
		do
				--| Initialize SSL, as this may be one of the entry points into SSL where it is
				--| useful to initialize the SSL Library
			initialize_ssl
			method_pointer := c_tlsv12_client_method
			ctx := c_ssl_ctx_new (method_pointer)
		end

	make_as_tls_client
			-- Make a flexible capable client context.
			--| The actual protocol version used will be negotiated to the highest version mutually supported by the client and the server.
			--| The supported protocols are SSLv3, TLSv1, TLSv1.1, TLSv1.2 and TLSv1.3.
			--| Applications should use these methods, and avoid the version-specific methods described below.
		local
			method_pointer: POINTER
		do
				--| Initialize SSL, as this may be one of the entry points into SSL where it is
				--| useful to initialize the SSL Library
			initialize_ssl
			method_pointer := c_tls_client_method
			ctx := c_ssl_ctx_new (method_pointer)
		end


	make_as_sslv23_server
			-- Make an SSLv2 and SSLv3 capable server context.	
		local
			err: DEVELOPER_EXCEPTION
		do
			create err
			err.set_description ("Obsolete protocol, use Tlsv1_2")
			err.raise
		end

	make_as_tlsv10_server
			-- Make an TLSv1 capable server context.
		local
			method_pointer: POINTER
		do
				--| Initialize SSL, as this may be one of the entry points into SSL where it is
				--| useful to initialize the SSL Library
			initialize_ssl
			method_pointer := c_tlsv10_server_method
			ctx := c_ssl_ctx_new (method_pointer)
		end

	make_as_tlsv11_server
			-- Make an TLSv11 capable server context.
		local
			method_pointer: POINTER
		do
				--| Initialize SSL, as this may be one of the entry points into SSL where it is
				--| useful to initialize the SSL Library
			initialize_ssl
			method_pointer := c_tlsv11_server_method
			ctx := c_ssl_ctx_new (method_pointer)
		end

	make_as_tlsv12_server
			-- Make an TLSv12 capable server context.
		local
			method_pointer: POINTER
		do
				--| Initialize SSL, as this may be one of the entry points into SSL where it is
				--| useful to initialize the SSL Library
			initialize_ssl
			method_pointer := c_tlsv12_server_method
			ctx := c_ssl_ctx_new (method_pointer)
		end

	make_as_tls_server
		-- Make a flexible TLS capable server context.
		--| The actual protocol version used will be negotiated to the highest version mutually supported by the client and the server.
		--| The supported protocols are SSLv3, TLSv1, TLSv1.1, TLSv1.2 and TLSv1.3.
		--| Applications should use these methods, and avoid the version-specific methods described below.

		local
			method_pointer: POINTER
		do
				--| Initialize SSL, as this may be one of the entry points into SSL where it is
				--| useful to initialize the SSL Library
			initialize_ssl
			method_pointer := c_tls_server_method
			ctx := c_ssl_ctx_new (method_pointer)
		end

	make_as_dtlsv1_server
			-- Make an DTLSv1 capable server context.
		local
			method_pointer: POINTER
		do
				--| Initialize SSL, as this may be one of the entry points into SSL where it is
				--| useful to initialize the SSL Library
			initialize_ssl
			method_pointer := c_dtlsv1_server_method
			ctx := c_ssl_ctx_new (method_pointer)
		end

	make_from_context_pointer (a_context_pointer: POINTER; a_ssl_pointer: POINTER)
			-- Make a SSL context from a pointer `a_context_pointer' and set the
			-- SSL structed represented by the pointer `a_ssl_pointer'.
		do
			ctx := a_context_pointer
			create last_ssl.make_from_pointer (a_ssl_pointer)
		end

	make_from_retained_context_pointer (a_context_pointer: POINTER)
			-- Make a SSL context sharing the SSL_CTX structure `a_context_pointer',
			-- taking ownership of one reference previously obtained with `retained_context_pointer'.
			--| The SSL_CTX is reference counted, and `free' releases the reference owned by Current.
			--| SSL_CTX is thread safe for `create_ssl', so it can be shared between threads and SCOOP processors.
		require
			a_context_pointer_set: a_context_pointer /= default_pointer
		do
			ctx := a_context_pointer
		end

feature -- Access

	retained_context_pointer: POINTER
			-- Pointer to the SSL_CTX structure, with its reference count incremented.
			-- The caller owns the new reference, and is responsible to release it,
			-- for instance via `make_from_retained_context_pointer' and then `free'.
			--| Being a POINTER, it can be passed to another SCOOP processor without lock passing.
			-- Return `default_pointer' if there is no SSL_CTX.
		do
			if ctx /= default_pointer and then c_ssl_ctx_up_ref (ctx) = 1 then
				Result := ctx
			end
		end

	options: INTEGER_64
			-- Current options set for ctx as a bitmask.
		do
			Result := c_ssl_ctx_get_options (ctx);
		end

	create_ssl
			-- Create an SSL object from the current context.
		do
			create last_ssl.make_from_context (ctx)
		end

	free
			-- Free the underlying SSL Context Structure.
			--| Note: the SSL_CTX is reference counted, so this only releases the reference owned by Current.
		do
			c_ssl_ctx_free (ctx)
		end

	use_certificate (a_certificate: STRING)
			-- Import the PEM certificate in `a_certificate' into this context.
		local
			c_string: C_STRING
			err: INTEGER
			l_exception: DEVELOPER_EXCEPTION
		do
			create c_string.make (a_certificate)
			err := c_ssl_ctx_use_certificate (ctx, c_string.item)
			if err <= 0 then
				create l_exception
				l_exception.set_description ("Cannot load certificate from memory " + a_certificate)
				l_exception.raise
			end
		end

	use_private_key (a_private_key: STRING)
			-- Import the PEM private key in `a_private_key' into this context.
		local
			c_string: C_STRING
			err: INTEGER
			l_exception: DEVELOPER_EXCEPTION
		do
			create c_string.make (a_private_key)
			err := c_ssl_ctx_use_rsaprivatekey (ctx, c_string.item)
			if err <= 0 then
				create l_exception
				l_exception.set_description ("Cannot load private key from memory " + a_private_key)
				l_exception.raise
			end
			err := c_ssl_ctx_check_private_key (ctx)
			if err = 0 then
				create l_exception
				l_exception.set_description ("Private key does not match public key in certificate!")
				l_exception.raise
			end
		end

	use_certificate_file (a_file_name: PATH)
			-- Import the PEM certificate in `a_file_name' into this context.
		local
			c_string: C_STRING
			err: INTEGER
			l_exception: DEVELOPER_EXCEPTION
		do
			create c_string.make (a_file_name.utf_8_name)
			err := c_ssl_ctx_use_certificate_file (ctx, c_string.item, 1)
			if err <= 0 then
				create l_exception
				l_exception.set_description ("Cannot load certificate file " + a_file_name.out)
				l_exception.raise
			end
		end

	use_private_key_file (a_file_name: PATH)
			-- Import the PEM private key in `a_file_name' into this context.
		local
			c_string: C_STRING
			err: INTEGER
			l_exception: DEVELOPER_EXCEPTION
		do
			create c_string.make (a_file_name.utf_8_name)
			err := c_ssl_ctx_use_privatekey_file (ctx, c_string.item, 1)
			if err <= 0 then
				create l_exception
				l_exception.set_description ("Cannot load private key file " + a_file_name.out)
				l_exception.raise
			end
			err := c_ssl_ctx_check_private_key (ctx)
			if err = 0 then
				create l_exception
				l_exception.set_description ("Private key does not match public key in certificate!")
				l_exception.raise
			end
		end

	ssl_set_tlsext_host_name (a_server_name: READABLE_STRING_GENERAL)
			-- Set the value of the servername extension `a_server_name' to send in the client hello.
		local
			c_string: C_STRING
		do
			create c_string.make (a_server_name)
			if attached last_ssl as l_ssl then
				c_ssl_set_tlsext_host_name (l_ssl.ptr, c_string.item)
			end
		end

	set_options (a_options: INTEGER_64)
			-- adds the options `a_options' set via bitmask in options to ctx.
			-- Options already set before are not cleared!
		note
			EIS: "name=CTX_set_options", "src=https://www.openssl.org/docs/man1.1.0/ssl/SSL_CTX_set_options.html", "protocol=uri"
		local
			l_options: INTEGER_64
		do
			l_options := c_ssl_ctx_set_options (ctx, a_options);
		end

	clear_options (a_options: INTEGER_64)
			-- clears the options `a_options' set via bitmask in options to ctx.
		local
			l_options: INTEGER_64
		do
			l_options := c_ssl_ctx_clear_options (ctx, a_options);
		end

	set_min_proto_version (a_version: NATURAL)
			-- Set the minimum version to `a_version'.
			-- If the version is 0, will enable protocol versions down to the lowest version supported by the library.
			--| Currently supported versions are SSL3_VERSION, TLS1_VERSION, TLS1_1_VERSION, TLS1_2_VERSION, TLS1_3_VERSION for TLS and DTLS1_VERSION, DTLS1_2_VERSION for DTLS.
		require
			is_valid_version: {SSL_PROTOCOL}.is_valid_protocol (a_version)
		local
			l_res: INTEGER_64
		do
			l_res := c_ssl_ctx_set_min_proto_version (ctx, a_version)
		ensure
			min_proto_version_setted: a_version = min_proto_version
		end


	min_proto_version: NATURAL
			-- Configured version or 0 for auto-configuration of lowest protocol.
		do
			Result := c_ssl_ctx_get_min_proto_version (ctx)
		end


	set_max_proto_version (a_version: NATURAL)
			-- Set the maximun version to `a_version'.
			-- If the version is 0, will enable protocol versions up to the highest version supported by the library.
			--| Currently supported versions are SSL3_VERSION, TLS1_VERSION, TLS1_1_VERSION, TLS1_2_VERSION, TLS1_3_VERSION for TLS and DTLS1_VERSION, DTLS1_2_VERSION for DTLS.
		require
			is_valid_version: {SSL_PROTOCOL}.is_valid_protocol (a_version)
		local
			l_res: INTEGER_64
		do
			l_res := ssl_ctx_set_max_proto_version (ctx, a_version)
		ensure
			max_proto_version_setted: a_version = max_proto_version
		end

	max_proto_version: NATURAL
			-- Configured version or 0 for auto-configuration of highest protocol.
		do
			Result := c_ssl_ctx_get_max_proto_version (ctx)
		end

feature -- Status Report

	version: INTEGER
			-- returns the numeric protocol version used for the connection.
		do
			if attached last_ssl as l_ssl then
				Result := c_ssl_version (l_ssl.ptr)
			end
		end

	last_ssl: detachable SSL
			-- The SSL Structure created by `create_ssl'.

feature {NONE} -- Attributes

	ctx: POINTER
			-- External SSL_CTX structure.

feature {NONE} -- Externals

	c_ssl_ctx_check_private_key (a_ctx_ptr: POINTER): INTEGER
			-- Call external SSL_CTX_check_private_key.
		external
			"C use %"eif_openssl.h%""
		alias
			"SSL_CTX_check_private_key"
		end

	c_ssl_ctx_free (a_ctx_ptr: POINTER)
			-- External call to SSL_CTX_free.
		external
			"C use %"eif_openssl.h%""
		alias
			"SSL_CTX_free"
		end

	c_ssl_ctx_up_ref (a_ctx_ptr: POINTER): INTEGER
			-- External call to SSL_CTX_up_ref.
		external
			"C use %"eif_openssl.h%""
		alias
			"SSL_CTX_up_ref"
		end

	c_ssl_ctx_new (method_ptr: POINTER): POINTER
			-- External call to SSL_CTX_new.
		external
			"C use %"eif_openssl.h%""
		alias
			"SSL_CTX_new"
		end

	c_ssl_ctx_use_certificate(a_ctx_ptr, a_cert_buffer: POINTER ): INTEGER
			-- Call external c_ssl_ctx_use_certificate.
			--| SSL_CTX_use_certificate takes its own reference on the certificate,
			--| so the BIO and the X509 are released here.
		external
			"C inline use %"eif_openssl.h%""
		alias
			"{
				X509 *cert = NULL;
				BIO *cbio;
				int res = 0;
			
				cbio = BIO_new_mem_buf((void*)(const char *)$a_cert_buffer, -1);
				if (cbio != NULL) {
					cert = PEM_read_bio_X509(cbio, NULL, 0, NULL);
					if (cert != NULL) {
						res = SSL_CTX_use_certificate((SSL_CTX *)$a_ctx_ptr, cert);
						X509_free(cert);
					}
					BIO_free(cbio);
				}
				return (EIF_INTEGER_32) res;
			}"
		end


	c_ssl_ctx_use_rsaprivatekey	(a_ctx_ptr, a_key_buffer: POINTER): INTEGER
			-- Call external c_ssl_ctx_use_rsaprivatekey
			--| SSL_CTX_use_RSAPrivateKey takes its own reference on the key,
			--| so the BIO and the RSA are released here.
		external
			"C inline use %"eif_openssl.h%""
		alias
		 "{
			BIO *kbio;
			RSA *rsa = NULL;
			int res = 0;
	
			kbio = BIO_new_mem_buf((void*)(const char *)$a_key_buffer, -1);
			if (kbio != NULL) {
				rsa = PEM_read_bio_RSAPrivateKey(kbio, NULL, 0, NULL);
				if (rsa != NULL) {
					res = SSL_CTX_use_RSAPrivateKey((SSL_CTX *)$a_ctx_ptr, rsa);
					RSA_free(rsa);
				}
				BIO_free(kbio);
			}
			return (EIF_INTEGER_32) res;
		  }"
		end

	c_ssl_ctx_use_certificate_file (a_ctx_ptr, file: POINTER; type: INTEGER): INTEGER
			-- Call external SSL_CTX_use_certificate_file.
		external
			"C use %"eif_openssl.h%""
		alias
			"SSL_CTX_use_certificate_file"
		end

	c_ssl_ctx_use_privatekey_file (a_ctx_ptr, file: POINTER; type: INTEGER): INTEGER
			-- Call external SSL_CTX_use_PrivateKey_file.
		external
			"C use %"eif_openssl.h%""
		alias
			"SSL_CTX_use_PrivateKey_file"
		end

	c_tlsv10_client_method: POINTER
			-- External call to TLSv1_client_method.
		external
			"C use %"eif_openssl.h%""
		alias
			"TLSv1_client_method"
		end

	c_tlsv10_server_method: POINTER
			-- External call to TLSv1_server_method.
		external
			"C use %"eif_openssl.h%""
		alias
			"TLSv1_server_method"
		end

	c_tlsv11_client_method: POINTER
			-- External call to TLSv1_1_client_method.
		external
			"C use %"eif_openssl.h%""
		alias
			"TLSv1_1_client_method"
		end

	c_tlsv11_server_method: POINTER
			-- External call to TLSv1_1_server_method.
		external
			"C use %"eif_openssl.h%""
		alias
			"TLSv1_1_server_method"
		end

	c_tlsv12_client_method: POINTER
			-- External call to TLSv1_2_client_method.
		external
			"C use %"eif_openssl.h%""
		alias
			"TLSv1_2_client_method"
		end


	c_tlsv12_server_method: POINTER
			-- External call to TLSv1_2_server_method.
		external
			"C use %"eif_openssl.h%""
		alias
			"TLSv1_2_server_method"
		end

	c_tls_client_method: POINTER
			-- External call to TLS_client_method.
		external
			"C use %"eif_openssl.h%""
		alias
			"TLS_client_method"
		end

	c_tls_server_method: POINTER
			-- External call to TLS_server_method.
		external
			"C use %"eif_openssl.h%""
		alias
			"TLS_server_method"
		end

	c_dtlsv1_client_method: POINTER
			-- External call to DTLSv1_client_method.
		external
			"C use %"eif_openssl.h%""
		alias
			"DTLSv1_client_method"
		end

	c_dtlsv1_server_method: POINTER
			-- External call to DTLSv1_server_method.
		external
			"C use %"eif_openssl.h%""
		alias
			"DTLSv1_server_method"
		end

	c_ssl_set_tlsext_host_name (a_ssl: POINTER; a_name: POINTER)
			-- External call to SSL_set_tlsext_host_name.
		external
			"C inline use %"eif_openssl.h%""
		alias
			"SSL_set_tlsext_host_name((SSL *)$a_ssl,(char *)$a_name)"
		end

	c_ssl_ctx_set_options (a_ctx: POINTER; a_options: INTEGER_64): INTEGER_64
			-- External call to SSL_CTX_set_options(SSL_CTX *ctx, long options).
		external
			"C inline use %"eif_openssl.h%""
		alias
			"return SSL_CTX_set_options((SSL_CTX *)$a_ctx, (long)$a_options);"
		end

	c_ssl_ctx_clear_options (a_ctx: POINTER; a_options: INTEGER_64): INTEGER_64
			-- External call to SSL_CTX_clear_options(SSL_CTX *ctx, long options).
		external
			"C inline use %"eif_openssl.h%""
		alias
			"return SSL_CTX_clear_options((SSL_CTX *)$a_ctx, (long)$a_options);"
		end

	c_ssl_ctx_get_options (a_ctx: POINTER): INTEGER_64
			-- External call to SSL_CTX_get_options(SSL_CTX *ctx).
		external
			"C inline use %"eif_openssl.h%""
		alias
			"return SSL_CTX_get_options((SSL_CTX *)$a_ctx);"
		end

	c_ssl_ctx_set_min_proto_version (a_ctx: POINTER; a_version: NATURAL): INTEGER_64
			-- External call to SSL_CTX_set_min_proto_version(SSL_CTX *ctx, int version);
		external
			"C inline use %"eif_openssl.h%""
		alias
			"return SSL_CTX_set_min_proto_version((SSL_CTX *)$a_ctx, (int) $a_version);"
		end

	ssl_ctx_set_max_proto_version (a_ctx: POINTER; a_version: NATURAL): INTEGER_64
			-- External call to SSL_CTX_set_max_proto_version(SSL_CTX *ctx, int version);
		external
			"C inline use %"eif_openssl.h%""
		alias
			"return SSL_CTX_set_max_proto_version((SSL_CTX *)$a_ctx, (int) $a_version);"
		end

	c_ssl_ctx_get_min_proto_version (a_ctx: POINTER): NATURAL
			-- External call to SSL_CTX_get_min_proto_version(SSL_CTX *ctx).
		external
			"C inline use %"eif_openssl.h%""
		alias
			"return (EIF_NATURAL) SSL_CTX_get_min_proto_version((SSL_CTX *)$a_ctx);"
		end

	c_ssl_ctx_get_max_proto_version (a_ctx: POINTER): NATURAL
			-- External call to SSL_CTX_get_max_proto_version(SSL_CTX *ctx).
		external
			"C inline use %"eif_openssl.h%""
		alias
			"return (EIF_NATURAL) SSL_CTX_get_max_proto_version((SSL_CTX *)$a_ctx);"
		end

	c_ssl_version (a_ctx: POINTER): INTEGER
		external
			"C inline use %"eif_openssl.h%""
		alias
			"return SSL_version((const SSL *)$a_ctx);"
		end

note
	copyright: "Copyright (c) 1984-2018, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"

end
