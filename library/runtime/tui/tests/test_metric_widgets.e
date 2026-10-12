note
	description: "[
		Autotest test set for Phase 9: TUI_GAUGE, TUI_LINE_GAUGE, TUI_SPARKLINE, and TUI_BARCHART.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_METRIC_WIDGETS

inherit
	EQA_TEST_SET

feature -- Test routines

	test_gauge_rendering_and_label
			-- Test TUI_GAUGE progress calculation and centered label rendering.
		local
			l_gauge: TUI_GAUGE
			l_buf: BUFFER
			l_area: RECT
		do
			create l_gauge.make
			l_gauge.set_percent (50)
			assert ("percent is 50", l_gauge.percent = 50)
			assert ("ratio is 0.5", l_gauge.ratio = 0.5)

			create l_buf.make (20, 3)
			create l_area.make (0, 0, 20, 3)

			l_gauge.render (l_area, l_buf)

			-- First cell (0, 0) should be full block '█' (code 9608)
			assert ("first cell filled", l_buf.cell (0, 0).symbol.code (1) = 9608)
			-- Cell at col 9 should be filled
			assert ("col 9 filled", l_buf.cell (0, 9).symbol.code (1) = 9608)
			-- Middle row (row 1) has centered label "50%"
			-- 20 width, "50%" has width 3 -> start col = (20 - 3) // 2 = 8
			assert ("label char 5", l_buf.cell (1, 8).symbol.same_string_general ("5"))
			assert ("label char 0", l_buf.cell (1, 9).symbol.same_string_general ("0"))
			assert ("label char %%", l_buf.cell (1, 10).symbol.same_string_general ("%%"))
		end

	test_gauge_unicode_sub_cell
			-- Test TUI_GAUGE with Unicode sub-cell block fractions enabled.
		local
			l_gauge: TUI_GAUGE
			l_buf: BUFFER
			l_area: RECT
		do
			create l_gauge.make
			l_gauge.set_use_unicode (True)
			l_gauge.set_label ("")
			-- 10 width, ratio 0.25 => filled_f = 2.5 => full_cells = 2, frac = 0.5 (half block '▌' code 9612)
			l_gauge.set_ratio (0.25)

			create l_buf.make (10, 1)
			create l_area.make (0, 0, 10, 1)

			l_gauge.render (l_area, l_buf)

			assert ("col 0 full block", l_buf.cell (0, 0).symbol.code (1) = 9608)
			assert ("col 1 full block", l_buf.cell (0, 1).symbol.code (1) = 9608)
			-- Sub-cell fraction at col 2: 0.5 fraction => 4/8 => '▌' (code 9612)
			assert ("col 2 half block", l_buf.cell (0, 2).symbol.code (1) = 9612)
			-- Remainder unfilled spaces
			assert ("col 3 space", l_buf.cell (0, 3).symbol.same_string_general (" "))
		end

	test_line_gauge_rendering
			-- Test TUI_LINE_GAUGE single-line rendering.
		local
			l_gauge: TUI_LINE_GAUGE
			l_buf: BUFFER
			l_area: RECT
		do
			create l_gauge.make
			l_gauge.set_percent (50)

			create l_buf.make (20, 1)
			create l_area.make (0, 0, 20, 1)

			l_gauge.render (l_area, l_buf)

			-- Left label "50% "
			assert ("label 5", l_buf.cell (0, 0).symbol.same_string_general ("5"))
			assert ("label 0", l_buf.cell (0, 1).symbol.same_string_general ("0"))
			assert ("label %%", l_buf.cell (0, 2).symbol.same_string_general ("%%"))
			assert ("space separator", l_buf.cell (0, 3).symbol.same_string_general (" "))

			-- Line starts at col 4, remaining width 16 cells => 8 filled ('━' code 9473) and 8 unfilled ('─' code 9472)
			assert ("filled line char", l_buf.cell (0, 4).symbol.code (1) = 9473)
			assert ("unfilled line char", l_buf.cell (0, 19).symbol.code (1) = 9472)
		end

	test_sparkline_rendering
			-- Test TUI_SPARKLINE trend calculation and multi-level vertical bar glyphs.
		local
			l_spark: TUI_SPARKLINE
			l_buf: BUFFER
			l_area: RECT
		do
			create l_spark.make_with_data (<<{NATURAL_64} 10, {NATURAL_64} 20, {NATURAL_64} 30, {NATURAL_64} 40>>)
			l_spark.set_max_value (40)

			create l_buf.make (4, 1)
			create l_area.make (0, 0, 4, 1)

			l_spark.render (l_area, l_buf)

			-- Height 1 => 8 levels
			-- Col 0: 10 / 40 * 8 = 2 => '▂' (code 9602)
			assert ("col 0 level 2", l_buf.cell (0, 0).symbol.code (1) = 9602)
			-- Col 1: 20 / 40 * 8 = 4 => '▄' (code 9604)
			assert ("col 1 level 4", l_buf.cell (0, 1).symbol.code (1) = 9604)
			-- Col 2: 30 / 40 * 8 = 6 => '▆' (code 9606)
			assert ("col 2 level 6", l_buf.cell (0, 2).symbol.code (1) = 9606)
			-- Col 3: 40 / 40 * 8 = 8 => '█' (code 9608)
			assert ("col 3 level 8", l_buf.cell (0, 3).symbol.code (1) = 9608)
		end

	test_barchart_rendering
			-- Test TUI_BARCHART columns, values, and labels rendering.
		local
			l_chart: TUI_BARCHART
			l_b1, l_b2: BAR_ITEM
			l_buf: BUFFER
			l_area: RECT
		do
			create l_b1.make ("CPU", 100)
			create l_b2.make ("MEM", 50)

			create l_chart.make_with_data (<<l_b1, l_b2>>)
			l_chart.set_bar_width (3)
			l_chart.set_bar_gap (1)
			l_chart.set_max_value (100)

			create l_buf.make (15, 4)
			create l_area.make (0, 0, 15, 4)

			l_chart.render (l_area, l_buf)

			-- Row layout with height 4:
			-- Row 0..1: Bars (height 2)
			-- Row 2: Values ("100", "50")
			-- Row 3: Labels ("CPU", "MEM")

			-- Bar 1 (CPU = 100%): Top of bar at row 0 is full block '█' (code 9608)
			assert ("bar1 row 0 full block", l_buf.cell (0, 0).symbol.code (1) = 9608)
			assert ("bar1 row 1 full block", l_buf.cell (1, 0).symbol.code (1) = 9608)

			-- Bar 1 Value at row 2: "100"
			assert ("bar1 val 1", l_buf.cell (2, 0).symbol.same_string_general ("1"))
			assert ("bar1 val 0", l_buf.cell (2, 1).symbol.same_string_general ("0"))
			assert ("bar1 val 0", l_buf.cell (2, 2).symbol.same_string_general ("0"))

			-- Bar 1 Label at row 3: "CPU"
			assert ("bar1 label C", l_buf.cell (3, 0).symbol.same_string_general ("C"))
			assert ("bar1 label P", l_buf.cell (3, 1).symbol.same_string_general ("P"))
			assert ("bar1 label U", l_buf.cell (3, 2).symbol.same_string_general ("U"))

			-- Bar 2 (MEM = 50%): Starts at col 4 (width 3 + gap 1 = 4)
			-- Row 0: empty space
			assert ("bar2 row 0 empty", l_buf.cell (0, 4).symbol.same_string_general (" "))
			-- Row 1: full block '█'
			assert ("bar2 row 1 full block", l_buf.cell (1, 4).symbol.code (1) = 9608)
			-- Row 3: Label "MEM"
			assert ("bar2 label M", l_buf.cell (3, 4).symbol.same_string_general ("M"))
			assert ("bar2 label E", l_buf.cell (3, 5).symbol.same_string_general ("E"))
			assert ("bar2 label M", l_buf.cell (3, 6).symbol.same_string_general ("M"))
		end


feature -- Wide labels and one-column symbols (review finding U7)

	test_gauge_label_wide_char_across_fill_edge
			-- A wide label character straddling the fill edge is drawn whole, in the style of
			-- its first column (it used to disappear).
		local
			l_gauge: TUI_GAUGE
			l_buf: BUFFER
		do
			create l_gauge.make
			l_gauge.set_percent (50)
			l_gauge.set_gauge_style (create {STYLE}.make_fg ({COLOR}.green))
			l_gauge.set_label ({STRING_32} "a%/0x65E5/b")
			create l_buf.make (6, 1)
			-- 3 filled cells (columns 0..2); label of width 4 centred at column 1
			l_gauge.render (l_buf.area, l_buf)
			assert ("a at column 1", l_buf.cell (0, 1).symbol.same_string ("a"))
			assert ("wide character at column 2", l_buf.cell (0, 2).symbol.same_string ({STRING_32} "%/0x65E5/"))
			assert ("its second half at column 3", l_buf.cell (0, 3).is_continuation)
			assert ("b at column 4", l_buf.cell (0, 4).symbol.same_string ("b"))
			assert ("a over the fill", l_buf.cell (0, 1).style.background.is_equal ({COLOR}.green))
			assert ("wide character over the fill", l_buf.cell (0, 2).style.background.is_equal ({COLOR}.green))
			assert ("b outside the fill", l_buf.cell (0, 4).style.background.is_default)
			assert ("consistent", l_buf.is_consistent)
		end

	test_gauge_label_wide_char_after_fill_edge
			-- A wide label character that starts at the fill edge is drawn whole, unfilled.
		local
			l_gauge: TUI_GAUGE
			l_buf: BUFFER
		do
			create l_gauge.make
			l_gauge.set_percent (50)
			l_gauge.set_gauge_style (create {STYLE}.make_fg ({COLOR}.green))
			l_gauge.set_label ({STRING_32} "ab%/0x65E5/")
			create l_buf.make (6, 1)
			-- 3 filled cells; label of width 4 at column 1: the wide character takes 3..4
			l_gauge.render (l_buf.area, l_buf)
			assert ("wide character at column 3", l_buf.cell (0, 3).symbol.same_string ({STRING_32} "%/0x65E5/"))
			assert ("b over the fill", l_buf.cell (0, 2).style.background.is_equal ({COLOR}.green))
			assert ("wide character outside the fill", l_buf.cell (0, 3).style.background.is_default)
		end

	test_one_column_symbols
			-- {TERMINAL_CELL}.is_one_column_symbol: one grapheme cluster, one column wide, or empty.
		do
			assert ("thick line", {TERMINAL_CELL}.is_one_column_symbol ({STRING_32} "%/0x2501/"))
			assert ("letter with a mark", {TERMINAL_CELL}.is_one_column_symbol ({STRING_32} "=%/0x332/"))
			assert ("empty", {TERMINAL_CELL}.is_one_column_symbol (""))
			assert ("wide emoji", not {TERMINAL_CELL}.is_one_column_symbol ({STRING_32} "%/0x1F7E9/"))
			assert ("two characters", not {TERMINAL_CELL}.is_one_column_symbol ("=>"))
			assert ("scrollbar uses the same rule", {TUI_SCROLLBAR}.is_valid_symbol ("=>") = {TERMINAL_CELL}.is_one_column_symbol ("=>"))
		end

	test_line_gauge_refuses_wide_symbols
			-- The line gauge symbol setters refuse symbols wider than one column.
		local
			l_gauge: TUI_LINE_GAUGE
		do
			create l_gauge.make
			assert ("wide filled", precondition_raised (agent l_gauge.set_filled_symbol ({STRING_32} "%/0x1F7E9/")))
			assert ("two-character filled", precondition_raised (agent l_gauge.set_filled_symbol ("=>")))
			assert ("wide unfilled", precondition_raised (agent l_gauge.set_unfilled_symbol ({STRING_32} "%/0x2B1C/")))
			assert ("symbols unchanged", l_gauge.filled_symbol.same_string ({STRING_32} "%/0x2501/")
				and l_gauge.unfilled_symbol.same_string ({STRING_32} "%/0x2500/"))
		end

	test_line_gauge_invariant_catches_edited_symbol
			-- Widening the public symbol string in place breaks the invariant, caught on the next call.
		local
			l_gauge: TUI_LINE_GAUGE
			l_raised, l_retried: BOOLEAN
		do
			if not l_retried then
				create l_gauge.make
				l_gauge.filled_symbol.append (">")
				l_gauge.render (create {RECT}.make (0, 0, 10, 1), create {BUFFER}.make (10, 1))
			end
			assert ("invariant violated", l_raised)
		rescue
			if not l_retried then
				l_retried := True
				l_raised := attached (create {EXCEPTION_MANAGER}).last_exception as e and then
					(attached {INVARIANT_VIOLATION} e.original as v and then
					(attached v.description as d and then d.same_string ("one_column_filled")))
				retry
			end
		end

	test_line_gauge_multi_code_point_symbol_in_every_cell
			-- A one-column symbol of several code points fills every cell of the line whole.
		local
			l_gauge: TUI_LINE_GAUGE
			l_buf: BUFFER
			c: INTEGER
		do
			create l_gauge.make
			l_gauge.set_label ("")
			l_gauge.set_percent (100)
			l_gauge.set_filled_symbol ({STRING_32} "=%/0x332/")
			create l_buf.make (8, 1)
			l_gauge.render (l_buf.area, l_buf)
			from c := 1 until c >= 8 loop
				assert ("cell " + c.out, l_buf.cell (0, c).symbol.same_string ({STRING_32} "=%/0x332/"))
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
