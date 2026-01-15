note
	description: "Summary description for {CMS_ADMIN_MAILS_HANDLER}."
	date: "$Date$"
	revision: "$Revision$"

class
	CMS_ADMIN_MAILS_HANDLER

inherit
	CMS_HANDLER
	WSF_URI_TEMPLATE_HANDLER

create
	make

feature -- Execution

	execute (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Execute request handler
		local
			r: like new_generic_response
			l_to_user: CMS_USER
			l_offset, l_count, i: INTEGER
			s: STRING
		do
			if req.is_get_request_method then
				if api.has_permission ({CMS_ADMIN_MODULE_ADMINISTRATION}.perm_view_mails) then
					r := new_generic_response (req, res)
					if attached {WSF_STRING} req.query_parameter ("offset") as p_offset then
						l_offset := p_offset.integer_value
					end
					if attached {WSF_STRING} req.query_parameter ("count") as p_count then
						l_count := p_count.integer_value
					else
						l_count := 25
					end

					create s.make_empty
					if
						attached {WSF_STRING} req.path_parameter ("uid") as l_to_user_id
					then
						l_to_user := api.user_api.user_by_id_or_name (l_to_user_id.value)
					end
					if l_to_user /= Void then
						r.set_title ({STRING_32} "Mails sent to user " + api.real_user_display_name (l_to_user))
					else
						r.set_title ("Mails ...")
					end
					r.add_to_primary_tabs (api.administration_link ("Administration", ""))
					if attached api.storage.mails_to (l_to_user, l_offset, l_count) as l_mails then
						i := l_offset
						s.append ("<div id=%"messages%">")
						across
							l_mails as m
						loop
							i := i + 1
							if attached {CMS_EMAIL} m as e then
								append_cms_email_info_to (i, e, s)
							end
						end
						s.append ("</div>%N")
						s.append ("<div class=%"pager%">%N")
						if l_offset > 0 then
							s.append ("<a href=%""+ req.percent_encoded_path_info +"?offset="+ (l_offset - l_count).max (0).out +"&count=" + l_count.out +"%">&lt; Previous</a> ")
						end
						if not l_mails.is_empty then
							s.append ("<a href=%""+ req.percent_encoded_path_info +"?offset="+ (l_offset + l_count).out +"&count=" + l_count.out +"%">Next &gt;</a>")
						end
						s.append ("</div>%N")
					end
					r.set_main_content (s)
					r.execute
				else
					send_access_denied (req, res)
				end
			else
				send_bad_request (req, res)
			end
		end

	append_cms_email_info_to (a_index: INTEGER; e: CMS_EMAIL; a_html: STRING_8)
		local
			ft: HTML_SOURCE_CONTENT_FORMAT
			is_notif: BOOLEAN
		do
			if e.is_sent then
				a_html.append ("<div class=%"message success%">")
			else
				a_html.append ("<div class=%"message error%">")
			end
			a_html.append ("<span class=%"index%">" + a_index.out + "</span> ")
			if attached e.to_user as u then
				a_html.append (" <strong>user:</strong> ")
				if u.has_name then
					a_html.append (api.user_html_administration_link (u))
				end
			end
			a_html.append (" <span class=%"date%"><strong>date:</strong> " + api.formatted_date_time_ago (e.date))
			a_html.append (" (" + api.date_time_to_iso8601_string (e.date) + ")</span>")
			a_html.append ("<br/>")

			if not e.from_address.same_string (api.setup.site_email) then
				a_html.append (" <span class=%"address%"><strong>from:</strong> ")
				a_html.append (html_encoded (e.from_address))
				a_html.append ("</span>")
				a_html.append ("<br/>")
			end

			across
				e.to_addresses as add
			loop
				if add.has_substring (api.setup.site_notification_email) then
					is_notif := True
				else
					is_notif := False
				end
				a_html.append (" <span class=%"address ")
				if is_notif then
					a_html.append (" notification")
				end
				a_html.append ("%"><strong>to:</strong> ")
				a_html.append (html_encoded (add))
				a_html.append ("</span>")
				a_html.append ("<br/>")
			end
			if attached e.cc_addresses as l_cc_addresses then
				across
					l_cc_addresses as add
				loop
					is_notif := False
					a_html.append (" <span class=%"address%"><strong>cc:</strong> ")
					a_html.append (html_encoded (add))
					a_html.append ("</span>")
					a_html.append ("<br/>")
				end
			end
			if attached e.bcc_addresses as l_bcc_addresses then
				across
					l_bcc_addresses as add
				loop
					is_notif := False
					a_html.append (" <span class=%"address%"><strong>bcc:</strong> ")
					a_html.append (html_encoded (add))
					a_html.append ("</span>")
					a_html.append ("<br/>")
				end
			end
			a_html.append (" <strong")
			if is_notif then
				a_html.append (" class=%"notification%"")
			end
			a_html.append (">subject:</strong> " + e.subject)

			a_html.append ("<blockquote><pre>")
			create ft
			ft.append_formatted_to (e.content, a_html)
			a_html.append ("</pre></blockquote>%N")
			a_html.append ("</div>%N")
			a_html.append ("<hr/>%N")
		end

end
