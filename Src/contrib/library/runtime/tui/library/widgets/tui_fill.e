note
	description: "[
		Widget that paints every cell of its area with one symbol and one style (Ratatui
		`Fill`, fill.rs, 0.30.1): backgrounds, separators, tracks, hatched regions.

		    (create {TUI_FILL}.make ("."))
		        .with_style (create {STYLE}.make_fg ({COLOR}.Dark_gray))
		        .render (l_area, l_buffer)

		The area is cut to the buffer; nothing is drawn for an empty area or an empty symbol.

		Symbol: one grapheme cluster, one or two columns wide (`is_valid_symbol`), such as
		"x", "%/0x2022/", "e" + U+0301 or a VS16 emoji. `make`, `set_symbol` and
		`with_symbol` refuse anything else:
		  * The empty string is refused, as Ratatui's `new` and `symbol` panic on it. Only
		    `default_create` (Ratatui `Fill::default`) has an empty symbol, and it draws nothing.
		  * A zero-width cluster (a lone combining mark, a control) is refused: the buffer
		    would attach it to the cell on its left or drop it, so it cannot fill a cell.
		  * Two or more clusters are refused (Ratatui would store the whole string in one cell).

		Style: `style` patches each cell's style (Ratatui `Cell::set_style`), so colours left
		at the default keep the cell's own colours, as in Ratatui.

		Wide symbols (decision for P1 V7): Ratatui writes the symbol into every cell, also
		into the cell a wide symbol already covers. Here the fill steps by the symbol's
		width, which is what the buffer's continuation invariant needs: a wide symbol takes
		columns (c, c + 1), the next one starts at c + 2. When the area's width is odd (also
		when it is cut at the buffer's right edge), the last column has no room for the
		symbol and becomes a blank with the style, as BUFFER does for a wide character at
		its right edge. So every cell of the area gets the style, and no symbol reaches past
		the area.

		Wide characters already in the buffer: the style is patched over the style a cell
		shows, so both columns of a wide character inside the area get its style patched.
		A wide character cut by the area's left or right edge is split; its half outside the
		area becomes a blank that keeps the wide character's style (as SHADOW does), so every
		row stays continuation-consistent.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_FILL

inherit
	WIDGET
		redefine
			default_create,
			is_equal
		end

create
	default_create,
	make

feature {NONE} -- Initialization

	default_create
			-- Fill with an empty symbol, which draws nothing (Ratatui `Fill::default`).
		do
			symbol := Empty_symbol
			create style
		ensure then
			empty_symbol: symbol.is_empty
		end

	make (a_symbol: READABLE_STRING_GENERAL)
			-- Fill painting `a_symbol` in the default style (Ratatui `Fill::new`).
		require
			symbol_not_void: a_symbol /= Void
			valid_symbol: is_valid_symbol (a_symbol)
		do
			default_create
			set_symbol (a_symbol)
		ensure
			symbol_set: symbol.same_string_general ({UNICODE_SCALAR}.scalar_string (a_symbol))
			default_style: style.is_equal (create {STYLE})
		end

feature -- Access

	symbol: IMMUTABLE_STRING_32
			-- Grapheme cluster written into the cells (empty only after `default_create`)

	style: STYLE
			-- Style patched over every cell of the area

	symbol_width: INTEGER
			-- Columns taken by one `symbol` (0 when it is empty)
		do
			Result := {UNICODE_WIDTH}.grapheme_width (symbol).to_integer_32
		ensure
			valid: Result >= 0 and Result <= 2
			empty_is_zero: symbol.is_empty implies Result = 0
		end

feature -- Status report

	is_valid_symbol (a_symbol: READABLE_STRING_GENERAL): BOOLEAN
			-- Can `a_symbol` fill cells: is it one grapheme cluster, one or two columns wide?
			-- (Checked after surrogates are replaced by U+FFFD, as BUFFER draws them.)
		local
			l_text: READABLE_STRING_GENERAL
		do
			if not a_symbol.is_empty then
				l_text := {UNICODE_SCALAR}.scalar_string (a_symbol)
				Result := {UNICODE_WIDTH}.grapheme_end (l_text, 1) = l_text.count
					and {UNICODE_WIDTH}.grapheme_width (l_text) > 0
			end
		ensure
			instance_free: class
			not_empty: Result implies not a_symbol.is_empty
		end

feature -- Element change

	set_symbol (a_symbol: READABLE_STRING_GENERAL)
			-- Paint `a_symbol` (Ratatui `Fill::symbol`).
		require
			symbol_not_void: a_symbol /= Void
			valid_symbol: is_valid_symbol (a_symbol)
		do
			create symbol.make_from_string_general ({UNICODE_SCALAR}.scalar_string (a_symbol))
		ensure
			symbol_set: symbol.same_string_general ({UNICODE_SCALAR}.scalar_string (a_symbol))
		end

	set_style (a_style: STYLE)
			-- Patch `a_style` over the cells (Ratatui `Fill::style`).
		require
			style_not_void: a_style /= Void
		do
			style := a_style
		ensure
			style_set: style = a_style
		end

feature -- Fluent Builders

	with_symbol (a_symbol: READABLE_STRING_GENERAL): like Current
			-- Copy of Current painting `a_symbol`.
		require
			symbol_not_void: a_symbol /= Void
			valid_symbol: is_valid_symbol (a_symbol)
		do
			Result := twin
			Result.set_symbol (a_symbol)
		ensure
			result_not_void: Result /= Void
			symbol_set: Result.symbol.same_string_general ({UNICODE_SCALAR}.scalar_string (a_symbol))
			style_kept: Result.style = style
		end

	with_style (a_style: STYLE): like Current
			-- Copy of Current with `style` set to `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_style (a_style)
		ensure
			result_not_void: Result /= Void
			style_set: Result.style = a_style
			symbol_kept: Result.symbol.same_string (symbol)
		end

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Same symbol and style?
		do
			Result := symbol.same_string (a_other.symbol) and style.is_equal (a_other.style)
		end

feature -- Rendering

	render (a_area: RECT; a_buffer: BUFFER)
			-- Paint `symbol` with `style` into every cell of `a_area` inside `a_buffer`,
			-- stepping by the symbol's width (see the class note).
		local
			l_area: RECT
			r, c, l_left, l_right, l_w, l_last_col: INTEGER
			l_source, l_patched, l_carry: detachable STYLE
			l_style: STYLE
		do
			l_area := a_area.intersection (a_buffer.area)
			l_w := symbol_width
			if not l_area.is_empty and l_w > 0 then
				l_left := l_area.left.to_integer_32
				l_right := l_area.right.to_integer_32
				from
					r := l_area.top.to_integer_32
				until
					r >= l_area.bottom.to_integer_32
				loop
					split_at_edges (a_buffer, r, l_left, l_right)
					l_carry := Void
					from
						c := l_left
					until
						c >= l_right
					loop
							-- The source is the style the cell shows: for the right half of a
							-- wide character, the style of that character, read before the
							-- previous write blanked this half (`l_carry`).
						if attached l_carry as l_wide_style then
							l_style := l_wide_style
						else
							l_style := a_buffer.cell (r, c).style
						end
						l_last_col := (c + l_w).min (l_right) - 1
						if a_buffer.cell (r, l_last_col).width = 2 then
							l_carry := a_buffer.cell (r, l_last_col).style
						else
							l_carry := Void
						end
							-- Cells written with equal styles share one style object, so the
							-- patch is computed once per run of such cells. It is a new object,
							-- never one the buffer holds.
						if l_style /= l_source or else not attached l_patched as l_last then
							l_source := l_style
							l_style := l_style.patch (style)
							l_patched := l_style
						else
							l_style := l_last
						end
						if c + l_w <= l_right then
							a_buffer.set_string_clipped (r, c, symbol, c, c + l_w, l_style)
						else
								-- No room for a wide symbol in the last column
							a_buffer.put_char (r, c, ' ', l_style)
						end
						c := c + l_w
					end
					r := r + 1
				end
			end
		ensure then
			consistent: a_buffer.is_consistent
		end

feature {NONE} -- Implementation

	split_at_edges (a_buffer: BUFFER; a_row, a_left, a_right: INTEGER)
			-- Split the wide characters that the edges of the area cut on `a_row`: both
			-- halves become blanks with the character's style. The half outside
			-- [`a_left`, `a_right`) stays so; the fill patches its style over the half inside.
		require
			buffer_not_void: a_buffer /= Void
			valid_row: a_row >= 0 and a_row < a_buffer.height
			valid_columns: 0 <= a_left and a_left < a_right and a_right <= a_buffer.width
		local
			l_style: STYLE
		do
				-- The style is passed as a copy: BUFFER does not take a style object that its
				-- cells already hold (`owned_style` keeps them private).
			if a_left > 0 and then a_buffer.cell (a_row, a_left).is_continuation then
				l_style := a_buffer.cell (a_row, a_left - 1).style.twin
				a_buffer.put_char (a_row, a_left - 1, ' ', l_style)
				a_buffer.put_char (a_row, a_left, ' ', l_style)
			end
			if a_right < a_buffer.width and then a_buffer.cell (a_row, a_right).is_continuation then
				l_style := a_buffer.cell (a_row, a_right - 1).style.twin
				a_buffer.put_char (a_row, a_right, ' ', l_style)
				a_buffer.put_char (a_row, a_right - 1, ' ', l_style)
			end
		ensure
			continuation_consistent: a_buffer.is_continuation_consistent (a_row)
			left_whole: a_left > 0 implies not a_buffer.cell (a_row, a_left).is_continuation
			right_whole: a_right < a_buffer.width implies not a_buffer.cell (a_row, a_right).is_continuation
		end

	Empty_symbol: IMMUTABLE_STRING_32
			-- The empty symbol of `default_create`
		once
			create Result.make_empty
		end

invariant
	symbol_not_void: symbol /= Void
	style_not_void: style /= Void
	valid_or_empty_symbol: symbol.is_empty or else is_valid_symbol (symbol)

end
