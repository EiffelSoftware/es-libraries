note
	description: "[
			Handler processing the FastCGI requests received on an accepted connection.

			It reuses the httpd connection management (thread pool, SCOOP, ...),
			but replaces the HTTP parsing with the FastCGI protocol.
		]"
	date: "$Date$"
	revision: "$Revision$"

class
	WGI_FCGI_REQUEST_HANDLER [G -> WGI_EXECUTION create make end]

inherit
	HTTPD_REQUEST_HANDLER
		redefine
			execute,
			new_client_socket
		end

	WGI_EXPORTER

create
	make,
	make_with_connector

feature {NONE} -- Initialization

	make_with_connector (a_request_settings: HTTPD_REQUEST_SETTINGS; conn: like connector; a_max_connections: INTEGER)
		do
			make (a_request_settings)
			connector := conn
			max_connections := a_max_connections
		end

feature -- Access

	connector: detachable separate WGI_FCGI_CONNECTOR [G]
			-- Associated connector.

	max_connections: INTEGER
			-- Maximum number of concurrent connections, announced to the web server.

	base: detachable IMMUTABLE_STRING_8
			-- Root url base.
		do
			if attached connector as conn then
				if attached connector_base (conn) as l_base then
					create Result.make_from_separate (l_base)
				end
			end
		end

feature -- SCOOP helpers

	connector_base (conn: separate WGI_FCGI_CONNECTOR [G]): detachable separate READABLE_STRING_8
			-- Root url based from a connector `conn'.
		do
			Result := conn.base
		end

feature {NONE} -- Factory

	new_client_socket (a_is_secure: BOOLEAN): HTTPD_STREAM_SOCKET
			-- <Precursor>
		do
			create {WGI_FCGI_STREAM_SOCKET} Result.make_empty
		end

feature -- Execution

	execute
			-- <Precursor>
			-- Process the FastCGI requests sent by the web server on `client_socket'.
		local
			l_socket: like client_socket
			conn: WGI_FCGI_CONNECTION
			n: INTEGER
		do
			l_socket := client_socket
			l_socket.set_timeout_ns (timeout_ns)
			l_socket.set_recv_timeout_ns (socket_recv_timeout_ns)
			create conn.make (l_socket, max_connections)
			from
			until
				not conn.wait_for_request
			loop
				n := n + 1
				l_socket.set_recv_timeout_ns (socket_recv_timeout_ns)
				if is_verbose then
					log_request (conn, n)
				end
				process_fcgi_request (conn)
				conn.finish_request (0)
				if conn.has_error and is_verbose and attached conn.error_message as err then
					log ("FastCGI error: " + err, warning_level)
				end
					-- Waiting for next request on persistent connection.
				l_socket.set_recv_timeout_ns (keep_alive_timeout_ns)
			end
			conn.close
		end

	process_fcgi_request (conn: WGI_FCGI_CONNECTION)
			-- Process the current request of connection `conn'.
		require
			has_request: conn.has_request
		local
			l_input: WGI_FCGI_INPUT_STREAM
			l_output: detachable WGI_FCGI_OUTPUT_STREAM
			req: detachable WGI_REQUEST_FROM_TABLE
			res: detachable WGI_RESPONSE_STREAM
			exec: detachable WGI_EXECUTION
			retried: BOOLEAN
		do
			if not retried then
				create l_input.make (conn)
				create l_output.make (conn)
				create req.make (fcgi_environment (conn.params), l_input, connector)
				create res.make (l_output, l_output)
				create {G} exec.make (req, res)
				exec.execute
				res.push
				exec.clean
			elseif exec /= Void then
				exec.execute_rescue ((create {EXCEPTION_MANAGER}).last_exception)
				exec.clean
			else
				(create {WGI_RESCUE_EXECUTION}).execute (req, res, (create {EXCEPTION_MANAGER}).last_exception)
			end
			if l_output /= Void and then conn.has_request then
				l_output.flush
			end
		rescue
			if not retried then
				retried := True
				retry
			end
		end

	process_request (a_socket: HTTPD_STREAM_SOCKET)
			-- <Precursor>
			-- Not used: FastCGI requests are processed by `execute'.
		do
		end

feature {NONE} -- Environment

	fcgi_environment (a_params: STRING_TABLE [READABLE_STRING_8]): STRING_TABLE [READABLE_STRING_8]
			-- CGI meta variables from FastCGI params `a_params',
			-- completed with PATH_INFO when the web server did not provide it (nginx default).
		local
			l_path_info: STRING_8
			l_base: detachable READABLE_STRING_8
			p: INTEGER
			enc: URL_ENCODER
		do
			Result := a_params
			if
				not attached Result.item ({WGI_META_NAMES}.path_info) as l_existing_path_info or else
				l_existing_path_info.is_empty
			then
				if attached Result.item ({WGI_META_NAMES}.request_uri) as l_request_uri then
					create l_path_info.make_from_string (l_request_uri)
					p := l_path_info.index_of ('?', 1)
					if p > 0 then
						l_path_info.keep_head (p - 1)
					end
					l_base := base
					if l_base /= Void and then not l_base.is_empty and then l_path_info.starts_with (l_base) then
						l_path_info.remove_head (l_base.count)
					else
						l_base := ""
					end
					convert_multiple_slashes_to_single (l_path_info)
					create enc
					Result.force (enc.decoded_utf_8_string (l_path_info), {WGI_META_NAMES}.path_info)
					Result.force (l_base, {WGI_META_NAMES}.script_name)
				end
			end
			if not Result.has ({WGI_META_NAMES}.gateway_interface) then
				Result.force ("CGI/1.1", {WGI_META_NAMES}.gateway_interface)
			end
		end

	convert_multiple_slashes_to_single (s: STRING_8)
			-- Replace multiple slashes sequence by a single slash character.
		local
			i, n: INTEGER
		do
			from
				i := 1
				n := s.count
			until
				i > n
			loop
				if s [i] = '/' then
					from
						i := i + 1
					until
						i > n or else s [i] /= '/'
					loop
						s.remove (i)
						n := n - 1
					end
				else
					i := i + 1
				end
			end
		end

feature {NONE} -- Logging

	log_request (conn: WGI_FCGI_CONNECTION; a_index: INTEGER)
			-- Log current request of `conn'.
		local
			s: STRING
		do
			create s.make (64)
			s.append ("FastCGI request #")
			s.append_integer (conn.request_id)
			if a_index > 1 then
				s.append (" (connection reused ")
				s.append_integer (a_index)
				s.append_character (')')
			end
			s.append_character (' ')
			if attached conn.params.item ({WGI_META_NAMES}.request_method) as l_method then
				s.append (l_method)
				s.append_character (' ')
			end
			if attached conn.params.item ({WGI_META_NAMES}.request_uri) as l_uri then
				s.append (l_uri)
			end
			log (s, information_level)
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
