note
	description: "Implementation of request handler factory for WGI_FCGI_CONNECTOR."
	date: "$Date$"
	revision: "$Revision$"

class
	WGI_FCGI_REQUEST_HANDLER_FACTORY [G -> WGI_EXECUTION create make end]

inherit
	HTTPD_REQUEST_HANDLER_FACTORY

feature -- Access

	connector: detachable separate WGI_FCGI_CONNECTOR [G]
			-- Associated connector.

	request_settings: HTTPD_REQUEST_SETTINGS
			-- Settings specific to request handling.

	max_connections: INTEGER
			-- Maximum number of concurrent connections.

feature -- Element change

	update_with (conn: like connector; a_conf: separate HTTPD_CONFIGURATION)
			-- Set `connector' with `conn', and update settings from `a_conf'.
		do
			connector := conn
			request_settings := a_conf.request_settings
			max_connections := a_conf.max_concurrent_connections
		end

feature -- Factory

	new_handler: separate WGI_FCGI_REQUEST_HANDLER [G]
		do
			create Result.make_with_connector (request_settings, connector, max_connections)
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
