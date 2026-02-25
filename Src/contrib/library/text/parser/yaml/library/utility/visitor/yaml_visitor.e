note
	description: "Abstract visitor for traversing YAML values."
	date: "$Date$"
	revision: "$Revision$"

deferred class
	YAML_VISITOR

feature -- Visiting

	visit_document (a_doc: YAML_DOCUMENT)
			-- Visit mapping `a_mapping`.
		require
			a_doc_attached: a_doc /= Void
		deferred
		end

	visit_scalar (a_scalar: YAML_SCALAR)
			-- Visit scalar value `a_scalar`.
		require
			scalar_attached: a_scalar /= Void
		deferred
		end

	visit_sequence (a_sequence: YAML_SEQUENCE)
			-- Visit sequence `a_sequence`.
		require
			sequence_attached: a_sequence /= Void
		deferred
		end

	visit_mapping (a_mapping: YAML_MAPPING)
			-- Visit mapping `a_mapping`.
		require
			mapping_attached: a_mapping /= Void
		deferred
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
