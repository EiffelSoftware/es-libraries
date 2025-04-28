note
	description: "CORS filter"
	date: "$Date$"
	revision: "$Revision$"

class
	CMS_CORS_FILTER

inherit
	WSF_FILTER

feature -- Basic operations

	execute (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Execute the filter.
		local
			l_header: HTTP_HEADER
		do
			create l_header.make
--			l_header.put_header_key_value ("Access-Control-Allow-Origin", "localhost")
--			l_header.put_access_control_allow_all_origin
			l_header.put_access_control_allow_headers ("*")
			l_header.put_access_control_allow_methods (<<"*">>)
			l_header.put_access_control_allow_credentials (True)

			res.put_header_lines (l_header)
			execute_next (req, res)
		end
end
