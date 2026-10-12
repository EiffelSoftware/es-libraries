note
	description: "[
		Tier 5 Advanced Example: 3D Volatility Surface (Ratatui 1-to-1).
		Visualizes an implied volatility financial surface as an interactive
		3D wireframe on TUI_CANVAS using perspective projection, rotation matrices,
		and real-time Braille dot rendering.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	EXAMPLE_VOLATILITY_SURFACE

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
			-- Initialize and launch 3D Volatility Surface.
		local
			l_args: ARGUMENTS_32
			i: INTEGER
		do
			init_state
			Precursor
			set_tick_rate (33) -- ~30 FPS
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
			set_tick_rate (33)
			auto_exit_frames := a_frames
			frame_counter := 0
			run
		end

feature {NONE} -- State

	auto_exit_frames: INTEGER
	frame_counter: INTEGER

	rotation_x: REAL_64
	rotation_z: REAL_64
	zoom: REAL_64
	is_paused: BOOLEAN
	palette_index: INTEGER

	grid_n: INTEGER = 12
			-- Number of grid steps on X and Y axes

	Camera_distance: REAL_64 = 4.0
	Pi: REAL_64 = 3.14159265358979323846

	math: DOUBLE_MATH

feature {NONE} -- Setup

	init_state
		do
			create math
			rotation_x := 0.6
			rotation_z := 0.4
			zoom := 1.2
			is_paused := False
			palette_index := 1
		end

feature {NONE} -- Application Hooks

	render (a_frame: FRAME)
			-- Render 3D surface and status panel.
		local
			l_v_layout: LAYOUT
			l_v_chunks: ARRAY [RECT]
			l_canvas_area, l_info_area: RECT
			l_canvas: TUI_CANVAS
			l_block: TUI_BLOCK
			l_info_para: TUI_PARAGRAPH
			l_info_line: TEXT_LINE
			l_b_style, l_s_label, l_s_val: STYLE
			l_title_str: STRING_32
		do
			if auto_exit_frames > 0 then
				frame_counter := frame_counter + 1
				if frame_counter >= auto_exit_frames then
					stop
				end
			end

			-- Auto-rotate if not paused
			if not is_paused then
				rotation_z := rotation_z + 0.02
				if rotation_z > 2.0 * Pi then
					rotation_z := rotation_z - 2.0 * Pi
				end
			end

			-- Split area: Canvas (fill), Footer Controls (2 rows)
			create l_v_layout.make_vertical (<<
				{CONSTRAINTS}.flex (1),
				{CONSTRAINTS}.fixed (2)
			>>)
			l_v_chunks := l_v_layout.split (a_frame.area)
			l_canvas_area := l_v_chunks [1]
			l_info_area := l_v_chunks [2]

			-- Canvas Block
			create l_b_style.make_fg ({COLOR}.Bright_cyan)
			create l_title_str.make_from_string (" 3D Implied Volatility Surface [Braille Canvas] ")
			create l_block.make
			l_block := l_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (l_b_style).
				with_title (l_title_str)

			create l_canvas.make
			l_canvas := l_canvas.with_block (l_block).
				with_bounds (-1.8, 1.8, -1.4, 1.4).
				with_painter (agent paint_surface)

			a_frame.render_widget (l_canvas, l_canvas_area)

			-- Footer Info
			create l_s_label.make_fg ({COLOR}.Bright_yellow)
			create l_s_val.make_fg ({COLOR}.White)

			create l_info_line.make_empty
			l_info_line.append_span (create {TEXT_SPAN}.make ("Controls: ", l_s_label))
			l_info_line.append_span (create {TEXT_SPAN}.make ("[Arrows] Rotate  ", l_s_val))
			l_info_line.append_span (create {TEXT_SPAN}.make ("[+/-] Zoom: ", l_s_label))
			l_info_line.append_span (create {TEXT_SPAN}.make (zoom.out.substring (1, 4) + "  ", l_s_val))
			l_info_line.append_span (create {TEXT_SPAN}.make ("[Space/p] ", l_s_label))
			l_info_line.append_span (create {TEXT_SPAN}.make (if is_paused then "Resume  " else "Pause  " end, l_s_val))
			l_info_line.append_span (create {TEXT_SPAN}.make ("[c] Palette: ", l_s_label))
			l_info_line.append_span (create {TEXT_SPAN}.make (palette_name + "  ", l_s_val))
			l_info_line.append_span (create {TEXT_SPAN}.make ("[q] Quit", l_s_label))

			create l_info_para.make (create {TEXT}.make (<<l_info_line>>))
			l_info_para := l_info_para.with_alignment ({TEXT_ALIGNMENT}.center)
			a_frame.render_widget (l_info_para, l_info_area)
		end

	paint_surface (a_painter: CANVAS_PAINTER)
			-- Paint 3D grid onto canvas.
		local
			i, j: INTEGER
			x, y, z: REAL_64
			p1, p2, p3: TUPLE [x, y: REAL_64]
			l_style: STYLE
		do
			l_style := current_palette_style
			a_painter.set_style (l_style)

			-- Render grid lines along X
			from i := 0 until i > grid_n loop
				x := -1.0 + (2.0 * i.to_double / grid_n.to_double)
				from j := 0 until j >= grid_n loop
					y := -1.0 + (2.0 * j.to_double / grid_n.to_double)
					z := vol_height (x, y)
					p1 := project_3d (x, y, z)

					y := -1.0 + (2.0 * (j + 1).to_double / grid_n.to_double)
					z := vol_height (x, y)
					p2 := project_3d (x, y, z)

					a_painter.draw_line (p1.x, p1.y, p2.x, p2.y)
					j := j + 1
				end
				i := i + 1
			end

			-- Render grid lines along Y
			from j := 0 until j > grid_n loop
				y := -1.0 + (2.0 * j.to_double / grid_n.to_double)
				from i := 0 until i >= grid_n loop
					x := -1.0 + (2.0 * i.to_double / grid_n.to_double)
					z := vol_height (x, y)
					p1 := project_3d (x, y, z)

					x := -1.0 + (2.0 * (i + 1).to_double / grid_n.to_double)
					z := vol_height (x, y)
					p3 := project_3d (x, y, z)

					a_painter.draw_line (p1.x, p1.y, p3.x, p3.y)
					i := i + 1
				end
				j := j + 1
			end
		end

	vol_height (a_x, a_y: REAL_64): REAL_64
			-- Financial volatility smile formula: parabolic strike smile + term structure term.
		do
			Result := 0.25 * (a_x * a_x) - 0.15 * a_y + 0.12 * math.sine (2.0 * a_x + 3.0 * a_y)
		end

	project_3d (a_x, a_y, a_z: REAL_64): TUPLE [x, y: REAL_64]
			-- Project 3D point (a_x, a_y, a_z) to 2D screen coordinate using perspective projection.
		local
			sin_x, cos_x, sin_z, cos_z: REAL_64
			x1, y1, z1, y2, z2: REAL_64
			persp: REAL_64
		do
			sin_x := math.sine (rotation_x)
			cos_x := math.cosine (rotation_x)
			sin_z := math.sine (rotation_z)
			cos_z := math.cosine (rotation_z)

			-- Rotate around Z axis (yaw)
			x1 := a_x * cos_z - a_y * sin_z
			y1 := a_x * sin_z + a_y * cos_z
			z1 := a_z

			-- Rotate around X axis (pitch)
			y2 := y1 * cos_x - z1 * sin_x
			z2 := y1 * sin_x + z1 * cos_x

			-- Perspective projection
			persp := Camera_distance / (Camera_distance + z2)
			Result := [x1 * persp * zoom, y2 * persp * zoom]
		end

	palette_name: STRING
		do
			inspect palette_index
			when 1 then Result := "Cyan Cyber"
			when 2 then Result := "Emerald Matrix"
			when 3 then Result := "Solar Amber"
			when 4 then Result := "Neon Magenta"
			else Result := "Default"
			end
		end

	current_palette_style: STYLE
		do
			inspect palette_index
			when 1 then create Result.make_fg ({COLOR}.Bright_cyan)
			when 2 then create Result.make_fg ({COLOR}.Bright_green)
			when 3 then create Result.make_fg ({COLOR}.Bright_yellow)
			when 4 then create Result.make_fg ({COLOR}.Bright_magenta)
			else create Result.make_fg ({COLOR}.Bright_white)
			end
		end

	process (a_event: EVENT)
			-- Handle interactive keyboard controls.
		do
			if attached {KEY_EVENT} a_event as k then
				if k.is_press then
					if k.code.is_escape or else (k.code.is_char and then (k.code.character = 'q' or k.code.character = 'Q')) then
						stop
					elseif k.code.is_char and then (k.code.character = 'p' or k.code.character = 'P' or k.code.character = ' ') then
						is_paused := not is_paused
					elseif k.code.is_char and then (k.code.character = 'c' or k.code.character = 'C') then
						palette_index := palette_index + 1
						if palette_index > 4 then
							palette_index := 1
						end
					elseif k.code.is_char and then (k.code.character = '+' or k.code.character = '=') then
						zoom := (zoom * 1.1).min (3.0)
					elseif k.code.is_char and then (k.code.character = '-' or k.code.character = '_') then
						zoom := (zoom * 0.9).max (0.3)
					elseif k.code.is_left then
						rotation_z := rotation_z - 0.1
					elseif k.code.is_right then
						rotation_z := rotation_z + 0.1
					elseif k.code.is_up then
						rotation_x := (rotation_x + 0.1).min (Pi / 2.0)
					elseif k.code.is_down then
						rotation_x := (rotation_x - 0.1).max (-Pi / 2.0)
					end
				end
			end
		end

end
