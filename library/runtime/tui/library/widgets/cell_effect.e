note
	description: "[
		Effect that changes the cells covered by a SHADOW (Ratatui `CellEffect`).
		SHADOW.render applies the shadow style first, then calls `apply` with the shadow
		area (already cut to the buffer) and the area of the block that casts the shadow.
		An effect must leave the cells inside `a_base_area` alone: `visible_regions` and
		`is_shadow_cell` give the cells it may change.

		An effect must not keep state between calls to `apply`. A block (and so its shadow
		and the effect, which `twin` shares rather than copies) may be rendered again and
		again, from any thread that owns the buffer. This is the EiffelTUI form of the
		Ratatui 0.30.2 rule that custom effects be `Send + Sync`.

		Effects that write symbols should use `put_shadow_symbol`: it keeps the buffer's
		continuation invariant when a wide character is under, or cut by, the shadow.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	CELL_EFFECT

feature -- Basic operations

	apply (a_shadow_area, a_base_area: RECT; a_buffer: BUFFER)
			-- Change the cells of `a_shadow_area` that are not in `a_base_area`.
			-- `a_shadow_area` lies inside `a_buffer`.
		require
			shadow_area_not_void: a_shadow_area /= Void
			base_area_not_void: a_base_area /= Void
			buffer_not_void: a_buffer /= Void
			shadow_area_in_buffer: a_buffer.area.contains_rect (a_shadow_area)
		deferred
		end

feature -- Shadow cells

	visible_regions (a_shadow_area, a_base_area: RECT): ARRAYED_LIST [RECT]
			-- The part of `a_shadow_area` outside `a_base_area` (see {SHADOW}.visible_regions)
		require
			shadow_area_not_void: a_shadow_area /= Void
			base_area_not_void: a_base_area /= Void
		do
			Result := {SHADOW}.visible_regions (a_shadow_area, a_base_area)
		ensure
			at_most_four: Result.count <= 4
			inside_shadow: across Result as r all a_shadow_area.contains_rect (r) end
			outside_base: across Result as r all not r.intersects (a_base_area) end
		end

	is_shadow_cell (a_row, a_col: INTEGER; a_shadow_area, a_base_area: RECT): BOOLEAN
			-- Is the cell at (`a_row`, `a_col`) in `a_shadow_area` and not in `a_base_area`?
		require
			shadow_area_not_void: a_shadow_area /= Void
			base_area_not_void: a_base_area /= Void
		do
			Result := {SHADOW}.is_shadow_cell (a_row, a_col, a_shadow_area, a_base_area)
		end

	put_shadow_symbol (a_buffer: BUFFER; a_row, a_col: INTEGER; a_char: CHARACTER_32)
			-- Put the one-column `a_char` at (`a_row`, `a_col`), keeping the cell's style and
			-- splitting a wide character it cuts (see {SHADOW}.put_shadow_symbol).
		require
			buffer_not_void: a_buffer /= Void
			valid_position: a_buffer.is_valid_position (a_row, a_col)
			one_column: {UNICODE_WIDTH}.width (a_char.natural_32_code) = 1
		do
			{SHADOW}.put_shadow_symbol (a_buffer, a_row, a_col, a_char)
		ensure
			continuation_consistent: a_buffer.is_continuation_consistent (a_row)
		end

end
