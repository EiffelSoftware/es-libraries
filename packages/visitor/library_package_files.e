note
	description: "[
			Access to the package.iron files associated with libraries:
			- the package file of a directory, if any (cached),
			- the projects (ecf files) declared in the "project" section of a package file,
			- the package an ecf file belongs to (the closest package.iron in the parent directories),
			- the default library name for a project of a package.
		]"
	date: "$Date$"
	revision: "$Revision$"

class
	LIBRARY_PACKAGE_FILES

create
	make

feature {NONE} -- Initialization

	make
		do
			create package_files.make (10)
		end

feature -- Access

	package_file_name: STRING_32 = "package.iron"
			-- Name of the package file.

	package_file_in (a_dir: PATH): detachable IRON_PACKAGE_FILE
			-- Package file located in directory `a_dir', if any (and valid).
		local
			k: STRING_32
			fn: PATH
			ut: FILE_UTILITIES
			pf: IRON_PACKAGE_FILE
		do
			k := a_dir.canonical_path.name.as_lower
			if package_files.has_key (k) then
				Result := package_files.found_item
			else
				fn := a_dir.extended (package_file_name)
				if ut.file_path_exists (fn) then
					pf := (create {IRON_PACKAGE_FILE_FACTORY}).new_package_file (fn)
					if not pf.has_error then
						Result := pf
					end
				end
				package_files.force (Result, k)
			end
		end

	has_projects (a_package: IRON_PACKAGE_FILE): BOOLEAN
			-- Does `a_package' have a "project" section (with at least one project)?
		do
			Result := attached a_package.projects as l_projects and then not l_projects.is_empty
		end

	project_paths (a_dir: PATH; a_package: IRON_PACKAGE_FILE): ARRAYED_LIST [TUPLE [name: READABLE_STRING_GENERAL; path: PATH]]
			-- Existing ecf files declared in the "project" section of `a_package', located in `a_dir'.
		local
			ut: FILE_UTILITIES
			p: PATH
		do
			if attached a_package.projects as l_projects then
				create Result.make (l_projects.count)
				across
					l_projects as ic
				loop
					p := a_dir.extended_path (create {PATH}.make_from_string (ic.relative_iri)).canonical_path
					if ut.file_path_exists (p) then
						Result.force ([ic.name, p])
					end
				end
			else
				create Result.make (0)
			end
		end

	owner_package (a_ecf: PATH): detachable TUPLE [package: IRON_PACKAGE_FILE; project_name: detachable READABLE_STRING_GENERAL]
			-- Package that `a_ecf' belongs to, i.e the closest package.iron in the parent directories,
			-- and the name of the associated project, if `a_ecf' is declared in the "project" section.
		local
			d: detachable PATH
			i: INTEGER
			l_ecf: STRING_32
			l_project_name: detachable READABLE_STRING_GENERAL
		do
			from
				d := a_ecf.parent
				i := 1
			until
				Result /= Void or d = Void or i > max_parent_levels
			loop
				if attached package_file_in (d) as pf then
					l_ecf := a_ecf.canonical_path.name.as_lower
					l_project_name := Void
					across
						project_paths (d, pf) as ic
					until
						l_project_name /= Void
					loop
						if ic.path.name.as_lower.same_string (l_ecf) then
							l_project_name := ic.name
						end
					end
					Result := [pf, l_project_name]
				elseif attached d.parent as l_parent and then not l_parent.same_as (d) then
					d := l_parent
				else
					d := Void
				end
				i := i + 1
			end
		end

	max_parent_levels: INTEGER = 8
			-- Number of parent directories checked to find the package of an ecf file.

feature {NONE} -- Implementation

	package_files: STRING_TABLE [detachable IRON_PACKAGE_FILE]
			-- Parsed package files, indexed by (lower case) directory name.

feature -- Element change

	reset
			-- Forget the parsed package files.
		do
			package_files.wipe_out
		end

feature -- Conversion

	default_library_name (a_package_name, a_project_name: READABLE_STRING_GENERAL): STRING_32
			-- Default name for project `a_project_name' of package `a_package_name':
			-- "package_project", unless the project name already is, or starts with, the package name
			-- or the last segment of the package name (for instance "gobo" for package "ise_gobo").
			-- Characters that are not valid in a library name are replaced by '_'.
		local
			l_pkg, l_proj, l_last: STRING_32
			i: INTEGER
		do
			l_pkg := a_package_name.as_string_32.as_lower
			l_proj := a_project_name.as_string_32.as_lower
			i := l_pkg.last_index_of ('_', l_pkg.count)
			if i > 0 and i < l_pkg.count then
				l_last := l_pkg.substring (i + 1, l_pkg.count)
			else
				l_last := l_pkg
			end
			if
				l_pkg.is_empty or else
				l_proj.same_string (l_pkg) or else l_proj.starts_with (l_pkg + {STRING_32} "_") or else
				l_proj.same_string (l_last) or else l_proj.starts_with (l_last + {STRING_32} "_")
			then
				create Result.make_from_string_general (a_project_name)
			elseif l_proj.is_empty then
				create Result.make_from_string_general (a_package_name)
			else
				create Result.make_from_string_general (a_package_name)
				Result.append_character ('_')
				Result.append_string_general (a_project_name)
			end
			across
				Result as ic
			loop
				if not (ic.is_alpha_numeric or ic = '_') then
					Result [@ ic.target_index] := '_'
				end
			end
		end

note
	copyright: "Copyright (c) 1984-2026, Eiffel Software"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"
end
