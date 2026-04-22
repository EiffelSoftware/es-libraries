note
	description: "[
			Partial list, but including the total_count of the initial list
		]"
	date: "$Date$"
	revision: "$Revision$"

class
	CMS_DATA_LIST [G]

inherit
	ARRAYED_LIST [G]

create
	make,
	make_partial

feature {NONE} -- Initialization

	make_partial (a_offset, a_count: INTEGER; a_total_count: INTEGER)
		do
			make (a_count)
			total_count := a_total_count
			offset := a_offset
		end

feature -- Access

	total_count: INTEGER

	offset: INTEGER

	remaining_count: INTEGER
		do
			Result := total_count - offset - count
		end

invariant

note
	copyright: "2011-2026, Jocelyn Fiat, Javier Velilla, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
end

