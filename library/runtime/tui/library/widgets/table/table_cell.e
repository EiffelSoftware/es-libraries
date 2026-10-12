note
	description: "[
		Individual cell in a TABLE_ROW holding styled multi-line or single-line TEXT,
		cell-level style, column span, and horizontal alignment.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TABLE_CELL

inherit
	ANY
		redefine
			default_create,
			copy,
			is_equal,
			out
		end

create
	default_create,
	make_empty,
	make_raw,
	make_styled,
	make_span,
	make_line,
	make_text

feature -- Duplication

	copy (a_other: like Current)
			-- Re-create content on copy.
		do
			if a_other /= Current then
				standard_copy (a_other)
				content := a_other.content.twin
			end
		end

	is_equal (a_other: like Current): BOOLEAN
			-- Is `a_other` content-equal to `Current`?
		do
			if a_other = Current then
				Result := True
			elseif standard_is_equal (a_other) then
				Result := True
			else
				Result := column_span = a_other.column_span
					and alignment = a_other.alignment
					and style.is_equal (a_other.style)
					and content.is_equal (a_other.content)
			end
		end

feature {NONE} -- Initialization

	default_create
			-- Initialize as an empty cell.
		do
			create content.make_empty
			create style.default_create
			column_span := 1
			alignment := {TEXT_ALIGNMENT}.left
		ensure then
			content_empty: content.lines.is_empty
			span_is_one: column_span = 1
			align_left: alignment = {TEXT_ALIGNMENT}.left
		end

	make_empty
			-- Synonym for `default_create`.
		do
			default_create
		ensure
			content_empty: content.lines.is_empty
		end

	make_raw (a_text: READABLE_STRING_GENERAL)
			-- Initialize cell with unstyled plain text `a_text`.
		require
			text_not_void: a_text /= Void
		do
			create content.make_raw (a_text)
			create style.default_create
			column_span := 1
			alignment := {TEXT_ALIGNMENT}.left
		ensure
			span_is_one: column_span = 1
		end

	make_styled (a_text: READABLE_STRING_GENERAL; a_style: STYLE)
			-- Initialize cell with `a_text` and cell-level `a_style`.
		require
			text_not_void: a_text /= Void
			style_not_void: a_style /= Void
		do
			create content.make_raw (a_text)
			style := a_style
			column_span := 1
			alignment := {TEXT_ALIGNMENT}.left
		ensure
			style_set: style = a_style
			span_is_one: column_span = 1
		end

	make_span (a_span: TEXT_SPAN)
			-- Initialize cell with a single styled `a_span`.
		require
			span_not_void: a_span /= Void
		local
			l_line: TEXT_LINE
		do
			create l_line.make_empty
			l_line.append_span (a_span)
			create content.make_empty
			content.append_line (l_line)
			create style.default_create
			column_span := 1
			alignment := {TEXT_ALIGNMENT}.left
		ensure
			span_is_one: column_span = 1
		end

	make_line (a_line: TEXT_LINE)
			-- Initialize cell with a single line of text `a_line`.
		require
			line_not_void: a_line /= Void
		do
			create content.make_empty
			content.append_line (a_line)
			create style.default_create
			column_span := 1
			alignment := a_line.alignment
		ensure
			span_is_one: column_span = 1
		end

	make_text (a_text: TEXT)
			-- Initialize cell with multi-line `a_text`.
		require
			text_not_void: a_text /= Void
		do
			content := a_text
			create style.default_create
			column_span := 1
			alignment := a_text.alignment
		ensure
			content_set: content = a_text
			span_is_one: column_span = 1
		end

feature -- Access

	content: TEXT
			-- Textual content of the cell

	style: STYLE
			-- Style applied to the cell area and merged with content

	column_span: NATURAL_16
			-- Number of columns spanned by this cell (default 1)

	alignment: NATURAL_8
			-- Horizontal text alignment within the cell

	width: NATURAL_16
			-- Visual display width of the widest line in the cell
		local
			l_w: NATURAL_16
		do
			Result := 0
			across
				content.lines as l
			loop
				l_w := l.width
				if l_w > Result then
					Result := l_w
				end
			end
		end

	height: NATURAL_16
			-- Number of lines in cell content
		do
			Result := content.lines.count.to_natural_16
		end

feature -- Element change

	set_content (a_content: TEXT)
			-- Set cell text content.
		require
			content_not_void: a_content /= Void
		do
			content := a_content
		ensure
			content_set: content = a_content
		end

	set_style (a_style: STYLE)
			-- Set cell-level style.
		require
			style_not_void: a_style /= Void
		do
			style := a_style
		ensure
			style_set: style = a_style
		end

	set_column_span (a_span: NATURAL_16)
			-- Set number of columns spanned by this cell.
		require
			positive_span: a_span >= 1
		do
			column_span := a_span
		ensure
			column_span_set: column_span = a_span
		end

	set_alignment (a_alignment: NATURAL_8)
			-- Set horizontal alignment.
		require
			valid_alignment: {TEXT_ALIGNMENT}.is_valid (a_alignment)
		do
			alignment := a_alignment
		ensure
			alignment_set: alignment = a_alignment
		end

feature -- Fluent Builders

	with_style (a_style: STYLE): like Current
			-- Cell with `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_style (a_style)
		ensure
			style_set: Result.style = a_style
		end

	with_column_span (a_span: NATURAL_16): like Current
			-- Cell with `a_span`.
		require
			positive_span: a_span >= 1
		do
			Result := twin
			Result.set_column_span (a_span)
		ensure
			column_span_set: Result.column_span = a_span
		end

	with_alignment (a_alignment: NATURAL_8): like Current
			-- Cell with `a_alignment`.
		require
			valid_alignment: {TEXT_ALIGNMENT}.is_valid (a_alignment)
		do
			Result := twin
			Result.set_alignment (a_alignment)
		ensure
			alignment_set: Result.alignment = a_alignment
		end

feature -- Output

	out: STRING
			-- String representation for debugging, UTF-8 encoded.
		do
			create Result.make_from_string ("TABLE_CELL(")
			{UTF_CONVERTER}.utf_32_string_into_utf_8_string_8 (content.to_plain_string, Result)
			Result.append_character (')')
		end

invariant
	content_not_void: content /= Void
	style_not_void: style /= Void
	positive_column_span: column_span >= 1
	valid_alignment: {TEXT_ALIGNMENT}.is_valid (alignment)

end
