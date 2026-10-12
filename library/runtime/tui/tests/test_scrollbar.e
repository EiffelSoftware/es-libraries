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
	EQA_TEST_SET

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

feature {NONE} -- Helpers

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
