note
	description: "[
		Comprehensive unit test suite for Milestone E: Layout Parity.
		Validates:
		- LAYOUT value object (direction, constraints, margin, spacing, flex) and fluent builders.
		- LAYOUT.split returning ARRAY [RECT].
		- Documented deterministic algorithm with fixed rules:
		  * Min can grow.
		  * Max can shrink.
		  * Percentage and ratio remainders are distributed.
		  * Over-constrained layouts shrink proportionally.
		  * Flex remainder is split by weight.
		- FLEX_JUSTIFY as proper type with SpaceEvenly and Legacy.
		- Exact distribution of justify remainder across gaps.
		- Postconditions: chunks do not overlap, stay inside area, cover the length.
		- Layout cache keyed by (area, layout).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_MILESTONE_E

inherit
	EQA_TEST_SET

feature -- Test Routines

	test_layout_value_object_and_builders
			-- Test LAYOUT value object initialization, fluent builders, and equality.
		local
			l_layout, l_modified: LAYOUT
			l_c1, l_c2: CONSTRAINT
			l_margin: MARGIN
		do
			l_c1 := {CONSTRAINTS}.fixed (10)
			l_c2 := {CONSTRAINTS}.flex (1)

			-- 1. Default creation
			create l_layout.default_create
			assert ("default direction vertical", l_layout.direction.is_vertical)
			assert ("default constraints empty", l_layout.constraints.is_empty)
			assert ("default margin zero", l_layout.margin.horizontal = 0 and l_layout.margin.vertical = 0)
			assert ("default spacing zero", l_layout.spacing = 0)
			assert ("default flex start", l_layout.flex.is_start)

			-- 2. Fluent builders create independent copies
			create l_margin.make (2, 4)
			l_modified := l_layout.with_direction ({SPLIT_DIRECTION}.horizontal)
				.with_constraints (<<l_c1, l_c2>>)
				.with_margin (l_margin)
				.with_spacing (3)
				.with_flex ({FLEX_JUSTIFY}.space_between)

			assert ("original layout unchanged", l_layout.direction.is_vertical)
			assert ("original constraints still empty", l_layout.constraints.is_empty)

			assert ("modified direction horizontal", l_modified.direction.is_horizontal)
			assert ("modified constraints count 2", l_modified.constraints.count = 2)
			assert ("modified margin horizontal 2", l_modified.margin.horizontal = 2)
			assert ("modified margin vertical 4", l_modified.margin.vertical = 4)
			assert ("modified spacing 3", l_modified.spacing = 3)
			assert ("modified flex space_between", l_modified.flex.is_space_between)

			-- 3. Equality
			assert ("same value layouts equal", l_modified.is_equal (l_modified.twin))
			assert ("different layouts not equal", not l_modified.is_equal (l_layout))
		end

	test_layout_split_array
			-- Test LAYOUT.split returning ARRAY [RECT] with 1-based indexing.
		local
			l_layout: LAYOUT
			l_area: RECT
			l_chunks: ARRAY [RECT]
		do
			create l_area.make (0, 0, 80, 24)
			create l_layout.make_vertical (<<{CONSTRAINTS}.fixed (4), {CONSTRAINTS}.flex (1)>>)

			l_chunks := l_layout.split (l_area)

			assert ("array lower bound is 1", l_chunks.lower = 1)
			assert ("array upper bound is 2", l_chunks.upper = 2)
			assert ("array count is 2", l_chunks.count = 2)

			assert ("chunk 1 y is 0", l_chunks [1].y = 0)
			assert ("chunk 1 height is 4", l_chunks [1].height = 4)
			assert ("chunk 1 width is 80", l_chunks [1].width = 80)

			assert ("chunk 2 y is 4", l_chunks [2].y = 4)
			assert ("chunk 2 height is 20", l_chunks [2].height = 20)
			assert ("chunk 2 width is 80", l_chunks [2].width = 80)
		end

	test_deterministic_min_can_grow
			-- Test deterministic rule: Min can grow when there is excess space and no Flex.
		local
			l_solver: LAYOUT_SOLVER
			l_area: RECT
			l_chunks: ARRAYED_LIST [RECT]
		do
			create l_solver
			-- 1. Single Min with Fixed: width 100, Min(20) + Fixed(30) = 50 base. Excess 50 goes to Min.
			create l_area.make (0, 0, 100, 10)
			l_chunks := l_solver.split (
				l_area,
				<<{CONSTRAINTS}.min_size (20), {CONSTRAINTS}.fixed (30)>>,
				{SPLIT_DIRECTION}.horizontal
			)
			assert ("two chunks", l_chunks.count = 2)
			assert ("min chunk grew to 70", l_chunks.i_th (1).width = 70)
			assert ("fixed chunk stayed 30", l_chunks.i_th (2).width = 30)
			assert ("total width is 100", l_chunks.i_th (1).width + l_chunks.i_th (2).width = 100)

			-- 2. Two Min constraints: width 60, Min(10) + Min(20) = 30 base. Excess 30 split 1:2 -> 10:20 -> 20 and 40.
			create l_area.make (0, 0, 60, 10)
			l_chunks := l_solver.split (
				l_area,
				<<{CONSTRAINTS}.min_size (10), {CONSTRAINTS}.min_size (20)>>,
				{SPLIT_DIRECTION}.horizontal
			)
			assert ("min 1 grew to 20", l_chunks.i_th (1).width = 20)
			assert ("min 2 grew to 40", l_chunks.i_th (2).width = 40)
			assert ("total width is 60", l_chunks.i_th (1).width + l_chunks.i_th (2).width = 60)
		end

	test_deterministic_max_can_shrink
			-- Test deterministic rule: Max can shrink when space is needed before hard constraints.
		local
			l_solver: LAYOUT_SOLVER
			l_area: RECT
			l_chunks: ARRAYED_LIST [RECT]
		do
			create l_solver
			-- Width 40, Fixed(30) + Max(20) = 50 base. Excess 10 is absorbed by shrinking Max from 20 to 10.
			create l_area.make (0, 0, 40, 10)
			l_chunks := l_solver.split (
				l_area,
				<<{CONSTRAINTS}.fixed (30), {CONSTRAINTS}.max_size (20)>>,
				{SPLIT_DIRECTION}.horizontal
			)
			assert ("two chunks", l_chunks.count = 2)
			assert ("fixed chunk stayed 30", l_chunks.i_th (1).width = 30)
			assert ("max chunk shrunk to 10", l_chunks.i_th (2).width = 10)
			assert ("total width is 40", l_chunks.i_th (1).width + l_chunks.i_th (2).width = 40)
		end

	test_deterministic_pct_and_ratio_remainders
			-- Test deterministic rule: Percentage and ratio remainders are distributed by largest fractional part.
		local
			l_solver: LAYOUT_SOLVER
			l_area: RECT
			l_chunks: ARRAYED_LIST [RECT]
		do
			create l_solver

			-- 1. Three 1/3 ratios on width 100: base 33 each = 99. Remainder 1/3 cell goes to first chunk -> 34, 33, 33.
			create l_area.make (0, 0, 100, 10)
			l_chunks := l_solver.split (
				l_area,
				<<{CONSTRAINTS}.ratio (1, 3), {CONSTRAINTS}.ratio (1, 3), {CONSTRAINTS}.ratio (1, 3)>>,
				{SPLIT_DIRECTION}.horizontal
			)
			assert ("three chunks", l_chunks.count = 3)
			assert ("first chunk gets remainder cell", l_chunks.i_th (1).width = 34)
			assert ("second chunk is 33", l_chunks.i_th (2).width = 33)
			assert ("third chunk is 33", l_chunks.i_th (3).width = 33)
			assert ("total width is 100", l_chunks.i_th (1).width + l_chunks.i_th (2).width + l_chunks.i_th (3).width = 100)

			-- 2. Two 50% on width 99: 49.5 each -> base 49 each = 98. Remainder 1 cell goes to first chunk -> 50, 49.
			create l_area.make (0, 0, 99, 10)
			l_chunks := l_solver.split (
				l_area,
				<<{CONSTRAINTS}.percentage (50), {CONSTRAINTS}.percentage (50)>>,
				{SPLIT_DIRECTION}.horizontal
			)
			assert ("two chunks", l_chunks.count = 2)
			assert ("first chunk is 50", l_chunks.i_th (1).width = 50)
			assert ("second chunk is 49", l_chunks.i_th (2).width = 49)
			assert ("total width is 99", l_chunks.i_th (1).width + l_chunks.i_th (2).width = 99)

			-- 3. Three 33% on width 10: 3.3 each -> base 3 each = 9. Remainder 1 cell goes to first -> 4, 3, 3.
			create l_area.make (0, 0, 10, 5)
			l_chunks := l_solver.split (
				l_area,
				<<{CONSTRAINTS}.percentage (33), {CONSTRAINTS}.percentage (33), {CONSTRAINTS}.percentage (33)>>,
				{SPLIT_DIRECTION}.horizontal
			)
			assert ("three pct chunks", l_chunks.count = 3)
			assert ("pct 1 is 4", l_chunks.i_th (1).width = 4)
			assert ("pct 2 is 3", l_chunks.i_th (2).width = 3)
			assert ("pct 3 is 3", l_chunks.i_th (3).width = 3)
			assert ("total width is 10", l_chunks.i_th (1).width + l_chunks.i_th (2).width + l_chunks.i_th (3).width = 10)
		end

	test_deterministic_overconstrained_proportional_shrink
			-- Test deterministic rule: Over-constrained layouts shrink proportionally.
		local
			l_solver: LAYOUT_SOLVER
			l_area: RECT
			l_chunks: ARRAYED_LIST [RECT]
		do
			create l_solver
			-- Available width 30, requested Fixed(20) + Fixed(40) = 60.
			-- Proportional share: 20 * 30 / 60 = 10, 40 * 30 / 60 = 20.
			create l_area.make (0, 0, 30, 5)
			l_chunks := l_solver.split (
				l_area,
				<<{CONSTRAINTS}.fixed (20), {CONSTRAINTS}.fixed (40)>>,
				{SPLIT_DIRECTION}.horizontal
			)
			assert ("two chunks", l_chunks.count = 2)
			assert ("chunk 1 shrunk proportionally to 10", l_chunks.i_th (1).width = 10)
			assert ("chunk 2 shrunk proportionally to 20", l_chunks.i_th (2).width = 20)
			assert ("total width is 30", l_chunks.i_th (1).width + l_chunks.i_th (2).width = 30)

			-- Three equal Fixed(10) in available width 20: 20 // 3 = 6 each, remainder 2 -> 7, 7, 6.
			create l_area.make (0, 0, 20, 5)
			l_chunks := l_solver.split (
				l_area,
				<<{CONSTRAINTS}.fixed (10), {CONSTRAINTS}.fixed (10), {CONSTRAINTS}.fixed (10)>>,
				{SPLIT_DIRECTION}.horizontal
			)
			assert ("three chunks", l_chunks.count = 3)
			assert ("chunk 1 is 7", l_chunks.i_th (1).width = 7)
			assert ("chunk 2 is 7", l_chunks.i_th (2).width = 7)
			assert ("chunk 3 is 6", l_chunks.i_th (3).width = 6)
			assert ("total width is 20", l_chunks.i_th (1).width + l_chunks.i_th (2).width + l_chunks.i_th (3).width = 20)
		end

	test_deterministic_flex_split_by_weight
			-- Test deterministic rule: Flex remainder is split by weight.
		local
			l_solver: LAYOUT_SOLVER
			l_area: RECT
			l_chunks: ARRAYED_LIST [RECT]
		do
			create l_solver
			-- Width 100, Flex(1) and Flex(3) -> weights sum to 4. 25 and 75.
			create l_area.make (0, 0, 100, 10)
			l_chunks := l_solver.split (
				l_area,
				<<{CONSTRAINTS}.flex (1), {CONSTRAINTS}.flex (3)>>,
				{SPLIT_DIRECTION}.horizontal
			)
			assert ("two flex chunks", l_chunks.count = 2)
			assert ("flex 1 is 25", l_chunks.i_th (1).width = 25)
			assert ("flex 3 is 75", l_chunks.i_th (2).width = 75)
			assert ("total width is 100", l_chunks.i_th (1).width + l_chunks.i_th (2).width = 100)

			-- Width 100, Flex(1) and Flex(2) -> weights sum to 3. 33 and 66, remainder 1 goes to weight 2 -> 33 and 67.
			l_chunks := l_solver.split (
				l_area,
				<<{CONSTRAINTS}.flex (1), {CONSTRAINTS}.flex (2)>>,
				{SPLIT_DIRECTION}.horizontal
			)
			assert ("flex 1 is 33", l_chunks.i_th (1).width = 33)
			assert ("flex 2 gets remainder (67)", l_chunks.i_th (2).width = 67)
			assert ("total width is 100", l_chunks.i_th (1).width + l_chunks.i_th (2).width = 100)
		end

	test_flex_justify_proper_type_and_constants
			-- Test FLEX_JUSTIFY proper type, all strategy options, and inspection.
		local
			f_start, f_end, f_center, f_between, f_around, f_evenly, f_legacy: FLEX_JUSTIFY
		do
			f_start := {FLEX_JUSTIFY}.start
			f_end := {FLEX_JUSTIFY}.end_align
			f_center := {FLEX_JUSTIFY}.center
			f_between := {FLEX_JUSTIFY}.space_between
			f_around := {FLEX_JUSTIFY}.space_around
			f_evenly := {FLEX_JUSTIFY}.space_evenly
			f_legacy := {FLEX_JUSTIFY}.legacy

			assert ("start status", f_start.is_start and not f_start.is_end)
			assert ("end status", f_end.is_end and not f_end.is_start)
			assert ("center status", f_center.is_center and not f_center.is_legacy)
			assert ("space_between status", f_between.is_space_between)
			assert ("space_around status", f_around.is_space_around)
			assert ("space_evenly status", f_evenly.is_space_evenly)
			assert ("legacy status", f_legacy.is_legacy)

			assert ("start out", f_start.out.is_equal ("Start"))
			assert ("space_evenly out", f_evenly.out.is_equal ("SpaceEvenly"))
			assert ("legacy out", f_legacy.out.is_equal ("Legacy"))
		end

	test_flex_justify_space_evenly
			-- Test SpaceEvenly justification distributes space equally before, between, and after chunks.
		local
			l_solver: LAYOUT_SOLVER
			l_area: RECT
			l_chunks: ARRAYED_LIST [RECT]
		do
			create l_solver
			-- Width 20, 3 items of fixed 4 => 12 allocated. Extra = 8 cells.
			-- 4 gaps (before, 2 middle, after): 8 // 4 = 2 cells per gap.
			create l_area.make (0, 0, 20, 5)
			l_chunks := l_solver.split_with_justification (
				l_area,
				<<{CONSTRAINTS}.fixed (4), {CONSTRAINTS}.fixed (4), {CONSTRAINTS}.fixed (4)>>,
				{SPLIT_DIRECTION}.horizontal,
				0,
				{FLEX_JUSTIFY}.space_evenly
			)
			assert ("three chunks", l_chunks.count = 3)
			-- Chunk 1: starts at x=2, width=4 (ends at 6)
			assert ("chunk 1 x is 2", l_chunks.i_th (1).x = 2)
			assert ("chunk 1 width is 4", l_chunks.i_th (1).width = 4)
			-- Chunk 2: starts at x=6+2=8, width=4 (ends at 12)
			assert ("chunk 2 x is 8", l_chunks.i_th (2).x = 8)
			assert ("chunk 2 width is 4", l_chunks.i_th (2).width = 4)
			-- Chunk 3: starts at x=12+2=14, width=4 (ends at 18)
			assert ("chunk 3 x is 14", l_chunks.i_th (3).x = 14)
			assert ("chunk 3 width is 4", l_chunks.i_th (3).width = 4)
			-- After chunk 3: trailing gap is 20 - 18 = 2
		end

	test_flex_justify_remainder_distribution
			-- Test exact distribution of justify remainder across gaps without dropping cells.
		local
			l_solver: LAYOUT_SOLVER
			l_area: RECT
			l_chunks: ARRAYED_LIST [RECT]
		do
			create l_solver
			-- Width 21, 3 items of fixed 4 => 12 allocated. Extra = 9 cells.
			-- With SpaceBetween: 2 gaps. 9 // 2 = 4, remainder = 1.
			-- First gap gets 4 + 1 = 5, second gap gets 4.
			create l_area.make (0, 0, 21, 5)
			l_chunks := l_solver.split_with_justification (
				l_area,
				<<{CONSTRAINTS}.fixed (4), {CONSTRAINTS}.fixed (4), {CONSTRAINTS}.fixed (4)>>,
				{SPLIT_DIRECTION}.horizontal,
				0,
				{FLEX_JUSTIFY}.space_between
			)
			assert ("three chunks", l_chunks.count = 3)
			assert ("chunk 1 at 0", l_chunks.i_th (1).x = 0)
			-- Chunk 2 starts at 0 + 4 + 5 = 9
			assert ("chunk 2 at 9", l_chunks.i_th (2).x = 9)
			-- Chunk 3 starts at 9 + 4 + 4 = 17
			assert ("chunk 3 at 17", l_chunks.i_th (3).x = 17)
			-- Last chunk reaches 17 + 4 = 21 (exact reach, no dropped cell!)
			assert ("last chunk reaches right edge", l_chunks.i_th (3).right = 21)
		end

	test_flex_justify_legacy
			-- Test Legacy flex justification stretches the last element to fill available space.
		local
			l_solver: LAYOUT_SOLVER
			l_area: RECT
			l_chunks: ARRAYED_LIST [RECT]
		do
			create l_solver
			-- Width 50, Fixed(10) + Fixed(10) with Legacy flex => last element gets remaining 30 -> 40.
			create l_area.make (0, 0, 50, 5)
			l_chunks := l_solver.split_with_justification (
				l_area,
				<<{CONSTRAINTS}.fixed (10), {CONSTRAINTS}.fixed (10)>>,
				{SPLIT_DIRECTION}.horizontal,
				0,
				{FLEX_JUSTIFY}.legacy
			)
			assert ("two chunks", l_chunks.count = 2)
			assert ("chunk 1 stayed 10", l_chunks.i_th (1).width = 10)
			assert ("chunk 2 stretched to 40", l_chunks.i_th (2).width = 40)
			assert ("total width is 50", l_chunks.i_th (1).width + l_chunks.i_th (2).width = 50)
		end

	test_layout_cache
			-- Test layout caching keyed by (area, layout).
		local
			l_layout: LAYOUT
			l_area: RECT
			l_first, l_second: ARRAY [RECT]
			l_cache: LAYOUT_CACHE
		do
			create l_area.make (0, 0, 100, 50)
			create l_layout.make_vertical (<<{CONSTRAINTS}.fixed (10), {CONSTRAINTS}.flex (1)>>)

			l_cache := {LAYOUT}.shared_cache
			l_cache.clear
			assert ("cache initially empty", l_cache.count = 0)

			-- First call computes and caches
			l_first := l_layout.split (l_area)
			assert ("cache has 1 entry", l_cache.count = 1)

			-- Second call is served from the cache (no new entry) as a fresh copy of the solution
			l_second := l_layout.split (l_area)
			assert ("served from cache", l_cache.count = 1)
			assert ("fresh array per call", l_first /= l_second)
			assert ("same solution", l_first [1].is_equal (l_second [1]) and l_first [2].is_equal (l_second [2]))

			-- Disabling cache clears and skips caching
			l_cache.disable
			assert ("disabled cache is empty", l_cache.count = 0)
			l_first := l_layout.split (l_area)
			assert ("cache stayed empty while disabled", l_cache.count = 0)

			-- Re-enable cache
			l_cache.enable
			assert ("cache re-enabled", l_cache.is_enabled)
		end

	test_layout_postconditions
			-- Test that LAYOUT postconditions hold: chunks do not overlap, stay inside area, and cover length.
		local
			l_layout: LAYOUT
			l_area: RECT
			l_chunks: ARRAY [RECT]
		do
			create l_area.make (10, 5, 80, 24)
			create l_layout.make_horizontal (<<
				{CONSTRAINTS}.fixed (20),
				{CONSTRAINTS}.percentage (25),
				{CONSTRAINTS}.ratio (1, 4),
				{CONSTRAINTS}.flex (1)
			>>)
			l_layout := l_layout.with_spacing (2).with_flex ({FLEX_JUSTIFY}.space_between)

			l_chunks := l_layout.split (l_area)

			assert ("4 chunks produced", l_chunks.count = 4)
			assert ("chunks do not overlap verified", l_layout.chunks_do_not_overlap (l_chunks))
			assert ("covers length verified", l_layout.covers_length (l_area, l_chunks))
			across
				l_chunks as r
			loop
				assert ("chunk contained inside area", l_area.contains_rect (r))
			end
		end

end
