note
	description: "[
		Tier 5 Advanced Example: File Logging & Tracing (Ratatui 1-to-1).
		Demonstrates non-blocking structured file logging to `tui_trace.log`
		without corrupting terminal escape sequences or screen buffers.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	EXAMPLE_LOGGING

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
			-- Initialize and launch Logging & Tracing example.
		local
			l_args: ARGUMENTS_32
			i: INTEGER
		do
			init_logger
			Precursor
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
			close_logger
		end

	make_batch (a_frames: INTEGER)
			-- Initialize and run for `a_frames` frames in batch mode.
		do
			init_logger
			make_with_viewport (create {VIEWPORT}.make_fullscreen)
			set_tick_rate (50)
			auto_exit_frames := a_frames
			frame_counter := 0
			run
			close_logger
		end

feature {NONE} -- State

	auto_exit_frames: INTEGER
	frame_counter: INTEGER

	log_file: detachable PLAIN_TEXT_FILE
	log_path: STRING = "tui_trace.log"
	total_logs_written: INTEGER

	recent_events: ARRAYED_LIST [STRING_32]
	manual_log_counter: INTEGER

feature {NONE} -- Setup & File Logger

	init_logger
			-- Open log file and write startup header.
		local
			l_f: PLAIN_TEXT_FILE
		do
			create recent_events.make (20)
			manual_log_counter := 0
			total_logs_written := 0

			create l_f.make_create_read_write (log_path)
			log_file := l_f
			write_log_line ("INFO", "EiffelTUI logging subsystem initialized. Target: " + log_path)
		end

	close_logger
			-- Flush and close log file.
		do
			if attached log_file as l_f and then not l_f.is_closed then
				write_log_line ("INFO", "EiffelTUI application shutting down cleanly. Flushing logs.")
				l_f.close
			end
		end

	write_log_line (a_level, a_msg: READABLE_STRING_GENERAL)
			-- Write formatted line to disk and push to UI buffer.
		local
			l_entry: STRING_32
			l_now: INTEGER_64
		do
			l_now := {MONOTONIC_CLOCK}.milliseconds
			total_logs_written := total_logs_written + 1

			create l_entry.make (128)
			l_entry.append_character ('[')
			l_entry.append_string_general (a_level)
			l_entry.append ("] [T+")
			l_entry.append_integer_64 (l_now)
			l_entry.append ("ms] ")
			l_entry.append_string_general (a_msg)

			-- Write to file without polluting stdout
			if attached log_file as l_f and then l_f.is_open_write then
				l_f.put_string (l_entry.to_string_8)
				l_f.put_new_line
				l_f.flush
			end

			-- Push to in-memory UI buffer (capped at 14 items)
			recent_events.extend (l_entry)
			if recent_events.count > 14 then
				recent_events.start
				recent_events.remove
			end
		end

feature {NONE} -- Application Hooks

	render (a_frame: FRAME)
			-- Render logging feed and status dashboard.
		local
			l_v_layout, l_h_layout: LAYOUT
			l_v_chunks, l_h_chunks: ARRAY [RECT]
			l_title_area, l_body_area, l_footer_area: RECT
			l_feed_area, l_status_area: RECT
			l_title_para, l_feed_para, l_stat_para, l_foot_para: TUI_PARAGRAPH
			l_feed_block, l_stat_block: TUI_BLOCK
			l_lines: ARRAYED_LIST [TEXT_LINE]
			l_line: TEXT_LINE
			l_b_style, l_title_style, l_stat_style, l_warn_style, l_dim_style: STYLE
			i: INTEGER
		do
			if auto_exit_frames > 0 then
				frame_counter := frame_counter + 1
				if frame_counter >= auto_exit_frames then
					stop
				end
			end

			-- Layout: Title (2), Body (fill), Footer (2)
			create l_v_layout.make_vertical (<<
				{CONSTRAINTS}.fixed (2),
				{CONSTRAINTS}.flex (1),
				{CONSTRAINTS}.fixed (2)
			>>)
			l_v_chunks := l_v_layout.split (a_frame.area)
			l_title_area := l_v_chunks [1]
			l_body_area := l_v_chunks [2]
			l_footer_area := l_v_chunks [3]

			-- 1. Title
			create l_title_style.make_fg ({COLOR}.Bright_cyan)
			l_title_style := l_title_style.with_bold
			create l_title_para.make (create {TEXT}.make_styled ("Diagnostic File Logging & Tracing Center", l_title_style))
			a_frame.render_widget (l_title_para, l_title_area)

			-- 2. Body: Left Feed (65%), Right Status (35%)
			create l_h_layout.make_horizontal (<<
				{CONSTRAINTS}.percentage (65),
				{CONSTRAINTS}.percentage (35)
			>>)
			l_h_chunks := l_h_layout.split (l_body_area)
			l_feed_area := l_h_chunks [1]
			l_status_area := l_h_chunks [2]

			-- Feed Block
			create l_b_style.make_fg ({COLOR}.Bright_yellow)
			create l_feed_block.make
			l_feed_block := l_feed_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (l_b_style).
				with_title (" Real-time Event Feed (Last 14) ")

			create l_lines.make (recent_events.count)
			create l_dim_style.make_fg ({COLOR}.White)
			from i := 1 until i > recent_events.count loop
				create l_line.make_styled (recent_events [i], l_dim_style)
				l_lines.extend (l_line)
				i := i + 1
			end
			create l_feed_para.make (create {TEXT}.make (l_lines))
			l_feed_para := l_feed_para.with_block (l_feed_block)
			a_frame.render_widget (l_feed_para, l_feed_area)

			-- Status Block
			create l_b_style.make_fg ({COLOR}.Bright_green)
			create l_stat_block.make
			l_stat_block := l_stat_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (l_b_style).
				with_title (" Logger Status ")

			create l_stat_style.make_fg ({COLOR}.Green)
			create l_warn_style.make_fg ({COLOR}.Bright_yellow)
			create l_lines.make (8)
			l_lines.extend (create {TEXT_LINE}.make_styled ("Log File: " + log_path, l_stat_style))
			l_lines.extend (create {TEXT_LINE}.make_styled ("Mode: Non-blocking disk append", l_dim_style))
			l_lines.extend (create {TEXT_LINE}.make_raw (""))
			l_lines.extend (create {TEXT_LINE}.make_styled ("Total Log Records: " + total_logs_written.out, l_warn_style))
			l_lines.extend (create {TEXT_LINE}.make_styled ("Terminal stdout: Isolated & clean", l_stat_style))
			l_lines.extend (create {TEXT_LINE}.make_raw (""))
			l_lines.extend (create {TEXT_LINE}.make_styled ("Inspect " + log_path + " in an external", l_dim_style))
			l_lines.extend (create {TEXT_LINE}.make_styled ("editor to view live records.", l_dim_style))

			create l_stat_para.make (create {TEXT}.make (l_lines))
			l_stat_para := l_stat_para.with_block (l_stat_block)
			a_frame.render_widget (l_stat_para, l_status_area)

			-- 3. Footer
			create l_foot_para.make (create {TEXT}.make_styled ("Press [l] Log test record  |  [c] Clear UI buffer  |  [q] Quit", create {STYLE}.make_fg ({COLOR}.Dark_gray)))
			l_foot_para := l_foot_para.with_alignment ({TEXT_ALIGNMENT}.center)
			a_frame.render_widget (l_foot_para, l_footer_area)
		end

	process (a_event: EVENT)
			-- Process key events and log interactions.
		do
			if attached {KEY_EVENT} a_event as k then
				if k.is_press then
					if k.code.is_escape or else (k.code.is_char and then (k.code.character = 'q' or k.code.character = 'Q')) then
						write_log_line ("INFO", "User requested termination via keypress.")
						stop
					elseif k.code.is_char and then (k.code.character = 'l' or k.code.character = 'L') then
						manual_log_counter := manual_log_counter + 1
						write_log_line ("DEBUG", "Manual diagnostic event triggered #" + manual_log_counter.out)
					elseif k.code.is_char and then (k.code.character = 'c' or k.code.character = 'C') then
						recent_events.wipe_out
						write_log_line ("INFO", "In-memory UI event log buffer cleared by user.")
					else
						write_log_line ("TRACE", "Key pressed: " + k.code.out)
					end
				end
			end
		end

end
