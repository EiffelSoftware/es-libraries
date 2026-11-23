note
	description: "[
		Filled line shape: a line between two world-space coordinates with the area between it
		and the world Y `fill_to_y` filled in the same style (Ratatui `canvas::FilledLine`).
		Useful for area charts; TUI_CHART draws {CHART_GRAPH_TYPE}.area datasets this way.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	SHAPE_FILLED_LINE

inherit
	SHAPE
		redefine
			is_equal
		end

create
	make

feature {NONE} -- Initialization

	make (a_x1, a_y1, a_x2, a_y2, a_fill_to_y: REAL_64; a_style: STYLE)
			-- Initialize line from (`a_x1`, `a_y1`) to (`a_x2`, `a_y2`), filled to `a_fill_to_y`,
			-- with `a_style`.
		require
			style_not_void: a_style /= Void
		do
			x1 := a_x1
			y1 := a_y1
			x2 := a_x2
			y2 := a_y2
			fill_to_y := a_fill_to_y
			style := a_style
		ensure
			x1_set: x1 = a_x1
			y1_set: y1 = a_y1
			x2_set: x2 = a_x2
			y2_set: y2 = a_y2
			fill_to_y_set: fill_to_y = a_fill_to_y or (fill_to_y.is_nan and a_fill_to_y.is_nan)
			style_set: style = a_style
		end

feature -- Access

	x1, y1, x2, y2: REAL_64
			-- Endpoint coordinates in world space

	fill_to_y: REAL_64
			-- World Y the area is filled to (clamped to the Y bounds when painted; NaN paints nothing)

	style: STYLE
			-- Line and fill styling

feature -- Execution

	paint (a_painter: CANVAS_PAINTER)
			-- Paint filled line using `a_painter`.
		do
			a_painter.set_style (style)
			a_painter.draw_filled_line (x1, y1, x2, y2, fill_to_y)
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
					and fill_to_y = a_other.fill_to_y
					and style.is_equal (a_other.style)
			end
		end

invariant
	style_not_void: style /= Void

end
