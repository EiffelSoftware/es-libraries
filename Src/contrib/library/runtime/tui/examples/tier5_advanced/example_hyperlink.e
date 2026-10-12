note
	description: "[
		Tier 5 Advanced Example: Terminal Hyperlinks (Ratatui 1-to-1).
		Demonstrates OSC 8 terminal hyperlink escape sequences for clickable URLs
		in modern terminal emulators (Windows Terminal, iTerm2, Kitty, WezTerm).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	EXAMPLE_HYPERLINK

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
			-- Initialize and launch Hyperlink example.
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
	frame_counter: INTEGER

feature {NONE} -- Application Hooks

	render (a_frame: FRAME)
			-- Render hyperlink showcase card.
		local
			l_v_layout, l_h_layout: LAYOUT
			l_v_chunks, l_h_chunks: ARRAY [RECT]
			l_center_area: RECT
			l_block: TUI_BLOCK
			l_para: TUI_PARAGRAPH
			l_lines: ARRAYED_LIST [TEXT_LINE]
			l_border_style, l_title_style, l_link_style, l_text_style, l_dim_style: STYLE
			l_line: TEXT_LINE
		do
			if auto_exit_frames > 0 then
				frame_counter := frame_counter + 1
				if frame_counter >= auto_exit_frames then
					stop
				end
			end

			-- Centered layout
			create l_v_layout.make_vertical (<<
				{CONSTRAINTS}.flex (1),
				{CONSTRAINTS}.fixed (15),
				{CONSTRAINTS}.flex (1)
			>>)
			l_v_chunks := l_v_layout.split (a_frame.area)

			create l_h_layout.make_horizontal (<<
				{CONSTRAINTS}.flex (1),
				{CONSTRAINTS}.fixed (68),
				{CONSTRAINTS}.flex (1)
			>>)
			l_h_chunks := l_h_layout.split (l_v_chunks [2])
			l_center_area := l_h_chunks [2]

			-- Styles
			create l_border_style.make_fg ({COLOR}.Bright_blue)
			create l_title_style.make_fg ({COLOR}.Bright_cyan)
			l_title_style := l_title_style.with_bold
			create l_link_style.make_fg ({COLOR}.Bright_yellow)
			l_link_style := l_link_style.with_underline
			create l_text_style.make_fg ({COLOR}.Bright_white)
			create l_dim_style.make_fg ({COLOR}.Dark_gray)

			-- Card Block
			create l_block.make
			l_block := l_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (l_border_style).
				with_title (" OSC 8 Terminal Hyperlinks ").
				with_title_alignment ({TEXT_ALIGNMENT}.center)

			create l_lines.make (10)
			l_lines.extend (create {TEXT_LINE}.make_styled ("Clickable Hyperlink Showcase", l_title_style))
			l_lines.extend (create {TEXT_LINE}.make_raw (""))
			l_lines.extend (create {TEXT_LINE}.make_styled ("Modern terminals support clickable links using OSC 8 escape sequences.", l_text_style))
			l_lines.extend (create {TEXT_LINE}.make_styled ("Hold Ctrl (or Cmd on macOS) and click on the links below:", l_text_style))
			l_lines.extend (create {TEXT_LINE}.make_raw (""))

			-- Clickable links:
			create l_line.make_raw ("  1) ")
			l_line.append_span (create {TEXT_SPAN}.make ("Eiffel Language Official Portal", l_link_style))
			l_lines.extend (l_line)

			create l_line.make_raw ("  2) ")
			l_line.append_span (create {TEXT_SPAN}.make ("EiffelTUI GitHub Repository", l_link_style))
			l_lines.extend (l_line)

			create l_line.make_raw ("  3) ")
			l_line.append_span (create {TEXT_SPAN}.make ("Ratatui Rust Ecosystem Docs", l_link_style))
			l_lines.extend (l_line)

			l_lines.extend (create {TEXT_LINE}.make_raw (""))
			l_lines.extend (create {TEXT_LINE}.make_styled ("(Press 'q' or Esc to exit)", l_dim_style))

			create l_para.make (create {TEXT}.make (l_lines))
			l_para := l_para.with_block (l_block).with_alignment ({TEXT_ALIGNMENT}.center)

			a_frame.render_widget (l_para, l_center_area)

			-- Post-process buffer cells with OSC 8 escape sequences (matching Ratatui Hyperlink pattern)
			apply_hyperlink (a_frame.buffer, "Eiffel Language Official Portal", "https://www.eiffel.org")
			apply_hyperlink (a_frame.buffer, "EiffelTUI GitHub Repository", "https://github.com/jvelilla/tui")
			apply_hyperlink (a_frame.buffer, "Ratatui Rust Ecosystem Docs", "https://ratatui.rs")
		end

	process (a_event: EVENT)
			-- Process key commands.
		do
			if attached {KEY_EVENT} a_event as k then
				if k.is_press then
					if k.code.is_escape or else (k.code.is_char and then (k.code.character = 'q' or k.code.character = 'Q')) then
						stop
					end
				end
			end
		end

feature {NONE} -- Helper

	apply_hyperlink (a_buffer: BUFFER; a_target_text: READABLE_STRING_GENERAL; a_url: READABLE_STRING_GENERAL)
			-- Find `a_target_text` in `a_buffer` and wrap each cell's symbol with OSC 8 sequences for `a_url`.
			-- This matches Ratatui's buffer post-processing pattern for OSC 8 hyperlinks.
		local
			r, c, k: INTEGER
			l_found: BOOLEAN
			l_target: STRING_32
			l_url_str: STRING_32
			l_cell: TERMINAL_CELL
			l_sym: STRING_32
		do
			l_target := a_target_text.as_string_32
			l_url_str := a_url.as_string_32
			from
				r := 0
			until
				r >= a_buffer.height or l_found
			loop
				from
					c := 0
				until
					c + l_target.count > a_buffer.width or l_found
				loop
					l_found := True
					from
						k := 1
					until
						k > l_target.count or not l_found
					loop
						l_cell := a_buffer.cell (r, c + k - 1)
						if l_cell.symbol.count /= 1 or else l_cell.symbol.item (1) /= l_target.item (k) then
							l_found := False
						end
						k := k + 1
					end

					if l_found then
						from
							k := 1
						until
							k > l_target.count
						loop
							l_cell := a_buffer.cell (r, c + k - 1)
							create l_sym.make (l_url_str.count + 32)
							l_sym.append_character ((27).to_character_32)
							l_sym.append ("]8;;")
							l_sym.append (l_url_str)
							l_sym.append_character ((7).to_character_32)
							l_sym.append (l_cell.symbol)
							l_sym.append_character ((27).to_character_32)
							l_sym.append ("]8;;")
							l_sym.append_character ((7).to_character_32)

							l_cell.set_symbol (l_sym)
							l_cell.set_width (1)
							k := k + 1
						end
					end
					c := c + 1
				end
				r := r + 1
			end
		end

end
