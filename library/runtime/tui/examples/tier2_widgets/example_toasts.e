note
	description: "[
		Tier 2 Widget Specialist Example: Toasts (P2 W5).
		Demonstrates TUI_TOAST + TOAST_QUEUE: messages of four levels stacked at an edge of the
		screen, each shown for its own time, driven by the application's clock.

		  * i / s / w / e push an info, success, warning or error toast; l pushes a long one
		    (word-wrapped to the toast's width); b pushes five at once (two wait: at most
		    `max_visible` are shown, and a waiting toast's time starts when it is shown).
		  * p moves the toasts to the next position (the four corners, top and bottom centre);
		    m changes `max_visible` (1, 2, 3); t switches the dark and the light theme.
		  * A click on a toast dismisses it; c clears them all; q or Esc quits.

		Clock: on each TICK_EVENT the example calls `TOAST_QUEUE.expire` with
		{MONOTONIC_CLOCK}.milliseconds (through `clock_ms`, which a test redefines). The
		queue's `expired_action` counts the toasts that expired; the status line shows it.
		A toast pushed between two ticks starts its time at the next one. The toasts are
		rendered last, over the panel; the widget registers each box under `Toast_id_base` +
		the toast's id (`TUI_TOAST.with_hit_id_base`), so a click dismisses the toast clicked
		(`TOAST_QUEUE.dismiss_id`) even when another expired since the frame was drawn.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	EXAMPLE_TOASTS

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
			-- Initialize and launch the toast example.
		local
			l_args: ARGUMENTS_32
			i: INTEGER
		do
			init_toasts
			Precursor
			count_expiries
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
			init_toasts
			make_with_viewport (create {VIEWPORT}.make_fullscreen)
			count_expiries
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
			init_toasts
			make_with_terminal (a_terminal)
			count_expiries
			set_mouse_capture (True)
			auto_exit_frames := -1
			frame_counter := 0
		ensure
			not_running: not is_running
		end

feature {NONE} -- Setup

	init_toasts
			-- Build the queue, at the clock's time (its expiry counter is set by
			-- `count_expiries`, once the application is initialized).
		do
			create toasts.make_at (clock_ms)
			position := {TOAST_POSITION}.top_right
			is_dark := True
		end

feature -- Access

	toasts: TOAST_QUEUE
			-- The messages

	position: NATURAL_8
			-- Where the toasts are stacked (TOAST_POSITION)

	is_dark: BOOLEAN
			-- Dark theme (else light)?

	expired_count: INTEGER
			-- Toasts that expired so far

	pushed_count: INTEGER
			-- Toasts pushed so far

	theme: TUI_THEME
			-- The theme in use
		do
			if is_dark then
				Result := {TUI_THEME}.dark
			else
				Result := {TUI_THEME}.light
			end
		end

	clock_ms: INTEGER_64
			-- The application's clock (a test redefines it)
		do
			Result := {MONOTONIC_CLOCK}.milliseconds
		end

	Position_names: ARRAY [STRING_32]
			-- Names of the positions, by TOAST_POSITION value
		once
			Result := <<{STRING_32} "top left", {STRING_32} "top centre", {STRING_32} "top right",
				{STRING_32} "bottom left", {STRING_32} "bottom centre", {STRING_32} "bottom right">>
		end

	Toast_id_base: INTEGER = 100
			-- A toast's box is registered under `Toast_id_base` + its id (above every other id)

feature {NONE} -- State

	auto_exit_frames: INTEGER
			-- Auto-exit in batch mode

	frame_counter: INTEGER
			-- Rendered frame count

feature {NONE} -- Application Hooks

	render (a_frame: FRAME)
			-- Draw the panel, then the toasts over it.
		local
			l_theme: TUI_THEME
			l_inner: RECT
			l_toast: TUI_TOAST
			l_lines: ARRAY [STRING_32]
			i: INTEGER
		do
			if auto_exit_frames > 0 then
				frame_counter := frame_counter + 1
				if frame_counter >= auto_exit_frames then
					stop
				end
			end
			l_theme := theme
			a_frame.render_widget ((create {TUI_BLOCK}.make).with_border_type ({BORDER_TYPE}.rounded)
				.with_style (l_theme.base).with_border_style (l_theme.primary).with_title (" Toasts "), a_frame.area)
			l_inner := a_frame.area.inner (1, 1)
			l_lines := <<
				{STRING_32} "i s w e: info, success, warning, error",
				{STRING_32} "l: long message   b: five at once",
				{STRING_32} "p: position (" + Position_names [position] + ")",
				{STRING_32} "m: max visible (" + toasts.max_visible.out + ")   t: theme",
				{STRING_32} "click: dismiss   c: clear   q: quit",
				{STRING_32} "",
				{STRING_32} "Shown " + toasts.visible_count.out + ", waiting " + toasts.waiting_count.out
					+ ", expired " + expired_count.out>>
			from i := 1 until i > l_lines.count or i > l_inner.height.to_integer_32 loop
				a_frame.render_widget ((create {TUI_PARAGRAPH}.make_raw (l_lines [i])).with_style (l_theme.base),
					create {RECT}.make (l_inner.x + 1, l_inner.y + (i - 1).to_natural_16, l_inner.width - l_inner.width.min (1), 1))
				i := i + 1
			end
				-- The toasts last, over the panel; each box clickable under its toast's id
			l_toast := (create {TUI_TOAST}).with_theme (l_theme).with_position (position).with_max_width (32)
				.with_border_type ({BORDER_TYPE}.rounded).with_hit_id_base (Toast_id_base)
			a_frame.render_stateful_widget (l_toast, l_inner, toasts)
		end

	process (a_event: EVENT)
			-- Ticks expire toasts; keys push, move and clear them; a click dismisses one.
		do
			if a_event.is_tick then
				toasts.expire (clock_ms.max (toasts.now_ms))
			elseif attached {MOUSE_EVENT} a_event as m then
				if m.is_down and then attached hit_test (m) as l_hit
					and then toasts.has_id (l_hit.value - Toast_id_base)
				then
					toasts.dismiss_id (l_hit.value - Toast_id_base)
				end
			elseif attached {KEY_EVENT} a_event as k and then k.is_press then
				if k.code.is_escape then
					stop
				elseif k.code.is_char then
					handle_key (k.code.character)
				end
			end
		end

feature {NONE} -- Commands

	handle_key (a_char: CHARACTER_32)
			-- Run the command of key `a_char`.
		local
			i: INTEGER
		do
			inspect a_char
			when 'i' then
				push ("Build started.", {TOAST_LEVEL}.info, 3000)
			when 's' then
				push ("Saved settings.toml", {TOAST_LEVEL}.success, 3000)
			when 'w' then
				push ("Disk almost full: 92%% used", {TOAST_LEVEL}.warning, 5000)
			when 'e' then
				push ("Could not reach the server.%NRetrying in 10 s.", {TOAST_LEVEL}.error, 8000)
			when 'l' then
				push ("A long message is word-wrapped to the width of the toast, here at most 30 columns of text.",
					{TOAST_LEVEL}.info, 6000)
			when 'b' then
				from i := 1 until i > 5 loop
					push ({STRING_32} "Message " + i.out + " of 5", {TOAST_LEVEL}.info, 2000)
					i := i + 1
				end
			when 'p' then
				position := position \\ {TOAST_POSITION}.bottom_right + 1
			when 'm' then
				toasts.set_max_visible (toasts.max_visible \\ 3 + 1)
			when 't' then
				is_dark := not is_dark
			when 'c' then
				toasts.clear
			when 'q' then
				stop
			else
			end
		end

	push (a_text: READABLE_STRING_GENERAL; a_level: NATURAL_8; a_duration_ms: INTEGER_64)
			-- Push a toast (its time starts at the next tick).
		require
			text_not_void: a_text /= Void
			valid_level: {TOAST_LEVEL}.is_valid (a_level)
			positive_duration: a_duration_ms > 0
		do
			toasts.push (a_text, a_level, a_duration_ms)
			pushed_count := pushed_count + 1
		ensure
			counted: pushed_count = old pushed_count + 1
		end

	count_expiries
			-- Count the toasts that expire, through the queue's `expired_action`.
		do
			toasts.set_expired_action (agent count_expired)
		end

	count_expired (a_toast: TOAST)
			-- Count `a_toast`, which just expired.
		do
			expired_count := expired_count + 1
		ensure
			counted: expired_count = old expired_count + 1
		end

invariant
	valid_position: {TOAST_POSITION}.is_valid (position)

end
