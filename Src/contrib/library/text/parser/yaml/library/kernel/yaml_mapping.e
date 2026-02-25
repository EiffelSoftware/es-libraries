note
	description: "YAML mapping (collection of key-value pairs)."
	date: "$Date$"
	revision: "$Revision$"

class
	YAML_MAPPING

inherit
	YAML_VALUE
		redefine
			is_mapping
		end

	ITERABLE [TUPLE [key: YAML_STRING; value: YAML_VALUE]]

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize empty mapping.
		do
			create keys.make (10)
			create values.make (10)
			is_flow_style := False
		ensure
			empty: is_empty
			block_style: not is_flow_style
		end

feature -- Access

	keys: ARRAYED_LIST [YAML_STRING]
			-- Keys in this mapping (preserving order).

	values: ARRAYED_LIST [YAML_VALUE]
			-- Values in this mapping (preserving order).

	count: INTEGER
			-- Number of key-value pairs.
		do
			Result := keys.count
		ensure
			non_negative: Result >= 0
		end

	value_at alias "[]" (a_key: YAML_STRING): detachable YAML_VALUE
			-- Value associated with string key `a_key`, or Void if not found.
		require
			key_attached: a_key /= Void
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > keys.count or Result /= Void
			loop
				if attached keys [i] as k then
					if a_key.value.same_string (k.value) then
						Result := values [i]
					end
				end
				i := i + 1
			end
		end

	key_at (i: INTEGER): YAML_STRING
			-- Key at index `i`.
		require
			valid_index: i >= 1 and i <= count
		do
			Result := keys [i]
		ensure
			result_attached: Result /= Void
		end

	value_at_index (i: INTEGER): YAML_VALUE
			-- Value at index `i`.
		require
			valid_index: i >= 1 and i <= count
		do
			Result := values [i]
		ensure
			result_attached: Result /= Void
		end

feature -- Status report

	is_mapping: BOOLEAN = True
			-- <Precursor>

	is_empty: BOOLEAN
			-- Is mapping empty?
		do
			Result := keys.is_empty
		end

	has_key (a_key: YAML_STRING): BOOLEAN
			-- Does mapping contain string key `a_key`?
		require
			key_attached: a_key /= Void
		do
			Result := value_at (a_key) /= Void
		end

	is_flow_style: BOOLEAN
			-- Should this mapping be rendered in flow style (inline)?

feature -- Iteration

	new_cursor: YAML_MAPPING_CURSOR
			-- Fresh cursor for iteration.
		do
			create Result.make (Current)
		end

feature -- Element change

	put (a_value: YAML_VALUE; a_key: YAML_STRING)
			-- Associate `a_value` with `a_key`.
			-- If key already exists, replace value.
		require
			key_attached: a_key /= Void
			value_attached: a_value /= Void
		local
			i: INTEGER
			found: BOOLEAN
		do
			from
				i := 1
			until
				i > keys.count or found
			loop
				if attached keys [i] as existing_key then
					if existing_key.value.same_string (a_key.value) then
						values [i] := a_value
						found := True
					end
				end
				i := i + 1
			end
			if not found then
				keys.extend (a_key)
				values.extend (a_value)
			end
		ensure
			has_key: has_key (a_key)
		end

	put_string (a_value: READABLE_STRING_GENERAL; a_key: YAML_STRING)
			-- Associate `a_value` with string key `a_key`.
		require
			key_attached: a_key /= Void
			value_attached: a_value /= Void
		do
			put (create {YAML_STRING}.make_string (a_value), a_key)
		ensure
			has_key: has_key (a_key)
		end

	remove (a_key: YAML_STRING)
			-- Remove entry with string key `a_key`.
		require
			key_attached: a_key /= Void
		local
			i: INTEGER
			found: BOOLEAN
		do
			from
				i := 1
			until
				i > keys.count or found
			loop
				if attached keys [i] as k then
					if k.value.same_string (a_key.value) then
						keys.go_i_th (i)
						keys.remove
						values.go_i_th (i)
						values.remove
						found := True
					end
				end
				i := i + 1
			end
		ensure
			removed: not has_key (a_key)
		end

	wipe_out
			-- Remove all entries.
		do
			keys.wipe_out
			values.wipe_out
		ensure
			empty: is_empty
		end

	set_flow_style (a_value: BOOLEAN)
			-- Set `is_flow_style` to `a_value`.
		do
			is_flow_style := a_value
		ensure
			flow_style_set: is_flow_style = a_value
		end

feature -- Visitor

	accept (a_visitor: YAML_VISITOR)
			-- <Precursor>
		do
			a_visitor.visit_mapping (Current)
		end

feature -- Output

	representation: STRING_32
			-- <Precursor>
		do
			if is_flow_style then
				Result := flow_representation
			else
				Result := block_representation
			end
		end

feature {NONE} -- Implementation

	flow_representation: STRING_32
			-- Flow style representation {key1: value1, key2: value2, ...}.
		local
			i: INTEGER
		do
			create Result.make (100)
			Result.append_character ('{')
			from
				i := 1
			until
				i > keys.count
			loop
				if i > 1 then
					Result.append (", ")
				end
				Result.append (keys [i].representation)
				Result.append (": ")
				Result.append (values [i].representation)
				i := i + 1
			end
			Result.append_character ('}')
		end

	block_representation: STRING_32
			-- Block style representation.
		local
			i: INTEGER
		do
			create Result.make (200)
			from
				i := 1
			until
				i > keys.count
			loop
				Result.append (keys [i].representation)
				Result.append (": ")
				Result.append (values [i].representation)
				Result.append_character ('%N')
				i := i + 1
			end
		end

invariant
	keys_attached: keys /= Void
	values_attached: values /= Void
	same_count: keys.count = values.count

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
