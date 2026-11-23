note
	description: "[
		P2 T3, OSC 52 clipboard write: the BASE64 encoder, the byte-exact OSC 52 sequence for
		the clipboard and the primary selection, TERMINAL's length cap and grapheme-safe
		prefix, TEXT_AREA_STATE.selected_text, and Ctrl+C in EXAMPLE_TEXT_AREA.
		P2b K1: the strict BASE64 decoder and its UTF-8 read with U+FFFD replacement.
		The sequence is checked against crossterm's documentation for `CopyToClipboard`
		(feature `osc52`), not its source (which is not in this repository):
		`ESC ] 52 ; c ; <base64> ESC \`, `p` for the primary selection.
		A copy leaves no terminal state, so it has nothing in TEST_SUSPEND_RESUME or
		TEST_PLATFORM_DRIVER.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_CLIPBOARD

inherit
	EQA_TEST_SET

feature -- Base64

	test_base64_rfc4648_vectors
			-- RFC 4648 §10 test vectors, with their lengths and alphabet.
		do
			assert_encoded ("", "")
			assert_encoded ("f", "Zg==")
			assert_encoded ("fo", "Zm8=")
			assert_encoded ("foo", "Zm9v")
			assert_encoded ("foob", "Zm9vYg==")
			assert_encoded ("fooba", "Zm9vYmE=")
			assert_encoded ("foobar", "Zm9vYmFy")
		end

	test_base64_high_bytes_and_utf_8
			-- Bytes over 127 and the last two letters of the alphabet (`+`, `/`); a text is
			-- encoded as UTF-8 first: "é宽" is C3 A9 E5 AE BD, U+1F600 is F0 9F 98 80.
		do
			assert_encoded ("%/0xFF/%/0xFE/%/0xFD/", "//79")
			assert_encoded ("%/0xFB/%/0xEF/", "++8=")
			assert ("utf-8 of e acute and kuan", {BASE64}.encoded_utf_8 ({STRING_32} "%/0xE9/%/0x5BBD/").same_string ("w6nlrr0="))
			assert ("same as its bytes", {BASE64}.encoded ("%/0xC3/%/0xA9/%/0xE5/%/0xAE/%/0xBD/").same_string ("w6nlrr0="))
			assert ("outside the BMP", {BASE64}.encoded_utf_8 ({STRING_32} "%/0x1F600/").same_string ("8J+YgA=="))
			assert ("STRING_8 read as Latin-1", {BASE64}.encoded_utf_8 ("%/0xE9/").same_string ("w6k="))
			assert ("utf-8 count", {BASE64}.utf_8_count ({STRING_32} "a%/0xE9/%/0x5BBD/%/0x1F600/") = 10)
			assert ("not base64: bad length", not {BASE64}.is_encoded ("Zg="))
			assert ("not base64: padding inside", not {BASE64}.is_encoded ("Zg==Zg=="))
			assert ("not base64: alphabet", not {BASE64}.is_encoded ("Zm9-"))
		end


feature -- Base64 decoding (P2b K1)

	test_base64_decodes_rfc4648_vectors
			-- RFC 4648 §10 test vectors decoded, each valid and encoding back to itself;
			-- bytes over 127 and `+`, `/` as well.
		do
			assert_decoded ("", "")
			assert_decoded ("Zg==", "f")
			assert_decoded ("Zm8=", "fo")
			assert_decoded ("Zm9v", "foo")
			assert_decoded ("Zm9vYg==", "foob")
			assert_decoded ("Zm9vYmE=", "fooba")
			assert_decoded ("Zm9vYmFy", "foobar")
			assert_decoded ("//79", "%/0xFF/%/0xFE/%/0xFD/")
			assert_decoded ("++8=", "%/0xFB/%/0xEF/")
			assert_decoded ("AA==", "%/0/")
			assert_decoded ("AAAA", "%/0/%/0/%/0/")
		end

	test_base64_round_trips
			-- `decoded (encoded (x)) ~ x` for every byte value, every length 0 .. 9 of a
			-- run of high and low bytes, and the T3 texts through UTF-8 (ASCII, U+1F600,
			-- CJK, Latin-1, empty).
		local
			l_all, l_run: STRING_8
			i: INTEGER
		do
			create l_all.make (256)
			from i := 0 until i > 255 loop
				l_all.append_character (i.to_character_8)
				assert ("byte " + i.out, {BASE64}.decoded ({BASE64}.encoded (l_all.substring (i + 1, i + 1))) ~ l_all.substring (i + 1, i + 1))
				i := i + 1
			end
			assert ("all 256 bytes", {BASE64}.decoded ({BASE64}.encoded (l_all)) ~ l_all)
			l_run := "%/0xFF/%/0/%/0x80/a%/0x7F/%/0xC3/%/0xA9/+/"
			from i := 0 until i > l_run.count loop
				assert ("prefix of length " + i.out, {BASE64}.decoded ({BASE64}.encoded (l_run.head (i))) ~ l_run.head (i))
				i := i + 1
			end
			assert_text_round_trip ({STRING_32} "foobar")
			assert_text_round_trip ({STRING_32} "Hello, world!")
			assert_text_round_trip ({STRING_32} "%/0x1F600/")
			assert_text_round_trip ({STRING_32} "%/0x5BBD/%/0x5E45/%/0x5B57/%/0x7B26/")
			assert_text_round_trip ({STRING_32} "%/0xE9/%/0x5BBD/")
			assert_text_round_trip ({STRING_32} "a%/0xE9/%/0x5BBD/%/0x1F600/z")
			assert_text_round_trip ({STRING_32} "")
			assert ("emoji text", {BASE64}.decoded_utf_8 ("8J+YgA==").same_string ({STRING_32} "%/0x1F600/"))
			assert ("CJK text", {BASE64}.decoded_utf_8 ("w6nlrr0=").same_string ({STRING_32} "%/0xE9/%/0x5BBD/"))
			assert ("empty text", {BASE64}.decoded_utf_8 ("").is_empty)
		end

	test_base64_rejects_invalid
			-- Strict RFC 4648: bad lengths, padding inside or too long, characters outside
			-- the alphabet (blanks and line breaks too), and non-zero unused bits; `decoded`
			-- and `decoded_utf_8` refuse each through their precondition.
		local
			l_base64: BASE64
			l_c: CHARACTER_8
			i, l_value: INTEGER
		do
			create l_base64
			assert ("empty is valid", {BASE64}.is_valid_encoding (""))
			across <<"Z", "Zg", "Zg=", "Zm9vY", "Zm9vYg=", "Zm9vYmFy=">> as t loop
				assert ("length " + t.count.out + ": " + t, not {BASE64}.is_valid_encoding (t))
			end
			across <<"Zg==Zg==", "Zm=v", "Z=9v", "=m9v", "Zg=a">> as t loop
				assert ("padding inside: " + t, not {BASE64}.is_valid_encoding (t))
			end
			across <<"Z===", "====", "Zg===", "Zm9v====", "Zm9v===A">> as t loop
				assert ("too much padding: " + t, not {BASE64}.is_valid_encoding (t))
			end
			across <<"Zm9-", "Zm9_", "Zm 9", "Zm9v%NYmFy", "Zm9v%R%N", "Zm9v YmFy", "Zm9%T", "Zm9.", "Zm9%/0/", "Zm9%/0xC3/", "Zm9%/0xFF/">> as t loop
				assert ("outside the alphabet: " + t, not {BASE64}.is_valid_encoding (t))
			end
			across <<"QR==", "Zh==", "Zm9=", "Zg9=", "Zm9vYh==", "Zm9vYmF=", "//==", "///=">> as t loop
				assert ("unused bits set: " + t, not {BASE64}.is_valid_encoding (t))
				assert ("still padded base64: " + t, {BASE64}.is_encoded (t))
			end
			assert ("QQ== valid", {BASE64}.is_valid_encoding ("QQ=="))
			assert ("Zm8= valid", {BASE64}.is_valid_encoding ("Zm8="))
				-- Every last character before the padding: valid exactly when its unused
				-- bits are zero, and then the inverse of `encoded`
			across {BASE64}.Alphabet as c loop
				l_c := c
				l_value := {BASE64}.Alphabet.index_of (l_c, 1) - 1
				assert ("one byte, last character " + l_c.out, {BASE64}.is_valid_encoding ("Q" + l_c.out + "==") = (l_value \\ 16 = 0))
				assert ("two bytes, last character " + l_c.out, {BASE64}.is_valid_encoding ("Zm" + l_c.out + "=") = (l_value \\ 4 = 0))
				if {BASE64}.is_valid_encoding ("Q" + l_c.out + "==") then
					assert ("one byte inverse " + l_c.out, {BASE64}.encoded ({BASE64}.decoded ("Q" + l_c.out + "==")).same_string ("Q" + l_c.out + "=="))
				end
			end
				-- Every byte outside the alphabet, in each position of a group
			from i := 0 until i > 255 loop
				l_c := i.to_character_8
				if not {BASE64}.Alphabet.has (l_c) then
					assert ("byte " + i.out + " first", not {BASE64}.is_valid_encoding (l_c.out + "m9v"))
					assert ("byte " + i.out + " last", not {BASE64}.is_valid_encoding ("Zm9" + l_c.out))
					if l_c /= {BASE64}.Padding then
						assert ("byte " + i.out + " before padding", not {BASE64}.is_valid_encoding ("Z" + l_c.out + "=="))
					end
				end
				i := i + 1
			end
			across <<"Zm9vY", "Zg==Zg==", "Z===", "Zm9-", "Zm9v%NYmFy", "QR==">> as t loop
				assert ("decoded refuses " + t, precondition_raised (agent l_base64.decoded (t), "valid_encoding"))
				assert ("decoded_utf_8 refuses " + t, precondition_raised (agent l_base64.decoded_utf_8 (t), "valid_encoding"))
			end
			assert ("valid accepted", not precondition_raised (agent l_base64.decoded ("QQ=="), "valid_encoding"))
		end

	test_base64_utf_8_replacement
			-- Invalid UTF-8 becomes U+FFFD, one per maximal subpart (Unicode §3.9): bytes
			-- that start nothing, overlong forms, surrogates, code points past U+10FFFF,
			-- truncated sequences; decoding goes on at the byte that broke a sequence.
			-- Each case is checked on the bytes and through base64.
		do
				-- The plan's cases: "/w==" is the lone byte FF
			assert ("/w== is FF", {BASE64}.decoded ("/w==").same_string ("%/0xFF/"))
			assert ("/w== replaced", {BASE64}.decoded_utf_8 ("/w==").same_string ({STRING_32} "%/0xFFFD/"))
			assert_utf_8 ("lone FF", "%/0xFF/", {STRING_32} "%/0xFFFD/")
			assert_utf_8 ("FF between letters", "a%/0xFF/b", {STRING_32} "a%/0xFFFD/b")
				-- Bytes that start no sequence: continuation bytes, C0, C1, F5 .. FF
			assert_utf_8 ("lone continuation", "%/0x80/", {STRING_32} "%/0xFFFD/")
			assert_utf_8 ("two continuations", "%/0x80/%/0xBF/", {STRING_32} "%/0xFFFD/%/0xFFFD/")
			assert_utf_8 ("FE FF", "%/0xFE/%/0xFF/", {STRING_32} "%/0xFFFD/%/0xFFFD/")
			assert_utf_8 ("F5 lead", "%/0xF5/%/0x80/%/0x80/%/0x80/", {STRING_32} "%/0xFFFD/%/0xFFFD/%/0xFFFD/%/0xFFFD/")
			assert_utf_8 ("old 5-byte form", "%/0xF8/%/0x88/%/0x80/%/0x80/%/0x80/", {STRING_32} "%/0xFFFD/%/0xFFFD/%/0xFFFD/%/0xFFFD/%/0xFFFD/")
				-- Overlong forms
			assert_utf_8 ("overlong slash C0 AF", "%/0xC0/%/0xAF/", {STRING_32} "%/0xFFFD/%/0xFFFD/")
			assert_utf_8 ("overlong C1 BF", "%/0xC1/%/0xBF/", {STRING_32} "%/0xFFFD/%/0xFFFD/")
			assert_utf_8 ("overlong NUL C0 80", "%/0xC0/%/0x80/", {STRING_32} "%/0xFFFD/%/0xFFFD/")
			assert_utf_8 ("overlong E0 80 AF", "%/0xE0/%/0x80/%/0xAF/", {STRING_32} "%/0xFFFD/%/0xFFFD/%/0xFFFD/")
			assert_utf_8 ("overlong E0 9F BF", "%/0xE0/%/0x9F/%/0xBF/", {STRING_32} "%/0xFFFD/%/0xFFFD/%/0xFFFD/")
			assert_utf_8 ("overlong F0 80 80 AF", "%/0xF0/%/0x80/%/0x80/%/0xAF/", {STRING_32} "%/0xFFFD/%/0xFFFD/%/0xFFFD/%/0xFFFD/")
			assert_utf_8 ("overlong F0 8F BF BF", "%/0xF0/%/0x8F/%/0xBF/%/0xBF/", {STRING_32} "%/0xFFFD/%/0xFFFD/%/0xFFFD/%/0xFFFD/")
				-- Surrogates
			assert_utf_8 ("surrogate D800", "%/0xED/%/0xA0/%/0x80/", {STRING_32} "%/0xFFFD/%/0xFFFD/%/0xFFFD/")
			assert_utf_8 ("surrogate DFFF", "%/0xED/%/0xBF/%/0xBF/", {STRING_32} "%/0xFFFD/%/0xFFFD/%/0xFFFD/")
			assert_utf_8 ("surrogate pair", "%/0xED/%/0xA0/%/0xBD/%/0xED/%/0xB8/%/0x80/", {STRING_32} "%/0xFFFD/%/0xFFFD/%/0xFFFD/%/0xFFFD/%/0xFFFD/%/0xFFFD/")
				-- Past U+10FFFF
			assert_utf_8 ("U+110000", "%/0xF4/%/0x90/%/0x80/%/0x80/", {STRING_32} "%/0xFFFD/%/0xFFFD/%/0xFFFD/%/0xFFFD/")
			assert_utf_8 ("F7 BF BF BF", "%/0xF7/%/0xBF/%/0xBF/%/0xBF/", {STRING_32} "%/0xFFFD/%/0xFFFD/%/0xFFFD/%/0xFFFD/")
				-- Truncated: the start that fits is one U+FFFD, the next byte is read again
			assert_utf_8 ("C3 at the end", "a%/0xC3/", {STRING_32} "a%/0xFFFD/")
			assert_utf_8 ("C3 before a letter", "%/0xC3/A", {STRING_32} "%/0xFFFD/A")
			assert_utf_8 ("E2 82 at the end", "%/0xE2/%/0x82/", {STRING_32} "%/0xFFFD/")
			assert_utf_8 ("E2 82 before a letter", "%/0xE2/%/0x82/A", {STRING_32} "%/0xFFFD/A")
			assert_utf_8 ("F0 9F 98 at the end", "%/0xF0/%/0x9F/%/0x98/", {STRING_32} "%/0xFFFD/")
			assert_utf_8 ("F0 9F 98 before a letter", "%/0xF0/%/0x9F/%/0x98/A", {STRING_32} "%/0xFFFD/A")
			assert_utf_8 ("cut sequence then a whole one", "%/0xE2/%/0x82/%/0xE2/%/0x82/%/0xAC/", {STRING_32} "%/0xFFFD/%/0x20AC/")
			assert_utf_8 ("lead before a lead", "%/0xC3/%/0xC3/%/0xA9/", {STRING_32} "%/0xFFFD/%/0xE9/")
				-- Unicode Table 3-8 (and WHATWG): 61 F1 80 80 E1 80 C2 62 80 63 80 BF 64
			assert_utf_8 ("Unicode table 3-8", "a%/0xF1/%/0x80/%/0x80/%/0xE1/%/0x80/%/0xC2/b%/0x80/c%/0x80/%/0xBF/d",
				{STRING_32} "a%/0xFFFD/%/0xFFFD/%/0xFFFD/b%/0xFFFD/c%/0xFFFD/%/0xFFFD/d")
				-- Valid boundaries are kept, and a real U+FFFD stays one character
			assert_utf_8 ("U+0000 and U+007F", "%/0/%/0x7F/", {STRING_32} "%/0/%/0x7F/")
			assert_utf_8 ("U+0080", "%/0xC2/%/0x80/", {STRING_32} "%/0x80/")
			assert_utf_8 ("U+07FF", "%/0xDF/%/0xBF/", {STRING_32} "%/0x7FF/")
			assert_utf_8 ("U+0800", "%/0xE0/%/0xA0/%/0x80/", {STRING_32} "%/0x800/")
			assert_utf_8 ("U+D7FF", "%/0xED/%/0x9F/%/0xBF/", {STRING_32} "%/0xD7FF/")
			assert_utf_8 ("U+E000", "%/0xEE/%/0x80/%/0x80/", {STRING_32} "%/0xE000/")
			assert_utf_8 ("U+FFFD", "%/0xEF/%/0xBF/%/0xBD/", {STRING_32} "%/0xFFFD/")
			assert_utf_8 ("U+FFFF", "%/0xEF/%/0xBF/%/0xBF/", {STRING_32} "%/0xFFFF/")
			assert_utf_8 ("U+10000", "%/0xF0/%/0x90/%/0x80/%/0x80/", {STRING_32} "%/0x10000/")
			assert_utf_8 ("U+1F600", "%/0xF0/%/0x9F/%/0x98/%/0x80/", {STRING_32} "%/0x1F600/")
			assert_utf_8 ("U+10FFFF", "%/0xF4/%/0x8F/%/0xBF/%/0xBF/", {STRING_32} "%/0x10FFFF/")
			assert_utf_8 ("control characters kept", "a%/9/%/27/%/0x7F/b", {STRING_32} "a%/9/%/27/%/0x7F/b")
			assert_utf_8 ("empty", "", {STRING_32} "")
		end

feature -- Backends

	test_ansi_backend_writes_osc52
			-- Byte-exact OSC 52 for both targets: `ESC ] 52 ; c ; Zm9vYmFy ESC \` and the same
			-- with `p`; a non-ASCII text goes as the base64 of its UTF-8.
		local
			l_backend: ANSI_TERMINAL_BACKEND
			l_sink: STRING_32
		do
			create l_sink.make_empty
			create l_backend.make_with_driver_and_sink (create {FAKE_CONSOLE_DRIVER}, l_sink)
			l_backend.set_clipboard ('c', "foobar")
			assert ("clipboard bytes", l_sink.same_string_general ("%/27/]52;c;Zm9vYmFy%/27/\"))
			l_sink.wipe_out
			l_backend.set_clipboard ('p', "foobar")
			assert ("selection bytes", l_sink.same_string_general ("%/27/]52;p;Zm9vYmFy%/27/\"))
			l_sink.wipe_out
			l_backend.set_clipboard ('c', {STRING_32} "%/0xE9/%/0x5BBD/")
			assert ("utf-8 bytes", l_sink.same_string_general ("%/27/]52;c;w6nlrr0=%/27/\"))
			l_sink.wipe_out
			l_backend.set_clipboard ('c', "")
			assert ("empty text", l_sink.same_string_general ("%/27/]52;c;%/27/\"))
			assert ("other target refused", precondition_raised (agent l_backend.set_clipboard ('s', "x"), "valid_selection"))
		end

	test_virtual_terminal_records_clipboard
			-- VIRTUAL_TERMINAL records each target's text and logs it.
		local
			l_vt: VIRTUAL_TERMINAL
		do
			create l_vt.make (10, 3)
			assert ("nothing yet", l_vt.clipboard_text = Void and l_vt.primary_selection_text = Void)
			l_vt.set_clipboard ('c', "one")
			l_vt.set_clipboard ('p', "two")
			assert ("clipboard", attached l_vt.clipboard_text as t and then t.same_string ({STRING_32} "one"))
			assert ("selection", attached l_vt.primary_selection_text as t and then t.same_string ({STRING_32} "two"))
			assert ("logged", l_vt.operations.has ("set_clipboard(c,one)") and l_vt.operations.has ("set_clipboard(p,two)"))
		end

feature -- Terminal

	test_terminal_copies_both_targets
			-- `copy_to_clipboard` targets `c`, `copy_to_selection` targets `p`.
		local
			l_terminal: TERMINAL [ANSI_TERMINAL_BACKEND]
			l_sink: STRING_32
		do
			l_terminal := new_terminal
			l_sink := sink_of (l_terminal)
			l_terminal.copy_to_clipboard ("foobar")
			l_terminal.copy_to_selection ({STRING_32} "%/0xE9/%/0x5BBD/")
			assert ("bytes [" + l_sink.to_string_8 + "]", l_sink.same_string_general ("%/27/]52;c;Zm9vYmFy%/27/\%/27/]52;p;w6nlrr0=%/27/\"))
		end

	test_fits_in_clipboard_at_the_boundary
			-- The limit counts base64 characters: with 8, 6 bytes (8 characters) fit and 7
			-- (12) do not, whatever the characters; the default is 100 000, which 75 000 ASCII
			-- characters fill exactly.
		local
			l_terminal: TERMINAL [ANSI_TERMINAL_BACKEND]
		do
			l_terminal := new_terminal
			assert ("default limit", l_terminal.clipboard_limit = 100_000 and l_terminal.clipboard_limit = l_terminal.Default_clipboard_limit)
			assert ("75 000 fit", l_terminal.fits_in_clipboard (create {STRING_8}.make_filled ('x', 75_000)))
			assert ("75 001 do not", not l_terminal.fits_in_clipboard (create {STRING_8}.make_filled ('x', 75_001)))
			l_terminal.set_clipboard_limit (8)
			assert ("payload of 6 bytes", l_terminal.clipboard_payload_length ("foobar") = 8)
			assert ("6 bytes fit", l_terminal.fits_in_clipboard ("foobar"))
			assert ("7 bytes do not", not l_terminal.fits_in_clipboard ("foobarb"))
			assert ("5 UTF-8 bytes fit", l_terminal.fits_in_clipboard ({STRING_32} "%/0xE9/%/0x5BBD/"))
			assert ("7 UTF-8 bytes do not", not l_terminal.fits_in_clipboard ({STRING_32} "%/0xE9/%/0x5BBD/%/0xE9/"))
			assert ("empty fits", l_terminal.fits_in_clipboard (""))
			assert ("limit under one group refused", precondition_raised (agent l_terminal.set_clipboard_limit (3), "room_for_one_group"))
		end

	test_copy_over_the_limit_raises
			-- The cap is a precondition of both copies, and nothing is written.
		local
			l_terminal: TERMINAL [ANSI_TERMINAL_BACKEND]
		do
			l_terminal := new_terminal
			l_terminal.set_clipboard_limit (8)
			assert ("clipboard refused", precondition_raised (agent l_terminal.copy_to_clipboard ("foobarb"), "fits"))
			assert ("selection refused", precondition_raised (agent l_terminal.copy_to_selection ("foobarb"), "fits"))
			assert ("nothing written", sink_of (l_terminal).is_empty)
			assert ("at the limit accepted", not precondition_raised (agent l_terminal.copy_to_clipboard ("foobar"), "fits"))
		end

	test_clipboard_prefix_keeps_graphemes
			-- With a limit of 8 (6 bytes), the prefix stops before a cluster that would pass
			-- the limit, never inside it.
		local
			l_terminal: TERMINAL [ANSI_TERMINAL_BACKEND]
		do
			l_terminal := new_terminal
			l_terminal.set_clipboard_limit (8)
			assert ("ASCII cut", l_terminal.clipboard_prefix ("abcdefgh").same_string ({STRING_32} "abcdef"))
			assert ("fits whole", l_terminal.clipboard_prefix ("abc").same_string ({STRING_32} "abc"))
				-- "e" + U+0301 is one cluster of 3 bytes: 4 + 3 > 6, and "abcde" would cut it
			assert ("combining mark kept with its base", l_terminal.clipboard_prefix ({STRING_32} "abcde%/0x301/x").same_string ({STRING_32} "abcd"))
			assert ("wide characters", l_terminal.clipboard_prefix ({STRING_32} "%/0x5BBD/%/0x5BBD/%/0x5BBD/").same_string ({STRING_32} "%/0x5BBD/%/0x5BBD/"))
			l_terminal.set_clipboard_limit (4)
			assert ("one cluster over the limit", l_terminal.clipboard_prefix ({STRING_32} "%/0x1F600/").is_empty)
			assert ("empty", l_terminal.clipboard_prefix ("").is_empty)
		end

feature -- Text area

	test_selected_text
			-- The selection's text, newlines included, whichever end the cursor is at; empty
			-- without a selection.
		local
			l_state: TEXT_AREA_STATE
		do
			create l_state.make_with_text ({STRING_32} "ab%Ncd")
			assert ("no selection", l_state.selected_text.is_empty)
			l_state.move_cursor_left (True)
			l_state.move_cursor_left (True)
			l_state.move_cursor_left (True)
			assert ("backwards over a newline", l_state.selected_text.same_string ({STRING_32} "%Ncd"))
			l_state.select_all
			assert ("all", l_state.selected_text.same_string ({STRING_32} "ab%Ncd"))
			l_state.move_cursor_home (False)
			assert ("cleared by a move", l_state.selected_text.is_empty)
		end

feature -- Example

	test_example_text_area_copies_selection
			-- EXAMPLE_TEXT_AREA run on a fake console with an output sink: Ctrl+A, Ctrl+C
			-- writes one OSC 52 with the whole text, and the status line says so.
		local
			l_app: TEXT_AREA_SCRIPTED_APP
			l_sink: STRING_32
			l_text: STRING_32
		do
			l_app := new_example ("%/1/%/3/", 2)
			l_sink := app_sink (l_app)
			l_text := {STRING_32} "Hello from TEXT_AREA%NType here. Ctrl+Z undoes, Ctrl+Y redoes.%N"
			l_app.run
			assert ("both keys processed", l_app.presses = 2)
			assert ("all selected", l_app.selected_text.same_string (l_text))
			assert ("one OSC 52", occurrences (l_sink, {STRING_32} "%/27/]52;") = 1)
			assert ("the whole text", l_sink.has_substring (osc52 (l_text)))
			assert ("status", l_app.status_line.same_string ({STRING_32} "Copied " + l_text.count.out + " characters."))
		end

	test_example_text_area_copy_without_selection
			-- Ctrl+C with nothing selected writes no OSC 52, and does not quit (the next key,
			-- a letter, is still processed).
		local
			l_app: TEXT_AREA_SCRIPTED_APP
			l_sink: STRING_32
		do
			l_app := new_example ("%/3/x", 2)
			l_sink := app_sink (l_app)
			l_app.run
			assert ("both keys processed", l_app.presses = 2)
			assert ("no OSC 52", not l_sink.has_substring ({STRING_32} "%/27/]52;"))
			assert ("status", l_app.status_line.same_string ({STRING_32} "Nothing selected: nothing copied."))
		end

	test_example_text_area_truncates_long_selection
			-- With a limit of 8 base64 characters (6 bytes), the example copies "Hello " and
			-- says how much of the selection it copied.
		local
			l_app: TEXT_AREA_SCRIPTED_APP
			l_sink: STRING_32
		do
			l_app := new_example ("%/1/%/3/", 2)
			l_sink := app_sink (l_app)
			l_app.terminal.set_clipboard_limit (8)
			l_app.run
			assert ("first 6 characters", l_sink.has_substring ({STRING_32} "%/27/]52;c;SGVsbG8g%/27/\"))
			assert ("one OSC 52", occurrences (l_sink, {STRING_32} "%/27/]52;") = 1)
			assert ("status", l_app.status_line.same_string ({STRING_32} "Selection too long: copied the first 6 of " + l_app.selected_text.count.out + " characters."))
		end

	test_empty_copy_refused
			-- P2 T3 review #4: an empty copy is refused (xterm clears the clipboard on an
			-- empty OSC 52 payload), for both targets.
		local
			l_terminal: TERMINAL [ANSI_TERMINAL_BACKEND]
		do
			l_terminal := new_terminal
			assert ("clipboard refused", precondition_raised (agent l_terminal.copy_to_clipboard (""), "not_empty"))
			assert ("selection refused", precondition_raised (agent l_terminal.copy_to_selection (""), "not_empty"))
			assert ("nothing written", attached l_terminal.backend.output_sink as s and then s.is_empty)
		end

	test_example_text_area_copies_nothing_when_nothing_fits
			-- P2 T3 review #4: with a limit of 4 base64 characters (3 bytes), a selection that
			-- starts with a 4-byte character has an empty `clipboard_prefix`. The example then
			-- sends no OSC 52 (an empty one would clear the clipboard) and says so. Keys: U+1F600
			-- typed as UTF-8, Shift+Left to select it, Ctrl+C.
		local
			l_app: TEXT_AREA_SCRIPTED_APP
			l_sink: STRING_32
		do
			l_app := new_example ("%/240/%/159/%/152/%/128/%/27/[1;2D%/3/", 3)
			l_sink := app_sink (l_app)
			l_app.terminal.set_clipboard_limit (4)
			l_app.run
			assert ("the emoji selected", l_app.selected_text.same_string ({STRING_32} "%/0x1F600/"))
			assert ("nothing fits", l_app.terminal.clipboard_prefix (l_app.selected_text).is_empty)
			assert ("no OSC 52", occurrences (l_sink, {STRING_32} "%/27/]52;") = 0)
			assert ("status", l_app.status_line.same_string ({STRING_32} "Selection too long: nothing copied."))
		end

feature {NONE} -- Helpers

	assert_decoded (a_text, a_expected: STRING_8)
			-- Check that the base64 `a_text` is valid, decodes to `a_expected`, and that
			-- `a_expected` encodes back to `a_text`.
		local
			l_result: STRING_8
		do
			assert ("valid [" + a_text + "]", {BASE64}.is_valid_encoding (a_text))
			l_result := {BASE64}.decoded (a_text)
			assert ("decoded [" + a_text + "]", l_result ~ a_expected)
			assert ("encodes back [" + a_text + "]", {BASE64}.encoded (a_expected).same_string (a_text))
		end

	assert_text_round_trip (a_text: STRING_32)
			-- Check that `a_text` encoded as UTF-8 base64 decodes back to itself.
		local
			l_encoded: STRING_8
		do
			l_encoded := {BASE64}.encoded_utf_8 (a_text)
			assert ("valid base64 of [" + a_text.count.out + " characters]", {BASE64}.is_valid_encoding (l_encoded))
			assert ("text round trip of " + l_encoded, {BASE64}.decoded_utf_8 (l_encoded) ~ a_text)
			assert ("bytes round trip of " + l_encoded, {BASE64}.encoded ({BASE64}.decoded (l_encoded)).same_string (l_encoded))
		end

	assert_utf_8 (a_tag: STRING; a_bytes: STRING_8; a_expected: STRING_32)
			-- Check that `a_bytes` read as UTF-8 is `a_expected`, both directly and as the
			-- base64 of `a_bytes`.
		do
			assert (a_tag + ": bytes", {BASE64}.utf_8_text (a_bytes).same_string (a_expected))
			assert (a_tag + ": through base64", {BASE64}.decoded_utf_8 ({BASE64}.encoded (a_bytes)).same_string (a_expected))
		end

	assert_encoded (a_bytes, a_expected: STRING_8)
			-- Check that `a_bytes` encodes to `a_expected`, as valid padded base64.
		local
			l_result: STRING_8
		do
			l_result := {BASE64}.encoded (a_bytes)
			assert ("base64 of [" + a_bytes + "] is " + a_expected + ", got " + l_result, l_result.same_string (a_expected))
			assert ("length of [" + a_bytes + "]", l_result.count = {BASE64}.encoded_length (a_bytes.count))
			assert ("valid [" + a_bytes + "]", {BASE64}.is_encoded (l_result))
		end

	osc52 (a_text: READABLE_STRING_GENERAL): STRING_32
			-- `ESC ] 52 ; c ; base64 ESC \` for `a_text`
		do
			Result := {STRING_32} "%/27/]52;c;" + {BASE64}.encoded_utf_8 (a_text).to_string_32 + {STRING_32} "%/27/\"
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

	new_example (a_input: READABLE_STRING_8; a_presses: INTEGER): TEXT_AREA_SCRIPTED_APP
			-- EXAMPLE_TEXT_AREA on a fake console replaying `a_input`, output captured,
			-- stopping after `a_presses` key presses.
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
			create Result.make_scripted (create {TERMINAL [ANSI_TERMINAL_BACKEND]}.make (l_backend), a_presses)
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
