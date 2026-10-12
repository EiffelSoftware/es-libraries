note
	description: "[
		Regression tests for the Milestone E review (2026-09-26). Each test failed on the code
		as first delivered for Milestone E:
		- percentage/ratio rounding handed out cells beyond the rounded exact total
		- over-constrained layouts shrank Min below its minimum before Fixed
		- SpaceAround put the leftover cells at the end
		- large spacing and large ratios overflowed 16/32-bit arithmetic
		- LAYOUT.split returned the cache's own array; in-place constraint edits served stale results
		- postcondition queries accepted misplaced or unordered chunks
		Follow-up review (overlap and border merging):
		- a zero-width chunk under an overlap made the next chunk step back (postcondition violation)
		- merged double/thick borders came out as single-line junctions
		- ASCII text ('-', '|', '+') under a merged border was turned into junctions
		- the overlap postcondition did not bound how much neighbouring chunks overlap
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_MILESTONE_E_REVIEW

inherit
	EQA_TEST_SET

feature -- Sizing

	test_percentage_rounding_bounded_by_exact_total
			-- Only the cells lost to flooring are given back: 33% of 10 is 3, not 4.
		local
			l_chunks: ARRAYED_LIST [RECT]
		do
			l_chunks := solver.split (area (10), <<{CONSTRAINTS}.percentage (33)>>, horizontal)
			assert ("33 percent of 10 is 3", l_chunks.first.width = 3)

			l_chunks := solver.split (area (10), <<{CONSTRAINTS}.percentage (1), {CONSTRAINTS}.percentage (1), {CONSTRAINTS}.percentage (1)>>, horizontal)
			assert ("three times 1 percent of 10 is nothing", across l_chunks as c all c.width = 0 end)

			l_chunks := solver.split (area (100), <<{CONSTRAINTS}.ratio (1, 3), {CONSTRAINTS}.ratio (1, 3), {CONSTRAINTS}.ratio (1, 3)>>, horizontal)
			assert ("thirds of 100 still sum to 100", l_chunks.i_th (1).width = 34 and l_chunks.i_th (2).width = 33 and l_chunks.i_th (3).width = 33)

			l_chunks := solver.split (area (11), <<{CONSTRAINTS}.percentage (50), {CONSTRAINTS}.flex (1)>>, horizontal)
			assert ("half of 11 rounds half up", l_chunks.i_th (1).width = 6 and l_chunks.i_th (2).width = 5)
		end

	test_ratio_does_not_overflow
			-- Large ratio terms are computed in 64 bits.
		local
			l_chunks: ARRAYED_LIST [RECT]
		do
			l_chunks := solver.split (area (1000), <<{CONSTRAINTS}.ratio (3000000000, 4000000000)>>, horizontal)
			assert ("3/4 of 1000", l_chunks.first.width = 750)
		end

	test_overconstrained_shrink_order
			-- Max gives way first, then Percentage/Ratio, then Fixed; Min keeps its minimum.
		local
			l_chunks: ARRAYED_LIST [RECT]
		do
			l_chunks := solver.split (area (30), <<{CONSTRAINTS}.min_size (20), {CONSTRAINTS}.fixed (20)>>, horizontal)
			assert ("min kept, fixed shrunk", l_chunks.i_th (1).width = 20 and l_chunks.i_th (2).width = 10)

			l_chunks := solver.split (area (30), <<{CONSTRAINTS}.max_size (15), {CONSTRAINTS}.fixed (20), {CONSTRAINTS}.min_size (10)>>, horizontal)
			assert ("max gives way first", l_chunks.i_th (1).width = 0 and l_chunks.i_th (2).width = 20 and l_chunks.i_th (3).width = 10)

			l_chunks := solver.split (area (30), <<{CONSTRAINTS}.percentage (50), {CONSTRAINTS}.fixed (20), {CONSTRAINTS}.min_size (10)>>, horizontal)
			assert ("percentage before fixed", l_chunks.i_th (1).width = 0 and l_chunks.i_th (2).width = 20 and l_chunks.i_th (3).width = 10)

			l_chunks := solver.split (area (30), <<{CONSTRAINTS}.min_size (20), {CONSTRAINTS}.min_size (20)>>, horizontal)
			assert ("mins alone shrink proportionally", l_chunks.i_th (1).width = 15 and l_chunks.i_th (2).width = 15)
		end

feature -- Justification and spacing

	test_space_around_is_symmetric
			-- Leftover cells are spread from exact positions: equal space at both edges.
		local
			l_chunks: ARRAYED_LIST [RECT]
		do
			l_chunks := solver.split_with_justification (area (22),
				<<{CONSTRAINTS}.fixed (4), {CONSTRAINTS}.fixed (4), {CONSTRAINTS}.fixed (4)>>, horizontal, 0, {FLEX_JUSTIFY}.space_around)
			assert ("leading 2", l_chunks.i_th (1).x = 2)
			assert ("middle at 9", l_chunks.i_th (2).x = 9)
			assert ("trailing 2", 22 - l_chunks.i_th (3).right = 2)
		end

	test_large_spacing_does_not_overflow
			-- Spacing larger than the area leaves empty chunks inside it; normal spacing still fills.
		local
			l_chunks: ARRAYED_LIST [RECT]
		do
			l_chunks := solver.split_with_spacing (area (100),
				<<{CONSTRAINTS}.flex (1), {CONSTRAINTS}.flex (1), {CONSTRAINTS}.flex (1)>>, horizontal, 32768)
			assert ("all empty", across l_chunks as c all c.width = 0 end)
			assert ("all inside the area", across l_chunks as c all c.x <= 100 end)

			l_chunks := solver.split_with_spacing (area (100),
				<<{CONSTRAINTS}.flex (1), {CONSTRAINTS}.flex (1), {CONSTRAINTS}.flex (1)>>, horizontal, 40)
			assert ("sizes 7 7 6", l_chunks.i_th (1).width = 7 and l_chunks.i_th (2).width = 7 and l_chunks.i_th (3).width = 6)
			assert ("positions 0 47 94", l_chunks.i_th (1).x = 0 and l_chunks.i_th (2).x = 47 and l_chunks.i_th (3).x = 94)
		end

feature -- LAYOUT and cache

	test_layout_split_returns_copies
			-- Modifying a result does not affect the next split of the same layout.
		local
			l_layout: LAYOUT
			l_first: ARRAY [RECT]
		do
			create l_layout.make_horizontal (<<{CONSTRAINTS}.fixed (10), {CONSTRAINTS}.flex (1)>>)
			l_first := l_layout.split (area (50))
			l_first.put (create {RECT}.make (40, 0, 1, 1), 1)
			assert ("cached solution intact", l_layout.split (area (50)) [1].is_equal (create {RECT}.make (0, 0, 10, 1)))
		end

	test_layout_is_immutable
			-- The constraints of a layout cannot be changed behind the cache's back; `with_constraints`
			-- gives a new layout whose values are told apart by the cache.
		local
			l_layout, l_other: LAYOUT
			l_list: ARRAYED_LIST [CONSTRAINT]
		do
			create l_layout.make_horizontal (<<{CONSTRAINTS}.fixed (10), {CONSTRAINTS}.flex (1)>>)
			assert ("first split", l_layout.split (area (60)) [1].width = 10)
			l_list := l_layout.constraints
			l_list.put_i_th ({CONSTRAINTS}.fixed (20), 1)
			assert ("copy changed, layout did not", l_layout.split (area (60)) [1].width = 10)
			l_other := l_layout.with_constraints (l_list)
			assert ("new layout, new solution", l_other.split (area (60)) [1].width = 20)
		end

feature -- Postconditions

	test_postcondition_queries_reject_bad_chunks
			-- The queries behind the postconditions detect overlap, disorder, misplacement and gaps.
		local
			l_rects: ARRAYED_LIST [RECT]
		do
			create l_rects.make (2)
			l_rects.extend (create {RECT}.make (0, 0, 10, 1))
			l_rects.extend (create {RECT}.make (5, 0, 10, 1))
			assert ("overlap detected", not solver.chunks_do_not_overlap (l_rects))
			assert ("disorder detected", not solver.chunks_ordered (horizontal, l_rects))

			create l_rects.make (1)
			l_rects.extend (create {RECT}.make (200, 0, 0, 1))
			assert ("empty chunk outside the area detected", not solver.chunks_positioned_inside (area (100), l_rects))

			create l_rects.make (1)
			l_rects.extend (create {RECT}.make (0, 0, 90, 1))
			assert ("gap at the end detected", not solver.fills_length (area (100), horizontal, l_rects))
			assert ("flex must fill", solver.is_filling (area (100), <<{CONSTRAINTS}.flex (1)>>, horizontal, 0, {FLEX_JUSTIFY}.start_align))
			assert ("fixed alone need not fill", not solver.is_filling (area (100), <<{CONSTRAINTS}.fixed (10)>>, horizontal, 0, {FLEX_JUSTIFY}.start_align))
		end

feature -- Overlap and border merging (follow-up review)

	test_overlap_with_zero_width_chunk
			-- A zero-width chunk under an overlap does not make the next chunk step back.
		local
			l_layout: LAYOUT
			l_chunks: ARRAY [RECT]
		do
			create l_layout.make_horizontal (<<{CONSTRAINTS}.fixed (5), {CONSTRAINTS}.fixed (0), {CONSTRAINTS}.fixed (5)>>)
			l_chunks := l_layout.with_overlap (1).split (area (20))
			assert ("first at 0", l_chunks [1].x = 0 and l_chunks [1].width = 5)
			assert ("empty chunk shares the last cell", l_chunks [2].x = 4 and l_chunks [2].width = 0)
			assert ("third does not step back", l_chunks [3].x = 4 and l_chunks [3].width = 5)
		end

	test_overlap_bound_query
			-- The overlap postcondition rejects neighbours that share more than the overlap.
		local
			l_rects: ARRAYED_LIST [RECT]
		do
			create l_rects.make (2)
			l_rects.extend (create {RECT}.make (0, 0, 10, 1))
			l_rects.extend (create {RECT}.make (5, 0, 10, 1))
			assert ("5 shared cells exceed an overlap of 1", not solver.chunks_overlap_bounded (horizontal, l_rects, 1))
			assert ("5 shared cells fit an overlap of 5", solver.chunks_overlap_bounded (horizontal, l_rects, 5))
			assert ("well-formed check uses the bound", not solver.is_well_formed_with_overlap (area (20), horizontal, l_rects, 1))
		end

	test_merged_borders_keep_line_family
			-- Double and thick seams get double and thick junctions; rounded corners are kept;
			-- borders of different families meet with single-line junctions.
		local
			l_buf: BUFFER
			l_merger: BORDER_COLLISION_SOLVER
		do
			l_buf := overlapping_blocks ({BORDER_TYPE}.double)
			assert ("double top junction", l_buf.cell (0, 5).symbol.code (1) = 0x2566)
			assert ("double seam", l_buf.cell (1, 5).symbol.code (1) = 0x2551)
			assert ("double bottom junction", l_buf.cell (2, 5).symbol.code (1) = 0x2569)

			l_buf := overlapping_blocks ({BORDER_TYPE}.thick)
			assert ("thick top junction", l_buf.cell (0, 5).symbol.code (1) = 0x2533)
			assert ("thick seam", l_buf.cell (1, 5).symbol.code (1) = 0x2503)
			assert ("thick bottom junction", l_buf.cell (2, 5).symbol.code (1) = 0x253B)

			l_buf := overlapping_blocks ({BORDER_TYPE}.rounded)
			assert ("rounded blocks join with a single junction", l_buf.cell (0, 5).symbol.code (1) = 0x252C)
			assert ("outer rounded corner kept", l_buf.cell (0, 0).symbol.code (1) = 0x256D)

			create l_merger
			assert ("double meets single: single junction",
				l_merger.merge_symbols ((0x2550).to_character_32, (0x2502).to_character_32).code = 0x253C)
		end

	test_merged_border_ignores_text
			-- Text under a merged border is replaced, never turned into junctions.
		local
			l_buf: BUFFER
			l_block: TUI_BLOCK
		do
			create l_buf.make (8, 3)
			l_buf.put_string (1, 0, "a-b|c+d-", create {STYLE})
			create l_block.make
			l_block.with_border_merged (True).render (area_of (8, 3), l_buf)
			assert ("left border over text", l_buf.cell (1, 0).symbol.code (1) = 0x2502)
			assert ("right border over a hyphen", l_buf.cell (1, 7).symbol.code (1) = 0x2502)
			assert ("text inside kept", l_buf.cell (1, 3).symbol.same_string ({STRING_32} "|"))
		end

	test_render_merged_restores_setting
			-- `render_merged` merges for one call and leaves the block's setting as it was.
		local
			l_buf: BUFFER
			l_block: TUI_BLOCK
		do
			create l_buf.make (8, 3)
			create l_block.make
			l_block.render_merged (area_of (8, 3), l_buf)
			assert ("setting restored", not l_block.is_border_merged)
		end

feature {NONE} -- Helpers

	solver: LAYOUT_SOLVER
		once
			create Result
		end

	horizontal: SPLIT_DIRECTION
		do
			Result := {SPLIT_DIRECTION}.horizontal
		end

	area_of (a_width, a_height: NATURAL_16): RECT
			-- Area of `a_width` x `a_height` at the origin
		do
			create Result.make (0, 0, a_width, a_height)
		end

	overlapping_blocks (a_type: NATURAL_8): BUFFER
			-- Two blocks of border type `a_type` in an 11x3 buffer, overlapping by one column
			-- (column 5), the second drawn with border merging
		local
			l_layout: LAYOUT
			l_chunks: ARRAY [RECT]
			l_b1, l_b2: TUI_BLOCK
		do
			create Result.make (11, 3)
			create l_layout.make_horizontal (<<{CONSTRAINTS}.flex (1), {CONSTRAINTS}.flex (1)>>)
			l_chunks := l_layout.with_overlap (1).split (area_of (11, 3))
			create l_b1.make
			l_b1.set_border_type (a_type)
			l_b1.render (l_chunks [1], Result)
			create l_b2.make
			l_b2.set_border_type (a_type)
			l_b2.with_border_merged (True).render (l_chunks [2], Result)
		end

	area (a_width: NATURAL_16): RECT
			-- One-row area of `a_width` columns at the origin
		do
			create Result.make (0, 0, a_width, 1)
		end

end
