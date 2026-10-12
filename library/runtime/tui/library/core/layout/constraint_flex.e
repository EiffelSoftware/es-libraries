note
	description: "[
		Flexible weight constraint distributing available remaining space.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	CONSTRAINT_FLEX

inherit
	CONSTRAINT
		redefine
			is_flex
		end

create
	make

feature {NONE} -- Initialization

	make (a_weight: NATURAL_16)
			-- Initialize with flex weight `a_weight`.
		require
			positive_weight: a_weight > 0
		do
			weight := a_weight
		ensure
			weight_set: weight = a_weight
		end

feature -- Access

	weight: NATURAL_16
			-- Proportional share weight

feature -- Status report

	is_flex: BOOLEAN = True

invariant
	positive_weight: weight > 0

end
