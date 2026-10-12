note
	description: "[
		Terminal screen resize event carrying new dimensions in columns and rows.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	RESIZE_EVENT

inherit
	EVENT
		redefine
			is_resize
		end

create
	make

feature {NONE} -- Initialization

	make (a_width, a_height: NATURAL_16)
			-- Initialize resize event with new dimensions.
		do
			width := a_width
			height := a_height
		ensure
			width_set: width = a_width
			height_set: height = a_height
		end

feature -- Access

	width: NATURAL_16
			-- New width in columns

	height: NATURAL_16
			-- New height in rows

feature -- Status report

	is_resize: BOOLEAN = True

end
