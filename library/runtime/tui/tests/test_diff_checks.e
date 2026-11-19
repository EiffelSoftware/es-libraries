note
	description: "[
		P1 X2: checks of DIFF_ENGINE and ANSI_SERIALIZER against the Ratatui 0.30.1 / 0.30.2 diff
		fixes (`ratatui-core/src/buffer/diff.rs`), so the diff's behaviour is pinned before and
		after V8 (CELL_DIFF_OPTION).

		  * X2a (#2587, #2585, #2685): columns a wide glyph covered in the previous frame are
		    written when the glyph goes, and a long escape-sequence symbol hides no later cell.
		  * X2b (#2308, #2652): a wide glyph whose style alone changes is written again, and
		    nothing is written into its right half afterwards.
		  * X2c (VS16, Ratatui `terminal_model`): a cluster with U+FE0F is two columns in the
		    buffer, but some terminals draw it in one. VIRTUAL_TERMINAL is such a terminal (it
		    places code points one at a time), so the column the buffer reserved must not keep
		    the previous frame's text.

		EiffelTUI's diff compares continuation cells too, so most Ratatui cases hold by
		construction; the tests pin it.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_DIFF_CHECKS

inherit
	EQA_TEST_SET

feature -- X2a: uncovered cells

	test_uncovered_trailing_cells_written
			-- Ratatui `uncovered_trailing_cells_emitted_when_wide_char_style_changes`:
			-- "你好，世界！" on blue replaced by "Hello" writes the right halves 5, 7, 9 and 11.
		local
			l_prev, l_next: BUFFER
			l_written: STRING_32
		do
			l_prev := row_with (12, wide_text, blue)
			l_next := row_with (12, "Hello", create {STYLE})
			l_written := written (diff (l_prev, l_next))
			assert ("column 5", l_written.has_substring ({STRING_32} " 5= "))
			assert ("column 7", l_written.has_substring ({STRING_32} " 7= "))
			assert ("column 9", l_written.has_substring ({STRING_32} " 9= "))
			assert ("column 11", l_written.has_substring ({STRING_32} " 11= "))
			assert ("screen", screen_after (l_prev, l_next).same_string ({STRING_32} "Hello       "))
		end

	test_partially_replaced_wide_chars_write_uncovered_cell
			-- Ratatui `uncovered_trailing_cells_emitted_when_wide_chars_partially_replaced`:
			-- column 7, the right half of "世", is written although both styles are blue.
		local
			l_prev, l_next: BUFFER
		do
			l_prev := row_with (12, wide_text, blue)
			l_next := row_with (12, {STRING_32} "%/0x55B5/%/0x545C/www", blue)
			assert ("column 7", written (diff (l_prev, l_next)).has_substring ({STRING_32} " 7= "))
		end

	test_shrinking_wide_glyph_clears_trailing_cell
			-- Ratatui `shrinking_wide_glyph_clears_trailing_cell` (#2585): "＋" on red, then a
			-- blank row: both columns are written.
		local
			l_prev, l_next: BUFFER
		do
			l_prev := row_with (2, {STRING_32} "%/0xFF0B/", red)
			create l_next.make (2, 1)
			assert ("both columns", written (diff (l_prev, l_next)).same_string ({STRING_32} " 0=  1= "))
		end

	test_wide_char_trailing_not_corrupted
			-- Ratatui `trailing_range_wide_char_trailing_not_corrupted`: "你好" to "a好" with "好"
			-- moved one column left. "好" is written at column 1 and no blank goes into its right
			-- half (column 2).
		local
			l_prev, l_next: BUFFER
			l_written: STRING_32
		do
			l_prev := row_with (4, {STRING_32} "%/0x4F60/%/0x597D/", blue)
			l_next := row_with (4, {STRING_32} "a%/0x597D/", blue)
			l_written := written (diff (l_prev, l_next))
			assert ("good at column 1", l_written.has_substring ({STRING_32} " 1=%/0x597D/"))
			assert ("nothing at column 2", not l_written.has_substring ({STRING_32} " 2="))
			assert ("screen", screen_after (l_prev, l_next).same_string ({STRING_32} "a%/0x597D/  "))
		end

	test_long_symbol_does_not_hide_later_cells
			-- Ratatui `long_symbol_does_not_hide_later_cells` (#2685): a one-column cell that
			-- holds 400 escape sequences; every changed cell after it is still written.
		local
			l_prev, l_next: BUFFER
		do
			l_prev := filled (20, 5, 'S')
			l_next := filled (20, 5, 'L')
			put_symbol (l_next, 0, 10, long_payload)
			assert ("every cell", written_count (diff (l_prev, l_next)) = 100)
			assert ("every L", written_l_count (diff (l_prev, l_next)) = 99)

			-- Ratatui `unchanged_long_symbol_does_not_hide_later_cells`. The unchanged cell sits
			-- in a merged gap, so it is written again; every changed cell after it is written.
			put_symbol (l_prev, 0, 10, long_payload)
			assert ("every L, unchanged payload", written_l_count (diff (l_prev, l_next)) = 99)
		end

feature -- X2b: style-only changes of wide glyphs

	test_wide_glyph_background_change_rewrites_glyph
			-- Ratatui `wide_glyph_style_change_clears_trailing_cell_before_repaint` (#2652): a
			-- wide glyph that loses its blue background is written again. The terminal paints
			-- both columns with it; nothing is written into its right half afterwards.
		local
			l_prev, l_next: BUFFER
			l_spans: ARRAYED_LIST [DIFF_SPAN]
		do
			l_prev := row_with (3, {STRING_32} "%/0xD55C/", blue)
			l_next := row_with (3, {STRING_32} "%/0xD55C/", create {STYLE})
			l_spans := diff (l_prev, l_next)
			assert ("the glyph only", written (l_spans).same_string ({STRING_32} " 0=%/0xD55C/"))
			assert ("no move into its right half", not rendered (l_spans).has_substring (csi + "1;2H"))
		end

	test_wide_glyph_style_change_resumes_after_repaint
			-- Ratatui `wide_glyph_style_change_resumes_after_repaint`: "한a" on blue to "한b" on
			-- red writes the glyph, then "b" in column 2 after an explicit move.
		local
			l_prev, l_next: BUFFER
			l_spans: ARRAYED_LIST [DIFF_SPAN]
		do
			l_prev := row_with (3, {STRING_32} "%/0xD55C/a", blue)
			l_next := row_with (3, {STRING_32} "%/0xD55C/b", red)
			l_spans := diff (l_prev, l_next)
			assert ("glyph and b", written (l_spans).same_string ({STRING_32} " 0=%/0xD55C/ 2=b"))
			assert ("b in column 2", rendered (l_spans).has_substring (utf_8 ({STRING_32} "%/0xD55C/") + csi + "1;3Hb"))
			assert ("screen", screen_after (l_prev, l_next).same_string ({STRING_32} "%/0xD55C/ b"))
		end

	test_wide_glyph_foreground_change_writes_glyph_only
			-- Ratatui `wide_glyph_foreground_change_does_not_clear_trailing_cell`.
		local
			l_prev, l_next: BUFFER
		do
			l_prev := row_with (3, {STRING_32} "%/0xD55C/", (create {STYLE}).with_fg ({COLOR}.blue))
			l_next := row_with (3, {STRING_32} "%/0xD55C/", (create {STYLE}).with_fg ({COLOR}.red))
			assert ("the glyph only", written (diff (l_prev, l_next)).same_string ({STRING_32} " 0=%/0xD55C/"))
		end

feature -- X2c: VS16 clusters

	test_vs16_cluster_is_two_columns_and_disputed
			-- The buffer gives "❤️" (U+2764 U+FE0F) two columns, and the serializer re-anchors
			-- after it.
		local
			l_buf: BUFFER
		do
			l_buf := row_with (4, heart, create {STYLE})
			assert ("two columns", l_buf.cell (0, 0).width = 2)
			assert ("continuation", l_buf.cell (0, 1).is_continuation)
			assert ("disputed", {ANSI_SERIALIZER}.is_width_disputed (l_buf.cell (0, 0)))
		end

	test_vs16_replacing_narrower_content_leaves_no_stale_column
			-- Ratatui `vs16_emoji_replacing_narrower_content_leaves_no_stale_column` (#2063), on a
			-- terminal that draws the cluster in one column: the reserved column is blank.
		do
			assert ("ab", screen_after (row_with (2, "ab", create {STYLE}), row_with (2, heart, create {STYLE})).same_string ({STRING_32} "%/0x2764/ "))
			assert ("abcd", screen_after (row_with (4, "abcd", create {STYLE}), row_with (4, heart + {STRING_32} "cd", create {STYLE})).same_string ({STRING_32} "%/0x2764/ cd"))
			assert ("ab..", screen_after (row_with (4, "abcd", create {STYLE}), row_with (4, {STRING_32} "ab" + heart, create {STYLE})).same_string ({STRING_32} "ab%/0x2764/ "))
		end

	test_vs16_row_replacing_ascii_does_not_drift
			-- Ratatui `vs16_emoji_replacing_ascii_does_not_drift` (#2357) on a one-column terminal.
		local
			l_hearts: STRING_32
			i: INTEGER
		do
			create l_hearts.make_empty
			from i := 1 until i > 6 loop
				l_hearts.append (heart)
				i := i + 1
			end
			assert ("hearts", screen_after (row_with (12, "int value8;;", create {STYLE}), row_with (12, l_hearts, create {STYLE})).same_string (
				{STRING_32} "%/0x2764/ %/0x2764/ %/0x2764/ %/0x2764/ %/0x2764/ %/0x2764/ "))
		end

	test_mixed_width_rows_do_not_drift
			-- Ratatui `mixed_width_rows_do_not_drift` on a one-column terminal.
		local
			l_mixed: STRING_32
		do
			l_mixed := {STRING_32} "a" + heart + {STRING_32} "b%/0x6F22/c%/0x1F600/d"
			assert ("ascii to mixed", screen_after (row_with (12, "int value8;;", create {STYLE}), row_with (12, l_mixed, create {STYLE})).same_string (
				{STRING_32} "a%/0x2764/ b%/0x6F22/ c%/0x1F600/ d  "))
			assert ("mixed to ascii", screen_after (row_with (12, l_mixed, create {STYLE}), row_with (12, "int value8;;", create {STYLE})).same_string (
				{STRING_32} "int value8;;"))
		end

	test_vs16_trailing_column_cleared_before_glyph
			-- On a terminal that draws the cluster in two columns, a write into its right half
			-- after the glyph would erase the glyph: anything written there comes first.
		local
			l_out: STRING_32
			l_glyph, l_move: INTEGER
		do
			l_out := rendered (diff (row_with (4, "abcd", create {STYLE}), row_with (4, heart + {STRING_32} "cd", create {STYLE})))
			l_glyph := l_out.substring_index (utf_8 (heart), 1)
			assert ("glyph written", l_glyph > 0)
			l_move := l_out.substring_index (csi + "1;2H", l_glyph)
			assert ("no write into the right half after the glyph", l_move = 0)
		end

feature {NONE} -- Helpers

	diff (a_prev, a_next: BUFFER): ARRAYED_LIST [DIFF_SPAN]
			-- Spans from `a_prev` to `a_next` (a new engine: the spans stay valid)
		do
			Result := (create {DIFF_ENGINE}).diff (a_prev, a_next)
		end

	written (a_spans: ARRAYED_LIST [DIFF_SPAN]): STRING_32
			-- " col=symbol" for every cell of row 0 that `a_spans` write (continuations are
			-- not written)
		local
			i: INTEGER
		do
			create Result.make_empty
			across a_spans as s loop
				from i := 1 until i > s.cells.count loop
					if s.row = 0 and not s.cells.i_th (i).is_continuation then
						Result.append_character (' ')
						Result.append_integer (s.start_col + i - 1)
						Result.append_character ('=')
						Result.append (s.cells.i_th (i).symbol)
					end
					i := i + 1
				end
			end
		end

	written_count (a_spans: ARRAYED_LIST [DIFF_SPAN]): INTEGER
			-- Number of cells (not continuations) that `a_spans` write
		do
			across a_spans as s loop
				across s.cells as c loop
					if not c.is_continuation then
						Result := Result + 1
					end
				end
			end
		end

	written_l_count (a_spans: ARRAYED_LIST [DIFF_SPAN]): INTEGER
			-- Number of "L" cells that `a_spans` write
		do
			across a_spans as s loop
				across s.cells as c loop
					if c.symbol.same_string ({STRING_32} "L") then
						Result := Result + 1
					end
				end
			end
		end

	rendered (a_spans: ARRAYED_LIST [DIFF_SPAN]): STRING_32
			-- Bytes (one character each) the serializer sends for `a_spans`
		local
			l_backend: ANSI_TERMINAL_BACKEND
		do
			create Result.make (128)
			create l_backend.make_with_driver_and_sink (create {FAKE_CONSOLE_DRIVER}, Result)
			(create {ANSI_SERIALIZER}).render_spans (a_spans, l_backend)
		end

	screen_after (a_prev, a_next: BUFFER): STRING_32
			-- Row 0 of a VIRTUAL_TERMINAL that showed `a_prev` (drawn over a blank screen) and
			-- was then updated to `a_next`
		local
			l_vt: VIRTUAL_TERMINAL
			l_serializer: ANSI_SERIALIZER
		do
			create l_vt.make (a_prev.width, 1)
			create l_serializer
			l_serializer.render_spans (diff (create {BUFFER}.make (a_prev.width, 1), a_prev), l_vt)
			l_serializer.render_spans (diff (a_prev, a_next), l_vt)
			Result := l_vt.line (0)
		end

	row_with (a_width: INTEGER; a_text: READABLE_STRING_GENERAL; a_style: STYLE): BUFFER
			-- One row of `a_width` columns with `a_text` from column 0
		do
			create Result.make (a_width, 1)
			Result.put_string (0, 0, a_text, a_style)
		end

	filled (a_width, a_height: INTEGER; a_char: CHARACTER_32): BUFFER
			-- Buffer filled with `a_char`
		do
			create Result.make (a_width, a_height)
			Result.fill (a_char, create {STYLE})
		end

	put_symbol (a_buffer: BUFFER; a_row, a_col: INTEGER; a_symbol: READABLE_STRING_GENERAL)
			-- Store `a_symbol` whole in one one-column cell (the buffer's writes drop escapes).
		do
			a_buffer.cell (a_row, a_col).set_symbol (a_symbol)
			a_buffer.cell (a_row, a_col).set_width (1)
		end

	long_payload: STRING_32
			-- 400 times ESC [ s
		local
			i: INTEGER
		do
			create Result.make (1200)
			from i := 1 until i > 400 loop
				Result.append ({STRING_32} "%/27/[s")
				i := i + 1
			end
		end

	wide_text: STRING_32
			-- "你好，世界！": six wide characters
		do
			Result := {STRING_32} "%/0x4F60/%/0x597D/%/0xFF0C/%/0x4E16/%/0x754C/%/0xFF01/"
		end

	heart: STRING_32
			-- U+2764 U+FE0F: a VS16 cluster
		do
			Result := {STRING_32} "%/0x2764/%/0xFE0F/"
		end

	blue: STYLE
			-- Blue background
		do
			Result := (create {STYLE}).with_bg ({COLOR}.blue)
		end

	red: STYLE
			-- Red background
		do
			Result := (create {STYLE}).with_bg ({COLOR}.red)
		end

	utf_8 (a_text: READABLE_STRING_32): STRING_32
			-- UTF-8 bytes of `a_text`, one character each (the form the sink holds)
		do
			Result := {UTF_CONVERTER}.string_32_to_utf_8_string_8 (a_text).to_string_32
		end

	csi: STRING_32
			-- Control Sequence Introducer
		do
			Result := {STRING_32} "%/27/["
		end

end
