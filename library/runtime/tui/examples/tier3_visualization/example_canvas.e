note
	description: "[
		Tier 3 Layout & Visualization Example: Canvas & Vector Graphics (Ratatui 1-to-1).
		Demonstrates 2D vector primitives, world map coordinate projection,
		real-time animated Pong ball bouncing, shapes, and Braille resolution plotting.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	EXAMPLE_CANVAS

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
			-- Initialize and launch Canvas showcase.
		local
			l_args: ARGUMENTS_32
			i: INTEGER
		do
			init_state
			Precursor
			set_tick_rate (33) -- ~30 FPS for smooth Pong ball animation
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
			set_tick_rate (33)
			auto_exit_frames := a_frames
			frame_counter := 0
			run
		end

feature {NONE} -- Setup

	init_state
			-- Setup coordinates, ball kinematics, and markers.
		do
			marker_type := {CANVAS_MARKER}.braille
			is_pong_active := True
			shapes_aspect := 1.0

			-- Map coordinates
			user_x := 0.0
			user_y := 20.0

			-- Pong ball
			ball_x := 50.0
			ball_y := 50.0
			ball_radius := 10.0
			ball_vx := 3.0
			ball_vy := 2.0
		end

feature {NONE} -- State

	marker_type: NATURAL_8
			-- Current canvas marker ({CANVAS_MARKER}.braille, dot, block, etc.)

	is_pong_active: BOOLEAN
			-- Is ball animation running?

	user_x, user_y: REAL_64
			-- Coordinates for the "You are here" marker

	ball_x, ball_y: REAL_64
			-- Pong ball center

	ball_radius: REAL_64
			-- Pong ball radius

	ball_vx, ball_vy: REAL_64
			-- Pong ball velocity vector

	auto_exit_frames: INTEGER
			-- Batch auto-exit counter

	frame_counter: INTEGER
			-- Rendered frame count

feature {NONE} -- Kinematics

	update_physics
			-- Bounce ball inside Pong court [10.0, 190.0] x [10.0, 90.0].
		do
			if is_pong_active then
				ball_x := ball_x + ball_vx
				ball_y := ball_y + ball_vy

				if (ball_x - ball_radius) <= 10.0 then
					ball_x := 10.0 + ball_radius
					ball_vx := -ball_vx
				elseif (ball_x + ball_radius) >= 190.0 then
					ball_x := 190.0 - ball_radius
					ball_vx := -ball_vx
				end

				if (ball_y - ball_radius) <= 10.0 then
					ball_y := 10.0 + ball_radius
					ball_vy := -ball_vy
				elseif (ball_y + ball_radius) >= 90.0 then
					ball_y := 90.0 - ball_radius
					ball_vy := -ball_vy
				end
			end
		end

feature {NONE} -- Rendering

	render (a_frame: FRAME)
			-- Draw 4-quadrant canvas showcase.
		local
			l_main_layout: LAYOUT
			l_main_chunks: ARRAY [RECT]
			l_header_area, l_body_area, l_footer_area: RECT
			l_quad_layout: LAYOUT
			l_row_chunks: ARRAY [RECT]
			l_top_row, l_bot_row: RECT
			l_col_layout: LAYOUT
			l_top_chunks, l_bot_chunks: ARRAY [RECT]
			l_map_area, l_pong_area, l_shapes_area, l_art_area: RECT
		do
			if auto_exit_frames > 0 then
				frame_counter := frame_counter + 1
				if frame_counter >= auto_exit_frames then
					stop
				end
			end

			update_physics

			-- Vertical structure: Header(3), Quadrants(Flex 1), Footer(2)
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

			-- Split body into 2 rows, then each row into 2 columns (2x2 grid)
			create l_quad_layout.make_vertical (<<
				{CONSTRAINTS}.ratio (1, 2),
				{CONSTRAINTS}.ratio (1, 2)
			>>)
			l_row_chunks := l_quad_layout.split (l_body_area)
			l_top_row := l_row_chunks [1]
			l_bot_row := l_row_chunks [2]

			create l_col_layout.make_horizontal (<<
				{CONSTRAINTS}.ratio (1, 2),
				{CONSTRAINTS}.ratio (1, 2)
			>>)
			l_top_chunks := l_col_layout.split (l_top_row)
			l_map_area := l_top_chunks [1]
			l_pong_area := l_top_chunks [2]

			l_bot_chunks := l_col_layout.split (l_bot_row)
			l_shapes_area := l_bot_chunks [1]
			l_art_area := l_bot_chunks [2]

			render_map_canvas (a_frame, l_map_area)
			render_pong_canvas (a_frame, l_pong_area)
			render_shapes_canvas (a_frame, l_shapes_area)
			render_art_canvas (a_frame, l_art_area)

			render_footer (a_frame, l_footer_area)
		end

	render_header (a_frame: FRAME; a_area: RECT)
			-- Render title and active canvas settings.
		local
			l_para: TUI_PARAGRAPH
			l_text: TEXT
			l_line: TEXT_LINE
			l_marker_str: STRING_32
		do
			create l_text.make_empty
			create l_line.make_empty
			l_line.append_span (create {TEXT_SPAN}.make (
				"EiffelTUI 2D Vector Canvas & Braille Graphics",
				(create {STYLE}.make_fg ({COLOR}.Bright_cyan)).with_bold
			))
			l_line.append_span (create {TEXT_SPAN}.make (
				"  [Ratatui 1-to-1]",
				create {STYLE}.make_fg ({COLOR}.Dark_gray)
			))
			l_text.append_line (l_line)

			create l_line.make_empty
			l_line.append_span (create {TEXT_SPAN}.make ("Marker: ", create {STYLE}.make_fg ({COLOR}.Gray)))
			inspect marker_type
			when {CANVAS_MARKER}.braille then l_marker_str := "Braille (2x4 sub-pixel)"
			when {CANVAS_MARKER}.dot then l_marker_str := "Dot (%/0x2022/)"
			when {CANVAS_MARKER}.block then l_marker_str := "Full Block (%/0x2588/)"
			when {CANVAS_MARKER}.half_block then l_marker_str := "Half Block (%/0x2580/)"
			when {CANVAS_MARKER}.bar then l_marker_str := "Bar (%/0x2584/)"
			when {CANVAS_MARKER}.quadrant then l_marker_str := "Quadrant (2x2)"
			when {CANVAS_MARKER}.sextant then l_marker_str := "Sextant (2x3)"
			when {CANVAS_MARKER}.octant then l_marker_str := "Octant (2x4)"
			when {CANVAS_MARKER}.custom then l_marker_str := "Custom (%/0xD7/)"
			else l_marker_str := "Braille"
			end
			l_line.append_span (create {TEXT_SPAN}.make (
				l_marker_str,
				(create {STYLE}.make_with_colors ({COLOR}.Black, {COLOR}.Bright_yellow)).with_bold
			))
			l_line.append_span (create {TEXT_SPAN}.make ("  | World Pos: ", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_line.append_span (create {TEXT_SPAN}.make (
				"(" + user_x.rounded.out + ", " + user_y.rounded.out + ")",
				(create {STYLE}.make_fg ({COLOR}.Bright_green)).with_bold
			))
			l_line.append_span (create {TEXT_SPAN}.make ("  | Ball Pos: ", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_line.append_span (create {TEXT_SPAN}.make (
				"(" + ball_x.rounded.out + ", " + ball_y.rounded.out + ")",
				(create {STYLE}.make_fg ({COLOR}.Bright_magenta)).with_bold
			))
			l_text.append_line (l_line)

			create l_para.make (l_text)
			a_frame.render_widget (l_para, a_area)
		end

	render_map_canvas (a_frame: FRAME; a_area: RECT)
			-- Top-Left: World map projection with movable "You are here" marker.
		local
			l_block: TUI_BLOCK
			l_canvas: TUI_CANVAS
		do
			create l_block.make
			l_block := l_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (create {STYLE}.make_fg ({COLOR}.Bright_green)).
				with_title (" 1. World Map Coordinate Projection ")

			create l_canvas.make
			-- The Custom marker draws this character (`with_marker` below keeps it)
			l_canvas.set_custom_marker ('%/0xD7/')
			l_canvas := l_canvas.with_block (l_block).
				with_bounds (-180.0, 180.0, -90.0, 90.0).
				with_marker (marker_type).
				with_painter (agent paint_map)
			a_frame.render_widget (l_canvas, a_area)
		end

	paint_map (p: CANVAS_PAINTER)
			-- Paint the world map coastlines (SHAPE_MAP) and the user crosshair.
		do
			-- Latitude and Longitude grid
			p.set_style (create {STYLE}.make_fg ({COLOR}.Dark_gray))
			p.draw_line (-180.0, 0.0, 180.0, 0.0)   -- Equator
			p.draw_line (0.0, -90.0, 0.0, 90.0)     -- Prime Meridian
			p.draw_line (-180.0, 45.0, 180.0, 45.0)  -- Tropic of Cancer
			p.draw_line (-180.0, -45.0, 180.0, -45.0)-- Tropic of Capricorn

			-- Coastlines: the high resolution world map (Ratatui `Map`, `MapResolution::High`)
			world_map.paint (p)

			-- User "You are here" Crosshair & Text
			p.set_style (create {STYLE}.make_fg ({COLOR}.Bright_red))
			p.draw_line (user_x - 8.0, user_y, user_x + 8.0, user_y)
			p.draw_line (user_x, user_y - 8.0, user_x, user_y + 8.0)
			p.draw_circle (user_x, user_y, 4.0)

			p.draw_text (user_x + 5.0, user_y - 3.0, "You are here", (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold)
		end

	world_map: SHAPE_MAP
			-- High resolution world map in bright green (Ratatui `Map`, `MapResolution::High`).
		once
			create Result.make ({MAP_RESOLUTION}.high, create {STYLE}.make_fg ({COLOR}.Bright_green))
		end

	render_pong_canvas (a_frame: FRAME; a_area: RECT)
			-- Top-Right: Animated Pong court with bouncing ball.
		local
			l_block: TUI_BLOCK
			l_canvas: TUI_CANVAS
		do
			create l_block.make
			l_block := l_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).
				with_title (" 2. Animated Pong Court (Tick-Driven) ")

			create l_canvas.make
			-- The Custom marker draws this character (`with_marker` below keeps it)
			l_canvas.set_custom_marker ('%/0xD7/')
			l_canvas := l_canvas.with_block (l_block).
				with_bounds (0.0, 200.0, 0.0, 100.0).
				with_marker (marker_type).
				with_painter (agent paint_pong)
			a_frame.render_widget (l_canvas, a_area)
		end

	paint_pong (p: CANVAS_PAINTER)
			-- Paint court walls, net, paddles, and bouncing ball.
		do
			-- Court boundaries
			p.set_style (create {STYLE}.make_fg ({COLOR}.White))
			p.draw_rect (10.0, 10.0, 180.0, 80.0)

			-- Center dividing line (net)
			p.set_style (create {STYLE}.make_fg ({COLOR}.Dark_gray))
			p.draw_line (100.0, 10.0, 100.0, 90.0)

			-- Center circle
			p.draw_circle (100.0, 50.0, 15.0)

			-- Left paddle
			p.set_style (create {STYLE}.make_fg ({COLOR}.Bright_cyan))
			p.draw_rect (15.0, 35.0, 4.0, 30.0)

			-- Right paddle
			p.set_style (create {STYLE}.make_fg ({COLOR}.Bright_red))
			p.draw_rect (181.0, 40.0, 4.0, 30.0)

			-- Bouncing ball
			p.set_style (create {STYLE}.make_fg ({COLOR}.Bright_yellow))
			p.draw_circle (ball_x, ball_y, ball_radius)
			p.draw_point (ball_x, ball_y)

			-- Scoreboard text
			p.draw_text (70.0, 82.0, "PLAYER 1: 03", (create {STYLE}.make_fg ({COLOR}.Bright_cyan)).with_bold)
			p.draw_text (115.0, 82.0, "PLAYER 2: 05", (create {STYLE}.make_fg ({COLOR}.Bright_red)).with_bold)
		end

	render_shapes_canvas (a_frame: FRAME; a_area: RECT)
			-- Bottom-Left: Geometric shapes, nested boxes, and rulers.
		local
			l_block: TUI_BLOCK
			l_canvas: TUI_CANVAS
		do
			create l_block.make
			l_block := l_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (create {STYLE}.make_fg ({COLOR}.Bright_magenta)).
				with_title (" 3. Shapes: Circles, Rects, Polygons & Rulers ")

			-- Width over height of the inner area, a cell being about twice as tall as wide:
			-- the star uses it to keep its shape (the world is 100 x 100 whatever the panel)
			if a_area.height > 2 and a_area.width > 2 then
				shapes_aspect := (a_area.width.to_integer_32 - 2).to_double / (2.0 * (a_area.height.to_integer_32 - 2).to_double)
			else
				shapes_aspect := 1.0
			end
			create l_canvas.make
			-- The Custom marker draws this character (`with_marker` below keeps it)
			l_canvas.set_custom_marker ('%/0xD7/')
			l_canvas := l_canvas.with_block (l_block).
				with_bounds (0.0, 100.0, 0.0, 100.0).
				with_marker (marker_type).
				with_painter (agent paint_shapes)
			a_frame.render_widget (l_canvas, a_area)
		end

	paint_shapes (p: CANVAS_PAINTER)
			-- Paint nested rectangles, diagonals, concentric circles, and two polygons
			-- (SHAPE_AREA, Ratatui `Area`): a filled star and a triangle outline.
		local
			i: INTEGER
			sz: REAL_64
		do
			-- Concentric circles
			p.set_style (create {STYLE}.make_fg ({COLOR}.Bright_cyan))
			from i := 1 until i > 4 loop
				p.draw_circle (30.0, 60.0, (i * 6).to_double)
				i := i + 1
			end

			-- Nested squares
			p.set_style (create {STYLE}.make_fg ({COLOR}.Bright_yellow))
			from i := 1 until i > 5 loop
				sz := (i * 6).to_double
				p.draw_rect (70.0 - sz / 2.0, 60.0 - sz / 2.0, sz, sz)
				i := i + 1
			end

			-- Cross diagonal lines
			p.set_style (create {STYLE}.make_fg ({COLOR}.Dark_gray))
			p.draw_line (10.0, 10.0, 90.0, 90.0)
			p.draw_line (10.0, 90.0, 90.0, 10.0)

			-- Polygons: a concave star filled by the even-odd rule, and a triangle outline
			star_polygon (shapes_aspect).paint (p)
			triangle_polygon.paint (p)

			-- Axis ticks & labels
			p.set_style (create {STYLE}.make_fg ({COLOR}.White))
			p.draw_line (10.0, 20.0, 90.0, 20.0)
			from i := 10 until i > 90 loop
				p.draw_line (i.to_double, 18.0, i.to_double, 22.0)
				i := i + 20
			end
			p.draw_text (15.0, 14.0, "20", create {STYLE}.make_fg ({COLOR}.Gray))
			p.draw_text (35.0, 14.0, "40", create {STYLE}.make_fg ({COLOR}.Gray))
			p.draw_text (55.0, 14.0, "60", create {STYLE}.make_fg ({COLOR}.Gray))
			p.draw_text (75.0, 14.0, "80", create {STYLE}.make_fg ({COLOR}.Gray))
		end

	shapes_aspect: REAL_64
			-- Width over height of the shapes panel on screen (set by `render_shapes_canvas`)

	star_polygon (a_aspect: REAL_64): SHAPE_AREA
			-- Filled five-pointed star centred at (88, 40), 36 units high: ten vertices alternating
			-- between an outer and an inner radius (so the polygon is concave), its x radius
			-- divided by `a_aspect` so that it looks like a star on screen.
		require
			positive_aspect: a_aspect > 0.0
		local
			l_vertices: ARRAYED_LIST [TUPLE [x, y: REAL_64]]
			l_angle, l_radius: REAL_64
			i: INTEGER
			m: DOUBLE_MATH
		do
			create m
			create l_vertices.make (10)
			from i := 0 until i >= 10 loop
				l_angle := {DOUBLE_MATH}.pi / 2.0 + i.to_double * {DOUBLE_MATH}.pi / 5.0
				if i \\ 2 = 0 then l_radius := 18.0 else l_radius := 7.0 end
				l_vertices.extend ([88.0 + l_radius / a_aspect * m.cosine (l_angle), 40.0 + l_radius * m.sine (l_angle)])
				i := i + 1
			end
			create Result.make (l_vertices, create {STYLE}.make_fg ({COLOR}.Bright_green), True)
		end

	triangle_polygon: SHAPE_AREA
			-- Triangle outline in the lower-left corner (not filled).
		once
			create Result.make (<<[5.0, 26.0], [25.0, 26.0], [15.0, 44.0]>>, create {STYLE}.make_fg ({COLOR}.Bright_red), False)
		end

	render_art_canvas (a_frame: FRAME; a_area: RECT)
			-- Bottom-Right: Mathematical Lissajous curve / spiral art.
		local
			l_block: TUI_BLOCK
			l_canvas: TUI_CANVAS
		do
			create l_block.make
			l_block := l_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (create {STYLE}.make_fg ({COLOR}.Bright_blue)).
				with_title (" 4. Mathematical Lissajous Harmonic Curves ")

			create l_canvas.make
			-- The Custom marker draws this character (`with_marker` below keeps it)
			l_canvas.set_custom_marker ('%/0xD7/')
			l_canvas := l_canvas.with_block (l_block).
				with_bounds (-1.2, 1.2, -1.2, 1.2).
				with_marker (marker_type).
				with_painter (agent paint_art)
			a_frame.render_widget (l_canvas, a_area)
		end

	paint_art (p: CANVAS_PAINTER)
			-- Paint Lissajous figure: x = sin(3t), y = sin(4t).
		local
			i, steps: INTEGER
			t, dt: REAL_64
			x1, y1, x2, y2: REAL_64
			m: DOUBLE_MATH
		do
			create m
			steps := 300
			dt := (2.0 * {DOUBLE_MATH}.pi) / steps.to_double

			p.set_style (create {STYLE}.make_fg ({COLOR}.Bright_cyan))
			from
				i := 0
				t := 0.0
				x1 := m.sine (3.0 * t)
				y1 := m.sine (4.0 * t)
			until
				i >= steps
			loop
				t := t + dt
				x2 := m.sine (3.0 * t)
				y2 := m.sine (4.0 * t)
				p.draw_line (x1, y1, x2, y2)
				x1 := x2
				y1 := y2
				i := i + 1
			end

			p.draw_text (-0.9, -0.9, "3:4 Lissajous Knot", (create {STYLE}.make_fg ({COLOR}.Bright_white)).with_bold)
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
			l_line.append_span (create {TEXT_SPAN}.make ("[hjkl/Arrows] ", (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold))
			l_line.append_span (create {TEXT_SPAN}.make ("Move Map Marker  ", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_line.append_span (create {TEXT_SPAN}.make ("[Enter] ", (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold))
			l_line.append_span (create {TEXT_SPAN}.make ("Cycle Marker  ", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_line.append_span (create {TEXT_SPAN}.make ("[Space] ", (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold))
			l_line.append_span (create {TEXT_SPAN}.make ("Pause/Resume Pong  ", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_line.append_span (create {TEXT_SPAN}.make ("[q/Esc] ", (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold))
			l_line.append_span (create {TEXT_SPAN}.make ("Quit", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_text.append_line (l_line)

			create l_para.make (l_text)
			l_para := l_para.with_alignment ({TEXT_ALIGNMENT}.center)
			a_frame.render_widget (l_para, a_area)
		end

feature {NONE} -- Event Handling

	process (a_event: EVENT)
			-- Handle interactive canvas navigation.
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
					elseif ch = 'h' or ch = 'H' then
						user_x := (user_x - 5.0).max (-170.0)
					elseif ch = 'l' or ch = 'L' then
						user_x := (user_x + 5.0).min (170.0)
					elseif ch = 'j' or ch = 'J' then
						user_y := (user_y - 5.0).max (-80.0)
					elseif ch = 'k' or ch = 'K' then
						user_y := (user_y + 5.0).min (80.0)
					elseif ch = ' ' then
						is_pong_active := not is_pong_active
					end
				elseif k.code.is_enter then
					-- Cycle marker: Braille -> Dot -> Block -> HalfBlock -> Bar -> Quadrant -> Sextant -> Octant -> Custom
					marker_type := (marker_type \\ {CANVAS_MARKER}.custom) + 1
				elseif k.code.is_left then
					user_x := (user_x - 5.0).max (-170.0)
				elseif k.code.is_right then
					user_x := (user_x + 5.0).min (170.0)
				elseif k.code.is_down then
					user_y := (user_y - 5.0).max (-80.0)
				elseif k.code.is_up then
					user_y := (user_y + 5.0).min (80.0)
				end
			end
		end

end
