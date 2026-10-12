note
	description: "[
		EiffelTUI Interactive Demonstration Application.
		Inherits TUI_APPLICATION, managing the event thread (Eiffel Threads, no SCOOP),
		input parser (CSI keys, Arrows, SGR mouse), layout solver, and differential rendering.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	HELLO_TUI

inherit
	TUI_APPLICATION
		redefine
			make
		end

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize and launch interactive TUI demo.
		local
			l_args: ARGUMENTS_32
		do
			Precursor
			-- Key release / repeat events where the terminal supports them (Kitty protocol, Windows console)
			set_keyboard_enhancement (True)
			counter := 0
			last_event_description := {STRING_32} "None (Waiting for key...)"

			create tabs_state.make
			create nav_state.make
			nav_state.select_index (1)
			create table_state.make
			table_state.select_index (1)

			create event_history.make (16)
			event_history.extend ("System initialized")

			-- Layouts are immutable values, built once. Neighbouring panels overlap by one cell
			-- (`Shared_border`) so that each pair of blocks shares a single, merged border.
			create root_layout.make_with_all ({SPLIT_DIRECTION}.vertical,
				<<{CONSTRAINTS}.fixed (3), {CONSTRAINTS}.flex (1), {CONSTRAINTS}.fixed (3)>>,
				create {MARGIN}.default_create, Shared_border, {FLEX_JUSTIFY}.start_align)
			create body_layout.make_with_all ({SPLIT_DIRECTION}.horizontal,
				<<{CONSTRAINTS}.ratio (1, 4), {CONSTRAINTS}.ratio (3, 4)>>,
				create {MARGIN}.default_create, Shared_border, {FLEX_JUSTIFY}.start_align)
			create dash_split_layout.make_with_all ({SPLIT_DIRECTION}.vertical,
				<<{CONSTRAINTS}.fixed (5), {CONSTRAINTS}.flex (1)>>,
				create {MARGIN}.default_create, Shared_border, {FLEX_JUSTIFY}.start_align)
			create dash_metrics_layout.make_with_all ({SPLIT_DIRECTION}.horizontal,
				<<{CONSTRAINTS}.flex (1), {CONSTRAINTS}.fixed (20)>>,
				create {MARGIN}.default_create, Shared_border, {FLEX_JUSTIFY}.start_align)
			create gauge_spark_layout.make_with_all ({SPLIT_DIRECTION}.vertical,
				<<{CONSTRAINTS}.fixed (3), {CONSTRAINTS}.flex (1)>>,
				create {MARGIN}.default_create, Shared_border, {FLEX_JUSTIFY}.start_align)

			-- Check if running in auto-exit batch mode
			create l_args
			if l_args.argument_count > 0 and then l_args.argument (1).is_equal ("-batch") then
				auto_exit_frames := 10
			else
				auto_exit_frames := -1
			end
			frame_counter := 0

			run
		end

feature {NONE} -- Event Handling

	process (a_event: EVENT)
			-- Process user input and system events.
		local
			l_desc: STRING_32
		do
			if attached {KEY_EVENT} a_event as ev then
				l_desc := {STRING_32} "Key: " + ev.code.out.to_string_32 + {STRING_32} " [" + ev.modifiers.out.to_string_32 + {STRING_32} "]"
				if ev.is_release then
					l_desc.append ({STRING_32} " (Release)")
				elseif ev.is_repeat then
					l_desc.append ({STRING_32} " (Repeat)")
				else
					l_desc.append ({STRING_32} " (Press)")
				end
				last_event_description := l_desc
				event_history.extend (l_desc)
				if event_history.count > 20 then
					event_history.remove_i_th (1)
				end

				if ev.is_press or ev.is_repeat then
					-- Act on presses and auto-repeat, not on releases
					if ev.code.is_char then
						if ev.code.character = 'q' or ev.code.character = 'Q' then
							stop
						elseif ev.code.character = '1' then
							tabs_state.select_index (1)
						elseif ev.code.character = '2' then
							tabs_state.select_index (2)
						elseif ev.code.character = '3' then
							tabs_state.select_index (3)
						elseif ev.code.character = '4' then
							tabs_state.select_index (4)
						elseif ev.code.character = '+' or ev.code.character = '=' then
							counter := counter + 1
						elseif ev.code.character = '-' then
							counter := counter - 1
						end
					elseif ev.code.is_tab then
						if ev.modifiers.is_shift then
							tabs_state.select_previous (4)
						else
							tabs_state.select_next (4)
						end
					elseif ev.code.is_left then
						tabs_state.select_previous (4)
					elseif ev.code.is_right then
						tabs_state.select_next (4)
					elseif ev.code.is_up then
						if tabs_state.selected = 2 then
							table_state.select_previous (5)
						else
							nav_state.select_previous (8)
						end
					elseif ev.code.is_down then
						if tabs_state.selected = 2 then
							table_state.select_next (5)
						else
							nav_state.select_next (8)
						end
					elseif ev.code.is_escape then
						stop
					end
				end
			elseif attached {MOUSE_EVENT} a_event as ev_m then
				l_desc := {STRING_32} "Mouse: col=" + ev_m.column.out.to_string_32 + {STRING_32} ", row=" + ev_m.row.out.to_string_32
				last_event_description := l_desc
				event_history.extend (l_desc)
				if event_history.count > 20 then
					event_history.remove_i_th (1)
				end
			end
		end

feature {NONE} -- Rendering

	render (a_frame: FRAME)
			-- Render multi-panel interactive layout into `a_frame` using Phase 6 widgets.
		local
			a_buffer: BUFFER
			l_screen_rect: RECT
			l_rows: ARRAYED_LIST [RECT]
			l_body_cols: ARRAYED_LIST [RECT]
			l_header_rect, l_body_rect, l_footer_rect: RECT
			l_side_rect, l_main_rect, l_side_inner: RECT
			l_title_style, l_border_style, l_text_style, l_accent_style, l_hl_style: STYLE
			l_header_block, l_side_block, l_main_block, l_footer_block: TUI_BLOCK
			l_tabs: TUI_TABS
			l_list: TUI_LIST
			l_list_sb: TUI_SCROLLBAR
			l_list_sb_state: SCROLLBAR_STATE
			l_table: TUI_TABLE
			l_tbl_hdr, l_tbl_ftr: TABLE_ROW
			l_row1, l_row2, l_row3, l_row4, l_row5: TABLE_ROW
			l_p_main, l_p_footer: TUI_PARAGRAPH
			l_t_main, l_t_footer: TEXT
			l_line: TEXT_LINE
			l_span1, l_span2: TEXT_SPAN
			l_dash_rows, l_dash_metrics, l_gauge_spark: ARRAYED_LIST [RECT]
			l_gauge: TUI_LINE_GAUGE
			l_spark: TUI_SPARKLINE
			l_chart: TUI_BARCHART
			l_b1, l_b2, l_b3: BAR_ITEM
			l_gauge_block, l_spark_block, l_chart_block: TUI_BLOCK
			l_cnt_pct: NATURAL_16
			l_chart_widget: TUI_CHART
			l_ds_sin, l_ds_cos: TUI_CHART_DATASET
			l_math: DOUBLE_MATH
			l_step_idx: INTEGER
			l_x_val, l_y_sin, l_y_cos: REAL_64
			i: INTEGER
		do
			a_buffer := a_frame.buffer
			frame_counter := frame_counter + 1
			if auto_exit_frames > 0 and frame_counter >= auto_exit_frames then
				stop
			end

			-- Setup styles
			create l_border_style.make_fg ({COLOR}.cyan)
			create l_title_style.make_fg ({COLOR}.bright_yellow)
			l_title_style := l_title_style.with_bold
			create l_text_style.make_fg ({COLOR}.bright_green)
			create l_accent_style.make_fg (create {COLOR}.make_rgb (255, 128, 0))
			l_accent_style := l_accent_style.with_bold
			create l_hl_style.make_fg ({COLOR}.bright_yellow)
			l_hl_style := l_hl_style.with_bold

			-- Layout: Header (3), Body (Flex 1), Footer (3) with border overlap
			create l_screen_rect.make (0, 0, a_buffer.width.to_natural_16, a_buffer.height.to_natural_16)
			l_rows := root_layout.split_list (l_screen_rect)
			l_header_rect := l_rows.i_th (1)
			l_body_rect := l_rows.i_th (2)
			l_footer_rect := l_rows.i_th (3)

			-- Split Body: Sidebar (1/4) and Main (3/4) with border overlap
			l_body_cols := body_layout.split_list (l_body_rect)
			l_side_rect := l_body_cols.i_th (1)
			l_main_rect := l_body_cols.i_th (2)

			-- 1. Header with TUI_TABS
			create l_header_block.make
			l_header_block.set_border_type ({BORDER_TYPE}.rounded)
			l_header_block.set_border_style (l_border_style)
			l_header_block.set_border_merged (True)
			l_header_block.set_title_string (" EiffelTUI Navigation ")

			create l_tabs.make_from_strings (<<"[1] Dashboard", "[2] Processes", "[3] Braille Chart", "[4] Event Log">>)
			l_tabs.set_block (l_header_block)
			l_tabs.set_highlight_style (l_hl_style)
			l_tabs.set_divider ("  |  ")
			l_tabs.render_stateful (l_header_rect, a_buffer, tabs_state)

			-- 2. Sidebar with TUI_LIST, LIST_STATE & TUI_SCROLLBAR
			create l_side_block.make
			l_side_block.set_border_type ({BORDER_TYPE}.rounded)
			l_side_block.set_border_style (l_border_style)
			l_side_block.set_border_merged (True)
			l_side_block.set_title_string (" Modules ")

			create l_list.make_empty
			l_list.append_raw_item ("Core Engine")
			l_list.append_raw_item ("Layout Solver")
			l_list.append_raw_item ("Table Widget")
			l_list.append_raw_item ("Scrollbar")
			l_list.append_raw_item ("Event Threads")
			l_list.append_raw_item ("ANSI Parser")
			l_list.append_raw_item ("Diff Engine")
			l_list.append_raw_item ("Virtual Term")
			l_list.set_highlight_symbol ("> ")
			l_list.set_highlight_style (l_accent_style)

			-- The block is drawn on its own so that the list can leave its last inner column
			-- to the scrollbar (the right border is shared with the main panel and carries its
			-- junctions, so the scrollbar cannot go there).
			l_side_block.render (l_side_rect, a_buffer)
			l_side_inner := l_side_block.inner (l_side_rect)
			if l_side_inner.width >= 2 and l_side_inner.height > 0 then
				l_list.render_list (create {RECT}.make (l_side_inner.x, l_side_inner.y, l_side_inner.width - 1, l_side_inner.height),
					a_buffer, nav_state)

				create l_list_sb.make ({SCROLLBAR_ORIENTATION}.vertical_right)
				create l_list_sb_state.make (l_list.count)
				l_list_sb_state.set_viewport_content_length (l_side_inner.height.to_integer_32)
				if nav_state.has_selection then
					l_list_sb_state.set_position (nav_state.selected - 1)
				end
				l_list_sb.set_track_symbol ({STRING_32} "%/0x2591/")
				l_list_sb.set_thumb_style (l_accent_style)
				l_list_sb.set_track_style (l_border_style)
				l_list_sb.render_scrollbar (create {RECT}.make (l_side_inner.right - 1, l_side_inner.y, 1, l_side_inner.height),
					a_buffer, l_list_sb_state)
			else
				l_list.render_list (l_side_inner, a_buffer, nav_state)
			end

			-- 3. Main Panel (Content depends on active tab)
			create l_main_block.make
			l_main_block.set_border_type ({BORDER_TYPE}.rounded)
			l_main_block.set_border_style (l_border_style)
			l_main_block.set_border_merged (True)

			create l_t_main.make_empty

			if tabs_state.selected = 1 then
				-- Tab 1: Dashboard with live metrics
				l_dash_rows := dash_split_layout.split_list (l_main_rect)

				-- Upper block: Dashboard info
				l_main_block.set_title_string (" Interactive Dashboard ")

				create l_line.make_empty
				create l_span1.make_raw ("Live Counter:   ")
				create l_span2.make ("[" + counter.out + "] (Press '+' or '-' to change)", l_title_style)
				l_line.append_span (l_span1)
				l_line.append_span (l_span2)
				l_t_main.append_line (l_line)

				create l_line.make_empty
				create l_span1.make_raw ("Last Event:     ")
				create l_span2.make (last_event_description, l_accent_style)
				l_line.append_span (l_span1)
				l_line.append_span (l_span2)
				l_t_main.append_line (l_line)

				create l_line.make_styled ("Navigation:     Use [Up]/[Down] for lists/tables, [Tab]/[1..4] for tabs", l_text_style)
				l_t_main.append_line (l_line)

				create l_p_main.make (l_t_main)
				l_p_main.set_block (l_main_block)
				l_p_main.set_wrap_mode ({TEXT_WRAP_MODE}.word, True)
				l_p_main.render (l_dash_rows.i_th (1), a_buffer)

				-- Lower section: Metrics (Split horizontally into Gauge+Sparkline and BarChart)
				l_dash_metrics := dash_metrics_layout.split_list (l_dash_rows.i_th (2))

				-- Left metrics: Gauge (top) and Sparkline (bottom)
				l_gauge_spark := gauge_spark_layout.split_list (l_dash_metrics.i_th (1))

				-- Line Gauge
				create l_gauge_block.make
				l_gauge_block.set_border_type ({BORDER_TYPE}.rounded)
				l_gauge_block.set_border_style (l_border_style)
				l_gauge_block.set_border_merged (True)
				l_gauge_block.set_title_string (" Counter Meter ")

				l_cnt_pct := ((counter.abs * 10) \\ 101).to_natural_16
				create l_gauge.make
				l_gauge.set_percent (l_cnt_pct)
				l_gauge.set_filled_style (l_accent_style)
				l_gauge.set_block (l_gauge_block)
				l_gauge.render (l_gauge_spark.i_th (1), a_buffer)

				-- Sparkline
				create l_spark_block.make
				l_spark_block.set_border_type ({BORDER_TYPE}.rounded)
				l_spark_block.set_border_style (l_border_style)
				l_spark_block.set_border_merged (True)
				l_spark_block.set_title_string (" Activity Velocity ")

				create l_spark.make_with_data (<<{NATURAL_64} 15, {NATURAL_64} 30, {NATURAL_64} 25, {NATURAL_64} 60, {NATURAL_64} 45, {NATURAL_64} 80, {NATURAL_64} 70, {NATURAL_64} 95, {NATURAL_64} 85, {NATURAL_64} 100, {NATURAL_64} 75, {NATURAL_64} 90>>)
				l_spark.set_style (l_title_style)
				l_spark.set_block (l_spark_block)
				l_spark.render (l_gauge_spark.i_th (2), a_buffer)

				-- Right metrics: BarChart
				create l_chart_block.make
				l_chart_block.set_border_type ({BORDER_TYPE}.rounded)
				l_chart_block.set_border_style (l_border_style)
				l_chart_block.set_border_merged (True)
				l_chart_block.set_title_string (" System Load ")

				create l_b1.make ("CPU", 68)
				create l_b2.make ("MEM", 42)
				create l_b3.make ("NET", 85)
				create l_chart.make_with_data (<<l_b1, l_b2, l_b3>>)
				l_chart.set_bar_width (3)
				l_chart.set_bar_gap (2)
				l_chart.set_bar_style (l_accent_style)
				l_chart.set_value_style (l_title_style)
				l_chart.set_label_style (l_text_style)
				l_chart.set_block (l_chart_block)
				l_chart.render (l_dash_metrics.i_th (2), a_buffer)

			elseif tabs_state.selected = 2 then
				-- Tab 2: System Processes Table
				l_main_block.set_title_string (" System Processes (TUI_TABLE) ")

				create l_table.default_create
				create l_tbl_hdr.make_raw (<<"PID", "NAME", "CPU%%", "MEM", "STATUS">>)
				l_tbl_hdr.set_style (l_title_style)
				l_table.set_header (l_tbl_hdr)

				create l_row1.make_raw (<<"101", "eiffeltui_gui", "0.8%%", "18.4 MB", "RUNNING">>)
				create l_row2.make_raw (<<"204", "layout_solver", "1.2%%", "12.1 MB", "ACTIVE">>)
				create l_row3.make_raw (<<"315", "diff_engine", "0.4%%", "8.2 MB", "IDLE">>)
				create l_row4.make_raw (<<"480", "term_reader", "0.1%%", "4.5 MB", "WAITING">>)
				create l_row5.make_raw (<<"512", "ansi_serializer", "0.3%%", "6.7 MB", "RUNNING">>)

				l_table.append_row (l_row1)
				l_table.append_row (l_row2)
				l_table.append_row (l_row3)
				l_table.append_row (l_row4)
				l_table.append_row (l_row5)

				create l_tbl_ftr.make_raw (<<"TOTAL", "5 tasks", "2.8%%", "49.9 MB", "HEALTHY">>)
				l_tbl_ftr.set_style (l_accent_style)
				l_table.set_footer (l_tbl_ftr)

				l_table.set_widths (<<{CONSTRAINTS}.fixed (6), {CONSTRAINTS}.flex (1), {CONSTRAINTS}.fixed (8), {CONSTRAINTS}.fixed (10), {CONSTRAINTS}.fixed (10)>>)
				l_table.set_column_spacing (2)
				l_table.set_block (l_main_block)
				l_table.set_highlight_symbol ("> ")
				l_table.set_row_highlight_style (l_hl_style)
				l_table.render_stateful (l_main_rect, a_buffer, table_state)

			elseif tabs_state.selected = 3 then
				-- Tab 3: Braille Vector Chart
				l_main_block.set_title_string (" Braille 2D Vector Chart (TUI_CHART) ")

				create l_math
				create l_ds_sin.make ("Sine")
				l_ds_sin.set_style (l_accent_style)
				create l_ds_cos.make ("Cosine")
				l_ds_cos.set_style (l_title_style)

				from
					l_step_idx := 0
				until
					l_step_idx > 40
				loop
					l_x_val := l_step_idx.to_double / 4.0
					l_y_sin := 5.0 + 4.0 * l_math.sine (l_x_val + frame_counter.to_double * 0.15)
					l_y_cos := 5.0 + 4.0 * l_math.cosine (l_x_val + frame_counter.to_double * 0.15)
					l_ds_sin.append_point (l_x_val, l_y_sin)
					l_ds_cos.append_point (l_x_val, l_y_cos)
					l_step_idx := l_step_idx + 1
				end

				create l_chart_widget.make_with_datasets (<<l_ds_sin, l_ds_cos>>)
				l_chart_widget.set_x_bounds (0.0, 10.0)
				l_chart_widget.set_y_bounds (0.0, 10.0)
				l_chart_widget.set_x_labels (<<"0.0", "2.5", "5.0", "7.5", "10.0">>)
				l_chart_widget.set_y_labels (<<"10.0", "5.0", "0.0">>)
				l_chart_widget.set_axis_style (l_text_style)
				l_chart_widget.set_block (l_main_block)
				l_chart_widget.render (l_main_rect, a_buffer)

			else
				-- Tab 4: Event Log
				l_main_block.set_title_string (" Recent Event Log ")

				from
					i := event_history.count
				until
					i < 1 or (event_history.count - i) >= 8
				loop
					create l_line.make_styled ({STRING_32} "# " + event_history.i_th (i), l_text_style)
					l_t_main.append_line (l_line)
					i := i - 1
				end

				create l_p_main.make (l_t_main)
				l_p_main.set_block (l_main_block)
				l_p_main.set_wrap_mode ({TEXT_WRAP_MODE}.word, True)
				l_p_main.render (l_main_rect, a_buffer)
			end

			-- 4. Footer
			create l_footer_block.make
			l_footer_block.set_border_type ({BORDER_TYPE}.rounded)
			l_footer_block.set_border_style (l_border_style)
			l_footer_block.set_border_merged (True)
			l_footer_block.set_title_string (" Status ")

			create l_t_footer.make_styled ("Frame #" + frame_counter.out + " | Keys: [1..4] Tabs | [Up/Down] Navigate | [+/-] Counter | [q] Exit", l_text_style)
			create l_p_footer.make (l_t_footer)
			l_p_footer.set_block (l_footer_block)
			l_p_footer.render (l_footer_rect, a_buffer)
		end

feature {NONE} -- Layouts

	Shared_border: INTEGER = -1
			-- Spacing that makes neighbouring blocks overlap by one cell and share their border

	root_layout: LAYOUT
			-- Top-level vertical split: Header, Body, Footer with 1-cell border overlap.

	body_layout: LAYOUT
			-- Body horizontal split: Sidebar and Main panel with 1-cell border overlap.

	dash_split_layout: LAYOUT
			-- Tab 1 vertical split: Upper dashboard info and Lower metrics with 1-cell border overlap.

	dash_metrics_layout: LAYOUT
			-- Tab 1 horizontal split: Left gauges/sparkline and Right barchart with 1-cell border overlap.

	gauge_spark_layout: LAYOUT
			-- Tab 1 vertical split: Line Gauge and Sparkline with 1-cell border overlap.

feature {NONE} -- State

	counter: INTEGER
	last_event_description: STRING_32
	auto_exit_frames: INTEGER
	frame_counter: INTEGER
	tabs_state: TABS_STATE
	nav_state: LIST_STATE
	table_state: TABLE_STATE
	event_history: ARRAYED_LIST [STRING_32]

end
