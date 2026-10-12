note
	description: "[
		Border flag bitmask definitions and queries for box drawing.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	BORDERS

feature -- Constants

	none: NATURAL_8 = 0
			-- No borders.

	top: NATURAL_8 = 1
			-- Top horizontal border.

	right: NATURAL_8 = 2
			-- Right vertical border.

	bottom: NATURAL_8 = 4
			-- Bottom horizontal border.

	left: NATURAL_8 = 8
			-- Left vertical border.

	all_borders: NATURAL_8 = 15
			-- All four borders (top | right | bottom | left).

feature -- Status report

	has_top (a_borders: NATURAL_8): BOOLEAN
			-- Does `a_borders` include the top edge?
		do
			Result := (a_borders.bit_and (top)) /= 0
		ensure
			instance_free: class
		end

	has_right (a_borders: NATURAL_8): BOOLEAN
			-- Does `a_borders` include the right edge?
		do
			Result := (a_borders.bit_and (right)) /= 0
		ensure
			instance_free: class
		end

	has_bottom (a_borders: NATURAL_8): BOOLEAN
			-- Does `a_borders` include the bottom edge?
		do
			Result := (a_borders.bit_and (bottom)) /= 0
		ensure
			instance_free: class
		end

	has_left (a_borders: NATURAL_8): BOOLEAN
			-- Does `a_borders` include the left edge?
		do
			Result := (a_borders.bit_and (left)) /= 0
		ensure
			instance_free: class
		end

	is_valid (a_borders: NATURAL_8): BOOLEAN
			-- Is `a_borders` a valid combination of border flags?
		do
			Result := a_borders <= all_borders
		ensure
			instance_free: class
		end

end
