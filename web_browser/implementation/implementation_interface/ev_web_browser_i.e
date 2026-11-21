note
	description: "[
			Eiffel Vision web browser.
			Implementation interface.

			Platform-independent part: action sequences, navigation handler, and the JavaScript bridge.
			The page sends string messages to the application with `window.eiffel.postMessage`,
			that calls the native channel of the web engine:
				- `window.chrome.webview.postMessage` (WebView2),
				- `window.webkit.messageHandlers.eiffel.postMessage` (WebKitGTK, WKWebView).
			`evaluate_script` is built on `execute_script` and this channel, so that every implementation
			only needs to execute a script and to forward the received messages to `on_message_received`.
		]"
	legal: "See notice at end of class."
	status: "See notice at end of class."
	keywords: "web, browser, html, webview, javascript"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	EV_WEB_BROWSER_I

inherit
	EV_PRIMITIVE_I
		redefine
			interface
		end

feature {EV_ANY, EV_ANY_I} -- Implementation

	interface: detachable EV_WEB_BROWSER note option: stable attribute end
			-- <Precursor>

feature -- Status report

	is_browser_usable: BOOLEAN
			-- Is the web engine available and initialized?
		deferred
		end

	is_loading: BOOLEAN
			-- Is a page being loaded?
		require
			is_browser_usable: is_browser_usable
		deferred
		end

	can_go_back: BOOLEAN
			-- Is there a previous page in the history?
		require
			is_browser_usable: is_browser_usable
		deferred
		end

	can_go_forth: BOOLEAN
			-- Is there a next page in the history?
		require
			is_browser_usable: is_browser_usable
		deferred
		end

feature -- Access

	uri: detachable READABLE_STRING_32
			-- URI of the current page, if any.
		require
			is_browser_usable: is_browser_usable
		deferred
		end

	title: detachable READABLE_STRING_32
			-- Title of the current page, if any.
		require
			is_browser_usable: is_browser_usable
		deferred
		end

	zoom_level: REAL_64
			-- Zoom factor of the page (1.0 means 100%).
		require
			is_browser_usable: is_browser_usable
		deferred
		end

	home_uri: READABLE_STRING_32
			-- URI loaded by `home`.
		do
			if attached home_uri_internal as l_uri then
				Result := l_uri
			else
				Result := default_home_uri
			end
		end

	navigation_handler: detachable PREDICATE [TUPLE [uri: READABLE_STRING_32]]
			-- Function deciding whether the page is allowed to navigate to a given URI.
			-- Void means every navigation is allowed.

feature -- Element change

	set_zoom_level (a_zoom_level: REAL_64)
			-- Set `zoom_level` to `a_zoom_level`.
		require
			is_browser_usable: is_browser_usable
			a_zoom_level_positive: a_zoom_level > 0
		deferred
		end

	set_user_agent (a_user_agent: READABLE_STRING_GENERAL)
			-- Use `a_user_agent` as user agent for the next requests.
		require
			is_browser_usable: is_browser_usable
			a_user_agent_not_empty: not a_user_agent.is_empty
		deferred
		end

	set_developer_tools_enabled (b: BOOLEAN)
			-- Enable (if `b`) or disable the developer tools of the page.
		require
			is_browser_usable: is_browser_usable
		deferred
		end

	set_home_uri (a_uri: READABLE_STRING_GENERAL)
			-- Set `home_uri` to `a_uri`.
		require
			a_uri_not_empty: not a_uri.is_empty
		do
			create home_uri_internal.make_from_string_general (a_uri)
		ensure
			home_uri_set: home_uri.same_string_general (a_uri)
		end

	set_navigation_handler (a_handler: like navigation_handler)
			-- Set `navigation_handler` to `a_handler`.
		do
			navigation_handler := a_handler
		ensure
			navigation_handler_set: navigation_handler = a_handler
		end

feature -- Basic operations

	load_uri (a_uri: READABLE_STRING_GENERAL)
			-- Request the loading of `a_uri`.
		require
			is_browser_usable: is_browser_usable
			not_empty: a_uri /= Void and then not a_uri.is_empty
		deferred
		end

	load_html (a_html: READABLE_STRING_GENERAL; a_base_uri: detachable READABLE_STRING_GENERAL)
			-- Display the HTML document `a_html`, resolving relative URIs against `a_base_uri` if set.
		require
			is_browser_usable: is_browser_usable
			a_base_uri_not_empty: a_base_uri /= Void implies not a_base_uri.is_empty
		deferred
		end

	back
			-- Go to the previous page in the history.
		require
			is_browser_usable: is_browser_usable
		deferred
		end

	forth
			-- Go to the next page in the history.
		require
			is_browser_usable: is_browser_usable
		deferred
		end

	home
			-- Load `home_uri`.
		require
			is_browser_usable: is_browser_usable
		do
			load_uri (home_uri)
		end

	refresh
			-- Reload the current page.
		require
			is_browser_usable: is_browser_usable
		deferred
		end

	stop
			-- Stop loading the current page.
		require
			is_browser_usable: is_browser_usable
		deferred
		end

feature -- Scripting

	execute_script (a_script: READABLE_STRING_GENERAL)
			-- Execute the JavaScript code `a_script` in the current page, ignoring its result.
		require
			is_browser_usable: is_browser_usable
			a_script_not_empty: not a_script.is_empty
		deferred
		end

	evaluate_script (a_script: READABLE_STRING_GENERAL; a_handler: PROCEDURE [TUPLE [json_value: detachable READABLE_STRING_32; error: detachable READABLE_STRING_32]])
			-- Evaluate the JavaScript expression `a_script` in the current page,
			-- then call `a_handler` with the JSON representation of its value, or with the error message.
		require
			is_browser_usable: is_browser_usable
			a_script_not_empty: not a_script.is_empty
		local
			l_id: INTEGER
			s: STRING_32
		do
			last_evaluation_id := last_evaluation_id + 1
			l_id := last_evaluation_id
			pending_evaluations.force (a_handler, l_id)
			create s.make_from_string_general (evaluation_script_template)
			s.replace_substring_all ({STRING_32} "$SEND", bridge_send_function)
			s.replace_substring_all ({STRING_32} "$PREFIX", js_string_literal (evaluation_result_prefix))
			s.replace_substring_all ({STRING_32} "$ID", l_id.out)
				-- Last, as `a_script` may contain the other place holders.
			s.replace_substring_all ({STRING_32} "$SCRIPT", js_string_literal (a_script))
			execute_script (s)
		ensure
			evaluation_pending: pending_evaluations.has (last_evaluation_id)
		end

	add_document_start_script (a_script: READABLE_STRING_GENERAL)
			-- Execute the JavaScript code `a_script` at the start of every page loaded from now on.
		require
			is_browser_usable: is_browser_usable
			a_script_not_empty: not a_script.is_empty
		deferred
		end

feature -- Events

	load_started_actions: EV_LITE_ACTION_SEQUENCE [TUPLE [uri: READABLE_STRING_32]]
			-- Actions performed when the loading of a page starts.
		do
			if attached load_started_actions_internal as l_result then
				Result := l_result
			else
				create Result
				load_started_actions_internal := Result
			end
		end

	load_finished_actions: EV_LITE_ACTION_SEQUENCE [TUPLE [uri: READABLE_STRING_32]]
			-- Actions performed when a page is loaded.
		do
			if attached load_finished_actions_internal as l_result then
				Result := l_result
			else
				create Result
				load_finished_actions_internal := Result
			end
		end

	load_failed_actions: EV_LITE_ACTION_SEQUENCE [TUPLE [uri: READABLE_STRING_32; error: READABLE_STRING_32]]
			-- Actions performed when the loading of a page fails.
		do
			if attached load_failed_actions_internal as l_result then
				Result := l_result
			else
				create Result
				load_failed_actions_internal := Result
			end
		end

	uri_changed_actions: EV_LITE_ACTION_SEQUENCE [TUPLE [uri: READABLE_STRING_32]]
			-- Actions performed when `uri` changes.
		do
			if attached uri_changed_actions_internal as l_result then
				Result := l_result
			else
				create Result
				uri_changed_actions_internal := Result
			end
		end

	title_changed_actions: EV_LITE_ACTION_SEQUENCE [TUPLE [title: READABLE_STRING_32]]
			-- Actions performed when `title` changes.
		do
			if attached title_changed_actions_internal as l_result then
				Result := l_result
			else
				create Result
				title_changed_actions_internal := Result
			end
		end

	message_received_actions: EV_LITE_ACTION_SEQUENCE [TUPLE [message: READABLE_STRING_32]]
			-- Actions performed when the page sends a message with `window.eiffel.postMessage`.
		do
			if attached message_received_actions_internal as l_result then
				Result := l_result
			else
				create Result
				message_received_actions_internal := Result
			end
		end

feature {NONE} -- Event handling (for implementations)

	on_load_started (a_uri: READABLE_STRING_32)
			-- The loading of `a_uri` started.
		do
			if attached load_started_actions_internal as l_actions then
				l_actions.call ([a_uri])
			end
		end

	on_load_finished (a_uri: READABLE_STRING_32)
			-- The page `a_uri` is loaded.
		do
			if attached load_finished_actions_internal as l_actions then
				l_actions.call ([a_uri])
			end
		end

	on_load_failed (a_uri: READABLE_STRING_32; a_error: READABLE_STRING_32)
			-- The loading of `a_uri` failed with `a_error`.
		do
			if attached load_failed_actions_internal as l_actions then
				l_actions.call ([a_uri, a_error])
			end
		end

	on_uri_changed (a_uri: READABLE_STRING_32)
			-- `uri` changed to `a_uri`.
		do
			if attached uri_changed_actions_internal as l_actions then
				l_actions.call ([a_uri])
			end
		end

	on_title_changed (a_title: READABLE_STRING_32)
			-- `title` changed to `a_title`.
		do
			if attached title_changed_actions_internal as l_actions then
				l_actions.call ([a_title])
			end
		end

	on_message_received (a_message: READABLE_STRING_32)
			-- The page sent `a_message` through the native channel:
			-- either the result of an `evaluate_script`, or a message for `message_received_actions`.
		local
			i, j: INTEGER
			l_id: INTEGER
			l_ok: BOOLEAN
			l_payload: STRING_32
		do
			if a_message.starts_with (evaluation_result_prefix) then
					-- Format: prefix + id + ":" + ("1" | "0") + payload
				i := evaluation_result_prefix.count + 1
				j := a_message.index_of (':', i)
				if j > i and j < a_message.count then
					if attached a_message.substring (i, j - 1) as l_id_string and then l_id_string.is_integer then
						l_id := l_id_string.to_integer
						l_ok := a_message [j + 1] = '1'
						l_payload := a_message.substring (j + 2, a_message.count)
						if attached pending_evaluations.item (l_id) as l_handler then
							pending_evaluations.remove (l_id)
							if l_ok then
								l_handler.call ([l_payload, Void])
							else
								l_handler.call ([Void, l_payload])
							end
						end
					end
				end
			elseif attached message_received_actions_internal as l_actions then
				l_actions.call ([a_message])
			end
		end

	is_navigation_allowed (a_uri: READABLE_STRING_32): BOOLEAN
			-- Is the navigation to `a_uri` allowed by `navigation_handler`?
		do
			Result := attached navigation_handler as h implies h.item ([a_uri])
		end

feature {NONE} -- JavaScript bridge

	bridge_script: STRING_32
			-- Script defining `window.eiffel`, to add at the start of every page.
		do
			create Result.make_from_string_general ("[
				(function () {
					if (window.eiffel) { return; }
					var send = $SEND;
					Object.defineProperty (window, "eiffel", {
						value: Object.freeze ({
							postMessage: function (m) { send (typeof m === "string" ? m : JSON.stringify (m)); }
						})
					});
				}) ();
			]")
			Result.replace_substring_all ({STRING_32} "$SEND", bridge_send_function)
		end

	bridge_send_function: STRING_32
			-- JavaScript function sending a string to the application through the native channel.
		once
			create Result.make_from_string_general ("[
				function (s) {
					if (window.chrome && window.chrome.webview) {
						window.chrome.webview.postMessage (s);
					} else if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.eiffel) {
						window.webkit.messageHandlers.eiffel.postMessage (s);
					}
				}
			]")
		end

	evaluation_script_template: STRING_32
			-- Script evaluating $SCRIPT in the global scope, and replying $PREFIX + $ID + ":" + result.
		once
			create Result.make_from_string_general ("[
				(function () {
					var send = $SEND;
					var reply = function (ok, s) { send ($PREFIX + "$ID:" + (ok ? "1" : "0") + s); };
					try {
						Promise.resolve ((0, eval) ($SCRIPT)).then (
							function (v) {
								try {
									var j = JSON.stringify (v);
									reply (true, j === undefined ? "null" : j);
								} catch (e) { reply (false, String (e)); }
							},
							function (e) { reply (false, String (e)); }
						);
					} catch (e) { reply (false, String (e)); }
				}) ();
			]")
		end

	evaluation_result_prefix: STRING_32
			-- Prefix of the messages carrying the result of an `evaluate_script`.
		once
			Result := {STRING_32} "%/1/eiffel:result:"
		end

	js_string_literal (s: READABLE_STRING_GENERAL): STRING_32
			-- JavaScript string literal (with quotes) for `s`.
		local
			i, n: INTEGER
			c: NATURAL_32
		do
			n := s.count
			create Result.make (n + 10)
			Result.append_character ('"')
			from
				i := 1
			until
				i > n
			loop
				c := s.code (i)
				inspect c
				when 0x22 then
					Result.append ({STRING_32} "\%"")
				when 0x5C then
					Result.append ({STRING_32} "\\")
				when 0x0A then
					Result.append ({STRING_32} "\n")
				when 0x0D then
					Result.append ({STRING_32} "\r")
				when 0x2028, 0x2029 then
					Result.append ({STRING_32} "\u")
					Result.append (c.to_hex_string.substring (5, 8).as_lower)
				when 0 .. 0x09, 0x0B, 0x0C, 0x0E .. 0x1F, 0x7F then
					Result.append ({STRING_32} "\u00")
					Result.append (c.to_hex_string.substring (7, 8).as_lower)
				else
					Result.append_code (c)
				end
				i := i + 1
			end
			Result.append_character ('"')
		end

feature {NONE} -- Implementation

	default_home_uri: STRING_32 = "about:blank"
			-- Default value of `home_uri`.

	home_uri_internal: detachable STRING_32
			-- Value of `home_uri` set by `set_home_uri`.

	pending_evaluations: HASH_TABLE [PROCEDURE [TUPLE [json_value: detachable READABLE_STRING_32; error: detachable READABLE_STRING_32]], INTEGER]
			-- Handlers of the `evaluate_script` calls waiting for their result, indexed by evaluation id.
		do
			if attached pending_evaluations_internal as l_result then
				Result := l_result
			else
				create Result.make (1)
				pending_evaluations_internal := Result
			end
		end

	pending_evaluations_internal: detachable like pending_evaluations
			-- Once per object `pending_evaluations`.

	last_evaluation_id: INTEGER
			-- Id of the last `evaluate_script` call.

	load_started_actions_internal: detachable like load_started_actions
			-- Once per object `load_started_actions`.

	load_finished_actions_internal: detachable like load_finished_actions
			-- Once per object `load_finished_actions`.

	load_failed_actions_internal: detachable like load_failed_actions
			-- Once per object `load_failed_actions`.

	uri_changed_actions_internal: detachable like uri_changed_actions
			-- Once per object `uri_changed_actions`.

	title_changed_actions_internal: detachable like title_changed_actions
			-- Once per object `title_changed_actions`.

	message_received_actions_internal: detachable like message_received_actions
			-- Once per object `message_received_actions`.

;note
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
