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
	EQA_TEST_SET

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

feature {NONE} -- Helper Agent

	paint_test_pattern (p: CANVAS_PAINTER)
			-- Painter agent for test_tui_canvas_rendering_with_agent.
		do
			p.draw_line (0.0, 0.0, 100.0, 100.0)
		end

end
