note
	description: "[
		A short help text drawn in a box next to the control it describes, the anchor (P2 W6).
		Ratatui has no tooltip widget; apps draw one as a `Clear` and a `Block` next to the
		control, which is what this widget draws.

		    tip := (create {TUI_TOOLTIP}.make ("Wrap long lines at the window's edge", box_area))
		    frame.render_widget (tip, frame.area)

		The area given to `render` is the bounds the box must stay in (normally the whole
		frame), clipped to the buffer; the box is placed next to `anchor` by `placement`:
		  * Side: `preferred_side` (OVERLAY_PLACEMENT `below`, `above`, `right`, `left`;
		    `below` by default). OVERLAY_PLACEMENT, shared with TUI_MENU, flips the box to
		    the opposite side when it does not fit whole there, shifts it along the edge back
		    inside the bounds, and cuts it when it fits whole on neither side.
		  * Size: the text is word-wrapped (TEXT_LAYOUT, blanks trimmed at the breaks) to at
		    most `max_width` columns of box, borders included, and at most the bounds' width.
		    A word longer than that is broken between grapheme clusters. The box is as wide as
		    its widest row plus the borders, and one row per wrapped row plus the borders high.
		  * Cut: when the placed box is narrower than asked (a box left or right of the anchor
		    with less room), the text is wrapped again to its inside and the box placed again,
		    as tall as that needs. Rows that do not fit the box's height (a box cut above or
		    below the anchor, or taller than the bounds) are left out, the box closed after the
		    last one shown. A box with no inside (narrower or lower than 3 cells bordered, 1
		    borderless) is not drawn.

		Drawing: the box's cells are cleared first (TUI_CLEAR, as TUI_POPUP), then a TUI_BLOCK
		with `border_type` and `border_style` (when `is_bordered`) and `style` patched over the
		whole box, then the text, each row from the left of the inside, in the cell's style
		patched by the TEXT's, the line's and the span's styles.

		Render it last, over the rest. Two ways to show one, both up to the application: for
		the focused control (after F1, or always), which needs no mouse motion; and on hover,
		with {TUI_APPLICATION}.set_mouse_motion and a HOVER_STATE fed with `hit_test` on moves.

		Hit region: with a `hit_id` (HIT_TARGET), the box is registered under it, so a click
		on the tooltip does not reach the control under it, and moving the pointer onto the
		tooltip does not hover that control. Give the same id to {HOVER_STATE}.set_tooltip_id
		so the hover stays on the control the tooltip describes. Without one (the default)
		nothing is registered. The box is placed in the area given to `render`; FRAME
		registers it in that area too, so keep the area inside the frame (normally the
		frame's area) for the region to match the box drawn.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_TOOLTIP

inherit
	WIDGET
		redefine
			is_equal
		end

	HIT_TARGET
		redefine
			is_equal,
			hit_area
		end

create
	make,
	make_with_text

feature {NONE} -- Initialization

	make (a_text: READABLE_STRING_GENERAL; a_anchor: RECT)
			-- Tooltip showing `a_text` (split on %N) below `a_anchor`, at most
			-- `Default_max_width` columns wide, with a plain border.
		require
			text_not_void: a_text /= Void
			anchor_not_void: a_anchor /= Void
		do
			make_with_text (create {TEXT}.make_raw (a_text), a_anchor)
		ensure
			anchor_set: anchor = a_anchor
			below: preferred_side = {OVERLAY_PLACEMENT}.below
		end

	make_with_text (a_text: TEXT; a_anchor: RECT)
			-- Tooltip showing a copy of `a_text` below `a_anchor`, at most `Default_max_width`
			-- columns wide, with a plain border.
		require
			text_not_void: a_text /= Void
			anchor_not_void: a_anchor /= Void
		do
			text := a_text.twin
			anchor := a_anchor
			preferred_side := {OVERLAY_PLACEMENT}.below
			max_width := Default_max_width
			is_bordered := True
			border_type := {BORDER_TYPE}.plain
			create style
			create border_style
		ensure
			text_copied: text ~ a_text and text /= a_text
			anchor_set: anchor = a_anchor
			below: preferred_side = {OVERLAY_PLACEMENT}.below
			default_width: max_width = Default_max_width
			bordered: is_bordered
			plain: border_type = {BORDER_TYPE}.plain
		end

feature -- Access

	text: TEXT
			-- Help text (the tooltip's own copy)

	anchor: RECT
			-- Area of the control the tooltip describes, in the coordinates of the area
			-- given to `render` (frame coordinates)

	preferred_side: NATURAL_8
			-- Side of `anchor` the box goes on when it fits (OVERLAY_PLACEMENT)

	max_width: NATURAL_16
			-- Widest box, borders included

	is_bordered: BOOLEAN
			-- Is the box drawn with a border?

	border_type: NATURAL_8
			-- Corners and edges of a bordered box (BORDER_TYPE)

	style: STYLE
			-- Style patched over the whole box

	border_style: STYLE
			-- Style of the border, patched over `style`

	Default_max_width: NATURAL_16 = 40
			-- `max_width` of a new tooltip

	Minimum_width: NATURAL_16 = 3
			-- Narrowest `max_width`: two borders and one column of text

	hit_area (a_area: RECT; a_state: detachable WIDGET_STATE): RECT
			-- The box drawn in `a_area` (`placement` in it), registered under `hit_id`
		do
			Result := placement (anchor, a_area)
		end

	border_size: INTEGER
			-- Cells of border on each side of the box: 1 bordered, 0 borderless
		do
			if is_bordered then
				Result := 1
			end
		ensure
			definition: Result = (if is_bordered then 1 else 0 end)
		end

feature -- Geometry

	placement (a_anchor, a_bounds: RECT): RECT
			-- Box of the tooltip next to `a_anchor` inside `a_bounds` (see the class note);
			-- empty when nothing of it can be drawn
		require
			anchor_not_void: a_anchor /= Void
			bounds_not_void: a_bounds /= Void
		local
			l_size: TUPLE [width, height: INTEGER]
			l_rows: INTEGER
		do
			l_size := box_size (a_bounds)
			if l_size.width > 0 then
				Result := {OVERLAY_PLACEMENT}.placement (a_anchor, l_size.width.to_natural_16, l_size.height.to_natural_16,
					preferred_side, a_bounds)
				if Result.width.to_integer_32 < l_size.width and Result.width.to_integer_32 > 2 * border_size then
						-- Cut along a row (left or right of the anchor, with less room): the text
						-- wraps to more rows, so place the narrower, taller box again
					l_rows := wrapped (Result.width.to_integer_32 - 2 * border_size).count.max (1) + 2 * border_size
					Result := {OVERLAY_PLACEMENT}.placement (a_anchor, Result.width, l_rows.min ({NATURAL_16}.max_value.to_integer_32).to_natural_16,
						preferred_side, a_bounds)
				end
				if Result.width.to_integer_32 < 2 * border_size + 1 or Result.height.to_integer_32 < 2 * border_size + 1 then
					create Result.make (a_bounds.x, a_bounds.y, 0, 0)
				end
			else
				create Result.make (a_bounds.x, a_bounds.y, 0, 0)
			end
		ensure
			result_not_void: Result /= Void
			inside_bounds: Result.is_empty or else a_bounds.contains_rect (Result)
			clear_of_anchor: not Result.intersects (a_anchor)
			not_too_wide: Result.width <= max_width
			room_for_text: not Result.is_empty implies
				(Result.width.to_integer_32 > 2 * border_size and Result.height.to_integer_32 > 2 * border_size)
		end

	placed_side (a_anchor, a_bounds: RECT): NATURAL_8
			-- Side of `a_anchor` that `placement` puts the box on (OVERLAY_PLACEMENT)
		require
			anchor_not_void: a_anchor /= Void
			bounds_not_void: a_bounds /= Void
		local
			l_size: TUPLE [width, height: INTEGER]
		do
			l_size := box_size (a_bounds)
			Result := {OVERLAY_PLACEMENT}.placed_side (a_anchor, l_size.width.to_natural_16, l_size.height.to_natural_16,
				preferred_side, a_bounds)
		ensure
			preferred_or_opposite: Result = preferred_side or Result = {OVERLAY_PLACEMENT}.opposite (preferred_side)
		end

	box_size (a_bounds: RECT): TUPLE [width, height: INTEGER]
			-- Size of the whole box in `a_bounds` before it is placed: the text wrapped to at
			-- most `max_width` and the bounds' width, plus the borders; 0 x 0 when the bounds
			-- have no room for one column of text
		require
			bounds_not_void: a_bounds /= Void
		local
			l_inside, l_width: INTEGER
			l_lines: ARRAYED_LIST [TEXT_LINE]
		do
			l_inside := max_width.min (a_bounds.width).to_integer_32 - 2 * border_size
			if l_inside >= 1 then
				l_lines := wrapped (l_inside)
				l_width := 1
				across l_lines as l loop
					l_width := l_width.max (l.width.to_integer_32)
				end
				Result := [l_width.min (l_inside) + 2 * border_size, l_lines.count.max (1) + 2 * border_size]
			else
				Result := [0, 0]
			end
		ensure
			result_not_void: Result /= Void
			not_too_wide: Result.width <= max_width.min (a_bounds.width).to_integer_32
			non_negative: Result.width >= 0 and Result.height >= 0
		end

feature -- Element change

	set_text (a_text: READABLE_STRING_GENERAL)
			-- Show `a_text`, split on %N.
		require
			text_not_void: a_text /= Void
		do
			create text.make_raw (a_text)
		end

	set_text_value (a_text: TEXT)
			-- Show a copy of `a_text`.
		require
			text_not_void: a_text /= Void
		do
			text := a_text.twin
		ensure
			text_copied: text ~ a_text and text /= a_text
		end

	set_anchor (a_anchor: RECT)
			-- Describe the control at `a_anchor`.
		require
			anchor_not_void: a_anchor /= Void
		do
			anchor := a_anchor
		ensure
			anchor_set: anchor = a_anchor
		end

	set_preferred_side (a_side: NATURAL_8)
			-- Put the box on `a_side` of the anchor when it fits.
		require
			valid_side: {OVERLAY_PLACEMENT}.is_valid_side (a_side)
		do
			preferred_side := a_side
		ensure
			preferred_side_set: preferred_side = a_side
		end

	set_max_width (a_width: NATURAL_16)
			-- Make the box no wider than `a_width` columns, borders included.
		require
			room_for_text: a_width >= Minimum_width
		do
			max_width := a_width
		ensure
			max_width_set: max_width = a_width
		end

	set_bordered (a_bordered: BOOLEAN)
			-- Draw the box with a border, or without.
		do
			is_bordered := a_bordered
		ensure
			bordered_set: is_bordered = a_bordered
		end

	set_border_type (a_type: NATURAL_8)
			-- Draw the border with `a_type` corners and edges.
		require
			valid_type: {BORDER_TYPE}.is_valid (a_type)
		do
			border_type := a_type
		ensure
			border_type_set: border_type = a_type
		end

	set_style (a_style: STYLE)
			-- Patch `a_style` over the whole box.
		require
			style_not_void: a_style /= Void
		do
			style := a_style
		ensure
			style_set: style = a_style
		end

	set_border_style (a_style: STYLE)
			-- Draw the border in `a_style`.
		require
			style_not_void: a_style /= Void
		do
			border_style := a_style
		ensure
			border_style_set: border_style = a_style
		end

feature -- Fluent Builders

	with_text (a_text: READABLE_STRING_GENERAL): like Current
			-- Copy of Current showing `a_text`.
		require
			text_not_void: a_text /= Void
		do
			Result := twin
			Result.set_text (a_text)
		ensure
			result_not_void: Result /= Void
		end

	with_text_value (a_text: TEXT): like Current
			-- Copy of Current showing a copy of `a_text`.
		require
			text_not_void: a_text /= Void
		do
			Result := twin
			Result.set_text_value (a_text)
		ensure
			result_not_void: Result /= Void
			text_set: Result.text ~ a_text
		end

	with_anchor (a_anchor: RECT): like Current
			-- Copy of Current describing the control at `a_anchor`.
		require
			anchor_not_void: a_anchor /= Void
		do
			Result := twin
			Result.set_anchor (a_anchor)
		ensure
			result_not_void: Result /= Void
			anchor_set: Result.anchor = a_anchor
		end

	with_preferred_side (a_side: NATURAL_8): like Current
			-- Copy of Current putting the box on `a_side` when it fits.
		require
			valid_side: {OVERLAY_PLACEMENT}.is_valid_side (a_side)
		do
			Result := twin
			Result.set_preferred_side (a_side)
		ensure
			result_not_void: Result /= Void
			preferred_side_set: Result.preferred_side = a_side
		end

	with_max_width (a_width: NATURAL_16): like Current
			-- Copy of Current with no box wider than `a_width` columns.
		require
			room_for_text: a_width >= Minimum_width
		do
			Result := twin
			Result.set_max_width (a_width)
		ensure
			result_not_void: Result /= Void
			max_width_set: Result.max_width = a_width
		end

	with_bordered (a_bordered: BOOLEAN): like Current
			-- Copy of Current drawn with a border, or without.
		do
			Result := twin
			Result.set_bordered (a_bordered)
		ensure
			result_not_void: Result /= Void
			bordered_set: Result.is_bordered = a_bordered
		end

	with_border_type (a_type: NATURAL_8): like Current
			-- Copy of Current with `a_type` corners and edges.
		require
			valid_type: {BORDER_TYPE}.is_valid (a_type)
		do
			Result := twin
			Result.set_border_type (a_type)
		ensure
			result_not_void: Result /= Void
			border_type_set: Result.border_type = a_type
		end

	with_style (a_style: STYLE): like Current
			-- Copy of Current patching `a_style` over the box.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_style (a_style)
		ensure
			result_not_void: Result /= Void
			style_set: Result.style = a_style
		end

	with_border_style (a_style: STYLE): like Current
			-- Copy of Current drawing the border in `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_border_style (a_style)
		ensure
			result_not_void: Result /= Void
			border_style_set: Result.border_style = a_style
		end

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Same text, anchor, side, width, border, styles and hit id?
		do
			if a_other = Current then
				Result := True
			else
				Result := text.is_equal (a_other.text)
					and anchor.is_equal (a_other.anchor)
					and preferred_side = a_other.preferred_side
					and max_width = a_other.max_width
					and is_bordered = a_other.is_bordered
					and border_type = a_other.border_type
					and style.is_equal (a_other.style)
					and border_style.is_equal (a_other.border_style)
					and hit_id ~ a_other.hit_id
			end
		end

feature -- Rendering

	render (a_area: RECT; a_buffer: BUFFER)
			-- Draw the box next to `anchor`, inside `a_area` clipped to `a_buffer` (see the
			-- class note).
		local
			l_box, l_inside: RECT
			l_block: TUI_BLOCK
			l_lines: ARRAYED_LIST [TEXT_LINE]
			l_row: INTEGER
			l_base: STYLE
		do
			l_box := placement (anchor, a_area.intersection (a_buffer.area))
			if not l_box.is_empty then
				(create {TUI_CLEAR}).render (l_box, a_buffer)
				create l_block.make
				if is_bordered then
					l_block := l_block.with_border_type (border_type).with_border_style (border_style)
				else
					l_block := l_block.with_borders ({BORDERS}.none)
				end
				l_block.with_style (style).render (l_box, a_buffer)
				l_inside := l_box.inner (border_size.to_natural_16, border_size.to_natural_16)
					-- Wrapped again to the inside: a box cut along a row is narrower than asked
				l_lines := wrapped (l_inside.width.to_integer_32)
				l_row := l_inside.y.to_integer_32
				across l_lines as l until l_row >= l_inside.bottom.to_integer_32 loop
					l_base := a_buffer.cell (l_row, l_inside.x.to_integer_32).style.patch (text.style)
					a_buffer.set_line_clipped (l_row, l_inside.x.to_integer_32, l, l_base,
						l_inside.x.to_integer_32, l_inside.right.to_integer_32)
					l_row := l_row + 1
				end
			end
		end

feature {NONE} -- Implementation

	wrapped (a_width: INTEGER): ARRAYED_LIST [TEXT_LINE]
			-- `text` word-wrapped to `a_width` columns, blanks trimmed at the breaks
		require
			positive_width: a_width >= 1
		do
			Result := {TEXT_LAYOUT}.wrap_text (text, a_width.min ({NATURAL_16}.max_value.to_integer_32).to_natural_16,
				{TEXT_WRAP_MODE}.word, True)
		ensure
			result_not_void: Result /= Void
		end

invariant
	text_not_void: text /= Void
	anchor_not_void: anchor /= Void
	valid_side: {OVERLAY_PLACEMENT}.is_valid_side (preferred_side)
	room_for_text: max_width >= Minimum_width
	valid_border_type: {BORDER_TYPE}.is_valid (border_type)
	style_not_void: style /= Void
	border_style_not_void: border_style /= Void

end
