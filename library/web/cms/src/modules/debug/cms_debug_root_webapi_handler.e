note
	description: "Summary description for {CMS_DEBUG_MODULE_ROOT_WEBAPI_HANDLER}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	CMS_DEBUG_ROOT_WEBAPI_HANDLER

inherit
	CMS_DEBUG_WEBAPI_HANDLER

	WSF_URI_HANDLER

	SHARED_EXECUTION_ENVIRONMENT

	WSF_SELF_DOCUMENTED_HANDLER

create
	make

feature -- Basic operations

	associated_router: detachable WSF_ROUTER

	setup_router (a_router: WSF_ROUTER)
			-- Configures routing for publisher content endpoints
			-- `a_router`: Router instance to configure routes on
		do
			associated_router := a_router
			a_router.handle ("/debug/", Current, a_router.methods_get)
			a_router.handle ("/debug/router/", Current, a_router.methods_get)
		end

feature -- Execution

	execute (req: WSF_REQUEST; res: WSF_RESPONSE)
		do
			if req.path_info.ends_with_general ("/router/") then
				handle_debug_router (req, res)
			else
				handle_debug (req, res)
			end
		end

	handle_debug (req: WSF_REQUEST; res: WSF_RESPONSE)
		local
			r: like new_response
		do
			r := new_response (req, res)
			append_info_to ("SiteName", api.setup.site_name, r)
			append_info_to ("SiteUrl", api.setup.site_url, r)

			if attached api.setup.environment.cms_config_ini_path as l_loc then
				append_info_to ("Configuration file", l_loc.name, r)
			end

			append_info_to ("Current dir", execution_environment.current_working_path.utf_8_name, r)
--				append_info_to ("Base url", cms.base_url, r)
--				append_info_to ("Script url", cms.script_url, r)
			append_info_to ("Site dir", api.site_location.utf_8_name, r)
			append_info_to ("Www dir", api.setup.environment.www_path.utf_8_name, r)
			append_info_to ("Assets dir", api.setup.environment.assets_path.utf_8_name, r)
			append_info_to ("Config dir", api.setup.environment.config_path.utf_8_name, r)
			append_info_to ("Theme", api.theme_name, r)
			append_info_to ("Theme location", api.theme_location.utf_8_name, r)
			append_info_to ("Files location", api.files_location.utf_8_name, r)
			append_info_to ("Modules location", api.modules_location.utf_8_name, r)
			append_info_to ("Storage", api.storage.generator, r)

			append_info_to ("Url", r.url ("/", Void), r)
--				if attached r.user as u then
--					append_info_to ("User", u.name, r)
--					append_info_to ("User url", r.user_url (u), r)
--				end


			if attached associated_router as l_router then
				r.add_link ("router", Void, api.webapi_path ("/debug/router/"))
--				append_router_info_to (l_router, r)
			end

			r.execute
		end

	handle_debug_router (req: WSF_REQUEST; res: WSF_RESPONSE)
		local
			r: like new_response
		do
			r := new_response (req, res)
			if attached associated_router as l_router then
				append_router_info_to (l_router, r)
			else
				r.add_boolean_field ("error", True)
			end

			r.add_link ("debug", "back to debug", api.webapi_path ("/debug/"))
			r.execute
		end

	append_info_to (n: READABLE_STRING_8; v: detachable READABLE_STRING_GENERAL; r: JSON_WEBAPI_RESPONSE)
		do
			if v = Void then
				r.resource.put (Void, n)
--				r.add_string_field (n, "")
			else
				r.add_string_field (n, v)
			end
		end

	append_router_info_to (a_router: WSF_ROUTER; r: JSON_WEBAPI_RESPONSE)
		local
			jarr: JSON_ARRAY
		do
			if attached a_router.base_url as l_base then
				r.resource.put_string (l_base, "base_url")
			end
			create jarr.make_empty
			across
				a_router as ri
			loop
				jarr.extend (create {JSON_STRING}.make_from_string_general (ri.debug_output))
			end
			r.resource.put (jarr, "routes")
		end


feature -- Documentation

	mapping_documentation (m: WSF_ROUTER_MAPPING; a_request_methods: detachable WSF_REQUEST_METHODS): WSF_ROUTER_MAPPING_DOCUMENTATION
			-- Documentation associated with Current handler, in the context of the mapping `m` and methods `a_request_methods`.
		do
			create Result.make (m)
--			Result.set_is_hidden (True)
			if m.associated_resource.ends_with ("/router/") then
				Result.add_description ("/debug/router/ : display available routes")
			else
				Result.add_description ("/debug/ : display debug information")
			end
		end

note
	copyright: "2011-2026, Jocelyn Fiat, Javier Velilla, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
end
