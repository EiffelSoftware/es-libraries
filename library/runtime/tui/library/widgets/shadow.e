note
	description: "[
		Shadow cast by a TUI_BLOCK (Ratatui `Shadow`, block/shadow.rs, 0.30.1).

		The shadow covers the block's area moved by (`offset_x`, `offset_y`), default (1, 1),
		cut to the buffer. Cells inside the block itself are never touched, so with the
		default offset the shadow is the column right of the block and the row below it:

		    +Popup-----+
		    |content   |#
		    +----------+#
		     ###########

		Kinds (creation procedures):
		  * `make_overlay` (also `default_create`): only `style` is applied; the symbols
		    underneath stay, so the shadow tints what it covers.
		  * `make_block`, `make_light_shade`, `make_medium_shade`, `make_dark_shade` and
		    `make_symbol (c)`: every shadow cell gets the symbol (full block, the three shades,
		    or `c`) and `style`. The cell's own style is kept under `style`.
		  * `make_custom (e)`: `style` is applied, then the CELL_EFFECT `e` (for example
		    DIMMED_EFFECT). The effect is shared, not copied, by `twin`, and two custom shadows
		    are equal only with the same effect object (Ratatui compares `Arc` pointers).

		`style` patches each cell, as BUFFER.set_style does: colours left at the default keep
		the cell's colours.

		Wide characters: the buffer keeps a wide character and its continuation cell
		together. A symbol shadow over half of a wide character splits it: the shadow column
		gets the symbol, and the other column becomes a blank with the wide character's style.
		An overlay keeps wide characters whole: a wide character whose first column is under
		the shadow takes the shadow style in both columns; one whose first column is outside
		keeps its style.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	SHADOW

inherit
	ANY
		redefine
			default_create,
			is_equal
		end

create
	default_create,
	make_overlay,
	make_block,
	make_light_shade,
	make_medium_shade,
	make_dark_shade,
	make_symbol,
	make_custom

feature {NONE} -- Initialization

	default_create
			-- Overlay shadow (Ratatui `Shadow::default`).
		do
			make_overlay
		end

	make_overlay
			-- Shadow that applies only `style`; the symbols underneath stay.
		do
			create style
			offset_x := 1
			offset_y := 1
			has_symbol := False
			symbol := ' '
			effect := Void
		ensure
			overlay: is_overlay
			default_offset: offset_x = 1 and offset_y = 1
		end

	make_block
			-- Shadow filled with full blocks.
		do
			make_symbol ({SYMBOLS_BLOCK}.full)
		ensure
			symbol_set: has_symbol and symbol = {SYMBOLS_BLOCK}.full
		end

	make_light_shade
			-- Shadow filled with light shades.
		do
			make_symbol ({SYMBOLS_BLOCK}.light_shade)
		ensure
			symbol_set: has_symbol and symbol = {SYMBOLS_BLOCK}.light_shade
		end

	make_medium_shade
			-- Shadow filled with medium shades.
		do
			make_symbol ({SYMBOLS_BLOCK}.medium_shade)
		ensure
			symbol_set: has_symbol and symbol = {SYMBOLS_BLOCK}.medium_shade
		end

	make_dark_shade
			-- Shadow filled with dark shades.
		do
			make_symbol ({SYMBOLS_BLOCK}.dark_shade)
		ensure
			symbol_set: has_symbol and symbol = {SYMBOLS_BLOCK}.dark_shade
		end

	make_symbol (a_char: CHARACTER_32)
			-- Shadow filled with `a_char`.
		require
			one_column: is_valid_symbol (a_char)
		do
			make_overlay
			symbol := a_char
			has_symbol := True
		ensure
			symbol_set: has_symbol and symbol = a_char
			no_effect: effect = Void
			default_offset: offset_x = 1 and offset_y = 1
		end

	make_custom (a_effect: CELL_EFFECT)
			-- Shadow that applies `style`, then `a_effect`.
		require
			effect_not_void: a_effect /= Void
		do
			make_overlay
			effect := a_effect
		ensure
			effect_set: effect = a_effect
			custom: is_custom
			default_offset: offset_x = 1 and offset_y = 1
		end

feature -- Access

	style: STYLE
			-- Style patched over every shadow cell (applied before the symbol or the effect)

	offset_x: INTEGER
			-- Columns from the block to the shadow; negative moves it left

	offset_y: INTEGER
			-- Rows from the block to the shadow; negative moves it up

	symbol: CHARACTER_32
			-- Symbol written into every shadow cell, when `has_symbol`

	effect: detachable CELL_EFFECT
			-- Custom effect, for `make_custom`

feature -- Status report

	has_symbol: BOOLEAN
			-- Does the shadow write `symbol` into its cells?

	is_overlay: BOOLEAN
			-- Does the shadow apply only `style`?
		do
			Result := not has_symbol and effect = Void
		ensure
			definition: Result = (not has_symbol and effect = Void)
		end

	is_custom: BOOLEAN
			-- Does the shadow apply a custom `effect`?
		do
			Result := effect /= Void
		ensure
			definition: Result = (effect /= Void)
		end

	is_valid_symbol (a_char: CHARACTER_32): BOOLEAN
			-- Can `a_char` fill a shadow: is it one column wide?
		do
			Result := {UNICODE_WIDTH}.width (a_char.natural_32_code) = 1
		ensure
			instance_free: class
			definition: Result = ({UNICODE_WIDTH}.width (a_char.natural_32_code) = 1)
		end

feature -- Element change

	set_style (a_style: STYLE)
			-- Set the style applied to the shadow cells.
		require
			style_not_void: a_style /= Void
		do
			style := a_style
		ensure
			style_set: style = a_style
		end

	set_offset (a_x, a_y: INTEGER)
			-- Move the shadow by `a_x` columns and `a_y` rows from the block.
		do
			offset_x := a_x
			offset_y := a_y
		ensure
			offset_x_set: offset_x = a_x
			offset_y_set: offset_y = a_y
		end

feature -- Fluent Builders

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
		end

	with_offset (a_x, a_y: INTEGER): like Current
			-- Copy of Current moved by `a_x` columns and `a_y` rows from the block.
		do
			Result := twin
			Result.set_offset (a_x, a_y)
		ensure
			result_not_void: Result /= Void
			offset_x_set: Result.offset_x = a_x
			offset_y_set: Result.offset_y = a_y
		end

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Same kind, symbol, style and offset? Custom effects are compared by reference.
		do
			Result := has_symbol = a_other.has_symbol
				and (has_symbol implies symbol = a_other.symbol)
				and effect = a_other.effect
				and style.is_equal (a_other.style)
				and offset_x = a_other.offset_x
				and offset_y = a_other.offset_y
		end

feature -- Geometry

	shadow_area (a_base: RECT; a_buffer: BUFFER): RECT
			-- `a_base` moved by the offset, then cut to `a_buffer`. As Ratatui's `Rect + Offset`,
			-- the move keeps the size and clamps the position to 0 .. 65535 - size, so an offset
			-- that would push the shadow past column or row 0 leaves it at 0, still partly visible.
		require
			base_not_void: a_base /= Void
			buffer_not_void: a_buffer /= Void
		local
			l_x0, l_y0, l_x1, l_y1: INTEGER_64
		do
			l_x0 := (a_base.x.to_integer_64 + offset_x.to_integer_64).max (0).min (Max_coordinate - a_base.width.to_integer_64)
			l_y0 := (a_base.y.to_integer_64 + offset_y.to_integer_64).max (0).min (Max_coordinate - a_base.height.to_integer_64)
			l_x1 := (l_x0 + a_base.width.to_integer_64).min (a_buffer.width.to_integer_64)
			l_y1 := (l_y0 + a_base.height.to_integer_64).min (a_buffer.height.to_integer_64)
			if l_x0 < l_x1 and l_y0 < l_y1 then
				create Result.make (l_x0.to_natural_16, l_y0.to_natural_16,
					(l_x1 - l_x0).to_natural_16, (l_y1 - l_y0).to_natural_16)
			else
				create Result
			end
		ensure
			result_not_void: Result /= Void
			in_buffer: Result.is_empty or else a_buffer.area.contains_rect (Result)
		end

feature -- Shadow cells

	visible_regions (a_shadow_area, a_base_area: RECT): ARRAYED_LIST [RECT]
			-- The part of `a_shadow_area` outside `a_base_area`, as at most four rectangles that
			-- do not overlap: the rows above `a_base_area`, the rows below it, and in the rows
			-- beside it the columns left and right of it. Empty rectangles are left out.
		require
			shadow_area_not_void: a_shadow_area /= Void
			base_area_not_void: a_base_area /= Void
		local
			l_inter: RECT
			l_top, l_bottom: NATURAL_16
		do
			create Result.make (4)
			if not a_shadow_area.is_empty then
				l_inter := a_shadow_area.intersection (a_base_area)
				if l_inter.is_empty then
					Result.extend (a_shadow_area)
				else
					l_top := l_inter.top
					l_bottom := l_inter.bottom
					if a_shadow_area.top < l_top then
						Result.extend (create {RECT}.make (a_shadow_area.x, a_shadow_area.y,
							a_shadow_area.width, l_top - a_shadow_area.top))
					end
					if l_bottom < a_shadow_area.bottom then
						Result.extend (create {RECT}.make (a_shadow_area.x, l_bottom,
							a_shadow_area.width, a_shadow_area.bottom - l_bottom))
					end
					if a_shadow_area.left < l_inter.left then
						Result.extend (create {RECT}.make (a_shadow_area.x, l_top,
							l_inter.left - a_shadow_area.left, l_bottom - l_top))
					end
					if l_inter.right < a_shadow_area.right then
						Result.extend (create {RECT}.make (l_inter.right, l_top,
							a_shadow_area.right - l_inter.right, l_bottom - l_top))
					end
				end
			end
		ensure
			instance_free: class
			at_most_four: Result.count <= 4
			inside_shadow: across Result as r all a_shadow_area.contains_rect (r) end
			outside_base: across Result as r all not r.intersects (a_base_area) end
			none_empty: across Result as r all not r.is_empty end
		end

	is_shadow_cell (a_row, a_col: INTEGER; a_shadow_area, a_base_area: RECT): BOOLEAN
			-- Is the cell at (`a_row`, `a_col`) in `a_shadow_area` and not in `a_base_area`?
		require
			shadow_area_not_void: a_shadow_area /= Void
			base_area_not_void: a_base_area /= Void
		do
			Result := in_rect (a_row, a_col, a_shadow_area) and not in_rect (a_row, a_col, a_base_area)
		ensure
			instance_free: class
		end

	put_shadow_symbol (a_buffer: BUFFER; a_row, a_col: INTEGER; a_char: CHARACTER_32)
			-- Put the one-column `a_char` at (`a_row`, `a_col`), keeping the cell's style
			-- (as Ratatui `Cell::set_symbol`). When the cell is half of a wide character, the
			-- character is split: `a_char` takes this column and the other column becomes a
			-- blank, both with the wide character's style, so the row stays consistent.
		require
			buffer_not_void: a_buffer /= Void
			valid_position: a_buffer.is_valid_position (a_row, a_col)
			one_column: {UNICODE_WIDTH}.width (a_char.natural_32_code) = 1
		local
			l_cell: TERMINAL_CELL
			l_style: STYLE
		do
				-- The style is passed as a copy: BUFFER does not take a style object that its
				-- cells already hold (`owned_style` keeps them private).
			l_cell := a_buffer.cell (a_row, a_col)
			if l_cell.is_continuation and a_col > 0 then
				l_style := a_buffer.cell (a_row, a_col - 1).style.twin
				a_buffer.put_char (a_row, a_col, a_char, l_style)
				a_buffer.put_char (a_row, a_col - 1, ' ', l_style)
			elseif l_cell.width = 2 and a_col + 1 < a_buffer.width then
				l_style := l_cell.style.twin
				a_buffer.put_char (a_row, a_col, a_char, l_style)
				a_buffer.put_char (a_row, a_col + 1, ' ', l_style)
			else
				a_buffer.put_char (a_row, a_col, a_char, l_cell.style.twin)
			end
		ensure
			instance_free: class
			symbol_set: a_buffer.cell (a_row, a_col).symbol.count = 1
				and then a_buffer.cell (a_row, a_col).symbol.code (1) = {UNICODE_SCALAR}.scalar_value (a_char.natural_32_code)
			continuation_consistent: a_buffer.is_continuation_consistent (a_row)
		end

feature {NONE} -- Implementation: cells

	Max_coordinate: INTEGER_64 = 65535
			-- Largest coordinate of a RECT edge (NATURAL_16, Ratatui `u16::MAX`)

	in_rect (a_row, a_col: INTEGER; a_rect: RECT): BOOLEAN
			-- Is (`a_row`, `a_col`) inside `a_rect`?
		do
			Result := a_col >= a_rect.left.to_integer_32 and a_col < a_rect.right.to_integer_32
				and a_row >= a_rect.top.to_integer_32 and a_row < a_rect.bottom.to_integer_32
		ensure
			instance_free: class
		end

feature -- Rendering

	render (a_base: RECT; a_buffer: BUFFER)
			-- Draw the shadow of a block covering `a_base` on `a_buffer` (Ratatui
			-- `Shadow::render`): the shadow area, without the cells of `a_base`, gets
			-- `style`, then the symbol or the effect.
		require
			base_not_void: a_base /= Void
			buffer_not_void: a_buffer /= Void
		local
			l_area: RECT
			l_regions: ARRAYED_LIST [RECT]
			r, c: INTEGER
		do
			l_area := shadow_area (a_base, a_buffer)
			if not l_area.is_empty then
				l_regions := visible_regions (l_area, a_base)
				if has_symbol then
						-- Symbols first: the cells are then all one column wide, so the
						-- style reaches every one of them. Ratatui sets the style first, but
						-- its symbol does not change the style, so the cells end the same.
					across l_regions as l_region loop
						from
							r := l_region.top.to_integer_32
						until
							r >= l_region.bottom.to_integer_32
						loop
							from
								c := l_region.left.to_integer_32
							until
								c >= l_region.right.to_integer_32
							loop
								put_shadow_symbol (a_buffer, r, c, symbol)
								c := c + 1
							end
							r := r + 1
						end
					end
				end
				across l_regions as l_region loop
					a_buffer.set_style (l_region, style)
				end
				if attached effect as l_effect then
					l_effect.apply (l_area, a_base, a_buffer)
				end
			end
		ensure
			consistent: a_buffer.is_consistent
		end

invariant
	style_not_void: style /= Void
	one_column_symbol: has_symbol implies is_valid_symbol (symbol)
	one_kind: not (has_symbol and effect /= Void)

end
