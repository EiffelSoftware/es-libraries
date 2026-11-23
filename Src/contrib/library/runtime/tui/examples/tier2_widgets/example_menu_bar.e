note
	description: "[
		Tier 2 Widget Specialist Example: Menu Bar (P2 W4).
		Demonstrates TUI_MENU + MENU_STATE: a menu bar with drop-downs, separators, a disabled
		item, shortcut texts and a sub-menu, over a small editor panel with two checkboxes on a
		FOCUS_MANAGER ring.

		  * F10 opens or closes the menu; Alt+F / Alt+E / Alt+V / Alt+H open an entry (where
		    the terminal sends Alt as ESC + letter).
		  * In the menu: the arrows move (separators and the disabled item are skipped; Left /
		    Right go in and out of the sub-menu and across the bar), Enter chooses, Esc closes
		    one level. Every other key, Tab included, is swallowed while the menu is open: the
		    menu's focus scope (MENU_STATE.set_focus_manager) traps it.
		  * A click on a bar entry opens it (again: closes it), on an item chooses it, and
		    anywhere else closes the menu without reaching the panel below.
		  * With the menu closed: Tab / Shift+Tab move the focus, Space or a click toggles a
		    checkbox, q or Esc asks to quit (the same confirmation as File > Quit).

		File > Quit asks first (P2b U3): it opens a TUI_DIALOG confirmation ("Quit?", a
		DIALOG_STATE made by `make_confirm` on the same focus manager), whose Yes stops the
		application and whose No / Esc keeps it running. The menu has closed, and popped its
		focus scope, when the command runs, so the dialog's scope is pushed in its place.
		While the dialog is open it takes every key (`handle_key`: Tab / Left / Right,
		Enter / Space, Esc, y / n) and every click (`click`); the menu and the panel get none.
		View > Wrap lines / Line numbers toggle the checkboxes, and every command is shown on
		the status line. The menu is rendered over the panel, and the dialog last, over both.

		Edit > Paste reads the clipboard (P2b K6, {TUI_APPLICATION}.read_clipboard): the status
		line says "Paste: reading clipboard..." until the answer, a CLIPBOARD_EVENT, reaches
		`process'. Its first line (sanitised as TEXT_AREA_STATE.sanitize does, cut to
		`Toast_text_limit' characters) is shown in a success toast; an empty clipboard gives an
		info toast, and any other answer (no reply within the timeout, a reply too large or not
		valid) a warning toast pointing to the terminal's own paste key. On Windows the console
		driver reads the system clipboard itself (P2b K4); elsewhere most terminals do not
		answer an OSC 52 read (see the TUI_APPLICATION class note). The toasts (TOAST_QUEUE,
		expired on each tick by the monotonic clock) sit at the panel's bottom right, under the
		menu and the dialog; a click on one dismisses it. Ticks and the clipboard's answer are
		handled whatever is open, so an answer that comes while the menu or the dialog is open
		is not lost.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	EXAMPLE_MENU_BAR

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
			-- Initialize and launch the menu bar example.
		local
			l_args: ARGUMENTS_32
			i: INTEGER
		do
			init_menu
			Precursor
			quit_dialog.set_answered_action (agent on_quit_answered)
			set_mouse_capture (True)
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
			-- Initialize and run for `a_frames` frames.
		do
			init_menu
			make_with_viewport (create {VIEWPORT}.make_fullscreen)
			quit_dialog.set_answered_action (agent on_quit_answered)
			set_mouse_capture (True)
			auto_exit_frames := a_frames
			frame_counter := 0
			run
		end

	make_on (a_terminal: TERMINAL [ANSI_TERMINAL_BACKEND])
			-- Initialize on `a_terminal` without running (for snapshot tests).
		require
			terminal_attached: a_terminal /= Void
		do
			init_menu
			make_with_terminal (a_terminal)
			quit_dialog.set_answered_action (agent on_quit_answered)
			set_mouse_capture (True)
			auto_exit_frames := -1
			frame_counter := 0
		ensure
			not_running: not is_running
		end

feature {NONE} -- Setup

	init_menu
			-- Build the menu, the panel's values and the focus ring.
		do
			options := <<True, False>>
			create last_command.make_from_string ("(none)")
			create focus_manager.make
			create id_wrap.make (1)
			create id_numbers.make (2)
			focus_manager.register (id_wrap)
			focus_manager.register (id_numbers)
			create menu.make (<<
				(create {MENU_ITEM}.make_submenu ("File", <<
					(create {MENU_ITEM}.make ("New")).with_shortcut ("Ctrl+N").with_id (create {WIDGET_ID}.make (Cmd_new)),
					(create {MENU_ITEM}.make ("Open...")).with_shortcut ("Ctrl+O").with_id (create {WIDGET_ID}.make (Cmd_open)),
					create {MENU_ITEM}.make_separator,
					create {MENU_ITEM}.make_submenu ("Recent", <<
						(create {MENU_ITEM}.make ("notes.txt")).with_id (create {WIDGET_ID}.make (Cmd_recent_1)),
						(create {MENU_ITEM}.make ("todo.txt")).with_id (create {WIDGET_ID}.make (Cmd_recent_2))>>),
					(create {MENU_ITEM}.make ("Save")).with_shortcut ("Ctrl+S").with_enabled (False)
						.with_id (create {WIDGET_ID}.make (Cmd_save)),
					create {MENU_ITEM}.make_separator,
					(create {MENU_ITEM}.make ("Quit")).with_shortcut ("Ctrl+Q").with_id (create {WIDGET_ID}.make (Cmd_quit))>>))
					.with_id (create {WIDGET_ID}.make (Entry_file)),
				(create {MENU_ITEM}.make_submenu ("Edit", <<
					(create {MENU_ITEM}.make ("Undo")).with_shortcut ("Ctrl+Z").with_id (create {WIDGET_ID}.make (Cmd_undo)),
					(create {MENU_ITEM}.make ("Redo")).with_enabled (False).with_id (create {WIDGET_ID}.make (Cmd_redo)),
					create {MENU_ITEM}.make_separator,
					(create {MENU_ITEM}.make ("Copy")).with_id (create {WIDGET_ID}.make (Cmd_copy)),
					(create {MENU_ITEM}.make ("Paste")).with_id (create {WIDGET_ID}.make (Cmd_paste))>>))
					.with_id (create {WIDGET_ID}.make (Entry_edit)),
				(create {MENU_ITEM}.make_submenu ("View", <<
					(create {MENU_ITEM}.make ("Wrap lines")).with_id (create {WIDGET_ID}.make (Cmd_wrap)),
					(create {MENU_ITEM}.make ("Line numbers")).with_id (create {WIDGET_ID}.make (Cmd_numbers))>>))
					.with_id (create {WIDGET_ID}.make (Entry_view)),
				(create {MENU_ITEM}.make_submenu ("Help", <<
					(create {MENU_ITEM}.make ("About")).with_id (create {WIDGET_ID}.make (Cmd_about))>>))
					.with_id (create {WIDGET_ID}.make (Entry_help))>>)
			menu.set_menu_id (create {WIDGET_ID}.make (Menu_surface))
			menu.set_focus_manager (focus_manager)
			create toasts.make_at ({MONOTONIC_CLOCK}.milliseconds)
			create quit_dialog.make_confirm
			quit_dialog.set_focus_manager (focus_manager)
		end

feature -- Access

	menu: MENU_STATE
			-- The menu's items and open path

	quit_dialog: DIALOG_STATE
			-- "Quit?" confirmation opened by File > Quit (Yes / No; No by default and on Esc)

	toasts: TOAST_QUEUE
			-- Toasts over the panel (Edit > Paste shows the clipboard's first line in one)

	options: ARRAY [BOOLEAN]
			-- Values of the two checkboxes: wrap lines, line numbers

	last_command: STRING_32
			-- Label of the last command chosen

	focus_manager: FOCUS_MANAGER
			-- Tab order of the two checkboxes (the menu pushes a scope on it while open)

	Option_labels: ARRAY [STRING_32]
			-- Labels of the checkboxes
		once
			Result := <<{STRING_32} "Wrap lines", {STRING_32} "Show line numbers">>
		end

feature -- Commands

	Entry_file: INTEGER = 11
	Entry_edit: INTEGER = 12
	Entry_view: INTEGER = 13
	Entry_help: INTEGER = 14
			-- Ids of the bar entries (the checkboxes have 1 and 2: ids must not clash)

	Cmd_new: INTEGER = 21
	Cmd_open: INTEGER = 22
	Cmd_recent_1: INTEGER = 23
	Cmd_recent_2: INTEGER = 24
	Cmd_save: INTEGER = 25
	Cmd_quit: INTEGER = 26
	Cmd_undo: INTEGER = 27
	Cmd_redo: INTEGER = 28
	Cmd_copy: INTEGER = 29
	Cmd_paste: INTEGER = 30
	Cmd_wrap: INTEGER = 31
	Cmd_numbers: INTEGER = 32
	Cmd_about: INTEGER = 33
			-- Ids of the commands

	Menu_surface: INTEGER = 100
			-- Id of the menu's own surface (border, separators, the bar's blanks)

	Toast_id_base: INTEGER = 1000
			-- A toast's box is registered under `Toast_id_base' + its id (above every other id)

	Toast_duration_ms: INTEGER = 4000
			-- How long a toast is shown

	Toast_text_limit: INTEGER = 40
			-- Characters of the clipboard's first line shown in the paste toast

	Unreadable_message: STRING_32
			-- Toast when the clipboard could not be read
		once
			Result := {STRING_32} "Clipboard not readable here: use your terminal's paste (Ctrl+Shift+V)"
		end

feature {NONE} -- State

	id_wrap, id_numbers: WIDGET_ID
			-- Ids of the checkboxes

	auto_exit_frames: INTEGER
			-- Auto-exit in batch mode

	frame_counter: INTEGER
			-- Rendered frame count

	clock_ms: INTEGER_64
			-- The toasts' clock
		do
			Result := {MONOTONIC_CLOCK}.milliseconds
		end

feature {NONE} -- Application Hooks

	render (a_frame: FRAME)
			-- Draw the panel, then the menu over it, then the quit confirmation over both.
		local
			l_panel, l_inner: RECT
			l_ids: ARRAY [WIDGET_ID]
			i: INTEGER
		do
			if auto_exit_frames > 0 then
				frame_counter := frame_counter + 1
				if frame_counter >= auto_exit_frames then
					stop
				end
			end
			if a_frame.area.height > 1 then
				create l_panel.make (0, 1, a_frame.area.width, a_frame.area.height - 1)
				a_frame.render_widget ((create {TUI_BLOCK}.make).with_border_type ({BORDER_TYPE}.rounded)
					.with_title (" Editor "), l_panel)
				l_inner := l_panel.inner (1, 1)
				l_ids := <<id_wrap, id_numbers>>
				from i := 1 until i > 2 loop
					if l_inner.height.to_integer_32 > i then
						a_frame.render_widget ((create {TUI_CHECKBOX}.make (Option_labels [i]))
								.with_checked (options [i])
								.with_focused (focus_manager.is_focused (l_ids [i]))
								.with_hit_id (l_ids [i]),
							create {RECT}.make (l_inner.x, l_inner.y + i.to_natural_16, l_inner.width, 1))
					end
					i := i + 1
				end
				if l_inner.height > 4 then
					a_frame.render_widget (create {TUI_PARAGRAPH}.make_raw ({STRING_32} "Last command: " + last_command),
						create {RECT}.make (l_inner.x, l_inner.y + 4, l_inner.width, 1))
				end
				if l_inner.height > 6 then
					a_frame.render_widget (create {TUI_PARAGRAPH}.make_raw ("F10/Alt+F: menu  Tab, Space, click  q: quit"),
						create {RECT}.make (l_inner.x, l_inner.y + 6, l_inner.width, 1))
				end
					-- The toasts over the panel's inside, at its bottom right; a click dismisses one
				a_frame.render_stateful_widget ((create {TUI_TOAST})
						.with_position ({TOAST_POSITION}.bottom_right).with_max_width (36)
						.with_border_type ({BORDER_TYPE}.rounded).with_hit_id_base (Toast_id_base),
					l_inner, toasts)
			end
				-- The menu over the panel: its drop-downs cover it, and its hit regions sit above it
			a_frame.render_stateful_widget ((create {TUI_MENU}).with_shadow (create {SHADOW}.make_light_shade),
				a_frame.area, menu)
				-- The confirmation last (it draws nothing while closed): open, it blocks every
				-- region registered above
			a_frame.render_stateful_widget ((create {TUI_DIALOG}).with_title (" Quit ")
					.with_message (create {TEXT}.make_raw ("Quit?"))
					.with_kind ({DIALOG_KIND}.question),
				a_frame.area, quit_dialog)
		end

	process (a_event: EVENT)
			-- Ticks expire the toasts and the clipboard's answer is shown, whatever is open.
			-- Keys and clicks go to the quit confirmation while it is open; else to the menu
			-- while it is open (or when they open it); else to a toast or the panel.
		local
			l_hit: detachable WIDGET_ID
			l_used: BOOLEAN
		do
			if a_event.is_tick then
				toasts.expire (clock_ms.max (toasts.now_ms))
			elseif attached {CLIPBOARD_EVENT} a_event as l_clip then
				paste_answer (l_clip)
			elseif quit_dialog.is_open then
				if attached {KEY_EVENT} a_event as k then
						-- Keys the dialog does not use are swallowed while it is open
					l_used := quit_dialog.handle_key (k)
				elseif attached {MOUSE_EVENT} a_event as m and then m.is_down then
					l_hit := hit_test (m)
					if quit_dialog.handles (l_hit) then
						quit_dialog.click (l_hit)
					end
				end
			elseif attached {MOUSE_EVENT} a_event as m then
				if m.is_down then
					l_hit := hit_test (m)
					if menu.handles (l_hit) then
						menu.click (l_hit)
					elseif attached l_hit and then toasts.has_id (l_hit.value - Toast_id_base) then
						toasts.dismiss_id (l_hit.value - Toast_id_base)
					elseif focus_manager.focus_at (l_hit) then
						toggle_focused
					end
				end
			elseif attached {KEY_EVENT} a_event as k and then k.is_press then
				if k.code.is_function and then k.code.function_number = 10 then
					if menu.is_open then
						menu.close
					else
						menu.open
					end
				elseif k.modifiers.is_alt and then k.code.is_char
					and then menu.entry_with_initial (k.code.character) > 0
				then
					menu.open_entry (menu.entry_with_initial (k.code.character))
				elseif menu.is_open then
					if k.code.is_down then
						menu.move_down
					elseif k.code.is_up then
						menu.move_up
					elseif k.code.is_right then
						menu.move_right
					elseif k.code.is_left then
						menu.move_left
					elseif k.code.is_enter then
						menu.activate
					elseif k.code.is_escape then
						menu.close_level
					end
				elseif k.code.is_escape or else (k.code.is_char and then k.code.character = 'q') then
					ask_quit
				elseif k.code.is_tab then
					focus_manager.focus_next
				elseif k.code.is_back_tab then
					focus_manager.focus_previous
				elseif k.code.is_char and then k.code.character = ' ' then
					toggle_focused
				end
			end
			run_chosen
		end

feature {NONE} -- Commands

	run_chosen
			-- Run the command chosen in the menu, if any, and forget it.
		do
			if attached menu.chosen_item as l_item then
				last_command := l_item.label.to_plain_string
				if attached l_item.widget_id as l_id then
					inspect l_id.value
					when Cmd_quit then
						ask_quit
					when Cmd_paste then
						paste_from_clipboard
					when Cmd_wrap then
						options [1] := not options [1]
					when Cmd_numbers then
						options [2] := not options [2]
					else
					end
				end
				menu.clear_chosen
			end
		end

	paste_from_clipboard
			-- Ask for the clipboard's text (Edit > Paste). The answer comes to `process' as a
			-- CLIPBOARD_EVENT (`paste_answer'); a Paste while a read is pending is ignored.
		do
			read_clipboard
			last_command := {STRING_32} "Paste: reading clipboard%/0x2026/"
		ensure
			reading: is_clipboard_read_pending
		end

	paste_answer (a_answer: CLIPBOARD_EVENT)
			-- Show the first line of `a_answer' in a toast, or say that the clipboard could not
			-- be read.
		require
			answer_attached: a_answer /= Void
		local
			l_line: STRING_32
		do
			if a_answer.has_text then
				l_line := first_line (a_answer.text)
				if l_line.is_empty then
					last_command := {STRING_32} "Paste: no text"
					toasts.push ({STRING_32} "Clipboard holds no text.", {TOAST_LEVEL}.info, Toast_duration_ms)
				else
					last_command := {STRING_32} "Paste: " + l_line
					toasts.push ({STRING_32} "Clipboard: " + l_line, {TOAST_LEVEL}.success, Toast_duration_ms)
				end
			else
				last_command := {STRING_32} "Paste: clipboard not readable"
				toasts.push (Unreadable_message, {TOAST_LEVEL}.warning, Toast_duration_ms)
			end
		ensure
			one_toast_more: toasts.count = old toasts.count + 1
		end

	first_line (a_text: READABLE_STRING_GENERAL): STRING_32
			-- The first non-empty line of `a_text', sanitised (TEXT_AREA_STATE.sanitize: TAB
			-- to a blank, CR LF to LF, other controls dropped) and cut to `Toast_text_limit'
			-- characters with a trailing ellipsis.
		local
			l_text: STRING_32
			l_lines: LIST [STRING_32]
		do
			l_text := {TEXT_AREA_STATE}.sanitize (a_text)
			create Result.make_empty
			l_lines := l_text.split ('%N')
			from
				l_lines.start
			until
				l_lines.after or else not Result.is_empty
			loop
				Result := l_lines.item
				Result.adjust
				l_lines.forth
			end
			if Result.count > Toast_text_limit then
				Result := Result.substring (1, Toast_text_limit - 1)
				Result.append_character ('%/0x2026/')
			end
		ensure
			no_line_break: not Result.has ('%N')
			short: Result.count <= Toast_text_limit
		end

	ask_quit
			-- Open the quit confirmation. The menu that chose File > Quit has closed by now and
			-- popped its focus scope, so the dialog's scope is the innermost one.
		require
			menu_closed: not menu.is_open
		do
			if not quit_dialog.is_open then
				quit_dialog.open
			end
		ensure
			asking: quit_dialog.is_open
		end

	on_quit_answered (a_answer: INTEGER)
			-- `quit_dialog` was answered with button `a_answer`: stop on Yes (1); No (2) and Esc
			-- keep running.
		do
			if a_answer = 1 then
				last_command := {STRING_32} "Quit: yes"
				stop
			else
				last_command := {STRING_32} "Quit: no"
			end
		end

	toggle_focused
			-- Toggle the focused checkbox.
		do
			if focus_manager.is_focused (id_wrap) then
				options [1] := not options [1]
			elseif focus_manager.is_focused (id_numbers) then
				options [2] := not options [2]
			end
		end

end
