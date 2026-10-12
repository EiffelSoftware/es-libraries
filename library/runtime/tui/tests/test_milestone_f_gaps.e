note
	description: "[
		Tests for the Milestone F gaps closed after the review (2026-09-27), all as buffer snapshots:
		- Table: columns clipped (not compressed) with auto-scroll to the selected column;
		  row/column/cell highlights applied after the cells, over the full row
		- BarChart: groups in both directions, group labels, maximum from the groups,
		  vertical values hidden when they do not fit
		- Canvas/Chart: stacked layers, marker resolutions, markers for every graph type,
		  bars from 0, legend border and hiding, circle radius per axis, clipped text
		- Block: several titles on one side laid out one after another
		- Gauge: explicit label foreground kept over the fill; wide characters clipped
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_MILESTONE_F_GAPS

inherit
	EQA_TEST_SET
	BUFFER_TEST_HELPER

feature -- Table

	test_table_clips_columns_and_scrolls_right
			-- Four Fixed (4) columns in 12 cells: two fit (4 + 1 + 4); selecting column 4 scrolls
			-- right so that columns 3 and 4 are shown, each at its full width.
		local
			l_buf: BUFFER
			l_table: TUI_TABLE
			l_state: TABLE_STATE
		do
			l_table := four_column_table
			create l_state.make
			create l_buf.make (12, 1)
			l_table.render_table (l_buf.area, l_buf, l_state)
			assert_buffer_lines ("first two columns", l_buf, <<"a1   b1     ">>)

			l_state.select_column (4)
			create l_buf.make (12, 1)
			l_table.render_table (l_buf.area, l_buf, l_state)
			assert ("scrolled right", l_state.column_offset = 3)
			assert_buffer_lines ("columns 3 and 4", l_buf, <<"c1   d1     ">>)

			l_state.select_column (1)
			create l_buf.make (12, 1)
			l_table.render_table (l_buf.area, l_buf, l_state)
			assert ("scrolled back", l_state.column_offset = 1)
		end

	test_table_highlights_win_over_cell_styles
			-- The row highlight covers the whole row (gaps included) and overrides a cell's own
			-- background; the column highlight covers the body rows only; the cell highlight wins
			-- at the intersection.
		local
			l_buf: BUFFER
			l_table: TUI_TABLE
			l_state: TABLE_STATE
			l_cell: TABLE_CELL
		do
			create l_table.make_empty
			l_table.set_header (create {TABLE_ROW}.make_raw (<<"H1", "H2">>))
			create l_cell.make_styled ("x", create {STYLE}.make_bg ({COLOR}.green))
			l_table.append_row (create {TABLE_ROW}.make (<<l_cell, create {TABLE_CELL}.make_raw ("y")>>))
			l_table.append_row (create {TABLE_ROW}.make_raw (<<"p", "q">>))
			l_table.set_widths (<<{CONSTRAINTS}.fixed (3), {CONSTRAINTS}.fixed (3)>>)
			l_table.set_row_highlight_style (create {STYLE}.make_bg ({COLOR}.blue))
			l_table.set_column_highlight_style (create {STYLE}.make_bg ({COLOR}.yellow))
			l_table.set_cell_highlight_style (create {STYLE}.make_bg ({COLOR}.red))
			create l_state.make
			l_state.select_index (1)
			l_state.select_column (2)
			create l_buf.make (8, 3)
			l_table.render_table (l_buf.area, l_buf, l_state)

			assert ("row highlight beats the cell's own style", l_buf.cell (1, 0).style.background.is_equal ({COLOR}.blue))
			assert ("row highlight covers the gap", l_buf.cell (1, 3).style.background.is_equal ({COLOR}.blue))
			assert ("row highlight covers the rest of the row", l_buf.cell (1, 7).style.background.is_equal ({COLOR}.blue))
			assert ("cell highlight at the intersection", l_buf.cell (1, 4).style.background.is_equal ({COLOR}.red))
			assert ("column highlight on the other body row", l_buf.cell (2, 4).style.background.is_equal ({COLOR}.yellow))
			assert ("header not column-highlighted", l_buf.cell (0, 4).style.background.renders_as_default)
			assert ("unselected cell keeps its style", l_buf.cell (2, 0).style.background.renders_as_default)
		end

feature -- BarChart

	test_barchart_vertical_groups_and_group_labels
			-- Two groups (group gap 2): bars, centred values, labels and centred group labels.
		local
			l_buf: BUFFER
			l_chart: TUI_BARCHART
			g1, g2: BAR_GROUP
		do
			create g1.make_with_bars (<<create {BAR_ITEM}.make ("a", 4), create {BAR_ITEM}.make ("b", 8)>>)
			g1.set_label ("G1")
			create g2.make_with_bars (<<create {BAR_ITEM}.make ("c", 8)>>)
			g2.set_label ("G2")
			create l_chart.make
			l_chart.set_groups (<<g1, g2>>)
			create l_buf.make (12, 5)
			l_chart.render (l_buf.area, l_buf)
			assert_buffer_lines ("grouped vertical chart", l_buf, <<
				{STRING_32} "    %/0x2588/%/0x2588/%/0x2588/  %/0x2588/%/0x2588/%/0x2588/",
				{STRING_32} "%/0x2588/%/0x2588/%/0x2588/ %/0x2588/%/0x2588/%/0x2588/  %/0x2588/%/0x2588/%/0x2588/",
				" 4   8    8 ",
				" a   b    c ",
				"  G1     G2 "
			>>)
		end

	test_barchart_max_follows_group_changes
			-- A bar added to a group after `append_group` is part of the scaling (no stale copy).
		local
			l_buf: BUFFER
			l_chart: TUI_BARCHART
			l_group: BAR_GROUP
		do
			create l_group.make_with_bars (<<create {BAR_ITEM}.make ("a", 10)>>)
			create l_chart.make
			l_chart.append_group (l_group)
			l_group.append_bar (create {BAR_ITEM}.make ("b", 20))
			l_chart.set_direction ({BAR_CHART_DIRECTION}.horizontal)
			l_chart.set_bar_width (1)
			create l_buf.make (10, 3)
			l_chart.render (l_buf.area, l_buf)
			assert_buffer_lines ("half and full bars", l_buf, <<
				{STRING_32} "a %/0x2588/%/0x2588/%/0x2588/%/0x2588/ 10 ",
				"          ",
				{STRING_32} "b 20%/0x2588/%/0x2588/%/0x2588/%/0x2588/%/0x2588/%/0x2588/"
			>>)
		end

	test_barchart_hides_values_wider_than_the_bar
			-- 1234 does not fit a 3-wide bar: the value row stays empty instead of showing "123".
		local
			l_buf: BUFFER
			l_chart: TUI_BARCHART
		do
			create l_chart.make_with_data (<<create {BAR_ITEM}.make ("x", 1234)>>)
			create l_buf.make (3, 3)
			l_chart.render (l_buf.area, l_buf)
			assert_buffer_lines ("value hidden", l_buf, <<{STRING_32} "%/0x2588/%/0x2588/%/0x2588/", "   ", " x ">>)
		end

feature -- Canvas

	test_canvas_layers_stack
			-- A later layer replaces the cells it draws in (glyph and colour); its empty cells
			-- leave the layer below visible.
		local
			l_buf: BUFFER
			l_canvas: TUI_CANVAS
			l_layer: CANVAS_LAYER
		do
			create l_canvas.make
			l_canvas.set_bounds (0.0, 2.0, 0.0, 1.0)
			l_canvas.set_marker ({CANVAS_MARKER}.block)
			l_canvas.add_shape (create {SHAPE_POINTS}.make (<<[0.0, 0.0], [1.0, 0.0]>>, create {STYLE}.make_fg ({COLOR}.red)))
			create l_layer.make_with_shapes (<<create {SHAPE_POINTS}.make (<<[1.0, 0.0]>>, create {STYLE}.make_fg ({COLOR}.blue))>>)
			l_layer.set_marker ({CANVAS_MARKER}.dot)
			l_canvas.add_layer (l_layer)
			create l_buf.make (3, 1)
			l_canvas.render (l_buf.area, l_buf)
			assert_buffer_lines ("base block, layer dot on top, empty cell", l_buf, <<{STRING_32} "%/0x2588/%/0x2022/ ">>)
			assert ("base colour", l_buf.cell (0, 0).style.foreground.is_equal ({COLOR}.red))
			assert ("layer colour replaces", l_buf.cell (0, 1).style.foreground.is_equal ({COLOR}.blue))
		end

	test_canvas_half_block_resolution
			-- HalfBlock has two dots per cell: upper half, lower half, or both.
		do
			assert_buffer_lines ("upper", half_block_canvas (<<[0.0, 1.0]>>), <<{STRING_32} "%/0x2580/">>)
			assert_buffer_lines ("lower", half_block_canvas (<<[0.0, 0.0]>>), <<{STRING_32} "%/0x2584/">>)
			assert_buffer_lines ("both", half_block_canvas (<<[0.0, 1.0], [0.0, 0.0]>>), <<{STRING_32} "%/0x2588/">>)
		end

	test_canvas_text_clipped_to_area
			-- Text drawn on the canvas does not spill outside the canvas area.
		local
			l_buf: BUFFER
			l_canvas: TUI_CANVAS
		do
			create l_canvas.make
			l_canvas.set_painter (agent (p: CANVAS_PAINTER) do p.draw_text (0.0, 1.0, "abcdef", create {STYLE}) end)
			create l_buf.make (8, 1)
			l_canvas.render (create {RECT}.make (0, 0, 4, 1), l_buf)
			assert_buffer_lines ("clipped at the canvas edge", l_buf, <<"abcd    ">>)
		end

feature -- Chart

	test_chart_line_uses_marker
			-- The dataset marker applies to line graphs too: a Block-marker line draws full blocks,
			-- no Braille.
		local
			l_buf: BUFFER
			l_chart: TUI_CHART
			l_data: TUI_CHART_DATASET
			l_blocks, l_braille: INTEGER
			r, c: INTEGER
		do
			create l_data.make ("line")
			l_data.append_point (0.0, 0.0)
			l_data.append_point (10.0, 10.0)
			l_data.set_marker ({CANVAS_MARKER}.block)
			create l_chart.make_with_datasets (<<l_data>>)
			l_chart.set_x_bounds (0.0, 10.0)
			l_chart.set_y_bounds (0.0, 10.0)
			create l_buf.make (12, 6)
			l_chart.render (l_buf.area, l_buf)
			from r := 0 until r >= 5 loop
				from c := 1 until c >= 12 loop
					if l_buf.cell (r, c).symbol.same_string ({STRING_32} "%/0x2588/") then
						l_blocks := l_blocks + 1
					elseif l_buf.cell (r, c).symbol.code (1) >= 0x2800 and l_buf.cell (r, c).symbol.code (1) <= 0x28FF then
						l_braille := l_braille + 1
					end
					c := c + 1
				end
				r := r + 1
			end
			assert ("line drawn with blocks", l_blocks >= 5)
			assert ("no braille", l_braille = 0)
		end

	test_chart_bars_rise_from_zero
			-- With y bounds [-10, 10] a bar of 5 fills from 0 up, not from -10.
		local
			l_buf: BUFFER
			l_chart: TUI_CHART
			l_data: TUI_CHART_DATASET
		do
			create l_data.make ("bars")
			l_data.append_point (5.0, 5.0)
			l_data.set_graph_type ({CHART_GRAPH_TYPE}.bar)
			l_data.set_marker ({CANVAS_MARKER}.block)
			create l_chart.make_with_datasets (<<l_data>>)
			l_chart.set_x_bounds (0.0, 10.0)
			l_chart.set_y_bounds (-10.0, 10.0)
			create l_buf.make (11, 11)
			l_chart.render (l_buf.area, l_buf)
			assert ("bar above zero", l_buf.cell (3, 6).symbol.same_string ({STRING_32} "%/0x2588/"))
			assert ("nothing below zero", l_buf.cell (8, 6).symbol.same_string ({STRING_32} " "))
		end

	test_chart_legend_border_and_hiding
			-- The legend is a bordered box with the dataset names; by default (Ratatui's 1/4 rule)
			-- it is hidden when too large for the plot.
		local
			l_buf: BUFFER
			l_chart: TUI_CHART
			l_data: TUI_CHART_DATASET
		do
			create l_data.make ("sin")
			l_data.append_point (0.0, 0.0)
			create l_chart.make_with_datasets (<<l_data>>)
			l_chart.set_x_bounds (0.0, 10.0)
			l_chart.set_y_bounds (0.0, 10.0)
			l_chart.set_legend (True, {CHART_LEGEND_POSITION}.top_right)
			create l_buf.make (20, 8)
			l_chart.render (l_buf.area, l_buf)
			assert ("hidden: 5x3 exceeds a quarter of the 19x7 plot", l_buf.line (0).substring (16, 20).same_string ({STRING_32} "     "))

			l_chart.set_legend_hidden_ratio (1.0)
			create l_buf.make (20, 8)
			l_chart.render (l_buf.area, l_buf)
			assert ("legend top border", l_buf.line (0).substring (16, 20).same_string ({STRING_32} "%/0x250C/%/0x2500/%/0x2500/%/0x2500/%/0x2510/"))
			assert ("legend entry", l_buf.line (1).substring (16, 20).same_string ({STRING_32} "%/0x2502/sin%/0x2502/"))
			assert ("legend bottom border", l_buf.line (2).substring (16, 20).same_string ({STRING_32} "%/0x2514/%/0x2500/%/0x2500/%/0x2500/%/0x2518/"))
		end

feature -- Block and Gauge

	test_block_titles_laid_out_per_side
			-- Titles sharing a side and alignment follow each other with one cell between them;
			-- left, centre and right groups each take their place.
		local
			l_buf: BUFFER
			l_block: TUI_BLOCK
		do
			create l_block.make
			l_block := l_block.with_title_top ("A", {TEXT_ALIGNMENT}.left)
				.with_title_top ("B", {TEXT_ALIGNMENT}.left)
				.with_title_top ("C", {TEXT_ALIGNMENT}.center)
				.with_title_top ("R", {TEXT_ALIGNMENT}.right)
				.with_title_bottom ("x", {TEXT_ALIGNMENT}.right)
				.with_title_bottom ("y", {TEXT_ALIGNMENT}.right)
			create l_buf.make (14, 3)
			l_block.render (l_buf.area, l_buf)
			assert_buffer_lines ("titles laid out", l_buf, <<
				{STRING_32} "%/0x250C/A%/0x2500/B%/0x2500/%/0x2500/C%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/R%/0x2510/",
				{STRING_32} "%/0x2502/            %/0x2502/",
				{STRING_32} "%/0x2514/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/x%/0x2500/y%/0x2518/"
			>>)
		end

	test_gauge_label_keeps_explicit_colour
			-- Over the filled part an explicit label foreground wins over the inverted colours.
		local
			l_buf: BUFFER
			l_gauge: TUI_GAUGE
		do
			create l_gauge.make
			l_gauge.set_percent (100)
			l_gauge.set_gauge_style (create {STYLE}.make_with_colors ({COLOR}.green, {COLOR}.black))
			l_gauge.set_label_style (create {STYLE}.make_fg ({COLOR}.white))
			create l_buf.make (6, 1)
			l_gauge.render (l_buf.area, l_buf)
			assert ("label over the fill", l_buf.line (0).same_string ({STRING_32} "%/0x2588/100%%%/0x2588/"))
			assert ("explicit label foreground kept", l_buf.cell (0, 2).style.foreground.is_equal ({COLOR}.white))
			assert ("fill colour behind the label", l_buf.cell (0, 2).style.background.is_equal ({COLOR}.green))
		end

	test_gauge_label_wide_char_clipped
			-- A wide character that does not fit the gauge is not drawn past its edge.
		local
			l_buf: BUFFER
			l_gauge: TUI_GAUGE
		do
			create l_gauge.make
			l_gauge.set_percent (0)
			l_gauge.set_label ({STRING_32} "%/0x9032/%/0x6357/")
			create l_buf.make (5, 1)
			l_gauge.render (create {RECT}.make (0, 0, 3, 1), l_buf)
			assert ("first character drawn", l_buf.cell (0, 0).symbol.same_string ({STRING_32} "%/0x9032/"))
			assert ("nothing past the gauge", l_buf.cell (0, 3).symbol.same_string ({STRING_32} " ") and not l_buf.cell (0, 3).is_continuation)
			assert ("consistent", l_buf.is_consistent)
		end

feature {NONE} -- Helpers

	half_block_canvas (a_points: ARRAY [TUPLE [x, y: REAL_64]]): BUFFER
			-- 1x1 buffer with `a_points` drawn in [0, 1] x [0, 1] with the HalfBlock marker
		local
			l_canvas: TUI_CANVAS
		do
			create l_canvas.make
			l_canvas.set_marker ({CANVAS_MARKER}.half_block)
			l_canvas.add_shape (create {SHAPE_POINTS}.make (a_points, create {STYLE}))
			create Result.make (1, 1)
			l_canvas.render (Result.area, Result)
		end


	four_column_table: TUI_TABLE
			-- Table with one row "a1 b1 c1 d1" and four Fixed (4) columns, spacing 1
		do
			create Result.make_empty
			Result.append_row (create {TABLE_ROW}.make_raw (<<"a1", "b1", "c1", "d1">>))
			Result.set_widths (<<{CONSTRAINTS}.fixed (4), {CONSTRAINTS}.fixed (4), {CONSTRAINTS}.fixed (4), {CONSTRAINTS}.fixed (4)>>)
			Result.set_column_spacing (1)
		end

end
