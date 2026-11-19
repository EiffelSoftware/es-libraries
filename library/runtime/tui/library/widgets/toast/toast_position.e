note
	description: "[
		Where TUI_TOAST stacks its toasts in the area: one of the four corners, or centred on
		the top or the bottom edge. The first toast of the queue (the oldest shown) is next to
		that edge, and newer ones stack away from it (downwards from a top position, upwards
		from a bottom one).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TOAST_POSITION

feature -- Constants

	top_left: NATURAL_8 = 1
			-- Top-left corner.

	top_center: NATURAL_8 = 2
			-- Centred on the top edge.

	top_right: NATURAL_8 = 3
			-- Top-right corner.

	bottom_left: NATURAL_8 = 4
			-- Bottom-left corner.

	bottom_center: NATURAL_8 = 5
			-- Centred on the bottom edge.

	bottom_right: NATURAL_8 = 6
			-- Bottom-right corner.

feature -- Status report

	is_valid (a_position: NATURAL_8): BOOLEAN
			-- Is `a_position` a valid toast position?
		do
			Result := a_position >= top_left and a_position <= bottom_right
		ensure
			instance_free: class
		end

	is_top (a_position: NATURAL_8): BOOLEAN
			-- Does `a_position` stack from the top edge?
		require
			valid_position: is_valid (a_position)
		do
			Result := a_position <= top_right
		ensure
			instance_free: class
		end

	is_left (a_position: NATURAL_8): BOOLEAN
			-- Is `a_position` at the left edge?
		require
			valid_position: is_valid (a_position)
		do
			Result := a_position = top_left or a_position = bottom_left
		ensure
			instance_free: class
		end

	is_right (a_position: NATURAL_8): BOOLEAN
			-- Is `a_position` at the right edge?
		require
			valid_position: is_valid (a_position)
		do
			Result := a_position = top_right or a_position = bottom_right
		ensure
			instance_free: class
		end

end
