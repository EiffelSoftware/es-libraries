note
	description: "[
		A theme file read or to be written (review/p2_terminal_widgets_plan.md, Q1): its
		sections, in order. Read by TOML_SUBSET_READER, printed by TOML_SUBSET_WRITER.

		A section name appears at most once, as TOML requires. There are no keys outside a
		section. Equality is ordered (the same sections in the same order, each equal), so
		`read (write (d))` is equal to `d`.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TOML_SUBSET_DOCUMENT

inherit
	ANY
		redefine
			default_create,
			is_equal
		end

create
	default_create

feature {NONE} -- Initialization

	default_create
			-- An empty document.
		do
			create sections.make (12)
		ensure then
			is_empty: count = 0
		end

feature -- Access

	count: INTEGER
			-- Number of sections
		do
			Result := sections.count
		end

	section (i: INTEGER): TOML_SUBSET_SECTION
			-- The `i`-th section, in the order put
		require
			valid_index: 1 <= i and i <= count
		do
			Result := sections.i_th (i)
		end

	item alias "[]" (a_name: READABLE_STRING_GENERAL): detachable TOML_SUBSET_SECTION
			-- The section named `a_name`, or Void when there is none
		local
			i: INTEGER
		do
			from
				i := 1
			until
				Result /= Void or i > sections.count
			loop
				if sections.i_th (i).name.same_string_general (a_name) then
					Result := sections.i_th (i)
				end
				i := i + 1
			end
		ensure
			found: has_section (a_name) = (Result /= Void)
		end

feature -- Status report

	has_section (a_name: READABLE_STRING_GENERAL): BOOLEAN
			-- Is there a section named `a_name` (compared exactly)?
		do
			Result := across sections as l_section some l_section.name.same_string_general (a_name) end
		end

feature -- Element change

	put (a_section: TOML_SUBSET_SECTION)
			-- Add `a_section` after the existing sections.
		require
			new_name: not has_section (a_section.name)
		do
			sections.extend (a_section)
		ensure
			one_more: count = old count + 1
			last: section (count) = a_section
		end

	put_new (a_name: READABLE_STRING_GENERAL): TOML_SUBSET_SECTION
			-- Add an empty section named `a_name` after the existing sections, and return it.
		require
			valid_name: {TOML_SUBSET_SECTION}.is_valid_key (a_name)
			new_name: not has_section (a_name)
		do
			create Result.make (a_name)
			sections.extend (Result)
		ensure
			one_more: count = old count + 1
			last: section (count) = Result
			named: Result.name.same_string_general (a_name)
		end

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- The same sections in the same order, each equal
		local
			i: INTEGER
		do
			Result := count = a_other.count
			from
				i := 1
			until
				not Result or i > count
			loop
				Result := sections.i_th (i).is_equal (a_other.section (i))
				i := i + 1
			end
		end

feature {NONE} -- Implementation

	sections: ARRAYED_LIST [TOML_SUBSET_SECTION]
			-- The sections, in order

end
