note
	description: "[
		Strict UTF-8 input decoding in ANSI_INPUT_PARSER (review finding U4), after Unicode 16.0
		section 3.9 (table 3-7 for the well-formed byte sequences, table 3-8 for U+FFFD per
		maximal subpart):
		- the boundaries of every well-formed range decode
		- overlongs, surrogates, values above U+10FFFF, bad lead bytes, stray continuation
		  bytes and truncated sequences become U+FFFD, one per maximal subpart
		- an overlong ESC cannot end a bracketed paste
		- a character split by a pause in a paste is kept; one left unfinished becomes U+FFFD
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_UTF_8_INPUT

inherit
	EQA_TEST_SET

feature -- Well-formed

	test_well_formed_boundaries
			-- The first and last code point of every row of table 3-7 decode.
		do
			assert_decodes (<<0x7E>>, <<0x7E>>, "U+007E (U+007F is Backspace)")
			assert_decodes (<<0xC2, 0x80>>, <<0x80>>, "U+0080")
			assert_decodes (<<0xDF, 0xBF>>, <<0x7FF>>, "U+07FF")
			assert_decodes (<<0xE0, 0xA0, 0x80>>, <<0x800>>, "U+0800")
			assert_decodes (<<0xEC, 0xBF, 0xBF>>, <<0xCFFF>>, "U+CFFF")
			assert_decodes (<<0xED, 0x80, 0x80>>, <<0xD000>>, "U+D000")
			assert_decodes (<<0xED, 0x9F, 0xBF>>, <<0xD7FF>>, "U+D7FF")
			assert_decodes (<<0xEE, 0x80, 0x80>>, <<0xE000>>, "U+E000")
			assert_decodes (<<0xEF, 0xBF, 0xBD>>, <<0xFFFD>>, "U+FFFD itself")
			assert_decodes (<<0xEF, 0xBF, 0xBF>>, <<0xFFFF>>, "U+FFFF")
			assert_decodes (<<0xF0, 0x90, 0x80, 0x80>>, <<0x10000>>, "U+10000")
			assert_decodes (<<0xF3, 0xBF, 0xBF, 0xBF>>, <<0xFFFFF>>, "U+FFFFF")
			assert_decodes (<<0xF4, 0x80, 0x80, 0x80>>, <<0x100000>>, "U+100000")
			assert_decodes (<<0xF4, 0x8F, 0xBF, 0xBF>>, <<0x10FFFF>>, "U+10FFFF")
		end

feature -- Ill-formed

	test_unicode_table_3_8_example
			-- The example of table 3-8: 61 F1 80 80 E1 80 C2 62 80 63 80 BF 64
			-- gives a FFFD FFFD FFFD b FFFD c FFFD FFFD d.
		do
			assert_decodes (<<0x61, 0xF1, 0x80, 0x80, 0xE1, 0x80, 0xC2, 0x62, 0x80, 0x63, 0x80, 0xBF, 0x64>>,
				<<0x61, 0xFFFD, 0xFFFD, 0xFFFD, 0x62, 0xFFFD, 0x63, 0xFFFD, 0xFFFD, 0x64>>, "table 3-8")
		end

	test_overlongs_rejected
			-- Overlong forms never decode, one U+FFFD per byte (no lead accepts their second byte).
		do
			assert_decodes (<<0xC0, 0x80>>, <<0xFFFD, 0xFFFD>>, "C0 80 (U+0000)")
			assert_decodes (<<0xC1, 0xBF>>, <<0xFFFD, 0xFFFD>>, "C1 BF (U+007F)")
			assert_decodes (<<0xE0, 0x80, 0x9B>>, <<0xFFFD, 0xFFFD, 0xFFFD>>, "E0 80 9B (ESC)")
			assert_decodes (<<0xE0, 0x9F, 0xBF>>, <<0xFFFD, 0xFFFD, 0xFFFD>>, "E0 9F BF (U+07FF)")
			assert_decodes (<<0xF0, 0x80, 0x80, 0x80>>, <<0xFFFD, 0xFFFD, 0xFFFD, 0xFFFD>>, "F0 80 80 80")
			assert_decodes (<<0xF0, 0x8F, 0xBF, 0xBF>>, <<0xFFFD, 0xFFFD, 0xFFFD, 0xFFFD>>, "F0 8F BF BF (U+FFFF)")
		end

	test_surrogates_rejected
			-- Encoded surrogates never decode.
		do
			assert_decodes (<<0xED, 0xA0, 0x80>>, <<0xFFFD, 0xFFFD, 0xFFFD>>, "ED A0 80 (U+D800)")
			assert_decodes (<<0xED, 0xBF, 0xBF>>, <<0xFFFD, 0xFFFD, 0xFFFD>>, "ED BF BF (U+DFFF)")
			assert_decodes (<<0xED, 0xA0, 0xBD, 0xED, 0xB8, 0x80>>, <<0xFFFD, 0xFFFD, 0xFFFD, 0xFFFD, 0xFFFD, 0xFFFD>>, "CESU-8 pair")
		end

	test_above_u10ffff_rejected
			-- Values above U+10FFFF and lead bytes that never occur in UTF-8 do not decode.
		do
			assert_decodes (<<0xF4, 0x90, 0x80, 0x80>>, <<0xFFFD, 0xFFFD, 0xFFFD, 0xFFFD>>, "F4 90 80 80 (U+110000)")
			assert_decodes (<<0xF5, 0x80, 0x80, 0x80>>, <<0xFFFD, 0xFFFD, 0xFFFD, 0xFFFD>>, "F5 lead")
			assert_decodes (<<0xF8, 0x88, 0x80, 0x80, 0x80>>, <<0xFFFD, 0xFFFD, 0xFFFD, 0xFFFD, 0xFFFD>>, "5-byte form")
			assert_decodes (<<0xFE>>, <<0xFFFD>>, "FE")
			assert_decodes (<<0xFF>>, <<0xFFFD>>, "FF")
		end

	test_stray_continuation_bytes
			-- A continuation byte without a lead is U+FFFD, never a C1 control key.
		do
			assert_decodes (<<0x80>>, <<0xFFFD>>, "80")
			assert_decodes (<<0x9B>>, <<0xFFFD>>, "9B (would be the 8-bit CSI)")
			assert_decodes (<<0xBF, 0xBF, 0x41>>, <<0xFFFD, 0xFFFD, 0x41>>, "BF BF A")
			assert_decodes (<<0xC3, 0xB1, 0xB1>>, <<0xF1, 0xFFFD>>, "one continuation too many")
		end

	test_truncated_sequences
			-- A sequence cut short is one U+FFFD: when the next byte breaks it, or when the
			-- input pauses (notify_idle).
		do
			assert_decodes (<<0xF0, 0x9F, 0x98, 0x61>>, <<0xFFFD, 0x61>>, "F0 9F 98 a")
			assert_decodes (<<0xE6, 0x97, 0xE6, 0x97, 0xA5>>, <<0xFFFD, 0x65E5>>, "E6 97 then a whole character")
			assert_decodes (<<0xE6, 0x97>>, <<0xFFFD>>, "E6 97 at the end of the input")
			assert_decodes (<<0xC3>>, <<0xFFFD>>, "C3 at the end of the input")
		end

	test_decoded_code_points
			-- A code above 255 is an already decoded character: a scalar value is kept, a
			-- surrogate becomes U+FFFD, and a pending sequence is replaced first.
		do
			assert_decodes (<<0x65E5>>, <<0x65E5>>, "U+65E5")
			assert_decodes (<<0xD800>>, <<0xFFFD>>, "U+D800")
			assert_decodes (<<0x110000>>, <<0xFFFD>>, "U+110000")
			assert_decodes (<<0xE6, 0x65E5>>, <<0xFFFD, 0x65E5>>, "E6 then U+65E5")
		end

feature -- Bracketed paste

	test_overlong_esc_does_not_end_paste
			-- The review's probe: `ESC[200~safe` E0 80 9B `[201~rm` ESC[201~ is one paste
			-- holding the whole text, and no key event.
		local
			l_parser: ANSI_INPUT_PARSER
			l_expected: STRING_32
		do
			create l_parser.make
			feed (l_parser, "%/27/[200~safe")
			feed_codes (l_parser, <<0xE0, 0x80, 0x9B>>)
			feed (l_parser, "[201~rm%/27/[201~")
			l_expected := {STRING_32} "safe"
			l_expected.append (codes (<<0xFFFD, 0xFFFD, 0xFFFD>>))
			l_expected.append ({STRING_32} "[201~rm")
			assert ("one event", l_parser.events.count = 1)
			assert ("whole text pasted", attached {PASTE_EVENT} l_parser.events.first as p and then p.text.same_string (l_expected))
			assert ("paste ended by the real marker", not l_parser.is_in_paste)
		end

	test_paste_keeps_character_split_by_pause
			-- A character whose bytes are split by a pause inside a paste is kept whole.
		local
			l_parser: ANSI_INPUT_PARSER
		do
			create l_parser.make
			feed (l_parser, "%/27/[200~a")
			feed_codes (l_parser, <<0xE6, 0x97>>)
			l_parser.notify_idle (50)
			feed_codes (l_parser, <<0xA5>>)
			feed (l_parser, "b%/27/[201~")
			assert ("one event", l_parser.events.count = 1)
			assert ("character kept", attached {PASTE_EVENT} l_parser.events.first as p and then
				p.text.same_string (codes (<<0x61, 0x65E5, 0x62>>)))
		end

	test_paste_watchdog_replaces_unfinished_character
			-- When the paste watchdog ends a paste in the middle of a character, the character
			-- becomes U+FFFD at the end of the text, and the next key decodes normally.
		local
			l_parser: ANSI_INPUT_PARSER
		do
			create l_parser.make
			feed (l_parser, "%/27/[200~ab")
			feed_codes (l_parser, <<0xF0, 0x9F>>)
			l_parser.notify_idle (l_parser.paste_timeout_ms)
			assert ("paste ended", not l_parser.is_in_paste)
			assert ("one event", l_parser.events.count = 1)
			assert ("unfinished character replaced", attached {PASTE_EVENT} l_parser.events.first as p and then
				p.text.same_string (codes (<<0x61, 0x62, 0xFFFD>>)))
			l_parser.wipe_out
			feed (l_parser, "q")
			assert ("next key", l_parser.events.count = 1 and then attached {KEY_EVENT} l_parser.events.first as k and then
				(k.code.is_char and then k.code.character = 'q'))
		end

feature {NONE} -- Helpers

	assert_decodes (a_bytes, a_expected: ARRAY [NATURAL_32]; a_tag: STRING)
			-- Assert that feeding `a_bytes` to a new parser, then a pause, gives one character
			-- key per code point of `a_expected`, in order.
		local
			l_parser: ANSI_INPUT_PARSER
			l_keys: STRING_32
		do
			create l_parser.make
			feed_codes (l_parser, a_bytes)
			l_parser.notify_idle (50)
			create l_keys.make (a_expected.count)
			across l_parser.events as e loop
				if attached {KEY_EVENT} e as k and then k.code.is_char then
					l_keys.append_character (k.code.character)
				else
					l_keys.append_code (0)
				end
			end
			assert (a_tag, l_keys.same_string (codes (a_expected)))
		end

	feed (a_parser: ANSI_INPUT_PARSER; a_ascii: STRING_8)
			-- Feed the bytes of `a_ascii` to `a_parser`.
		do
			a_parser.parse_string (a_ascii)
		end

	feed_codes (a_parser: ANSI_INPUT_PARSER; a_codes: ARRAY [NATURAL_32])
			-- Feed `a_codes` to `a_parser`, one `parse_code` each.
		do
			across a_codes as c loop
				a_parser.parse_code (c)
			end
		end

	codes (a_codes: ARRAY [NATURAL_32]): STRING_32
			-- String of the code points `a_codes`
		do
			create Result.make (a_codes.count)
			across a_codes as c loop
				Result.append_code (c)
			end
		end

end
