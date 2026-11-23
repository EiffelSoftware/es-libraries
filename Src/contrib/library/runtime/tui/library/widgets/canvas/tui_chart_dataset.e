note
	description: "[
		Dataset series for TUI_CHART, storing 2D (x, y) points, graph type (line, scatter,
		bar, area), the Y an area is filled to, styling, and series name.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_CHART_DATASET

inherit
	ANY
		redefine
			copy,
			is_equal
		end

create
	make,
	make_with_data

feature {NONE} -- Initialization

	make (a_name: READABLE_STRING_GENERAL)
			-- Initialize dataset with `a_name`.
		require
			name_not_void: a_name /= Void
		do
			create name.make_from_string_general (a_name)
			create data.make (10)
			create style.default_create
			is_line := True
			graph_type := {CHART_GRAPH_TYPE}.line
			marker := {CANVAS_MARKER}.braille
			marker_char := (8226).to_character_32 -- '•'
			fill_to_y := 0.0
		ensure
			name_set: name.same_string_general (a_name)
			is_line_default: is_line = True
			graph_type_default: graph_type = {CHART_GRAPH_TYPE}.line
			marker_default: marker = {CANVAS_MARKER}.braille
			fill_to_y_default: fill_to_y = 0.0
		end

	make_with_data (a_name: READABLE_STRING_GENERAL; a_data: ITERABLE [TUPLE [x, y: REAL_64]])
			-- Initialize dataset with `a_name` and points `a_data`.
		require
			name_not_void: a_name /= Void
			data_not_void: a_data /= Void
		do
			make (a_name)
			across
				a_data as pt
			loop
				data.extend (pt)
			end
		ensure
			name_set: name.same_string_general (a_name)
		end

feature -- Duplication

	copy (a_other: like Current)
			-- Copy `a_other` with its own list of points.
		do
			if a_other /= Current then
				standard_copy (a_other)
				data := a_other.data.twin
			end
		end

	is_equal (a_other: like Current): BOOLEAN
			-- Are all settings the same and the data equal?
		local
			i: INTEGER
			pt1, pt2: TUPLE [x, y: REAL_64]
		do
			if a_other = Current then
				Result := True
			elseif standard_is_equal (a_other) then
				Result := True
			elseif name.same_string (a_other.name)
				and style.is_equal (a_other.style)
				and is_line = a_other.is_line
				and graph_type = a_other.graph_type
				and marker = a_other.marker
				and marker_char = a_other.marker_char
				and fill_to_y = a_other.fill_to_y
				and data.count = a_other.data.count
			then
				Result := True
				from
					i := 1
				until
					i > data.count or not Result
				loop
					pt1 := data [i]
					pt2 := a_other.data [i]
					Result := pt1.x = pt2.x and pt1.y = pt2.y
					i := i + 1
				end
			end
		end

feature -- Access

	name: STRING_32
			-- Series name.

	data: ARRAYED_LIST [TUPLE [x, y: REAL_64]]
			-- List of (x, y) coordinates.

	style: STYLE
			-- Color and style for this dataset.

	is_line: BOOLEAN
			-- Should points be connected with a line? (True = line chart, False = scatter).

	graph_type: NATURAL_8
			-- Representation graph type ({CHART_GRAPH_TYPE}.line, scatter, bar, area).

	fill_to_y: REAL_64
			-- World Y that an {CHART_GRAPH_TYPE}.area plot fills to, below or above the line
			-- (Ratatui `Dataset::fill_to_y`, default 0.0; clamped to the chart's Y bounds when drawn).

	marker: NATURAL_8
			-- Marker type ({CANVAS_MARKER}.braille, dot, block, half_block, bar, quadrant, sextant,
			-- octant, custom).

	marker_char: CHARACTER_32
			-- Marker character for scatter points; with the Custom marker, the character drawn
			-- in every painted cell of the line or scatter plot (one column wide then).

feature -- Element Change

	append_point (a_x, a_y: REAL_64)
			-- Append coordinate (`a_x`, `a_y`) to series.
		do
			data.extend ([a_x, a_y])
		ensure
			one_more: data.count = old data.count + 1
		end

	set_style (a_style: STYLE)
			-- Set dataset style.
		require
			style_not_void: a_style /= Void
		do
			style := a_style
		ensure
			style_set: style = a_style
		end

	set_is_line (a_line: BOOLEAN)
			-- Set line connection mode.
		do
			is_line := a_line
			if a_line then
				graph_type := {CHART_GRAPH_TYPE}.line
			else
				graph_type := {CHART_GRAPH_TYPE}.scatter
			end
		ensure
			is_line_set: is_line = a_line
		end

	set_graph_type (a_type: NATURAL_8)
			-- Set graph representation type ({CHART_GRAPH_TYPE}.line, scatter, bar, area).
		require
			valid_type: {CHART_GRAPH_TYPE}.is_valid (a_type)
		do
			graph_type := a_type
			is_line := (a_type = {CHART_GRAPH_TYPE}.line)
		ensure
			graph_type_set: graph_type = a_type
		end

	set_fill_to_y (a_y: REAL_64)
			-- Set the world Y that an area plot fills to.
		require
			not_nan: not a_y.is_nan
		do
			fill_to_y := a_y
		ensure
			fill_to_y_set: fill_to_y = a_y
		end

	set_marker (a_marker: NATURAL_8)
			-- Set marker type ({CANVAS_MARKER}.braille, dot, block, half_block, bar, quadrant, sextant,
			-- octant, custom). `marker_char` becomes the marker's symbol; Custom keeps `marker_char`
			-- when it is one column wide, else uses {CANVAS_MARKER}.default_custom_char.
		require
			valid_marker: {CANVAS_MARKER}.is_valid (a_marker)
		do
			marker := a_marker
			if a_marker /= {CANVAS_MARKER}.custom then
				marker_char := {CANVAS_MARKER}.marker_symbol (a_marker)
			elseif not {CANVAS_MARKER}.is_valid_custom_char (marker_char) then
				marker_char := {CANVAS_MARKER}.default_custom_char
			end
		ensure
			marker_set: marker = a_marker
		end

	set_custom_marker (a_char: CHARACTER_32)
			-- Draw this dataset with the Custom marker, `a_char` in every painted cell.
		require
			one_column: {CANVAS_MARKER}.is_valid_custom_char (a_char)
		do
			marker := {CANVAS_MARKER}.custom
			marker_char := a_char
		ensure
			custom_marker: marker = {CANVAS_MARKER}.custom
			char_set: marker_char = a_char
		end

	set_marker_char (a_char: CHARACTER_32)
			-- Set scatter marker character.
		require
			one_column_when_custom: marker = {CANVAS_MARKER}.custom implies {CANVAS_MARKER}.is_valid_custom_char (a_char)
		do
			marker_char := a_char
		ensure
			marker_set: marker_char = a_char
		end

feature -- Fluent Builders

	with_style (a_style: STYLE): like Current
			-- Dataset with style `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_style (a_style)
		ensure
			result_is_copy: Result /= Current
		end

	with_line_mode (a_line: BOOLEAN): like Current
			-- Dataset with line mode `a_line`.
		do
			Result := twin
			Result.set_is_line (a_line)
		ensure
			result_is_copy: Result /= Current
		end

	with_graph_type (a_type: NATURAL_8): like Current
			-- Dataset with graph type `a_type`.
		require
			valid_type: {CHART_GRAPH_TYPE}.is_valid (a_type)
		do
			Result := twin
			Result.set_graph_type (a_type)
		ensure
			result_is_copy: Result /= Current
			graph_type_set: Result.graph_type = a_type
		end

	with_fill_to_y (a_y: REAL_64): like Current
			-- Dataset whose area plot fills to world Y `a_y`.
		require
			not_nan: not a_y.is_nan
		do
			Result := twin
			Result.set_fill_to_y (a_y)
		ensure
			result_is_copy: Result /= Current
			fill_to_y_set: Result.fill_to_y = a_y
		end

	with_marker (a_marker: NATURAL_8): like Current
			-- Dataset with marker `a_marker`.
		require
			valid_marker: {CANVAS_MARKER}.is_valid (a_marker)
		do
			Result := twin
			Result.set_marker (a_marker)
		ensure
			result_is_copy: Result /= Current
			marker_set: Result.marker = a_marker
		end

	with_custom_marker (a_char: CHARACTER_32): like Current
			-- Dataset with the Custom marker `a_char` (line and scatter plots).
		require
			one_column: {CANVAS_MARKER}.is_valid_custom_char (a_char)
		do
			Result := twin
			Result.set_custom_marker (a_char)
		ensure
			result_is_copy: Result /= Current
			custom_marker: Result.marker = {CANVAS_MARKER}.custom
			char_set: Result.marker_char = a_char
		end

	with_marker_char (a_char: CHARACTER_32): like Current
			-- Dataset with marker char `a_char`.
		require
			one_column_when_custom: marker = {CANVAS_MARKER}.custom implies {CANVAS_MARKER}.is_valid_custom_char (a_char)
		do
			Result := twin
			Result.set_marker_char (a_char)
		ensure
			result_is_copy: Result /= Current
		end

invariant
	name_not_void: name /= Void
	data_not_void: data /= Void
	style_not_void: style /= Void
	valid_marker: {CANVAS_MARKER}.is_valid (marker)
	fill_to_y_not_nan: not fill_to_y.is_nan
	one_column_custom_char: marker = {CANVAS_MARKER}.custom implies {CANVAS_MARKER}.is_valid_custom_char (marker_char)

end
