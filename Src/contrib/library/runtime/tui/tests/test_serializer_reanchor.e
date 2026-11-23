note
	description: "[
		Cursor re-anchoring in ANSI_SERIALIZER (review finding U5): after a cell whose width a
		terminal may see differently (wide, or more than one code point), the next cell starts
		with an absolute cursor move, so the rest of the span lands in the buffer's columns.

		VIRTUAL_TERMINAL places text one code point at a time, like a terminal without ZWJ
		support: a ZWJ family takes 2 + 0 + 2 columns there, against 2 in the buffer.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_SERIALIZER_REANCHOR

inherit
	EQA_TEST_SET

feature -- Output bytes

	test_narrow_text_has_one_move
			-- Plain single-code-point narrow text costs one cursor move per span, as before.
		local
			l_out: STRING_32
		do
			l_out := rendered ("hello", 0, 0)
			assert ("one move", cursor_moves (l_out) = 1)
			assert ("text in one run", l_out.has_substring (csi + "1;1Hhello"))
		end

	test_move_after_wide_cell
			-- After a wide cell, the next cell is placed with a move to its own column.
		local
			l_out: STRING_32
		do
			l_out := rendered ({STRING_32} "%/0x65E5/x", 0, 0)
			assert ("move to column 3 before x", l_out.has_substring (utf_8 ({STRING_32} "%/0x65E5/") + csi + "1;3Hx"))
		end

	test_move_after_multi_code_point_cluster
			-- After a cluster of several code points (even a narrow one), the next cell is re-anchored.
		local
			l_out: STRING_32
		do
			l_out := rendered ({STRING_32} "e%/0x301/x", 0, 0)
			assert ("move to column 2 before x", l_out.has_substring (utf_8 ({STRING_32} "e%/0x301/") + csi + "1;2Hx"))
			l_out := rendered (family + "ab", 0, 0)
			assert ("move to column 3 before a", l_out.has_substring (utf_8 (family) + csi + "1;3Ha"))
			assert ("no move between a and b", l_out.has_substring ("Hab"))
		end

	test_no_move_after_last_cell
			-- A disputed cell at the end of a span adds no move.
		local
			l_out: STRING_32
		do
			l_out := rendered ({STRING_32} "ab%/0x65E5/", 0, 0)
			assert ("one move", cursor_moves (l_out) = 1)
		end

	test_moves_use_the_offset
			-- The re-anchoring move includes the viewport offset.
		local
			l_out: STRING_32
		do
			l_out := rendered ({STRING_32} "%/0x65E5/x", 5, 2)
			assert ("span start with offset", l_out.has_substring (csi + "3;6H"))
			assert ("re-anchor with offset", l_out.has_substring (utf_8 ({STRING_32} "%/0x65E5/") + csi + "3;8Hx"))
		end

feature -- Disagreeing terminal

	test_text_after_zwj_sequence_lands_in_place
			-- On a terminal that draws a ZWJ family 4 columns wide, the text after it still
			-- starts in the family's second column plus one, as in the buffer.
		local
			l_vt: VIRTUAL_TERMINAL
		do
			create l_vt.make (20, 2)
			draw (l_vt, blank_buffer, buffer_with (family + "xyz"))
			assert ("x in column 2", l_vt.line (0).item (3) = 'x')
			assert ("y in column 3", l_vt.line (0).item (4) = 'y')
			assert ("z in column 4", l_vt.line (0).item (5) = 'z')
		end

	test_diff_keeps_the_row_in_place
			-- A later frame that changes one cell after the disputed cluster lines up with the
			-- cells the first frame drew (before the fix, those stayed 2 columns to the right).
		local
			l_vt: VIRTUAL_TERMINAL
			l_first, l_second: BUFFER
		do
			create l_vt.make (20, 2)
			l_first := buffer_with (family + "xyz")
			l_second := buffer_with (family + "xyZ")
			draw (l_vt, blank_buffer, l_first)
			draw (l_vt, l_first, l_second)
			assert ("x unchanged", l_vt.line (0).item (3) = 'x')
			assert ("y unchanged", l_vt.line (0).item (4) = 'y')
			assert ("Z drawn after y", l_vt.line (0).item (5) = 'Z')
			assert ("nothing left further right", l_vt.line (0).item (6) = ' ' and l_vt.line (0).item (7) = ' ')
		end

feature -- Forced width (V8, CELL_DIFF_OPTION)

	test_move_after_forced_width_cell
			-- A cell with a forced width of n is followed at once by a move to its column + n,
			-- also when it ends its span; the backend's cursor is then there.
		local
			l_buf: BUFFER
			l_out: STRING_32
			l_backend: ANSI_TERMINAL_BACKEND
			l_link: STRING_32
		do
			l_link := osc_8 ("http://example.com", "ab")
			l_buf := blank_buffer
			put_symbol (l_buf, 0, 0, l_link)
			l_buf.set_diff_option (0, 0, {CELL_DIFF_OPTION}.Forced_width, 2)
			create l_out.make (64)
			create l_backend.make_with_driver_and_sink (create {FAKE_CONSOLE_DRIVER}, l_out)
			(create {ANSI_SERIALIZER}).render_spans ((create {DIFF_ENGINE}).diff (blank_buffer, l_buf), l_backend)
			assert ("move to column 3 after the link", l_out.has_substring (utf_8 (l_link) + csi + "1;3H"))
			assert ("backend cursor after the link", l_backend.cursor_row = 0 and l_backend.cursor_column = 2)

			-- A cell after the cover starts its own span
			l_buf.put_char (0, 2, 'c', create {STYLE})
			l_out.wipe_out;
			(create {ANSI_SERIALIZER}).render_spans ((create {DIFF_ENGINE}).diff (blank_buffer, l_buf), l_backend)
			assert ("c at column 3", l_out.has_substring (csi + "1;3Hc"))
			assert ("backend cursor after c", l_backend.cursor_column = 3)
		end

	test_cursor_after_forced_width_on_virtual_terminal
			-- A link whose text is 3 columns, forced to 2: the terminal draws 3 columns, and the
			-- cursor is put back at column 2, where the buffer's next cell is.
		local
			l_vt: VIRTUAL_TERMINAL
			l_first, l_second: BUFFER
		do
			create l_vt.make (20, 2)
			l_first := blank_buffer
			put_symbol (l_first, 0, 0, osc_8 ("http://example.com", "abc"))
			l_first.set_diff_option (0, 0, {CELL_DIFF_OPTION}.Forced_width, 2)
			draw (l_vt, blank_buffer, l_first)
			assert ("link text drawn", l_vt.line (0).substring (1, 3).same_string ("abc"))
			assert ("cursor at column 2", l_vt.cursor_row = 0 and l_vt.cursor_column = 2)

			l_second := blank_buffer
			put_symbol (l_second, 0, 0, osc_8 ("http://example.com", "abc"))
			l_second.set_diff_option (0, 0, {CELL_DIFF_OPTION}.Forced_width, 2)
			l_second.put_string (0, 2, "Z", create {STYLE})
			draw (l_vt, l_first, l_second)
			assert ("Z in column 2", l_vt.line (0).substring (1, 4).same_string ("abZ "))
		end

	test_hyperlink_cells_keep_their_columns
			-- EXAMPLE_HYPERLINK's pattern: each cell of "link" wrapped in its own OSC 8 link and
			-- forced to one column. The text lands in the buffer's columns.
		local
			l_vt: VIRTUAL_TERMINAL
			l_buf: BUFFER
			c: INTEGER
		do
			create l_vt.make (20, 1)
			l_buf := buffer_with ("   link!")
			from c := 3 until c > 6 loop
				put_symbol (l_buf, 0, c, osc_8 ("http://example.com", l_buf.cell (0, c).symbol))
				l_buf.set_diff_option (0, c, {CELL_DIFF_OPTION}.Forced_width, 1)
				c := c + 1
			end
			draw (l_vt, blank_buffer, l_buf)
			assert ("text in place", l_vt.line (0).substring (1, 9).same_string ("   link! "))
			draw (l_vt, l_buf, l_buf)
			assert ("unchanged frame keeps it", l_vt.line (0).substring (1, 9).same_string ("   link! "))
		end

	test_continuation_at_span_start
			-- When the left half of a wide character is skipped, a span can start with its
			-- continuation cell; the next cell is still placed in its own column.
		local
			l_buf: BUFFER
			l_out: STRING_32
		do
			l_buf := buffer_with ({STRING_32} "%/0x65E5/x")
			l_buf.set_diff_option (0, 0, {CELL_DIFF_OPTION}.Skip, 0)
			l_out := rendered_buffer (l_buf)
			assert ("span starts at the continuation", l_out.has_substring (csi + "1;2H"))
			assert ("x moved to column 3", l_out.has_substring (csi + "1;3Hx"))
			assert ("wide character not written", not l_out.has_substring (utf_8 ({STRING_32} "%/0x65E5/")))
		end

feature {NONE} -- Helpers

	osc_8 (a_url, a_text: READABLE_STRING_GENERAL): STRING_32
			-- `a_text` as an OSC 8 link to `a_url` (BEL terminators, as EXAMPLE_HYPERLINK writes)
		do
			Result := {STRING_32} "%/27/]8;;"
			Result.append_string_general (a_url)
			Result.append_character ((7).to_character_32)
			Result.append_string_general (a_text)
			Result.append ({STRING_32} "%/27/]8;;")
			Result.append_character ((7).to_character_32)
		end

	put_symbol (a_buffer: BUFFER; a_row, a_col: INTEGER; a_symbol: READABLE_STRING_GENERAL)
			-- Store `a_symbol` whole in one one-column cell (the buffer's writes drop escapes).
		do
			a_buffer.cell (a_row, a_col).set_symbol (a_symbol)
			a_buffer.cell (a_row, a_col).set_width (1)
		end

	rendered_buffer (a_buffer: BUFFER): STRING_32
			-- Bytes (one character each) sent for `a_buffer` drawn over a blank 20x1 buffer
		local
			l_backend: ANSI_TERMINAL_BACKEND
		do
			create Result.make (64)
			create l_backend.make_with_driver_and_sink (create {FAKE_CONSOLE_DRIVER}, Result)
			(create {ANSI_SERIALIZER}).render_spans ((create {DIFF_ENGINE}).diff (blank_buffer, a_buffer), l_backend)
		end

	family: STRING_32
			-- MAN ZWJ WOMAN: one 2-column cluster in the buffer
		do
			Result := {STRING_32} "%/0x1F468/%/0x200D/%/0x1F469/"
		end

	rendered (a_text: READABLE_STRING_GENERAL; a_offset_col, a_offset_row: INTEGER): STRING_32
			-- Bytes (one character each) sent for `a_text` drawn on a blank 20x1 buffer
		local
			l_backend: ANSI_TERMINAL_BACKEND
		do
			create Result.make (64)
			create l_backend.make_with_driver_and_sink (create {FAKE_CONSOLE_DRIVER}, Result)
			(create {ANSI_SERIALIZER}).render_spans_with_offset ((create {DIFF_ENGINE}).diff (blank_buffer, buffer_with (a_text)),
				l_backend, a_offset_col, a_offset_row)
		end

	draw (a_terminal: TERMINAL_BACKEND; a_previous, a_current: BUFFER)
			-- Serialize the difference between `a_previous` and `a_current` to `a_terminal`.
		do
			(create {ANSI_SERIALIZER}).render_spans ((create {DIFF_ENGINE}).diff (a_previous, a_current), a_terminal)
		end

	blank_buffer: BUFFER
			-- Blank 20x1 buffer
		do
			create Result.make (20, 1)
		end

	buffer_with (a_text: READABLE_STRING_GENERAL): BUFFER
			-- 20x1 buffer with `a_text` at the start of the row
		do
			Result := blank_buffer
			Result.put_string (0, 0, a_text, create {STYLE})
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

	cursor_moves (a_text: READABLE_STRING_32): INTEGER
			-- Number of cursor position sequences (`CSI digits;digits H`) in `a_text`
		local
			i, k: INTEGER
		do
			from
				i := a_text.substring_index (csi, 1)
			until
				i = 0
			loop
				from
					k := i + 2
				until
					k > a_text.count or else not (a_text.item (k).is_digit or a_text.item (k) = ';')
				loop
					k := k + 1
				end
				if k <= a_text.count and then a_text.item (k) = 'H' then
					Result := Result + 1
				end
				i := a_text.substring_index (csi, i + 1)
			end
		end

end
