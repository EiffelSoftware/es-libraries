note
	description: "[
			Scanner of library configuration files (ecf files).
			When a directory contains a package.iron file:
			  - only the ecf files declared in its "project" section are considered,
			    or, without "project" section, only the ecf files located in that directory,
			  - the sub directories are only scanned for nested package.iron files.
		]"
	date: "$Date$"
	revision: "$Revision$"

class
	LIBRARY_ECF_SCANNER

inherit
	DIRECTORY_ITERATOR
		redefine
			directory_excluded,
			file_excluded,
			process_file,
			process_directory
		end

create
	make,
	make_with_depth

feature {NONE} -- Initialization

	make
		do
			max_depth := 0
			create items.make (0)
			create package_files.make
		end

	make_with_depth (a_max_depth: INTEGER)
			-- Visit with max depth `a_max_depth'
		require
			a_max_depth > 0
		do
			max_depth := a_max_depth
			create items.make (0)
			create package_files.make
		end

feature -- Access

	max_depth: INTEGER
			-- Max depth for recursion
			-- if <= 0: recursive
			-- else stop at `max_depth'

	items: ARRAYED_LIST [PATH]

	package_files: LIBRARY_PACKAGE_FILES
			-- Access to package.iron files.

feature {NONE} -- Implementation	

	depth: INTEGER

	is_in_package: BOOLEAN
			-- Is the current directory located inside a package directory?
			-- (then only nested package files are considered).

feature -- Reset

	reset
		do
			items.wipe_out
		end

feature -- Visitor

	process_directory (dn: PATH)
		local
			l_was_in_package: BOOLEAN
		do
			depth := depth + 1
			if max_depth <= 0 or else (depth <= max_depth) then
				if attached package_files.package_file_in (dn) as pf then
					if package_files.has_projects (pf) then
						across
							package_files.project_paths (dn, pf) as ic
						loop
							process_file (ic.path)
						end
					else
						process_files_of (dn)
					end
					l_was_in_package := is_in_package
					is_in_package := True
					process_sub_directories_of (dn)
					is_in_package := l_was_in_package
				elseif is_in_package then
						-- Only look for nested packages.
					process_sub_directories_of (dn)
				else
					Precursor (dn)
				end
			end
			depth := depth - 1
		end

	process_files_of (dn: PATH)
			-- Process the (non excluded) files of directory `dn', but not its sub directories.
		local
			d: DIRECTORY
			fp: PATH
			ut: FILE_UTILITIES
		do
			create d.make_with_path (dn)
			if d.is_readable then
				across
					d.entries as ic
				loop
					if not path_excluded (ic) and then not file_excluded (ic) then
						fp := dn.extended_path (ic)
						if ut.file_path_exists (fp) then
							process_file (fp)
						end
					end
				end
			end
		end

	process_sub_directories_of (dn: PATH)
			-- Process the (non excluded) sub directories of directory `dn', but not its files.
		local
			d: DIRECTORY
			fp: PATH
			ut: FILE_UTILITIES
		do
			create d.make_with_path (dn)
			if d.is_readable then
				across
					d.entries as ic
				loop
					if not path_excluded (ic) and then not directory_excluded (ic) then
						fp := dn.extended_path (ic)
						if ut.directory_path_exists (fp) then
							process_directory (fp)
						end
					end
				end
			end
		end

	process_file (fn: PATH)
			-- Visit file `fn'
		do
			if not items.there_exists (agent {PATH}.same_as (fn)) then
				items.force (fn)
			end
		end

feature -- Status

	directory_excluded (dn: PATH): BOOLEAN
			-- Is Directory `dn' excluded?
		local
			n: READABLE_STRING_32
		do
			Result := Precursor (dn)
			if not Result then
				if attached dn.entry as e then
					n := e.name
				else
					n := dn.name
				end
				Result := n.starts_with_general (".") or n.same_string_general ("EIFGENs")
			end
		end

	file_excluded (fn: PATH): BOOLEAN
			-- Is file `fn' excluded?
		do
			Result := True
			if attached fn.extension as l_ext then
				Result := not l_ext.is_case_insensitive_equal_general ("ecf")
			end
		end

note
	copyright: "Copyright (c) 1984-2013, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"
end
