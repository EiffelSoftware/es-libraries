note
	description: "[
		A drawing layer for TUI_CANVAS, containing a set of shapes and/or a painter callback.
		Layers are stacked like Ratatui `Context::layer`: where a later layer draws, it sets the
		symbol and patches the style below with what it sets (Ratatui `LayerCell`), so a Block
		layer's bg stays under a later layer's symbol (see {TUI_CANVAS}.render). A layer may use its own `marker` (0: the canvas marker), and with the Custom
		marker its own `custom_marker_char`.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	CANVAS_LAYER

inherit
	ANY
		redefine
			copy,
			is_equal
		end

create
	make,
	make_with_shapes,
	make_with_painter

feature {NONE} -- Initialization

	make
			-- Initialize empty canvas layer.
		do
			create shapes.make (4)
			custom_marker_char := {CANVAS_MARKER}.default_custom_char
		ensure
			shapes_empty: shapes.is_empty
			no_painter: painter_agent = Void
			default_custom_char: custom_marker_char = {CANVAS_MARKER}.default_custom_char
		end

	make_with_shapes (a_shapes: ITERABLE [SHAPE])
			-- Initialize layer with `a_shapes`.
		require
			shapes_not_void: a_shapes /= Void
		do
			make
			across
				a_shapes as s
			loop
				shapes.extend (s)
			end
		end

	make_with_painter (a_painter: PROCEDURE [CANVAS_PAINTER])
			-- Initialize layer with `a_painter`.
		require
			painter_not_void: a_painter /= Void
		do
			make
			painter_agent := a_painter
		ensure
			painter_set: painter_agent = a_painter
		end

feature -- Duplication

	copy (a_other: like Current)
			-- Copy `a_other` with its own copies of the shapes.
		do
			if a_other /= Current then
				standard_copy (a_other)
				create shapes.make (a_other.shapes.count)
				across a_other.shapes as sh loop
					shapes.extend (sh.twin)
				end
			end
		end

	is_equal (a_other: like Current): BOOLEAN
			-- Are all settings the same and the shapes equal?
		local
			l_other: like Current
		do
			if a_other = Current then
				Result := True
			elseif shapes.count = a_other.shapes.count
				and then across shapes as sh all sh.is_equal (a_other.shapes [@sh.cursor_index]) end
			then
				l_other := a_other.standard_twin
				l_other.share_shapes (shapes)
				Result := standard_is_equal (l_other)
			end
		end

feature {CANVAS_LAYER} -- Duplication

	share_shapes (a_shapes: like shapes)
			-- Use `a_shapes` as the list of shapes (for `is_equal`).
		do
			shapes := a_shapes
		end

feature -- Access

	shapes: ARRAYED_LIST [SHAPE]
			-- Shapes in this layer

	painter_agent: detachable PROCEDURE [CANVAS_PAINTER]
			-- Agent callback performing custom drawing on this layer

	marker: NATURAL_8
			-- Marker of this layer ({CANVAS_MARKER}), or 0 to use the canvas marker

	custom_marker_char: CHARACTER_32
			-- Character of this layer when `marker` is {CANVAS_MARKER}.custom. One column wide.
			-- (With `marker` 0 the canvas marker and its character are used.)

feature -- Element change

	add_shape (a_shape: SHAPE)
			-- Add `a_shape` to layer.
		require
			shape_not_void: a_shape /= Void
		do
			shapes.extend (a_shape)
		ensure
			one_more: shapes.count = old shapes.count + 1
			last_shape: shapes.last = a_shape
		end

	set_marker (a_marker: NATURAL_8)
			-- Draw this layer with `a_marker` (0: the canvas marker).
			-- Custom keeps `custom_marker_char` ({CANVAS_MARKER}.default_custom_char unless
			-- `set_custom_marker` gave another one).
		require
			valid_marker: a_marker = 0 or else {CANVAS_MARKER}.is_valid (a_marker)
		do
			marker := a_marker
		ensure
			marker_set: marker = a_marker
		end

	set_custom_marker (a_char: CHARACTER_32)
			-- Draw this layer with the Custom marker, `a_char` in every painted cell.
		require
			one_column: {CANVAS_MARKER}.is_valid_custom_char (a_char)
		do
			marker := {CANVAS_MARKER}.custom
			custom_marker_char := a_char
		ensure
			custom_marker: marker = {CANVAS_MARKER}.custom
			char_set: custom_marker_char = a_char
		end

	set_painter (a_painter: detachable PROCEDURE [CANVAS_PAINTER])
			-- Set custom painter agent.
		do
			painter_agent := a_painter
		ensure
			painter_set: painter_agent = a_painter
		end

feature -- Fluent Builders

	with_custom_marker (a_char: CHARACTER_32): like Current
			-- Layer with the Custom marker `a_char` (with its own copies of the shapes).
		require
			one_column: {CANVAS_MARKER}.is_valid_custom_char (a_char)
		do
			Result := twin
			Result.set_custom_marker (a_char)
		ensure
			custom_marker: Result.marker = {CANVAS_MARKER}.custom
			char_set: Result.custom_marker_char = a_char
		end

feature -- Execution

	paint (a_painter: CANVAS_PAINTER)
			-- Paint this layer onto `a_painter`.
		require
			painter_not_void: a_painter /= Void
		do
			if attached painter_agent as p then
				p.call ([a_painter])
			end
			across
				shapes as s
			loop
				s.paint (a_painter)
			end
		end

invariant
	shapes_not_void: shapes /= Void
	valid_marker: marker = 0 or else {CANVAS_MARKER}.is_valid (marker)
	one_column_custom_char: {CANVAS_MARKER}.is_valid_custom_char (custom_marker_char)

end
