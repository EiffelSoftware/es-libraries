note
	description: "[
		Win32 console driver interfacing directly with the Windows Console API via inlined C.
		Supports Virtual Terminal Processing, non-blocking UTF-16 input re-encoded as UTF-8 bytes,
		quick-edit disabling, exact restoration of the original console modes and code pages,
		and a console Ctrl handler that restores the console on unexpected termination.

		Shared native state (cached console handles and the original modes) lives in
		file-scope C globals defined once by `c_win32_define_runtime', so that the
		Ctrl handler, which runs on a system thread, can restore the console.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	WIN32_CONSOLE_DRIVER

inherit
	CONSOLE_DRIVER
		redefine
			default_create,
			input_claim
		end

create
	default_create

feature {NONE} -- Initialization

	default_create
			-- Initialize driver and cache the console input/output handles.
		do
			c_win32_define_runtime
			c_win32_init
			create pending_bytes.make (8)
		end

feature -- Queries

	console_width: INTEGER
			-- Current console width in columns, or default if unavailable.
		local
			w, h: INTEGER
		do
			if c_win32_get_console_size ($w, $h) and w > 0 then
				Result := w
			else
				Result := Default_width
			end
		end

	console_height: INTEGER
			-- Current console height in rows, or default if unavailable.
		local
			w, h: INTEGER
		do
			if c_win32_get_console_size ($w, $h) and h > 0 then
				Result := h
			else
				Result := Default_height
			end
		end

	is_raw: BOOLEAN
			-- Is raw input mode currently active?

	is_vt_enabled: BOOLEAN
			-- Is virtual terminal escape processing active?

	is_mouse_enabled: BOOLEAN
			-- Is mouse event reporting enabled in driver?

feature -- Mode Commands

	enable_vt_mode: BOOLEAN
			-- Enable Virtual Terminal processing for ANSI escape sequences.
		do
			Result := c_win32_enable_vt_mode
			if Result then
				is_vt_enabled := True
			end
		end

	enable_raw_mode: BOOLEAN
			-- Enable raw terminal input mode (disable echo and line buffering).
		do
			Result := c_win32_enable_raw_mode
			if Result then
				is_raw := True
			end
		end

	disable_raw_mode: BOOLEAN
			-- Restore normal cooked terminal input mode.
		do
			Result := c_win32_disable_raw_mode
			if Result then
				is_raw := False
			end
		end

	enable_mouse: BOOLEAN
			-- Enable mouse event capture (disabling quick-edit mode).
		do
			Result := c_win32_enable_mouse
			if Result then
				is_mouse_enabled := True
			end
		end

	disable_mouse: BOOLEAN
			-- Restore the original mouse and quick-edit behavior.
		do
			Result := c_win32_disable_mouse
			if Result then
				is_mouse_enabled := False
			end
		end

	is_keyboard_enhancement_enabled: BOOLEAN
			-- Is extended keyboard reporting (key release and repeat) active?

	enable_keyboard_enhancement
			-- Enable extended keyboard reporting.
		do
			is_keyboard_enhancement_enabled := True
		end

	disable_keyboard_enhancement
			-- Disable extended keyboard reporting.
		do
			is_keyboard_enhancement_enabled := False
		end

	restore_modes
			-- Restore original console modes and code pages saved before the first change.
		do
			c_win32_restore_modes
			is_raw := False
			is_mouse_enabled := False
			is_vt_enabled := False
			is_keyboard_enhancement_enabled := False
		end

feature -- Input & Resize

	input_claim: CONSOLE_INPUT_CLAIM
			-- One claim for the whole process: every WIN32_CONSOLE_DRIVER reads the same
			-- console, and they share the key sequence state kept in C statics
			-- (`l_seq_buf`, `l_seq_pos`, `l_seq_len`).
		once ("PROCESS")
			create Result.make
		end

	read_char_with_timeout (a_timeout_ms: INTEGER): INTEGER
			-- Read next input byte (UTF-8 encoded) from console with timeout in milliseconds.
			-- Returns byte value (0..255), or -1 if timeout expired or error.
		local
			l_record, l_unit: INTEGER
			l_done: BOOLEAN
		do
			from
				l_done := not pending_bytes.is_empty
			until
				l_done
			loop
				l_record := c_win32_read_unit (a_timeout_ms, is_keyboard_enhancement_enabled)
				if l_record < 0 then
					l_done := True
				else
					l_unit := l_record & 0xFFFF
					enqueue_utf16_unit (l_unit, (l_record |>> 16).max (1))
					l_done := not pending_bytes.is_empty
				end
			end
			if pending_bytes.is_empty then
				Result := -1
			else
				Result := pending_bytes.item
				pending_bytes.remove
			end
		end

	poll_resize (a_cols, a_rows: TYPED_POINTER [INTEGER]): BOOLEAN
			-- Query if console size has changed since last poll.
		local
			w, h: INTEGER
		do
			if c_win32_get_console_size ($w, $h) and then w > 0 and then h > 0 then
				if last_polled_width = 0 and last_polled_height = 0 then
					last_polled_width := w
					last_polled_height := h
					Result := False
				elseif w /= last_polled_width or h /= last_polled_height then
					last_polled_width := w
					last_polled_height := h
					set_integer_pointer (a_cols, w)
					set_integer_pointer (a_rows, h)
					Result := True
				end
			end
		end

	install_ctrl_handler
			-- Install console Ctrl handler that restores the console on unexpected termination.
		do
			c_win32_install_ctrl_handler
		end

feature -- Termination requests

	is_deferring_termination: BOOLEAN
			-- Are Ctrl events recorded for the application loop instead of handled at once?
		do
			Result := c_win32_is_deferring
		end

	set_deferring_termination (a_on: BOOLEAN)
			-- Record Ctrl events for the application loop (`a_on`), or handle them at once.
		do
			c_win32_set_deferring (a_on)
		end

	has_termination_request: BOOLEAN
			-- Is a deferred Ctrl event waiting?
		do
			Result := c_win32_pending >= 0
		end

	termination_request_code: INTEGER
			-- Type of the pending Ctrl event (CTRL_C_EVENT = 0, CTRL_BREAK_EVENT = 1,
			-- CTRL_CLOSE_EVENT = 2, CTRL_LOGOFF_EVENT = 5, CTRL_SHUTDOWN_EVENT = 6)
		do
			Result := c_win32_pending
		end

	discard_termination_request
			-- Forget the pending Ctrl event.
		do
			c_win32_discard
		end

	finish_termination
			-- End the process with STATUS_CONTROL_C_EXIT, as the default Ctrl handler does. For a
			-- close, logoff or shutdown, first release the handler thread waiting for the
			-- restore. Does not return.
		do
			c_win32_finish
		end

feature {NONE} -- UTF-16 to UTF-8 conversion

	pending_bytes: ARRAYED_QUEUE [INTEGER]
			-- UTF-8 bytes decoded from the last console record, not yet returned

	pending_high_surrogate: INTEGER
			-- High surrogate waiting for its low surrogate, or 0

	Max_repeat: INTEGER = 64
			-- Upper bound on honoured key auto-repeat count per record

	enqueue_utf16_unit (a_unit, a_repeat: INTEGER)
			-- Decode UTF-16 code unit `a_unit` (repeated `a_repeat` times) into `pending_bytes`.
		require
			valid_unit: a_unit >= 0 and a_unit <= 0xFFFF
			positive_repeat: a_repeat >= 1
		do
			if a_unit >= 0xD800 and a_unit <= 0xDBFF then
				pending_high_surrogate := a_unit
			elseif a_unit >= 0xDC00 and a_unit <= 0xDFFF then
				if pending_high_surrogate /= 0 then
					enqueue_code_point (0x10000 + ((pending_high_surrogate - 0xD800) |<< 10) + (a_unit - 0xDC00), a_repeat)
				end
				pending_high_surrogate := 0
			else
				pending_high_surrogate := 0
				enqueue_code_point (a_unit, a_repeat)
			end
		end

	enqueue_code_point (a_code: INTEGER; a_repeat: INTEGER)
			-- Append the UTF-8 encoding of `a_code` to `pending_bytes`, `a_repeat` times.
		require
			valid_code_point: a_code >= 0 and a_code <= 0x10FFFF
			positive_repeat: a_repeat >= 1
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > a_repeat.min (Max_repeat)
			loop
				if a_code <= 0x7F then
					pending_bytes.extend (a_code)
				elseif a_code <= 0x7FF then
					pending_bytes.extend (0xC0 | (a_code |>> 6))
					pending_bytes.extend (0x80 | (a_code & 0x3F))
				elseif a_code <= 0xFFFF then
					pending_bytes.extend (0xE0 | (a_code |>> 12))
					pending_bytes.extend (0x80 | ((a_code |>> 6) & 0x3F))
					pending_bytes.extend (0x80 | (a_code & 0x3F))
				else
					pending_bytes.extend (0xF0 | (a_code |>> 18))
					pending_bytes.extend (0x80 | ((a_code |>> 12) & 0x3F))
					pending_bytes.extend (0x80 | ((a_code |>> 6) & 0x3F))
					pending_bytes.extend (0x80 | (a_code & 0x3F))
				end
				i := i + 1
			end
		end

feature {NONE} -- Implementation Helpers

	last_polled_width: INTEGER
	last_polled_height: INTEGER

	set_integer_pointer (a_ptr: TYPED_POINTER [INTEGER]; a_val: INTEGER)
		external
			"C inline"
		alias
			"[
				*(EIF_INTEGER *)$a_ptr = (EIF_INTEGER)$a_val;
			]"
		end

feature {NONE} -- Inlined C Implementation

	c_win32_define_runtime
			-- Define the file-scope C state and helpers shared by the other externals.
			-- The body closes the generated wrapper function, emits file-scope
			-- definitions, and reopens an unused function for the generated epilogue.
		external
			"C inline use <windows.h>"
		alias
			"[
				}

				HANDLE eiffeltui_w32_in = INVALID_HANDLE_VALUE;
				HANDLE eiffeltui_w32_out = INVALID_HANDLE_VALUE;
				int eiffeltui_w32_saved = 0;
				int eiffeltui_w32_in_saved = 0;
				int eiffeltui_w32_out_saved = 0;
				DWORD eiffeltui_w32_orig_in_mode = 0;
				DWORD eiffeltui_w32_orig_out_mode = 0;
				UINT eiffeltui_w32_orig_in_cp = 0;
				UINT eiffeltui_w32_orig_out_cp = 0;
				int eiffeltui_w32_handler_installed = 0;

					/* Deferred termination (review finding C5): while an application loop draws,
					 * the handler records the event (type + 1, 0: none) and the loop restores the
					 * console. `eiffeltui_w32_restored' is set when the loop is done, for a
					 * handler thread waiting on a close event. */
				volatile LONG eiffeltui_w32_deferring = 0;
				volatile LONG eiffeltui_w32_pending = 0;
				HANDLE eiffeltui_w32_restored = NULL;

				static HANDLE eiffeltui_w32_open (DWORD a_std, LPCWSTR a_name)
				{
					DWORD l_mode = 0;
					HANDLE h = GetStdHandle (a_std);
					if (h != INVALID_HANDLE_VALUE && h != NULL && GetConsoleMode (h, &l_mode)) {
						return h;
					}
					h = CreateFileW (a_name, GENERIC_READ | GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL);
					if (h != INVALID_HANDLE_VALUE && GetConsoleMode (h, &l_mode)) {
						return h;
					}
					if (h != INVALID_HANDLE_VALUE) {
						CloseHandle (h);
					}
					return INVALID_HANDLE_VALUE;
				}

				void eiffeltui_w32_init (void)
				{
					if (eiffeltui_w32_in == INVALID_HANDLE_VALUE) {
						eiffeltui_w32_in = eiffeltui_w32_open (STD_INPUT_HANDLE, L"CONIN$");
					}
					if (eiffeltui_w32_out == INVALID_HANDLE_VALUE) {
						eiffeltui_w32_out = eiffeltui_w32_open (STD_OUTPUT_HANDLE, L"CONOUT$");
					}
				}

				void eiffeltui_w32_save (void)
				{
					DWORD l_mode = 0;
					if (eiffeltui_w32_saved) return;
					if (eiffeltui_w32_in != INVALID_HANDLE_VALUE && GetConsoleMode (eiffeltui_w32_in, &l_mode)) {
						eiffeltui_w32_orig_in_mode = l_mode;
						eiffeltui_w32_in_saved = 1;
					}
					if (eiffeltui_w32_out != INVALID_HANDLE_VALUE && GetConsoleMode (eiffeltui_w32_out, &l_mode)) {
						eiffeltui_w32_orig_out_mode = l_mode;
						eiffeltui_w32_out_saved = 1;
					}
					eiffeltui_w32_orig_in_cp = GetConsoleCP ();
					eiffeltui_w32_orig_out_cp = GetConsoleOutputCP ();
					eiffeltui_w32_saved = 1;
				}

				void eiffeltui_w32_restore_modes (void)
				{
					if (!eiffeltui_w32_saved) return;
					if (eiffeltui_w32_in_saved) {
							/* ENABLE_EXTENDED_FLAGS makes the quick-edit/insert bits take effect. */
						SetConsoleMode (eiffeltui_w32_in, eiffeltui_w32_orig_in_mode | 0x0080);
					}
					if (eiffeltui_w32_out_saved) {
						SetConsoleMode (eiffeltui_w32_out, eiffeltui_w32_orig_out_mode);
					}
					if (eiffeltui_w32_orig_in_cp != 0) SetConsoleCP (eiffeltui_w32_orig_in_cp);
					if (eiffeltui_w32_orig_out_cp != 0) SetConsoleOutputCP (eiffeltui_w32_orig_out_cp);
				}

				static BOOL WINAPI eiffeltui_w32_ctrl_handler (DWORD a_type)
				{
					static const char l_reset [] =
						"\x1b[<u\x1b[?1000l\x1b[?1002l\x1b[?1006l\x1b[?2004l\x1b[?1004l\x1b[0m\x1b[?25h\x1b[?1049l";
					DWORD l_written = 0;
					switch (a_type) {
						case CTRL_C_EVENT:
						case CTRL_BREAK_EVENT:
						case CTRL_CLOSE_EVENT:
						case CTRL_LOGOFF_EVENT:
						case CTRL_SHUTDOWN_EVENT:
							if (eiffeltui_w32_deferring
								&& InterlockedCompareExchange (&eiffeltui_w32_pending, (LONG) a_type + 1, 0) == 0
									/* Check again: if the loop stopped deferring meanwhile, it may
									 * have looked for a request before this one was recorded. */
								&& InterlockedCompareExchange (&eiffeltui_w32_deferring, 0, 0)) {
								if (a_type == CTRL_C_EVENT || a_type == CTRL_BREAK_EVENT) {
										/* Handled: the loop restores the console, then ends the process. */
									return TRUE;
								}
									/* The process ends when this handler returns: give the loop a
									 * moment to restore the console first (the system allows 5 s). */
								if (eiffeltui_w32_restored != NULL
									&& WaitForSingleObject (eiffeltui_w32_restored, 3000) == WAIT_OBJECT_0) {
									return FALSE;
								}
							}
								/* Not deferred, a second request, or the loop did not answer: restore here. */
							if (eiffeltui_w32_out != INVALID_HANDLE_VALUE) {
								WriteConsoleA (eiffeltui_w32_out, l_reset, (DWORD) (sizeof (l_reset) - 1), &l_written, NULL);
							}
							eiffeltui_w32_restore_modes ();
							break;
						default:
							break;
					}
						/* Chain to the next handler (default termination / Eiffel runtime). */
					return FALSE;
				}

				void eiffeltui_w32_set_deferring (int a_on)
				{
					if (a_on && eiffeltui_w32_restored == NULL) {
						eiffeltui_w32_restored = CreateEventW (NULL, TRUE, FALSE, NULL);
					}
					InterlockedExchange (&eiffeltui_w32_deferring, a_on ? 1 : 0);
				}

				void eiffeltui_w32_finish (void)
				{
					if (eiffeltui_w32_restored != NULL) {
						SetEvent (eiffeltui_w32_restored);
					}
						/* The exit status of the default Ctrl handler. */
					ExitProcess ((UINT) 0xC000013AL);
				}

				void eiffeltui_w32_install_ctrl_handler (void)
				{
					if (!eiffeltui_w32_handler_installed) {
						if (SetConsoleCtrlHandler (eiffeltui_w32_ctrl_handler, TRUE)) {
							eiffeltui_w32_handler_installed = 1;
						}
					}
				}

					/* Test hooks: is the handler in the process handler list, and run it as the
					 * system would for `a_type` (without delivering a real Ctrl event, which would
					 * reach every process attached to the console). */
				int eiffeltui_w32_ctrl_handler_registered (void)
				{
						/* Removing succeeds only for a registered handler; put it back at once. */
					if (SetConsoleCtrlHandler (eiffeltui_w32_ctrl_handler, FALSE)) {
						SetConsoleCtrlHandler (eiffeltui_w32_ctrl_handler, TRUE);
						return 1;
					}
					return 0;
				}

				int eiffeltui_w32_invoke_ctrl_handler (DWORD a_type)
				{
					return (int) eiffeltui_w32_ctrl_handler (a_type);
				}

				static void eiffeltui_w32_runtime_epilogue (void)
				{
			]"
		end

	c_win32_init
			-- Cache console handles (opening CONIN$/CONOUT$ once when std handles are redirected).
		external
			"C inline use <windows.h>"
		alias
			"[
				extern void eiffeltui_w32_init (void);
				eiffeltui_w32_init ();
			]"
		end

	c_win32_enable_vt_mode: BOOLEAN
			-- Enable ENABLE_VIRTUAL_TERMINAL_PROCESSING and UTF-8 code pages, saving originals first.
		external
			"C inline use <windows.h>"
		alias
			"[
				extern HANDLE eiffeltui_w32_out;
				extern void eiffeltui_w32_save (void);
				DWORD l_mode = 0;
				if (eiffeltui_w32_out == INVALID_HANDLE_VALUE || !GetConsoleMode (eiffeltui_w32_out, &l_mode)) {
					return EIF_TRUE; /* Not a console: nothing to enable. */
				}
				eiffeltui_w32_save ();
				l_mode |= 0x0004; /* ENABLE_VIRTUAL_TERMINAL_PROCESSING */
				l_mode |= 0x0008; /* DISABLE_NEWLINE_AUTO_RETURN */
				SetConsoleOutputCP (65001); /* CP_UTF8 */
				SetConsoleCP (65001);
				return (EIF_BOOLEAN) (SetConsoleMode (eiffeltui_w32_out, l_mode) != 0);
			]"
		end

	c_win32_get_console_size (a_cols, a_rows: TYPED_POINTER [INTEGER]): BOOLEAN
			-- Query current console window dimensions.
		external
			"C inline use <windows.h>"
		alias
			"[
				extern HANDLE eiffeltui_w32_out;
				CONSOLE_SCREEN_BUFFER_INFO csbi;
				if (eiffeltui_w32_out == INVALID_HANDLE_VALUE || !GetConsoleScreenBufferInfo (eiffeltui_w32_out, &csbi)) {
					return EIF_FALSE;
				}
				*(EIF_INTEGER *)$a_cols = csbi.srWindow.Right - csbi.srWindow.Left + 1;
				*(EIF_INTEGER *)$a_rows = csbi.srWindow.Bottom - csbi.srWindow.Top + 1;
				return EIF_TRUE;
			]"
		end

	c_win32_enable_raw_mode: BOOLEAN
			-- Disable line input, echo and processed input; enable VT input. Saves originals first.
		external
			"C inline use <windows.h>"
		alias
			"[
				extern HANDLE eiffeltui_w32_in;
				extern void eiffeltui_w32_save (void);
				DWORD l_mode = 0;
				if (eiffeltui_w32_in == INVALID_HANDLE_VALUE || !GetConsoleMode (eiffeltui_w32_in, &l_mode)) {
					return EIF_TRUE; /* Not a console: nothing to change. */
				}
				eiffeltui_w32_save ();
				l_mode &= ~(0x0001 | 0x0002 | 0x0004); /* PROCESSED | LINE | ECHO */
				l_mode |= 0x0200; /* ENABLE_VIRTUAL_TERMINAL_INPUT */
				return (EIF_BOOLEAN) (SetConsoleMode (eiffeltui_w32_in, l_mode) != 0);
			]"
		end

	c_win32_disable_raw_mode: BOOLEAN
			-- Restore the raw-mode bits (processed, line, echo, VT input) to their original values.
		external
			"C inline use <windows.h>"
		alias
			"[
				extern HANDLE eiffeltui_w32_in;
				extern int eiffeltui_w32_in_saved;
				extern DWORD eiffeltui_w32_orig_in_mode;
				const DWORD l_mask = 0x0001 | 0x0002 | 0x0004 | 0x0200;
				DWORD l_mode = 0;
				if (eiffeltui_w32_in == INVALID_HANDLE_VALUE || !GetConsoleMode (eiffeltui_w32_in, &l_mode)) {
					return EIF_TRUE;
				}
				if (eiffeltui_w32_in_saved) {
					l_mode = (l_mode & ~l_mask) | (eiffeltui_w32_orig_in_mode & l_mask);
				} else {
					l_mode = (l_mode | 0x0001 | 0x0002 | 0x0004) & ~0x0200;
				}
				return (EIF_BOOLEAN) (SetConsoleMode (eiffeltui_w32_in, l_mode) != 0);
			]"
		end

	c_win32_enable_mouse: BOOLEAN
			-- Enable mouse input and disable quick-edit mode. Saves originals first.
		external
			"C inline use <windows.h>"
		alias
			"[
				extern HANDLE eiffeltui_w32_in;
				extern void eiffeltui_w32_save (void);
				DWORD l_mode = 0;
				if (eiffeltui_w32_in == INVALID_HANDLE_VALUE || !GetConsoleMode (eiffeltui_w32_in, &l_mode)) {
					return EIF_TRUE;
				}
				eiffeltui_w32_save ();
				l_mode |= 0x0080;  /* ENABLE_EXTENDED_FLAGS */
				l_mode &= ~0x0040; /* ENABLE_QUICK_EDIT_MODE */
				l_mode |= 0x0010;  /* ENABLE_MOUSE_INPUT */
				return (EIF_BOOLEAN) (SetConsoleMode (eiffeltui_w32_in, l_mode) != 0);
			]"
		end

	c_win32_disable_mouse: BOOLEAN
			-- Restore the original quick-edit and mouse-input bits.
		external
			"C inline use <windows.h>"
		alias
			"[
				extern HANDLE eiffeltui_w32_in;
				extern int eiffeltui_w32_in_saved;
				extern DWORD eiffeltui_w32_orig_in_mode;
				const DWORD l_mask = 0x0040 | 0x0010;
				DWORD l_mode = 0;
				if (eiffeltui_w32_in == INVALID_HANDLE_VALUE || !GetConsoleMode (eiffeltui_w32_in, &l_mode)) {
					return EIF_TRUE;
				}
				if (eiffeltui_w32_in_saved) {
					l_mode = (l_mode & ~l_mask) | (eiffeltui_w32_orig_in_mode & l_mask);
				} else {
					l_mode = (l_mode | 0x0040) & ~0x0010;
				}
				l_mode |= 0x0080; /* ENABLE_EXTENDED_FLAGS */
				return (EIF_BOOLEAN) (SetConsoleMode (eiffeltui_w32_in, l_mode) != 0);
			]"
		end

	c_win32_restore_modes
			-- Restore the exact original input/output modes and code pages.
		external
			"C inline use <windows.h>"
		alias
			"[
				extern void eiffeltui_w32_restore_modes (void);
				eiffeltui_w32_restore_modes ();
			]"
		end

	c_win32_read_unit (a_timeout_ms: INTEGER; a_enhanced: BOOLEAN): INTEGER
			-- Wait up to `a_timeout_ms` for a console event record.
			-- In enhanced mode, synthesizes Kitty escape sequences for key-up (!bKeyDown)
			-- and repeat events, streaming them as byte units.
			-- Returns (repeat_count << 16) | utf16_unit, or -1 when timeout expires.
		external
			"C blocking inline use <windows.h>, <stdio.h>"
		alias
			"[
				extern HANDLE eiffeltui_w32_in;
				static char l_seq_buf[64];
				static int l_seq_pos = 0;
				static int l_seq_len = 0;
					/* High surrogate of a key-up record, waiting for its low surrogate. */
				static unsigned int l_up_high = 0;

				if (l_seq_pos < l_seq_len) {
					unsigned char c = (unsigned char) l_seq_buf[l_seq_pos++];
					return (1 << 16) | (EIF_INTEGER) c;
				}
				l_seq_pos = 0;
				l_seq_len = 0;

				ULONGLONG l_deadline = GetTickCount64 () + (ULONGLONG) $a_timeout_ms;
				for (;;) {
					DWORD l_count = 0;
					ULONGLONG l_now;
					if (eiffeltui_w32_in == INVALID_HANDLE_VALUE || !GetNumberOfConsoleInputEvents (eiffeltui_w32_in, &l_count)) {
							/* Not a console (redirected stdin): honour the timeout instead of spinning. */
						if ($a_timeout_ms > 0) Sleep ((DWORD) $a_timeout_ms);
						return -1;
					}
					while (l_count > 0) {
						INPUT_RECORD l_rec;
						DWORD l_read = 0;
						if (!ReadConsoleInputW (eiffeltui_w32_in, &l_rec, 1, &l_read) || l_read == 0) {
							return -1;
						}
						l_count--;
						if (l_rec.EventType == KEY_EVENT) {
							KEY_EVENT_RECORD* kev = &l_rec.Event.KeyEvent;
							if (kev->bKeyDown) {
									/* Key-down records (auto-repeat included) keep the legacy text path:
									 * like a Kitty terminal without "report all keys as escape codes",
									 * repeats of text keys arrive as text, i.e. as presses. */
								if (kev->uChar.UnicodeChar != 0) {
									EIF_INTEGER l_repeat = (EIF_INTEGER) kev->wRepeatCount;
									if (l_repeat < 1) l_repeat = 1;
									if (l_repeat > 0x7FFF) l_repeat = 0x7FFF;
									return (l_repeat << 16) | (EIF_INTEGER) (unsigned short) kev->uChar.UnicodeChar;
								}
							} else if ($a_enhanced) {
								int shift = (kev->dwControlKeyState & 0x0010) ? 1 : 0;
								int alt = (kev->dwControlKeyState & (0x0001 | 0x0002)) ? 2 : 0;
								int ctrl = (kev->dwControlKeyState & (0x0004 | 0x0008)) ? 4 : 0;
								int mod = 1 + shift + alt + ctrl;
								WORD vk = kev->wVirtualKeyCode;
								unsigned int l_unit = (unsigned int) kev->uChar.UnicodeChar;
								unsigned int l_high = l_up_high;
								l_up_high = 0;
								l_seq_len = 0;
								if (l_unit >= 0xD800 && l_unit <= 0xDBFF) {
										/* A character above U+FFFF is released as two records (its UTF-16 halves):
										 * keep the high half, and report the code point with the low half. A half
										 * without its partner is dropped. */
									l_up_high = l_unit;
									continue;
								}
								if (l_unit >= 0xDC00 && l_unit <= 0xDFFF) {
									if (l_high != 0) {
										l_seq_len = sprintf (l_seq_buf, "\x1b[%u;%d:3u", 0x10000 + ((l_high - 0xD800) << 10) + (l_unit - 0xDC00), mod);
									}
								} else if (l_unit >= 32) {
									l_seq_len = sprintf (l_seq_buf, "\x1b[%u;%d:3u", l_unit, mod);
								} else if (vk >= 'A' && vk <= 'Z') {
										/* With Ctrl held the record carries a control character: report the letter */
									l_seq_len = sprintf (l_seq_buf, "\x1b[%d;%d:3u", (int) (vk - 'A' + 'a'), mod);
								} else if (vk >= '0' && vk <= '9') {
									l_seq_len = sprintf (l_seq_buf, "\x1b[%d;%d:3u", (int) vk, mod);
								} else if (vk == VK_RETURN) {
									l_seq_len = sprintf (l_seq_buf, "\x1b[13;%d:3u", mod);
								} else if (vk == VK_TAB) {
									l_seq_len = sprintf (l_seq_buf, "\x1b[9;%d:3u", mod);
								} else if (vk == VK_BACK) {
									l_seq_len = sprintf (l_seq_buf, "\x1b[127;%d:3u", mod);
								} else if (vk == VK_ESCAPE) {
									l_seq_len = sprintf (l_seq_buf, "\x1b[27;%d:3u", mod);
								} else if (vk == VK_UP) {
									l_seq_len = sprintf (l_seq_buf, "\x1b[1;%d:3A", mod);
								} else if (vk == VK_DOWN) {
									l_seq_len = sprintf (l_seq_buf, "\x1b[1;%d:3B", mod);
								} else if (vk == VK_RIGHT) {
									l_seq_len = sprintf (l_seq_buf, "\x1b[1;%d:3C", mod);
								} else if (vk == VK_LEFT) {
									l_seq_len = sprintf (l_seq_buf, "\x1b[1;%d:3D", mod);
								} else if (vk == VK_HOME) {
									l_seq_len = sprintf (l_seq_buf, "\x1b[1;%d:3H", mod);
								} else if (vk == VK_END) {
									l_seq_len = sprintf (l_seq_buf, "\x1b[1;%d:3F", mod);
								} else if (vk == VK_INSERT) {
									l_seq_len = sprintf (l_seq_buf, "\x1b[2;%d:3~", mod);
								} else if (vk == VK_DELETE) {
									l_seq_len = sprintf (l_seq_buf, "\x1b[3;%d:3~", mod);
								} else if (vk == VK_PRIOR) {
									l_seq_len = sprintf (l_seq_buf, "\x1b[5;%d:3~", mod);
								} else if (vk == VK_NEXT) {
									l_seq_len = sprintf (l_seq_buf, "\x1b[6;%d:3~", mod);
								} else if (vk >= VK_F1 && vk <= VK_F12) {
										/* Tilde forms for all of F1..F12 (Kitty's F3 is 13~, never ambiguous with a DSR reply) */
									static const int fn_codes[] = {11, 12, 13, 14, 15, 17, 18, 19, 20, 21, 23, 24};
									l_seq_len = sprintf (l_seq_buf, "\x1b[%d;%d:3~", fn_codes[vk - VK_F1], mod);
								}
								if (l_seq_len > 0) {
									l_seq_pos = 0;
									return (1 << 16) | (EIF_INTEGER) (unsigned char) l_seq_buf[l_seq_pos++];
								}
							}
						}
					}
					l_now = GetTickCount64 ();
					if (l_now >= l_deadline) {
						return -1;
					}
					if (WaitForSingleObject (eiffeltui_w32_in, (DWORD) (l_deadline - l_now)) != WAIT_OBJECT_0) {
						return -1;
					}
				}
			]"
		end

	c_win32_is_deferring: BOOLEAN
			-- Are Ctrl events deferred?
		external
			"C inline use <windows.h>"
		alias
			"[
				extern volatile LONG eiffeltui_w32_deferring;
				return (EIF_BOOLEAN) (eiffeltui_w32_deferring != 0);
			]"
		end

	c_win32_set_deferring (a_on: BOOLEAN)
			-- Defer Ctrl events (`a_on`) or not.
		external
			"C inline use <windows.h>"
		alias
			"[
				extern void eiffeltui_w32_set_deferring (int a_on);
				eiffeltui_w32_set_deferring ($a_on ? 1 : 0);
			]"
		end

	c_win32_pending: INTEGER
			-- Type of the deferred Ctrl event, or -1
		external
			"C inline use <windows.h>"
		alias
			"[
				extern volatile LONG eiffeltui_w32_pending;
				return (EIF_INTEGER) (InterlockedCompareExchange (&eiffeltui_w32_pending, 0, 0) - 1);
			]"
		end

	c_win32_discard
			-- Forget the deferred Ctrl event.
		external
			"C inline use <windows.h>"
		alias
			"[
				extern volatile LONG eiffeltui_w32_pending;
				InterlockedExchange (&eiffeltui_w32_pending, 0);
			]"
		end

	c_win32_finish
			-- Release a waiting handler and end the process.
		external
			"C inline use <windows.h>"
		alias
			"[
				extern void eiffeltui_w32_finish (void);
				eiffeltui_w32_finish ();
			]"
		end

	c_win32_install_ctrl_handler
			-- Register the console Ctrl handler (once per process).
		external
			"C inline use <windows.h>"
		alias
			"[
				extern void eiffeltui_w32_install_ctrl_handler (void);
				eiffeltui_w32_install_ctrl_handler ();
			]"
		end

invariant
	valid_pending_surrogate: pending_high_surrogate = 0 or (pending_high_surrogate >= 0xD800 and pending_high_surrogate <= 0xDBFF)

end
