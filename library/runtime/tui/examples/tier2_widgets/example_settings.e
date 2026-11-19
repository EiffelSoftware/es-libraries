note
	description: "[
		Tier 2 Widget Specialist Example: Settings (P2 step 7; W1–W5 and C3 together).
		A settings screen in a theme: a menu bar (TUI_MENU), three checkboxes (TUI_CHECKBOX),
		two sliders (TUI_SLIDER), section rules (TUI_DIVIDER), a toast on save (TUI_TOAST)
		and theme switching, every widget styled from the current TUI_THEME.

		  * t, or Theme > Next theme, cycles the themes: the four presets (dark, light, nord,
		    dracula) and, first, the theme file given as an argument. Theme > Dark ... picks
		    a preset.
		  * s, or File > Save theme, writes the current theme with TUI_THEME_FILE.save to
		    `save_path` (settings_theme.toml in the current directory) and shows a success
		    toast, or an error toast when it cannot be written.
		  * Tab / Shift+Tab move the focus; Space or a click toggles a checkbox; on a focused
		    slider the arrows, Home and End move it, and a click on its track jumps there.
		  * F10 or Alt+F / Alt+T / Alt+H open the menu (arrows, Enter, Esc, clicks as in
		    EXAMPLE_MENU_BAR); a click on a toast dismisses it; q or Esc quits.

		Arguments: a theme file path (loaded with TUI_THEME_FILE.load; an error is shown in
		an error toast, and the presets are used), `-batch` (two frames), or
		`-write-presets DIR`, which writes the four presets to DIR/dark.toml ... with
		TUI_THEME_FILE.save and quits: that is how examples/themes/ is made. Any other
		argument starting with "-", or `-write-presets` without a directory, prints `Usage`
		and exits with status 2, before `run` (so the terminal stays as it was).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	EXAMPLE_SETTINGS

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
			-- Initialize and launch the settings example, with the arguments described above.
			-- A bad argument prints the usage to the error output and exits with status 2, and
			-- a preset that cannot be written exits with status 1. Both exit before `run`, so
			-- the terminal is never put in raw mode or on the alternate screen (`Precursor`
			-- only makes the terminal objects and enables VT output).
		local
			l_args: ARGUMENTS_32
			i: INTEGER
			l_presets_dir, l_bad: detachable STRING_32
			l_paths: ARRAYED_LIST [STRING_32]
			l_batch: BOOLEAN
		do
			init_settings
			Precursor
			create l_args
			create l_paths.make (2)
			from i := 1 until i > l_args.argument_count or l_bad /= Void loop
				if l_args.argument (i).same_string ("-batch") then
					l_batch := True
				elseif l_args.argument (i).same_string ("-write-presets") then
					if i < l_args.argument_count and then not l_args.argument (i + 1).is_empty then
						i := i + 1
						l_presets_dir := l_args.argument (i)
					else
						l_bad := {STRING_32} "-write-presets needs a directory"
					end
				elseif l_args.argument (i).starts_with ("-") then
					l_bad := {STRING_32} "unknown option '" + l_args.argument (i) + "'"
				elseif not l_args.argument (i).is_empty then
					l_paths.extend (l_args.argument (i))
				end
				i := i + 1
			end
			if attached l_bad as l_message then
				io.error.put_string_32 ({STRING_32} "example_settings: " + l_message + "%N" + Usage + "%N")
				(create {EXCEPTIONS}).die (2)
			elseif attached l_presets_dir as l_dir then
				if not write_presets (l_dir) then
					(create {EXCEPTIONS}).die (1)
				end
			else
				set_mouse_capture (True)
				across l_paths as l_path loop
					add_theme_file (l_path)
				end
				if l_batch then
					auto_exit_frames := 2
				else
					auto_exit_frames := -1
				end
				frame_counter := 0
				run
			end
		end

	Usage: STRING_32 = "[
		Usage: example_settings [-batch] [THEME_FILE ...]
		       example_settings -write-presets DIR
		  THEME_FILE          a theme file to load first (a path starting with "-" as ./-name)
		  -batch              run two frames and exit
		  -write-presets DIR  write dark.toml, light.toml, nord.toml and dracula.toml to DIR
	]"
			-- What `make` prints for a bad argument

	make_batch (a_frames: INTEGER)
			-- Initialize and run for `a_frames` frames.
		do
			init_settings
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
			init_settings
			make_with_terminal (a_terminal)
			set_mouse_capture (True)
			auto_exit_frames := -1
			frame_counter := 0
		ensure
			not_running: not is_running
		end

feature {NONE} -- Setup

	init_settings
			-- The values, the themes, the focus ring, the menu and the toasts.
		do
			options := <<True, False, True>>
			create volume.make (0, 100, 10)
			volume.set_value (60)
			create speed.make (1, 10, 1)
			speed.set_value (3)
			create themes.make (5)
			create theme_names.make (5)
			across Preset_names as l_name loop
				themes.extend (preset (l_name))
				theme_names.extend (l_name)
			end
			theme_index := 1
			create focus_manager.make
			create option_ids.make_filled (create {WIDGET_ID}.make (1), 1, 3)
			option_ids [2] := create {WIDGET_ID}.make (2)
			option_ids [3] := create {WIDGET_ID}.make (3)
			create id_volume.make (4)
			create id_speed.make (5)
			across option_ids as l_id loop
				focus_manager.register (l_id)
			end
			focus_manager.register (id_volume)
			focus_manager.register (id_speed)
			create volume_area.make (0, 0, 0, 0)
			create speed_area.make (0, 0, 0, 0)
			create toasts.make_at (clock_ms)
			create menu.make (<<
				(create {MENU_ITEM}.make_submenu ("File", <<
					(create {MENU_ITEM}.make ("Save theme")).with_shortcut ("s").with_id (create {WIDGET_ID}.make (Cmd_save)),
					create {MENU_ITEM}.make_separator,
					(create {MENU_ITEM}.make ("Quit")).with_shortcut ("q").with_id (create {WIDGET_ID}.make (Cmd_quit))>>))
					.with_id (create {WIDGET_ID}.make (Entry_file)),
				(create {MENU_ITEM}.make_submenu ("Theme", <<
					(create {MENU_ITEM}.make ("Next theme")).with_shortcut ("t").with_id (create {WIDGET_ID}.make (Cmd_next_theme)),
					create {MENU_ITEM}.make_separator,
					(create {MENU_ITEM}.make ("Dark")).with_id (create {WIDGET_ID}.make (Cmd_dark)),
					(create {MENU_ITEM}.make ("Light")).with_id (create {WIDGET_ID}.make (Cmd_light)),
					(create {MENU_ITEM}.make ("Nord")).with_id (create {WIDGET_ID}.make (Cmd_nord)),
					(create {MENU_ITEM}.make ("Dracula")).with_id (create {WIDGET_ID}.make (Cmd_dracula))>>))
					.with_id (create {WIDGET_ID}.make (Entry_theme)),
				(create {MENU_ITEM}.make_submenu ("Help", <<
					(create {MENU_ITEM}.make ("About")).with_id (create {WIDGET_ID}.make (Cmd_about))>>))
					.with_id (create {WIDGET_ID}.make (Entry_help))>>)
			menu.set_menu_id (create {WIDGET_ID}.make (Menu_surface))
			menu.set_focus_manager (focus_manager)
		end

	add_theme_file (a_path: READABLE_STRING_GENERAL)
			-- Load the theme file at `a_path` and make it the first and current theme, or push
			-- an error toast and keep the presets.
		require
			path_not_empty: not a_path.is_empty
		local
			l_file: TUI_THEME_FILE
		do
			create l_file.make
			if attached l_file.loaded (a_path) as l_theme then
				themes.put_front (l_theme)
				theme_names.put_front (file_name (a_path))
				theme_index := 1
			else
				toasts.push ({STRING_32} "Theme file not loaded: " + l_file.error_description, {TOAST_LEVEL}.error, 8000)
			end
		ensure
			loaded_or_toast: themes.count = old themes.count + 1 or toasts.count = old toasts.count + 1
		end

	write_presets (a_directory: READABLE_STRING_GENERAL): BOOLEAN
			-- Write the four presets to `a_directory`/<name>.toml with TUI_THEME_FILE.save;
			-- were all four written? An error goes to the error output.
		local
			l_file: TUI_THEME_FILE
			l_path: PATH
		do
			Result := True
			create l_file.make
			across Preset_names as l_name loop
				l_path := (create {PATH}.make_from_string (a_directory)).extended (l_name + ".toml")
				l_file.save (preset (l_name), l_path.name)
				if l_file.has_error then
					io.error.put_string_32 ({STRING_32} "Error: " + l_file.error_description + "%N")
					Result := False
				else
					io.put_string_32 ({STRING_32} "Wrote " + l_path.name + "%N")
				end
			end
		end

feature -- Access

	options: ARRAY [BOOLEAN]
			-- Values of the checkboxes: line numbers, wrap lines, autosave

	volume: SLIDER_STATE
			-- Volume, 0 .. 100 by 10

	speed: SLIDER_STATE
			-- Scroll speed, 1 .. 10

	themes: ARRAYED_LIST [TUI_THEME]
			-- The themes `t` cycles: a loaded file first, if any, then the presets

	theme_names: ARRAYED_LIST [STRING_32]
			-- The name of each of `themes`

	theme_index: INTEGER
			-- Index of the current theme in `themes`

	theme: TUI_THEME
			-- The current theme
		do
			Result := themes [theme_index]
		end

	theme_name: STRING_32
			-- The name of the current theme
		do
			Result := theme_names [theme_index]
		end

	menu: MENU_STATE
			-- The menu bar's items and open path

	toasts: TOAST_QUEUE
			-- The toasts shown over the screen

	save_path: STRING_32
			-- Where `s` saves the current theme (a test redefines it)
		do
			Result := {STRING_32} "settings_theme.toml"
		end

	clock_ms: INTEGER_64
			-- The application's clock (a test redefines it)
		do
			Result := {MONOTONIC_CLOCK}.milliseconds
		end

	Preset_names: ARRAY [STRING_32]
			-- The presets, in the order `t` cycles them
		once
			Result := <<{STRING_32} "dark", {STRING_32} "light", {STRING_32} "nord", {STRING_32} "dracula">>
		end

	Option_labels: ARRAY [STRING_32]
			-- Labels of the checkboxes
		once
			Result := <<{STRING_32} "Show line numbers", {STRING_32} "Wrap lines", {STRING_32} "Autosave">>
		end

feature -- Ids

	Entry_file: INTEGER = 11
	Entry_theme: INTEGER = 12
	Entry_help: INTEGER = 13
			-- Ids of the bar entries (the controls have 1 .. 5)

	Cmd_save: INTEGER = 21
	Cmd_quit: INTEGER = 22
	Cmd_next_theme: INTEGER = 23
	Cmd_about: INTEGER = 24
	Cmd_dark: INTEGER = 31
	Cmd_light: INTEGER = 32
	Cmd_nord: INTEGER = 33
	Cmd_dracula: INTEGER = 34
			-- Ids of the commands (`Cmd_dark` .. `Cmd_dracula` pick the presets in order)

	Menu_surface: INTEGER = 100
			-- Id of the menu's own surface

	Toast_id_base: INTEGER = 200
			-- A toast's box is registered under `Toast_id_base` + its id

feature {NONE} -- State

	focus_manager: FOCUS_MANAGER
			-- Tab order of the five controls (the menu pushes a scope on it while open)

	option_ids: ARRAY [WIDGET_ID]
			-- Ids of the checkboxes

	id_volume, id_speed: WIDGET_ID
			-- Ids of the sliders

	volume_area, speed_area: RECT
			-- Areas the sliders were last rendered into, for the mouse

	auto_exit_frames: INTEGER
			-- Auto-exit in batch mode

	frame_counter: INTEGER
			-- Rendered frame count

feature {NONE} -- Widgets

	volume_slider: TUI_SLIDER
			-- The volume slider in the current theme
		do
			Result := slider (id_volume, agent percent)
		end

	speed_slider: TUI_SLIDER
			-- The scroll speed slider in the current theme
		do
			Result := slider (id_speed, agent lines)
		end

	slider (a_id: WIDGET_ID; a_format: FUNCTION [INTEGER_64, READABLE_STRING_GENERAL]): TUI_SLIDER
			-- A horizontal slider for `a_id`, its label `a_format` on the right
		do
			Result := (create {TUI_SLIDER}.make)
				.with_label_position ({SLIDER_LABEL_POSITION}.right)
				.with_label_format (a_format)
				.with_label_width (Label_width)
				.with_style (theme.muted)
				.with_filled_style (theme.success)
				.with_thumb_style (theme.primary)
				.with_focused_style (theme.highlight)
				.with_focused (focus_manager.is_focused (a_id))
				.with_hit_id (a_id)
		end

	percent (a_value: INTEGER_64): READABLE_STRING_GENERAL
			-- "60%"
		do
			Result := a_value.out + "%%"
		end

	lines (a_value: INTEGER_64): READABLE_STRING_GENERAL
			-- "3 lines"
		do
			Result := a_value.out + " lines"
		end

	Label_width: INTEGER = 8
			-- Columns of a slider's value label, so both tracks are as long

	divider (a_label: READABLE_STRING_GENERAL): TUI_DIVIDER
			-- A section rule with `a_label`, in the theme's border style
		do
			Result := (create {TUI_DIVIDER}.make).with_label (a_label).with_style (theme.border)
		end

feature {NONE} -- Application Hooks

	render (a_frame: FRAME)
			-- Draw the panel in the current theme, then the menu bar and the toasts over it.
		local
			l_theme: TUI_THEME
			l_panel, l_inner: RECT
			l_width, i: INTEGER
			l_spans: ARRAYED_LIST [TEXT_SPAN]
		do
			if auto_exit_frames > 0 then
				frame_counter := frame_counter + 1
				if frame_counter >= auto_exit_frames then
					stop
				end
			end
			l_theme := theme
			if a_frame.area.height > 1 then
				create l_panel.make (a_frame.area.x, a_frame.area.y + 1, a_frame.area.width, a_frame.area.height - 1)
				a_frame.render_widget ((create {TUI_BLOCK}.make).with_border_type ({BORDER_TYPE}.rounded)
					.with_style (l_theme.base).with_border_style (l_theme.border)
					.with_title_line (create {TEXT_LINE}.make_styled (" Settings ", l_theme.title)), l_panel)
				l_inner := l_panel.inner (1, 1)
				l_width := l_inner.width.to_integer_32

					-- Editor: the checkboxes
				a_frame.render_widget (divider ("Editor"), part (l_inner, 0, 0, l_width, 1))
				from i := 1 until i > 3 loop
					a_frame.render_widget ((create {TUI_CHECKBOX}.make (Option_labels [i]))
							.with_checked (options [i])
							.with_style (l_theme.text)
							.with_focused (focus_manager.is_focused (option_ids [i]))
							.with_focused_style (l_theme.highlight)
							.with_hit_id (option_ids [i]),
						part (l_inner, 1, i, l_width - 1, 1))
					i := i + 1
				end

					-- Sound and scrolling: the sliders
				a_frame.render_widget (divider ("Levels"), part (l_inner, 0, 4, l_width, 1))
				a_frame.render_widget ((create {TUI_PARAGRAPH}.make (create {TEXT}.make_styled ("Volume", l_theme.text))).with_style (l_theme.base),
					part (l_inner, 1, 5, 7, 1))
				volume_area := part (l_inner, 9, 5, l_width - 10, 1)
				a_frame.render_stateful_widget (volume_slider, volume_area, volume)
				a_frame.render_widget ((create {TUI_PARAGRAPH}.make (create {TEXT}.make_styled ("Scroll", l_theme.text))).with_style (l_theme.base),
					part (l_inner, 1, 6, 7, 1))
				speed_area := part (l_inner, 9, 6, l_width - 10, 1)
				a_frame.render_stateful_widget (speed_slider, speed_area, speed)

					-- Theme: its name and its message styles
				a_frame.render_widget (divider ("Theme"), part (l_inner, 0, 7, l_width, 1))
				create l_spans.make (4)
				l_spans.extend (create {TEXT_SPAN}.make ({STRING_32} "Theme: ", l_theme.text))
				l_spans.extend (create {TEXT_SPAN}.make (theme_name, l_theme.primary.with_bold))
				l_spans.extend (create {TEXT_SPAN}.make ({STRING_32} " (" + theme_index.out + "/" + themes.count.out + ")", l_theme.muted))
				a_frame.render_widget ((create {TUI_PARAGRAPH}.make (create {TEXT}.make (<<create {TEXT_LINE}.make (l_spans)>>))).with_style (l_theme.base),
					part (l_inner, 1, 8, l_width - 1, 1))
				create l_spans.make (8)
				l_spans.extend (create {TEXT_SPAN}.make ({STRING_32} "info", l_theme.info))
				l_spans.extend (create {TEXT_SPAN}.make ({STRING_32} "  ", l_theme.text))
				l_spans.extend (create {TEXT_SPAN}.make ({STRING_32} "success", l_theme.success))
				l_spans.extend (create {TEXT_SPAN}.make ({STRING_32} "  ", l_theme.text))
				l_spans.extend (create {TEXT_SPAN}.make ({STRING_32} "warning", l_theme.warning))
				l_spans.extend (create {TEXT_SPAN}.make ({STRING_32} "  ", l_theme.text))
				l_spans.extend (create {TEXT_SPAN}.make ({STRING_32} "error", l_theme.error))
				a_frame.render_widget ((create {TUI_PARAGRAPH}.make (create {TEXT}.make (<<create {TEXT_LINE}.make (l_spans)>>))).with_style (l_theme.base),
					part (l_inner, 1, 9, l_width - 1, 1))

					-- Help
				a_frame.render_widget ((create {TUI_PARAGRAPH}.make (create {TEXT}.make_styled (
						"t: theme  s: save  Tab/Space/arrows  F10: menu  q: quit", l_theme.muted))).with_style (l_theme.base),
					part (l_inner, 1, l_inner.height.to_integer_32 - 1, l_width - 1, 1))

					-- The toasts over the panel, above the help line, each clickable under its
					-- toast's id
				a_frame.render_stateful_widget ((create {TUI_TOAST}).with_theme (l_theme)
					.with_position ({TOAST_POSITION}.bottom_right).with_max_width (36)
					.with_border_type ({BORDER_TYPE}.rounded).with_hit_id_base (Toast_id_base),
					part (l_inner, 0, 0, l_width, l_inner.height.to_integer_32 - 1), toasts)
			end
				-- The menu last: its drop-downs cover the panel and the toasts
			a_frame.render_stateful_widget ((create {TUI_MENU})
				.with_bar_style (l_theme.base).with_menu_style (l_theme.base)
				.with_highlight_style (l_theme.highlight).with_disabled_style (l_theme.muted)
				.with_shadow (create {SHADOW}.make_light_shade), a_frame.area, menu)
		end

	process (a_event: EVENT)
			-- Ticks expire toasts; keys and clicks go to the menu while it is open (or when
			-- they open it), else to the toasts and the controls.
		do
			if a_event.is_tick then
				toasts.expire (clock_ms.max (toasts.now_ms))
			elseif attached {MOUSE_EVENT} a_event as m then
				process_mouse (m)
			elseif attached {KEY_EVENT} a_event as k and then k.is_press then
				process_key (k)
			end
			run_chosen
		end

feature {NONE} -- Input

	process_key (k: KEY_EVENT)
			-- Handle the key press `k`.
		do
			if k.code.is_function and then k.code.function_number = 10 then
				if menu.is_open then
					menu.close
				else
					menu.open
				end
			elseif k.modifiers.is_alt and then k.code.is_char
				and then menu.entry_with_initial (k.code.character) > 0
			then
				menu.open_entry (menu.entry_with_initial (k.code.character))
			elseif menu.is_open then
				if k.code.is_down then
					menu.move_down
				elseif k.code.is_up then
					menu.move_up
				elseif k.code.is_right then
					menu.move_right
				elseif k.code.is_left then
					menu.move_left
				elseif k.code.is_enter then
					menu.activate
				elseif k.code.is_escape then
					menu.close_level
				end
			elseif k.code.is_escape then
				stop
			elseif k.code.is_tab then
				focus_manager.focus_next
			elseif k.code.is_back_tab then
				focus_manager.focus_previous
			elseif k.code.is_char then
				inspect k.code.character
				when 'q' then
					stop
				when 't' then
					next_theme
				when 's' then
					save_theme
				when ' ' then
					toggle_focused
				else
				end
			elseif attached focused_slider as l_state then
				if k.code.is_right or k.code.is_up then
					l_state.increase
				elseif k.code.is_left or k.code.is_down then
					l_state.decrease
				elseif k.code.is_home then
					l_state.set_to_minimum
				elseif k.code.is_end then
					l_state.set_to_maximum
				end
			end
		end

	process_mouse (m: MOUSE_EVENT)
			-- A press goes to the menu, a toast, or the control under it.
		local
			l_hit: detachable WIDGET_ID
			col, row: INTEGER
		do
			if m.is_down then
				l_hit := hit_test (m)
				if attached terminal.shown_area as l_shown then
					col := m.column.to_integer_32 - l_shown.x.to_integer_32
					row := m.row.to_integer_32 - l_shown.y.to_integer_32
				end
				if menu.handles (l_hit) then
					menu.click (l_hit)
				elseif attached l_hit and then toasts.has_id (l_hit.value - Toast_id_base) then
					toasts.dismiss_id (l_hit.value - Toast_id_base)
				elseif focus_manager.focus_at (l_hit) then
					if focus_manager.is_focused (id_volume) then
						slide (volume_slider, volume_area, volume, col, row)
					elseif focus_manager.is_focused (id_speed) then
						slide (speed_slider, speed_area, speed, col, row)
					else
						toggle_focused
					end
				end
			end
		end

	slide (a_slider: TUI_SLIDER; a_area: RECT; a_state: SLIDER_STATE; a_column, a_row: INTEGER)
			-- Move `a_state` to the track cell at (`a_column`, `a_row`), when it is on the track.
		local
			l_length: INTEGER
		do
			l_length := a_slider.track_length (a_area, a_state)
			if l_length > 0 and then a_slider.is_on_track (a_area, a_state, a_column, a_row) then
				a_state.set_from_position (a_slider.track_cell (a_area, a_state, a_column, a_row), l_length)
			end
		end

	focused_slider: detachable SLIDER_STATE
			-- State of the focused slider, or Void
		do
			if focus_manager.is_focused (id_volume) then
				Result := volume
			elseif focus_manager.is_focused (id_speed) then
				Result := speed
			end
		end

feature -- Commands

	next_theme
			-- Make the next of `themes` current (after the last, the first).
		do
			theme_index := theme_index \\ themes.count + 1
		ensure
			cycled: theme_index = old theme_index \\ themes.count + 1
		end

	select_preset (a_preset: INTEGER)
			-- Make preset `a_preset` (1 dark .. 4 dracula) current.
		require
			valid_preset: Preset_names.valid_index (a_preset)
		do
			theme_index := themes.count - Preset_names.count + a_preset
		ensure
			selected: theme_name.same_string (Preset_names [a_preset])
		end

	save_theme
			-- Save the current theme to `save_path`, and say so in a toast.
		local
			l_file: TUI_THEME_FILE
		do
			create l_file.make
			l_file.save (theme, save_path)
			if l_file.has_error then
				toasts.push ({STRING_32} "Not saved: " + l_file.error_message, {TOAST_LEVEL}.error, 6000)
			else
				toasts.push ({STRING_32} "Saved theme " + theme_name + " to " + file_name (save_path), {TOAST_LEVEL}.success, 3000)
			end
		ensure
			toast_pushed: toasts.count = old toasts.count + 1
		end

	toggle_focused
			-- Toggle the focused checkbox.
		local
			i: INTEGER
		do
			from i := 1 until i > 3 loop
				if focus_manager.is_focused (option_ids [i]) then
					options [i] := not options [i]
				end
				i := i + 1
			end
		end

	run_chosen
			-- Run the command chosen in the menu, if any, and forget it.
		do
			if attached menu.chosen_item as l_item then
				if attached l_item.widget_id as l_id then
					inspect l_id.value
					when Cmd_save then
						save_theme
					when Cmd_quit then
						stop
					when Cmd_next_theme then
						next_theme
					when Cmd_about then
						toasts.push ("EiffelTUI settings: themes are TOML files (TUI_THEME_FILE)", {TOAST_LEVEL}.info, 4000)
					when Cmd_dark .. Cmd_dracula then
						select_preset (l_id.value - Cmd_dark + 1)
					else
					end
				end
				menu.clear_chosen
			end
		end

feature {NONE} -- Implementation

	preset (a_name: READABLE_STRING_GENERAL): TUI_THEME
			-- The preset named `a_name` (dark when the name is not a preset's)
		do
			if a_name.same_string ("light") then
				Result := {TUI_THEME}.light
			elseif a_name.same_string ("nord") then
				Result := {TUI_THEME}.nord
			elseif a_name.same_string ("dracula") then
				Result := {TUI_THEME}.dracula
			else
				Result := {TUI_THEME}.dark
			end
		end

	file_name (a_path: READABLE_STRING_GENERAL): STRING_32
			-- The last part of `a_path`
		do
			if attached (create {PATH}.make_from_string (a_path)).entry as l_entry then
				Result := l_entry.name
			else
				create Result.make_from_string_general (a_path)
			end
		end

	part (a_parent: RECT; a_dx, a_dy, a_width, a_height: INTEGER): RECT
			-- The rectangle `a_width` x `a_height` at (`a_dx`, `a_dy`) inside `a_parent`, cut to it
		do
			if a_dx < 0 or a_dy < 0 or a_dx >= a_parent.width.to_integer_32 or a_dy >= a_parent.height.to_integer_32
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
	themes_named: themes.count = theme_names.count
	presets_last: themes.count >= Preset_names.count
	valid_theme_index: themes.valid_index (theme_index)

end
