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
