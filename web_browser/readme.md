Web browser
===========

`EV_WEB_BROWSER` is a Vision2 widget displaying web content with the web engine of the platform.

| Platform | Engine | Run-time dependency |
| --- | --- | --- |
| Linux (GTK3) | WebKitGTK (`webkit2gtk-4.1`, or `webkit2gtk-4.0`) | `libwebkit2gtk-4.1-0` package |
| Windows | Microsoft Edge WebView2 | WebView2 Runtime (part of Windows 11, installed on most Windows 10 systems) |
| macOS (GTK3 on Quartz) | WKWebView | none (part of macOS) |

The engine is loaded at run time: when it is not available, the widget displays a message,
and `is_browser_usable` is False.

Linux
-----

Install the WebKitGTK run-time library (no development package is needed to compile):

    sudo apt-get install libwebkit2gtk-4.1-0      # Debian, Ubuntu
    sudo dnf install webkit2gtk4.1                # Fedora

Note: WebKitGTK uses the signal `SIGUSR1` for its garbage collector, and prints
"Overriding existing handler for signal 10" at start-up. Set the environment variable
`JSC_SIGNAL_FOR_GC` to use another signal.

Windows
-------

The WebView2 Runtime is located through `WebView2Loader.dll` when it is found (next to the executable,
or in the `PATH`), otherwise directly from the registry: no DLL needs to be distributed with the application.
The data of the web view (cache, cookies, ...) is stored in `%LOCALAPPDATA%\Eiffel Software\WebView2\<executable name>`.

The C part (`Clib/eif_webview2.c`) is compiled with `finish_freezing -library` in `Clib`
(`eif_webview2.lib`, and `mteif_webview2.lib` for multithreaded applications).
Set the environment variable `EIF_WEBVIEW2_TRACE` to trace the creation of the web view and its events
(to the standard error and the debugger output).
`spec/include/eif_webview2_api.h` is generated from the `WebView2.h` header of the WebView2 SDK
(NuGet package `Microsoft.Web.WebView2`) by `Clib/generate_webview2_header.py`.

macOS
-----

EiffelStudio on macOS uses the GTK3 implementation of Vision2, and the web view is a WKWebView:

- with the Quartz backend of GDK (MacPorts `gtk3 +quartz`), it is embedded in the native window (`NSView`)
  of the GTK window, over the GTK widget;
- with the X11 backend (MacPorts default `gtk3 +x11`, with XQuartz), the GTK windows belong to the XQuartz
  process: the WKWebView is displayed in a borderless window of the application, kept over the GTK widget
  and ordered just above the XQuartz window that contains it.

The Objective-C runtime and WebKit are used through the C API of the Objective-C runtime
(`spec/include/eif_wkwebview.h`), so no Objective-C compiler and no link option are needed.
Set the environment variable `EIF_WKWEBVIEW_TRACE` to trace the events of the web view.

Note: the generated C makefiles do not track the dependency on this header: after changing it,
recompile the application with `-clean` (or delete the object files that include it).

Usage
-----

```eiffel
	create browser
	browser.load_uri ("https://www.eiffel.org/")
		-- or
	browser.load_html ("<h1>Hello</h1>", Void)
```

Events: `load_started_actions`, `load_finished_actions`, `load_failed_actions`, `uri_changed_actions`,
`title_changed_actions`, `message_received_actions`.
Navigation can be restricted with `set_navigation_handler`.

### JavaScript

- `execute_script (script)`: run a script in the current page.
- `evaluate_script (expression, agent (json_value, error: detachable READABLE_STRING_32) ...)`:
  evaluate an expression (a promise is awaited) and get its value as JSON, or the error message.
- `add_document_start_script (script)`: run a script at the start of every page, before the scripts of the page.
- From the page, `window.eiffel.postMessage (value)` triggers `message_received_actions`
  (a value that is not a string is sent as JSON).

Checking the library
--------------------

`tests/tests.ecf` builds a program that opens a window, runs a sequence of checks of the
widget on the current platform, prints `PASS`/`FAIL` for each, and exits with status 0 if all pass:

    ec -batch -config tests/tests.ecf -project_path <dir> -c_compile
    <dir>/EIFGENs/web_browser_tests/W_code/web_browser_tests

On a Linux system without display, run it with `xvfb-run -a`.
