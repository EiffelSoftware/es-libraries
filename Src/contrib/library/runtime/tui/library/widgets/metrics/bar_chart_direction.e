note
	description: "[
		Orientation direction constants for TUI_BARCHART (vertical or horizontal).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	BAR_CHART_DIRECTION

feature -- Constants

	vertical: NATURAL_8 = 1
			-- Vertical bars growing from bottom to top.

	horizontal: NATURAL_8 = 2
			-- Horizontal bars growing from left to right.

feature -- Status report

	is_valid (a_dir: NATURAL_8): BOOLEAN
			-- Is `a_dir` a valid direction?
		do
			Result := a_dir = vertical or a_dir = horizontal
		ensure
			instance_free: class
		end

end
