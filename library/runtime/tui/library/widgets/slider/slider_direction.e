note
	description: "[
		Direction constants for TUI_SLIDER: a horizontal track (one row, `minimum` at the
		left) or a vertical track (one column, `minimum` at the bottom).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	SLIDER_DIRECTION

feature -- Constants

	horizontal: NATURAL_8 = 1
			-- A track along the top row of the area, `minimum` at the left.

	vertical: NATURAL_8 = 2
			-- A track down the left column of the area, `minimum` at the bottom.

feature -- Status report

	is_valid (a_dir: NATURAL_8): BOOLEAN
			-- Is `a_dir` a valid slider direction?
		do
			Result := a_dir = horizontal or a_dir = vertical
		ensure
			instance_free: class
		end

end
