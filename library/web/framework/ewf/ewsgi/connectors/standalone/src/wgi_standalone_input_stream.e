note
	description: "[
			Input stream for the Standalone Web Server connector.
		]"
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date$"
	revision: "$Revision$"

class
	WGI_STANDALONE_INPUT_STREAM

inherit
	WGI_INPUT_STREAM
		redefine
			append_to_string
		end

create
	make

feature {NONE} -- Initialization

	make (a_source: like source)
		do
			create last_string.make_empty
			set_source (a_source)
		end

feature {WGI_STANDALONE_CONNECTOR, WGI_SERVICE, WGI_STANDALONE_CONNECTOR_EXPORTER} -- Standalone

	set_source (i: like source)
		do
			source := i
		end

	source: HTTPD_STREAM_SOCKET

feature {WGI_STANDALONE_CONNECTOR, WGI_HTTPD_REQUEST_HANDLER} -- Expect 100-continue

	set_continue_response_pending (a_output: like continue_response_output)
			-- The client sent "Expect: 100-continue", and waits for "100 Continue"
			-- before sending the request body.
			-- The interim response will be sent on `a_output' at the first read,
			-- unless the response was already started.
		do
			continue_response_output := a_output
			is_continue_response_pending := True
		ensure
			is_continue_response_pending: is_continue_response_pending
		end

feature -- Status report: Expect 100-continue

	is_continue_response_pending: BOOLEAN
			-- Is the "100 Continue" interim response expected by the client, and not yet sent?
			-- If True, the client may not have sent the request body.

feature {NONE} -- Expect 100-continue

	continue_response_output: detachable WGI_STANDALONE_OUTPUT_STREAM
			-- Output stream used to send the "100 Continue" interim response.

	send_continue_response_if_pending
			-- Send the "100 Continue" interim response if pending,
			-- and if the final response was not yet started.
		do
			if is_continue_response_pending then
				is_continue_response_pending := False
				if
					attached continue_response_output as o and then
					not o.has_written and then
					source.is_open_write
				then
					source.put_string_8_noexception ({HTTP_CONSTANTS}.http_version_1_1 + " 100 Continue%R%N%R%N")
				end
			end
		end

feature -- Input

	read_character
			-- Read the next character in input stream.
			-- Make the result available in `last_character'.
		local
			src: like source
		do
			send_continue_response_if_pending
			src := source
			if src.readable and not src.was_error then
				src.read_character_noexception
				last_character := src.last_character
			else
				last_character := '%U'
			end
		end

	read_string (nb: INTEGER)
			-- Read the next `nb' characters and make the result available in `last_string'.
			-- Note: a single socket read may return less than requested,
			-- so keep reading until `nb' characters are read, or the peer closed, or an error occurred.
		local
			src: like source
			l_done: BOOLEAN
		do
			send_continue_response_if_pending
			src := source
			last_string.wipe_out
			from
			until
				l_done or last_string.count >= nb or not src.readable or src.was_error
			loop
				src.read_stream_noexception ((nb - last_string.count).min (max_socket_read_size))
				if src.last_string.is_empty then
						-- Peer closed the connection, or error.
					l_done := True
				else
					last_string.append_string (src.last_string)
				end
			end
		end

	append_to_string (a_string: STRING; nb: INTEGER)
			-- <Precursor>
			-- Read by blocks, rather than character by character.
		do
			read_string (nb)
			a_string.append (last_string)
			last_appended_count := last_string.count
			last_string.wipe_out
		end

feature -- Access

	last_string: STRING_8
			-- Last string read
			-- (Note: this query *might* return the same object.
			-- Therefore a clone should be used if the result
			-- is to be kept beyond the next call to this feature.
			-- However `last_string' is not shared between input objects.)

	last_character: CHARACTER_8
			-- Last item read

feature {NONE} -- Implementation

	max_socket_read_size: INTEGER = 65_536
			-- Maximum number of bytes requested by a single socket read.

feature -- Status report

	is_open_read: BOOLEAN
			-- Can items be read from input stream?
		do
			Result := source.is_open_read
		end

	end_of_input: BOOLEAN
			-- Has the end of input stream been reached?
		do
			Result := not source.readable or source.was_error
		end

;note
	copyright: "2011-2016, Jocelyn Fiat, Javier Velilla, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"

end
