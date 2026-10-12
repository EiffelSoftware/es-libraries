note
	description: "[
		Line shape connecting two world-space coordinates with styling.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	SHAPE_LINE

inherit
	SHAPE
		redefine
			is_equal
		end

create
	make

feature {NONE} -- Initialization

	make (a_x1, a_y1, a_x2, a_y2: REAL_64; a_style: STYLE)
			-- Initialize line from (`a_x1`, `a_y1`) to (`a_x2`, `a_y2`) with `a_style`.
		require
			style_not_void: a_style /= Void
		do
			x1 := a_x1
			y1 := a_y1
			x2 := a_x2
			y2 := a_y2
			style := a_style
		ensure
			x1_set: x1 = a_x1
			y1_set: y1 = a_y1
			x2_set: x2 = a_x2
			y2_set: y2 = a_y2
			style_set: style = a_style
		end

feature -- Access

	x1, y1, x2, y2: REAL_64
			-- Endpoint coordinates in world space

	style: STYLE
			-- Line styling

feature -- Execution

	paint (a_painter: CANVAS_PAINTER)
			-- Paint line using `a_painter`.
		do
			a_painter.set_style (style)
			a_painter.draw_line (x1, y1, x2, y2)
		end

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Is `a_other` equal to `Current`?
		do
			if a_other = Current then
				Result := True
			elseif standard_is_equal (a_other) then
				Result := True
			else
				Result := x1 = a_other.x1 and y1 = a_other.y1
					and x2 = a_other.x2 and y2 = a_other.y2
					and style.is_equal (a_other.style)
			end
		end

invariant
	style_not_void: style /= Void

end
