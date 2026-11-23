note
	description: "[
		A slider: a track with a thumb at the value of a SLIDER_STATE, "====o------ 40" (box-drawing glyphs).
		Ratatui has no slider (third-party crates and apps draw their own). The state holds the
		range, the step and the value; the widget draws it and maps the mouse to it. The widget
		reads no events.

		    a_frame.render_stateful_widget ((create {TUI_SLIDER})
		            .with_label_position ({SLIDER_LABEL_POSITION}.right)
		            .with_focused (focus.is_focused (id_volume))
		            .with_hit_id (id_volume),
		        l_area, volume)

		Layout, horizontal (`make`): the track is the top row of the area, `minimum` at the
		left. With a label, the label takes `label_width` columns at the left or the right,
		with one blank between it and the track; it is right-aligned on the left (next to the
		track) and left-aligned on the right. Vertical (`make_vertical`): the track is the left
		column, `minimum` at the bottom; the label is on its own row, above the track (`left`)
		or below it (`right`), left-aligned. The label is never cut, so it never shows a wrong
		number: it is dropped when it does not fit whole with at least one track cell
		(horizontal: the area is narrower than `label_width` + 2; vertical: it has one row or
		is narrower than `label_width`). Cells of the area outside the track and the label
		(`content_area`) are left as they are. The area is cut to the buffer for drawing, but
		the track is laid out on the whole area, so `track_area` is the same on screen and in
		the arithmetic.

		The thumb is on cell (value - minimum) / (maximum - minimum) * (track length - 1),
		rounded half away from zero ({SLIDER_STATE}.thumb_cell), so `minimum` is the first
		cell, `maximum` the last, and `minimum` = `maximum` puts the thumb at the start. Cells
		before the thumb are drawn with `filled_glyph`, the thumb with `thumb_glyph`, cells
		after it with `track_glyph`. The default glyphs depend on the direction (horizontal
		U+2501 / U+25CF / U+2500, vertical U+2503 / U+25CF / U+2502); `with_*_symbol` sets
		one-column symbols of your own, and Void goes back to the default.

		Label text: `value.out`, or what `label_format` gives for the value. `label_width` does
		not depend on the value, so the track never moves as the value changes (a drag stays
		mapped onto the track it started on): it is `fixed_label_width` when set
		(`with_label_width`), else the wider of the texts for `minimum` and `maximum`. With the
		default `out` no value's text is wider than that (its digits are at most those of the
		end it lies towards, and a minus sign only below zero, where `minimum` has one too). A
		`label_format` can make a middle value wider (a word, a unit that changes): give it
		`with_label_width`. A value text wider than `label_width` is left out (the label
		columns stay blank) rather than cut, so the label never shows a wrong number.

		Style: `style`, patched by `focused_style` when `is_focused` (reversed by default, as
		TUI_CHECKBOX), is patched over the track and the label (`track_area`, `label_area`)
		only; `filled_style` is patched over the filled cells and `thumb_style` over the thumb
		on top of that, so colours left at the default keep the cells' own colours.

		Hit region: as a HIT_TARGET with a `hit_id`, FRAME.render_stateful_widget registers
		`content_area` (`hit_area`): the track and the label (a click on the label focuses the
		slider). For a vertical slider with a label wider than one column, that rectangle also
		holds the blank cells beside the track under the label's width. `is_on_track` tells
		whether a point is on the track itself.

		Input (the application's part): keys move the state, and the mouse maps through the
		track. Coordinates are the frame's: subtract the shown viewport's origin
		({TERMINAL}.shown_area) in an inline or fixed viewport.

		    if attached {MOUSE_EVENT} a_event as m then
		        col := m.column - origin_x; row := m.row - origin_y
		        if m.is_down and then focus.focus_at (hit_test (m)) and then focus.is_focused (id_volume)
		            and then slider.is_on_track (l_area, volume, col, row)
		        then
		            dragging := True    -- a click on the track jumps there
		            volume.set_from_position (slider.track_cell (l_area, volume, col, row),
		                slider.track_length (l_area, volume))
		        elseif m.is_drag and dragging then
		            -- the drag follows the pointer, also past the ends
		            volume.set_from_position (slider.track_cell (l_area, volume, col, row),
		                slider.track_length (l_area, volume))
		        elseif m.is_up then
		            dragging := False
		        end
		    elseif attached {KEY_EVENT} a_event as k and then k.is_press and then focus.is_focused (id_volume) then
		        if k.code.is_right or k.code.is_up then volume.increase
		        elseif k.code.is_left or k.code.is_down then volume.decrease
		        elseif k.code.is_page_up then volume.increase_page
		        elseif k.code.is_page_down then volume.decrease_page
		        elseif k.code.is_home then volume.set_to_minimum
		        elseif k.code.is_end then volume.set_to_maximum
		        end
		    end
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_SLIDER

inherit
	STATEFUL_WIDGET [SLIDER_STATE]
		redefine
			default_create,
			is_equal
		end

	HIT_TARGET
		redefine
			default_create,
			is_equal,
			hit_area
		end

create
	default_create,
	make,
	make_vertical

feature {NONE} -- Initialization

	default_create
			-- Horizontal slider, default glyphs, no label, unfocused, default styles.
		do
			direction := {SLIDER_DIRECTION}.horizontal
			label_position := {SLIDER_LABEL_POSITION}.none
			create style
			create filled_style
			create thumb_style
			focused_style := (create {STYLE}).with_reverse
		ensure then
			horizontal: direction = {SLIDER_DIRECTION}.horizontal
			no_label: label_position = {SLIDER_LABEL_POSITION}.none
			default_glyphs: track_symbol = Void and filled_symbol = Void and thumb_symbol = Void
			not_focused: not is_focused
			no_hit_id: hit_id = Void
		end

	make
			-- Horizontal slider (as `default_create`).
		do
			default_create
		ensure
			horizontal: direction = {SLIDER_DIRECTION}.horizontal
		end

	make_vertical
			-- Vertical slider, `minimum` at the bottom.
		do
			default_create
			direction := {SLIDER_DIRECTION}.vertical
		ensure
			vertical: direction = {SLIDER_DIRECTION}.vertical
		end

feature -- Access

	direction: NATURAL_8
			-- {SLIDER_DIRECTION}.horizontal or .vertical

	track_symbol: detachable IMMUTABLE_STRING_32
			-- Symbol for the cells after the thumb, or Void for the direction's default

	filled_symbol: detachable IMMUTABLE_STRING_32
			-- Symbol for the cells before the thumb, or Void for the direction's default

	thumb_symbol: detachable IMMUTABLE_STRING_32
			-- Symbol for the thumb, or Void for the default

	style: STYLE
			-- Style patched over the track and the label

	filled_style: STYLE
			-- Style patched over the filled cells

	thumb_style: STYLE
			-- Style patched over the thumb

	focused_style: STYLE
			-- Style patched over `style` when `is_focused`

	label_position: NATURAL_8
			-- {SLIDER_LABEL_POSITION}.none, .left or .right

	label_format: detachable FUNCTION [INTEGER_64, READABLE_STRING_GENERAL]
			-- Text of the label for a value, or Void for `out`

	fixed_label_width: INTEGER
			-- Columns kept for the label whatever the value, or 0 to use the wider of the
			-- `minimum` and `maximum` texts (see `label_width`)

	track_glyph: IMMUTABLE_STRING_32
			-- Symbol drawn after the thumb: `track_symbol`, or U+2500 / U+2502
		do
			if attached track_symbol as s then
				Result := s
			elseif is_horizontal then
				Result := glyph (0x2500)
			else
				Result := glyph (0x2502)
			end
		end

	filled_glyph: IMMUTABLE_STRING_32
			-- Symbol drawn before the thumb: `filled_symbol`, or U+2501 / U+2503
		do
			if attached filled_symbol as s then
				Result := s
			elseif is_horizontal then
				Result := glyph (0x2501)
			else
				Result := glyph (0x2503)
			end
		end

	thumb_glyph: IMMUTABLE_STRING_32
			-- Symbol drawn for the thumb: `thumb_symbol`, or U+25CF
		do
			if attached thumb_symbol as s then
				Result := s
			else
				Result := glyph (0x25CF)
			end
		end

	effective_style: STYLE
			-- Style patched over the track and the label: `style`, patched by `focused_style`
			-- when focused
		do
			if is_focused then
				Result := style.patch (focused_style)
			else
				Result := style
			end
		end

	label_text (a_value: INTEGER_64): STRING_32
			-- Label for `a_value`: `label_format` applied to it, or its `out`
		do
			if attached label_format as f then
				create Result.make_from_string_general (f (a_value))
			else
				Result := a_value.out.to_string_32
			end
		ensure
			result_not_void: Result /= Void
		end

	label_width (a_state: SLIDER_STATE): INTEGER
			-- Columns of the label: `fixed_label_width` when set, else the wider of the texts
			-- for `minimum` and `maximum`; 0 without a label. Not the value's, so the track does
			-- not move as the value changes.
		require
			state_not_void: a_state /= Void
		do
			if label_position /= {SLIDER_LABEL_POSITION}.none then
				if fixed_label_width > 0 then
					Result := fixed_label_width
				else
					Result := text_width (label_text (a_state.minimum))
						.max (text_width (label_text (a_state.maximum)))
				end
			end
		ensure
			non_negative: Result >= 0
			none: label_position = {SLIDER_LABEL_POSITION}.none implies Result = 0
			fixed: (label_position /= {SLIDER_LABEL_POSITION}.none and fixed_label_width > 0)
				implies Result = fixed_label_width
		end

	label_fits (a_state: SLIDER_STATE): BOOLEAN
			-- Does the text for `a_state`'s value fit whole in `label_width`?
		require
			state_not_void: a_state /= Void
		do
			Result := text_width (label_text (a_state.value)) <= label_width (a_state)
		end

feature -- Geometry

	shows_label (a_area: RECT; a_state: SLIDER_STATE): BOOLEAN
			-- Is the label drawn in `a_area`: a label position, a non-empty label, room for it
			-- whole (never cut, so it never shows a wrong number) and at least one track cell?
		require
			area_not_void: a_area /= Void
			state_not_void: a_state /= Void
		local
			l_width: INTEGER
		do
			if label_position /= {SLIDER_LABEL_POSITION}.none and not a_area.is_empty then
				l_width := label_width (a_state)
				if l_width > 0 then
					if is_horizontal then
						Result := a_area.width.to_integer_32 >= l_width + 2
					else
						Result := a_area.height >= 2 and a_area.width.to_integer_32 >= l_width
					end
				end
			end
		ensure
			fits_whole: Result implies (if is_horizontal then a_area.width.to_integer_32 >= label_width (a_state) + 2
				else a_area.width.to_integer_32 >= label_width (a_state) and a_area.height >= 2 end)
		end

	label_area (a_area: RECT; a_state: SLIDER_STATE): RECT
			-- Cells of the label when rendered into `a_area` with `a_state`, with the blank
			-- between it and a horizontal track; empty when `shows_label` is false
		require
			area_not_void: a_area /= Void
			state_not_void: a_state /= Void
		local
			l_width: NATURAL_16
		do
			if shows_label (a_area, a_state) then
				l_width := label_width (a_state).to_natural_16
				if is_horizontal then
					if label_position = {SLIDER_LABEL_POSITION}.left then
						create Result.make (a_area.x, a_area.y, l_width + 1, 1)
					else
						create Result.make (a_area.x + a_area.width - l_width - 1, a_area.y, l_width + 1, 1)
					end
				elseif label_position = {SLIDER_LABEL_POSITION}.left then
					create Result.make (a_area.x, a_area.y, l_width, 1)
				else
					create Result.make (a_area.x, a_area.y + a_area.height - 1, l_width, 1)
				end
			else
				create Result.make (a_area.x, a_area.y, 0, 0)
			end
		ensure
			result_not_void: Result /= Void
			inside: Result.is_empty or else a_area.contains_rect (Result)
			empty_without_label: not shows_label (a_area, a_state) implies Result.is_empty
		end

	content_area (a_area: RECT; a_state: SLIDER_STATE): RECT
			-- Smallest rectangle holding `track_area` and `label_area`: the top row of a
			-- horizontal slider; the left column of a vertical one, as wide as its label
		require
			area_not_void: a_area /= Void
			state_not_void: a_state /= Void
		local
			l_track, l_label: RECT
		do
			l_track := track_area (a_area, a_state)
			l_label := label_area (a_area, a_state)
			if l_label.is_empty then
				Result := l_track
			else
				Result := l_track.union (l_label)
			end
		ensure
			result_not_void: Result /= Void
			inside: Result.is_empty or else a_area.contains_rect (Result)
		end

	hit_area (a_area: RECT; a_state: detachable WIDGET_STATE): RECT
			-- `content_area` with `a_state` (with a default SLIDER_STATE when it is not one):
			-- the track and the label
		do
			if attached {SLIDER_STATE} a_state as l_state then
				Result := content_area (a_area, l_state)
			else
				Result := content_area (a_area, create {SLIDER_STATE})
			end
		end

	track_area (a_area: RECT; a_state: SLIDER_STATE): RECT
			-- Cells of the track when rendered into `a_area` with `a_state`: one row
			-- (horizontal) or one column (vertical), empty for an empty area. Not cut to a
			-- buffer, so it maps the mouse the same way whatever is on screen.
		require
			area_not_void: a_area /= Void
			state_not_void: a_state /= Void
		local
			l_label: NATURAL_16
		do
			if a_area.is_empty then
				create Result.make (a_area.x, a_area.y, 0, 0)
			elseif is_horizontal then
				if shows_label (a_area, a_state) then
					l_label := (label_width (a_state) + 1).to_natural_16
					if label_position = {SLIDER_LABEL_POSITION}.left then
						create Result.make (a_area.x + l_label, a_area.y, a_area.width - l_label, 1)
					else
						create Result.make (a_area.x, a_area.y, a_area.width - l_label, 1)
					end
				else
					create Result.make (a_area.x, a_area.y, a_area.width, 1)
				end
			elseif shows_label (a_area, a_state) then
				if label_position = {SLIDER_LABEL_POSITION}.left then
					create Result.make (a_area.x, a_area.y + 1, 1, a_area.height - 1)
				else
					create Result.make (a_area.x, a_area.y, 1, a_area.height - 1)
				end
			else
				create Result.make (a_area.x, a_area.y, 1, a_area.height)
			end
		ensure
			result_not_void: Result /= Void
			inside: a_area.contains_rect (Result) or Result.is_empty
			one_row_or_column: not Result.is_empty implies
				(if is_horizontal then Result.height = 1 else Result.width = 1 end)
			not_empty: not a_area.is_empty implies not Result.is_empty
		end

	track_length (a_area: RECT; a_state: SLIDER_STATE): INTEGER
			-- Cells in `track_area`; 0 for an empty area
		require
			area_not_void: a_area /= Void
			state_not_void: a_state /= Void
		local
			l_track: RECT
		do
			l_track := track_area (a_area, a_state)
			if l_track.is_empty then
				Result := 0
			elseif is_horizontal then
				Result := l_track.width.to_integer_32
			else
				Result := l_track.height.to_integer_32
			end
		ensure
			non_negative: Result >= 0
			empty_area: a_area.is_empty implies Result = 0
		end

	track_cell (a_area: RECT; a_state: SLIDER_STATE; a_column, a_row: INTEGER): INTEGER
			-- Cell of the track at frame point (`a_column`, `a_row`), counted from the `minimum`
			-- end (the left, or the bottom of a vertical track); below 0 or from `track_length`
			-- up when the point is past an end, which {SLIDER_STATE}.set_from_position clamps.
			-- Only the coordinate along the track counts, so a drag off the track still follows.
		require
			area_not_void: a_area /= Void
			state_not_void: a_state /= Void
		local
			l_track: RECT
		do
			l_track := track_area (a_area, a_state)
			if is_horizontal then
				Result := a_column - l_track.x.to_integer_32
			else
				Result := l_track.y.to_integer_32 + l_track.height.to_integer_32 - 1 - a_row
			end
		end

	is_on_track (a_area: RECT; a_state: SLIDER_STATE; a_column, a_row: INTEGER): BOOLEAN
			-- Is frame point (`a_column`, `a_row`) on `track_area`?
		require
			area_not_void: a_area /= Void
			state_not_void: a_state /= Void
		local
			l_track: RECT
		do
			l_track := track_area (a_area, a_state)
			Result := not l_track.is_empty
				and a_column >= l_track.left.to_integer_32 and a_column < l_track.right.to_integer_32
				and a_row >= l_track.top.to_integer_32 and a_row < l_track.bottom.to_integer_32
		end

feature -- Status report

	is_horizontal: BOOLEAN
			-- Is the track one row?
		do
			Result := direction = {SLIDER_DIRECTION}.horizontal
		end

	is_focused: BOOLEAN
			-- Is the slider drawn with `focused_style`?

	is_valid_symbol (a_symbol: READABLE_STRING_GENERAL): BOOLEAN
			-- Can `a_symbol` be a track symbol: one grapheme cluster, one column wide? (The
			-- empty string is allowed too: it draws nothing, the cell keeps its symbol.)
		do
			Result := {TERMINAL_CELL}.is_one_column_symbol (a_symbol)
		ensure
			instance_free: class
		end

feature -- Element change

	set_direction (a_direction: NATURAL_8)
			-- Lay the track out in `a_direction`.
		require
			valid_direction: {SLIDER_DIRECTION}.is_valid (a_direction)
		do
			direction := a_direction
		ensure
			direction_set: direction = a_direction
		end

	set_track_symbol (a_symbol: detachable READABLE_STRING_GENERAL)
			-- Draw `a_symbol` after the thumb (Void: the direction's default).
		require
			one_column: attached a_symbol as s implies is_valid_symbol (s)
		do
			track_symbol := immutable (a_symbol)
		ensure
			symbol_set: attached a_symbol as s implies (attached track_symbol as t and then t.same_string_general (s))
			default: a_symbol = Void implies track_symbol = Void
		end

	set_filled_symbol (a_symbol: detachable READABLE_STRING_GENERAL)
			-- Draw `a_symbol` before the thumb (Void: the direction's default).
		require
			one_column: attached a_symbol as s implies is_valid_symbol (s)
		do
			filled_symbol := immutable (a_symbol)
		ensure
			symbol_set: attached a_symbol as s implies (attached filled_symbol as t and then t.same_string_general (s))
			default: a_symbol = Void implies filled_symbol = Void
		end

	set_thumb_symbol (a_symbol: detachable READABLE_STRING_GENERAL)
			-- Draw `a_symbol` for the thumb (Void: the default).
		require
			one_column: attached a_symbol as s implies is_valid_symbol (s)
		do
			thumb_symbol := immutable (a_symbol)
		ensure
			symbol_set: attached a_symbol as s implies (attached thumb_symbol as t and then t.same_string_general (s))
			default: a_symbol = Void implies thumb_symbol = Void
		end

	set_style (a_style: STYLE)
			-- Patch `a_style` over the track and the label.
		require
			style_not_void: a_style /= Void
		do
			style := a_style
		ensure
			style_set: style = a_style
		end

	set_filled_style (a_style: STYLE)
			-- Patch `a_style` over the filled cells.
		require
			style_not_void: a_style /= Void
		do
			filled_style := a_style
		ensure
			filled_style_set: filled_style = a_style
		end

	set_thumb_style (a_style: STYLE)
			-- Patch `a_style` over the thumb.
		require
			style_not_void: a_style /= Void
		do
			thumb_style := a_style
		ensure
			thumb_style_set: thumb_style = a_style
		end

	set_focused_style (a_style: STYLE)
			-- Patch `a_style` over `style` when focused.
		require
			style_not_void: a_style /= Void
		do
			focused_style := a_style
		ensure
			focused_style_set: focused_style = a_style
		end

	set_focused (a_focused: BOOLEAN)
			-- Draw the slider with `focused_style` (True) or not.
		do
			is_focused := a_focused
		ensure
			focused_set: is_focused = a_focused
		end

	set_label_position (a_position: NATURAL_8)
			-- Draw the value label at `a_position` ({SLIDER_LABEL_POSITION}).
		require
			valid_position: {SLIDER_LABEL_POSITION}.is_valid (a_position)
		do
			label_position := a_position
		ensure
			label_position_set: label_position = a_position
		end

	set_label_width (a_width: INTEGER)
			-- Keep `a_width` columns for the label whatever the value (0: the wider of the
			-- `minimum` and `maximum` texts).
		require
			non_negative: a_width >= 0
			fits_natural_16: a_width < {NATURAL_16}.max_value
		do
			fixed_label_width := a_width
		ensure
			fixed_label_width_set: fixed_label_width = a_width
		end

	set_label_format (a_format: like label_format)
			-- Make the label text with `a_format` (Void: the value's `out`).
		do
			label_format := a_format
		ensure
			label_format_set: label_format = a_format
		end

feature -- Fluent Builders

	with_direction (a_direction: NATURAL_8): like Current
			-- Copy of Current laid out in `a_direction`.
		require
			valid_direction: {SLIDER_DIRECTION}.is_valid (a_direction)
		do
			Result := twin
			Result.set_direction (a_direction)
		ensure
			result_not_void: Result /= Void
			direction_set: Result.direction = a_direction
		end

	with_track_symbol (a_symbol: detachable READABLE_STRING_GENERAL): like Current
			-- Copy of Current drawing `a_symbol` after the thumb (Void: the default).
		require
			one_column: attached a_symbol as s implies is_valid_symbol (s)
		do
			Result := twin
			Result.set_track_symbol (a_symbol)
		ensure
			result_not_void: Result /= Void
		end

	with_filled_symbol (a_symbol: detachable READABLE_STRING_GENERAL): like Current
			-- Copy of Current drawing `a_symbol` before the thumb (Void: the default).
		require
			one_column: attached a_symbol as s implies is_valid_symbol (s)
		do
			Result := twin
			Result.set_filled_symbol (a_symbol)
		ensure
			result_not_void: Result /= Void
		end

	with_thumb_symbol (a_symbol: detachable READABLE_STRING_GENERAL): like Current
			-- Copy of Current drawing `a_symbol` for the thumb (Void: the default).
		require
			one_column: attached a_symbol as s implies is_valid_symbol (s)
		do
			Result := twin
			Result.set_thumb_symbol (a_symbol)
		ensure
			result_not_void: Result /= Void
		end

	with_style (a_style: STYLE): like Current
			-- Copy of Current with `style` set to `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_style (a_style)
		ensure
			result_not_void: Result /= Void
			style_set: Result.style = a_style
		end

	with_filled_style (a_style: STYLE): like Current
			-- Copy of Current with `filled_style` set to `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_filled_style (a_style)
		ensure
			result_not_void: Result /= Void
			filled_style_set: Result.filled_style = a_style
		end

	with_thumb_style (a_style: STYLE): like Current
			-- Copy of Current with `thumb_style` set to `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_thumb_style (a_style)
		ensure
			result_not_void: Result /= Void
			thumb_style_set: Result.thumb_style = a_style
		end

	with_focused_style (a_style: STYLE): like Current
			-- Copy of Current with `focused_style` set to `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_focused_style (a_style)
		ensure
			result_not_void: Result /= Void
			focused_style_set: Result.focused_style = a_style
		end

	with_focused (a_focused: BOOLEAN): like Current
			-- Copy of Current drawn focused (True) or not.
		do
			Result := twin
			Result.set_focused (a_focused)
		ensure
			result_not_void: Result /= Void
			focused_set: Result.is_focused = a_focused
		end

	with_label_position (a_position: NATURAL_8): like Current
			-- Copy of Current with the value label at `a_position`.
		require
			valid_position: {SLIDER_LABEL_POSITION}.is_valid (a_position)
		do
			Result := twin
			Result.set_label_position (a_position)
		ensure
			result_not_void: Result /= Void
			label_position_set: Result.label_position = a_position
		end

	with_label_width (a_width: INTEGER): like Current
			-- Copy of Current keeping `a_width` columns for the label (0: from the ends' texts).
		require
			non_negative: a_width >= 0
			fits_natural_16: a_width < {NATURAL_16}.max_value
		do
			Result := twin
			Result.set_label_width (a_width)
		ensure
			result_not_void: Result /= Void
			fixed_label_width_set: Result.fixed_label_width = a_width
		end

	with_label_format (a_format: like label_format): like Current
			-- Copy of Current making the label text with `a_format` (Void: `out`).
		do
			Result := twin
			Result.set_label_format (a_format)
		ensure
			result_not_void: Result /= Void
			label_format_set: Result.label_format = a_format
		end

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Same direction, symbols, styles, focus, label position and format, and hit id?
		do
			if a_other = Current then
				Result := True
			else
				Result := direction = a_other.direction
					and is_focused = a_other.is_focused
					and label_position = a_other.label_position
					and label_format = a_other.label_format
					and fixed_label_width = a_other.fixed_label_width
					and same_symbol (track_symbol, a_other.track_symbol)
					and same_symbol (filled_symbol, a_other.filled_symbol)
					and same_symbol (thumb_symbol, a_other.thumb_symbol)
					and style.is_equal (a_other.style)
					and filled_style.is_equal (a_other.filled_style)
					and thumb_style.is_equal (a_other.thumb_style)
					and focused_style.is_equal (a_other.focused_style)
					and hit_id ~ a_other.hit_id
			end
		end

feature -- Rendering

	render (a_area: RECT; a_buffer: BUFFER)
			-- Render with a default SLIDER_STATE (0 .. 100 at 0).
		do
			render_stateful (a_area, a_buffer, create {SLIDER_STATE})
		end

	render_stateful (a_area: RECT; a_buffer: BUFFER; a_state: SLIDER_STATE)
			-- Patch `effective_style` over the track and the label (cut to `a_buffer`), then
			-- draw the label and the track with the thumb at `a_state`'s value (see the class
			-- note). The rest of `a_area` is left as it is.
		local
			l_clip, l_track: RECT
			l_len, l_thumb, i, l_first, r, c: INTEGER
			l_filled, l_thumb_glyph, l_track_glyph, l_symbol: IMMUTABLE_STRING_32
			l_patch: detachable STYLE
		do
			l_clip := a_area.intersection (a_buffer.area)
			if not l_clip.is_empty then
				l_track := track_area (a_area, a_state)
				a_buffer.set_style (l_track.intersection (a_buffer.area), effective_style)
				if shows_label (a_area, a_state) then
					a_buffer.set_style (label_area (a_area, a_state).intersection (a_buffer.area), effective_style)
					render_label (a_area, l_clip, a_buffer, a_state)
				end
				l_len := track_length (a_area, a_state)
				if l_len > 0 then
					l_thumb := a_state.thumb_cell (l_len)
					l_filled := filled_glyph
					l_thumb_glyph := thumb_glyph
					l_track_glyph := track_glyph
					if is_horizontal then
						l_first := 0
					else
							-- Cells below the buffer are skipped
						l_first := (l_track.bottom.to_integer_32 - a_buffer.height).max (0)
					end
					from
						i := l_first
					until
						i >= l_len
					loop
						if is_horizontal then
							r := l_track.y.to_integer_32
							c := l_track.x.to_integer_32 + i
						else
							r := l_track.bottom.to_integer_32 - 1 - i
							c := l_track.x.to_integer_32
						end
						if r < a_buffer.height and c < a_buffer.width then
							if i < l_thumb then
								l_symbol := l_filled
								l_patch := filled_style
							elseif i = l_thumb then
								l_symbol := l_thumb_glyph
								l_patch := thumb_style
							else
								l_symbol := l_track_glyph
								l_patch := Void
							end
							put_symbol (a_buffer, r, c, l_symbol, l_patch)
							i := i + 1
						else
								-- Past the right edge or below the bottom: nothing more to draw
							i := l_len
						end
					end
				end
			end
		ensure then
			consistent: a_buffer.is_consistent
		end

feature {NONE} -- Implementation

	render_label (a_area, a_clip: RECT; a_buffer: BUFFER; a_state: SLIDER_STATE)
			-- Blank the label's columns (and the gap next to a horizontal track), then draw the
			-- label text, clipped to `a_clip`.
		require
			shown: shows_label (a_area, a_state)
		local
			l_text: STRING_32
			l_width, l_text_width, l_row, l_from, l_to, l_text_col, l_text_end, c: INTEGER
			l_left, l_right: INTEGER
			l_base: detachable STYLE
		do
			l_text := label_text (a_state.value)
			l_text_width := text_width (l_text)
			l_width := label_width (a_state)
			l_left := a_area.left.to_integer_32
			l_right := a_area.right.to_integer_32
			if is_horizontal then
				l_row := a_area.y.to_integer_32
				if label_position = {SLIDER_LABEL_POSITION}.left then
						-- Label right-aligned, then the gap
					l_from := l_left
					l_to := l_left + l_width + 1
					l_text_col := l_left + l_width - l_text_width
					l_text_end := l_left + l_width
				else
						-- The gap, then the label left-aligned
					l_from := l_right - l_width - 1
					l_to := l_right
					l_text_col := l_from + 1
					l_text_end := l_to
				end
			else
				if label_position = {SLIDER_LABEL_POSITION}.left then
					l_row := a_area.y.to_integer_32
				else
					l_row := a_area.bottom.to_integer_32 - 1
				end
				l_from := l_left
				l_to := (l_left + l_width).min (l_right)
				l_text_col := l_left
				l_text_end := l_to
			end
			l_from := l_from.max (a_clip.left.to_integer_32)
			l_to := l_to.min (a_clip.right.to_integer_32)
			l_text_end := l_text_end.min (l_to)
			if l_row < a_buffer.height and l_from < l_to then
				from c := l_from until c >= l_to loop
					if l_base = Void and c >= l_text_col then
						l_base := a_buffer.cell (l_row, c).style.twin
					end
					a_buffer.put_char (l_row, c, ' ', a_buffer.cell (l_row, c).style.twin)
					c := c + 1
				end
				if l_base = Void then
					l_base := a_buffer.cell (l_row, l_from).style.twin
				end
					-- A text wider than `label_width` (a `label_format` without `with_label_width`)
					-- is left out, never cut
				if l_from < l_text_end and label_fits (a_state) then
					a_buffer.set_string_clipped (l_row, l_text_col, l_text, l_from, l_text_end, l_base)
				end
			end
		end

	put_symbol (a_buffer: BUFFER; a_row, a_col: INTEGER; a_symbol: IMMUTABLE_STRING_32; a_patch: detachable STYLE)
			-- Draw `a_symbol` in cell (`a_row`, `a_col`) in the cell's style patched by `a_patch`;
			-- an empty symbol only patches the style.
		require
			valid_row: a_row >= 0 and a_row < a_buffer.height
			valid_col: a_col >= 0 and a_col < a_buffer.width
		local
			l_style: STYLE
		do
			if attached a_patch as p then
				l_style := a_buffer.cell (a_row, a_col).style.patch (p)
			else
				l_style := a_buffer.cell (a_row, a_col).style.twin
			end
			if a_symbol.is_empty then
				a_buffer.set_style (create {RECT}.make (a_col.to_natural_16, a_row.to_natural_16, 1, 1), l_style)
			else
				a_buffer.set_string_clipped (a_row, a_col, a_symbol, a_col, a_col + 1, l_style)
			end
		end

	glyph (a_code: NATURAL_32): IMMUTABLE_STRING_32
			-- One-character string for code point `a_code`
		local
			s: STRING_32
		do
			create s.make (1)
			s.append_character (a_code.to_character_32)
			create Result.make_from_string (s)
		end

	immutable (a_symbol: detachable READABLE_STRING_GENERAL): detachable IMMUTABLE_STRING_32
			-- `a_symbol` as an immutable string, or Void
		do
			if attached a_symbol as s then
				create Result.make_from_string_general (s)
			end
		end

	same_symbol (a, b: detachable IMMUTABLE_STRING_32): BOOLEAN
			-- Both Void, or the same text?
		do
			if attached a as x and attached b as y then
				Result := x.same_string (y)
			else
				Result := a = Void and b = Void
			end
		end

	text_width (a_text: READABLE_STRING_GENERAL): INTEGER
			-- Columns of `a_text`
		do
			Result := {UNICODE_WIDTH}.string_width (a_text).to_integer_32
		end

invariant
	valid_direction: {SLIDER_DIRECTION}.is_valid (direction)
	valid_label_position: {SLIDER_LABEL_POSITION}.is_valid (label_position)
	non_negative_label_width: fixed_label_width >= 0
	style_not_void: style /= Void
	filled_style_not_void: filled_style /= Void
	thumb_style_not_void: thumb_style /= Void
	focused_style_not_void: focused_style /= Void
	one_column_track: attached track_symbol as s implies is_valid_symbol (s)
	one_column_filled: attached filled_symbol as s implies is_valid_symbol (s)
	one_column_thumb: attached thumb_symbol as s implies is_valid_symbol (s)

end
