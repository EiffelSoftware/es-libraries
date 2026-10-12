note
	description: "[
		Ratio constraint allocating a fractional share (numerator / denominator) of parent space.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	CONSTRAINT_RATIO

inherit
	CONSTRAINT
		redefine
			is_ratio
		end

create
	make

feature {NONE} -- Initialization

	make (a_num, a_den: NATURAL_32)
			-- Initialize with numerator `a_num` and denominator `a_den`.
		require
			positive_denominator: a_den > 0
			numerator_le_denominator: a_num <= a_den
		do
			numerator := a_num
			denominator := a_den
		ensure
			numerator_set: numerator = a_num
			denominator_set: denominator = a_den
		end

feature -- Access

	numerator: NATURAL_32
			-- Numerator of ratio

	denominator: NATURAL_32
			-- Denominator of ratio

feature -- Status report

	is_ratio: BOOLEAN = True

invariant
	positive_denominator: denominator > 0
	numerator_le_denominator: numerator <= denominator

end
