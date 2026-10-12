note
	description: "[
		Multi-column tabular data grid widget supporting column constraints,
		sticky header/footer, row and column selection, scrolling, and block styling.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_TABLE

inherit
	STATEFUL_WIDGET [TABLE_STATE]
		redefine
			default_create,
			copy,
			is_equal
		end
	BLOCK_CONTAINER
		redefine
			default_create,
			copy,
			is_equal
		end

create
	default_create,
	make_empty,
	make

feature {NONE} -- Initialization

	default_create
			-- Initialize as an empty table.
		do
			create row_store.make (8)
			create widths.make (4)
			column_spacing := 1
			flex := {FLEX_JUSTIFY}.start_align
			create style.default_create
			create row_highlight_style.default_create
			create column_highlight_style.default_create
			create cell_highlight_style.default_create
			create highlight_symbol.make_empty
		ensure then
			rows_empty: rows.is_empty
			widths_empty: widths.is_empty
			column_spacing_default: column_spacing = 1
			flex_start: flex.is_start
			no_header: header = Void
			no_footer: footer = Void
		end

	make_empty
			-- Synonym for `default_create`.
		do
			default_create
		ensure
			rows_empty: rows.is_empty
		end

	make (a_rows: ITERABLE [TABLE_ROW]; a_widths: ITERABLE [CONSTRAINT])
			-- Initialize table with `a_rows` and column `a_widths`.
		require
			rows_not_void: a_rows /= Void
			widths_not_void: a_widths /= Void
		do
			default_create
			set_rows (a_rows)
			set_widths (a_widths)
		end

feature {TUI_TABLE} -- Copy on write

	row_store: ARRAYED_LIST [TABLE_ROW]
			-- Data rows, possibly shared with copies of `Current` (see `rows_shared`)

	rows_shared: BOOLEAN
			-- Is `row_store` shared with another object?

	mark_rows_shared
			-- Record that `row_store` is now shared with a copy.
		do
			rows_shared := True
		ensure
			shared: rows_shared
		end

	own_rows
			-- Give `Current` its own copy of the data rows if they are shared.
		do
			if rows_shared then
				row_store := copied_rows (row_store)
				rows_shared := False
			end
		ensure
			not_shared: not rows_shared
		end

feature {NONE} -- Copy on write

	copied_rows (a_list: ARRAYED_LIST [TABLE_ROW]): ARRAYED_LIST [TABLE_ROW]
			-- Copy of `a_list` holding copies of its elements
		do
			create Result.make (a_list.count)
			across a_list as e loop
				Result.extend (e.twin)
			end
		end

feature -- Access

	rows: ARRAYED_LIST [TABLE_ROW]
			-- Table data rows (owned by `Current`: content still shared with a copy is copied first)
		do
			own_rows
			Result := row_store
		ensure
			owned: not rows_shared
		end

	widths: ARRAYED_LIST [CONSTRAINT]
			-- Column width constraints

	header: detachable TABLE_ROW
			-- Optional sticky header row

	footer: detachable TABLE_ROW
			-- Optional sticky footer row

	column_spacing: NATURAL_16
			-- Spacing (in characters) between adjacent columns (default 1)

	flex: FLEX_JUSTIFY
			-- Flex justification strategy for distributing spare horizontal space across columns

	style: STYLE
			-- Base style for the entire table
			-- Base style for the entire table

	row_highlight_style: STYLE
			-- Style applied to the selected row

	column_highlight_style: STYLE
			-- Style applied to the selected column

	cell_highlight_style: STYLE
			-- Style applied to the cell at intersection of selected row and column

	highlight_symbol: STRING_32
			-- Prefix symbol rendered before selected row (e.g. "> ")

	count: INTEGER
			-- Total number of data rows
		do
			Result := row_store.count
		ensure
			correct_count: Result = row_store.count
		end

	column_count: INTEGER
			-- Maximum number of columns across widths, rows, header, and footer.
		local
			m: INTEGER
		do
			m := widths.count
			if attached header as h and then h.count > m then
				m := h.count
			end
			if attached footer as f and then f.count > m then
				m := f.count
			end
			across
				row_store as r
			loop
				if r.count > m then
					m := r.count
				end
			end
			Result := m
		ensure
			non_negative: Result >= 0
		end

feature -- Element change

	append_row (a_row: TABLE_ROW)
			-- Append `a_row` to table.
		require
			row_not_void: a_row /= Void
		do
			rows.extend (a_row)
		ensure
			row_added: rows.count = old rows.count + 1
			last_row: rows.last = a_row
		end

	set_rows (a_rows: ITERABLE [TABLE_ROW])
			-- Replace data rows with `a_rows`.
		require
			rows_not_void: a_rows /= Void
		do
			rows.wipe_out
			across
				a_rows as r
			loop
				rows.extend (r)
			end
		end

	set_widths (a_widths: ITERABLE [CONSTRAINT])
			-- Replace column constraints with `a_widths`.
		require
			widths_not_void: a_widths /= Void
		do
			widths.wipe_out
			across
				a_widths as w
			loop
				widths.extend (w)
			end
		end

	set_header (a_header: detachable TABLE_ROW)
			-- Set or clear sticky header row.
		do
			header := a_header
		ensure
			header_set: header = a_header
		end

	set_footer (a_footer: detachable TABLE_ROW)
			-- Set or clear sticky footer row.
		do
			footer := a_footer
		ensure
			footer_set: footer = a_footer
		end

	set_column_spacing (a_spacing: NATURAL_16)
			-- Set character spacing between columns.
		do
			column_spacing := a_spacing
		ensure
			spacing_set: column_spacing = a_spacing
		end

	set_flex (a_flex: FLEX_JUSTIFY)
			-- Set column flex justification strategy.
		require
			flex_not_void: a_flex /= Void
		do
			flex := a_flex
		ensure
			flex_set: flex = a_flex
		end

feature -- Duplication

	copy (a_other: like Current)
			-- Copy `a_other` to `Current`.
			-- The data rows are copied on write (see `rows`); rendering never copies them.
		do
			if a_other /= Current then
				standard_copy (a_other)
				rows_shared := True
				a_other.mark_rows_shared
				widths := a_other.widths.twin
				if attached a_other.header as h then
					header := h.twin
				end
				if attached a_other.footer as f then
					footer := f.twin
				end
			end
		end

	is_equal (a_other: like Current): BOOLEAN
			-- Is `a_other` content-equal to `Current`?
		local
			i: INTEGER
		do
			if a_other = Current then
				Result := True
			elseif standard_is_equal (a_other) then
				Result := True
			elseif same_block (a_other)
				and style.is_equal (a_other.style)
				and column_spacing = a_other.column_spacing
				and flex = a_other.flex
				and row_highlight_style.is_equal (a_other.row_highlight_style)
				and column_highlight_style.is_equal (a_other.column_highlight_style)
				and cell_highlight_style.is_equal (a_other.cell_highlight_style)
				and highlight_symbol.same_string (a_other.highlight_symbol)
				and header ~ a_other.header
				and footer ~ a_other.footer
				and widths.count = a_other.widths.count
				and row_store.count = a_other.row_store.count
			then
				Result := True
				from
					i := 1
				until
					i > widths.count or not Result
				loop
					Result := widths [i].is_equal (a_other.widths [i])
					i := i + 1
				end
				if Result then
					from
						i := 1
					until
						i > row_store.count or not Result
					loop
						Result := row_store [i].is_equal (a_other.row_store [i])
						i := i + 1
					end
				end
			end
		end

	set_style (a_style: STYLE)
			-- Set table base style.
		require
			style_not_void: a_style /= Void
		do
			style := a_style
		ensure
			style_set: style = a_style
		end

	set_row_highlight_style (a_style: STYLE)
			-- Set style for selected row.
		require
			style_not_void: a_style /= Void
		do
			row_highlight_style := a_style
		ensure
			row_highlight_style_set: row_highlight_style = a_style
		end

	set_column_highlight_style (a_style: STYLE)
			-- Set style for selected column.
		require
			style_not_void: a_style /= Void
		do
			column_highlight_style := a_style
		ensure
			column_highlight_style_set: column_highlight_style = a_style
		end

	set_cell_highlight_style (a_style: STYLE)
			-- Set style for selected cell (intersection).
		require
			style_not_void: a_style /= Void
		do
			cell_highlight_style := a_style
		ensure
			cell_highlight_style_set: cell_highlight_style = a_style
		end

	set_highlight_symbol (a_symbol: READABLE_STRING_GENERAL)
			-- Set prefix symbol for selected row.
		require
			symbol_not_void: a_symbol /= Void
		do
			create highlight_symbol.make_from_string_general (a_symbol)
		ensure
			symbol_set: highlight_symbol.same_string_general (a_symbol)
		end

feature -- Fluent Builders

	with_rows (a_rows: ITERABLE [TABLE_ROW]): like Current
			-- Return a copy of Current with `a_rows`.
		require
			rows_not_void: a_rows /= Void
		do
			Result := twin
			Result.set_rows (a_rows)
		ensure
			result_not_void: Result /= Void
		end

	with_widths (a_widths: ITERABLE [CONSTRAINT]): like Current
			-- Return a copy of Current with column `a_widths`.
		require
			widths_not_void: a_widths /= Void
		do
			Result := twin
			Result.set_widths (a_widths)
		ensure
			result_not_void: Result /= Void
		end

	with_header (a_header: detachable TABLE_ROW): like Current
			-- Return a copy of Current with `a_header`.
		do
			Result := twin
			Result.set_header (a_header)
		ensure
			header_set: Result.header = a_header
			result_not_void: Result /= Void
		end

	with_footer (a_footer: detachable TABLE_ROW): like Current
			-- Return a copy of Current with `a_footer`.
		do
			Result := twin
			Result.set_footer (a_footer)
		ensure
			footer_set: Result.footer = a_footer
			result_not_void: Result /= Void
		end

	with_column_spacing (a_spacing: NATURAL_16): like Current
			-- Return a copy of Current with `a_spacing` between columns.
		do
			Result := twin
			Result.set_column_spacing (a_spacing)
		ensure
			spacing_set: Result.column_spacing = a_spacing
			result_not_void: Result /= Void
		end

	with_flex (a_flex: FLEX_JUSTIFY): like Current
			-- Return a copy of Current with column flex justification `a_flex`.
		require
			flex_not_void: a_flex /= Void
		do
			Result := twin
			Result.set_flex (a_flex)
		ensure
			flex_set: Result.flex = a_flex
			result_not_void: Result /= Void
		end

	with_style (a_style: STYLE): like Current
			-- Return a copy of Current with base `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_style (a_style)
		ensure
			style_set: Result.style = a_style
			result_not_void: Result /= Void
		end

	with_row_highlight_style (a_style: STYLE): like Current
			-- Return a copy of Current with row highlight `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_row_highlight_style (a_style)
		ensure
			row_highlight_style_set: Result.row_highlight_style = a_style
			result_not_void: Result /= Void
		end

	with_column_highlight_style (a_style: STYLE): like Current
			-- Return a copy of Current with column highlight `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_column_highlight_style (a_style)
		ensure
			column_highlight_style_set: Result.column_highlight_style = a_style
			result_not_void: Result /= Void
		end

	with_cell_highlight_style (a_style: STYLE): like Current
			-- Return a copy of Current with cell highlight `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_cell_highlight_style (a_style)
		ensure
			cell_highlight_style_set: Result.cell_highlight_style = a_style
			result_not_void: Result /= Void
		end

	with_highlight_symbol (a_symbol: READABLE_STRING_GENERAL): like Current
			-- Return a copy of Current with `a_symbol` prefix for selected row.
		require
			symbol_not_void: a_symbol /= Void
		do
			Result := twin
			Result.set_highlight_symbol (a_symbol)
		ensure
			result_not_void: Result /= Void
		end

feature -- Rendering

	render (a_area: RECT; a_buffer: BUFFER)
			-- Stateless rendering using a default empty TABLE_STATE.
		local
			l_state: TABLE_STATE
		do
			create l_state.default_create
			render_stateful (a_area, a_buffer, l_state)
		end

	render_table (a_area: RECT; a_buffer: BUFFER; a_state: TABLE_STATE)
			-- Synonym for `render_stateful`.
		require
			area_not_void: a_area /= Void
			buffer_not_void: a_buffer /= Void
			state_not_void: a_state /= Void
		do
			render_stateful (a_area, a_buffer, a_state)
		end

	render_stateful (a_area: RECT; a_buffer: BUFFER; a_state: TABLE_STATE)
			-- Render table grid using mutable `a_state`.
		local
			l_target_area: RECT
			l_sym_w: NATURAL_16
			l_avail_cols_width: NATURAL_16
			l_col_x, l_col_w: ARRAYED_LIST [NATURAL_16]
			l_hdr_h, l_ftr_h, l_rows_h: INTEGER
			l_hdr_y, l_ftr_y, l_rows_y: INTEGER
			l_row_idx, l_curr_y, l_row_y, l_avail_h, l_paint_h: INTEGER
			l_col_offset: INTEGER
			l_row: TABLE_ROW
			l_is_sel: BOOLEAN
			l_row_base_style: STYLE
			l_sel_col, l_sel_row_y, l_sel_row_h, l_vis_idx, l_sel_col_x: INTEGER
		do
			if not a_area.is_empty then
				render_block (a_area, a_buffer)
				l_target_area := inner_area (a_area)

				if not l_target_area.is_empty and l_target_area.width > 0 and l_target_area.height > 0 then
					apply_cell_style (l_target_area.y.to_integer_32, l_target_area.x.to_integer_32, l_target_area.width.to_integer_32, l_target_area.height.to_integer_32, style, a_buffer)

					if a_state.has_selection and then not highlight_symbol.is_empty then
						l_sym_w := {UNICODE_WIDTH}.string_width (highlight_symbol)
					else
						l_sym_w := 0
					end

					if l_target_area.width > l_sym_w then
						l_avail_cols_width := l_target_area.width - l_sym_w
					else
						l_avail_cols_width := 0
					end

					create l_col_x.make (4)
					create l_col_w.make (4)
					-- Columns keep their requested widths; only those that fit after the offset are shown.
					-- Scroll right (or left) until the selected column is visible.
					l_col_offset := a_state.column_offset.min (column_count).max (1)
					if a_state.has_column_selection and column_count > 0 and l_avail_cols_width > 0 then
						l_sel_col := a_state.selected_column.min (column_count)
						if l_sel_col < l_col_offset then
							l_col_offset := l_sel_col
						end
						from
						until
							l_col_offset >= l_sel_col or else
								l_sel_col < l_col_offset + visible_column_count (l_col_offset, l_avail_cols_width.to_integer_32)
						loop
							l_col_offset := l_col_offset + 1
						end
						a_state.set_column_offset (l_col_offset)
					end
					compute_column_widths (l_avail_cols_width.to_integer_32, l_col_offset, column_count, l_col_x, l_col_w)

					if attached header as h then
						l_hdr_h := h.total_height.to_integer_32.min (l_target_area.height.to_integer_32)
					else
						l_hdr_h := 0
					end

					if attached footer as f then
						l_ftr_h := f.total_height.to_integer_32.min (l_target_area.height.to_integer_32 - l_hdr_h)
					else
						l_ftr_h := 0
					end

					l_rows_h := (l_target_area.height.to_integer_32 - l_hdr_h - l_ftr_h).max (0)
					l_hdr_y := l_target_area.y.to_integer_32
					l_rows_y := l_hdr_y + l_hdr_h
					l_ftr_y := l_rows_y + l_rows_h

					-- 1. Render Header
					if attached header as h and then l_hdr_h > 0 then
						render_row_cells (h, l_hdr_y + h.top_margin.to_integer_32, h.height.to_integer_32.min (l_hdr_h), style.patch (h.style), False, l_sym_w, l_col_offset, l_col_x, l_col_w, l_target_area, a_state, a_buffer)
					end

					-- 2. Render Rows
					if l_rows_h > 0 and not row_store.is_empty then
						a_state.adjust_viewport (l_rows_h, row_store.count)
						l_row_idx := a_state.offset
						l_curr_y := l_rows_y

						from
						until
							l_curr_y >= l_rows_y + l_rows_h or l_row_idx > row_store.count
						loop
							l_row := row_store.i_th (l_row_idx)
							l_is_sel := a_state.has_selection and then (a_state.selected = l_row_idx)
							l_row_y := l_curr_y + l_row.top_margin.to_integer_32
							l_avail_h := (l_rows_y + l_rows_h - l_row_y).max (0)

							if l_avail_h > 0 then
								l_paint_h := l_row.height.to_integer_32.min (l_avail_h)
								l_row_base_style := style.patch (l_row.style)
								if l_is_sel then
									l_sel_row_y := l_row_y
									l_sel_row_h := l_paint_h
									if not highlight_symbol.is_empty and l_sym_w > 0 and l_row_y < a_buffer.height then
										-- Clipped to the symbol column, the area and the buffer
										a_buffer.set_string_clipped (l_row_y, l_target_area.x.to_integer_32, highlight_symbol,
											l_target_area.x.to_integer_32,
											(l_target_area.x.to_integer_32 + l_sym_w.to_integer_32).min (l_target_area.right.to_integer_32),
											l_row_base_style)
									end
								end

								render_row_cells (l_row, l_row_y, l_paint_h, l_row_base_style, l_is_sel, l_sym_w, l_col_offset, l_col_x, l_col_w, l_target_area, a_state, a_buffer)
							end

							l_curr_y := l_curr_y + l_row.total_height.to_integer_32
							l_row_idx := l_row_idx + 1
						end
					end

					-- Highlights come after the cells, so they win over cell styles (Ratatui order):
					-- the selected row (full width, gaps and symbol column included), the selected column
					-- across the body rows, then their intersection.
					if l_sel_row_h > 0 then
						a_buffer.set_style (area_rect (l_target_area.x.to_integer_32, l_sel_row_y, l_target_area.width.to_integer_32, l_sel_row_h), row_highlight_style)
					end
					if a_state.has_column_selection and l_rows_h > 0 then
						l_vis_idx := a_state.selected_column - l_col_offset + 1
						if l_vis_idx >= 1 and l_vis_idx <= l_col_w.count then
							l_sel_col_x := l_target_area.x.to_integer_32 + l_sym_w.to_integer_32 + l_col_x.i_th (l_vis_idx).to_integer_32
							a_buffer.set_style (area_rect (l_sel_col_x, l_rows_y, l_col_w.i_th (l_vis_idx).to_integer_32, l_rows_h), column_highlight_style)
							if l_sel_row_h > 0 then
								a_buffer.set_style (area_rect (l_sel_col_x, l_sel_row_y, l_col_w.i_th (l_vis_idx).to_integer_32, l_sel_row_h), cell_highlight_style)
							end
						end
					end

					-- 3. Render Footer
					if attached footer as f and then l_ftr_h > 0 then
						render_row_cells (f, l_ftr_y + f.top_margin.to_integer_32, f.height.to_integer_32.min (l_ftr_h), style.patch (f.style), False, l_sym_w, l_col_offset, l_col_x, l_col_w, l_target_area, a_state, a_buffer)
					end
				end
			end
		end

feature {NONE} -- Implementation: Columns

	column_constraint (a_column: INTEGER): CONSTRAINT
			-- Width constraint of column `a_column` (Flex (1) when none was given)
		do
			if a_column >= 1 and a_column <= widths.count then
				Result := widths.i_th (a_column)
			else
				Result := {CONSTRAINTS}.flex (1)
			end
		end

	requested_width (a_constraint: CONSTRAINT; a_available_width: INTEGER): INTEGER
			-- Width `a_constraint` asks for when `a_available_width` columns are available:
			-- its value for Fixed, Min and Max, its share for Percentage and Ratio, 1 for Flex
			-- (a flexible column takes spare space later, but needs at least one cell)
		do
			if attached {CONSTRAINT_FIXED} a_constraint as c then
				Result := c.value.to_integer_32
			elseif attached {CONSTRAINT_MIN} a_constraint as c then
				Result := c.min_value.to_integer_32
			elseif attached {CONSTRAINT_MAX} a_constraint as c then
				Result := c.max_value.to_integer_32
			elseif attached {CONSTRAINT_PERCENTAGE} a_constraint as c then
				Result := (a_available_width.to_natural_64 * c.percent_value.to_natural_64 // 100).to_integer_32
			elseif attached {CONSTRAINT_RATIO} a_constraint as c then
				Result := (a_available_width.to_natural_64 * c.numerator.to_natural_64 // c.denominator.to_natural_64.max (1)).to_integer_32
			else
				Result := 1
			end
		ensure
			non_negative: Result >= 0
		end

	visible_column_count (a_start_col, a_available_width: INTEGER): INTEGER
			-- Number of columns, from `a_start_col` on, that fit in `a_available_width` at their
			-- requested width (with column spacing); at least one while columns remain, so a
			-- column wider than the area is shown clipped rather than hidden.
		local
			i, l_used, l_needed: INTEGER
			l_stop: BOOLEAN
		do
			from
				i := a_start_col
			until
				l_stop or i > column_count
			loop
				l_needed := l_used + requested_width (column_constraint (i), a_available_width)
				if Result > 0 then
					l_needed := l_needed + column_spacing.to_integer_32
				end
				if l_needed <= a_available_width or Result = 0 then
					l_used := l_needed
					Result := Result + 1
					i := i + 1
				else
					l_stop := True
				end
			end
		ensure
			bounded: Result <= (column_count - a_start_col + 1).max (0)
			at_least_one: a_start_col <= column_count and a_available_width > 0 implies Result >= 1
		end

	area_rect (a_x, a_y, a_w, a_h: INTEGER): RECT
			-- Rectangle from integer coordinates, clamped to the RECT range
		do
			create Result.make (a_x.max (0).min (65535).to_natural_16, a_y.max (0).min (65535).to_natural_16,
				a_w.max (0).min (65535).to_natural_16, a_h.max (0).min (65535).to_natural_16)
		end

feature {NONE} -- Implementation: Row and Cell Rendering

	render_row_cells (
		a_row: TABLE_ROW;
		a_target_row_y, a_paint_h: INTEGER;
		a_row_style: STYLE;
		a_is_selected: BOOLEAN;
		a_sym_w: NATURAL_16;
		a_col_offset: INTEGER;
		a_col_x, a_col_w: ARRAYED_LIST [NATURAL_16];
		a_target_area: RECT;
		a_state: TABLE_STATE;
		a_buffer: BUFFER
	)
			-- Render cells of `a_row` across column layout starting from `a_col_offset`.
		local
			c_data_idx, i: INTEGER
			l_cell: TABLE_CELL
			l_span, v_start, v_end, v_span: INTEGER
			l_cell_w, l_cell_x: INTEGER
			l_cell_eff_style: STYLE
		do
			c_data_idx := 1
			from
				i := 1
			until
				i > a_row.cells.count or a_col_w.is_empty
			loop
				l_cell := a_row.cells.i_th (i)
				l_span := l_cell.column_span.to_integer_32

				-- Check if cell overlaps visible columns [a_col_offset, a_col_offset + a_col_w.count - 1]
				if (c_data_idx + l_span - 1 >= a_col_offset) and (c_data_idx < a_col_offset + a_col_w.count) then
					v_start := (c_data_idx - a_col_offset + 1).max (1)
					v_end := (c_data_idx + l_span - a_col_offset).min (a_col_w.count)
					v_span := v_end - v_start + 1

					if v_span > 0 and v_start <= a_col_w.count then
						l_cell_w := compute_span_width (v_start, v_span, a_col_w)
						l_cell_x := a_target_area.x.to_integer_32 + a_sym_w.to_integer_32 + a_col_x.i_th (v_start).to_integer_32

						l_cell_eff_style := a_row_style.patch (l_cell.style)

						apply_cell_style (a_target_row_y, l_cell_x, l_cell_w, a_paint_h, l_cell_eff_style, a_buffer)
						render_cell_content (l_cell, a_target_row_y, l_cell_x, l_cell_w, a_paint_h, l_cell_eff_style, a_target_area, a_buffer)
					end
				end

				c_data_idx := c_data_idx + l_span
				i := i + 1
			end
		end

	compute_span_width (a_start_col, a_span: INTEGER; a_col_w: ARRAYED_LIST [NATURAL_16]): INTEGER
			-- Width of `a_span` columns starting at `a_start_col` including column spacing.
		local
			j: INTEGER
			w: INTEGER
		do
			w := 0
			from
				j := a_start_col
			until
				j >= a_start_col + a_span
			loop
				w := w + a_col_w.i_th (j).to_integer_32
				if j < a_start_col + a_span - 1 then
					w := w + column_spacing.to_integer_32
				end
				j := j + 1
			end
			Result := w
		end

	render_cell_content (
		a_cell: TABLE_CELL;
		a_target_row_y, a_start_col, a_cell_width, a_paint_h: INTEGER;
		a_eff_style: STYLE;
		a_target_area: RECT;
		a_buffer: BUFFER
	)
			-- Paint lines of `a_cell` inside cell bounding area.
		local
			l, l_max_lines: INTEGER
			l_line: TEXT_LINE
			l_line_y: INTEGER
		do
			l_max_lines := a_cell.content.lines.count.min (a_paint_h)
			from
				l := 1
			until
				l > l_max_lines
			loop
				l_line := a_cell.content.lines.i_th (l)
				l_line_y := a_target_row_y + l - 1
				if l_line_y >= 0 and l_line_y < a_buffer.height and l_line_y < a_target_area.bottom.to_integer_32 then
					render_cell_line (l_line, a_cell.alignment, l_line_y, a_start_col, a_cell_width, a_eff_style, a_target_area, a_buffer)
				end
				l := l + 1
			end
		end

	render_cell_line (
		a_line: TEXT_LINE;
		a_align: NATURAL_8;
		a_row, a_start_col, a_cell_width: INTEGER;
		a_base_style: STYLE;
		a_target_area: RECT;
		a_buffer: BUFFER
	)
			-- Paint characters of a single line aligned within `a_cell_width`.
		local
			l_vw, l_offset, l_right_bound: INTEGER
		do
			l_vw := a_line.width.to_integer_32
			if a_align = {TEXT_ALIGNMENT}.center then
				l_offset := ((a_cell_width - l_vw) // 2).max (0)
			elseif a_align = {TEXT_ALIGNMENT}.right then
				l_offset := (a_cell_width - l_vw).max (0)
			else
				l_offset := 0
			end

			l_right_bound := (a_start_col + a_cell_width).min (a_target_area.right.to_integer_32)
			a_buffer.set_line_clipped (a_row, a_start_col + l_offset, a_line, a_base_style,
				a_start_col.max (a_target_area.x.to_integer_32), l_right_bound)
		end


	apply_cell_style (a_row, a_col, a_w, a_h: INTEGER; a_style: STYLE; a_buffer: BUFFER)
			-- Apply `a_style` to rectangular subregion bounded by buffer limits.
		local
			r_start, c_start, r_end, c_end, w, h: INTEGER
		do
			r_start := a_row.max (0)
			c_start := a_col.max (0)
			r_end := (a_row + a_h).min (a_buffer.height)
			c_end := (a_col + a_w).min (a_buffer.width)
			w := c_end - c_start
			h := r_end - r_start
			if w > 0 and h > 0 then
				a_buffer.set_style (area_rect (c_start, r_start, w, h), a_style)
			end
		end

	compute_column_widths (
		a_available_width: INTEGER;
		a_start_col: INTEGER;
		a_col_count: INTEGER;
		a_col_x, a_col_w: ARRAYED_LIST [NATURAL_16]
	)
			-- Calculate column x offsets and widths using LAYOUT starting from `a_start_col`.
		local
			l_constraints: ARRAYED_LIST [CONSTRAINT]
			l_layout: LAYOUT
			l_virtual_rect: RECT
			l_rects: ARRAYED_LIST [RECT]
			i, l_num_cols: INTEGER
		do
			if a_col_count >= a_start_col and a_available_width > 0 then
				l_num_cols := visible_column_count (a_start_col, a_available_width)
				create l_constraints.make (l_num_cols)
				from
					i := a_start_col
				until
					i >= a_start_col + l_num_cols
				loop
					l_constraints.extend (column_constraint (i))
					i := i + 1
				end

				create l_layout.make_with_all (
					{SPLIT_DIRECTION}.horizontal,
					l_constraints,
					create {MARGIN}.default_create,
					column_spacing.as_integer_32,
					flex
				)
				create l_virtual_rect.make (0, 0, a_available_width.to_natural_16, 1)
				l_rects := l_layout.split_list (l_virtual_rect)

				from
					i := 1
				until
					i > l_rects.count
				loop
					a_col_x.extend (l_rects.i_th (i).x)
					a_col_w.extend (l_rects.i_th (i).width)
					i := i + 1
				end
			end
		end

invariant
	rows_not_void: row_store /= Void
	widths_not_void: widths /= Void
	flex_not_void: flex /= Void
	style_not_void: style /= Void
	row_highlight_style_not_void: row_highlight_style /= Void
	column_highlight_style_not_void: column_highlight_style /= Void
	cell_highlight_style_not_void: cell_highlight_style /= Void
	highlight_symbol_not_void: highlight_symbol /= Void

end
