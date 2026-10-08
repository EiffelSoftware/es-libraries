note
	date: "$Date$"
	revision: "$Revision$"

deferred class
	ES_LIBRARY_PROVIDER

feature -- Access

	identifier: STRING
			-- Provider identifier.
		deferred
		end

	description: detachable READABLE_STRING_32
			-- Optional description
		deferred
		end

	libraries (a_query: detachable READABLE_STRING_GENERAL; a_target: CONF_TARGET): LIST [ES_LIBRARY_PROVIDER_ITEM]
			-- Configuration system view objects indexed by location.
		deferred
		end

	updated_date (a_target: CONF_TARGET): detachable DATE_TIME
			-- Date of last update.
		deferred
		end

feature -- Status report

	is_strict: BOOLEAN
			-- Is the query matching strict?
			-- If False, a searched text is considered as "*text*".

feature -- Settings

	set_is_strict (b: BOOLEAN)
			-- Set `is_strict' to `b'.
		do
			is_strict := b
		ensure
			is_strict_set: is_strict = b
		end

feature -- Reset

	reset (a_target: CONF_TARGET)
		deferred
		end

	update (a_target: CONF_TARGET)
		do
			reset (a_target)
		end

feature {NONE} -- Implementation

	categories: ES_LIBRARY_CATEGORIES
			-- Library categories helper.
		once
			create Result
		end

	is_dotnet (a_target: CONF_TARGET): BOOLEAN
			-- Is dotnet?
		do
			Result := a_target.setting_msil_generation
		end

	real_directory_path (a_target: CONF_TARGET; a_path: READABLE_STRING_GENERAL): PATH
		local
			l_location: CONF_DIRECTORY_LOCATION
		do
			create l_location.make (a_path.as_string_32, a_target)
			Result := l_location.evaluated_path
		end

	conf_system_from (a_target: CONF_TARGET; a_path: READABLE_STRING_32; a_search_iron: BOOLEAN): detachable CONF_SYSTEM_VIEW
			-- Lib configuration from `a_path' path name.
		local
			fn: PATH
		do
			fn := real_directory_path (a_target, a_path)
			create Result.make (fn, a_path)
			if
				Result.has_library_target and then
				(not Result.is_redirection or else is_declared_in_package (fn))
			then
					-- Exclude redirection, unless it is declared in the "project" section of a package.iron file.
				if a_search_iron then
					apply_iron_package_information_to (fn, Result)
				end
				if categories.is_precompile_system_name (Result.system_name) then
					Result.set_info (categories.precompiled, "category")
				elseif
					Result.info ("category") = Void and then
					attached categories.category_from_path (fn) as l_category
				then
					Result.set_info (l_category, "category")
				end
			else
				Result := Void
			end
		ensure
			result_attached: attached Result implies Result.has_library_target
		end

	apply_iron_package_information_to (a_ecf_path: PATH; cfg: CONF_SYSTEM_VIEW)
			-- Apply to `cfg' the information of the package that `a_ecf_path' belongs to, if any:
			-- notes, title, description, as well as the package name ("package")
			-- and the associated project name ("project").
		do
			if attached package_files.owner_package (a_ecf_path) as o then
				if attached {IRON_PACKAGE_INFO_FILE} o.package as pfinfo then
					across
						pfinfo.notes as ic
					loop
						cfg.set_info (ic, @ ic.key)
					end
				end
				if attached o.package.title as pf_title then
					cfg.set_info (pf_title, "title")
				end
				if attached o.package.description as pf_desc then
					cfg.set_info (pf_desc, "description")
				end
				if attached o.package.package_name as l_package_name then
					cfg.set_info (l_package_name, "package")
				end
				if attached o.project_name as l_project_name then
					cfg.set_info (l_project_name.to_string_32, "project")
				end
			end
		end

	is_declared_in_package (a_ecf_path: PATH): BOOLEAN
			-- Is `a_ecf_path' declared in the "project" section of its package.iron file?
		do
			Result := attached package_files.owner_package (a_ecf_path) as o and then o.project_name /= Void
		end

	package_files: LIBRARY_PACKAGE_FILES
			-- Access to package.iron files.
		once ("OBJECT")
			create Result.make
		end

note
	copyright: "Copyright (c) 1984-2021, Eiffel Software"
	license: "GPL version 2 (see http://www.eiffel.com/licensing/gpl.txt)"
	licensing_options: "http://www.eiffel.com/licensing"
	copying: "[
			This file is part of Eiffel Software's Eiffel Development Environment.
			
			Eiffel Software's Eiffel Development Environment is free
			software; you can redistribute it and/or modify it under
			the terms of the GNU General Public License as published
			by the Free Software Foundation, version 2 of the License
			(available at the URL listed under "license" above).
			
			Eiffel Software's Eiffel Development Environment is
			distributed in the hope that it will be useful, but
			WITHOUT ANY WARRANTY; without even the implied warranty
			of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
			See the GNU General Public License for more details.
			
			You should have received a copy of the GNU General Public
			License along with Eiffel Software's Eiffel Development
			Environment; if not, write to the Free Software Foundation,
			Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
		]"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"
end
