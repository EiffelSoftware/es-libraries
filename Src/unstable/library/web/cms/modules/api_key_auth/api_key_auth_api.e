note
	description: "API to handle API key authentication and management."
	date: "$Date$"
	revision: "$Revision$"

class
	API_KEY_AUTH_API

inherit
	CMS_MODULE_API
		redefine
			initialize
		end

	REFACTORING_HELPER

create
	make

feature {NONE} -- Initialization

	initialize
			-- Initialize the API key authentication module.
			-- Sets up storage based on available CMS storage type.
		do
			Precursor
					-- Storage initialization
			if attached cms_api.storage.as_sql_storage as l_storage_sql then
				create {API_KEY_AUTH_STORAGE_SQL} api_key_auth_storage.make (l_storage_sql)
			else
					-- FIXME: in case of NULL storage, should Current be disabled?
				create {API_KEY_AUTH_STORAGE_NULL} api_key_auth_storage
			end
		end

feature {CMS_MODULE} -- Access nodes storage.

	api_key_auth_storage: API_KEY_AUTH_STORAGE_I
			-- Storage interface for API key authentication data

feature -- Settings

	secret_key_prefix: STRING_8 = "sk_"
			-- Prefix used for all secret keys

feature -- Scopes collection

	scopes_declarations: API_KEY_AUTH_SCOPES_LIST
			-- List of available API key scopes
		do
			create Result.make
			cms_api.hooks.invoke_hook (agent (h: CMS_HOOK; a_scopes: API_KEY_AUTH_SCOPES_LIST)
					do
						if attached {API_KEY_AUTH_SCOPES_HOOK} h as l_hook then
							l_hook.declare_scopes (a_scopes)
						end
					end(?, Result)
				, {API_KEY_AUTH_SCOPES_HOOK})
		end

feature -- Factory

	new_token (a_user: CMS_USER; a_scopes: detachable ITERABLE [READABLE_STRING_GENERAL]): like new_token_with_expiration
			-- Token for `a_user` with specified `a_scopes`
			-- Uses default expiration time
		do
			Result := new_token_with_expiration (a_user, a_scopes, 0)
		end

	new_token_with_expiration (a_user: CMS_USER; a_scopes: detachable ITERABLE [READABLE_STRING_GENERAL]; a_expiration_in_seconds: NATURAL_32): detachable TUPLE [token: API_KEY_AUTH_TOKEN; secret: READABLE_STRING_8]
			-- Token for `a_user` with specified `a_scopes` and `a_expiration_in_seconds`
			-- If `a_expiration_in_seconds` exceeds configuration limit, uses configuration value
		require
			a_expiration_in_seconds > 0
		local
			key_id, sec: READABLE_STRING_8
			dt: DATE_TIME
			nb: INTEGER
			tok: API_KEY_AUTH_TOKEN
		do
			create dt.make_now_utc
			key_id := secret_key_prefix + cms_api.new_random_identifier (11, Void)
			create tok.make_new (a_user, key_id, dt)
			tok.set_creation_date (dt)
			if
				attached cms_api.module_configuration_by_name ({API_KEY_AUTH_MODULE}.name, "config") as cfg
			then
				nb := cfg.integer_item ("api-key.expiration") -- In Seconds
			end
			if a_expiration_in_seconds > 0 then
				if nb <= 0 or else a_expiration_in_seconds.to_integer_32 <= nb then
					nb := a_expiration_in_seconds.to_integer_32
				end
			end
			if nb < 0 then
					-- Never expires ...
			else
				create dt.make_now_utc
				if nb = 0 then
					dt.day_add (90) -- 90 days
				elseif nb > 0 then
					dt.second_add (nb)
				end
				tok.set_expiration_date (dt)
			end
			tok.set_scopes (a_scopes)
			sec := tok.secret
			if sec /= Void then
				record_user_token (tok)
				if has_error then
					tok := Void
				else
					Result := [tok, sec]
				end
			end
		end

	token_prefix_from_key (k: READABLE_STRING_GENERAL): detachable READABLE_STRING_GENERAL
		local
			i: INTEGER
		do
			if k.starts_with (secret_key_prefix) then
				i := k.index_of ('_', secret_key_prefix.count + 1)
				if i > 0 then
					Result := k.head (i - 1)
				end
			end
		end

feature -- Access

	set_current_user_token (tok: API_KEY_AUTH_TOKEN)
			-- Sets `tok` as the current user's token and updates last used timestamp
		do
			update_user_token_last_used (tok, create {DATE_TIME}.make_now_utc)
			cms_api.set_execution_variable ({API_KEY_AUTH_MODULE}.name + ".token", tok)
		end

	current_user_token: detachable API_KEY_AUTH_TOKEN
			-- Currently active token for the user
		do
			if attached {API_KEY_AUTH_TOKEN} cms_api.execution_variable ({API_KEY_AUTH_MODULE}.name + ".token") as tok then
				Result := tok
			end
		end

	user_token_for_request_api_key (a_key: READABLE_STRING_GENERAL): detachable API_KEY_AUTH_TOKEN
			-- Token associated with API key `a_key` from request header
		require
			not_blank: not a_key.is_whitespace
		local
			k: STRING_8
			k_id: STRING_8
			p: INTEGER
		do
			k := utf_8_encoded (a_key)
			if not k.starts_with_general (secret_key_prefix) then
				k := utf_8_encoded (cms_api.base64_decoded_string (k))
			end
			p := k.index_of ('_', secret_key_prefix.count + 1)
			if p > 0 then
				k_id := k.head (p - 1)
				k_id.adjust
				if attached api_key_auth_storage.token (k_id) as tok then
					if
						tok.is_active and then
						tok.is_valid_hashed_key (k)
					then
						Result := tok
					else
						-- TODO: Remove expired or bad token ...
					end
				end
			end
		end

	user_for_token (a_key_id: READABLE_STRING_GENERAL): detachable CMS_USER
			-- User associated with token identified by `a_key_id`
		require
			not_blank: not a_key_id.is_whitespace
		do
			if attached api_key_auth_storage.token (a_key_id) as tok then
				if
					tok.is_active
				then
					Result := tok.user
				else
						-- Remove expired or bad token ...
					discard_user_token (tok.user, a_key_id)
				end
			end
		end

	user_tokens (a_user: CMS_USER; a_scope: detachable READABLE_STRING_GENERAL): detachable LIST [API_KEY_AUTH_TOKEN]
			-- List of tokens for `a_user`, optionally filtered by `a_scope`
		require
			valid_user: a_user.has_id
		local
			tok: API_KEY_AUTH_TOKEN
		do
			Result := api_key_auth_storage.user_tokens (a_user)
			if Result /= Void and a_scope /= Void then
				from
					Result.start
				until
					Result.off
				loop
					tok := Result.item
					if attached tok.scopes as lst and then across lst as sco some a_scope.is_case_insensitive_equal (sco) end then
							-- Keep
						Result.forth
					else
						Result.remove
					end
				end
			end
		end

feature -- Change

	record_user_token (a_info: API_KEY_AUTH_TOKEN)
			-- Records token information `a_info` in storage
		require
			user_has_id: a_info.user.has_id
			valid_token: not a_info.key.is_whitespace
		do
			a_info.prepare
			api_key_auth_storage.record_user_token (a_info)
		end

	update_user_token (tok: API_KEY_AUTH_TOKEN)
			-- Updates token `tok` metadata (name, status)
		require
			user_has_id: tok.user.has_id
			valid_token: not tok.key.is_whitespace
		do
			api_key_auth_storage.update_user_token (tok)
		end

	update_user_token_last_used (tok: API_KEY_AUTH_TOKEN; a_dt: DATE_TIME)
			-- Updates last used timestamp of token `tok` to `a_dt`
		require
			user_has_id: tok.user.has_id
			valid_token: not tok.key.is_whitespace
		do
			api_key_auth_storage.update_user_token_last_used (tok, a_dt)
		end

	token (a_key_id: READABLE_STRING_GENERAL): detachable API_KEY_AUTH_TOKEN
		do
			Result := api_key_auth_storage.token (a_key_id)
		end

	disable_user_token (a_api_token: API_KEY_AUTH_TOKEN)
		require
			a_api_token.is_active
		do
			a_api_token.set_inactive
			update_user_token (a_api_token)
		end

	enable_user_token (a_api_token: API_KEY_AUTH_TOKEN)
		require
			a_api_token.is_inactive
		do
			a_api_token.set_active
			update_user_token (a_api_token)
		end

	revoke_user_token (a_api_token: API_KEY_AUTH_TOKEN)
		do
			a_api_token.set_revoked
			update_user_token (a_api_token)
		end

	discard_user_token (a_user: CMS_USER; a_key_id: READABLE_STRING_GENERAL)
			-- Discard `a_token` from `a_user`.
		require
			user_has_id: a_user.has_id
			valid_token: not a_key_id.is_whitespace
		do
			api_key_auth_storage.discard_user_token (a_user, a_key_id)
		end

	rotation_user_token (a_token: API_KEY_AUTH_TOKEN): like new_token
			-- Replace `a_token` with a new key for the same user: same scopes, same optional name,
			-- and expiry set to `a_token.expiration_date - a_token.creation_date` after the new key's creation when both exist.
			-- On success, same tuple as `new_token` (`token`, one-time `secret`); on failure `Void` (old key unchanged).
			-- Note: return type is the same detachable tuple as `new_token` so the plaintext secret is available once; use `Result.token` for the new {API_KEY_AUTH_TOKEN} alone.
		local
			l_old_key_id: READABLE_STRING_GENERAL
			l_new: like new_token
			l_need_meta_update: BOOLEAN
			l_ttl: DATE_TIME_DURATION
		do
			if
				a_token.is_revoked or else a_token.is_expired (Void)
				or else not a_token.user.has_id
			then
				Result := Void
			else
				l_old_key_id := a_token.key_id
				l_new := new_token (a_token.user, a_token.scopes)
				if l_new = Void or else has_error then
					Result := Void
				else
					l_need_meta_update := False
					if attached a_token.name as l_old_name then
						l_new.token.set_name (l_old_name)
						l_need_meta_update := True
					end
					if attached a_token.creation_date as l_old_created and attached a_token.expiration_date as l_old_exp then
						l_ttl := l_old_exp.relative_duration (l_old_created)
						if l_ttl.seconds_count >= 0 and then attached l_new.token.creation_date as l_new_created then
							l_new.token.set_expiration_date (l_new_created + l_ttl)
							l_need_meta_update := True
						end
					end
					if l_need_meta_update then
						update_user_token (l_new.token)
					end
					if has_error then
						Result := Void
					else
						revoke_user_token (a_token)
						if has_error then
							Result := Void
						else
							Result := l_new
						end
					end
				end
			end
		end

	discard_all_user_tokens (a_user: CMS_USER)
			-- Discard all tokens from `a_user`.
		require
			user_has_id: a_user.has_id
		do
			api_key_auth_storage.discard_all_user_tokens (a_user)
		end

	discard_expired_or_revoked_user_tokens (a_user: CMS_USER; a_count: detachable CELL [INTEGER])
			-- Discard expired or revoked tokens.
		do
			if attached user_tokens (a_user, Void) as lst then
				across
					lst as t
				loop
					if
						t.is_revoked
						or t.is_expired (Void)
					then
						discard_user_token (a_user, t.key_id)
					end
				end

			end
		end

	discard_expired_or_revoked_tokens (a_date: DATE_TIME; a_discarded_count: detachable CELL [INTEGER])
			-- Discard expired tokens at date `dt`.
		local
			dt: DATE_TIME
		do
			dt := a_date
			if dt = Void then
				create dt.make_now_utc
			end
			api_key_auth_storage.discard_expired_or_revoked_tokens (dt, a_discarded_count)
		end

feature -- Helpers

	set_key_status_from_string (s: READABLE_STRING_GENERAL; k: API_KEY_AUTH_TOKEN)
		local
			str: READABLE_STRING_GENERAL
		do
			str := s.as_lower
			if str.same_string ("active") then
				k.set_status ({API_KEY_AUTH_TOKEN}.status_active)
			elseif str.same_string ("revoked") then
				k.set_status ({API_KEY_AUTH_TOKEN}.status_revoked)
			elseif str.same_string ("inactive") then
				k.set_status ({API_KEY_AUTH_TOKEN}.status_inactive)
			elseif str.same_string ("expired") then
				k.set_status ({API_KEY_AUTH_TOKEN}.status_expired)
			else
				check has_status: False end
				k.set_status ({API_KEY_AUTH_TOKEN}.status_revoked) -- Not expected !
			end
		ensure
			instance_free: class
		end

	key_status_as_string (k: API_KEY_AUTH_TOKEN): STRING_8
		do
			inspect k.status
			when {API_KEY_AUTH_TOKEN}.status_active then
				Result := "active"
			when {API_KEY_AUTH_TOKEN}.status_revoked then
				Result := "revoked"
			when {API_KEY_AUTH_TOKEN}.status_inactive then
				Result := "inactive"
			when {API_KEY_AUTH_TOKEN}.status_expired then
				Result := "expired"
			else
				Result := "unknown"
			end
		ensure
			instance_free: class
		end


note
	copyright: "2011-2017, Jocelyn Fiat, Javier Velilla, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
end

