note
	description: "YAML mapping (collection of key-value pairs)."
	date: "$Date$"
	revision: "$Revision$"

class
	YAML_MAPPING

inherit
	YAML_VALUE
		redefine
			is_mapping,
			chained_item
		end

	TABLE_ITERABLE [YAML_VALUE, YAML_STRING]

create
	make_empty, make_with_capacity, make

feature {NONE} -- Initialization

	make_with_capacity (nb: INTEGER)
			-- Initialize with a capacity of `nb' items.
		do
			create items.make (nb)
			is_flow_style := False
		ensure
			empty: is_empty
			block_style: not is_flow_style
		end

	make_empty
			-- Initialize as empty object.
		do
			make_with_capacity (0)
		end

	make
			-- Initialize with default capacity.
		do
			make_with_capacity (10)
		end

feature -- Access

	items: HASH_TABLE [YAML_VALUE, YAML_STRING]

	count: INTEGER
			-- Number of key-value pairs.
		do
			Result := items.count
		ensure
			non_negative: Result >= 0
		end

	item alias "[]" (a_key: YAML_STRING): detachable YAML_VALUE
			-- Value associated with string key `a_key`, or Void if not found.
		require
			key_attached: a_key /= Void
		do
			Result := items [a_key]
		end

	string_item (a_key: YAML_STRING): detachable YAML_STRING
		do
			if attached {YAML_STRING} item (a_key) as s then
				Result := s
			end
		end

	integer_item (a_key: YAML_STRING): detachable YAML_INTEGER
		do
			if attached {YAML_INTEGER} item (a_key) as n then
				Result := n
			end
		end

	real_item (a_key: YAML_STRING): detachable YAML_REAL
		do
			if attached {YAML_REAL} item (a_key) as r then
				Result := r
			end
		end

	boolean_item (a_key: YAML_STRING): detachable YAML_BOOLEAN
		do
			if attached {YAML_BOOLEAN} item (a_key) as b then
				Result := b
			end
		end

	date_item (a_key: YAML_STRING): detachable YAML_DATE
		do
			if attached {YAML_DATE} item (a_key) as d then
				Result := d
			end
		end

	mapping_item (a_key: YAML_STRING): detachable YAML_MAPPING
		do
			if attached {YAML_MAPPING} item (a_key) as m then
				Result := m
			end
		end

	sequence_item (a_key: YAML_STRING): detachable YAML_SEQUENCE
		do
			if attached {YAML_SEQUENCE} item (a_key) as s then
				Result := s
			end
		end

	chained_item alias "/" (a_key: YAML_STRING): YAML_VALUE
			-- <Precursor>.
		do
			if attached item (a_key) as v then
				Result := v
			else
				Result := Precursor (a_key)
			end
		end

feature -- Access basic values

 	string_8_value (a_key: YAML_STRING): detachable READABLE_STRING_8
 		require
 			is_string_value: attached string_item (a_key)
 		do
 			if attached string_item (a_key) as s then
 				check s.value.is_valid_as_string_8 end
 				Result := s.value_as_string_8
 			end
 		end

 	string_32_value (a_key: YAML_STRING): detachable READABLE_STRING_32
 		require
 			is_string_value: attached string_item (a_key)
 		do
 			if attached string_item (a_key) as s then
 				Result := s.value
 			end
 		end

 	integer_32_value (a_key: YAML_STRING): INTEGER_32
		require
 			is_integer_32_value: attached integer_item (a_key) as yint and then yint.is_integer_32
 		do
 			if attached integer_item (a_key) as v then
 				Result := v.value_as_integer_32
 			end
 		end

 	integer_64_value (a_key: YAML_STRING): INTEGER_64
		require
 			is_integer_64_value: attached integer_item (a_key)
 		do
 			if attached integer_item (a_key) as v then
 				Result := v.value_as_integer_64
 			end
 		end

 	natural_32_value (a_key: YAML_STRING): NATURAL_32
		require
 			is_natural_32: attached integer_item (a_key) as yint and then yint.is_natural_32
 		do
 			if attached integer_item (a_key) as v then
 				Result := v.value_as_natural_32
 			end
 		end

 	natural_64_value (a_key: YAML_STRING): NATURAL_64
		require
 			is_natural_64: attached integer_item (a_key) as yint and then yint.is_natural_64
 		do
 			if attached integer_item (a_key) as v then
 				Result := v.value_as_natural_64
 			end
 		end

 	real_32_value (a_key: YAML_STRING): REAL_32
		require
 			is_real_32_value: attached real_item (a_key) as jnum and then jnum.is_real_32
 		do
 			if attached real_item (a_key) as v then
 				Result := v.value_as_real_32
 			end
 		end

 	real_64_value (a_key: YAML_STRING): REAL_64
		require
 			is_real_64_value: attached real_item (a_key)
 		do
 			if attached real_item (a_key) as v then
 				Result := v.value_as_real_64
 			end
 		end

 	boolean_value (a_key: YAML_STRING): BOOLEAN
		require
 			is_boolean_value: attached boolean_item (a_key)
 		do
 			if attached boolean_item (a_key) as b then
	 			Result := b.value
	 		else
	 			check is_boolean: False end
 			end
 		end

feature -- Status report

	is_mapping: BOOLEAN = True
			-- <Precursor>

	is_empty: BOOLEAN
			-- Is mapping empty?
		do
			Result := items.is_empty
		end

	has_key (a_key: YAML_STRING): BOOLEAN
			-- Does mapping contain string key `a_key`?
		require
			key_attached: a_key /= Void
		do
			Result := items.has_key (a_key)
		end

	is_flow_style: BOOLEAN
			-- Should this mapping be rendered in flow style (inline)?

feature -- Iteration

	new_cursor: TABLE_ITERATION_CURSOR [YAML_VALUE, YAML_STRING]
			-- Fresh cursor associated with current structure
		do
			Result := items.new_cursor
		end

feature -- Element change

	put (a_value: YAML_VALUE; a_key: YAML_STRING)
			-- Associate `a_value` with `a_key`.
			-- If key already exists, replace value.
		require
			key_attached: a_key /= Void
			value_attached: a_value /= Void
		do
			items.force (a_value, a_key)
		ensure
			has_key: has_key (a_key)
		end

	put_string (a_value: READABLE_STRING_GENERAL; a_key: YAML_STRING)
			-- Associate `a_value` with string key `a_key`.
		require
			key_attached: a_key /= Void
			value_attached: a_value /= Void
		do
			put (create {YAML_STRING}.make_plain (a_value), a_key)
		ensure
			has_key: has_key (a_key)
		end

	put_boolean (a_value: BOOLEAN; a_key: YAML_STRING)
			-- Associate `a_value` with string key `a_key`.
		require
			key_attached: a_key /= Void
		do
			put (create {YAML_BOOLEAN}.make (a_value), a_key)
		ensure
			has_key: has_key (a_key)
		end

	put_integer_64 (a_value: INTEGER_64; a_key: YAML_STRING)
			-- Associate `a_value` with string key `a_key`.
		require
			key_attached: a_key /= Void
		do
			put (create {YAML_INTEGER}.make_integer_64 (a_value), a_key)
		ensure
			has_key: has_key (a_key)
		end

	put_integer_32 (a_value: INTEGER_32; a_key: YAML_STRING)
			-- Associate `a_value` with string key `a_key`.
		require
			key_attached: a_key /= Void
		do
			put (create {YAML_INTEGER}.make_integer_32 (a_value), a_key)
		ensure
			has_key: has_key (a_key)
		end

	put_natural_32 (a_value: NATURAL_32; a_key: YAML_STRING)
			-- Associate `a_value` with string key `a_key`.
		require
			key_attached: a_key /= Void
		do
			put (create {YAML_INTEGER}.make_integer_64 (a_value.to_integer_64), a_key)
		ensure
			has_key: has_key (a_key)
		end

	put_real_64 (a_value: REAL_64; a_key: YAML_STRING)
			-- Associate `a_value` with string key `a_key`.
		require
			key_attached: a_key /= Void
		do
			put (create {YAML_REAL}.make_real_64 (a_value), a_key)
		ensure
			has_key: has_key (a_key)
		end

	put_real_32 (a_value: REAL_32; a_key: YAML_STRING)
			-- Associate `a_value` with string key `a_key`.
		require
			key_attached: a_key /= Void
		do
			put (create {YAML_REAL}.make_real_32 (a_value), a_key)
		ensure
			has_key: has_key (a_key)
		end

	remove (a_key: YAML_STRING)
			-- Remove entry with string key `a_key`.
		require
			key_attached: a_key /= Void
		do
			items.remove (a_key)
		ensure
			removed: not has_key (a_key)
		end

	wipe_out
			-- Remove all entries.
		do
			items.wipe_out
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

feature -- Internal		

	current_keys: ARRAY [YAML_STRING]
			-- Array containing actually used keys.
		do
			Result := items.current_keys
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
			i := 1
			across
				items as v
			loop
				if i > 1 then
					Result.append (", ")
				end
				Result.append ((@v.key).representation)
				Result.append (": ")
				Result.append (v.representation)
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
			i := 1
			across
				items as v
			loop
				Result.append ((@v.key).representation)
				Result.append (": ")
				Result.append (v.representation)
				Result.append_character ('%N')
				i := i + 1
			end
		end

invariant
	items_attached: items /= Void

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
