note
	description: "Server status observer for the FastCGI connector."
	date: "$Date$"
	revision: "$Revision$"

class
	WGI_FCGI_SERVER_OBSERVER

inherit
	HTTPD_SERVER_OBSERVER

feature -- Access

	started: BOOLEAN
			-- Is the server started?

	stopped: BOOLEAN
			-- Is the server stopped?

	terminated: BOOLEAN
			-- Is the server terminated?

	port: INTEGER
			-- Server listening on port (0 when listening on inherited socket).

feature -- Event

	on_launched (a_port: INTEGER)
		do
			started := True
			port := a_port
		end

	on_stopped
		do
			stopped := True
		end

	on_terminated
		do
			port := 0
			terminated := True
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
