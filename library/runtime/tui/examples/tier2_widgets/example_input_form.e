note
	description: "[
		Tier 2 Widget Specialist Example: Input Form (Ratatui 1-to-1).
		Demonstrates multi-field input focus handling, Tab navigation,
		numeric validation, and form submission.
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
	make_batch

feature {NONE} -- Initialization

	make
			-- Initialize and launch Input Form example.
		local
			l_args: ARGUMENTS_32
			i: INTEGER
		do
			init_form
			Precursor
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
			auto_exit_frames := a_frames
			frame_counter := 0
			run
		end

feature {NONE} -- Setup

	init_form
			-- Initialize form state.
		do
			create first_name.make_from_string_general ("Ada")
			create last_name.make_from_string_general ("Lovelace")
			age := 36
			focused_field := 1
			is_submitted := False
		end

feature {NONE} -- State

	first_name: STRING_32
			-- Value of first name field

	last_name: STRING_32
			-- Value of last name field

	age: INTEGER
			-- Value of age field (0..130)

	focused_field: INTEGER
			-- Currently focused field: 1=First Name, 2=Last Name, 3=Age

	is_submitted: BOOLEAN
			-- Has the user submitted the form?

	auto_exit_frames: INTEGER
			-- Auto-exit in batch mode

	frame_counter: INTEGER
			-- Rendered frame count

	Max_age: INTEGER = 130
			-- Maximum allowable age value

feature {NONE} -- Form Navigation

	next_focus
			-- Move focus to the next field.
		do
			focused_field := (focused_field \\ 3) + 1
		ensure
			valid_focus: focused_field >= 1 and focused_field <= 3
		end

	prev_focus
			-- Move focus to the previous field.
		do
			if focused_field = 1 then
				focused_field := 3
			else
				focused_field := focused_field - 1
			end
		ensure
			valid_focus: focused_field >= 1 and focused_field <= 3
		end

feature {NONE} -- Application Hooks

	render (a_frame: FRAME)
			-- Render input form dialog with fields and submitted status.
		local
			l_v_layout, l_h_layout, l_form_layout: LAYOUT
			l_v_chunks, l_h_chunks, l_form_chunks: ARRAY [RECT]
			l_dialog_area: RECT
			l_outer_block, l_field_block: TUI_BLOCK
			l_outer_style, l_active_style, l_inactive_style: STYLE
			l_header_para, l_fn_para, l_ln_para, l_age_para, l_status_para: TUI_PARAGRAPH
			l_fn_text, l_ln_text, l_age_text, l_status_text: STRING_32
			l_instructions: STRING_32
		do
			if auto_exit_frames > 0 then
				frame_counter := frame_counter + 1
				if frame_counter >= auto_exit_frames then
					stop
				end
			end

			-- Centered dialog layout
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

			-- Outer Container Block
			create l_outer_style.make_fg ({COLOR}.Bright_cyan)
			create l_outer_block.make
			l_outer_block := l_outer_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (l_outer_style).
				with_title (" User Profile Form ").
				with_title_alignment ({TEXT_ALIGNMENT}.center)

			-- Split dialog area vertically into 5 rows: Instructions(2), Field 1(3), Field 2(3), Field 3(3), Status(4)
			create l_form_layout.make_vertical (<<
				{CONSTRAINTS}.fixed (2),
				{CONSTRAINTS}.fixed (3),
				{CONSTRAINTS}.fixed (3),
				{CONSTRAINTS}.fixed (3),
				{CONSTRAINTS}.flex (1)
			>>)
			l_form_chunks := l_form_layout.split (l_dialog_area.inner (1, 1))

			a_frame.render_widget (l_outer_block, l_dialog_area)

			-- Styles for active vs inactive fields
			create l_active_style.make_fg ({COLOR}.Bright_yellow)
			create l_inactive_style.make_fg ({COLOR}.Dark_gray)

			-- Instructions
			create l_instructions.make_from_string_general ("Tab/Shift-Tab: Next field | Enter: Submit | Esc: Exit")
			create l_header_para.make (create {TEXT}.make_styled (l_instructions, create {STYLE}.make_fg ({COLOR}.White)))
			l_header_para := l_header_para.with_alignment ({TEXT_ALIGNMENT}.center)
			a_frame.render_widget (l_header_para, l_form_chunks [1])

			-- Field 1: First Name
			create l_fn_text.make (32)
			l_fn_text.append (first_name)
			if focused_field = 1 then
				l_fn_text.append_character ('_')
			end
			create l_field_block.make
			l_field_block := l_field_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.plain)
			if focused_field = 1 then
				l_field_block := l_field_block.with_border_style (l_active_style).
					with_title (" First Name [Focused] ")
				create l_fn_para.make (create {TEXT}.make_styled (l_fn_text, create {STYLE}.make_fg ({COLOR}.Bright_yellow)))
			else
				l_field_block := l_field_block.with_border_style (l_inactive_style).
					with_title (" First Name ")
				create l_fn_para.make (create {TEXT}.make_styled (l_fn_text, create {STYLE}.make_fg ({COLOR}.White)))
			end
			l_fn_para := l_fn_para.with_block (l_field_block)
			a_frame.render_widget (l_fn_para, l_form_chunks [2])

			-- Field 2: Last Name
			create l_ln_text.make (32)
			l_ln_text.append (last_name)
			if focused_field = 2 then
				l_ln_text.append_character ('_')
			end
			create l_field_block.make
			l_field_block := l_field_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.plain)
			if focused_field = 2 then
				l_field_block := l_field_block.with_border_style (l_active_style).
					with_title (" Last Name [Focused] ")
				create l_ln_para.make (create {TEXT}.make_styled (l_ln_text, create {STYLE}.make_fg ({COLOR}.Bright_yellow)))
			else
				l_field_block := l_field_block.with_border_style (l_inactive_style).
					with_title (" Last Name ")
				create l_ln_para.make (create {TEXT}.make_styled (l_ln_text, create {STYLE}.make_fg ({COLOR}.White)))
			end
			l_ln_para := l_ln_para.with_block (l_field_block)
			a_frame.render_widget (l_ln_para, l_form_chunks [3])

			-- Field 3: Age
			create l_age_text.make (16)
			l_age_text.append_integer (age)
			if focused_field = 3 then
				l_age_text.append_string_general ("  (Up/Down or Digits, max 130)")
			end
			create l_field_block.make
			l_field_block := l_field_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.plain)
			if focused_field = 3 then
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

			-- Submission Status Box
			create l_status_text.make (128)
			if is_submitted then
				l_status_text.append_string_general ("SUBMITTED DATA: { first_name: %"")
				l_status_text.append (first_name)
				l_status_text.append_string_general ("%", last_name: %"")
				l_status_text.append (last_name)
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
		end

	process (a_event: EVENT)
			-- Process input according to focused form field.
		local
			c: CHARACTER_32
			l_digit, l_new_age: INTEGER
		do
			if attached {KEY_EVENT} a_event as k and then k.is_press then
				if k.code.is_escape or else (not is_submitted and then k.code.is_char and then k.code.character = '%U') then
					stop
				elseif k.code.is_tab then
					next_focus
				elseif k.code.is_back_tab then
					prev_focus
				elseif k.code.is_enter then
					is_submitted := True
				else
					inspect focused_field
					when 1 then
						-- First Name field
						if k.code.is_backspace then
							if not first_name.is_empty then
								first_name.remove_tail (1)
							end
						elseif k.code.is_char then
							c := k.code.character
							if c >= ' ' and c /= '%/127/' then
								first_name.append_character (c)
							end
						end
					when 2 then
						-- Last Name field
						if k.code.is_backspace then
							if not last_name.is_empty then
								last_name.remove_tail (1)
							end
						elseif k.code.is_char then
							c := k.code.character
							if c >= ' ' and c /= '%/127/' then
								last_name.append_character (c)
							end
						end
					when 3 then
						-- Age field
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
					else
						-- fallback
					end
				end
			end
		end

end
