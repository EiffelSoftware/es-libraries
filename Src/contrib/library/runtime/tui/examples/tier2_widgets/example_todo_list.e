note
	description: "[
		Tier 2 Widget Specialist Example: Todo List (Ratatui 1-to-1).
		Demonstrates TUI_LIST with LIST_STATE, selection navigation, item toggling,
		alternating row styles, and detail view panel.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	EXAMPLE_TODO_LIST

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
			-- Initialize and launch Todo List example.
		local
			l_args: ARGUMENTS_32
			i: INTEGER
		do
			init_todo_items
			create list_state.make
			list_state.select_first
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
			init_todo_items
			create list_state.make
			list_state.select_first
			make_with_viewport (create {VIEWPORT}.make_fullscreen)
			auto_exit_frames := a_frames
			frame_counter := 0
			run
		end

feature {NONE} -- Setup

	init_todo_items
			-- Populate the sample todo task list.
		do
			create todo_items.make (6)
			todo_items.extend (create {TODO_ITEM}.make (False, "Rewrite everything with Eiffel!", "Eiffel's Design by Contract and Void safety provide unparalleled reliability."))
			todo_items.extend (create {TODO_ITEM}.make (True, "Port Ratatui core widgets to EiffelTUI", "All core widgets, layouts, buffers, and styling have been natively implemented!"))
			todo_items.extend (create {TODO_ITEM}.make (False, "Feed your cat", "Don't forget to give your pet fresh food, water, and plenty of love."))
			todo_items.extend (create {TODO_ITEM}.make (False, "Walk in the park", "Take a refreshing break outside away from the terminal screen."))
			todo_items.extend (create {TODO_ITEM}.make (True, "Pay internet subscription", "Keep the broadband connection active for GitHub commits."))
			todo_items.extend (create {TODO_ITEM}.make (True, "Refactor widget state classes", "Separated immutable widgets from mutable widget state objects."))
		end

feature {NONE} -- State

	todo_items: ARRAYED_LIST [TODO_ITEM]
			-- List of todo tasks

	list_state: LIST_STATE
			-- Mutable list selection and scroll state

	auto_exit_frames: INTEGER
			-- Auto-exit in batch mode

	frame_counter: INTEGER
			-- Number of rendered frames

	Char_todo: CHARACTER_32 = '%/0x2610/'
			-- Unicode ballot box glyph (☐)

	Char_done: CHARACTER_32 = '%/0x2713/'
			-- Unicode checkmark glyph (✓)

feature {NONE} -- State Operations

	toggle_status
			-- Toggle completed status of currently selected todo item.
		local
			l_idx: INTEGER
		do
			if list_state.has_selection then
				l_idx := list_state.selected
				if l_idx >= 1 and l_idx <= todo_items.count then
					todo_items [l_idx].toggle
				end
			end
		end

feature {NONE} -- Application Hooks

	render (a_frame: FRAME)
			-- Render todo list view, detail pane, header and footer.
		local
			l_main_layout, l_content_layout: LAYOUT
			l_main_chunks, l_content_chunks: ARRAY [RECT]
			l_header_area, l_content_area, l_footer_area: RECT
			l_list_area, l_info_area: RECT
			l_header_para, l_footer_para, l_info_para: TUI_PARAGRAPH
			l_header_style, l_footer_style, l_info_style: STYLE
			l_list: TUI_LIST
			l_list_items: ARRAYED_LIST [LIST_ITEM]
			l_item: LIST_ITEM
			l_block: TUI_BLOCK
			l_border_style, l_selected_style, l_row_style: STYLE
			l_text_line: TEXT_LINE
			l_span_icon, l_span_text: TEXT_SPAN
			l_spans: ARRAYED_LIST [TEXT_SPAN]
			l_icon_str, l_info_text: STRING_32
			i: INTEGER
		do
			if auto_exit_frames > 0 then
				frame_counter := frame_counter + 1
				if frame_counter >= auto_exit_frames then
					stop
				end
			end

			-- 3-tier main layout: Header (2), Content (Flex), Footer (1)
			create l_main_layout.make_vertical (<<
				{CONSTRAINTS}.fixed (2),
				{CONSTRAINTS}.flex (1),
				{CONSTRAINTS}.fixed (1)
			>>)
			l_main_chunks := l_main_layout.split (a_frame.area)
			l_header_area := l_main_chunks [1]
			l_content_area := l_main_chunks [2]
			l_footer_area := l_main_chunks [3]

			-- Split content into list (top half) and info (bottom half)
			create l_content_layout.make_vertical (<<
				{CONSTRAINTS}.flex (1),
				{CONSTRAINTS}.flex (1)
			>>)
			l_content_chunks := l_content_layout.split (l_content_area)
			l_list_area := l_content_chunks [1]
			l_info_area := l_content_chunks [2]

			-- Header
			create l_header_style.make_fg ({COLOR}.Bright_cyan)
			l_header_style := l_header_style.with_bold
			create l_header_para.make (create {TEXT}.make_styled ("EiffelTUI Todo List Example", l_header_style))
			l_header_para := l_header_para.with_alignment ({TEXT_ALIGNMENT}.center)
			a_frame.render_widget (l_header_para, l_header_area)

			-- Footer
			create l_footer_style.make_fg ({COLOR}.Dark_gray)
			create l_footer_para.make (create {TEXT}.make_styled (
				"Use j/k or Down/Up to move | Space/Enter to toggle | h/Left to unselect | g/G top/bottom | q to quit",
				l_footer_style
			))
			l_footer_para := l_footer_para.with_alignment ({TEXT_ALIGNMENT}.center)
			a_frame.render_widget (l_footer_para, l_footer_area)

			-- Todo List Items
			create l_list_items.make (todo_items.count)
			from i := 1 until i > todo_items.count loop
				create l_spans.make (2)
				create l_icon_str.make (3)
				if todo_items [i].is_done then
					l_icon_str.append_character (' ')
					l_icon_str.append_character (Char_done)
					l_icon_str.append_character (' ')
					create l_span_icon.make (l_icon_str, (create {STYLE}.make_fg ({COLOR}.Green)).with_bold)
					create l_span_text.make (todo_items [i].title, create {STYLE}.make_fg ({COLOR}.Green))
				else
					l_icon_str.append_character (' ')
					l_icon_str.append_character (Char_todo)
					l_icon_str.append_character (' ')
					create l_span_icon.make (l_icon_str, create {STYLE}.make_fg ({COLOR}.Bright_yellow))
					create l_span_text.make (todo_items [i].title, create {STYLE}.make_fg ({COLOR}.White))
				end
				l_spans.extend (l_span_icon)
				l_spans.extend (l_span_text)
				create l_text_line.make (l_spans)

				create l_row_style.default_create
				if i \\ 2 = 1 then
					l_row_style := l_row_style.with_bg (create {COLOR}.make_rgb (15, 23, 42))
				else
					l_row_style := l_row_style.with_bg (create {COLOR}.make_rgb (30, 41, 59))
				end

				create l_item.make (create {TEXT}.make (<<l_text_line>>))
				l_item := l_item.with_style (l_row_style)
				l_list_items.extend (l_item)
				i := i + 1
			end

			-- List Widget Block
			create l_border_style.make_with_colors ({COLOR}.White, create {COLOR}.make_rgb (30, 58, 138))
			create l_block.make
			l_block := l_block.with_borders ({BORDERS}.top).
				with_border_style (l_border_style).
				with_title (" TODO List ").
				with_title_alignment ({TEXT_ALIGNMENT}.center)

			create l_selected_style.make_with_colors ({COLOR}.Bright_yellow, create {COLOR}.make_rgb (51, 65, 85))
			l_selected_style := l_selected_style.with_bold

			create l_list.make (l_list_items)
			l_list := l_list.with_block (l_block).
				with_highlight_style (l_selected_style).
				with_highlight_symbol ("> ").
				with_highlight_spacing ({HIGHLIGHT_SPACING}.always)

			a_frame.render_stateful_widget (l_list, l_list_area, list_state)

			-- Detail / Info Panel
			create l_info_text.make (128)
			if list_state.has_selection and then (list_state.selected >= 1 and list_state.selected <= todo_items.count) then
				if todo_items [list_state.selected].is_done then
					l_info_text.append_string_general ("[COMPLETED] ")
				else
					l_info_text.append_string_general ("[PENDING] ")
				end
				l_info_text.append_string_general ("Task: ")
				l_info_text.append (todo_items [list_state.selected].title)
				l_info_text.append_string_general ("%N%NDescription: ")
				l_info_text.append (todo_items [list_state.selected].info)
			else
				l_info_text.append_string_general ("Nothing selected...")
			end

			create l_info_style.make_fg ({COLOR}.Bright_white)
			create l_info_para.make (create {TEXT}.make_styled (l_info_text, l_info_style))

			create l_block.make
			l_block := l_block.with_borders ({BORDERS}.top).
				with_border_style (l_border_style).
				with_title (" Task Details ").
				with_title_alignment ({TEXT_ALIGNMENT}.center)

			l_info_para := l_info_para.with_block (l_block)
			a_frame.render_widget (l_info_para, l_info_area)
		end

	process (a_event: EVENT)
			-- Handle navigation and action keys.
		do
			if attached {KEY_EVENT} a_event as k and then k.is_press then
				if k.code.is_escape or else (k.code.is_char and then (k.code.character = 'q' or k.code.character = 'Q')) then
					stop
				elseif k.code.is_down or else (k.code.is_char and then k.code.character = 'j') then
					list_state.select_next (todo_items.count)
				elseif k.code.is_up or else (k.code.is_char and then k.code.character = 'k') then
					list_state.select_previous (todo_items.count)
				elseif k.code.is_left or else (k.code.is_char and then k.code.character = 'h') then
					list_state.unselect
				elseif k.code.is_home or else (k.code.is_char and then k.code.character = 'g') then
					list_state.select_first
				elseif k.code.is_end or else (k.code.is_char and then k.code.character = 'G') then
					list_state.select_last (todo_items.count)
				elseif k.code.is_enter or else k.code.is_right or else
					(k.code.is_char and then (k.code.character = ' ' or k.code.character = 'l')) then
					toggle_status
				end
			end
		end

end
