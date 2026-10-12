note
	description: "[
		Automated test suite verifying all 7 Tier 2 Widget Specialist examples
		execute cleanly in batch / headless mode without raising exceptions,
		and properly restore the terminal environment.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_TIER2_EXAMPLES

inherit
	EQA_TEST_SET

feature -- Test: Todo List

	test_example_todo_list
			-- Verify EXAMPLE_TODO_LIST runs in batch mode without error.
		local
			l_app: EXAMPLE_TODO_LIST
		do
			create l_app.make_batch (1)
			assert ("not running after batch", not l_app.is_running)
			assert ("terminal restored", not l_app.is_terminal_set_up)
		end

feature -- Test: User Input

	test_example_user_input
			-- Verify EXAMPLE_USER_INPUT runs in batch mode without error.
		local
			l_app: EXAMPLE_USER_INPUT
		do
			create l_app.make_batch (1)
			assert ("not running after batch", not l_app.is_running)
			assert ("terminal restored", not l_app.is_terminal_set_up)
		end

feature -- Test: Input Form

	test_example_input_form
			-- Verify EXAMPLE_INPUT_FORM runs in batch mode without error.
		local
			l_app: EXAMPLE_INPUT_FORM
		do
			create l_app.make_batch (1)
			assert ("not running after batch", not l_app.is_running)
			assert ("terminal restored", not l_app.is_terminal_set_up)
		end

feature -- Test: Table

	test_example_table
			-- Verify EXAMPLE_TABLE runs in batch mode without error.
		local
			l_app: EXAMPLE_TABLE
		do
			create l_app.make_batch (1)
			assert ("not running after batch", not l_app.is_running)
			assert ("terminal restored", not l_app.is_terminal_set_up)
		end

feature -- Test: Scrollbar

	test_example_scrollbar
			-- Verify EXAMPLE_SCROLLBAR runs in batch mode without error.
		local
			l_app: EXAMPLE_SCROLLBAR
		do
			create l_app.make_batch (1)
			assert ("not running after batch", not l_app.is_running)
			assert ("terminal restored", not l_app.is_terminal_set_up)
		end

feature -- Test: Gauge

	test_example_gauge
			-- Verify EXAMPLE_GAUGE runs in batch mode without error.
		local
			l_app: EXAMPLE_GAUGE
		do
			create l_app.make_batch (2)
			assert ("not running after batch", not l_app.is_running)
			assert ("terminal restored", not l_app.is_terminal_set_up)
		end

feature -- Test: Calendar Explorer

	test_example_calendar_explorer
			-- Verify EXAMPLE_CALENDAR_EXPLORER runs in batch mode without error.
		local
			l_app: EXAMPLE_CALENDAR_EXPLORER
		do
			create l_app.make_batch (1)
			assert ("not running after batch", not l_app.is_running)
			assert ("terminal restored", not l_app.is_terminal_set_up)
		end

end
