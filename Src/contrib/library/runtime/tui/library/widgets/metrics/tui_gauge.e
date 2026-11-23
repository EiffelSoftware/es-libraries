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
			-- Render progress bar within `a_area` into `a_buffer`, as Ratatui's `Gauge`: `style`
			-- over the whole area, then the block, then `gauge_style` over the gauge area, so the
			-- unfilled part shows the gauge background. Filled cells are full blocks in the gauge
			-- colours (an unset colour is Reset); under the label they are blanks with the two
			-- colours swapped, so the label reads as inverted there. The filled width is rounded
			-- down with `use_unicode` (the next cell then shows the eighth block of the rest) and
			-- to the nearest cell without. The label is centred, cut to the gauge width, and its
			-- style is patched over each cell's style.
		local
			l_target: RECT
			l_end, l_right, l_bottom, r, c, i: INTEGER
			l_lbl: STRING_32
			l_lbl_w, l_lbl_col, l_lbl_row, l_lbl_right: INTEGER
			l_fg, l_bg: COLOR
			l_cell_style: STYLE
			l_saved: ARRAYED_LIST [STYLE]
		do
			if not a_area.is_empty then
				a_buffer.set_style (a_area, style)
				render_block (a_area, a_buffer)
				l_target := inner_area (a_area)

				if not l_target.is_empty and then l_target.intersects (a_buffer.area) then
					a_buffer.set_style (l_target, gauge_style)
					l_right := l_target.right.to_integer_32.min (a_buffer.width)
					l_bottom := l_target.bottom.to_integer_32.min (a_buffer.height)
					if gauge_style.foreground.is_default then l_fg := {COLOR}.Reset_color else l_fg := gauge_style.foreground end
					if gauge_style.background.is_default then l_bg := {COLOR}.Reset_color else l_bg := gauge_style.background end

						-- Label place: centred, at most the gauge width
					if attached label as l then
						l_lbl := l
					else
						l_lbl := percent.out.to_string_32 + "%%"
					end
					l_lbl_w := {UNICODE_WIDTH}.string_width (l_lbl).to_integer_32.min (l_target.width.to_integer_32)
					l_lbl_col := l_target.x.to_integer_32 + (l_target.width.to_integer_32 - l_lbl_w) // 2
					l_lbl_row := l_target.y.to_integer_32 + l_target.height.to_integer_32 // 2
					l_lbl_right := l_lbl_col + l_lbl_w

						-- Filled part
					if use_unicode then
						l_end := l_target.x.to_integer_32 + (l_target.width.to_integer_32.to_double * ratio).floor
					else
						l_end := l_target.x.to_integer_32 + (l_target.width.to_integer_32.to_double * ratio).rounded
					end
					l_end := l_end.min (l_target.right.to_integer_32)
					from r := l_target.y.to_integer_32 until r >= l_bottom loop
						from c := l_target.x.to_integer_32 until c >= l_end or c >= l_right loop
							l_cell_style := a_buffer.cell (r, c).style
							if c < l_lbl_col or c >= l_lbl_right or r /= l_lbl_row then
								a_buffer.put_char (r, c, {SYMBOLS_BLOCK}.full, l_cell_style.with_foreground (l_fg).with_background (l_bg))
							else
								a_buffer.put_char (r, c, ' ', l_cell_style.with_foreground (l_bg).with_background (l_fg))
							end
							c := c + 1
						end
						if use_unicode and ratio < 1.0 and l_end < l_right then
							a_buffer.put_char (r, l_end, unicode_block_code (l_target.width.to_integer_32.to_double * ratio
								- (l_target.width.to_integer_32.to_double * ratio).floor).to_character_32, a_buffer.cell (r, l_end).style.twin)
						end
						r := r + 1
					end

						-- Label: written plain, then each cell gets its own style patched by `label_style`
					if l_lbl_w > 0 and l_lbl_row < a_buffer.height then
						create l_saved.make (l_lbl_w)
						from c := l_lbl_col until c >= l_lbl_right loop
							if c < a_buffer.width then
								l_saved.extend (a_buffer.cell (l_lbl_row, c).style.twin)
							end
							c := c + 1
						end
						a_buffer.set_string_clipped (l_lbl_row, l_lbl_col, l_lbl, l_lbl_col, l_lbl_right.min (a_buffer.width), create {STYLE})
						i := 1
						from c := l_lbl_col until c >= l_lbl_right or c >= a_buffer.width loop
							a_buffer.set_style (create {RECT}.make (c.to_natural_16, l_lbl_row.to_natural_16, 1, 1), l_saved [i].patch (label_style))
							i := i + 1
							c := c + 1
						end
					end
				end
			end
		ensure then
			consistent: a_buffer.is_consistent
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
