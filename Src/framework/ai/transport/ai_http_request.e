note
	description: "HTTP request to a provider: method, base URL and path, headers, body (JSON, UTF-8), and whether the answer is streamed."
	date: "$Date$"
	revision: "$Revision$"

class
	AI_HTTP_REQUEST

create
	make_get,
	make_post

feature {NONE} -- Initialization

	make_get (a_base_url, a_path: READABLE_STRING_8)
			-- GET request of `a_path' at `a_base_url'.
		do
			method := "GET"
			base_url := a_base_url.to_string_8
			path := a_path.to_string_8
			create headers.make (4)
		end

	make_post (a_base_url, a_path: READABLE_STRING_8; a_body: READABLE_STRING_8; a_streamed: BOOLEAN)
			-- POST request of `a_path' at `a_base_url', with `a_body', whose answer is streamed if `a_streamed'.
		do
			method := "POST"
			base_url := a_base_url.to_string_8
			path := a_path.to_string_8
			body := a_body.to_string_8
			is_streamed := a_streamed
			create headers.make (4)
		end

feature -- Access

	method: STRING_8
			-- "GET" or "POST"

	base_url: STRING_8
			-- Scheme, host and port, e.g. "https://api.anthropic.com"

	path: STRING_8
			-- Path, e.g. "/v1/messages"

	headers: ARRAYED_LIST [TUPLE [name, value: STRING_8]]
			-- Header lines

	body: detachable STRING_8
			-- Body (JSON, UTF-8)

	url: STRING_8
			-- Full URL
		do
			Result := base_url + path
		end

	timeout: INTEGER
			-- Maximum duration of the transfer, in seconds (0: none)

feature -- Status report

	is_streamed: BOOLEAN
			-- Is the answer streamed (Server-Sent Events)?

feature -- Element change

	add_header (a_name, a_value: READABLE_STRING_8)
			-- Add header `a_name: a_value'.
		do
			headers.extend ([a_name.to_string_8, a_value.to_string_8])
		end

	set_timeout (a_seconds: INTEGER)
			-- Set `timeout' to `a_seconds'.
		require
			a_seconds_non_negative: a_seconds >= 0
		do
			timeout := a_seconds
		ensure
			timeout_set: timeout = a_seconds
		end

note
	copyright: "Copyright (c) 1984-2026, Eiffel Software"
	license: "GPL version 2 (see http://www.eiffel.com/licensing/gpl.txt)"
	licensing_options: "http://www.eiffel.com/licensing"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"

end
