note
	description: "[
		Local HTTP server for the streaming tests: in a thread, it accepts one connection, reads the
		request, and answers with a chunked response whose parts are sent with delays.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_STREAMING_SERVER

create
	make

feature {NONE} -- Initialization

	make (a_first_delay_ms: INTEGER; a_parts: ARRAY [READABLE_STRING_8]; a_delays_ms: ARRAY [INTEGER])
			-- Server waiting `a_first_delay_ms' before answering, then sending each part of `a_parts'
			-- after the delay of the same index in `a_delays_ms'.
		require
			same_count: a_parts.count = a_delays_ms.count
		do
			first_delay_ms := a_first_delay_ms
			parts := a_parts
			delays_ms := a_delays_ms
		end

feature -- Access

	port: INTEGER
			-- Port listened to (on the loopback interface), once started

	url: STRING_8
			-- URL of the server
		do
			Result := "http://127.0.0.1:" + port.out
		end

feature -- Basic operations

	start
			-- Listen, and serve one connection in a thread.
		local
			l_socket: detachable NETWORK_STREAM_SOCKET
			l_thread: WORKER_THREAD
			p: INTEGER
		do
				-- (A free port near a random one.)
			from
				p := 40000 + ((create {TIME}.make_now).milli_second * 7 + (create {TIME}.make_now).second * 13) \\ 20000
			until
				l_socket /= Void or p > 65000
			loop
				l_socket := new_server_socket (p)
				if l_socket = Void then
					p := p + 1
				end
			end
			if l_socket /= Void then
				port := p
				server_socket := l_socket
				l_socket.listen (1)
				create l_thread.make (agent serve (l_socket))
				thread := l_thread
				l_thread.launch
			end
		end

	stop
			-- Stop serving (the delays end early), and wait for the thread.
		do
			is_stop_requested := True
			if attached thread as t then
				t.join
			end
			if attached server_socket as s and then not s.is_closed then
				s.close
			end
		end

feature {NONE} -- Implementation

	first_delay_ms: INTEGER
	parts: ARRAY [READABLE_STRING_8]
	delays_ms: ARRAY [INTEGER]
			-- Behavior of the server

	server_socket: detachable NETWORK_STREAM_SOCKET
			-- Socket listened to

	thread: detachable WORKER_THREAD
			-- Thread serving the connection

	is_stop_requested: BOOLEAN
			-- Should the server stop?

	new_server_socket (a_port: INTEGER): detachable NETWORK_STREAM_SOCKET
			-- Server socket bound to `a_port' on the loopback interface, if possible
		local
			retried: BOOLEAN
		do
			if not retried then
				create Result.make_loopback_server_by_port (a_port)
				if not Result.is_bound then
					Result := Void
				end
			end
		rescue
			retried := True
			retry
		end

	serve (a_socket: NETWORK_STREAM_SOCKET)
			-- Accept a connection on `a_socket', read the request, send the response.
		local
			retried: BOOLEAN
			l_done: BOOLEAN
			i: INTEGER
		do
			if not retried then
				a_socket.accept
				if attached a_socket.accepted as c then
					from
					until
						l_done
					loop
						c.read_line
						l_done := c.last_string.is_empty or else c.last_string.same_string ("%R") or else not c.readable
					end
					wait (first_delay_ms)
					if not is_stop_requested then
						c.put_string ("HTTP/1.1 200 OK%R%NContent-Type: text/event-stream%R%NTransfer-Encoding: chunked%R%NConnection: close%R%N%R%N")
						from
							i := parts.lower
						until
							i > parts.upper or is_stop_requested
						loop
							wait (delays_ms [i])
							if not is_stop_requested then
								c.put_string (parts [i].count.to_hex_string.as_lower + "%R%N" + parts [i] + "%R%N")
							end
							i := i + 1
						end
						if not is_stop_requested then
							c.put_string ("0%R%N%R%N")
						end
					end
					c.close
				end
			end
		rescue
				-- (The client may have closed the connection.)
			retried := True
			retry
		end

	wait (a_ms: INTEGER)
			-- Wait `a_ms' milliseconds, or less if the server is asked to stop.
		local
			i: INTEGER
		do
			from
				i := 0
			until
				i >= a_ms or is_stop_requested
			loop
				(create {EXECUTION_ENVIRONMENT}).sleep (20_000_000)
				i := i + 20
			end
		end

note
	copyright: "2011-2026, Jocelyn Fiat, Javier Velilla, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
end
