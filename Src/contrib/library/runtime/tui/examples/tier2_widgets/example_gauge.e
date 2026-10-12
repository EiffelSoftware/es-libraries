note
	description: "[
		Tier 2 Widget Specialist Example: Gauge (Ratatui 1-to-1).
		Demonstrates TUI_GAUGE with percentages, ratios, custom labels,
		and Unicode fractional sub-character block rendering.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	EXAMPLE_GAUGE

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
			-- Initialize and launch Gauge example.
		local
			l_args: ARGUMENTS_32
			i: INTEGER
		do
			init_state
			Precursor
			set_tick_rate (50) -- 20 FPS update rate
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
			-- Initialize and run for `a_frames` frames.
		do
			init_state
			make_with_viewport (create {VIEWPORT}.make_fullscreen)
			set_tick_rate (50)
			auto_exit_frames := a_frames
			frame_counter := 0
			run
		end

feature {NONE} -- Setup

	init_state
			-- Setup initial progress values.
		do
			progress_percent := 25
			progress_ratio := 0.25
			is_animating := True
		end

feature {NONE} -- State

	progress_percent: INTEGER
			-- Progress percentage (0..100)

	progress_ratio: REAL_64
			-- Progress ratio (0.0..1.0)

	is_animating: BOOLEAN
			-- Is progress animation running?

	auto_exit_frames: INTEGER
			-- Auto-exit in batch mode

	frame_counter: INTEGER
			-- Rendered frame count

feature {NONE} -- Animation Updates

	update_progress
			-- Advance progress values.
		do
			if is_animating then
				progress_percent := (progress_percent + 1)
				if progress_percent > 100 then
					progress_percent := 0
				end

				progress_ratio := progress_ratio + 0.008
				if progress_ratio > 1.0 then
					progress_ratio := 0.0
				end
			end
		end

feature {NONE} -- Application Hooks

	render (a_frame: FRAME)
			-- Render header, 4 gauge variants, and footer controls.
		local
			l_main_layout, l_gauge_layout: LAYOUT
			l_main_chunks, l_gauge_chunks: ARRAY [RECT]
			l_header_area, l_body_area, l_footer_area: RECT
			l_g1_area, l_g2_area, l_g3_area, l_g4_area: RECT
			l_header_para, l_footer_para: TUI_PARAGRAPH
			l_gauge1, l_gauge2, l_gauge3, l_gauge4: TUI_GAUGE
			l_block1, l_block2, l_block3, l_block4: TUI_BLOCK
			l_style1, l_style2, l_style3, l_style4: STYLE
			l_label2, l_label3, l_label4: STRING_32
			l_footer_text: STRING_32
		do
			if auto_exit_frames > 0 then
				frame_counter := frame_counter + 1
				if frame_counter >= auto_exit_frames then
					stop
				end
			end

			update_progress

			-- Layout: Header (2), Body (Flex 1), Footer (1)
			create l_main_layout.make_vertical (<<
				{CONSTRAINTS}.fixed (2),
				{CONSTRAINTS}.flex (1),
				{CONSTRAINTS}.fixed (1)
			>>)
			l_main_chunks := l_main_layout.split (a_frame.area)
			l_header_area := l_main_chunks [1]
			l_body_area := l_main_chunks [2]
			l_footer_area := l_main_chunks [3]

			-- Header
			create l_header_para.make (create {TEXT}.make_styled (
				"EiffelTUI Gauge Showcase",
				(create {STYLE}.make_fg ({COLOR}.Bright_cyan)).with_bold
			))
			l_header_para := l_header_para.with_alignment ({TEXT_ALIGNMENT}.center)
			a_frame.render_widget (l_header_para, l_header_area)

			-- Footer
			create l_footer_text.make (64)
			l_footer_text.append_string_general ("Press Space or Enter to ")
			if is_animating then
				l_footer_text.append_string_general ("Pause")
			else
				l_footer_text.append_string_general ("Resume")
			end
			l_footer_text.append_string_general (" | Press q or Esc to quit")
			create l_footer_para.make (create {TEXT}.make_styled (l_footer_text, create {STYLE}.make_fg ({COLOR}.Dark_gray)))
			l_footer_para := l_footer_para.with_alignment ({TEXT_ALIGNMENT}.center)
			a_frame.render_widget (l_footer_para, l_footer_area)

			-- Split body area into 4 equal rows for the gauges
			create l_gauge_layout.make_vertical (<<
				{CONSTRAINTS}.flex (1),
				{CONSTRAINTS}.flex (1),
				{CONSTRAINTS}.flex (1),
				{CONSTRAINTS}.flex (1)
			>>)
			l_gauge_chunks := l_gauge_layout.split (l_body_area)
			l_g1_area := l_gauge_chunks [1]
			l_g2_area := l_gauge_chunks [2]
			l_g3_area := l_gauge_chunks [3]
			l_g4_area := l_gauge_chunks [4]

			-- 1. Percentage Gauge (Crimson / Red)
			create l_block1.make
			l_block1 := l_block1.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (create {STYLE}.make_fg ({COLOR}.Bright_red)).
				with_title (" Gauge 1: Percentage Progress ")
			create l_style1.make_with_colors ({COLOR}.Bright_white, create {COLOR}.make_rgb (185, 28, 28))
			create l_gauge1.make
			l_gauge1 := l_gauge1.with_block (l_block1).
				with_percent (progress_percent.to_natural_16).
				with_gauge_style (l_style1)
			a_frame.render_widget (l_gauge1, l_g1_area)

			-- 2. Ratio with Custom Styled Label (Emerald / Green)
			create l_block2.make
			l_block2 := l_block2.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (create {STYLE}.make_fg ({COLOR}.Bright_green)).
				with_title (" Gauge 2: Ratio with Custom Styled Label ")
			create l_style2.make_with_colors ({COLOR}.Bright_white, create {COLOR}.make_rgb (21, 128, 61))
			create l_label2.make (32)
			l_label2.append_string_general ("Progress: ")
			l_label2.append_integer ((progress_ratio * 1000.0).rounded // 10)
			l_label2.append_string_general (".")
			l_label2.append_integer ((progress_ratio * 1000.0).rounded \\ 10)
			l_label2.append_string_general (" / 100.0")

			create l_gauge2.make
			l_gauge2 := l_gauge2.with_block (l_block2).
				with_ratio (progress_ratio).
				with_label (l_label2).
				with_gauge_style (l_style2)
			a_frame.render_widget (l_gauge2, l_g2_area)

			-- 3. Standard Continuous Gauge (Indigo / Blue)
			create l_block3.make
			l_block3 := l_block3.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (create {STYLE}.make_fg ({COLOR}.Bright_blue)).
				with_title (" Gauge 3: Continuous Ratio (No Unicode) ")
			create l_style3.make_with_colors ({COLOR}.Bright_white, create {COLOR}.make_rgb (29, 78, 216))
			create l_label3.make (16)
			l_label3.append_integer ((progress_ratio * 100.0).rounded)
			l_label3.append_string_general ("% %")

			create l_gauge3.make
			l_gauge3 := l_gauge3.with_block (l_block3).
				with_ratio (progress_ratio).
				with_label (l_label3).
				with_use_unicode (False).
				with_gauge_style (l_style3)
			a_frame.render_widget (l_gauge3, l_g3_area)

			-- 4. Unicode Sub-Character Block Gauge (Amber / Orange)
			create l_block4.make
			l_block4 := l_block4.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).
				with_title (" Gauge 4: High-Precision Fractional Blocks (Unicode) ")
			create l_style4.make_with_colors ({COLOR}.Black, create {COLOR}.make_rgb (217, 119, 6))
			create l_label4.make (16)
			l_label4.append_integer ((progress_ratio * 100.0).rounded)
			l_label4.append_string_general ("% % (Sub-cell 1/8 resolution)")

			create l_gauge4.make
			l_gauge4 := l_gauge4.with_block (l_block4).
				with_ratio (progress_ratio).
				with_label (l_label4).
				with_use_unicode (True).
				with_gauge_style (l_style4)
			a_frame.render_widget (l_gauge4, l_g4_area)
		end

	process (a_event: EVENT)
			-- Handle pause and quit keys.
		do
			if attached {KEY_EVENT} a_event as k and then k.is_press then
				if k.code.is_escape or else (k.code.is_char and then (k.code.character = 'q' or k.code.character = 'Q')) then
					stop
				elseif k.code.is_enter or else (k.code.is_char and then k.code.character = ' ') then
					is_animating := not is_animating
				end
			end
		end

end
