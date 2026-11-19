note
	description: "[
		Autotest for TEXT_AREA_STATE / TUI_TEXT_AREA: newlines, grapheme cursor,
		selection, undo, and buffer snapshots.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_TEXT_AREA

inherit
	EQA_TEST_SET

feature -- State

	test_newline_and_navigation
			-- Enter inserts LF; up/down move between hard lines.
		local
			l_state: TEXT_AREA_STATE
		do
			create l_state.default_create
			l_state.insert_string ("hello")
			l_state.insert_newline
			l_state.insert_string ("world")
			assert ("has newline", l_state.value.has ('%N'))
			assert ("two lines", l_state.line_count = 2)
			l_state.move_cursor_home (False)
			assert ("line start", l_state.cursor_position = 6)
			l_state.move_cursor_up (False)
			assert ("on first line", l_state.hard_line_index (l_state.cursor_position) = 0)
			l_state.move_cursor_end (False)
			assert ("end of hello", l_state.cursor_position = 5)
		end

	test_grapheme_delete
			-- Backspace removes a whole grapheme cluster.
		local
			l_state: TEXT_AREA_STATE
			l_flag: STRING_32
		do
			create l_flag.make_empty
			l_flag.append_code (0x1F1E6) -- regional A
			l_flag.append_code (0x1F1E8) -- regional C (flag)
			create l_state.make_with_text (l_flag)
			assert ("cursor at end", l_state.cursor_position = l_flag.count)
			l_state.delete_backward
			assert ("flag removed", l_state.value.is_empty)
		end

	test_selection_and_undo
			-- Selection replace and undo restore prior text.
		local
			l_state: TEXT_AREA_STATE
		do
			create l_state.make_with_text ("abcdef")
			l_state.set_cursor_position (0)
			l_state.set_selection_anchor (0)
			l_state.set_cursor_position (3)
			assert ("selected", l_state.has_selection)
			l_state.insert_string ("X")
			assert ("replaced", l_state.value.same_string ("Xdef"))
			assert ("can undo", l_state.can_undo)
			l_state.undo
			assert ("restored", l_state.value.same_string ("abcdef"))
		end

	test_render_snapshot
			-- Multi-line content paints on separate rows inside the block, row-exact; the
			-- cursor (at the end of the text) is the blank reversed cell after "two".
		local
			l_state: TEXT_AREA_STATE
			l_widget: TUI_TEXT_AREA
			l_buf: BUFFER
			l_area: RECT
			l_block: TUI_BLOCK
		do
			create l_state.make_with_text ("one%Ntwo")
			create l_widget.make
			create l_block.make
			l_widget := l_widget.with_block (l_block.with_borders ({BORDERS}.all_borders))
			create l_buf.make (12, 6)
			create l_area.make (0, 0, 12, 6)
			l_widget.render_stateful (l_area, l_buf, l_state)
			assert_rows ("boxed", l_buf, <<top_border (10), boxed ("one       "), boxed ("two       "),
				boxed ("          "), boxed ("          "), bottom_border (10)>>)
			assert_cursor ("after two", l_widget, l_area, l_buf, l_state, 4, 2)
			assert ("o of two plain", not l_buf.cell (2, 3).style.is_reversed)
		end

	test_backspace_after_extend_leaves_no_selection
			-- H3 / P1: Shift+Left then Shift+Right returns to the anchor; Backspace
			-- deletes one grapheme and leaves no phantom selection.
		local
			l_state: TEXT_AREA_STATE
		do
			create l_state.make_with_text ("abc")
			l_state.set_cursor_position (2)
			l_state.move_cursor_left (True)
			l_state.move_cursor_right (True)
			assert ("anchor dropped on return", l_state.selection_anchor = -1)
			l_state.delete_backward
			assert ("deleted b", l_state.value.same_string ("ac"))
			assert ("cursor 1", l_state.cursor_position = 1)
			assert ("no selection", not l_state.has_selection)
			assert ("anchor cleared", l_state.selection_anchor = -1)
			l_state.move_cursor_right (False)
			assert ("plain move keeps no selection", not l_state.has_selection)
		end

	test_delete_with_stale_anchor_keeps_invariant
			-- H3 / P2: an anchor at the end must not outlive a deletion
			-- (it used to break `valid_anchor`).
		local
			l_state: TEXT_AREA_STATE
		do
			create l_state.make_with_text ("ab")
			l_state.move_cursor_right (True)
			l_state.delete_backward
			assert ("backspace ok", l_state.value.same_string ("a"))
			assert ("anchor cleared", l_state.selection_anchor = -1)
				-- Anchor set directly on the cursor, then Backspace.
			l_state.set_selection_anchor (1)
			l_state.delete_backward
			assert ("emptied", l_state.value.is_empty)
			assert ("anchor cleared after api anchor", l_state.selection_anchor = -1)
				-- Delete key with an anchor at the start.
			create l_state.make_with_text ("xy")
			l_state.set_cursor_position (0)
			l_state.move_cursor_left (True)
			l_state.set_selection_anchor (0)
			l_state.delete_forward
			assert ("delete ok", l_state.value.same_string ("y"))
			assert ("anchor cleared by delete", l_state.selection_anchor = -1)
			l_state.move_cursor_end (False)
			assert ("cursor valid", l_state.cursor_position = 1)
		end

	test_scroll_follows_wrapped_rows
			-- H2 / P3: scrolling counts visual (wrapped) rows, so the cursor stays on screen.
		local
			l_state: TEXT_AREA_STATE
			l_widget: TUI_TEXT_AREA
			l_buf: BUFFER
			l_text: STRING_32
		do
			create l_text.make_filled ('a', 50)
			l_text.append ("%Nx")
			create l_state.make_with_text (l_text)
			create l_widget.make
			create l_buf.make (10, 3)
			l_widget.render_stateful (l_buf.area, l_buf, l_state)
			assert ("scrolled to visual row 3", l_state.scroll_row = 3)
			assert_rows ("bottom of text", l_buf, <<"aaaaaaaaaa", "aaaaaaaaaa", "x         ">>)
			if attached l_widget.cursor_screen_position (l_buf.area, l_state) as c then
				assert ("cursor col after x", c.col = 1)
				assert ("cursor on last row", c.row = 2)
			else
				assert ("cursor visible", False)
			end
				-- Back to the top.
			l_state.set_cursor_position (0)
			l_widget.render_stateful (l_buf.area, l_buf, l_state)
			assert ("scrolled to top", l_state.scroll_row = 0)
			assert ("top cursor visible", l_widget.cursor_screen_position (l_buf.area, l_state) /= Void)
				-- Content shrinks below the scroll origin: no blank viewport.
			l_state.set_cursor_position (l_state.value.count)
			l_widget.render_stateful (l_buf.area, l_buf, l_state)
			l_state.set_value ("one%Ntwo")
			create l_buf.make (10, 3)
			l_widget.render_stateful (l_buf.area, l_buf, l_state)
			assert ("scroll clamped", l_state.scroll_row = 0)
			assert_rows ("short text", l_buf, <<"one       ", "two       ", "          ">>)
		end

	test_scroll_row_inside_bordered_block
			-- H2: the viewport height is the inner area of the block.
		local
			l_state: TEXT_AREA_STATE
			l_widget: TUI_TEXT_AREA
			l_block: TUI_BLOCK
			l_buf: BUFFER
		do
			create l_state.make_with_text ("1%N2%N3%N4%N5")
			create l_block.make
			create l_widget.make
			l_widget := l_widget.with_block (l_block.with_borders ({BORDERS}.all_borders))
			create l_buf.make (5, 4)
			l_widget.render_stateful (l_buf.area, l_buf, l_state)
			assert ("two inner rows, last two lines", l_state.scroll_row = 3)
			assert_rows ("last two lines", l_buf, <<top_border (3), boxed ("4  "), boxed ("5  "), bottom_border (3)>>)
			assert_cursor ("after 5", l_widget, l_buf.area, l_buf, l_state, 2, 2)
		end

	test_scroll_moves_by_the_fewest_rows
			-- T1 / P3: the view scrolls only as far as needed to keep the cursor's visual row
			-- in sight: not at all while the row is visible, one row at a time at the edges,
			-- in both directions, over soft-wrapped and hard rows. Visual rows of
			-- "aaaabbbbcc%Ndd" in 4 columns: "aaaa" (0), "bbbb" (4), "cc" (8), "dd" (11).
		local
			l_state: TEXT_AREA_STATE
			l_widget: TUI_TEXT_AREA
			l_buf: BUFFER
		do
			create l_state.make_with_text ("aaaabbbbcc%Ndd")
			l_state.set_cursor_position (0)
			create l_widget.make
			l_buf := rendered (l_widget, l_state, 4, 2)
			assert_rows ("top", l_buf, <<"aaaa", "bbbb">>)
			assert_cursor ("top", l_widget, l_buf.area, l_buf, l_state, 0, 0)
			l_state.move_cursor_down (False)
			l_buf := rendered (l_widget, l_state, 4, 2)
			assert ("row 1 visible: no scroll", l_state.cursor_position = 4 and l_state.scroll_row = 0)
			assert_rows ("no scroll", l_buf, <<"aaaa", "bbbb">>)
			assert_cursor ("second row", l_widget, l_buf.area, l_buf, l_state, 0, 1)
			l_state.move_cursor_down (False)
			l_buf := rendered (l_widget, l_state, 4, 2)
			assert ("one row down", l_state.cursor_position = 8 and l_state.scroll_row = 1)
			assert_rows ("one row down", l_buf, <<"bbbb", "cc  ">>)
			assert_cursor ("on the bottom row", l_widget, l_buf.area, l_buf, l_state, 0, 1)
			l_state.move_cursor_down (False)
			l_buf := rendered (l_widget, l_state, 4, 2)
			assert ("over the hard break", l_state.cursor_position = 11 and l_state.scroll_row = 2)
			assert_rows ("bottom", l_buf, <<"cc  ", "dd  ">>)
			assert_cursor ("on dd", l_widget, l_buf.area, l_buf, l_state, 0, 1)
			l_state.move_cursor_up (False)
			l_buf := rendered (l_widget, l_state, 4, 2)
			assert ("up inside the view: no scroll", l_state.cursor_position = 8 and l_state.scroll_row = 2)
			assert_rows ("still bottom", l_buf, <<"cc  ", "dd  ">>)
			assert_cursor ("on cc", l_widget, l_buf.area, l_buf, l_state, 0, 0)
			l_state.move_cursor_up (False)
			l_buf := rendered (l_widget, l_state, 4, 2)
			assert ("one row up", l_state.cursor_position = 4 and l_state.scroll_row = 1)
			assert_rows ("one row up", l_buf, <<"bbbb", "cc  ">>)
			assert_cursor ("on the top row", l_widget, l_buf.area, l_buf, l_state, 0, 0)
		end

	test_word_wrap_scroll_and_cursor
			-- T1 / P3 + P6: word-wrapped rows scroll with the cursor, and the cursor cell
			-- follows the rows. "one two three four" in 6 columns wraps to "one " / "two " /
			-- "three " / "four" (offsets 0, 4, 8, 14); 2 rows are visible.
		local
			l_state: TEXT_AREA_STATE
			l_widget: TUI_TEXT_AREA
			l_buf: BUFFER
		do
			create l_state.make_with_text ("one two three four")
			create l_widget.make
			l_widget.set_wrap_mode ({TEXT_WRAP_MODE}.word)
			l_buf := rendered (l_widget, l_state, 6, 2)
			assert ("cursor at the end, last two rows", l_state.scroll_row = 2)
			assert_rows ("end", l_buf, <<"three ", "four  ">>)
			assert_cursor ("after four", l_widget, l_buf.area, l_buf, l_state, 4, 1)
			l_state.move_cursor_up (False)
			l_buf := rendered (l_widget, l_state, 6, 2)
			assert ("same column on three: cursor " + l_state.cursor_position.out + " scroll " + l_state.scroll_row.out,
				l_state.cursor_position = 12 and l_state.scroll_row = 2)
			assert_cursor ("on the second e", l_widget, l_buf.area, l_buf, l_state, 4, 0)
			assert ("e kept", l_buf.cell (0, 4).symbol.same_string ({STRING_32} "e"))
			l_state.move_cursor_up (False)
			l_buf := rendered (l_widget, l_state, 6, 2)
			assert ("before the space of two", l_state.cursor_position = 7 and l_state.scroll_row = 1)
			assert_rows ("middle", l_buf, <<"two   ", "three ">>)
			assert_cursor ("on the space of two", l_widget, l_buf.area, l_buf, l_state, 3, 0)
			l_state.move_cursor_up (False)
			l_buf := rendered (l_widget, l_state, 6, 2)
			assert ("before the space of one", l_state.cursor_position = 3 and l_state.scroll_row = 0)
			assert_rows ("top", l_buf, <<"one   ", "two   ">>)
			assert_cursor ("on the space of one", l_widget, l_buf.area, l_buf, l_state, 3, 0)
		end

	test_cursor_position_in_offset_scrolled_block
			-- T1 / P3 + P4: in a bordered area that does not start at the buffer's origin,
			-- the scrolled rows are drawn inside the block only, and the cursor's screen cell
			-- is in buffer coordinates. "ab%Ncd%Nef" in the 4x2 inner area of (3, 2, 6, 4).
		local
			l_state: TEXT_AREA_STATE
			l_widget: TUI_TEXT_AREA
			l_block: TUI_BLOCK
			l_buf: BUFFER
			l_area: RECT
		do
			create l_state.make_with_text ("ab%Ncd%Nef")
			create l_block.make
			create l_widget.make
			l_widget := l_widget.with_block (l_block.with_borders ({BORDERS}.all_borders))
			create l_buf.make (10, 7)
			create l_area.make (3, 2, 6, 4)
			l_widget.render_stateful (l_area, l_buf, l_state)
			assert ("scrolled one row", l_state.scroll_row = 1)
			assert_rows ("placed", l_buf, {ARRAY [STRING_32]} <<"          ", "          ",
				{STRING_32} "   " + top_border (4) + " ", {STRING_32} "   " + boxed ("cd  ") + " ",
				{STRING_32} "   " + boxed ("ef  ") + " ", {STRING_32} "   " + bottom_border (4) + " ", "          ">>)
			assert_cursor ("after ef", l_widget, l_area, l_buf, l_state, 6, 4)
		end

	test_selection_and_cursor_cell_styles
			-- T1 / P4 + P5: the cell attributes of a selection and of the cursor. Selected
			-- cells get `selection_style` (black on bright blue by default, or the style set
			-- with `set_selection_style`); the cursor inside the selection keeps it and is
			-- reversed on top; unselected cells keep the body style. A selection that starts
			-- above the view is highlighted from the first visible row.
		local
			l_state: TEXT_AREA_STATE
			l_widget: TUI_TEXT_AREA
			l_buf: BUFFER
			c: INTEGER
		do
				-- "abcdef", cursor 4, Shift+Left twice: [2, 4) selected, cursor on c
			create l_state.make_with_text ("abcdef")
			l_state.set_cursor_position (4)
			l_state.move_cursor_left (True)
			l_state.move_cursor_left (True)
			create l_widget.make
			l_buf := rendered (l_widget, l_state, 6, 1)
			assert_rows ("text kept", l_buf, <<"abcdef">>)
			from c := 0 until c > 5 loop
				if c = 2 or c = 3 then
					assert ("selected colours at " + c.out, l_buf.cell (0, c).style.foreground ~ {COLOR}.Black
						and l_buf.cell (0, c).style.background ~ {COLOR}.Bright_blue)
				else
					assert ("body style at " + c.out, l_buf.cell (0, c).style.background /~ {COLOR}.Bright_blue
						and l_buf.cell (0, c).style.foreground /~ {COLOR}.Black and not l_buf.cell (0, c).style.is_reversed)
				end
				c := c + 1
			end
			assert ("cursor on c reversed", l_buf.cell (0, 2).style.is_reversed)
			assert ("d not reversed", not l_buf.cell (0, 3).style.is_reversed)
				-- A custom selection style
			l_widget.set_selection_style ((create {STYLE}.default_create).with_underline)
			l_buf := rendered (l_widget, l_state, 6, 1)
			assert ("custom style on c and d", l_buf.cell (0, 2).style.is_underlined and l_buf.cell (0, 3).style.is_underlined)
			assert ("not on b and e", not l_buf.cell (0, 1).style.is_underlined and not l_buf.cell (0, 4).style.is_underlined)
			assert ("no default colours left", l_buf.cell (0, 3).style.background /~ {COLOR}.Bright_blue)
				-- "ab%Ncd%Nef", [1, 7) selected, cursor on f, 2 rows visible
			create l_state.make_with_text ("ab%Ncd%Nef")
			l_state.set_selection_anchor (1)
			l_state.set_cursor_position (7)
			create l_widget.make
			l_buf := rendered (l_widget, l_state, 4, 2)
			assert_rows ("scrolled", l_buf, <<"cd  ", "ef  ">>)
			assert ("row 0 SS..", selection_map (l_buf, 0, 4).same_string ("SS.."))
			assert ("row 1 S...", selection_map (l_buf, 1, 4).same_string ("S..."))
			assert_cursor ("on f", l_widget, l_buf.area, l_buf, l_state, 1, 1)
		end

	test_cursor_keeps_character_under_it
			-- M1 / P4: the cursor reverses the grapheme under it instead of blanking it;
			-- at the end of a line it is a blank reversed cell.
		local
			l_state: TEXT_AREA_STATE
			l_widget: TUI_TEXT_AREA
			l_buf: BUFFER
			l_wide: STRING_32
		do
			create l_state.make_with_text ("abc%Nd")
			l_state.set_cursor_position (1)
			create l_widget.make
			create l_buf.make (6, 2)
			l_widget.render_stateful (l_buf.area, l_buf, l_state)
			assert_rows ("text kept", l_buf, <<"abc   ", "d     ">>)
			assert ("b reversed", l_buf.cell (0, 1).style.is_reversed)
			assert ("a plain", not l_buf.cell (0, 0).style.is_reversed)
			assert ("c plain", not l_buf.cell (0, 2).style.is_reversed)
				-- End of a hard line (before its LF).
			l_state.move_cursor_end (False)
			create l_buf.make (6, 2)
			l_widget.render_stateful (l_buf.area, l_buf, l_state)
			assert_rows ("text kept at end", l_buf, <<"abc   ", "d     ">>)
			assert ("blank cursor after c", l_buf.cell (0, 3).style.is_reversed)
			assert ("c not reversed", not l_buf.cell (0, 2).style.is_reversed)
				-- Wide grapheme: both of its columns are covered by one styled cell.
			create l_wide.make_empty
			l_wide.append_code (0x4E2D)
			create l_state.make_with_text ({STRING_32} "x" + l_wide)
			l_state.set_cursor_position (1)
			create l_buf.make (6, 1)
			l_widget.render_stateful (l_buf.area, l_buf, l_state)
			assert ("wide kept", l_buf.cell (0, 1).symbol.same_string (l_wide))
			assert ("wide reversed", l_buf.cell (0, 1).style.is_reversed)
		end

	test_selection_highlights_only_the_range
			-- M2 / P5: only the selected columns get `selection_style`, also across rows.
		local
			l_state: TEXT_AREA_STATE
			l_widget: TUI_TEXT_AREA
			l_buf: BUFFER
		do
			create l_state.make_with_text ("abcdef")
			l_state.set_cursor_position (1)
			l_state.move_cursor_right (True)
			create l_widget.make
			l_widget.set_shows_cursor (False)
			create l_buf.make (6, 1)
			l_widget.render_stateful (l_buf.area, l_buf, l_state)
			assert ("map .S....", selection_map (l_buf, 0, 6).same_string (".S...."))
				-- Across a hard line break: "ab|cd" with [1, 4) selected.
			create l_state.make_with_text ("ab%Ncd")
			l_state.set_selection_anchor (1)
			l_state.set_cursor_position (4)
			create l_buf.make (4, 2)
			l_widget.render_stateful (l_buf.area, l_buf, l_state)
			assert ("row 0 .S..", selection_map (l_buf, 0, 4).same_string (".S.."))
			assert ("row 1 S...", selection_map (l_buf, 1, 4).same_string ("S..."))
				-- Across a soft wrap: "abcdef" in 4 columns, [2, 5) selected.
			create l_state.make_with_text ("abcdef")
			l_state.set_selection_anchor (2)
			l_state.set_cursor_position (5)
			create l_buf.make (4, 2)
			l_widget.render_stateful (l_buf.area, l_buf, l_state)
			assert_rows ("wrapped", l_buf, <<"abcd", "ef  ">>)
			assert ("wrap row 0 ..SS", selection_map (l_buf, 0, 4).same_string ("..SS"))
			assert ("wrap row 1 S...", selection_map (l_buf, 1, 4).same_string ("S..."))
		end

	test_word_wrap_breaks_at_spaces
			-- L4 / P6: `word` mode wraps after the last space; spaces hang past the width.
		local
			l_state: TEXT_AREA_STATE
			l_widget: TUI_TEXT_AREA
			l_buf: BUFFER
		do
			create l_state.make_with_text ("hello world")
			l_state.set_cursor_position (0)
			create l_widget.make
			l_widget.set_wrap_mode ({TEXT_WRAP_MODE}.word)
			create l_buf.make (8, 3)
			l_widget.render_stateful (l_buf.area, l_buf, l_state)
			assert_rows ("word rows", l_buf, <<"hello   ", "world   ", "        ">>)
				-- A word longer than the width still breaks by character.
			create l_state.make_with_text ("ab abcdefghij")
			create l_buf.make (5, 4)
			l_widget.render_stateful (l_buf.area, l_buf, l_state)
			assert_rows ("long word", l_buf, <<"ab   ", "abcde", "fghij", "     ">>)
				-- Hanging spaces: "hello world" in 5 columns keeps the space on row 0.
			create l_state.make_with_text ("hello world")
			l_state.set_cursor_position (5)
			create l_buf.make (5, 2)
			l_widget.render_stateful (l_buf.area, l_buf, l_state)
			assert_rows ("hanging", l_buf, <<"hello", "world">>)
			if attached l_widget.cursor_screen_position (l_buf.area, l_state) as c then
				assert ("cursor on hanging space stays inside", c.col = 4 and c.row = 0)
			else
				assert ("cursor shown", False)
			end
		end

	test_cursor_after_full_row_is_inside_area
			-- L4: at the end of a wrapped line that fills the width, the cursor goes to an
			-- empty row below instead of the column past the area.
		local
			l_state: TEXT_AREA_STATE
			l_widget: TUI_TEXT_AREA
			l_buf: BUFFER
		do
			create l_state.make_with_text ("aaaaaaaaaa")
			create l_widget.make
			create l_buf.make (10, 2)
			l_widget.render_stateful (l_buf.area, l_buf, l_state)
			if attached l_widget.cursor_screen_position (l_buf.area, l_state) as c then
				assert ("col 0 of the next row", c.col = 0 and c.row = 1)
			else
				assert ("cursor shown", False)
			end
			assert ("blank cursor cell", l_buf.cell (1, 0).style.is_reversed)
				-- Cursor not at the end: no extra row.
			l_state.set_cursor_position (3)
			create l_buf.make (10, 2)
			l_widget.render_stateful (l_buf.area, l_buf, l_state)
			assert_rows ("one row", l_buf, <<"aaaaaaaaaa", "          ">>)
				-- Without wrap, a cursor past the right edge is hidden, not drawn outside.
			l_widget.set_wrap_mode ({TEXT_WRAP_MODE}.none)
			l_state.set_cursor_position (10)
			assert ("no wrap: off-screen", l_widget.cursor_screen_position (create {RECT}.make (0, 0, 10, 1), l_state) = Void)
		end

	test_up_down_move_by_visual_rows
			-- L4: after a render, Up/Down move by wrapped rows and keep the goal column;
			-- after an edit they fall back to hard lines until the next render.
		local
			l_state: TEXT_AREA_STATE
			l_widget: TUI_TEXT_AREA
			l_buf: BUFFER
			l_text: STRING_32
		do
			create l_text.make_filled ('a', 25)
			l_text.append ("%Nbb")
			create l_state.make_with_text (l_text)
			l_state.set_cursor_position (23)
			create l_widget.make
			create l_buf.make (10, 5)
			l_widget.render_stateful (l_buf.area, l_buf, l_state)
			assert ("layout recorded", l_state.has_visual_rows)
			l_state.move_cursor_up (False)
			assert ("up one row", l_state.cursor_position = 13)
			l_state.move_cursor_up (False)
			assert ("up to first row", l_state.cursor_position = 3)
			l_state.move_cursor_up (False)
			assert ("first row stays", l_state.cursor_position = 3)
			l_state.move_cursor_down (False)
			l_state.move_cursor_down (False)
			assert ("back on row 3", l_state.cursor_position = 23)
				-- Row 4 is "bb": clamp to its end, keep the goal for the way back.
			l_state.move_cursor_down (False)
			assert ("clamped on bb", l_state.cursor_position = 28)
			l_state.move_cursor_up (False)
			assert ("goal column kept", l_state.cursor_position = 23)
				-- Shift+Down extends the selection by rows.
			l_state.set_cursor_position (3)
			l_state.move_cursor_down (True)
			assert ("selection by rows", l_state.has_selection and l_state.selection_start = 3 and l_state.selection_end = 13)
				-- An edit drops the layout: hard-line movement.
			l_state.insert_character ('x')
			assert ("layout dropped", not l_state.has_visual_rows)
			l_state.move_cursor_down (False)
			assert ("hard line down to bb", l_state.hard_line_index (l_state.cursor_position) = 1)
				-- Word wrap: rows "hi " / "there " / "world". A goal past the end of a row
				-- that continues on the next row stops before its last grapheme.
			create l_state.make_with_text ("hi there world")
			l_state.set_cursor_position (8)
			l_widget.set_wrap_mode ({TEXT_WRAP_MODE}.word)
			create l_buf.make (7, 3)
			l_widget.render_stateful (l_buf.area, l_buf, l_state)
			assert_rows ("word rows", l_buf, <<"hi     ", "there  ", "world  ">>)
			l_state.move_cursor_up (False)
			assert ("stays on row 0, before its space", l_state.cursor_position = 2)
			l_state.move_cursor_down (False)
			assert ("goal 5 back on row 1", l_state.cursor_position = 8)
		end

	test_loaded_text_keeps_cursor_column
			-- L6: after `make_with_text`, `set_value` or `select_all` (no render, so hard
			-- lines), the first Up or Down keeps the cursor's column, not column 0 or a
			-- column from the text before.
		local
			l_state: TEXT_AREA_STATE
		do
				-- "abc" / "hello" / "xyz12": the cursor starts at the end, column 5.
			create l_state.make_with_text ("abc%Nhello%Nxyz12")
			assert ("column of the end", l_state.preferred_column = 5)
			l_state.move_cursor_up (False)
			assert ("up keeps column 5", l_state.cursor_position = 9)
			l_state.move_cursor_up (False)
			assert ("clamped on abc", l_state.cursor_position = 3)
			l_state.move_cursor_down (False)
			assert ("down back to column 5", l_state.cursor_position = 9)
			l_state.move_cursor_down (False)
			assert ("down to the end", l_state.cursor_position = 15)
				-- `set_value` clamps the cursor (10, column 10) into "xy" at column 1.
			create l_state.make_with_text ("abcdefghij")
			l_state.set_value ("abcdefgh%Nxy%Nlong line")
			assert ("clamped cursor", l_state.cursor_position = 10 and l_state.preferred_column = 1)
			l_state.move_cursor_down (False)
			assert ("down keeps column 1", l_state.cursor_position = 13)
				-- `select_all` puts the cursor at the end, column 4 of "cdef".
			create l_state.make_with_text ("ab%Ncdef")
			l_state.set_cursor_position (0)
			l_state.select_all
			l_state.move_cursor_up (True)
			assert ("up clamped on ab", l_state.cursor_position = 2)
			assert ("selection kept", l_state.has_selection and l_state.selection_start = 0 and l_state.selection_end = 2)
		end

	test_editing_large_text_is_line_local
			-- M3 / P7: grapheme lookups segment from the line start, so typing and moving in
			-- a 250-line text no longer cost O(text) each (was 64 ms per key).
		local
			l_state: TEXT_AREA_STATE
			l_text: STRING_32
			i, l_start, l_elapsed: INTEGER_64
		do
			create l_text.make (20_250)
			from i := 1 until i > 250 loop
				l_text.append (create {STRING_32}.make_filled ('x', 80))
				l_text.append_character ('%N')
				i := i + 1
			end
			create l_state.make_with_text (l_text)
			l_start := {MONOTONIC_CLOCK}.milliseconds
			from i := 1 until i > 100 loop
				l_state.insert_character ('y')
				i := i + 1
			end
			from i := 1 until i > 100 loop
				l_state.move_cursor_left (False)
				i := i + 1
			end
			l_elapsed := {MONOTONIC_CLOCK}.milliseconds - l_start
			assert ("200 edits and moves under 1 s (was 12.5 s): " + l_elapsed.out + " ms", l_elapsed < 1000)
			assert ("typed", l_state.value.count = l_text.count + 100)
		end

	test_typing_groups_into_undo_steps
			-- L5: typed characters form one undo step per word; a move, a newline or another
			-- edit starts a new one.
		local
			l_state: TEXT_AREA_STATE
		do
			create l_state.default_create
			type_text (l_state, "hello")
			assert ("one step for the word", l_state.undo_count = 1 and l_state.is_undo_group_open)
			type_text (l_state, " world")
			assert ("second word, second step", l_state.undo_count = 2)
			l_state.undo
			assert ("word undone", l_state.value.same_string ("hello "))
			l_state.undo
			assert ("first word undone", l_state.value.is_empty)
			assert ("two steps only", not l_state.can_undo)
				-- A move ends the group
			type_text (l_state, "ab")
			l_state.move_cursor_left (False)
			type_text (l_state, "c")
			assert ("typed in the middle", l_state.value.same_string ("acb"))
			l_state.undo
			assert ("insert after the move undone alone", l_state.value.same_string ("ab"))
			l_state.undo
			assert ("then the first run", l_state.value.is_empty)
				-- A newline, a backspace and a paste are steps of their own
			type_text (l_state, "x")
			l_state.insert_newline
			type_text (l_state, "y")
			l_state.delete_backward
			l_state.insert_string ("pasted")
			l_state.undo
			assert ("paste undone", l_state.value.same_string ("x%N"))
			l_state.undo
			assert ("backspace undone", l_state.value.same_string ("x%Ny"))
			l_state.undo
			assert ("y undone", l_state.value.same_string ("x%N"))
			l_state.undo
			assert ("newline undone", l_state.value.same_string ("x"))
			l_state.undo
			assert ("all undone", l_state.value.is_empty and not l_state.can_undo)
		end

	test_no_op_edits_record_no_undo
			-- L5: edits that change nothing leave the undo stack alone.
		local
			l_state: TEXT_AREA_STATE
		do
			create l_state.make_with_text ("abc")
			l_state.set_cursor_position (0)
			l_state.delete_backward
			l_state.move_cursor_end (False)
			l_state.delete_forward
			l_state.insert_string ("")
			l_state.insert_character ('%/7/')
			l_state.set_value ("abc")
			assert ("unchanged", l_state.value.same_string ("abc"))
			assert ("nothing to undo", not l_state.can_undo)
				-- A control character changes nothing, so it does not split a typed run either
			type_text (l_state, "de")
			l_state.insert_character ('%/7/')
			type_text (l_state, "f")
			assert ("one step", l_state.value.same_string ("abcdef") and l_state.undo_count = 1)
			l_state.undo
			assert ("run undone at once", l_state.value.same_string ("abc") and not l_state.can_undo)
				-- A Delete at the end after a Backspace run neither records nor splits it
			l_state.delete_backward
			l_state.delete_forward
			l_state.delete_backward
			assert ("backspace step only", l_state.value.same_string ("a") and l_state.undo_count = 1)
			l_state.undo
			assert ("back to abc", l_state.value.same_string ("abc") and not l_state.can_undo)
				-- A selection replaced by nothing is an edit
			l_state.select_all
			l_state.insert_string ("")
			assert ("selection deleted", l_state.value.is_empty and l_state.can_undo)
		end

	test_redo_reverses_undo
			-- Redo: each `redo` goes forward over the last undone step, back to the text,
			-- cursor and selection as they were when it was undone; undo and redo can be
			-- mixed. With nothing to redo (or undo), nothing happens.
		local
			l_state: TEXT_AREA_STATE
		do
			create l_state.default_create
			l_state.redo
			assert ("nothing to redo at first", l_state.value.is_empty and not l_state.can_redo)
			type_text (l_state, "hello")
			type_text (l_state, " world")
			l_state.move_cursor_home (False)
			l_state.move_cursor_right (True)
			l_state.insert_string ("J")
			assert ("three steps", l_state.value.same_string ("Jello world") and l_state.undo_count = 3)
			l_state.undo
			assert ("replace undone, selection back", l_state.value.same_string ("hello world")
				and l_state.has_selection and l_state.selection_start = 0 and l_state.selection_end = 1)
			l_state.undo
			l_state.undo
			assert ("all undone", l_state.value.is_empty and l_state.redo_count = 3 and not l_state.can_undo)
			l_state.redo
			assert ("first word again, cursor after it", l_state.value.same_string ("hello ")
				and l_state.cursor_position = 6)
			l_state.redo
			assert ("second word again, cursor and selection as when undone", l_state.value.same_string ("hello world")
				and l_state.cursor_position = 1 and l_state.selection_start = 0 and l_state.selection_end = 1)
			l_state.undo
			assert ("undo after redo", l_state.value.same_string ("hello ") and l_state.redo_count = 2)
			l_state.redo
			l_state.redo
			assert ("replace again, cursor after it", l_state.value.same_string ("Jello world")
				and l_state.cursor_position = 1 and not l_state.has_selection)
			assert ("nothing left to redo", not l_state.can_redo and l_state.undo_count = 3)
			l_state.redo
			assert ("redo with nothing to redo changes nothing", l_state.value.same_string ("Jello world")
				and l_state.undo_count = 3)
			assert ("redo closes the typing step", not l_state.is_undo_group_open)
		end

	test_edit_forgets_redo
			-- Redo: an edit after an undo starts a new history, so what was undone can no
			-- longer be redone. Moves, selection changes and edits that change nothing keep it.
		local
			l_state: TEXT_AREA_STATE
		do
			create l_state.make_with_text ("abc")
			l_state.set_cursor_position (3)
			type_text (l_state, "d")
			l_state.undo
			assert ("can redo", l_state.can_redo and l_state.value.same_string ("abc"))
			l_state.move_cursor_left (False)
			l_state.move_cursor_left (True)
			l_state.clear_selection
			l_state.set_value ("abc")
			l_state.set_cursor_position (3)
			l_state.delete_forward
			l_state.set_cursor_position (0)
			l_state.delete_backward
			l_state.insert_string ("")
			assert ("moves and no-op edits keep redo", l_state.can_redo and l_state.value.same_string ("abc"))
			l_state.redo
			assert ("redone", l_state.value.same_string ("abcd") and l_state.cursor_position = 4)
			l_state.undo
			type_text (l_state, "x")
			assert ("an edit forgets redo", not l_state.can_redo and l_state.value.same_string ("abcx"))
			l_state.redo
			assert ("nothing redone", l_state.value.same_string ("abcx"))
				-- `set_value` that changes the text is an edit too
			l_state.undo
			assert ("can redo again", l_state.can_redo)
			l_state.set_value ("other")
			assert ("set_value forgets redo", not l_state.can_redo and l_state.value.same_string ("other"))
		end

	test_undo_and_redo_share_the_bound
			-- Redo: undo and redo steps together stay within `Max_undo`. Undoing everything
			-- and redoing it all gives back the last text, with every step still undoable.
		local
			l_state: TEXT_AREA_STATE
			i: INTEGER
		do
			create l_state.default_create
			from
				i := 1
			until
				i > {TEXT_AREA_STATE}.Max_undo + 5
			loop
				l_state.insert_string ("x")
				i := i + 1
			end
			assert ("undo bounded", l_state.undo_count = {TEXT_AREA_STATE}.Max_undo)
			from
			until
				not l_state.can_undo
			loop
				l_state.undo
			end
			assert ("all kept for redo", l_state.redo_count = {TEXT_AREA_STATE}.Max_undo
				and l_state.value.count = 5)
			from
			until
				not l_state.can_redo
			loop
				l_state.redo
			end
			assert ("last text back", l_state.value.count = {TEXT_AREA_STATE}.Max_undo + 5
				and l_state.undo_count = {TEXT_AREA_STATE}.Max_undo)
		end

	test_backspace_run_is_one_undo_step
			-- L5: Backspaces one after another form one undo step, and so do Deletes; a move,
			-- typing or the other kind of deletion starts a new step.
		local
			l_state: TEXT_AREA_STATE
			i: INTEGER
		do
			create l_state.make_with_text ("hello world")
			from i := 1 until i > 6 loop
				l_state.delete_backward
				i := i + 1
			end
			assert ("deleted", l_state.value.same_string ("hello"))
			assert ("one step", l_state.undo_count = 1)
			l_state.undo
			assert ("restored", l_state.value.same_string ("hello world") and l_state.cursor_position = 11)
			assert ("nothing more", not l_state.can_undo)
				-- Deletes at the cursor
			l_state.set_cursor_position (0)
			from i := 1 until i > 6 loop
				l_state.delete_forward
				i := i + 1
			end
			assert ("forward deleted", l_state.value.same_string ("world") and l_state.undo_count = 1)
			l_state.undo
			assert ("forward restored", l_state.value.same_string ("hello world") and l_state.cursor_position = 0)
				-- Backspace then Delete: two steps
			l_state.set_cursor_position (5)
			l_state.delete_backward
			l_state.delete_backward
			l_state.delete_forward
			assert ("hel world", l_state.value.same_string ("helworld") and l_state.undo_count = 2)
			l_state.undo
			assert ("delete undone alone", l_state.value.same_string ("hel world"))
			l_state.undo
			assert ("backspaces undone", l_state.value.same_string ("hello world") and not l_state.can_undo)
				-- A move between Backspaces splits the run
			l_state.move_cursor_end (False)
			l_state.delete_backward
			l_state.move_cursor_left (False)
			l_state.delete_backward
			assert ("two runs", l_state.value.same_string ("hello wol") and l_state.undo_count = 2)
			l_state.undo
			assert ("second run undone", l_state.value.same_string ("hello worl"))
				-- Typing then Backspace: two steps
			l_state.undo
			l_state.move_cursor_end (False)
			type_text (l_state, "xy")
			l_state.delete_backward
			assert ("typed and erased", l_state.value.same_string ("hello worldx") and l_state.undo_count = 2)
			l_state.undo
			assert ("backspace undone", l_state.value.same_string ("hello worldxy"))
			l_state.undo
			assert ("typing undone", l_state.value.same_string ("hello world") and not l_state.can_undo)
		end

	test_newline_ends_typing_step
			-- L5: a newline is its own undo step and ends the typed run before it.
		local
			l_state: TEXT_AREA_STATE
		do
			create l_state.default_create
			type_text (l_state, "ab")
			l_state.insert_character ('%N')
			assert ("group closed", not l_state.is_undo_group_open)
			type_text (l_state, "cd")
			assert ("three steps", l_state.undo_count = 3)
			l_state.undo
			assert ("cd undone", l_state.value.same_string ("ab%N") and l_state.cursor_position = 3)
			l_state.undo
			assert ("newline undone", l_state.value.same_string ("ab") and l_state.cursor_position = 2)
			l_state.undo
			assert ("ab undone", l_state.value.is_empty and not l_state.can_undo)
				-- CR typed as a character is a newline too
			type_text (l_state, "x")
			l_state.insert_character ('%R')
			type_text (l_state, "y")
			assert ("CR splits", l_state.value.same_string ("x%Ny") and l_state.undo_count = 3)
		end

	test_undo_restores_cursor_and_anchor
			-- L5 / H3: undo puts back the text, the cursor and the selection anchor of the
			-- moment before the step, and never leaves a stale anchor.
		local
			l_state: TEXT_AREA_STATE
		do
				-- Typing over a selection: undo brings the selection back
			create l_state.make_with_text ("abcd")
			l_state.set_selection_anchor (1)
			l_state.set_cursor_position (3)
			type_text (l_state, "XY")
			assert ("replaced", l_state.value.same_string ("aXYd") and not l_state.has_selection)
			assert ("one step", l_state.undo_count = 1)
			l_state.undo
			assert ("text back", l_state.value.same_string ("abcd"))
			assert ("cursor back", l_state.cursor_position = 3)
			assert ("selection back", l_state.has_selection and l_state.selection_start = 1 and l_state.selection_end = 3)
				-- Backspace over a selection made with Shift+Left
			l_state.clear_selection
			l_state.move_cursor_end (False)
			l_state.move_cursor_left (True)
			l_state.move_cursor_left (True)
			l_state.delete_backward
			assert ("cut", l_state.value.same_string ("ab") and l_state.selection_anchor = -1)
			l_state.undo
			assert ("selection restored", l_state.value.same_string ("abcd") and l_state.cursor_position = 2
				and l_state.selection_anchor = 4)
				-- A typed run without a selection: the anchor stays cleared
			l_state.clear_selection
			l_state.move_cursor_end (False)
			type_text (l_state, "ef")
			l_state.undo
			assert ("cursor at run start", l_state.value.same_string ("abcd") and l_state.cursor_position = 4)
			assert ("no anchor", l_state.selection_anchor = -1 and not l_state.has_selection)
				-- P1 case: an anchor left on the cursor is not brought back as a selection
			l_state.move_cursor_left (True)
			l_state.move_cursor_right (True)
			l_state.delete_backward
			l_state.undo
			assert ("no phantom selection", l_state.value.same_string ("abcd") and l_state.selection_anchor = -1)
				-- Undo ends the open step
			type_text (l_state, "g")
			assert ("open", l_state.is_undo_group_open)
			l_state.undo
			assert ("closed by undo", not l_state.is_undo_group_open)
		end

	test_undo_depth_is_bounded
			-- L5: at most `Max_undo` steps are kept; the oldest go first.
		local
			l_state: TEXT_AREA_STATE
			i, l_max: INTEGER
		do
			create l_state.default_create
			l_max := l_state.Max_undo
			from i := 1 until i > l_max + 10 loop
				l_state.move_cursor_end (False)
				l_state.insert_character ('a')
				i := i + 1
			end
			assert ("one step per insert, capped", l_state.undo_count = l_max)
			from i := 1 until not l_state.can_undo loop
				l_state.undo
				i := i + 1
			end
			assert ("max steps undone", i - 1 = l_max)
			assert ("oldest steps dropped", l_state.value.count = 10)
				-- A long typed run is one step and adds no snapshot per key
			create l_state.default_create
			from i := 1 until i > 200 loop
				l_state.insert_character ('z')
				i := i + 1
			end
			assert ("one step for 200 keys", l_state.undo_count = 1)
			l_state.undo
			assert ("all undone", l_state.value.is_empty)
		end

	test_focus_tab_into_area
			-- TEXT_AREA id participates in FOCUS_MANAGER Tab order.
		local
			l_focus: FOCUS_MANAGER
			l_input, l_area: WIDGET_ID
		do
			create l_focus.make
			create l_input.make (1)
			create l_area.make (2)
			l_focus.register (l_input)
			l_focus.register (l_area)
			assert ("starts input", l_focus.is_focused (l_input))
			l_focus.focus_next
			assert ("tab to area", l_focus.is_focused (l_area))
			l_focus.focus_next
			assert ("wrap input", l_focus.is_focused (l_input))
		end

feature {NONE} -- Helpers

	type_text (a_state: TEXT_AREA_STATE; a_text: STRING)
			-- Type `a_text` one character at a time.
		do
			across
				a_text as c
			loop
				a_state.insert_character (c)
			end
		end

	rendered (a_widget: TUI_TEXT_AREA; a_state: TEXT_AREA_STATE; a_width, a_height: INTEGER): BUFFER
			-- A new `a_width` x `a_height` buffer with `a_state` rendered by `a_widget` over all
			-- of it (a fresh buffer each time, as a terminal frame is).
		do
			create Result.make (a_width, a_height)
			a_widget.render_stateful (Result.area, Result, a_state)
		end

	assert_cursor (a_tag: STRING; a_widget: TUI_TEXT_AREA; a_area: RECT; a_buffer: BUFFER; a_state: TEXT_AREA_STATE; a_col, a_row: INTEGER)
			-- Check that the cursor of `a_state` rendered in `a_area` is on screen cell
			-- (`a_col`, `a_row`), both as the hardware position and as the reversed cell painted
			-- in `a_buffer`.
		do
			if attached a_widget.cursor_screen_position (a_area, a_state) as c then
				assert (a_tag + ": cursor at (" + a_col.out + ", " + a_row.out + ") got (" + c.col.out + ", " + c.row.out + ")",
					c.col = a_col and c.row = a_row)
			else
				assert (a_tag + ": cursor shown", False)
			end
			assert (a_tag + ": cursor cell reversed", a_buffer.cell (a_row, a_col).style.is_reversed)
		end

	top_border (a_inner: INTEGER): STRING_32
			-- Top row of a plain box with `a_inner` columns inside.
		do
			Result := {STRING_32} "%/0x250C/" + create {STRING_32}.make_filled ('%/0x2500/', a_inner) + {STRING_32} "%/0x2510/"
		end

	bottom_border (a_inner: INTEGER): STRING_32
			-- Bottom row of a plain box with `a_inner` columns inside.
		do
			Result := {STRING_32} "%/0x2514/" + create {STRING_32}.make_filled ('%/0x2500/', a_inner) + {STRING_32} "%/0x2518/"
		end

	boxed (a_inner: STRING_32): STRING_32
			-- `a_inner` between the side borders of a plain box.
		do
			Result := {STRING_32} "%/0x2502/" + a_inner + {STRING_32} "%/0x2502/"
		end

	selection_map (a_buffer: BUFFER; a_row, a_width: INTEGER): STRING
			-- 'S' for each cell of `a_row` with the default selection background, '.' otherwise.
		local
			c: INTEGER
		do
			create Result.make (a_width)
			from c := 0 until c >= a_width loop
				if a_buffer.cell (a_row, c).style.background ~ {COLOR}.Bright_blue then
					Result.append_character ('S')
				else
					Result.append_character ('.')
				end
				c := c + 1
			end
		end

	assert_rows (a_tag: STRING; a_buffer: BUFFER; a_rows: ARRAY [STRING_32])
			-- Check that the first rows of `a_buffer` are exactly `a_rows`.
		local
			i: INTEGER
		do
			from
				i := a_rows.lower
			until
				i > a_rows.upper
			loop
				assert (a_tag + ": row " + (i - a_rows.lower).out + " is [" + a_rows [i].out + "] got ["
					+ a_buffer.line (i - a_rows.lower).out + "]", a_buffer.line (i - a_rows.lower).same_string (a_rows [i]))
				i := i + 1
			end
		end

end
