note
	description: "[
		FAKE_CONSOLE_DRIVER whose clipboard read is the real Win32 one
		({WIN32_CONSOLE_DRIVER}.read_clipboard_text), so that TEST_WIN32_CLIPBOARD can run
		TUI_APPLICATION.read_clipboard against the system clipboard while the console itself
		stays scripted (P2b K4).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	WIN32_CLIPBOARD_TEST_DRIVER

inherit
	FAKE_CONSOLE_DRIVER
		redefine
			provides_clipboard_read,
			read_clipboard_text
		end

create
	make_reading

feature {NONE} -- Initialization

	make_reading (a_win32: WIN32_CONSOLE_DRIVER)
			-- Script the console as FAKE_CONSOLE_DRIVER does, and read the clipboard through
			-- `a_win32`.
		do
			default_create
			win32 := a_win32
		ensure
			set: win32 = a_win32
		end

feature -- Access

	win32: WIN32_CONSOLE_DRIVER
			-- Driver whose clipboard read is used

feature -- Clipboard read

	provides_clipboard_read: BOOLEAN
			-- As the Win32 driver.
		do
			Result := win32.provides_clipboard_read
		end

	read_clipboard_text (a_max_count: INTEGER): detachable STRING_32
			-- The Win32 driver's read.
		do
			clipboard_read_count := clipboard_read_count + 1
			last_clipboard_max_count := a_max_count
			Result := win32.read_clipboard_text (a_max_count)
			last_clipboard_status := win32.last_clipboard_status
		end

end
