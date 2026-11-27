note
	description: "[
			Eiffel wrapper for a WebKitGTK `WebKitWebView` (GTK3 API: webkit2gtk-4.1 or webkit2gtk-4.0).

			The WebKitGTK library is loaded at run time, so that applications run (without web view)
			on systems where it is not installed.
		]"
	date: "$Date$"
	revision: "$Revision$"
	EIS: "name=WebKitGTK", "src=https://webkitgtk.org/reference/webkit2gtk/stable/class.WebView.html", "protocol=uri"

class
	EV_WEBKIT_WEB_VIEW

create
	make

feature {NONE} -- Initialization

	make
			-- Create a web view, if the WebKitGTK library is available.
		do
			if
				is_library_loaded and then
				across required_api_names as n all not api (n).is_default_pointer end and then
				(not api ("webkit_web_view_evaluate_javascript").is_default_pointer or
				not api ("webkit_web_view_run_javascript").is_default_pointer)
			then
				user_content_manager := c_new (api ("webkit_user_content_manager_new"))
				item := c_new_with_pointer (api ("webkit_web_view_new_with_user_content_manager"), user_content_manager)
			end
		end

feature -- Status report

	is_usable: BOOLEAN
			-- Is the web view created?
		do
			Result := not item.is_default_pointer
		end

	can_go_back: BOOLEAN
			-- Is there a previous page in the history?
		require
			is_usable: is_usable
		do
			Result := c_boolean_function (api ("webkit_web_view_can_go_back"), item)
		end

	can_go_forward: BOOLEAN
			-- Is there a next page in the history?
		require
			is_usable: is_usable
		do
			Result := c_boolean_function (api ("webkit_web_view_can_go_forward"), item)
		end

	is_loading: BOOLEAN
			-- Is a page being loaded?
		require
			is_usable: is_usable
		do
			Result := c_boolean_function (api ("webkit_web_view_is_loading"), item)
		end

feature -- Access

	item: POINTER
			-- WebKitWebView C object.

	user_content_manager: POINTER
			-- WebKitUserContentManager C object of `item`.

	uri: detachable STRING_32
			-- URI of the current page.
		require
			is_usable: is_usable
		do
			Result := string_from_utf_8 (c_pointer_function (api ("webkit_web_view_get_uri"), item))
		end

	title: detachable STRING_32
			-- Title of the current page.
		require
			is_usable: is_usable
		do
			Result := string_from_utf_8 (c_pointer_function (api ("webkit_web_view_get_title"), item))
		end

	zoom_level: REAL_64
			-- Zoom factor of the page.
		require
			is_usable: is_usable
		do
			Result := c_get_zoom_level (api ("webkit_web_view_get_zoom_level"), item)
		end

feature -- Element change

	set_zoom_level (a_zoom_level: REAL_64)
			-- Set `zoom_level` to `a_zoom_level`.
		require
			is_usable: is_usable
		do
			c_set_zoom_level (api ("webkit_web_view_set_zoom_level"), item, a_zoom_level)
		end

	set_user_agent (a_user_agent: READABLE_STRING_GENERAL)
			-- Use `a_user_agent` as user agent.
		require
			is_usable: is_usable
		local
			s: EV_GTK_C_STRING
		do
			create s.set_with_eiffel_string (a_user_agent)
			c_procedure_with_pointer (api ("webkit_settings_set_user_agent"), settings, s.item)
		end

	set_developer_extras_enabled (b: BOOLEAN)
			-- Enable (if `b`) or disable the web inspector.
		require
			is_usable: is_usable
		do
			c_procedure_with_boolean (api ("webkit_settings_set_enable_developer_extras"), settings, b)
		end

feature -- Basic operations

	load_uri (a_uri: READABLE_STRING_GENERAL)
			-- Load `a_uri`.
		require
			is_usable: is_usable
		local
			s: EV_GTK_C_STRING
		do
			create s.set_with_eiffel_string (a_uri)
			c_procedure_with_pointer (api ("webkit_web_view_load_uri"), item, s.item)
		end

	load_html (a_html: READABLE_STRING_GENERAL; a_base_uri: detachable READABLE_STRING_GENERAL)
			-- Load the HTML document `a_html`, with `a_base_uri` as base URI if set.
		require
			is_usable: is_usable
		local
			s, b: EV_GTK_C_STRING
		do
			create s.set_with_eiffel_string (a_html)
			if a_base_uri /= Void then
				create b.set_with_eiffel_string (a_base_uri)
				c_procedure_with_two_pointers (api ("webkit_web_view_load_html"), item, s.item, b.item)
			else
				c_procedure_with_two_pointers (api ("webkit_web_view_load_html"), item, s.item, default_pointer)
			end
		end

	reload
			-- Reload the current page.
		require
			is_usable: is_usable
		do
			c_procedure (api ("webkit_web_view_reload"), item)
		end

	stop_loading
			-- Stop the loading of the current page.
		require
			is_usable: is_usable
		do
			c_procedure (api ("webkit_web_view_stop_loading"), item)
		end

	go_back
			-- Load the previous page in the history.
		require
			is_usable: is_usable
		do
			c_procedure (api ("webkit_web_view_go_back"), item)
		end

	go_forward
			-- Load the next page in the history.
		require
			is_usable: is_usable
		do
			c_procedure (api ("webkit_web_view_go_forward"), item)
		end

	run_javascript (a_script: READABLE_STRING_GENERAL)
			-- Run `a_script` in the main frame, ignoring its result.
		require
			is_usable: is_usable
		local
			s: EV_GTK_C_STRING
			l_api: POINTER
		do
			create s.set_with_eiffel_string (a_script)
			l_api := api ("webkit_web_view_evaluate_javascript")
			if not l_api.is_default_pointer then
					-- WebKitGTK 2.40 and later.
				c_evaluate_javascript (l_api, item, s.item)
			else
				c_run_javascript (api ("webkit_web_view_run_javascript"), item, s.item)
			end
		end

	add_user_script (a_script: READABLE_STRING_GENERAL)
			-- Inject `a_script` at the start of every document of the top frame.
		require
			is_usable: is_usable
		local
			s: EV_GTK_C_STRING
			l_script: POINTER
		do
			create s.set_with_eiffel_string (a_script)
			l_script := c_user_script_new (api ("webkit_user_script_new"), s.item)
			if not l_script.is_default_pointer then
				c_procedure_with_pointer (api ("webkit_user_content_manager_add_script"), user_content_manager, l_script)
				c_procedure (api ("webkit_user_script_unref"), l_script)
			end
		end

	register_script_message_handler (a_name: READABLE_STRING_8)
			-- Make `window.webkit.messageHandlers.<a_name>` available to the pages,
			-- and emit "script-message-received::<a_name>" on `user_content_manager`.
		require
			is_usable: is_usable
		local
			s: EV_GTK_C_STRING
		do
			create s.set_with_eiffel_string (a_name)
			c_procedure_with_pointer (api ("webkit_user_content_manager_register_script_message_handler"), user_content_manager, s.item)
		end

feature -- Signal data

	script_message_string (a_value: POINTER): detachable STRING_32
			-- String value of the JavaScript value in the GValue `a_value`
			-- (argument of "script-message-received": a `JSCValue`, or a `WebKitJavascriptResult` before WebKitGTK 2.40).
		require
			is_usable: is_usable
		local
			p: POINTER
		do
			p := c_script_message_to_string (a_value, api ("webkit_javascript_result_get_js_value"), api ("jsc_value_to_string"))
			if not p.is_default_pointer then
				Result := string_from_utf_8 (p)
				c_g_free (p)
			end
		end

	navigation_uri (a_decision: POINTER): detachable STRING_32
			-- URI requested by the navigation policy decision `a_decision`.
		require
			is_usable: is_usable
		local
			p: POINTER
		do
			p := c_pointer_function (api ("webkit_navigation_policy_decision_get_navigation_action"), a_decision)
			if not p.is_default_pointer then
				p := c_pointer_function (api ("webkit_navigation_action_get_request"), p)
				if not p.is_default_pointer then
					Result := string_from_utf_8 (c_pointer_function (api ("webkit_uri_request_get_uri"), p))
				end
			end
		end

	ignore_decision (a_decision: POINTER)
			-- Ignore the policy decision `a_decision` (cancel the navigation).
		require
			is_usable: is_usable
		do
			c_procedure (api ("webkit_policy_decision_ignore"), a_decision)
		end

	error_message (a_error: POINTER): STRING_32
			-- Message of the GError `a_error`.
		do
			if attached string_from_utf_8 (c_error_message (a_error)) as m then
				Result := m
			else
				create Result.make_empty
			end
		end

feature -- Constants

	Load_started: INTEGER = 0
	Load_redirected: INTEGER = 1
	Load_committed: INTEGER = 2
	Load_finished: INTEGER = 3
			-- Values of WebKitLoadEvent.

	Policy_decision_navigation_action: INTEGER = 0
	Policy_decision_new_window_action: INTEGER = 1
	Policy_decision_response: INTEGER = 2
			-- Values of WebKitPolicyDecisionType.

feature {NONE} -- Implementation

	settings: POINTER
			-- WebKitSettings of `item`.
		require
			is_usable: is_usable
		do
			Result := c_pointer_function (api ("webkit_web_view_get_settings"), item)
		end

	string_from_utf_8 (p: POINTER): detachable STRING_32
			-- Copy of the UTF-8 zero-terminated string `p`, if any.
		local
			s: EV_GTK_C_STRING
		do
			if not p.is_default_pointer then
				create s.share_from_pointer (p)
				Result := s.string
			end
		end

	api (a_name: READABLE_STRING_8): POINTER
			-- Address of the function `a_name` of the WebKitGTK library, or `default_pointer` if not found.
		require
			is_library_loaded: is_library_loaded
		local
			l_name: C_STRING
		do
			if api_table.has_key (a_name) then
				Result := api_table.found_item
			else
				create l_name.make (a_name)
				Result := c_dlsym (library_handle, l_name.item)
				api_table.force (Result, a_name)
			end
		end

	api_table: STRING_TABLE [POINTER]
			-- Cache of `api`.
		once
			create Result.make (32)
		end

	is_library_loaded: BOOLEAN
			-- Is the WebKitGTK library loaded?
		do
			Result := not library_handle.is_default_pointer
		end

	library_handle: POINTER
			-- Handle of the WebKitGTK library, or `default_pointer` if not found.
		local
			l_name: C_STRING
		once
			across
				library_names as n
			until
				not Result.is_default_pointer
			loop
				create l_name.make (n)
				Result := c_dlopen (l_name.item)
			end
		end

	library_names: ARRAY [STRING_8]
			-- File names of the supported WebKitGTK libraries, by order of preference.
		once
			Result := <<
					"libwebkit2gtk-4.1.so.0", -- libsoup 3
					"libwebkit2gtk-4.0.so.37", -- libsoup 2
					"libwebkit2gtk-4.1.so",
					"libwebkit2gtk-4.0.so"
				>>
		end

	required_api_names: ARRAY [STRING_8]
			-- Names of the WebKitGTK functions used by `Current`, except the JavaScript evaluation.
		once
			Result := <<
					"webkit_user_content_manager_new",
					"webkit_web_view_new_with_user_content_manager",
					"webkit_web_view_can_go_back",
					"webkit_web_view_can_go_forward",
					"webkit_web_view_is_loading",
					"webkit_web_view_get_uri",
					"webkit_web_view_get_title",
					"webkit_web_view_get_zoom_level",
					"webkit_web_view_set_zoom_level",
					"webkit_web_view_get_settings",
					"webkit_settings_set_user_agent",
					"webkit_settings_set_enable_developer_extras",
					"webkit_web_view_load_uri",
					"webkit_web_view_load_html",
					"webkit_web_view_reload",
					"webkit_web_view_stop_loading",
					"webkit_web_view_go_back",
					"webkit_web_view_go_forward",
					"webkit_user_script_new",
					"webkit_user_content_manager_add_script",
					"webkit_user_script_unref",
					"webkit_user_content_manager_register_script_message_handler",
					"webkit_navigation_policy_decision_get_navigation_action",
					"webkit_navigation_action_get_request",
					"webkit_uri_request_get_uri",
					"webkit_policy_decision_ignore",
					"jsc_value_to_string"
				>>
		end

feature {NONE} -- Externals

	c_dlopen (a_file_name: POINTER): POINTER
		external
			"C inline use <dlfcn.h>"
		alias
			"return dlopen ((const char *) $a_file_name, RTLD_LAZY | RTLD_GLOBAL);"
		end

	c_dlsym (a_handle: POINTER; a_name: POINTER): POINTER
		external
			"C inline use <dlfcn.h>"
		alias
			"return dlsym ((void *) $a_handle, (const char *) $a_name);"
		end

	c_g_free (p: POINTER)
		external
			"C signature (gpointer) use <ev_gtk.h>"
		alias
			"g_free"
		end

	c_new (a_api: POINTER): POINTER
		external
			"C inline use <ev_gtk.h>"
		alias
			"return (FUNCTION_CAST (gpointer, ()) $a_api) ();"
		end

	c_new_with_pointer (a_api: POINTER; a_arg: POINTER): POINTER
		external
			"C inline use <ev_gtk.h>"
		alias
			"return (FUNCTION_CAST (gpointer, (gpointer)) $a_api) ((gpointer) $a_arg);"
		end

	c_pointer_function (a_api: POINTER; a_object: POINTER): POINTER
		external
			"C inline use <ev_gtk.h>"
		alias
			"return (EIF_POINTER) (FUNCTION_CAST (gconstpointer, (gpointer)) $a_api) ((gpointer) $a_object);"
		end

	c_boolean_function (a_api: POINTER; a_object: POINTER): BOOLEAN
		external
			"C inline use <ev_gtk.h>"
		alias
			"return EIF_TEST ((FUNCTION_CAST (gboolean, (gpointer)) $a_api) ((gpointer) $a_object));"
		end

	c_procedure (a_api: POINTER; a_object: POINTER)
		external
			"C inline use <ev_gtk.h>"
		alias
			"(FUNCTION_CAST (void, (gpointer)) $a_api) ((gpointer) $a_object);"
		end

	c_procedure_with_pointer (a_api: POINTER; a_object: POINTER; a_arg: POINTER)
		external
			"C inline use <ev_gtk.h>"
		alias
			"(FUNCTION_CAST (void, (gpointer, gconstpointer)) $a_api) ((gpointer) $a_object, (gconstpointer) $a_arg);"
		end

	c_procedure_with_two_pointers (a_api: POINTER; a_object: POINTER; a_arg1, a_arg2: POINTER)
		external
			"C inline use <ev_gtk.h>"
		alias
			"(FUNCTION_CAST (void, (gpointer, gconstpointer, gconstpointer)) $a_api) ((gpointer) $a_object, (gconstpointer) $a_arg1, (gconstpointer) $a_arg2);"
		end

	c_procedure_with_boolean (a_api: POINTER; a_object: POINTER; a_arg: BOOLEAN)
		external
			"C inline use <ev_gtk.h>"
		alias
			"(FUNCTION_CAST (void, (gpointer, gboolean)) $a_api) ((gpointer) $a_object, (gboolean) $a_arg);"
		end

	c_get_zoom_level (a_api: POINTER; a_object: POINTER): REAL_64
		external
			"C inline use <ev_gtk.h>"
		alias
			"return (FUNCTION_CAST (gdouble, (gpointer)) $a_api) ((gpointer) $a_object);"
		end

	c_set_zoom_level (a_api: POINTER; a_object: POINTER; a_level: REAL_64)
		external
			"C inline use <ev_gtk.h>"
		alias
			"(FUNCTION_CAST (void, (gpointer, gdouble)) $a_api) ((gpointer) $a_object, (gdouble) $a_level);"
		end

	c_evaluate_javascript (a_api: POINTER; a_object: POINTER; a_script: POINTER)
			-- webkit_web_view_evaluate_javascript (web_view, script, -1, NULL, NULL, NULL, NULL, NULL)
		external
			"C inline use <ev_gtk.h>"
		alias
			"[
				(FUNCTION_CAST (void, (gpointer, const char *, gssize, const char *, const char *, gpointer, GAsyncReadyCallback, gpointer)) $a_api)
					((gpointer) $a_object, (const char *) $a_script, (gssize) -1, NULL, NULL, NULL, NULL, NULL);
			]"
		end

	c_run_javascript (a_api: POINTER; a_object: POINTER; a_script: POINTER)
			-- webkit_web_view_run_javascript (web_view, script, NULL, NULL, NULL)
		external
			"C inline use <ev_gtk.h>"
		alias
			"[
				(FUNCTION_CAST (void, (gpointer, const gchar *, gpointer, GAsyncReadyCallback, gpointer)) $a_api)
					((gpointer) $a_object, (const gchar *) $a_script, NULL, NULL, NULL);
			]"
		end

	c_user_script_new (a_api: POINTER; a_source: POINTER): POINTER
			-- webkit_user_script_new (source, WEBKIT_USER_CONTENT_INJECT_TOP_FRAME, WEBKIT_USER_SCRIPT_INJECT_AT_DOCUMENT_START, NULL, NULL)
		external
			"C inline use <ev_gtk.h>"
		alias
			"[
				return (FUNCTION_CAST (gpointer, (const gchar *, int, int, const gchar * const *, const gchar * const *)) $a_api)
					((const gchar *) $a_source, 1, 0, NULL, NULL);
			]"
		end

	c_script_message_to_string (a_value: POINTER; a_get_js_value: POINTER; a_to_string: POINTER): POINTER
			-- New string (to free with `g_free`) for the JavaScript value held by the GValue `a_value`.
		external
			"C inline use <ev_gtk.h>"
		alias
			"[
				GValue *v = (GValue *) $a_value;
				gpointer js_value = g_value_peek_pointer (v);
				if (js_value && !G_TYPE_IS_OBJECT (G_VALUE_TYPE (v))) {
						/* WebKitJavascriptResult (boxed), before WebKitGTK 2.40 */
					js_value = $a_get_js_value ? (FUNCTION_CAST (gpointer, (gpointer)) $a_get_js_value) (js_value) : NULL;
				}
				if (js_value && $a_to_string) {
					return (EIF_POINTER) (FUNCTION_CAST (char *, (gpointer)) $a_to_string) (js_value);
				}
				return NULL;
			]"
		end

	c_error_message (a_error: POINTER): POINTER
		external
			"C inline use <ev_gtk.h>"
		alias
			"return ($a_error ? (EIF_POINTER) ((GError *) $a_error)->message : NULL);"
		end

note
	copyright: "Copyright (c) 1984-2026, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"

end
