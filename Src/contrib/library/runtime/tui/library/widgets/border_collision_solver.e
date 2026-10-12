note
	description: "[
		Border collision and junction engine (mirroring Ratatui symbols::merge).
		Uses a 4-bit directional connectivity model (Up, Right, Down, Left) to
		fuse intersecting border lines, corners, and T-junctions into seamless
		composite box-drawing characters. Junctions keep the line family of the
		borders they join (single/rounded → single, thick, double); borders of
		different families meet with single-line junctions. Only box-drawing
		characters take part: text such as '-', '|' or '+' is never merged.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	BORDER_COLLISION_SOLVER

feature -- Connectivity Bits

	up_bit: NATURAL_8 = 1      -- Direction: North (Up)
	right_bit: NATURAL_8 = 2   -- Direction: East (Right)
	down_bit: NATURAL_8 = 4    -- Direction: South (Down)
	left_bit: NATURAL_8 = 8    -- Direction: West (Left)

feature -- Symbol Analysis

	is_border_char (a_char: CHARACTER_32): BOOLEAN
			-- Is `a_char` a recognized box-drawing or border character?
		do
			Result := connections_from_char (a_char) /= 0
		end

	connections_from_char (a_char: CHARACTER_32): NATURAL_8
			-- 4-bit directional connectivity mask for `a_char`.
		local
			c: INTEGER
		do
			c := a_char.code
			inspect c
				-- Plain Single Lines & Corners
			when 9472 then Result := 10 -- '─' (Left | Right)
			when 9474 then Result := 5  -- '│' (Up | Down)
			when 9484 then Result := 6  -- '┌' (Down | Right)
			when 9488 then Result := 12 -- '┐' (Down | Left)
			when 9492 then Result := 3  -- '└' (Up | Right)
			when 9496 then Result := 9  -- '┘' (Up | Left)
			when 9500 then Result := 7  -- '├' (Up | Down | Right)
			when 9508 then Result := 13 -- '┤' (Up | Down | Left)
			when 9516 then Result := 14 -- '┬' (Left | Right | Down)
			when 9524 then Result := 11 -- '┴' (Left | Right | Up)
			when 9532 then Result := 15 -- '┼' (Up | Down | Left | Right)

				-- Rounded Corners
			when 9581 then Result := 6  -- '╭' (Down | Right)
			when 9582 then Result := 12 -- '╮' (Down | Left)
			when 9583 then Result := 9  -- '╯' (Up | Left)
			when 9584 then Result := 3  -- '╰' (Up | Right)

				-- Heavy / Thick Lines
			when 9473 then Result := 10 -- '━'
			when 9475 then Result := 5  -- '┃'
			when 9487 then Result := 6  -- '┏'
			when 9491 then Result := 12 -- '┓'
			when 9495 then Result := 3  -- '┗'
			when 9499 then Result := 9  -- '┛'
			when 9507 then Result := 7  -- '┣'
			when 9515 then Result := 13 -- '┫'
			when 9523 then Result := 14 -- '┳'
			when 9531 then Result := 11 -- '┻'
			when 9547 then Result := 15 -- '╋'

				-- Double Lines
			when 9552 then Result := 10 -- '═'
			when 9553 then Result := 5  -- '║'
			when 9556 then Result := 6  -- '╔'
			when 9559 then Result := 12 -- '╗'
			when 9562 then Result := 3  -- '╚'
			when 9565 then Result := 9  -- '╝'
			when 9568 then Result := 7  -- '╠'
			when 9571 then Result := 13 -- '╣'
			when 9574 then Result := 14 -- '╦'
			when 9577 then Result := 11 -- '╩'
			when 9580 then Result := 15 -- '╬'


			else
				Result := 0
			end
		end

	char_from_connections (a_mask: NATURAL_8): CHARACTER_32
			-- Unicode box-drawing character corresponding to 4-bit `a_mask`.
		do
			inspect a_mask
			when 10 then Result := (9472).to_character_32 -- '─'
			when 5  then Result := (9474).to_character_32 -- '│'
			when 6  then Result := (9484).to_character_32 -- '┌'
			when 12 then Result := (9488).to_character_32 -- '┐'
			when 3  then Result := (9492).to_character_32 -- '└'
			when 9  then Result := (9496).to_character_32 -- '┘'
			when 7  then Result := (9500).to_character_32 -- '├'
			when 13 then Result := (9508).to_character_32 -- '┤'
			when 14 then Result := (9516).to_character_32 -- '┬'
			when 11 then Result := (9524).to_character_32 -- '┴'
			when 15 then Result := (9532).to_character_32 -- '┼'
				-- Single stub ends
			when 1  then Result := (9474).to_character_32 -- Up only
			when 2  then Result := (9472).to_character_32 -- Right only
			when 4  then Result := (9474).to_character_32 -- Down only
			when 8  then Result := (9472).to_character_32 -- Left only
			else
				Result := ' '
			end
		end

feature -- Merging Operations

	merge_symbols (a_char1, a_char2: CHARACTER_32): CHARACTER_32
			-- Merge two intersecting border symbols into a unified junction symbol.
		local
			m1, m2: NATURAL_8
		do
			m1 := connections_from_char (a_char1)
			m2 := connections_from_char (a_char2)
			if m1 = 0 then
				Result := a_char2
			elseif m2 = 0 then
				Result := a_char1
			elseif m1 | m2 = m2 then
				-- The new symbol already has every connection: keep it (e.g. a rounded corner)
				Result := a_char2
			elseif m1 | m2 = m1 then
				Result := a_char1
			elseif line_family (a_char1) = line_family (a_char2) then
				Result := char_from_connections_in (m1 | m2, line_family (a_char1))
			else
				Result := char_from_connections (m1 | m2)
			end
		end

	line_family (a_char: CHARACTER_32): INTEGER
			-- Line family of box-drawing `a_char`: `Family_single` (plain and rounded),
			-- `Family_thick` or `Family_double`; 0 when it is not a border character.
		do
			inspect a_char.code
			when 9472, 9474, 9484, 9488, 9492, 9496, 9500, 9508, 9516, 9524, 9532, 9581 .. 9584 then
				Result := Family_single
			when 9473, 9475, 9487, 9491, 9495, 9499, 9507, 9515, 9523, 9531, 9547 then
				Result := Family_thick
			when 9552, 9553, 9556, 9559, 9562, 9565, 9568, 9571, 9574, 9577, 9580 then
				Result := Family_double
			else
				Result := 0
			end
		end

	char_from_connections_in (a_mask: NATURAL_8; a_family: INTEGER): CHARACTER_32
			-- Box-drawing character of line family `a_family` for 4-bit `a_mask`
			-- (single-line glyph for `Family_single` or an unknown family).
		local
			l_code: INTEGER
		do
			if a_family = Family_thick then
				inspect a_mask
				when 10, 2, 8 then l_code := 9473 -- '━'
				when 5, 1, 4 then l_code := 9475 -- '┃'
				when 6 then l_code := 9487  -- '┏'
				when 12 then l_code := 9491 -- '┓'
				when 3 then l_code := 9495  -- '┗'
				when 9 then l_code := 9499  -- '┛'
				when 7 then l_code := 9507  -- '┣'
				when 13 then l_code := 9515 -- '┫'
				when 14 then l_code := 9523 -- '┳'
				when 11 then l_code := 9531 -- '┻'
				when 15 then l_code := 9547 -- '╋'
				else
					l_code := 32
				end
				Result := l_code.to_character_32
			elseif a_family = Family_double then
				inspect a_mask
				when 10, 2, 8 then l_code := 9552 -- '═'
				when 5, 1, 4 then l_code := 9553 -- '║'
				when 6 then l_code := 9556  -- '╔'
				when 12 then l_code := 9559 -- '╗'
				when 3 then l_code := 9562  -- '╚'
				when 9 then l_code := 9565  -- '╝'
				when 7 then l_code := 9568  -- '╠'
				when 13 then l_code := 9571 -- '╣'
				when 14 then l_code := 9574 -- '╦'
				when 11 then l_code := 9577 -- '╩'
				when 15 then l_code := 9580 -- '╬'
				else
					l_code := 32
				end
				Result := l_code.to_character_32
			else
				Result := char_from_connections (a_mask)
			end
		end

	Family_single: INTEGER = 1
	Family_thick: INTEGER = 2
	Family_double: INTEGER = 3
			-- Line families

	merge_into_buffer (a_buffer: BUFFER; a_row, a_col: INTEGER; a_char: CHARACTER_32; a_style: STYLE)
			-- Put `a_char` into `a_buffer` at (`a_row`, `a_col`), merging with any existing border.
		require
			buffer_not_void: a_buffer /= Void
			style_not_void: a_style /= Void
		local
			l_existing: CHARACTER_32
			l_merged: CHARACTER_32
			l_cell: TERMINAL_CELL
		do
			if a_row >= 0 and a_row < a_buffer.height and a_col >= 0 and a_col < a_buffer.width then
				l_cell := a_buffer.cell (a_row, a_col)
				if l_cell.symbol.count > 0 then
					l_existing := l_cell.symbol.item (1)
				else
					l_existing := ' '
				end
				l_merged := merge_symbols (l_existing, a_char)
				a_buffer.put_char (a_row, a_col, l_merged, l_cell.style.patch (a_style))
			end
		end

	fuse_touching_blocks (a_buffer: BUFFER; a_rect1, a_rect2: RECT; a_style: STYLE)
			-- Fuse shared border edges of touching rectangular blocks `a_rect1` and `a_rect2`.
		require
			buffer_not_void: a_buffer /= Void
			r1_not_void: a_rect1 /= Void
			r2_not_void: a_rect2 /= Void
			style_not_void: a_style /= Void
		local
			r, c: INTEGER
			l_x, l_y: INTEGER
		do
			-- Check horizontal sharing: a_rect1's right edge touches a_rect2's left edge
			if a_rect1.right = a_rect2.x then
				l_x := a_rect1.right.to_integer_32 - 1
				from
					r := a_rect1.y.to_integer_32.max (a_rect2.y.to_integer_32)
				until
					r >= a_rect1.bottom.to_integer_32.min (a_rect2.bottom.to_integer_32)
				loop
					merge_into_buffer (a_buffer, r, l_x, (9474).to_character_32, a_style)
					r := r + 1
				end
			end

			-- Check vertical sharing: a_rect1's bottom edge touches a_rect2's top edge
			if a_rect1.bottom = a_rect2.y then
				l_y := a_rect1.bottom.to_integer_32 - 1
				from
					c := a_rect1.x.to_integer_32.max (a_rect2.x.to_integer_32)
				until
					c >= a_rect1.right.to_integer_32.min (a_rect2.right.to_integer_32)
				loop
					merge_into_buffer (a_buffer, l_y, c, (9472).to_character_32, a_style)
					c := c + 1
				end
			end
		end

end
