note
	description: "[
		Drawing context for BRAILLE_CANVAS with world coordinate mapping,
		Bresenham line rasterization, filled lines, circles, rectangles, and text overlays.
		Polygons (Ratatui `Area`) are clipped by Sutherland-Hodgman, outlined and optionally filled by
		the even-odd rule. A concave polygon that the bounds split in two is clipped into one polygon
		joined along the border, so its outline shows a "bridge" there (as in Ratatui).
		Lines and filled lines are clipped to the world bounds before the dot walk. Points outside the bounds,
		and NaN, infinities or values too large to map, are skipped (as Ratatui's `get_point`).
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

feature -- Status report

	is_finite (a_value: REAL_64): BOOLEAN
			-- Is `a_value` neither NaN nor an infinity?
		do
			Result := not a_value.is_nan and not a_value.is_positive_infinity and not a_value.is_negative_infinity
		end

	is_inside (a_x, a_y: REAL_64): BOOLEAN
			-- Is world point (`a_x`, `a_y`) within the bounds, edges included? False for NaN.
		do
			Result := a_x >= x_bounds.min and a_x <= x_bounds.max and a_y >= y_bounds.min and a_y <= y_bounds.max
		end

	is_drawable (a_x, a_y: REAL_64): BOOLEAN
			-- Is world point (`a_x`, `a_y`) within the bounds, up to floating-point error at the edges?
			-- A point outside by at most `Edge_slack` times the span (0.1 + 0.2 against a bound of 0.3)
			-- counts as on the edge; Ratatui's `get_point` would skip it. False for NaN.
		local
			l_dx, l_dy: REAL_64
		do
				-- From the half spans, which stay finite for bounds near the REAL_64 range (X3b)
			l_dx := Edge_slack * (x_bounds.max / 2 - x_bounds.min / 2).abs * 2
			l_dy := Edge_slack * (y_bounds.max / 2 - y_bounds.min / 2).abs * 2
			Result := a_x >= x_bounds.min - l_dx and a_x <= x_bounds.max + l_dx
				and a_y >= y_bounds.min - l_dy and a_y <= y_bounds.max + l_dy
		ensure
			inside_is_drawable: is_inside (a_x, a_y) implies Result
		end

	Edge_slack: REAL_64 = 1.0e-9
			-- Fraction of an axis span by which a point may lie outside the bounds and still be drawn
			-- on the edge (floating-point error only: far below one dot on any grid).

	is_mappable_x (a_x: REAL_64): BOOLEAN
			-- Can world X `a_x` be mapped to a subpixel column without overflow?
		do
			Result := is_finite (a_x) and then is_finite (subpixel_x_real (a_x))
				and then subpixel_x_real (a_x).abs <= Max_subpixel_magnitude
		end

	is_mappable_y (a_y: REAL_64): BOOLEAN
			-- Can world Y `a_y` be mapped to a subpixel row without overflow?
		do
			Result := is_finite (a_y) and then is_finite (subpixel_y_real (a_y))
				and then subpixel_y_real (a_y).abs <= Max_subpixel_magnitude
		end

	Max_subpixel_magnitude: REAL_64 = 1_000_000.0
			-- Largest subpixel coordinate (in absolute value) that is mapped.
			-- Keeps the dot arithmetic far from INTEGER_32 overflow and bounds the circle loops.

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
		require
			mappable: is_mappable_x (a_x)
		do
			Result := subpixel_x_real (a_x).rounded
		end

	world_to_subpixel_y (a_y: REAL_64): INTEGER
			-- Map world Y to canvas subpixel Y (Cartesian: y_max at top = 0).
		require
			mappable: is_mappable_y (a_y)
		do
			Result := subpixel_y_real (a_y).rounded
		end

	world_to_cell_col (a_x: REAL_64): INTEGER
			-- Map world X to terminal character cell column (at the canvas resolution).
		require
			mappable: is_mappable_x (a_x)
		do
			Result := world_to_subpixel_x (a_x) // canvas.dots_x
		ensure
			cell_of_subpixel: Result = world_to_subpixel_x (a_x) // canvas.dots_x
		end

	world_to_cell_row (a_y: REAL_64): INTEGER
			-- Map world Y to terminal character cell row (at the canvas resolution).
		require
			mappable: is_mappable_y (a_y)
		do
			Result := world_to_subpixel_y (a_y) // canvas.dots_y
		ensure
			cell_of_subpixel: Result = world_to_subpixel_y (a_y) // canvas.dots_y
		end

	clipped_segment (a_x1, a_y1, a_x2, a_y2: REAL_64): detachable TUPLE [x1, y1, x2, y2: REAL_64]
			-- Part of the segment from (`a_x1`, `a_y1`) to (`a_x2`, `a_y2`) inside the world bounds,
			-- by Cohen-Sutherland as Ratatui's `clip_line`. Void when the segment misses the bounds.
			-- A line through a corner can leave an end bouncing between the two edges by rounding
			-- until the step cap; such ends, within `Edge_slack` of the bounds, are clamped onto them.
		require
			finite_ends: is_finite (a_x1) and is_finite (a_y1) and is_finite (a_x2) and is_finite (a_y2)
		local
			x1, y1, x2, y2, x, y: REAL_64
			c1, c2, c, l_steps: INTEGER
			l_done: BOOLEAN
		do
			x1 := a_x1
			y1 := a_y1
			x2 := a_x2
			y2 := a_y2
			c1 := out_code (x1, y1)
			c2 := out_code (x2, y2)
			from
			until
				l_done or l_steps >= Max_clip_steps
			loop
				if c1 = 0 and c2 = 0 then
					Result := [x1, y1, x2, y2]
					l_done := True
				elseif c1.bit_and (c2) /= 0 then
						-- Both ends beyond the same edge: the segment misses the bounds
					l_done := True
				else
						-- Move one outside end onto the edge it crosses
					if c1 /= 0 then c := c1 else c := c2 end
					if c.bit_and (Code_top) /= 0 then
						x := x1 + (x2 - x1) * (y_bounds.max - y1) / (y2 - y1)
						if overflows (y1, x1, y2, x2, x) then
							x := crossing (y1, x1, y2, x2, y_bounds.max)
						end
						y := y_bounds.max
					elseif c.bit_and (Code_bottom) /= 0 then
						x := x1 + (x2 - x1) * (y_bounds.min - y1) / (y2 - y1)
						if overflows (y1, x1, y2, x2, x) then
							x := crossing (y1, x1, y2, x2, y_bounds.min)
						end
						y := y_bounds.min
					elseif c.bit_and (Code_right) /= 0 then
						y := y1 + (y2 - y1) * (x_bounds.max - x1) / (x2 - x1)
						if overflows (x1, y1, x2, y2, y) then
							y := crossing (x1, y1, x2, y2, x_bounds.max)
						end
						x := x_bounds.max
					else
						y := y1 + (y2 - y1) * (x_bounds.min - x1) / (x2 - x1)
						if overflows (x1, y1, x2, y2, y) then
							y := crossing (x1, y1, x2, y2, x_bounds.min)
						end
						x := x_bounds.min
					end
					if not is_finite (x) or not is_finite (y) then
							-- The interpolation overflowed (ends near the REAL_64 range): give up
						l_done := True
					elseif c = c1 then
						x1 := x
						y1 := y
						c1 := out_code (x1, y1)
					else
						x2 := x
						y2 := y
						c2 := out_code (x2, y2)
					end
				end
				l_steps := l_steps + 1
			variant
				Max_clip_steps - l_steps
			end
			if not l_done and then is_drawable (x1, y1) and then is_drawable (x2, y2) then
					-- Step cap reached with both ends on the bounds up to rounding
				Result := [x1.max (x_bounds.min).min (x_bounds.max), y1.max (y_bounds.min).min (y_bounds.max),
					x2.max (x_bounds.min).min (x_bounds.max), y2.max (y_bounds.min).min (y_bounds.max)]
			end
		ensure
			inside: attached Result as r implies (is_inside (r.x1, r.y1) and is_inside (r.x2, r.y2))
		end

	clipped_polygon (a_vertices: ITERABLE [TUPLE [x, y: REAL_64]]): ARRAYED_LIST [TUPLE [x, y: REAL_64]]
			-- Part of the polygon `a_vertices` inside the world bounds, by Sutherland-Hodgman as Ratatui's
			-- `clip_polygon` (line_clipping 0.3.8): clipped against the left, right, bottom and top bound
			-- in turn. Empty when the polygon misses the bounds. A polygon inside keeps its vertices,
			-- their order and its start vertex. A concave polygon that the bounds split in two comes back
			-- as one polygon, its parts joined by edges along the border (the "bridge artifact").
			-- The vertices are new tuples; `a_vertices` is not changed.
		require
			vertices_not_void: a_vertices /= Void
			finite_vertices: across a_vertices as v all is_finite (v.x) and is_finite (v.y) end
		do
			create Result.make (8)
			across a_vertices as v loop
				Result.extend ([v.x, v.y])
			end
			Result := clipped_polygon_edge (Result, Code_left)
			Result := clipped_polygon_edge (Result, Code_right)
			Result := clipped_polygon_edge (Result, Code_bottom)
			Result := clipped_polygon_edge (Result, Code_top)
		ensure
			result_not_void: Result /= Void
		end

feature -- Drawing Primitives

	draw_point (a_x, a_y: REAL_64)
			-- Plot single point at world coordinate (`a_x`, `a_y`).
			-- Skipped when the point is outside the bounds or not finite (Ratatui `get_point`); a point
			-- outside only by floating-point error is drawn on the edge (`is_drawable`).
		do
			if is_drawable (a_x, a_y) and then is_mappable_x (a_x) and then is_mappable_y (a_y) then
				canvas.set_pixel_with_style (world_to_subpixel_x (a_x), world_to_subpixel_y (a_y), current_style)
			end
		end

	draw_line (a_x1, a_y1, a_x2, a_y2: REAL_64)
			-- Draw line between (`a_x1`, `a_y1`) and (`a_x2`, `a_y2`) using Bresenham's algorithm.
			-- The segment is clipped to the bounds first. A line with a non-finite end draws nothing.
		do
			if (is_finite (a_x1) and is_finite (a_y1) and is_finite (a_x2) and is_finite (a_y2)) and then
				attached clipped_segment (a_x1, a_y1, a_x2, a_y2) as l_seg and then
				(is_mappable_x (l_seg.x1) and is_mappable_y (l_seg.y1) and is_mappable_x (l_seg.x2) and is_mappable_y (l_seg.y2))
			then
				draw_subpixel_line (world_to_subpixel_x (l_seg.x1), world_to_subpixel_y (l_seg.y1),
					world_to_subpixel_x (l_seg.x2), world_to_subpixel_y (l_seg.y2), False, 0)
			end
		end

	draw_filled_line (a_x1, a_y1, a_x2, a_y2, a_fill_to_y: REAL_64)
			-- Draw line between (`a_x1`, `a_y1`) and (`a_x2`, `a_y2`) and fill the area between it and
			-- world Y `a_fill_to_y` (below or above the line), as Ratatui's `FilledLine`: every dot of
			-- the line walk gets its dot column painted from the line to the fill row.
			-- The segment is clipped to the bounds first and `a_fill_to_y` is clamped to the Y bounds,
			-- so only the visible part is walked. A non-finite end or a NaN `a_fill_to_y` draws nothing;
			-- an infinite `a_fill_to_y` fills to the nearer Y bound.
		local
			l_fill: REAL_64
		do
			if (is_finite (a_x1) and is_finite (a_y1) and is_finite (a_x2) and is_finite (a_y2) and not a_fill_to_y.is_nan) and then
				attached clipped_segment (a_x1, a_y1, a_x2, a_y2) as l_seg and then
				(is_mappable_x (l_seg.x1) and is_mappable_y (l_seg.y1) and is_mappable_x (l_seg.x2) and is_mappable_y (l_seg.y2))
			then
				l_fill := a_fill_to_y.max (y_bounds.min).min (y_bounds.max)
				draw_subpixel_line (world_to_subpixel_x (l_seg.x1), world_to_subpixel_y (l_seg.y1),
					world_to_subpixel_x (l_seg.x2), world_to_subpixel_y (l_seg.y2), True, world_to_subpixel_y (l_fill))
			end
		end

	draw_polygon (a_vertices: ITERABLE [TUPLE [x, y: REAL_64]]; a_fill: BOOLEAN)
			-- Draw the polygon `a_vertices` (closed: the last vertex joins the first), as Ratatui's `Area`:
			-- clipped to the bounds (`clipped_polygon`), mapped to dots, outlined edge by edge with the
			-- line walk, and when `a_fill`, filled by the even-odd rule (`fill_dot_polygon`).
			-- Draws nothing for an empty list, for a NaN or infinite vertex (as `draw_line`), or when a
			-- clipped vertex cannot be mapped (Ratatui's `get_point` returning None). Only the visible
			-- part is walked and filled. A clipped vertex outside the bounds by rounding error only
			-- (`is_drawable`) is mapped onto the edge; Ratatui would draw nothing.
		require
			vertices_not_void: a_vertices /= Void
		local
			l_clipped: ARRAYED_LIST [TUPLE [x, y: REAL_64]]
			l_dots: ARRAYED_LIST [TUPLE [x, y: INTEGER]]
			l_previous: TUPLE [x, y: INTEGER]
		do
			if across a_vertices as v all is_finite (v.x) and is_finite (v.y) end then
				l_clipped := clipped_polygon (a_vertices)
				if not l_clipped.is_empty and then
					across l_clipped as p all is_drawable (p.x, p.y) and then is_mappable_x (p.x) and then is_mappable_y (p.y) end
				then
					create l_dots.make (l_clipped.count)
					across l_clipped as p loop
						l_dots.extend ([world_to_subpixel_x (p.x), world_to_subpixel_y (p.y)])
					end
						-- Outline, starting with the closing edge from the last vertex
					l_previous := l_dots.last
					across l_dots as d loop
						draw_subpixel_line (l_previous.x, l_previous.y, d.x, d.y, False, 0)
						l_previous := d
					end
					if a_fill then
						fill_dot_polygon (l_dots)
					end
				end
			end
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
			-- Skipped when the center or the radius is not finite or too large to map.
		local
			scx, scy, rx, ry, i, n: INTEGER
			l_angle: REAL_64
			l_math: DOUBLE_MATH
		do
			if is_mappable_x (a_cx) and is_mappable_y (a_cy)
				and is_mappable_x (a_cx + a_radius.abs) and is_mappable_y (a_cy - a_radius.abs)
			then
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
		end

	draw_text (a_x, a_y: REAL_64; a_text: READABLE_STRING_GENERAL; a_style: STYLE)
			-- Register text overlay to be drawn at world position (`a_x`, `a_y`).
			-- Skipped when the position is not finite or too large to map.
		require
			text_not_void: a_text /= Void
			style_not_void: a_style /= Void
		local
			col, row: INTEGER
			l_str: STRING_32
		do
			if is_mappable_x (a_x) and is_mappable_y (a_y) then
				col := world_to_cell_col (a_x)
				row := world_to_cell_row (a_y)
				create l_str.make_from_string_general (a_text)
				text_overlays.extend ([col, row, l_str, a_style])
			end
		end

feature {NONE} -- Coordinate Helpers

	subpixel_x_real (a_x: REAL_64): REAL_64
			-- World X `a_x` scaled to subpixel columns, before rounding.
			-- When the span overflows (bounds near the REAL_64 range, such as +-1e308), the offset
			-- and the span are taken by halves, which is exact; Ratatui's `get_point` divides
			-- infinity by infinity there and draws such points in column 0.
		local
			l_span: REAL_64
		do
			l_span := x_bounds.max - x_bounds.min
			if l_span > 0.0 and canvas.subpixel_width > 1 then
				if l_span.is_positive_infinity then
					Result := ((a_x / 2 - x_bounds.min / 2) / (x_bounds.max / 2 - x_bounds.min / 2)) * (canvas.subpixel_width - 1).to_double
				else
					Result := ((a_x - x_bounds.min) / l_span) * (canvas.subpixel_width - 1).to_double
				end
			end
		end

	subpixel_y_real (a_y: REAL_64): REAL_64
			-- World Y `a_y` scaled to subpixel rows (y_max at row 0), before rounding.
			-- A span that overflows is taken by halves, as in `subpixel_x_real`.
		local
			l_span: REAL_64
		do
			l_span := y_bounds.max - y_bounds.min
			if l_span > 0.0 and canvas.subpixel_height > 1 then
				if l_span.is_positive_infinity then
					Result := ((y_bounds.max / 2 - a_y / 2) / (y_bounds.max / 2 - y_bounds.min / 2)) * (canvas.subpixel_height - 1).to_double
				else
					Result := ((y_bounds.max - a_y) / l_span) * (canvas.subpixel_height - 1).to_double
				end
			end
		end

	out_code (a_x, a_y: REAL_64): INTEGER
			-- Cohen-Sutherland region code of world point (`a_x`, `a_y`): 0 inside the bounds.
		do
			if a_x < x_bounds.min then
				Result := Code_left
			elseif a_x > x_bounds.max then
				Result := Code_right
			end
			if a_y < y_bounds.min then
				Result := Result.bit_or (Code_bottom)
			elseif a_y > y_bounds.max then
				Result := Result.bit_or (Code_top)
			end
		end

	Code_left: INTEGER = 1
	Code_right: INTEGER = 2
	Code_bottom: INTEGER = 4
	Code_top: INTEGER = 8
			-- Cohen-Sutherland region bits.

	Max_clip_steps: INTEGER = 8
			-- Upper bound on clipping steps (each end crosses at most two edges, plus float slack).

	clipped_polygon_edge (a_vertices: ARRAYED_LIST [TUPLE [x, y: REAL_64]]; a_edge: INTEGER): ARRAYED_LIST [TUPLE [x, y: REAL_64]]
			-- `a_vertices` clipped against the one bound `a_edge` (`Code_left`, `Code_right`, `Code_bottom`
			-- or `Code_top`): one Sutherland-Hodgman pass, as line_clipping's `clip_edge`. It starts with
			-- the closing edge from the last vertex to the first, so the start vertex is kept.
		require
			vertices_not_void: a_vertices /= Void
			valid_edge: a_edge = Code_left or a_edge = Code_right or a_edge = Code_bottom or a_edge = Code_top
		local
			l_previous: TUPLE [x, y: REAL_64]
			l_previous_inside, l_current_inside: BOOLEAN
		do
			create Result.make (a_vertices.count + 4)
			if not a_vertices.is_empty then
				l_previous := a_vertices.last
				across a_vertices as c loop
					l_previous_inside := is_inside_edge (l_previous, a_edge)
					l_current_inside := is_inside_edge (c, a_edge)
					if l_previous_inside and l_current_inside then
						Result.extend (c)
					elseif l_previous_inside then
						Result.extend (edge_intersection (l_previous, c, a_edge))
					elseif l_current_inside then
						Result.extend (edge_intersection (l_previous, c, a_edge))
						Result.extend (c)
					end
					l_previous := c
				end
			end
		ensure
			result_not_void: Result /= Void
		end

	is_inside_edge (a_point: TUPLE [x, y: REAL_64]; a_edge: INTEGER): BOOLEAN
			-- Is `a_point` on the inner side of bound `a_edge` (the bound itself included)?
		require
			point_not_void: a_point /= Void
		do
			inspect a_edge
			when Code_left then
				Result := a_point.x >= x_bounds.min
			when Code_right then
				Result := a_point.x <= x_bounds.max
			when Code_bottom then
				Result := a_point.y >= y_bounds.min
			else
				Result := a_point.y <= y_bounds.max
			end
		end

	edge_intersection (a_from, a_to: TUPLE [x, y: REAL_64]; a_edge: INTEGER): TUPLE [x, y: REAL_64]
			-- Point where the edge from `a_from` to `a_to`, which crosses bound `a_edge`, meets it
			-- (line_clipping's interpolation, `t` measured from `a_from`).
		require
			from_not_void: a_from /= Void
			to_not_void: a_to /= Void
		local
			t, v: REAL_64
		do
			inspect a_edge
			when Code_left then
				t := (x_bounds.min - a_from.x) / (a_to.x - a_from.x)
				v := a_from.y + t * (a_to.y - a_from.y)
				if overflows (a_from.x, a_from.y, a_to.x, a_to.y, v) then
					v := crossing (a_from.x, a_from.y, a_to.x, a_to.y, x_bounds.min)
				end
				Result := [x_bounds.min, v]
			when Code_right then
				t := (x_bounds.max - a_from.x) / (a_to.x - a_from.x)
				v := a_from.y + t * (a_to.y - a_from.y)
				if overflows (a_from.x, a_from.y, a_to.x, a_to.y, v) then
					v := crossing (a_from.x, a_from.y, a_to.x, a_to.y, x_bounds.max)
				end
				Result := [x_bounds.max, v]
			when Code_bottom then
				t := (y_bounds.min - a_from.y) / (a_to.y - a_from.y)
				v := a_from.x + t * (a_to.x - a_from.x)
				if overflows (a_from.y, a_from.x, a_to.y, a_to.x, v) then
					v := crossing (a_from.y, a_from.x, a_to.y, a_to.x, y_bounds.min)
				end
				Result := [v, y_bounds.min]
			else
				t := (y_bounds.max - a_from.y) / (a_to.y - a_from.y)
				v := a_from.x + t * (a_to.x - a_from.x)
				if overflows (a_from.y, a_from.x, a_to.y, a_to.x, v) then
					v := crossing (a_from.y, a_from.x, a_to.y, a_to.x, y_bounds.max)
				end
				Result := [v, y_bounds.max]
			end
		end

	overflows (a_c1, a_o1, a_c2, a_o2, a_value: REAL_64): BOOLEAN
			-- Did the interpolation that gave `a_value`, on the segment from (`a_c1`, `a_o1`) to
			-- (`a_c2`, `a_o2`), overflow? A difference of the ends beyond the REAL_64 range makes
			-- the result NaN, or silently 0 or 1 for `t` (finite / infinity); a product can
			-- overflow too.
		do
			Result := not is_finite (a_c2 - a_c1) or not is_finite (a_o2 - a_o1) or not is_finite (a_value)
		end

	crossing (a_c1, a_o1, a_c2, a_o2, a_bound: REAL_64): REAL_64
			-- Coordinate other than `c` where the segment from (`a_c1`, `a_o1`) to (`a_c2`, `a_o2`)
			-- meets c = `a_bound`, for ends near the REAL_64 range (X3b): `t` from half values and
			-- the result as a weighted mean, so no intermediate value overflows.
		require
			finite_ends: is_finite (a_c1) and is_finite (a_o1) and is_finite (a_c2) and is_finite (a_o2)
			distinct: a_c1 /= a_c2
		local
			t: REAL_64
		do
			t := ((a_bound / 2 - a_c1 / 2) / (a_c2 / 2 - a_c1 / 2)).max (0.0).min (1.0)
			Result := a_o1 * (1.0 - t) + a_o2 * t
		end

feature {NONE} -- Rasterization Algorithms

	draw_subpixel_line (x0, y0, x1, y1: INTEGER; a_filled: BOOLEAN; a_fill_row: INTEGER)
			-- Bresenham line in subpixel dot space, as Ratatui's `for_each_line_point`: a shallow
			-- line is walked from its smaller x, a steep one from its smaller y, so the dots do not
			-- depend on the order of the ends. When `a_filled`, each dot of the walk also fills its
			-- column to dot row `a_fill_row` (`plot_line_dot`), as Ratatui's `FilledLine`.
		local
			x, y: INTEGER
		do
			if x0 = x1 then
				from y := y0.min (y1) until y > y0.max (y1) loop
					plot_line_dot (x0, y, a_filled, a_fill_row)
					y := y + 1
				end
			elseif y0 = y1 then
				from x := x0.min (x1) until x > x0.max (x1) loop
					plot_line_dot (x, y0, a_filled, a_fill_row)
					x := x + 1
				end
			elseif (y1 - y0).abs < (x1 - x0).abs then
				if x0 > x1 then
					draw_subpixel_line_low (x1, y1, x0, y0, a_filled, a_fill_row)
				else
					draw_subpixel_line_low (x0, y0, x1, y1, a_filled, a_fill_row)
				end
			elseif y0 > y1 then
				draw_subpixel_line_high (x1, y1, x0, y0, a_filled, a_fill_row)
			else
				draw_subpixel_line_high (x0, y0, x1, y1, a_filled, a_fill_row)
			end
		end

	draw_subpixel_line_low (x0, y0, x1, y1: INTEGER; a_filled: BOOLEAN; a_fill_row: INTEGER)
			-- Bresenham walk of a shallow line, one dot per x from `x0` to `x1` (Ratatui `for_each_line_point_low`).
		require
			left_to_right: x0 < x1
			shallow: (y1 - y0).abs < x1 - x0
		local
			dx, dy, d, x, y: INTEGER
		do
			dx := x1 - x0
			dy := (y1 - y0).abs
			d := 2 * dy - dx
			y := y0
			from x := x0 until x > x1 loop
				plot_line_dot (x, y, a_filled, a_fill_row)
				if d > 0 then
					if y0 > y1 then y := y - 1 else y := y + 1 end
					d := d - 2 * dx
				end
				d := d + 2 * dy
				x := x + 1
			end
		end

	draw_subpixel_line_high (x0, y0, x1, y1: INTEGER; a_filled: BOOLEAN; a_fill_row: INTEGER)
			-- Bresenham walk of a steep line, one dot per y from `y0` to `y1` (Ratatui `for_each_line_point_high`).
		require
			top_to_bottom: y0 < y1
			steep: (x1 - x0).abs <= y1 - y0
		local
			dx, dy, d, x, y: INTEGER
		do
			dx := (x1 - x0).abs
			dy := y1 - y0
			d := 2 * dx - dy
			x := x0
			from y := y0 until y > y1 loop
				plot_line_dot (x, y, a_filled, a_fill_row)
				if d > 0 then
					if x0 > x1 then x := x - 1 else x := x + 1 end
					d := d - 2 * dy
				end
				d := d + 2 * dx
				y := y + 1
			end
		end

	plot_line_dot (x, y: INTEGER; a_filled: BOOLEAN; a_fill_row: INTEGER)
			-- Set dot (`x`, `y`) of a line walk; when `a_filled`, every dot of column `x` from row `y`
			-- to row `a_fill_row` (both included, in either order).
		local
			r: INTEGER
		do
			if a_filled then
				from r := y.min (a_fill_row) until r > y.max (a_fill_row) loop
					canvas.set_pixel_with_style (x, r, current_style)
					r := r + 1
				end
			else
				canvas.set_pixel_with_style (x, y, current_style)
			end
		end

	fill_dot_polygon (a_dots: ARRAYED_LIST [TUPLE [x, y: INTEGER]])
			-- Fill the closed dot polygon `a_dots` by the even-odd rule, as Ratatui's `Area` scanline:
			-- for each dot row from the top vertex to the bottom one, every edge that is not horizontal
			-- and has end rows `y1 <= row < y2` (in either order) adds a crossing at
			-- `x1 + (row - y1) * (x2 - x1) // (y2 - y1)` (integer division truncated toward zero, as Rust's).
			-- The crossings are sorted and painted in pairs, both ends included; an odd last one is not.
		require
			dots_not_void: a_dots /= Void
			not_empty: not a_dots.is_empty
		local
			l_top, l_bottom, y, x, i: INTEGER
			l_previous: TUPLE [x, y: INTEGER]
			l_crossings: ARRAYED_LIST [INTEGER]
		do
			l_top := a_dots.first.y
			l_bottom := a_dots.first.y
			across a_dots as d loop
				l_top := l_top.min (d.y)
				l_bottom := l_bottom.max (d.y)
			end
			create l_crossings.make (a_dots.count)
			from y := l_top until y > l_bottom loop
				l_crossings.wipe_out
				l_previous := a_dots.last
				across a_dots as d loop
					if l_previous.y /= d.y and then
						((l_previous.y <= y and y < d.y) or (d.y <= y and y < l_previous.y))
					then
						l_crossings.extend (l_previous.x + (y - l_previous.y) * (d.x - l_previous.x) // (d.y - l_previous.y))
					end
					l_previous := d
				end
				sort_ascending (l_crossings)
				from i := 1 until i >= l_crossings.count loop
					from x := l_crossings [i] until x > l_crossings [i + 1] loop
						canvas.set_pixel_with_style (x, y, current_style)
						x := x + 1
					end
					i := i + 2
				end
				y := y + 1
			end
		end

	sort_ascending (a_list: ARRAYED_LIST [INTEGER])
			-- Sort `a_list` in ascending order (insertion sort: a scanline has few crossings).
		require
			list_not_void: a_list /= Void
		local
			i, j, l_item: INTEGER
		do
			from i := 2 until i > a_list.count loop
				l_item := a_list [i]
				from j := i - 1 until j < 1 or else a_list [j] <= l_item loop
					a_list [j + 1] := a_list [j]
					j := j - 1
				end
				a_list [j + 1] := l_item
				i := i + 1
			end
		ensure
			same_count: a_list.count = old a_list.count
			sorted: across 2 |..| a_list.count as k all a_list [k - 1] <= a_list [k] end
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
