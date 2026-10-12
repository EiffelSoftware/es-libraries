note
	description: "[
		Tier 5 Advanced Example: Widget Reference Container (Ratatui 1-to-1).
		Demonstrates storing heterogeneous, polymorphic WIDGET references inside a composite
		container (STACK_CONTAINER) and rendering them cleanly across dynamic layout splits.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	EXAMPLE_WIDGET_CONTAINER

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
			-- Initialize and launch Widget Container example.
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
			set_tick_rate (50)
			auto_exit_frames := a_frames
			frame_counter := 0
			run
		end

feature {NONE} -- State

	auto_exit_frames: INTEGER
	frame_counter: INTEGER

	tick_count: INTEGER

feature {NONE} -- Setup

	init_state
		do
			tick_count := 0
		end

feature {NONE} -- Application Hooks

	render (a_frame: FRAME)
			-- Render composite stack container.
		local
			l_main_stack: STACK_CONTAINER
			l_row_stack: STACK_CONTAINER
			l_title_para, l_help_para: TUI_PARAGRAPH
			l_greeting: GREETING_WIDGET
			l_farewell: FAREWELL_WIDGET
			l_gauge: TUI_GAUGE
			l_title_style, l_help_style, l_gauge_style: STYLE
			l_gauge_ratio: REAL_64
		do
			if auto_exit_frames > 0 then
				frame_counter := frame_counter + 1
				if frame_counter >= auto_exit_frames then
					stop
				end
			end

			tick_count := tick_count + 1
			l_gauge_ratio := ((tick_count * 2) \\ 100) / 100.0

			-- Root Vertical Stack Container
			create l_main_stack.make_vertical

			-- 1. Title Paragraph
			create l_title_style.make_fg ({COLOR}.Bright_yellow)
			l_title_style := l_title_style.with_bold
			create l_title_para.make (create {TEXT}.make_styled ("Heterogeneous Polymorphic Widget Container Demo", l_title_style))
			l_title_para := l_title_para.with_alignment ({TEXT_ALIGNMENT}.center)
			l_main_stack.extend (l_title_para, {CONSTRAINTS}.fixed (2))

			-- 2. Horizontal Sub-Stack with Greeting and Farewell
			create l_row_stack.make_horizontal
			create l_greeting.make ("Eiffel Developer")
			create l_farewell.make ("Until next time! Keep contracts tight.")
			l_row_stack.extend (l_greeting, {CONSTRAINTS}.percentage (50))
			l_row_stack.extend (l_farewell, {CONSTRAINTS}.percentage (50))
			l_main_stack.extend (l_row_stack, {CONSTRAINTS}.fixed (5))

			-- 3. Gauge Widget
			create l_gauge_style.make_fg ({COLOR}.Bright_cyan)
			create l_gauge.make
			l_gauge := l_gauge.with_ratio (l_gauge_ratio).
				with_gauge_style (l_gauge_style).
				with_label ("Dynamic Container Refresh Pipeline")
			l_main_stack.extend (l_gauge, {CONSTRAINTS}.fixed (3))

			-- 4. Help / Exit message
			create l_help_style.make_fg ({COLOR}.Dark_gray)
			create l_help_para.make (create {TEXT}.make_styled ("Press 'q' or Esc to quit. All child widgets dispatched polymorphically.", l_help_style))
			l_help_para := l_help_para.with_alignment ({TEXT_ALIGNMENT}.center)
			l_main_stack.extend (l_help_para, {CONSTRAINTS}.fixed (2))

			-- Render the entire root stack container onto the frame
			a_frame.render_widget (l_main_stack, a_frame.area)
		end

	process (a_event: EVENT)
			-- Process key events.
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
