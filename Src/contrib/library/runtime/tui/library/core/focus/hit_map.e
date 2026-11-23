note
	description: "[
		Per-frame mouse hit-test map: interactive widgets register (id, RECT) during
		render; mouse events resolve to the topmost (last registered) covering id.
		A blocker region (`register_blocker`) has no id: it hides what lies below it.
		A modal (`register_modal`, used by a modal TUI_POPUP) blocks the whole frame and
		also clips every region registered after it to the dialog's area, so a background
		control rendered after the dialog by mistake cannot be clicked through it: only the
		dialog's own controls are reachable while it is open, whatever the drawing order.
		An overlay (`begin_overlay` .. `end_overlay`, used by an open TUI_MENU) is a modal made
		of several boxes: it blocks the whole frame, its own regions are registered unclipped
		(it is above any earlier modal), and every region registered after it is unreachable.
		Coordinates are those of the frame buffer (viewport-relative); see
		{TUI_APPLICATION}.hit_test for mouse events in screen coordinates.
		Each FRAME has a fresh map (immediate-mode).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	HIT_MAP

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize an empty hit map.
		do
			create entries.make (16)
		ensure
			empty: is_empty
			no_modal: modal_area = Void
		end

feature -- Access

	modal_area: detachable RECT
			-- Dialog area of the innermost modal registered with `register_modal`, to which
			-- later regions are clipped; Void when no modal was registered

	effective_area (a_area: RECT): RECT
			-- Part of `a_area` that `register` would make reachable: all of it, or, after
			-- `register_modal`, only what lies inside `modal_area`.
		require
			area_attached: a_area /= Void
		do
			if is_overlay_open then
				Result := a_area
			elseif attached modal_area as l_modal then
				Result := a_area.intersection (l_modal)
			else
				Result := a_area
			end
		ensure
			unclipped: (modal_area = Void or is_overlay_open) implies Result = a_area
			inside_modal: (not is_overlay_open and then attached modal_area as l_modal)
				implies (Result.is_empty or l_modal.contains_rect (Result))
		end

feature -- Status report

	is_empty: BOOLEAN
			-- Are there no registered regions?
		do
			Result := entries.is_empty
		end

	count: INTEGER
			-- Number of registered regions
		do
			Result := entries.count
		end

	is_overlay_open: BOOLEAN
			-- Between `begin_overlay` and `end_overlay`: are regions registered unclipped?

feature -- Registration

	register (a_id: WIDGET_ID; a_area: RECT)
			-- Record that `a_id` occupies `a_area` (later entries sit above earlier ones),
			-- clipped to `modal_area` when a modal was registered before (`effective_area`).
		require
			id_attached: a_id /= Void
			area_attached: a_area /= Void
		do
			entries.extend ([a_id, effective_area (a_area)])
		ensure
			one_more: count = old count + 1
			topmost: not effective_area (a_area).is_empty
				implies hit (effective_area (a_area).x, effective_area (a_area).y) ~ a_id
		end

	register_blocker (a_area: RECT)
			-- Record a region without id above the earlier ones: points in `a_area` hit
			-- nothing, even where a region registered before covers them, unless a region
			-- registered after this call covers them too.
		require
			area_attached: a_area /= Void
		do
			entries.extend ([Void, a_area])
		ensure
			one_more: count = old count + 1
			hides_below: not a_area.is_empty implies hit (a_area.x, a_area.y) = Void
		end

	register_modal (a_blocked, a_dialog: RECT)
			-- Open a modal: block `a_blocked` (normally the whole frame), then clip every region
			-- registered after this call to `a_dialog`, so only controls inside the dialog stay
			-- reachable, whether they are drawn before or after other background content.
			-- A nested modal replaces the clip with its own dialog area.
		require
			blocked_attached: a_blocked /= Void
			dialog_attached: a_dialog /= Void
			no_overlay_open: not is_overlay_open
		do
			register_blocker (a_blocked)
			modal_area := a_dialog
		ensure
			one_more: count = old count + 1
			hides_below: not a_blocked.is_empty implies hit (a_blocked.x, a_blocked.y) = Void
			clipped: modal_area = a_dialog
		end

	begin_overlay (a_blocked: RECT)
			-- Open an overlay: block `a_blocked` (normally the whole frame), then register the
			-- regions that follow unclipped, even after a modal, until `end_overlay`.
		require
			blocked_attached: a_blocked /= Void
			no_overlay_open: not is_overlay_open
		do
			register_blocker (a_blocked)
			is_overlay_open := True
		ensure
			one_more: count = old count + 1
			hides_below: not a_blocked.is_empty implies hit (a_blocked.x, a_blocked.y) = Void
			open: is_overlay_open
		end

	end_overlay
			-- Close the overlay: every region registered after this call is clipped away (it
			-- hits nothing), as it lies below the overlay, until a later modal clips to its own
			-- dialog.
		require
			overlay_open: is_overlay_open
		do
			is_overlay_open := False
			create modal_area.make (0, 0, 0, 0)
		ensure
			closed: not is_overlay_open
			later_unreachable: attached modal_area as l_modal and then l_modal.is_empty
		end

	wipe_out
			-- Clear all registrations for a new frame.
		do
			entries.wipe_out
			modal_area := Void
			is_overlay_open := False
		ensure
			empty: is_empty
			no_modal: modal_area = Void
			no_overlay: not is_overlay_open
		end

feature -- Query

	hit (a_column, a_row: NATURAL_16): detachable WIDGET_ID
			-- Id of the topmost region covering (`a_column`, `a_row`); Void if none covers it
			-- or the topmost one is a blocker.
		local
			i: INTEGER
			l_found: BOOLEAN
		do
			from
				i := entries.count
			until
				i < 1 or l_found
			loop
				if entries.i_th (i).area.contains_point (a_column, a_row) then
					Result := entries.i_th (i).id
					l_found := True
				end
				i := i - 1
			end
		end

feature {NONE} -- Implementation

	entries: ARRAYED_LIST [TUPLE [id: detachable WIDGET_ID; area: RECT]]
			-- Registration order (last = highest Z); Void id for a blocker

invariant
	entries_attached: entries /= Void

end
