note
	description: "[
			Server accepting FastCGI connections from the web server.

			It listens either:
				- on the socket inherited from the web server as stdin (fd 0),
				  when the application is spawned by the web server (Apache mod_fcgid, lighttpd, spawn-fcgi),
				- or on the configured TCP port (nginx fastcgi_pass, Apache mod_proxy_fcgi, ...).
		]"
	date: "$Date$"
	revision: "$Revision$"

class
	WGI_FCGI_HTTPD_SERVER

inherit
	HTTPD_SERVER
		redefine
			new_listening_socket
		end

	WGI_FCGI_CONSTANTS

create
	make

feature -- Status report

	is_inherited_listening_socket_ignored: BOOLEAN
			-- Ignore listening socket inherited from the web server, and always use the TCP port?

	is_using_inherited_listening_socket: BOOLEAN
			-- Is the server listening on the socket inherited from the web server?

feature -- Element change

	set_is_inherited_listening_socket_ignored (b: BOOLEAN)
			-- Set `is_inherited_listening_socket_ignored' to `b'.
		do
			is_inherited_listening_socket_ignored := b
		ensure
			is_inherited_listening_socket_ignored_set: is_inherited_listening_socket_ignored = b
		end

feature {NONE} -- Factory

	new_listening_socket (a_addr: detachable INET_ADDRESS; a_http_port: INTEGER): HTTPD_STREAM_SOCKET
			-- <Precursor>
		local
			l_platform: WGI_FCGI_PLATFORM
			fd: INTEGER
		do
			is_using_inherited_listening_socket := False
			create l_platform
			if
				not is_inherited_listening_socket_ignored and then
				l_platform.is_inherited_listening_socket_supported and then
				l_platform.is_listening_socket (fcgi_listensock_fileno)
			then
				fd := l_platform.duplicated_descriptor (fcgi_listensock_fileno)
			end
			if fd > 0 then
				is_using_inherited_listening_socket := True
				if is_verbose then
					log ("Using FastCGI listening socket inherited from the web server.")
				end
				create {WGI_FCGI_STREAM_SOCKET} Result.make_from_inherited_descriptor (fd)
			else
				Result := Precursor (a_addr, a_http_port)
			end
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
