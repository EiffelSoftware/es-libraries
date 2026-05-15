note
	description: "Summary description for {API_KEY_AUTH_TOKEN_WEBAPI_HANDLER}."
	date: "$Date$"
	revision: "$Revision$"

class
	API_KEY_AUTH_TOKEN_WEBAPI_HANDLER

inherit
	CMS_WEBAPI_HANDLER
		rename
			make as make_with_cms_api
		end

	WSF_URI_TEMPLATE_HANDLER

create
	make

feature {NONE} -- Initialization

	make (mod: API_KEY_AUTH_MODULE_WEBAPI; a_api_key_auth_api: API_KEY_AUTH_API)
		do
			module := mod
			make_with_cms_api (a_api_key_auth_api.cms_api)
			api_key_auth_api := a_api_key_auth_api
		end

feature -- API

	module: API_KEY_AUTH_MODULE_WEBAPI

	api_key_auth_api: API_KEY_AUTH_API

feature -- Execution

	execute (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Execute handler for `req' and respond in `res'.
		local
			l_uid: READABLE_STRING_GENERAL
		do
			if attached {WSF_STRING} req.path_parameter ("uid") as p_uid then
				l_uid := p_uid.value
				if attached {WSF_STRING} req.path_parameter ("key") as p_key then
					if req.is_get_request_method then
						get_api_key_details (l_uid, p_key.value, req, res)
					elseif req.is_put_request_method then
						update_api_token (l_uid, p_key.value, req, res)
					elseif req.is_delete_request_method then
						delete_api_token (l_uid, p_key.value, req, res)
					else
						new_bad_request_error_response (Void, req, res).execute
					end
				else
					if req.is_post_request_method then
						post_api_token (l_uid, req, res)
					elseif req.is_get_request_method then
						get_api_tokens (l_uid, req, res)
					else
						new_bad_request_error_response (Void, req, res).execute
					end
				end
			else
				new_bad_request_error_response ("Missing {uid} parameter", req, res).execute
			end
		end

feature -- Helper

	user_by_uid (a_uid: READABLE_STRING_GENERAL): detachable CMS_USER
		do
			Result := api.user_api.user_by_id_or_name (a_uid)
		end

feature -- Request execution		

	get_api_tokens (a_uid: READABLE_STRING_GENERAL; req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Execute handler for `req' and respond in `res'.
		local
			rep: HM_WEBAPI_RESPONSE
			tb: STRING_TABLE [detachable ANY]
			arr: ARRAYED_LIST [STRING_TABLE [detachable ANY]]
			l_scopes: detachable READABLE_STRING_GENERAL
		do
			if attached user_by_uid (a_uid) as l_user then
				if attached api.user as u then
					if u.same_as (l_user) or api.user_api.is_admin_user (u) then
						rep := new_response (req, res)
						if attached {WSF_STRING} req.query_parameter ("scopes") as p_scopes then
							l_scopes := p_scopes.value
						end

						if attached api_key_auth_api.user_tokens (l_user, l_scopes) as l_tokens and then not l_tokens.is_empty then
							create arr.make (l_tokens.count)
							across
								l_tokens as t
							loop
								create tb.make (5)
								fill_api_key_token_table (t, tb)
								arr.extend (tb)
							end
						else
							create arr.make (0)
						end
						rep.add_iterator_field ("access_tokens", arr)
						rep.add_integer_64_field ("count", arr.count)
						create tb.make_equal (3)
						tb.force (l_user.name, "name")
						tb.force (l_user.id, "uid")
						rep.add_table_iterator_field ("user", tb)

						rep.add_self (req.percent_encoded_path_info)
						add_user_links_to (l_user, rep)
					else
							-- Only admin, or current user can see its access_token!
						rep := new_access_denied_error_response (Void, req, res)
					end
				else
					rep := new_access_denied_error_response (Void, req, res)
				end
			else
				rep := new_not_found_error_response ("User not found", req, res)
			end
			rep.execute
		end

	fill_api_key_token_table (tok: API_KEY_AUTH_TOKEN; tb: STRING_TABLE [detachable ANY])
			-- Same metadata shape as each element of the `keys` array from `handle_api_keys`.
		do
			tb.force (tok.key_id, "key_id")
			if attached tok.name as n then
				tb.force (n, "name")
			end
			if tok.is_revoked then
				tb.force ("revoked", "status")
			elseif tok.is_expired (Void) then
				tb.force ("expired", "status")
			elseif tok.is_inactive then
				tb.force ("inactive", "status")
			elseif tok.is_active then
				tb.force ("active", "status")
			end
			if attached tok.creation_date as dt then
				tb.force (api.date_time_to_iso8601_string (dt), "creation_date")
			end
			if attached tok.expiration_date as dt then
				tb.force (api.date_time_to_iso8601_string (dt), "expiration_date")
			end
			if attached tok.last_used_date as dt then
				tb.force (api.date_time_to_iso8601_string (dt), "last_used_date")
			end
			if attached tok.scopes_as_csv as scv then
				tb.force (scv, "scopes")
			end
		end

	get_api_key_details (a_uid: READABLE_STRING_GENERAL; a_key_id: READABLE_STRING_GENERAL; req: WSF_REQUEST; res: WSF_RESPONSE)
		require
			req.is_get_head_request_method
		local
			tb: STRING_TABLE [detachable ANY]
			rep: like new_response
			tok: API_KEY_AUTH_TOKEN
		do
			if attached user_by_uid (a_uid) as l_user then
				if attached api.user as u then
					if u.same_as (l_user) or api.user_api.is_admin_user (u) then
						if
							a_key_id.same_string ("current") and then
							attached req.meta_string_variable ("HTTP_X_API_KEY") as p_curr_api_key and then
							attached api_key_auth_api.token_prefix_from_key (p_curr_api_key) as l_curr_key_id
						then
							tok := api_key_auth_api.token (l_curr_key_id)
						else
							tok := api_key_auth_api.token (a_key_id)
						end

						if attached tok then
							if l_user.id = tok.user.id then
								rep := new_response (req, res)
								create tb.make (5)
								fill_api_key_token_table (tok, tb)
								rep.add_table_iterator_field ("access_token", tb)
							else
								rep := new_not_found_error_response ("API key not found", req, res)
							end
						else
							rep := new_not_found_error_response ("API key not found", req, res)
						end
						create tb.make_equal (2)
						tb.force (l_user.name, "name")
						tb.force (l_user.id, "uid")
						rep.add_table_iterator_field ("user", tb)
						rep.add_self (req.percent_encoded_path_info)
						add_user_links_to (l_user, rep)
					else
						rep := new_access_denied_error_response (Void, req, res)
					end
				else
					rep := new_access_denied_error_response (Void, req, res)
				end
			else
				rep := new_not_found_error_response ("User not found", req, res)
			end
			rep.execute
		end

	post_api_token (a_uid: READABLE_STRING_GENERAL; req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Execute handler for `req' and respond in `res'.
		local
			tb: STRING_TABLE [detachable ANY]
			rep: like new_response
			l_scopes: detachable LIST [READABLE_STRING_GENERAL]
			l_name: READABLE_STRING_GENERAL
			l_changed: BOOLEAN
		do
			if attached user_by_uid (a_uid) as l_user then
				if attached api.user as u then
					if u.same_as (l_user) or api.user_api.is_admin_user (u) then
						if
							attached req.string_item ("op") as s_op and then
							s_op.is_case_insensitive_equal ("discard")
						then
							if
								attached {WSF_STRING} req.form_parameter ("token") as s_token
							then
								api_key_auth_api.discard_user_token (l_user, s_token.value)
								if attached api_key_auth_api.user_for_token (s_token.value) then
									rep := new_error_response ("Could not discard token", req, res)
								else
									rep := new_response (req, res)
								end
							else
								rep := new_error_response ("Could not discard token", req, res)
							end
						else
							l_name := Void
							l_scopes := Void
							if attached {WSF_STRING} req.form_parameter ("name") as p_name then
								l_name := p_name.value
							end
							if attached {WSF_STRING} req.form_parameter ("scopes") as s_scope then
								l_scopes := s_scope.value.split (',')
							end
							if attached {JSON_OBJECT} api.json_value_from_request (req) as jobj then
								if
									l_name = Void and
									attached {JSON_STRING} jobj.string_item ("name") as j_name
								then
									l_name := j_name.unescaped_string_32
								end
								if
									l_scopes = Void and
									attached jobj.item ("scopes") as j_scopes_val
								then
									if attached {JSON_STRING} j_scopes_val as j_scopes_str then
										l_scopes := j_scopes_str.unescaped_string_8.split (',')
									elseif attached {JSON_ARRAY} j_scopes_val as j_scopes_arr then
										create {ARRAYED_LIST [READABLE_STRING_GENERAL]} l_scopes.make (j_scopes_arr.count)
										across
											j_scopes_arr as j_scope
										loop
											if attached {JSON_STRING} j_scope as js then
												l_scopes.force (js.unescaped_string_32)
											end
										end
									end
								end
							end
							if attached api_key_auth_api.new_token (l_user, l_scopes) as l_new_token then
								if l_name /= Void then
									l_new_token.token.set_name (l_name)
									l_changed := True
								end
								if l_changed then
									api_key_auth_api.update_user_token (l_new_token.token)
								end
								rep := new_response (req, res)
								if attached l_new_token.secret as sec then
									rep.add_string_field ("secret", sec)
								end
								rep.add_string_field ("key_id", l_new_token.token.key_id)
								if attached l_new_token.token.name as n then
									rep.add_string_field ("name", n)
								end
							else
								rep := new_error_response ("Could not create new token", req, res)
							end
						end
						create tb.make_equal (2)
						tb.force (l_user.name, "name")
						tb.force (l_user.id, "uid")
						rep.add_table_iterator_field ("user", tb)
						rep.add_self (req.percent_encoded_path_info)
						add_user_links_to (l_user, rep)
					else
							-- Only admin, or current user can create the user access_token!
						rep := new_access_denied_error_response (Void, req, res)
					end
				else
					rep := new_access_denied_error_response (Void, req, res)
				end
			else
				rep := new_not_found_error_response ("User not found", req, res)
			end
			rep.execute
		end

	update_api_token (a_uid: READABLE_STRING_GENERAL; a_key: READABLE_STRING_GENERAL; req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Update token `a_key` for user `a_uid`, or replace it with a new key when query `op=rotate` (see `API_KEY_AUTH_API.rotation_user_token`).
		require
			req.is_put_request_method
		local
			tb: STRING_TABLE [detachable ANY]
			rep: like new_response
			l_scopes: detachable LIST [READABLE_STRING_GENERAL]
			l_changed: BOOLEAN
			l_name: READABLE_STRING_GENERAL
			l_rot: detachable like api_key_auth_api.new_token
		do
			if attached user_by_uid (a_uid) as l_user then
				if attached api.user as u then
					if u.same_as (l_user) or api.user_api.is_admin_user (u) then
						if attached api_key_auth_api.token (a_key) as tok then
							if l_user.id = tok.user.id then
								if
									attached {WSF_STRING} req.query_parameter ("op") as p_op and then
									p_op.value.is_case_insensitive_equal ("rotate")
								then
									if tok.is_revoked or tok.is_expired (Void) then
										rep := new_error_response ("Cannot rotate revoked or expired API key", req, res)
									else
										l_rot := api_key_auth_api.rotation_user_token (tok)
										if l_rot = Void or else api_key_auth_api.has_error then
											rep := new_error_response ("Could not rotate API key", req, res)
										else
											l_changed := False
											if attached {WSF_STRING} req.form_parameter ("name") as p_rn then
												l_rot.token.set_name (p_rn.value)
												l_changed := True
											elseif
												attached {JSON_OBJECT} api.json_value_from_request (req) as j_rot and then
												attached {JSON_STRING} j_rot.string_item ("name") as j_rn
											then
												l_rot.token.set_name (j_rn.unescaped_string_32)
												l_changed := True
											end
											if l_changed then
												api_key_auth_api.update_user_token (l_rot.token)
											end

											rep := new_response (req, res)
											if attached l_rot.secret as l_sec then
												rep.add_string_field ("access_token", utf_8_encoded (l_sec))
											end
											rep.add_string_field ("key_id", utf_8_encoded (l_rot.token.key_id))
											if attached l_rot.token.name as n then
												rep.add_string_field ("name", n)
											end
											rep.add_string_field ("revoked_key_id", utf_8_encoded (tok.key_id))
										end
									end
								else
									if tok.is_revoked then
										rep := new_error_response ("Cannot update revoked API key", req, res)
									else
										l_changed := False
										l_name := Void
										l_scopes := Void
										if attached {WSF_STRING} req.form_parameter ("name") as p_name then
											l_name := p_name.value
										end
										if attached {WSF_STRING} req.form_parameter ("scopes") as s_scope then
											l_scopes := s_scope.value.split (',')
										end
										if attached {JSON_OBJECT} api.json_value_from_request (req) as jobj then
											if
												l_name = Void and
												attached {JSON_STRING} jobj.string_item ("name") as j_name
											then
												l_name := j_name.unescaped_string_32
											end
											if
												l_scopes = Void and
												attached jobj.item ("scopes") as j_scopes_val
											then
												if attached {JSON_STRING} j_scopes_val as j_scopes_str then
													l_scopes := j_scopes_str.unescaped_string_8.split (',')
												elseif attached {JSON_ARRAY} j_scopes_val as j_scopes_arr then
													create {ARRAYED_LIST [READABLE_STRING_GENERAL]} l_scopes.make (j_scopes_arr.count)
													across
														j_scopes_arr as j_scope
													loop
														if attached {JSON_STRING} j_scope as js then
															l_scopes.force (js.unescaped_string_32)
														end
													end
												end
											end
										end
										if attached l_name then
											tok.set_name (l_name)
											l_changed := True
										end
										if attached l_scopes then
											tok.set_scopes (l_scopes)
											l_changed := True
										end
										if l_changed then
											api_key_auth_api.update_user_token (tok)
											if api_key_auth_api.has_error then
												rep := new_error_response ("Could not update API key", req, res)
											else
												rep := new_response (req, res)
											end
										else
											rep := new_error_response ("Missing name or scopes to update", req, res)
										end
									end
								end
							else
								rep := new_not_found_error_response ("API key not found", req, res)
							end
						else
							rep := new_not_found_error_response ("API key not found", req, res)
						end
						create tb.make_equal (2)
						tb.force (l_user.name, "name")
						tb.force (l_user.id, "uid")
						rep.add_table_iterator_field ("user", tb)
						rep.add_self (req.percent_encoded_path_info)
						add_user_links_to (l_user, rep)
					else
						rep := new_access_denied_error_response (Void, req, res)
					end
				else
					rep := new_access_denied_error_response (Void, req, res)
				end
			else
				rep := new_not_found_error_response ("User not found", req, res)
			end
			rep.execute
		end

	delete_api_token (a_uid: READABLE_STRING_GENERAL; a_key: READABLE_STRING_GENERAL; req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Remove token `a_key` for user `a_uid`.
		require
			req.is_delete_request_method
		local
			tb: STRING_TABLE [detachable ANY]
			rep: like new_response
		do
			if attached user_by_uid (a_uid) as l_user then
				if attached api.user as u then
					if u.same_as (l_user) or api.user_api.is_admin_user (u) then
						if attached api_key_auth_api.token (a_key) as tok then
							if l_user.id = tok.user.id then
								api_key_auth_api.discard_user_token (l_user, tok.key_id)
								if api_key_auth_api.has_error then
									rep := new_error_response ("Could not delete API key", req, res)
								else
									rep := new_response (req, res)
								end
							else
								rep := new_not_found_error_response ("API key not found", req, res)
							end
						else
							rep := new_not_found_error_response ("API key not found", req, res)
						end
						create tb.make_equal (2)
						tb.force (l_user.name, "name")
						tb.force (l_user.id, "uid")
						rep.add_table_iterator_field ("user", tb)
						rep.add_self (req.percent_encoded_path_info)
						add_user_links_to (l_user, rep)
					else
						rep := new_access_denied_error_response (Void, req, res)
					end
				else
					rep := new_access_denied_error_response (Void, req, res)
				end
			else
				rep := new_not_found_error_response ("User not found", req, res)
			end
			rep.execute
		end


note
	copyright: "2011-2017, Jocelyn Fiat, Javier Velilla, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
end

