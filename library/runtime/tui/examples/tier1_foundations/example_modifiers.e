note
	description: "[
		Tier 1 Foundation Example: Modifiers (Ratatui 1-to-1).
		Showcases ANSI SGR style modifiers: Bold, Dim, Italic,
		Underlined, Blink, Reversed, and Strikethrough across different colors.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	EXAMPLE_MODIFIERS

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
			-- Initialize and launch style modifiers showcase example.
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
			-- Render modifier test matrix.
		local
			l_buf: BUFFER
			l_header_style: STYLE
			l_block: TUI_BLOCK
			l_inner: RECT
			l_mods: ARRAY [STRING_8]
			l_colors: ARRAY [COLOR]
			l_color_names: ARRAY [STRING_8]
			m, c, r, col_x, row_y, col_width: INTEGER
			l_style: STYLE
			l_text: STRING_32
		do
			if auto_exit_frames > 0 then
				frame_counter := frame_counter + 1
				if frame_counter >= auto_exit_frames then
					stop
				end
			end

			l_buf := a_frame.buffer

			-- Top Notice
			create l_header_style.make_fg ({COLOR}.Bright_red)
			l_header_style := l_header_style.with_bold
			l_buf.put_string (a_frame.area.y.to_integer_32, a_frame.area.x.to_integer_32 + 1, "Note: not all terminal emulators support all modifiers (Press 'q' or Esc to quit)", l_header_style)

			-- Main container block
			create l_block.make
			l_block := l_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (create {STYLE}.make_fg ({COLOR}.Cyan)).
				with_title (" SGR Style Modifiers Matrix ")
			l_block.render (create {RECT}.make (a_frame.area.x, a_frame.area.y + 1, a_frame.area.width, a_frame.area.height - 1), l_buf)

			l_inner := l_block.inner (create {RECT}.make (a_frame.area.x, a_frame.area.y + 1, a_frame.area.width, a_frame.area.height - 1))

			if l_inner.width > 30 and l_inner.height >= 10 then
				l_mods := << "Normal", "Bold", "Dim", "Italic", "Underline", "Blink", "Reversed", "Strike" >>
				l_colors := << {COLOR}.White, {COLOR}.Bright_yellow, {COLOR}.Bright_green, {COLOR}.Bright_cyan, {COLOR}.Bright_red, {COLOR}.Dark_gray >>
				l_color_names := << "White", "Yellow", "Green", "Cyan", "Red", "DarkGray" >>

				col_width := (l_inner.width.to_integer_32 // (l_colors.count + 1)).max (9)

				-- Header row: modifier label column + each color name
				r := l_inner.y.to_integer_32
				l_buf.put_string (r, l_inner.x.to_integer_32, "Modifier", create {STYLE}.make_fg ({COLOR}.Cyan))
				from c := 1 until c > l_colors.count loop
					col_x := l_inner.x.to_integer_32 + c * col_width
					if col_x < a_frame.buffer.width then
						l_buf.put_string (r, col_x, l_color_names [c], create {STYLE}.make_fg (l_colors [c]))
					end
					c := c + 1
				end

				-- Grid rows: each modifier tested against each color
				from m := 1 until m > l_mods.count loop
					row_y := l_inner.y.to_integer_32 + m + 1
					if row_y < l_inner.bottom.to_integer_32 then
						l_buf.put_string (row_y, l_inner.x.to_integer_32, l_mods [m], create {STYLE}.make_fg ({COLOR}.White))

						from c := 1 until c > l_colors.count loop
							col_x := l_inner.x.to_integer_32 + c * col_width
							if col_x < a_frame.buffer.width then
								l_style := apply_modifier (create {STYLE}.make_fg (l_colors [c]), m)
								create l_text.make_from_string_general (l_mods [m])
								l_buf.put_string (row_y, col_x, l_text, l_style)
							end
							c := c + 1
						end
					end
					m := m + 1
				end
			end
		end

	apply_modifier (a_base: STYLE; a_modifier_index: INTEGER): STYLE
			-- Apply modifier corresponding to `a_modifier_index` to `a_base`.
		do
			inspect a_modifier_index
			when 1 then Result := a_base -- Normal
			when 2 then Result := a_base.with_bold
			when 3 then Result := a_base.with_dim
			when 4 then Result := a_base.with_italic
			when 5 then Result := a_base.with_underline
			when 6 then Result := a_base.with_blink
			when 7 then Result := a_base.with_reverse
			when 8 then Result := a_base.with_strikethrough
			else Result := a_base
			end
		ensure
			result_attached: Result /= Void
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
