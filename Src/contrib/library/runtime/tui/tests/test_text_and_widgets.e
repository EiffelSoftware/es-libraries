note
	description: "[
		Test set for Phase 5 Text pipeline (spans, lines, wrapping, alignment)
		and immediate-mode widgets (TUI_BLOCK, TUI_PARAGRAPH, TUI_CLEAR).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_TEXT_AND_WIDGETS

inherit
	EQA_TEST_SET

feature -- Test routines

	test_text_span_and_unicode_width
			-- Test TEXT_SPAN width calculation for ASCII and wide Unicode characters.
		local
			l_s1, l_s2, l_sub: TEXT_SPAN
			l_style: STYLE
			l_cjk: STRING_32
		do
			create l_s1.make_raw ("Hello")
			assert ("s1 width 5", l_s1.width = 5)
			assert ("s1 count 5", l_s1.count = 5)

			-- "Hello 中文" has 6 ASCII chars + 2 CJK characters (width 2 each) = 10 cols
			create l_style.make_fg ({COLOR}.cyan)
			create l_cjk.make (8)
			l_cjk.append_string_general ("Hello ")
			l_cjk.append_character ((20013).to_character_32)
			l_cjk.append_character ((25991).to_character_32)
			create l_s2.make (l_cjk, l_style)
			assert ("s2 count 8", l_s2.count = 8)
			assert ("s2 width 10", l_s2.width = 10)
			assert ("s2 style fg cyan", l_s2.style.foreground.is_ansi and l_s2.style.foreground.ansi_code = 6)

			-- Sub-span
			l_sub := l_s2.sub_span (1, 5)
			assert ("sub content Hello", l_sub.content.same_string_general ("Hello"))
			assert ("sub width 5", l_sub.width = 5)
			assert ("sub retains style", l_sub.style.foreground.ansi_code = 6)
		end

	test_text_line_and_composition
			-- Test TEXT_LINE aggregation of spans and overall width.
		local
			l_line: TEXT_LINE
			l_s1, l_s2: TEXT_SPAN
			l_style1, l_style2: STYLE
		do
			create l_line.make_empty
			assert ("initially empty", l_line.is_empty)

			create l_style1.make_fg ({COLOR}.red)
			create l_s1.make ("Part1: ", l_style1)

			create l_style2.make_fg ({COLOR}.green)
			create l_s2.make ("OK", l_style2)

			l_line.append_span (l_s1)
			l_line.append_span (l_s2)

			assert ("count 2 spans", l_line.count = 2)
			assert ("total width 9", l_line.width = 9)
			assert ("plain text", l_line.to_plain_string.same_string_general ("Part1: OK"))
		end

	test_text_wrapping
			-- Test word wrapping and character wrapping with style retention.
		local
			l_line: TEXT_LINE
			l_wrapped: ARRAYED_LIST [TEXT_LINE]
			l_style: STYLE
		do
			create l_style.make_fg ({COLOR}.yellow)
			create l_line.make_styled ("The quick brown fox jumps over the lazy dog", l_style)

			-- Wrap at width 16 columns using word wrapping
			l_wrapped := {TEXT_LAYOUT}.wrap_line (l_line, 16, {TEXT_WRAP_MODE}.word, True)
			assert ("wrapped into multiple lines", l_wrapped.count >= 3)
			assert ("line 1 words", l_wrapped.i_th (1).to_plain_string.same_string_general ("The quick brown"))
			assert ("line 2 words", l_wrapped.i_th (2).to_plain_string.same_string_general ("fox jumps over"))
			assert ("line 3 words", l_wrapped.i_th (3).to_plain_string.same_string_general ("the lazy dog"))

			-- Character wrapping
			l_wrapped := {TEXT_LAYOUT}.wrap_line (l_line, 10, {TEXT_WRAP_MODE}.character, True)
			assert ("char wrapped line count", l_wrapped.count >= 4)
			assert ("line 1 char wrap", l_wrapped.i_th (1).to_plain_string.same_string_general ("The quick "))
		end

	test_text_alignment
			-- Test alignment offset calculations.
		local
			l_offset: NATURAL_16
		do
			-- Width 10 inside area 30
			l_offset := {TEXT_LAYOUT}.aligned_offset (10, 30, {TEXT_ALIGNMENT}.left)
			assert ("left offset is 0", l_offset = 0)

			l_offset := {TEXT_LAYOUT}.aligned_offset (10, 30, {TEXT_ALIGNMENT}.center)
			assert ("center offset is 10", l_offset = 10)

			l_offset := {TEXT_LAYOUT}.aligned_offset (10, 30, {TEXT_ALIGNMENT}.right)
			assert ("right offset is 20", l_offset = 20)

			-- Line wider than area
			l_offset := {TEXT_LAYOUT}.aligned_offset (40, 30, {TEXT_ALIGNMENT}.center)
			assert ("overflow offset is 0", l_offset = 0)
		end

	test_tui_block_geometry_and_rendering
			-- Test TUI_BLOCK inner area computation and border drawing.
		local
			l_block: TUI_BLOCK
			l_outer, l_inner: RECT
			l_pad: MARGIN
			l_buf: BUFFER
		do
			create l_block.make
			l_block.set_border_type ({BORDER_TYPE}.rounded)
			l_block.set_title_string ("Panel")
			create l_pad.make (1, 1)
			l_block.set_padding (l_pad)

			create l_outer.make (0, 0, 20, 10)
			l_inner := l_block.inner (l_outer)

			-- Left border (1) + horizontal padding (1) = 2 inset on left and right
			-- Width = 20 - 2 (borders) - 2 (padding) = 16
			assert ("inner x is 2", l_inner.x = 2)
			assert ("inner y is 2", l_inner.y = 2)
			assert ("inner width is 16", l_inner.width = 16)
			assert ("inner height is 6", l_inner.height = 6)

			-- Render onto buffer
			create l_buf.make (20, 10)
			l_block.render (l_outer, l_buf)

			-- Check rounded top-left corner '╭' (code 9581) at (0, 0)
			assert ("top left is rounded corner", l_buf.cell (0, 0).symbol.code (1) = 9581)
			-- Check rounded top-right corner '╮' (code 9582) at (0, 19)
			assert ("top right is rounded corner", l_buf.cell (0, 19).symbol.code (1) = 9582)
			-- Check rounded bottom-left corner '╰' (code 9584) at (9, 0)
			assert ("bottom left is rounded corner", l_buf.cell (9, 0).symbol.code (1) = 9584)
			-- Check rounded bottom-right corner '╯' (code 9583) at (9, 19)
			assert ("bottom right is rounded corner", l_buf.cell (9, 19).symbol.code (1) = 9583)

			-- Check title rendered on top border at (0, 1)
			assert ("title character P", l_buf.cell (0, 1).symbol.same_string_general ("P"))
			assert ("title character a", l_buf.cell (0, 2).symbol.same_string_general ("a"))
			assert ("title character n", l_buf.cell (0, 3).symbol.same_string_general ("n"))
			assert ("title character e", l_buf.cell (0, 4).symbol.same_string_general ("e"))
			assert ("title character l", l_buf.cell (0, 5).symbol.same_string_general ("l"))
		end

	test_tui_paragraph_rendering
			-- Test TUI_PARAGRAPH rendered inside a block with wrapping.
		local
			l_p: TUI_PARAGRAPH
			l_block: TUI_BLOCK
			l_buf: BUFFER
			l_area: RECT
		do
			create l_block.make
			l_block.set_title_string ("Message")

			create l_p.make_raw ("Line 1%NLine 2")
			l_p.set_block (l_block)

			create l_buf.make (15, 6)
			create l_area.make (0, 0, 15, 6)
			l_p.render (l_area, l_buf)

			-- Inside block, row 1 is top border, so text starts at row 1
			-- (0, 0) is top-left border '┌' (code 9484)
			assert ("block top left", l_buf.cell (0, 0).symbol.code (1) = 9484)

			-- Inner row 1 contains "Line 1"
			assert ("line 1 char L", l_buf.cell (1, 1).symbol.same_string_general ("L"))
			assert ("line 1 char i", l_buf.cell (1, 2).symbol.same_string_general ("i"))
			assert ("line 1 char n", l_buf.cell (1, 3).symbol.same_string_general ("n"))
			assert ("line 1 char e", l_buf.cell (1, 4).symbol.same_string_general ("e"))
			assert ("line 1 char 1", l_buf.cell (1, 6).symbol.same_string_general ("1"))

			-- Inner row 2 contains "Line 2"
			assert ("line 2 char L", l_buf.cell (2, 1).symbol.same_string_general ("L"))
			assert ("line 2 char 2", l_buf.cell (2, 6).symbol.same_string_general ("2"))
		end

	test_tui_clear
			-- Test TUI_CLEAR clearing buffer region.
		local
			l_buf: BUFFER
			l_clear: TUI_CLEAR
			l_area: RECT
			l_style: STYLE
		do
			create l_buf.make (10, 5)
			create l_style.default_create
			l_buf.fill ('X', l_style)
			assert ("dirty cell", l_buf.cell (2, 3).symbol.same_string_general ("X"))

			create l_clear
			create l_area.make (2, 1, 4, 3)
			l_clear.render (l_area, l_buf)

			-- (1, 2) is inside cleared area (y in 1..3, x in 2..5)
			assert ("cleared cell is space", l_buf.cell (1, 2).symbol.same_string_general (" "))
			assert ("cleared cell 2,3 is space", l_buf.cell (2, 3).symbol.same_string_general (" "))

			-- (0, 0) was outside cleared area and still 'X'
			assert ("outside cell is still X", l_buf.cell (0, 0).symbol.same_string_general ("X"))
		end

end
