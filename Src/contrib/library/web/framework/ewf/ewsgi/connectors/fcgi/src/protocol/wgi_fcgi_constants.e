note
	description: "[
			Constants of the FastCGI protocol (version 1).

			See https://fastcgi-archives.github.io/FastCGI_Specification.html
		]"
	date: "$Date$"
	revision: "$Revision$"

class
	WGI_FCGI_CONSTANTS

feature -- Protocol

	fcgi_version_1: NATURAL_8 = 1
			-- FastCGI protocol version.

	fcgi_header_length: INTEGER = 8
			-- Number of bytes in a record header.

	fcgi_max_content_length: INTEGER = 65535
			-- Maximum number of content bytes in a record.

	fcgi_max_padding_length: INTEGER = 255
			-- Maximum number of padding bytes in a record.

	fcgi_null_request_id: INTEGER = 0
			-- Request id used by management records.

	fcgi_listensock_fileno: INTEGER = 0
			-- File descriptor of the listening socket, when the application
			-- is spawned by the web server (Apache mod_fcgid, lighttpd, ...).

feature -- Record types

	fcgi_begin_request: INTEGER = 1
	fcgi_abort_request: INTEGER = 2
	fcgi_end_request: INTEGER = 3
	fcgi_params: INTEGER = 4
	fcgi_stdin: INTEGER = 5
	fcgi_stdout: INTEGER = 6
	fcgi_stderr: INTEGER = 7
	fcgi_data: INTEGER = 8
	fcgi_get_values: INTEGER = 9
	fcgi_get_values_result: INTEGER = 10
	fcgi_unknown_type: INTEGER = 11

feature -- Flags

	fcgi_keep_conn: INTEGER = 1
			-- Flag of FCGI_BEGIN_REQUEST body: keep the connection open after the request.

feature -- Roles

	fcgi_responder: INTEGER = 1
	fcgi_authorizer: INTEGER = 2
	fcgi_filter: INTEGER = 3

feature -- Protocol status

	fcgi_request_complete: INTEGER = 0
	fcgi_cant_mpx_conn: INTEGER = 1
	fcgi_overloaded: INTEGER = 2
	fcgi_unknown_role: INTEGER = 3

feature -- Management variables

	fcgi_max_conns: STRING = "FCGI_MAX_CONNS"
	fcgi_max_reqs: STRING = "FCGI_MAX_REQS"
	fcgi_mpxs_conns: STRING = "FCGI_MPXS_CONNS"

note
	copyright: "2011-2026, Jocelyn Fiat, Javier Velilla, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"
end
