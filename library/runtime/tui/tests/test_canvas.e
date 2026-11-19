note
	description: "[
		Unit tests for Phase 10: Canvas, 2D Coordinates & Braille Plotting.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_CANVAS

inherit
	BUFFER_TEST_HELPER

feature -- Test Routines

	test_braille_canvas_subpixels
			-- Test BRAILLE_CANVAS 2x4 dot subpixel mapping and Unicode Braille encoding.
		local
			l_canvas: BRAILLE_CANVAS
		do
			-- 2 character cells wide by 2 character cells high
			-- Subpixel dot dimensions: 4 dots wide x 8 dots high
			create l_canvas.make (2, 2)
			assert ("cols is 2", l_canvas.cols = 2)
			assert ("rows is 2", l_canvas.rows = 2)
			assert ("subpixel width is 4", l_canvas.subpixel_width = 4)
			assert ("subpixel height is 8", l_canvas.subpixel_height = 8)

			-- Cell (0, 0): set dot 1 (dx=0, dy=0) -> bit 1
			l_canvas.set_pixel (0, 0)
			assert ("pixel (0, 0) set", l_canvas.is_pixel_set (0, 0))
			assert ("cell (0, 0) mask is 1", l_canvas.cell_mask (0, 0) = 1)
			assert ("cell (0, 0) char code 10241", l_canvas.cell_char (0, 0).code = 10241)

			-- Cell (0, 0): also set dot 8 (dx=1, dy=3) -> bit 128
			l_canvas.set_pixel (1, 3)
			assert ("pixel (1, 3) set", l_canvas.is_pixel_set (1, 3))
			assert ("cell (0, 0) mask is 129", l_canvas.cell_mask (0, 0) = 129)
			assert ("cell (0, 0) char code 10369", l_canvas.cell_char (0, 0).code = 10369)

			-- Other cells remain empty
			assert ("cell (1, 0) mask is 0", l_canvas.cell_mask (1, 0) = 0)
			assert ("cell (1, 0) char is space", l_canvas.cell_char (1, 0) = ' ')

			-- Reset pixel (0, 0)
			l_canvas.reset_pixel (0, 0)
			assert ("pixel (0, 0) reset", not l_canvas.is_pixel_set (0, 0))
			assert ("cell (0, 0) mask is 128", l_canvas.cell_mask (0, 0) = 128)
		end

	test_canvas_painter_bresenham_line
			-- Test CANVAS_PAINTER coordinate mapping and Bresenham line rasterization.
		local
			l_canvas: BRAILLE_CANVAS
			l_painter: CANVAS_PAINTER
		do
			-- 5 cols x 5 rows => 10 subpixels wide x 20 subpixels high
			create l_canvas.make (5, 5)
			create l_painter.make (l_canvas, [0.0, 10.0], [0.0, 10.0])

			-- World coordinates: bottom-left (0.0, 0.0) to top-right (10.0, 10.0)
			-- (0.0, 0.0) maps to subpixel x=0, y=19 (since y_max is at top=0)
			-- (10.0, 10.0) maps to subpixel x=9, y=0
			l_painter.draw_line (0.0, 0.0, 10.0, 10.0)

			assert ("start point set", l_canvas.is_pixel_set (0, 19))
			assert ("end point set", l_canvas.is_pixel_set (9, 0))
			-- A diagonal line must activate dots across intermediate cells
			assert ("cell (0, 4) has dots", l_canvas.cell_mask (0, 4) > 0)
			assert ("cell (4, 0) has dots", l_canvas.cell_mask (4, 0) > 0)
		end

	test_canvas_painter_circle_and_rect
			-- Test rectangle and circle plotting.
		local
			l_canvas: BRAILLE_CANVAS
			l_painter: CANVAS_PAINTER
			l_cx, l_cy, l_rx, l_ry: INTEGER
		do
			-- 10 cols x 10 rows => 20 subpixels wide x 40 subpixels high
			create l_canvas.make (10, 10)
			create l_painter.make (l_canvas, [0.0, 20.0], [0.0, 20.0])

			-- Draw rectangle
			l_painter.draw_rect (5.0, 5.0, 10.0, 10.0)
			assert ("rect corner 1 set", l_canvas.cell_mask (l_painter.world_to_cell_col (5.0), l_painter.world_to_cell_row (5.0)) > 0)
			assert ("rect corner 2 set", l_canvas.cell_mask (l_painter.world_to_cell_col (15.0), l_painter.world_to_cell_row (15.0)) > 0)

			-- Draw circle centered at (10.0, 10.0) with radius 4.0. The radius is scaled per axis
			-- (20 dots for 20 world units across, 40 dots for 20 units down), so on the dot grid it
			-- is an ellipse about 4 dots wide and 8 dots tall, round in world coordinates.
			l_painter.draw_circle (10.0, 10.0, 4.0)
			l_cx := l_painter.world_to_subpixel_x (10.0)
			l_cy := l_painter.world_to_subpixel_y (10.0)
			l_rx := l_painter.world_to_subpixel_x (14.0) - l_cx
			l_ry := l_painter.world_to_subpixel_y (6.0) - l_cy
			assert ("radius follows the x scale", l_rx < l_ry)
			assert ("circle top subpixel set", l_canvas.is_pixel_set (l_cx, l_cy - l_ry))
			assert ("circle bottom subpixel set", l_canvas.is_pixel_set (l_cx, l_cy + l_ry))
			assert ("circle left subpixel set", l_canvas.is_pixel_set (l_cx - l_rx, l_cy))
			assert ("circle right subpixel set", l_canvas.is_pixel_set (l_cx + l_rx, l_cy))
			assert ("circle center hollow", not l_canvas.is_pixel_set (l_cx, l_cy))
		end

	test_tui_canvas_rendering_with_agent
			-- Test TUI_CANVAS rendering into BUFFER using agent-based painter.
		local
			l_canvas_widget: TUI_CANVAS
			l_buf: BUFFER
			l_area: RECT
		do
			create l_canvas_widget.make
			l_canvas_widget.set_bounds (0.0, 100.0, 0.0, 100.0)
			l_canvas_widget.set_painter (agent paint_test_pattern)

			create l_buf.make (10, 5)
			create l_area.make (0, 0, 10, 5)

			l_canvas_widget.render (l_area, l_buf)

			-- Painted points should yield non-space Braille characters
			assert ("corner cell 0, 0 non-empty", l_buf.cell (0, 9).symbol.code (1) >= 10240)
			assert ("corner cell 4, 0 non-empty", l_buf.cell (4, 0).symbol.code (1) >= 10240)
		end

	test_tui_chart_rendering
			-- Test TUI_CHART dataset lines, axes, corner junction, and labels.
		local
			l_chart: TUI_CHART
			l_ds1, l_ds2: TUI_CHART_DATASET
			l_buf: BUFFER
			l_area: RECT
		do
			create l_ds1.make ("sin")
			l_ds1.append_point (0.0, 0.0)
			l_ds1.append_point (5.0, 10.0)
			l_ds1.append_point (10.0, 0.0)

			create l_ds2.make ("points")
			l_ds2.set_is_line (False)
			l_ds2.append_point (2.5, 5.0)
			l_ds2.append_point (7.5, 5.0)

			create l_chart.make_with_datasets (<<l_ds1, l_ds2>>)
			l_chart.set_x_bounds (0.0, 10.0)
			l_chart.set_y_bounds (0.0, 10.0)
			l_chart.set_x_labels (<<"0", "5", "10">>)
			-- Y labels are listed from the y minimum up, as in Ratatui ("10" ends up on the top row)
			l_chart.set_y_labels (<<"0", "5", "10">>)

			create l_buf.make (20, 8)
			create l_area.make (0, 0, 20, 8)

			l_chart.render (l_area, l_buf)

			-- Y-axis label "10" at top left
			assert ("y label 1", l_buf.cell (0, 0).symbol.same_string_general ("1"))
			assert ("y label 0", l_buf.cell (0, 1).symbol.same_string_general ("0"))

			-- Vertical axis line '│' (code 9474) at column 2
			assert ("vertical axis line", l_buf.cell (0, 2).symbol.code (1) = 9474)

			-- Bottom-left corner junction '└' (code 9492) at row 6, col 2
			assert ("corner junction", l_buf.cell (6, 2).symbol.code (1) = 9492)

			-- Horizontal axis line '─' (code 9472) at row 6, col 3
			assert ("horizontal axis line", l_buf.cell (6, 3).symbol.code (1) = 9472)

			-- X-axis labels at row 7
			assert ("x label 0", l_buf.cell (7, 3).symbol.same_string_general ("0"))
		end

	test_text_cell_dot_marker
			-- B1: on a Dot grid (1 x 1 dots per cell) a label at (x_max, y_min) lands in the bottom-right cell.
		local
			l_grid: BRAILLE_CANVAS
			l_painter: CANVAS_PAINTER
			l_canvas: TUI_CANVAS
			l_buf: BUFFER
		do
			create l_grid.make_with_resolution (10, 5, 1, 1)
			create l_painter.make (l_grid, [0.0, 10.0], [0.0, 5.0])
			assert ("x_max is the last column", l_painter.world_to_cell_col (10.0) = 9)
			assert ("y_min is the last row", l_painter.world_to_cell_row (0.0) = 4)
			assert ("x_min is column 0", l_painter.world_to_cell_col (0.0) = 0)
			assert ("y_max is row 0", l_painter.world_to_cell_row (5.0) = 0)

			-- Same through TUI_CANVAS: the label is drawn in the bottom-right cell of the buffer
			create l_canvas.make
			l_canvas.set_marker ({CANVAS_MARKER}.dot)
			l_canvas.set_bounds (0.0, 10.0, 0.0, 5.0)
			l_canvas.set_painter (agent (p: CANVAS_PAINTER) do p.draw_text (10.0, 0.0, "X", create {STYLE}) end)
			create l_buf.make (10, 5)
			l_canvas.render (create {RECT}.make (0, 0, 10, 5), l_buf)
			assert ("label in bottom-right cell", l_buf.cell (4, 9).symbol.same_string_general ("X"))
		end

	test_text_cell_half_block_marker
			-- B1: on a HalfBlock grid (1 x 2 dots per cell) a label at (x_max, y_min) lands in the bottom-right cell.
		local
			l_grid: BRAILLE_CANVAS
			l_painter: CANVAS_PAINTER
		do
			create l_grid.make_with_resolution (10, 5, 1, 2)
			create l_painter.make (l_grid, [0.0, 10.0], [0.0, 5.0])
			assert ("x_max is the last column", l_painter.world_to_cell_col (10.0) = 9)
			assert ("y_min is the last row", l_painter.world_to_cell_row (0.0) = 4)
			assert ("y_max is row 0", l_painter.world_to_cell_row (5.0) = 0)
		end

	test_text_cell_braille_marker
			-- B1: on a Braille grid (2 x 4 dots per cell) the mapping is unchanged.
		local
			l_grid: BRAILLE_CANVAS
			l_painter: CANVAS_PAINTER
		do
			create l_grid.make (10, 5)
			create l_painter.make (l_grid, [0.0, 10.0], [0.0, 5.0])
			assert ("x_max is the last column", l_painter.world_to_cell_col (10.0) = 9)
			assert ("y_min is the last row", l_painter.world_to_cell_row (0.0) = 4)
			assert ("x_min is column 0", l_painter.world_to_cell_col (0.0) = 0)
			assert ("y_max is row 0", l_painter.world_to_cell_row (5.0) = 0)
		end

	test_line_far_end_is_clipped
			-- B4: a line from (0, 0) to (1e9, 0) on bounds [0, 1] is clipped before the dot walk.
			-- 100 draws take less than 1 s (under 10 ms each), and only the bottom row is drawn.
		local
			l_grid: BRAILLE_CANVAS
			l_painter: CANVAS_PAINTER
			l_start, l_elapsed: INTEGER_64
			i: INTEGER
		do
			-- 5 x 5 cells => 10 x 20 dots
			create l_grid.make (5, 5)
			create l_painter.make (l_grid, [0.0, 1.0], [0.0, 1.0])
			l_start := {MONOTONIC_CLOCK}.milliseconds
			from i := 1 until i > 100 loop
				l_painter.draw_line (0.0, 0.0, 1.0e9, 0.0)
				i := i + 1
			end
			l_elapsed := {MONOTONIC_CLOCK}.milliseconds - l_start
			assert ("100 draws under 1 s", l_elapsed < 1000)
			from i := 0 until i >= 10 loop
				assert ("bottom row dot " + i.out, l_grid.is_pixel_set (i, 19))
				i := i + 1
			end
			assert ("only the bottom row", dot_count (l_grid) = 10)

			-- The clipped segment itself, and a segment that misses the bounds
			if attached l_painter.clipped_segment (0.0, 0.0, 1.0e9, 0.0) as l_seg then
				assert ("clipped start", l_seg.x1 = 0.0 and l_seg.y1 = 0.0)
				assert ("clipped end on x_max", l_seg.x2 = 1.0 and l_seg.y2 = 0.0)
			else
				assert ("segment is visible", False)
			end
			assert ("missing segment is Void", l_painter.clipped_segment (2.0, 0.0, 1.0e9, 5.0) = Void)
		end

	test_point_non_finite_or_outside_draws_nothing
			-- B4: `draw_point` skips NaN, infinities, values beyond INTEGER_32 and points outside
			-- the bounds, as Ratatui's `get_point`. Points exactly on the bounds are still drawn.
		local
			l_grid: BRAILLE_CANVAS
			l_painter: CANVAS_PAINTER
		do
			-- Dot grid 10 x 10, one world unit per dot
			create l_grid.make_with_resolution (10, 10, 1, 1)
			create l_painter.make (l_grid, [0.0, 9.0], [0.0, 9.0])
			l_painter.draw_point ({REAL_64}.nan, 0.0)
			l_painter.draw_point (0.0, {REAL_64}.nan)
			l_painter.draw_point ({REAL_64}.positive_infinity, 0.0)
			l_painter.draw_point (0.0, {REAL_64}.negative_infinity)
			l_painter.draw_point ({REAL_64}.negative_infinity, {REAL_64}.positive_infinity)
			l_painter.draw_point (1.0e300, 0.0)
			l_painter.draw_point (0.0, -1.0e12)
			l_painter.draw_point (3.0e9, 3.0e9)
			assert ("non-finite and huge points draw nothing", dot_count (l_grid) = 0)

			-- Just outside the bounds: Ratatui skips them (the old code rounded them onto the edge)
			l_painter.draw_point (-0.4, 4.0)
			l_painter.draw_point (4.0, 9.4)
			assert ("outside points draw nothing", dot_count (l_grid) = 0)

			-- On the bounds
			l_painter.draw_point (0.0, 0.0)
			l_painter.draw_point (9.0, 9.0)
			l_painter.draw_point (9.0, 0.0)
			assert ("corner (0, 0) drawn", l_grid.is_pixel_set (0, 9))
			assert ("corner (9, 9) drawn", l_grid.is_pixel_set (9, 0))
			assert ("corner (9, 0) drawn", l_grid.is_pixel_set (9, 9))
			assert ("three dots", dot_count (l_grid) = 3)
		end

	test_point_on_bound_with_rounding_error_is_drawn
			-- B4 review #3: a point that is on a bound up to floating-point error (0.1 + 0.2 against
			-- a bound of 0.3) is drawn on the edge, on a painter and through a chart scatter dataset.
			-- Points clearly outside are still skipped (see `test_point_non_finite_or_outside_draws_nothing`).
		local
			l_grid: BRAILLE_CANVAS
			l_painter: CANVAS_PAINTER
			l_x: REAL_64
			l_chart: TUI_CHART
			l_ds: TUI_CHART_DATASET
			l_buf: BUFFER
		do
			l_x := 0.1 + 0.2
			assert ("0.1 + 0.2 is above 0.3", l_x > 0.3)
			create l_grid.make_with_resolution (10, 10, 1, 1)
			create l_painter.make (l_grid, [0.0, 0.3], [0.0, 0.3])
			l_painter.draw_point (l_x, l_x)
			assert ("top right corner drawn", l_grid.is_pixel_set (9, 0))
			l_painter.draw_point (-1.0e-17, -1.0e-17)
			assert ("bottom left corner drawn", l_grid.is_pixel_set (0, 9))
			assert ("two dots", dot_count (l_grid) = 2)
			l_painter.draw_point (0.3 + 1.0e-3, 0.0)
			assert ("a point clearly outside is still skipped", dot_count (l_grid) = 2)

			create l_ds.make ("edge")
			l_ds := l_ds.with_graph_type ({CHART_GRAPH_TYPE}.scatter).with_marker ({CANVAS_MARKER}.dot)
			l_ds.append_point (l_x, l_x)
			create l_chart.make_with_datasets (<<l_ds>>)
			l_chart.set_x_bounds (0.0, 0.3)
			l_chart.set_y_bounds (0.0, 0.3)
			-- 8 x 5: y axis in column 0, x axis on row 4, plot 7 x 4
			create l_buf.make (8, 5)
			l_chart.render (l_buf.area, l_buf)
			assert_cell_symbol ("chart point at the top right", l_buf, 0, 7, {STRING_32} "%/0x2022/")
		end

	test_line_through_corner_is_clipped
			-- B4 review: two lines through a corner of the bounds, found by a search, whose end at
			-- that corner bounces between the two edges by rounding until the clipping step cap.
			-- Their visible part is long, so it must be returned and drawn, not dropped.
		local
			l_grid: BRAILLE_CANVAS
			l_painter: CANVAS_PAINTER
		do
			create l_grid.make_with_resolution (10, 10, 1, 1)
			create l_painter.make (l_grid, [-1.0, 0.3], [0.2, 1.0])
			if attached l_painter.clipped_segment (-88.7151418856438, 134.1487430080231, 205.27465360182077, -308.24299763899967) as s then
				assert ("first: top end", (s.x1 - -0.2316370419709699).abs < 1.0e-9 and (s.y1 - 1.0).abs < 1.0e-9)
				assert ("first: corner end", (s.x2 - 0.3).abs < 1.0e-9 and (s.y2 - 0.2).abs < 1.0e-9)
			else
				assert ("first segment kept", False)
			end
			l_painter.draw_line (-88.7151418856438, 134.1487430080231, 205.27465360182077, -308.24299763899967)
			assert ("first line drawn across the grid", dot_count (l_grid) >= 7)
			assert ("first line reaches the bottom right corner", l_grid.is_pixel_set (9, 9))

			create l_grid.make_with_resolution (10, 10, 1, 1)
			create l_painter.make (l_grid, [0.1, 1.0], [-3.0, 0.3])
			if attached l_painter.clipped_segment (3.3477613162707422, -6.24213904332658, -5.285297765740942, 11.14789285366814) as s then
				assert ("second: right end", (s.x1 - 1.0).abs < 1.0e-9 and (s.y1 - -1.5129180582010135).abs < 1.0e-9)
				assert ("second: corner end", (s.x2 - 0.1).abs < 1.0e-9 and (s.y2 - 0.3).abs < 1.0e-9)
			else
				assert ("second segment kept", False)
			end
		end

	test_line_non_finite_draws_nothing
			-- B4: a line with a NaN or infinite end draws nothing and raises nothing (Ratatui `Line::draw`).
		local
			l_grid: BRAILLE_CANVAS
			l_painter: CANVAS_PAINTER
		do
			create l_grid.make_with_resolution (10, 10, 1, 1)
			create l_painter.make (l_grid, [0.0, 9.0], [0.0, 9.0])
			l_painter.draw_line (0.0, 0.0, {REAL_64}.nan, 5.0)
			l_painter.draw_line ({REAL_64}.nan, {REAL_64}.nan, 9.0, 9.0)
			l_painter.draw_line (0.0, 4.0, {REAL_64}.positive_infinity, 4.0)
			l_painter.draw_line (4.0, {REAL_64}.negative_infinity, 4.0, 9.0)
			l_painter.draw_rect (1.0, 1.0, {REAL_64}.nan, {REAL_64}.nan)
			assert ("nothing drawn", dot_count (l_grid) = 0)
		end

	test_shapes_non_finite_draw_nothing
			-- B4: circles and text labels with NaN, infinite or huge values are skipped and raise nothing.
		local
			l_grid: BRAILLE_CANVAS
			l_painter: CANVAS_PAINTER
		do
			create l_grid.make_with_resolution (10, 10, 1, 1)
			create l_painter.make (l_grid, [0.0, 9.0], [0.0, 9.0])
			l_painter.draw_circle ({REAL_64}.nan, 4.0, 2.0)
			l_painter.draw_circle (4.0, 4.0, {REAL_64}.positive_infinity)
			l_painter.draw_circle (4.0, 4.0, 1.0e12)
			l_painter.draw_circle (1.0e300, 4.0, 2.0)
			assert ("no circle drawn", dot_count (l_grid) = 0)
			l_painter.draw_text ({REAL_64}.nan, 4.0, "x", create {STYLE})
			l_painter.draw_text (4.0, {REAL_64}.negative_infinity, "x", create {STYLE})
			l_painter.draw_text (1.0e300, 4.0, "x", create {STYLE})
			assert ("no label registered", l_painter.text_overlays.is_empty)

			-- A finite circle is still drawn
			l_painter.draw_circle (4.0, 4.0, 2.0)
			assert ("circle drawn", dot_count (l_grid) > 0)
		end

	test_line_partly_outside_matches_unclipped_walk
			-- B4: a line partly outside the bounds is clipped, and its visible dots are those of
			-- the unclipped line. The reference draws the whole line on a larger grid whose bounds
			-- contain both ends (same scale), then compares the window that the small grid shows.
		do
			assert_clipped_line_matches (-5.0, -5.0, 20.0, 20.0)
			assert_clipped_line_matches (-100.0, 4.0, 100.0, 4.0)
			assert_clipped_line_matches (3.0, -50.0, 3.0, 50.0)
			assert_clipped_line_matches (-3.0, 0.0, 15.0, 6.0)
			assert_clipped_line_matches (15.0, 6.0, -3.0, 0.0)
			assert_clipped_line_matches (-4.0, 13.0, 13.0, -4.0)
			-- Entirely outside: nothing
			assert_clipped_line_matches (-5.0, 20.0, 20.0, 30.0)
			assert_clipped_line_matches (-5.0, 3.0, 3.0, 20.0)
		end

	test_ratatui_horizontal_with_vertical_pattern_markers
			-- V1: Ratatui `canvas.rs` `test_horizontal_with_vertical` (cases braille, quadrant,
			-- sextant, octant). A vertical and a horizontal line on a 5 x 5 canvas, bounds [0, 10].
			-- Ratatui fills the buffer with 'x' and leaves undrawn cells alone; TUI_CANVAS paints
			-- its background, so those cells are spaces here.
		do
			assert_buffer_lines ("braille", lines_canvas ({CANVAS_MARKER}.braille, <<[0.0, 0.0, 0.0, 10.0], [0.0, 0.0, 10.0, 0.0]>>), <<
				{STRING_32} "%/0x2847/    ",
				{STRING_32} "%/0x2847/    ",
				{STRING_32} "%/0x2847/    ",
				{STRING_32} "%/0x2847/    ",
				{STRING_32} "%/0x28C7/%/0x28C0/%/0x28C0/%/0x28C0/%/0x28C0/"
			>>)
			assert_buffer_lines ("quadrant", lines_canvas ({CANVAS_MARKER}.quadrant, <<[0.0, 0.0, 0.0, 10.0], [0.0, 0.0, 10.0, 0.0]>>), <<
				{STRING_32} "%/0x258C/    ",
				{STRING_32} "%/0x258C/    ",
				{STRING_32} "%/0x258C/    ",
				{STRING_32} "%/0x258C/    ",
				{STRING_32} "%/0x2599/%/0x2584/%/0x2584/%/0x2584/%/0x2584/"
			>>)
			assert_buffer_lines ("sextant", lines_canvas ({CANVAS_MARKER}.sextant, <<[0.0, 0.0, 0.0, 10.0], [0.0, 0.0, 10.0, 0.0]>>), <<
				{STRING_32} "%/0x258C/    ",
				{STRING_32} "%/0x258C/    ",
				{STRING_32} "%/0x258C/    ",
				{STRING_32} "%/0x258C/    ",
				{STRING_32} "%/0x1FB32/%/0x1FB2D/%/0x1FB2D/%/0x1FB2D/%/0x1FB2D/"
			>>)
			assert_buffer_lines ("octant", lines_canvas ({CANVAS_MARKER}.octant, <<[0.0, 0.0, 0.0, 10.0], [0.0, 0.0, 10.0, 0.0]>>), <<
				{STRING_32} "%/0x258C/    ",
				{STRING_32} "%/0x258C/    ",
				{STRING_32} "%/0x258C/    ",
				{STRING_32} "%/0x258C/    ",
				{STRING_32} "%/0x1CDC0/%/0x2582/%/0x2582/%/0x2582/%/0x2582/"
			>>)
		end

	test_ratatui_diagonal_lines_pattern_markers
			-- V1: Ratatui `canvas.rs` `test_diagonal_lines` (cases braille, quadrant, sextant,
			-- octant). Two diagonals on a 5 x 5 canvas, bounds [0, 10]; undrawn cells are spaces
			-- here ('x' in Ratatui, see above).
		do
			assert_buffer_lines ("braille", lines_canvas ({CANVAS_MARKER}.braille, <<[0.0, 10.0, 10.0, 0.0], [0.0, 0.0, 10.0, 10.0]>>), <<
				{STRING_32} "%/0x28A3/   %/0x285C/",
				{STRING_32} " %/0x28A3/ %/0x285C/ ",
				{STRING_32} "  %/0x28FF/  ",
				{STRING_32} " %/0x285C/ %/0x28A3/ ",
				{STRING_32} "%/0x285C/   %/0x28A3/"
			>>)
			assert_buffer_lines ("quadrant", lines_canvas ({CANVAS_MARKER}.quadrant, <<[0.0, 10.0, 10.0, 0.0], [0.0, 0.0, 10.0, 10.0]>>), <<
				{STRING_32} "%/0x259A/   %/0x259E/",
				{STRING_32} " %/0x259A/ %/0x259E/ ",
				{STRING_32} "  %/0x2588/  ",
				{STRING_32} " %/0x259E/ %/0x259A/ ",
				{STRING_32} "%/0x259E/   %/0x259A/"
			>>)
			-- The 10 x 15 dot lines are steep with a tie at the crossing; the center cell is a full
			-- block only because the line walk starts from the smaller y, as in Ratatui
			-- `for_each_line_point_high` (V1 review #2: it was U+1FB38 when the walk began at the first end).
			assert_buffer_lines ("sextant", lines_canvas ({CANVAS_MARKER}.sextant, <<[0.0, 10.0, 10.0, 0.0], [0.0, 0.0, 10.0, 10.0]>>), <<
				{STRING_32} "%/0x1FB27/   %/0x1FB14/",
				{STRING_32} " %/0x1FB27/ %/0x1FB14/ ",
				{STRING_32} "  %/0x2588/  ",
				{STRING_32} " %/0x1FB18/ %/0x1FB23/ ",
				{STRING_32} "%/0x1FB18/   %/0x1FB23/"
			>>)
			assert_cell_symbol ("sextant center is a full block", lines_canvas ({CANVAS_MARKER}.sextant,
				<<[0.0, 10.0, 10.0, 0.0], [0.0, 0.0, 10.0, 10.0]>>), 2, 2, {STRING_32} "%/0x2588/")
			assert_buffer_lines ("octant", lines_canvas ({CANVAS_MARKER}.octant, <<[0.0, 10.0, 10.0, 0.0], [0.0, 0.0, 10.0, 10.0]>>), <<
				{STRING_32} "%/0x259A/   %/0x259E/",
				{STRING_32} " %/0x259A/ %/0x259E/ ",
				{STRING_32} "  %/0x2588/  ",
				{STRING_32} " %/0x259E/ %/0x259A/ ",
				{STRING_32} "%/0x259E/   %/0x259A/"
			>>)
		end

	test_ratatui_line_cases_dot_marker
			-- V1 review #2: Ratatui `canvas/line.rs` `tests` (cases off_grid5..8, horizontal1..2,
			-- vertical1..2, diagonal1..4). One line on a 10 x 10 Dot canvas, bounds [0, 10].
			-- diagonal2 and diagonal4 start at the end Ratatui does not walk from.
			-- Rows are written with '*' for the Dot marker's '•' (see `dot_rows`).
		local
			e: STRING
		do
			e := "          "
			assert_buffer_lines ("off_grid5", dot_line_canvas (-10.0, 0.0, 5.0, 0.0),
				dot_rows (<<e, e, e, e, e, e, e, e, e, "******    ">>))
			assert_buffer_lines ("off_grid6", dot_line_canvas (-1.0, -1.0, 10.0, 10.0), dot_rows (diagonal_rows))
			assert_buffer_lines ("off_grid7", dot_line_canvas (0.0, 0.0, 11.0, 11.0), dot_rows (diagonal_rows))
			assert_buffer_lines ("off_grid8", dot_line_canvas (-1.0, -1.0, 11.0, 11.0), dot_rows (diagonal_rows))
			assert_buffer_lines ("horizontal1", dot_line_canvas (0.0, 0.0, 10.0, 0.0),
				dot_rows (<<e, e, e, e, e, e, e, e, e, "**********">>))
			assert_buffer_lines ("horizontal2", dot_line_canvas (10.0, 10.0, 0.0, 10.0),
				dot_rows (<<"**********", e, e, e, e, e, e, e, e, e>>))
			assert_buffer_lines ("vertical1", dot_line_canvas (0.0, 0.0, 0.0, 10.0), dot_rows (<<
				"*         ", "*         ", "*         ", "*         ", "*         ",
				"*         ", "*         ", "*         ", "*         ", "*         ">>))
			assert_buffer_lines ("vertical2", dot_line_canvas (10.0, 10.0, 10.0, 0.0), dot_rows (<<
				"         *", "         *", "         *", "         *", "         *",
				"         *", "         *", "         *", "         *", "         *">>))
			assert_buffer_lines ("diagonal1", dot_line_canvas (0.0, 0.0, 10.0, 5.0), dot_rows (<<e, e, e, e, e,
				"        **", "      **  ", "    **    ", "  **      ", "**        ">>))
			assert_buffer_lines ("diagonal2", dot_line_canvas (10.0, 0.0, 0.0, 5.0), dot_rows (<<e, e, e, e, e,
				"**        ", "  **      ", "    **    ", "      **  ", "        **">>))
			assert_buffer_lines ("diagonal3", dot_line_canvas (0.0, 0.0, 5.0, 10.0), dot_rows (<<
				"     *    ", "    *     ", "    *     ", "   *      ", "   *      ",
				"  *       ", "  *       ", " *        ", " *        ", "*         ">>))
			assert_buffer_lines ("diagonal4", dot_line_canvas (0.0, 10.0, 5.0, 0.0), dot_rows (<<
				"*         ", " *        ", " *        ", "  *       ", "  *       ",
				"   *      ", "   *      ", "    *     ", "    *     ", "     *    ">>))
		end

	dot_rows (a_rows: ARRAY [STRING]): ARRAY [READABLE_STRING_GENERAL]
			-- `a_rows` with each '*' replaced by the Dot marker's '•' (U+2022).
		local
			l_row: STRING_32
		do
			create Result.make_filled ({STRING_32} "", a_rows.lower, a_rows.upper)
			across a_rows as r loop
				create l_row.make_from_string_general (r)
				l_row.replace_substring_all ({STRING_32} "*", {STRING_32} "%/0x2022/")
				Result [@r.target_index] := l_row
			end
		end

	test_line_dots_do_not_depend_on_end_order
			-- V1 review #2: a line from A to B sets the same dots as from B to A (Ratatui walks
			-- shallow lines from the smaller x and steep ones from the smaller y), on a Braille
			-- and a Sextant grid, for shallow, steep and 45-degree lines with ties.
		local
			l_lines: ARRAY [TUPLE [x1, y1, x2, y2: REAL_64]]
			l_markers: ARRAY [NATURAL_8]
			l_forward, l_backward: BUFFER
			l_name: STRING
		do
			l_lines := <<[0.0, 10.0, 10.0, 0.0], [0.0, 0.0, 10.0, 3.0], [1.0, 9.0, 4.0, 0.5],
				[0.0, 0.0, 7.0, 10.0], [2.0, 8.0, 9.0, 1.0], [0.0, 5.0, 10.0, 6.0]>>
			l_markers := <<{CANVAS_MARKER}.braille, {CANVAS_MARKER}.sextant, {CANVAS_MARKER}.dot>>
			across l_markers as m loop
				across l_lines as l loop
					l_forward := sized_lines_canvas (m, 7, 6, <<[l.x1, l.y1, l.x2, l.y2]>>)
					l_backward := sized_lines_canvas (m, 7, 6, <<[l.x2, l.y2, l.x1, l.y1]>>)
					l_name := "marker " + m.out + ", line " + @l.cursor_index.out
					assert_same_buffer_lines (l_name, l_forward, l_backward)
				end
			end
		end

	diagonal_rows: ARRAY [STRING]
			-- Rows ('*' for a dot) of the 10 x 10 diagonal from the bottom-left to the top-right corner.
		local
			r: INTEGER
			l_row: STRING
		do
			create Result.make_filled ("", 1, 10)
			from r := 0 until r >= 10 loop
				create l_row.make_filled (' ', 10)
				l_row.put ('*', 10 - r)
				Result [r + 1] := l_row
				r := r + 1
			end
		end

	assert_same_buffer_lines (a_name: STRING; a_one, a_other: BUFFER)
			-- Do `a_one` and `a_other` show the same symbols in every cell?
		local
			r, c: INTEGER
		do
			from r := 0 until r >= a_one.height loop
				from c := 0 until c >= a_one.width loop
					assert (a_name + " at (" + r.out + ", " + c.out + ")",
						a_one.cell (r, c).symbol.same_string (a_other.cell (r, c).symbol))
					c := c + 1
				end
				r := r + 1
			end
		end

	test_pattern_grid_one_cell_per_bit
			-- V1: each single pseudo-pixel of a 2 x 2, 2 x 3 and 2 x 4 cell sets bit x + 2 * y
			-- (row-major, as Ratatui `PatternGrid`) and renders the table character of that pattern.
		do
			assert_one_cell_per_bit ({CANVAS_MARKER}.quadrant)
			assert_one_cell_per_bit ({CANVAS_MARKER}.sextant)
			assert_one_cell_per_bit ({CANVAS_MARKER}.octant)
			-- A few table entries spelled out (Ratatui `symbols::pixel`)
			assert ("quadrant top-left", {SYMBOLS_PIXEL}.quadrant (1) = '%/0x2598/')
			assert ("quadrant bottom-right", {SYMBOLS_PIXEL}.quadrant (8) = '%/0x2597/')
			assert ("sextant top-left", {SYMBOLS_PIXEL}.sextant (1) = '%/0x1FB00/')
			assert ("sextant bottom-right", {SYMBOLS_PIXEL}.sextant (32) = '%/0x1FB1E/')
			assert ("octant top-left", {SYMBOLS_PIXEL}.octant (1) = '%/0x1CEA8/')
			assert ("octant bottom-right", {SYMBOLS_PIXEL}.octant (128) = '%/0x1CEA0/')
			assert ("octant left column", {SYMBOLS_PIXEL}.octant (0x55) = '%/0x258C/')
			assert ("blank patterns", {SYMBOLS_PIXEL}.quadrant (0) = ' ' and {SYMBOLS_PIXEL}.sextant (0) = ' ' and {SYMBOLS_PIXEL}.octant (0) = ' ')
			assert ("full patterns", {SYMBOLS_PIXEL}.quadrant (15) = '%/0x2588/' and {SYMBOLS_PIXEL}.sextant (63) = '%/0x2588/' and {SYMBOLS_PIXEL}.octant (255) = '%/0x2588/')
		end

	test_pixel_tables_are_one_column_wide
			-- V1: every quadrant, sextant and octant character is 1 column wide in UNICODE_WIDTH,
			-- and the characters of the octant table are distinct.
		local
			i: INTEGER
			l_seen: HASH_TABLE [INTEGER, NATURAL_32]
		do
			create l_seen.make (256)
			from i := 1 until i > 255 loop
				assert ("octant " + i.out + " width 1", {UNICODE_WIDTH}.width ({SYMBOLS_PIXEL}.octant (i).natural_32_code) = 1)
				l_seen.force (i, {SYMBOLS_PIXEL}.octant (i).natural_32_code)
				if i < 64 then
					assert ("sextant " + i.out + " width 1", {UNICODE_WIDTH}.width ({SYMBOLS_PIXEL}.sextant (i).natural_32_code) = 1)
				end
				if i < 16 then
					assert ("quadrant " + i.out + " width 1", {UNICODE_WIDTH}.width ({SYMBOLS_PIXEL}.quadrant (i).natural_32_code) = 1)
				end
				i := i + 1
			end
			assert ("255 distinct octants", l_seen.count = 255)
			-- The whole octant block of Symbols for Legacy Computing Supplement
			from i := 0x1CD00 until i > 0x1CDE5 loop
				assert ("U+" + i.to_hex_string + " width 1", {UNICODE_WIDTH}.width (i.to_natural_32) = 1)
				i := i + 1
			end
		end

	test_marker_resolution
			-- V1: grid size per marker (Ratatui `marker_to_grid`), and the bit order of each grid.
		local
			l_grid: BRAILLE_CANVAS
		do
			assert ("braille 2 x 4", {CANVAS_MARKER}.dots_x ({CANVAS_MARKER}.braille) = 2 and {CANVAS_MARKER}.dots_y ({CANVAS_MARKER}.braille) = 4)
			assert ("octant 2 x 4", {CANVAS_MARKER}.dots_x ({CANVAS_MARKER}.octant) = 2 and {CANVAS_MARKER}.dots_y ({CANVAS_MARKER}.octant) = 4)
			assert ("sextant 2 x 3", {CANVAS_MARKER}.dots_x ({CANVAS_MARKER}.sextant) = 2 and {CANVAS_MARKER}.dots_y ({CANVAS_MARKER}.sextant) = 3)
			assert ("quadrant 2 x 2", {CANVAS_MARKER}.dots_x ({CANVAS_MARKER}.quadrant) = 2 and {CANVAS_MARKER}.dots_y ({CANVAS_MARKER}.quadrant) = 2)
			assert ("half block 1 x 2", {CANVAS_MARKER}.dots_x ({CANVAS_MARKER}.half_block) = 1 and {CANVAS_MARKER}.dots_y ({CANVAS_MARKER}.half_block) = 2)
			assert ("dot 1 x 1", {CANVAS_MARKER}.dots_x ({CANVAS_MARKER}.dot) = 1 and {CANVAS_MARKER}.dots_y ({CANVAS_MARKER}.dot) = 1)
			assert ("new markers valid", {CANVAS_MARKER}.is_valid ({CANVAS_MARKER}.quadrant) and {CANVAS_MARKER}.is_valid ({CANVAS_MARKER}.sextant) and {CANVAS_MARKER}.is_valid ({CANVAS_MARKER}.octant))
			assert ("custom 1 x 1", {CANVAS_MARKER}.dots_x ({CANVAS_MARKER}.custom) = 1 and {CANVAS_MARKER}.dots_y ({CANVAS_MARKER}.custom) = 1)
			assert ("custom valid", {CANVAS_MARKER}.is_valid ({CANVAS_MARKER}.custom))
			assert ("10 not valid", not {CANVAS_MARKER}.is_valid (10))

			-- Two orders on a 2 x 4 cell: dot (1, 0) is Braille dot 4 (0x08) but octant bit 1 (0x02)
			create l_grid.make (1, 1)
			l_grid.set_pixel (1, 0)
			assert ("braille order", l_grid.is_braille_order and l_grid.cell_mask (0, 0) = 0x08)
			create l_grid.make_with_pattern (1, 1, 2, 4)
			l_grid.set_pixel (1, 0)
			assert ("row-major order", not l_grid.is_braille_order and l_grid.cell_mask (0, 0) = 0x02)
			l_grid.set_pixel (1, 3)
			assert ("bit 7 at (1, 3)", l_grid.cell_mask (0, 0) = 0x82)
			assert ("pixel query in row-major order", l_grid.is_pixel_set (1, 3) and not l_grid.is_pixel_set (0, 3))
		end

	test_braille_layer_over_octant_base
			-- V1: a Braille layer over an Octant base. Where the layer draws, its cell replaces the
			-- base cell; where its pattern is empty, the Octant cell underneath stays visible.
		local
			l_canvas: TUI_CANVAS
			l_layer: CANVAS_LAYER
			l_buf: BUFFER
		do
			-- 3 x 1 cells: 6 x 4 dots on both grids, one world unit per dot
			create l_canvas.make
			l_canvas.set_marker ({CANVAS_MARKER}.octant)
			l_canvas.set_bounds (0.0, 5.0, 0.0, 3.0)
			-- Base: the bottom dot row across all three cells
			l_canvas.set_painter (agent (p: CANVAS_PAINTER)
				do
					p.set_style (create {STYLE}.make_fg ({COLOR}.red))
					p.draw_line (0.0, 0.0, 5.0, 0.0)
				end)
			-- Layer: the top-left dot of the middle cell only
			create l_layer.make_with_painter (agent (p: CANVAS_PAINTER)
				do
					p.set_style (create {STYLE}.make_fg ({COLOR}.blue))
					p.draw_point (2.0, 3.0)
				end)
			l_layer.set_marker ({CANVAS_MARKER}.braille)
			l_canvas.add_layer (l_layer)
			create l_buf.make (3, 1)
			l_canvas.render (l_buf.area, l_buf)
			-- Octant bits 6 + 7 (bottom row) = U+2582; Braille dot 1 = U+2801
			assert_buffer_lines ("octant, braille, octant", l_buf, <<{STRING_32} "%/0x2582/%/0x2801/%/0x2582/">>)
			assert ("base colour kept left", l_buf.cell (0, 0).style.foreground.is_equal ({COLOR}.red))
			assert ("layer colour in the middle", l_buf.cell (0, 1).style.foreground.is_equal ({COLOR}.blue))
			assert ("base colour kept right", l_buf.cell (0, 2).style.foreground.is_equal ({COLOR}.red))
		end

	test_chart_dataset_pattern_markers
			-- V1: a chart dataset accepts Quadrant, Sextant and Octant, and its line is drawn
			-- with that marker's characters (a line along y_min is the bottom pseudo-pixel row).
		do
			assert_chart_marker_row ({CANVAS_MARKER}.quadrant, '%/0x2584/')
			assert_chart_marker_row ({CANVAS_MARKER}.sextant, '%/0x1FB2D/')
			assert_chart_marker_row ({CANVAS_MARKER}.octant, '%/0x2582/')
		end

	test_ratatui_horizontal_with_vertical_custom_markers
			-- V2: Ratatui `canvas.rs` `test_horizontal_with_vertical` (cases x_sign, plus_sign).
			-- Undrawn cells are spaces here ('x' in Ratatui, see the pattern markers).
		do
			assert_buffer_lines ("x_sign", custom_lines_canvas ('%/0xD7/', <<[0.0, 0.0, 0.0, 10.0], [0.0, 0.0, 10.0, 0.0]>>), <<
				{STRING_32} "%/0xD7/    ",
				{STRING_32} "%/0xD7/    ",
				{STRING_32} "%/0xD7/    ",
				{STRING_32} "%/0xD7/    ",
				{STRING_32} "%/0xD7/%/0xD7/%/0xD7/%/0xD7/%/0xD7/"
			>>)
			assert_buffer_lines ("plus_sign", custom_lines_canvas ('+', <<[0.0, 0.0, 0.0, 10.0], [0.0, 0.0, 10.0, 0.0]>>), <<
				{STRING_32} "+    ",
				{STRING_32} "+    ",
				{STRING_32} "+    ",
				{STRING_32} "+    ",
				{STRING_32} "+++++"
			>>)
		end

	test_ratatui_diagonal_lines_custom_markers
			-- V2: Ratatui `canvas.rs` `test_diagonal_lines` (cases x_sign, plus_sign).
			-- Undrawn cells are spaces here ('x' in Ratatui).
		do
			assert_buffer_lines ("x_sign", custom_lines_canvas ('%/0xD7/', <<[0.0, 10.0, 10.0, 0.0], [0.0, 0.0, 10.0, 10.0]>>), <<
				{STRING_32} "%/0xD7/   %/0xD7/",
				{STRING_32} " %/0xD7/ %/0xD7/ ",
				{STRING_32} "  %/0xD7/  ",
				{STRING_32} " %/0xD7/ %/0xD7/ ",
				{STRING_32} "%/0xD7/   %/0xD7/"
			>>)
			assert_buffer_lines ("plus_sign", custom_lines_canvas ('+', <<[0.0, 10.0, 10.0, 0.0], [0.0, 0.0, 10.0, 10.0]>>), <<
				{STRING_32} "+   +",
				{STRING_32} " + + ",
				{STRING_32} "  +  ",
				{STRING_32} " + + ",
				{STRING_32} "+   +"
			>>)
		end

	test_ratatui_horizontal_with_vertical_cell_markers
			-- B2: Ratatui `canvas.rs` `test_horizontal_with_vertical` (cases block, half_block, bar,
			-- dot). Bar draws Ratatui's `symbols::bar::HALF` ('▄', U+2584). Undrawn cells are spaces
			-- here ('x' in Ratatui, see the pattern markers).
		do
			assert_buffer_lines ("block", lines_canvas ({CANVAS_MARKER}.block, <<[0.0, 0.0, 0.0, 10.0], [0.0, 0.0, 10.0, 0.0]>>), <<
				{STRING_32} "%/0x2588/    ",
				{STRING_32} "%/0x2588/    ",
				{STRING_32} "%/0x2588/    ",
				{STRING_32} "%/0x2588/    ",
				{STRING_32} "%/0x2588/%/0x2588/%/0x2588/%/0x2588/%/0x2588/"
			>>)
			assert_buffer_lines ("half_block", lines_canvas ({CANVAS_MARKER}.half_block, <<[0.0, 0.0, 0.0, 10.0], [0.0, 0.0, 10.0, 0.0]>>), <<
				{STRING_32} "%/0x2588/    ",
				{STRING_32} "%/0x2588/    ",
				{STRING_32} "%/0x2588/    ",
				{STRING_32} "%/0x2588/    ",
				{STRING_32} "%/0x2588/%/0x2584/%/0x2584/%/0x2584/%/0x2584/"
			>>)
			assert_buffer_lines ("bar", lines_canvas ({CANVAS_MARKER}.bar, <<[0.0, 0.0, 0.0, 10.0], [0.0, 0.0, 10.0, 0.0]>>), <<
				{STRING_32} "%/0x2584/    ",
				{STRING_32} "%/0x2584/    ",
				{STRING_32} "%/0x2584/    ",
				{STRING_32} "%/0x2584/    ",
				{STRING_32} "%/0x2584/%/0x2584/%/0x2584/%/0x2584/%/0x2584/"
			>>)
			assert_buffer_lines ("dot", lines_canvas ({CANVAS_MARKER}.dot, <<[0.0, 0.0, 0.0, 10.0], [0.0, 0.0, 10.0, 0.0]>>), <<
				{STRING_32} "%/0x2022/    ",
				{STRING_32} "%/0x2022/    ",
				{STRING_32} "%/0x2022/    ",
				{STRING_32} "%/0x2022/    ",
				{STRING_32} "%/0x2022/%/0x2022/%/0x2022/%/0x2022/%/0x2022/"
			>>)
		end

	test_ratatui_diagonal_lines_cell_markers
			-- B2: Ratatui `canvas.rs` `test_diagonal_lines` (cases block, half_block, bar, dot).
			-- Undrawn cells are spaces here ('x' in Ratatui).
		do
			assert_buffer_lines ("block", lines_canvas ({CANVAS_MARKER}.block, <<[0.0, 10.0, 10.0, 0.0], [0.0, 0.0, 10.0, 10.0]>>), <<
				{STRING_32} "%/0x2588/   %/0x2588/",
				{STRING_32} " %/0x2588/ %/0x2588/ ",
				{STRING_32} "  %/0x2588/  ",
				{STRING_32} " %/0x2588/ %/0x2588/ ",
				{STRING_32} "%/0x2588/   %/0x2588/"
			>>)
			assert_buffer_lines ("half_block", lines_canvas ({CANVAS_MARKER}.half_block, <<[0.0, 10.0, 10.0, 0.0], [0.0, 0.0, 10.0, 10.0]>>), <<
				{STRING_32} "%/0x2588/   %/0x2588/",
				{STRING_32} " %/0x2588/ %/0x2588/ ",
				{STRING_32} "  %/0x2588/  ",
				{STRING_32} " %/0x2588/ %/0x2588/ ",
				{STRING_32} "%/0x2588/   %/0x2588/"
			>>)
			assert_buffer_lines ("bar", lines_canvas ({CANVAS_MARKER}.bar, <<[0.0, 10.0, 10.0, 0.0], [0.0, 0.0, 10.0, 10.0]>>), <<
				{STRING_32} "%/0x2584/   %/0x2584/",
				{STRING_32} " %/0x2584/ %/0x2584/ ",
				{STRING_32} "  %/0x2584/  ",
				{STRING_32} " %/0x2584/ %/0x2584/ ",
				{STRING_32} "%/0x2584/   %/0x2584/"
			>>)
			assert_buffer_lines ("dot", lines_canvas ({CANVAS_MARKER}.dot, <<[0.0, 10.0, 10.0, 0.0], [0.0, 0.0, 10.0, 10.0]>>), <<
				{STRING_32} "%/0x2022/   %/0x2022/",
				{STRING_32} " %/0x2022/ %/0x2022/ ",
				{STRING_32} "  %/0x2022/  ",
				{STRING_32} " %/0x2022/ %/0x2022/ ",
				{STRING_32} "%/0x2022/   %/0x2022/"
			>>)
		end

	test_marker_symbols_match_ratatui
			-- B2: the symbol of each one-symbol marker is the one Ratatui's `Canvas::render` gives its
			-- `CharGrid` (`canvas.rs`): Dot `symbols::DOT`, Block `symbols::block::FULL`, Bar
			-- `symbols::bar::HALF`. A Bar layer and a chart dataset with these markers draw them, and
			-- the dataset takes the symbol as its `marker_char`.
		local
			l_ds: TUI_CHART_DATASET
			l_canvas: TUI_CANVAS
			l_layer: CANVAS_LAYER
			l_buf: BUFFER
		do
			assert ("dot", {CANVAS_MARKER}.marker_symbol ({CANVAS_MARKER}.dot) = '%/0x2022/')
			assert ("block", {CANVAS_MARKER}.marker_symbol ({CANVAS_MARKER}.block) = '%/0x2588/')
			assert ("bar", {CANVAS_MARKER}.marker_symbol ({CANVAS_MARKER}.bar) = '%/0x2584/')
			-- HalfBlock draws '▀', '▄' or '█' per cell (Ratatui `HalfBlockGrid`); its nominal symbol is '▀'
			assert ("half block", {CANVAS_MARKER}.marker_symbol ({CANVAS_MARKER}.half_block) = '%/0x2580/')
			-- The dot is the only glyph SYMBOLS_MARKER shares with Ratatui `symbols::marker`
			assert ("SYMBOLS_MARKER dot", {SYMBOLS_MARKER}.dot = {CANVAS_MARKER}.marker_symbol ({CANVAS_MARKER}.dot))
			-- Every marker's symbol fills one cell (checked here, not per drawn cell in `marker_symbol`)
			across {CANVAS_MARKER}.braille.to_integer_32 |..| {CANVAS_MARKER}.custom.to_integer_32 as m loop
				assert ("one column " + m.out,
					{UNICODE_WIDTH}.width ({CANVAS_MARKER}.marker_symbol (m.to_natural_8).natural_32_code) = 1)
			end

			create l_ds.make ("bar")
			l_ds.set_marker ({CANVAS_MARKER}.bar)
			assert ("dataset marker_char", l_ds.marker_char = '%/0x2584/')
			assert_chart_marker_row ({CANVAS_MARKER}.bar, '%/0x2584/')
			assert_chart_marker_row ({CANVAS_MARKER}.block, '%/0x2588/')
			assert_chart_marker_row ({CANVAS_MARKER}.dot, '%/0x2022/')

			-- A Bar layer on a Braille canvas: 3 x 1 cells, one point in the middle cell
			create l_canvas.make
			l_canvas.set_bounds (0.0, 2.0, 0.0, 1.0)
			create l_layer.make_with_painter (agent (p: CANVAS_PAINTER)
				do
					p.draw_point (1.0, 0.0)
				end)
			l_layer.set_marker ({CANVAS_MARKER}.bar)
			l_canvas.add_layer (l_layer)
			create l_buf.make (3, 1)
			l_canvas.render (l_buf.area, l_buf)
			assert_buffer_lines ("bar layer", l_buf, <<{STRING_32} " %/0x2584/ ">>)
		end

	test_ratatui_rectangle_block_lines
			-- B3: Ratatui `canvas/rectangle.rs` `draw_block_lines`: a red rectangle on a 10 x 10
			-- Block canvas. Block puts its colour in the fg and the bg (`CharGrid::apply_color_to_bg`).
		local
			l_buf: BUFFER
		do
			l_buf := rectangle_canvas ({CANVAS_MARKER}.block)
			assert_buffer_lines ("draw_block_lines", l_buf, ring_rows (
				{STRING_32} "%/0x2588/%/0x2588/%/0x2588/%/0x2588/%/0x2588/%/0x2588/%/0x2588/%/0x2588/%/0x2588/%/0x2588/",
				{STRING_32} "%/0x2588/        %/0x2588/",
				{STRING_32} "%/0x2588/%/0x2588/%/0x2588/%/0x2588/%/0x2588/%/0x2588/%/0x2588/%/0x2588/%/0x2588/%/0x2588/"))
			-- R: red on red
			assert_buffer_colors ("draw_block_lines", l_buf, 0, 0, <<['R', {COLOR}.red, {COLOR}.red]>>,
				ring_rows ("RRRRRRRRRR", "R........R", "RRRRRRRRRR"))
		end

	test_ratatui_rectangle_half_block_lines
			-- B3: Ratatui `canvas/rectangle.rs` `draw_half_block_lines`: a red rectangle on a 10 x 10
			-- HalfBlock canvas. A cell with both halves red is '█' red on red; the top and bottom
			-- edges are '▀' and '▄' with only the fg set (`HalfBlockGrid::save`).
		local
			l_buf: BUFFER
		do
			l_buf := rectangle_canvas ({CANVAS_MARKER}.half_block)
			assert_buffer_lines ("draw_half_block_lines", l_buf, ring_rows (
				{STRING_32} "%/0x2588/%/0x2580/%/0x2580/%/0x2580/%/0x2580/%/0x2580/%/0x2580/%/0x2580/%/0x2580/%/0x2588/",
				{STRING_32} "%/0x2588/        %/0x2588/",
				{STRING_32} "%/0x2588/%/0x2584/%/0x2584/%/0x2584/%/0x2584/%/0x2584/%/0x2584/%/0x2584/%/0x2584/%/0x2588/"))
			-- R: red on red; r: red fg only
			assert_buffer_colors ("draw_half_block_lines", l_buf, 0, 0, <<['R', {COLOR}.red, {COLOR}.red], ['r', {COLOR}.red, create {COLOR}]>>,
				ring_rows ("RrrrrrrrrR", "R........R", "RrrrrrrrrR"))
		end

	test_ratatui_rectangle_braille_lines
			-- B3: Ratatui `canvas/rectangle.rs` `draw_braille_lines`: a red and a green rectangle on
			-- a 10 x 10 Braille canvas, bounds [0, 20] x [0, 20]. Pattern markers set the fg only.
		local
			l_canvas: TUI_CANVAS
			l_buf: BUFFER
		do
			create l_canvas.make
			l_canvas.set_bounds (0.0, 20.0, 0.0, 20.0)
			l_canvas.add_shape (create {SHAPE_RECT}.make (0.0, 0.0, 20.0, 20.0, create {STYLE}.make_fg ({COLOR}.red)))
			l_canvas.add_shape (create {SHAPE_RECT}.make (4.0, 4.0, 12.0, 12.0, create {STYLE}.make_fg ({COLOR}.green)))
			create l_buf.make (10, 10)
			l_canvas.render (l_buf.area, l_buf)
			assert_buffer_lines ("draw_braille_lines", l_buf, braille_hex_rows (<<
				"4F0909090909090909B9",
				"470000000000000000B8",
				"47004F09090909B900B8",
				"47004700000000B800B8",
				"47004700000000B800B8",
				"47004700000000B800B8",
				"47004700000000B800B8",
				"4700C7C0C0C0C0F800B8",
				"470000000000000000B8",
				"C7C0C0C0C0C0C0C0C0F8">>))
			assert_buffer_colors ("draw_braille_lines", l_buf, 0, 0, <<['r', {COLOR}.red, create {COLOR}], ['g', {COLOR}.green, create {COLOR}]>>, <<
				"rrrrrrrrrr",
				"r........r",
				"r.gggggg.r",
				"r.g....g.r",
				"r.g....g.r",
				"r.g....g.r",
				"r.g....g.r",
				"r.gggggg.r",
				"r........r",
				"rrrrrrrrrr">>)
		end

	test_ratatui_rectangle_custom_lines
			-- B3: Ratatui `canvas/rectangle.rs` `draw_x_lines` and `draw_plus_lines`: a red rectangle
			-- with the Custom markers '×' and '+'. A Custom marker sets the fg only.
		local
			l_buf: BUFFER
			l_char: CHARACTER_32
			l_side: STRING_32
		do
			across <<{CHARACTER_32} '%/0xD7/', {CHARACTER_32} '+'>> as ch loop
				l_char := ch
				create l_side.make_filled (' ', 10)
				l_side [1] := l_char
				l_side [10] := l_char
				l_buf := rectangle_canvas_with ((create {TUI_CANVAS}.make).with_custom_marker (l_char))
				assert_buffer_lines ("custom " + l_char.out, l_buf, ring_rows (
					create {STRING_32}.make_filled (l_char, 10),
					l_side,
					create {STRING_32}.make_filled (l_char, 10)))
				assert_buffer_colors ("custom " + l_char.out, l_buf, 0, 0, <<['r', {COLOR}.red, create {COLOR}]>>,
					ring_rows ("rrrrrrrrrr", "r........r", "rrrrrrrrrr"))
			end
		end

	test_ratatui_chart_overlapping_lines
			-- B3: Ratatui `chart.rs` `overlapping_lines` (cases dot and braille): a blue Block line
			-- (0, 0) -> (5, 5), then a red line (0, 5) -> (5, 0) with the Dot or Braille marker, bounds
			-- [0, 5] x [0, 5], 5 x 5 plot. Where they cross, the Block layer's blue bg stays under the
			-- red symbol of the layer above (Ratatui `LayerCell`). TUI_CHART always draws the axes, so
			-- the buffer is 6 x 6 and the plot is columns 1..5, rows 0..4.
		local
			l_chart: TUI_CHART
			l_up, l_down: TUI_CHART_DATASET
			l_buf: BUFFER
			l_symbol: STRING_32
			l_case: STRING
		do
			across <<{CANVAS_MARKER}.dot, {CANVAS_MARKER}.braille>> as m loop
				if m = {CANVAS_MARKER}.dot then
					l_symbol := {STRING_32} "%/0x2022/"
					l_case := "dot"
				else
					l_symbol := {STRING_32} "%/0x28A3/"
					l_case := "braille"
				end
				create l_up.make ("up")
				l_up.append_point (0.0, 0.0)
				l_up.append_point (5.0, 5.0)
				l_up := l_up.with_marker ({CANVAS_MARKER}.block).with_graph_type ({CHART_GRAPH_TYPE}.line).with_style (create {STYLE}.make_fg ({COLOR}.blue))
				create l_down.make ("down")
				l_down.append_point (0.0, 5.0)
				l_down.append_point (5.0, 0.0)
				l_down := l_down.with_marker (m).with_graph_type ({CHART_GRAPH_TYPE}.line).with_style (create {STYLE}.make_fg ({COLOR}.red))
				create l_chart.make_with_datasets (<<l_up, l_down>>)
				l_chart.set_x_bounds (0.0, 5.0)
				l_chart.set_y_bounds (0.0, 5.0)
				create l_buf.make (6, 6)
				l_chart.render (l_buf.area, l_buf)
				assert_buffer_lines ("overlapping_lines " + l_case, l_buf, <<
					{STRING_32} "%/0x2502/" + l_symbol + "   %/0x2588/",
					{STRING_32} "%/0x2502/ " + l_symbol + " %/0x2588/ ",
					{STRING_32} "%/0x2502/  " + l_symbol + "  ",
					{STRING_32} "%/0x2502/ %/0x2588/ " + l_symbol + " ",
					{STRING_32} "%/0x2502/%/0x2588/   " + l_symbol,
					{STRING_32} "%/0x2514/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/">>)
				-- r: red fg; B: blue on blue; X: red on blue (the crossing)
				assert_buffer_colors ("overlapping_lines " + l_case, l_buf, 1, 0,
					<<['r', {COLOR}.red, create {COLOR}], ['B', {COLOR}.blue, {COLOR}.blue], ['X', {COLOR}.red, {COLOR}.blue]>>, <<
					"r...B",
					".r.B.",
					"..X..",
					".B.r.",
					"B...r">>)
			end
		end

	test_half_block_cell_colours
			-- B3: the four states of a HalfBlock cell (Ratatui `HalfBlockGrid::save`): upper only '▀'
			-- with the upper colour as fg; lower only '▄' with the lower colour as fg; two colours '▀'
			-- with the upper colour as fg and the lower one as bg; one colour twice '█' with it as fg
			-- and bg. 5 x 1 cells, one dot per world unit (bounds [0, 4] x [0, 1]: y 1 is the upper half).
			-- The colour policy works per half: in the last cell the upper half is drawn red, then green.
		local
			l_canvas: TUI_CANVAS
			l_buf: BUFFER
		do
			create l_canvas.make
			l_canvas.set_marker ({CANVAS_MARKER}.half_block)
			l_canvas.set_bounds (0.0, 4.0, 0.0, 1.0)
			l_canvas.set_painter (agent (p: CANVAS_PAINTER)
				do
					p.set_style (create {STYLE}.make_fg ({COLOR}.red))
					p.draw_point (0.0, 1.0)
					p.draw_point (2.0, 1.0)
					p.draw_point (3.0, 1.0)
					p.draw_point (3.0, 0.0)
					p.draw_point (4.0, 1.0)
					p.set_style (create {STYLE}.make_fg ({COLOR}.blue))
					p.draw_point (1.0, 0.0)
					p.draw_point (2.0, 0.0)
					p.draw_point (4.0, 0.0)
					p.set_style (create {STYLE}.make_fg ({COLOR}.green))
					p.draw_point (4.0, 1.0)
				end)
			create l_buf.make (5, 1)
			l_canvas.render (l_buf.area, l_buf)
			assert_buffer_lines ("last wins", l_buf, <<{STRING_32} "%/0x2580/%/0x2584/%/0x2580/%/0x2588/%/0x2580/">>)
			-- r: red fg; b: blue fg; X: red on blue; R: red on red; G: green on blue
			assert_buffer_colors ("last wins", l_buf, 0, 0, <<['r', {COLOR}.red, create {COLOR}], ['b', {COLOR}.blue, create {COLOR}],
				['X', {COLOR}.red, {COLOR}.blue], ['R', {COLOR}.red, {COLOR}.red], ['G', {COLOR}.green, {COLOR}.blue]>>, <<"rbXRG">>)

			l_canvas.set_color_policy ({BRAILLE_CANVAS}.policy_first_wins)
			create l_buf.make (5, 1)
			l_canvas.render (l_buf.area, l_buf)
			assert_buffer_lines ("first wins", l_buf, <<{STRING_32} "%/0x2580/%/0x2584/%/0x2580/%/0x2588/%/0x2580/">>)
			-- The upper half of the last cell keeps its first colour; its lower half is still blue
			assert_buffer_colors ("first wins", l_buf, 0, 0, <<['r', {COLOR}.red, create {COLOR}], ['b', {COLOR}.blue, create {COLOR}],
				['X', {COLOR}.red, {COLOR}.blue], ['R', {COLOR}.red, {COLOR}.red]>>, <<"rbXRX">>)
		end

	test_layer_cell_sets_only_its_fields
			-- B3: Ratatui `LayerCell` (`canvas.rs`): a layer cell sets only the symbol, fg and bg it
			-- has. A Block base fills three cells blue (fg and bg). Above it, a red Braille layer
			-- draws in the middle cell, a green HalfBlock layer the upper half of the right cell, and
			-- a Dot layer whose style has no colour the left cell. Each keeps the blue bg below; the
			-- Dot layer keeps the blue fg too (EiffelTUI: a default colour sets nothing, where a
			-- Ratatui shape always has a colour, `Color::Reset` at least).
		local
			l_canvas: TUI_CANVAS
			l_layer: CANVAS_LAYER
			l_buf: BUFFER
		do
			-- 3 x 1 cells: Block 3 x 1 dots, Braille 6 x 4, HalfBlock 3 x 2, Dot 3 x 1
			create l_canvas.make
			l_canvas.set_marker ({CANVAS_MARKER}.block)
			l_canvas.set_bounds (0.0, 5.0, 0.0, 3.0)
			l_canvas.set_painter (agent (p: CANVAS_PAINTER)
				do
					p.set_style (create {STYLE}.make_fg ({COLOR}.blue))
					p.draw_line (0.0, 0.0, 5.0, 0.0)
				end)
			create l_layer.make_with_painter (agent (p: CANVAS_PAINTER)
				do
					p.set_style (create {STYLE}.make_fg ({COLOR}.red))
					p.draw_point (2.0, 3.0)
				end)
			l_layer.set_marker ({CANVAS_MARKER}.braille)
			l_canvas.add_layer (l_layer)
			create l_layer.make_with_painter (agent (p: CANVAS_PAINTER)
				do
					p.set_style (create {STYLE}.make_fg ({COLOR}.green))
					p.draw_point (5.0, 3.0)
				end)
			l_layer.set_marker ({CANVAS_MARKER}.half_block)
			l_canvas.add_layer (l_layer)
			create l_layer.make_with_painter (agent (p: CANVAS_PAINTER)
				do
					p.draw_point (0.0, 0.0)
				end)
			l_layer.set_marker ({CANVAS_MARKER}.dot)
			l_canvas.add_layer (l_layer)
			create l_buf.make (3, 1)
			l_canvas.render (l_buf.area, l_buf)
			assert_buffer_lines ("dot, braille, upper half", l_buf, <<{STRING_32} "%/0x2022/%/0x2801/%/0x2580/">>)
			-- B: blue on blue; X: red on blue; G: green on blue
			assert_buffer_colors ("bg kept under each layer", l_buf, 0, 0, <<['B', {COLOR}.blue, {COLOR}.blue],
				['X', {COLOR}.red, {COLOR}.blue], ['G', {COLOR}.green, {COLOR}.blue]>>, <<"BXG">>)
		end

	test_custom_marker_layers_use_their_own_char
			-- V2: a layer with its own Custom marker draws its own character; a layer without a
			-- marker uses the canvas marker and character.
		local
			l_canvas: TUI_CANVAS
			l_layer: CANVAS_LAYER
			l_buf: BUFFER
		do
			-- 3 x 1 cells, one dot per cell: the base draws the left cell, layers the others
			create l_canvas.make
			l_canvas.set_custom_marker ('+')
			l_canvas.set_bounds (0.0, 2.0, 0.0, 1.0)
			l_canvas.set_painter (agent (p: CANVAS_PAINTER) do p.draw_point (0.0, 0.0) end)
			create l_layer.make_with_painter (agent (p: CANVAS_PAINTER) do p.draw_point (1.0, 0.0) end)
			l_canvas.add_layer (l_layer.with_custom_marker ('%/0xD7/'))
			create l_layer.make_with_painter (agent (p: CANVAS_PAINTER) do p.draw_point (2.0, 0.0) end)
			l_canvas.add_layer (l_layer)
			create l_buf.make (3, 1)
			l_canvas.render (l_buf.area, l_buf)
			assert_buffer_lines ("base +, layer x, layer with the canvas marker +", l_buf, <<{STRING_32} "+%/0xD7/+">>)

			-- A Custom layer over a Braille base, drawing over a base cell
			create l_canvas.make
			l_canvas.set_bounds (0.0, 5.0, 0.0, 3.0)
			l_canvas.set_painter (agent (p: CANVAS_PAINTER) do p.draw_line (0.0, 0.0, 5.0, 0.0) end)
			create l_layer.make_with_painter (agent (p: CANVAS_PAINTER) do p.draw_point (2.5, 0.0) end)
			l_layer.set_custom_marker ('o')
			l_canvas.add_layer (l_layer)
			create l_buf.make (3, 1)
			l_canvas.render (l_buf.area, l_buf)
			-- Braille dots 7 + 8 (bottom row) = U+28C0; the layer's grid is 3 x 1 dots, x = 2.5 is its middle cell
			assert_buffer_lines ("braille, custom, braille", l_buf, <<{STRING_32} "%/0x28C0/o%/0x28C0/">>)
		end

	test_chart_dataset_custom_marker
			-- V2: a chart dataset with the Custom marker draws its line and its scatter points
			-- with its own character; two datasets keep their own characters.
		local
			l_chart: TUI_CHART
			l_line, l_points: TUI_CHART_DATASET
			l_buf: BUFFER
			r, c, l_plus, l_other: INTEGER
		do
			create l_line.make ("line")
			l_line := l_line.with_custom_marker ('%/0xD7/')
			l_line.append_point (0.0, 0.0)
			l_line.append_point (10.0, 0.0)
			create l_points.make ("points")
			l_points := l_points.with_graph_type ({CHART_GRAPH_TYPE}.scatter).with_custom_marker ('+')
			l_points.append_point (5.0, 5.0)
			l_points.append_point (10.0, 10.0)
			create l_chart.make_with_datasets (<<l_line, l_points>>)
			l_chart.set_x_bounds (0.0, 10.0)
			l_chart.set_y_bounds (0.0, 10.0)
			-- 8 x 5: y axis in column 0, x axis on row 4, plot 7 x 4
			create l_buf.make (8, 5)
			l_chart.render (l_buf.area, l_buf)
			from c := 1 until c >= 8 loop
				assert_cell_symbol ("line column " + c.out, l_buf, 3, c, {STRING_32} "%/0xD7/")
				c := c + 1
			end
			assert_cell_symbol ("point at the top right", l_buf, 0, 7, "+")
			from r := 0 until r >= 3 loop
				from c := 1 until c >= 8 loop
					if l_buf.cell (r, c).symbol.same_string ("+") then
						l_plus := l_plus + 1
					elseif not l_buf.cell (r, c).symbol.same_string (" ") then
						l_other := l_other + 1
					end
					c := c + 1
				end
				r := r + 1
			end
			assert ("two scatter points", l_plus = 2)
			assert ("nothing else above the line", l_other = 0)
		end

	test_custom_marker_builders_and_defaults
			-- V2: `with_custom_marker` leaves the original unchanged; `set_marker (custom)` without
			-- a character keeps the current one ({CANVAS_MARKER}.default_custom_char at first).
		local
			l_canvas, l_custom: TUI_CANVAS
			l_layer, l_custom_layer: CANVAS_LAYER
			l_ds, l_custom_ds: TUI_CHART_DATASET
		do
			-- Canvas
			create l_canvas.make
			l_custom := l_canvas.with_custom_marker ('%/0xD7/')
			assert ("canvas original marker", l_canvas.marker = {CANVAS_MARKER}.braille)
			assert ("canvas original char", l_canvas.custom_marker_char = {CANVAS_MARKER}.default_custom_char)
			assert ("canvas result", l_custom.marker = {CANVAS_MARKER}.custom and l_custom.custom_marker_char = '%/0xD7/')
			assert ("char in is_equal", not l_custom.is_equal (l_canvas.with_custom_marker ('+')))
			assert ("same char equal", l_custom.is_equal (l_canvas.with_custom_marker ('%/0xD7/')))
			assert ("twin keeps char", l_custom.twin.custom_marker_char = '%/0xD7/')
			l_canvas.set_marker ({CANVAS_MARKER}.custom)
			assert ("canvas default char", l_canvas.custom_marker_char = {CANVAS_MARKER}.default_custom_char)
			l_custom.set_marker ({CANVAS_MARKER}.dot)
			l_custom.set_marker ({CANVAS_MARKER}.custom)
			assert ("canvas char kept", l_custom.custom_marker_char = '%/0xD7/')

			-- Layer
			create l_layer.make
			l_layer.add_shape (create {SHAPE_POINTS}.make (<<[1.0, 1.0]>>, create {STYLE}.default_create))
			l_custom_layer := l_layer.with_custom_marker ('+')
			assert ("layer original", l_layer.marker = 0 and l_layer.custom_marker_char = {CANVAS_MARKER}.default_custom_char)
			assert ("layer result", l_custom_layer.marker = {CANVAS_MARKER}.custom and l_custom_layer.custom_marker_char = '+')
			assert ("layer shapes copied", l_custom_layer.shapes.count = 1 and l_custom_layer.shapes.first /= l_layer.shapes.first)
			assert ("layer char in is_equal", not l_custom_layer.is_equal (l_layer.with_custom_marker ('o')))
			l_layer.set_marker ({CANVAS_MARKER}.custom)
			assert ("layer default char", l_layer.custom_marker_char = {CANVAS_MARKER}.default_custom_char)

			-- Dataset
			create l_ds.make ("ds")
			l_custom_ds := l_ds.with_custom_marker ('+')
			assert ("dataset original", l_ds.marker = {CANVAS_MARKER}.braille and l_ds.marker_char = '%/0x2022/')
			assert ("dataset result", l_custom_ds.marker = {CANVAS_MARKER}.custom and l_custom_ds.marker_char = '+')
			l_ds.set_marker_char ('o')
			l_ds.set_marker ({CANVAS_MARKER}.custom)
			assert ("dataset char kept", l_ds.marker_char = 'o')
			l_ds.set_marker ({CANVAS_MARKER}.dot)
			l_ds.set_marker_char ('%/0x5BBD/')
			l_ds.set_marker ({CANVAS_MARKER}.custom)
			assert ("dataset wide char replaced", l_ds.marker_char = {CANVAS_MARKER}.default_custom_char)
		end

	test_dataset_custom_marker_after_blank_symbol_marker
			-- V2 review #1: `set_marker` gives Braille, Quadrant, Sextant and Octant the blank Braille
			-- symbol (U+2800) as `marker_char`. Switching to Custom afterwards must not keep it, or the
			-- line draws blank cells; it uses {CANVAS_MARKER}.default_custom_char instead.
		local
			l_chart: TUI_CHART
			l_ds: TUI_CHART_DATASET
			l_buf: BUFFER
			l_markers: ARRAY [NATURAL_8]
			i, c: INTEGER
		do
			assert ("blank Braille is not a custom char", not {CANVAS_MARKER}.is_valid_custom_char ({CANVAS_MARKER}.blank_braille))
			l_markers := <<{CANVAS_MARKER}.braille, {CANVAS_MARKER}.quadrant, {CANVAS_MARKER}.sextant, {CANVAS_MARKER}.octant>>
			from i := l_markers.lower until i > l_markers.upper loop
				create l_ds.make ("ds")
				l_ds := l_ds.with_marker (l_markers [i]).with_marker ({CANVAS_MARKER}.custom)
				assert ("default char after marker " + l_markers [i].out, l_ds.marker_char = {CANVAS_MARKER}.default_custom_char)
				l_ds.append_point (0.0, 0.0)
				l_ds.append_point (10.0, 0.0)
				create l_chart.make_with_datasets (<<l_ds>>)
				l_chart.set_x_bounds (0.0, 10.0)
				l_chart.set_y_bounds (0.0, 10.0)
				-- 8 x 5: y axis in column 0, x axis on row 4, plot 7 x 4
				create l_buf.make (8, 5)
				l_chart.render (l_buf.area, l_buf)
				from c := 1 until c >= 8 loop
					assert_cell_symbol ("line visible after marker " + l_markers [i].out + ", column " + c.out,
						l_buf, 3, c, {STRING_32} "%/0x2022/")
					c := c + 1
				end
				i := i + 1
			end
		end

	test_snapshot_failure_message_is_readable
			-- Review: a failing snapshot with characters above U+00FF reports both rows, with those
			-- characters as <U+XXXX>, instead of failing a precondition while building the message.
		local
			l_buf: BUFFER
			l_message: detachable READABLE_STRING_GENERAL
		do
			l_buf := lines_canvas ({CANVAS_MARKER}.sextant, <<[0.0, 10.0, 10.0, 0.0], [0.0, 0.0, 10.0, 10.0]>>)
			l_message := assertion_message (agent assert_buffer_lines ("probe", l_buf, <<{STRING_32} "%/0x1FB38/ ab">>))
			assert ("a failure is reported", attached l_message)
			if attached l_message as m then
				assert ("row and expected text", m.same_string ("probe [row 0]: expected %"<U+1FB38> ab%" but got %"<U+1FB27>   <U+1FB14>%""))
			end
		end

	test_custom_marker_refuses_wide_char
			-- V2: a wide (U+5BBD) or zero-width (U+0301) character is refused by the precondition.
		local
			l_canvas: TUI_CANVAS
			l_layer: CANVAS_LAYER
			l_ds: TUI_CHART_DATASET
		do
			assert ("width of U+5BBD", {UNICODE_WIDTH}.width (0x5BBD) = 2)
			assert ("width of U+0301", {UNICODE_WIDTH}.width (0x301) = 0)
			create l_canvas.make
			create l_layer.make
			create l_ds.make ("ds")
			assert ("canvas set wide", precondition_raised (agent l_canvas.set_custom_marker ('%/0x5BBD/'), "one_column"))
			assert ("canvas set zero width", precondition_raised (agent l_canvas.set_custom_marker ('%/0x301/'), "one_column"))
			assert ("canvas set blank Braille", precondition_raised (agent l_canvas.set_custom_marker ('%/0x2800/'), "one_column"))
			assert ("canvas with wide", precondition_raised (agent l_canvas.with_custom_marker ('%/0x5BBD/'), "one_column"))
			assert ("layer set wide", precondition_raised (agent l_layer.set_custom_marker ('%/0x5BBD/'), "one_column"))
			assert ("layer with wide", precondition_raised (agent l_layer.with_custom_marker ('%/0x5BBD/'), "one_column"))
			assert ("dataset set wide", precondition_raised (agent l_ds.set_custom_marker ('%/0x5BBD/'), "one_column"))
			assert ("dataset with wide", precondition_raised (agent l_ds.with_custom_marker ('%/0x5BBD/'), "one_column"))
			l_ds.set_custom_marker ('+')
			assert ("dataset wide char while custom", precondition_raised (agent l_ds.set_marker_char ('%/0x5BBD/'), "one_column_when_custom"))
			assert ("one column accepted", not precondition_raised (agent l_canvas.set_custom_marker ('%/0xD7/'), "one_column"))
			assert ("nothing changed", l_canvas.custom_marker_char = '%/0xD7/' and l_layer.marker = 0 and l_ds.marker_char = '+')
		end

	test_ratatui_filled_line_cases_dot_marker
			-- V3: Ratatui `canvas/line.rs` `tests_filled` (all 22 cases: filled_off_grid1..8,
			-- filled_horizontal1..4, filled_vertical1..2, filled_diagonal1..4, filled_split1..2).
			-- One filled line in red on a 10 x 10 Dot canvas, bounds [0, 10] x [0, 10].
			-- The off_grid cases also cover clipping, and off_grid5 the clamping of `fill_to_y` (-10).
			-- Rows are written with '*' for the Dot marker's '•' (see `dot_rows`).
		local
			e, f: STRING
			l_buf: BUFFER
		do
			e := "          "
			f := "**********"
			assert_buffer_lines ("filled_off_grid1", filled_dot_canvas (-1.0, 0.0, -1.0, 10.0, 0.0), dot_rows (<<e, e, e, e, e, e, e, e, e, e>>))
			assert_buffer_lines ("filled_off_grid2", filled_dot_canvas (0.0, -1.0, 10.0, -1.0, 0.0), dot_rows (<<e, e, e, e, e, e, e, e, e, e>>))
			assert_buffer_lines ("filled_off_grid3", filled_dot_canvas (-10.0, 5.0, -1.0, 5.0, 0.0), dot_rows (<<e, e, e, e, e, e, e, e, e, e>>))
			assert_buffer_lines ("filled_off_grid4", filled_dot_canvas (5.0, 11.0, 5.0, 20.0, 0.0), dot_rows (<<e, e, e, e, e, e, e, e, e, e>>))
			assert_buffer_lines ("filled_off_grid5", filled_dot_canvas (-10.0, 0.0, 5.0, 0.0, -10.0),
				dot_rows (<<e, e, e, e, e, e, e, e, e, "******    ">>))
			assert_buffer_lines ("filled_off_grid6", filled_dot_canvas (0.0, 0.0, 10.0, 10.0, 0.0), dot_rows (lower_triangle_rows))
			assert_buffer_lines ("filled_off_grid7", filled_dot_canvas (0.0, 0.0, 11.0, 11.0, 0.0), dot_rows (lower_triangle_rows))
			assert_buffer_lines ("filled_off_grid8", filled_dot_canvas (-1.0, -1.0, 11.0, 11.0, 0.0), dot_rows (lower_triangle_rows))
			assert_buffer_lines ("filled_horizontal1", filled_dot_canvas (0.0, 0.0, 10.0, 0.0, 0.0),
				dot_rows (<<e, e, e, e, e, e, e, e, e, f>>))
			assert_buffer_lines ("filled_horizontal2", filled_dot_canvas (0.0, 0.0, 10.0, 0.0, 10.0),
				dot_rows (<<f, f, f, f, f, f, f, f, f, f>>))
			assert_buffer_lines ("filled_horizontal3", filled_dot_canvas (10.0, 10.0, 0.0, 10.0, 10.0),
				dot_rows (<<f, e, e, e, e, e, e, e, e, e>>))
			assert_buffer_lines ("filled_horizontal4", filled_dot_canvas (10.0, 10.0, 0.0, 10.0, 0.0),
				dot_rows (<<f, f, f, f, f, f, f, f, f, f>>))
			assert_buffer_lines ("filled_vertical1", filled_dot_canvas (0.0, 0.0, 0.0, 10.0, 0.0), dot_rows (<<
				"*         ", "*         ", "*         ", "*         ", "*         ",
				"*         ", "*         ", "*         ", "*         ", "*         ">>))
			assert_buffer_lines ("filled_vertical2", filled_dot_canvas (10.0, 10.0, 10.0, 0.0, 0.0), dot_rows (<<
				"         *", "         *", "         *", "         *", "         *",
				"         *", "         *", "         *", "         *", "         *">>))
			-- dy < dx, x1 < x2
			assert_buffer_lines ("filled_diagonal1", filled_dot_canvas (0.0, 0.0, 10.0, 5.0, 0.0), dot_rows (<<e, e, e, e, e,
				"        **", "      ****", "    ******", "  ********", f>>))
			-- dy < dx, x1 > x2
			assert_buffer_lines ("filled_diagonal2", filled_dot_canvas (10.0, 0.0, 0.0, 5.0, 0.0), dot_rows (<<e, e, e, e, e,
				"**        ", "****      ", "******    ", "********  ", f>>))
			-- dy > dx, y1 < y2
			assert_buffer_lines ("filled_diagonal3", filled_dot_canvas (0.0, 0.0, 5.0, 10.0, 0.0), dot_rows (<<
				"     *    ", "    **    ", "    **    ", "   ***    ", "   ***    ",
				"  ****    ", "  ****    ", " *****    ", " *****    ", "******    ">>))
			-- dy > dx, y1 > y2
			assert_buffer_lines ("filled_diagonal4", filled_dot_canvas (0.0, 10.0, 5.0, 0.0, 0.0), dot_rows (<<
				"*         ", "**        ", "**        ", "***       ", "***       ",
				"****      ", "****      ", "*****     ", "*****     ", "******    ">>))
			assert_buffer_lines ("filled_split1", filled_dot_canvas (0.0, 0.0, 10.0, 10.0, 5.0), dot_rows (<<
				"         *", "        **", "       ***", "      ****", "     *****",
				f, "****      ", "***       ", "**        ", "*         ">>))
			assert_buffer_lines ("filled_split2", filled_dot_canvas (0.0, 0.0, 10.0, 10.0, 7.0), dot_rows (<<
				"         *", "        **", "       ***", f, "******    ",
				"*****     ", "****      ", "***       ", "**        ", "*         ">>))

			-- Ratatui also checks the colour: painted cells are red, the others keep the default
			l_buf := filled_dot_canvas (0.0, 0.0, 10.0, 5.0, 0.0)
			assert ("filled cell is red", l_buf.cell (7, 4).style.foreground.is_equal ({COLOR}.red))
			assert ("line cell is red", l_buf.cell (5, 9).style.foreground.is_equal ({COLOR}.red))
			assert ("empty cell keeps the default fg", l_buf.cell (4, 4).style.foreground.is_default)
		end

	test_ratatui_chart_filled_line
			-- V3: Ratatui `chart.rs` `filled_line`: a Dot dataset (0, 0), (5, 5), (10, 5) with
			-- `fill_to_y (0.0)` and `GraphType::Area`, bounds [0, 10] x [0, 10], in an 11 x 11 plot.
			-- TUI_CHART always draws the axes, so the buffer is 12 x 12: the y axis in column 0 and the
			-- x axis on row 11 frame Ratatui's 11 x 11 rows, which are columns 1..11, rows 0..10.
		local
			l_chart: TUI_CHART
			l_ds: TUI_CHART_DATASET
			l_buf: BUFFER
		do
			create l_ds.make ("area")
			l_ds.append_point (0.0, 0.0)
			l_ds.append_point (5.0, 5.0)
			l_ds.append_point (10.0, 5.0)
			l_ds := l_ds.with_marker ({CANVAS_MARKER}.dot).with_fill_to_y (0.0).with_graph_type ({CHART_GRAPH_TYPE}.area)
			create l_chart.make_with_datasets (<<l_ds>>)
			l_chart.set_x_bounds (0.0, 10.0)
			l_chart.set_y_bounds (0.0, 10.0)
			create l_buf.make (12, 12)
			l_chart.render (l_buf.area, l_buf)
			assert_buffer_lines ("filled_line", l_buf, framed_plot_rows (<<
				"           ",
				"           ",
				"           ",
				"           ",
				"           ",
				"     ******",
				"    *******",
				"   ********",
				"  *********",
				" **********",
				"***********">>))
		end

	test_chart_area_fill_to_y
			-- V3: `fill_to_y` of an area dataset: above the line when it is the y maximum, clamped
			-- to the y bounds (100 and +infinity fill like 10, -infinity like 0). The line graph type
			-- of the same data draws only the diagonal.
		local
			l_ds: TUI_CHART_DATASET
			l_upper, l_lower: ARRAY [READABLE_STRING_GENERAL]
		do
			create l_ds.make ("area")
			l_ds.append_point (0.0, 0.0)
			l_ds.append_point (10.0, 10.0)
			l_ds := l_ds.with_marker ({CANVAS_MARKER}.dot).with_graph_type ({CHART_GRAPH_TYPE}.area)
			l_upper := framed_plot_rows (<<
				"***********", "********** ", "*********  ", "********   ", "*******    ", "******     ",
				"*****      ", "****       ", "***        ", "**         ", "*          ">>)
			l_lower := framed_plot_rows (<<
				"          *", "         **", "        ***", "       ****", "      *****", "     ******",
				"    *******", "   ********", "  *********", " **********", "***********">>)
			assert_buffer_lines ("fill to y max", area_chart (l_ds.with_fill_to_y (10.0)), l_upper)
			assert_buffer_lines ("fill to 100 is clamped", area_chart (l_ds.with_fill_to_y (100.0)), l_upper)
			assert_buffer_lines ("fill to +infinity is clamped", area_chart (l_ds.with_fill_to_y ({REAL_64}.positive_infinity)), l_upper)
			assert_buffer_lines ("fill to 0 (default)", area_chart (l_ds), l_lower)
			assert_buffer_lines ("fill to -infinity is clamped", area_chart (l_ds.with_fill_to_y ({REAL_64}.negative_infinity)), l_lower)
			assert_buffer_lines ("line type draws the diagonal only", area_chart (l_ds.with_graph_type ({CHART_GRAPH_TYPE}.line)), framed_plot_rows (<<
				"          *", "         * ", "        *  ", "       *   ", "      *    ", "     *     ",
				"    *      ", "   *       ", "  *        ", " *         ", "*          ">>))
		end

	test_chart_single_point_dataset_is_drawn
			-- Review fix #5: TUI_CHART draws every dataset's points first, whatever the graph type,
			-- as Ratatui's chart does. A line or area dataset with one point therefore shows that
			-- point (before, nothing: there is no pair to join). Bar and scatter are unchanged, and
			-- a two-point line still draws only its diagonal.
		local
			l_ds: TUI_CHART_DATASET
			l_point: ARRAY [READABLE_STRING_GENERAL]
		do
			create l_ds.make ("one")
			l_ds.append_point (5.0, 5.0)
			l_ds := l_ds.with_marker ({CANVAS_MARKER}.dot)
			l_point := framed_plot_rows (<<
				"           ", "           ", "           ", "           ", "           ", "     *     ",
				"           ", "           ", "           ", "           ", "           ">>)
			assert_buffer_lines ("line, one point", area_chart (l_ds.with_graph_type ({CHART_GRAPH_TYPE}.line)), l_point)
			assert_buffer_lines ("area, one point", area_chart (l_ds.with_graph_type ({CHART_GRAPH_TYPE}.area)), l_point)
			assert_buffer_lines ("area, one point, fill above", area_chart (l_ds.with_graph_type ({CHART_GRAPH_TYPE}.area).with_fill_to_y (10.0)), l_point)
			assert_buffer_lines ("scatter, one point", area_chart (l_ds.with_graph_type ({CHART_GRAPH_TYPE}.scatter)), l_point)
			assert_buffer_lines ("bar, one point", area_chart (l_ds.with_graph_type ({CHART_GRAPH_TYPE}.bar)), framed_plot_rows (<<
				"           ", "           ", "           ", "           ", "           ", "     *     ",
				"     *     ", "     *     ", "     *     ", "     *     ", "     *     ">>))
		end

	test_chart_dataset_fill_to_y_builders
			-- V3: `fill_to_y` defaults to 0.0; `with_fill_to_y` leaves the original unchanged; the value
			-- counts in `is_equal` and is kept by `twin`; Area is a valid graph type and not `is_line`;
			-- NaN is refused by the precondition, infinities are accepted.
		local
			l_ds, l_other: TUI_CHART_DATASET
		do
			assert ("area is valid", {CHART_GRAPH_TYPE}.is_valid ({CHART_GRAPH_TYPE}.area))
			assert ("5 is not valid", not {CHART_GRAPH_TYPE}.is_valid (5))
			create l_ds.make ("ds")
			assert ("default fill_to_y", l_ds.fill_to_y = 0.0)
			l_other := l_ds.with_fill_to_y (3.5)
			assert ("builder sets", l_other.fill_to_y = 3.5)
			assert ("original unchanged", l_ds.fill_to_y = 0.0)
			assert ("fill_to_y counts in is_equal", not l_ds.is_equal (l_other))
			assert ("twin keeps fill_to_y", l_other.twin.fill_to_y = 3.5 and l_other.twin.is_equal (l_other))
			l_ds.set_fill_to_y (3.5)
			assert ("setter sets", l_ds.fill_to_y = 3.5 and l_ds.is_equal (l_other))
			l_ds.set_graph_type ({CHART_GRAPH_TYPE}.area)
			assert ("area set", l_ds.graph_type = {CHART_GRAPH_TYPE}.area)
			assert ("area is not is_line", not l_ds.is_line)
			assert ("set NaN refused", precondition_raised (agent l_ds.set_fill_to_y ({REAL_64}.nan), "not_nan"))
			assert ("with NaN refused", precondition_raised (agent l_ds.with_fill_to_y ({REAL_64}.nan), "not_nan"))
			assert ("NaN not stored", l_ds.fill_to_y = 3.5)
			assert ("infinity accepted", not precondition_raised (agent l_ds.set_fill_to_y ({REAL_64}.negative_infinity), "not_nan"))
			assert ("infinity set", l_ds.fill_to_y = {REAL_64}.negative_infinity)
		end

	test_shape_filled_line
			-- V3: SHAPE_FILLED_LINE paints as `draw_filled_line` (Ratatui filled_split1 through a shape),
			-- and compares its coordinates, `fill_to_y` and style.
		local
			l_canvas: TUI_CANVAS
			l_buf: BUFFER
			l_red: STYLE
			l_shape: SHAPE_FILLED_LINE
		do
			create l_red.make_fg ({COLOR}.red)
			create l_shape.make (0.0, 0.0, 10.0, 10.0, 5.0, l_red)
			assert ("fill_to_y set", l_shape.fill_to_y = 5.0)
			create l_canvas.make
			l_canvas := l_canvas.with_marker ({CANVAS_MARKER}.dot).with_bounds (0.0, 10.0, 0.0, 10.0).with_shape (l_shape)
			create l_buf.make (10, 10)
			l_canvas.render (l_buf.area, l_buf)
			assert_buffer_lines ("filled_split1 as a shape", l_buf, dot_rows (<<
				"         *", "        **", "       ***", "      ****", "     *****",
				"**********", "****      ", "***       ", "**        ", "*         ">>))
			assert ("shape cell is red", l_buf.cell (5, 0).style.foreground.is_equal ({COLOR}.red))
			assert ("equal shape", l_shape.is_equal (create {SHAPE_FILLED_LINE}.make (0.0, 0.0, 10.0, 10.0, 5.0, create {STYLE}.make_fg ({COLOR}.red))))
			assert ("fill_to_y counts", not l_shape.is_equal (create {SHAPE_FILLED_LINE}.make (0.0, 0.0, 10.0, 10.0, 6.0, l_red)))
			assert ("end counts", not l_shape.is_equal (create {SHAPE_FILLED_LINE}.make (0.0, 0.0, 10.0, 9.0, 5.0, l_red)))
			assert ("style counts", not l_shape.is_equal (create {SHAPE_FILLED_LINE}.make (0.0, 0.0, 10.0, 10.0, 5.0, create {STYLE}.make_fg ({COLOR}.blue))))
		end

	test_filled_line_non_finite_and_far_end
			-- V3: a filled line with a NaN or infinite end, or a NaN `fill_to_y`, draws nothing; an
			-- infinite `fill_to_y` fills to the nearer bound. A filled line to x = 1e9 is clipped
			-- before the walk: 100 draws on bounds [0, 1] take under 1 s, and fill the whole grid.
			-- The dots do not depend on which end comes first (the walk is shared with `draw_line`).
		local
			l_grid, l_ref: BRAILLE_CANVAS
			l_painter: CANVAS_PAINTER
			l_start, l_elapsed: INTEGER_64
			l_cases: ARRAY [TUPLE [x1, y1, x2, y2, fill: REAL_64]]
			i: INTEGER
		do
			create l_grid.make_with_resolution (10, 10, 1, 1)
			create l_painter.make (l_grid, [0.0, 9.0], [0.0, 9.0])
			l_painter.draw_filled_line ({REAL_64}.nan, 0.0, 5.0, 5.0, 0.0)
			l_painter.draw_filled_line (0.0, {REAL_64}.nan, 5.0, 5.0, 0.0)
			l_painter.draw_filled_line (0.0, 0.0, {REAL_64}.positive_infinity, 5.0, 0.0)
			l_painter.draw_filled_line (0.0, 0.0, 5.0, {REAL_64}.negative_infinity, 0.0)
			l_painter.draw_filled_line (0.0, 0.0, 5.0, 5.0, {REAL_64}.nan)
			assert ("non-finite filled lines draw nothing", dot_count (l_grid) = 0)

			-- +infinity fills to y max: the horizontal line on y = 0 fills the whole grid
			l_painter.draw_filled_line (0.0, 0.0, 9.0, 0.0, {REAL_64}.positive_infinity)
			assert ("+infinity fills to the top", dot_count (l_grid) = 100)
			-- -infinity fills to y min: the dots on and under the line y = 4 (dot rows 5..9)
			create l_grid.make_with_resolution (10, 10, 1, 1)
			create l_painter.make (l_grid, [0.0, 9.0], [0.0, 9.0])
			l_painter.draw_filled_line (0.0, 4.0, 9.0, 4.0, {REAL_64}.negative_infinity)
			assert ("-infinity fills to the bottom", dot_count (l_grid) = 50 and l_grid.is_pixel_set (0, 9)
				and l_grid.is_pixel_set (9, 5) and not l_grid.is_pixel_set (0, 4))

			-- Far end: clipped first, so only the visible part is walked
			create l_grid.make_with_resolution (10, 10, 1, 1)
			create l_painter.make (l_grid, [0.0, 1.0], [0.0, 1.0])
			l_start := {MONOTONIC_CLOCK}.milliseconds
			from i := 1 until i > 100 loop
				l_painter.draw_filled_line (0.0, 0.0, 1.0e9, 0.0, 1.0)
				i := i + 1
			end
			l_elapsed := {MONOTONIC_CLOCK}.milliseconds - l_start
			assert ("100 draws under 1 s", l_elapsed < 1000)
			assert ("whole grid filled", dot_count (l_grid) = 100)

			-- Same dots whichever end comes first, on a Braille grid
			l_cases := <<[0.0, 0.0, 10.0, 3.0, 5.0], [1.0, 9.0, 4.0, 0.5, 0.0], [2.0, 7.0, 9.0, 7.5, 10.0], [0.0, 2.0, 10.0, 8.0, 4.0]>>
			across l_cases as l loop
				create l_grid.make (5, 5)
				create l_painter.make (l_grid, [0.0, 10.0], [0.0, 10.0])
				l_painter.draw_filled_line (l.x1, l.y1, l.x2, l.y2, l.fill)
				create l_ref.make (5, 5)
				create l_painter.make (l_ref, [0.0, 10.0], [0.0, 10.0])
				l_painter.draw_filled_line (l.x2, l.y2, l.x1, l.y1, l.fill)
				assert ("end order, case " + (@l.target_index).out, same_dots (l_grid, l_ref) and dot_count (l_grid) > 0)
			end
		end

	test_ratatui_area_cases_dot_marker
			-- V4: Ratatui `canvas/area.rs` `tests` (all 21 cases: empty_area, off_grid1..12,
			-- rhombus_1..2, rhombus_1_not_filled, rhombus_2_not_filled, cross1..2, cross1_not_filled,
			-- cross_not_filled2). One red polygon on a 10 x 10 Dot canvas, bounds [0, 10] x [0, 10].
			-- The off_grid cases cover the Sutherland-Hodgman clipping, the cross cases the even-odd
			-- rule on a self-intersecting polygon. Rows are written with '*' for the Dot marker's '•'.
		local
			e, f: STRING
			l_buf: BUFFER
		do
			e := "          "
			f := "**********"
			assert_buffer_lines ("empty_area", area_dot_canvas (create {ARRAY [TUPLE [x, y: REAL_64]]}.make_empty, True),
				dot_rows (<<e, e, e, e, e, e, e, e, e, e>>))
			assert_buffer_lines ("off_grid1", area_dot_canvas (<<[-1.0, 0.0], [-1.0, 10.0], [-1.0, -1.0]>>, True),
				dot_rows (<<e, e, e, e, e, e, e, e, e, e>>))
			assert_buffer_lines ("off_grid2", area_dot_canvas (<<[0.0, -1.0], [10.0, -1.0], [0.0, -10.0]>>, True),
				dot_rows (<<e, e, e, e, e, e, e, e, e, e>>))
			assert_buffer_lines ("off_grid3", area_dot_canvas (<<[-10.0, 5.0], [-1.0, 5.0], [-1.0, 0.0]>>, True),
				dot_rows (<<e, e, e, e, e, e, e, e, e, e>>))
			assert_buffer_lines ("off_grid4", area_dot_canvas (<<[5.0, 11.0], [5.0, 20.0], [11.0, 11.0]>>, True),
				dot_rows (<<e, e, e, e, e, e, e, e, e, e>>))
			assert_buffer_lines ("off_grid5", area_dot_canvas (<<[-10.0, 0.0], [5.0, 0.0], [-10.0, 0.0]>>, True),
				dot_rows (<<e, e, e, e, e, e, e, e, e, "******    ">>))
			assert_buffer_lines ("off_grid6", area_dot_canvas (<<[0.0, 0.0], [10.0, 10.0], [10.0, 0.0]>>, True),
				dot_rows (lower_triangle_rows))
			assert_buffer_lines ("off_grid7", area_dot_canvas (<<[0.0, 0.0], [11.0, 11.0], [10.0, 0.0]>>, True),
				dot_rows (lower_triangle_rows))
			assert_buffer_lines ("off_grid8", area_dot_canvas (<<[-1.0, -1.0], [11.0, 11.0], [10.0, -1.0]>>, True),
				dot_rows (lower_triangle_rows))
			assert_buffer_lines ("off_grid9", area_dot_canvas (<<[5.0, 0.0], [5.0, 5.0], [15.0, 0.0]>>, True), dot_rows (<<
				e, e, e, e, e,
				"     **   ", "     **** ", "     *****", "     *****", "     *****">>))
			assert_buffer_lines ("off_grid10", area_dot_canvas (<<[-5.0, 0.0], [-5.0, 5.0], [5.0, 0.0]>>, True), dot_rows (<<
				e, e, e, e, e, e, e,
				"**        ", "****      ", "******    ">>))
			assert_buffer_lines ("off_grid11", area_dot_canvas (<<[5.0, 0.0], [5.0, 5.0], [10.0, 5.0], [10.0, 0.0]>>, True), dot_rows (<<
				e, e, e, e, e,
				"     *****", "     *****", "     *****", "     *****", "     *****">>))
			assert_buffer_lines ("off_grid12", area_dot_canvas (<<[7.0, 5.0], [11.0, 10.0], [11.0, 0.0]>>, True), dot_rows (<<
				e, "         *", "        **", "       ***", "      ****",
				"      ****", "       ***", "        **", "         *", e>>))
			assert_buffer_lines ("rhombus_1", area_dot_canvas (<<[0.0, 0.0], [0.0, 7.0], [10.0, 10.0], [10.0, 3.0]>>, True), dot_rows (<<
				"        **", "     *****", "  ********", f, f,
				f, f, "********  ", "*****     ", "**        ">>))
			assert_buffer_lines ("rhombus_2", area_dot_canvas (<<[5.0, 0.0], [4.0, 0.0], [0.0, 4.0], [0.0, 5.0],
				[4.0, 10.0], [5.0, 10.0], [10.0, 6.0], [10.0, 5.0]>>, True), dot_rows (rhombus_2_rows))
			assert_buffer_lines ("rhombus_1_not_filled", area_dot_canvas (<<[0.0, 0.0], [0.0, 7.0], [10.0, 10.0], [10.0, 3.0]>>, False), dot_rows (<<
				"        **", "     *** *", "  ***    *", "**       *", "*        *",
				"*        *", "*       **", "*    ***  ", "* ***     ", "**        ">>))
			assert_buffer_lines ("rhombus_2_not_filled", area_dot_canvas (<<[5.0, 0.0], [4.0, 0.0], [0.0, 5.0], [0.0, 6.0],
				[4.0, 10.0], [5.0, 10.0], [10.0, 6.0], [10.0, 5.0]>>, False), dot_rows (<<
				"    **    ", "   *  *   ", "  *    *  ", " *      * ", "*        *",
				"*        *", " *      * ", "  *    *  ", "   *  *   ", "    **    ">>))
			assert_buffer_lines ("cross1", area_dot_canvas (<<[0.0, 0.0], [0.0, 5.0], [10.0, 5.0], [10.0, 10.0]>>, True), dot_rows (<<
				"         *", "        **", "       ***", "      ****", "     *****",
				f, "****      ", "***       ", "**        ", "*         ">>))
			assert_buffer_lines ("cross2", area_dot_canvas (<<[0.0, 0.0], [0.0, 7.0], [10.0, 3.0], [10.0, 10.0]>>, True), dot_rows (<<
				"         *", "        **", "       ***", "**    ****", f,
				f, "****    **", "***       ", "**        ", "*         ">>))
			assert_buffer_lines ("cross1_not_filled", area_dot_canvas (<<[0.0, 0.0], [0.0, 5.0], [10.0, 5.0], [10.0, 10.0]>>, False), dot_rows (<<
				"         *", "        **", "       * *", "      *  *", "     *   *",
				f, "*  *      ", "* *       ", "**        ", "*         ">>))
			assert_buffer_lines ("cross_not_filled2", area_dot_canvas (<<[0.0, 0.0], [0.0, 7.0], [10.0, 3.0], [10.0, 10.0]>>, False), dot_rows (<<
				"         *", "        **", "       * *", "**    *  *", "* ****   *",
				"*   **** *", "*  *    **", "* *       ", "**        ", "*         ">>))

			-- Ratatui also checks the colour: painted cells are red, the others keep the default
			l_buf := area_dot_canvas (<<[0.0, 0.0], [0.0, 5.0], [10.0, 5.0], [10.0, 10.0]>>, True)
			assert ("filled cell is red", l_buf.cell (2, 8).style.foreground.is_equal ({COLOR}.red))
			assert ("outline cell is red", l_buf.cell (9, 0).style.foreground.is_equal ({COLOR}.red))
			assert ("empty cell keeps the default fg", l_buf.cell (2, 2).style.foreground.is_default)
		end

	test_clipped_polygon
			-- V4: `clipped_polygon` is Sutherland-Hodgman as line_clipping's `clip_polygon`: the left,
			-- right, bottom and top bound in turn, each pass starting with the closing edge. A polygon
			-- inside keeps its vertices and their order; one outside gives an empty list.
			-- The documented bridge artifact: a concave polygon that the bounds split in two comes
			-- back as one polygon, and its outline joins the two parts along the border.
		local
			l_grid: BRAILLE_CANVAS
			l_painter: CANVAS_PAINTER
			l_clip: ARRAYED_LIST [TUPLE [x, y: REAL_64]]
			l_u: ARRAY [TUPLE [x, y: REAL_64]]
		do
			-- line_clipping's own example: the square [-1, 1]^2 against the window [0, 3]^2
			create l_grid.make_with_resolution (4, 4, 1, 1)
			create l_painter.make (l_grid, [0.0, 3.0], [0.0, 3.0])
			l_clip := l_painter.clipped_polygon (<<[-1.0, -1.0], [-1.0, 1.0], [1.0, 1.0], [1.0, -1.0]>>)
			assert ("example clipped", same_vertices (l_clip, <<[0.0, 0.0], [0.0, 1.0], [1.0, 1.0], [1.0, 0.0]>>))
			-- Inside: unchanged, same start vertex
			l_clip := l_painter.clipped_polygon (<<[2.0, 1.0], [0.5, 0.5], [3.0, 3.0]>>)
			assert ("inside unchanged", same_vertices (l_clip, <<[2.0, 1.0], [0.5, 0.5], [3.0, 3.0]>>))
			-- Outside and empty
			assert ("outside is empty", l_painter.clipped_polygon (<<[4.0, 0.0], [5.0, 1.0], [4.0, 2.0]>>).is_empty)
			assert ("empty is empty", l_painter.clipped_polygon (create {ARRAY [TUPLE [x, y: REAL_64]]}.make_empty).is_empty)

			-- Bridge artifact: an upside-down U whose top bar is above the bounds [0, 10]^2. Its two
			-- legs (x 1..3 and 7..9) are visible; the clipped outline also runs along y = 10 between them.
			l_u := <<[1.0, 0.0], [1.0, 15.0], [9.0, 15.0], [9.0, 0.0], [7.0, 0.0], [7.0, 12.0], [3.0, 12.0], [3.0, 0.0]>>
			create l_grid.make_with_resolution (11, 11, 1, 1)
			create l_painter.make (l_grid, [0.0, 10.0], [0.0, 10.0])
			l_painter.draw_polygon (l_u, False)
			assert ("bridge drawn on the border", l_grid.is_pixel_set (5, 0) and l_grid.is_pixel_set (4, 0) and l_grid.is_pixel_set (6, 0))
			assert ("nothing between the legs below", not l_grid.is_pixel_set (5, 1) and not l_grid.is_pixel_set (5, 10))
			assert ("legs drawn", l_grid.is_pixel_set (1, 5) and l_grid.is_pixel_set (3, 5) and l_grid.is_pixel_set (7, 5) and l_grid.is_pixel_set (9, 5))
			-- Filled, the even-odd rule leaves the gap between the legs empty, but the outline keeps the bridge
			create l_grid.make_with_resolution (11, 11, 1, 1)
			create l_painter.make (l_grid, [0.0, 10.0], [0.0, 10.0])
			l_painter.draw_polygon (l_u, True)
			assert ("filled legs", l_grid.is_pixel_set (2, 5) and l_grid.is_pixel_set (8, 5))
			assert ("gap stays empty", not l_grid.is_pixel_set (5, 5) and not l_grid.is_pixel_set (4, 9))
			assert ("filled bridge", l_grid.is_pixel_set (5, 0))
		end

	test_polygon_non_finite_and_degenerate
			-- V4: a polygon with a NaN or infinite vertex draws nothing (as `draw_line`). One vertex draws
			-- one dot, two vertices a line. A vertex far outside is clipped before the walk and the
			-- fill: 100 draws to x = 1e9 on [0, 1] take under 1 s. The dots, outline or filled, do not
			-- depend on the start vertex (each edge keeps its direction: Ratatui's crossing formula
			-- rounds toward the edge's first end, so reversing the list may move a fill end). Integer division
			-- truncates toward zero, as Rust's isize division in Ratatui's crossing formula.
		local
			l_grid, l_ref: BRAILLE_CANVAS
			l_painter: CANVAS_PAINTER
			l_start, l_elapsed: INTEGER_64
			l_fill: BOOLEAN
		do
			assert ("truncating division", (-7) // 2 = -3 and 7 // (-2) = -3)
			create l_grid.make_with_resolution (10, 10, 1, 1)
			create l_painter.make (l_grid, [0.0, 9.0], [0.0, 9.0])
			l_painter.draw_polygon (<<[0.0, 0.0], [{REAL_64}.nan, 5.0], [9.0, 0.0]>>, True)
			l_painter.draw_polygon (<<[0.0, 0.0], [5.0, {REAL_64}.positive_infinity], [9.0, 0.0]>>, True)
			l_painter.draw_polygon (<<[0.0, 0.0], [{REAL_64}.negative_infinity, 5.0], [9.0, 0.0]>>, False)
			assert ("non-finite polygons draw nothing", dot_count (l_grid) = 0)

			l_painter.draw_polygon (<<[4.0, 4.0]>>, True)
			assert ("one vertex, one dot", dot_count (l_grid) = 1 and l_grid.is_pixel_set (4, 5))
			create l_grid.make_with_resolution (10, 10, 1, 1)
			create l_painter.make (l_grid, [0.0, 9.0], [0.0, 9.0])
			l_painter.draw_polygon (<<[0.0, 0.0], [9.0, 9.0]>>, True)
			assert ("two vertices, a line", dot_count (l_grid) = 10 and l_grid.is_pixel_set (0, 9) and l_grid.is_pixel_set (9, 0))

			-- Far vertex: clipped first, so only the visible part is walked and filled
			create l_grid.make_with_resolution (10, 10, 1, 1)
			create l_painter.make (l_grid, [0.0, 1.0], [0.0, 1.0])
			l_start := {MONOTONIC_CLOCK}.milliseconds
			across 1 |..| 100 as i loop
				l_painter.draw_polygon (<<[0.0, 0.0], [1.0e9, 0.0], [1.0e9, 1.0], [0.0, 1.0]>>, True)
			end
			l_elapsed := {MONOTONIC_CLOCK}.milliseconds - l_start
			assert ("100 draws under 1 s", l_elapsed < 1000)
			assert ("whole grid filled", dot_count (l_grid) = 100)

			-- Start vertex, on a Braille grid, for a concave and a self-intersecting polygon
			across <<False, True>> as b loop
				l_fill := b
				create l_grid.make (5, 5)
				create l_painter.make (l_grid, [0.0, 10.0], [0.0, 10.0])
				l_painter.draw_polygon (<<[1.0, 1.0], [9.0, 2.0], [5.0, 5.0], [8.0, 9.0], [0.5, 8.0]>>, l_fill)
				l_painter.draw_polygon (<<[0.0, 0.0], [0.0, 7.0], [10.0, 3.0], [10.0, 10.0]>>, l_fill)
				create l_ref.make (5, 5)
				create l_painter.make (l_ref, [0.0, 10.0], [0.0, 10.0])
				l_painter.draw_polygon (<<[5.0, 5.0], [8.0, 9.0], [0.5, 8.0], [1.0, 1.0], [9.0, 2.0]>>, l_fill)
				l_painter.draw_polygon (<<[10.0, 3.0], [10.0, 10.0], [0.0, 0.0], [0.0, 7.0]>>, l_fill)
				assert ("same dots, fill " + l_fill.out, same_dots (l_grid, l_ref) and dot_count (l_grid) > 0)
			end
		end

	test_shape_area
			-- V4: SHAPE_AREA paints as `draw_polygon` (Ratatui rhombus_2 through a shape). It keeps its
			-- own copy of the vertices, `twin` copies the list, and `is_equal` compares the vertices,
			-- the fill flag and the style.
		local
			l_canvas: TUI_CANVAS
			l_buf: BUFFER
			l_red: STYLE
			l_shape, l_copy: SHAPE_AREA
			l_vertices: ARRAY [TUPLE [x, y: REAL_64]]
		do
			create l_red.make_fg ({COLOR}.red)
			l_vertices := <<[5.0, 0.0], [4.0, 0.0], [0.0, 4.0], [0.0, 5.0], [4.0, 10.0], [5.0, 10.0], [10.0, 6.0], [10.0, 5.0]>>
			create l_shape.make (l_vertices, l_red, True)
			assert ("fill set", l_shape.is_filled)
			assert ("vertices copied", l_shape.vertices.count = 8 and l_shape.vertices [3].x = 0.0 and l_shape.vertices [3].y = 4.0)
			l_vertices [3] := [9.0, 9.0]
			l_vertices [1].x := 3.0
			assert ("own vertices", l_shape.vertices [3].x = 0.0 and l_shape.vertices [1].x = 5.0)
			create l_canvas.make
			l_canvas := l_canvas.with_marker ({CANVAS_MARKER}.dot).with_bounds (0.0, 10.0, 0.0, 10.0).with_shape (l_shape)
			create l_buf.make (10, 10)
			l_canvas.render (l_buf.area, l_buf)
			assert_buffer_lines ("rhombus_2 as a shape", l_buf, dot_rows (rhombus_2_rows))
			assert ("shape cell is red", l_buf.cell (4, 0).style.foreground.is_equal ({COLOR}.red))

			l_copy := l_shape.twin
			assert ("twin equal", l_copy.is_equal (l_shape))
			assert ("twin has its own list", l_copy.vertices /= l_shape.vertices)
			l_copy.vertices.extend ([1.0, 1.0])
			assert ("original unchanged", l_shape.vertices.count = 8 and not l_copy.is_equal (l_shape))
			assert ("equal shape", l_shape.is_equal (create {SHAPE_AREA}.make (<<[5.0, 0.0], [4.0, 0.0], [0.0, 4.0], [0.0, 5.0],
				[4.0, 10.0], [5.0, 10.0], [10.0, 6.0], [10.0, 5.0]>>, create {STYLE}.make_fg ({COLOR}.red), True)))
			assert ("fill counts", not l_shape.is_equal (create {SHAPE_AREA}.make (l_shape.vertices, l_red, False)))
			assert ("style counts", not l_shape.is_equal (create {SHAPE_AREA}.make (l_shape.vertices, create {STYLE}.make_fg ({COLOR}.blue), True)))
			assert ("vertex counts", not l_shape.is_equal (create {SHAPE_AREA}.make (<<[5.0, 0.0], [4.0, 0.0], [0.0, 4.0], [0.0, 5.0],
				[4.0, 10.0], [5.0, 10.0], [10.0, 6.0], [10.0, 4.0]>>, l_red, True)))

			-- Outline only, through a shape
			create l_canvas.make
			l_canvas := l_canvas.with_marker ({CANVAS_MARKER}.dot).with_bounds (0.0, 10.0, 0.0, 10.0)
				.with_shape (create {SHAPE_AREA}.make (<<[0.0, 0.0], [0.0, 5.0], [10.0, 5.0], [10.0, 10.0]>>, l_red, False))
			create l_buf.make (10, 10)
			l_canvas.render (l_buf.area, l_buf)
			assert_buffer_lines ("cross1_not_filled as a shape", l_buf, dot_rows (<<
				"         *", "        **", "       * *", "      *  *", "     *   *",
				"**********", "*  *      ", "* *       ", "**        ", "*         ">>))
		end

	test_world_map_data_counts_and_ranges
			-- V5: WORLD_MAP_DATA has Ratatui's point counts (`WORLD_LOW_RESOLUTION` 1 166,
			-- `WORLD_HIGH_RESOLUTION` 5 125), longitude and latitude interleaved. Every latitude is in
			-- [-90, 90]. High resolution longitudes are in [-180, 180]; six low resolution points lie
			-- east of 180 (up to 188.87), as in world.rs. First and last points as in world.rs.
		local
			l_low, l_high: SPECIAL [REAL_64]
			i, l_east: INTEGER
			l_ok: BOOLEAN
		do
			l_low := {WORLD_MAP_DATA}.low_resolution
			l_high := {WORLD_MAP_DATA}.high_resolution
			assert ("low count", {WORLD_MAP_DATA}.Low_resolution_count = 1166 and l_low.count = 2 * 1166)
			assert ("high count", {WORLD_MAP_DATA}.High_resolution_count = 5125 and l_high.count = 2 * 5125)
			assert ("point_count", {MAP_RESOLUTION}.point_count ({MAP_RESOLUTION}.low) = 1166
				and {MAP_RESOLUTION}.point_count ({MAP_RESOLUTION}.high) = 5125)
			assert ("points", {MAP_RESOLUTION}.points ({MAP_RESOLUTION}.low) = l_low
				and {MAP_RESOLUTION}.points ({MAP_RESOLUTION}.high) = l_high)
			assert ("once", {WORLD_MAP_DATA}.high_resolution = l_high)

			l_ok := True
			from i := 0 until i >= l_high.count loop
				l_ok := l_ok and l_high [i] >= -180.0 and l_high [i] <= 180.0 and l_high [i + 1] >= -90.0 and l_high [i + 1] <= 90.0
				i := i + 2
			end
			assert ("high in range", l_ok)
			from i := 0 until i >= l_low.count loop
				l_ok := l_ok and l_low [i] >= -180.0 and l_low [i] <= 188.87 and l_low [i + 1] >= -90.0 and l_low [i + 1] <= 90.0
				if l_low [i] > 180.0 then
					l_east := l_east + 1
				end
				i := i + 2
			end
			assert ("low in range", l_ok)
			assert ("six low points east of 180", l_east = 6)

			assert ("low first", l_low [0] = -92.32 and l_low [1] = 48.24)
			assert ("low east-most", l_low [2 * 647] = 188.87 and l_low [2 * 647 + 1] = 66.38)
			assert ("low last", l_low [2 * 1165] = 66.82 and l_low [2 * 1165 + 1] = 66.82)
			assert ("high first", l_high [0] = -163.7128 and l_high [1] = -78.5956)
			assert ("high Ireland", l_high [2 * 11] = -6.1978 and l_high [2 * 11 + 1] = 53.8675)
		end

	test_map_resolution_names_and_default
			-- V5: Ratatui `map.rs` `map_resolution_to_string`, `map_resolution_from_str` and `default`
			-- (`Map::default` is low resolution with `Color::Reset`).
		local
			l_map: SHAPE_MAP
		do
			assert ("Low", {MAP_RESOLUTION}.name ({MAP_RESOLUTION}.low).same_string ("Low"))
			assert ("High", {MAP_RESOLUTION}.name ({MAP_RESOLUTION}.high).same_string ("High"))
			assert ("parse Low", {MAP_RESOLUTION}.from_name ("Low") = {MAP_RESOLUTION}.low)
			assert ("parse High", {MAP_RESOLUTION}.from_name ({STRING_32} "High") = {MAP_RESOLUTION}.high)
			assert ("empty is not a name", not {MAP_RESOLUTION}.is_valid_name (""))
			assert ("case-sensitive", not {MAP_RESOLUTION}.is_valid_name ("low"))
			assert ("valid", {MAP_RESOLUTION}.is_valid ({MAP_RESOLUTION}.low) and {MAP_RESOLUTION}.is_valid ({MAP_RESOLUTION}.high))
			assert ("invalid", not {MAP_RESOLUTION}.is_valid (0) and not {MAP_RESOLUTION}.is_valid (3))

			create l_map
			assert ("default low", l_map.resolution = {MAP_RESOLUTION}.low)
			assert ("default style", l_map.style.is_equal (create {STYLE}.default_create)
				and l_map.style.foreground.is_default)
		end

	test_ratatui_map_draw_low
			-- V5: Ratatui `map.rs` `draw_low`: `Map::default` on an 80 x 40 Dot canvas, bounds
			-- [-180, 180] x [-90, 90]. Row-exact; rows written with '*' for the Dot marker's '•'.
		do
			assert_buffer_lines ("draw_low", map_canvas ({CANVAS_MARKER}.dot, create {SHAPE_MAP}), dot_rows (ratatui_map_low_rows))
		end

	test_ratatui_map_draw_high
			-- V5: Ratatui `map.rs` `draw_high`: a high resolution map on an 80 x 40 Braille canvas,
			-- bounds [-180, 180] x [-90, 90]. Row-exact; each cell is written as the two hex digits of
			-- its Braille pattern (see `braille_hex_rows`).
		do
			assert_buffer_lines ("draw_high", map_canvas ({CANVAS_MARKER}.braille,
				create {SHAPE_MAP}.make ({MAP_RESOLUTION}.high, create {STYLE}.default_create)),
				braille_hex_rows (ratatui_map_high_rows))
		end

	test_shape_map
			-- V5: SHAPE_MAP paints in its style, only inside the bounds (a region of the world), and
			-- `is_equal` / `twin` compare the resolution and the style.
		local
			l_red: STYLE
			l_map, l_copy: SHAPE_MAP
			l_canvas: TUI_CANVAS
			l_buf: BUFFER
			l_grid: BRAILLE_CANVAS
			l_painter: CANVAS_PAINTER
			r, c, l_painted: INTEGER
			l_all_red: BOOLEAN
		do
			create l_red.make_fg ({COLOR}.red)
			create l_map.make ({MAP_RESOLUTION}.high, l_red)
			assert ("resolution set", l_map.resolution = {MAP_RESOLUTION}.high and l_map.style = l_red)

			-- Whole world: every painted cell is red, empty cells keep the default
			l_buf := map_canvas ({CANVAS_MARKER}.braille, l_map)
			l_all_red := True
			from r := 0 until r >= 40 loop
				from c := 0 until c >= 80 loop
					if not l_buf.cell (r, c).symbol.same_string (" ") then
						l_painted := l_painted + 1
						l_all_red := l_all_red and l_buf.cell (r, c).style.foreground.is_equal ({COLOR}.red)
					end
					c := c + 1
				end
				r := r + 1
			end
			assert ("painted", l_painted > 500)
			assert ("all red", l_all_red)

			-- A region: Western Europe [-10, 30] x [35, 60] has coast; the South Pacific
			-- [-150, -100] x [-50, -20] has none (all its points are skipped)
			create l_grid.make (20, 10)
			create l_painter.make (l_grid, [-10.0, 30.0], [35.0, 60.0])
			l_map.paint (l_painter)
			assert ("Europe drawn", dot_count (l_grid) > 50)
			create l_grid.make (20, 10)
			create l_painter.make (l_grid, [-150.0, -100.0], [-50.0, -20.0])
			l_map.paint (l_painter)
			assert ("South Pacific empty", dot_count (l_grid) = 0)

			-- The six low resolution points east of 180 are skipped with bounds [-180, 180], drawn
			-- with bounds [180, 190]
			create l_grid.make (10, 10)
			create l_painter.make (l_grid, [180.0, 190.0], [60.0, 70.0])
			(create {SHAPE_MAP}).paint (l_painter)
			assert ("east of 180", dot_count (l_grid) = 6)

			-- Through TUI_CANVAS as a shape
			create l_canvas.make
			l_canvas := l_canvas.with_marker ({CANVAS_MARKER}.dot).with_bounds (-180.0, 180.0, -90.0, 90.0).with_shape (create {SHAPE_MAP})
			create l_buf.make (80, 40)
			l_canvas.render (l_buf.area, l_buf)
			assert_buffer_lines ("draw_low as a shape", l_buf, dot_rows (ratatui_map_low_rows))

			l_copy := l_map.twin
			assert ("twin equal", l_copy.is_equal (l_map))
			assert ("equal map", l_map.is_equal (create {SHAPE_MAP}.make ({MAP_RESOLUTION}.high, create {STYLE}.make_fg ({COLOR}.red))))
			assert ("resolution counts", not l_map.is_equal (create {SHAPE_MAP}.make ({MAP_RESOLUTION}.low, l_red)))
			assert ("style counts", not l_map.is_equal (create {SHAPE_MAP}.make ({MAP_RESOLUTION}.high, create {STYLE}.make_fg ({COLOR}.blue))))
			assert ("invalid resolution refused", precondition_raised (agent (s: STYLE) local m: SHAPE_MAP do create m.make (3, s) end (l_red), "valid_resolution"))
		end

feature {NONE} -- Helper Agent

	paint_test_pattern (p: CANVAS_PAINTER)
			-- Painter agent for test_tui_canvas_rendering_with_agent.
		do
			p.draw_line (0.0, 0.0, 100.0, 100.0)
		end

feature {NONE} -- Helpers

	map_canvas (a_marker: NATURAL_8; a_map: SHAPE_MAP): BUFFER
			-- 80 x 40 buffer with a canvas of `a_marker`, bounds [-180, 180] x [-90, 90], showing
			-- `a_map` (the setup of Ratatui `canvas/map.rs` `draw_low` and `draw_high`).
		local
			l_canvas: TUI_CANVAS
		do
			create l_canvas.make
			l_canvas.set_marker (a_marker)
			l_canvas.set_bounds (-180.0, 180.0, -90.0, 90.0)
			l_canvas.set_painter (agent (p: CANVAS_PAINTER; m: SHAPE_MAP) do m.paint (p) end (?, a_map))
			create Result.make (80, 40)
			l_canvas.render (Result.area, Result)
		end

	braille_hex_rows (a_rows: ARRAY [STRING]): ARRAY [READABLE_STRING_GENERAL]
			-- `a_rows` decoded: every two hex digits are one cell, the Braille character U+2800 plus
			-- that pattern, and "00" is a space (an undrawn cell).
		require
			even_rows: across a_rows as r all r.count \\ 2 = 0 end
		local
			l_row: STRING_32
			i, l_pattern: INTEGER
		do
			create Result.make_filled ({STRING_32} "", a_rows.lower, a_rows.upper)
			across a_rows as r loop
				create l_row.make (r.count // 2)
				from i := 1 until i > r.count loop
					l_pattern := 16 * hex_digit (r [i]) + hex_digit (r [i + 1])
					if l_pattern = 0 then
						l_row.append_character (' ')
					else
						l_row.append_code ((0x2800 + l_pattern).to_natural_32)
					end
					i := i + 2
				end
				Result [@r.target_index] := l_row
			end
		end

	hex_digit (a_char: CHARACTER_8): INTEGER
			-- Value of the hex digit `a_char` (0-9, A-F).
		require
			hex: a_char.is_digit or ('A' <= a_char and a_char <= 'F')
		do
			if a_char.is_digit then
				Result := a_char.code - ('0').code
			else
				Result := a_char.code - ('A').code + 10
			end
		ensure
			range: 0 <= Result and Result < 16
		end

	ratatui_map_low_rows: ARRAY [STRING]
			-- Expected rows of Ratatui `canvas/map.rs` `draw_low` ('*' for a dot), as printed by
			-- `python tools/generate_world_map_data.py --test-rows`.
		do
			Result := <<
				"                                                                                ",
				"                               *                                                ",
				"               * ** ******** **   ****    *****  *** **     ***                 ",
				"             ***************       *      ****      * *   *******     ***       ",
				"    * **** *************** **     **  *     ***    **  ****    **  ******* ***  ",
				"*****     ************ **** *  ******     **** * *** *****                     *",
				"   **  * *   **** ********  ****   **  * ** *  ***                        ** ***",
				"    **** ***   ****** *****   *       ** ******                       * *****   ",
				"*****     ***     *  **   **         *******                          **  ** ** ",
				"            **    ****  *****          **       *  * *                **        ",
				"            *  *    *******           ** **** *** ** *  **          * **        ",
				"            *          **             ********* * **             **** *         ",
				"             **       **              * * * ** *                  *****         ",
				"              **   ***               *      ****  *               * *           ",
				"               *  *   **             *         **  ** *           *             ",
				"    **          * *******           *           *   *  *   *   ** *             ",
				"                 *********          *           ** *   *  * ** *  **            ",
				"                    **  **          *            ***     *   ***  **            ",
				"                     ***  * *        *  *         *     **  ***  ***            ",
				"                      *               *  **                   * **              ",
				"                   *  *     ***                * *            ***   ***         ",
				"                                *         *     *              * *    ***       ",
				"  *                                        *    * *                  * * *      ",
				"                       *       *                * *               *** **       *",
				"                        *      *          *    * **              *      *   *   ",
				"                        *    *                   *               *       *      ",
				"                        *   *              *   *                    *           ",
				"                           **               **                   **  **  *   *  ",
				"                       *  *                                           ***    ** ",
				"                       *  *                                            **   **  ",
				"                       * *                                                      ",
				"                       *****                                                    ",
				"                                                                                ",
				"                          **                                                    ",
				"                         ***           *       * ***** * **** * * ** ** **      ",
				"            *    * * ******        ********* * **      **                  ***  ",
				"*    *** **** ****   * *  * *** * *                                        *** *",
				"   ** *                *  **  * **                                         **   ",
				"*      *                                                                      * ",
				"                                                                                "
			>>
		end

	ratatui_map_high_rows: ARRAY [STRING]
			-- Expected rows of Ratatui `canvas/map.rs` `draw_high` (Braille patterns in hex, see
			-- `braille_hex_rows`), as printed by `python tools/generate_world_map_data.py --test-rows`.
		do
			Result := <<
				"0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
				"0000000000000000000000000000000000000080C0E4042424E4C040C0C0440484C0C4448040000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
				"0000000000000000000000000080C0E430A4FC6FBD5FC0B6FA5B010000000000000008B003010000000096D2FE5F020000081B0100000000000000003AA9964400000000000000000000000000000000",
				"0000000000000000000000006C8DFFDFFFFBFFFFFF7EEF40080101A6000000000000807F000000000000000800000000000000A0B6180B41C0A02416180901083C6744C44000ABD71206000000000000",
				"D30000E016131222248424363D3DF6C3FD6EFF77D7E46DCD93440038F700000080C03F0700000000000000801412320484804099D144344DDF0900000000000000000000110909000011102624E4249E",
				"36A7D7BE46000000000000000000080801080980F9F6E9FDD0AE0300C70080540A00B0D6F200000000805001F02600B2F61B0B00000000100B0000000000000000000000000000000000000000000064",
				"000009EEC0C0F464E0400000000000000000004E001BAB19ABAB000008263C000000000000000000004340B83CE44400000000000000000000000000000000000000000000000040C0C05076E3A41609",
				"000000807D1F030000083140000000000000001922C0E8060801A74000000000000000000000F8F700B9F7FCF803000000000000000000000000000000000000000000000080508000015AE806000000",
				"0000000000000000000018B3400000000000000000083E0000C0C0FD00000000000000000038BCC7670B0901000000000000000000000000000000000000000000000000000009FF0000220200000000",
				"000000000000000000000008BB00000000000000000000001CB9F53B0700000000000000000008BB000080400000A0E0640080A4000000000000000000000000000000000000B0EF0000000000000000",
				"000000000000000000000000BC0000000000000000000080FE1B090000000000000000000010561270BADEF54480CF6DD94495AB40000000000000000000000000008000A016B17F0300000000000000",
				"00000000000000000000000038000000000000000000204E0000000000000000000000000030C5F0C3D8637FBB7FC1C0000038FD0000000000000000000000000010FFFDEB0078470000000000000000",
				"0000000000000000000000000033C400000000000000700300000000000000000000000000800E090000A740E0DB08BB000000000000000000000000000000000000BB18BA7F1A010000000000000000",
				"0000000000000000000000000000BBC70000E03216B247000000000000000000000000000078000000000009030809FF0000B0C60000000000000000000000000000B800080100000000000000000000",
				"000000000000000000000000000008BFC6005F0000D8FB000000000000000000000000007800000000000000000000B88700082FBF523240000000804000000000C0BE00000000000000000000000000",
				"0000000008B3000000000000000000003840B3E0BE09B9E6E4C0000000000000000000004700000000000000000000007F440000B00300114200A00FA30000FC6E018840000000000000000000000000",
				"00000000000000000000000000000000001932867FA6080901010000000000000000000047000000000000000000000031C7C03C0300000043B0030038B600180400BE41000000000000000000000000",
				"000000000000000000000000000000000000000019FEC07476A4E4000000000000000000B30000000000000000000000003B35460000000038F8000000B8736403807EFF000000000000000000000000",
				"00000000000000000000000000000000000000000018BB0100000826C40000000000000000A7C0C024C000000000000000009001000000000829060000D8E701007854BF000000000000000000000000",
				"00000000000000000000000000000000000000000000780000000000A80000000000000000000100000947000000000000800E00000000000000000000BBBF047491E760440000000000000000000000",
				"00000000000000000000000000000000000000000000470000000000080B264400000000000000000008460000000000A0030000000000000000000000008F47A7FCFEE7FDFF36A440E4000000000000",
				"00000000000000000000000000000000000000000000C700000000000000000847000000000000000000B80000000000B8000000000000000000000000000836E6C4CBC14038F5A0FB0B37C400000000",
				"00000000000000000000000000000000000000000000304000000000000000F001000000000000000000980600000000B800A0400000000000000000000000000000190BA02644F71903001900000000",
				"040000000000000000000000000000000000000000000023400000000000004300000000000000000000B80000000000F8A1BE060000000000000000000000000000005E1B18A74F4600000038040064",
				"000000000000000000000000000000000000000000000000310000000000A003000000000000000000003840000000B801B8A80000000000000000000000000000641A000000000031400000A6000001",
				"00000000000000000000000000000000000000000000000005000000005609000000000000000000000000470000005C00381400000000000000000000000000004700000000000000B3000000000000",
				"00000000000000000000000000000000000000000000000047000000800300000000000000000000000000B14000B0030000000000000000000000000000000000C700008040000000B8000000000000",
				"000000000000000000000000000000000000000000000080030000660F0000000000000000000000000000083716030000000000000000000000000000000000003E340A0139E600005E00000000C400",
				"0000000000000000000000000000000000000000000000B80000640300000000000000000000000000000000000000000000000000000000000000000000000000000000000018B2160300000000FD46",
				"0000000000000000000000000000000000000000000000B800F8010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000083F00000080BC0F00",
				"00000000000000000000000000000000000000000000001E00570000000000000000000000000000000000000000000000000000000000C40000000000000000000000000000000000000000080B0000",
				"0000000000000000000000000000000000000000000000A77C41320200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
				"0000000000000000000000000000000000000000000000001909000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
				"0000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
				"00000000000000000000000000000000000000000000000000F40F0100000000000000000000000000000000000000000000C064A4C0C0000080C0E4C0C074C464A4C0242434C4C04000000000000000",
				"0000000000000000000000000000000000C0C000000000E0FF4DC600000000000000000000E0E4E4243436163224141B12090000000828C7160B00000000000000000000000000000809132224840000",
				"00000000004000E02434121A1B1B1222243F190909118BDAC9251A00000000000080C0601F010000000000000000000000000000000000000000000000000000000000000000000000000000740B0000",
				"0000001036DBEB640000000000000000000000000000108FC0E4E400F4CB8780EE650000000000000000000000000000000000000000000000000000000000000000000000000000000000F413000000",
				"2424242440C8A3E0440000000000000000000000000000000000090A09090900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000813062424",
				"0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
			>>
		end

	filled_dot_canvas (a_x1, a_y1, a_x2, a_y2, a_fill_to_y: REAL_64): BUFFER
			-- 10 x 10 buffer with a Dot canvas, bounds [0, 10] x [0, 10], showing one red filled line
			-- (the setup of Ratatui `canvas/line.rs` `tests_filled`).
		local
			l_canvas: TUI_CANVAS
		do
			create l_canvas.make
			l_canvas.set_marker ({CANVAS_MARKER}.dot)
			l_canvas.set_bounds (0.0, 10.0, 0.0, 10.0)
			l_canvas.set_painter (agent (p: CANVAS_PAINTER; x1, y1, x2, y2, f: REAL_64)
				do
					p.set_style (create {STYLE}.make_fg ({COLOR}.red))
					p.draw_filled_line (x1, y1, x2, y2, f)
				end (?, a_x1, a_y1, a_x2, a_y2, a_fill_to_y))
			create Result.make (10, 10)
			l_canvas.render (Result.area, Result)
		end

	area_dot_canvas (a_vertices: ARRAY [TUPLE [x, y: REAL_64]]; a_fill: BOOLEAN): BUFFER
			-- 10 x 10 buffer with a Dot canvas, bounds [0, 10] x [0, 10], showing one red polygon
			-- (the setup of Ratatui `canvas/area.rs` `tests`).
		local
			l_canvas: TUI_CANVAS
		do
			create l_canvas.make
			l_canvas.set_marker ({CANVAS_MARKER}.dot)
			l_canvas.set_bounds (0.0, 10.0, 0.0, 10.0)
			l_canvas.set_painter (agent (p: CANVAS_PAINTER; v: ARRAY [TUPLE [x, y: REAL_64]]; f: BOOLEAN)
				do
					p.set_style (create {STYLE}.make_fg ({COLOR}.red))
					p.draw_polygon (v, f)
				end (?, a_vertices, a_fill))
			create Result.make (10, 10)
			l_canvas.render (Result.area, Result)
		end

	rhombus_2_rows: ARRAY [STRING]
			-- Rows ('*' for a dot) of Ratatui `canvas/area.rs` case rhombus_2 (filled octagon).
		do
			Result := <<"    **    ", "   ****   ", "  ******  ", " ******** ", "**********",
				"**********", " ******** ", "  ******  ", "   ****   ", "    **    ">>
		end

	same_vertices (a_list: ARRAYED_LIST [TUPLE [x, y: REAL_64]]; a_expected: ARRAY [TUPLE [x, y: REAL_64]]): BOOLEAN
			-- Does `a_list` hold exactly `a_expected`, in order?
		local
			i: INTEGER
		do
			Result := a_list.count = a_expected.count
			from i := 1 until i > a_list.count or not Result loop
				Result := a_list [i].x = a_expected [a_expected.lower + i - 1].x and a_list [i].y = a_expected [a_expected.lower + i - 1].y
				i := i + 1
			end
		end

	lower_triangle_rows: ARRAY [STRING]
			-- Rows ('*' for a dot) of the 10 x 10 diagonal from the bottom-left to the top-right corner,
			-- filled down to the bottom row.
		local
			r: INTEGER
			l_row: STRING
		do
			create Result.make_filled ("", 1, 10)
			from r := 0 until r >= 10 loop
				create l_row.make_filled (' ', 10)
				l_row.keep_head (9 - r)
				l_row.append (create {STRING}.make_filled ('*', r + 1))
				Result [r + 1] := l_row
				r := r + 1
			end
		end

	framed_plot_rows (a_plot: ARRAY [STRING]): ARRAY [READABLE_STRING_GENERAL]
			-- Rows of a 12 x 12 TUI_CHART buffer whose 11 x 11 plot shows `a_plot` ('*' for a dot):
			-- the y axis '│' in column 0 beside each plot row, then the x axis '└' and 11 '─'.
		require
			eleven_rows: a_plot.count = 11
		local
			l_dots: ARRAY [READABLE_STRING_GENERAL]
			l_row: STRING_32
			i: INTEGER
		do
			l_dots := dot_rows (a_plot)
			create Result.make_filled ({STRING_32} "", 1, 12)
			from i := 1 until i > 11 loop
				create l_row.make_from_string_general ({STRING_32} "%/0x2502/")
				l_row.append_string_general (l_dots [l_dots.lower + i - 1])
				Result [i] := l_row
				i := i + 1
			end
			create l_row.make_from_string_general ({STRING_32} "%/0x2514/")
			l_row.append (create {STRING_32}.make_filled ('%/0x2500/', 11))
			Result [12] := l_row
		end

	area_chart (a_dataset: TUI_CHART_DATASET): BUFFER
			-- 12 x 12 buffer with a chart of `a_dataset` alone, bounds [0, 10] x [0, 10] (an 11 x 11 plot).
		local
			l_chart: TUI_CHART
		do
			create l_chart.make_with_datasets (<<a_dataset>>)
			l_chart.set_x_bounds (0.0, 10.0)
			l_chart.set_y_bounds (0.0, 10.0)
			create Result.make (12, 12)
			l_chart.render (Result.area, Result)
		end

	same_dots (a_grid, a_other: BRAILLE_CANVAS): BOOLEAN
			-- Do `a_grid` and `a_other` (the same size) have the same dots set?
		require
			same_size: a_grid.subpixel_width = a_other.subpixel_width and a_grid.subpixel_height = a_other.subpixel_height
		local
			x, y: INTEGER
		do
			Result := True
			from y := 0 until y >= a_grid.subpixel_height or not Result loop
				from x := 0 until x >= a_grid.subpixel_width or not Result loop
					Result := a_grid.is_pixel_set (x, y) = a_other.is_pixel_set (x, y)
					x := x + 1
				end
				y := y + 1
			end
		end

	lines_canvas (a_marker: NATURAL_8; a_lines: ARRAY [TUPLE [x1, y1, x2, y2: REAL_64]]): BUFFER
			-- 5 x 5 buffer with a canvas of `a_marker`, bounds [0, 10] x [0, 10], showing `a_lines`
			-- (drawn in order).
		local
			l_canvas: TUI_CANVAS
		do
			create l_canvas.make
			l_canvas.set_marker (a_marker)
			l_canvas.set_bounds (0.0, 10.0, 0.0, 10.0)
			l_canvas.set_painter (agent (p: CANVAS_PAINTER; a: ARRAY [TUPLE [x1, y1, x2, y2: REAL_64]])
				do
					across a as l loop
						p.draw_line (l.x1, l.y1, l.x2, l.y2)
					end
				end (?, a_lines))
			create Result.make (5, 5)
			l_canvas.render (Result.area, Result)
		end

	rectangle_canvas (a_marker: NATURAL_8): BUFFER
			-- 10 x 10 buffer with a canvas of `a_marker`, bounds [0, 10] x [0, 10], showing a red
			-- rectangle over the whole bounds (the setup of Ratatui `canvas/rectangle.rs` `tests`).
		require
			valid_marker: {CANVAS_MARKER}.is_valid (a_marker)
		do
			Result := rectangle_canvas_with ((create {TUI_CANVAS}.make).with_marker (a_marker))
		end

	rectangle_canvas_with (a_canvas: TUI_CANVAS): BUFFER
			-- As `rectangle_canvas`, with `a_canvas` (its marker) as the canvas.
		do
			a_canvas.set_bounds (0.0, 10.0, 0.0, 10.0)
			a_canvas.add_shape (create {SHAPE_RECT}.make (0.0, 0.0, 10.0, 10.0, create {STYLE}.make_fg ({COLOR}.red)))
			create Result.make (10, 10)
			a_canvas.render (Result.area, Result)
		end

	ring_rows (a_top, a_side, a_bottom: READABLE_STRING_GENERAL): ARRAY [READABLE_STRING_GENERAL]
			-- Ten rows: `a_top`, eight times `a_side`, then `a_bottom` (a rectangle on a 10 x 10 canvas).
		do
			create Result.make_filled (a_side, 1, 10)
			Result [1] := a_top
			Result [10] := a_bottom
		ensure
			ten_rows: Result.count = 10
		end

	assert_buffer_colors (a_tag: STRING; a_buf: BUFFER; a_col, a_row: INTEGER;
			a_legend: ARRAY [TUPLE [key: CHARACTER_8; fg, bg: COLOR]]; a_rows: ARRAY [READABLE_STRING_GENERAL])
			-- Row-exact colour snapshot: the cell at (`a_row` + i - 1, `a_col` + j - 1) has the fg and
			-- bg of the `a_legend` entry whose key is character j of row i of `a_rows` ('.': default
			-- fg and bg). Colours are compared by `same_rendering` (default and reset alike, as Ratatui
			-- has only `Color::Reset`). The message names the first cell that differs.
		require
			inside: a_col >= 0 and a_row >= 0 and a_row + a_rows.count <= a_buf.height
				and across a_rows as r all a_col + r.count <= a_buf.width end
		local
			l_fg, l_bg: COLOR
			l_key: CHARACTER_32
			l_style: STYLE
			l_found: BOOLEAN
		do
			across a_rows as r loop
				across 1 |..| r.count as j loop
					l_key := r.code (j).to_character_32
					create l_fg
					create l_bg
					l_found := l_key = '.'
					across a_legend as e loop
						if e.key.to_character_32 = l_key then
							l_fg := e.fg
							l_bg := e.bg
							l_found := True
						end
					end
					assert (a_tag + ": key '" + key_text (l_key) + "' is in the legend", l_found)
					l_style := a_buf.cell (a_row + @r.cursor_index - 1, a_col + j - 1).style
					assert (a_tag + " [row " + (@r.cursor_index - 1).out + ", col " + (j - 1).out + "]: expected '" + key_text (l_key)
						+ "' (fg " + l_fg.out + ", bg " + l_bg.out + ") but got fg " + l_style.foreground.out + ", bg " + l_style.background.out,
						l_style.foreground.same_rendering (l_fg) and l_style.background.same_rendering (l_bg))
				end
			end
		end

	key_text (a_key: CHARACTER_32): STRING
			-- `a_key` for a failure message (the character itself when it is ASCII).
		do
			if a_key.natural_32_code < 128 then
				Result := a_key.to_character_8.out
			else
				Result := a_key.out
			end
		end

	dot_line_canvas (a_x1, a_y1, a_x2, a_y2: REAL_64): BUFFER
			-- 10 x 10 buffer with a Dot canvas, bounds [0, 10] x [0, 10], showing one line
			-- (the setup of Ratatui `canvas/line.rs` `tests`).
		do
			Result := sized_lines_canvas ({CANVAS_MARKER}.dot, 10, 10, <<[a_x1, a_y1, a_x2, a_y2]>>)
		end

	sized_lines_canvas (a_marker: NATURAL_8; a_cols, a_rows: INTEGER; a_lines: ARRAY [TUPLE [x1, y1, x2, y2: REAL_64]]): BUFFER
			-- `a_cols` x `a_rows` buffer with a canvas of `a_marker`, bounds [0, 10] x [0, 10],
			-- showing `a_lines` (drawn in order).
		local
			l_canvas: TUI_CANVAS
		do
			create l_canvas.make
			l_canvas.set_marker (a_marker)
			l_canvas.set_bounds (0.0, 10.0, 0.0, 10.0)
			l_canvas.set_painter (agent (p: CANVAS_PAINTER; a: ARRAY [TUPLE [x1, y1, x2, y2: REAL_64]])
				do
					across a as l loop
						p.draw_line (l.x1, l.y1, l.x2, l.y2)
					end
				end (?, a_lines))
			create Result.make (a_cols, a_rows)
			l_canvas.render (Result.area, Result)
		end

	custom_lines_canvas (a_char: CHARACTER_32; a_lines: ARRAY [TUPLE [x1, y1, x2, y2: REAL_64]]): BUFFER
			-- As `lines_canvas`, with the Custom marker `a_char`.
		require
			one_column: {CANVAS_MARKER}.is_valid_custom_char (a_char)
		local
			l_canvas: TUI_CANVAS
		do
			create l_canvas.make
			l_canvas := l_canvas.with_custom_marker (a_char).with_bounds (0.0, 10.0, 0.0, 10.0)
			l_canvas.set_painter (agent (p: CANVAS_PAINTER; a: ARRAY [TUPLE [x1, y1, x2, y2: REAL_64]])
				do
					across a as l loop
						p.draw_line (l.x1, l.y1, l.x2, l.y2)
					end
				end (?, a_lines))
			create Result.make (5, 5)
			l_canvas.render (Result.area, Result)
		end

	assertion_message (a_action: ROUTINE): detachable READABLE_STRING_GENERAL
			-- Description of the assertion failure that `a_action` raises, if any;
			-- Void when it raises none, or raises another kind of exception.
		local
			l_retried: BOOLEAN
		do
			if not l_retried then
				a_action.call
			end
		rescue
			if not l_retried then
				l_retried := True
				if attached (create {EXCEPTION_MANAGER}).last_exception as e and then
					attached {DEVELOPER_EXCEPTION} e as d
				then
					Result := d.description
				end
				retry
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

	assert_one_cell_per_bit (a_marker: NATURAL_8)
			-- Each pseudo-pixel alone, on a 1-cell canvas of `a_marker`, gives mask bit x + 2 * y
			-- and the SYMBOLS_PIXEL character of that pattern.
		local
			l_h, x, y, l_bit: INTEGER
			l_grid: BRAILLE_CANVAS
			l_canvas: TUI_CANVAS
			l_buf: BUFFER
			l_expected: CHARACTER_32
		do
			l_h := {CANVAS_MARKER}.dots_y (a_marker)
			from y := 0 until y >= l_h loop
				from x := 0 until x > 1 loop
					l_bit := x + 2 * y
					-- The grid alone
					create l_grid.make_with_pattern (1, 1, 2, l_h)
					l_grid.set_pixel (x, y)
					assert ("marker " + a_marker.out + " mask of (" + x.out + ", " + y.out + ")", l_grid.cell_mask (0, 0) = (1 |<< l_bit).to_natural_8)

					-- Through TUI_CANVAS: bounds [0, 1] x [0, h - 1], one world unit per dot
					inspect a_marker
					when {CANVAS_MARKER}.quadrant then l_expected := {SYMBOLS_PIXEL}.quadrant (1 |<< l_bit)
					when {CANVAS_MARKER}.sextant then l_expected := {SYMBOLS_PIXEL}.sextant (1 |<< l_bit)
					else l_expected := {SYMBOLS_PIXEL}.octant (1 |<< l_bit)
					end
					create l_canvas.make
					l_canvas.set_marker (a_marker)
					l_canvas.set_bounds (0.0, 1.0, 0.0, (l_h - 1).to_double)
					l_canvas.set_painter (agent (p: CANVAS_PAINTER; wx, wy: REAL_64) do p.draw_point (wx, wy) end (?, x.to_double, (l_h - 1 - y).to_double))
					create l_buf.make (1, 1)
					l_canvas.render (l_buf.area, l_buf)
					assert_buffer_lines ("marker " + a_marker.out + " glyph of (" + x.out + ", " + y.out + ")", l_buf, <<create {STRING_32}.make_filled (l_expected, 1)>>)
					x := x + 1
				end
				y := y + 1
			end
		end

	assert_chart_marker_row (a_marker: NATURAL_8; a_glyph: CHARACTER_32)
			-- A chart whose only dataset, with `a_marker`, is a line along y_min: the plot row above
			-- the x axis holds `a_glyph` in every column, and the row above it is empty.
		local
			l_chart: TUI_CHART
			l_ds: TUI_CHART_DATASET
			l_buf: BUFFER
			c: INTEGER
		do
			create l_ds.make ("line")
			l_ds.set_marker (a_marker)
			assert ("marker set", l_ds.marker = a_marker)
			l_ds.append_point (0.0, 0.0)
			l_ds.append_point (10.0, 0.0)
			create l_chart.make_with_datasets (<<l_ds>>)
			l_chart.set_x_bounds (0.0, 10.0)
			l_chart.set_y_bounds (0.0, 10.0)
			-- 8 x 5: y axis in column 0, x axis on row 4, plot 7 x 4
			create l_buf.make (8, 5)
			l_chart.render (l_buf.area, l_buf)
			from c := 1 until c >= 8 loop
				assert_cell_symbol ("marker " + a_marker.out + " column " + c.out, l_buf, 3, c, create {STRING_32}.make_filled (a_glyph, 1))
				assert_cell_symbol ("marker " + a_marker.out + " empty above, column " + c.out, l_buf, 2, c, " ")
				c := c + 1
			end
		end

	dot_count (a_grid: BRAILLE_CANVAS): INTEGER
			-- Number of dots set in `a_grid`.
		local
			x, y: INTEGER
		do
			from y := 0 until y >= a_grid.subpixel_height loop
				from x := 0 until x >= a_grid.subpixel_width loop
					if a_grid.is_pixel_set (x, y) then
						Result := Result + 1
					end
					x := x + 1
				end
				y := y + 1
			end
		end

	assert_clipped_line_matches (a_x1, a_y1, a_x2, a_y2: REAL_64)
			-- Draw the line on a 10 x 10 Dot grid with bounds [0, 9] (one unit per dot), and on a
			-- reference Dot grid whose integer bounds contain both ends; the dots in [0, 9] must match.
		local
			l_small, l_ref: BRAILLE_CANVAS
			l_p: CANVAS_PAINTER
			l_xmin, l_xmax, l_ymin, l_ymax, x, y: INTEGER
		do
			create l_small.make_with_resolution (10, 10, 1, 1)
			create l_p.make (l_small, [0.0, 9.0], [0.0, 9.0])
			l_p.draw_line (a_x1, a_y1, a_x2, a_y2)

			l_xmin := a_x1.min (a_x2).floor.min (0)
			l_xmax := a_x1.max (a_x2).ceiling.max (9)
			l_ymin := a_y1.min (a_y2).floor.min (0)
			l_ymax := a_y1.max (a_y2).ceiling.max (9)
			create l_ref.make_with_resolution (l_xmax - l_xmin + 1, l_ymax - l_ymin + 1, 1, 1)
			create l_p.make (l_ref, [l_xmin.to_double, l_xmax.to_double], [l_ymin.to_double, l_ymax.to_double])
			l_p.draw_line (a_x1, a_y1, a_x2, a_y2)

			-- World (wx, wy) is dot (wx, 9 - wy) on the small grid and (wx - xmin, ymax - wy) on the reference
			from y := 0 until y > 9 loop
				from x := 0 until x > 9 loop
					assert ("dot (" + x.out + ", " + y.out + ") of line " + a_x1.out + ", " + a_y1.out + " -> " + a_x2.out + ", " + a_y2.out,
						l_small.is_pixel_set (x, 9 - y) = l_ref.is_pixel_set (x - l_xmin, l_ymax - y))
					x := x + 1
				end
				y := y + 1
			end
		end

end
