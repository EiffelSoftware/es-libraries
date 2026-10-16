note
	description: "Platform specific helpers for the FastCGI connector (Unix)."
	date: "$Date$"
	revision: "$Revision$"

class
	WGI_FCGI_PLATFORM

feature -- Status report

	is_inherited_listening_socket_supported: BOOLEAN = True
			-- Is listening on a socket inherited from the web server supported?

	is_listening_socket (fd: INTEGER): BOOLEAN
			-- Is `fd' a listening socket?
			-- This is the case when the application is spawned by the web server
			-- (Apache mod_fcgid, lighttpd, spawn-fcgi, ...) with the listening socket as stdin.
		external
			"C inline use <sys/socket.h>, <errno.h>"
		alias
			"[
				struct sockaddr_storage sa;
				socklen_t len = sizeof(sa);
				if (getpeername((int) $fd, (struct sockaddr *) &sa, &len) == 0) {
					return EIF_FALSE;
				}
				return EIF_TEST(errno == ENOTCONN);
			]"
		end

feature -- Basic operation

	duplicated_descriptor (fd: INTEGER): INTEGER
			-- New file descriptor duplicating `fd', or -1 on failure.
		external
			"C inline use <unistd.h>"
		alias
			"return (EIF_INTEGER) dup((int) $fd);"
		end

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
