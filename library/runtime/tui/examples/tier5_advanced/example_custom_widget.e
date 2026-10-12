note
	description: "[
		Tier 5 Advanced Example: Custom Widget (Ratatui 1-to-1).
		Demonstrates creating, styling, and interacting with custom EiffelTUI
		widgets (BUTTON_WIDGET) with 3D bevel shading, mouse capture, and keyboard navigation.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	EXAMPLE_CUSTOM_WIDGET

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
			-- Initialize and launch Custom Widget interactive example.
		local
			l_args: ARGUMENTS_32
			i: INTEGER
		do
			init_state
			Precursor
			set_mouse_capture (True)
			set_tick_rate (50)
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
			-- Initialize and run for `a_frames` frames in batch mode.
		do
			init_state
			make_with_viewport (create {VIEWPORT}.make_fullscreen)
			set_mouse_capture (False)
			set_tick_rate (50)
			auto_exit_frames := a_frames
			frame_counter := 0
			run
		end

feature {NONE} -- State

	auto_exit_frames: INTEGER
	frame_counter: INTEGER

	selected_button: INTEGER
			-- 1 = Red, 2 = Green, 3 = Blue

	button_active: ARRAY [BOOLEAN]
			-- Is button currently active/toggled?

	button_areas: ARRAY [RECT]
			-- Cached button screen bounds for mouse click hit testing

	status_message: STRING_32

feature {NONE} -- Setup

	init_state
			-- Setup initial states.
		do
			selected_button := 1
			create button_active.make_filled (False, 1, 3)
			create button_areas.make_filled (create {RECT}.default_create, 1, 3)
			status_message := "Ready. Click buttons or use arrows / Space."
		end

feature {NONE} -- Application Hooks

	render (a_frame: FRAME)
			-- Render custom button widget playground.
		local
			l_v_layout, l_h_layout: LAYOUT
			l_v_chunks, l_h_chunks: ARRAY [RECT]
			l_title_area, l_buttons_row, l_help_area, l_status_area: RECT
			l_btn_red, l_btn_green, l_btn_blue: BUTTON_WIDGET
			l_red_st, l_green_st, l_blue_st: INTEGER
			l_title_para, l_help_para, l_stat_para: TUI_PARAGRAPH
			l_title_style, l_help_style, l_stat_style: STYLE
		do
			if auto_exit_frames > 0 then
				frame_counter := frame_counter + 1
				if frame_counter >= auto_exit_frames then
					stop
				end
			end

			-- Vertical layout: Title (2), Buttons row (5), Help (2), Status (2)
			create l_v_layout.make_vertical (<<
				{CONSTRAINTS}.fixed (2),
				{CONSTRAINTS}.fixed (5),
				{CONSTRAINTS}.fixed (2),
				{CONSTRAINTS}.fixed (2),
				{CONSTRAINTS}.flex (1)
			>>)
			l_v_chunks := l_v_layout.split (a_frame.area)
			l_title_area := l_v_chunks [1]
			l_buttons_row := l_v_chunks [2]
			l_help_area := l_v_chunks [3]
			l_status_area := l_v_chunks [4]

			-- 1. Title
			create l_title_style.make_fg ({COLOR}.Bright_cyan)
			l_title_style := l_title_style.with_bold
			create l_title_para.make (create {TEXT}.make_styled ("Custom Widget Showcase: 3D Beveled Buttons (Mouse & Keyboard)", l_title_style))
			a_frame.render_widget (l_title_para, l_title_area)

			-- 2. Buttons Row: 3 buttons horizontally (16 cols each, with spacing)
			create l_h_layout.make_horizontal (<<
				{CONSTRAINTS}.fixed (18),
				{CONSTRAINTS}.fixed (2),
				{CONSTRAINTS}.fixed (18),
				{CONSTRAINTS}.fixed (2),
				{CONSTRAINTS}.fixed (18),
				{CONSTRAINTS}.flex (1)
			>>)
			l_h_chunks := l_h_layout.split (l_buttons_row)
			button_areas [1] := l_h_chunks [1]
			button_areas [2] := l_h_chunks [3]
			button_areas [3] := l_h_chunks [5]

			-- Calculate button states
			l_red_st := calculate_state (1)
			l_green_st := calculate_state (2)
			l_blue_st := calculate_state (3)

			-- Red Button
			create l_btn_red.make ("Red")
			l_btn_red := l_btn_red.with_colors (
				create {COLOR}.make_rgb (255, 230, 230),
				create {COLOR}.make_rgb (144, 48, 48),
				create {COLOR}.make_rgb (192, 64, 64),
				create {COLOR}.make_rgb (96, 32, 32)).with_state (l_red_st)
			a_frame.render_widget (l_btn_red, button_areas [1])

			-- Green Button
			create l_btn_green.make ("Green")
			l_btn_green := l_btn_green.with_colors (
				create {COLOR}.make_rgb (230, 255, 230),
				create {COLOR}.make_rgb (48, 144, 48),
				create {COLOR}.make_rgb (64, 192, 64),
				create {COLOR}.make_rgb (32, 96, 32)).with_state (l_green_st)
			a_frame.render_widget (l_btn_green, button_areas [2])

			-- Blue Button
			create l_btn_blue.make ("Blue")
			l_btn_blue := l_btn_blue.with_colors (
				create {COLOR}.make_rgb (230, 240, 255),
				create {COLOR}.make_rgb (48, 72, 144),
				create {COLOR}.make_rgb (64, 96, 192),
				create {COLOR}.make_rgb (32, 48, 96)).with_state (l_blue_st)
			a_frame.render_widget (l_btn_blue, button_areas [3])

			-- 3. Help shortcuts
			create l_help_style.make_fg ({COLOR}.Yellow)
			create l_help_para.make (create {TEXT}.make_styled ("Controls: [Left / Right / Tab] Select  |  [Space / Enter / Click] Toggle  |  [q] Quit", l_help_style))
			a_frame.render_widget (l_help_para, l_help_area)

			-- 4. Status
			create l_stat_style.make_fg ({COLOR}.Green)
			create l_stat_para.make (create {TEXT}.make_styled (status_message, l_stat_style))
			a_frame.render_widget (l_stat_para, l_status_area)
		end

	calculate_state (a_index: INTEGER): INTEGER
			-- Compute state constant for button `a_index`.
		do
			if button_active [a_index] then
				Result := {BUTTON_WIDGET}.State_active
			elseif selected_button = a_index then
				Result := {BUTTON_WIDGET}.State_selected
			else
				Result := {BUTTON_WIDGET}.State_normal
			end
		end

	process (a_event: EVENT)
			-- Process mouse and keyboard events.
		local
			i: INTEGER
		do
			-- Keyboard
			if attached {KEY_EVENT} a_event as k then
				if k.is_press then
					if k.code.is_char and then (k.code.character = 'q' or k.code.character = 'Q') then
						stop
					elseif k.code.is_escape then
						stop
					elseif k.code.is_left then
						selected_button := selected_button - 1
						if selected_button < 1 then
							selected_button := 3
						end
						status_message := {STRING_32} "Focused button: " + button_name (selected_button)
					elseif k.code.is_right or k.code.is_tab then
						selected_button := selected_button + 1
						if selected_button > 3 then
							selected_button := 1
						end
						status_message := {STRING_32} "Focused button: " + button_name (selected_button)
					elseif (k.code.is_char and then k.code.character = ' ') or k.code.is_enter then
						button_active [selected_button] := not button_active [selected_button]
						status_message := {STRING_32} "Toggled button: " + button_name (selected_button) +
							if button_active [selected_button] then {STRING_32} " [PRESSED]" else {STRING_32} " [RELEASED]" end
					end
				end
			end

			-- Mouse click
			if attached {MOUSE_EVENT} a_event as m then
				if m.is_down and m.button = 0 then
					from i := 1 until i > 3 loop
						if button_areas [i].contains_point (m.column, m.row) then
							selected_button := i
							button_active [i] := not button_active [i]
							status_message := {STRING_32} "Mouse clicked " + button_name (i) +
								if button_active [i] then {STRING_32} " [PRESSED]" else {STRING_32} " [RELEASED]" end
						end
						i := i + 1
					end
				end
			end
		end

	button_name (a_index: INTEGER): STRING_32
			-- Name of button `a_index`.
		do
			inspect a_index
			when 1 then Result := "Red"
			when 2 then Result := "Green"
			when 3 then Result := "Blue"
			else Result := "Unknown"
			end
		end

end
