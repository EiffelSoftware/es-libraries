/*
	description: "[
			WKWebView (macOS) displayed over a GTK3 widget (GDK Quartz backend), for {EV_WEB_BROWSER_IMP} (gtk3_macos).

			The WKWebView is added as a subview of the NSView of the GTK toplevel window,
			and kept at the position of the GTK widget by `eif_wkwebview_sync`.

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

	/* Events notified to the Eiffel object, with (kind, text, flag): result. */
#define EIF_WKWEBVIEW_LOAD_STARTED 1
#define EIF_WKWEBVIEW_NAVIGATION_REQUESTED 2	/* text = URI; a non zero result cancels the navigation. */
#define EIF_WKWEBVIEW_LOAD_FINISHED 3
#define EIF_WKWEBVIEW_LOAD_FAILED 4			/* text = error message. */
#define EIF_WKWEBVIEW_LOAD_COMMITTED 5
#define EIF_WKWEBVIEW_MESSAGE_RECEIVED 6		/* text = message. */
#define EIF_WKWEBVIEW_NEW_WINDOW_REQUESTED 7	/* text = URI (the new window is not opened). */

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
				eif_objc.gdk_quartz_window_get_nsview && eif_objc.get_class ("WKWebView");
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
	if (!ctx || !ctx->eiffel_object || !ctx->dispatch) {
		return 0;
	}
	return (ctx->dispatch) (eif_access (ctx->eiffel_object), kind, (EIF_POINTER) text, flag);
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

static EIF_BOOLEAN eif_wkwebview_is_available (void)
	/* Is WKWebView available with the current GDK backend (Quartz)? */
{
	GdkDisplay *display = gdk_display_get_default ();
	return EIF_TEST (display && strcmp (G_OBJECT_TYPE_NAME (display), "GdkQuartzDisplay") == 0 && eif_objc_load ());
}

static eif_wkwebview *eif_wkwebview_new (EIF_REFERENCE eiffel_object, EIF_POINTER dispatch)
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
	eif_msg_bool (ctx->webview, "setHidden:", 1);
	eif_objc.pool_pop (pool);
	ctx->eiffel_object = eif_protect (eiffel_object);
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
	eif_msg_id (ctx->webview, "setNavigationDelegate:", NULL);
	eif_msg_id (ctx->content_controller, "removeScriptMessageHandlerForName:", eif_ns_string ("eiffel"));
	eif_msg (ctx->webview, "stopLoading");
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
