note
	description: "[
		BSON_ARRAY represents an array in BSON.
		An array in BSON is a document where keys are sequential integer strings ('0', '1', '2', ...).
		
		Example: ['red', 'blue'] encodes as {'0': 'red', '1': 'blue'}
	]"
	date: "$Date$"
	revision: "$Revision$"
	EIS: "name=BSON Specification", "protocol=URI", "src=https://bsonspec.org/spec.html"

class
	BSON_ARRAY

inherit
	BSON_VALUE
		redefine
			is_array
		end

	BSON_CONSTANTS
		undefine
			is_equal
		end

	ITERABLE [BSON_VALUE]
		undefine
			is_equal
		end

	DEBUG_OUTPUT
		undefine
			is_equal
		end

create
	make,
	make_empty,
	make_from_string_list,
	make_from_integer_list

feature {NONE} -- Initialization

	make (nb: INTEGER)
			-- Initialize BSON array with capacity of `nb' items.
		do
			create items.make (nb)
		ensure
			items_created: items /= Void
		end

	make_empty
			-- Initialize empty BSON array.
		do
			make (0)
		ensure
			is_empty: is_empty
		end

	make_from_string_list (lst: ITERABLE [READABLE_STRING_GENERAL])
			-- Initialize from list of strings.
		do
			if attached {FINITE [READABLE_STRING_GENERAL]} lst as f then
				make (f.count)
			else
				make_empty
			end
			across lst as s loop
				extend_string (s)
			end
		end

	make_from_integer_list (lst: ITERABLE [INTEGER_64])
			-- Initialize from list of integers.
		do
			if attached {FINITE [INTEGER_64]} lst as f then
				make (f.count)
			else
				make_empty
			end
			across lst as v loop
				extend_int64 (v)
			end
		end

feature -- Status report

	is_array: BOOLEAN = True
			-- <Precursor>

feature -- Access

	bson_type: INTEGER_8
			-- <Precursor>
		do
			Result := bson_type_array
		end

	i_th alias "[]" (i: INTEGER): BSON_VALUE
			-- Item at `i'-th position (1-based).
		require
			is_valid_index: valid_index (i)
		do
			Result := items.i_th (i)
		end

feature -- Measurement

	count: INTEGER
			-- Number of items.
		do
			Result := items.count
		end

feature -- Status report

	is_empty: BOOLEAN
			-- Is structure empty?
		do
			Result := count = 0
		end

	valid_index (i: INTEGER): BOOLEAN
			-- Is `i' a valid index?
		do
			Result := (1 <= i) and (i <= count)
		end

feature -- Access

	new_cursor: ITERATION_CURSOR [BSON_VALUE]
			-- Fresh cursor associated with current structure.
		do
			Result := items.new_cursor
		end

feature -- Element change

	put_front (v: BSON_VALUE)
			-- Add `v' at front.
		require
			v_not_void: v /= Void
		do
			items.put_front (v)
		ensure
			has_new_value: old items.count + 1 = items.count and items.first = v
		end

	add,
	extend (v: BSON_VALUE)
			-- Add `v' at end.
		require
			v_not_void: v /= Void
		do
			items.extend (v)
		ensure
			has_new_value: old items.count + 1 = items.count and items.has (v)
		end

	prune_all (v: BSON_VALUE)
			-- Remove all occurrences of `v'.
		require
			v_not_void: v /= Void
		do
			items.prune_all (v)
		ensure
			not_has_value: not items.has (v)
		end

	wipe_out
			-- Remove all items.
		do
			items.wipe_out
		ensure
			is_empty: is_empty
		end

feature -- Helpers

	extend_string (s: READABLE_STRING_GENERAL)
			-- Extend with string value.
		do
			extend (create {BSON_STRING}.make_from_string_general (s))
		end

	extend_int32 (i: INTEGER_32)
			-- Extend with int32 value.
		do
			extend (create {BSON_INT32}.make (i))
		end

	extend_int64 (i: INTEGER_64)
			-- Extend with int64 value.
		do
			extend (create {BSON_INT64}.make (i))
		end

	extend_double (d: REAL_64)
			-- Extend with double value.
		do
			extend (create {BSON_DOUBLE}.make (d))
		end

	extend_boolean (b: BOOLEAN)
			-- Extend with boolean value.
		do
			extend (create {BSON_BOOLEAN}.make (b))
		end

	extend_null
			-- Extend with null value.
		do
			extend (create {BSON_NULL})
		end

feature -- Visitor pattern

	accept (a_visitor: BSON_VISITOR)
			-- Accept `a_visitor'.
		do
			a_visitor.visit_bson_array (Current)
		end

feature -- Conversion

	array_representation: ARRAYED_LIST [BSON_VALUE]
			-- Representation as a sequence of values.
			-- Warning: modifying the return object may impact the original BSON_ARRAY.
		do
			Result := items
		end

feature -- Report

	hash_code: INTEGER
			-- Hash code value.
		local
			l_started: BOOLEAN
		do
			across items as i loop
				if l_started then
					Result := ((Result \\ 8388593) |<< 8) + i.hash_code
				else
					Result := i.hash_code
					l_started := True
				end
			end
			if items.count > 0 then
				Result := Result \\ items.count
			end
		end

feature -- Status report

	debug_output: STRING
			-- String that should be displayed in debugger.
		do
			create Result.make (10)
			Result.append_integer (count)
			Result.append (" item")
			if count > 1 then
				Result.append_character ('s')
			end
		end

feature {NONE} -- Implementation

	items: ARRAYED_LIST [BSON_VALUE]
			-- Value container.

invariant
	items_not_void: items /= Void

note
	copyright: "2026, Jocelyn Fiat and Eiffel Software"
	license: "MIT License"
end
