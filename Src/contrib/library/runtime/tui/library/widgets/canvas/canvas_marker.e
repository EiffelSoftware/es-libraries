note
	description: "[
		Marker types for canvas and chart rendering (Braille, Dot, Block, HalfBlock, Bar).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	CANVAS_MARKER

feature -- Constants

	braille: NATURAL_8 = 1
			-- Braille sub-pixel dot patterns (default).

	dot: NATURAL_8 = 2
			-- Dot symbol ('•', U+2022).

	block: NATURAL_8 = 3
			-- Full block symbol ('█', U+2588).

	half_block: NATURAL_8 = 4
			-- Half block symbol ('▀', U+2580).

	bar: NATURAL_8 = 5
			-- Vertical bar symbol ('┃', U+2503).

feature -- Conversion

	marker_symbol (a_marker: NATURAL_8): CHARACTER_32
			-- Character corresponding to `a_marker`.
		do
			inspect a_marker
			when dot then
				Result := (8226).to_character_32 -- '•'
			when block then
				Result := (9608).to_character_32 -- '█'
			when half_block then
				Result := (9600).to_character_32 -- '▀'
			when bar then
				Result := (9475).to_character_32 -- '┃'
			else
				Result := (10240).to_character_32 -- Blank Braille U+2800
			end
		ensure
			instance_free: class
		end

	is_valid (a_marker: NATURAL_8): BOOLEAN
			-- Is `a_marker` a valid marker constant?
		do
			Result := a_marker >= braille and a_marker <= bar
		ensure
			instance_free: class
		end

end
