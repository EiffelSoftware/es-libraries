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

static gdouble ev_gnome_text_scaling_factor (void)
{
	gdouble result = 1.0;
	GSettings *settings = NULL;

	if (g_type_class_peek (G_TYPE_SETTINGS) != NULL &&
		g_settings_schema_source_get_default () != NULL) {
		settings = g_settings_new ("org.gnome.desktop.interface");
		if (settings != NULL) {
			result = g_settings_get_double (settings, "text-scaling-factor");
			g_object_unref (settings);
		}
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
	if (g_type_class_peek (G_TYPE_SETTINGS) == NULL ||
		g_settings_schema_source_get_default () == NULL) {
		return NULL;
	}
	return (gpointer) g_settings_new ("org.gnome.desktop.interface");
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

#endif
