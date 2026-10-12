note
	description: "[
		Tier 3 Layout & Visualization Example: Mouse Drawing on Canvas (Ratatui 1-to-1).
		Interactive freehand vector sketching on Braille canvas using mouse capture,
		click-and-drag line rendering, multi-color palette, and keyboard pen fallback.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	EXAMPLE_MOUSE_DRAWING

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
			-- Initialize and launch Mouse Drawing canvas showcase.
		local
			l_args: ARGUMENTS_32
			i: INTEGER
		do
			init_state
			Precursor
			set_mouse_capture (True)
			set_tick_rate (33) -- ~30 FPS
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
			set_mouse_capture (False) -- No mouse required in headless batch mode
			set_tick_rate (33)
			auto_exit_frames := a_frames
			frame_counter := 0
			populate_batch_drawing
			run
		end

feature {NONE} -- Setup

	init_state
			-- Setup color palette, strokes storage, and markers.
		do
			marker_type := {CANVAS_MARKER}.braille
			is_mouse_down := False
			create strokes.make (200)

			-- Initial pen position
			pen_x := 40.0
			pen_y := 20.0
			last_drag_x := 40.0
			last_drag_y := 20.0

			create canvas_inner.make (0, 0, 80, 24)
			init_colors
		end

	init_colors
			-- Setup selectable color palette.
		do
			create palette.make (7)
			palette.extend ({COLOR}.Bright_cyan)
			palette.extend ({COLOR}.Bright_green)
			palette.extend ({COLOR}.Bright_yellow)
			palette.extend ({COLOR}.Bright_magenta)
			palette.extend ({COLOR}.Bright_red)
			palette.extend ({COLOR}.Bright_white)
			palette.extend ({COLOR}.Bright_blue)

			create palette_names.make (7)
			palette_names.extend ("Cyan")
			palette_names.extend ("Green")
			palette_names.extend ("Yellow")
			palette_names.extend ("Magenta")
			palette_names.extend ("Red")
			palette_names.extend ("White")
			palette_names.extend ("Blue")

			color_index := 1
		end

	populate_batch_drawing
			-- Pre-populate stylized test drawing for automated tests.
		local
			i: INTEGER
			angle1, angle2: REAL_64
			m: DOUBLE_MATH
		do
			create m
			-- Draw a geometric star
			from
				i := 0
			until
				i >= 5
			loop
				angle1 := (i.to_double * 4.0 * {DOUBLE_MATH}.pi) / 5.0
				angle2 := ((i + 1).to_double * 4.0 * {DOUBLE_MATH}.pi) / 5.0
				strokes.extend ([
					40.0 + (m.cosine (angle1) * 20.0),
					20.0 + (m.sine (angle1) * 12.0),
					40.0 + (m.cosine (angle2) * 20.0),
					20.0 + (m.sine (angle2) * 12.0),
					{COLOR}.Bright_yellow
				])
				i := i + 1
			end
		end

feature {NONE} -- State

	marker_type: NATURAL_8
			-- Marker kind ({CANVAS_MARKER}.braille, dot, block, etc.)

	color_index: INTEGER
			-- Active color index (1..count)

	palette: ARRAYED_LIST [COLOR]
			-- Color palette

	palette_names: ARRAYED_LIST [STRING_32]
			-- Color names

	is_mouse_down: BOOLEAN
			-- Is mouse button pressed?

	pen_x, pen_y: REAL_64
			-- Current pen / mouse world coordinate

	last_drag_x, last_drag_y: REAL_64
			-- Previous drag position for continuous lines

	canvas_inner: RECT
			-- Inner boundary of the canvas area

	strokes: ARRAYED_LIST [TUPLE [x1, y1, x2, y2: REAL_64; color: COLOR]]
			-- Recorded line segments

	auto_exit_frames: INTEGER
			-- Batch auto-exit counter

	frame_counter: INTEGER
			-- Rendered frame count

feature {NONE} -- Drawing Actions

	add_line_stroke (x1, y1, x2, y2: REAL_64; a_col: COLOR)
			-- Record line stroke in strokes list.
		do
			strokes.extend ([x1, y1, x2, y2, a_col])
		end

feature {NONE} -- Rendering

	render (a_frame: FRAME)
			-- Draw mouse drawing application.
		local
			l_main_layout: LAYOUT
			l_main_chunks: ARRAY [RECT]
			l_header_area, l_body_area, l_footer_area: RECT
		do
			if auto_exit_frames > 0 then
				frame_counter := frame_counter + 1
				if frame_counter >= auto_exit_frames then
					stop
				end
			end

			-- Vertical structure: Header(3), Canvas(Flex 1), Footer(2)
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
			render_canvas (a_frame, l_body_area)
			render_footer (a_frame, l_footer_area)
		end

	render_header (a_frame: FRAME; a_area: RECT)
			-- Render top header with palette badges and stroke stats.
		local
			l_para: TUI_PARAGRAPH
			l_text: TEXT
			l_line: TEXT_LINE
			i: INTEGER
			l_badge_style: STYLE
		do
			create l_text.make_empty
			create l_line.make_empty
			l_line.append_span (create {TEXT_SPAN}.make (
				"EiffelTUI Mouse Capture & Freehand Drawing",
				(create {STYLE}.make_fg ({COLOR}.Bright_cyan)).with_bold
			))
			l_line.append_span (create {TEXT_SPAN}.make (
				"  [Ratatui 1-to-1]",
				create {STYLE}.make_fg ({COLOR}.Dark_gray)
			))
			l_text.append_line (l_line)

			create l_line.make_empty
			l_line.append_span (create {TEXT_SPAN}.make ("Palette: ", create {STYLE}.make_fg ({COLOR}.Gray)))
			from
				i := 1
			until
				i > palette.count
			loop
				if i = color_index then
					l_badge_style := (create {STYLE}.make_with_colors ({COLOR}.Black, palette [i])).with_bold
					l_line.append_span (create {TEXT_SPAN}.make ({STRING_32} "[" + palette_names [i] + "] ", l_badge_style))
				else
					l_badge_style := create {STYLE}.make_fg (palette [i])
					l_line.append_span (create {TEXT_SPAN}.make ({STRING_32} " " + palette_names [i] + "  ", l_badge_style))
				end
				i := i + 1
			end

			l_line.append_span (create {TEXT_SPAN}.make ("| Pos: ", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_line.append_span (create {TEXT_SPAN}.make (
				"(" + pen_x.rounded.out + ", " + pen_y.rounded.out + ")",
				(create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold
			))
			l_line.append_span (create {TEXT_SPAN}.make (" | Strokes: ", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_line.append_span (create {TEXT_SPAN}.make (
				strokes.count.out,
				create {STYLE}.make_fg ({COLOR}.Bright_white)
			))
			l_text.append_line (l_line)

			create l_para.make (l_text)
			a_frame.render_widget (l_para, a_area)
		end

	render_canvas (a_frame: FRAME; a_area: RECT)
			-- Render main drawing canvas with borders.
		local
			l_block: TUI_BLOCK
			l_canvas: TUI_CANVAS
			w, h: REAL_64
		do
			create l_block.make
			l_block := l_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (create {STYLE}.make_fg (palette [color_index])).
				with_title (" Vector Drawing Canvas (Click & Drag to Sketch) ")

			canvas_inner := l_block.inner (a_area)
			w := canvas_inner.width.to_real_64.max (10.0)
			h := canvas_inner.height.to_real_64.max (10.0)

			create l_canvas.make
			l_canvas := l_canvas.with_block (l_block).
				with_bounds (0.0, w, 0.0, h).
				with_marker (marker_type).
				with_painter (agent paint_strokes)
			a_frame.render_widget (l_canvas, a_area)
		end

	paint_strokes (p: CANVAS_PAINTER)
			-- Draw all line segments and cursor crosshair.
		do
			across
				strokes as s
			loop
				p.set_style (create {STYLE}.make_fg (s.color))
				p.draw_line (s.x1, s.y1, s.x2, s.y2)
			end

			-- Virtual cursor / crosshair at pen position
			p.set_style (create {STYLE}.make_fg ({COLOR}.White))
			p.draw_point (pen_x, pen_y)
			p.draw_line (pen_x - 1.0, pen_y, pen_x + 1.0, pen_y)
			p.draw_line (pen_x, pen_y - 0.5, pen_x, pen_y + 0.5)
		end

	render_footer (a_frame: FRAME; a_area: RECT)
			-- Render interactive drawing shortcuts.
		local
			l_para: TUI_PARAGRAPH
			l_text: TEXT
			l_line: TEXT_LINE
		do
			create l_text.make_empty
			create l_line.make_empty
			l_line.append_span (create {TEXT_SPAN}.make ("[Mouse Click/Drag] ", (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold))
			l_line.append_span (create {TEXT_SPAN}.make ("Draw Line  ", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_line.append_span (create {TEXT_SPAN}.make ("[Space] ", (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold))
			l_line.append_span (create {TEXT_SPAN}.make ("Cycle Color  ", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_line.append_span (create {TEXT_SPAN}.make ("[c] ", (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold))
			l_line.append_span (create {TEXT_SPAN}.make ("Clear Canvas  ", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_line.append_span (create {TEXT_SPAN}.make ("[m] ", (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold))
			l_line.append_span (create {TEXT_SPAN}.make ("Cycle Marker  ", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_line.append_span (create {TEXT_SPAN}.make ("[hjkl/Arrows] ", (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold))
			l_line.append_span (create {TEXT_SPAN}.make ("Pen Move  ", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_line.append_span (create {TEXT_SPAN}.make ("[Enter] ", (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold))
			l_line.append_span (create {TEXT_SPAN}.make ("Plot  ", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_line.append_span (create {TEXT_SPAN}.make ("[q/Esc] ", (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold))
			l_line.append_span (create {TEXT_SPAN}.make ("Quit", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_text.append_line (l_line)

			create l_para.make (l_text)
			l_para := l_para.with_alignment ({TEXT_ALIGNMENT}.center)
			a_frame.render_widget (l_para, a_area)
		end

feature {NONE} -- Coordinate Mapping

	screen_to_world_x (a_col: INTEGER): REAL_64
			-- Map screen column coordinate to canvas world X.
		do
			Result := (a_col - canvas_inner.x.to_integer_32).max (0).to_double
		end

	screen_to_world_y (a_row: INTEGER): REAL_64
			-- Map screen row coordinate to canvas world Y (Cartesian: 0 at bottom).
		do
			Result := (canvas_inner.y.to_integer_32 + canvas_inner.height.to_integer_32 - a_row).max (0).to_double
		end

feature {NONE} -- Event Handling

	process (a_event: EVENT)
			-- Handle mouse events and keyboard fallback.
		local
			ch: CHARACTER_32
			wx, wy: REAL_64
			old_x, old_y: REAL_64
		do
			-- Mouse Events
			if attached {MOUSE_EVENT} a_event as m then
				wx := screen_to_world_x (m.column.to_integer_32)
				wy := screen_to_world_y (m.row.to_integer_32)
				pen_x := wx
				pen_y := wy

				if m.is_down then
					is_mouse_down := True
					last_drag_x := wx
					last_drag_y := wy
					add_line_stroke (wx, wy, wx, wy, palette [color_index])
				elseif m.is_drag and is_mouse_down then
					add_line_stroke (last_drag_x, last_drag_y, wx, wy, palette [color_index])
					last_drag_x := wx
					last_drag_y := wy
				elseif m.is_up then
					is_mouse_down := False
				end

			-- Key Events
			elseif attached {KEY_EVENT} a_event as k and then k.is_press then
				if k.code.is_escape then
					stop
				elseif k.code.is_char then
					ch := k.code.character
					if ch = 'q' or ch = 'Q' then
						stop
					elseif ch = ' ' then
						color_index := (color_index \\ palette.count) + 1
					elseif ch = 'c' or ch = 'C' then
						strokes.wipe_out
					elseif ch = 'm' or ch = 'M' then
						marker_type := (marker_type \\ 5) + 1
					elseif ch = 'h' or ch = 'H' then
						pen_x := (pen_x - 1.0).max (0.0)
					elseif ch = 'l' or ch = 'L' then
						pen_x := (pen_x + 1.0).min (canvas_inner.width.to_real_64)
					elseif ch = 'j' or ch = 'J' then
						pen_y := (pen_y - 1.0).max (0.0)
					elseif ch = 'k' or ch = 'K' then
						pen_y := (pen_y + 1.0).min (canvas_inner.height.to_real_64)
					end
				elseif k.code.is_enter then
					add_line_stroke (pen_x, pen_y, pen_x, pen_y, palette [color_index])
				elseif k.code.is_left then
					old_x := pen_x
					pen_x := (pen_x - 1.0).max (0.0)
					if is_mouse_down then
						add_line_stroke (old_x, pen_y, pen_x, pen_y, palette [color_index])
					end
				elseif k.code.is_right then
					old_x := pen_x
					pen_x := (pen_x + 1.0).min (canvas_inner.width.to_real_64)
					if is_mouse_down then
						add_line_stroke (old_x, pen_y, pen_x, pen_y, palette [color_index])
					end
				elseif k.code.is_down then
					old_y := pen_y
					pen_y := (pen_y - 1.0).max (0.0)
					if is_mouse_down then
						add_line_stroke (pen_x, old_y, pen_x, pen_y, palette [color_index])
					end
				elseif k.code.is_up then
					old_y := pen_y
					pen_y := (pen_y + 1.0).min (canvas_inner.height.to_real_64)
					if is_mouse_down then
						add_line_stroke (pen_x, old_y, pen_x, pen_y, palette [color_index])
					end
				end
			end
		end

end
