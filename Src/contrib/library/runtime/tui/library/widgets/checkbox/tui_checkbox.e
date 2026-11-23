note
	description: "[
		A check box with a label: "[x] Wrap lines". Ratatui has no checkbox widget (third-party
		crates and apps draw their own). Immediate mode: the application owns the boolean and
		gives it to the widget each frame (`with_checked`); there is no state class. The widget
		reads no events.

		    a_frame.render_widget ((create {TUI_CHECKBOX}.make ("Wrap lines"))
		            .with_checked (wrap)
		            .with_focused (focus.is_focused (id_wrap))
		            .with_hit_id (id_wrap),
		        l_area)

		Layout: on the top row of the area, the symbol (`checked_symbol` or `unchecked_symbol`),
		one blank, then the label. An empty label has no blank before it. Both are clipped to
		the area's right edge (a wide character that would cross it is left out), and the area
		is first cut to the buffer. The box takes `content_area`: the top row, `width` columns
		wide (cut to the area); the rest of the area is left as it is, so a box can be given a
		whole layout row. `width` is the number of columns the symbol and the label take.

		Style: `style`, patched by `focused_style` when `is_focused`, is patched over
		`content_area` (cut to the buffer), so colours left at the default keep the cells' own
		colours. The symbol and the label are drawn in the style of its first cell after that
		patch; the label's line and span styles are patched over it. The default
		`focused_style` is reversed video, so focus shows without a theme.

		Symbols: default ASCII "[x]" / "[ ]"; `with_unicode_symbols` gives U+2611 / U+2610;
		`with_symbols` takes any pair (CHECKBOX_SYMBOLS has the presets) without control
		characters (`is_valid_symbol`). The label starts after the wider of the two symbols
		(`symbol_width`), the narrower one padded with blanks, so ticking the box never moves
		the label.

		Hit region: as a HIT_TARGET with a `hit_id`, FRAME.render_widget registers
		`content_area` (`hit_area`): the symbol and the label are clickable, and the region is
		what the style highlights; a click beside the label, in the rest of the area, misses.

		Input (the application's part): Space on the focused box, or a click on it, toggles
		the application's boolean. FOCUS_MANAGER chooses the box:

		    if attached {MOUSE_EVENT} a_event as m and then m.is_down then
		        if focus.focus_at (hit_test (m)) and then focus.is_focused (id_wrap) then
		            wrap := not wrap
		        end
		    elseif attached {KEY_EVENT} a_event as k and then k.is_press
		        and then k.code.is_char and then k.code.character = ' '
		        and then focus.is_focused (id_wrap)
		    then
		        wrap := not wrap
		    end

		Recipe, a radio group: checkboxes sharing one selected index (the application's
		INTEGER), drawn with the radio symbols "(" U+2022 ")" / "( )". Space or a click on
		option `i` sets `selected := i`; it never clears it.

		    from i := 1 until i > options.count loop
		        a_frame.render_widget ((create {TUI_CHECKBOX}.make (options [i]))
		                .with_symbols ({CHECKBOX_SYMBOLS}.radio_selected, {CHECKBOX_SYMBOLS}.radio_unselected)
		                .with_checked (i = selected)
		                .with_focused (focus.is_focused (option_ids [i]))
		                .with_hit_id (option_ids [i]),
		            create {RECT}.make (x, y + (i - 1).to_natural_16, w, 1))
		        i := i + 1
		    end
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_CHECKBOX

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
			is_equal,
			hit_area
		end

create
	default_create,
	make,
	make_with_line

feature {NONE} -- Initialization

	default_create
			-- Unchecked, unfocused box with an empty label, ASCII symbols and the default styles.
		do
			create label.make_raw ("")
			checked_symbol := {CHECKBOX_SYMBOLS}.ascii_checked
			unchecked_symbol := {CHECKBOX_SYMBOLS}.ascii_unchecked
			create style
			focused_style := (create {STYLE}).with_reverse
		ensure then
			empty_label: label.is_empty
			unchecked: not is_checked
			not_focused: not is_focused
			ascii: checked_symbol.same_string ({CHECKBOX_SYMBOLS}.ascii_checked)
				and unchecked_symbol.same_string ({CHECKBOX_SYMBOLS}.ascii_unchecked)
			no_hit_id: hit_id = Void
		end

	make (a_label: READABLE_STRING_GENERAL)
			-- Unchecked box labelled with the plain text `a_label`.
		require
			label_not_void: a_label /= Void
		do
			default_create
			set_label_string (a_label)
		ensure
			unchecked: not is_checked
		end

	make_with_line (a_label: TEXT_LINE)
			-- Unchecked box with the styled label `a_label`.
		require
			label_not_void: a_label /= Void
		do
			default_create
			set_label (a_label)
		ensure
			label_set: label = a_label
			unchecked: not is_checked
		end

feature -- Access

	label: TEXT_LINE
			-- Text after the symbol

	checked_symbol: IMMUTABLE_STRING_32
			-- Symbol drawn when `is_checked`

	unchecked_symbol: IMMUTABLE_STRING_32
			-- Symbol drawn when not `is_checked`

	style: STYLE
			-- Style patched over `content_area`

	focused_style: STYLE
			-- Style patched over `style` when `is_focused`

	symbol: IMMUTABLE_STRING_32
			-- Symbol drawn for the current `is_checked`
		do
			if is_checked then
				Result := checked_symbol
			else
				Result := unchecked_symbol
			end
		ensure
			definition: Result = (if is_checked then checked_symbol else unchecked_symbol end)
		end

	effective_style: STYLE
			-- Style patched over `content_area`: `style`, patched by `focused_style` when focused
		do
			if is_focused then
				Result := style.patch (focused_style)
			else
				Result := style
			end
		end

	symbol_width: INTEGER
			-- Columns kept for the symbol: the wider of `checked_symbol` and `unchecked_symbol`,
			-- so the label is in the same place whether the box is checked or not
		do
			Result := {UNICODE_WIDTH}.string_width (checked_symbol).to_integer_32
				.max ({UNICODE_WIDTH}.string_width (unchecked_symbol).to_integer_32)
		ensure
			at_least_checked: Result >= {UNICODE_WIDTH}.string_width (checked_symbol).to_integer_32
			at_least_unchecked: Result >= {UNICODE_WIDTH}.string_width (unchecked_symbol).to_integer_32
		end

	width: INTEGER
			-- Columns taken by the symbol (`symbol_width`), the blank after it and the label (no
			-- blank for an empty label), when nothing is clipped; the same checked or not
		do
			Result := symbol_width
			if not label.is_empty then
				Result := Result + 1 + label.width.to_integer_32
			end
		ensure
			non_negative: Result >= 0
		end

	content_area (a_area: RECT): RECT
			-- Cells the box takes when rendered into `a_area`: the top row, `width` columns
			-- wide, cut to `a_area`; empty for an empty area (see the class note)
		require
			area_not_void: a_area /= Void
		do
			if a_area.is_empty then
				create Result.make (a_area.x, a_area.y, 0, 0)
			else
				create Result.make (a_area.x, a_area.y, width.min (a_area.width.to_integer_32).to_natural_16, 1)
			end
		ensure
			result_not_void: Result /= Void
			inside: Result.is_empty or else a_area.contains_rect (Result)
			one_row: not Result.is_empty implies Result.height = 1
		end

	hit_area (a_area: RECT; a_state: detachable WIDGET_STATE): RECT
			-- `content_area`: the symbol and the label, what the style highlights
		do
			Result := content_area (a_area)
		end

feature -- Status report

	is_checked: BOOLEAN
			-- Is the box drawn checked?

	is_valid_symbol (a_symbol: READABLE_STRING_GENERAL): BOOLEAN
			-- Can `a_symbol` be a check symbol: no C0 or C1 control character and no DEL, which
			-- would move the cursor or end a sequence instead of drawing? (Empty is allowed: the
			-- box then shows only the label, after `symbol_width` columns.)
		local
			i: INTEGER
			c: NATURAL_32
		do
			Result := True
			from i := 1 until not Result or i > a_symbol.count loop
				c := a_symbol.code (i)
				Result := c >= 32 and not (c >= 127 and c <= 159)
				i := i + 1
			end
		ensure
			instance_free: class
		end

	is_focused: BOOLEAN
			-- Is the box drawn with `focused_style`?

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

	set_checked (a_checked: BOOLEAN)
			-- Draw the box checked (True) or not.
		do
			is_checked := a_checked
		ensure
			checked_set: is_checked = a_checked
		end

	set_focused (a_focused: BOOLEAN)
			-- Draw the box with `focused_style` (True) or not.
		do
			is_focused := a_focused
		ensure
			focused_set: is_focused = a_focused
		end

	set_style (a_style: STYLE)
			-- Patch `a_style` over `content_area` (the symbol and the label).
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

	set_checked_symbol (a_symbol: READABLE_STRING_GENERAL)
			-- Draw `a_symbol` when checked.
		require
			symbol_not_void: a_symbol /= Void
			valid_symbol: is_valid_symbol (a_symbol)
		do
			create checked_symbol.make_from_string_general (a_symbol)
		ensure
			checked_symbol_set: checked_symbol.same_string_general (a_symbol)
		end

	set_unchecked_symbol (a_symbol: READABLE_STRING_GENERAL)
			-- Draw `a_symbol` when not checked.
		require
			symbol_not_void: a_symbol /= Void
			valid_symbol: is_valid_symbol (a_symbol)
		do
			create unchecked_symbol.make_from_string_general (a_symbol)
		ensure
			unchecked_symbol_set: unchecked_symbol.same_string_general (a_symbol)
		end

	set_symbols (a_checked, a_unchecked: READABLE_STRING_GENERAL)
			-- Draw `a_checked` when checked and `a_unchecked` when not.
		require
			checked_not_void: a_checked /= Void
			unchecked_not_void: a_unchecked /= Void
			valid_checked: is_valid_symbol (a_checked)
			valid_unchecked: is_valid_symbol (a_unchecked)
		do
			set_checked_symbol (a_checked)
			set_unchecked_symbol (a_unchecked)
		ensure
			checked_symbol_set: checked_symbol.same_string_general (a_checked)
			unchecked_symbol_set: unchecked_symbol.same_string_general (a_unchecked)
		end

	use_unicode_symbols
			-- Draw U+2611 / U+2610 (CHECKBOX_SYMBOLS).
		do
			set_symbols ({CHECKBOX_SYMBOLS}.unicode_checked, {CHECKBOX_SYMBOLS}.unicode_unchecked)
		ensure
			unicode: checked_symbol.same_string ({CHECKBOX_SYMBOLS}.unicode_checked)
				and unchecked_symbol.same_string ({CHECKBOX_SYMBOLS}.unicode_unchecked)
		end

	use_ascii_symbols
			-- Draw "[x]" / "[ ]" (the default).
		do
			set_symbols ({CHECKBOX_SYMBOLS}.ascii_checked, {CHECKBOX_SYMBOLS}.ascii_unchecked)
		ensure
			ascii: checked_symbol.same_string ({CHECKBOX_SYMBOLS}.ascii_checked)
				and unchecked_symbol.same_string ({CHECKBOX_SYMBOLS}.ascii_unchecked)
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

	with_checked (a_checked: BOOLEAN): like Current
			-- Copy of Current drawn checked (True) or not.
		do
			Result := twin
			Result.set_checked (a_checked)
		ensure
			result_not_void: Result /= Void
			checked_set: Result.is_checked = a_checked
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

	with_checked_symbol (a_symbol: READABLE_STRING_GENERAL): like Current
			-- Copy of Current drawing `a_symbol` when checked.
		require
			symbol_not_void: a_symbol /= Void
			valid_symbol: is_valid_symbol (a_symbol)
		do
			Result := twin
			Result.set_checked_symbol (a_symbol)
		ensure
			result_not_void: Result /= Void
			checked_symbol_set: Result.checked_symbol.same_string_general (a_symbol)
		end

	with_unchecked_symbol (a_symbol: READABLE_STRING_GENERAL): like Current
			-- Copy of Current drawing `a_symbol` when not checked.
		require
			symbol_not_void: a_symbol /= Void
			valid_symbol: is_valid_symbol (a_symbol)
		do
			Result := twin
			Result.set_unchecked_symbol (a_symbol)
		ensure
			result_not_void: Result /= Void
			unchecked_symbol_set: Result.unchecked_symbol.same_string_general (a_symbol)
		end

	with_symbols (a_checked, a_unchecked: READABLE_STRING_GENERAL): like Current
			-- Copy of Current drawing `a_checked` when checked and `a_unchecked` when not.
		require
			checked_not_void: a_checked /= Void
			unchecked_not_void: a_unchecked /= Void
			valid_checked: is_valid_symbol (a_checked)
			valid_unchecked: is_valid_symbol (a_unchecked)
		do
			Result := twin
			Result.set_symbols (a_checked, a_unchecked)
		ensure
			result_not_void: Result /= Void
			checked_symbol_set: Result.checked_symbol.same_string_general (a_checked)
			unchecked_symbol_set: Result.unchecked_symbol.same_string_general (a_unchecked)
		end

	with_unicode_symbols: like Current
			-- Copy of Current drawing U+2611 / U+2610.
		do
			Result := twin
			Result.use_unicode_symbols
		ensure
			result_not_void: Result /= Void
		end

	with_ascii_symbols: like Current
			-- Copy of Current drawing "[x]" / "[ ]".
		do
			Result := twin
			Result.use_ascii_symbols
		ensure
			result_not_void: Result /= Void
		end

feature -- Duplication

	copy (a_other: like Current)
			-- Copy `a_other`, with its own copy of the label, so that changing the label of a
			-- copy made by a `with_*` builder leaves the original unchanged. The symbols are
			-- immutable and are shared.
		do
			if a_other /= Current then
				standard_copy (a_other)
				label := a_other.label.twin
			end
		end

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Same label, check state, focus, symbols, styles and hit id?
		do
			if a_other = Current then
				Result := True
			else
				Result := is_checked = a_other.is_checked
					and is_focused = a_other.is_focused
					and label ~ a_other.label
					and checked_symbol.same_string (a_other.checked_symbol)
					and unchecked_symbol.same_string (a_other.unchecked_symbol)
					and style.is_equal (a_other.style)
					and focused_style.is_equal (a_other.focused_style)
					and hit_id ~ a_other.hit_id
			end
		end

feature -- Rendering

	render (a_area: RECT; a_buffer: BUFFER)
			-- Patch `effective_style` over `content_area` cut to `a_buffer`, then draw the
			-- symbol, a blank and the label in it (see the class note).
		local
			l_area: RECT
			l_row, l_left, l_right, l_col: INTEGER
			l_base: STYLE
		do
			l_area := content_area (a_area).intersection (a_buffer.area)
			if not l_area.is_empty then
				a_buffer.set_style (l_area, effective_style)
				l_row := l_area.top.to_integer_32
				l_left := l_area.left.to_integer_32
				l_right := l_area.right.to_integer_32
				l_base := a_buffer.cell (l_row, l_left).style.twin
				a_buffer.set_string_clipped (l_row, l_left, symbol, l_left, l_right, l_base)
					-- Blanks after a symbol narrower than the other one
				from
					l_col := l_left + {UNICODE_WIDTH}.string_width (symbol).to_integer_32
				until
					l_col >= (l_left + symbol_width).min (l_right)
				loop
					a_buffer.put_char (l_row, l_col, ' ', l_base)
					l_col := l_col + 1
				end
				if not label.is_empty then
					l_col := l_left + symbol_width
					if l_col < l_right then
						a_buffer.put_char (l_row, l_col, ' ', l_base)
						l_col := l_col + 1
						if l_col < l_right then
							a_buffer.set_line_clipped (l_row, l_col, label, l_base, l_col, l_right)
						end
					end
				end
			end
		end

invariant
	label_not_void: label /= Void
	checked_symbol_not_void: checked_symbol /= Void
	unchecked_symbol_not_void: unchecked_symbol /= Void
	valid_checked_symbol: is_valid_symbol (checked_symbol)
	valid_unchecked_symbol: is_valid_symbol (unchecked_symbol)
	style_not_void: style /= Void
	focused_style_not_void: focused_style /= Void

end
