note
	description: "[
		Tier 1 Foundation Example: Color Explorer (Ratatui 1-to-1).
		Interactive inspection of terminal color palettes:
		16 standard ANSI colors, 256-indexed palette (6x6x6 color cube),
		and the 24-step grayscale ramp.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	EXAMPLE_COLOR_EXPLORER

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
			-- Initialize and launch color explorer example.
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

	Full_block: CHARACTER_32 = '%/0x2588/'
			-- Full block glyph (█)

feature {NONE} -- Application Hooks

	render (a_frame: FRAME)
			-- Render complete color palette grid.
		local
			l_v_layout: LAYOUT
			l_chunks: ARRAY [RECT]
			l_header_block: TUI_BLOCK
		do
			if auto_exit_frames > 0 then
				frame_counter := frame_counter + 1
				if frame_counter >= auto_exit_frames then
					stop
				end
			end

			-- Layout: Title (3 rows), Named ANSI colors (12 rows), 256 colors & Grayscale (flex)
			create l_v_layout.make_vertical (<<
				{CONSTRAINTS}.fixed (3),
				{CONSTRAINTS}.fixed (10),
				{CONSTRAINTS}.flex (1)
			>>)
			l_chunks := l_v_layout.split (a_frame.area)

			-- 1. Header Title Block
			create l_header_block.make
			l_header_block := l_header_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (create {STYLE}.make_fg ({COLOR}.Cyan)).
				with_title (" Color Explorer: ANSI 16, 256-Indexed, & Grayscale (Press 'q' or Esc to quit) ").
				with_title_alignment ({TEXT_ALIGNMENT}.center)
			l_header_block.render (l_chunks [1], a_frame.buffer)

			-- 2. Section: Named ANSI Colors
			render_named_ansi (l_chunks [2], a_frame.buffer)

			-- 3. Section: 256 Indexed Colors & Grayscale
			render_indexed_and_grayscale (l_chunks [3], a_frame.buffer)
		end

	render_named_ansi (a_area: RECT; a_buf: BUFFER)
			-- Render the 16 ANSI colors on various backgrounds.
		local
			l_block: TUI_BLOCK
			l_inner: RECT
			l_names: ARRAY [STRING_8]
			l_colors: ARRAY [COLOR]
			i, c, r, l_cell_w: INTEGER
			l_style: STYLE
			l_txt: STRING_32
		do
			create l_block.make
			l_block := l_block.with_borders ({BORDERS}.all_borders).
				with_border_style (create {STYLE}.make_fg ({COLOR}.Dark_gray)).
				with_title (" Named ANSI 16 Colors ")
			l_block.render (a_area, a_buf)

			l_inner := l_block.inner (a_area)
			if l_inner.width > 20 and l_inner.height >= 4 then
				l_names := <<
					"Black", "Red", "Green", "Yellow",
					"Blue", "Magenta", "Cyan", "White",
					"BrBlack", "BrRed", "BrGreen", "BrYellow",
					"BrBlue", "BrMagenta", "BrCyan", "BrWhite"
				>>
				l_colors := <<
					{COLOR}.Black, {COLOR}.Red, {COLOR}.Green, {COLOR}.Yellow,
					{COLOR}.Blue, {COLOR}.Magenta, {COLOR}.Cyan, {COLOR}.White,
					{COLOR}.Bright_black, {COLOR}.Bright_red, {COLOR}.Bright_green, {COLOR}.Bright_yellow,
					{COLOR}.Bright_blue, {COLOR}.Bright_magenta, {COLOR}.Bright_cyan, {COLOR}.Bright_white
				>>

				l_cell_w := (l_inner.width.to_integer_32 // 8).max (1)
				-- Row 1: Foreground on black
				from i := 1 until i > 8 loop
					create l_style.make_with_colors (l_colors [i], {COLOR}.Black)
					create l_txt.make_from_string_general (l_names [i])
					c := l_inner.x.to_integer_32 + (i - 1) * l_cell_w
					r := l_inner.y.to_integer_32
					if c + l_txt.count < a_buf.width then
						a_buf.put_string (r, c, l_txt, l_style)
					end
					i := i + 1
				end
				-- Row 2: Bright Foreground on black
				from i := 9 until i > 16 loop
					create l_style.make_with_colors (l_colors [i], {COLOR}.Black)
					create l_txt.make_from_string_general (l_names [i])
					c := l_inner.x.to_integer_32 + (i - 9) * l_cell_w
					r := l_inner.y.to_integer_32 + 1
					if c + l_txt.count < a_buf.width then
						a_buf.put_string (r, c, l_txt, l_style)
					end
					i := i + 1
				end
				-- Row 3 & 4: Background blocks with black text
				if l_inner.height >= 5 then
					from i := 1 until i > 8 loop
						create l_style.make_with_colors ({COLOR}.Black, l_colors [i])
						create l_txt.make_from_string_general (" " + l_names [i] + " ")
						c := l_inner.x.to_integer_32 + (i - 1) * l_cell_w
						r := l_inner.y.to_integer_32 + 3
						if c + l_txt.count < a_buf.width then
							a_buf.put_string (r, c, l_txt, l_style)
						end
						i := i + 1
					end
					from i := 9 until i > 16 loop
						create l_style.make_with_colors ({COLOR}.Black, l_colors [i])
						create l_txt.make_from_string_general (" " + l_names [i] + " ")
						c := l_inner.x.to_integer_32 + (i - 9) * l_cell_w
						r := l_inner.y.to_integer_32 + 4
						if c + l_txt.count < a_buf.width then
							a_buf.put_string (r, c, l_txt, l_style)
						end
						i := i + 1
					end
				end
			end
		end

	render_indexed_and_grayscale (a_area: RECT; a_buf: BUFFER)
			-- Render 256-color palette (16..231) and grayscale ramp (232..255).
		local
			l_block: TUI_BLOCK
			l_inner: RECT
			idx: INTEGER
			r, c, col_step, l_cube_row: INTEGER
			l_col: COLOR
			l_style: STYLE
			l_tag: STRING_32
		do
			create l_block.make
			l_block := l_block.with_borders ({BORDERS}.all_borders).
				with_border_style (create {STYLE}.make_fg ({COLOR}.Dark_gray)).
				with_title (" 256-Indexed Color Cube (16..231) & Grayscale (232..255) ")
			l_block.render (a_area, a_buf)

			l_inner := l_block.inner (a_area)
			if l_inner.width > 30 and l_inner.height >= 8 then
				-- Display 36 colors per row in 6 rows (16..231)
				col_step := (l_inner.width.to_integer_32 // 36).max (2)
				from
					l_cube_row := 0
				until
					l_cube_row >= 6 or (l_inner.y.to_integer_32 + l_cube_row >= l_inner.bottom.to_integer_32 - 3)
				loop
					from
						c := 0
					until
						c >= 36
					loop
						idx := 16 + l_cube_row * 36 + c
						create l_col.make_indexed (idx.to_natural_8)
						create l_style.make_fg (l_col)

						r := l_inner.y.to_integer_32 + l_cube_row
						if l_inner.x.to_integer_32 + c * col_step + 1 < a_buf.width then
							a_buf.put_char (r, l_inner.x.to_integer_32 + c * col_step, Full_block, l_style)
							a_buf.put_char (r, l_inner.x.to_integer_32 + c * col_step + 1, Full_block, l_style)
						end
						c := c + 1
					end
					l_cube_row := l_cube_row + 1
				end

				-- Grayscale ramp: indices 232 to 255
				r := l_inner.y.to_integer_32 + l_cube_row + 1
				if r < l_inner.bottom.to_integer_32 then
					create l_tag.make_from_string_general ("Grayscale: ")
					a_buf.put_string (r, l_inner.x.to_integer_32, l_tag, create {STYLE}.make_fg ({COLOR}.White))
					from
						idx := 232
					until
						idx > 255
					loop
						create l_col.make_indexed (idx.to_natural_8)
						create l_style.make_fg (l_col)
						c := l_inner.x.to_integer_32 + l_tag.count + (idx - 232) * 2
						if c + 1 < a_buf.width then
							a_buf.put_char (r, c, Full_block, l_style)
							a_buf.put_char (r, c + 1, Full_block, l_style)
						end
						idx := idx + 1
					end
				end
			end
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
