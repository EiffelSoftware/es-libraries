/*
	description: "C interface of Clib/eif_webview2.c: Microsoft Edge WebView2 for {EV_WEB_BROWSER_IMP} (mswin)."
	copyright: "Copyright (c) 1984-2026, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
*/

#ifndef EIF_WEBVIEW2_H
#define EIF_WEBVIEW2_H

#include <eif_eiffel.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct eif_webview2 eif_webview2;

	/* Events notified to the Eiffel object, with (kind, text, flag):
	   READY: flag = HRESULT of the creation (0 if the web view is ready).
	   NAVIGATION_STARTING: text = URI; a non zero result cancels the navigation.
	   NAVIGATION_COMPLETED: flag = 0 if success, the WebView2 web error status + 1 otherwise.
	   SOURCE_CHANGED, TITLE_CHANGED: no data.
	   WEB_MESSAGE_RECEIVED: text = message.
	   NEW_WINDOW_REQUESTED: text = URI (the new window is not opened). */
#define EIF_WEBVIEW2_READY 1
#define EIF_WEBVIEW2_NAVIGATION_STARTING 2
#define EIF_WEBVIEW2_NAVIGATION_COMPLETED 3
#define EIF_WEBVIEW2_SOURCE_CHANGED 4
#define EIF_WEBVIEW2_TITLE_CHANGED 5
#define EIF_WEBVIEW2_WEB_MESSAGE_RECEIVED 6
#define EIF_WEBVIEW2_NEW_WINDOW_REQUESTED 7

	/* Eiffel routine receiving the events: (Current, kind, text (wide string, or NULL), flag): result. */
typedef EIF_INTEGER (*EIF_WEBVIEW2_DISPATCH) (EIF_REFERENCE, EIF_INTEGER, EIF_POINTER, EIF_INTEGER);

extern eif_webview2 *eif_webview2_new (EIF_POINTER parent, EIF_OBJECT eiffel_object, EIF_POINTER dispatch);
extern void eif_webview2_destroy (eif_webview2 *ctx);
extern EIF_BOOLEAN eif_webview2_is_ready (eif_webview2 *ctx);
extern void eif_webview2_set_bounds (eif_webview2 *ctx, EIF_INTEGER width, EIF_INTEGER height);
extern void eif_webview2_parent_window_moved (eif_webview2 *ctx);
extern void eif_webview2_set_focus (eif_webview2 *ctx);
extern void eif_webview2_navigate (eif_webview2 *ctx, EIF_POINTER uri);
extern void eif_webview2_navigate_to_string (eif_webview2 *ctx, EIF_POINTER html);
extern void eif_webview2_execute_script (eif_webview2 *ctx, EIF_POINTER script);
extern void eif_webview2_add_document_start_script (eif_webview2 *ctx, EIF_POINTER script);
extern void eif_webview2_reload (eif_webview2 *ctx);
extern void eif_webview2_stop (eif_webview2 *ctx);
extern void eif_webview2_go_back (eif_webview2 *ctx);
extern void eif_webview2_go_forward (eif_webview2 *ctx);
extern EIF_BOOLEAN eif_webview2_can_go_back (eif_webview2 *ctx);
extern EIF_BOOLEAN eif_webview2_can_go_forward (eif_webview2 *ctx);
extern EIF_POINTER eif_webview2_source (eif_webview2 *ctx);
extern EIF_POINTER eif_webview2_title (eif_webview2 *ctx);
extern void eif_webview2_free_string (EIF_POINTER s);
extern EIF_REAL_64 eif_webview2_zoom_factor (eif_webview2 *ctx);
extern void eif_webview2_set_zoom_factor (eif_webview2 *ctx, EIF_REAL_64 z);
extern void eif_webview2_set_user_agent (eif_webview2 *ctx, EIF_POINTER user_agent);
extern void eif_webview2_set_dev_tools_enabled (eif_webview2 *ctx, EIF_BOOLEAN b);

#ifdef __cplusplus
}
#endif

#endif
