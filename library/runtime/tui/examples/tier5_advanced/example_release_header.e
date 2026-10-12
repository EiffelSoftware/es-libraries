note
	description: "[
		Tier 5 Advanced Example: Release Header Banner (Ratatui 1-to-1).
		Generates a stylized terminal release banner with logo typography,
		rainbow gradient reflection, version metadata, and rounded package menus.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	EXAMPLE_RELEASE_HEADER

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
			-- Initialize and launch Release Header example.
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

	Version_tag: STRING = "v0.3.0 %"Eiffel-Emerald%""

feature {NONE} -- Application Hooks

	render (a_frame: FRAME)
			-- Render release banner dashboard.
		local
			l_v_layout, l_h_layout, l_menu_layout: LAYOUT
			l_v_chunks, l_h_chunks, l_menu_chunks: ARRAY [RECT]
			l_center_area, l_logo_area, l_menu_area: RECT
			l_bg_color, l_fg_color, l_border_color: COLOR
			l_base_style: STYLE
			l_menu_block1, l_menu_block2: TUI_BLOCK
			l_menu_para1, l_menu_para2: TUI_PARAGRAPH
			l_lines1, l_lines2: ARRAYED_LIST [TEXT_LINE]
			l_item_style, l_b_style: STYLE
		do
			if auto_exit_frames > 0 then
				frame_counter := frame_counter + 1
				if frame_counter >= auto_exit_frames then
					stop
				end
			end

			-- TrueColor Palette matching Ratatui release-header
			l_fg_color := create {COLOR}.make_rgb (246, 214, 187) -- #F6D6BB
			l_bg_color := create {COLOR}.make_rgb (20, 20, 50)     -- #141432
			l_border_color := create {COLOR}.make_rgb (255, 255, 160) -- #FFFFA0

			create l_base_style.make_with_colors (l_fg_color, l_bg_color)
			a_frame.buffer.set_style (a_frame.area, l_base_style)

			-- Centered layout: 16 rows, 68 cols
			create l_v_layout.make_vertical (<<
				{CONSTRAINTS}.flex (1),
				{CONSTRAINTS}.fixed (15),
				{CONSTRAINTS}.flex (1)
			>>)
			l_v_chunks := l_v_layout.split (a_frame.area)

			create l_h_layout.make_horizontal (<<
				{CONSTRAINTS}.flex (1),
				{CONSTRAINTS}.fixed (70),
				{CONSTRAINTS}.flex (1)
			>>)
			l_h_chunks := l_h_layout.split (l_v_chunks [2])
			l_center_area := l_h_chunks [2]

			-- Inside center area: Horizontal split for Logo (36 cols), Spacing (4), Menu (30 cols)
			create l_h_layout.make_horizontal (<<
				{CONSTRAINTS}.fixed (36),
				{CONSTRAINTS}.fixed (4),
				{CONSTRAINTS}.fixed (30)
			>>)
			l_h_chunks := l_h_layout.split (l_center_area)
			l_logo_area := l_h_chunks [1]
			l_menu_area := l_h_chunks [3]

			-- 1. Render Logo Banner & Reflection
			render_logo (a_frame, l_logo_area, l_fg_color, l_bg_color)

			-- 2. Render Package Menus ("Core Packages" and "Platform Backends")
			create l_menu_layout.make_vertical (<<
				{CONSTRAINTS}.fixed (6),
				{CONSTRAINTS}.fixed (1),
				{CONSTRAINTS}.fixed (6),
				{CONSTRAINTS}.flex (1)
			>>)
			l_menu_chunks := l_menu_layout.split (l_menu_area)

			create l_b_style.make_with_colors (l_border_color, l_bg_color)
			create l_item_style.make_with_colors (l_fg_color, l_bg_color)

			-- Block 1: Core Packages
			create l_menu_block1.make
			l_menu_block1 := l_menu_block1.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (l_b_style).
				with_style (create {STYLE}.make_with_colors (l_fg_color, l_bg_color)).
				with_title (" Core Packages ")

			create l_lines1.make (4)
			l_lines1.extend (create {TEXT_LINE}.make_styled (" > eiffeltui", l_item_style))
			l_lines1.extend (create {TEXT_LINE}.make_styled (" > eiffeltui-core", l_item_style))
			l_lines1.extend (create {TEXT_LINE}.make_styled (" > eiffeltui-widgets", l_item_style))
			l_lines1.extend (create {TEXT_LINE}.make_styled (" > eiffeltui-layout", l_item_style))

			create l_menu_para1.make (create {TEXT}.make (l_lines1))
			l_menu_para1 := l_menu_para1.with_block (l_menu_block1).
				with_style (create {STYLE}.make_with_colors (l_fg_color, l_bg_color))
			a_frame.render_widget (l_menu_para1, l_menu_chunks [1])

			-- Block 2: Platform Backends
			create l_menu_block2.make
			l_menu_block2 := l_menu_block2.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (l_b_style).
				with_style (create {STYLE}.make_with_colors (l_fg_color, l_bg_color)).
				with_title (" Platform Backends ")

			create l_lines2.make (4)
			l_lines2.extend (create {TEXT_LINE}.make_styled (" > eiffeltui-windows", l_item_style))
			l_lines2.extend (create {TEXT_LINE}.make_styled (" > eiffeltui-posix", l_item_style))
			l_lines2.extend (create {TEXT_LINE}.make_styled (" > eiffeltui-autotest", l_item_style))
			l_lines2.extend (create {TEXT_LINE}.make_styled (" > eiffeltui-benchmark", l_item_style))

			create l_menu_para2.make (create {TEXT}.make (l_lines2))
			l_menu_para2 := l_menu_para2.with_block (l_menu_block2).
				with_style (create {STYLE}.make_with_colors (l_fg_color, l_bg_color))
			a_frame.render_widget (l_menu_para2, l_menu_chunks [3])
		end

	render_logo (a_frame: FRAME; a_area: RECT; a_fg, a_bg: COLOR)
			-- Render ASCII logo art with rainbow reflection.
		local
			l_y: INTEGER
			l_logo_style, l_sub_style: STYLE
			i: INTEGER
			l_rainbow_color: COLOR
			l_rainbow_style: STYLE
		do
			l_y := a_area.y.to_integer_32 + 1
			create l_logo_style.make_with_colors (a_fg, a_bg)
			l_logo_style := l_logo_style.with_bold

			-- Primary Big Typography Logo
			a_frame.buffer.put_string (l_y, a_area.x.to_integer_32,     "  ______ _  __  __     _ _____ _   _ _____ ", l_logo_style)
			a_frame.buffer.put_string (l_y + 1, a_area.x.to_integer_32, " |  ____(_)/ _|/ _|   | |_   _| | | |_   _|", l_logo_style)
			a_frame.buffer.put_string (l_y + 2, a_area.x.to_integer_32, " | |__   _| |_| |_ ___| | | | | | | | | |  ", l_logo_style)
			a_frame.buffer.put_string (l_y + 3, a_area.x.to_integer_32, " |  __| | |  _|  _/ _ \ | | | | | | | | |  ", l_logo_style)
			a_frame.buffer.put_string (l_y + 4, a_area.x.to_integer_32, " | |____| | | | ||  __/ |_| |_| |_| |_| |_ ", l_logo_style)
			a_frame.buffer.put_string (l_y + 5, a_area.x.to_integer_32, " |______|_|_| |_| \___|_|_____|\___/|_____|", l_logo_style)

			-- Rainbow gradient reflection shadow bar below logo (ROYGBIV) using Unicode upper half blocks (U+2580)
			from i := 0 until i >= 7 loop
				if i = 0 then
					l_rainbow_color := create {COLOR}.make_rgb (240, 70, 70)     -- Red
				elseif i = 1 then
					l_rainbow_color := create {COLOR}.make_rgb (245, 140, 40)    -- Orange
				elseif i = 2 then
					l_rainbow_color := create {COLOR}.make_rgb (250, 215, 50)    -- Yellow
				elseif i = 3 then
					l_rainbow_color := create {COLOR}.make_rgb (65, 205, 110)    -- Green
				elseif i = 4 then
					l_rainbow_color := create {COLOR}.make_rgb (55, 160, 245)    -- Blue
				elseif i = 5 then
					l_rainbow_color := create {COLOR}.make_rgb (110, 100, 230)   -- Indigo
				else
					l_rainbow_color := create {COLOR}.make_rgb (195, 80, 225)    -- Violet
				end
				create l_rainbow_style.make_with_colors (l_rainbow_color, a_bg)
				a_frame.buffer.put_string (l_y + 7, a_area.x.to_integer_32 + i * 5, {STRING_32} "%/0x2580/%/0x2580/%/0x2580/%/0x2580/%/0x2580/", l_rainbow_style)
				i := i + 1
			end

			-- Version and Release Name below
			create l_sub_style.make_with_colors ({COLOR}.Bright_yellow, a_bg)
			l_sub_style := l_sub_style.with_bold
			a_frame.buffer.put_string (l_y + 9, a_area.x.to_integer_32 + 2, "Release: " + Version_tag, l_sub_style)

			create l_sub_style.make_with_colors ({COLOR}.Gray, a_bg)
			a_frame.buffer.put_string (l_y + 11, a_area.x.to_integer_32 + 2, "(Press 'q' or Esc to quit)", l_sub_style)
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

end
