note
	description: "[
		Tier 5 Advanced Example: Advanced Widget Implementation (Ratatui 1-to-1).
		Demonstrates advanced widget rendering patterns: ephemeral widgets, persistent
		timer widgets, boxed shape widgets, and mutable dynamic bouncing position widgets.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	EXAMPLE_ADVANCED_WIDGET

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
			-- Initialize and launch Advanced Widget example.
		local
			l_args: ARGUMENTS_32
			i: INTEGER
		do
			init_state
			Precursor
			set_tick_rate (30) -- ~33 FPS
			create l_args
			auto_exit_frames := -1
			from i := 1 until i > l_args.argument_count loop
				if l_args.argument (i).is_equal ("-batch") then
					auto_exit_frames := 3
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
			set_tick_rate (30)
			auto_exit_frames := a_frames
			frame_counter := 0
			run
		end

feature {NONE} -- State

	auto_exit_frames: INTEGER
	frame_counter: INTEGER

	start_time_ms: INTEGER_64
	frame_ticks: INTEGER

	green_pos_x: INTEGER
	green_direction: INTEGER -- 1 for right, -1 for left

feature {NONE} -- Setup

	init_state
		do
			start_time_ms := {MONOTONIC_CLOCK}.milliseconds
			frame_ticks := 0
			green_pos_x := 0
			green_direction := 1
		end

feature {NONE} -- Application Hooks

	render (a_frame: FRAME)
			-- Render composite advanced widget layout.
		local
			l_v_layout, l_sq_layout: LAYOUT
			l_v_chunks, l_sq_chunks: ARRAY [RECT]
			l_greeting_area, l_timer_area, l_squares_area, l_pos_area, l_help_area: RECT
			l_greeting_para, l_timer_para, l_pos_para, l_help_para: TUI_PARAGRAPH
			l_elapsed_sec: REAL_64
			l_elapsed_str, l_pos_str: STRING_32
			l_red_style, l_blue_style, l_green_style, l_title_style, l_timer_style: STYLE
			l_block: STRING_32
			l_green_target_x: INTEGER
			l_max_x: INTEGER
		do
			if auto_exit_frames > 0 then
				frame_counter := frame_counter + 1
				if frame_counter >= auto_exit_frames then
					stop
				end
			end

			frame_ticks := frame_ticks + 1
			l_elapsed_sec := ({MONOTONIC_CLOCK}.milliseconds - start_time_ms).to_double / 1000.0

			-- Layout vertical splits: Greeting (2), Timer (2), Squares (4), Position (2), Help (2)
			create l_v_layout.make_vertical (<<
				{CONSTRAINTS}.fixed (2),
				{CONSTRAINTS}.fixed (2),
				{CONSTRAINTS}.fixed (4),
				{CONSTRAINTS}.fixed (2),
				{CONSTRAINTS}.fixed (2),
				{CONSTRAINTS}.flex (1)
			>>)
			l_v_chunks := l_v_layout.split (a_frame.area)
			l_greeting_area := l_v_chunks [1]
			l_timer_area := l_v_chunks [2]
			l_squares_area := l_v_chunks [3]
			l_pos_area := l_v_chunks [4]
			l_help_area := l_v_chunks [5]

			-- 1. Ephemeral Greeting
			create l_title_style.make_fg ({COLOR}.Bright_yellow)
			l_title_style := l_title_style.with_bold
			create l_greeting_para.make (create {TEXT}.make_styled ("Advanced Widget Patterns: Lifecycle & State Separation", l_title_style))
			a_frame.render_widget (l_greeting_para, l_greeting_area)

			-- 2. Timer Widget
			create l_timer_style.make_fg ({COLOR}.Bright_cyan)
			create l_elapsed_str.make_from_string ("Elapsed Timer: ")
			l_elapsed_str.append_double (l_elapsed_sec)
			l_elapsed_str.append_character ('s')
			l_elapsed_str.append_string (" (Frame ticks: ")
			l_elapsed_str.append_integer (frame_ticks)
			l_elapsed_str.append_character (')')
			create l_timer_para.make (create {TEXT}.make_styled (l_elapsed_str, l_timer_style))
			a_frame.render_widget (l_timer_para, l_timer_area)

			-- 3. Boxed Red and Blue Squares + Bouncing Green Square
			create l_red_style.make_with_colors ({COLOR}.Bright_red, {COLOR}.Red)
			create l_blue_style.make_with_colors ({COLOR}.Bright_blue, {COLOR}.Blue)
			create l_green_style.make_with_colors ({COLOR}.Bright_green, {COLOR}.Green)

			create l_block.make_filled ('%U', 4)
			l_block.put_code (9608, 1) -- '█'
			l_block.put_code (9608, 2)
			l_block.put_code (9608, 3)
			l_block.put_code (9608, 4)

			-- Split squares area into columns: Red (6), Blue (6), Spacing (2), Bouncing area
			create l_sq_layout.make_horizontal (<<
				{CONSTRAINTS}.fixed (6),
				{CONSTRAINTS}.fixed (2),
				{CONSTRAINTS}.fixed (6),
				{CONSTRAINTS}.fixed (4),
				{CONSTRAINTS}.flex (1)
			>>)
			l_sq_chunks := l_sq_layout.split (l_squares_area)

			-- Render Red Square (height 2)
			a_frame.buffer.put_string (l_sq_chunks [1].y.to_integer_32, l_sq_chunks [1].x.to_integer_32, l_block, l_red_style)
			a_frame.buffer.put_string ((l_sq_chunks [1].y + 1).to_integer_32, l_sq_chunks [1].x.to_integer_32, l_block, l_red_style)

			-- Render Blue Square (height 2)
			a_frame.buffer.put_string (l_sq_chunks [3].y.to_integer_32, l_sq_chunks [3].x.to_integer_32, l_block, l_blue_style)
			a_frame.buffer.put_string ((l_sq_chunks [3].y + 1).to_integer_32, l_sq_chunks [3].x.to_integer_32, l_block, l_blue_style)

			-- Bouncing Green Square logic
			l_max_x := (l_sq_chunks [5].width.to_integer_32 - 4).max (0)
			if l_max_x > 0 then
				green_pos_x := green_pos_x + green_direction
				if green_pos_x >= l_max_x then
					green_pos_x := l_max_x
					green_direction := -1
				elseif green_pos_x <= 0 then
					green_pos_x := 0
					green_direction := 1
				end
			else
				green_pos_x := 0
			end

			l_green_target_x := l_sq_chunks [5].x.to_integer_32 + green_pos_x
			a_frame.buffer.put_string (l_sq_chunks [5].y.to_integer_32, l_green_target_x, l_block, l_green_style)
			a_frame.buffer.put_string ((l_sq_chunks [5].y + 1).to_integer_32, l_green_target_x, l_block, l_green_style)

			-- 4. Dynamic Position Indicator
			create l_pos_str.make_from_string ("Green dynamic square coordinate: X = ")
			l_pos_str.append_integer (l_green_target_x)
			l_pos_str.append_string (", offset = ")
			l_pos_str.append_integer (green_pos_x)
			create l_pos_para.make (create {TEXT}.make_styled (l_pos_str, create {STYLE}.make_fg ({COLOR}.Bright_green)))
			a_frame.render_widget (l_pos_para, l_pos_area)

			-- 5. Footer help
			create l_help_para.make (create {TEXT}.make_styled ("Press 'q' or Esc to exit.", create {STYLE}.make_fg ({COLOR}.Dark_gray)))
			a_frame.render_widget (l_help_para, l_help_area)
		end

	process (a_event: EVENT)
			-- Process user input.
		do
			if attached {KEY_EVENT} a_event as k then
				if k.is_press then
					if k.code.is_escape or else (k.code.is_char and then (k.code.character = 'q' or k.code.character = 'Q')) then
						stop
					end
				end
			end
		end

end
