note
	description: "[
		Background worker thread reading raw input bytes from the terminal,
		detecting window resize, parsing escape sequences via ANSI_INPUT_PARSER,
		and depositing normalized EVENTs into a SYNCHRONIZED_EVENT_QUEUE.
		Uses Eiffel Threads (no SCOOP).

		Start it with `start`, not `launch`: `start` takes the driver's input claim, so no
		other reader (such as a DSR query) reads the console while the thread runs.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	EVENT_THREAD

inherit
	THREAD
		rename
			make as make_thread
		end

create
	make

feature {NONE} -- Initialization

	make (a_queue: SYNCHRONIZED_EVENT_QUEUE; a_driver: CONSOLE_DRIVER)
			-- Initialize event thread with target `a_queue` and console `a_driver`.
		require
			queue_attached: a_queue /= Void
			driver_attached: a_driver /= Void
		do
			make_thread
			queue := a_queue
			driver := a_driver
			create parser.make
			create stop_mutex.make
			create internal_failure_description.make_empty
			internal_should_stop := False
			poll_interval_ms := 25
		ensure
			queue_set: queue = a_queue
			driver_set: driver = a_driver
		end

feature -- Access

	queue: SYNCHRONIZED_EVENT_QUEUE
			-- Synchronized target queue for parsed events

	driver: CONSOLE_DRIVER
			-- OS console platform driver

feature -- Status report

	should_stop: BOOLEAN
			-- Has thread termination been requested?
		do
			stop_mutex.lock
			Result := internal_should_stop
			stop_mutex.unlock
		end

	poll_interval_ms: INTEGER
			-- Input poll timeout in milliseconds

feature -- Duplication

	renewed: EVENT_THREAD
			-- A new thread, not yet launched, with the same queue, driver and settings
			-- (poll interval, paste timeout, paste size). A THREAD object runs only once:
			-- use this to read input again after Current has terminated.
			-- Its parser starts empty: a sequence cut off by the end of Current is dropped.
		do
			create Result.make (queue, driver)
			Result.set_poll_interval (poll_interval_ms)
			Result.set_paste_timeout (parser.paste_timeout_ms)
			Result.set_max_paste_size (parser.max_paste_size)
		ensure
			fresh: Result /= Current and Result.is_launchable and not Result.should_stop
			same_queue: Result.queue = queue
			same_driver: Result.driver = driver
			same_poll_interval: Result.poll_interval_ms = poll_interval_ms
		end

feature -- Element change

	stop
			-- Signal the thread to stop executing its read loop.
		do
			stop_mutex.lock
			internal_should_stop := True
			stop_mutex.unlock
		ensure
			stopping: should_stop
		end

	set_poll_interval (a_ms: INTEGER)
			-- Set polling timeout in milliseconds.
		require
			positive_ms: a_ms > 0
		do
			poll_interval_ms := a_ms
		ensure
			interval_set: poll_interval_ms = a_ms
		end

	set_paste_timeout (a_ms: INTEGER)
			-- End a bracketed paste whose end marker has not arrived after `a_ms` milliseconds
			-- without input. Call before `launch`.
		require
			positive_ms: a_ms > 0
		do
			parser.set_paste_timeout (a_ms)
		ensure
			timeout_set: parser.paste_timeout_ms = a_ms
		end

	set_max_paste_size (a_size: INTEGER)
			-- Deliver a bracketed paste in parts of at most `a_size` characters
			-- (see {PASTE_EVENT}.is_continued). Call before `launch`.
		require
			positive_size: a_size > 0
		do
			parser.set_max_paste_size (a_size)
		ensure
			size_set: parser.max_paste_size = a_size
		end

feature -- Basic operations

	start
			-- Take the driver's `input_claim`, then launch the thread. The claim is released
			-- when `execute` ends, after `stop`, or after the thread gives up.
			-- Raise if another reader took the claim first.
		require
			launchable: is_launchable
			input_not_claimed: not driver.is_input_claimed
		local
			l_failure: DEVELOPER_EXCEPTION
		do
			if driver.input_claim.try_acquire then
				holds_input_claim := True
				launch
				if not is_last_launch_successful then
					holds_input_claim := False
					driver.input_claim.release
				end
			else
				create l_failure
				l_failure.set_description ("Console input is already being read by another reader")
				l_failure.raise
			end
		rescue
			-- `launch` raised: no thread will release the claim
			if holds_input_claim and not is_last_launch_successful then
				holds_input_claim := False
				driver.input_claim.release
			end
		end

feature -- Execution

	execute
			-- Continuous background loop reading console bytes, checking resize, and pushing events.
			-- An exception in one iteration is retried; after `Max_consecutive_failures`
			-- failures in a row the thread gives up and reports it through `has_failed`.
		local
			l_failures: INTEGER
			l_gave_up: BOOLEAN
		do
			if not l_gave_up then
				last_input_ms := {MONOTONIC_CLOCK}.milliseconds
				last_resize_poll_ms := last_input_ms - poll_interval_ms
				from
				until
					should_stop
				loop
					read_step
					l_failures := 0
				end
			end
			release_input_claim
		rescue
			-- The failing step may have stopped part-way through a sequence, or after pushing
			-- some of its events: start the next one from a clean parser
			parser.discard_pending
			l_failures := l_failures + 1
			if l_failures >= Max_consecutive_failures then
				record_failure
				l_gave_up := True
			end
			retry
		end

	Max_consecutive_failures: INTEGER = 10
			-- Consecutive failing iterations tolerated before the thread gives up

feature -- Status report (failure)

	has_failed: BOOLEAN
			-- Did the thread stop because input processing kept failing?
		do
			stop_mutex.lock
			Result := internal_has_failed
			stop_mutex.unlock
		end

	failure_description: STRING_32
			-- Description of the exception that made the thread give up (empty if none)
		local
			l_description: STRING_32
		do
			-- Copied outside the lock, so that nothing that can raise runs while it is held
			-- (`record_failure` replaces the string, it never changes it)
			stop_mutex.lock
			l_description := internal_failure_description
			stop_mutex.unlock
			Result := l_description.twin
		end

feature -- Measurement

	backlog_wait_count: INTEGER
			-- Number of read steps spent waiting because `queue` was full (written by the input
			-- thread: read it once the thread has ended)

feature {NONE} -- Implementation

	read_step
			-- One iteration: check for resize (at most once per `poll_interval_ms`, so a
			-- stream of input bytes does not cost a console-size query each), read one byte
			-- (or time out), push parsed events. While the queue `is_full`, wait one poll
			-- interval instead: the input stays in the console's buffer until there is room.
		do
			if queue.is_full then
				(create {EXECUTION_ENVIRONMENT}).sleep (poll_interval_ms.to_integer_64 * 1_000_000)
				-- Not idle input, only a wait: do not let it end a paste (`notify_idle`)
				last_input_ms := {MONOTONIC_CLOCK}.milliseconds
				backlog_wait_count := backlog_wait_count + 1
			else
				read_input
			end

			if driver.has_termination_request then
				-- Recorded by a Ctrl/signal handler: have the application loop see it now,
				-- not at its next tick (a close event gives it only a few seconds)
				queue.wake
			end
		end

	read_input
			-- Check for resize, read one byte (or time out), push the events it completes.
		local
			l_code: INTEGER
			l_new_w, l_new_h: INTEGER
			l_now: INTEGER_64
		do
			-- Check for window resize
			l_now := {MONOTONIC_CLOCK}.milliseconds
			if l_now - last_resize_poll_ms >= poll_interval_ms then
				last_resize_poll_ms := l_now
				if driver.poll_resize ($l_new_w, $l_new_h) and l_new_w > 0 and l_new_h > 0 then
					queue.push (create {RESIZE_EVENT}.make (l_new_w.to_natural_16, l_new_h.to_natural_16))
				end
			end

			-- Read next input byte; -1 means no input arrived within the poll interval
			l_code := driver.read_char_with_timeout (poll_interval_ms)
			if l_code >= 0 then
				last_input_ms := {MONOTONIC_CLOCK}.milliseconds
				parser.parse_code (l_code.to_natural_32)
			else
				-- Timeout elapsed without input: a pending lone ESC is the Escape key, and a
				-- paste whose end marker never came is ended after the parser's paste timeout
				parser.notify_idle (({MONOTONIC_CLOCK}.milliseconds - last_input_ms).max (0).min ({INTEGER}.max_value).to_integer_32)
			end
			across parser.events as e loop
				queue.push (e)
			end
			parser.wipe_out
		end

	release_input_claim
			-- Give back the driver's input claim if `start` took it for this thread.
		do
			if holds_input_claim then
				holds_input_claim := False
				driver.input_claim.release
			end
		end

	holds_input_claim: BOOLEAN
			-- Did `start` take the driver's input claim for this thread? Set on the thread
			-- calling `start` before the launch; cleared by the input thread when it ends.

	record_failure
			-- Remember the current exception and mark the thread as failed.
		local
			l_description: STRING_32
		do
			create l_description.make_from_string ("Input thread stopped after repeated failures")
			if attached {EXCEPTION_MANAGER}.last_exception as l_exception and then attached l_exception.description as l_text then
				l_description.append ({STRING_32} ": ")
				l_description.append (l_text)
			end
			stop_mutex.lock
			internal_has_failed := True
			internal_failure_description := l_description
			stop_mutex.unlock
		end

	internal_has_failed: BOOLEAN

	internal_failure_description: STRING_32
			-- Set in `make`, not on first use: it is read with `stop_mutex` held


	parser: ANSI_INPUT_PARSER
			-- Escape sequence parser instance

	last_input_ms: INTEGER_64
			-- {MONOTONIC_CLOCK} time at which the last input byte arrived (input thread only)

	last_resize_poll_ms: INTEGER_64
			-- {MONOTONIC_CLOCK} time of the last console-size query (input thread only)

	stop_mutex: MUTEX
			-- Mutex guarding thread stop flag

	internal_should_stop: BOOLEAN

end
