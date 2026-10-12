note
	description: "[
		Immutable value object representing a layout specification: direction, constraints,
		margin, spacing, and flex justification strategy. Change it with the `with_*` builders,
		which return new layouts.
		A negative spacing (`with_overlap`) makes neighbouring chunks share cells, e.g. a common
		border that TUI_BLOCK merges with `with_border_merged`.
		Splits a target RECT into child RECTs and, with `split_with_spacers`, the spacers around them
		(see LAYOUT_SOLVER for the algorithm and guarantees: chunks inside the area that exactly fill
		it when the layout can absorb all space; ordered and non-overlapping unless an overlap is
		requested). Results are cached per thread in `shared_cache` (LRU, 500 entries); `split`
		always returns fresh arrays, so callers may modify them.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	LAYOUT

inherit
	ANY
		redefine
			default_create,
			is_equal,
			out
		end

create
	default_create,
	make,
	make_horizontal,
	make_vertical,
	make_with_all

feature {NONE} -- Initialization

	default_create
			-- Initialize layout with vertical direction, empty constraints, zero margin, zero spacing, start flex.
		do
			direction := {SPLIT_DIRECTION}.vertical
			create constraint_list.make (0)
			create margin.default_create
			spacing := 0
			flex := {FLEX_JUSTIFY}.start_align
		ensure then
			direction_vertical: direction.is_vertical
			constraints_empty: constraints.is_empty
			margin_zero: margin.horizontal = 0 and margin.vertical = 0
			spacing_zero: spacing = 0
			flex_start: flex.is_start
		end

	make (a_direction: SPLIT_DIRECTION; a_constraints: ITERABLE [CONSTRAINT])
			-- Initialize layout with `a_direction` and `a_constraints`.
		require
			direction_attached: a_direction /= Void
			constraints_attached: a_constraints /= Void
		do
			make_with_all (a_direction, a_constraints, create {MARGIN}.default_create, 0, {FLEX_JUSTIFY}.start_align)
		ensure
			direction_set: direction = a_direction
		end

	make_horizontal (a_constraints: ITERABLE [CONSTRAINT])
			-- Initialize horizontal layout with `a_constraints`.
		require
			constraints_attached: a_constraints /= Void
		do
			make ({SPLIT_DIRECTION}.horizontal, a_constraints)
		ensure
			direction_horizontal: direction.is_horizontal
		end

	make_vertical (a_constraints: ITERABLE [CONSTRAINT])
			-- Initialize vertical layout with `a_constraints`.
		require
			constraints_attached: a_constraints /= Void
		do
			make ({SPLIT_DIRECTION}.vertical, a_constraints)
		ensure
			direction_vertical: direction.is_vertical
		end

	make_with_all (
		a_direction: SPLIT_DIRECTION;
		a_constraints: ITERABLE [CONSTRAINT];
		a_margin: MARGIN;
		a_spacing: INTEGER;
		a_flex: FLEX_JUSTIFY
	)
			-- Initialize layout with complete parameters.
		require
			direction_attached: a_direction /= Void
			constraints_attached: a_constraints /= Void
			margin_attached: a_margin /= Void
			flex_attached: a_flex /= Void
		do
			direction := a_direction
			create constraint_list.make (8)
			across a_constraints as c loop
				constraint_list.extend (c)
			end
			margin := a_margin
			spacing := a_spacing
			flex := a_flex
		ensure
			direction_set: direction = a_direction
			margin_set: margin = a_margin
			spacing_set: spacing = a_spacing
			flex_set: flex = a_flex
		end

feature -- Access

	direction: SPLIT_DIRECTION
			-- Orientation of split (horizontal or vertical)

	constraints: ARRAYED_LIST [CONSTRAINT]
			-- Copy of the sequence of constraints to evaluate (changing it does not affect `Current`)
		do
			create Result.make_from_iterable (constraint_list)
		ensure
			same_count: Result.count = constraint_count
		end

	constraint_count: INTEGER
			-- Number of constraints
		do
			Result := constraint_list.count
		end

	constraint (i: INTEGER): CONSTRAINT
			-- `i`-th constraint
		require
			valid_index: i >= 1 and i <= constraint_count
		do
			Result := constraint_list.i_th (i)
		end

	margin: MARGIN
			-- Margin deflating parent area before splitting

	spacing: INTEGER
			-- Gap cells between adjacent chunks (negative for overlap)

	spacing_model: SPACING
			-- High-level spacing specification (Space or Overlap)
		do
			create Result.make_from_integer (spacing)
		ensure
			result_attached: Result /= Void
		end

	has_overlap: BOOLEAN
			-- Does layout have negative spacing (overlapping segments)?
		do
			Result := spacing < 0
		end

	flex: FLEX_JUSTIFY
			-- Justification strategy for distributing remaining space

feature -- Fluent Builders

	with_direction (a_direction: SPLIT_DIRECTION): LAYOUT
			-- Copy of Current with updated direction `a_direction`.
		require
			direction_attached: a_direction /= Void
		do
			create Result.make_with_all (a_direction, constraint_list, margin, spacing, flex)
		ensure
			direction_updated: Result.direction = a_direction
		end

	with_constraints (a_constraints: ITERABLE [CONSTRAINT]): LAYOUT
			-- Copy of Current with updated constraints `a_constraints`.
		require
			constraints_attached: a_constraints /= Void
		do
			create Result.make_with_all (direction, a_constraints, margin, spacing, flex)
		end

	with_margin (a_margin: MARGIN): LAYOUT
			-- Copy of Current with updated margin `a_margin`.
		require
			margin_attached: a_margin /= Void
		do
			create Result.make_with_all (direction, constraint_list, a_margin, spacing, flex)
		ensure
			margin_updated: Result.margin = a_margin
		end

	with_horizontal_margin (a_h_margin: NATURAL_16): LAYOUT
			-- Copy of Current with updated horizontal margin `a_h_margin`.
		local
			l_m: MARGIN
		do
			create l_m.make (a_h_margin, margin.vertical)
			Result := with_margin (l_m)
		ensure
			h_margin_updated: Result.margin.horizontal = a_h_margin
		end

	with_vertical_margin (a_v_margin: NATURAL_16): LAYOUT
			-- Copy of Current with updated vertical margin `a_v_margin`.
		local
			l_m: MARGIN
		do
			create l_m.make (margin.horizontal, a_v_margin)
			Result := with_margin (l_m)
		ensure
			v_margin_updated: Result.margin.vertical = a_v_margin
		end

	with_spacing (a_spacing: INTEGER): LAYOUT
			-- Copy of Current with updated spacing `a_spacing` (negative values represent overlap).
		do
			create Result.make_with_all (direction, constraint_list, margin, a_spacing, flex)
		ensure
			spacing_updated: Result.spacing = a_spacing
		end

	with_overlap (a_overlap: NATURAL_16): LAYOUT
			-- Copy of Current with overlapping spacing of `a_overlap` cells.
		do
			Result := with_spacing (- a_overlap.to_integer_32)
		ensure
			has_overlap: a_overlap > 0 implies Result.has_overlap
		end

	with_spacing_model (a_spacing: SPACING): LAYOUT
			-- Copy of Current with spacing defined by `a_spacing` model.
		require
			spacing_attached: a_spacing /= Void
		do
			Result := with_spacing (a_spacing.effective_spacing.to_integer_32)
		end

	with_flex (a_flex: FLEX_JUSTIFY): LAYOUT
			-- Copy of Current with updated flex `a_flex`.
		require
			flex_attached: a_flex /= Void
		do
			create Result.make_with_all (direction, constraint_list, margin, spacing, a_flex)
		ensure
			flex_updated: Result.flex = a_flex
		end

feature -- Operations

	split_with_spacers (a_area: RECT): TUPLE [areas: ARRAY [RECT]; spacers: ARRAY [RECT]]
			-- Split `a_area` into chunks and the spacers between/around them according to layout
			-- specification. Fresh arrays are returned (copies of the cached solution).
		local
			l_solution: LAYOUT_CACHE_ENTRY
		do
			l_solution := solution (a_area)
			if attached l_solution.spacers as l_spacers then
				Result := [l_solution.areas.twin, l_spacers.twin]
			else
				Result := [l_solution.areas.twin, create {ARRAY [RECT]}.make_empty]
			end
		ensure
			areas_count: Result.areas.count = constraint_count
			spacers_count: Result.spacers.count = (if constraint_count = 0 then 1 else constraint_count + 1 end)
			areas_one_based: Result.areas.lower = 1
			spacers_one_based: Result.spacers.lower = 1
			well_formed: is_well_formed (a_area, Result.areas)
			covers_length: covers_length (a_area, Result.areas)
		end

	split_with_spacers_list (a_area: RECT): TUPLE [areas: ARRAYED_LIST [RECT]; spacers: ARRAYED_LIST [RECT]]
			-- Split `a_area` and return result as lists of areas and spacers.
		local
			l_solution: LAYOUT_CACHE_ENTRY
		do
			l_solution := solution (a_area)
			if attached l_solution.spacers as l_spacers then
				Result := [list_copy (l_solution.areas), list_copy (l_spacers)]
			else
				Result := [list_copy (l_solution.areas), create {ARRAYED_LIST [RECT]}.make (0)]
			end
		ensure
			areas_count: Result.areas.count = constraint_count
			spacers_count: Result.spacers.count = (if constraint_count = 0 then 1 else constraint_count + 1 end)
		end

	split (a_area: RECT): ARRAY [RECT]
			-- Split `a_area` into chunks according to layout specification.
			-- The result is a fresh array (a copy of the cached solution; spacers are not copied).
		do
			Result := solution (a_area).areas.twin
		ensure
			correct_count: Result.count = constraint_count
			one_based: Result.lower = 1
			well_formed: is_well_formed (a_area, Result)
			covers_length: covers_length (a_area, Result)
		end

	split_list (a_area: RECT): ARRAYED_LIST [RECT]
			-- Split `a_area` and return the chunks as a fresh ARRAYED_LIST [RECT]
			-- (built directly from the cached solution: one list, no intermediate array).
		do
			Result := list_copy (solution (a_area).areas)
		ensure
			correct_count: Result.count = constraint_count
		end

	inner_area (a_area: RECT): RECT
			-- `a_area` deflated by `margin`
		do
			if margin.horizontal > 0 or margin.vertical > 0 then
				Result := a_area.inner (margin.horizontal, margin.vertical)
			else
				Result := a_area
			end
		end

feature -- Postcondition Queries

	chunks_do_not_overlap (a_rects: ARRAY [RECT]): BOOLEAN
			-- Do no two non-empty rectangles in `a_rects` intersect?
		do
			Result := Solver.chunks_do_not_overlap (create {ARRAYED_LIST [RECT]}.make_from_array (a_rects))
		end

	is_well_formed (a_area: RECT; a_rects: ARRAY [RECT]): BOOLEAN
			-- Are `a_rects` ordered, inside the inner area of `a_area` and spanning it
			-- across the split direction (and non-overlapping if spacing is non-negative)?
		do
			if has_overlap then
				Result := Solver.is_well_formed_with_overlap (inner_area (a_area), direction, create {ARRAYED_LIST [RECT]}.make_from_array (a_rects), - spacing)
			else
				Result := Solver.is_well_formed (inner_area (a_area), direction, create {ARRAYED_LIST [RECT]}.make_from_array (a_rects))
			end
		end

	covers_length (a_area: RECT; a_rects: ARRAY [RECT]): BOOLEAN
			-- When the layout can absorb all space (see {LAYOUT_SOLVER}.is_filling), do `a_rects`
			-- exactly fill the inner area of `a_area` along the split direction?
		local
			l_inner: RECT
		do
			l_inner := inner_area (a_area)
			Result := Solver.is_filling (l_inner, constraint_list, direction, spacing, flex) implies
				Solver.fills_length (l_inner, direction, create {ARRAYED_LIST [RECT]}.make_from_array (a_rects))
		end

feature -- Shared Cache (Class feature)

	shared_cache: LAYOUT_CACHE
			-- Layout cache keyed by (area, layout), one per thread (`once` is per thread)
		once
			create Result.default_create
		ensure
			instance_free: class
			cache_attached: Result /= Void
		end

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Is `Current` equal in value to `a_other`?
		local
			i: INTEGER
		do
			if direction.is_equal (a_other.direction) and
			   margin.is_equal (a_other.margin) and
			   spacing = a_other.spacing and
			   flex.is_equal (a_other.flex) and
			   constraint_count = a_other.constraint_count
			then
				Result := True
				from
					i := 1
				until
					i > constraint_count or not Result
				loop
					if not constraint (i).is_equal (a_other.constraint (i)) then
						Result := False
					end
					i := i + 1
				end
			end
		end

feature {NONE} -- Implementation

	solution (a_area: RECT): LAYOUT_CACHE_ENTRY
			-- Solution for `a_area`: the cache's own entry (no allocation on a hit), computed and
			-- stored on a miss. Its arrays belong to the cache and must never be handed out.
		local
			l_res: TUPLE [areas: ARRAYED_LIST [RECT]; spacers: ARRAYED_LIST [RECT]]
			l_areas, l_spacers: ARRAY [RECT]
		do
			if attached shared_cache.entry (a_area, Current) as l_cached and then attached l_cached.spacers then
				Result := l_cached
			else
				l_res := (create {LAYOUT_SOLVER}).split_with_spacers (inner_area (a_area), constraint_list, direction, spacing, flex)
				l_areas := array_copy (l_res.areas)
				l_spacers := array_copy (l_res.spacers)
				shared_cache.put_with_spacers (l_areas, l_spacers, a_area, Current)
				if attached shared_cache.entry (a_area, Current) as l_stored then
					Result := l_stored
				else
					-- Caching disabled: a private entry
					create Result.make (create {LAYOUT_CACHE_KEY}.make (a_area, Current), l_areas, l_spacers)
				end
			end
		ensure
			areas_count: Result.areas.count = constraint_count
			has_spacers: Result.spacers /= Void
		end

	array_copy (a_list: ARRAYED_LIST [RECT]): ARRAY [RECT]
			-- 1-based array with the items of `a_list`
		local
			i: INTEGER
		do
			create Result.make_filled (Empty_rect, 1, a_list.count)
			from
				i := 1
			until
				i > a_list.count
			loop
				Result.put (a_list.i_th (i), i)
				i := i + 1
			end
		ensure
			same_count: Result.count = a_list.count
		end

	list_copy (a_array: ARRAY [RECT]): ARRAYED_LIST [RECT]
			-- Fresh list with the items of `a_array`
		do
			create Result.make (a_array.count)
			across a_array as r loop
				Result.extend (r)
			end
		ensure
			same_count: Result.count = a_array.count
		end

	Empty_rect: RECT
			-- Shared filler for new arrays
		once
			create Result
		ensure
			instance_free: class
		end

	constraint_list: ARRAYED_LIST [CONSTRAINT]
			-- Constraints (never exposed, so a layout used as a cache key cannot change)

	Solver: LAYOUT_SOLVER
			-- Solver used by the postcondition queries
		once
			create Result
		ensure
			instance_free: class
		end

feature -- Output

	out: STRING_8
			-- String representation
		do
			Result := "LAYOUT [dir=" + direction.out + ", constraints=" + constraint_count.out +
				", margin=(" + margin.horizontal.out + "," + margin.vertical.out + ")" +
				", spacing=" + spacing.out + ", flex=" + flex.out + "]"
		end

invariant
	direction_attached: direction /= Void
	constraints_attached: constraint_list /= Void
	margin_attached: margin /= Void
	flex_attached: flex /= Void

end
