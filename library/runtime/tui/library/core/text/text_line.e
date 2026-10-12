note
	description: "[
		A single horizontal line of text composed of one or more styled TEXT_SPANs.
		Supports alignment and line-level styling.
		No grapheme cluster straddles two spans (invariant `no_split_cluster`): spans are
		added only through `append_span` and `append_text`, `spans` is a read-only view, and
		TEXT_SPAN is immutable.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEXT_LINE

inherit
	WIDGET
		redefine
			default_create,
			copy,
			is_equal,
			out
		end

create
	default_create,
	make_empty,
	make,
	make_raw,
	make_styled,
	make_from_span

convert
	make_raw ({READABLE_STRING_8, READABLE_STRING_32, STRING_8, STRING_32}),
	make_from_span ({TEXT_SPAN})

feature {NONE} -- Initialization

	default_create
			-- Initialize as an empty line.
		do
			make_empty
		ensure then
			spans_empty: spans.is_empty
		end

	make_empty
			-- Initialize an empty line with left alignment and default style.
		do
			create span_items.make (4)
			create spans.make (span_items)
			create style.default_create
			alignment := {TEXT_ALIGNMENT}.left
		ensure
			spans_empty: spans.is_empty
			alignment_left: alignment = {TEXT_ALIGNMENT}.left
		end

	make (a_spans: ITERABLE [TEXT_SPAN])
			-- Initialize line with `a_spans`.
		require
			spans_not_void: a_spans /= Void
		do
			make_empty
			across
				a_spans as s
			loop
				append_span (s)
			end
		end

	make_raw (a_content: READABLE_STRING_GENERAL)
			-- Initialize line with a single unstyled span.
		require
			content_not_void: a_content /= Void
		local
			l_span: TEXT_SPAN
		do
			make_empty
			create l_span.make_raw (a_content)
			append_span (l_span)
		ensure
			one_span: spans.count = 1
		end

	make_styled (a_content: READABLE_STRING_GENERAL; a_style: STYLE)
			-- Initialize line with a single span styled with `a_style`.
		require
			content_not_void: a_content /= Void
			style_not_void: a_style /= Void
		local
			l_span: TEXT_SPAN
		do
			make_empty
			create l_span.make (a_content, a_style)
			append_span (l_span)
		ensure
			one_span: spans.count = 1
		end

	make_from_span (a_span: TEXT_SPAN)
			-- Initialize line with a single `a_span`.
		require
			span_not_void: a_span /= Void
		do
			make_empty
			append_span (a_span)
		ensure
			one_span: spans.count = 1
			first_span: spans.first = a_span
		end

feature -- Duplication

	copy (a_other: like Current)
			-- Copy `a_other` to `Current`, with its own list of spans.
		do
			if a_other /= Current then
				standard_copy (a_other)
				create span_items.make (a_other.spans.count)
				across a_other.spans as s loop
					span_items.extend (s.twin)
				end
				create spans.make (span_items)
			end
		end

feature -- Access

	spans: TEXT_SPAN_LIST
			-- Ordered sequence of styled spans (read-only view)

	alignment: NATURAL_8
			-- Alignment mode (left, center, right)

	style: STYLE
			-- Baseline style for the line

	width: NATURAL_16
			-- Total display width in columns of all spans, clamped to NATURAL_16.max_value on overflow.
		local
			w: NATURAL_32
		do
			w := 0
			across
				spans as s
			loop
				w := w + s.width.to_natural_32
			end
			if w > {NATURAL_16}.max_value.to_natural_32 then
				Result := {NATURAL_16}.max_value
			else
				Result := w.to_natural_16
			end
		end

	count: INTEGER
			-- Number of spans in this line
		do
			Result := spans.count
		ensure
			count_matches: Result = spans.count
		end

	is_empty: BOOLEAN
			-- Is the line empty (no spans or all spans empty)?
		do
			Result := width = 0
		ensure
			empty_definition: Result = (width = 0)
		end

feature -- Element change

	append_span (a_span: TEXT_SPAN)
			-- Add `a_span` to the end of this line.
			-- Grapheme clusters never straddle two spans: if `a_span` starts with code points that
			-- continue the last cluster of the last non-empty span (a combining mark, VS16, a ZWJ
			-- tail, the second half of a flag), they are moved into that span and take its style
			-- (empty spans after it stay where they are), and the rest of `a_span` is added as a
			-- new span. Otherwise `a_span` itself is added.
		require
			span_not_void: a_span /= Void
		local
			l_moved, k: INTEGER
			l_text: TEXT_SPAN
		do
			l_moved := continuation_of (a_span)
			if l_moved = 0 then
				span_items.extend (a_span)
			else
				k := last_text_index
				l_text := span_items.i_th (k)
				span_items.put_i_th (create {TEXT_SPAN}.make (l_text.content + a_span.content.substring (1, l_moved), l_text.style), k)
				if l_moved < a_span.count then
					span_items.extend (create {TEXT_SPAN}.make (a_span.content.substring (l_moved + 1, a_span.count), a_span.style))
				end
			end
		ensure
			span_added: spans.count = old spans.count + 1 or (spans.count = old spans.count and not spans.is_empty)
			last_span: old continuation_of (a_span) = 0 implies spans.last = a_span
			text_appended: to_plain_string.same_string (old to_plain_string + a_span.content)
		end

	append_text (a_text: READABLE_STRING_GENERAL; a_style: STYLE)
			-- Add `a_text` styled with `a_style` at the end of this line: joined to the last span
			-- when that span has text and an equal style, otherwise as a new span (see `append_span`).
		require
			text_not_void: a_text /= Void
			style_not_void: a_style /= Void
		local
			l_last: TEXT_SPAN
		do
			if not span_items.is_empty and then not span_items.last.is_empty
				and then span_items.last.style.is_equal (a_style) then
				l_last := span_items.last
				span_items.finish
				span_items.replace (create {TEXT_SPAN}.make (l_last.content + a_text.as_string_32, l_last.style))
			else
				append_span (create {TEXT_SPAN}.make (a_text, a_style))
			end
		ensure
			text_appended: to_plain_string.same_string (old to_plain_string + a_text.as_string_32)
		end

	right_adjust
			-- Remove trailing white space, and the spans it leaves empty.
		local
			l_last: TEXT_SPAN
			l_text: STRING_32
			l_done: BOOLEAN
		do
			from
			until
				l_done or span_items.is_empty
			loop
				l_last := span_items.last
				create l_text.make_from_string (l_last.content)
				l_text.right_adjust
				if l_text.is_empty then
					span_items.finish
					span_items.remove
				else
					if l_text.count < l_last.count then
						span_items.finish
						span_items.replace (create {TEXT_SPAN}.make (l_text, l_last.style))
					end
					l_done := True
				end
			end
		ensure
			no_more_spans: spans.count <= old spans.count
		end

	wipe_out
			-- Remove all spans from this line.
		do
			span_items.wipe_out
		ensure
			spans_empty: spans.is_empty
		end

	set_alignment (a_align: NATURAL_8)
			-- Set alignment to `a_align`.
		require
			valid_align: {TEXT_ALIGNMENT}.is_valid (a_align)
		do
			alignment := a_align
		ensure
			alignment_set: alignment = a_align
		end

	set_style (a_style: STYLE)
			-- Set baseline line style.
		require
			style_not_void: a_style /= Void
		do
			style := a_style
		ensure
			style_set: style = a_style
		end

feature -- Measurement

	continuation_of (a_span: TEXT_SPAN): INTEGER
			-- Number of code points at the start of `a_span` that would continue the last grapheme
			-- cluster of this line's last non-empty span (see `append_span`).
		require
			span_not_void: a_span /= Void
		do
			if last_text_index > 0 then
				Result := continuation_length (spans.i_th (last_text_index).content, a_span.content)
			end
		ensure
			in_range: Result >= 0 and Result <= a_span.count
			none_without_text: last_text_index = 0 implies Result = 0
		end

	has_split_cluster: BOOLEAN
			-- Does a grapheme cluster straddle two spans (empty spans in between ignored)?
		local
			i: INTEGER
			l_prev: detachable TEXT_SPAN
			l_curr: TEXT_SPAN
		do
			from
				i := 1
			until
				Result or i > span_items.count
			loop
				l_curr := span_items.i_th (i)
				if not l_curr.is_empty then
					if l_prev /= Void then
						Result := continuation_length (l_prev.content, l_curr.content) > 0
					end
					l_prev := l_curr
				end
				i := i + 1
			end
		end

	last_text_index: INTEGER
			-- Index in `spans` of the last non-empty span (0 if there is none).
		do
			from
				Result := spans.count
			until
				Result = 0 or else not spans.i_th (Result).is_empty
			loop
				Result := Result - 1
			end
		ensure
			in_range: Result >= 0 and Result <= spans.count
			not_empty: Result > 0 implies not spans.i_th (Result).is_empty
		end

	continuation_length (a_before, a_after: READABLE_STRING_32): INTEGER
			-- Number of code points at the start of `a_after` that belong to the last grapheme
			-- cluster of `a_before` when the two are joined (0 if `a_after` starts a new cluster).
		local
			l_code: NATURAL_32
			i, l_start: INTEGER
			l_join: STRING_32
		do
			if not a_before.is_empty and not a_after.is_empty then
				l_code := a_after.code (1)
				-- Only these can continue a cluster (see {UNICODE_WIDTH}.grapheme_end)
				if {UNICODE_WIDTH}.is_extend (l_code) or {UNICODE_WIDTH}.is_regional_indicator (l_code)
					or {UNICODE_WIDTH}.is_extended_pictographic (l_code) or l_code = 10 then
					from
						i := 1
					until
						i > a_before.count
					loop
						l_start := i
						i := {UNICODE_WIDTH}.grapheme_end (a_before, i) + 1
					end
					create l_join.make (a_before.count - l_start + 1 + a_after.count)
					l_join.append_substring (a_before, l_start, a_before.count)
					l_join.append (a_after)
					Result := ({UNICODE_WIDTH}.grapheme_end (l_join, 1) - (a_before.count - l_start + 1)).max (0)
				end
			end
		ensure
			instance_free: class
			in_range: Result >= 0 and Result <= a_after.count
		end

feature -- Conversion

	to_plain_string: STRING_32
			-- Concatenated plain text of all spans without styling.
		do
			create Result.make (width.to_integer_32)
			across
				spans as s
			loop
				Result.append (s.content)
			end
		ensure
			result_not_void: Result /= Void
		end

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Is `Current` equal to `a_other`?
		local
			i: INTEGER
		do
			if alignment = a_other.alignment and style.is_equal (a_other.style) and spans.count = a_other.spans.count then
				Result := True
				from
					i := 1
				until
					i > spans.count or not Result
				loop
					if not spans.i_th (i).is_equal (a_other.spans.i_th (i)) then
						Result := False
					end
					i := i + 1
				end
			end
		end

feature -- Output

	out: STRING_8
			-- Plain string representation, UTF-8 encoded (so `print` shows any text on a
			-- UTF-8 terminal; `to_string_8` would fail on characters above U+00FF)
		do
			Result := {UTF_CONVERTER}.utf_32_string_to_utf_8_string_8 (to_plain_string)
		end

feature -- Rendering

	render (a_area: RECT; a_buffer: BUFFER)
			-- Render line inside `a_area` into `a_buffer` honoring alignment and style.
		local
			l_x, l_y, l_w: INTEGER
			l_start_col: INTEGER
			l_line_w: INTEGER
		do
			if not a_area.is_empty and a_area.height > 0 and a_area.width > 0 then
				l_x := a_area.x.to_integer_32
				l_y := a_area.y.to_integer_32
				l_w := a_area.width.to_integer_32
				if l_y >= 0 and l_y < a_buffer.height then
					l_line_w := width.to_integer_32
					inspect alignment
					when {TEXT_ALIGNMENT}.center then
						l_start_col := l_x + ((l_w - l_line_w) // 2).max (0)
					when {TEXT_ALIGNMENT}.right then
						l_start_col := l_x + (l_w - l_line_w).max (0)
					else
						l_start_col := l_x
					end
					a_buffer.set_line_clipped (l_y, l_start_col, Current, style, l_x, l_x + l_w)
				end
			end
		end

feature {NONE} -- Implementation

	span_items: ARRAYED_LIST [TEXT_SPAN]
			-- Spans of this line, viewed by `spans`

invariant
	spans_not_void: spans /= Void
	spans_view_items: spans.list = span_items
	no_split_cluster: not has_split_cluster
	style_not_void: style /= Void
	valid_alignment: {TEXT_ALIGNMENT}.is_valid (alignment)

end
