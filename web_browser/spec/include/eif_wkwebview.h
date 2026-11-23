/*
	description: "[
			WKWebView (macOS) displayed over a GTK3 widget, for {EV_WEB_BROWSER_IMP} (gtk3_macos).

			With the Quartz backend of GDK, the WKWebView is added as a subview of the NSView
			of the GTK toplevel window, and kept at the position of the GTK widget by `eif_wkwebview_sync`.

			With the X11 backend (XQuartz), the windows belong to the XQuartz process, so the WKWebView
			cannot be embedded: it is displayed in a borderless window of the application (overlay),
			kept over the screen position of the GTK widget. The Cocoa events of the application are
			processed by a GLib timeout, which also follows the moves of the GTK window, and keeps
			the overlay ordered just above the XQuartz window of the GTK window (found with the
			window list of the window server), so that the other windows keep their stacking order.

			The Objective-C runtime (libobjc) and the WebKit framework are loaded at run time,
			and used through the C API of the Objective-C runtime: no Objective-C compiler,
			and no link option, are needed. The delegate class receiving the events of the
			web view is created at run time.

			Strings are UTF-8.
		]"
	copyright: "Copyright (c) 1984-2026, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
*/

#ifndef EIF_WKWEBVIEW_H
#define EIF_WKWEBVIEW_H

#include <eif_eiffel.h>
#include <gtk/gtk.h>
#include <dlfcn.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>
#include <stdio.h>
#include <stdarg.h>

static void eif_wk_trace (const char *format, ...)
	/* Trace, enabled by the environment variable EIF_WKWEBVIEW_TRACE (to the standard error). */
{
	static int is_enabled = -1;
	va_list args;
	if (is_enabled < 0) {
		is_enabled = getenv ("EIF_WKWEBVIEW_TRACE") != NULL;
	}
	if (is_enabled) {
		va_start (args, format);
		fprintf (stderr, "[wkwebview] ");
		vfprintf (stderr, format, args);
		fprintf (stderr, "\n");
		fflush (stderr);
		va_end (args);
	}
}

	/* Events notified to the Eiffel object, with (kind, text, flag): result. */
#define EIF_WKWEBVIEW_LOAD_STARTED 1
#define EIF_WKWEBVIEW_NAVIGATION_REQUESTED 2	/* text = URI; a non zero result cancels the navigation. */
#define EIF_WKWEBVIEW_LOAD_FINISHED 3
#define EIF_WKWEBVIEW_LOAD_FAILED 4			/* text = error message. */
#define EIF_WKWEBVIEW_LOAD_COMMITTED 5
#define EIF_WKWEBVIEW_MESSAGE_RECEIVED 6		/* text = message. */
#define EIF_WKWEBVIEW_NEW_WINDOW_REQUESTED 7	/* text = URI (the new window is not opened). */
#define EIF_WKWEBVIEW_TITLE_CHANGED 8
#define EIF_WKWEBVIEW_URI_CHANGED 9

typedef EIF_INTEGER (*EIF_WKWEBVIEW_DISPATCH) (EIF_REFERENCE, EIF_INTEGER, EIF_POINTER, EIF_INTEGER);

typedef void *eif_id;
typedef void *eif_sel;
typedef void *eif_class;
typedef signed char eif_objc_bool;
typedef struct { double x, y, width, height; } eif_cgrect;	/* CGRect (64-bit). */

typedef struct eif_wkwebview {
	eif_id webview;					/* WKWebView */
	eif_id content_controller;		/* WKUserContentController */
	eif_id delegate;				/* EiffelWKWebViewDelegate */
	EIF_OBJECT eiffel_object;
	EIF_WKWEBVIEW_DISPATCH dispatch;
	eif_id overlay;					/* Overlay window (X11 backend), or NULL. */
	GtkWidget *widget;				/* Widget followed by the overlay (weak reference). */
	struct eif_wkwebview *next;		/* Next overlay web view. */
} eif_wkwebview;

/* -------------------------------------------------------------------------- */
/* Objective-C runtime */

static struct {
	int is_initialized;
	int is_loaded;
	eif_class (*get_class) (const char *);
	eif_sel (*sel) (const char *);
	void (*msg_send) (void);
	void (*msg_send_stret) (void);
	eif_class (*allocate_class_pair) (eif_class, const char *, size_t);
	void (*register_class_pair) (eif_class);
	eif_objc_bool (*add_method) (eif_class, eif_sel, void (*) (void), const char *);
	eif_objc_bool (*add_ivar) (eif_class, const char *, size_t, uint8_t, const char *);
	void *(*get_protocol) (const char *);
	eif_objc_bool (*add_protocol) (eif_class, void *);
	void *(*set_ivar) (eif_id, const char *, void *);
	void *(*get_ivar) (eif_id, const char *, void **);
	void *(*pool_push) (void);
	void (*pool_pop) (void *);
	eif_id (*gdk_quartz_window_get_nsview) (GdkWindow *);
} eif_objc;

#define EIF_OBJC_SYM(lib, field, name) *(void **) (&eif_objc.field) = dlsym (lib, name)

static int eif_objc_load (void)
	/* Load the Objective-C runtime and WebKit; True if available. */
{
	void *objc;
	if (!eif_objc.is_initialized) {
		eif_objc.is_initialized = 1;
		objc = dlopen ("/usr/lib/libobjc.A.dylib", RTLD_LAZY | RTLD_GLOBAL);
		if (objc && dlopen ("/System/Library/Frameworks/WebKit.framework/WebKit", RTLD_LAZY | RTLD_GLOBAL)) {
			EIF_OBJC_SYM (objc, get_class, "objc_getClass");
			EIF_OBJC_SYM (objc, sel, "sel_registerName");
			EIF_OBJC_SYM (objc, msg_send, "objc_msgSend");
			EIF_OBJC_SYM (objc, msg_send_stret, "objc_msgSend_stret");
			EIF_OBJC_SYM (objc, allocate_class_pair, "objc_allocateClassPair");
			EIF_OBJC_SYM (objc, register_class_pair, "objc_registerClassPair");
			EIF_OBJC_SYM (objc, add_method, "class_addMethod");
			EIF_OBJC_SYM (objc, add_ivar, "class_addIvar");
			EIF_OBJC_SYM (objc, get_protocol, "objc_getProtocol");
			EIF_OBJC_SYM (objc, add_protocol, "class_addProtocol");
			EIF_OBJC_SYM (objc, set_ivar, "object_setInstanceVariable");
			EIF_OBJC_SYM (objc, get_ivar, "object_getInstanceVariable");
			EIF_OBJC_SYM (objc, pool_push, "objc_autoreleasePoolPush");
			EIF_OBJC_SYM (objc, pool_pop, "objc_autoreleasePoolPop");
			EIF_OBJC_SYM (RTLD_DEFAULT, gdk_quartz_window_get_nsview, "gdk_quartz_window_get_nsview");
			eif_objc.is_loaded =
				eif_objc.get_class && eif_objc.sel && eif_objc.msg_send && eif_objc.allocate_class_pair &&
				eif_objc.register_class_pair && eif_objc.add_method && eif_objc.add_ivar &&
				eif_objc.set_ivar && eif_objc.get_ivar && eif_objc.pool_push && eif_objc.pool_pop &&
				eif_objc.get_class ("WKWebView") && eif_objc.get_class ("NSApplication");
		}
	}
	return eif_objc.is_loaded;
}

#define EIF_SEL(name) (eif_objc.sel (name))
#define EIF_CLASS(name) ((eif_id) eif_objc.get_class (name))

	/* objc_msgSend, cast to the exact type of each method (mandatory on arm64). */
static eif_id eif_msg (eif_id o, const char *s)
	{ return ((eif_id (*) (eif_id, eif_sel)) eif_objc.msg_send) (o, EIF_SEL (s)); }
static eif_id eif_msg_id (eif_id o, const char *s, eif_id a)
	{ return ((eif_id (*) (eif_id, eif_sel, eif_id)) eif_objc.msg_send) (o, EIF_SEL (s), a); }
static eif_id eif_msg_id_id (eif_id o, const char *s, eif_id a, eif_id b)
	{ return ((eif_id (*) (eif_id, eif_sel, eif_id, eif_id)) eif_objc.msg_send) (o, EIF_SEL (s), a, b); }
static eif_id eif_msg_cstr (eif_id o, const char *s, const char *a)
	{ return ((eif_id (*) (eif_id, eif_sel, const char *)) eif_objc.msg_send) (o, EIF_SEL (s), a); }
static void eif_msg_bool (eif_id o, const char *s, eif_objc_bool b)
	{ ((void (*) (eif_id, eif_sel, eif_objc_bool)) eif_objc.msg_send) (o, EIF_SEL (s), b); }
static void eif_msg_double (eif_id o, const char *s, double d)
	{ ((void (*) (eif_id, eif_sel, double)) eif_objc.msg_send) (o, EIF_SEL (s), d); }
static void eif_msg_rect (eif_id o, const char *s, eif_cgrect r)
	{ ((void (*) (eif_id, eif_sel, eif_cgrect)) eif_objc.msg_send) (o, EIF_SEL (s), r); }
static eif_objc_bool eif_msg_ret_bool (eif_id o, const char *s)
	{ return ((eif_objc_bool (*) (eif_id, eif_sel)) eif_objc.msg_send) (o, EIF_SEL (s)); }
static double eif_msg_ret_double (eif_id o, const char *s)
	{ return ((double (*) (eif_id, eif_sel)) eif_objc.msg_send) (o, EIF_SEL (s)); }
static const char *eif_msg_ret_cstr (eif_id o, const char *s)
	{ return ((const char *(*) (eif_id, eif_sel)) eif_objc.msg_send) (o, EIF_SEL (s)); }
static eif_objc_bool eif_msg_id_ret_bool (eif_id o, const char *s, eif_id a)
	{ return ((eif_objc_bool (*) (eif_id, eif_sel, eif_id)) eif_objc.msg_send) (o, EIF_SEL (s), a); }
static eif_objc_bool eif_responds_to (eif_id o, const char *s)
	{ return ((eif_objc_bool (*) (eif_id, eif_sel, eif_sel)) eif_objc.msg_send) (o, EIF_SEL ("respondsToSelector:"), EIF_SEL (s)); }

static eif_cgrect eif_msg_ret_rect (eif_id o, const char *s)
{
	eif_cgrect r;
#if defined(__x86_64__)
	((void (*) (eif_cgrect *, eif_id, eif_sel)) eif_objc.msg_send_stret) (&r, o, EIF_SEL (s));
#else
	r = ((eif_cgrect (*) (eif_id, eif_sel)) eif_objc.msg_send) (o, EIF_SEL (s));
#endif
	return r;
}

static eif_id eif_ns_string (const char *s)
	/* Autoreleased NSString for `s`. */
{
	return eif_msg_cstr (EIF_CLASS ("NSString"), "stringWithUTF8String:", s ? s : "");
}

static char *eif_c_string (eif_id ns_string)
	/* New UTF-8 copy of `ns_string` (to free with `free`), or NULL. */
{
	const char *s;
	if (!ns_string) {
		return NULL;
	}
	s = eif_msg_ret_cstr (ns_string, "UTF8String");
	return s ? strdup (s) : NULL;
}

/* -------------------------------------------------------------------------- */
/* Delegate: WKNavigationDelegate and WKScriptMessageHandler */

static eif_wkwebview *eif_wk_context (eif_id delegate)
{
	void *ctx = NULL;
	eif_objc.get_ivar (delegate, "eif_context", &ctx);
	return (eif_wkwebview *) ctx;
}

static EIF_INTEGER eif_wk_notify (eif_id delegate, EIF_INTEGER kind, const char *text, EIF_INTEGER flag)
{
	eif_wkwebview *ctx = eif_wk_context (delegate);
	EIF_INTEGER result;
	if (!ctx || !ctx->eiffel_object || !ctx->dispatch) {
		eif_wk_trace ("event %d ignored", (int) kind);
		return 0;
	}
	eif_wk_trace ("event %d (%s): calling Eiffel", (int) kind, text ? text : "");
	result = (ctx->dispatch) (eif_access (ctx->eiffel_object), kind, (EIF_POINTER) text, flag);
	eif_wk_trace ("event %d: back from Eiffel", (int) kind);
	return result;
}

static void eif_wk_did_receive_script_message (eif_id self, eif_sel cmd, eif_id controller, eif_id message)
{
	eif_id body = eif_msg (message, "body");
	char *s;
	if (body && eif_msg_id_ret_bool (body, "isKindOfClass:", EIF_CLASS ("NSString"))) {
		s = eif_c_string (body);
		if (s) {
			eif_wk_notify (self, EIF_WKWEBVIEW_MESSAGE_RECEIVED, s, 0);
			free (s);
		}
	}
}

	/* Block (Apple ABI): the function is called with the block as first argument. */
struct eif_block { void *isa; int flags; int reserved; void (*invoke) (void *, long); };

static void eif_wk_decide_policy (eif_id self, eif_sel cmd, eif_id webview, eif_id action, void *decision_handler)
{
	long policy = 1;	/* WKNavigationActionPolicyAllow */
	eif_id url = eif_msg (eif_msg (action, "request"), "URL");
	char *uri = url ? eif_c_string (eif_msg (url, "absoluteString")) : NULL;
	if (uri) {
		if (!eif_msg (action, "targetFrame")) {
				/* Opening a new window: handled by the Eiffel object. */
			eif_wk_notify (self, EIF_WKWEBVIEW_NEW_WINDOW_REQUESTED, uri, 0);
			policy = 0;
		} else if (eif_wk_notify (self, EIF_WKWEBVIEW_NAVIGATION_REQUESTED, uri, 0)) {
			policy = 0;	/* WKNavigationActionPolicyCancel */
		}
		free (uri);
	}
	((struct eif_block *) decision_handler)->invoke (decision_handler, policy);
}

static void eif_wk_did_start (eif_id self, eif_sel cmd, eif_id webview, eif_id navigation)
{
	eif_wk_notify (self, EIF_WKWEBVIEW_LOAD_STARTED, NULL, 0);
}

static void eif_wk_did_commit (eif_id self, eif_sel cmd, eif_id webview, eif_id navigation)
{
	eif_wk_notify (self, EIF_WKWEBVIEW_LOAD_COMMITTED, NULL, 0);
}

static void eif_wk_did_finish (eif_id self, eif_sel cmd, eif_id webview, eif_id navigation)
{
	eif_wk_notify (self, EIF_WKWEBVIEW_LOAD_FINISHED, NULL, 0);
}

static void eif_wk_did_fail (eif_id self, eif_sel cmd, eif_id webview, eif_id navigation, eif_id error)
{
	char *s = error ? eif_c_string (eif_msg (error, "localizedDescription")) : NULL;
	eif_wk_notify (self, EIF_WKWEBVIEW_LOAD_FAILED, s ? s : "", 0);
	free (s);
}

static void eif_wk_observe_value (eif_id self, eif_sel cmd, eif_id key_path, eif_id object, eif_id change, void *context)
	/* Key-value observation of the `title` and `URL` properties of the web view. */
{
	char *key = eif_c_string (key_path);
	if (key) {
		if (strcmp (key, "title") == 0) {
			eif_wk_notify (self, EIF_WKWEBVIEW_TITLE_CHANGED, NULL, 0);
		} else if (strcmp (key, "URL") == 0) {
			eif_wk_notify (self, EIF_WKWEBVIEW_URI_CHANGED, NULL, 0);
		}
		free (key);
	}
}

static eif_class eif_wk_delegate_class (void)
	/* Class EiffelWKWebViewDelegate, created on first use. */
{
	eif_class c = eif_objc.get_class ("EiffelWKWebViewDelegate");
	void *p;
	if (!c) {
		c = eif_objc.allocate_class_pair (eif_objc.get_class ("NSObject"), "EiffelWKWebViewDelegate", 0);
		if (c) {
			eif_objc.add_ivar (c, "eif_context", sizeof (void *), sizeof (void *) == 8 ? 3 : 2, "^v");
			eif_objc.add_method (c, EIF_SEL ("userContentController:didReceiveScriptMessage:"), (void (*) (void)) eif_wk_did_receive_script_message, "v@:@@");
			eif_objc.add_method (c, EIF_SEL ("webView:decidePolicyForNavigationAction:decisionHandler:"), (void (*) (void)) eif_wk_decide_policy, "v@:@@@?");
			eif_objc.add_method (c, EIF_SEL ("webView:didStartProvisionalNavigation:"), (void (*) (void)) eif_wk_did_start, "v@:@@");
			eif_objc.add_method (c, EIF_SEL ("webView:didCommitNavigation:"), (void (*) (void)) eif_wk_did_commit, "v@:@@");
			eif_objc.add_method (c, EIF_SEL ("webView:didFinishNavigation:"), (void (*) (void)) eif_wk_did_finish, "v@:@@");
			eif_objc.add_method (c, EIF_SEL ("webView:didFailNavigation:withError:"), (void (*) (void)) eif_wk_did_fail, "v@:@@@");
			eif_objc.add_method (c, EIF_SEL ("webView:didFailProvisionalNavigation:withError:"), (void (*) (void)) eif_wk_did_fail, "v@:@@@");
			eif_objc.add_method (c, EIF_SEL ("observeValueForKeyPath:ofObject:change:context:"), (void (*) (void)) eif_wk_observe_value, "v@:@@@^v");
			if (eif_objc.get_protocol && eif_objc.add_protocol) {
				p = eif_objc.get_protocol ("WKNavigationDelegate");
				if (p) {
					eif_objc.add_protocol (c, p);
				}
				p = eif_objc.get_protocol ("WKScriptMessageHandler");
				if (p) {
					eif_objc.add_protocol (c, p);
				}
			}
			eif_objc.register_class_pair (c);
		}
	}
	return c;
}

/* -------------------------------------------------------------------------- */
/* API */

/* -------------------------------------------------------------------------- */
/* Overlay (X11 backend) */

static eif_wkwebview *eif_wk_overlays = NULL;	/* Web views displayed in an overlay window. */
static guint eif_wk_pump_source = 0;
static int eif_wk_order_ticks = 0;			/* Ticks of `eif_wk_pump` before the next check of the stacking order. */

	/* Window list of the window server (CoreGraphics and CoreFoundation, loaded at run time). */
static struct {
	int is_initialized;
	void *(*copy_window_info) (uint32_t, uint32_t);
	long (*array_count) (void *);
	void *(*array_at) (void *, long);
	void *(*dictionary_get) (void *, void *);
	unsigned char (*number_get) (void *, long, void *);
	unsigned char (*rect_from_dictionary) (void *, eif_cgrect *);
	void (*release) (void *);
	void **key_number, **key_pid, **key_layer, **key_bounds;
} eif_cg;

static int eif_cg_load (void)
	/* Load the functions of the window list; True if available. */
{
	if (!eif_cg.is_initialized) {
		eif_cg.is_initialized = 1;
		dlopen ("/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics", RTLD_LAZY | RTLD_GLOBAL);
		*(void **) &eif_cg.copy_window_info = dlsym (RTLD_DEFAULT, "CGWindowListCopyWindowInfo");
		*(void **) &eif_cg.array_count = dlsym (RTLD_DEFAULT, "CFArrayGetCount");
		*(void **) &eif_cg.array_at = dlsym (RTLD_DEFAULT, "CFArrayGetValueAtIndex");
		*(void **) &eif_cg.dictionary_get = dlsym (RTLD_DEFAULT, "CFDictionaryGetValue");
		*(void **) &eif_cg.number_get = dlsym (RTLD_DEFAULT, "CFNumberGetValue");
		*(void **) &eif_cg.rect_from_dictionary = dlsym (RTLD_DEFAULT, "CGRectMakeWithDictionaryRepresentation");
		*(void **) &eif_cg.release = dlsym (RTLD_DEFAULT, "CFRelease");
		eif_cg.key_number = (void **) dlsym (RTLD_DEFAULT, "kCGWindowNumber");
		eif_cg.key_pid = (void **) dlsym (RTLD_DEFAULT, "kCGWindowOwnerPID");
		eif_cg.key_layer = (void **) dlsym (RTLD_DEFAULT, "kCGWindowLayer");
		eif_cg.key_bounds = (void **) dlsym (RTLD_DEFAULT, "kCGWindowBounds");
	}
	return eif_cg.copy_window_info && eif_cg.array_count && eif_cg.array_at && eif_cg.dictionary_get &&
		eif_cg.number_get && eif_cg.rect_from_dictionary && eif_cg.release &&
		eif_cg.key_number && eif_cg.key_pid && eif_cg.key_layer && eif_cg.key_bounds;
}

static long eif_cg_long (void *dictionary, void **key)
	/* Value of the number `key` in `dictionary`, or -1. */
{
	long long v = -1;
	void *n = eif_cg.dictionary_get (dictionary, *key);
	if (n) {
		eif_cg.number_get (n, 4 /* kCFNumberSInt64Type */, &v);
	}
	return (long) v;
}

static void eif_wk_overlay_order (eif_wkwebview *ctx, eif_cgrect expected)
	/* Order the overlay of `ctx` just above the window of another process whose bounds (window server
	   coordinates: origin at the top left of the main screen) are `expected`, if found. */
{
	void *list, *info, *bounds_dictionary;
	long i, count, number, overlay_index = -1, x_index = -1, x_number = 0;
	long overlay_number = ((long (*) (eif_id, eif_sel)) eif_objc.msg_send) (ctx->overlay, EIF_SEL ("windowNumber"));
	long pid = (long) getpid ();
	eif_cgrect b;

	if (!eif_cg_load ()) {
		return;
	}
	list = eif_cg.copy_window_info (1 /* kCGWindowListOptionOnScreenOnly */, 0);
	if (!list) {
		return;
	}
	count = eif_cg.array_count (list);
		/* From front to back. */
	for (i = 0; i < count && x_index < 0; i++) {
		info = eif_cg.array_at (list, i);
		number = eif_cg_long (info, eif_cg.key_number);
		if (number == overlay_number) {
			overlay_index = i;
		} else if (eif_cg_long (info, eif_cg.key_pid) != pid && eif_cg_long (info, eif_cg.key_layer) == 0) {
			bounds_dictionary = eif_cg.dictionary_get (info, *eif_cg.key_bounds);
			if (
				bounds_dictionary && eif_cg.rect_from_dictionary (bounds_dictionary, &b) &&
				b.x > expected.x - 2 && b.x < expected.x + 2 && b.y > expected.y - 2 && b.y < expected.y + 2 &&
				b.width > expected.width - 2 && b.width < expected.width + 2 &&
				b.height > expected.height - 2 && b.height < expected.height + 2)
			{
				x_index = i;
				x_number = number;
			}
		}
	}
	eif_cg.release (list);
	if (x_index >= 0 && overlay_index != x_index - 1) {
		eif_wk_trace ("overlay: ordered above window %ld", x_number);
		((void (*) (eif_id, eif_sel, long, long)) eif_objc.msg_send) (ctx->overlay, EIF_SEL ("orderWindow:relativeTo:"), 1 /* NSWindowAbove */, x_number);
	}
}

static eif_objc_bool eif_wk_can_become_key (eif_id self, eif_sel cmd)
{
	return 1;
}

static eif_cgrect eif_wk_constrain_frame (eif_id self, eif_sel cmd, eif_cgrect frame, eif_id screen)
	/* Keep the frame of the overlay as set, even over the menu bar. */
{
	return frame;
}

static eif_class eif_wk_overlay_class (void)
	/* Borderless window class that can become the key window (to type in the web view),
	   and whose frame is not constrained by AppKit (the overlay follows the GTK window). */
{
	eif_class c = eif_objc.get_class ("EiffelWKOverlayWindow");
	if (!c) {
		c = eif_objc.allocate_class_pair (eif_objc.get_class ("NSWindow"), "EiffelWKOverlayWindow", 0);
		if (c) {
			eif_objc.add_method (c, EIF_SEL ("canBecomeKeyWindow"), (void (*) (void)) eif_wk_can_become_key, "c@:");
			eif_objc.add_method (c, EIF_SEL ("canBecomeMainWindow"), (void (*) (void)) eif_wk_can_become_key, "c@:");
			eif_objc.add_method (c, EIF_SEL ("constrainFrameRect:toScreen:"), (void (*) (void)) eif_wk_constrain_frame,
				"{CGRect={CGPoint=dd}{CGSize=dd}}@:{CGRect={CGPoint=dd}{CGSize=dd}}@");
			eif_objc.register_class_pair (c);
		}
	}
	return c;
}

static int eif_wk_application_init (void)
	/* Initialize the Cocoa application of the process (no Dock icon); True if done. */
{
	static int is_done = 0;
	eif_id app;
	if (!is_done && dlopen ("/System/Library/Frameworks/AppKit.framework/AppKit", RTLD_LAZY | RTLD_GLOBAL)) {
		app = eif_msg (EIF_CLASS ("NSApplication"), "sharedApplication");
		if (app) {
				/* NSApplicationActivationPolicyAccessory */
			((eif_objc_bool (*) (eif_id, eif_sel, long)) eif_objc.msg_send) (app, EIF_SEL ("setActivationPolicy:"), 1);
			eif_msg (app, "finishLaunching");
			is_done = 1;
		}
	}
	return is_done;
}

static void eif_wk_overlay_sync (eif_wkwebview *ctx);

static gboolean eif_wk_pump (gpointer data)
	/* Process the pending Cocoa events, and update the overlay windows. */
{
	void *pool = eif_objc.pool_push ();
	eif_id app = eif_msg (EIF_CLASS ("NSApplication"), "sharedApplication");
	eif_id past = eif_msg (EIF_CLASS ("NSDate"), "distantPast");
	eif_id *mode = (eif_id *) dlsym (RTLD_DEFAULT, "NSDefaultRunLoopMode");
	eif_id event;
	eif_wkwebview *ctx, *next;
	int n = 0;

	if (mode) {
		while (n++ < 100 && (event = ((eif_id (*) (eif_id, eif_sel, unsigned long long, eif_id, eif_id, eif_objc_bool)) eif_objc.msg_send)
			(app, EIF_SEL ("nextEventMatchingMask:untilDate:inMode:dequeue:"), ~0ULL, past, *mode, 1)))
		{
			eif_msg_id (app, "sendEvent:", event);
		}
	}
	if (--eif_wk_order_ticks < 0) {
			/* Check the stacking order about every 100 ms. */
		eif_wk_order_ticks = 6;
	}
	for (ctx = eif_wk_overlays; ctx; ctx = next) {
		next = ctx->next;
		eif_wk_overlay_sync (ctx);
	}
	eif_objc.pool_pop (pool);
	return G_SOURCE_CONTINUE;
}

static int eif_wk_screen_geometry (double *left, double *bottom, double *width)
	/* Bounding box of the screens in Cocoa coordinates: left, bottom and width. True if found. */
{
	eif_id screens = eif_msg (EIF_CLASS ("NSScreen"), "screens");
	unsigned long i, count = screens ? ((unsigned long (*) (eif_id, eif_sel)) eif_objc.msg_send) (screens, EIF_SEL ("count")) : 0;
	double min_x = 0, max_x = 0, min_y = 0;
	eif_cgrect f;
	for (i = 0; i < count; i++) {
		f = eif_msg_ret_rect (((eif_id (*) (eif_id, eif_sel, unsigned long)) eif_objc.msg_send) (screens, EIF_SEL ("objectAtIndex:"), i), "frame");
		if (i == 0 || f.x < min_x) min_x = f.x;
		if (i == 0 || f.x + f.width > max_x) max_x = f.x + f.width;
		if (i == 0 || f.y < min_y) min_y = f.y;
	}
	*left = min_x;
	*bottom = min_y;
	*width = max_x - min_x;
	return count > 0 && *width > 0;
}

static double eif_wk_main_screen_top (void)
	/* Top of the main screen in Cocoa coordinates (the origin of the window server coordinates). */
{
	eif_id screens = eif_msg (EIF_CLASS ("NSScreen"), "screens");
	eif_cgrect f;
	if (!screens || ((unsigned long (*) (eif_id, eif_sel)) eif_objc.msg_send) (screens, EIF_SEL ("count")) == 0) {
		return 0;
	}
	f = eif_msg_ret_rect (((eif_id (*) (eif_id, eif_sel, unsigned long)) eif_objc.msg_send) (screens, EIF_SEL ("objectAtIndex:"), 0), "frame");
	return f.y + f.height;
}

static void eif_wk_overlay_sync (eif_wkwebview *ctx)
	/* Show the overlay window of `ctx` over its widget if the widget is visible, hide it otherwise. */
{
	GtkWidget *widget = ctx->widget;
	GtkWidget *toplevel = widget ? gtk_widget_get_toplevel (widget) : NULL;
	GdkWindow *window = (toplevel && gtk_widget_is_toplevel (toplevel)) ? gtk_widget_get_window (toplevel) : NULL;
	eif_cgrect frame, current, x_frame;
	GdkWindow *root;
	GdkRectangle extents;
	double left, bottom, width, scale, top;
	int x = 0, y = 0, ox = 0, oy = 0, root_width, root_height;
	int is_changed = 0;
	int is_visible =
		window && gtk_widget_get_mapped (widget) &&
		!(gdk_window_get_state (window) & (GDK_WINDOW_STATE_ICONIFIED | GDK_WINDOW_STATE_WITHDRAWN)) &&
		gtk_widget_translate_coordinates (widget, toplevel, 0, 0, &x, &y) &&
		eif_wk_screen_geometry (&left, &bottom, &width);

	if (!is_visible) {
		if (eif_msg_ret_bool (ctx->overlay, "isVisible")) {
			eif_msg_id (ctx->overlay, "orderOut:", NULL);
		}
		return;
	}
	gdk_window_get_origin (window, &ox, &oy);
		/* X11 root coordinates (pixels or points, depending on XQuartz) -> Cocoa coordinates (points).
		   XQuartz places the X11 root window at the left of the bounding box of the screens, and below the
		   menu bar: its top is the bottom of the bounding box plus its height. */
	root = gdk_screen_get_root_window (gtk_widget_get_screen (widget));
	root_width = gdk_window_get_width (root);
	root_height = gdk_window_get_height (root);
	scale = (root_width > 0) ? width / (double) root_width : 1.0;
	top = bottom + root_height * scale;
	frame.x = left + (ox + x) * scale;
	frame.width = gtk_widget_get_allocated_width (widget) * scale;
	frame.height = gtk_widget_get_allocated_height (widget) * scale;
	frame.y = top - (oy + y) * scale - frame.height;
	current = eif_msg_ret_rect (ctx->overlay, "frame");
	if (current.x != frame.x || current.y != frame.y || current.width != frame.width || current.height != frame.height) {
		eif_wk_trace ("overlay: origin %d,%d + %d,%d, scale %.3f, screens left %.0f top %.0f -> frame %.0f,%.0f %.0fx%.0f",
			ox, oy, x, y, scale, left, top, frame.x, frame.y, frame.width, frame.height);
		((void (*) (eif_id, eif_sel, eif_cgrect, eif_objc_bool)) eif_objc.msg_send) (ctx->overlay, EIF_SEL ("setFrame:display:"), frame, 1);
		is_changed = 1;
	}
	if (!eif_msg_ret_bool (ctx->overlay, "isVisible")) {
		eif_msg_id (ctx->overlay, "orderFront:", NULL);
		is_changed = 1;
	}
	if (is_changed || eif_wk_order_ticks == 0) {
			/* Frame of the XQuartz window (with its decorations), in window server coordinates. */
		gdk_window_get_frame_extents (window, &extents);
		x_frame.x = left + extents.x * scale;
		x_frame.y = (eif_wk_main_screen_top () - top) + extents.y * scale;
		x_frame.width = extents.width * scale;
		x_frame.height = extents.height * scale;
		eif_wk_overlay_order (ctx, x_frame);
	}
}

static eif_id eif_wk_new_overlay (eif_id content)
	/* New borderless window, hidden, with `content` as content view. */
{
	eif_cgrect zero = {0, 0, 1, 1};
	eif_id w = ((eif_id (*) (eif_id, eif_sel, eif_cgrect, unsigned long, unsigned long, eif_objc_bool)) eif_objc.msg_send)
		(eif_msg ((eif_id) eif_wk_overlay_class (), "alloc"), EIF_SEL ("initWithContentRect:styleMask:backing:defer:"),
		zero, 0 /* NSWindowStyleMaskBorderless */, 2 /* NSBackingStoreBuffered */, 0);
	if (w) {
		eif_msg_bool (w, "setReleasedWhenClosed:", 0);
		eif_msg_bool (w, "setHasShadow:", 0);
		eif_msg_id (w, "setContentView:", content);
	}
	return w;
}

/* -------------------------------------------------------------------------- */
/* API */

static int eif_wk_is_quartz (void)
	/* Is the GDK backend Quartz? */
{
	GdkDisplay *display = gdk_display_get_default ();
	return display && strcmp (G_OBJECT_TYPE_NAME (display), "GdkQuartzDisplay") == 0;
}

static EIF_BOOLEAN eif_wkwebview_is_available (void)
	/* Is WKWebView available: embedded (Quartz backend) or in an overlay window (X11 backend)? */
{
	GdkDisplay *display = gdk_display_get_default ();
	if (!display || !eif_objc_load ()) {
		return EIF_FALSE;
	}
	if (eif_wk_is_quartz ()) {
		return EIF_TEST (eif_objc.gdk_quartz_window_get_nsview != NULL);
	}
	return EIF_TEST (strcmp (G_OBJECT_TYPE_NAME (display), "GdkX11Display") == 0 && eif_wk_application_init () && eif_wk_overlay_class ());
}

static void eif_wk_set_observed (eif_wkwebview *ctx, int b)
	/* Start (if `b`) or stop observing the `title` and `URL` properties of the web view. */
{
	static const char *keys [] = {"title", "URL"};
	int i;
	for (i = 0; i < 2; i++) {
		if (b) {
			((void (*) (eif_id, eif_sel, eif_id, eif_id, unsigned long, void *)) eif_objc.msg_send)
				(ctx->webview, EIF_SEL ("addObserver:forKeyPath:options:context:"), ctx->delegate, eif_ns_string (keys [i]), 0, NULL);
		} else {
			eif_msg_id_id (ctx->webview, "removeObserver:forKeyPath:", ctx->delegate, eif_ns_string (keys [i]));
		}
	}
}

static eif_wkwebview *eif_wkwebview_new (EIF_OBJECT eiffel_object, EIF_POINTER dispatch)
{
	eif_wkwebview *ctx;
	eif_id configuration;
	eif_cgrect zero = {0, 0, 0, 0};
	void *pool;
	eif_class delegate_class;

	if (!eif_wkwebview_is_available () || !(delegate_class = eif_wk_delegate_class ())) {
		return NULL;
	}
	ctx = (eif_wkwebview *) calloc (1, sizeof (eif_wkwebview));
	if (!ctx) {
		return NULL;
	}
	pool = eif_objc.pool_push ();
	ctx->delegate = eif_msg (eif_msg ((eif_id) delegate_class, "alloc"), "init");
	eif_objc.set_ivar (ctx->delegate, "eif_context", ctx);
	configuration = eif_msg (eif_msg (EIF_CLASS ("WKWebViewConfiguration"), "alloc"), "init");
	ctx->content_controller = eif_msg (eif_msg (configuration, "userContentController"), "retain");
	eif_msg_id_id (ctx->content_controller, "addScriptMessageHandler:name:", ctx->delegate, eif_ns_string ("eiffel"));
	ctx->webview = ((eif_id (*) (eif_id, eif_sel, eif_cgrect, eif_id)) eif_objc.msg_send)
		(eif_msg (EIF_CLASS ("WKWebView"), "alloc"), EIF_SEL ("initWithFrame:configuration:"), zero, configuration);
	eif_msg (configuration, "release");
	eif_msg_id (ctx->webview, "setNavigationDelegate:", ctx->delegate);
	eif_wk_set_observed (ctx, 1);
	if (eif_wk_is_quartz ()) {
		eif_msg_bool (ctx->webview, "setHidden:", 1);
	} else {
		ctx->overlay = eif_wk_new_overlay (ctx->webview);
		ctx->next = eif_wk_overlays;
		eif_wk_overlays = ctx;
		if (!eif_wk_pump_source) {
			eif_wk_pump_source = g_timeout_add (16, eif_wk_pump, NULL);
		}
	}
	eif_objc.pool_pop (pool);
	ctx->eiffel_object = eif_adopt (eiffel_object);
	ctx->dispatch = (EIF_WKWEBVIEW_DISPATCH) dispatch;
	return ctx;
}

static void eif_wkwebview_destroy (eif_wkwebview *ctx)
{
	void *pool;
	if (!ctx) {
		return;
	}
	pool = eif_objc.pool_push ();
	eif_objc.set_ivar (ctx->delegate, "eif_context", NULL);
	eif_wk_set_observed (ctx, 0);
	eif_msg_id (ctx->webview, "setNavigationDelegate:", NULL);
	eif_msg_id (ctx->content_controller, "removeScriptMessageHandlerForName:", eif_ns_string ("eiffel"));
	eif_msg (ctx->webview, "stopLoading");
	if (ctx->overlay) {
		eif_wkwebview **p;
		for (p = &eif_wk_overlays; *p; p = &(*p)->next) {
			if (*p == ctx) {
				*p = ctx->next;
				break;
			}
		}
		if (ctx->widget) {
			g_object_remove_weak_pointer (G_OBJECT (ctx->widget), (gpointer *) &ctx->widget);
		}
		eif_msg_id (ctx->overlay, "setContentView:", NULL);
		eif_msg (ctx->overlay, "close");
		eif_msg (ctx->overlay, "release");
		if (!eif_wk_overlays && eif_wk_pump_source) {
			g_source_remove (eif_wk_pump_source);
			eif_wk_pump_source = 0;
		}
	}
	eif_msg (ctx->webview, "removeFromSuperview");
	eif_msg (ctx->webview, "release");
	eif_msg (ctx->content_controller, "release");
	eif_msg (ctx->delegate, "release");
	eif_objc.pool_pop (pool);
	if (ctx->eiffel_object) {
		eif_wean (ctx->eiffel_object);
	}
	free (ctx);
}

static void eif_wkwebview_sync (eif_wkwebview *ctx, EIF_POINTER a_widget)
	/* Show the web view over the GTK widget `a_widget` if it is mapped, hide it otherwise. */
{
	GtkWidget *widget = (GtkWidget *) a_widget;
	GtkWidget *toplevel;
	GdkWindow *window;
	eif_id view, superview;
	eif_cgrect frame;
	int x = 0, y = 0;
	void *pool = eif_objc.pool_push ();

	if (ctx->overlay) {
		if (ctx->widget != widget) {
			if (ctx->widget) {
				g_object_remove_weak_pointer (G_OBJECT (ctx->widget), (gpointer *) &ctx->widget);
			}
			ctx->widget = widget;
			g_object_add_weak_pointer (G_OBJECT (widget), (gpointer *) &ctx->widget);
		}
		eif_wk_overlay_sync (ctx);
		eif_objc.pool_pop (pool);
		return;
	}
	toplevel = gtk_widget_get_toplevel (widget);
	window = (toplevel && gtk_widget_is_toplevel (toplevel)) ? gtk_widget_get_window (toplevel) : NULL;
	view = window ? eif_objc.gdk_quartz_window_get_nsview (window) : NULL;
	if (!view || !gtk_widget_get_mapped (widget) || !gtk_widget_translate_coordinates (widget, toplevel, 0, 0, &x, &y)) {
		eif_msg_bool (ctx->webview, "setHidden:", 1);
	} else {
		superview = eif_msg (ctx->webview, "superview");
		if (superview != view) {
			if (superview) {
				eif_msg (ctx->webview, "removeFromSuperview");
			}
			eif_msg_id (view, "addSubview:", ctx->webview);
		}
		frame.x = x;
		frame.width = gtk_widget_get_allocated_width (widget);
		frame.height = gtk_widget_get_allocated_height (widget);
		if (eif_msg_ret_bool (view, "isFlipped")) {
			frame.y = y;
		} else {
			frame.y = eif_msg_ret_rect (view, "bounds").height - y - frame.height;
		}
		eif_msg_rect (ctx->webview, "setFrame:", frame);
		eif_msg_bool (ctx->webview, "setHidden:", 0);
	}
	eif_objc.pool_pop (pool);
}

static void eif_wkwebview_set_focus (eif_wkwebview *ctx)
{
	void *pool = eif_objc.pool_push ();
	eif_id window = eif_msg (ctx->webview, "window");
	if (ctx->overlay && eif_msg_ret_bool (ctx->overlay, "isVisible")) {
			/* The overlay belongs to the application, not to XQuartz: activate it to receive the keyboard. */
		eif_msg_bool (eif_msg (EIF_CLASS ("NSApplication"), "sharedApplication"), "activateIgnoringOtherApps:", 1);
		eif_msg (ctx->overlay, "makeKeyWindow");
	}
	if (window) {
		eif_msg_id (window, "makeFirstResponder:", ctx->webview);
	}
	eif_objc.pool_pop (pool);
}

static void eif_wkwebview_load_uri (eif_wkwebview *ctx, EIF_POINTER uri)
{
	void *pool = eif_objc.pool_push ();
	eif_id url = eif_msg_id (EIF_CLASS ("NSURL"), "URLWithString:", eif_ns_string ((const char *) uri));
	if (url) {
		if (eif_msg_ret_bool (url, "isFileURL")) {
				/* Local files: allow the access to the folder of the file. */
			eif_msg_id_id (ctx->webview, "loadFileURL:allowingReadAccessToURL:", url, eif_msg (url, "URLByDeletingLastPathComponent"));
		} else {
			eif_msg_id (ctx->webview, "loadRequest:", eif_msg_id (EIF_CLASS ("NSURLRequest"), "requestWithURL:", url));
		}
	}
	eif_objc.pool_pop (pool);
}

static void eif_wkwebview_load_html (eif_wkwebview *ctx, EIF_POINTER html, EIF_POINTER base_uri)
{
	void *pool = eif_objc.pool_push ();
	eif_id base = base_uri ? eif_msg_id (EIF_CLASS ("NSURL"), "URLWithString:", eif_ns_string ((const char *) base_uri)) : NULL;
	eif_msg_id_id (ctx->webview, "loadHTMLString:baseURL:", eif_ns_string ((const char *) html), base);
	eif_objc.pool_pop (pool);
}

static void eif_wkwebview_execute_script (eif_wkwebview *ctx, EIF_POINTER script)
{
	void *pool = eif_objc.pool_push ();
	eif_msg_id_id (ctx->webview, "evaluateJavaScript:completionHandler:", eif_ns_string ((const char *) script), NULL);
	eif_objc.pool_pop (pool);
}

static void eif_wkwebview_add_document_start_script (eif_wkwebview *ctx, EIF_POINTER script)
{
	void *pool = eif_objc.pool_push ();
		/* WKUserScriptInjectionTimeAtDocumentStart = 0, for the main frame only. */
	eif_id user_script = ((eif_id (*) (eif_id, eif_sel, eif_id, long, eif_objc_bool)) eif_objc.msg_send)
		(eif_msg (EIF_CLASS ("WKUserScript"), "alloc"), EIF_SEL ("initWithSource:injectionTime:forMainFrameOnly:"),
		eif_ns_string ((const char *) script), 0, 1);
	eif_msg_id (ctx->content_controller, "addUserScript:", user_script);
	eif_msg (user_script, "release");
	eif_objc.pool_pop (pool);
}

static void eif_wkwebview_perform (eif_wkwebview *ctx, EIF_POINTER selector)
	/* Send the message `selector` without argument (reload, stopLoading, goBack, goForward) to the web view. */
{
	void *pool = eif_objc.pool_push ();
	eif_msg (ctx->webview, (const char *) selector);
	eif_objc.pool_pop (pool);
}

static EIF_BOOLEAN eif_wkwebview_boolean_query (eif_wkwebview *ctx, EIF_POINTER selector)
	/* Value of the boolean property `selector` (canGoBack, canGoForward, isLoading) of the web view. */
{
	return EIF_TEST (eif_msg_ret_bool (ctx->webview, (const char *) selector));
}

static EIF_POINTER eif_wkwebview_title (eif_wkwebview *ctx)
	/* New UTF-8 string (to free with `free`), or NULL. */
{
	void *pool = eif_objc.pool_push ();
	char *s = eif_c_string (eif_msg (ctx->webview, "title"));
	eif_objc.pool_pop (pool);
	return (EIF_POINTER) s;
}

static EIF_POINTER eif_wkwebview_uri (eif_wkwebview *ctx)
	/* New UTF-8 string (to free with `free`), or NULL. */
{
	void *pool = eif_objc.pool_push ();
	eif_id url = eif_msg (ctx->webview, "URL");
	char *s = url ? eif_c_string (eif_msg (url, "absoluteString")) : NULL;
	eif_objc.pool_pop (pool);
	return (EIF_POINTER) s;
}

static EIF_REAL_64 eif_wkwebview_zoom (eif_wkwebview *ctx)
{
	if (eif_responds_to (ctx->webview, "pageZoom")) {
		return (EIF_REAL_64) eif_msg_ret_double (ctx->webview, "pageZoom");
	}
	return (EIF_REAL_64) eif_msg_ret_double (ctx->webview, "magnification");
}

static void eif_wkwebview_set_zoom (eif_wkwebview *ctx, EIF_REAL_64 zoom)
{
	if (eif_responds_to (ctx->webview, "setPageZoom:")) {
		eif_msg_double (ctx->webview, "setPageZoom:", (double) zoom);	/* macOS 11 */
	} else {
		eif_msg_double (ctx->webview, "setMagnification:", (double) zoom);
	}
}

static void eif_wkwebview_set_user_agent (eif_wkwebview *ctx, EIF_POINTER user_agent)
{
	void *pool = eif_objc.pool_push ();
	eif_msg_id (ctx->webview, "setCustomUserAgent:", eif_ns_string ((const char *) user_agent));
	eif_objc.pool_pop (pool);
}

static void eif_wkwebview_set_developer_tools_enabled (eif_wkwebview *ctx, EIF_BOOLEAN b)
{
	void *pool = eif_objc.pool_push ();
	eif_id preferences;
	if (eif_responds_to (ctx->webview, "setInspectable:")) {
		eif_msg_bool (ctx->webview, "setInspectable:", b ? 1 : 0);	/* macOS 13.3 */
	} else {
		preferences = eif_msg (eif_msg (ctx->webview, "configuration"), "preferences");
		eif_msg_id_id (preferences, "setValue:forKey:",
			((eif_id (*) (eif_id, eif_sel, eif_objc_bool)) eif_objc.msg_send) (EIF_CLASS ("NSNumber"), EIF_SEL ("numberWithBool:"), b ? 1 : 0),
			eif_ns_string ("developerExtrasEnabled"));
	}
	eif_objc.pool_pop (pool);
}

#endif
