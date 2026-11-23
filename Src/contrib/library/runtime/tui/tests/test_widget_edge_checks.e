note
	description: "[
		P1 X4: checks against three Ratatui 0.30.1 fixes at the edges of widths and areas
		(`ratatui-core/src/buffer/cell_width.rs`, `buffer.rs`; `ratatui-widgets/src/clear.rs`,
		`block.rs`, `paragraph.rs`).

		  * X4a (#2499): the halfwidth (semi-)voiced sound marks U+FF9E and U+FF9F are one column
		    wide. They are Grapheme_Extend, so "ka + dakuten" is one cluster in one two-column
		    cell, as in Ratatui; a mark that would make a cluster wider than 2 columns starts a
		    cluster of its own (Ratatui gives such a cluster 3 columns), so the columns agree.
		  * X4b (#2368): TUI_CLEAR with an area partly or fully outside the buffer clears what
		    lies inside and fails no precondition.
		  * X4c (#2488): TUI_BLOCK at the buffer's last column and row, on empty and one-cell
		    areas, with padding larger than the area or than the NATURAL_16 range, and with very
		    wide titles; and BUFFER at the coordinate limit of RECT.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_WIDGET_EDGE_CHECKS

inherit
	BUFFER_TEST_HELPER

	TERMINAL_TEST_ACCESS
		undefine
			default_create
		end

feature -- X4a: halfwidth dakuten / handakuten

	test_halfwidth_sound_marks_are_one_column
			-- Ratatui `cell_width.rs` (#2499): `halfwidth_dakuten_alone`, `halfwidth_handakuten_alone`,
			-- `halfwidth_katakana_with_dakuten`, `halfwidth_katakana_with_handakuten`,
			-- `non_katakana_with_halfwidth_dakuten`, `combining_dakuten_no_special_handling`,
			-- `combining_handakuten_no_special_handling` and `mixed_text_unchanged`.
			-- The cluster checks follow UAX #29 (U+FF9E / U+FF9F are Grapheme_Extend, so they join
			-- the character before, as the combining U+3099 / U+309A do), except that a mark that
			-- would make its cluster wider than 2 columns starts a cluster of its own.
		do
			assert ("dakuten alone", {UNICODE_WIDTH}.width (0xFF9E) = 1)
			assert ("handakuten alone", {UNICODE_WIDTH}.width (0xFF9F) = 1)
			assert ("dakuten extends", {UNICODE_WIDTH}.is_extend (0xFF9E) and {UNICODE_WIDTH}.is_grapheme_extend (0xFF9E))
			assert ("handakuten extends", {UNICODE_WIDTH}.is_extend (0xFF9F) and {UNICODE_WIDTH}.is_grapheme_extend (0xFF9F))
				-- halfwidth_katakana_with_dakuten / _with_handakuten
			assert_width ("ka + dakuten", {STRING_32} "%/0xFF76/%/0xFF9E/", 2)
			assert_width ("sa + dakuten", {STRING_32} "%/0xFF7B/%/0xFF9E/", 2)
			assert_width ("ha + handakuten", {STRING_32} "%/0xFF8A/%/0xFF9F/", 2)
			assert_width ("hi + handakuten", {STRING_32} "%/0xFF8B/%/0xFF9F/", 2)
				-- non_katakana_with_halfwidth_dakuten
			assert_width ("a + dakuten", {STRING_32} "a%/0xFF9E/", 2)
			assert_width ("1 + handakuten", {STRING_32} "1%/0xFF9F/", 2)
			assert_width ("hiragana + dakuten", {STRING_32} "%/0x3042/%/0xFF9E/", 3)
			assert_width ("kanji + dakuten", {STRING_32} "%/0x7D05/%/0xFF9E/", 3)
				-- combining_dakuten_no_special_handling / combining_handakuten_no_special_handling
			assert_width ("halfwidth ka + combining dakuten", {STRING_32} "%/0xFF76/%/0x3099/", 1)
			assert_width ("ka + combining dakuten", {STRING_32} "%/0x30AB/%/0x3099/", 2)
			assert_width ("halfwidth ha + combining handakuten", {STRING_32} "%/0xFF8A/%/0x309A/", 1)
			assert_width ("ha + combining handakuten", {STRING_32} "%/0x30CF/%/0x309A/", 2)
				-- mixed_text_unchanged
			assert_width ("a", {STRING_32} "a", 1)
			assert_width ("hiragana a", {STRING_32} "%/0x3042/", 2)
			assert_width ("halfwidth ka", {STRING_32} "%/0xFF76/", 1)
			assert_width ("ka", {STRING_32} "%/0x30AB/", 2)
			assert_width ("a ka dakuten b", {STRING_32} "a%/0xFF76/%/0xFF9E/b", 4)
			assert_width ("hiragana a, ka dakuten", {STRING_32} "%/0x3042/%/0xFF76/%/0xFF9E/", 4)
				-- Cluster boundaries and cluster widths
			assert_cluster ("ka + dakuten", {STRING_32} "%/0xFF76/%/0xFF9E/", 2, 2)
			assert_cluster ("ha + handakuten", {STRING_32} "%/0xFF8A/%/0xFF9F/", 2, 2)
			assert_cluster ("a + dakuten", {STRING_32} "a%/0xFF9E/", 2, 2)
			assert_cluster ("two marks alone", {STRING_32} "%/0xFF9E/%/0xFF9F/", 2, 2)
			assert_cluster ("ka + dakuten + combining acute", {STRING_32} "%/0xFF76/%/0xFF9E/%/0x0301/", 3, 2)
			assert ("after a wide character the mark starts a cluster", {UNICODE_WIDTH}.grapheme_end ({STRING_32} "%/0x3042/%/0xFF9E/", 1) = 1)
			assert ("a second mark starts a cluster", {UNICODE_WIDTH}.grapheme_end ({STRING_32} "%/0xFF76/%/0xFF9E/%/0xFF9E/", 1) = 2)
			assert_width ("ka + two dakuten", {STRING_32} "%/0xFF76/%/0xFF9E/%/0xFF9E/", 3)
			assert_cluster ("combining dakuten", {STRING_32} "%/0xFF76/%/0x3099/", 2, 1)
			assert_cluster ("combining handakuten", {STRING_32} "%/0xFF8A/%/0x309A/", 2, 1)
		end

	test_other_grapheme_extend_characters
			-- The rest of Other_Grapheme_Extend (PropList.txt), which the Grapheme_Extend table brings in
			-- beside U+FF9E / U+FF9F: spacing marks such as Bengali U+09BE, Tamil U+0BBE and Malayalam
			-- U+0D57, the Hangul tone marks U+302E / U+302F, ZWNJ and the emoji tags. They extend the
			-- cluster before them and take no column, as in the unicode-width crate (Grapheme_Extend:
			-- width 0). ZWJ sequences, VS16, flags and skin tones are unchanged.
		do
			across <<{NATURAL_32} 0x09BE, {NATURAL_32} 0x09D7, {NATURAL_32} 0x0B3E, {NATURAL_32} 0x0BBE, {NATURAL_32} 0x0CC2,
				{NATURAL_32} 0x0D3E, {NATURAL_32} 0x0D57, {NATURAL_32} 0x0DCF, {NATURAL_32} 0x1B35, {NATURAL_32} 0x302E,
				{NATURAL_32} 0x302F, {NATURAL_32} 0x200C, {NATURAL_32} 0xE0020, {NATURAL_32} 0xE007F, {NATURAL_32} 0x1D165>> as c
			loop
				assert ("grapheme extend " + c.to_hex_string, {UNICODE_WIDTH}.is_grapheme_extend (c)
					and {UNICODE_WIDTH}.is_extend (c) and {UNICODE_WIDTH}.width (c) = 0)
			end
				-- Bengali KA + AA, Tamil TTA + AA, Malayalam KA + AU length mark: one cluster, one column
			assert_cluster ("bengali ka aa", {STRING_32} "%/0x0995/%/0x09BE/", 2, 1)
			assert_cluster ("tamil tta aa", {STRING_32} "%/0x0B9F/%/0x0BBE/", 2, 1)
			assert_cluster ("malayalam ka au", {STRING_32} "%/0x0D15/%/0x0D57/", 2, 1)
				-- Hangul syllable + tone mark: one cluster, two columns
			assert_cluster ("hangul tone mark", {STRING_32} "%/0xAC00/%/0x302E/", 2, 2)
				-- Black flag + tag sequence (England): one cluster, two columns
			assert_cluster ("tag sequence", {STRING_32} "%/0x1F3F4/%/0xE0067/%/0xE0062/%/0xE0065/%/0xE006E/%/0xE0067/%/0xE007F/", 7, 2)
				-- Unchanged: ZWJ sequence, flag, skin tone, VS16, a spacing mark that is not Grapheme_Extend
			assert_cluster ("zwj", {STRING_32} "%/0x1F468/%/0x200D/%/0x1F469/", 3, 2)
			assert_cluster ("flag", {STRING_32} "%/0x1F1EF/%/0x1F1F5/", 2, 2)
			assert_cluster ("skin tone", {STRING_32} "%/0x1F44D/%/0x1F3FD/", 2, 2)
			assert_cluster ("vs16", {STRING_32} "%/0x2764/%/0xFE0F/", 2, 2)
			assert ("devanagari i is still its own cluster", {UNICODE_WIDTH}.grapheme_end ({STRING_32} "%/0x0915/%/0x093F/", 1) = 1)
			assert ("ZWJ is not Grapheme_Extend", not {UNICODE_WIDTH}.is_grapheme_extend (0x200D))
		end

	test_set_string_halfwidth_katakana_with_dakuten
			-- Ratatui `set_string_halfwidth_katakana_with_dakuten` (buffer.rs, #2499), in 5 x 1:
			-- "ka + dakuten" is one two-column cell (Ratatui resets cell 1; here it is the
			-- continuation cell). Three of them need 6 columns: 5 hold two, and column 4 is blank.
		local
			l_buf: BUFFER
		do
				-- Fullwidth katakana: 2 cells
			l_buf := string_buffer ({STRING_32} "%/0x30AC/", 5)
			assert_buffer_lines ("fullwidth ga", l_buf, <<{STRING_32} "%/0x30AC/   ">>)
			assert ("fullwidth ga is wide", l_buf.cell (0, 0).width = 2 and l_buf.cell (0, 1).is_continuation)
				-- Halfwidth katakana (no dakuten): 1 cell
			l_buf := string_buffer ({STRING_32} "%/0xFF76/", 5)
			assert_cells ("halfwidth ka", l_buf, <<{STRING_32} "%/0xFF76/", " ", " ", " ", " ">>)
				-- Halfwidth katakana + halfwidth dakuten: one cell, 2 columns
			l_buf := string_buffer ({STRING_32} "%/0xFF76/%/0xFF9E/", 5)
			assert_buffer_lines ("ka + dakuten", l_buf, <<{STRING_32} "%/0xFF76/%/0xFF9E/   ">>)
			assert_wide_cell ("ka + dakuten", l_buf, 0, {STRING_32} "%/0xFF76/%/0xFF9E/")
			assert_cell_symbol ("ka + dakuten, column 2", l_buf, 0, 2, " ")
				-- Halfwidth katakana + halfwidth handakuten
			l_buf := string_buffer ({STRING_32} "%/0xFF8A/%/0xFF9F/", 5)
			assert_wide_cell ("ha + handakuten", l_buf, 0, {STRING_32} "%/0xFF8A/%/0xFF9F/")
				-- Two of them: 4 columns
			l_buf := string_buffer ({STRING_32} "%/0xFF76/%/0xFF9E/%/0xFF77/%/0xFF9E/", 5)
			assert_wide_cell ("ga gi, first", l_buf, 0, {STRING_32} "%/0xFF76/%/0xFF9E/")
			assert_wide_cell ("ga gi, second", l_buf, 2, {STRING_32} "%/0xFF77/%/0xFF9E/")
			assert_cell_symbol ("ga gi, last", l_buf, 0, 4, " ")
				-- Overflow: only the first two clusters fit, column 4 stays blank
			l_buf := string_buffer ({STRING_32} "%/0xFF76/%/0xFF9E/%/0xFF77/%/0xFF9E/%/0xFF78/%/0xFF9E/", 5)
			assert_buffer_lines ("overflow", l_buf, <<{STRING_32} "%/0xFF76/%/0xFF9E/%/0xFF77/%/0xFF9E/ ">>)
			assert_cell_symbol ("overflow, column 4 blank", l_buf, 0, 4, " ")
			assert ("overflow consistent", l_buf.is_consistent)
		end

	test_set_string_combining_vs_halfwidth_dakuten
			-- Ratatui `set_string_combining_vs_halfwidth_dakuten` (buffer.rs, #2499): the combining
			-- dakuten (U+3099) joins the katakana in one one-column cell; with the halfwidth dakuten
			-- (U+FF9E) the cluster is one two-column cell. Ratatui's returned end column (1, then 2)
			-- is the text's width here.
		local
			l_buf: BUFFER
		do
			l_buf := string_buffer ({STRING_32} "%/0xFF76/%/0x3099/", 5)
			assert_cells ("combining", l_buf, <<{STRING_32} "%/0xFF76/%/0x3099/", " ", " ", " ", " ">>)
			assert ("combining: one column", l_buf.cell (0, 0).width = 1)
			assert ("combining: ends at 1", {UNICODE_WIDTH}.string_width ({STRING_32} "%/0xFF76/%/0x3099/") = 1)
			l_buf := string_buffer ({STRING_32} "%/0xFF76/%/0xFF9E/", 5)
			assert_wide_cell ("halfwidth", l_buf, 0, {STRING_32} "%/0xFF76/%/0xFF9E/")
			assert ("halfwidth: ends at 2", {UNICODE_WIDTH}.string_width ({STRING_32} "%/0xFF76/%/0xFF9E/") = 2)
		end

	test_render_paragraph_with_halfwidth_katakana_dakuten_and_background
			-- Ratatui `test_render_paragraph_with_halfwidth_katakana_dakuten_and_background`, with
			-- `test_render_paragraph_with_ascii_and_background` and
			-- `test_render_paragraph_with_fullwidth_and_background` (paragraph.rs, #2499): a paragraph
			-- on a green background in 10 x 1. Every cell is green; a continuation cell is not drawn,
			-- so it is skipped (as Ratatui's comment says, its colour does not matter).
		local
			l_buf: BUFFER
		do
			l_buf := green_paragraph ({STRING_32} "abc")
			assert_buffer_lines ("ascii", l_buf, <<{STRING_32} "abc       ">>)
			assert_green ("ascii", l_buf)

			l_buf := green_paragraph ({STRING_32} "%/0x3042/%/0x3044/%/0x3046/")
			assert_buffer_lines ("fullwidth", l_buf, <<{STRING_32} "%/0x3042/%/0x3044/%/0x3046/    ">>)
			assert ("fullwidth cells", l_buf.cell (0, 0).width = 2 and l_buf.cell (0, 2).width = 2 and l_buf.cell (0, 4).width = 2)
			assert_green ("fullwidth", l_buf)

				-- Three two-column cells at 0, 2 and 4, as in Ratatui
			l_buf := green_paragraph ({STRING_32} "%/0xFF76/%/0xFF9E/%/0xFF77/%/0xFF9E/%/0xFF78/%/0xFF9E/")
			assert_buffer_lines ("halfwidth", l_buf, <<{STRING_32} "%/0xFF76/%/0xFF9E/%/0xFF77/%/0xFF9E/%/0xFF78/%/0xFF9E/    ">>)
			assert_wide_cell ("halfwidth 0", l_buf, 0, {STRING_32} "%/0xFF76/%/0xFF9E/")
			assert_wide_cell ("halfwidth 2", l_buf, 2, {STRING_32} "%/0xFF77/%/0xFF9E/")
			assert_wide_cell ("halfwidth 4", l_buf, 4, {STRING_32} "%/0xFF78/%/0xFF9E/")
			assert_green ("halfwidth", l_buf)
		end

	test_clipping_keeps_dakuten_with_its_katakana
			-- A clip edge through "gu" (ku + dakuten) shows neither half: when the mark was a cell
			-- of its own, the right edge kept "ku", a different letter. The left edge blanks the
			-- cut cluster.
		local
			l_buf: BUFFER
		do
			create l_buf.make (6, 2)
				-- Right edge at column 3: "ga" fits, "gu" (columns 2 and 3) does not
			l_buf.set_stringn (0, 0, {STRING_32} "%/0xFF76/%/0xFF9E/%/0xFF78/%/0xFF9E/", 3, create {STYLE})
			assert_buffer_lines ("right edge", l_buf, <<{STRING_32} "%/0xFF76/%/0xFF9E/    ", "      ">>)
				-- Left edge at column 1, text from column 0: the first cluster is cut
			l_buf.set_string_clipped (1, 0, {STRING_32} "%/0xFF78/%/0xFF9E/ab", 1, 6, create {STYLE})
			assert_buffer_lines ("left edge", l_buf, <<{STRING_32} "%/0xFF76/%/0xFF9E/    ", "  ab  ">>)
			assert ("consistent", l_buf.is_consistent)
		end

	test_text_input_and_area_edit_dakuten_as_one_character
			-- TEXT_INPUT_STATE and TEXT_AREA_STATE move over "ka + dakuten" in one step and delete it
			-- with one backspace, like any other grapheme cluster; the cursor column counts 2.
		local
			l_input: TEXT_INPUT_STATE
			l_area: TEXT_AREA_STATE
		do
			create l_input.make_with_text ({STRING_32} "a%/0xFF76/%/0xFF9E/b")
			l_input.move_cursor_left
			assert ("input: before b", l_input.cursor_position = 3 and l_input.cursor_column = 3)
			l_input.move_cursor_left
			assert ("input: before ga, one step", l_input.cursor_position = 1 and l_input.cursor_column = 1)
			l_input.move_cursor_right
			assert ("input: after ga, one step", l_input.cursor_position = 3 and l_input.cursor_column = 3)
			l_input.delete_backward
			assert ("input: one backspace deletes ga", l_input.value.same_string_general ("ab") and l_input.cursor_position = 1)

			create l_area.make_with_text ({STRING_32} "a%/0xFF76/%/0xFF9E/b")
			l_area.move_cursor_left (False)
			l_area.move_cursor_left (False)
			assert ("area: before ga, one step", l_area.cursor_position = 1)
			l_area.move_cursor_right (False)
			assert ("area: after ga, one step", l_area.cursor_position = 3)
			l_area.delete_backward
			assert ("area: one backspace deletes ga", l_area.value.same_string_general ("ab") and l_area.cursor_position = 1)
		end

feature -- X4b: Clear outside the buffer

	test_clear_render
			-- Ratatui `render` (clear.rs): (1, 2, 3, 4) in a 15 x 7 buffer of 'x'.
		local
			l_buf: BUFFER
		do
			l_buf := x_buffer;
			(create {TUI_CLEAR}).render (create {RECT}.make (1, 2, 3, 4), l_buf)
			assert_buffer_lines ("cleared", l_buf, <<
				"xxxxxxxxxxxxxxx",
				"xxxxxxxxxxxxxxx",
				"x   xxxxxxxxxxx",
				"x   xxxxxxxxxxx",
				"x   xxxxxxxxxxx",
				"x   xxxxxxxxxxx",
				"xxxxxxxxxxxxxxx">>)
		end

	test_clear_render_partially_out_of_bounds
			-- Ratatui `render_partially_out_of_bounds` (clear.rs, #2368): (2, 0, 100, 100) clears
			-- columns 2 to 14 of every row. The same at the buffer's last column and row, and with
			-- an area that reaches RECT's limit (x + width = 65535).
		local
			l_buf: BUFFER
		do
			l_buf := x_buffer;
			(create {TUI_CLEAR}).render (create {RECT}.make (2, 0, 100, 100), l_buf)
			assert_buffer_lines ("partly outside", l_buf, <<
				"xx             ", "xx             ", "xx             ", "xx             ",
				"xx             ", "xx             ", "xx             ">>)

			l_buf := x_buffer;
			(create {TUI_CLEAR}).render (create {RECT}.make (14, 6, 100, 100), l_buf)
			assert_buffer_lines ("last cell", l_buf, <<
				"xxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxx",
				"xxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxx", "xxxxxxxxxxxxxx ">>)

			l_buf := x_buffer;
			(create {TUI_CLEAR}).render (create {RECT}.make (0, 0, 65535, 65535), l_buf)
			assert_buffer_lines ("largest area", l_buf, <<
				"               ", "               ", "               ", "               ",
				"               ", "               ", "               ">>)

			l_buf := x_buffer;
			(create {TUI_CLEAR}).render (create {RECT}.make (13, 5, 65535, 65535), l_buf)
			assert ("clamped to the coordinate limit", l_buf.cell (5, 13).symbol.same_string_general (" ")
				and l_buf.cell (6, 14).symbol.same_string_general (" ") and l_buf.cell (4, 13).symbol.same_string_general ("x")
				and l_buf.cell (5, 12).symbol.same_string_general ("x"))
		end

	test_clear_render_fully_out_of_bounds
			-- Ratatui `render_fully_out_of_bounds` (clear.rs, #2368): (100, 0, 100, 100) changes
			-- nothing. The same just past the right and the bottom edge, at RECT's limit, and for
			-- empty areas inside the buffer.
		local
			l_buf: BUFFER
		do
			l_buf := x_buffer
			across <<create {RECT}.make (100, 0, 100, 100), create {RECT}.make (15, 0, 1, 7), create {RECT}.make (0, 7, 15, 1),
				create {RECT}.make (15, 7, 1, 1), create {RECT}.make (65535, 65535, 0, 0), create {RECT}.make (65534, 65534, 1, 1),
				create {RECT}.make (3, 3, 0, 4), create {RECT}.make (3, 3, 4, 0), create {RECT}.make (0, 0, 0, 0)>> as r
			loop
				(create {TUI_CLEAR}).render (r, l_buf)
				assert_buffer_lines ("untouched by " + r.out, l_buf, <<
					"xxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxx",
					"xxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxx">>)
			end
		end

	test_clear_resets_cells_and_splits_cut_wide_characters
			-- Ratatui `Cell::reset`: a cleared cell is a space with no style and no diff option.
			-- A wide character cut by the area's edge is split into blanks, so the row stays
			-- consistent (Ratatui resets only the half inside the area).
		local
			l_buf: BUFFER
		do
			create l_buf.make (6, 2)
			l_buf.fill ('x', create {STYLE}.make_with_colors ({COLOR}.Red, {COLOR}.Blue))
			l_buf.set_diff_option (0, 1, {CELL_DIFF_OPTION}.Skip, 0);
			(create {TUI_CLEAR}).render (create {RECT}.make (1, 0, 2, 9), l_buf)
			assert_buffer_lines ("cleared", l_buf, <<"x  xxx", "x  xxx">>)
			assert ("no style", l_buf.cell (0, 1).style.renders_as_default and l_buf.cell (1, 2).style.renders_as_default)
			assert ("no diff option", l_buf.cell (0, 1).diff_option = {CELL_DIFF_OPTION}.None)
			assert ("outside keeps its style", not l_buf.cell (0, 0).style.renders_as_default)

			create l_buf.make (6, 1)
			l_buf.put_string (0, 0, {STRING_32} "%/0x4F60/%/0x597D/%/0x4E16/", create {STYLE})
				-- Columns 1 to 3: the right half of the first character and all of the second
			(create {TUI_CLEAR}).render (create {RECT}.make (1, 0, 3, 1), l_buf)
			assert_buffer_lines ("wide cut", l_buf, <<{STRING_32} "    %/0x4E16/">>)
			assert ("wide cut consistent", l_buf.is_consistent)

			create l_buf.make (6, 1)
			l_buf.put_string (0, 0, {STRING_32} "%/0x4F60/%/0x597D/%/0x4E16/", create {STYLE})
				-- Columns 2 to 4: the second character and the left half of the third
			(create {TUI_CLEAR}).render (create {RECT}.make (2, 0, 3, 1), l_buf)
			assert_buffer_lines ("wide cut at the right edge", l_buf, <<{STRING_32} "%/0x4F60/    ">>)
			assert ("wide cut at the right edge consistent", l_buf.is_consistent)
		end

	test_clear_on_buffer_at_the_coordinate_limit
			-- A 65535-column buffer (RECT's limit) filled with 'x': an area at its last column, one
			-- that runs past it (cut by RECT to x + width = 65535), and a whole row clear only those
			-- cells. `fill` and `TUI_CLEAR` are linear (they were quadratic on such rows with
			-- assertions on), so this takes well under 30 s even in a workbench build.
		local
			l_buf: BUFFER
			l_start: INTEGER_64
			c: INTEGER
			l_blank, l_x: BOOLEAN
		do
			l_start := {MONOTONIC_CLOCK}.milliseconds
			create l_buf.make (65535, 2)
			l_buf.fill ('x', create {STYLE});
			(create {TUI_CLEAR}).render (create {RECT}.make (65534, 0, 1, 1), l_buf)
			assert_slice ("last column", l_buf, 0, 65532, <<"x", "x", " ">>)
			assert_slice ("row 1 untouched", l_buf, 1, 65532, <<"x", "x", "x">>);
			(create {TUI_CLEAR}).render (create {RECT}.make (65533, 1, 100, 100), l_buf)
			assert_slice ("past the last column", l_buf, 1, 65532, <<"x", " ", " ">>)
			assert_slice ("row 0 unchanged", l_buf, 0, 65532, <<"x", "x", " ">>);
			(create {TUI_CLEAR}).render (create {RECT}.make (0, 0, 65535, 1), l_buf)
			l_blank := True
			l_x := True
			from c := 0 until c >= 65535 loop
				l_blank := l_blank and l_buf.cell (0, c).symbol.same_string_general (" ")
				if c < 65533 then
					l_x := l_x and l_buf.cell (1, c).symbol.same_string_general ("x")
				end
				c := c + 1
			end
			assert ("whole row 0 cleared", l_blank)
			assert ("row 1 kept up to its cleared end", l_x)
			assert ("consistent", l_buf.is_consistent)
			assert ("linear time: " + ({MONOTONIC_CLOCK}.milliseconds - l_start).out + " ms", {MONOTONIC_CLOCK}.milliseconds - l_start < 30_000)
		end

feature -- X4c: block edge arithmetic

	test_inner_takes_into_account_the_borders
			-- Ratatui `inner_takes_into_account_the_borders` (block.rs): borders on empty, one-cell,
			-- two-cell and three-cell areas; and the same at the coordinate limit.
		do
			assert_inner ("none_0", {BORDERS}.none, rect (0, 0, 0, 0), rect (0, 0, 0, 0))
			assert_inner ("none_1", {BORDERS}.none, rect (0, 0, 1, 1), rect (0, 0, 1, 1))
			assert_inner ("left_0", {BORDERS}.left, rect (0, 0, 0, 0), rect (0, 0, 0, 0))
			assert_inner ("left_w1", {BORDERS}.left, rect (0, 0, 0, 1), rect (0, 0, 0, 1))
			assert_inner ("left_w2", {BORDERS}.left, rect (0, 0, 1, 1), rect (1, 0, 0, 1))
			assert_inner ("left_w3", {BORDERS}.left, rect (0, 0, 2, 1), rect (1, 0, 1, 1))
			assert_inner ("top_0", {BORDERS}.top, rect (0, 0, 0, 0), rect (0, 0, 0, 0))
			assert_inner ("top_h1", {BORDERS}.top, rect (0, 0, 1, 0), rect (0, 0, 1, 0))
			assert_inner ("top_h2", {BORDERS}.top, rect (0, 0, 1, 1), rect (0, 1, 1, 0))
			assert_inner ("top_h3", {BORDERS}.top, rect (0, 0, 1, 2), rect (0, 1, 1, 1))
			assert_inner ("right_0", {BORDERS}.right, rect (0, 0, 0, 0), rect (0, 0, 0, 0))
			assert_inner ("right_w1", {BORDERS}.right, rect (0, 0, 0, 1), rect (0, 0, 0, 1))
			assert_inner ("right_w2", {BORDERS}.right, rect (0, 0, 1, 1), rect (0, 0, 0, 1))
			assert_inner ("right_w3", {BORDERS}.right, rect (0, 0, 2, 1), rect (0, 0, 1, 1))
			assert_inner ("bottom_0", {BORDERS}.bottom, rect (0, 0, 0, 0), rect (0, 0, 0, 0))
			assert_inner ("bottom_h1", {BORDERS}.bottom, rect (0, 0, 1, 0), rect (0, 0, 1, 0))
			assert_inner ("bottom_h2", {BORDERS}.bottom, rect (0, 0, 1, 1), rect (0, 0, 1, 0))
			assert_inner ("bottom_h3", {BORDERS}.bottom, rect (0, 0, 1, 2), rect (0, 0, 1, 1))
			assert_inner ("all_0", {BORDERS}.all_borders, rect (0, 0, 0, 0), rect (0, 0, 0, 0))
			assert_inner ("all_1", {BORDERS}.all_borders, rect (0, 0, 1, 1), rect (1, 1, 0, 0))
			assert_inner ("all_2", {BORDERS}.all_borders, rect (0, 0, 2, 2), rect (1, 1, 0, 0))
			assert_inner ("all_3", {BORDERS}.all_borders, rect (0, 0, 3, 3), rect (1, 1, 1, 1))
				-- At the coordinate limit
			assert_inner ("all, last cell", {BORDERS}.all_borders, rect (65534, 65534, 1, 1), rect (65535, 65535, 0, 0))
			assert_inner ("all, at the limit", {BORDERS}.all_borders, rect (65535, 65535, 0, 0), rect (65535, 65535, 0, 0))
			assert_inner ("all, 3 x 3 at the limit", {BORDERS}.all_borders, rect (65532, 65532, 3, 3), rect (65533, 65533, 1, 1))
		end

	test_inner_saturates_when_padding_sum_overflows
			-- Ratatui `inner_saturates_when_padding_sum_overflows` (block.rs, #2488): padding whose
			-- sum passes 65535 leaves no room. Ratatui moves the empty inner area by the left (or
			-- top) padding, to (65535, 0, 0, 1) and (0, 65535, 1, 0); here an inner area without
			-- room stays where the padding starts, inside the area. (Before the fix, the NATURAL_16
			-- sum wrapped to 0 and the first case gave Ratatui's rectangle by accident: x moved by
			-- 65535 and RECT cut the width to 0.)
		local
			l_block: TUI_BLOCK
		do
			l_block := no_borders.with_four_sided_padding (create {PADDING}.make (0, 1, 0, 65535))
			assert_rect ("left 65535, right 1", l_block.inner (rect (0, 0, 1, 1)), rect (0, 0, 0, 1))
			l_block := no_borders.with_four_sided_padding (create {PADDING}.make (65535, 0, 1, 0))
			assert_rect ("top 65535, bottom 1", l_block.inner (rect (0, 0, 1, 1)), rect (0, 0, 1, 0))
		end

	test_inner_padding_sums_do_not_wrap
			-- The sums of #2488 where a NATURAL_16 sum wraps to a small number: the four-sided padding
			-- on its own, and the symmetric `padding` (MARGIN) with the four-sided padding together.
			-- (PADDING.horizontal / vertical are not used by `inner`.)
		local
			l_block: TUI_BLOCK
		do
				-- Left 65535 and right 3 sum to 2 in NATURAL_16, which fits in 5 columns
			l_block := no_borders.with_four_sided_padding (create {PADDING}.make (0, 3, 0, 65535))
			assert_rect ("left 65535, right 3, at x 1", l_block.inner (rect (1, 0, 5, 1)), rect (1, 0, 0, 1))
			l_block := no_borders.with_four_sided_padding (create {PADDING}.make (65535, 0, 3, 0))
			assert_rect ("top 65535, bottom 3, at y 1", l_block.inner (rect (0, 1, 1, 5)), rect (0, 1, 1, 0))
				-- 65535 symmetric padding plus 1 on each side: 65536 per side, no room left
			l_block := no_borders.with_padding (create {MARGIN}.make (65535, 65535)).with_four_sided_padding (create {PADDING}.make_all (1))
			assert_rect ("margin 65535 + padding 1", l_block.inner (rect (0, 0, 10, 4)), rect (0, 0, 0, 0))
			l_block := l_block.with_borders ({BORDERS}.all_borders)
			assert_rect ("margin 65535 + padding 1, bordered", l_block.inner (rect (0, 0, 10, 4)), rect (1, 1, 0, 0))
		end

	test_inner_with_padding_larger_than_the_area
			-- Padding that just fits, that takes the last column or row, and that is larger than
			-- the area; and a paragraph in such a block draws only the block.
		local
			l_block: TUI_BLOCK
			l_buf: BUFFER
		do
			l_block := (create {TUI_BLOCK}).with_four_sided_padding (create {PADDING}.make (1, 2, 1, 2))
			assert_rect ("fits", l_block.inner (rect (0, 0, 10, 5)), rect (3, 2, 4, 1))
			assert_rect ("one column left", l_block.inner (rect (0, 0, 7, 5)), rect (3, 2, 1, 1))
			assert_rect ("no column left", l_block.inner (rect (0, 0, 6, 5)), rect (1, 2, 0, 1))
			assert_rect ("no row left", l_block.inner (rect (0, 0, 10, 4)), rect (3, 1, 4, 0))
			assert_rect ("larger than the area", l_block.inner (rect (2, 1, 3, 3)), rect (3, 2, 0, 0))
			assert_rect ("at the last cell", l_block.inner (rect (65534, 65534, 1, 1)), rect (65535, 65535, 0, 0))

			create l_buf.make (6, 4);
			(create {TUI_PARAGRAPH}.make_raw ("text")).with_block (l_block.with_four_sided_padding (create {PADDING}.make_all (3))).render (l_buf.area, l_buf)
			assert_buffer_lines ("paragraph in a padded block", l_buf, <<
				{STRING_32} "%/0x250C/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2510/",
				{STRING_32} "%/0x2502/    %/0x2502/",
				{STRING_32} "%/0x2502/    %/0x2502/",
				{STRING_32} "%/0x2514/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2518/">>)
		end

	test_render_empty_areas_draws_nothing
			-- Ratatui `render_sides_handles_empty_area_without_panicking` and
			-- `render_corners_handles_empty_area_without_panicking` (block.rs, #2488) call the
			-- private side and corner renderers with `Rect::ZERO`; through `render` (which first
			-- cuts the area to the buffer) nothing is drawn, as here. Empty areas at the buffer's
			-- edges and at the coordinate limit, merged or not.
		local
			l_buf: BUFFER
		do
			create l_buf.make (3, 2)
			across <<rect (0, 0, 0, 0), rect (0, 0, 0, 2), rect (0, 0, 3, 0), rect (2, 1, 0, 1), rect (2, 1, 1, 0),
				rect (3, 0, 0, 2), rect (0, 2, 3, 0), rect (65535, 65535, 0, 0)>> as r
			loop
				titled_block.render (r, l_buf)
				titled_block.with_border_merged (True).render (r, l_buf)
				assert_buffer_lines ("nothing drawn for " + r.out, l_buf, <<"   ", "   ">>)
			end
		end

	test_render_merged_borders_in_minimal_buffer
			-- Ratatui `render_merged_borders_in_minimal_buffer_does_not_panic` (block.rs, #2488): a
			-- bordered block in a 1 x 1 buffer, merged. Ratatui draws all four sides and corners into
			-- the cell and merges them to a cross; here the cell gets its top-left corner, as without
			-- merging (as Ratatui's `MergeStrategy::Replace`).
		local
			l_buf: BUFFER
		do
			create l_buf.make (1, 1);
			(create {TUI_BLOCK}).with_border_merged (True).render (l_buf.area, l_buf)
			assert_buffer_lines ("merged", l_buf, <<{STRING_32} "%/0x250C/">>)
			create l_buf.make (1, 1);
			(create {TUI_BLOCK}).render (l_buf.area, l_buf)
			assert_buffer_lines ("replace", l_buf, <<{STRING_32} "%/0x250C/">>)
		end

	test_block_at_the_last_column_and_row
			-- Bordered blocks in the buffer's last column and row of a 6 x 4 buffer: one cell, 2 x 2,
			-- one column, one row, titled; as Ratatui's `Replace` strategy draws them (corners
			-- last). A block that runs past the buffer is first cut to it, as Ratatui's
			-- `Block::render` (`area.intersection(buf.area)`), so the box is closed at the
			-- buffer's edge.
		local
			l_buf: BUFFER
		do
			l_buf := block_buffer (rect (5, 3, 1, 1))
			assert_buffer_lines ("1 x 1", l_buf, <<"      ", "      ", "      ", {STRING_32} "     %/0x250C/">>)
			l_buf := block_buffer (rect (4, 2, 2, 2))
			assert_buffer_lines ("2 x 2", l_buf, <<"      ", "      ",
				{STRING_32} "    %/0x250C/%/0x2510/", {STRING_32} "    %/0x2514/%/0x2518/">>)
			l_buf := block_buffer (rect (5, 0, 1, 4))
			assert_buffer_lines ("one column", l_buf, <<{STRING_32} "     %/0x250C/", {STRING_32} "     %/0x2502/",
				{STRING_32} "     %/0x2502/", {STRING_32} "     %/0x2514/">>)
			l_buf := block_buffer (rect (0, 3, 6, 1))
			assert_buffer_lines ("one row", l_buf, <<"      ", "      ", "      ", {STRING_32} "%/0x250C/Titl%/0x2510/">>)
			l_buf := block_buffer (rect (3, 1, 3, 3))
			assert_buffer_lines ("3 x 3 titled", l_buf, <<"      ",
				{STRING_32} "   %/0x250C/T%/0x2510/", {STRING_32} "   %/0x2502/ %/0x2502/", {STRING_32} "   %/0x2514/B%/0x2518/">>)
			l_buf := block_buffer (rect (3, 3, 3, 1))
			assert_buffer_lines ("3 x 1 titled", l_buf, <<"      ", "      ", "      ", {STRING_32} "   %/0x250C/T%/0x2510/">>)
			l_buf := block_buffer (rect (0, 0, 6, 4))
			assert_buffer_lines ("whole buffer", l_buf, <<{STRING_32} "%/0x250C/Titl%/0x2510/", {STRING_32} "%/0x2502/    %/0x2502/",
				{STRING_32} "%/0x2502/    %/0x2502/", {STRING_32} "%/0x2514/Bott%/0x2518/">>)
				-- Running past the right and bottom edges: a closed 3 x 3 box
			l_buf := block_buffer (rect (3, 1, 5, 5))
			assert_buffer_lines ("past the edges", l_buf, <<"      ",
				{STRING_32} "   %/0x250C/T%/0x2510/", {STRING_32} "   %/0x2502/ %/0x2502/", {STRING_32} "   %/0x2514/B%/0x2518/">>)
			l_buf := block_buffer (rect (5, 3, 65535, 65535))
			assert_buffer_lines ("past the edges to the limit", l_buf, <<"      ", "      ", "      ", {STRING_32} "     %/0x250C/">>)
		end

	test_block_partly_outside_the_buffer_is_closed_at_its_edge
			-- Ratatui `Block::render` cuts the area to the buffer first (since #933; no Ratatui test
			-- names this case): a block running past the right edge, the bottom edge or both is drawn
			-- as a closed box in the part inside the buffer; a block fully outside draws nothing.
		local
			l_buf: BUFFER
		do
			l_buf := plain_block_buffer (rect (3, 0, 5, 4))
			assert_buffer_lines ("past the right edge", l_buf, <<
				{STRING_32} "   %/0x250C/%/0x2500/%/0x2510/", {STRING_32} "   %/0x2502/ %/0x2502/",
				{STRING_32} "   %/0x2502/ %/0x2502/", {STRING_32} "   %/0x2514/%/0x2500/%/0x2518/">>)
			l_buf := plain_block_buffer (rect (0, 2, 4, 5))
			assert_buffer_lines ("past the bottom edge", l_buf, <<"      ", "      ",
				{STRING_32} "%/0x250C/%/0x2500/%/0x2500/%/0x2510/  ", {STRING_32} "%/0x2514/%/0x2500/%/0x2500/%/0x2518/  ">>)
			l_buf := plain_block_buffer (rect (3, 1, 65535, 65535))
			assert_buffer_lines ("past both edges", l_buf, <<"      ",
				{STRING_32} "   %/0x250C/%/0x2500/%/0x2510/", {STRING_32} "   %/0x2502/ %/0x2502/", {STRING_32} "   %/0x2514/%/0x2500/%/0x2518/">>)
			across <<rect (6, 0, 3, 3), rect (0, 4, 3, 3), rect (6, 4, 2, 2), rect (100, 100, 5, 5)>> as r loop
				l_buf := plain_block_buffer (r)
				assert_buffer_lines ("fully outside " + r.out, l_buf, <<"      ", "      ", "      ", "      ">>)
			end
				-- The same through `render_merged`
			create l_buf.make (6, 4)
			(create {TUI_BLOCK}).render_merged (rect (3, 0, 5, 4), l_buf)
			assert_buffer_lines ("merged, past the right edge", l_buf, <<
				{STRING_32} "   %/0x250C/%/0x2500/%/0x2510/", {STRING_32} "   %/0x2502/ %/0x2502/",
				{STRING_32} "   %/0x2502/ %/0x2502/", {STRING_32} "   %/0x2514/%/0x2500/%/0x2518/">>)
		end

	test_content_stays_inside_a_block_cut_by_the_buffer
			-- A paragraph in a block that runs past the buffer cuts its area to the buffer first, as
			-- Ratatui's `Paragraph::render`, so its text stays inside the closed box. A list does
			-- not, as Ratatui's `List` (it computes `inner` on the uncut area): its text runs over
			-- the block's right border at the buffer's edge. This snapshot matches Ratatui.
		local
			l_buf: BUFFER
			l_list: TUI_LIST
		do
			create l_buf.make (6, 4)
			(create {TUI_PARAGRAPH}.make_raw ("abcdef")).with_block (create {TUI_BLOCK}).render (rect (2, 0, 7, 3), l_buf)
			assert_buffer_lines ("paragraph", l_buf, <<{STRING_32} "  %/0x250C/%/0x2500/%/0x2500/%/0x2510/", {STRING_32} "  %/0x2502/ab%/0x2502/",
				{STRING_32} "  %/0x2514/%/0x2500/%/0x2500/%/0x2518/", "      ">>)

			create l_buf.make (6, 4)
			create l_list.make_empty
			l_list.append_raw_item ("abcdef")
			l_list.with_block (create {TUI_BLOCK}).render (rect (2, 0, 7, 3), l_buf)
			assert_buffer_lines ("list, as Ratatui", l_buf, <<{STRING_32} "  %/0x250C/%/0x2500/%/0x2500/%/0x2510/", {STRING_32} "  %/0x2502/abc",
				{STRING_32} "  %/0x2514/%/0x2500/%/0x2500/%/0x2518/", "      ">>)
			assert ("consistent", l_buf.is_consistent)
		end

	test_huge_titles_are_clipped
			-- Ratatui `render_center_titles_handles_title_width_increment_overflow`,
			-- `render_center_titles_handles_total_width_overflow`,
			-- `render_centered_titles_without_truncation_handles_title_advance_overflow`,
			-- `render_centered_titles_with_truncation_handles_title_advance_overflow` and
			-- `render_left_titles_handles_title_advance_overflow` (block.rs, #2488): titles of
			-- 65535 columns, and two that add up past 65535. Ratatui renders them on a borderless
			-- block in 1 x 1; titles are drawn on borders here, so the block is bordered and 5 x 3,
			-- with three title cells. A centred group wider than the room starts at the left
			-- corner (Ratatui shows its middle; with one letter repeated it is the same row).
		local
			l_a, l_a40, l_b30: STRING_32
			l_expected_top: STRING_32
		do
			l_a := repeated ('a', 65535)
			l_a40 := repeated ('a', 40000)
			l_b30 := repeated ('b', 30000)
			l_expected_top := {STRING_32} "%/0x250C/aaa%/0x2510/"
			assert_buffer_lines ("one centred", rendered ((create {TUI_BLOCK}).with_title_top (l_a, {TEXT_ALIGNMENT}.center), 5, 3),
				<<l_expected_top, {STRING_32} "%/0x2502/   %/0x2502/", {STRING_32} "%/0x2514/%/0x2500/%/0x2500/%/0x2500/%/0x2518/">>)
			assert_buffer_lines ("two centred", rendered ((create {TUI_BLOCK}).with_title_top (l_a40, {TEXT_ALIGNMENT}.center)
				.with_title_top (l_b30, {TEXT_ALIGNMENT}.center), 5, 3), <<l_expected_top>>)
			assert_buffer_lines ("one left", rendered ((create {TUI_BLOCK}).with_title_top (l_a, {TEXT_ALIGNMENT}.left), 5, 3), <<l_expected_top>>)
			assert_buffer_lines ("two left", rendered ((create {TUI_BLOCK}).with_title_top (l_a, {TEXT_ALIGNMENT}.left)
				.with_title_top (l_a, {TEXT_ALIGNMENT}.left), 5, 3), <<l_expected_top>>)
			assert_buffer_lines ("one right", rendered ((create {TUI_BLOCK}).with_title_top (l_a, {TEXT_ALIGNMENT}.right), 5, 3), <<l_expected_top>>)
			assert_buffer_lines ("bottom, set_title", rendered ((create {TUI_BLOCK}).with_title (l_a).with_title_bottom (l_a40, {TEXT_ALIGNMENT}.center), 5, 3),
				<<l_expected_top, {STRING_32} "%/0x2502/   %/0x2502/", {STRING_32} "%/0x2514/aaa%/0x2518/">>)
		end

	test_block_on_buffer_at_the_coordinate_limit
			-- A 65535 x 3 buffer (RECT's limit): a titled block in its last three columns, a
			-- one-column block in its last column, and a paragraph in a block there (Ratatui
			-- `render_centered_titles_without_truncation_handles_maximum_x` places titles at
			-- x = 65534).
		local
			l_buf: BUFFER
			l_para: TUI_PARAGRAPH
		do
			create l_buf.make (65535, 3)
			titled_block.render (rect (65532, 0, 3, 3), l_buf)
			assert_slice ("top", l_buf, 0, 65531, <<" ", {STRING_32} "%/0x250C/", "T", {STRING_32} "%/0x2510/">>)
			assert_slice ("middle", l_buf, 1, 65531, <<" ", {STRING_32} "%/0x2502/", " ", {STRING_32} "%/0x2502/">>)
			assert_slice ("bottom", l_buf, 2, 65531, <<" ", {STRING_32} "%/0x2514/", "B", {STRING_32} "%/0x2518/">>)
			assert_rect ("inner", titled_block.inner (rect (65532, 0, 3, 3)), rect (65533, 1, 1, 1))

			create l_buf.make (65535, 3)
			titled_block.render (rect (65534, 0, 100, 3), l_buf)
			assert_slice ("one column, top", l_buf, 0, 65533, <<" ", {STRING_32} "%/0x250C/">>)
			assert_slice ("one column, middle", l_buf, 1, 65533, <<" ", {STRING_32} "%/0x2502/">>)
			assert_slice ("one column, bottom", l_buf, 2, 65533, <<" ", {STRING_32} "%/0x2514/">>)

			create l_buf.make (65535, 3)
			create l_para.make_raw ("xyz")
			l_para.with_block (create {TUI_BLOCK}).render (rect (65531, 0, 4, 3), l_buf)
			assert_slice ("paragraph", l_buf, 1, 65530, <<" ", {STRING_32} "%/0x2502/", "x", "y", {STRING_32} "%/0x2502/">>)
			assert ("consistent", l_buf.is_consistent)
		end

	test_buffer_size_is_within_rect_range
			-- A buffer is at most 65535 x 65535, the range of RECT (Ratatui's buffer area is a
			-- `Rect` of u16). Wider or taller is refused, so `area` keeps its size.
		local
			l_buf: BUFFER
		do
			create l_buf.make (65535, 1)
			assert ("widest area", l_buf.area.width = 65535 and l_buf.area.right = 65535)
			assert ("too wide refused", precondition_raised (agent make_buffer (65536, 1), "width_in_rect_range"))
			assert ("too tall refused", precondition_raised (agent make_buffer (1, 65536), "height_in_rect_range"))
			assert ("resize too wide refused", precondition_raised (agent l_buf.resize (65536, 1), "width_in_rect_range"))
			assert ("resize too tall refused", precondition_raised (agent l_buf.resize (1, 65536), "height_in_rect_range"))
			assert ("buffer unchanged", l_buf.width = 65535 and l_buf.height = 1)
		end

feature -- X4 review: more rows or columns than a buffer holds

	test_insert_before_more_rows_than_a_buffer_holds
			-- `TERMINAL.insert_before` with more rows than one block holds: the rows are drawn in
			-- blocks of `insert_block_limit` rows, top to bottom, the last block holding the rest,
			-- and every row reaches the screen or the scrollback, in order. The limit is lowered to
			-- 3 (it is {BUFFER}.Max_extent, 65535, otherwise; see
			-- `test_insert_before_at_the_buffer_limit`). A 6 x 5 VIRTUAL_TERMINAL with an inline
			-- viewport of 2 rows at row 0: the first 3 rows move the viewport down, the rest scroll.
		local
			l_vt: VIRTUAL_TERMINAL
			l_term: TERMINAL [VIRTUAL_TERMINAL]
		do
				-- 10 rows: 3 + 3 + 3 + 1, a last partial block
			l_term := small_inline_terminal
			l_vt := l_term.backend
			create block_heights.make (4)
			next_row_number := 0
			l_term.insert_before (10, agent draw_numbered_rows)
			assert_blocks ("10 rows", <<3, 3, 3, 1>>, Void)
			assert_inserted_rows ("10 rows", l_vt, l_term, 10)
				-- 9 rows: 3 + 3 + 3, an exact multiple
			l_term := small_inline_terminal
			l_vt := l_term.backend
			create block_heights.make (3)
			next_row_number := 0
			l_term.insert_before (9, agent draw_numbered_rows)
			assert_blocks ("9 rows", <<3, 3, 3>>, Void)
			assert_inserted_rows ("9 rows", l_vt, l_term, 9)
				-- Rows that fit in one block: the agent is called once
			across <<1, 2, 3>> as n loop
				l_term := small_inline_terminal
				l_vt := l_term.backend
				create block_heights.make (1)
				next_row_number := 0
				l_term.insert_before (n, agent draw_numbered_rows)
				assert ("one call for " + n.out, block_heights.count = 1 and block_heights [1] = n)
				assert_inserted_rows (n.out + " rows", l_vt, l_term, n)
			end
		end

	test_insert_before_rows_gives_each_block_its_first_row
			-- `TERMINAL.insert_before_rows`: each block is drawn from the 0-based index of its first
			-- row (0, 3, 6, 9 for 10 rows in blocks of 3), and the rows land as with `insert_before`.
		local
			l_vt: VIRTUAL_TERMINAL
			l_term: TERMINAL [VIRTUAL_TERMINAL]
		do
			l_term := small_inline_terminal
			l_vt := l_term.backend
			create block_heights.make (4)
			create block_firsts.make (4)
			l_term.insert_before_rows (10, agent draw_rows_from)
			assert_blocks ("10 rows", <<3, 3, 3, 1>>, <<0, 3, 6, 9>>)
			assert_inserted_rows ("10 rows", l_vt, l_term, 10)
				-- An exact multiple, then 2 rows in one block from row 0
			l_term := small_inline_terminal
			l_vt := l_term.backend
			create block_heights.make (3)
			create block_firsts.make (3)
			l_term.insert_before_rows (6, agent draw_rows_from)
			assert_blocks ("6 rows", <<3, 3>>, <<0, 3>>)
			assert_inserted_rows ("6 rows", l_vt, l_term, 6)
			create block_heights.make (1)
			create block_firsts.make (1)
			l_term.insert_before_rows (2, agent draw_rows_from)
			assert_blocks ("2 more rows", <<2>>, <<0>>)
			assert ("2 more rows on top of the viewport", l_vt.line (1).starts_with ("1 ") and l_vt.line (2).starts_with ("2 "))
		end

	test_insert_before_at_the_buffer_limit
			-- At the real limit, nothing drawn: 65537 rows are drawn in blocks of 65535 and 2 rows,
			-- from rows 0 and 65535, and the default limit is {BUFFER}.Max_extent. The backend is an
			-- ANSI backend on a fake 1 x 1002 console (output kept in a string, never shown), so the
			-- 65535-row block is one column wide and the rows scroll 1000 at a time.
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_term: TERMINAL [ANSI_TERMINAL_BACKEND]
		do
			create l_driver
			l_driver.set_size (1, 1002)
			create l_term.make_with_viewport (create {ANSI_TERMINAL_BACKEND}.make_with_driver_and_sink (l_driver, create {STRING_32}.make (0)),
				create {VIEWPORT}.make_inline (2))
			assert ("default limit", l_term.insert_block_limit = {BUFFER}.Max_extent)
			create block_heights.make (2)
			create block_firsts.make (2)
			l_term.insert_before_rows (65537, agent record_block)
			assert_blocks ("65537 rows", <<65535, 2>>, <<0, 65535>>)
			assert ("viewport at the bottom", l_term.viewport_origin_row = 1000)
		end

	test_terminal_larger_than_a_buffer
			-- A backend wider or taller than 65535 cells: the terminal's buffers stop at
			-- {BUFFER}.Max_extent (the rest of the screen is not drawn), instead of failing
			-- BUFFER's precondition.
		local
			l_term: TERMINAL [VIRTUAL_TERMINAL]
		do
			create l_term.make (create {VIRTUAL_TERMINAL}.make (70000, 2))
			assert ("width capped", l_term.width = 65535 and l_term.height = 2)
			create l_term.make (create {VIRTUAL_TERMINAL}.make (2, 70000))
			assert ("height capped", l_term.width = 2 and l_term.height = 65535)
			l_term.autoresize
			assert ("still capped", l_term.height = 65535)
		end

feature {NONE} -- Helpers

	assert_width (a_tag: STRING; a_text: STRING_32; a_expected: INTEGER)
			-- `a_text` is `a_expected` columns wide.
		do
			assert (a_tag + ": width " + {UNICODE_WIDTH}.string_width (a_text).out, {UNICODE_WIDTH}.string_width (a_text) = a_expected)
		end

	assert_cells (a_tag: STRING; a_buf: BUFFER; a_symbols: ARRAY [READABLE_STRING_GENERAL])
			-- Row 0 of `a_buf` holds `a_symbols`, one per cell from column 0.
		local
			i: INTEGER
		do
			from i := a_symbols.lower until i > a_symbols.upper loop
				assert_cell_symbol (a_tag + " [" + (i - a_symbols.lower).out + "]", a_buf, 0, i - a_symbols.lower, a_symbols [i])
				i := i + 1
			end
		end

	assert_cluster (a_tag: STRING; a_text: STRING_32; a_end, a_width: INTEGER)
			-- `a_text` starts with one cluster ending at `a_end`, `a_width` columns wide.
		do
			assert (a_tag + ": end " + {UNICODE_WIDTH}.grapheme_end (a_text, 1).out, {UNICODE_WIDTH}.grapheme_end (a_text, 1) = a_end)
			assert (a_tag + ": width " + {UNICODE_WIDTH}.grapheme_width (a_text.substring (1, a_end)).out,
				{UNICODE_WIDTH}.grapheme_width (a_text.substring (1, a_end)) = a_width)
		end

	assert_wide_cell (a_tag: STRING; a_buf: BUFFER; a_col: INTEGER; a_symbol: READABLE_STRING_GENERAL)
			-- Row 0 of `a_buf` has the two-column cell `a_symbol` at `a_col`, then its continuation.
		do
			assert_cell_symbol (a_tag, a_buf, 0, a_col, a_symbol)
			assert (a_tag + ": two columns", a_buf.cell (0, a_col).width = 2 and a_buf.cell (0, a_col + 1).is_continuation)
		end

	block_heights: ARRAYED_LIST [INTEGER]
			-- Heights of the blocks the drawing agents were given
		attribute
			create Result.make (2)
		end

	block_firsts: ARRAYED_LIST [INTEGER]
			-- First rows of the blocks `draw_rows_from` and `record_block` were given
		attribute
			create Result.make (2)
		end

	next_row_number: INTEGER
			-- Rows drawn so far by `draw_numbered_rows`

	draw_numbered_rows (a_block: BUFFER)
			-- Number the rows of `a_block` from `next_row_number` + 1 on (for `insert_before`).
		local
			r: INTEGER
		do
			block_heights.extend (a_block.height)
			from r := 0 until r >= a_block.height loop
				next_row_number := next_row_number + 1
				a_block.put_string (r, 0, next_row_number.out, create {STYLE})
				r := r + 1
			end
		end

	draw_rows_from (a_block: BUFFER; a_first: INTEGER)
			-- Number the rows of `a_block` from `a_first` + 1 on (for `insert_before_rows`).
		local
			r: INTEGER
		do
			record_block (a_block, a_first)
			from r := 0 until r >= a_block.height loop
				a_block.put_string (r, 0, (a_first + r + 1).out, create {STYLE})
				r := r + 1
			end
		end

	record_block (a_block: BUFFER; a_first: INTEGER)
			-- Record the height and first row of `a_block`; draw nothing.
		do
			block_heights.extend (a_block.height)
			block_firsts.extend (a_first)
		end

	small_inline_terminal: TERMINAL [VIRTUAL_TERMINAL]
			-- Terminal on a 6 x 5 virtual terminal, inline viewport of 2 rows at row 0, inserted
			-- rows drawn in blocks of 3
		local
			l_vt: VIRTUAL_TERMINAL
		do
			create l_vt.make (6, 5)
			l_vt.move_cursor (0, 0)
			create Result.make_with_viewport (l_vt, create {VIEWPORT}.make_inline (2))
			Result.setup_inline_viewport
			Result.set_insert_block_limit (3)
		end

	assert_blocks (a_tag: STRING; a_heights: ARRAY [INTEGER]; a_firsts: detachable ARRAY [INTEGER])
			-- The agent got blocks of `a_heights` rows, and when given, from rows `a_firsts`.
		local
			i: INTEGER
		do
			assert (a_tag + ": " + block_heights.count.out + " blocks", block_heights.count = a_heights.count)
			from i := 1 until i > a_heights.count loop
				assert (a_tag + ": block " + i.out + " height", block_heights [i] = a_heights [i])
				if attached a_firsts as l_firsts then
					assert (a_tag + ": block " + i.out + " first row", block_firsts [i] = l_firsts [i])
				end
				i := i + 1
			end
		end

	assert_inserted_rows (a_tag: STRING; a_vt: VIRTUAL_TERMINAL; a_term: TERMINAL [VIRTUAL_TERMINAL]; a_count: INTEGER)
			-- Rows "1" .. `a_count` were inserted above the 2-row viewport of `a_term`, which
			-- started at row 0 of `a_vt`: the oldest are in the scrollback in order, the newest on
			-- the rows above the viewport, and the viewport has moved down as far as they need.
		local
			i, l_room, l_on_screen: INTEGER
		do
			l_room := a_vt.height - 2
			l_on_screen := a_count.min (l_room)
			assert (a_tag + ": viewport row", a_term.viewport_origin_row = l_on_screen)
			assert (a_tag + ": scrollback " + a_vt.scrollback.count.out, a_vt.scrollback.count = a_count - l_on_screen)
			from i := 1 until i > a_vt.scrollback.count loop
				assert (a_tag + ": scrollback row " + i.out, a_vt.scrollback [i].starts_with ((i.out + " ").to_string_32))
				i := i + 1
			end
			from i := 0 until i >= l_on_screen loop
				assert (a_tag + ": screen row " + i.out + " is " + a_vt.line (i).out,
					a_vt.line (i).starts_with ((((a_count - l_on_screen) + i + 1).out + " ").to_string_32))
				i := i + 1
			end
		end

	assert_slice (a_tag: STRING; a_buf: BUFFER; a_row, a_col: INTEGER; a_symbols: ARRAY [READABLE_STRING_GENERAL])
			-- Row `a_row` of `a_buf` holds `a_symbols`, one per cell from column `a_col`.
		local
			i: INTEGER
		do
			from i := a_symbols.lower until i > a_symbols.upper loop
				assert_cell_symbol (a_tag + " [" + (a_col + i - a_symbols.lower).out + "]", a_buf, a_row, a_col + i - a_symbols.lower, a_symbols [i])
				i := i + 1
			end
		end

	assert_green (a_tag: STRING; a_buf: BUFFER)
			-- Every cell of row 0 that is not a continuation cell has a green background.
		local
			c: INTEGER
		do
			from c := 0 until c >= a_buf.width loop
				if not a_buf.cell (0, c).is_continuation then
					assert (a_tag + ": green " + c.out, a_buf.cell (0, c).style.background.is_equal ({COLOR}.Green))
				end
				c := c + 1
			end
		end

	assert_inner (a_tag: STRING; a_borders: NATURAL_8; a_area, a_expected: RECT)
			-- A block with `a_borders` has inner area `a_expected` in `a_area`.
		do
			assert_rect (a_tag, (create {TUI_BLOCK}).with_borders (a_borders).inner (a_area), a_expected)
		end

	assert_rect (a_tag: STRING; a_actual, a_expected: RECT)
			-- `a_actual` is `a_expected`.
		do
			assert (a_tag + ": expected " + a_expected.out + " but got " + a_actual.out, a_actual.is_equal (a_expected))
		end

	string_buffer (a_text: STRING_32; a_width: INTEGER): BUFFER
			-- `a_text` written at (0, 0) of a new `a_width` x 1 buffer
		do
			create Result.make (a_width, 1)
			Result.put_string (0, 0, a_text, create {STYLE})
		end

	green_paragraph (a_text: STRING_32): BUFFER
			-- A paragraph of `a_text` on a green background, rendered in 10 x 1
		do
			create Result.make (10, 1);
			(create {TUI_PARAGRAPH}.make_raw (a_text)).with_style (create {STYLE}.make_bg ({COLOR}.Green)).render (Result.area, Result)
		end

	x_buffer: BUFFER
			-- 15 x 7 buffer of 'x' (Ratatui `Buffer::with_lines(["xxxxxxxxxxxxxxx"; 7])`)
		do
			create Result.make (15, 7)
			Result.fill ('x', create {STYLE})
		end

	no_borders: TUI_BLOCK
			-- Block without borders (Ratatui `Block::new`)
		do
			Result := (create {TUI_BLOCK}).with_borders ({BORDERS}.none)
		end

	titled_block: TUI_BLOCK
			-- Bordered block with a centred top title "Title" and a centred bottom title "Bottom"
		do
			Result := (create {TUI_BLOCK}).with_title_top ("Title", {TEXT_ALIGNMENT}.center)
				.with_title_bottom ("Bottom", {TEXT_ALIGNMENT}.center)
		end

	block_buffer (a_area: RECT): BUFFER
			-- `titled_block` rendered in `a_area` of a new 6 x 4 buffer, checked for consistency
		do
			create Result.make (6, 4)
			titled_block.render (a_area, Result)
			assert ("consistent after " + a_area.out, Result.is_consistent)
		end

	plain_block_buffer (a_area: RECT): BUFFER
			-- A bordered block without titles rendered in `a_area` of a new 6 x 4 buffer, checked
			-- for consistency
		do
			create Result.make (6, 4)
			(create {TUI_BLOCK}).render (a_area, Result)
			assert ("consistent after " + a_area.out, Result.is_consistent)
		end

	rendered (a_widget: WIDGET; a_width, a_height: INTEGER): BUFFER
			-- `a_widget` rendered into a new `a_width` x `a_height` buffer
		do
			create Result.make (a_width, a_height)
			a_widget.render (Result.area, Result)
		end

	rect (a_x, a_y, a_width, a_height: NATURAL_16): RECT
			-- New rectangle
		do
			create Result.make (a_x, a_y, a_width, a_height)
		end

	repeated (c: CHARACTER_32; n: INTEGER): STRING_32
			-- `c` repeated `n` times
		do
			create Result.make_filled (c, n)
		end

	make_buffer (a_width, a_height: INTEGER)
			-- Create a buffer (for `precondition_raised`).
		local
			l_buf: BUFFER
		do
			create l_buf.make (a_width, a_height)
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
