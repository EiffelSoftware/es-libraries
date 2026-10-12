note
	description: "[
		Border drawing style types (plain, rounded, double, thick) and box glyph lookup.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	BORDER_TYPE

feature -- Constants

	plain: NATURAL_8 = 1
			-- Standard single-line box drawing characters (┌─┐│└─┘).

	rounded: NATURAL_8 = 2
			-- Rounded corner box drawing characters (╭─╮│╰─╯).

	double: NATURAL_8 = 3
			-- Double-line box drawing characters (╔═╗║╚═╝).

	thick: NATURAL_8 = 4
			-- Heavy/thick box drawing characters (┏━┓┃┗━┛).

feature -- Glyphs

	top_left (a_type: NATURAL_8): CHARACTER_32
			-- Top-left corner character for `a_type`.
		do
			inspect a_type
			when rounded then
				Result := (9581).to_character_32 -- '╭'
			when double then
				Result := (9556).to_character_32 -- '╔'
			when thick then
				Result := (9487).to_character_32 -- '┏'
			else
				Result := (9484).to_character_32 -- '┌'
			end
		ensure
			instance_free: class
		end

	top_right (a_type: NATURAL_8): CHARACTER_32
			-- Top-right corner character for `a_type`.
		do
			inspect a_type
			when rounded then
				Result := (9582).to_character_32 -- '╮'
			when double then
				Result := (9559).to_character_32 -- '╗'
			when thick then
				Result := (9491).to_character_32 -- '┓'
			else
				Result := (9488).to_character_32 -- '┐'
			end
		ensure
			instance_free: class
		end

	bottom_left (a_type: NATURAL_8): CHARACTER_32
			-- Bottom-left corner character for `a_type`.
		do
			inspect a_type
			when rounded then
				Result := (9584).to_character_32 -- '╰'
			when double then
				Result := (9562).to_character_32 -- '╚'
			when thick then
				Result := (9495).to_character_32 -- '┗'
			else
				Result := (9492).to_character_32 -- '└'
			end
		ensure
			instance_free: class
		end

	bottom_right (a_type: NATURAL_8): CHARACTER_32
			-- Bottom-right corner character for `a_type`.
		do
			inspect a_type
			when rounded then
				Result := (9583).to_character_32 -- '╯'
			when double then
				Result := (9565).to_character_32 -- '╝'
			when thick then
				Result := (9499).to_character_32 -- '┛'
			else
				Result := (9496).to_character_32 -- '┘'
			end
		ensure
			instance_free: class
		end

	horizontal (a_type: NATURAL_8): CHARACTER_32
			-- Horizontal line character for `a_type`.
		do
			inspect a_type
			when double then
				Result := (9552).to_character_32 -- '═'
			when thick then
				Result := (9473).to_character_32 -- '━'
			else
				Result := (9472).to_character_32 -- '─'
			end
		ensure
			instance_free: class
		end

	vertical (a_type: NATURAL_8): CHARACTER_32
			-- Vertical line character for `a_type`.
		do
			inspect a_type
			when double then
				Result := (9553).to_character_32 -- '║'
			when thick then
				Result := (9475).to_character_32 -- '┃'
			else
				Result := (9474).to_character_32 -- '│'
			end
		ensure
			instance_free: class
		end

feature -- Status report

	is_valid (a_type: NATURAL_8): BOOLEAN
			-- Is `a_type` a recognized border style type?
		do
			Result := a_type = plain or a_type = rounded or a_type = double or a_type = thick
		ensure
			instance_free: class
		end

end
