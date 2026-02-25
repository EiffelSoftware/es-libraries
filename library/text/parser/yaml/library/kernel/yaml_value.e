note
	description: "Abstract base class for all YAML value types."
	date: "$Date$"
	revision: "$Revision$"

deferred class
	YAML_VALUE

feature -- Access

	tag: detachable STRING_32
			-- Optional tag associated with this value.

	anchor: detachable STRING_32
			-- Optional anchor name for this value.

feature -- Status report

	is_scalar: BOOLEAN
			-- Is this value a scalar?
		do
			Result := False
		end

	is_sequence: BOOLEAN
			-- Is this value a sequence?
		do
			Result := False
		end

	is_mapping: BOOLEAN
			-- Is this value a mapping?
		do
			Result := False
		end

	is_null: BOOLEAN
			-- Is this value null?
		do
			Result := False
		end

	is_boolean: BOOLEAN
			-- Is this value a boolean?
		do
			Result := False
		end

	is_integer: BOOLEAN
			-- Is this value an integer?
		do
			Result := False
		end

	is_real: BOOLEAN
			-- Is this value a real number?
		do
			Result := False
		end

	is_string: BOOLEAN
			-- Is this value a string?
		do
			Result := False
		end

feature -- Conversion

	as_scalar: YAML_SCALAR
			-- This value as a scalar.
		require
			is_scalar: is_scalar
		do
			check attached {YAML_SCALAR} Current as s then
				Result := s
			end
		ensure
			result_attached: Result /= Void
		end

	as_sequence: YAML_SEQUENCE
			-- This value as a sequence.
		require
			is_sequence: is_sequence
		do
			check attached {YAML_SEQUENCE} Current as s then
				Result := s
			end
		ensure
			result_attached: Result /= Void
		end

	as_mapping: YAML_MAPPING
			-- This value as a mapping.
		require
			is_mapping: is_mapping
		do
			check attached {YAML_MAPPING} Current as m then
				Result := m
			end
		ensure
			result_attached: Result /= Void
		end

feature -- Element change

	set_tag (a_tag: like tag)
			-- Set `tag` to `a_tag`.
		do
			tag := a_tag
		ensure
			tag_set: tag = a_tag
		end

	set_anchor (a_anchor: like anchor)
			-- Set `anchor` to `a_anchor`.
		do
			anchor := a_anchor
		ensure
			anchor_set: anchor = a_anchor
		end

feature -- Visitor

	accept (a_visitor: YAML_VISITOR)
			-- Accept `a_visitor` for processing.
		require
			visitor_attached: a_visitor /= Void
		deferred
		end

feature -- Output

	representation: STRING_32
			-- String representation of this YAML value.
		deferred
		ensure
			result_attached: Result /= Void
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
