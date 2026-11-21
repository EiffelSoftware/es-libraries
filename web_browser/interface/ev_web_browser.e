note
	description: "[
			Eiffel Vision2 widget displaying web content with the web engine of the platform:
				- Windows: Microsoft Edge WebView2,
				- Linux (GTK3): WebKitGTK,
				- macOS (GTK3 on Quartz): WKWebView.

			Pages can exchange messages with the Eiffel application:
				- from the page: `window.eiffel.postMessage (value)`, received through `message_received_actions`
				  (a value that is not a string is sent as its JSON representation);
				- from the application: `execute_script` and `evaluate_script`.
		]"
	legal: "See notice at end of class."
	status: "See notice at end of class."
	keywords: "web, browser, html, webview, javascript"
	date: "$Date$"
	revision: "$Revision$"

class
	EV_WEB_BROWSER

inherit
	EV_PRIMITIVE
		redefine
			implementation
		end

feature -- Status report

	is_browser_usable: BOOLEAN
			-- Is the web engine available on this platform and initialized?
			-- When False, no web content can be displayed (for instance, the run-time
			-- of the web engine is not installed).
		do
			Result := implementation.is_browser_usable
		end

	is_loading: BOOLEAN
			-- Is a page being loaded?
		require
			is_browser_usable: is_browser_usable
		do
			Result := implementation.is_loading
		end

	can_go_back: BOOLEAN
			-- Is there a previous page in the history?
		require
			is_browser_usable: is_browser_usable
		do
			Result := implementation.can_go_back
		end

	can_go_forth: BOOLEAN
			-- Is there a next page in the history?
		require
			is_browser_usable: is_browser_usable
		do
			Result := implementation.can_go_forth
		end

feature -- Access

	uri: detachable READABLE_STRING_32
			-- URI of the current page, if any.
		require
			is_browser_usable: is_browser_usable
		do
			Result := implementation.uri
		end

	title: detachable READABLE_STRING_32
			-- Title of the current page, if any.
		require
			is_browser_usable: is_browser_usable
		do
			Result := implementation.title
		end

	zoom_level: REAL_64
			-- Zoom factor of the page (1.0 means 100%).
		require
			is_browser_usable: is_browser_usable
		do
			Result := implementation.zoom_level
		end

	home_uri: READABLE_STRING_32
			-- URI loaded by `home`.
		do
			Result := implementation.home_uri
		end

	navigation_handler: detachable PREDICATE [TUPLE [uri: READABLE_STRING_32]]
			-- Function deciding whether the page is allowed to navigate to a given URI.
			-- Void means every navigation is allowed.
		do
			Result := implementation.navigation_handler
		end

feature -- Element change

	set_zoom_level (a_zoom_level: REAL_64)
			-- Set `zoom_level` to `a_zoom_level`.
		require
			is_browser_usable: is_browser_usable
			a_zoom_level_positive: a_zoom_level > 0
		do
			implementation.set_zoom_level (a_zoom_level)
		end

	set_user_agent (a_user_agent: READABLE_STRING_GENERAL)
			-- Use `a_user_agent` as user agent for the next requests.
		require
			is_browser_usable: is_browser_usable
			a_user_agent_not_empty: not a_user_agent.is_empty
		do
			implementation.set_user_agent (a_user_agent)
		end

	set_developer_tools_enabled (b: BOOLEAN)
			-- Enable (if `b`) or disable the developer tools (web inspector) of the page.
		require
			is_browser_usable: is_browser_usable
		do
			implementation.set_developer_tools_enabled (b)
		end

	set_home_uri (a_uri: READABLE_STRING_GENERAL)
			-- Set `home_uri` to `a_uri`.
		require
			a_uri_not_empty: not a_uri.is_empty
		do
			implementation.set_home_uri (a_uri)
		ensure
			home_uri_set: home_uri.same_string_general (a_uri)
		end

	set_navigation_handler (a_handler: like navigation_handler)
			-- Set `navigation_handler` to `a_handler`.
			-- `a_handler` is called with the requested URI before the page navigates
			-- (link, form, script, `load_uri` ...) and returns True to allow the navigation.
		do
			implementation.set_navigation_handler (a_handler)
		ensure
			navigation_handler_set: navigation_handler = a_handler
		end

feature -- Basic operations

	load_uri (a_uri: READABLE_STRING_GENERAL)
			-- Request the loading of `a_uri`.
		require
			is_browser_usable: is_browser_usable
			not_empty: a_uri /= Void and then not a_uri.is_empty
		do
			implementation.load_uri (a_uri)
		end

	load_html (a_html: READABLE_STRING_GENERAL; a_base_uri: detachable READABLE_STRING_GENERAL)
			-- Display the HTML document `a_html`.
			-- Relative URIs of the document are resolved against `a_base_uri` if set.
			-- Note: depending on the platform, a document without `a_base_uri` may not be
			-- allowed to load local files, and the document may not be recorded in the history.
		require
			is_browser_usable: is_browser_usable
			a_base_uri_not_empty: a_base_uri /= Void implies not a_base_uri.is_empty
		do
			implementation.load_html (a_html, a_base_uri)
		end

	back
			-- Go to the previous page in the history.
		require
			is_browser_usable: is_browser_usable
		do
			implementation.back
		end

	forth
			-- Go to the next page in the history.
		require
			is_browser_usable: is_browser_usable
		do
			implementation.forth
		end

	home
			-- Load `home_uri`.
		require
			is_browser_usable: is_browser_usable
		do
			implementation.home
		end

	search
			-- Load `home_uri`.
		obsolete
			"Use `load_uri` with the URI of a search engine. [2027-05-21]"
		require
			is_browser_usable: is_browser_usable
		do
			implementation.home
		end

	refresh
			-- Reload the current page.
		require
			is_browser_usable: is_browser_usable
		do
			implementation.refresh
		end

	stop
			-- Stop loading the current page.
		require
			is_browser_usable: is_browser_usable
		do
			implementation.stop
		end

feature -- Scripting

	execute_script (a_script: READABLE_STRING_GENERAL)
			-- Execute the JavaScript code `a_script` in the current page, ignoring its result.
		require
			is_browser_usable: is_browser_usable
			a_script_not_empty: not a_script.is_empty
		do
			implementation.execute_script (a_script)
		end

	evaluate_script (a_script: READABLE_STRING_GENERAL; a_handler: PROCEDURE [TUPLE [json_value: detachable READABLE_STRING_32; error: detachable READABLE_STRING_32]])
			-- Evaluate the JavaScript expression `a_script` in the current page, then call `a_handler`
			-- asynchronously with either the JSON representation of the value of `a_script`
			-- (the value of a promise once resolved; "null" for undefined) and no error,
			-- or no value and the error message.
			-- `a_handler` is not called if the page is replaced before the evaluation completes.
		require
			is_browser_usable: is_browser_usable
			a_script_not_empty: not a_script.is_empty
		do
			implementation.evaluate_script (a_script, a_handler)
		end

	add_document_start_script (a_script: READABLE_STRING_GENERAL)
			-- Execute the JavaScript code `a_script` at the start of every page loaded from now on,
			-- before the scripts of the page.
		require
			is_browser_usable: is_browser_usable
			a_script_not_empty: not a_script.is_empty
		do
			implementation.add_document_start_script (a_script)
		end

feature -- Events

	load_started_actions: EV_LITE_ACTION_SEQUENCE [TUPLE [uri: READABLE_STRING_32]]
			-- Actions performed when the loading of a page starts.
		do
			Result := implementation.load_started_actions
		end

	load_finished_actions: EV_LITE_ACTION_SEQUENCE [TUPLE [uri: READABLE_STRING_32]]
			-- Actions performed when a page is loaded.
		do
			Result := implementation.load_finished_actions
		end

	load_failed_actions: EV_LITE_ACTION_SEQUENCE [TUPLE [uri: READABLE_STRING_32; error: READABLE_STRING_32]]
			-- Actions performed when the loading of a page fails.
		do
			Result := implementation.load_failed_actions
		end

	uri_changed_actions: EV_LITE_ACTION_SEQUENCE [TUPLE [uri: READABLE_STRING_32]]
			-- Actions performed when `uri` changes.
		do
			Result := implementation.uri_changed_actions
		end

	title_changed_actions: EV_LITE_ACTION_SEQUENCE [TUPLE [title: READABLE_STRING_32]]
			-- Actions performed when `title` changes.
		do
			Result := implementation.title_changed_actions
		end

	message_received_actions: EV_LITE_ACTION_SEQUENCE [TUPLE [message: READABLE_STRING_32]]
			-- Actions performed when the page sends a message with `window.eiffel.postMessage`.
		do
			Result := implementation.message_received_actions
		end

feature {EV_ANY, EV_ANY_I} -- Implementation

	implementation: EV_WEB_BROWSER_I
			-- Responsible for interaction with native graphics toolkit.

feature {NONE} -- Implementation

	create_implementation
			-- <Precursor>
		do
			create {EV_WEB_BROWSER_IMP} implementation.make
		end

note
	copyright:	"Copyright (c) 1984-2026, Eiffel Software and others"
	license:	"Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"

end
