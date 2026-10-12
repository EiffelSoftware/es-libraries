note
	description: "[
		Maximum bound constraint capping size at a specified cell count.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	CONSTRAINT_MAX

inherit
	CONSTRAINT
		redefine
			is_max
		end

create
	make

feature {NONE} -- Initialization

	make (a_max: NATURAL_16)
			-- Initialize with maximum bound `a_max`.
		do
			max_value := a_max
		ensure
			max_set: max_value = a_max
		end

feature -- Access

	max_value: NATURAL_16
			-- Maximum cell size

feature -- Status report

	is_max: BOOLEAN = True

end
