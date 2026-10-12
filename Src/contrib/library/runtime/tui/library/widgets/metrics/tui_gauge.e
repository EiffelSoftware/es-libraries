note
	description: "[
		Progress bar widget rendering horizontal progress from percentage or ratio,
		with customizable fill styles, centered labels, and optional Unicode fractional blocks.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_GAUGE

inherit
	WIDGET
		redefine
			default_create
		end
	BLOCK_CONTAINER
		redefine
			default_create
		end

create
	default_create,
	make

feature {NONE} -- Initialization

	default_create
			-- Initialize gauge with 0% progress and default styling.
		do
			ratio := 0.0
			use_unicode := False
			create style.default_create
			create gauge_style.default_create
			create label_style.default_create
			label_style := label_style.with_bold
		ensure then
			ratio_zero: ratio = 0.0
			no_unicode: not use_unicode
			no_block: block = Void
			no_custom_label: label = Void
		end

	make
			-- Synonym for `default_create`.
		do
			default_create
		end

feature -- Access

	ratio: REAL_64
			-- Progress ratio from 0.0 to 1.0

	percent: NATURAL_16
			-- Progress as percentage (0..100)
		do
			Result := (ratio * 100.0).rounded.to_natural_16
		ensure
			valid_percent: Result <= 100
		end

	label: detachable STRING_32
			-- Optional custom label displayed at center of gauge

	use_unicode: BOOLEAN
			-- Render sub-character block fractions using Unicode?

	style: STYLE
			-- Base style applied to unfilled portion of gauge

	gauge_style: STYLE
			-- Style applied to filled portion of gauge

	label_style: STYLE
			-- Style applied to centered label text

feature -- Element change

	set_ratio (a_ratio: REAL_64)
			-- Set progress ratio from 0.0 to 1.0.
		require
			valid_ratio: a_ratio >= 0.0 and a_ratio <= 1.0
		do
			ratio := a_ratio
		ensure
			ratio_set: ratio = a_ratio
		end

	set_percent (a_percent: NATURAL_16)
			-- Set progress from percentage `a_percent`.
		require
			valid_percent: a_percent <= 100
		do
			ratio := a_percent.to_integer_32.to_double / 100.0
		ensure
			percent_set: percent = a_percent
		end

	set_label (a_label: detachable READABLE_STRING_GENERAL)
			-- Set or clear centered label.
		do
			if attached a_label as l then
				create label.make_from_string_general (l)
			else
				label := Void
			end
		ensure
			label_set: attached a_label implies attached label
		end

	set_use_unicode (a_val: BOOLEAN)
			-- Toggle Unicode fractional block rendering.
		do
			use_unicode := a_val
		ensure
			unicode_set: use_unicode = a_val
		end

	set_style (a_style: STYLE)
			-- Set unfilled background style.
		require
			style_not_void: a_style /= Void
		do
			style := a_style
		ensure
			style_set: style = a_style
		end

	set_gauge_style (a_style: STYLE)
			-- Set filled progress style.
		require
			style_not_void: a_style /= Void
		do
			gauge_style := a_style
		ensure
			gauge_style_set: gauge_style = a_style
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

	with_ratio (a_ratio: REAL_64): like Current
			-- Gauge with progress `a_ratio`.
		require
			valid_ratio: a_ratio >= 0.0 and a_ratio <= 1.0
		do
			Result := twin
			Result.set_ratio (a_ratio)
		ensure
			ratio_set: Result.ratio = a_ratio
		end

	with_percent (a_percent: NATURAL_16): like Current
			-- Gauge with progress `a_percent`.
		require
			valid_percent: a_percent <= 100
		do
			Result := twin
			Result.set_percent (a_percent)
		ensure
			percent_set: Result.percent = a_percent
		end

	with_label (a_label: detachable READABLE_STRING_GENERAL): like Current
			-- Gauge with centered `a_label`.
		do
			Result := twin
			Result.set_label (a_label)
		end

	with_use_unicode (a_val: BOOLEAN): like Current
			-- Gauge with Unicode fractional blocks enabled.
		do
			Result := twin
			Result.set_use_unicode (a_val)
		ensure
			unicode_set: Result.use_unicode = a_val
		end

	with_style (a_style: STYLE): like Current
			-- Gauge with unfilled `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_style (a_style)
		ensure
			style_set: Result.style = a_style
		end

	with_gauge_style (a_style: STYLE): like Current
			-- Gauge with filled `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_gauge_style (a_style)
		ensure
			gauge_style_set: Result.gauge_style = a_style
		end

	with_label_style (a_style: STYLE): like Current
			-- Gauge with label `a_style`.
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
			-- Render progress bar within `a_area` into `a_buffer`.
		local
			l_target: RECT
			l_filled_f: REAL_64
			l_full_cells: INTEGER
			l_frac_code: INTEGER
			l_frac_char: CHARACTER_32
			r, c, l_col_abs: INTEGER
			l_lbl: STRING_32
			l_lbl_w, l_lbl_col, l_lbl_row: INTEGER
			l_filled_lbl_style: STYLE
			l_fill_end, l_filled_start, l_filled_stop: INTEGER
		do
			if not a_area.is_empty then
				render_block (a_area, a_buffer)
				l_target := inner_area (a_area)

				if not l_target.is_empty and l_target.width > 0 and l_target.height > 0 then
					l_filled_f := l_target.width.to_integer_32.to_double * ratio
					l_full_cells := l_filled_f.floor.to_integer_32

					if use_unicode and ratio < 1.0 then
						l_frac_code := unicode_block_code (l_filled_f - l_full_cells.to_double)
						l_frac_char := l_frac_code.to_character_32
					else
						l_frac_char := ' '
					end

					-- Fill cell background
					from
						r := l_target.y.to_integer_32
					until
						r >= l_target.bottom.to_integer_32 or r >= a_buffer.height
					loop
						from
							c := 0
						until
							c >= l_target.width.to_integer_32 or (l_target.x.to_integer_32 + c) >= a_buffer.width
						loop
							l_col_abs := l_target.x.to_integer_32 + c
							if c < l_full_cells then
								-- Full block U+2588
								a_buffer.put_char (r, l_col_abs, (9608).to_character_32, gauge_style)
							elseif c = l_full_cells and use_unicode and ratio < 1.0 and l_frac_char /= ' ' then
								a_buffer.put_char (r, l_col_abs, l_frac_char, gauge_style)
							else
								a_buffer.put_char (r, l_col_abs, ' ', style)
							end
							c := c + 1
						end
						r := r + 1
					end

					-- Render centered label (clipped to target area and inverted over filled cells)
					if attached label as l then
						l_lbl := l
					else
						l_lbl := percent.out.to_string_32 + "%%"
					end

					l_lbl_w := {UNICODE_WIDTH}.string_width (l_lbl).to_integer_32
					l_lbl_col := l_target.x.to_integer_32 + ((l_target.width.to_integer_32 - l_lbl_w) // 2).max (0)
					l_lbl_row := l_target.y.to_integer_32 + (l_target.height.to_integer_32 // 2)

					if l_lbl_row >= 0 and l_lbl_row < a_buffer.height then
						-- Over the filled part the gauge colours are inverted so the label stays readable;
						-- the label style is patched on top, so an explicit label colour wins.
						create l_filled_lbl_style
						if not gauge_style.foreground.is_default then
							l_filled_lbl_style := l_filled_lbl_style.with_background (gauge_style.foreground)
							if not gauge_style.background.is_default then
								l_filled_lbl_style := l_filled_lbl_style.with_foreground (gauge_style.background)
							else
								l_filled_lbl_style := l_filled_lbl_style.with_foreground ({COLOR}.Black)
							end
						else
							l_filled_lbl_style := l_filled_lbl_style.with_reverse
						end
						l_filled_lbl_style := l_filled_lbl_style.patch (label_style)

						-- Draw the label once, then restyle its columns over the filled cells. A wide
						-- character straddling the fill edge is drawn whole, in the style of its
						-- first column (two clipped passes used to drop it: the first stopped
						-- before it, the second blanked it).
						a_buffer.set_string_clipped (l_lbl_row, l_lbl_col, l_lbl, l_target.x.to_integer_32, l_target.right.to_integer_32, style.patch (label_style))
						l_fill_end := (l_target.x.to_integer_32 + l_full_cells).min (l_target.right.to_integer_32)
						l_filled_start := l_lbl_col.max (l_target.x.to_integer_32)
						l_filled_stop := (l_lbl_col + l_lbl_w).min (l_fill_end)
						if l_filled_stop > l_filled_start then
							a_buffer.set_style (create {RECT}.make (l_filled_start.to_natural_16, l_lbl_row.to_natural_16,
								(l_filled_stop - l_filled_start).to_natural_16, 1), l_filled_lbl_style)
						end
					end
				end
			end
		end

feature {NONE} -- Implementation

	unicode_block_code (a_frac: REAL_64): INTEGER
			-- Unicode codepoint for horizontal fraction (U+258F..U+2588).
		local
			eighths: INTEGER
		do
			eighths := (a_frac * 8.0).rounded.to_integer_32
			inspect eighths
			when 1 then Result := 9615 -- '▏'
			when 2 then Result := 9614 -- '▎'
			when 3 then Result := 9613 -- '▍'
			when 4 then Result := 9612 -- '▌'
			when 5 then Result := 9611 -- '▋'
			when 6 then Result := 9610 -- '▊'
			when 7 then Result := 9609 -- '▉'
			when 8 then Result := 9608 -- '█'
			else Result := 32 -- ' '
			end
		end

invariant
	valid_ratio: ratio >= 0.0 and ratio <= 1.0
	style_not_void: style /= Void
	gauge_style_not_void: gauge_style /= Void
	label_style_not_void: label_style /= Void

end
