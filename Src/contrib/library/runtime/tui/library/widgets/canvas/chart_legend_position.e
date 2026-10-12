note
	description: "[
		Legend placement positions for TUI_CHART.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	CHART_LEGEND_POSITION

feature -- Constants

	top_right: NATURAL_8 = 1
			-- Legend placed in top-right corner.

	top_left: NATURAL_8 = 2
			-- Legend placed in top-left corner.

	bottom_right: NATURAL_8 = 3
			-- Legend placed in bottom-right corner.

	bottom_left: NATURAL_8 = 4
			-- Legend placed in bottom-left corner.

feature -- Status report

	is_valid (a_pos: NATURAL_8): BOOLEAN
			-- Is `a_pos` a recognized legend position?
		do
			Result := a_pos >= top_right and a_pos <= bottom_left
		ensure
			instance_free: class
		end

end
