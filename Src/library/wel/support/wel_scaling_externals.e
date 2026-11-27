note
	description: "[
			Eiffel wrapper to load the Windows Scaling API dynamically.
		]"
	date: "$Date$"
	revision: "$Revision$"
	EIS: "name=High-DPI Reference", "src=https://docs.microsoft.com/en-us/windows/desktop/hidpi/high-dpi-reference", "protocol=uri"

class
	WEL_SCALING_EXTERNALS

inherit
	ANY
		redefine
			default_create
		end

feature {NONE} -- Initialization

	frozen default_create
			-- Default creation method.
		local
			retried: BOOLEAN
		do
			if not retried then
				initialize_scaling
			end
		rescue
			retried := True
			retry
		end

	initialize_scaling
			-- Properly initialize Current.
		local
			dll: WEL_DLL
			dll2: WEL_DLL
		do
			create dll.make_permanent ("Shcore.dll")
			scaling_handle := dll.item
			create dll2.make_permanent ("User32.dll")
			scaling_handle_ctx := dll2.item
		end

feature -- Constants

	Mdt_effective_dpi: INTEGER  = 0

	Monitor_defaulttoprimary: INTEGER = 0x00000001

	Monitor_defaulttonearest: INTEGER = 0x00000002

	Default_dpi: INTEGER = 96
			-- Default DPI value of 96
			-- known as DPI unaware, the application render as
			-- if the screen that they are on has a DPI value of 96 .

	Process_dpi_unaware: INTEGER = 0
			-- Defined as PROCESS_DPI_UNAWARE = 0

	Process_system_dpi_aware: INTEGER = 1
			-- Defined as PROCESS_SYSTEM_DPI_AWARE = 1

	Process_per_monitor_dpi_aware: INTEGER  = 2
			-- Defined as PROCESS_PER_MONITOR_DPI_AWARE = 2


	Dpi_awareness_context_per_monitor_aware_v2 : NATURAL_64
		do
			Result := c_dpi_awareness_context_per_monitor_aware_v2
		end

feature -- Status report

	is_scaling_installed: BOOLEAN
			-- Is "Shcore.dll" available?
		do
			Result := not scaling_handle.is_default_pointer
		end

	is_scaling_context_installed: BOOLEAN
			-- Is "User32.dll" available?
		do
			Result := not scaling_handle_ctx.is_default_pointer
		end

feature -- Access

	scaling_handle: POINTER
			-- Handle to Schore.dll if present.

	scaling_handle_ctx: POINTER
			-- Handle to User32.dll if present.


	monitor_scale (hwnd: POINTER): TUPLE [scalex: DOUBLE; scaley: DOUBLE]
			-- Return the scale DIP (device independent pixels) size, based on the current DPI
			-- (Dots per inch).
			-- examples
			-- DPI Size             DIP size
			--   96                    1 pixel
			--  120                    1.25 pixel
		note
			EIS:"name=", "protocol=https://docs.microsoft.com/en-us/windows/desktop/learnwin32/dpi-and-device-independent-pixels", "protocol=src"
		local
			l_monitor: POINTER
			l_dpi_x: INTEGER
			l_dpi_y: INTEGER
		do
			Result := [1.0, 1.0]
			if not scaling_handle.is_default_pointer then
				l_monitor := {WEL_API}.monitor_from_window (hwnd, Monitor_defaulttonearest)
				if not l_monitor.is_default_pointer then
					c_get_dpi_for_monitor (scaling_handle, l_monitor, Mdt_effective_dpi, $l_dpi_x, $l_dpi_y)
					Result := [l_dpi_x / default_dpi, l_dpi_y / default_dpi]
				end
			end
		end

	dpi_for_monitor (hwnd: POINTER): INTEGER
			-- Return the dots per inch (dpi) of a display `hwnd`.
			-- DPI sizes 96, 120, 144, 192, etc.
		require
			hwnd_exists: not hwnd.is_default_pointer
		local
			l_monitor: POINTER
			l_dpi_x: INTEGER
			l_dpi_y: INTEGER
		do
			if not scaling_handle.is_default_pointer then
				l_monitor := {WEL_API}.monitor_from_window (hwnd, Monitor_defaulttonearest)
				if not l_monitor.is_default_pointer then
					c_get_dpi_for_monitor (scaling_handle, l_monitor, Mdt_effective_dpi, $l_dpi_x, $l_dpi_y)
					Result := l_dpi_x
				end
			end
		end

	system_dpi: NATURAL_32
			-- DPI of the system: the DPI of the primary monitor when the user session started.
			-- It does not change during the life of the process, and it is the DPI
			-- at which fonts defined by a point size are realized.
		do
			Result := c_system_dpi
			if Result = 0 then
				Result := Default_dpi.to_natural_32
			end
		ensure
			instance_free: class
			positive: Result > 0
		end

	dpi_for_window (hwnd: POINTER): NATURAL_32
			-- DPI of the window `hwnd`, i.e. the DPI of the monitor on which it is displayed
			-- when the process is per monitor DPI aware, `system_dpi` otherwise.
		require
			hwnd_exists: not hwnd.is_default_pointer
		do
			Result := c_get_dpi_for_window (hwnd)
			if Result = 0 then
					-- `GetDpiForWindow' is not available (before Windows 10 1607).
				Result := dpi_for_monitor_handle ({WEL_API}.monitor_from_window (hwnd, Monitor_defaulttonearest))
			end
		ensure
			instance_free: class
			positive: Result > 0
		end

	dpi_for_monitor_handle (a_monitor: POINTER): NATURAL_32
			-- Effective DPI of the monitor `a_monitor` (a HMONITOR),
			-- or `system_dpi` if it cannot be retrieved.
		do
			if not a_monitor.is_default_pointer then
				Result := c_get_dpi_for_monitor_handle (a_monitor)
			end
			if Result = 0 then
				Result := system_dpi
			end
		ensure
			instance_free: class
			positive: Result > 0
		end

	dpi_at_point (a_x, a_y: INTEGER): NATURAL_32
			-- Effective DPI of the monitor containing the screen point (`a_x`, `a_y`),
			-- or of the nearest monitor if the point is outside of all monitors.
		do
			Result := dpi_for_monitor_handle (c_monitor_from_point (a_x, a_y, Monitor_defaulttonearest))
		ensure
			instance_free: class
			positive: Result > 0
		end

	primary_monitor_dpi: NATURAL_32
			-- Effective DPI of the primary monitor.
		do
			Result := dpi_for_monitor_handle (c_monitor_from_point (0, 0, Monitor_defaulttoprimary))
		ensure
			instance_free: class
			positive: Result > 0
		end

	scaled_for_dpi (a_size: INTEGER; a_dpi: NATURAL_32): INTEGER
			-- `a_size`, given for `Default_dpi`, scaled to `a_dpi`.
		do
			Result := (a_size * a_dpi.to_integer_32 / Default_dpi).rounded
		ensure
			instance_free: class
		end

	rescaled_for_dpi (a_size: INTEGER; a_from_dpi, a_to_dpi: NATURAL_32): INTEGER
			-- `a_size`, given for `a_from_dpi`, scaled to `a_to_dpi`.
		require
			a_from_dpi_positive: a_from_dpi > 0
		do
			Result := (a_size * a_to_dpi.to_integer_32 / a_from_dpi.to_integer_32).rounded
		ensure
			instance_free: class
		end

feature -- Status setting

	enable_per_monitor_dpi_awareness
			-- Make the process per monitor DPI aware, using the best mode available:
			-- Per Monitor v2 (Windows 10 1703+: scaled non-client area, DPI notifications
			-- to child windows, scaled theme parts of common controls), Per Monitor
			-- (Windows 8.1+), or else system DPI aware (Windows Vista+).
			-- Has no effect if the DPI awareness of the process is already set
			-- (for instance by its manifest).
		do
			c_enable_per_monitor_dpi_awareness
		ensure
			instance_free: class
		end

	set_process_per_monitor_dpi_aware
			-- Set ProcessDPIAwareness to PROCESS_PER_MONITOR_DPI_AWARE
			-- PROCESS_PER_MONITOR_DPI_AWARE
			--| Per monitor DPI aware. This app checks for the DPI when it is created and adjusts the scale factor whenever the DPI changes.
			--| These applications are not automatically scaled by the system.
		local
			l_res: BOOLEAN
			l_value: INTEGER
			l_val_res: INTEGER
			retried: BOOLEAN
		do
			if not retried then
				if not scaling_handle.is_default_pointer  then
					l_res := c_set_process_dpi_awareness (scaling_handle, process_per_monitor_dpi_aware)
					debug
						l_val_res := c_get_process_dpi_awareness (scaling_handle, default_pointer, $l_value )
						check process_dpi_awarness: l_value = process_per_monitor_dpi_aware  end
					end
				end
			end
		rescue
			retried := True
			retry
		end

	set_process_per_monitor_dpi_aware_v2
		local
			l_res: BOOLEAN
			retried: BOOLEAN
		do
			if not retried then
				if not scaling_handle_ctx.is_default_pointer  then
					l_res := c_set_process_dpi_awareness_context (scaling_handle_ctx, c_dpi_awareness_context_per_monitor_aware_v2)
				end
			end
		rescue
			retried := True
			retry
		end

feature {NONE} -- C externals

	c_get_dpi_for_monitor (a_scaling_handle: POINTER; a_hwnd: POINTER; a_flags: INTEGER_32; dpi_x, dpi_y: TYPED_POINTER [INTEGER])
			-- Declared as HRESULT GetDpiForMonitor( HMONITOR hmonitor, MONITOR_DPI_TYPE dpiType, UINT *dpiX, UINT *dpiY );
		require
			a_api_exists: a_scaling_handle /= default_pointer
		external
			"C inline use <wel_scaling_api.h>"
		alias
			"[
				#if defined(_MSC_VER) && defined(DPI_ENUMS_DECLARED)
					FARPROC GetDpiForMonitor = NULL;
					HMODULE user32_module = (HMODULE) $a_scaling_handle;
					
					GetDpiForMonitor = GetProcAddress (user32_module, "GetDpiForMonitor");
					if (GetDpiForMonitor) {
						(FUNCTION_CAST_TYPE(void, WINAPI, (HMONITOR, MONITOR_DPI_TYPE, UINT *, UINT * )) GetDpiForMonitor) ((HMONITOR) $a_hwnd, (MONITOR_DPI_TYPE) $a_flags, (UINT *) $dpi_x, (UINT *) $dpi_y );
					}
				#endif
			]"
		end

	c_set_process_dpi_awareness	(a_scaling_handle: POINTER; a_level: INTEGER): BOOLEAN
			-- Declated as HRESULT SetProcessDpiAwareness(PROCESS_DPI_AWARENESS value);
		require
			a_api_exists: a_scaling_handle /= default_pointer
		external
			"C inline use <wel_scaling_api.h>"
		alias
			"[
				#if defined(_MSC_VER) && defined(DPI_ENUMS_DECLARED)
					FARPROC SetProcessDpiAwareness = NULL;
					HMODULE user32_module = (HMODULE) $a_scaling_handle;
							
					SetProcessDpiAwareness = GetProcAddress (user32_module, "SetProcessDpiAwareness");
					if (SetProcessDpiAwareness) {
						return EIF_TEST((FUNCTION_CAST_TYPE(HRESULT, WINAPI, (PROCESS_DPI_AWARENESS)) SetProcessDpiAwareness) ((PROCESS_DPI_AWARENESS)$a_level));
					} else {
						return EIF_FALSE;
					}
				#else
					return EIF_FALSE;
				#endif
			]"
		end

	c_dpi_awareness_context_per_monitor_aware_v2 : NATURAL_64
			-- Declared as
		external
			"C inline use <wel_scaling_api.h>"
		alias
		  "[
			#if defined(_MSC_VER) && defined(_DPI_AWARENESS_CONTEXTS_) && defined(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2)
				return DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2;
			#else
				return 0;
			#endif
			]"
		end

	c_set_process_dpi_awareness_context	(a_scaling_handle: POINTER; a_level: NATURAL_64): BOOLEAN
			-- Declated as BOOL SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT value);
		require
			a_api_exists: a_scaling_handle /= default_pointer
		external
			"C inline use <wel_scaling_api.h>"
		alias
			"[
				#if defined(_MSC_VER) && defined(_DPI_AWARENESS_CONTEXTS_)
					FARPROC SetProcessDpiAwarenessContext = NULL;
					HMODULE user32_module = (HMODULE) $a_scaling_handle;
					SetProcessDpiAwarenessContext = GetProcAddress (user32_module, "SetProcessDpiAwarenessContext");
					if (SetProcessDpiAwarenessContext) {
						return EIF_TEST((FUNCTION_CAST_TYPE(BOOL, WINAPI, (DPI_AWARENESS_CONTEXT)) SetProcessDpiAwarenessContext) ((DPI_AWARENESS_CONTEXT) $a_level));
					} else {
						return EIF_FALSE;
					}
				#else
					return EIF_FALSE;
				#endif
			]"
		end

	c_get_process_dpi_awareness	(a_scaling_handle:POINTER; a_process: POINTER; a_value: TYPED_POINTER [INTEGER]): INTEGER
			-- Declared as HRESULT GetProcessDpiAwareness(HANDLE hprocess, PROCESS_DPI_AWARENESS *value);
		require
			a_api_exists: a_scaling_handle /= default_pointer
		external
			"C inline use <wel_scaling_api.h>"
		alias
			"[
				#if defined(_MSC_VER) && defined(DPI_ENUMS_DECLARED)
					FARPROC GetProcessDpiAwareness = NULL;
					HMODULE user32_module = (HMODULE) $a_scaling_handle;
									
					GetProcessDpiAwareness = GetProcAddress (user32_module, "GetProcessDpiAwareness");
					if (GetProcessDpiAwareness) {
						return (FUNCTION_CAST_TYPE(HRESULT, WINAPI, (HANDLE, PROCESS_DPI_AWARENESS * )) GetProcessDpiAwareness) ((HANDLE) $a_process, (PROCESS_DPI_AWARENESS *) $a_value);
					} else {
						return 0;
					}
				#else
					return 0;
				#endif
			]"
		end

	c_get_dpi_for_window (a_hwnd: POINTER): NATURAL_32
			-- GetDpiForWindow (Windows 10 1607+), or 0 if not available.
		external
			"C inline use <windows.h>"
		alias
			"[
				typedef UINT (WINAPI *EIF_GET_DPI_FOR_WINDOW) (HWND);
				static EIF_GET_DPI_FOR_WINDOW get_dpi_for_window = NULL;
				static int is_loaded = 0;
				HMODULE l_user32;

				if (!is_loaded) {
					l_user32 = GetModuleHandleW (L"user32.dll");
					if (l_user32) {
						get_dpi_for_window = (EIF_GET_DPI_FOR_WINDOW) GetProcAddress (l_user32, "GetDpiForWindow");
					}
					is_loaded = 1;
				}
				if (get_dpi_for_window) {
					return (EIF_NATURAL_32) get_dpi_for_window ((HWND) $a_hwnd);
				} else {
					return 0;
				}
			]"
		end

	c_get_dpi_for_monitor_handle (a_monitor: POINTER): NATURAL_32
			-- Effective DPI of `a_monitor` with GetDpiForMonitor (Windows 8.1+), or 0 if not available.
		external
			"C inline use <windows.h>"
		alias
			"[
				typedef HRESULT (WINAPI *EIF_GET_DPI_FOR_MONITOR) (HMONITOR, int, UINT *, UINT *);
				static EIF_GET_DPI_FOR_MONITOR get_dpi_for_monitor = NULL;
				static int is_loaded = 0;
				HMODULE l_shcore;
				UINT l_dpi_x = 0, l_dpi_y = 0;

				if (!is_loaded) {
					l_shcore = LoadLibraryW (L"shcore.dll");
					if (l_shcore) {
						get_dpi_for_monitor = (EIF_GET_DPI_FOR_MONITOR) GetProcAddress (l_shcore, "GetDpiForMonitor");
					}
					is_loaded = 1;
				}
					/* 0 is MDT_EFFECTIVE_DPI. */
				if (get_dpi_for_monitor && SUCCEEDED (get_dpi_for_monitor ((HMONITOR) $a_monitor, 0, &l_dpi_x, &l_dpi_y))) {
					return (EIF_NATURAL_32) l_dpi_x;
				} else {
					return 0;
				}
			]"
		end

	c_system_dpi: NATURAL_32
			-- GetDpiForSystem (Windows 10 1607+), or else the vertical logical pixels of the screen.
		external
			"C inline use <windows.h>"
		alias
			"[
				typedef UINT (WINAPI *EIF_GET_DPI_FOR_SYSTEM) (void);
				static EIF_GET_DPI_FOR_SYSTEM get_dpi_for_system = NULL;
				static int is_loaded = 0;
				HMODULE l_user32;
				HDC l_dc;
				EIF_NATURAL_32 l_result = 0;

				if (!is_loaded) {
					l_user32 = GetModuleHandleW (L"user32.dll");
					if (l_user32) {
						get_dpi_for_system = (EIF_GET_DPI_FOR_SYSTEM) GetProcAddress (l_user32, "GetDpiForSystem");
					}
					is_loaded = 1;
				}
				if (get_dpi_for_system) {
					l_result = (EIF_NATURAL_32) get_dpi_for_system ();
				} else {
					l_dc = GetDC (NULL);
					if (l_dc) {
						l_result = (EIF_NATURAL_32) GetDeviceCaps (l_dc, LOGPIXELSY);
						ReleaseDC (NULL, l_dc);
					}
				}
				return l_result;
			]"
		end

	c_monitor_from_point (a_x, a_y: INTEGER; a_flags: INTEGER): POINTER
			-- SDK MonitorFromPoint.
		external
			"C inline use <windows.h>"
		alias
			"[
				POINT l_point;

				l_point.x = (LONG) $a_x;
				l_point.y = (LONG) $a_y;
				return (EIF_POINTER) MonitorFromPoint (l_point, (DWORD) $a_flags);
			]"
		end

	c_enable_per_monitor_dpi_awareness
			-- Set the DPI awareness of the process to Per Monitor v2, or else Per Monitor,
			-- or else system DPI aware, depending on what the OS supports.
		external
			"C inline use <windows.h>"
		alias
			"[
				typedef BOOL (WINAPI *EIF_SET_PROCESS_DPI_AWARENESS_CONTEXT) (HANDLE);
				typedef HRESULT (WINAPI *EIF_SET_PROCESS_DPI_AWARENESS) (int);
				typedef BOOL (WINAPI *EIF_SET_PROCESS_DPI_AWARE) (void);
				EIF_SET_PROCESS_DPI_AWARENESS_CONTEXT l_set_context = NULL;
				EIF_SET_PROCESS_DPI_AWARENESS l_set_awareness = NULL;
				EIF_SET_PROCESS_DPI_AWARE l_set_aware = NULL;
				HMODULE l_user32, l_shcore;
				int l_done = 0;

				l_user32 = GetModuleHandleW (L"user32.dll");
				if (l_user32) {
					l_set_context = (EIF_SET_PROCESS_DPI_AWARENESS_CONTEXT) GetProcAddress (l_user32, "SetProcessDpiAwarenessContext");
						/* (HANDLE) -4 is DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2. */
					if (l_set_context && l_set_context ((HANDLE) (INT_PTR) -4)) {
						l_done = 1;
					}
				}
				if (!l_done) {
					l_shcore = LoadLibraryW (L"shcore.dll");
					if (l_shcore) {
						l_set_awareness = (EIF_SET_PROCESS_DPI_AWARENESS) GetProcAddress (l_shcore, "SetProcessDpiAwareness");
							/* 2 is PROCESS_PER_MONITOR_DPI_AWARE. */
						if (l_set_awareness && SUCCEEDED (l_set_awareness (2))) {
							l_done = 1;
						}
					}
				}
				if (!l_done && l_user32) {
					l_set_aware = (EIF_SET_PROCESS_DPI_AWARE) GetProcAddress (l_user32, "SetProcessDPIAware");
					if (l_set_aware) {
						l_set_aware ();
					}
				}
			]"
		end

note
	copyright: "Copyright (c) 1984-2019, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"
end
