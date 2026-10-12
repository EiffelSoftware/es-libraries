note
	description: "Compare library search items by a text key (case insensitive), for a sortable column."
	date: "$Date$"
	revision: "$Revision$"

class
	LIBRARY_SEARCH_ITEM_COMPARATOR

inherit
	PART_COMPARATOR [ES_LIBRARY_PROVIDER_ITEM]

create
	make

feature {NONE} -- Initialization

	make (a_key: like key; a_ascending: BOOLEAN)
			-- Compare using the text returned by `a_key', in ascending order if `a_ascending'.
		do
			key := a_key
			is_ascending := a_ascending
		end

feature -- Access

	key: FUNCTION [ES_LIBRARY_PROVIDER_ITEM, READABLE_STRING_GENERAL]
			-- Text key of an item.

	is_ascending: BOOLEAN
			-- Ascending order?

feature -- Status report

	less_than (u, v: ES_LIBRARY_PROVIDER_ITEM): BOOLEAN
			-- Is `u' considered less than `v'?
		local
			ku, kv: STRING_32
		do
			ku := key.item ([u]).as_lower.to_string_32
			kv := key.item ([v]).as_lower.to_string_32
			if ku.same_string (kv) then
					-- Stable order on identifier.
				Result := u.identifier.as_lower.to_string_32 < v.identifier.as_lower.to_string_32
			elseif is_ascending then
				Result := ku < kv
			else
				Result := kv < ku
			end
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
