note
	description: "[
		Event floods (review finding M5):
		- the queue merges consecutive drag, move and resize events into the newest
		- `is_full' and the input thread waiting while the queue is full, without losing input
		The application's redraw budget is tested in TEST_MILESTONE_C.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_EVENT_FLOOD

inherit
	EQA_TEST_SET

feature -- Queue

	test_drag_and_resize_coalesced
			-- Runs of drags and resizes give their newest event; anything else breaks a run.
		local
			l_queue: SYNCHRONIZED_EVENT_QUEUE
		do
			create l_queue.make
			assert ("on by default", l_queue.is_coalescing)
			l_queue.push (drag (0, 1))
			l_queue.push (drag (0, 2))
			l_queue.push (drag (0, 3))
			l_queue.push (drag (2, 4)) -- other button
			l_queue.push (create {KEY_EVENT}.make_char ('k'))
			l_queue.push (drag (2, 5))
			l_queue.push (create {RESIZE_EVENT}.make (80, 24))
			l_queue.push (create {RESIZE_EVENT}.make (100, 30))
			assert ("newest drag", attached {MOUSE_EVENT} l_queue.poll as m and then (m.column = 3 and m.button = 0))
			assert ("other button kept", attached {MOUSE_EVENT} l_queue.poll as m2 and then m2.column = 4)
			assert ("key kept", attached {KEY_EVENT} l_queue.poll)
			assert ("drag after the key", attached {MOUSE_EVENT} l_queue.poll as m3 and then m3.column = 5)
			assert ("newest size", attached {RESIZE_EVENT} l_queue.poll_with_timeout (10) as r and then (r.width = 100 and r.height = 30))
			assert ("empty", l_queue.is_empty)
			assert ("three dropped", l_queue.coalesced_count = 3)
		end

	test_clicks_and_moves_not_merged
			-- Presses and scrolls are never merged; a move does not merge into a drag.
		local
			l_queue: SYNCHRONIZED_EVENT_QUEUE
		do
			create l_queue.make
			l_queue.push (mouse ({MOUSE_EVENT}.kind_down, 1))
			l_queue.push (mouse ({MOUSE_EVENT}.kind_down, 2))
			l_queue.push (mouse ({MOUSE_EVENT}.kind_scroll_up, 3))
			l_queue.push (mouse ({MOUSE_EVENT}.kind_scroll_up, 4))
			l_queue.push (mouse ({MOUSE_EVENT}.kind_drag, 5))
			l_queue.push (mouse ({MOUSE_EVENT}.kind_move, 6))
			l_queue.push (mouse ({MOUSE_EVENT}.kind_move, 7))
			assert ("7 pushed", l_queue.count = 7)
			assert ("down 1", attached {MOUSE_EVENT} l_queue.poll as e1 and then e1.column = 1)
			assert ("down 2", attached {MOUSE_EVENT} l_queue.poll as e2 and then e2.column = 2)
			assert ("scroll 3", attached {MOUSE_EVENT} l_queue.poll as e3 and then e3.column = 3)
			assert ("scroll 4", attached {MOUSE_EVENT} l_queue.poll as e4 and then e4.column = 4)
			assert ("drag 5", attached {MOUSE_EVENT} l_queue.poll as e5 and then e5.column = 5)
			assert ("newest move", attached {MOUSE_EVENT} l_queue.poll as e7 and then e7.column = 7)
			assert ("one dropped", l_queue.coalesced_count = 1)
		end

	test_coalescing_off
			-- With coalescing off, every drag is delivered.
		local
			l_queue: SYNCHRONIZED_EVENT_QUEUE
			i: INTEGER
		do
			create l_queue.make
			l_queue.set_coalescing (False)
			from
				i := 1
			until
				i > 3
			loop
				l_queue.push (drag (0, i))
				i := i + 1
			end
			from
				i := 1
			until
				i > 3
			loop
				assert ("drag " + i.out, attached {MOUSE_EVENT} l_queue.poll as m and then m.column = i)
				i := i + 1
			end
			assert ("none dropped", l_queue.coalesced_count = 0)
		end

	test_queue_full
			-- `is_full` from `max_count` waiting events on; pushing still works.
		local
			l_queue: SYNCHRONIZED_EVENT_QUEUE
		do
			create l_queue.make
			assert ("default bound", l_queue.max_count = {SYNCHRONIZED_EVENT_QUEUE}.Default_max_count)
			l_queue.set_max_count (2)
			l_queue.push (create {KEY_EVENT}.make_char ('a'))
			assert ("not full", not l_queue.is_full)
			l_queue.push (create {KEY_EVENT}.make_char ('b'))
			assert ("full", l_queue.is_full)
			l_queue.push (create {KEY_EVENT}.make_char ('c'))
			assert ("still accepted", l_queue.count = 3)
			assert ("first", attached l_queue.poll)
			assert ("second", attached l_queue.poll)
			assert ("room again", not l_queue.is_full)
		end

feature -- Input thread

	test_input_thread_waits_while_full
			-- With room for 2 events, the input thread stops reading until the consumer catches
			-- up; every key still arrives, in order.
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_queue: SYNCHRONIZED_EVENT_QUEUE
			l_thread: EVENT_THREAD
			l_keys: STRING_32
			l_max_seen: INTEGER
			l_deadline: INTEGER_64
		do
			create l_driver
			l_driver.script ("abcdefgh")
			create l_queue.make
			l_queue.set_max_count (2)
			create l_thread.make (l_queue, l_driver)
			l_thread.set_poll_interval (5)
			l_thread.launch
			-- Let the thread fill the queue, then drain slowly
			sleep_ms (100)
			l_max_seen := l_queue.count
			create l_keys.make (8)
			from
				l_deadline := {MONOTONIC_CLOCK}.milliseconds + 5000
			until
				l_keys.count >= 8 or {MONOTONIC_CLOCK}.milliseconds > l_deadline
			loop
				l_max_seen := l_max_seen.max (l_queue.count)
				if attached {KEY_EVENT} l_queue.poll_with_timeout (20) as k then
					l_keys.append_character (k.code.character)
				end
				sleep_ms (10)
			end
			l_thread.stop
			l_thread.join
			assert ("all keys in order", l_keys.same_string ("abcdefgh"))
			assert ("bounded", l_max_seen <= 2)
			assert ("waited", l_thread.backlog_wait_count > 0)
		end

feature {NONE} -- Helpers

	drag (a_button: NATURAL_8; a_col: INTEGER): MOUSE_EVENT
			-- Drag with `a_button` at column and row `a_col`, no modifiers
		do
			create Result.make ({MOUSE_EVENT}.kind_drag, a_button, a_col.to_natural_16, a_col.to_natural_16, create {MODIFIERS})
		end

	mouse (a_kind: NATURAL_8; a_col: INTEGER): MOUSE_EVENT
			-- Left-button mouse event of `a_kind` at column `a_col`, row 0
		do
			create Result.make (a_kind, 0, a_col.to_natural_16, 0, create {MODIFIERS})
		end

	sleep_ms (a_ms: INTEGER)
			-- Suspend the calling thread for `a_ms` milliseconds.
		do
			(create {EXECUTION_ENVIRONMENT}).sleep (a_ms.to_integer_64 * 1_000_000)
		end

end
