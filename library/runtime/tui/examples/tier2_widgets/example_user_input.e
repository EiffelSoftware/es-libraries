note
	description: "[
		Tier 2 Widget Specialist Example: User Input (Ratatui 1-to-1).
		Demonstrates single-line text input with TUI_TEXT_INPUT and TEXT_INPUT_STATE,
		modal navigation between normal and editing modes, and message submission.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	EXAMPLE_USER_INPUT

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
			-- Initialize and launch User Input example.
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

feature {NONE} -- State

	input_state: TEXT_INPUT_STATE
			-- Current text input buffer and cursor state

	messages: ARRAYED_LIST [STRING_32]
			-- History of recorded messages

	is_editing: BOOLEAN
			-- True when user is in editing mode, False for normal command mode

	auto_exit_frames: INTEGER
			-- Auto-exit in batch mode

	frame_counter: INTEGER
			-- Rendered frame count

feature {NONE} -- Setup

	init_state
			-- Setup initial state.
		do
			create input_state.make_with_text ("Hello EiffelTUI!")
			create messages.make (10)
			messages.extend ("Welcome to EiffelTUI interactive user input demo!")
			messages.extend ("Press 'e' to enter editing mode, type something, then press Enter.")
			is_editing := False
		end

feature {NONE} -- State Operations

	submit_message
			-- Record message to history and clear input field.
		local
			l_msg: STRING_32
		do
			l_msg := input_state.value.twin
			if not l_msg.is_empty then
				messages.extend (l_msg)
				input_state.set_value ("")
				input_state.set_cursor_position (0)
			end
		end

feature {NONE} -- Application Hooks

	render (a_frame: FRAME)
			-- Render help message, styled text input field, and recorded message history.
		local
			l_layout: LAYOUT
			l_chunks: ARRAY [RECT]
			l_help_area, l_input_area, l_messages_area: RECT
			l_help_para: TUI_PARAGRAPH
			l_help_style, l_input_border_style, l_box_border_style: STYLE
			l_help_spans: ARRAYED_LIST [TEXT_SPAN]
			l_text_input: TUI_TEXT_INPUT
			l_input_block, l_msg_block: TUI_BLOCK
			l_msg_items: ARRAYED_LIST [LIST_ITEM]
			l_msg_list: TUI_LIST
			l_line: STRING_32
			i: INTEGER
		do
			if auto_exit_frames > 0 then
				frame_counter := frame_counter + 1
				if frame_counter >= auto_exit_frames then
					stop
				end
			end

			-- 3 vertical sections: Help (1), Input (3), Messages (Min 1)
			create l_layout.make_vertical (<<
				{CONSTRAINTS}.fixed (1),
				{CONSTRAINTS}.fixed (3),
				{CONSTRAINTS}.min_size (1)
			>>)
			l_chunks := l_layout.split (a_frame.area)
			l_help_area := l_chunks [1]
			l_input_area := l_chunks [2]
			l_messages_area := l_chunks [3]

			-- Help text
			create l_help_spans.make (4)
			if is_editing then
				create l_help_style.make_fg ({COLOR}.Bright_white)
				l_help_spans.extend (create {TEXT_SPAN}.make ("Press ", l_help_style))
				l_help_spans.extend (create {TEXT_SPAN}.make ("Esc", (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold))
				l_help_spans.extend (create {TEXT_SPAN}.make (" to stop editing, ", l_help_style))
				l_help_spans.extend (create {TEXT_SPAN}.make ("Enter", (create {STYLE}.make_fg ({COLOR}.Bright_green)).with_bold))
				l_help_spans.extend (create {TEXT_SPAN}.make (" to record message.", l_help_style))
			else
				create l_help_style.make_fg ({COLOR}.White)
				l_help_spans.extend (create {TEXT_SPAN}.make ("Press ", l_help_style))
				l_help_spans.extend (create {TEXT_SPAN}.make ("q", (create {STYLE}.make_fg ({COLOR}.Bright_red)).with_bold))
				l_help_spans.extend (create {TEXT_SPAN}.make (" to exit, ", l_help_style))
				l_help_spans.extend (create {TEXT_SPAN}.make ("e", (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold))
				l_help_spans.extend (create {TEXT_SPAN}.make (" to start editing.", l_help_style))
			end
			create l_help_para.make (create {TEXT}.make (<<create {TEXT_LINE}.make (l_help_spans)>>))
			a_frame.render_widget (l_help_para, l_help_area)

			-- Input Field
			create l_input_block.make
			if is_editing then
				create l_input_border_style.make_fg ({COLOR}.Bright_yellow)
				l_input_block := l_input_block.with_borders ({BORDERS}.all_borders).
					with_border_type ({BORDER_TYPE}.rounded).
					with_border_style (l_input_border_style).
					with_title (" Input [Editing] ")
			else
				create l_input_border_style.make_fg ({COLOR}.White)
				l_input_block := l_input_block.with_borders ({BORDERS}.all_borders).
					with_border_type ({BORDER_TYPE}.rounded).
					with_border_style (l_input_border_style).
					with_title (" Input [Normal] ")
			end

			create l_text_input.make
			l_text_input := l_text_input.with_block (l_input_block).
				with_placeholder ("Type your text here...").
				with_shows_cursor (is_editing)

			a_frame.render_stateful_widget (l_text_input, l_input_area, input_state)

			-- Message History List
			create l_msg_items.make (messages.count)
			from i := 1 until i > messages.count loop
				create l_line.make (32)
				l_line.append_integer (i - 1)
				l_line.append_string_general (": ")
				l_line.append (messages [i])
				l_msg_items.extend (create {LIST_ITEM}.make_raw (l_line))
				i := i + 1
			end

			create l_box_border_style.make_fg ({COLOR}.Cyan)
			create l_msg_block.make
			l_msg_block := l_msg_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (l_box_border_style).
				with_title (" Messages ")

			create l_msg_list.make (l_msg_items)
			l_msg_list := l_msg_list.with_block (l_msg_block)
			a_frame.render_widget (l_msg_list, l_messages_area)
		end

	process (a_event: EVENT)
			-- Process input according to active mode.
		local
			c: CHARACTER_32
		do
			if attached {KEY_EVENT} a_event as k and then k.is_press then
				if not is_editing then
					if k.code.is_escape or else (k.code.is_char and then (k.code.character = 'q' or k.code.character = 'Q')) then
						stop
					elseif k.code.is_char and then (k.code.character = 'e' or k.code.character = 'E') then
						is_editing := True
					end
				else
					-- Editing Mode
					if k.code.is_escape then
						is_editing := False
					elseif k.code.is_enter then
						submit_message
					elseif k.code.is_backspace then
						input_state.delete_backward
					elseif k.code.is_delete then
						input_state.delete_forward
					elseif k.code.is_left then
						input_state.move_cursor_left
					elseif k.code.is_right then
						input_state.move_cursor_right
					elseif k.code.is_home then
						input_state.move_cursor_home
					elseif k.code.is_end then
						input_state.move_cursor_end
					elseif k.code.is_char then
						c := k.code.character
						if c >= ' ' and c /= '%/127/' then
							input_state.insert_character (c)
						end
					end
				end
			end
		end

end
