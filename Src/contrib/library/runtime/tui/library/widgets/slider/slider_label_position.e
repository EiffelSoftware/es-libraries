note
	description: "[
		Where TUI_SLIDER draws its value label: nowhere, `left` or `right`. A horizontal slider
		puts the label left or right of the track, on the same row. A vertical slider puts it
		on its own row: `left` above the track (before it, in reading order) and `right` below.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	SLIDER_LABEL_POSITION

feature -- Constants

	none: NATURAL_8 = 0
			-- No label.

	left: NATURAL_8 = 1
			-- Left of a horizontal track; above a vertical one.

	right: NATURAL_8 = 2
			-- Right of a horizontal track; below a vertical one.

feature -- Status report

	is_valid (a_position: NATURAL_8): BOOLEAN
			-- Is `a_position` a valid label position?
		do
			Result := a_position = none or a_position = left or a_position = right
		ensure
			instance_free: class
		end

end
