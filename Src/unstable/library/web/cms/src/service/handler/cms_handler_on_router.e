note
	description: "[
			Common interface for request handler specific to the CMS component on specific router
			Declare the routes inside the handler itself.
		]"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	CMS_HANDLER_ON_ROUTER

inherit
	CMS_HANDLER
		rename
			make as make_with_cms_api
		end

feature {NONE} -- Initialization

	make (a_api: CMS_API; a_router: WSF_ROUTER)
			-- Initialize Current handler with `a_api'.
		do
			make_with_cms_api (a_api)
			setup_router (a_router)
		end

feature -- Routing

	setup_router (a_router: WSF_ROUTER)
			-- Setup url dispatching for Current handler.
			-- (note: `a_router` is already based with path prefix).
		deferred
		end

note
	copyright: "2011-2026, Jocelyn Fiat, Javier Velilla, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
end
