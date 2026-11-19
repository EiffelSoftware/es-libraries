note
	description: "[
		Tier 2 Widget Specialist Example: Form Controls (P2 W1, W2, W3).
		Demonstrates TUI_DIVIDER section rules, TUI_CHECKBOX boxes, a radio group made of
		checkboxes sharing one selected index (the recipe in TUI_CHECKBOX's note), and
		TUI_SLIDER + SLIDER_STATE in both directions, on one FOCUS_MANAGER ring:

		  * Tab / Shift+Tab move the focus; a click focuses the control under the pointer.
		  * Space or a click toggles the focused checkbox, or selects the focused radio option.
		  * On a focused slider: Right / Up and Left / Down step, Page Up / Page Down move ten
		    steps, Home / End jump to the ends; a click on the track jumps there and a drag
		    follows the pointer (past the ends too) until the button is released.
		  * Esc or q quits.

		The three checkboxes act on a sample document in the Preview section (`preview_text`):
		"Wrap lines" word-wraps its long line (otherwise it is cut at the edge), "Show line
		numbers" adds a numbered gutter (blank on the rows a line wraps onto), and "Bold
		headings" makes its headings bold.

		The theme radio group switches the dialog between the TUI_THEME `dark` and `light`
		presets (`palette`): the dialog's background and text (`base`), its border and title
		(`primary`), the section rules (`border`), the focused control (`highlight`), the
		sliders (`success`, `info`, `primary`) and the status line (`success`) all come from
		the selected theme.

		Each control registers its own cells (`hit_area`) in the frame's hit map, so a click
		beside a checkbox's label or below a slider's track misses. The application owns
		every value; the widgets are built from them each frame.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	EXAMPLE_FORM_CONTROLS

inherit
	TUI_APPLICATION
		redefine
			make
		end

create
	make,
	make_batch,
	make_on

feature {NONE} -- Initialization

	make
			-- Initialize and launch the form controls example.
		local
			l_args: ARGUMENTS_32
			i: INTEGER
		do
			init_controls
			Precursor
			set_mouse_capture (True)
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
			init_controls
			make_with_viewport (create {VIEWPORT}.make_fullscreen)
			set_mouse_capture (True)
			auto_exit_frames := a_frames
			frame_counter := 0
			run
		end

	make_on (a_terminal: TERMINAL [ANSI_TERMINAL_BACKEND])
			-- Initialize on `a_terminal` without running (for snapshot tests).
		require
			terminal_attached: a_terminal /= Void
		do
			init_controls
			make_with_terminal (a_terminal)
			set_mouse_capture (True)
			auto_exit_frames := -1
			frame_counter := 0
		ensure
			not_running: not is_running
		end

feature {NONE} -- Setup

	init_controls
			-- Initialize the values and the focus ring (in Tab order).
		do
			options := <<True, False, True>>
			theme := 1
			create volume.make (0, 100, 5)
			volume.set_value (50)
			create gain.make (-12, 12, 1)
			gain.set_value (0)
			create focus_manager.make
			create option_ids.make_filled (create {WIDGET_ID}.make (1), 1, 3)
			option_ids [1] := create {WIDGET_ID}.make (1)
			option_ids [2] := create {WIDGET_ID}.make (2)
			option_ids [3] := create {WIDGET_ID}.make (3)
			create theme_ids.make_filled (create {WIDGET_ID}.make (4), 1, 2)
			theme_ids [1] := create {WIDGET_ID}.make (4)
			theme_ids [2] := create {WIDGET_ID}.make (5)
			create id_volume.make (6)
			create id_gain.make (7)
			across option_ids as l_id loop
				focus_manager.register (l_id)
			end
			across theme_ids as l_id loop
				focus_manager.register (l_id)
			end
			focus_manager.register (id_volume)
			focus_manager.register (id_gain)
			create volume_area.make (0, 0, 0, 0)
			create gain_area.make (0, 0, 0, 0)
		end

feature -- Access

	options: ARRAY [BOOLEAN]
			-- Values of the three checkboxes: wrap lines, line numbers, bold headings

	theme: INTEGER
			-- Selected radio option: 1 dark, 2 light

	palette: TUI_THEME
			-- Styles of the selected `theme`: {TUI_THEME}.dark or .light (a new theme per call)
		do
			if theme = 2 then
				Result := {TUI_THEME}.light
			else
				Result := {TUI_THEME}.dark
			end
		ensure
			result_not_void: Result /= Void
		end

	volume: SLIDER_STATE
			-- Horizontal slider: 0 .. 100 by 5

	gain: SLIDER_STATE
			-- Vertical slider: -12 .. 12 dB by 1

	Option_labels: ARRAY [STRING_32]
			-- Labels of the checkboxes
		once
			Result := <<{STRING_32} "Wrap lines", {STRING_32} "Show line numbers", {STRING_32} "Bold headings">>
		end

	Sample_lines: ARRAY [STRING_32]
			-- The preview's document; lines starting with "#" are headings
		once
			Result := <<{STRING_32} "# Release notes",
				{STRING_32} "Sliders, checkboxes and dividers join the widget set, each with its own hit region.",
				{STRING_32} "## Fixes",
				{STRING_32} "Labels are never cut.">>
		end

	Theme_labels: ARRAY [STRING_32]
			-- Labels of the radio options
		once
			Result := <<{STRING_32} "Dark", {STRING_32} "Light">>
		end

	Dialog_width: INTEGER = 64
			-- Columns of the dialog (it is cut to a smaller frame)

	Dialog_height: INTEGER = 20
			-- Rows of the dialog

feature {NONE} -- State

	focus_manager: FOCUS_MANAGER
			-- Tab order of the seven controls

	option_ids: ARRAY [WIDGET_ID]
			-- Ids of the checkboxes

	theme_ids: ARRAY [WIDGET_ID]
			-- Ids of the radio options

	id_volume, id_gain: WIDGET_ID
			-- Ids of the sliders

	volume_area, gain_area: RECT
			-- Areas the sliders were last rendered into (frame coordinates), for the mouse

	dragged: detachable WIDGET_ID
			-- Slider whose track was pressed and not released yet, or Void

	auto_exit_frames: INTEGER
			-- Auto-exit in batch mode

	frame_counter: INTEGER
			-- Rendered frame count

feature {NONE} -- Widgets

	volume_slider: TUI_SLIDER
			-- The horizontal slider, as drawn and as mapped for the mouse
		do
			Result := (create {TUI_SLIDER}.make)
				.with_label_position ({SLIDER_LABEL_POSITION}.right)
				.with_label_format (agent percent)
				.with_filled_style (palette.success)
				.with_thumb_style (palette.primary)
				.with_focused_style (palette.highlight)
				.with_focused (focus_manager.is_focused (id_volume))
				.with_hit_id (id_volume)
		end

	gain_slider: TUI_SLIDER
			-- The vertical slider, as drawn and as mapped for the mouse
		do
			Result := (create {TUI_SLIDER}.make_vertical)
				.with_label_position ({SLIDER_LABEL_POSITION}.left)
				.with_label_format (agent decibels)
				.with_filled_style (palette.info)
				.with_thumb_style (palette.primary)
				.with_focused_style (palette.highlight)
				.with_focused (focus_manager.is_focused (id_gain))
				.with_hit_id (id_gain)
		end

	percent (a_value: INTEGER_64): READABLE_STRING_GENERAL
			-- "50%"
		do
			Result := a_value.out + "%%"
		end

	decibels (a_value: INTEGER_64): READABLE_STRING_GENERAL
			-- "+3 dB", "0 dB", "-12 dB"
		do
			if a_value > 0 then
				Result := "+" + a_value.out + " dB"
			else
				Result := a_value.out + " dB"
			end
		end

	divider (a_label: READABLE_STRING_GENERAL): TUI_DIVIDER
			-- A section rule with `a_label`
		do
			Result := (create {TUI_DIVIDER}.make)
				.with_label (a_label)
				.with_style (palette.border)
		end

feature {NONE} -- Application Hooks

	render (a_frame: FRAME)
			-- Draw the dialog in the selected theme: help, the checkboxes, the radio group, both
			-- sliders and a status line, each control from the application's values.
		local
			l_dialog, l_inner, l_left, l_right: RECT
			l_w, l_h: INTEGER
			i: INTEGER
			l_box: TUI_CHECKBOX
			l_palette: TUI_THEME
		do
			l_palette := palette
			if auto_exit_frames > 0 then
				frame_counter := frame_counter + 1
				if frame_counter >= auto_exit_frames then
					stop
				end
			end

			l_w := Dialog_width.min (a_frame.area.width.to_integer_32)
			l_h := Dialog_height.min (a_frame.area.height.to_integer_32)
			create l_dialog.make (((a_frame.area.width.to_integer_32 - l_w) // 2).to_natural_16,
				((a_frame.area.height.to_integer_32 - l_h) // 2).to_natural_16, l_w.to_natural_16, l_h.to_natural_16)
			a_frame.render_widget ((create {TUI_BLOCK}.make).with_borders ({BORDERS}.all_borders)
				.with_border_type ({BORDER_TYPE}.rounded)
				.with_style (l_palette.base)
				.with_border_style (l_palette.primary)
				.with_title (" Form Controls ")
				.with_title_alignment ({TEXT_ALIGNMENT}.center), l_dialog)
			l_inner := l_dialog.inner (1, 1)
			if not l_inner.is_empty then
				a_frame.render_widget ((create {TUI_PARAGRAPH}.make (create {TEXT}.make_styled (
					"Tab: focus  Space/click: toggle  Arrows/drag: slide  Esc: quit",
					l_palette.text))).with_style (l_palette.base), part (l_inner, 0, 0, l_inner.width.to_integer_32, 1))
				l_left := part (l_inner, 0, 1, 44, 10)
				l_right := part (l_inner, 46, 1, 16, 10)

					-- Checkboxes
				a_frame.render_widget (divider ("Options"), part (l_left, 0, 0, l_left.width.to_integer_32, 1))
				from i := 1 until i > 3 loop
					create l_box.make (Option_labels [i])
					a_frame.render_widget (l_box.with_checked (options [i])
							.with_focused (focus_manager.is_focused (option_ids [i]))
							.with_focused_style (l_palette.highlight)
							.with_hit_id (option_ids [i]),
						part (l_left, 1, i, l_left.width.to_integer_32 - 1, 1))
					i := i + 1
				end

					-- Radio group: checkboxes sharing one selected index
				a_frame.render_widget (divider ("Theme"), part (l_left, 0, 4, l_left.width.to_integer_32, 1))
				from i := 1 until i > 2 loop
					create l_box.make (Theme_labels [i])
					a_frame.render_widget (l_box.with_symbols ({CHECKBOX_SYMBOLS}.radio_selected, {CHECKBOX_SYMBOLS}.radio_unselected)
							.with_checked (theme = i)
							.with_focused (focus_manager.is_focused (theme_ids [i]))
							.with_focused_style (l_palette.highlight)
							.with_hit_id (theme_ids [i]),
						part (l_left, 1, 4 + i, l_left.width.to_integer_32 - 1, 1))
					i := i + 1
				end

					-- Horizontal slider
				a_frame.render_widget (divider ("Volume"), part (l_left, 0, 7, l_left.width.to_integer_32, 1))
				volume_area := part (l_left, 1, 8, l_left.width.to_integer_32 - 1, 1)
				a_frame.render_stateful_widget (volume_slider, volume_area, volume)

					-- Vertical slider
				a_frame.render_widget (divider ("Gain"), part (l_right, 0, 0, l_right.width.to_integer_32, 1))
				gain_area := part (l_right, 1, 1, l_right.width.to_integer_32 - 1, 9)
				a_frame.render_stateful_widget (gain_slider, gain_area, gain)

					-- Preview: the sample document as the checkboxes ask
				a_frame.render_widget (divider ("Preview"), part (l_inner, 0, 11, l_inner.width.to_integer_32, 1))
				a_frame.render_widget ((create {TUI_PARAGRAPH}.make (preview_text (l_inner.width.to_integer_32 - 1, l_palette)))
					.with_style (l_palette.base), part (l_inner, 1, 12, l_inner.width.to_integer_32 - 1, 5))

					-- Status
				a_frame.render_widget ((create {TUI_PARAGRAPH}.make (create {TEXT}.make_styled (status_text,
					l_palette.success))).with_style (l_palette.base), part (l_inner, 0, 17, l_inner.width.to_integer_32, 1))
			end
		end

	process (a_event: EVENT)
			-- Move the focus, toggle and select with Space or a click, and move the focused
			-- slider with keys, a click on its track or a drag.
		do
			if attached {MOUSE_EVENT} a_event as m then
				process_mouse (m)
			elseif attached {KEY_EVENT} a_event as k and then k.is_press then
				if k.code.is_escape or else (k.code.is_char and then k.code.character = 'q') then
					stop
				elseif k.code.is_tab then
					focus_manager.focus_next
				elseif k.code.is_back_tab then
					focus_manager.focus_previous
				elseif k.code.is_char and then k.code.character = ' ' then
					activate_focused
				elseif attached focused_slider as l_state then
					if k.code.is_right or k.code.is_up then
						l_state.increase
					elseif k.code.is_left or k.code.is_down then
						l_state.decrease
					elseif k.code.is_page_up then
						l_state.increase_page
					elseif k.code.is_page_down then
						l_state.decrease_page
					elseif k.code.is_home then
						l_state.set_to_minimum
					elseif k.code.is_end then
						l_state.set_to_maximum
					end
				end
			end
		end

feature {NONE} -- Input

	process_mouse (m: MOUSE_EVENT)
			-- A press focuses the control under it and toggles, selects, or jumps a slider when
			-- on its track (and starts a drag); a drag moves the pressed slider; a release ends it.
		local
			col, row: INTEGER
		do
			if attached terminal.shown_area as l_shown then
				col := m.column.to_integer_32 - l_shown.x.to_integer_32
				row := m.row.to_integer_32 - l_shown.y.to_integer_32
			end
			if m.is_down then
				dragged := Void
				if focus_manager.focus_at (hit_test (m)) then
					if focus_manager.is_focused (id_volume) then
						if volume_slider.is_on_track (volume_area, volume, col, row) then
							dragged := id_volume
							slide (volume_slider, volume_area, volume, col, row)
						end
					elseif focus_manager.is_focused (id_gain) then
						if gain_slider.is_on_track (gain_area, gain, col, row) then
							dragged := id_gain
							slide (gain_slider, gain_area, gain, col, row)
						end
					else
						activate_focused
					end
				end
			elseif m.is_drag and then attached dragged as l_id then
				if l_id ~ id_volume then
					slide (volume_slider, volume_area, volume, col, row)
				else
					slide (gain_slider, gain_area, gain, col, row)
				end
			elseif m.is_up then
				dragged := Void
			end
		end

	slide (a_slider: TUI_SLIDER; a_area: RECT; a_state: SLIDER_STATE; a_column, a_row: INTEGER)
			-- Move `a_state` to the track cell at frame point (`a_column`, `a_row`).
		local
			l_length: INTEGER
		do
			l_length := a_slider.track_length (a_area, a_state)
			if l_length > 0 then
				a_state.set_from_position (a_slider.track_cell (a_area, a_state, a_column, a_row), l_length)
			end
		end

	activate_focused
			-- Toggle the focused checkbox, or select the focused radio option.
		local
			i: INTEGER
		do
			from i := 1 until i > 3 loop
				if focus_manager.is_focused (option_ids [i]) then
					options [i] := not options [i]
				end
				i := i + 1
			end
			from i := 1 until i > 2 loop
				if focus_manager.is_focused (theme_ids [i]) then
					theme := i
				end
				i := i + 1
			end
		end

	focused_slider: detachable SLIDER_STATE
			-- State of the focused slider, or Void
		do
			if focus_manager.is_focused (id_volume) then
				Result := volume
			elseif focus_manager.is_focused (id_gain) then
				Result := gain
			end
		end

feature -- Preview

	preview_text (a_width: INTEGER; a_palette: TUI_THEME): TEXT
			-- `Sample_lines` for a preview `a_width` columns wide, as the checkboxes ask: wrapped
			-- by word (`options` [1]) or left to be cut, behind a "nn | " gutter (`options` [2]),
			-- headings in `a_palette`'s primary colour, bold when `options` [3]
		require
			positive_width: a_width > 0
		local
			l_rows: ARRAYED_LIST [TEXT_LINE]
			l_spans: ARRAYED_LIST [TEXT_SPAN]
			l_style: STYLE
			l_gutter: STRING_32
			l_text_width, i: INTEGER
			l_first: BOOLEAN
		do
			create Result.make_empty
			l_text_width := a_width
			if options [2] then
				l_text_width := (a_width - Gutter_width).max (1)
			end
			from i := 1 until i > Sample_lines.count loop
				if Sample_lines [i].starts_with ({STRING_32} "#") then
					l_style := a_palette.primary
					if options [3] then
						l_style := l_style.with_bold
					end
				else
					l_style := a_palette.text
				end
				if options [1] then
					l_rows := {TEXT_LAYOUT}.wrap_text (create {TEXT}.make (<<create {TEXT_LINE}.make_styled (Sample_lines [i], l_style)>>),
						l_text_width.to_natural_16, {TEXT_WRAP_MODE}.word, True)
				else
					create l_rows.make (1)
					l_rows.extend (create {TEXT_LINE}.make_styled (Sample_lines [i], l_style))
				end
				l_first := True
				across l_rows as l_row loop
					create l_spans.make (l_row.spans.count + 1)
					if options [2] then
						create l_gutter.make (Gutter_width)
						if l_first then
							l_gutter.append_string_general (i.out)
						end
						from until l_gutter.count >= Gutter_width - 3 loop
							l_gutter.prepend_character (' ')
						end
						l_gutter.append_string_general ({STRING_32} " %/0x2502/ ")
						l_spans.extend (create {TEXT_SPAN}.make (l_gutter, a_palette.muted))
					end
					across l_row.spans as l_span loop
						l_spans.extend (l_span)
					end
					Result.append_line (create {TEXT_LINE}.make (l_spans))
					l_first := False
				end
				i := i + 1
			end
		ensure
			result_not_void: Result /= Void
		end

	Gutter_width: INTEGER = 5
			-- Columns of the line-number gutter: two digits, " | "

feature {NONE} -- Implementation

	status_text: STRING_32
			-- One line summing up the values
		do
			create Result.make (64)
			Result.append_string_general ("wrap ")
			Result.append_string_general (on_off (options [1]))
			Result.append_string_general (", numbers ")
			Result.append_string_general (on_off (options [2]))
			Result.append_string_general (", bold ")
			Result.append_string_general (on_off (options [3]))
			Result.append_string_general (", ")
			Result.append (Theme_labels [theme].as_lower)
			Result.append_string_general (", volume ")
			Result.append_string_general (percent (volume.value))
			Result.append_string_general (", gain ")
			Result.append_string_general (decibels (gain.value))
		end

	on_off (a_value: BOOLEAN): STRING
			-- "on" or "off"
		do
			if a_value then
				Result := "on"
			else
				Result := "off"
			end
		end

	part (a_parent: RECT; a_dx, a_dy, a_width, a_height: INTEGER): RECT
			-- The rectangle `a_width` x `a_height` at (`a_dx`, `a_dy`) inside `a_parent`, cut to it
		do
			if a_dx >= a_parent.width.to_integer_32 or a_dy >= a_parent.height.to_integer_32
				or a_width <= 0 or a_height <= 0
			then
				create Result.make (a_parent.x, a_parent.y, 0, 0)
			else
				create Result.make (a_parent.x + a_dx.to_natural_16, a_parent.y + a_dy.to_natural_16,
					a_width.min (a_parent.width.to_integer_32 - a_dx).to_natural_16,
					a_height.min (a_parent.height.to_integer_32 - a_dy).to_natural_16)
			end
		ensure
			inside: Result.is_empty or else a_parent.contains_rect (Result)
		end

invariant
	three_options: options.count = 3
	valid_theme: theme = 1 or theme = 2

end
