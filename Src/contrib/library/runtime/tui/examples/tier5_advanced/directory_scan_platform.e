note
	description: "[
		What DIRECTORY_SCANNER needs to know about a file that `base' does not tell (P2 A1).
		All the platform code of the scan is here, behind three queries:

		  * `is_link': is an entry a symbolic link or a junction? FILE_INFO.is_symlink answers
		    on POSIX (lstat); on Windows it is always False, because `base' reads files with
		    `_wstat', which follows links, so the reparse tag is read with FindFirstFileW.
		  * `can_list': may a directory be listed? On POSIX, FILE_INFO's read and search
		    permissions for this process (root may list anything). On Windows, FindFirstFileW
		    on "dir\*": `base' lists a directory it may not open as an empty one, so the
		    listing cannot tell.
		  * `file_size': the size of a plain file in 64 bits (FILE_INFO.size is an INTEGER,
		    so a file of 4 GiB or more is wrong there): stat on POSIX,
		    GetFileAttributesExW on Windows.

		Inline C, with each platform's part under `#ifdef EIF_WINDOWS'. Safe on any thread.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	DIRECTORY_SCAN_PLATFORM

feature -- Status report

	is_link (a_path: PATH; a_info: FILE_INFO): BOOLEAN
			-- Is the entry `a_path`, whose information (not following links) is `a_info`, a
			-- symbolic link or a junction?
		local
			l_name: NATIVE_STRING
		do
			Result := a_info.is_symlink
			if not Result and {PLATFORM}.is_windows then
				create l_name.make (a_path.name)
				Result := c_is_windows_link (l_name.item)
			end
		end

	can_list (a_path: PATH; a_info: FILE_INFO): BOOLEAN
			-- May this process list the directory `a_path`, whose information is `a_info`?
		require
			directory: a_info.exists and then a_info.is_directory
		local
			l_name: NATIVE_STRING
		do
			if {PLATFORM}.is_windows then
				create l_name.make (a_path.name)
				Result := c_windows_can_list (l_name.item)
			else
				Result := a_info.is_readable and a_info.is_executable
			end
		end

feature -- Measurement

	file_size (a_path: PATH; a_info: FILE_INFO): INTEGER_64
			-- Size in bytes of the plain file `a_path`, whose information is `a_info`
		require
			plain: a_info.exists and then a_info.is_plain
		local
			l_name: NATIVE_STRING
		do
			create l_name.make (a_path.name)
			Result := c_file_size (l_name.item)
			if Result < 0 then
					-- Not readable as a whole: FILE_INFO's size, read as unsigned 32 bits
				if a_info.size >= 0 then
					Result := a_info.size
				else
					Result := a_info.size.to_natural_32.to_integer_64
				end
			end
		ensure
			not_negative: Result >= 0
		end

feature {NONE} -- Externals

	c_is_windows_link (a_name: POINTER): BOOLEAN
			-- Is the file named `a_name` (UTF-16) a reparse point tagged as a symbolic link or a
			-- junction (mount point)? Other reparse points, such as OneDrive placeholders and
			-- deduplicated files, are ordinary files and directories. False off Windows.
		external
			"C inline use %"eif_misc.h%""
		alias
			"[
				#ifdef EIF_WINDOWS
					WIN32_FIND_DATAW l_data;
					HANDLE l_handle = FindFirstFileW ((LPCWSTR) $a_name, &l_data);
					if (l_handle == INVALID_HANDLE_VALUE) {
						return EIF_FALSE;
					}
					FindClose (l_handle);
					return (EIF_BOOLEAN) ((l_data.dwFileAttributes & FILE_ATTRIBUTE_REPARSE_POINT) != 0 &&
						(l_data.dwReserved0 == IO_REPARSE_TAG_MOUNT_POINT || l_data.dwReserved0 == IO_REPARSE_TAG_SYMLINK));
				#else
					return EIF_FALSE;
				#endif
			]"
		end

	c_windows_can_list (a_name: POINTER): BOOLEAN
			-- Can the directory named `a_name` (UTF-16) be listed: does FindFirstFileW on
			-- "`a_name'\*" succeed, or find nothing? (Access denied, a path too long, or a
			-- directory gone is False.) False off Windows.
		external
			"C inline use %"eif_misc.h%", <stdlib.h>, <wchar.h>"
		alias
			"[
				#ifdef EIF_WINDOWS
					const wchar_t *l_name = (const wchar_t *) $a_name;
					size_t l_count = wcslen (l_name);
					wchar_t *l_pattern = (wchar_t *) malloc ((l_count + 3) * sizeof (wchar_t));
					WIN32_FIND_DATAW l_data;
					HANDLE l_handle;
					DWORD l_error;
					if (l_pattern == NULL) {
						return EIF_FALSE;
					}
					wcscpy (l_pattern, l_name);
					if (l_count > 0 && l_pattern [l_count - 1] != L'\\' && l_pattern [l_count - 1] != L'/') {
						l_pattern [l_count++] = L'\\';
					}
					l_pattern [l_count++] = L'*';
					l_pattern [l_count] = L'\0';
					l_handle = FindFirstFileW (l_pattern, &l_data);
					l_error = GetLastError ();
					free (l_pattern);
					if (l_handle == INVALID_HANDLE_VALUE) {
						return (EIF_BOOLEAN) (l_error == ERROR_FILE_NOT_FOUND);
					}
					FindClose (l_handle);
					return EIF_TRUE;
				#else
					return EIF_FALSE;
				#endif
			]"
		end

	c_file_size (a_name: POINTER): INTEGER_64
			-- Size of the file named `a_name` (UTF-16 on Windows, bytes elsewhere), or -1 when
			-- it cannot be read.
		external
			"C inline use %"eif_misc.h%", <sys/types.h>, <sys/stat.h>"
		alias
			"[
				#ifdef EIF_WINDOWS
					WIN32_FILE_ATTRIBUTE_DATA l_data;
					if (!GetFileAttributesExW ((LPCWSTR) $a_name, GetFileExInfoStandard, &l_data)) {
						return (EIF_INTEGER_64) -1;
					}
					return (EIF_INTEGER_64) ((((unsigned __int64) l_data.nFileSizeHigh) << 32) | l_data.nFileSizeLow);
				#else
					struct stat l_info;
					if (stat ((const char *) $a_name, &l_info) != 0) {
						return (EIF_INTEGER_64) -1;
					}
					return (EIF_INTEGER_64) l_info.st_size;
				#endif
			]"
		end

end
