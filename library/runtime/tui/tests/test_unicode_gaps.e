note
	description: "[
		Unicode subset gaps closed for review finding U10:
		- VS16 widens only characters with the Emoji property
		- explicit bidi formatting characters are clusters of their own, and the buffer drops them
		- the calendar header is centred by display width
		- `sub_span' cannot split a grapheme cluster
		Non-ASCII text is built from code points: BOM-less sources compile as Latin-1.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_UNICODE_GAPS

inherit
	EQA_TEST_SET

feature -- Width

	test_vs16_widens_only_emoji
			-- A + VS16 stays 1 wide; emoji bases (text-default heart and smiley, keycap #) become 2.
		do
			assert ("A + VS16", {UNICODE_WIDTH}.grapheme_width (codes (<<0x41, 0xFE0F>>)) = 1)
			assert ("CJK + VS16 stays 2", {UNICODE_WIDTH}.grapheme_width (codes (<<0x4E00, 0xFE0F>>)) = 2)
			assert ("heart + VS16", {UNICODE_WIDTH}.grapheme_width (codes (<<0x2764, 0xFE0F>>)) = 2)
			assert ("smiley + VS16", {UNICODE_WIDTH}.grapheme_width (codes (<<0x263A, 0xFE0F>>)) = 2)
			assert ("keycap #", {UNICODE_WIDTH}.grapheme_width (codes (<<0x23, 0xFE0F, 0x20E3>>)) = 2)
			assert ("heart alone", {UNICODE_WIDTH}.grapheme_width (codes (<<0x2764>>)) = 1)
			assert ("string", {UNICODE_WIDTH}.string_width (codes (<<0x41, 0xFE0F, 0x2764, 0xFE0F>>)) = 3)
			assert ("emoji property", {UNICODE_WIDTH}.is_emoji_code (0x2764) and not {UNICODE_WIDTH}.is_emoji_code (0x41))
		end

feature -- Bidi controls

	test_bidi_controls_are_own_clusters
			-- U+202A..U+202E and U+2066..U+2069 break clusters instead of extending them;
			-- other format characters (ZWJ, VS16) still extend.
		local
			l_text: STRING_32
			l_code: NATURAL_32
		do
			across <<0x202A, 0x202B, 0x202C, 0x202D, 0x202E, 0x2066, 0x2067, 0x2068, 0x2069>> as c loop
				l_code := c
				assert ("bidi control " + l_code.to_hex_string, {UNICODE_WIDTH}.is_bidi_control (l_code)
					and {UNICODE_WIDTH}.is_never_drawn (l_code) and not {UNICODE_WIDTH}.is_extend (l_code))
			end
			assert ("LRM is not", not {UNICODE_WIDTH}.is_bidi_control (0x200E))
			assert ("ZWJ still extends", {UNICODE_WIDTH}.is_extend (0x200D))
			l_text := codes (<<0x61, 0x202E, 0x0301, 0x62>>)
			assert ("a alone", {UNICODE_WIDTH}.grapheme_end (l_text, 1) = 1)
			assert ("RLO alone, even before a mark", {UNICODE_WIDTH}.grapheme_end (l_text, 2) = 2)
			assert ("width unchanged", {UNICODE_WIDTH}.string_width (l_text) = 2)
		end

	test_buffer_drops_bidi_controls
			-- No cell holds a bidi control: not attached to the previous cell, not at the start.
		local
			l_buf: BUFFER
			c: INTEGER
		do
			create l_buf.make (6, 1)
			l_buf.set_string_clipped (0, 0, codes (<<0x2067, 0x61, 0x202E, 0x62, 0x63, 0x2069>>), 0, 6, create {STYLE})
			assert ("a", l_buf.cell (0, 0).symbol.same_string ("a"))
			assert ("b", l_buf.cell (0, 1).symbol.same_string ("b"))
			assert ("c", l_buf.cell (0, 2).symbol.same_string ("c"))
			from
				c := 0
			until
				c >= 6
			loop
				assert ("no bidi control in cell " + c.out, across l_buf.cell (0, c).symbol as s all not {UNICODE_WIDTH}.is_bidi_control (s.natural_32_code) end)
				c := c + 1
			end
			-- A combining mark after a bidi control has nothing to attach to in its own cluster
			create l_buf.make (4, 1)
			l_buf.set_string_clipped (0, 0, codes (<<0x65, 0x0301, 0x202E, 0x66>>), 0, 4, create {STYLE})
			assert ("e + acute kept", l_buf.cell (0, 0).symbol.same_string (codes (<<0x65, 0x0301>>)))
			assert ("f next", l_buf.cell (0, 1).symbol.same_string ("f"))
		end

feature -- Widgets

	test_calendar_header_centred_by_width
			-- A month name of two wide characters: the header "<name> 2026" is 9 columns
			-- (7 characters), centred in 21 columns at column 6 (it was 7).
		local
			l_cal: TUI_CALENDAR
			l_state: LOCALIZED_CALENDAR_STATE
			l_buf: BUFFER
		do
			create l_state.make
			create l_cal.make
			create l_buf.make (21, 9)
			l_cal.render_stateful (create {RECT}.make (0, 0, 21, 9), l_buf, l_state)
			assert ("blank before", l_buf.cell (0, 5).symbol.same_string (" "))
			assert ("name starts at 6", l_buf.cell (0, 6).symbol.same_string (codes (<<0x4E00>>)))
			assert ("year ends at 14", l_buf.cell (0, 14).symbol.same_string ("6"))
		end

feature -- Spans

	test_sub_span_on_cluster_boundaries
			-- `is_cluster_boundary` and a `sub_span` that would split a cluster refused.
		local
			l_span: TEXT_SPAN
			l_sub: TEXT_SPAN
		do
			-- e + U+0301, then x
			create l_span.make_raw (codes (<<0x65, 0x0301, 0x78>>))
			assert ("1", l_span.is_cluster_boundary (1))
			assert ("inside e+acute", not l_span.is_cluster_boundary (2))
			assert ("3", l_span.is_cluster_boundary (3))
			assert ("end", l_span.is_cluster_boundary (4))
			l_sub := l_span.sub_span (1, 2)
			assert ("whole cluster", l_sub.content.same_string (codes (<<0x65, 0x0301>>)) and l_sub.width = 1)
			assert ("split refused", sub_span_refused (l_span, 1, 1, "end_on_boundary"))
			assert ("split at start refused", sub_span_refused (l_span, 2, 2, "start_on_boundary"))
		end

feature {NONE} -- Helpers

	sub_span_refused (a_span: TEXT_SPAN; a_start, a_count: INTEGER; a_tag: STRING): BOOLEAN
			-- Does `a_span.sub_span (a_start, a_count)` violate its precondition `a_tag`?
		local
			l_retried: BOOLEAN
		do
			if not l_retried then
				a_span.sub_span (a_start, a_count).do_nothing
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

	codes (a_codes: ARRAY [INTEGER]): STRING_32
			-- String of the code points `a_codes`
		do
			create Result.make (a_codes.count)
			across a_codes as c loop
				Result.append_code (c.to_natural_32)
			end
		end

end
