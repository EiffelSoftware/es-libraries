note
	description: "[
		A group of BAR_ITEMs for TUI_BARCHART, supporting an optional group label
		and group-level operations.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	BAR_GROUP

inherit
	ANY
		redefine
			copy,
			is_equal
		end

create
	make,
	make_with_label,
	make_with_bars

feature {NONE} -- Initialization

	make
			-- Initialize as an empty bar group.
		do
			create bars.make (4)
		ensure
			bars_empty: bars.is_empty
			no_label: label = Void
		end

	make_with_label (a_label: READABLE_STRING_GENERAL)
			-- Initialize with `a_label`.
		do
			make
			set_label (a_label)
		ensure
			label_set: attached label as l and then l.same_string_general (a_label)
		end

	make_with_bars (a_bars: ITERABLE [BAR_ITEM])
			-- Initialize with `a_bars`.
		do
			make
			set_bars (a_bars)
		end

feature -- Duplication

	copy (a_other: like Current)
			-- Copy `a_other` with its own copies of the bars.
		do
			if a_other /= Current then
				standard_copy (a_other)
				create bars.make (a_other.bars.count)
				across a_other.bars as b loop
					bars.extend (b.twin)
				end
				if attached a_other.label as l then
					label := l.twin
				end
			end
		end

	is_equal (a_other: like Current): BOOLEAN
			-- Are all settings the same and the bars equal?
		local
			l_other: like Current
		do
			if a_other = Current then
				Result := True
			elseif bars.count = a_other.bars.count
				and then across bars as b all b.is_equal (a_other.bars [@b.cursor_index]) end
				and then label ~ a_other.label
			then
				l_other := a_other.standard_twin
				l_other.share_bars (bars)
				l_other.share_label (label)
				Result := standard_is_equal (l_other)
			end
		end

feature {BAR_GROUP} -- Duplication

	share_bars (a_bars: like bars)
			-- Use `a_bars` as the list of bars (for `is_equal`).
		do
			bars := a_bars
		end

	share_label (a_label: like label)
			-- Use `a_label` as the label (for `is_equal`).
		do
			label := a_label
		end

feature -- Access

	label: detachable STRING_32
			-- Optional group label displayed beneath or alongside the bar group

	bars: ARRAYED_LIST [BAR_ITEM]
			-- Bar items in this group

	count: INTEGER
			-- Number of bars in this group
		do
			Result := bars.count
		ensure
			correct_count: Result = bars.count
		end

	is_empty: BOOLEAN
			-- Is group empty?
		do
			Result := bars.is_empty
		ensure
			definition: Result = (bars.count = 0)
		end

	max_value: NATURAL_64
			-- Maximum value among all bars in this group
		local
			m: NATURAL_64
		do
			m := 0
			across
				bars as b
			loop
				if b.value > m then
					m := b.value
				end
			end
			Result := m
		end

feature -- Element change

	append_bar (a_bar: BAR_ITEM)
			-- Add `a_bar` to group.
		do
			bars.extend (a_bar)
		ensure
			one_more: bars.count = old bars.count + 1
			last_bar: bars.last = a_bar
		end

	set_bars (a_bars: ITERABLE [BAR_ITEM])
			-- Replace bars with `a_bars`.
		do
			bars.wipe_out
			across
				a_bars as b
			loop
				bars.extend (b)
			end
		end

	set_label (a_label: detachable READABLE_STRING_GENERAL)
			-- Set or clear group label.
		do
			if attached a_label as l then
				create label.make_from_string_general (l)
			else
				label := Void
			end
		ensure
			label_set: attached a_label implies attached label
		end

feature -- Fluent Builders

	with_label (a_label: READABLE_STRING_GENERAL): like Current
			-- Group with label `a_label`.
		do
			Result := twin
			Result.set_label (a_label)
		ensure
			result_is_copy: Result /= Current
		end

	with_bars (a_bars: ITERABLE [BAR_ITEM]): like Current
			-- Group with `a_bars`.
		do
			Result := twin
			Result.set_bars (a_bars)
		ensure
			result_is_copy: Result /= Current
		end

invariant
	bars_not_void: bars /= Void

end
