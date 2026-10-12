note
	description: "[
		Named vertical and horizontal fractional Unicode bar glyphs and level sets (U+2581..U+258F).
		Matches Ratatui `symbols::bar`.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

expanded class
	SYMBOLS_BAR

feature -- Vertical Bar Glyphs

	empty: CHARACTER_32 = ' '
			-- Empty space (0/8)

	one_eighth: CHARACTER_32 = '%/0x2581/'
			-- Lower one-eighth block (1/8)

	one_quarter: CHARACTER_32 = '%/0x2582/'
			-- Lower one-quarter block (2/8)

	three_eighths: CHARACTER_32 = '%/0x2583/'
			-- Lower three-eighths block (3/8)

	half: CHARACTER_32 = '%/0x2584/'
			-- Lower half block (4/8)

	five_eighths: CHARACTER_32 = '%/0x2585/'
			-- Lower five-eighths block (5/8)

	three_quarters: CHARACTER_32 = '%/0x2586/'
			-- Lower three-quarters block (6/8)

	seven_eighths: CHARACTER_32 = '%/0x2587/'
			-- Lower seven-eighths block (7/8)

	full: CHARACTER_32 = '%/0x2588/'
			-- Full solid block (8/8)

	vertical_full: CHARACTER_32
			-- Full solid block (synonym for full)
		do
			Result := full
		end

	vertical_bar (a_level: INTEGER): CHARACTER_32
			-- Vertical bar glyph for level 1..8.
		require
			valid_level: a_level >= 1 and a_level <= 8
		do
			inspect a_level
			when 1 then Result := one_eighth
			when 2 then Result := one_quarter
			when 3 then Result := three_eighths
			when 4 then Result := half
			when 5 then Result := five_eighths
			when 6 then Result := three_quarters
			when 7 then Result := seven_eighths
			else Result := full
			end
		end

feature -- Horizontal Bar Glyphs (Left to Right)

	horizontal_one_eighth: CHARACTER_32 = '%/0x258F/'
			-- Left one-eighth block (1/8)

	horizontal_one_quarter: CHARACTER_32 = '%/0x258E/'
			-- Left one-quarter block (2/8)

	horizontal_three_eighths: CHARACTER_32 = '%/0x258D/'
			-- Left three-eighths block (3/8)

	horizontal_half: CHARACTER_32 = '%/0x258C/'
			-- Left half block (4/8)

	horizontal_five_eighths: CHARACTER_32 = '%/0x258B/'
			-- Left five-eighths block (5/8)

	horizontal_three_quarters: CHARACTER_32 = '%/0x258A/'
			-- Left three-quarters block (6/8)

	horizontal_seven_eighths: CHARACTER_32 = '%/0x2589/'
			-- Left seven-eighths block (7/8)

	horizontal_full: CHARACTER_32 = '%/0x2588/'
			-- Full solid block (8/8)

feature -- Sets and Ratios

	vertical_bar_for_ratio (a_ratio: REAL_64): CHARACTER_32
			-- Vertical bar glyph corresponding to `a_ratio` in 0.0..1.0.
		local
			l_clamped: REAL_64
			l_idx: INTEGER
		do
			l_clamped := a_ratio.max (0.0).min (1.0)
			l_idx := (l_clamped * 8.0).floor.to_integer_32
			inspect l_idx
			when 0 then
				Result := empty
			when 1 then
				Result := one_eighth
			when 2 then
				Result := one_quarter
			when 3 then
				Result := three_eighths
			when 4 then
				Result := half
			when 5 then
				Result := five_eighths
			when 6 then
				Result := three_quarters
			when 7 then
				Result := seven_eighths
			else
				Result := full
			end
		end

	horizontal_bar_for_ratio (a_ratio: REAL_64): CHARACTER_32
			-- Horizontal bar glyph corresponding to `a_ratio` in 0.0..1.0.
		local
			l_clamped: REAL_64
			l_idx: INTEGER
		do
			l_clamped := a_ratio.max (0.0).min (1.0)
			l_idx := (l_clamped * 8.0).floor.to_integer_32
			inspect l_idx
			when 0 then
				Result := empty
			when 1 then
				Result := horizontal_one_eighth
			when 2 then
				Result := horizontal_one_quarter
			when 3 then
				Result := horizontal_three_eighths
			when 4 then
				Result := horizontal_half
			when 5 then
				Result := horizontal_five_eighths
			when 6 then
				Result := horizontal_three_quarters
			when 7 then
				Result := horizontal_seven_eighths
			else
				Result := horizontal_full
			end
		end

end
