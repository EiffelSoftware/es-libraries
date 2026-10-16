note
	description: "[
			Output stream for the FastCGI connector: content sent on FCGI_STDOUT stream,
			and errors sent on FCGI_STDERR stream.

			The response uses the CGI format, i.e the status is sent as "Status:" header.
		]"
	date: "$Date$"
	revision: "$Revision$"

class
	WGI_FCGI_OUTPUT_STREAM

inherit
	WGI_OUTPUT_STREAM

	WGI_ERROR_STREAM

	HTTP_STATUS_CODE_MESSAGES
		export
			{NONE} all
		end

create
	make

feature {NONE} -- Initialization

	make (a_connection: like connection)
		do
			connection := a_connection
			create buffer.make (buffer_capacity)
		end

feature -- Status report

	is_open_write: BOOLEAN
			-- Can items be written to output stream?
		do
			Result := connection.has_request
		end

	is_available: BOOLEAN
			-- <Precursor>
		do
			Result := not connection.has_error and not connection.is_aborted
		end

feature -- Status writing

	put_status_line (a_code: INTEGER; a_reason_phrase: detachable READABLE_STRING_8)
			-- <Precursor>
		local
			s: STRING
			m: detachable READABLE_STRING_8
		do
			create s.make (16)
			s.append ("Status: ")
			s.append_integer (a_code)
			m := a_reason_phrase
			if m = Void then
				m := http_status_code_message (a_code)
			end
			if m /= Void then
				s.append_character (' ')
				s.append_string (m)
			end
			put_header_line (s)
		end

feature -- Output

	put_string (s: READABLE_STRING_8)
			-- Send `s' to http client.
		do
			if buffer.count + s.count <= buffer_capacity then
				buffer.append (s)
			else
				flush
				if s.count <= buffer_capacity then
					buffer.append (s)
				else
					connection.put_stdout (s)
				end
			end
		end

	put_character (c: CHARACTER_8)
			-- Send `c' to http client.
		do
			if buffer.count >= buffer_capacity then
				flush
			end
			buffer.append_character (c)
		end

feature -- Basic operations

	flush
			-- Send buffered data.
		do
			if not buffer.is_empty then
				if connection.has_request then
					connection.put_stdout (buffer)
				end
				buffer.wipe_out
			end
		end

feature -- Error

	put_error (a_message: READABLE_STRING_8)
			-- Send `a_message' to the web server error log (FCGI_STDERR).
		do
			if connection.has_request then
				connection.put_stderr (a_message)
			end
		end

feature {NONE} -- Implementation

	connection: WGI_FCGI_CONNECTION
			-- Associated FastCGI connection.

	buffer: STRING_8
			-- Output buffer.

	buffer_capacity: INTEGER = 16_384
			-- Capacity of `buffer'.

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
