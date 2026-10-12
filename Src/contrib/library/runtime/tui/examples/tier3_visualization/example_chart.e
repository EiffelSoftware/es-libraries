note
	description: "[
		Tier 3 Layout & Visualization Example: Chart & Datasets (Ratatui 1-to-1).
		Real-time animated multi-series oscilloscope plotting sine/cosine signals,
		scatter datasets, labeled X/Y axes, and floating legends.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	EXAMPLE_CHART

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
			-- Initialize and launch Chart showcase.
		local
			l_args: ARGUMENTS_32
			i: INTEGER
		do
			init_state
			Precursor
			set_tick_rate (50) -- 20 FPS
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
			-- Setup signal parameters, initial data points, and window bounds.
		local
			i: INTEGER
			x: REAL_64
			m: DOUBLE_MATH
		do
			create m
			is_running_signal := True
			window_width := 20.0
			window_start := 0.0
			legend_pos := {CHART_LEGEND_POSITION}.top_right

			create data1.make (300)
			create data2.make (300)
			create scatter_data.make (50)

			current_x := 0.0
			from
				i := 0
			until
				i >= 200
			loop
				x := i.to_double * 0.1
				data1.extend ([x, m.sine (x / 2.0) * 18.0])
				data2.extend ([x, m.cosine (x / 1.5) * 12.0])
				if i \\ 10 = 0 then
					scatter_data.extend ([x, m.sine (x / 2.0) * 18.0])
				end
				current_x := x
				i := i + 1
			end
		end

feature {NONE} -- State

	is_running_signal: BOOLEAN
			-- Is real-time waveform animation advancing?

	window_start: REAL_64
			-- Start of visible X-axis time window

	window_width: REAL_64
			-- Width of visible X-axis time window

	current_x: REAL_64
			-- Latest generated X coordinate

	legend_pos: NATURAL_8
			-- Current position of chart legend

	data1: ARRAYED_LIST [TUPLE [x, y: REAL_64]]
			-- Signal 1 waveform points (Sine)

	data2: ARRAYED_LIST [TUPLE [x, y: REAL_64]]
			-- Signal 2 waveform points (Cosine)

	scatter_data: ARRAYED_LIST [TUPLE [x, y: REAL_64]]
			-- Scatter points dataset

	auto_exit_frames: INTEGER
			-- Batch auto-exit counter

	frame_counter: INTEGER
			-- Rendered frame count

feature {NONE} -- Signal Generator

	update_signals
			-- Advance signal generation and slide visible time window.
		local
			i: INTEGER
			x: REAL_64
			m: DOUBLE_MATH
		do
			if is_running_signal then
				create m
				-- Generate 2 new samples per tick
				from i := 1 until i > 2 loop
					current_x := current_x + 0.15
					x := current_x
					data1.extend ([x, m.sine (x / 2.0) * 18.0])
					data2.extend ([x, m.cosine (x / 1.5) * 12.0])

					if (current_x * 10.0).rounded \\ 12 = 0 then
						scatter_data.extend ([x, m.sine (x / 2.0) * 18.0])
					end
					i := i + 1
				end

				-- Slide window to follow signal
				window_start := current_x - window_width

				-- Prune old points to keep memory bounded
				from
				until
					data1.is_empty or else data1.first.x >= (window_start - 5.0)
				loop
					data1.start
					data1.remove
				end

				from
				until
					data2.is_empty or else data2.first.x >= (window_start - 5.0)
				loop
					data2.start
					data2.remove
				end

				from
				until
					scatter_data.is_empty or else scatter_data.first.x >= (window_start - 5.0)
				loop
					scatter_data.start
					scatter_data.remove
				end
			end
		end

feature {NONE} -- Rendering

	render (a_frame: FRAME)
			-- Draw chart view.
		local
			l_main_layout: LAYOUT
			l_main_chunks: ARRAY [RECT]
			l_header_area, l_body_area, l_footer_area: RECT
		do
			if auto_exit_frames > 0 then
				frame_counter := frame_counter + 1
				if frame_counter >= auto_exit_frames then
					stop
				end
			end

			update_signals

			-- Vertical structure: Header(3), Chart View(Flex 1), Footer(2)
			create l_main_layout.make_vertical (<<
				{CONSTRAINTS}.fixed (3),
				{CONSTRAINTS}.flex (1),
				{CONSTRAINTS}.fixed (2)
			>>)
			l_main_chunks := l_main_layout.split (a_frame.area)
			l_header_area := l_main_chunks [1]
			l_body_area := l_main_chunks [2]
			l_footer_area := l_main_chunks [3]

			render_header (a_frame, l_header_area)
			render_chart (a_frame, l_body_area)
			render_footer (a_frame, l_footer_area)
		end

	render_header (a_frame: FRAME; a_area: RECT)
			-- Render header with live signal stats.
		local
			l_para: TUI_PARAGRAPH
			l_text: TEXT
			l_line: TEXT_LINE
			l_status_str: STRING_32
			l_status_style: STYLE
		do
			create l_text.make_empty
			create l_line.make_empty
			l_line.append_span (create {TEXT_SPAN}.make (
				"EiffelTUI Real-Time Oscilloscope & Charting",
				(create {STYLE}.make_fg ({COLOR}.Bright_cyan)).with_bold
			))
			l_line.append_span (create {TEXT_SPAN}.make (
				"  [Ratatui 1-to-1]",
				create {STYLE}.make_fg ({COLOR}.Dark_gray)
			))
			l_text.append_line (l_line)

			create l_line.make_empty
			l_line.append_span (create {TEXT_SPAN}.make ("Status: ", create {STYLE}.make_fg ({COLOR}.Gray)))
			if is_running_signal then
				l_status_str := "Live Streaming"
				l_status_style := (create {STYLE}.make_with_colors ({COLOR}.Black, {COLOR}.Bright_green)).with_bold
			else
				l_status_str := "Paused"
				l_status_style := (create {STYLE}.make_with_colors ({COLOR}.Black, {COLOR}.Bright_yellow)).with_bold
			end
			l_line.append_span (create {TEXT_SPAN}.make (l_status_str, l_status_style))

			l_line.append_span (create {TEXT_SPAN}.make ("  | Time Window: ", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_line.append_span (create {TEXT_SPAN}.make (
				window_start.rounded.out + "s .. " + (window_start + window_width).rounded.out + "s",
				(create {STYLE}.make_fg ({COLOR}.Bright_white)).with_bold
			))
			l_line.append_span (create {TEXT_SPAN}.make ("  | Datasets: ", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_line.append_span (create {TEXT_SPAN}.make ("3 Series (2 Continuous, 1 Scatter)", create {STYLE}.make_fg ({COLOR}.Bright_cyan)))
			l_text.append_line (l_line)

			create l_para.make (l_text)
			a_frame.render_widget (l_para, a_area)
		end

	render_chart (a_frame: FRAME; a_area: RECT)
			-- Render main chart widget.
		local
			l_block: TUI_BLOCK
			l_chart: TUI_CHART
			l_ds1, l_ds2, l_ds_scatter: TUI_CHART_DATASET
			l_x_labels, l_y_labels: ARRAYED_LIST [STRING_32]
			i: INTEGER
			t: REAL_64
		do
			create l_block.make
			l_block := l_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (create {STYLE}.make_fg ({COLOR}.Bright_cyan)).
				with_title (" Real-Time Frequency Waveform Analyzer ")

			-- Series 1: Sine Wave
			create l_ds1.make_with_data ("Sine Wave (18V Peak)", data1)
			l_ds1 := l_ds1.with_style ((create {STYLE}.make_fg ({COLOR}.Bright_cyan)).with_bold)
			l_ds1.set_graph_type ({CHART_GRAPH_TYPE}.line)

			-- Series 2: Cosine Wave
			create l_ds2.make_with_data ("Cosine Harmonic (12V)", data2)
			l_ds2 := l_ds2.with_style ((create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold)
			l_ds2.set_graph_type ({CHART_GRAPH_TYPE}.line)

			-- Series 3: Scatter Peaks
			create l_ds_scatter.make_with_data ("Peak Samples", scatter_data)
			l_ds_scatter := l_ds_scatter.with_style ((create {STYLE}.make_fg ({COLOR}.Bright_magenta)).with_bold)
			l_ds_scatter.set_graph_type ({CHART_GRAPH_TYPE}.scatter)
			l_ds_scatter.set_marker ({CANVAS_MARKER}.dot)

			-- X-axis labels
			create l_x_labels.make (5)
			from i := 0 until i > 4 loop
				t := window_start + (i.to_double * (window_width / 4.0))
				l_x_labels.extend (t.rounded.out + "s")
				i := i + 1
			end

			-- Y-axis labels
			create l_y_labels.make (5)
			l_y_labels.extend ("-20V")
			l_y_labels.extend ("-10V")
			l_y_labels.extend ("  0V")
			l_y_labels.extend ("+10V")
			l_y_labels.extend ("+20V")

			create l_chart.make
			l_chart := l_chart.with_block (l_block).
				with_x_bounds (window_start, window_start + window_width).
				with_y_bounds (-25.0, 25.0).
				with_x_title ("Time (seconds)").
				with_y_title ("Amplitude (Volts)").
				with_x_labels (l_x_labels).
				with_y_labels (l_y_labels).
				with_axis_style (create {STYLE}.make_fg ({COLOR}.Dark_gray)).
				with_legend (True, legend_pos).
				with_dataset (l_ds1).
				with_dataset (l_ds2).
				with_dataset (l_ds_scatter)
			-- The legend (23 x 5) is hidden when it exceeds this share of the plot. The default
			-- 1/4 would need a plot of 92 x 20 or more; 1/2 (as in Ratatui's chart example)
			-- shows it, and lets [Tab] move it, from an 80 x 24 terminal up.
			l_chart.set_legend_hidden_ratio (0.5)

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
			l_line.append_span (create {TEXT_SPAN}.make ("[Space] ", (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold))
			l_line.append_span (create {TEXT_SPAN}.make ("Pause/Resume  ", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_line.append_span (create {TEXT_SPAN}.make ("[Tab] ", (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold))
			l_line.append_span (create {TEXT_SPAN}.make ("Cycle Legend  ", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_line.append_span (create {TEXT_SPAN}.make ("[+/-] ", (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold))
			l_line.append_span (create {TEXT_SPAN}.make ("Window Zoom  ", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_line.append_span (create {TEXT_SPAN}.make ("[q/Esc] ", (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold))
			l_line.append_span (create {TEXT_SPAN}.make ("Quit", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_text.append_line (l_line)

			create l_para.make (l_text)
			l_para := l_para.with_alignment ({TEXT_ALIGNMENT}.center)
			a_frame.render_widget (l_para, a_area)
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
					elseif ch = ' ' then
						is_running_signal := not is_running_signal
					elseif ch = '%T' then
						legend_pos := (legend_pos \\ 4) + 1
					elseif ch = '+' or ch = '=' then
						if window_width > 5.0 then
							window_width := window_width - 2.0
						end
					elseif ch = '-' or ch = '_' then
						if window_width < 50.0 then
							window_width := window_width + 2.0
						end
					end
				elseif k.code.is_tab then
					legend_pos := (legend_pos \\ 4) + 1
				end
			end
		end

end
