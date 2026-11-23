note
	description: "[
		Where to put an overlay box (a drop-down menu, a sub-menu, a tooltip) next to the
		control it belongs to, the anchor, inside some bounds (normally the frame's area).
		Shared by TUI_MENU (P2 W4) and the tooltip (P2 W6). No instances: `placement` is a
		pure query.

		The box goes on the preferred side of the anchor (`below`, `above`, `right` or `left`):
		  1. Flip: when it does not fit whole on that side but fits whole on the opposite
		     side, it goes there.
		  2. Shift: along the edge it starts where the anchor starts (the anchor's left column
		     below or above it, its top row right or left of it), and it is moved back towards
		     the start of the bounds when it would run past their end.
		  3. Cut: when it fits whole on neither side, it goes on the side with more room (the
		     preferred side on a tie) and is cut to that room; when it is longer than the
		     bounds along the edge, it is cut to them. A cut box keeps its start (its left
		     column, and its top row unless it is above the anchor), so the first rows and
		     columns of what it holds stay.
		The box never covers the anchor and lies inside the bounds; it is empty when there is
		no room at all.

		    -- a drop-down below a menu bar entry, flipped above it at the bottom of the screen
		    box := {OVERLAY_PLACEMENT}.placement (entry, 20, 8, {OVERLAY_PLACEMENT}.below, frame.area)
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	OVERLAY_PLACEMENT

feature -- Sides

	below: NATURAL_8 = 1
			-- Under the anchor, starting at its left column

	above: NATURAL_8 = 2
			-- Over the anchor, starting at its left column

	right: NATURAL_8 = 3
			-- Right of the anchor, starting at its top row

	left: NATURAL_8 = 4
			-- Left of the anchor, starting at its top row

	is_valid_side (a_side: NATURAL_8): BOOLEAN
			-- Is `a_side` one of `below`, `above`, `right` and `left`?
		do
			Result := a_side >= below and a_side <= left
		ensure
			instance_free: class
		end

	opposite (a_side: NATURAL_8): NATURAL_8
			-- The side across the anchor from `a_side`
		require
			valid_side: is_valid_side (a_side)
		do
			inspect a_side
			when below then Result := above
			when above then Result := below
			when right then Result := left
			else Result := right
			end
		ensure
			instance_free: class
			valid: is_valid_side (Result)
			involution: opposite (Result) = a_side
		end

	is_vertical_side (a_side: NATURAL_8): BOOLEAN
			-- Is `a_side` `below` or `above` (the box is laid out along a row)?
		require
			valid_side: is_valid_side (a_side)
		do
			Result := a_side = below or a_side = above
		ensure
			instance_free: class
		end

feature -- Measurement

	room (a_anchor: RECT; a_side: NATURAL_8; a_bounds: RECT): INTEGER
			-- Rows (below, above) or columns (right, left) between `a_anchor` and the edge of
			-- `a_bounds` on `a_side`, inside `a_bounds`; 0 for empty bounds
		require
			anchor_attached: a_anchor /= Void
			valid_side: is_valid_side (a_side)
			bounds_attached: a_bounds /= Void
		do
			if not a_bounds.is_empty then
				inspect a_side
				when below then
					Result := a_bounds.bottom.to_integer_32 - a_anchor.bottom.to_integer_32.max (a_bounds.top.to_integer_32)
				when above then
					Result := a_anchor.top.to_integer_32.min (a_bounds.bottom.to_integer_32) - a_bounds.top.to_integer_32
				when right then
					Result := a_bounds.right.to_integer_32 - a_anchor.right.to_integer_32.max (a_bounds.left.to_integer_32)
				else
					Result := a_anchor.left.to_integer_32.min (a_bounds.right.to_integer_32) - a_bounds.left.to_integer_32
				end
				Result := Result.max (0)
			end
		ensure
			instance_free: class
			non_negative: Result >= 0
			inside_vertically: is_vertical_side (a_side) implies Result <= a_bounds.height.to_integer_32
			inside_horizontally: not is_vertical_side (a_side) implies Result <= a_bounds.width.to_integer_32
		end

	fits (a_anchor: RECT; a_width, a_height: NATURAL_16; a_side: NATURAL_8; a_bounds: RECT): BOOLEAN
			-- Does a `a_width` x `a_height` box fit whole on `a_side` of `a_anchor` inside
			-- `a_bounds` (shifting along the edge allowed)?
		require
			anchor_attached: a_anchor /= Void
			valid_side: is_valid_side (a_side)
			bounds_attached: a_bounds /= Void
		do
			if is_vertical_side (a_side) then
				Result := room (a_anchor, a_side, a_bounds) >= a_height.to_integer_32 and a_width <= a_bounds.width
			else
				Result := room (a_anchor, a_side, a_bounds) >= a_width.to_integer_32 and a_height <= a_bounds.height
			end
		ensure
			instance_free: class
		end

feature -- Placement

	placed_side (a_anchor: RECT; a_width, a_height: NATURAL_16; a_preferred: NATURAL_8; a_bounds: RECT): NATURAL_8
			-- Side of `a_anchor` that `placement` uses: `a_preferred` when the box fits whole
			-- there; else its opposite when it fits whole there; else the side with more room
			-- (`a_preferred` on a tie)
		require
			anchor_attached: a_anchor /= Void
			valid_side: is_valid_side (a_preferred)
			bounds_attached: a_bounds /= Void
		local
			l_size, l_pref, l_opp: INTEGER
		do
			if is_vertical_side (a_preferred) then
				l_size := a_height.to_integer_32
			else
				l_size := a_width.to_integer_32
			end
			l_pref := room (a_anchor, a_preferred, a_bounds)
			l_opp := room (a_anchor, opposite (a_preferred), a_bounds)
			if l_pref >= l_size then
				Result := a_preferred
			elseif l_opp >= l_size or l_opp > l_pref then
				Result := opposite (a_preferred)
			else
				Result := a_preferred
			end
		ensure
			instance_free: class
			preferred_or_opposite: Result = a_preferred or Result = opposite (a_preferred)
			preferred_when_it_fits: fits (a_anchor, a_width, a_height, a_preferred, a_bounds) implies Result = a_preferred
		end

	placement (a_anchor: RECT; a_width, a_height: NATURAL_16; a_preferred: NATURAL_8; a_bounds: RECT): RECT
			-- Box of `a_width` x `a_height` cells next to `a_anchor` inside `a_bounds`, on
			-- `a_preferred` side, flipped, shifted along the edge, then cut (see the class note)
		require
			anchor_attached: a_anchor /= Void
			valid_side: is_valid_side (a_preferred)
			bounds_attached: a_bounds /= Void
		local
			l_side: NATURAL_8
			l_room, l_cross, l_cross_start, l_along, l_along_start, l_lo, l_hi: INTEGER
		do
			l_side := placed_side (a_anchor, a_width, a_height, a_preferred, a_bounds)
			l_room := room (a_anchor, l_side, a_bounds)
				-- Across the edge: start at the anchor (below, right) or end at it (above, left)
			if is_vertical_side (l_side) then
				l_cross := a_height.to_integer_32.min (l_room)
				if l_side = below then
					l_cross_start := a_anchor.bottom.to_integer_32.max (a_bounds.top.to_integer_32)
				else
					l_cross_start := a_anchor.top.to_integer_32.min (a_bounds.bottom.to_integer_32) - l_cross
				end
				l_along := a_width.to_integer_32
				l_along_start := a_anchor.left.to_integer_32
				l_lo := a_bounds.left.to_integer_32
				l_hi := a_bounds.right.to_integer_32
			else
				l_cross := a_width.to_integer_32.min (l_room)
				if l_side = right then
					l_cross_start := a_anchor.right.to_integer_32.max (a_bounds.left.to_integer_32)
				else
					l_cross_start := a_anchor.left.to_integer_32.min (a_bounds.right.to_integer_32) - l_cross
				end
				l_along := a_height.to_integer_32
				l_along_start := a_anchor.top.to_integer_32
				l_lo := a_bounds.top.to_integer_32
				l_hi := a_bounds.bottom.to_integer_32
			end
				-- Along the edge: shift back inside, then cut to the bounds
			if l_along_start + l_along > l_hi then
				l_along_start := l_hi - l_along
			end
			l_along_start := l_along_start.max (l_lo)
			l_along := l_along.min ((l_hi - l_along_start).max (0))
			if l_cross <= 0 or l_along <= 0 then
				create Result.make (a_bounds.x, a_bounds.y, 0, 0)
			elseif is_vertical_side (l_side) then
				create Result.make (l_along_start.to_natural_16, l_cross_start.to_natural_16, l_along.to_natural_16, l_cross.to_natural_16)
			else
				create Result.make (l_cross_start.to_natural_16, l_along_start.to_natural_16, l_cross.to_natural_16, l_along.to_natural_16)
			end
		ensure
			instance_free: class
			result_attached: Result /= Void
			inside_bounds: Result.is_empty or else a_bounds.contains_rect (Result)
			not_larger: Result.width <= a_width and Result.height <= a_height
			clear_of_anchor: not Result.intersects (a_anchor)
			whole_when_it_fits: (a_width > 0 and a_height > 0 and fits (a_anchor, a_width, a_height, a_preferred, a_bounds))
				implies (Result.width = a_width and Result.height = a_height)
			whole_when_flipped: (a_width > 0 and a_height > 0 and not fits (a_anchor, a_width, a_height, a_preferred, a_bounds)
				and fits (a_anchor, a_width, a_height, opposite (a_preferred), a_bounds))
				implies (Result.width = a_width and Result.height = a_height)
		end

end
