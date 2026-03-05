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

	chained_item alias "/" (a_key: YAML_STRING): YAML_VALUE
			-- Item associated with key `a_key` if exists.
			-- Note: if item does not exists, return also JSON_NULL.
		do
			create {YAML_NULL} Result
		end

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

feature -- Status report

	same_string (a_string: READABLE_STRING_GENERAL): BOOLEAN
			-- Current value is a string value, and same content as `a_string`?
		do
				-- To redefined in descendants.
		end

	same_caseless_string (a_string: READABLE_STRING_GENERAL): BOOLEAN
			-- Current value is a string value, and same caseless content as `a_string`?	
		do
				-- To redefined in descendants.
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
