note
	description: "[
		Autotest test set for Phase 8: SCROLLBAR_ORIENTATION, SCROLLBAR_STATE, and TUI_SCROLLBAR.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_SCROLLBAR

inherit
	BUFFER_TEST_HELPER

feature -- Test routines

	test_scrollbar_orientation_constants
			-- Test orientation predicates and validation.
		do
			assert ("vr is vertical", {SCROLLBAR_ORIENTATION}.is_vertical ({SCROLLBAR_ORIENTATION}.vertical_right))
			assert ("vl is vertical", {SCROLLBAR_ORIENTATION}.is_vertical ({SCROLLBAR_ORIENTATION}.vertical_left))
			assert ("hb is horizontal", {SCROLLBAR_ORIENTATION}.is_horizontal ({SCROLLBAR_ORIENTATION}.horizontal_bottom))
			assert ("ht is horizontal", {SCROLLBAR_ORIENTATION}.is_horizontal ({SCROLLBAR_ORIENTATION}.horizontal_top))

			assert ("vr valid", {SCROLLBAR_ORIENTATION}.is_valid ({SCROLLBAR_ORIENTATION}.vertical_right))
			assert ("vl valid", {SCROLLBAR_ORIENTATION}.is_valid ({SCROLLBAR_ORIENTATION}.vertical_left))
			assert ("hb valid", {SCROLLBAR_ORIENTATION}.is_valid ({SCROLLBAR_ORIENTATION}.horizontal_bottom))
			assert ("ht valid", {SCROLLBAR_ORIENTATION}.is_valid ({SCROLLBAR_ORIENTATION}.horizontal_top))
			assert ("0 invalid", not {SCROLLBAR_ORIENTATION}.is_valid (0))
		end

	test_scrollbar_state_navigation
			-- Test scrollbar state movement and clamping.
		local
			l_st: SCROLLBAR_STATE
		do
			create l_st.make (10)
			assert ("content length 10", l_st.content_length = 10)
			assert ("initial pos 0", l_st.position = 0)

			l_st.next
			assert ("next pos 1", l_st.position = 1)
			l_st.next
			assert ("next pos 2", l_st.position = 2)

			l_st.prev
			assert ("prev pos 1", l_st.position = 1)

			l_st.last
			assert ("last pos 9", l_st.position = 9)
			l_st.next
			assert ("clamped at 9", l_st.position = 9)

			l_st.first
			assert ("first pos 0", l_st.position = 0)
			l_st.prev
			assert ("clamped at 0", l_st.position = 0)

			l_st.set_position (5)
			assert ("set pos 5", l_st.position = 5)
			l_st.set_viewport_content_length (3)
			assert ("viewport 3", l_st.viewport_content_length = 3)
		end

	test_tui_scrollbar_vertical_rendering
			-- Test vertical scrollbar with begin/end arrows, track, and thumb.
		local
			l_sb: TUI_SCROLLBAR
			l_st: SCROLLBAR_STATE
			l_buf: BUFFER
			l_area: RECT
			l_up, l_down: STRING_32
		do
			create l_up.make (1)
			l_up.append_character ((9650).to_character_32)
			create l_down.make (1)
			l_down.append_character ((9660).to_character_32)

			create l_sb.make ({SCROLLBAR_ORIENTATION}.vertical_right)
			l_sb.set_begin_symbol (l_up)
			l_sb.set_end_symbol (l_down)

			create l_st.make (50)
			l_st.set_position (0)

			create l_buf.make (10, 10)
			create l_area.make (0, 0, 10, 10)

			l_sb.render_scrollbar (l_area, l_buf, l_st)

			-- Column 9:
			-- Row 0: begin arrow "▲" (code 9650)
			assert ("top arrow", l_buf.cell (0, 9).symbol.code (1) = 9650)
			-- Row 1: thumb at start "█" (code 9608)
			assert ("thumb at top", l_buf.cell (1, 9).symbol.code (1) = 9608)
			-- Row 8: track near bottom "│" (code 9474)
			assert ("track near bottom", l_buf.cell (8, 9).symbol.code (1) = 9474)
			-- Row 9: end arrow "▼" (code 9660)
			assert ("bottom arrow", l_buf.cell (9, 9).symbol.code (1) = 9660)

			-- Shift position to bottom (49)
			l_st.set_position (49)
			l_buf.clear
			l_sb.render_scrollbar (l_area, l_buf, l_st)

			-- Row 0: begin arrow
			assert ("top arrow after scroll", l_buf.cell (0, 9).symbol.code (1) = 9650)
			-- Row 1: track at top
			assert ("track at top after scroll", l_buf.cell (1, 9).symbol.code (1) = 9474)
			-- Row 8: thumb shifted to bottom
			assert ("thumb at bottom after scroll", l_buf.cell (8, 9).symbol.code (1) = 9608)
			-- Row 9: end arrow
			assert ("bottom arrow after scroll", l_buf.cell (9, 9).symbol.code (1) = 9660)
		end

	test_tui_scrollbar_horizontal_rendering
			-- Test horizontal bottom scrollbar rendering.
		local
			l_sb: TUI_SCROLLBAR
			l_st: SCROLLBAR_STATE
			l_buf: BUFFER
			l_area: RECT
			l_left, l_right: STRING_32
		do
			create l_left.make (1)
			l_left.append_character ((9668).to_character_32)
			create l_right.make (1)
			l_right.append_character ((9658).to_character_32)

			create l_sb.make ({SCROLLBAR_ORIENTATION}.horizontal_bottom)
			l_sb.set_begin_symbol (l_left)
			l_sb.set_end_symbol (l_right)

			create l_st.make (10)
			l_st.set_position (0)

			create l_buf.make (10, 5)
			create l_area.make (0, 0, 10, 5)

			l_sb.render_scrollbar (l_area, l_buf, l_st)

			-- Bottom row is row 4:
			-- Col 0: left arrow "◄" (code 9668)
			assert ("left arrow", l_buf.cell (4, 0).symbol.code (1) = 9668)
			-- Col 1: thumb "█" (code 9608)
			assert ("thumb at left", l_buf.cell (4, 1).symbol.code (1) = 9608)
			-- Col 9: right arrow "►" (code 9658)
			assert ("right arrow", l_buf.cell (4, 9).symbol.code (1) = 9658)
		end

	test_tui_scrollbar_pairing_with_list
			-- Test rendering a list and scrollbar together.
		local
			l_list: TUI_LIST
			l_sb: TUI_SCROLLBAR
			l_list_state: LIST_STATE
			l_sb_state: SCROLLBAR_STATE
			l_buf: BUFFER
			l_area: RECT
		do
			create l_list.make_empty
			l_list.append_raw_item ("Item A")
			l_list.append_raw_item ("Item B")
			l_list.append_raw_item ("Item C")

			create l_list_state.make
			l_list_state.select_index (1)

			create l_sb.make ({SCROLLBAR_ORIENTATION}.vertical_right)
			create l_sb_state.make (l_list.count)
			l_sb_state.set_position (0)

			create l_buf.make (15, 3)
			create l_area.make (0, 0, 15, 3)

			l_list.render_list (l_area, l_buf, l_list_state)
			l_sb.render_scrollbar (l_area, l_buf, l_sb_state)

			-- List item rendered on left
			assert ("list item I", l_buf.cell (0, 0).symbol.same_string_general ("I"))
			-- Scrollbar rendered on right edge (col 14)
			assert ("scrollbar thumb at col 14", l_buf.cell (0, 14).symbol.code (1) = 9608)
		end


feature -- One-column symbols (review finding U6)

	test_scrollbar_valid_symbols
			-- A symbol is one grapheme cluster, one column wide (or empty).
		do
			assert ("arrow", {TUI_SCROLLBAR}.is_valid_symbol ({STRING_32} "%/0x25B2/"))
			assert ("letter with a combining mark", {TUI_SCROLLBAR}.is_valid_symbol ({STRING_32} "e%/0x301/"))
			assert ("empty", {TUI_SCROLLBAR}.is_valid_symbol (""))
			assert ("wide emoji refused", not {TUI_SCROLLBAR}.is_valid_symbol ({STRING_32} "%/0x1F53C/"))
			assert ("wide CJK refused", not {TUI_SCROLLBAR}.is_valid_symbol ({STRING_32} "%/0x65E5/"))
			assert ("two characters refused", not {TUI_SCROLLBAR}.is_valid_symbol ("=>"))
			assert ("character and tab refused", not {TUI_SCROLLBAR}.is_valid_symbol ("a%T"))
			assert ("zero width refused", not {TUI_SCROLLBAR}.is_valid_symbol ({STRING_32} "%/0x301/"))
		end

	test_scrollbar_setters_refuse_wide_symbols
			-- Every symbol setter and builder refuses a symbol wider than one column.
		local
			l_sb: TUI_SCROLLBAR
		do
			create l_sb.make ({SCROLLBAR_ORIENTATION}.vertical_right)
			assert ("begin", precondition_raised (agent l_sb.set_begin_symbol ({STRING_32} "%/0x1F53C/")))
			assert ("end", precondition_raised (agent l_sb.set_end_symbol ({STRING_32} "%/0x1F53D/")))
			assert ("track", precondition_raised (agent l_sb.set_track_symbol ("==")))
			assert ("thumb", precondition_raised (agent l_sb.set_thumb_symbol ({STRING_32} "%/0x2588/%/0x2588/")))
			assert ("with_thumb", precondition_raised (agent (b: TUI_SCROLLBAR) do b.with_thumb_symbol ("##").do_nothing end (l_sb)))
			assert ("with_begin", precondition_raised (agent (b: TUI_SCROLLBAR) do b.with_begin_symbol ({STRING_32} "%/0x65E5/").do_nothing end (l_sb)))
			assert ("symbols unchanged", l_sb.begin_symbol = Void and l_sb.thumb_symbol.same_string ({STRING_32} "%/0x2588/"))
			l_sb.set_begin_symbol (Void)
			l_sb.set_track_symbol ("")
			assert ("Void and empty accepted", l_sb.begin_symbol = Void and attached l_sb.track_symbol as t and then t.is_empty)
		end

	test_scrollbar_invariant_catches_edited_symbol
			-- The symbol strings are public: widening one in place breaks the class invariant,
			-- which is caught on the next call.
		local
			l_sb: TUI_SCROLLBAR
			l_raised, l_retried: BOOLEAN
		do
			if not l_retried then
				create l_sb.make ({SCROLLBAR_ORIENTATION}.vertical_right)
				l_sb.thumb_symbol.append ({STRING_32} "%/0x2588/")
				l_sb.render (create {RECT}.make (0, 0, 3, 3), create {BUFFER}.make (3, 3))
			end
			assert ("invariant violated", l_raised)
		rescue
			if not l_retried then
				l_retried := True
				l_raised := attached (create {EXCEPTION_MANAGER}).last_exception as e and then
					(attached {INVARIANT_VIOLATION} e.original as v and then
					(attached v.description as d and then d.same_string ("one_column_thumb")))
				retry
			end
		end

	test_scrollbar_stays_in_its_column
			-- A vertical bar with multi-code-point symbols writes only its own column: the
			-- cells of the widget next to it are left alone.
		local
			l_sb: TUI_SCROLLBAR
			l_buf: BUFFER
			l_st: SCROLLBAR_STATE
			r: INTEGER
		do
			create l_sb.make ({SCROLLBAR_ORIENTATION}.vertical_right)
			l_sb.set_begin_symbol ({STRING_32} "^%/0x301/")
			l_sb.set_track_symbol ({STRING_32} "|%/0x300/")
			create l_buf.make (4, 5)
			from r := 0 until r >= 5 loop
				l_buf.put_string (r, 0, "abc", create {STYLE})
				r := r + 1
			end
			create l_st.make (20)
			l_sb.render_scrollbar (create {RECT}.make (3, 0, 1, 5), l_buf, l_st)
			assert ("begin symbol in one cell", l_buf.cell (0, 3).symbol.same_string ({STRING_32} "^%/0x301/"))
			assert ("track in one cell", l_buf.cell (4, 3).symbol.same_string ({STRING_32} "|%/0x300/"))
			from r := 0 until r >= 5 loop
				assert ("neighbour kept on row " + r.out, l_buf.cell (r, 2).symbol.same_string ("c"))
				r := r + 1
			end
		end

	test_horizontal_scrollbar_symbols_do_not_blank_each_other
			-- In a horizontal bar every cell keeps its own symbol.
		local
			l_sb: TUI_SCROLLBAR
			l_buf: BUFFER
			l_st: SCROLLBAR_STATE
			c: INTEGER
		do
			create l_sb.make ({SCROLLBAR_ORIENTATION}.horizontal_bottom)
			l_sb.set_begin_symbol ({STRING_32} "%/0x25C4/")
			l_sb.set_end_symbol ({STRING_32} "%/0x25BA/")
			create l_buf.make (8, 1)
			create l_st.make (100)
			l_sb.render_scrollbar (create {RECT}.make (0, 0, 8, 1), l_buf, l_st)
			assert ("begin", l_buf.cell (0, 0).symbol.same_string ({STRING_32} "%/0x25C4/"))
			assert ("end", l_buf.cell (0, 7).symbol.same_string ({STRING_32} "%/0x25BA/"))
			from c := 0 until c >= 8 loop
				assert ("cell " + c.out + " drawn", not l_buf.cell (0, c).symbol.same_string (" ") and l_buf.cell (0, c).width = 1)
				c := c + 1
			end
		end

feature -- Thumb in the track (X1: Ratatui 0.30.2 #2594, 0.30.1 #2352)

	test_large_thumb_stays_in_track_at_end
			-- X1a (#2594): content 12, viewport 10, position at the end. The thumb's last cell
			-- is the track's last cell, not past it, in every orientation, with and without
			-- arrows (an arrow is never overwritten).
		do
			across all_orientations as o loop
				assert_bar ("no arrows, end", o, False, 12, 10, 11, {STRING_32} "-----#####")
				assert_bar ("no arrows, start", o, False, 12, 10, 0, {STRING_32} "#####-----")
				assert_bar ("arrows, end", o, True, 12, 10, 11, {STRING_32} "<-----#####>")
				assert_bar ("arrows, past the end", o, True, 12, 10, 50, {STRING_32} "<-----#####>")
			end
		end

	test_render_scrollbar_keeps_end_symbol_for_large_thumb
			-- Ratatui `render_scrollbar_keeps_end_symbol_for_large_thumb` (#2594, issue #2582):
			-- content 9 in a bar of 24 (track 22, viewport 24): the thumb is 17 cells, and at the
			-- end it starts at 5, so the end symbol stays. Ratatui renders `HorizontalTop`;
			-- here every orientation.
		do
			across all_orientations as o loop
				assert_bar ("large thumb at end", o, True, 9, 0, 8, {STRING_32} "<-----#################>")
				assert_bar ("large thumb at start", o, True, 9, 0, 0, {STRING_32} "<#################----->")
			end
		end

	test_thumb_stays_within_track_for_large_thumb_at_end
			-- Ratatui `thumb_stays_within_track_for_large_thumb_at_end` (#2594, issue #2582):
			-- a vertical right bar of height 24 with the arrow heads (track 22), content 9 at
			-- position 8. Ratatui checks `part_lengths`; here the rendered column, with the
			-- default symbols: arrow, 5 track cells, 17 thumb cells, arrow.
		local
			l_sb: TUI_SCROLLBAR
			l_st: SCROLLBAR_STATE
			l_buf: BUFFER
			l_expected: ARRAY [READABLE_STRING_GENERAL]
			i: INTEGER
		do
			create l_sb.make ({SCROLLBAR_ORIENTATION}.vertical_right)
			l_sb.set_begin_symbol ({STRING_32} "%/0x25B2/")
			l_sb.set_end_symbol ({STRING_32} "%/0x25BC/")
			create l_st.make (9)
			l_st.set_position (8)
			create l_buf.make (1, 24)
			l_sb.render_scrollbar (create {RECT}.make (0, 0, 1, 24), l_buf, l_st)
			create l_expected.make_filled ({STRING_32} "%/0x2588/", 1, 24)
			l_expected [1] := {STRING_32} "%/0x25B2/"
			from i := 2 until i > 6 loop
				l_expected [i] := {STRING_32} "%/0x2502/"
				i := i + 1
			end
			l_expected [24] := {STRING_32} "%/0x25BC/"
			assert_buffer_lines ("thumb within the track", l_buf, l_expected)
		end

	test_render_scrollbar_simple
			-- Ratatui `render_scrollbar_simple` (no arrows, content 10 in a bar of 10): the
			-- thumb is 5 cells at every position.
		do
			across all_orientations as o loop
				assert_bar ("position 0", o, False, 10, 0, 0, {STRING_32} "#####-----")
				assert_bar ("position 1", o, False, 10, 0, 1, {STRING_32} "-#####----")
				assert_bar ("position 2", o, False, 10, 0, 2, {STRING_32} "-#####----")
				assert_bar ("position 3", o, False, 10, 0, 3, {STRING_32} "--#####---")
				assert_bar ("position 4", o, False, 10, 0, 4, {STRING_32} "--#####---")
				assert_bar ("position 5", o, False, 10, 0, 5, {STRING_32} "---#####--")
				assert_bar ("position 6", o, False, 10, 0, 6, {STRING_32} "---#####--")
				assert_bar ("position 7", o, False, 10, 0, 7, {STRING_32} "----#####-")
				assert_bar ("position 8", o, False, 10, 0, 8, {STRING_32} "----#####-")
				assert_bar ("position 9", o, False, 10, 0, 9, {STRING_32} "-----#####")
			end
		end

	test_render_scrollbar_with_symbols
			-- Ratatui `render_scrollbar_with_symbols` (`HorizontalTop`),
			-- `render_scrollbar_vertical_left` and `render_scrollbar_vertical_right`, as
			-- changed by #2352: the thumb is 4 cells at every position (positions 1 and 8 drew
			-- 5 cells before #2352). Here every orientation, `HorizontalBottom` included.
		do
			across all_orientations as o loop
				assert_bar ("position 0", o, True, 10, 0, 0, {STRING_32} "<####---->")
				assert_bar ("position 1", o, True, 10, 0, 1, {STRING_32} "<####---->")
				assert_bar ("position 2", o, True, 10, 0, 2, {STRING_32} "<-####--->")
				assert_bar ("position 3", o, True, 10, 0, 3, {STRING_32} "<-####--->")
				assert_bar ("position 4", o, True, 10, 0, 4, {STRING_32} "<--####-->")
				assert_bar ("position 5", o, True, 10, 0, 5, {STRING_32} "<--####-->")
				assert_bar ("position 6", o, True, 10, 0, 6, {STRING_32} "<---####->")
				assert_bar ("position 7", o, True, 10, 0, 7, {STRING_32} "<---####->")
				assert_bar ("position 8", o, True, 10, 0, 8, {STRING_32} "<---####->")
				assert_bar ("position 9", o, True, 10, 0, 9, {STRING_32} "<----####>")
				assert_bar ("one out of bounds", o, True, 10, 0, 10, {STRING_32} "<----####>")
				assert_bar ("few out of bounds", o, True, 10, 0, 15, {STRING_32} "<----####>")
				assert_bar ("very many out of bounds", o, True, 10, 0, 500, {STRING_32} "<----####>")
			end
		end

	test_custom_viewport_length
			-- Ratatui `custom_viewport_length` (no arrows, content 10, viewport 2), as changed
			-- by #2352: the thumb is 2 cells at every position (positions 4 and 5 drew 1 cell
			-- before #2352).
		local
			o: NATURAL_8
		do
			o := {SCROLLBAR_ORIENTATION}.horizontal_top
			assert_bar ("position 0", o, False, 10, 2, 0, {STRING_32} "##--------")
			assert_bar ("position 1", o, False, 10, 2, 1, {STRING_32} "-##-------")
			assert_bar ("position 2", o, False, 10, 2, 2, {STRING_32} "--##------")
			assert_bar ("position 3", o, False, 10, 2, 3, {STRING_32} "---##-----")
			assert_bar ("position 4", o, False, 10, 2, 4, {STRING_32} "----##----")
			assert_bar ("position 5", o, False, 10, 2, 5, {STRING_32} "-----##---")
			assert_bar ("position 6", o, False, 10, 2, 6, {STRING_32} "-----##---")
			assert_bar ("position 7", o, False, 10, 2, 7, {STRING_32} "------##--")
			assert_bar ("position 8", o, False, 10, 2, 8, {STRING_32} "-------##-")
			assert_bar ("position 9", o, False, 10, 2, 9, {STRING_32} "--------##")
			assert_bar ("one out of bounds", o, False, 10, 2, 10, {STRING_32} "--------##")
		end

	test_thumb_visible_on_very_small_track
			-- Ratatui `thumb_visible_on_very_small_track` (no arrows, content 100, viewport 2,
			-- a bar of 5): the thumb is one cell, never zero.
		local
			o: NATURAL_8
		do
			o := {SCROLLBAR_ORIENTATION}.horizontal_top
			assert_bar ("position 0", o, False, 100, 2, 0, {STRING_32} "#----")
			assert_bar ("position 10", o, False, 100, 2, 10, {STRING_32} "#----")
			assert_bar ("position 20", o, False, 100, 2, 20, {STRING_32} "-#---")
			assert_bar ("position 30", o, False, 100, 2, 30, {STRING_32} "-#---")
			assert_bar ("position 40", o, False, 100, 2, 40, {STRING_32} "--#--")
			assert_bar ("position 50", o, False, 100, 2, 50, {STRING_32} "--#--")
			assert_bar ("position 60", o, False, 100, 2, 60, {STRING_32} "---#-")
			assert_bar ("position 70", o, False, 100, 2, 70, {STRING_32} "---#-")
			assert_bar ("position 80", o, False, 100, 2, 80, {STRING_32} "----#")
			assert_bar ("position 90", o, False, 100, 2, 90, {STRING_32} "----#")
			assert_bar ("one out of bounds", o, False, 100, 2, 100, {STRING_32} "----#")
		end

	test_thumb_length_constant_while_scrolling
			-- X1b (#2352): for each bar, every position from 0 to past the end draws the same
			-- number of thumb cells, in one run, inside the track (the arrows are kept). The
			-- cases are: bar length, arrows, content, viewport (0: the bar's length), and the
			-- expected thumb length, which includes large thumbs (content shorter than the
			-- viewport) and a full bar.
		local
			l_cases: ARRAY [TUPLE [length: INTEGER; arrows: BOOLEAN; content, viewport, thumb: INTEGER]]
			l_buf: BUFFER
			l_bar: STRING_32
			l_tag: STRING
			p, l_first, l_last: INTEGER
		do
			l_cases := <<
				[10, False, 12, 10, 5],
				[10, False, 10, 0, 5],
				[10, True, 10, 0, 4],
				[10, False, 10, 2, 2],
				[5, False, 100, 0, 1],
				[8, False, 20, 6, 2],
				[24, True, 9, 0, 17],
				[10, False, 3, 0, 8],
				[12, True, 2, 0, 9],
				[10, False, 1, 0, 10]
			>>
			across l_cases as c loop
				across all_orientations as o loop
					from p := 0 until p > c.content + 2 loop
						l_tag := "length " + c.length.out + ", content " + c.content.out + ", viewport " + c.viewport.out
							+ ", orientation " + o.out + ", position " + p.out
						l_buf := bar_buffer (o, c.arrows, c.length, c.content, c.viewport, p)
						l_bar := bar_text (l_buf, o)
						assert (l_tag + ": thumb length", l_bar.occurrences ('#') = c.thumb)
						l_first := l_bar.index_of ('#', 1)
						l_last := l_first + c.thumb - 1
						assert (l_tag + ": one run", l_bar.substring (l_first, l_last).occurrences ('#') = c.thumb)
						if c.arrows then
							assert (l_tag + ": arrows kept", l_bar [1] = '<' and l_bar [l_bar.count] = '>')
						end
						p := p + 1
					end
				end
			end
		end

	test_thumb_math_does_not_overflow_for_long_content
			-- Ratatui computes the thumb in `usize` with `saturating_mul`. Here a position times the
			-- track length beyond {INTEGER_32}.max_value must not wrap around: content 30 000 000 in
			-- a bar of 100 (position * 100 is above 2^31 from position 21 474 837), and content and
			-- viewport of {INTEGER}.max_value (their sum is above 2^31) in a bar of 10.
		local
			l_track: STRING_32
		do
			create l_track.make_filled ('-', 100)
			across all_orientations as o loop
				l_track [1] := '#'
				assert_bar ("30M at 0", o, False, 30_000_000, 0, 0, l_track)
				l_track [1] := '-'
				l_track [74] := '#'
					-- (22 000 000 * 100 + 15 000 049) // 30 000 099 = 73
				assert_bar ("30M at 22M", o, False, 30_000_000, 0, 22_000_000, l_track)
				l_track [74] := '-'
				l_track [100] := '#'
				assert_bar ("30M at the end", o, False, 30_000_000, 0, 29_999_999, l_track)
				l_track [100] := '-'
				assert_bar ("max at 0", o, False, {INTEGER}.max_value, {INTEGER}.max_value, 0, {STRING_32} "#####-----")
				assert_bar ("max at the end", o, False, {INTEGER}.max_value, {INTEGER}.max_value, {INTEGER}.max_value - 1, {STRING_32} "-----#####")
			end
		end

feature {NONE} -- Helpers

	all_orientations: ARRAY [NATURAL_8]
			-- The four orientations.
		do
			Result := <<{SCROLLBAR_ORIENTATION}.vertical_right, {SCROLLBAR_ORIENTATION}.vertical_left,
				{SCROLLBAR_ORIENTATION}.horizontal_top, {SCROLLBAR_ORIENTATION}.horizontal_bottom>>
		ensure
			four: Result.count = 4
		end

	bar_buffer (a_orientation: NATURAL_8; a_arrows: BOOLEAN; a_length, a_content, a_viewport, a_position: INTEGER): BUFFER
			-- A buffer holding a bar of `a_length` cells along its `a_orientation` edge, with
			-- the symbols of Ratatui's tests (track "-", thumb "#", and "<" ">" when `a_arrows`),
			-- for content `a_content`, viewport `a_viewport` (0: the bar's length) and
			-- `a_position`. A vertical bar's buffer is 5 columns wide (as in Ratatui's
			-- vertical tests), a horizontal bar's 2 rows high, so the opposite edge shows too.
		require
			valid_orientation: {SCROLLBAR_ORIENTATION}.is_valid (a_orientation)
			positive_length: a_length > 0
			non_negative: a_content >= 0 and a_viewport >= 0 and a_position >= 0
		local
			l_sb: TUI_SCROLLBAR
			l_st: SCROLLBAR_STATE
			l_w, l_h: INTEGER
		do
			create l_sb.make (a_orientation)
			l_sb.set_track_symbol ("-")
			l_sb.set_thumb_symbol ("#")
			if a_arrows then
				l_sb.set_begin_symbol ("<")
				l_sb.set_end_symbol (">")
			end
			create l_st.make (a_content)
			l_st.set_viewport_content_length (a_viewport)
			l_st.set_position (a_position)
			if {SCROLLBAR_ORIENTATION}.is_vertical (a_orientation) then
				l_w := 5
				l_h := a_length
			else
				l_w := a_length
				l_h := 2
			end
			create Result.make (l_w, l_h)
			l_sb.render_scrollbar (create {RECT}.make (0, 0, l_w.to_natural_16, l_h.to_natural_16), Result, l_st)
		end

	bar_text (a_buf: BUFFER; a_orientation: NATURAL_8): STRING_32
			-- The cells of the bar in `a_buf` (rendered by `bar_buffer`), first to last.
		require
			valid_orientation: {SCROLLBAR_ORIENTATION}.is_valid (a_orientation)
		local
			i: INTEGER
		do
			inspect a_orientation
			when {SCROLLBAR_ORIENTATION}.vertical_right, {SCROLLBAR_ORIENTATION}.vertical_left then
				create Result.make (a_buf.height)
				from i := 0 until i >= a_buf.height loop
					if a_orientation = {SCROLLBAR_ORIENTATION}.vertical_right then
						Result.append (a_buf.cell (i, a_buf.width - 1).symbol)
					else
						Result.append (a_buf.cell (i, 0).symbol)
					end
					i := i + 1
				end
			when {SCROLLBAR_ORIENTATION}.horizontal_top then
				Result := buffer_row_as_string (a_buf, 0)
			else
				Result := buffer_row_as_string (a_buf, a_buf.height - 1)
			end
		end

	assert_bar (a_tag: STRING; a_orientation: NATURAL_8; a_arrows: BOOLEAN; a_content, a_viewport, a_position: INTEGER; a_expected: STRING_32)
			-- Check every row of `bar_buffer` for a bar of `a_expected.count` cells: the bar
			-- reads `a_expected` along its edge, and every other cell is blank.
		require
			valid_orientation: {SCROLLBAR_ORIENTATION}.is_valid (a_orientation)
			not_empty: not a_expected.is_empty
		local
			l_lines: ARRAY [READABLE_STRING_GENERAL]
			l_blank, l_row: STRING_32
			i: INTEGER
		do
			if {SCROLLBAR_ORIENTATION}.is_vertical (a_orientation) then
				create l_lines.make_filled ({STRING_32} "", 1, a_expected.count)
				from i := 1 until i > a_expected.count loop
					create l_row.make_filled (' ', 5)
					if a_orientation = {SCROLLBAR_ORIENTATION}.vertical_right then
						l_row [5] := a_expected [i]
					else
						l_row [1] := a_expected [i]
					end
					l_lines [i] := l_row
					i := i + 1
				end
			else
				create l_blank.make_filled (' ', a_expected.count)
				if a_orientation = {SCROLLBAR_ORIENTATION}.horizontal_top then
					l_lines := <<a_expected, l_blank>>
				else
					l_lines := <<l_blank, a_expected>>
				end
			end
			assert_buffer_lines (a_tag + " (orientation " + a_orientation.out + ")",
				bar_buffer (a_orientation, a_arrows, a_expected.count, a_content, a_viewport, a_position), l_lines)
		end

	precondition_raised (a_action: PROCEDURE): BOOLEAN
			-- Does `a_action` raise a precondition violation tagged "one_column"?
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
					(attached v.description as d and then d.same_string ("one_column")))
				retry
			end
		end

end
