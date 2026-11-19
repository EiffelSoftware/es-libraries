note
	description: "[
		Direction constants for TUI_DIVIDER: a horizontal rule (one row) or a vertical rule
		(one column).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	DIVIDER_DIRECTION

feature -- Constants

	horizontal: NATURAL_8 = 1
			-- A rule along the top row of the area.

	vertical: NATURAL_8 = 2
			-- A rule down the left column of the area.

feature -- Status report

	is_valid (a_dir: NATURAL_8): BOOLEAN
			-- Is `a_dir` a valid divider direction?
		do
			Result := a_dir = horizontal or a_dir = vertical
		ensure
			instance_free: class
		end

end
