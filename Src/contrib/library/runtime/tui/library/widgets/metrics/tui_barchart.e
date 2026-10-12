note
	description: "[
		Vertical bar chart widget displaying bars with values and category labels,
		custom bar widths, gaps, and independent styling for bars, values, and labels.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_BARCHART

inherit
	WIDGET
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
	make,
	make_with_data

feature {NONE} -- Initialization

	default_create
			-- Initialize as an empty bar chart with standard 3-cell bar width and 1-cell gap.
		do
			create groups.make (2)
			bar_width := 3
			bar_gap := 1
			group_gap := 2
			direction := {BAR_CHART_DIRECTION}.vertical
			max_value := 0
			create style.default_create
			create bar_style.default_create
			create value_style.default_create
			value_style := value_style.with_bold
			create label_style.default_create
		ensure then
			bars_empty: bars.is_empty
			groups_empty: groups.is_empty
			bar_width_default: bar_width = 3
			bar_gap_default: bar_gap = 1
			group_gap_default: group_gap = 2
			direction_vertical: direction = {BAR_CHART_DIRECTION}.vertical
			max_auto: max_value = 0
			no_block: block = Void
		end

	make
			-- Synonym for `default_create`.
		do
			default_create
		end

	make_with_data (a_bars: ITERABLE [BAR_ITEM])
			-- Initialize chart with `a_bars`.
		require
			bars_not_void: a_bars /= Void
		do
			default_create
			set_bars (a_bars)
		end

feature -- Duplication

	copy (a_other: like Current)
			-- Re-create bar groups on copy.
		local
			l_groups: ARRAYED_LIST [BAR_GROUP]
		do
			if a_other /= Current then
				standard_copy (a_other)
				create l_groups.make (a_other.groups.count)
				across a_other.groups as g loop
					l_groups.extend (g.twin)
				end
				groups := l_groups
			end
		end

	is_equal (a_other: like Current): BOOLEAN
			-- Is `a_other` content-equal to `Current`?
		local
			i: INTEGER
		do
			if a_other = Current then
				Result := True
			elseif standard_is_equal (a_other) then
				Result := True
			elseif direction = a_other.direction
				and bar_width = a_other.bar_width
				and bar_gap = a_other.bar_gap
				and group_gap = a_other.group_gap
				and max_value = a_other.max_value
				and same_block (a_other)
				and style.is_equal (a_other.style)
				and bar_style.is_equal (a_other.bar_style)
				and value_style.is_equal (a_other.value_style)
				and label_style.is_equal (a_other.label_style)
				and groups.count = a_other.groups.count
			then
				Result := True
				from
					i := 1
				until
					i > groups.count or not Result
				loop
					Result := groups [i].is_equal (a_other.groups [i])
					i := i + 1
				end
			end
		end

feature -- Access

	groups: ARRAYED_LIST [BAR_GROUP]
			-- Bar groups displayed in the chart

	bars: ARRAYED_LIST [BAR_ITEM]
			-- All bars of all groups, in order (a fresh list; the groups are the only storage)
		do
			create Result.make (8)
			across groups as g loop
				across g.bars as b loop
					Result.extend (b)
				end
			end
		end

	direction: NATURAL_8
			-- Bar chart orientation ({BAR_CHART_DIRECTION}.vertical or horizontal)

	bar_width: NATURAL_16
			-- Width of each individual bar in terminal character columns (or height in horizontal mode)

	bar_gap: NATURAL_16
			-- Spacing gap in columns between consecutive bars

	group_gap: NATURAL_16
			-- Spacing gap between consecutive bar groups

	max_value: NATURAL_64
			-- Explicit maximum value for scaling (0 = auto-compute from bars)

	style: STYLE
			-- Base style applied to unfilled chart area

	bar_style: STYLE
			-- Baseline style applied to bar columns

	value_style: STYLE
			-- Baseline style applied to printed values

	label_style: STYLE
			-- Baseline style applied to category labels

	count: INTEGER
			-- Number of bars in the chart
		do
			across groups as g loop
				Result := Result + g.bars.count
			end
		ensure
			correct_count: Result = bars.count
		end

feature -- Element change

	append_bar (a_bar: BAR_ITEM)
			-- Add `a_bar` to the last group (a new unlabelled group when there is none).
		require
			bar_not_void: a_bar /= Void
		do
			if groups.is_empty then
				groups.extend (create {BAR_GROUP}.make)
			end
			groups.last.append_bar (a_bar)
		ensure
			bar_added: count = old count + 1
			last_bar: bars.last = a_bar
		end

	append_group (a_group: BAR_GROUP)
			-- Add `a_group` to chart.
		require
			group_not_void: a_group /= Void
		do
			groups.extend (a_group)
		ensure
			group_added: groups.count = old groups.count + 1
			last_group: groups.last = a_group
		end

	set_groups (a_groups: ITERABLE [BAR_GROUP])
			-- Replace all groups with `a_groups`.
		require
			groups_not_void: a_groups /= Void
		do
			groups.wipe_out
			across
				a_groups as g
			loop
				groups.extend (g)
			end
		end

	set_direction (a_direction: NATURAL_8)
			-- Set bar chart orientation ({BAR_CHART_DIRECTION}.vertical or horizontal).
		require
			valid_direction: {BAR_CHART_DIRECTION}.is_valid (a_direction)
		do
			direction := a_direction
		ensure
			direction_set: direction = a_direction
		end

	set_group_gap (a_gap: NATURAL_16)
			-- Set spacing gap between bar groups.
		do
			group_gap := a_gap
		ensure
			group_gap_set: group_gap = a_gap
		end

	append_item (a_label: READABLE_STRING_GENERAL; a_value: NATURAL_64)
			-- Add a simple bar with `a_label` and `a_value`.
		require
			label_not_void: a_label /= Void
		local
			l_item: BAR_ITEM
		do
			create l_item.make (a_label, a_value)
			append_bar (l_item)
		ensure
			bar_added: bars.count = old bars.count + 1
		end

	set_bars (a_bars: ITERABLE [BAR_ITEM])
			-- Replace bars with `a_bars`.
		require
			bars_not_void: a_bars /= Void
		local
			l_grp: BAR_GROUP
		do
			groups.wipe_out
			create l_grp.make
			across
				a_bars as b
			loop
				l_grp.append_bar (b)
			end
			groups.extend (l_grp)
		end

	set_bar_width (a_width: NATURAL_16)
			-- Set width of each bar.
		require
			positive_width: a_width >= 1
		do
			bar_width := a_width
		ensure
			bar_width_set: bar_width = a_width
		end

	set_bar_gap (a_gap: NATURAL_16)
			-- Set gap between bars.
		do
			bar_gap := a_gap
		ensure
			bar_gap_set: bar_gap = a_gap
		end

	set_max_value (a_max: NATURAL_64)
			-- Set explicit vertical maximum.
		do
			max_value := a_max
		ensure
			max_value_set: max_value = a_max
		end

	set_style (a_style: STYLE)
			-- Set base style.
		require
			style_not_void: a_style /= Void
		do
			style := a_style
		ensure
			style_set: style = a_style
		end

	set_bar_style (a_style: STYLE)
			-- Set bar column style.
		require
			style_not_void: a_style /= Void
		do
			bar_style := a_style
		ensure
			bar_style_set: bar_style = a_style
		end

	set_value_style (a_style: STYLE)
			-- Set value text style.
		require
			style_not_void: a_style /= Void
		do
			value_style := a_style
		ensure
			value_style_set: value_style = a_style
		end

	set_label_style (a_style: STYLE)
			-- Set label text style.
		require
			style_not_void: a_style /= Void
		do
			label_style := a_style
		ensure
			label_style_set: label_style = a_style
		end

feature -- Fluent Builders

	with_bars (a_bars: ITERABLE [BAR_ITEM]): like Current
			-- Bar chart with `a_bars`.
		require
			bars_not_void: a_bars /= Void
		do
			Result := twin
			Result.set_bars (a_bars)
		end

	with_bar_width (a_width: NATURAL_16): like Current
			-- Bar chart with bar width `a_width`.
		require
			positive_width: a_width >= 1
		do
			Result := twin
			Result.set_bar_width (a_width)
		ensure
			bar_width_set: Result.bar_width = a_width
		end

	with_bar_gap (a_gap: NATURAL_16): like Current
			-- Bar chart with `a_gap` between bars.
		do
			Result := twin
			Result.set_bar_gap (a_gap)
		ensure
			bar_gap_set: Result.bar_gap = a_gap
		end

	with_max_value (a_max: NATURAL_64): like Current
			-- Bar chart with explicit `a_max`.
		do
			Result := twin
			Result.set_max_value (a_max)
		ensure
			max_value_set: Result.max_value = a_max
		end

	with_bar_style (a_style: STYLE): like Current
			-- Bar chart with `a_style` for bars.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_bar_style (a_style)
		ensure
			bar_style_set: Result.bar_style = a_style
		end

	with_direction (a_direction: NATURAL_8): like Current
			-- Bar chart with orientation `a_direction`.
		require
			valid_direction: {BAR_CHART_DIRECTION}.is_valid (a_direction)
		do
			Result := twin
			Result.set_direction (a_direction)
		ensure
			direction_set: Result.direction = a_direction
		end

	with_groups (a_groups: ITERABLE [BAR_GROUP]): like Current
			-- Bar chart with `a_groups`.
		require
			groups_not_void: a_groups /= Void
		do
			Result := twin
			Result.set_groups (a_groups)
		end

	with_group_gap (a_gap: NATURAL_16): like Current
			-- Bar chart with `a_gap` between groups.
		do
			Result := twin
			Result.set_group_gap (a_gap)
		ensure
			group_gap_set: Result.group_gap = a_gap
		end

	with_style (a_style: STYLE): like Current
			-- Bar chart with base `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_style (a_style)
		ensure
			style_set: Result.style = a_style
		end

	with_value_style (a_style: STYLE): like Current
			-- Bar chart with value text `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_value_style (a_style)
		ensure
			value_style_set: Result.value_style = a_style
		end

	with_label_style (a_style: STYLE): like Current
			-- Bar chart with label text `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_label_style (a_style)
		ensure
			label_style_set: Result.label_style = a_style
		end

feature -- Rendering

	render (a_area: RECT; a_buffer: BUFFER)
			-- Render bar chart inside `a_area` into `a_buffer`.
		local
			l_target: RECT
		do
			if not a_area.is_empty then
				render_block (a_area, a_buffer)
				l_target := inner_area (a_area)

				if not l_target.is_empty and l_target.width > 0 and l_target.height > 0 then
					if direction = {BAR_CHART_DIRECTION}.horizontal then
						render_horizontal (l_target, a_buffer)
					else
						render_vertical (l_target, a_buffer)
					end
				end
			end
		end

feature {NONE} -- Implementation: Vertical & Horizontal Rendering

	render_vertical (l_target: RECT; a_buffer: BUFFER)
			-- Vertical bars, grouped, with rows (bottom-up) for group labels, bar labels and values
			-- when there is content for them and room left for at least one bar row.
		local
			l_eff_max, l_total_sublevels, l_rem_sublevels: NATURAL_64
			l_rows, l_bottom, l_group_row, l_label_row, l_value_row, l_bars_bottom_row, l_bar_height: INTEGER
			l_curr_x, l_bw, l_group_start, l_group_end, l_right: INTEGER
			b_idx, w_idx, r, g_idx: INTEGER
			l_bar: BAR_ITEM
			l_char: CHARACTER_32
			l_b_style, l_v_style, l_l_style: STYLE
			l_val_str: STRING_32
			l_val_w, l_lbl_w: INTEGER
			l_group: BAR_GROUP
			l_want_labels, l_want_group_labels: BOOLEAN
		do
			l_eff_max := effective_max
			l_right := l_target.right.to_integer_32
			l_bw := bar_width.to_integer_32

			-- Reserve rows while at least one bar row remains: labels first, then values, then group labels
			l_rows := l_target.height.to_integer_32
			l_want_labels := has_bar_labels and l_rows >= 2
			if l_want_labels then
				l_rows := l_rows - 1
			end
			if l_rows >= 2 then
				l_value_row := 0
				l_rows := l_rows - 1
			else
				l_value_row := -1
			end
			l_want_group_labels := has_group_labels and l_rows >= 2
			if l_want_group_labels then
				l_rows := l_rows - 1
			end
			l_bar_height := l_rows

			l_bottom := l_target.bottom.to_integer_32 - 1
			l_group_row := -1
			l_label_row := -1
			if l_want_group_labels then
				l_group_row := l_bottom
				l_bottom := l_bottom - 1
			end
			if l_want_labels then
				l_label_row := l_bottom
				l_bottom := l_bottom - 1
			end
			if l_value_row = 0 then
				l_value_row := l_bottom
				l_bottom := l_bottom - 1
			end
			l_bars_bottom_row := l_bottom
			l_total_sublevels := (l_bar_height * 8).to_natural_64

			l_curr_x := l_target.x.to_integer_32
			from
				g_idx := 1
			until
				g_idx > groups.count or l_curr_x >= l_right
			loop
				l_group := groups.i_th (g_idx)
				l_group_start := l_curr_x
				l_group_end := l_curr_x
				from
					b_idx := 1
				until
					b_idx > l_group.bars.count or (l_curr_x + l_bw) > l_right
				loop
					l_bar := l_group.bars.i_th (b_idx)
					l_b_style := style.patch (bar_style).patch (l_bar.style)
					l_v_style := style.patch (value_style).patch (l_bar.value_style)
					l_l_style := style.patch (label_style).patch (l_bar.label_style)

					-- Bar column, with 1/8 remainders on its top cell
					l_rem_sublevels := ((l_bar.value.min (l_eff_max) * l_total_sublevels) // l_eff_max)
					from
						r := 0
					until
						r >= l_bar_height or l_rem_sublevels = 0
					loop
						if l_rem_sublevels >= 8 then
							l_char := (9608).to_character_32 -- '█'
							l_rem_sublevels := l_rem_sublevels - 8
						else
							l_char := (9600 + l_rem_sublevels.to_integer_32).to_character_32
							l_rem_sublevels := 0
						end
						if l_bars_bottom_row - r >= 0 and l_bars_bottom_row - r < a_buffer.height then
							from
								w_idx := 0
							until
								w_idx >= l_bw
							loop
								a_buffer.set_string_clipped (l_bars_bottom_row - r, l_curr_x + w_idx,
									{TERMINAL_CELL}.pooled_char (l_char.natural_32_code), l_curr_x, (l_curr_x + l_bw).min (l_right), l_b_style)
								w_idx := w_idx + 1
							end
						end
						r := r + 1
					end

					-- Value, centred, only when it fits the bar width (hidden otherwise, as in Ratatui)
					if l_value_row >= 0 and l_value_row < a_buffer.height then
						l_val_str := value_text (l_bar)
						l_val_w := {UNICODE_WIDTH}.string_width (l_val_str).to_integer_32
						if l_val_w <= l_bw then
							a_buffer.set_string_clipped (l_value_row, l_curr_x + (l_bw - l_val_w) // 2, l_val_str,
								l_curr_x, (l_curr_x + l_bw).min (l_right), l_v_style)
						end
					end

					-- Label, centred and clipped to the bar width
					if l_label_row >= 0 and l_label_row < a_buffer.height then
						l_lbl_w := {UNICODE_WIDTH}.string_width (l_bar.label).to_integer_32
						a_buffer.set_string_clipped (l_label_row, l_curr_x + ((l_bw - l_lbl_w) // 2).max (0), l_bar.label,
							l_curr_x, (l_curr_x + l_bw).min (l_right), l_l_style)
					end

					l_group_end := l_curr_x + l_bw
					l_curr_x := l_curr_x + l_bw + bar_gap.to_integer_32
					b_idx := b_idx + 1
				end

				-- Group label, centred under the group's bars and clipped to them
				if l_group_row >= 0 and l_group_row < a_buffer.height and attached l_group.label as gl and then l_group_end > l_group_start then
					l_lbl_w := {UNICODE_WIDTH}.string_width (gl).to_integer_32
					a_buffer.set_string_clipped (l_group_row, l_group_start + ((l_group_end - l_group_start - l_lbl_w) // 2).max (0), gl,
						l_group_start, l_group_end.min (l_right), style.patch (label_style))
				end

				-- Between groups the group gap replaces the bar gap
				l_curr_x := l_group_end + group_gap.to_integer_32
				g_idx := g_idx + 1
			end
		end

	render_horizontal (l_target: RECT; a_buffer: BUFFER)
			-- Horizontal bars extending left-to-right, grouped (a group label takes its own row
			-- above the group's bars; `group_gap` rows separate groups).
		local
			l_eff_max: NATURAL_64
			l_max_lbl_w, l_lbl_w, l_curr_y, l_bar_len, l_avail_w, l_bottom, l_left, l_right: INTEGER
			l_bar_start_x, l_label_end_x, l_val_w, b_idx, g_idx, w_idx, r: INTEGER
			l_bar: BAR_ITEM
			l_group: BAR_GROUP
			l_b_style, l_v_style, l_l_style: STYLE
			l_val_str: STRING_32
			l_bar_h: INTEGER
		do
			l_eff_max := effective_max
			l_left := l_target.x.to_integer_32
			l_right := l_target.right.to_integer_32
			l_bottom := l_target.bottom.to_integer_32.min (a_buffer.height)

			-- Label column: the widest bar label, at most half the width
			across bars as bi loop
				l_lbl_w := {UNICODE_WIDTH}.string_width (bi.label).to_integer_32
				if l_lbl_w > l_max_lbl_w then
					l_max_lbl_w := l_lbl_w
				end
			end
			l_max_lbl_w := l_max_lbl_w.min (l_target.width.to_integer_32 // 2)
			-- Labels, then a 1-column margin (only when there are labels), then the bars
			l_label_end_x := l_left + l_max_lbl_w
			if l_max_lbl_w > 0 then
				l_bar_start_x := l_label_end_x + 1
			else
				l_bar_start_x := l_label_end_x
			end
			l_avail_w := (l_right - l_bar_start_x).max (0)
			l_bar_h := bar_width.to_integer_32.max (1)

			l_curr_y := l_target.y.to_integer_32
			from
				g_idx := 1
			until
				g_idx > groups.count or l_curr_y >= l_bottom
			loop
				l_group := groups.i_th (g_idx)
				if attached l_group.label as gl and then not gl.is_empty then
					a_buffer.set_string_clipped (l_curr_y, l_left, gl, l_left, l_right, style.patch (label_style))
					l_curr_y := l_curr_y + 1
				end
				from
					b_idx := 1
				until
					b_idx > l_group.bars.count or l_curr_y >= l_bottom
				loop
					l_bar := l_group.bars.i_th (b_idx)
					l_b_style := style.patch (bar_style).patch (l_bar.style)
					l_v_style := style.patch (value_style).patch (l_bar.value_style)
					l_l_style := style.patch (label_style).patch (l_bar.label_style)
					l_bar_len := ((l_bar.value.min (l_eff_max) * l_avail_w.to_natural_64) // l_eff_max).to_integer_32

					from
						r := 0
					until
						r >= l_bar_h or (l_curr_y + r) >= l_bottom
					loop
						if r = 0 and l_max_lbl_w > 0 then
							a_buffer.set_string_clipped (l_curr_y, l_left, l_bar.label, l_left, l_label_end_x, l_l_style)
						end
						from
							w_idx := 0
						until
							w_idx >= l_bar_len
						loop
							a_buffer.set_string_clipped (l_curr_y + r, l_bar_start_x + w_idx, {TERMINAL_CELL}.pooled_char (9608),
								l_bar_start_x, l_right, l_b_style) -- '█'
							w_idx := w_idx + 1
						end
						-- Value on the first row: after the bar when it fits, otherwise over the start
						-- of the bar (Ratatui draws horizontal values inside the bar), clipped to the bar
						if r = 0 then
							l_val_str := value_text (l_bar)
							l_val_w := {UNICODE_WIDTH}.string_width (l_val_str).to_integer_32
							if l_bar_start_x + l_bar_len + 1 + l_val_w <= l_right then
								a_buffer.set_string_clipped (l_curr_y, l_bar_start_x + l_bar_len + 1, l_val_str,
									l_bar_start_x + l_bar_len + 1, l_right, l_v_style)
							elseif l_bar_len > 0 then
								a_buffer.set_string_clipped (l_curr_y, l_bar_start_x, l_val_str,
									l_bar_start_x, l_bar_start_x + l_bar_len, l_b_style.patch (l_v_style).with_reverse)
							end
						end
						r := r + 1
					end

					l_curr_y := l_curr_y + l_bar_h
					if b_idx < l_group.bars.count then
						l_curr_y := l_curr_y + bar_gap.to_integer_32
					end
					b_idx := b_idx + 1
				end
				-- Between groups the group gap replaces the bar gap
				l_curr_y := l_curr_y + group_gap.to_integer_32
				g_idx := g_idx + 1
			end
		end

feature {NONE} -- Implementation

	effective_max: NATURAL_64
			-- `max_value` when set, otherwise the largest value over all groups (at least 1)
		do
			Result := max_value
			if Result = 0 then
				across groups as g loop
					across g.bars as b loop
						Result := Result.max (b.value)
					end
				end
				Result := Result.max (1)
			end
		ensure
			positive: Result >= 1
		end

	has_bar_labels: BOOLEAN
			-- Does some bar have a non-empty label?
		do
			Result := across groups as g some across g.bars as b some not b.label.is_empty end end
		end

	has_group_labels: BOOLEAN
			-- Does some group have a non-empty label?
		do
			Result := across groups as g some attached g.label as l and then not l.is_empty end
		end

	value_text (a_bar: BAR_ITEM): STRING_32
			-- Text shown as the value of `a_bar`
		do
			if attached a_bar.text_value as tv then
				Result := tv
			else
				Result := a_bar.value.out.to_string_32
			end
		end

invariant
	groups_not_void: groups /= Void
	positive_bar_width: bar_width >= 1
	valid_direction: {BAR_CHART_DIRECTION}.is_valid (direction)
	style_not_void: style /= Void
	bar_style_not_void: bar_style /= Void
	value_style_not_void: value_style /= Void
	label_style_not_void: label_style /= Void

end
