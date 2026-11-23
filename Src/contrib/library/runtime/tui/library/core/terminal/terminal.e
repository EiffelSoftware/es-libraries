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
			insert_block_limit := {BUFFER}.Max_extent
			clipboard_limit := Default_clipboard_limit
		ensure
			backend_set: backend = a_backend
			viewport_set: viewport = a_viewport
			default_block_limit: insert_block_limit = {BUFFER}.Max_extent
			default_clipboard_limit: clipboard_limit = Default_clipboard_limit
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

	shown_area: detachable RECT
			-- Screen area (screen coordinates) showing the frame that the last `draw` flushed;
			-- Void before the first `draw` and once anything erased, scrolled or moved the
			-- viewport since (resize, `insert_before`, `clear_screen`, setup, suspend):
			-- until the next `draw`, the screen does not show that frame there.

	is_cursor_shape_uncertain: BOOLEAN
			-- May the terminal show its default cursor shape instead of the one last written
			-- (`backend.cursor_shape`)? Set by `forget_shown_frame`: a stop's signal handler
			-- resets the shape to the default behind the backend's back. The next `draw` then
			-- writes the frame's shape even when it equals the one last written, unless it is
			-- the default. Cleared by `draw`.

	title: detachable STRING_32
			-- Window title last set with `set_title`, sanitized ({WINDOW_TITLE}.sanitized);
			-- Void before the first. The one record of the title: `show_title` writes it again
			-- after every setup, also when it was set while the terminal was not shown.

	is_title_shown: BOOLEAN
			-- Does the terminal show `title`, with its own title saved, between `show_title`
			-- and `restore_title`? Only then does `draw` write a new `title`.

	is_title_stale: BOOLEAN
			-- Was `title` changed since it was last written? `draw` writes it while
			-- `is_title_shown`.

	clipboard_limit: INTEGER
			-- Largest OSC 52 payload `copy_to_clipboard` sends, in base64 characters (bytes
			-- on the wire). Terminals cut longer payloads, mostly without a word (xterm,
			-- kitty, WezTerm and Windows Terminal each have their own limit, not checked
			-- here), so a copy that does not fit is refused rather than sent cut.

	Default_clipboard_limit: INTEGER = 100_000
			-- `clipboard_limit` of a new terminal

feature -- Status setting

	forget_shown_frame
			-- Record that the screen no longer shows the last drawn frame (`shown_area`),
			-- and that the cursor shape may have been reset to the default since
			-- (`is_cursor_shape_uncertain`), so that a resume writes the shape again.
		do
			shown_area := Void
			is_cursor_shape_uncertain := True
		ensure
			forgotten: shown_area = Void
			shape_uncertain: is_cursor_shape_uncertain
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

			-- Hardware cursor shape: written only when it changes, as SGR attributes are
			if is_cursor_shape_stale (l_frame.cursor_shape) then
				backend.set_cursor_shape (l_frame.cursor_shape)
			end
			is_cursor_shape_uncertain := False

			-- Window title set since the last frame, only while it is shown: before
			-- `show_title`, the terminal's own title is not saved yet
			if is_title_shown and is_title_stale and then attached title as l_title then
				backend.set_title (l_title)
				is_title_stale := False
			end

			-- Clipboard read requests made since the last frame
			across clipboard_requests as r loop
				backend.request_clipboard_contents (r)
			end
			clipboard_requests.wipe_out

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
			create shown_area.make (viewport_origin_col.to_natural_16, viewport_origin_row.to_natural_16,
				width.to_natural_16, height.to_natural_16)
		ensure
			requests_written: not has_clipboard_request
			shown: attached shown_area as l_shown and then (l_shown.x.to_integer_32 = viewport_origin_col
				and l_shown.y.to_integer_32 = viewport_origin_row
				and l_shown.width.to_integer_32 = width and l_shown.height.to_integer_32 = height)
			shape_certain: not is_cursor_shape_uncertain
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
				forget_shown_frame
			end
			if target_width /= current_buffer.width or target_height /= current_buffer.height then
				forget_shown_frame
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

	invalidate
			-- Forget what the screen shows and clear it, so that the next `draw` repaints every
			-- cell (e.g. after another program has used the terminal).
		do
			create previous_buffer.make (previous_buffer.width, previous_buffer.height)
			diff_engine.discard_pool
			if viewport.is_inline then
				clear_viewport_rows
			else
				backend.clear_screen
			end
		ensure
			width_unchanged: width = old width
			height_unchanged: height = old height
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
			forget_shown_frame
			backend.flush
		ensure
			viewport_on_screen: viewport_origin_row + height <= backend.height.max (height)
			nothing_shown: shown_area = Void
		end

	insert_before (a_lines: INTEGER; a_draw: PROCEDURE [BUFFER])
			-- Insert `a_lines` rows, drawn by `a_draw` into a `width` x `a_lines` buffer, just
			-- above the inline viewport. The viewport moves down while there is room below it;
			-- after that the screen scrolls, pushing the oldest rows into the scrollback.
			-- A buffer holds at most {BUFFER}.Max_extent (65535) rows (Ratatui's `insert_before`
			-- takes a u16). For more, `a_draw` is called once per block of `insert_block_limit`
			-- (65535) rows, top to bottom, the last block holding the rest; each block is on screen
			-- before the next is drawn. Use `insert_before_rows` to know where a block starts.
		require
			inline_viewport: viewport.is_inline
			positive_lines: a_lines > 0
			draw_not_void: a_draw /= Void
		do
			insert_before_rows (a_lines, agent draw_block (a_draw, ?, ?))
		ensure
			viewport_on_screen: viewport_origin_row + height <= backend.height.max (height)
			nothing_shown: shown_area = Void
		end

	insert_before_rows (a_lines: INTEGER; a_draw: PROCEDURE [BUFFER, INTEGER])
			-- Insert `a_lines` rows just above the inline viewport, as `insert_before`, drawn by
			-- `a_draw` in blocks of at most `insert_block_limit` ({BUFFER}.Max_extent) rows: `a_draw`
			-- gets a `width` x n buffer for rows `first` .. `first + n - 1` of the inserted rows
			-- (0-based `first`), top to bottom. Up to 65535 rows are one block with `first` = 0.
		require
			inline_viewport: viewport.is_inline
			positive_lines: a_lines > 0
			draw_not_void: a_draw /= Void
		local
			l_block: BUFFER
			l_room, l_first, l_count: INTEGER
		do
			autoresize
			-- Rows available above the viewport once it sits at the bottom of the screen
			l_room := backend.height - height
			from
				l_first := 0
			until
				l_first >= a_lines
			loop
				l_count := (a_lines - l_first).min (insert_block_limit)
				create l_block.make (width, l_count)
				a_draw.call ([l_block, l_first])
				insert_block (l_block, l_room)
				l_first := l_first + l_count
			variant
				a_lines - l_first
			end
			-- The viewport moved or was scrolled: repaint it completely on the next draw
			clear_viewport_rows
			create previous_buffer.make (width, height)
			forget_shown_frame
			backend.flush
		ensure
			viewport_on_screen: viewport_origin_row + height <= backend.height.max (height)
			nothing_shown: shown_area = Void
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
			forget_shown_frame
			backend.flush
		ensure
			nothing_shown: shown_area = Void
		end

feature -- Access: inserted rows

	insert_block_limit: INTEGER
			-- Most rows `insert_before` and `insert_before_rows` draw in one block:
			-- {BUFFER}.Max_extent, the most rows a buffer holds. Only tests lower it, to cross
			-- block edges with a few rows (`set_insert_block_limit`).

feature {TERMINAL_TEST_ACCESS} -- Testing

	set_insert_block_limit (a_limit: INTEGER)
			-- Draw inserted rows in blocks of at most `a_limit` rows (for tests).
		require
			positive_limit: a_limit > 0
			limit_in_buffer_range: a_limit <= {BUFFER}.Max_extent
		do
			insert_block_limit := a_limit
		ensure
			limit_set: insert_block_limit = a_limit
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

	reset_cursor_shape
			-- Give the terminal back its user's default cursor shape (`CSI 0 SP q`) if the
			-- shape last written was another one. Part of restoring the terminal: crossterm
			-- leaves this to the application.
		do
			if not backend.cursor_shape.is_default then
				backend.set_cursor_shape ({CURSOR_SHAPE}.Default_user)
			end
		ensure
			default_shape: backend.cursor_shape.is_default
		end

	set_title (a_title: READABLE_STRING_GENERAL)
			-- Make `a_title` without its control characters ({WINDOW_TITLE}.sanitized) the
			-- terminal's window title, sent as UTF-8 in OSC 0 (crossterm `SetTitle`). Writes
			-- nothing itself: the next `draw` writes it while `is_title_shown`, otherwise
			-- `show_title` does. So a title set while the terminal is not the application's
			-- (before setup, stopped, waiting in the background) is never written there, and
			-- is not lost by a stop.
		require
			title_attached: a_title /= Void
		do
			title := {WINDOW_TITLE}.sanitized (a_title)
			is_title_stale := True
		ensure
			title_set: attached title as t and then t.same_string ({WINDOW_TITLE}.sanitized (a_title))
			stale: is_title_stale
		end

	show_title
			-- Show `title`, if any: save the terminal's own title first (XTWINOPS 22) unless it
			-- is saved already, then write `title`. Part of setting the terminal up, once the
			-- process owns it (TUI_APPLICATION calls it after every setup, a resume included):
			-- a stop gives the terminal's title back, and only output written then reaches it,
			-- so the saved-title record (`backend.is_title_pushed`) matches the terminal.
		do
			if attached title as l_title then
				if not backend.is_title_pushed then
					backend.push_title
				end
				backend.set_title (l_title)
				is_title_shown := True
				is_title_stale := False
			end
		ensure
			shown_with_title: attached title implies (is_title_shown and not is_title_stale and backend.is_title_pushed)
		end

	restore_title
			-- Give the terminal back the title `show_title` saved (XTWINOPS 23), if it saved
			-- one, and stop showing `title` (kept for the next `show_title`). Part of restoring
			-- the terminal: crossterm leaves this to the application. Terminals without a
			-- title stack keep the last title written.
		do
			if backend.is_title_pushed then
				backend.pop_title
			end
			is_title_shown := False
		ensure
			popped: not backend.is_title_pushed
			not_shown: not is_title_shown
		end

feature -- Clipboard (OSC 52)

	-- Write: the text goes to the terminal, which puts it on the system clipboard
	-- (crossterm `CopyToClipboard`, feature `osc52`).
	--
	-- Read: `request_clipboard` / `request_selection` send the OSC 52 query (`?` as the
	-- data). The answer is input, a CLIPBOARD_EVENT from the parser, and most terminals
	-- never send one (they refuse the read, or ask the user). crossterm has no read.
	-- Applications use {TUI_APPLICATION}.read_clipboard, which keeps one request pending
	-- and always answers, with "unavailable" after a timeout; its note lists what to
	-- expect per terminal.
	--
	-- Timing: a copy goes through the backend's buffered output, so it reaches the
	-- terminal with the next frame (`draw`'s flush). A copy made while the application is
	-- being stopped mid-frame (the M11 window of TUI_APPLICATION's suspend) is dropped with
	-- that frame. A read request is held here (`pending_clipboard_requests`) and written
	-- by the next `draw`, so a stop or the end of `run` before that frame can take it
	-- back (`discard_clipboard_requests`): it never reaches a terminal that has been
	-- handed back to the shell. Nothing else is to undo: neither leaves terminal state,
	-- so they have no part in `restore_terminal`, the signal handlers' reset or the resume.
	--
	-- tmux and GNU screen pass OSC 52 on only when told to (tmux: `set -g set-clipboard on`).
	-- The library does not wrap the sequence in their passthrough (`ESC P tmux; ...`).

	set_clipboard_limit (a_limit: INTEGER)
			-- Send OSC 52 payloads of at most `a_limit` base64 characters.
		require
			room_for_one_group: a_limit >= 4
		do
			clipboard_limit := a_limit
		ensure
			limit_set: clipboard_limit = a_limit
		end

	clipboard_payload_length (a_text: READABLE_STRING_GENERAL): INTEGER
			-- Base64 characters `copy_to_clipboard (a_text)` would send: `a_text` as UTF-8,
			-- then base64 (4 characters per 3 bytes or part of 3).
		require
			text_attached: a_text /= Void
		do
			Result := {BASE64}.encoded_length ({BASE64}.utf_8_count (a_text))
		ensure
			four_per_group: Result \\ 4 = 0
		end

	fits_in_clipboard (a_text: READABLE_STRING_GENERAL): BOOLEAN
			-- Is the payload of `a_text` within `clipboard_limit`?
		require
			text_attached: a_text /= Void
		do
			Result := clipboard_payload_length (a_text) <= clipboard_limit
		ensure
			definition: Result = (clipboard_payload_length (a_text) <= clipboard_limit)
		end

	clipboard_prefix (a_text: READABLE_STRING_GENERAL): STRING_32
			-- Longest start of `a_text` that fits in the clipboard and does not cut a grapheme
			-- cluster: `a_text` itself when it fits. For an application that would rather
			-- copy part of a long text than nothing.
		require
			text_attached: a_text /= Void
		local
			i, l_end, l_bytes, l_max_bytes: INTEGER
			l_full: BOOLEAN
		do
				-- Base64 of n bytes fits when 4 * ceiling (n / 3) <= limit, that is n <= limit // 4 * 3
			l_max_bytes := clipboard_limit // 4 * 3
			from
				i := 1
			until
				l_full or i > a_text.count
			loop
				l_end := {UNICODE_WIDTH}.grapheme_end (a_text, i)
				l_bytes := l_bytes + {UTF_CONVERTER}.utf_8_bytes_count (a_text, i, l_end)
				if l_bytes > l_max_bytes then
					l_full := True
				else
					i := l_end + 1
				end
			end
			Result := a_text.substring (1, i - 1).to_string_32
		ensure
			fits: fits_in_clipboard (Result)
			prefix_of_text: a_text.to_string_32.starts_with (Result)
			whole_when_it_fits: fits_in_clipboard (a_text) implies Result.same_string_general (a_text)
		end

	copy_to_clipboard (a_text: READABLE_STRING_GENERAL)
			-- Ask the terminal to put `a_text` on the system clipboard (OSC 52, target `c`):
			-- `ESC ] 52 ; c ; base64 ESC \`, the base64 of `a_text` as UTF-8. Sent with the
			-- next frame; see the notes of this feature clause for timing and tmux.
			-- `a_text` is not empty: an empty payload is not a copy of nothing, xterm clears
			-- the clipboard on it (so does an empty `clipboard_prefix`, when not even the
			-- first grapheme cluster fits).
		require
			text_attached: a_text /= Void
			not_empty: not a_text.is_empty
			fits: fits_in_clipboard (a_text)
		do
			backend.set_clipboard ({TERMINAL_BACKEND}.Clipboard_selection, a_text)
		end

	copy_to_selection (a_text: READABLE_STRING_GENERAL)
			-- Ask the terminal to put `a_text` in the primary selection (OSC 52, target `p`;
			-- X11 terminals, others ignore it), as `copy_to_clipboard` does the clipboard.
		require
			text_attached: a_text /= Void
			not_empty: not a_text.is_empty
			fits: fits_in_clipboard (a_text)
		do
			backend.set_clipboard ({TERMINAL_BACKEND}.Primary_selection, a_text)
		end

	pending_clipboard_requests: STRING_8
			-- Selections (`c`, `p`) of the read requests the next `draw` writes, in order;
			-- empty when there are none (a copy)
		do
			Result := clipboard_requests.twin
		end

	has_clipboard_request: BOOLEAN
			-- Will the next `draw` write a read request?
		do
			Result := not clipboard_requests.is_empty
		ensure
			definition: Result = not pending_clipboard_requests.is_empty
		end

	request_clipboard
			-- Ask the terminal for the clipboard's contents (OSC 52 query, target `c`):
			-- `ESC ] 52 ; c ; ? ESC \`, written by the next `draw`. The answer, if the
			-- terminal sends one, is a CLIPBOARD_EVENT read as input. See the notes of this
			-- feature clause; applications use {TUI_APPLICATION}.read_clipboard.
		do
			clipboard_requests.extend ({TERMINAL_BACKEND}.Clipboard_selection)
		ensure
			queued: pending_clipboard_requests.count = old pending_clipboard_requests.count + 1
			last_is_clipboard: pending_clipboard_requests.item (pending_clipboard_requests.count) = {TERMINAL_BACKEND}.Clipboard_selection
		end

	request_selection
			-- Ask the terminal for the primary selection's contents (OSC 52 query, target
			-- `p`; X11 terminals), as `request_clipboard` does for the clipboard.
		do
			clipboard_requests.extend ({TERMINAL_BACKEND}.Primary_selection)
		ensure
			queued: pending_clipboard_requests.count = old pending_clipboard_requests.count + 1
			last_is_selection: pending_clipboard_requests.item (pending_clipboard_requests.count) = {TERMINAL_BACKEND}.Primary_selection
		end

	discard_clipboard_requests
			-- Take back the read requests not written yet (`pending_clipboard_requests`).
		do
			clipboard_requests.wipe_out
		ensure
			none: not has_clipboard_request
		end

	clear_screen
			-- Clear terminal screen.
		do
			backend.clear_screen
			forget_shown_frame
		ensure
			nothing_shown: shown_area = Void
		end

	force_full_redraw
			-- Make the next `draw` rewrite every cell (e.g. after suspend/resume).
		do
			create previous_buffer.make (width, height)
			diff_engine.discard_pool
			forget_shown_frame
		ensure
			nothing_shown: shown_area = Void
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
			forget_shown_frame
		ensure
			width_set: width = a_area.width.to_integer_32
			height_set: height = a_area.height.to_integer_32
			nothing_shown: shown_area = Void
		end

	enable_mouse_capture
			-- Enable mouse event capture.
		do
			backend.enable_mouse_capture
		end

	disable_mouse_capture
			-- Disable mouse event capture, motion reporting included.
		do
			backend.disable_mouse_capture
		end

	enable_mouse_motion
			-- Report motion with no button held too (mode 1003; see
			-- {TERMINAL_BACKEND}.enable_mouse_motion).
		require
			mouse_captured: backend.is_mouse_captured
		do
			backend.enable_mouse_motion
		ensure
			motion_enabled: backend.is_mouse_motion_enabled
		end

	disable_mouse_motion
			-- Stop reporting motion with no button held.
		do
			backend.disable_mouse_motion
		ensure
			motion_off: not backend.is_mouse_motion_enabled
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

	is_cursor_shape_stale (a_shape: CURSOR_SHAPE): BOOLEAN
			-- Must `draw` write `a_shape` for the terminal to show it? Yes when it is not the
			-- shape last written, or when the terminal may have been reset to the default
			-- since (`is_cursor_shape_uncertain`) and `a_shape` is not the default.
		do
			Result := a_shape /~ backend.cursor_shape or (is_cursor_shape_uncertain and not a_shape.is_default)
		end

	draw_block (a_draw: PROCEDURE [BUFFER]; a_block: BUFFER; a_first: INTEGER)
			-- Draw `a_block` with `a_draw` (for `insert_before`, which does not pass `a_first`).
		do
			a_draw.call ([a_block])
		end

	insert_block (a_lines: BUFFER; a_room: INTEGER)
			-- Write all rows of `a_lines` above the inline viewport, `a_room` being the rows above
			-- the viewport once it sits at the bottom of the screen: move the viewport down while
			-- there is room below it, then scroll.
		local
			l_chunk, l_top, l_free_below, r: INTEGER
		do
			from
				r := 0
			until
				r >= a_lines.height
			loop
				if a_room <= 0 then
					-- The viewport fills the screen: write the row on top, then scroll it away
					write_rows (a_lines, r, 1, 0)
					backend.scroll_up (1)
					l_chunk := 1
				else
					l_chunk := (a_lines.height - r).min (a_room)
					l_top := viewport_origin_row
					l_free_below := backend.height - (l_top + height)
					if l_free_below < l_chunk then
						backend.scroll_up (l_chunk - l_free_below)
						l_top := l_top - (l_chunk - l_free_below)
					end
					write_rows (a_lines, r, l_chunk, l_top)
					viewport.set_origin (l_top + l_chunk, viewport.origin_column)
				end
				r := r + l_chunk
			end
		end

	clipboard_requests: STRING_8
			-- Selections of the read requests not written yet (see `pending_clipboard_requests`)
		do
			if attached internal_clipboard_requests as l_clipboard_requests then
				Result := l_clipboard_requests
			else
				create Result.make (2)
				internal_clipboard_requests := Result
			end
		end

	internal_clipboard_requests: detachable STRING_8
			-- Storage of `clipboard_requests`, created on first use (rather than a self-initializing
			-- attribute, which is not initialized when the library is compiled without void safety)

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
				Result := backend.width.max (1).min ({BUFFER}.Max_extent)
			end
		ensure
			positive: Result > 0
			in_buffer_range: Result <= {BUFFER}.Max_extent
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
				Result := backend.height.max (1).min ({BUFFER}.Max_extent)
			end
		ensure
			positive: Result > 0
			in_buffer_range: Result <= {BUFFER}.Max_extent
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
	valid_insert_block_limit: insert_block_limit > 0 and insert_block_limit <= {BUFFER}.Max_extent
	valid_clipboard_limit: clipboard_limit >= 4
	valid_clipboard_requests: across clipboard_requests as r all backend.is_valid_selection (r) end
	backend_not_void: backend /= Void
	current_buffer_not_void: current_buffer /= Void
	previous_buffer_not_void: previous_buffer /= Void

end
