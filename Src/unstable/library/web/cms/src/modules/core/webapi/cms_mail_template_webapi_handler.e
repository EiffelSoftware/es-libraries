note
	description: "WebAPI handler for /mails/template/{tpl_name}/ resource."
	date: "$Date$"
	revision: "$Revision$"

class
	CMS_MAIL_TEMPLATE_WEBAPI_HANDLER

inherit
	CMS_MAILS_WEBAPI_HANDLER_BASE

	WSF_URI_TEMPLATE_HANDLER

create
	make

feature -- Execution

	execute (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Execute handler for `req' and respond in `res'.
		local
			l_tpl_name: READABLE_STRING_GENERAL
		do
			if attached {WSF_STRING} req.path_parameter ("tpl_name") as p_tpl_name then
				l_tpl_name := p_tpl_name.value
				if req.is_get_request_method then
					execute_get_template (l_tpl_name, req, res)
				elseif req.is_put_request_method then
					execute_put_template (l_tpl_name, req, res)
				else
					new_bad_request_error_response (Void, req, res).execute
				end
			else
				new_bad_request_error_response ("Missing {tpl_name} parameter", req, res).execute
			end
		end

	execute_get_template (a_tpl_name: READABLE_STRING_GENERAL; req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Show email template `a_tpl_name'.
		local
			rep: like new_response
			l_template: detachable CMS_EMAIL_TEMPLATE
		do
			if api.has_permission ({CMS_CORE_MODULE_WEBAPI}.perm_view_mails) then
				l_template := api.email_api.email_template (a_tpl_name)
				if l_template /= Void then
					rep := new_response (req, res)
					add_json_to_response (rep, "template", api.email_api.template_to_json_object (l_template))
					rep.add_self (req.percent_encoded_path_info)
				else
					rep := new_not_found_error_response ("Template not found", req, res)
				end
			else
				rep := new_access_denied_error_response (Void, req, res)
			end
			rep.execute
		end

	execute_put_template (a_tpl_name: READABLE_STRING_GENERAL; req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Update email template `a_tpl_name'.
		local
			rep: like new_response
			l_template: detachable CMS_EMAIL_TEMPLATE
			l_parsed: like api.email_api.template_from_json_object
			err: detachable READABLE_STRING_32
		do
			if api.has_permission ({CMS_CORE_MODULE_WEBAPI}.perm_manage_mail_templates) then
				if attached {JSON_OBJECT} api.json_value_from_request (req) as jobj then
					l_parsed := api.email_api.template_from_json_object (jobj, a_tpl_name)
					l_template := l_parsed.template
					err := l_parsed.error
					if l_template /= Void and err = Void then
						if not api.email_api.update_email_template (l_template) then
							err := {STRING_32} "Could not update email template"
							l_template := Void
						end
					end
				else
					err := {STRING_32} "Invalid or missing JSON payload"
				end
				if l_template = Void or else err /= Void then
					rep := new_error_response (err, req, res)
				else
					rep := new_response (req, res)
					add_json_to_response (rep, "template", api.email_api.template_to_json_object (l_template))
				end
				rep.add_self (req.percent_encoded_path_info)
			else
				rep := new_access_denied_error_response (Void, req, res)
			end
			rep.execute
		end

note
	copyright: "2011-2026, Jocelyn Fiat, Javier Velilla, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
end
