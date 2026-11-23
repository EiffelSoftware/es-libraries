note
	description: "[
		Multi-line editor state: grapheme-aware cursor, hard newlines, vertical scroll,
		basic selection, and bounded undo and redo.
		Undo works in steps: each step is a snapshot of the text, cursor and selection anchor
		taken before its first edit. Consecutive edits of one kind at the cursor join the open
		step without copying anything (see `insert_character`, `delete_backward` and
		`delete_forward`); every other edit, a move, a selection change, `undo` or `redo` ends it.
		Edits that change nothing record nothing.
		`undo` keeps the state it leaves for `redo`, and `redo` gives it back for `undo`. An
		edit that starts a new undo step forgets what could be redone; moves and selection
		changes do not. Undo and redo steps together never exceed `Max_undo`.
		Unlike TEXT_INPUT_STATE, LF is kept as a line break; other C0/C1 controls are stripped
		(TAB becomes a space; CR/CRLF become a single LF).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEXT_AREA_STATE

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
			-- Initialize empty with cursor at 0.
		do
			create content.make_empty
			cursor_position := 0
			scroll_row := 0
			selection_anchor := -1
			create undo_stack.make (Max_undo)
			create redo_stack.make (Max_undo)
			preferred_column := 0
			undo_group := No_group
			group_end := -1
		ensure then
			empty: value.is_empty
			cursor_zero: cursor_position = 0
		end

	make_with_text (a_text: READABLE_STRING_GENERAL)
			-- Initialize with `a_text` and cursor at the end; Up/Down keep the cursor's column.
		require
			text_not_void: a_text /= Void
		do
			default_create
			content := sanitize (a_text)
			cursor_position := content.count
			preferred_column := column_of (cursor_position)
		ensure
			value_set: value.same_string (sanitize (a_text))
			cursor_at_end: cursor_position = value.count
			column_of_cursor: preferred_column = column_of (cursor_position)
		end

feature -- Access

	value: READABLE_STRING_32
			-- Current multi-line text
		do
			Result := content
		end

	cursor_position: INTEGER
			-- Cursor index in code points (0..value.count), on a grapheme boundary

	scroll_row: INTEGER
			-- First visual row shown in the viewport (0-based)

	selection_anchor: INTEGER
			-- Selection other end, or -1 when there is no selection

	preferred_column: INTEGER
			-- Preferred display column for vertical movement

	Max_undo: INTEGER = 64
			-- Maximum undo and redo steps retained together (the oldest undo step is dropped
			-- beyond it)

	undo_count: INTEGER
			-- Number of undo steps available
		do
			Result := undo_stack.count
		ensure
			bounded: Result >= 0 and Result <= Max_undo
		end

	redo_count: INTEGER
			-- Number of redo steps available
		do
			Result := redo_stack.count
		ensure
			bounded: Result >= 0 and Result <= Max_undo
		end

feature -- Status report

	has_selection: BOOLEAN
			-- Is a selection active?
		do
			Result := selection_anchor >= 0 and selection_anchor /= cursor_position
		end

	selection_start: INTEGER
			-- Smaller end of the selection (or cursor when none)
		do
			if has_selection then
				Result := selection_anchor.min (cursor_position)
			else
				Result := cursor_position
			end
		end

	selection_end: INTEGER
			-- Larger end of the selection (or cursor when none)
		do
			if has_selection then
				Result := selection_anchor.max (cursor_position)
			else
				Result := cursor_position
			end
		end

	selected_text: STRING_32
			-- Text of the selection, newlines included; empty when there is no selection.
			-- A new string each time (for a copy, e.g. {TERMINAL}.copy_to_clipboard).
		do
			Result := content.substring (selection_start + 1, selection_end)
		ensure
			fresh: Result /= content
			empty_without_selection: not has_selection implies Result.is_empty
			selection_length: Result.count = selection_end - selection_start
			from_value: Result.same_string (value.substring (selection_start + 1, selection_end))
		end

	is_undo_group_open: BOOLEAN
			-- Can the next edit of the same kind at the cursor join the last undo step?
		do
			Result := undo_group /= No_group
		end

	is_boundary (a_pos: INTEGER): BOOLEAN
			-- Is `a_pos` on a grapheme cluster boundary?
		require
			in_range: a_pos >= 0 and a_pos <= value.count
		do
			Result := boundary_at_or_before (a_pos) = a_pos
		end

	line_count: INTEGER
			-- Number of hard lines (at least 1)
		local
			i: INTEGER
		do
			Result := 1
			from
				i := 1
			until
				i > content.count
			loop
				if content.code (i) = 10 then
					Result := Result + 1
				end
				i := i + 1
			end
		ensure
			at_least_one: Result >= 1
		end

feature -- Conversion

	sanitize (a_text: READABLE_STRING_GENERAL): STRING_32
			-- `a_text` with TAB→space, CR/CRLF→LF, other controls removed.
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
				if l_code = 9 then
					Result.append_character (' ')
				elseif l_code = 10 then
					Result.append_character ('%N')
				elseif l_code = 13 then
					Result.append_character ('%N')
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
		end

feature -- Element change

	set_value (a_text: READABLE_STRING_GENERAL)
			-- Replace content with sanitized `a_text` and clamp cursor. When the text changes,
			-- Up/Down take the column of the clamped cursor in the new text.
		require
			text_not_void: a_text /= Void
		local
			l_text: STRING_32
		do
			end_undo_group
			l_text := sanitize (a_text)
			if not l_text.same_string (content) then
				invalidate_visual_rows
				push_undo
				content := l_text
				cursor_position := boundary_at_or_before (cursor_position.min (content.count))
				preferred_column := column_of (cursor_position)
			end
			clear_selection
		ensure
			value_set: value.same_string (sanitize (a_text))
			column_of_cursor: not value.same_string (old value.twin) implies preferred_column = column_of (cursor_position)
		end

	set_cursor_position (a_pos: INTEGER)
			-- Move cursor to a grapheme boundary near `a_pos`.
		do
			end_undo_group
			cursor_position := boundary_at_or_before (a_pos.max (0).min (content.count))
			preferred_column := column_of (cursor_position)
		ensure
			valid: cursor_position >= 0 and cursor_position <= value.count
		end

	set_scroll_row (a_row: INTEGER)
			-- Set vertical scroll origin.
		do
			scroll_row := a_row.max (0)
		ensure
			non_negative: scroll_row >= 0
		end

	clear_selection
			-- Drop the selection.
		do
			selection_anchor := -1
		ensure
			no_selection: not has_selection
		end

	set_selection_anchor (a_pos: INTEGER)
			-- Start or update selection from `a_pos`.
		do
			end_undo_group
			selection_anchor := boundary_at_or_before (a_pos.max (0).min (content.count))
		end

	end_undo_group
			-- Make the next edit start a new undo step (an app may call it, e.g. after a
			-- pause in typing).
		do
			undo_group := No_group
			group_end := -1
		ensure
			closed: not is_undo_group_open
		end

	select_all
			-- Select the entire buffer.
		do
			end_undo_group
			selection_anchor := 0
			cursor_position := content.count
			preferred_column := column_of (cursor_position)
		ensure
			selected_or_empty: value.is_empty or has_selection
			cursor_at_end: cursor_position = value.count
			column_of_cursor: preferred_column = column_of (cursor_position)
		end

feature -- Editing

	insert_character (c: CHARACTER_32)
			-- Insert `c` (sanitized) at the cursor, replacing any selection.
			-- Undo steps: characters typed one after another at the cursor join one step, as in
			-- editors, so no snapshot is taken for them. A new step starts with each new word
			-- (a non-space typed after a space), and after a newline, any other edit, a move, a
			-- selection change or `undo`. A character that sanitizes to nothing (a control
			-- character) with no selection changes nothing and records nothing.
		local
			l_text: STRING_32
			l_joins: BOOLEAN
		do
			l_text := sanitize (create {STRING_32}.make_filled (c, 1))
			if l_text.is_empty and not has_selection then
				clear_selection
			elseif l_text.is_empty or else l_text [1] = '%N' then
				end_undo_group
				insert_text (l_text, True)
			else
				l_joins := joins_typing_group (c)
				insert_text (l_text, not l_joins)
				open_undo_group (Typing_group)
				is_last_typed_space := l_text [1] = ' '
			end
		ensure
			unchanged_records_nothing: (not old has_selection and value.count = old value.count) implies undo_count = old undo_count
			joined_open_step: old joins_typing_group (c) implies undo_count = old undo_count
			newline_is_own_step: sanitize (create {STRING_32}.make_filled (c, 1)).same_string ("%N") implies not is_undo_group_open
		end

	insert_newline
			-- Insert a hard line break at the cursor.
		do
			insert_string ("%N")
		end

	insert_string (s: READABLE_STRING_GENERAL)
			-- Insert sanitized `s` at the cursor (replacing selection), as one undo step.
		require
			string_not_void: s /= Void
		do
			end_undo_group
			insert_text (s, True)
		end

	delete_backward
			-- Backspace: delete selection or the grapheme before the cursor.
			-- Undo steps: Backspaces one after another (no move, no selection in between) join
			-- one step. Deleting a selection is a step of its own. At the start of the text
			-- nothing changes and nothing is recorded.
		local
			l_start: INTEGER
		do
			if has_selection then
				end_undo_group
				invalidate_visual_rows
				push_undo
				delete_selection_internal
			elseif cursor_position > 0 then
				invalidate_visual_rows
				if not continues_undo_group (Backspace_group) then
					end_undo_group
					push_undo
				end
				l_start := previous_boundary (cursor_position)
				content.remove_substring (l_start + 1, cursor_position)
				cursor_position := boundary_at_or_before (l_start)
				preferred_column := column_of (cursor_position)
				open_undo_group (Backspace_group)
			end
			clear_selection
		ensure
			anchor_cleared: selection_anchor = -1
			at_start_records_nothing: (old cursor_position = 0 and not old has_selection) implies
				(value.count = old value.count and undo_count = old undo_count)
			joined_open_step: old continues_undo_group (Backspace_group) implies undo_count = old undo_count
		end

	delete_forward
			-- Delete: delete selection or the grapheme at the cursor.
			-- Undo steps: Deletes one after another (no move, no selection in between) join
			-- one step. Deleting a selection is a step of its own. At the end of the text
			-- nothing changes and nothing is recorded.
		do
			if has_selection then
				end_undo_group
				invalidate_visual_rows
				push_undo
				delete_selection_internal
			elseif cursor_position < content.count then
				invalidate_visual_rows
				if not continues_undo_group (Delete_group) then
					end_undo_group
					push_undo
				end
				content.remove_substring (cursor_position + 1, {UNICODE_WIDTH}.grapheme_end (content, cursor_position + 1))
				cursor_position := boundary_at_or_before (cursor_position)
				preferred_column := column_of (cursor_position)
				open_undo_group (Delete_group)
			end
			clear_selection
		ensure
			anchor_cleared: selection_anchor = -1
			at_end_records_nothing: (old cursor_position = old value.count and not old has_selection) implies
				(value.count = old value.count and undo_count = old undo_count)
			joined_open_step: old continues_undo_group (Delete_group) implies undo_count = old undo_count
		end

feature -- Navigation

	move_cursor_left (a_extend: BOOLEAN)
			-- Move left one grapheme; extend selection when `a_extend`.
		do
			prepare_move (a_extend)
			if cursor_position > 0 then
				cursor_position := previous_boundary (cursor_position)
				preferred_column := column_of (cursor_position)
			end
			normalize_selection
		end

	move_cursor_right (a_extend: BOOLEAN)
			-- Move right one grapheme; extend selection when `a_extend`.
		do
			prepare_move (a_extend)
			if cursor_position < content.count then
				cursor_position := {UNICODE_WIDTH}.grapheme_end (content, cursor_position + 1)
				preferred_column := column_of (cursor_position)
			end
			normalize_selection
		end

	move_cursor_home (a_extend: BOOLEAN)
			-- Move to start of the current hard line.
		do
			prepare_move (a_extend)
			cursor_position := line_start (cursor_position)
			preferred_column := 0
			normalize_selection
		end

	move_cursor_end (a_extend: BOOLEAN)
			-- Move to end of the current hard line (before its LF).
		do
			prepare_move (a_extend)
			cursor_position := line_end (cursor_position)
			preferred_column := column_of (cursor_position)
			normalize_selection
		end

	move_cursor_up (a_extend: BOOLEAN)
			-- Move to the previous visual row when `has_visual_rows`, else to the previous
			-- hard line, keeping the preferred column.
		local
			l_start, l_prev_end, l_prev_start, l_row: INTEGER
		do
			prepare_move (a_extend)
			if attached visual_rows as l_rows then
				l_row := visual_row_index (cursor_position, l_rows) + 1
				if l_row > 1 then
					move_to_visual_row (l_rows, l_row, l_row - 1)
				end
			else
				l_start := line_start (cursor_position)
				if l_start > 0 then
					l_prev_end := l_start - 1
					l_prev_start := line_start (l_prev_end)
					cursor_position := position_at_column (l_prev_start, l_prev_end, preferred_column)
				end
			end
			normalize_selection
		end

	move_cursor_down (a_extend: BOOLEAN)
			-- Move to the next visual row when `has_visual_rows`, else to the next
			-- hard line, keeping the preferred column.
		local
			l_end, l_next_start, l_next_end, l_row: INTEGER
		do
			prepare_move (a_extend)
			if attached visual_rows as l_rows then
				l_row := visual_row_index (cursor_position, l_rows) + 1
				if l_row < l_rows.count then
					move_to_visual_row (l_rows, l_row, l_row + 1)
				end
			else
				l_end := line_end (cursor_position)
				if l_end < content.count then
					l_next_start := l_end + 1
					l_next_end := line_end (l_next_start)
					cursor_position := position_at_column (l_next_start, l_next_end, preferred_column)
				end
			end
			normalize_selection
		end

feature -- Undo

	undo
			-- Go back one undo step: restore the text, cursor and selection anchor as they were
			-- before the step's first edit, and keep the current ones for `redo`. Nothing
			-- happens when there is nothing to undo.
		local
			l_before: TUPLE [text: STRING_32; cursor: INTEGER; anchor: INTEGER]
		do
			end_undo_group
			if can_undo then
				l_before := undo_stack.item
				undo_stack.remove
					-- No copy: the current text leaves `content` for the redo entry
				redo_stack.put ([[content, cursor_position, selection_anchor], l_before])
				restore (l_before)
			end
		ensure
			step_closed: not is_undo_group_open
			one_step_back: old can_undo implies undo_count = old undo_count - 1
			kept_for_redo: old can_undo implies redo_count = old redo_count + 1
			nothing_to_undo: not old can_undo implies (value.same_string (old value.twin) and redo_count = old redo_count)
		end

	can_undo: BOOLEAN
			-- Is an undo snapshot available?
		do
			Result := not undo_stack.is_empty
		end

	redo
			-- Go forward again over the last undone step: restore the text, cursor and
			-- selection anchor as they were when it was undone, and give the step back to
			-- `undo` as it was (an undo then returns to where the step's first edit was,
			-- wherever the cursor went in between). Nothing happens when there is nothing to
			-- redo.
		local
			l_step: TUPLE [after, before: TUPLE [text: STRING_32; cursor: INTEGER; anchor: INTEGER]]
		do
			end_undo_group
			if can_redo then
				l_step := redo_stack.item
				redo_stack.remove
				undo_stack.put (l_step.before)
				restore (l_step.after)
			end
		ensure
			step_closed: not is_undo_group_open
			one_step_forward: old can_redo implies redo_count = old redo_count - 1
			kept_for_undo: old can_redo implies undo_count = old undo_count + 1
			nothing_to_redo: not old can_redo implies (value.same_string (old value.twin) and undo_count = old undo_count)
		end

	can_redo: BOOLEAN
			-- Is a redo snapshot available?
		do
			Result := not redo_stack.is_empty
		end

feature -- Visual rows

	has_visual_rows: BOOLEAN
			-- Does the state know the row layout of the current content?
			-- True from a render until the next edit.
		do
			Result := attached visual_rows
		end

	set_visual_rows (a_starts: ARRAYED_LIST [INTEGER])
			-- Record the start offset of each visual row, as the widget laid out the
			-- current content. The state does not wrap text itself: it only keeps these
			-- offsets so that Up/Down can move by rows until the next edit.
		require
			starts_attached: a_starts /= Void
			not_empty: not a_starts.is_empty
			first_row_at_zero: a_starts.first = 0
			starts_in_range: across a_starts as ic all ic >= 0 and ic <= value.count end
		do
			visual_rows := a_starts.twin
		ensure
			has_visual_rows: has_visual_rows
		end

	invalidate_visual_rows
			-- Forget the recorded layout (Up/Down fall back to hard lines).
		do
			visual_rows := Void
		ensure
			no_visual_rows: not has_visual_rows
		end

	visual_row_index (a_pos: INTEGER; a_starts: READABLE_INDEXABLE [INTEGER]): INTEGER
			-- 0-based index of the visual row (from row starts `a_starts`) that shows offset `a_pos`:
			-- the last row starting at or before `a_pos`.
		require
			starts_attached: a_starts /= Void
			not_empty: a_starts.upper >= a_starts.lower
		local
			l_lo, l_hi, l_mid: INTEGER
		do
			from
				l_lo := a_starts.lower
				l_hi := a_starts.upper
			until
				l_lo >= l_hi
			loop
				l_mid := (l_lo + l_hi + 1) // 2
				if a_starts [l_mid] <= a_pos then
					l_lo := l_mid
				else
					l_hi := l_mid - 1
				end
			end
			Result := l_lo - a_starts.lower
		ensure
			instance_free: class
			in_range: Result >= 0 and Result <= a_starts.upper - a_starts.lower
		end

feature -- Viewport

	scroll_to_row (a_row, a_height, a_total: INTEGER)
			-- Adjust `scroll_row` so visual row `a_row` is inside a viewport of `a_height` rows,
			-- with `a_total` visual rows in all. The widget computes rows from its wrap layout;
			-- the state stays layout-free (like LIST_STATE offsets).
		require
			positive_height: a_height > 0
			row_in_range: a_row >= 0 and a_row < a_total
		do
			if a_row < scroll_row then
				scroll_row := a_row
			elseif a_row >= scroll_row + a_height then
				scroll_row := a_row - a_height + 1
			end
				-- Do not leave blank rows at the bottom when content shrank.
			scroll_row := scroll_row.min ((a_total - a_height).max (0))
		ensure
			row_visible: a_row >= scroll_row and a_row < scroll_row + a_height
			non_negative: scroll_row >= 0
		end

	hard_line_index (a_pos: INTEGER): INTEGER
			-- 0-based hard line containing cursor position `a_pos`.
		require
			in_range: a_pos >= 0 and a_pos <= value.count
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > a_pos
			loop
				if content.code (i) = 10 then
					Result := Result + 1
				end
				i := i + 1
			end
		end

	line_start (a_pos: INTEGER): INTEGER
			-- Start offset of the hard line containing `a_pos`.
		require
			in_range: a_pos >= 0 and a_pos <= value.count
		local
			i: INTEGER
		do
			from
				i := a_pos
			until
				i <= 0 or else content.code (i) = 10
			loop
				i := i - 1
			end
			if i > 0 and then content.code (i) = 10 then
				Result := i
			else
				Result := 0
			end
		end

	line_end (a_pos: INTEGER): INTEGER
			-- Offset just before the LF ending the hard line containing `a_pos`, or content.count.
		require
			in_range: a_pos >= 0 and a_pos <= value.count
		local
			i: INTEGER
		do
			from
				i := a_pos + 1
			until
				i > content.count or else content.code (i) = 10
			loop
				i := i + 1
			end
			Result := i - 1
		end

	column_of (a_pos: INTEGER): INTEGER
			-- Display column of `a_pos` within its hard line.
		require
			in_range: a_pos >= 0 and a_pos <= value.count
		local
			l_start: INTEGER
		do
			l_start := line_start (a_pos)
			Result := {UNICODE_WIDTH}.string_width (content.substring (l_start + 1, a_pos)).to_integer_32
		end

feature {NONE} -- Implementation

	content: STRING_32
			-- Editable buffer

	undo_stack: ARRAYED_STACK [TUPLE [text: STRING_32; cursor: INTEGER; anchor: INTEGER]]
			-- One entry per undo step: the text, cursor and selection anchor before the
			-- step's first edit (most recent on top)

	redo_stack: ARRAYED_STACK [TUPLE [after, before: TUPLE [text: STRING_32; cursor: INTEGER; anchor: INTEGER]]]
			-- One entry per undone step (most recently undone on top): the text, cursor and
			-- selection anchor when it was undone (`after`), and the step's undo entry
			-- (`before`), given back to `undo` as it was

	undo_group: INTEGER
			-- Kind of edit the open undo step is made of (`Typing_group`, `Backspace_group`
			-- or `Delete_group`), or `No_group` when the next edit starts a new step

	group_end: INTEGER
			-- Cursor offset where the open undo step ended, or -1 when none is open

	is_last_typed_space: BOOLEAN
			-- Was the last character of the open typing step a space?

	No_group: INTEGER = 0
			-- No undo step is open

	Typing_group: INTEGER = 1
			-- The open step is a run of typed characters

	Backspace_group: INTEGER = 2
			-- The open step is a run of Backspaces

	Delete_group: INTEGER = 3
			-- The open step is a run of Deletes

	continues_undo_group (a_kind: INTEGER): BOOLEAN
			-- Can an edit of kind `a_kind` join the open undo step instead of starting one?
		do
			Result := undo_group = a_kind and group_end = cursor_position
				and not has_selection and not undo_stack.is_empty
		ensure
			only_when_open: Result implies is_undo_group_open
		end

	joins_typing_group (c: CHARACTER_32): BOOLEAN
			-- Would typing `c` now join the open typing step? Only a printable character,
			-- typed where the step ended with no selection, and not the first letter of a
			-- new word (a non-space after a space).
		local
			l_text: STRING_32
		do
			l_text := sanitize (create {STRING_32}.make_filled (c, 1))
			Result := continues_undo_group (Typing_group) and l_text.count = 1
				and then (l_text [1] /= '%N' and (l_text [1] = ' ' or not is_last_typed_space))
		ensure
			only_when_open: Result implies undo_group = Typing_group
		end

	open_undo_group (a_kind: INTEGER)
			-- Let later edits of kind `a_kind` at the cursor join the last undo step.
		require
			kind_valid: a_kind = Typing_group or a_kind = Backspace_group or a_kind = Delete_group
			has_step: not undo_stack.is_empty
		do
			undo_group := a_kind
			group_end := cursor_position
		ensure
			open: undo_group = a_kind and group_end = cursor_position
		end

	insert_text (s: READABLE_STRING_GENERAL; a_snapshot: BOOLEAN)
			-- Insert sanitized `s` at the cursor, replacing any selection; snapshot the
			-- content first when `a_snapshot`. Nothing changes (and nothing is recorded)
			-- when `s` sanitizes to nothing and there is no selection.
		local
			l_text: STRING_32
		do
			l_text := sanitize (s)
			if has_selection or not l_text.is_empty then
				invalidate_visual_rows
				if a_snapshot then
					push_undo
				end
				delete_selection_internal
				if not l_text.is_empty then
					content.insert_string (l_text, cursor_position + 1)
					cursor_position := boundary_at_or_after (cursor_position + l_text.count)
				end
				preferred_column := column_of (cursor_position)
			end
			clear_selection
		end

	push_undo
			-- Start a new undo step: snapshot the text, cursor and anchor before an edit, and
			-- forget what could be redone (the edit starts a new history from here).
			-- This is the only copy of the text an edit makes, so a run of edits that joins
			-- the step costs no copy (see `continues_undo_group`).
		do
			redo_stack.wipe_out
			if undo_stack.count >= Max_undo then
				-- Drop oldest: rebuild without the bottom entry
				trim_undo_stack
			end
			undo_stack.put ([content.twin, cursor_position, selection_anchor])
		ensure
			pushed: undo_stack.item.cursor = cursor_position and undo_stack.item.anchor = selection_anchor
			bounded: undo_stack.count <= Max_undo
			nothing_to_redo: redo_stack.is_empty
		end

	restore (a_snap: TUPLE [text: STRING_32; cursor: INTEGER; anchor: INTEGER])
			-- Make the text, cursor and selection anchor those of `a_snap`. Its text becomes
			-- `content` itself: no entry still on a stack may share it, since edits change
			-- `content` in place (an entry handed out by `undo` stays only in the redo entry,
			-- which the first edit forgets before changing anything).
		require
			snap_attached: a_snap /= Void
		do
			invalidate_visual_rows
			content := a_snap.text
			cursor_position := boundary_at_or_before (a_snap.cursor.max (0).min (content.count))
			if a_snap.anchor >= 0 and a_snap.anchor <= content.count then
				selection_anchor := a_snap.anchor
			else
				selection_anchor := -1
			end
			normalize_selection
			preferred_column := column_of (cursor_position)
		end

	trim_undo_stack
			-- Remove the oldest undo entry when at capacity.
		local
			l_items: ARRAYED_LIST [TUPLE [text: STRING_32; cursor: INTEGER; anchor: INTEGER]]
			i: INTEGER
		do
			create l_items.make (undo_stack.count)
			from
			until
				undo_stack.is_empty
			loop
				l_items.extend (undo_stack.item)
				undo_stack.remove
			end
			from
				i := l_items.count - 1
			until
				i < 1
			loop
				undo_stack.put (l_items.i_th (i))
				i := i - 1
			end
		end

	delete_selection_internal
			-- Remove the selected range and place the cursor at its start.
		local
			l_s, l_e: INTEGER
		do
			if has_selection then
				l_s := selection_start
				l_e := selection_end
				content.remove_substring (l_s + 1, l_e)
				cursor_position := boundary_at_or_before (l_s)
				preferred_column := column_of (cursor_position)
			end
		end

	prepare_move (a_extend: BOOLEAN)
			-- Record selection anchor when starting an extended move.
		do
			end_undo_group
			if a_extend then
				if selection_anchor < 0 then
					selection_anchor := cursor_position
				end
			else
				clear_selection
			end
		end

	visual_rows: detachable ARRAYED_LIST [INTEGER]
			-- Row start offsets from the last render, or Void after an edit

	move_to_visual_row (a_rows: ARRAYED_LIST [INTEGER]; a_from, a_to: INTEGER)
			-- Move the cursor from row `a_from` to row `a_to` (1-based), keeping the goal
			-- column relative to the row start. `preferred_column` stays a hard-line
			-- column: the goal plus the width of the hard line before the target row.
		require
			from_valid: a_rows.valid_index (a_from)
			to_valid: a_rows.valid_index (a_to)
		local
			l_goal, l_start: INTEGER
		do
			l_goal := (preferred_column - column_of (a_rows [a_from])).max (0)
			l_start := a_rows [a_to]
			cursor_position := position_at_column (l_start, visual_row_end (a_rows, a_to), l_goal)
			preferred_column := column_of (l_start) + l_goal
		end

	visual_row_end (a_rows: ARRAYED_LIST [INTEGER]; a_row: INTEGER): INTEGER
			-- Last cursor offset shown on row `a_row` (1-based): the end of the text, the
			-- offset before the LF that ends the row, or, when the next row continues the
			-- same hard line, the start of the row's last grapheme.
		require
			row_valid: a_rows.valid_index (a_row)
		local
			l_next: INTEGER
		do
			if a_row = a_rows.count then
				Result := content.count
			else
				l_next := a_rows [a_row + 1]
				if l_next > 0 and then content.code (l_next) = 10 then
					Result := l_next - 1
				elseif l_next > a_rows [a_row] then
					Result := previous_boundary (l_next)
				else
					Result := l_next
				end
			end
		end

	normalize_selection
			-- An anchor on the cursor selects nothing: drop it so later edits cannot strand it.
		do
			if selection_anchor = cursor_position then
				selection_anchor := -1
			end
		ensure
			no_empty_anchor: selection_anchor /= cursor_position
		end

	position_at_column (a_start, a_end, a_column: INTEGER): INTEGER
			-- Cursor position on [a_start, a_end] closest to display column `a_column`.
		local
			i, l_col, l_next: INTEGER
		do
			Result := a_start
			l_col := 0
			from
				i := a_start
			until
				i >= a_end or l_col >= a_column
			loop
				l_next := {UNICODE_WIDTH}.grapheme_end (content, i + 1)
				l_col := l_col + {UNICODE_WIDTH}.string_width (content.substring (i + 1, l_next)).to_integer_32
				Result := l_next
				i := l_next
			end
		end

	previous_boundary (a_pos: INTEGER): INTEGER
			-- Start of the grapheme ending at `a_pos`.
		require
			positive: a_pos > 0 and a_pos <= content.count
		local
			l_next: INTEGER
		do
				-- LF is always a cluster boundary (UAX #29 GB4/GB5): start at the
				-- line holding the grapheme, not at the start of the text.
			from
				Result := line_start (a_pos - 1)
				l_next := {UNICODE_WIDTH}.grapheme_end (content, Result + 1)
			until
				l_next >= a_pos
			loop
				Result := l_next
				l_next := {UNICODE_WIDTH}.grapheme_end (content, l_next + 1)
			end
		end

	boundary_at_or_after (a_pos: INTEGER): INTEGER
			-- Smallest cluster boundary not before `a_pos`.
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
		end

	boundary_at_or_before (a_pos: INTEGER): INTEGER
			-- Largest cluster boundary not after `a_pos`.
		require
			in_range: a_pos >= 0 and a_pos <= content.count
		local
			l_next: INTEGER
		do
				-- LF is always a cluster boundary: segment from the start of the line only.
			from
				l_next := line_start (a_pos)
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
		end

invariant
	content_attached: content /= Void
	undo_attached: undo_stack /= Void
	valid_cursor: cursor_position >= 0 and cursor_position <= value.count
	cursor_on_boundary: is_boundary (cursor_position)
	valid_scroll: scroll_row >= 0
	valid_anchor: selection_anchor = -1 or (selection_anchor >= 0 and selection_anchor <= value.count)
	undo_bounded: undo_count <= Max_undo
	redo_attached: redo_stack /= Void
	steps_bounded: undo_count + redo_count <= Max_undo
	open_step_at_cursor: is_undo_group_open implies (group_end = cursor_position and selection_anchor = -1 and can_undo)
	open_step_nothing_to_redo: is_undo_group_open implies not can_redo

end
