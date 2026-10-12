note
	description: "[
		Tier 1 Foundation Example: Inline Viewport (Ratatui 1-to-1).
		Demonstrates non-fullscreen terminal rendering under the prompt
		using an 8-line inline viewport, simulated parallel download progress,
		and full terminal history preservation.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	EXAMPLE_INLINE

inherit
	TUI_APPLICATION
		redefine
			make,
			make_with_terminal
		end

create
	make,
	make_batch,
	make_with_terminal

feature {NONE} -- Initialization

	make
			-- Initialize and launch 8-line inline viewport example.
		local
			l_args: ARGUMENTS_32
			i: INTEGER
		do
			init_progress
			make_with_viewport (create {VIEWPORT}.make_inline (8))
			set_tick_rate (80)

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
			-- Initialize and run for `a_frames` frames.
		do
			init_progress
			make_with_viewport (create {VIEWPORT}.make_inline (8))
			set_tick_rate (80)
			auto_exit_frames := a_frames
			frame_counter := 0
			run
		end

	make_with_terminal (a_terminal: TERMINAL [ANSI_TERMINAL_BACKEND])
			-- Initialize with custom `a_terminal`.
		do
			init_progress
			Precursor (a_terminal)
		end

	init_progress
			-- Initialize download state arrays.
		do
			create progress_items.make_filled (0, 1, 4)
			create progress_names.make_filled ("", 1, 4)
			progress_names.put ("kernel-src.tar.xz", 1)
			progress_names.put ("eiffel_runtime.dll", 2)
			progress_names.put ("dataset_2026.parquet", 3)
			progress_names.put ("tui_assets.zip", 4)
		end

feature {NONE} -- State

	progress_items: ARRAY [INTEGER]
			-- Percentage progress (0..100) for each of the 4 downloads

	progress_names: ARRAY [STRING_8]
			-- File names of the downloads

	auto_exit_frames: INTEGER
			-- Number of frames before auto-exit in batch mode (-1 = interactive)

	frame_counter: INTEGER
			-- Frame counter for batch mode

feature {NONE} -- Application Hooks

	render (a_frame: FRAME)
			-- Render inline download progress bars.
		local
			l_buf: BUFFER
			l_title_style, l_stat_style, l_hint_style: STYLE
			l_gauge: TUI_LINE_GAUGE
			l_tot_ratio: REAL_64
			l_completed, i, r, w, l_x, l_y: INTEGER
			l_tot_label: STRING_32
			l_gauge_area: RECT
		do
			if auto_exit_frames > 0 then
				frame_counter := frame_counter + 1
				if frame_counter >= auto_exit_frames then
					stop
				end
			end

			l_buf := a_frame.buffer
			l_x := a_frame.area.x.to_integer_32
			l_y := a_frame.area.y.to_integer_32
			w := a_frame.area.width.to_integer_32

			-- Calculate completed downloads and total progress
			l_completed := 0
			from i := 1 until i > 4 loop
				if progress_items [i] >= 100 then
					l_completed := l_completed + 1
				end
				i := i + 1
			end
			l_tot_ratio := (progress_items [1] + progress_items [2] + progress_items [3] + progress_items [4]).to_double / 400.0

			-- Line 0: Header
			create l_title_style.make_with_colors ({COLOR}.Bright_white, {COLOR}.Black)
			l_title_style := l_title_style.with_bold
			l_buf.put_string (l_y, l_x + 1, "Inline Viewport (8 lines) - Press 'q' or Esc to quit", l_title_style)

			-- Line 1: Total progress line gauge
			create l_tot_label.make_from_string_general ("Total Progress: ")
			l_tot_label.append_string_general (l_completed.out)
			l_tot_label.append_string_general ("/4 files (")
			l_tot_label.append_string_general ((l_tot_ratio * 100.0).truncated_to_integer.out)
			l_tot_label.append_string_general ("%) ")

			create l_gauge.make
			l_gauge := l_gauge.with_ratio (l_tot_ratio.min (1.0)).
				with_label (l_tot_label).
				with_filled_style (create {STYLE}.make_fg ({COLOR}.Bright_cyan)).
				with_unfilled_style (create {STYLE}.make_fg ({COLOR}.Dark_gray))
			create l_gauge_area.make (a_frame.area.x, (l_y + 1).to_natural_16, a_frame.area.width, 1)
			l_gauge.render (l_gauge_area, l_buf)

			-- Lines 2..5: 4 individual download progress lines
			from i := 1 until i > 4 loop
				r := l_y + 1 + i
				create l_gauge.make
				l_gauge := l_gauge.with_ratio ((progress_items [i].to_double / 100.0).min (1.0)).
					with_label (" " + progress_names [i] + ": ").
					with_filled_style (create {STYLE}.make_fg ({COLOR}.Bright_green)).
					with_unfilled_style (create {STYLE}.make_fg ({COLOR}.Dark_gray))
				create l_gauge_area.make (a_frame.area.x, r.to_natural_16, a_frame.area.width, 1)
				l_gauge.render (l_gauge_area, l_buf)
				i := i + 1
			end

			-- Line 6: Status
			create l_stat_style.make_fg ({COLOR}.Bright_yellow)
			if l_completed = 4 then
				l_buf.put_string (l_y + 6, l_x + 1, "Status: All downloads completed successfully!", l_stat_style)
			else
				l_buf.put_string (l_y + 6, l_x + 1, "Status: Downloading assets in background...", l_stat_style)
			end

			-- Line 7: Hint about scrollback
			create l_hint_style.make_fg ({COLOR}.Dark_gray)
			l_buf.put_string (l_y + 7, l_x + 1, "Scrollback history above this 8-line area is preserved.", l_hint_style)
		end

	process (a_event: EVENT)
			-- Advance simulated downloads on tick and quit on 'q' or Escape.
		do
			if a_event.is_tick then
				if progress_items [1] < 100 then
					progress_items.put ((progress_items [1] + 5).min (100), 1)
				end
				if progress_items [2] < 100 then
					progress_items.put ((progress_items [2] + 3).min (100), 2)
				end
				if progress_items [3] < 100 then
					progress_items.put ((progress_items [3] + 4).min (100), 3)
				end
				if progress_items [4] < 100 then
					progress_items.put ((progress_items [4] + 2).min (100), 4)
				end
			elseif attached {KEY_EVENT} a_event as k then
				if k.is_press then
					if k.code.is_escape or else (k.code.is_char and then (k.code.character = 'q' or k.code.character = 'Q')) then
						stop
					end
				end
			end
		end

end
