note
	description: "[
		Drawing context for BRAILLE_CANVAS with world coordinate mapping,
		Bresenham line rasterization, circles, rectangles, and text overlays.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	CANVAS_PAINTER

create
	make

feature {NONE} -- Initialization

	make (a_canvas: BRAILLE_CANVAS; a_x_bounds, a_y_bounds: TUPLE [min, max: REAL_64])
			-- Initialize painter for `a_canvas` with world coordinate bounds.
		require
			canvas_not_void: a_canvas /= Void
			x_bounds_valid: a_x_bounds /= Void and then a_x_bounds.min < a_x_bounds.max
			y_bounds_valid: a_y_bounds /= Void and then a_y_bounds.min < a_y_bounds.max
		do
			canvas := a_canvas
			x_bounds := a_x_bounds
			y_bounds := a_y_bounds
			create current_style.default_create
			create text_overlays.make (10)
		ensure
			canvas_set: canvas = a_canvas
			x_bounds_set: x_bounds = a_x_bounds
			y_bounds_set: y_bounds = a_y_bounds
		end

feature -- Access

	canvas: BRAILLE_CANVAS
			-- Associated Braille canvas.

	x_bounds: TUPLE [min, max: REAL_64]
			-- World coordinate X bounds [min, max].

	y_bounds: TUPLE [min, max: REAL_64]
			-- World coordinate Y bounds [min, max].

	current_style: STYLE
			-- Current drawing style.

	text_overlays: ARRAYED_LIST [TUPLE [col, row: INTEGER; text: STRING_32; style: STYLE]]
			-- Text overlays registered during painting.

feature -- Configuration

	set_style (a_style: STYLE)
			-- Set current drawing style to `a_style`.
		require
			style_not_void: a_style /= Void
		do
			current_style := a_style
		ensure
			style_set: current_style = a_style
		end

feature -- Coordinate Mapping

	world_to_subpixel_x (a_x: REAL_64): INTEGER
			-- Map world X to canvas subpixel X.
		local
			l_span, l_w: REAL_64
		do
			l_span := x_bounds.max - x_bounds.min
			if l_span > 0.0 and canvas.subpixel_width > 1 then
				l_w := (canvas.subpixel_width - 1).to_double
				Result := (((a_x - x_bounds.min) / l_span) * l_w).rounded.to_integer_32
			else
				Result := 0
			end
		end

	world_to_subpixel_y (a_y: REAL_64): INTEGER
			-- Map world Y to canvas subpixel Y (Cartesian: y_max at top = 0).
		local
			l_span, l_h: REAL_64
		do
			l_span := y_bounds.max - y_bounds.min
			if l_span > 0.0 and canvas.subpixel_height > 1 then
				l_h := (canvas.subpixel_height - 1).to_double
				Result := (((y_bounds.max - a_y) / l_span) * l_h).rounded.to_integer_32
			else
				Result := 0
			end
		end

	world_to_cell_col (a_x: REAL_64): INTEGER
			-- Map world X to terminal character cell column.
		do
			Result := world_to_subpixel_x (a_x) // 2
		end

	world_to_cell_row (a_y: REAL_64): INTEGER
			-- Map world Y to terminal character cell row.
		do
			Result := world_to_subpixel_y (a_y) // 4
		end

feature -- Drawing Primitives

	draw_point (a_x, a_y: REAL_64)
			-- Plot single point at world coordinate (`a_x`, `a_y`).
		local
			sx, sy: INTEGER
		do
			sx := world_to_subpixel_x (a_x)
			sy := world_to_subpixel_y (a_y)
			canvas.set_pixel_with_style (sx, sy, current_style)
		end

	draw_line (a_x1, a_y1, a_x2, a_y2: REAL_64)
			-- Draw line between (`a_x1`, `a_y1`) and (`a_x2`, `a_y2`) using Bresenham's algorithm.
		local
			sx1, sy1, sx2, sy2: INTEGER
		do
			sx1 := world_to_subpixel_x (a_x1)
			sy1 := world_to_subpixel_y (a_y1)
			sx2 := world_to_subpixel_x (a_x2)
			sy2 := world_to_subpixel_y (a_y2)
			draw_subpixel_line (sx1, sy1, sx2, sy2)
		end

	draw_rect (a_x, a_y, a_width, a_height: REAL_64)
			-- Draw rectangle with bottom-left at (`a_x`, `a_y`) and dimensions (`a_width`, `a_height`).
		do
			draw_line (a_x, a_y, a_x + a_width, a_y)
			draw_line (a_x + a_width, a_y, a_x + a_width, a_y + a_height)
			draw_line (a_x + a_width, a_y + a_height, a_x, a_y + a_height)
			draw_line (a_x, a_y + a_height, a_x, a_y)
		end

	draw_circle (a_cx, a_cy, a_radius: REAL_64)
			-- Draw circle centered at (`a_cx`, `a_cy`) with world radius `a_radius`.
			-- The radius is scaled on each axis, so a circle stays round in world coordinates
			-- (an ellipse on the dot grid when the axes have different scales, as in Ratatui).
		local
			scx, scy, rx, ry, i, n: INTEGER
			l_angle: REAL_64
			l_math: DOUBLE_MATH
		do
			scx := world_to_subpixel_x (a_cx)
			scy := world_to_subpixel_y (a_cy)
			rx := (world_to_subpixel_x (a_cx + a_radius.abs) - scx).abs
			ry := (world_to_subpixel_y (a_cy - a_radius.abs) - scy).abs
			if rx = ry then
				draw_subpixel_circle (scx, scy, rx)
			else
				create l_math
				n := (4 * (rx + ry)).max (8).min (100_000)
				from
					i := 0
				until
					i >= n
				loop
					l_angle := 2.0 * {DOUBLE_MATH}.pi * i.to_double / n.to_double
					canvas.set_pixel_with_style (scx + (rx.to_double * l_math.cosine (l_angle)).rounded,
						scy + (ry.to_double * l_math.sine (l_angle)).rounded, current_style)
					i := i + 1
				end
			end
		end

	draw_text (a_x, a_y: REAL_64; a_text: READABLE_STRING_GENERAL; a_style: STYLE)
			-- Register text overlay to be drawn at world position (`a_x`, `a_y`).
		require
			text_not_void: a_text /= Void
			style_not_void: a_style /= Void
		local
			col, row: INTEGER
			l_str: STRING_32
		do
			col := world_to_cell_col (a_x)
			row := world_to_cell_row (a_y)
			create l_str.make_from_string_general (a_text)
			text_overlays.extend ([col, row, l_str, a_style])
		end

feature {NONE} -- Rasterization Algorithms

	draw_subpixel_line (x0, y0, x1, y1: INTEGER)
			-- Bresenham line algorithm in subpixel dot space.
		local
			dx, dy, sx, sy, err, e2: INTEGER
			cx, cy: INTEGER
		do
			dx := (x1 - x0).abs
			dy := -(y1 - y0).abs
			if x0 < x1 then sx := 1 else sx := -1 end
			if y0 < y1 then sy := 1 else sy := -1 end
			err := dx + dy
			from
				cx := x0
				cy := y0
			until
				cx = x1 and cy = y1
			loop
				canvas.set_pixel_with_style (cx, cy, current_style)
				e2 := 2 * err
				if e2 >= dy then
					err := err + dy
					cx := cx + sx
				end
				if e2 <= dx then
					err := err + dx
					cy := cy + sy
				end
			end
			canvas.set_pixel_with_style (x1, y1, current_style)
		end

	draw_subpixel_circle (xc, yc, r: INTEGER)
			-- Midpoint circle algorithm in subpixel space.
		local
			x, y, d: INTEGER
		do
			x := 0
			y := r
			d := 3 - 2 * r
			plot_circle_points (xc, yc, x, y)
			from
			until
				y < x
			loop
				x := x + 1
				if d > 0 then
					y := y - 1
					d := d + 4 * (x - y) + 10
				else
					d := d + 4 * x + 6
				end
				plot_circle_points (xc, yc, x, y)
			end
		end

	plot_circle_points (xc, yc, x, y: INTEGER)
			-- Plot 8 symmetric circle points.
		do
			canvas.set_pixel_with_style (xc + x, yc + y, current_style)
			canvas.set_pixel_with_style (xc - x, yc + y, current_style)
			canvas.set_pixel_with_style (xc + x, yc - y, current_style)
			canvas.set_pixel_with_style (xc - x, yc - y, current_style)
			canvas.set_pixel_with_style (xc + y, yc + x, current_style)
			canvas.set_pixel_with_style (xc - y, yc + x, current_style)
			canvas.set_pixel_with_style (xc + y, yc - x, current_style)
			canvas.set_pixel_with_style (xc - y, yc - x, current_style)
		end

invariant
	canvas_not_void: canvas /= Void
	x_bounds_not_void: x_bounds /= Void
	y_bounds_not_void: y_bounds /= Void
	current_style_not_void: current_style /= Void
	text_overlays_not_void: text_overlays /= Void

end
