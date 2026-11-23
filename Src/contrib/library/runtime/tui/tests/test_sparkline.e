note
	description: "[
		P1 item V9, TUI_SPARKLINE absent values, per-bar style (SPARKLINE_BAR) and markers
		(review/p1_visualization_plan.md).
		The `test_ratatui_*` cases are the tests of Ratatui ratatui-widgets/src/sparkline.rs, as
		row-exact buffer snapshots with the style of every cell checked. Ratatui's `render`
		helper (a `width` x 1 buffer filled with "x") is `rendered`.
		Coordinates: Ratatui writes buffer[(x, y)] and Rect::new (x, y, width, height); here
		cells are (row, column) and RECT.make (x, y, width, height).
		The older sparkline tests (TEST_METRIC_WIDGETS, TEST_MILESTONE_F) are unchanged.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_SPARKLINE

inherit
	BUFFER_TEST_HELPER

feature -- Ratatui sparkline.rs: data

	test_ratatui_it_can_be_created_from_values
			-- Ratatui `it_can_be_created_from_vec_of_u64`, `..._array_of_u64`, `..._slice_of_u64`
			-- and the `Option<u64>` variants: plain values become present bars without a style;
			-- `None` is an absent bar.
		local
			l_list: ARRAYED_LIST [NATURAL_64]
			l_spark: TUI_SPARKLINE
		do
			create l_list.make_from_array (<<1, 2, 3>>)
			l_spark := (create {TUI_SPARKLINE}).with_data (l_list)
			assert ("from list", same_bars (l_spark, <<create {SPARKLINE_BAR}.make (1), create {SPARKLINE_BAR}.make (2), create {SPARKLINE_BAR}.make (3)>>))
			l_spark := (create {TUI_SPARKLINE}).with_data ({ARRAY [NATURAL_64]} <<1, 2, 3>>)
			assert ("from array", same_bars (l_spark, <<create {SPARKLINE_BAR}.make (1), create {SPARKLINE_BAR}.make (2), create {SPARKLINE_BAR}.make (3)>>))
			create l_spark.make_with_data (l_list)
			assert ("make_with_data", same_bars (l_spark, <<create {SPARKLINE_BAR}.make (1), create {SPARKLINE_BAR}.make (2), create {SPARKLINE_BAR}.make (3)>>))
			l_spark := (create {TUI_SPARKLINE}).with_bars (<<create {SPARKLINE_BAR}.make (1), create {SPARKLINE_BAR}.make_absent, create {SPARKLINE_BAR}.make (3)>>)
			assert ("with absent", same_bars (l_spark, <<create {SPARKLINE_BAR}.make (1), create {SPARKLINE_BAR}.make_absent, create {SPARKLINE_BAR}.make (3)>>))
			assert ("absent is not zero", not (create {SPARKLINE_BAR}.make_absent).is_equal (create {SPARKLINE_BAR}.make (0)))
			create l_spark
			l_spark.append_value (1)
			l_spark.append_absent
			l_spark.append_value (3)
			assert ("appended", same_bars (l_spark, <<create {SPARKLINE_BAR}.make (1), create {SPARKLINE_BAR}.make_absent, create {SPARKLINE_BAR}.make (3)>>))
		end

feature -- Ratatui sparkline.rs: bar set

	test_ratatui_it_does_not_panic_if_max_is_zero
			-- Ratatui `it_does_not_panic_if_max_is_zero`: all values 0 give blank bars; the
			-- columns past the data keep their "x".
		do
			assert_buffer_lines ("zeros", rendered ((create {TUI_SPARKLINE}).with_data ({ARRAY [NATURAL_64]} <<0, 0, 0>>), 6), <<"   xxx">>)
		end

	test_ratatui_it_does_not_panic_if_max_is_set_to_zero
			-- Ratatui `it_does_not_panic_if_max_is_set_to_zero` (deviation): Ratatui's `max (0)`
			-- scales every bar to 0 ("   xxx"). Here `max_value` 0 means "the largest value", so
			-- the bars are drawn against 2.
		do
			assert_buffer_lines ("max 0 is automatic", rendered ((create {TUI_SPARKLINE}).with_data ({ARRAY [NATURAL_64]} <<0, 1, 2>>).with_max_value (0), 6), <<{STRING_32} " %/0x2584/%/0x2588/xxx">>)
		end

	test_ratatui_it_draws
			-- Ratatui `it_draws`, and `it_renders_left_to_right`.
		local
			l_buf: BUFFER
		do
			l_buf := rendered ((create {TUI_SPARKLINE}).with_data (Zero_to_eight), 12)
			assert_buffer_lines ("draws", l_buf, <<{STRING_32} " %/0x2581/%/0x2582/%/0x2583/%/0x2584/%/0x2585/%/0x2586/%/0x2587/%/0x2588/xxx">>)
			assert_cell_styles ("draws", l_buf, No_styled_cells)
			assert_buffer_lines ("left to right", rendered ((create {TUI_SPARKLINE}).with_data (Zero_to_eight).with_direction ({SPARKLINE_DIRECTION}.Left_to_right), 12), <<{STRING_32} " %/0x2581/%/0x2582/%/0x2583/%/0x2584/%/0x2585/%/0x2586/%/0x2587/%/0x2588/xxx">>)
		end

	test_ratatui_it_draws_double_height
			-- Ratatui `it_draws_double_height`.
		local
			l_buf: BUFFER
		do
			l_buf := buffer_with_lines (<<"xxxxxxxxxxxx", "xxxxxxxxxxxx">>)
			(create {TUI_SPARKLINE}).with_data (Zero_to_eight).render (create {RECT}.make (0, 0, 12, 2), l_buf)
			assert_buffer_lines ("double height", l_buf, <<{STRING_32} "     %/0x2582/%/0x2584/%/0x2586/%/0x2588/xxx", {STRING_32} " %/0x2582/%/0x2584/%/0x2586/%/0x2588/%/0x2588/%/0x2588/%/0x2588/%/0x2588/xxx">>)
		end

	test_ratatui_render_handles_u64_max_value
			-- Ratatui `render_handles_u64_max_value`: no overflow in value * levels.
		local
			l_buf: BUFFER
		do
			create l_buf.make (1, 3)
			(create {TUI_SPARKLINE}).with_data ({ARRAY [NATURAL_64]} <<{NATURAL_64}.max_value>>).with_max_value ({NATURAL_64}.max_value).render (create {RECT}.make (0, 0, 1, 3), l_buf)
			assert_buffer_lines ("full", l_buf, <<{STRING_32} "%/0x2588/", {STRING_32} "%/0x2588/", {STRING_32} "%/0x2588/">>)
		end

	test_ratatui_render_keeps_integer_precision_for_large_values
			-- Ratatui `render_keeps_integer_precision_for_large_values`: (max - 1) of max is 7
			-- eighths, not 8 (no floating point, no rounding up).
		local
			l_buf: BUFFER
		do
			create l_buf.make (1, 1)
			(create {TUI_SPARKLINE}).with_data ({ARRAY [NATURAL_64]} <<{NATURAL_64}.max_value - 1>>).with_max_value ({NATURAL_64}.max_value).render (create {RECT}.make (0, 0, 1, 1), l_buf)
			assert_buffer_lines ("seven eighths", l_buf, <<{STRING_32} "%/0x2587/">>)
		end

	test_ratatui_it_renders_right_to_left
			-- Ratatui `it_renders_right_to_left`.
		do
			assert_buffer_lines ("right to left", rendered ((create {TUI_SPARKLINE}).with_data (Zero_to_eight).with_direction ({SPARKLINE_DIRECTION}.Right_to_left), 12), <<{STRING_32} "xxx%/0x2588/%/0x2587/%/0x2586/%/0x2585/%/0x2584/%/0x2583/%/0x2582/%/0x2581/ ">>)
		end

	test_ratatui_it_renders_with_absent_value_style
			-- Ratatui `it_renders_with_absent_value_style`: an absent first bar is a full shade
			-- in red; the other cells keep the default style.
		local
			l_buf: BUFFER
		do
			l_buf := rendered (absent_first_sparkline.with_absent_value_style (Red).with_absent_value_symbol ('%/0x2588/'), 12)
			assert_buffer_lines ("absent", l_buf, <<{STRING_32} "%/0x2588/%/0x2581/%/0x2582/%/0x2583/%/0x2584/%/0x2585/%/0x2586/%/0x2587/%/0x2588/xxx">>)
			assert_cell_styles ("absent", l_buf, <<[0, 0, Red]>>)
		end

	test_ratatui_it_renders_with_absent_value_style_double_height
			-- Ratatui `it_renders_with_absent_value_style_double_height`: the absent column fills
			-- the whole height.
		local
			l_buf: BUFFER
		do
			l_buf := buffer_with_lines (<<"xxxxxxxxxxxx", "xxxxxxxxxxxx">>)
			absent_first_sparkline.with_absent_value_style (Red).with_absent_value_symbol ('%/0x2588/').render (create {RECT}.make (0, 0, 12, 2), l_buf)
			assert_buffer_lines ("absent double", l_buf, <<{STRING_32} "%/0x2588/    %/0x2582/%/0x2584/%/0x2586/%/0x2588/xxx", {STRING_32} "%/0x2588/%/0x2582/%/0x2584/%/0x2586/%/0x2588/%/0x2588/%/0x2588/%/0x2588/%/0x2588/xxx">>)
			assert_cell_styles ("absent double", l_buf, <<[0, 0, Red], [1, 0, Red]>>)
		end

	test_ratatui_it_renders_with_custom_absent_value_style
			-- Ratatui `it_renders_with_custom_absent_value_style`: symbol '*', no style.
		local
			l_buf: BUFFER
		do
			l_buf := rendered (absent_first_sparkline.with_absent_value_symbol ('*'), 12)
			assert_buffer_lines ("star", l_buf, <<{STRING_32} "*%/0x2581/%/0x2582/%/0x2583/%/0x2584/%/0x2585/%/0x2586/%/0x2587/%/0x2588/xxx">>)
			assert_cell_styles ("star", l_buf, No_styled_cells)
		end

	test_ratatui_it_renders_with_custom_bar_styles
			-- Ratatui `it_renders_with_custom_bar_styles`: three red, three green, three blue
			-- bars. The style covers the whole column, also the blank cell of the 0 bar.
		local
			l_bars: ARRAYED_LIST [SPARKLINE_BAR]
			l_buf: BUFFER
			i: INTEGER
			l_expected: ARRAYED_LIST [TUPLE [row, col: INTEGER; style: STYLE]]
		do
			create l_bars.make (9)
			create l_expected.make (9)
			from i := 0 until i > 8 loop
				l_bars.extend ((create {SPARKLINE_BAR}.make (i.to_natural_64)).with_style (rgb_style (i // 3)))
				l_expected.extend ([0, i, rgb_style (i // 3)])
				i := i + 1
			end
			l_buf := rendered ((create {TUI_SPARKLINE}).with_bars (l_bars), 12)
			assert_buffer_lines ("bar styles", l_buf, <<{STRING_32} " %/0x2581/%/0x2582/%/0x2583/%/0x2584/%/0x2585/%/0x2586/%/0x2587/%/0x2588/xxx">>)
			assert_cell_styles ("bar styles", l_buf, l_expected.to_array)
		end

	test_ratatui_render_in_minimal_buffer
			-- Ratatui `render_in_minimal_buffer`, and `render_in_zero_size_buffer` (a BUFFER is at
			-- least 1 x 1, so a zero area stands in for the zero buffer).
		local
			l_buf: BUFFER
			l_spark: TUI_SPARKLINE
		do
			create l_buf.make (1, 1)
			l_spark := (create {TUI_SPARKLINE}).with_data ({ARRAY [NATURAL_64]} <<1, 2, 3, 4, 5, 6, 7, 8, 9, 10>>).with_max_value (10)
			l_spark.render (create {RECT}.make (0, 0, 1, 1), l_buf)
			assert_buffer_lines ("minimal", l_buf, <<" ">>)
			l_buf := buffer_with_lines (<<"x">>)
			l_spark.render (create {RECT}.make (0, 0, 0, 0), l_buf)
			l_spark.with_marker ({CANVAS_MARKER}.braille).render (create {RECT}.make (0, 0, 0, 0), l_buf)
			assert_buffer_lines ("zero area", l_buf, <<"x">>)
		end

feature -- Ratatui sparkline.rs: markers

	test_ratatui_marker_setter
			-- Ratatui `marker_setter`; the default is the bar set.
		do
			assert ("default bar", (create {TUI_SPARKLINE}).marker = {CANVAS_MARKER}.bar)
			assert ("braille", (create {TUI_SPARKLINE}).with_marker ({CANVAS_MARKER}.braille).marker = {CANVAS_MARKER}.braille)
		end

	test_ratatui_it_renders_braille
			-- Ratatui `it_renders_braille`: two points per column; an empty cell of a drawn
			-- column is U+2800.
		do
			assert_buffer_lines ("braille", rendered (braille_sparkline (<<0, 1, 2, 3, 4, 3, 2, 1, 0>>, 4), 6), <<{STRING_32} "%/0x2880/%/0x28F4/%/0x28F7/%/0x28C4/%/0x2800/x">>)
		end

	test_ratatui_it_renders_braille_double_height
			-- Ratatui `it_renders_braille_double_height`.
		local
			l_buf: BUFFER
		do
			l_buf := buffer_with_lines (<<"xxxxxx", "xxxxxx">>)
			braille_sparkline (Zero_to_eight, 8).render (create {RECT}.make (0, 0, 6, 2), l_buf)
			assert_buffer_lines ("braille double", l_buf, <<{STRING_32} "%/0x2800/%/0x2800/%/0x2880/%/0x28F4/%/0x2847/x", {STRING_32} "%/0x2880/%/0x28F4/%/0x28FF/%/0x28FF/%/0x2847/x">>)
		end

	test_ratatui_it_renders_braille_right_to_left
			-- Ratatui `it_renders_braille_right_to_left`.
		do
			assert_buffer_lines ("braille rtl", rendered (braille_sparkline (<<0, 1, 2, 3, 4>>, 4).with_direction ({SPARKLINE_DIRECTION}.Right_to_left), 4), <<{STRING_32} "x%/0x28B8/%/0x28E6/%/0x2840/">>)
		end

	test_ratatui_it_renders_braille_with_absent_values
			-- Ratatui `it_renders_braille_with_absent_values`: two absent points make an absent
			-- column.
		local
			l_buf: BUFFER
		do
			l_buf := rendered (braille_sparkline_of_bars (<<absent, absent, bar (1), bar (4)>>, 4).with_absent_value_style (Red).with_absent_value_symbol ('%/0x2588/'), 3)
			assert_buffer_lines ("braille absent", l_buf, <<{STRING_32} "%/0x2588/%/0x28F8/x">>)
			assert_cell_styles ("braille absent", l_buf, <<[0, 0, Red]>>)
		end

	test_ratatui_braille_uses_right_sample_style_when_styles_differ
			-- Ratatui `braille_uses_right_sample_style_when_styles_differ`.
		local
			l_buf: BUFFER
		do
			l_buf := rendered (braille_sparkline_of_bars (<<bar (1).with_style (Red), bar (4).with_style (Blue)>>, 4), 2)
			assert_buffer_lines ("right style", l_buf, <<{STRING_32} "%/0x28F8/x">>)
			assert_cell_styles ("right style", l_buf, <<[0, 0, Blue]>>)
		end

	test_ratatui_braille_uses_base_style_when_right_sample_has_no_custom_style
			-- Ratatui `braille_uses_base_style_when_right_sample_has_no_custom_style`.
		local
			l_buf: BUFFER
		do
			l_buf := rendered (braille_sparkline_of_bars (<<bar (4).with_style (Red), bar (4)>>, 4).with_style (Blue), 2)
			assert_buffer_lines ("base style", l_buf, <<{STRING_32} "%/0x28FF/x">>)
			assert_cell_styles ("base style", l_buf, <<[0, 0, Blue]>>)
		end

	test_ratatui_braille_renders_lone_absent_value
			-- Ratatui `braille_renders_lone_absent_value`, both cases.
		do
			assert_buffer_lines ("left to right", rendered (braille_sparkline_of_bars (<<absent>>, 0).with_absent_value_symbol ('*'), 2), <<"*x">>)
			assert_buffer_lines ("right to left", rendered (braille_sparkline_of_bars (<<absent>>, 0).with_absent_value_symbol ('*').with_direction ({SPARKLINE_DIRECTION}.Right_to_left), 2), <<"x*">>)
		end

	test_ratatui_braille_renders_absent_pair_right_to_left
			-- Ratatui `braille_renders_absent_pair_right_to_left`.
		do
			assert_buffer_lines ("pair", rendered (braille_sparkline_of_bars (<<absent, absent>>, 0).with_absent_value_symbol ('*').with_direction ({SPARKLINE_DIRECTION}.Right_to_left), 2), <<"x*">>)
		end

	test_ratatui_braille_applies_absent_style_with_default_blank_symbol
			-- Ratatui `braille_applies_absent_style_with_default_blank_symbol`.
		local
			l_buf: BUFFER
		do
			l_buf := rendered (braille_sparkline_of_bars (<<absent, absent>>, 0).with_absent_value_style (Yellow), 1)
			assert_buffer_lines ("blank", l_buf, <<" ">>)
			assert_cell_styles ("blank", l_buf, <<[0, 0, Yellow]>>)
		end

	test_ratatui_braille_absent_sample_does_not_override_visible_sample
			-- Ratatui `braille_absent_sample_does_not_override_visible_sample`.
		local
			l_buf: BUFFER
		do
			l_buf := rendered (braille_sparkline_of_bars (<<bar (4).with_style (Red), absent, absent, bar (4).with_style (Blue)>>, 4).with_absent_value_style (Yellow).with_absent_value_symbol ('*'), 3)
			assert_buffer_lines ("visible wins", l_buf, <<{STRING_32} "%/0x2847/%/0x28B8/x">>)
			assert_cell_styles ("visible wins", l_buf, <<[0, 0, Red], [0, 1, Blue]>>)
		end

	test_ratatui_braille_renders_mixed_pair_right_to_left
			-- Ratatui `braille_renders_mixed_pair_right_to_left`, both cases.
		local
			l_buf: BUFFER
		do
			l_buf := rendered (braille_sparkline_of_bars (<<bar (4).with_style (Red), absent>>, 4).with_direction ({SPARKLINE_DIRECTION}.Right_to_left).with_absent_value_style (Yellow).with_absent_value_symbol ('*'), 2)
			assert_buffer_lines ("left visible", l_buf, <<{STRING_32} "x%/0x28B8/">>)
			assert_cell_styles ("left visible", l_buf, <<[0, 1, Red]>>)
			l_buf := rendered (braille_sparkline_of_bars (<<absent, bar (4).with_style (Blue)>>, 4).with_direction ({SPARKLINE_DIRECTION}.Right_to_left).with_absent_value_style (Yellow).with_absent_value_symbol ('*'), 2)
			assert_buffer_lines ("right visible", l_buf, <<{STRING_32} "x%/0x2847/">>)
			assert_cell_styles ("right visible", l_buf, <<[0, 1, Blue]>>)
		end

	test_ratatui_braille_render_direction_is_symmetric
			-- Ratatui `braille_render_direction_is_symmetric`.
		do
			assert_buffer_lines ("left to right", rendered (braille_sparkline (<<0, 1, 2, 3>>, 4), 2), <<{STRING_32} "%/0x2880/%/0x28F4/">>)
			assert_buffer_lines ("right to left", rendered (braille_sparkline (<<0, 1, 2, 3>>, 4).with_direction ({SPARKLINE_DIRECTION}.Right_to_left), 2), <<{STRING_32} "%/0x28E6/%/0x2840/">>)
		end

	test_ratatui_double_width_marker_renders_multiple_rows
			-- Ratatui `double_width_marker_renders_multiple_rows`: [4, 4] of 8 on two rows fill
			-- the bottom row for every double-width marker.
		do
			assert_two_rows ("braille", {CANVAS_MARKER}.braille, {STRING_32} "%/0x2800/", {STRING_32} "%/0x28FF/")
			assert_two_rows ("quadrant", {CANVAS_MARKER}.quadrant, " ", {STRING_32} "%/0x2588/")
			assert_two_rows ("sextant", {CANVAS_MARKER}.sextant, " ", {STRING_32} "%/0x2588/")
			assert_two_rows ("octant", {CANVAS_MARKER}.octant, " ", {STRING_32} "%/0x2588/")
		end

	test_ratatui_braille_handles_max_extremes
			-- Ratatui `braille_handles_max_extremes`. The u64::MAX case as in Ratatui; the zero
			-- case is a deviation: `max_value` 0 is automatic, so [MAX, MAX] are full (Ratatui
			-- draws empty U+2800 cells).
		local
			l_buf: BUFFER
		do
			l_buf := buffer_with_lines (<<"x", "x">>)
			braille_sparkline (<<{NATURAL_64}.max_value, {NATURAL_64}.max_value>>, {NATURAL_64}.max_value).render (create {RECT}.make (0, 0, 1, 2), l_buf)
			assert_buffer_lines ("u64 max", l_buf, <<{STRING_32} "%/0x28FF/", {STRING_32} "%/0x28FF/">>)
			l_buf := buffer_with_lines (<<"x", "x">>)
			braille_sparkline (<<{NATURAL_64}.max_value, {NATURAL_64}.max_value>>, 0).render (create {RECT}.make (0, 0, 1, 2), l_buf)
			assert_buffer_lines ("max 0 is automatic", l_buf, <<{STRING_32} "%/0x28FF/", {STRING_32} "%/0x28FF/">>)
		end

	test_ratatui_it_renders_quadrant
			-- Ratatui `it_renders_quadrant`.
		do
			assert_buffer_lines ("quadrant", rendered (braille_sparkline (<<0, 1, 2, 2, 1, 0>>, 2).with_marker ({CANVAS_MARKER}.quadrant), 4), <<{STRING_32} "%/0x2597/%/0x2588/%/0x2596/x">>)
		end

	test_ratatui_it_renders_sextant
			-- Ratatui `it_renders_sextant`.
		do
			assert_buffer_lines ("sextant", rendered (braille_sparkline (<<0, 1, 2, 3, 3, 2, 1, 0>>, 3).with_marker ({CANVAS_MARKER}.sextant), 5), <<{STRING_32} "%/0x1FB1E/%/0x1FB3B/%/0x1FB3A/%/0x1FB0F/x">>)
		end

	test_ratatui_it_renders_octant
			-- Ratatui `it_renders_octant`: the empty cell of a drawn column is a space.
		do
			assert_buffer_lines ("octant", rendered (braille_sparkline (<<0, 1, 2, 3, 4, 3, 2, 1, 0>>, 4).with_marker ({CANVAS_MARKER}.octant), 6), <<{STRING_32} "%/0x1CEA0/%/0x1CDE1/%/0x1CDE4/%/0x1CDBB/ x">>)
		end

	test_ratatui_it_renders_half_block
			-- Ratatui `it_renders_half_block`: the lower half, then a full block.
		do
			assert_buffer_lines ("half block", rendered (braille_sparkline (<<0, 1, 2>>, 2).with_marker ({CANVAS_MARKER}.half_block), 4), <<{STRING_32} " %/0x2584/%/0x2588/x">>)
		end

	test_ratatui_it_renders_block_dot_and_custom
			-- Ratatui `it_renders_block`, `it_renders_dot` and `it_renders_custom_marker`.
		do
			assert_buffer_lines ("block", rendered (braille_sparkline (<<0, 1, 0, 1>>, 1).with_marker ({CANVAS_MARKER}.block), 5), <<{STRING_32} " %/0x2588/ %/0x2588/x">>)
			assert_buffer_lines ("dot", rendered (braille_sparkline (<<0, 1, 0, 1>>, 1).with_marker ({CANVAS_MARKER}.dot), 5), <<{STRING_32} " %/0x2022/ %/0x2022/x">>)
			assert_buffer_lines ("custom", rendered (braille_sparkline (<<0, 1, 0, 1>>, 1).with_custom_marker ('*'), 5), <<" * *x">>)
		end

feature -- EiffelTUI cases

	test_sparkline_bar_value_and_style
			-- SPARKLINE_BAR: creation, CQS twins, equality, copy and the invariant.
		local
			l_bar, l_styled: SPARKLINE_BAR
		do
			create l_bar.make (7)
			assert ("present", not l_bar.is_absent and l_bar.value = 7 and l_bar.style = Void)
			l_styled := l_bar.with_style (Red)
			assert ("original keeps no style", l_bar.style = Void)
			assert ("styled", l_styled.style = Red and l_styled.value = 7)
			assert ("styles differ", not l_bar.is_equal (l_styled))
			assert ("equal style values", l_styled.is_equal (l_bar.with_style (create {STYLE}.make_fg ({COLOR}.Red))))
			assert ("twin equal", l_styled.twin.is_equal (l_styled))
			assert ("with_absent", l_styled.with_absent.is_absent and l_styled.with_absent.value = 0 and l_styled.with_absent.style = Red)
			assert ("with_value", (create {SPARKLINE_BAR}.make_absent).with_value (3).value = 3 and not (create {SPARKLINE_BAR}.make_absent).with_value (3).is_absent)
			l_bar.set_absent
			assert ("set_absent", l_bar.is_absent and l_bar.value = 0)
			l_bar.set_value (0)
			assert ("set_value 0 is present", not l_bar.is_absent)
			l_styled.set_style (Void)
			assert ("style removed", l_styled.style = Void)
		end

	test_sparkline_absent_bars_ignored_by_max
			-- The automatic maximum is the largest present value: an absent bar does not count,
			-- and all-absent data draws only absent columns.
		local
			l_spark: TUI_SPARKLINE
		do
			l_spark := (create {TUI_SPARKLINE}).with_bars (<<absent, bar (2), bar (4)>>).with_absent_value_symbol ('-')
			assert ("max 4", l_spark.effective_max = 4)
			assert_buffer_lines ("half and full", rendered (l_spark, 4), <<{STRING_32} "-%/0x2584/%/0x2588/x">>)
			l_spark := (create {TUI_SPARKLINE}).with_bars (<<absent, absent>>).with_absent_value_symbol ('-')
			assert ("max 0", l_spark.effective_max = 0)
			assert_buffer_lines ("all absent", rendered (l_spark, 3), <<"--x">>)
			assert ("explicit max", l_spark.with_max_value (9).effective_max = 9)
			assert ("values show 0 for absent", l_spark.values.count = 2 and l_spark.values [1] = 0)
		end

	test_sparkline_values_is_a_copy
			-- `values` is a new list each time: changing it does not change the sparkline
			-- (the obsolete `data` returns the same copy).
		local
			l_spark: TUI_SPARKLINE
			l_values: ARRAYED_LIST [NATURAL_64]
		do
			create l_spark.make_with_data ({ARRAY [NATURAL_64]} <<1, 2>>)
			l_values := l_spark.values
			l_values.extend (7)
			l_values [1] := 9
			assert ("bars unchanged", l_spark.bars.count = 2 and l_spark.bars [1].value = 1)
			assert ("values unchanged", l_spark.values.count = 2 and l_spark.values [1] = 1)
			assert ("new list each time", l_spark.values /= l_spark.values)
			l_spark.append_value (5)
			assert ("append_value adds a bar", l_spark.values.count = 3 and l_spark.values [3] = 5)
		end

	test_sparkline_style_layers
			-- `style`, then `bar_style` on the cells that show the bar, then the bar's own style;
			-- `absent_value_style` over `style` in an absent column; all patched over the cell.
		local
			l_buf: BUFFER
			l_base, l_bar_style, l_own, l_filled, l_empty, l_absent: STYLE
		do
			l_base := create {STYLE}.make_with_colors ({COLOR}.White, {COLOR}.Blue)
			l_bar_style := create {STYLE}.make_fg ({COLOR}.Green)
			l_own := (create {STYLE}).with_bold
			create l_buf.make (3, 2)
			(create {TUI_SPARKLINE}).with_bars (<<bar (1).with_style (l_own), bar (2), absent>>).with_max_value (2).
				with_style (l_base).with_bar_style (l_bar_style).with_absent_value_style (Red).
				render (create {RECT}.make (0, 0, 3, 2), l_buf)
			assert_buffer_lines ("layers", l_buf, <<{STRING_32} " %/0x2588/ ", {STRING_32} "%/0x2588/%/0x2588/ ">>)
			l_filled := l_base.patch (l_bar_style)
			l_empty := l_base.patch (l_own)
			l_absent := l_base.patch (Red)
			assert_cell_styles ("layers", l_buf, <<[0, 0, l_empty], [1, 0, l_filled.patch (l_own)], [0, 1, l_filled], [1, 1, l_filled], [0, 2, l_absent], [1, 2, l_absent]>>)
				-- Over a styled cell, the unset fields keep the cell's
			l_buf := buffer_with_lines (<<"xx">>)
			l_buf.put_string (0, 0, "xx", create {STYLE}.make_bg ({COLOR}.Green))
			(create {TUI_SPARKLINE}).with_data ({ARRAY [NATURAL_64]} <<1, 0>>).with_style (Red).render (create {RECT}.make (0, 0, 2, 1), l_buf)
			assert_buffer_lines ("patched", l_buf, <<{STRING_32} "%/0x2588/ ">>)
			assert_cell_styles ("patched", l_buf, <<[0, 0, create {STYLE}.make_with_colors ({COLOR}.Red, {COLOR}.Green)], [0, 1, create {STYLE}.make_with_colors ({COLOR}.Red, {COLOR}.Green)]>>)
		end

	test_sparkline_markers_with_blocks_and_clipping
			-- Every marker inside a bordered block, and in an area cut by the buffer's right and
			-- bottom edges: the scale uses the whole area, only cells on the buffer are drawn.
		local
			l_buf: BUFFER
			l_spark: TUI_SPARKLINE
		do
			l_spark := (create {TUI_SPARKLINE}).with_data ({ARRAY [NATURAL_64]} <<4, 8, 2, 6>>).with_max_value (8).with_block ((create {TUI_BLOCK}).with_borders ({BORDERS}.all_borders))
			create l_buf.make (6, 4)
			l_spark.render (create {RECT}.make (0, 0, 6, 4), l_buf)
			assert_buffer_lines ("bars in block", l_buf, <<{STRING_32} "%/0x250C/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2510/", {STRING_32} "%/0x2502/ %/0x2588/ %/0x2584/%/0x2502/", {STRING_32} "%/0x2502/%/0x2588/%/0x2588/%/0x2584/%/0x2588/%/0x2502/", {STRING_32} "%/0x2514/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2518/">>)
			create l_buf.make (6, 4)
			l_spark.with_marker ({CANVAS_MARKER}.braille).render (create {RECT}.make (0, 0, 6, 4), l_buf)
			assert_buffer_lines ("braille in block", l_buf, <<{STRING_32} "%/0x250C/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2510/", {STRING_32} "%/0x2502/%/0x28B8/%/0x28A0/  %/0x2502/", {STRING_32} "%/0x2502/%/0x28FF/%/0x28FC/  %/0x2502/", {STRING_32} "%/0x2514/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2518/">>)
				-- Area 4 x 4 at (2, 2) of a 4 x 4 buffer: rows 2..3 and columns 2..3 are visible,
				-- the top half of the bars (16 of 32 levels is empty there, 32 is full)
			create l_buf.make (4, 4)
			(create {TUI_SPARKLINE}).with_data ({ARRAY [NATURAL_64]} <<4, 8>>).with_max_value (8).render (create {RECT}.make (2, 2, 4, 4), l_buf)
			assert_buffer_lines ("cut", l_buf, <<"    ", "    ", {STRING_32} "   %/0x2588/", {STRING_32} "   %/0x2588/">>)
			create l_buf.make (4, 4)
			(create {TUI_SPARKLINE}).with_data ({ARRAY [NATURAL_64]} <<1, 2, 3, 4, 5, 6>>).with_direction ({SPARKLINE_DIRECTION}.Right_to_left).render (create {RECT}.make (2, 3, 4, 1), l_buf)
			assert_buffer_lines ("cut rtl", l_buf, <<"    ", "    ", "    ", {STRING_32} "  %/0x2585/%/0x2584/">>)
			assert ("consistent", l_buf.is_consistent)
		end

	test_sparkline_scaled_ticks
			-- `scaled_ticks` is value * ticks // max for every NATURAL_64, without overflow.
		local
			l_max: NATURAL_64
		do
			l_max := {NATURAL_64}.max_value
			assert ("zero max", {TUI_SPARKLINE}.scaled_ticks (5, 0, 8) = 0)
			assert ("above max", {TUI_SPARKLINE}.scaled_ticks (9, 4, 8) = 8)
			assert ("plain", {TUI_SPARKLINE}.scaled_ticks (3, 8, 8) = 3)
			assert ("max - 1", {TUI_SPARKLINE}.scaled_ticks (l_max - 1, l_max, 8) = 7)
			assert ("half", {TUI_SPARKLINE}.scaled_ticks ({NATURAL_64} 1 |<< 63, l_max, 524280) = 262140)
			assert ("third", {TUI_SPARKLINE}.scaled_ticks (l_max // 3, l_max, 3) = 1)
			assert ("third + 1", {TUI_SPARKLINE}.scaled_ticks (l_max // 3 + 1, l_max, 3) = 1)
			assert ("max - 2", {TUI_SPARKLINE}.scaled_ticks (l_max - 2, l_max, 3) = 2)
			assert ("large max", {TUI_SPARKLINE}.scaled_ticks (l_max // 2, l_max - 1, 524280) = 262140)
			assert ("cell ticks", {TUI_SPARKLINE}.cell_ticks (11, 0, 8) = 8 and {TUI_SPARKLINE}.cell_ticks (11, 1, 8) = 3 and {TUI_SPARKLINE}.cell_ticks (11, 2, 8) = 0)
		end

	test_sparkline_equality_and_copy
			-- `is_equal` and `twin` cover the bars and the new settings; a twin's bars are its own;
			-- the `with_*` builders leave the original unchanged.
		local
			l_a, l_b: TUI_SPARKLINE
		do
			l_a := (create {TUI_SPARKLINE}).with_bars (<<bar (1).with_style (Red), absent>>)
			l_b := l_a.twin
			assert ("twin equal", l_b.is_equal (l_a))
			assert ("twin bars own", l_b.bars [1] /= l_a.bars [1])
			l_b.bars [1].set_value (5)
			assert ("original kept", l_a.bars [1].value = 1)
			assert ("now differ", not l_b.is_equal (l_a))
			assert ("marker differs", not l_a.with_marker ({CANVAS_MARKER}.octant).is_equal (l_a))
			assert ("custom char differs", not l_a.with_custom_marker ('*').is_equal (l_a.with_custom_marker ('+')))
			assert ("absent symbol differs", not l_a.with_absent_value_symbol ('*').is_equal (l_a))
			assert ("absent style differs", not l_a.with_absent_value_style (Red).is_equal (l_a))
			assert ("bar style differs", not l_a.with_bar_style (Red).is_equal (l_a))
			assert ("original marker", l_a.marker = {CANVAS_MARKER}.bar and l_a.absent_value_symbol = ' ')
			assert ("set_bars copies", l_a.bars [2].is_absent)
		end

	test_sparkline_preconditions
			-- A wide or zero-width absent symbol, an invalid custom character and an invalid
			-- marker are refused.
		do
			assert ("wide absent", precondition_raised (agent (create {TUI_SPARKLINE}).set_absent_value_symbol ('%/0x5BBD/'), "one_column"))
			assert ("combining absent", precondition_raised (agent (create {TUI_SPARKLINE}).with_absent_value_symbol ('%/0x301/'), "one_column"))
			assert ("braille blank custom", precondition_raised (agent (create {TUI_SPARKLINE}).set_custom_marker ({CANVAS_MARKER}.blank_braille), "one_column"))
			assert ("invalid marker", precondition_raised (agent (create {TUI_SPARKLINE}).set_marker (0), "valid_marker"))
			assert ("valid absent", {TUI_SPARKLINE}.is_valid_absent_symbol ('%/0x2591/') and {TUI_SPARKLINE}.is_valid_absent_symbol ({CANVAS_MARKER}.blank_braille))
		end

feature {NONE} -- Fixtures

	Zero_to_eight: ARRAY [NATURAL_64]
			-- 0 .. 8
		once
			Result := <<0, 1, 2, 3, 4, 5, 6, 7, 8>>
		end

	absent_first_sparkline: TUI_SPARKLINE
			-- Ratatui's `[None, Some(1), .., Some(8)]`
		local
			i: INTEGER
		do
			create Result
			Result.append_absent
			from i := 1 until i > 8 loop
				Result.append_value (i.to_natural_64)
				i := i + 1
			end
		end

	braille_sparkline (a_data: ARRAY [NATURAL_64]; a_max: NATURAL_64): TUI_SPARKLINE
			-- Braille sparkline of `a_data` with `max_value` `a_max`
		do
			Result := (create {TUI_SPARKLINE}).with_data (a_data).with_max_value (a_max).with_marker ({CANVAS_MARKER}.braille)
		end

	braille_sparkline_of_bars (a_bars: ARRAY [SPARKLINE_BAR]; a_max: NATURAL_64): TUI_SPARKLINE
			-- Braille sparkline of `a_bars` with `max_value` `a_max`
		do
			Result := (create {TUI_SPARKLINE}).with_bars (a_bars).with_max_value (a_max).with_marker ({CANVAS_MARKER}.braille)
		end

	bar (a_value: NATURAL_64): SPARKLINE_BAR
			-- Present bar of `a_value`
		do
			create Result.make (a_value)
		end

	absent: SPARKLINE_BAR
			-- Absent bar
		do
			create Result.make_absent
		end

	Red: STYLE
		once
			create Result.make_fg ({COLOR}.Red)
		end

	Blue: STYLE
		once
			create Result.make_fg ({COLOR}.Blue)
		end

	Yellow: STYLE
		once
			create Result.make_fg ({COLOR}.Yellow)
		end

	rgb_style (a_index: INTEGER): STYLE
			-- Red, green or blue foreground for `a_index` 0, 1, 2
		do
			inspect a_index
			when 0 then
				Result := Red
			when 1 then
				create Result.make_fg ({COLOR}.Green)
			else
				Result := Blue
			end
		end

	No_styled_cells: ARRAY [TUPLE [row, col: INTEGER; style: STYLE]]
			-- No cells, for `assert_cell_styles` (a typed `<<>>`)
		once
			create Result.make_empty
		end

feature {NONE} -- Helpers

	rendered (a_spark: TUI_SPARKLINE; a_width: INTEGER): BUFFER
			-- `a_spark` rendered over a `a_width` x 1 buffer of "x" (Ratatui's `render` helper)
		do
			create Result.make (a_width, 1)
			Result.fill ('x', create {STYLE})
			a_spark.render (create {RECT}.make (0, 0, a_width.to_natural_16, 1), Result)
		end

	assert_two_rows (a_tag: STRING; a_marker: NATURAL_8; a_empty, a_full: READABLE_STRING_GENERAL)
			-- [4, 4] of 8 with `a_marker` on a 1 x 2 area: `a_empty` above `a_full`.
		local
			l_buf: BUFFER
		do
			l_buf := buffer_with_lines (<<"x", "x">>)
			braille_sparkline (<<4, 4>>, 8).with_marker (a_marker).render (create {RECT}.make (0, 0, 1, 2), l_buf)
			assert_buffer_lines (a_tag, l_buf, <<a_empty, a_full>>)
		end

	same_bars (a_spark: TUI_SPARKLINE; a_expected: ARRAY [SPARKLINE_BAR]): BOOLEAN
			-- Are the bars of `a_spark` equal to `a_expected`?
		local
			i: INTEGER
		do
			Result := a_spark.bars.count = a_expected.count
			from i := 1 until not Result or i > a_expected.count loop
				Result := a_spark.bars [i].is_equal (a_expected [i])
				i := i + 1
			end
		end

	assert_cell_styles (a_tag: STRING; a_buf: BUFFER; a_cells: ARRAY [TUPLE [row, col: INTEGER; style: STYLE]])
			-- The cells `a_cells` of `a_buf` have their style; every other cell that is not a
			-- continuation cell has the default style.
		local
			r, c: INTEGER
			l_found: detachable STYLE
		do
			from r := 0 until r >= a_buf.height loop
				from c := 0 until c >= a_buf.width loop
					l_found := Void
					across a_cells as t loop
						if t.row = r and t.col = c then
							l_found := t.style
						end
					end
					if attached l_found as s then
						assert (a_tag + ": style " + r.out + "," + c.out, a_buf.cell (r, c).style.same_rendering (s))
					elseif not a_buf.cell (r, c).is_continuation then
						assert (a_tag + ": default style " + r.out + "," + c.out, a_buf.cell (r, c).style.renders_as_default)
					end
					c := c + 1
				end
				r := r + 1
			end
		end

	buffer_with_lines (a_lines: ARRAY [READABLE_STRING_GENERAL]): BUFFER
			-- New buffer with `a_lines` as rows (Ratatui `Buffer::with_lines`)
		require
			not_empty: not a_lines.is_empty
		local
			i: INTEGER
		do
			create Result.make ({UNICODE_WIDTH}.string_width (a_lines [a_lines.lower]).to_integer_32, a_lines.count)
			from i := a_lines.lower until i > a_lines.upper loop
				Result.put_string (i - a_lines.lower, 0, a_lines [i], create {STYLE})
				i := i + 1
			end
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
