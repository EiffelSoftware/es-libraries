note
	description: "[
		Two-dimensional framebuffer storing a grid of TERMINAL_CELLs in a flat SPECIAL [TERMINAL_CELL].
		Coordinates are 0-based: row in 0..height-1, column in 0..width-1.

		Text is placed one grapheme cluster per cell (see {UNICODE_WIDTH}.grapheme_end), wide clusters
		take a continuation cell, and every writing operation keeps each row continuation-consistent.
		Cells are updated in place: writing text allocates nothing for ASCII and pooled code points,
		and consecutive writes with an equal style share one private copy of that style.

		Code points that are never drawn ({UNICODE_WIDTH}.is_never_drawn: C0/C1 controls, and the
		explicit bidi formatting characters) are dropped, so user text cannot move the cursor or
		reorder what the terminal displays. That includes TAB: tabs are not expanded, because the
		buffer does not know where the caller's tab stops are. Replace them before drawing (for
		example with spaces up to the next multiple of 4 or 8 columns).

		Diff options (Ratatui `CellDiffOption`, see CELL_DIFF_OPTION) are set with `set_diff_option`.
		Writing content into a cell (`put_char`, `put_string`, `set_stringn`, `set_string_clipped`,
		`set_span`, `set_line`, `set_line_clipped`, `fill`, `clear`, and the repair of a wide
		character the write cuts) clears that cell's option, so set an option after the content.
		Changing only the style (`set_style`, `set_style_region`) keeps it, as do `merge`,
		`copy_from` and `resize`. Ratatui's `Cell::set_symbol` keeps the option; here a cell that
		gets new content is an ordinary cell again, so a widget drawn over a skipped cell shows.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	BUFFER

create
	make

feature {NONE} -- Initialization

	make (a_width, a_height: INTEGER)
			-- Initialize buffer with `a_width` columns and `a_height` rows.
		require
			positive_width: a_width > 0
			positive_height: a_height > 0
			width_in_rect_range: a_width <= Max_extent
			height_in_rect_range: a_height <= Max_extent
		do
			width := a_width
			height := a_height
			cells := new_cells (a_width * a_height)
		ensure
			width_set: width = a_width
			height_set: height = a_height
			area_valid: area_count = a_width * a_height
		end

feature -- Access

	width: INTEGER
			-- Number of columns in buffer

	height: INTEGER
			-- Number of rows in buffer

	area: RECT
			-- Bounding rectangle for this entire buffer
		do
			create Result.make (0, 0, width.to_natural_16, height.to_natural_16)
		ensure
			origin_at_zero: Result.x = 0 and Result.y = 0
			width_matches: Result.width.to_integer_32 = width
			height_matches: Result.height.to_integer_32 = height
		end

	area_count: INTEGER
			-- Total number of cells
		do
			Result := width * height
		ensure
			correct_count: Result = width * height
		end

	cell (a_row, a_col: INTEGER): TERMINAL_CELL
			-- Cell at 0-based (`a_row`, `a_col`)
		require
			valid_row: a_row >= 0 and a_row < height
			valid_col: a_col >= 0 and a_col < width
		do
			Result := cells.item (index_of (a_row, a_col))
		ensure
			cell_attached: Result /= Void
		end

	is_valid_position (a_row, a_col: INTEGER): BOOLEAN
			-- Is (`a_row`, `a_col`) within buffer dimensions?
		do
			Result := a_row >= 0 and a_row < height and a_col >= 0 and a_col < width
		end

	is_continuation_consistent (a_row: INTEGER): BOOLEAN
			-- Are wide characters and their continuation cells consistent along `a_row`?
		require
			valid_row: a_row >= 0 and a_row < height
		do
			Result := is_continuation_consistent_between (a_row, 0, width)
		end

	is_continuation_consistent_between (a_row, a_from, a_to: INTEGER): BOOLEAN
			-- Is each cell of `a_row` in columns [`a_from`, `a_to`) (cut to the row) consistent with
			-- its neighbours: a continuation cell follows a wide character, and a wide character is
			-- followed by a continuation cell?
		require
			valid_row: a_row >= 0 and a_row < height
		local
			c: INTEGER
			l_c: TERMINAL_CELL
		do
			Result := True
			from
				c := a_from.max (0)
			until
				c >= a_to.min (width) or not Result
			loop
				l_c := cell (a_row, c)
				if l_c.is_continuation then
					if c = 0 or else cell (a_row, c - 1).width /= 2 then
						Result := False
					end
				elseif l_c.width = 2 then
					if c + 1 >= width or else not cell (a_row, c + 1).is_continuation then
						Result := False
					end
				end
				c := c + 1
			end
		end

	is_consistent: BOOLEAN
			-- Is every row continuation-consistent?
		local
			r: INTEGER
		do
			Result := True
			from
				r := 0
			until
				r >= height or not Result
			loop
				Result := is_continuation_consistent (r)
				r := r + 1
			end
		end

feature -- Element change

	put_cell (a_row, a_col: INTEGER; a_cell: TERMINAL_CELL)
			-- Place `a_cell` itself (not a copy) at 0-based (`a_row`, `a_col`).
			-- Low-level: the caller is responsible for continuation consistency.
		require
			valid_row: a_row >= 0 and a_row < height
			valid_col: a_col >= 0 and a_col < width
		do
			cells.put (a_cell, index_of (a_row, a_col))
		end

	set_diff_option (a_row, a_col: INTEGER; a_option, a_width: NATURAL_8)
			-- Give the cell at (`a_row`, `a_col`) diff option `a_option` (a CELL_DIFF_OPTION
			-- constant), with forced width `a_width` for `Forced_width` and 0 otherwise
			-- (Ratatui `Cell::set_diff_option`). The cell's content is unchanged.
			-- A forced width counts from this cell along its row; it does not reach the next row.
		require
			valid_row: a_row >= 0 and a_row < height
			valid_col: a_col >= 0 and a_col < width
			valid_option: {CELL_DIFF_OPTION}.is_valid (a_option)
			valid_width: {CELL_DIFF_OPTION}.is_valid_width (a_option, a_width)
			forced_not_continuation: a_option = {CELL_DIFF_OPTION}.Forced_width implies not cell (a_row, a_col).is_continuation
		do
			cell (a_row, a_col).set_diff_option_in_place (a_option, a_width)
		ensure
			option_set: cell (a_row, a_col).diff_option = a_option
			width_set: cell (a_row, a_col).forced_width = a_width
			same_symbol: cell (a_row, a_col).symbol = old cell (a_row, a_col).symbol
			same_style: cell (a_row, a_col).style = old cell (a_row, a_col).style
		end

	put_char (a_row, a_col: INTEGER; a_char: CHARACTER_32; a_style: STYLE)
			-- Place character `a_char` with `a_style` at (`a_row`, `a_col`), repairing any wide
			-- character it overlaps. A wide character that does not fit at the right edge becomes
			-- a blank with `a_style`. Zero-width characters (controls, combining marks) are ignored:
			-- use `set_stringn` to attach combining marks to a base character. A surrogate or a
			-- value above U+10FFFF is drawn as U+FFFD (see UNICODE_SCALAR).
		require
			valid_row: a_row >= 0 and a_row < height
			valid_col: a_col >= 0 and a_col < width
		local
			l_code: NATURAL_32
			l_w: NATURAL_8
		do
			l_code := {UNICODE_SCALAR}.scalar_value (a_char.natural_32_code)
			l_w := {UNICODE_WIDTH}.width (l_code)
			if l_w > 0 then
				put_grapheme (a_row, a_col, {TERMINAL_CELL}.pooled_char (l_code), l_w, owned_style (a_style))
			end
		ensure
			continuation_consistent: is_continuation_consistent (a_row)
		end

	put_string (a_row, a_col: INTEGER; a_string: READABLE_STRING_GENERAL; a_style: STYLE)
			-- Write `a_string` starting at (`a_row`, `a_col`), clipped at the right edge of the buffer.
		require
			valid_row: a_row >= 0 and a_row < height
			valid_col: a_col >= 0 and a_col < width
		do
			set_stringn (a_row, a_col, a_string, width - a_col, a_style)
		ensure
			continuation_consistent: is_continuation_consistent (a_row)
		end

	set_stringn (a_row, a_col: INTEGER; a_string: READABLE_STRING_GENERAL; a_max_width: INTEGER; a_style: STYLE)
			-- Write up to `a_max_width` columns of `a_string` at (`a_row`, `a_col`), clipped to buffer.
		require
			valid_row: a_row >= 0 and a_row < height
			valid_col: a_col >= 0 and a_col < width
			non_negative_max_width: a_max_width >= 0
		do
			set_string_clipped (a_row, a_col, a_string, a_col, a_col + a_max_width, a_style)
		ensure
			continuation_consistent: is_continuation_consistent (a_row)
		end

	set_string_clipped (a_row, a_col: INTEGER; a_string: READABLE_STRING_GENERAL; a_min_col, a_max_col: INTEGER; a_style: STYLE)
			-- Lay out `a_string` from column `a_col` (which may lie left of the buffer or of
			-- `a_min_col`) and write the grapheme clusters that fall inside columns
			-- [`a_min_col`, `a_max_col`) of the buffer.
			-- A wide cluster straddling `a_min_col` leaves a blank with `a_style`; one straddling
			-- `a_max_col` ends the write. A zero-width cluster at the start of `a_string` is attached
			-- to the cell left of `a_col` when that cell lies inside the clip range.
			-- A surrogate or a value above U+10FFFF is drawn as U+FFFD, in the same columns
			-- (see UNICODE_SCALAR).
		require
			valid_row: a_row >= 0 and a_row < height
		local
			i, l_end, c, l_lo, l_hi: INTEGER
			l_code: NATURAL_32
			l_w: NATURAL_8
			l_text: READABLE_STRING_GENERAL
			l_cluster: IMMUTABLE_STRING_32
			l_style: detachable STYLE
			l_stop: BOOLEAN
		do
			l_text := {UNICODE_SCALAR}.scalar_string (a_string)
			l_lo := a_min_col.max (0)
			l_hi := a_max_col.min (width)
			from
				i := 1
				c := a_col
			until
				l_stop or i > l_text.count or c >= l_hi
			loop
				l_end := {UNICODE_WIDTH}.grapheme_end (l_text, i)
				if l_end = i then
					l_code := l_text.code (i)
					l_w := {UNICODE_WIDTH}.width (l_code)
					l_cluster := {TERMINAL_CELL}.pooled_char (l_code)
				else
					create l_cluster.make_from_string_general (l_text.substring (i, l_end))
					l_w := {UNICODE_WIDTH}.grapheme_width (l_cluster)
				end
				if l_style = Void then
					l_style := owned_style (a_style)
				end
				if l_w = 0 then
					if not {UNICODE_WIDTH}.is_never_drawn (l_cluster.code (1)) then
						c := attached_to_previous (a_row, c, l_cluster, l_lo, l_hi)
					end
				elseif c >= l_lo then
					if c + l_w.to_integer_32 <= l_hi then
						put_grapheme (a_row, c, l_cluster, l_w, l_style)
						c := c + l_w.to_integer_32
					else
						l_stop := True
					end
				else
					if c + l_w.to_integer_32 > l_lo then
						-- Wide cluster cut by the left clip edge
						put_grapheme (a_row, l_lo, {TERMINAL_CELL}.pooled_char (32), 1, l_style)
					end
					c := c + l_w.to_integer_32
				end
				i := l_end + 1
			end
		ensure
			continuation_consistent: is_continuation_consistent (a_row)
		end

	set_span (a_row, a_col: INTEGER; a_span: TEXT_SPAN; a_max_width: INTEGER)
			-- Write `a_span` styled text at (`a_row`, `a_col`) up to `a_max_width` columns.
		require
			valid_row: a_row >= 0 and a_row < height
			valid_col: a_col >= 0 and a_col < width
			non_negative_max_width: a_max_width >= 0
		do
			set_stringn (a_row, a_col, a_span.content, a_max_width, a_span.style)
		ensure
			continuation_consistent: is_continuation_consistent (a_row)
		end

	set_line (a_row, a_col: INTEGER; a_line: TEXT_LINE; a_max_width: INTEGER)
			-- Write spans of `a_line` at (`a_row`, `a_col`) up to `a_max_width` columns.
		require
			valid_row: a_row >= 0 and a_row < height
			valid_col: a_col >= 0 and a_col < width
			non_negative_max_width: a_max_width >= 0
		do
			set_line_clipped (a_row, a_col, a_line, Default_style, a_col, a_col + a_max_width)
		ensure
			continuation_consistent: is_continuation_consistent (a_row)
		end

	set_line_clipped (a_row, a_col: INTEGER; a_line: TEXT_LINE; a_base_style: STYLE; a_min_col, a_max_col: INTEGER)
			-- Lay out `a_line` from column `a_col` (possibly left of `a_min_col`, e.g. when scrolled
			-- horizontally) and write what falls inside columns [`a_min_col`, `a_max_col`).
			-- Each span is drawn with `a_base_style` patched by the line style and the span style.
		require
			valid_row: a_row >= 0 and a_row < height
		local
			s, l_curr_col, l_hi: INTEGER
			l_span: TEXT_SPAN
			l_line_style: STYLE
		do
			l_hi := a_max_col.min (width)
			l_line_style := a_base_style.patch (a_line.style)
			l_curr_col := a_col
			from
				s := 1
			until
				s > a_line.spans.count or l_curr_col >= l_hi
			loop
				l_span := a_line.spans.i_th (s)
				set_string_clipped (a_row, l_curr_col, l_span.content, a_min_col, l_hi, l_line_style.patch (l_span.style))
				l_curr_col := l_curr_col + l_span.width.to_integer_32
				s := s + 1
			end
		ensure
			continuation_consistent: is_continuation_consistent (a_row)
		end

	set_style (a_area: RECT; a_style: STYLE)
			-- Apply `a_style` via patch to all cells in `a_area` intersecting this buffer.
		local
			r, c, l_r_end, l_c_end: INTEGER
			l_cell: TERMINAL_CELL
			l_last_src, l_last_res: detachable STYLE
		do
			if not a_area.is_empty then
				l_r_end := (a_area.bottom.to_integer_32).min (height)
				l_c_end := (a_area.right.to_integer_32).min (width)
				from
					r := (a_area.top.to_integer_32).max (0)
				until
					r >= l_r_end
				loop
					from
						c := (a_area.left.to_integer_32).max (0)
					until
						c >= l_c_end
					loop
						l_cell := cell (r, c)
						if not l_cell.is_continuation then
							if l_cell.style /= l_last_src or l_last_res = Void then
								l_last_src := l_cell.style
								l_last_res := l_cell.style.patch (a_style)
							end
							if attached l_last_res as l_res then
								l_cell.set_content_style (l_res)
							end
						end
						c := c + 1
					end
					r := r + 1
				end
			end
		end

	set_style_region (a_row, a_col, a_w, a_h: INTEGER; a_style: STYLE)
			-- Replace the style of all cells in the specified rectangle by `a_style`.
		require
			valid_row: a_row >= 0 and a_row < height
			valid_col: a_col >= 0 and a_col < width
			valid_w: a_w >= 0 and a_col + a_w <= width
			valid_h: a_h >= 0 and a_row + a_h <= height
		local
			r, c: INTEGER
			l_style: STYLE
		do
			l_style := owned_style (a_style)
			from
				r := a_row
			until
				r >= a_row + a_h
			loop
				from
					c := a_col
				until
					c >= a_col + a_w
				loop
					if not cell (r, c).is_continuation then
						cell (r, c).set_content_style (l_style)
					end
					c := c + 1
				end
				r := r + 1
			end
		end

	fill (a_char: CHARACTER_32; a_style: STYLE)
			-- Fill entire buffer with `a_char` and `a_style`: `put_char` on every cell, in row
			-- order, with the buffer's consistency checked once at the end (linear time).
		local
			r, c: INTEGER
			l_code: NATURAL_32
			l_w: NATURAL_8
			l_symbol: IMMUTABLE_STRING_32
			l_style: STYLE
		do
			l_code := {UNICODE_SCALAR}.scalar_value (a_char.natural_32_code)
			l_w := {UNICODE_WIDTH}.width (l_code)
			if l_w > 0 then
				l_symbol := {TERMINAL_CELL}.pooled_char (l_code)
				l_style := owned_style (a_style)
				from
					r := 0
				until
					r >= height
				loop
					from
						c := 0
					until
						c >= width
					loop
						put_grapheme (r, c, l_symbol, l_w, l_style)
						c := c + 1
					end
					r := r + 1
				end
			end
		ensure
			consistent: is_consistent
		end

	clear_area (a_area: RECT)
			-- Write a blank with the default style into every cell of `a_area` that lies in the
			-- buffer, as `put_char (row, col, ' ', default style)` on each would, so diff options
			-- are cleared and a wide character cut by the area's edge is split into blanks
			-- (TUI_CLEAR, Ratatui `Clear`). Linear in the area: the rows are checked once.
		local
			r, c, l_r_end, l_c_end: INTEGER
			l_blank: IMMUTABLE_STRING_32
			l_style: STYLE
		do
			if not a_area.is_empty then
				l_blank := {TERMINAL_CELL}.pooled_char (32)
				l_style := owned_style (Default_style)
				l_r_end := a_area.bottom.to_integer_32.min (height)
				l_c_end := a_area.right.to_integer_32.min (width)
				from
					r := a_area.y.to_integer_32
				until
					r >= l_r_end
				loop
					from
						c := a_area.x.to_integer_32
					until
						c >= l_c_end
					loop
						put_grapheme (r, c, l_blank, 1, l_style)
						c := c + 1
					end
					r := r + 1
				end
			end
		ensure
			rows_consistent: across a_area.y.to_integer_32 |..| (a_area.bottom.to_integer_32.min (height) - 1) as i_row all
				is_continuation_consistent (i_row) end
		end

	clear
			-- Reset all cells to default spaces in place, without diff options.
		local
			i: INTEGER
		do
			from
				i := 0
			until
				i >= area_count
			loop
				cells.item (i).reset
				i := i + 1
			end
		ensure
			consistent: is_consistent
		end

	resize (a_new_width, a_new_height: INTEGER)
			-- Resize buffer, preserving existing contents (and diff options) within the overlapping area.
			-- A wide character cut by the new right edge becomes a blank.
		require
			positive_width: a_new_width > 0
			positive_height: a_new_height > 0
			width_in_rect_range: a_new_width <= Max_extent
			height_in_rect_range: a_new_height <= Max_extent
		local
			l_new_cells: SPECIAL [TERMINAL_CELL]
			r, c: INTEGER
			l_min_w, l_min_h: INTEGER
		do
			if a_new_width /= width or a_new_height /= height then
				l_new_cells := new_cells (a_new_width * a_new_height)
				l_min_w := width.min (a_new_width)
				l_min_h := height.min (a_new_height)
				from
					r := 0
				until
					r >= l_min_h
				loop
					from
						c := 0
					until
						c >= l_min_w
					loop
						l_new_cells.put (cell (r, c), r * a_new_width + c)
						c := c + 1
					end
					r := r + 1
				end

				cells := l_new_cells
				width := a_new_width
				height := a_new_height
				normalize_rows
			end
		ensure
			width_set: width = a_new_width
			height_set: height = a_new_height
			area_valid: area_count = a_new_width * a_new_height
			consistent: is_consistent
		end

	merge (a_other: BUFFER)
			-- Overwrite the overlapping top-left area of `Current` with the cells of `a_other`,
			-- diff options included (like Ratatui `Buffer::merge`), then repair wide characters
			-- cut by its edges.
		local
			r, c, l_min_h, l_min_w: INTEGER
		do
			l_min_h := height.min (a_other.height)
			l_min_w := width.min (a_other.width)
			from
				r := 0
			until
				r >= l_min_h
			loop
				from
					c := 0
				until
					c >= l_min_w
				loop
					cell (r, c).copy_cell (a_other.cell (r, c))
					c := c + 1
				end
				r := r + 1
			end
			normalize_rows
		ensure
			consistent: is_consistent
		end

	copy_from (a_other: BUFFER)
			-- Copy all cell contents, styling and diff options from `a_other` (symbols and styles
			-- are shared).
		require
			same_dimensions: width = a_other.width and height = a_other.height
		local
			i: INTEGER
		do
			from
				i := 0
			until
				i >= area_count
			loop
				cells.item (i).copy_cell (a_other.cells.item (i))
				i := i + 1
			end
		end

feature -- Output & Inspection

	line (a_row: INTEGER): STRING_32
			-- Extract plain text representation of line `a_row`.
		require
			valid_row: a_row >= 0 and a_row < height
		local
			c: INTEGER
			l_cell: TERMINAL_CELL
		do
			create Result.make (width)
			from
				c := 0
			until
				c >= width
			loop
				l_cell := cell (a_row, c)
				if not l_cell.is_continuation then
					Result.append (l_cell.symbol)
				end
				c := c + 1
			end
		end

	rendered_text: STRING_32
			-- Entire buffer rendered as multiline text.
		local
			r: INTEGER
		do
			create Result.make (height * (width + 1))
			from
				r := 0
			until
				r >= height
			loop
				Result.append (line (r))
				if r < height - 1 then
					Result.append_character ('%N')
				end
				r := r + 1
			end
		end

feature {BUFFER, DIFF_ENGINE} -- Implementation

	cells: SPECIAL [TERMINAL_CELL]
			-- Flat storage of cells in row-major order

	index_of (a_row, a_col: INTEGER): INTEGER
			-- Compute flat index for 0-based (`a_row`, `a_col`).
		require
			valid_row: a_row >= 0 and a_row < height
			valid_col: a_col >= 0 and a_col < width
		do
			Result := a_row * width + a_col
		ensure
			valid_index: Result >= 0 and Result < area_count
		end

feature {NONE} -- Implementation

	last_owned_style: detachable STYLE
			-- Private style copy most recently stored in cells, shared by the cells that use it

	owned_style (a_style: STYLE): STYLE
			-- Private copy of `a_style` that cells may share: reuses the previous copy when equal.
		do
			if attached last_owned_style as l_last and then l_last.is_equal (a_style) then
				Result := l_last
			else
				Result := a_style.twin
				last_owned_style := Result
			end
		ensure
			equal: Result.is_equal (a_style)
			private: Result /= a_style
		end

	put_grapheme (a_row, a_col: INTEGER; a_symbol: IMMUTABLE_STRING_32; a_width: NATURAL_8; a_style: STYLE)
			-- Store cluster `a_symbol` of display width `a_width` at (`a_row`, `a_col`) in place,
			-- repairing the wide characters it overlaps. `a_symbol` and `a_style` are shared.
		require
			valid_row: a_row >= 0 and a_row < height
			valid_col: a_col >= 0 and a_col < width
			valid_width: a_width = 1 or a_width = 2
		local
			l_target: TERMINAL_CELL
		do
			l_target := cell (a_row, a_col)
			-- Overwriting the right half of a wide character: blank its left half
			if l_target.is_continuation and a_col > 0 then
				cell (a_row, a_col - 1).reset
			end
			-- Overwriting a wide character: blank its right half
			if l_target.width = 2 and a_col + 1 < width then
				cell (a_row, a_col + 1).reset
			end

			if a_width = 2 then
				if a_col + 1 < width then
					-- The cell to become our continuation may itself start a wide character
					if cell (a_row, a_col + 1).width = 2 and a_col + 2 < width then
						cell (a_row, a_col + 2).reset
					end
					l_target.set_content (a_symbol, 2, a_style)
					cell (a_row, a_col + 1).make_continuation_in_place
				else
					-- Cannot fit a 2-column glyph at the right edge: blank with the caller's style
					l_target.set_blank (a_style)
				end
			else
				l_target.set_content (a_symbol, 1, a_style)
			end
		ensure
				-- Only columns `a_col` - 1 .. `a_col` + 2 change, which only the checks of columns
				-- `a_col` - 2 .. `a_col` + 3 read: a row that was consistent stays consistent when
				-- these are. Checking only them keeps a write on a wide row in constant time; the
				-- public writers still check the whole row, once per call.
			consistent_around: is_continuation_consistent_between (a_row, a_col - 2, a_col + 4)
		end

	attached_to_previous (a_row, a_col: INTEGER; a_cluster: IMMUTABLE_STRING_32; a_lo, a_hi: INTEGER): INTEGER
			-- Append zero-width `a_cluster` to the cluster ending just left of `a_col`, provided that
			-- cell lies inside [`a_lo`, `a_hi`); return the column where writing continues.
		local
			l_col: INTEGER
			l_prev: TERMINAL_CELL
			l_builder: STRING_32
			l_symbol: IMMUTABLE_STRING_32
			l_w: NATURAL_8
		do
			Result := a_col
			l_col := a_col - 1
			if l_col >= a_lo and l_col < a_hi and l_col < width then
				if cell (a_row, l_col).is_continuation and l_col > a_lo then
					l_col := l_col - 1
				end
				l_prev := cell (a_row, l_col)
				if not l_prev.is_continuation then
					create l_builder.make (l_prev.symbol.count + a_cluster.count)
					l_builder.append (l_prev.symbol)
					l_builder.append (a_cluster)
					create l_symbol.make_from_string_32 (l_builder)
					l_w := {UNICODE_WIDTH}.grapheme_width (l_symbol)
					if l_w = l_prev.width then
						l_prev.set_content (l_symbol, l_w, l_prev.style)
					elseif l_w = 1 then
						-- e.g. VS15 turning a wide emoji into text presentation
						put_grapheme (a_row, l_col, l_symbol, 1, l_prev.style)
						Result := l_col + 1
					elseif l_w = 2 and l_col + 1 < a_hi then
						-- e.g. VS16 turning a narrow symbol into a wide emoji, with room to grow
						put_grapheme (a_row, l_col, l_symbol, 2, l_prev.style)
						Result := l_col + 2
					end
					-- Otherwise there is no room to grow: the selector is dropped.
				end
			end
		end

	normalize_rows
			-- Repair every row: blank orphan continuation cells, and give each wide character a
			-- continuation cell (or blank it at the right edge).
		local
			r, c: INTEGER
			l_cell: TERMINAL_CELL
		do
			from
				r := 0
			until
				r >= height
			loop
				from
					c := 0
				until
					c >= width
				loop
					l_cell := cell (r, c)
					if l_cell.is_continuation then
						if c = 0 or else cell (r, c - 1).width /= 2 then
							l_cell.reset
						end
					elseif l_cell.width = 2 then
						if c + 1 >= width then
							l_cell.set_blank (l_cell.style)
						elseif not cell (r, c + 1).is_continuation then
							cell (r, c + 1).make_continuation_in_place
						end
					end
					c := c + 1
				end
				r := r + 1
			end
		ensure
			consistent: is_consistent
		end

	new_cells (a_count: INTEGER): SPECIAL [TERMINAL_CELL]
			-- `a_count` fresh blank cells
		require
			non_negative: a_count >= 0
		local
			i: INTEGER
		do
			create Result.make_empty (a_count)
			from
				i := 0
			until
				i >= a_count
			loop
				Result.extend (create {TERMINAL_CELL}.default_create)
				i := i + 1
			end
		ensure
			count_set: Result.count = a_count
		end

feature -- Constants

	Max_extent: INTEGER = 65535
			-- Largest width and height: `area` is a RECT, whose coordinates are NATURAL_16
			-- (Ratatui's buffer area is a `Rect` of u16)

feature {NONE} -- Constants

	Default_style: STYLE
		once
			create Result.default_create
		ensure
			instance_free: class
		end

invariant
	positive_dimensions: width > 0 and height > 0
	dimensions_in_rect_range: width <= Max_extent and height <= Max_extent
	cells_count_consistent: cells.count = area_count

end
