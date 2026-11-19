note
	description: "[
		Graph representation types for TUI_CHART datasets (Line, Scatter, Bar, Area).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	CHART_GRAPH_TYPE

feature -- Constants

	line: NATURAL_8 = 1
			-- Line chart connecting points with Bresenham lines.

	scatter: NATURAL_8 = 2
			-- Scatter plot rendering points as markers.

	bar: NATURAL_8 = 3
			-- Vertical bar plot rendering columns from baseline to point Y.

	area: NATURAL_8 = 4
			-- Line chart with the area between the line and the dataset's `fill_to_y` filled
			-- (Ratatui `GraphType::Area`).

feature -- Status report

	is_valid (a_type: NATURAL_8): BOOLEAN
			-- Is `a_type` a recognized graph type?
		do
			Result := a_type = line or a_type = scatter or a_type = bar or a_type = area
		ensure
			instance_free: class
		end

end
