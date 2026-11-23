note
	description: "[
		Diff engine calculating dirty screen regions between previous and current frames.
		Groups adjacent dirty cells into SPANs and merges small gaps (<= 4 cells)
		to minimize cursor positioning overhead. Reuses diff span storage to eliminate allocations.

		Pool memory follows what frames actually change: a new span starts with room for
		`Initial_span_capacity' cells and grows as needed, pooled spans that a diff does not use
		are emptied (so they keep no cells of old buffers alive), and `discard_pool' drops the
		whole pool, which TERMINAL does when it replaces its buffers on a resize.

		Diff options (Ratatui `CellDiffOption`, see CELL_DIFF_OPTION) of the current frame's cells:
		  * `Skip`: the cell is never written, and it ends the current span, so that no merged
		    gap writes over it (Ratatui's diff is per cell and merges no gaps).
		  * `Always_update`: the cell is always dirty.
		  * `Forced_width (n)`: the cell is dirty like any other; the next n - 1 cells of its row
		    are covered: they are not compared and never put in a span (a span ends before
		    them and a new one starts after them). The cover stops at the end of the row.
		A cell whose option differs from the previous frame's (Ratatui compares the option as
		part of the cell) is dirty. So is a cell that a forced width of the previous frame
		covered and the current frame does not: what the terminal shows there came from the
		covering cell, not from the previous buffer (an EiffelTUI addition).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	DIFF_ENGINE

feature -- Operations

	diff (a_prev, a_curr: BUFFER): ARRAYED_LIST [DIFF_SPAN]
			-- Compute minimal list of spans required to update `a_prev` to `a_curr`.
			-- Cells are compared by what they display (`same_content`), so styles that differ only
			-- in patch modifiers do not cause output. Diff options are applied as described in
			-- the class note.
			-- Note: the DIFF_SPAN objects come from an internal pool and are reused by the next
			-- call to `diff`; consume the result before calling `diff` again.
		local
			r, c, k: INTEGER
			l_span: detachable DIFF_SPAN
			l_is_dirty: BOOLEAN
			l_prev_cell: detachable TERMINAL_CELL
			l_curr_cell: TERMINAL_CELL
			l_min_h, l_min_w: INTEGER
			l_cover_end, l_prev_cover_end: INTEGER
		do
			create Result.make (32)
			pool_index := 0
			l_min_h := a_prev.height.min (a_curr.height)
			l_min_w := a_prev.width.min (a_curr.width)

			from
				r := 0
			until
				r >= a_curr.height
			loop
				l_span := Void
				-- Last column covered by a forced width in the current / previous frame
				l_cover_end := -1
				l_prev_cover_end := -1
				from
					c := 0
				until
					c >= a_curr.width
				loop
					l_curr_cell := a_curr.cell (r, c)
					if r < l_min_h and c < l_min_w then
						l_prev_cell := a_prev.cell (r, c)
					else
						-- Newly added area due to buffer growth
						l_prev_cell := Void
					end
					if c <= l_cover_end or l_curr_cell.diff_option = {CELL_DIFF_OPTION}.Skip then
						-- Not written: end the span, so that no merged gap reaches this cell
						if attached l_span as span then
							Result.extend (span)
							l_span := Void
						end
						l_is_dirty := False
					elseif l_curr_cell.diff_option = {CELL_DIFF_OPTION}.Always_update then
						l_is_dirty := True
					elseif attached l_prev_cell as l_prev then
						l_is_dirty := c <= l_prev_cover_end or else not l_curr_cell.same_diff_option (l_prev)
							or else not l_curr_cell.same_content (l_prev)
					else
						-- Newly added area is unconditionally dirty
						l_is_dirty := True
					end
					-- Record the columns that forced widths cover: the previous frame's (also
					-- under cells this frame covers or skips), and this frame's
					if attached l_prev_cell as l_prev and then l_prev.diff_option = {CELL_DIFF_OPTION}.Forced_width then
						l_prev_cover_end := l_prev_cover_end.max (c + l_prev.forced_width.to_integer_32 - 1)
					end
					if c > l_cover_end and l_curr_cell.diff_option = {CELL_DIFF_OPTION}.Forced_width then
						l_cover_end := c + l_curr_cell.forced_width.to_integer_32 - 1
					end

					if l_is_dirty then
						if attached l_span as span then
							if c = span.end_col + 1 then
								-- Direct continuation of current span
								span.extend (l_curr_cell)
							elseif c <= span.end_col + 1 + Max_merge_gap then
								-- Merge small gap: redraw intermediate cells to avoid cursor jump
								from
									k := span.end_col + 1
								until
									k >= c
								loop
									span.extend (a_curr.cell (r, k))
									k := k + 1
								end
								span.extend (l_curr_cell)
							else
								-- Gap is too large: commit current span and start a new one
								Result.extend (span)
								l_span := acquire_span (r, c)
								l_span.extend (l_curr_cell)
							end
						else
							l_span := acquire_span (r, c)
							l_span.extend (l_curr_cell)
						end
					end
					c := c + 1
				end

				if attached l_span as span then
					Result.extend (span)
				end
				r := r + 1
			end
			release_unused_spans
		ensure
			result_attached: Result /= Void
			spans_from_pool: Result.count = pool_in_use
		end

feature -- Basic operations

	discard_pool
			-- Drop the span pool, and the cells its spans refer to. Spans returned by the last
			-- `diff` stay valid; the next `diff` builds a new pool.
		do
			span_pool := Void
			pool_index := 0
			last_pool_index := 0
		ensure
			empty: pool_size = 0 and pool_in_use = 0
		end

feature -- Measurement

	pool_size: INTEGER
			-- Number of spans in the pool (used or not)
		do
			if attached span_pool as p then
				Result := p.count
			end
		end

	pool_in_use: INTEGER
			-- Number of pooled spans returned by the last `diff`
		do
			Result := pool_index
		end

	pool_cell_capacity: INTEGER
			-- Total cell capacity of the pooled spans
		do
			if attached span_pool as p then
				across p as s loop
					Result := Result + s.cells.capacity
				end
			end
		end

	pool_cell_count: INTEGER
			-- Total number of cells the pooled spans refer to
		do
			if attached span_pool as p then
				across p as s loop
					Result := Result + s.count
				end
			end
		end

feature -- Constants

	Max_merge_gap: INTEGER = 4
			-- Maximum cell gap distance to merge into a single span

	Initial_span_capacity: INTEGER = 8
			-- Cells a new span has room for before it grows

feature {NONE} -- Pool

	span_pool: detachable ARRAYED_LIST [DIFF_SPAN]
			-- Reusable pool of DIFF_SPAN objects to avoid allocations during diff

	pool_index: INTEGER
			-- Number of pooled spans handed out by the current (or last) `diff`

	last_pool_index: INTEGER
			-- `pool_index` at the end of the previous `diff`: the spans after the current
			-- `pool_index` and up to this one still hold cells

	release_unused_spans
			-- Empty the pooled spans the previous `diff` used and this one did not, so that
			-- they keep no cells alive (the collector follows a list's items only up to its count).
		local
			i: INTEGER
		do
			if attached span_pool as p then
				from
					i := pool_index + 1
				until
					i > last_pool_index.min (p.count)
				loop
					p.i_th (i).cells.wipe_out
					i := i + 1
				end
			end
			last_pool_index := pool_index
		ensure
			recorded: last_pool_index = pool_index
		end

	acquire_span (a_row, a_col: INTEGER): DIFF_SPAN
			-- Get a reusable DIFF_SPAN from pool or create a new one.
		local
			l_pool: ARRAYED_LIST [DIFF_SPAN]
		do
			if attached span_pool as p then
				l_pool := p
			else
				create l_pool.make (64)
				span_pool := l_pool
			end

			pool_index := pool_index + 1
			if pool_index <= l_pool.count then
				Result := l_pool.i_th (pool_index)
				Result.reset (a_row, a_col)
			else
				create Result.make (a_row, a_col, Initial_span_capacity)
				l_pool.extend (Result)
			end
		ensure
			span_attached: Result /= Void
			row_set: Result.row = a_row
			col_set: Result.start_col = a_col
		end

end
