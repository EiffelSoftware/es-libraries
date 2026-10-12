note
	description: "[
		Contiguous slice of text sharing a single styling configuration.
		Supports Unicode characters and provides calculated terminal visual width.
		The text is immutable: a span cannot change once it is part of a TEXT_LINE, which keeps
		the line's rule that no grapheme cluster straddles two spans. Build a new span instead.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEXT_SPAN

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
	make,
	make_raw

convert
	make_raw ({READABLE_STRING_8, READABLE_STRING_32, STRING_8, STRING_32})

feature {NONE} -- Initialization

	default_create
			-- Initialize as an empty span with default styling.
		do
			create content.make_empty
			create style.default_create
			width := 0
		ensure then
			content_empty: content.is_empty
			width_zero: width = 0
		end

	make (a_content: READABLE_STRING_GENERAL; a_style: STYLE)
			-- Initialize span with `a_content` and `a_style`.
		require
			content_not_void: a_content /= Void
			style_not_void: a_style /= Void
		do
			create content.make_from_string_general (a_content)
			style := a_style
			width := {UNICODE_WIDTH}.string_width (content)
		ensure
			content_set: content.same_string_general (a_content)
			style_set: style = a_style
			width_computed: width = {UNICODE_WIDTH}.string_width (content)
		end

	make_raw (a_content: READABLE_STRING_GENERAL)
			-- Initialize span with `a_content` and default styling.
		require
			content_not_void: a_content /= Void
		do
			create content.make_from_string_general (a_content)
			create style.default_create
			width := {UNICODE_WIDTH}.string_width (content)
		ensure
			content_set: content.same_string_general (a_content)
			style_default: style.is_equal (create {STYLE}.default_create)
			width_computed: width = {UNICODE_WIDTH}.string_width (content)
		end

feature -- Access

	content: IMMUTABLE_STRING_32
			-- Text payload of this span

	style: STYLE
			-- Visual styling applied to this span

	width: NATURAL_16
			-- Total visual width in terminal cell columns

	count: INTEGER
			-- Number of characters in `content`
		do
			Result := content.count
		ensure
			correct_count: Result = content.count
		end

	is_empty: BOOLEAN
			-- Is `content` empty?
		do
			Result := content.is_empty
		ensure
			empty_definition: Result = (count = 0)
		end

feature -- Element change

	set_style (a_style: STYLE)
			-- Replace styling with `a_style`.
		require
			style_not_void: a_style /= Void
		do
			style := a_style
		ensure
			style_set: style = a_style
		end

feature -- Status report

	is_cluster_boundary (a_index: INTEGER): BOOLEAN
			-- Does a grapheme cluster of `content` start at `a_index` (`count + 1`: the end)?
		require
			valid_index: a_index >= 1 and a_index <= count + 1
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i >= a_index
			loop
				i := {UNICODE_WIDTH}.grapheme_end (content, i) + 1
			end
			Result := i = a_index
		ensure
			ends: (a_index = 1 or a_index = count + 1) implies Result
		end

feature -- Operations

	sub_span (a_start, a_count: INTEGER): TEXT_SPAN
			-- Extract substring span starting at index `a_start` with `a_count` characters,
			-- preserving the current styling. Both ends must fall between grapheme clusters, so
			-- that no cluster is split (a split cluster would be measured and drawn as two).
		require
			valid_start: a_start >= 1 and a_start <= count + 1
			valid_count: a_count >= 0 and a_start + a_count - 1 <= count
			start_on_boundary: is_cluster_boundary (a_start)
			end_on_boundary: is_cluster_boundary (a_start + a_count)
		do
			create Result.make (content.substring (a_start, a_start + a_count - 1), style)
		ensure
			result_not_void: Result /= Void
			same_style: Result.style = style
			correct_count: Result.count = a_count
		end

feature -- Duplication

	copy (a_other: like Current)
			-- Copy `a_other` to `Current`.
			-- `content` is immutable, so it is shared.
		do
			if a_other /= Current then
				standard_copy (a_other)
			end
		end

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Is `Current` equal to `a_other`?
		do
			Result := content.same_string (a_other.content) and style.is_equal (a_other.style)
		end

feature -- Output

	out: STRING_8
			-- Plain string representation, UTF-8 encoded (so `print` shows any text on a
			-- UTF-8 terminal; `to_string_8` would fail on characters above U+00FF)
		do
			Result := {UTF_CONVERTER}.utf_32_string_to_utf_8_string_8 (content)
		end

feature -- Rendering

	render (a_area: RECT; a_buffer: BUFFER)
			-- Render span on the first row of `a_area` into `a_buffer`.
		local
			l_x, l_y, l_w: INTEGER
		do
			if not a_area.is_empty and a_area.height > 0 and a_area.width > 0 then
				l_x := a_area.x.to_integer_32
				l_y := a_area.y.to_integer_32
				l_w := a_area.width.to_integer_32
				if l_y >= 0 and l_y < a_buffer.height then
					a_buffer.set_string_clipped (l_y, l_x, content, l_x, (l_x + l_w).min (a_buffer.width), style)
				end
			end
		end

invariant
	content_not_void: content /= Void
	style_not_void: style /= Void
	width_non_negative: width >= 0

end
