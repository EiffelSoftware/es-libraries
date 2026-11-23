note
	description: "[
		Resolutions of the SHAPE_MAP world map (Ratatui `canvas::MapResolution`): how many points
		are used to draw it. Low (the default, 1 166 points) and High (5 125 points; best with the
		Braille or Octant marker). The points are in WORLD_MAP_DATA.
		A reference class of constants, as CHART_GRAPH_TYPE.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	MAP_RESOLUTION

feature -- Constants

	low: NATURAL_8 = 1
			-- About 1 000 points (Ratatui `MapResolution::Low`, the default).

	high: NATURAL_8 = 2
			-- About 5 000 points (Ratatui `MapResolution::High`).

feature -- Status report

	is_valid (a_resolution: NATURAL_8): BOOLEAN
			-- Is `a_resolution` a recognized map resolution?
		do
			Result := a_resolution = low or a_resolution = high
		ensure
			instance_free: class
			definition: Result = (a_resolution = low or a_resolution = high)
		end

	is_valid_name (a_name: READABLE_STRING_GENERAL): BOOLEAN
			-- Is `a_name` the name of a map resolution ("Low" or "High", case-sensitive as Ratatui's
			-- `FromStr`)?
		require
			name_not_void: a_name /= Void
		do
			Result := a_name.same_string ("Low") or a_name.same_string ("High")
		ensure
			instance_free: class
		end

feature -- Access

	name (a_resolution: NATURAL_8): STRING
			-- Name of `a_resolution`: "Low" or "High" (Ratatui `Display`).
		require
			valid_resolution: is_valid (a_resolution)
		do
			if a_resolution = high then
				Result := "High"
			else
				Result := "Low"
			end
		ensure
			instance_free: class
			named: is_valid_name (Result)
		end

	from_name (a_name: READABLE_STRING_GENERAL): NATURAL_8
			-- Resolution named `a_name` (Ratatui `FromStr`).
		require
			name_not_void: a_name /= Void
			valid_name: is_valid_name (a_name)
		do
			if a_name.same_string ("High") then
				Result := high
			else
				Result := low
			end
		ensure
			instance_free: class
			valid: is_valid (Result)
			round_trip: name (Result).same_string_general (a_name)
		end

	point_count (a_resolution: NATURAL_8): INTEGER
			-- Number of points of the map at `a_resolution`.
		require
			valid_resolution: is_valid (a_resolution)
		do
			if a_resolution = high then
				Result := {WORLD_MAP_DATA}.High_resolution_count
			else
				Result := {WORLD_MAP_DATA}.Low_resolution_count
			end
		ensure
			instance_free: class
			positive: Result > 0
		end

	points (a_resolution: NATURAL_8): SPECIAL [REAL_64]
			-- Points of the map at `a_resolution`, longitude and latitude interleaved (WORLD_MAP_DATA).
			-- Shared: do not change it.
		require
			valid_resolution: is_valid (a_resolution)
		do
			if a_resolution = high then
				Result := {WORLD_MAP_DATA}.high_resolution
			else
				Result := {WORLD_MAP_DATA}.low_resolution
			end
		ensure
			instance_free: class
			count: Result.count = 2 * point_count (a_resolution)
		end

end
