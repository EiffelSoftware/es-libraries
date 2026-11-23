note
	description: "[
			Eiffel Vision web browser. GTK3 implementation with WebKitGTK (webkit2gtk-4.1 or webkit2gtk-4.0).
			When WebKitGTK is not installed, a label is displayed instead and `is_browser_usable` is False.
		]"
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date$"
	revision: "$Revision$"

class
	EV_WEB_BROWSER_IMP

inherit
	EV_WEB_BROWSER_I
		redefine
			interface
		end

	EV_PRIMITIVE_IMP
		redefine
			interface,
			make
		end

create
	make

feature {NONE} -- Initialization

	make
			-- <Precursor>
		local
			l_label: EV_GTK_C_STRING
		do
				-- Make sure that gtk backend is initialized first.
			app_implementation.do_nothing
			create webkit.make
			if webkit.is_usable then
				set_c_object (webkit.item)
				webkit.register_script_message_handler (message_handler_name)
				webkit.add_user_script (bridge_script)
			else
				create l_label.set_with_eiffel_string ("The web engine (WebKitGTK webkit2gtk-4.1) is not available.")
				set_c_object ({GTK}.gtk_label_new (l_label.item))
			end
			Precursor {EV_PRIMITIVE_IMP}
			if webkit.is_usable then
				real_signal_connect (c_object, "load-changed", agent on_webkit_load_changed)
				real_signal_connect (c_object, "load-failed", agent on_webkit_load_failed)
				real_signal_connect (c_object, "notify::uri", agent on_webkit_uri_changed)
				real_signal_connect (c_object, "notify::title", agent on_webkit_title_changed)
				real_signal_connect (c_object, "decide-policy", agent on_webkit_decide_policy)
				real_signal_connect (webkit.user_content_manager, "script-message-received::" + message_handler_name, agent on_webkit_script_message_received)
			end
		end

	old_make (an_interface: attached like interface)
			-- <Precursor>
		do
			assign_interface (an_interface)
		end

feature -- Status report

	is_browser_usable: BOOLEAN
			-- <Precursor>
		do
			Result := webkit.is_usable
		end

	is_loading: BOOLEAN
			-- <Precursor>
		do
			Result := webkit.is_loading
		end

	can_go_back: BOOLEAN
			-- <Precursor>
		do
			Result := webkit.can_go_back
		end

	can_go_forth: BOOLEAN
			-- <Precursor>
		do
			Result := webkit.can_go_forward
		end

feature -- Access

	uri: detachable READABLE_STRING_32
			-- <Precursor>
		do
			Result := webkit.uri
		end

	title: detachable READABLE_STRING_32
			-- <Precursor>
		do
			Result := webkit.title
		end

	zoom_level: REAL_64
			-- <Precursor>
		do
			Result := webkit.zoom_level
		end

feature -- Element change

	set_zoom_level (a_zoom_level: REAL_64)
			-- <Precursor>
		do
			webkit.set_zoom_level (a_zoom_level)
		end

	set_user_agent (a_user_agent: READABLE_STRING_GENERAL)
			-- <Precursor>
		do
			webkit.set_user_agent (a_user_agent)
		end

	set_developer_tools_enabled (b: BOOLEAN)
			-- <Precursor>
		do
			webkit.set_developer_extras_enabled (b)
		end

feature -- Basic operations

	load_uri (a_uri: READABLE_STRING_GENERAL)
			-- <Precursor>
		do
			webkit.load_uri (a_uri)
		end

	load_html (a_html: READABLE_STRING_GENERAL; a_base_uri: detachable READABLE_STRING_GENERAL)
			-- <Precursor>
		do
			webkit.load_html (a_html, a_base_uri)
		end

	back
			-- <Precursor>
		do
			webkit.go_back
		end

	forth
			-- <Precursor>
		do
			webkit.go_forward
		end

	refresh
			-- <Precursor>
		do
			webkit.reload
		end

	stop
			-- <Precursor>
		do
			webkit.stop_loading
		end

feature -- Scripting

	execute_script (a_script: READABLE_STRING_GENERAL)
			-- <Precursor>
		do
			webkit.run_javascript (a_script)
		end

	add_document_start_script (a_script: READABLE_STRING_GENERAL)
			-- <Precursor>
		do
			webkit.add_user_script (a_script)
		end

feature {EV_ANY, EV_ANY_I} -- Implementation

	interface: detachable EV_WEB_BROWSER note option: stable attribute end
			-- <Precursor>

feature {NONE} -- WebKitGTK signals

	on_webkit_load_changed (n: INTEGER; a_args: POINTER)
			-- "load-changed" (WebKitLoadEvent load_event).
		local
			l_uri: READABLE_STRING_32
		do
			l_uri := current_uri
			inspect {GOBJECT}.g_value_enum ({GOBJECT}.g_value_array_i_th (a_args, 1))
			when {EV_WEBKIT_WEB_VIEW}.load_started then
				has_load_failed := False
				on_load_started (l_uri)
			when {EV_WEBKIT_WEB_VIEW}.load_finished then
				if not has_load_failed then
					on_load_finished (l_uri)
				end
			else
			end
		end

	on_webkit_load_failed (n: INTEGER; a_args: POINTER): BOOLEAN
			-- "load-failed" (WebKitLoadEvent load_event, gchar *failing_uri, GError *error).
			-- Result: True to stop the default handler (error page).
		local
			l_uri: detachable STRING_32
			l_cs: EV_GTK_C_STRING
		do
			has_load_failed := True
			create l_cs.share_from_pointer ({GOBJECT}.g_value_pointer ({GOBJECT}.g_value_array_i_th (a_args, 2)))
			l_uri := l_cs.string
			on_load_failed (l_uri, webkit.error_message ({GOBJECT}.g_value_pointer ({GOBJECT}.g_value_array_i_th (a_args, 3))))
		end

	on_webkit_uri_changed (n: INTEGER; a_args: POINTER)
			-- "notify::uri".
		do
			on_uri_changed (current_uri)
		end

	on_webkit_title_changed (n: INTEGER; a_args: POINTER)
			-- "notify::title".
		do
			if attached webkit.title as t then
				on_title_changed (t)
			else
				on_title_changed ({STRING_32} "")
			end
		end

	on_webkit_decide_policy (n: INTEGER; a_args: POINTER): BOOLEAN
			-- "decide-policy" (WebKitPolicyDecision *decision, WebKitPolicyDecisionType decision_type).
			-- Result: True when the decision is handled.
		local
			l_decision: POINTER
			l_type: INTEGER
		do
			l_decision := {GOBJECT}.g_value_pointer ({GOBJECT}.g_value_array_i_th (a_args, 1))
			l_type := {GOBJECT}.g_value_enum ({GOBJECT}.g_value_array_i_th (a_args, 2))
			if
				(l_type = {EV_WEBKIT_WEB_VIEW}.policy_decision_navigation_action or
				l_type = {EV_WEBKIT_WEB_VIEW}.policy_decision_new_window_action) and then
				attached webkit.navigation_uri (l_decision) as l_uri
			then
				if not is_navigation_allowed (l_uri) then
					webkit.ignore_decision (l_decision)
					Result := True
				elseif l_type = {EV_WEBKIT_WEB_VIEW}.policy_decision_new_window_action then
						-- Open the links targeting a new window in the current view.
					webkit.ignore_decision (l_decision)
					webkit.load_uri (l_uri)
					Result := True
				end
			end
		end

	on_webkit_script_message_received (n: INTEGER; a_args: POINTER)
			-- "script-message-received::eiffel" (JSCValue *value).
		do
			if attached webkit.script_message_string ({GOBJECT}.g_value_array_i_th (a_args, 1)) as m then
				on_message_received (m)
			end
		end

feature {NONE} -- Implementation

	webkit: EV_WEBKIT_WEB_VIEW
			-- WebKitGTK web view.

	has_load_failed: BOOLEAN
			-- Did the current load fail?

	current_uri: READABLE_STRING_32
			-- `uri`, or empty.
		do
			if attached webkit.uri as u then
				Result := u
			else
				Result := {STRING_32} ""
			end
		end

	message_handler_name: STRING_8 = "eiffel"
			-- Name of the script message handler: `window.webkit.messageHandlers.eiffel`.

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
