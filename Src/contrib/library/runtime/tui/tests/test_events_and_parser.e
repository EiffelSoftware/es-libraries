note
	description: "[
		AutoTest suite for Layer 2: Key codes, Modifiers, ANSI Input Parser,
		and Synchronized Event Queue.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_EVENTS_AND_PARSER

inherit
	EQA_TEST_SET

feature -- Test routines

	test_modifiers
			-- Test bitwise modifier combinations.
		local
			l_mod: MODIFIERS
		do
			create l_mod.default_create
			assert ("empty", l_mod.is_empty)

			l_mod.set_control (True)
			assert ("has ctrl", l_mod.is_control)
			assert ("no shift", not l_mod.is_shift)

			l_mod.set_shift (True)
			assert ("has both", l_mod.is_control and l_mod.is_shift)

			l_mod.set_control (False)
			assert ("only shift", not l_mod.is_control and l_mod.is_shift)
		end

	test_key_code_definitions
			-- Test key code classification and equality.
		local
			l_k1, l_k2, l_k3, l_fn: KEY_CODE
		do
			create l_k1.make_char ('q')
			assert ("is char", l_k1.is_char)
			assert ("char is q", l_k1.character = 'q')

			l_k2 := {KEY_CODE}.up
			assert ("is up", l_k2.is_up)
			assert ("is special", l_k2.is_special)

			l_k3 := {KEY_CODE}.up
			assert ("equal", l_k2.is_equal (l_k3))

			create l_fn.make_function (5)
			assert ("is function", l_fn.is_function)
			assert ("is f5", l_fn.function_number = 5)
		end

	test_parser_ground_characters
			-- Test parsing standard characters, control characters, and Enter/Tab/Backspace.
		local
			l_parser: ANSI_INPUT_PARSER
		do
			create l_parser.make
			l_parser.parse_string ("A")
			assert ("1 event", l_parser.events.count = 1)
			if attached {KEY_EVENT} l_parser.events.first as ev then
				assert ("is A", ev.code.is_char and then ev.code.character = 'A')
			else
				assert ("expected key event", False)
			end

			-- Parse Enter, Tab, Backspace
			l_parser.wipe_out
			l_parser.parse_string ("%N%T%B")
			assert ("3 events", l_parser.events.count = 3)
			if attached {KEY_EVENT} l_parser.events.i_th (1) as ev1 then
				assert ("first is enter", ev1.code.is_enter)
			end
			if attached {KEY_EVENT} l_parser.events.i_th (2) as ev2 then
				assert ("second is tab", ev2.code.is_tab)
			end
			if attached {KEY_EVENT} l_parser.events.i_th (3) as ev3 then
				assert ("third is backspace", ev3.code.is_backspace)
			end

			-- Parse Ctrl+C (code 3)
			l_parser.wipe_out
			l_parser.parse_code (3)
			assert ("1 event for ctrl-c", l_parser.events.count = 1)
			if attached {KEY_EVENT} l_parser.events.first as ev_c then
				assert ("is c", ev_c.code.is_char and then ev_c.code.character = 'c')
				assert ("has ctrl", ev_c.modifiers.is_control)
			end
		end

	test_parser_csi_arrow_keys
			-- Test parsing ANSI CSI arrow key sequences.
		local
			l_parser: ANSI_INPUT_PARSER
		do
			create l_parser.make

			-- Up: \e[A
			l_parser.parse_string ("%/27/[A")
			assert ("up event", l_parser.events.count = 1)
			if attached {KEY_EVENT} l_parser.events.first as ev then
				assert ("is up", ev.code.is_up)
			end

			-- Down: \e[B
			l_parser.wipe_out
			l_parser.parse_string ("%/27/[B")
			assert ("down event", l_parser.events.count = 1)
			if attached {KEY_EVENT} l_parser.events.first as ev then
				assert ("is down", ev.code.is_down)
			end

			-- Right: \e[C
			l_parser.wipe_out
			l_parser.parse_string ("%/27/[C")
			if attached {KEY_EVENT} l_parser.events.first as ev then
				assert ("is right", ev.code.is_right)
			end

			-- Left: \e[D
			l_parser.wipe_out
			l_parser.parse_string ("%/27/[D")
			if attached {KEY_EVENT} l_parser.events.first as ev then
				assert ("is left", ev.code.is_left)
			end
		end

	test_parser_csi_modifiers
			-- Test parsing modified keys (e.g. \e[1;5C -> Ctrl+Right).
		local
			l_parser: ANSI_INPUT_PARSER
		do
			create l_parser.make
			l_parser.parse_string ("%/27/[1;5C")
			assert ("ctrl-right parsed", l_parser.events.count = 1)
			if attached {KEY_EVENT} l_parser.events.first as ev then
				assert ("is right", ev.code.is_right)
				assert ("has control", ev.modifiers.is_control)
				assert ("no shift", not ev.modifiers.is_shift)
			else
				assert ("expected key event", False)
			end
		end

	test_parser_sgr_mouse
			-- Test parsing SGR 1006 mouse press and release.
		local
			l_parser: ANSI_INPUT_PARSER
		do
			create l_parser.make
			-- Mouse click button 0 at column 25, row 10 (1-based ANSI: 26;11)
			l_parser.parse_string ("%/27/[<0;26;11M")
			assert ("mouse event parsed", l_parser.events.count = 1)
			if attached {MOUSE_EVENT} l_parser.events.first as ev then
				assert ("is press", ev.is_down)
				assert ("button is 0", ev.button = 0)
				assert ("col is 25", ev.column = 25)
				assert ("row is 10", ev.row = 10)
			else
				assert ("expected mouse event", False)
			end

			-- Mouse release: \e[<0;26;11m
			l_parser.wipe_out
			l_parser.parse_string ("%/27/[<0;26;11m")
			if attached {MOUSE_EVENT} l_parser.events.first as ev_up then
				assert ("is release", ev_up.is_up)
			end
		end

	test_synchronized_queue
			-- Test thread-safe FIFO queue operations.
		local
			l_queue: SYNCHRONIZED_EVENT_QUEUE
			l_e1, l_e2: KEY_EVENT
		do
			create l_queue.make
			assert ("initially empty", l_queue.is_empty)
			assert ("poll on empty returns void", l_queue.poll = Void)

			create l_e1.make_char ('1')
			create l_e2.make_char ('2')

			l_queue.push (l_e1)
			l_queue.push (l_e2)
			assert ("count is 2", l_queue.count = 2)

			if attached {KEY_EVENT} l_queue.poll as p1 then
				assert ("fifo item 1", p1.code.character = '1')
			else
				assert ("poll failed", False)
			end

			if attached {KEY_EVENT} l_queue.poll as p2 then
				assert ("fifo item 2", p2.code.character = '2')
			else
				assert ("poll failed", False)
			end

			assert ("empty after polling", l_queue.is_empty)
		end

end
