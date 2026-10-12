note
	description: "[
		Named Unicode block characters: full block, half blocks, quadrant blocks, and shades.
		Matches Ratatui `symbols::block`.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

expanded class
	SYMBOLS_BLOCK

feature -- Solid and Half Blocks

	full: CHARACTER_32 = '%/0x2588/'
			-- Full solid block '█'

	upper_half: CHARACTER_32 = '%/0x2580/'
			-- Upper half block '▀'

	lower_half: CHARACTER_32 = '%/0x2584/'
			-- Lower half block '▄'

	left_half: CHARACTER_32 = '%/0x258C/'
			-- Left half block '▌'

	right_half: CHARACTER_32 = '%/0x2590/'
			-- Right half block '▐'

feature -- Quadrant Blocks

	quadrant_lower_left: CHARACTER_32 = '%/0x2596/'
			-- Quadrant lower left '▖'

	quadrant_lower_right: CHARACTER_32 = '%/0x2597/'
			-- Quadrant lower right '▗'

	quadrant_upper_left: CHARACTER_32 = '%/0x2598/'
			-- Quadrant upper left '▘'

	quadrant_upper_right: CHARACTER_32 = '%/0x259D/'
			-- Quadrant upper right '▝'

	quadrant_upper_left_lower_left_lower_right: CHARACTER_32 = '%/0x2599/'
			-- Quadrant upper-left, lower-left and lower-right '▙'

	quadrant_upper_left_lower_right: CHARACTER_32 = '%/0x259A/'
			-- Quadrant upper-left and lower-right '▚'

	quadrant_upper_left_upper_right_lower_left: CHARACTER_32 = '%/0x259B/'
			-- Quadrant upper-left, upper-right and lower-left '▛'

	quadrant_upper_left_upper_right_lower_right: CHARACTER_32 = '%/0x259C/'
			-- Quadrant upper-left, upper-right and lower-right '▜'

	quadrant_upper_right_lower_left: CHARACTER_32 = '%/0x259E/'
			-- Quadrant upper-right and lower-left '▞'

	quadrant_upper_right_lower_left_lower_right: CHARACTER_32 = '%/0x259F/'
			-- Quadrant upper-right, lower-left and lower-right '▟'

feature -- Shades

	light_shade: CHARACTER_32 = '%/0x2591/'
			-- Light shade '░' (25% fill)

	medium_shade: CHARACTER_32 = '%/0x2592/'
			-- Medium shade '▒' (50% fill)

	dark_shade: CHARACTER_32 = '%/0x2593/'
			-- Dark shade '▓' (75% fill)

end
