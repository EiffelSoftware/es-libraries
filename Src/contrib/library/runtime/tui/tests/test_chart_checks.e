note
	description: "[
		P1 X3: checks of TUI_CHART and TUI_BARCHART against the Ratatui 0.30.1 chart fixes
		(`ratatui-widgets/src/chart.rs`, `barchart.rs`).

		  * X3a (#2550): a chart with one y-axis label (or one x-axis label) renders without a
		    division by zero. Ratatui skips an axis with fewer than two labels; EiffelTUI draws
		    the one label (y at the bottom row, x aligned in the plot width).
		  * X3b (#2546, and B4): bar heights are value * ticks // max without NATURAL_64
		    overflow (Ratatui computes in u128), and chart bounds near the REAL_64 range render
		    without an exception, with the points in their cells.
		  * X3c (#2553): a bar chart with no data renders its block only, and empty groups take
		    no room (Ratatui's constructors drop them).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_CHART_CHECKS

inherit
	BUFFER_TEST_HELPER

feature -- X3a: single axis label

	test_chart_one_y_label_renders_it
			-- Ratatui `it_does_not_panic_if_y_axis_has_one_label`: no dataset, y bounds [0, 1], the
			-- one y label "only", in 20 x 5. Ratatui renders no label; here it is on the bottom plot row.
		local
			l_chart: TUI_CHART
		do
			create l_chart.make
			l_chart.set_y_bounds (0.0, 1.0)
			l_chart.set_y_labels (<<"only">>)
			assert_buffer_lines ("one y label", rendered (l_chart, 20, 5), <<
				{STRING_32} "    %/0x2502/" + spaces (15),
				{STRING_32} "    %/0x2502/" + spaces (15),
				{STRING_32} "    %/0x2502/" + spaces (15),
				{STRING_32} "only%/0x2502/" + spaces (15),
				{STRING_32} "    %/0x2514/" + repeated ('%/0x2500/', 15)>>)
		end

	test_chart_one_x_label_renders_it
			-- The x-axis counterpart (Ratatui `render_x_labels` returns for fewer than two labels):
			-- the one x label is centred under the plot by default, and placed left or right by the
			-- alignment.
		local
			l_chart: TUI_CHART
		do
			create l_chart.make
			l_chart.set_x_labels (<<"only">>)
			assert_buffer_lines ("one x label, centred", rendered (l_chart, 20, 5), <<
				{STRING_32} "%/0x2502/" + spaces (19),
				{STRING_32} "%/0x2502/" + spaces (19),
				{STRING_32} "%/0x2502/" + spaces (19),
				{STRING_32} "%/0x2514/" + repeated ('%/0x2500/', 19),
				spaces (8) + {STRING_32} "only" + spaces (8)>>)
			l_chart.set_x_label_alignment ({TEXT_ALIGNMENT}.left)
			assert_buffer_lines ("one x label, left", rendered (l_chart, 20, 5), <<
				{STRING_32} "%/0x2502/" + spaces (19),
				{STRING_32} "%/0x2502/" + spaces (19),
				{STRING_32} "%/0x2502/" + spaces (19),
				{STRING_32} "%/0x2514/" + repeated ('%/0x2500/', 19),
				{STRING_32} " only" + spaces (15)>>)
			l_chart.set_x_label_alignment ({TEXT_ALIGNMENT}.right)
			assert_buffer_lines ("one x label, right", rendered (l_chart, 20, 5), <<
				{STRING_32} "%/0x2502/" + spaces (19),
				{STRING_32} "%/0x2502/" + spaces (19),
				{STRING_32} "%/0x2502/" + spaces (19),
				{STRING_32} "%/0x2514/" + repeated ('%/0x2500/', 19),
				spaces (16) + {STRING_32} "only">>)
		end

	test_chart_labels_on_one_cell_plot
			-- The smallest plot (one row, two columns) with one and with two labels on each axis:
			-- the label spacing divides by the label count minus one, and by a plot of one row.
		local
			l_chart: TUI_CHART
		do
			create l_chart.make
			l_chart.set_y_labels (<<"y">>)
			l_chart.set_x_labels (<<"x">>)
			assert_buffer_lines ("one label each", rendered (l_chart, 4, 3), <<
				{STRING_32} "y%/0x2502/  ",
				{STRING_32} " %/0x2514/%/0x2500/%/0x2500/",
				{STRING_32} "  x ">>)
			l_chart.set_y_labels (<<"a", "b">>)
			l_chart.set_x_labels (<<"a", "b">>)
				-- Both y labels fall on the one plot row; the last (the maximum) wins
			assert_buffer_lines ("two labels each", rendered (l_chart, 4, 3), <<
				{STRING_32} "b%/0x2502/  ",
				{STRING_32} " %/0x2514/%/0x2500/%/0x2500/",
				{STRING_32} "  ab">>)
		end

feature -- X3b: scaling near the numeric limits

	test_chart_huge_bounds_render
			-- The plan's X3b case: bounds of +-1e308 on both axes (the span overflows to infinity)
			-- and points of +-1e308, for every graph type, render without an exception, keep the
			-- axes, and draw what the same chart draws on bounds of +-1 (the points map to the same
			-- dots: 0 is the exact middle of both spans). The same for bounds of +-{REAL_64}.max_value.
		local
			l_buf, l_unit: BUFFER
			l_type: NATURAL_8
			l_limit: REAL_64
			l_tag: STRING
			r: INTEGER
		do
			across <<{CHART_GRAPH_TYPE}.scatter, {CHART_GRAPH_TYPE}.line, {CHART_GRAPH_TYPE}.bar, {CHART_GRAPH_TYPE}.area>> as t loop
				l_type := t
				l_unit := rendered (huge_chart (1.0, l_type, {CANVAS_MARKER}.braille), 20, 5)
				assert ("type " + l_type.out + ": something plotted on +-1",
					across 0 |..| 3 as row some not buffer_row_as_string (l_unit, row).substring (2, 20).is_whitespace end)
				across <<1.0e308, {REAL_64}.max_value>> as lim loop
					l_limit := lim
					l_tag := "type " + l_type.out + ", limit " + l_limit.out
					l_buf := rendered (huge_chart (l_limit, l_type, {CANVAS_MARKER}.braille), 20, 5)
					from r := 0 until r >= 4 loop
						assert (l_tag + ": y axis", l_buf.cell (r, 0).symbol.same_string ({STRING_32} "%/0x2502/"))
						r := r + 1
					end
					assert (l_tag + ": x axis", buffer_row_as_string (l_buf, 4).same_string ({STRING_32} "%/0x2514/" + repeated ('%/0x2500/', 19)))
					assert_buffer_lines (l_tag + ": as on +-1", l_buf, buffer_as_lines (l_unit).to_array)
				end
			end
		end

	test_clipping_ends_beyond_half_the_range
			-- Ends whose difference overflows (x from -1.5e308 to 1.5e308) on bounds [-1, 1]: the
			-- clipped line is (-1, 0) to (1, 0) (the slope is about 1e-308), not dropped, and a
			-- polygon edge between them meets the left and right bounds at y = 0, not at its first
			-- end's y. Ratatui's clipping gets NaN or a wrong end there.
		local
			l_chart: TUI_CHART
			l_data: TUI_CHART_DATASET
			l_canvas: TUI_CANVAS
			l_painter: CANVAS_PAINTER
			l_grid: BRAILLE_CANVAS
			l_poly: ARRAYED_LIST [TUPLE [x, y: REAL_64]]
			l_buf: BUFFER
		do
			create l_grid.make (10, 5)
			create l_painter.make (l_grid, [-1.0, 1.0], [-1.0, 1.0])
			if attached l_painter.clipped_segment (-1.5e308, -1.0, 1.5e308, 1.0) as s then
				assert ("clipped from the left bound", s.x1 = -1.0 and s.y1.abs < 1.0e-300)
				assert ("clipped to the right bound", s.x2 = 1.0 and s.y2.abs < 1.0e-300)
			else
				assert ("segment kept", False)
			end
			l_poly := l_painter.clipped_polygon (<<[-1.5e308, -1.0], [1.5e308, 1.0], [1.5e308, -1.0]>>)
			assert ("polygon clipped", not l_poly.is_empty)
			assert ("left crossing at y 0", across l_poly as p some p.x = -1.0 and p.y.abs < 1.0e-300 end)
			assert ("right crossing at y 0", across l_poly as p some p.x = 1.0 and p.y.abs < 1.0e-300 end)

				-- Through a chart: the same rows as the line (-1, 0) to (1, 0)
			create l_data.make ("far")
			l_data.append_point (-1.5e308, -1.0)
			l_data.append_point (1.5e308, 1.0)
			l_data.set_graph_type ({CHART_GRAPH_TYPE}.line)
			create l_chart.make_with_datasets (<<l_data>>)
			l_chart.set_x_bounds (-1.0, 1.0)
			l_chart.set_y_bounds (-1.0, 1.0)
			l_buf := rendered (l_chart, 20, 5)
			create l_data.make ("near")
			l_data.append_point (-1.0, 0.0)
			l_data.append_point (1.0, 0.0)
			l_data.set_graph_type ({CHART_GRAPH_TYPE}.line)
			create l_chart.make_with_datasets (<<l_data>>)
			l_chart.set_x_bounds (-1.0, 1.0)
			l_chart.set_y_bounds (-1.0, 1.0)
			assert ("chart line drawn", not buffer_row_as_string (l_buf, 2).substring (2, 20).is_whitespace)
			assert_buffer_lines ("chart line", l_buf, buffer_as_lines (rendered (l_chart, 20, 5)).to_array)

				-- Through a canvas: the filled polygon covers the same cells as (-1, 0), (1, 0), (1, -1)
			create l_canvas.make
			l_canvas := l_canvas.with_marker ({CANVAS_MARKER}.dot).with_bounds (-1.0, 1.0, -1.0, 1.0)
			assert_buffer_lines ("canvas polygon",
				rendered (l_canvas.with_shape (create {SHAPE_AREA}.make (<<[-1.5e308, -1.0], [1.5e308, 1.0], [1.5e308, -1.0]>>, create {STYLE}, True)), 10, 5),
				buffer_as_lines (rendered (l_canvas.with_shape (create {SHAPE_AREA}.make (<<[-1.0, 0.0], [1.0, 1.0e-308], [1.0, -1.0], [-1.0, -1.0]>>, create {STYLE}, True)), 10, 5)).to_array)
		end

	test_chart_huge_bounds_place_points
			-- Bounds of +-1e308: the points 1e308, 0 and -1e308 land in the top-right cell, the middle
			-- and the bottom-left cell. Ratatui's `get_point` computes (x - left) * (width - 1) / width,
			-- which is infinity / infinity there, and casts the NaN to 0.
		local
			l_chart: TUI_CHART
			l_expected: ARRAY [READABLE_STRING_GENERAL]
		do
			l_expected := <<
				{STRING_32} "%/0x2502/" + spaces (18) + {STRING_32} "%/0x2022/",
				{STRING_32} "%/0x2502/" + spaces (19),
				{STRING_32} "%/0x2502/" + spaces (9) + {STRING_32} "%/0x2022/" + spaces (9),
				{STRING_32} "%/0x2502/%/0x2022/" + spaces (18),
				{STRING_32} "%/0x2514/" + repeated ('%/0x2500/', 19)>>
			l_chart := huge_chart (1.0e308, {CHART_GRAPH_TYPE}.scatter, {CANVAS_MARKER}.dot)
			assert_buffer_lines ("+-1e308", rendered (l_chart, 20, 5), l_expected)
			l_chart := huge_chart ({REAL_64}.max_value, {CHART_GRAPH_TYPE}.scatter, {CANVAS_MARKER}.dot)
			assert_buffer_lines ("+-max_value", rendered (l_chart, 20, 5), l_expected)
				-- A finite span up to 1e308: the point at the maximum is in the top-right cell
			l_chart := huge_chart (1.0e308, {CHART_GRAPH_TYPE}.scatter, {CANVAS_MARKER}.dot)
			l_chart.set_x_bounds (0.0, 1.0e308)
			l_chart.set_y_bounds (0.0, 1.0e308)
			assert_buffer_lines ("0 to 1e308", rendered (l_chart, 20, 5), <<
				{STRING_32} "%/0x2502/" + spaces (18) + {STRING_32} "%/0x2022/",
				{STRING_32} "%/0x2502/" + spaces (19),
				{STRING_32} "%/0x2502/" + spaces (19),
				{STRING_32} "%/0x2502/%/0x2022/" + spaces (18),
				{STRING_32} "%/0x2514/" + repeated ('%/0x2500/', 19)>>)
		end

	test_barchart_render_handles_u64_max_value
			-- Ratatui `render_handles_u64_max_value`: one bar of u64::MAX with max u64::MAX in 5 x 5,
			-- ["█    "; 5] (the value, 20 digits in a bar of 1, is hidden). Then the same without an
			-- explicit maximum (the largest value), and horizontally.
		local
			l_chart: TUI_BARCHART
		do
			l_chart := u64_chart (<<{NATURAL_64}.max_value>>).with_max_value ({NATURAL_64}.max_value)
			assert_buffer_lines ("explicit max", rendered (l_chart, 5, 5), <<
				{STRING_32} "%/0x2588/    ",
				{STRING_32} "%/0x2588/    ",
				{STRING_32} "%/0x2588/    ",
				{STRING_32} "%/0x2588/    ",
				{STRING_32} "%/0x2588/    ">>)
				-- Automatic maximum; MAX // 2 is 19 eighths of 5 rows (40 * (2^63 - 1) / (2^64 - 1))
			l_chart := u64_chart (<<{NATURAL_64}.max_value, {NATURAL_64}.max_value // 2>>)
			assert_buffer_lines ("automatic max", rendered (l_chart, 3, 5), <<
				{STRING_32} "%/0x2588/  ",
				{STRING_32} "%/0x2588/  ",
				{STRING_32} "%/0x2588/ %/0x2583/",
				{STRING_32} "%/0x2588/ %/0x2588/",
				{STRING_32} "%/0x2588/ %/0x2588/">>)
				-- Horizontal: an empty value text, so the bar alone shows
			l_chart := (create {TUI_BARCHART}).with_bars (<<create {BAR_ITEM}.make_with_text ("", {NATURAL_64}.max_value, "")>>)
				.with_max_value ({NATURAL_64}.max_value).with_bar_width (1).with_direction ({BAR_CHART_DIRECTION}.horizontal)
			assert_buffer_lines ("horizontal", rendered (l_chart, 5, 1), <<{STRING_32} "%/0x2588/%/0x2588/%/0x2588/%/0x2588/%/0x2588/">>)
		end

	test_barchart_render_keeps_integer_precision_for_large_values
			-- Ratatui `render_keeps_integer_precision_for_large_values`: u64::MAX - 1 with max u64::MAX
			-- in 1 x 1 is 7 eighths, "▇" (a REAL_64 ratio would round it to a full cell).
			-- Horizontally, in 5 columns, it is 4 cells, not 5.
		local
			l_chart: TUI_BARCHART
		do
			l_chart := u64_chart (<<{NATURAL_64}.max_value - 1>>).with_max_value ({NATURAL_64}.max_value)
			assert_buffer_lines ("vertical", rendered (l_chart, 1, 1), <<{STRING_32} "%/0x2587/">>)
			l_chart := (create {TUI_BARCHART}).with_bars (<<create {BAR_ITEM}.make_with_text ("", {NATURAL_64}.max_value - 1, "")>>)
				.with_max_value ({NATURAL_64}.max_value).with_bar_width (1).with_direction ({BAR_CHART_DIRECTION}.horizontal)
			assert_buffer_lines ("horizontal", rendered (l_chart, 5, 1), <<{STRING_32} "%/0x2588/%/0x2588/%/0x2588/%/0x2588/ ">>)
		end

	test_barchart_values_on_the_bars
			-- Ratatui `data` (10 x 3, bars "foo" 1 and "bar" 2, bar width 1): the values are written
			-- on the bars' bottom row, which has no row of its own. A value as wide as the bar shows
			-- only when the bar fills that cell ("1" over one eighth is hidden), and 0 shows nothing.
		local
			l_chart: TUI_BARCHART
		do
			l_chart := (create {TUI_BARCHART}).with_bars (<<create {BAR_ITEM}.make ("foo", 1), create {BAR_ITEM}.make ("bar", 2)>>).with_bar_width (1)
			assert_buffer_lines ("data", rendered (l_chart, 10, 3), <<
				{STRING_32} "  %/0x2588/       ",
				{STRING_32} "1 2       ",
				{STRING_32} "f b       ">>)
			l_chart := (create {TUI_BARCHART}).with_bars (<<create {BAR_ITEM}.make ("a", 1), create {BAR_ITEM}.make ("b", 8), create {BAR_ITEM}.make ("c", 0)>>).with_bar_width (1)
			assert_buffer_lines ("partial cell, zero", rendered (l_chart, 5, 2), <<
				{STRING_32} "%/0x2581/ 8  ",
				{STRING_32} "a b c">>)
		end

feature -- X3c: empty bar charts

	test_horizontal_empty_barchart_renders_block_only
			-- Ratatui `horizontal_empty_barchart_does_not_panic` (10 x 3, `BarChart::horizontal` with
			-- no bars) and `default`: nothing is drawn; with a block, the block alone. Vertical too.
		local
			l_chart: TUI_BARCHART
			l_blank, l_framed: ARRAY [READABLE_STRING_GENERAL]
		do
			l_blank := <<spaces (10), spaces (10), spaces (10)>>
			l_framed := <<
				{STRING_32} "%/0x250C/" + repeated ('%/0x2500/', 8) + {STRING_32} "%/0x2510/",
				{STRING_32} "%/0x2502/" + spaces (8) + {STRING_32} "%/0x2502/",
				{STRING_32} "%/0x2514/" + repeated ('%/0x2500/', 8) + {STRING_32} "%/0x2518/">>
			across <<{BAR_CHART_DIRECTION}.horizontal, {BAR_CHART_DIRECTION}.vertical>> as d loop
				create l_chart
				l_chart := l_chart.with_direction (d)
				assert_buffer_lines ("default", rendered (l_chart, 10, 3), l_blank)
				l_chart := l_chart.with_bars (create {ARRAYED_LIST [BAR_ITEM]}.make (0))
				assert_buffer_lines ("no bars", rendered (l_chart, 10, 3), l_blank)
				l_chart := l_chart.with_block (create {TUI_BLOCK}.make)
				assert_buffer_lines ("block only", rendered (l_chart, 10, 3), l_framed)
				l_chart := l_chart.with_groups (<<create {BAR_GROUP}.make_with_label ("G"), create {BAR_GROUP}.make>>)
				assert_buffer_lines ("empty groups, block only", rendered (l_chart, 10, 3), l_framed)
			end
		end

	test_constructors_ignore_empty_groups
			-- Ratatui `constructors_ignore_empty_groups`: `BarChart::new(vec![])` has no group, and
			-- an empty group before a group of one bar is dropped. EiffelTUI keeps the groups it is
			-- given by reference (a group can be filled after `append_group`), and an empty one is
			-- not part of the chart (`visible_groups`): no room, no label, no group gap.
		local
			l_chart: TUI_BARCHART
			l_one: BAR_GROUP
		do
			assert ("no bars, no group", (create {TUI_BARCHART}.make_with_data (create {ARRAYED_LIST [BAR_ITEM]}.make (0))).groups.is_empty)
			create l_one.make_with_bars (<<create {BAR_ITEM}.make ("", 1)>>)
			l_chart := (create {TUI_BARCHART}).with_bar_width (1)
				.with_groups (<<create {BAR_GROUP}.make_with_label ("E"), l_one>>)
			assert_buffer_lines ("vertical", rendered (l_chart, 5, 3), <<
				{STRING_32} "%/0x2588/    ",
				{STRING_32} "%/0x2588/    ",
				{STRING_32} "1    ">>)
			assert_buffer_lines ("vertical, as the group alone", rendered (l_chart, 5, 3),
				buffer_as_lines (rendered (l_chart.with_groups (<<l_one>>), 5, 3)).to_array)
			l_chart := l_chart.with_direction ({BAR_CHART_DIRECTION}.horizontal)
			assert_buffer_lines ("horizontal", rendered (l_chart, 5, 3), <<
				{STRING_32} "1%/0x2588/%/0x2588/%/0x2588/%/0x2588/",
				spaces (5),
				spaces (5)>>)
		end

	test_empty_groups_are_not_part_of_the_chart
			-- One rule for a group without bars, however it was added: it stays in `groups` but is
			-- not in `visible_groups`, is not drawn and is not compared, so two charts that draw the
			-- same are equal. An empty group added first and filled later is drawn from then on.
		local
			l_chart, l_plain: TUI_BARCHART
			l_one, l_late: BAR_GROUP
		do
			create l_one.make_with_bars (<<create {BAR_ITEM}.make ("", 1)>>)
			l_chart := (create {TUI_BARCHART}).with_bar_width (1)
				.with_groups (<<create {BAR_GROUP}.make_with_label ("E"), l_one>>)
			l_plain := (create {TUI_BARCHART}).with_bar_width (1).with_groups (<<l_one>>)
			assert ("kept in groups", l_chart.groups.count = 2)
			assert ("not visible", l_chart.visible_groups.count = 1 and l_chart.visible_groups.first = l_one)
			assert ("equal to the chart without it", l_chart.is_equal (l_plain) and l_plain.is_equal (l_chart))
			assert ("twin equal", l_chart.twin.is_equal (l_chart))

			create l_late.make_with_label ("L")
			l_plain.append_group (l_late)
			assert ("appended, not visible", l_plain.groups.count = 2 and l_plain.visible_groups.count = 1)
			assert ("still equal", l_plain.is_equal (l_chart))
			assert_buffer_lines ("empty group not drawn", rendered (l_plain, 5, 3), <<
				{STRING_32} "%/0x2588/    ",
				{STRING_32} "%/0x2588/    ",
				{STRING_32} "1    ">>)
			l_late.append_bar (create {BAR_ITEM}.make ("", 1))
			assert ("visible once filled", l_plain.visible_groups.count = 2 and l_plain.visible_groups.last = l_late)
			assert ("no longer equal", not l_plain.is_equal (l_chart))
				-- Group gap 2 after the first group; the second group's label row appears
			assert_buffer_lines ("filled group drawn", rendered (l_plain, 5, 3), <<
				{STRING_32} "%/0x2588/  %/0x2588/ ",
				{STRING_32} "1  1 ",
				{STRING_32} "   L ">>)
		end

feature {NONE} -- Helpers

	rendered (a_widget: WIDGET; a_width, a_height: INTEGER): BUFFER
			-- `a_widget` rendered into a new `a_width` x `a_height` buffer
		do
			create Result.make (a_width, a_height)
			a_widget.render (Result.area, Result)
		end

	huge_chart (a_limit: REAL_64; a_type: NATURAL_8; a_marker: NATURAL_8): TUI_CHART
			-- Chart with bounds -`a_limit`..`a_limit` on both axes and one dataset of `a_type`
			-- through (-`a_limit`, -`a_limit`), (0, 0) and (`a_limit`, `a_limit`)
		local
			l_data: TUI_CHART_DATASET
		do
			create l_data.make ("huge")
			l_data.append_point (- a_limit, - a_limit)
			l_data.append_point (0.0, 0.0)
			l_data.append_point (a_limit, a_limit)
			l_data.set_graph_type (a_type)
			l_data.set_marker (a_marker)
			create Result.make_with_datasets (<<l_data>>)
			Result.set_x_bounds (- a_limit, a_limit)
			Result.set_y_bounds (- a_limit, a_limit)
		end

	u64_chart (a_values: ARRAY [NATURAL_64]): TUI_BARCHART
			-- Vertical bar chart of unlabelled bars of `a_values`, one column wide, as Ratatui's
			-- `BarChart::new` (bar width 1)
		local
			l_bars: ARRAYED_LIST [BAR_ITEM]
		do
			create l_bars.make (a_values.count)
			across a_values as v loop
				l_bars.extend (create {BAR_ITEM}.make ("", v))
			end
			Result := (create {TUI_BARCHART}).with_bars (l_bars).with_bar_width (1)
		end

	spaces (n: INTEGER): STRING_32
			-- `n` spaces
		do
			Result := repeated (' ', n)
		end

	repeated (c: CHARACTER_32; n: INTEGER): STRING_32
			-- `c` repeated `n` times
		do
			create Result.make_filled (c, n)
		end

end
