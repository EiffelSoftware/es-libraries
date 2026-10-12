note
	description: "[
		State for TUI_TEXT_INPUT widget holding string content, cursor position,
		and horizontal viewport scroll offset.
		The cursor always sits on a grapheme cluster boundary (invariant `cursor_on_boundary`):
		moving and deleting step over whole clusters (a base character with its combining marks,
		a ZWJ emoji, a flag). An edit can regroup the clusters around it (a character typed
		before a combining mark or a regional indicator joins them), so after inserting the
		cursor moves forward to the next boundary, and after deleting back to the previous one.
		The text is a single line without control characters (invariant `single_line`): text
		that comes in (typed, pasted, set) has each TAB and line break (CR LF, CR or LF) turned
		into one space, and every other control character (C0, DEL, C1) removed.
		The scroll offset is measured in display columns, so wide characters scroll correctly.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEXT_INPUT_STATE

inherit
	WIDGET_STATE
		redefine
			default_create
		end

create
	default_create,
	make_with_text

feature {NONE} -- Initialization

	default_create
			-- Initialize with empty text and cursor at 0.
		do
			create content.make_empty
			cursor_position := 0
			scroll_offset := 0
		ensure then
			value_empty: value.is_empty
			cursor_at_zero: cursor_position = 0
			scroll_at_zero: scroll_offset = 0
		end

	make_with_text (a_text: READABLE_STRING_GENERAL)
			-- Initialize with `a_text` and cursor at the end.
		require
			text_not_void: a_text /= Void
		do
			content := single_line_text (a_text)
			cursor_position := content.count
			scroll_offset := 0
		ensure
			value_set: value.same_string (single_line_text (a_text))
			cursor_at_end: cursor_position = value.count
		end

feature -- Access

	value: READABLE_STRING_32
			-- Current text content (read-only view; edit through the commands below)
		do
			Result := content
		end

	cursor_position: INTEGER
			-- Cursor index in code points (0..value.count, where 0 is before the first character),
			-- always on a grapheme cluster boundary

	scroll_offset: INTEGER
			-- Display columns scrolled horizontally from the left edge (kept by the widget
			-- so that the cursor stays visible)

	character_count: INTEGER
			-- Length of text content in code points
		do
			Result := content.count
		ensure
			matches_value_count: Result = value.count
		end

	cursor_column: INTEGER
			-- Display column of the cursor from the start of the text
		do
			Result := {UNICODE_WIDTH}.string_width (content.substring (1, cursor_position)).to_integer_32
		ensure
			non_negative: Result >= 0
		end

feature -- Status report

	is_boundary (a_pos: INTEGER): BOOLEAN
			-- Is cursor position `a_pos` between two grapheme clusters (or at an end)?
		require
			in_range: a_pos >= 0 and a_pos <= value.count
		do
			Result := boundary_at_or_before (a_pos) = a_pos
		end

feature -- Conversion

	single_line_text (a_text: READABLE_STRING_GENERAL): STRING_32
			-- `a_text` as the input keeps it: each TAB and line break (CR LF, CR or LF) becomes
			-- one space, and every other control character (C0, DEL, C1) is removed.
		local
			i: INTEGER
			l_code: NATURAL_32
		do
			create Result.make (a_text.count)
			from
				i := 1
			until
				i > a_text.count
			loop
				l_code := a_text.code (i)
				if l_code = 9 or l_code = 10 then
					Result.append_character (' ')
				elseif l_code = 13 then
					Result.append_character (' ')
					if i < a_text.count and then a_text.code (i + 1) = 10 then
						i := i + 1
					end
				elseif not {UNICODE_WIDTH}.is_control (l_code) then
					Result.append_code (l_code)
				end
				i := i + 1
			end
		ensure
			instance_free: class
			no_controls: not has_control (Result)
			not_longer: Result.count <= a_text.count
		end

	has_control (a_text: READABLE_STRING_GENERAL): BOOLEAN
			-- Does `a_text` hold a C0 or C1 control character (DEL included)?
		local
			i: INTEGER
		do
			from
				i := 1
			until
				Result or i > a_text.count
			loop
				Result := {UNICODE_WIDTH}.is_control (a_text.code (i))
				i := i + 1
			end
		ensure
			instance_free: class
		end

feature -- Element Change & Editing

	set_value (a_text: READABLE_STRING_GENERAL)
			-- Replace content with `a_text` (as `single_line_text` keeps it) and clamp cursor.
		require
			text_not_void: a_text /= Void
		do
			content := single_line_text (a_text)
			cursor_position := boundary_at_or_before (cursor_position.min (content.count))
		ensure
			value_set: value.same_string (single_line_text (a_text))
			cursor_valid: cursor_position <= value.count
		end

	set_cursor_position (a_pos: INTEGER)
			-- Set cursor position, clamped to [0, value.count] and moved back to a cluster boundary.
		do
			cursor_position := boundary_at_or_before (a_pos.max (0).min (content.count))
		ensure
			cursor_valid: cursor_position >= 0 and cursor_position <= value.count
			not_after_request: cursor_position <= a_pos.max (0)
		end

	set_scroll_offset (a_offset: INTEGER)
			-- Set horizontal scroll offset in display columns (negative values become 0).
		do
			scroll_offset := a_offset.max (0)
		ensure
			scroll_valid: scroll_offset = a_offset.max (0)
		end

	insert_character (c: CHARACTER_32)
			-- Insert character `c` (as `single_line_text` keeps it) at the cursor, and move the
			-- cursor after it, to the next cluster boundary if `c` joined the following cluster.
		do
			insert_string (create {STRING_32}.make_filled (c, 1))
		ensure
			one_more_char: not {UNICODE_WIDTH}.is_control (c.natural_32_code) implies value.count = old value.count + 1
			ignored_control: ({UNICODE_WIDTH}.is_control (c.natural_32_code) and c /= '%T' and c /= '%N' and c /= '%R') implies value.same_string (old value.twin)
			cursor_after_insertion: cursor_position >= old cursor_position + (value.count - old value.count)
		end

	insert_string (s: READABLE_STRING_GENERAL)
			-- Insert `s` (as `single_line_text` keeps it) at the cursor, and move the cursor after
			-- it, to the next cluster boundary if the text joined the following cluster.
		require
			string_not_void: s /= Void
		local
			l_text: STRING_32
		do
			l_text := single_line_text (s)
			if not l_text.is_empty then
				content.insert_string (l_text, cursor_position + 1)
				cursor_position := boundary_at_or_after (cursor_position + l_text.count)
			end
		ensure
			count_increased: value.count = old value.count + single_line_text (s).count
			cursor_after_insertion: cursor_position >= old cursor_position + single_line_text (s).count
		end

	delete_backward
			-- Backspace: delete the grapheme cluster immediately before the cursor, if any.
		local
			l_start: INTEGER
		do
			if cursor_position > 0 then
				l_start := previous_boundary (cursor_position)
				content.remove_substring (l_start + 1, cursor_position)
				-- The clusters on both sides may now form one: stay before it
				cursor_position := boundary_at_or_before (l_start)
			end
		ensure
			count_decreased: old cursor_position > 0 implies value.count < old value.count
			cursor_decreased: old cursor_position > 0 implies cursor_position < old cursor_position
			removed_before_cursor: cursor_position <= old cursor_position - (old value.count - value.count)
		end

	delete_forward
			-- Delete: delete the grapheme cluster at the cursor, if any.
		do
			if cursor_position < content.count then
				content.remove_substring (cursor_position + 1, {UNICODE_WIDTH}.grapheme_end (content, cursor_position + 1))
				-- The clusters on both sides may now form one: stay before it
				cursor_position := boundary_at_or_before (cursor_position)
			end
		ensure
			count_decreased: old cursor_position < old value.count implies value.count < old value.count
			cursor_not_moved_right: cursor_position <= old cursor_position
		end

	move_cursor_left
			-- Move cursor left one grapheme cluster.
		do
			if cursor_position > 0 then
				cursor_position := previous_boundary (cursor_position)
			end
		ensure
			moved_left: old cursor_position > 0 implies cursor_position < old cursor_position
		end

	move_cursor_right
			-- Move cursor right one grapheme cluster.
		do
			if cursor_position < content.count then
				cursor_position := {UNICODE_WIDTH}.grapheme_end (content, cursor_position + 1)
			end
		ensure
			moved_right: old cursor_position < value.count implies cursor_position > old cursor_position
		end

	move_cursor_home
			-- Move cursor to beginning of text.
		do
			cursor_position := 0
		ensure
			cursor_at_start: cursor_position = 0
		end

	move_cursor_end
			-- Move cursor to end of text.
		do
			cursor_position := content.count
		ensure
			cursor_at_end: cursor_position = value.count
		end

feature {NONE} -- Implementation

	content: STRING_32
			-- Text being edited

	previous_boundary (a_pos: INTEGER): INTEGER
			-- Start (as a cursor position) of the grapheme cluster that ends at cursor position `a_pos`
		require
			positive: a_pos > 0 and a_pos <= content.count
		local
			l_next: INTEGER
		do
			from
				l_next := {UNICODE_WIDTH}.grapheme_end (content, 1)
			until
				l_next >= a_pos
			loop
				Result := l_next
				l_next := {UNICODE_WIDTH}.grapheme_end (content, l_next + 1)
			end
		ensure
			before: Result < a_pos
		end

	boundary_at_or_after (a_pos: INTEGER): INTEGER
			-- Smallest cluster boundary not before cursor position `a_pos`
		require
			in_range: a_pos >= 0 and a_pos <= content.count
		do
			from
				Result := boundary_at_or_before (a_pos)
			until
				Result >= a_pos
			loop
				Result := {UNICODE_WIDTH}.grapheme_end (content, Result + 1)
			end
		ensure
			not_before: Result >= a_pos
			in_range: Result <= content.count
		end

	boundary_at_or_before (a_pos: INTEGER): INTEGER
			-- Largest cluster boundary not after cursor position `a_pos`
		require
			in_range: a_pos >= 0 and a_pos <= content.count
		local
			l_next: INTEGER
		do
			from
				l_next := 0
			until
				l_next > a_pos
			loop
				Result := l_next
				if l_next < content.count then
					l_next := {UNICODE_WIDTH}.grapheme_end (content, l_next + 1)
				else
					l_next := a_pos + 1
				end
			end
		ensure
			not_after: Result <= a_pos
		end

invariant
	content_not_void: content /= Void
	valid_cursor: cursor_position >= 0 and cursor_position <= value.count
	cursor_on_boundary: is_boundary (cursor_position)
	single_line: not has_control (value)
	valid_scroll: scroll_offset >= 0

end
