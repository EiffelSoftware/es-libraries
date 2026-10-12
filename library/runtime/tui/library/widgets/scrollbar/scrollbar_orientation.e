note
	description: "[
		Orientation modes for TUI_SCROLLBAR: vertical left/right or horizontal top/bottom.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	SCROLLBAR_ORIENTATION

feature -- Constants

	vertical_right: NATURAL_8 = 1
			-- Positions scrollbar along the right edge, scrolling vertically

	vertical_left: NATURAL_8 = 2
			-- Positions scrollbar along the left edge, scrolling vertically

	horizontal_bottom: NATURAL_8 = 3
			-- Positions scrollbar along the bottom edge, scrolling horizontally

	horizontal_top: NATURAL_8 = 4
			-- Positions scrollbar along the top edge, scrolling horizontally

feature -- Status report

	is_vertical (a_val: NATURAL_8): BOOLEAN
			-- Is `a_val` a vertical scrollbar orientation?
		do
			Result := a_val = vertical_right or a_val = vertical_left
		ensure
			instance_free: class
		end

	is_horizontal (a_val: NATURAL_8): BOOLEAN
			-- Is `a_val` a horizontal scrollbar orientation?
		do
			Result := a_val = horizontal_bottom or a_val = horizontal_top
		ensure
			instance_free: class
		end

	is_valid (a_val: NATURAL_8): BOOLEAN
			-- Is `a_val` a valid scrollbar orientation constant?
		do
			Result := is_vertical (a_val) or is_horizontal (a_val)
		ensure
			instance_free: class
		end

end
