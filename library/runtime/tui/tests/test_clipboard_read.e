note
	description: "[
		P2b K2, the parser reads OSC replies: `ESC ] 52 ; <selection> ; <base64>` ended by
		BEL or ST (`ESC \`) gives one CLIPBOARD_EVENT; every other OSC is dropped; no byte of
		an OSC becomes a key; Alt+`]` is kept while `ESC ]` has not been followed by digits
		and `;`; the data is capped at `max_osc_size`; inside a bracketed paste `ESC ]` is
		text; a committed OSC cut off is dropped after the paste timeout.
		Events are compared through `described`, one token per event separated by " | ":
		a key as its modifiers and character (`Alt+]`, `Ctrl+x`, `q`) or its name (`Up`),
		a clipboard answer as `clip(<selection>,<status>[,<text>])`, a paste as
		`paste(<text>)`. Control characters in texts are written `\xNN`.
		P2b K4: with a driver that reads the clipboard itself (FAKE_CONSOLE_DRIVER's
		`set_clipboard_provider', as WIN32_CONSOLE_DRIVER does), the driver's answer takes the
		same path; the real Win32 read is tested in tests/platform/windows (TEST_WIN32_CLIPBOARD).
		P2b K3, the application part: the request bytes (`ESC ] 52 ; c ; ? ESC \`) written
		with the next frame; TUI_APPLICATION.read_clipboard with one pending read, a reply
		reaching `process' once, a reply nobody asked for dropped (`late_clipboard_replies'),
		`Status_unavailable' at the deadline (also with ticks far apart), a second read
		ignored, and the lifecycle: a stop sends nothing more and answers at the next `run',
		a suspend ends the read, nothing is asked while waiting for the terminal. These run
		TEST_TUI_APP_IMPL on a FAKE_CONSOLE_DRIVER; a reply is scripted by the key hook
		right after the read is asked for.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_CLIPBOARD_READ

inherit
	EQA_TEST_SET

feature -- Complete replies

	test_reply_ended_by_bel
			-- A reply ended by BEL gives one event with the decoded text; the next key arrives.
		do
			assert_parsed ("foobar", reply ("c", "Zm9vYmFy", bel) + "q", "clip(c,text,foobar) | q")
			assert_parsed ("rfc vectors", reply ("c", "Zg==", bel) + reply ("c", "Zm8=", bel) + reply ("c", "Zm9vYg==", bel),
				"clip(c,text,f) | clip(c,text,fo) | clip(c,text,foob)")
			assert_parsed ("utf-8", reply ("c", "w6nlrr0=", bel), {STRING_32} "clip(c,text,%/0xE9/%/0x5BBD/)")
			assert_parsed ("outside the BMP", reply ("c", "8J+YgA==", bel), {STRING_32} "clip(c,text,%/0x1F600/)")
			assert_parsed ("number with a leading zero is 52", esc + "]052;c;Zm9v" + bel, "clip(c,text,foo)")
		end

	test_reply_ended_by_st
			-- A reply ended by ST (`ESC \`) gives the same event as with BEL.
		do
			assert_parsed ("foobar", reply ("c", "Zm9vYmFy", st) + "q", "clip(c,text,foobar) | q")
			assert_parsed ("utf-8", reply ("p", "w6nlrr0=", st), {STRING_32} "clip(p,text,%/0xE9/%/0x5BBD/)")
			assert_parsed ("then an arrow", reply ("c", "Zm9v", st) + esc + "[A", "clip(c,text,foo) | Up")
		end

	test_reply_selections
			-- `selection` is the first character of the selection field, `c` when it is empty.
		do
			assert_parsed ("c", reply ("c", "Zm9v", bel), "clip(c,text,foo)")
			assert_parsed ("p", reply ("p", "Zm9v", bel), "clip(p,text,foo)")
			assert_parsed ("empty field", reply ("", "Zm9v", bel), "clip(c,text,foo)")
			assert_parsed ("several characters", reply ("pc", "Zm9v", st), "clip(p,text,foo)")
			assert_parsed ("xterm s0", reply ("s0", "Zm9v", st), "clip(s,text,foo)")
		end

	test_reply_empty_and_query
			-- Empty data, or `?` (the query echoed back), is `Status_text` with empty text.
		do
			assert_parsed ("empty bel", reply ("c", "", bel), "clip(c,text,)")
			assert_parsed ("empty st", reply ("p", "", st), "clip(p,text,)")
			assert_parsed ("query bel", reply ("c", "?", bel), "clip(c,text,)")
			assert_parsed ("query st", reply ("p", "?", st) + "q", "clip(p,text,) | q")
		end

	test_reply_invalid_base64
			-- Data that is not strict base64, or no data field at all, is `Status_invalid`.
		do
			assert_parsed ("length", reply ("c", "Zm9", bel), "clip(c,invalid)")
			assert_parsed ("alphabet", reply ("c", "Zm9-", bel), "clip(c,invalid)")
			assert_parsed ("unused bits", reply ("c", "QR==", bel), "clip(c,invalid)")
			assert_parsed ("padding inside", reply ("c", "Zg==Zg==", bel), "clip(c,invalid)")
			assert_parsed ("two queries", reply ("c", "??", bel), "clip(c,invalid)")
			assert_parsed ("blank", reply ("c", "Zm9v Zm9v", bel), "clip(c,invalid)")
			assert_parsed ("line break", reply ("c", "Zm9v%NZm9v", st), "clip(c,invalid)")
			assert_parsed ("third field", reply ("c", "Zm9v;Zm9v", st), "clip(c,invalid)")
			assert_parsed ("non-ASCII", reply ("c", {STRING_32} "Zm9%/0xC3/%/0xA9/", st), "clip(c,invalid)")
			assert_parsed ("non-ASCII as '*'", reply ("c", {STRING_32} "%/0xC3/%/0xA9/", st), "clip(c,invalid)")
			assert_parsed ("no data field", esc + "]52;c" + bel + "q", "clip(c,invalid) | q")
			assert_parsed ("no selection field", esc + "]52;" + st, "clip(c,invalid)")
		end

	test_reply_text_not_sanitised
			-- The text keeps control characters; invalid UTF-8 is U+FFFD; the 8-bit ST (U+009C)
			-- does not end the reply.
		do
			-- "a<TAB>b<LF><ESC>c" is YQliCh tj in base64
			assert_parsed ("controls kept", reply ("c", {BASE64}.encoded ("a%Tb%N%/27/c"), bel), "clip(c,text,a\x09b\x0A\x1Bc)")
			assert_parsed ("lone FF", reply ("c", "/w==", bel), {STRING_32} "clip(c,text,%/0xFFFD/)")
			assert_parsed ("genuine U+FFFD kept", reply ("c", {BASE64}.encoded_utf_8 ({STRING_32} "x%/0xFFFD/"), bel), {STRING_32} "clip(c,text,x%/0xFFFD/)")
			assert_parsed ("8-bit ST is data", reply ("c", {STRING_32} "Zm9v%/0xC2/%/0x9C/", bel), "clip(c,invalid)")
		end

feature -- Split replies

	test_reply_split_byte_by_byte
			-- A reply read one byte at a time gives nothing until its last byte, then one event.
		local
			l_replies: ARRAY [STRING_32]
			l_expected: ARRAY [STRING_8]
			l_parser: ANSI_INPUT_PARSER
			l_reply: STRING_32
			i, k: INTEGER
		do
			l_replies := <<reply ("c", "Zm9vYmFy", bel), reply ("p", "Zm9vYmFy", st), reply ("c", "", st), reply ("", "?", bel),
				reply ("c", "Zm9", st), esc + "]11;rgb:0000/0000/0000" + st>>
			l_expected := <<"clip(c,text,foobar) | q", "clip(p,text,foobar) | q", "clip(c,text,) | q", "clip(c,text,) | q",
				"clip(c,invalid) | q", "q">>
			from
				i := l_replies.lower
			until
				i > l_replies.upper
			loop
				l_reply := l_replies [i]
				create l_parser.make
				from
					k := 1
				until
					k > l_reply.count
				loop
					assert ("nothing before byte " + k.out + " of reply " + i.out, l_parser.events.is_empty)
					l_parser.parse_code (l_reply.code (k))
					k := k + 1
				end
				assert ("back to ground after reply " + i.out, l_parser.is_between_sequences)
				l_parser.parse_string ("q")
				assert_events ("reply " + i.out, l_parser, l_expected [i])
				i := i + 1
			end
		end

	test_reply_split_with_pauses
			-- Once committed (`ESC ] 52 ;` read), a reply survives input pauses shorter than the
			-- paste timeout, between any two of its bytes, ST split included. Split at every
			-- position into two reads, it gives the same event.
		local
			l_parser: ANSI_INPUT_PARSER
			l_reply: STRING_32
			l_commit, k: INTEGER
		do
			l_reply := reply ("c", "Zm9vYmFy", st)
			l_commit := l_reply.index_of (';', 1)
			create l_parser.make
			from
				k := 1
			until
				k > l_reply.count
			loop
				l_parser.parse_code (l_reply.code (k))
				if k >= l_commit and k < l_reply.count then
					l_parser.flush_escape
					l_parser.notify_idle (l_parser.paste_timeout_ms - 1)
					assert ("waiting after byte " + k.out, l_parser.is_in_osc and l_parser.events.is_empty)
				end
				k := k + 1
			end
			assert_events ("paused reply", l_parser, "clip(c,text,foobar)")

			from
				k := 1
			until
				k >= l_reply.count
			loop
				create l_parser.make
				l_parser.parse_string (l_reply.substring (1, k))
				assert ("nothing yet at " + k.out, l_parser.events.is_empty)
				l_parser.parse_string (l_reply.substring (k + 1, l_reply.count))
				l_parser.parse_string ("q")
				assert_events ("split at " + k.out, l_parser, "clip(c,text,foobar) | q")
				k := k + 1
			end
		end

	test_reply_between_two_keys
			-- A reply between two keys: key, event, key, whatever the keys.
		do
			assert_parsed ("letters", {STRING_32} "a" + reply ("c", "Zm9v", bel) + "b", "a | clip(c,text,foo) | b")
			assert_parsed ("arrows", esc + "[A" + reply ("p", "Zm9v", st) + esc + "[B", "Up | clip(p,text,foo) | Down")
			assert_parsed ("alt keys", esc + "x" + reply ("c", "", st) + esc + "y", "Alt+x | clip(c,text,) | Alt+y")
			assert_parsed ("two replies and Alt+]", reply ("c", "Zm9v", bel) + reply ("p", "YmFy", st) + esc + "]a",
				"clip(c,text,foo) | clip(p,text,bar) | Alt+] | a")
			assert_parsed ("escape key before", esc + reply ("c", "Zm9v", st) + "q", "Escape | clip(c,text,foo) | q")
		end

feature -- Alt+]

	test_alt_bracket_then_letter
			-- `ESC ]` then a letter is Alt+`]`, then the letter.
		do
			assert_parsed ("a", esc + "]a", "Alt+] | a")
			assert_parsed ("bracket", esc + "]]", "Alt+] | ]")
			assert_parsed ("empty number then ;", esc + "];", "Alt+] | ;")
			assert_parsed ("enter", esc + "]%R", "Alt+] | Enter")
			assert_parsed ("BEL", esc + "]" + bel, "Alt+] | Ctrl+g")
			assert_parsed ("then a sequence", esc + "]" + esc + "[A", "Alt+] | Up")
			assert_parsed ("then Alt+x", esc + "]" + esc + "x", "Alt+] | Alt+x")
			assert_parsed ("twice", esc + "]" + esc + "]q", "Alt+] | Alt+] | q")
		end

	test_alt_bracket_timeout
			-- `ESC ]` then the lone-ESC timeout is Alt+`]`; what follows is plain typing.
		local
			l_parser: ANSI_INPUT_PARSER
		do
			create l_parser.make
			l_parser.parse_string (esc + "]")
			assert ("pending", l_parser.events.is_empty and not l_parser.is_between_sequences and not l_parser.is_in_osc)
			l_parser.flush_escape
			assert ("ground", l_parser.is_between_sequences)
			l_parser.parse_string ("x")
			assert_events ("flush", l_parser, "Alt+] | x")

			l_parser.parse_string (esc + "]")
			l_parser.notify_idle (25)
			l_parser.parse_string ("52;")
			assert_events ("idle", l_parser, "Alt+] | 5 | 2 | ;")

			l_parser.parse_string (esc + "]" + esc)
			l_parser.flush_escape
			assert_events ("then a lone ESC", l_parser, "Alt+] | Escape")
		end

	test_alt_bracket_digit_then_letter
			-- `ESC ] 1 x` is Alt+`]`, `1`, `x`: digits before a non-digit, or before a timeout,
			-- are typed keys.
		local
			l_parser: ANSI_INPUT_PARSER
			l_digits: STRING_32
		do
			assert_parsed ("1 x", esc + "]1x", "Alt+] | 1 | x")
			assert_parsed ("52 then BEL", esc + "]52" + bel, "Alt+] | 5 | 2 | Ctrl+g")
			assert_parsed ("52 then a sequence", esc + "]52" + esc + "[A", "Alt+] | 5 | 2 | Up")
			assert_parsed ("52 then ST", esc + "]52" + st, "Alt+] | 5 | 2 | Alt+\")
			assert_parsed ("52 then :", esc + "]52:c;Zm9v", "Alt+] | 5 | 2 | : | c | ; | Z | m | 9 | v")

			create l_parser.make
			l_parser.parse_string (esc + "]12")
			l_parser.flush_escape
			l_parser.parse_string ("x")
			assert_events ("timeout after digits", l_parser, "Alt+] | 1 | 2 | x")

			-- More digits than an OSC number has: Alt+], then all of them typed
			create l_digits.make_filled ('7', 70)
			create l_parser.make
			l_parser.parse_string (esc + "]" + l_digits + ";")
			assert ("not committed", not l_parser.is_in_osc and l_parser.is_between_sequences)
			assert ("Alt+], 70 digits, ;", l_parser.events.count = 72)
			assert ("first Alt+]", attached {KEY_EVENT} l_parser.events.first as k and then (k.modifiers.is_alt and k.code.character = ']'))
			assert ("digits plain", across 2 |..| 71 as j all attached {KEY_EVENT} l_parser.events [j] as d and then (d.modifiers.is_empty and d.code.character = '7') end)
		end

feature -- Dropped and capped

	test_other_osc_dropped
			-- OSC replies other than 52 give no event and no key, by BEL or ST; the next key arrives.
		local
			l_parser: ANSI_INPUT_PARSER
			l_long: STRING_32
		do
			assert_parsed ("OSC 11 st", esc + "]11;rgb:1e1e/1e1e/1e1e" + st + "q", "q")
			assert_parsed ("OSC 10 bel", esc + "]10;rgb:ffff/ffff/ffff" + bel + "q", "q")
			assert_parsed ("OSC 4", esc + "]4;1;rgb:cdcd/0000/0000" + st + "q", "q")
			assert_parsed ("OSC 8 echo", esc + "]8;;https://example.org/" + st + "link" + esc + "]8;;" + st, "l | i | n | k")
			assert_parsed ("OSC 520", esc + "]520;c;Zm9v" + bel + "q", "q")
			assert_parsed ("OSC 0 title", esc + "]0;" + bel, "")
			assert_parsed ("number too long for 52", esc + "]99999999999999999999;c;Zm9v" + bel + "q", "q")

			-- A long colour reply is not kept
			create l_long.make_filled ('x', 5000)
			create l_parser.make
			l_parser.set_max_osc_size (8)
			l_parser.parse_string (esc + "]11;" + l_long)
			assert ("not kept", l_parser.is_in_osc and l_parser.osc_data_count = 0)
			l_parser.parse_string (st + "q")
			assert_events ("long OSC 11", l_parser, "q")
		end

	test_reply_over_cap
			-- Data up to `max_osc_size` is kept; one more character drops it, the reply is followed
			-- to its end and gives `Status_too_large`; the next key arrives.
		local
			l_parser: ANSI_INPUT_PARSER
			l_reply: STRING_32
			l_big: STRING_8
			k: INTEGER
		do
			create l_parser.make
			assert ("default cap", l_parser.max_osc_size = {ANSI_INPUT_PARSER}.Default_max_paste_size)
			l_parser.set_max_osc_size (8)
			assert ("cap set", l_parser.max_osc_size = 8)
			l_parser.parse_string (reply ("c", "Zm9vYmFy", bel))
			assert_events ("exactly the cap", l_parser, "clip(c,text,foobar)")

			l_reply := reply ("p", "Zm9vYmFyYg==", st)
			from
				k := 1
			until
				k > l_reply.count
			loop
				l_parser.parse_code (l_reply.code (k))
				assert ("bounded at " + k.out, l_parser.osc_data_count <= 8)
				k := k + 1
			end
			l_parser.parse_string ("q")
			assert_events ("over the cap", l_parser, "clip(p,too_large) | q")

			l_parser.parse_string (reply ("c", "!!!!!!!!!!", bel) + "q")
			assert_events ("invalid and over the cap", l_parser, "clip(c,too_large) | q")
			l_parser.parse_string (reply ("c", "Zm9v", bel))
			assert_events ("next reply kept again", l_parser, "clip(c,text,foo)")

			-- A large reply under a large cap is read whole
			l_big := {BASE64}.encoded (create {STRING_8}.make_filled ('z', 30_000))
			create l_parser.make
			l_parser.set_max_osc_size (l_big.count)
			l_parser.parse_string (reply ("c", l_big, st))
			assert ("one event", l_parser.events.count = 1)
			assert ("whole text", attached {CLIPBOARD_EVENT} l_parser.events.first as c and then
				(c.has_text and c.text.count = 30_000 and c.text.occurrences ('z') = 30_000))
			l_parser.wipe_out
			l_parser.set_max_osc_size (l_big.count - 1)
			l_parser.parse_string (reply ("c", l_big, st))
			assert_events ("one character too many", l_parser, "clip(c,too_large)")
		end

feature -- Paste

	test_reply_inside_paste
			-- Inside a bracketed paste, a reply (or any `ESC ]`) is pasted text.
		local
			l_parser: ANSI_INPUT_PARSER
			l_texts: ARRAY [STRING_32]
			i: INTEGER
		do
			l_texts := <<reply ("c", "Zm9v", bel), reply ("p", "Zm9v", st), esc + "]11;rgb:0/0/0" + st, esc + "]a", {STRING_32} "ab" + esc + "]", {STRING_32} "x" + esc + "]52;">>
			from
				i := l_texts.lower
			until
				i > l_texts.upper
			loop
				create l_parser.make
				l_parser.parse_string (esc + "[200~" + l_texts [i] + esc + "[201~q")
				assert ("paste ended " + i.out, not l_parser.is_in_paste and l_parser.is_between_sequences)
				assert ("paste then key " + i.out, l_parser.events.count = 2)
				assert ("text kept " + i.out, attached {PASTE_EVENT} l_parser.events.first as p and then p.text.same_string (l_texts [i]))
				assert ("then q " + i.out, attached {KEY_EVENT} l_parser.events [2] as q and then q.code.character = 'q')
				i := i + 1
			end
		end

feature -- Timeout

	test_committed_osc_timeout
			-- A committed OSC cut off is dropped after the paste timeout, without an event or key;
			-- the parser is back in ground and the next key arrives.
		local
			l_parser: ANSI_INPUT_PARSER
			l_cuts: ARRAY [STRING_32]
			i: INTEGER
		do
			l_cuts := <<esc + "]52;", esc + "]52;c", esc + "]52;c;Zm9v", esc + "]52;c;Zm9v" + esc, esc + "]11;rgb:0",
				esc + "]52;c;Zm9v%/0xC3/">>
			from
				i := l_cuts.lower
			until
				i > l_cuts.upper
			loop
				create l_parser.make
				l_parser.set_paste_timeout (100)
				-- The last cut ends in the lead byte of a UTF-8 sequence
				across l_cuts [i] as c loop
					l_parser.parse_code (c.natural_32_code)
				end
				l_parser.flush_escape
				l_parser.notify_idle (99)
				assert ("still waiting " + i.out, l_parser.is_in_osc and l_parser.events.is_empty)
				l_parser.notify_idle (100)
				assert ("dropped " + i.out, not l_parser.is_in_osc and l_parser.is_between_sequences)
				assert ("no event " + i.out, l_parser.events.is_empty)
				l_parser.parse_string ({STRING_32} "q" + esc + "]a")
				assert_events ("typing after cut " + i.out, l_parser, "q | Alt+] | a")
				i := i + 1
			end
		end

feature -- Edge cases

	test_escape_inside_osc
			-- Inside an OSC, ESC not followed by `\` drops the OSC and starts a new sequence.
		local
			l_parser: ANSI_INPUT_PARSER
		do
			assert_parsed ("arrow", esc + "]52;c;Zm9v" + esc + "[A", "Up")
			assert_parsed ("alt key", esc + "]11;rgb:0" + esc + "x", "Alt+x")
			assert_parsed ("new OSC", esc + "]11;rgb:0" + reply ("c", "Zm9v", bel), "clip(c,text,foo)")
			assert_parsed ("new Alt+]", esc + "]52;c;Zm" + esc + "]a", "Alt+] | a")

			create l_parser.make
			l_parser.parse_string (esc + "]52;c;Zm" + esc + esc)
			l_parser.flush_escape
			assert_events ("two Escape keys", l_parser, "Escape | Escape")

			l_parser.parse_string (esc + "]52;c;Zm9v" + esc)
			l_parser.flush_escape
			l_parser.notify_idle (25)
			assert ("ST may follow", l_parser.is_in_osc and l_parser.events.is_empty)
			l_parser.parse_string ("\")
			assert_events ("ST after a pause", l_parser, "clip(c,text,foo)")
		end

	test_can_sub_cancel_osc
			-- CAN or SUB inside an OSC drops it without an event and is then a key.
		do
			assert_parsed ("CAN", esc + "]52;c;Zm9v%/24/q", "Ctrl+x | q")
			assert_parsed ("SUB", esc + "]52;c;Zm9v%/26/q", "Ctrl+z | q")
			assert_parsed ("CAN in selection", esc + "]52;%/24/", "Ctrl+x")
			assert_parsed ("SUB in OSC 11", esc + "]11;rgb%/26/q", "Ctrl+z | q")
			assert_parsed ("other controls are data", reply ("c", "Zm9v%T", bel), "clip(c,invalid)")
		end

	test_discard_pending_in_osc
			-- `discard_pending` drops an OSC in progress; typing goes on and the cap can be set.
		local
			l_parser: ANSI_INPUT_PARSER
		do
			create l_parser.make
			l_parser.parse_string (esc + "]52;c;Zm9v")
			assert ("in osc", l_parser.is_in_osc and l_parser.osc_data_count = 4)
			l_parser.discard_pending
			assert ("dropped", not l_parser.is_in_osc and l_parser.is_between_sequences and l_parser.osc_data_count = 0)
			l_parser.set_max_osc_size (16)
			l_parser.parse_string ({STRING_32} "YmFy" + bel + "q")
			assert_events ("rest typed", l_parser, "Y | m | F | y | Ctrl+g | q")

			l_parser.parse_string (esc + "]1")
			l_parser.discard_pending
			l_parser.parse_string ("q")
			assert_events ("number dropped", l_parser, "q")
		end

	test_clipboard_event_kind
			-- CLIPBOARD_EVENT is a clipboard event only; other events are not.
		local
			l_event: CLIPBOARD_EVENT
			l_text: STRING_32
		do
			create l_event.make ('c', {CLIPBOARD_EVENT}.Status_unavailable)
			assert ("is clipboard", l_event.is_clipboard)
			assert ("no other kind", not (l_event.is_key or l_event.is_mouse or l_event.is_resize or l_event.is_tick
				or l_event.is_paste or l_event.is_focus or l_event.is_cursor_position or l_event.is_keyboard_flags
				or l_event.is_device_attributes or l_event.is_custom))
			assert ("unavailable", l_event.status = {CLIPBOARD_EVENT}.Status_unavailable and not l_event.has_text and l_event.text.is_empty)
			assert ("selection", l_event.selection = 'c')
			create l_text.make_from_string ("x")
			create l_event.make_text ('p', l_text)
			l_text.append ("y")
			assert ("text copied", l_event.has_text and l_event.text.same_string ("x") and l_event.selection = 'p')
			assert ("statuses valid", across <<{CLIPBOARD_EVENT}.Status_text, {CLIPBOARD_EVENT}.Status_unavailable,
				{CLIPBOARD_EVENT}.Status_too_large, {CLIPBOARD_EVENT}.Status_invalid>> as s all {CLIPBOARD_EVENT}.is_valid_status (s) end)
			assert ("others not", not {CLIPBOARD_EVENT}.is_valid_status (0) and not {CLIPBOARD_EVENT}.is_valid_status (5))
			assert ("key not clipboard", not (create {KEY_EVENT}.make_char ('a')).is_clipboard)
			assert ("paste not clipboard", not (create {PASTE_EVENT}.make ("a")).is_clipboard)
			assert ("tick not clipboard", not (create {TICK_EVENT}).is_clipboard)
		end

	test_event_thread_reply
			-- Through EVENT_THREAD: a reply between keys; `renewed` keeps `max_osc_size`.
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_queue: SYNCHRONIZED_EVENT_QUEUE
			l_thread, l_next: EVENT_THREAD
			l_events: ARRAYED_LIST [EVENT]
		do
			create l_driver
			l_driver.script ("a%/27/]52;c;Zm9vYmFy%/7/q")
			create l_queue.make
			create l_thread.make (l_queue, l_driver)
			l_thread.set_poll_interval (5)
			l_thread.launch
			l_events := collect_events (l_queue, 3, 3000)
			l_thread.stop
			l_thread.join
			assert_described ("thread", l_events, "a | clip(c,text,foobar) | q")

			create l_driver
			l_driver.script ("%/27/]52;p;Zm9vYmFy%/27/\q")
			create l_queue.make
			create l_thread.make (l_queue, l_driver)
			l_thread.set_poll_interval (5)
			l_thread.set_max_osc_size (4)
			l_next := l_thread.renewed
			l_next.launch
			l_events := collect_events (l_queue, 2, 3000)
			l_next.stop
			l_next.join
			assert_described ("renewed thread", l_events, "clip(p,too_large) | q")
		end

feature -- Request (K3)

	test_request_bytes
			-- The backend writes `ESC ] 52 ; <sel> ; ? ESC \`; TERMINAL holds requests until the
			-- next `draw`, which writes each once, in order; discarded ones are never written;
			-- VIRTUAL_TERMINAL logs them.
		local
			l_sink: STRING_32
			l_backend: ANSI_TERMINAL_BACKEND
			l_terminal: TERMINAL [ANSI_TERMINAL_BACKEND]
			l_vt: VIRTUAL_TERMINAL
			l_vt_terminal: TERMINAL [VIRTUAL_TERMINAL]
			l_copy: STRING_8
		do
			create l_sink.make_empty
			create l_backend.make_with_driver_and_sink (create {FAKE_CONSOLE_DRIVER}, l_sink)
			l_backend.request_clipboard_contents ('c')
			assert ("clipboard query", l_sink.same_string (query ("c")))
			assert ("exact bytes", l_sink.same_string ({STRING_32} "%/27/]52;c;?%/27/\"))
			l_sink.wipe_out
			l_backend.request_clipboard_contents ('p')
			assert ("selection query", l_sink.same_string (query ("p")))
			assert ("other target refused", precondition_raised (agent l_backend.request_clipboard_contents ('s'), "valid_selection"))

			create l_sink.make_empty
			create l_terminal.make (create {ANSI_TERMINAL_BACKEND}.make_with_driver_and_sink (create {FAKE_CONSOLE_DRIVER}, l_sink))
			assert ("none at first", not l_terminal.has_clipboard_request and l_terminal.pending_clipboard_requests.is_empty)
			l_terminal.request_clipboard
			assert ("held", l_terminal.has_clipboard_request and l_terminal.pending_clipboard_requests.same_string ("c"))
			assert ("not written before the frame", not l_sink.has_substring ({STRING_32} "]52;"))
			l_terminal.request_selection
			l_copy := l_terminal.pending_clipboard_requests
			l_copy.wipe_out
			assert ("a copy", l_terminal.pending_clipboard_requests.same_string ("cp"))
			l_terminal.draw (agent (f: FRAME) do end)
			assert ("both written once", occurrences (l_sink, query ("c")) = 1 and occurrences (l_sink, query ("p")) = 1)
			assert ("in order", l_sink.substring_index (query ("c"), 1) < l_sink.substring_index (query ("p"), 1))
			assert ("none left", not l_terminal.has_clipboard_request)
			l_terminal.draw (agent (f: FRAME) do end)
			assert ("not written again", occurrences (l_sink, query ("c")) = 1 and occurrences (l_sink, query ("p")) = 1)
			l_terminal.request_clipboard
			l_terminal.discard_clipboard_requests
			assert ("discarded", not l_terminal.has_clipboard_request)
			l_terminal.draw (agent (f: FRAME) do end)
			assert ("discarded never written", occurrences (l_sink, query ("c")) = 1)

			create l_vt.make (10, 3)
			l_vt.request_clipboard_contents ('c')
			assert ("virtual logged", l_vt.operations.has ("request_clipboard(c)"))
			create l_vt.make (10, 3)
			create l_vt_terminal.make (l_vt)
			l_vt_terminal.request_selection
			assert ("virtual: not before the frame", not l_vt.operations.has ("request_clipboard(p)"))
			l_vt_terminal.draw (agent (f: FRAME) do end)
			assert ("virtual: with the frame", l_vt.operations.has ("request_clipboard(p)"))
		end

feature -- Application (K3)

	test_app_reply_reaches_process_once
			-- A read sends one request with the next frame; the reply, scripted after it,
			-- reaches `process` once, ends the read, and is not counted as late.
		local
			l_app: TEST_TUI_APP_IMPL
			l_sink: STRING_32
			l_pending_seen: CELL [BOOLEAN]
		do
			l_app := new_app ("r", False)
			l_sink := sink_of (l_app)
			create l_pending_seen.put (False)
			l_app.set_clipboard_timeout (5_000)
			l_app.set_key_hook (agent (k: KEY_EVENT; a: TEST_TUI_APP_IMPL; c: CELL [BOOLEAN])
				do
					if is_char (k, 'r') then
						a.read_clipboard
						c.put (a.is_clipboard_read_pending and a.is_clipboard_request_queued
							and not a.is_clipboard_request_sent
							and a.clipboard_read_selection = 'c' and a.terminal.has_clipboard_request)
					end
				end (?, l_app, l_pending_seen))
			reply_once_sent (l_app, "%/27/]52;c;Zm9vYmFy%/7/")
			l_app.set_clipboard_hook (agent (e: CLIPBOARD_EVENT; a: TEST_TUI_APP_IMPL) do a.stop end (?, l_app))
			l_app.run
			assert ("pending and queued, not sent, after the read", l_pending_seen.item)
			assert_described ("one answer", l_app.clipboard_events, "clip(c,text,foobar)")
			assert ("one request", occurrences (l_sink, query ("c")) = 1)
			assert ("no other OSC 52", occurrences (l_sink, {STRING_32} "%/27/]52;") = 1)
			assert ("read over", not l_app.is_clipboard_read_pending and not l_app.is_clipboard_request_sent)
			assert ("not late", l_app.late_clipboard_replies = 0)
		end

	test_app_unrequested_reply_dropped
			-- A reply with no read pending never reaches `process` and is counted; the keys
			-- around it still arrive; nothing is asked of the terminal.
		local
			l_app: TEST_TUI_APP_IMPL
		do
			l_app := new_app ("a%/27/]52;c;Zm9v%/7/b%/27/]52;p;%/27/\q", False)
			l_app.run
			assert ("no answer processed", l_app.clipboard_events.is_empty)
			assert ("two late", l_app.late_clipboard_replies = 2)
			assert ("keys arrive", l_app.key_count = 3)
			assert ("no request", not sink_of (l_app).has_substring ({STRING_32} "]52;"))
			assert ("nothing pending", not l_app.is_clipboard_read_pending)
		end

	test_app_timeout_unavailable
			-- With no reply, `process` gets `Status_unavailable` at the deadline, also when
			-- ticks are far apart (10 s); a reply after the timeout is dropped as late.
		local
			l_app: TEST_TUI_APP_IMPL
			l_asked, l_answered: CELL [INTEGER_64]
			l_elapsed: INTEGER_64
		do
			l_app := new_app ("r", False)
			create l_asked.put (0)
			create l_answered.put (0)
			l_app.set_tick_rate (10_000)
			l_app.set_clipboard_timeout (150)
			l_app.set_key_hook (agent (k: KEY_EVENT; a: TEST_TUI_APP_IMPL; c: CELL [INTEGER_64])
				do
					if is_char (k, 'r') then
						c.put ({MONOTONIC_CLOCK}.milliseconds)
						a.read_selection
					end
				end (?, l_app, l_asked))
			l_app.set_clipboard_hook (agent (e: CLIPBOARD_EVENT; a: TEST_TUI_APP_IMPL; c: CELL [INTEGER_64])
				do
					c.put ({MONOTONIC_CLOCK}.milliseconds)
					assert ("over before process", not a.is_clipboard_read_pending)
					-- The reply comes too late, then 'q' ends the run
					driver_of (a).script ("%/27/]52;p;Zm9v%/27/\q")
				end (?, l_app, l_answered))
			l_app.run
			assert_described ("unavailable", l_app.clipboard_events, "clip(p,unavailable)")
			l_elapsed := l_answered.item - l_asked.item
			assert ("not before the deadline: " + l_elapsed.out, l_elapsed >= 150)
			assert ("near the deadline: " + l_elapsed.out, l_elapsed < 2_000)
			assert ("no tick needed", l_app.tick_count = 0)
			assert ("selection request", occurrences (sink_of (l_app), query ("p")) = 1)
			assert ("reply after the timeout dropped", l_app.late_clipboard_replies = 1)
			assert ("nothing pending", not l_app.is_clipboard_read_pending)
		end

	test_app_second_read_ignored
			-- A read while one is pending changes nothing and sends nothing; once answered, a
			-- new read is taken (and may be asked for from `process` handling the answer).
		local
			l_app: TEST_TUI_APP_IMPL
			l_sink: STRING_32
			l_unchanged: CELL [BOOLEAN]
		do
			l_app := new_app ("r", False)
			l_sink := sink_of (l_app)
			create l_unchanged.put (False)
			l_app.set_clipboard_timeout (5_000)
			l_app.set_key_hook (agent (k: KEY_EVENT; a: TEST_TUI_APP_IMPL; c: CELL [BOOLEAN])
				local
					l_deadline: INTEGER_64
				do
					if is_char (k, 'r') then
						a.read_clipboard
						l_deadline := a.clipboard_read_deadline
						a.read_selection
						a.read_clipboard
						c.put (a.clipboard_read_selection = 'c' and a.clipboard_read_deadline = l_deadline
							and a.terminal.pending_clipboard_requests.same_string ("c"))
					end
				end (?, l_app, l_unchanged))
			reply_once_sent (l_app, "%/27/]52;c;Zm9v%/7/")
			l_app.set_clipboard_hook (agent (e: CLIPBOARD_EVENT; a: TEST_TUI_APP_IMPL)
				do
					if a.clipboard_events.count = 1 then
						a.read_selection
						reply_once_sent (a, "%/27/]52;p;YmFy%/27/\")
					else
						a.stop
					end
				end (?, l_app))
			l_app.run
			assert ("second read ignored", l_unchanged.item)
			assert_described ("two answers", l_app.clipboard_events, "clip(c,text,foo) | clip(p,text,bar)")
			assert ("one clipboard request", occurrences (l_sink, query ("c")) = 1)
			assert ("one selection request, after it", occurrences (l_sink, query ("p")) = 1
				and l_sink.substring_index (query ("c"), 1) < l_sink.substring_index (query ("p"), 1))
			assert ("not late", l_app.late_clipboard_replies = 0)
		end

	test_app_stop_sends_nothing_more
			-- A stop with a read pending sends nothing more and gives `process` no event
			-- after it. A read asked for and stopped in the same `process` is never written.
			-- The `Status_unavailable` answer is given at the start of the next `run`.
		local
			l_app: TEST_TUI_APP_IMPL
			l_sink: STRING_32
			l_mark: INTEGER
			l_once: CELL [BOOLEAN]
		do
				-- Asked, written with the frame, then 'q'
			l_app := new_app ("r", False)
			l_sink := sink_of (l_app)
			l_app.set_clipboard_timeout (5_000)
			l_app.set_key_hook (agent (k: KEY_EVENT; a: TEST_TUI_APP_IMPL) do if is_char (k, 'r') then a.read_clipboard end end (?, l_app))
			create l_once.put (False)
			l_app.set_draw_hook (agent (f: FRAME; a: TEST_TUI_APP_IMPL; c: CELL [BOOLEAN])
				do
					if not c.item and a.is_clipboard_request_sent and not a.terminal.has_clipboard_request
						and sink_of (a).has_substring (query ("c"))
					then
						c.put (True)
						driver_of (a).script ("q")
					end
				end (?, l_app, l_once))
			l_app.run
			assert ("one request", occurrences (l_sink, query ("c")) = 1)
			assert ("nothing after the stop", attached driver_of (l_app).output_at_restore as l_out
				and then occurrences (l_out, query ("c")) = 1)
			assert ("no event after the stop", l_app.clipboard_events.is_empty)
			assert ("owed, not sent", l_app.is_clipboard_read_pending and not l_app.is_clipboard_request_sent)

				-- The next run answers first
			l_mark := l_sink.count
			l_app.set_key_hook (Void)
			l_app.set_draw_hook (Void)
			l_app.set_clipboard_hook (agent (e: CLIPBOARD_EVENT; a: TEST_TUI_APP_IMPL) do a.stop end (?, l_app))
			l_app.set_tick_hook (agent (a: TEST_TUI_APP_IMPL) do if a.tick_count > 100 then a.stop end end (l_app))
			l_app.run
			assert_described ("answered in the next run", l_app.clipboard_events, "clip(c,unavailable)")
			assert ("at once", l_app.tick_count <= 2)
			assert ("nothing asked in the next run", not l_sink.substring (l_mark + 1, l_sink.count).has_substring ({STRING_32} "]52;"))
			assert ("over", not l_app.is_clipboard_read_pending)

				-- Asked and stopped in the same `process`: never written
			l_app := new_app ("r", False)
			l_app.set_key_hook (agent (k: KEY_EVENT; a: TEST_TUI_APP_IMPL)
				do
					if is_char (k, 'r') then
						a.read_clipboard
						a.stop
					end
				end (?, l_app))
			l_app.run
			assert ("never written", not sink_of (l_app).has_substring ({STRING_32} "]52;"))
			assert ("taken back", not l_app.terminal.has_clipboard_request)
			assert ("no event", l_app.clipboard_events.is_empty)
			assert ("owed", l_app.is_clipboard_read_pending and not l_app.is_clipboard_request_sent)
		end

	test_app_suspend_ends_read
			-- A stop (Ctrl+Z) ends a pending read: `process` gets `Status_unavailable` after
			-- the resume, and a reply that comes then is late. A read asked for and then
			-- suspended in the same `process` is never written (nothing goes to the shell).
		local
			l_app: TEST_TUI_APP_IMPL
			l_driver: FAKE_CONSOLE_DRIVER
			l_sink: STRING_32
			l_once: CELL [BOOLEAN]
		do
				-- Written with a frame, then Ctrl+Z
			l_app := new_app ("r", True)
			l_driver := driver_of (l_app)
			l_sink := sink_of (l_app)
			l_app.set_clipboard_timeout (5_000)
			l_app.set_key_hook (agent (k: KEY_EVENT; a: TEST_TUI_APP_IMPL) do if is_char (k, 'r') then a.read_clipboard end end (?, l_app))
			create l_once.put (False)
			l_app.set_draw_hook (agent (f: FRAME; a: TEST_TUI_APP_IMPL; c: CELL [BOOLEAN])
				do
					if not c.item and a.is_clipboard_request_sent and sink_of (a).has_substring (query ("c"))
						and not a.terminal.has_clipboard_request
					then
						c.put (True)
						driver_of (a).script ("%/26/")
					end
				end (?, l_app, l_once))
			l_app.set_clipboard_hook (agent (e: CLIPBOARD_EVENT; a: TEST_TUI_APP_IMPL)
				do
					-- The terminal answers after the resume: too late
					driver_of (a).script ("%/27/]52;c;Zm9v%/7/q")
				end (?, l_app))
			l_app.run
			assert ("suspended once", l_driver.suspend_count = 1)
			assert_described ("unavailable after the stop", l_app.clipboard_events, "clip(c,unavailable)")
			assert ("the reply after it is late", l_app.late_clipboard_replies = 1)
			assert ("one request, before the stop", occurrences (l_sink, query ("c")) = 1
				and attached l_driver.output_at_suspend as l_out and then occurrences (l_out, query ("c")) = 1)

				-- Asked and suspended in the same `process`
			l_app := new_app ("r", True)
			l_driver := driver_of (l_app)
			l_app.set_key_hook (agent (k: KEY_EVENT; a: TEST_TUI_APP_IMPL)
				do
					if is_char (k, 'r') then
						a.read_clipboard
						a.suspend
						assert ("ended by the stop", a.is_clipboard_read_pending and not a.is_clipboard_request_sent)
					end
				end (?, l_app))
			l_app.set_clipboard_hook (agent (e: CLIPBOARD_EVENT; a: TEST_TUI_APP_IMPL) do a.stop end (?, l_app))
			l_app.run
			assert ("suspended", l_driver.suspend_count = 1)
			assert_described ("unavailable", l_app.clipboard_events, "clip(c,unavailable)")
			assert ("never written", not sink_of (l_app).has_substring ({STRING_32} "]52;"))
		end

	test_app_read_while_waiting_for_terminal
			-- Started in the background, the application does not own the terminal: a read
			-- asks nothing and is answered `Status_unavailable` at the next iteration. A read
			-- before `run` is answered the same way at its start.
		local
			l_app: TEST_TUI_APP_IMPL
			l_driver: FAKE_CONSOLE_DRIVER
			l_state: CELL [BOOLEAN]
		do
			l_app := new_app ("", True)
			l_driver := driver_of (l_app)
			l_driver.set_background_for (1_000_000)
			create l_state.put (False)
			l_app.set_tick_hook (agent (a: TEST_TUI_APP_IMPL; c: CELL [BOOLEAN])
				do
					if a.tick_count = 1 then
						a.read_clipboard
						c.put (a.is_waiting_for_terminal and a.is_clipboard_read_pending and not a.is_clipboard_request_sent
							and not a.terminal.has_clipboard_request)
					elseif a.tick_count > 100 then
						a.stop
					end
				end (l_app, l_state))
			l_app.set_clipboard_hook (agent (e: CLIPBOARD_EVENT; a: TEST_TUI_APP_IMPL) do a.stop end (?, l_app))
			l_app.run
			assert ("not sent while waiting", l_state.item)
			assert_described ("unavailable", l_app.clipboard_events, "clip(c,unavailable)")
			assert ("before the next tick", l_app.tick_count = 1)
			assert ("nothing written", sink_of (l_app).is_empty)

			l_app := new_app ("", False)
			l_app.read_selection
			assert ("before run: not sent", l_app.is_clipboard_read_pending and not l_app.is_clipboard_request_sent)
			l_app.set_clipboard_hook (agent (e: CLIPBOARD_EVENT; a: TEST_TUI_APP_IMPL) do a.stop end (?, l_app))
			l_app.set_tick_hook (agent (a: TEST_TUI_APP_IMPL) do if a.tick_count > 100 then a.stop end end (l_app))
			l_app.run
			assert_described ("answered at the start", l_app.clipboard_events, "clip(p,unavailable)")
			assert ("nothing asked", not sink_of (l_app).has_substring ({STRING_32} "]52;"))
		end

	test_app_reply_before_request_written_dropped
			-- A reply that reaches the loop after a read but before the frame that writes its
			-- request answers an earlier request: it is dropped as late, and the reply that
			-- comes after the request is the answer. A reply for another selection is dropped
			-- as well.
		local
			l_app: TEST_TUI_APP_IMPL
			l_state: CELL [BOOLEAN]
		do
			l_app := new_app ("r", False)
			create l_state.put (False)
			l_app.set_clipboard_timeout (5_000)
			l_app.set_key_hook (agent (k: KEY_EVENT; a: TEST_TUI_APP_IMPL; c: CELL [BOOLEAN])
				do
					if is_char (k, 'r') then
						a.read_clipboard
							-- A stale reply, already queued behind the key
						a.dispatch_now (create {CLIPBOARD_EVENT}.make_text ('c', "stale"))
						c.put (a.late_clipboard_replies = 1 and a.is_clipboard_read_pending
							and a.is_clipboard_request_queued and a.clipboard_events.is_empty)
					end
				end (?, l_app, l_state))
			l_app.set_draw_hook (agent (f: FRAME; a: TEST_TUI_APP_IMPL)
				do
					if a.is_clipboard_request_sent and a.late_clipboard_replies = 1 then
							-- Written: a reply for the primary selection is not this read's answer
						a.dispatch_now (create {CLIPBOARD_EVENT}.make_text ('p', "other"))
						driver_of (a).script ("%/27/]52;c;Zm9v%/7/")
					end
				end (?, l_app))
			l_app.set_clipboard_hook (agent (e: CLIPBOARD_EVENT; a: TEST_TUI_APP_IMPL) do a.stop end (?, l_app))
			l_app.run
			assert ("stale reply dropped while queued", l_state.item)
			assert_described ("the answer", l_app.clipboard_events, "clip(c,text,foo)")
			assert ("stale and other selection late", l_app.late_clipboard_replies = 2)
			assert ("over", not l_app.is_clipboard_read_pending and not l_app.is_clipboard_request_queued)
		end

	test_app_reread_while_waiting_does_not_spin
			-- An application that reads again on each `Status_unavailable` while it waits for
			-- its terminal gets each answer `Unsent_clipboard_answer_ms` after its read, not at
			-- once: the loop still sleeps.
		local
			l_app: TEST_TUI_APP_IMPL
			l_driver: FAKE_CONSOLE_DRIVER
			l_times: ARRAYED_LIST [INTEGER_64]
			i: INTEGER
		do
			l_app := new_app ("", True)
			l_driver := driver_of (l_app)
			l_driver.set_background_for (1_000_000)
			create l_times.make (8)
			l_app.set_tick_hook (agent (a: TEST_TUI_APP_IMPL; t: ARRAYED_LIST [INTEGER_64])
				do
					if a.tick_count = 1 then
						t.extend ({MONOTONIC_CLOCK}.milliseconds)
						a.read_clipboard
					elseif a.tick_count > 200 then
						a.stop
					end
				end (l_app, l_times))
			l_app.set_clipboard_hook (agent (e: CLIPBOARD_EVENT; a: TEST_TUI_APP_IMPL; t: ARRAYED_LIST [INTEGER_64])
				do
					t.extend ({MONOTONIC_CLOCK}.milliseconds)
					if a.clipboard_events.count < 5 then
						a.read_clipboard
					else
						a.stop
					end
				end (?, l_app, l_times))
			l_app.run
			assert ("five answers", l_app.clipboard_events.count = 5)
			assert ("all unavailable", across l_app.clipboard_events as e all e.status = {CLIPBOARD_EVENT}.Status_unavailable end)
			from i := 2 until i > l_times.count loop
				assert ("not at once: " + (l_times [i] - l_times [i - 1]).out,
					l_times [i] - l_times [i - 1] >= l_app.Unsent_clipboard_answer_ms)
				i := i + 1
			end
			assert ("nothing written", sink_of (l_app).is_empty)
		end

	test_app_without_reads_unchanged
			-- An application that never reads writes no OSC 52, keeps nothing pending, and
			-- has the default timeout; the timeout can be set and must be positive.
		local
			l_app: TEST_TUI_APP_IMPL
		do
			l_app := new_app ("abq", False)
			assert ("default timeout", l_app.clipboard_timeout_ms = 3_000 and l_app.clipboard_timeout_ms = l_app.Default_clipboard_timeout_ms)
			assert ("nothing pending", not l_app.is_clipboard_read_pending and not l_app.is_clipboard_request_sent)
			l_app.run
			assert ("no OSC 52", not sink_of (l_app).has_substring ({STRING_32} "]52;"))
			assert ("no answer", l_app.clipboard_events.is_empty and l_app.late_clipboard_replies = 0)
			assert ("keys", l_app.key_count = 3)
			l_app.set_clipboard_timeout (1)
			assert ("set", l_app.clipboard_timeout_ms = 1)
			assert ("zero refused", precondition_raised (agent l_app.set_clipboard_timeout (0), "positive_ms"))
		end

feature -- Driver provider (K4)

	test_app_driver_reads_no_clipboard_by_default
			-- The fake driver, as on Linux, reads no clipboard: the terminal is asked (K3's
			-- path), and asking the driver anyway is refused.
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_app: TEST_TUI_APP_IMPL
		do
			create l_driver
			assert ("no provider", not l_driver.provides_clipboard_read)
			assert ("read refused", precondition_raised (agent l_driver.read_clipboard_text (10), "provides"))
			assert ("answer refused", precondition_raised (agent l_driver.clipboard_answer ('c', 10), "provides"))
			l_app := new_app ("r", False)
			l_app.set_clipboard_timeout (5_000)
			l_app.set_key_hook (agent (k: KEY_EVENT; a: TEST_TUI_APP_IMPL)
				do
					if is_char (k, 'r') then
						a.read_clipboard
						assert ("terminal asked", a.is_clipboard_request_queued and not a.is_native_clipboard_answer_queued)
					end
				end (?, l_app))
			reply_once_sent (l_app, "%/27/]52;c;Zm9v%/7/")
			l_app.set_clipboard_hook (agent (e: CLIPBOARD_EVENT; a: TEST_TUI_APP_IMPL) do a.stop end (?, l_app))
			l_app.run
			assert_described ("terminal answer", l_app.clipboard_events, "clip(c,text,foo)")
			assert ("request written", occurrences (sink_of (l_app), query ("c")) = 1)
			assert ("driver not asked", driver_of (l_app).clipboard_read_count = 0)
		end

	test_app_driver_read_answers_once
			-- With a driver that reads the clipboard itself, a read asks the driver at once,
			-- writes nothing to the terminal, counts as sent, and `process` gets the driver's
			-- answer once, CR LF kept; `read_selection` reads the same clipboard and answers
			-- for `p`. The cap is the input thread's `max_osc_size`.
		local
			l_app: TEST_TUI_APP_IMPL
			l_state: CELL [BOOLEAN]
		do
			l_app := new_app ("r", False)
			driver_of (l_app).set_clipboard_provider ("foo%R%Nbar", {CLIPBOARD_EVENT}.Status_text)
			l_app.set_clipboard_timeout (5_000)
			create l_state.put (False)
			l_app.set_key_hook (agent (k: KEY_EVENT; a: TEST_TUI_APP_IMPL; c: CELL [BOOLEAN])
				do
					if is_char (k, 'r') then
						a.read_clipboard
						c.put (a.is_clipboard_read_pending and a.is_clipboard_request_sent
							and not a.is_clipboard_request_queued and a.is_native_clipboard_answer_queued
							and not a.terminal.has_clipboard_request and driver_of (a).clipboard_read_count = 1)
						-- Ignored while pending: the driver is not asked again
						a.read_selection
						a.read_clipboard
					end
				end (?, l_app, l_state))
			l_app.set_clipboard_hook (agent (e: CLIPBOARD_EVENT; a: TEST_TUI_APP_IMPL)
				do
					assert ("over before process", not a.is_clipboard_read_pending and not a.is_native_clipboard_answer_queued)
					if a.clipboard_events.count = 1 then
						-- A new read from `process` handling the answer is taken
						a.read_selection
					else
						a.stop
					end
				end (?, l_app))
			l_app.run
			assert ("asked at once, sent, nothing written", l_state.item)
			assert_described ("two answers", l_app.clipboard_events, "clip(c,text,foo\x0D\x0Abar) | clip(p,text,foo\x0D\x0Abar)")
			assert ("driver asked twice", driver_of (l_app).clipboard_read_count = 2)
			assert ("cap", driver_of (l_app).last_clipboard_max_count = l_app.event_thread.max_osc_size
				and l_app.event_thread.max_osc_size = {ANSI_INPUT_PARSER}.Default_max_paste_size)
			assert ("no OSC 52", not sink_of (l_app).has_substring ({STRING_32} "]52;"))
			assert ("not late", l_app.late_clipboard_replies = 0)
		end

	test_app_driver_read_statuses
			-- The driver's answer: an empty clipboard is `Status_text` with empty text, one
			-- that cannot be read `Status_unavailable`, a text over `max_osc_size`
			-- `Status_too_large` (and at the cap, the text).
		do
			assert_described ("empty", driver_answers (Void, {CLIPBOARD_EVENT}.Status_text, 0), "clip(c,text,)")
			assert_described ("empty string", driver_answers ("", {CLIPBOARD_EVENT}.Status_text, 0), "clip(c,text,)")
			assert_described ("unavailable", driver_answers (Void, {CLIPBOARD_EVENT}.Status_unavailable, 0), "clip(c,unavailable)")
			assert_described ("too large", driver_answers ("abcd", {CLIPBOARD_EVENT}.Status_text, 3), "clip(c,too_large)")
			assert_described ("at the cap", driver_answers ("abc", {CLIPBOARD_EVENT}.Status_text, 3), "clip(c,text,abc)")
			assert_described ("U+1F600", driver_answers ({STRING_32} "%/0x1F600/", {CLIPBOARD_EVENT}.Status_text, 0), {STRING_32} "clip(c,text,%/0x1F600/)")
		end

	test_app_driver_read_terminal_reply_late
			-- While the driver answers, only its queued answer ends the read: an OSC 52 reply
			-- that comes meanwhile (or after) is late, whatever order the two arrive in.
		local
			l_app: TEST_TUI_APP_IMPL
		do
			l_app := new_app ("r%/27/]52;c;Zm9v%/7/", False)
			driver_of (l_app).set_clipboard_provider ("native", {CLIPBOARD_EVENT}.Status_text)
			l_app.set_clipboard_timeout (5_000)
			l_app.set_key_hook (agent (k: KEY_EVENT; a: TEST_TUI_APP_IMPL)
				do
					if is_char (k, 'r') then
						a.read_clipboard
						-- And one more terminal reply, queued after the driver's answer
						driver_of (a).script ("%/27/]52;c;YmFy%/7/q")
					end
				end (?, l_app))
			l_app.run
			assert_described ("the driver's answer", l_app.clipboard_events, "clip(c,text,native)")
			assert ("both replies late", l_app.late_clipboard_replies = 2)
			assert ("nothing pending", not l_app.is_clipboard_read_pending and not l_app.is_native_clipboard_answer_queued)
		end

	test_app_driver_read_deadline_after_read
			-- The deadline starts once the driver has read: a read slower than the timeout
			-- (another program holding the clipboard) still gives the text, not
			-- `Status_unavailable`, and exactly one answer.
		local
			l_app: TEST_TUI_APP_IMPL
		do
			l_app := new_app ("r", False)
			driver_of (l_app).set_clipboard_provider ("slow", {CLIPBOARD_EVENT}.Status_text)
			driver_of (l_app).set_clipboard_read_delay (200)
			l_app.set_clipboard_timeout (80)
			l_app.set_key_hook (agent (k: KEY_EVENT; a: TEST_TUI_APP_IMPL) do if is_char (k, 'r') then a.read_clipboard end end (?, l_app))
			l_app.set_clipboard_hook (agent (e: CLIPBOARD_EVENT; a: TEST_TUI_APP_IMPL)
				do
					-- Wait past any deadline: no second answer may come
					driver_of (a).script ("q")
				end (?, l_app))
			l_app.run
			assert_described ("text", l_app.clipboard_events, "clip(c,text,slow)")
			assert ("not late", l_app.late_clipboard_replies = 0)
		end

	test_app_driver_read_lifecycle
			-- A stop ends a read whose driver answer is still queued: that answer is late (or
			-- wiped with the run's queue), and the read is answered `Status_unavailable`, after
			-- the resume or at the next `run`, exactly once. A read before `run` asks nothing
			-- of the driver, as K3 asks nothing of the terminal.
		local
			l_app: TEST_TUI_APP_IMPL
			l_driver: FAKE_CONSOLE_DRIVER
		do
				-- Asked and suspended in the same `process`
			l_app := new_app ("r", True)
			l_driver := driver_of (l_app)
			l_driver.set_clipboard_provider ("text", {CLIPBOARD_EVENT}.Status_text)
			l_app.set_key_hook (agent (k: KEY_EVENT; a: TEST_TUI_APP_IMPL)
				do
					if is_char (k, 'r') then
						a.read_clipboard
						a.suspend
						assert ("ended by the stop", a.is_clipboard_read_pending and not a.is_clipboard_request_sent
							and not a.is_native_clipboard_answer_queued)
					end
				end (?, l_app))
			l_app.set_clipboard_hook (agent (e: CLIPBOARD_EVENT; a: TEST_TUI_APP_IMPL) do a.stop end (?, l_app))
			l_app.run
			assert ("suspended", l_driver.suspend_count = 1)
			assert_described ("unavailable", l_app.clipboard_events, "clip(c,unavailable)")
			assert ("the driver's answer late", l_app.late_clipboard_replies = 1)
			assert ("driver asked once", l_driver.clipboard_read_count = 1)

				-- Asked and stopped in the same `process`: nothing more in this run, the
				-- answer at the start of the next
			l_app := new_app ("r", False)
			l_driver := driver_of (l_app)
			l_driver.set_clipboard_provider ("text", {CLIPBOARD_EVENT}.Status_text)
			l_app.set_key_hook (agent (k: KEY_EVENT; a: TEST_TUI_APP_IMPL)
				do
					if is_char (k, 'r') then
						a.read_clipboard
						a.stop
					end
				end (?, l_app))
			l_app.run
			assert ("no answer after the stop", l_app.clipboard_events.is_empty)
			assert ("owed", l_app.is_clipboard_read_pending and not l_app.is_clipboard_request_sent
				and not l_app.is_native_clipboard_answer_queued)
			l_app.set_key_hook (Void)
			l_app.set_clipboard_hook (agent (e: CLIPBOARD_EVENT; a: TEST_TUI_APP_IMPL) do a.stop end (?, l_app))
			l_app.run
			assert_described ("answered at the next run", l_app.clipboard_events, "clip(c,unavailable)")
			assert ("driver asked once", l_driver.clipboard_read_count = 1)

				-- Asked before `run`
			l_app := new_app ("", False)
			l_driver := driver_of (l_app)
			l_driver.set_clipboard_provider ("text", {CLIPBOARD_EVENT}.Status_text)
			l_app.read_clipboard
			assert ("not sent", l_app.is_clipboard_read_pending and not l_app.is_clipboard_request_sent
				and not l_app.is_native_clipboard_answer_queued)
			l_app.set_clipboard_hook (agent (e: CLIPBOARD_EVENT; a: TEST_TUI_APP_IMPL) do a.stop end (?, l_app))
			l_app.run
			assert_described ("unavailable at the start", l_app.clipboard_events, "clip(c,unavailable)")
			assert ("driver not asked", l_driver.clipboard_read_count = 0)
		end

feature {NONE} -- Helpers

	driver_answers (a_text: detachable READABLE_STRING_GENERAL; a_status, a_cap: INTEGER): ARRAYED_LIST [CLIPBOARD_EVENT]
			-- The answers `process` gets for one `read_clipboard`, the fake driver reading
			-- `a_text` with `a_status`, and `max_osc_size` set to `a_cap` (0: the default).
		local
			l_app: TEST_TUI_APP_IMPL
		do
			l_app := new_app ("r", False)
			driver_of (l_app).set_clipboard_provider (a_text, a_status)
			if a_cap > 0 then
				l_app.event_thread.set_max_osc_size (a_cap)
			end
			l_app.set_clipboard_timeout (5_000)
			l_app.set_key_hook (agent (k: KEY_EVENT; a: TEST_TUI_APP_IMPL) do if is_char (k, 'r') then a.read_clipboard end end (?, l_app))
			l_app.set_clipboard_hook (agent (e: CLIPBOARD_EVENT; a: TEST_TUI_APP_IMPL) do a.stop end (?, l_app))
			l_app.run
			assert ("no OSC 52", not sink_of (l_app).has_substring ({STRING_32} "]52;"))
			Result := l_app.clipboard_events
		end

	is_char (a_key: KEY_EVENT; a_char: CHARACTER_8): BOOLEAN
			-- Is `a_key` a press of `a_char` without modifiers?
		do
			Result := a_key.is_press and a_key.modifiers.is_empty and a_key.code.is_char
				and then a_key.code.character = a_char.to_character_32
		end

	query (a_selection: STRING_8): STRING_32
			-- `ESC ] 52 ; a_selection ; ? ESC \`
		do
			Result := esc + "]52;"
			Result.append_string_general (a_selection)
			Result.append ({STRING_32} ";?")
			Result.append (st)
		end

	new_app (a_input: READABLE_STRING_8; a_can_suspend: BOOLEAN): TEST_TUI_APP_IMPL
			-- Fullscreen application on a fake console replaying `a_input`, output captured;
			-- acting as a POSIX platform that can suspend when `a_can_suspend`.
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_sink: STRING_32
			l_backend: ANSI_TERMINAL_BACKEND
		do
			create l_driver
			l_driver.set_supports_suspend_resume (a_can_suspend)
			create l_sink.make_empty
			l_driver.watch_sink (l_sink)
			l_driver.script (a_input)
			create l_backend.make_with_driver_and_sink (l_driver, l_sink)
			create Result.make_with_terminal (create {TERMINAL [ANSI_TERMINAL_BACKEND]}.make (l_backend))
		end

	reply_once_sent (a_app: TEST_TUI_APP_IMPL; a_reply: READABLE_STRING_8)
			-- Script `a_reply` as the terminal's input at the first frame after the pending
			-- read's request was written (a reply scripted before could be read before that
			-- frame, and then be dropped as the answer to an earlier request).
		local
			l_done: CELL [BOOLEAN]
		do
			create l_done.put (False)
			a_app.set_draw_hook (agent (f: FRAME; a: TEST_TUI_APP_IMPL; r: READABLE_STRING_8; c: CELL [BOOLEAN])
				do
					if not c.item and a.is_clipboard_request_sent then
						c.put (True)
						driver_of (a).script (r)
					end
				end (?, a_app, a_reply, l_done))
		end

	driver_of (a_app: TUI_APPLICATION): FAKE_CONSOLE_DRIVER
			-- The fake console of `a_app`.
		do
			check attached {FAKE_CONSOLE_DRIVER} a_app.backend.driver as d then
				Result := d
			end
		end

	sink_of (a_app: TUI_APPLICATION): STRING_32
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

	esc: STRING_32
			-- A fresh one-character string holding ESC
		do
			create Result.make_filled ((27).to_character_32, 1)
		end

	bel: STRING_32
			-- A fresh one-character string holding BEL
		do
			create Result.make_filled ((7).to_character_32, 1)
		end

	st: STRING_32
			-- A fresh string holding ST, `ESC \`
		do
			Result := esc + "\"
		end

	reply (a_selection, a_data: READABLE_STRING_GENERAL; a_end: STRING_32): STRING_32
			-- `ESC ] 52 ; a_selection ; a_data a_end`
		do
			Result := esc + "]52;"
			Result.append_string_general (a_selection)
			Result.append_character (';')
			Result.append_string_general (a_data)
			Result.append (a_end)
		end

	assert_parsed (a_tag: STRING; a_input: READABLE_STRING_GENERAL; a_expected: READABLE_STRING_GENERAL)
			-- A new parser given `a_input`, then a lone-ESC flush, gives the events `a_expected`
			-- and is back in ground.
		local
			l_parser: ANSI_INPUT_PARSER
		do
			create l_parser.make
			l_parser.parse_string (a_input)
			l_parser.flush_escape
			assert (a_tag + ": back in ground", l_parser.is_between_sequences)
			assert_events (a_tag, l_parser, a_expected)
		end

	assert_events (a_tag: STRING; a_parser: ANSI_INPUT_PARSER; a_expected: READABLE_STRING_GENERAL)
			-- `a_parser` collected the events `a_expected`; clear them.
		do
			assert_described (a_tag, a_parser.events, a_expected)
			a_parser.wipe_out
		end

	assert_described (a_tag: STRING; a_events: LIST [EVENT]; a_expected: READABLE_STRING_GENERAL)
			-- `a_events` are described by `a_expected`.
		local
			l_got: STRING_32
		do
			l_got := described (a_events)
			assert (a_tag + ": expected [" + {UTF_CONVERTER}.string_32_to_utf_8_string_8 (a_expected.as_string_32)
				+ "], got [" + {UTF_CONVERTER}.string_32_to_utf_8_string_8 (l_got) + "]", l_got.same_string_general (a_expected))
		end

	described (a_events: LIST [EVENT]): STRING_32
			-- One token per event of `a_events`, separated by " | " (see the class note).
		do
			create Result.make_empty
			across a_events as e loop
				if not Result.is_empty then
					Result.append ({STRING_32} " | ")
				end
				if attached {KEY_EVENT} e as k then
					if not k.modifiers.is_empty then
						Result.append_string_general (k.modifiers.out)
						Result.append_character ('+')
					end
					if k.code.is_char then
						append_visible (Result, create {STRING_32}.make_filled (k.code.character, 1))
					else
						Result.append_string_general (k.code.out)
					end
				elseif attached {CLIPBOARD_EVENT} e as c then
					Result.append ({STRING_32} "clip(")
					Result.append_character (c.selection)
					inspect c.status
					when {CLIPBOARD_EVENT}.Status_text then
						Result.append ({STRING_32} ",text,")
						append_visible (Result, c.text)
					when {CLIPBOARD_EVENT}.Status_unavailable then
						Result.append ({STRING_32} ",unavailable")
					when {CLIPBOARD_EVENT}.Status_too_large then
						Result.append ({STRING_32} ",too_large")
					else
						Result.append ({STRING_32} ",invalid")
					end
					Result.append_character (')')
				elseif attached {PASTE_EVENT} e as p then
					Result.append ({STRING_32} "paste(")
					append_visible (Result, p.text)
					Result.append_character (')')
				else
					Result.append_string_general (e.generating_type.name)
				end
			end
		end

	append_visible (a_target: STRING_32; a_text: READABLE_STRING_GENERAL)
			-- Append `a_text` to `a_target`, control characters written `\xNN`.
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > a_text.count
			loop
				if a_text.code (i) < 32 or a_text.code (i) = 127 then
					a_target.append ({STRING_32} "\x")
					a_target.append_string_general (a_text.code (i).to_hex_string.substring (7, 8))
				else
					a_target.append_code (a_text.code (i))
				end
				i := i + 1
			end
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
