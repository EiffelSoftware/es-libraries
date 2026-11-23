note
	description: "[
		P1 item V7, the TUI_FILL widget (review/p1_visualization_plan.md).
		The `test_ratatui_*` cases are the tests of Ratatui ratatui-widgets/src/fill.rs, as
		row-exact buffer snapshots with the styles checked cell by cell.
		Coordinates: Ratatui writes buffer[(x, y)] and Rect::new (x, y, width, height); here
		cells are (row, column) and RECT.make (x, y, width, height).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_FILL

inherit
	BUFFER_TEST_HELPER

feature -- Ratatui fill.rs

	test_ratatui_fills_area_with_symbol_and_style
			-- Ratatui `fills_area_with_symbol_and_style`: "." in red on (1, 1, 3, 1) of an empty
			-- 5 x 3 buffer fills row 1, columns 1..3, and only those cells are red.
		local
			l_buf: BUFFER
		do
			create l_buf.make (5, 3)
			(create {TUI_FILL}.make (".")).with_style (create {STYLE}.make_fg ({COLOR}.Red)).render (create {RECT}.make (1, 1, 3, 1), l_buf)
			assert_buffer_lines ("filled", l_buf, <<"     ", " ... ", "     ">>)
			assert_styles ("filled", l_buf, <<[1, 1], [1, 2], [1, 3]>>, create {STYLE}.make_fg ({COLOR}.Red))
		end

	test_ratatui_clips_area_to_buffer
			-- Ratatui `clips_area_to_buffer`: an area running past the right and bottom edges of
			-- a 3 x 2 buffer is cut to the buffer.
		local
			l_buf: BUFFER
		do
			create l_buf.make (3, 2)
			(create {TUI_FILL}.make ("x")).render (create {RECT}.make (1, 1, 100, 100), l_buf)
			assert_buffer_lines ("clipped", l_buf, <<"   ", " xx">>)
			assert_styles ("clipped", l_buf, No_cells, create {STYLE})
		end

	test_ratatui_render_fully_out_of_bounds_is_noop
			-- Ratatui `render_fully_out_of_bounds_is_noop`: an area outside the buffer changes
			-- nothing.
		local
			l_buf: BUFFER
		do
			l_buf := buffer_with_lines (<<"xxxxx", "xxxxx", "xxxxx">>)
			(create {TUI_FILL}.make (".")).with_style (create {STYLE}.make_bg ({COLOR}.Red)).render (create {RECT}.make (100, 100, 5, 5), l_buf)
			assert_buffer_lines ("untouched", l_buf, <<"xxxxx", "xxxxx", "xxxxx">>)
			assert_styles ("untouched", l_buf, No_cells, create {STYLE})
				-- Just past the right and the bottom edge
			(create {TUI_FILL}.make (".")).render (create {RECT}.make (5, 0, 2, 3), l_buf)
			(create {TUI_FILL}.make (".")).render (create {RECT}.make (0, 3, 5, 2), l_buf)
			assert_buffer_lines ("edges untouched", l_buf, <<"xxxxx", "xxxxx", "xxxxx">>)
		end

	test_ratatui_renders_with_offset_buffer_area
			-- Ratatui `renders_with_offset_buffer_area`: Ratatui's buffer (2, 2, 2, 2) and area
			-- (0, 0, 4, 4) intersect in the whole buffer. A BUFFER always starts at (0, 0), so
			-- the same intersection is a 2 x 2 buffer under an area that covers it and runs past
			-- it: every cell is '#', with the default style.
		local
			l_buf: BUFFER
		do
			create l_buf.make (2, 2)
			(create {TUI_FILL}.make ("#")).render (create {RECT}.make (0, 0, 4, 4), l_buf)
			assert_buffer_lines ("covered", l_buf, <<"##", "##">>)
			assert_styles ("covered", l_buf, No_cells, create {STYLE})
				-- An area starting inside the buffer and covering its last cell only
			create l_buf.make (2, 2)
			(create {TUI_FILL}.make ("#")).render (create {RECT}.make (1, 1, 4, 4), l_buf)
			assert_buffer_lines ("corner", l_buf, <<"  ", " #">>)
		end

	test_ratatui_stylize_shorthand_works
			-- Ratatui `stylize_shorthand_works` (`.blue().bold()`): EiffelTUI has no Stylize
			-- shorthands, so the style is given with `with_style`. Both cells are blue and bold.
		local
			l_buf: BUFFER
			l_style: STYLE
		do
			create l_buf.make (2, 1)
			create l_style.make_fg ({COLOR}.Blue)
			l_style := l_style.with_bold;
			(create {TUI_FILL}.make ("*")).with_style (l_style).render (create {RECT}.make (0, 0, 2, 1), l_buf)
			assert_buffer_lines ("stars", l_buf, <<"**">>)
			assert_styles ("stars", l_buf, <<[0, 0], [0, 1]>>, l_style)
			assert ("bold", l_buf.cell (0, 1).style.is_bold)
		end

	test_ratatui_accepts_owned_string_symbol
			-- Ratatui `accepts_owned_string_symbol`: "•" (U+2022) given as a STRING_32, and also
			-- as an IMMUTABLE_STRING_32 and (ASCII) as a STRING_8.
		local
			l_buf: BUFFER
		do
			create l_buf.make (2, 1)
			(create {TUI_FILL}.make (create {STRING_32}.make_from_string ({STRING_32} "%/0x2022/"))).render (create {RECT}.make (0, 0, 2, 1), l_buf)
			assert_buffer_lines ("owned", l_buf, <<{STRING_32} "%/0x2022/%/0x2022/">>)
			create l_buf.make (2, 1)
			(create {TUI_FILL}.make (create {IMMUTABLE_STRING_32}.make_from_string_32 ({STRING_32} "%/0x2022/"))).render (create {RECT}.make (0, 0, 2, 1), l_buf)
			assert_buffer_lines ("immutable", l_buf, <<{STRING_32} "%/0x2022/%/0x2022/">>)
			create l_buf.make (2, 1)
			(create {TUI_FILL}.make (create {STRING_8}.make_filled ('o', 1))).render (create {RECT}.make (0, 0, 2, 1), l_buf)
			assert_buffer_lines ("string_8", l_buf, <<"oo">>)
		end

	test_ratatui_symbol_setter_replaces_symbol
			-- Ratatui `symbol_setter_replaces_symbol`: `with_symbol ("b")` on a fill of "a"
			-- paints "b". The original fill keeps "a"; `set_symbol` is the command twin.
		local
			l_buf: BUFFER
			l_a, l_b: TUI_FILL
		do
			create l_buf.make (2, 1)
			create l_a.make ("a")
			l_b := l_a.with_symbol ("b")
			l_b.render (create {RECT}.make (0, 0, 2, 1), l_buf)
			assert_buffer_lines ("b", l_buf, <<"bb">>)
			assert ("original kept", l_a.symbol.same_string ("a"))
			l_a.set_symbol ("c")
			l_a.render (create {RECT}.make (0, 0, 2, 1), l_buf)
			assert_buffer_lines ("c", l_buf, <<"cc">>)
		end

	test_ratatui_new_panics_on_empty_symbol
			-- Ratatui `new_panics_on_empty_symbol` and `symbol_panics_on_empty_symbol`: the
			-- empty symbol is refused by `make`, `set_symbol` and `with_symbol` (the
			-- precondition `valid_symbol`, Ratatui's panic).
		do
			assert ("make empty", precondition_raised (agent make_fill (""), "valid_symbol"))
			assert ("with_symbol empty", precondition_raised (agent (create {TUI_FILL}.make ("x")).with_symbol (""), "valid_symbol"))
			assert ("set_symbol empty", precondition_raised (agent (create {TUI_FILL}.make ("x")).set_symbol (""), "valid_symbol"))
			assert ("not valid", not {TUI_FILL}.is_valid_symbol (""))
		end

	test_ratatui_default_is_noop
			-- Ratatui `default_is_noop`: `default_create` has an empty symbol, and a red one
			-- changes nothing, neither the symbols nor the styles.
		local
			l_buf: BUFFER
			l_fill: TUI_FILL
		do
			l_buf := buffer_with_lines (<<"xxxxx">>)
			create l_fill
			assert ("empty symbol", l_fill.symbol.is_empty and l_fill.symbol_width = 0)
			l_fill.with_style (create {STYLE}.make_fg ({COLOR}.Red)).render (create {RECT}.make (1, 0, 3, 1), l_buf)
			assert_buffer_lines ("untouched", l_buf, <<"xxxxx">>)
			assert_styles ("untouched", l_buf, No_cells, create {STYLE})
		end

feature -- Symbols

	test_fill_symbol_validity
			-- The symbol is one grapheme cluster, one or two columns wide. Refused: a lone
			-- combining mark (U+0301), a zero-width joiner, a control (BEL, TAB), two clusters
			-- ("ab", "宽宽", "e" U+0301 "x"). Accepted: ASCII, "•", "宽" (U+5BBD), "e" + U+0301,
			-- a flag (two regional indicators) and "❤" + VS16.
		do
			assert ("combining refused", not {TUI_FILL}.is_valid_symbol ({STRING_32} "%/0x301/"))
			assert ("zwj refused", not {TUI_FILL}.is_valid_symbol ({STRING_32} "%/0x200D/"))
			assert ("bel refused", not {TUI_FILL}.is_valid_symbol ({STRING_32} "%/0x7/"))
			assert ("tab refused", not {TUI_FILL}.is_valid_symbol ("%T"))
			assert ("two refused", not {TUI_FILL}.is_valid_symbol ("ab"))
			assert ("two wide refused", not {TUI_FILL}.is_valid_symbol ({STRING_32} "%/0x5BBD/%/0x5BBD/"))
			assert ("cluster and more refused", not {TUI_FILL}.is_valid_symbol ({STRING_32} "e%/0x301/x"))
			assert ("ascii", {TUI_FILL}.is_valid_symbol ("x"))
			assert ("bullet", {TUI_FILL}.is_valid_symbol ({STRING_32} "%/0x2022/"))
			assert ("wide", {TUI_FILL}.is_valid_symbol ({STRING_32} "%/0x5BBD/"))
			assert ("combined", {TUI_FILL}.is_valid_symbol ({STRING_32} "e%/0x301/"))
			assert ("flag", {TUI_FILL}.is_valid_symbol ({STRING_32} "%/0x1F1EB/%/0x1F1F7/"))
			assert ("emoji vs16", {TUI_FILL}.is_valid_symbol ({STRING_32} "%/0x2764/%/0xFE0F/"))
			assert ("make combining refused", precondition_raised (agent make_fill ({STRING_32} "%/0x301/"), "valid_symbol"))
			assert ("make two refused", precondition_raised (agent make_fill ("ab"), "valid_symbol"))
			assert ("make wide accepted", not precondition_raised (agent make_fill ({STRING_32} "%/0x5BBD/"), "valid_symbol"))
			assert ("widths", (create {TUI_FILL}.make ("x")).symbol_width = 1
				and (create {TUI_FILL}.make ({STRING_32} "%/0x5BBD/")).symbol_width = 2
				and (create {TUI_FILL}.make ({STRING_32} "e%/0x301/")).symbol_width = 1)
		end

	test_fill_cluster_symbol
			-- A multi-code-point cluster fills each cell whole: "e" + U+0301 in every cell of
			-- (0, 0, 3, 1), one cluster per cell.
		local
			l_buf: BUFFER
			l_e: STRING_32
		do
			l_e := {STRING_32} "e%/0x301/"
			create l_buf.make (4, 1)
			(create {TUI_FILL}.make (l_e)).render (create {RECT}.make (0, 0, 3, 1), l_buf)
			assert_buffer_lines ("clusters", l_buf, <<l_e + l_e + l_e + " ">>)
			assert ("one cluster per cell", l_buf.cell (0, 1).symbol.same_string (l_e) and l_buf.cell (0, 1).width = 1)
		end

	test_fill_wide_symbol
			-- A wide symbol ("宽", U+5BBD) steps by two columns, and each copy gets its
			-- continuation cell (the snapshot shows a continuation cell as nothing):
			--  * an even area, (0, 0, 6, 1): three copies;
			--  * an odd area, (0, 1, 5, 1): two copies, and column 4 a blank in the fill's
			--    style; column 5 is outside and stays default;
			--  * cut at the buffer's right edge, (2, 2, 100, 1) on 7 columns: columns 2..6, so
			--    two copies and a blank in column 6;
			--  * a one-column area: a blank in the style.
			-- Every row stays continuation-consistent.
		local
			l_buf: BUFFER
			l_fill: TUI_FILL
			l_blue: STYLE
			l_w: STRING_32
		do
			l_w := {STRING_32} "%/0x5BBD/"
			create l_blue.make_bg ({COLOR}.Blue)
			l_fill := (create {TUI_FILL}.make (l_w)).with_style (l_blue)
			create l_buf.make (7, 4)
			l_fill.render (create {RECT}.make (0, 0, 6, 1), l_buf)
			l_fill.render (create {RECT}.make (0, 1, 5, 1), l_buf)
			l_fill.render (create {RECT}.make (2, 2, 100, 1), l_buf)
			l_fill.render (create {RECT}.make (3, 3, 1, 1), l_buf)
			assert_buffer_lines ("wide", l_buf, <<
				l_w + l_w + l_w + " ",
				l_w + l_w + "   ",
				{STRING_32} "  " + l_w + l_w + " ",
				"       ">>)
			assert ("consistent", l_buf.is_consistent)
			assert ("even: wide and continuation", l_buf.cell (0, 4).width = 2 and l_buf.cell (0, 5).is_continuation)
			assert ("odd: last column blank", l_buf.cell (1, 4).symbol.same_string (" ") and l_buf.cell (1, 4).width = 1)
			assert ("edge: last column blank", l_buf.cell (2, 6).symbol.same_string (" ") and not l_buf.cell (2, 6).is_continuation)
			assert_styles ("wide", l_buf, <<[0, 0], [0, 2], [0, 4], [1, 0], [1, 2], [1, 4], [2, 2], [2, 4], [2, 6], [3, 3]>>, l_blue)
		end

feature -- Styles and existing content

	test_fill_patches_cell_style
			-- `style` is patched over each cell's style (Ratatui `Cell::set_style`): a red
			-- foreground over yellow on blue and green on black keeps each background.
			-- The cells outside the area keep their symbols and styles.
		local
			l_buf: BUFFER
			l_yb, l_gk: STYLE
		do
			create l_yb.make_with_colors ({COLOR}.Yellow, {COLOR}.Blue)
			create l_gk.make_with_colors ({COLOR}.Green, {COLOR}.Black)
			create l_buf.make (6, 2)
			l_buf.put_string (0, 0, "abc", l_yb)
			l_buf.put_string (0, 3, "def", l_gk)
			l_buf.put_string (1, 0, "ghijkl", l_yb)
			(create {TUI_FILL}.make (".")).with_style (create {STYLE}.make_fg ({COLOR}.Red)).render (create {RECT}.make (1, 0, 4, 1), l_buf)
			assert_buffer_lines ("patched", l_buf, <<"a....f", "ghijkl">>)
			assert_cell_style ("outside left", l_buf, 0, 0, l_yb)
			assert_cell_style ("over yellow on blue", l_buf, 0, 1, create {STYLE}.make_with_colors ({COLOR}.Red, {COLOR}.Blue))
			assert_cell_style ("over yellow on blue 2", l_buf, 0, 2, create {STYLE}.make_with_colors ({COLOR}.Red, {COLOR}.Blue))
			assert_cell_style ("over green on black", l_buf, 0, 3, create {STYLE}.make_with_colors ({COLOR}.Red, {COLOR}.Black))
			assert_cell_style ("over green on black 2", l_buf, 0, 4, create {STYLE}.make_with_colors ({COLOR}.Red, {COLOR}.Black))
			assert_cell_style ("outside right", l_buf, 0, 5, l_gk)
			assert_cell_style ("next row", l_buf, 1, 2, l_yb)
				-- A reset colour clears the cell's colour, as STYLE.patch does
			(create {TUI_FILL}.make ("-")).with_style (create {STYLE}.make_bg ({COLOR}.Reset_color)).render (create {RECT}.make (0, 1, 2, 1), l_buf)
			assert_buffer_lines ("reset", l_buf, <<"a....f", "--ijkl">>)
			assert ("bg cleared", l_buf.cell (1, 0).style.background.is_default and l_buf.cell (1, 0).style.foreground ~ {COLOR}.Yellow)
		end

	test_fill_over_wide_characters
			-- "宽宽宽" in green on row 1 of a 6 x 3 buffer (columns 0-1, 2-3, 4-5), filled with
			-- "#" on a blue background in (1, 1, 4, 1), which cuts the first and the last
			-- character:
			--  * columns 1..4 are '#'; each takes the green of the character it covered and
			--    the blue background, also the right halves (columns 1 and 3);
			--  * columns 0 and 5, outside, become blanks that keep green, without blue.
			-- Then a wide fill over the row moved by one column, (1, 1, 5, 1), and over a
			-- narrow row. Every row stays continuation-consistent.
		local
			l_buf: BUFFER
			l_green, l_blue, l_green_blue: STYLE
			l_wide, l_w: STRING_32
			c: INTEGER
		do
			create l_green.make_fg ({COLOR}.Green)
			create l_blue.make_bg ({COLOR}.Blue)
			create l_green_blue.make_with_colors ({COLOR}.Green, {COLOR}.Blue)
			l_w := {STRING_32} "%/0x5BBD/"
			l_wide := l_w + l_w + l_w

			l_buf := wide_row_buffer (l_wide, l_green)
			(create {TUI_FILL}.make ("#")).with_style (l_blue).render (create {RECT}.make (1, 1, 4, 1), l_buf)
			assert_buffer_lines ("narrow over wide", l_buf, <<"      ", " #### ", "      ">>)
			assert ("narrow consistent", l_buf.is_consistent)
			assert_cell_style ("left half kept", l_buf, 1, 0, l_green)
			assert_cell_style ("right half kept", l_buf, 1, 5, l_green)
			from c := 1 until c > 4 loop
				assert_cell_style ("covered " + c.out, l_buf, 1, c, l_green_blue)
				c := c + 1
			end

				-- A wide fill one column right of the characters: columns 1-2, 3-4, and 5 blank
			l_buf := wide_row_buffer (l_wide, l_green)
			(create {TUI_FILL}.make (l_w)).with_style (l_blue).render (create {RECT}.make (1, 1, 5, 1), l_buf)
			assert_buffer_lines ("wide over wide", l_buf, <<"      ", {STRING_32} " " + l_w + l_w + " ", "      ">>)
			assert ("wide consistent", l_buf.is_consistent)
			assert_cell_style ("wide: left half kept", l_buf, 1, 0, l_green)
			assert_cell_style ("wide: first", l_buf, 1, 1, l_green_blue)
			assert_cell_style ("wide: second", l_buf, 1, 3, l_green_blue)
			assert_cell_style ("wide: blank", l_buf, 1, 5, l_green_blue)

				-- A wide fill over narrow text, the area's right edge inside a wide character
				-- that starts at its last column
			create l_buf.make (6, 1)
			l_buf.put_string (0, 0, "ab", l_green)
			l_buf.put_string (0, 2, l_w + l_w, l_green)
			(create {TUI_FILL}.make (l_w)).render (create {RECT}.make (0, 0, 3, 1), l_buf)
			assert_buffer_lines ("cut right", l_buf, <<l_w + "  " + l_w>>)
			assert ("cut consistent", l_buf.is_consistent)
			assert_cell_style ("cut: blank keeps green", l_buf, 0, 2, l_green)
			assert_cell_style ("cut: outside half keeps green", l_buf, 0, 3, l_green)
			assert ("cut: last wide kept", l_buf.cell (0, 4).width = 2 and l_buf.cell (0, 5).is_continuation)
		end

feature -- Comparison and copy

	test_fill_equality_and_copy
			-- `is_equal` compares the symbol and the style; `with_*` leave the original as it
			-- was; `twin` is equal.
		local
			l_a, l_b: TUI_FILL
			l_red: STYLE
		do
			create l_red.make_fg ({COLOR}.Red)
			create l_a.make ("x")
			create l_b.make ("x")
			assert ("equal", l_a ~ l_b)
			assert ("default style", l_a.style.is_equal (create {STYLE}))
			l_b := l_a.with_style (l_red)
			assert ("style differs", not (l_a ~ l_b))
			assert ("original style kept", l_a.style.is_equal (create {STYLE}))
			assert ("style set", l_b.style = l_red and l_b.symbol.same_string ("x"))
			assert ("equal styles", l_b ~ (create {TUI_FILL}.make ("x")).with_style (create {STYLE}.make_fg ({COLOR}.Red)))
			assert ("symbol differs", not (l_a ~ l_a.with_symbol ("y")))
			assert ("twin equal", l_b.twin ~ l_b)
			assert ("default equal", (create {TUI_FILL}) ~ (create {TUI_FILL}))
			assert ("default differs", not ((create {TUI_FILL}) ~ l_a))
			assert ("surrogate stored as U+FFFD", (create {TUI_FILL}.make (create {STRING_32}.make_filled ((0xD800).to_character_32, 1))).symbol.same_string ({STRING_32} "%/0xFFFD/"))
		end

feature {NONE} -- Helpers

	No_cells: ARRAY [TUPLE [row, col: INTEGER]]
			-- No cells, for `assert_styles` (a typed `<<>>`)
		once
			create Result.make_empty
		end

	assert_styles (a_tag: STRING; a_buf: BUFFER; a_cells: ARRAY [TUPLE [row, col: INTEGER]]; a_style: STYLE)
			-- The cells `a_cells` of `a_buf` have `a_style`; every other cell that is not a
			-- continuation cell has the default style.
		local
			r, c: INTEGER
			l_listed: BOOLEAN
		do
			from r := 0 until r >= a_buf.height loop
				from c := 0 until c >= a_buf.width loop
					l_listed := across a_cells as t some t.row = r and t.col = c end
					if l_listed then
						assert (a_tag + ": fill style " + r.out + "," + c.out, a_buf.cell (r, c).style.is_equal (a_style))
					elseif not a_buf.cell (r, c).is_continuation then
						assert (a_tag + ": default style " + r.out + "," + c.out, a_buf.cell (r, c).style.renders_as_default)
					end
					c := c + 1
				end
				r := r + 1
			end
		end

	buffer_with_lines (a_lines: ARRAY [READABLE_STRING_GENERAL]): BUFFER
			-- New buffer with `a_lines` as rows (Ratatui `Buffer::with_lines`)
		require
			not_empty: not a_lines.is_empty
		local
			i: INTEGER
		do
			create Result.make ({UNICODE_WIDTH}.string_width (a_lines [a_lines.lower]).to_integer_32, a_lines.count)
			from i := a_lines.lower until i > a_lines.upper loop
				Result.put_string (i - a_lines.lower, 0, a_lines [i], create {STYLE})
				i := i + 1
			end
		end

	wide_row_buffer (a_row: STRING_32; a_style: STYLE): BUFFER
			-- New 6 x 3 buffer with `a_row` on row 1 in `a_style`
		do
			create Result.make (6, 3)
			Result.put_string (1, 0, a_row, a_style)
		end

	make_fill (a_symbol: READABLE_STRING_GENERAL)
			-- Create a fill of `a_symbol` (for `precondition_raised`).
		local
			l_fill: TUI_FILL
		do
			create l_fill.make (a_symbol)
		end

	precondition_raised (a_action: ROUTINE; a_tag: STRING): BOOLEAN
			-- Does `a_action` raise a precondition violation tagged `a_tag`?
		local
			l_retried: BOOLEAN
		do
			if not l_retried then
				a_action.call
			end
		rescue
			if not l_retried then
				l_retried := True
				Result := attached (create {EXCEPTION_MANAGER}).last_exception as e and then
					(attached {PRECONDITION_VIOLATION} e.original as v and then
					(attached v.description as d and then d.same_string (a_tag)))
				retry
			end
		end

end
