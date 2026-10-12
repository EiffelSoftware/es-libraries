note
	description: "[
		Minimum bound constraint ensuring at least a specified cell count.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	CONSTRAINT_MIN

inherit
	CONSTRAINT
		redefine
			is_min
		end

create
	make

feature {NONE} -- Initialization

	make (a_min: NATURAL_16)
			-- Initialize with minimum bound `a_min`.
		do
			min_value := a_min
		ensure
			min_set: min_value = a_min
		end

feature -- Access

	min_value: NATURAL_16
			-- Minimum cell size

feature -- Status report

	is_min: BOOLEAN = True

end
