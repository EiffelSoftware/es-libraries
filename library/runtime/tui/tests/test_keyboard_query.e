note
	description: "[
		P2 T4, keyboard support query: the parser's KEYBOARD_FLAGS_EVENT and
		DEVICE_ATTRIBUTES_EVENT, {ANSI_TERMINAL_BACKEND}.query_keyboard_enhancement on a
		fake console (reply orders, no reply, keys before the replies, the input claim), and
		TUI_APPLICATION asking once per run, only when `set_keyboard_enhancement_if_supported`
		is on, never on a resume.
		The sequences are checked against crossterm's documentation, not its source (which is
		not in this repository): `supports_keyboard_enhancement` writes `ESC [ ? u` (Kitty:
		query the flags) followed by `ESC [ c` (primary device attributes, DA1) and waits up
		to 2 seconds; a reply `ESC [ ? flags u` before the DA1 reply `ESC [ ? ... c` means
		the terminal speaks the protocol, the DA1 reply alone that it does not. The reply
		formats are those of the Kitty keyboard protocol specification (progressive
		enhancement) and of DEC / xterm DA1.
		Before T4 the parser dropped both replies with no event and went on parsing (checked
		on the old code, 2026-10-27: `ESC [ ? 1 u`, `ESC [ ? 31 u`, `ESC [ ? 62 ; 22 c` and
		`ESC [ ? 1 ; 0 c` gave no event, and a key after them was still a key).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_KEYBOARD_QUERY

inherit
	EQA_TEST_SET

feature -- Parser

	test_parser_flags_reply
			-- `CSI ? flags u` is a KEYBOARD_FLAGS_EVENT, not a key. A flags field that is not
			-- one number 0 .. 255 gives no event, as before T4.
		local
			l_parser: ANSI_INPUT_PARSER
		do
			create l_parser.make
			l_parser.parse_string (Csi + "?1u")
			assert ("flags 1", one_flags (l_parser, 1))
			l_parser.wipe_out
			l_parser.parse_string (Csi + "?0u")
			assert ("flags 0", one_flags (l_parser, 0))
			l_parser.wipe_out
			l_parser.parse_string (Csi + "?31u")
			assert ("flags 31", one_flags (l_parser, 31))
			assert ("not a key", not l_parser.events.first.is_key and l_parser.events.first.is_keyboard_flags)
			l_parser.wipe_out
			l_parser.parse_string (Csi + "?256u" + Csi + "?u" + Csi + "?1;2u" + Csi + "?1:2u")
			assert ("malformed replies dropped", l_parser.events.is_empty)
			l_parser.parse_string ("x")
			assert ("still parsing keys", l_parser.events.count = 1 and l_parser.events.first.is_key)
		end

	test_parser_device_attributes
			-- DA1 `CSI ? ... c` is a DEVICE_ATTRIBUTES_EVENT with its numbers; an empty or
			-- non-numeric part counts as 0. `CSI c` without '?' is still nothing.
		local
			l_parser: ANSI_INPUT_PARSER
		do
			create l_parser.make
			l_parser.parse_string (Csi + "?62;22c")
			assert ("xterm-like", one_attributes (l_parser, <<62, 22>>))
			assert ("not a key", not l_parser.events.first.is_key and l_parser.events.first.is_device_attributes)
			l_parser.wipe_out
			l_parser.parse_string (Csi + "?1;0c")
			assert ("conhost-like", one_attributes (l_parser, <<1, 0>>))
			l_parser.wipe_out
			l_parser.parse_string (Csi + "?6c")
			assert ("vt102", one_attributes (l_parser, <<6>>))
			l_parser.wipe_out
			l_parser.parse_string (Csi + "?c")
			assert ("no numbers", one_attributes (l_parser, {ARRAY [INTEGER]} <<>>))
			l_parser.wipe_out
			l_parser.parse_string (Csi + "?62;;4:1c")
			assert ("empty and odd parts are 0", one_attributes (l_parser, <<62, 0, 0>>))
			l_parser.wipe_out
			l_parser.parse_string (Csi + "c")
			assert ("no private marker: nothing", l_parser.events.is_empty)
		end

	test_parser_replies_split_and_among_keys
			-- The replies split over several reads, with keys around them; inside a
			-- bracketed paste they are pasted text.
		local
			l_parser: ANSI_INPUT_PARSER
			l_all: STRING_32
			i: INTEGER
		do
			create l_parser.make
			l_all := {STRING_32} "a" + Csi + "?3u" + Csi + "?62;22c" + {STRING_32} "b"
			from i := 1 until i > l_all.count loop
				l_parser.parse_code (l_all.code (i))
				i := i + 1
			end
			assert ("four events", l_parser.events.count = 4)
			assert ("key a", attached {KEY_EVENT} l_parser.events.i_th (1) as k and then k.code.is_char and then k.code.character = 'a')
			assert ("flags 3", attached {KEYBOARD_FLAGS_EVENT} l_parser.events.i_th (2) as f and then f.flags = 3)
			assert ("da1", attached {DEVICE_ATTRIBUTES_EVENT} l_parser.events.i_th (3) as d and then d.parameters.count = 2)
			assert ("key b", attached {KEY_EVENT} l_parser.events.i_th (4) as k and then k.code.is_char and then k.code.character = 'b')
			l_parser.wipe_out
			l_parser.parse_string (Csi + "?")
			l_parser.parse_string ("1")
			assert ("nothing before the final byte", l_parser.events.is_empty)
			l_parser.parse_string ("5u")
			assert ("flags 15 over three reads", one_flags (l_parser, 15))
			l_parser.wipe_out
			l_parser.parse_string (Csi + "200~" + Csi + "?1u" + Csi + "?62c" + Csi + "201~")
			assert ("pasted text", l_parser.events.count = 1 and then attached {PASTE_EVENT} l_parser.events.first as p
				and then p.text.same_string (Csi + "?1u" + Csi + "?62c"))
		end

feature -- Backend

	test_query_writes_both_queries
			-- Byte-exact: `ESC [ ? u` then `ESC [ c`, flushed before reading.
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_sink: STRING_32
			l_backend: ANSI_TERMINAL_BACKEND
		do
			l_driver := new_driver (Csi_8 + "?1u" + Csi_8 + "?62;22c")
			create l_sink.make_empty
			create l_backend.make_with_driver_and_sink (l_driver, l_sink)
			assert ("supported", attached l_backend.query_keyboard_enhancement as r and then r.flags = 1)
			assert ("bytes [" + l_sink.to_string_8 + "]", l_sink.same_string_general ("%/27/[?u%/27/[c"))
		end

	test_query_flags_then_da1_is_supported
			-- The flags reply before DA1: the flags. The DA1 reply is read too, so that it
			-- does not reach the next reader; the input after it does.
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_backend: ANSI_TERMINAL_BACKEND
		do
			l_driver := new_driver (Csi_8 + "?3u" + Csi_8 + "?62;22c" + "z")
			l_backend := new_backend (l_driver)
			assert ("flags 3", attached l_backend.query_keyboard_enhancement as r and then r.flags = 3)
			assert ("answered", l_backend.is_keyboard_query_answered)
			assert ("claim released", not l_backend.is_input_in_use)
			assert ("the key after the replies is left", l_driver.read_char_with_timeout (0) = ('z').code)
			assert ("nothing more", l_driver.read_char_with_timeout (0) = -1)
		end

	test_query_da1_alone_is_unsupported
			-- Only the DA1 reply: Void, but answered (the terminal lacks the protocol).
			-- A flags reply after DA1 is not taken.
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_backend: ANSI_TERMINAL_BACKEND
		do
			l_driver := new_driver (Csi_8 + "?1;0c")
			l_backend := new_backend (l_driver)
			assert ("void", l_backend.query_keyboard_enhancement = Void)
			assert ("answered", l_backend.is_keyboard_query_answered)
			l_driver.script (Csi_8 + "?62c" + Csi_8 + "?1u")
			assert ("flags after DA1 not taken", l_backend.query_keyboard_enhancement = Void and l_backend.is_keyboard_query_answered)
			assert ("left for the next reader", l_driver.read_char_with_timeout (0) = 27)
			assert ("claim released", not l_backend.is_input_in_use)
		end

	test_query_no_reply_is_unknown
			-- No reply at all: Void and not answered, after the attempts (2 seconds of
			-- silence); the claim is released.
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_backend: ANSI_TERMINAL_BACKEND
		do
			l_driver := new_driver ("")
			l_backend := new_backend (l_driver)
			assert ("void", l_backend.query_keyboard_enhancement = Void)
			assert ("not answered", not l_backend.is_keyboard_query_answered)
			assert ("80 silent polls", l_driver.read_count = 80)
			assert ("claim released", not l_backend.is_input_in_use)
		end

	test_query_flags_without_da1
			-- A flags reply and then silence (no DA1): the flags, after the attempts.
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_backend: ANSI_TERMINAL_BACKEND
		do
			l_driver := new_driver (Csi_8 + "?1u")
			l_backend := new_backend (l_driver)
			assert ("flags 1", attached l_backend.query_keyboard_enhancement as r and then r.flags = 1)
			assert ("answered", l_backend.is_keyboard_query_answered)
		end

	test_query_keeps_keys_before_replies
			-- Keys typed before the replies are not lost (review, minor): they are kept in
			-- order in `keyboard_query_other_events`, a cursor report among them too, and
			-- none of the replies is.
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_backend: ANSI_TERMINAL_BACKEND
			l_events: ARRAYED_LIST [EVENT]
		do
			l_driver := new_driver ("ab" + Csi_8 + "A" + Csi_8 + "5;1R" + Csi_8 + "?1u" + Csi_8 + "?62c")
			l_backend := new_backend (l_driver)
			assert ("flags 1", attached l_backend.query_keyboard_enhancement as r and then r.flags = 1)
			assert ("fenced", l_backend.is_keyboard_query_fenced)
			assert ("all read", l_driver.read_char_with_timeout (0) = -1)
			l_events := l_backend.keyboard_query_other_events
			assert ("four kept", l_events.count = 4)
			assert ("a", attached {KEY_EVENT} l_events [1] as k and then (k.code.is_char and then k.code.character = 'a'))
			assert ("b", attached {KEY_EVENT} l_events [2] as k and then (k.code.is_char and then k.code.character = 'b'))
			assert ("up", attached {KEY_EVENT} l_events [3] as k and then k.code.is_up)
			assert ("cursor report", attached {CURSOR_POSITION_EVENT} l_events [4])
		end

	test_query_keeps_lone_escape
			-- An Esc key typed on its own while the query reads waits in its parser for a
			-- sequence; it is delivered when the query ends, after a key before it. Not
			-- fenced: no DA1 reply came.
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_backend: ANSI_TERMINAL_BACKEND
			l_events: ARRAYED_LIST [EVENT]
		do
			l_driver := new_driver ("x%/27/")
			l_backend := new_backend (l_driver)
			assert ("void", l_backend.query_keyboard_enhancement = Void)
			assert ("not fenced", not l_backend.is_keyboard_query_fenced and not l_backend.is_keyboard_query_answered)
			l_events := l_backend.keyboard_query_other_events
			assert ("two kept", l_events.count = 2)
			assert ("x", attached {KEY_EVENT} l_events [1] as k and then (k.code.is_char and then k.code.character = 'x'))
			assert ("esc", attached {KEY_EVENT} l_events [2] as k and then k.code.is_escape)
		end

	test_query_refused_while_input_in_use
			-- While another reader holds the console's input claim, the query is refused by
			-- its precondition and writes nothing.
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_sink: STRING_32
			l_backend: ANSI_TERMINAL_BACKEND
		do
			l_driver := new_driver (Csi_8 + "?1u" + Csi_8 + "?62c")
			create l_sink.make_empty
			create l_backend.make_with_driver_and_sink (l_driver, l_sink)
			assert ("taken", l_driver.input_claim.try_acquire)
			assert ("refused", precondition_raised (agent (b: ANSI_TERMINAL_BACKEND) do if attached b.query_keyboard_enhancement then end end (l_backend), "input_not_in_use"))
			assert ("nothing written", l_sink.is_empty)
			assert ("nothing read", l_driver.read_count = 0)
			l_driver.input_claim.release
		end

feature -- Application

	test_app_asks_once_and_pushes_when_supported
			-- `set_keyboard_enhancement_if_supported`: asked once, in the setup and before
			-- the input thread; supported, so the flags are pushed after the answer, at the
			-- same point of the setup as on a resume (before `?25l`), and popped on exit. A
			-- key typed before the replies is not lost: it reaches `process` before the key
			-- after them. A second run asks again.
		local
			l_app: TEST_TUI_APP_IMPL
			l_sink: STRING_32
		do
			l_app := new_app ("x" + Csi_8 + "?0u" + Csi_8 + "?62;22c" + "q", create {VIEWPORT}.make_fullscreen)
			l_sink := sink_of (l_app)
			l_app.set_keyboard_enhancement_if_supported (True)
			assert ("unknown before the run", l_app.keyboard_enhancement_support = l_app.Keyboard_enhancement_unknown)
			l_app.run
			assert ("supported", l_app.is_keyboard_enhancement_supported)
			assert ("asked once", occurrences (l_sink, Csi + "?u") = 1 and occurrences (l_sink, Csi + "c") = 1)
			assert ("setup, query, push", l_sink.has_substring (Csi + "?1049h" + Csi + "2J" + Csi + "H" + Csi + "?u" + Csi + "c" + Csi + ">3u" + Csi + "?25l"))
			assert ("popped before leaving the screen", l_sink.has_substring (Csi + "<u") and then
				l_sink.substring_index (Csi + "<u", 1) < l_sink.substring_index (Csi + "?1049l", 1))
			assert ("the key before the replies kept", l_app.key_count = 2)
			assert ("no reply processed", l_app.reply_count = 0)
			driver_of (l_app).script (Csi_8 + "?0u" + Csi_8 + "?62;22c" + "q")
			l_app.run
			assert ("asked once per run", occurrences (l_sink, Csi + "?u") = 2)
			assert ("pushed per run", occurrences (l_sink, Csi + ">3u") = 2)
		end

	test_app_unsupported_does_not_push
			-- The DA1 reply alone: unsupported, nothing pushed or popped.
		local
			l_app: TEST_TUI_APP_IMPL
			l_sink: STRING_32
		do
			l_app := new_app (Csi_8 + "?62;22c" + "q", create {VIEWPORT}.make_fullscreen)
			l_sink := sink_of (l_app)
			l_app.set_keyboard_enhancement_if_supported (True)
			l_app.run
			assert ("unsupported", l_app.keyboard_enhancement_support = l_app.Keyboard_enhancement_unsupported)
			assert ("asked", occurrences (l_sink, Csi + "?u") = 1)
			assert ("not pushed", not l_sink.has_substring (Csi + ">3u") and not l_sink.has_substring (Csi + "<u"))
			assert ("key processed", l_app.key_count = 1)
		end

	test_app_no_reply_is_unknown
			-- No reply: unknown, nothing pushed; the application runs on.
		local
			l_app: TEST_TUI_APP_IMPL
			l_sink: STRING_32
		do
			l_app := new_app ("", create {VIEWPORT}.make_fullscreen)
			l_sink := sink_of (l_app)
			l_app.set_keyboard_enhancement_if_supported (True)
			l_app.set_draw_hook (agent (f: FRAME; a: TEST_TUI_APP_IMPL) do a.stop end (?, l_app))
			l_app.run
			assert ("unknown", l_app.keyboard_enhancement_support = l_app.Keyboard_enhancement_unknown)
			assert ("not pushed", not l_sink.has_substring (Csi + ">3u"))
			assert ("frame drawn", l_sink.has_substring ("frame"))
		end

	test_app_not_requested_asks_nothing
			-- Without `set_keyboard_enhancement_if_supported` nothing is asked: no query, no
			-- read before the input thread (the first key is processed), and the same bytes as
			-- before T4. `set_keyboard_enhancement (True)` alone pushes without asking.
		local
			l_app: TEST_TUI_APP_IMPL
			l_sink: STRING_32
		do
			l_app := new_app ("aq", create {VIEWPORT}.make_fullscreen)
			l_sink := sink_of (l_app)
			l_app.run
			assert ("no query", not l_sink.has_substring (Csi + "?u") and not l_sink.has_substring (Csi + "c"))
			assert ("same start as before T4", l_sink.starts_with (Csi + "?1049h" + Csi + "2J" + Csi + "H" + Csi + "?25l" + Csi + "?2026h"))
			assert ("both keys processed", l_app.key_count = 2)
			assert ("unknown", l_app.keyboard_enhancement_support = l_app.Keyboard_enhancement_unknown)

			l_app := new_app ("aq", create {VIEWPORT}.make_fullscreen)
			l_sink := sink_of (l_app)
			l_app.set_keyboard_enhancement (True)
			l_app.run
			assert ("pushed without a query", not l_sink.has_substring (Csi + "?u") and not l_sink.has_substring (Csi + "c"))
			assert ("same start as before T4 (flags)", l_sink.starts_with (Csi + "?1049h" + Csi + "2J" + Csi + "H" + Csi + ">3u" + Csi + "?25l" + Csi + "?2026h"))
			assert ("both keys processed (flags)", l_app.key_count = 2)
		end

	test_app_not_asked_on_resume
			-- Ctrl+Z and `fg`: the resume does not ask again (the M4 lesson: on a resume the
			-- input thread holds the console); it pushes the flags in the setup, from the
			-- answer of the start.
		local
			l_app: TEST_TUI_APP_IMPL
			l_driver: FAKE_CONSOLE_DRIVER
			l_sink, l_after: STRING_32
		do
			l_app := new_app (Csi_8 + "?1u" + Csi_8 + "?62c" + Ctrl_z, create {VIEWPORT}.make_fullscreen)
			l_driver := driver_of (l_app)
			l_sink := sink_of (l_app)
			l_app.set_keyboard_enhancement_if_supported (True)
			stop_after_resume (l_app, l_driver)
			l_app.run
			assert ("suspended once", l_driver.suspend_count = 1)
			assert ("asked once", occurrences (l_sink, Csi + "?u") = 1)
			assert ("still supported", l_app.is_keyboard_enhancement_supported)
			check attached l_driver.output_at_suspend as l_out then
				l_after := l_sink.substring (l_out.count + 1, l_sink.count)
				assert ("popped before the stop", l_out.has_substring (Csi + "<u"))
			end
			assert ("pushed again in the resume setup", l_after.has_substring (Csi + "?1049h" + Csi + "2J" + Csi + "H" + Csi + ">3u" + Csi + "?25l"))
			assert ("not asked on resume", not l_after.has_substring (Csi + "?u") and not l_after.has_substring (Csi + "c"))
		end

	test_app_background_start_asks_after_fg
			-- M10: started in the background, the application asks only once `fg` gave it
			-- the terminal; nothing is written or read before.
		local
			l_app: TEST_TUI_APP_IMPL
			l_driver: FAKE_CONSOLE_DRIVER
			l_sink: STRING_32
		do
			l_app := new_app (Csi_8 + "?1u" + Csi_8 + "?62c", create {VIEWPORT}.make_fullscreen)
			l_driver := driver_of (l_app)
			l_sink := sink_of (l_app)
			l_driver.set_background_for (3)
			l_app.set_keyboard_enhancement_if_supported (True)
			l_app.set_draw_hook (agent (f: FRAME; a: TEST_TUI_APP_IMPL) do a.stop end (?, l_app))
			l_app.run
			assert ("waited for the terminal", l_driver.background_query_count = 3)
			assert ("nothing read in the background", l_driver.read_count_at_foreground = 0)
			check attached l_driver.output_at_foreground as l_fg then
				assert ("nothing written in the background", l_fg.is_empty)
			end
			assert ("asked once after fg", occurrences (l_sink, Csi + "?u") = 1)
			assert ("supported and pushed", l_app.is_keyboard_enhancement_supported and l_sink.has_substring (Csi + ">3u"))
		end

	test_app_driver_provided_enhancement_asks_nothing
			-- Review fix #1: a driver that builds the enhanced key events itself (Win32) is
			-- "supported" whatever the terminal would answer. Nothing is asked or read, the
			-- flags are pushed in the setup, and the first key typed is processed.
		local
			l_app: TEST_TUI_APP_IMPL
			l_driver: FAKE_CONSOLE_DRIVER
			l_sink: STRING_32
		do
			l_app := new_app ("aq", create {VIEWPORT}.make_fullscreen)
			l_driver := driver_of (l_app)
			l_sink := sink_of (l_app)
			l_driver.set_provides_keyboard_enhancement (True)
			l_app.set_keyboard_enhancement_if_supported (True)
			l_app.run
			assert ("supported", l_app.is_keyboard_enhancement_supported)
			assert ("no query", not l_sink.has_substring (Csi + "?u") and not l_sink.has_substring (Csi + "c"))
			assert ("pushed once", occurrences (l_sink, Csi + ">3u") = 1)
			assert ("popped", l_sink.has_substring (Csi + "<u"))
			assert ("both keys processed", l_app.key_count = 2)
		end

	test_app_late_replies_dropped
			-- The query gives up (no reply within its wait); the replies then come late, to
			-- the input thread. They are not the application's: `dispatch` drops them, up to
			-- and including the DA1 reply. A key after them, and a DA1 reply after that one
			-- (the application's own), reach `process`.
		local
			l_app: TEST_TUI_APP_IMPL
			l_driver: FAKE_CONSOLE_DRIVER
			l_scripted: CELL [BOOLEAN]
		do
			l_app := new_app ("", create {VIEWPORT}.make_fullscreen)
			l_driver := driver_of (l_app)
			create l_scripted.put (False)
			l_app.set_keyboard_enhancement_if_supported (True)
			l_app.set_draw_hook (agent (f: FRAME; d: FAKE_CONSOLE_DRIVER; s: CELL [BOOLEAN])
				do
					if not s.item then
						s.put (True)
						d.script (Csi_8 + "?1u" + Csi_8 + "?62;22c" + "z" + Csi_8 + "?62c" + "q")
					end
				end (?, l_driver, l_scripted))
			l_app.run
			assert ("unknown", l_app.keyboard_enhancement_support = l_app.Keyboard_enhancement_unknown)
			assert ("late replies dropped, the next DA1 processed", l_app.reply_count = 1)
			assert ("keys processed", l_app.key_count = 2)
		end

feature {NONE} -- Helpers

	Csi: STRING_32 = "%/27/["
			-- Control Sequence Introducer

	Csi_8: STRING_8 = "%/27/["
			-- Control Sequence Introducer, for the fake driver's script

	Ctrl_z: STRING_8 = "%/26/"
			-- Ctrl+Z as the console sends it in raw mode

	one_flags (a_parser: ANSI_INPUT_PARSER; a_flags: NATURAL_8): BOOLEAN
			-- Did `a_parser` produce exactly one event, a flags reply with `a_flags`?
		do
			Result := a_parser.events.count = 1 and then attached {KEYBOARD_FLAGS_EVENT} a_parser.events.first as f
				and then f.flags = a_flags
		end

	one_attributes (a_parser: ANSI_INPUT_PARSER; a_parameters: ARRAY [INTEGER]): BOOLEAN
			-- Did `a_parser` produce exactly one event, a DA1 reply with `a_parameters`?
		local
			i: INTEGER
		do
			if a_parser.events.count = 1 and then attached {DEVICE_ATTRIBUTES_EVENT} a_parser.events.first as d
				and then d.parameters.count = a_parameters.count
			then
				Result := True
				from i := 1 until i > a_parameters.count loop
					Result := Result and d.parameters.i_th (i) = a_parameters [a_parameters.lower + i - 1]
					i := i + 1
				end
			end
		end

	new_driver (a_input: READABLE_STRING_8): FAKE_CONSOLE_DRIVER
			-- Fake console replaying `a_input`.
		do
			create Result
			Result.script (a_input)
		end

	new_backend (a_driver: FAKE_CONSOLE_DRIVER): ANSI_TERMINAL_BACKEND
			-- Backend on `a_driver`, output captured.
		do
			create Result.make_with_driver_and_sink (a_driver, create {STRING_32}.make_empty)
		end

	new_app (a_input: READABLE_STRING_8; a_viewport: VIEWPORT): TEST_TUI_APP_IMPL
			-- Application on a fake POSIX-like console replaying `a_input`, output captured.
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_sink: STRING_32
			l_backend: ANSI_TERMINAL_BACKEND
		do
			create l_driver
			l_driver.set_supports_suspend_resume (True)
			create l_sink.make_empty
			l_driver.watch_sink (l_sink)
			l_driver.script (a_input)
			create l_backend.make_with_driver_and_sink (l_driver, l_sink)
			create Result.make_with_terminal (create {TERMINAL [ANSI_TERMINAL_BACKEND]}.make_with_viewport (l_backend, a_viewport))
			Result.event_thread.set_poll_interval (5)
		end

	sink_of (a_app: TEST_TUI_APP_IMPL): STRING_32
			-- The output capture of `a_app`.
		do
			check attached a_app.backend.output_sink as s then
				Result := s
			end
		end

	driver_of (a_app: TEST_TUI_APP_IMPL): FAKE_CONSOLE_DRIVER
			-- The fake driver behind `a_app`.
		do
			check attached {FAKE_CONSOLE_DRIVER} a_app.backend.driver as d then
				Result := d
			end
		end

	stop_after_resume (a_app: TEST_TUI_APP_IMPL; a_driver: FAKE_CONSOLE_DRIVER)
			-- Stop `a_app` at the first frame drawn once the terminal was set up a second time.
		do
			a_app.set_draw_hook (agent (f: FRAME; a: TEST_TUI_APP_IMPL; d: FAKE_CONSOLE_DRIVER)
				do
					if d.raw_enable_count >= 2 then
						a.stop
					end
				end (?, a_app, a_driver))
		end

	occurrences (a_text, a_part: READABLE_STRING_32): INTEGER
			-- Number of non-overlapping occurrences of `a_part` in `a_text`.
		local
			i: INTEGER
		do
			from
				i := a_text.substring_index (a_part, 1)
			until
				i = 0
			loop
				Result := Result + 1
				i := a_text.substring_index (a_part, i + a_part.count)
			end
		end

	precondition_raised (a_action: ROUTINE; a_tag: STRING): BOOLEAN
			-- Does `a_action` raise a precondition violation tagged `a_tag`?
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

end
