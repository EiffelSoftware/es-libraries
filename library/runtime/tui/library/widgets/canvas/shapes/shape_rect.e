note
	description: "[
		Rectangle shape in world coordinates with styling.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	SHAPE_RECT

inherit
	SHAPE
		redefine
			is_equal
		end

create
	make

feature {NONE} -- Initialization

	make (a_x, a_y, a_w, a_h: REAL_64; a_style: STYLE)
			-- Initialize rectangle at (`a_x`, `a_y`) of size `a_w` by `a_h` with `a_style`.
		require
			style_not_void: a_style /= Void
			positive_w: a_w >= 0.0
			positive_h: a_h >= 0.0
		do
			x := a_x
			y := a_y
			width := a_w
			height := a_h
			style := a_style
		ensure
			x_set: x = a_x
			y_set: y = a_y
			width_set: width = a_w
			height_set: height = a_h
			style_set: style = a_style
		end

feature -- Access

	x, y, width, height: REAL_64
			-- Bounding coordinates in world space

	style: STYLE
			-- Rectangle styling

feature -- Execution

	paint (a_painter: CANVAS_PAINTER)
			-- Paint rectangle outline using `a_painter`.
		do
			a_painter.set_style (style)
			a_painter.draw_rect (x, y, width, height)
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
				Result := x = a_other.x and y = a_other.y
					and width = a_other.width and height = a_other.height
					and style.is_equal (a_other.style)
			end
		end

invariant
	style_not_void: style /= Void
	positive_dimensions: width >= 0.0 and height >= 0.0

end
