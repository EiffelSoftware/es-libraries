note
	description: "[
		A push button: "[ OK ]". Ratatui has no button widget (third-party crates and apps
		draw their own). Immediate mode, as TUI_CHECKBOX: the application owns focus and the
		pressed look and gives them to the widget each frame (`with_focused`, `with_pressed`);
		there is no state class. The widget reads no events.

		    a_frame.render_widget ((create {TUI_BUTTON}.make ("OK"))
		            .with_focused (focus.is_focused (id_ok))
		            .with_hit_id (id_ok),
		        l_area)

		Layout: on the middle row of the area (row `(height - 1) // 2`, the upper one of two
		for an even height), `left_bracket`, the label and `right_bracket`, placed by
		`alignment` (centre by default, as Ratatui's paragraph centres: `width // 2 -
		content // 2`; right: `width - content`). Content wider than the area starts at the
		left edge and is clipped at the right edge per grapheme cluster (a wide character
		that would cross it is left out, with the rest), and the area is first cut to the
		buffer. Cells of the row not covered by the content keep their symbols. The label's
		own alignment (TEXT_LINE.alignment) is not used. `width` is the number of columns the
		brackets and the label take; give the button an area that wide to draw it tight.

		Style: `style`, patched by `focused_style` when `is_focused`, then by `pressed_style`
		when `is_pressed` (`effective_style`), is patched over the whole area (cut to the
		buffer), so a wider or higher area is a filled button and colours left at the default
		keep the cells' own colours. `with_fill (False)` patches it over the brackets and the
		label only (a tight highlight in a wider slot, as a list row); the hit region is still
		the whole area. The brackets and the label are drawn in the style of the
		cell where the content starts after that patch; the label's line and span styles are
		patched over it. The default `focused_style` is reversed video, so focus shows without
		a theme; the default `pressed_style` is reversed and bold.

		Brackets: default "[ " / " ]"; `with_brackets` takes any pair without control
		characters (`is_valid_bracket`), Void for none: `with_brackets (Void, Void)` draws the
		bare label.

		Hit region: as a HIT_TARGET with a `hit_id`, FRAME.render_widget registers the whole
		area: a click anywhere on the button hits it, also on the cells beside the label.

		Input (the application's part): Enter or Space on the focused button, or a click on
		it, presses it. FOCUS_MANAGER chooses the button:

		    if attached {MOUSE_EVENT} a_event as m and then m.is_down then
		        if focus.focus_at (hit_test (m)) and then focus.is_focused (id_ok) then
		            confirm
		        end
		    elseif attached {KEY_EVENT} a_event as k and then k.is_press
		        and then k.code.is_enter and then focus.is_focused (id_ok)
		    then
		        confirm
		    end
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_BUTTON

inherit
	WIDGET
		redefine
			default_create,
			copy,
			is_equal
		end

	HIT_TARGET
		redefine
			default_create,
			copy,
			is_equal
		end

create
	default_create,
	make,
	make_with_line

feature {NONE} -- Initialization

	default_create
			-- Unfocused, unpressed button with an empty label, "[ " / " ]" brackets, centred,
			-- and the default styles.
		do
			create label.make_raw ("")
			create left_bracket.make_from_string_general (Default_left_bracket)
			create right_bracket.make_from_string_general (Default_right_bracket)
			alignment := {TEXT_ALIGNMENT}.center
			fills_area := True
			create style
			focused_style := (create {STYLE}).with_reverse
			pressed_style := (create {STYLE}).with_reverse.with_bold
		ensure then
			empty_label: label.is_empty
			not_focused: not is_focused
			not_pressed: not is_pressed
			default_brackets: left_bracket.same_string_general (Default_left_bracket)
				and right_bracket.same_string_general (Default_right_bracket)
			centred: alignment = {TEXT_ALIGNMENT}.center
			filled: fills_area
			no_hit_id: hit_id = Void
		end

	make (a_label: READABLE_STRING_GENERAL)
			-- Button labelled with the plain text `a_label`.
		require
			label_not_void: a_label /= Void
		do
			default_create
			set_label_string (a_label)
		ensure
			label_set: label.to_plain_string.same_string_general (a_label)
			not_focused: not is_focused
			not_pressed: not is_pressed
		end

	make_with_line (a_label: TEXT_LINE)
			-- Button with the styled label `a_label`.
		require
			label_not_void: a_label /= Void
		do
			default_create
			set_label (a_label)
		ensure
			label_set: label = a_label
			not_focused: not is_focused
			not_pressed: not is_pressed
		end

feature -- Access

	label: TEXT_LINE
			-- Text between the brackets

	left_bracket: IMMUTABLE_STRING_32
			-- Drawn before the label; empty for none

	right_bracket: IMMUTABLE_STRING_32
			-- Drawn after the label; empty for none

	alignment: NATURAL_8
			-- Horizontal place of the content in the area (TEXT_ALIGNMENT)

	style: STYLE
			-- Style patched over the whole area

	focused_style: STYLE
			-- Style patched over `style` when `is_focused`

	pressed_style: STYLE
			-- Style patched over `style` (and `focused_style`) when `is_pressed`

	Default_left_bracket: STRING = "[ "
			-- `left_bracket` of a new button

	Default_right_bracket: STRING = " ]"
			-- `right_bracket` of a new button

	effective_style: STYLE
			-- Style patched over the area: `style`, patched by `focused_style` when focused,
			-- then by `pressed_style` when pressed
		do
			Result := style
			if is_focused then
				Result := Result.patch (focused_style)
			end
			if is_pressed then
				Result := Result.patch (pressed_style)
			end
		ensure
			result_not_void: Result /= Void
			plain: not is_focused and not is_pressed implies Result = style
		end

	width: INTEGER
			-- Columns taken by the brackets and the label when nothing is clipped
		do
			Result := {UNICODE_WIDTH}.string_width (left_bracket).to_integer_32
				+ label.width.to_integer_32
				+ {UNICODE_WIDTH}.string_width (right_bracket).to_integer_32
		ensure
			non_negative: Result >= 0
			at_least_label: Result >= label.width.to_integer_32
		end

	content_row (a_area: RECT): INTEGER
			-- Row of `a_area` the content is drawn on: the middle one, the upper of the two
			-- middle rows for an even height
		require
			area_not_void: a_area /= Void
			area_not_empty: not a_area.is_empty
		do
			Result := a_area.y.to_integer_32 + (a_area.height.to_integer_32 - 1) // 2
		ensure
			inside: Result >= a_area.top.to_integer_32 and Result < a_area.bottom.to_integer_32
		end

	content_offset (a_area_width: INTEGER): INTEGER
			-- Columns between the area's left edge and the content in an area `a_area_width`
			-- columns wide, by `alignment`; 0 when the content does not fit
		require
			width_non_negative: a_area_width >= 0
		do
			if alignment = {TEXT_ALIGNMENT}.center then
				Result := (a_area_width // 2 - width // 2).max (0)
			elseif alignment = {TEXT_ALIGNMENT}.right then
				Result := (a_area_width - width).max (0)
			end
		ensure
			non_negative: Result >= 0
			left: alignment = {TEXT_ALIGNMENT}.left implies Result = 0
			too_wide: width >= a_area_width implies Result = 0
		end

feature -- Status report

	is_focused: BOOLEAN
			-- Is the button drawn with `focused_style`?

	is_pressed: BOOLEAN
			-- Is the button drawn with `pressed_style`?

	fills_area: BOOLEAN
			-- Is `effective_style` patched over the whole area (True, the default), or only over
			-- the cells of the brackets and the label? The hit region is the whole area either way.

	is_valid_bracket (a_bracket: READABLE_STRING_GENERAL): BOOLEAN
			-- Can `a_bracket` be a bracket: no C0 or C1 control character and no DEL, which
			-- would move the cursor or end a sequence instead of drawing? (Empty is allowed.)
		require
			bracket_not_void: a_bracket /= Void
		local
			i: INTEGER
			c: NATURAL_32
		do
			Result := True
			from i := 1 until not Result or i > a_bracket.count loop
				c := a_bracket.code (i)
				Result := c >= 32 and not (c >= 127 and c <= 159)
				i := i + 1
			end
		ensure
			instance_free: class
		end

feature -- Element change

	set_label (a_label: TEXT_LINE)
			-- Set the label to the styled line `a_label`.
		require
			label_not_void: a_label /= Void
		do
			label := a_label
		ensure
			label_set: label = a_label
		end

	set_label_string (a_text: READABLE_STRING_GENERAL)
			-- Set the label to the plain text `a_text`.
		require
			text_not_void: a_text /= Void
		do
			create label.make_raw (a_text)
		ensure
			text_set: label.to_plain_string.same_string_general (a_text)
		end

	set_focused (a_focused: BOOLEAN)
			-- Draw the button with `focused_style` (True) or not.
		do
			is_focused := a_focused
		ensure
			focused_set: is_focused = a_focused
		end

	set_pressed (a_pressed: BOOLEAN)
			-- Draw the button with `pressed_style` (True) or not.
		do
			is_pressed := a_pressed
		ensure
			pressed_set: is_pressed = a_pressed
		end

	set_fill (a_fill: BOOLEAN)
			-- Patch the style over the whole area (True) or over the content only.
		do
			fills_area := a_fill
		ensure
			fill_set: fills_area = a_fill
		end

	set_style (a_style: STYLE)
			-- Patch `a_style` over the whole area.
		require
			style_not_void: a_style /= Void
		do
			style := a_style
		ensure
			style_set: style = a_style
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

	set_pressed_style (a_style: STYLE)
			-- Patch `a_style` over `style` (and `focused_style`) when pressed.
		require
			style_not_void: a_style /= Void
		do
			pressed_style := a_style
		ensure
			pressed_style_set: pressed_style = a_style
		end

	set_alignment (a_alignment: NATURAL_8)
			-- Place the content by `a_alignment` (TEXT_ALIGNMENT).
		require
			valid_alignment: {TEXT_ALIGNMENT}.is_valid (a_alignment)
		do
			alignment := a_alignment
		ensure
			alignment_set: alignment = a_alignment
		end

	set_brackets (a_left, a_right: detachable READABLE_STRING_GENERAL)
			-- Draw `a_left` before the label and `a_right` after it; Void for none.
		require
			valid_left: attached a_left as l implies is_valid_bracket (l)
			valid_right: attached a_right as r implies is_valid_bracket (r)
		do
			if attached a_left as l then
				create left_bracket.make_from_string_general (l)
			else
				create left_bracket.make_empty
			end
			if attached a_right as r then
				create right_bracket.make_from_string_general (r)
			else
				create right_bracket.make_empty
			end
		ensure
			left_set: attached a_left as l implies left_bracket.same_string_general (l)
			no_left: a_left = Void implies left_bracket.is_empty
			right_set: attached a_right as r implies right_bracket.same_string_general (r)
			no_right: a_right = Void implies right_bracket.is_empty
		end

feature -- Fluent Builders

	with_label (a_text: READABLE_STRING_GENERAL): like Current
			-- Copy of Current labelled with the plain text `a_text`.
		require
			text_not_void: a_text /= Void
		do
			Result := twin
			Result.set_label_string (a_text)
		ensure
			result_not_void: Result /= Void
			text_set: Result.label.to_plain_string.same_string_general (a_text)
		end

	with_label_line (a_label: TEXT_LINE): like Current
			-- Copy of Current with the styled label `a_label`.
		require
			label_not_void: a_label /= Void
		do
			Result := twin
			Result.set_label (a_label)
		ensure
			result_not_void: Result /= Void
			label_set: Result.label = a_label
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

	with_pressed (a_pressed: BOOLEAN): like Current
			-- Copy of Current drawn pressed (True) or not.
		do
			Result := twin
			Result.set_pressed (a_pressed)
		ensure
			result_not_void: Result /= Void
			pressed_set: Result.is_pressed = a_pressed
		end

	with_fill (a_fill: BOOLEAN): like Current
			-- Copy of Current patching its style over the whole area (True) or over the
			-- content only (False: a tight highlight, the whole area still clickable).
		do
			Result := twin
			Result.set_fill (a_fill)
		ensure
			result_not_void: Result /= Void
			fill_set: Result.fills_area = a_fill
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

	with_pressed_style (a_style: STYLE): like Current
			-- Copy of Current with `pressed_style` set to `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_pressed_style (a_style)
		ensure
			result_not_void: Result /= Void
			pressed_style_set: Result.pressed_style = a_style
		end

	with_alignment (a_alignment: NATURAL_8): like Current
			-- Copy of Current placing the content by `a_alignment` (TEXT_ALIGNMENT).
		require
			valid_alignment: {TEXT_ALIGNMENT}.is_valid (a_alignment)
		do
			Result := twin
			Result.set_alignment (a_alignment)
		ensure
			result_not_void: Result /= Void
			alignment_set: Result.alignment = a_alignment
		end

	with_brackets (a_left, a_right: detachable READABLE_STRING_GENERAL): like Current
			-- Copy of Current drawing `a_left` before the label and `a_right` after it; Void
			-- for none.
		require
			valid_left: attached a_left as l implies is_valid_bracket (l)
			valid_right: attached a_right as r implies is_valid_bracket (r)
		do
			Result := twin
			Result.set_brackets (a_left, a_right)
		ensure
			result_not_void: Result /= Void
			left_set: attached a_left as l implies Result.left_bracket.same_string_general (l)
			no_left: a_left = Void implies Result.left_bracket.is_empty
			right_set: attached a_right as r implies Result.right_bracket.same_string_general (r)
			no_right: a_right = Void implies Result.right_bracket.is_empty
		end

feature -- Duplication

	copy (a_other: like Current)
			-- Copy `a_other`, with its own copy of the label, so that changing the label of a
			-- copy made by a `with_*` builder leaves the original unchanged. The brackets are
			-- immutable and are shared.
		do
			if a_other /= Current then
				standard_copy (a_other)
				label := a_other.label.twin
			end
		end

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Same label, brackets, alignment, focus, pressed look, styles and hit id?
		do
			if a_other = Current then
				Result := True
			else
				Result := is_focused = a_other.is_focused
					and is_pressed = a_other.is_pressed
					and fills_area = a_other.fills_area
					and alignment = a_other.alignment
					and label ~ a_other.label
					and left_bracket.same_string (a_other.left_bracket)
					and right_bracket.same_string (a_other.right_bracket)
					and style.is_equal (a_other.style)
					and focused_style.is_equal (a_other.focused_style)
					and pressed_style.is_equal (a_other.pressed_style)
					and hit_id ~ a_other.hit_id
			end
		end

feature -- Rendering

	render (a_area: RECT; a_buffer: BUFFER)
			-- Patch `effective_style` over `a_area` cut to `a_buffer`, then draw the brackets
			-- and the label on `content_row`, placed by `alignment` (see the class note).
		local
			l_clip: RECT
			l_row, l_left, l_right, l_col: INTEGER
			l_base: STYLE
		do
			l_clip := a_area.intersection (a_buffer.area)
			if not l_clip.is_empty then
				l_row := content_row (a_area)
				l_left := l_clip.left.to_integer_32
				l_right := l_clip.right.to_integer_32
				l_col := a_area.x.to_integer_32 + content_offset (a_area.width.to_integer_32)
				if fills_area then
					a_buffer.set_style (l_clip, effective_style)
				elseif l_row >= l_clip.top.to_integer_32 and l_row < l_clip.bottom.to_integer_32 and l_col < l_right then
					a_buffer.set_style ((create {RECT}.make (l_col.to_natural_16, l_row.to_natural_16,
						width.min (l_right - l_col).to_natural_16, 1)).intersection (l_clip), effective_style)
				end
				if l_row >= l_clip.top.to_integer_32 and l_row < l_clip.bottom.to_integer_32 and l_col < l_right then
					l_base := a_buffer.cell (l_row, l_col.max (l_left)).style.twin
					if not left_bracket.is_empty then
						a_buffer.set_string_clipped (l_row, l_col, left_bracket, l_left, l_right, l_base)
						l_col := l_col + {UNICODE_WIDTH}.string_width (left_bracket).to_integer_32
					end
					if not label.is_empty and l_col < l_right then
						a_buffer.set_line_clipped (l_row, l_col, label, l_base, l_left, l_right)
						l_col := l_col + label.width.to_integer_32
					end
					if not right_bracket.is_empty and l_col < l_right then
						a_buffer.set_string_clipped (l_row, l_col, right_bracket, l_left, l_right, l_base)
					end
				end
			end
		end

invariant
	label_not_void: label /= Void
	left_bracket_not_void: left_bracket /= Void
	right_bracket_not_void: right_bracket /= Void
	valid_left_bracket: is_valid_bracket (left_bracket)
	valid_right_bracket: is_valid_bracket (right_bracket)
	valid_alignment: {TEXT_ALIGNMENT}.is_valid (alignment)
	style_not_void: style /= Void
	focused_style_not_void: focused_style /= Void
	pressed_style_not_void: pressed_style /= Void

end
