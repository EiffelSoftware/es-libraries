note
	description: "[
		P2b K6: the examples read the clipboard. EXAMPLE_TEXT_AREA's Ctrl+V and
		EXAMPLE_MENU_BAR's Edit > Paste, each run through the real event loop on a
		FAKE_CONSOLE_DRIVER with an output sink (TEXT_AREA_SCRIPTED_APP,
		MENU_BAR_SCRIPTED_APP), on both of TUI_APPLICATION's paths:
		  * OSC 52 (the fake driver as on Linux, no clipboard of its own): the request is
		    written with a frame, and the terminal's reply is scripted at the first frame
		    after it was written (scripted earlier, it would be dropped as late); with no
		    reply the answer is `Status_unavailable` after the (shortened) timeout.
		  * The driver's own read (`FAKE_CONSOLE_DRIVER.set_clipboard_provider`, as
		    WIN32_CONSOLE_DRIVER reads the system clipboard): nothing is written to the
		    terminal.
		The text area inserts the text sanitised, as one undo step, and says so; the menu bar
		shows the first line in a toast. Any other answer gives the "not readable here"
		status line or toast. The real clipboard is not touched here (TEST_WIN32_CLIPBOARD
		does that, for the driver alone).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_CLIPBOARD_EXAMPLES

inherit
	BUFFER_TEST_HELPER

feature -- Text area

	test_text_area_ctrl_v_inserts_reply
			-- Ctrl+V, Ctrl+V again while the read is pending (ignored: one request), then the
			-- terminal's reply and Ctrl+Z. The status line says "Reading clipboard…" while
			-- pending; the reply's text is inserted at the cursor (the end), sanitised (CR LF
			-- to LF, TAB to a blank, the control character dropped), and the status line counts
			-- it; Ctrl+Z takes the whole paste back in one step.
		local
			l_app: TEXT_AREA_SCRIPTED_APP
		do
			l_app := new_text_area ("%/22/%/22/", 3, osc_reply ("c", {STRING_32} "foo%R%Nbar%Tbaz%/1/!") + "%/26/")
			l_app.set_clipboard_timeout (5_000)
			l_app.run
			assert ("one answer", l_app.clipboard_answers = 1)
			assert ("text answer", attached l_app.last_answer as a and then a.has_text)
			assert_same ("reading while pending", l_app.pending_status, {STRING_32} "Reading clipboard%/0x2026/")
			assert_same ("inserted, sanitised", l_app.text_at_answer, Initial_text + {STRING_32} "foo%Nbar baz!")
			assert_same ("status", l_app.status_at_answer, {STRING_32} "Pasted 12 characters from the clipboard.")
			assert_same ("one undo step", l_app.text, Initial_text)
			assert ("one request", occurrences (app_sink (l_app), query ("c")) = 1)
			assert ("not late", l_app.late_clipboard_replies = 0)
			assert ("read over", not l_app.is_clipboard_read_pending)
		end

	test_text_area_ctrl_v_no_reply
			-- Ctrl+V with no reply: after the timeout (150 ms here) the status line points to
			-- the terminal's own paste key, and the text is unchanged.
		local
			l_app: TEXT_AREA_SCRIPTED_APP
			l_start: INTEGER_64
		do
			l_app := new_text_area ("%/22/", 1, Void)
			l_app.set_clipboard_timeout (150)
			l_start := {MONOTONIC_CLOCK}.milliseconds
			l_app.run
			assert ("after the timeout", {MONOTONIC_CLOCK}.milliseconds - l_start >= 150)
			assert ("one answer", l_app.clipboard_answers = 1)
			assert ("unavailable", attached l_app.last_answer as a and then a.status = {CLIPBOARD_EVENT}.Status_unavailable)
			assert_same ("reading while pending", l_app.pending_status, {STRING_32} "Reading clipboard%/0x2026/")
			assert_same ("status", l_app.status_at_answer, Unreadable_message)
			assert_same ("text unchanged", l_app.text, Initial_text)
			assert ("one request", occurrences (app_sink (l_app), query ("c")) = 1)
		end

	test_text_area_ctrl_v_reply_not_text
			-- A reply too large for the parser's cap is not inserted either: the same status
			-- line as for no reply.
		local
			l_app: TEXT_AREA_SCRIPTED_APP
		do
			l_app := new_text_area ("%/22/", 1, osc_reply ("c", {STRING_32} "far too long for the cap"))
			l_app.event_thread.set_max_osc_size (8)
			l_app.set_clipboard_timeout (5_000)
			l_app.run
			assert ("too large", attached l_app.last_answer as a and then a.status = {CLIPBOARD_EVENT}.Status_too_large)
			assert_same ("status", l_app.status_at_answer, Unreadable_message)
			assert_same ("text unchanged", l_app.text, Initial_text)
		end

	test_text_area_ctrl_v_driver_provider
			-- A driver that reads the clipboard itself (Windows): Ctrl+V inserts its text, CR LF
			-- as one line break, and writes nothing to the terminal; an unavailable clipboard
			-- gives the "not readable" status line, an empty one says there was nothing, and
			-- neither changes the text.
		local
			l_app: TEXT_AREA_SCRIPTED_APP
		do
			l_app := new_text_area ("%/22/", 1, Void)
			driver_of (l_app).set_clipboard_provider ({STRING_32} "one%R%Ntwo %/0x1F600/", {CLIPBOARD_EVENT}.Status_text)
			l_app.set_clipboard_timeout (5_000)
			l_app.run
			assert ("driver asked once", driver_of (l_app).clipboard_read_count = 1)
			assert ("no OSC 52", not app_sink (l_app).has_substring ({STRING_32} "]52;"))
			assert_same ("inserted", l_app.text, Initial_text + {STRING_32} "one%Ntwo %/0x1F600/")
			assert_same ("status", l_app.status_at_answer, {STRING_32} "Pasted 9 characters from the clipboard.")

			l_app := new_text_area ("%/22/", 1, Void)
			driver_of (l_app).set_clipboard_provider (Void, {CLIPBOARD_EVENT}.Status_unavailable)
			l_app.run
			assert_same ("unavailable status", l_app.status_at_answer, Unreadable_message)
			assert_same ("unavailable: text unchanged", l_app.text, Initial_text)

			l_app := new_text_area ("%/22/", 1, Void)
			driver_of (l_app).set_clipboard_provider (Void, {CLIPBOARD_EVENT}.Status_text)
			l_app.run
			assert ("empty answer", attached l_app.last_answer as a and then a.has_text and then a.text.is_empty)
			assert_same ("empty status", l_app.status_at_answer, {STRING_32} "Clipboard holds no text: nothing pasted.")
			assert_same ("empty: text unchanged", l_app.text, Initial_text)
		end

	test_text_area_typed_keys_unchanged
			-- A paste through the terminal (no bracketed paste: typed keys) is inserted as
			-- before, and reads nothing from the clipboard.
		local
			l_app: TEXT_AREA_SCRIPTED_APP
		do
			create l_app.make_scripted (new_terminal ("ab%Rc"), 4)
			l_app.run
			assert_same ("typed", l_app.text, Initial_text + {STRING_32} "ab%Nc")
			assert ("no read", l_app.clipboard_answers = 0 and not l_app.is_clipboard_read_pending)
			assert ("no OSC 52", not app_sink (l_app).has_substring ({STRING_32} "]52;"))
		end

	test_text_area_bracketed_paste
			-- The example turns bracketed paste on; the terminal's own paste (a PASTE_EVENT)
			-- is inserted sanitised as one undo step, reads nothing from the clipboard, and the
			-- status line counts its characters.
		local
			l_app: TEXT_AREA_SCRIPTED_APP
		do
			create l_app.make_scripted (new_terminal ("x%/27/[200~foo%R%Nbar%Tbaz%/27/[201~y"), 2)
			l_app.run
			assert ("bracketed paste on", app_sink (l_app).has_substring ({STRING_32} "%/27/[?2004h"))
			assert_same ("pasted, sanitised", l_app.text, Initial_text + {STRING_32} "xfoo%Nbar bazy")
			assert_same ("status", l_app.status_line, {STRING_32} "Pasted 11 characters (terminal paste).")
			assert ("no read", l_app.clipboard_answers = 0 and not app_sink (l_app).has_substring ({STRING_32} "]52;"))

				-- Ctrl+Z after the paste undoes all of it at once
			create l_app.make_scripted (new_terminal ("%/27/[200~one two%/27/[201~%/26/"), 1)
			l_app.run
			assert_same ("one undo step", l_app.text, Initial_text)
		end

feature -- Menu bar

	test_menu_bar_paste_reply_toast
			-- Edit > Paste (F10, Right to Edit, Up wraps to Paste, Enter) asks the terminal; its
			-- reply's first line is shown in a success toast at the panel's bottom right and on
			-- the "Last command" line.
		local
			l_app: MENU_BAR_SCRIPTED_APP
			l_buf: BUFFER
		do
			l_app := new_menu_bar (Choose_paste, osc_reply ("c", {STRING_32} "first line%Nsecond line"))
			l_app.set_clipboard_timeout (5_000)
			l_app.run
			assert ("one answer", l_app.clipboard_answers = 1)
			assert_same ("reading while pending", l_app.pending_command, {STRING_32} "Paste: reading clipboard%/0x2026/")
			assert_same ("command", l_app.last_command, {STRING_32} "Paste: first line")
			assert ("one toast", l_app.toasts.count = 1)
			assert ("success", l_app.toasts.item (1).level = {TOAST_LEVEL}.success)
			assert ("one request", occurrences (app_sink (l_app), query ("c")) = 1)
			assert ("not late", l_app.late_clipboard_replies = 0)
			assert ("menu closed", not l_app.menu.is_open)
				-- The 23 x 3 box at the bottom right of the panel's inside (columns 16..38,
				-- rows 8..10), over the help line
			create l_buf.make (40, 12)
			l_app.render_now (create {FRAME}.make (l_buf))
			assert_buffer_line ("toast top", l_buf, 8, {STRING_32} "%/0x2502/F10/Alt+F: menu%/0x256D/" + line_of (21) + "%/0x256E/%/0x2502/")
			assert_buffer_line ("toast text", l_buf, 9, {STRING_32} "%/0x2502/               %/0x2502/Clipboard: first line%/0x2502/%/0x2502/")
			assert_buffer_line ("toast bottom", l_buf, 10, {STRING_32} "%/0x2502/               %/0x2570/" + line_of (21) + "%/0x256F/%/0x2502/")
		end

	test_menu_bar_paste_no_reply_toast
			-- Edit > Paste with no reply: after the timeout a warning toast points to the
			-- terminal's own paste key (word-wrapped in the toast's 36 columns).
		local
			l_app: MENU_BAR_SCRIPTED_APP
			l_buf: BUFFER
			l_start: INTEGER_64
		do
			l_app := new_menu_bar (Choose_paste, Void)
			l_app.set_clipboard_timeout (150)
			l_start := {MONOTONIC_CLOCK}.milliseconds
			l_app.run
			assert ("after the timeout", {MONOTONIC_CLOCK}.milliseconds - l_start >= 150)
			assert ("unavailable", attached l_app.last_answer as a and then a.status = {CLIPBOARD_EVENT}.Status_unavailable)
			assert_same ("command", l_app.last_command, {STRING_32} "Paste: clipboard not readable")
			assert ("one toast", l_app.toasts.count = 1)
			assert ("warning", l_app.toasts.item (1).level = {TOAST_LEVEL}.warning)
				-- At most 34 columns inside: three rows, the widest 32, so the box is 34 wide at
				-- columns 5..38, rows 6..10; the help line's "F10/" is left of it on row 8
			create l_buf.make (40, 12)
			l_app.render_now (create {FRAME}.make (l_buf))
			assert_buffer_line ("wrapped 1", l_buf, 7, toast_row ("    ", "Clipboard not readable here: use", 32))
			assert_buffer_line ("wrapped 2", l_buf, 8, toast_row ("F10/", "your terminal's paste", 32))
			assert_buffer_line ("wrapped 3", l_buf, 9, toast_row ("    ", "(Ctrl+Shift+V)", 32))
		end

	test_menu_bar_paste_driver_provider
			-- A driver that reads the clipboard itself: nothing is written to the terminal. The
			-- toast shows the first line that is not blank, sanitised and cut to 40 characters
			-- with an ellipsis; an unavailable clipboard gives the warning toast, an empty one
			-- an info toast.
		local
			l_app: MENU_BAR_SCRIPTED_APP
		do
			l_app := new_menu_bar (Choose_paste, Void)
			driver_of (l_app).set_clipboard_provider ({STRING_32} "  %R%N%T0123456789 0123456789 0123456789 0123456789 tail%R%Nnext", {CLIPBOARD_EVENT}.Status_text)
			l_app.set_clipboard_timeout (5_000)
			l_app.run
			assert ("driver asked once", driver_of (l_app).clipboard_read_count = 1)
			assert ("no OSC 52", not app_sink (l_app).has_substring ({STRING_32} "]52;"))
			assert_same ("first line, cut", l_app.last_command, {STRING_32} "Paste: 0123456789 0123456789 0123456789 012345%/0x2026/")
			assert ("success", l_app.toasts.count = 1 and then l_app.toasts.item (1).level = {TOAST_LEVEL}.success)

			l_app := new_menu_bar (Choose_paste, Void)
			driver_of (l_app).set_clipboard_provider (Void, {CLIPBOARD_EVENT}.Status_unavailable)
			l_app.run
			assert_same ("unavailable command", l_app.last_command, {STRING_32} "Paste: clipboard not readable")
			assert ("warning", l_app.toasts.count = 1 and then l_app.toasts.item (1).level = {TOAST_LEVEL}.warning)

			l_app := new_menu_bar (Choose_paste, Void)
			driver_of (l_app).set_clipboard_provider (Void, {CLIPBOARD_EVENT}.Status_text)
			l_app.run
			assert_same ("empty command", l_app.last_command, {STRING_32} "Paste: no text")
			assert ("info", l_app.toasts.count = 1 and then l_app.toasts.item (1).level = {TOAST_LEVEL}.info)
		end

	test_menu_bar_paste_answer_while_dialog_open
			-- Edit > Paste, then q (the "Quit?" dialog opens) before the reply comes: the
			-- answer still reaches the example and gives its toast, and the dialog stays open.
		local
			l_app: MENU_BAR_SCRIPTED_APP
		do
			l_app := new_menu_bar (Choose_paste + "q", osc_reply ("c", {STRING_32} "kept"))
			l_app.set_clipboard_timeout (5_000)
			l_app.run
			assert ("one answer", l_app.clipboard_answers = 1)
			assert ("dialog still open", l_app.quit_dialog.is_open)
			assert_same ("command", l_app.last_command, {STRING_32} "Paste: kept")
			assert ("toast", l_app.toasts.count = 1 and then l_app.toasts.item (1).level = {TOAST_LEVEL}.success)
		end

feature {NONE} -- Helpers

	Initial_text: STRING_32 = "Hello from TEXT_AREA%NType here. Ctrl+Z undoes, Ctrl+Y redoes.%N"
			-- EXAMPLE_TEXT_AREA's text at start (the cursor is at its end)

	Unreadable_message: STRING_32 = "Clipboard not readable here: use your terminal's paste (Ctrl+Shift+V)"
			-- The examples' answer when the clipboard is not read

	Choose_paste: STRING_8 = "%/27/[21~%/27/[C%/27/[A%R"
			-- F10 (File), Right (Edit), Up (wraps to Paste), Enter

	new_text_area (a_input: READABLE_STRING_8; a_presses: INTEGER; a_reply: detachable READABLE_STRING_8): TEXT_AREA_SCRIPTED_APP
			-- EXAMPLE_TEXT_AREA on a fake console replaying `a_input`, output captured, stopping
			-- after `a_presses` presses and one clipboard answer; `a_reply` is scripted once the
			-- read's request is written.
		do
			create Result.make_clipboard_scripted (new_terminal (a_input), a_presses, a_reply)
		end

	new_menu_bar (a_input: READABLE_STRING_8; a_reply: detachable READABLE_STRING_8): MENU_BAR_SCRIPTED_APP
			-- EXAMPLE_MENU_BAR on a fake console replaying `a_input`, output captured, stopping
			-- after one clipboard answer; `a_reply` is scripted once the read's request is
			-- written.
		do
			create Result.make_scripted (new_terminal (a_input), a_reply)
		end

	new_terminal (a_input: READABLE_STRING_8): TERMINAL [ANSI_TERMINAL_BACKEND]
			-- Fullscreen terminal on a fake console replaying `a_input`, output captured
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_sink: STRING_32
		do
			create l_driver
			create l_sink.make_empty
			l_driver.watch_sink (l_sink)
			l_driver.script (a_input)
			create Result.make (create {ANSI_TERMINAL_BACKEND}.make_with_driver_and_sink (l_driver, l_sink))
		end

	osc_reply (a_selection: STRING_8; a_text: READABLE_STRING_GENERAL): STRING_8
			-- The terminal's reply `ESC ] 52 ; a_selection ; <base64 of a_text as UTF-8> BEL`
		do
			Result := "%/27/]52;" + a_selection + ";" + {BASE64}.encoded_utf_8 (a_text) + "%/7/"
		end

	query (a_selection: STRING_8): STRING_32
			-- The request `ESC ] 52 ; a_selection ; ? ESC \`
		do
			Result := {STRING_32} "%/27/]52;" + a_selection.to_string_32 + {STRING_32} ";?%/27/\"
		end

	toast_row (a_left, a_text: STRING_32; a_width: INTEGER): STRING_32
			-- A panel row: its border, `a_left`, a toast box row holding `a_text` padded to
			-- `a_width`, the panel's border
		do
			Result := {STRING_32} "%/0x2502/" + a_left + {STRING_32} "%/0x2502/" + a_text
			Result.append (create {STRING_32}.make_filled (' ', a_width - a_text.count))
			Result.append ({STRING_32} "%/0x2502/%/0x2502/")
		end

	line_of (a_count: INTEGER): STRING_32
			-- `a_count` horizontal box lines (U+2500)
		do
			create Result.make_filled ('%/0x2500/', a_count)
		end

	assert_buffer_line (a_tag: STRING; a_buf: BUFFER; a_row: INTEGER; a_expected: STRING_32)
			-- Row `a_row` of `a_buf` is `a_expected`.
		local
			l_got: STRING_32
		do
			l_got := buffer_row_as_string (a_buf, a_row)
			assert (a_tag + ": expected [" + printable (a_expected) + "], got [" + printable (l_got) + "]", l_got.same_string (a_expected))
		end

	assert_same (a_tag: STRING; a_got: detachable READABLE_STRING_32; a_expected: READABLE_STRING_32)
			-- `a_got` is `a_expected`.
		do
			if attached a_got as g then
				assert (a_tag + ": expected [" + printable (a_expected) + "], got [" + printable (g) + "]", g.same_string (a_expected))
			else
				assert (a_tag + ": got nothing", False)
			end
		end

	driver_of (a_app: TUI_APPLICATION): FAKE_CONSOLE_DRIVER
			-- The fake console of `a_app`.
		do
			check attached {FAKE_CONSOLE_DRIVER} a_app.backend.driver as d then
				Result := d
			end
		end

	app_sink (a_app: TUI_APPLICATION): STRING_32
			-- The output capture of `a_app`.
		do
			check attached a_app.backend.output_sink as s then
				Result := s
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

end
