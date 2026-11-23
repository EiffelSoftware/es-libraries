note
	description: "[
		Stateless widget that clears all cells within its bounding rectangle to default spaces.
		Commonly used before drawing floating overlays, modals, or popup menus.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_CLEAR

inherit
	WIDGET

feature -- Rendering

	render (a_area: RECT; a_buffer: BUFFER)
			-- Clear all cells in `a_area` on `a_buffer` (the part of it inside the buffer).
		do
			a_buffer.clear_area (a_area)
		end

end
