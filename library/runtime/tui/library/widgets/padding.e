note
	description: "[
		Four-sided padding (top, right, bottom, left) in terminal characters.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	PADDING

inherit
	ANY
		redefine
			default_create
		end

create
	default_create,
	make,
	make_all,
	make_symmetric

feature {NONE} -- Initialization

	default_create
			-- Initialize with zero padding on all sides.
		do
			top := 0
			right := 0
			bottom := 0
			left := 0
		ensure then
			top_zero: top = 0
			right_zero: right = 0
			bottom_zero: bottom = 0
			left_zero: left = 0
		end

	make (a_top, a_right, a_bottom, a_left: NATURAL_16)
			-- Initialize with independent four-sided padding.
		do
			top := a_top
			right := a_right
			bottom := a_bottom
			left := a_left
		ensure
			top_set: top = a_top
			right_set: right = a_right
			bottom_set: bottom = a_bottom
			left_set: left = a_left
		end

	make_all (a_val: NATURAL_16)
			-- Initialize with uniform padding `a_val` on all sides.
		do
			make (a_val, a_val, a_val, a_val)
		ensure
			top_set: top = a_val
			right_set: right = a_val
			bottom_set: bottom = a_val
			left_set: left = a_val
		end

	make_symmetric (a_vertical, a_horizontal: NATURAL_16)
			-- Initialize with vertical and horizontal padding.
		do
			make (a_vertical, a_horizontal, a_vertical, a_horizontal)
		ensure
			top_set: top = a_vertical
			bottom_set: bottom = a_vertical
			left_set: left = a_horizontal
			right_set: right = a_horizontal
		end

feature -- Access

	top: NATURAL_16
			-- Top padding

	right: NATURAL_16
			-- Right padding

	bottom: NATURAL_16
			-- Bottom padding

	left: NATURAL_16
			-- Left padding

	horizontal: NATURAL_16
			-- Total horizontal padding (left + right)
		do
			Result := left + right
		ensure
			sum: Result = left + right
		end

	vertical: NATURAL_16
			-- Total vertical padding (top + bottom)
		do
			Result := top + bottom
		ensure
			sum: Result = top + bottom
		end

end
