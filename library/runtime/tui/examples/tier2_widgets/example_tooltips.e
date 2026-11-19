note
	description: "[
		Tier 2 Widget Specialist Example: Tooltips (P2 W6).
		Demonstrates TUI_TOOLTIP, HOVER_STATE and mouse motion reporting
		({TUI_APPLICATION}.set_mouse_motion, mode 1003): four checkboxes, each with a help
		text shown in a box next to it.

		  * Hover: rest the pointer on a control for half a second (10 ticks of 50 ms) and its
		    tooltip appears; moving to another control starts again, moving off every control
		    hides it, and a click or a key dismisses it until the pointer moves on.
		  * Focus: F1 shows the tooltip of the focused control, and hides it again; Tab and
		    Shift+Tab move the focus. This works without motion reporting.
		  * Space or a click toggles a checkbox; q or Esc quits.

		The controls are placed so that the tooltips show OVERLAY_PLACEMENT at work: "Autosave"
		at the right edge (its box is shifted left), "Spell check" on the last rows (its box
		flips above it). A hover tooltip wins over the F1 one. The tooltip is rendered last,
		over the panel, in the whole frame.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	EXAMPLE_TOOLTIPS

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
			-- Initialize and launch the tooltip example.
		local
			l_args: ARGUMENTS_32
			i: INTEGER
		do
			init_tooltips
			Precursor
			set_mouse_capture (True)
			set_mouse_motion (True)
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
			init_tooltips
			make_with_viewport (create {VIEWPORT}.make_fullscreen)
			set_mouse_capture (True)
			set_mouse_motion (True)
			auto_exit_frames := a_frames
			frame_counter := 0
			run
		end

	make_on (a_terminal: TERMINAL [ANSI_TERMINAL_BACKEND])
			-- Initialize on `a_terminal` without running (for snapshot tests).
		require
			terminal_attached: a_terminal /= Void
		do
			init_tooltips
			make_with_terminal (a_terminal)
			set_mouse_capture (True)
			set_mouse_motion (True)
			auto_exit_frames := -1
			frame_counter := 0
		ensure
			not_running: not is_running
		end

feature {NONE} -- Setup

	init_tooltips
			-- The controls, their ids, the focus ring and the hover state.
		local
			i: INTEGER
		do
			create checked.make_filled (False, 1, Labels.count)
			checked [1] := True
			create ids.make_filled (create {WIDGET_ID}.make (Id_base + 1), 1, Labels.count)
			create anchors.make_filled (create {RECT}.make (0, 0, 0, 0), 1, Labels.count)
			create focus_manager.make
			from i := 1 until i > Labels.count loop
				ids [i] := create {WIDGET_ID}.make (Id_base + i)
				focus_manager.register (ids [i])
				i := i + 1
			end
			create hover
			hover.set_tooltip_id (create {WIDGET_ID}.make (Tooltip_id))
		end

feature -- Access

	hover: HOVER_STATE
			-- The control under the pointer, and whether its tooltip is due

	checked: ARRAY [BOOLEAN]
			-- Values of the checkboxes

	is_help_shown: BOOLEAN
			-- Did F1 ask for the focused control's tooltip?

	shown_index: INTEGER
			-- Control whose tooltip the last frame showed (1 .. 4), 0 for none
		do
			if attached hover.shown_id as l_id then
				Result := index_of (l_id)
			end
			if Result = 0 and is_help_shown and then attached focus_manager.focused_id as l_focused then
				Result := index_of (l_focused)
			end
		ensure
			in_range: Result >= 0 and Result <= Labels.count
		end

	hovered_index: INTEGER
			-- Control under the pointer (1 .. 4), 0 for none
		do
			if attached hover.hovered as l_id then
				Result := index_of (l_id)
			end
		ensure
			in_range: Result >= 0 and Result <= Labels.count
		end

	anchors: ARRAY [RECT]
			-- Areas the controls were last drawn in (frame coordinates)

	Labels: ARRAY [STRING_32]
			-- Labels of the checkboxes
		once
			Result := <<{STRING_32} "Wrap lines", {STRING_32} "Line numbers", {STRING_32} "Autosave",
				{STRING_32} "Spell check">>
		end

	Help_texts: ARRAY [STRING_32]
			-- Tooltip of each checkbox
		once
			Result := <<{STRING_32} "Wrap long lines at the window's edge instead of scrolling sideways.",
				{STRING_32} "Show line numbers in the gutter.",
				{STRING_32} "Save every 30 s.",
				{STRING_32} "Underline unknown words.">>
		end

	Tooltip_width: NATURAL_16 = 30
			-- Widest tooltip box, borders included

	Id_base: INTEGER = 200
			-- Id of control `i` is `Id_base + i`

	Tooltip_id: INTEGER = 300
			-- Id the tooltip's box is registered under: the pointer on it keeps the hover, a
			-- click on it toggles nothing

feature {NONE} -- State

	focus_manager: FOCUS_MANAGER
			-- Tab order of the checkboxes

	ids: ARRAY [WIDGET_ID]
			-- Ids of the checkboxes

	auto_exit_frames: INTEGER
			-- Auto-exit in batch mode

	frame_counter: INTEGER
			-- Rendered frame count

feature {NONE} -- Application Hooks

	render (a_frame: FRAME)
			-- Draw the panel and the checkboxes, then the tooltip due, if any, over them.
		local
			l_theme: TUI_THEME
			l_inner: RECT
			l_box: TUI_CHECKBOX
			i, l_shown: INTEGER
			l_status: STRING_32
		do
			if auto_exit_frames > 0 then
				frame_counter := frame_counter + 1
				if frame_counter >= auto_exit_frames then
					stop
				end
			end
			l_theme := {TUI_THEME}.dark
			a_frame.render_widget ((create {TUI_BLOCK}.make).with_border_type ({BORDER_TYPE}.rounded)
				.with_style (l_theme.base).with_border_style (l_theme.primary).with_title (" Tooltips "), a_frame.area)
			l_inner := a_frame.area.inner (1, 1)
			if l_inner.width >= 2 and l_inner.height >= 2 then
				a_frame.render_widget ((create {TUI_PARAGRAPH}.make_raw ("Hover or F1: help  Tab: focus  Space: toggle  q: quit"))
					.with_style (l_theme.base), create {RECT}.make (l_inner.x + 1, l_inner.y, l_inner.width - 1, 1))
				from i := 1 until i > Labels.count loop
					create l_box.make (Labels [i])
					anchors [i] := control_area (i, l_box.width, l_inner)
					a_frame.render_widget (l_box.with_checked (checked [i])
							.with_focused (focus_manager.is_focused (ids [i]))
							.with_focused_style (l_theme.highlight)
							.with_hit_id (ids [i]),
						anchors [i])
					i := i + 1
				end
				if hovered_index > 0 then
					l_status := {STRING_32} "Hovered: " + Labels [hovered_index]
				else
					l_status := {STRING_32} "Hovered: none"
				end
				a_frame.render_widget ((create {TUI_PARAGRAPH}.make_raw (l_status)).with_style (l_theme.muted),
					create {RECT}.make (l_inner.x + 1, l_inner.bottom - 1, l_inner.width - 1, 1))
					-- The tooltip last, over the rest, anywhere in the frame
				l_shown := shown_index
				if l_shown > 0 then
					a_frame.render_widget ((create {TUI_TOOLTIP}.make (Help_texts [l_shown], anchors [l_shown]))
						.with_hit_id (hover.tooltip_id)
						.with_max_width (Tooltip_width)
						.with_style (l_theme.base)
						.with_border_style (l_theme.info), a_frame.area)
				end
			end
		end

	process (a_event: EVENT)
			-- Ticks count the hover; moves track it; a press toggles the control under it and
			-- dismisses the tooltip; keys move the focus, toggle, show the F1 tooltip or quit.
		do
			if a_event.is_tick then
				hover.tick
			elseif attached {MOUSE_EVENT} a_event as m then
				if m.is_move or m.is_drag then
					hover.hover (hit_test (m))
				elseif m.is_down then
					hover.dismiss
					if focus_manager.focus_at (hit_test (m)) then
						toggle_focused
					end
				end
			elseif attached {KEY_EVENT} a_event as k and then k.is_press then
				hover.dismiss
				if k.code.is_escape or else (k.code.is_char and then k.code.character = 'q') then
					stop
				elseif k.code.is_function and then k.code.function_number = 1 then
					is_help_shown := not is_help_shown
				elseif k.code.is_tab then
					focus_manager.focus_next
				elseif k.code.is_back_tab then
					focus_manager.focus_previous
				elseif k.code.is_char and then k.code.character = ' ' then
					toggle_focused
				end
			end
		end

feature {NONE} -- Implementation

	control_area (a_index, a_width: INTEGER; a_inner: RECT): RECT
			-- Area of control `a_index`, `a_width` columns wide, in the panel's inside
			-- `a_inner`: two on the left, one at the right edge, one on the row above the status
		require
			valid_index: a_index >= 1 and a_index <= Labels.count
			room: a_inner.width >= 2 and a_inner.height >= 2
		local
			l_width, l_x, l_y, l_last: INTEGER
		do
			l_width := a_width.min (a_inner.width.to_integer_32 - 1)
			l_last := a_inner.bottom.to_integer_32 - 1
			inspect a_index
			when 1 then
				l_x := a_inner.x.to_integer_32 + 1
				l_y := (a_inner.y.to_integer_32 + 2).min (l_last)
			when 2 then
				l_x := a_inner.x.to_integer_32 + 1
				l_y := (a_inner.y.to_integer_32 + 4).min (l_last)
			when 3 then
				l_x := a_inner.right.to_integer_32 - l_width - 1
				l_y := (a_inner.y.to_integer_32 + 2).min (l_last)
			else
				l_x := a_inner.x.to_integer_32 + 1
				l_y := l_last - 1
			end
			create Result.make (l_x.to_natural_16, l_y.to_natural_16, l_width.to_natural_16, 1)
		ensure
			result_not_void: Result /= Void
		end

	index_of (a_id: WIDGET_ID): INTEGER
			-- Index of the control with id `a_id`, 0 if none
		require
			id_not_void: a_id /= Void
		local
			i: INTEGER
		do
			from i := 1 until i > ids.count or Result > 0 loop
				if ids [i] ~ a_id then
					Result := i
				end
				i := i + 1
			end
		ensure
			in_range: Result >= 0 and Result <= Labels.count
		end

	toggle_focused
			-- Toggle the focused checkbox.
		local
			i: INTEGER
		do
			from i := 1 until i > ids.count loop
				if focus_manager.is_focused (ids [i]) then
					checked [i] := not checked [i]
				end
				i := i + 1
			end
		end

invariant
	hover_attached: hover /= Void
	one_value_per_control: checked.count = Labels.count and ids.count = Labels.count and anchors.count = Labels.count

end
