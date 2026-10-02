note
	description:
		"EiffelVision screen. GTK+ implementation."
	legal: "See notice at end of class."
	status: "See notice at end of class."
	keywords: "screen, root, window, visual, top"
	date: "$Date$"
	revision: "$Revision$"


class
	EV_SCREEN_IMP

inherit
	EV_SCREEN_I
		redefine
			interface,
			widget_at_mouse_pointer,
			virtual_x,
			virtual_y,
			virtual_width,
			virtual_height,
			monitor_count,
			monitor_area_from_position,
			monitor_area_from_window,
			working_area_from_position,
			working_area_from_window,
			start_drawing_session, end_drawing_session
		end

	EV_DRAWABLE_IMP
		redefine
			interface,
			supports_pixbuf_alpha,
			device_x_offset,
			device_y_offset,
			draw_segment,
			set_drawing_mode,
			set_line_width,
			enable_dashed_line_style,
			disable_dashed_line_style,
			init_default_values,
			start_drawing_session,
			end_drawing_session,
			clear_rectangle,
			fill_rectangle,
			internal_set_color,
			draw_ellipse,
			draw_point,
			draw_arc,
			draw_rectangle,
			draw_polyline,
			fill_ellipse,
			fill_polygon,
			fill_pie_slice,
			pixbuf_from_drawable_at_position
		end

	EV_GTK_DEPENDENT_ROUTINES

create
	make

feature {NONE} -- Initialization

	old_make (an_interface: attached like interface)
			-- Create an empty drawing area.
		do
			assign_interface (an_interface)
		end

	make
		do
				-- In order to access the screen, the EV_APPLICATION needs to be created
			app_implementation.do_nothing
			has_x11_support := app_implementation.has_x11_support

--			initialize_drawing

				-- Note: `device_x_offset' and `device_y_offset' are computed on demand
				-- (to match the Win32 implementation, the logical origin is the top left
				-- of the primary monitor), so there is nothing to snapshot here.

			set_is_initialized (True)
			-- Set up action sequence connections and create graphics context.
		end

feature {EV_GTK_DEPENDENT_APPLICATION_IMP, EV_ANY_I} -- Drawing / Access

	pixbuf_from_drawable_at_position (src_x, src_y, dest_x, dest_y, a_width, a_height: INTEGER): POINTER
			-- <Precursor>
			--
			--| Read straight off the root window rather than through
			--| `cairo_get_target (cairo_context)' as the inherited version does. That
			--| version answers from whatever context happens to be current, and
			--| `sub_pixmap' -- the one caller that matters here -- never opens a drawing
			--| session, so on `Current' it always fell through to the `gdk_pixbuf_new'
			--| branch and handed back an uninitialized buffer instead of the screen.
			--|
			--| `src_x' / `src_y' are root coordinates: `sub_pixmap' adds
			--| `device_x_offset' / `device_y_offset' before calling, which is exactly
			--| the logical-to-root conversion.
		local
			l_width, l_height: INTEGER
		do
			prepare_drawing
			l_width := app_implementation.safe_pixmap_dimension (a_width)
			l_height := app_implementation.safe_pixmap_dimension (a_height)
			if not drawable.is_default_pointer then
				Result := {GDK}.gdk_pixbuf_get_from_window (drawable, src_x, src_y, l_width, l_height)
			end
			if Result.is_default_pointer then
				Result := {GDK}.gdk_pixbuf_new (0, True, 8, l_width, l_height)
			end
		end

feature -- Status report

	has_x11_support: BOOLEAN

feature {NONE} -- Drawing initialization	

	prepare_drawing
		do
			-- This feature is used to delay the initialization of the drawable resources
			-- (drawable, gc, ...) that are needed only when drawing.
			if not drawing_initialized then
				initialize_drawing
			end
		end

	initialize_drawing
		do
			if not drawing_initialized then
				drawing_initialized := True
				-- TODO update this code to support different environments like (Wayland)
				if has_x11_support then
					drawable := {GDK}.gdk_screen_get_root_window ({GDK}.gdk_screen_get_default)
					debug ("refactor_fixme")
						{REFACTORING_HELPER}.to_implement ("update this code to support different environments like (Wayland)")
					end
					gc := {GDK_X11}.create_gc (drawable)
					{GDK_X11}.x_set_subwindow_mode ({GDK_X11}.x_display (drawable), gc, {GDK_X11}.x_subwindow_mode_include_inferiors)
				end
				init_default_values
			end
		rescue
			drawing_initialized := True
			has_x11_support := False
			retry
		end

	init_default_values
			-- Set default values. Call during initialization.
		do
			enable_dashed_line_style
			set_drawing_mode (drawing_mode_copy)
			set_line_width (1)
		end

feature -- Drawing / Access

	drawing_initialized: BOOLEAN

	gc: POINTER
			-- X11 graphics context.
			-- available only for X11 session.

	drawable: POINTER
			-- Pointer to the screen (root window)

	get_cairo_context
			-- <Precursor>
			--
			--| This used to be `cairo_context := drawable', assigning a GdkWindow to a
			--| field every other feature reads as a cairo_t: `cairo_get_target' was
			--| being handed it in `pixbuf_from_drawable_at_position', and
			--| `clear_cairo_context' would have called `cairo_destroy' on it. Nothing
			--| ever caught fire only because `has_x11_support' was False under
			--| XWayland, leaving `drawable' null -- so this has to be right before the
			--| backend detection is fixed, not after.
		do
			if cairo_context.is_default_pointer then
				prepare_drawing
				cairo_context := {GDK}.gdk_window_create_cairo_context (drawable)
			end
		end

feature -- Status report

	pointer_position: EV_COORDINATE
			-- Position of the screen pointer.
		local
			l_display_data: TUPLE [a_window: POINTER; a_x: INTEGER; a_y: INTEGER; a_mask: NATURAL_32]
		do
			l_display_data := app_implementation.retrieve_display_data
				-- Logical offset is taken in to account in `retrieve_display_data'.
			create Result.set (l_display_data.a_x, l_display_data.a_y)
		end

	widget_at_position (x, y: INTEGER): detachable EV_WIDGET
			-- Widget at position ('x', 'y') if any.
		local
			l_pointer_position: TUPLE [a_window: POINTER; a_x: INTEGER; a_y: INTEGER; a_mask: NATURAL_32]
			l_widget_imp: detachable EV_WIDGET_IMP
			l_change: BOOLEAN
		do
			l_pointer_position := app_implementation.retrieve_display_data
				-- If `x' and `y' are at the pointer position then as an optimization we do not change the position of the mouse.
			l_change := l_pointer_position.a_x /= x or else l_pointer_position.a_y /= y
			if l_change then
				set_pointer_position (x, y)
			end
			l_widget_imp := widget_imp_at_pointer_position
			if l_change then
				set_pointer_position (l_pointer_position.a_x, l_pointer_position.a_y)
			end
			if l_widget_imp /= Void then
				Result := l_widget_imp.interface
			end
		end

	widget_at_mouse_pointer: detachable EV_WIDGET
			-- Widget at mouse pointer if any.
		local
			l_widget_imp: detachable EV_WIDGET_IMP
		do
			l_widget_imp := widget_imp_at_pointer_position
			if l_widget_imp /= Void then
				Result := l_widget_imp.interface
			end
		end

	widget_imp_at_pointer_position: detachable EV_WIDGET_IMP
			-- Widget implementation at current mouse pointer position (if any)
		local
			gdkwin: POINTER
			l_display_data: TUPLE [window: POINTER; a_x: INTEGER; a_y: INTEGER; a_mask: NATURAL_32]
			l_gtk_widget_imp: detachable EV_GTK_WIDGET_IMP
		do
			l_display_data := app_implementation.retrieve_display_data
			gdkwin := l_display_data.window
			if not gdkwin.is_default_pointer then
				l_gtk_widget_imp := app_implementation.gtk_widget_from_gdk_window (gdkwin)
				Result ?= l_gtk_widget_imp
			end
		end

	monitor_count: INTEGER
			-- Number of monitors used for displaying virtual screen.
		do
			Result := app_implementation.screen_monitor_count
		end

	monitor_area_from_position (a_x, a_y: INTEGER): EV_RECTANGLE
			-- Full area of monitor nearest to coordinates (a_x, a_y)
		do
			Result := monitor_rectangle (monitor_at_position (a_x, a_y), False)
		end

	monitor_area_from_window (a_window: EV_WINDOW): EV_RECTANGLE
			-- Full area of monitor of which most of `a_window' is located.
			-- Returns nearest monitor area if `a_window' does not overlap any monitors.
		do
			Result := monitor_rectangle (monitor_of_window (a_window), False)
		end

	working_area_from_position (a_x, a_y: INTEGER): EV_RECTANGLE
			-- <Precursor>
		do
			Result := monitor_rectangle (monitor_at_position (a_x, a_y), True)
		end

	working_area_from_window (a_window: EV_WINDOW): EV_RECTANGLE
			-- <Precursor>
		do
			Result := monitor_rectangle (monitor_of_window (a_window), True)
		end

feature {NONE} -- Monitor geometry

	monitor_at_position (a_x, a_y: INTEGER): POINTER
			-- GdkMonitor at logical position (`a_x', `a_y'), or the nearest one.
			-- Null when the display reports no monitor.
		do
			Result := {GDK}.gdk_display_get_monitor_at_point (
				{GDK}.gdk_display_get_default,
				a_x + device_x_offset,
				a_y + device_y_offset)
		end

	monitor_of_window (a_window: EV_WINDOW): POINTER
			-- GdkMonitor holding most of `a_window', or the nearest one.
			-- Null when `a_window' is not realized or the display reports no monitor.
		local
			l_gdk_window: POINTER
		do
			if attached {EV_WINDOW_IMP} a_window.implementation as l_window_imp then
				l_gdk_window := {GTK}.gtk_widget_get_window (l_window_imp.c_object)
				if not l_gdk_window.is_default_pointer then
					Result := {GDK}.gdk_display_get_monitor_at_window (
						{GDK}.gdk_display_get_default, l_gdk_window)
				end
			end
		end

	monitor_rectangle (a_monitor: POINTER; a_working_area: BOOLEAN): EV_RECTANGLE
			-- Geometry of `a_monitor', in Vision2 logical coordinates.
			--
			-- When `a_working_area', the area left free by desktop panels rather than the
			-- full monitor: the GNOME top bar and dock, a taskbar, and so on. On a typical
			-- GNOME desktop that is an inset of several tens of pixels on two edges, so a
			-- dialog positioned against the full monitor area lands underneath them.
			--
			-- Falls back to the primary monitor, and then to the primary monitor size,
			-- when `a_monitor' is null: `gdk_display_get_monitor_at_point' and
			-- `gdk_display_get_monitor_at_window' both return null rather than a default.
		local
			l_rect: POINTER
			l_monitor: POINTER
		do
			l_monitor := a_monitor
			if l_monitor.is_default_pointer then
				l_monitor := app_implementation.screen_primary_monitor
			end
			if l_monitor.is_default_pointer then
				create Result.make (0, 0, width, height)
			else
				l_rect := {GDK}.c_gdk_rectangle_struct_allocate
				if a_working_area then
					{GDK}.gdk_monitor_get_workarea (l_monitor, l_rect)
				else
					{GDK}.gdk_monitor_get_geometry (l_monitor, l_rect)
				end
				create Result.make (
					{GDK}.gdk_rectangle_struct_x (l_rect) - device_x_offset,
					{GDK}.gdk_rectangle_struct_y (l_rect) - device_y_offset,
					{GDK}.gdk_rectangle_struct_width (l_rect),
					{GDK}.gdk_rectangle_struct_height (l_rect))
				l_rect.memory_free
			end
		ensure
			has_area: Result.width > 0 and then Result.height > 0
		end

feature -- Status report

feature -- Basic operation		

	set_pointer_position (a_x, a_y: INTEGER)
			-- Set pointer position to (a_x, a_y).
		local
			a_success_flag: BOOLEAN
			l_gdk_display_warp_pointer_symbol, l_x_test_fake_motion_event_symbol: POINTER
			l_x, l_y: INTEGER
		do
				-- Update logical coords to device coords
			l_x := a_x + device_x_offset
			l_y := a_y + device_y_offset
			l_gdk_display_warp_pointer_symbol := gdk_display_warp_pointer_symbol
			if l_gdk_display_warp_pointer_symbol /= default_pointer then
				gdk_display_warp_pointer_call (l_gdk_display_warp_pointer_symbol, {GDK_HELPERS}.default_display, {GDK_HELPERS}.default_screen, l_x, l_y)
			else
				l_x_test_fake_motion_event_symbol := x_test_fake_motion_event_symbol
				if l_x_test_fake_motion_event_symbol /= default_pointer then
					a_success_flag := x_test_fake_motion_event_call (l_x_test_fake_motion_event_symbol, gdk_x_display, -1, l_x, l_y, 0)
				end
			end
			if app_implementation.use_stored_display_data then
					-- If we are set to using the stored display data then it needs to be updated.
				app_implementation.update_display_data
			end
		end

	fake_pointer_button_press (a_button: INTEGER)
			-- Fake button `a_button' press on pointer.
		local
			a_success_flag: BOOLEAN
			l_p_b_press_symbol: POINTER
			l_window: POINTER
			l_x, l_y: INTEGER
			l_x_test_fake_button_event_symbol: POINTER
		do
			l_p_b_press_symbol := gdk_test_simulate_button_symbol
			if l_p_b_press_symbol /= default_pointer then
				l_window := {GDK_HELPERS}.window_at ($l_x, $l_y)
				a_success_flag := gdk_test_simulate_call (l_p_b_press_symbol, l_window, l_x, l_y, a_button, 0, {EV_GTK_ENUMS}.gdk_button_press_enum)
			end
			if not a_success_flag then
				l_x_test_fake_button_event_symbol := x_test_fake_button_event_symbol
				if l_x_test_fake_button_event_symbol /= default_pointer then
					a_success_flag := x_test_fake_key_button_event_call (l_x_test_fake_button_event_symbol, gdk_x_display, a_button, True, 0)
				end
			end
		end

	fake_pointer_button_release (a_button: INTEGER)
			-- Fake button `a_button' release on pointer.
		local
			a_success_flag: BOOLEAN
			l_p_b_release_symbol: POINTER
			l_window: POINTER
			l_x, l_y: INTEGER
			l_x_test_fake_button_event_symbol: POINTER
		do
			l_p_b_release_symbol := gdk_test_simulate_button_symbol
			if l_p_b_release_symbol /= default_pointer then
				l_window := {GDK_HELPERS}.window_at ($l_x, $l_y)
				a_success_flag := gdk_test_simulate_call (l_p_b_release_symbol, l_window, l_x, l_y, a_button, 0, {EV_GTK_ENUMS}.gdk_button_release_enum)
			end
			if not a_success_flag then
				l_x_test_fake_button_event_symbol := x_test_fake_button_event_symbol
				if l_x_test_fake_button_event_symbol /= default_pointer then
					a_success_flag := x_test_fake_key_button_event_call (l_x_test_fake_button_event_symbol, gdk_x_display, a_button, False, 0)
				end
			end
		end

	fake_pointer_wheel_up
			-- Simulate the user rotating the mouse wheel up.
		do
				--| Mouse pointer button number 4 relates to mouse wheel up
			fake_pointer_button_press (4)
		end

	fake_pointer_wheel_down
			-- Simulate the user rotating the mouse wheel down.
		do
				--| Mouse pointer button number 5 relates to mouse wheel up
			fake_pointer_button_press (5)
		end

	fake_key_press (a_key: EV_KEY)
			-- Fake key `a_key' press.
		local
			a_success_flag: BOOLEAN
			a_key_code: INTEGER
			l_window, l_x_test_fake_key_event_symbol, l_x_keysym_to_keycode_symbol, l_gdk_test_simulate_key_symbol: POINTER
			l_x, l_y: INTEGER
		do
			l_x_test_fake_key_event_symbol := x_test_fake_key_event_symbol
			if l_x_test_fake_key_event_symbol /= default_pointer then
				l_x_keysym_to_keycode_symbol := x_keysym_to_keycode_symbol
				if l_x_keysym_to_keycode_symbol /= default_pointer then
					a_key_code := x_keysym_to_keycode_call (l_x_keysym_to_keycode_symbol, gdk_x_display, key_conversion.key_code_to_gtk (a_key.code).to_integer_32)
					a_success_flag := x_test_fake_key_button_event_call (l_x_test_fake_key_event_symbol, gdk_x_display, a_key_code, True, 0)
				end
			end

			if not a_success_flag then
				a_key_code := key_conversion.key_code_to_gtk (a_key.code).to_integer_32
				l_gdk_test_simulate_key_symbol := gdk_test_simulate_key_symbol
				if l_gdk_test_simulate_key_symbol /= default_pointer then
					l_window := {GDK_HELPERS}.window_at ($l_x, $l_y)
					a_success_flag := gdk_test_simulate_call (l_gdk_test_simulate_key_symbol, l_window, l_x, l_y, a_key_code, 0, {GDK}.gdk_key_press_enum)
				end
			end
		end

	fake_key_release (a_key: EV_KEY)
			-- Fake key `a_key' release.
		local
			a_success_flag: BOOLEAN
			a_key_code: INTEGER
			l_window, l_x_test_fake_key_event_symbol, l_x_keysym_to_keycode_symbol, l_gdk_test_simulate_key_symbol: POINTER
			l_x, l_y: INTEGER
		do
			l_x_test_fake_key_event_symbol := x_test_fake_key_event_symbol
			if l_x_test_fake_key_event_symbol /= default_pointer then
				l_x_keysym_to_keycode_symbol := x_keysym_to_keycode_symbol
				if l_x_keysym_to_keycode_symbol /= default_pointer then
					a_key_code := x_keysym_to_keycode_call (l_x_keysym_to_keycode_symbol, gdk_x_display, key_conversion.key_code_to_gtk (a_key.code).to_integer_32)
					a_success_flag := x_test_fake_key_button_event_call (l_x_test_fake_key_event_symbol, gdk_x_display, a_key_code, False, 0)
				end
			end

			if not a_success_flag then
				a_key_code := key_conversion.key_code_to_gtk (a_key.code).to_integer_32
				l_gdk_test_simulate_key_symbol := gdk_test_simulate_key_symbol
				if l_gdk_test_simulate_key_symbol /= default_pointer then
					l_window := {GDK_HELPERS}.window_at ($l_x, $l_y)
					a_success_flag := gdk_test_simulate_call (l_gdk_test_simulate_key_symbol, l_window, l_x, l_y, a_key_code, 0, {GDK}.gdk_key_release_enum)
				end
			end
		end

	key_conversion: EV_GTK_KEY_CONVERSION
			-- Utilities for converting X key codes.
		once
			create Result
		end

feature -- Measurement

	horizontal_resolution: INTEGER
			-- Number of logical pixels per inch along horizontal axis
			--| Logical, like every other size Vision2 hands out on GTK 3; see
			--| `logical_resolution'.
		do
			Result := logical_resolution
		end

	vertical_resolution: INTEGER
			-- Number of logical pixels per inch along vertical axis
		do
			Result := logical_resolution
		end

	logical_resolution: INTEGER
			-- Number of logical pixels per inch of the display.
			--
			-- This is the resolution to size things with. Widths, heights, paddings
			-- and pixmaps are all logical on GTK 3: GTK multiplies them by
			-- `screen_scale_factor' itself when it renders. It is the X server DPI
			-- divided by that factor, so it stays at 96 on a scaled display unless
			-- the user enlarged the text (a 288 Xft.dpi at scale 3 gives 96, 360
			-- gives 120).
			--
			--| Returning `effective_resolution' here instead, as was tried for a while,
			--| scales everything twice: an application seeing 288 dpi picks icons and
			--| margins three times larger, and GTK then triples them again.
		do
			Result := {GDK}.gdk_screen_get_resolution ({GDK}.gdk_screen_get_default)
			if Result <= 0 then
					-- If no resolution has been set then default to 96.
				Result := 96
			end
		ensure
			positive: Result > 0
		end

	effective_resolution: INTEGER
			-- Number of device pixels per inch of the display, i.e. `logical_resolution'
			-- times the GDK integer scale factor.
			--
			-- On a 3840x2160 panel scaled to 1536x864 logical pixels, GTK reports 96 dpi
			-- and a scale factor of 3, and the effective resolution is 288 dpi.
			--
			--| Only for code that works in device pixels, such as choosing how much
			--| detail to render into a backing store. Anything that sizes widgets or
			--| picks a pixmap to show at its own size wants `logical_resolution'.
		do
			Result := logical_resolution * app_implementation.screen_scale_factor.max (1)
		ensure
			positive: Result > 0
		end

	height: INTEGER
			-- Vertical size in pixels.
		do
			Result := app_implementation.screen_height
		end

	width: INTEGER
			-- Horizontal size in pixels.
		do
			Result := app_implementation.screen_width
		end

	virtual_x: INTEGER
			-- <Precursor>
		do
			Result := app_implementation.screen_virtual_x
		end

	virtual_y: INTEGER
			-- <Precursor>
		do
			Result := app_implementation.screen_virtual_y
		end

	virtual_height: INTEGER
			-- <Precursor>
		do
			Result := app_implementation.screen_virtual_height
		end

	virtual_width: INTEGER
			-- <Precursor>
		do
			Result := app_implementation.screen_virtual_width
		end

feature {NONE} -- Externals (XTEST extension)

	device_x_offset: INTEGER
			-- <Precursor>
			--| Read live rather than cached at creation: the virtual screen origin moves
			--| whenever a monitor is plugged in, unplugged or rearranged, and an
			--| `EV_SCREEN' that outlives such a change would otherwise keep converting
			--| coordinates with a stale origin.
		do
			Result := app_implementation.to_device_x (0)
		end

	device_y_offset: INTEGER
			-- <Precursor>
			--| See `device_x_offset'.
		do
			Result := app_implementation.to_device_y (0)
		end

	gdk_test_simulate_button_symbol: POINTER
			-- Symbol for `gdk_test_simulate_button'
		once
			Result := app_implementation.symbol_from_symbol_name ("gdk_test_simulate_button")
		end

	x_test_fake_button_event_symbol: POINTER
			-- Symbol for `XTestFakeButtonEvent'
		once
			Result := app_implementation.symbol_from_symbol_name ("XTestFakeButtonEvent")
		end

	x_test_fake_key_event_symbol: POINTER
			-- Symbol for `XTestFakeKeyEvent'
		once
			Result := app_implementation.symbol_from_symbol_name ("XTestFakeKeyEvent")
		end

	x_test_fake_motion_event_symbol: POINTER
			-- Symbol for `XTestFakeMotionEvent'
		once
			Result := app_implementation.symbol_from_symbol_name ("XTestFakeMotionEvent")
		end

	gdk_test_simulate_key_symbol: POINTER
			-- Symbol for `gdk_test_simulate_key'
		once
			Result := app_implementation.symbol_from_symbol_name ("gdk_test_simulate_key")
		end

	gdk_display_warp_pointer_symbol: POINTER
			-- Symbol for `gdk_display_warp_pointer'.
		once
			Result := app_implementation.symbol_from_symbol_name ("gdk_display_warp_pointer")
		end

	gdk_test_simulate_call (a_function, a_window: POINTER; a_x, a_y: INTEGER; a_button, a_modifiers: INTEGER; a_press_release: INTEGER): BOOLEAN
		external
			"C inline use <ev_gtk.h>"
		alias
			"return (FUNCTION_CAST(gboolean, (GdkWindow*, gint, gint, guint, GdkModifierType, GdkEventType)) $a_function) ((GdkWindow*) $a_window, (gint) $a_x, (gint) $a_y, (guint) $a_button, (GdkModifierType) $a_modifiers, (GdkEventType) $a_press_release)"
		end

	gdk_display_warp_pointer_call (a_function, a_display, a_screen: POINTER; a_x, a_y: INTEGER)
		external
			"C inline use <ev_gtk.h>"
		alias
			"(FUNCTION_CAST(void, (GdkDisplay*, GdkScreen*, gint, gint)) $a_function) ((GdkDisplay*) $a_display, (GdkScreen*) $a_screen, (gint) $a_x, (gint) $a_y)"
		end

	x_keysym_to_keycode_symbol: POINTER
			-- Symbol for `x_keysym_to_keycode'.
		once
			Result := app_implementation.symbol_from_symbol_name ("XKeysymToKeycode")
		end

	x_keysym_to_keycode_call (a_function, a_display: POINTER; a_keycode: INTEGER): INTEGER
		external
			"C inline use <ev_gtk.h>"
		alias
			"return (FUNCTION_CAST(EIF_INTEGER, (EIF_POINTER, EIF_INTEGER)) $a_function) ((EIF_POINTER) $a_display, (EIF_INTEGER) $a_keycode)"
		end

	x_test_fake_key_button_event_call (a_function, a_display: POINTER; a_keycode_or_button: INTEGER; a_is_press: BOOLEAN; a_delay: INTEGER): BOOLEAN
		external
			"C inline use <ev_gtk.h>"
		alias
			"return (FUNCTION_CAST(EIF_BOOLEAN, (EIF_POINTER, EIF_INTEGER, EIF_BOOLEAN, EIF_INTEGER)) $a_function) ((EIF_POINTER) $a_display, (EIF_INTEGER) $a_keycode_or_button, (EIF_BOOLEAN) $a_is_press, (EIF_INTEGER) $a_delay)"
		end

	x_test_fake_motion_event_call (a_function, a_display: POINTER; a_scr_num, a_x, a_y, a_delay: INTEGER): BOOLEAN
		external
			"C inline use <ev_gtk.h>"
		alias
			"return (FUNCTION_CAST(EIF_BOOLEAN, (EIF_POINTER, EIF_INTEGER, EIF_INTEGER, EIF_INTEGER, EIF_INTEGER)) $a_function) ((EIF_POINTER) $a_display, (EIF_INTEGER) $a_scr_num, (EIF_INTEGER) $a_x, (EIF_INTEGER) $a_x, (EIF_INTEGER) $a_delay)"
		end

feature {NONE} -- Implementation

	supports_pixbuf_alpha: BOOLEAN
			-- <Precursor>
		do
				-- For the moment EV_SCREEN doesn't support direct alpha blending.
			Result := False
		end

	frozen gdk_x_display: POINTER
		local
			l_symbol: POINTER
		do
			l_symbol := gdk_x11_display_get_xdisplay_symbol
			if l_symbol /= default_pointer then
				Result := gdk_x11_display_get_xdisplay_call (l_symbol, {GDK}.gdk_display_get_default)
			end
		end

	gdk_x11_display_get_xdisplay_symbol: POINTER
			-- Symbol for `gdk_x11_display_get_xdisplay'.
		once
			Result := app_implementation.symbol_from_symbol_name ("gdk_x11_display_get_xdisplay")
		end

	gdk_x11_display_get_xdisplay_call (a_function, a_display: POINTER): POINTER
		external
			"C inline use <ev_gtk.h>"
		alias
			"return (FUNCTION_CAST(EIF_POINTER, (GdkDisplay*)) $a_function) ((GdkDisplay*) $a_display)"
		end

	update_if_needed
			-- Update `Current' if needed
		do
				-- Nothing to do: `device_x_offset' and `device_y_offset' are now computed
				-- on demand from the application screen metadata, so they can never be
				-- stale. Kept because the X11 drawing routines call it after each
				-- operation.
		end

feature -- Drawing / Clear Operations

	clear_rectangle (x, y, a_width, a_height: INTEGER)
			-- Erase rectangle specified with `background_color'.
		local
			tmp_fg_color, tmp_bg_color: detachable EV_COLOR
		do
			pre_drawing
			if
				has_x11_support and then
				not drawable_x_window.is_default_pointer and then
				not drawable_x_display.is_default_pointer
			then
				{GDK}.gdk_window_invalidate_rect (drawable, default_pointer, True)

				tmp_fg_color := internal_foreground_color
				if tmp_fg_color = Void then
					tmp_fg_color := foreground_color
				end
				tmp_bg_color := internal_background_color
				if tmp_bg_color = Void then
					tmp_bg_color := background_color
				end
				internal_set_color (True, tmp_bg_color.red, tmp_bg_color.green, tmp_bg_color.blue)
				{GDK_X11}.draw_rectangle (drawable_x_window, drawable_x_display, gc, True,
					(x + device_x_offset),
					(y + device_y_offset),
					a_width,
					a_height)
				internal_set_color (True, tmp_fg_color.red, tmp_fg_color.green, tmp_fg_color.blue)
				update_if_needed
			end
			post_drawing
		end

feature -- Drawing

	draw_segment (x1, y1, x2, y2: INTEGER)
			-- Draw line segment from (`x1', 'y1') to (`x2', 'y2').
		do
			debug ("refactor_fixme")
				{REFACTORING_HELPER}.to_implement ("update this code to support different environments like (Wayland)")
			end
			pre_drawing
			if
				has_x11_support and then
				not drawable_x_window.is_default_pointer and then
				not drawable_x_display.is_default_pointer
			then
				{GDK}.gdk_window_invalidate_rect (drawable, default_pointer, True)
				{GDK_X11}.draw_line (
					drawable_x_window, drawable_x_display,
					gc,
					(x1 + device_x_offset),
					(y1 + device_y_offset),
					(x2 + device_x_offset),
					(y2 + device_y_offset)
				)
				update_if_needed
			end
			post_drawing
		end

	draw_ellipse (x, y, a_width, a_height: INTEGER)
			-- Draw an ellipse bounded by top left (`x', `y') with
			-- size `a_width' and `a_height'.
		do
			debug ("refactor_fixme")
				{REFACTORING_HELPER}.to_implement ("update this code to support different environments like (Wayland)")
			end
			pre_drawing
			if
				has_x11_support and then
				not drawable_x_window.is_default_pointer and then
				not drawable_x_display.is_default_pointer and then
				a_width > 0 and a_height > 0
			then
				{GDK}.gdk_window_invalidate_rect (drawable, default_pointer, True)
				{GDK_X11}.draw_arc (
					drawable_x_window, drawable_x_display,
					gc,
					False,
					(x + device_x_offset),
					(y + device_y_offset),
					a_width - 1,
					a_height - 1,
					0,
					whole_circle
				)
				update_if_needed
			end
			post_drawing
		end

	draw_point (x, y: INTEGER)
			-- Draw point at (`x', `y').
		do
			debug ("refactor_fixme")
				{REFACTORING_HELPER}.to_implement ("update this code to support different environments like (Wayland)")
			end
			pre_drawing
			if
				has_x11_support and then
				not drawable_x_window.is_default_pointer and then
				not drawable_x_display.is_default_pointer
			then
				{GDK}.gdk_window_invalidate_rect (drawable, default_pointer, True)
	 			{GDK_X11}.draw_point (
	 				drawable_x_window, drawable_x_display,
	 				gc,
	 				(x + device_x_offset),
	 				(y + device_y_offset)
	 			)
	 			update_if_needed
			end
			post_drawing
		end

	draw_arc (x, y, a_width, a_height: INTEGER; a_start_angle, an_aperture: REAL)
			-- Draw a part of an ellipse bounded by top left (`x', `y') with
			-- size `a_width' and `a_height'.
			-- Start at `a_start_angle' and stop at `a_start_angle' + `an_aperture'.
			-- Angles are measured in radians.
		local
			a_radians: INTEGER
		do
			debug ("refactor_fixme")
				{REFACTORING_HELPER}.to_implement ("update this code to support different environments like (Wayland)")
			end
			pre_drawing
			if
				has_x11_support and then
				not drawable_x_window.is_default_pointer and then
				not drawable_x_display.is_default_pointer
			then
				{GDK}.gdk_window_invalidate_rect (drawable, default_pointer, True)
				a_radians := radians_to_gdk_angle
				{GDK_X11}.draw_arc (
					drawable_x_window, drawable_x_display,
					gc,
					False,
					(x + device_x_offset),
					(y + device_y_offset),
					a_width,
					a_height,
					(a_start_angle * a_radians + 0.5).truncated_to_integer,
					(an_aperture * a_radians + 0.5).truncated_to_integer
				)
				update_if_needed
			end
			post_drawing
		end

	draw_rectangle (x, y, a_width, a_height: INTEGER)
			-- Draw rectangle with upper-left corner on (`x', `y')
			-- with size `a_width' and `a_height'.
		do
			debug ("refactor_fixme")
					{REFACTORING_HELPER}.to_implement ("update this code to support different environments like (Wayland)")
			end
			pre_drawing
			if not has_x11_support then
					-- No usable root window: paint it in an overlay instead.
				overlay_toggle_rectangle (False, x, y, a_width, a_height)
			elseif
				not drawable_x_window.is_default_pointer and then
				not drawable_x_display.is_default_pointer and then
				a_width > 0 and then a_height > 0
			then
				{GDK}.gdk_window_invalidate_rect (drawable, default_pointer, True)
					-- If width or height are zero then nothing will be rendered.
				{GDK_X11}.draw_rectangle (
					drawable_x_window, drawable_x_display,
					gc,
					False,
					(x + device_x_offset),
					(y + device_y_offset),
					a_width - 1,
					a_height - 1
				)
				update_if_needed
			end
			post_drawing
		end

	draw_polyline (points: ARRAY [EV_COORDINATE]; is_closed: BOOLEAN)
			-- Draw line segments between subsequent points in
			-- `points'. If `is_closed' draw line segment between first
			-- and last point in `points'.
		local
			tmp: SPECIAL [INTEGER]
		do
			debug ("refactor_fixme")
					{REFACTORING_HELPER}.to_implement ("update this code to support different environments like (Wayland)")
			end
			pre_drawing
			if
				has_x11_support and then
				not drawable_x_window.is_default_pointer and then
				not drawable_x_display.is_default_pointer
			then
				{GDK}.gdk_window_invalidate_rect (drawable, default_pointer, True)
				tmp := coord_array_to_gdkpoint_array (points).area
				if is_closed then
					{GDK_X11}.draw_polygon (drawable_x_window, drawable_x_display, gc, False, $tmp, points.count)
					update_if_needed
				else
					{GDK_X11}.draw_lines (drawable_x_window, drawable_x_display, gc, $tmp, points.count)
					update_if_needed
				end
			end
		end

feature -- Drawing / Fill Operations

	fill_rectangle (x, y, a_width, a_height: INTEGER)
			-- Draw rectangle with upper-left corner on (`x', `y')
			-- with size `a_width' and `a_height'. Fill with `background_color'.
		do
			pre_drawing
			if not has_x11_support then
					-- No usable root window: paint it in an overlay instead.
				overlay_toggle_rectangle (True, x, y, a_width, a_height)
			elseif
				not drawable_x_window.is_default_pointer and then
				not drawable_x_display.is_default_pointer and then
				a_width > 0 and then a_height > 0
			then
				{GDK}.gdk_window_invalidate_rect (drawable, default_pointer, True)
				if tile /= Void then
					{GDK_X11}.x_set_fill_style (drawable_x_display, gc, {GDK_X11}.x_fill_tiled)
				end
				{GDK_X11}.draw_rectangle (
					drawable_x_window, drawable_x_display,
					gc,
					True,
					(x + device_x_offset),
					(y + device_y_offset),
					a_width,
					a_height
				)
				{GDK_X11}.x_set_fill_style (drawable_x_display, gc, {GDK_X11}.x_fill_solid)
				update_if_needed
			end
			post_drawing
		end

	fill_ellipse (x, y, a_width, a_height: INTEGER)
			-- Draw an ellipse bounded by top left (`x', `y') with
			-- size `a_width' and `a_height'.
			-- Fill with `background_color'.
		do
			pre_drawing
			if
				has_x11_support and then
				not drawable_x_window.is_default_pointer and then
				not drawable_x_display.is_default_pointer
			then
				{GDK}.gdk_window_invalidate_rect (drawable, default_pointer, True)
				if tile /= Void then
					{GDK_X11}.x_set_fill_style (drawable_x_display, gc, {GDK_X11}.x_fill_tiled)
				end
				{GDK_X11}.draw_arc (drawable_x_window, drawable_x_display, gc, True, (x + device_x_offset),
					(y + device_y_offset), a_width,
					a_height, 0, whole_circle)
				{GDK_X11}.x_set_fill_style (drawable_x_display, gc, {GDK_X11}.x_fill_solid)
				update_if_needed
			end
			post_drawing
		end

	fill_polygon (points: ARRAY [EV_COORDINATE])
			-- Draw line segments between subsequent points in `points'.
			-- Fill all enclosed area's with `background_color'.
		local
			tmp: SPECIAL [INTEGER]
		do
			pre_drawing
			if
				has_x11_support and then
				not drawable_x_window.is_default_pointer and then
				not drawable_x_display.is_default_pointer
			then
				{GDK}.gdk_window_invalidate_rect (drawable, default_pointer, True)
				tmp := coord_array_to_gdkpoint_array (points).area
				if tile /= Void then
					{GDK_X11}.x_set_fill_style (drawable_x_display, gc, {GDK_X11}.x_fill_tiled)
				end
				{GDK_X11}.draw_polygon (drawable_x_window, drawable_x_display, gc, True, $tmp, points.count)
				{GDK_X11}.x_set_fill_style (drawable_x_display, gc, {GDK_X11}.x_fill_solid)
				update_if_needed
			end
			post_drawing
		end

	fill_pie_slice (x, y, a_width, a_height: INTEGER; a_start_angle, an_aperture: REAL)
			-- Draw a part of an ellipse bounded by top left (`x', `y') with
			-- size `a_width' and `a_height'.
			-- Start at `a_start_angle' and stop at `a_start_angle' + `an_aperture'.
			-- The arc is then closed by two segments through (`x', `y').
			-- Angles are measured in radians.
		do
			pre_drawing
			if
				has_x11_support and then
				not drawable_x_window.is_default_pointer and then
				not drawable_x_display.is_default_pointer
			then
				{GDK}.gdk_window_invalidate_rect (drawable, default_pointer, True)
				if tile /= Void then
					{GDK_X11}.x_set_fill_style (drawable_x_display, gc, {GDK_X11}.x_fill_tiled)
				end
				{GDK_X11}.draw_arc (
					drawable_x_window, drawable_x_display,
					gc,
					False,
					(x + device_x_offset),
					(y + device_y_offset),
					a_width,
					a_height,
					(a_start_angle * radians_to_gdk_angle).truncated_to_integer,
					(an_aperture * radians_to_gdk_angle).truncated_to_integer
				)
				{GDK_X11}.x_set_fill_style (drawable_x_display, gc, {GDK_X11}.x_fill_solid)
				update_if_needed
			end
			post_drawing
		end

feature -- Drawing / Session		

	start_drawing_session
		do
			prepare_drawing
			Precursor
			drawable_x_window := default_pointer
			drawable_x_display := default_pointer
			get_drawable_x_display_and_window
		end

	end_drawing_session
		do
			check drawing_initialized end
			prepare_drawing	-- Just in case start_drawing_session was never called (should not occur)!
			if not drawable_x_display.is_default_pointer then
				{GDK_X11}.x_flush (drawable_x_display)
			end
			drawable_x_window := default_pointer
			drawable_x_display := default_pointer
			if is_in_top_drawing_session then
					-- Release the context `get_cairo_context' may have created on the
					-- root window, rather than keeping one alive for the lifetime of the
					-- application across resolution and monitor changes.
				clear_cairo_context
			end
			Precursor
		end

	get_drawable_x_display_and_window
		require
			drawing_initialized
		do
			if
				has_x11_support and then -- TODO: find a workaroung for Wayland.
				not drawable.is_default_pointer and then
				(drawable_x_window.is_default_pointer
				or drawable_x_display.is_default_pointer)
			then
				drawable_x_window := {GDK_X11}.x_window (drawable)
				drawable_x_display := {GDK_X11}.x_display (drawable)
			end
		end

	drawable_x_window: POINTER
	drawable_x_display: POINTER

feature {EV_ANY_I} -- Drawing / wrapper

	pre_drawing
			-- <Precursor>
		do
			prepare_drawing
			get_drawable_x_display_and_window
		end

	post_drawing
			-- <Precursor>
		do
		end

feature -- Drawing / Status setting

	set_default_colors
			-- Set foreground and background color to their default values.
		local
			a_default_colors: EV_STOCK_COLORS
		do
			prepare_drawing
			create a_default_colors
			set_background_color (a_default_colors.default_background_color)
			set_foreground_color (a_default_colors.default_foreground_color)
		end

feature -- Drawing / Element change

	set_drawing_mode (a_drawing_mode: INTEGER)
			-- Set drawing mode to `a_drawing_mode'.
		local
			l_gc: like gc
			l_drawable: like drawable
			l_display: POINTER
		do
			prepare_drawing
			Precursor (a_drawing_mode)
			if has_x11_support then
				l_gc := gc
				l_drawable := drawable

				if
					not l_gc.is_default_pointer and then
					not l_drawable.is_default_pointer
				then
					l_display := {GDK_X11}.x_display (l_drawable)
					inspect
						a_drawing_mode
					when {EV_DRAWABLE_CONSTANTS}.drawing_mode_copy then
						{GDK_X11}.x_set_function (l_display, l_gc, {GDK_X11}.x_function_GXcopy)
					when {EV_DRAWABLE_CONSTANTS}.drawing_mode_and then
						{GDK_X11}.x_set_function (l_display, l_gc, {GDK_X11}.x_function_GXand)
					when {EV_DRAWABLE_CONSTANTS}.drawing_mode_xor then
						{GDK_X11}.x_set_function (l_display, l_gc, {GDK_X11}.x_function_GXxor)
					when {EV_DRAWABLE_CONSTANTS}.drawing_mode_invert then
						{GDK_X11}.x_set_function (l_display, l_gc, {GDK_X11}.x_function_GXinvert)
					when {EV_DRAWABLE_CONSTANTS}.drawing_mode_or then
						{GDK_X11}.x_set_function (l_display, l_gc, {GDK_X11}.x_function_GXor)
					else
						check
							drawing_mode_exists: False
						end
						{GDK_X11}.x_set_function (l_display, l_gc, {GDK_X11}.x_function_GXcopy)
					end
				end
			end
		end

	set_line_width (a_width: INTEGER)
			-- Assign `a_width' to `line_width'.
		do
			prepare_drawing
			Precursor (a_width)
			if
				has_x11_support and then
				not gc.is_default_pointer and then
				not drawable.is_default_pointer
			then
				if dashed_line_style then
					{GDK_X11}.set_line_attributes_to_dashed_style (drawable, gc, a_width)
				else
					{GDK_X11}.set_line_attributes_to_solid_style (drawable, gc, a_width)
				end
			end
		end

	enable_dashed_line_style
			-- Draw lines dashed.
		do
			prepare_drawing
			Precursor {EV_DRAWABLE_IMP}
			if
				has_x11_support and then
				not gc.is_default_pointer and then
				not drawable.is_default_pointer
			then
				{GDK_X11}.set_line_attributes_to_dashed_style (drawable, gc, line_width)
			end
		end

	disable_dashed_line_style
			-- Draw lines solid.
		do
			prepare_drawing
			Precursor {EV_DRAWABLE_IMP}
			if
				has_x11_support and then
				not gc.is_default_pointer and then
				not drawable.is_default_pointer
			then
				{GDK_X11}.set_line_attributes_to_solid_style (drawable, gc, line_width)
			end
		end

feature -- Drawing / Basic operation

	redraw
			-- Redraw the entire area.
		do
			prepare_drawing
				-- Note: this used to invalidate `cairo_context' and pass it to
				-- `gtk_widget_queue_draw'. Both want the window, which is `drawable';
				-- `cairo_context' only happened to hold one because `get_cairo_context'
				-- was assigning it, and a GdkWindow is not a GtkWidget in any case.
			if not drawable.is_default_pointer then
				{GDK}.gdk_window_invalidate_rect (drawable, default_pointer, True)
				-- FIXME JV gdk_window_process_updates has been deprecated since version 3.22 and should not be used in newly-written code.
				--{GDK}.gdk_window_process_updates (drawable, True)
				-- https://stackoverflow.com/questions/34912757/how-do-you-force-a-screen-refresh-in-gtk-3-8
	--			app_implementation.process_pending_events_on_default_context
			end
		end

feature {NONE} -- Drawing / implementation

	flush
			-- Force all queued draw to be called.
		do
			prepare_drawing
			-- By default do nothing
			if
				has_x11_support and then
				not drawable.is_default_pointer
			then
				{GDK_X11}.flush_drawable (drawable)
			end
		end

	internal_set_color (a_foreground: BOOLEAN; a_red, a_green, a_blue: REAL_64)
		local
			r,g,b: INTEGER
		do
			prepare_drawing
			debug ("refactor_fixme")
				{REFACTORING_HELPER}.fixme ("The current Xlib code does not set the bg and fg correcty")
			end
			if has_x11_support then
				r := (a_red * 0xFFFF).rounded
				g := (a_green * 0xFFFF).rounded
				b := (a_blue * 0xFFFF).rounded
				if a_foreground then
					{GDK_X11}.set_drawable_foreground (drawable, gc, r, g, b)
				else
					{GDK_X11}.set_drawable_background (drawable, gc, r, g, b)
				end
			end
		end

feature {NONE} -- Screen feedback overlay

	overlay: EV_SCREEN_FEEDBACK_OVERLAY
			-- Feedback painted on top of the screen, shared by every `EV_SCREEN'.
			-- See `EV_SCREEN_FEEDBACK_OVERLAY' for why it is shared and how the
			-- draw-twice-to-erase protocol survives the lack of a root window.
		once
			create Result.make
		end

	overlay_is_supported: BOOLEAN
			-- Can feedback be painted on top of the screen in a transparent window?
			--
			--| Requires a compositing manager and an RGBA visual. Without both, the
			--| overlay would come up as an opaque rectangle covering the screen, which
			--| is a great deal worse than the missing feedback it is meant to replace,
			--| so this stays False and the drawing routines do nothing, as before.
		local
			l_screen: POINTER
		once
			Result := True
			if attached {EXECUTION_ENVIRONMENT}.item (once "EV_SCREEN_OVERLAY") as e then
				Result := not e.is_case_insensitive_equal_general ("no")
			end
			if Result then
				l_screen := {GDK}.gdk_screen_get_default
				Result :=
					not l_screen.is_default_pointer and then
					not {GDK}.gdk_screen_get_rgba_visual (l_screen).is_default_pointer and then
					{GDK}.gdk_screen_is_composited (l_screen)
			end
		end

	is_overlay_drawing_mode: BOOLEAN
			-- Is the current mode one the overlay stands in for?
			--
			--| Only the reversible modes. A caller drawing in copy mode wants to put
			--| pixels on the screen and keep them, which the overlay does not pretend
			--| to offer; invert and xor are the ones used for transient feedback, and
			--| the only ones whose erase step the shape toggling can reproduce.
		do
			Result :=
				drawing_mode = drawing_mode_invert or else
				drawing_mode = drawing_mode_xor
		end

	overlay_toggle_rectangle (a_filled: BOOLEAN; a_x, a_y, a_width, a_height: INTEGER)
			-- Show or erase the feedback rectangle described by the arguments.
		local
			l_color: detachable EV_COLOR
		do
			if
				overlay_is_supported and then
				is_overlay_drawing_mode and then
				a_width > 0 and then a_height > 0
			then
				l_color := internal_foreground_color
				if l_color = Void then
					l_color := foreground_color
				end
				overlay.toggle_rectangle (a_filled, a_x, a_y, a_width, a_height, line_width.max (1),
					l_color.red, l_color.green, l_color.blue)
				refresh_overlay
			end
		end

	refresh_overlay
			-- Bring the overlay window in line with `overlay.shapes'.
		require
			overlay_is_supported
		local
			l_window: POINTER
		do
			if overlay.shapes.is_empty then
				l_window := overlay.window
				if not l_window.is_default_pointer then
					{GTK}.gtk_widget_hide (l_window)
				end
			else
				build_overlay_window
				l_window := overlay.window
				if not l_window.is_default_pointer then
					overlay.set_origin (virtual_x, virtual_y)
					{GTK}.gtk_window_move (l_window,
						app_implementation.to_device_x (overlay.origin_x),
						app_implementation.to_device_y (overlay.origin_y))
					{GTK}.gtk_window_resize (l_window, virtual_width, virtual_height)
					{GTK}.gtk_widget_show (l_window)
					{GTK}.gtk_widget_queue_draw (l_window)
				end
			end
		end

	build_overlay_window
			-- Create the overlay window on first use.
		require
			overlay_is_supported
		local
			c_window, c_region: POINTER
			d: EV_DRAWING_AREA
		do
			if overlay.window.is_default_pointer then
				c_window := {GTK}.gtk_window_new ({GTK}.gtk_window_popup_enum)
				{GTK}.gtk_widget_set_visual (c_window, {GDK}.gdk_screen_get_rgba_visual ({GDK}.gdk_screen_get_default))
				{GTK}.gtk_widget_set_app_paintable (c_window, True)
				{GTK}.gtk_window_set_skip_taskbar_hint (c_window, True)
				{GTK}.gtk_window_set_accept_focus (c_window, False)

					-- The overlay covers every window on the screen, so it must not take
					-- a single pointer event: the drag that asked for this feedback is
					-- still tracking motion over the widgets underneath. An empty input
					-- region lets everything through.
				c_region := {CAIRO}.cairo_region_create
				{GTK}.gtk_widget_input_shape_combine_region (c_window, c_region)
				{CAIRO}.cairo_region_destroy (c_region)

				create d
				overlay.set_drawing (d)
				if attached {EV_DRAWING_AREA_IMP} d.implementation as d_imp then
					{GTK}.gtk_container_add (c_window, d_imp.c_object)
					{GTK}.gtk_widget_show (d_imp.c_object)
				end
				d.expose_actions.extend (agent paint_overlay)
				overlay.set_window (c_window)
			end
		end

	paint_overlay (a_x, a_y, a_width, a_height: INTEGER)
			-- Repaint the overlay window.
		local
			cr: POINTER
			l_line_width, l_x, l_y: REAL_64
			i, n: INTEGER
		do
			if attached overlay.drawing as d then
				d.start_drawing_session
				if attached {EV_DRAWING_AREA_IMP} d.implementation as d_imp then
						-- Erase to fully transparent rather than to a background colour:
						-- everything not covered by a shape has to show the screen.
					d_imp.start_transparency (0.0)
					d.clear
					if d_imp.background_transparency_set then
						d_imp.stop_transparency
					end
					cr := d_imp.cairo_context
				end
				if not cr.is_default_pointer then
					from
						i := 1
						n := overlay.shapes.count
					until
						i > n
					loop
						if attached overlay.shapes.i_th (i) as s then
							l_x := (s.x - overlay.origin_x).to_double
							l_y := (s.y - overlay.origin_y).to_double
							if s.filled then
								{CAIRO}.set_source_rgba (cr, s.red, s.green, s.blue, overlay_fill_alpha)
								{CAIRO}.rectangle (cr, l_x, l_y, s.width.to_double, s.height.to_double)
								{CAIRO}.fill (cr)
							else
								l_line_width := s.line_width.to_double
								{CAIRO}.set_source_rgba (cr, s.red, s.green, s.blue, overlay_line_alpha)
								{CAIRO}.set_line_width (cr, l_line_width)
									-- Cairo centres a stroke on the path, so inset it by
									-- half the line width to keep the whole border inside
									-- the rectangle the caller asked for.
								{CAIRO}.rectangle (cr,
									l_x + l_line_width / 2.0,
									l_y + l_line_width / 2.0,
									(s.width.to_double - l_line_width).max (1.0),
									(s.height.to_double - l_line_width).max (1.0))
								{CAIRO}.stroke (cr)
							end
						end
						i := i + 1
					end
				end
				d.end_drawing_session
			end
		end

	overlay_line_alpha: REAL_64 = 0.85
			-- Opacity of a feedback border.

	overlay_fill_alpha: REAL_64 = 0.30
			-- Opacity of a filled feedback area. Well short of opaque: these cover
			-- whole panes during a resize and the user needs to see what is behind.

feature {NONE} -- Implementation

	app_implementation: EV_APPLICATION_IMP
			-- Return the instance of EV_APPLICATION_IMP.
		once
			check attached {EV_APPLICATION_IMP} (create {EV_ENVIRONMENT}).implementation.application_i as l_result then
				Result := l_result
			end
		end

	destroy
		do
			set_is_destroyed (True)
		end

	dispose
			-- Cleanup
		do
			if not cairo_context.is_default_pointer then
				release_cairo_context (cairo_context)
				cairo_context := default_pointer
			end
				-- Note: guarded on `drawing_initialized' as well. `gc' and `drawable' are
				-- only ever set by `initialize_drawing', which is deferred until the
				-- first drawing operation, so an `EV_SCREEN' that was queried but never
				-- drawn on legitimately has neither.
			if has_x11_support and then drawing_initialized then
				if
					not gc.is_default_pointer and
					not drawable.is_default_pointer
				then
					{GDK_X11}.x_free_gc (drawable, gc)
				else
					check should_not_occur: False end
				end
			end
			drawable := default_pointer
			gc := default_pointer
		end

feature {EV_ANY, EV_ANY_I} -- Implementation

	interface: detachable EV_SCREEN note option: stable attribute end;

note
	copyright:	"Copyright (c) 1984-2024, Eiffel Software and others"
	license:	"Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"

end -- class EV_SCREEN_IMP
