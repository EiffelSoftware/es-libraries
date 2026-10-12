note
	description: "[
		Tier 3 Layout & Visualization Example: Weather Dashboard (Ratatui 1-to-1).
		Hourly weather temperature forecast rendered using TUI_BARCHART with
		temperature-scaled color gradients, diurnal temperature curves, and stats cards.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	EXAMPLE_WEATHER

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
			-- Initialize and launch Weather example.
		local
			l_args: ARGUMENTS_32
			i: INTEGER
		do
			init_state
			Precursor
			set_tick_rate (50)
			create l_args
			auto_exit_frames := -1
			from i := 1 until i > l_args.argument_count loop
				if l_args.argument (i).is_equal ("-batch") then
					auto_exit_frames := 5
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
			set_tick_rate (50)
			auto_exit_frames := a_frames
			frame_counter := 0
			run
		end

feature {NONE} -- Setup

	init_state
			-- Setup temperature dataset and preferences.
		do
			is_celsius := False
			selected_hour := 14 -- 14:00 (peak afternoon)
			seed := 12345
			generate_temperatures
		end

	generate_temperatures
			-- Generate 24 hourly temperatures following a diurnal atmospheric curve.
		local
			h: INTEGER
			angle, rad: REAL_64
			base_temp, noise: REAL_64
			t_val: INTEGER
			m: DOUBLE_MATH
		do
			create m
			create hourly_temps.make (24)
			from
				h := 0
			until
				h >= 24
			loop
				-- Diurnal temperature cycle: coolest at 5am, warmest at 15pm
				angle := (h.to_double - 9.0) * {DOUBLE_MATH}.pi / 12.0
				rad := (1.0 + m.sine (angle)) / 2.0
				base_temp := 52.0 + (rad * 34.0) -- 52°F to 86°F base

				-- Pseudo-random variation
				seed := ((seed * 1103515245 + 12345) & 0x7FFFFFFF)
				noise := ((seed \\ 7) - 3).to_double

				t_val := (base_temp + noise).rounded.max (45).min (98)
				hourly_temps.extend (t_val)
				h := h + 1
			end
		end

feature {NONE} -- State

	is_celsius: BOOLEAN
			-- True for Celsius, False for Fahrenheit

	selected_hour: INTEGER
			-- Currently inspected hour (0..23)

	hourly_temps: ARRAYED_LIST [INTEGER]
			-- 24 hourly temperatures in Fahrenheit

	seed: INTEGER_64
			-- LCG PRNG state

	auto_exit_frames: INTEGER
			-- Batch auto-exit counter

	frame_counter: INTEGER
			-- Rendered frame count

feature {NONE} -- Temperature Conversions & Colors

	format_temp (a_f_temp: INTEGER): STRING_32
			-- Format temperature according to `is_celsius`.
		local
			c: INTEGER
		do
			create Result.make (8)
			if is_celsius then
				c := ((a_f_temp - 32) * 5) // 9
				Result.append_integer (c)
				Result.append_character ('%/176/')
				Result.append_character ('C')
			else
				Result.append_integer (a_f_temp)
				Result.append_character ('%/176/')
				Result.append_character ('F')
			end
		end

	temp_color (a_f_temp: INTEGER): COLOR
			-- Color palette representing thermal intensity.
		do
			if a_f_temp < 58 then
				create Result.make_rgb (59, 130, 246)  -- Blue
			elseif a_f_temp < 68 then
				create Result.make_rgb (20, 184, 166)  -- Teal
			elseif a_f_temp < 76 then
				create Result.make_rgb (34, 197, 94)   -- Green
			elseif a_f_temp < 84 then
				create Result.make_rgb (234, 179, 8)   -- Yellow/Amber
			else
				create Result.make_rgb (239, 68, 68)   -- Red/Orange
			end
		end

feature {NONE} -- Rendering

	render (a_frame: FRAME)
			-- Draw weather dashboard.
		local
			l_main_layout: LAYOUT
			l_main_chunks: ARRAY [RECT]
			l_header_area, l_stats_area, l_chart_area, l_footer_area: RECT
		do
			if auto_exit_frames > 0 then
				frame_counter := frame_counter + 1
				if frame_counter >= auto_exit_frames then
					stop
				end
			end

			-- Vertical structure: Header(3), Stats Cards(5), BarChart(Flex 1), Footer(2)
			create l_main_layout.make_vertical (<<
				{CONSTRAINTS}.fixed (3),
				{CONSTRAINTS}.fixed (5),
				{CONSTRAINTS}.flex (1),
				{CONSTRAINTS}.fixed (2)
			>>)
			l_main_chunks := l_main_layout.split (a_frame.area)
			l_header_area := l_main_chunks [1]
			l_stats_area := l_main_chunks [2]
			l_chart_area := l_main_chunks [3]
			l_footer_area := l_main_chunks [4]

			render_header (a_frame, l_header_area)
			render_stats_cards (a_frame, l_stats_area)
			render_barchart (a_frame, l_chart_area)
			render_footer (a_frame, l_footer_area)
		end

	render_header (a_frame: FRAME; a_area: RECT)
			-- Render top header with location and condition summary.
		local
			l_para: TUI_PARAGRAPH
			l_text: TEXT
			l_line: TEXT_LINE
			l_unit_str: STRING_32
		do
			create l_text.make_empty
			create l_line.make_empty
			l_line.append_span (create {TEXT_SPAN}.make (
				"EiffelTUI 24-Hour Weather Forecast",
				(create {STYLE}.make_fg ({COLOR}.Bright_cyan)).with_bold
			))
			l_line.append_span (create {TEXT_SPAN}.make (
				"  --  San Francisco, CA (Sunny & Clear)",
				create {STYLE}.make_fg ({COLOR}.Bright_yellow)
			))
			l_text.append_line (l_line)

			create l_line.make_empty
			l_line.append_span (create {TEXT_SPAN}.make ("Active Unit: ", create {STYLE}.make_fg ({COLOR}.Gray)))
			if is_celsius then
				l_unit_str := "Celsius (metric)"
			else
				l_unit_str := "Fahrenheit (imperial)"
			end
			l_line.append_span (create {TEXT_SPAN}.make (
				l_unit_str,
				(create {STYLE}.make_with_colors ({COLOR}.Black, {COLOR}.Bright_green)).with_bold
			))
			l_line.append_span (create {TEXT_SPAN}.make ("  | Selected Hour: ", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_line.append_span (create {TEXT_SPAN}.make (
				format_hour (selected_hour) + " -> " + format_temp (hourly_temps [selected_hour + 1]),
				(create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold
			))
			l_text.append_line (l_line)

			create l_para.make (l_text)
			a_frame.render_widget (l_para, a_area)
		end

	render_stats_cards (a_frame: FRAME; a_area: RECT)
			-- Render summary KPI metric boxes (Min, Max, Avg, Current).
		local
			l_layout: LAYOUT
			l_chunks: ARRAY [RECT]
			min_temp, max_temp, sum_temp, avg_temp: INTEGER
			min_hour, max_hour: INTEGER
			h, t: INTEGER
		do
			min_temp := 999
			max_temp := -999
			sum_temp := 0
			from
				h := 0
			until
				h >= 24
			loop
				t := hourly_temps [h + 1]
				if t < min_temp then
					min_temp := t
					min_hour := h
				end
				if t > max_temp then
					max_temp := t
					max_hour := h
				end
				sum_temp := sum_temp + t
				h := h + 1
			end
			avg_temp := sum_temp // 24

			create l_layout.make_horizontal (<<
				{CONSTRAINTS}.ratio (1, 4),
				{CONSTRAINTS}.ratio (1, 4),
				{CONSTRAINTS}.ratio (1, 4),
				{CONSTRAINTS}.ratio (1, 4)
			>>)
			l_chunks := l_layout.split (a_area)

			render_kpi_card (a_frame, l_chunks [1], "Selected Hour", format_temp (hourly_temps [selected_hour + 1]), format_hour (selected_hour), {COLOR}.Bright_yellow)
			render_kpi_card (a_frame, l_chunks [2], "Daily Minimum", format_temp (min_temp), {STRING_32} "at " + format_hour (min_hour), {COLOR}.Bright_blue)
			render_kpi_card (a_frame, l_chunks [3], "Daily Maximum", format_temp (max_temp), {STRING_32} "at " + format_hour (max_hour), {COLOR}.Bright_red)
			render_kpi_card (a_frame, l_chunks [4], "Daily Average", format_temp (avg_temp), "24h Mean", {COLOR}.Bright_green)
		end

	render_kpi_card (a_frame: FRAME; a_area: RECT; a_title, a_value, a_sub: STRING_32; a_color: COLOR)
			-- Render single KPI card.
		local
			l_block: TUI_BLOCK
			l_para: TUI_PARAGRAPH
			l_text: TEXT
			l_line: TEXT_LINE
		do
			create l_block.make
			l_block := l_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (create {STYLE}.make_fg (a_color)).
				with_title (a_title)
			a_frame.render_widget (l_block, a_area)

			create l_text.make_empty
			create l_line.make_empty
			l_line.append_span (create {TEXT_SPAN}.make (a_value, (create {STYLE}.make_fg (a_color)).with_bold))
			l_text.append_line (l_line)

			create l_line.make_empty
			l_line.append_span (create {TEXT_SPAN}.make (a_sub, create {STYLE}.make_fg ({COLOR}.Gray)))
			l_text.append_line (l_line)

			create l_para.make (l_text)
			l_para := l_para.with_alignment ({TEXT_ALIGNMENT}.center)
			a_frame.render_widget (l_para, l_block.inner (a_area))
		end

	render_barchart (a_frame: FRAME; a_area: RECT)
			-- Render 24-hour vertical bar chart.
		local
			l_block: TUI_BLOCK
			l_chart: TUI_BARCHART
			l_bars: ARRAYED_LIST [BAR_ITEM]
			h, t_val: INTEGER
			l_bar: BAR_ITEM
			l_col: COLOR
			l_bar_style, l_val_style, l_lbl_style: STYLE
		do
			create l_block.make
			l_block := l_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (create {STYLE}.make_fg ({COLOR}.Bright_cyan)).
				with_title (" 24-Hour Diurnal Temperature Distribution (Hourly Breakdown) ")

			create l_bars.make (24)
			from
				h := 0
			until
				h >= 24
			loop
				t_val := hourly_temps [h + 1]
				l_col := temp_color (t_val)

				create l_bar.make_with_text (
					format_hour_short (h),
					t_val.to_natural_64,
					format_temp (t_val)
				)

				if h = selected_hour then
					-- Highlight selected bar with reverse styling
					create l_bar_style.make_with_colors ({COLOR}.Black, {COLOR}.Bright_yellow)
					l_val_style := (create {STYLE}.make_with_colors ({COLOR}.Black, {COLOR}.Bright_yellow)).with_bold
					l_lbl_style := (create {STYLE}.make_with_colors ({COLOR}.Black, {COLOR}.Bright_yellow)).with_bold
				else
					create l_bar_style.make_fg (l_col)
					l_val_style := (create {STYLE}.make_fg (l_col)).with_bold
					create l_lbl_style.make_fg ({COLOR}.Dark_gray)
				end

				l_bar := l_bar.with_style (l_bar_style).
					with_value_style (l_val_style).
					with_label_style (l_lbl_style)

				l_bars.extend (l_bar)
				h := h + 1
			end

			create l_chart.make
			l_chart := l_chart.with_block (l_block).
				with_bars (l_bars).
				with_bar_width (4).
				with_bar_gap (1).
				with_max_value (100)

			a_frame.render_widget (l_chart, a_area)
		end

	render_footer (a_frame: FRAME; a_area: RECT)
			-- Render navigation commands.
		local
			l_para: TUI_PARAGRAPH
			l_text: TEXT
			l_line: TEXT_LINE
		do
			create l_text.make_empty
			create l_line.make_empty
			l_line.append_span (create {TEXT_SPAN}.make ("[Left/Right/h/l] ", (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold))
			l_line.append_span (create {TEXT_SPAN}.make ("Select Hour  ", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_line.append_span (create {TEXT_SPAN}.make ("[u] ", (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold))
			l_line.append_span (create {TEXT_SPAN}.make ("Toggle Unit  ", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_line.append_span (create {TEXT_SPAN}.make ("[r] ", (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold))
			l_line.append_span (create {TEXT_SPAN}.make ("Regenerate Forecast  ", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_line.append_span (create {TEXT_SPAN}.make ("[q/Esc] ", (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold))
			l_line.append_span (create {TEXT_SPAN}.make ("Quit", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_text.append_line (l_line)

			create l_para.make (l_text)
			l_para := l_para.with_alignment ({TEXT_ALIGNMENT}.center)
			a_frame.render_widget (l_para, a_area)
		end

feature {NONE} -- Helpers

	format_hour (a_hour: INTEGER): STRING_32
			-- Format hour as "HH:00".
		do
			create Result.make (5)
			if a_hour < 10 then
				Result.append_character ('0')
			end
			Result.append_integer (a_hour)
			Result.append_string_general (":00")
		end

	format_hour_short (a_hour: INTEGER): STRING_32
			-- Short label for bar chart: "00", "01", etc.
		do
			create Result.make (2)
			if a_hour < 10 then
				Result.append_character ('0')
			end
			Result.append_integer (a_hour)
		end

feature {NONE} -- Event Handling

	process (a_event: EVENT)
			-- Handle interactive commands.
		local
			ch: CHARACTER_32
		do
			if attached {KEY_EVENT} a_event as k and then k.is_press then
				if k.code.is_escape then
					stop
				elseif k.code.is_char then
					ch := k.code.character
					if ch = 'q' or ch = 'Q' then
						stop
					elseif ch = 'u' or ch = 'U' then
						is_celsius := not is_celsius
					elseif ch = 'r' or ch = 'R' then
						generate_temperatures
					elseif ch = 'h' or ch = 'H' then
						selected_hour := (selected_hour - 1 + 24) \\ 24
					elseif ch = 'l' or ch = 'L' then
						selected_hour := (selected_hour + 1) \\ 24
					end
				elseif k.code.is_left then
					selected_hour := (selected_hour - 1 + 24) \\ 24
				elseif k.code.is_right then
					selected_hour := (selected_hour + 1) \\ 24
				end
			end
		end

end
