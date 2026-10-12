note
	description: "[
		Tier 4 Flagship Showcase Dashboard: Demo 1 (Ratatui 1-to-1).
		Comprehensive multi-tab operations center featuring:
		- Top navigation tabs with live tab switching
		- Dynamic real-time metrics: Gauge, Sparkline, and LineGauge
		- Interactive Task list with cursor navigation & System Log feed
		- Real-time animated sinusoidal waveform charts with dual datasets
		- High-density BarChart distribution metrics
		- Multi-server geospatial tracking with Braille World Map projection
		- Full color matrix and system reference guide
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	EXAMPLE_DEMO

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
			-- Initialize and launch Flagship Demo.
		local
			l_args: ARGUMENTS_32
			i: INTEGER
		do
			init_state
			Precursor
			set_tick_rate (50) -- 20 FPS refresh rate
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
			-- Initialize and run for `a_frames` frames in headless batch mode.
		do
			init_state
			make_with_viewport (create {VIEWPORT}.make_fullscreen)
			set_tick_rate (50)
			auto_exit_frames := a_frames
			frame_counter := 0
			run
		end

feature {NONE} -- State Setup

	init_state
			-- Setup initial datasets, lists, and waveform signals.
		local
			i: INTEGER
			x, y1, y2: REAL_64
			m: DOUBLE_MATH
			l_val: NATURAL_64
		do
			create m
			active_tab := 1
			show_chart := True
			progress := 0.0
			sin_x := 0.0
			window_start := 0.0
			window_width := 20.0
			seed := 987654321

			-- Sparkline initial dataset (100 values)
			create sparkline_data.make (100)
			from i := 1 until i > 100 loop
				l_val := next_random_val (100).to_natural_64
				sparkline_data.extend (l_val)
				i := i + 1
			end

			-- Sine waveforms for chart
			create sin1_data.make (120)
			create sin2_data.make (120)
			from i := 0 until i >= 100 loop
				x := i.to_double * 0.2
				y1 := m.sine (x / 3.0) * 18.0
				y2 := m.cosine (x / 2.0) * 12.0
				sin1_data.extend ([x, y1])
				sin2_data.extend ([x, y2])
				sin_x := x
				i := i + 1
			end

			-- Tasks List
			create tasks_items.make (24)
			from i := 1 until i > 24 loop
				tasks_items.extend ("Item " + i.out)
				i := i + 1
			end
			create tasks_state.make
			tasks_state.select_index (1)

			-- Logs Feed
			create logs_items.make (26)
			init_logs

			-- BarChart Items
			create barchart_items.make (24)
			init_barchart
		end

	init_logs
			-- Populate initial system event log entries.
		do
			logs_items.extend (["Event 1", "INFO"])
			logs_items.extend (["Event 2", "INFO"])
			logs_items.extend (["Event 3", "CRITICAL"])
			logs_items.extend (["Event 4", "ERROR"])
			logs_items.extend (["Event 5", "INFO"])
			logs_items.extend (["Event 6", "INFO"])
			logs_items.extend (["Event 7", "WARNING"])
			logs_items.extend (["Event 8", "INFO"])
			logs_items.extend (["Event 9", "INFO"])
			logs_items.extend (["Event 10", "INFO"])
			logs_items.extend (["Event 11", "CRITICAL"])
			logs_items.extend (["Event 12", "INFO"])
			logs_items.extend (["Event 13", "INFO"])
			logs_items.extend (["Event 14", "INFO"])
			logs_items.extend (["Event 15", "INFO"])
			logs_items.extend (["Event 16", "INFO"])
			logs_items.extend (["Event 17", "ERROR"])
			logs_items.extend (["Event 18", "ERROR"])
			logs_items.extend (["Event 19", "INFO"])
			logs_items.extend (["Event 20", "INFO"])
			logs_items.extend (["Event 21", "WARNING"])
			logs_items.extend (["Event 22", "INFO"])
			logs_items.extend (["Event 23", "INFO"])
			logs_items.extend (["Event 24", "WARNING"])
			logs_items.extend (["Event 25", "INFO"])
			logs_items.extend (["Event 26", "INFO"])
			create logs_state.make
			logs_state.select_index (1)
		end

	init_barchart
			-- Populate initial barchart activity levels.
		local
			l_vals: ARRAY [NATURAL_64]
			i: INTEGER
		do
			l_vals := <<9, 12, 5, 8, 2, 4, 5, 9, 14, 15, 1, 0, 4, 6, 4, 6, 4, 7, 13, 8, 11, 9, 3, 5>>
			from i := 1 until i > l_vals.count loop
				barchart_items.extend (create {BAR_ITEM}.make ("B" + i.out, l_vals [i]))
				i := i + 1
			end
		end

feature {NONE} -- State Fields

	active_tab: INTEGER
			-- Active tab: 1 = Dashboard, 2 = Servers & Map, 3 = Colors Matrix

	show_chart: BOOLEAN
			-- Toggle for showing/hiding right-side waveform chart

	progress: REAL_64
			-- Progress fraction 0.0 to 1.0

	sparkline_data: ARRAYED_LIST [NATURAL_64]
			-- Real-time sparkline telemetry

	sin1_data: ARRAYED_LIST [TUPLE [x, y: REAL_64]]
			-- First sine wave dataset

	sin2_data: ARRAYED_LIST [TUPLE [x, y: REAL_64]]
			-- Second harmonic dataset

	sin_x: REAL_64
			-- Current X abscissa for sine generation

	window_start: REAL_64
			-- Chart visible time window start

	window_width: REAL_64
			-- Chart visible time window width

	tasks_items: ARRAYED_LIST [STRING_8]
			-- Task list items

	tasks_state: LIST_STATE
			-- State tracking task list cursor

	logs_items: ARRAYED_LIST [TUPLE [event, level: STRING_8]]
			-- Rotating event logs

	logs_state: LIST_STATE
			-- State tracking log feed

	barchart_items: ARRAYED_LIST [BAR_ITEM]
			-- Rotating bar chart values

	seed: INTEGER_64
			-- LCG random number generator state

	auto_exit_frames: INTEGER
			-- Batch auto-exit counter (-1 for infinite interactive loop)

	frame_counter: INTEGER
			-- Rendered frame count

feature {NONE} -- Kinematics & Simulation

	next_random_val (a_max: INTEGER): INTEGER
			-- Next pseudo-random integer in 0..a_max.
		do
			seed := ((seed * 1103515245 + 12345) & 0x7FFFFFFF)
			Result := ((seed \\ (a_max + 1).to_integer_64)).to_integer_32.abs
		end

	on_tick
			-- Heartbeat tick: advance animations and data series.
		local
			m: DOUBLE_MATH
			y1, y2: REAL_64
			l_log: TUPLE [event, level: STRING_8]
			l_bar: BAR_ITEM
		do
			create m

			-- Progress bar cycle
			progress := progress + 0.005
			if progress > 1.0 then
				progress := 0.0
			end

			-- Sparkline advance
			if sparkline_data.count > 0 then
				sparkline_data.start
				sparkline_data.remove
			end
			sparkline_data.extend (next_random_val (100).to_natural_64)

			-- Waveform advances
			sin_x := sin_x + 0.2
			y1 := m.sine (sin_x / 3.0) * 18.0
			y2 := m.cosine (sin_x / 2.0) * 12.0
			if sin1_data.count > 100 then
				sin1_data.start
				sin1_data.remove
			end
			sin1_data.extend ([sin_x, y1])

			if sin2_data.count > 100 then
				sin2_data.start
				sin2_data.remove
			end
			sin2_data.extend ([sin_x, y2])

			window_start := window_start + 0.2

			-- Rotate log feed
			if logs_items.count > 1 then
				l_log := logs_items.last
				logs_items.finish
				logs_items.remove
				logs_items.put_front (l_log)
			end

			-- Rotate barchart items
			if barchart_items.count > 1 then
				l_bar := barchart_items.last
				barchart_items.finish
				barchart_items.remove
				barchart_items.put_front (l_bar)
			end
		end

feature {NONE} -- Event Handling

	process (a_event: EVENT)
			-- Process user keystrokes and periodic timer ticks.
		local
			ch: CHARACTER_32
		do
			if attached {TICK_EVENT} a_event then
				on_tick
			elseif attached {KEY_EVENT} a_event as k and then k.is_press then
				if k.code.is_escape then
					stop
				elseif k.code.is_left then
					active_tab := (active_tab - 2 + 3) \\ 3 + 1
				elseif k.code.is_right or k.code.is_tab then
					active_tab := (active_tab \\ 3) + 1
				elseif k.code.is_up then
					tasks_state.select_previous (tasks_items.count)
				elseif k.code.is_down then
					tasks_state.select_next (tasks_items.count)
				elseif k.code.is_char then
					ch := k.code.character
					if ch = 'q' or ch = 'Q' then
						stop
					elseif ch = 'h' or ch = 'H' then
						active_tab := (active_tab - 2 + 3) \\ 3 + 1
					elseif ch = 'l' or ch = 'L' then
						active_tab := (active_tab \\ 3) + 1
					elseif ch = 'k' or ch = 'K' then
						tasks_state.select_previous (tasks_items.count)
					elseif ch = 'j' or ch = 'J' then
						tasks_state.select_next (tasks_items.count)
					elseif ch = 't' or ch = 'T' then
						show_chart := not show_chart
					elseif ch = '1' then
						active_tab := 1
					elseif ch = '2' then
						active_tab := 2
					elseif ch = '3' then
						active_tab := 3
					end
				end
			end
		end

feature {NONE} -- Main Rendering Loop

	render (a_frame: FRAME)
			-- Main rendering pipeline: header tabs + active tab contents.
		local
			l_layout: LAYOUT
			l_chunks: ARRAY [RECT]
			l_tabs_area, l_body_area: RECT
		do
			if auto_exit_frames > 0 then
				frame_counter := frame_counter + 1
				if frame_counter >= auto_exit_frames then
					stop
				end
			end

			create l_layout.make_vertical (<<
				{CONSTRAINTS}.fixed (3),
				{CONSTRAINTS}.flex (1)
			>>)
			l_chunks := l_layout.split (a_frame.area)
			l_tabs_area := l_chunks [1]
			l_body_area := l_chunks [2]

			render_tabs (a_frame, l_tabs_area)

			inspect active_tab
			when 1 then
				render_dashboard_tab (a_frame, l_body_area)
			when 2 then
				render_servers_tab (a_frame, l_body_area)
			when 3 then
				render_colors_tab (a_frame, l_body_area)
			else
				render_dashboard_tab (a_frame, l_body_area)
			end
		end

	render_tabs (a_frame: FRAME; a_area: RECT)
			-- Render top navigation tab bar.
		local
			l_tabs: TUI_TABS
			l_block: TUI_BLOCK
			l_titles: ARRAYED_LIST [READABLE_STRING_GENERAL]
			l_tab_style, l_hi_style: STYLE
		do
			create l_titles.make (3)
			l_titles.extend (" Tab0: Operations Dashboard ")
			l_titles.extend (" Tab1: Servers & World Map ")
			l_titles.extend (" Tab2: Color Palette Matrix ")

			create l_block.make
			l_block := l_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (create {STYLE}.make_fg ({COLOR}.Bright_cyan)).
				with_title (" EiffelTUI Master Demo [Ratatui 1-to-1] ")

			create l_tab_style.make_fg ({COLOR}.Dark_gray)
			create l_hi_style.make_with_colors ({COLOR}.Black, {COLOR}.Bright_yellow)
			l_hi_style := l_hi_style.with_bold

			create l_tabs.make_from_strings (l_titles)
			l_tabs := l_tabs.with_block (l_block).
				with_style (l_tab_style).
				with_highlight_style (l_hi_style).
				with_divider ("|").
				with_selected (active_tab)

			a_frame.render_widget (l_tabs, a_area)
		end

feature {NONE} -- Tab 0: Dashboard

	render_dashboard_tab (a_frame: FRAME; a_area: RECT)
			-- Render Tab 0: Gauges, Charts/Lists, and Footer.
		local
			l_layout: LAYOUT
			l_chunks: ARRAY [RECT]
			l_gauges_area, l_middle_area, l_footer_area: RECT
		do
			create l_layout.make_vertical (<<
				{CONSTRAINTS}.fixed (9),
				{CONSTRAINTS}.flex (1),
				{CONSTRAINTS}.fixed (6)
			>>)
			l_chunks := l_layout.split (a_area)
			l_gauges_area := l_chunks [1]
			l_middle_area := l_chunks [2]
			l_footer_area := l_chunks [3]

			render_gauges_block (a_frame, l_gauges_area)
			render_middle_dashboard (a_frame, l_middle_area)
			render_footer_block (a_frame, l_footer_area)
		end

	render_gauges_block (a_frame: FRAME; a_area: RECT)
			-- Render top gauges panel: TUI_GAUGE, TUI_SPARKLINE, and TUI_LINE_GAUGE.
		local
			l_block: TUI_BLOCK
			l_layout: LAYOUT
			l_chunks: ARRAY [RECT]
			l_inner_area: RECT
			l_gauge: TUI_GAUGE
			l_sparkline: TUI_SPARKLINE
			l_line_gauge: TUI_LINE_GAUGE
			l_pct_str: STRING_32
			l_gauge_style: STYLE
		do
			create l_block.make
			l_block := l_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (create {STYLE}.make_fg ({COLOR}.Bright_green)).
				with_title (" Telemetry & Gauges ")
			a_frame.render_widget (l_block, a_area)

			l_inner_area := a_area.inner (1, 1)

			create l_layout.make_vertical (<<
				{CONSTRAINTS}.fixed (2),
				{CONSTRAINTS}.fixed (3),
				{CONSTRAINTS}.fixed (2)
			>>)
			l_chunks := l_layout.split (l_inner_area)

			-- 1. Standard Gauge with Label
			create l_pct_str.make (16)
			l_pct_str.append_string_general ("Progress: ")
			l_pct_str.append_integer ((progress * 100.0).rounded)
			l_pct_str.append_character ('%%')

			create l_gauge_style.make_with_colors ({COLOR}.Bright_white, {COLOR}.Magenta)
			l_gauge_style := l_gauge_style.with_bold

			create l_gauge.make
			l_gauge := l_gauge.with_ratio (progress).
				with_label (l_pct_str).
				with_gauge_style (l_gauge_style).
				with_use_unicode (True)
			a_frame.render_widget (l_gauge, l_chunks [1])

			-- 2. Sparkline
			create l_sparkline.make_with_data (sparkline_data)
			l_sparkline := l_sparkline.with_bar_style (create {STYLE}.make_fg ({COLOR}.Bright_green)).
				with_style (create {STYLE}.make_fg ({COLOR}.Dark_gray))
			a_frame.render_widget (l_sparkline, l_chunks [2])

			-- 3. Line Gauge
			create l_line_gauge.make
			l_line_gauge := l_line_gauge.with_ratio (progress).
				with_filled_style (create {STYLE}.make_fg ({COLOR}.Bright_magenta)).
				with_unfilled_style (create {STYLE}.make_fg ({COLOR}.Dark_gray))
			a_frame.render_widget (l_line_gauge, l_chunks [3])
		end

	render_middle_dashboard (a_frame: FRAME; a_area: RECT)
			-- Render middle section: Left (Tasks, Logs, BarChart), Right (Waveform Chart).
		local
			l_h_layout: LAYOUT
			l_h_chunks: ARRAY [RECT]
			l_left_area, l_right_area: RECT
		do
			if show_chart then
				create l_h_layout.make_horizontal (<<
					{CONSTRAINTS}.ratio (1, 2),
					{CONSTRAINTS}.ratio (1, 2)
				>>)
				l_h_chunks := l_h_layout.split (a_area)
				l_left_area := l_h_chunks [1]
				l_right_area := l_h_chunks [2]

				render_left_dashboard_column (a_frame, l_left_area)
				render_waveform_chart (a_frame, l_right_area)
			else
				render_left_dashboard_column (a_frame, a_area)
			end
		end

	render_left_dashboard_column (a_frame: FRAME; a_area: RECT)
			-- Render Left Column: Top (Tasks + Logs), Bottom (BarChart).
		local
			l_v_layout: LAYOUT
			l_v_chunks: ARRAY [RECT]
			l_top_area, l_bottom_area: RECT
			l_h_layout: LAYOUT
			l_h_chunks: ARRAY [RECT]
			l_tasks_area, l_logs_area: RECT
		do
			create l_v_layout.make_vertical (<<
				{CONSTRAINTS}.ratio (1, 2),
				{CONSTRAINTS}.ratio (1, 2)
			>>)
			l_v_chunks := l_v_layout.split (a_area)
			l_top_area := l_v_chunks [1]
			l_bottom_area := l_v_chunks [2]

			-- Top: Tasks List & Logs Feed
			create l_h_layout.make_horizontal (<<
				{CONSTRAINTS}.ratio (1, 2),
				{CONSTRAINTS}.ratio (1, 2)
			>>)
			l_h_chunks := l_h_layout.split (l_top_area)
			l_tasks_area := l_h_chunks [1]
			l_logs_area := l_h_chunks [2]

			render_tasks_list (a_frame, l_tasks_area)
			render_logs_feed (a_frame, l_logs_area)
			render_barchart_panel (a_frame, l_bottom_area)
		end

	render_tasks_list (a_frame: FRAME; a_area: RECT)
			-- Render interactive Tasks list widget.
		local
			l_items: ARRAYED_LIST [LIST_ITEM]
			l_item: LIST_ITEM
			l_block: TUI_BLOCK
			l_list: TUI_LIST
			l_sel_style: STYLE
			i: INTEGER
		do
			create l_items.make (tasks_items.count)
			from i := 1 until i > tasks_items.count loop
				create l_item.make_raw (tasks_items [i])
				l_items.extend (l_item)
				i := i + 1
			end

			create l_block.make
			l_block := l_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (create {STYLE}.make_fg ({COLOR}.Bright_blue)).
				with_title (" Tasks (Up/Down) ")

			create l_sel_style.make_with_colors ({COLOR}.Black, {COLOR}.Bright_yellow)
			l_sel_style := l_sel_style.with_bold

			create l_list.make (l_items)
			l_list := l_list.with_block (l_block).
				with_highlight_style (l_sel_style).
				with_highlight_symbol ("> ")

			a_frame.render_stateful_widget (l_list, a_area, tasks_state)
		end

	render_logs_feed (a_frame: FRAME; a_area: RECT)
			-- Render system logs feed with colorized log severity levels.
		local
			l_items: ARRAYED_LIST [LIST_ITEM]
			l_item: LIST_ITEM
			l_block: TUI_BLOCK
			l_list: TUI_LIST
			l_line: TEXT_LINE
			l_lvl_span, l_evt_span: TEXT_SPAN
			l_lvl_style: STYLE
			l_tuple: TUPLE [event, level: STRING_8]
			i: INTEGER
		do
			create l_items.make (logs_items.count)
			from i := 1 until i > logs_items.count loop
				l_tuple := logs_items [i]

				if l_tuple.level.is_equal ("CRITICAL") then
					create l_lvl_style.make_with_colors ({COLOR}.Bright_white, {COLOR}.Red)
					l_lvl_style := l_lvl_style.with_bold
				elseif l_tuple.level.is_equal ("ERROR") then
					create l_lvl_style.make_fg ({COLOR}.Bright_red)
					l_lvl_style := l_lvl_style.with_bold
				elseif l_tuple.level.is_equal ("WARNING") then
					create l_lvl_style.make_fg ({COLOR}.Bright_yellow)
				else
					create l_lvl_style.make_fg ({COLOR}.Bright_cyan)
				end

				create l_line.make_empty
				create l_lvl_span.make (pad_string (l_tuple.level, 10), l_lvl_style)
				create l_evt_span.make (l_tuple.event, create {STYLE}.make_fg ({COLOR}.White))
				l_line.append_span (l_lvl_span)
				l_line.append_span (l_evt_span)

				create l_item.make (create {TEXT}.make (<<l_line>>))
				l_items.extend (l_item)
				i := i + 1
			end

			create l_block.make
			l_block := l_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (create {STYLE}.make_fg ({COLOR}.Bright_magenta)).
				with_title (" System Event Log ")

			create l_list.make (l_items)
			l_list := l_list.with_block (l_block)

			a_frame.render_stateful_widget (l_list, a_area, logs_state)
		end

	render_barchart_panel (a_frame: FRAME; a_area: RECT)
			-- Render BarChart distribution.
		local
			l_block: TUI_BLOCK
			l_chart: TUI_BARCHART
		do
			create l_block.make
			l_block := l_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (create {STYLE}.make_fg ({COLOR}.Bright_green)).
				with_title (" Activity Events (BarChart) ")

			create l_chart.make_with_data (barchart_items)
			l_chart := l_chart.with_block (l_block).
				with_bar_width (3).
				with_bar_gap (2).
				with_bar_style (create {STYLE}.make_fg ({COLOR}.Bright_green)).
				with_label_style (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).
				with_value_style ((create {STYLE}.make_with_colors ({COLOR}.Black, {COLOR}.Bright_green)).with_bold)

			a_frame.render_widget (l_chart, a_area)
		end

	render_waveform_chart (a_frame: FRAME; a_area: RECT)
			-- Render dual-signal oscilloscope chart widget.
		local
			l_block: TUI_BLOCK
			l_chart: TUI_CHART
			l_ds1, l_ds2: TUI_CHART_DATASET
			l_x_labels, l_y_labels: ARRAYED_LIST [STRING_32]
			i: INTEGER
			t: REAL_64
		do
			create l_block.make
			l_block := l_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (create {STYLE}.make_fg ({COLOR}.Bright_cyan)).
				with_title (" Signal Waveforms (Press 't' to Toggle) ")

			create l_ds1.make_with_data ("Sine (data2)", sin1_data)
			l_ds1 := l_ds1.with_style ((create {STYLE}.make_fg ({COLOR}.Bright_cyan)).with_bold)
			l_ds1.set_graph_type ({CHART_GRAPH_TYPE}.line)

			create l_ds2.make_with_data ("Harmonic (data3)", sin2_data)
			l_ds2 := l_ds2.with_style ((create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold)
			l_ds2.set_graph_type ({CHART_GRAPH_TYPE}.line)

			create l_x_labels.make (3)
			from i := 0 until i > 2 loop
				t := window_start + (i.to_double * (window_width / 2.0))
				l_x_labels.extend (t.rounded.out + "s")
				i := i + 1
			end

			create l_y_labels.make (3)
			l_y_labels.extend ("-20.0")
			l_y_labels.extend ("  0.0")
			l_y_labels.extend ("+20.0")

			create l_chart.make
			l_chart := l_chart.with_block (l_block).
				with_x_bounds (window_start, window_start + window_width).
				with_y_bounds (-22.0, 22.0).
				with_x_title ("Time [s]").
				with_y_title ("Amplitude").
				with_x_labels (l_x_labels).
				with_y_labels (l_y_labels).
				with_dataset (l_ds1).
				with_dataset (l_ds2)

			a_frame.render_widget (l_chart, a_area)
		end

	render_footer_block (a_frame: FRAME; a_area: RECT)
			-- Render rich stylized footer paragraph with mixed styles & unicode characters.
		local
			l_block: TUI_BLOCK
			l_para: TUI_PARAGRAPH
			l_text: TEXT
			l_line: TEXT_LINE
		do
			create l_block.make
			l_block := l_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).
				with_title (" System Status & Controls ")

			create l_text.make_empty

			create l_line.make_empty
			l_line.append_span (create {TEXT_SPAN}.make ("Controls: ", (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold))
			l_line.append_span (create {TEXT_SPAN}.make ("[h/l/Left/Right/Tab] ", (create {STYLE}.make_fg ({COLOR}.Bright_white)).with_bold))
			l_line.append_span (create {TEXT_SPAN}.make ("Switch Tabs  ", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_line.append_span (create {TEXT_SPAN}.make ("[j/k/Up/Down] ", (create {STYLE}.make_fg ({COLOR}.Bright_white)).with_bold))
			l_line.append_span (create {TEXT_SPAN}.make ("Select Task  ", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_line.append_span (create {TEXT_SPAN}.make ("[t] ", (create {STYLE}.make_fg ({COLOR}.Bright_white)).with_bold))
			l_line.append_span (create {TEXT_SPAN}.make ("Toggle Chart  ", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_line.append_span (create {TEXT_SPAN}.make ("[q/Esc] ", (create {STYLE}.make_fg ({COLOR}.Bright_red)).with_bold))
			l_line.append_span (create {TEXT_SPAN}.make ("Quit", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_text.append_line (l_line)

			create l_line.make_empty
			l_line.append_span (create {TEXT_SPAN}.make ("Design by Contract: ", (create {STYLE}.make_fg ({COLOR}.Bright_green)).with_bold))
			l_line.append_span (create {TEXT_SPAN}.make ("Preconditions ", create {STYLE}.make_fg ({COLOR}.Bright_cyan)))
			l_line.append_span (create {TEXT_SPAN}.make ("Postconditions ", create {STYLE}.make_fg ({COLOR}.Bright_magenta)))
			l_line.append_span (create {TEXT_SPAN}.make ("Class Invariants ", (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_underline))
			l_line.append_span (create {TEXT_SPAN}.make ("| Unicode currency support: 100%% (100%% = 1000", create {STYLE}.make_fg ({COLOR}.White)))
			l_line.append_span (create {TEXT_SPAN}.make ((8364).to_character_32.out, create {STYLE}.make_fg ({COLOR}.White))) -- Euro symbol €
			l_line.append_span (create {TEXT_SPAN}.make (")", create {STYLE}.make_fg ({COLOR}.White)))
			l_text.append_line (l_line)

			create l_para.make (l_text)
			l_para := l_para.with_block (l_block)
			a_frame.render_widget (l_para, a_area)
		end

feature {NONE} -- Tab 1: Servers & World Map

	render_servers_tab (a_frame: FRAME; a_area: RECT)
			-- Render Tab 1: Server table (30%) and Canvas World Map (70%).
		local
			l_layout: LAYOUT
			l_chunks: ARRAY [RECT]
			l_table_area, l_map_area: RECT
		do
			create l_layout.make_horizontal (<<
				{CONSTRAINTS}.ratio (3, 10),
				{CONSTRAINTS}.ratio (7, 10)
			>>)
			l_chunks := l_layout.split (a_area)
			l_table_area := l_chunks [1]
			l_map_area := l_chunks [2]

			render_servers_table (a_frame, l_table_area)
			render_world_map_canvas (a_frame, l_map_area)
		end

	render_servers_table (a_frame: FRAME; a_area: RECT)
			-- Render server health table.
		local
			l_block: TUI_BLOCK
			l_table: TUI_TABLE
			l_header: TABLE_ROW
			l_rows: ARRAYED_LIST [TABLE_ROW]
			l_row: TABLE_ROW
		do
			create l_block.make
			l_block := l_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (create {STYLE}.make_fg ({COLOR}.Bright_cyan)).
				with_title (" Servers ")

			create l_header.make_raw (<<"Server", "Location", "Status">>)
			l_header := l_header.with_style ((create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold)

			create l_rows.make (4)

			create l_row.make_raw (<<"NorthAmerica-1", "New York", "Up">>)
			l_row := l_row.with_style (create {STYLE}.make_fg ({COLOR}.Bright_green))
			l_rows.extend (l_row)

			create l_row.make_raw (<<"Europe-1", "Paris", "Failure">>)
			l_row := l_row.with_style ((create {STYLE}.make_fg ({COLOR}.Bright_red)).with_bold)
			l_rows.extend (l_row)

			create l_row.make_raw (<<"SouthAmerica-1", "Sao Paulo", "Up">>)
			l_row := l_row.with_style (create {STYLE}.make_fg ({COLOR}.Bright_green))
			l_rows.extend (l_row)

			create l_row.make_raw (<<"Asia-1", "Singapore", "Up">>)
			l_row := l_row.with_style (create {STYLE}.make_fg ({COLOR}.Bright_green))
			l_rows.extend (l_row)

			create l_table.make (
				l_rows,
				<<
					{CONSTRAINTS}.fixed (15),
					{CONSTRAINTS}.fixed (12),
					{CONSTRAINTS}.fixed (8)
				>>
			)
			l_table := l_table.with_block (l_block).with_header (l_header)

			a_frame.render_widget (l_table, a_area)
		end

	render_world_map_canvas (a_frame: FRAME; a_area: RECT)
			-- Render Braille World Map with telemetry routes.
		local
			l_block: TUI_BLOCK
			l_canvas: TUI_CANVAS
		do
			create l_block.make
			l_block := l_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (create {STYLE}.make_fg ({COLOR}.Bright_green)).
				with_title (" Global Node Topography ")

			create l_canvas.make
			l_canvas := l_canvas.with_block (l_block).
				with_bounds (-180.0, 180.0, -90.0, 90.0).
				with_marker ({CANVAS_MARKER}.braille).
				with_painter (agent paint_servers_world_map)

			a_frame.render_widget (l_canvas, a_area)
		end

	paint_servers_world_map (p: CANVAS_PAINTER)
			-- Draw continental outlines and inter-server connection grid.
		local
			l_ny_x, l_ny_y: REAL_64
			l_pa_x, l_pa_y: REAL_64
			l_sp_x, l_sp_y: REAL_64
			l_sg_x, l_sg_y: REAL_64
		do
			-- Lat/Lon Grid
			p.set_style (create {STYLE}.make_fg ({COLOR}.Dark_gray))
			p.draw_line (-180.0, 0.0, 180.0, 0.0)
			p.draw_line (0.0, -90.0, 0.0, 90.0)
			p.draw_line (-180.0, 45.0, 180.0, 45.0)
			p.draw_line (-180.0, -45.0, 180.0, -45.0)

			-- Continents
			p.set_style (create {STYLE}.make_fg ({COLOR}.Dark_gray))
			-- North America
			p.draw_line (-130.0, 50.0, -65.0, 45.0)
			p.draw_line (-65.0, 45.0, -80.0, 25.0)
			p.draw_line (-80.0, 25.0, -115.0, 30.0)
			p.draw_line (-115.0, 30.0, -130.0, 50.0)

			-- South America
			p.draw_line (-80.0, 10.0, -35.0, -5.0)
			p.draw_line (-35.0, -5.0, -70.0, -55.0)
			p.draw_line (-70.0, -55.0, -80.0, 10.0)

			-- Eurasia
			p.draw_line (-10.0, 40.0, 40.0, 60.0)
			p.draw_line (40.0, 60.0, 140.0, 50.0)
			p.draw_line (140.0, 50.0, 100.0, 10.0)
			p.draw_line (100.0, 10.0, -10.0, 40.0)

			-- Africa
			p.draw_line (-15.0, 35.0, 50.0, 30.0)
			p.draw_line (50.0, 30.0, 30.0, -35.0)
			p.draw_line (30.0, -35.0, -15.0, 35.0)

			-- Australia
			p.draw_line (115.0, -20.0, 150.0, -25.0)
			p.draw_line (150.0, -25.0, 140.0, -38.0)
			p.draw_line (140.0, -38.0, 115.0, -20.0)

			-- Server Coordinates: (Longitude = X, Latitude = Y)
			l_ny_x := -74.0; l_ny_y := 40.71  -- New York
			l_pa_x := 2.35;  l_pa_y := 48.85  -- Paris
			l_sp_x := -46.62; l_sp_y := -23.54 -- Sao Paulo
			l_sg_x := 103.86; l_sg_y := 1.35  -- Singapore

			-- Connecting lines
			p.set_style (create {STYLE}.make_fg ({COLOR}.Bright_yellow))
			p.draw_line (l_ny_x, l_ny_y, l_pa_x, l_pa_y)
			p.draw_line (l_pa_x, l_pa_y, l_sg_x, l_sg_y)
			p.draw_line (l_ny_x, l_ny_y, l_sp_x, l_sp_y)
			p.draw_line (l_sp_x, l_sp_y, l_sg_x, l_sg_y)

			-- Highlights: Circle around Sao Paulo
			p.set_style (create {STYLE}.make_fg ({COLOR}.Bright_green))
			p.draw_circle (l_sp_x, l_sp_y, 8.0)

			-- Highlights: Rectangle around Paris
			p.set_style (create {STYLE}.make_fg ({COLOR}.Bright_red))
			p.draw_rect (l_pa_x - 6.0, l_pa_y - 6.0, 12.0, 12.0)

			-- Server Points & Labels
			p.set_style (create {STYLE}.make_fg ({COLOR}.Bright_green))
			p.draw_circle (l_ny_x, l_ny_y, 2.5)
			p.draw_text (l_ny_x + 4.0, l_ny_y - 2.0, "New York (Up)", create {STYLE}.make_fg ({COLOR}.Bright_green))

			p.set_style (create {STYLE}.make_fg ({COLOR}.Bright_red))
			p.draw_circle (l_pa_x, l_pa_y, 2.5)
			p.draw_text (l_pa_x + 4.0, l_pa_y + 2.0, "Paris (Failure)", (create {STYLE}.make_fg ({COLOR}.Bright_red)).with_bold)

			p.set_style (create {STYLE}.make_fg ({COLOR}.Bright_green))
			p.draw_circle (l_sp_x, l_sp_y, 2.5)
			p.draw_text (l_sp_x + 4.0, l_sp_y - 2.0, "Sao Paulo (Up)", create {STYLE}.make_fg ({COLOR}.Bright_green))

			p.set_style (create {STYLE}.make_fg ({COLOR}.Bright_green))
			p.draw_circle (l_sg_x, l_sg_y, 2.5)
			p.draw_text (l_sg_x + 4.0, l_sg_y - 2.0, "Singapore (Up)", create {STYLE}.make_fg ({COLOR}.Bright_green))
		end

feature {NONE} -- Tab 2: Colors Matrix

	render_colors_tab (a_frame: FRAME; a_area: RECT)
			-- Render Tab 2: Color Palette Table and Guidelines.
		local
			l_layout: LAYOUT
			l_chunks: ARRAY [RECT]
			l_table_area, l_info_area: RECT
		do
			create l_layout.make_horizontal (<<
				{CONSTRAINTS}.ratio (1, 2),
				{CONSTRAINTS}.ratio (1, 2)
			>>)
			l_chunks := l_layout.split (a_area)
			l_table_area := l_chunks [1]
			l_info_area := l_chunks [2]

			render_colors_table (a_frame, l_table_area)
			render_colors_guide (a_frame, l_info_area)
		end

	render_colors_table (a_frame: FRAME; a_area: RECT)
			-- Render full table of terminal color palettes.
		local
			l_block: TUI_BLOCK
			l_table: TUI_TABLE
			l_header: TABLE_ROW
			l_rows: ARRAYED_LIST [TABLE_ROW]
			l_row: TABLE_ROW
			l_cell_name, l_cell_fg, l_cell_bg: TEXT_LINE
			l_cols: ARRAY [COLOR]
			l_names: ARRAY [STRING_32]
			i: INTEGER
		do
			create l_block.make
			l_block := l_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (create {STYLE}.make_fg ({COLOR}.Bright_magenta)).
				with_title (" System Colors Matrix ")

			create l_header.make_raw (<<"Color", "Foreground Preview", "Background Preview">>)
			l_header := l_header.with_style ((create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold)

			l_cols := <<
				{COLOR}.Black,
				{COLOR}.Red,
				{COLOR}.Green,
				{COLOR}.Yellow,
				{COLOR}.Blue,
				{COLOR}.Magenta,
				{COLOR}.Cyan,
				{COLOR}.Gray,
				{COLOR}.Dark_gray,
				{COLOR}.Bright_red,
				{COLOR}.Bright_green,
				{COLOR}.Bright_yellow,
				{COLOR}.Bright_blue,
				{COLOR}.Bright_magenta,
				{COLOR}.Bright_cyan,
				{COLOR}.White
			>>
			l_names := <<
				"Black", "Red", "Green", "Yellow",
				"Blue", "Magenta", "Cyan", "Gray",
				"Dark Gray", "Bright Red", "Bright Green", "Bright Yellow",
				"Bright Blue", "Bright Magenta", "Bright Cyan", "White"
			>>

			create l_rows.make (l_cols.count)
			from i := 1 until i > l_cols.count loop
				create l_cell_name.make_raw (l_names [i])

				create l_cell_fg.make_empty
				l_cell_fg.append_span (create {TEXT_SPAN}.make ("AaBbCc 123 ", create {STYLE}.make_fg (l_cols [i])))

				create l_cell_bg.make_empty
				l_cell_bg.append_span (create {TEXT_SPAN}.make (
					" [ BG PREVIEW ] ",
					create {STYLE}.make_with_colors ({COLOR}.Black, l_cols [i])
				))

				create l_row.make (<<
					create {TABLE_CELL}.make_line (l_cell_name),
					create {TABLE_CELL}.make_line (l_cell_fg),
					create {TABLE_CELL}.make_line (l_cell_bg)
				>>)
				l_rows.extend (l_row)
				i := i + 1
			end

			create l_table.make (
				l_rows,
				<<
					{CONSTRAINTS}.fixed (16),
					{CONSTRAINTS}.fixed (18),
					{CONSTRAINTS}.flex (1)
				>>
			)
			l_table := l_table.with_block (l_block).with_header (l_header)

			a_frame.render_widget (l_table, a_area)
		end

	render_colors_guide (a_frame: FRAME; a_area: RECT)
			-- Render informational guide regarding TrueColor and styling.
		local
			l_block: TUI_BLOCK
			l_para: TUI_PARAGRAPH
			l_text: TEXT
			l_heading_style, l_body_style: STYLE
		do
			create l_block.make
			l_block := l_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (create {STYLE}.make_fg ({COLOR}.Bright_cyan)).
				with_title (" Color Architecture Guide ")

			create l_text.make_empty
			l_heading_style := (create {STYLE}.make_fg ({COLOR}.Bright_cyan)).with_bold
			l_body_style := create {STYLE}.make_fg ({COLOR}.Gray)

			l_text.append_line (create {TEXT_LINE}.make_styled ("EiffelTUI Color Hierarchy", l_heading_style))
			l_text.append_line (create {TEXT_LINE}.make_empty)

			l_text.append_line (create {TEXT_LINE}.make_styled ("1. ANSI Standard Colors (16 Colors)", (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold))
			l_text.append_line (create {TEXT_LINE}.make_styled ("   Standard 8 dark shades and 8 high-intensity bright shades.", l_body_style))
			l_text.append_line (create {TEXT_LINE}.make_styled ("   Universal support across VT100 and legacy terminal emulators.", l_body_style))
			l_text.append_line (create {TEXT_LINE}.make_empty)

			l_text.append_line (create {TEXT_LINE}.make_styled ("2. 256-Color Indexed Palette", (create {STYLE}.make_fg ({COLOR}.Bright_green)).with_bold))
			l_text.append_line (create {TEXT_LINE}.make_styled ("   Extended 6x6x6 color cube + 24-step grayscale ramp.", l_body_style))
			l_text.append_line (create {TEXT_LINE}.make_styled ("   Used via {COLOR}.make_indexed (code: NATURAL_8).", l_body_style))
			l_text.append_line (create {TEXT_LINE}.make_empty)

			l_text.append_line (create {TEXT_LINE}.make_styled ("3. 24-Bit TrueColor RGB", (create {STYLE}.make_fg ({COLOR}.Bright_magenta)).with_bold))
			l_text.append_line (create {TEXT_LINE}.make_styled ("   Full 16.7 million true RGB color reproduction.", l_body_style))
			l_text.append_line (create {TEXT_LINE}.make_styled ("   Used via {COLOR}.make_rgb (r, g, b: NATURAL_8).", l_body_style))
			l_text.append_line (create {TEXT_LINE}.make_styled ("   Supports half-block 2D TrueColor graphics rendering.", l_body_style))
			l_text.append_line (create {TEXT_LINE}.make_empty)

			l_text.append_line (create {TEXT_LINE}.make_styled ("4. Style Modifiers", (create {STYLE}.make_fg ({COLOR}.Bright_white)).with_bold))
			l_text.append_line (create {TEXT_LINE}.make_styled ("   Combine styles with .with_bold, .with_italic, .with_underlined,", l_body_style))
			l_text.append_line (create {TEXT_LINE}.make_styled ("   .with_reversed, .with_dim, and .with_crossed_out.", l_body_style))

			create l_para.make (l_text)
			l_para := l_para.with_block (l_block)

			a_frame.render_widget (l_para, a_area)
		end

feature {NONE} -- Helpers

	pad_string (a_str: READABLE_STRING_GENERAL; a_len: INTEGER): STRING_32
			-- Pad string with trailing spaces to `a_len`.
		do
			create Result.make (a_len)
			Result.append_string_general (a_str)
			from until Result.count >= a_len loop
				Result.append_character (' ')
			end
		end

end
