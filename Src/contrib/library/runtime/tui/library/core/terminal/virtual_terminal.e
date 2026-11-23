note
	description: "[
		In-memory virtual terminal implementation for headless unit testing.
		Stores a 2D grid of characters and logs all terminal operations.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	VIRTUAL_TERMINAL

inherit
	TERMINAL_BACKEND

create
	make,
	make_default

feature {NONE} -- Initialization

	make (a_width, a_height: INTEGER)
			-- Initialize virtual terminal with given dimensions.
		require
			positive_width: a_width > 0
			positive_height: a_height > 0
		do
			width := a_width
			height := a_height
			cursor_row := 0
			cursor_column := 0
			is_raw := False
			is_alternate_screen := False
			is_cursor_visible := True
			cursor_shape := {CURSOR_SHAPE}.Default_user
			create operations.make (20)
			operations.compare_objects
			create grid.make_filled (' ', height, width)
		ensure
			width_set: width = a_width
			height_set: height = a_height
			cursor_at_origin: cursor_row = 0 and cursor_column = 0
		end

	make_default
			-- Initialize with standard 80x24 dimensions.
		do
			make (80, 24)
		ensure
			default_width: width = 80
			default_height: height = 24
		end

feature -- Access

	width: INTEGER
			-- Width of virtual screen in columns

	height: INTEGER
			-- Height of virtual screen in rows

	cursor_row: INTEGER
			-- Current 0-based cursor row

	cursor_column: INTEGER
			-- Current 0-based cursor column

	is_input_in_use: BOOLEAN
			-- Is a reader reading the terminal's input? Never: a virtual terminal has no
			-- input, and `query_cursor_position` answers from the simulated cursor.
		do
		end

	is_raw: BOOLEAN
			-- Is raw mode active?

	is_alternate_screen: BOOLEAN
			-- Is alternate screen buffer active?

	is_cursor_visible: BOOLEAN
			-- Is cursor visible?

	cursor_shape: CURSOR_SHAPE
			-- Cursor shape last set by `set_cursor_shape`

	title: detachable STRING_32
			-- Window title last set by `set_title`, Void before the first

	is_title_pushed: BOOLEAN
			-- Did `push_title` run without `pop_title` since?

	clipboard_text: detachable STRING_32
			-- Text last sent to the clipboard by `set_clipboard`, Void before the first

	primary_selection_text: detachable STRING_32
			-- Text last sent to the primary selection by `set_clipboard`, Void before the first

	operations: ARRAYED_LIST [STRING_32]
			-- Log of executed terminal commands for testing assertions

	cell (a_row, a_column: INTEGER): CHARACTER_32
			-- Character at 0-based (`a_row`, `a_column`)
		require
			valid_row: a_row >= 0 and a_row < height
			valid_column: a_column >= 0 and a_column < width
		do
			Result := grid.item (a_row + 1, a_column + 1)
		end

	line (a_row: INTEGER): STRING_32
			-- Full line at 0-based `a_row` as a string
		require
			valid_row: a_row >= 0 and a_row < height
		local
			c: INTEGER
		do
			create Result.make (width)
			from
				c := 0
			until
				c >= width
			loop
				Result.append_character (cell (a_row, c))
				c := c + 1
			end
		ensure
			length_matches_width: Result.count = width
		end

	rendered_text: STRING_32
			-- Entire screen rendered as a multiline string
		local
			r: INTEGER
		do
			create Result.make (height * (width + 1))
			from
				r := 0
			until
				r >= height
			loop
				Result.append (line (r))
				if r < height - 1 then
					Result.append_character ('%N')
				end
				r := r + 1
			end
		end

feature -- Basic operations

	clear_screen
			-- Clear entire screen grid with spaces and reset cursor to (0, 0).
		local
			r, c: INTEGER
		do
			operations.extend ("clear_screen")
			from
				r := 1
			until
				r > height
			loop
				from
					c := 1
				until
					c > width
				loop
					grid.put (' ', r, c)
					c := c + 1
				end
				r := r + 1
			end
			cursor_row := 0
			cursor_column := 0
		end

	move_cursor (a_row, a_column: INTEGER)
			-- Move cursor to 0-based (`a_row`, `a_column`).
		do
			operations.extend ("move_cursor(" + a_row.out + ", " + a_column.out + ")")
			cursor_row := a_row
			cursor_column := a_column
		end

	put_string (a_string: READABLE_STRING_GENERAL)
			-- Write `a_string` into grid starting at current cursor position.
			-- UTF-8 byte strings are decoded; escape sequences are skipped, except cursor
			-- positioning (`CSI row;col H`), which moves the cursor.
		local
			i: INTEGER
			ch: CHARACTER_32
			l_w: NATURAL_8
			l_str: READABLE_STRING_GENERAL
			l_scanner: like output_scanner
		do
			if attached {READABLE_STRING_8} a_string as s8 then
				l_str := {UTF_CONVERTER}.utf_8_string_8_to_string_32 (s8)
			else
				l_str := a_string
			end
			operations.extend ({STRING_32} "put_string(" + l_str.to_string_32 + {STRING_32} ")")
			l_scanner := output_scanner
			from
				i := 1
			until
				i > l_str.count
			loop
				ch := l_str.code (i).to_character_32
				l_scanner.feed (ch.natural_32_code)
				if l_scanner.last_kind = l_scanner.Kind_cursor_position then
					cursor_row := l_scanner.last_row.min (height - 1).max (0)
					cursor_column := l_scanner.last_column.min (width - 1).max (0)
				elseif l_scanner.last_kind /= l_scanner.Kind_text then
					-- Inside an escape sequence
				elseif ch = '%N' then
					cursor_column := 0
					if cursor_row + 1 < height then
						cursor_row := cursor_row + 1
					end
				elseif ch = '%R' then
					cursor_column := 0
				else
					l_w := {UNICODE_WIDTH}.width (ch.natural_32_code)
					if cursor_row < height and cursor_column < width then
						if l_w = 2 then
							grid.put (ch, cursor_row + 1, cursor_column + 1)
							if cursor_column + 1 < width then
								grid.put (' ', cursor_row + 1, cursor_column + 2)
								cursor_column := cursor_column + 2
							else
								cursor_column := width - 1
							end
						elseif l_w = 1 then
							grid.put (ch, cursor_row + 1, cursor_column + 1)
							cursor_column := cursor_column + 1
						end
						if cursor_column >= width then
							cursor_column := width - 1
						end
					end
				end
				i := i + 1
			end
		end

	flush
			-- Record flush operation.
		do
			operations.extend ("flush")
		end

	clear_line (a_row: INTEGER)
			-- Blank row `a_row` and move the cursor to its start.
		local
			c: INTEGER
		do
			operations.extend ("clear_line(" + a_row.out + ")")
			from
				c := 1
			until
				c > width
			loop
				grid.put (' ', a_row + 1, c)
				c := c + 1
			end
			cursor_row := a_row
			cursor_column := 0
		end

	set_clipboard (a_selection: CHARACTER_8; a_text: READABLE_STRING_GENERAL)
			-- Record `a_text` as the content of `a_selection`, logged as "set_clipboard(s,text)".
		do
			operations.extend ({STRING_32} "set_clipboard(" + a_selection.out + "," + a_text.to_string_32 + ")")
			if a_selection = Clipboard_selection then
				clipboard_text := a_text.to_string_32
			else
				primary_selection_text := a_text.to_string_32
			end
		ensure then
			clipboard_set: a_selection = Clipboard_selection implies
				(attached clipboard_text as t and then t.same_string_general (a_text))
			selection_set: a_selection = Primary_selection implies
				(attached primary_selection_text as t and then t.same_string_general (a_text))
		end

	request_clipboard_contents (a_selection: CHARACTER_8)
			-- Log the request as "request_clipboard(s)". A virtual terminal never answers.
		do
			operations.extend ("request_clipboard(" + a_selection.out + ")")
		end

	scroll_up (a_lines: INTEGER)
			-- Shift the grid up by `a_lines` rows; scrolled-off rows are appended to `scrollback`.
		local
			r, c, n: INTEGER
		do
			operations.extend ("scroll_up(" + a_lines.out + ")")
			n := a_lines.min (height)
			from
				r := 0
			until
				r >= n
			loop
				scrollback.extend (line (r))
				r := r + 1
			end
			from
				r := 1
			until
				r > height
			loop
				from
					c := 1
				until
					c > width
				loop
					if r + n <= height then
						grid.put (grid.item (r + n, c), r, c)
					else
						grid.put (' ', r, c)
					end
					c := c + 1
				end
				r := r + 1
			end
			cursor_row := height - 1
			cursor_column := 0
		end

	query_cursor_position: detachable TUPLE [row, column: INTEGER]
			-- Report the simulated cursor position.
		do
			operations.extend ("query_cursor_position")
			Result := [cursor_row, cursor_column]
		end

	scrollback: ARRAYED_LIST [STRING_32]
			-- Rows scrolled off the top of the screen by `scroll_up`, oldest first
		do
			if attached internal_scrollback as l_scrollback then
				Result := l_scrollback
			else
				create Result.make (0)
				internal_scrollback := Result
			end
		end

	internal_scrollback: detachable ARRAYED_LIST [STRING_32]
			-- Storage of `scrollback`, created on first use (rather than a self-initializing
			-- attribute, which is not initialized when the library is compiled without void safety)

	set_size (a_width, a_height: INTEGER)
			-- Simulate the user resizing the terminal to `a_width` x `a_height`.
			-- The screen is blanked and the cursor clamped to the new bounds.
		require
			positive_width: a_width > 0
			positive_height: a_height > 0
		do
			operations.extend ("set_size(" + a_width.out + ", " + a_height.out + ")")
			width := a_width
			height := a_height
			create grid.make_filled (' ', height, width)
			cursor_row := cursor_row.min (height - 1)
			cursor_column := cursor_column.min (width - 1)
		ensure
			width_set: width = a_width
			height_set: height = a_height
		end

feature -- Mode settings

	enter_raw_mode
			-- Enable raw mode.
		do
			operations.extend ("enter_raw_mode")
			is_raw := True
		end

	leave_raw_mode
			-- Disable raw mode.
		do
			operations.extend ("leave_raw_mode")
			is_raw := False
		end

	enter_alternate_screen
			-- Enter alternate screen.
		do
			operations.extend ("enter_alternate_screen")
			is_alternate_screen := True
		end

	leave_alternate_screen
			-- Leave alternate screen.
		do
			operations.extend ("leave_alternate_screen")
			is_alternate_screen := False
		end

	hide_cursor
			-- Hide cursor.
		do
			operations.extend ("hide_cursor")
			is_cursor_visible := False
		end

	show_cursor
			-- Show cursor.
		do
			operations.extend ("show_cursor")
			is_cursor_visible := True
		end

	set_cursor_shape (a_shape: CURSOR_SHAPE)
			-- Record `a_shape`, logged as "set_cursor_shape(n)" with n its code.
		do
			operations.extend ("set_cursor_shape(" + a_shape.code.out + ")")
			cursor_shape := a_shape
		end

	set_title (a_title: READABLE_STRING_GENERAL)
			-- Record `a_title`, logged as "set_title(title)".
		do
			operations.extend ({STRING_32} "set_title(" + a_title.to_string_32 + ")")
			title := a_title.to_string_32
		ensure then
			title_set: attached title as t and then t.same_string_general (a_title)
		end

	push_title
			-- Record the push, logged as "push_title".
		do
			operations.extend ("push_title")
			is_title_pushed := True
		end

	pop_title
			-- Record the pop, logged as "pop_title".
		do
			operations.extend ("pop_title")
			is_title_pushed := False
		end

	refresh_size
			-- Refresh dimensions (no-op in virtual terminal).
		do
			operations.extend ("refresh_size")
		end

	enable_mouse_capture
			-- Enable mouse capture.
		do
			operations.extend ("enable_mouse_capture")
			is_mouse_captured := True
		end

	disable_mouse_capture
			-- Disable mouse capture, motion reporting included.
		do
			operations.extend ("disable_mouse_capture")
			is_mouse_motion_enabled := False
			is_mouse_captured := False
		end

	is_mouse_captured: BOOLEAN

	enable_mouse_motion
			-- Report motion with no button held too.
		do
			operations.extend ("enable_mouse_motion")
			is_mouse_motion_enabled := True
		end

	disable_mouse_motion
			-- Stop reporting motion with no button held.
		do
			operations.extend ("disable_mouse_motion")
			is_mouse_motion_enabled := False
		end

	is_mouse_motion_enabled: BOOLEAN

	enable_bracketed_paste
			-- Enable bracketed paste.
		do
			operations.extend ("enable_bracketed_paste")
			is_bracketed_paste_enabled := True
		end

	disable_bracketed_paste
			-- Disable bracketed paste.
		do
			operations.extend ("disable_bracketed_paste")
			is_bracketed_paste_enabled := False
		end

	is_bracketed_paste_enabled: BOOLEAN

	enable_focus_change
			-- Enable focus events.
		do
			operations.extend ("enable_focus_change")
			is_focus_change_enabled := True
		end

	disable_focus_change
			-- Disable focus events.
		do
			operations.extend ("disable_focus_change")
			is_focus_change_enabled := False
		end

	is_focus_change_enabled: BOOLEAN

	enable_keyboard_enhancement
			-- Enable extended keyboard reporting.
		do
			operations.extend ("enable_keyboard_enhancement")
			is_keyboard_enhancement_enabled := True
		end

	disable_keyboard_enhancement
			-- Disable extended keyboard reporting.
		do
			operations.extend ("disable_keyboard_enhancement")
			is_keyboard_enhancement_enabled := False
		end

	is_keyboard_enhancement_enabled: BOOLEAN

feature {NONE} -- Implementation

	grid: ARRAY2 [CHARACTER_32]
			-- Character grid storage

	output_scanner: ANSI_TEXT_SCANNER
			-- Escape sequence scanner (state persists across writes)
		do
			if attached internal_output_scanner as l_output_scanner then
				Result := l_output_scanner
			else
				create Result.make
				internal_output_scanner := Result
			end
		end

	internal_output_scanner: detachable ANSI_TEXT_SCANNER
			-- Storage of `output_scanner`, created on first use (rather than a self-initializing
			-- attribute, which is not initialized when the library is compiled without void safety)

end
