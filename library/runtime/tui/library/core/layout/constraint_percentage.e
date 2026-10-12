note
	description: "[
		Percentage constraint allocating a proportion (0..100) of parent space.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	CONSTRAINT_PERCENTAGE

inherit
	CONSTRAINT
		redefine
			is_percentage
		end

create
	make

feature {NONE} -- Initialization

	make (a_percent: NATURAL_16)
			-- Initialize with percentage `a_percent` (0..100).
		require
			valid_percentage: a_percent <= 100
		do
			percent_value := a_percent
		ensure
			percentage_set: percent_value = a_percent
		end

feature -- Access

	percent_value: NATURAL_16
			-- Percentage share of parent area

feature -- Status report

	is_percentage: BOOLEAN = True

invariant
	valid_percentage: percent_value <= 100

end
