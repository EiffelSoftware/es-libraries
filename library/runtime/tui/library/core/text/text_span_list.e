note
	description: "[
		Read-only view of the spans of a TEXT_LINE.
		Spans are added through TEXT_LINE (`append_span`, `append_text`), which keeps every
		grapheme cluster inside one span; this view gives no way to change the list.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEXT_SPAN_LIST

inherit
	ITERABLE [TEXT_SPAN]

create {TEXT_LINE}
	make

feature {NONE} -- Initialization

	make (a_list: ARRAYED_LIST [TEXT_SPAN])
			-- View `a_list`.
		do
			list := a_list
		ensure
			list_set: list = a_list
		end

feature -- Access

	i_th alias "[]" (i: INTEGER): TEXT_SPAN
			-- Span at index `i`.
		require
			valid_index: valid_index (i)
		do
			Result := list.i_th (i)
		end

	first: TEXT_SPAN
			-- First span.
		require
			not_empty: not is_empty
		do
			Result := list.first
		end

	last: TEXT_SPAN
			-- Last span.
		require
			not_empty: not is_empty
		do
			Result := list.last
		end

	new_cursor: ITERATION_CURSOR [TEXT_SPAN]
			-- Fresh cursor over the spans, first to last.
		do
			Result := list.new_cursor
		end

feature -- Measurement

	count: INTEGER
			-- Number of spans.
		do
			Result := list.count
		ensure
			non_negative: Result >= 0
		end

feature -- Status report

	is_empty: BOOLEAN
			-- Are there no spans?
		do
			Result := list.is_empty
		ensure
			definition: Result = (count = 0)
		end

	valid_index (i: INTEGER): BOOLEAN
			-- Is `i` a valid span index?
		do
			Result := i >= 1 and i <= count
		ensure
			definition: Result = (i >= 1 and i <= count)
		end

feature {TEXT_LINE} -- Implementation

	list: ARRAYED_LIST [TEXT_SPAN]
			-- Viewed list, owned by the line.

invariant
	list_not_void: list /= Void

end
