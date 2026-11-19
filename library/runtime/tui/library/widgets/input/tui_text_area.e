note
	description: "[
		Multi-line text editor widget with vertical scrolling, soft wrap (character or
		word), selection highlighting, and hardware cursor positioning.
		Rendering records the row layout in the TEXT_AREA_STATE, so that Up/Down move
		by visual rows until the next edit.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_TEXT_AREA

inherit
	STATEFUL_WIDGET [TEXT_AREA_STATE]
		redefine
			default_create
		end
	BLOCK_CONTAINER
		redefine
			default_create
		end
	HIT_TARGET
		redefine
			default_create
		end

create
	default_create,
	make

feature {NONE} -- Initialization

	default_create
			-- Initialize with default styling and character wrap.
		do
			create style.default_create
			create cursor_style.default_create
			cursor_style := cursor_style.with_reverse
			create selection_style.make_with_colors ({COLOR}.Black, {COLOR}.Bright_blue)
			create placeholder_style.default_create
			placeholder_style := placeholder_style.with_dim
			shows_cursor := True
			cursor_shape := {CURSOR_SHAPE}.Steady_bar
			wrap_mode := {TEXT_WRAP_MODE}.character
		ensure then
			shows_cursor_default: shows_cursor
			bar_by_default: cursor_shape ~ {CURSOR_SHAPE}.Steady_bar
		end

	make
			-- Synonym for `default_create`.
		do
			default_create
		end

feature -- Access

	style: STYLE
			-- Style for body text

	cursor_style: STYLE
			-- Style for the cursor cell

	selection_style: STYLE
			-- Style for the selected range

	placeholder_style: STYLE
			-- Style for placeholder text

	placeholder: detachable STRING_32
			-- Placeholder when the buffer is empty

	shows_cursor: BOOLEAN
			-- Whether the cursor cell is highlighted

	cursor_shape: CURSOR_SHAPE
			-- Hardware cursor shape to ask for with `{FRAME}.set_cursor_shape` when the
			-- application shows the cursor at `cursor_screen_position` (default: steady bar)

	wrap_mode: NATURAL_8
			-- Soft wrap mode for display

feature -- Element change

	set_style (a_style: STYLE)
		require
			style_attached: a_style /= Void
		do
			style := a_style
		end

	set_cursor_style (a_style: STYLE)
		require
			style_attached: a_style /= Void
		do
			cursor_style := a_style
		end

	set_selection_style (a_style: STYLE)
		require
			style_attached: a_style /= Void
		do
			selection_style := a_style
		end

	set_placeholder_style (a_style: STYLE)
		require
			style_attached: a_style /= Void
		do
			placeholder_style := a_style
		end

	set_placeholder (a_placeholder: detachable READABLE_STRING_GENERAL)
		do
			if attached a_placeholder as p then
				create placeholder.make_from_string_general (p)
			else
				placeholder := Void
			end
		end

	set_shows_cursor (a_val: BOOLEAN)
		do
			shows_cursor := a_val
		end

	set_cursor_shape (a_shape: CURSOR_SHAPE)
			-- Set the hardware cursor shape to `a_shape`.
		require
			shape_attached: a_shape /= Void
		do
			cursor_shape := a_shape
		ensure
			cursor_shape_set: cursor_shape = a_shape
		end

	set_wrap_mode (a_mode: NATURAL_8)
		require
			valid: {TEXT_WRAP_MODE}.is_valid (a_mode)
		do
			wrap_mode := a_mode
		end

feature -- Fluent builders

	with_style (a_style: STYLE): like Current
		require
			style_attached: a_style /= Void
		do
			Result := twin
			Result.set_style (a_style)
		end

	with_shows_cursor (a_val: BOOLEAN): like Current
		do
			Result := twin
			Result.set_shows_cursor (a_val)
		end

	with_placeholder (a_placeholder: detachable READABLE_STRING_GENERAL): like Current
		do
			Result := twin
			Result.set_placeholder (a_placeholder)
		end

	with_cursor_shape (a_shape: CURSOR_SHAPE): like Current
			-- Copy of Current with `cursor_shape` set to `a_shape`.
		require
			shape_attached: a_shape /= Void
		do
			Result := twin
			Result.set_cursor_shape (a_shape)
		ensure
			cursor_shape_set: Result.cursor_shape = a_shape
		end

	with_wrap_mode (a_mode: NATURAL_8): like Current
		require
			valid: {TEXT_WRAP_MODE}.is_valid (a_mode)
		do
			Result := twin
			Result.set_wrap_mode (a_mode)
		end

feature -- Rendering

	render (a_area: RECT; a_buffer: BUFFER)
			-- Stateless render with an empty state.
		local
			l_state: TEXT_AREA_STATE
		do
			create l_state.default_create
			render_stateful (a_area, a_buffer, l_state)
		end

	render_stateful (a_area: RECT; a_buffer: BUFFER; a_state: TEXT_AREA_STATE)
			-- Render `a_state` into `a_area`, scroll it to the cursor's visual row and
			-- record the row layout in `a_state` (for Up/Down by visual rows).
		local
			l_target: RECT
			l_pack: TUPLE [lines: ARRAYED_LIST [STRING_32]; starts: ARRAYED_LIST [INTEGER]]
			l_lines: ARRAYED_LIST [STRING_32]
			l_starts: ARRAYED_LIST [INTEGER]
			l_view_row, i, l_y, l_x: INTEGER
		do
			if not a_area.is_empty then
				render_block (a_area, a_buffer)
				l_target := inner_area (a_area)
				if not l_target.is_empty then
					l_pack := build_visual_lines (a_state.value, l_target.width.to_integer_32, a_state.cursor_position)
					l_lines := l_pack.lines
					l_starts := l_pack.starts
					a_state.set_visual_rows (l_starts)
					a_state.scroll_to_row ({TEXT_AREA_STATE}.visual_row_index (a_state.cursor_position, l_starts),
						l_target.height.to_integer_32, l_lines.count)
					from
						l_view_row := 0
						i := a_state.scroll_row + 1
					until
						l_view_row >= l_target.height.to_integer_32 or i > l_lines.count
					loop
						l_y := l_target.y.to_integer_32 + l_view_row
						l_x := l_target.x.to_integer_32
						if a_state.value.is_empty and l_view_row = 0 and attached placeholder as pl then
							a_buffer.set_string_clipped (l_y, l_x, pl, l_x, l_target.right.to_integer_32, style.patch (placeholder_style))
						else
							paint_line (a_buffer, l_y, l_x, l_target.right.to_integer_32, l_lines.i_th (i), l_starts.i_th (i), a_state)
						end
						l_view_row := l_view_row + 1
						i := i + 1
					end
					if shows_cursor then
						paint_cursor (a_buffer, l_target, a_state, l_lines, l_starts)
					end
				end
			end
		end

feature -- Cursor

	cursor_screen_position (a_area: RECT; a_state: TEXT_AREA_STATE): detachable TUPLE [col, row: INTEGER]
			-- Hardware cursor cell for `a_state` in `a_area`, or Void if off-screen.
		require
			area_attached: a_area /= Void
			state_attached: a_state /= Void
		local
			l_target: RECT
			l_pack: TUPLE [lines: ARRAYED_LIST [STRING_32]; starts: ARRAYED_LIST [INTEGER]]
		do
			l_target := inner_area (a_area)
			if not l_target.is_empty then
				l_pack := build_visual_lines (a_state.value, l_target.width.to_integer_32, a_state.cursor_position)
				Result := cursor_cell (l_target, a_state, l_pack.lines, l_pack.starts)
			end
		end

feature {NONE} -- Layout helpers

	build_visual_lines (a_text: READABLE_STRING_32; a_width, a_cursor: INTEGER): TUPLE [lines: ARRAYED_LIST [STRING_32]; starts: ARRAYED_LIST [INTEGER]]
			-- Soft-wrap `a_text` into visual rows of at most `a_width` columns.
			-- `a_cursor` is the cursor offset: a wrapped hard line that exactly fills the
			-- width gets an empty row after it when the cursor is at its end, so that the
			-- cursor is not drawn on the column past the area.
		local
			l_lines: ARRAYED_LIST [STRING_32]
			l_starts: ARRAYED_LIST [INTEGER]
			l_hard: STRING_32
			l_pos, l_hard_start, i: INTEGER
		do
			create l_lines.make (8)
			create l_starts.make (8)
			if a_text.is_empty then
				l_lines.extend (create {STRING_32}.make_empty)
				l_starts.extend (0)
			else
				from
					l_pos := 0
				until
					l_pos > a_text.count
				loop
					l_hard_start := l_pos
					from
						i := l_pos + 1
					until
						i > a_text.count or else a_text.code (i) = 10
					loop
						i := i + 1
					end
					l_hard := a_text.substring (l_pos + 1, i - 1).as_string_32
					if a_width <= 0 or wrap_mode = {TEXT_WRAP_MODE}.none then
						l_lines.extend (l_hard)
						l_starts.extend (l_hard_start)
					else
						wrap_hard_line (l_hard, l_hard_start, a_width, a_cursor = l_hard_start + l_hard.count, l_lines, l_starts)
					end
					if i <= a_text.count and then a_text.code (i) = 10 then
						l_pos := i
						if l_pos = a_text.count then
								-- (The text ends with a line break: one empty row after it, and the end.)
							l_lines.extend (create {STRING_32}.make_empty)
							l_starts.extend (l_pos)
							l_pos := a_text.count + 1
						end
					else
						l_pos := a_text.count + 1
					end
				end
			end
			Result := [l_lines, l_starts]
		ensure
			same_count: Result.lines.count = Result.starts.count
			first_row_at_zero: Result.starts.first = 0
		end

	wrap_hard_line (a_hard: STRING_32; a_start, a_width: INTEGER; a_cursor_at_end: BOOLEAN; a_lines: ARRAYED_LIST [STRING_32]; a_starts: ARRAYED_LIST [INTEGER])
			-- Wrap one hard line into `a_lines`, starting at offset `a_start` of the text.
			-- Character mode breaks before the grapheme that does not fit. Word mode breaks
			-- after the last space of the row instead, and lets spaces hang past the width
			-- (as CSS `pre-wrap` does), so every character stays on a row.
			-- `a_cursor_at_end`: add an empty row when the last row is full (see `build_visual_lines`).
		local
			i, l_end, l_w, l_cw, l_seg_start, l_break: INTEGER
			l_is_word, l_is_space: BOOLEAN
		do
			l_is_word := wrap_mode = {TEXT_WRAP_MODE}.word
			if a_hard.is_empty then
				a_lines.extend (a_hard)
				a_starts.extend (a_start)
			else
				from
					i := 1
					l_seg_start := 1
					l_w := 0
				until
					i > a_hard.count
				loop
					l_end := {UNICODE_WIDTH}.grapheme_end (a_hard, i)
					l_cw := {UNICODE_WIDTH}.string_width (a_hard.substring (i, l_end)).to_integer_32
					l_is_space := a_hard.code (i) = 32
					if l_w > 0 and l_w + l_cw > a_width and not (l_is_word and l_is_space) then
						if l_is_word and l_break > l_seg_start then
								-- Break after the last space; the word so far moves down.
							a_lines.extend (a_hard.substring (l_seg_start, l_break - 1))
							a_starts.extend (a_start + l_seg_start - 1)
							l_w := {UNICODE_WIDTH}.string_width (a_hard.substring (l_break, i - 1)).to_integer_32
							l_seg_start := l_break
						end
						if l_seg_start = i or l_w + l_cw > a_width then
								-- No space to break at, or the word alone is too wide.
							if l_seg_start < i then
								a_lines.extend (a_hard.substring (l_seg_start, i - 1))
								a_starts.extend (a_start + l_seg_start - 1)
							end
							l_seg_start := i
							l_w := 0
						end
						l_break := 0
					end
					l_w := l_w + l_cw
					i := l_end + 1
					if l_is_word and l_is_space then
						l_break := i
					end
				end
				a_lines.extend (a_hard.substring (l_seg_start, a_hard.count))
				a_starts.extend (a_start + l_seg_start - 1)
				if a_cursor_at_end and l_w >= a_width then
					a_lines.extend (create {STRING_32}.make_empty)
					a_starts.extend (a_start + a_hard.count)
				end
			end
		end

	paint_line (a_buffer: BUFFER; a_row, a_left, a_right: INTEGER; a_line: STRING_32; a_src_start: INTEGER; a_state: TEXT_AREA_STATE)
			-- Paint one visual line (text offset `a_src_start`), then patch
			-- `selection_style` onto the columns of the selected part of it.
		local
			l_from, l_to, l_x, l_w: INTEGER
		do
			a_buffer.set_string_clipped (a_row, a_left, a_line, a_left, a_right, style)
			if a_state.has_selection then
				l_from := (a_state.selection_start - a_src_start).max (0).min (a_line.count)
				l_to := (a_state.selection_end - a_src_start).max (0).min (a_line.count)
				if l_from < l_to then
					l_x := a_left + {UNICODE_WIDTH}.string_width (a_line.substring (1, l_from)).to_integer_32
					l_w := {UNICODE_WIDTH}.string_width (a_line.substring (l_from + 1, l_to)).to_integer_32
					l_w := l_w.min (a_right - l_x)
					if l_w > 0 then
						a_buffer.set_style (create {RECT}.make (l_x.to_natural_16, a_row.to_natural_16, l_w.to_natural_16, 1), selection_style)
					end
				end
			end
		end

	paint_cursor (a_buffer: BUFFER; a_area: RECT; a_state: TEXT_AREA_STATE; a_lines: ARRAYED_LIST [STRING_32]; a_starts: ARRAYED_LIST [INTEGER])
			-- Highlight the cursor cell when on-screen: patch `cursor_style` onto the
			-- grapheme under the cursor, or draw a blank cursor cell at the end of a line.
		local
			l_pos, l_w: INTEGER
			l_text: READABLE_STRING_32
		do
			if attached cursor_cell (a_area, a_state, a_lines, a_starts) as c and then a_buffer.is_valid_position (c.row, c.col) then
				l_text := a_state.value
				l_pos := a_state.cursor_position
				if l_pos = l_text.count or else l_text.code (l_pos + 1) = 10 then
					a_buffer.put_char (c.row, c.col, ' ', style.patch (cursor_style))
				else
						-- A zero-width cluster is shown with the previous cell: highlight one cell.
					l_w := {UNICODE_WIDTH}.string_width (l_text.substring (l_pos + 1,
						{UNICODE_WIDTH}.grapheme_end (l_text, l_pos + 1))).to_integer_32.max (1)
					l_w := l_w.min (a_area.right.to_integer_32 - c.col)
					a_buffer.set_style (create {RECT}.make (c.col.to_natural_16, c.row.to_natural_16, l_w.to_natural_16, 1), cursor_style)
				end
			end
		end

	cursor_cell (a_area: RECT; a_state: TEXT_AREA_STATE; a_lines: ARRAYED_LIST [STRING_32]; a_starts: ARRAYED_LIST [INTEGER]): detachable TUPLE [col, row: INTEGER]
			-- Screen cell of the cursor in inner area `a_area` with layout `a_lines`/`a_starts`,
			-- or Void when it is scrolled out or past the right edge (no wrap).
			-- A cursor on a space hanging past the width (word wrap) is shown on the last column.
		local
			l_vis, l_col: INTEGER
		do
			l_vis := {TEXT_AREA_STATE}.visual_row_index (a_state.cursor_position, a_starts) - a_state.scroll_row
			if l_vis >= 0 and l_vis < a_area.height.to_integer_32 then
				l_col := column_in_visual (a_state, a_starts, a_lines)
				if l_col >= a_area.width.to_integer_32 and wrap_mode /= {TEXT_WRAP_MODE}.none then
					l_col := a_area.width.to_integer_32 - 1
				end
				if l_col < a_area.width.to_integer_32 then
					Result := [a_area.x.to_integer_32 + l_col, a_area.y.to_integer_32 + l_vis]
				end
			end
		end

	column_in_visual (a_state: TEXT_AREA_STATE; a_starts: ARRAYED_LIST [INTEGER]; a_lines: ARRAYED_LIST [STRING_32]): INTEGER
			-- Display column of the cursor within its visual row.
		local
			l_row, l_start: INTEGER
			l_line: STRING_32
		do
			l_row := {TEXT_AREA_STATE}.visual_row_index (a_state.cursor_position, a_starts) + 1
			l_start := a_starts.i_th (l_row)
			l_line := a_lines.i_th (l_row)
			if a_state.cursor_position > l_start then
				Result := {UNICODE_WIDTH}.string_width (a_state.value.substring (l_start + 1, a_state.cursor_position.min (l_start + l_line.count))).to_integer_32
			end
		end

invariant
	style_attached: style /= Void
	cursor_style_attached: cursor_style /= Void
	selection_style_attached: selection_style /= Void
	cursor_shape_attached: cursor_shape /= Void
	valid_wrap: {TEXT_WRAP_MODE}.is_valid (wrap_mode)

end
