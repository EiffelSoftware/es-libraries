note
	description: "Iterator that traverses all nodes in a YAML value tree."
	date: "$Date$"
	revision: "$Revision$"

class
	YAML_ITERATOR

inherit
	YAML_VISITOR

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize iterator.
		do
		end

feature -- Visiting

	visit_document (a_doc: YAML_DOCUMENT)
			-- Visit mapping `a_mapping`.
		do
			if attached a_doc.root as v then
				v.accept (Current)
			end
		end

	visit_scalar (a_scalar: YAML_SCALAR)
			-- <Precursor>
		do
			-- Leaf node, nothing to traverse
		end

	visit_sequence (a_sequence: YAML_SEQUENCE)
			-- <Precursor>
		do
			across a_sequence as ic loop
				ic.accept (Current)
			end
		end

	visit_mapping (a_mapping: YAML_MAPPING)
			-- <Precursor>
		do
			across
				a_mapping as val
			loop
				(@val.key).accept (Current)
				val.accept (Current)
			end
		end

note
	copyright: "Copyright (c) 1984-2026, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"
end
