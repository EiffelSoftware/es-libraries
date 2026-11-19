note
	description: "[
		A section of a theme file (review/p2_terminal_widgets_plan.md, Q1): a `[name]` header
		and its `key = value` lines, both kept in order. TOML calls it a table.

		Names and keys are TOML bare keys (`is_valid_key`): ASCII letters, digits, "_" and
		"-", at least one. A key appears at most once in a section, as TOML requires.
		Equality is ordered: the same name, and the same keys with equal values in the same
		order, so that the writer's output, which keeps the order, is equal after reading.
		A section read by TOML_SUBSET_READER also knows the line of its header (`line`) and of
		each key (`key_line`), so that a later check of the values (STYLE_TEXT, C2) can
		report where a key is; equality ignores them. A section made in code has line 0.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TOML_SUBSET_SECTION

inherit
	ANY
		redefine
			is_equal
		end

create
	make

feature {NONE} -- Initialization

	make (a_name: READABLE_STRING_GENERAL)
			-- An empty section named `a_name` (TOML: `[a_name]`).
		require
			valid_name: is_valid_key (a_name)
		do
			create name.make_from_string_general (a_name)
			create keys.make (8)
			create values.make (8)
			create key_lines.make (8)
		ensure
			name_set: name.same_string_general (a_name)
			is_empty: count = 0
		end

feature -- Access

	name: IMMUTABLE_STRING_32
			-- The section's name, as in its `[name]` header

	count: INTEGER
			-- Number of keys
		do
			Result := keys.count
		end

	key (i: INTEGER): IMMUTABLE_STRING_32
			-- The `i`-th key, in the order put
		require
			valid_index: 1 <= i and i <= count
		do
			Result := keys.i_th (i)
		end

	value (i: INTEGER): TOML_SUBSET_VALUE
			-- The value of the `i`-th key
		require
			valid_index: 1 <= i and i <= count
		do
			Result := values.i_th (i)
		end

	line: INTEGER
			-- Line of the `[name]` header when read (TOML_SUBSET_READER), 0 when made in code

	key_line (i: INTEGER): INTEGER
			-- Line of the `i`-th key when read, 0 when put in code
		require
			valid_index: 1 <= i and i <= count
		do
			Result := key_lines.i_th (i)
		ensure
			not_negative: Result >= 0
		end

	item alias "[]" (a_key: READABLE_STRING_GENERAL): detachable TOML_SUBSET_VALUE
			-- The value of `a_key`, or Void when the section has no such key
		local
			i: INTEGER
		do
			i := index_of (a_key)
			if i > 0 then
				Result := values.i_th (i)
			end
		ensure
			found: has_key (a_key) = (Result /= Void)
		end

feature -- Status report

	has_key (a_key: READABLE_STRING_GENERAL): BOOLEAN
			-- Does the section have `a_key` (compared exactly, as TOML keys are)?
		do
			Result := index_of (a_key) > 0
		end

	is_valid_key (a_text: READABLE_STRING_GENERAL): BOOLEAN
			-- Is `a_text` a TOML bare key: one or more of "A" .. "Z", "a" .. "z", "0" .. "9",
			-- "_" and "-" (TOML 1.0, "Keys")? Section names and keys are bare keys only; quoted
			-- and dotted keys are not in the subset.
		local
			i: INTEGER
			l_code: NATURAL_32
		do
			from
				Result := not a_text.is_empty
				i := 1
			until
				not Result or i > a_text.count
			loop
				l_code := a_text.code (i)
				Result := (l_code >= ('a').natural_32_code and l_code <= ('z').natural_32_code)
					or (l_code >= ('A').natural_32_code and l_code <= ('Z').natural_32_code)
					or (l_code >= ('0').natural_32_code and l_code <= ('9').natural_32_code)
					or l_code = ('_').natural_32_code or l_code = ('-').natural_32_code
				i := i + 1
			end
		ensure
			instance_free: class
		end

feature -- Element change

	put (a_key: READABLE_STRING_GENERAL; a_value: TOML_SUBSET_VALUE)
			-- Add `a_key` with `a_value` after the existing keys.
		require
			valid_key: is_valid_key (a_key)
			new_key: not has_key (a_key)
		do
			keys.extend (create {IMMUTABLE_STRING_32}.make_from_string_general (a_key))
			values.extend (a_value)
			key_lines.extend (0)
		ensure
			one_more: count = old count + 1
			last_key: key (count).same_string_general (a_key)
			last_value: value (count) = a_value
			no_line: key_line (count) = 0
		end

	put_string (a_key, a_text: READABLE_STRING_GENERAL)
			-- Add `a_key` with the string `a_text` (TOML: `a_key = "a_text"`).
		require
			valid_key: is_valid_key (a_key)
			new_key: not has_key (a_key)
			valid_text: {TOML_SUBSET_VALUE}.is_valid_text (a_text)
		do
			put (a_key, create {TOML_SUBSET_VALUE}.make_string (a_text))
		ensure
			one_more: count = old count + 1
			put: attached item (a_key) as l_value and then (l_value.is_string and l_value.string_value.same_string_general (a_text))
		end

	put_array (a_key: READABLE_STRING_GENERAL; a_items: ITERABLE [READABLE_STRING_GENERAL])
			-- Add `a_key` with the array of strings `a_items` (TOML: `a_key = ["a", "b"]`).
		require
			valid_key: is_valid_key (a_key)
			new_key: not has_key (a_key)
			valid_items: across a_items as l_item all {TOML_SUBSET_VALUE}.is_valid_text (l_item) end
		do
			put (a_key, create {TOML_SUBSET_VALUE}.make_array (a_items))
		ensure
			one_more: count = old count + 1
			put: attached item (a_key) as l_value and then l_value.is_array
		end

feature {TOML_SUBSET_READER} -- Element change (reading)

	set_line (a_line: INTEGER)
			-- Record that the header was read on line `a_line`.
		require
			valid_line: a_line >= 1
		do
			line := a_line
		ensure
			line_set: line = a_line
		end

	set_key_line (i, a_line: INTEGER)
			-- Record that the `i`-th key was read on line `a_line`.
		require
			valid_index: 1 <= i and i <= count
			valid_line: a_line >= 1
		do
			key_lines.put_i_th (a_line, i)
		ensure
			line_set: key_line (i) = a_line
		end

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Same name, and the same keys with equal values in the same order
		local
			i: INTEGER
		do
			Result := name.same_string (a_other.name) and count = a_other.count
			from
				i := 1
			until
				not Result or i > count
			loop
				Result := keys.i_th (i).same_string (a_other.key (i)) and values.i_th (i).is_equal (a_other.value (i))
				i := i + 1
			end
		end

feature {NONE} -- Implementation

	keys: ARRAYED_LIST [IMMUTABLE_STRING_32]
			-- The keys, in order

	values: ARRAYED_LIST [TOML_SUBSET_VALUE]
			-- The values, `values [i]` for `keys [i]`

	key_lines: ARRAYED_LIST [INTEGER]
			-- The lines the keys were read on, `key_lines [i]` for `keys [i]` (0: put in code)

	index_of (a_key: READABLE_STRING_GENERAL): INTEGER
			-- Index of `a_key` in `keys`, or 0
		local
			i: INTEGER
		do
			from
				i := 1
			until
				Result > 0 or i > keys.count
			loop
				if keys.i_th (i).same_string_general (a_key) then
					Result := i
				end
				i := i + 1
			end
		end

invariant
	valid_name: is_valid_key (name)
	one_value_per_key: keys.count = values.count
	one_line_per_key: keys.count = key_lines.count
	line_not_negative: line >= 0

end
