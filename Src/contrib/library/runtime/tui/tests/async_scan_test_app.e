note
	description: "[
		EXAMPLE_ASYNC_SCAN on a terminal and a tree the test gives (P2 A1), with a fixed toast
		clock, a scanner that cannot list directories named "locked" (when asked), and a gate
		that holds a worker back at a step or before it posts its result, so that a test can
		cancel, refresh or quit during a scan without depending on timing. Every wait here is
		bounded (`Gate_limit_ms').
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	ASYNC_SCAN_TEST_APP

inherit
	EXAMPLE_ASYNC_SCAN
		redefine
			clock_ms,
			batch_limit_ms,
			new_scanner,
			at_scan_step,
			before_posting_result,
			scan_worker_body
		end

create
	make_on_tree

feature {NONE} -- Initialization

	make_on_tree (a_terminal: TERMINAL [ANSI_TERMINAL_BACKEND]; a_root: READABLE_STRING_GENERAL)
			-- Initialize on `a_terminal` to scan `a_root`, without scanning or running.
		require
			terminal_attached: a_terminal /= Void
			root_not_empty: not a_root.is_empty
		do
			create gate_mutex.make
			make_on (a_terminal, a_root)
		ensure
			not_running: not is_running
		end

feature -- Settings

	clock_ms: INTEGER_64
			-- A clock that never moves, so toasts stay for a snapshot
		do
			Result := 0
		end

	batch_limit_ms: INTEGER_64
			-- `test_batch_limit_ms` if set, else the example's
		do
			if test_batch_limit_ms > 0 then
				Result := test_batch_limit_ms
			else
				Result := Precursor
			end
		end

	test_batch_limit_ms: INTEGER_64
			-- Longest batch run set by the test (0: the example's)

	set_batch_limit_ms (a_ms: INTEGER_64)
			-- Make a batch run quit `a_ms` milliseconds after `set_batch_now` at the latest.
		require
			positive: a_ms > 0
		do
			test_batch_limit_ms := a_ms
		ensure
			set: batch_limit_ms = a_ms
		end

	simulates_locked: BOOLEAN
			-- Does the scanner treat directories named "locked" as unreadable?

	set_simulates_locked (a_on: BOOLEAN)
			-- Treat directories named "locked" as unreadable (or not).
		do
			simulates_locked := a_on
		ensure
			set: simulates_locked = a_on
		end

	set_step_delay (a_ms: INTEGER)
			-- Make each worker step take at least `a_ms` milliseconds.
		require
			not_negative: a_ms >= 0
		do
			gate_mutex.lock
			step_delay_ms := a_ms
			gate_mutex.unlock
		end

	hold_at_step (a_generation: INTEGER; a_ignores_cancel: BOOLEAN)
			-- Hold the worker of scan `a_generation` at its first step until `release`, or
			-- until the scan is stale or cancelled unless `a_ignores_cancel`.
		do
			set_gate (Stage_step, a_generation, a_ignores_cancel)
		end

	hold_before_result (a_generation: INTEGER)
			-- Hold the worker of scan `a_generation` once it has checked that its result is
			-- wanted, before it posts it, until `release`.
		do
			set_gate (Stage_result, a_generation, True)
		end

	release
			-- Let a held worker go on.
		do
			gate_mutex.lock
			is_released := True
			gate_mutex.unlock
		end

	set_batch_now
			-- Quit once the first scan has ended.
		do
			set_batch
		end

	stop_after_frames (a_frames: INTEGER)
			-- Stop `run` after `a_frames` frames, whatever the scan does.
		require
			positive: a_frames > 0
		do
			auto_exit_frames := a_frames
			frame_counter := 0
		end

feature -- Status report

	is_held: BOOLEAN
			-- Has a worker reached the gate (and maybe left it since)?
		do
			gate_mutex.lock
			Result := held
			gate_mutex.unlock
		end

	finished_count: INTEGER
			-- Workers that have ended
		do
			gate_mutex.lock
			Result := finished
			gate_mutex.unlock
		end

	generation: INTEGER
			-- Number of the latest scan
		do
			Result := scan_generation
		end

	running_worker_count: INTEGER
			-- Scan workers still running
		do
			forget_ended_workers
			Result := scan_workers.count
		end

	is_worker_join_timed_out: BOOLEAN
			-- Did the last `stop_background_work` leave a worker running?
		do
			Result := worker_join_timed_out
		end

	is_cancelled_now: BOOLEAN
			-- Is the latest scan cancelled?
		do
			Result := is_scan_cancelled
		end

feature -- Driving

	start_scan_now
			-- Start a scan as `r` does.
		do
			start_scan
		end

	process_now (a_event: EVENT)
			-- Process `a_event` as the example does.
		require
			event_attached: a_event /= Void
		do
			process (a_event)
		end

	render_now (a_frame: FRAME)
			-- Render the example into `a_frame`.
		require
			frame_attached: a_frame /= Void
		do
			render (a_frame)
		end

	stop_background_work_now
			-- Cancel the scans and join the workers, as `run` does when it ends.
		require
			not_running: not is_running
		do
			stop_background_work
		end

	taken_events: ARRAYED_LIST [EVENT]
			-- The events waiting in the queue, taken out of it in order
		local
			l_event: detachable EVENT
		do
			create Result.make (8)
			from
				l_event := event_queue.poll
			until
				l_event = Void
			loop
				Result.extend (l_event)
				l_event := event_queue.poll
			end
		end

feature {NONE} -- Worker

	new_scanner (a_root: STRING_32; a_excluded: ARRAYED_LIST [STRING_32]): DIRECTORY_SCANNER
			-- A LOCKED_DIRECTORY_SCANNER when `simulates_locked`
		do
			if simulates_locked then
				create {LOCKED_DIRECTORY_SCANNER} Result.make (a_root, a_excluded, Kept_count)
			else
				Result := Precursor (a_root, a_excluded)
			end
		end

	scan_worker_body (a_generation: INTEGER; a_root: STRING_32; a_excluded: ARRAYED_LIST [STRING_32])
			-- The example's worker, then record that it has ended.
		do
			Precursor (a_generation, a_root, a_excluded)
			gate_mutex.lock
			finished := finished + 1
			gate_mutex.unlock
		end

	at_scan_step (a_generation: INTEGER)
			-- Wait `step_delay_ms`, and at the gate if it is set for this step.
		local
			l_delay: INTEGER
		do
			gate_mutex.lock
			l_delay := step_delay_ms
			gate_mutex.unlock
			if l_delay > 0 then
				(create {EXECUTION_ENVIRONMENT}).sleep (l_delay.to_integer_64 * 1_000_000)
			end
			wait_at_gate (a_generation, Stage_step)
		end

	before_posting_result (a_generation: INTEGER)
			-- Wait at the gate if it is set for this step.
		do
			wait_at_gate (a_generation, Stage_result)
		end

	wait_at_gate (a_generation, a_stage: INTEGER)
			-- If the gate is set for `a_stage` of scan `a_generation` and not released yet,
			-- wait until `release`, at most `Gate_limit_ms`; unless the gate ignores cancels,
			-- also stop waiting once the scan is stale or cancelled.
		local
			l_waiting, l_ignores_cancel: BOOLEAN
			l_deadline: INTEGER_64
		do
			gate_mutex.lock
			l_waiting := gate_stage = a_stage and gate_generation = a_generation and not is_released
			l_ignores_cancel := gate_ignores_cancel
			if l_waiting then
				held := True
			end
			gate_mutex.unlock
			from
				l_deadline := {MONOTONIC_CLOCK}.milliseconds + Gate_limit_ms
			until
				not l_waiting
			loop
				(create {EXECUTION_ENVIRONMENT}).sleep (2_000_000)
				gate_mutex.lock
				l_waiting := not is_released
				gate_mutex.unlock
				if (not l_ignores_cancel and then not is_scan_wanted (a_generation))
					or {MONOTONIC_CLOCK}.milliseconds > l_deadline
				then
					l_waiting := False
				end
			end
		end

	set_gate (a_stage, a_generation: INTEGER; a_ignores_cancel: BOOLEAN)
			-- Hold the worker of scan `a_generation` at `a_stage`.
		do
			gate_mutex.lock
			gate_stage := a_stage
			gate_generation := a_generation
			gate_ignores_cancel := a_ignores_cancel
			held := False
			is_released := False
			gate_mutex.unlock
		end

	gate_mutex: MUTEX
			-- Guards the gate, `step_delay_ms` and `finished`

	gate_stage, gate_generation: INTEGER
			-- Where the gate is set (`gate_stage` 0: nowhere)

	gate_ignores_cancel: BOOLEAN
			-- Does the gate hold a cancelled or stale worker too?

	held, is_released: BOOLEAN
			-- Has a worker reached the gate? Has it been released?

	finished: INTEGER
			-- Storage of `finished_count`

	step_delay_ms: INTEGER
			-- Least time of each worker step

	Stage_step: INTEGER = 1
	Stage_result: INTEGER = 2
			-- Places of the gate

	Gate_limit_ms: INTEGER = 5000
			-- Longest wait at the gate

end
