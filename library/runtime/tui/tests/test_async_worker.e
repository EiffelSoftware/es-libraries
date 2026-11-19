note
	description: "[
		P2 item B2 (review/p2_terminal_widgets_plan.md): TUI_APPLICATION calls
		`stop_background_work` once on every exit path of `run`, after the terminal is
		restored and before a termination request ends the process; EXAMPLE_ASYNC_GITHUB
		cancels and joins its fetch workers there, so `run` returns only once they have
		ended (or after the join timeout, for a worker that does not listen); a refresh
		stops the older worker, and a result from an older fetch is dropped.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_ASYNC_WORKER

inherit
	EQA_TEST_SET

feature -- Example

	test_quit_during_fetch_joins_worker
			-- Start a fetch and stop at once (one frame): `run` returns only after the worker
			-- has ended. It was cancelled, so it posted nothing and the result is not shown.
		local
			l_app: ASYNC_GITHUB_TEST_APP
		do
			l_app := new_app
			l_app.start_fetch
			l_app.set_auto_exit_frames (1)
			l_app.run
			assert ("worker ended before run returned", l_app.is_worker_finished)
			assert ("not timed out", not l_app.is_worker_join_timed_out)
			assert ("no worker kept", l_app.worker_count = 0)
			assert ("cancelled worker posted nothing", l_app.event_queue.is_empty)
			assert ("result not shown", l_app.is_loading_now and l_app.loaded_count = 0)
		end

	test_stale_fetch_result_dropped
			-- Two fetches: the result tagged with the first one's generation is dropped, the
			-- second one's is shown.
		local
			l_app: ASYNC_GITHUB_TEST_APP
		do
			l_app := new_app
			l_app.start_fetch
			l_app.start_fetch
			assert ("second generation", l_app.generation = 2)
			l_app.process_now (l_app.fetch_result (1))
			assert ("stale result dropped", l_app.is_loading_now and l_app.loaded_count = 0)
			l_app.process_now (l_app.fetch_result (2))
			assert ("latest result shown", not l_app.is_loading_now and l_app.loaded_count = 7)
			l_app.stop_background_work_now
			assert ("workers joined", l_app.worker_count = 0 and not l_app.is_worker_join_timed_out)
		end

	test_refresh_stops_older_worker
			-- A refresh during a fetch makes the older worker stop early (within its poll
			-- interval, well before the 500 ms latency), without posting.
		local
			l_app: ASYNC_GITHUB_TEST_APP
			l_deadline: INTEGER_64
		do
			l_app := new_app
			l_app.start_fetch
			l_app.start_fetch
			from
				l_deadline := {MONOTONIC_CLOCK}.milliseconds + 300
			until
				l_app.running_worker_count <= 1 or {MONOTONIC_CLOCK}.milliseconds > l_deadline
			loop
				(create {EXECUTION_ENVIRONMENT}).sleep (5_000_000)
			end
			assert ("older worker stopped", l_app.running_worker_count = 1)
			assert ("older worker posted nothing", l_app.event_queue.is_empty)
			l_app.stop_background_work_now
			assert ("workers joined", l_app.worker_count = 0 and not l_app.is_worker_join_timed_out)
		end

	test_quit_gives_up_after_join_timeout
			-- Quit while the worker is deaf to the cancel: `run` returns after the 500 ms join
			-- timeout, with the worker recorded as still running. Released, it sees the cancel
			-- and ends without posting.
		local
			l_app: ASYNC_GITHUB_TEST_APP
			l_start, l_elapsed: INTEGER_64
		do
			l_app := new_app
			l_app.hold_worker
			l_app.start_fetch
			l_app.set_auto_exit_frames (1)
			l_start := {MONOTONIC_CLOCK}.milliseconds
			l_app.run
			l_elapsed := {MONOTONIC_CLOCK}.milliseconds - l_start
			assert ("timed out", l_app.is_worker_join_timed_out)
			assert ("worker kept", not l_app.is_worker_finished and l_app.worker_count = 1)
			assert ("waited the timeout: " + l_elapsed.out + " ms", l_elapsed >= 450)
			assert ("returned in " + l_elapsed.out + " ms", l_elapsed < Wait_limit_ms)
			l_app.release
			assert ("worker ended once released", wait_until (agent l_app.is_worker_finished))
			assert ("posted nothing", l_app.event_queue.is_empty)
			assert ("forgotten", l_app.running_worker_count = 0)
		end

	test_termination_request_during_fetch
			-- A termination request (Ctrl+Break, SIGTERM) during a fetch: the worker is
			-- cancelled and joined before the process is ended (`finish_termination`).
		local
			l_app: ASYNC_GITHUB_TEST_APP
		do
			l_app := new_app
			if attached {FAKE_CONSOLE_DRIVER} l_app.terminal_driver as d then
				d.set_request_on_read (15, 1)
				l_app.start_fetch
					-- Only if the request is never seen, so that the test cannot hang
				l_app.set_auto_exit_frames (2000)
				l_app.run
				assert ("process ended", d.finish_count = 1)
				assert ("joined first", l_app.was_finished_at_join and l_app.finish_count_at_join = 0)
				assert ("not timed out", not l_app.is_worker_join_timed_out and l_app.worker_count = 0)
				assert ("posted nothing", l_app.event_queue.is_empty)
			else
				assert ("fake driver", False)
			end
		end

feature -- TUI_APPLICATION hook

	test_background_work_stopped_on_every_exit
			-- `stop_background_work` is called once per `run`, after the input thread has
			-- stopped and the terminal is restored: on `stop`, and again on a second run.
		local
			l_app: BACKGROUND_WORK_TEST_APP
		do
			l_app := new_hook_app
			l_app.run
			assert ("called once", l_app.stop_count = 1)
			assert ("after the restore", not l_app.was_set_up_at_stop)
			assert ("after the input thread", not l_app.was_input_running_at_stop)
			l_app.run
			assert ("once per run", l_app.stop_count = 2)
		end

	test_background_work_stopped_on_exception
			-- An exception from `render` still calls `stop_background_work` once, after the
			-- restore, and is then propagated.
		local
			l_app: detachable BACKGROUND_WORK_TEST_APP
			l_raised: BOOLEAN
		do
			if not l_raised then
				l_app := new_hook_app
				l_app.set_failing_frame (1)
				l_app.run
			end
			assert ("exception propagated", l_raised)
			if attached l_app as a then
				assert ("called once", a.stop_count = 1)
				assert ("after the restore", not a.was_set_up_at_stop)
				assert ("terminal restored", not a.is_terminal_set_up)
			else
				assert ("app attached", False)
			end
		rescue
			-- Only the run failure is expected; a failing assertion above must propagate
			if not l_raised then
				l_raised := True
				retry
			end
		end

	test_background_work_stopped_on_termination_request
			-- A termination request calls `stop_background_work` once, after the restore and
			-- before the process is ended (`finish_termination`).
		local
			l_app: BACKGROUND_WORK_TEST_APP
			l_driver: FAKE_CONSOLE_DRIVER
		do
			create l_driver
			create l_app.make_with_terminal (new_terminal_on (l_driver))
			l_app.event_thread.set_poll_interval (5)
			l_driver.set_request_on_read (2, 1)
				-- Stop only if the request is never seen, so that the test cannot hang
			l_app.set_draw_hook (agent (a_frame: FRAME; a_app: BACKGROUND_WORK_TEST_APP)
				do
					if a_app.draw_pass_count >= 2000 then
						a_app.stop
					end
				end (?, l_app))
			l_app.run
			assert ("process ended", l_driver.finish_count = 1)
			assert ("called once", l_app.stop_count = 1)
			assert ("after the restore", not l_app.was_set_up_at_stop)
			assert ("before the process ended", l_app.finish_count_at_stop = 0)
		end

	test_background_work_failure_dropped
			-- An exception from `stop_background_work` is dropped: `run` returns normally,
			-- with the terminal restored.
		local
			l_app: BACKGROUND_WORK_TEST_APP
		do
			l_app := new_hook_app
			l_app.set_raises_in_stop (True)
			l_app.run
			assert ("called once", l_app.stop_count = 1)
			assert ("stopped", not l_app.is_running)
			assert ("terminal restored", not l_app.is_terminal_set_up)
		end

feature {NONE} -- Helpers

	Wait_limit_ms: INTEGER = 10_000
			-- Longest wait for a worker in these tests

	wait_until (a_condition: FUNCTION [BOOLEAN]): BOOLEAN
			-- Did `a_condition` hold within `Wait_limit_ms`? (Looks every 2 ms.)
		local
			l_deadline: INTEGER_64
		do
			from
				l_deadline := {MONOTONIC_CLOCK}.milliseconds + Wait_limit_ms
				Result := a_condition.item ([])
			until
				Result or {MONOTONIC_CLOCK}.milliseconds > l_deadline
			loop
				(create {EXECUTION_ENVIRONMENT}).sleep (2_000_000)
				Result := a_condition.item ([])
			end
		end

	new_app: ASYNC_GITHUB_TEST_APP
			-- The example on an ANSI backend whose driver reads nothing.
		do
			create Result.make_on (new_terminal)
			Result.event_thread.set_poll_interval (5)
		end

	new_hook_app: BACKGROUND_WORK_TEST_APP
			-- An application recording its `stop_background_work` calls, on an ANSI backend
			-- whose driver reads nothing, that stops after its first frame.
		do
			create Result.make_with_terminal (new_terminal)
			Result.event_thread.set_poll_interval (5)
			-- Stop after the first frame; a second `run` would discard a posted quit key
			Result.set_draw_hook (agent (a_frame: FRAME; a_app: BACKGROUND_WORK_TEST_APP) do a_app.stop end (?, Result))
		end

	new_terminal: TERMINAL [ANSI_TERMINAL_BACKEND]
			-- A terminal on a fake driver, writing to a string.
		do
			Result := new_terminal_on (create {FAKE_CONSOLE_DRIVER})
		end

	new_terminal_on (a_driver: FAKE_CONSOLE_DRIVER): TERMINAL [ANSI_TERMINAL_BACKEND]
			-- A terminal on `a_driver`, writing to a string.
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_sink: STRING_32
			l_backend: ANSI_TERMINAL_BACKEND
		do
			l_driver := a_driver
			create l_sink.make_empty
			l_driver.watch_sink (l_sink)
			create l_backend.make_with_driver_and_sink (l_driver, l_sink)
			create Result.make (l_backend)
		end

end
