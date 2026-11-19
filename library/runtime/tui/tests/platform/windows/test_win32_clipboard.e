note
	description: "[
		P2b K4, Windows only: WIN32_CONSOLE_DRIVER reads the system clipboard
		(`read_clipboard_text'), and TUI_APPLICATION.read_clipboard delivers that answer as a
		CLIPBOARD_EVENT. The tests set the clipboard through the Win32 API (`set_clipboard_text',
		`SetClipboardData'), read it back directly and through an application whose console
		is scripted (WIN32_CLIPBOARD_TEST_DRIVER), and hold it open from another thread to see
		`Status_unavailable' after the retries.
		These tests touch the developer's clipboard. Each runs inside `with_saved_clipboard',
		which saves the whole clipboard first (every format that is a memory block: text,
		HTML, RTF, a DIB image, a file list...; and an enhanced metafile) and puts it back
		afterwards, also on failure. When the clipboard holds a format that cannot be copied
		(owner-drawn, private, a bitmap with no DIB), or cannot be opened, the test is not
		run and prints a [NOTE] line, so the clipboard is never lost. The texts set here are marked
		`ExcludeClipboardContentFromMonitorProcessing', so that the clipboard history (Win+V)
		does not keep them.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_WIN32_CLIPBOARD

inherit
	EQA_TEST_SET

feature -- Registry

	tests: ARRAYED_LIST [TUPLE [name: STRING; routine: PROCEDURE]]
			-- Tests of this class, for TEST_PLATFORM_DRIVER.
		do
			create Result.make (5)
			Result.extend (["test_win32_clipboard_provider", agent test_win32_clipboard_provider])
			Result.extend (["test_win32_clipboard_reads_text", agent test_win32_clipboard_reads_text])
			Result.extend (["test_win32_clipboard_empty", agent test_win32_clipboard_empty])
			Result.extend (["test_win32_clipboard_too_large", agent test_win32_clipboard_too_large])
			Result.extend (["test_win32_clipboard_held_unavailable", agent test_win32_clipboard_held_unavailable])
			Result.extend (["test_win32_clipboard_saved_whole", agent test_win32_clipboard_saved_whole])
		end

feature -- Tests

	test_win32_clipboard_provider
			-- The Win32 driver, and so the default TERMINAL_DRIVER, reads the clipboard itself.
		local
			l_win32: WIN32_CONSOLE_DRIVER
			l_default: TERMINAL_DRIVER
		do
			create l_win32
			create l_default
			assert ("win32 provides", l_win32.provides_clipboard_read)
			assert ("default driver provides", l_default.provides_clipboard_read)
			assert ("default backend provides", (create {ANSI_TERMINAL_BACKEND}.make).driver.provides_clipboard_read)
		end

	test_win32_clipboard_reads_text
			-- Text set with SetClipboardData is read back as it was, directly and through
			-- `read_clipboard` / `read_selection`: ASCII, U+1F600 (a surrogate pair), CR LF
			-- kept, mixed scripts. Nothing is written to the terminal.
		do
			with_saved_clipboard (agent
				do
					assert_reads ("ascii", "Hello, clipboard!")
					assert_reads ("emoji", {STRING_32} "%/0x1F600/")
					assert_reads ("emoji in text", {STRING_32} "a%/0x1F600/b%/0x1F600/")
					assert_reads ("crlf", "line 1%R%Nline 2%R%N")
					assert_reads ("mixed", {STRING_32} "%/0xE9/%/0x5BBD/%/0x10FFFF/ tab%Tend")
					assert ("set for the selection", set_clipboard_text ("primary?"))
					assert_described ("read_selection reads the clipboard", app_answer (True, 0), "clip(p,text,primary?)")
				end)
		end

	test_win32_clipboard_empty
			-- An empty clipboard, and one that holds no text, give `Status_text` with empty
			-- text (Void from the driver).
		do
			with_saved_clipboard (agent
				do
					assert ("emptied", empty_clipboard (False))
					assert ("empty: Void", driver.read_clipboard_text (Big_cap) = Void)
					assert ("empty: text status", driver.last_clipboard_status = {CLIPBOARD_EVENT}.Status_text)
					assert_described ("empty answer", app_answer (False, 0), "clip(c,text,)")
					assert ("no text, other format only", empty_clipboard (True))
					assert ("no text: Void", driver.read_clipboard_text (Big_cap) = Void)
					assert ("no text: text status", driver.last_clipboard_status = {CLIPBOARD_EVENT}.Status_text)
					assert_described ("no-text answer", app_answer (False, 0), "clip(c,text,)")
					assert ("empty string set", set_clipboard_text (""))
					assert_described ("empty string answer", app_answer (False, 0), "clip(c,text,)")
				end)
		end

	test_win32_clipboard_too_large
			-- A text longer than the cap (UTF-16 code units) gives `Status_too_large` and no
			-- text; at the cap it is read. Through the application the cap is the input
			-- thread's `max_osc_size`.
		do
			with_saved_clipboard (agent
				do
					assert ("set", set_clipboard_text ("abcdef"))
					assert ("over the cap: Void", driver.read_clipboard_text (5) = Void)
					assert ("over the cap: too large", driver.last_clipboard_status = {CLIPBOARD_EVENT}.Status_too_large)
					assert ("at the cap", attached driver.read_clipboard_text (6) as t and then t.same_string ("abcdef"))
					assert ("at the cap: text", driver.last_clipboard_status = {CLIPBOARD_EVENT}.Status_text)
					assert_described ("app over the cap", app_answer (False, 5), "clip(c,too_large)")
					assert_described ("app at the cap", app_answer (False, 6), "clip(c,text,abcdef)")
					assert ("set emoji", set_clipboard_text ({STRING_32} "%/0x1F600/"))
					assert ("a surrogate pair is two units", driver.read_clipboard_text (1) = Void
						and driver.last_clipboard_status = {CLIPBOARD_EVENT}.Status_too_large)
					assert ("two units fit", attached driver.read_clipboard_text (2) as t and then t.count = 1)
				end)
		end

	test_win32_clipboard_held_unavailable
			-- While another thread holds the clipboard open, the read gives Void with
			-- `Status_unavailable` after retrying for about 100 ms, and the application's
			-- answer is `Status_unavailable`; once released, the text is read again.
		do
			with_saved_clipboard (agent
				local
					l_start, l_elapsed: INTEGER_64
				do
					assert ("set", set_clipboard_text ("free again"))
					assert ("held", hold_clipboard)
					l_start := {MONOTONIC_CLOCK}.milliseconds
					assert ("held: Void", driver.read_clipboard_text (Big_cap) = Void)
					l_elapsed := {MONOTONIC_CLOCK}.milliseconds - l_start
					assert ("held: unavailable", driver.last_clipboard_status = {CLIPBOARD_EVENT}.Status_unavailable)
					assert ("retried about 100 ms: " + l_elapsed.out, l_elapsed >= 80 and l_elapsed < 2_000)
					assert_described ("held: app answer", app_answer (False, 0), "clip(c,unavailable)")
					release_clipboard
					assert ("released: text", attached driver.read_clipboard_text (Big_cap) as t and then t.same_string ("free again"))
					assert_described ("released: app answer", app_answer (False, 0), "clip(c,text,free again)")
				end)
		end

	test_win32_clipboard_saved_whole
			-- The save that guards the developer's clipboard keeps formats other than text: a
			-- clipboard with text and a format of its own (as HTML or an image would be) is
			-- saved, overwritten, and put back with both.
		do
			with_saved_clipboard (agent
				do
					assert ("text and own format put", c_put_text_and_own_format)
					assert ("saved whole", c_snapshot_clipboard (1))
					assert ("overwritten", set_clipboard_text ({STRING_32} "other"))
					assert ("own format gone", not c_own_format_matches)
					assert ("put back", c_restore_clipboard (1))
					assert ("own format back", c_own_format_matches)
					assert ("text back", attached driver.read_clipboard_text (Big_cap) as t and then t.same_string ({STRING_32} "keep me"))
				end)
		end

feature {NONE} -- Checks

	assert_reads (a_tag: STRING; a_text: READABLE_STRING_32)
			-- Set the clipboard to `a_text`; the driver reads it back, and so does
			-- `read_clipboard` through an application.
		local
			l_expected: STRING_32
		do
			assert (a_tag + ": set", set_clipboard_text (a_text))
			assert (a_tag + ": read back", attached driver.read_clipboard_text (Big_cap) as t and then t.same_string (a_text))
			assert (a_tag + ": text status", driver.last_clipboard_status = {CLIPBOARD_EVENT}.Status_text)
			create l_expected.make_from_string ("clip(c,text,")
			append_visible (l_expected, a_text)
			l_expected.append_character (')')
			assert_described (a_tag + ": app answer", app_answer (False, 0), l_expected)
		end

	app_answer (a_selection: BOOLEAN; a_cap: INTEGER): ARRAYED_LIST [CLIPBOARD_EVENT]
			-- The answers `process` gets for one read (`read_selection` if `a_selection`,
			-- else `read_clipboard`) of an application on a scripted console whose driver
			-- reads the Win32 clipboard, `max_osc_size` set to `a_cap` (0: the default).
			-- Checks that nothing went to the terminal and that nothing came late.
		local
			l_driver: WIN32_CLIPBOARD_TEST_DRIVER
			l_sink: STRING_32
			l_backend: ANSI_TERMINAL_BACKEND
			l_app: TEST_TUI_APP_IMPL
		do
			create l_driver.make_reading (driver)
			create l_sink.make_empty
			l_driver.watch_sink (l_sink)
			l_driver.script ("r")
			create l_backend.make_with_driver_and_sink (l_driver, l_sink)
			create l_app.make_with_terminal (create {TERMINAL [ANSI_TERMINAL_BACKEND]}.make (l_backend))
			if a_cap > 0 then
				l_app.event_thread.set_max_osc_size (a_cap)
			end
			l_app.set_clipboard_timeout (5_000)
			l_app.set_key_hook (agent (k: KEY_EVENT; a: TEST_TUI_APP_IMPL; s: BOOLEAN)
				do
					if k.is_press and k.code.is_char and then k.code.character = 'r' then
						if s then
							a.read_selection
						else
							a.read_clipboard
						end
					end
				end (?, l_app, a_selection))
			l_app.set_clipboard_hook (agent (e: CLIPBOARD_EVENT; a: TEST_TUI_APP_IMPL) do a.stop end (?, l_app))
			l_app.run
			assert ("driver asked once", l_driver.clipboard_read_count = 1)
			assert ("no OSC 52", not l_sink.has_substring ({STRING_32} "]52;"))
			assert ("nothing late", l_app.late_clipboard_replies = 0)
			Result := l_app.clipboard_events
		end

	assert_described (a_tag: STRING; a_events: LIST [CLIPBOARD_EVENT]; a_expected: READABLE_STRING_GENERAL)
			-- `a_events` are described by `a_expected` (`clip(<selection>,<status>[,<text>])`,
			-- tokens separated by " | ", controls written `\xNN`).
		local
			l_got: STRING_32
		do
			create l_got.make_empty
			across a_events as e loop
				if not l_got.is_empty then
					l_got.append ({STRING_32} " | ")
				end
				l_got.append ({STRING_32} "clip(")
				l_got.append_character (e.selection)
				inspect e.status
				when {CLIPBOARD_EVENT}.Status_text then
					l_got.append ({STRING_32} ",text,")
					append_visible (l_got, e.text)
				when {CLIPBOARD_EVENT}.Status_unavailable then
					l_got.append ({STRING_32} ",unavailable")
				when {CLIPBOARD_EVENT}.Status_too_large then
					l_got.append ({STRING_32} ",too_large")
				else
					l_got.append ({STRING_32} ",invalid")
				end
				l_got.append_character (')')
			end
			assert (a_tag + ": expected [" + {UTF_CONVERTER}.string_32_to_utf_8_string_8 (a_expected.as_string_32)
				+ "], got [" + {UTF_CONVERTER}.string_32_to_utf_8_string_8 (l_got) + "]", l_got.same_string_general (a_expected))
		end

	append_visible (a_target: STRING_32; a_text: READABLE_STRING_GENERAL)
			-- Append `a_text` to `a_target`, control characters written `\xNN`.
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > a_text.count
			loop
				if a_text.code (i) < 32 or a_text.code (i) = 127 then
					a_target.append ({STRING_32} "\x")
					a_target.append_string_general (a_text.code (i).to_hex_string.substring (7, 8))
				else
					a_target.append_code (a_text.code (i))
				end
				i := i + 1
			end
		end

feature {NONE} -- Saving the developer's clipboard

	with_saved_clipboard (a_test: PROCEDURE)
			-- Run `a_test` with the developer's whole clipboard saved before and put back
			-- after, also when it fails (the failure is then passed on). Every format that is
			-- a memory block (text, HTML, RTF, a DIB image, a file list...) or an enhanced
			-- metafile is copied; the formats Windows makes from those (a bitmap from a DIB,
			-- ANSI text from Unicode text...) come back with them. When the clipboard holds a
			-- format that cannot be copied (owner-drawn, private, other GDI objects), or
			-- cannot be opened, `a_test` is not run and a [NOTE] line says so: the clipboard
			-- is never lost.
		local
			l_saved, l_restoring: BOOLEAN
		do
			if not l_restoring then
				release_clipboard
				l_saved := save_clipboard
				if l_saved then
					a_test.call
					l_restoring := True
					restore_clipboard
				else
					print ("  [NOTE] TEST_WIN32_CLIPBOARD: a test not run: the clipboard could not be saved whole (held by another program, or a format that cannot be copied)%N")
				end
			end
		rescue
			if not l_restoring and l_saved then
				l_restoring := True
				-- Put the clipboard back, then let the failure through
				restore_clipboard
			end
		end

	save_clipboard: BOOLEAN
			-- Copy every format of the clipboard into memory (`c_snapshot_clipboard`). False,
			-- with nothing kept, if it could not be opened or holds a format that cannot be
			-- copied.
		do
			c_define_holder
			Result := c_snapshot_clipboard (0)
		end

	restore_clipboard
			-- Put back the clipboard saved by `save_clipboard` (marked not for the clipboard
			-- history, which already has it), and free the copy. Best effort: never raises.
		local
			l_failed: BOOLEAN
		do
			if not l_failed then
				release_clipboard
				c_define_holder
				if not c_restore_clipboard (0) then
					io.error.put_string ("[NOTE] TEST_WIN32_CLIPBOARD could not put the clipboard back%N")
				end
			end
		rescue
			l_failed := True
			retry
		end

	c_snapshot_clipboard (a_slot: INTEGER): BOOLEAN
			-- See `save_clipboard`.
		external
			"C inline use <windows.h>"
		alias
			"[
				extern int eiffeltui_test_clip_snapshot (int s);
				return (EIF_BOOLEAN) (eiffeltui_test_clip_snapshot ($a_slot) != 0);
			]"
		end

	c_restore_clipboard (a_slot: INTEGER): BOOLEAN
			-- See `restore_clipboard`.
		external
			"C inline use <windows.h>"
		alias
			"[
				extern int eiffeltui_test_clip_restore (int s);
				return (EIF_BOOLEAN) (eiffeltui_test_clip_restore ($a_slot) != 0);
			]"
		end

feature {NONE} -- Win32 helpers

	driver: WIN32_CONSOLE_DRIVER
			-- Driver under test
		once
			create Result
		end

	Big_cap: INTEGER = 100_000_000
			-- A cap no test text reaches

	set_clipboard_text (a_text: READABLE_STRING_32): BOOLEAN
			-- Put `a_text` on the clipboard as CF_UNICODETEXT (marked not for the history).
		local
			l_units: MANAGED_POINTER
			l_count: INTEGER
		do
			l_units := utf_16 (a_text)
			l_count := l_units.count // 2 - 1
			Result := c_set_clipboard (l_units.item, l_count, True, True)
		end

	empty_clipboard (a_other_format: BOOLEAN): BOOLEAN
			-- Empty the clipboard; with `a_other_format`, leave a format that is not text in it.
		do
			Result := c_set_clipboard (default_pointer, 0, False, a_other_format)
		end

	utf_16 (a_text: READABLE_STRING_32): MANAGED_POINTER
			-- `a_text` as UTF-16 code units, with a terminating 0 unit.
		local
			i, l_pos: INTEGER
			l_code: NATURAL_32
		do
			create Result.make ((a_text.count * 2 + 1) * 2)
			from
				i := 1
			until
				i > a_text.count
			loop
				l_code := a_text.code (i)
				if l_code >= 0x10000 then
					Result.put_natural_16 ((0xD800 + ((l_code - 0x10000) |>> 10)).to_natural_16, l_pos)
					Result.put_natural_16 ((0xDC00 + ((l_code - 0x10000) & 0x3FF)).to_natural_16, l_pos + 2)
					l_pos := l_pos + 4
				else
					Result.put_natural_16 (l_code.to_natural_16, l_pos)
					l_pos := l_pos + 2
				end
				i := i + 1
			end
			Result.put_natural_16 (0, l_pos)
			Result.resize (l_pos + 2)
		ensure
			terminated: Result.read_natural_16 (Result.count - 2) = 0
		end

	c_set_clipboard (a_units: POINTER; a_count: INTEGER; a_text, a_mark: BOOLEAN): BOOLEAN
			-- Open the clipboard (owned by a message-only window made for the call and
			-- destroyed after, so that no window of this process stays its owner), empty it,
			-- then put `a_count` UTF-16 units at `a_units` as CF_UNICODETEXT if `a_text`, and
			-- the "ExcludeClipboardContentFromMonitorProcessing" format if `a_mark`.
		external
			"C inline use <windows.h>"
		alias
			"[
				HWND l_window = CreateWindowExW (0, L"STATIC", L"", 0, 0, 0, 0, 0, HWND_MESSAGE, NULL, GetModuleHandleW (NULL), NULL);
				BOOL l_ok = FALSE;
				int l_try;
				for (l_try = 0; l_try < 50; l_try++) {
					if (OpenClipboard (l_window)) {
						l_ok = TRUE;
						break;
					}
					Sleep (10);
				}
				if (l_ok) {
					l_ok = EmptyClipboard ();
					if (l_ok && $a_mark) {
						UINT l_format = RegisterClipboardFormatW (L"ExcludeClipboardContentFromMonitorProcessing");
						HGLOBAL l_flag = GlobalAlloc (GMEM_MOVEABLE, sizeof (DWORD));
						if (l_format != 0 && l_flag != NULL) {
							DWORD *l_p = (DWORD *) GlobalLock (l_flag);
							*l_p = 0;
							GlobalUnlock (l_flag);
							if (SetClipboardData (l_format, l_flag) == NULL) {
								GlobalFree (l_flag);
							}
						}
					}
					if (l_ok && $a_text) {
						SIZE_T l_bytes = ((SIZE_T) $a_count + 1) * sizeof (WCHAR);
						HGLOBAL l_data = GlobalAlloc (GMEM_MOVEABLE, l_bytes);
						l_ok = FALSE;
						if (l_data != NULL) {
							WCHAR *l_dst = (WCHAR *) GlobalLock (l_data);
							CopyMemory (l_dst, $a_units, (SIZE_T) $a_count * sizeof (WCHAR));
							l_dst [$a_count] = 0;
							GlobalUnlock (l_data);
							if (SetClipboardData (CF_UNICODETEXT, l_data) != NULL) {
								l_ok = TRUE;
							} else {
								GlobalFree (l_data);
							}
						}
					}
					CloseClipboard ();
				}
				if (l_window != NULL) {
					DestroyWindow (l_window);
				}
				return (EIF_BOOLEAN) (l_ok ? 1 : 0);
			]"
		end

	c_put_text_and_own_format: BOOLEAN
			-- Empty the clipboard and put "keep me" as CF_UNICODETEXT and the bytes "EiffelTUI"
			-- in a format registered as "EiffelTUI.TestFormat" (both marked not for the history).
		external
			"C inline use <windows.h>"
		alias
			"[
				static const WCHAR l_text [] = L"keep me";
				static const char l_bytes [] = "EiffelTUI";
				UINT l_own = RegisterClipboardFormatW (L"EiffelTUI.TestFormat");
				UINT l_mark = RegisterClipboardFormatW (L"ExcludeClipboardContentFromMonitorProcessing");
				HWND l_window = CreateWindowExW (0, L"STATIC", L"", 0, 0, 0, 0, 0, HWND_MESSAGE, NULL, GetModuleHandleW (NULL), NULL);
				BOOL l_ok = FALSE;
				int l_try;
				for (l_try = 0; l_try < 50 && !l_ok; l_try++) {
					l_ok = OpenClipboard (l_window);
					if (!l_ok) Sleep (10);
				}
				if (l_ok) {
					HGLOBAL l_t = GlobalAlloc (GMEM_MOVEABLE, sizeof (l_text));
					HGLOBAL l_o = GlobalAlloc (GMEM_MOVEABLE, sizeof (l_bytes));
					HGLOBAL l_m = GlobalAlloc (GMEM_MOVEABLE, sizeof (DWORD));
					l_ok = EmptyClipboard () && l_t != NULL && l_o != NULL && l_m != NULL && l_own != 0;
					if (l_ok) {
						CopyMemory (GlobalLock (l_t), l_text, sizeof (l_text)); GlobalUnlock (l_t);
						CopyMemory (GlobalLock (l_o), l_bytes, sizeof (l_bytes)); GlobalUnlock (l_o);
						*(DWORD *) GlobalLock (l_m) = 0; GlobalUnlock (l_m);
						l_ok = SetClipboardData (CF_UNICODETEXT, l_t) != NULL;
						if (l_ok) l_t = NULL;
						l_ok = l_ok && SetClipboardData (l_own, l_o) != NULL;
						if (l_ok) l_o = NULL;
						if (l_mark != 0 && SetClipboardData (l_mark, l_m) != NULL) l_m = NULL;
					}
					if (l_t != NULL) GlobalFree (l_t);
					if (l_o != NULL) GlobalFree (l_o);
					if (l_m != NULL) GlobalFree (l_m);
					CloseClipboard ();
				}
				if (l_window != NULL) DestroyWindow (l_window);
				return (EIF_BOOLEAN) (l_ok ? 1 : 0);
			]"
		end

	c_own_format_matches: BOOLEAN
			-- Does the clipboard hold "EiffelTUI.TestFormat" with the bytes of
			-- `c_put_text_and_own_format`?
		external
			"C inline use <windows.h>, <string.h>"
		alias
			"[
				static const char l_bytes [] = "EiffelTUI";
				UINT l_own = RegisterClipboardFormatW (L"EiffelTUI.TestFormat");
				BOOL l_ok = FALSE;
				int l_try;
				for (l_try = 0; l_try < 50; l_try++) {
					if (OpenClipboard (NULL)) {
						HANDLE l_h = GetClipboardData (l_own);
						if (l_h != NULL && GlobalSize (l_h) >= sizeof (l_bytes)) {
							const char *l_p = (const char *) GlobalLock (l_h);
							l_ok = l_p != NULL && memcmp (l_p, l_bytes, sizeof (l_bytes)) == 0;
							GlobalUnlock (l_h);
						}
						CloseClipboard ();
						break;
					}
					Sleep (10);
				}
				return (EIF_BOOLEAN) (l_ok ? 1 : 0);
			]"
		end

	hold_clipboard: BOOLEAN
			-- Open the clipboard on a new thread (with a message-only window of that thread)
			-- and keep it open until `release_clipboard` (or 10 s). True once that thread has
			-- it open.
		do
			c_define_holder
			Result := c_hold_clipboard
		end

	release_clipboard
			-- Let the thread of `hold_clipboard` close the clipboard, and wait for it.
			-- Nothing if none holds it.
		do
			c_define_holder
			c_release_clipboard
		end

	c_hold_clipboard: BOOLEAN
			-- See `hold_clipboard`.
		external
			"C inline use <windows.h>"
		alias
			"[
				extern int eiffeltui_test_clip_hold (void);
				return (EIF_BOOLEAN) (eiffeltui_test_clip_hold () != 0);
			]"
		end

	c_define_holder
			-- Define the holder thread, the saved clipboard and their state at file scope (the body closes the
			-- generated wrapper and reopens an unused function for its epilogue, as
			-- {WIN32_CONSOLE_DRIVER}.c_win32_define_runtime does).
		external
			"C inline use <windows.h>, <stdlib.h>"
		alias
			"[
				}

				static HANDLE eiffeltui_test_clip_opened = NULL;
				static HANDLE eiffeltui_test_clip_release = NULL;
				static HANDLE eiffeltui_test_clip_thread = NULL;
				static volatile LONG eiffeltui_test_clip_held = 0;

					/* The holder opens the clipboard with a window of its own thread: opened
					 * with NULL, another thread of the same process could still open it. */
				static DWORD WINAPI eiffeltui_test_clip_holder (LPVOID a_unused)
				{
					int l_try;
					HWND l_window = CreateWindowExW (0, L"STATIC", L"", 0, 0, 0, 0, 0, HWND_MESSAGE, NULL, GetModuleHandleW (NULL), NULL);
					for (l_try = 0; l_window != NULL && l_try < 100; l_try++) {
						if (OpenClipboard (l_window)) {
							InterlockedExchange (&eiffeltui_test_clip_held, 1);
							break;
						}
						Sleep (10);
					}
					SetEvent (eiffeltui_test_clip_opened);
					if (eiffeltui_test_clip_held) {
						WaitForSingleObject (eiffeltui_test_clip_release, 10000);
						CloseClipboard ();
						InterlockedExchange (&eiffeltui_test_clip_held, 0);
					}
					if (l_window != NULL) {
						DestroyWindow (l_window);
					}
					return 0;
				}

				int eiffeltui_test_clip_hold (void)
				{
					if (eiffeltui_test_clip_thread != NULL) {
						return 0;
					}
					eiffeltui_test_clip_held = 0;
					eiffeltui_test_clip_opened = CreateEventW (NULL, TRUE, FALSE, NULL);
					eiffeltui_test_clip_release = CreateEventW (NULL, TRUE, FALSE, NULL);
					eiffeltui_test_clip_thread = CreateThread (NULL, 0, eiffeltui_test_clip_holder, NULL, 0, NULL);
					if (eiffeltui_test_clip_thread == NULL) {
						return 0;
					}
					WaitForSingleObject (eiffeltui_test_clip_opened, 5000);
					return (int) eiffeltui_test_clip_held;
				}

				void eiffeltui_test_clip_release_held (void)
				{
					if (eiffeltui_test_clip_thread != NULL) {
						SetEvent (eiffeltui_test_clip_release);
						WaitForSingleObject (eiffeltui_test_clip_thread, 5000);
						CloseHandle (eiffeltui_test_clip_thread);
						CloseHandle (eiffeltui_test_clip_opened);
						CloseHandle (eiffeltui_test_clip_release);
						eiffeltui_test_clip_thread = NULL;
					}
				}

					/* The developer's clipboard, saved whole by `eiffeltui_test_clip_snapshot'
					 * and put back by `eiffeltui_test_clip_restore'. */
				#define EIFFELTUI_TEST_CLIP_MAX 256
					/* Two slots: 0 for the developer's clipboard, 1 for a test of the save itself */
				static UINT eiffeltui_test_clip_formats [2][EIFFELTUI_TEST_CLIP_MAX];
				static SIZE_T eiffeltui_test_clip_sizes [2][EIFFELTUI_TEST_CLIP_MAX];
				static void *eiffeltui_test_clip_data [2][EIFFELTUI_TEST_CLIP_MAX];
				static int eiffeltui_test_clip_count [2] = {0, 0};
				static int eiffeltui_test_clip_saved [2] = {0, 0};

				static void eiffeltui_test_clip_free (int s)
				{
					int i;
					for (i = 0; i < eiffeltui_test_clip_count [s]; i++) {
						free (eiffeltui_test_clip_data [s][i]);
						eiffeltui_test_clip_data [s][i] = NULL;
					}
					eiffeltui_test_clip_count [s] = 0;
					eiffeltui_test_clip_saved [s] = 0;
				}

				static BOOL eiffeltui_test_clip_open (HWND a_window)
				{
					int l_try;
					for (l_try = 0; l_try < 50; l_try++) {
						if (OpenClipboard (a_window)) {
							return TRUE;
						}
						Sleep (10);
					}
					return FALSE;
				}

					/* Save every format of the clipboard: 1 when all of it could be kept.
					 * Formats Windows makes from another one that is kept are left out (CF_TEXT,
					 * CF_OEMTEXT and CF_LOCALE from CF_UNICODETEXT; CF_BITMAP, CF_PALETTE and
					 * CF_DIB from CF_DIBV5 or CF_DIB; CF_METAFILEPICT from CF_ENHMETAFILE). */
				int eiffeltui_test_clip_snapshot (int s)
				{
					HWND l_window;
					UINT l_format = 0;
					BOOL l_ok = TRUE, l_has_dibv5 = FALSE, l_has_dib = FALSE;
					BOOL l_has_enh = FALSE, l_has_unicode = FALSE;
					eiffeltui_test_clip_free (s);
					l_window = CreateWindowExW (0, L"STATIC", L"", 0, 0, 0, 0, 0, HWND_MESSAGE, NULL, GetModuleHandleW (NULL), NULL);
					if (!eiffeltui_test_clip_open (l_window)) {
						if (l_window != NULL) DestroyWindow (l_window);
						return 0;
					}
					while ((l_format = EnumClipboardFormats (l_format)) != 0) {
						if (l_format == CF_DIBV5) l_has_dibv5 = TRUE;
						if (l_format == CF_DIB) l_has_dib = TRUE;
						if (l_format == CF_ENHMETAFILE) l_has_enh = TRUE;
						if (l_format == CF_UNICODETEXT) l_has_unicode = TRUE;
					}
					l_format = 0;
					while (l_ok && (l_format = EnumClipboardFormats (l_format)) != 0) {
						HANDLE l_handle;
						void *l_copy = NULL;
						SIZE_T l_size = 0;
						if (l_format == CF_TEXT || l_format == CF_OEMTEXT || l_format == CF_LOCALE) {
							if (l_has_unicode) continue;
						} else if (l_format == CF_DIB) {
							if (l_has_dibv5) continue;
						} else if (l_format == CF_BITMAP || l_format == CF_PALETTE) {
							if (l_has_dib || l_has_dibv5) continue;
							l_ok = FALSE; /* A bitmap with no DIB: cannot be copied */
							break;
						} else if (l_format == CF_METAFILEPICT) {
							if (l_has_enh) continue;
							l_ok = FALSE;
							break;
						} else if (l_format == CF_OWNERDISPLAY || l_format == CF_DSPBITMAP || l_format == CF_DSPMETAFILEPICT
							|| l_format == CF_DSPENHMETAFILE || l_format == CF_DSPTEXT
							|| (l_format >= CF_PRIVATEFIRST && l_format <= CF_GDIOBJLAST)) {
							l_ok = FALSE; /* Owner-drawn, private or a GDI object: cannot be copied */
							break;
						}
						if (eiffeltui_test_clip_count [s] >= EIFFELTUI_TEST_CLIP_MAX) {
							l_ok = FALSE;
							break;
						}
						l_handle = GetClipboardData (l_format);
						if (l_handle == NULL) {
							continue; /* Nothing to render: nothing lost */
						}
						if (l_format == CF_ENHMETAFILE) {
							UINT l_bytes = GetEnhMetaFileBits ((HENHMETAFILE) l_handle, 0, NULL);
							l_size = l_bytes;
							l_copy = l_bytes > 0 ? malloc (l_bytes) : NULL;
							if (l_copy == NULL || GetEnhMetaFileBits ((HENHMETAFILE) l_handle, l_bytes, (LPBYTE) l_copy) != l_bytes) {
								free (l_copy);
								l_ok = FALSE;
								break;
							}
						} else {
							void *l_src = GlobalLock (l_handle);
							l_size = GlobalSize (l_handle);
							if (l_src == NULL) {
								l_ok = FALSE;
								break;
							}
							l_copy = malloc (l_size > 0 ? l_size : 1);
							if (l_copy == NULL) {
								GlobalUnlock (l_handle);
								l_ok = FALSE;
								break;
							}
							CopyMemory (l_copy, l_src, l_size);
							GlobalUnlock (l_handle);
						}
						eiffeltui_test_clip_formats [s][eiffeltui_test_clip_count [s]] = l_format;
						eiffeltui_test_clip_sizes [s][eiffeltui_test_clip_count [s]] = l_size;
						eiffeltui_test_clip_data [s][eiffeltui_test_clip_count [s]] = l_copy;
						eiffeltui_test_clip_count [s]++;
					}
					CloseClipboard ();
					if (l_window != NULL) DestroyWindow (l_window);
					if (!l_ok) {
						eiffeltui_test_clip_free (s);
						return 0;
					}
					eiffeltui_test_clip_saved [s] = 1;
					return 1;
				}

					/* Put back what `eiffeltui_test_clip_snapshot' saved (marked not for the
					 * clipboard history, which already holds it), and free the copy. */
				int eiffeltui_test_clip_restore (int s)
				{
					HWND l_window;
					BOOL l_ok;
					int i;
					UINT l_mark;
					if (!eiffeltui_test_clip_saved [s]) {
						return 1;
					}
					l_window = CreateWindowExW (0, L"STATIC", L"", 0, 0, 0, 0, 0, HWND_MESSAGE, NULL, GetModuleHandleW (NULL), NULL);
					l_ok = eiffeltui_test_clip_open (l_window);
					if (l_ok) {
						l_ok = EmptyClipboard ();
						l_mark = RegisterClipboardFormatW (L"ExcludeClipboardContentFromMonitorProcessing");
						for (i = 0; l_ok && i < eiffeltui_test_clip_count [s]; i++) {
							UINT l_format = eiffeltui_test_clip_formats [s][i];
							if (l_format == l_mark) continue;
							if (l_format == CF_ENHMETAFILE) {
								HENHMETAFILE l_meta = SetEnhMetaFileBits ((UINT) eiffeltui_test_clip_sizes [s][i], (const BYTE *) eiffeltui_test_clip_data [s][i]);
								if (l_meta == NULL || SetClipboardData (CF_ENHMETAFILE, l_meta) == NULL) {
									if (l_meta != NULL) DeleteEnhMetaFile (l_meta);
									l_ok = FALSE;
								}
							} else {
								HGLOBAL l_global = GlobalAlloc (GMEM_MOVEABLE, eiffeltui_test_clip_sizes [s][i] > 0 ? eiffeltui_test_clip_sizes [s][i] : 1);
								void *l_dst = l_global != NULL ? GlobalLock (l_global) : NULL;
								if (l_dst == NULL) {
									if (l_global != NULL) GlobalFree (l_global);
									l_ok = FALSE;
								} else {
									CopyMemory (l_dst, eiffeltui_test_clip_data [s][i], eiffeltui_test_clip_sizes [s][i]);
									GlobalUnlock (l_global);
									if (SetClipboardData (l_format, l_global) == NULL) {
										GlobalFree (l_global);
										l_ok = FALSE;
									}
								}
							}
						}
						if (l_ok && l_mark != 0) {
							HGLOBAL l_flag = GlobalAlloc (GMEM_MOVEABLE, sizeof (DWORD));
							if (l_flag != NULL) {
								DWORD *l_p = (DWORD *) GlobalLock (l_flag);
								*l_p = 0;
								GlobalUnlock (l_flag);
								if (SetClipboardData (l_mark, l_flag) == NULL) GlobalFree (l_flag);
							}
						}
						CloseClipboard ();
					}
					if (l_window != NULL) DestroyWindow (l_window);
					eiffeltui_test_clip_free (s);
					return l_ok ? 1 : 0;
				}

				static void eiffeltui_test_clip_epilogue (void)
				{
			]"
		end

	c_release_clipboard
			-- See `release_clipboard`.
		external
			"C inline use <windows.h>"
		alias
			"[
				extern void eiffeltui_test_clip_release_held (void);
				eiffeltui_test_clip_release_held ();
			]"
		end

end
