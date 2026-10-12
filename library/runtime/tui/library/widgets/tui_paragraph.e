note
	description: "[
		Widget rendering multi-line styled text with automatic word/character wrapping,
		alignment, optional scrolling, and optional container block integration.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_PARAGRAPH

inherit
	BLOCK_CONTAINER
		redefine
			copy,
			is_equal
		end

create
	make,
	make_raw,
	make_styled

feature {NONE} -- Initialization

	make (a_text: TEXT)
			-- Initialize paragraph with `a_text`.
		require
			text_not_void: a_text /= Void
		do
			text_store := a_text
			create style.default_create
			wrap_mode := {TEXT_WRAP_MODE}.none
			wrap_trim := True
			alignment := {TEXT_ALIGNMENT}.left
			scroll_x := 0
			scroll_y := 0
		ensure
			text_set: text = a_text
			no_block: block = Void
		end

	make_raw (a_content: READABLE_STRING_GENERAL)
			-- Initialize paragraph from a plain text string.
		require
			content_not_void: a_content /= Void
		local
			l_text: TEXT
		do
			create l_text.make_raw (a_content)
			make (l_text)
		end

	make_styled (a_content: READABLE_STRING_GENERAL; a_style: STYLE)
			-- Initialize paragraph from `a_content` with uniform `a_style`.
		require
			content_not_void: a_content /= Void
			style_not_void: a_style /= Void
		local
			l_text: TEXT
		do
			create l_text.make_styled (a_content, a_style)
			make (l_text)
			style := a_style
		end

feature {TUI_PARAGRAPH} -- Copy on write

	text_store: TEXT
			-- Text, possibly shared with copies of `Current` (see `text_shared`)

	text_shared: BOOLEAN
			-- Is `text_store` shared with another object?

	mark_text_shared
			-- Record that `text_store` is now shared with a copy.
		do
			text_shared := True
		ensure
			shared: text_shared
		end

	own_text
			-- Give `Current` its own copy of the text if they are shared.
		do
			if text_shared then
				text_store := text_store.twin
				text_shared := False
			end
		ensure
			not_shared: not text_shared
		end

feature -- Access

	text: TEXT
			-- The text content to display (owned by `Current`: content still shared with a copy is copied first)
		do
			own_text
			Result := text_store
		ensure
			owned: not text_shared
		end

	style: STYLE
			-- Base style for paragraph

	wrap_mode: NATURAL_8
			-- Text wrapping mode (none, character, word)

	wrap_trim: BOOLEAN
			-- Should leading whitespace be trimmed on wrapped continuation lines?

	alignment: NATURAL_8
			-- Text alignment (left, center, right)

	scroll_x: NATURAL_16
			-- Horizontal scroll offset in columns

	scroll_y: NATURAL_16
			-- Vertical scroll offset in lines

feature -- Element change

	set_text (a_text: TEXT)
			-- Set text content.
		require
			text_not_void: a_text /= Void
		do
			text_store := a_text
			text_shared := False
		ensure
			text_set: text = a_text
		end

	set_style (a_style: STYLE)
			-- Set base style.
		require
			style_not_void: a_style /= Void
		do
			style := a_style
		ensure
			style_set: style = a_style
		end

	set_wrap_mode (a_mode: NATURAL_8; a_trim: BOOLEAN)
			-- Set text wrapping mode and trimming option.
		require
			valid_mode: {TEXT_WRAP_MODE}.is_valid (a_mode)
		do
			wrap_mode := a_mode
			wrap_trim := a_trim
		ensure
			mode_set: wrap_mode = a_mode
			trim_set: wrap_trim = a_trim
		end

	set_alignment (a_align: NATURAL_8)
			-- Set default text alignment.
		require
			valid_align: {TEXT_ALIGNMENT}.is_valid (a_align)
		do
			alignment := a_align
		ensure
			alignment_set: alignment = a_align
		end

	set_scroll (a_x, a_y: NATURAL_16)
			-- Set scroll offsets.
		do
			scroll_x := a_x
			scroll_y := a_y
		ensure
			scroll_x_set: scroll_x = a_x
			scroll_y_set: scroll_y = a_y
		end

feature -- Fluent Builders

	with_style (a_style: STYLE): like Current
			-- Return a copy of Current with specified base style.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_style (a_style)
		ensure
			style_set: Result.style = a_style
			result_not_void: Result /= Void
		end

	with_wrap (a_mode: NATURAL_8; a_trim: BOOLEAN): like Current
			-- Return a copy of Current with specified wrapping configuration.
		require
			valid_mode: {TEXT_WRAP_MODE}.is_valid (a_mode)
		do
			Result := twin
			Result.set_wrap_mode (a_mode, a_trim)
		ensure
			mode_set: Result.wrap_mode = a_mode
			trim_set: Result.wrap_trim = a_trim
			result_not_void: Result /= Void
		end

	with_alignment (a_align: NATURAL_8): like Current
			-- Return a copy of Current with specified text alignment.
		require
			valid_align: {TEXT_ALIGNMENT}.is_valid (a_align)
		do
			Result := twin
			Result.set_alignment (a_align)
		ensure
			alignment_set: Result.alignment = a_align
			result_not_void: Result /= Void
		end

	with_scroll (a_x, a_y: NATURAL_16): like Current
			-- Return a copy of Current with specified scroll offset.
		do
			Result := twin
			Result.set_scroll (a_x, a_y)
		ensure
			scroll_x_set: Result.scroll_x = a_x
			scroll_y_set: Result.scroll_y = a_y
			result_not_void: Result /= Void
		end

feature -- Duplication

	copy (a_other: like Current)
			-- Copy `a_other` to `Current`.
		do
			if a_other /= Current then
				standard_copy (a_other)
				text_shared := True
				a_other.mark_text_shared
			end
		end

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Is `a_other` content-equal to `Current`?
		do
			if a_other = Current then
				Result := True
			elseif standard_is_equal (a_other) then
				Result := True
			else
				Result := text_store.is_equal (a_other.text_store)
					and style.is_equal (a_other.style)
					and wrap_mode = a_other.wrap_mode
					and wrap_trim = a_other.wrap_trim
					and alignment = a_other.alignment
					and scroll_x = a_other.scroll_x
					and scroll_y = a_other.scroll_y
					and same_block (a_other)
			end
		end

feature -- Rendering

	render (a_area: RECT; a_buffer: BUFFER)
			-- Render paragraph within `a_area` on `a_buffer`.
		local
			l_render_area: RECT
			l_lines: ARRAYED_LIST [TEXT_LINE]
			l_row, l_target_row: INTEGER
			l_line_idx: INTEGER
			l_line: TEXT_LINE
			l_align: NATURAL_8
			l_offset: NATURAL_16
			l_col_offset: INTEGER
		do
			if not a_area.is_empty then
				render_block (a_area, a_buffer)
				l_render_area := inner_area (a_area)

				if not l_render_area.is_empty and l_render_area.width > 0 and l_render_area.height > 0 then
					l_lines := {TEXT_LAYOUT}.wrap_text (text_store, l_render_area.width, wrap_mode, wrap_trim)

					from
						l_row := 0
					until
						l_row >= l_render_area.height.to_integer_32
					loop
						l_line_idx := scroll_y.to_integer_32 + l_row + 1
						l_target_row := l_render_area.y.to_integer_32 + l_row

						if l_target_row < a_buffer.height and l_line_idx <= l_lines.count then
							l_line := l_lines.i_th (l_line_idx)
							if l_line.alignment /= {TEXT_ALIGNMENT}.left then
								l_align := l_line.alignment
							else
								l_align := alignment
							end

							l_offset := {TEXT_LAYOUT}.aligned_offset (l_line.width, l_render_area.width, l_align)
							l_col_offset := l_render_area.x.to_integer_32 + l_offset.to_integer_32 - scroll_x.to_integer_32
							render_line (l_line, l_target_row, l_col_offset, l_render_area, a_buffer)
						end
						l_row := l_row + 1
					end
				end
			end
		end

feature {NONE} -- Implementation: Line Rendering

	render_line (a_line: TEXT_LINE; a_row, a_start_col: INTEGER; a_area: RECT; a_buffer: BUFFER)
			-- Paint spans of `a_line` on `a_row` starting at column `a_start_col` clipped by `a_area`.
		do
			a_buffer.set_line_clipped (a_row, a_start_col, a_line, style,
				a_area.x.to_integer_32, a_area.right.to_integer_32)
		end

invariant
	text_not_void: text_store /= Void
	style_not_void: style /= Void
	valid_wrap_mode: {TEXT_WRAP_MODE}.is_valid (wrap_mode)
	valid_alignment: {TEXT_ALIGNMENT}.is_valid (alignment)

end
