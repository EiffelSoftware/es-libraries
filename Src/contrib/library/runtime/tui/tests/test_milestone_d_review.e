note
	description: "[
		Regression tests for the Milestone D review (2026-09-26). Each test failed on the code
		as first delivered for Milestone D:
		- horizontal clipping of spans that start left of the area (paragraph scroll_x)
		- BUFFER continuation consistency after put_char of zero-width chars, resize and merge
		- grapheme clusters (ZWJ emoji, flags, skin tones, combining marks, VS16) in BUFFER
		- Unicode width tables generated from the UCD
		- backend cursor tracking on UTF-8 byte strings and split/OSC/partial CSI sequences
		- in-place cell updates, shared style copies, buffer swap in TERMINAL
		- rendering-based style comparison, Reset color in patch, exact SGR deltas
		- RECT clamp / inner semantics
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_MILESTONE_D_REVIEW

inherit
	EQA_TEST_SET
	BUFFER_TEST_HELPER

feature -- Clipping

	test_paragraph_horizontal_scroll_clips_per_grapheme
			-- A line scrolled left of the area keeps its visible part; a wide character cut by the
			-- left edge leaves a blank.
		local
			l_buf: BUFFER
			l_p: TUI_PARAGRAPH
		do
			create l_buf.make (10, 1)
			create l_p.make_raw ("Hello World")
			l_p.set_scroll (2, 0)
			l_p.render (create {RECT}.make (0, 0, 10, 1), l_buf)
			assert_buffer_lines ("ascii scrolled", l_buf, <<"llo World ">>)

			create l_buf.make (6, 1)
			create l_p.make_raw ({STRING_32} "%/0x3042/%/0x3044/%/0x3046/")
			l_p.set_scroll (1, 0)
			l_p.render (create {RECT}.make (0, 0, 6, 1), l_buf)
			assert ("col 0 blank", l_buf.cell (0, 0).symbol.same_string ({STRING_32} " "))
			assert ("col 1 is i", l_buf.cell (0, 1).symbol.same_string ({STRING_32} "%/0x3044/"))
			assert ("col 3 is u", l_buf.cell (0, 3).symbol.same_string ({STRING_32} "%/0x3046/"))
			assert ("row consistent", l_buf.is_continuation_consistent (0))
		end

	test_set_line_clipped_negative_start
			-- `set_line_clipped` accepts a start column left of the buffer and honours both clip edges.
		local
			l_buf: BUFFER
			l_line: TEXT_LINE
			l_spans: ARRAYED_LIST [TEXT_SPAN]
		do
			create l_buf.make (8, 1)
			create l_spans.make (2)
			l_spans.extend (create {TEXT_SPAN}.make_raw ("abc"))
			l_spans.extend (create {TEXT_SPAN}.make_raw ("def"))
			create l_line.make (l_spans)
			l_buf.set_line_clipped (0, -2, l_line, create {STYLE}, 0, 3)
			assert_buffer_lines ("clipped both sides", l_buf, <<"cde     ">>)
		end

feature -- Buffer consistency

	test_put_char_zero_width_keeps_consistency
			-- Controls and combining marks passed to put_char leave the cells untouched.
		local
			l_buf: BUFFER
		do
			create l_buf.make (6, 1)
			l_buf.put_char (0, 0, (0x4E2D).to_character_32, create {STYLE})
			l_buf.put_char (0, 0, '%T', create {STYLE})
			l_buf.put_char (0, 1, (0x0301).to_character_32, create {STYLE})
			assert ("wide char kept", l_buf.cell (0, 0).width = 2 and l_buf.cell (0, 1).is_continuation)
			assert ("row consistent", l_buf.is_continuation_consistent (0))
		end

	test_resize_cuts_wide_char
			-- Shrinking through a wide character blanks it instead of leaving a half character.
		local
			l_buf: BUFFER
		do
			create l_buf.make (4, 1)
			l_buf.put_char (0, 2, (0x4E2D).to_character_32, create {STYLE})
			l_buf.resize (3, 1)
			assert ("consistent", l_buf.is_consistent)
			assert ("cut char blanked", l_buf.cell (0, 2).symbol.same_string ({STRING_32} " ") and l_buf.cell (0, 2).width = 1)
			l_buf.put_char (0, 0, 'x', create {STYLE})
			assert ("row still writable", l_buf.cell (0, 0).symbol.same_string ({STRING_32} "x"))
		end

	test_merge_repairs_cut_wide_char
			-- Merging over the left half of a wide character repairs its orphaned right half.
		local
			l_buf1, l_buf2: BUFFER
		do
			create l_buf1.make (6, 1)
			l_buf1.put_char (0, 3, (0x4E2D).to_character_32, create {STYLE})
			create l_buf2.make (4, 1)
			l_buf2.put_char (0, 3, 'x', create {STYLE})
			l_buf1.merge (l_buf2)
			assert ("x merged", l_buf1.cell (0, 3).symbol.same_string ({STRING_32} "x"))
			assert ("orphan repaired", not l_buf1.cell (0, 4).is_continuation)
			assert ("consistent", l_buf1.is_consistent)
		end

feature -- Grapheme clusters

	test_grapheme_clusters_in_buffer
			-- ZWJ sequences, flags, skin tones, combining marks and VS16 each occupy one cell cluster.
		local
			l_buf: BUFFER
			l_s: STRING_32
		do
			create l_buf.make (12, 1)
			create l_s.make_empty
			l_s.append_code (0x1F468); l_s.append_code (0x200D); l_s.append_code (0x1F469)
			l_s.append_code (0x200D); l_s.append_code (0x1F467)
			l_s.append_code (0x1F1FA); l_s.append_code (0x1F1F8)
			l_s.append_code (0x1F44D); l_s.append_code (0x1F3FD)
			l_s.append_code (0x65); l_s.append_code (0x0301)
			l_s.append_code (0x2764); l_s.append_code (0xFE0F)
			l_s.append_character ('!')
			l_buf.put_string (0, 0, l_s, create {STYLE})

			assert ("family is one wide cluster", l_buf.cell (0, 0).width = 2 and l_buf.cell (0, 0).symbol.count = 5)
			assert ("family continuation", l_buf.cell (0, 1).is_continuation)
			assert ("flag is one wide cluster", l_buf.cell (0, 2).width = 2 and l_buf.cell (0, 2).symbol.count = 2)
			assert ("skin tone joins its base", l_buf.cell (0, 4).width = 2 and l_buf.cell (0, 4).symbol.count = 2)
			assert ("combining mark joins its base", l_buf.cell (0, 6).width = 1 and l_buf.cell (0, 6).symbol.count = 2)
			assert ("VS16 makes a wide emoji", l_buf.cell (0, 7).width = 2 and l_buf.cell (0, 7).symbol.count = 2)
			assert ("next char right after", l_buf.cell (0, 9).symbol.same_string ({STRING_32} "!"))
			assert ("string_width agrees with placement", {UNICODE_WIDTH}.string_width (l_s) = 10)
			assert ("consistent", l_buf.is_consistent)
		end

	test_combining_mark_across_spans
			-- A combining mark starting a span attaches to the last character of the previous span.
		local
			l_buf: BUFFER
			l_line: TEXT_LINE
			l_spans: ARRAYED_LIST [TEXT_SPAN]
			l_mark: STRING_32
		do
			create l_buf.make (5, 1)
			create l_mark.make_empty
			l_mark.append_code (0x0301)
			l_mark.append_character ('x')
			create l_spans.make (2)
			l_spans.extend (create {TEXT_SPAN}.make_raw ("e"))
			l_spans.extend (create {TEXT_SPAN}.make_raw (l_mark))
			create l_line.make (l_spans)
			l_buf.set_line (0, 0, l_line, 5)
			assert ("accent attached", l_buf.cell (0, 0).symbol.count = 2)
			assert ("x at col 1", l_buf.cell (0, 1).symbol.same_string ({STRING_32} "x"))
		end

	test_unicode_tables_from_ucd
			-- Spot checks against the Unicode 16.0 data the tables are generated from.
		do
			assert ("thai vowel sign is zero width", {UNICODE_WIDTH}.width (0x0E31) = 0)
			assert ("hangul medial jamo is zero width", {UNICODE_WIDTH}.width (0x1160) = 0)
			assert ("combining acute is zero width", {UNICODE_WIDTH}.width (0x0301) = 0)
			assert ("soft hyphen is visible", {UNICODE_WIDTH}.width (0x00AD) = 1)
			assert ("ideographic space is wide", {UNICODE_WIDTH}.width (0x3000) = 2)
			assert ("CJK is wide", {UNICODE_WIDTH}.width (0x4E00) = 2)
			assert ("CJK ext B is wide", {UNICODE_WIDTH}.width (0x20000) = 2)
			assert ("emoji is wide", {UNICODE_WIDTH}.width (0x1F600) = 2)
			assert ("text-default heart is narrow", {UNICODE_WIDTH}.width (0x2764) = 1)
			assert ("thermometer (text default) is narrow", {UNICODE_WIDTH}.width (0x1F321) = 1)
			assert ("single regional indicator is narrow", {UNICODE_WIDTH}.width (0x1F1E6) = 1)
			assert ("latin is narrow", {UNICODE_WIDTH}.width (0x00E9) = 1)
		end

feature -- Backend cursor tracking

	test_backend_cursor_tracking_utf8_bytes
			-- The production path writes UTF-8 byte strings: the cursor must advance by display width.
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_sink: STRING_32
			l_backend: ANSI_TERMINAL_BACKEND
		do
			create l_driver.default_create
			create l_sink.make (128)
			create l_backend.make_with_driver_and_sink (l_driver, l_sink)
			l_backend.move_cursor (0, 0)
			l_backend.put_string ({UTF_CONVERTER}.string_32_to_utf_8_string_8 ({STRING_32} "%/0x3042/%/0xE9/"))
			assert ("wide + accented = 3 columns", l_backend.cursor_column = 3)

			l_backend.put_string ("%/27/]0;title%/7/")
			assert ("OSC does not move the cursor", l_backend.cursor_column = 3)

			l_backend.put_string ("%/27/[5H")
			assert ("row-only CSI H", l_backend.cursor_row = 4 and l_backend.cursor_column = 0)

			l_backend.put_string ("%/27/[")
			l_backend.put_string ("2;7H")
			assert ("sequence split across writes", l_backend.cursor_row = 1 and l_backend.cursor_column = 6)
		end

feature -- Allocation and ownership

	test_cells_updated_in_place_and_styles_shared
			-- Writing reuses the cell objects, equal styles share one private copy, and the
			-- caller's style object is never stored.
		local
			l_buf: BUFFER
			l_cell: TERMINAL_CELL
			l_st: STYLE
		do
			create l_buf.make (4, 1)
			create l_st.make_fg ({COLOR}.red)
			l_cell := l_buf.cell (0, 0)
			l_buf.put_string (0, 0, "ab", l_st)
			assert ("same cell object", l_buf.cell (0, 0) = l_cell)
			assert ("equal styles shared", l_buf.cell (0, 0).style = l_buf.cell (0, 1).style)
			assert ("caller style not stored", l_buf.cell (0, 0).style /= l_st)
			l_st := l_st.with_bold
			assert ("isolated from caller mutation", not l_buf.cell (0, 0).style.flags.is_bold)
			assert ("ascii symbols pooled", l_buf.cell (0, 0).symbol = {TERMINAL_CELL}.pooled_char (97))
		end

	test_terminal_swaps_buffers
			-- An unchanged frame produces no output after the buffers are swapped; a changed one does.
		local
			l_vt: VIRTUAL_TERMINAL
			l_term: TERMINAL [VIRTUAL_TERMINAL]
			l_first_current: BUFFER
		do
			create l_vt.make (20, 3)
			create l_term.make (l_vt)
			l_first_current := l_term.current_buffer
			l_term.draw (agent draw_label (?, "same"))
			assert ("buffers swapped", l_term.previous_buffer = l_first_current)
			l_vt.operations.wipe_out
			l_term.draw (agent draw_label (?, "same"))
			assert ("no output for unchanged frame", not across l_vt.operations as o some o.starts_with ("put_string") end)
			l_term.draw (agent draw_label (?, "diff"))
			assert ("changed frame drawn", l_vt.line (0).starts_with ("diff"))
		end

	test_diff_span_pool_reused
			-- The second diff reuses the span objects of the first.
		local
			l_b1, l_b2: BUFFER
			l_engine: DIFF_ENGINE
			l_first: DIFF_SPAN
		do
			create l_b1.make (10, 2)
			create l_b2.make (10, 2)
			create l_engine
			l_b2.put_string (0, 0, "a", create {STYLE})
			l_first := l_engine.diff (l_b1, l_b2).first
			l_b2.put_string (1, 0, "b", create {STYLE})
			assert ("pooled span reused", l_engine.diff (l_b1, l_b2).first = l_first)
		end

feature -- Style semantics

	test_style_same_rendering_and_reset
			-- Styles differing only in patch modifiers render the same; Reset clears a color in a patch.
		local
			l_a, l_b, l_base, l_patched: STYLE
			l_overlay: STYLE
		do
			create l_a
			create l_b
			l_b := l_b.without_modifier ({STYLE_FLAGS}.flag_bold)
			assert ("not is_equal (sub_modifier differs)", not l_a.is_equal (l_b))
			assert ("same rendering", l_a.same_rendering (l_b))

			create l_base.make_with_colors ({COLOR}.red, {COLOR}.blue)
			create l_overlay.make_bg ({COLOR}.reset_color)
			l_patched := l_base.patch (l_overlay)
			assert ("reset clears background", l_patched.background.is_default)
			assert ("foreground kept", l_patched.foreground.is_equal ({COLOR}.red))
			create l_overlay
			assert ("default overlay keeps background", l_base.patch (l_overlay).background.is_equal ({COLOR}.blue))
		end

	test_serializer_exact_sgr_deltas
			-- Only the changed attribute is emitted, and visually equal styles emit nothing.
		local
			l_prev, l_curr: BUFFER
			l_engine: DIFF_ENGINE
			l_serializer: ANSI_SERIALIZER
			l_sink: STRING_32
			l_backend: ANSI_TERMINAL_BACKEND
			l_st1, l_st2, l_plain: STYLE
		do
			create l_prev.make (10, 1)
			create l_curr.make (10, 1)
			create l_st1.make_fg ({COLOR}.red)
			l_st2 := l_st1.with_background ({COLOR}.blue)
			create l_plain
			l_plain := l_plain.without_modifier ({STYLE_FLAGS}.flag_bold)
			l_curr.put_string (0, 0, "A", l_st1)
			l_curr.put_string (0, 1, "B", l_st2)
			l_curr.put_string (0, 2, "C", create {STYLE})
			l_curr.put_string (0, 3, "D", l_plain)

			create l_engine
			create l_sink.make (256)
			create l_backend.make_with_driver_and_sink (create {FAKE_CONSOLE_DRIVER}, l_sink)
			create l_serializer
			l_serializer.render_spans (l_engine.diff (l_prev, l_curr), l_backend)
			assert ("red then A", l_sink.has_substring ("%/27/[31mA"))
			assert ("only background added before B", l_sink.has_substring ("A%/27/[44mB"))
			assert ("reset before C", l_sink.has_substring ("B%/27/[0mC"))
			assert ("no SGR between visually equal C and D", l_sink.has_substring ("CD"))
		end

feature -- RECT

	test_rect_clamp_moves_and_inner_does_not_wrap
			-- clamp moves the rectangle inside the bounds; inner with huge margins is empty.
		local
			l_r: RECT
		do
			l_r := (create {RECT}.make (8, 8, 4, 4)).clamp (create {RECT}.make (0, 0, 10, 10))
			assert ("moved to 6,6", l_r.x = 6 and l_r.y = 6)
			assert ("size kept", l_r.width = 4 and l_r.height = 4)
			l_r := (create {RECT}.make (0, 0, 20, 5)).clamp (create {RECT}.make (2, 1, 10, 10))
			assert ("shrunk to bounds", l_r.x = 2 and l_r.width = 10 and l_r.height = 5)
			l_r := (create {RECT}.make (0, 0, 20000, 10)).inner (40000, 0)
			assert ("huge margin gives empty rect", l_r.width = 0)
		end

feature {NONE} -- Helpers

	draw_label (a_frame: FRAME; a_text: STRING)
			-- Draw `a_text` on the first row.
		do
			a_frame.buffer.put_string (0, 0, a_text, create {STYLE})
		end

end
