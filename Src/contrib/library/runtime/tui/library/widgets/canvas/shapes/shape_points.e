note
	description: "[
		Point set shape in world coordinates with styling.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	SHAPE_POINTS

inherit
	SHAPE
		redefine
			copy,
			is_equal
		end

create
	make

feature {NONE} -- Initialization

	make (a_points: ITERABLE [TUPLE [x, y: REAL_64]]; a_style: STYLE)
			-- Initialize point set with `a_points` and `a_style`.
		require
			points_not_void: a_points /= Void
			style_not_void: a_style /= Void
		do
			create points.make (8)
			across
				a_points as pt
			loop
				points.extend (pt)
			end
			style := a_style
		ensure
			style_set: style = a_style
		end

feature -- Access

	points: ARRAYED_LIST [TUPLE [x, y: REAL_64]]
			-- Coordinates in world space

	style: STYLE
			-- Points styling

feature -- Execution

	paint (a_painter: CANVAS_PAINTER)
			-- Paint points using `a_painter`.
		do
			a_painter.set_style (style)
			across
				points as pt
			loop
				a_painter.draw_point (pt.x, pt.y)
			end
		end

feature -- Duplication

	copy (a_other: like Current)
			-- Re-create points list on copy.
		do
			if a_other /= Current then
				standard_copy (a_other)
				points := a_other.points.twin
			end
		end

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Is `a_other` equal to `Current`?
		local
			i: INTEGER
		do
			if a_other = Current then
				Result := True
			elseif standard_is_equal (a_other) then
				Result := True
			elseif style.is_equal (a_other.style) and points.count = a_other.points.count then
				Result := True
				from
					i := 1
				until
					i > points.count or not Result
				loop
					Result := points [i].x = a_other.points [i].x and points [i].y = a_other.points [i].y
					i := i + 1
				end
			end
		end

invariant
	points_not_void: points /= Void
	style_not_void: style /= Void

end
