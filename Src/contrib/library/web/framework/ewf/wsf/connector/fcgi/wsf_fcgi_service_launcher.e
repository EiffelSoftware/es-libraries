note
	description: "[
			Component to launch the service using the FastCGI connector (pure Eiffel, no libfcgi).

			When spawned by the web server (Apache mod_fcgid, lighttpd, spawn-fcgi) on Unix,
			the application uses the listening socket inherited as stdin.
			Otherwise it listens on the TCP port, for instance for:
				nginx:  fastcgi_pass 127.0.0.1:9000;
				Apache: ProxyPass "/app/" "fcgi://127.0.0.1:9000/"

			The FastCGI connector supports options:
				port: TCP port (default: 9000)
				server_name: address to bind (default: 127.0.0.1, use 0.0.0.0 for all interfaces, e.g. in a container)
				base: base url, used to compute PATH_INFO when the web server does not send it (nginx default)
				verbose: to display verbose output
				verbose_level: alert, critical, error, warning, notice, information, debug (combined with '+')

				max_concurrent_connections: number of connections processed concurrently
						(should be greater than the number of persistent connections kept by the web server)
				max_tcp_clients: listen backlog

				socket_timeout: connection timeout (seconds by default, or with unit ns, ms, s)
				socket_recv_timeout: timeout when reading request data
				keep_alive_timeout: delay to wait for the next request on a persistent connection
						(should be greater than the web server keepalive timeout)

				ignore_inherited_socket: if True, always listen on the TCP port

			check WSF_SERVICE_LAUNCHER for more documentation
		]"
	date: "$Date$"
	revision: "$Revision$"

class
	WSF_FCGI_SERVICE_LAUNCHER [G -> WSF_EXECUTION create make end]

inherit
	WSF_SERVICE_LAUNCHER [G]
		redefine
			launchable
		end

	HTTPD_LOGGER_CONSTANTS

	WSF_TIMEOUT_UTILITIES

create
	make,
	make_and_launch

feature {NONE} -- Initialization

	initialize
		local
			conn: like connector
			s: READABLE_STRING_GENERAL
		do
			create on_launched_actions

			port_number := default_port_number
			server_name := default_server_name
			max_concurrent_connections := 100
			max_tcp_clients := 100
			socket_timeout_ns := seconds_to_nanoseconds (60)
			socket_recv_timeout_ns := seconds_to_nanoseconds (60)
			keep_alive_timeout_ns := seconds_to_nanoseconds (75)
			verbose := False
			verbose_level := notice_level

			if attached options as opts then
				if attached {READABLE_STRING_GENERAL} opts.option ("server_name") as l_server_name then
					server_name := l_server_name.to_string_8
				end
				if
					attached {READABLE_STRING_GENERAL} opts.option ("base") as l_base_str and then
					l_base_str.is_valid_as_string_8
				then
					base_url := l_base_str.to_string_8
				end

				verbose := opts.option_boolean_value ("verbose", verbose)
				if opts.has_integer_option ("verbose_level") then
					verbose_level := opts.option_integer_value ("verbose_level", verbose_level)
				elseif attached {READABLE_STRING_GENERAL} opts.option ("verbose_level") as s_verbose_level then
					verbose_level := 0
					across
						s_verbose_level.split ('+') as ic
					loop
						s := ic.item
						if s.is_case_insensitive_equal ("alert") then
							verbose_level := verbose_level | alert_level
						elseif s.is_case_insensitive_equal ("critical") then
							verbose_level := verbose_level | critical_level
						elseif s.is_case_insensitive_equal ("error") then
							verbose_level := verbose_level | error_level
						elseif s.is_case_insensitive_equal ("warning") then
							verbose_level := verbose_level | warning_level
						elseif s.is_case_insensitive_equal ("notice") then
							verbose_level := verbose_level | notice_level
						elseif s.is_case_insensitive_equal ("information") then
							verbose_level := verbose_level | information_level
						elseif s.is_case_insensitive_equal ("debug") then
							verbose_level := verbose_level | debug_level
						end
					end
				end
				port_number := opts.option_integer_value ("port", port_number)
				max_concurrent_connections := opts.option_integer_value ("max_concurrent_connections", max_concurrent_connections)
				max_tcp_clients := opts.option_integer_value ("max_tcp_clients", max_tcp_clients)
				socket_timeout_ns := opts.option_timeout_ns_value ("socket_timeout", socket_timeout_ns)
				socket_recv_timeout_ns := opts.option_timeout_ns_value ("socket_recv_timeout", socket_recv_timeout_ns)
				keep_alive_timeout_ns := opts.option_timeout_ns_value ("keep_alive_timeout", keep_alive_timeout_ns)
				is_inherited_socket_ignored := opts.option_boolean_value ("ignore_inherited_socket", is_inherited_socket_ignored)
			end

			create conn.make
			connector := conn
			conn.on_launched_actions.extend (agent on_launched)
			conn.set_base (base_url)
			conn.set_is_inherited_listening_socket_ignored (is_inherited_socket_ignored)
			update_configuration (conn.configuration)
		end

feature -- Execution

	update_configuration (cfg: like connector.configuration)
		do
			cfg.set_is_verbose (verbose)
			cfg.set_verbose_level (verbose_level)
			cfg.set_http_server_name_from_separate (server_name)
			cfg.http_server_port := port_number
			cfg.is_reuse_address_allowed := True
			cfg.set_max_concurrent_connections (max_concurrent_connections)
			cfg.set_max_tcp_clients (max_tcp_clients)
			cfg.set_socket_timeout_ns (socket_timeout_ns)
			cfg.set_socket_recv_timeout_ns (socket_recv_timeout_ns)
			cfg.set_keep_alive_timeout_ns (keep_alive_timeout_ns)
		end

	launch
			-- <Precursor/>
		local
			conn: like connector
		do
			conn := connector
			conn.set_base (base_url)
			update_configuration (conn.configuration)
			conn.launch
		end

feature -- Callback

	on_launched_actions: ACTION_SEQUENCE [TUPLE [like connector]]
			-- Actions triggered when launched.

feature -- Status report

	connector: WGI_FCGI_CONNECTOR [G]
			-- Default connector.

	launchable: BOOLEAN
		do
			Result := Precursor and port_number >= 0
		end

feature {NONE} -- Implementation

	on_launched (conn: like connector)
		do
			on_launched_actions.call ([conn])
		end

	default_port_number: INTEGER = 9000
			-- Default TCP port.

	default_server_name: STRING = "127.0.0.1"
			-- Default address to bind.

	port_number: INTEGER

	server_name: detachable READABLE_STRING_8

	base_url: detachable READABLE_STRING_8

	verbose: BOOLEAN

	verbose_level: INTEGER

	max_concurrent_connections: INTEGER

	max_tcp_clients: INTEGER

	socket_timeout_ns: NATURAL_64

	socket_recv_timeout_ns: NATURAL_64

	keep_alive_timeout_ns: NATURAL_64

	is_inherited_socket_ignored: BOOLEAN

;note
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
