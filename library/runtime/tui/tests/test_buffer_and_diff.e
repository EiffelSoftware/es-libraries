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

feature -- V8: CellDiffOption, Ratatui diff.rs

	test_ratatui_skip_cells_are_skipped
			-- Ratatui `skip_cells_are_skipped`: "abc" to "xyz" with the middle cell skipped
			-- writes "x" and "z" only, in two spans (the skip ends the span).
		local
			l_prev, l_next: BUFFER
			l_spans: ARRAYED_LIST [DIFF_SPAN]
		do
			l_prev := buffer_with_lines (<<"abc">>)
			l_next := buffer_with_lines (<<"xyz">>)
			l_next.set_diff_option (0, 1, {CELL_DIFF_OPTION}.Skip, 0)
			l_spans := (create {DIFF_ENGINE}).diff (l_prev, l_next)
			assert_written ("x and z", l_spans, "0,0=x 0,2=z ")
			assert_layout ("two spans", l_spans, "0:0+1 0:2+1 ")
		end

	test_ratatui_always_update_cells_are_emitted_even_when_identical
			-- Ratatui `always_update_cells_are_emitted_even_when_identical`.
		local
			l_prev, l_next: BUFFER
			l_spans: ARRAYED_LIST [DIFF_SPAN]
		do
			l_prev := buffer_with_lines (<<"abc">>)
			l_prev.set_diff_option (0, 1, {CELL_DIFF_OPTION}.Always_update, 0)
			l_next := buffer_with_lines (<<"abc">>)
			l_next.set_diff_option (0, 1, {CELL_DIFF_OPTION}.Always_update, 0)
			l_spans := (create {DIFF_ENGINE}).diff (l_prev, l_next)
			assert_written ("b only", l_spans, "0,1=b ")
			-- Every frame: the same buffers again give the same output
			l_spans := (create {DIFF_ENGINE}).diff (l_next, l_next)
			assert_written ("b again", l_spans, "0,1=b ")
		end

	test_ratatui_forced_width_skips_trailing
			-- Ratatui `forced_width_skips_trailing`: "abcd" to "xbcd" with a forced width of 2 at
			-- column 0 writes "x" only. Also when the covered cell changed: it is not compared.
		local
			l_prev, l_next: BUFFER
			l_spans: ARRAYED_LIST [DIFF_SPAN]
		do
			l_prev := buffer_with_lines (<<"abcd">>)
			l_next := buffer_with_lines (<<"xbcd">>)
			l_next.set_diff_option (0, 0, {CELL_DIFF_OPTION}.Forced_width, 2)
			l_spans := (create {DIFF_ENGINE}).diff (l_prev, l_next)
			assert_written ("x only", l_spans, "0,0=x ")

			l_next := buffer_with_lines (<<"xycd">>)
			l_next.set_diff_option (0, 0, {CELL_DIFF_OPTION}.Forced_width, 2)
			l_spans := (create {DIFF_ENGINE}).diff (l_prev, l_next)
			assert_written ("covered y not written", l_spans, "0,0=x ")

			l_next := buffer_with_lines (<<"xyzd">>)
			l_next.set_diff_option (0, 0, {CELL_DIFF_OPTION}.Forced_width, 2)
			l_spans := (create {DIFF_ENGINE}).diff (l_prev, l_next)
			assert_written ("z after the cover", l_spans, "0,0=x 0,2=z ")
			assert_layout ("a span after the cover", l_spans, "0:0+1 0:2+1 ")
		end

	test_ratatui_forced_width_replaces_skip
			-- Adapted from Ratatui `forced_width_takes_precedence_over_deprecated_skip` and
			-- `deprecated_skip_field_is_respected`. EiffelTUI has one option per cell and no
			-- separate skip flag: the option set last wins, so a forced width replaces a skip.
		local
			l_prev, l_next: BUFFER
		do
			l_prev := buffer_with_lines (<<"abcd">>)
			l_next := buffer_with_lines (<<"xbcd">>)
			l_next.set_diff_option (0, 0, {CELL_DIFF_OPTION}.Skip, 0)
			assert_written ("skipped", (create {DIFF_ENGINE}).diff (l_prev, l_next), "")
			l_next.set_diff_option (0, 0, {CELL_DIFF_OPTION}.Forced_width, 2)
			assert ("forced replaces skip", l_next.cell (0, 0).diff_option = {CELL_DIFF_OPTION}.Forced_width)
			assert_written ("x", (create {DIFF_ENGINE}).diff (l_prev, l_next), "0,0=x ")

			l_prev := buffer_with_lines (<<"abc">>)
			l_next := buffer_with_lines (<<"xyz">>)
			l_next.set_diff_option (0, 1, {CELL_DIFF_OPTION}.Skip, 0)
			assert_written ("xz", (create {DIFF_ENGINE}).diff (l_prev, l_next), "0,0=x 0,2=z ")
		end

feature -- V8: CellDiffOption, Ratatui buffer.rs

	test_ratatui_diff_skip
			-- Ratatui `diff_skip`: "123" to "456" with cells 1 and 2 skipped writes "4" only.
		local
			l_prev, l_next: BUFFER
		do
			l_prev := buffer_with_lines (<<"123">>)
			l_next := buffer_with_lines (<<"456">>)
			l_next.set_diff_option (0, 1, {CELL_DIFF_OPTION}.Skip, 0)
			l_next.set_diff_option (0, 2, {CELL_DIFF_OPTION}.Skip, 0)
			assert_written ("4 only", (create {DIFF_ENGINE}).diff (l_prev, l_next), "0,0=4 ")
		end

	test_ratatui_merge_diff_forcedwidth
			-- Ratatui `merge_diff_forcedwidth`: after a merge, the diff to the merged buffer is empty.
		local
			l_prev, l_next: BUFFER
		do
			l_prev := buffer_with_lines (<<"123">>)
			create l_next.make (3, 1)
			put_symbol (l_next, 0, 0, "456")
			l_next.set_diff_option (0, 0, {CELL_DIFF_OPTION}.Forced_width, 3)
			l_prev.merge (l_next)
			assert ("option merged", l_prev.cell (0, 0).diff_option = {CELL_DIFF_OPTION}.Forced_width and l_prev.cell (0, 0).forced_width = 3)
			assert_written ("no diff", (create {DIFF_ENGINE}).diff (l_prev, l_next), "")
		end

	test_ratatui_merge_diff_link
			-- Ratatui `merge_diff_link`: a whole OSC 8 link squeezed into the first cell.
		local
			l_prev, l_next: BUFFER
		do
			l_prev := buffer_with_lines (<<"____">>)
			create l_next.make (4, 1)
			put_symbol (l_next, 0, 0, osc_8 ("http://example.com", "link"))
			l_next.set_diff_option (0, 0, {CELL_DIFF_OPTION}.Forced_width, 4)
			l_prev.merge (l_next)
			assert_written ("no diff", (create {DIFF_ENGINE}).diff (l_prev, l_next), "")
		end

	test_ratatui_merge_diff_split_link
			-- Ratatui `merge_diff_split_link`: the opening sequence and a wide first character in
			-- the first cell, plain inner characters, the closing part in the last cell.
		local
			l_prev, l_next: BUFFER
			l_open, l_close: STRING_32
		do
			l_prev := buffer_with_lines (<<"________">>)
			create l_next.make (8, 1)
			l_open := {STRING_32} "%/27/]8;;http://example.com%/27/\%/0x1F517/"
			put_symbol (l_next, 0, 0, l_open)
			l_next.set_diff_option (0, 0, {CELL_DIFF_OPTION}.Forced_width, 2)
			l_next.put_string (0, 2, "link", create {STYLE})
			l_close := {STRING_32} "%/0x1F517/%/27/]8;;%/27/\"
			put_symbol (l_next, 0, 7, l_close)
			l_next.set_diff_option (0, 7, {CELL_DIFF_OPTION}.Forced_width, 2)
			l_prev.merge (l_next)
			assert_written ("no diff", (create {DIFF_ENGINE}).diff (l_prev, l_next), "")
			-- The forced width of the last cell stops at the end of the row
			assert_written ("all but the covered cell from blank", (create {DIFF_ENGINE}).diff (create {BUFFER}.make (8, 1), l_next),
				{STRING_32} "0,0=" + l_open + " 0,2=l 0,3=i 0,4=n 0,5=k 0,6=  0,7=" + l_close + " ")
		end

	test_ratatui_merge_diff_image_sequences
			-- Ratatui `merge_diff_image_sequences`: kitty placeholder cells with escape sequences,
			-- each forced to one column, merged over a buffer of "x".
		local
			l_prev, l_buffer: BUFFER
			l_start: STRING_32
		do
			create l_prev.make (20, 1)
			l_start := {STRING_32} "%/27/[s%/27/[38;2;0;0;0m%/0x10EEEE/%/0x305/%/0x305/%/0x305/"
			put_symbol (l_prev, 0, 0, l_start)
			l_prev.set_diff_option (0, 0, {CELL_DIFF_OPTION}.Forced_width, 1)
			put_symbol (l_prev, 0, 1, {STRING_32} "%/0x10EEEE/")
			put_symbol (l_prev, 0, 2, {STRING_32} "%/0x10EEEE/")
			put_symbol (l_prev, 0, 3, {STRING_32} "%/0x10EEEE/%/27/[u")
			l_prev.set_diff_option (0, 3, {CELL_DIFF_OPTION}.Forced_width, 1)
			create l_buffer.make (20, 1)
			l_buffer.fill ('x', create {STYLE})
			l_buffer.merge (l_prev)
			assert_written ("no diff", (create {DIFF_ENGINE}).diff (l_buffer, l_prev), "")
		end

	test_ratatui_merge_skip
			-- Adapted from Ratatui `merge_skip`: a merge copies the diff option with the cell.
			-- BUFFER.merge copies the top-left overlap, so the second buffer (2 x 2) covers
			-- the first two rows of the first (2 x 3).
		local
			l_one, l_two: BUFFER
		do
			l_one := filled_with_option (2, 3, '1', {CELL_DIFF_OPTION}.None)
			l_two := filled_with_option (2, 2, '2', {CELL_DIFF_OPTION}.Skip)
			l_one.merge (l_two)
			assert ("skip, skip, none", options_of (l_one).same_string ("11 11 00"))

			l_one := filled_with_option (2, 3, '1', {CELL_DIFF_OPTION}.Skip)
			l_two := filled_with_option (2, 2, '2', {CELL_DIFF_OPTION}.None)
			l_one.merge (l_two)
			assert ("none, none, skip", options_of (l_one).same_string ("00 00 11"))
		end

feature -- V8: CellDiffOption, spans

	test_skip_splits_merged_span
			-- Two dirty cells with a skipped cell in the gap give two spans, not one merged
			-- span: the merged gap would write over the skipped cell.
		local
			l_prev, l_curr: BUFFER
			l_spans: ARRAYED_LIST [DIFF_SPAN]
		do
			create l_prev.make (30, 2)
			create l_curr.make (30, 2)
			l_curr.put_char (1, 2, 'A', create {STYLE})
			l_curr.put_char (1, 5, 'B', create {STYLE})
			l_spans := (create {DIFF_ENGINE}).diff (l_prev, l_curr)
			assert_layout ("merged without skip", l_spans, "1:2+4 ")

			l_curr.set_diff_option (1, 4, {CELL_DIFF_OPTION}.Skip, 0)
			l_spans := (create {DIFF_ENGINE}).diff (l_prev, l_curr)
			assert_layout ("split by the skip", l_spans, "1:2+1 1:5+1 ")
			assert_written ("A and B", l_spans, "1,2=A 1,5=B ")

			-- A skipped cell right after a dirty one, and a dirty skipped cell
			l_curr.put_char (1, 3, 'C', create {STYLE})
			l_curr.set_diff_option (1, 3, {CELL_DIFF_OPTION}.Skip, 0)
			l_curr.set_diff_option (1, 4, {CELL_DIFF_OPTION}.None, 0)
			l_spans := (create {DIFF_ENGINE}).diff (l_prev, l_curr)
			assert_layout ("C skipped, no gap merged over it", l_spans, "1:2+1 1:5+1 ")
			assert_written ("C not written", l_spans, "1,2=A 1,5=B ")
		end

	test_forced_width_cover_splits_span
			-- The cells a forced width covers are never in a span, even inside a mergeable gap.
		local
			l_prev, l_curr: BUFFER
			l_spans: ARRAYED_LIST [DIFF_SPAN]
		do
			create l_prev.make (30, 1)
			create l_curr.make (30, 1)
			-- The same forced cell (unchanged) in both frames, covering column 4
			-- A forced cell covering column 4 in both frames; it changes to "F" in this one
			l_prev.set_diff_option (0, 3, {CELL_DIFF_OPTION}.Forced_width, 2)
			l_curr.put_char (0, 1, 'A', create {STYLE})
			l_curr.put_char (0, 3, 'F', create {STYLE})
			l_curr.set_diff_option (0, 3, {CELL_DIFF_OPTION}.Forced_width, 2)
			l_curr.put_char (0, 4, 'Z', create {STYLE})
			l_curr.put_char (0, 6, 'B', create {STYLE})
			l_spans := (create {DIFF_ENGINE}).diff (l_prev, l_curr)
			assert_layout ("gap merged up to the forced cell, new span after the cover", l_spans, "0:1+3 0:6+1 ")
			assert_written ("Z covered", l_spans, "0,1=A 0,2=  0,3=F 0,6=B ")
			-- Unchanged forced cell: the span before the cover holds A only
			l_prev.put_char (0, 3, 'F', create {STYLE})
			l_prev.set_diff_option (0, 3, {CELL_DIFF_OPTION}.Forced_width, 2)
			l_spans := (create {DIFF_ENGINE}).diff (l_prev, l_curr)
			assert_layout ("A, then B", l_spans, "0:1+1 0:6+1 ")
		end

	test_forced_width_stops_at_row_end
			-- A forced width past the end of its row does not cover the next row.
		local
			l_prev, l_curr: BUFFER
		do
			create l_prev.make (5, 2)
			create l_curr.make (5, 2)
			l_prev.set_diff_option (0, 4, {CELL_DIFF_OPTION}.Forced_width, 9)
			l_curr.set_diff_option (0, 4, {CELL_DIFF_OPTION}.Forced_width, 9)
			l_curr.put_char (1, 0, 'n', create {STYLE})
			assert_written ("next row written", (create {DIFF_ENGINE}).diff (l_prev, l_curr), "1,0=n ")
		end

	test_option_change_is_dirty
			-- A cell whose option differs from the previous frame's is written (Ratatui compares
			-- the option as part of the cell), even when it looks the same.
		local
			l_prev, l_curr: BUFFER
		do
			l_prev := buffer_with_lines (<<"abc">>)
			l_curr := buffer_with_lines (<<"abc">>)
			l_prev.set_diff_option (0, 0, {CELL_DIFF_OPTION}.Skip, 0)
			assert_written ("no longer skipped", (create {DIFF_ENGINE}).diff (l_prev, l_curr), "0,0=a ")

			l_prev := buffer_with_lines (<<"abc">>)
			l_prev.set_diff_option (0, 1, {CELL_DIFF_OPTION}.Always_update, 0)
			assert_written ("no longer always updated", (create {DIFF_ENGINE}).diff (l_prev, l_curr), "0,1=b ")

			l_prev := buffer_with_lines (<<"abc">>)
			l_curr := buffer_with_lines (<<"abc">>)
			l_prev.set_diff_option (0, 0, {CELL_DIFF_OPTION}.Forced_width, 1)
			l_curr.set_diff_option (0, 0, {CELL_DIFF_OPTION}.Forced_width, 2)
			assert_written ("forced width changed", (create {DIFF_ENGINE}).diff (l_prev, l_curr), "0,0=a ")
			l_prev.set_diff_option (0, 0, {CELL_DIFF_OPTION}.Forced_width, 2)
			assert_written ("same forced width", (create {DIFF_ENGINE}).diff (l_prev, l_curr), "")
		end

	test_previous_cover_is_redrawn
			-- The columns a forced width covered in the previous frame are written when the
			-- current frame does not cover them: the terminal shows what the covering cell drew
			-- there, not the previous buffer's cells (an EiffelTUI addition to Ratatui).
		local
			l_prev, l_curr: BUFFER
		do
			l_prev := buffer_with_lines (<<"abcde">>)
			l_curr := buffer_with_lines (<<"abcde">>)
			l_prev.set_diff_option (0, 1, {CELL_DIFF_OPTION}.Forced_width, 3)
			assert_written ("b changed option, c and d uncovered", (create {DIFF_ENGINE}).diff (l_prev, l_curr), "0,1=b 0,2=c 0,3=d ")
			-- Still covered by a shorter forced width: only the uncovered column
			l_curr.set_diff_option (0, 1, {CELL_DIFF_OPTION}.Forced_width, 2)
			assert_written ("b and d", (create {DIFF_ENGINE}).diff (l_prev, l_curr), "0,1=b 0,3=d ")
			-- Under a skipped cell nothing is written
			l_curr.set_diff_option (0, 3, {CELL_DIFF_OPTION}.Skip, 0)
			assert_written ("d skipped", (create {DIFF_ENGINE}).diff (l_prev, l_curr), "0,1=b ")
		end

	test_options_in_grown_area
			-- In the area a larger current buffer adds, a skipped cell is still not written and
			-- a forced width still covers.
		local
			l_prev, l_curr: BUFFER
		do
			create l_prev.make (2, 1)
			create l_curr.make (6, 1)
			l_curr.put_string (0, 0, "abcdef", create {STYLE})
			l_curr.set_diff_option (0, 2, {CELL_DIFF_OPTION}.Skip, 0)
			l_curr.set_diff_option (0, 3, {CELL_DIFF_OPTION}.Forced_width, 2)
			assert_written ("c skipped, e covered", (create {DIFF_ENGINE}).diff (l_prev, l_curr), "0,0=a 0,1=b 0,3=d 0,5=f ")
		end

feature -- V8: CellDiffOption, buffer operations

	test_writes_clear_diff_option
			-- Writing content into a cell clears its option (the decision recorded in BUFFER's
			-- note; Ratatui's `set_symbol` keeps it).
		local
			l_buf: BUFFER
			l_cell: TERMINAL_CELL
		do
			create l_buf.make (10, 2)
			l_buf.set_diff_option (0, 0, {CELL_DIFF_OPTION}.Skip, 0)
			l_buf.put_char (0, 0, 'a', create {STYLE})
			assert ("put_char clears", l_buf.cell (0, 0).diff_option = {CELL_DIFF_OPTION}.None)

			l_buf.set_diff_option (0, 1, {CELL_DIFF_OPTION}.Forced_width, 3)
			l_buf.put_string (0, 1, "b", create {STYLE})
			assert ("put_string clears", no_option (l_buf.cell (0, 1)))

			l_buf.set_diff_option (0, 2, {CELL_DIFF_OPTION}.Always_update, 0)
			l_buf.set_line (0, 0, create {TEXT_LINE}.make_raw ("xyz"), 10)
			assert ("set_line clears", no_option (l_buf.cell (0, 2)))

			-- A wide character written over the left half repairs the right half
			l_buf.put_char (1, 0, (0x65E5).to_character_32, create {STYLE})
			l_buf.set_diff_option (1, 2, {CELL_DIFF_OPTION}.Skip, 0)
			l_buf.put_char (1, 1, (0x65E5).to_character_32, create {STYLE})
			assert ("continuation made over a skip", l_buf.cell (1, 2).is_continuation and no_option (l_buf.cell (1, 2)))

			l_buf.set_diff_option (1, 5, {CELL_DIFF_OPTION}.Skip, 0)
			l_buf.fill ('.', create {STYLE})
			assert ("fill clears", no_option (l_buf.cell (1, 5)))
			l_buf.set_diff_option (1, 5, {CELL_DIFF_OPTION}.Skip, 0)
			l_buf.clear
			assert ("clear clears", no_option (l_buf.cell (1, 5)))

			l_cell := l_buf.cell (1, 6)
			l_buf.set_diff_option (1, 6, {CELL_DIFF_OPTION}.Forced_width, 2)
			l_cell.set_symbol ("s")
			assert ("set_symbol clears", no_option (l_cell))
			l_buf.set_diff_option (1, 6, {CELL_DIFF_OPTION}.Skip, 0)
			l_cell.set_char ('c')
			assert ("set_char clears", no_option (l_cell))
			l_buf.set_diff_option (1, 6, {CELL_DIFF_OPTION}.Skip, 0)
			l_cell.reset
			assert ("reset clears", no_option (l_cell))
			assert ("default_create has none", no_option (create {TERMINAL_CELL}))
			assert ("consistent", l_buf.is_consistent)
		end

	test_style_changes_keep_diff_option
			-- Changing only a cell's style keeps its option; so do merge, copy_from and resize.
		local
			l_buf, l_copy: BUFFER
			l_red: STYLE
		do
			create l_red.make_fg ({COLOR}.red)
			l_buf := buffer_with_lines (<<"abcd", "efgh">>)
			l_buf.set_diff_option (0, 0, {CELL_DIFF_OPTION}.Skip, 0)
			l_buf.set_diff_option (0, 1, {CELL_DIFF_OPTION}.Forced_width, 2)
			l_buf.set_diff_option (1, 3, {CELL_DIFF_OPTION}.Always_update, 0)
			l_buf.set_style (l_buf.area, l_red)
			l_buf.set_style_region (0, 0, 4, 2, l_red)
			l_buf.cell (0, 0).set_style (l_red)
			assert ("styles kept options", options_of (l_buf).same_string ("1300 0002"))
			assert ("forced width kept", l_buf.cell (0, 1).forced_width = 2)

			create l_copy.make (4, 2)
			l_copy.copy_from (l_buf)
			assert ("copy_from keeps", options_of (l_copy).same_string ("1300 0002") and l_copy.cell (0, 1).forced_width = 2)

			l_copy.resize (6, 3)
			assert ("grown keeps", l_copy.cell (0, 0).diff_option = {CELL_DIFF_OPTION}.Skip and l_copy.cell (1, 3).diff_option = {CELL_DIFF_OPTION}.Always_update)
			l_copy.resize (2, 1)
			assert ("shrunk keeps", options_of (l_copy).same_string ("13") and l_copy.cell (0, 1).forced_width = 2)
		end

	test_cell_equality_with_diff_option
			-- `same_content` compares what is shown and ignores the option; `is_equal` (like
			-- Ratatui's `Cell` equality) and `same_diff_option` compare it; copies keep it.
		local
			l_buf: BUFFER
			l_a, l_b: TERMINAL_CELL
		do
			l_buf := buffer_with_lines (<<"aa">>)
			l_buf.set_diff_option (0, 0, {CELL_DIFF_OPTION}.Forced_width, 2)
			l_a := l_buf.cell (0, 0)
			l_b := l_buf.cell (0, 1)
			assert ("same content", l_a.same_content (l_b))
			assert ("not equal", not l_a.is_equal (l_b) and not l_a.same_diff_option (l_b))
			assert ("twin equal", l_a.twin.is_equal (l_a) and l_a.twin.forced_width = 2)
			assert ("covered width", l_a.covered_width = 2 and l_b.covered_width = 1)
			l_buf.set_diff_option (0, 1, {CELL_DIFF_OPTION}.Forced_width, 2)
			assert ("equal now", l_a.is_equal (l_b))
		end

	test_set_diff_option_preconditions
			-- `set_diff_option` needs a valid option, a forced width only with `Forced_width`
			-- (and at least 1 there), and no forced width on a continuation cell.
		local
			l_buf: BUFFER
		do
			create l_buf.make (4, 1)
			l_buf.put_char (0, 0, (0x65E5).to_character_32, create {STYLE})
			assert ("invalid option", precondition_raised (agent l_buf.set_diff_option (0, 2, 4, 0), "valid_option"))
			assert ("forced width 0", precondition_raised (agent l_buf.set_diff_option (0, 2, {CELL_DIFF_OPTION}.Forced_width, 0), "valid_width"))
			assert ("skip with width", precondition_raised (agent l_buf.set_diff_option (0, 2, {CELL_DIFF_OPTION}.Skip, 1), "valid_width"))
			assert ("forced continuation", precondition_raised (agent l_buf.set_diff_option (0, 1, {CELL_DIFF_OPTION}.Forced_width, 1), "forced_not_continuation"))
			assert ("skip continuation allowed", not precondition_raised (agent l_buf.set_diff_option (0, 1, {CELL_DIFF_OPTION}.Skip, 0), "forced_not_continuation"))
			assert ("valid", {CELL_DIFF_OPTION}.is_valid (3) and not {CELL_DIFF_OPTION}.is_valid (4))
		end

feature {NONE} -- V8 helpers

	buffer_with_lines (a_lines: ARRAY [READABLE_STRING_GENERAL]): BUFFER
			-- Buffer as wide as the longest of `a_lines` (ASCII) with one row per line
			-- (Ratatui `Buffer::with_lines`)
		local
			l_width, i: INTEGER
		do
			across a_lines as l loop
				l_width := l_width.max (l.count)
			end
			create Result.make (l_width, a_lines.count)
			from i := a_lines.lower until i > a_lines.upper loop
				Result.put_string (i - a_lines.lower, 0, a_lines [i], create {STYLE})
				i := i + 1
			end
		end

	filled_with_option (a_width, a_height: INTEGER; a_char: CHARACTER_32; a_option: NATURAL_8): BUFFER
			-- `a_width` x `a_height` buffer of `a_char`, each cell with `a_option`
		local
			r, c: INTEGER
		do
			create Result.make (a_width, a_height)
			Result.fill (a_char, create {STYLE})
			from r := 0 until r >= a_height loop
				from c := 0 until c >= a_width loop
					Result.set_diff_option (r, c, a_option, 0)
					c := c + 1
				end
				r := r + 1
			end
		end

	put_symbol (a_buffer: BUFFER; a_row, a_col: INTEGER; a_symbol: READABLE_STRING_GENERAL)
			-- Store `a_symbol` whole in one one-column cell (Ratatui `Cell::set_symbol`), as an
			-- escape-sequence symbol is stored: the buffer's writes would drop the escapes.
		do
			a_buffer.cell (a_row, a_col).set_symbol (a_symbol)
			a_buffer.cell (a_row, a_col).set_width (1)
		end

	osc_8 (a_url, a_text: READABLE_STRING_GENERAL): STRING_32
			-- `a_text` as an OSC 8 link to `a_url`, with ST terminators
		do
			Result := {STRING_32} "%/27/]8;;"
			Result.append_string_general (a_url)
			Result.append ({STRING_32} "%/27/\")
			Result.append_string_general (a_text)
			Result.append ({STRING_32} "%/27/]8;;%/27/\")
		end

	options_of (a_buffer: BUFFER): STRING
			-- Diff option of every cell as a digit, rows separated by a space
		local
			r, c: INTEGER
		do
			create Result.make (a_buffer.area_count + a_buffer.height)
			from r := 0 until r >= a_buffer.height loop
				if r > 0 then
					Result.append_character (' ')
				end
				from c := 0 until c >= a_buffer.width loop
					Result.append_natural_8 (a_buffer.cell (r, c).diff_option)
					c := c + 1
				end
				r := r + 1
			end
		end

	no_option (a_cell: TERMINAL_CELL): BOOLEAN
			-- Has `a_cell` no diff option?
		do
			Result := a_cell.diff_option = {CELL_DIFF_OPTION}.None and a_cell.forced_width = 0
		end

	written (a_spans: LIST [DIFF_SPAN]): STRING_32
			-- "row,col=symbol " for each cell the spans write (continuation cells write nothing)
		local
			i: INTEGER
		do
			create Result.make (64)
			across a_spans as s loop
				from i := 1 until i > s.count loop
					if not s.cells [i].is_continuation then
						Result.append_integer (s.row)
						Result.append_character (',')
						Result.append_integer (s.start_col + i - 1)
						Result.append_character ('=')
						Result.append (s.cells [i].symbol)
						Result.append_character (' ')
					end
					i := i + 1
				end
			end
		end

	assert_written (a_tag: STRING; a_spans: LIST [DIFF_SPAN]; a_expected: READABLE_STRING_GENERAL)
			-- Assert that `a_spans` write exactly `a_expected` (see `written`).
		do
			assert (a_tag + ": got [" + {UTF_CONVERTER}.string_32_to_utf_8_string_8 (written (a_spans)) + "]", written (a_spans).same_string_general (a_expected))
		end

	assert_layout (a_tag: STRING; a_spans: LIST [DIFF_SPAN]; a_expected: STRING)
			-- Assert that `a_spans` are "row:start+count " each, in order.
		local
			l_got: STRING
		do
			create l_got.make (32)
			across a_spans as s loop
				l_got.append_integer (s.row)
				l_got.append_character (':')
				l_got.append_integer (s.start_col)
				l_got.append_character ('+')
				l_got.append_integer (s.count)
				l_got.append_character (' ')
			end
			assert (a_tag + ": got [" + l_got + "]", l_got.same_string (a_expected))
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
