note
	description: "[
		Tier 2 Widget Specialist Example: Table (Ratatui 1-to-1).
		Demonstrates multi-column tabular data with TUI_TABLE, TABLE_STATE,
		TUI_SCROLLBAR, row/column/cell highlight styles, and palette cycling.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	EXAMPLE_TABLE

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
			-- Initialize and launch Table example.
		local
			l_args: ARGUMENTS_32
			i: INTEGER
		do
			init_data
			create table_state.make
			table_state.select_first
			table_state.select_column (1)
			create scrollbar_state.make (items.count)
			palette_index := 1
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
			init_data
			create table_state.make
			table_state.select_first
			table_state.select_column (1)
			create scrollbar_state.make (items.count)
			palette_index := 1
			make_with_viewport (create {VIEWPORT}.make_fullscreen)
			auto_exit_frames := a_frames
			frame_counter := 0
			run
		end

feature {NONE} -- Setup

	init_data
			-- Create dataset of sample contacts.
		do
			create items.make (15)
			items.extend (create {CONTACT_ITEM}.make ("Ada Lovelace", "12 St. James's Square, London", "ada@analytical-engine.org"))
			items.extend (create {CONTACT_ITEM}.make ("Alan Turing", "43 Adlington Road, Wilmslow", "alan@bletchley.gov.uk"))
			items.extend (create {CONTACT_ITEM}.make ("Grace Hopper", "Arlington National, Virginia", "grace.hopper@us-navy.mil"))
			items.extend (create {CONTACT_ITEM}.make ("Bertrand Meyer", "Santa Barbara, California", "bertrand@eiffel.com"))
			items.extend (create {CONTACT_ITEM}.make ("Edsger Dijkstra", "Nuenen, Netherlands", "ewd@utexas.edu"))
			items.extend (create {CONTACT_ITEM}.make ("Claude Shannon", "Petoskey, Michigan", "shannon@bell-labs.com"))
			items.extend (create {CONTACT_ITEM}.make ("Margaret Hamilton", "Paoli, Indiana", "margaret@mit.edu"))
			items.extend (create {CONTACT_ITEM}.make ("John von Neumann", "Budapest, Hungary", "jvn@ias.edu"))
			items.extend (create {CONTACT_ITEM}.make ("Donald Knuth", "Stanford University, California", "knuth@cs.stanford.edu"))
			items.extend (create {CONTACT_ITEM}.make ("Barbara Liskov", "Cambridge, Massachusetts", "liskov@csail.mit.edu"))
			items.extend (create {CONTACT_ITEM}.make ("Leslie Lamport", "New York City, New York", "lamport@microsoft.com"))
			items.extend (create {CONTACT_ITEM}.make ("Ken Thompson", "Alameda County, California", "ken@plan9.bell-labs.com"))
			items.extend (create {CONTACT_ITEM}.make ("Dennis Ritchie", "Bronxville, New York", "dmr@bell-labs.com"))
			items.extend (create {CONTACT_ITEM}.make ("Bjarne Stroustrup", "Aarhus, Denmark", "bjarne@stroustrup.com"))
			items.extend (create {CONTACT_ITEM}.make ("Linus Torvalds", "Helsinki, Finland", "torvalds@kernel.org"))
		end

feature {NONE} -- State

	items: ARRAYED_LIST [CONTACT_ITEM]
			-- Contact entries

	table_state: TABLE_STATE
			-- Table selection and scrolling state

	scrollbar_state: SCROLLBAR_STATE
			-- Scrollbar tracking state

	palette_index: INTEGER
			-- Active color palette theme (1..4)

	auto_exit_frames: INTEGER
			-- Auto-exit in batch mode

	frame_counter: INTEGER
			-- Rendered frame count

	Arrow_up: CHARACTER_32 = '%/0x2191/'
	Arrow_down: CHARACTER_32 = '%/0x2193/'
	Arrow_left: CHARACTER_32 = '%/0x2190/'
	Arrow_right: CHARACTER_32 = '%/0x2192/'

feature {NONE} -- Palette Theme Helpers

	theme_primary_color: COLOR
			-- Primary accent color for current palette.
		do
			inspect palette_index
			when 1 then
				Result := {COLOR}.Cyan
			when 2 then
				Result := {COLOR}.Green
			when 3 then
				Result := {COLOR}.Bright_magenta
			when 4 then
				Result := {COLOR}.Bright_red
			else
				Result := {COLOR}.Cyan
			end
		end

	theme_name: STRING_32
			-- Name of active palette.
		do
			inspect palette_index
			when 1 then Result := "Cyan / Slate"
			when 2 then Result := "Emerald / Forest"
			when 3 then Result := "Indigo / Violet"
			when 4 then Result := "Ruby / Crimson"
			else Result := "Default"
			end
		end

	cycle_palette
			-- Advance to next theme color.
		do
			palette_index := (palette_index \\ 4) + 1
		end

feature {NONE} -- Application Hooks

	render (a_frame: FRAME)
			-- Render table with header, alternating rows, scrollbar, and navigation footer.
		local
			l_main_layout: LAYOUT
			l_main_chunks: ARRAY [RECT]
			l_header_area, l_body_area, l_footer_area: RECT
			l_table_area, l_scroll_area: RECT
			l_header_para, l_footer_para: TUI_PARAGRAPH
			l_table: TUI_TABLE
			l_header_row, l_row: TABLE_ROW
			l_rows: ARRAYED_LIST [TABLE_ROW]
			l_scrollbar: TUI_SCROLLBAR
			l_header_style, l_row_sel_style, l_col_sel_style, l_cell_sel_style: STYLE
			l_normal_bg, l_alt_bg, l_accent: COLOR
			l_block: TUI_BLOCK
			l_footer_text: STRING_32
			i: INTEGER
		do
			if auto_exit_frames > 0 then
				frame_counter := frame_counter + 1
				if frame_counter >= auto_exit_frames then
					stop
				end
			end

			l_accent := theme_primary_color

			-- 3-tier layout: Header (1), Table body (Flex 1), Footer (2)
			create l_main_layout.make_vertical (<<
				{CONSTRAINTS}.fixed (1),
				{CONSTRAINTS}.flex (1),
				{CONSTRAINTS}.fixed (2)
			>>)
			l_main_chunks := l_main_layout.split (a_frame.area)
			l_header_area := l_main_chunks [1]
			l_body_area := l_main_chunks [2]
			l_footer_area := l_main_chunks [3]

			-- Header
			create l_header_style.make_fg (l_accent)
			l_header_style := l_header_style.with_bold
			create l_header_para.make (create {TEXT}.make_styled ("EiffelTUI Interactive Table Example", l_header_style))
			l_header_para := l_header_para.with_alignment ({TEXT_ALIGNMENT}.center)
			a_frame.render_widget (l_header_para, l_header_area)

			-- Split body horizontally into Table (Flex 1) and Scrollbar (Fixed 1)
			l_table_area := l_body_area
			l_scroll_area := create {RECT}.make (l_body_area.right - 1, l_body_area.y, 1, l_body_area.height)

			-- Table Data Rows
			create l_rows.make (items.count)
			l_normal_bg := create {COLOR}.make_rgb (15, 23, 42)
			l_alt_bg := create {COLOR}.make_rgb (30, 41, 59)

			from i := 1 until i > items.count loop
				create l_row.make_raw (<<items [i].name, items [i].address, items [i].email>>)
				if i \\ 2 = 1 then
					l_row := l_row.with_style (create {STYLE}.make_with_colors ({COLOR}.White, l_normal_bg))
				else
					l_row := l_row.with_style (create {STYLE}.make_with_colors ({COLOR}.Bright_white, l_alt_bg))
				end
				l_rows.extend (l_row)
				i := i + 1
			end

			-- Table Header Row
			create l_header_row.make_raw (<<"Name", "Address", "Email">>)
			l_header_row := l_header_row.with_style ((create {STYLE}.make_with_colors ({COLOR}.Black, l_accent)).with_bold)

			-- Outer Table Block
			create l_block.make
			l_block := l_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (create {STYLE}.make_fg (l_accent)).
				with_title (" Pioneers of Computing ")

			-- Highlight styles
			create l_row_sel_style.make_with_colors ({COLOR}.Bright_yellow, create {COLOR}.make_rgb (55, 65, 81))
			create l_col_sel_style.make_fg ({COLOR}.Bright_cyan)
			create l_cell_sel_style.make_with_colors ({COLOR}.Black, {COLOR}.Bright_yellow)

			create l_table.make (
				l_rows,
				<<
					{CONSTRAINTS}.fixed (22),
					{CONSTRAINTS}.fixed (34),
					{CONSTRAINTS}.flex (1)
				>>
			)
			l_table := l_table.with_block (l_block).
				with_header (l_header_row).
				with_row_highlight_style (l_row_sel_style).
				with_column_highlight_style (l_col_sel_style).
				with_cell_highlight_style (l_cell_sel_style).
				with_highlight_symbol ("> ")

			a_frame.render_stateful_widget (l_table, l_table_area, table_state)

			-- Scrollbar
			scrollbar_state.set_content_length (items.count)
			if table_state.has_selection and table_state.selected >= 1 then
				scrollbar_state.set_position (table_state.selected - 1)
			end
			create l_scrollbar.make ({SCROLLBAR_ORIENTATION}.vertical_right)
			l_scrollbar := l_scrollbar.with_thumb_style (create {STYLE}.make_fg (l_accent))
			a_frame.render_stateful_widget (l_scrollbar, l_scroll_area, scrollbar_state)

			-- Footer Instructions
			create l_footer_text.make (128)
			l_footer_text.append_character ('(')
			l_footer_text.append_character (Arrow_up)
			l_footer_text.append_string_general ("/k) Up | (")
			l_footer_text.append_character (Arrow_down)
			l_footer_text.append_string_general ("/j) Down | (")
			l_footer_text.append_character (Arrow_left)
			l_footer_text.append_string_general ("/h) Left Col | (")
			l_footer_text.append_character (Arrow_right)
			l_footer_text.append_string_general ("/l) Right Col | (c) Cycle Palette: ")
			l_footer_text.append (theme_name)
			l_footer_text.append_string_general (" | (q) Quit")
			create l_footer_para.make (create {TEXT}.make_styled (l_footer_text, create {STYLE}.make_fg ({COLOR}.Dark_gray)))
			l_footer_para := l_footer_para.with_alignment ({TEXT_ALIGNMENT}.center)
			a_frame.render_widget (l_footer_para, l_footer_area)
		end

	process (a_event: EVENT)
			-- Handle navigation and palette switching.
		do
			if attached {KEY_EVENT} a_event as k and then k.is_press then
				if k.code.is_escape or else (k.code.is_char and then (k.code.character = 'q' or k.code.character = 'Q')) then
					stop
				elseif k.code.is_down or else (k.code.is_char and then k.code.character = 'j') then
					table_state.select_next (items.count)
				elseif k.code.is_up or else (k.code.is_char and then k.code.character = 'k') then
					table_state.select_previous (items.count)
				elseif k.code.is_right or else (k.code.is_char and then k.code.character = 'l') then
					table_state.select_next_column (3)
				elseif k.code.is_left or else (k.code.is_char and then k.code.character = 'h') then
					table_state.select_previous_column (3)
				elseif k.code.is_char and then (k.code.character = 'c' or k.code.character = 'C') then
					cycle_palette
				end
			end
		end

end
