note
	description: "[
		Canvas widget allowing arbitrary 2D vector drawing and plotting using
		sub-pixel Unicode Braille patterns (U+2800..U+28FF) and agent-based painters.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_CANVAS

inherit
	WIDGET
		redefine
			copy,
			is_equal
		end
	BLOCK_CONTAINER
		redefine
			copy,
			is_equal
		end

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize canvas widget with default [0.0, 1.0] coordinate bounds.
		do
			set_block (Void)
			x_bounds := [0.0, 1.0]
			y_bounds := [0.0, 1.0]
			create background_style.default_create
			create shape_store.make (4)
			create layer_store.make (2)
			marker := {CANVAS_MARKER}.braille
			color_policy := {BRAILLE_CANVAS}.policy_last_wins
		ensure
			x_min_default: x_bounds.min = 0.0
			x_max_default: x_bounds.max = 1.0
			y_min_default: y_bounds.min = 0.0
			y_max_default: y_bounds.max = 1.0
			shapes_empty: shapes.is_empty
			layers_empty: layers.is_empty
			default_marker: marker = {CANVAS_MARKER}.braille
			no_block: block = Void
		end

feature -- Duplication

	copy (a_other: like Current)
			-- Re-create shapes and layers on copy.
			-- Shapes and layers are copied on write (see `shapes`, `layers`); rendering never
			-- copies them.
		do
			if a_other /= Current then
				standard_copy (a_other)
				shapes_shared := True
				a_other.mark_shapes_shared
				layers_shared := True
				a_other.mark_layers_shared
			end
		end

	is_equal (a_other: like Current): BOOLEAN
			-- Is `a_other` content-equal to `Current`?
		local
			i: INTEGER
		do
			if a_other = Current then
				Result := True
			elseif standard_is_equal (a_other) then
				Result := True
			elseif x_bounds.min = a_other.x_bounds.min
				and x_bounds.max = a_other.x_bounds.max
				and y_bounds.min = a_other.y_bounds.min
				and y_bounds.max = a_other.y_bounds.max
				and marker = a_other.marker
				and color_policy = a_other.color_policy
				and same_block (a_other)
				and background_style.is_equal (a_other.background_style)
				and painter_agent = a_other.painter_agent
				and shape_store.count = a_other.shape_store.count
				and layer_store.count = a_other.layer_store.count
			then
				Result := True
				from
					i := 1
				until
					i > shape_store.count or not Result
				loop
					Result := shape_store [i].is_equal (a_other.shape_store [i])
					i := i + 1
				end
				if Result then
					from
						i := 1
					until
						i > layer_store.count or not Result
					loop
						Result := layer_store [i].is_equal (a_other.layer_store [i])
						i := i + 1
					end
				end
			end
		end

feature {TUI_CANVAS} -- Copy on write

	shape_store: ARRAYED_LIST [SHAPE]
			-- Shapes, possibly shared with copies of `Current` (see `shapes_shared`)

	shapes_shared: BOOLEAN
			-- Is `shape_store` shared with another object?

	mark_shapes_shared
			-- Record that `shape_store` is now shared with a copy.
		do
			shapes_shared := True
		ensure
			shared: shapes_shared
		end

	own_shapes
			-- Give `Current` its own copy of the shapes if they are shared.
		do
			if shapes_shared then
				shape_store := copied_shapes (shape_store)
				shapes_shared := False
			end
		ensure
			not_shared: not shapes_shared
		end

feature {TUI_CANVAS} -- Copy on write

	layer_store: ARRAYED_LIST [CANVAS_LAYER]
			-- Layers, possibly shared with copies of `Current` (see `layers_shared`)

	layers_shared: BOOLEAN
			-- Is `layer_store` shared with another object?

	mark_layers_shared
			-- Record that `layer_store` is now shared with a copy.
		do
			layers_shared := True
		ensure
			shared: layers_shared
		end

	own_layers
			-- Give `Current` its own copy of the layers if they are shared.
		do
			if layers_shared then
				layer_store := copied_layers (layer_store)
				layers_shared := False
			end
		ensure
			not_shared: not layers_shared
		end

feature {NONE} -- Copy on write

	copied_shapes (a_list: ARRAYED_LIST [SHAPE]): ARRAYED_LIST [SHAPE]
			-- Copy of `a_list` holding copies of its elements
		do
			create Result.make (a_list.count)
			across a_list as e loop
				Result.extend (e.twin)
			end
		end

	copied_layers (a_list: ARRAYED_LIST [CANVAS_LAYER]): ARRAYED_LIST [CANVAS_LAYER]
			-- Copy of `a_list` holding copies of its elements
		do
			create Result.make (a_list.count)
			across a_list as e loop
				Result.extend (e.twin)
			end
		end

feature -- Access

	x_bounds: TUPLE [min, max: REAL_64]
			-- World coordinate X bounds [min, max].

	y_bounds: TUPLE [min, max: REAL_64]
			-- World coordinate Y bounds [min, max].

	painter_agent: detachable PROCEDURE [CANVAS_PAINTER]
			-- Agent callback performing the drawing operations.

	shapes: ARRAYED_LIST [SHAPE]
			-- Vector shapes drawn on canvas (owned by `Current`: content still shared with a copy is copied first)
		do
			own_shapes
			Result := shape_store
		ensure
			owned: not shapes_shared
		end

	layers: ARRAYED_LIST [CANVAS_LAYER]
			-- Drawing layers composed on canvas (owned by `Current`: content still shared with a copy is copied first)
		do
			own_layers
			Result := layer_store
		ensure
			owned: not layers_shared
		end

	marker: NATURAL_8
			-- Marker type for subpixel dots ({CANVAS_MARKER}.braille, dot, block, etc.).

	color_policy: NATURAL_8
			-- Subpixel dot color resolution policy ({BRAILLE_CANVAS}.policy_last_wins or first_wins).

	background_style: STYLE
			-- Default canvas background style.

feature -- Configuration

	set_bounds (a_x_min, a_x_max, a_y_min, a_y_max: REAL_64)
			-- Set world coordinate bounds.
		require
			valid_x_range: a_x_min < a_x_max
			valid_y_range: a_y_min < a_y_max
		do
			x_bounds := [a_x_min, a_x_max]
			y_bounds := [a_y_min, a_y_max]
		ensure
			x_bounds_set: x_bounds.min = a_x_min and x_bounds.max = a_x_max
			y_bounds_set: y_bounds.min = a_y_min and y_bounds.max = a_y_max
		end

	set_painter (a_painter: detachable PROCEDURE [CANVAS_PAINTER])
			-- Set drawing routine agent.
		do
			painter_agent := a_painter
		ensure
			painter_set: painter_agent = a_painter
		end

	set_background_style (a_style: STYLE)
			-- Set canvas background style.
		require
			style_not_void: a_style /= Void
		do
			background_style := a_style
		ensure
			style_set: background_style = a_style
		end

	add_shape (a_shape: SHAPE)
			-- Add vector `a_shape` to canvas.
		require
			shape_not_void: a_shape /= Void
		do
			shapes.extend (a_shape)
		ensure
			one_more: shapes.count = old shapes.count + 1
			last_shape: shapes.last = a_shape
		end

	add_layer (a_layer: CANVAS_LAYER)
			-- Add drawing `a_layer` to canvas.
		require
			layer_not_void: a_layer /= Void
		do
			layers.extend (a_layer)
		ensure
			one_more: layers.count = old layers.count + 1
			last_layer: layers.last = a_layer
		end

	set_marker (a_marker: NATURAL_8)
			-- Set marker type ({CANVAS_MARKER}.braille, dot, block, etc.).
		require
			valid_marker: {CANVAS_MARKER}.is_valid (a_marker)
		do
			marker := a_marker
		ensure
			marker_set: marker = a_marker
		end

	set_color_policy (a_policy: NATURAL_8)
			-- Set color resolution policy ({BRAILLE_CANVAS}.policy_last_wins or first_wins).
		require
			valid_policy: a_policy = {BRAILLE_CANVAS}.policy_last_wins or a_policy = {BRAILLE_CANVAS}.policy_first_wins
		do
			color_policy := a_policy
		ensure
			policy_set: color_policy = a_policy
		end

feature -- Fluent Builders

	with_bounds (a_x_min, a_x_max, a_y_min, a_y_max: REAL_64): like Current
			-- Canvas with bounds `[a_x_min, a_x_max]`, `[a_y_min, a_y_max]`.
		require
			valid_x_range: a_x_min < a_x_max
			valid_y_range: a_y_min < a_y_max
		do
			Result := twin
			Result.set_bounds (a_x_min, a_x_max, a_y_min, a_y_max)
		ensure
			x_bounds_set: Result.x_bounds.min = a_x_min and Result.x_bounds.max = a_x_max
			y_bounds_set: Result.y_bounds.min = a_y_min and Result.y_bounds.max = a_y_max
		end

	with_painter (a_painter: PROCEDURE [CANVAS_PAINTER]): like Current
			-- Canvas with painter agent `a_painter`.
		require
			painter_not_void: a_painter /= Void
		do
			Result := twin
			Result.set_painter (a_painter)
		ensure
			painter_set: Result.painter_agent = a_painter
		end

	with_background_style (a_style: STYLE): like Current
			-- Canvas with background style `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_background_style (a_style)
		ensure
			style_set: Result.background_style = a_style
		end

	with_shape (a_shape: SHAPE): like Current
			-- Canvas with added `a_shape`.
		require
			shape_not_void: a_shape /= Void
		do
			Result := twin
			Result.add_shape (a_shape)
		end

	with_layer (a_layer: CANVAS_LAYER): like Current
			-- Canvas with added `a_layer`.
		require
			layer_not_void: a_layer /= Void
		do
			Result := twin
			Result.add_layer (a_layer)
		end

	with_marker (a_marker: NATURAL_8): like Current
			-- Canvas with `a_marker`.
		require
			valid_marker: {CANVAS_MARKER}.is_valid (a_marker)
		do
			Result := twin
			Result.set_marker (a_marker)
		ensure
			marker_set: Result.marker = a_marker
		end

	with_color_policy (a_policy: NATURAL_8): like Current
			-- Canvas with `a_policy`.
		require
			valid_policy: a_policy = {BRAILLE_CANVAS}.policy_last_wins or a_policy = {BRAILLE_CANVAS}.policy_first_wins
		do
			Result := twin
			Result.set_color_policy (a_policy)
		ensure
			policy_set: Result.color_policy = a_policy
		end

feature -- Rendering

	render (a_area: RECT; a_buffer: BUFFER)
			-- Render canvas inside `a_area` into `a_buffer`.
			-- The painter agent and the direct shapes form the base layer; each CANVAS_LAYER is
			-- painted on its own grid and stacked on top (a cell a later layer draws in replaces the
			-- cell below, as with Ratatui `Context::layer`). Each grid has the resolution of its
			-- marker: Braille 2 x 4 dots per cell, HalfBlock 1 x 2, Dot / Block / Bar 1 x 1.
			-- Text drawn with `draw_text` is clipped to the canvas area.
		local
			l_target: RECT
			l_grids: ARRAYED_LIST [TUPLE [grid: BRAILLE_CANVAS; marker: NATURAL_8]]
			l_painters: ARRAYED_LIST [CANVAS_PAINTER]
			l_painter: CANVAS_PAINTER
			l_grid: BRAILLE_CANVAS
			l_marker: NATURAL_8
			r, c, l_abs_row, l_abs_col, l_rows, l_cols, l_left, l_right: INTEGER
		do
			if not a_area.is_empty then
				render_block (a_area, a_buffer)
				l_target := inner_area (a_area)

				if not l_target.is_empty then
					l_cols := l_target.width.to_integer_32
					l_rows := l_target.height.to_integer_32
					l_left := l_target.x.to_integer_32
					l_right := l_target.right.to_integer_32
					create l_grids.make (1 + layer_store.count)
					create l_painters.make (1 + layer_store.count)

					-- Base layer: painter agent, then direct shapes
					l_grid := new_grid (l_cols, l_rows, marker)
					create l_painter.make (l_grid, x_bounds, y_bounds)
					if attached painter_agent as p then
						p.call ([l_painter])
					end
					across shape_store as sh loop
						sh.paint (l_painter)
					end
					l_grids.extend ([l_grid, marker])
					l_painters.extend (l_painter)

					-- Stacked layers
					across layer_store as lay loop
						if lay.marker /= 0 then
							l_marker := lay.marker
						else
							l_marker := marker
						end
						l_grid := new_grid (l_cols, l_rows, l_marker)
						create l_painter.make (l_grid, x_bounds, y_bounds)
						lay.paint (l_painter)
						l_grids.extend ([l_grid, l_marker])
						l_painters.extend (l_painter)
					end

					-- Background, then each grid's drawn cells over the grids below
					a_buffer.set_style (l_target, background_style)
					from
						r := 0
					until
						r >= l_rows or l_target.y.to_integer_32 + r >= a_buffer.height
					loop
						l_abs_row := l_target.y.to_integer_32 + r
						from
							c := 0
						until
							c >= l_cols or l_left + c >= a_buffer.width
						loop
							l_abs_col := l_left + c
							a_buffer.put_char (l_abs_row, l_abs_col, ' ', background_style)
							across l_grids as g loop
								if g.grid.cell_mask (c, r) /= 0 then
									a_buffer.put_char (l_abs_row, l_abs_col, cell_glyph (g.grid, g.marker, c, r),
										background_style.patch (g.grid.cell_style (c, r)))
								end
							end
							c := c + 1
						end
						r := r + 1
					end

					-- Text overlays, clipped to the canvas area
					across l_painters as pt loop
						across pt.text_overlays as ov loop
							l_abs_row := l_target.y.to_integer_32 + ov.row
							if ov.row >= 0 and ov.row < l_rows and l_abs_row < a_buffer.height then
								a_buffer.set_string_clipped (l_abs_row, l_left + ov.col, ov.text, l_left, l_right, ov.style)
							end
						end
					end
				end
			end
		end

feature {NONE} -- Implementation

	new_grid (a_cols, a_rows: INTEGER; a_marker: NATURAL_8): BRAILLE_CANVAS
			-- Empty grid for `a_marker` (Braille 2 x 4 dots per cell, HalfBlock 1 x 2, others 1 x 1)
		do
			if a_marker = {CANVAS_MARKER}.half_block then
				create Result.make_with_resolution (a_cols, a_rows, 1, 2)
			elseif a_marker = {CANVAS_MARKER}.braille then
				create Result.make (a_cols, a_rows)
			else
				create Result.make_with_resolution (a_cols, a_rows, 1, 1)
			end
			Result.set_color_policy (color_policy)
		end

	cell_glyph (a_grid: BRAILLE_CANVAS; a_marker: NATURAL_8; a_col, a_row: INTEGER): CHARACTER_32
			-- Character for the drawn cell (`a_col`, `a_row`) of `a_grid` with `a_marker`
		require
			drawn: a_grid.cell_mask (a_col, a_row) /= 0
		do
			if a_marker = {CANVAS_MARKER}.braille then
				Result := a_grid.cell_char (a_col, a_row)
			elseif a_marker = {CANVAS_MARKER}.half_block then
				inspect a_grid.cell_mask (a_col, a_row)
				when 1 then
					Result := (0x2580).to_character_32 -- '▀' upper half
				when 2 then
					Result := (0x2584).to_character_32 -- '▄' lower half
				else
					Result := (0x2588).to_character_32 -- '█' both halves
				end
			else
				Result := {CANVAS_MARKER}.marker_symbol (a_marker)
			end
		end

invariant
	x_bounds_valid: x_bounds /= Void and then x_bounds.min < x_bounds.max
	y_bounds_valid: y_bounds /= Void and then y_bounds.min < y_bounds.max
	background_style_not_void: background_style /= Void
	shapes_not_void: shape_store /= Void
	layers_not_void: layer_store /= Void
	valid_marker: {CANVAS_MARKER}.is_valid (marker)

end
