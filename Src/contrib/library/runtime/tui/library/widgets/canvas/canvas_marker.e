note
	description: "[
		Marker types for canvas and chart rendering (Braille, Dot, Block, HalfBlock, Bar,
		Quadrant, Sextant, Octant, Custom), and the grid resolution of each (Ratatui `marker_to_grid`).
		Custom (Ratatui `Marker::Custom (char)`) is a 1 x 1 grid: the widget that uses it holds the
		character (`is_valid_custom_char`), since a marker constant cannot carry one.
		`marker_symbol` is the character a canvas draws for the Dot, Block and Bar markers, as
		Ratatui `Canvas::render` gives its `CharGrid`. SYMBOLS_MARKER is a separate set of legend and
		list glyphs, not the canvas symbols.
		Sextant and Octant need a font with "Symbols for Legacy Computing (Supplement)"; see
		SYMBOLS_PIXEL.
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
			-- Dot symbol ('•', U+2022, Ratatui `symbols::DOT`).

	block: NATURAL_8 = 3
			-- Full block symbol ('█', U+2588, Ratatui `symbols::block::FULL`).

	half_block: NATURAL_8 = 4
			-- Half blocks, 1 x 2 pseudo-pixels per cell: '▀', '▄' or '█' (U+2580, U+2584, U+2588).

	bar: NATURAL_8 = 5
			-- Lower half block symbol ('▄', U+2584, Ratatui `symbols::bar::HALF`).

	quadrant: NATURAL_8 = 6
			-- Quadrant characters, 2 x 2 pseudo-pixels per cell (U+2596..U+259F).

	sextant: NATURAL_8 = 7
			-- Sextant characters, 2 x 3 pseudo-pixels per cell (U+1FB00..U+1FB3B).

	octant: NATURAL_8 = 8
			-- Octant characters, 2 x 4 pseudo-pixels per cell (U+1CD00..U+1CDE5).

	custom: NATURAL_8 = 9
			-- One character of the user's choice per painted cell, 1 x 1 (Ratatui `Marker::Custom`).

	default_custom_char: CHARACTER_32 = '%/0x2022/'
			-- Character of a Custom marker when none was given ('•', as the Dot marker).

	blank_braille: CHARACTER_32 = '%/0x2800/'
			-- Symbol of the Braille and pattern markers (U+2800, no dots): one column wide, but blank.

feature -- Conversion

	marker_symbol (a_marker: NATURAL_8): CHARACTER_32
			-- Character corresponding to `a_marker`: the one a canvas draws in each painted cell for
			-- Dot, Block and Bar (Ratatui `Canvas::render`). HalfBlock gives its upper half '▀'; a
			-- canvas picks '▀', '▄' or '█' per cell (Ratatui `HalfBlockGrid`). Custom gives
			-- `default_custom_char`, and Braille and the pattern markers `blank_braille`.
		do
			inspect a_marker
			when dot then
				Result := (0x2022).to_character_32 -- '•' (Ratatui `symbols::DOT`)
			when block then
				Result := (0x2588).to_character_32 -- '█' (Ratatui `symbols::block::FULL`)
			when half_block then
				Result := (0x2580).to_character_32 -- '▀' (Ratatui `symbols::half_block::UPPER`)
			when bar then
				Result := (0x2584).to_character_32 -- '▄' (Ratatui `symbols::bar::HALF`)
			when custom then
				Result := default_custom_char
			else
				Result := blank_braille
			end
		ensure
			instance_free: class
		end

	is_valid (a_marker: NATURAL_8): BOOLEAN
			-- Is `a_marker` a valid marker constant?
		do
			Result := a_marker >= braille and a_marker <= custom
		ensure
			instance_free: class
		end

	is_valid_custom_char (a_char: CHARACTER_32): BOOLEAN
			-- Can `a_char` be the character of a Custom marker: one column wide, and not `blank_braille`?
			-- (A wider one would spill into the next cell; a zero-width one would draw nothing, and so
			-- would `blank_braille`, which `marker_symbol` gives the Braille and pattern markers.)
		do
			Result := {UNICODE_WIDTH}.width (a_char.natural_32_code) = 1 and a_char /= blank_braille
		ensure
			instance_free: class
		end

	is_pattern (a_marker: NATURAL_8): BOOLEAN
			-- Does `a_marker` draw pseudo-pixel patterns in row-major bit order (Quadrant, Sextant, Octant)?
		do
			Result := a_marker = quadrant or a_marker = sextant or a_marker = octant
		ensure
			instance_free: class
		end

feature -- Resolution

	dots_x (a_marker: NATURAL_8): INTEGER
			-- Dots per cell horizontally on a grid for `a_marker`.
		require
			valid_marker: is_valid (a_marker)
		do
			if a_marker = braille or is_pattern (a_marker) then
				Result := 2
			else
				Result := 1
			end
		ensure
			instance_free: class
		end

	dots_y (a_marker: NATURAL_8): INTEGER
			-- Dots per cell vertically on a grid for `a_marker`.
		require
			valid_marker: is_valid (a_marker)
		do
			inspect a_marker
			when braille, octant then
				Result := 4
			when sextant then
				Result := 3
			when quadrant, half_block then
				Result := 2
			else
				Result := 1
			end
		ensure
			instance_free: class
		end

end
