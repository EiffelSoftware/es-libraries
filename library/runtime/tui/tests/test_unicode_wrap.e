note
	description: "[
		Grapheme-aware character wrapping (review finding U1) and word wrapping (U2):
		- words are measured by grapheme cluster: VS16 emoji are not under-counted, and
		  ZWJ / skin-tone emoji are not over-counted
		- combining marks, VS16, ZWJ sequences and flags are never dropped
		- lines break only between grapheme clusters
		- every wrapped line fits the width, and the lines concatenate back to the input,
		  code point for code point
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_UNICODE_WRAP

inherit
	EQA_TEST_SET

feature -- Character wrap

	test_character_wrap_keeps_combining_marks
			-- "café" written with U+0301 keeps the accent, and the accent stays with its "e".
		local
			l_text: STRING_32
			l_wrapped: ARRAYED_LIST [TEXT_LINE]
		do
			l_text := codes (<<0x63, 0x61, 0x66, 0x65, 0x301>>)
			l_wrapped := character_wrap (l_text, 10)
			assert ("one line", l_wrapped.count = 1)
			assert ("accent kept", l_wrapped.first.to_plain_string.same_string (l_text))
			assert ("width 4", l_wrapped.first.width = 4)

			l_wrapped := character_wrap (l_text, 2)
			assert ("two lines", l_wrapped.count = 2)
			assert ("line 1", l_wrapped.i_th (1).to_plain_string.same_string (codes (<<0x63, 0x61>>)))
			assert ("line 2 keeps accent on e", l_wrapped.i_th (2).to_plain_string.same_string (codes (<<0x66, 0x65, 0x301>>)))
			assert_round_trip ("cafe", l_text)
		end

	test_character_wrap_keeps_vs16
			-- Two "❤️" (U+2764 U+FE0F, 2 columns each) in 3 columns: one heart per line, VS16 kept.
		local
			l_heart: STRING_32
			l_wrapped: ARRAYED_LIST [TEXT_LINE]
		do
			l_heart := codes (<<0x2764, 0xFE0F>>)
			l_wrapped := character_wrap (l_heart + l_heart, 3)
			assert ("two lines", l_wrapped.count = 2)
			assert ("line 1 is a heart", l_wrapped.i_th (1).to_plain_string.same_string (l_heart))
			assert ("line 2 is a heart", l_wrapped.i_th (2).to_plain_string.same_string (l_heart))
			assert ("heart width 2", l_wrapped.i_th (1).width = 2)
		end

	test_character_wrap_keeps_zwj_sequence
			-- A ZWJ family (2 columns) is kept whole and not split into separate emoji.
		local
			l_family: STRING_32
			l_wrapped: ARRAYED_LIST [TEXT_LINE]
		do
			l_family := codes (<<0x1F468, 0x200D, 0x1F469, 0x200D, 0x1F467>>)
			l_wrapped := character_wrap (l_family + {STRING_32} "ab", 2)
			assert ("two lines", l_wrapped.count = 2)
			assert ("family whole", l_wrapped.i_th (1).to_plain_string.same_string (l_family))
			assert ("family width 2", l_wrapped.i_th (1).width = 2)
			assert ("ab on line 2", l_wrapped.i_th (2).to_plain_string.same_string_general ("ab"))
		end

	test_character_wrap_keeps_flags_whole
			-- Regional indicator pairs are not split across lines.
		local
			l_jp, l_us: STRING_32
			l_wrapped: ARRAYED_LIST [TEXT_LINE]
		do
			l_jp := codes (<<0x1F1EF, 0x1F1F5>>)
			l_us := codes (<<0x1F1FA, 0x1F1F8>>)
			l_wrapped := character_wrap (l_jp + l_us, 3)
			assert ("two lines", l_wrapped.count = 2)
			assert ("flag 1", l_wrapped.i_th (1).to_plain_string.same_string (l_jp))
			assert ("flag 2", l_wrapped.i_th (2).to_plain_string.same_string (l_us))
		end

	test_character_wrap_round_trip
			-- At several widths, wrapped lines fit and concatenate back to the input.
		do
			assert_round_trip ("devanagari", codes (<<0x928, 0x92E, 0x938, 0x94D, 0x924, 0x947>>))
			assert_round_trip ("skin tone", codes (<<0x1F44D, 0x1F3FD, 0x61, 0x1F44D, 0x1F3FD>>))
			assert_round_trip ("mixed", codes (<<0x41, 0x301, 0x20, 0x4E2D, 0x2764, 0xFE0F, 0x1F468, 0x200D, 0x1F469, 0x62, 0x1F1EF, 0x1F1F5>>))
			assert_round_trip ("leading mark", codes (<<0x301, 0x61, 0x62>>))
		end

	test_character_wrap_trims_leading_space
			-- With trim, a space starting a continuation line is still skipped.
		local
			l_wrapped: ARRAYED_LIST [TEXT_LINE]
		do
			l_wrapped := {TEXT_LAYOUT}.wrap_line (create {TEXT_LINE}.make_raw ("abc def"), 3, {TEXT_WRAP_MODE}.character, True)
			assert ("two lines", l_wrapped.count = 2)
			assert ("line 1", l_wrapped.i_th (1).to_plain_string.same_string_general ("abc"))
			assert ("line 2 trimmed", l_wrapped.i_th (2).to_plain_string.same_string_general ("def"))
		end

	test_character_wrap_across_spans
			-- Clusters in several styled spans keep their marks and their styles.
		local
			l_line: TEXT_LINE
			l_red, l_blue: STYLE
			l_wrapped: ARRAYED_LIST [TEXT_LINE]
		do
			create l_red.make_fg ({COLOR}.red)
			create l_blue.make_fg ({COLOR}.blue)
			create l_line.make_empty
			l_line.append_span (create {TEXT_SPAN}.make (codes (<<0x61, 0x65, 0x301>>), l_red))
			l_line.append_span (create {TEXT_SPAN}.make (codes (<<0x2764, 0xFE0F, 0x62>>), l_blue))
			l_wrapped := {TEXT_LAYOUT}.wrap_line (l_line, 3, {TEXT_WRAP_MODE}.character, False)
			assert ("two lines", l_wrapped.count = 2)
			assert ("line 1 text", l_wrapped.i_th (1).to_plain_string.same_string (codes (<<0x61, 0x65, 0x301>>)))
			assert ("line 1 red", l_wrapped.i_th (1).spans.first.style.is_equal (l_red))
			assert ("line 2 text", l_wrapped.i_th (2).to_plain_string.same_string (codes (<<0x2764, 0xFE0F, 0x62>>)))
			assert ("line 2 blue", l_wrapped.i_th (2).spans.first.style.is_equal (l_blue))
		end

feature -- Word wrap

	test_word_wrap_vs16_not_under_counted
			-- "❤️❤️" is 4 columns, not 2: in 3 columns it is split, one heart per line, VS16 kept.
		local
			l_heart: STRING_32
			l_wrapped: ARRAYED_LIST [TEXT_LINE]
		do
			l_heart := codes (<<0x2764, 0xFE0F>>)
			l_wrapped := word_wrap (l_heart + l_heart, 3)
			assert ("two lines", l_wrapped.count = 2)
			assert ("line 1 is a heart", l_wrapped.i_th (1).to_plain_string.same_string (l_heart))
			assert ("line 2 is a heart", l_wrapped.i_th (2).to_plain_string.same_string (l_heart))
		end

	test_word_wrap_emoji_not_over_counted
			-- A ZWJ family and a skin-tone emoji are 2 columns each, so short lines hold them.
		local
			l_family, l_thumb: STRING_32
			l_wrapped: ARRAYED_LIST [TEXT_LINE]
		do
			l_family := codes (<<0x1F468, 0x200D, 0x1F469, 0x200D, 0x1F467>>)
			l_wrapped := word_wrap (l_family + {STRING_32} " ab", 5)
			assert ("family fits one line", l_wrapped.count = 1)
			assert ("family line text", l_wrapped.first.to_plain_string.same_string (l_family + {STRING_32} " ab"))
			assert ("family line width 5", l_wrapped.first.width = 5)

			l_thumb := codes (<<0x1F44D, 0x1F3FD>>)
			l_wrapped := word_wrap (l_thumb + {STRING_32} " x", 4)
			assert ("thumb fits one line", l_wrapped.count = 1)
			assert ("thumb line text", l_wrapped.first.to_plain_string.same_string (l_thumb + {STRING_32} " x"))
		end

	test_word_wrap_oversized_keeps_zwj
			-- A word wider than the line is split between clusters; ZWJ sequences stay whole.
		local
			l_family: STRING_32
			l_wrapped: ARRAYED_LIST [TEXT_LINE]
		do
			l_family := codes (<<0x1F468, 0x200D, 0x1F469, 0x200D, 0x1F467>>)
			l_wrapped := word_wrap (l_family + l_family + l_family, 4)
			assert ("two lines", l_wrapped.count = 2)
			assert ("line 1 two families", l_wrapped.i_th (1).to_plain_string.same_string (l_family + l_family))
			assert ("line 1 width 4", l_wrapped.i_th (1).width = 4)
			assert ("line 2 one family", l_wrapped.i_th (2).to_plain_string.same_string (l_family))
		end

	test_word_wrap_keeps_combining_marks
			-- Accented words written with combining marks wrap at the space, marks kept,
			-- also when a word has to be split.
		local
			l_cafe, l_creme: STRING_32
			l_wrapped: ARRAYED_LIST [TEXT_LINE]
		do
			l_cafe := codes (<<0x63, 0x61, 0x66, 0x65, 0x301>>)
			l_creme := codes (<<0x63, 0x72, 0x65, 0x300, 0x6D, 0x65>>)
			l_wrapped := word_wrap (l_cafe + {STRING_32} " " + l_creme, 5)
			assert ("two lines", l_wrapped.count = 2)
			assert ("line 1 cafe", l_wrapped.i_th (1).to_plain_string.same_string (l_cafe))
			assert ("line 2 creme", l_wrapped.i_th (2).to_plain_string.same_string (l_creme))

			l_wrapped := word_wrap (l_creme, 3)
			assert ("split in two", l_wrapped.count = 2)
			assert ("split line 1 keeps grave", l_wrapped.i_th (1).to_plain_string.same_string (codes (<<0x63, 0x72, 0x65, 0x300>>)))
			assert ("split line 2", l_wrapped.i_th (2).to_plain_string.same_string_general ("me"))
		end

	test_word_wrap_keeps_flags_whole
			-- Flags in an oversized word are not split into lone regional indicators.
		local
			l_jp, l_us: STRING_32
			l_wrapped: ARRAYED_LIST [TEXT_LINE]
		do
			l_jp := codes (<<0x1F1EF, 0x1F1F5>>)
			l_us := codes (<<0x1F1FA, 0x1F1F8>>)
			l_wrapped := word_wrap (l_jp + l_us, 3)
			assert ("two lines", l_wrapped.count = 2)
			assert ("flag 1", l_wrapped.i_th (1).to_plain_string.same_string (l_jp))
			assert ("flag 2", l_wrapped.i_th (2).to_plain_string.same_string (l_us))
		end

	test_word_wrap_round_trip
			-- At several widths, word-wrapped lines of text without spaces fit and concatenate
			-- back to the input (this goes through the oversized-word split).
		do
			assert_round_trip_in_mode ("devanagari", codes (<<0x928, 0x92E, 0x938, 0x94D, 0x924, 0x947>>), {TEXT_WRAP_MODE}.word)
			assert_round_trip_in_mode ("skin tone", codes (<<0x1F44D, 0x1F3FD, 0x61, 0x1F44D, 0x1F3FD>>), {TEXT_WRAP_MODE}.word)
			assert_round_trip_in_mode ("mixed", codes (<<0x41, 0x301, 0x4E2D, 0x2764, 0xFE0F, 0x1F468, 0x200D, 0x1F469, 0x62, 0x1F1EF, 0x1F1F5>>), {TEXT_WRAP_MODE}.word)
			assert_round_trip_in_mode ("leading mark", codes (<<0x301, 0x61, 0x62>>), {TEXT_WRAP_MODE}.word)
		end

feature -- Cluster split across spans

	test_wrap_same_style_spans_split_vs16
			-- "ab❤" + VS16 in two spans of one style become one 4-column line when merged, so
			-- both modes must measure the merged text: in 3 columns the heart goes to line 2.
		local
			l_line: TEXT_LINE
			l_style: STYLE
			l_wrapped: ARRAYED_LIST [TEXT_LINE]
			l_mode: NATURAL_8
		do
			create l_style.make_fg ({COLOR}.green)
			across
				<<{TEXT_WRAP_MODE}.character, {TEXT_WRAP_MODE}.word>> as m
			loop
				l_mode := m
				create l_line.make_empty
				l_line.append_span (create {TEXT_SPAN}.make (codes (<<0x61, 0x62, 0x2764>>), l_style))
				l_line.append_span (create {TEXT_SPAN}.make (codes (<<0xFE0F>>), l_style))
				l_wrapped := {TEXT_LAYOUT}.wrap_line (l_line, 3, l_mode, True)
				assert ("two lines, mode " + l_mode.out, l_wrapped.count = 2)
				assert ("line 1 ab, mode " + l_mode.out, l_wrapped.i_th (1).to_plain_string.same_string_general ("ab"))
				assert ("line 2 heart, mode " + l_mode.out, l_wrapped.i_th (2).to_plain_string.same_string (codes (<<0x2764, 0xFE0F>>)))
				across
					l_wrapped as l
				loop
					assert ("line fits, mode " + l_mode.out, l.width <= 3)
				end
			end
		end

	test_wrap_same_style_spans_split_zwj
			-- A ZWJ pair split over two spans of one style is one 2-column cluster: it is not
			-- broken across lines in 2 columns.
		local
			l_line: TEXT_LINE
			l_style: STYLE
			l_wrapped: ARRAYED_LIST [TEXT_LINE]
			l_mode: NATURAL_8
		do
			create l_style.make_fg ({COLOR}.green)
			across
				<<{TEXT_WRAP_MODE}.character, {TEXT_WRAP_MODE}.word>> as m
			loop
				l_mode := m
				create l_line.make_empty
				l_line.append_span (create {TEXT_SPAN}.make (codes (<<0x1F468, 0x200D>>), l_style))
				l_line.append_span (create {TEXT_SPAN}.make (codes (<<0x1F469>>), l_style))
				l_wrapped := {TEXT_LAYOUT}.wrap_line (l_line, 2, l_mode, True)
				assert ("one line, mode " + l_mode.out, l_wrapped.count = 1)
				assert ("pair whole, mode " + l_mode.out, l_wrapped.first.to_plain_string.same_string (codes (<<0x1F468, 0x200D, 0x1F469>>)))
				assert ("width 2, mode " + l_mode.out, l_wrapped.first.width = 2)
			end
		end

feature -- Cluster split across spans of different styles (U11)

	test_append_span_moves_continuation
			-- Code points continuing the last cluster move into the previous span and take its
			-- style; the rest keeps its own style.
		local
			l_line: TEXT_LINE
			l_red, l_blue: STYLE
		do
			create l_red.make_fg ({COLOR}.red)
			create l_blue.make_fg ({COLOR}.blue)

			-- Combining mark
			create l_line.make_empty
			l_line.append_span (create {TEXT_SPAN}.make ("e", l_red))
			l_line.append_span (create {TEXT_SPAN}.make (codes (<<0x301, 0x78>>), l_blue))
			assert ("mark: two spans", l_line.spans.count = 2)
			assert ("mark: moved to e", l_line.spans.i_th (1).content.same_string (codes (<<0x65, 0x301>>)))
			assert ("mark: e keeps red", l_line.spans.i_th (1).style.is_equal (l_red))
			assert ("mark: x stays blue", l_line.spans.i_th (2).content.same_string_general ("x") and l_line.spans.i_th (2).style.is_equal (l_blue))

			-- VS16 alone: the second span disappears, and the heart is 2 columns
			create l_line.make_empty
			l_line.append_span (create {TEXT_SPAN}.make (codes (<<0x2764>>), l_red))
			l_line.append_span (create {TEXT_SPAN}.make (codes (<<0xFE0F>>), l_blue))
			assert ("vs16: one span", l_line.spans.count = 1)
			assert ("vs16: width 2", l_line.width = 2)

			-- ZWJ tail
			create l_line.make_empty
			l_line.append_span (create {TEXT_SPAN}.make (codes (<<0x1F468, 0x200D>>), l_red))
			l_line.append_span (create {TEXT_SPAN}.make (codes (<<0x1F469, 0x62>>), l_blue))
			assert ("zwj: pair in span 1", l_line.spans.i_th (1).content.same_string (codes (<<0x1F468, 0x200D, 0x1F469>>)))
			assert ("zwj: b in span 2", l_line.spans.i_th (2).content.same_string_general ("b"))
			assert ("zwj: width 3", l_line.width = 3)

			-- Second half of a flag
			create l_line.make_empty
			l_line.append_span (create {TEXT_SPAN}.make (codes (<<0x61, 0x1F1EF>>), l_red))
			l_line.append_span (create {TEXT_SPAN}.make (codes (<<0x1F1F5>>), l_blue))
			assert ("flag: one span", l_line.spans.count = 1)
			assert ("flag: width 3", l_line.width = 3)
		end

	test_append_span_keeps_independent_span
			-- A span that starts a new cluster is stored as it is (same object).
		local
			l_line: TEXT_LINE
			l_span: TEXT_SPAN
		do
			create l_line.make_raw ("ab")
			create l_span.make_raw ("cd")
			l_line.append_span (l_span)
			assert ("two spans", l_line.spans.count = 2)
			assert ("same object", l_line.spans.last = l_span)

			-- A ZWJ at the end of span 1 followed by a non-pictographic character does not join
			create l_line.make_raw (codes (<<0x1F468, 0x200D>>))
			create l_span.make_raw ("x")
			l_line.append_span (l_span)
			assert ("zwj + x: two spans", l_line.spans.count = 2 and l_line.spans.last = l_span)
		end

	test_append_span_skips_empty_spans
			-- Empty spans between the two halves of a cluster do not stop the join: the
			-- continuation moves into the last non-empty span, and the empty spans stay.
		local
			l_line: TEXT_LINE
			l_red, l_blue: STYLE
		do
			create l_red.make_fg ({COLOR}.red)
			create l_blue.make_fg ({COLOR}.blue)
			create l_line.make_empty
			l_line.append_span (create {TEXT_SPAN}.make ("e", l_red))
			l_line.append_span (create {TEXT_SPAN}.make ("", l_blue))
			l_line.append_span (create {TEXT_SPAN}.make ("", l_red))
			l_line.append_span (create {TEXT_SPAN}.make (codes (<<0x301, 0x78>>), l_blue))
			assert ("four spans", l_line.spans.count = 4)
			assert ("mark moved to e", l_line.spans.i_th (1).content.same_string (codes (<<0x65, 0x301>>)))
			assert ("empties kept", l_line.spans.i_th (2).is_empty and l_line.spans.i_th (3).is_empty)
			assert ("x last", l_line.spans.i_th (4).content.same_string_general ("x"))
			assert ("text in order", l_line.to_plain_string.same_string (codes (<<0x65, 0x301, 0x78>>)))
			assert ("width 2", l_line.width = 2)
		end

	test_append_text
			-- `append_text` joins text to a last span of equal style and otherwise goes
			-- through `append_span`, so continuations still move and never land in an empty span.
		local
			l_line: TEXT_LINE
			l_red, l_blue: STYLE
		do
			create l_red.make_fg ({COLOR}.red)
			create l_blue.make_fg ({COLOR}.blue)
			create l_line.make_empty
			l_line.append_text ("ab", l_red)
			l_line.append_text ("cd", l_red)
			assert ("same style joined", l_line.spans.count = 1 and l_line.spans.first.content.same_string_general ("abcd"))
			l_line.append_text ("ef", l_blue)
			assert ("other style added", l_line.spans.count = 2)

			create l_line.make_empty
			l_line.append_text ("e", l_red)
			l_line.append_span (create {TEXT_SPAN}.make ("", l_blue))
			l_line.append_text (codes (<<0x301>>), l_blue)
			assert ("mark joined to e", l_line.spans.first.content.same_string (codes (<<0x65, 0x301>>)))
			assert ("no split", not l_line.has_split_cluster)
		end

	test_right_adjust
			-- `right_adjust` removes trailing white space and the spans it empties.
		local
			l_line: TEXT_LINE
			l_red, l_blue: STYLE
		do
			create l_red.make_fg ({COLOR}.red)
			create l_blue.make_fg ({COLOR}.blue)
			create l_line.make_empty
			l_line.append_text ("ab  ", l_red)
			l_line.append_text ("   ", l_blue)
			l_line.append_span (create {TEXT_SPAN}.make ("", l_red))
			l_line.right_adjust
			assert ("one span left", l_line.spans.count = 1)
			assert ("trimmed", l_line.to_plain_string.same_string_general ("ab"))
			assert ("style kept", l_line.spans.first.style.is_equal (l_red))

			create l_line.make_raw ("   ")
			l_line.right_adjust
			assert ("all blank: no spans", l_line.spans.is_empty)
		end

	test_wrap_split_around_empty_span
			-- "👨‍" red, "" blue, "👩" blue: the pair is joined across the empty span, so
			-- neither wrap mode breaks it.
		local
			l_line: TEXT_LINE
			l_red, l_blue: STYLE
			l_wrapped: ARRAYED_LIST [TEXT_LINE]
			l_mode: NATURAL_8
		do
			create l_red.make_fg ({COLOR}.red)
			create l_blue.make_fg ({COLOR}.blue)
			across
				<<{TEXT_WRAP_MODE}.character, {TEXT_WRAP_MODE}.word>> as m
			loop
				l_mode := m
				create l_line.make_empty
				l_line.append_span (create {TEXT_SPAN}.make (codes (<<0x1F468, 0x200D>>), l_red))
				l_line.append_span (create {TEXT_SPAN}.make ("", l_blue))
				l_line.append_span (create {TEXT_SPAN}.make (codes (<<0x1F469>>), l_blue))
				l_wrapped := {TEXT_LAYOUT}.wrap_line (l_line, 2, l_mode, True)
				assert ("one line, mode " + l_mode.out, l_wrapped.count = 1)
				assert ("pair whole, mode " + l_mode.out, l_wrapped.first.to_plain_string.same_string (codes (<<0x1F468, 0x200D, 0x1F469>>)))
				assert ("width 2, mode " + l_mode.out, l_wrapped.first.width = 2)
			end
		end

	test_buffer_draws_vs16_split_around_empty_span
			-- "❤", "", VS16, "x" in four spans: the heart is 2 columns and "x" follows it.
		local
			l_buf: BUFFER
			l_line: TEXT_LINE
			l_red, l_blue: STYLE
		do
			create l_red.make_fg ({COLOR}.red)
			create l_blue.make_fg ({COLOR}.blue)
			create l_line.make_empty
			l_line.append_span (create {TEXT_SPAN}.make (codes (<<0x2764>>), l_red))
			l_line.append_span (create {TEXT_SPAN}.make ("", l_red))
			l_line.append_span (create {TEXT_SPAN}.make (codes (<<0xFE0F>>), l_blue))
			l_line.append_span (create {TEXT_SPAN}.make ("x", l_blue))
			create l_buf.make (5, 1)
			l_buf.set_line (0, 0, l_line, 5)
			assert ("heart is wide", l_buf.cell (0, 0).width = 2)
			assert ("x at col 2", l_buf.cell (0, 2).symbol.same_string_general ("x"))
			assert ("consistent", l_buf.is_consistent)
		end

	test_wrap_different_style_spans_split_zwj
			-- A ZWJ pair split over two differently styled spans is not broken across lines.
		local
			l_line: TEXT_LINE
			l_red, l_blue: STYLE
			l_wrapped: ARRAYED_LIST [TEXT_LINE]
			l_mode: NATURAL_8
		do
			create l_red.make_fg ({COLOR}.red)
			create l_blue.make_fg ({COLOR}.blue)
			across
				<<{TEXT_WRAP_MODE}.character, {TEXT_WRAP_MODE}.word>> as m
			loop
				l_mode := m
				create l_line.make_empty
				l_line.append_span (create {TEXT_SPAN}.make (codes (<<0x1F468, 0x200D>>), l_red))
				l_line.append_span (create {TEXT_SPAN}.make (codes (<<0x1F469>>), l_blue))
				l_wrapped := {TEXT_LAYOUT}.wrap_line (l_line, 2, l_mode, True)
				assert ("one line, mode " + l_mode.out, l_wrapped.count = 1)
				assert ("pair whole, mode " + l_mode.out, l_wrapped.first.to_plain_string.same_string (codes (<<0x1F468, 0x200D, 0x1F469>>)))
				assert ("width 2, mode " + l_mode.out, l_wrapped.first.width = 2)
			end
		end

	test_buffer_draws_vs16_split_across_styles
			-- "❤" red + VS16 blue + "x": the heart takes 2 columns and "x" is drawn after it,
			-- not over the heart's second cell.
		local
			l_buf: BUFFER
			l_line: TEXT_LINE
			l_red, l_blue: STYLE
		do
			create l_red.make_fg ({COLOR}.red)
			create l_blue.make_fg ({COLOR}.blue)
			create l_line.make_empty
			l_line.append_span (create {TEXT_SPAN}.make (codes (<<0x2764>>), l_red))
			l_line.append_span (create {TEXT_SPAN}.make (codes (<<0xFE0F>>), l_blue))
			l_line.append_span (create {TEXT_SPAN}.make ("x", l_blue))
			create l_buf.make (5, 1)
			l_buf.set_line (0, 0, l_line, 5)
			assert ("heart at col 0", l_buf.cell (0, 0).symbol.same_string (codes (<<0x2764, 0xFE0F>>)))
			assert ("heart is wide", l_buf.cell (0, 0).width = 2)
			assert ("continuation at col 1", l_buf.cell (0, 1).is_continuation)
			assert ("x at col 2", l_buf.cell (0, 2).symbol.same_string_general ("x"))
			assert ("consistent", l_buf.is_consistent)
		end

feature {NONE} -- Helpers

	character_wrap (a_text: STRING_32; a_width: NATURAL_16): ARRAYED_LIST [TEXT_LINE]
			-- `a_text' wrapped by character at `a_width' columns, without trimming.
		do
			Result := {TEXT_LAYOUT}.wrap_line (create {TEXT_LINE}.make_raw (a_text), a_width, {TEXT_WRAP_MODE}.character, False)
		end

	word_wrap (a_text: STRING_32; a_width: NATURAL_16): ARRAYED_LIST [TEXT_LINE]
			-- `a_text' wrapped by word at `a_width' columns, with trimming.
		do
			Result := {TEXT_LAYOUT}.wrap_line (create {TEXT_LINE}.make_raw (a_text), a_width, {TEXT_WRAP_MODE}.word, True)
		end

	assert_round_trip (a_tag: STRING; a_text: STRING_32)
			-- For widths 1 to 6, every line of `a_text' wrapped by character fits the width,
			-- and the lines concatenate back to `a_text'.
		do
			assert_round_trip_in_mode (a_tag, a_text, {TEXT_WRAP_MODE}.character)
		end

	assert_round_trip_in_mode (a_tag: STRING; a_text: STRING_32; a_mode: NATURAL_8)
			-- For widths 1 to 6, every line of `a_text' wrapped with `a_mode' (no trimming)
			-- fits the width, and the lines concatenate back to `a_text'.
		local
			w: NATURAL_16
			l_joined: STRING_32
			l_wrapped: ARRAYED_LIST [TEXT_LINE]
		do
			from
				w := 1
			until
				w > 6
			loop
				l_wrapped := {TEXT_LAYOUT}.wrap_line (create {TEXT_LINE}.make_raw (a_text), w, a_mode, False)
				create l_joined.make (a_text.count)
				across
					l_wrapped as l
				loop
					assert (a_tag + ": line fits width " + w.out, l.width <= w.max (2))
					l_joined.append (l.to_plain_string)
				end
				assert (a_tag + ": nothing dropped at width " + w.out, l_joined.same_string (a_text))
				w := w + 1
			end
		end

	codes (a_codes: ARRAY [INTEGER]): STRING_32
			-- String made of the code points `a_codes'.
		do
			create Result.make (a_codes.count)
			across
				a_codes as c
			loop
				Result.append_character (c.to_character_32)
			end
		end

end
