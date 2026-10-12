note
	description: "[
		Horizontal text alignment constants and validation.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEXT_ALIGNMENT

feature -- Constants

	left: NATURAL_8 = 0
			-- Align text to the left boundary.

	center: NATURAL_8 = 1
			-- Center text horizontally within the available area.

	right: NATURAL_8 = 2
			-- Align text to the right boundary.

feature -- Status report

	is_valid (a_align: NATURAL_8): BOOLEAN
			-- Is `a_align` a supported alignment constant?
		do
			Result := a_align = left or a_align = center or a_align = right
		ensure
			instance_free: class
		end

end
