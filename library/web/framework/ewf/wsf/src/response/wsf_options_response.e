note
	description: "[
			This class is used to respond a OPTIONS request
		]"
	date: "$Date$"
	revision: "$Revision$"

class
	WSF_OPTIONS_RESPONSE

inherit
	WSF_RESPONSE_MESSAGE

create
	make

feature {NONE} -- Initialization

	make (req: WSF_REQUEST)
		do
			request := req
			create header.make
		end

feature -- Header

	header: HTTP_HEADER
			-- Response' header

	request: WSF_REQUEST
			-- Associated request.

feature {WSF_RESPONSE} -- Output

	send_to (res: WSF_RESPONSE)
		local
			h: like header
		do
			res.set_status_code ({HTTP_STATUS_CODE}.ok)
			h := header
			h.put_content_length (0)
			res.put_header_text (h.string)
			res.flush
		end

note
	copyright: "2011-2025, Jocelyn Fiat, Javier Velilla, Olivier Ligot, Colin Adams, Alexander Kogtenkov, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"
end
