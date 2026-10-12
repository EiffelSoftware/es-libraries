note
	description: "[
		AutoTest suite for TERMINAL_BACKEND and VIRTUAL_TERMINAL.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_TERMINAL_BACKEND

inherit
	EQA_TEST_SET

feature -- Test routines

	test_virtual_terminal_initialization
			-- Test initial dimensions and cursor placement.
		local
			l_term: VIRTUAL_TERMINAL
		do
			create l_term.make (40, 10)
			assert ("width set", l_term.width = 40)
			assert ("height set", l_term.height = 10)
			assert ("cursor at row 0", l_term.cursor_row = 0)
			assert ("cursor at col 0", l_term.cursor_column = 0)
			assert ("cursor visible by default", l_term.is_cursor_visible)
			assert ("not raw by default", not l_term.is_raw)
		end

	test_cursor_movement
			-- Test moving cursor within bounds.
		local
			l_term: VIRTUAL_TERMINAL
		do
			create l_term.make (80, 24)
			l_term.move_cursor (5, 12)
			assert ("row moved", l_term.cursor_row = 5)
			assert ("col moved", l_term.cursor_column = 12)
			assert ("move logged", l_term.operations.has ("move_cursor(5, 12)"))
		end

	test_put_string_and_cell_inspection
			-- Test writing string into virtual terminal and verifying grid cells.
		local
			l_term: VIRTUAL_TERMINAL
		do
			create l_term.make (20, 5)
			l_term.move_cursor (1, 2)
			l_term.put_string ("Hello")
			assert ("H written", l_term.cell (1, 2) = 'H')
			assert ("e written", l_term.cell (1, 3) = 'e')
			assert ("l written", l_term.cell (1, 4) = 'l')
			assert ("l written 2", l_term.cell (1, 5) = 'l')
			assert ("o written", l_term.cell (1, 6) = 'o')
			assert ("empty cell remains space", l_term.cell (1, 1) = ' ')
			assert ("cursor advanced", l_term.cursor_column = 7)
		end

	test_clear_screen
			-- Test clearing screen resets cells and cursor.
		local
			l_term: VIRTUAL_TERMINAL
		do
			create l_term.make (10, 5)
			l_term.move_cursor (2, 2)
			l_term.put_string ("Data")
			assert ("has char", l_term.cell (2, 2) = 'D')
			l_term.clear_screen
			assert ("cleared to space", l_term.cell (2, 2) = ' ')
			assert ("cursor reset to 0", l_term.cursor_row = 0 and l_term.cursor_column = 0)
			assert ("clear logged", l_term.operations.has ("clear_screen"))
		end

	test_screen_modes
			-- Test raw mode, alternate screen, and cursor visibility toggles.
		local
			l_term: VIRTUAL_TERMINAL
		do
			create l_term.make_default
			l_term.enter_raw_mode
			assert ("raw active", l_term.is_raw)
			l_term.leave_raw_mode
			assert ("raw inactive", not l_term.is_raw)

			l_term.enter_alternate_screen
			assert ("alt active", l_term.is_alternate_screen)
			l_term.leave_alternate_screen
			assert ("alt inactive", not l_term.is_alternate_screen)

			l_term.hide_cursor
			assert ("cursor hidden", not l_term.is_cursor_visible)
			l_term.show_cursor
			assert ("cursor shown", l_term.is_cursor_visible)
		end

end
