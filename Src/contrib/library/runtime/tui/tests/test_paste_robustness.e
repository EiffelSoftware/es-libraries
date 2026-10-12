note
	description: "[
		Bracketed paste robustness (review finding C1):
		- the paste end marker cut by an input timeout at every byte position
		- an ESC in the pasted text right before the end marker, from every parser state
		- the paste watchdog ending a paste whose end marker never arrives
		- a stray end marker outside a paste
		- EVENT_THREAD with a pause inside the end marker, and with a lost end marker
		Paste size (review finding M1):
		- a paste longer than `max_paste_size' delivered in parts that join back to the paste
		- each paste event owning its text (the parser collects the next paste in a new buffer)
		- EVENT_THREAD not querying the console size once per input byte

		Type checks are asserted, never guarded with `if attached', so a wrong event type fails.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_PASTE_ROBUSTNESS

inherit
	EQA_TEST_SET

feature -- Parser

	test_end_marker_split_by_timeout
			-- A timeout after any prefix of ESC[201~ keeps the paste open until the marker completes.
		local
			l_parser: ANSI_INPUT_PARSER
			l_marker: STRING_32
			k: INTEGER
		do
			l_marker := esc + "[201~"
			from
				k := 1
			until
				k >= l_marker.count
			loop
				create l_parser.make
				l_parser.parse_string (esc + "[200~hello")
				l_parser.parse_string (l_marker.substring (1, k))
				l_parser.flush_escape
				l_parser.notify_idle (25)
				assert ("still in paste after split at " + k.out, l_parser.is_in_paste)
				assert ("nothing emitted yet at " + k.out, l_parser.events.is_empty)
				l_parser.parse_string (l_marker.substring (k + 1, l_marker.count))
				l_parser.parse_string ("q")
				assert ("paste ended at " + k.out, not l_parser.is_in_paste)
				assert ("paste then key at " + k.out, l_parser.events.count = 2)
				assert ("paste text at " + k.out, attached {PASTE_EVENT} l_parser.events.first as p and then p.text.same_string ("hello"))
				assert ("q is a key at " + k.out, attached {KEY_EVENT} l_parser.events.i_th (2) as q and then (q.code.is_char and then q.code.character = 'q'))
				k := k + 1
			end
		end

	test_escape_before_end_marker
			-- Pasted text ending in ESC, ESC[, ESC[params, ESC O or ESC[<params keeps that text,
			-- and the ESC of the end marker still ends the paste.
		local
			l_tails: ARRAY [STRING_32]
			l_parser: ANSI_INPUT_PARSER
			l_tail: STRING_32
			i: INTEGER
		do
			l_tails := <<esc, esc + "[", esc + "[1;2", esc + "O", esc + "[<0;1", esc + "[<0;x">>
			from
				i := l_tails.lower
			until
				i > l_tails.upper
			loop
				l_tail := l_tails [i]
				create l_parser.make
				l_parser.parse_string (esc + "[200~a" + l_tail + esc + "[201~q")
				assert ("paste ended for tail " + i.out, not l_parser.is_in_paste)
				assert ("paste then key for tail " + i.out, l_parser.events.count = 2)
				assert ("tail kept verbatim " + i.out, attached {PASTE_EVENT} l_parser.events.first as p and then p.text.same_string ({STRING_32} "a" + l_tail))
				assert ("q is a key for tail " + i.out, attached {KEY_EVENT} l_parser.events.i_th (2) as q and then q.code.character = 'q')
				i := i + 1
			end
		end

	test_long_parameters_in_paste_kept
			-- Pasted text that looks like a CSI with more than 64 parameter characters is kept whole.
		local
			l_parser: ANSI_INPUT_PARSER
			l_digits: STRING_32
		do
			create l_digits.make_filled ('1', 100)
			create l_parser.make
			l_parser.parse_string (esc + "[200~" + esc + "[" + l_digits + "m" + esc + "[201~")
			assert ("paste ended", not l_parser.is_in_paste)
			assert ("one paste", l_parser.events.count = 1)
			assert ("text kept", attached {PASTE_EVENT} l_parser.events.first as p and then p.text.same_string (esc + "[" + l_digits + "m"))
		end

	test_paste_watchdog
			-- Without its end marker, a paste ends after `paste_timeout_ms` of silence, keeping its text.
		local
			l_parser: ANSI_INPUT_PARSER
		do
			create l_parser.make
			assert ("default timeout", l_parser.paste_timeout_ms = {ANSI_INPUT_PARSER}.Default_paste_timeout_ms)
			l_parser.set_paste_timeout (100)
			l_parser.parse_string (esc + "[200~abc" + esc + "[20")
			l_parser.notify_idle (99)
			assert ("short silence keeps the paste", l_parser.is_in_paste and l_parser.events.is_empty)
			l_parser.notify_idle (100)
			assert ("watchdog ended the paste", not l_parser.is_in_paste)
			assert ("one paste", l_parser.events.count = 1)
			assert ("collected text delivered", attached {PASTE_EVENT} l_parser.events.first as p and then p.text.same_string ("abc"))
			l_parser.wipe_out

			-- Keys work again, and the late end marker is ignored
			l_parser.parse_string ({STRING_32} "q" + esc + "[201~")
			assert ("only the key", l_parser.events.count = 1)
			assert ("q is a key", attached {KEY_EVENT} l_parser.events.first as q and then q.code.character = 'q')
		end

	test_flush_outside_paste_unchanged
			-- Outside a paste, a timeout still turns a lone ESC into the Escape key.
		local
			l_parser: ANSI_INPUT_PARSER
		do
			create l_parser.make
			l_parser.parse_code (27)
			l_parser.notify_idle (25)
			assert ("escape emitted", l_parser.events.count = 1)
			assert ("is escape", attached {KEY_EVENT} l_parser.events.first as k and then k.code.is_escape)
		end

feature -- Paste size

	test_paste_split_into_parts
			-- A paste longer than `max_paste_size` arrives in full parts marked continued, then a final part.
		local
			l_parser: ANSI_INPUT_PARSER
		do
			create l_parser.make
			assert ("default size", l_parser.max_paste_size = {ANSI_INPUT_PARSER}.Default_max_paste_size)
			l_parser.set_max_paste_size (4)
			l_parser.parse_string ({STRING_32} "" + esc + "[200~abcdefghij" + esc + "[201~")
			assert ("paste ended", not l_parser.is_in_paste)
			assert ("three parts", l_parser.events.count = 3)
			assert ("part 1", attached {PASTE_EVENT} l_parser.events.i_th (1) as p1 and then (p1.text.same_string ("abcd") and p1.is_continued))
			assert ("part 2", attached {PASTE_EVENT} l_parser.events.i_th (2) as p2 and then (p2.text.same_string ("efgh") and p2.is_continued))
			assert ("part 3", attached {PASTE_EVENT} l_parser.events.i_th (3) as p3 and then (p3.text.same_string ("ij") and not p3.is_continued))
		end

	test_paste_exact_multiple_ends_with_empty_part
			-- A paste of exactly `max_paste_size` characters is followed by an empty final part.
		local
			l_parser: ANSI_INPUT_PARSER
		do
			create l_parser.make
			l_parser.set_max_paste_size (5)
			l_parser.parse_string ({STRING_32} "" + esc + "[200~abcde" + esc + "[201~")
			assert ("two parts", l_parser.events.count = 2)
			assert ("full part", attached {PASTE_EVENT} l_parser.events.i_th (1) as p1 and then (p1.text.same_string ("abcde") and p1.is_continued))
			assert ("empty final", attached {PASTE_EVENT} l_parser.events.i_th (2) as p2 and then (p2.text.is_empty and not p2.is_continued))
		end

	test_paste_parts_keep_sequences
			-- Sequences kept as text are split across parts like other text; the parts join back verbatim.
		local
			l_parser: ANSI_INPUT_PARSER
			l_body, l_joined: STRING_32
			i: INTEGER
		do
			create l_parser.make
			l_parser.set_max_paste_size (3)
			l_body := {STRING_32} "x" + esc + "[A" + esc + "OPy" + esc + "[<0;1;2Mz" + esc + "[1;5C" + esc + esc + "[20"
			l_parser.parse_string ({STRING_32} "" + esc + "[200~" + l_body + esc + "[201~q")
			assert ("paste ended", not l_parser.is_in_paste)
			assert ("parts and key", l_parser.events.count >= 2)
			create l_joined.make_empty
			from
				i := 1
			until
				i >= l_parser.events.count
			loop
				assert ("paste part " + i.out, attached {PASTE_EVENT} l_parser.events.i_th (i) as p and then
					(p.text.count <= 3 and p.is_continued = (i < l_parser.events.count - 1)))
				if attached {PASTE_EVENT} l_parser.events.i_th (i) as p then
					l_joined.append (p.text)
				end
				i := i + 1
			end
			assert ("q is a key", attached {KEY_EVENT} l_parser.events.last as q and then q.code.character = 'q')
			assert ("joined text verbatim", l_joined.same_string (l_body))
		end

	test_paste_watchdog_delivers_parts
			-- The watchdog ends a split paste with a final part holding the rest.
		local
			l_parser: ANSI_INPUT_PARSER
		do
			create l_parser.make
			l_parser.set_max_paste_size (2)
			l_parser.set_paste_timeout (100)
			l_parser.parse_string ({STRING_32} "" + esc + "[200~abcde")
			assert ("two full parts so far", l_parser.events.count = 2)
			l_parser.notify_idle (100)
			assert ("paste ended", not l_parser.is_in_paste)
			assert ("three parts", l_parser.events.count = 3)
			assert ("final part", attached {PASTE_EVENT} l_parser.events.last as p and then (p.text.same_string ("e") and not p.is_continued))
		end

	test_paste_event_owns_its_text
			-- Collecting the next paste does not change the text of an earlier paste event.
		local
			l_parser: ANSI_INPUT_PARSER
			l_first: detachable PASTE_EVENT
		do
			create l_parser.make
			l_parser.parse_string ({STRING_32} "" + esc + "[200~first" + esc + "[201~")
			if attached {PASTE_EVENT} l_parser.events.first as p then
				l_first := p
			end
			assert ("first paste", attached l_first)
			l_parser.wipe_out
			l_parser.parse_string ({STRING_32} "" + esc + "[200~second paste")
			assert ("still in second paste", l_parser.is_in_paste)
			assert ("first text unchanged", attached l_first as f and then f.text.same_string ("first"))
		end

feature -- Input thread

	test_event_thread_resize_poll_not_per_byte
			-- A burst of input bytes is read without a console-size query per byte.
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_queue: SYNCHRONIZED_EVENT_QUEUE
			l_thread: EVENT_THREAD
			l_events: ARRAYED_LIST [EVENT]
			l_text: STRING_8
		do
			create l_text.make_filled ('x', 5000)
			create l_driver
			l_driver.script ("%/27/[200~" + l_text + "%/27/[201~")
			create l_queue.make
			create l_thread.make (l_queue, l_driver)
			l_thread.set_max_paste_size (1000)
			l_thread.launch
			-- About 1 s in a workbench build with all assertions on; the deadline only bounds a
			-- failure (collecting returns as soon as the six events are there)
			l_events := collect_events (l_queue, 6, 20000)
			l_thread.stop
			l_thread.join
			assert ("six parts", l_events.count = 6)
			assert ("last part final", attached {PASTE_EVENT} l_events.last as p and then (p.text.is_empty and not p.is_continued))
			assert ("all bytes read", l_driver.read_count >= 5012)
			assert ("few size queries", l_driver.resize_poll_count < 500)
		end

	test_event_thread_pause_inside_end_marker
			-- EVENT_THREAD times out (several polls) inside ESC[201~; the paste still ends and later keys arrive.
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_queue: SYNCHRONIZED_EVENT_QUEUE
			l_thread: EVENT_THREAD
			l_events: ARRAYED_LIST [EVENT]
		do
			create l_driver
			l_driver.script ("%/27/[200~hello%/27/[20")
			create l_queue.make
			create l_thread.make (l_queue, l_driver)
			l_thread.set_poll_interval (5)
			l_thread.launch
			sleep_ms (100)
			l_driver.script ("1~q")
			l_events := collect_events (l_queue, 2, 3000)
			l_thread.stop
			l_thread.join
			assert ("two events", l_events.count = 2)
			assert ("paste", attached {PASTE_EVENT} l_events.first as p and then p.text.same_string ("hello"))
			assert ("then q", attached {KEY_EVENT} l_events.i_th (2) as q and then q.code.character = 'q')
		end

	test_event_thread_lost_end_marker
			-- EVENT_THREAD ends a paste whose end marker never arrives; keys typed afterwards arrive.
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_queue: SYNCHRONIZED_EVENT_QUEUE
			l_thread: EVENT_THREAD
			l_events: ARRAYED_LIST [EVENT]
		do
			create l_driver
			l_driver.script ("%/27/[200~lost")
			create l_queue.make
			create l_thread.make (l_queue, l_driver)
			l_thread.set_poll_interval (5)
			l_thread.set_paste_timeout (50)
			l_thread.launch
			l_events := collect_events (l_queue, 1, 3000)
			l_driver.script ("q")
			l_events.append (collect_events (l_queue, 1, 3000))
			l_thread.stop
			l_thread.join
			assert ("two events", l_events.count = 2)
			assert ("paste delivered", attached {PASTE_EVENT} l_events.first as p and then p.text.same_string ("lost"))
			assert ("then q", attached {KEY_EVENT} l_events.i_th (2) as q and then q.code.character = 'q')
		end

feature {NONE} -- Helpers

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

	sleep_ms (a_ms: INTEGER)
			-- Suspend the calling thread for `a_ms` milliseconds.
		do
			(create {EXECUTION_ENVIRONMENT}).sleep (a_ms.to_integer_64 * 1_000_000)
		end

end
