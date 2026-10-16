note
	description: "[
			Socket for the FastCGI connector.

			In addition to the usual sockets, it can wrap the listening socket
			inherited from the web server when the application is spawned by it
			(Apache mod_fcgid, lighttpd, spawn-fcgi, ...).
		]"
	date: "$Date$"
	revision: "$Revision$"

class
	WGI_FCGI_STREAM_SOCKET

inherit
	HTTPD_STREAM_SOCKET

create
	make_empty,
	make_from_inherited_descriptor

create {NETWORK_STREAM_SOCKET}
	make_from_descriptor_and_address

feature {NONE} -- Initialization

	make_from_inherited_descriptor (a_fd: INTEGER)
			-- Create listening socket from inherited descriptor `a_fd'
			-- which is already bound (and listening).
		require
			a_fd_positive: a_fd > 0
		do
			make_from_descriptor_and_address (a_fd, create {NETWORK_SOCKET_ADDRESS}.make_localhost (0))
			is_bound := True
		ensure
			is_bound: is_bound
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
