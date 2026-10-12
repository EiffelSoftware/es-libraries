note
	description: "[
		Terminal backend outputting ANSI escape sequences to standard output.
		Uses CONSOLE_DRIVER to interface with host OS console settings.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	ANSI_TERMINAL_BACKEND

inherit
	TERMINAL_BACKEND
		redefine
			put_frame
		end

create
	make,
	make_with_driver,
	make_with_driver_and_sink

feature {NONE} -- Initialization

	make
			-- Initialize ANSI terminal backend with default platform driver.
		do
			make_with_driver (create {TERMINAL_DRIVER})
		end

	make_with_driver (a_driver: CONSOLE_DRIVER)
			-- Initialize ANSI terminal backend with specific `a_driver`.
		require
			driver_attached: a_driver /= Void
		do
			driver := a_driver
			driver.enable_vt_mode.do_nothing
			driver.install_ctrl_handler
			width := driver.console_width
			height := driver.console_height
			cursor_row := 0
			cursor_column := 0
			is_raw := False
			is_alternate_screen := False
			is_cursor_visible := True
			is_mouse_captured := False
			is_bracketed_paste_enabled := False
			is_focus_change_enabled := False
		ensure
			driver_set: driver = a_driver
			console_output: output_sink = Void
		end

	make_with_driver_and_sink (a_driver: CONSOLE_DRIVER; a_sink: STRING_32)
			-- Initialize with `a_driver`, appending all output to `a_sink` instead of stdout.
			-- Intended for tests that need the exact escape sequences the backend emits.
		require
			driver_attached: a_driver /= Void
			sink_attached: a_sink /= Void
		do
			make_with_driver (a_driver)
			output_sink := a_sink
		ensure
			driver_set: driver = a_driver
			sink_set: output_sink = a_sink
		end

feature -- Access

	output_sink: detachable STRING_32
			-- Capture buffer receiving all output, or Void to write to stdout

	width: INTEGER
			-- Width of console in columns

	height: INTEGER
			-- Height of console in rows

	cursor_row: INTEGER
			-- Current 0-based cursor row

	cursor_column: INTEGER
			-- Current 0-based cursor column

	is_input_in_use: BOOLEAN
			-- Is a reader reading the console's input (see {CONSOLE_DRIVER}.input_claim)?
		do
			Result := driver.is_input_claimed
		end

	is_raw: BOOLEAN
			-- Is raw mode active?

	is_alternate_screen: BOOLEAN
			-- Is alternate screen buffer active?

	is_cursor_visible: BOOLEAN
			-- Is cursor visible?

	is_mouse_captured: BOOLEAN
			-- Is mouse reporting active?

	is_bracketed_paste_enabled: BOOLEAN
			-- Is bracketed paste mode active?

	is_focus_change_enabled: BOOLEAN
			-- Is focus reporting active?

	is_keyboard_enhancement_enabled: BOOLEAN
			-- Is extended keyboard reporting active?

feature -- Status setting

	refresh_size
			-- Update cached width and height from console driver.
		do
			width := driver.console_width
			height := driver.console_height
			if cursor_row >= height and height > 0 then
				cursor_row := height - 1
			end
			if cursor_column >= width and width > 0 then
				cursor_column := width - 1
			end
		end

feature -- Basic operations

	clear_screen
			-- Clear entire screen contents and move cursor to (0, 0).
		do
			write (Csi + "2J" + Csi + "H")
			cursor_row := 0
			cursor_column := 0
		end

	move_cursor (a_row, a_column: INTEGER)
			-- Move cursor to 0-based (`a_row`, `a_column`).
		do
			write (Csi + (a_row + 1).out + ";" + (a_column + 1).out + "H")
			cursor_row := a_row
			cursor_column := a_column
		end

	put_string (a_string: READABLE_STRING_GENERAL)
			-- Write `a_string` at current cursor position and update cursor tracking.
		do
			write (a_string)
			advance_cursor_tracking (a_string)
		end

	put_frame (a_frame: READABLE_STRING_8; a_cursor: detachable TUPLE [row, column: INTEGER])
			-- Write `a_frame` and take the cursor position from `a_cursor`, without decoding and
			-- scanning the frame (review finding M2: `put_string` does both for every frame).
		do
			write (a_frame)
			if attached a_cursor as c then
				if height > 0 then
					cursor_row := c.row.min (height - 1)
				end
				if width > 0 then
					cursor_column := c.column.min (width - 1)
				end
			end
		ensure then
			row_tracked: (attached a_cursor as c and height > 0) implies cursor_row = c.row.min (height - 1)
			column_tracked: (attached a_cursor as c and width > 0) implies cursor_column = c.column.min (width - 1)
			unchanged_without_cursor: a_cursor = Void implies (cursor_row = old cursor_row and cursor_column = old cursor_column)
		end

	flush
			-- Flush pending console output.
		do
			if output_sink = Void then
				io.output.flush
			end
		end

	clear_line (a_row: INTEGER)
			-- Blank screen row `a_row` (EL 2) and leave the cursor at its start.
		do
			move_cursor (a_row, 0)
			write (Csi + "2K")
		end

	scroll_up (a_lines: INTEGER)
			-- Scroll the screen up by `a_lines` rows by emitting line feeds on the last row,
			-- so that the scrolled-off rows enter the terminal's scrollback history.
		local
			i: INTEGER
		do
			if height > 0 then
				move_cursor (height - 1, 0)
				from
					i := 1
				until
					i > a_lines
				loop
					write ("%N")
					i := i + 1
				end
				cursor_row := height - 1
				cursor_column := 0
			end
		end

	query_cursor_position: detachable TUPLE [row, column: INTEGER]
			-- Send DSR `ESC [ 6 n` and wait (up to `Cursor_report_attempts` x
			-- `Cursor_report_poll_ms`) for the `ESC [ row ; col R` answer.
			-- Input other than the report that arrives meanwhile is discarded.
			-- Holds the driver's `input_claim` while it reads, so no other reader can start;
			-- Void, without sending the query, if another reader took it first.
		local
			l_parser: ANSI_INPUT_PARSER
			l_code, l_misses: INTEGER
			l_claimed: BOOLEAN
		do
			if driver.input_claim.try_acquire then
				l_claimed := True
				write (Csi + "6n")
				flush
				create l_parser.make
				from
				until
					Result /= Void or l_misses >= Cursor_report_attempts
				loop
					l_code := driver.read_char_with_timeout (Cursor_report_poll_ms)
					if l_code < 0 then
						l_misses := l_misses + 1
					else
						l_parser.parse_code (l_code.to_natural_32)
						across l_parser.events as e loop
							if attached {CURSOR_POSITION_EVENT} e as l_report then
								Result := [l_report.row.to_integer_32, l_report.column.to_integer_32]
							end
						end
						l_parser.wipe_out
					end
				end
				l_claimed := False
				driver.input_claim.release
				if attached Result as r then
					if height > 0 then
						cursor_row := r.row.min (height - 1)
					end
					if width > 0 then
						cursor_column := r.column.min (width - 1)
					end
				end
			end
		rescue
			if l_claimed then
				l_claimed := False
				driver.input_claim.release
			end
		end

feature -- Mode settings

	enter_raw_mode
			-- Put terminal into raw mode.
		local
			l_failure: DEVELOPER_EXCEPTION
		do
			if driver.enable_raw_mode then
				is_raw := True
			else
				create l_failure
				l_failure.set_description ("Unable to switch the console to raw input mode")
				l_failure.raise
			end
		end

	leave_raw_mode
			-- Disable the reporting modes, flush them, then restore the original console modes.
			-- Escape sequences must be written before the driver restores the modes, because
			-- restoring may turn virtual terminal processing off again.
		local
			l_res: BOOLEAN
		do
			if is_mouse_captured then
				disable_mouse_capture
			end
			if is_bracketed_paste_enabled then
				disable_bracketed_paste
			end
			if is_focus_change_enabled then
				disable_focus_change
			end
			if is_keyboard_enhancement_enabled then
				disable_keyboard_enhancement
			end
			flush
			l_res := driver.disable_raw_mode
			driver.restore_modes
			is_raw := False
		end

	enter_alternate_screen
			-- Switch to alternate screen buffer.
		do
			write (Csi + "?1049h")
			is_alternate_screen := True
		end

	leave_alternate_screen
			-- Restore primary screen buffer.
		do
			write (Csi + "?1049l")
			is_alternate_screen := False
		end

	hide_cursor
			-- Make cursor invisible.
		do
			write (Csi + "?25l")
			is_cursor_visible := False
		end

	show_cursor
			-- Make cursor visible.
		do
			write (Csi + "?25h")
			is_cursor_visible := True
		end

	enable_mouse_capture
			-- Enable mouse tracking (normal + drag + SGR format).
		local
			l_res: BOOLEAN
		do
			l_res := driver.enable_mouse
			write (Csi + "?1000h" + Csi + "?1002h" + Csi + "?1006h")
			is_mouse_captured := True
		end

	disable_mouse_capture
			-- Disable mouse tracking and restore driver state.
		local
			l_res: BOOLEAN
		do
			write (Csi + "?1006l" + Csi + "?1002l" + Csi + "?1000l")
			l_res := driver.disable_mouse
			is_mouse_captured := False
		end

	enable_bracketed_paste
			-- Enable bracketed paste reporting.
		do
			write (Csi + "?2004h")
			is_bracketed_paste_enabled := True
		end

	disable_bracketed_paste
			-- Disable bracketed paste reporting.
		do
			write (Csi + "?2004l")
			is_bracketed_paste_enabled := False
		end

	enable_focus_change
			-- Enable focus gained/lost reporting.
		do
			write (Csi + "?1004h")
			is_focus_change_enabled := True
		end

	disable_focus_change
			-- Disable focus reporting.
		do
			write (Csi + "?1004l")
			is_focus_change_enabled := False
		end

	enable_keyboard_enhancement
			-- Enable extended keyboard reporting (progressive enhancement / key release & repeat).
		do
			driver.enable_keyboard_enhancement
			write (Csi + ">3u")
			is_keyboard_enhancement_enabled := True
		end

	disable_keyboard_enhancement
			-- Disable extended keyboard reporting.
		do
			write (Csi + "<u")
			driver.disable_keyboard_enhancement
			is_keyboard_enhancement_enabled := False
		end

feature -- Driver Access

	driver: CONSOLE_DRIVER
			-- OS console platform driver

feature {NONE} -- Output

	write (a_text: READABLE_STRING_GENERAL)
			-- Send `a_text` to `output_sink` if set, otherwise to standard output.
		do
			if attached output_sink as l_sink then
				l_sink.append_string_general (a_text)
			else
				print (a_text)
			end
		end

feature {NONE} -- Cursor tracking

	advance_cursor_tracking (a_string: READABLE_STRING_GENERAL)
			-- Move the tracked cursor the way the terminal will when it prints `a_string`:
			-- by display width for text (UTF-8 byte strings are decoded first), to the start of the
			-- line for CR/LF, to the requested cell for `CSI row;col H`; other escapes do not move it.
		local
			i: INTEGER
			l_text: READABLE_STRING_GENERAL
			l_code: NATURAL_32
			l_scanner: like output_scanner
		do
			if attached {READABLE_STRING_8} a_string as l_bytes then
				l_text := {UTF_CONVERTER}.utf_8_string_8_to_string_32 (l_bytes)
			else
				l_text := a_string
			end
			l_scanner := output_scanner
			from
				i := 1
			until
				i > l_text.count
			loop
				l_code := l_text.code (i)
				l_scanner.feed (l_code)
				if l_scanner.last_kind = l_scanner.Kind_cursor_position then
					if height > 0 then
						cursor_row := l_scanner.last_row.min (height - 1)
					end
					if width > 0 then
						cursor_column := l_scanner.last_column.min (width - 1)
					end
				elseif l_scanner.last_kind = l_scanner.Kind_text then
					if l_code = 10 then
						cursor_column := 0
						if cursor_row + 1 < height then
							cursor_row := cursor_row + 1
						end
					elseif l_code = 13 then
						cursor_column := 0
					elseif width > 0 then
						cursor_column := (cursor_column + {UNICODE_WIDTH}.width (l_code).to_integer_32).min (width - 1)
					end
				end
				i := i + 1
			end
		end

	output_scanner: ANSI_TEXT_SCANNER
			-- Escape sequence scanner used by cursor tracking (state persists across writes)
		attribute
			create Result.make
		end

feature {NONE} -- Constants

	Csi: STRING_8 = "%/27/["
			-- Control Sequence Introducer

	Cursor_report_attempts: INTEGER = 10
			-- Number of silent polls before giving up on a cursor position report

	Cursor_report_poll_ms: INTEGER = 25
			-- Poll timeout while waiting for a cursor position report

end
