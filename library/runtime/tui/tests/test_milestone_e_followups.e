note
	description: "[
		Unit tests for the Milestone E follow-ups:
		- SPACING value object (Space and Overlap variants, signed conversions)
		- Overlapping spacing (Ratatui Spacing::Overlap) in LAYOUT and LAYOUT_SOLVER
		- Border collision merging for overlapping adjacent blocks (BORDER_COLLISION_SOLVER & TUI_BLOCK)
		- LAYOUT.split_with_spacers returning chunks and n + 1 spacers
		- LAYOUT_CACHE O(1) LRU eviction
		- TUI_TABLE integration with LAYOUT (columns, spacing, flex)
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_MILESTONE_E_FOLLOWUPS

inherit
	EQA_TEST_SET

feature -- Test Routines

	test_spacing_value_object
			-- Test SPACING constructors, properties, and signed effective spacing.
		local
			l_s1, l_s2, l_s3, l_s4: SPACING
		do
			create l_s1.default_create
			assert ("default spacing is space", l_s1.is_space)
			assert ("default spacing value is 0", l_s1.value = 0)
			assert ("default effective spacing is 0", l_s1.effective_spacing = 0)

			l_s2 := {SPACING}.space (2)
			assert ("s2 is space", l_s2.is_space)
			assert ("s2 value is 2", l_s2.value = 2)
			assert ("s2 effective is 2", l_s2.effective_spacing = 2)

			l_s3 := {SPACING}.overlap (1)
			assert ("s3 is overlap", l_s3.is_overlap)
			assert ("s3 value is 1", l_s3.value = 1)
			assert ("s3 effective is -1", l_s3.effective_spacing = -1)

			create l_s4.make_from_integer (-3)
			assert ("s4 from -3 is overlap", l_s4.is_overlap)
			assert ("s4 value is 3", l_s4.value = 3)
			assert ("s4 effective is -3", l_s4.effective_spacing = -3)
			assert ("s4 equality with overlap 3", l_s4.is_equal ({SPACING}.overlap (3)))
		end

	test_layout_overlap_spacing_ratatui_cases
			-- Test Ratatui parity test cases for Spacing::Overlap(-1).
		local
			l_area: RECT
			l_layout: LAYOUT
			l_chunks: ARRAY [RECT]
		do
			create l_area.make (0, 0, 100, 1)

			-- Case 1: Length(20), Length(20), Length(20) with Flex::Start and Overlap(1)
			-- Expected: [(0, 20), (19, 20), (38, 20)]
			create l_layout.make_horizontal (<<
				{CONSTRAINTS}.fixed (20),
				{CONSTRAINTS}.fixed (20),
				{CONSTRAINTS}.fixed (20)
			>>)
			l_layout := l_layout.with_overlap (1).with_flex ({FLEX_JUSTIFY}.start_align)
			assert ("layout has overlap", l_layout.has_overlap)
			assert ("layout spacing is -1", l_layout.spacing = -1)

			l_chunks := l_layout.split (l_area)
			assert ("3 chunks", l_chunks.count = 3)
			assert ("chunk 1 x=0, w=20", l_chunks [1].x = 0 and l_chunks [1].width = 20)
			assert ("chunk 2 x=19, w=20", l_chunks [2].x = 19 and l_chunks [2].width = 20)
			assert ("chunk 3 x=38, w=20", l_chunks [3].x = 38 and l_chunks [3].width = 20)

			-- Case 2: Flex::Center with Overlap(1)
			-- Expected: [(21, 20), (40, 20), (59, 20)]
			l_layout := l_layout.with_flex ({FLEX_JUSTIFY}.center_align)
			l_chunks := l_layout.split (l_area)
			assert ("center chunk 1 x=21, w=20", l_chunks [1].x = 21 and l_chunks [1].width = 20)
			assert ("center chunk 2 x=40, w=20", l_chunks [2].x = 40 and l_chunks [2].width = 20)
			assert ("center chunk 3 x=59, w=20", l_chunks [3].x = 59 and l_chunks [3].width = 20)

			-- Case 3: Flex::End with Overlap(1)
			-- Expected: [(42, 20), (61, 20), (80, 20)]
			l_layout := l_layout.with_flex ({FLEX_JUSTIFY}.end_align)
			l_chunks := l_layout.split (l_area)
			assert ("end chunk 1 x=42, w=20", l_chunks [1].x = 42 and l_chunks [1].width = 20)
			assert ("end chunk 2 x=61, w=20", l_chunks [2].x = 61 and l_chunks [2].width = 20)
			assert ("end chunk 3 x=80, w=20", l_chunks [3].x = 80 and l_chunks [3].width = 20)

			-- Case 4: Flex::Legacy with Overlap(1)
			-- Expected: [(0, 20), (19, 20), (38, 62)]
			l_layout := l_layout.with_flex ({FLEX_JUSTIFY}.legacy)
			l_chunks := l_layout.split (l_area)
			assert ("legacy chunk 1 x=0, w=20", l_chunks [1].x = 0 and l_chunks [1].width = 20)
			assert ("legacy chunk 2 x=19, w=20", l_chunks [2].x = 19 and l_chunks [2].width = 20)
			assert ("legacy chunk 3 x=38, w=62", l_chunks [3].x = 38 and l_chunks [3].width = 62)

			-- Case 5: Flex(1), Fixed(10), Flex(1) with Overlap(1)
			-- Total len = 100, spacing total = -2 => avail = 102. Fixed(10) leaves 92 => 46 each.
			-- Expected: [(0, 46), (45, 10), (54, 46)]
			create l_layout.make_horizontal (<<
				{CONSTRAINTS}.flex (1),
				{CONSTRAINTS}.fixed (10),
				{CONSTRAINTS}.flex (1)
			>>)
			l_layout := l_layout.with_overlap (1)
			l_chunks := l_layout.split (l_area)
			assert ("fill overlap chunk 1 x=0, w=46", l_chunks [1].x = 0 and l_chunks [1].width = 46)
			assert ("fill overlap chunk 2 x=45, w=10", l_chunks [2].x = 45 and l_chunks [2].width = 10)
			assert ("fill overlap chunk 3 x=54, w=46", l_chunks [3].x = 54 and l_chunks [3].width = 46)
			assert ("fill overlap covers length", l_chunks [1].x = 0 and l_chunks [3].right = 100)
		end

	test_adjacent_blocks_overlap_border_merging
			-- Test that adjacent blocks with 1-cell overlap share a border merged by BORDER_COLLISION_SOLVER.
		local
			l_buf: BUFFER
			l_layout: LAYOUT
			l_chunks: ARRAY [RECT]
			l_b1, l_b2: TUI_BLOCK
		do
			create l_buf.make (21, 6)

			-- Split width 21 into two equal flex blocks with 1-cell overlap:
			-- 21 - (-1) = 22 available -> 11 and 11.
			-- Block 1: x = 0, width = 11 (occupies cols 0..10, right border at col 10)
			-- Block 2: x = 10, width = 11 (occupies cols 10..20, left border at col 10)
			create l_layout.make_horizontal (<<{CONSTRAINTS}.flex (1), {CONSTRAINTS}.flex (1)>>)
			l_layout := l_layout.with_overlap (1)
			l_chunks := l_layout.split (create {RECT}.make (0, 0, 21, 6))

			assert ("block 1 right is 11", l_chunks [1].right = 11)
			assert ("block 2 starts at 10", l_chunks [2].x = 10)
			assert ("blocks share column 10", l_chunks [1].right - 1 = l_chunks [2].x)

			-- Render block 1 into buffer
			create l_b1.make
			l_b1.set_border_type ({BORDER_TYPE}.plain)
			l_b1.render (l_chunks [1], l_buf)

			-- Render block 2 with border merging enabled
			create l_b2.make
			l_b2.set_border_type ({BORDER_TYPE}.plain)
			l_b2.with_border_merged (True).render (l_chunks [2], l_buf)

			-- Shared column is 10:
			-- Row 0: Block 1's '┐' (9488) merged with Block 2's '┌' (9484) -> '┬' (9516)
			assert ("top junction is T-top", l_buf.cell (0, 10).symbol.code (1) = 9516)

			-- Rows 1..4: '│' merged with '│' -> '│' (9474)
			assert ("vertical seam is line", l_buf.cell (2, 10).symbol.code (1) = 9474)

			-- Row 5: Block 1's '┘' (9496) merged with Block 2's '└' (9492) -> '┴' (9524)
			assert ("bottom junction is T-bottom", l_buf.cell (5, 10).symbol.code (1) = 9524)
		end

	test_layout_split_with_spacers
			-- Test split_with_spacers returning chunks and n + 1 spacers matching Ratatui.
		local
			l_layout: LAYOUT
			l_area: RECT
			l_res: TUPLE [areas: ARRAY [RECT]; spacers: ARRAY [RECT]]
		do
			-- Vertical layout without spacing: 2 segments, 3 spacers
			create l_area.make (2, 2, 10, 10)
			create l_layout.make_vertical (<<{CONSTRAINTS}.fixed (5), {CONSTRAINTS}.flex (1)>>)
			l_res := l_layout.split_with_spacers (l_area)

			assert ("2 areas", l_res.areas.count = 2)
			assert ("3 spacers", l_res.spacers.count = 3)
			assert ("area 1: (2, 2, 10, 5)", l_res.areas [1].is_equal (create {RECT}.make (2, 2, 10, 5)))
			assert ("area 2: (2, 7, 10, 5)", l_res.areas [2].is_equal (create {RECT}.make (2, 7, 10, 5)))

			assert ("spacer 1: (2, 2, 10, 0)", l_res.spacers [1].is_equal (create {RECT}.make (2, 2, 10, 0)))
			assert ("spacer 2: (2, 7, 10, 0)", l_res.spacers [2].is_equal (create {RECT}.make (2, 7, 10, 0)))
			assert ("spacer 3: (2, 12, 10, 0)", l_res.spacers [3].is_equal (create {RECT}.make (2, 12, 10, 0)))

			-- Horizontal layout with spacing 1
			create l_area.make (0, 0, 10, 2)
			create l_layout.make_horizontal (<<{CONSTRAINTS}.ratio (1, 3), {CONSTRAINTS}.ratio (2, 3)>>)
			l_layout := l_layout.with_spacing (1)
			l_res := l_layout.split_with_spacers (l_area)

			assert ("area 1: (0, 0, 3, 2)", l_res.areas [1].is_equal (create {RECT}.make (0, 0, 3, 2)))
			assert ("area 2: (4, 0, 6, 2)", l_res.areas [2].is_equal (create {RECT}.make (4, 0, 6, 2)))
			assert ("spacer 1: (0, 0, 0, 2)", l_res.spacers [1].is_equal (create {RECT}.make (0, 0, 0, 2)))
			assert ("spacer 2: (3, 0, 1, 2)", l_res.spacers [2].is_equal (create {RECT}.make (3, 0, 1, 2)))
			assert ("spacer 3: (10, 0, 0, 2)", l_res.spacers [3].is_equal (create {RECT}.make (10, 0, 0, 2)))

			-- Empty layout: 0 areas, 1 spacer covering the whole area
			create l_area.make (0, 0, 50, 20)
			create l_layout.default_create
			l_res := l_layout.split_with_spacers (l_area)
			assert ("0 areas for empty layout", l_res.areas.is_empty)
			assert ("1 spacer for empty layout", l_res.spacers.count = 1)
			assert ("spacer covers area", l_res.spacers [1].is_equal (l_area))
		end

	test_layout_cache_lru_eviction
			-- Test that LAYOUT_CACHE evicts the least recently used entry when full.
		local
			l_cache: LAYOUT_CACHE
			l_l1, l_l2, l_l3, l_l4: LAYOUT
			l_area: RECT
			l_res: ARRAY [RECT]
		do
			create l_cache.make (3)
			assert ("capacity 3", l_cache.capacity = 3)
			assert ("initially empty", l_cache.count = 0)

			create l_area.make (0, 0, 100, 50)
			create l_l1.make_vertical (<<{CONSTRAINTS}.fixed (10)>>)
			create l_l2.make_vertical (<<{CONSTRAINTS}.fixed (20)>>)
			create l_l3.make_vertical (<<{CONSTRAINTS}.fixed (30)>>)
			create l_l4.make_vertical (<<{CONSTRAINTS}.fixed (40)>>)

			create l_res.make_filled (create {RECT}.default_create, 1, 1)

			-- Fill cache to capacity: L1, L2, L3
			l_cache.put (l_res, l_area, l_l1)
			l_cache.put (l_res, l_area, l_l2)
			l_cache.put (l_res, l_area, l_l3)
			assert ("cache count 3", l_cache.count = 3)

			-- Access L1 (promotes L1 to MRU head; L2 becomes LRU tail)
			assert ("L1 hit", l_cache.get (l_area, l_l1) /= Void)

			-- Insert L4: should evict L2 (the LRU entry)
			l_cache.put (l_res, l_area, l_l4)
			assert ("count stays at capacity 3", l_cache.count = 3)

			-- Check that L2 was evicted, while L1, L3, and L4 remain
			assert ("L2 evicted", not l_cache.has (l_area, l_l2))
			assert ("L1 still present", l_cache.has (l_area, l_l1))
			assert ("L3 still present", l_cache.has (l_area, l_l3))
			assert ("L4 present", l_cache.has (l_area, l_l4))
		end

	test_tui_table_layout_integration
			-- Test that TUI_TABLE uses LAYOUT for column spacing and flex justification.
		local
			l_table: TUI_TABLE
			l_header: TABLE_ROW
			l_row: TABLE_ROW
			l_buf: BUFFER
			l_area: RECT
		do
			create l_header.make_raw (<<"A", "B">>)
			create l_row.make_raw (<<"1", "2">>)
			create l_table.default_create
			l_table.set_header (l_header)
			l_table.append_row (l_row)
			l_table.set_widths (<<{CONSTRAINTS}.fixed (4), {CONSTRAINTS}.fixed (4)>>)
			l_table.set_column_spacing (2)
			l_table.set_flex ({FLEX_JUSTIFY}.end_align)

			-- Width 20: 2 cols of 4 + 2 spacing = 10 needed.
			-- With end_align flex, extra 10 cells are placed before column 1.
			-- Col 1 starts at x = 10, width = 4
			-- Col 2 starts at x = 10 + 4 + 2 = 16, width = 4
			create l_buf.make (20, 4)
			create l_area.make (0, 0, 20, 4)
			l_table.render (l_area, l_buf)

			-- Header row 0: "A" at col 10, "B" at col 16
			assert ("header A at col 10", l_buf.cell (0, 10).symbol.same_string_general ("A"))
			assert ("header B at col 16", l_buf.cell (0, 16).symbol.same_string_general ("B"))

			-- Row 1: "1" at col 10, "2" at col 16
			assert ("row 1 at col 10", l_buf.cell (1, 10).symbol.same_string_general ("1"))
			assert ("row 2 at col 16", l_buf.cell (1, 16).symbol.same_string_general ("2"))
		end


feature -- Allocation-free cache hits

	test_split_list_is_independent_of_cache
			-- `split_list` builds a fresh list straight from the cached solution: changing it does not
			-- change the next split.
		local
			l_layout: LAYOUT
			l_list: ARRAYED_LIST [RECT]
			l_area: RECT
		do
			create l_area.make (0, 0, 40, 1)
			create l_layout.make_horizontal (<<{CONSTRAINTS}.fixed (10), {CONSTRAINTS}.flex (1)>>)
			l_list := l_layout.split_list (l_area)
			l_list.put_i_th (create {RECT}.make (30, 0, 1, 1), 1)
			l_list.extend (create {RECT}.make (0, 0, 1, 1))
			l_list := l_layout.split_list (l_area)
			assert ("two chunks", l_list.count = 2)
			assert ("first chunk intact", l_list.first.is_equal (create {RECT}.make (0, 0, 10, 1)))
		end

	test_cache_hit_reuses_stored_solution
			-- A hit returns copies of the stored arrays; the stored arrays themselves are neither
			-- replaced nor copied, and `split` keeps the spacers for `split_with_spacers`.
		local
			l_layout: LAYOUT
			l_area: RECT
			l_first, l_second: detachable LAYOUT_CACHE_ENTRY
			l_chunks: ARRAY [RECT]
		do
			create l_area.make (0, 0, 40, 3)
			create l_layout.make_vertical (<<{CONSTRAINTS}.fixed (1), {CONSTRAINTS}.flex (1)>>)
			l_chunks := l_layout.split (l_area)
			l_first := {LAYOUT}.shared_cache.entry (l_area, l_layout)
			l_chunks := l_layout.split (l_area)
			l_second := {LAYOUT}.shared_cache.entry (l_area, l_layout)
			assert ("entry cached", attached l_first)
			assert ("same entry on hit", l_first = l_second)
			if attached l_first as e then
				assert ("result is a copy", l_chunks /= e.areas)
				assert ("spacers kept by split", attached e.spacers as sp and then sp.count = 3)
			end
			assert ("split_with_spacers served from the same entry", l_layout.split_with_spacers (l_area).spacers.count = 3)
		end

end
