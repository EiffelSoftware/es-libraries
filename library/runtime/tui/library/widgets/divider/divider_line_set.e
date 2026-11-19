note
	description: "[
		Line glyph sets for TUI_DIVIDER (plain, thick, double, dashed) and their glyphs.
		`plain`, `double` and `thick` have the values of the BORDER_TYPE constants of the same
		name, and their glyphs are BORDER_TYPE's line glyphs, so a divider matches the border
		of a block of that type. `dashed` is Ratatui's `line::LIGHT_DOUBLE_DASHED` (U+254C and
		U+254E), which BORDER_TYPE does not have. BORDER_TYPE's `rounded` has the plain line
		glyphs, so it is not a line set here.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	DIVIDER_LINE_SET

feature -- Constants

	plain: NATURAL_8 = 1
			-- Single line (─ │), as {BORDER_TYPE}.plain.

	double: NATURAL_8 = 3
			-- Double line (═ ║), as {BORDER_TYPE}.double.

	thick: NATURAL_8 = 4
			-- Heavy line (━ ┃), as {BORDER_TYPE}.thick.

	dashed: NATURAL_8 = 5
			-- Light double-dash line (╌ ╎), Ratatui `line::LIGHT_DOUBLE_DASHED`.

feature -- Glyphs

	horizontal (a_set: NATURAL_8): CHARACTER_32
			-- Glyph of a horizontal rule drawn with `a_set`.
		require
			valid_set: is_valid (a_set)
		do
			if a_set = dashed then
				Result := (0x254C).to_character_32 -- '╌'
			else
				Result := {BORDER_TYPE}.horizontal (a_set)
			end
		ensure
			instance_free: class
		end

	vertical (a_set: NATURAL_8): CHARACTER_32
			-- Glyph of a vertical rule drawn with `a_set`.
		require
			valid_set: is_valid (a_set)
		do
			if a_set = dashed then
				Result := (0x254E).to_character_32 -- '╎'
			else
				Result := {BORDER_TYPE}.vertical (a_set)
			end
		ensure
			instance_free: class
		end

feature -- Status report

	is_valid (a_set: NATURAL_8): BOOLEAN
			-- Is `a_set` a recognized divider line set?
		do
			Result := a_set = plain or a_set = double or a_set = thick or a_set = dashed
		ensure
			instance_free: class
		end

end
