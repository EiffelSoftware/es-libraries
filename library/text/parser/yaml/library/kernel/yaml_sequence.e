note
	description: "YAML sequence (ordered collection of values)."
	date: "$Date$"
	revision: "$Revision$"

class
	YAML_SEQUENCE

inherit
	YAML_VALUE
		redefine
			is_sequence
		end

	ITERABLE [YAML_VALUE]

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize empty sequence.
		do
			create items.make (10)
			is_flow_style := False
		ensure
			empty: is_empty
			block_style: not is_flow_style
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

	item (i: INTEGER): YAML_VALUE
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
			added: item (count) = a_value
		end

	put (a_value: YAML_VALUE; i: INTEGER)
			-- Replace item at index `i` with `a_value`.
		require
			value_attached: a_value /= Void
			valid_index: i >= 1 and i <= count
		do
			items [i] := a_value
		ensure
			replaced: item (i) = a_value
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
