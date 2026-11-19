note
	description: "[
		Named glyph constants for legends, indicators and list symbols (bullets, squares,
		diamonds, triangles, check marks).

		These are not the canvas marker symbols: a canvas or chart draws the symbols of
		CANVAS_MARKER (`marker_symbol`), and a sparkline has glyphs of its own. Only `dot` is the same ('•', Ratatui `symbols::DOT`);
		`block`, `bar`, `half_block` and `braille` here are single glyphs for text and differ from
		what those markers draw (Bar draws '▄', Block '█', Braille a dot pattern per cell).
		Ratatui `symbols::marker` has only `DOT` and the `Marker` enum; the rest of this class is
		EiffelTUI's own.

		An expanded class of class features, called as `{SYMBOLS_MARKER}.dot`. EiffelStudio
		26.09 has an incremental compilation bug: a melted build crashes at start when melted
		code is the first to use an expanded class. Freeze after such a change (see the V1 melt
		crash notes in review/p1_visualization_plan.md).
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
			-- Black square block '■' (a list or legend glyph; the Block canvas marker draws '█')

	bar: CHARACTER_32 = '|'
			-- Vertical bar '|' (a list or legend glyph; the Bar canvas marker draws '▄')

	half_block: CHARACTER_32 = '%/0x2580/'
			-- Upper half block '▀'

	braille: CHARACTER_32 = '%/0x283F/'
			-- Full 6-dot braille pattern '⠿' (a list or legend glyph; the Braille canvas marker
			-- draws the dots of each cell)

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
