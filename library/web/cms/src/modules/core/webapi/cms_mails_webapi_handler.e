note
	description: "WebAPI handler for /mails/ resource."
	date: "$Date$"
	revision: "$Revision$"

class
	CMS_MAILS_WEBAPI_HANDLER

inherit
	CMS_MAILS_WEBAPI_HANDLER_BASE

	WSF_URI_HANDLER

create
	make

feature -- Execution

	execute (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Execute handler for `req' and respond in `res'.
		do
			if req.is_get_request_method then
				execute_get_mails (Void, req, res)
			elseif req.is_post_request_method then
				execute_post_mail (req, res)
			else
				new_bad_request_error_response (Void, req, res).execute
			end
		end

note
	copyright: "2011-2026, Jocelyn Fiat, Javier Velilla, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
end
