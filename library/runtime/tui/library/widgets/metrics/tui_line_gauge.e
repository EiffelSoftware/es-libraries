note
	description: "[
		Ultra-compact single-line horizontal progress gauge widget,
		rendering left-aligned label followed by filled and unfilled line glyphs.
		The line repeats one symbol per cell, so both symbols must be one column wide
		({TERMINAL_CELL}.is_one_column_symbol): a wide one blanked its neighbours, and a
		multi-character one was cut to its first character.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_LINE_GAUGE

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
			-- Initialize line gauge with 0% progress and standard line glyphs.
		do
			ratio := 0.0
			create filled_symbol.make (1)
			filled_symbol.append_character ((9473).to_character_32) -- Thick line '━'
			create unfilled_symbol.make (1)
			unfilled_symbol.append_character ((9472).to_character_32) -- Thin line '─'
			create style.default_create
			create filled_style.default_create
			create unfilled_style.default_create
			create label_style.default_create
			label_style := label_style.with_bold
		ensure then
			ratio_zero: ratio = 0.0
			no_block: block = Void
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
			-- Optional custom left-aligned label

	filled_symbol: STRING_32
			-- Glyph representing filled progress segment (default '━')

	unfilled_symbol: STRING_32
			-- Glyph representing unfilled progress segment (default '─')

	style: STYLE
			-- Base style

	filled_style: STYLE
			-- Style applied to filled progress glyphs

	unfilled_style: STYLE
			-- Style applied to unfilled progress glyphs

	label_style: STYLE
			-- Style applied to label text

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
			-- Set or clear left label.
		do
			if attached a_label as l then
				create label.make_from_string_general (l)
			else
				label := Void
			end
		ensure
			label_set: attached a_label implies attached label
		end

	set_filled_symbol (a_symbol: READABLE_STRING_GENERAL)
			-- Set filled line character glyph.
		require
			symbol_not_void: a_symbol /= Void
			one_column: {TERMINAL_CELL}.is_one_column_symbol (a_symbol)
		do
			create filled_symbol.make_from_string_general (a_symbol)
		ensure
			symbol_set: filled_symbol.same_string_general (a_symbol)
		end

	set_unfilled_symbol (a_symbol: READABLE_STRING_GENERAL)
			-- Set unfilled line character glyph.
		require
			symbol_not_void: a_symbol /= Void
			one_column: {TERMINAL_CELL}.is_one_column_symbol (a_symbol)
		do
			create unfilled_symbol.make_from_string_general (a_symbol)
		ensure
			symbol_set: unfilled_symbol.same_string_general (a_symbol)
		end

	set_filled_style (a_style: STYLE)
			-- Set filled progress style.
		require
			style_not_void: a_style /= Void
		do
			filled_style := a_style
		ensure
			style_set: filled_style = a_style
		end

	set_unfilled_style (a_style: STYLE)
			-- Set unfilled progress style.
		require
			style_not_void: a_style /= Void
		do
			unfilled_style := a_style
		ensure
			style_set: unfilled_style = a_style
		end

	set_label_style (a_style: STYLE)
			-- Set label style.
		require
			style_not_void: a_style /= Void
		do
			label_style := a_style
		ensure
			style_set: label_style = a_style
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

feature -- Fluent Builders

	with_ratio (a_ratio: REAL_64): like Current
			-- Line gauge with progress `a_ratio`.
		require
			valid_ratio: a_ratio >= 0.0 and a_ratio <= 1.0
		do
			Result := twin
			Result.set_ratio (a_ratio)
		ensure
			ratio_set: Result.ratio = a_ratio
		end

	with_percent (a_percent: NATURAL_16): like Current
			-- Line gauge with progress `a_percent`.
		require
			valid_percent: a_percent <= 100
		do
			Result := twin
			Result.set_percent (a_percent)
		ensure
			percent_set: Result.percent = a_percent
		end

	with_label (a_label: detachable READABLE_STRING_GENERAL): like Current
			-- Line gauge with label `a_label`.
		do
			Result := twin
			Result.set_label (a_label)
		end

	with_filled_style (a_style: STYLE): like Current
			-- Line gauge with filled `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_filled_style (a_style)
		ensure
			style_set: Result.filled_style = a_style
		end

	with_unfilled_style (a_style: STYLE): like Current
			-- Line gauge with unfilled `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_unfilled_style (a_style)
		ensure
			style_set: Result.unfilled_style = a_style
		end

	with_style (a_style: STYLE): like Current
			-- Line gauge with base `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_style (a_style)
		ensure
			style_set: Result.style = a_style
		end

	with_label_style (a_style: STYLE): like Current
			-- Line gauge with label `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_label_style (a_style)
		ensure
			style_set: Result.label_style = a_style
		end

feature -- Rendering

	render (a_area: RECT; a_buffer: BUFFER)
			-- Render single-line gauge into `a_buffer` within `a_area`.
		local
			l_target: RECT
			l_lbl: STRING_32
			l_lbl_w, l_line_w, l_filled_count, i, l_col, l_row, l_left, l_right: INTEGER
		do
			if not a_area.is_empty then
				render_block (a_area, a_buffer)
				l_target := inner_area (a_area)

				if not l_target.is_empty and l_target.y.to_integer_32 < a_buffer.height then
					l_row := l_target.y.to_integer_32
					l_left := l_target.x.to_integer_32
					l_right := l_target.right.to_integer_32

					if attached label as l then
						l_lbl := l
					else
						l_lbl := percent.out.to_string_32 + "%%"
					end
					l_lbl_w := {UNICODE_WIDTH}.string_width (l_lbl).to_integer_32

					-- Label (clipped when space is tight), a space, then the line in the remaining width.
					-- Every write is clipped to the area and the buffer.
					a_buffer.set_string_clipped (l_row, l_left, l_lbl, l_left, l_right, label_style)
					if l_lbl_w + 1 < l_target.width.to_integer_32 then
						a_buffer.set_string_clipped (l_row, l_left + l_lbl_w, " ", l_left, l_right, style)
						l_col := l_left + l_lbl_w + 1
						l_line_w := l_right - l_col
					end

					if l_line_w > 0 then
						-- Filled cells: floor of the exact share, as in Ratatui
						l_filled_count := (l_line_w.to_double * ratio).floor.min (l_line_w)
						from
							i := 0
						until
							i >= l_line_w
						loop
							-- Each symbol is clipped to its own cell
							if i < l_filled_count then
								a_buffer.set_string_clipped (l_row, l_col + i, filled_symbol, l_col + i, l_col + i + 1, filled_style)
							else
								a_buffer.set_string_clipped (l_row, l_col + i, unfilled_symbol, l_col + i, l_col + i + 1, unfilled_style)
							end
							i := i + 1
						end
					end
				end
			end
		end

invariant
	valid_ratio: ratio >= 0.0 and ratio <= 1.0
	filled_symbol_not_void: filled_symbol /= Void
	unfilled_symbol_not_void: unfilled_symbol /= Void
	one_column_filled: {TERMINAL_CELL}.is_one_column_symbol (filled_symbol)
	one_column_unfilled: {TERMINAL_CELL}.is_one_column_symbol (unfilled_symbol)
	style_not_void: style /= Void
	filled_style_not_void: filled_style /= Void
	unfilled_style_not_void: unfilled_style /= Void
	label_style_not_void: label_style /= Void

end
