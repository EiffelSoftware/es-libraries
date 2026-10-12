note
	description: "[
		Single-line text input widget with horizontal scrolling, placeholder text,
		password masking support, and cursor rendering.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_TEXT_INPUT

inherit
	STATEFUL_WIDGET [TEXT_INPUT_STATE]
		redefine
			default_create
		end
	BLOCK_CONTAINER
		redefine
			default_create
		end

create
	default_create,
	make

feature {NONE} -- Initialization

	default_create
			-- Initialize with default styling and cursor enabled.
		do
			create style.default_create
			create cursor_style.default_create
			cursor_style := cursor_style.with_reverse
			create placeholder_style.default_create
			placeholder_style := placeholder_style.with_dim
			shows_cursor := True
		ensure then
			shows_cursor_default: shows_cursor
		end

	make
			-- Synonym for `default_create`.
		do
			default_create
		end

feature -- Access

	style: STYLE
			-- Style for entered text

	cursor_style: STYLE
			-- Style for cursor cell

	placeholder_style: STYLE
			-- Style for placeholder text

	placeholder: detachable STRING_32
			-- Placeholder text displayed when input value is empty

	has_mask: BOOLEAN
			-- Is input masked with a mask character (e.g. for passwords)?

	mask_char: CHARACTER_32
			-- Character used to mask input when `has_mask` is True

	shows_cursor: BOOLEAN
			-- Whether cursor is rendered

feature -- Element Change

	set_style (a_style: STYLE)
			-- Set text style to `a_style`.
		require
			style_not_void: a_style /= Void
		do
			style := a_style
		ensure
			style_set: style = a_style
		end

	set_cursor_style (a_style: STYLE)
			-- Set cursor style to `a_style`.
		require
			style_not_void: a_style /= Void
		do
			cursor_style := a_style
		ensure
			cursor_style_set: cursor_style = a_style
		end

	set_placeholder_style (a_style: STYLE)
			-- Set placeholder style to `a_style`.
		require
			style_not_void: a_style /= Void
		do
			placeholder_style := a_style
		ensure
			placeholder_style_set: placeholder_style = a_style
		end

	set_placeholder (a_placeholder: detachable READABLE_STRING_GENERAL)
			-- Set placeholder text.
		do
			if attached a_placeholder as l_pl then
				create placeholder.make_from_string_general (l_pl)
			else
				placeholder := Void
			end
		end

	set_mask_char (a_char: CHARACTER_32)
			-- Set masking character for password inputs.
		require
			visible_mask: {UNICODE_WIDTH}.width (a_char.natural_32_code) > 0
		do
			mask_char := a_char
			has_mask := True
		ensure
			has_mask: has_mask
			mask_char_set: mask_char = a_char
		end

	clear_mask_char
			-- Disable password masking.
		do
			has_mask := False
		ensure
			mask_cleared: not has_mask
		end

	set_shows_cursor (a_val: BOOLEAN)
			-- Set cursor visibility flag.
		do
			shows_cursor := a_val
		ensure
			shows_cursor_set: shows_cursor = a_val
		end

feature -- Fluent Builders

	with_style (a_style: STYLE): like Current
			-- Return a copy of Current with `style` set to `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_style (a_style)
		ensure
			result_not_void: Result /= Void
			style_set: Result.style = a_style
		end

	with_cursor_style (a_style: STYLE): like Current
			-- Return a copy of Current with `cursor_style` set to `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_cursor_style (a_style)
		ensure
			result_not_void: Result /= Void
			cursor_style_set: Result.cursor_style = a_style
		end

	with_placeholder_style (a_style: STYLE): like Current
			-- Return a copy of Current with `placeholder_style` set to `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_placeholder_style (a_style)
		ensure
			result_not_void: Result /= Void
			placeholder_style_set: Result.placeholder_style = a_style
		end

	with_placeholder (a_placeholder: detachable READABLE_STRING_GENERAL): like Current
			-- Return a copy of Current with placeholder set.
		do
			Result := twin
			Result.set_placeholder (a_placeholder)
		ensure
			result_not_void: Result /= Void
		end

	with_mask_char (a_char: CHARACTER_32): like Current
			-- Return a copy of Current with mask character set.
		require
			visible_mask: {UNICODE_WIDTH}.width (a_char.natural_32_code) > 0
		do
			Result := twin
			Result.set_mask_char (a_char)
		ensure
			result_not_void: Result /= Void
			mask_char_set: Result.mask_char = a_char
		end

	without_mask_char: like Current
			-- Return a copy of Current without mask character.
		do
			Result := twin
			Result.clear_mask_char
		ensure
			result_not_void: Result /= Void
			mask_cleared: not Result.has_mask
		end

	with_shows_cursor (a_val: BOOLEAN): like Current
			-- Return a copy of Current with cursor visibility set.
		do
			Result := twin
			Result.set_shows_cursor (a_val)
		ensure
			result_not_void: Result /= Void
			shows_cursor_set: Result.shows_cursor = a_val
		end

feature -- Rendering

	render (a_area: RECT; a_buffer: BUFFER)
			-- Stateless rendering using a default empty TEXT_INPUT_STATE.
		local
			l_state: TEXT_INPUT_STATE
		do
			create l_state.default_create
			render_stateful (a_area, a_buffer, l_state)
		end

	render_stateful (a_area: RECT; a_buffer: BUFFER; a_state: TEXT_INPUT_STATE)
			-- Render input widget using `a_state` within `a_area` on `a_buffer`.
			-- Text is laid out by display width (wide characters, combining marks) and clipped to
			-- the inner area; `a_state.scroll_offset` is adjusted so that the cursor stays visible.
		local
			l_target: RECT
			l_row, l_left, l_right, l_cursor_x, l_cursor_w: INTEGER
			l_text: READABLE_STRING_32
			l_at_end: BOOLEAN
		do
			if not a_area.is_empty then
				render_block (a_area, a_buffer)
				l_target := inner_area (a_area)

				if not l_target.is_empty then
					l_row := l_target.y.to_integer_32
					l_left := l_target.x.to_integer_32
					l_right := l_target.right.to_integer_32
					adjust_scroll (l_target.width.to_integer_32, a_state)

					if l_row < a_buffer.height then
						a_buffer.set_style (create {RECT}.make (l_target.x, l_target.y, l_target.width, 1), style)

						if a_state.value.is_empty then
							if attached placeholder as l_pl and then not l_pl.is_empty then
								a_buffer.set_string_clipped (l_row, l_left, l_pl, l_left, l_right, style.patch (placeholder_style))
							end
							l_cursor_x := l_left
							l_cursor_w := 1
							l_at_end := True
						else
							l_text := displayed_text (a_state)
							a_buffer.set_string_clipped (l_row, l_left - a_state.scroll_offset, l_text, l_left, l_right, style)
							l_cursor_x := l_left + displayed_column (a_state) - a_state.scroll_offset
							l_at_end := displayed_cursor_index (a_state) = l_text.count
							-- A zero-width cluster at the cursor (a lone leading combining mark) is
							-- drawn on no cell of its own: highlight the cell it is shown with
							l_cursor_w := cell_width_at_cursor (l_text, displayed_cursor_index (a_state)).max (1)
						end

						if shows_cursor and l_cursor_x >= l_left and l_cursor_x < l_right and l_cursor_x < a_buffer.width then
							if l_at_end then
								-- After the last character: draw a blank cursor cell
								a_buffer.put_char (l_row, l_cursor_x, ' ', style.patch (cursor_style))
							else
								a_buffer.set_style (create {RECT}.make (l_cursor_x.to_natural_16, l_row.to_natural_16,
									l_cursor_w.min (l_right - l_cursor_x).to_natural_16, 1), cursor_style)
							end
						end
					end
				end
			end
		end

feature -- Cursor

	cursor_screen_position (a_area: RECT; a_state: TEXT_INPUT_STATE): detachable TUPLE [col, row: INTEGER]
			-- Buffer position of the cursor when `Current` renders `a_state` into `a_area`, or Void
			-- when it is not visible. Call after rendering (rendering may scroll) and pass it to
			-- `{FRAME}.set_cursor_position` to show the terminal's hardware cursor there.
		require
			area_not_void: a_area /= Void
			state_not_void: a_state /= Void
		local
			l_target: RECT
			l_col: INTEGER
		do
			l_target := inner_area (a_area)
			if not l_target.is_empty then
				if a_state.value.is_empty then
					l_col := l_target.x.to_integer_32
				else
					l_col := l_target.x.to_integer_32 + displayed_column (a_state) - a_state.scroll_offset
				end
				if l_col >= l_target.x.to_integer_32 and l_col < l_target.right.to_integer_32 then
					Result := [l_col, l_target.y.to_integer_32]
				end
			end
		end

feature {NONE} -- Implementation

	displayed_text (a_state: TEXT_INPUT_STATE): READABLE_STRING_32
			-- Text as shown: the value, or one `mask_char` per grapheme cluster when masked
		local
			i, l_count: INTEGER
			l_masked: STRING_32
		do
			if has_mask then
				from
					i := 1
				until
					i > a_state.value.count
				loop
					i := {UNICODE_WIDTH}.grapheme_end (a_state.value, i) + 1
					l_count := l_count + 1
				end
				create l_masked.make_filled (mask_char, l_count)
				Result := l_masked
			else
				Result := a_state.value
			end
		end

	displayed_cursor_index (a_state: TEXT_INPUT_STATE): INTEGER
			-- Cursor position in `displayed_text (a_state)` (code points before the cursor)
		local
			i: INTEGER
		do
			if has_mask then
				from
					i := 1
				until
					i > a_state.cursor_position
				loop
					i := {UNICODE_WIDTH}.grapheme_end (a_state.value, i) + 1
					Result := Result + 1
				end
			else
				Result := a_state.cursor_position
			end
		end

	displayed_column (a_state: TEXT_INPUT_STATE): INTEGER
			-- Display column of the cursor in the displayed text
		do
			if has_mask then
				Result := displayed_cursor_index (a_state) * {UNICODE_WIDTH}.width (mask_char.natural_32_code).to_integer_32
			else
				Result := a_state.cursor_column
			end
		end

	cell_width_at_cursor (a_text: READABLE_STRING_32; a_index: INTEGER): INTEGER
			-- Width of the cluster after position `a_index` in `a_text`, 0 at the end
		do
			if a_index < a_text.count then
				Result := {UNICODE_WIDTH}.grapheme_width (a_text.substring (a_index + 1, {UNICODE_WIDTH}.grapheme_end (a_text, a_index + 1))).to_integer_32
			end
		end

	adjust_scroll (a_width: INTEGER; a_state: TEXT_INPUT_STATE)
			-- Scroll `a_state` so that the cursor (and the cluster under it) is inside `a_width`
			-- columns, and so that no columns are wasted after the end of the text.
		local
			l_col, l_cell, l_total: INTEGER
			l_text: READABLE_STRING_32
		do
			l_text := displayed_text (a_state)
			l_col := displayed_column (a_state)
			l_cell := cell_width_at_cursor (l_text, displayed_cursor_index (a_state)).max (1)
			l_total := {UNICODE_WIDTH}.string_width (l_text).to_integer_32 + 1
			if a_state.scroll_offset > (l_total - a_width).max (0) then
				a_state.set_scroll_offset ((l_total - a_width).max (0))
			end
			if l_col < a_state.scroll_offset then
				a_state.set_scroll_offset (l_col)
			elseif l_col + l_cell > a_state.scroll_offset + a_width then
				a_state.set_scroll_offset (l_col + l_cell - a_width)
			end
		ensure
			non_negative: a_state.scroll_offset >= 0
		end

invariant
	style_not_void: style /= Void
	cursor_style_not_void: cursor_style /= Void
	placeholder_style_not_void: placeholder_style /= Void

end
