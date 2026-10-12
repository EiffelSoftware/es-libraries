note
	description: "[
		Tier 3 Layout & Visualization Example: Constraints (Ratatui 1-to-1).
		Interactive tabbed exploration of layout constraint behavior and solver priorities
		for Min, Max, Length, Percentage, Ratio, and Fill constraints.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	EXAMPLE_CONSTRAINTS

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
			-- Initialize and launch Constraints showcase.
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
			-- Setup tab names, explanations, and constraint scenarios.
		do
			selected_tab := 1
			scroll_offset := 0
			init_tabs
		end

	init_tabs
			-- Setup tab definitions.
		do
			create tab_names.make (6)
			tab_names.extend ("Min")
			tab_names.extend ("Max")
			tab_names.extend ("Length")
			tab_names.extend ("Percentage")
			tab_names.extend ("Ratio")
			tab_names.extend ("Fill")

			create tab_priorities.make (6)
			tab_priorities.extend ("Priority 2 (Lower than Length, higher than Percentage)")
			tab_priorities.extend ("Priority 2 (Lower than Length, higher than Percentage)")
			tab_priorities.extend ("Priority 1 (Highest priority; rigidly respected first)")
			tab_priorities.extend ("Priority 3 (Calculated from parent container area)")
			tab_priorities.extend ("Priority 3 (Proportional integer numerator/denominator share)")
			tab_priorities.extend ("Priority 4 (Lowest priority; greedily absorbs all remaining slack)")

			create tab_summaries.make (6)
			tab_summaries.extend ("Min guarantees at least the specified cells, but will grow if extra space exists.")
			tab_summaries.extend ("Max bounds the maximum size to specified cells, but allows shrinking if space is scarce.")
			tab_summaries.extend ("Length enforces an exact fixed cell count, resisting resizing whenever possible.")
			tab_summaries.extend ("Percentage allocates an exact percentage (0-100%) of the total available width.")
			tab_summaries.extend ("Ratio allocates an exact fraction (N / D) of the total available width.")
			tab_summaries.extend ("Fill shares all remaining unallocated space weighted against other Fill constraints.")
		end

feature {NONE} -- State

	selected_tab: INTEGER
			-- Active tab index (1..6)

	scroll_offset: INTEGER
			-- Vertical scroll offset in lines

	tab_names: ARRAYED_LIST [STRING_32]
			-- Names of the 6 constraint tabs

	tab_priorities: ARRAYED_LIST [STRING_32]
			-- Solver priority rank descriptions

	tab_summaries: ARRAYED_LIST [STRING_32]
			-- Detailed explanation for each constraint type

	auto_exit_frames: INTEGER
			-- Auto-exit frame limit for batch runs

	frame_counter: INTEGER
			-- Rendered frame counter

feature {NONE} -- Rendering

	render (a_frame: FRAME)
			-- Draw constraint explorer layout.
		local
			l_main_layout: LAYOUT
			l_main_chunks: ARRAY [RECT]
			l_header_area, l_tab_area, l_body_area, l_footer_area: RECT
		do
			if auto_exit_frames > 0 then
				frame_counter := frame_counter + 1
				if frame_counter >= auto_exit_frames then
					stop
				end
			end

			-- Vertical structure: Header(2), Tabs(3), Body(Flex 1), Footer(2)
			create l_main_layout.make_vertical (<<
				{CONSTRAINTS}.fixed (2),
				{CONSTRAINTS}.fixed (3),
				{CONSTRAINTS}.flex (1),
				{CONSTRAINTS}.fixed (2)
			>>)
			l_main_chunks := l_main_layout.split (a_frame.area)
			l_header_area := l_main_chunks [1]
			l_tab_area := l_main_chunks [2]
			l_body_area := l_main_chunks [3]
			l_footer_area := l_main_chunks [4]

			render_header (a_frame, l_header_area)
			render_tabs (a_frame, l_tab_area)
			render_body (a_frame, l_body_area)
			render_footer (a_frame, l_footer_area)
		end

	render_header (a_frame: FRAME; a_area: RECT)
			-- Render top title and current constraint priority.
		local
			l_para: TUI_PARAGRAPH
			l_text: TEXT
			l_line: TEXT_LINE
		do
			create l_text.make_empty
			create l_line.make_empty
			l_line.append_span (create {TEXT_SPAN}.make (
				"EiffelTUI Layout Constraints Solver",
				(create {STYLE}.make_fg ({COLOR}.Bright_cyan)).with_bold
			))
			l_line.append_span (create {TEXT_SPAN}.make (
				{STRING_32} "  --  " + tab_names [selected_tab] + " Constraints",
				(create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold
			))
			l_text.append_line (l_line)

			create l_line.make_empty
			l_line.append_span (create {TEXT_SPAN}.make (
				"Priority Level: ",
				create {STYLE}.make_fg ({COLOR}.Gray)
			))
			l_line.append_span (create {TEXT_SPAN}.make (
				tab_priorities [selected_tab],
				create {STYLE}.make_fg ({COLOR}.Bright_green)
			))
			l_text.append_line (l_line)

			create l_para.make (l_text)
			a_frame.render_widget (l_para, a_area)
		end

	render_tabs (a_frame: FRAME; a_area: RECT)
			-- Render clickable/selectable tab row.
		local
			l_layout: LAYOUT
			l_chunks: ARRAY [RECT]
			i: INTEGER
			l_block: TUI_BLOCK
			l_para: TUI_PARAGRAPH
			l_text: STRING_32
			l_style: STYLE
		do
			create l_layout.make_horizontal (<<
				{CONSTRAINTS}.ratio (1, 6),
				{CONSTRAINTS}.ratio (1, 6),
				{CONSTRAINTS}.ratio (1, 6),
				{CONSTRAINTS}.ratio (1, 6),
				{CONSTRAINTS}.ratio (1, 6),
				{CONSTRAINTS}.ratio (1, 6)
			>>)
			l_chunks := l_layout.split (a_area)

			from
				i := 1
			until
				i > tab_names.count or i > l_chunks.count
			loop
				create l_block.make
				l_block := l_block.with_borders ({BORDERS}.all_borders).with_border_type ({BORDER_TYPE}.rounded)

				if i = selected_tab then
					l_block := l_block.with_border_style (create {STYLE}.make_fg ({COLOR}.Bright_yellow))
					l_style := (create {STYLE}.make_with_colors ({COLOR}.Black, {COLOR}.Bright_yellow)).with_bold
				else
					l_block := l_block.with_border_style (create {STYLE}.make_fg ({COLOR}.Dark_gray))
					l_style := create {STYLE}.make_fg ({COLOR}.Gray)
				end
				a_frame.render_widget (l_block, l_chunks [i])

				create l_text.make (16)
				l_text.append_integer (i)
				l_text.append_string_general (". ")
				l_text.append_string (tab_names [i])
				create l_para.make (create {TEXT}.make_styled (l_text, l_style))
				l_para := l_para.with_alignment ({TEXT_ALIGNMENT}.center)
				a_frame.render_widget (l_para, l_block.inner (l_chunks [i]))

				i := i + 1
			end
		end

	render_body (a_frame: FRAME; a_area: RECT)
			-- Render detailed scenarios for the selected tab.
		local
			l_outer_block: TUI_BLOCK
			l_inner: RECT
			l_vlayout: LAYOUT
			l_vchunks: ARRAY [RECT]
			l_summary_para: TUI_PARAGRAPH
			l_scenario_area: RECT
		do
			create l_outer_block.make
			l_outer_block := l_outer_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (create {STYLE}.make_fg ({COLOR}.Bright_cyan)).
				with_title (" Solver Execution Details ")
			a_frame.render_widget (l_outer_block, a_area)
			l_inner := l_outer_block.inner (a_area)

			create l_vlayout.make_vertical (<<
				{CONSTRAINTS}.fixed (2),
				{CONSTRAINTS}.flex (1)
			>>)
			l_vchunks := l_vlayout.split (l_inner)

			-- Summary note
			create l_summary_para.make (create {TEXT}.make_styled (
				tab_summaries [selected_tab],
				(create {STYLE}.make_fg ({COLOR}.White)).with_italic
			))
			a_frame.render_widget (l_summary_para, l_vchunks [1])

			-- Scenarios
			l_scenario_area := l_vchunks [2]
			inspect selected_tab
			when 1 then render_min_scenarios (a_frame, l_scenario_area)
			when 2 then render_max_scenarios (a_frame, l_scenario_area)
			when 3 then render_length_scenarios (a_frame, l_scenario_area)
			when 4 then render_percentage_scenarios (a_frame, l_scenario_area)
			when 5 then render_ratio_scenarios (a_frame, l_scenario_area)
			when 6 then render_fill_scenarios (a_frame, l_scenario_area)
			else
			end
		end

	render_min_scenarios (a_frame: FRAME; a_area: RECT)
			-- Render Min constraint test scenarios.
		local
			l_rows: ARRAY [TUPLE [title: READABLE_STRING_GENERAL; constraints: ARRAY [CONSTRAINT]]]
		do
			l_rows := <<
				["1. Min(20) with available excess space expands to fill", <<{CONSTRAINTS}.min_size (20)>>],
				["2. Min(20) alongside Fill(1) and Fill(2)", <<{CONSTRAINTS}.min_size (20), {CONSTRAINTS}.flex (1), {CONSTRAINTS}.flex (2)>>],
				["3. Min(30) alongside Length(15)", <<{CONSTRAINTS}.min_size (30), {CONSTRAINTS}.fixed (15)>>],
				["4. Multiple Min constraints: Min(10), Min(20), Min(15)", <<{CONSTRAINTS}.min_size (10), {CONSTRAINTS}.min_size (20), {CONSTRAINTS}.min_size (15)>>]
			>>
			render_scenario_rows (a_frame, a_area, l_rows)
		end

	render_max_scenarios (a_frame: FRAME; a_area: RECT)
			-- Render Max constraint test scenarios.
		local
			l_rows: ARRAY [TUPLE [title: READABLE_STRING_GENERAL; constraints: ARRAY [CONSTRAINT]]]
		do
			l_rows := <<
				["1. Max(30) caps width when ample space is present", <<{CONSTRAINTS}.max_size (30)>>],
				["2. Max(20) paired with Fill(1) to absorb remaining space", <<{CONSTRAINTS}.max_size (20), {CONSTRAINTS}.flex (1)>>],
				["3. Max(25) vs Length(20)", <<{CONSTRAINTS}.max_size (25), {CONSTRAINTS}.fixed (20)>>],
				["4. Max(15) and Percentage(50)", <<{CONSTRAINTS}.max_size (15), {CONSTRAINTS}.percentage (50)>>]
			>>
			render_scenario_rows (a_frame, a_area, l_rows)
		end

	render_length_scenarios (a_frame: FRAME; a_area: RECT)
			-- Render Length constraint test scenarios.
		local
			l_rows: ARRAY [TUPLE [title: READABLE_STRING_GENERAL; constraints: ARRAY [CONSTRAINT]]]
		do
			l_rows := <<
				["1. Rigid Length(25) fixed dimension", <<{CONSTRAINTS}.fixed (25)>>],
				["2. Multiple Length blocks: Length(15), Length(20), Length(15)", <<{CONSTRAINTS}.fixed (15), {CONSTRAINTS}.fixed (20), {CONSTRAINTS}.fixed (15)>>],
				["3. Length(20) with Fill(1) taking the slack", <<{CONSTRAINTS}.fixed (20), {CONSTRAINTS}.flex (1)>>],
				["4. Length(10) with Percentage(30) and Ratio(1, 4)", <<{CONSTRAINTS}.fixed (10), {CONSTRAINTS}.percentage (30), {CONSTRAINTS}.ratio (1, 4)>>]
			>>
			render_scenario_rows (a_frame, a_area, l_rows)
		end

	render_percentage_scenarios (a_frame: FRAME; a_area: RECT)
			-- Render Percentage constraint test scenarios.
		local
			l_rows: ARRAY [TUPLE [title: READABLE_STRING_GENERAL; constraints: ARRAY [CONSTRAINT]]]
		do
			l_rows := <<
				["1. Exact 25%%, 50%%, 25%% distribution", <<{CONSTRAINTS}.percentage (25), {CONSTRAINTS}.percentage (50), {CONSTRAINTS}.percentage (25)>>],
				["2. Percentage(30) alongside Length(20)", <<{CONSTRAINTS}.percentage (30), {CONSTRAINTS}.fixed (20)>>],
				["3. Percentage(40) with Fill(1) and Fill(2)", <<{CONSTRAINTS}.percentage (40), {CONSTRAINTS}.flex (1), {CONSTRAINTS}.flex (2)>>],
				["4. Under-allocated: Percentage(20) + Percentage(30) (50%% slack)", <<{CONSTRAINTS}.percentage (20), {CONSTRAINTS}.percentage (30)>>]
			>>
			render_scenario_rows (a_frame, a_area, l_rows)
		end

	render_ratio_scenarios (a_frame: FRAME; a_area: RECT)
			-- Render Ratio constraint test scenarios.
		local
			l_rows: ARRAY [TUPLE [title: READABLE_STRING_GENERAL; constraints: ARRAY [CONSTRAINT]]]
		do
			l_rows := <<
				["1. Quarter / Half / Quarter (1/4, 2/4, 1/4)", <<{CONSTRAINTS}.ratio (1, 4), {CONSTRAINTS}.ratio (2, 4), {CONSTRAINTS}.ratio (1, 4)>>],
				["2. Golden proportion: Ratio(1, 3) and Ratio(2, 3)", <<{CONSTRAINTS}.ratio (1, 3), {CONSTRAINTS}.ratio (2, 3)>>],
				["3. Ratio(1, 5) with Length(15) and Fill(1)", <<{CONSTRAINTS}.ratio (1, 5), {CONSTRAINTS}.fixed (15), {CONSTRAINTS}.flex (1)>>],
				["4. Ratio(2, 5) and Ratio(3, 5)", <<{CONSTRAINTS}.ratio (2, 5), {CONSTRAINTS}.ratio (3, 5)>>]
			>>
			render_scenario_rows (a_frame, a_area, l_rows)
		end

	render_fill_scenarios (a_frame: FRAME; a_area: RECT)
			-- Render Fill constraint test scenarios.
		local
			l_rows: ARRAY [TUPLE [title: READABLE_STRING_GENERAL; constraints: ARRAY [CONSTRAINT]]]
		do
			l_rows := <<
				["1. Equal share: Fill(1) and Fill(1)", <<{CONSTRAINTS}.flex (1), {CONSTRAINTS}.flex (1)>>],
				["2. Weighted proportions: Fill(1), Fill(2), Fill(3)", <<{CONSTRAINTS}.flex (1), {CONSTRAINTS}.flex (2), {CONSTRAINTS}.flex (3)>>],
				["3. Fill(1) absorbing excess space after Length(25)", <<{CONSTRAINTS}.fixed (25), {CONSTRAINTS}.flex (1)>>],
				["4. Fill(1) and Fill(2) alongside Min(20) and Max(30)", <<{CONSTRAINTS}.min_size (20), {CONSTRAINTS}.max_size (30), {CONSTRAINTS}.flex (1), {CONSTRAINTS}.flex (2)>>]
			>>
			render_scenario_rows (a_frame, a_area, l_rows)
		end

	render_scenario_rows (
		a_frame: FRAME;
		a_area: RECT;
		a_rows: ARRAY [TUPLE [title: READABLE_STRING_GENERAL; constraints: ARRAY [CONSTRAINT]]]
	)
			-- Render structured scenario cards.
		local
			l_layout: LAYOUT
			l_chunks: ARRAY [RECT]
			r: INTEGER
			l_card_layout: LAYOUT
			l_card_chunks: ARRAY [RECT]
			l_title_area, l_track_area: RECT
			l_title_para: TUI_PARAGRAPH
			l_c_layout: LAYOUT
			l_c_chunks: ARRAY [RECT]
			c: INTEGER
			l_box: TUI_BLOCK
			l_info: STRING_32
			l_info_para: TUI_PARAGRAPH
			l_color: COLOR
		do
			create l_layout.make_vertical (<<
				{CONSTRAINTS}.fixed (4),
				{CONSTRAINTS}.fixed (4),
				{CONSTRAINTS}.fixed (4),
				{CONSTRAINTS}.fixed (4)
			>>)
			l_chunks := l_layout.split (a_area)

			from
				r := 1
			until
				r > a_rows.count or r > l_chunks.count
			loop
				-- Each card has title (1 row) and track (3 rows)
				create l_card_layout.make_vertical (<<
					{CONSTRAINTS}.fixed (1),
					{CONSTRAINTS}.fixed (3)
				>>)
				l_card_chunks := l_card_layout.split (l_chunks [r])
				l_title_area := l_card_chunks [1]
				l_track_area := l_card_chunks [2]

				create l_title_para.make (create {TEXT}.make_styled (
					a_rows [r].title,
					(create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold
				))
				a_frame.render_widget (l_title_para, l_title_area)

				create l_c_layout.make_horizontal (a_rows [r].constraints)
				l_c_layout := l_c_layout.with_spacing (1)
				l_c_chunks := l_c_layout.split (l_track_area)

				from
					c := 1
				until
					c > l_c_chunks.count
				loop
					l_color := block_color (c)
					create l_box.make
					l_box := l_box.with_borders ({BORDERS}.all_borders).
						with_border_type ({BORDER_TYPE}.plain).
						with_border_style (create {STYLE}.make_fg (l_color))
					a_frame.render_widget (l_box, l_c_chunks [c])

					create l_info.make (16)
					l_info.append_string (constraint_label (a_rows [r].constraints [c]))
					l_info.append_string_general (" [")
					l_info.append_integer (l_c_chunks [c].width.to_integer_32)
					l_info.append_string_general ("px]")

					create l_info_para.make (create {TEXT}.make_styled (l_info, create {STYLE}.make_fg (l_color)))
					l_info_para := l_info_para.with_alignment ({TEXT_ALIGNMENT}.center)
					a_frame.render_widget (l_info_para, l_box.inner (l_c_chunks [c]))
					c := c + 1
				end

				r := r + 1
			end
		end

	render_footer (a_frame: FRAME; a_area: RECT)
			-- Render navigation controls.
		local
			l_para: TUI_PARAGRAPH
			l_text: TEXT
			l_line: TEXT_LINE
		do
			create l_text.make_empty
			create l_line.make_empty
			l_line.append_span (create {TEXT_SPAN}.make ("[Tab/Left/Right] ", (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold))
			l_line.append_span (create {TEXT_SPAN}.make ("Switch Tab  ", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_line.append_span (create {TEXT_SPAN}.make ("[1-6] ", (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold))
			l_line.append_span (create {TEXT_SPAN}.make ("Jump to Tab  ", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_line.append_span (create {TEXT_SPAN}.make ("[q/Esc] ", (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold))
			l_line.append_span (create {TEXT_SPAN}.make ("Quit", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_text.append_line (l_line)

			create l_para.make (l_text)
			l_para := l_para.with_alignment ({TEXT_ALIGNMENT}.center)
			a_frame.render_widget (l_para, a_area)
		end

feature {NONE} -- Helpers

	block_color (a_index: INTEGER): COLOR
			-- Color palette for blocks.
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
				Result.append_string_general ("Length(")
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
					elseif ch >= '1' and ch <= '6' then
						selected_tab := ch.code - ('0').code
					elseif ch = '%T' then
						selected_tab := (selected_tab \\ tab_names.count) + 1
					end
				elseif k.code.is_tab or k.code.is_right then
					selected_tab := (selected_tab \\ tab_names.count) + 1
				elseif k.code.is_left then
					selected_tab := selected_tab - 1
					if selected_tab < 1 then
						selected_tab := tab_names.count
					end
				end
			end
		end

end
