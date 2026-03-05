note
	description: "YAML sequence (ordered collection of values)."
	date: "$Date$"
	revision: "$Revision$"

class
	YAML_SEQUENCE

inherit
	YAML_VALUE
		redefine
			is_sequence,
			chained_item
		end

	ITERABLE [YAML_VALUE]

create
	make_empty, make_with_capacity, make,
	make_from_string_list,
	make_from_numeric_list

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

	make_from_string_list (lst: ITERABLE [READABLE_STRING_GENERAL])
		do
			if attached {FINITE [READABLE_STRING_GENERAL]} lst as f then
				make_with_capacity (f.count)
			else
				make_empty
			end
			across
				lst as s
			loop
				extend_string (s)
			end
		end

	make_from_numeric_list (lst: ITERABLE [NUMERIC])
		do
			if attached {FINITE [NUMERIC]} lst as f then
				make_with_capacity (f.count)
			else
				make_empty
			end
			across
				lst as v
			loop
				extend_numeric (v)
			end
		end

feature -- Access

	items: ARRAYED_LIST [YAML_VALUE]
			-- Items in this sequence.

	count: INTEGER
			-- Number of items in sequence.
		do
			Result := items.count
		ensure
			non_negative: Result >= 0
		end

	i_th alias "[]" (i: INTEGER): YAML_VALUE
			-- Item at index `i`.
		require
			valid_index: i >= 1 and i <= count
		do
			Result := items [i]
		ensure
			result_attached: Result /= Void
		end

	first: YAML_VALUE
			-- First item.
		require
			not_empty: not is_empty
		do
			Result := items.first
		ensure
			result_attached: Result /= Void
		end

	last: YAML_VALUE
			-- Last item.
		require
			not_empty: not is_empty
		do
			Result := items.last
		ensure
			result_attached: Result /= Void
		end

	chained_item alias "/" (a_key: YAML_STRING): YAML_VALUE
			-- <Precursor>.
		do
			if a_key.value.is_integer then
				Result := i_th (a_key.value.to_integer)
			else
				Result := Precursor (a_key)
			end
		end

feature -- Status report

	is_sequence: BOOLEAN = True
			-- <Precursor>

	is_empty: BOOLEAN
			-- Is sequence empty?
		do
			Result := items.is_empty
		end

	is_flow_style: BOOLEAN
			-- Should this sequence be rendered in flow style (inline)?

feature -- Iteration

	new_cursor: ARRAYED_LIST_ITERATION_CURSOR [YAML_VALUE]
			-- Fresh cursor for iteration.
		do
			Result := items.new_cursor
		end

feature -- Element change

	extend (a_value: YAML_VALUE)
			-- Add `a_value` to end of sequence.
		require
			value_attached: a_value /= Void
		do
			items.extend (a_value)
		ensure
			one_more: count = old count + 1
			added: last = a_value
		end

	put_front (a_value: YAML_VALUE)
		require
			value_not_void: a_value /= Void
		do
			items.put_front (a_value)
		ensure
			one_more: count = old count + 1
			added: first = a_value
		end

	put (a_value: YAML_VALUE; i: INTEGER)
			-- Replace item at index `i` with `a_value`.
		require
			value_attached: a_value /= Void
			valid_index: i >= 1 and i <= count
		do
			items [i] := a_value
		ensure
			replaced: i_th (i) = a_value
		end

	remove (i: INTEGER)
			-- Remove item at index `i`.
		require
			valid_index: i >= 1 and i <= count
		do
			items.go_i_th (i)
			items.remove
		ensure
			one_less: count = old count - 1
		end

	prune_all (v: YAML_VALUE)
			-- Remove all occurrences of `v'.
		require
			v_not_void: v /= Void
		do
			items.prune_all (v)
		ensure
			not_has_new_value: not items.has (v)
		end

	wipe_out
			-- Remove all items.
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

feature -- Helpers

	extend_string (s: READABLE_STRING_GENERAL)
		do
			extend (create {YAML_STRING}.make (s))
		end

	extend_numeric (v: NUMERIC)
		do
			if attached {INTEGER_32_REF} v as i32 then
				extend_integer_32 (i32)
			elseif attached {INTEGER_64_REF} v as i64 then
				extend_integer_64 (i64)
			elseif attached {NATURAL_32_REF} v as n32 then
				extend_natural_32 (n32)
			elseif attached {NATURAL_64_REF} v as n64 then
				extend_natural_64 (n64)
			elseif attached {REAL_32_REF} v as r32 then
				extend_real_32 (r32)
			elseif attached {REAL_64_REF} v as r64 then
				extend_real_64 (r64)
			elseif attached {INTEGER_8_REF} v as i then
				extend_integer_32 (i.to_integer_32)
			elseif attached {INTEGER_16_REF} v as i then
				extend_integer_32 (i.to_integer_32)
			elseif attached {NATURAL_8_REF} v as n then
				extend_natural_32 (n.to_natural_32)
			elseif attached {NATURAL_16_REF} v as n then
				extend_natural_32 (n.to_natural_32)
			else
				check False end
				extend_integer_32 (0)
			end
		end

	extend_integer_32 (i: INTEGER_32)
		do
			extend (create {YAML_INTEGER}.make_integer_32 (i))
		end

	extend_integer_64 (i: INTEGER_64)
		do
			extend (create {YAML_INTEGER}.make_integer_64 (i))
		end

	extend_natural_32 (n: NATURAL_32)
		do
			extend (create {YAML_INTEGER}.make_integer_64 (n.to_integer_64))
		end

	extend_natural_64 (n: NATURAL_64)
		do
			extend (create {YAML_INTEGER}.make_integer_64 (n.to_integer_64))
		end

	extend_real_32 (r: REAL_32)
		do
			extend (create {YAML_REAL}.make_real_32 (r))
		end

	extend_real_64 (r: REAL_64)
		do
			extend (create {YAML_REAL}.make_real_64 (r))
		end

	extend_boolean (b: BOOLEAN)
		do
			extend (create {YAML_BOOLEAN}.make (b))
		end

	extend_null
		do
			extend (create {YAML_NULL})
		end


feature -- Visitor

	accept (a_visitor: YAML_VISITOR)
			-- <Precursor>
		do
			a_visitor.visit_sequence (Current)
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
			-- Flow style representation [item1, item2, ...].
		local
			first_item: BOOLEAN
		do
			create Result.make (50)
			Result.append_character ('[')
			first_item := True
			across items as ic loop
				if not first_item then
					Result.append (", ")
				end
				Result.append (ic.representation)
				first_item := False
			end
			Result.append_character (']')
		end

	block_representation: STRING_32
			-- Block style representation with dashes.
		do
			create Result.make (100)
			across items as ic loop
				Result.append ("- ")
				Result.append (ic.representation)
				Result.append_character ('%N')
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
