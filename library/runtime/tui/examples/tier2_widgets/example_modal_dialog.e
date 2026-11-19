note
	description: "[
		Tier 2 Widget Specialist Example: Modal Dialog (mouse + keyboard).
		A file list with Delete / Help / Quit buttons. Delete opens a TUI_DIALOG confirmation
		(P2b U3): a DIALOG_STATE made by `make_confirm` and given the focus manager, so that
		`open` pushes a modal focus scope, which traps Tab inside the dialog and makes the
		rendered dialog block clicks on everything behind it. While it is open, keys go to
		`handle_key` (Tab / Left / Right, Enter / Space, Esc = No, y / n) and clicks to
		`click`; its `answered_action` deletes the file or keeps it.
		Help opens a non-modal TUI_POPUP hint: the background stays clickable, and its
		Dismiss button is the popup's `inner_widget`, registered for clicks by the popup.
		Clicks on the background go through `hit_test` and FOCUS_MANAGER.focus_at.
		The confirmation casts the dialog's dimmed shadow (SHADOW with DIMMED_EFFECT): the
		files under it stay readable, and clicks on it hit nothing while the dialog is open.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	EXAMPLE_MODAL_DIALOG

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
			-- Initialize and launch the Modal Dialog example.
		local
			l_args: ARGUMENTS_32
			i: INTEGER
		do
			init_state
			Precursor
			confirm.set_answered_action (agent on_confirm_answered)
			set_mouse_capture (True)
			create l_args
			auto_exit_frames := -1
			from i := 1 until i > l_args.argument_count loop
				if l_args.argument (i).is_equal ("-batch") then
					auto_exit_frames := 2
				end
				i := i + 1
			end
			run
		end

	make_batch (a_frames: INTEGER)
			-- Initialize and run for `a_frames` frames.
		do
			init_state
			make_with_viewport (create {VIEWPORT}.make_fullscreen)
			confirm.set_answered_action (agent on_confirm_answered)
			set_mouse_capture (True)
			auto_exit_frames := a_frames
			run
		end

	make_on (a_terminal: TERMINAL [ANSI_TERMINAL_BACKEND])
			-- Initialize on `a_terminal` without running (for scripted tests).
		require
			terminal_attached: a_terminal /= Void
		do
			init_state
			make_with_terminal (a_terminal)
			confirm.set_answered_action (agent on_confirm_answered)
			set_mouse_capture (True)
			auto_exit_frames := -1
		ensure
			not_running: not is_running
		end

feature {NONE} -- Setup

	init_state
			-- Files, ids, focus ring and the confirmation dialog.
		local
			i: INTEGER
		do
			create files.make (3)
			files.extend ({STRING_32} "report.txt")
			files.extend ({STRING_32} "notes.md")
			files.extend ({STRING_32} "todo.e")
			create file_ids.make (3)
			create focus_manager.make
			from i := 1 until i > files.count loop
				file_ids.extend (create {WIDGET_ID}.make (i))
				focus_manager.register (file_ids [i])
				i := i + 1
			end
			create id_delete.make (11)
			create id_help.make (12)
			create id_quit.make (13)
			create id_dismiss.make (31)
			focus_manager.register (id_delete)
			focus_manager.register (id_help)
			focus_manager.register (id_quit)
			selected_index := 1
			create confirm.make_confirm
			confirm.set_focus_manager (focus_manager)
			create status.make_from_string_general ("Click a file, then Delete. Clicks behind the dialog are blocked.")
			frame_counter := 0
		end

feature {NONE} -- State

	files: ARRAYED_LIST [STRING_32]
			-- File names still listed

	file_ids: ARRAYED_LIST [WIDGET_ID]
			-- Hit / focus id of each entry of `files`

	selected_index: INTEGER
			-- Index in `files` of the file Delete acts on; 0 if none

	id_delete, id_help, id_quit: WIDGET_ID
			-- Background buttons

	id_dismiss: WIDGET_ID
			-- Dismiss button of the hint popup (its `inner_widget`)

	focus_manager: FOCUS_MANAGER
			-- Tab order; the dialog pushes its modal scope on it while open

	confirm: DIALOG_STATE
			-- Confirmation dialog (Yes / No; No by default and on Esc), kept across frames:
			-- its open state, focus scope and answer live in it

	is_hint_open: BOOLEAN
			-- Is the non-modal hint popup shown?

	blocked_clicks: INTEGER
			-- Clicks that the modal dialog kept from reaching the background

	status: STRING_32
			-- Message on the bottom row

	auto_exit_frames: INTEGER
			-- Auto-exit in batch mode (-1 = interactive)

	frame_counter: INTEGER
			-- Rendered frame count

feature {NONE} -- Application Hooks

	render (a_frame: FRAME)
			-- Background (title, files, buttons, status), then the hint, then the dialog.
		local
			l_area: RECT
			l_button: TUI_BUTTON
			l_para: TUI_PARAGRAPH
			l_block: TUI_BLOCK
			l_popup: TUI_POPUP
			l_x, l_y: INTEGER
			i: INTEGER
		do
			if auto_exit_frames > 0 then
				frame_counter := frame_counter + 1
				if frame_counter >= auto_exit_frames then
					stop
				end
			end
			l_area := a_frame.area

			create l_para.make (create {TEXT}.make_styled ("Click or Tab: focus | Enter: press | d: delete | h: hint | q: quit",
				create {STYLE}.make_fg ({COLOR}.Bright_cyan)))
			a_frame.render_widget (l_para, clipped (0, 0, l_area.width.to_integer_32, 1, l_area))

				-- Files, one clickable row each; the selected one is marked
			from i := 1 until i > files.count loop
				if i = selected_index then
					l_button := new_button ({STRING_32} "> " + files [i])
				else
					l_button := new_button (files [i])
				end
				render_button_widget (a_frame, l_button.with_focused (focus_manager.is_focused (file_ids [i])),
					file_ids [i], clipped (2, 1 + i, 24, 1, l_area))
				i := i + 1
			end

			render_button (a_frame, "Delete", id_delete, clipped (2, 6, 12, 1, l_area))
			render_button (a_frame, "Help", id_help, clipped (16, 6, 10, 1, l_area))
			render_button (a_frame, "Quit", id_quit, clipped (28, 6, 10, 1, l_area))

			create l_para.make (create {TEXT}.make_styled (status, create {STYLE}.make_fg ({COLOR}.Bright_green)))
			a_frame.render_widget (l_para, clipped (0, l_area.height.to_integer_32 - 1, l_area.width.to_integer_32, 1, l_area))

				-- Non-modal hint: never begins a modal scope, so it blocks nothing. Its
				-- Dismiss button is the popup's inner widget; the popup registers its hit id.
			if is_hint_open then
				create l_popup.make
				create l_block.make
				l_button := new_button ("Dismiss")
				l_popup := l_popup.with_block (l_block.with_borders ({BORDERS}.all_borders).
						with_border_style (create {STYLE}.make_fg ({COLOR}.Bright_blue)).
						with_title (" Tip: files are clickable ")).
					with_inner_widget (l_button.with_hit_id (id_dismiss))
				l_x := (l_area.width.to_integer_32 - 42).max (0)
				l_y := (l_area.height.to_integer_32 - 6).max (0)
				a_frame.render_widget (l_popup, clipped (l_x, l_y, 40, 4, l_area))
			end

				-- Confirmation, rendered last into the whole frame: while `confirm` is open its
				-- popup blocks every region registered above, and Yes / No are registered
				-- after it (closed, the dialog draws and registers nothing).
			if confirm.is_open then
				a_frame.render_stateful_widget ((create {TUI_DIALOG}).with_title (" Confirm ")
						.with_message (confirm_message)
						.with_border_type ({BORDER_TYPE}.double)
						.with_kind ({DIALOG_KIND}.warning)
						.with_kind_style ({DIALOG_KIND}.warning, create {STYLE}.make_fg ({COLOR}.Bright_yellow))
						.with_button_style (create {STYLE}.make_fg ({COLOR}.Bright_white))
						.with_focused_button_style ((create {STYLE}.make_with_colors ({COLOR}.Black, {COLOR}.Bright_yellow)).with_bold),
					l_area, confirm)
			end
		end

	process (a_event: EVENT)
			-- While the dialog is open, every key goes to its `handle_key` and every click to
			-- its `click` (a click beside Yes / No is counted as blocked). Otherwise mouse:
			-- `hit_test`, then `focus_at`, and a click on a button presses it; keys: Tab,
			-- Enter, and the shortcuts of the title row.
		local
			l_hit: detachable WIDGET_ID
			l_used: BOOLEAN
		do
			if attached {MOUSE_EVENT} a_event as m and then m.is_down then
				l_hit := hit_test (m)
				if confirm.handles (l_hit) then
					if confirm.index_of_id (l_hit) = 0 then
						blocked_clicks := blocked_clicks + 1
						set_status ("The dialog is modal: answer Yes or No first.")
					end
					confirm.click (l_hit)
				elseif focus_manager.focus_at (l_hit) then
					press_focused
				elseif attached l_hit as l_id and then l_id ~ id_dismiss then
					is_hint_open := False
					set_status ("Hint dismissed.")
				end
			elseif attached {KEY_EVENT} a_event as k and then k.is_press then
				if confirm.is_open then
						-- Keys the dialog does not use are swallowed while it is open
					l_used := confirm.handle_key (k)
				elseif k.code.is_tab then
					focus_manager.focus_next
				elseif k.code.is_back_tab then
					focus_manager.focus_previous
				elseif k.code.is_enter then
					press_focused
				elseif k.code.is_escape or else (k.code.is_char and then k.code.character.as_lower = 'q') then
					stop
				elseif k.code.is_char and then k.code.character.as_lower = 'd' then
					open_confirm
				elseif k.code.is_char and then k.code.character.as_lower = 'h' then
					is_hint_open := not is_hint_open
				end
			end
			sync_selection
		end

feature {NONE} -- Actions

	press_focused
			-- Act on the focused background control, as a click on it does.
		do
			if attached focus_manager.focused_id as l_id then
				if l_id ~ id_delete then
					open_confirm
				elseif l_id ~ id_help then
					is_hint_open := not is_hint_open
				elseif l_id ~ id_quit then
					stop
				end
			end
		end

	open_confirm
			-- Ask whether to delete the selected file (No focused first).
		do
			if confirm.is_open then
				-- Already asking
			elseif selected_index = 0 then
				set_status ("No file selected.")
			else
				confirm.open
				set_status ({STRING_32} "Delete " + files [selected_index] + "? Tab / click Yes or No.")
			end
		ensure
			asking: old selected_index > 0 implies confirm.is_open
		end

	on_confirm_answered (a_answer: INTEGER)
			-- `confirm` was answered with button `a_answer`, its focus scope already popped:
			-- delete the selected file on Yes (1), keep it on No (2).
		require
			answered: not confirm.is_open
			file_selected: selected_index > 0
		local
			l_name: STRING_32
			l_id: WIDGET_ID
		do
			l_name := files [selected_index]
			if a_answer = 1 then
				l_id := file_ids [selected_index]
				focus_manager.unregister (l_id)
				files.go_i_th (selected_index)
				files.remove
				file_ids.go_i_th (selected_index)
				file_ids.remove
				selected_index := selected_index.min (files.count)
				set_status ({STRING_32} "Deleted " + l_name + ".")
			else
				set_status ({STRING_32} "Kept " + l_name + ".")
			end
		ensure
			deleted: a_answer = 1 implies files.count = old files.count - 1
			kept: a_answer /= 1 implies files.count = old files.count
		end

	confirm_message: TEXT
			-- `Delete "<file>"?' and `This cannot be undone.', in white, for the selected file
		require
			file_selected: selected_index > 0
		local
			l_message: STRING_32
		do
			create l_message.make_from_string_general ("Delete %"")
			l_message.append (files [selected_index])
			l_message.append_string_general ("%"?%NThis cannot be undone.")
			create Result.make_styled (l_message, create {STYLE}.make_fg ({COLOR}.White))
		ensure
			result_not_void: Result /= Void
		end

	sync_selection
			-- Select the focused file, if a file is focused.
		local
			i: INTEGER
		do
			from i := 1 until i > file_ids.count loop
				if focus_manager.is_focused (file_ids [i]) then
					selected_index := i
				end
				i := i + 1
			end
		end

	set_status (a_text: READABLE_STRING_GENERAL)
			-- Show `a_text` on the status row.
		do
			create status.make_from_string_general (a_text)
		end

feature {NONE} -- Drawing helpers

	render_button (a_frame: FRAME; a_label: STRING; a_id: WIDGET_ID; a_rect: RECT)
			-- Render a button labelled `a_label` for `a_id` on `a_rect` (see `render_button_widget`).
		do
			render_button_widget (a_frame, new_button (a_label).with_focused (focus_manager.is_focused (a_id)), a_id, a_rect)
		end

	new_button (a_label: READABLE_STRING_GENERAL): TUI_BUTTON
			-- "[ label ]" in bright white, black on bright yellow and bold when focused; the
			-- style covers the brackets and the label only (`with_fill (False)`).
		do
			Result := (create {TUI_BUTTON}.make (a_label))
				.with_fill (False)
				.with_style (create {STYLE}.make_fg ({COLOR}.Bright_white))
				.with_focused_style ((create {STYLE}.make_with_colors ({COLOR}.Black, {COLOR}.Bright_yellow)).with_bold)
		ensure
			result_not_void: Result /= Void
		end

	render_button_widget (a_frame: FRAME; a_button: TUI_BUTTON; a_id: WIDGET_ID; a_rect: RECT)
			-- Render `a_button` into `a_rect` under `a_id`: a click anywhere in `a_rect`, also
			-- beside the label, hits it.
		do
			a_frame.render_widget (a_button.with_hit_id (a_id), a_rect)
		end

	clipped (a_x, a_y, a_width, a_height: INTEGER; a_area: RECT): RECT
			-- (`a_x`, `a_y`, `a_width`, `a_height`) cut to `a_area` (empty when outside it).
		local
			l_x, l_y, l_w, l_h: INTEGER
		do
			l_x := a_x.max (0).min (a_area.width.to_integer_32)
			l_y := a_y.max (0).min (a_area.height.to_integer_32)
			l_w := (a_x + a_width).min (a_area.width.to_integer_32) - l_x
			l_h := (a_y + a_height).min (a_area.height.to_integer_32) - l_y
			create Result.make (l_x.to_natural_16, l_y.to_natural_16, l_w.max (0).to_natural_16, l_h.max (0).to_natural_16)
		ensure
			inside: Result.x.to_integer_32 + Result.width.to_integer_32 <= a_area.width.to_integer_32
				and Result.y.to_integer_32 + Result.height.to_integer_32 <= a_area.height.to_integer_32
		end

invariant
	parallel_ids: files.count = file_ids.count
	selection_valid: selected_index >= 0 and selected_index <= files.count

end
