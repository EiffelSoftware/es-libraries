note
	description: "[
		One console input reader at a time (review finding C3):
		- CONSOLE_INPUT_CLAIM is exclusive; the platform drivers share one claim per process
		- EVENT_THREAD holds the claim from `start' until it ends; a second reader is refused
		- a DSR query holds the claim only while it reads
		- the DSR query, the inline viewport setup and `run' are refused while a reader runs
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_CONSOLE_INPUT_CLAIM

inherit
	EQA_TEST_SET

feature -- Claim

	test_claim_is_exclusive
			-- A claim is taken once, refused while held, and free again after `release`.
		local
			l_claim: CONSOLE_INPUT_CLAIM
		do
			create l_claim.make
			assert ("free at first", not l_claim.is_held)
			assert ("taken", l_claim.try_acquire)
			assert ("held", l_claim.is_held)
			assert ("refused while held", not l_claim.try_acquire)
			l_claim.release
			assert ("free again", not l_claim.is_held)
			assert ("taken again", l_claim.try_acquire)
			l_claim.release
		end

	test_platform_drivers_share_one_claim
			-- Two platform drivers read the same console, so they share one claim; two fake
			-- drivers are separate consoles, so they do not.
		local
			l_a, l_b: TERMINAL_DRIVER
			l_fa, l_fb: FAKE_CONSOLE_DRIVER
		do
			create l_a
			create l_b
			assert ("platform drivers share the claim", l_a.input_claim = l_b.input_claim)
			create l_fa
			create l_fb
			assert ("fake drivers do not", l_fa.input_claim /= l_fb.input_claim)
			assert ("one claim per fake driver", l_fa.input_claim = l_fa.input_claim)
		end

feature -- Event thread

	test_event_thread_holds_claim_while_running
			-- `start` takes the claim before the thread runs, and it is free after stop and join.
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_thread: EVENT_THREAD
		do
			create l_driver
			create l_thread.make (create {SYNCHRONIZED_EVENT_QUEUE}.make, l_driver)
			l_thread.set_poll_interval (5)
			l_thread.start
			assert ("claimed as soon as start returns", l_driver.is_input_claimed)
			l_thread.stop
			l_thread.join
			assert ("released when the thread ends", not l_driver.is_input_claimed)
		end

	test_second_reader_refused
			-- A second input thread on the same console cannot start while the first runs,
			-- and can once it has ended.
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_queue: SYNCHRONIZED_EVENT_QUEUE
			l_first, l_second: EVENT_THREAD
		do
			create l_driver
			create l_queue.make
			create l_first.make (l_queue, l_driver)
			l_first.set_poll_interval (5)
			create l_second.make (l_queue, l_driver)
			l_second.set_poll_interval (5)
			l_first.start
			assert ("second start refused", precondition_raised (agent l_second.start, "input_not_claimed"))
			assert ("second thread not launched", l_second.is_launchable)
			l_first.stop
			l_first.join

			l_second.start
			assert ("second thread reads now", l_driver.is_input_claimed)
			l_second.stop
			l_second.join
			assert ("released", not l_driver.is_input_claimed)
		end

feature -- Cursor position query

	test_query_releases_claim
			-- The DSR query holds the claim only while it reads: free after an answer and
			-- after a timeout, so the input thread can start afterwards.
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_backend: ANSI_TERMINAL_BACKEND
		do
			l_driver := new_driver
			l_backend := new_backend (l_driver)
			l_driver.script ("%/27/[3;4R")
			assert ("answered", attached l_backend.query_cursor_position as p and then (p.row = 2 and p.column = 3))
			assert ("free after an answer", not l_backend.is_input_in_use)
			assert ("no answer", l_backend.query_cursor_position = Void)
			assert ("free after a timeout", not l_backend.is_input_in_use)
		end

	test_query_refused_while_reader_runs
			-- While the input thread runs, the DSR query is refused and sends nothing, and the
			-- thread still gets every byte (a report included, as a CURSOR_POSITION_EVENT).
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_sink: STRING_32
			l_backend: ANSI_TERMINAL_BACKEND
			l_queue: SYNCHRONIZED_EVENT_QUEUE
			l_thread: EVENT_THREAD
			l_events: ARRAYED_LIST [EVENT]
		do
			l_driver := new_driver
			create l_sink.make_empty
			create l_backend.make_with_driver_and_sink (l_driver, l_sink)
			create l_queue.make
			create l_thread.make (l_queue, l_driver)
			l_thread.set_poll_interval (5)
			l_thread.start
			assert ("input in use", l_backend.is_input_in_use)
			assert ("query refused", precondition_raised (agent run_query (l_backend), "input_not_in_use"))
			assert ("no DSR sent", not l_sink.has_substring ("%/27/[6n"))

			l_driver.script ("a%/27/[3;4Rb")
			l_events := collect_events (l_queue, 3, 3000)
			l_thread.stop
			l_thread.join
			assert ("three events", l_events.count = 3)
			assert ("a", attached {KEY_EVENT} l_events.i_th (1) as k1 and then (k1.code.is_char and then k1.code.character = 'a'))
			assert ("report", attached {CURSOR_POSITION_EVENT} l_events.i_th (2) as r and then (r.row = 2 and r.column = 3))
			assert ("b", attached {KEY_EVENT} l_events.i_th (3) as k3 and then (k3.code.is_char and then k3.code.character = 'b'))
		end

	test_inline_setup_refused_while_reader_runs
			-- `setup_inline_viewport` asks the terminal for the cursor, so it is refused while
			-- the input thread runs.
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_term: TERMINAL [ANSI_TERMINAL_BACKEND]
			l_thread: EVENT_THREAD
		do
			l_driver := new_driver
			create l_term.make_with_viewport (new_backend (l_driver), create {VIEWPORT}.make_inline (3))
			create l_thread.make (create {SYNCHRONIZED_EVENT_QUEUE}.make, l_driver)
			l_thread.set_poll_interval (5)
			l_thread.start
			assert ("setup refused", precondition_raised (agent l_term.setup_inline_viewport, "input_not_in_use"))
			l_thread.stop
			l_thread.join
		end

feature -- Application

	test_application_holds_claim_while_running
			-- While `run` is active the console input is in use and a DSR query is refused;
			-- after `run` it is free.
		local
			l_app: TEST_TUI_APP_IMPL
			l_in_use, l_refused: CELL [BOOLEAN]
		do
			l_app := new_app ("aq")
			create l_in_use.put (False)
			create l_refused.put (False)
			l_app.set_key_hook (agent (k: KEY_EVENT; a: TEST_TUI_APP_IMPL; u, r: CELL [BOOLEAN])
				do
					if k.code.is_char and then k.code.character = 'a' then
						u.put (a.backend.is_input_in_use)
						r.put (precondition_raised (agent run_query (a.backend), "input_not_in_use"))
					end
				end (?, l_app, l_in_use, l_refused))
			l_app.run
			assert ("both keys processed", l_app.key_count = 2)
			assert ("in use while running", l_in_use.item)
			assert ("query refused while running", l_refused.item)
			assert ("free after run", not l_app.backend.is_input_in_use)
		end

	test_run_refused_while_input_in_use
			-- `run` does not touch the terminal while another reader holds the console input.
		local
			l_app: TEST_TUI_APP_IMPL
			l_driver: FAKE_CONSOLE_DRIVER
		do
			l_app := new_app ("q")
			check attached {FAKE_CONSOLE_DRIVER} l_app.backend.driver as d then
				l_driver := d
			end
			assert ("taken by another reader", l_driver.input_claim.try_acquire)
			assert ("run refused", precondition_raised (agent l_app.run, "input_not_in_use"))
			assert ("raw mode not entered", l_driver.raw_enable_count = 0)
			assert ("not running", not l_app.is_running)
			l_driver.input_claim.release

			l_app.run
			assert ("runs once the input is free", l_app.key_count = 1)
		end

feature {NONE} -- Helpers

	precondition_raised (a_action: PROCEDURE; a_tag: STRING): BOOLEAN
			-- Does `a_action` raise a precondition violation tagged `a_tag`? (Seen through
			-- `original`: a routine with a rescue clause passes it on as a routine failure.)
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

	run_query (a_backend: ANSI_TERMINAL_BACKEND)
			-- Ask `a_backend` for the cursor position, ignoring the answer.
		do
			if attached a_backend.query_cursor_position then
			end
		end

	new_driver: FAKE_CONSOLE_DRIVER
			-- Fake console with an empty script
		do
			create Result
		end

	new_backend (a_driver: FAKE_CONSOLE_DRIVER): ANSI_TERMINAL_BACKEND
			-- ANSI backend on `a_driver`, with its output captured
		do
			create Result.make_with_driver_and_sink (a_driver, create {STRING_32}.make_empty)
		end

	new_app (a_input: READABLE_STRING_8): TEST_TUI_APP_IMPL
			-- Application on a fake console that replays `a_input`
		local
			l_driver: FAKE_CONSOLE_DRIVER
		do
			l_driver := new_driver
			l_driver.script (a_input)
			create Result.make_with_terminal (create {TERMINAL [ANSI_TERMINAL_BACKEND]}.make (new_backend (l_driver)))
			Result.event_thread.set_poll_interval (5)
		end

	collect_events (a_queue: SYNCHRONIZED_EVENT_QUEUE; a_count, a_timeout_ms: INTEGER): ARRAYED_LIST [EVENT]
			-- Up to `a_count` events from `a_queue`, waiting at most `a_timeout_ms` overall.
		local
			l_deadline: INTEGER_64
		do
			create Result.make (a_count)
			from
				l_deadline := {MONOTONIC_CLOCK}.milliseconds + a_timeout_ms
			until
				Result.count >= a_count or {MONOTONIC_CLOCK}.milliseconds > l_deadline
			loop
				if attached a_queue.poll_with_timeout (20) as e then
					Result.extend (e)
				end
			end
		end

end
