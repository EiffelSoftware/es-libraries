note
	description: "[
		Primary coordinator for terminal rendering, managing the backend, dual framebuffers
		(current and previous frames), diff calculation, and agent-based draw cycles.

		Viewports:
		  * Fullscreen: buffers follow the backend size; a resize clears the screen.
		  * Inline: `setup_inline_viewport' places the viewport at the cursor (DSR query),
		    scrolling the screen when needed; `insert_before' writes rows above it that
		    scroll into the scrollback; `restore_inline_viewport' leaves the cursor below it.
		  * Fixed: buffers follow the fixed area; `resize' changes that area.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TERMINAL [B -> TERMINAL_BACKEND]

create
	make,
	make_with_viewport

feature {NONE} -- Initialization

	make (a_backend: B)
			-- Initialize terminal coordinator with `a_backend` in fullscreen mode.
		require
			backend_not_void: a_backend /= Void
		do
			make_with_viewport (a_backend, create {VIEWPORT}.make_fullscreen)
		ensure
			backend_set: backend = a_backend
			fullscreen_default: viewport.is_fullscreen
		end

	make_with_viewport (a_backend: B; a_viewport: VIEWPORT)
			-- Initialize terminal coordinator with `a_backend` and `a_viewport`.
		require
			backend_not_void: a_backend /= Void
			viewport_not_void: a_viewport /= Void
		do
			backend := a_backend
			viewport := a_viewport
			create current_buffer.make (target_width, target_height)
			create previous_buffer.make (target_width, target_height)
			create diff_engine
			create ansi_serializer
		ensure
			backend_set: backend = a_backend
			viewport_set: viewport = a_viewport
		end

feature -- Access

	backend: B
			-- Underlying terminal I/O backend

	viewport: VIEWPORT
			-- Current viewport mode (Fullscreen, Inline, or Fixed)

	current_buffer: BUFFER
			-- Active framebuffer receiving current draw calls

	previous_buffer: BUFFER
			-- Historical framebuffer representing current screen contents

	width: INTEGER
			-- Width in columns of the current terminal viewport
		do
			Result := current_buffer.width
		ensure
			correct_width: Result = current_buffer.width
		end

	height: INTEGER
			-- Height in rows of the current terminal viewport
		do
			Result := current_buffer.height
		ensure
			correct_height: Result = current_buffer.height
		end

	viewport_origin_col: INTEGER
			-- Effective X origin of viewport on the underlying terminal screen
		do
			if viewport.is_fixed and attached viewport.fixed_area as fa then
				Result := fa.x.to_integer_32
			else
				Result := viewport.origin_column
			end
		ensure
			non_negative: Result >= 0
		end

	viewport_origin_row: INTEGER
			-- Effective Y origin of viewport on the underlying terminal screen
		do
			if viewport.is_fixed and attached viewport.fixed_area as fa then
				Result := fa.y.to_integer_32
			else
				Result := viewport.origin_row
			end
		ensure
			non_negative: Result >= 0
		end

feature -- Drawing

	draw (a_render_pass: PROCEDURE [FRAME])
			-- Execute `a_render_pass` agent with a fresh FRAME, compute delta diffs,
			-- serialize changes to `backend`, and flush to screen.
		require
			render_pass_not_void: a_render_pass /= Void
		local
			l_frame: FRAME
			l_spans: ARRAYED_LIST [DIFF_SPAN]
			l_old: BUFFER
		do
			autoresize

			-- Reset back buffer
			current_buffer.clear

			-- Dispatch rendering agent
			create l_frame.make (current_buffer)
			a_render_pass.call ([l_frame])

			-- Differential rendering pass
			l_spans := diff_engine.diff (previous_buffer, current_buffer)
			if not l_spans.is_empty then
				ansi_serializer.render_spans_with_offset (l_spans, backend, viewport_origin_col, viewport_origin_row)
			end
			-- The frame just drawn is now what the screen shows: swap instead of copying cells.
			-- The old previous buffer is cleared in place by the next `draw`.
			l_old := previous_buffer
			previous_buffer := current_buffer
			current_buffer := l_old

			-- Hardware cursor management
			if attached l_frame.cursor_position as pos then
				backend.move_cursor (pos.integer_32_item (2) + viewport_origin_row, pos.integer_32_item (1) + viewport_origin_col)
				backend.show_cursor
			else
				if not l_frame.is_cursor_visible then
					backend.hide_cursor
				end
			end
			backend.flush
		end

	autoresize
			-- Match the buffers to the backend size (fullscreen and inline viewports) or to the
			-- fixed area. When the size changes, the old screen contents are erased: the whole
			-- screen for fullscreen/fixed viewports, only the viewport rows for inline ones.
		do
			backend.refresh_size
			if viewport.is_inline and viewport_origin_row + target_height > backend.height then
				-- The terminal got shorter: keep the viewport on screen
				viewport.set_origin ((backend.height - target_height).max (0), viewport.origin_column)
			end
			if target_width /= current_buffer.width or target_height /= current_buffer.height then
				create current_buffer.make (target_width, target_height)
				create previous_buffer.make (target_width, target_height)
				-- Pooled spans are sized by the old frames and refer to the old buffers' cells
				diff_engine.discard_pool
				if viewport.is_inline then
					clear_viewport_rows
				else
					backend.clear_screen
				end
			end
		ensure
			width_matches: width = target_width
			height_matches: height = target_height
		end

feature -- Inline viewport

	setup_inline_viewport
			-- Place the inline viewport on the current cursor row (asked to the terminal with
			-- a DSR query), scrolling the screen up when the viewport would not fit below it,
			-- and blank the viewport rows. Call in raw mode, before any input reader runs.
		require
			inline_viewport: viewport.is_inline
			input_not_in_use: not backend.is_input_in_use
		local
			l_row, l_overflow: INTEGER
		do
			backend.refresh_size
			if attached backend.query_cursor_position as l_pos then
				l_row := l_pos.row
			else
				l_row := backend.cursor_row
			end
			l_overflow := l_row + target_height - backend.height
			if l_overflow > 0 then
				backend.scroll_up (l_overflow)
				l_row := backend.height - target_height
			end
			viewport.set_origin (l_row.max (0), 0)
			create current_buffer.make (target_width, target_height)
			create previous_buffer.make (target_width, target_height)
			clear_viewport_rows
			backend.flush
		ensure
			viewport_on_screen: viewport_origin_row + height <= backend.height.max (height)
		end

	insert_before (a_lines: INTEGER; a_draw: PROCEDURE [BUFFER])
			-- Insert `a_lines` rows, drawn by `a_draw` into a `width` x `a_lines` buffer, just
			-- above the inline viewport. The viewport moves down while there is room below it;
			-- after that the screen scrolls, pushing the oldest rows into the scrollback.
		require
			inline_viewport: viewport.is_inline
			positive_lines: a_lines > 0
			draw_not_void: a_draw /= Void
		local
			l_lines: BUFFER
			l_room, l_chunk, l_top, l_free_below, r: INTEGER
		do
			autoresize
			create l_lines.make (width, a_lines)
			a_draw.call ([l_lines])
			-- Rows available above the viewport once it sits at the bottom of the screen
			l_room := backend.height - height
			from
				r := 0
			until
				r >= a_lines
			loop
				if l_room <= 0 then
					-- The viewport fills the screen: write the row on top, then scroll it away
					write_rows (l_lines, r, 1, 0)
					backend.scroll_up (1)
					l_chunk := 1
				else
					l_chunk := (a_lines - r).min (l_room)
					l_top := viewport_origin_row
					l_free_below := backend.height - (l_top + height)
					if l_free_below < l_chunk then
						backend.scroll_up (l_chunk - l_free_below)
						l_top := l_top - (l_chunk - l_free_below)
					end
					write_rows (l_lines, r, l_chunk, l_top)
					viewport.set_origin (l_top + l_chunk, viewport.origin_column)
				end
				r := r + l_chunk
			end
			-- The viewport moved or was scrolled: repaint it completely on the next draw
			clear_viewport_rows
			create previous_buffer.make (width, height)
			backend.flush
		ensure
			viewport_on_screen: viewport_origin_row + height <= backend.height.max (height)
		end

	restore_inline_viewport
			-- Leave the cursor at the start of the row below the inline viewport, so that
			-- the shell prompt appears after the last frame instead of over it.
		require
			inline_viewport: viewport.is_inline
		do
			if viewport_origin_row + height < backend.height then
				backend.move_cursor (viewport_origin_row + height, 0)
			elseif backend.height > 0 then
				backend.scroll_up (1)
			end
			backend.flush
		end

feature -- Terminal Mode & Screen Control

	enter_raw_mode
			-- Put terminal into raw mode.
		do
			backend.enter_raw_mode
		end

	leave_raw_mode
			-- Restore cooked mode.
		do
			backend.leave_raw_mode
		end

	enter_alternate_screen
			-- Switch to alternate screen buffer.
		do
			backend.enter_alternate_screen
		end

	leave_alternate_screen
			-- Restore primary screen buffer.
		do
			backend.leave_alternate_screen
		end

	hide_cursor
			-- Make terminal cursor invisible.
		do
			backend.hide_cursor
		end

	show_cursor
			-- Make terminal cursor visible.
		do
			backend.show_cursor
		end

	clear_screen
			-- Clear terminal screen.
		do
			backend.clear_screen
		end

	resize (a_area: RECT)
			-- Move a fixed viewport to `a_area`, resize the buffers and clear the screen.
			-- Fullscreen and inline viewports follow the backend size automatically (`autoresize`).
		require
			fixed_viewport: viewport.is_fixed
			area_not_void: a_area /= Void
			non_empty_area: a_area.width > 0 and a_area.height > 0
		do
			viewport.set_fixed_area (a_area)
			create current_buffer.make (a_area.width.to_integer_32, a_area.height.to_integer_32)
			create previous_buffer.make (a_area.width.to_integer_32, a_area.height.to_integer_32)
			diff_engine.discard_pool
			backend.clear_screen
		ensure
			width_set: width = a_area.width.to_integer_32
			height_set: height = a_area.height.to_integer_32
		end

	enable_mouse_capture
			-- Enable mouse event capture.
		do
			backend.enable_mouse_capture
		end

	disable_mouse_capture
			-- Disable mouse event capture.
		do
			backend.disable_mouse_capture
		end

	enable_bracketed_paste
			-- Enable bracketed paste reporting.
		do
			backend.enable_bracketed_paste
		end

	disable_bracketed_paste
			-- Disable bracketed paste reporting.
		do
			backend.disable_bracketed_paste
		end

	enable_focus_change
			-- Enable focus reporting events.
		do
			backend.enable_focus_change
		end

	disable_focus_change
			-- Disable focus reporting events.
		do
			backend.disable_focus_change
		end

feature {NONE} -- Implementation

	diff_engine: DIFF_ENGINE
			-- Framebuffer delta comparison engine

	ansi_serializer: ANSI_SERIALIZER
			-- ANSI escape code batch serializer

	target_width: INTEGER
			-- Buffer width required by `viewport` for the current backend size
		do
			if viewport.is_fixed and attached viewport.fixed_area as fa then
				Result := fa.width.to_integer_32.max (1)
			else
				Result := backend.width.max (1)
			end
		ensure
			positive: Result > 0
		end

	target_height: INTEGER
			-- Buffer height required by `viewport` for the current backend size
		do
			if viewport.is_inline then
				Result := viewport.inline_height.to_integer_32
				if backend.height > 0 then
					Result := Result.min (backend.height)
				end
				Result := Result.max (1)
			elseif viewport.is_fixed and attached viewport.fixed_area as fa then
				Result := fa.height.to_integer_32.max (1)
			else
				Result := backend.height.max (1)
			end
		ensure
			positive: Result > 0
		end

	clear_viewport_rows
			-- Blank the screen rows covered by the viewport.
		local
			r: INTEGER
		do
			from
				r := viewport_origin_row
			until
				r >= viewport_origin_row + height or (backend.height > 0 and r >= backend.height)
			loop
				backend.clear_line (r)
				r := r + 1
			end
		end

	write_rows (a_lines: BUFFER; a_first, a_count, a_screen_row: INTEGER)
			-- Write rows `a_first` .. `a_first + a_count - 1` of `a_lines` to the screen starting
			-- at `a_screen_row`, blanking each target row first.
		require
			valid_range: a_first >= 0 and a_count > 0 and a_first + a_count <= a_lines.height
			non_negative_row: a_screen_row >= 0
		local
			l_chunk, l_blank: BUFFER
			r, c: INTEGER
		do
			create l_chunk.make (a_lines.width, a_count)
			create l_blank.make (a_lines.width, a_count)
			from
				r := 0
			until
				r >= a_count
			loop
				backend.clear_line (a_screen_row + r)
				from
					c := 0
				until
					c >= a_lines.width
				loop
					l_chunk.put_cell (r, c, a_lines.cell (a_first + r, c))
					c := c + 1
				end
				r := r + 1
			end
			ansi_serializer.render_spans_with_offset (diff_engine.diff (l_blank, l_chunk), backend, viewport_origin_col, a_screen_row)
		end

invariant
	backend_not_void: backend /= Void
	current_buffer_not_void: current_buffer /= Void
	previous_buffer_not_void: previous_buffer /= Void

end
