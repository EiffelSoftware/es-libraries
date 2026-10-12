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
			-- Clear all cells in `a_area` on `a_buffer`.
		local
			r, c, l_max_r, l_max_c: INTEGER
			l_def_style: STYLE
		do
			if not a_area.is_empty then
				create l_def_style.default_create
				l_max_r := (a_area.bottom.to_integer_32).min (a_buffer.height)
				l_max_c := (a_area.right.to_integer_32).min (a_buffer.width)

				from
					r := a_area.y.to_integer_32
				until
					r >= l_max_r
				loop
					from
						c := a_area.x.to_integer_32
					until
						c >= l_max_c
					loop
						a_buffer.put_char (r, c, ' ', l_def_style)
						c := c + 1
					end
					r := r + 1
				end
			end
		end

end
