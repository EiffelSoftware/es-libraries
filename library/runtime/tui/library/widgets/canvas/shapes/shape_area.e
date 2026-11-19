note
	description: "[
		Polygon shape in world coordinates with styling (Ratatui `canvas::Area`): the outline, and
		with `is_filled` the interior by the even-odd rule. The polygon may be convex, concave or
		self-intersecting; the last vertex joins the first. It is clipped to the canvas bounds by
		Sutherland-Hodgman ({CANVAS_PAINTER}.draw_polygon).

		Bridge artifact (as in Ratatui): a concave polygon that the bounds split into separate visible
		parts is clipped into one polygon, so its outline also runs along the border between the parts,
		where separate polygons would be correct.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	SHAPE_AREA

inherit
	SHAPE
		redefine
			copy,
			is_equal
		end

create
	make

feature {NONE} -- Initialization

	make (a_vertices: ITERABLE [TUPLE [x, y: REAL_64]]; a_style: STYLE; a_fill: BOOLEAN)
			-- Initialize polygon with `a_vertices` and `a_style`; fill its interior when `a_fill`.
			-- The vertices are copied into new tuples, so later changes to `a_vertices` do not show.
		require
			vertices_not_void: a_vertices /= Void
			style_not_void: a_style /= Void
		do
			create vertices.make (8)
			across
				a_vertices as v
			loop
				vertices.extend ([v.x, v.y])
			end
			style := a_style
			is_filled := a_fill
		ensure
			style_set: style = a_style
			fill_set: is_filled = a_fill
		end

feature -- Access

	vertices: ARRAYED_LIST [TUPLE [x, y: REAL_64]]
			-- Polygon vertices in world space, in boundary order

	style: STYLE
			-- Outline and fill styling

feature -- Status report

	is_filled: BOOLEAN
			-- Is the interior filled (Ratatui `fill`), not only the outline drawn?

feature -- Execution

	paint (a_painter: CANVAS_PAINTER)
			-- Paint polygon using `a_painter`.
		do
			a_painter.set_style (style)
			a_painter.draw_polygon (vertices, is_filled)
		end

feature -- Duplication

	copy (a_other: like Current)
			-- Re-create vertex list on copy.
		do
			if a_other /= Current then
				standard_copy (a_other)
				vertices := a_other.vertices.twin
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
			elseif is_filled = a_other.is_filled and style.is_equal (a_other.style)
				and vertices.count = a_other.vertices.count
			then
				Result := True
				from
					i := 1
				until
					i > vertices.count or not Result
				loop
					Result := vertices [i].x = a_other.vertices [i].x and vertices [i].y = a_other.vertices [i].y
					i := i + 1
				end
			end
		end

invariant
	vertices_not_void: vertices /= Void
	style_not_void: style /= Void

end
