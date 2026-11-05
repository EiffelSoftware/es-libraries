note
	description: "Input stream for the FastCGI connector: content of FCGI_STDIN stream."
	date: "$Date$"
	revision: "$Revision$"

class
	WGI_FCGI_INPUT_STREAM

inherit
	WGI_INPUT_STREAM

create
	make

feature {NONE} -- Initialization

	make (a_connection: like connection)
		do
			connection := a_connection
			create last_string.make_empty
		end

feature -- Input

	read_character
			-- Read the next character in input stream.
			-- Make the result available in `last_character'.
		do
			read_string (1)
			if last_string.count = 1 then
				last_character := last_string [1]
			else
				last_character := '%U'
			end
		end

	read_string (nb: INTEGER)
			-- Read a string of at most `nb' characters, or until end of input.
			-- Make result available in `last_string'.
		local
			conn: like connection
		do
			last_string.wipe_out
			conn := connection
			from
			until
				last_string.count = nb or conn.end_of_stdin
			loop
				conn.read_stdin (nb - last_string.count, last_string)
			end
		end

feature -- Access

	last_string: STRING_8
			-- Last string read.

	last_character: CHARACTER_8
			-- Last item read.

feature -- Status report

	is_open_read: BOOLEAN
			-- Can items be read from input stream?
		do
			Result := connection.has_request
		end

	end_of_input: BOOLEAN
			-- Has the end of input stream been reached?
		do
			Result := connection.end_of_stdin
		end

feature {NONE} -- Implementation

	connection: WGI_FCGI_CONNECTION
			-- Associated FastCGI connection.

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
