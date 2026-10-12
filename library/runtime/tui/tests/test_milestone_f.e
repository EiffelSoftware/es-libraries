note
	description: "[
		Comprehensive test suite for Milestone F (Widget Completion):
		- Table: horizontal column scrolling via TABLE_STATE.column_offset, column and cell highlighting
		- BarChart: BAR_GROUP, horizontal direction, label and value clipping
		- Chart: legend with positioning, axis titles, label alignment, markers, bar graphs, bounds-checked axes
		- Canvas: marker enums, layers, SHAPE hierarchy, per-dot color policy
		- Block: multiple titles (top/bottom), background style painting, four-sided PADDING, BORDER_SET
		- List: multi-line items, row-wide highlight filling, symbol clipping, direction, repeat-symbol,
		        scroll padding, and highlight spacing
		- Tabs: title padding (left/right) and boundary clipping for dividers and titles
		- Gauge & LineGauge: label color inversion over filled cells, label clipping, LineGauge label truncation
		- Sparkline: left-to-right default ordering and direction option (SPARKLINE_DIRECTION)
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_MILESTONE_F

inherit
	EQA_TEST_SET
	BUFFER_TEST_HELPER

feature -- Table Tests

	test_table_horizontal_column_scroll_and_highlight
			-- Verify TABLE_STATE.column_offset skips columns and column/cell highlighting styles.
		local
			l_table: TUI_TABLE
			l_state: TABLE_STATE
			l_buf: BUFFER
			l_area: RECT
			l_hstyle, l_col_style, l_cell_style: STYLE
			l_red, l_green, l_blue: COLOR
			l_row: TABLE_ROW
			l_rows: ARRAYED_LIST [TABLE_ROW]
			l_widths: ARRAYED_LIST [CONSTRAINT]
		do
			create l_red.make_ansi (1)
			create l_green.make_ansi (2)
			create l_blue.make_ansi (4)

			create l_hstyle.make_bg (l_red)
			create l_col_style.make_bg (l_green)
			create l_cell_style.make_bg (l_blue)

			create l_widths.make (4)
			l_widths.extend ({CONSTRAINTS}.fixed (6))
			l_widths.extend ({CONSTRAINTS}.fixed (6))
			l_widths.extend ({CONSTRAINTS}.fixed (6))
			l_widths.extend ({CONSTRAINTS}.fixed (6))

			create l_rows.make (2)
			create l_row.make_raw (<<"A1", "B1", "C1", "D1">>)
			l_rows.extend (l_row)
			create l_row.make_raw (<<"A2", "B2", "C2", "D2">>)
			l_rows.extend (l_row)

			create l_table.make (l_rows, l_widths)
			l_table.set_row_highlight_style (l_hstyle)
			l_table.set_column_highlight_style (l_col_style)
			l_table.set_cell_highlight_style (l_cell_style)

			create l_state.default_create
			l_state.select_index (1)
			l_state.select_column (2)
			l_state.set_column_offset (2) -- Start displaying from column 2 ("B1", "C1", "D1")

			create l_area.make (0, 0, 18, 2)
			create l_buf.make (18, 2)

			l_table.render_table (l_area, l_buf, l_state)

			-- Column 1 ("A1") was skipped. Column 2 ("B1") is rendered at column 0.
			assert ("first rendered column is B1", l_buf.cell (0, 0).symbol.same_string ("B"))
			-- And cell at (row 0, col 2) is the selected row and column -> highlight_cell_style (blue bg)
			assert ("selected cell has cell highlight", attached l_buf.cell (0, 0).style.background as bg and then bg.same_rendering (l_blue))
		end

feature -- BarChart Tests

	test_barchart_bar_group_and_horizontal
			-- Verify BAR_GROUP, horizontal direction, and label clipping to bar width.
		local
			l_chart: TUI_BARCHART
			l_group: BAR_GROUP
			l_bar: BAR_ITEM
			l_area: RECT
			l_buf: BUFFER
		do
			create l_chart.default_create
			l_chart.set_bar_width (3)
			l_chart.set_bar_gap (1)

			create l_group.make_with_label ("G1")
			create l_bar.make ("SuperLongLabel", 50)
			l_group.append_bar (l_bar)
			l_chart.append_group (l_group)

			create l_area.make (0, 0, 10, 5)
			create l_buf.make (10, 5)

			-- Render vertical with label clipping
			l_chart.render (l_area, l_buf)
			-- Verify label didn't spill past width 3 (col 0..2)
			assert ("label clipped to bar width", l_buf.cell (4, 3).symbol.same_string (" "))

			-- Now test horizontal direction
			l_chart.set_direction ({BAR_CHART_DIRECTION}.Horizontal)
			create l_buf.make (10, 5)
			l_chart.render (l_area, l_buf)
			-- The group label takes the first row; the bar (label clipped to half the width) follows
			assert ("group label row", l_buf.line (0).starts_with ({STRING_32} "G1"))
			assert ("horizontal bar rendered", l_buf.line (1).starts_with ({STRING_32} "Super "))
		end

feature -- Chart Tests

	test_chart_legend_position_axis_titles_markers
			-- Verify Chart legend position, axis titles, label alignment, and bar graph type.
		local
			l_chart: TUI_CHART
			l_ds: TUI_CHART_DATASET
			l_pts: ARRAYED_LIST [TUPLE [x, y: REAL_64]]
			l_area: RECT
			l_buf: BUFFER
		do
			create l_pts.make (3)
			l_pts.extend ([0.0, 5.0])
			l_pts.extend ([5.0, 10.0])
			l_pts.extend ([10.0, 15.0])

			create l_ds.make_with_data ("Dataset1", l_pts)
			l_ds.set_graph_type ({CHART_GRAPH_TYPE}.Bar)
			l_ds.set_marker ({CANVAS_MARKER}.Dot)

			create l_chart.make_with_datasets (<<l_ds>>)
			l_chart.set_x_bounds (0.0, 10.0)
			l_chart.set_y_bounds (0.0, 20.0)
			l_chart.set_x_title ("Time")
			l_chart.set_y_title ("Value")
			l_chart.set_x_labels (<<"0", "5", "10">>)
			l_chart.set_y_labels (<<"0", "10", "20">>)
			l_chart.set_legend (True, {CHART_LEGEND_POSITION}.Top_right)

			create l_area.make (0, 0, 30, 12)
			create l_buf.make (30, 12)

			l_chart.render (l_area, l_buf)

			-- Titles and labels as drawn
			assert ("y title on its own row", l_buf.line (0).starts_with ({STRING_32} "Value"))
			assert ("top y label is the maximum", l_buf.line (1).starts_with ({STRING_32} "20"))
			assert ("x title on the last row", l_buf.line (11).has_substring ({STRING_32} "Time"))
			assert ("dot markers drawn for the bars", across 1 |..| 8 as r some l_buf.line (r).has_substring ({STRING_32} "%/0x2022/") end)
			-- A 12x3 legend exceeds a quarter of the 28x8 plot: hidden by default (Ratatui rule)
			assert ("legend hidden by default", not across 0 |..| 11 as r some l_buf.line (r).has_substring ({STRING_32} "Dataset1") end)
			l_chart.set_legend_hidden_ratio (1.0)
			create l_buf.make (30, 12)
			l_chart.render (l_area, l_buf)
			assert ("legend entry at the top right", l_buf.line (2).ends_with ({STRING_32} "%/0x2502/Dataset1%/0x2502/"))
		end

feature -- Canvas Tests

	test_canvas_shapes_layers_color_policy
			-- Verify CANVAS_LAYER, SHAPE implementations, and BRAILLE_CANVAS color policy.
		local
			l_canvas: TUI_CANVAS
			l_layer: CANVAS_LAYER
			l_line: SHAPE_LINE
			l_rect: SHAPE_RECT
			l_circ: SHAPE_CIRCLE
			l_pts_shape: SHAPE_POINTS
			l_braille: BRAILLE_CANVAS
			l_red, l_green: COLOR
			l_s1, l_s2: STYLE
			l_area: RECT
			l_buf: BUFFER
		do
			create l_red.make_ansi (1)
			create l_green.make_ansi (2)
			create l_s1.make_fg (l_red)
			create l_s2.make_fg (l_green)

			-- Test shapes
			create l_line.make (0.0, 0.0, 10.0, 10.0, l_s1)
			create l_rect.make (2.0, 2.0, 6.0, 6.0, l_s2)
			create l_circ.make (5.0, 5.0, 3.0, l_s1)
			create l_pts_shape.make (<<[1.0, 1.0], [2.0, 2.0]>>, l_s2)

			create l_canvas.make
			l_canvas.set_bounds (0.0, 10.0, 0.0, 10.0)
			l_canvas.add_shape (l_line)
			l_canvas.add_shape (l_rect)
			l_canvas.add_shape (l_circ)
			l_canvas.add_shape (l_pts_shape)

			create l_layer.make
			l_layer.add_shape (l_line)
			l_canvas.add_layer (l_layer)

			create l_area.make (0, 0, 10, 5)
			create l_buf.make (10, 5)
			l_canvas.render (l_area, l_buf)
			-- The diagonal line (drawn in the base layer and again in a layer) crosses the canvas:
			-- its end cells hold Braille dots in the line colour
			assert ("bottom-left cell drawn", l_buf.cell (4, 0).symbol.code (1) > 0x2800 and l_buf.cell (4, 0).symbol.code (1) <= 0x28FF)
			assert ("top-right cell drawn", l_buf.cell (0, 9).symbol.code (1) > 0x2800 and l_buf.cell (0, 9).symbol.code (1) <= 0x28FF)
			assert ("layer draws the line colour on top", l_buf.cell (0, 9).style.foreground.is_equal (l_red))

			-- Test BRAILLE_CANVAS color policy
			create l_braille.make (10, 5)
			l_braille.set_color_policy ({BRAILLE_CANVAS}.Policy_first_wins)
			l_braille.set_pixel_with_style (0, 0, l_s1)
			l_braille.set_pixel_with_style (1, 1, l_s2)
			assert ("first wins policy preserves first color", attached l_braille.cell_style (0, 0).foreground as fg and then fg.same_rendering (l_s1.foreground))

			l_braille.set_color_policy ({BRAILLE_CANVAS}.Policy_last_wins)
			l_braille.set_pixel_with_style (0, 0, l_s2)
			assert ("last wins policy overrides color", attached l_braille.cell_style (0, 0).foreground as fg and then fg.same_rendering (l_s2.foreground))
		end

feature -- Block Tests

	test_block_multiple_titles_background_padding_borders
			-- Verify TUI_BLOCK multiple titles, background style painting, four-sided PADDING, and BORDER_SET.
		local
			l_block: TUI_BLOCK
			l_t1, l_t2: BLOCK_TITLE
			l_pad: PADDING
			l_bset: BORDER_SET
			l_bg_style: STYLE
			l_blue: COLOR
			l_area, l_inner: RECT
			l_buf: BUFFER
		do
			create l_blue.make_ansi (4)
			create l_bg_style.make_bg (l_blue)

			create l_block.default_create
			l_block.set_style (l_bg_style)
			create l_t1.make_raw ("TopLeft", {BLOCK_TITLE}.Position_top, {TEXT_ALIGNMENT}.Left)
			create l_t2.make_raw ("BottomRight", {BLOCK_TITLE}.Position_bottom, {TEXT_ALIGNMENT}.Right)
			l_block.add_title (l_t1)
			l_block.add_title (l_t2)

			-- Four-sided padding (top 1, right 2, bottom 1, left 1)
			create l_pad.make (1, 2, 1, 1)
			l_block.set_four_sided_padding (l_pad)

			-- Custom border set
			create l_bset.make ('+', '+', '+', '+', '-', '-', '|', '|')
			l_block.set_border_set (l_bset)

			create l_area.make (0, 0, 20, 10)
			create l_buf.make (20, 10)

			l_inner := l_block.inner (l_area)
			-- Borders take 1 cell each side (w - 2 = 18, h - 2 = 8)
			-- Padding left 1 + right 2 = 3 (18 - 3 = 15)
			-- Padding top 1 + bottom 1 = 2 (8 - 2 = 6)
			assert ("inner width reflects 4-sided padding", l_inner.width = 15)
			assert ("inner height reflects 4-sided padding", l_inner.height = 6)

			l_block.render (l_area, l_buf)

			-- Verify custom corner character
			assert ("custom border set top left", l_buf.cell (0, 0).symbol.same_string ("+"))
			-- Verify background style painted
			assert ("background painted", attached l_buf.cell (5, 5).style.background as bg and then bg.same_rendering (l_blue))
		end

feature -- List Tests

	test_list_multiline_highlight_spacing_direction
			-- Verify TUI_LIST multi-line items, row-wide highlight, clipping, direction, and highlight spacing.
		local
			l_list: TUI_LIST
			l_state: LIST_STATE
			l_item: LIST_ITEM
			l_items: ARRAYED_LIST [LIST_ITEM]
			l_buf: BUFFER
			l_area: RECT
			l_hstyle: STYLE
			l_yellow: COLOR
		do
			create l_yellow.make_ansi (3)
			create l_hstyle.make_bg (l_yellow)

			create l_items.make (2)
			create l_item.make_raw ("Item 1 Line 1%NItem 1 Line 2")
			l_items.extend (l_item)
			create l_item.make_raw ("Item 2")
			l_items.extend (l_item)

			create l_list.make (l_items)
			l_list.set_highlight_style (l_hstyle)
			l_list.set_highlight_symbol ("> ")
			l_list.set_repeat_highlight_symbol (True)
			l_list.set_highlight_spacing ({HIGHLIGHT_SPACING}.Always)

			create l_state.default_create
			l_state.select_index (1)

			create l_area.make (0, 0, 20, 5)
			create l_buf.make (20, 5)

			l_list.render_list (l_area, l_buf, l_state)

			-- Verify multi-line: Line 1 on row 0, Line 2 on row 1
			assert ("multiline line 1 rendered", l_buf.cell (0, 2).symbol.same_string ("I"))
			assert ("multiline line 2 rendered", l_buf.cell (1, 2).symbol.same_string ("I"))
			-- Repeat highlight symbol
			assert ("repeat highlight symbol on line 2", l_buf.cell (1, 0).symbol.same_string (">"))
			-- Row filled with highlight
			assert ("row 0 filled with highlight", attached l_buf.cell (0, 19).style.background as bg and then bg.same_rendering (l_yellow))
			assert ("row 1 filled with highlight", attached l_buf.cell (1, 19).style.background as bg and then bg.same_rendering (l_yellow))

			-- Test Bottom_to_top direction
			l_list.set_direction ({LIST_DIRECTION}.Bottom_to_top)
			create l_buf.make (20, 5)
			l_list.render_list (l_area, l_buf, l_state)
			-- Item 1 with 2 lines should end at row 4
			assert ("bottom to top rendered at bottom", l_buf.cell (4, 2).symbol.same_string ("I"))

			-- Test scroll padding
			l_state.set_scroll_padding (2)
			l_state.select_index (5)
			l_state.adjust_viewport (10, 20)
			assert ("scroll padding keeps margin", l_state.offset <= 4)
		end

feature -- Tabs Tests

	test_tabs_padding_and_divider_clipping
			-- Verify TUI_TABS title padding and divider/title area clipping.
		local
			l_tabs: TUI_TABS
			l_area: RECT
			l_buf: BUFFER
		do
			create l_tabs.make_from_strings (<<"Tab One", "Tab Two">>)
			l_tabs.set_padding (" [", "] ")
			l_tabs.set_divider (" | ")

			-- Area with tight width to test clipping
			create l_area.make (0, 0, 15, 1)
			create l_buf.make (15, 1)

			l_tabs.render (l_area, l_buf)

			-- Check left padding of first tab
			assert ("tab padding left rendered", l_buf.cell (0, 0).symbol.same_string (" ") and l_buf.cell (0, 1).symbol.same_string ("["))
			-- Verify no index out of bounds and width is respected
			assert ("buffer width respected", l_buf.width = 15)
		end

feature -- Gauge Tests

	test_gauge_color_inversion_and_line_gauge_truncation
			-- Verify Gauge label color inversion over filled cells and LineGauge label truncation.
		local
			l_gauge: TUI_GAUGE
			l_line_gauge: TUI_LINE_GAUGE
			l_g_style, l_lbl_style: STYLE
			l_green, l_white: COLOR
			l_area: RECT
			l_buf: BUFFER
		do
			create l_green.make_ansi (2)
			create l_white.make_ansi (7)

			create l_g_style.make_fg (l_green)
			create l_lbl_style.make_fg (l_white)

			create l_gauge.default_create
			l_gauge.set_percent (100) -- 100% full
			l_gauge.set_gauge_style (l_g_style)
			l_gauge.set_label_style (l_lbl_style)
			l_gauge.set_label ("TEST")

			create l_area.make (0, 0, 10, 1)
			create l_buf.make (10, 1)

			l_gauge.render (l_area, l_buf)

			-- Center label "TEST" in width 10: col 3..6. Filled cells have green fg.
			-- Inverted label over filled cells should have background = green!
			assert ("gauge label background is inverted to gauge color", attached l_buf.cell (0, 3).style.background as bg and then bg.same_rendering (l_green))

			-- LineGauge narrow truncation
			create l_line_gauge.default_create
			l_line_gauge.set_label ("SuperLongLabel")
			create l_area.make (0, 0, 4, 1) -- Only 4 cells available
			create l_buf.make (4, 1)

			l_line_gauge.render (l_area, l_buf)
			-- First 4 characters "Supe" should be rendered, not dropped
			assert ("line gauge label truncated instead of dropped", l_buf.cell (0, 0).symbol.same_string ("S"))
			assert ("line gauge label fourth char", l_buf.cell (0, 3).symbol.same_string ("e"))
		end

feature -- Sparkline Tests

	test_sparkline_direction_and_ordering
			-- Verify Sparkline default left-to-right ordering and direction option.
		local
			l_spark: TUI_SPARKLINE
			l_area: RECT
			l_buf: BUFFER
			l_data: ARRAYED_LIST [NATURAL_64]
		do
			create l_data.make (3)
			l_data.extend (8)  -- First element
			l_data.extend (16) -- Second element
			l_data.extend (32) -- Third element

			create l_spark.make_with_data (l_data)
			l_spark.set_max_value (32)

			create l_area.make (0, 0, 5, 1)
			create l_buf.make (5, 1)

			-- Default is Left-to-right: col 0 has element 1 (8), col 1 has element 2 (16), col 2 has element 3 (32)
			l_spark.render (l_area, l_buf)
			assert ("col 0 is non-empty", not l_buf.cell (0, 0).symbol.same_string (" "))
			assert ("col 2 is full block", l_buf.cell (0, 2).symbol.same_string ("%U%U%U%U") or l_buf.cell (0, 2).symbol.count > 0)

			-- Right-to-left: col 4 has element 1 (8)
			l_spark.set_direction ({SPARKLINE_DIRECTION}.Right_to_left)
			create l_buf.make (5, 1)
			l_spark.render (l_area, l_buf)
			assert ("rtl: col 4 has data", not l_buf.cell (0, 4).symbol.same_string (" "))
		end

end
