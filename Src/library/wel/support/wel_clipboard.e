note
	description: "Class that handles Windows Clipboard operations"
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date$"
	revision: "$Revision$"

class
	WEL_CLIPBOARD

inherit
	ANY
		redefine
			default_create
		end

feature {NONE} -- Initialization

	default_create
		do
			create last_string.make_empty
			create last_files.make (0)
		end

feature -- Access

	clipboard_open: BOOLEAN
		-- Is clipboard open?

	last_string: STRING_32
			-- Text retrieved from Clipboard
			-- Only valid after a successfull call to
			-- `retrieve_clipboard_text'

	last_data: detachable MANAGED_POINTER
			-- Data retrieved from the clipboard (a copy), if any.
			-- Only valid after a call to `retrieve_clipboard_data'.

	last_files: ARRAYED_LIST [PATH]
			-- Files retrieved from the clipboard.
			-- Only valid after a call to `retrieve_clipboard_files'.

	is_clipboard_format_available (format: INTEGER): BOOLEAN
		do
			Result :=  cwel_is_clipboard_format_available (format)
		end

	registered_clipboard_format (a_name: READABLE_STRING_GENERAL): INTEGER
			-- Clipboard format registered with name `a_name' (such as "PNG" or "HTML Format"),
			-- registered if needed; 0 if it fails.
		require
			a_name_not_empty: not a_name.is_empty
		local
			l_name: WEL_STRING
		do
			create l_name.make (a_name)
			Result := cwel_register_clipboard_format (l_name.item)
		end

feature -- Element Change

	retrieve_clipboard_text
			-- Retrieves text from the clipboard
		require
			clipboard_open: clipboard_open
			text_available: is_clipboard_format_available ({WEL_CLIPBOARD_CONSTANTS}.Cf_unicodetext)
		local
			shared_string: WEL_SHARED_MEMORY_STRING
			shared_memory_handle: POINTER
			l_string: detachable like last_string
		do
			shared_memory_handle := cwel_get_clipboard_data ({WEL_CLIPBOARD_CONSTANTS}.Cf_unicodetext)
			if shared_memory_handle /= default_pointer then
				create shared_string.make_from_handle (shared_memory_handle)
				shared_string.retrieve_string
				l_string := shared_string.last_string
			end
			if l_string = Void then
				create last_string.make_empty
			else
				last_string := l_string
			end
		ensure
			last_string_not_void: last_string /= Void
		end

	retrieve_clipboard_text_discarding_carriage_return
			-- Retrieves text from the clipboard
		require
			clipboard_open: clipboard_open
			text_available: is_clipboard_format_available ({WEL_CLIPBOARD_CONSTANTS}.Cf_unicodetext)
		local
			shared_string: WEL_SHARED_MEMORY_STRING
			shared_memory_handle: POINTER
			l_string: detachable like last_string
		do
			shared_memory_handle := cwel_get_clipboard_data ({WEL_CLIPBOARD_CONSTANTS}.Cf_unicodetext)
			if shared_memory_handle /= default_pointer then
				create shared_string.make_from_handle (shared_memory_handle)
				shared_string.retrieve_string_discarding_carriage_return
				l_string := shared_string.last_string
			end
			if l_string = Void then
				create last_string.make_empty
			else
				last_string := l_string
			end
		ensure
			last_string_not_void: last_string /= Void
		end

	retrieve_clipboard_data (a_format: INTEGER)
			-- Retrieve the data of format `a_format' from the clipboard, as bytes, in `last_data'
			-- (Void if there is none).
		require
			clipboard_open: clipboard_open
		local
			l_handle, l_data: POINTER
			l_size: INTEGER
			l_unlocked: BOOLEAN
		do
			last_data := Void
			l_handle := cwel_get_clipboard_data (a_format)
			if l_handle /= default_pointer then
				l_size := cwel_global_size (l_handle)
				l_data := cwel_global_lock (l_handle)
				if l_data /= default_pointer then
					if l_size > 0 then
						create last_data.make_from_pointer (l_data, l_size)
					end
					l_unlocked := cwel_global_unlock (l_handle)
				end
			end
		end

	retrieve_clipboard_files
			-- Retrieve the files of the clipboard (copied in the explorer) in `last_files'.
		require
			clipboard_open: clipboard_open
			files_available: is_clipboard_format_available ({WEL_CLIPBOARD_CONSTANTS}.Cf_hdrop)
		local
			l_drop: POINTER
			i, n, l_count: INTEGER
			l_name: WEL_STRING
		do
			create last_files.make (0)
			l_drop := cwel_get_clipboard_data ({WEL_CLIPBOARD_CONSTANTS}.Cf_hdrop)
			if l_drop /= default_pointer then
				n := {WEL_API}.drag_query_file (l_drop, -1, default_pointer, 0)
				from
					create last_files.make (n)
				until
					i >= n
				loop
						-- (Without a buffer: the length of the name, without the final null character.)
					l_count := {WEL_API}.drag_query_file (l_drop, i, default_pointer, 0)
					if l_count > 0 then
						create l_name.make_empty (l_count + 1)
						l_count := {WEL_API}.drag_query_file (l_drop, i, l_name.item, l_count + 1)
						last_files.extend (create {PATH}.make_from_string (l_name.substring (1, l_count)))
					end
					i := i + 1
				end
			end
		end

	set_clipboard_text (a_text: READABLE_STRING_GENERAL)
			-- Assign `a_text' to the clipboard
		require
			clipboard_open: clipboard_open
			a_text_not_void: a_text /= Void
		local
			shared_string: WEL_SHARED_MEMORY_STRING
		do
			create shared_string.make_from_string (a_text)
			cwel_set_clipboard_data ({WEL_CLIPBOARD_CONSTANTS}.Cf_unicodetext, shared_string.handle)
		end

	set_clipboard_text_with_newline_conversion (a_text: READABLE_STRING_GENERAL)
			-- Assign `a_text' to the clipboard guaranteeing that all newline (linefeed) characters '%N'
			-- are prepended with a carriage return character '%R'.
		require
			clipboard_open: clipboard_open
			a_text_not_void: a_text /= Void
		local
			shared_string: WEL_SHARED_MEMORY_STRING
		do
			create shared_string.make_from_string_with_newline_conversion (a_text)
			cwel_set_clipboard_data ({WEL_CLIPBOARD_CONSTANTS}.Cf_unicodetext, shared_string.handle)
		end

	open_clipboard (window: detachable WEL_WINDOW)
			-- Open clipboard for `window'. If `Void',
			-- clipboard is opened to the current task.
		require
			window_exists: window /= Void implies window.exists
		do
			if window /= Void then
				clipboard_open := cwel_open_clipboard (window.item)
			else
				clipboard_open := cwel_open_clipboard (default_pointer)
			end
		end

	close_clipboard
			-- Close clipboard.
		require
			clipboard_open: clipboard_open
		local
			b_result: BOOLEAN
		do
			b_result := cwel_close_clipboard
			check
				clipboard_closed: b_result
			end
		end

	empty_clipboard
			-- Empty clipboard.
		require
			clipboard_open: clipboard_open
		local
			b_result: BOOLEAN
		do
			b_result := cwel_empty_clipboard
			check
				clipboard_emptied: b_result
			end
		end

feature {NONE} -- Externals

	cwel_empty_clipboard: BOOLEAN
		external
			"C signature (): BOOL use %"wel.h%""
		alias
			"EmptyClipboard"
		end

	cwel_open_clipboard (hwnd_owner: POINTER): BOOLEAN
			-- Opens the clipboard
			-- hwnd_owner is the handle to the window opening the clipboard
		external
			"C signature (HWND): BOOL use %"wel.h%""
		alias
			"OpenClipboard"
		end

	cwel_close_clipboard: BOOLEAN
			-- Closes the clipboard
		external
			"C signature (): BOOL use %"wel.h%""
		alias
			"CloseClipboard"
		end

	cwel_get_clipboard_data (format: INTEGER): POINTER
			-- Gets a shared memory handle which gives access to
			-- the data currently stored in the clipboard.
			-- Format is one of the constants in WEL_CLIPBOARD_CONSTANTS
		external
			"C signature (UINT): HANDLE use %"wel.h%""
		alias
			"GetClipboardData"
		end

	cwel_set_clipboard_data (format: INTEGER; text: POINTER)
			-- Format is one of the constants in WEL_CLIPBOARD_CONSTANTS
		external
			"C signature (UINT, HANDLE) use %"wel.h%""
		alias
			"SetClipboardData"
		end

	cwel_register_clipboard_format (a_name: POINTER): INTEGER
			-- Register the clipboard format named `a_name' (a wide C string).
		external
			"C inline use %"wel.h%""
		alias
			"return (EIF_INTEGER) RegisterClipboardFormat ((LPCTSTR) $a_name);"
		end

	cwel_global_size (a_handle: POINTER): INTEGER
		external
			"C inline use %"wel.h%""
		alias
			"return (EIF_INTEGER) GlobalSize ((HGLOBAL) $a_handle);"
		end

	cwel_global_lock (a_handle: POINTER): POINTER
		external
			"C inline use %"wel.h%""
		alias
			"return GlobalLock ((HGLOBAL) $a_handle);"
		end

	cwel_global_unlock (a_handle: POINTER): BOOLEAN
		external
			"C inline use %"wel.h%""
		alias
			"return (EIF_BOOLEAN) GlobalUnlock ((HGLOBAL) $a_handle);"
		end

	cwel_is_clipboard_format_available (format: INTEGER): BOOLEAN
			-- Determines whether the clipboard contains data in the specified format.
		external
			"C signature (UINT): BOOL use %"wel.h%""
		alias
			"IsClipboardFormatAvailable"
		end

note
	copyright:	"Copyright (c) 1984-2011, Eiffel Software and others"
	license:	"Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"




end -- class WEL_CLIPBOARD

