note
	description: "[
			URL dispatching of request
			
			Map a route to an handler according to the request method and path

		]"
	date: "$Date$"
	revision: "$Revision$"

class
	WSF_ROUTER

inherit
	ITERABLE [WSF_ROUTER_ITEM]

	WSF_REQUEST_EXPORTER

create
	make,
	make_with_base_url

feature {NONE} -- Initialization

	make (n: INTEGER)
			-- Create the router with a capacity of `n' mappings.
		require
			valid_number_of_items: n >= 0
		do
			initialize (n)
		ensure
			no_handler_set: count = 0
		end

	make_with_base_url (n: INTEGER; a_base_url: like base_url)
			-- Make router allocated for at least `n' maps,
			-- and use `a_base_url' as `base_url'
			--| This avoids prefixing all the resource string.
		require
			valid_number_of_items: n >= 0
			a_valid_base_url: (a_base_url /= Void and then a_base_url.is_empty) implies (a_base_url.starts_with ("/") and not a_base_url.ends_with ("/"))
		do
			make (n)
			check
				no_handler_set: count = 0
					-- ensured by `make'
			end
			set_base_url (a_base_url)
		end

	initialize (n: INTEGER)
			-- Initialize router.
		require
			valid_number_of_items: n >= 0
		do
			create mappings.make (n)
			create pre_execution_actions
		ensure
			no_handler_set: count = 0
		end

	mappings: ARRAYED_LIST [WSF_ROUTER_ITEM]
			-- Existing mappings

feature -- Mapping

	map (a_mapping: WSF_ROUTER_MAPPING; rqst_methods: detachable WSF_REQUEST_METHODS)
			-- Map `a_mapping',
			-- if `rqst_methods' is set, accept only request method in `rqst_methods'.
			-- if `rqst_method' is Void, accept any request methods.
		require
			a_mapping_attached: a_mapping /= Void
		do
			extend (create {WSF_ROUTER_ITEM}.make (a_mapping, rqst_methods))
		end

	map_with_request_methods (a_mapping: WSF_ROUTER_MAPPING; rqst_methods: detachable WSF_REQUEST_METHODS)
			-- Map `a_mapping' for request methods `rqst_methods'.
		obsolete
			"Use directly `map' [2017-05-31]"
		require
			a_mapping_attached: a_mapping /= Void
		do
			map (a_mapping, rqst_methods)
		end

	import (a_mapping_items: ITERABLE [WSF_ROUTER_ITEM])
			-- Import mapping items from `a_mapping_items'.
			-- note: this `a_mapping_items' could be an instance of WSF_ROUTER.
		do
			across
				a_mapping_items as ic
			loop
				extend (ic.item)
			end
		end

feature {WSF_ROUTER} -- Mapping

	extend (a_item: WSF_ROUTER_ITEM)
			-- Extend `mappings' with `a_item'.
		local
			l_mapping: WSF_ROUTER_MAPPING
		do
			l_mapping := a_item.mapping
			debug ("router")
				-- Display conflict in mapping
				if has_item_associated_with_resource (l_mapping.associated_resource, a_item.request_methods) then
					io.error.put_string_32 ({STRING_32} "Mapping: " + l_mapping.debug_output.to_string_32 + {STRING_32} ": conflict with existing mapping")
					if attached item_associated_with_resource (l_mapping.associated_resource, a_item.request_methods) as l_conflicted then
						io.error.put_string_32 ({STRING_32} ": " + l_conflicted.debug_output)
					end
					io.error.put_string ("%N")
				end
			end

			mappings.extend (a_item)
			l_mapping.handler.on_mapped (l_mapping, a_item.request_methods)
		end

feature -- Mapping handler

	handle (a_resource: READABLE_STRING_8; f: WSF_ROUTER_MAPPING_FACTORY; rqst_methods: detachable WSF_REQUEST_METHODS)
			-- Map the mapping created by factory `f' for resource `a_resource'.
			-- if `rqst_methods' is set, accept only request method in `rqst_methods'.
			-- if `rqst_method' is Void, accept any request methods.
		require
			a_resource_attached: a_resource /= Void
			f_attached: f /= Void
		do
			map (f.new_mapping (a_resource), rqst_methods)
		end

	handle_with_request_methods (a_resource: READABLE_STRING_8; f: WSF_ROUTER_MAPPING_FACTORY; rqst_methods: detachable WSF_REQUEST_METHODS)
			-- Map the mapping created by factory `f' for resource `a_resource'	
			-- and only for request methods `rqst_methods'
		obsolete
			"Use directly `handle' [2017-05-31]"
		require
			a_resource_attached: a_resource /= Void
			f_attached: f /= Void
		do
			handle (a_resource, f, rqst_methods)
		end

feature -- Basic operations

	dispatch (req: WSF_REQUEST; res: WSF_RESPONSE; sess: detachable WSF_ROUTER_SESSION)
			-- Dispatch request `req' among  the `mappings'.
			-- Set `sess' if the request were dispatched and `sess' attached.
		require
			req_attached: req /= Void
			res_attached: res /= Void
		local
			l_sess: detachable WSF_ROUTER_SESSION
		do
			l_sess := sess
			if l_sess = Void then
				create l_sess
			end
			router_dispatch (req, res, l_sess)
		end

	dispatch_and_return_handler (req: WSF_REQUEST; res: WSF_RESPONSE): detachable WSF_HANDLER
			-- Dispatch request `req' among the `mappings'
			-- And return the associated handler if mapping found and handler executed.
			--| Violates CQS
		obsolete
			"Use `dispatch' [2017-05-31]"
		require
			req_attached: req /= Void
			res_attached: res /= Void
		local
			sess: WSF_ROUTER_SESSION
		do
			create sess
			router_dispatch (req, res, sess)
			Result := sess.dispatched_handler
		end

feature {WSF_ROUTER_MAPPING} -- Dispatch helper

	path_to_dispatch (req: WSF_REQUEST): READABLE_STRING_8
			-- Path used by the router, to apply url dispatching of request `req'.
			-- This can be redefined in descendant, to apply various url mapping, or aliasing
			-- if needed, or for other purpose.
		require
			req_attached: req /= Void
		do
			Result := req.percent_encoded_path_info
		ensure
			path_from_request_attached: Result /= Void
		end

feature {NONE} -- Dispatch implementation

	router_dispatch (req: WSF_REQUEST; res: WSF_RESPONSE; sess: WSF_ROUTER_SESSION)
		require
			req_attached: req /= Void
			res_attached: res /= Void
			sess_attached: sess /= Void
			sess_not_dispatched: not sess.dispatched
		local
			l_req_method: READABLE_STRING_8
			head_res: WSF_HEAD_RESPONSE_WRAPPER
		do
			l_req_method := request_method (req)
			router_dispatch_for_request_method (req, res, sess, l_req_method)
			if not sess.dispatched and l_req_method = {HTTP_REQUEST_METHODS}.method_options then
				router_process_options_request_method (req, res, sess)
			end
			if
				l_req_method = {HTTP_REQUEST_METHODS}.method_head and then
				not sess.dispatched
			then
				create head_res.make_from_response (res)
				req.set_request_method ({HTTP_REQUEST_METHODS}.method_GET)
				router_dispatch_for_request_method (req, head_res, sess, {HTTP_REQUEST_METHODS}.method_GET)
			end
		end

	router_process_options_request_method (req: WSF_REQUEST; res: WSF_RESPONSE; sess: WSF_ROUTER_SESSION)
			-- Respond to OPTIONS http request, when the Current router has no matching mapping.
			-- note: this the default behavior, and avoid handling this OPTIONS request for each handler.
			--       but if a mapping is set for the OPTIONS method, it will be executed instead of this feature.
		require
			req_attached: req /= Void
			is_options_request_method: req.is_options_request_method
			res_attached: res /= Void
			sess_attached: sess /= Void
			sess_not_dispatched: not sess.dispatched
		local
			m: WSF_ROUTER_MAPPING
			p: like path_to_dispatch
			l_info: WSF_ROUTER_ITEM
			mtds: WSF_REQUEST_METHODS
			hdl: WSF_HANDLER
			l_options_response: WSF_OPTIONS_RESPONSE
			h: HTTP_HEADER
		do
			p := path_to_dispatch (req)
			across
				mappings as c
			loop
				l_info := c.item
				if
					l_info /= Void and then
					attached l_info.request_methods as l_info_rqst_mtds
				then
					m := l_info.mapping
					if m.is_mapping (p, req, Current) then
						if hdl = Void then
							hdl := m.handler
						end
						if mtds = Void then
							mtds := l_info_rqst_mtds
						else
							mtds := mtds + l_info_rqst_mtds
						end
					end
				end
			end
			if mtds /= Void and hdl /= Void then
				create l_options_response.make (req)
				h := l_options_response.header
				h.put_allow (mtds)
				h.put_access_control_allow_methods (mtds)
				h.put_access_control_allow_all_origin
--				h.put_access_control_allow_credentials (True)
				if attached req.http_access_control_request_headers as l_headers then
					h.put_access_control_allow_headers (l_headers)
				end
				h.put_header_key_value ("X-Dbg-Handler", hdl.generator)
				res.send (l_options_response)
				sess.set_dispatched_handler (hdl)
			end
		end

	router_dispatch_for_request_method (req: WSF_REQUEST; res: WSF_RESPONSE; sess: WSF_ROUTER_SESSION; a_request_method: READABLE_STRING_8)
			-- Dispatch request `req' among the `mappings'
			-- And return the associated handler if mapping found and handler executed.
			--| Violates CQS
		require
			req_attached: req /= Void
			res_attached: res /= Void
			sess_attached: sess /= Void
			sess_not_dispatched: not sess.dispatched
			a_request_method_attached: a_request_method /= Void
		local
			m: WSF_ROUTER_MAPPING
			p: like path_to_dispatch
			l_info: WSF_ROUTER_ITEM
		do
			p := path_to_dispatch (req)
			across
				mappings as c
			until
				sess.dispatched
			loop
				l_info := c.item
				if l_info /= Void then
					if is_matching_request_methods (a_request_method, l_info.request_methods) then
						m := l_info.mapping
						m.try (p, req, res, sess, Current)
					end
				end
			end
		end

feature -- Status report

	has_item_associated_with_resource (a_resource: READABLE_STRING_8; rqst_methods: detachable WSF_REQUEST_METHODS): BOOLEAN
			-- Is there a handler for `a_resource' (taking into account `rqst_methods')?
		require
			a_resource_attached: a_resource /= Void
		local
			m: WSF_ROUTER_MAPPING
			ok: BOOLEAN
		do
			across
				mappings as c
			loop
				m := c.item.mapping
				ok := True
				if rqst_methods /= Void then
					if attached c.item.request_methods as l_item_rqst_methods then
						ok := across rqst_methods as mtd some is_matching_request_methods (mtd.item, l_item_rqst_methods) end
					else
						ok := True
					end
				end
				if ok then
					if attached {WSF_ROUTING_HANDLER} m.handler as l_routing then
						Result := l_routing.router.has_item_associated_with_resource (a_resource, rqst_methods)
					elseif m.associated_resource.same_string (a_resource) then
						Result := True
					end
				end
			end
		end

	item_associated_with_resource (a_resource: READABLE_STRING_8; rqst_methods: detachable WSF_REQUEST_METHODS): detachable WSF_ROUTER_ITEM
			-- First handler for `a_resource', taking into account `rqst_methods'
		require
			a_resource_attached: a_resource /= Void
		local
			m: WSF_ROUTER_MAPPING
			ok: BOOLEAN
		do
			across
				mappings as c
			until
				Result /= Void
			loop
				m := c.item.mapping
				ok := True
				if rqst_methods /= Void then
					if attached c.item.request_methods as l_item_rqst_methods then
						ok := across rqst_methods as mtd some is_matching_request_methods (mtd.item, l_item_rqst_methods) end
					else
						ok := True
					end
				end
				if ok then
					if attached {WSF_ROUTING_HANDLER} m.handler as l_routing then
						Result := l_routing.router.item_associated_with_resource (a_resource, rqst_methods)
					elseif m.associated_resource.same_string (a_resource) then
						Result := c.item
					end
				end
			end
		end

	items_associated_with_resource (a_resource: READABLE_STRING_8; rqst_methods: detachable WSF_REQUEST_METHODS): LIST [WSF_ROUTER_ITEM]
			-- All handlers for `a_resource', taking into account `rqst_methods'
		require
			a_resource_attached: a_resource /= Void
		local
			m: WSF_ROUTER_MAPPING
			ok: BOOLEAN
		do
			create {ARRAYED_LIST [WSF_ROUTER_ITEM]} Result.make (1)
			across
				mappings as c
			loop
				m := c.item.mapping
				ok := True
				if rqst_methods /= Void then
					if attached c.item.request_methods as l_item_rqst_methods then
						ok := across rqst_methods as mtd some is_matching_request_methods (mtd.item, l_item_rqst_methods) end
					else
						ok := True
					end
				end
				if ok then
					if attached {WSF_ROUTING_HANDLER} m.handler as l_routing then
						Result.append (l_routing.router.items_associated_with_resource (a_resource, rqst_methods))
					elseif m.associated_resource.same_string (a_resource) then
						Result.force (c.item)
					end
				end
			end
		end

	allowed_methods_for_request (req: WSF_REQUEST): WSF_REQUEST_METHODS
			-- Allowed methods for `req'
		require
			req_attched: req /= Void
		local
			m: WSF_ROUTER_MAPPING
			l_rqsmethods: detachable WSF_REQUEST_METHODS
			p: like path_to_dispatch
		do
			create Result
			p := path_to_dispatch (req)
			across
				mappings as c
			loop
				m := c.item.mapping
				if attached {WSF_ROUTING_HANDLER} m.handler as l_routing then
					l_rqsmethods := l_routing.router.allowed_methods_for_request (req)
				elseif m.is_mapping (p, req, Current) then
					l_rqsmethods := c.item.request_methods
				else
					l_rqsmethods := Void
				end
				if l_rqsmethods /= Void then
					Result := Result + l_rqsmethods
				end
			end
		end

	all_allowed_methods: WSF_REQUEST_METHODS
			-- Methods allowed for ALL requests handled by `Current'
		local
			l_mapping: WSF_ROUTER_MAPPING
		do
			create Result
			across
				mappings as c
			loop
				if attached c.item.request_methods as m then
					Result := Result + m
				end
				l_mapping := c.item.mapping
				if attached {WSF_ROUTING_HANDLER} l_mapping.handler as l_routing then
					Result := Result + l_routing.router.all_allowed_methods
				end
				--| not sure if that covers everything - Jocelyn, please comment
			end
		end

feature -- Hook

	execute_before (a_mapping: WSF_ROUTER_MAPPING)
			-- Execute before the handler associated with `a_mapping' is executed.
		require
			a_mapping_attached: a_mapping /= Void
		do
			pre_execution_actions.call ([a_mapping])
		end

	execute_after (a_mapping: WSF_ROUTER_MAPPING)
			-- Execute after the handler associated with `a_mapping' is executed.
			--| Could be redefined to add specific hook.
		require
			a_mapping_attached: a_mapping /= Void
		do
		end

	pre_execution_actions: ACTION_SEQUENCE [TUPLE [WSF_ROUTER_MAPPING]]
			-- Action triggered before a route is execute
			--| Could be used for tracing, logging		

feature -- Base url

	count: INTEGER
			-- Number of mappings registered
		do
			Result := mappings.count
		end

	base_url: detachable READABLE_STRING_8
			-- Common start of any route url

feature -- Element change

	set_base_url (a_base_url: like base_url)
			-- Set `base_url' to `a_base_url'
			-- make sure no map is already added (i.e: count = 0)
		require
			a_valid_base_url: (a_base_url /= Void and then a_base_url.is_empty) implies (a_base_url.starts_with ("/") and not a_base_url.ends_with ("/"))
			no_handler_set: count = 0
		do
			if a_base_url = Void or else a_base_url.is_empty then
				base_url := Void
			else
				base_url := a_base_url
			end
		end

feature -- Traversing

	new_cursor: ITERATION_CURSOR [WSF_ROUTER_ITEM]
			-- Fresh cursor associated with current structure
		do
			Result := mappings.new_cursor
		end

feature -- Request methods helper

	methods_head: WSF_REQUEST_METHODS
		once ("THREAD")
			create Result
			Result.enable_head
			Result.lock
		ensure
			methods_head_not_void: Result /= Void
		end

	methods_options: WSF_REQUEST_METHODS
		once ("THREAD")
			create Result
			Result.enable_options
			Result.lock
		ensure
			methods_options_not_void: Result /= Void
		end

	methods_get: WSF_REQUEST_METHODS
		once ("THREAD")
			create Result
			Result.enable_get
			Result.lock
		ensure
			methods_get_not_void: Result /= Void
		end

	methods_post: WSF_REQUEST_METHODS
		once ("THREAD")
			create Result
			Result.enable_post
			Result.lock
		ensure
			methods_post_not_void: Result /= Void
		end

	methods_put: WSF_REQUEST_METHODS
		once ("THREAD")
			create Result
			Result.enable_put
			Result.lock
		ensure
			methods_put_not_void: Result /= Void
		end

	methods_delete: WSF_REQUEST_METHODS
		once ("THREAD")
			create Result
			Result.enable_delete
			Result.lock
		ensure
			methods_delete_not_void: Result /= Void
		end

	methods_head_get_post: WSF_REQUEST_METHODS
		once ("THREAD")
			create Result.make (3)
			Result.enable_head
			Result.enable_get
			Result.enable_post
			Result.lock
		ensure
			methods_head_get_post_not_void: Result /= Void
		end

	methods_get_post_put_delete: WSF_REQUEST_METHODS
		once ("THREAD")
			create Result.make (3)
			Result.enable_get
			Result.enable_post
			Result.enable_put
			Result.enable_delete
			Result.lock
		ensure
			methods_get_put_not_void: Result /= Void
		end

	methods_get_put_delete: WSF_REQUEST_METHODS
		once ("THREAD")
			create Result.make (3)
			Result.enable_get
			Result.enable_put
			Result.enable_delete
			Result.lock
		ensure
			methods_get_put_not_void: Result /= Void
		end

	methods_head_get: WSF_REQUEST_METHODS
		once ("THREAD")
			create Result.make (2)
			Result.enable_head
			Result.enable_get
			Result.lock
		ensure
			methods_head_get_not_void: Result /= Void
		end

	methods_get_post: WSF_REQUEST_METHODS
		once ("THREAD")
			create Result.make (2)
			Result.enable_get
			Result.enable_post
			Result.lock
		ensure
			methods_get_post_not_void: Result /= Void
		end

	methods_put_post: WSF_REQUEST_METHODS
		once ("THREAD")
			create Result.make (2)
			Result.enable_put
			Result.enable_post
			Result.lock
		ensure
			methods_put_post_not_void: Result /= Void
		end

feature {NONE} -- Access: Implementation

	request_method (req: WSF_REQUEST): READABLE_STRING_8
			-- Request method from `req' to be used in the router implementation
		require
			req_attached: req /= Void
		local
			m: READABLE_STRING_8
		do
			m := req.request_method
			if m.is_case_insensitive_equal ({HTTP_REQUEST_METHODS}.method_get) then
				Result := {HTTP_REQUEST_METHODS}.method_get
			elseif m.is_case_insensitive_equal ({HTTP_REQUEST_METHODS}.method_post) then
				Result := {HTTP_REQUEST_METHODS}.method_post
			elseif m.is_case_insensitive_equal ({HTTP_REQUEST_METHODS}.method_head) then
				Result := {HTTP_REQUEST_METHODS}.method_head
			elseif m.is_case_insensitive_equal ({HTTP_REQUEST_METHODS}.method_trace) then
				Result := {HTTP_REQUEST_METHODS}.method_trace
			elseif m.is_case_insensitive_equal ({HTTP_REQUEST_METHODS}.method_options) then
				Result := {HTTP_REQUEST_METHODS}.method_options
			elseif m.is_case_insensitive_equal ({HTTP_REQUEST_METHODS}.method_put) then
				Result := {HTTP_REQUEST_METHODS}.method_put
			elseif m.is_case_insensitive_equal ({HTTP_REQUEST_METHODS}.method_delete) then
				Result := {HTTP_REQUEST_METHODS}.method_delete
			elseif m.is_case_insensitive_equal ({HTTP_REQUEST_METHODS}.method_connect) then
				Result := {HTTP_REQUEST_METHODS}.method_connect
			elseif m.is_case_insensitive_equal ({HTTP_REQUEST_METHODS}.method_patch) then
				Result := {HTTP_REQUEST_METHODS}.method_patch
			else
				Result := m.as_upper
			end
		end

	is_matching_request_methods (a_request_method: READABLE_STRING_8; a_rqst_methods: detachable WSF_REQUEST_METHODS): BOOLEAN
			-- `a_request_method' is matching `a_rqst_methods' contents
		require
			a_request_method_attached: a_request_method /= Void
		do
			if a_rqst_methods /= Void and then not a_rqst_methods.is_empty then
				Result := a_rqst_methods.has (a_request_method)
			else
				Result := True
			end
		end

invariant

	mappings_attached: mappings /= Void
	pre_execution_actions_attached: pre_execution_actions /= Void

note
	copyright: "2011-2025, Jocelyn Fiat, Javier Velilla, Olivier Ligot, Colin Adams, Alexander Kogtenkov, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"
end
