note
	description: "[
		EXAMPLE_ASYNC_GITHUB on a terminal the test gives, whose fetch worker records when
		it has ended, so that a test can check that `run` waits for it (P2 B2). The fetch
		takes 10 s instead of 500 ms, so that only a cancel or a refresh ends it within a
		test, however slow the machine; and a worker can be made deaf to them (held until
		`release`, at most `Hold_limit_ms`), so that the join times out.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	ASYNC_GITHUB_TEST_APP

inherit
	EXAMPLE_ASYNC_GITHUB
		redefine
			fetch_worker_body,
			fetch_latency_ms,
			stop_background_work
		end

create
	make_on

feature {NONE} -- Initialization

	make_on (a_terminal: TERMINAL [ANSI_TERMINAL_BACKEND])
			-- Initialize on `a_terminal` without running and without fetching.
		require
			terminal_attached: a_terminal /= Void
		do
			create flag_mutex.make
			init_state
			terminal_driver := a_terminal.backend.driver
			make_with_terminal (a_terminal)
			set_tick_rate (50)
			auto_exit_frames := -1
			frame_counter := 0
		ensure
			not_running: not is_running
		end

feature -- Status report

	is_worker_finished: BOOLEAN
			-- Has a fetch worker ended since the last `start_fetch`? (Read and written under
			-- `flag_mutex`: the worker sets it.)
		do
			flag_mutex.lock
			Result := worker_finished
			flag_mutex.unlock
		end

	is_loading_now: BOOLEAN
			-- Is the example waiting for a fetch?
		do
			Result := is_loading
		end

	loaded_count: INTEGER
			-- Number of pull requests shown
		do
			Result := pull_requests.count
		end

	generation: INTEGER
			-- Number of the latest fetch
		do
			Result := fetch_generation
		end

	worker_count: INTEGER
			-- Number of fetch workers kept (some may have ended since the last look)
		do
			Result := fetch_workers.count
		end

	running_worker_count: INTEGER
			-- Number of fetch workers still running
		do
			forget_ended_workers
			Result := fetch_workers.count
		end

	is_worker_join_timed_out: BOOLEAN
			-- Did the last `stop_background_work` leave a worker running?
		do
			Result := worker_join_timed_out
		end

	was_finished_at_join: BOOLEAN
			-- At the end of the last `stop_background_work`, had the worker ended?

	finish_count_at_join: INTEGER
			-- `finish_termination` calls of the fake driver at the end of the last
			-- `stop_background_work` (-1: not a FAKE_CONSOLE_DRIVER)

	terminal_driver: CONSOLE_DRIVER
			-- The driver of the terminal given at creation

feature -- Driving

	start_fetch
			-- Start a fetch as the `r` key does.
		do
			flag_mutex.lock
			worker_finished := False
			flag_mutex.unlock
			trigger_fetch
		end

	hold_worker
			-- Make the next fetch worker deaf to cancels and refreshes: it waits until
			-- `release` (at most `Hold_limit_ms`), then goes on as the example's.
		do
			flag_mutex.lock
			is_holding := True
			is_released := False
			flag_mutex.unlock
		end

	release
			-- Let a held worker go on.
		do
			flag_mutex.lock
			is_released := True
			flag_mutex.unlock
		end

	set_auto_exit_frames (a_frames: INTEGER)
			-- Stop `run` after `a_frames` frames.
		require
			positive: a_frames > 0
		do
			auto_exit_frames := a_frames
			frame_counter := 0
		end

	process_now (a_event: EVENT)
			-- Process `a_event` as the example does.
		require
			event_attached: a_event /= Void
		do
			process (a_event)
		end

	fetch_result (a_generation: INTEGER): CUSTOM_EVENT
			-- The event a worker posts for fetch `a_generation`
		do
			Result := new_fetch_result (a_generation)
		end

	stop_background_work_now
			-- Cancel the fetches and join the workers, as `run` does when it ends.
		require
			not_running: not is_running
		do
			stop_background_work
		end

feature {NONE} -- Worker

	fetch_latency_ms: INTEGER
			-- 10 s: only a cancel or a refresh ends a fetch within a test
		do
			Result := 10_000
		end

	fetch_worker_body (a_generation: INTEGER)
			-- Wait while held, then the example's worker, then record that it has ended.
		local
			l_holding: BOOLEAN
			l_deadline: INTEGER_64
		do
			flag_mutex.lock
			l_holding := is_holding
			is_holding := False
			flag_mutex.unlock
			from
				l_deadline := {MONOTONIC_CLOCK}.milliseconds + Hold_limit_ms
			until
				not l_holding
			loop
				(create {EXECUTION_ENVIRONMENT}).sleep (2_000_000)
				flag_mutex.lock
				l_holding := not is_released and {MONOTONIC_CLOCK}.milliseconds <= l_deadline
				flag_mutex.unlock
			end
			Precursor (a_generation)
			flag_mutex.lock
			worker_finished := True
			flag_mutex.unlock
		end

	stop_background_work
			-- The example's, then record whether the worker had ended and whether the process
			-- had been ended (`finish_termination`) by then.
		do
			Precursor
			was_finished_at_join := is_worker_finished
			if attached {FAKE_CONSOLE_DRIVER} terminal_driver as d then
				finish_count_at_join := d.finish_count
			else
				finish_count_at_join := -1
			end
		end

	is_holding, is_released: BOOLEAN
			-- Will the next worker wait at the start? Has it been released?

	Hold_limit_ms: INTEGER = 5000
			-- Longest wait of a held worker

	worker_finished: BOOLEAN
			-- Storage of `is_worker_finished`

	flag_mutex: MUTEX
			-- Guards `worker_finished`, `is_holding` and `is_released`

end
