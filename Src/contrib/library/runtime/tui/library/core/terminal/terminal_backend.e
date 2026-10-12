note
	description: "[
		Deferred base class representing a terminal output surface.
		Coordinates are 0-based: row in 0..height-1, column in 0..width-1.
		Design by Contract ensures all bounds and attachment constraints.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	TERMINAL_BACKEND

feature -- Access

	width: INTEGER
			-- Width of terminal screen in columns
		deferred
		ensure
			non_negative: Result >= 0
		end

	height: INTEGER
			-- Height of terminal screen in rows
		deferred
		ensure
			non_negative: Result >= 0
		end

	cursor_row: INTEGER
			-- Current 0-based cursor row position
		deferred
		ensure
			non_negative: Result >= 0
			within_height: height = 0 or Result < height
		end

	cursor_column: INTEGER
			-- Current 0-based cursor column position
		deferred
		ensure
			non_negative: Result >= 0
			within_width: width = 0 or Result < width
		end

feature -- Status report

	is_input_in_use: BOOLEAN
			-- Is a reader (such as a running EVENT_THREAD) reading the terminal's input?
			-- While it is, `query_cursor_position` must not be called: its answer would go
			-- to that reader.
		deferred
		end

	is_raw: BOOLEAN
			-- Is the terminal in raw input mode?
		deferred
		end

	is_alternate_screen: BOOLEAN
			-- Is the terminal displaying the alternate screen buffer?
		deferred
		end

	is_cursor_visible: BOOLEAN
			-- Is the terminal cursor visible?
		deferred
		end

	is_mouse_captured: BOOLEAN
			-- Is mouse event reporting currently active?
		deferred
		end

	is_bracketed_paste_enabled: BOOLEAN
			-- Is bracketed paste mode active?
		deferred
		end

	is_focus_change_enabled: BOOLEAN
			-- Is focus reporting active?
		deferred
		end

	is_keyboard_enhancement_enabled: BOOLEAN
			-- Is extended keyboard reporting (progressive enhancement / key release & repeat) active?
		deferred
		end

feature -- Status setting

	refresh_size
			-- Refresh cached dimensions from underlying display device.
		deferred
		end

feature -- Basic operations

	clear_screen
			-- Clear entire screen contents and reset cursor to (0, 0).
		deferred
		ensure
			cursor_at_origin: cursor_row = 0 and cursor_column = 0
		end

	move_cursor (a_row, a_column: INTEGER)
			-- Move cursor to 0-based (`a_row`, `a_column`).
		require
			valid_row: a_row >= 0 and (height = 0 or a_row < height)
			valid_column: a_column >= 0 and (width = 0 or a_column < width)
		deferred
		ensure
			cursor_row_set: cursor_row = a_row
			cursor_column_set: cursor_column = a_column
		end

	put_string (a_string: READABLE_STRING_GENERAL)
			-- Write `a_string` at current cursor position.
		deferred
		end

	put_frame (a_frame: READABLE_STRING_8; a_cursor: detachable TUPLE [row, column: INTEGER])
			-- Write `a_frame`: escape sequences and UTF-8 text laid out by its producer (such as
			-- ANSI_SERIALIZER), after which the cursor is at `a_cursor` (Void: where it was).
			-- `a_frame` may be reused by the caller afterwards: do not keep it.
			-- By default the frame is written like any string; a backend that tracks the cursor
			-- by scanning its output can take `a_cursor` instead of scanning the frame again.
		require
			valid_cursor: attached a_cursor as c implies (c.row >= 0 and c.column >= 0)
		do
			put_string (a_frame)
		end

	flush
			-- Flush pending output buffer to physical or virtual terminal.
		deferred
		end

	clear_line (a_row: INTEGER)
			-- Blank the whole of screen row `a_row` and leave the cursor at its start.
		require
			valid_row: a_row >= 0 and (height = 0 or a_row < height)
		deferred
		ensure
			cursor_at_line_start: cursor_row = a_row and cursor_column = 0
		end

	scroll_up (a_lines: INTEGER)
			-- Scroll the whole screen up by `a_lines` rows, pushing the top rows into the
			-- scrollback history and leaving blank rows at the bottom.
		require
			positive_lines: a_lines > 0
		deferred
		ensure
			cursor_on_last_row: height = 0 or (cursor_row = height - 1 and cursor_column = 0)
		end

	query_cursor_position: detachable TUPLE [row, column: INTEGER]
			-- Ask the terminal for the 0-based hardware cursor position (DSR `ESC [ 6 n`).
			-- Void when the terminal does not answer.
		require
			input_not_in_use: not is_input_in_use
		deferred
		ensure
			non_negative: attached Result as r implies (r.row >= 0 and r.column >= 0)
		end

feature -- Mode settings

	enter_raw_mode
			-- Put terminal into raw mode.
		deferred
		ensure
			raw_mode_enabled: is_raw
		end

	leave_raw_mode
			-- Restore terminal from raw mode to normal cooked mode.
		deferred
		ensure
			raw_mode_disabled: not is_raw
		end

	enter_alternate_screen
			-- Switch to alternate screen buffer.
		deferred
		ensure
			alternate_screen_active: is_alternate_screen
		end

	leave_alternate_screen
			-- Restore primary screen buffer.
		deferred
		ensure
			alternate_screen_inactive: not is_alternate_screen
		end

	hide_cursor
			-- Make terminal cursor invisible.
		deferred
		ensure
			cursor_hidden: not is_cursor_visible
		end

	show_cursor
			-- Make terminal cursor visible.
		deferred
		ensure
			cursor_visible: is_cursor_visible
		end

	enable_mouse_capture
			-- Enable mouse tracking mode.
		deferred
		ensure
			mouse_captured: is_mouse_captured
		end

	disable_mouse_capture
			-- Disable mouse tracking mode.
		deferred
		ensure
			mouse_released: not is_mouse_captured
		end

	enable_bracketed_paste
			-- Enable bracketed paste reporting.
		deferred
		ensure
			bracketed_paste_enabled: is_bracketed_paste_enabled
		end

	disable_bracketed_paste
			-- Disable bracketed paste reporting.
		deferred
		ensure
			bracketed_paste_disabled: not is_bracketed_paste_enabled
		end

	enable_focus_change
			-- Enable focus reporting events.
		deferred
		ensure
			focus_change_enabled: is_focus_change_enabled
		end

	disable_focus_change
			-- Disable focus reporting events.
		deferred
		ensure
			focus_change_disabled: not is_focus_change_enabled
		end

	enable_keyboard_enhancement
			-- Enable extended keyboard reporting (progressive enhancement / key release & repeat).
		deferred
		ensure
			keyboard_enhancement_enabled: is_keyboard_enhancement_enabled
		end

	disable_keyboard_enhancement
			-- Disable extended keyboard reporting.
		deferred
		ensure
			keyboard_enhancement_disabled: not is_keyboard_enhancement_enabled
		end

invariant
	valid_dimensions: width >= 0 and height >= 0
	cursor_row_valid: cursor_row >= 0 and (height = 0 or cursor_row < height)
	cursor_column_valid: cursor_column >= 0 and (width = 0 or cursor_column < width)

end
