note
	description: "[
		TEST_TUI_APP_IMPL whose `stop_background_work` records each call, and the state of
		the application at that moment, and can raise (P2 B2).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	BACKGROUND_WORK_TEST_APP

inherit
	TEST_TUI_APP_IMPL
		redefine
			stop_background_work
		end

create
	make_with_terminal

feature -- Access

	stop_count: INTEGER
			-- Number of calls to `stop_background_work`

	was_set_up_at_stop: BOOLEAN
			-- Was the terminal still set up at the last call?

	was_input_running_at_stop: BOOLEAN
			-- Was the input thread still running at the last call?

	finish_count_at_stop: INTEGER
			-- `finish_termination` calls of the fake driver at the last call (-1: not a
			-- FAKE_CONSOLE_DRIVER)

	raises_in_stop: BOOLEAN
			-- Does `stop_background_work` raise?

feature -- Settings

	set_raises_in_stop (a_raises: BOOLEAN)
			-- Make `stop_background_work` raise (or not).
		do
			raises_in_stop := a_raises
		ensure
			set: raises_in_stop = a_raises
		end

feature {NONE} -- Background work

	stop_background_work
			-- Record the call, then raise if `raises_in_stop`.
		local
			l_failure: DEVELOPER_EXCEPTION
		do
			stop_count := stop_count + 1
			was_set_up_at_stop := is_terminal_set_up
			was_input_running_at_stop := not event_thread.terminated
			if attached {FAKE_CONSOLE_DRIVER} backend.driver as d then
				finish_count_at_stop := d.finish_count
			else
				finish_count_at_stop := -1
			end
			if raises_in_stop then
				create l_failure
				l_failure.set_description ("stop_background_work failed")
				l_failure.raise
			end
		end

end
