note
	description: "[
		Monthly calendar widget displaying month/year header, weekday labels,
		and a 7-column numeric date grid with selection highlighting.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_CALENDAR

inherit
	STATEFUL_WIDGET [CALENDAR_STATE]
		redefine
			default_create,
			copy,
			is_equal
		end
	BLOCK_CONTAINER
		redefine
			default_create,
			copy,
			is_equal
		end

create
	default_create,
	make

feature {NONE} -- Initialization

	default_create
			-- Initialize with default styling and headers enabled.
		do
			create style.default_create
			create header_style.default_create
			header_style := header_style.with_bold
			create weekday_style.default_create
			weekday_style := weekday_style.with_dim
			create selected_style.default_create
			selected_style := selected_style.with_reverse
			show_month_header := True
			show_weekday_header := True
			first_day_of_week := 1
		ensure then
			show_month_header_default: show_month_header
			show_weekday_header_default: show_weekday_header
			default_first_day: first_day_of_week = 1
		end

	make
			-- Synonym for `default_create`.
		do
			default_create
		end

feature -- Duplication

	copy (a_other: like Current)
			-- Copy `a_other` to `Current`.
		do
			if a_other /= Current then
				standard_copy (a_other)
				if attached a_other.date_styles as ds then
					date_styles := ds.twin
				end
			end
		end

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Is `a_other` content-equal to `Current`?
		do
			if a_other = Current then
				Result := True
			elseif standard_is_equal (a_other) then
				Result := True
			else
				Result := first_day_of_week = a_other.first_day_of_week
					and show_month_header = a_other.show_month_header
					and show_weekday_header = a_other.show_weekday_header
					and style.is_equal (a_other.style)
					and header_style.is_equal (a_other.header_style)
					and weekday_style.is_equal (a_other.weekday_style)
					and selected_style.is_equal (a_other.selected_style)
					and same_block (a_other)
					and date_style_agent = a_other.date_style_agent
					and same_date_styles (a_other)
					and surrounding_style ~ a_other.surrounding_style
			end
		end

	same_date_styles (a_other: like Current): BOOLEAN
			-- Do `Current` and `a_other` have equal per-date styles?
		do
			if attached date_styles as l_mine and then attached a_other.date_styles as l_theirs then
				Result := l_mine.count = l_theirs.count and then
					across l_mine as s all
						attached l_theirs.item (@s.key) as l_style and then l_style.is_equal (s)
					end
			else
				Result := not (attached date_styles as l_d and then not l_d.is_empty)
					and not (attached a_other.date_styles as l_o and then not l_o.is_empty)
			end
		end

feature -- Access

	style: STYLE
			-- Base style for calendar grid

	header_style: STYLE
			-- Style for month/year header line

	weekday_style: STYLE
			-- Style for weekday labels (Mo Tu We...)

	selected_style: STYLE
			-- Style for currently selected day cell

	show_month_header: BOOLEAN
			-- Display month name and year at top?

	show_weekday_header: BOOLEAN
			-- Display weekday abbreviations?

	first_day_of_week: INTEGER
			-- First day of the week (1 = Monday, ..., 7 = Sunday). Default is 1.

	date_style_agent: detachable FUNCTION [INTEGER, INTEGER, INTEGER, detachable STYLE]
			-- Optional callback returning custom style for (year, month, day).

	date_styles: detachable HASH_TABLE [STYLE, INTEGER_64]
			-- Optional per-date custom styles map keyed by `date_key`.

	surrounding_style: detachable STYLE
			-- Style of the days of the adjacent months shown in the first and last week
			-- (Ratatui `Monthly::show_surrounding`), or Void to leave those cells blank

feature -- Element Change

	set_style (a_style: STYLE)
			-- Set base style to `a_style`.
		require
			style_not_void: a_style /= Void
		do
			style := a_style
		ensure
			style_set: style = a_style
		end

	set_header_style (a_style: STYLE)
			-- Set header style to `a_style`.
		require
			style_not_void: a_style /= Void
		do
			header_style := a_style
		ensure
			header_style_set: header_style = a_style
		end

	set_weekday_style (a_style: STYLE)
			-- Set weekday style to `a_style`.
		require
			style_not_void: a_style /= Void
		do
			weekday_style := a_style
		ensure
			weekday_style_set: weekday_style = a_style
		end

	set_selected_style (a_style: STYLE)
			-- Set selected day style to `a_style`.
		require
			style_not_void: a_style /= Void
		do
			selected_style := a_style
		ensure
			selected_style_set: selected_style = a_style
		end

	set_show_month_header (a_val: BOOLEAN)
			-- Set month header visibility.
		do
			show_month_header := a_val
		ensure
			show_month_header_set: show_month_header = a_val
		end

	set_show_weekday_header (a_val: BOOLEAN)
			-- Set weekday header visibility.
		do
			show_weekday_header := a_val
		ensure
			show_weekday_header_set: show_weekday_header = a_val
		end

	set_first_day_of_week (a_day: INTEGER)
			-- Set first day of week (1 = Monday, ..., 7 = Sunday).
		require
			valid_day: a_day >= 1 and a_day <= 7
		do
			first_day_of_week := a_day
		ensure
			first_day_set: first_day_of_week = a_day
		end

	set_date_style_agent (a_agent: detachable FUNCTION [INTEGER, INTEGER, INTEGER, detachable STYLE])
			-- Set custom styling callback for (year, month, day).
		do
			date_style_agent := a_agent
		ensure
			agent_set: date_style_agent = a_agent
		end

	set_show_surrounding (a_style: detachable STYLE)
			-- Show the days of the adjacent months with `a_style` (Void: hide them).
		do
			surrounding_style := a_style
		ensure
			surrounding_style_set: surrounding_style = a_style
		end

	set_date_style (a_year, a_month, a_day: INTEGER; a_style: STYLE)
			-- Set custom style for specific date.
		require
			style_not_void: a_style /= Void
			valid_month: a_month >= 1 and a_month <= 12
			valid_day: a_day >= 1 and a_day <= {CALENDAR_STATE}.days_in_month (a_year, a_month)
		local
			l_styles: HASH_TABLE [STYLE, INTEGER_64]
		do
			if attached date_styles as ds then
				l_styles := ds
			else
				create l_styles.make (8)
				date_styles := l_styles
			end
			l_styles.force (a_style, date_key (a_year, a_month, a_day))
		end

feature -- Fluent Builders

	with_style (a_style: STYLE): like Current
			-- Return a copy of Current with `style` set to `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_style (a_style)
		ensure
			result_not_void: Result /= Void
			style_set: Result.style = a_style
		end

	with_header_style (a_style: STYLE): like Current
			-- Return a copy of Current with `header_style` set to `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_header_style (a_style)
		ensure
			result_not_void: Result /= Void
			header_style_set: Result.header_style = a_style
		end

	with_weekday_style (a_style: STYLE): like Current
			-- Return a copy of Current with `weekday_style` set to `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_weekday_style (a_style)
		ensure
			result_not_void: Result /= Void
			weekday_style_set: Result.weekday_style = a_style
		end

	with_selected_style (a_style: STYLE): like Current
			-- Return a copy of Current with `selected_style` set to `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_selected_style (a_style)
		ensure
			result_not_void: Result /= Void
			selected_style_set: Result.selected_style = a_style
		end

	with_show_month_header (a_val: BOOLEAN): like Current
			-- Return a copy of Current with `show_month_header` set.
		do
			Result := twin
			Result.set_show_month_header (a_val)
		ensure
			result_not_void: Result /= Void
			show_month_header_set: Result.show_month_header = a_val
		end

	with_show_weekday_header (a_val: BOOLEAN): like Current
			-- Return a copy of Current with `show_weekday_header` set.
		do
			Result := twin
			Result.set_show_weekday_header (a_val)
		ensure
			result_not_void: Result /= Void
			show_weekday_header_set: Result.show_weekday_header = a_val
		end

	with_first_day_of_week (a_day: INTEGER): like Current
			-- Return a copy of Current with `first_day_of_week` set to `a_day`.
		require
			valid_day: a_day >= 1 and a_day <= 7
		do
			Result := twin
			Result.set_first_day_of_week (a_day)
		ensure
			result_not_void: Result /= Void
			first_day_set: Result.first_day_of_week = a_day
		end

	with_date_style_agent (a_agent: detachable FUNCTION [INTEGER, INTEGER, INTEGER, detachable STYLE]): like Current
			-- Return a copy of Current with `date_style_agent` set.
		do
			Result := twin
			Result.set_date_style_agent (a_agent)
		ensure
			result_not_void: Result /= Void
			agent_set: Result.date_style_agent = a_agent
		end

	with_show_surrounding (a_style: detachable STYLE): like Current
			-- Return a copy of Current showing the days of the adjacent months with `a_style`.
		do
			Result := twin
			Result.set_show_surrounding (a_style)
		ensure
			result_not_void: Result /= Void
			surrounding_style_set: Result.surrounding_style = a_style
		end

	with_date_style (a_year, a_month, a_day: INTEGER; a_style: STYLE): like Current
			-- Return a copy of Current with custom style for specific date.
		require
			style_not_void: a_style /= Void
			valid_month: a_month >= 1 and a_month <= 12
			valid_day: a_day >= 1 and a_day <= {CALENDAR_STATE}.days_in_month (a_year, a_month)
		do
			Result := twin
			Result.set_date_style (a_year, a_month, a_day, a_style)
		ensure
			result_not_void: Result /= Void
		end

feature -- Helpers

	weekday_header_string: STRING_32
			-- Weekday abbreviations row matching `first_day_of_week`.
		local
			i, l_day: INTEGER
			l_names: ARRAY [STRING_8]
		do
			l_names := <<"Mo", "Tu", "We", "Th", "Fr", "Sa", "Su">>
			create Result.make (20)
			from
				i := 0
			until
				i >= 7
			loop
				l_day := ((first_day_of_week - 1 + i) \\ 7) + 1
				if i > 0 then
					Result.append_character (' ')
				end
				Result.append_string (l_names [l_day])
				i := i + 1
			end
		end

	custom_date_style (a_year, a_month, a_day: INTEGER): detachable STYLE
			-- Custom style configured for (`a_year`, `a_month`, `a_day`), if any.
		do
			if attached date_style_agent as l_agent then
				Result := l_agent.item ([a_year, a_month, a_day])
			end
			if Result = Void and attached date_styles as ds then
				if ds.has (date_key (a_year, a_month, a_day)) then
					Result := ds.item (date_key (a_year, a_month, a_day))
				end
			end
		end

	surrounding_or_default: STYLE
			-- `surrounding_style`, or a default style when none is set
		do
			if attached surrounding_style as l_s then
				Result := l_s
			else
				create Result
			end
		end

	date_key (a_year, a_month, a_day: INTEGER): INTEGER_64
			-- Unique integer key for (year, month, day).
		do
			Result := a_year.to_integer_64 * 10000 + a_month.to_integer_64 * 100 + a_day.to_integer_64
		end

feature -- Rendering

	render (a_area: RECT; a_buffer: BUFFER)
			-- Stateless rendering using a default CALENDAR_STATE.
		local
			l_state: CALENDAR_STATE
		do
			create l_state.default_create
			render_stateful (a_area, a_buffer, l_state)
		end

	render_stateful (a_area: RECT; a_buffer: BUFFER; a_state: CALENDAR_STATE)
			-- Render calendar grid using `a_state` within `a_area` on `a_buffer`.
			-- Every write is clipped to the inner area and the buffer.
		local
			l_target: RECT
			l_w, l_col_offset, l_cur_row, l_hdr_x, l_left, l_right, l_bottom: INTEGER
			l_hdr: STRING_32
			l_start_dow, d, p, l_first, l_last, l_days, l_prev_days, l_grid_row, l_day_x: INTEGER
			l_day_str: STRING_32
			l_cell_style: STYLE
		do
			if not a_area.is_empty then
				render_block (a_area, a_buffer)
				l_target := inner_area (a_area)

				if not l_target.is_empty then
					a_buffer.set_style (l_target, style)
					l_w := l_target.width.to_integer_32
					l_cur_row := l_target.y.to_integer_32
					l_left := l_target.x.to_integer_32
					l_right := l_target.right.to_integer_32
					l_bottom := l_target.bottom.to_integer_32.min (a_buffer.height)

					-- 20 characters for "Mo Tu We Th Fr Sa Su"
					l_col_offset := l_left + ((l_w - 20) // 2).max (0)

					-- 1. Month / Year header
					if show_month_header then
						if l_cur_row < l_bottom then
							create l_hdr.make_from_string (a_state.month_name)
							l_hdr.append_character (' ')
							l_hdr.append_string (a_state.year.out)
							-- Centred by display width: a localized month name may hold wide characters
							l_hdr_x := l_left + ((l_w - {UNICODE_WIDTH}.string_width (l_hdr).to_integer_32) // 2).max (0)
							a_buffer.set_string_clipped (l_cur_row, l_hdr_x, l_hdr, l_left, l_right, style.patch (header_style))
						end
						l_cur_row := l_cur_row + 1
					end

					-- 2. Weekday abbreviations header
					if show_weekday_header then
						if l_cur_row < l_bottom then
							a_buffer.set_string_clipped (l_cur_row, l_col_offset, weekday_header_string, l_left, l_right, style.patch (weekday_style))
						end
						l_cur_row := l_cur_row + 1
					end

					-- 3. Day numbers grid: cell `p` (0-based) holds day `p - l_start_dow + 1` of the
					-- month; with `surrounding_style`, the cells before the 1st and after the last day
					-- in the first and last week show the days of the adjacent months.
					l_start_dow := (a_state.first_weekday_of_month - first_day_of_week + 7) \\ 7
					l_days := a_state.days_in_current_month
					if a_state.month = 1 then
						l_prev_days := {CALENDAR_STATE}.days_in_month (a_state.year - 1, 12)
					else
						l_prev_days := {CALENDAR_STATE}.days_in_month (a_state.year, a_state.month - 1)
					end
					if attached surrounding_style then
						l_first := 0
						l_last := ((l_start_dow + l_days + 6) // 7) * 7 - 1
					else
						l_first := l_start_dow
						l_last := l_start_dow + l_days - 1
					end
					from
						p := l_first
					until
						p > l_last
					loop
						l_grid_row := l_cur_row + p // 7
						if l_grid_row < l_bottom then
							d := p - l_start_dow + 1
							if d < 1 then
								d := d + l_prev_days
								l_cell_style := style.patch (surrounding_or_default)
							elseif d > l_days then
								d := d - l_days
								l_cell_style := style.patch (surrounding_or_default)
							else
								if d = a_state.selected_day then
									l_cell_style := style.patch (selected_style)
								else
									l_cell_style := style
								end
								if attached custom_date_style (a_state.year, a_state.month, d) as cds then
									l_cell_style := l_cell_style.patch (cds)
								end
							end
							if d < 10 then
								create l_day_str.make_from_string (" ")
								l_day_str.append_string (d.out)
							else
								create l_day_str.make_from_string (d.out)
							end
							l_day_x := l_col_offset + ((p \\ 7) * 3)
							a_buffer.set_string_clipped (l_grid_row, l_day_x, l_day_str, l_left, l_right, l_cell_style)
						end
						p := p + 1
					end
				end
			end
		end

invariant
	style_not_void: style /= Void
	header_style_not_void: header_style /= Void
	weekday_style_not_void: weekday_style /= Void
	selected_style_not_void: selected_style /= Void
	valid_first_day: first_day_of_week >= 1 and first_day_of_week <= 7

end
