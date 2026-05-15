note
	description: "Summary description for {API_KEY_AUTH_MODULE_WEBAPI}."
	date: "$Date$"
	revision: "$Revision$"

class
	API_KEY_AUTH_MODULE_WEBAPI

inherit
	CMS_MODULE_WEBAPI [API_KEY_AUTH_MODULE]
		redefine
			permissions,
			setup_hooks,
			filters
		end

	CMS_HOOK_WEBAPI_RESPONSE_ALTER

	CMS_HOOK_AUTO_REGISTER

create
	make

feature {NONE} -- Router/administration

	setup_webapi_router (a_router: WSF_ROUTER; a_api: CMS_API)
			-- <Precursor>
		local
			h: API_KEY_AUTH_TOKEN_WEBAPI_HANDLER
		do
			if attached module.api_key_auth_api as l_api_key_auth_api then
				create h.make (Current, l_api_key_auth_api)
				a_router.handle ("/user/{uid}/api_key_token", h, a_router.methods_get_post)
				a_router.handle ("/user/{uid}/api_key_token/{key}/", h, a_router.methods_get_post_put_delete - a_router.methods_post)
			end
		end

feature -- Permissions

	permissions: LIST [READABLE_STRING_8]
		do
			Result := Precursor
			Result.force (perm_use_api_key_auth)
			Result.append (module.permissions)
		end

	perm_use_api_key_auth: STRING = "use api_key_auth"

feature -- Access: filter

	filters (a_api: CMS_API): detachable LIST [WSF_FILTER]
			-- Possibly list of Filter's module.
		do
			if attached module.api_key_auth_api as api_key_auth_api then
				create {ARRAYED_LIST [WSF_FILTER]} Result.make (1)
				Result.extend (create {API_KEY_AUTH_TOKEN_WEBAPI_FILTER}.make (a_api, api_key_auth_api))
			end
		end

feature -- Hooks configuration

	setup_hooks (a_hooks: CMS_HOOK_CORE_MANAGER)
			-- Module hooks configuration.
		do
			a_hooks.subscribe_to_webapi_response_alter_hook (Current)
		end

feature -- Hook

	webapi_response_alter (rep: WEBAPI_RESPONSE)
		do
--			if
--				attached {HM_WEBAPI_RESPONSE} rep as hm and then
--				rep.is_root
--			then
--				if attached rep.user as u then
--					hm.add_link ("api-key:access_token", Void, rep.api.webapi_path ("user/" + u.id.out + "/api_key_token"))
--				end
--			end
		end

note
	copyright: "2011-2017, Jocelyn Fiat, Javier Velilla, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
end
