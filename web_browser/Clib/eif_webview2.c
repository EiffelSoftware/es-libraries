/*
	description: "[
			Microsoft Edge WebView2 hosted in a window, for {EV_WEB_BROWSER_IMP} (mswin).

			The WebView2 environment and controller are created asynchronously:
			`eif_webview2_new` returns at once, and the Eiffel object is notified with
			EIF_WEBVIEW2_READY when the web view can be used (or failed to be created).

			WebView2Loader.dll is loaded at run time (from the folder of the executable, or the PATH);
			when it is not found, the WebView2 Runtime is located from the registry and its
			EmbeddedBrowserWebView.dll is used directly, so that no DLL has to be distributed
			with the applications.
		]"
	copyright: "Copyright (c) 1984-2026, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
*/

#ifndef UNICODE
#define UNICODE
#endif
#ifndef _UNICODE
#define _UNICODE
#endif
#ifndef COBJMACROS
#define COBJMACROS
#endif

#include <windows.h>
#include <objbase.h>
#include <stdlib.h>
#include <string.h>
#include <wchar.h>

#include "eif_webview2.h"
#include "eif_webview2_api.h"

/* -------------------------------------------------------------------------- */
/* Context */

struct eif_webview2 {
	LONG ref_count;				/* References: the Eiffel object, and each pending asynchronous creation. */
	HWND parent;
	ICoreWebView2Controller *controller;
	ICoreWebView2 *webview;
	EIF_OBJECT eiffel_object;	/* Protected Eiffel object receiving the events, NULL once destroyed. */
	EIF_WEBVIEW2_DISPATCH dispatch;
	int is_destroyed;
};

static void context_add_ref (eif_webview2 *ctx)
{
	InterlockedIncrement (&ctx->ref_count);
}

static void context_release (eif_webview2 *ctx)
{
	if (InterlockedDecrement (&ctx->ref_count) == 0) {
		free (ctx);
	}
}

static EIF_INTEGER notify (eif_webview2 *ctx, EIF_INTEGER kind, LPCWSTR text, EIF_INTEGER flag)
	/* Notify the Eiffel object of the event `kind`. */
{
	if (ctx->is_destroyed || !ctx->eiffel_object || !ctx->dispatch) {
		return 0;
	}
	return (ctx->dispatch) (eif_access (ctx->eiffel_object), kind, (EIF_POINTER) text, flag);
}

/* -------------------------------------------------------------------------- */
/* COM event handlers.
   All the handlers have the same layout: the vtable, a reference count, and the context.
   The IUnknown methods are shared; `Invoke` is specific to each handler interface. */

typedef struct eif_handler {
	const void *lpVtbl;
	LONG ref_count;
	eif_webview2 *ctx;
	const IID *iid;
} eif_handler;

static HRESULT STDMETHODCALLTYPE handler_query_interface (eif_handler *This, REFIID riid, void **ppv)
{
	if (!ppv) {
		return E_POINTER;
	}
	if (IsEqualIID (riid, &IID_IUnknown) || IsEqualIID (riid, This->iid)) {
		*ppv = This;
		InterlockedIncrement (&This->ref_count);
		return S_OK;
	}
	*ppv = NULL;
	return E_NOINTERFACE;
}

static ULONG STDMETHODCALLTYPE handler_add_ref (eif_handler *This)
{
	return (ULONG) InterlockedIncrement (&This->ref_count);
}

static ULONG STDMETHODCALLTYPE handler_release (eif_handler *This)
{
	LONG n = InterlockedDecrement (&This->ref_count);
	if (n == 0) {
		context_release (This->ctx);
		free (This);
	}
	return (ULONG) n;
}

static void *new_handler (const void *vtbl, const IID *iid, eif_webview2 *ctx)
	/* New handler with a reference count of 1, keeping a reference to `ctx`. */
{
	eif_handler *h = (eif_handler *) calloc (1, sizeof (eif_handler));
	if (h) {
		h->lpVtbl = vtbl;
		h->ref_count = 1;
		h->ctx = ctx;
		h->iid = iid;
		context_add_ref (ctx);
	}
	return h;
}

#define HANDLER_IUNKNOWN(T) \
	(HRESULT (STDMETHODCALLTYPE *) (T *, REFIID, void **)) handler_query_interface, \
	(ULONG (STDMETHODCALLTYPE *) (T *)) handler_add_ref, \
	(ULONG (STDMETHODCALLTYPE *) (T *)) handler_release

#define CTX(This) (((eif_handler *) (This))->ctx)

/* Navigation starting: veto by the Eiffel object. */

static HRESULT STDMETHODCALLTYPE on_navigation_starting (ICoreWebView2NavigationStartingEventHandler *This, ICoreWebView2 *sender, ICoreWebView2NavigationStartingEventArgs *args)
{
	LPWSTR uri = NULL;
	if (SUCCEEDED (args->lpVtbl->get_Uri (args, &uri)) && uri) {
		if (notify (CTX (This), EIF_WEBVIEW2_NAVIGATION_STARTING, uri, 0)) {
			args->lpVtbl->put_Cancel (args, TRUE);
		}
		CoTaskMemFree (uri);
	}
	return S_OK;
}

static const ICoreWebView2NavigationStartingEventHandlerVtbl navigation_starting_vtbl = {
	HANDLER_IUNKNOWN (ICoreWebView2NavigationStartingEventHandler),
	on_navigation_starting
};

/* Navigation completed. */

static HRESULT STDMETHODCALLTYPE on_navigation_completed (ICoreWebView2NavigationCompletedEventHandler *This, ICoreWebView2 *sender, ICoreWebView2NavigationCompletedEventArgs *args)
{
	BOOL is_success = FALSE;
	COREWEBVIEW2_WEB_ERROR_STATUS status = 0;
	args->lpVtbl->get_IsSuccess (args, &is_success);
	if (!is_success) {
		args->lpVtbl->get_WebErrorStatus (args, &status);
	}
		/* flag: 0 if success, the web error status + 1 otherwise. */
	notify (CTX (This), EIF_WEBVIEW2_NAVIGATION_COMPLETED, NULL, is_success ? 0 : (EIF_INTEGER) status + 1);
	return S_OK;
}

static const ICoreWebView2NavigationCompletedEventHandlerVtbl navigation_completed_vtbl = {
	HANDLER_IUNKNOWN (ICoreWebView2NavigationCompletedEventHandler),
	on_navigation_completed
};

/* Source changed. */

static HRESULT STDMETHODCALLTYPE on_source_changed (ICoreWebView2SourceChangedEventHandler *This, ICoreWebView2 *sender, ICoreWebView2SourceChangedEventArgs *args)
{
	notify (CTX (This), EIF_WEBVIEW2_SOURCE_CHANGED, NULL, 0);
	return S_OK;
}

static const ICoreWebView2SourceChangedEventHandlerVtbl source_changed_vtbl = {
	HANDLER_IUNKNOWN (ICoreWebView2SourceChangedEventHandler),
	on_source_changed
};

/* Document title changed. */

static HRESULT STDMETHODCALLTYPE on_title_changed (ICoreWebView2DocumentTitleChangedEventHandler *This, ICoreWebView2 *sender, IUnknown *args)
{
	notify (CTX (This), EIF_WEBVIEW2_TITLE_CHANGED, NULL, 0);
	return S_OK;
}

static const ICoreWebView2DocumentTitleChangedEventHandlerVtbl title_changed_vtbl = {
	HANDLER_IUNKNOWN (ICoreWebView2DocumentTitleChangedEventHandler),
	on_title_changed
};

/* Web message received (from `window.chrome.webview.postMessage`). */

static HRESULT STDMETHODCALLTYPE on_web_message_received (ICoreWebView2WebMessageReceivedEventHandler *This, ICoreWebView2 *sender, ICoreWebView2WebMessageReceivedEventArgs *args)
{
	LPWSTR message = NULL;
	if (SUCCEEDED (args->lpVtbl->TryGetWebMessageAsString (args, &message)) && message) {
		notify (CTX (This), EIF_WEBVIEW2_WEB_MESSAGE_RECEIVED, message, 0);
		CoTaskMemFree (message);
	}
	return S_OK;
}

static const ICoreWebView2WebMessageReceivedEventHandlerVtbl web_message_received_vtbl = {
	HANDLER_IUNKNOWN (ICoreWebView2WebMessageReceivedEventHandler),
	on_web_message_received
};

/* New window requested: handled by the Eiffel object (opened in the current view, if allowed). */

static HRESULT STDMETHODCALLTYPE on_new_window_requested (ICoreWebView2NewWindowRequestedEventHandler *This, ICoreWebView2 *sender, ICoreWebView2NewWindowRequestedEventArgs *args)
{
	LPWSTR uri = NULL;
	args->lpVtbl->put_Handled (args, TRUE);
	if (SUCCEEDED (args->lpVtbl->get_Uri (args, &uri)) && uri) {
		notify (CTX (This), EIF_WEBVIEW2_NEW_WINDOW_REQUESTED, uri, 0);
		CoTaskMemFree (uri);
	}
	return S_OK;
}

static const ICoreWebView2NewWindowRequestedEventHandlerVtbl new_window_requested_vtbl = {
	HANDLER_IUNKNOWN (ICoreWebView2NewWindowRequestedEventHandler),
	on_new_window_requested
};

/* Controller created. */

static void register_handler (eif_webview2 *ctx, void *handler, HRESULT (STDMETHODCALLTYPE *add) (ICoreWebView2 *, void *, EventRegistrationToken *))
	/* Register `handler` with `add`, and release the reference of the creation. */
{
	EventRegistrationToken token;
	if (handler) {
		add (ctx->webview, handler, &token);
		((IUnknown *) handler)->lpVtbl->Release ((IUnknown *) handler);
	}
}

#define REGISTER(ctx, vtbl, iid, method) \
	register_handler (ctx, new_handler (&vtbl, &iid, ctx), \
		(HRESULT (STDMETHODCALLTYPE *) (ICoreWebView2 *, void *, EventRegistrationToken *)) (ctx)->webview->lpVtbl->method)

static HRESULT STDMETHODCALLTYPE on_controller_created (ICoreWebView2CreateCoreWebView2ControllerCompletedHandler *This, HRESULT result, ICoreWebView2Controller *controller)
{
	eif_webview2 *ctx = CTX (This);
	ICoreWebView2Settings *settings = NULL;

	if (ctx->is_destroyed) {
		if (SUCCEEDED (result) && controller) {
			controller->lpVtbl->Close (controller);
		}
		return S_OK;
	}
	if (FAILED (result) || !controller) {
		notify (ctx, EIF_WEBVIEW2_READY, NULL, (EIF_INTEGER) result);
		return S_OK;
	}
	controller->lpVtbl->AddRef (controller);
	ctx->controller = controller;
	if (FAILED (controller->lpVtbl->get_CoreWebView2 (controller, &ctx->webview)) || !ctx->webview) {
		notify (ctx, EIF_WEBVIEW2_READY, NULL, (EIF_INTEGER) E_FAIL);
		return S_OK;
	}
	if (SUCCEEDED (ctx->webview->lpVtbl->get_Settings (ctx->webview, &settings)) && settings) {
		settings->lpVtbl->put_IsWebMessageEnabled (settings, TRUE);
		settings->lpVtbl->Release (settings);
	}
	REGISTER (ctx, navigation_starting_vtbl, EIF_IID_ICoreWebView2NavigationStartingEventHandler, add_NavigationStarting);
	REGISTER (ctx, navigation_completed_vtbl, EIF_IID_ICoreWebView2NavigationCompletedEventHandler, add_NavigationCompleted);
	REGISTER (ctx, source_changed_vtbl, EIF_IID_ICoreWebView2SourceChangedEventHandler, add_SourceChanged);
	REGISTER (ctx, title_changed_vtbl, EIF_IID_ICoreWebView2DocumentTitleChangedEventHandler, add_DocumentTitleChanged);
	REGISTER (ctx, web_message_received_vtbl, EIF_IID_ICoreWebView2WebMessageReceivedEventHandler, add_WebMessageReceived);
	REGISTER (ctx, new_window_requested_vtbl, EIF_IID_ICoreWebView2NewWindowRequestedEventHandler, add_NewWindowRequested);
	controller->lpVtbl->put_IsVisible (controller, TRUE);
	notify (ctx, EIF_WEBVIEW2_READY, NULL, (EIF_INTEGER) S_OK);
	return S_OK;
}

static const ICoreWebView2CreateCoreWebView2ControllerCompletedHandlerVtbl controller_created_vtbl = {
	HANDLER_IUNKNOWN (ICoreWebView2CreateCoreWebView2ControllerCompletedHandler),
	on_controller_created
};

/* Environment created. */

static HRESULT STDMETHODCALLTYPE on_environment_created (ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler *This, HRESULT result, ICoreWebView2Environment *environment)
{
	eif_webview2 *ctx = CTX (This);
	ICoreWebView2CreateCoreWebView2ControllerCompletedHandler *handler;
	HRESULT hr;

	if (ctx->is_destroyed) {
		return S_OK;
	}
	if (FAILED (result) || !environment) {
		notify (ctx, EIF_WEBVIEW2_READY, NULL, (EIF_INTEGER) (FAILED (result) ? result : E_FAIL));
		return S_OK;
	}
	handler = new_handler (&controller_created_vtbl, &EIF_IID_ICoreWebView2CreateCoreWebView2ControllerCompletedHandler, ctx);
	if (!handler) {
		notify (ctx, EIF_WEBVIEW2_READY, NULL, (EIF_INTEGER) E_OUTOFMEMORY);
		return S_OK;
	}
	hr = environment->lpVtbl->CreateCoreWebView2Controller (environment, ctx->parent, handler);
	handler->lpVtbl->Release (handler);
	if (FAILED (hr)) {
		notify (ctx, EIF_WEBVIEW2_READY, NULL, (EIF_INTEGER) hr);
	}
	return S_OK;
}

static const ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandlerVtbl environment_created_vtbl = {
	HANDLER_IUNKNOWN (ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler),
	on_environment_created
};

/* -------------------------------------------------------------------------- */
/* Loader */

typedef HRESULT (STDMETHODCALLTYPE *EIF_CREATE_WEBVIEW_ENVIRONMENT_INTERNAL) (
	BOOL check_runtime_only, int runtime_type, LPCWSTR user_data_folder,
	ICoreWebView2EnvironmentOptions *options,
	ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler *handler);

	/* Client id of the WebView2 Runtime (Evergreen) in the EdgeUpdate registry keys. */
#define WEBVIEW2_RUNTIME_CLIENT L"{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}"

static int is_version_newer (const wchar_t *a, const wchar_t *b)
	/* Is the version `a` (as "1.2.3.4") newer than `b`? */
{
	unsigned long va [4] = {0, 0, 0, 0}, vb [4] = {0, 0, 0, 0};
	int i;
	swscanf (a, L"%lu.%lu.%lu.%lu", &va [0], &va [1], &va [2], &va [3]);
	swscanf (b, L"%lu.%lu.%lu.%lu", &vb [0], &vb [1], &vb [2], &vb [3]);
	for (i = 0; i < 4; i++) {
		if (va [i] != vb [i]) {
			return va [i] > vb [i];
		}
	}
	return 0;
}

static int find_runtime_dll (wchar_t *path, DWORD size)
	/* Path of EmbeddedBrowserWebView.dll of the newest installed WebView2 Runtime. */
{
	static const struct { HKEY root; const wchar_t *key; } locations [] = {
		{HKEY_LOCAL_MACHINE, L"SOFTWARE\\WOW6432Node\\Microsoft\\EdgeUpdate\\Clients\\" WEBVIEW2_RUNTIME_CLIENT},
		{HKEY_LOCAL_MACHINE, L"SOFTWARE\\Microsoft\\EdgeUpdate\\Clients\\" WEBVIEW2_RUNTIME_CLIENT},
		{HKEY_CURRENT_USER, L"Software\\Microsoft\\EdgeUpdate\\Clients\\" WEBVIEW2_RUNTIME_CLIENT}
	};
	wchar_t best_version [64] = L"";
	wchar_t best_location [MAX_PATH] = L"";
	wchar_t version [64], location [MAX_PATH];
	DWORD n;
	size_t i;
	const wchar_t *arch;

	for (i = 0; i < sizeof (locations) / sizeof (locations [0]); i++) {
		n = sizeof (version);
		if (RegGetValueW (locations [i].root, locations [i].key, L"pv", RRF_RT_REG_SZ, NULL, version, &n) != ERROR_SUCCESS) {
			continue;
		}
		n = sizeof (location);
		if (RegGetValueW (locations [i].root, locations [i].key, L"location", RRF_RT_REG_SZ, NULL, location, &n) != ERROR_SUCCESS) {
			continue;
		}
		if (wcscmp (version, L"0.0.0.0") != 0 && (best_version [0] == 0 || is_version_newer (version, best_version))) {
			wcsncpy (best_version, version, 63);
			best_version [63] = 0;
			wcsncpy (best_location, location, MAX_PATH - 1);
			best_location [MAX_PATH - 1] = 0;
		}
	}
	if (best_version [0] == 0) {
		return 0;
	}
#if defined(_M_ARM64) || defined(__aarch64__)
	arch = L"arm64";
#elif defined(_WIN64)
	arch = L"x64";
#else
	arch = L"x86";
#endif
	return _snwprintf (path, size, L"%s\\%s\\EBWebView\\%s\\EmbeddedBrowserWebView.dll", best_location, best_version, arch) > 0;
}

static HRESULT create_environment (LPCWSTR user_data_folder, ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler *handler)
{
	HMODULE module;
	wchar_t path [2 * MAX_PATH];

	module = LoadLibraryW (L"WebView2Loader.dll");
	if (module) {
		EIF_CREATE_WEBVIEW2_ENVIRONMENT_WITH_OPTIONS create = (EIF_CREATE_WEBVIEW2_ENVIRONMENT_WITH_OPTIONS) (void (*) (void))
			GetProcAddress (module, "CreateCoreWebView2EnvironmentWithOptions");
		if (create) {
			return create (NULL, user_data_folder, NULL, handler);
		}
	}
	if (find_runtime_dll (path, sizeof (path) / sizeof (path [0]))) {
		module = LoadLibraryExW (path, NULL, LOAD_WITH_ALTERED_SEARCH_PATH);
		if (module) {
			EIF_CREATE_WEBVIEW_ENVIRONMENT_INTERNAL create = (EIF_CREATE_WEBVIEW_ENVIRONMENT_INTERNAL) (void (*) (void))
				GetProcAddress (module, "CreateWebViewEnvironmentWithOptionsInternal");
			if (create) {
					/* Runtime type 0: installed (Evergreen) runtime. */
				return create (TRUE, 0, user_data_folder, NULL, handler);
			}
		}
	}
	return HRESULT_FROM_WIN32 (ERROR_FILE_NOT_FOUND);
}

static void default_user_data_folder (wchar_t *folder, DWORD size)
	/* "%LOCALAPPDATA%\Eiffel Software\WebView2\<executable name>":
	   the default folder (next to the executable) is not writable for installed applications. */
{
	wchar_t local [MAX_PATH], exe [MAX_PATH];
	wchar_t *name, *dot;
	DWORD n;

	n = GetEnvironmentVariableW (L"LOCALAPPDATA", local, MAX_PATH);
	if (n == 0 || n >= MAX_PATH) {
		n = GetTempPathW (MAX_PATH, local);
		if (n == 0 || n >= MAX_PATH) {
			folder [0] = 0;
			return;
		}
	}
	if (GetModuleFileNameW (NULL, exe, MAX_PATH) == 0) {
		wcscpy (exe, L"eiffel");
	}
	exe [MAX_PATH - 1] = 0;
	name = wcsrchr (exe, L'\\');
	name = name ? name + 1 : exe;
	dot = wcsrchr (name, L'.');
	if (dot) {
		*dot = 0;
	}
	_snwprintf (folder, size, L"%s\\Eiffel Software\\WebView2\\%s", local, name);
	folder [size - 1] = 0;
}

/* -------------------------------------------------------------------------- */
/* API */

eif_webview2 *eif_webview2_new (EIF_POINTER parent, EIF_REFERENCE eiffel_object, EIF_POINTER dispatch)
{
	eif_webview2 *ctx;
	ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler *handler;
	wchar_t folder [2 * MAX_PATH];
	HRESULT hr;

	hr = CoInitializeEx (NULL, COINIT_APARTMENTTHREADED);
	if (hr == RPC_E_CHANGED_MODE) {
			/* WebView2 requires a single-threaded apartment. */
		return NULL;
	}
	ctx = (eif_webview2 *) calloc (1, sizeof (eif_webview2));
	if (!ctx) {
		return NULL;
	}
	ctx->ref_count = 1;
	ctx->parent = (HWND) parent;
	ctx->eiffel_object = eif_protect (eiffel_object);
	ctx->dispatch = (EIF_WEBVIEW2_DISPATCH) dispatch;
	handler = new_handler (&environment_created_vtbl, &EIF_IID_ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler, ctx);
	if (!handler) {
		eif_webview2_destroy (ctx);
		return NULL;
	}
	default_user_data_folder (folder, sizeof (folder) / sizeof (folder [0]));
	hr = create_environment (folder [0] ? folder : NULL, handler);
	handler->lpVtbl->Release (handler);
	if (FAILED (hr)) {
		eif_webview2_destroy (ctx);
		return NULL;
	}
	return ctx;
}

void eif_webview2_destroy (eif_webview2 *ctx)
{
	if (!ctx || ctx->is_destroyed) {
		return;
	}
	ctx->is_destroyed = 1;
	if (ctx->webview) {
		ctx->webview->lpVtbl->Release (ctx->webview);
		ctx->webview = NULL;
	}
	if (ctx->controller) {
		ctx->controller->lpVtbl->Close (ctx->controller);
		ctx->controller->lpVtbl->Release (ctx->controller);
		ctx->controller = NULL;
	}
	if (ctx->eiffel_object) {
		eif_wean (ctx->eiffel_object);
		ctx->eiffel_object = NULL;
	}
	context_release (ctx);
}

EIF_BOOLEAN eif_webview2_is_ready (eif_webview2 *ctx)
{
	return EIF_TEST (ctx && !ctx->is_destroyed && ctx->webview);
}

void eif_webview2_set_bounds (eif_webview2 *ctx, EIF_INTEGER width, EIF_INTEGER height)
{
	RECT bounds;
	if (eif_webview2_is_ready (ctx)) {
		bounds.left = 0;
		bounds.top = 0;
		bounds.right = width;
		bounds.bottom = height;
		ctx->controller->lpVtbl->put_Bounds (ctx->controller, bounds);
	}
}

void eif_webview2_parent_window_moved (eif_webview2 *ctx)
{
	if (eif_webview2_is_ready (ctx)) {
		ctx->controller->lpVtbl->NotifyParentWindowPositionChanged (ctx->controller);
	}
}

void eif_webview2_set_focus (eif_webview2 *ctx)
{
	if (eif_webview2_is_ready (ctx)) {
			/* COREWEBVIEW2_MOVE_FOCUS_REASON_PROGRAMMATIC */
		ctx->controller->lpVtbl->MoveFocus (ctx->controller, 0);
	}
}

void eif_webview2_navigate (eif_webview2 *ctx, EIF_POINTER uri)
{
	if (eif_webview2_is_ready (ctx)) {
		ctx->webview->lpVtbl->Navigate (ctx->webview, (LPCWSTR) uri);
	}
}

void eif_webview2_navigate_to_string (eif_webview2 *ctx, EIF_POINTER html)
{
	if (eif_webview2_is_ready (ctx)) {
		ctx->webview->lpVtbl->NavigateToString (ctx->webview, (LPCWSTR) html);
	}
}

void eif_webview2_execute_script (eif_webview2 *ctx, EIF_POINTER script)
{
	if (eif_webview2_is_ready (ctx)) {
		ctx->webview->lpVtbl->ExecuteScript (ctx->webview, (LPCWSTR) script, NULL);
	}
}

void eif_webview2_add_document_start_script (eif_webview2 *ctx, EIF_POINTER script)
{
	if (eif_webview2_is_ready (ctx)) {
		ctx->webview->lpVtbl->AddScriptToExecuteOnDocumentCreated (ctx->webview, (LPCWSTR) script, NULL);
	}
}

void eif_webview2_reload (eif_webview2 *ctx)
{
	if (eif_webview2_is_ready (ctx)) {
		ctx->webview->lpVtbl->Reload (ctx->webview);
	}
}

void eif_webview2_stop (eif_webview2 *ctx)
{
	if (eif_webview2_is_ready (ctx)) {
		ctx->webview->lpVtbl->Stop (ctx->webview);
	}
}

void eif_webview2_go_back (eif_webview2 *ctx)
{
	if (eif_webview2_is_ready (ctx)) {
		ctx->webview->lpVtbl->GoBack (ctx->webview);
	}
}

void eif_webview2_go_forward (eif_webview2 *ctx)
{
	if (eif_webview2_is_ready (ctx)) {
		ctx->webview->lpVtbl->GoForward (ctx->webview);
	}
}

EIF_BOOLEAN eif_webview2_can_go_back (eif_webview2 *ctx)
{
	BOOL b = FALSE;
	if (eif_webview2_is_ready (ctx)) {
		ctx->webview->lpVtbl->get_CanGoBack (ctx->webview, &b);
	}
	return EIF_TEST (b);
}

EIF_BOOLEAN eif_webview2_can_go_forward (eif_webview2 *ctx)
{
	BOOL b = FALSE;
	if (eif_webview2_is_ready (ctx)) {
		ctx->webview->lpVtbl->get_CanGoForward (ctx->webview, &b);
	}
	return EIF_TEST (b);
}

EIF_POINTER eif_webview2_source (eif_webview2 *ctx)
{
	LPWSTR s = NULL;
	if (eif_webview2_is_ready (ctx)) {
		ctx->webview->lpVtbl->get_Source (ctx->webview, &s);
	}
	return (EIF_POINTER) s;
}

EIF_POINTER eif_webview2_title (eif_webview2 *ctx)
{
	LPWSTR s = NULL;
	if (eif_webview2_is_ready (ctx)) {
		ctx->webview->lpVtbl->get_DocumentTitle (ctx->webview, &s);
	}
	return (EIF_POINTER) s;
}

void eif_webview2_free_string (EIF_POINTER s)
{
	CoTaskMemFree ((LPVOID) s);
}

EIF_REAL_64 eif_webview2_zoom_factor (eif_webview2 *ctx)
{
	double z = 1.0;
	if (eif_webview2_is_ready (ctx)) {
		ctx->controller->lpVtbl->get_ZoomFactor (ctx->controller, &z);
	}
	return (EIF_REAL_64) z;
}

void eif_webview2_set_zoom_factor (eif_webview2 *ctx, EIF_REAL_64 z)
{
	if (eif_webview2_is_ready (ctx)) {
		ctx->controller->lpVtbl->put_ZoomFactor (ctx->controller, (double) z);
	}
}

void eif_webview2_set_user_agent (eif_webview2 *ctx, EIF_POINTER user_agent)
{
	ICoreWebView2Settings *settings = NULL;
	ICoreWebView2Settings2 *settings2 = NULL;
	if (eif_webview2_is_ready (ctx) && SUCCEEDED (ctx->webview->lpVtbl->get_Settings (ctx->webview, &settings)) && settings) {
		if (SUCCEEDED (settings->lpVtbl->QueryInterface (settings, &EIF_IID_ICoreWebView2Settings2, (void **) &settings2)) && settings2) {
			settings2->lpVtbl->put_UserAgent (settings2, (LPCWSTR) user_agent);
			settings2->lpVtbl->Release (settings2);
		}
		settings->lpVtbl->Release (settings);
	}
}

void eif_webview2_set_dev_tools_enabled (eif_webview2 *ctx, EIF_BOOLEAN b)
{
	ICoreWebView2Settings *settings = NULL;
	if (eif_webview2_is_ready (ctx) && SUCCEEDED (ctx->webview->lpVtbl->get_Settings (ctx->webview, &settings)) && settings) {
		settings->lpVtbl->put_AreDevToolsEnabled (settings, b ? TRUE : FALSE);
		settings->lpVtbl->Release (settings);
	}
}
