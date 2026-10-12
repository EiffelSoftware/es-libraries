note
	description: "[
		Fixed cell count constraint allocating an exact number of cells.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	CONSTRAINT_FIXED

inherit
	CONSTRAINT
		redefine
			is_fixed
		end

create
	make

feature {NONE} -- Initialization

	make (a_value: NATURAL_16)
			-- Initialize with exact cell count `a_value`.
		do
			value := a_value
		ensure
			value_set: value = a_value
		end

feature -- Access

	value: NATURAL_16
			-- Fixed cell dimension

feature -- Status report

	is_fixed: BOOLEAN = True

end
