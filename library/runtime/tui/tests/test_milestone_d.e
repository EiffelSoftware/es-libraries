note
	description: "[
		Unit tests for Milestone D:
		- Style value semantics, all 8 modifier setters, underline color, add/sub modifier patch, and fluent builders
		- Unicode UAX #11 width calculation, VS15/VS16, ZWJ sequences, and saturating string_width
		- Buffer wide-over-wide repair without orphan continuation cells, caller style at right boundary
		- Buffer API: area, resize, set_stringn, set_span, set_line, set_style, merge
		- RECT 65535 invariants, saturating constructors/offsets, and helpers (offset, clamp, centered, rows, cols, positions)
		- Synchronized output (?2026h/?2026l), frame accumulation in STRING_8, and minimal SGR deltas
		- Backend cursor tracking advancing by display width and ignoring escape bytes
		- Allocation reuse: DIFF_ENGINE span pooling and in-place buffer clearing
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_MILESTONE_D

inherit
	EQA_TEST_SET
	BUFFER_TEST_HELPER

feature -- Tests

	test_style_modifiers_and_fluent_builders
			-- Test all 8 modifiers, underline color, remove_modifier, and patch logic.
		local
			l_s1, l_s2, l_patched: STYLE
			l_cell: TERMINAL_CELL
		do
			create l_s1.default_create
			-- Set all 8 modifier flags using fluent builders
			l_s1 := l_s1.with_bold
				.with_dim
				.with_italic
				.with_underline
				.with_blink
				.with_reverse
				.with_hidden
				.with_strikethrough
				.with_underline_color ({COLOR}.cyan)

			assert ("is bold", l_s1.flags.is_bold)
			assert ("is dim", l_s1.flags.is_dim)
			assert ("is italic", l_s1.flags.is_italic)
			assert ("is underline", l_s1.flags.is_underline)
			assert ("is blink", l_s1.flags.is_blink)
			assert ("is reverse", l_s1.flags.is_reverse)
			assert ("is hidden", l_s1.flags.is_hidden)
			assert ("is strikethrough", l_s1.flags.is_strikethrough)
			assert ("underline color is cyan", l_s1.underline_color.is_equal ({COLOR}.cyan))
			assert ("sgr contains underline color 58;5", l_s1.sgr_sequence.has_substring ("58;5;6"))

			-- Remove a modifier
			l_s1 := l_s1.without_modifier ({STYLE_FLAGS}.flag_dim)
			assert ("dim removed", not l_s1.flags.is_dim)
			assert ("sub_modifier has dim", l_s1.sub_modifier.has_flag ({STYLE_FLAGS}.flag_dim))

			-- Fluent builders
			create l_s2.default_create
			l_s2 := l_s2.with_foreground ({COLOR}.red).with_background ({COLOR}.blue).with_bold.with_italic
			assert ("builder fg red", l_s2.foreground.is_equal ({COLOR}.red))
			assert ("builder bg blue", l_s2.background.is_equal ({COLOR}.blue))
			assert ("builder bold", l_s2.flags.is_bold)
			assert ("builder italic", l_s2.flags.is_italic)

			-- Patch with sub_modifier removal: l_s1 has dim in sub_modifier, patching over a style with dim should remove dim!
			create l_s2.default_create
			l_s2 := l_s2.with_dim
			l_patched := l_s2.patch (l_s1)
			assert ("patched removed dim", not l_patched.flags.is_dim)
			assert ("patched kept bold", l_patched.flags.is_bold)

			-- Cell style isolation: immutable styles are safe to share
			create l_cell.default_create
			l_cell.set_style (l_s2)
			l_s2 := l_s2.with_bold
			assert ("cell style isolated from caller mutation", not l_cell.style.flags.is_bold)
		end

	test_unicode_width_uax11_and_graphemes
			-- Test display width calculations, VS15/VS16, ZWJ, combining marks, and saturating string_width.
		local
			l_uw: UNICODE_WIDTH
			l_combining: STRING_32
			l_vs16_str, l_vs15_str: STRING_32
			l_zwj_str: STRING_32
			l_large_str: STRING_32
			i: INTEGER
		do
			create l_uw

			-- Combining mark alone is width 0
			assert ("combining acute width 0", l_uw.width (769) = 0) -- U+0301 Combining Acute Accent

			-- Grapheme with combining mark
			create l_combining.make (2)
			l_combining.append_character ('e')
			l_combining.append_character ((769).to_character_32)
			assert ("e with acute grapheme width 1", l_uw.grapheme_width (l_combining) = 1)

			-- VS16 on text symbol promotes to width 2 (Emoji Presentation)
			create l_vs16_str.make (2)
			l_vs16_str.append_character ((9749).to_character_32) -- U+2615 Hot Beverage
			l_vs16_str.append_character ((65039).to_character_32) -- U+FE0F VS16
			assert ("hot beverage with vs16 is width 2", l_uw.grapheme_width (l_vs16_str) = 2)

			-- VS15 on emoji forces width 1 (Text Presentation)
			create l_vs15_str.make (2)
			l_vs15_str.append_character ((9749).to_character_32)
			l_vs15_str.append_character ((65038).to_character_32) -- U+FE0E VS15
			assert ("hot beverage with vs15 is width 1", l_uw.grapheme_width (l_vs15_str) = 1)

			-- ZWJ sequence renders as single 2-column emoji
			create l_zwj_str.make (3)
			l_zwj_str.append_character ((128104).to_character_32) -- U+1F468 Man
			l_zwj_str.append_character ((8205).to_character_32) -- U+200D ZWJ
			l_zwj_str.append_character ((128187).to_character_32) -- U+1F4BB Laptop
			assert ("man technologist zwj width 2", l_uw.grapheme_width (l_zwj_str) = 2)

			-- Saturating string_width: prevents NATURAL_16 overflow (> 65535)
			create l_large_str.make (70000)
			from
				i := 1
			until
				i > 70000
			loop
				l_large_str.append_character ('A')
				i := i + 1
			end
			assert ("string_width saturated at 65535", l_uw.string_width (l_large_str) = 65535)
		end

	test_buffer_wide_over_wide_repair
			-- Test wide-over-wide buffer overwrite repairs leaving NO orphan continuations,
			-- and caller style at right boundary.
		local
			l_buf: BUFFER
			l_st: STYLE
		do
			create l_buf.make (8, 2)
			create l_st.make_fg ({COLOR}.yellow)

			-- Place wide char at col 1 (occupies 1 and 2)
			l_buf.put_char (0, 1, (12354).to_character_32, l_st) -- 'あ'
			assert ("col 1 is wide", l_buf.cell (0, 1).width = 2)
			assert ("col 2 is continuation", l_buf.cell (0, 2).is_continuation)

			-- Place wide char at col 0 (occupies 0 and 1)
			-- Col 1 becomes continuation of col 0. Col 2 (continuation of old col 1) MUST be repaired!
			l_buf.put_char (0, 0, (12356).to_character_32, l_st) -- 'い'
			assert ("col 0 is wide", l_buf.cell (0, 0).width = 2)
			assert ("col 1 is continuation", l_buf.cell (0, 1).is_continuation)
			assert ("col 2 repaired (not orphan continuation)", not l_buf.cell (0, 2).is_continuation)
			assert ("col 2 is space", l_buf.cell (0, 2).symbol.is_equal ({STRING_32} " "))
			assert ("row 0 consistent", l_buf.is_continuation_consistent (0))

			-- Place wide char at right boundary (col 7 on width 8): cannot fit
			-- Must be blanked using caller's style!
			l_buf.put_char (0, 7, (12358).to_character_32, l_st)
			assert ("col 7 blanked to space", l_buf.cell (0, 7).symbol.is_equal ({STRING_32} " "))
			assert ("col 7 has caller style", l_buf.cell (0, 7).style.foreground.is_equal ({COLOR}.yellow))
			assert ("row 0 consistent after boundary test", l_buf.is_continuation_consistent (0))
		end

	test_buffer_api_extensions
			-- Test area, resize, set_stringn, set_span, set_line, set_style, merge.
		local
			l_buf1, l_buf2: BUFFER
			l_st: STYLE
			l_span: TEXT_SPAN
			l_line: TEXT_LINE
		do
			create l_buf1.make (10, 4)
			create l_st.make_fg ({COLOR}.green)

			-- 1. area
			assert ("area origin 0,0", l_buf1.area.x = 0 and l_buf1.area.y = 0)
			assert ("area size 10x4", l_buf1.area.width = 10 and l_buf1.area.height = 4)

			-- 2. set_stringn with clipping
			l_buf1.set_stringn (0, 2, "ABCDEF", 3, l_st)
			assert ("col 2 is A", l_buf1.cell (0, 2).symbol.is_equal ({STRING_32} "A"))
			assert ("col 3 is B", l_buf1.cell (0, 3).symbol.is_equal ({STRING_32} "B"))
			assert ("col 4 is C", l_buf1.cell (0, 4).symbol.is_equal ({STRING_32} "C"))
			assert ("col 5 still space", l_buf1.cell (0, 5).symbol.is_equal ({STRING_32} " "))

			-- 3. set_span and set_line
			create l_span.make ("Hello", l_st)
			l_buf1.set_span (1, 0, l_span, 5)
			assert ("row 1 starts with Hello", l_buf1.line (1).starts_with ({STRING_32} "Hello"))

			create l_line.make_styled ("World", l_st)
			l_buf1.set_line (2, 0, l_line, 5)
			assert ("row 2 starts with World", l_buf1.line (2).starts_with ({STRING_32} "World"))

			-- 4. set_style
			l_buf1.set_style (create {RECT}.make (0, 0, 5, 2), create {STYLE}.make_fg ({COLOR}.red))
			assert ("row 0 col 2 style patched to red", l_buf1.cell (0, 2).style.foreground.is_equal ({COLOR}.red))

			-- 5. resize
			l_buf1.resize (15, 6)
			assert ("new width 15", l_buf1.width = 15)
			assert ("new height 6", l_buf1.height = 6)
			assert ("preserved content row 1", l_buf1.line (1).starts_with ({STRING_32} "Hello"))

			-- 6. merge
			create l_buf2.make (15, 6)
			l_buf2.put_string (3, 0, "MergeTest", l_st)
			l_buf1.merge (l_buf2)
			assert ("merged row 3 has MergeTest", l_buf1.line (3).starts_with ({STRING_32} "MergeTest"))
		end

	test_rect_saturating_bounds_and_helpers
			-- Test RECT invariants, saturating arithmetic, and helper queries.
		local
			l_r: RECT
			l_centered, l_offset: RECT
			l_rows, l_cols: ARRAYED_LIST [RECT]
			l_pos: ARRAYED_LIST [TUPLE [x, y: NATURAL_16]]
		do
			-- Saturating constructor prevents overflow beyond 65535
			create l_r.make (65500, 65500, 100, 100)
			assert ("width saturated", l_r.width = 35)
			assert ("height saturated", l_r.height = 35)
			assert ("right is 65535", l_r.right = 65535)
			assert ("bottom is 65535", l_r.bottom = 65535)

			-- Centered
			create l_r.make (0, 0, 20, 10)
			l_centered := l_r.centered (10, 4)
			assert ("centered x is 5", l_centered.x = 5)
			assert ("centered y is 3", l_centered.y = 3)
			assert ("centered width is 10", l_centered.width = 10)
			assert ("centered height is 4", l_centered.height = 4)

			-- Offset
			l_offset := l_centered.offset (2, -1)
			assert ("offset x is 7", l_offset.x = 7)
			assert ("offset y is 2", l_offset.y = 2)

			-- Rows and Columns
			create l_r.make (2, 4, 3, 2)
			l_rows := l_r.rows
			assert ("2 row strips", l_rows.count = 2)
			assert ("first row y is 4", l_rows.first.y = 4 and l_rows.first.height = 1)
			assert ("second row y is 5", l_rows.i_th (2).y = 5 and l_rows.i_th (2).height = 1)

			l_cols := l_r.columns
			assert ("3 column strips", l_cols.count = 3)
			assert ("first col x is 2", l_cols.first.x = 2 and l_cols.first.width = 1)

			-- Positions
			l_pos := l_r.positions
			assert ("6 positions in 3x2 rect", l_pos.count = 6)
			assert ("first pos is 2,4", l_pos.first.x = 2 and l_pos.first.y = 4)
		end

	test_synchronized_output_and_minimal_sgr
			-- Test ANSI_SERIALIZER synchronized output (?2026) and minimal SGR deltas.
		local
			l_prev, l_curr: BUFFER
			l_engine: DIFF_ENGINE
			l_serializer: ANSI_SERIALIZER
			l_driver: FAKE_CONSOLE_DRIVER
			l_sink: STRING_32
			l_backend: ANSI_TERMINAL_BACKEND
			l_spans: ARRAYED_LIST [DIFF_SPAN]
			l_st1, l_st2: STYLE
		do
			create l_prev.make (20, 3)
			create l_curr.make (20, 3)
			create l_st1.make_fg ({COLOR}.red)
			create l_st2.make_fg ({COLOR}.red)
			l_st2 := l_st2.with_background ({COLOR}.blue)

			l_curr.put_string (0, 0, "A", l_st1)
			l_curr.put_string (0, 1, "B", l_st2)

			create l_engine
			l_spans := l_engine.diff (l_prev, l_curr)

			create l_driver.default_create
			create l_sink.make (256)
			create l_backend.make_with_driver_and_sink (l_driver, l_sink)

			create l_serializer
			l_serializer.render_spans (l_spans, l_backend)

			-- Verify synchronized update wrapper ?2026h and ?2026l
			assert ("contains sync start ?2026h", l_sink.has_substring ("%/27/[?2026h"))
			assert ("contains sync end ?2026l", l_sink.has_substring ("%/27/[?2026l"))
			-- Verify explicit reset at frame start
			assert ("contains reset at start", l_sink.has_substring ("%/27/[0m"))
			-- Verify characters rendered
			assert ("contains A and B", l_sink.has_substring ("A") and l_sink.has_substring ("B"))
			-- Minimal delta: only the added background is emitted between A and B
			assert ("minimal delta before B", l_sink.has_substring ("A%/27/[44mB"))
		end

	test_backend_cursor_tracking_and_escapes
			-- Test cursor tracking advancing by display width and ignoring ANSI escape sequences.
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_sink: STRING_32
			l_backend: ANSI_TERMINAL_BACKEND
			l_vt: VIRTUAL_TERMINAL
		do
			create l_driver.default_create
			create l_sink.make (128)
			create l_backend.make_with_driver_and_sink (l_driver, l_sink)
			l_backend.move_cursor (0, 0)
			assert ("initial col 0", l_backend.cursor_column = 0)

			-- Write escape sequence: must NOT advance cursor column
			l_backend.put_string ("%/27/[31;1m")
			assert ("escapes do not advance cursor", l_backend.cursor_column = 0)

			-- Write ASCII character: advances by 1
			l_backend.put_string ("A")
			assert ("ascii advances by 1", l_backend.cursor_column = 1)

			-- Write CJK wide character (U+3042 'あ') as UTF-8 bytes, as the serializer does: advances by 2
			l_backend.put_string ({UTF_CONVERTER}.string_32_to_utf_8_string_8 ({STRING_32} "%/0x3042/"))
			assert ("wide char advances by 2", l_backend.cursor_column = 3)

			-- VIRTUAL_TERMINAL cursor positioning via CSI sequence inside put_string
			create l_vt.make (20, 5)
			l_vt.put_string ("%/27/[3;8HX")
			assert ("vt cursor moved to row 2", l_vt.cursor_row = 2)
			assert ("vt cursor cell placed at col 7", l_vt.cell (2, 7) = 'X')
			assert ("vt cursor advanced to col 8", l_vt.cursor_column = 8)
		end

	test_allocation_reuse
			-- Test DIFF_ENGINE span pooling and in-place BUFFER.clear.
		local
			l_b1, l_b2: BUFFER
			l_engine: DIFF_ENGINE
			l_spans1, l_spans2: ARRAYED_LIST [DIFF_SPAN]
			l_st: STYLE
		do
			create l_b1.make (20, 5)
			create l_b2.make (20, 5)
			create l_st.default_create
			create l_engine

			l_b2.put_string (0, 0, "Test1", l_st)
			l_spans1 := l_engine.diff (l_b1, l_b2)
			assert ("first diff has 1 span", l_spans1.count = 1)

			l_b2.clear
			l_b2.put_string (1, 0, "Test2", l_st)
			l_spans2 := l_engine.diff (l_b1, l_b2)
			assert ("second diff has 1 span", l_spans2.count = 1)
			assert ("second diff row is 1", l_spans2.first.row = 1)
			assert ("span object reused from the pool", l_spans2.first = l_spans1.first)
		end

end
