note
	description: "[
			Eiffel Vision web browser. MS Windows implementation with Microsoft Edge WebView2.
			The web view is created asynchronously: the operations requested before it is ready
			are performed once it is ready.
		]"
	legal: "See notice at end of class."
	status: "See notice at end of class."
	keywords: "web, browser, html, webview, javascript"
	date: "$Date$"
	revision: "$Revision$"

class
	EV_WEB_BROWSER_IMP

inherit
	EV_WEB_BROWSER_I
		redefine
			interface
		end

	EV_WIDGET_IMP
		undefine
			is_tabable_from,
			destroy
		redefine
			interface,
			on_size,
			on_set_focus,
			make
		end

	EV_SIZEABLE_PRIMITIVE_IMP
		redefine
			interface
		end

	EV_PRIMITIVE_IMP
		redefine
			interface,
			on_size,
			on_set_focus,
			destroy,
			make
		end

	WEL_WINDOW
		rename
			parent as wel_parent,
			enabled as is_sensitive,
			move as wel_move,
			resize as wel_resize,
			shown as is_displayed,
			destroy as wel_destroy,
			set_parent as wel_set_parent,
			has_capture as wel_has_capture,
			move_and_resize as wel_move_and_resize,
			width as wel_width,
			height as wel_height,
			item as wel_item
		undefine
			on_left_button_up,
			on_left_button_down,
			on_left_button_double_click,
			on_middle_button_up,
			on_middle_button_down,
			on_middle_button_double_click,
			on_right_button_up,
			on_right_button_down,
			on_right_button_double_click,
			on_mouse_move,
			on_mouse_wheel,
			on_wm_dropfiles,
			on_key_up,
			on_key_down,
			on_sys_key_up,
			on_sys_key_down,
			set_width,
			set_height,
			on_set_focus,
			on_kill_focus,
			on_set_cursor,
			on_size,
			on_char,
			on_desactivate,
			on_getdlgcode,
			show,
			hide,
			default_process_message
		redefine
			on_destroy
		end

	WEL_CS_CONSTANTS

	WEL_COLOR_CONSTANTS

	WEL_IDC_CONSTANTS

create
	make

feature {NONE} -- Initialization

	make
			-- <Precursor>
		local
			l_action: PROCEDURE
		do
			create pending_operations.make (4)
			pending_zoom_level := 1.0
			register_class
			internal_window_make (default_parent, "", default_style, 0, 0, 0, 0, 0, default_pointer)
			initialize_sizeable
			Precursor
			webview := c_webview2_new (wel_item, Current, $on_webview2_event)
			if webview.is_default_pointer then
				has_creation_failed := True
			else
				add_document_start_script (bridge_script)
				l_action := agent close_webview
				application_destroy_action := l_action
				application_imp.destroy_actions.extend (l_action)
			end
		end

	old_make (an_interface: attached like interface)
			-- <Precursor>
		do
			check never_used: False end -- Just because {EV_ANY_I} has it as deferred feature
		end

feature {NONE} -- Window class register

	register_class
			-- Register the window class if the class is not already registered.
		do
			create wnd_class.make (class_name)
			if not wnd_class.registered then
				wnd_class.set_style (class_style)
				wnd_class.set_window_procedure (class_window_procedure)
				wnd_class.set_cursor (class_cursor)
				if
					background_brush = Void and then
					class_background /= Void
				then
					wnd_class.set_background (class_background)
				end
				wnd_class.set_menu_name (class_menu_name)
				wnd_class.register
			end
		end

	wnd_class: WEL_WND_CLASS
			-- Associated windows class of current window.

	class_style: INTEGER
			-- Standard style used to create the window class.
		once
			Result := Cs_dblclks
		end

	class_window_procedure: POINTER
			-- Standard window procedure
		once
			Result := cwel_window_procedure_address
		ensure
			result_not_null: Result /= default_pointer
		end

	class_cursor: WEL_CURSOR
			-- Standard arrow cursor used to create the window class.
		once
			create Result.make_by_predefined_id (Idc_arrow)
		ensure
			result_not_void: Result /= Void
			result_exists: Result.exists
		end

	class_background: WEL_BRUSH
			-- Standard window background color used to create the window class.
		require
			background_brush_not_set: background_brush = Void
		once
			create Result.make_by_sys_color (Color_window + 1)
		ensure
			result_not_void: Result /= Void
		end

	class_menu_name: STRING_32
			-- Window's menu used to create the window class (none).
		once
			create Result.make (0)
		ensure
			result_not_void: Result /= Void
		end

feature -- Status report

	is_browser_usable: BOOLEAN
			-- <Precursor>
			-- True while the web view is being created, False if its creation failed
			-- (for instance when the WebView2 Runtime is not installed).
		do
			Result := not has_creation_failed
		end

	is_loading: BOOLEAN
			-- <Precursor>

	can_go_back: BOOLEAN
			-- <Precursor>
		do
			Result := is_ready and then c_webview2_can_go_back (webview)
		end

	can_go_forth: BOOLEAN
			-- <Precursor>
		do
			Result := is_ready and then c_webview2_can_go_forward (webview)
		end

feature -- Access

	uri: detachable READABLE_STRING_32
			-- <Precursor>
		do
			if attached html_base_uri as l_base_uri then
				Result := l_base_uri
			elseif is_ready then
				Result := taken_string (c_webview2_source (webview))
			end
		end

	title: detachable READABLE_STRING_32
			-- <Precursor>
		do
			if is_ready then
				Result := taken_string (c_webview2_title (webview))
			end
		end

	zoom_level: REAL_64
			-- <Precursor>
		do
			if is_ready then
				Result := c_webview2_zoom_factor (webview)
			else
				Result := pending_zoom_level
			end
		end

feature -- Element change

	set_zoom_level (a_zoom_level: REAL_64)
			-- <Precursor>
		do
			if is_ready then
				c_webview2_set_zoom_factor (webview, a_zoom_level)
			else
				pending_zoom_level := a_zoom_level
				pending_operations.extend (agent c_webview2_set_zoom_factor (webview, a_zoom_level))
			end
		end

	set_user_agent (a_user_agent: READABLE_STRING_GENERAL)
			-- <Precursor>
		do
			perform (agent (s: READABLE_STRING_GENERAL)
				do
					c_webview2_set_user_agent (webview, (create {WEL_STRING}.make (s)).item)
				end (a_user_agent.twin))
		end

	set_developer_tools_enabled (b: BOOLEAN)
			-- <Precursor>
		do
			perform (agent c_webview2_set_dev_tools_enabled (webview, b))
		end

feature -- Basic operations

	load_uri (a_uri: READABLE_STRING_GENERAL)
			-- <Precursor>
		do
			perform (agent (s: READABLE_STRING_GENERAL)
				do
					c_webview2_navigate (webview, (create {WEL_STRING}.make (s)).item)
				end (a_uri.twin))
		end

	load_html (a_html: READABLE_STRING_GENERAL; a_base_uri: detachable READABLE_STRING_GENERAL)
			-- <Precursor>
			-- Note: WebView2 does not support a base URI for a document given as a string:
			-- a `<base>` element is inserted at the start of the document instead,
			-- and `uri` is `a_base_uri` while the document is displayed (as with the other engines).
		local
			s: STRING_32
			b: detachable STRING_32
		do
			create s.make (a_html.count + 50)
			if a_base_uri /= Void then
				s.append_string_general ("<base href=%"")
				s.append_string_general (html_attribute_escaped (a_base_uri))
				s.append_string_general ("%">")
				create b.make_from_string_general (a_base_uri)
			end
			s.append_string_general (a_html)
			perform (agent (h: READABLE_STRING_GENERAL; a_base: detachable STRING_32)
				do
					is_loading_html := True
					pending_html_base_uri := a_base
					c_webview2_navigate_to_string (webview, (create {WEL_STRING}.make (h)).item)
				end (s, b))
		end

	back
			-- <Precursor>
		do
			perform (agent c_webview2_go_back (webview))
		end

	forth
			-- <Precursor>
		do
			perform (agent c_webview2_go_forward (webview))
		end

	refresh
			-- <Precursor>
		do
			perform (agent c_webview2_reload (webview))
		end

	stop
			-- <Precursor>
		do
			perform (agent c_webview2_stop (webview))
		end

feature -- Scripting

	execute_script (a_script: READABLE_STRING_GENERAL)
			-- <Precursor>
		do
			perform (agent (s: READABLE_STRING_GENERAL)
				do
					c_webview2_execute_script (webview, (create {WEL_STRING}.make (s)).item)
				end (a_script.twin))
		end

	add_document_start_script (a_script: READABLE_STRING_GENERAL)
			-- <Precursor>
		do
			perform (agent (s: READABLE_STRING_GENERAL)
				do
					c_webview2_add_document_start_script (webview, (create {WEL_STRING}.make (s)).item)
				end (a_script.twin))
		end

feature -- Removal

	destroy
			-- <Precursor>
		do
			close_webview
			Precursor {EV_PRIMITIVE_IMP}
		end

feature {NONE} -- Removal

	close_webview
			-- Close the web view, if not yet closed: `is_browser_usable` becomes False.
			-- Called when `Current` or its window is destroyed, and when the application ends
			-- (`{EV_APPLICATION}.destroy` does not destroy the windows: without this, WebView2
			-- would still have windows when the process exits).
		do
			if not webview.is_default_pointer then
				c_webview2_destroy (webview)
				webview := default_pointer
			end
			is_ready := False
			has_creation_failed := True
			pending_operations.wipe_out
			if attached application_destroy_action as l_action then
				application_destroy_action := Void
				if not application_imp.is_destroyed then
						-- Not called by the application destroy actions.
					application_imp.destroy_actions.prune_all (l_action)
				end
			end
		ensure
			closed: webview.is_default_pointer
			not_usable: not is_browser_usable
		end

	on_destroy
			-- <Precursor>
			-- The window of `Current` is destroyed (for instance with its parent window).
		do
			close_webview
			Precursor {WEL_WINDOW}
		end

	application_destroy_action: detachable PROCEDURE
			-- Action of `{EV_APPLICATION}.destroy_actions` closing the web view.

feature {EV_ANY, EV_ANY_I} -- Implementation

	interface: detachable EV_WEB_BROWSER note option: stable attribute end
			-- Vision2 widget interface

feature {NONE} -- WebView2 events

	on_webview2_event (a_kind: INTEGER; a_text: POINTER; a_flag: INTEGER): INTEGER
			-- Event `a_kind` of the web view, with `a_text` and `a_flag` (see eif_webview2.h).
			-- Called by the C code.
		local
			l_text: detachable STRING_32
			l_base_uri: detachable STRING_32
		do
			if not a_text.is_default_pointer then
				l_text := (create {WEL_STRING}.make_by_pointer (a_text)).string
			end
			inspect a_kind
			when Webview2_ready then
				if a_flag = 0 then
					is_ready := True
					c_webview2_set_bounds (webview, wel_width, wel_height)
					across pending_operations as op loop
						op.call
					end
					pending_operations.wipe_out
				else
					has_creation_failed := True
					pending_operations.wipe_out
				end
			when Webview2_navigation_starting then
				l_base_uri := Void
				if is_loading_html then
						-- Document of `load_html`: use its base URI, if any.
					is_loading_html := False
					l_base_uri := pending_html_base_uri
					pending_html_base_uri := Void
					if l_base_uri /= Void then
						l_text := l_base_uri
					end
				end
				if l_text /= Void then
					if is_navigation_allowed (l_text) then
						html_base_uri := l_base_uri
						is_loading := True
						is_navigation_cancelled := False
						on_load_started (l_text)
					else
						is_navigation_cancelled := True
						Result := 1
					end
				end
			when Webview2_navigation_completed then
				if is_navigation_cancelled then
					is_navigation_cancelled := False
				else
					is_loading := False
					if a_flag = 0 then
						on_load_finished (current_uri)
					else
						on_load_failed (current_uri, {STRING_32} "Navigation failed (WebView2 web error status " + (a_flag - 1).out + ")")
					end
				end
			when Webview2_source_changed then
				on_uri_changed (current_uri)
			when Webview2_title_changed then
				if attached title as t then
					on_title_changed (t)
				end
			when Webview2_web_message_received then
				if l_text /= Void then
					on_message_received (l_text)
				end
			when Webview2_new_window_requested then
					-- Open the links targeting a new window in the current view.
				if l_text /= Void and then is_navigation_allowed (l_text) then
					load_uri (l_text)
				end
			else
			end
		end

feature {NONE} -- Implementation

	webview: POINTER
			-- WebView2 context (see eif_webview2.c).

	is_ready: BOOLEAN
			-- Is the web view created?

	has_creation_failed: BOOLEAN
			-- Did the creation of the web view fail?

	is_navigation_cancelled: BOOLEAN
			-- Was the current navigation cancelled by `navigation_handler`?

	is_loading_html: BOOLEAN
			-- Is the next navigation the one of a document given to `load_html`?

	pending_html_base_uri: detachable STRING_32
			-- Base URI of the document given to `load_html`, until its navigation starts.

	html_base_uri: detachable STRING_32
			-- Base URI of the displayed document, if it was given to `load_html` with a base URI.

	pending_operations: ARRAYED_LIST [PROCEDURE]
			-- Operations to perform once the web view is ready.

	pending_zoom_level: REAL_64
			-- Value of `zoom_level` until the web view is ready.

	perform (a_operation: PROCEDURE)
			-- Perform `a_operation` now if the web view is ready, otherwise once it is ready.
		do
			if is_ready then
				a_operation.call
			elseif not has_creation_failed then
				pending_operations.extend (a_operation)
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
			-- String of the wide string `p` allocated by WebView2, that is freed.
		do
			if not p.is_default_pointer then
				Result := (create {WEL_STRING}.make_by_pointer (p)).string
				c_webview2_free_string (p)
			end
		end

	html_attribute_escaped (s: READABLE_STRING_GENERAL): STRING_32
			-- `s` escaped for a quoted HTML attribute value.
		do
			create Result.make_from_string_general (s)
			Result.replace_substring_all ({STRING_32} "&", {STRING_32} "&amp;")
			Result.replace_substring_all ({STRING_32} "%"", {STRING_32} "&quot;")
			Result.replace_substring_all ({STRING_32} "<", {STRING_32} "&lt;")
		end

	on_size (size_type, a_width, a_height: INTEGER_32)
			-- <Precursor>
		do
			Precursor {EV_PRIMITIVE_IMP} (size_type, a_width, a_height)
			if is_ready then
				c_webview2_set_bounds (webview, a_width, a_height)
			end
		end

	on_set_focus
			-- <Precursor>
		do
			Precursor {EV_PRIMITIVE_IMP}
			if is_ready then
				c_webview2_set_focus (webview)
			end
		end

	class_name: STRING_32
			-- <Precursor>
		once
			create Result.make_from_string_general (generator)
		end

	default_style: INTEGER
			-- <Precursor>
		do
			Result := ws_visible | ws_child | ws_group | ws_tabstop | Ws_clipchildren | Ws_clipsiblings
		end

	cwin_get_next_dlgtabitem (hdlg, hctl: POINTER; previous: BOOLEAN): POINTER
			-- <Precursor>
		do
			Result := {WEL_CONTROL}.c_cwin_get_next_dlgtabitem (hdlg, hctl, previous)
		end

feature {NONE} -- Constants

	Webview2_ready: INTEGER = 1
	Webview2_navigation_starting: INTEGER = 2
	Webview2_navigation_completed: INTEGER = 3
	Webview2_source_changed: INTEGER = 4
	Webview2_title_changed: INTEGER = 5
	Webview2_web_message_received: INTEGER = 6
	Webview2_new_window_requested: INTEGER = 7
			-- Events of the web view (see eif_webview2.h).

feature {NONE} -- Externals

	c_webview2_new (a_parent: POINTER; a_object: ANY; a_dispatch: POINTER): POINTER
		external
			"C signature (EIF_POINTER, EIF_OBJECT, EIF_POINTER): eif_webview2 * use %"eif_webview2.h%""
		alias
			"eif_webview2_new"
		end

	c_webview2_destroy (a_webview: POINTER)
		external
			"C signature (eif_webview2 *) use %"eif_webview2.h%""
		alias
			"eif_webview2_destroy"
		end

	c_webview2_set_bounds (a_webview: POINTER; a_width, a_height: INTEGER)
		external
			"C signature (eif_webview2 *, EIF_INTEGER, EIF_INTEGER) use %"eif_webview2.h%""
		alias
			"eif_webview2_set_bounds"
		end

	c_webview2_set_focus (a_webview: POINTER)
		external
			"C signature (eif_webview2 *) use %"eif_webview2.h%""
		alias
			"eif_webview2_set_focus"
		end

	c_webview2_navigate (a_webview: POINTER; a_uri: POINTER)
		external
			"C signature (eif_webview2 *, EIF_POINTER) use %"eif_webview2.h%""
		alias
			"eif_webview2_navigate"
		end

	c_webview2_navigate_to_string (a_webview: POINTER; a_html: POINTER)
		external
			"C signature (eif_webview2 *, EIF_POINTER) use %"eif_webview2.h%""
		alias
			"eif_webview2_navigate_to_string"
		end

	c_webview2_execute_script (a_webview: POINTER; a_script: POINTER)
		external
			"C signature (eif_webview2 *, EIF_POINTER) use %"eif_webview2.h%""
		alias
			"eif_webview2_execute_script"
		end

	c_webview2_add_document_start_script (a_webview: POINTER; a_script: POINTER)
		external
			"C signature (eif_webview2 *, EIF_POINTER) use %"eif_webview2.h%""
		alias
			"eif_webview2_add_document_start_script"
		end

	c_webview2_reload (a_webview: POINTER)
		external
			"C signature (eif_webview2 *) use %"eif_webview2.h%""
		alias
			"eif_webview2_reload"
		end

	c_webview2_stop (a_webview: POINTER)
		external
			"C signature (eif_webview2 *) use %"eif_webview2.h%""
		alias
			"eif_webview2_stop"
		end

	c_webview2_go_back (a_webview: POINTER)
		external
			"C signature (eif_webview2 *) use %"eif_webview2.h%""
		alias
			"eif_webview2_go_back"
		end

	c_webview2_go_forward (a_webview: POINTER)
		external
			"C signature (eif_webview2 *) use %"eif_webview2.h%""
		alias
			"eif_webview2_go_forward"
		end

	c_webview2_can_go_back (a_webview: POINTER): BOOLEAN
		external
			"C signature (eif_webview2 *): EIF_BOOLEAN use %"eif_webview2.h%""
		alias
			"eif_webview2_can_go_back"
		end

	c_webview2_can_go_forward (a_webview: POINTER): BOOLEAN
		external
			"C signature (eif_webview2 *): EIF_BOOLEAN use %"eif_webview2.h%""
		alias
			"eif_webview2_can_go_forward"
		end

	c_webview2_source (a_webview: POINTER): POINTER
		external
			"C signature (eif_webview2 *): EIF_POINTER use %"eif_webview2.h%""
		alias
			"eif_webview2_source"
		end

	c_webview2_title (a_webview: POINTER): POINTER
		external
			"C signature (eif_webview2 *): EIF_POINTER use %"eif_webview2.h%""
		alias
			"eif_webview2_title"
		end

	c_webview2_free_string (a_string: POINTER)
		external
			"C signature (EIF_POINTER) use %"eif_webview2.h%""
		alias
			"eif_webview2_free_string"
		end

	c_webview2_zoom_factor (a_webview: POINTER): REAL_64
		external
			"C signature (eif_webview2 *): EIF_REAL_64 use %"eif_webview2.h%""
		alias
			"eif_webview2_zoom_factor"
		end

	c_webview2_set_zoom_factor (a_webview: POINTER; a_zoom: REAL_64)
		external
			"C signature (eif_webview2 *, EIF_REAL_64) use %"eif_webview2.h%""
		alias
			"eif_webview2_set_zoom_factor"
		end

	c_webview2_set_user_agent (a_webview: POINTER; a_user_agent: POINTER)
		external
			"C signature (eif_webview2 *, EIF_POINTER) use %"eif_webview2.h%""
		alias
			"eif_webview2_set_user_agent"
		end

	c_webview2_set_dev_tools_enabled (a_webview: POINTER; b: BOOLEAN)
		external
			"C signature (eif_webview2 *, EIF_BOOLEAN) use %"eif_webview2.h%""
		alias
			"eif_webview2_set_dev_tools_enabled"
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
