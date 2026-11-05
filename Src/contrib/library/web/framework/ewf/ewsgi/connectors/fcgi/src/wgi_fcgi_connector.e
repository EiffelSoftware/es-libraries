note
	description: "[
			FastCGI connector implemented in pure Eiffel (no dependency on the C libfcgi).

			The application is a FastCGI server, accepting connections from the web server:
				- on the socket inherited as stdin, when spawned by the web server
				  (Apache mod_fcgid, lighttpd, spawn-fcgi) [Unix only],
				- otherwise on the configured TCP port, for instance with
				  nginx `fastcgi_pass 127.0.0.1:9000;'
				  or Apache `ProxyPass "/app/" "fcgi://127.0.0.1:9000/"'.

			Connections are processed concurrently (according to the concurrency mode, and
			the max_concurrent_connections setting), and persistent connections (FCGI_KEEP_CONN)
			are supported.
		]"
	date: "$Date$"
	revision: "$Revision$"

class
	WGI_FCGI_CONNECTOR [G -> WGI_EXECUTION create make end]

inherit
	WGI_CONNECTOR

create
	make,
	make_with_base

feature {NONE} -- Initialization

	make
			-- Create current FastCGI connector.
		local
			fac: like request_handler_factory
		do
				-- Callbacks
			create on_launched_actions

				-- Server
			create <NONE> fac
			request_handler_factory := fac
			create server.make (fac)
			create <NONE> observer
			configuration := server_configuration (server)
			controller := server_controller (server)
			initialize_server (server)
		end

	make_with_base (a_base: detachable separate READABLE_STRING_8)
			-- Create current connector with base url `a_base'.
		require
			a_base_starts_with_slash: (a_base /= Void and then not a_base.is_empty) implies is_valid_base (a_base)
		do
			make
			set_base (a_base)
		end

feature {NONE} -- Separate helper

	initialize_server (a_server: like server)
		do
			a_server.set_observer (observer)
		end

	update_factory (conn: detachable separate WGI_FCGI_CONNECTOR [G]; fac: separate WGI_FCGI_REQUEST_HANDLER_FACTORY [G]; a_conf: like configuration)
		do
			fac.update_with (conn, a_conf)
		end

	server_configuration (a_server: like server): like configuration
		do
			Result := a_server.configuration
		end

	server_controller (a_server: like server): separate HTTPD_CONTROLLER
		do
			Result := a_server.controller
		end

feature -- Access

	name: STRING_8 = "fcgi"
			-- Name of Current connector.

	version: STRING_8 = "1.0"
			-- Version of Current connector.

feature -- Access

	server: separate WGI_FCGI_HTTPD_SERVER
			-- Server object accepting FastCGI connections.

	request_handler_factory: separate WGI_FCGI_REQUEST_HANDLER_FACTORY [G]
			-- Factory for request handlers.

	controller: separate HTTPD_CONTROLLER
			-- Controller used to shutdown server.

	observer: separate WGI_FCGI_SERVER_OBSERVER
			-- Observer providing information related to port number, and server status.

	configuration: separate HTTPD_CONFIGURATION
			-- Server configuration.

	base: detachable READABLE_STRING_8
			-- Root url base, used to compute PATH_INFO when the web server does not provide it.

feature -- Status report

	launched: BOOLEAN
			-- Server launched?

	port: INTEGER
			-- Listening port.
			--| 0: not launched, or listening on inherited socket.

feature -- Callbacks

	on_launched_actions: ACTION_SEQUENCE [TUPLE [WGI_FCGI_CONNECTOR [WGI_EXECUTION]]]
			-- Actions triggered when launched.
			-- WARNING: only supported for now with SCOOP concurrency mode.

feature -- Event

	on_launched (a_port: INTEGER)
			-- Server launched.
		do
			launched := True
			port := a_port
			on_launched_actions.call ([Current])
		end

feature -- Element change

	set_base (v: detachable separate READABLE_STRING_8)
			-- Set base url `base' to `v'.
		require
			b_starts_with_slash: (v /= Void and then not v.is_empty) implies is_valid_base (v)
		do
			if v = Void then
				base := Void
			else
				create {STRING_8} base.make_from_separate (v)
			end
		end

	is_valid_base (v: separate READABLE_STRING_8): BOOLEAN
		do
			Result := not v.is_whitespace and then v [1] = '/'
		end

	set_port_number (a_port_number: INTEGER)
			-- Set port number to `a_port_number'.
		require
			a_port_number_positive_or_zero: a_port_number >= 0
		do
			set_port_on_configuration (a_port_number, configuration)
		end

	set_max_concurrent_connections (nb: INTEGER)
			-- Set maximum concurrent connections to `nb'.
		require
			nb_positive_or_zero: nb >= 0
		do
			set_max_concurrent_connections_on_configuration (nb, configuration)
		end

	set_is_verbose (b: BOOLEAN)
			-- Set verbose mode.
		do
			set_is_verbose_on_configuration (b, configuration)
		end

	set_is_inherited_listening_socket_ignored (b: BOOLEAN)
			-- Ignore listening socket inherited from the web server, and always use the TCP port?
		do
			set_is_inherited_listening_socket_ignored_on_server (b, server)
		end

feature -- Server

	launch_on_port (a_port_number: INTEGER)
			-- Launch server listening on port `a_port_number'.
		do
			set_port_number (a_port_number)
			launch
		end

	launch
			-- Launch FastCGI server.
		do
			launched := False
			port := 0
			launch_server (server)
			on_server_started (observer)
		end

	shutdown_server
			-- Shutdown server.
		do
			if launched then
				separate_shutdown_server_on_controller (controller)
			end
		end

feature -- Events

	on_server_started (obs: like observer)
			-- Server started.
		require
			obs.started -- SCOOP wait condition.
		do
			if obs.port > 0 then
				on_launched (obs.port)
			end
		end

feature {NONE} -- Implementation

	apply_configuration (a_configuration: like configuration)
		do
			if a_configuration.is_verbose then
				if attached base as l_base and then not l_base.is_whitespace then
					io.error.put_string ("Base=" + l_base + "%N")
				end
			end
			update_factory (Current, request_handler_factory, a_configuration)
		end

	launch_server (a_server: like server)
		do
			apply_configuration (a_server.configuration)
			a_server.launch
		end

	separate_shutdown_server_on_controller (a_controller: separate HTTPD_CONTROLLER)
		do
			a_controller.shutdown
		end

feature {NONE} -- Implementation: element change

	set_port_on_configuration (a_port_number: INTEGER; cfg: like configuration)
		do
			cfg.set_http_server_port (a_port_number)
		end

	set_max_concurrent_connections_on_configuration (nb: INTEGER; cfg: like configuration)
		do
			cfg.set_max_concurrent_connections (nb)
		end

	set_is_verbose_on_configuration (b: BOOLEAN; cfg: like configuration)
		do
			cfg.set_is_verbose (b)
		end

	set_is_inherited_listening_socket_ignored_on_server (b: BOOLEAN; a_server: like server)
		do
			a_server.set_is_inherited_listening_socket_ignored (b)
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
