note
	description: "[
		Tier 1 Foundation Example: Popup (Ratatui 1-to-1).
		Demonstrates modal dialog overlay rendering using TUI_POPUP,
		background cell clearing (TUI_CLEAR), and centered rect calculation.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	EXAMPLE_POPUP

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
			-- Initialize and launch popup overlay example.
		local
			l_args: ARGUMENTS_32
			i: INTEGER
		do
			Precursor
			show_popup := False
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
			show_popup := True
			auto_exit_frames := a_frames
			frame_counter := 0
			run
		end

feature {NONE} -- State

	show_popup: BOOLEAN
			-- Is modal popup currently visible?

	auto_exit_frames: INTEGER
			-- Number of frames before auto-exit in batch mode (-1 = interactive)

	frame_counter: INTEGER
			-- Frame counter for batch mode

feature {NONE} -- Application Hooks

	render (a_frame: FRAME)
			-- Render background UI and modal overlay if toggled.
		local
			l_v_layout: LAYOUT
			l_chunks: ARRAY [RECT]
			l_inst_para: TUI_PARAGRAPH
			l_bg_block: TUI_BLOCK
			l_bg_para: TUI_PARAGRAPH
			l_bg_style: STYLE
			l_popup: TUI_POPUP
			l_popup_block: TUI_BLOCK
			l_popup_para: TUI_PARAGRAPH
			l_popup_area: RECT
		do
			if auto_exit_frames > 0 then
				frame_counter := frame_counter + 1
				if frame_counter >= auto_exit_frames then
					stop
				end
			end

			-- Vertical split: instruction bar (1 line) and main content area (flex)
			create l_v_layout.make_vertical (<<
				{CONSTRAINTS}.fixed (1),
				{CONSTRAINTS}.flex (1)
			>>)
			l_chunks := l_v_layout.split (a_frame.area)

			-- Top instruction line
			create l_inst_para.make_raw ("Press 'p' to toggle popup dialog, 'q' or Esc to quit")
			l_inst_para := l_inst_para.with_alignment ({TEXT_ALIGNMENT}.center).
				with_style (create {STYLE}.make_fg ({COLOR}.Yellow))
			a_frame.render_widget (l_inst_para, l_chunks [1])

			-- Main background content with Blue theme
			create l_bg_style.make_with_colors ({COLOR}.Bright_white, {COLOR}.Blue)
			create l_bg_block.make
			l_bg_block := l_bg_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (l_bg_style).
				with_title (" Main Application Content ").
				with_style (l_bg_style)

			create l_bg_para.make_raw (
				"This is the background content panel.%N%N" +
				"When you press 'p', a modal dialog pops up in the center of the screen.%N" +
				"TUI_POPUP automatically clears all background cells beneath the popup%N" +
				"so the underlying text and blue background do not bleed through!%N%N" +
				"Try pressing 'p' now."
			)
			l_bg_para := l_bg_para.with_block (l_bg_block).with_style (l_bg_style)
			a_frame.render_widget (l_bg_para, l_chunks [2])

			-- Modal Popup Overlay
			if show_popup then
				create l_popup.make
				l_popup_area := l_popup.centered_rect (60, 30, a_frame.area)

				create l_popup_block.make
				l_popup_block := l_popup_block.with_borders ({BORDERS}.all_borders).
					with_border_type ({BORDER_TYPE}.double).
					with_border_style (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).
					with_title (" Modal Popup Dialog ").
					with_title_alignment ({TEXT_ALIGNMENT}.center)

				create l_popup_para.make_raw (
					"Greetings from EiffelTUI Modal Popup!%N%N" +
					"Background was cleanly cleared using TUI_CLEAR.%N" +
					"Press 'p' again to close this popup."
				)
				l_popup_para := l_popup_para.with_alignment ({TEXT_ALIGNMENT}.center)

				l_popup := l_popup.with_block (l_popup_block).
					with_inner_widget (l_popup_para).
					with_clear_background (True)

				a_frame.render_widget (l_popup, l_popup_area)
			end
		end

	process (a_event: EVENT)
			-- Toggle popup on 'p' or 'P', quit on 'q', 'Q', or Escape.
		do
			if attached {KEY_EVENT} a_event as k then
				if k.is_press then
					if k.code.is_char and then (k.code.character = 'p' or k.code.character = 'P') then
						show_popup := not show_popup
					elseif k.code.is_escape or else (k.code.is_char and then (k.code.character = 'q' or k.code.character = 'Q')) then
						stop
					end
				end
			end
		end

end
