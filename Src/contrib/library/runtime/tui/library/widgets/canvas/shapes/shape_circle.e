note
	description: "[
		Circle shape specified by center and radius in world coordinates with styling.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	SHAPE_CIRCLE

inherit
	SHAPE
		redefine
			is_equal
		end

create
	make

feature {NONE} -- Initialization

	make (a_cx, a_cy, a_radius: REAL_64; a_style: STYLE)
			-- Initialize circle centered at (`a_cx`, `a_cy`) with `a_radius` and `a_style`.
		require
			style_not_void: a_style /= Void
			positive_radius: a_radius >= 0.0
		do
			center_x := a_cx
			center_y := a_cy
			radius := a_radius
			style := a_style
		ensure
			center_x_set: center_x = a_cx
			center_y_set: center_y = a_cy
			radius_set: radius = a_radius
			style_set: style = a_style
		end

feature -- Access

	center_x, center_y: REAL_64
			-- Center coordinates in world space

	radius: REAL_64
			-- Radius in world space

	style: STYLE
			-- Circle styling

feature -- Execution

	paint (a_painter: CANVAS_PAINTER)
			-- Paint circle using `a_painter`.
		do
			a_painter.set_style (style)
			a_painter.draw_circle (center_x, center_y, radius)
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
				Result := center_x = a_other.center_x and center_y = a_other.center_y
					and radius = a_other.radius
					and style.is_equal (a_other.style)
			end
		end

invariant
	style_not_void: style /= Void
	positive_radius: radius >= 0.0

end
