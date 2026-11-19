note
	description: "[
		A horizontal or vertical rule, with an optional label on a horizontal one. Ratatui has
		no divider widget; Ratatui apps draw one with a `Block` that has one border, which is
		what this widget draws without the block.

		    (create {TUI_DIVIDER}.make)
		        .with_line_set ({DIVIDER_LINE_SET}.double)
		        .with_label ("Settings")
		        .with_label_alignment ({TEXT_ALIGNMENT}.center)
		        .render (l_area, l_buffer)

		gives "═══ Settings ═══" on the top row of a 16-column area.

		Line: a horizontal divider draws the top row of its area, a vertical one the left
		column, with the glyph of `line_set` (DIVIDER_LINE_SET). The area is first cut to the
		buffer, as TUI_BLOCK cuts its own, so the rule ends at the buffer's edge and the label
		is placed on the part inside the buffer. The other rows (columns) of the area are left
		as they are.

		Style: `style` is patched over each line cell's style (Ratatui `Cell::set_style`, as a
		`Block`'s border), so colours left at the default keep the cell's own colours.

		Label (horizontal only; a vertical divider ignores it):
		  * It is placed as TUI_BLOCK places a title between its corners: one line cell is
		    kept at each end, and the label, with `label_padding` blanks on each side, is
		    put at the left, centred or at the right of the columns between them
		    (`label_alignment`). The label's own alignment is not used (as TUI_BLOCK).
		  * It is clipped per grapheme cluster: only the clusters that fit whole are drawn, so
		    a wide character that would cross the right end is left out with the rest, and
		    the padding stays next to the last cluster drawn.
		  * It is dropped, and the line drawn whole, when the padding and the label's first
		    cluster do not fit with one line cell on each side. An empty label draws nothing.
		  * Its base style is the line cell's style under it (the cell's style patched by
		    `style`), patched by the label's line and span styles, as BUFFER draws a line.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_DIVIDER

inherit
	WIDGET
		redefine
			default_create,
			copy,
			is_equal
		end

create
	default_create,
	make,
	make_vertical

feature {NONE} -- Initialization

	default_create
			-- Horizontal plain divider in the default style, without a label.
		do
			direction := {DIVIDER_DIRECTION}.horizontal
			line_set := {DIVIDER_LINE_SET}.plain
			create style
			label_alignment := {TEXT_ALIGNMENT}.left
			label_padding := 1
		ensure then
			horizontal: direction = {DIVIDER_DIRECTION}.horizontal
			plain: line_set = {DIVIDER_LINE_SET}.plain
			no_label: label = Void
			left_label: label_alignment = {TEXT_ALIGNMENT}.left
			one_blank: label_padding = 1
		end

	make
			-- Synonym for `default_create`.
		do
			default_create
		end

	make_vertical
			-- Vertical plain divider in the default style.
		do
			default_create
			direction := {DIVIDER_DIRECTION}.vertical
		ensure
			vertical: direction = {DIVIDER_DIRECTION}.vertical
			plain: line_set = {DIVIDER_LINE_SET}.plain
		end

feature -- Access

	direction: NATURAL_8
			-- Horizontal (top row) or vertical (left column) rule (DIVIDER_DIRECTION)

	line_set: NATURAL_8
			-- Line glyphs (DIVIDER_LINE_SET)

	style: STYLE
			-- Style patched over the line cells

	label: detachable TEXT_LINE
			-- Optional label on a horizontal rule

	label_alignment: NATURAL_8
			-- Position of the label between the line's ends (TEXT_ALIGNMENT)

	label_padding: NATURAL_16
			-- Blank cells on each side of the label

	glyph: CHARACTER_32
			-- Character drawn in each line cell
		do
			if direction = {DIVIDER_DIRECTION}.vertical then
				Result := {DIVIDER_LINE_SET}.vertical (line_set)
			else
				Result := {DIVIDER_LINE_SET}.horizontal (line_set)
			end
		end

feature -- Status report

	is_horizontal: BOOLEAN
			-- Is this a horizontal rule?
		do
			Result := direction = {DIVIDER_DIRECTION}.horizontal
		ensure
			definition: Result = (direction = {DIVIDER_DIRECTION}.horizontal)
		end

feature -- Element change

	set_direction (a_direction: NATURAL_8)
			-- Draw a horizontal or a vertical rule.
		require
			valid_direction: {DIVIDER_DIRECTION}.is_valid (a_direction)
		do
			direction := a_direction
		ensure
			direction_set: direction = a_direction
		end

	set_line_set (a_set: NATURAL_8)
			-- Draw the line with the glyphs of `a_set`.
		require
			valid_set: {DIVIDER_LINE_SET}.is_valid (a_set)
		do
			line_set := a_set
		ensure
			line_set_set: line_set = a_set
		end

	set_style (a_style: STYLE)
			-- Patch `a_style` over the line cells.
		require
			style_not_void: a_style /= Void
		do
			style := a_style
		ensure
			style_set: style = a_style
		end

	set_label (a_label: detachable TEXT_LINE)
			-- Set or clear the label.
		do
			label := a_label
		ensure
			label_set: label = a_label
		end

	set_label_string (a_text: READABLE_STRING_GENERAL)
			-- Set the label from a plain string.
		require
			text_not_void: a_text /= Void
		do
			create label.make_raw (a_text)
		ensure
			label_attached: label /= Void
		end

	set_label_alignment (a_align: NATURAL_8)
			-- Put the label at the left, centred or at the right.
		require
			valid_align: {TEXT_ALIGNMENT}.is_valid (a_align)
		do
			label_alignment := a_align
		ensure
			label_alignment_set: label_alignment = a_align
		end

	set_label_padding (a_padding: NATURAL_16)
			-- Keep `a_padding` blank cells on each side of the label.
		do
			label_padding := a_padding
		ensure
			label_padding_set: label_padding = a_padding
		end

feature -- Fluent Builders

	with_direction (a_direction: NATURAL_8): like Current
			-- Copy of Current drawing a rule in `a_direction`.
		require
			valid_direction: {DIVIDER_DIRECTION}.is_valid (a_direction)
		do
			Result := twin
			Result.set_direction (a_direction)
		ensure
			result_not_void: Result /= Void
			direction_set: Result.direction = a_direction
		end

	with_line_set (a_set: NATURAL_8): like Current
			-- Copy of Current drawing the line with `a_set`.
		require
			valid_set: {DIVIDER_LINE_SET}.is_valid (a_set)
		do
			Result := twin
			Result.set_line_set (a_set)
		ensure
			result_not_void: Result /= Void
			line_set_set: Result.line_set = a_set
		end

	with_style (a_style: STYLE): like Current
			-- Copy of Current with `style` set to `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_style (a_style)
		ensure
			result_not_void: Result /= Void
			style_set: Result.style = a_style
		end

	with_label (a_text: READABLE_STRING_GENERAL): like Current
			-- Copy of Current with a plain label `a_text`.
		require
			text_not_void: a_text /= Void
		do
			Result := twin
			Result.set_label_string (a_text)
		ensure
			result_not_void: Result /= Void
			label_attached: Result.label /= Void
		end

	with_label_line (a_line: TEXT_LINE): like Current
			-- Copy of Current with the styled label `a_line`.
		require
			line_not_void: a_line /= Void
		do
			Result := twin
			Result.set_label (a_line)
		ensure
			result_not_void: Result /= Void
			label_set: Result.label = a_line
		end

	without_label: like Current
			-- Copy of Current without a label.
		do
			Result := twin
			Result.set_label (Void)
		ensure
			result_not_void: Result /= Void
			no_label: Result.label = Void
		end

	with_label_alignment (a_align: NATURAL_8): like Current
			-- Copy of Current with the label at `a_align`.
		require
			valid_align: {TEXT_ALIGNMENT}.is_valid (a_align)
		do
			Result := twin
			Result.set_label_alignment (a_align)
		ensure
			result_not_void: Result /= Void
			label_alignment_set: Result.label_alignment = a_align
		end

	with_label_padding (a_padding: NATURAL_16): like Current
			-- Copy of Current with `a_padding` blank cells on each side of the label.
		do
			Result := twin
			Result.set_label_padding (a_padding)
		ensure
			result_not_void: Result /= Void
			label_padding_set: Result.label_padding = a_padding
		end

feature -- Duplication

	copy (a_other: like Current)
			-- Copy `a_other`, with its own copy of the label, so that changing the label of a
			-- copy made by a `with_*` builder leaves the original unchanged.
		do
			if a_other /= Current then
				standard_copy (a_other)
				if attached a_other.label as l_label then
					label := l_label.twin
				end
			end
		end

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Same direction, line set, style, label and label placement?
		do
			if a_other = Current then
				Result := True
			else
				Result := direction = a_other.direction
					and line_set = a_other.line_set
					and style.is_equal (a_other.style)
					and label ~ a_other.label
					and label_alignment = a_other.label_alignment
					and label_padding = a_other.label_padding
			end
		end

feature -- Rendering

	render (a_area: RECT; a_buffer: BUFFER)
			-- Draw the rule on the top row (horizontal) or the left column (vertical) of
			-- `a_area` cut to `a_buffer`, then the label of a horizontal rule (see the class note).
		local
			l_area: RECT
			r, c, l_left, l_right: INTEGER
			l_glyph: CHARACTER_32
		do
			l_area := a_area.intersection (a_buffer.area)
			if not l_area.is_empty then
				l_glyph := glyph
				l_left := l_area.left.to_integer_32
				l_right := l_area.right.to_integer_32
				r := l_area.top.to_integer_32
				if is_horizontal then
					from
						c := l_left
					until
						c >= l_right
					loop
						a_buffer.put_char (r, c, l_glyph, a_buffer.cell (r, c).style.patch (style))
						c := c + 1
					end
					if attached label as l_label then
						render_label (l_label, r, l_left, l_right, a_buffer)
					end
				else
					from
					until
						r >= l_area.bottom.to_integer_32
					loop
						a_buffer.put_char (r, l_left, l_glyph, a_buffer.cell (r, l_left).style.patch (style))
						r := r + 1
					end
				end
			end
		end

feature {NONE} -- Implementation

	render_label (a_label: TEXT_LINE; a_row, a_left, a_right: INTEGER; a_buffer: BUFFER)
			-- Draw `a_label` with its padding on the rule drawn on row `a_row` in columns
			-- [`a_left`, `a_right`) of `a_buffer`, keeping one line cell at each end.
		require
			valid_row: a_row >= 0 and a_row < a_buffer.height
			valid_columns: 0 <= a_left and a_left < a_right and a_right <= a_buffer.width
		local
			l_lo, l_hi, l_pad, l_shown, l_total, l_start, c: INTEGER
			l_base: STYLE
		do
			l_lo := a_left + 1
			l_hi := a_right - 1
			l_pad := label_padding.to_integer_32
			if l_hi - l_lo > 2 * l_pad then
				l_shown := fitting_width (a_label, l_hi - l_lo - 2 * l_pad)
			end
			if l_shown > 0 then
				l_total := l_shown + 2 * l_pad
				if label_alignment = {TEXT_ALIGNMENT}.center then
					l_start := l_lo + (l_hi - l_lo - l_total) // 2
				elseif label_alignment = {TEXT_ALIGNMENT}.right then
					l_start := l_hi - l_total
				else
					l_start := l_lo
				end
				l_base := a_buffer.cell (a_row, l_start).style.twin
				from
					c := l_start
				until
					c >= l_start + l_total
				loop
					a_buffer.put_char (a_row, c, ' ', l_base)
					c := c + 1
				end
				a_buffer.set_line_clipped (a_row, l_start + l_pad, a_label, l_base, l_start + l_pad, l_start + l_pad + l_shown)
			end
		end

	fitting_width (a_line: TEXT_LINE; a_max: INTEGER): INTEGER
			-- Columns taken by the whole grapheme clusters of `a_line`, from its start, that
			-- fit in `a_max` columns (clusters split as BUFFER splits them, span by span).
		local
			s, i, l_end, l_w: INTEGER
			l_text: READABLE_STRING_GENERAL
			l_stop: BOOLEAN
		do
			from
				s := 1
			until
				l_stop or s > a_line.spans.count
			loop
				l_text := {UNICODE_SCALAR}.scalar_string (a_line.spans.i_th (s).content)
				from
					i := 1
				until
					l_stop or i > l_text.count
				loop
					l_end := {UNICODE_WIDTH}.grapheme_end (l_text, i)
					if l_end = i then
						l_w := {UNICODE_WIDTH}.width (l_text.code (i)).to_integer_32
					else
						l_w := {UNICODE_WIDTH}.grapheme_width (l_text.substring (i, l_end)).to_integer_32
					end
					if Result + l_w > a_max then
						l_stop := True
					else
						Result := Result + l_w
						i := l_end + 1
					end
				end
				s := s + 1
			end
		ensure
			in_range: 0 <= Result and Result <= a_max.max (0)
		end

invariant
	valid_direction: {DIVIDER_DIRECTION}.is_valid (direction)
	valid_line_set: {DIVIDER_LINE_SET}.is_valid (line_set)
	valid_label_alignment: {TEXT_ALIGNMENT}.is_valid (label_alignment)
	style_not_void: style /= Void

end
