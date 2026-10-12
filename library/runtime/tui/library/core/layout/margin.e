note
	description: "[
		Margin specification for layout spacing.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	MARGIN

inherit
	ANY
		redefine
			default_create,
			is_equal
		end

create
	default_create,
	make,
	make_symmetric

feature {NONE} -- Initialization

	default_create
			-- Initialize with 0 margins.
		do
			horizontal := 0
			vertical := 0
		ensure then
			zero_horizontal: horizontal = 0
			zero_vertical: vertical = 0
		end

	make (a_horizontal, a_vertical: NATURAL_16)
			-- Initialize with distinct horizontal and vertical margins.
		do
			horizontal := a_horizontal
			vertical := a_vertical
		ensure
			horizontal_set: horizontal = a_horizontal
			vertical_set: vertical = a_vertical
		end

	make_symmetric (a_margin: NATURAL_16)
			-- Initialize with equal margin on all sides.
		do
			horizontal := a_margin
			vertical := a_margin
		ensure
			horizontal_set: horizontal = a_margin
			vertical_set: vertical = a_margin
		end

feature -- Access

	horizontal: NATURAL_16
			-- Horizontal margin (left and right)

	vertical: NATURAL_16
			-- Vertical margin (top and bottom)

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Is `Current` equal to `a_other`?
		do
			Result := horizontal = a_other.horizontal and vertical = a_other.vertical
		end

end
