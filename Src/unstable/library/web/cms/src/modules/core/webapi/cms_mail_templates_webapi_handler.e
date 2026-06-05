note
	description: "WebAPI handler for /mails/templates/ resource."
	date: "$Date$"
	revision: "$Revision$"

class
	CMS_MAIL_TEMPLATES_WEBAPI_HANDLER

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
				execute_get_templates (req, res)
			elseif req.is_post_request_method then
				execute_post_template (req, res)
			else
				new_bad_request_error_response (Void, req, res).execute
			end
		end

	execute_get_templates (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- List existing email templates.
		local
			rep: like new_response
			arr: JSON_ARRAY
		do
			if api.has_permission ({CMS_CORE_MODULE_WEBAPI}.perm_view_mails) then
				rep := new_response (req, res)
				create arr.make (api.email_api.email_templates.count)
				across
					api.email_api.email_templates as tpl
				loop
					arr.extend (api.email_api.template_to_json_object (tpl))
				end
				add_json_to_response (rep, "templates", arr)
				rep.add_integer_64_field ("templates_count", arr.count)
				rep.add_self (req.percent_encoded_path_info)
			else
				rep := new_access_denied_error_response (Void, req, res)
			end
			rep.execute
		end

	execute_post_template (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Create a new email template.
		local
			rep: like new_response
			l_template: detachable CMS_EMAIL_TEMPLATE
			l_parsed: like api.email_api.template_from_json_object
			err: detachable READABLE_STRING_32
		do
			if api.has_permission ({CMS_CORE_MODULE_WEBAPI}.perm_manage_mail_templates) then
				if attached {JSON_OBJECT} api.json_value_from_request (req) as jobj then
					l_parsed := api.email_api.template_from_json_object (jobj, Void)
					l_template := l_parsed.template
					err := l_parsed.error
					if l_template /= Void and err = Void then
						if not api.email_api.save_email_template (l_template) then
							err := {STRING_32} "Could not save email template"
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
