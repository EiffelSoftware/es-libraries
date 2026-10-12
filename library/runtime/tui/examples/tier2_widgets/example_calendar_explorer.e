note
	description: "[
		Tier 2 Widget Specialist Example: Calendar Explorer (Ratatui 1-to-1).
		Demonstrates monthly calendar visualization with TUI_CALENDAR and CALENDAR_STATE,
		keyboard date navigation, holiday styling, and display style toggling.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	EXAMPLE_CALENDAR_EXPLORER

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
			-- Initialize and launch Calendar Explorer example.
		local
			l_args: ARGUMENTS_32
			i: INTEGER
		do
			init_state
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
			init_state
			make_with_viewport (create {VIEWPORT}.make_fullscreen)
			auto_exit_frames := a_frames
			frame_counter := 0
			run
		end

feature {NONE} -- Setup

	init_state
			-- Setup initial date and style mode.
		do
			create calendar_state.make_with_date (2026, 9, 28)
			style_mode := 6 -- Month + Weekdays Header + Surrounding
		end

feature {NONE} -- State

	calendar_state: CALENDAR_STATE
			-- Calendar date selection and math state

	style_mode: INTEGER
			-- Display style mode (1..6)

	auto_exit_frames: INTEGER
			-- Auto-exit in batch mode

	frame_counter: INTEGER
			-- Rendered frame count

	Arrow_up: CHARACTER_32 = '%/0x2191/'
	Arrow_down: CHARACTER_32 = '%/0x2193/'
	Arrow_left: CHARACTER_32 = '%/0x2190/'
	Arrow_right: CHARACTER_32 = '%/0x2192/'

feature {NONE} -- Style Helpers

	style_name: STRING_32
			-- Name of active calendar presentation style.
		do
			inspect style_mode
			when 1 then Result := "Default (Minimal Grid)"
			when 2 then Result := "Show Surrounding Days"
			when 3 then Result := "Show Weekdays Header"
			when 4 then Result := "Surrounding & Weekdays Header"
			when 5 then Result := "Month Header Only"
			when 6 then Result := "Full: Month, Weekdays & Surrounding"
			else Result := "Default"
			end
		end

	cycle_style
			-- Advance to next calendar presentation mode.
		do
			style_mode := (style_mode \\ 6) + 1
		end

feature {NONE} -- Application Hooks

	render (a_frame: FRAME)
			-- Render header, calendar panel, and controls footer.
		local
			l_main_layout, l_h_layout, l_v_layout: LAYOUT
			l_main_chunks, l_h_chunks, l_v_chunks: ARRAY [RECT]
			l_header_area, l_body_area, l_footer_area: RECT
			l_calendar_area: RECT
			l_header_para, l_footer_para: TUI_PARAGRAPH
			l_calendar: TUI_CALENDAR
			l_cal_block: TUI_BLOCK
			l_date_str, l_info_str: STRING_32
			l_border_style, l_sel_style, l_hdr_style, l_weekday_style, l_surround_style: STYLE
		do
			if auto_exit_frames > 0 then
				frame_counter := frame_counter + 1
				if frame_counter >= auto_exit_frames then
					stop
				end
			end

			-- Layout: Header (3), Calendar Area (Flex 1), Footer (1)
			create l_main_layout.make_vertical (<<
				{CONSTRAINTS}.fixed (3),
				{CONSTRAINTS}.flex (1),
				{CONSTRAINTS}.fixed (1)
			>>)
			l_main_chunks := l_main_layout.split (a_frame.area)
			l_header_area := l_main_chunks [1]
			l_body_area := l_main_chunks [2]
			l_footer_area := l_main_chunks [3]

			-- Header Info
			create l_date_str.make (64)
			l_date_str.append_string_general ("EiffelTUI Calendar Explorer%N")
			l_date_str.append_string_general ("Date: ")
			l_date_str.append_integer (calendar_state.year)
			l_date_str.append_character ('-')
			if calendar_state.month < 10 then
				l_date_str.append_character ('0')
			end
			l_date_str.append_integer (calendar_state.month)
			l_date_str.append_character ('-')
			if calendar_state.selected_day < 10 then
				l_date_str.append_character ('0')
			end
			l_date_str.append_integer (calendar_state.selected_day)
			l_date_str.append_string_general (" (")
			l_date_str.append (calendar_state.month_name)
			l_date_str.append_string_general (") | Style: ")
			l_date_str.append (style_name)

			create l_header_para.make (create {TEXT}.make_styled (
				l_date_str,
				(create {STYLE}.make_fg ({COLOR}.Bright_cyan)).with_bold
			))
			l_header_para := l_header_para.with_alignment ({TEXT_ALIGNMENT}.center)
			a_frame.render_widget (l_header_para, l_header_area)

			-- Footer Instructions
			create l_info_str.make (128)
			l_info_str.append_string_general ("(h/l/")
			l_info_str.append_character (Arrow_left)
			l_info_str.append_character ('/')
			l_info_str.append_character (Arrow_right)
			l_info_str.append_string_general (") Day | (j/k/")
			l_info_str.append_character (Arrow_down)
			l_info_str.append_character ('/')
			l_info_str.append_character (Arrow_up)
			l_info_str.append_string_general (") Week | (n/p) Month | (s) Toggle Style | (q/Esc) Quit")
			create l_footer_para.make (create {TEXT}.make_styled (l_info_str, create {STYLE}.make_fg ({COLOR}.Dark_gray)))
			l_footer_para := l_footer_para.with_alignment ({TEXT_ALIGNMENT}.center)
			a_frame.render_widget (l_footer_para, l_footer_area)

			-- Center the calendar in the body area (Fixed 36 wide, Fixed 12 high)
			create l_v_layout.make_vertical (<<
				{CONSTRAINTS}.flex (1),
				{CONSTRAINTS}.fixed (13),
				{CONSTRAINTS}.flex (1)
			>>)
			l_v_chunks := l_v_layout.split (l_body_area)

			create l_h_layout.make_horizontal (<<
				{CONSTRAINTS}.flex (1),
				{CONSTRAINTS}.fixed (38),
				{CONSTRAINTS}.flex (1)
			>>)
			l_h_chunks := l_h_layout.split (l_v_chunks [2])
			l_calendar_area := l_h_chunks [2]

			-- Block Container
			create l_border_style.make_fg ({COLOR}.Bright_yellow)
			create l_cal_block.make
			l_cal_block := l_cal_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (l_border_style).
				with_title (" Calendar ").
				with_title_alignment ({TEXT_ALIGNMENT}.center)

			-- Calendar Styles
			create l_hdr_style.make_with_colors ({COLOR}.Bright_yellow, {COLOR}.Black)
			l_hdr_style := l_hdr_style.with_bold
			create l_weekday_style.make_fg ({COLOR}.Cyan)
			create l_sel_style.make_with_colors ({COLOR}.Black, {COLOR}.Bright_yellow)
			l_sel_style := l_sel_style.with_bold
			create l_surround_style.make_fg ({COLOR}.Dark_gray)

			create l_calendar.make
			l_calendar := l_calendar.with_block (l_cal_block).
				with_header_style (l_hdr_style).
				with_weekday_style (l_weekday_style).
				with_selected_style (l_sel_style)

			-- Apply style mode features
			inspect style_mode
			when 1 then
				l_calendar := l_calendar.with_show_month_header (False).
					with_show_weekday_header (False).
					with_show_surrounding (Void)
			when 2 then
				l_calendar := l_calendar.with_show_month_header (False).
					with_show_weekday_header (False).
					with_show_surrounding (l_surround_style)
			when 3 then
				l_calendar := l_calendar.with_show_month_header (False).
					with_show_weekday_header (True).
					with_show_surrounding (Void)
			when 4 then
				l_calendar := l_calendar.with_show_month_header (False).
					with_show_weekday_header (True).
					with_show_surrounding (l_surround_style)
			when 5 then
				l_calendar := l_calendar.with_show_month_header (True).
					with_show_weekday_header (False).
					with_show_surrounding (Void)
			when 6 then
				l_calendar := l_calendar.with_show_month_header (True).
					with_show_weekday_header (True).
					with_show_surrounding (l_surround_style)
			else
				-- fallback
			end

			-- Highlight holidays or special days
			-- e.g. 1st of month in bright green
			l_calendar.set_date_style (calendar_state.year, calendar_state.month, 1, (create {STYLE}.make_fg ({COLOR}.Bright_green)).with_bold)
			if calendar_state.month = 12 and calendar_state.days_in_current_month >= 25 then
				l_calendar.set_date_style (calendar_state.year, 12, 25, (create {STYLE}.make_fg ({COLOR}.Bright_red)).with_bold)
			end

			a_frame.render_stateful_widget (l_calendar, l_calendar_area, calendar_state)
		end

	process (a_event: EVENT)
			-- Handle navigation and style toggles.
		do
			if attached {KEY_EVENT} a_event as k and then k.is_press then
				if k.code.is_escape or else (k.code.is_char and then (k.code.character = 'q' or k.code.character = 'Q')) then
					stop
				elseif k.code.is_char and then (k.code.character = 's' or k.code.character = 'S') then
					cycle_style
				elseif k.code.is_left or else (k.code.is_char and then k.code.character = 'h') then
					calendar_state.previous_day
				elseif k.code.is_right or else (k.code.is_char and then k.code.character = 'l') then
					calendar_state.next_day
				elseif k.code.is_up or else (k.code.is_char and then k.code.character = 'k') then
					calendar_state.previous_week
				elseif k.code.is_down or else (k.code.is_char and then k.code.character = 'j') then
					calendar_state.next_week
				elseif k.code.is_page_down or else (k.code.is_char and then k.code.character = 'n') then
					calendar_state.next_month
				elseif k.code.is_page_up or else (k.code.is_char and then k.code.character = 'p') then
					calendar_state.previous_month
				end
			end
		end

end
