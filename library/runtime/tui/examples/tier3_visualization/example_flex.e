note
	description: "[
		Tier 3 Layout & Visualization Example: Flex Justification (Ratatui 1-to-1).
		Demonstrates layout space distribution across Start, Center, End,
		SpaceBetween, SpaceAround, SpaceEvenly, and Legacy flex modes.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	EXAMPLE_FLEX

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
			-- Initialize and launch Flex layout example.
		local
			l_args: ARGUMENTS_32
			i: INTEGER
		do
			init_state
			Precursor
			set_tick_rate (50)
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
			-- Initialize and run for `a_frames` frames in batch mode.
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
			-- Setup datasets, flex modes, and initial settings.
		do
			spacing_value := 1
			is_horizontal := True
			selected_dataset := 1
			selected_flex_index := 1
			init_flex_modes
			init_datasets
		end

	init_flex_modes
			-- Initialize list of available flex modes.
		do
			create flex_modes.make (7)
			flex_modes.extend ({FLEX_JUSTIFY}.start_align)
			flex_modes.extend ({FLEX_JUSTIFY}.center)
			flex_modes.extend ({FLEX_JUSTIFY}.end_justify)
			flex_modes.extend ({FLEX_JUSTIFY}.space_between)
			flex_modes.extend ({FLEX_JUSTIFY}.space_around)
			flex_modes.extend ({FLEX_JUSTIFY}.space_evenly)
			flex_modes.extend ({FLEX_JUSTIFY}.legacy)

			create flex_names.make (7)
			flex_names.extend ("Start")
			flex_names.extend ("Center")
			flex_names.extend ("End")
			flex_names.extend ("SpaceBetween")
			flex_names.extend ("SpaceAround")
			flex_names.extend ("SpaceEvenly")
			flex_names.extend ("Legacy")
		end

	init_datasets
			-- Initialize constraint scenario datasets.
		local
			l_set: ARRAYED_LIST [CONSTRAINT]
		do
			create dataset_descriptions.make (6)
			create dataset_items.make (6)

			-- Dataset 1: Mixed constraints
			dataset_descriptions.extend ("Mixed: Length(12), Min(10), Max(16), Percentage(15), Ratio(1, 8), Fill(1)")
			create l_set.make (6)
			l_set.extend ({CONSTRAINTS}.fixed (12))
			l_set.extend ({CONSTRAINTS}.min_size (10))
			l_set.extend ({CONSTRAINTS}.max_size (16))
			l_set.extend ({CONSTRAINTS}.percentage (15))
			l_set.extend ({CONSTRAINTS}.ratio (1, 8))
			l_set.extend ({CONSTRAINTS}.flex (1))
			dataset_items.extend (l_set)

			-- Dataset 2: Fill weights scaling
			dataset_descriptions.extend ("Fill Scaling: Length(16), Fill(1), Fill(2), Fill(1)")
			create l_set.make (4)
			l_set.extend ({CONSTRAINTS}.fixed (16))
			l_set.extend ({CONSTRAINTS}.flex (1))
			l_set.extend ({CONSTRAINTS}.flex (2))
			l_set.extend ({CONSTRAINTS}.flex (1))
			dataset_items.extend (l_set)

			-- Dataset 3: Equal fixed lengths with spacing
			dataset_descriptions.extend ("Discrete Blocks: 4 x Length(14)")
			create l_set.make (4)
			l_set.extend ({CONSTRAINTS}.fixed (14))
			l_set.extend ({CONSTRAINTS}.fixed (14))
			l_set.extend ({CONSTRAINTS}.fixed (14))
			l_set.extend ({CONSTRAINTS}.fixed (14))
			dataset_items.extend (l_set)

			-- Dataset 4: Min and Max bounds
			dataset_descriptions.extend ("Bounds: Min(15), Max(25), Length(18)")
			create l_set.make (3)
			l_set.extend ({CONSTRAINTS}.min_size (15))
			l_set.extend ({CONSTRAINTS}.max_size (25))
			l_set.extend ({CONSTRAINTS}.fixed (18))
			dataset_items.extend (l_set)

			-- Dataset 5: Ratios and Percentages
			dataset_descriptions.extend ("Proportions: Ratio(1, 4), Percentage(25), Ratio(1, 2)")
			create l_set.make (3)
			l_set.extend ({CONSTRAINTS}.ratio (1, 4))
			l_set.extend ({CONSTRAINTS}.percentage (25))
			l_set.extend ({CONSTRAINTS}.ratio (1, 2))
			dataset_items.extend (l_set)

			-- Dataset 6: Excess Space Absorption
			dataset_descriptions.extend ("Excess Space: Percentage(40), Fill(2), Min(20)")
			create l_set.make (3)
			l_set.extend ({CONSTRAINTS}.percentage (40))
			l_set.extend ({CONSTRAINTS}.flex (2))
			l_set.extend ({CONSTRAINTS}.min_size (20))
			dataset_items.extend (l_set)
		end

feature {NONE} -- State

	spacing_value: INTEGER
			-- Spacing between child chunks

	is_horizontal: BOOLEAN
			-- True for horizontal layout, False for vertical

	selected_dataset: INTEGER
			-- Index of currently active dataset (1..count)

	selected_flex_index: INTEGER
			-- Index of currently active flex mode (1..count)

	flex_modes: ARRAYED_LIST [FLEX_JUSTIFY]
			-- Available flex justify strategies

	flex_names: ARRAYED_LIST [STRING_32]
			-- Display names for flex modes

	dataset_descriptions: ARRAYED_LIST [STRING_32]
			-- Textual summaries of constraint datasets

	dataset_items: ARRAYED_LIST [ARRAYED_LIST [CONSTRAINT]]
			-- List of constraint sets

	auto_exit_frames: INTEGER
			-- Batch mode frame counter

	frame_counter: INTEGER
			-- Rendered frame count

feature {NONE} -- Rendering

	render (a_frame: FRAME)
			-- Draw flex layout showcase.
		local
			l_main_layout: LAYOUT
			l_main_chunks: ARRAY [RECT]
			l_header_area, l_body_area, l_all_modes_area, l_footer_area: RECT
		do
			if auto_exit_frames > 0 then
				frame_counter := frame_counter + 1
				if frame_counter >= auto_exit_frames then
					stop
				end
			end

			-- Master vertical layout: Header(3), Primary View(Flex 1), Comparative Modes(8), Footer(2)
			create l_main_layout.make_vertical (<<
				{CONSTRAINTS}.fixed (3),
				{CONSTRAINTS}.flex (1),
				{CONSTRAINTS}.fixed (11),
				{CONSTRAINTS}.fixed (2)
			>>)
			l_main_chunks := l_main_layout.split (a_frame.area)
			l_header_area := l_main_chunks [1]
			l_body_area := l_main_chunks [2]
			l_all_modes_area := l_main_chunks [3]
			l_footer_area := l_main_chunks [4]

			render_header (a_frame, l_header_area)
			render_primary_view (a_frame, l_body_area)
			render_comparative_modes (a_frame, l_all_modes_area)
			render_footer (a_frame, l_footer_area)
		end

	render_header (a_frame: FRAME; a_area: RECT)
			-- Render top header with status badges.
		local
			l_header_para: TUI_PARAGRAPH
			l_text: TEXT
			l_line1, l_line2: TEXT_LINE
			l_badge: TEXT_SPAN
			l_dir_str: STRING_32
		do
			create l_text.make_empty
			create l_line1.make_empty
			l_line1.append_span (create {TEXT_SPAN}.make (
				"EiffelTUI Flex Justification Showcase",
				(create {STYLE}.make_fg ({COLOR}.Bright_cyan)).with_bold
			))
			l_line1.append_span (create {TEXT_SPAN}.make (
				"  [Ratatui 1-to-1]",
				create {STYLE}.make_fg ({COLOR}.Dark_gray)
			))
			l_text.append_line (l_line1)

			create l_line2.make_empty
			l_line2.append_span (create {TEXT_SPAN}.make ("Mode: ", create {STYLE}.make_fg ({COLOR}.Gray)))
			create l_badge.make (
				flex_names [selected_flex_index],
				(create {STYLE}.make_with_colors ({COLOR}.Black, {COLOR}.Bright_yellow)).with_bold
			)
			l_line2.append_span (l_badge)

			l_line2.append_span (create {TEXT_SPAN}.make ("  | Spacing: ", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_line2.append_span (create {TEXT_SPAN}.make (
				spacing_value.out + " cells",
				(create {STYLE}.make_fg ({COLOR}.Bright_green)).with_bold
			))

			l_line2.append_span (create {TEXT_SPAN}.make ("  | Direction: ", create {STYLE}.make_fg ({COLOR}.Gray)))
			if is_horizontal then
				l_dir_str := "Horizontal"
			else
				l_dir_str := "Vertical"
			end
			l_line2.append_span (create {TEXT_SPAN}.make (
				l_dir_str,
				(create {STYLE}.make_fg ({COLOR}.Bright_magenta)).with_bold
			))

			l_line2.append_span (create {TEXT_SPAN}.make ("  | Scenario: ", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_line2.append_span (create {TEXT_SPAN}.make (
				selected_dataset.out + "/" + dataset_items.count.out,
				(create {STYLE}.make_fg ({COLOR}.Bright_white)).with_bold
			))
			l_text.append_line (l_line2)

			create l_header_para.make (l_text)
			a_frame.render_widget (l_header_para, a_area)
		end

	render_primary_view (a_frame: FRAME; a_area: RECT)
			-- Render large primary view for the active flex mode.
		local
			l_block: TUI_BLOCK
			l_inner: RECT
			l_constraints: ARRAYED_LIST [CONSTRAINT]
			l_layout: LAYOUT
			l_chunks: ARRAY [RECT]
			l_title: STRING_32
			i: INTEGER
			l_box_block: TUI_BLOCK
			l_box_para: TUI_PARAGRAPH
			l_info: STRING_32
			l_color: COLOR
		do
			create l_title.make (64)
			l_title.append_string_general (" Active Flex Mode: ")
			l_title.append_string (flex_names [selected_flex_index])
			l_title.append_string_general (" -- ")
			l_title.append_string (dataset_descriptions [selected_dataset])
			l_title.append_string_general (" ")

			create l_block.make
			l_block := l_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (create {STYLE}.make_fg ({COLOR}.Bright_cyan)).
				with_title (l_title)
			a_frame.render_widget (l_block, a_area)
			l_inner := l_block.inner (a_area)

			l_constraints := dataset_items [selected_dataset]
			if is_horizontal then
				create l_layout.make_horizontal (l_constraints)
			else
				create l_layout.make_vertical (l_constraints)
			end
			l_layout := l_layout.with_spacing (spacing_value).with_flex (flex_modes [selected_flex_index])
			l_chunks := l_layout.split (l_inner)

			from
				i := 1
			until
				i > l_chunks.count
			loop
				l_color := block_color (i)
				create l_box_block.make
				l_box_block := l_box_block.with_borders ({BORDERS}.all_borders).
					with_border_type ({BORDER_TYPE}.plain).
					with_border_style (create {STYLE}.make_fg (l_color))
				a_frame.render_widget (l_box_block, l_chunks [i])

				create l_info.make (32)
				l_info.append_string (constraint_label (l_constraints [i]))
				l_info.append_character ('%N')
				l_info.append_integer (l_chunks [i].width.to_integer_32)
				l_info.append_string_general ("x")
				l_info.append_integer (l_chunks [i].height.to_integer_32)

				create l_box_para.make (create {TEXT}.make_styled (
					l_info,
					(create {STYLE}.make_fg (l_color)).with_bold
				))
				l_box_para := l_box_para.with_alignment ({TEXT_ALIGNMENT}.center)
				a_frame.render_widget (l_box_para, l_box_block.inner (l_chunks [i]))
				i := i + 1
			end
		end

	render_comparative_modes (a_frame: FRAME; a_area: RECT)
			-- Render compact comparison rows showing all flex modes side-by-side.
		local
			l_container: TUI_BLOCK
			l_inner: RECT
			l_row_layout: LAYOUT
			l_row_chunks: ARRAY [RECT]
			l_constraints: ARRAYED_LIST [CONSTRAINT]
			m, c: INTEGER
			l_flex: FLEX_JUSTIFY
			l_mode_layout: LAYOUT
			l_mode_chunks: ARRAY [RECT]
			l_label_area, l_track_area: RECT
			l_label_para: TUI_PARAGRAPH
			l_split_label: LAYOUT
			l_split_chunks: ARRAY [RECT]
			l_box_block: TUI_BLOCK
			l_style: STYLE
		do
			create l_container.make
			l_container := l_container.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (create {STYLE}.make_fg ({COLOR}.Dark_gray)).
				with_title (" All Flex Justification Modes Compared ")
			a_frame.render_widget (l_container, a_area)
			l_inner := l_container.inner (a_area)

			l_constraints := dataset_items [selected_dataset]

			-- 7 rows for 7 flex modes
			create l_row_layout.make_vertical (<<
				{CONSTRAINTS}.fixed (1),
				{CONSTRAINTS}.fixed (1),
				{CONSTRAINTS}.fixed (1),
				{CONSTRAINTS}.fixed (1),
				{CONSTRAINTS}.fixed (1),
				{CONSTRAINTS}.fixed (1),
				{CONSTRAINTS}.fixed (1)
			>>)
			l_row_chunks := l_row_layout.split (l_inner)

			from
				m := 1
			until
				m > flex_modes.count or m > l_row_chunks.count
			loop
				l_flex := flex_modes [m]

				-- Split row: label(14 cells), track(remaining)
				create l_split_label.make_horizontal (<<
					{CONSTRAINTS}.fixed (14),
					{CONSTRAINTS}.flex (1)
				>>)
				l_split_chunks := l_split_label.split (l_row_chunks [m])
				l_label_area := l_split_chunks [1]
				l_track_area := l_split_chunks [2]

				if m = selected_flex_index then
					l_style := (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold
				else
					l_style := create {STYLE}.make_fg ({COLOR}.Gray)
				end
				create l_label_para.make (create {TEXT}.make_styled (flex_names [m], l_style))
				a_frame.render_widget (l_label_para, l_label_area)

				-- Split track area using this flex mode
				create l_mode_layout.make_horizontal (l_constraints)
				l_mode_layout := l_mode_layout.with_spacing (spacing_value).with_flex (l_flex)
				l_mode_chunks := l_mode_layout.split (l_track_area)

				from
					c := 1
				until
					c > l_mode_chunks.count
				loop
					create l_box_block.make
					l_box_block := l_box_block.with_borders ({BORDERS}.all_borders).
						with_border_type ({BORDER_TYPE}.plain).
						with_border_style (create {STYLE}.make_fg (block_color (c)))
					a_frame.render_widget (l_box_block, l_mode_chunks [c])
					c := c + 1
				end

				m := m + 1
			end
		end

	render_footer (a_frame: FRAME; a_area: RECT)
			-- Render navigation and shortcut guide.
		local
			l_footer_para: TUI_PARAGRAPH
			l_text: TEXT
			l_line: TEXT_LINE
		do
			create l_text.make_empty
			create l_line.make_empty
			l_line.append_span (create {TEXT_SPAN}.make ("[Tab/f] ", (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold))
			l_line.append_span (create {TEXT_SPAN}.make ("Cycle Flex  ", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_line.append_span (create {TEXT_SPAN}.make ("[+/-] ", (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold))
			l_line.append_span (create {TEXT_SPAN}.make ("Spacing  ", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_line.append_span (create {TEXT_SPAN}.make ("[1-6] ", (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold))
			l_line.append_span (create {TEXT_SPAN}.make ("Scenarios  ", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_line.append_span (create {TEXT_SPAN}.make ("[o/Space] ", (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold))
			l_line.append_span (create {TEXT_SPAN}.make ("Orientation  ", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_line.append_span (create {TEXT_SPAN}.make ("[q/Esc] ", (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold))
			l_line.append_span (create {TEXT_SPAN}.make ("Quit", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_text.append_line (l_line)

			create l_footer_para.make (l_text)
			l_footer_para := l_footer_para.with_alignment ({TEXT_ALIGNMENT}.center)
			a_frame.render_widget (l_footer_para, a_area)
		end

feature {NONE} -- Helpers

	block_color (a_index: INTEGER): COLOR
			-- Color palette for child constraint blocks.
		do
			inspect (a_index - 1) \\ 6
			when 0 then Result := {COLOR}.Bright_cyan
			when 1 then Result := {COLOR}.Bright_green
			when 2 then Result := {COLOR}.Bright_yellow
			when 3 then Result := {COLOR}.Bright_magenta
			when 4 then Result := {COLOR}.Bright_blue
			else Result := {COLOR}.Bright_red
			end
		end

	constraint_label (a_c: CONSTRAINT): STRING_32
			-- Short description for constraint `a_c`.
		do
			create Result.make (16)
			if attached {CONSTRAINT_FIXED} a_c as f then
				Result.append_string_general ("Len(")
				Result.append_natural_16 (f.value)
				Result.append_character (')')
			elseif attached {CONSTRAINT_MIN} a_c as mn then
				Result.append_string_general ("Min(")
				Result.append_natural_16 (mn.min_value)
				Result.append_character (')')
			elseif attached {CONSTRAINT_MAX} a_c as mx then
				Result.append_string_general ("Max(")
				Result.append_natural_16 (mx.max_value)
				Result.append_character (')')
			elseif attached {CONSTRAINT_PERCENTAGE} a_c as p then
				Result.append_string_general ("Pct(")
				Result.append_natural_16 (p.percent_value)
				Result.append_string_general ("%%)")
			elseif attached {CONSTRAINT_RATIO} a_c as r then
				Result.append_string_general ("Ratio(")
				Result.append_natural_32 (r.numerator)
				Result.append_character ('/')
				Result.append_natural_32 (r.denominator)
				Result.append_character (')')
			elseif attached {CONSTRAINT_FLEX} a_c as fl then
				Result.append_string_general ("Fill(")
				Result.append_natural_16 (fl.weight)
				Result.append_character (')')
			else
				Result.append_string_general ("Constraint")
			end
		end

feature {NONE} -- Event Handling

	process (a_event: EVENT)
			-- Handle key commands.
		local
			ch: CHARACTER_32
		do
			if attached {KEY_EVENT} a_event as k and then k.is_press then
				if k.code.is_escape then
					stop
				elseif k.code.is_char then
					ch := k.code.character
					if ch = 'q' or ch = 'Q' then
						stop
					elseif ch = 'f' or ch = 'F' or ch = '%T' then
						selected_flex_index := (selected_flex_index \\ flex_modes.count) + 1
					elseif ch = '+' or ch = '=' or ch = ']' then
						if spacing_value < 10 then
							spacing_value := spacing_value + 1
						end
					elseif ch = '-' or ch = '_' or ch = '[' then
						if spacing_value > 0 then
							spacing_value := spacing_value - 1
						end
					elseif ch = 'o' or ch = 'O' or ch = ' ' then
						is_horizontal := not is_horizontal
					elseif ch >= '1' and ch <= '6' then
						selected_dataset := ch.code - ('0').code
					end
				elseif k.code.is_tab then
					selected_flex_index := (selected_flex_index \\ flex_modes.count) + 1
				elseif k.code.is_right then
					selected_flex_index := (selected_flex_index \\ flex_modes.count) + 1
				elseif k.code.is_left then
					selected_flex_index := selected_flex_index - 1
					if selected_flex_index < 1 then
						selected_flex_index := flex_modes.count
					end
				elseif k.code.is_up then
					if spacing_value < 10 then
						spacing_value := spacing_value + 1
					end
				elseif k.code.is_down then
					if spacing_value > 0 then
						spacing_value := spacing_value - 1
					end
				end
			end
		end

end
