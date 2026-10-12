note
	description: "[
		Tier 1 Foundation Example: Colors RGB (Ratatui 1-to-1).
		Renders an animated full-screen 24-bit TrueColor RGB wave
		using half-block glyphs (U+2580) to double vertical pixel resolution.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	EXAMPLE_COLORS_RGB

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
			-- Initialize and launch animated RGB color wave example.
		local
			l_args: ARGUMENTS_32
			i: INTEGER
		do
			Precursor
			set_tick_rate (25) -- ~40 FPS animation rate
			last_fps_instant := {MONOTONIC_CLOCK}.milliseconds
			fps_frame_count := 0
			current_fps := 0.0

			create l_args
			auto_exit_frames := -1
			from i := 1 until i > l_args.argument_count loop
				if l_args.argument (i).is_equal ("-batch") then
					auto_exit_frames := 10
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
			set_tick_rate (25)
			last_fps_instant := {MONOTONIC_CLOCK}.milliseconds
			fps_frame_count := 0
			current_fps := 0.0
			auto_exit_frames := a_frames
			frame_counter := 0
			run
		end

feature {NONE} -- State

	auto_exit_frames: INTEGER
			-- Number of frames before auto-exit in batch mode (-1 = interactive)

	frame_counter: INTEGER
			-- Frame counter for animation wave and batch mode

	last_fps_instant: INTEGER_64
			-- Timestamp of last FPS calculation

	fps_frame_count: INTEGER
			-- Frames elapsed since last FPS calculation

	current_fps: REAL_64
			-- Calculated frames per second

	Half_block: CHARACTER_32 = '%/0x2580/'
			-- Unicode upper half block character (▀)

feature {NONE} -- Application Hooks

	render (a_frame: FRAME)
			-- Render animated RGB color spectrum.
		local
			l_buf: BUFFER
			l_top_style, l_fps_style, l_cell_style: STYLE
			l_fps_text: STRING_32
			w, h, sub_h: INTEGER
			x, y, y_top, y_bot: INTEGER
			l_hue, l_val_top, l_val_bot: REAL_64
			l_fg, l_bg: COLOR
		do
			if auto_exit_frames > 0 then
				frame_counter := frame_counter + 1
				if frame_counter >= auto_exit_frames then
					stop
				end
			end

			l_buf := a_frame.buffer
			w := a_frame.area.width.to_integer_32
			h := a_frame.area.height.to_integer_32

			if w > 0 and h > 1 then
				-- Top Header bar
				create l_top_style.make_with_colors ({COLOR}.Bright_white, {COLOR}.Black)
				l_top_style := l_top_style.with_bold
				l_buf.put_string (a_frame.area.y.to_integer_32, a_frame.area.x.to_integer_32 + 1, "colors_rgb example. Press 'q' or Esc to quit", l_top_style)

				-- FPS meter in header
				create l_fps_style.make_with_colors ({COLOR}.Bright_yellow, {COLOR}.Black)
				create l_fps_text.make (16)
				l_fps_text.append_string_general (current_fps.truncated_to_integer.out)
				l_fps_text.append_string_general (" fps")
				if w > l_fps_text.count + 4 then
					l_buf.put_string (a_frame.area.y.to_integer_32, a_frame.area.x.to_integer_32 + w - l_fps_text.count - 2, l_fps_text, l_fps_style)
				end

				-- Sub-pixel rendering area (each cell row has 2 pixel rows: top and bottom)
				sub_h := (h - 1) * 2
				from
					x := 0
				until
					x >= w
				loop
					l_hue := ((x + frame_counter) \\ w).to_double * 360.0 / w.to_double
					from
						y := 0
					until
						y >= h - 1
					loop
						y_top := y * 2
						y_bot := y * 2 + 1
						l_val_top := ((sub_h - y_top).to_double / sub_h.to_double).max (0.0).min (1.0)
						l_val_bot := ((sub_h - y_bot).to_double / sub_h.to_double).max (0.0).min (1.0)

						l_fg := hsv_to_rgb (l_hue, 1.0, l_val_top)
						l_bg := hsv_to_rgb (l_hue, 1.0, l_val_bot)
						create l_cell_style.make_with_colors (l_fg, l_bg)

						l_buf.put_char (a_frame.area.y.to_integer_32 + 1 + y, a_frame.area.x.to_integer_32 + x, Half_block, l_cell_style)
						y := y + 1
					end
					x := x + 1
				end
			end
		end

	process (a_event: EVENT)
			-- Update frame counter on tick and quit on 'q' or Escape.
		local
			l_now: INTEGER_64
			l_elapsed: REAL_64
		do
			if a_event.is_tick then
				frame_counter := frame_counter + 1
				fps_frame_count := fps_frame_count + 1
				l_now := {MONOTONIC_CLOCK}.milliseconds
				if l_now - last_fps_instant >= 1000 then
					l_elapsed := (l_now - last_fps_instant).to_double / 1000.0
					if l_elapsed > 0.0 then
						current_fps := fps_frame_count.to_double / l_elapsed
					end
					fps_frame_count := 0
					last_fps_instant := l_now
				end
			elseif attached {KEY_EVENT} a_event as k then
				if k.is_press then
					if k.code.is_escape or else (k.code.is_char and then (k.code.character = 'q' or k.code.character = 'Q')) then
						stop
					end
				end
			end
		end

feature {NONE} -- Color Conversion

	hsv_to_rgb (a_h, a_s, a_v: REAL_64): COLOR
			-- Convert HSV coordinates (H in 0..360, S in 0..1, V in 0..1) to 24-bit TrueColor RGB.
		local
			c, x, m, r1, g1, b1: REAL_64
			h_prime, f: REAL_64
			h_sector: INTEGER
			r8, g8, b8: NATURAL_8
		do
			c := a_v * a_s
			h_prime := (a_h / 60.0).max (0.0)
			h_sector := h_prime.truncated_to_integer \\ 6
			f := h_prime - (h_prime.truncated_to_integer).to_double
			if h_sector \\ 2 = 0 then
				x := c * f
			else
				x := c * (1.0 - f)
			end

			inspect h_sector
			when 0 then
				r1 := c; g1 := x; b1 := 0.0
			when 1 then
				r1 := x; g1 := c; b1 := 0.0
			when 2 then
				r1 := 0.0; g1 := c; b1 := x
			when 3 then
				r1 := 0.0; g1 := x; b1 := c
			when 4 then
				r1 := x; g1 := 0.0; b1 := c
			else
				r1 := c; g1 := 0.0; b1 := x
			end

			m := a_v - c
			r8 := ((r1 + m) * 255.0).max (0.0).min (255.0).rounded.to_natural_8
			g8 := ((g1 + m) * 255.0).max (0.0).min (255.0).rounded.to_natural_8
			b8 := ((b1 + m) * 255.0).max (0.0).min (255.0).rounded.to_natural_8
			create Result.make_rgb (r8, g8, b8)
		ensure
			result_attached: Result /= Void
		end

end
