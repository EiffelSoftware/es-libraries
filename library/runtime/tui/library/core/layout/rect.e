note
	description: "[
		Pure geometric rectangular region in terminal cell coordinates.
		Uses 0-based coordinates and unsigned 16-bit integers (NATURAL_16).
		Maintains strict overflow-free invariants and saturating arithmetic.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	RECT

inherit
	ANY
		redefine
			default_create,
			is_equal,
			out
		end

create
	default_create,
	make

feature {NONE} -- Initialization

	default_create
			-- Initialize as an empty rectangle at (0, 0).
		do
			x := 0
			y := 0
			width := 0
			height := 0
		ensure then
			at_origin: x = 0 and y = 0
			zero_dimensions: width = 0 and height = 0
		end

	make (a_x, a_y, a_width, a_height: NATURAL_16)
			-- Initialize rectangle at (`a_x`, `a_y`) with saturating bounds within 65535.
		local
			l_w, l_h: NATURAL_16
		do
			x := a_x
			y := a_y
			if a_x.to_natural_32 + a_width.to_natural_32 > 65535 then
				l_w := (65535 - a_x.to_natural_32).to_natural_16
			else
				l_w := a_width
			end
			width := l_w

			if a_y.to_natural_32 + a_height.to_natural_32 > 65535 then
				l_h := (65535 - a_y.to_natural_32).to_natural_16
			else
				l_h := a_height
			end
			height := l_h
		ensure
			x_set: x = a_x
			y_set: y = a_y
			bounded_width: x.to_natural_32 + width.to_natural_32 <= 65535
			bounded_height: y.to_natural_32 + height.to_natural_32 <= 65535
		end

feature -- Access

	x: NATURAL_16
			-- 0-based column coordinate of top-left corner

	y: NATURAL_16
			-- 0-based row coordinate of top-left corner

	width: NATURAL_16
			-- Number of columns

	height: NATURAL_16
			-- Number of rows

	left: NATURAL_16
			-- Left boundary
		do
			Result := x
		end

	top: NATURAL_16
			-- Top boundary
		do
			Result := y
		end

	right: NATURAL_16
			-- Right boundary (exclusive)
		do
			Result := x + width
		end

	bottom: NATURAL_16
			-- Bottom boundary (exclusive)
		do
			Result := y + height
		end

	area: NATURAL_32
			-- Total cell count covered by rectangle
		do
			Result := width.to_natural_32 * height.to_natural_32
		end

feature -- Status report

	is_empty: BOOLEAN
			-- Does rectangle have zero area?
		do
			Result := width = 0 or height = 0
		end

	contains_point (a_col, a_row: NATURAL_16): BOOLEAN
			-- Is point (`a_col`, `a_row`) within this rectangle?
		do
			Result := a_col >= x and a_col < right and a_row >= y and a_row < bottom
		end

	contains_rect (a_other: RECT): BOOLEAN
			-- Is `a_other` completely enclosed within this rectangle?
		do
			if a_other.is_empty then
				Result := True
			else
				Result := a_other.x >= x and a_other.right <= right and
					a_other.y >= y and a_other.bottom <= bottom
			end
		end

	intersects (a_other: RECT): BOOLEAN
			-- Does this rectangle overlap with `a_other`?
		do
			if is_empty or a_other.is_empty then
				Result := False
			else
				Result := x < a_other.right and right > a_other.x and
					y < a_other.bottom and bottom > a_other.y
			end
		end

feature -- Geometric operations

	intersection (a_other: RECT): RECT
			-- Intersection of `Current` and `a_other`.
			-- Returns an empty rectangle if they do not intersect.
		local
			l_x1, l_x2, l_y1, l_y2: NATURAL_16
		do
			if intersects (a_other) then
				l_x1 := x.max (a_other.x)
				l_x2 := right.min (a_other.right)
				l_y1 := y.max (a_other.y)
				l_y2 := bottom.min (a_other.bottom)
				create Result.make (l_x1, l_y1, l_x2 - l_x1, l_y2 - l_y1)
			else
				create Result.default_create
			end
		ensure
			result_contained: is_empty or contains_rect (Result)
		end

	union (a_other: RECT): RECT
			-- Minimal bounding rectangle enclosing both `Current` and `a_other`.
		local
			l_x1, l_x2, l_y1, l_y2: NATURAL_16
		do
			if is_empty then
				Result := a_other
			elseif a_other.is_empty then
				Result := Current
			else
				l_x1 := x.min (a_other.x)
				l_x2 := right.max (a_other.right)
				l_y1 := y.min (a_other.y)
				l_y2 := bottom.max (a_other.bottom)
				create Result.make (l_x1, l_y1, l_x2 - l_x1, l_y2 - l_y1)
			end
		ensure
			contains_current: Result.contains_rect (Current)
			contains_other: Result.contains_rect (a_other)
		end

	inner (a_h_margin, a_v_margin: NATURAL_16): RECT
			-- Deflate rectangle by horizontal and vertical margins (empty when they do not fit).
		local
			l_w, l_h: NATURAL_16
			l_x, l_y: NATURAL_16
		do
			if width.to_natural_32 > a_h_margin.to_natural_32 * 2 then
				l_x := x + a_h_margin
				l_w := (width.to_natural_32 - a_h_margin.to_natural_32 * 2).to_natural_16
			else
				l_x := x
				l_w := 0
			end

			if height.to_natural_32 > a_v_margin.to_natural_32 * 2 then
				l_y := y + a_v_margin
				l_h := (height.to_natural_32 - a_v_margin.to_natural_32 * 2).to_natural_16
			else
				l_y := y
				l_h := 0
			end
			create Result.make (l_x, l_y, l_w, l_h)
		ensure
			result_contained: contains_rect (Result)
		end

	offset (a_dx, a_dy: INTEGER_16): RECT
			-- Translate rectangle by `a_dx` and `a_dy`, clamping coordinates to [0, 65535].
		local
			l_new_x, l_new_y: INTEGER_32
			l_new_w, l_new_h: NATURAL_16
			l_final_x, l_final_y: NATURAL_16
		do
			l_new_x := x.to_integer_32 + a_dx.to_integer_32
			l_new_y := y.to_integer_32 + a_dy.to_integer_32
			if l_new_x < 0 then
				l_final_x := 0
			elseif l_new_x > 65535 then
				l_final_x := 65535
			else
				l_final_x := l_new_x.to_natural_16
			end

			if l_new_y < 0 then
				l_final_y := 0
			elseif l_new_y > 65535 then
				l_final_y := 65535
			else
				l_final_y := l_new_y.to_natural_16
			end

			l_new_w := width
			if l_final_x.to_natural_32 + l_new_w.to_natural_32 > 65535 then
				l_new_w := (65535 - l_final_x.to_natural_32).to_natural_16
			end

			l_new_h := height
			if l_final_y.to_natural_32 + l_new_h.to_natural_32 > 65535 then
				l_new_h := (65535 - l_final_y.to_natural_32).to_natural_16
			end

			create Result.make (l_final_x, l_final_y, l_new_w, l_new_h)
		end

	clamp (a_bounds: RECT): RECT
			-- This rectangle moved (not cut) so that it lies inside `a_bounds`, shrunk only when it
			-- is larger than `a_bounds` (Ratatui `Rect::clamp`).
		local
			l_w, l_h, l_x, l_y: NATURAL_16
		do
			l_w := width.min (a_bounds.width)
			l_h := height.min (a_bounds.height)
			l_x := x.max (a_bounds.x).min (a_bounds.right - l_w)
			l_y := y.max (a_bounds.y).min (a_bounds.bottom - l_h)
			create Result.make (l_x, l_y, l_w, l_h)
		ensure
			clamped_in_bounds: a_bounds.contains_rect (Result) or Result.is_empty
			size_kept_when_possible: Result.width = width.min (a_bounds.width) and Result.height = height.min (a_bounds.height)
		end

	centered (a_width, a_height: NATURAL_16): RECT
			-- Center a sub-rectangle of given dimensions within `Current`.
		local
			l_w, l_h: NATURAL_16
			l_cx, l_cy: NATURAL_16
		do
			l_w := a_width.min (width)
			l_h := a_height.min (height)
			l_cx := x + (width - l_w) // 2
			l_cy := y + (height - l_h) // 2
			create Result.make (l_cx, l_cy, l_w, l_h)
		ensure
			centered_in_current: contains_rect (Result)
		end

	rows: ARRAYED_LIST [RECT]
			-- Slices of rectangle divided into 1-row strips.
		local
			r: NATURAL_16
		do
			create Result.make (height.to_integer_32)
			from
				r := 0
			until
				r >= height
			loop
				Result.extend (create {RECT}.make (x, y + r, width, 1))
				r := r + 1
			end
		ensure
			count_matches_height: Result.count = height.to_integer_32
		end

	columns: ARRAYED_LIST [RECT]
			-- Slices of rectangle divided into 1-column strips.
		local
			c: NATURAL_16
		do
			create Result.make (width.to_integer_32)
			from
				c := 0
			until
				c >= width
			loop
				Result.extend (create {RECT}.make (x + c, y, 1, height))
				c := c + 1
			end
		ensure
			count_matches_width: Result.count = width.to_integer_32
		end

	positions: ARRAYED_LIST [TUPLE [x, y: NATURAL_16]]
			-- List of all (col, row) coordinate pairs covered by this rectangle.
		local
			r, c: NATURAL_16
		do
			create Result.make (area.to_integer_32)
			from
				r := 0
			until
				r >= height
			loop
				from
					c := 0
				until
					c >= width
				loop
					Result.extend ([x + c, y + r])
					c := c + 1
				end
				r := r + 1
			end
		ensure
			count_matches_area: Result.count = area.to_integer_32
		end

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Is `Current` geometrically identical to `a_other`?
		do
			Result := x = a_other.x and y = a_other.y and
				width = a_other.width and height = a_other.height
		end

feature -- Output

	out: STRING_8
			-- String representation of rectangle
		do
			Result := "Rect(" + x.out + "," + y.out + " " + width.out + "x" + height.out + ")"
		end

invariant
	valid_horizontal_bounds: x.to_natural_32 + width.to_natural_32 <= 65535
	valid_vertical_bounds: y.to_natural_32 + height.to_natural_32 <= 65535

end
