note
	description: "[
		Deferred base class for layout sizing constraints.
		Descendants specify exact cell size, percentages, ratios, bounds, or flex weights.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	CONSTRAINT

feature -- Status report

	is_fixed: BOOLEAN
			-- Is this an exact cell size constraint?
		do
			Result := False
		end

	is_percentage: BOOLEAN
			-- Is this a percentage of parent area constraint?
		do
			Result := False
		end

	is_ratio: BOOLEAN
			-- Is this a fractional ratio of parent area constraint?
		do
			Result := False
		end

	is_min: BOOLEAN
			-- Is this a minimum bound constraint?
		do
			Result := False
		end

	is_max: BOOLEAN
			-- Is this a maximum bound constraint?
		do
			Result := False
		end

	is_flex: BOOLEAN
			-- Is this a weighted flexible share constraint?
		do
			Result := False
		end

end
