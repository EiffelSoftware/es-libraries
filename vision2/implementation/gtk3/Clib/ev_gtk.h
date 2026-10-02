/*
indexing
	description: "Include file for gtk and Eiffel runtime features"
	date: "$Date$"
	revision: "$Revision$"
	copyright:	"Copyright (c) 1984-2006, Eiffel Software and others"
	license:	"Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			 Eiffel Software
			 356 Storke Road, Goleta, CA 93117 USA
			 Telephone 805-685-1006, Fax 805-685-6869
			 Website http://www.eiffel.com
			 Customer support http://support.eiffel.com
		]"
*/

#ifndef _EV_GTK_H_INCLUDED_
#define _EV_GTK_H_INCLUDED_

#include <gtk/gtk.h>
#include <gio/gio.h>
#include <pango/pangocairo.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#include <X11/Xlib.h>
#endif
#ifdef GDK_WINDOWING_WAYLAND
#include <gdk/gdkwayland.h>
#endif

/* 
	For macOs GDB_BACKEND quarts maybe we need  
    to check GDK_WINDOWING_QUARTZ
*/
#ifdef EIF_MACOSX
	#include <TargetConditionals.h>
	#ifdef TARGET_OS_MAC
		#include <gdk/gdk.h>
		#include <gdk/gdkquartz.h>
	#endif
#endif


#include <eif_eiffel.h>

/* For dev/debug purpose, added output print statement */
#define EV_PRINTF(str) printf(str)
#define EV_PRINTF_1(str, p1) printf(str, p1)
#define EV_PRINTF_2(str, p1, p2) printf(str, p1, p1)

#ifdef EIF_IL_DLL
/* 
 * Uncomment the following definition when debugging .Net projects
 */
#define IL_EV_PRINTF(str) //EV_PRINTF(str)
#define IL_EV_PRINTF_1(str, p1) //EV_PRINTF_1(str, p1)
#define IL_EV_PRINTF_2(str, p1, p2) //EV_PRINTF_2(str, p1, p1)
#else
#define IL_EV_PRINTF(str)
#define IL_EV_PRINTF_1(str, p1)
#define IL_EV_PRINTF_2(str, p1, p2)
#endif

/* Default font DPI used by Vision2 GTK conversions (96 dpi). */
#define EV_VISION2_DEFAULT_FONT_DPI 96
/* gtk-xft-dpi and Pango font sizes use dpi * PANGO_SCALE (1024). */
#define EV_VISION2_PANGO_DEFAULT_DPI (EV_VISION2_DEFAULT_FONT_DPI * PANGO_SCALE)

/*
 * GSettings for org.gnome.desktop.interface, or NULL when the schema (or its
 * text-scaling-factor key) is not installed, e.g. on macOS without
 * gsettings-desktop-schemas: g_settings_new aborts the process in that case.
 */
static GSettings *ev_desktop_interface_settings_new (void)
{
	GSettingsSchemaSource *source;
	GSettingsSchema *schema;
	GSettings *settings = NULL;

	source = g_settings_schema_source_get_default ();
	if (source != NULL) {
		schema = g_settings_schema_source_lookup (source, "org.gnome.desktop.interface", TRUE);
		if (schema != NULL) {
			if (g_settings_schema_has_key (schema, "text-scaling-factor")) {
				settings = g_settings_new_full (schema, NULL, NULL);
			}
			g_settings_schema_unref (schema);
		}
	}
	return settings;
}

static gdouble ev_gnome_text_scaling_factor (void)
{
	gdouble result = 1.0;
	GSettings *settings = ev_desktop_interface_settings_new ();

	if (settings != NULL) {
		result = g_settings_get_double (settings, "text-scaling-factor");
		g_object_unref (settings);
	}

	if (result <= 0.0) {
		result = 1.0;
	}
	return result;
}

static gint ev_gtk_xft_dpi (void)
{
	gint xft_dpi = 0;
	GtkSettings *gtk_settings = gtk_settings_get_default ();

	if (gtk_settings != NULL) {
		g_object_get (gtk_settings, "gtk-xft-dpi", &xft_dpi, NULL);
	}
	if (xft_dpi <= 0) {
		xft_dpi = EV_VISION2_PANGO_DEFAULT_DPI;
	}
	return xft_dpi;
}

static gint ev_effective_pango_dpi (void)
{
	return (gint) (ev_gtk_xft_dpi () * ev_gnome_text_scaling_factor () + 0.5);
}

static gdouble ev_text_scaling_factor (void)
{
	return (gdouble) ev_effective_pango_dpi () / (gdouble) EV_VISION2_PANGO_DEFAULT_DPI;
}

static gint ev_pixels_from_points (gint points)
{
	return (gint) ((points * (gdouble) ev_effective_pango_dpi ()) / (72.0 * (gdouble) PANGO_SCALE) + 0.5);
}

static gint ev_points_from_pixels (gint pixels)
{
	gint effective_dpi = ev_effective_pango_dpi ();

	if (pixels <= 0 || effective_dpi <= 0) {
		return 0;
	}
	return (gint) ((pixels * 72.0 * (gdouble) PANGO_SCALE) / (gdouble) effective_dpi + 0.5);
}

static void ev_sync_pango_layout_with_gtk_widget (PangoLayout *layout, GtkWidget *widget)
{
	PangoContext *layout_context;
	PangoContext *widget_context;
	gdouble dpi;

	if (layout == NULL || widget == NULL) {
		return;
	}
	layout_context = pango_layout_get_context (layout);
	if (layout_context == NULL) {
		return;
	}
	dpi = 0.0;
	widget_context = gtk_widget_get_pango_context (widget);
	if (widget_context != NULL) {
		dpi = pango_cairo_context_get_resolution (widget_context);
	}
	if (dpi <= 0.0) {
		dpi = (gdouble) ev_effective_pango_dpi () / (gdouble) PANGO_SCALE;
	}
	pango_cairo_context_set_resolution (layout_context, dpi);
}

static gpointer ev_text_scaling_gsettings_new (void)
{
	return (gpointer) ev_desktop_interface_settings_new ();
}

/*
 * GTK drags started in this process (dragging selected text, a color swatch, ...).
 * The count is kept on the default display rather than in a static variable, as
 * this header is included in many C files and each would get its own copy.
 */
#define EV_GTK_DRAG_SOURCE_COUNT_KEY "ev-gtk-drag-source-count"

static gboolean ev_gtk_drag_source_hook (GSignalInvocationHint *ihint, guint n_param_values, const GValue *param_values, gpointer data)
{
	GObject *display = G_OBJECT (gdk_display_get_default ());
	gint count;

	if (display != NULL) {
		count = GPOINTER_TO_INT (g_object_get_data (display, EV_GTK_DRAG_SOURCE_COUNT_KEY)) + GPOINTER_TO_INT (data);
		g_object_set_data (display, EV_GTK_DRAG_SOURCE_COUNT_KEY, GINT_TO_POINTER (count > 0 ? count : 0));
	}
		/* Keep the hook installed. */
	return TRUE;
}

static void ev_gtk_install_drag_source_hooks (void)
{
	gpointer widget_class = g_type_class_ref (GTK_TYPE_WIDGET);

	g_signal_add_emission_hook (g_signal_lookup ("drag-begin", GTK_TYPE_WIDGET), 0, ev_gtk_drag_source_hook, GINT_TO_POINTER (1), NULL);
	g_signal_add_emission_hook (g_signal_lookup ("drag-end", GTK_TYPE_WIDGET), 0, ev_gtk_drag_source_hook, GINT_TO_POINTER (-1), NULL);
	g_type_class_unref (widget_class);
}

static gboolean ev_gtk_is_drag_source_active (void)
{
	GdkDisplay *display = gdk_display_get_default ();
	GdkSeat *seat;
	GdkDevice *pointer;

	if (display == NULL || GPOINTER_TO_INT (g_object_get_data (G_OBJECT (display), EV_GTK_DRAG_SOURCE_COUNT_KEY)) <= 0) {
		return FALSE;
	}
		/* A drag in progress holds the pointer grab: should a "drag-end" ever be missed,
		 * this keeps the events from being dispatched by GTK alone forever. */
	seat = gdk_display_get_default_seat (display);
	pointer = (seat != NULL) ? gdk_seat_get_pointer (seat) : NULL;
	return pointer != NULL && gdk_display_device_is_grabbed (display, pointer);
}

/*
 * Clamp width/height before GdkPixbuf/Cairo pixmap creation.
 * Minimum 1 avoids 0x0 surfaces (X_CreatePixmap BadValue during resize/docking).
 * Maximum 32767 is INT16_MAX: the X11/Cairo/pixman stack still treats coordinates
 * as signed 16-bit in places; larger values overflow or fail at the X server.
 */
static gint ev_safe_pixmap_dimension (gint value)
{
	if (value <= 0) {
		return 1;
	}
	if (value > 32767) {
		return 32767;
	}
	return value;
}

static GdkPixbuf *
ev_gdk_pixbuf_new_safe (GdkColorspace colorspace, gboolean has_alpha, gint bits_per_sample, gint width, gint height)
{
	return gdk_pixbuf_new (colorspace, has_alpha, bits_per_sample,
		ev_safe_pixmap_dimension (width), ev_safe_pixmap_dimension (height));
}

static GdkPixbuf *
ev_gdk_pixbuf_scale_simple_safe (GdkPixbuf *src, gint width, gint height, GdkInterpType interp)
{
	if (src == NULL || !GDK_IS_PIXBUF (src)) {
		return ev_gdk_pixbuf_new_safe (GDK_COLORSPACE_RGB, TRUE, 8, 1, 1);
	}
	return gdk_pixbuf_scale_simple (src,
		ev_safe_pixmap_dimension (width), ev_safe_pixmap_dimension (height), interp);
}

static GdkPixbuf *
ev_gdk_pixbuf_get_from_surface_safe (cairo_surface_t *surface, gint src_x, gint src_y, gint width, gint height)
{
	GdkPixbuf *result;

	if (surface == NULL) {
		return ev_gdk_pixbuf_new_safe (GDK_COLORSPACE_RGB, TRUE, 8, 1, 1);
	}
	result = gdk_pixbuf_get_from_surface (surface, src_x, src_y,
		ev_safe_pixmap_dimension (width), ev_safe_pixmap_dimension (height));
	if (result == NULL) {
		return ev_gdk_pixbuf_new_safe (GDK_COLORSPACE_RGB, TRUE, 8, 1, 1);
	}
	return result;
}

static GdkPixbuf *
ev_gdk_pixbuf_new_subpixbuf_safe (GdkPixbuf *src, gint src_x, gint src_y, gint width, gint height)
{
	GdkPixbuf *result;

	if (src == NULL || !GDK_IS_PIXBUF (src)) {
		return ev_gdk_pixbuf_new_safe (GDK_COLORSPACE_RGB, TRUE, 8, 1, 1);
	}
	result = gdk_pixbuf_new_subpixbuf (src, src_x, src_y,
		ev_safe_pixmap_dimension (width), ev_safe_pixmap_dimension (height));
	if (result == NULL) {
		return ev_gdk_pixbuf_new_safe (GDK_COLORSPACE_RGB, TRUE, 8, 1, 1);
	}
	return result;
}

static GdkPixbuf *
ev_gdk_pixbuf_get_from_window_safe (GdkWindow *window, gint src_x, gint src_y, gint width, gint height)
{
	GdkPixbuf *result;

	if (window == NULL) {
		return ev_gdk_pixbuf_new_safe (GDK_COLORSPACE_RGB, TRUE, 8, 1, 1);
	}
	result = gdk_pixbuf_get_from_window (window, src_x, src_y,
		ev_safe_pixmap_dimension (width), ev_safe_pixmap_dimension (height));
	if (result == NULL) {
		return ev_gdk_pixbuf_new_safe (GDK_COLORSPACE_RGB, TRUE, 8, 1, 1);
	}
	return result;
}

static GdkCursor *
ev_gdk_cursor_new_from_pixbuf_safe (GdkDisplay *display, GdkPixbuf *pixbuf, gint x, gint y)
{
	gint width, height;

	if (display == NULL) {
		return NULL;
	}
	if (pixbuf == NULL || !GDK_IS_PIXBUF (pixbuf)) {
		return gdk_cursor_new_for_display (display, GDK_LEFT_PTR);
	}
	width = gdk_pixbuf_get_width (pixbuf);
	height = gdk_pixbuf_get_height (pixbuf);
	if (width <= 0 || height <= 0) {
		return gdk_cursor_new_for_display (display, GDK_LEFT_PTR);
	}
	if (x < 0) {
		x = 0;
	}
	if (y < 0) {
		y = 0;
	}
	if (x >= width) {
		x = width - 1;
	}
	if (y >= height) {
		y = height - 1;
	}
	return gdk_cursor_new_from_pixbuf (display, pixbuf, x, y);
}

static void
ev_g_value_set_boolean (GValue *value, gboolean b)
{
	if (!G_VALUE_HOLDS_BOOLEAN (value)) {
		g_value_init (value, G_TYPE_BOOLEAN);
	}
	g_value_set_boolean (value, b);
}

/* Which GDK backend is actually live, as opposed to which session type the
 * environment advertises. The two differ under XWayland, where XDG_SESSION_TYPE
 * says "wayland" while GDK instantiates a GdkX11Display -- which is what
 * EV_APPLICATION_IMP.make deliberately arranges by restricting the allowed
 * backends to "x11,wayland,broadway,*". Only meaningful once gtk_init has run;
 * before that there is no default display and both return FALSE. */
static gboolean
ev_gdk_display_is_x11 (void)
{
#ifdef GDK_WINDOWING_X11
	GdkDisplay *display = gdk_display_get_default ();
	return display != NULL && GDK_IS_X11_DISPLAY (display);
#else
	return FALSE;
#endif
}

static gboolean
ev_gdk_display_is_wayland (void)
{
#ifdef GDK_WINDOWING_WAYLAND
	GdkDisplay *display = gdk_display_get_default ();
	return display != NULL && GDK_IS_WAYLAND_DISPLAY (display);
#else
	return FALSE;
#endif
}

/* Cairo context drawing straight onto `window', used by EV_SCREEN for the root
 * window. gdk_cairo_create is deprecated since GTK 3.22 in favour of
 * gdk_window_begin_draw_frame, which only applies to a window this process
 * owns and so cannot serve the root window. */
static cairo_t *
ev_gdk_window_create_cairo_context (GdkWindow *window)
{
	cairo_t *result = NULL;

	if (window != NULL) {
		G_GNUC_BEGIN_IGNORE_DEPRECATIONS
		result = gdk_cairo_create (window);
		G_GNUC_END_IGNORE_DEPRECATIONS
	}
	return result;
}

static gint
ev_g_object_get_eif_oid (gpointer object)
{
	if (object == NULL || !G_IS_OBJECT (object)) {
		return -1;
	}
	return (gint) (rt_int_ptr) g_object_get_data (G_OBJECT (object), "eif_oid");
}

typedef struct {
	/* Offset to add to a GDK root coordinate to obtain the matching Vision2
	 * logical coordinate. Vision2 places its origin at the top left of the
	 * PRIMARY monitor, to match the Win32 implementation. */
	gint origin_x;
	gint origin_y;
	/* Top left of the virtual desktop, in Vision2 logical coordinates. This is
	 * NOT the same as (origin_x, origin_y): the root coordinate space starts at
	 * (min_x, min_y), which is the root origin under X11 but can be negative
	 * under a native Wayland backend or any layout placing a monitor left of or
	 * above the primary one. */
	gint virtual_x;
	gint virtual_y;
	gint virtual_width;
	gint virtual_height;
	gint primary_width;
	gint primary_height;
	gint monitor_count;
} EvGdkVirtualScreen;

static void
ev_gdk_query_virtual_screen (EvGdkVirtualScreen *screen)
{
	GdkDisplay *display;
	int i, num_monitors;
	gint min_x, min_y, max_x, max_y;
	GdkMonitor *primary;

	if (screen == NULL) {
		return;
	}

	display = gdk_display_get_default ();
	num_monitors = gdk_display_get_n_monitors (display);
	min_x = min_y = G_MAXINT;
	max_x = max_y = G_MININT;

	for (i = 0; i < num_monitors; i++) {
		GdkRectangle rect;
		GdkMonitor *monitor = gdk_display_get_monitor (display, i);

		gdk_monitor_get_geometry (monitor, &rect);
		min_x = MIN (min_x, rect.x);
		min_y = MIN (min_y, rect.y);
		max_x = MAX (max_x, rect.x + rect.width);
		max_y = MAX (max_y, rect.y + rect.height);
	}

	primary = gdk_display_get_primary_monitor (display);
	if (primary != NULL) {
		GdkRectangle rect;

		gdk_monitor_get_geometry (primary, &rect);
		screen->origin_x = -rect.x;
		screen->origin_y = -rect.y;
		screen->primary_width = rect.width;
		screen->primary_height = rect.height;
	} else if (num_monitors > 0) {
		GdkRectangle rect;

		gdk_monitor_get_geometry (gdk_display_get_monitor (display, 0), &rect);
		screen->origin_x = -rect.x;
		screen->origin_y = -rect.y;
		screen->primary_width = rect.width;
		screen->primary_height = rect.height;
	} else {
		screen->origin_x = 0;
		screen->origin_y = 0;
		screen->primary_width = 0;
		screen->primary_height = 0;
	}

	if (num_monitors > 0) {
		screen->virtual_x = min_x + screen->origin_x;
		screen->virtual_y = min_y + screen->origin_y;
		screen->virtual_width = max_x - min_x;
		screen->virtual_height = max_y - min_y;
	} else {
		screen->virtual_x = 0;
		screen->virtual_y = 0;
		screen->virtual_width = 0;
		screen->virtual_height = 0;
	}
	screen->monitor_count = num_monitors;
}

#endif
