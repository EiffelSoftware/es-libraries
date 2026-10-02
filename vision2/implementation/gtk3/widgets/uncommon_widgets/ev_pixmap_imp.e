note
	description: "EiffelVision pixmap, GTK implementation."
	legal: "See notice at end of class."
	status: "See notice at end of class."
	keywords: "drawable, primitives, figures, buffer, bitmap, picture"
	date: "$Date$"
	revision: "$Revision$"

class
	EV_PIXMAP_IMP

inherit
	EV_PIXMAP_I
		redefine
			end_drawing_session,
			interface,
			flush,
			save_to_named_path
		end

	EV_DRAWABLE_IMP
		redefine
			interface,
			end_drawing_session,
			pixbuf_from_drawable_at_position
		end

	EV_PRIMITIVE_IMP
		undefine
			foreground_color_internal,
			background_color_internal,
			set_foreground_color,
			set_background_color
		redefine
			interface,
			width,
			height,
			destroy,
			c_object_dispose,
			make,
			process_draw_event
		end

create
	make

feature {NONE} -- Initialization

	old_make (an_interface: attached like interface)
			-- Create a gtk pixmap of size (1 * 1) with no mask.
		do
			assign_interface (an_interface)
		end

	make
			-- Initialize `Current'
		local
			l_app_imp: like app_implementation
			l_expose_actions: like expose_actions
		do
			set_c_object ({GTK}.gtk_drawing_area_new)
			Precursor {EV_PRIMITIVE_IMP}
			l_app_imp := app_implementation

				-- Connect Draw event (replacing previous expose-event)
			real_signal_connect_after (visual_widget,
					{EV_GTK_EVENT_STRINGS}.draw_event_name,
					agent (l_app_imp.gtk_marshal).draw_actions_event (c_object, ?))

			set_size (1, 1)

				-- Initialize the Graphical Context
			init_default_values
			clear_rectangle (0, 0, 1, 1)

				-- Initialize expose actions so blitting may occur.	
			l_expose_actions := expose_actions
		end

	init_from_pointer_style (a_pointer_style: EV_POINTER_STYLE)
			-- Initialize from `a_pointer_style'
		local
			l_pixbuf, l_xpm: POINTER
		do
			check
				attached {EV_POINTER_STYLE_IMP} a_pointer_style.implementation as a_pointer_style_imp
			then
				if a_pointer_style_imp.predefined_cursor_code > 0 then
						-- We are building from a stock cursor.
					inspect
						a_pointer_style_imp.predefined_cursor_code
					when {EV_POINTER_STYLE_CONSTANTS}.busy_cursor then
						l_xpm := {EV_STOCK_PIXMAPS_IMP}.busy_cursor_xpm
					when {EV_POINTER_STYLE_CONSTANTS}.wait_cursor then
						l_xpm := {EV_STOCK_PIXMAPS_IMP}.wait_cursor_xpm
					when {EV_POINTER_STYLE_CONSTANTS}.crosshair_cursor then
						l_xpm := {EV_STOCK_PIXMAPS_IMP}.crosshair_cursor_xpm
					when {EV_POINTER_STYLE_CONSTANTS}.help_cursor then
						l_xpm := {EV_STOCK_PIXMAPS_IMP}.help_cursor_xpm
					when {EV_POINTER_STYLE_CONSTANTS}.ibeam_cursor then
						l_xpm := {EV_STOCK_PIXMAPS_IMP}.ibeam_cursor_xpm
					when {EV_POINTER_STYLE_CONSTANTS}.no_cursor then
						l_xpm := {EV_STOCK_PIXMAPS_IMP}.no_cursor_xpm
					when {EV_POINTER_STYLE_CONSTANTS}.sizeall_cursor then
						l_xpm := {EV_STOCK_PIXMAPS_IMP}.sizeall_cursor_xpm
					when {EV_POINTER_STYLE_CONSTANTS}.sizenesw_cursor then
						l_xpm := {EV_STOCK_PIXMAPS_IMP}.sizenesw_cursor_xpm
					when {EV_POINTER_STYLE_CONSTANTS}.sizens_cursor then
						l_xpm := {EV_STOCK_PIXMAPS_IMP}.sizens_cursor_xpm
					when {EV_POINTER_STYLE_CONSTANTS}.sizenwse_cursor then
						l_xpm := {EV_STOCK_PIXMAPS_IMP}.sizenwse_cursor_xpm
					when {EV_POINTER_STYLE_CONSTANTS}.sizewe_cursor then
						l_xpm := {EV_STOCK_PIXMAPS_IMP}.sizewe_cursor_xpm
					when {EV_POINTER_STYLE_CONSTANTS}.uparrow_cursor then
						l_xpm := {EV_STOCK_PIXMAPS_IMP}.uparrow_cursor_xpm
					when {EV_POINTER_STYLE_CONSTANTS}.standard_cursor then
						l_xpm := {EV_STOCK_PIXMAPS_IMP}.standard_cursor_xpm
					else
						l_xpm := default_pointer
					end
					if l_xpm.is_default_pointer then
						l_xpm := default_pointer
						set_size (a_pointer_style.width, a_pointer_style.height)
						clear
					else
						set_from_xpm_data (l_xpm)
					end
				else
					l_pixbuf := a_pointer_style_imp.gdk_pixbuf
					if not l_pixbuf.is_default_pointer then
						set_pixmap_from_pixbuf (a_pointer_style_imp.gdk_pixbuf)
					else
						set_size (a_pointer_style.width, a_pointer_style.height)
						clear
					end
				end
			end
		end

	init_from_pixel_buffer (a_pixel_buffer: EV_PIXEL_BUFFER)
			-- Initialize from `a_pixel_buffer'
		do
			check attached {EV_PIXEL_BUFFER_IMP} a_pixel_buffer.implementation as l_pixel_buffer_imp then
				set_pixmap_from_pixbuf (l_pixel_buffer_imp.gdk_pixbuf)
			end
		end

feature -- Drawing operations

	update_if_needed
			-- Update `Current' if needed.
		do
			if not in_expose_actions then
				{GTK}.gtk_widget_queue_draw (visual_widget)
			end
		end

	redraw
			-- Force `Current' to redraw itself.
		do
			if is_displayed then
				{GTK}.gtk_widget_queue_draw (visual_widget)
			end
		end

	flush
			-- Ensure that the appearance of `Current' is updated on screen
			-- immediately. Any changes that have not yet been reflected will
			-- become visible.
		do
			refresh_now
		end

	disable_double_buffering
			-- Disable double buffering for exposed areas.
		note
			eis: "name=gtk_widget_set_double_buffered", "src=https://developer.gnome.org/gtk3/stable/GtkWidget.html#gtk-widget-set-double-buffered"
		obsolete
			"Disabling double buffering is mostly detrimental to the performance of an app. [2021-06-01]"
			-- In 3.10 GTK and GDK have been restructured for translucent drawing.
			-- Since then expose events for double-buffered widgets are culled into a single event to the toplevel GDK window.
			-- If you now unset double buffering, you will cause a separate rendering pass for every widget.
			-- This will likely cause rendering problems - in particular related to stacking -
			-- and usually increases rendering times significantly.
		do
			-- {GTK2}.gtk_widget_set_double_buffered (visual_widget, False)
		end

feature -- Measurement

	width: INTEGER
			-- Width of the pixmap in pixels.
			--| Logical pixels. The backing store holds `surface_scale' times as many
			--| in each direction; see `surface_scale'.
		do
			if cairo_surface /= default_pointer then
				Result := {CAIRO}.image_surface_get_width (cairo_surface) // surface_scale
			end
		end

	height: INTEGER
			-- height of the pixmap.
			--| See `width'.
		do
			if cairo_surface /= default_pointer then
				Result := {CAIRO}.image_surface_get_height (cairo_surface) // surface_scale
			end
		end

feature -- Element change

	read_from_named_path (file_path: PATH)
			-- Attempt to load pixmap data from a file specified by `file_name'.
		local
			a_cs: EV_GTK_C_STRING
			g_error: POINTER
			filepixbuf: POINTER
			e: EV_GLIB_ERROR
			m: READABLE_STRING_32
		do
			create a_cs.make_from_path (file_path)
			filepixbuf := {GDK}.gdk_pixbuf_new_from_file (a_cs.item, $g_error)
			if g_error /= default_pointer then
					-- GDK cannot not load the image. Raise an exception.
				create e.make_from_pointer (g_error)
				m := e.message
				e.free
				{EXCEPTIONS}.raise (m)
			end
			set_pixmap_from_pixbuf (filepixbuf)
				-- Unreference pixbuf so that it may be collected.
			{GOBJECT}.g_object_unref (filepixbuf)
		end

	pixbuf: POINTER
			-- Converts the Cairo surface to a GdkPixbuf
			--| Logical size, via `pixbuf_from_drawable_at_position' so that the device
			--| scale is accounted for in exactly one place.
		do
			if not cairo_surface.is_default_pointer then
				Result := pixbuf_from_drawable_at_position (0, 0, 0, 0, width, height)
			end
		end

	set_with_default
			-- Initialize the pixmap with the default
			-- pixmap (Vision2 logo)
		do
			set_from_xpm_data (default_pixmap_xpm)
		end

	stretch (a_x, a_y: INTEGER)
			-- Stretch the image to fit in size `a_x' by `a_y'.
		local
			a_gdkpixbuf, scaled_pixbuf: POINTER
			a_scale_type: INTEGER
			l_width, l_height, l_target_width, l_target_height: INTEGER
		do
			l_width := width
			l_height := height
			l_target_width := app_implementation.safe_pixmap_dimension (a_x)
			l_target_height := app_implementation.safe_pixmap_dimension (a_y)
			if l_width /= l_target_width or else l_height /= l_target_height then
				a_gdkpixbuf := pixbuf_from_drawable
				if l_target_width <= 16 and then l_target_height <= 16 then
						-- For small images this method scales better
					a_scale_type := {GDK}.gdk_interp_nearest
				else
						-- For larger images this mode provides better scaling
					a_scale_type := {GDK}.gdk_interp_bilinear
				end
				scaled_pixbuf := {GDK}.gdk_pixbuf_scale_simple (a_gdkpixbuf, l_target_width, l_target_height, a_scale_type)
				{GOBJECT}.g_object_unref (a_gdkpixbuf)
				set_pixmap_from_pixbuf (scaled_pixbuf)
				{GOBJECT}.g_object_unref (scaled_pixbuf)
			end
		end

	set_size (a_width, a_height: INTEGER)
			-- Set the size of the pixmap to `a_width' by `a_height'.
			--
			--| `a_width' / `a_height' are logical, and the backing store is allocated at
			--| `drawing_buffer_scale' times that: whatever is drawn here afterwards is
			--| generated by cairo, so it can be generated at the display's resolution
			--| and composited crisply. Loading an image into the pixmap replaces the
			--| surface again, at that image's own scale.
		local
			l_width, l_height, l_scale: INTEGER
		do
			l_width := app_implementation.safe_pixmap_dimension (a_width)
			l_height := app_implementation.safe_pixmap_dimension (a_height)
			l_scale := drawing_buffer_scale
			release_previous_cairo_surface
			set_cairo_surface (
					{CAIRO}.image_surface_create ({CAIRO}.format_argb32, l_width * l_scale, l_height * l_scale),
					l_scale)
			get_new_cairo_context
			init_default_values
		end

	drawing_buffer_scale: INTEGER
			-- Scale to allocate the backing store of a drawing buffer at.
			--
			--| The GDK scale factor of the display, so that a pixmap drawn into and then
			--| composited through cairo carries the resolution the screen can show. Set
			--| EV_PIXMAP_DEVICE_SCALE to "no" to pin it back to 1, which restores the
			--| pre-HiDPI behaviour of allocating every surface at logical size.
		do
			Result := app_implementation.screen_scale_factor.max (1)
			if
				Result > 1 and then
				attached {EXECUTION_ENVIRONMENT}.item (once "EV_PIXMAP_DEVICE_SCALE") as e and then
				e.is_case_insensitive_equal_general ("no")
			then
				Result := 1
			end
		ensure
			positive: Result >= 1
		end

	reset_for_buffering (a_width, a_height: INTEGER)
			-- Resets the size of the pixmap without keeping original image or clearing background.
		do
			set_size (a_width, a_height)
		end

	set_mask (a_mask: EV_BITMAP)
			-- Set the GdkBitmap used for masking `Current'.
		do
		end

feature {EV_GTK_DEPENDENT_APPLICATION_IMP, EV_ANY_I} -- Implementation

	pixbuf_from_drawable_at_position (src_x, src_y, dest_x, dest_y, a_width, a_height: INTEGER): POINTER
			-- Return a GdkPixbuf object from the current Gdkpixbuf structure
			--
			--| The one place where the backing store is read as raw pixels, so the one
			--| place that has to know about `surface_scale'. Everything else reaching
			--| for the surface goes through cairo (`create_context',
			--| `set_source_surface'), which applies the device scale itself.
			--|
			--| `src_x' / `src_y' and the result are in LOGICAL pixels, which is what
			--| every caller assumes: `pixbuf', `save_to_named_path', `stretch',
			--| `EV_PIXMAPABLE_IMP.internal_set_pixmap', `EV_PIXEL_BUFFER_IMP'. Keeping
			--| that contract is why the device-sized read below is scaled back down
			--| rather than handed out as is.
		local
			l_width, l_height, l_scale: INTEGER
			l_device_pixbuf: POINTER
		do
			l_width := app_implementation.safe_pixmap_dimension (a_width)
			l_height := app_implementation.safe_pixmap_dimension (a_height)
			l_scale := surface_scale
			if not cairo_surface.is_default_pointer then
				if l_scale = 1 then
					Result := {GDK}.gdk_pixbuf_get_from_surface (cairo_surface, src_x, src_y, l_width, l_height)
				else
						-- `gdk_pixbuf_get_from_surface' reads the backing store directly and
						-- ignores the surface device scale -- verified against GTK 3.24, a
						-- request for the logical size comes back as the top left corner
						-- rather than the whole surface. So ask in backing-store pixels.
					l_device_pixbuf := {GDK}.gdk_pixbuf_get_from_surface (cairo_surface,
							src_x * l_scale, src_y * l_scale,
							l_width * l_scale, l_height * l_scale)
					if not l_device_pixbuf.is_default_pointer then
						Result := {GDK}.gdk_pixbuf_scale_simple (l_device_pixbuf, l_width, l_height, {GDK}.gdk_interp_bilinear)
						{GOBJECT}.g_object_unref (l_device_pixbuf)
					end
				end
			end
			if Result.is_default_pointer then
				Result := {GDK}.gdk_pixbuf_new (0, True, 8, l_width, l_height)
			end
		end

	device_pixbuf_from_drawable: POINTER
			-- GdkPixbuf holding the whole backing store of `Current' at its full
			-- resolution, i.e. `width' * `surface_scale' by `height' * `surface_scale'.
			--| Unlike `pixbuf_from_drawable' this keeps whatever extra detail a scaled
			--| surface carries. For consumers that can place a pixbuf at a scale --
			--| saving to a file at full resolution, say -- rather than the ones that
			--| assume pixbuf size equals logical size.
		local
			l_scale: INTEGER
		do
			l_scale := surface_scale
			if not cairo_surface.is_default_pointer then
				Result := {GDK}.gdk_pixbuf_get_from_surface (cairo_surface, 0, 0,
						app_implementation.safe_pixmap_dimension (width * l_scale),
						app_implementation.safe_pixmap_dimension (height * l_scale))
			end
			if Result.is_default_pointer then
				Result := {GDK}.gdk_pixbuf_new (0, True, 8,
						app_implementation.safe_pixmap_dimension (width * l_scale),
						app_implementation.safe_pixmap_dimension (height * l_scale))
			end
		end

feature {EV_INTERMEDIARY_ROUTINES} -- Implementation

	in_expose_actions: BOOLEAN
			-- Is `Current' in an expose action?

	process_draw_event (a_cairo_context: POINTER): BOOLEAN
			-- Call the expose actions for the drawing area.
		local
			l_width, l_height: INTEGER
		do
			l_width := {GTK}.gtk_widget_get_allocated_width (c_object)
			l_height := {GTK}.gtk_widget_get_allocated_height (c_object)

			{CAIRO}.set_source_surface (a_cairo_context, cairo_surface, (l_width - width) / 2, (l_height - height) / 2)

			if attached expose_actions_internal as l_expose_actions then
				in_expose_actions := True
					-- Even if the callback on "draw" event provides a cairo_context, the implementation
					-- will use a new one using the expected cairo_surface.
				start_drawing_session
				l_expose_actions.call (app_implementation.gtk_marshal.dimension_tuple (0, 0, l_width, l_height))
				end_drawing_session
				in_expose_actions := False
			end

			{CAIRO}.paint (a_cairo_context)
		end

feature -- Access

	raw_image_data: EV_RAW_IMAGE_DATA
		local
--			a_gdkimage, a_visual: POINTER
--			a_visual_type, a_pixel: INTEGER
--			a_color: POINTER
--			a_color_map: POINTER
--			a_width: INTEGER
--			array_offset, array_size: INTEGER
--			array_area: SPECIAL [NATURAL_8]
--			color_struct_size: INTEGER
		do
			create Result.make_with_alpha_zero (width, height)
			Result.set_originating_pixmap (attached_interface)
--			a_gdkimage := {GDK}.gdk_image_get (drawable, 0, 0, width, height)

--			from
--				a_width := width * 4
----				a_color_map := {GDK}.gdk_screen_get_rgb_colormap ({GTK2}.gdk_screen_get_default)
--				a_visual := {GDK}.gdk_colormap_get_visual (a_color_map)
--				a_visual_type := {GDK}.gdk_visual_struct_type (a_visual)
--				a_color := {GTK}.c_gdk_color_struct_allocate
--				array_size := a_width * height
--				array_area := Result.area
--				color_struct_size := {GTK}.c_gdk_color_struct_size
--			until
--				array_offset = array_size
--			loop
----				a_pixel := {GDK}.gdk_image_get_pixel (
----					a_gdkimage,
----					(array_offset \\ (a_width) // 4), -- Zero based X coord
----					((array_offset) // a_width) -- Zero based Y coord
----				)
--				{GDK}.gdk_colormap_query_color (a_color_map, a_pixel, a_color)
--					-- RGB values of a_color are 16 bit.
--				array_area.put (({GDK}.gdk_color_struct_red (a_color) // 256).to_natural_8, array_offset)
--				array_area.put (({GDK}.gdk_color_struct_green (a_color) // 256).to_natural_8, array_offset + 1)
--				array_area.put (({GDK}.gdk_color_struct_blue (a_color) // 256).to_natural_8, array_offset + 2)
--				array_area.put (255, array_offset + 3)
--				array_offset := array_offset + 4
--			end
--			a_color.memory_free
--			{GDK}.gdk_image_destroy (a_gdkimage)
		end

feature -- Duplication

	copy_pixmap (other: EV_PIXMAP)
			-- Update `Current' to have same appearance as `other'.
			-- (So as to satisfy `is_equal'.)
		local
			l_width, l_height, l_scale: INTEGER
			cr: POINTER
		do
			if attached {EV_PIXMAP_IMP} other.implementation as l_other_imp then
				l_width := app_implementation.safe_pixmap_dimension (l_other_imp.width)
				l_height := app_implementation.safe_pixmap_dimension (l_other_imp.height)
				l_scale := l_other_imp.surface_scale
				release_previous_cairo_surface
					-- Match the source's scale, so a copy of a crisp pixmap stays crisp and
					-- a copy of a raster one is not blown up for nothing. `set_source_surface'
					-- below works in user space, so the paint is correct either way.
				set_cairo_surface (
						{CAIRO}.image_surface_create ({CAIRO}.format_argb32, l_width * l_scale, l_height * l_scale),
						l_scale)
				get_new_cairo_context
				cr := cairo_context
				init_default_values
				{CAIRO}.set_source_surface (cr, l_other_imp.cairo_surface, 0, 0)
				{CAIRO}.paint (cr)
				{CAIRO}.set_source_rgb (cr, 0, 0, 0)
			end
		end

feature {EV_ANY_I, EV_GTK_DEPENDENT_APPLICATION_IMP} -- Implementation

	set_pixmap_from_pixbuf (a_pixbuf: POINTER)
			-- Attempt to load pixmap data from a file specified by `file_name'.
			--| At scale 1: `a_pixbuf' is the limit of the available detail, so giving the
			--| surface a device scale would blow a 16x16 icon up to 48x48 and blur it
			--| rather than sharpen it. Use `set_pixmap_from_scaled_pixbuf' for a pixbuf
			--| that was actually rendered at a scale.
		do
			set_pixmap_from_scaled_pixbuf (a_pixbuf, 1)
		end

	set_pixmap_from_scaled_pixbuf (a_pixbuf: POINTER; a_scale: INTEGER)
			-- Load pixmap data from `a_pixbuf', whose pixels are `a_scale' per logical
			-- pixel -- as returned by `gtk_icon_theme_load_icon_for_scale', say.
		require
			positive_scale: a_scale >= 1
		local
			cr: POINTER
			l_width, l_height: INTEGER
		do
			l_width := app_implementation.safe_pixmap_dimension ({GDK}.gdk_pixbuf_get_width (a_pixbuf))
			l_height := app_implementation.safe_pixmap_dimension ({GDK}.gdk_pixbuf_get_height (a_pixbuf))
			release_previous_cairo_surface
				-- `l_width' / `l_height' are the pixbuf's own pixel count, which is
				-- already the backing-store size; the logical size is that over `a_scale'.
			set_cairo_surface (
					{CAIRO}.image_surface_create ({CAIRO}.FORMAT_ARGB32, l_width, l_height),
					a_scale)
			get_new_cairo_context
			cr := cairo_context
			set_drawing_mode (drawing_mode_copy)

				-- Temporarily set the source to the pixbuf so that we can draw it on to the drawable.
			if a_scale > 1 then
					-- The context works in user space, where the surface is only
					-- `l_width' / `a_scale' wide, while `a_pixbuf' is `l_width' pixels.
					-- Without this the paint would cover the top left corner alone.
				{CAIRO}.save (cr)
				{CAIRO}.scale (cr, 1.0 / a_scale, 1.0 / a_scale)
				{GDK_CAIRO}.set_source_pixbuf (cr, a_pixbuf, 0, 0)
				{CAIRO}.paint (cr)
				{CAIRO}.restore (cr)
			else
				{GDK_CAIRO}.set_source_pixbuf (cr, a_pixbuf, 0, 0)
				{CAIRO}.paint (cr)
			end

				-- Reset the cairo context back to rgb source of black.
			{CAIRO}.set_source_rgb (cr, 0, 0, 0)
		end

feature {EV_ANY_I} -- Drawing wrapper

	pre_drawing
		local
			cr: like cairo_context
		do
				-- If inside drawing session
				-- the cairo context is already created in `start_drawing_session`
			if not is_in_drawing_session then
					-- Reuse or get once a new cairo_context
				get_cairo_context
				cr := cairo_context
				if not cr.is_default_pointer then
					{CAIRO}.save (cr)
				end
			end
		end

	post_drawing
		local
			cr: like cairo_context
		do
				-- If inside drawing session
				-- keep the cairo context for the next draw operation, it will be releazed by `end_drawing_session`
			if not is_in_drawing_session then
				cr := cairo_context
				if not cr.is_default_pointer then
					{CAIRO}.restore (cr)
				end
				update_if_needed
			end
		end

feature {NONE} -- Session implementation				

	end_drawing_session
		do
			if is_in_top_drawing_session then
				update_if_needed
			end
			Precursor
		end

feature {EV_ANY_I} -- cairo object access

	cairo_surface: POINTER
			-- Cairo drawable surface used for storing pixmap data in RGB format.

	surface_scale: INTEGER
			-- Backing-store pixels per logical pixel in `cairo_surface'.
			--
			--| 1 for a pixmap whose content came from a raster source: a 16x16 PNG has
			--| no more detail to show, and blowing its surface up to 48x48 would only
			--| cost memory and blur it. Larger for a surface whose content is generated
			--| at that resolution -- a drawing buffer from `set_size', or a themed icon
			--| loaded through `gtk_icon_theme_load_icon_for_scale'.
			--|
			--| Kept alongside the surface rather than read back from it on demand,
			--| because `width' and `height' are on hot paths. Every producer that
			--| assigns `cairo_surface' has to assign this too, which is what
			--| `set_cairo_surface' is for.
			--|
			--| Normalized here rather than in the attribute: INTEGER is
			--| self-initializing, so an attribute body would never run and a pixmap
			--| whose surface was assigned without going through `set_cairo_surface'
			--| would divide by zero in `width'.
		do
			Result := internal_surface_scale.max (1)
		ensure
			positive: Result >= 1
		end

	internal_surface_scale: INTEGER
			-- Scale stored by `set_cairo_surface'; read it through `surface_scale'.

	set_cairo_surface (a_surface: POINTER; a_scale: INTEGER)
			-- Make `a_surface', whose backing store holds `a_scale' pixels per logical
			-- pixel, the surface of `Current'.
		require
			positive_scale: a_scale >= 1
		do
			cairo_surface := a_surface
			internal_surface_scale := a_scale
			if a_scale > 1 and then not a_surface.is_default_pointer then
				{CAIRO}.set_device_scale (a_surface, a_scale, a_scale)
			end
		ensure
			surface_set: cairo_surface = a_surface
			scale_set: surface_scale = a_scale
		end

	get_cairo_context
		local
			l_surface: like cairo_surface
		do
			if cairo_context.is_default_pointer then
				l_surface := cairo_surface
				if not l_surface.is_default_pointer then
					cairo_context := {CAIRO}.create_context (l_surface)
				end
			end
		end

feature {EV_ANY_I} -- cairo object release

	release_cairo_surface (a_surface: POINTER)
		do
			if not a_surface.is_default_pointer then
				{CAIRO}.surface_destroy (a_surface)
			end
		end

	release_previous_cairo_surface
		do
			clear_cairo_context
			release_cairo_surface (cairo_surface)
			cairo_surface := default_pointer
		end

feature {EV_GTK_DEPENDENT_APPLICATION_IMP, EV_ANY_I} -- Implementation

	internal_xpm_data: POINTER
		-- Pointer to the appropriate XPM image used for the default stock cursor if any

feature {EV_STOCK_PIXMAPS_IMP, EV_PIXMAPABLE_IMP, EV_PIXEL_BUFFER_IMP} -- Implementation

	set_from_xpm_data (a_xpm_data: POINTER)
			-- Pixmap symbolizing a piece of information.
		require
			xpm_data_not_null: a_xpm_data /= default_pointer
		local
			xpmpixbuf: POINTER
		do
				-- Store internal xpm data for default stock cursor handling.
			internal_xpm_data := a_xpm_data
			xpmpixbuf := {GDK}.gdk_pixbuf_new_from_xpm_data (a_xpm_data)

			set_pixmap_from_pixbuf (xpmpixbuf)
				-- Unreference pixbuf so that it may be collected.
			{GOBJECT}.g_object_unref (xpmpixbuf)
		end

	set_from_stock_id (a_stock_id: POINTER)
			-- Pixmap symbolizing a piece of information
		require
			a_stock_id_not_null: a_stock_id /= default_pointer
		local
			stock_pixbuf: POINTER
			l_error: POINTER
			l_screen: POINTER
			l_scale: INTEGER
		do
				-- Check if the current widget realized as well
				-- Gtk-WARNING produces "Drawing a gadget with negative dimensions"
			if not {GTK2}.gtk_widget_get_realized (c_object) then
				{GTK}.gtk_widget_realize (c_object)
			end
			if {GTK2}.gtk_widget_has_screen(c_object) then
				l_screen:= {GTK2}.gtk_widget_get_screen(c_object)
			else
				l_screen:= {GDK}.gdk_screen_get_default
			end
				-- A themed icon does have a higher-resolution variant to offer, so ask
				-- for the one matching the display: 48 stays the logical size and the
				-- pixbuf comes back 48 * `l_scale' wide. This is the case
				-- `set_pixmap_from_scaled_pixbuf' exists for.
			l_scale := drawing_buffer_scale
			stock_pixbuf := {GTK2}.gtk_icon_theme_load_icon_for_scale (
					{GTK2}.gtk_icon_theme_get_for_screen (l_screen), a_stock_id, 48, l_scale, 0, $l_error)
			if stock_pixbuf = default_pointer and then l_scale > 1 then
					-- No variant at that scale; fall back to the 1x lookup.
				l_scale := 1
				stock_pixbuf := {GTK2}.gtk_icon_theme_load_icon (
						{GTK2}.gtk_icon_theme_get_for_screen (l_screen), a_stock_id, 48, 0, $l_error)
			end
			if stock_pixbuf /= default_pointer then
					-- GTK only promises the best available icon, not exactly 48 * `l_scale'
					-- pixels. Trusting the requested scale against a pixbuf that came back
					-- at some other size would hand out a wrong logical size, so check.
				if {GDK}.gdk_pixbuf_get_width (stock_pixbuf) /= 48 * l_scale then
					l_scale := 1
				end
					-- If a stock pixmap can be found then set it, else do nothing.
				set_pixmap_from_scaled_pixbuf (stock_pixbuf, l_scale)
				{GOBJECT}.g_object_unref (stock_pixbuf)
			end
		end

feature {NONE} -- Implementation

	save_to_named_path (a_format: EV_GRAPHICAL_FORMAT; a_file_path: PATH)
			-- Save `Current' in `a_format' to `a_file_path'
		local
			a_gdkpixbuf, stretched_pixbuf: POINTER
			a_handle, a_filetype: EV_GTK_C_STRING
			gerror: POINTER
			e: EV_GLIB_ERROR
			m: READABLE_STRING_32
		do
			if app_implementation.writeable_pixbuf_formats.has (a_format.file_extension.as_upper) then
					-- Perform custom saving with GdkPixbuf
				a_gdkpixbuf := pixbuf_from_drawable
				create a_handle.make_from_path (a_file_path)
				a_filetype := a_format.file_extension
				if a_format.scale_width > 0 and then a_format.scale_height > 0 then
					stretched_pixbuf := {GDK}.gdk_pixbuf_scale_simple (a_gdkpixbuf, a_format.scale_width, a_format.scale_height, {GDK}.gdk_interp_bilinear)
						-- Unref original pixbuf so it gets deleted from memory
					{GOBJECT}.g_object_unref (a_gdkpixbuf)
						-- Set our scaled pixbuf to be the one that is saved
					a_gdkpixbuf := stretched_pixbuf
				end
				{GDK}.gdk_pixbuf_save (a_gdkpixbuf, a_handle.item, a_filetype.item, $gerror)
				{GOBJECT}.g_object_unref (a_gdkpixbuf)
				if not gerror.is_default_pointer then
						-- GDK cannot save the image. Raise an exception.
					create e.make_from_pointer (gerror)
					m := e.message
					e.free
					{EXCEPTIONS}.raise (m)
				end
			else
					-- If Gtk cannot save the file then the default is called.
				Precursor {EV_PIXMAP_I} (a_format, a_file_path)
			end
		end

	destroy
			-- Destroy the pixmap and resources.
		do
			clear_cairo_context
			if not cairo_surface.is_default_pointer then
				release_cairo_surface (cairo_surface)
				cairo_surface := default_pointer
			end
			Precursor {EV_PRIMITIVE_IMP}
		end

	c_object_dispose
			-- Called when `c_object' is destroyed.
			-- Only called if `Current' is referenced from `c_object'.
			-- Render `Current' unusable.
		do
			if not cairo_context.is_default_pointer then
				{CAIRO}.destroy (cairo_context)
				cairo_context := default_pointer
			end
			if not cairo_surface.is_default_pointer then
				{CAIRO}.surface_destroy (cairo_surface)
				cairo_surface := default_pointer
			end
			Precursor
		end

feature {NONE} -- Externals

	default_pixmap_xpm: POINTER
		external
			"C | %"ev_c_util.h%""
		alias
			"default_pixmap_xpm"
		end

feature {NONE} -- Constants

	Monochrome_color_depth: INTEGER = 1
			-- Black and White color depth (for mask).

feature {EV_ANY, EV_ANY_I} -- Implementation

	interface: detachable EV_PIXMAP note option: stable attribute end

note
	ca_ignore: "CA011", "CA011: too many arguments"
	copyright:	"Copyright (c) 1984-2024, Eiffel Software and others"
	license:	"Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"

end
