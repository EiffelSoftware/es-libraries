note
	description: "[
		Memory held by DIFF_ENGINE's span pool (review finding M3):
		- a sparse frame does not give every span room for the rest of its row
		- pooled spans a diff does not use keep no cells
		- a span still grows to a whole row
		- TERMINAL drops the pool when it replaces its buffers
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_DIFF_POOL

inherit
	EQA_TEST_SET

feature -- Tests

	test_sparse_frame_pool_is_small
			-- One changed cell per row of a 400x120 buffer: 120 one-cell spans with the initial
			-- capacity each (the review measured about 240k slots before).
		local
			l_engine: DIFF_ENGINE
			l_spans: ARRAYED_LIST [DIFF_SPAN]
		do
			create l_engine
			l_spans := l_engine.diff (create {BUFFER}.make (400, 120), sparse_buffer (400, 120, 120))
			assert ("120 spans", l_spans.count = 120 and l_engine.pool_in_use = 120)
			assert ("one cell each", across l_spans as s all s.count = 1 end)
			assert ("small capacity", l_engine.pool_cell_capacity = 120 * {DIFF_ENGINE}.Initial_span_capacity)
		end

	test_unused_spans_emptied
			-- After a busy frame, a quiet one uses one span: the other 119 keep no cells.
		local
			l_engine: DIFF_ENGINE
			l_spans: ARRAYED_LIST [DIFF_SPAN]
			l_prev: BUFFER
		do
			create l_engine
			create l_prev.make (400, 120)
			l_spans := l_engine.diff (l_prev, sparse_buffer (400, 120, 120))
			assert ("busy frame", l_engine.pool_cell_count = 120)
			l_spans := l_engine.diff (l_prev, sparse_buffer (400, 120, 1))
			assert ("one span", l_spans.count = 1 and l_engine.pool_in_use = 1)
			assert ("pool kept for reuse", l_engine.pool_size = 120)
			assert ("only the used span holds a cell", l_engine.pool_cell_count = 1)
			l_spans := l_engine.diff (l_prev, l_prev)
			assert ("no change, no cells", l_spans.is_empty and l_engine.pool_cell_count = 0)
		end

	test_span_grows_to_a_row
			-- A whole dirty row is still one span with every cell, in order.
		local
			l_engine: DIFF_ENGINE
			l_curr: BUFFER
			l_spans: ARRAYED_LIST [DIFF_SPAN]
			c: INTEGER
		do
			create l_engine
			create l_curr.make (400, 2)
			from
				c := 0
			until
				c >= 400
			loop
				l_curr.put_char (1, c, ('a').plus (c.integer_remainder (26)), create {STYLE})
				c := c + 1
			end
			l_spans := l_engine.diff (create {BUFFER}.make (400, 2), l_curr)
			assert ("one span", l_spans.count = 1)
			assert ("whole row", l_spans.first.row = 1 and l_spans.first.start_col = 0 and l_spans.first.count = 400)
			assert ("cells in order", l_spans.first.cells [1] = l_curr.cell (1, 0) and l_spans.first.cells [400] = l_curr.cell (1, 399))
		end

	test_discard_pool
			-- `discard_pool` empties the pool; the next diff builds a new one.
		local
			l_engine: DIFF_ENGINE
			l_spans: ARRAYED_LIST [DIFF_SPAN]
		do
			create l_engine
			l_spans := l_engine.diff (create {BUFFER}.make (20, 10), sparse_buffer (20, 10, 10))
			l_engine.discard_pool
			assert ("empty", l_engine.pool_size = 0 and l_engine.pool_in_use = 0 and l_engine.pool_cell_capacity = 0)
			assert ("returned spans still valid", l_spans.count = 10 and l_spans.first.count = 1)
			l_spans := l_engine.diff (create {BUFFER}.make (20, 10), sparse_buffer (20, 10, 3))
			assert ("new pool", l_spans.count = 3 and l_engine.pool_size = 3)
		end

	test_terminal_resize_discards_pool
			-- A backend resize replaces the buffers and drops the pool sized by the old frames.
		local
			l_vt: VIRTUAL_TERMINAL
			l_term: INSPECTABLE_TERMINAL
		do
			create l_vt.make (80, 24)
			create l_term.make (l_vt)
			l_term.draw (agent draw_rows (?, 24))
			assert ("24 spans pooled", l_term.diff_engine.pool_size = 24)
			l_vt.set_size (40, 10)
			l_term.draw (agent draw_rows (?, 1))
			assert ("pool rebuilt for the new size", l_term.diff_engine.pool_size = 1)
		end

feature {NONE} -- Helpers

	sparse_buffer (a_width, a_height, a_rows: INTEGER): BUFFER
			-- `a_width` x `a_height` buffer with an 'x' in column 0 of its first `a_rows` rows
		local
			r: INTEGER
		do
			create Result.make (a_width, a_height)
			from
				r := 0
			until
				r >= a_rows
			loop
				Result.put_char (r, 0, 'x', create {STYLE})
				r := r + 1
			end
		end

	draw_rows (a_frame: FRAME; a_rows: INTEGER)
			-- Write "row" on the first `a_rows` rows of `a_frame`.
		local
			r: INTEGER
		do
			from
				r := 0
			until
				r >= a_rows
			loop
				a_frame.buffer.put_string (r, 0, "row", create {STYLE})
				r := r + 1
			end
		end

end
