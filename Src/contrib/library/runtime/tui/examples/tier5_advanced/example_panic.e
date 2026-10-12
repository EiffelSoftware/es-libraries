note
	description: "[
		Tier 5 Advanced Example: Panic & Exception Recovery (Ratatui 1-to-1).
		Demonstrates guaranteed terminal restoration when an unhandled exception
		or contract violation occurs in an EiffelTUI application.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	EXAMPLE_PANIC

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
			-- Initialize and launch Panic example.
		local
			l_args: ARGUMENTS_32
			i: INTEGER
		do
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
			should_trigger_panic := False

			run

			if should_trigger_panic then
				io.put_string ("%N[EXAMPLE_PANIC] Terminal successfully restored before raising exception!%N")
				io.put_string ("[EXAMPLE_PANIC] Now demonstrating clean stack trace output...%N")
				trigger_developer_exception
			end
		end

	make_batch (a_frames: INTEGER)
			-- Initialize and run for `a_frames` frames.
		do
			make_with_viewport (create {VIEWPORT}.make_fullscreen)
			auto_exit_frames := a_frames
			frame_counter := 0
			should_trigger_panic := False
			run
		end

feature {NONE} -- State

	auto_exit_frames: INTEGER
			-- Number of frames before auto-exit in batch mode (-1 = interactive)

	frame_counter: INTEGER
			-- Frame counter for batch mode

	should_trigger_panic: BOOLEAN
			-- Did the user request an intentional panic on exit?

	panic_mode_name: STRING = "Eiffel Rescue & Restoration Active"

feature {NONE} -- Application Hooks

	render (a_frame: FRAME)
			-- Render panic demonstration card.
		local
			l_v_layout, l_h_layout: LAYOUT
			l_v_chunks, l_h_chunks: ARRAY [RECT]
			l_center_area: RECT
			l_block: TUI_BLOCK
			l_para: TUI_PARAGRAPH
			l_lines: ARRAYED_LIST [TEXT_LINE]
			l_border_style, l_title_style, l_warn_style, l_cmd_style, l_info_style: STYLE
		do
			if auto_exit_frames > 0 then
				frame_counter := frame_counter + 1
				if frame_counter >= auto_exit_frames then
					stop
				end
			end

			-- Centered layout: 3 vertical rows
			create l_v_layout.make_vertical (<<
				{CONSTRAINTS}.flex (1),
				{CONSTRAINTS}.fixed (15),
				{CONSTRAINTS}.flex (1)
			>>)
			l_v_chunks := l_v_layout.split (a_frame.area)

			create l_h_layout.make_horizontal (<<
				{CONSTRAINTS}.flex (1),
				{CONSTRAINTS}.fixed (64),
				{CONSTRAINTS}.flex (1)
			>>)
			l_h_chunks := l_h_layout.split (l_v_chunks [2])
			l_center_area := l_h_chunks [2]

			-- Styles
			create l_border_style.make_fg ({COLOR}.Red)
			create l_title_style.make_fg ({COLOR}.Bright_yellow)
			l_title_style := l_title_style.with_bold
			create l_warn_style.make_fg ({COLOR}.Bright_red)
			create l_cmd_style.make_fg ({COLOR}.Bright_cyan)
			create l_info_style.make_fg ({COLOR}.Gray)

			-- Block
			create l_block.make
			l_block := l_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.double).
				with_border_style (l_border_style).
				with_title (" EiffelTUI Exception & Panic Recovery Demo ").
				with_title_alignment ({TEXT_ALIGNMENT}.center)

			-- Lines
			create l_lines.make (11)
			l_lines.extend (create {TEXT_LINE}.make_styled ("Terminal Lifecycle Protection Status: [ACTIVE]", l_title_style))
			l_lines.extend (create {TEXT_LINE}.make_raw (""))
			l_lines.extend (create {TEXT_LINE}.make_styled ("Press 'p'  -> Trigger Intentional Developer Exception", l_cmd_style))
			l_lines.extend (create {TEXT_LINE}.make_styled ("Press 'c'  -> Trigger Contract Precondition Violation", l_cmd_style))
			l_lines.extend (create {TEXT_LINE}.make_styled ("Press 'q'  -> Exit normally without error", l_cmd_style))
			l_lines.extend (create {TEXT_LINE}.make_raw (""))
			l_lines.extend (create {TEXT_LINE}.make_styled ("In raw terminal mode, unhandled crashes usually freeze", l_info_style))
			l_lines.extend (create {TEXT_LINE}.make_styled ("the console and leave hidden cursors or garbled escape codes.", l_info_style))
			l_lines.extend (create {TEXT_LINE}.make_styled ("EiffelTUI's TUI_APPLICATION rescue handler guarantees that", l_info_style))
			l_lines.extend (create {TEXT_LINE}.make_styled ("alternate screens, mouse modes, and cursor visibility", l_info_style))
			l_lines.extend (create {TEXT_LINE}.make_styled ("are cleanly restored before reporting errors to stderr.", l_warn_style))

			create l_para.make (create {TEXT}.make (l_lines))
			l_para := l_para.with_block (l_block).with_alignment ({TEXT_ALIGNMENT}.center)

			a_frame.render_widget (l_para, l_center_area)
		end

	process (a_event: EVENT)
			-- Process key commands.
		do
			if attached {KEY_EVENT} a_event as k then
				if k.is_press then
					if k.code.is_char and then (k.code.character = 'q' or k.code.character = 'Q') then
						stop
					elseif k.code.is_escape then
						stop
					elseif k.code.is_char and then (k.code.character = 'p' or k.code.character = 'P') then
						should_trigger_panic := True
						stop
					elseif k.code.is_char and then (k.code.character = 'c' or k.code.character = 'C') then
						-- Trigger contract violation directly inside the event loop
						-- to test immediate clean_up in rescue!
						trigger_contract_violation (-1)
					end
				end
			end
		end

feature {NONE} -- Intentional Fault Generators

	trigger_developer_exception
			-- Raise an intentional developer exception.
		local
			l_dev_exc: DEVELOPER_EXCEPTION
		do
			create l_dev_exc
			l_dev_exc.set_description ("Intentional demonstration exception in EXAMPLE_PANIC")
			l_dev_exc.raise
		end

	trigger_contract_violation (a_positive: INTEGER)
			-- Routine with precondition to demonstrate DbC violation handling.
		require
			must_be_positive: a_positive > 0
		do
			io.put_integer (a_positive)
		end

end
