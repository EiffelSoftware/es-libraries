note
	description: "[
		Tier 2 Widget Specialist Example: Input Form (Ratatui 1-to-1).
		Demonstrates FOCUS_MANAGER Tab order, HIT_MAP mouse selection,
		TUI_TEXT_INPUT fields, numeric age validation, and form submission.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	EXAMPLE_INPUT_FORM

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
			-- Initialize and launch Input Form example.
		local
			l_args: ARGUMENTS_32
			i: INTEGER
		do
			init_form
			Precursor
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
			init_form
			make_with_viewport (create {VIEWPORT}.make_fullscreen)
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
			init_form
			make_with_terminal (a_terminal)
			set_mouse_capture (True)
			auto_exit_frames := -1
			frame_counter := 0
		ensure
			not_running: not is_running
		end

feature {NONE} -- Setup

	init_form
			-- Initialize form state and focus ring.
		do
			create first_name_state.make_with_text ("Ada")
			create last_name_state.make_with_text ("Lovelace")
			age := 36
			create focus_manager.make
			create id_first.make (1)
			create id_last.make (2)
			create id_age.make (3)
			focus_manager.register (id_first)
			focus_manager.register (id_last)
			focus_manager.register (id_age)
			is_submitted := False
		end

feature {NONE} -- State

	focus_manager: FOCUS_MANAGER
			-- Tab order and modal scopes for this form

	id_first, id_last, id_age: WIDGET_ID
			-- Stable ids for the three fields

	first_name_state: TEXT_INPUT_STATE
			-- First name field state

	last_name_state: TEXT_INPUT_STATE
			-- Last name field state

	age: INTEGER
			-- Value of age field (0..130)

	is_submitted: BOOLEAN
			-- Has the user submitted the form?

	auto_exit_frames: INTEGER
			-- Auto-exit in batch mode

	frame_counter: INTEGER
			-- Rendered frame count

	Max_age: INTEGER = 130
			-- Maximum allowable age value

feature {NONE} -- Application Hooks

	render (a_frame: FRAME)
			-- Render input form dialog with fields and submitted status.
		local
			l_v_layout, l_h_layout, l_form_layout: LAYOUT
			l_v_chunks, l_h_chunks, l_form_chunks: ARRAY [RECT]
			l_dialog_area: RECT
			l_outer_block, l_field_block: TUI_BLOCK
			l_outer_style, l_active_style, l_inactive_style: STYLE
			l_header_para, l_age_para, l_status_para: TUI_PARAGRAPH
			l_fn_input, l_ln_input: TUI_TEXT_INPUT
			l_age_text, l_status_text: STRING_32
			l_instructions: STRING_32
			l_cursor: detachable TUPLE [col, row: INTEGER]
		do
			if auto_exit_frames > 0 then
				frame_counter := frame_counter + 1
				if frame_counter >= auto_exit_frames then
					stop
				end
			end

			create l_v_layout.make_vertical (<<
				{CONSTRAINTS}.flex (1),
				{CONSTRAINTS}.fixed (18),
				{CONSTRAINTS}.flex (1)
			>>)
			l_v_chunks := l_v_layout.split (a_frame.area)

			create l_h_layout.make_horizontal (<<
				{CONSTRAINTS}.flex (1),
				{CONSTRAINTS}.fixed (64),
				{CONSTRAINTS}.flex (1)
			>>)
			l_h_chunks := l_h_layout.split (l_v_chunks [2])
			l_dialog_area := l_h_chunks [2]

			create l_outer_style.make_fg ({COLOR}.Bright_cyan)
			create l_outer_block.make
			l_outer_block := l_outer_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (l_outer_style).
				with_title (" User Profile Form ").
				with_title_alignment ({TEXT_ALIGNMENT}.center)

			create l_form_layout.make_vertical (<<
				{CONSTRAINTS}.fixed (2),
				{CONSTRAINTS}.fixed (3),
				{CONSTRAINTS}.fixed (3),
				{CONSTRAINTS}.fixed (3),
				{CONSTRAINTS}.flex (1)
			>>)
			l_form_chunks := l_form_layout.split (l_dialog_area.inner (1, 1))

			a_frame.render_widget (l_outer_block, l_dialog_area)

			create l_active_style.make_fg ({COLOR}.Bright_yellow)
			create l_inactive_style.make_fg ({COLOR}.Dark_gray)

			create l_instructions.make_from_string_general ("Tab/Shift-Tab/Click: Focus | Enter: Submit | Esc: Exit")
			create l_header_para.make (create {TEXT}.make_styled (l_instructions, create {STYLE}.make_fg ({COLOR}.White)))
			l_header_para := l_header_para.with_alignment ({TEXT_ALIGNMENT}.center)
			a_frame.render_widget (l_header_para, l_form_chunks [1])

			-- First Name
			create l_fn_input.make
			create l_field_block.make
			l_field_block := l_field_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.plain)
			if focus_manager.is_focused (id_first) then
				l_field_block := l_field_block.with_border_style (l_active_style).
					with_title (" First Name [Focused] ")
			else
				l_field_block := l_field_block.with_border_style (l_inactive_style).
					with_title (" First Name ")
			end
			l_fn_input := l_fn_input.with_block (l_field_block).with_shows_cursor (focus_manager.is_focused (id_first)).
				with_hit_id (id_first)
			a_frame.render_stateful_widget (l_fn_input, l_form_chunks [2], first_name_state)
			if focus_manager.is_focused (id_first) then
				l_cursor := l_fn_input.cursor_screen_position (l_form_chunks [2], first_name_state)
				a_frame.set_cursor_shape (l_fn_input.cursor_shape)
			end

			-- Last Name
			create l_ln_input.make
			create l_field_block.make
			l_field_block := l_field_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.plain)
			if focus_manager.is_focused (id_last) then
				l_field_block := l_field_block.with_border_style (l_active_style).
					with_title (" Last Name [Focused] ")
			else
				l_field_block := l_field_block.with_border_style (l_inactive_style).
					with_title (" Last Name ")
			end
			l_ln_input := l_ln_input.with_block (l_field_block).with_shows_cursor (focus_manager.is_focused (id_last)).
				with_hit_id (id_last)
			a_frame.render_stateful_widget (l_ln_input, l_form_chunks [3], last_name_state)
			if focus_manager.is_focused (id_last) then
				l_cursor := l_ln_input.cursor_screen_position (l_form_chunks [3], last_name_state)
				a_frame.set_cursor_shape (l_ln_input.cursor_shape)
			end

			-- Age
			create l_age_text.make (16)
			l_age_text.append_integer (age)
			if focus_manager.is_focused (id_age) then
				l_age_text.append_string_general ("  (Up/Down or Digits, max 130)")
			end
			create l_field_block.make
			l_field_block := l_field_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.plain)
			if focus_manager.is_focused (id_age) then
				l_field_block := l_field_block.with_border_style (l_active_style).
					with_title (" Age [Focused] ")
				create l_age_para.make (create {TEXT}.make_styled (l_age_text, create {STYLE}.make_fg ({COLOR}.Bright_yellow)))
			else
				l_field_block := l_field_block.with_border_style (l_inactive_style).
					with_title (" Age ")
				create l_age_para.make (create {TEXT}.make_styled (l_age_text, create {STYLE}.make_fg ({COLOR}.White)))
			end
			l_age_para := l_age_para.with_block (l_field_block)
			a_frame.render_widget (l_age_para, l_form_chunks [4])
			a_frame.register_hit (id_age, l_form_chunks [4])

			-- Status
			create l_status_text.make (128)
			if is_submitted then
				l_status_text.append_string_general ("SUBMITTED DATA: { first_name: %"")
				l_status_text.append (first_name_state.value)
				l_status_text.append_string_general ("%", last_name: %"")
				l_status_text.append (last_name_state.value)
				l_status_text.append_string_general ("%", age: ")
				l_status_text.append_integer (age)
				l_status_text.append_string_general (" }")
				create l_status_para.make (create {TEXT}.make_styled (l_status_text, (create {STYLE}.make_fg ({COLOR}.Bright_green)).with_bold))
			else
				l_status_text.append_string_general ("Status: Filling form... Press Enter when ready.")
				create l_status_para.make (create {TEXT}.make_styled (l_status_text, create {STYLE}.make_fg ({COLOR}.Dark_gray)))
			end
			l_status_para := l_status_para.with_alignment ({TEXT_ALIGNMENT}.center)
			a_frame.render_widget (l_status_para, l_form_chunks [5])

			if attached l_cursor as c then
				a_frame.set_cursor_position (c.col, c.row)
			end
		end

	process (a_event: EVENT)
			-- Process input according to focused form field.
		local
			c: CHARACTER_32
			l_digit, l_new_age: INTEGER
			l_state: TEXT_INPUT_STATE
			l_clicked: BOOLEAN
		do
			if attached {MOUSE_EVENT} a_event as m and then m.is_down then
				-- `hit_test` maps the screen position into the frame now on screen
				l_clicked := focus_manager.focus_at (hit_test (m))
			elseif attached {KEY_EVENT} a_event as k and then k.is_press then
				if k.code.is_escape or else (not is_submitted and then k.code.is_char and then k.code.character = '%U') then
					stop
				elseif k.code.is_tab then
					focus_manager.focus_next
				elseif k.code.is_back_tab then
					focus_manager.focus_previous
				elseif k.code.is_enter then
					is_submitted := True
				elseif focus_manager.is_focused (id_first) or focus_manager.is_focused (id_last) then
					if focus_manager.is_focused (id_first) then
						l_state := first_name_state
					else
						l_state := last_name_state
					end
					if k.code.is_backspace then
						l_state.delete_backward
					elseif k.code.is_delete then
						l_state.delete_forward
					elseif k.code.is_left then
						l_state.move_cursor_left
					elseif k.code.is_right then
						l_state.move_cursor_right
					elseif k.code.is_home then
						l_state.move_cursor_home
					elseif k.code.is_end then
						l_state.move_cursor_end
					elseif k.code.is_char then
						c := k.code.character
						if c >= ' ' and c /= '%/127/' then
							l_state.insert_character (c)
						end
					end
				elseif focus_manager.is_focused (id_age) then
					if k.code.is_up or else (k.code.is_char and then k.code.character = 'k') then
						if age < Max_age then
							age := age + 1
						end
					elseif k.code.is_down or else (k.code.is_char and then k.code.character = 'j') then
						if age > 0 then
							age := age - 1
						end
					elseif k.code.is_backspace then
						age := age // 10
					elseif k.code.is_char and then (k.code.character >= '0' and k.code.character <= '9') then
						l_digit := k.code.character.code - ('0').code
						l_new_age := age * 10 + l_digit
						if l_new_age <= Max_age then
							age := l_new_age
						end
					end
				end
			end
		end

end
