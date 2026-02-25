note
	description: "Iteration cursor for YAML_MAPPING."
	date: "$Date$"
	revision: "$Revision$"

class
	YAML_MAPPING_CURSOR

inherit
	ITERATION_CURSOR [TUPLE [key: YAML_STRING; value: YAML_VALUE]]

create
	make

feature {NONE} -- Initialization

	make (a_mapping: YAML_MAPPING)
			-- Initialize cursor for `a_mapping`.
		require
			mapping_attached: a_mapping /= Void
		do
			mapping := a_mapping
			index := 1
		ensure
			mapping_set: mapping = a_mapping
			at_start: index = 1
		end

feature -- Access

	item: TUPLE [key: YAML_STRING; value: YAML_VALUE]
			-- Item at current position.
		do
			Result := [mapping.key_at (index), mapping.value_at_index (index)]
		end

feature -- Status report

	after: BOOLEAN
			-- Is cursor past last item?
		do
			Result := index > mapping.count
		end

feature -- Cursor movement

	forth
			-- Move to next item.
		do
			index := index + 1
		end

feature {NONE} -- Implementation

	mapping: YAML_MAPPING
			-- Mapping being iterated.

	index: INTEGER
			-- Current position.

invariant
	mapping_attached: mapping /= Void
	valid_index: index >= 1

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
