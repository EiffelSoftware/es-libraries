note
	description: "[
			Eiffel Vision web browser. GTK3 implementation on macOS, with WKWebView.

			The WKWebView is displayed over a GTK drawing area, and follows its position and size.
			It requires the Quartz backend of GDK: with another backend (X11), or without WebKit,
			a label is displayed instead and `is_browser_usable` is False.
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
			make,
			destroy,
			set_focus
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
			webview := c_new (Current, $on_webview_event)
			if not webview.is_default_pointer then
				set_c_object ({GTK}.gtk_drawing_area_new)
				add_document_start_script (bridge_script)
			else
				create l_label.set_with_eiffel_string ("The web engine (WKWebView) requires the Quartz backend of GTK.")
				set_c_object ({GTK}.gtk_label_new (l_label.item))
			end
			Precursor {EV_PRIMITIVE_IMP}
			if not webview.is_default_pointer then
				real_signal_connect (c_object, "size-allocate", agent (n: INTEGER; a: POINTER) do synchronize end)
				real_signal_connect (c_object, "map", agent (n: INTEGER; a: POINTER) do synchronize end)
				real_signal_connect (c_object, "unmap", agent (n: INTEGER; a: POINTER) do synchronize end)
				real_signal_connect (c_object, "hierarchy-changed", agent (n: INTEGER; a: POINTER) do synchronize end)
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
			Result := not webview.is_default_pointer
		end

	is_loading: BOOLEAN
			-- <Precursor>
		do
			Result := c_boolean_query (webview, selector ("isLoading"))
		end

	can_go_back: BOOLEAN
			-- <Precursor>
		do
			Result := c_boolean_query (webview, selector ("canGoBack"))
		end

	can_go_forth: BOOLEAN
			-- <Precursor>
		do
			Result := c_boolean_query (webview, selector ("canGoForward"))
		end

feature -- Access

	uri: detachable READABLE_STRING_32
			-- <Precursor>
		do
			Result := taken_string (c_uri (webview))
		end

	title: detachable READABLE_STRING_32
			-- <Precursor>
		do
			Result := taken_string (c_title (webview))
		end

	zoom_level: REAL_64
			-- <Precursor>
		do
			Result := c_zoom (webview)
		end

feature -- Element change

	set_zoom_level (a_zoom_level: REAL_64)
			-- <Precursor>
		do
			c_set_zoom (webview, a_zoom_level)
		end

	set_user_agent (a_user_agent: READABLE_STRING_GENERAL)
			-- <Precursor>
		do
			c_set_user_agent (webview, (create {EV_GTK_C_STRING}.set_with_eiffel_string (a_user_agent)).item)
		end

	set_developer_tools_enabled (b: BOOLEAN)
			-- <Precursor>
		do
			c_set_developer_tools_enabled (webview, b)
		end

feature -- Basic operations

	load_uri (a_uri: READABLE_STRING_GENERAL)
			-- <Precursor>
		do
			c_load_uri (webview, (create {EV_GTK_C_STRING}.set_with_eiffel_string (a_uri)).item)
		end

	load_html (a_html: READABLE_STRING_GENERAL; a_base_uri: detachable READABLE_STRING_GENERAL)
			-- <Precursor>
		local
			h, b: EV_GTK_C_STRING
		do
			create h.set_with_eiffel_string (a_html)
			if a_base_uri /= Void then
				create b.set_with_eiffel_string (a_base_uri)
				c_load_html (webview, h.item, b.item)
			else
				c_load_html (webview, h.item, default_pointer)
			end
		end

	back
			-- <Precursor>
		do
			c_perform (webview, selector ("goBack"))
		end

	forth
			-- <Precursor>
		do
			c_perform (webview, selector ("goForward"))
		end

	refresh
			-- <Precursor>
		do
			c_perform (webview, selector ("reload"))
		end

	stop
			-- <Precursor>
		do
			c_perform (webview, selector ("stopLoading"))
		end

feature -- Scripting

	execute_script (a_script: READABLE_STRING_GENERAL)
			-- <Precursor>
		do
			c_execute_script (webview, (create {EV_GTK_C_STRING}.set_with_eiffel_string (a_script)).item)
		end

	add_document_start_script (a_script: READABLE_STRING_GENERAL)
			-- <Precursor>
		do
			c_add_document_start_script (webview, (create {EV_GTK_C_STRING}.set_with_eiffel_string (a_script)).item)
		end

feature -- Status setting

	set_focus
			-- <Precursor>
		do
			Precursor {EV_PRIMITIVE_IMP}
			if not webview.is_default_pointer then
				c_set_focus (webview)
			end
		end

feature -- Removal

	destroy
			-- <Precursor>
		do
			if not webview.is_default_pointer then
				c_destroy (webview)
				webview := default_pointer
			end
			Precursor {EV_PRIMITIVE_IMP}
		end

feature {EV_ANY, EV_ANY_I} -- Implementation

	interface: detachable EV_WEB_BROWSER note option: stable attribute end
			-- <Precursor>

feature {NONE} -- WKWebView events

	on_webview_event (a_kind: INTEGER; a_text: POINTER; a_flag: INTEGER): INTEGER
			-- Event `a_kind` of the web view, with the UTF-8 string `a_text` and `a_flag` (see eif_wkwebview.h).
			-- Called by the C code.
		local
			l_text: detachable STRING_32
		do
			if not a_text.is_default_pointer then
				l_text := (create {EV_GTK_C_STRING}.share_from_pointer (a_text)).string
			end
			inspect a_kind
			when Event_load_started then
				on_load_started (current_uri)
			when Event_navigation_requested then
				if l_text /= Void and then not is_navigation_allowed (l_text) then
					Result := 1
				end
			when Event_load_committed then
				notify_changes
			when Event_load_finished then
				notify_changes
				on_load_finished (current_uri)
			when Event_load_failed then
				if l_text /= Void then
					on_load_failed (current_uri, l_text)
				end
			when Event_message_received then
				if l_text /= Void then
					on_message_received (l_text)
				end
			when Event_new_window_requested then
					-- Open the links targeting a new window in the current view.
				if l_text /= Void and then is_navigation_allowed (l_text) then
					load_uri (l_text)
				end
			else
			end
		end

	notify_changes
			-- Call `on_uri_changed` and `on_title_changed` if `uri` or `title` changed since the last call.
		do
			if attached uri as u and then not (attached last_uri as l and then l.same_string (u)) then
				last_uri := u
				on_uri_changed (u)
			end
			if attached title as t and then not (attached last_title as l and then l.same_string (t)) then
				last_title := t
				on_title_changed (t)
			end
		end

feature {NONE} -- Implementation

	webview: POINTER
			-- WKWebView context (see eif_wkwebview.h).

	last_uri, last_title: detachable READABLE_STRING_32
			-- Last `uri` and `title` notified.

	synchronize
			-- Place the web view over the GTK widget.
		do
			if not webview.is_default_pointer then
				c_sync (webview, c_object)
			end
		end

	current_uri: READABLE_STRING_32
			-- `uri`, or empty.
		do
			if attached uri as u then
				Result := u
			else
				Result := {STRING_32} ""
			end
		end

	taken_string (p: POINTER): detachable STRING_32
			-- String of the UTF-8 string `p` allocated by the C code, that is freed.
		do
			if not p.is_default_pointer then
				Result := (create {EV_GTK_C_STRING}.share_from_pointer (p)).string
				c_free (p)
			end
		end

	selector (a_name: STRING_8): POINTER
			-- C string for the Objective-C selector `a_name`.
		local
			l_selectors: like selectors
		do
			l_selectors := selectors
			if attached l_selectors.item (a_name) as s then
				Result := s.item
			else
				l_selectors.put (create {C_STRING}.make (a_name), a_name)
				if attached l_selectors.item (a_name) as s then
					Result := s.item
				end
			end
		end

	selectors: STRING_TABLE [C_STRING]
			-- Cache of `selector`.
		once
			create Result.make (6)
		end

feature {NONE} -- Constants

	Event_load_started: INTEGER = 1
	Event_navigation_requested: INTEGER = 2
	Event_load_finished: INTEGER = 3
	Event_load_failed: INTEGER = 4
	Event_load_committed: INTEGER = 5
	Event_message_received: INTEGER = 6
	Event_new_window_requested: INTEGER = 7
			-- Events of the web view (see eif_wkwebview.h).

feature {NONE} -- Externals

	c_new (a_object: ANY; a_dispatch: POINTER): POINTER
		external
			"C signature (EIF_REFERENCE, EIF_POINTER): EIF_POINTER use %"eif_wkwebview.h%""
		alias
			"eif_wkwebview_new"
		end

	c_destroy (a_webview: POINTER)
		external
			"C signature (eif_wkwebview *) use %"eif_wkwebview.h%""
		alias
			"eif_wkwebview_destroy"
		end

	c_sync (a_webview: POINTER; a_widget: POINTER)
		external
			"C signature (eif_wkwebview *, EIF_POINTER) use %"eif_wkwebview.h%""
		alias
			"eif_wkwebview_sync"
		end

	c_set_focus (a_webview: POINTER)
		external
			"C signature (eif_wkwebview *) use %"eif_wkwebview.h%""
		alias
			"eif_wkwebview_set_focus"
		end

	c_load_uri (a_webview: POINTER; a_uri: POINTER)
		external
			"C signature (eif_wkwebview *, EIF_POINTER) use %"eif_wkwebview.h%""
		alias
			"eif_wkwebview_load_uri"
		end

	c_load_html (a_webview: POINTER; a_html, a_base_uri: POINTER)
		external
			"C signature (eif_wkwebview *, EIF_POINTER, EIF_POINTER) use %"eif_wkwebview.h%""
		alias
			"eif_wkwebview_load_html"
		end

	c_execute_script (a_webview: POINTER; a_script: POINTER)
		external
			"C signature (eif_wkwebview *, EIF_POINTER) use %"eif_wkwebview.h%""
		alias
			"eif_wkwebview_execute_script"
		end

	c_add_document_start_script (a_webview: POINTER; a_script: POINTER)
		external
			"C signature (eif_wkwebview *, EIF_POINTER) use %"eif_wkwebview.h%""
		alias
			"eif_wkwebview_add_document_start_script"
		end

	c_perform (a_webview: POINTER; a_selector: POINTER)
		external
			"C signature (eif_wkwebview *, EIF_POINTER) use %"eif_wkwebview.h%""
		alias
			"eif_wkwebview_perform"
		end

	c_boolean_query (a_webview: POINTER; a_selector: POINTER): BOOLEAN
		external
			"C signature (eif_wkwebview *, EIF_POINTER): EIF_BOOLEAN use %"eif_wkwebview.h%""
		alias
			"eif_wkwebview_boolean_query"
		end

	c_title (a_webview: POINTER): POINTER
		external
			"C signature (eif_wkwebview *): EIF_POINTER use %"eif_wkwebview.h%""
		alias
			"eif_wkwebview_title"
		end

	c_uri (a_webview: POINTER): POINTER
		external
			"C signature (eif_wkwebview *): EIF_POINTER use %"eif_wkwebview.h%""
		alias
			"eif_wkwebview_uri"
		end

	c_free (p: POINTER)
		external
			"C signature (void *) use <stdlib.h>"
		alias
			"free"
		end

	c_zoom (a_webview: POINTER): REAL_64
		external
			"C signature (eif_wkwebview *): EIF_REAL_64 use %"eif_wkwebview.h%""
		alias
			"eif_wkwebview_zoom"
		end

	c_set_zoom (a_webview: POINTER; a_zoom: REAL_64)
		external
			"C signature (eif_wkwebview *, EIF_REAL_64) use %"eif_wkwebview.h%""
		alias
			"eif_wkwebview_set_zoom"
		end

	c_set_user_agent (a_webview: POINTER; a_user_agent: POINTER)
		external
			"C signature (eif_wkwebview *, EIF_POINTER) use %"eif_wkwebview.h%""
		alias
			"eif_wkwebview_set_user_agent"
		end

	c_set_developer_tools_enabled (a_webview: POINTER; b: BOOLEAN)
		external
			"C signature (eif_wkwebview *, EIF_BOOLEAN) use %"eif_wkwebview.h%""
		alias
			"eif_wkwebview_set_developer_tools_enabled"
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
