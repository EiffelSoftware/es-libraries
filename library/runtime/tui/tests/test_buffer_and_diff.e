note
	description: "[
		AutoTest suite for Layer 3: Cell, Buffer, Wide Glyphs, Diff Engine, and ANSI Serializer.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_BUFFER_AND_DIFF

inherit
	EQA_TEST_SET

feature -- Test routines

	test_color_and_styles
			-- Test Color definitions and SGR sequence generation.
		local
			l_c1, l_c2: COLOR
			l_style: STYLE
		do
			l_c1 := {COLOR}.red
			assert ("red is ansi", l_c1.is_ansi)
			assert ("red sgr fg", l_c1.sgr_fg.is_equal ("31"))
			assert ("red sgr bg", l_c1.sgr_bg.is_equal ("41"))

			create l_c2.make_rgb (100, 150, 200)
			assert ("is rgb", l_c2.is_rgb)
			assert ("rgb sgr fg", l_c2.sgr_fg.is_equal ("38;2;100;150;200"))

			create l_style.make_with_colors (l_c1, l_c2)
			l_style := l_style.with_bold
			assert ("bold active", l_style.flags.is_bold)
			assert ("sgr starts with esc", l_style.sgr_sequence.starts_with ("%/27/["))
			assert ("sgr ends with m", l_style.sgr_sequence.ends_with ("m"))
		end

	test_unicode_and_wide_glyphs
			-- Test character width detection (narrow, wide, zero-width).
		local
			l_helper: UNICODE_WIDTH
		do
			create l_helper
			assert ("ascii 'A' is 1", l_helper.width (('A').natural_32_code) = 1)
			assert ("space is 1", l_helper.width ((' ').natural_32_code) = 1)
			-- CJK Ideograph '中' (U+4E2D = 20013)
			assert ("CJK '%/0x4E2D/' is 2", l_helper.width (20013) = 2)
			-- Zero width space (U+200B = 8203)
			assert ("ZWSP is 0", l_helper.width (8203) = 0)
		end

	test_buffer_wide_character_placement
			-- Test placing wide character creates primary cell and continuation cell.
		local
			l_buf: BUFFER
			l_style: STYLE
			l_cjk_char: CHARACTER_32
		do
			create l_buf.make (10, 5)
			create l_style.default_create
			l_cjk_char := (20013).to_character_32 -- '中'

			l_buf.put_char (1, 2, l_cjk_char, l_style)
			assert ("cell width is 2", l_buf.cell (1, 2).width = 2)
			assert ("not continuation", not l_buf.cell (1, 2).is_continuation)
			assert ("cell 3 is continuation", l_buf.cell (1, 3).is_continuation)
			assert ("continuation width is 0", l_buf.cell (1, 3).width = 0)

			-- Now overwrite continuation cell at (1, 3) with standard char 'X'
			-- Parent cell at (1, 2) should be repaired to space!
			l_buf.put_char (1, 3, 'X', l_style)
			assert ("parent repaired to space", l_buf.cell (1, 2).symbol.is_equal ({STRING_32} " "))
			assert ("parent width reset to 1", l_buf.cell (1, 2).width = 1)
			assert ("cell 3 has 'X'", l_buf.cell (1, 3).symbol.is_equal ({STRING_32} "X"))
			assert ("cell 3 width is 1", l_buf.cell (1, 3).width = 1)
			assert ("cell 3 not continuation", not l_buf.cell (1, 3).is_continuation)
		end

	test_diff_engine_dirty_detection
			-- Test that identical buffers yield zero spans, while changes yield spans.
		local
			l_prev, l_curr: BUFFER
			l_engine: DIFF_ENGINE
			l_spans: ARRAYED_LIST [DIFF_SPAN]
			l_style: STYLE
		do
			create l_prev.make (20, 5)
			create l_curr.make (20, 5)
			create l_engine

			-- Initially identical
			l_spans := l_engine.diff (l_prev, l_curr)
			assert ("no diff for identical", l_spans.is_empty)

			-- Single character change
			create l_style.default_create
			l_curr.put_char (2, 5, 'Z', l_style)
			l_spans := l_engine.diff (l_prev, l_curr)
			assert ("one span detected", l_spans.count = 1)
			assert ("span row is 2", l_spans.first.row = 2)
			assert ("span start col is 5", l_spans.first.start_col = 5)
			assert ("span cell count is 1", l_spans.first.count = 1)
		end

	test_diff_engine_gap_merging
			-- Test merging of dirty spans with gap <= 4 cells vs distinct spans when gap > 4.
		local
			l_prev, l_curr: BUFFER
			l_engine: DIFF_ENGINE
			l_spans: ARRAYED_LIST [DIFF_SPAN]
			l_style: STYLE
		do
			create l_prev.make (30, 5)
			create l_curr.make (30, 5)
			create l_engine
			create l_style.default_create

			-- Case 1: Gap of 2 cells (col 2 and col 5). Gap = 5 - 2 - 1 = 2 <= 4 -> Merged!
			l_curr.put_char (1, 2, 'A', l_style)
			l_curr.put_char (1, 5, 'B', l_style)
			l_spans := l_engine.diff (l_prev, l_curr)
			assert ("spans merged into 1", l_spans.count = 1)
			assert ("span covers from 2 to 5", l_spans.first.start_col = 2 and l_spans.first.count = 4)

			-- Case 2: Gap of 5 cells (col 2 and col 8). Gap = 8 - 2 - 1 = 5 > 4 -> 2 spans!
			l_curr.clear
			l_curr.put_char (1, 2, 'A', l_style)
			l_curr.put_char (1, 8, 'B', l_style)
			l_spans := l_engine.diff (l_prev, l_curr)
			assert ("spans not merged (2 spans)", l_spans.count = 2)
			assert ("first span at col 2", l_spans.i_th (1).start_col = 2 and l_spans.i_th (1).count = 1)
			assert ("second span at col 8", l_spans.i_th (2).start_col = 8 and l_spans.i_th (2).count = 1)
		end

	test_ansi_serializer_with_virtual_terminal
			-- Test serializer applying diff spans to VIRTUAL_TERMINAL.
		local
			l_prev, l_curr: BUFFER
			l_engine: DIFF_ENGINE
			l_serializer: ANSI_SERIALIZER
			l_term: VIRTUAL_TERMINAL
			l_spans: ARRAYED_LIST [DIFF_SPAN]
			l_style: STYLE
		do
			create l_prev.make (20, 5)
			create l_curr.make (20, 5)
			create l_style.default_create
			l_curr.put_string (1, 3, "TUI", l_style)

			create l_engine
			l_spans := l_engine.diff (l_prev, l_curr)

			create l_term.make (20, 5)
			create l_serializer
			l_serializer.render_spans (l_spans, l_term)

			-- Verify virtual terminal has received the text
			assert ("term has T", l_term.cell (1, 3) = 'T')
			assert ("term has U", l_term.cell (1, 4) = 'U')
			assert ("term has I", l_term.cell (1, 5) = 'I')
			assert ("flush logged", l_term.operations.has ({STRING_32} "flush"))
		end

end
