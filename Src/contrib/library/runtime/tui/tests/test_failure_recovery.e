note
	description: "[
		Failure and retry paths (review finding C6):
		- an SGR mouse report with a coordinate above 65535 gives a clamped event, not an exception
		- `discard_pending' returns the parser to a clean state and keeps a paste going
		- EVENT_THREAD starts the iteration after a failure from a clean parser
		- a push that fails while holding the queue lock releases it

		Type checks are asserted, never guarded with `if attached', so a wrong event type fails.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_FAILURE_RECOVERY

inherit
	EQA_TEST_SET

feature -- Parser

	test_sgr_mouse_large_coordinates_clamped
			-- Coordinates above 65535 are clamped (they used to fail `to_natural_16` before the
			-- parser returned to the ground state); a number too big for an INTEGER is no report.
		local
			l_parser: ANSI_INPUT_PARSER
		do
			create l_parser.make
			l_parser.parse_string (esc + "[<0;70000;99999999M")
			assert ("one event", l_parser.events.count = 1)
			assert ("clamped", attached {MOUSE_EVENT} l_parser.events.first as m and then
				(m.column = 65535 and m.row = 65535 and m.kind = {MOUSE_EVENT}.kind_down))
			assert ("between sequences", l_parser.is_between_sequences)
			l_parser.wipe_out

			l_parser.parse_string (esc + "[<0;99999999999;1M")
			assert ("no event", l_parser.events.is_empty)
			assert ("still between sequences", l_parser.is_between_sequences)
			l_parser.parse_string ("x")
			assert ("keys work", l_parser.events.count = 1 and then attached {KEY_EVENT} l_parser.events.first as k and then k.code.character = 'x')
		end

	test_discard_pending
			-- `discard_pending` drops a half-read sequence and the collected events; a paste goes on.
		local
			l_parser: ANSI_INPUT_PARSER
		do
			create l_parser.make
			l_parser.parse_string ({STRING_32} "a" + esc + "[<0;5")
			assert ("mid-sequence", not l_parser.is_between_sequences and l_parser.events.count = 1)
			l_parser.discard_pending
			assert ("clean", l_parser.is_between_sequences and l_parser.events.is_empty)
			l_parser.parse_string ("x")
			assert ("x is a key", l_parser.events.count = 1 and then attached {KEY_EVENT} l_parser.events.first as k and then k.code.character = 'x')
			l_parser.wipe_out

			-- A partial UTF-8 character is dropped too
			l_parser.parse_code (0xE2)
			assert ("mid-character", not l_parser.is_between_sequences)
			l_parser.discard_pending
			l_parser.parse_string ("y")
			assert ("y, no U+FFFD", l_parser.events.count = 1 and then attached {KEY_EVENT} l_parser.events.first as k2 and then k2.code.character = 'y')
			l_parser.wipe_out

			l_parser.parse_string (esc + "[200~ab" + esc + "[")
			l_parser.discard_pending
			assert ("paste goes on", l_parser.is_in_paste)
			l_parser.parse_string (esc + "[201~")
			assert ("paste text kept", l_parser.events.count = 1 and then attached {PASTE_EVENT} l_parser.events.first as p and then p.text.same_string ("ab"))
		end

feature -- Input thread

	test_event_thread_retry_starts_clean
			-- An iteration that fails in the middle of a mouse report does not leave the parser
			-- inside it: the next bytes are read as keys (they used to be taken as parameters).
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_queue: SYNCHRONIZED_EVENT_QUEUE
			l_thread: EVENT_THREAD
			l_events: ARRAYED_LIST [EVENT]
		do
			create l_driver
			-- Reads 1..6 give ESC [ < 0 ; 5, read 7 raises, then x and q
			l_driver.script ("%/27/[<0;5xq")
			l_driver.set_failing_read (7)
			create l_queue.make
			create l_thread.make (l_queue, l_driver)
			l_thread.set_poll_interval (5)
			l_thread.launch
			l_events := collect_events (l_queue, 2, 3000)
			l_thread.stop
			l_thread.join
			assert ("not given up", not l_thread.has_failed)
			assert ("two keys", l_events.count = 2)
			assert ("x", attached {KEY_EVENT} l_events.first as x and then x.code.character = 'x')
			assert ("q", attached {KEY_EVENT} l_events.i_th (2) as q and then q.code.character = 'q')
		end

	test_event_thread_large_mouse_coordinate
			-- The review's example through the input thread: no failure, a clamped event, then keys.
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_queue: SYNCHRONIZED_EVENT_QUEUE
			l_thread: EVENT_THREAD
			l_events: ARRAYED_LIST [EVENT]
		do
			create l_driver
			l_driver.script ("%/27/[<0;70000;1Mq")
			create l_queue.make
			create l_thread.make (l_queue, l_driver)
			l_thread.set_poll_interval (5)
			l_thread.launch
			l_events := collect_events (l_queue, 2, 3000)
			l_thread.stop
			l_thread.join
			assert ("not given up", not l_thread.has_failed)
			assert ("two events", l_events.count = 2)
			assert ("clamped mouse", attached {MOUSE_EVENT} l_events.first as m and then (m.column = 65535 and m.row = 0))
			assert ("q", attached {KEY_EVENT} l_events.i_th (2) as q and then q.code.character = 'q')
		end

feature -- Queue

	test_failed_push_releases_lock
			-- A push that raises while holding the lock releases it: another thread can still push,
			-- and the consumer receives that event (it used to block forever).
		local
			l_queue: FAILING_EVENT_QUEUE
			l_pusher: WORKER_THREAD
		do
			create l_queue.make
			l_queue.fail_next_push
			push_expecting_failure (l_queue)
			assert ("nothing queued", l_queue.is_empty)

			create l_pusher.make (agent (q: SYNCHRONIZED_EVENT_QUEUE)
				do
					q.push (create {TICK_EVENT}.default_create)
				end (l_queue))
			l_pusher.launch
			assert ("pushed from another thread", attached l_queue.poll_with_timeout (3000) as e and then e.is_tick)
			assert ("pusher finished", l_pusher.join_with_timeout (3000))
		end

feature {NONE} -- Helpers

	push_expecting_failure (a_queue: FAILING_EVENT_QUEUE)
			-- Push onto `a_queue` and check that it raised.
		local
			l_raised: BOOLEAN
		do
			if not l_raised then
				a_queue.push (create {TICK_EVENT}.default_create)
			end
			assert ("push raised", l_raised)
		rescue
			l_raised := True
			retry
		end

	esc: STRING_32
			-- A fresh one-character string holding ESC
		do
			create Result.make_filled ((27).to_character_32, 1)
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
