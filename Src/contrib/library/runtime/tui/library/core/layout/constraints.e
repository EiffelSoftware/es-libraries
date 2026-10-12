note
	description: "[
		Factory class providing convenient class features for creating CONSTRAINT instances.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	CONSTRAINTS

feature -- Factory functions (Class features)

	fixed (a_size: NATURAL_16): CONSTRAINT
			-- Exact cell size constraint
		do
			create {CONSTRAINT_FIXED} Result.make (a_size)
		ensure
			instance_free: class
			result_fixed: Result.is_fixed
		end

	percentage (a_percent: NATURAL_16): CONSTRAINT
			-- Percentage (0..100) of parent area constraint
		require
			valid_percentage: a_percent <= 100
		do
			create {CONSTRAINT_PERCENTAGE} Result.make (a_percent)
		ensure
			instance_free: class
			result_percentage: Result.is_percentage
		end

	ratio (a_num, a_den: NATURAL_32): CONSTRAINT
			-- Fractional share (`a_num` / `a_den`) of parent area constraint
		require
			positive_denominator: a_den > 0
			numerator_le_denominator: a_num <= a_den
		do
			create {CONSTRAINT_RATIO} Result.make (a_num, a_den)
		ensure
			instance_free: class
			result_ratio: Result.is_ratio
		end

	min_size (a_min: NATURAL_16): CONSTRAINT
			-- Minimum size constraint
		do
			create {CONSTRAINT_MIN} Result.make (a_min)
		ensure
			instance_free: class
			result_min: Result.is_min
		end

	max_size (a_max: NATURAL_16): CONSTRAINT
			-- Maximum size constraint
		do
			create {CONSTRAINT_MAX} Result.make (a_max)
		ensure
			instance_free: class
			result_max: Result.is_max
		end

	flex (a_weight: NATURAL_16): CONSTRAINT
			-- Weighted flexible share constraint (fills remaining space)
		require
			positive_weight: a_weight > 0
		do
			create {CONSTRAINT_FLEX} Result.make (a_weight)
		ensure
			instance_free: class
			result_flex: Result.is_flex
		end

end
