note
	description: "[
		Tier 1 Foundation Example: Minimal (Ratatui 1-to-1).
		Bare-metal frame loop demonstrating direct buffer cell writing
		without intermediate high-level widgets. Exits on any key press.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	EXAMPLE_MINIMAL

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
			-- Initialize and launch minimal direct-buffer example.
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
			-- Direct bare-metal buffer writing without widget containers.
		local
			l_buf: BUFFER
			l_style_title, l_style_body, l_style_box, l_style_hint: STYLE
			r, c, l_start_r, l_start_c, l_box_w, l_box_h: INTEGER
		do
			if auto_exit_frames > 0 then
				frame_counter := frame_counter + 1
				if frame_counter >= auto_exit_frames then
					stop
				end
			end

			l_buf := a_frame.buffer

			create l_style_title.make_with_colors ({COLOR}.Bright_white, {COLOR}.Blue)
			l_style_title := l_style_title.with_bold

			create l_style_body.make_fg ({COLOR}.Green)
			create l_style_box.make_fg ({COLOR}.Cyan)
			create l_style_hint.make_fg ({COLOR}.Yellow)

			l_box_w := (54).min (l_buf.width - 2).max (10)
			l_box_h := (8).min (l_buf.height - 2).max (4)
			l_start_r := ((l_buf.height - l_box_h) // 2).max (0)
			l_start_c := ((l_buf.width - l_box_w) // 2).max (0)

			-- Draw box border manually to demonstrate bare-metal buffer manipulation
			from
				c := l_start_c
			until
				c >= l_start_c + l_box_w
			loop
				l_buf.put_char (l_start_r, c, (9472).to_character_32, l_style_box) -- '─'
				l_buf.put_char (l_start_r + l_box_h - 1, c, (9472).to_character_32, l_style_box)
				c := c + 1
			end

			from
				r := l_start_r
			until
				r >= l_start_r + l_box_h
			loop
				l_buf.put_char (r, l_start_c, (9474).to_character_32, l_style_box) -- '│'
				l_buf.put_char (r, l_start_c + l_box_w - 1, (9474).to_character_32, l_style_box)
				r := r + 1
			end

			l_buf.put_char (l_start_r, l_start_c, (9484).to_character_32, l_style_box) -- '┌'
			l_buf.put_char (l_start_r, l_start_c + l_box_w - 1, (9488).to_character_32, l_style_box) -- '┐'
			l_buf.put_char (l_start_r + l_box_h - 1, l_start_c, (9492).to_character_32, l_style_box) -- '└'
			l_buf.put_char (l_start_r + l_box_h - 1, l_start_c + l_box_w - 1, (9496).to_character_32, l_style_box) -- '┘'

			-- Direct buffer string output
			l_buf.put_string (l_start_r + 1, l_start_c + 2, " Minimal EiffelTUI: Direct Buffer Rendering ", l_style_title)
			l_buf.put_string (l_start_r + 3, l_start_c + 4, "Hello World! Bare-metal frame loop active.", l_style_body)
			l_buf.put_string (l_start_r + 5, l_start_c + 4, "Press any key to exit.", l_style_hint)
		end

	process (a_event: EVENT)
			-- Process user input and exit on any key press.
		do
			if attached {KEY_EVENT} a_event as k then
				if k.is_press then
					stop
				end
			end
		end

end
