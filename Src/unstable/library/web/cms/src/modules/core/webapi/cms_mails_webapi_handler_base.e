note
	description: "Shared routines for CMS mails WebAPI handlers."
	date: "$Date$"
	revision: "$Revision$"

class
	CMS_MAILS_WEBAPI_HANDLER_BASE

inherit
	CMS_WEBAPI_HANDLER

create
	make

feature -- Execution

	execute_get_mails (a_to_user: detachable CMS_USER; req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Return a list of emails, optionally filtered to `a_to_user'.
		local
			rep: like new_response
			l_offset, l_count: INTEGER
			l_mails: detachable LIST [CMS_EMAIL]
			arr: JSON_ARRAY
			l_params: like query_offset_and_count
		do
			if can_view_mails (a_to_user) then
				rep := new_response (req, res)
				l_params := query_offset_and_count (req)
				l_offset := l_params.offset
				l_count := l_params.size
				l_mails := api.storage.mails_to (a_to_user, l_offset, l_count)
				if attached {CMS_DATA_LIST [CMS_EMAIL]} l_mails as l_data_mails then
					rep.add_integer_64_field ("total_count", l_data_mails.total_count)
				end
				rep.add_integer_64_field ("offset", l_offset)
				rep.add_integer_64_field ("count", l_count)
				if l_mails /= Void then
					create arr.make (l_mails.count)
					across
						l_mails as m
					loop
						if attached {CMS_EMAIL} m as e then
							arr.extend (email_to_json (e))
						end
					end
					add_json_to_response (rep, "mails", arr)
					rep.add_integer_64_field ("mails_returned", l_mails.count)
				else
					create arr.make (0)
					add_json_to_response (rep, "mails", arr)
					rep.add_integer_64_field ("mails_returned", 0)
				end
				rep.add_self (req.percent_encoded_path_info)
			else
				rep := new_access_denied_error_response (Void, req, res)
			end
			rep.execute
		end

	execute_post_mail (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Send email using JSON payload from `req'.
		local
			rep: like new_response
			l_parsed: like email_from_json_object
			l_group_parsed: like emails_from_to_group_json_object
			l_email: detachable CMS_EMAIL
			l_emails: detachable ARRAYED_LIST [CMS_EMAIL]
			arr: JSON_ARRAY
			err: detachable READABLE_STRING_32
		do
			if api.has_permission ({CMS_CORE_MODULE_WEBAPI}.perm_send_mails) then
				if attached {JSON_OBJECT} api.json_value_from_request (req) as jobj then
					if jobj.has_key ("to-group") then
						l_group_parsed := emails_from_to_group_json_object (jobj)
						l_emails := l_group_parsed.emails
						err := l_group_parsed.error
						if l_emails /= Void and err = Void then
							across
								l_emails as m
							loop
								if err = Void and then attached {CMS_EMAIL} m as e then
									api.process_email (e)
									if api.has_error then
										err := {STRING_32} "Could not send email"
										l_emails := Void
									end
								end
							end
						end
					else
						l_parsed := email_from_json_object (jobj)
						l_email := l_parsed.email
						err := l_parsed.error
						if l_email /= Void and err = Void then
							api.process_email (l_email)
							if api.has_error then
								err := {STRING_32} "Could not send email"
								l_email := Void
							end
						end
					end
				else
					err := {STRING_32} "Invalid or missing JSON payload"
				end
				if attached l_emails as l_sent_emails then
					rep := new_response (req, res)
					rep.add_string_field ("status", "sent")
					rep.add_integer_64_field ("mails_sent", l_sent_emails.count)
					create arr.make (l_sent_emails.count)
					across
						l_sent_emails as m
					loop
						if attached {CMS_EMAIL} m as e then
							arr.extend (email_to_json (e))
						end
					end
					add_json_to_response (rep, "mails", arr)
				elseif l_email = Void or else err /= Void then
					rep := new_error_response (err, req, res)
				else
					rep := new_response (req, res)
					rep.add_string_field ("status", "sent")
					if attached l_email.id as l_id then
						rep.add_string_field ("id", l_id)
					end
					add_json_to_response (rep, "mail", email_to_json (l_email))
				end
				rep.add_self (req.percent_encoded_path_info)
			else
				rep := new_access_denied_error_response (Void, req, res)
			end
			rep.execute
		end

feature {NONE} -- Security

	can_view_mails (a_to_user: detachable CMS_USER): BOOLEAN
			-- Is current user allowed to view mails for `a_to_user'?
		do
			if api.has_permission ({CMS_CORE_MODULE_WEBAPI}.perm_view_mails) then
				Result := True
			elseif
				a_to_user /= Void and then
				attached api.user as u and then
				u.same_as (a_to_user)
			then
				Result := True
			else
				Result := False
			end
		end

feature {NONE} -- Request parsing

	query_offset_and_count (req: WSF_REQUEST): TUPLE [offset: INTEGER; size: INTEGER]
			-- Extract `offset' and `count' query parameters from `req'.
		local
			l_offset, l_count: INTEGER
		do
			l_offset := 0
			l_count := default_mails_count
			if attached {WSF_STRING} req.query_parameter ("offset") as p_offset and then p_offset.is_integer then
				l_offset := p_offset.integer_value
			end
			if attached {WSF_STRING} req.query_parameter ("count") as p_count and then p_count.is_integer then
				l_count := p_count.integer_value
			end
			Result := [l_offset, l_count]
		end

	emails_from_to_group_json_object (jobj: JSON_OBJECT): TUPLE [emails: detachable ARRAYED_LIST [CMS_EMAIL]; error: detachable READABLE_STRING_32]
			-- Build one {CMS_EMAIL} per recipient from `to-group' in `jobj'.
		local
			l_emails: ARRAYED_LIST [CMS_EMAIL]
			l_resolved: like resolved_address
			l_parsed: like build_email_for_recipient
			err: STRING_32
		do
			create err.make_empty
			create l_emails.make (5)
			if attached jobj.array_item ("to-group") as j_group then
				if j_group.is_empty then
					err.append ({STRING_32} "Empty %"to-group%" field!%N")
				else
					across
						j_group as jv
					loop
						l_resolved := resolved_address (jv)
						if attached l_resolved.address as l_to_address then
							l_parsed := build_email_for_recipient (jobj, l_to_address, l_resolved.user)
							if attached l_parsed.email as l_email then
								l_emails.extend (l_email)
							elseif attached l_parsed.error as l_item_err then
								err.append_string_general (l_item_err)
							else
								err.append ({STRING_32} "Could not build email for recipient!%N")
							end
						else
							err.append ({STRING_32} "Invalid recipient in %"to-group%"!%N")
						end
					end
				end
			else
				err.append ({STRING_32} "Missing %"to-group%" field!%N")
			end
			if err.is_empty then
				Result := [l_emails, Void]
			else
				Result := [Void, err]
			end
		end

	email_from_json_object (jobj: JSON_OBJECT): TUPLE [email: detachable CMS_EMAIL; error: detachable READABLE_STRING_32]
			-- Build a {CMS_EMAIL} from WebAPI JSON object `jobj'.
		local
			l_to_resolved: like resolved_address
			err: STRING_32
		do
			create err.make_empty
			l_to_resolved := [Void, Void]
			if jobj.has_key ("to-group") then
				err.append ({STRING_32} "Use %"to-group%" only without %"to%" field!%N")
			elseif attached jobj.item ("to") as j_to then
				l_to_resolved := resolved_address (j_to)
				if l_to_resolved.address = Void then
					err.append ("Invalid or missing %"to%" address!%N")
				end
			else
				err.append ("Missing %"to%" field!%N")
			end
			if err.is_empty and then attached l_to_resolved.address as l_to_address then
				Result := build_email_for_recipient (jobj, l_to_address, l_to_resolved.user)
			else
				Result := [Void, err]
			end
		end

	build_email_for_recipient (jobj: JSON_OBJECT; a_to_address: READABLE_STRING_8; a_to_user: detachable CMS_USER): TUPLE [email: detachable CMS_EMAIL; error: detachable READABLE_STRING_32]
			-- Build a {CMS_EMAIL} for recipient `a_to_address' and `a_to_user'.
		local
			l_from_resolved: like resolved_address
			l_reply_resolved: like resolved_address
			l_subject, l_content: detachable READABLE_STRING_8
			l_rendered: like api.email_api.render_content_from_template_request
			l_target_user: detachable CMS_USER
			l_is_html: BOOLEAN
			l_email: CMS_EMAIL
			err: STRING_32
		do
			create err.make_empty
			l_target_user := a_to_user
			if l_target_user = Void then
				l_target_user := api.user_api.user_by_email (a_to_address)
			end
			if attached jobj.string_item ("subject") as j_subject then
				l_subject := api.email_api.render_plain_content (j_subject.unescaped_string_8, Void, l_target_user, a_to_address)
			end
			if attached jobj.string_item ("content") as j_content then
				l_content := api.email_api.render_plain_content (j_content.unescaped_string_8, Void, l_target_user, a_to_address)
			elseif attached jobj.object_item ("content") as j_content_obj then
				l_rendered := api.email_api.render_content_from_template_request (j_content_obj, l_target_user, a_to_address)
				l_content := l_rendered.content
				if l_subject = Void then
					l_subject := l_rendered.subject
				end
				if attached l_rendered.error as l_render_err then
					err.append_string_general (l_render_err)
				end
				if l_content = Void and err.is_empty then
					err.append ({STRING_32} "Could not render email template content!%N")
				end
			else
				err.append ({STRING_32} "Missing content field!%N")
			end
			if l_subject = Void then
				err.append ("Missing %"subject%" field!%N")
			end
			if
				err.is_empty and then
				l_subject /= Void and
				l_content /= Void
			then
				l_is_html := False
				if attached jobj.boolean_item ("is_html") as j_is_html then
					l_is_html := j_is_html.item
				end
				if l_is_html then
					l_email := api.new_html_email (a_to_address, l_subject, l_content)
				else
					l_email := api.new_email (a_to_address, l_subject, l_content)
				end
				if attached jobj.item ("from") as j_from then
					l_from_resolved := resolved_address (j_from)
					if attached l_from_resolved.address as l_from_address then
						l_email.set_from_address (l_from_address)
						if attached l_from_resolved.user as l_from_user then
							l_email.set_from_user (l_from_user)
						end
					else
						err.append ("Invalid %"from%" address!%N")
					end
				end
				if attached jobj.item ("reply_to") as j_reply_to then
					l_reply_resolved := resolved_address (j_reply_to)
					if attached l_reply_resolved.address as l_reply_to then
						l_email.set_reply_to_address (l_reply_to)
					else
						err.append ("Invalid %"reply_to%" address!%N")
					end
				end
				if l_target_user /= Void then
					l_email.set_to_user (l_target_user)
				end
				if err.is_empty then
					add_cc_addresses_from_json (jobj, l_email)
					add_bcc_addresses_from_json (jobj, l_email)
					add_header_lines_from_json_array (jobj, l_email)
					Result := [l_email, Void]
				else
					Result := [Void, err]
				end
			else
				if err.is_empty then
					Result := [Void, {STRING_32} "Invalid email request"]
				else
					Result := [Void, err]
				end
			end
		end

	add_json_to_response (rep: HM_WEBAPI_RESPONSE; a_name: READABLE_STRING_GENERAL; a_json_value: detachable JSON_VALUE)
			-- Add JSON value `a_json_value' to `rep' as field `a_name'.
		do
			if attached {JSON_WEBAPI_RESPONSE} rep as json_rep then
				json_rep.add_json_field (a_name, a_json_value)
			end
		end

	add_cc_addresses_from_json (jobj: JSON_OBJECT; a_email: CMS_EMAIL)
			-- Add CC addresses from JSON payload.
		local
			l_resolved: like resolved_address
		do
			if attached jobj.array_item ("cc") as jarr then
				across
					jarr as jv
				loop
					l_resolved := resolved_address (jv)
					if attached l_resolved.address as l_address then
						a_email.add_cc_address (l_address)
					end
				end
			end
		end

	add_bcc_addresses_from_json (jobj: JSON_OBJECT; a_email: CMS_EMAIL)
			-- Add BCC addresses from JSON payload.
		local
			l_resolved: like resolved_address
		do
			if attached jobj.array_item ("bcc") as jarr then
				across
					jarr as jv
				loop
					l_resolved := resolved_address (jv)
					if attached l_resolved.address as l_address then
						a_email.add_bcc_address (l_address)
					end
				end
			end
		end

	add_header_lines_from_json_array (jobj: JSON_OBJECT; a_email: CMS_EMAIL)
			-- Add additional header lines from JSON payload.
		do
			if attached jobj.array_item ("additional_header_lines") as jarr then
				across
					jarr as jv
				loop
					if attached {JSON_STRING} jv as js then
						a_email.add_header_line (js.unescaped_string_8)
					end
				end
			end
		end

	resolved_address (jv: JSON_VALUE): TUPLE [address: detachable READABLE_STRING_8; user: detachable CMS_USER]
			-- Resolve an email address or user id from JSON value `jv'.
		local
			l_uid: INTEGER_64
			l_user: detachable CMS_USER
			l_address: detachable READABLE_STRING_8
		do
			if attached {JSON_NUMBER} jv as num then
				if num.is_integer then
					if num.is_integer_64 then
						l_uid := num.integer_64_item
					else
						l_uid := num.integer_32_item
					end
					l_user := api.user_api.user_by_id (l_uid)
				end
			elseif attached {JSON_STRING} jv as js then
				if js.unescaped_string_8.is_integer_64 then
					l_uid := js.unescaped_string_8.to_integer_64
					l_user := api.user_api.user_by_id (l_uid)
				else
					l_address := js.unescaped_string_8
					if not l_address.has ('@') then
						l_user := api.user_api.user_by_id_or_name (l_address)
						l_address := Void
					else
						l_user := api.user_api.user_by_email (l_address)
					end
				end
			end
			if l_user /= Void then
				l_address := api.user_api.user_email (l_user)
			end
			Result := [l_address, l_user]
		end

	email_to_json (e: CMS_EMAIL): JSON_OBJECT
			-- JSON representation of email `e'.
		do
			if attached {CMS_CORE_STORAGE_SQL_I} api.storage as l_core_sql then
				Result := l_core_sql.mail_to_json (e)
			else
				create Result.make_empty
				Result.put_string (e.subject, "subject")
				Result.put_string (e.from_address, "from_address")
				Result.put_string (e.content, "content")
			end
		end

feature -- Constants

	default_mails_count: INTEGER = 25

note
	copyright: "2011-2026, Jocelyn Fiat, Javier Velilla, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
end
