note
	description: "[
		Multi-line styled text composed of an ordered list of TEXT_LINE objects.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEXT

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
	make_styled

convert
	make_raw ({READABLE_STRING_8, READABLE_STRING_32, STRING_8, STRING_32})

feature {NONE} -- Initialization

	default_create
			-- Initialize as empty text.
		do
			make_empty
		ensure then
			lines_empty: lines.is_empty
		end

	make_empty
			-- Initialize an empty text buffer.
		do
			create lines.make (8)
			create style.default_create
			alignment := {TEXT_ALIGNMENT}.left
		ensure
			lines_empty: lines.is_empty
			alignment_left: alignment = {TEXT_ALIGNMENT}.left
		end

	make (a_lines: ITERABLE [TEXT_LINE])
			-- Initialize with `a_lines`.
		require
			lines_not_void: a_lines /= Void
		do
			make_empty
			across
				a_lines as l
			loop
				append_line (l)
			end
		end

	make_raw (a_content: READABLE_STRING_GENERAL)
			-- Initialize text by splitting `a_content` on newlines (`%N`).
		require
			content_not_void: a_content /= Void
		local
			l_str: STRING_32
			l_split: LIST [STRING_32]
			l_line: TEXT_LINE
		do
			make_empty
			create l_str.make_from_string_general (a_content)
			l_str.prune_all ('%R')
			l_split := l_str.split ('%N')
			across
				l_split as s
			loop
				create l_line.make_raw (s)
				append_line (l_line)
			end
		end

	make_styled (a_content: READABLE_STRING_GENERAL; a_style: STYLE)
			-- Initialize text by splitting `a_content` with uniform `a_style`.
		require
			content_not_void: a_content /= Void
			style_not_void: a_style /= Void
		local
			l_str: STRING_32
			l_split: LIST [STRING_32]
			l_line: TEXT_LINE
		do
			make_empty
			style := a_style
			create l_str.make_from_string_general (a_content)
			l_str.prune_all ('%R')
			l_split := l_str.split ('%N')
			across
				l_split as s
			loop
				create l_line.make_styled (s, a_style)
				append_line (l_line)
			end
		end

feature -- Access

	lines: ARRAYED_LIST [TEXT_LINE]
			-- Ordered sequence of lines

	alignment: NATURAL_8
			-- Alignment mode (left, center, right)

	style: STYLE
			-- Baseline style

	line_count: INTEGER
			-- Number of lines
		do
			Result := lines.count
		ensure
			correct_count: Result = lines.count
		end

	max_width: NATURAL_16
			-- Maximum visual width across all lines
		local
			m: NATURAL_16
		do
			m := 0
			across
				lines as l
			loop
				m := m.max (l.width)
			end
			Result := m
		end

	is_empty: BOOLEAN
			-- Is text empty?
		do
			Result := lines.is_empty
		ensure
			empty_definition: Result = lines.is_empty
		end

feature -- Element change

	append_line (a_line: TEXT_LINE)
			-- Add `a_line` to text.
		require
			line_not_void: a_line /= Void
		do
			lines.extend (a_line)
		ensure
			line_added: lines.count = old lines.count + 1
			last_line: lines.last = a_line
		end

	append_raw_line (a_content: READABLE_STRING_GENERAL)
			-- Add a line from raw unstyled string `a_content`.
		require
			content_not_void: a_content /= Void
		local
			l_line: TEXT_LINE
		do
			create l_line.make_raw (a_content)
			append_line (l_line)
		ensure
			line_added: lines.count = old lines.count + 1
		end

	set_alignment (a_align: NATURAL_8)
			-- Set default alignment.
		require
			valid_align: {TEXT_ALIGNMENT}.is_valid (a_align)
		do
			alignment := a_align
		ensure
			alignment_set: alignment = a_align
		end

	set_style (a_style: STYLE)
			-- Set baseline style.
		require
			style_not_void: a_style /= Void
		do
			style := a_style
		ensure
			style_set: style = a_style
		end

feature -- Conversion

	to_plain_string: STRING_32
			-- Concatenated plain text representation with newlines.
		local
			i: INTEGER
		do
			create Result.make (lines.count * 32)
			from
				i := 1
			until
				i > lines.count
			loop
				Result.append (lines.i_th (i).to_plain_string)
				if i < lines.count then
					Result.append_character ('%N')
				end
				i := i + 1
			end
		ensure
			result_not_void: Result /= Void
		end

feature -- Duplication

	copy (a_other: like Current)
			-- Copy `a_other` to `Current`.
		local
			l_lines: ARRAYED_LIST [TEXT_LINE]
		do
			if a_other /= Current then
				standard_copy (a_other)
				create l_lines.make (a_other.lines.count)
				across a_other.lines as l loop
					l_lines.extend (l.twin)
				end
				lines := l_lines
			end
		end

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Is `a_other` content-equal to `Current`?
		local
			i: INTEGER
		do
			if a_other = Current then
				Result := True
			elseif standard_is_equal (a_other) then
				Result := True
			elseif alignment = a_other.alignment
				and style.is_equal (a_other.style)
				and lines.count = a_other.lines.count
			then
				Result := True
				from
					i := 1
				until
					i > lines.count or not Result
				loop
					Result := lines [i].is_equal (a_other.lines [i])
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
			-- Render multi-line text into `a_buffer` within `a_area`.
		local
			r, l_row, l_col, l_w: INTEGER
			l_line: TEXT_LINE
			l_start_col, l_line_w: INTEGER
			l_align: NATURAL_8
		do
			if not a_area.is_empty and a_area.height > 0 and a_area.width > 0 then
				l_col := a_area.x.to_integer_32
				l_w := a_area.width.to_integer_32
				from
					r := 1
				until
					r > lines.count or (a_area.y.to_integer_32 + r - 1) >= a_area.bottom.to_integer_32
				loop
					l_row := a_area.y.to_integer_32 + r - 1
					if l_row >= 0 and l_row < a_buffer.height then
						l_line := lines [r]
						if l_line.alignment /= {TEXT_ALIGNMENT}.left then
							l_align := l_line.alignment
						else
							l_align := alignment
						end
						l_line_w := l_line.width.to_integer_32
						inspect l_align
						when {TEXT_ALIGNMENT}.center then
							l_start_col := l_col + ((l_w - l_line_w) // 2).max (0)
						when {TEXT_ALIGNMENT}.right then
							l_start_col := l_col + (l_w - l_line_w).max (0)
						else
							l_start_col := l_col
						end
						a_buffer.set_line_clipped (l_row, l_start_col, l_line, style, l_col, l_col + l_w)
					end
					r := r + 1
				end
			end
		end

invariant
	lines_not_void: lines /= Void
	style_not_void: style /= Void
	valid_alignment: {TEXT_ALIGNMENT}.is_valid (alignment)

end
