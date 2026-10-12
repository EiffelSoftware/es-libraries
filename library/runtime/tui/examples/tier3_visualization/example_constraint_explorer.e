note
	description: "[
		Tier 3 Layout & Visualization Example: Constraint Explorer (Ratatui 1-to-1).
		Interactive layout playground with live addition, deletion, value adjustment,
		and real-time visualization across all Flex justification modes.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	EXAMPLE_CONSTRAINT_EXPLORER

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
			-- Initialize and launch Constraint Explorer.
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
			-- Setup initial dynamic constraint list and settings.
		do
			spacing_value := 1
			selected_index := 1
			selected_flex_index := 1

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

			-- Editable model: tuples of [type_id, value, value2]
			-- type_id: 1=Length, 2=Percentage, 3=Ratio, 4=Min, 5=Max, 6=Fill
			create constraint_models.make (8)
			constraint_models.extend ([1, 16, 0]) -- Length(16)
			constraint_models.extend ([2, 25, 0]) -- Percentage(25)
			constraint_models.extend ([6, 1, 0])  -- Fill(1)
			constraint_models.extend ([4, 12, 0]) -- Min(12)
		end

feature {NONE} -- State

	spacing_value: INTEGER
			-- Spacing between blocks

	selected_index: INTEGER
			-- Selected constraint in `constraint_models` (1..count)

	selected_flex_index: INTEGER
			-- Active flex mode index (1..7)

	flex_modes: ARRAYED_LIST [FLEX_JUSTIFY]
			-- Available flex modes

	flex_names: ARRAYED_LIST [STRING_32]
			-- Display names for flex modes

	constraint_models: ARRAYED_LIST [TUPLE [type_id: INTEGER; val1: INTEGER; val2: INTEGER]]
			-- User-editable constraint definitions

	auto_exit_frames: INTEGER
			-- Batch auto-exit frame limit

	frame_counter: INTEGER
			-- Rendered frame count

feature {NONE} -- Model to Constraint Conversion

	build_constraints: ARRAYED_LIST [CONSTRAINT]
			-- Convert current models to EiffelTUI CONSTRAINT objects.
		local
			i: INTEGER
			m: TUPLE [type_id: INTEGER; val1: INTEGER; val2: INTEGER]
		do
			create Result.make (constraint_models.count)
			from
				i := 1
			until
				i > constraint_models.count
			loop
				m := constraint_models [i]
				inspect m.type_id
				when 1 then
					Result.extend ({CONSTRAINTS}.fixed (m.val1.max (1).to_natural_16))
				when 2 then
					Result.extend ({CONSTRAINTS}.percentage (m.val1.min (100).max (1).to_natural_16))
				when 3 then
					Result.extend ({CONSTRAINTS}.ratio (m.val1.min (10).max (1).to_natural_32, 10))
				when 4 then
					Result.extend ({CONSTRAINTS}.min_size (m.val1.max (1).to_natural_16))
				when 5 then
					Result.extend ({CONSTRAINTS}.max_size (m.val1.max (1).to_natural_16))
				when 6 then
					Result.extend ({CONSTRAINTS}.flex (m.val1.max (1).to_natural_16))
				else
					Result.extend ({CONSTRAINTS}.fixed (10))
				end
				i := i + 1
			end
		end

	model_label (a_model: TUPLE [type_id: INTEGER; val1: INTEGER; val2: INTEGER]): STRING_32
			-- Display string for `a_model`.
		do
			create Result.make (16)
			inspect a_model.type_id
			when 1 then
				Result.append_string_general ("Length(")
				Result.append_integer (a_model.val1)
				Result.append_character (')')
			when 2 then
				Result.append_string_general ("Pct(")
				Result.append_integer (a_model.val1)
				Result.append_string_general ("%%)")
			when 3 then
				Result.append_string_general ("Ratio(")
				Result.append_integer (a_model.val1.min (10).max (1))
				Result.append_string_general ("/10)")
			when 4 then
				Result.append_string_general ("Min(")
				Result.append_integer (a_model.val1)
				Result.append_character (')')
			when 5 then
				Result.append_string_general ("Max(")
				Result.append_integer (a_model.val1)
				Result.append_character (')')
			when 6 then
				Result.append_string_general ("Fill(")
				Result.append_integer (a_model.val1)
				Result.append_character (')')
			else
				Result.append_string_general ("Unknown")
			end
		end

feature {NONE} -- Rendering

	render (a_frame: FRAME)
			-- Draw constraint playground.
		local
			l_main_layout: LAYOUT
			l_main_chunks: ARRAY [RECT]
			l_header_area, l_preview_area, l_control_area, l_footer_area: RECT
		do
			if auto_exit_frames > 0 then
				frame_counter := frame_counter + 1
				if frame_counter >= auto_exit_frames then
					stop
				end
			end

			-- Vertical structure: Header(3), Live Comparison(Flex 1), Constraint Inspector(7), Footer(2)
			create l_main_layout.make_vertical (<<
				{CONSTRAINTS}.fixed (3),
				{CONSTRAINTS}.flex (1),
				{CONSTRAINTS}.fixed (7),
				{CONSTRAINTS}.fixed (2)
			>>)
			l_main_chunks := l_main_layout.split (a_frame.area)
			l_header_area := l_main_chunks [1]
			l_preview_area := l_main_chunks [2]
			l_control_area := l_main_chunks [3]
			l_footer_area := l_main_chunks [4]

			render_header (a_frame, l_header_area)
			render_live_comparison (a_frame, l_preview_area)
			render_control_panel (a_frame, l_control_area)
			render_footer (a_frame, l_footer_area)
		end

	render_header (a_frame: FRAME; a_area: RECT)
			-- Render title and active playground properties.
		local
			l_para: TUI_PARAGRAPH
			l_text: TEXT
			l_line: TEXT_LINE
		do
			create l_text.make_empty
			create l_line.make_empty
			l_line.append_span (create {TEXT_SPAN}.make (
				"EiffelTUI Interactive Constraint Explorer Playground",
				(create {STYLE}.make_fg ({COLOR}.Bright_cyan)).with_bold
			))
			l_line.append_span (create {TEXT_SPAN}.make (
				"  [Ratatui 1-to-1]",
				create {STYLE}.make_fg ({COLOR}.Dark_gray)
			))
			l_text.append_line (l_line)

			create l_line.make_empty
			l_line.append_span (create {TEXT_SPAN}.make ("Selected: ", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_line.append_span (create {TEXT_SPAN}.make (
				{STRING_32} "#" + selected_index.out + " " + model_label (constraint_models [selected_index]),
				(create {STYLE}.make_with_colors ({COLOR}.Black, {COLOR}.Bright_yellow)).with_bold
			))
			l_line.append_span (create {TEXT_SPAN}.make ("  | Spacing: ", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_line.append_span (create {TEXT_SPAN}.make (
				spacing_value.out + " cells",
				(create {STYLE}.make_fg ({COLOR}.Bright_green)).with_bold
			))
			l_line.append_span (create {TEXT_SPAN}.make ("  | Active Flex: ", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_line.append_span (create {TEXT_SPAN}.make (
				flex_names [selected_flex_index],
				(create {STYLE}.make_fg ({COLOR}.Bright_magenta)).with_bold
			))
			l_line.append_span (create {TEXT_SPAN}.make ("  | Total Constraints: ", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_line.append_span (create {TEXT_SPAN}.make (
				constraint_models.count.out,
				create {STYLE}.make_fg ({COLOR}.Bright_white)
			))
			l_text.append_line (l_line)

			create l_para.make (l_text)
			a_frame.render_widget (l_para, a_area)
		end

	render_live_comparison (a_frame: FRAME; a_area: RECT)
			-- Render real-time multi-flex comparison view.
		local
			l_container: TUI_BLOCK
			l_inner: RECT
			l_constraints: ARRAYED_LIST [CONSTRAINT]
			l_vlayout: LAYOUT
			l_vchunks: ARRAY [RECT]
			m, c: INTEGER
			l_flex: FLEX_JUSTIFY
			l_row_layout: LAYOUT
			l_row_chunks: ARRAY [RECT]
			l_label_area, l_track_area: RECT
			l_label_para: TUI_PARAGRAPH
			l_mode_layout: LAYOUT
			l_mode_chunks: ARRAY [RECT]
			l_box: TUI_BLOCK
			l_style: STYLE
			l_color: COLOR
		do
			create l_container.make
			l_container := l_container.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (create {STYLE}.make_fg ({COLOR}.Bright_cyan)).
				with_title (" Live Solver Simulation Across All Flex Modes ")
			a_frame.render_widget (l_container, a_area)
			l_inner := l_container.inner (a_area)

			l_constraints := build_constraints

			-- Split inner area into 7 rows for the 7 flex modes
			create l_vlayout.make_vertical (<<
				{CONSTRAINTS}.flex (1),
				{CONSTRAINTS}.flex (1),
				{CONSTRAINTS}.flex (1),
				{CONSTRAINTS}.flex (1),
				{CONSTRAINTS}.flex (1),
				{CONSTRAINTS}.flex (1),
				{CONSTRAINTS}.flex (1)
			>>)
			l_vchunks := l_vlayout.split (l_inner)

			from
				m := 1
			until
				m > flex_modes.count or m > l_vchunks.count
			loop
				l_flex := flex_modes [m]

				-- Split row into label (14) and track (Flex 1)
				create l_row_layout.make_horizontal (<<
					{CONSTRAINTS}.fixed (14),
					{CONSTRAINTS}.flex (1)
				>>)
				l_row_chunks := l_row_layout.split (l_vchunks [m])
				l_label_area := l_row_chunks [1]
				l_track_area := l_row_chunks [2]

				if m = selected_flex_index then
					l_style := (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold
				else
					l_style := create {STYLE}.make_fg ({COLOR}.Gray)
				end
				create l_label_para.make (create {TEXT}.make_styled (flex_names [m], l_style))
				a_frame.render_widget (l_label_para, l_label_area)

				-- Split track using this flex mode
				create l_mode_layout.make_horizontal (l_constraints)
				l_mode_layout := l_mode_layout.with_spacing (spacing_value).with_flex (l_flex)
				l_mode_chunks := l_mode_layout.split (l_track_area)

				from
					c := 1
				until
					c > l_mode_chunks.count
				loop
					l_color := block_color (c)
					create l_box.make
					l_box := l_box.with_borders ({BORDERS}.all_borders).
						with_border_type ({BORDER_TYPE}.plain)

					if c = selected_index then
						-- Highlight selected block
						l_box := l_box.with_border_style ((create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold)
					else
						l_box := l_box.with_border_style (create {STYLE}.make_fg (l_color))
					end
					a_frame.render_widget (l_box, l_mode_chunks [c])
					c := c + 1
				end

				m := m + 1
			end
		end

	render_control_panel (a_frame: FRAME; a_area: RECT)
			-- Render interactive constraint cards and property editor.
		local
			l_panel_block: TUI_BLOCK
			l_inner: RECT
			l_card_layout: LAYOUT
			l_card_chunks: ARRAY [RECT]
			l_constraints_list: ARRAYED_LIST [CONSTRAINT]
			i: INTEGER
			l_card_box: TUI_BLOCK
			l_card_para: TUI_PARAGRAPH
			l_text: STRING_32
			l_style: STYLE
		do
			create l_panel_block.make
			l_panel_block := l_panel_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).
				with_title (" Constraint List & Property Inspector (Use [h/l] to Select, [+/-] to Adjust) ")
			a_frame.render_widget (l_panel_block, a_area)
			l_inner := l_panel_block.inner (a_area)

			create l_constraints_list.make (constraint_models.count)
			from i := 1 until i > constraint_models.count loop
				l_constraints_list.extend ({CONSTRAINTS}.flex (1))
				i := i + 1
			end

			create l_card_layout.make_horizontal (l_constraints_list)
			l_card_layout := l_card_layout.with_spacing (1)
			l_card_chunks := l_card_layout.split (l_inner)

			from
				i := 1
			until
				i > constraint_models.count or i > l_card_chunks.count
			loop
				create l_card_box.make
				l_card_box := l_card_box.with_borders ({BORDERS}.all_borders).
					with_border_type ({BORDER_TYPE}.rounded)

				if i = selected_index then
					l_card_box := l_card_box.with_border_style ((create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold)
					l_style := (create {STYLE}.make_with_colors ({COLOR}.Black, {COLOR}.Bright_yellow)).with_bold
				else
					l_card_box := l_card_box.with_border_style (create {STYLE}.make_fg ({COLOR}.Dark_gray))
					l_style := create {STYLE}.make_fg ({COLOR}.White)
				end
				a_frame.render_widget (l_card_box, l_card_chunks [i])

				create l_text.make (32)
				l_text.append_string_general ("#")
				l_text.append_integer (i)
				l_text.append_character ('%N')
				l_text.append_string (model_label (constraint_models [i]))
				l_text.append_character ('%N')
				l_text.append_string_general ("Val: ")
				l_text.append_integer (constraint_models [i].val1)

				create l_card_para.make (create {TEXT}.make_styled (l_text, l_style))
				l_card_para := l_card_para.with_alignment ({TEXT_ALIGNMENT}.center)
				a_frame.render_widget (l_card_para, l_card_box.inner (l_card_chunks [i]))

				i := i + 1
			end
		end

	render_footer (a_frame: FRAME; a_area: RECT)
			-- Render shortcut guide.
		local
			l_para: TUI_PARAGRAPH
			l_text: TEXT
			l_line: TEXT_LINE
		do
			create l_text.make_empty
			create l_line.make_empty
			l_line.append_span (create {TEXT_SPAN}.make ("[h/l/Left/Right] ", (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold))
			l_line.append_span (create {TEXT_SPAN}.make ("Select  ", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_line.append_span (create {TEXT_SPAN}.make ("[+/-] ", (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold))
			l_line.append_span (create {TEXT_SPAN}.make ("Value  ", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_line.append_span (create {TEXT_SPAN}.make ("[t] ", (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold))
			l_line.append_span (create {TEXT_SPAN}.make ("Type  ", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_line.append_span (create {TEXT_SPAN}.make ("[a] ", (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold))
			l_line.append_span (create {TEXT_SPAN}.make ("Add  ", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_line.append_span (create {TEXT_SPAN}.make ("[d] ", (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold))
			l_line.append_span (create {TEXT_SPAN}.make ("Delete  ", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_line.append_span (create {TEXT_SPAN}.make ("[f] ", (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold))
			l_line.append_span (create {TEXT_SPAN}.make ("Flex  ", create {STYLE}.make_fg ({COLOR}.Gray)))
			l_line.append_span (create {TEXT_SPAN}.make ("[s] ", (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold))
			l_line.append_span (create {TEXT_SPAN}.make ("Spacing  ", create {STYLE}.make_fg ({COLOR}.Gray)))
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

feature {NONE} -- Event Handling

	process (a_event: EVENT)
			-- Handle interactive manipulation commands.
		local
			ch: CHARACTER_32
			m: TUPLE [type_id: INTEGER; val1: INTEGER; val2: INTEGER]
		do
			if attached {KEY_EVENT} a_event as k and then k.is_press then
				if k.code.is_escape then
					stop
				elseif k.code.is_char then
					ch := k.code.character
					if ch = 'q' or ch = 'Q' then
						stop
					elseif ch = 'h' or ch = 'H' then
						selected_index := selected_index - 1
						if selected_index < 1 then
							selected_index := constraint_models.count
						end
					elseif ch = 'l' or ch = 'L' then
						selected_index := (selected_index \\ constraint_models.count) + 1
					elseif ch = '+' or ch = '=' then
						m := constraint_models [selected_index]
						m.val1 := m.val1 + 1
					elseif ch = '-' or ch = '_' then
						m := constraint_models [selected_index]
						if m.val1 > 1 then
							m.val1 := m.val1 - 1
						end
					elseif ch = 't' or ch = 'T' then
						-- Cycle constraint type
						m := constraint_models [selected_index]
						m.type_id := (m.type_id \\ 6) + 1
					elseif ch = 'a' or ch = 'A' then
						-- Add constraint
						if constraint_models.count < 8 then
							constraint_models.extend ([1, 15, 0])
							selected_index := constraint_models.count
						end
					elseif ch = 'd' or ch = 'D' or ch = 'x' or ch = 'X' then
						-- Delete constraint
						if constraint_models.count > 1 then
							constraint_models.go_i_th (selected_index)
							constraint_models.remove
							if selected_index > constraint_models.count then
								selected_index := constraint_models.count
							end
						end
					elseif ch = 'f' or ch = 'F' then
						selected_flex_index := (selected_flex_index \\ flex_modes.count) + 1
					elseif ch = 's' or ch = 'S' then
						spacing_value := (spacing_value + 1) \\ 6
					end
				elseif k.code.is_left then
					selected_index := selected_index - 1
					if selected_index < 1 then
						selected_index := constraint_models.count
					end
				elseif k.code.is_right then
					selected_index := (selected_index \\ constraint_models.count) + 1
				elseif k.code.is_up then
					m := constraint_models [selected_index]
					m.val1 := m.val1 + 1
				elseif k.code.is_down then
					m := constraint_models [selected_index]
					if m.val1 > 1 then
						m.val1 := m.val1 - 1
					end
				end
			end
		end

end
