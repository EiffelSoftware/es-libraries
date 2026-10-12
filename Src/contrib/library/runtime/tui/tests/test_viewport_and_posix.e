note
	description: "[
		Unit tests for Phase 12: Viewport Modes & Cross-Platform POSIX Driver
		(VIEWPORT, fixed viewport resize, FRAME cursor positioning, platform TERMINAL_DRIVER).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_VIEWPORT_AND_POSIX

inherit
	EQA_TEST_SET

feature -- Test Routines

	test_viewport_modes
			-- Test VIEWPORT creation in Fullscreen, Inline, and Fixed modes.
		local
			l_vp_full, l_vp_inline, l_vp_fixed: VIEWPORT
			l_rect: RECT
		do
			-- 1. Fullscreen
			create l_vp_full.make_fullscreen
			assert ("fullscreen mode", l_vp_full.is_fullscreen)
			assert ("not inline", not l_vp_full.is_inline)
			assert ("not fixed", not l_vp_full.is_fixed)

			-- 2. Inline
			create l_vp_inline.make_inline (12)
			assert ("is inline", l_vp_inline.is_inline)
			assert ("not fullscreen", not l_vp_inline.is_fullscreen)
			assert ("height is 12", l_vp_inline.inline_height = 12)

			-- 3. Fixed
			create l_rect.make (10, 5, 40, 20)
			create l_vp_fixed.make_fixed (l_rect)
			assert ("is fixed", l_vp_fixed.is_fixed)
			assert ("fixed area width 40", attached l_vp_fixed.fixed_area as fa and then fa.width = 40)
		end

	test_fixed_viewport_resize
			-- TERMINAL.resize moves a fixed viewport: new buffer size, cleared screen, offset drawing.
		local
			l_vt: VIRTUAL_TERMINAL
			l_term: TERMINAL [VIRTUAL_TERMINAL]
			l_vp: VIEWPORT
		do
			create l_vt.make (80, 24)
			create l_vp.make_fixed (create {RECT}.make (0, 0, 20, 5))
			create l_term.make_with_viewport (l_vt, l_vp)
			assert ("initial width 20", l_term.width = 20)

			l_term.resize (create {RECT}.make (10, 3, 30, 6))
			assert ("width 30", l_term.width = 30)
			assert ("height 6", l_term.height = 6)
			assert ("screen cleared", l_vt.operations.has ("clear_screen"))

			-- A later draw keeps the fixed size instead of reverting to the backend size
			l_term.draw (agent draw_with_cursor)
			assert ("size kept by draw", l_term.width = 30 and l_term.height = 6)
			assert ("drawn at fixed origin", l_vt.cell (3, 10) = 'I')
			assert ("cursor offset by origin", l_vt.cursor_row = 5 and l_vt.cursor_column = 15)
		end

	test_frame_cursor_positioning
			-- Test FRAME hardware cursor tracking and visibility controls.
		local
			l_buf: BUFFER
			l_frame: FRAME
			l_pos: detachable TUPLE [col, row: INTEGER]
		do
			create l_buf.make (20, 10)
			create l_frame.make (l_buf)

			-- Default: no explicit cursor position
			assert ("default cursor position void", l_frame.cursor_position = Void)

			-- Set cursor position to (7, 3)
			l_frame.set_cursor_position (7, 3)
			l_pos := l_frame.cursor_position
			assert ("cursor position attached", l_pos /= Void)
			if attached l_pos as p then
				assert ("col is 7", p.integer_32_item (1) = 7)
				assert ("row is 3", p.integer_32_item (2) = 3)
			end
			assert ("cursor is visible", l_frame.is_cursor_visible)

			-- Hide cursor
			l_frame.hide_cursor
			assert ("cursor hidden", not l_frame.is_cursor_visible)
			assert ("cursor position cleared", l_frame.cursor_position = Void)
		end

	test_terminal_with_inline_viewport_and_cursor
			-- Test TERMINAL configured with inline viewport and hardware cursor dispatch.
		local
			l_term_backend: VIRTUAL_TERMINAL
			l_terminal: TERMINAL [VIRTUAL_TERMINAL]
			l_vp: VIEWPORT
		do
			create l_term_backend.make (80, 24)
			create l_vp.make_inline_at (8, 10)
			create l_terminal.make_with_viewport (l_term_backend, l_vp)

			-- Viewport height is 8
			assert ("terminal height is 8", l_terminal.height = 8)
			assert ("terminal width is 80", l_terminal.width = 80)

			-- Draw with cursor positioning pass
			l_terminal.draw (agent draw_with_cursor)

			-- Backend cursor should be positioned at col 5, row 12 (offset 10 + row 2)
			assert ("backend cursor col is 5", l_term_backend.cursor_column = 5)
			assert ("backend cursor row is 12", l_term_backend.cursor_row = 12)
			assert ("backend cursor visible", l_term_backend.is_cursor_visible)

			-- Rendered text should be at row 10 (offset), not row 0
			assert ("rendered at offset row 10", l_term_backend.cell (10, 0) = 'I')
			assert ("unoffset row 0 is blank", l_term_backend.cell (0, 0) = ' ')
		end

	test_platform_terminal_driver
			-- TERMINAL_DRIVER (the driver the ECF selects for this platform) queries and contracts.
		local
			l_driver: TERMINAL_DRIVER
		do
			create l_driver
			assert ("positive width", l_driver.console_width > 0)
			assert ("positive height", l_driver.console_height > 0)
			assert ("enable raw mode succeeds", l_driver.enable_raw_mode)
			assert ("disable raw mode succeeds", l_driver.disable_raw_mode)
			l_driver.restore_modes
			assert ("not raw after restore", not l_driver.is_raw)
		end

feature {NONE} -- Helper Drawing Agent

	draw_with_cursor (f: FRAME)
			-- Render agent that sets hardware cursor.
		local
			l_p: TUI_PARAGRAPH
			l_t: TEXT
		do
			create l_t.make_raw ("Input: test")
			create l_p.make (l_t)
			f.render_widget (l_p, f.area)
			f.set_cursor_position (5, 2)
		end

end
