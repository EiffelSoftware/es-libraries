note
	description: "[
		Per-side border glyph set (top_left, top_right, bottom_left, bottom_right,
		top, bottom, left, right).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	BORDER_SET

inherit
	ANY
		redefine
			is_equal
		end

create
	make,
	make_plain,
	make_rounded,
	make_double,
	make_thick

feature {NONE} -- Initialization

	make (
		a_tl, a_tr, a_bl, a_br: CHARACTER_32;
		a_top, a_bottom, a_left, a_right: CHARACTER_32
	)
			-- Initialize border set with explicit characters.
		do
			top_left := a_tl
			top_right := a_tr
			bottom_left := a_bl
			bottom_right := a_br
			top := a_top
			bottom := a_bottom
			left := a_left
			right := a_right
		ensure
			tl_set: top_left = a_tl
			tr_set: top_right = a_tr
			bl_set: bottom_left = a_bl
			br_set: bottom_right = a_br
			top_set: top = a_top
			bottom_set: bottom = a_bottom
			left_set: left = a_left
			right_set: right = a_right
		end

	make_plain
			-- Standard single-line box drawing border set (┌─┐│└─┘).
		do
			make (
				(9484).to_character_32, -- '┌'
				(9488).to_character_32, -- '┐'
				(9492).to_character_32, -- '└'
				(9496).to_character_32, -- '┘'
				(9472).to_character_32, -- '─'
				(9472).to_character_32, -- '─'
				(9474).to_character_32, -- '│'
				(9474).to_character_32  -- '│'
			)
		end

	make_rounded
			-- Rounded corner box drawing border set (╭─╮│╰─╯).
		do
			make (
				(9581).to_character_32, -- '╭'
				(9582).to_character_32, -- '╮'
				(9584).to_character_32, -- '╰'
				(9583).to_character_32, -- '╯'
				(9472).to_character_32, -- '─'
				(9472).to_character_32, -- '─'
				(9474).to_character_32, -- '│'
				(9474).to_character_32  -- '│'
			)
		end

	make_double
			-- Double-line box drawing border set (╔═╗║╚═╝).
		do
			make (
				(9556).to_character_32, -- '╔'
				(9559).to_character_32, -- '╗'
				(9562).to_character_32, -- '╚'
				(9565).to_character_32, -- '╝'
				(9552).to_character_32, -- '═'
				(9552).to_character_32, -- '═'
				(9553).to_character_32, -- '║'
				(9553).to_character_32  -- '║'
			)
		end

	make_thick
			-- Thick/heavy box drawing border set (┏━┓┃┗━┛).
		do
			make (
				(9487).to_character_32, -- '┏'
				(9491).to_character_32, -- '┓'
				(9495).to_character_32, -- '┗'
				(9499).to_character_32, -- '┛'
				(9473).to_character_32, -- '━'
				(9473).to_character_32, -- '━'
				(9475).to_character_32, -- '┃'
				(9475).to_character_32  -- '┃'
			)
		end

feature -- Access

	top_left: CHARACTER_32
	top_right: CHARACTER_32
	bottom_left: CHARACTER_32
	bottom_right: CHARACTER_32
	top: CHARACTER_32
	bottom: CHARACTER_32
	left: CHARACTER_32
	right: CHARACTER_32

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Is `a_other` equal to `Current`?
		do
			if a_other = Current then
				Result := True
			else
				Result := top_left = a_other.top_left
					and top_right = a_other.top_right
					and bottom_left = a_other.bottom_left
					and bottom_right = a_other.bottom_right
					and top = a_other.top
					and bottom = a_other.bottom
					and left = a_other.left
					and right = a_other.right
			end
		end

end
