note
	description: "[
		Tier 2 Widget Specialist Example: Scrollbar (Ratatui 1-to-1).
		Demonstrates vertical and horizontal scrollbars with customizable symbols,
		tracks, begin/end arrows, and mirroring.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	EXAMPLE_SCROLLBAR

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
			-- Initialize and launch Scrollbar example.
		local
			l_args: ARGUMENTS_32
			i: INTEGER
		do
			init_state
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
			init_state
			make_with_viewport (create {VIEWPORT}.make_fullscreen)
			auto_exit_frames := a_frames
			frame_counter := 0
			run
		end

feature {NONE} -- Setup

	init_state
			-- Setup initial scroll position and states.
		do
			vertical_scroll := 0
			horizontal_scroll := 0
			create vertical_scroll_state.make (Total_lines)
			create horizontal_scroll_state.make (Total_columns)
		end

feature {NONE} -- State

	vertical_scroll: INTEGER
			-- Vertical scroll offset in lines

	horizontal_scroll: INTEGER
			-- Horizontal scroll offset in columns

	vertical_scroll_state: SCROLLBAR_STATE
			-- State tracking vertical scrollbar position

	horizontal_scroll_state: SCROLLBAR_STATE
			-- State tracking horizontal scrollbar position

	auto_exit_frames: INTEGER
			-- Auto-exit in batch mode

	frame_counter: INTEGER
			-- Rendered frame count

	Total_lines: INTEGER = 40
			-- Total lines of content

	Total_columns: INTEGER = 120
			-- Total columns of content

feature {NONE} -- Glyphs

	Arrow_up: CHARACTER_32 = '%/0x25B2/'
	Arrow_down: CHARACTER_32 = '%/0x25BC/'
	Arrow_left: CHARACTER_32 = '%/0x25C4/'
	Arrow_right: CHARACTER_32 = '%/0x25BA/'
	Shade_block: CHARACTER_32 = '%/0x2592/'

feature {NONE} -- Content Generation

	sample_text: TEXT
			-- Generate multi-line sample text for testing scrolling.
		local
			l_lines: ARRAYED_LIST [TEXT_LINE]
			l_line: STRING_32
			i: INTEGER
		do
			create l_lines.make (Total_lines)
			from i := 1 until i > Total_lines loop
				create l_line.make (140)
				l_line.append_string_general ("Line ")
				if i < 10 then
					l_line.append_character ('0')
				end
				l_line.append_integer (i)
				l_line.append_string_general (": Eiffel is an advanced object-oriented programming language designed by Bertrand Meyer emphasizing Design by Contract (DbC), Void Safety, and elegant ergonomics. [Column 80 marker .................... Column 100 .................... Column 120]")
				l_lines.extend (create {TEXT_LINE}.make_raw (l_line))
				i := i + 1
			end
			create Result.make (l_lines)
		end

feature {NONE} -- Application Hooks

	render (a_frame: FRAME)
			-- Render 4 panels showing distinct vertical and horizontal scrollbar styles.
		local
			l_main_layout: LAYOUT
			l_main_chunks, l_grid_chunks: ARRAY [RECT]
			l_header_area, l_grid_area, l_footer_area: RECT
			l_p1_area, l_p2_area, l_p3_area, l_p4_area: RECT
			l_header_para, l_footer_para: TUI_PARAGRAPH
			l_para1, l_para2, l_para3, l_para4: TUI_PARAGRAPH
			l_block1, l_block2, l_block3, l_block4: TUI_BLOCK
			l_sb1, l_sb2, l_sb3, l_sb4: TUI_SCROLLBAR
			l_content: TEXT
			l_up_str, l_down_str, l_left_str, l_shade_str: STRING_32
		do
			if auto_exit_frames > 0 then
				frame_counter := frame_counter + 1
				if frame_counter >= auto_exit_frames then
					stop
				end
			end

			-- Layout: Header (1), Grid (Flex 1), Footer (1)
			create l_main_layout.make_vertical (<<
				{CONSTRAINTS}.fixed (1),
				{CONSTRAINTS}.flex (1),
				{CONSTRAINTS}.fixed (1)
			>>)
			l_main_chunks := l_main_layout.split (a_frame.area)
			l_header_area := l_main_chunks [1]
			l_grid_area := l_main_chunks [2]
			l_footer_area := l_main_chunks [3]

			-- Header
			create l_header_para.make (create {TEXT}.make_styled (
				"EiffelTUI Scrollbar Showcase",
				(create {STYLE}.make_fg ({COLOR}.Bright_cyan)).with_bold
			))
			l_header_para := l_header_para.with_alignment ({TEXT_ALIGNMENT}.center)
			a_frame.render_widget (l_header_para, l_header_area)

			-- Footer
			create l_footer_para.make (create {TEXT}.make_styled (
				"Use h/j/k/l or Arrow Keys to scroll | q or Esc to quit",
				create {STYLE}.make_fg ({COLOR}.Dark_gray)
			))
			l_footer_para := l_footer_para.with_alignment ({TEXT_ALIGNMENT}.center)
			a_frame.render_widget (l_footer_para, l_footer_area)

			-- Grid: 2x2 quadrants
			-- Split grid area vertically into 2 rows, then each row horizontally into 2 columns
			l_grid_chunks := (create {LAYOUT}.make_vertical (<<{CONSTRAINTS}.flex (1), {CONSTRAINTS}.flex (1)>>)).split (l_grid_area)
			l_p1_area := (create {LAYOUT}.make_horizontal (<<{CONSTRAINTS}.flex (1), {CONSTRAINTS}.flex (1)>>)).split (l_grid_chunks [1]) [1]
			l_p2_area := (create {LAYOUT}.make_horizontal (<<{CONSTRAINTS}.flex (1), {CONSTRAINTS}.flex (1)>>)).split (l_grid_chunks [1]) [2]
			l_p3_area := (create {LAYOUT}.make_horizontal (<<{CONSTRAINTS}.flex (1), {CONSTRAINTS}.flex (1)>>)).split (l_grid_chunks [2]) [1]
			l_p4_area := (create {LAYOUT}.make_horizontal (<<{CONSTRAINTS}.flex (1), {CONSTRAINTS}.flex (1)>>)).split (l_grid_chunks [2]) [2]

			l_content := sample_text

			-- Update scrollbar states
			vertical_scroll_state.set_content_length (Total_lines)
			vertical_scroll_state.set_position (vertical_scroll)
			horizontal_scroll_state.set_content_length (Total_columns)
			horizontal_scroll_state.set_position (horizontal_scroll)

			-- Panel 1: Vertical Right with Arrows (▲/▼)
			create l_block1.make
			l_block1 := l_block1.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (create {STYLE}.make_fg ({COLOR}.Bright_blue)).
				with_title (" Vertical Right with Arrows ")
			create l_para1.make (l_content)
			l_para1 := l_para1.with_block (l_block1).
				with_scroll (0, vertical_scroll.to_natural_16)
			a_frame.render_widget (l_para1, l_p1_area)

			create l_up_str.make (1)
			l_up_str.append_character (Arrow_up)
			create l_down_str.make (1)
			l_down_str.append_character (Arrow_down)

			create l_sb1.make ({SCROLLBAR_ORIENTATION}.vertical_right)
			l_sb1 := l_sb1.with_begin_symbol (l_up_str).
				with_end_symbol (l_down_str).
				with_thumb_style (create {STYLE}.make_fg ({COLOR}.Bright_blue))
			a_frame.render_stateful_widget (l_sb1, l_p1_area, vertical_scroll_state)

			-- Panel 2: Vertical Left without arrows (mirrored)
			create l_block2.make
			l_block2 := l_block2.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (create {STYLE}.make_fg ({COLOR}.Bright_green)).
				with_title (" Vertical Left Mirrored ")
			create l_para2.make (l_content)
			l_para2 := l_para2.with_block (l_block2).
				with_scroll (0, vertical_scroll.to_natural_16)
			a_frame.render_widget (l_para2, l_p2_area)

			create l_sb2.make ({SCROLLBAR_ORIENTATION}.vertical_left)
			l_sb2 := l_sb2.with_thumb_style (create {STYLE}.make_fg ({COLOR}.Bright_green))
			a_frame.render_stateful_widget (l_sb2, l_p2_area, vertical_scroll_state)

			-- Panel 3: Horizontal Bottom with Begin Arrow (◄)
			create l_block3.make
			l_block3 := l_block3.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).
				with_title (" Horizontal with Begin Arrow ")
			create l_para3.make (l_content)
			l_para3 := l_para3.with_block (l_block3).
				with_scroll (horizontal_scroll.to_natural_16, 0)
			a_frame.render_widget (l_para3, l_p3_area)

			create l_left_str.make (1)
			l_left_str.append_character (Arrow_left)
			create l_sb3.make ({SCROLLBAR_ORIENTATION}.horizontal_bottom)
			l_sb3 := l_sb3.with_begin_symbol (l_left_str).
				with_thumb_style (create {STYLE}.make_fg ({COLOR}.Bright_yellow))
			a_frame.render_stateful_widget (l_sb3, l_p3_area, horizontal_scroll_state)

			-- Panel 4: Horizontal Bottom with Shaded Thumb
			create l_block4.make
			l_block4 := l_block4.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (create {STYLE}.make_fg ({COLOR}.Bright_magenta)).
				with_title (" Horizontal with Shaded Thumb ")
			create l_para4.make (l_content)
			l_para4 := l_para4.with_block (l_block4).
				with_scroll (horizontal_scroll.to_natural_16, 0)
			a_frame.render_widget (l_para4, l_p4_area)

			create l_shade_str.make (1)
			l_shade_str.append_character (Shade_block)
			create l_sb4.make ({SCROLLBAR_ORIENTATION}.horizontal_bottom)
			l_sb4 := l_sb4.with_thumb_symbol (l_shade_str).
				with_thumb_style (create {STYLE}.make_fg ({COLOR}.Bright_magenta))
			a_frame.render_stateful_widget (l_sb4, l_p4_area, horizontal_scroll_state)
		end

	process (a_event: EVENT)
			-- Handle scrolling keys.
		do
			if attached {KEY_EVENT} a_event as k and then k.is_press then
				if k.code.is_escape or else (k.code.is_char and then (k.code.character = 'q' or k.code.character = 'Q')) then
					stop
				elseif k.code.is_down or else (k.code.is_char and then k.code.character = 'j') then
					if vertical_scroll < Total_lines - 1 then
						vertical_scroll := vertical_scroll + 1
					end
				elseif k.code.is_up or else (k.code.is_char and then k.code.character = 'k') then
					if vertical_scroll > 0 then
						vertical_scroll := vertical_scroll - 1
					end
				elseif k.code.is_right or else (k.code.is_char and then k.code.character = 'l') then
					if horizontal_scroll < Total_columns - 1 then
						horizontal_scroll := horizontal_scroll + 1
					end
				elseif k.code.is_left or else (k.code.is_char and then k.code.character = 'h') then
					if horizontal_scroll > 0 then
						horizontal_scroll := horizontal_scroll - 1
					end
				end
			end
		end

end
