note
	description: "Interface for accessing API key from the database."
	date: "$Date$"
	revision: "$Revision$"

class
	API_KEY_AUTH_STORAGE_SQL

inherit
	API_KEY_AUTH_STORAGE_I
		redefine
			update_user_token_last_used
		end

	CMS_PROXY_STORAGE_SQL

	CMS_STORAGE_SQL_I

create
	make

feature -- Access/token

	token (a_key_id: READABLE_STRING_GENERAL): detachable API_KEY_AUTH_TOKEN
			-- Token record for key `a_key_id`.
		local
			l_parameters: STRING_TABLE [detachable ANY]
		do
			reset_error
			create l_parameters.make (1)
			l_parameters.put (a_key_id, "key_id")
			sql_query (sql_select_user_for_token, l_parameters)
			sql_start
			if not has_error  and not sql_after then
				Result := next_token
				sql_finalize_query (sql_select_user_for_token)
				if
					not has_error and then
					Result /= Void and then
					attached api as l_cms_api and then
					Result.user.id > 0
				then
					if attached l_cms_api.user_api.user_by_id (Result.user.id) as u then
						Result.set_user (u)
					else
						check known_user: False end
							-- Clean invalid entry!
						discard_uid_token (Result.user.id, Result.key_id)
					end
				end
			else
				sql_finalize_query (sql_select_user_for_token)
			end
		end

	next_token: detachable API_KEY_AUTH_TOKEN
		local
			l_uid: like {CMS_USER}.id
			l_user: detachable CMS_USER
			l_key_id,
			l_key_hash: READABLE_STRING_8

		do
			l_uid := sql_read_integer_64 (1)
			create {CMS_PARTIAL_USER} l_user.make_with_id (l_uid)
			l_key_id := sql_read_string_8 (3)
			l_key_hash := sql_read_string_8 (4)
			if l_key_id /= Void and l_key_hash /= Void then
				create Result.make (l_user, l_key_id, l_key_hash)
				if attached sql_read_string_32 (2) as l_name then
					Result.set_name (l_name)
				end
				if attached sql_read_date_time (5) as dt then
					Result.set_creation_date (dt)
				end
				if attached sql_read_date_time (6) as dt then
					Result.set_last_used_date (dt)
				end
				if attached sql_read_date_time (7) as dt then
					Result.set_expiration_date (dt)
				end
				if attached sql_read_string_8 (8) as st then
					{API_KEY_AUTH_API}.set_key_status_from_string (st, Result)
				end
				if attached sql_read_string_8 (9) as l_scopes_csv then
					Result.set_scopes_from_csv (l_scopes_csv)
				end
				if attached sql_read_string_8 (10) as d then
					Result.set_data (d)
				end
			end
		end

	user_tokens (a_user: CMS_USER): detachable LIST [API_KEY_AUTH_TOKEN]
			-- Tokens associated with `a_user`.
		local
			l_parameters: STRING_TABLE [detachable ANY]
			l_tokens: ARRAYED_LIST [API_KEY_AUTH_TOKEN]
			tok: API_KEY_AUTH_TOKEN
		do
			reset_error
			create l_parameters.make (1)
			l_parameters.put (a_user.id, "uid")
			sql_query (sql_select_user_tokens, l_parameters)
			if not has_error then
				create l_tokens.make (0)
				from
					sql_start
				until
					sql_after or has_error
				loop
					tok := next_token
					if tok /= Void then
						l_tokens.force (tok)
					end
					sql_forth
				end
			end
			sql_finalize_query (sql_select_user_tokens)
			if
				not has_error and
				l_tokens /= Void
			then
				Result := l_tokens
			end
		end

feature -- Change/token

	record_user_token (a_token: API_KEY_AUTH_TOKEN)
			-- Record `a_token`.
		local
			l_parameters: STRING_TABLE [detachable ANY]
		do
			create l_parameters.make (10)
			l_parameters.put (a_token.user.id, "uid")
			l_parameters.put (a_token.name, "name")
			l_parameters.put (a_token.key_id, "key_id")
			l_parameters.put (a_token.key, "key_hash")
			l_parameters.put (a_token.creation_date, "created_at")
			l_parameters.put (a_token.last_used_date, "used_at")
			l_parameters.put (a_token.expiration_date, "expires_at")
			l_parameters.put ({API_KEY_AUTH_API}.key_status_as_string (a_token), "status")
			l_parameters.put (a_token.scopes_as_csv, "scopes")
			l_parameters.put (a_token.data, "data")

			reset_error
			sql_insert (sql_insert_user_token, l_parameters)
			sql_finalize_insert (sql_insert_user_token)
		end

	update_user_token (a_token: API_KEY_AUTH_TOKEN)
			-- Update `a_token` auth information.
		local
			l_parameters: STRING_TABLE [detachable ANY]
		do
			create l_parameters.make (2)
			l_parameters.put (a_token.name, "name")
			l_parameters.put (a_token.key_id, "key_id")
			l_parameters.put (a_token.expiration_date, "expires_at")
			l_parameters.put ({API_KEY_AUTH_API}.key_status_as_string (a_token), "status")
			l_parameters.put (a_token.scopes_as_csv, "scopes")
			l_parameters.put (a_token.data, "data")
			reset_error
			sql_insert (sql_update_user_token, l_parameters)
			sql_finalize_insert (sql_update_user_token)
		end

	update_user_token_last_used (a_token: API_KEY_AUTH_TOKEN; a_dt: DATE_TIME)
			-- Update `a_token` last used date
		local
			l_parameters: STRING_TABLE [detachable ANY]
		do
			a_token.set_last_used_date (a_dt)
			create l_parameters.make (2)
			l_parameters.put (a_token.key_id, "key_id")
			l_parameters.put (a_dt, "used_at")
			reset_error
			sql_insert (sql_update_user_token_last_used, l_parameters)
			sql_finalize_insert (sql_update_user_token_last_used)
		end

	discard_user_token (a_user: CMS_USER; a_key_id: READABLE_STRING_GENERAL)
			-- Discard `a_token` from `a_user`.
		do
			discard_uid_token (a_user.id, a_key_id)
		end

	discard_all_user_tokens (a_user: CMS_USER)
			-- Discard all tokens for `a_user`.
			-- Discard `a_token` from `a_uid`.
		local
			l_parameters: STRING_TABLE [detachable ANY]
		do
			create l_parameters.make (1)
			l_parameters.put (a_user.id, "uid")

			reset_error
			sql_delete (sql_delete_all_user_tokens, l_parameters)
			sql_finalize_delete (sql_delete_all_user_tokens)
		end

	discard_uid_token (a_uid: INTEGER_64; a_key_id: READABLE_STRING_GENERAL)
			-- Discard token identified by `a_key_id` from `a_uid`.
		local
			l_parameters: STRING_TABLE [detachable ANY]
		do
			create l_parameters.make (2)
			l_parameters.put (a_uid, "uid")
			l_parameters.put (a_key_id, "key_id")

			reset_error
			sql_delete (sql_delete_user_token, l_parameters)
			sql_finalize_delete (sql_delete_user_token)
		end

	discard_expired_or_revoked_tokens (dt: DATE_TIME; a_discarded_count: detachable CELL [INTEGER])
		local
			l_parameters: STRING_TABLE [detachable ANY]
			tok: API_KEY_AUTH_TOKEN
			l_tokens: ARRAYED_LIST [API_KEY_AUTH_TOKEN]
		do
			reset_error
			create l_parameters.make (0)
			sql_query (sql_select_tokens, l_parameters)
			if not has_error then
				create l_tokens.make (0)
				from
					sql_start
				until
					sql_after or has_error
				loop
					tok := next_token
					if
						tok /= Void and then
						(
							tok.is_expired (dt)
							or tok.is_revoked
						)
					then
						l_tokens.force (tok)
					end
					sql_forth
				end
			end
			sql_finalize_query (sql_select_tokens)
			if l_tokens /= Void and then not l_tokens.is_empty then
				across
					l_tokens as t
				loop
					discard_user_token (t.user, t.key_id)
				end
				if a_discarded_count /= Void then
					a_discarded_count.replace (l_tokens.count)
				end
			end
		end

feature {NONE} -- Queries/token

	sql_select_user_for_token: STRING = "SELECT uid, name, key_id, key_hash, created_at, used_at, expires_at, status, scopes, data FROM api_key_auth WHERE key_id=:key_id;"

	sql_select_user_tokens: STRING = "SELECT uid, name, key_id, key_hash, created_at, used_at, expires_at, status, scopes, data FROM api_key_auth WHERE uid=:uid ORDER by created_at DESC, used_at DESC ;"

	sql_select_tokens: STRING = "SELECT uid, name, key_id, key_hash, created_at, used_at, expires_at, status, scopes, data FROM api_key_auth ORDER by created_at DESC, used_at DESC ;"

	sql_insert_user_token: STRING = "INSERT INTO api_key_auth (uid, name, key_id, key_hash, created_at, used_at, expires_at, status, scopes, data) VALUES (:uid, :name, :key_id, :key_hash, :created_at, :used_at, :expires_at, :status, :scopes, :data);"

	sql_update_user_token: STRING = "UPDATE api_key_auth SET name=:name, expires_at=:expires_at, status=:status, scopes=:scopes, data=:data WHERE key_id=:key_id ;"

	sql_update_user_token_last_used: STRING = "UPDATE api_key_auth SET used_at=:used_at WHERE key_id=:key_id ;"

	sql_delete_user_token: STRING = "DELETE FROM api_key_auth WHERE uid=:uid AND key_id=:key_id;"

	sql_delete_all_user_tokens: STRING = "DELETE FROM api_key_auth WHERE uid=:uid;"


note
	copyright: "2011-2017, Jocelyn Fiat, Javier Velilla, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
end
