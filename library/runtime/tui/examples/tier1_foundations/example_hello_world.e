note
	description: "[
		Tier 1 Foundation Example: Hello World (Ratatui 1-to-1).
		Demonstrates the core terminal pipeline, TUI_PARAGRAPH, TUI_BLOCK,
		centered layout, and clean event handling.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	EXAMPLE_HELLO_WORLD

inherit
	TUI_APPLICATION
		redefine
			make
		end

create
	make,
	make_batch,
	make_with_terminal

feature {NONE} -- Initialization

	make
			-- Initialize and launch Hello World example.
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
			run
		end

	make_batch (a_frames: INTEGER)
			-- Initialize and run for `a_frames` frames.
		do
			make_with_viewport (create {VIEWPORT}.make_fullscreen)
			auto_exit_frames := a_frames
			frame_counter := 0
			run
		end

feature {NONE} -- State

	auto_exit_frames: INTEGER
			-- Number of frames before auto-exit in batch mode (-1 = interactive)

	frame_counter: INTEGER
			-- Frame counter for batch mode

feature {NONE} -- Application Hooks

	render (a_frame: FRAME)
			-- Render centered greeting card.
		local
			l_v_layout, l_h_layout: LAYOUT
			l_v_chunks, l_h_chunks: ARRAY [RECT]
			l_center_area: RECT
			l_block: TUI_BLOCK
			l_para: TUI_PARAGRAPH
			l_lines: ARRAYED_LIST [TEXT_LINE]
			l_line1, l_line2: TEXT_LINE
			l_style1, l_style2, l_border_style: STYLE
		do
			if auto_exit_frames > 0 then
				frame_counter := frame_counter + 1
				if frame_counter >= auto_exit_frames then
					stop
				end
			end

			-- Centered layout: 3 vertical rows (flex, fixed 7, flex)
			create l_v_layout.make_vertical (<<
				{CONSTRAINTS}.flex (1),
				{CONSTRAINTS}.fixed (7),
				{CONSTRAINTS}.flex (1)
			>>)
			l_v_chunks := l_v_layout.split (a_frame.area)

			-- Middle row horizontal split: (flex, fixed 48, flex)
			create l_h_layout.make_horizontal (<<
				{CONSTRAINTS}.flex (1),
				{CONSTRAINTS}.fixed (48),
				{CONSTRAINTS}.flex (1)
			>>)
			l_h_chunks := l_h_layout.split (l_v_chunks [2])
			l_center_area := l_h_chunks [2]

			-- Block styling
			create l_border_style.make_fg ({COLOR}.Cyan)
			create l_block.make
			l_block := l_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (l_border_style).
				with_title (" Ratatui x EiffelTUI: Hello World ").
				with_title_alignment ({TEXT_ALIGNMENT}.center)

			-- Greeting text lines
			create l_style1.make_fg ({COLOR}.Bright_yellow)
			l_style1 := l_style1.with_bold
			create l_line1.make_styled ("Hello World!", l_style1)

			create l_style2.make_fg ({COLOR}.Dark_gray)
			create l_line2.make_styled ("(press 'q' or Esc to quit)", l_style2)

			create l_lines.make (2)
			l_lines.extend (l_line1)
			l_lines.extend (l_line2)

			create l_para.make (create {TEXT}.make (l_lines))
			l_para := l_para.with_block (l_block).with_alignment ({TEXT_ALIGNMENT}.center)

			a_frame.render_widget (l_para, l_center_area)
		end

	process (a_event: EVENT)
			-- Process user input and exit on 'q', 'Q', or Escape.
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
