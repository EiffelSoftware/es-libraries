note
	description: "[
		2D sub-pixel canvas for terminal character cell rendering.
		By default each cell holds 2 x 4 dots, encoded as Unicode Braille Patterns (U+2800..U+28FF);
		`make_with_resolution` gives other resolutions (1 x 2 for half blocks, 1 x 1 for dot, block
		and bar markers), whose cell masks use bit 1 for the (top) dot and bit 2 for the bottom one.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	BRAILLE_CANVAS

create
	make,
	make_with_resolution

feature {NONE} -- Initialization

	make (a_cols, a_rows: INTEGER)
			-- Initialize canvas of `a_cols` by `a_rows` terminal character cells.
		require
			positive_cols: a_cols >= 0
			positive_rows: a_rows >= 0
		do
			make_with_resolution (a_cols, a_rows, 2, 4)
		ensure
			cols_set: cols = a_cols
			rows_set: rows = a_rows
		end

	make_with_resolution (a_cols, a_rows, a_dots_x, a_dots_y: INTEGER)
			-- Initialize canvas of `a_cols` by `a_rows` cells, each `a_dots_x` by `a_dots_y` dots.
		require
			positive_cols: a_cols >= 0
			positive_rows: a_rows >= 0
			valid_resolution: (a_dots_x = 2 and a_dots_y = 4) or (a_dots_x = 1 and (a_dots_y = 1 or a_dots_y = 2))
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
		ensure
			cols_set: cols = a_cols
			rows_set: rows = a_rows
		end

feature -- Access

	cols: INTEGER
			-- Width in terminal character cells.

	rows: INTEGER
			-- Height in terminal character cells.

	dots_x, dots_y: INTEGER
			-- Dots per cell horizontally and vertically (2 x 4 for Braille)

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
			-- Braille bitmask for character cell (`a_col`, `a_row`).
		require
			valid_cell: is_cell_valid (a_col, a_row)
		do
			Result := masks.item (cell_index (a_col, a_row))
		end

	cell_style (a_col, a_row: INTEGER): STYLE
			-- Style for character cell (`a_col`, `a_row`).
		require
			valid_cell: is_cell_valid (a_col, a_row)
		do
			Result := styles.item (cell_index (a_col, a_row))
		end

	cell_char (a_col, a_row: INTEGER): CHARACTER_32
			-- Unicode Braille character (U+2800..U+28FF) or space if empty.
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
		require
			style_not_void: a_style /= Void
		local
			l_idx: INTEGER
			l_bit: NATURAL_8
		do
			if is_subpixel_valid (a_sx, a_sy) then
				l_idx := cell_index (a_sx // dots_x, a_sy // dots_y)
				l_bit := dot_bit (a_sx \\ dots_x, a_sy \\ dots_y)
				if color_policy = policy_first_wins and masks.item (l_idx) /= 0 then
					-- Retain first style
				else
					-- Last wins: the newest dot's style replaces the cell style
					styles.put (a_style, l_idx)
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
			-- Set style for cell (`a_col`, `a_row`).
		require
			valid_cell: is_cell_valid (a_col, a_row)
			style_not_void: a_style /= Void
		do
			styles.put (a_style, cell_index (a_col, a_row))
		ensure
			style_set: cell_style (a_col, a_row) = a_style
		end

	clear
			-- Clear all subpixels and styles.
		local
			l_default_style: STYLE
		do
			create l_default_style.default_create
			masks.fill_with (0, 0, masks.count - 1)
			styles.fill_with (l_default_style, 0, styles.count - 1)
		end

feature {NONE} -- Implementation

	masks: SPECIAL [NATURAL_8]
			-- Flat storage for cell dot masks.

	styles: SPECIAL [STYLE]
			-- Flat storage for cell styles.

	cell_index (a_col, a_row: INTEGER): INTEGER
			-- Flat 0-based index for (`a_col`, `a_row`).
		do
			Result := a_row * cols + a_col
		end

	dot_bit (a_dx, a_dy: INTEGER): NATURAL_8
			-- Unicode Braille dot bitmask for intra-cell subpixel offset `(a_dx, a_dy)`.
			-- `a_dx` in 0..1, `a_dy` in 0..3.
		do
			if dots_x = 1 then
				-- 1 x 1 and 1 x 2 cells: bit 1 = top dot, bit 2 = bottom dot
				Result := (1 |<< a_dy).to_natural_8
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
	valid_resolution: (dots_x = 2 and dots_y = 4) or (dots_x = 1 and (dots_y = 1 or dots_y = 2))
	masks_allocated: masks /= Void
	styles_allocated: styles /= Void

end
