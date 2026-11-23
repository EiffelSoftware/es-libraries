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

feature -- Test: Text Area

	test_example_text_area
			-- Verify EXAMPLE_TEXT_AREA runs in batch mode without error.
		local
			l_app: EXAMPLE_TEXT_AREA
		do
			create l_app.make_batch (1)
			assert ("not running after batch", not l_app.is_running)
			assert ("terminal restored", not l_app.is_terminal_set_up)
		end

feature -- Test: Modal Dialog

	test_example_modal_dialog
			-- Verify EXAMPLE_MODAL_DIALOG runs in batch mode without error.
		local
			l_app: EXAMPLE_MODAL_DIALOG
		do
			create l_app.make_batch (1)
			assert ("not running after batch", not l_app.is_running)
			assert ("terminal restored", not l_app.is_terminal_set_up)
		end

	test_example_modal_dialog_clicks
			-- Drive EXAMPLE_MODAL_DIALOG on an 80x24 fake console with clicks and keys, one
			-- step per frame (SGR mouse positions are 1-based). While the confirmation is
			-- open, clicks on the background are blocked; its Yes / No buttons and Tab work;
			-- the non-modal hint leaves the background clickable, and its Dismiss button
			-- (the popup's inner widget) is clickable too.
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_sink: STRING_32
			l_backend: ANSI_TERMINAL_BACKEND
			l_app: MODAL_DIALOG_SCRIPTED_APP
		do
			create l_driver
			create l_sink.make_empty
			l_driver.watch_sink (l_sink)
			create l_backend.make_with_driver_and_sink (l_driver, l_sink)
			create l_app.make_scripted (l_driver,
				create {TERMINAL [ANSI_TERMINAL_BACKEND]}.make_with_viewport (l_backend, create {VIEWPORT}.make_fullscreen),
				<<
					Esc + "[<0;11;4M",	-- 1 click notes.md (frame 10, 3)
					Esc + "[<0;6;7M",	-- 2 click Delete (5, 6): the dialog opens
					Esc + "[<0;11;3M",	-- 3 click report.txt behind the dialog: blocked
					Esc + "[<0;21;7M",	-- 4 click Help behind the dialog: blocked
					Esc + "[<0;44;14M",	-- 5 click No (43, 13): the TUI_DIALOG box is (27, 9) 26x6, No at 41..46
					"d",				-- 6 ask again
					"%T",				-- 7 Tab from No to Yes
					"%R",				-- 8 Enter: Yes
					Esc + "[<0;21;7M",	-- 9 click Help (20, 6): non-modal hint
					Esc + "[<0;11;3M",	-- 10 click report.txt with the hint open
					Esc + "[<0;51;20M",	-- 11 click Dismiss, the hint's inner widget (50, 19)
					"q"					-- 12 quit
				>>)
			l_app.event_thread.set_poll_interval (5)
			l_app.run
			assert ("terminal restored", not l_app.is_terminal_set_up)
			assert ("every step processed", l_app.log.count = 12)
			assert ("1 notes.md selected", l_app.log [1].selected = 2 and not l_app.log [1].modal)
			assert ("2 dialog open", l_app.log [2].modal)
			assert ("3 background click blocked", l_app.log [3].modal and l_app.log [3].selected = 2 and l_app.log [3].blocked = 1)
			assert ("4 Help blocked", l_app.log [4].modal and not l_app.log [4].hint and l_app.log [4].blocked = 2)
			assert ("5 No closes, nothing deleted", not l_app.log [5].modal and l_app.log [5].files = 3)
			assert ("6 open again", l_app.log [6].modal)
			assert ("7 Tab stays in the dialog", l_app.log [7].modal and l_app.log [7].files = 3)
			assert ("8 Yes deletes notes.md", not l_app.log [8].modal and l_app.log [8].files = 2
				and not l_app.file_names.has ({STRING_32} "notes.md"))
			assert ("9 hint open", l_app.log [9].hint and not l_app.log [9].modal)
			assert ("10 background clickable under a non-modal popup", l_app.log [10].selected = 1 and l_app.log [10].hint)
			assert ("11 Dismiss clicked", not l_app.log [11].hint)
			assert ("no click blocked without the dialog", l_app.log [12].blocked = 2)
		end

	Esc: STRING = "%/27/"
			-- Escape character

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
