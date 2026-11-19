note
	description: "[
		Tier 2 example: multi-line TEXT_AREA editor with wrap, selection, undo and redo.
		Ctrl+C copies the selection to the system clipboard through the terminal (OSC 52,
		{TERMINAL}.copy_to_clipboard). A selection over the terminal's clipboard limit is cut
		at a grapheme boundary first ({TERMINAL}.clipboard_prefix). The status line says what
		was copied (a toast once TUI_TOAST exists, P2 W5).
		Ctrl+V reads the clipboard ({TUI_APPLICATION}.read_clipboard, P2b K6): the status line
		says "Reading clipboard..." until the answer, a CLIPBOARD_EVENT, reaches `process'.
		Its text is inserted through TEXT_AREA_STATE.insert_string, which sanitises it (TAB to
		a blank, CR LF to LF, other controls dropped) and makes it one undo step. Any other
		answer (no reply within the timeout, a reply too large or not valid) leaves the text
		alone and the status line points to the terminal's own paste key. On Windows the
		console driver reads the system clipboard itself (P2b K4), but Windows Terminal
		binds Ctrl+V to its own paste by default, and conhost does too when its Ctrl key
		shortcuts are on: there Ctrl+V does not reach the application, and the terminal
		pastes instead. Elsewhere most terminals do not answer an OSC 52 read (see the
		TUI_APPLICATION class note).
		The terminal's own paste (Ctrl+Shift+V, or Ctrl+V where the terminal takes it) is
		the main way in: bracketed paste is turned on, so it comes as a PASTE_EVENT and is
		inserted, sanitised, as one undo step (one per part for a long paste). A terminal
		without bracketed paste types the text in as keys, which are inserted as before.
		Ctrl+C does not quit: raw mode makes it a key like any other (Esc quits).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	EXAMPLE_TEXT_AREA

inherit
	TUI_APPLICATION
		redefine
			make
		end

create
	make,
	make_batch,
	make_on

feature {NONE} -- Initialization

	make
			-- Launch the text area demo.
		local
			l_args: ARGUMENTS_32
			i: INTEGER
		do
			init_state
			Precursor
				-- Ctrl+Z is undo here, as in editors: do not let it suspend (POSIX)
			set_suspend_on_ctrl_z (False)
			create l_args
			auto_exit_frames := -1
			from i := 1 until i > l_args.argument_count loop
				if l_args.argument (i).is_equal ("-batch") then
					auto_exit_frames := 2
				end
				i := i + 1
			end
			frame_counter := 0
			run
		end

	make_batch (a_frames: INTEGER)
			-- Run for `a_frames` frames.
		do
			init_state
			make_with_viewport (create {VIEWPORT}.make_fullscreen)
			set_suspend_on_ctrl_z (False)
			auto_exit_frames := a_frames
			frame_counter := 0
			run
		end

	make_on (a_terminal: TERMINAL [ANSI_TERMINAL_BACKEND])
			-- Initialize on `a_terminal` without running (for scripted tests).
		require
			terminal_attached: a_terminal /= Void
		do
			init_state
			make_with_terminal (a_terminal)
			set_suspend_on_ctrl_z (False)
			auto_exit_frames := -1
			frame_counter := 0
		ensure
			not_running: not is_running
		end

feature {NONE} -- Setup

	init_state
		do
			create area_state.make_with_text ("Hello from TEXT_AREA%NType here. Ctrl+Z undoes, Ctrl+Y redoes.%N")
			create focus_manager.make
			create id_area.make (1)
			focus_manager.register (id_area)
			create status.make_from_string_general ("Select (Shift+arrows, Ctrl+A), then Ctrl+C to copy.")
		end

feature {NONE} -- State

	area_state: TEXT_AREA_STATE
	focus_manager: FOCUS_MANAGER
	id_area: WIDGET_ID
	auto_exit_frames: INTEGER
	frame_counter: INTEGER

	status: STRING_32
			-- Status line: what the last Ctrl+C copied or Ctrl+V pasted

feature {NONE} -- Hooks

	render (a_frame: FRAME)
		local
			l_area: RECT
			l_widget: TUI_TEXT_AREA
			l_block: TUI_BLOCK
			l_foot, l_status: TUI_PARAGRAPH
			l_layout: LAYOUT
			l_chunks: ARRAY [RECT]
			l_cursor: detachable TUPLE [col, row: INTEGER]
		do
			if auto_exit_frames > 0 then
				frame_counter := frame_counter + 1
				if frame_counter >= auto_exit_frames then
					stop
				end
			end
			create l_layout.make_vertical (<<
				{CONSTRAINTS}.flex (1),
				{CONSTRAINTS}.fixed (1),
				{CONSTRAINTS}.fixed (1)
			>>)
			l_chunks := l_layout.split (a_frame.area)
			l_area := l_chunks [1]
			create l_block.make
			l_block := l_block.with_borders ({BORDERS}.all_borders).
				with_title (" Notes ").
				with_border_style (create {STYLE}.make_fg ({COLOR}.Bright_cyan))
			create l_widget.make
			l_widget := l_widget.with_block (l_block).with_shows_cursor (True).
				with_wrap_mode ({TEXT_WRAP_MODE}.word).
				with_placeholder ("Start typing...").
				with_hit_id (id_area)
				-- Registers `l_area` under `id_area` in the frame's hit map
			a_frame.render_stateful_widget (l_widget, l_area, area_state)
			l_cursor := l_widget.cursor_screen_position (l_area, area_state)
			if attached l_cursor as c then
				a_frame.set_cursor_position (c.col, c.row)
				-- A bar between characters, as editors show it (DECSCUSR)
				a_frame.set_cursor_shape (l_widget.cursor_shape)
			end
			create l_foot.make (create {TEXT}.make_styled ("Ctrl+A: select all | Ctrl+C: copy | Ctrl+V: paste | Ctrl+Z: undo | Ctrl+Y: redo | Esc: quit", create {STYLE}.make_fg ({COLOR}.Dark_gray)))
			a_frame.render_widget (l_foot, l_chunks [2])
			create l_status.make (create {TEXT}.make_styled (status, create {STYLE}.make_fg ({COLOR}.Bright_green)))
			a_frame.render_widget (l_status, l_chunks [3])
		end

	process (a_event: EVENT)
		local
			c: CHARACTER_32
		do
			if not backend.is_bracketed_paste_enabled then
				-- The terminal's own paste then comes as one PASTE_EVENT, not as typed keys
				-- (TUI_APPLICATION turns it on again after a suspend)
				terminal.enable_bracketed_paste
			end
			if attached {CLIPBOARD_EVENT} a_event as l_clip then
				paste_answer (l_clip)
			elseif attached {PASTE_EVENT} a_event as l_paste then
				terminal_paste (l_paste)
			elseif attached {KEY_EVENT} a_event as k and then k.is_press then
				if k.code.is_escape then
					stop
				elseif k.code.is_enter then
					area_state.insert_newline
				elseif k.modifiers.is_control and then k.code.is_char and then (k.code.character = 'a' or k.code.character = 'A') then
					area_state.select_all
				elseif k.modifiers.is_control and then k.code.is_char and then (k.code.character = 'c' or k.code.character = 'C') then
					copy_selection
				elseif k.modifiers.is_control and then k.code.is_char and then (k.code.character = 'v' or k.code.character = 'V') then
					paste_from_clipboard
				elseif k.modifiers.is_control and then k.code.is_char and then (k.code.character = 'z' or k.code.character = 'Z') then
					-- Ctrl+Shift+Z redoes where the terminal reports Shift (Kitty protocol, Windows)
					if k.modifiers.is_shift then
						area_state.redo
					else
						area_state.undo
					end
				elseif k.modifiers.is_control and then k.code.is_char and then (k.code.character = 'y' or k.code.character = 'Y') then
					area_state.redo
				elseif k.code.is_backspace then
					area_state.delete_backward
				elseif k.code.is_delete then
					area_state.delete_forward
				elseif k.code.is_left then
					area_state.move_cursor_left (k.modifiers.is_shift)
				elseif k.code.is_right then
					area_state.move_cursor_right (k.modifiers.is_shift)
				elseif k.code.is_up then
					area_state.move_cursor_up (k.modifiers.is_shift)
				elseif k.code.is_down then
					area_state.move_cursor_down (k.modifiers.is_shift)
				elseif k.code.is_home then
					area_state.move_cursor_home (k.modifiers.is_shift)
				elseif k.code.is_end then
					area_state.move_cursor_end (k.modifiers.is_shift)
				elseif k.code.is_char and then not k.modifiers.is_control then
					c := k.code.character
					if c >= ' ' and c /= '%/127/' then
						area_state.insert_character (c)
					end
				end
			end
		end

feature {NONE} -- Clipboard

	Reading_message: STRING_32
			-- Status line while a clipboard read is pending
		once
			Result := {STRING_32} "Reading clipboard%/0x2026/"
		end

	Unreadable_message: STRING_32
			-- Status line when the clipboard could not be read
		once
			Result := {STRING_32} "Clipboard not readable here: use your terminal's paste (Ctrl+Shift+V)"
		end

	paste_from_clipboard
			-- Ask for the clipboard's text (Ctrl+V). The answer comes to `process' as a
			-- CLIPBOARD_EVENT (`paste_answer'); a Ctrl+V while a read is pending is ignored.
		do
			read_clipboard
			status := Reading_message
		ensure
			reading: is_clipboard_read_pending
		end

	paste_answer (a_answer: CLIPBOARD_EVENT)
			-- Insert the text of `a_answer', sanitised by `area_state', as one undo step, or say
			-- that the clipboard could not be read.
		require
			answer_attached: a_answer /= Void
		local
			l_text: STRING_32
		do
			if a_answer.has_text then
				l_text := {TEXT_AREA_STATE}.sanitize (a_answer.text)
				if l_text.is_empty then
					status := {STRING_32} "Clipboard holds no text: nothing pasted."
				else
					area_state.insert_string (l_text)
					status := {STRING_32} "Pasted " + l_text.count.out + " characters from the clipboard."
				end
			else
				status := Unreadable_message
			end
		end

	terminal_paste_count: INTEGER
			-- Characters inserted so far by a terminal paste whose last part has not come

	terminal_paste (a_paste: PASTE_EVENT)
			-- Insert the text of a bracketed paste (the terminal's own paste key), sanitised
			-- by `area_state'. A long paste comes in parts (`is_continued'), each one undo step;
			-- the status line counts them all once the last part has come.
		require
			paste_attached: a_paste /= Void
		local
			l_text: STRING_32
		do
			l_text := {TEXT_AREA_STATE}.sanitize (a_paste.text)
			if not l_text.is_empty then
				area_state.insert_string (l_text)
			end
			terminal_paste_count := terminal_paste_count + l_text.count
			if a_paste.is_continued then
				status := {STRING_32} "Pasting%/0x2026/"
			else
				status := {STRING_32} "Pasted " + terminal_paste_count.out + " characters (terminal paste)."
				terminal_paste_count := 0
			end
		end

	copy_selection
			-- Copy the selection to the clipboard (OSC 52, sent with the next frame), cut at a
			-- grapheme boundary when it is over the terminal's limit, and say so in `status`.
		local
			l_text, l_copied: STRING_32
		do
			l_text := area_state.selected_text
			if l_text.is_empty then
				status := {STRING_32} "Nothing selected: nothing copied."
			else
				l_copied := terminal.clipboard_prefix (l_text)
				if l_copied.is_empty then
					-- Not even the first character fits: an empty copy would clear the
					-- clipboard (xterm), so send nothing
					status := {STRING_32} "Selection too long: nothing copied."
				else
					terminal.copy_to_clipboard (l_copied)
					if l_copied.count = l_text.count then
						status := {STRING_32} "Copied " + l_copied.count.out + " characters."
					else
						status := {STRING_32} "Selection too long: copied the first " + l_copied.count.out
							+ " of " + l_text.count.out + " characters."
					end
				end
			end
		end

end
