note
	description: "[
			Categories of libraries and packages.
			The category is usually provided by the `category` note of the package.iron file (or of the iron package),
			otherwise it is deduced from the location of the library inside $ISE_LIBRARY.
			Only a few categories are predefined (official, contrib, precompiled),
			the others are discovered from the libraries and packages.
		]"
	date: "$Date$"
	revision: "$Revision$"

class
	ES_LIBRARY_CATEGORIES

inherit
	EIFFEL_LAYOUT
		export
			{NONE} all
			{ANY} is_eiffel_layout_defined
		end

feature -- Categories

	official: STRING_32 = "official"
			-- Official libraries.

	contrib: STRING_32 = "contrib"
			-- User contributions.

	prerelease: STRING_32 = "prerelease"
			-- Pre-release (unstable) libraries.

	precompiled: STRING_32 = "precompiled"
			-- Precompiled libraries (system name starting with "precomp_").

	predefined_categories: ARRAY [READABLE_STRING_32]
			-- Predefined categories.
		once
			Result := <<official, contrib, precompiled>>
		end

feature -- Query

	is_precompile_system_name (a_system_name: READABLE_STRING_GENERAL): BOOLEAN
			-- Is `a_system_name' the name of a precompiled library (i.e starting with "precomp_")?
		do
			Result := a_system_name.count > precomp_prefix.count and then
				a_system_name.substring (1, precomp_prefix.count).is_case_insensitive_equal (precomp_prefix)
		end

	precomp_prefix: STRING_32 = "precomp_"
			-- Prefix of system name of precompiled libraries.

	category_from_path (a_path: PATH): detachable STRING_32
			-- Category deduced from the location `a_path' of a library (or package) inside $ISE_LIBRARY, if any.
		do
			if is_eiffel_layout_defined then
				Result := category_from_path_in (a_path, eiffel_layout.eiffel_library)
			end
		end

	category_from_path_in (a_path: PATH; a_library_root: PATH): detachable STRING_32
			-- Category deduced from the location `a_path' of a library (or package) inside `a_library_root'
			-- (i.e the $ISE_LIBRARY directory), if any.
		local
			s, l_root: STRING_32
		do
			s := normalized_path_name (a_path, a_library_root)
			l_root := normalized_path_name (a_library_root, a_library_root)
			if l_root.is_empty or else l_root [l_root.count] /= '/' then
				l_root.append_character ('/')
			end
			if s.starts_with (l_root) then
				s.remove_head (l_root.count)
				if s.starts_with ({STRING_32} "library/") or s.starts_with ({STRING_32} "c_library/") then
					Result := official
				elseif s.starts_with ({STRING_32} "contrib/library/") then
					Result := contrib
				elseif s.starts_with ({STRING_32} "unstable/library/") then
					Result := prerelease
				end
			end
		end

feature {NONE} -- Implementation

	normalized_path_name (p: PATH; a_library_root: PATH): STRING_32
			-- Lower case name of canonical path `p', using '/' as separator.
			-- Note: a leading $ISE_LIBRARY variable is expanded as `a_library_root'.
		local
			l_path: PATH
			s: STRING_32
		do
			l_path := p
			s := p.name
			across
				<<{STRING_32} "$ISE_LIBRARY", {STRING_32} "${ISE_LIBRARY}">> as v
			loop
				if
					s.count > v.count and then
					s.substring (1, v.count).is_case_insensitive_equal (v) and then
					(s [v.count + 1] = '/' or s [v.count + 1] = '\')
				then
					l_path := a_library_root.extended (s.substring (v.count + 2, s.count))
				end
			end
			create Result.make_from_string (l_path.absolute_path.canonical_path.name)
			Result.replace_substring_all ({STRING_32} "\", {STRING_32} "/")
			Result.to_lower
		end

note
	copyright: "Copyright (c) 1984-2026, Eiffel Software"
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
