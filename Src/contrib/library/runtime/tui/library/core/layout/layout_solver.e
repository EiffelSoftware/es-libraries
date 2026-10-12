note
	description: "[
		Pure geometric layout solver splitting a parent RECT into child RECTs
		based on a sequence of sizing constraints (Fixed, Percentage, Ratio, Flex, Min, Max).

		Deterministic algorithm (all arithmetic in 32/64 bits, results clamped to the area):
		1. Spacing: `(n - 1) * spacing` cells are reserved between chunks; the rest is available.
		   A negative spacing is an overlap (Ratatui `Spacing::Overlap`): neighbouring chunks share
		   that many cells (e.g. a common border), so the available length grows by `(n - 1) * overlap`.
		2. Base sizes: Fixed = value, Min = minimum, Max = maximum, Percentage/Ratio = floor of the
		   exact share of the available length, Flex = 0.
		3. Rounding: the Percentage/Ratio cells lost to flooring are given back by largest remainder,
		   but only as many as `round (sum of exact shares) - sum of floors` (so 33% of 10 is 3,
		   and three 1/3 ratios of 100 are 34 + 33 + 33).
		4. Too little space: shrink Max first, then Percentage/Ratio, then Fixed, and Min last,
		   each group proportionally (largest remainder), a group only when the previous ones are
		   exhausted. Min therefore keeps its minimum whenever the other constraints can give way.
		5. Spare space: Flex constraints share it by weight; without Flex, Min constraints grow in
		   proportion to their minimum; otherwise Legacy gives it to the last chunk.
		6. Remaining space is placed by the flex justification. The offset before chunk i is
		   rounded from its exact position, so SpaceBetween/SpaceAround/SpaceEvenly are symmetric
		   and never drop cells.
		Guarantees (postconditions): chunks lie inside the area (empty ones included), span the area
		on the cross axis, and exactly fill the length when the layout can absorb all space
		(`is_filling`). With spacing >= 0 they are ordered and do not overlap; with an overlap they
		never start before the previous chunk and neighbours share at most the overlap.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	LAYOUT_SOLVER

feature -- Operations

	split (a_area: RECT; a_constraints: ITERABLE [CONSTRAINT]; a_direction: SPLIT_DIRECTION): ARRAYED_LIST [RECT]
			-- Split `a_area` along `a_direction` according to `a_constraints`.
		do
			Result := split_with_justification (a_area, a_constraints, a_direction, 0, {FLEX_JUSTIFY}.start_align)
		ensure
			well_formed: is_well_formed (a_area, a_direction, Result)
			fills_length: is_filling (a_area, a_constraints, a_direction, 0, {FLEX_JUSTIFY}.start_align) implies fills_length (a_area, a_direction, Result)
		end

	split_with_spacing (a_area: RECT; a_constraints: ITERABLE [CONSTRAINT]; a_direction: SPLIT_DIRECTION; a_spacing: INTEGER): ARRAYED_LIST [RECT]
			-- Split `a_area` along `a_direction` according to `a_constraints`, leaving `a_spacing` gap cells (or overlap if negative) between chunks.
		do
			Result := split_with_justification (a_area, a_constraints, a_direction, a_spacing, {FLEX_JUSTIFY}.start_align)
		ensure
			well_formed: a_spacing >= 0 implies is_well_formed (a_area, a_direction, Result)
			well_formed_overlap: a_spacing < 0 implies is_well_formed_with_overlap (a_area, a_direction, Result, - a_spacing)
			fills_length: is_filling (a_area, a_constraints, a_direction, a_spacing, {FLEX_JUSTIFY}.start_align) implies fills_length (a_area, a_direction, Result)
		end

	split_with_justification (
		a_area: RECT;
		a_constraints: ITERABLE [CONSTRAINT];
		a_direction: SPLIT_DIRECTION;
		a_spacing: INTEGER;
		a_justify: FLEX_JUSTIFY
	): ARRAYED_LIST [RECT]
			-- Split `a_area` along `a_direction` according to `a_constraints`, `a_spacing` gaps,
			-- and justified according to `a_justify` strategy.
		do
			Result := split_with_spacers (a_area, a_constraints, a_direction, a_spacing, a_justify).areas
		ensure
			count: Result.count = count_of (a_constraints)
			well_formed: a_spacing >= 0 implies is_well_formed (a_area, a_direction, Result)
			well_formed_overlap: a_spacing < 0 implies is_well_formed_with_overlap (a_area, a_direction, Result, - a_spacing)
			fills_length: is_filling (a_area, a_constraints, a_direction, a_spacing, a_justify) implies fills_length (a_area, a_direction, Result)
		end

	split_with_spacers (
		a_area: RECT;
		a_constraints: ITERABLE [CONSTRAINT];
		a_direction: SPLIT_DIRECTION;
		a_spacing: INTEGER;
		a_justify: FLEX_JUSTIFY
	): TUPLE [areas: ARRAYED_LIST [RECT]; spacers: ARRAYED_LIST [RECT]]
			-- Split `a_area` along `a_direction` according to `a_constraints`, `a_spacing` gaps/overlaps,
			-- and justified according to `a_justify` strategy, returning both chunk areas and spacers.
		local
			l_list: ARRAYED_LIST [CONSTRAINT]
			l_alloc: ARRAYED_LIST [NATURAL_32]
			l_total_len, l_avail, l_extra: NATURAL_32
			l_spacing_total_64, l_sum_64, l_pos_64, l_chunk_start_64: INTEGER_64
			l_start, l_end, l_len, l_offset: NATURAL_32
			l_rects, l_spacers: ARRAYED_LIST [RECT]
			l_first_chunk, l_prev_chunk, l_curr_chunk, l_last_chunk: RECT
			l_first_start, l_prev_end, l_curr_start, l_last_end, l_spacer_len: NATURAL_32
			l_prev_start_64: INTEGER_64
			i, n: INTEGER
		do
			create l_list.make (8)
			across a_constraints as c loop
				l_list.extend (c)
			end
			n := l_list.count
			create l_rects.make (n)
			create l_spacers.make (n + 1)

			if a_direction.is_horizontal then
				l_total_len := a_area.width.to_natural_32
				l_start := a_area.x.to_natural_32
			else
				l_total_len := a_area.height.to_natural_32
				l_start := a_area.y.to_natural_32
			end
			l_end := l_start + l_total_len

			if n > 0 then
				l_spacing_total_64 := (n - 1).to_integer_64 * a_spacing.to_integer_64
				if l_total_len.to_integer_64 > l_spacing_total_64 then
					l_avail := (l_total_len.to_integer_64 - l_spacing_total_64).to_natural_32
				else
					l_avail := 0
				end
				l_alloc := allocations (l_list, l_avail, a_justify)
				l_sum_64 := sum_of (l_alloc).to_integer_64
				if l_total_len.to_integer_64 > l_sum_64 + l_spacing_total_64 then
					l_extra := (l_total_len.to_integer_64 - l_sum_64 - l_spacing_total_64).to_natural_32
				else
					l_extra := 0
				end

				-- Position the chunks; clamp to the area end
				l_pos_64 := l_start.to_integer_64
				l_prev_start_64 := l_start.to_integer_64
				from
					i := 1
				until
					i > n
				loop
					l_offset := justify_offset (a_justify, i, n, l_extra)
					l_chunk_start_64 := l_pos_64 + l_offset.to_integer_64
					-- With an overlap, a chunk after an empty or short one would step back:
					-- never start before the previous chunk
					if l_chunk_start_64 < l_prev_start_64 then
						l_chunk_start_64 := l_prev_start_64
					end
					if l_chunk_start_64 > l_end.to_integer_64 then
						l_chunk_start_64 := l_end.to_integer_64
					end

					l_len := l_alloc.i_th (i)
					if l_chunk_start_64 + l_len.to_integer_64 > l_end.to_integer_64 then
						l_len := (l_end.to_integer_64 - l_chunk_start_64).to_natural_32
					end
					l_rects.extend (chunk (a_area, a_direction, l_chunk_start_64.to_natural_32, l_len))
					l_prev_start_64 := l_chunk_start_64

					l_pos_64 := l_pos_64 + l_len.to_integer_64 + a_spacing.to_integer_64
					if l_pos_64 < l_start.to_integer_64 then
						l_pos_64 := l_start.to_integer_64
					end
					if l_pos_64 > l_end.to_integer_64 then
						l_pos_64 := l_end.to_integer_64
					end
					i := i + 1
				end

				-- Calculate spacers: exactly n + 1 spacers
				-- Spacer 1: before first chunk
				l_first_chunk := l_rects.first
				if a_direction.is_horizontal then
					l_first_start := l_first_chunk.x.to_natural_32
				else
					l_first_start := l_first_chunk.y.to_natural_32
				end
				if l_first_start > l_start then
					l_spacer_len := l_first_start - l_start
				else
					l_spacer_len := 0
				end
				l_spacers.extend (chunk (a_area, a_direction, l_start, l_spacer_len))

				-- Middle spacers: between chunk i-1 and chunk i
				from
					i := 2
				until
					i > n
				loop
					l_prev_chunk := l_rects.i_th (i - 1)
					l_curr_chunk := l_rects.i_th (i)
					if a_direction.is_horizontal then
						l_prev_end := l_prev_chunk.right.to_natural_32
						l_curr_start := l_curr_chunk.x.to_natural_32
					else
						l_prev_end := l_prev_chunk.bottom.to_natural_32
						l_curr_start := l_curr_chunk.y.to_natural_32
					end
					if l_curr_start > l_prev_end then
						l_spacer_len := l_curr_start - l_prev_end
					else
						l_spacer_len := 0
					end
					l_spacers.extend (chunk (a_area, a_direction, l_prev_end, l_spacer_len))
					i := i + 1
				end

				-- Last spacer: after chunk n
				l_last_chunk := l_rects.last
				if a_direction.is_horizontal then
					l_last_end := l_last_chunk.right.to_natural_32
				else
					l_last_end := l_last_chunk.bottom.to_natural_32
				end
				if l_end > l_last_end then
					l_spacer_len := l_end - l_last_end
				else
					l_spacer_len := 0
				end
				l_spacers.extend (chunk (a_area, a_direction, l_last_end, l_spacer_len))
			else
				-- n = 0: exactly 1 spacer covering the inner area
				l_spacers.extend (chunk (a_area, a_direction, l_start, l_total_len))
			end

			Result := [l_rects, l_spacers]
		ensure
			areas_count: Result.areas.count = count_of (a_constraints)
			spacers_count: Result.spacers.count = (if count_of (a_constraints) = 0 then 1 else count_of (a_constraints) + 1 end)
			well_formed: a_spacing >= 0 implies is_well_formed (a_area, a_direction, Result.areas)
			well_formed_overlap: a_spacing < 0 implies is_well_formed_with_overlap (a_area, a_direction, Result.areas, - a_spacing)
			fills_length: is_filling (a_area, a_constraints, a_direction, a_spacing, a_justify) implies fills_length (a_area, a_direction, Result.areas)
		end

	split_with_spacing_model (
		a_area: RECT;
		a_constraints: ITERABLE [CONSTRAINT];
		a_direction: SPLIT_DIRECTION;
		a_spacing: SPACING;
		a_justify: FLEX_JUSTIFY
	): TUPLE [areas: ARRAYED_LIST [RECT]; spacers: ARRAYED_LIST [RECT]]
			-- Split `a_area` using `a_spacing` model (Space or Overlap).
		require
			spacing_attached: a_spacing /= Void
		do
			Result := split_with_spacers (a_area, a_constraints, a_direction, a_spacing.effective_spacing, a_justify)
		ensure
			areas_count: Result.areas.count = count_of (a_constraints)
			spacers_count: Result.spacers.count = (if count_of (a_constraints) = 0 then 1 else count_of (a_constraints) + 1 end)
		end

	split_with_justification_code (
		a_area: RECT;
		a_constraints: ITERABLE [CONSTRAINT];
		a_direction: SPLIT_DIRECTION;
		a_spacing: INTEGER;
		a_justify: INTEGER
	): ARRAYED_LIST [RECT]
			-- Backwards-compatible overload taking raw integer justification code.
		require
			valid_justify: {FLEX_JUSTIFY}.is_valid (a_justify)
		do
			Result := split_with_justification (a_area, a_constraints, a_direction, a_spacing, create {FLEX_JUSTIFY}.make_from_integer (a_justify))
		ensure
			well_formed: a_spacing >= 0 implies is_well_formed (a_area, a_direction, Result)
			well_formed_overlap: a_spacing < 0 implies is_well_formed_with_overlap (a_area, a_direction, Result, - a_spacing)
		end

	split_with_margin (a_area: RECT; a_constraints: ITERABLE [CONSTRAINT]; a_direction: SPLIT_DIRECTION; a_margin: MARGIN): ARRAYED_LIST [RECT]
			-- Split `a_area` deflated by `a_margin`.
		do
			Result := split (a_area.inner (a_margin.horizontal, a_margin.vertical), a_constraints, a_direction)
		ensure
			well_formed: is_well_formed (a_area.inner (a_margin.horizontal, a_margin.vertical), a_direction, Result)
		end

feature -- Postcondition Queries

	is_well_formed (a_area: RECT; a_direction: SPLIT_DIRECTION; a_rects: LIST [RECT]): BOOLEAN
			-- Are `a_rects` inside `a_area`, spanning it on the cross axis, ordered and non-overlapping?
		do
			Result := chunks_positioned_inside (a_area, a_rects) and
				spans_cross_axis (a_area, a_direction, a_rects) and
				chunks_ordered (a_direction, a_rects) and
				chunks_do_not_overlap (a_rects)
		end

	chunks_do_not_overlap (a_rects: LIST [RECT]): BOOLEAN
			-- Do no two non-empty rectangles in `a_rects` intersect?
		local
			i, j: INTEGER
		do
			Result := True
			from
				i := 1
			until
				i > a_rects.count or not Result
			loop
				from
					j := i + 1
				until
					j > a_rects.count or not Result
				loop
					if a_rects.i_th (i).intersects (a_rects.i_th (j)) then
						Result := False
					end
					j := j + 1
				end
				i := i + 1
			end
		end

	chunks_positioned_inside (a_area: RECT; a_rects: LIST [RECT]): BOOLEAN
			-- Is every rectangle, empty ones included, positioned within `a_area`?
		do
			Result := across a_rects as r all
				r.x >= a_area.x and r.right <= a_area.right and r.y >= a_area.y and r.bottom <= a_area.bottom
			end
		end

	spans_cross_axis (a_area: RECT; a_direction: SPLIT_DIRECTION; a_rects: LIST [RECT]): BOOLEAN
			-- Does every rectangle cover `a_area` entirely across the split direction?
		do
			if a_direction.is_horizontal then
				Result := across a_rects as r all r.y = a_area.y and r.height = a_area.height end
			else
				Result := across a_rects as r all r.x = a_area.x and r.width = a_area.width end
			end
		end

	chunks_ordered (a_direction: SPLIT_DIRECTION; a_rects: LIST [RECT]): BOOLEAN
			-- Does each rectangle start at or after the end of the previous one?
		local
			i: INTEGER
		do
			Result := True
			from
				i := 2
			until
				i > a_rects.count or not Result
			loop
				if a_direction.is_horizontal then
					Result := a_rects.i_th (i).x >= a_rects.i_th (i - 1).right
				else
					Result := a_rects.i_th (i).y >= a_rects.i_th (i - 1).bottom
				end
				i := i + 1
			end
		end

	is_well_formed_with_overlap (a_area: RECT; a_direction: SPLIT_DIRECTION; a_rects: LIST [RECT]; a_overlap: INTEGER): BOOLEAN
			-- Are `a_rects` inside `a_area`, spanning it on the cross axis, monotonic in start position,
			-- with each chunk sharing at most `a_overlap` cells with the previous one?
		require
			non_negative_overlap: a_overlap >= 0
		do
			Result := chunks_positioned_inside (a_area, a_rects) and
				spans_cross_axis (a_area, a_direction, a_rects) and
				chunks_monotonic (a_direction, a_rects) and
				chunks_overlap_bounded (a_direction, a_rects, a_overlap)
		end

	chunks_overlap_bounded (a_direction: SPLIT_DIRECTION; a_rects: LIST [RECT]; a_overlap: INTEGER): BOOLEAN
			-- Does each rectangle start no more than `a_overlap` cells before the end of the previous
			-- non-empty one (or at the previous start, when the previous one is shorter than that)?
		local
			i: INTEGER
			l_start, l_prev_start, l_prev_end: INTEGER
		do
			Result := True
			from
				i := 2
			until
				i > a_rects.count or not Result
			loop
				if a_direction.is_horizontal then
					l_start := a_rects.i_th (i).x.to_integer_32
					l_prev_start := a_rects.i_th (i - 1).x.to_integer_32
					l_prev_end := a_rects.i_th (i - 1).right.to_integer_32
				else
					l_start := a_rects.i_th (i).y.to_integer_32
					l_prev_start := a_rects.i_th (i - 1).y.to_integer_32
					l_prev_end := a_rects.i_th (i - 1).bottom.to_integer_32
				end
				Result := l_start >= (l_prev_end - a_overlap).max (l_prev_start)
				i := i + 1
			end
		end

	chunks_monotonic (a_direction: SPLIT_DIRECTION; a_rects: LIST [RECT]): BOOLEAN
			-- Does each rectangle start at or after the start position of the previous one?
		local
			i: INTEGER
		do
			Result := True
			from
				i := 2
			until
				i > a_rects.count or not Result
			loop
				if a_direction.is_horizontal then
					Result := a_rects.i_th (i).x >= a_rects.i_th (i - 1).x
				else
					Result := a_rects.i_th (i).y >= a_rects.i_th (i - 1).y
				end
				i := i + 1
			end
		end

	fills_length (a_area: RECT; a_direction: SPLIT_DIRECTION; a_rects: LIST [RECT]): BOOLEAN
			-- Does the first rectangle start at the start of `a_area` and the last one end at its end?
		do
			if a_rects.is_empty then
				Result := True
			elseif a_direction.is_horizontal then
				Result := a_rects.first.x = a_area.x and a_rects.last.right = a_area.right
			else
				Result := a_rects.first.y = a_area.y and a_rects.last.bottom = a_area.bottom
			end
		end

	is_filling (a_area: RECT; a_constraints: ITERABLE [CONSTRAINT]; a_direction: SPLIT_DIRECTION; a_spacing: INTEGER; a_justify: FLEX_JUSTIFY): BOOLEAN
			-- Must the chunks and gaps exactly fill the length of `a_area`?
			-- True when some constraint can absorb spare space (Flex, Min, or Legacy's last chunk)
			-- and the gaps leave room for content.
		local
			l_len: INTEGER_64
			l_spacing_total: INTEGER_64
			n: INTEGER
			l_absorbs: BOOLEAN
		do
			n := count_of (a_constraints)
			across a_constraints as c loop
				if c.is_flex or c.is_min then
					l_absorbs := True
				end
			end
			if a_direction.is_horizontal then
				l_len := a_area.width.to_integer_64
			else
				l_len := a_area.height.to_integer_64
			end
			l_spacing_total := (n - 1).to_integer_64 * a_spacing.to_integer_64
			Result := n > 0 and (l_absorbs or a_justify.is_legacy) and (l_len > l_spacing_total)
		end

	count_of (a_constraints: ITERABLE [CONSTRAINT]): INTEGER
			-- Number of constraints in `a_constraints`
		do
			across a_constraints as c loop
				Result := Result + 1
			end
		end

feature {NONE} -- Sizing

	allocations (a_list: ARRAYED_LIST [CONSTRAINT]; a_avail: NATURAL_32; a_justify: FLEX_JUSTIFY): ARRAYED_LIST [NATURAL_32]
			-- Size of each chunk for `a_avail` cells (steps 2 to 5 of the algorithm).
		local
			l_rem_num, l_rem_den: ARRAYED_LIST [NATURAL_64]
			l_fraction_sum: REAL_64
			l_sum, l_extra, l_rounding, l_weight_sum, l_min_sum: NATURAL_32
			l_has_min: BOOLEAN
			i: INTEGER
			l_c: CONSTRAINT
			l_num, l_den: NATURAL_64
		do
			create Result.make_filled (a_list.count)
			create l_rem_num.make_filled (a_list.count)
			create l_rem_den.make_filled (a_list.count)
			if a_avail > 0 then
				-- Step 2: base sizes
				from
					i := 1
				until
					i > a_list.count
				loop
					l_c := a_list.i_th (i)
					l_den := 0
					if attached {CONSTRAINT_FIXED} l_c as l_fixed then
						Result.put_i_th (l_fixed.value.to_natural_32, i)
					elseif attached {CONSTRAINT_MIN} l_c as l_min then
						Result.put_i_th (l_min.min_value.to_natural_32, i)
						l_min_sum := l_min_sum + l_min.min_value.to_natural_32
						l_has_min := True
					elseif attached {CONSTRAINT_MAX} l_c as l_max then
						Result.put_i_th (l_max.max_value.to_natural_32, i)
					elseif attached {CONSTRAINT_PERCENTAGE} l_c as l_pct then
						l_num := a_avail.to_natural_64 * l_pct.percent_value.to_natural_64
						l_den := 100
					elseif attached {CONSTRAINT_RATIO} l_c as l_ratio then
						l_num := a_avail.to_natural_64 * l_ratio.numerator.to_natural_64
						l_den := l_ratio.denominator.to_natural_64
					elseif attached {CONSTRAINT_FLEX} l_c as l_flex then
						l_weight_sum := l_weight_sum + l_flex.weight.to_natural_32
					end
					if l_den > 0 then
						Result.put_i_th ((l_num // l_den).min (a_avail.to_natural_64).to_natural_32, i)
						l_rem_num.put_i_th (l_num \\ l_den, i)
						l_rem_den.put_i_th (l_den, i)
						l_fraction_sum := l_fraction_sum + (l_num \\ l_den).to_real_64 / l_den.to_real_64
					end
					i := i + 1
				end

				-- Step 3: give back the cells lost to flooring, as many as the rounded exact total
				l_sum := sum_of (Result)
				l_rounding := (l_fraction_sum + 0.5 + Rounding_epsilon).floor.to_natural_32
				if l_rounding > 0 and l_sum < a_avail then
					distribute_largest_remainder (Result, l_rem_num, l_rem_den, l_rounding.min (a_avail - l_sum))
					l_sum := sum_of (Result)
				end

				if l_sum > a_avail then
					-- Step 4: shrink by priority group
					across <<Group_max, Group_share, Group_fixed, Group_min>> as g loop
						l_sum := sum_of (Result)
						if l_sum > a_avail then
							shrink_group (Result, a_list, g, l_sum - a_avail)
						end
					end
				elseif l_sum < a_avail then
					-- Step 5: grow
					l_extra := a_avail - l_sum
					if l_weight_sum > 0 then
						grow_group (Result, a_list, Group_flex, l_extra, l_weight_sum)
					elseif l_has_min then
						grow_group (Result, a_list, Group_min, l_extra, l_min_sum)
					elseif a_justify.is_legacy then
						Result.put_i_th (Result.last + l_extra, a_list.count)
					end
				end
			end
		ensure
			count: Result.count = a_list.count
			within_available: sum_of (Result) <= a_avail
		end

	shrink_group (a_alloc: ARRAYED_LIST [NATURAL_32]; a_list: ARRAYED_LIST [CONSTRAINT]; a_group: INTEGER; a_excess: NATURAL_32)
			-- Remove up to `a_excess` cells from the chunks of `a_group`, keeping their sizes
			-- proportional (largest remainder, earlier chunks first on ties).
		local
			l_group_sum, l_keep: NATURAL_32
			l_num, l_den: ARRAYED_LIST [NATURAL_64]
			i: INTEGER
		do
			from
				i := 1
			until
				i > a_list.count
			loop
				if in_group (a_list.i_th (i), a_group) then
					l_group_sum := l_group_sum + a_alloc.i_th (i)
				end
				i := i + 1
			end
			if l_group_sum > 0 then
				l_keep := l_group_sum - a_excess.min (l_group_sum)
				create l_num.make_filled (a_list.count)
				create l_den.make_filled (a_list.count)
				from
					i := 1
				until
					i > a_list.count
				loop
					if in_group (a_list.i_th (i), a_group) then
						l_num.put_i_th (a_alloc.i_th (i).to_natural_64 * l_keep.to_natural_64, i)
						a_alloc.put_i_th ((l_num.i_th (i) // l_group_sum.to_natural_64).to_natural_32, i)
						l_num.put_i_th (l_num.i_th (i) \\ l_group_sum.to_natural_64, i)
						l_den.put_i_th (l_group_sum.to_natural_64, i)
					end
					i := i + 1
				end
				distribute_largest_remainder (a_alloc, l_num, l_den, l_keep - group_total (a_alloc, a_list, a_group))
			end
		end

	grow_group (a_alloc: ARRAYED_LIST [NATURAL_32]; a_list: ARRAYED_LIST [CONSTRAINT]; a_group: INTEGER; a_extra, a_weight_sum: NATURAL_32)
			-- Add `a_extra` cells to the chunks of `a_group` in proportion to their weight (Flex)
			-- or minimum (Min); equal shares when all minimums are 0.
		require
			positive_weights: a_weight_sum > 0 or a_group = Group_min
		local
			l_num, l_den: ARRAYED_LIST [NATURAL_64]
			l_w, l_total, l_given: NATURAL_64
			l_count: INTEGER
			i: INTEGER
		do
			create l_num.make_filled (a_list.count)
			create l_den.make_filled (a_list.count)
			from
				i := 1
			until
				i > a_list.count
			loop
				if in_group (a_list.i_th (i), a_group) then
					l_count := l_count + 1
				end
				i := i + 1
			end
			l_total := a_weight_sum.to_natural_64
			if l_total = 0 then
				l_total := l_count.to_natural_64
			end
			from
				i := 1
			until
				i > a_list.count
			loop
				if in_group (a_list.i_th (i), a_group) then
					if a_weight_sum = 0 then
						l_w := 1
					elseif attached {CONSTRAINT_FLEX} a_list.i_th (i) as l_flex then
						l_w := l_flex.weight.to_natural_64
					else
						l_w := a_alloc.i_th (i).to_natural_64
					end
					l_num.put_i_th (a_extra.to_natural_64 * l_w, i)
					a_alloc.put_i_th (a_alloc.i_th (i) + (l_num.i_th (i) // l_total).to_natural_32, i)
					l_given := l_given + l_num.i_th (i) // l_total
					l_num.put_i_th (l_num.i_th (i) \\ l_total, i)
					l_den.put_i_th (l_total, i)
				end
				i := i + 1
			end
			distribute_largest_remainder (a_alloc, l_num, l_den, (a_extra.to_natural_64 - l_given).to_natural_32)
		end

	distribute_largest_remainder (a_alloc: ARRAYED_LIST [NATURAL_32]; a_num, a_den: ARRAYED_LIST [NATURAL_64]; a_cells: NATURAL_32)
			-- Give one cell each, up to `a_cells`, to the entries with the largest remaining
			-- fraction `a_num / a_den` (earlier entries first on ties); entries with a zero
			-- fraction receive nothing.
		local
			l_left: NATURAL_32
			i, l_best: INTEGER
		do
			from
				l_left := a_cells
			until
				l_left = 0
			loop
				l_best := 0
				from
					i := 1
				until
					i > a_alloc.count
				loop
					if a_num.i_th (i) > 0 and then (l_best = 0 or else
						a_num.i_th (i) * a_den.i_th (l_best) > a_num.i_th (l_best) * a_den.i_th (i)) then
						l_best := i
					end
					i := i + 1
				end
				if l_best = 0 then
					l_left := 0
				else
					a_alloc.put_i_th (a_alloc.i_th (l_best) + 1, l_best)
					a_num.put_i_th (0, l_best)
					l_left := l_left - 1
				end
			end
		end

	in_group (a_constraint: CONSTRAINT; a_group: INTEGER): BOOLEAN
			-- Does `a_constraint` belong to sizing group `a_group`?
		do
			inspect a_group
			when Group_max then
				Result := a_constraint.is_max
			when Group_share then
				Result := a_constraint.is_percentage or a_constraint.is_ratio
			when Group_fixed then
				Result := a_constraint.is_fixed
			when Group_min then
				Result := a_constraint.is_min
			when Group_flex then
				Result := a_constraint.is_flex
			else
			end
		end

	group_total (a_alloc: ARRAYED_LIST [NATURAL_32]; a_list: ARRAYED_LIST [CONSTRAINT]; a_group: INTEGER): NATURAL_32
			-- Cells currently allocated to `a_group`
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > a_list.count
			loop
				if in_group (a_list.i_th (i), a_group) then
					Result := Result + a_alloc.i_th (i)
				end
				i := i + 1
			end
		end

	sum_of (a_alloc: ARRAYED_LIST [NATURAL_32]): NATURAL_32
			-- Total of `a_alloc`
		do
			across a_alloc as a loop
				Result := Result + a
			end
		end

feature {NONE} -- Positioning

	justify_offset (a_justify: FLEX_JUSTIFY; a_index, a_count: INTEGER; a_extra: NATURAL_32): NATURAL_32
			-- Spare cells placed before chunk `a_index` (of `a_count`) when `a_extra` cells are left.
			-- Offsets are rounded from exact positions, so the distribution is symmetric.
		local
			l_i: NATURAL_64
			l_n: NATURAL_64
		do
			l_i := a_index.to_natural_64
			l_n := a_count.to_natural_64
			if a_justify.is_end then
				Result := a_extra
			elseif a_justify.is_center then
				Result := a_extra // 2
			elseif a_justify.is_space_between then
				if a_count > 1 then
					Result := rounded_share (a_extra, l_i - 1, l_n - 1)
				end
			elseif a_justify.is_space_around then
				-- Edges get half the space of the gaps between chunks
				Result := rounded_share (a_extra, 2 * l_i - 1, 2 * l_n)
			elseif a_justify.is_space_evenly then
				Result := rounded_share (a_extra, l_i, l_n + 1)
			end
		ensure
			within_extra: Result <= a_extra
		end

	rounded_share (a_extra: NATURAL_32; a_num, a_den: NATURAL_64): NATURAL_32
			-- `a_extra * a_num / a_den` rounded half up
		require
			positive_denominator: a_den > 0
			fraction: a_num <= a_den
		do
			Result := ((2 * a_extra.to_natural_64 * a_num + a_den) // (2 * a_den)).to_natural_32
		ensure
			within_extra: Result <= a_extra
		end

	chunk (a_area: RECT; a_direction: SPLIT_DIRECTION; a_pos, a_len: NATURAL_32): RECT
			-- Chunk of `a_area` starting at `a_pos` with length `a_len` along `a_direction`
		do
			if a_direction.is_horizontal then
				create Result.make (a_pos.to_natural_16, a_area.y, a_len.to_natural_16, a_area.height)
			else
				create Result.make (a_area.x, a_pos.to_natural_16, a_area.width, a_len.to_natural_16)
			end
		end

feature {NONE} -- Constants

	Group_max: INTEGER = 1
	Group_share: INTEGER = 2
	Group_fixed: INTEGER = 3
	Group_min: INTEGER = 4
	Group_flex: INTEGER = 5
			-- Sizing groups, in shrinking priority order (Max first, Min last)

	Rounding_epsilon: REAL_64 = 1.0e-9
			-- Tolerance when rounding the sum of fractional shares

end
