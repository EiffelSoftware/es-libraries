note
	description: "[
		2D sub-pixel canvas for terminal character cell rendering (Ratatui `PatternGrid`).
		By default each cell holds 2 x 4 dots, encoded as Unicode Braille Patterns (U+2800..U+28FF):
		the cell mask uses Braille's own bit order (`is_braille_order`).
		`make_with_pattern` gives a grid of 2 x 4 (octant), 2 x 3 (sextant) or 2 x 2 (quadrant)
		pseudo-pixels per cell, whose mask has the pseudo-pixels in row-major order, bit x + W * y
		(the index of SYMBOLS_PIXEL). `make_with_resolution` gives 1 x 2 (half blocks) and 1 x 1
		(dot, block and bar markers); there the mask is row-major too: bit 1 for the (top) dot and
		bit 2 for the bottom one.
		Octant and Braille are both 2 x 4, so the bit order is not given by the resolution alone.
		A cell with mask 0 is not drawn, so the layers below show through.
		Styles: one per cell (the colour of a Ratatui `PatternGrid` or `CharGrid` cell), except on a
		1 x 2 (half block) grid, which keeps one per dot, as Ratatui `HalfBlockGrid` keeps a colour
		per pixel: `cell_style` is the upper half, `lower_style` the lower half.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	BRAILLE_CANVAS

create
	make,
	make_with_resolution,
	make_with_pattern

feature {NONE} -- Initialization

	make (a_cols, a_rows: INTEGER)
			-- Initialize canvas of `a_cols` by `a_rows` terminal character cells.
		require
			positive_cols: a_cols >= 0
			positive_rows: a_rows >= 0
		do
			make_with_pattern (a_cols, a_rows, 2, 4)
			is_braille_order := True
		ensure
			cols_set: cols = a_cols
			rows_set: rows = a_rows
			braille_order: is_braille_order
		end

	make_with_resolution (a_cols, a_rows, a_dots_x, a_dots_y: INTEGER)
			-- Initialize canvas of `a_cols` by `a_rows` cells, each `a_dots_x` by `a_dots_y` dots.
			-- 2 x 4 is Braille (Braille bit order, as `make`); the other resolutions are row-major.
		require
			positive_cols: a_cols >= 0
			positive_rows: a_rows >= 0
			valid_resolution: is_valid_resolution (a_dots_x, a_dots_y)
		do
			make_with_pattern (a_cols, a_rows, a_dots_x, a_dots_y)
			is_braille_order := a_dots_x = 2 and a_dots_y = 4
		ensure
			cols_set: cols = a_cols
			rows_set: rows = a_rows
			dots_x_set: dots_x = a_dots_x
			dots_y_set: dots_y = a_dots_y
			braille_order: is_braille_order = (a_dots_x = 2 and a_dots_y = 4)
		end

	make_with_pattern (a_cols, a_rows, a_dots_x, a_dots_y: INTEGER)
			-- Initialize canvas of `a_cols` by `a_rows` cells, each `a_dots_x` by `a_dots_y`
			-- pseudo-pixels in row-major bit order (bit x + `a_dots_x` * y), as Ratatui `PatternGrid`.
			-- 2 x 4 is the octant grid, 2 x 3 sextant, 2 x 2 quadrant.
		require
			positive_cols: a_cols >= 0
			positive_rows: a_rows >= 0
			valid_resolution: is_valid_resolution (a_dots_x, a_dots_y)
		local
			l_default_style: STYLE
		do
			cols := a_cols
			rows := a_rows
			dots_x := a_dots_x
			dots_y := a_dots_y
			create l_default_style.default_create
			create masks.make_filled (0, (a_cols * a_rows).max (1))
			create styles.make_filled (l_default_style, (a_cols * a_rows).max (1))
			if a_dots_x = 1 and a_dots_y = 2 then
				create lower_styles.make_filled (l_default_style, styles.count)
			else
				create lower_styles.make_empty (0)
			end
			is_braille_order := False
		ensure
			cols_set: cols = a_cols
			rows_set: rows = a_rows
			dots_x_set: dots_x = a_dots_x
			dots_y_set: dots_y = a_dots_y
			row_major: not is_braille_order
		end

feature -- Access

	cols: INTEGER
			-- Width in terminal character cells.

	rows: INTEGER
			-- Height in terminal character cells.

	dots_x, dots_y: INTEGER
			-- Dots per cell horizontally and vertically (2 x 4 for Braille)

	is_braille_order: BOOLEAN
			-- Do the cell masks use Braille's dot order (U+2800 + mask)?
			-- Otherwise they are row-major: bit x + `dots_x` * y.

	is_half_block_grid: BOOLEAN
			-- Is this a 1 x 2 grid, with a style for each half of a cell (`cell_style`, `lower_style`)?
		do
			Result := dots_x = 1 and dots_y = 2
		ensure
			definition: Result = (dots_x = 1 and dots_y = 2)
		end

	subpixel_width: INTEGER
			-- Width in sub-pixel dots.
		do
			Result := cols * dots_x
		ensure
			width_set: Result = cols * dots_x
		end

	subpixel_height: INTEGER
			-- Height in sub-pixel dots.
		do
			Result := rows * dots_y
		ensure
			height_set: Result = rows * dots_y
		end

feature -- Query

	is_valid_resolution (a_dots_x, a_dots_y: INTEGER): BOOLEAN
			-- Is `a_dots_x` by `a_dots_y` dots per cell supported (2 x 4, 2 x 3, 2 x 2, 1 x 2, 1 x 1)?
		do
			Result := (a_dots_x = 2 and (a_dots_y >= 2 and a_dots_y <= 4)) or (a_dots_x = 1 and (a_dots_y = 1 or a_dots_y = 2))
		ensure
			instance_free: class
		end

	is_subpixel_valid (a_sx, a_sy: INTEGER): BOOLEAN
			-- Are subpixel coordinates `a_sx`, `a_sy` within canvas bounds?
		do
			Result := a_sx >= 0 and a_sx < subpixel_width and a_sy >= 0 and a_sy < subpixel_height
		end

	is_cell_valid (a_col, a_row: INTEGER): BOOLEAN
			-- Are cell coordinates `a_col`, `a_row` within canvas bounds?
		do
			Result := a_col >= 0 and a_col < cols and a_row >= 0 and a_row < rows
		end

	is_pixel_set (a_sx, a_sy: INTEGER): BOOLEAN
			-- Is subpixel dot at `a_sx`, `a_sy` turned on?
		require
			valid_coord: is_subpixel_valid (a_sx, a_sy)
		local
			l_cell_idx: INTEGER
			l_bit: NATURAL_8
		do
			l_cell_idx := cell_index (a_sx // dots_x, a_sy // dots_y)
			l_bit := dot_bit (a_sx \\ dots_x, a_sy \\ dots_y)
			Result := (masks.item (l_cell_idx) & l_bit) /= 0
		end

	cell_mask (a_col, a_row: INTEGER): NATURAL_8
			-- Dot bitmask for character cell (`a_col`, `a_row`): Braille's bit order when
			-- `is_braille_order`, row-major otherwise (the index of SYMBOLS_PIXEL).
		require
			valid_cell: is_cell_valid (a_col, a_row)
		do
			Result := masks.item (cell_index (a_col, a_row))
		end

	cell_style (a_col, a_row: INTEGER): STYLE
			-- Style for character cell (`a_col`, `a_row`); on a half block grid, the style of its
			-- upper half (see `lower_style`).
		require
			valid_cell: is_cell_valid (a_col, a_row)
		do
			Result := styles.item (cell_index (a_col, a_row))
		end

	lower_style (a_col, a_row: INTEGER): STYLE
			-- Style of the lower half of cell (`a_col`, `a_row`) of a half block grid.
		require
			half_block_grid: is_half_block_grid
			valid_cell: is_cell_valid (a_col, a_row)
		do
			Result := lower_styles.item (cell_index (a_col, a_row))
		end

	cell_char (a_col, a_row: INTEGER): CHARACTER_32
			-- Unicode Braille character (U+2800..U+28FF) or space if empty.
			-- Meaningful when `is_braille_order` (TUI_CANVAS picks the glyph for other grids).
		require
			valid_cell: is_cell_valid (a_col, a_row)
		local
			l_m: NATURAL_8
		do
			l_m := cell_mask (a_col, a_row)
			if l_m = 0 then
				Result := ' '
			else
				Result := (10240 + l_m.to_integer_32).to_character_32
			end
		end

feature -- Constants

	policy_last_wins: NATURAL_8 = 1
			-- Newest dot style overwrites cell style.

	policy_first_wins: NATURAL_8 = 2
			-- Oldest dot style is retained if cell already has active dots.

feature -- Access

	color_policy: NATURAL_8
			-- Color resolution policy when multiple dots in the same cell have different styles

feature -- Configuration

	set_color_policy (a_policy: NATURAL_8)
			-- Set color policy (`policy_last_wins` or `policy_first_wins`).
		require
			valid_policy: a_policy = policy_last_wins or a_policy = policy_first_wins
		do
			color_policy := a_policy
		ensure
			policy_set: color_policy = a_policy
		end

feature -- Modification

	set_pixel (a_sx, a_sy: INTEGER)
			-- Turn on subpixel dot at `a_sx`, `a_sy`.
		local
			l_idx: INTEGER
			l_bit: NATURAL_8
		do
			if is_subpixel_valid (a_sx, a_sy) then
				l_idx := cell_index (a_sx // dots_x, a_sy // dots_y)
				l_bit := dot_bit (a_sx \\ dots_x, a_sy \\ dots_y)
				masks.put (masks.item (l_idx) | l_bit, l_idx)
			end
		end

	set_pixel_with_style (a_sx, a_sy: INTEGER; a_style: STYLE)
			-- Turn on subpixel dot at `a_sx`, `a_sy` and update cell style according to `color_policy`.
			-- On a half block grid each half has its own style, and the policy applies per half
			-- (Ratatui `HalfBlockGrid::paint`: the last colour of each pixel wins).
		require
			style_not_void: a_style /= Void
		local
			l_idx: INTEGER
			l_bit: NATURAL_8
		do
			if is_subpixel_valid (a_sx, a_sy) then
				l_idx := cell_index (a_sx // dots_x, a_sy // dots_y)
				l_bit := dot_bit (a_sx \\ dots_x, a_sy \\ dots_y)
				if lower_styles.count = 0 then
					if color_policy = policy_first_wins and masks.item (l_idx) /= 0 then
						-- Retain first style
					else
						-- Last wins: the newest dot's style replaces the cell style
						styles.put (a_style, l_idx)
					end
				elseif color_policy = policy_first_wins and (masks.item (l_idx) & l_bit) /= 0 then
					-- Half block: retain the first style of this half
				elseif l_bit = 1 then
					styles.put (a_style, l_idx)
				else
					lower_styles.put (a_style, l_idx)
				end
				masks.put (masks.item (l_idx) | l_bit, l_idx)
			end
		end

	reset_pixel (a_sx, a_sy: INTEGER)
			-- Turn off subpixel dot at `a_sx`, `a_sy`.
		local
			l_idx: INTEGER
			l_bit: NATURAL_8
		do
			if is_subpixel_valid (a_sx, a_sy) then
				l_idx := cell_index (a_sx // dots_x, a_sy // dots_y)
				l_bit := dot_bit (a_sx \\ dots_x, a_sy \\ dots_y)
				masks.put (masks.item (l_idx) & (l_bit.bit_not), l_idx)
			end
		end

	set_cell_style (a_col, a_row: INTEGER; a_style: STYLE)
			-- Set style for cell (`a_col`, `a_row`) (both halves on a half block grid).
		require
			valid_cell: is_cell_valid (a_col, a_row)
			style_not_void: a_style /= Void
		do
			styles.put (a_style, cell_index (a_col, a_row))
			if lower_styles.count > 0 then
				lower_styles.put (a_style, cell_index (a_col, a_row))
			end
		ensure
			style_set: cell_style (a_col, a_row) = a_style
			lower_set: is_half_block_grid implies lower_style (a_col, a_row) = a_style
		end

	clear
			-- Clear all subpixels and styles.
		local
			l_default_style: STYLE
		do
			create l_default_style.default_create
			masks.fill_with (0, 0, masks.count - 1)
			styles.fill_with (l_default_style, 0, styles.count - 1)
			if lower_styles.count > 0 then
				lower_styles.fill_with (l_default_style, 0, lower_styles.count - 1)
			end
		end

feature {NONE} -- Implementation

	masks: SPECIAL [NATURAL_8]
			-- Flat storage for cell dot masks.

	styles: SPECIAL [STYLE]
			-- Flat storage for cell styles (of the upper halves on a half block grid).

	lower_styles: SPECIAL [STYLE]
			-- Flat storage for the styles of the lower halves on a half block grid; empty otherwise.

	cell_index (a_col, a_row: INTEGER): INTEGER
			-- Flat 0-based index for (`a_col`, `a_row`).
		do
			Result := a_row * cols + a_col
		end

	dot_bit (a_dx, a_dy: INTEGER): NATURAL_8
			-- Dot bitmask for intra-cell subpixel offset `(a_dx, a_dy)`: Unicode Braille's dot
			-- order when `is_braille_order`, else row-major (bit `a_dx` + `dots_x` * `a_dy`).
			-- `a_dx` in 0 .. `dots_x` - 1, `a_dy` in 0 .. `dots_y` - 1.
		do
			if not is_braille_order then
				-- Pattern grids, and 1 x 1 / 1 x 2 cells (bit 1 = top dot, bit 2 = bottom dot)
				Result := (1 |<< (a_dx + dots_x * a_dy)).to_natural_8
			elseif a_dx = 0 then
				inspect a_dy
				when 0 then Result := 1    -- Dot 1 (0x01)
				when 1 then Result := 2    -- Dot 2 (0x02)
				when 2 then Result := 4    -- Dot 3 (0x04)
				when 3 then Result := 64   -- Dot 7 (0x40)
				else
					Result := 0
				end
			else
				inspect a_dy
				when 0 then Result := 8    -- Dot 4 (0x08)
				when 1 then Result := 16   -- Dot 5 (0x10)
				when 2 then Result := 32   -- Dot 6 (0x20)
				when 3 then Result := 128  -- Dot 8 (0x80)
				else
					Result := 0
				end
			end
		end

invariant
	cols_non_negative: cols >= 0
	rows_non_negative: rows >= 0
	valid_resolution: is_valid_resolution (dots_x, dots_y)
	braille_order_is_2_by_4: is_braille_order implies (dots_x = 2 and dots_y = 4)
	masks_allocated: masks /= Void
	styles_allocated: styles /= Void
	lower_styles_only_for_half_blocks: lower_styles.count = (if is_half_block_grid then styles.count else 0 end)

end
