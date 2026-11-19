note
	description: "[
		World map shape (Ratatui `canvas::Map`): the coastlines of WORLD_MAP_DATA, one point each,
		in the EPSG:4326 coordinate reference system (x is the longitude, y the latitude).
		Use it on a canvas with bounds [-180, 180] x [-90, 90] for the whole world. Points outside
		the bounds are skipped (CANVAS_PAINTER.draw_point), so smaller bounds show a region.
		{MAP_RESOLUTION}.high is best with the Braille or Octant marker.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	SHAPE_MAP

inherit
	SHAPE
		redefine
			default_create,
			is_equal
		end

create
	make,
	default_create

feature {NONE} -- Initialization

	make (a_resolution: NATURAL_8; a_style: STYLE)
			-- Initialize map with `a_resolution` ({MAP_RESOLUTION}) and `a_style`.
		require
			valid_resolution: {MAP_RESOLUTION}.is_valid (a_resolution)
			style_not_void: a_style /= Void
		do
			resolution := a_resolution
			style := a_style
		ensure
			resolution_set: resolution = a_resolution
			style_set: style = a_style
		end

	default_create
			-- Initialize low resolution map with the default style (Ratatui `Map::default`:
			-- `MapResolution::Low`, `Color::Reset`).
		do
			make ({MAP_RESOLUTION}.low, create {STYLE}.default_create)
		ensure then
			low: resolution = {MAP_RESOLUTION}.low
		end

feature -- Access

	resolution: NATURAL_8
			-- Number of points used ({MAP_RESOLUTION}.low or `high`)

	style: STYLE
			-- Points styling

feature -- Execution

	paint (a_painter: CANVAS_PAINTER)
			-- Paint every map point inside the bounds using `a_painter`.
		local
			l_points: SPECIAL [REAL_64]
			i, n: INTEGER
		do
			a_painter.set_style (style)
			l_points := {MAP_RESOLUTION}.points (resolution)
			from
				n := l_points.count
			until
				i >= n
			loop
				a_painter.draw_point (l_points [i], l_points [i + 1])
				i := i + 2
			variant
				n - i
			end
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
				Result := resolution = a_other.resolution and style.is_equal (a_other.style)
			end
		end

invariant
	valid_resolution: {MAP_RESOLUTION}.is_valid (resolution)
	style_not_void: style /= Void

end
