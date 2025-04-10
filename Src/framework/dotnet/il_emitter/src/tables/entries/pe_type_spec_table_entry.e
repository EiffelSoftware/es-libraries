note
	description: "Object representing theTypeSpe table"
	date: "$Date$"
	revision: "$Revision$"
	EIS: "name=TypeSpec", "src=https://www.ecma-international.org/wp-content/uploads/ECMA-335_6th_edition_june_2012.pdf#page=274&zoom=100,116,540", "protocol=uri"

class
	PE_TYPE_SPEC_TABLE_ENTRY

inherit
	PE_TABLE_ENTRY_BASE
		redefine
			same_as
		end

create
	make_with_data

feature {NONE} -- Initialization

	make_with_data (a_signature_index: NATURAL_32)
		do
			create signature_index.make_with_index (a_signature_index)
		end

feature -- Status

	same_as (e: like Current): BOOLEAN
			-- Is `e` same as `Current`?
			-- note: used to detect if an entry is already recorded.
			--| There shall be no duplicate rows, based upon Signature
		do
			Result := Precursor (e)
				or else (
					e.signature_index.is_equal (signature_index)
				)
		end

feature -- Access

	signature_index: PE_BLOB
			-- index into the Blob heap.

feature -- Operations

	table_index: NATURAL_32
		once
			Result := {PE_TABLES}.ttypespec
		end

	render (a_sizes: SPECIAL [NATURAL_32]; a_dest: ARRAY [NATURAL_8]): NATURAL_32
		do
			Result := signature_index.render (a_sizes, a_dest, 0)
		end

	rendering_size (a_sizes: SPECIAL [NATURAL_32]): NATURAL_32
		do
			Result := signature_index.rendering_size (a_sizes)
		end

note
	copyright: "Copyright (c) 1984-2025, Eiffel Software"
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
