note
	description: "[
		Inline data trend chart widget (Ratatui `Sparkline`): one bar per data point, over one or
		more rows.

		Data: a list of SPARKLINE_BAR (`bars`). `set_data`, `make_with_data` and `append_value`
		take plain NATURAL_64 values; `set_bars`, `append_bar` and `append_absent` also give
		absent bars and bars with a style of their own. An absent bar is not a bar of value 0:
		its column gets `absent_value_symbol` in every row, in `style` patched with
		`absent_value_style`. The automatic maximum (`max_value` = 0) ignores absent bars.

		Marker (`marker`, a {CANVAS_MARKER} constant; Ratatui `Sparkline::marker`):
		- `bar` (default): the nine-level bar set (' ', U+2581 .. U+2587, U+2588), 8 levels per row.
		  (In TUI_CANVAS the Bar marker is a line symbol; in a sparkline it is the bar set, as in
		  Ratatui.)
		- `half_block`: ' ', U+2584 (lower half), U+2588; 2 levels per row.
		- `block`, `dot`, `custom`: U+2588, U+2022 or `custom_marker_char` when the row has a
		  level, else ' '; 1 level per row.
		- `braille`, `quadrant`, `sextant`, `octant`: two data points per column, one per
		  sub-column, drawn on a one-cell BRAILLE_CANVAS grid of that marker (4, 2, 3, 4 levels
		  per row). When both points of a column are present, the right-hand one's style is
		  used; an absent point is an empty sub-column; when both are absent, the column gets
		  the absent symbol and style. Right to left, the right sub-column holds the earlier
		  point. Braille draws U+2800 in an empty cell of a drawn column, the pattern markers a
		  space.

		Styles of a present bar's cells: `style` patched with the bar's own style, and for the
		cells that show part of the bar also with `bar_style` in between
		(`style` <- `bar_style` <- bar style). With the default `bar_style` this is Ratatui's
		`style.patch (bar.style)`. Each style is patched over the cell's style in the buffer,
		as Ratatui's `Cell::set_style` does. Columns without a data point are not touched.

		Direction: {SPARKLINE_DIRECTION}; right to left puts the first point in the rightmost
		column.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_SPARKLINE

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
			-- Initialize as an empty sparkline.
		do
			create bars.make (16)
			max_value := 0
			direction := {SPARKLINE_DIRECTION}.Left_to_right
			create style.default_create
			create bar_style.default_create
			create absent_value_style.default_create
			absent_value_symbol := ' '
			marker := {CANVAS_MARKER}.bar
			custom_marker_char := {CANVAS_MARKER}.default_custom_char
		ensure then
			data_empty: bars.is_empty
			auto_max: max_value = 0
			direction_ltr: not is_right_to_left
			no_block: block = Void
			blank_absent_symbol: absent_value_symbol = ' '
			bar_marker: marker = {CANVAS_MARKER}.bar
		end

	make
			-- Synonym for `default_create`.
		do
			default_create
		end

	make_with_data (a_data: ITERABLE [NATURAL_64])
			-- Initialize with `a_data`.
		require
			data_not_void: a_data /= Void
		do
			default_create
			set_data (a_data)
		end

feature -- Duplication

	copy (a_other: like Current)
			-- Re-create the bars on copy, so the copy's bars are its own.
		do
			if a_other /= Current then
				standard_copy (a_other)
				create bars.make (a_other.bars.count.max (1))
				across
					a_other.bars as b
				loop
					bars.extend (b.twin)
				end
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
			elseif max_value = a_other.max_value
				and direction = a_other.direction
				and marker = a_other.marker
				and custom_marker_char = a_other.custom_marker_char
				and absent_value_symbol = a_other.absent_value_symbol
				and same_block (a_other)
				and style.is_equal (a_other.style)
				and bar_style.is_equal (a_other.bar_style)
				and absent_value_style.is_equal (a_other.absent_value_style)
				and bars.count = a_other.bars.count
			then
				Result := True
				from
					i := 1
				until
					i > bars.count or not Result
				loop
					Result := bars [i].is_equal (a_other.bars [i])
					i := i + 1
				end
			end
		end

feature -- Access

	bars: ARRAYED_LIST [SPARKLINE_BAR]
			-- Data points, in order (Ratatui `data`)

	values: ARRAYED_LIST [NATURAL_64]
			-- Values of `bars`, 0 for an absent bar (a new list; changing it does not change the sparkline)
		do
			create Result.make (bars.count)
			across
				bars as b
			loop
				Result.extend (b.value)
			end
		ensure
			same_count: Result.count = bars.count
		end

	data: ARRAYED_LIST [NATURAL_64]
		obsolete "Use `values` (a copy) or `bars`. Since V9 this list is a copy: extending or changing it no longer changes the sparkline; use `append_value`, `set_data` or `set_bars`. [2026-10-23]"
			-- Values of `bars`, 0 for an absent bar (a new list, as `values`)
		do
			Result := values
		ensure
			same_count: Result.count = bars.count
		end

	max_value: NATURAL_64
			-- Explicit maximum value for scale calculation (0 = the largest present value)

	direction: INTEGER
			-- Render direction ({SPARKLINE_DIRECTION}.Left_to_right or Right_to_left)

	is_right_to_left: BOOLEAN
			-- Render sparkline from right to left?
		do
			Result := direction = {SPARKLINE_DIRECTION}.Right_to_left
		end

	style: STYLE
			-- Base style, for every cell of a drawn column

	bar_style: STYLE
			-- Style patched over `style` in the cells that show part of a bar

	absent_value_style: STYLE
			-- Style patched over `style` in the column of an absent bar

	absent_value_symbol: CHARACTER_32
			-- Symbol in every row of an absent bar's column (Ratatui `symbols::shade::EMPTY`, a space, by default)

	marker: NATURAL_8
			-- Marker the bars are drawn with ({CANVAS_MARKER}; `bar` is the nine-level bar set)

	custom_marker_char: CHARACTER_32
			-- Character of the Custom marker. One column wide.

	effective_max: NATURAL_64
			-- Value of a full-height bar: `max_value`, or the largest present value when it is 0
		do
			if max_value > 0 then
				Result := max_value
			else
				across
					bars as b
				loop
					if not b.is_absent and b.value > Result then
						Result := b.value
					end
				end
			end
		ensure
			explicit: max_value > 0 implies Result = max_value
		end

feature -- Status report

	is_valid_absent_symbol (a_char: CHARACTER_32): BOOLEAN
			-- Can `a_char` be `absent_value_symbol`: one column wide?
		do
			Result := {UNICODE_WIDTH}.width (a_char.natural_32_code) = 1
		ensure
			instance_free: class
		end

	is_double_width_marker (a_marker: NATURAL_8): BOOLEAN
			-- Does `a_marker` put two data points in each column (Braille, Quadrant, Sextant, Octant)?
		do
			Result := a_marker = {CANVAS_MARKER}.braille or {CANVAS_MARKER}.is_pattern (a_marker)
		ensure
			instance_free: class
		end

feature -- Element change

	set_data (a_data: ITERABLE [NATURAL_64])
			-- Replace dataset with present bars of the values `a_data`.
		require
			data_not_void: a_data /= Void
		do
			bars.wipe_out
			across
				a_data as d
			loop
				bars.extend (create {SPARKLINE_BAR}.make (d))
			end
		end

	set_bars (a_bars: ITERABLE [SPARKLINE_BAR])
			-- Replace dataset with copies of `a_bars` (Ratatui `data` with SparklineBar items).
		require
			bars_not_void: a_bars /= Void
		do
			bars.wipe_out
			across
				a_bars as b
			loop
				bars.extend (b.twin)
			end
		end

	append_value (a_val: NATURAL_64)
			-- Add a single point `a_val` to dataset.
		do
			bars.extend (create {SPARKLINE_BAR}.make (a_val))
		ensure
			value_added: bars.count = old bars.count + 1
			last_value: bars.last.value = a_val and not bars.last.is_absent
		end

	append_absent
			-- Add an absent point to dataset.
		do
			bars.extend (create {SPARKLINE_BAR}.make_absent)
		ensure
			bar_added: bars.count = old bars.count + 1
			last_absent: bars.last.is_absent
		end

	append_bar (a_bar: SPARKLINE_BAR)
			-- Add a copy of `a_bar` to dataset.
		require
			bar_not_void: a_bar /= Void
		do
			bars.extend (a_bar.twin)
		ensure
			bar_added: bars.count = old bars.count + 1
			last_bar: bars.last.is_equal (a_bar)
		end

	set_max_value (a_max: NATURAL_64)
			-- Set explicit scaling maximum.
		do
			max_value := a_max
		ensure
			max_value_set: max_value = a_max
		end

	set_direction (a_direction: INTEGER)
			-- Set render direction.
		require
			valid_direction: {SPARKLINE_DIRECTION}.is_valid (a_direction)
		do
			direction := a_direction
		ensure
			direction_set: direction = a_direction
		end

	set_right_to_left (a_rtl: BOOLEAN)
			-- Set render direction.
		do
			if a_rtl then
				direction := {SPARKLINE_DIRECTION}.Right_to_left
			else
				direction := {SPARKLINE_DIRECTION}.Left_to_right
			end
		ensure
			direction_set: is_right_to_left = a_rtl
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
			-- Set bar style.
		require
			style_not_void: a_style /= Void
		do
			bar_style := a_style
		ensure
			bar_style_set: bar_style = a_style
		end

	set_absent_value_style (a_style: STYLE)
			-- Set the style of absent bars (Ratatui `absent_value_style`).
		require
			style_not_void: a_style /= Void
		do
			absent_value_style := a_style
		ensure
			absent_value_style_set: absent_value_style = a_style
		end

	set_absent_value_symbol (a_char: CHARACTER_32)
			-- Set the symbol of absent bars (Ratatui `absent_value_symbol`).
		require
			one_column: is_valid_absent_symbol (a_char)
		do
			absent_value_symbol := a_char
		ensure
			absent_value_symbol_set: absent_value_symbol = a_char
		end

	set_marker (a_marker: NATURAL_8)
			-- Set the marker ({CANVAS_MARKER}.bar, half_block, block, dot, custom, braille,
			-- quadrant, sextant, octant). Custom keeps `custom_marker_char`.
		require
			valid_marker: {CANVAS_MARKER}.is_valid (a_marker)
		do
			marker := a_marker
		ensure
			marker_set: marker = a_marker
		end

	set_custom_marker (a_char: CHARACTER_32)
			-- Draw with the Custom marker, `a_char` in every cell with a level (Ratatui `Marker::Custom`).
		require
			one_column: {CANVAS_MARKER}.is_valid_custom_char (a_char)
		do
			marker := {CANVAS_MARKER}.custom
			custom_marker_char := a_char
		ensure
			custom_marker: marker = {CANVAS_MARKER}.custom
			char_set: custom_marker_char = a_char
		end

feature -- Fluent Builders

	with_data (a_data: ITERABLE [NATURAL_64]): like Current
			-- Sparkline with `a_data`.
		require
			data_not_void: a_data /= Void
		do
			Result := twin
			Result.set_data (a_data)
		end

	with_bars (a_bars: ITERABLE [SPARKLINE_BAR]): like Current
			-- Sparkline with copies of `a_bars`.
		require
			bars_not_void: a_bars /= Void
		do
			Result := twin
			Result.set_bars (a_bars)
		end

	with_max_value (a_max: NATURAL_64): like Current
			-- Sparkline with explicit `a_max`.
		do
			Result := twin
			Result.set_max_value (a_max)
		ensure
			max_value_set: Result.max_value = a_max
		end

	with_direction (a_direction: INTEGER): like Current
			-- Sparkline with render direction.
		require
			valid_direction: {SPARKLINE_DIRECTION}.is_valid (a_direction)
		do
			Result := twin
			Result.set_direction (a_direction)
		ensure
			direction_set: Result.direction = a_direction
		end

	with_style (a_style: STYLE): like Current
			-- Sparkline with base `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_style (a_style)
		ensure
			style_set: Result.style = a_style
		end

	with_bar_style (a_style: STYLE): like Current
			-- Sparkline with `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_bar_style (a_style)
		ensure
			bar_style_set: Result.bar_style = a_style
		end

	with_absent_value_style (a_style: STYLE): like Current
			-- Sparkline with absent bars in `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_absent_value_style (a_style)
		ensure
			absent_value_style_set: Result.absent_value_style = a_style
		end

	with_absent_value_symbol (a_char: CHARACTER_32): like Current
			-- Sparkline with absent bars drawn as `a_char`.
		require
			one_column: is_valid_absent_symbol (a_char)
		do
			Result := twin
			Result.set_absent_value_symbol (a_char)
		ensure
			absent_value_symbol_set: Result.absent_value_symbol = a_char
		end

	with_marker (a_marker: NATURAL_8): like Current
			-- Sparkline drawn with `a_marker`.
		require
			valid_marker: {CANVAS_MARKER}.is_valid (a_marker)
		do
			Result := twin
			Result.set_marker (a_marker)
		ensure
			marker_set: Result.marker = a_marker
		end

	with_custom_marker (a_char: CHARACTER_32): like Current
			-- Sparkline drawn with the Custom marker `a_char`.
		require
			one_column: {CANVAS_MARKER}.is_valid_custom_char (a_char)
		do
			Result := twin
			Result.set_custom_marker (a_char)
		ensure
			custom_marker: Result.marker = {CANVAS_MARKER}.custom
			char_set: Result.custom_marker_char = a_char
		end

feature -- Rendering

	render (a_area: RECT; a_buffer: BUFFER)
			-- Render sparkline into `a_buffer` within `a_area`.
		local
			l_target: RECT
		do
			if not a_area.is_empty then
				render_block (a_area, a_buffer)
				l_target := inner_area (a_area)
				if not l_target.is_empty then
					if is_double_width_marker (marker) then
						render_double_width (l_target, a_buffer)
					else
						render_single_width (l_target, a_buffer)
					end
				end
			end
		ensure then
			consistent: a_buffer.is_consistent
		end

feature -- Scaling

	scaled_ticks (a_value, a_max, a_max_ticks: NATURAL_64): NATURAL_64
			-- `a_value` * `a_max_ticks` // `a_max`, at most `a_max_ticks`; 0 when `a_max` is 0
			-- (Ratatui `scale_height`). Exact for every NATURAL_64: the product is not formed when
			-- it would overflow.
		local
			i: INTEGER
			q, r: NATURAL_64
		do
			if a_max = 0 then
				Result := 0
			elseif a_value >= a_max then
				Result := a_max_ticks
			elseif a_max_ticks = 0 or else a_value <= {NATURAL_64}.max_value // a_max_ticks then
				Result := (a_value * a_max_ticks) // a_max
			else
					-- Long multiplication modulo `a_max`: after each step,
					-- `a_value` * (the bits of `a_max_ticks` so far) = q * `a_max` + r, with r < `a_max`.
				from
					i := 63
				until
					i < 0
				loop
					q := q + q
					if r >= a_max - r then
						r := r - (a_max - r)
						q := q + 1
					else
						r := r + r
					end
					if a_max_ticks.bit_test (i) then
						if r >= a_max - a_value then
							r := r - (a_max - a_value)
							q := q + 1
						else
							r := r + a_value
						end
					end
					i := i - 1
				end
				Result := q
			end
		ensure
			instance_free: class
			bounded: Result <= a_max_ticks
			zero_max: a_max = 0 implies Result = 0
			full: (a_max > 0 and a_value >= a_max) implies Result = a_max_ticks
		end

	cell_ticks (a_total_ticks: NATURAL_64; a_row_from_bottom, a_sub_rows: INTEGER): INTEGER
			-- Levels of a bar of `a_total_ticks` in row `a_row_from_bottom` (0 is the bottom row)
			-- of `a_sub_rows` levels each (Ratatui `cell_ticks`).
		require
			row_non_negative: a_row_from_bottom >= 0
			positive_sub_rows: a_sub_rows > 0
		local
			l_base: NATURAL_64
		do
			l_base := a_row_from_bottom.to_natural_64 * a_sub_rows.to_natural_64
			if a_total_ticks >= l_base + a_sub_rows.to_natural_64 then
				Result := a_sub_rows
			elseif a_total_ticks > l_base then
				Result := (a_total_ticks - l_base).to_integer_32
			end
		ensure
			instance_free: class
			in_range: Result >= 0 and Result <= a_sub_rows
		end

	sub_rows (a_marker: NATURAL_8): INTEGER
			-- Levels per row for `a_marker`: 8 for the bar set, else the dots per cell vertically.
		require
			valid_marker: {CANVAS_MARKER}.is_valid (a_marker)
		do
			if a_marker = {CANVAS_MARKER}.bar then
				Result := 8
			else
				Result := {CANVAS_MARKER}.dots_y (a_marker)
			end
		ensure
			instance_free: class
			positive: Result > 0
		end

feature {NONE} -- Rendering implementation

	render_single_width (a_target: RECT; a_buffer: BUFFER)
			-- One bar per column of `a_target` (Ratatui `render_single_width`).
		require
			not_empty: not a_target.is_empty
		local
			i, j, x, y, l_count, l_sub, l_height, l_ticks: INTEGER
			l_max, l_total: NATURAL_64
			l_bar: SPARKLINE_BAR
			l_filled, l_empty: STYLE
			l_cache: like new_cache
		do
			l_cache := new_cache
			l_max := effective_max
			l_sub := sub_rows (marker)
			l_height := a_target.height.to_integer_32
			l_count := bars.count.min (a_target.width.to_integer_32)
			from
				i := 0
			until
				i >= l_count
			loop
				if is_right_to_left then
					x := a_target.right.to_integer_32 - 1 - i
				else
					x := a_target.left.to_integer_32 + i
				end
				if x < a_buffer.width then
					l_bar := bars [i + 1]
					if l_bar.is_absent then
						render_absent_column (x, a_target, a_buffer, l_cache)
					else
						l_total := scaled_ticks (l_bar.value, l_max, l_height.to_natural_64 * l_sub.to_natural_64)
						l_empty := bar_cell_style (l_bar, False)
						l_filled := bar_cell_style (l_bar, True)
						from
							j := 0
						until
							j >= l_height
						loop
							y := a_target.bottom.to_integer_32 - 1 - j
							if y < a_buffer.height then
								l_ticks := cell_ticks (l_total, j, l_sub)
								if l_ticks > 0 then
									put_patched (a_buffer, y, x, single_width_symbol (l_ticks), l_filled, l_cache)
								else
									put_patched (a_buffer, y, x, single_width_symbol (0), l_empty, l_cache)
								end
							end
							j := j + 1
						end
					end
				end
				i := i + 1
			end
		end

	render_double_width (a_target: RECT; a_buffer: BUFFER)
			-- Two bars per column of `a_target`, on a one-cell grid of `marker` (Ratatui `render_double_width`).
		require
			not_empty: not a_target.is_empty
			double_width: is_double_width_marker (marker)
		local
			l_col, j, x, y, l_dist, l_left_index, l_right_index, l_sub, l_height, l_width: INTEGER
			l_max, l_max_ticks, l_ticks_left, l_ticks_right: NATURAL_64
			l_left, l_right, l_owner: detachable SPARKLINE_BAR
			l_filled, l_empty: STYLE
			l_grid: BRAILLE_CANVAS
			l_mask: NATURAL_8
			l_cache: like new_cache
		do
			l_cache := new_cache
			l_max := effective_max
			l_sub := sub_rows (marker)
			l_height := a_target.height.to_integer_32
			l_width := a_target.width.to_integer_32
			l_max_ticks := l_height.to_natural_64 * l_sub.to_natural_64
			if marker = {CANVAS_MARKER}.braille then
				create l_grid.make (1, 1)
			else
				create l_grid.make_with_pattern (1, 1, {CANVAS_MARKER}.dots_x (marker), {CANVAS_MARKER}.dots_y (marker))
			end
			from
				l_col := 0
			until
				l_col >= l_width
			loop
				x := a_target.left.to_integer_32 + l_col
				if x < a_buffer.width then
						-- 1-based indexes of the left and right points; right to left, the right
						-- sub-column holds the earlier point.
					if is_right_to_left then
						l_dist := l_width - 1 - l_col
						l_left_index := 2 * l_dist + 2
						l_right_index := 2 * l_dist + 1
					else
						l_left_index := 2 * l_col + 1
						l_right_index := 2 * l_col + 2
					end
					l_left := bar_at (l_left_index)
					l_right := bar_at (l_right_index)
					if l_right /= Void and then not l_right.is_absent then
						l_owner := l_right
					elseif l_left /= Void and then not l_left.is_absent then
						l_owner := l_left
					else
						l_owner := Void
					end
					if l_owner /= Void then
						l_ticks_left := present_ticks (l_left, l_max, l_max_ticks)
						l_ticks_right := present_ticks (l_right, l_max, l_max_ticks)
						l_empty := bar_cell_style (l_owner, False)
						l_filled := bar_cell_style (l_owner, True)
						from
							j := 0
						until
							j >= l_height
						loop
							y := a_target.bottom.to_integer_32 - 1 - j
							if y < a_buffer.height then
								fill_grid_cell (l_grid, cell_ticks (l_ticks_left, j, l_sub), cell_ticks (l_ticks_right, j, l_sub))
								l_mask := l_grid.cell_mask (0, 0)
								if l_mask /= 0 then
									put_patched (a_buffer, y, x, grid_glyph (l_grid), l_filled, l_cache)
								else
									put_patched (a_buffer, y, x, grid_glyph (l_grid), l_empty, l_cache)
								end
							end
							j := j + 1
						end
					elseif l_left /= Void or l_right /= Void then
						render_absent_column (x, a_target, a_buffer, l_cache)
					end
				end
				l_col := l_col + 1
			end
		end

	render_absent_column (a_x: INTEGER; a_target: RECT; a_buffer: BUFFER; a_cache: like new_cache)
			-- `absent_value_symbol` in every row of column `a_x` of `a_target`, in `style` patched
			-- with `absent_value_style` (Ratatui `render_absent_column`).
		require
			valid_column: a_x >= 0 and a_x < a_buffer.width
		local
			y, l_bottom: INTEGER
			l_style: STYLE
		do
			l_style := style.patch (absent_value_style)
			l_bottom := a_target.bottom.to_integer_32.min (a_buffer.height)
			from
				y := a_target.top.to_integer_32
			until
				y >= l_bottom
			loop
				put_patched (a_buffer, y, a_x, absent_value_symbol, l_style, a_cache)
				y := y + 1
			end
		end

	bar_at (a_index: INTEGER): detachable SPARKLINE_BAR
			-- Bar number `a_index` (1-based), or Void past the data
		do
			if a_index >= 1 and a_index <= bars.count then
				Result := bars [a_index]
			end
		end

	present_ticks (a_bar: detachable SPARKLINE_BAR; a_max, a_max_ticks: NATURAL_64): NATURAL_64
			-- Levels of `a_bar`; 0 for a missing or absent bar (an empty sub-column)
		do
			if a_bar /= Void and then not a_bar.is_absent then
				Result := scaled_ticks (a_bar.value, a_max, a_max_ticks)
			end
		end

	bar_cell_style (a_bar: SPARKLINE_BAR; a_filled: BOOLEAN): STYLE
			-- Style of a cell of `a_bar`'s column: `style`, then `bar_style` when the cell shows
			-- part of the bar (`a_filled`), then the bar's own style
		do
			if a_filled then
				Result := style.patch (bar_style)
			else
				Result := style
			end
			if attached a_bar.style as s then
				Result := Result.patch (s)
			end
		end

	single_width_symbol (a_ticks: INTEGER): CHARACTER_32
			-- Symbol of a cell with `a_ticks` levels for the single-width `marker` (Ratatui `set_single_width_cell`)
		require
			valid_ticks: a_ticks >= 0 and a_ticks <= sub_rows (marker)
		do
			if a_ticks = 0 then
				Result := ' '
			else
				if marker = {CANVAS_MARKER}.half_block then
					if a_ticks = 1 then
						Result := (0x2584).to_character_32 -- '▄' lower half
					else
						Result := (0x2588).to_character_32 -- '█'
					end
				elseif marker = {CANVAS_MARKER}.block then
					Result := (0x2588).to_character_32 -- '█'
				elseif marker = {CANVAS_MARKER}.dot then
					Result := (0x2022).to_character_32 -- '•'
				elseif marker = {CANVAS_MARKER}.custom then
					Result := custom_marker_char
				else
						-- Nine-level bar set: U+2581 .. U+2587, then U+2588 for a full row
					Result := (0x2580 + a_ticks).to_character_32
				end
			end
		end

	fill_grid_cell (a_grid: BRAILLE_CANVAS; a_left, a_right: INTEGER)
			-- Set the bottom `a_left` dots of the left sub-column of `a_grid`'s only cell, and the
			-- bottom `a_right` dots of the right one; clear the others.
		require
			one_cell: a_grid.cols = 1 and a_grid.rows = 1
			two_sub_columns: a_grid.dots_x = 2
			valid_left: a_left >= 0 and a_left <= a_grid.dots_y
			valid_right: a_right >= 0 and a_right <= a_grid.dots_y
		local
			l_sy: INTEGER
		do
			from
				l_sy := 0
			until
				l_sy >= a_grid.dots_y
			loop
				if a_grid.dots_y - 1 - l_sy < a_left then
					a_grid.set_pixel (0, l_sy)
				else
					a_grid.reset_pixel (0, l_sy)
				end
				if a_grid.dots_y - 1 - l_sy < a_right then
					a_grid.set_pixel (1, l_sy)
				else
					a_grid.reset_pixel (1, l_sy)
				end
				l_sy := l_sy + 1
			end
		end

	grid_glyph (a_grid: BRAILLE_CANVAS): CHARACTER_32
			-- Character of `a_grid`'s only cell for `marker`: U+2800 + dots for Braille (also
			-- when empty), SYMBOLS_PIXEL for the pattern markers
		require
			one_cell: a_grid.cols = 1 and a_grid.rows = 1
		local
			l_mask: INTEGER
		do
			l_mask := a_grid.cell_mask (0, 0).to_integer_32
			if marker = {CANVAS_MARKER}.quadrant then
				Result := {SYMBOLS_PIXEL}.quadrant (l_mask)
			elseif marker = {CANVAS_MARKER}.sextant then
				Result := {SYMBOLS_PIXEL}.sextant (l_mask)
			elseif marker = {CANVAS_MARKER}.octant then
				Result := {SYMBOLS_PIXEL}.octant (l_mask)
			else
				if l_mask = 0 then
					Result := {CANVAS_MARKER}.blank_braille
				else
					Result := a_grid.cell_char (0, 0)
				end
			end
		end

	new_cache: TUPLE [base, overlay, patched: detachable STYLE]
			-- Empty cache for `put_patched`
		do
			create Result
		end

	put_patched (a_buffer: BUFFER; a_row, a_col: INTEGER; a_char: CHARACTER_32; a_style: STYLE; a_cache: like new_cache)
			-- Put `a_char` at (`a_row`, `a_col`) with `a_style` patched over the cell's style
			-- (Ratatui `set_symbol` then `set_style`). `a_cache` keeps the last patch, so cells
			-- that share one style object are patched once.
		require
			valid_row: a_row >= 0 and a_row < a_buffer.height
			valid_col: a_col >= 0 and a_col < a_buffer.width
		local
			l_base, l_result: STYLE
		do
			l_base := a_buffer.cell (a_row, a_col).style
			if a_cache.base = l_base and a_cache.overlay = a_style and then attached a_cache.patched as r then
				l_result := r
			else
				l_result := l_base.patch (a_style)
				a_cache.base := l_base
				a_cache.overlay := a_style
				a_cache.patched := l_result
			end
			a_buffer.put_char (a_row, a_col, a_char, l_result)
		end

invariant
	bars_not_void: bars /= Void
	style_not_void: style /= Void
	bar_style_not_void: bar_style /= Void
	absent_value_style_not_void: absent_value_style /= Void
	valid_direction: {SPARKLINE_DIRECTION}.is_valid (direction)
	valid_marker: {CANVAS_MARKER}.is_valid (marker)
	one_column_absent_symbol: is_valid_absent_symbol (absent_value_symbol)
	one_column_custom_char: {CANVAS_MARKER}.is_valid_custom_char (custom_marker_char)

end
