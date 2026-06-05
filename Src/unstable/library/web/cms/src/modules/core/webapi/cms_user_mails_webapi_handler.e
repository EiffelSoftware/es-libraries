note
	description: "WebAPI handler for /user/{uid}/mails/ resource."
	date: "$Date$"
	revision: "$Revision$"

class
	CMS_USER_MAILS_WEBAPI_HANDLER

inherit
	CMS_MAILS_WEBAPI_HANDLER_BASE

	WSF_URI_TEMPLATE_HANDLER

create
	make

feature -- Execution

	execute (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Execute handler for `req' and respond in `res'.
		local
			l_user: detachable CMS_USER
		do
			if req.is_get_request_method then
				if attached {WSF_STRING} req.path_parameter ("uid") as p_uid then
					l_user := api.user_api.user_by_id_or_name (p_uid.value)
					if l_user /= Void then
						execute_get_mails (l_user, req, res)
					else
						new_not_found_error_response ("User not found", req, res).execute
					end
				else
					new_bad_request_error_response ("Missing {uid} parameter", req, res).execute
				end
			else
				new_bad_request_error_response (Void, req, res).execute
			end
		end

note
	copyright: "2011-2026, Jocelyn Fiat, Javier Velilla, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
end
