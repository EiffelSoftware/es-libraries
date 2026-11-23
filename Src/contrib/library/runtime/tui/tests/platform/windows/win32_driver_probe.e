note
	description: "[
		WIN32_CONSOLE_DRIVER with its UTF-16 decoding exposed and a way to read the
		current console modes, for white-box tests.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	WIN32_DRIVER_PROBE

inherit
	WIN32_CONSOLE_DRIVER
		export
			{ANY} enqueue_utf16_unit
		end

create
	default_create

feature -- Inspection

	has_console_modes: BOOLEAN
			-- Are both console handles real consoles (so modes can be read)?
		local
			l_in, l_out: NATURAL_32
		do
			Result := c_modes ($l_in, $l_out)
		end

	console_modes: TUPLE [input, output: NATURAL_32]
			-- Current input and output console modes (0 when not a console).
		local
			l_in, l_out: NATURAL_32
		do
			c_modes ($l_in, $l_out).do_nothing
			Result := [l_in, l_out]
		end

	ctrl_handler_registered: BOOLEAN
			-- Is the console Ctrl handler in the process handler list?
		external
			"C inline use <windows.h>"
		alias
			"[
				extern int eiffeltui_w32_ctrl_handler_registered (void);
				return (EIF_BOOLEAN) (eiffeltui_w32_ctrl_handler_registered () != 0);
			]"
		end

	reset_sequence: STRING_8
			-- The escape sequences the Ctrl handler writes when it restores the console itself
		do
			create Result.make_from_c (c_reset_sequence)
		end

	handler_output: STRING_8
			-- What the Ctrl handler writes when it restores the console itself now: the reset,
			-- then the title pop if a title is pushed. Like the handler, it clears the push.
		local
			l_buffer: MANAGED_POINTER
			l_count: INTEGER
		do
			create l_buffer.make (256)
			l_count := c_reset_output (l_buffer.item)
			create Result.make_from_c_substring (l_buffer.item, 1, l_count)
		ensure
			popped: not is_title_pushed
		end

	invoke_ctrl_handler (a_type: NATURAL_32): BOOLEAN
			-- Run the console Ctrl handler as the system would for event `a_type`;
			-- True if it handled the event (False: chains to the next handler).
		external
			"C inline use <windows.h>"
		alias
			"[
				extern int eiffeltui_w32_invoke_ctrl_handler (DWORD a_type);
				return (EIF_BOOLEAN) (eiffeltui_w32_invoke_ctrl_handler ((DWORD) $a_type) != 0);
			]"
		end

	inject_key (a_down: BOOLEAN; a_vk, a_char: NATURAL_16; a_control_state: NATURAL_32): BOOLEAN
			-- Append one KEY_EVENT record to the console input buffer (read back by
			-- `read_char_with_timeout`, exactly like a real key stroke).
		external
			"C inline use <windows.h>"
		alias
			"[
				extern HANDLE eiffeltui_w32_in;
				INPUT_RECORD l_rec;
				DWORD l_written = 0;
				ZeroMemory (&l_rec, sizeof (l_rec));
				l_rec.EventType = KEY_EVENT;
				l_rec.Event.KeyEvent.bKeyDown = $a_down ? TRUE : FALSE;
				l_rec.Event.KeyEvent.wRepeatCount = 1;
				l_rec.Event.KeyEvent.wVirtualKeyCode = (WORD) $a_vk;
				l_rec.Event.KeyEvent.uChar.UnicodeChar = (WCHAR) $a_char;
				l_rec.Event.KeyEvent.dwControlKeyState = (DWORD) $a_control_state;
				return (EIF_BOOLEAN) (WriteConsoleInputW (eiffeltui_w32_in, &l_rec, 1, &l_written) && l_written == 1);
			]"
		end

	inject_key_repeated (a_down: BOOLEAN; a_vk, a_char: NATURAL_16; a_control_state: NATURAL_32; a_repeat_count: NATURAL_16): BOOLEAN
			-- Like `inject_key`, with `wRepeatCount` set to `a_repeat_count` (the console's
			-- way of folding several auto-repeats of a key into one record).
		external
			"C inline use <windows.h>"
		alias
			"[
				extern HANDLE eiffeltui_w32_in;
				INPUT_RECORD l_rec;
				DWORD l_written = 0;
				ZeroMemory (&l_rec, sizeof (l_rec));
				l_rec.EventType = KEY_EVENT;
				l_rec.Event.KeyEvent.bKeyDown = $a_down ? TRUE : FALSE;
				l_rec.Event.KeyEvent.wRepeatCount = (WORD) $a_repeat_count;
				l_rec.Event.KeyEvent.wVirtualKeyCode = (WORD) $a_vk;
				l_rec.Event.KeyEvent.uChar.UnicodeChar = (WCHAR) $a_char;
				l_rec.Event.KeyEvent.dwControlKeyState = (DWORD) $a_control_state;
				return (EIF_BOOLEAN) (WriteConsoleInputW (eiffeltui_w32_in, &l_rec, 1, &l_written) && l_written == 1);
			]"
		end

	inject_focus (a_gained: BOOLEAN): BOOLEAN
			-- Append one FOCUS_EVENT record (focus gained if `a_gained`, lost otherwise) to
			-- the console input buffer.
		external
			"C inline use <windows.h>"
		alias
			"[
				extern HANDLE eiffeltui_w32_in;
				INPUT_RECORD l_rec;
				DWORD l_written = 0;
				ZeroMemory (&l_rec, sizeof (l_rec));
				l_rec.EventType = FOCUS_EVENT;
				l_rec.Event.FocusEvent.bSetFocus = $a_gained ? TRUE : FALSE;
				return (EIF_BOOLEAN) (WriteConsoleInputW (eiffeltui_w32_in, &l_rec, 1, &l_written) && l_written == 1);
			]"
		end

	inject_menu_record: BOOLEAN
			-- Append one MENU_EVENT record, which the driver ignores. Between two equal key-down
			-- records it keeps the console from folding them into one record with a larger
			-- `wRepeatCount`, as it does when it writes them next to each other.
		external
			"C inline use <windows.h>"
		alias
			"[
				extern HANDLE eiffeltui_w32_in;
				INPUT_RECORD l_rec;
				DWORD l_written = 0;
				ZeroMemory (&l_rec, sizeof (l_rec));
				l_rec.EventType = MENU_EVENT;
				return (EIF_BOOLEAN) (WriteConsoleInputW (eiffeltui_w32_in, &l_rec, 1, &l_written) && l_written == 1);
			]"
		end

	pending_record_count: INTEGER
			-- Number of records in the console input buffer
		external
			"C inline use <windows.h>"
		alias
			"[
				extern HANDLE eiffeltui_w32_in;
				DWORD l_count = 0;
				if (!GetNumberOfConsoleInputEvents (eiffeltui_w32_in, &l_count)) return -1;
				return (EIF_INTEGER) l_count;
			]"
		end

	input_mode: NATURAL_32
			-- The console input mode now (0 when not a console)
		do
			Result := console_modes.input
		end

	set_input_mode (a_mode: NATURAL_32): BOOLEAN
			-- Set the console input mode to `a_mode` exactly (no saved state of the driver
			-- involved); True if the console took it.
		external
			"C inline use <windows.h>"
		alias
			"[
				extern HANDLE eiffeltui_w32_in;
				return (EIF_BOOLEAN) (SetConsoleMode (eiffeltui_w32_in, (DWORD) $a_mode) != 0);
			]"
		end

	inject_chars (a_text: READABLE_STRING_32): BOOLEAN
			-- Append one key-down record per character of `a_text` (BMP only), with no key
			-- code, no scan code and no modifier state: the records the console makes of a
			-- key-down record when ENABLE_VIRTUAL_TERMINAL_INPUT is on.
		local
			i: INTEGER
		do
			Result := True
			from
				i := 1
			until
				i > a_text.count or not Result
			loop
				Result := inject_key (True, 0, a_text.code (i).to_natural_16, 0)
				i := i + 1
			end
		end

	flush_console_input
			-- Discard pending console input records.
		external
			"C inline use <windows.h>"
		alias
			"[
				extern HANDLE eiffeltui_w32_in;
				FlushConsoleInputBuffer (eiffeltui_w32_in);
			]"
		end

feature {NONE} -- Implementation

	c_reset_sequence: POINTER
			-- The driver's `eiffeltui_w32_reset` (NUL-terminated)
		external
			"C inline"
		alias
			"[
				extern const char eiffeltui_w32_reset [];
				return (EIF_POINTER) eiffeltui_w32_reset;
			]"
		end

	c_reset_output (a_buffer: POINTER): INTEGER
			-- The driver's `eiffeltui_w32_reset_output` into `a_buffer` (256 bytes); its length
		external
			"C inline use <windows.h>"
		alias
			"[
				extern DWORD eiffeltui_w32_reset_output (char *a_buf);
				return (EIF_INTEGER) eiffeltui_w32_reset_output ((char *) $a_buffer);
			]"
		end

	c_modes (a_in, a_out: TYPED_POINTER [NATURAL_32]): BOOLEAN
		external
			"C inline use <windows.h>"
		alias
			"[
				extern HANDLE eiffeltui_w32_in;
				extern HANDLE eiffeltui_w32_out;
				DWORD l_in = 0, l_out = 0;
				BOOL l_ok = GetConsoleMode (eiffeltui_w32_in, &l_in) && GetConsoleMode (eiffeltui_w32_out, &l_out);
				*(EIF_NATURAL_32 *) $a_in = (EIF_NATURAL_32) l_in;
				*(EIF_NATURAL_32 *) $a_out = (EIF_NATURAL_32) l_out;
				return (EIF_BOOLEAN) (l_ok != 0);
			]"
		end

end
