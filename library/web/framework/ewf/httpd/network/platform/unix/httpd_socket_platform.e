note
	description: "Platform specific socket helpers for the httpd server (Unix)."
	date: "$Date$"
	revision: "$Revision$"

class
	HTTPD_SOCKET_PLATFORM

feature -- Basic operation

	shutdown_write (a_socket: HTTPD_STREAM_SOCKET)
			-- Disable further send operations on `a_socket' (half close),
			-- the peer receives an end of stream, but `a_socket' can still be read.
		do
			if a_socket.descriptor_available then
				last_shutdown_succeed := c_shutdown_write (a_socket.descriptor) = 0
			else
				last_shutdown_succeed := False
			end
		end

feature -- Status report

	last_shutdown_succeed: BOOLEAN
			-- Did last `shutdown_write' succeed?

feature {NONE} -- Externals

	c_shutdown_write (a_fd: INTEGER): INTEGER
		external
			"C inline use <sys/socket.h>"
		alias
			"return (EIF_INTEGER) shutdown ((int) $a_fd, SHUT_WR);"
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
