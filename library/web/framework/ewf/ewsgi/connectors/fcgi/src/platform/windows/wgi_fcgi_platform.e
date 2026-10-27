note
	description: "[
			Platform specific helpers for the FastCGI connector (Windows).

			On Windows, web servers spawning FastCGI applications (mod_fcgid, IIS)
			use a named pipe, which is not supported: use a TCP port instead.
		]"
	date: "$Date$"
	revision: "$Revision$"

class
	WGI_FCGI_PLATFORM

feature -- Status report

	is_inherited_listening_socket_supported: BOOLEAN = False
			-- Is listening on a socket inherited from the web server supported?

	is_listening_socket (fd: INTEGER): BOOLEAN
			-- Is `fd' a listening socket?
		do
			Result := False
		end

feature -- Basic operation

	duplicated_descriptor (fd: INTEGER): INTEGER
			-- New file descriptor duplicating `fd', or -1 on failure.
		do
			Result := -1
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
