note
	description: "GTK 3 implementation of SD_FEEDBACK_WINDOW."
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date$"
	revision: "$Revision$"

class
	SD_FEEDBACK_WINDOW_IMP

inherit
	EV_POPUP_WINDOW_IMP
		redefine
			make,
			new_gtk_window,
			show
		end

create
	make

feature {NONE} -- Initialization

	new_gtk_window: POINTER
			-- <Precursor>
			--| A popup rather than an undecorated toplevel: the window manager stays out
			--| of it entirely, so it is neither placed, focused nor raised behind our back
			--| while the drag goes on. The visual has to be set before the window is
			--| realized, which is why this is done here and not in `make'.
		local
			c_screen, c_visual: POINTER
		do
			Result := {GTK}.gtk_window_new ({GTK}.gtk_window_popup_enum)
			c_screen := {GDK}.gdk_screen_get_default
			c_visual := {GDK}.gdk_screen_get_rgba_visual (c_screen)
			if not c_visual.is_default_pointer then
				{GTK}.gtk_widget_set_visual (Result, c_visual)
			end
			{GTK}.gtk_widget_set_app_paintable (Result, True)
		end

	make
			-- <Precursor>
		do
			Precursor;
				-- The client area would otherwise paint the opaque window background
				-- under the drawing area.
			{GTK2}.gtk_event_box_set_visible_window (client_area, False)

				-- Same for the (empty) menu and status bar holders, which still get a
				-- row of pixels each and paint it with the theme background.
			if attached {EV_VERTICAL_BOX_IMP} upper_bar.implementation as l_bar then
				{GTK}.gtk_widget_hide (l_bar.c_object)
			end
			if attached {EV_VERTICAL_BOX_IMP} lower_bar.implementation as l_bar then
				{GTK}.gtk_widget_hide (l_bar.c_object)
			end
		end

feature {EV_ANY_I} -- Basic operations

	show
			-- <Precursor>
		do
			Precursor
			pass_pointer_through
		end

	pass_pointer_through
			-- Let every pointer event through `Current' to the windows underneath.
			--| The indicators sit right under the pointer while the user aims at them.
			--| Taking pointer events there would steal the motion from the widget
			--| tracking the drag, so the input region is made empty.
			--| This has to be done once shown: set any earlier, while `make' runs,
			--| it does not survive until the window is mapped.
		local
			c_region: POINTER
		do
			c_region := {CAIRO}.cairo_region_create
			{GTK}.gtk_widget_input_shape_combine_region (c_object, c_region)
			{CAIRO}.cairo_region_destroy (c_region)
		end

feature {SD_FEEDBACK_WINDOW} -- Basic operations

	raise_window
			-- Stack `Current' above the other windows.
		local
			l_window: POINTER
		do
			l_window := {GTK}.gtk_widget_get_window (c_object)
			if not l_window.is_default_pointer then
				{GDK}.gdk_window_raise (l_window)
			end
		end

	clear_to_transparent (a_drawing: EV_DRAWING_AREA)
			-- Erase all of `a_drawing' to fully transparent.
		local
			cr: POINTER
		do
			if attached {EV_DRAWING_AREA_IMP} a_drawing.implementation as l_imp then
				cr := l_imp.cairo_context
				if not cr.is_default_pointer then
					{CAIRO}.save (cr)
					{CAIRO}.set_operator (cr, {CAIRO}.operator_source)
					{CAIRO}.set_source_rgba (cr, 0.0, 0.0, 0.0, 0.0)
					{CAIRO}.paint (cr)
					{CAIRO}.restore (cr)
				end
			end
		end

	fill_translucent_rectangle (a_drawing: EV_DRAWING_AREA; a_x, a_y, a_width, a_height: INTEGER; a_color: EV_COLOR; a_alpha: REAL_64)
			-- Fill the given area of `a_drawing' with `a_color' at opacity `a_alpha'.
		local
			cr: POINTER
		do
			if attached {EV_DRAWING_AREA_IMP} a_drawing.implementation as l_imp then
				cr := l_imp.cairo_context
				if not cr.is_default_pointer then
					{CAIRO}.save (cr)
					{CAIRO}.set_source_rgba (cr, a_color.red, a_color.green, a_color.blue, a_alpha)
					{CAIRO}.rectangle (cr, a_x.to_double, a_y.to_double, a_width.to_double, a_height.to_double)
					{CAIRO}.fill (cr)
					{CAIRO}.restore (cr)
				end
			end
		end

note
	library:	"SmartDocking: Library of reusable components for Eiffel."
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
