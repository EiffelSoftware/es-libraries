note
	description: "WebAPI handler for /mails/templates/builtin-variables resource."
	date: "$Date$"
	revision: "$Revision$"

class
	CMS_MAIL_TEMPLATES_BUILTIN_VARIABLES_WEBAPI_HANDLER

inherit
	CMS_MAILS_WEBAPI_HANDLER_BASE

	WSF_URI_HANDLER

create
	make

feature -- Execution

	execute (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Execute handler for `req' and respond in `res'.
		local
			rep: like new_response
		do
			if req.is_get_request_method then
				if api.has_permission ({CMS_CORE_MODULE_WEBAPI}.perm_view_mails) then
					rep := new_response (req, res)
					add_json_to_response (rep, "builtin_variables", api.email_api.builtin_variables_json_array)
					rep.add_integer_64_field ("builtin_variables_count", api.email_api.known_builtin_variable_names.count)
					rep.add_self (req.percent_encoded_path_info)
				else
					rep := new_access_denied_error_response (Void, req, res)
				end
			else
				rep := new_bad_request_error_response (Void, req, res)
			end
			rep.execute
		end

note
	copyright: "2011-2026, Jocelyn Fiat, Javier Velilla, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
end
