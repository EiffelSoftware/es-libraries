note
	description: "Summary description for {API_KEY_AUTH_TOKEN_USER_HANDLER}."
	date: "$Date$"
	revision: "$Revision$"

class
	API_KEY_AUTH_TOKEN_USER_HANDLER

inherit
	CMS_HANDLER
		rename
			make as make_with_cms_api
		end

	WSF_URI_TEMPLATE_HANDLER

create
	make

feature {NONE} -- Initialization

	make (a_api_key_auth_api: API_KEY_AUTH_API; a_module: API_KEY_AUTH_MODULE)
		do
			make_with_cms_api (a_api_key_auth_api.cms_api)
			module := a_module
			api_key_auth_api := a_api_key_auth_api
		end

feature -- API

	api_key_auth_api: API_KEY_AUTH_API

	module: API_KEY_AUTH_MODULE

feature -- Execution

	execute (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Execute handler for `req' and respond in `res'.
		do
			if attached {WSF_STRING} req.path_parameter ("uid") as p_uid then
				if attached user_by_uid (p_uid.value) as l_user then
					if attached api.user as u then
						if u.same_as (l_user) or api.user_api.is_admin_user (u) then
							if attached {WSF_STRING} req.path_parameter ("keyid") as p_keyid then
								if attached api_key_auth_api.token (p_keyid.value) as tok then
									handle_api_token (u, l_user, tok, req, res)
								else
									send_not_found_with_message ("API key not found", req, res)
								end
							else
								if req.is_get_request_method then
									get_api_tokens (u, l_user, req, res)
								elseif req.is_post_request_method then
									post_api_token (u, l_user, req, res)
								else
									send_bad_request (req, res)
								end
							end

						else
								-- Only admin, or current user can see its access_token!
							send_access_denied (req, res)
						end
					else
						send_custom_access_denied ("Please authenticate first", Void, req, res)
					end
				else
					send_not_found_with_message ("User not found", req, res)
				end
			else
				send_bad_request (req, res)
			end
		end

feature -- Helper

	user_by_uid (a_uid: READABLE_STRING_GENERAL): detachable CMS_USER
		do
			Result := api.user_api.user_by_id_or_name (a_uid)
		end

feature -- Request execution

	handle_api_token (u: CMS_USER; a_token_user: CMS_USER; a_token: API_KEY_AUTH_TOKEN; req: WSF_REQUEST; res: WSF_RESPONSE)
		local
			rep: like new_generic_response
			s: STRING_8
			l_display_token: API_KEY_AUTH_TOKEN
			l_display_secret: detachable READABLE_STRING_8
			l_rot: detachable like api_key_auth_api.new_token
		do
			create s.make_empty
			rep := new_generic_response (req, res)
			if req.is_post_request_method then
				if attached req.form_parameter ("op") as p_op then
					if p_op.same_string (but_delete_text) then
						delete_token (a_token_user, a_token, rep, api.parent_location_of (rep.location))
					elseif a_token.is_revoked then
						rep.add_error_message ("API key is revoked ...")
					else
						if p_op.same_string (but_update_text) then
							update_token (a_token_user, a_token, rep, Void)
						elseif p_op.same_string (but_disable_text) then
							disable_token (a_token_user, a_token, rep, Void)
						elseif p_op.same_string (but_enable_text) then
							enable_token (a_token_user, a_token, rep, Void)
						elseif p_op.same_string (but_revoke_text) then
							revoke_token (a_token_user, a_token, rep, Void)
						elseif p_op.same_string (but_rotate_text) then
							l_rot := rotate_token (a_token_user, a_token, rep, Void)
						else
							rep.add_error_message ("Unsupported operation " + html_encoded (p_op.string_representation))
						end
					end
				else
					rep.add_error_message ("Bad request ...")
				end
			end
			l_display_token := a_token
			l_display_secret := Void
			if attached l_rot as r then
				l_display_token := r.token
				l_display_secret := r.secret
			end
			add_token_to_body (l_display_token, l_display_secret, s, l_display_token.is_revoked, rep)
			rep.set_main_content (s)

			rep.add_to_primary_tabs (api.local_link ("API keys", api.parent_location_of (rep.location)))
			rep.add_style (rep.module_resource_url (module, "/files/css/style.css", Void), Void)
			rep.execute
		end

	get_api_tokens (u: CMS_USER; a_token_user: CMS_USER; req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Execute handler for `req' and respond in `res'.
		local

			rep: CMS_RESPONSE
			fset: WSF_FORM_FIELD_SET
			ftxt: WSF_FORM_TEXT_INPUT
			fexp: WSF_FORM_DATE_INPUT
			sub: WSF_FORM_SUBMIT_INPUT
			l_form: CMS_FORM
			s: STRING
			l_now: DATE_TIME
			lst: LIST [API_KEY_AUTH_TOKEN]
			l_tokens_to_clean: INTEGER
			fcb: WSF_FORM_CHECKBOX_INPUT
		do
			rep := new_generic_response (req, res)
			rep.set_title ("API keys")
			create s.make_empty

			create l_now.make_now_utc

			lst := api_key_auth_api.user_tokens (a_token_user, Void)
			if lst /= Void and then not lst.is_empty then
				across
					lst as inf
				loop
					if inf.is_revoked or inf.is_expired (l_now) then
						l_tokens_to_clean := l_tokens_to_clean + 1
					end
				end
			end
			if lst /= Void and then not lst.is_empty then
				if l_tokens_to_clean > 0 then

					create l_form.make (req.percent_encoded_path_info, "user-api-tokens")
					l_form.set_method_post
					create fset.make
					l_form.extend (fset)
					create sub.make_with_text ("op", but_clean_text)
					fset.extend (sub)

					fset.extend_html_text ("<p>Clean all "+ l_tokens_to_clean.out + " expired or revoked api key(s) for user " +  html_encoded (api.user_display_name (a_token_user)) + " .</p>")
					l_form.append_to_html (rep.wsf_theme, s)
					l_form.append_html_attributes_to ("<br/>")
				end

				across
					lst as inf
				loop
					if inf.is_expired (l_now) then
						s.append ("<div>Expired API key ")
						if attached inf.name as l_name then
							s.append ("%"" + html_encoded (l_name) + "%"")
						end
						s.append (html_encoded (inf.key_id) + "</div>%N")
					else
						add_token_to_body (inf, Void, s, True, rep)
					end
				end
			end

				-- Create new token
			create l_form.make (req.percent_encoded_path_info, "user-api-tokens")
			l_form.set_method_post
			create fset.make
			fset.set_legend ("Operations")
			fset.add_css_style ("background-color: #ff830038")
			l_form.extend (fset)

			fset.extend_html_text ("<p>Create a new API key for user " +  html_encoded (api.user_display_name (a_token_user)) + " .</p>")

			create ftxt.make_with_text ("name", "")
			ftxt.set_placeholder ("Optional name")
			fset.extend (ftxt)

			create fexp.make ("expiration_date")
			fexp.set_label ("Expiration date (optional)")
			fexp.set_description ("Leave empty to use the default expiration from configuration. The key expires at the end of the selected day (UTC).")
			fset.extend (fexp)

			if attached api_key_auth_api.scopes_declarations as l_scopes_decl then
				fset.extend_html_text ("<strong>Scopes:</strong>")
				across
					l_scopes_decl as sco
				loop
					create fcb.make_with_value ("scopes", html_encoded (sco))
					fcb.set_checked (True)
					fcb.set_title (html_encoded (sco))
					fset.extend (fcb)
				end
			end

			create sub.make_with_text ("op", but_create_new_token_text)
			fset.extend (sub)

			l_form.append_to_html (rep.wsf_theme, s)

			rep.set_main_content (s)
			rep.add_to_primary_tabs (api.local_link ("API keys", rep.location))
			rep.add_style (rep.module_resource_url (module, "/files/css/style.css", Void), Void)
			rep.execute
		end

	add_token_to_body (a_token: API_KEY_AUTH_TOKEN; a_secret: detachable READABLE_STRING_8; a_body: STRING_8; a_is_view_only: BOOLEAN; rep: like new_generic_response)
		local
			f: WSF_FORM_COMPOSITE
			fset: WSF_FORM_FIELD_SET
			tf: WSF_FORM_TEXT_INPUT
			l_form: CMS_FORM
			hdiv,fdiv: WSF_FORM_DIV
			h: STRING_8
			l_legend: STRING_8
			fcb: WSF_FORM_CHECKBOX_INPUT
		do
			create l_form.make (rep.request.percent_encoded_path_info, "user-api-tokens")
			l_form.set_method_post

			if a_is_view_only then
				create fset.make
				if a_secret = Void then
					l_legend := "API key"
				else
					l_legend := "New API key"
				end
				if attached a_token.name as l_tok_name then
					l_legend.append (": ")
					l_legend.append (html_encoded (l_tok_name))
				end
				fset.set_legend (l_legend)
				l_form.extend (fset)
				f := fset
			else
				create fdiv.make
				create h.make_from_string ("<h1>")

				if a_secret = Void then
					h.append("API key")
				else
					h.append("New API key")
				end
				if attached a_token.name as l_tok_name then
					h.append (": ")
					h.append (html_encoded (l_tok_name))
				end
				h.append ("</h1>%N")
				fdiv.extend_html_text (h)
				l_form.extend (fdiv)
				f := fdiv
			end

			if a_is_view_only then
				if attached a_token.name as l_name then
					f.extend_html_text ("<div><strong>Name:</strong> " + html_encoded (l_name) + "</div>" )
				end
				f.extend_html_text ("<div><strong>Key:</strong> <a href=%"" + api.joined_paths (<<rep.request.percent_encoded_path_info, url_encoded (a_token.key_id)>>) + "%">" + html_encoded (a_token.key_id) + "...</a></div>" )
			else
				if attached a_token.name as l_name then
					create tf.make_with_text ("name", l_name)
				else
					create tf.make ("name")
				end
				tf.set_placeholder ("Name of the key")
				tf.set_label ("Name")
				tf.set_size (30)
				f.extend (tf)

				f.extend_html_text ("<div><strong>Key:</strong> " + html_encoded (a_token.key_id) + "...</div>" )
			end
			f.extend_hidden_input ("token", a_token.key_id)

			if attached a_secret then
				create tf.make_with_text ("secret", a_secret)
				tf.set_is_readonly (True)
				tf.set_label ("Secret")
				tf.set_size (80)
				tf.set_description ("Please copy and keep this secret secured (it will be displayed ONLY ONCE).")
				f.extend (tf)

				f.extend_html_text ("[
					Set the ${secret} in X-API-KEY http header
				]")
			end

			create hdiv.make
			hdiv.add_css_class ("horizontal")

			f.extend_html_text ("<div><strong>Status:</strong> " + {API_KEY_AUTH_API}.key_status_as_string (a_token) + "</div>%N")

			f.extend_html_text ("<div><strong>Creation date:</strong> ")
			if attached a_token.creation_date as dt then
				f.extend_html_text (api.date_time_to_string (dt))
			else
				f.extend_html_text ("--")
			end
			f.extend_html_text ("</div>%N")

			f.extend_html_text ("<div><strong>Expiration date:</strong> ")
			if attached a_token.expiration_date as dt then
				f.extend_html_text (api.date_time_to_string (dt))
			else
				f.extend_html_text ("--")
			end
			f.extend_html_text ("</div>%N")

			f.extend_html_text ("<div><strong>Last used:</strong> ")
			if attached a_token.last_used_date as dt then
				f.extend_html_text (api.date_time_to_string (dt))
			else
				f.extend_html_text ("--")
			end
			f.extend_html_text ("</div>%N")


			if a_is_view_only then
				hdiv.extend (create {WSF_FORM_SUBMIT_INPUT}.make_with_text ("op", but_edit_text))
--				if a_token.is_revoked then
--					hdiv.extend (create {WSF_FORM_SUBMIT_INPUT}.make_with_text ("op", but_delete_text))
--				end
			else
				if
					attached a_token.scopes as l_scopes and then
					attached api_key_auth_api.scopes_declarations as l_scopes_decl
				then
					f.extend_html_text ("<div><strong>Scopes:</strong>")
					across
						l_scopes_decl as decl
					loop
						create fcb.make_with_value ("scopes", decl)
						if across l_scopes as sco some decl.is_case_insensitive_equal_general (sco) end then
							fcb.set_checked (True)
						end
						fcb.set_title (html_encoded (decl))
						f.extend (fcb)
					end
				end
				hdiv.extend (create {WSF_FORM_SUBMIT_INPUT}.make_with_text ("op", but_update_text))
			end
			hdiv.extend (create {WSF_FORM_SUBMIT_INPUT}.make_with_text ("op", but_delete_text))

			if a_token.is_revoked then
				do_nothing
			else
				if a_token.is_active then
					hdiv.extend (create {WSF_FORM_SUBMIT_INPUT}.make_with_text ("op", but_disable_text))
				elseif a_token.is_inactive then
					hdiv.extend (create {WSF_FORM_SUBMIT_INPUT}.make_with_text ("op", but_enable_text))
				end
				hdiv.extend (create {WSF_FORM_SUBMIT_INPUT}.make_with_text ("op", but_revoke_text))
				if not a_token.is_expired (Void) then
					hdiv.extend (create {WSF_FORM_SUBMIT_INPUT}.make_with_text ("op", but_rotate_text))
				end

			end
			f.extend (hdiv)

			a_body.append ("<div class=%"api-token "+ {API_KEY_AUTH_API}.key_status_as_string (a_token))
			if a_secret /= Void then
				a_body.append (" secret")
			end
			a_body.append ("%">")
			l_form.append_to_html (rep.wsf_theme, a_body)
			l_form.append_html_attributes_to ("<br/>")
			a_body.append ("</div>")
		end

	but_revoke_text: STRING = "Revoke"
	but_delete_text: STRING = "Delete"
	but_enable_text: STRING = "Enable"
	but_disable_text: STRING = "Disable"
	but_edit_text: STRING = "Edit"
	but_update_text: STRING = "Update"
	but_clean_text: STRING = "Clean revoked or expired"
	but_create_new_token_text: STRING = "Create API key"
	but_rotate_text: STRING = "Rotate"

	post_api_token (u: CMS_USER; a_token_user: CMS_USER; req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Execute handler for `req' and respond in `res'.
		local
			tok: API_KEY_AUTH_TOKEN
			l_tok_and_secret: like api_key_auth_api.new_token
			rep: CMS_RESPONSE
			l_api_tokens_local_link: CMS_LOCAL_LINK
			s: STRING_8
			l_scopes: ARRAYED_LIST [READABLE_STRING_8]
			l_rot: detachable like api_key_auth_api.new_token
		do
			if attached req.form_parameter ("op") as p_op then
				rep := new_generic_response (req, res)
				l_api_tokens_local_link := api.local_link ("API keys", rep.location)
				if
					attached {WSF_STRING} req.form_parameter ("token") as p_token and then
					attached p_token.value as l_key_id
				then
					if attached api_key_auth_api.token (l_key_id) as l_api_token then
						if p_op.same_string (but_delete_text) then
							delete_token (a_token_user, l_api_token, rep, req.percent_encoded_path_info)
						elseif p_op.same_string (but_revoke_text) then
							revoke_token (a_token_user, l_api_token, rep, req.percent_encoded_path_info)
						elseif p_op.same_string (but_disable_text) then
							disable_token (a_token_user, l_api_token, rep, req.percent_encoded_path_info)
						elseif p_op.same_string (but_enable_text) then
							enable_token (a_token_user, l_api_token, rep, req.percent_encoded_path_info)
						elseif p_op.same_string (but_update_text) then
							update_token (a_token_user, l_api_token, rep, req.percent_encoded_path_info)
						elseif p_op.same_string (but_rotate_text) then
							l_rot := rotate_token (a_token_user, l_api_token, rep, Void)
							if attached l_rot as r then
								create s.make_empty
								add_token_to_body (r.token, r.secret, s, True, rep)
								rep.set_main_content (s)
							end
						elseif p_op.same_string (but_edit_text) then
							rep.set_redirection (api.joined_paths (<<req.percent_encoded_path_info, url_encoded (l_key_id)>>))
						else
							rep := Void
							send_bad_request (req, res)
						end
					else
						rep.add_error_message ("API key not found.")
					end
				elseif p_op.same_string (but_clean_text) then
					api_key_auth_api.discard_expired_or_revoked_user_tokens (a_token_user, Void)
					if api_key_auth_api.has_error then
						rep.add_error_message ("Error when trying to clean all revoked, and expired API keys !")
					else
						rep.add_success_message ("All revoked or expired API keys discarded.")
						rep.set_redirection (req.percent_encoded_path_info)
					end
				elseif p_op.same_string (but_create_new_token_text) then
					if attached req.form_parameter ("scopes") as p_scopes then
						create l_scopes.make (1)
						if attached {WSF_MULTIPLE_STRING} p_scopes as p_scopes_list then
							across
								p_scopes_list.values as sco
							loop
								l_scopes.extend (utf_8_encoded (sco.value))
							end
						elseif attached {WSF_STRING} p_scopes as p_scope then
							l_scopes.extend (utf_8_encoded (p_scope.value))
						end
					else
						l_scopes := Void
					end
					l_tok_and_secret := new_token_from_form (a_token_user, l_scopes, req, rep)
					if attached l_tok_and_secret then
						tok := l_tok_and_secret.token
						if attached {WSF_STRING} req.form_parameter ("name") as p_name then
							tok.set_name (p_name.value)
						end
						api_key_auth_api.update_user_token (tok)

						rep.add_success_message ("New API key created")
						create s.make_empty
						add_token_to_body (tok, l_tok_and_secret.secret, s, True, rep)
						rep.set_main_content (s)

						rep.theme.append_cms_link_to_html (rep.local_link ("See all API keys", rep.location), Void, s)
--									rep.set_redirection (req.percent_encoded_path_info)
					elseif api_key_auth_api.has_error then
						rep.add_error_message ("Error when trying to create a new API key !")
					end
				else
					rep := Void
					send_bad_request (req, res)
				end
				if rep /= Void then
					rep.add_to_primary_tabs (l_api_tokens_local_link)
					rep.add_style (rep.module_resource_url (module, "/files/css/style.css", Void), Void)
					rep.execute
				end
			else
				send_bad_request (req, res)
			end
		end

	update_token (a_token_user: CMS_USER; a_api_token: API_KEY_AUTH_TOKEN; rep: like new_generic_response; a_redir_on_success: detachable READABLE_STRING_8)
		local
			l_scopes: ARRAYED_LIST [READABLE_STRING_8]
		do
			if attached {WSF_STRING} rep.request.form_parameter ("name") as p_name then
				a_api_token.set_name (p_name.value)
				if attached rep.request.form_parameter ("scopes") as p_scopes then
					create l_scopes.make (1)
					if attached {WSF_MULTIPLE_STRING} p_scopes as p_scopes_list then
						across
							p_scopes_list.values as s
						loop
							l_scopes.extend (utf_8_encoded (s.value))
						end
					elseif attached {WSF_STRING} p_scopes as p_scope then
						l_scopes.extend (utf_8_encoded (p_scope.value))
					end
				else
					l_scopes := Void
				end
				a_api_token.set_scopes (l_scopes)

				api_key_auth_api.update_user_token (a_api_token)
				if api_key_auth_api.has_error then
					rep.add_error_message ("Error when trying to rename the API key " + html_encoded (a_api_token.key_id) + " !")
				else
					rep.add_success_message ("Token is now updated.")
					if a_redir_on_success /= Void then
						rep.set_redirection (a_redir_on_success)
					end
				end
			end
		end

	delete_token (a_token_user: CMS_USER; a_api_token: API_KEY_AUTH_TOKEN; rep: like new_generic_response; a_redir_on_success: detachable READABLE_STRING_8)
		do
			api_key_auth_api.discard_user_token (a_token_user, a_api_token.key_id)
			if api_key_auth_api.has_error then
				rep.add_error_message ("Error when trying to delete API key " + html_encoded (a_api_token.key_id) + " !")
			else
				rep.add_success_message ("API key deleted.")
				if a_redir_on_success /= Void then
					rep.set_redirection (a_redir_on_success)
				end
			end
		end

	disable_token (a_token_user: CMS_USER; a_api_token: API_KEY_AUTH_TOKEN; rep: like new_generic_response; a_redir_on_success: detachable READABLE_STRING_8)
		require
			a_api_token.is_active
		do
			api_key_auth_api.disable_user_token (a_api_token)
			if api_key_auth_api.has_error then
				rep.add_error_message ("Error when trying to disable API key " + html_encoded (a_api_token.key_id) + " !")
			else
				rep.add_success_message ("API key is now inactive.")
				if a_redir_on_success /= Void then
					rep.set_redirection (a_redir_on_success)
				end
			end
		end

	enable_token (a_token_user: CMS_USER; a_api_token: API_KEY_AUTH_TOKEN; rep: like new_generic_response; a_redir_on_success: detachable READABLE_STRING_8)
		require
			a_api_token.is_inactive
		do
			api_key_auth_api.enable_user_token (a_api_token)
			if api_key_auth_api.has_error then
				rep.add_error_message ("Error when trying to enable API key " + html_encoded (a_api_token.key_id) + " !")
			else
				rep.add_success_message ("API key is now active.")
				if a_redir_on_success /= Void then
					rep.set_redirection (a_redir_on_success)
				end
			end
		end

	revoke_token (a_token_user: CMS_USER; a_api_token: API_KEY_AUTH_TOKEN; rep: like new_generic_response; a_redir_on_success: detachable READABLE_STRING_8)
		do
			api_key_auth_api.revoke_user_token (a_api_token)
			if api_key_auth_api.has_error then
				rep.add_error_message ("Error when trying to revoke API key " + html_encoded (a_api_token.key_id) + " !")
			else
				rep.add_success_message ("API key is now revoked.")
				if a_redir_on_success /= Void then
					rep.set_redirection (a_redir_on_success)
				end
			end
		end

	rotate_token (a_token_user: CMS_USER; a_api_token: API_KEY_AUTH_TOKEN; rep: like new_generic_response; a_redir_on_success: detachable READABLE_STRING_8): detachable like api_key_auth_api.new_token
			-- Replace `a_api_token` with a new key and return the one-time secret tuple.
		local
			l_rot: like api_key_auth_api.new_token
		do
			if a_api_token.is_revoked or a_api_token.is_expired (Void) then
				rep.add_error_message ("Cannot rotate revoked or expired API key.")
			else
				l_rot := api_key_auth_api.rotation_user_token (a_api_token)
				if l_rot = Void or else api_key_auth_api.has_error then
					rep.add_error_message ("Error when trying to rotate API key " + html_encoded (a_api_token.key_id) + " !")
				else
					rep.add_success_message ("API key rotated. The previous key has been revoked.")
					Result := l_rot
				end
			end
		end

	new_token_from_form (a_token_user: CMS_USER; a_scopes: detachable LIST [READABLE_STRING_8]; req: WSF_REQUEST; rep: like new_generic_response): detachable like api_key_auth_api.new_token
			-- Create a new token, optionally using `expiration_date` from `req`.
		local
			l_now: DATE_TIME
			l_exp_dt: DATE_TIME
			l_secs: INTEGER_64
		do
			if
				attached {WSF_STRING} req.form_parameter ("expiration_date") as p_exp and then
				not p_exp.value.is_whitespace
			then
				if attached date_from_form_string (p_exp.value) as l_exp_date then
					l_exp_dt := expiration_date_time_from_date (l_exp_date)
					create l_now.make_now_utc
					if l_exp_dt <= l_now then
						rep.add_error_message ("Expiration date must be in the future.")
					elseif attached l_exp_dt.relative_duration (l_now) as l_dur then
						l_secs := l_dur.seconds_count
						if l_secs <= 0 then
							rep.add_error_message ("Expiration date must be in the future.")
						else
							Result := api_key_auth_api.new_token_with_expiration (a_token_user, a_scopes, l_secs.to_natural_32)
						end
					end
				else
					rep.add_error_message ("Invalid expiration date.")
				end
			else
				Result := api_key_auth_api.new_token (a_token_user, a_scopes)
			end
		end

	date_from_form_string (s: READABLE_STRING_GENERAL): detachable DATE
			-- Parse HTML `date` value `yyyy-MM-dd`.
		do
			if s.count >= 10 then
				Result := api.date_from_yyyy_mm_dd_string (s.substring (1, 10), '-')
			end
		end

	expiration_date_time_from_date (d: DATE): DATE_TIME
			-- End of `d` in UTC, used as token expiration instant.
		local
			l_time: TIME
		do
			create l_time.make (23, 59, 59)
			create Result.make_by_date_time (d, l_time)
		end

note
	copyright: "2011-2017, Jocelyn Fiat, Javier Velilla, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
end

