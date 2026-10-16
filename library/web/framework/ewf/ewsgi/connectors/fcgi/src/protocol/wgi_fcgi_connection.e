note
	description: "[
			FastCGI connection between the web server (nginx, Apache, lighttpd, ...)
			and the application, implemented in pure Eiffel on top of a stream socket.

			The connection processes one request at a time (FCGI_MPXS_CONNS=0),
			and may process several successive requests if the web server
			asked to keep the connection open (FCGI_KEEP_CONN).

			Typical usage:
				from until not conn.wait_for_request loop
					-- use `params', `read_stdin' and `put_stdout'
					conn.finish_request (0)
				end
		]"
	date: "$Date$"
	revision: "$Revision$"

class
	WGI_FCGI_CONNECTION

inherit
	WGI_FCGI_CONSTANTS

	STRING_HANDLER

create
	make

feature {NONE} -- Initialization

	make (a_socket: like socket; a_max_connections: INTEGER)
			-- Create FastCGI connection over `a_socket',
			-- announcing `a_max_connections' to the web server when asked.
		do
			socket := a_socket
			max_connections := a_max_connections
			create header_buffer.make (fcgi_header_length)
			create content_buffer.make (fcgi_max_content_length + fcgi_max_padding_length)
			create output_buffer.make (fcgi_header_length + fcgi_max_content_length)
			create stdin_buffer.make (0)
			create params.make_equal (0)
			stdin_index := 1
		end

feature -- Access

	socket: HTTPD_STREAM_SOCKET
			-- Socket connected to the web server.

	max_connections: INTEGER
			-- Value for FCGI_MAX_CONNS and FCGI_MAX_REQS management variables.

	request_id: INTEGER
			-- Id of the current request, 0 if none.

	role: INTEGER
			-- Role of the current request.

	params: STRING_TABLE [READABLE_STRING_8]
			-- CGI/1.1 meta variables of the current request (FCGI_PARAMS stream).

feature -- Status report

	has_request: BOOLEAN
			-- Is there a request being processed?
		do
			Result := request_id /= 0
		end

	is_keep_connection: BOOLEAN
			-- Did the web server ask to keep the connection open after current request?

	is_connection_closing: BOOLEAN
			-- Should the connection be closed (no more request expected)?

	is_aborted: BOOLEAN
			-- Was the current request aborted by the web server (FCGI_ABORT_REQUEST)?

	is_stdin_ended: BOOLEAN
			-- Was the end of the FCGI_STDIN stream received?

	end_of_stdin: BOOLEAN
			-- Is there no more stdin data to read for the current request?
		do
			Result := is_stdin_ended and not has_pending_stdin
		end

	has_error: BOOLEAN
			-- Did an error occur (network or protocol)?

	error_message: detachable STRING_8
			-- Description of the error, if any.

feature -- Request

	wait_for_request: BOOLEAN
			-- Wait for the next FastCGI responder request (FCGI_BEGIN_REQUEST and complete FCGI_PARAMS stream).
			-- Return True if a request is ready, False if the connection is over (closed, error, ...).
		local
			l_params_data: STRING_8
			done: BOOLEAN
		do
			reset_request
			create l_params_data.make_empty
			from
			until
				done or has_error or is_connection_closing
			loop
				read_record
				if has_error then
						-- Stop
				elseif last_record_request_id = fcgi_null_request_id then
					process_management_record
				elseif request_id = 0 then
					if last_record_type = fcgi_begin_request and last_record_content_length >= 8 then
						request_id := last_record_request_id
						role := content_buffer.read_natural_16_be (0).to_integer_32
						is_keep_connection := content_buffer.read_natural_8 (2).to_integer_32.bit_and (fcgi_keep_conn) /= 0
						if role /= fcgi_responder then
								-- Only the Responder role is supported.
							put_end_request (request_id, 0, fcgi_unknown_role)
							is_connection_closing := not is_keep_connection
							request_id := 0
						end
					else
							-- Ignore record related to a terminated request (late FCGI_ABORT_REQUEST, ...).
					end
				elseif last_record_request_id /= request_id then
						-- This implementation does not multiplex requests on the same connection.
					if last_record_type = fcgi_begin_request then
						put_end_request (last_record_request_id, 0, fcgi_cant_mpx_conn)
					end
				elseif last_record_type = fcgi_params then
					if last_record_content_length = 0 then
						decode_name_value_pairs (l_params_data, params)
						Result := True
						done := True
					else
						append_content_to (l_params_data)
					end
				elseif last_record_type = fcgi_stdin then
						-- Stdin data received before the end of params, keep it.
					if last_record_content_length = 0 then
						is_stdin_ended := True
					else
						append_content_to (stdin_buffer)
					end
				elseif last_record_type = fcgi_abort_request then
					put_end_request (request_id, 0, fcgi_request_complete)
					is_connection_closing := not is_keep_connection
					request_id := 0
					l_params_data.wipe_out
				else
						-- Ignore
				end
			end
		ensure
			has_request: Result implies has_request
		end

	finish_request (a_app_status: INTEGER)
			-- Complete the current request with application status `a_app_status'.
		local
			l_id: INTEGER
		do
			l_id := request_id
			if l_id /= 0 then
					-- Consume remaining stdin data, so that the connection can be reused.
				from
				until
					is_stdin_ended or has_error
				loop
					fetch_stdin
				end
				stdin_buffer.wipe_out
				stdin_index := 1

				if not is_aborted then
					put_record (fcgi_stdout, l_id, Void, 0, 0)
					if has_stderr then
						put_record (fcgi_stderr, l_id, Void, 0, 0)
					end
				end
				put_end_request (l_id, a_app_status, fcgi_request_complete)
				request_id := 0
				if not is_keep_connection then
					is_connection_closing := True
				end
			end
		ensure
			no_request: not has_request
		end

feature -- Input

	read_stdin (nb: INTEGER; a_target: STRING_8)
			-- Append at most `nb' bytes from FCGI_STDIN to `a_target'.
			-- Nothing is appended if `end_of_stdin'.
		require
			has_request: has_request
			nb_positive: nb > 0
		local
			n: INTEGER
		do
			if not has_pending_stdin and not is_stdin_ended then
				fetch_stdin
			end
			n := (stdin_buffer.count - stdin_index + 1).min (nb)
			if n > 0 then
				a_target.append_substring (stdin_buffer, stdin_index, stdin_index + n - 1)
				stdin_index := stdin_index + n
			end
		end

feature -- Output

	put_stdout (s: READABLE_STRING_8)
			-- Send `s' on FCGI_STDOUT stream.
		require
			has_request: has_request
		do
			put_stream (fcgi_stdout, s)
		end

	put_stderr (s: READABLE_STRING_8)
			-- Send `s' on FCGI_STDERR stream.
		require
			has_request: has_request
		do
			if not s.is_empty then
				has_stderr := True
				put_stream (fcgi_stderr, s)
			end
		end

feature -- Element change

	close
			-- Close the connection.
		do
			is_connection_closing := True
			if not socket.is_closed then
				socket.close
			end
		end

feature {NONE} -- Request

	reset_request
			-- Reset data related to the request.
		do
			request_id := 0
			role := 0
			is_keep_connection := False
			is_aborted := False
			is_stdin_ended := False
			has_stderr := False
			create params.make_equal (32)
			stdin_buffer.wipe_out
			stdin_index := 1
		end

	has_stderr: BOOLEAN
			-- Was any data sent to FCGI_STDERR for the current request?

	has_pending_stdin: BOOLEAN
			-- Is there stdin data received, but not yet read?
		do
			Result := stdin_index <= stdin_buffer.count
		end

	fetch_stdin
			-- Read records until new stdin data is available, or end of stdin.
		local
			done: BOOLEAN
		do
			stdin_buffer.wipe_out
			stdin_index := 1
			from
			until
				done or is_stdin_ended
			loop
				read_record
				if has_error then
					is_stdin_ended := True
				elseif last_record_request_id = fcgi_null_request_id then
					process_management_record
				elseif last_record_request_id /= request_id then
					if last_record_type = fcgi_begin_request then
						put_end_request (last_record_request_id, 0, fcgi_cant_mpx_conn)
					end
				elseif last_record_type = fcgi_stdin then
					if last_record_content_length = 0 then
						is_stdin_ended := True
					else
						append_content_to (stdin_buffer)
						done := True
					end
				elseif last_record_type = fcgi_abort_request then
					is_aborted := True
					is_stdin_ended := True
				else
						-- Ignore (FCGI_DATA is only for the Filter role).
				end
			end
		end

feature {NONE} -- Management records

	process_management_record
			-- Process management record (request id = 0).
		local
			q: STRING_TABLE [READABLE_STRING_8]
			s: STRING_8
		do
			if last_record_type = fcgi_get_values then
				create s.make_empty
				append_content_to (s)
				create q.make_equal (3)
				decode_name_value_pairs (s, q)
				create s.make_empty
				if q.has (fcgi_max_conns) then
					append_name_value_pair (fcgi_max_conns, max_connections.out, s)
				end
				if q.has (fcgi_max_reqs) then
					append_name_value_pair (fcgi_max_reqs, max_connections.out, s)
				end
				if q.has (fcgi_mpxs_conns) then
					append_name_value_pair (fcgi_mpxs_conns, "0", s)
				end
				put_record (fcgi_get_values_result, fcgi_null_request_id, s, 1, s.count)
			else
				create s.make_filled ('%U', 8)
				s [1] := last_record_type.to_character_8
				put_record (fcgi_unknown_type, fcgi_null_request_id, s, 1, s.count)
			end
		end

feature {NONE} -- Record reading

	last_record_type: INTEGER
			-- Type of the last record read.

	last_record_request_id: INTEGER
			-- Request id of the last record read.

	last_record_content_length: INTEGER
			-- Content length of the last record read.
			-- The content is available in `content_buffer'.

	read_record
			-- Read next record from `socket'.
		local
			s: like socket
			n, l_padding: INTEGER
		do
			last_record_type := 0
			last_record_request_id := 0
			last_record_content_length := 0
			s := socket
			if s.is_closed or else not s.readable then
				report_error ("Socket not readable")
			else
				s.read_to_managed_pointer_noexception (header_buffer, 0, fcgi_header_length)
				if s.bytes_read /= fcgi_header_length then
					report_error ("Connection closed")
				elseif header_buffer.read_natural_8 (0) /= fcgi_version_1 then
					report_error ("Unsupported FastCGI version")
				else
					last_record_type := header_buffer.read_natural_8 (1).to_integer_32
					last_record_request_id := header_buffer.read_natural_16_be (2).to_integer_32
					n := header_buffer.read_natural_16_be (4).to_integer_32
					l_padding := header_buffer.read_natural_8 (6).to_integer_32
					last_record_content_length := n
					if n + l_padding > 0 then
						s.read_to_managed_pointer_noexception (content_buffer, 0, n + l_padding)
						if s.bytes_read /= n + l_padding then
							last_record_content_length := 0
							report_error ("Truncated FastCGI record")
						end
					end
				end
			end
		end

	append_content_to (a_target: STRING_8)
			-- Append content of last record to `a_target'.
		local
			n, k: INTEGER
		do
			k := last_record_content_length
			if k > 0 then
				n := a_target.count
				a_target.grow (n + k)
				a_target.set_count (n + k)
				content_buffer.read_into_special_character_8 (a_target.area, 0, n, k)
			end
		end

feature {NONE} -- Record writing

	put_stream (a_type: INTEGER; s: READABLE_STRING_8)
			-- Send `s' as one or more records of stream type `a_type'.
		local
			i, n, k: INTEGER
		do
			from
				i := 1
				n := s.count
			until
				i > n or has_error
			loop
				k := (n - i + 1).min (fcgi_max_content_length)
				put_record (a_type, request_id, s, i, k)
				i := i + k
			end
		end

	put_end_request (a_request_id, a_app_status, a_protocol_status: INTEGER)
			-- Send FCGI_END_REQUEST record.
		local
			buf: like output_buffer
		do
			buf := output_buffer
			put_header (buf, fcgi_end_request, a_request_id, 8)
			buf.put_integer_32_be (a_app_status, fcgi_header_length)
			buf.put_natural_8 (a_protocol_status.to_natural_8, fcgi_header_length + 4)
			buf.put_natural_8 (0, fcgi_header_length + 5)
			buf.put_natural_8 (0, fcgi_header_length + 6)
			buf.put_natural_8 (0, fcgi_header_length + 7)
			send (buf, fcgi_header_length + 8)
		end

	put_record (a_type, a_request_id: INTEGER; s: detachable READABLE_STRING_8; a_start, a_count: INTEGER)
			-- Send record of type `a_type' with content `s [a_start, a_start + a_count - 1]'.
		require
			count_valid: 0 <= a_count and a_count <= fcgi_max_content_length
			s_valid: a_count > 0 implies (s /= Void and then a_start + a_count - 1 <= s.count)
		local
			buf: like output_buffer
			i: INTEGER
		do
			buf := output_buffer
			put_header (buf, a_type, a_request_id, a_count)
			if a_count > 0 then
				if attached {STRING_8} s as s8 then
					buf.put_special_character_8 (s8.area, a_start - 1, fcgi_header_length, a_count)
				elseif s /= Void then
					from
						i := 0
					until
						i = a_count
					loop
						buf.put_character (s [a_start + i], fcgi_header_length + i)
						i := i + 1
					end
				end
			end
			send (buf, fcgi_header_length + a_count)
		end

	put_header (buf: like output_buffer; a_type, a_request_id, a_content_length: INTEGER)
			-- Write record header into `buf'.
		do
			buf.put_natural_8 (fcgi_version_1, 0)
			buf.put_natural_8 (a_type.to_natural_8, 1)
			buf.put_natural_16_be (a_request_id.to_natural_16, 2)
			buf.put_natural_16_be (a_content_length.to_natural_16, 4)
			buf.put_natural_8 (0, 6) -- padding length
			buf.put_natural_8 (0, 7) -- reserved
		end

	send (buf: like output_buffer; nb: INTEGER)
			-- Send `nb' first bytes of `buf'.
		local
			s: like socket
		do
			s := socket
			if has_error then
					-- Skip
			elseif s.is_closed or else not s.extendible then
				report_error ("Socket not writable")
			else
				s.put_managed_pointer_noexception (buf, 0, nb)
				if s.bytes_sent /= nb then
					report_error ("Failed to send FastCGI record")
				end
			end
		end

feature {NONE} -- Name-Value pairs

	decode_name_value_pairs (a_data: READABLE_STRING_8; a_table: STRING_TABLE [READABLE_STRING_8])
			-- Decode FastCGI name-value pairs from `a_data' into `a_table'.
		local
			i, n: INTEGER
			l_name_size, l_value_size: INTEGER
			l_name_len, l_value_len: INTEGER
			l_malformed: BOOLEAN
		do
			from
				i := 1
				n := a_data.count
			until
				i > n or l_malformed
			loop
				l_name_size := encoded_length_size (a_data, i)
				l_value_size := encoded_length_size (a_data, i + l_name_size)
				if i + l_name_size + l_value_size - 1 > n then
					l_malformed := True
				else
					l_name_len := decoded_length (a_data, i)
					i := i + l_name_size
					l_value_len := decoded_length (a_data, i)
					i := i + l_value_size
					if i + l_name_len + l_value_len - 1 > n then
						l_malformed := True
					else
						a_table.force (a_data.substring (i + l_name_len, i + l_name_len + l_value_len - 1), a_data.substring (i, i + l_name_len - 1))
						i := i + l_name_len + l_value_len
					end
				end
			end
		end

	encoded_length_size (s: READABLE_STRING_8; i: INTEGER): INTEGER
			-- Number of bytes used to encode the length at position `i' in `s'.
		do
			if i <= s.count and then s [i].code >= 0x80 then
				Result := 4
			else
				Result := 1
			end
		end

	decoded_length (s: READABLE_STRING_8; i: INTEGER): INTEGER
			-- Length encoded at position `i' in `s'.
		require
			valid_index: i + encoded_length_size (s, i) - 1 <= s.count
		local
			c: INTEGER
		do
			c := s [i].code
			if c < 0x80 then
				Result := c
			else
				Result := c.bit_and (0x7F).bit_shift_left (24)
						.bit_or (s [i + 1].code.bit_shift_left (16))
						.bit_or (s [i + 2].code.bit_shift_left (8))
						.bit_or (s [i + 3].code)
			end
		end

	append_name_value_pair (a_name, a_value: READABLE_STRING_8; a_target: STRING_8)
			-- Append encoded name-value pair `a_name=a_value' to `a_target'.
		do
			append_encoded_length (a_name.count, a_target)
			append_encoded_length (a_value.count, a_target)
			a_target.append (a_name)
			a_target.append (a_value)
		end

	append_encoded_length (n: INTEGER; a_target: STRING_8)
			-- Append encoded length `n' to `a_target'.
		do
			if n < 0x80 then
				a_target.append_character (n.to_character_8)
			else
				a_target.append_character (n.bit_shift_right (24).bit_and (0x7F).bit_or (0x80).to_character_8)
				a_target.append_character (n.bit_shift_right (16).bit_and (0xFF).to_character_8)
				a_target.append_character (n.bit_shift_right (8).bit_and (0xFF).to_character_8)
				a_target.append_character (n.bit_and (0xFF).to_character_8)
			end
		end

feature {NONE} -- Implementation

	header_buffer: MANAGED_POINTER
			-- Buffer for record header.

	content_buffer: MANAGED_POINTER
			-- Buffer for record content and padding.

	output_buffer: MANAGED_POINTER
			-- Buffer for outgoing records.

	stdin_buffer: STRING_8
			-- Stdin data received, but not yet read from `stdin_index'.

	stdin_index: INTEGER
			-- Index of next character to read in `stdin_buffer'.

	report_error (m: READABLE_STRING_8)
			-- Report error `m'.
		do
			has_error := True
			if error_message = Void then
				create error_message.make_from_string (m)
			end
		end

invariant
	stdin_index_valid: stdin_index >= 1

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
