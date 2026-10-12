note
	description: "[
		Named glyph constants for plotting markers, indicators, and list symbols.
		Matches Ratatui `symbols::marker`.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

expanded class
	SYMBOLS_MARKER

feature -- Common Markers

	dot: CHARACTER_32 = '%/0x2022/'
			-- Bullet dot '•'

	block: CHARACTER_32 = '%/0x25A0/'
			-- Black square block '■'

	bar: CHARACTER_32 = '|'
			-- Vertical bar '|'

	half_block: CHARACTER_32 = '%/0x2580/'
			-- Upper half block '▀'

	braille: CHARACTER_32 = '%/0x283F/'
			-- Full 6-dot braille pattern '⠿'

	empty_square: CHARACTER_32 = '%/0x25A1/'
			-- White square '□'

	diamond: CHARACTER_32 = '%/0x25C6/'
			-- Black diamond '◆'

	empty_diamond: CHARACTER_32 = '%/0x25C7/'
			-- White diamond '◇'

	triangle_up: CHARACTER_32 = '%/0x25B2/'
			-- Up-pointing triangle '▲'

	triangle_down: CHARACTER_32 = '%/0x25BC/'
			-- Down-pointing triangle '▼'

	cross: CHARACTER_32 = '%/0x2716/'
			-- Heavy cross mark '✖'

	check_mark: CHARACTER_32 = '%/0x2714/'
			-- Check mark '✔'

end
