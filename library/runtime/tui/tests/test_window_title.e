note
	description: "[
		P2 T2, window title: WINDOW_TITLE's sanitizing, the backends, TERMINAL pushing the
		terminal's title once before the first title and popping it on restore, and
		TUI_APPLICATION setting the title once the terminal is set up and giving the
		terminal's title back when `run` ends.
		The sequences are checked against crossterm's documentation, not its source (which
		is not in this repository): `SetTitle` writes OSC 0 with a BEL terminator,
		`ESC ] 0 ; title BEL`. The title stack sequences are xterm's XTWINOPS 22 ; 0 (push)
		and 23 ; 0 (pop); crossterm has no command for them.
		The suspend sequence and the signal handlers are checked in TEST_SUSPEND_RESUME and
		TEST_PLATFORM_DRIVER.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_WINDOW_TITLE

inherit
	EQA_TEST_SET

feature -- Sanitizing

	test_sanitized_drops_controls
			-- Security property: C0 controls, DEL and C1 controls are dropped, everything else
			-- is kept in order. ESC, BEL and ST (U+009C) could otherwise end the OSC early and
			-- make the rest of the title escape sequences. The `\` of an `ESC \` stays, as text.
		local
			l_title, l_clean: STRING_32
		do
			l_title := {STRING_32} "a%/27/b%/7/c%/27/\d%/156/e%/127/f%Ug%/31/h%/128/i%/159/j"
			l_clean := {WINDOW_TITLE}.sanitized (l_title)
			assert ("controls dropped [" + l_clean.to_string_8 + "]", l_clean.same_string ({STRING_32} "abc\defghij"))
			assert ("sanitized", {WINDOW_TITLE}.is_sanitized (l_clean))
			assert ("not sanitized before", not {WINDOW_TITLE}.is_sanitized (l_title))
			assert ("dropped count", {WINDOW_TITLE}.dropped_count (l_title) = 9)
			assert ("non-ASCII kept", {WINDOW_TITLE}.sanitized ({STRING_32} "%/0xE9/%/0x5BBD/ ok").same_string ({STRING_32} "%/0xE9/%/0x5BBD/ ok"))
			assert ("STRING_8 C1 dropped", {WINDOW_TITLE}.sanitized ("x%/155/y").same_string ({STRING_32} "xy"))
			assert ("empty", {WINDOW_TITLE}.sanitized ("").is_empty)
			assert ("U+001F dropped", {WINDOW_TITLE}.is_dropped_code (0x1F))
			assert ("space kept", not {WINDOW_TITLE}.is_dropped_code (0x20))
			assert ("~ kept", not {WINDOW_TITLE}.is_dropped_code (0x7E))
			assert ("DEL dropped", {WINDOW_TITLE}.is_dropped_code (0x7F))
			assert ("U+009F dropped", {WINDOW_TITLE}.is_dropped_code (0x9F))
			assert ("U+00A0 kept", not {WINDOW_TITLE}.is_dropped_code (0xA0))
		end

feature -- Backends

	test_ansi_backend_writes_plain_title
			-- `set_title` writes exactly `ESC ] 0 ; title BEL`; `push_title` and `pop_title`
			-- write `CSI 22 ; 0 t` and `CSI 23 ; 0 t` and record the push in the driver.
		local
			l_backend: ANSI_TERMINAL_BACKEND
			l_sink: STRING_32
		do
			create l_sink.make_empty
			create l_backend.make_with_driver_and_sink (create {FAKE_CONSOLE_DRIVER}, l_sink)
			l_backend.set_title ("Hello, World")
			assert ("OSC 0 bytes", l_sink.same_string_general ("%/27/]0;Hello, World%/7/"))
			assert ("nothing pushed", not l_backend.is_title_pushed)
			l_sink.wipe_out
			l_backend.push_title
			assert ("push bytes", l_sink.same_string_general ("%/27/[22;0t"))
			assert ("pushed", l_backend.is_title_pushed and l_backend.driver.is_title_pushed)
			l_sink.wipe_out
			l_backend.pop_title
			assert ("pop bytes", l_sink.same_string_general ("%/27/[23;0t"))
			assert ("popped", not l_backend.is_title_pushed and not l_backend.driver.is_title_pushed)
		end

	test_ansi_backend_writes_utf8_title
			-- A title with "é" (U+00E9) and "宽" (U+5BBD) is written as UTF-8 bytes.
		local
			l_backend: ANSI_TERMINAL_BACKEND
			l_sink: STRING_32
		do
			create l_sink.make_empty
			create l_backend.make_with_driver_and_sink (create {FAKE_CONSOLE_DRIVER}, l_sink)
			l_backend.set_title ({STRING_32} "%/0xE9/%/0x5BBD/")
			assert ("UTF-8 bytes", l_sink.same_string_general ("%/27/]0;%/0xC3/%/0xA9/%/0xE5/%/0xAE/%/0xBD/%/7/"))
		end

	test_backend_refuses_unsanitized_title
			-- The backends take sanitized titles only (precondition): TERMINAL sanitizes.
		local
			l_backend: ANSI_TERMINAL_BACKEND
		do
			create l_backend.make_with_driver_and_sink (create {FAKE_CONSOLE_DRIVER}, create {STRING_32}.make_empty)
			assert ("BEL refused", precondition_raised (agent l_backend.set_title ("a%/7/b"), "sanitized"))
		end

	test_virtual_terminal_records_title
			-- VIRTUAL_TERMINAL records the title and the stack, and logs them.
		local
			l_vt: VIRTUAL_TERMINAL
		do
			create l_vt.make (10, 3)
			assert ("no title", l_vt.title = Void and not l_vt.is_title_pushed)
			l_vt.push_title
			l_vt.set_title ("Doc")
			assert ("recorded", attached l_vt.title as t and then t.same_string ({STRING_32} "Doc"))
			assert ("pushed", l_vt.is_title_pushed)
			l_vt.pop_title
			assert ("popped", not l_vt.is_title_pushed)
			assert ("logged", l_vt.operations.has ("push_title") and l_vt.operations.has ("set_title(Doc)")
				and l_vt.operations.has ("pop_title"))
		end

feature -- Terminal

	test_terminal_title_is_sanitized
			-- TERMINAL pushes, then writes the title with ESC, BEL, `ESC \` and U+009C
			-- dropped: the OSC ends at its own BEL only.
		local
			l_terminal: TERMINAL [ANSI_TERMINAL_BACKEND]
			l_sink: STRING_32
		do
			l_terminal := new_terminal
			l_sink := sink_of (l_terminal)
			l_terminal.set_title ({STRING_32} "ok%/27/]0;evil%/7/x%/27/\y%/156/z")
			assert ("recorded only", l_sink.is_empty)
			l_terminal.show_title
			assert ("bytes [" + l_sink.to_string_8 + "]",
				l_sink.same_string_general ("%/27/[22;0t%/27/]0;ok]0;evilx\yz%/7/"))
			assert ("title kept sanitized", attached l_terminal.title as t and then t.same_string ({STRING_32} "ok]0;evilx\yz"))
		end

	test_terminal_pushes_once
			-- `set_title` writes nothing itself. `show_title` pushes, then writes the title; a
			-- later `set_title` is written by the next `draw`, without a push. `restore_title`
			-- pops once, and writes nothing when nothing is pushed. After it, `draw` writes no
			-- title (the terminal's own is back), and the next `show_title` pushes again and
			-- writes the last title set.
		local
			l_terminal: TERMINAL [ANSI_TERMINAL_BACKEND]
			l_sink: STRING_32
		do
			l_terminal := new_terminal
			l_sink := sink_of (l_terminal)
			l_terminal.restore_title
			assert ("no pop without a push", l_sink.is_empty)
			l_terminal.show_title
			assert ("no title: nothing shown", l_sink.is_empty and not l_terminal.is_title_shown)
			l_terminal.set_title ("one")
			assert ("not shown: nothing written", l_sink.is_empty)
			l_terminal.show_title
			assert ("one push, then the title", l_sink.same_string_general ("%/27/[22;0t%/27/]0;one%/7/"))
			l_sink.wipe_out
			l_terminal.set_title ("two")
			assert ("written by the next frame", l_sink.is_empty)
			l_terminal.draw (agent (f: FRAME) do end)
			assert ("drawn without a push", occurrences (l_sink, {STRING_32} "%/27/]0;two%/7/") = 1
				and occurrences (l_sink, {STRING_32} "%/27/[22;0t") = 0)
			l_sink.wipe_out
			l_terminal.draw (agent (f: FRAME) do end)
			assert ("written once", occurrences (l_sink, {STRING_32} "%/27/]0;") = 0)
			l_sink.wipe_out
			l_terminal.restore_title
			l_terminal.restore_title
			assert ("one pop", l_sink.same_string_general ("%/27/[23;0t"))
			l_sink.wipe_out
			l_terminal.set_title ("three")
			l_terminal.draw (agent (f: FRAME) do end)
			assert ("not drawn once restored", occurrences (l_sink, {STRING_32} "%/27/]0;") = 0)
			l_sink.wipe_out
			l_terminal.show_title
			assert ("pushed again", l_sink.same_string_general ("%/27/[22;0t%/27/]0;three%/7/"))
		end

feature -- Application

	test_app_title_before_run_writes_nothing
			-- `set_title` before `run` only records the title (M10: nothing is written until
			-- the process owns the terminal).
		local
			l_app: TEST_TUI_APP_IMPL
		do
			l_app := new_app ("q")
			l_app.set_window_title ("App%/7/")
			assert ("nothing written", app_sink (l_app).is_empty)
			assert ("recorded sanitized", attached l_app.window_title as t and then t.same_string ({STRING_32} "App"))
		end

	test_app_pushes_once_per_run_and_pops
			-- A title set before `run` is written once the terminal is set up, after a push;
			-- a second title while running is written without a second push; the restore pops
			-- once, after leaving the alternate screen. A second `run` pushes and pops again.
			-- The second title is written by the frame after it was set, so the run stops in
			-- that frame (a quit key in the same batch as 't' would end it before any frame).
		local
			l_app: TEST_TUI_APP_IMPL
			l_sink: STRING_32
		do
			l_app := new_app ("t")
			l_sink := app_sink (l_app)
			l_app.set_window_title ("First")
			l_app.set_key_hook (agent (k: KEY_EVENT; a: TEST_TUI_APP_IMPL)
				do
					if k.code.is_char and then k.code.character = 't' then
						a.set_window_title ("Second")
					end
				end (?, l_app))
			l_app.set_draw_hook (agent (f: FRAME; a: TEST_TUI_APP_IMPL)
				do
					if attached a.window_title as t and then t.same_string ({STRING_32} "Second") then
						a.stop
					end
				end (?, l_app))
			l_app.run
			assert ("one push", occurrences (l_sink, Push) = 1)
			assert ("one pop", occurrences (l_sink, Pop) = 1)
			assert ("both titles", occurrences (l_sink, osc0 ("First")) = 1 and occurrences (l_sink, osc0 ("Second")) = 1)
			assert ("push before the first title", l_sink.substring_index (Push, 1) < l_sink.substring_index (osc0 ("First"), 1))
			assert ("first title after the setup", l_sink.substring_index ({STRING_32} "%/27/[?25l", 1) < l_sink.substring_index (osc0 ("First"), 1))
			assert ("pop after the second title", l_sink.substring_index (osc0 ("Second"), 1) < l_sink.substring_index (Pop, 1))
			assert ("restore order", l_sink.has_substring ({STRING_32} "%/27/[?1049l" + Pop))
			assert ("nothing pushed after the run", not l_app.backend.is_title_pushed)
			driver_of (l_app).script ("q")
			l_app.run
			assert ("pushed and popped once more", occurrences (l_sink, Push) = 2 and occurrences (l_sink, Pop) = 2)
			assert ("the last title set again", occurrences (l_sink, osc0 ("Second")) = 2)
		end

	test_app_without_title_writes_none
			-- An application that sets no title writes no OSC 0 and no push or pop.
		local
			l_app: TEST_TUI_APP_IMPL
			l_sink: STRING_32
		do
			l_app := new_app ("q")
			l_sink := app_sink (l_app)
			l_app.run
			assert ("restored", l_sink.has_substring ({STRING_32} "%/27/[?1049l"))
			assert ("no push", occurrences (l_sink, Push) = 0)
			assert ("no pop", occurrences (l_sink, Pop) = 0)
			assert ("no title", not l_sink.has_substring ({STRING_32} "%/27/]0;"))
		end

feature {NONE} -- Helpers

	Push: STRING_32 = "%/27/[22;0t"
			-- XTWINOPS 22 ; 0

	Pop: STRING_32 = "%/27/[23;0t"
			-- XTWINOPS 23 ; 0

	osc0 (a_title: READABLE_STRING_8): STRING_32
			-- `ESC ] 0 ; a_title BEL` for an ASCII `a_title`
		do
			Result := {STRING_32} "%/27/]0;" + a_title.to_string_32 + {STRING_32} "%/7/"
		end

	new_terminal: TERMINAL [ANSI_TERMINAL_BACKEND]
			-- Fullscreen terminal on a fake console, output captured
		do
			create Result.make (create {ANSI_TERMINAL_BACKEND}.make_with_driver_and_sink (create {FAKE_CONSOLE_DRIVER}, create {STRING_32}.make_empty))
		end

	sink_of (a_terminal: TERMINAL [ANSI_TERMINAL_BACKEND]): STRING_32
			-- The output capture of `a_terminal`.
		do
			check attached a_terminal.backend.output_sink as s then
				Result := s
			end
		end

	new_app (a_input: READABLE_STRING_8): TEST_TUI_APP_IMPL
			-- Fullscreen application on a fake console replaying `a_input`, output captured.
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_sink: STRING_32
			l_backend: ANSI_TERMINAL_BACKEND
		do
			create l_driver
			create l_sink.make_empty
			l_driver.watch_sink (l_sink)
			l_driver.script (a_input)
			create l_backend.make_with_driver_and_sink (l_driver, l_sink)
			create Result.make_with_terminal (create {TERMINAL [ANSI_TERMINAL_BACKEND]}.make (l_backend))
			Result.event_thread.set_poll_interval (5)
		end

	app_sink (a_app: TEST_TUI_APP_IMPL): STRING_32
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
