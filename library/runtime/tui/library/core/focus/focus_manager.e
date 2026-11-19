note
	description: "[
		Keyboard focus ring for immediate-mode widgets: ordered WIDGET_IDs with
		Tab / Shift-Tab cycling, programmatic set_focus, and modal push_scope /
		pop_scope traps that restrict navigation until the scope is popped.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	FOCUS_MANAGER

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize with an empty root focus scope.
		do
			create scopes.make (4)
			scopes.extend (create {ARRAYED_LIST [WIDGET_ID]}.make (8))
			create focused_stack.make (4)
			focused_stack.put (Void)
		ensure
			root_scope: scope_depth = 1
			no_focus: not has_focus
		end

feature -- Access

	focused_id: detachable WIDGET_ID
			-- Currently focused widget in the active scope, if any
		do
			Result := focused_stack.item
		end

	scope_depth: INTEGER
			-- Number of nested scopes (1 = root)
		do
			Result := scopes.count
		ensure
			at_least_root: Result >= 1
		end

	has_focus: BOOLEAN
			-- Is some widget focused in the active scope?
		do
			Result := focused_id /= Void
		end

	contains (a_id: WIDGET_ID): BOOLEAN
			-- Is `a_id` registered in the active scope?
		require
			id_attached: a_id /= Void
		do
			Result := index_of (a_id) > 0
		end

feature -- Registration

	register (a_id: WIDGET_ID)
			-- Add `a_id` to the active scope ring if not already present.
			-- First registration in an empty scope becomes focused.
		require
			id_attached: a_id /= Void
		do
			if not contains (a_id) then
				current_ring.extend (a_id)
				if focused_id = Void then
					set_focused_item (a_id)
				end
			end
		ensure
			registered: contains (a_id)
			focus_if_was_empty: old (focused_id = Void) implies focused_id ~ a_id
		end

	unregister (a_id: WIDGET_ID)
			-- Remove `a_id` from the active scope; clear focus if it was focused.
		require
			id_attached: a_id /= Void
		local
			i: INTEGER
		do
			i := index_of (a_id)
			if i > 0 then
				if focused_id ~ a_id then
					if current_ring.count = 1 then
						set_focused_item (Void)
					else
						focus_next
						if focused_id ~ a_id then
							set_focused_item (Void)
						end
					end
				end
				i := index_of (a_id)
				if i > 0 then
					current_ring.go_i_th (i)
					current_ring.remove
				end
			end
		ensure
			gone: not contains (a_id)
		end

	wipe_ring
			-- Clear all ids in the active scope and drop focus.
		do
			current_ring.wipe_out
			set_focused_item (Void)
		ensure
			empty: current_ring.is_empty
			no_focus: not has_focus
		end

feature -- Focus

	set_focus (a_id: WIDGET_ID)
			-- Focus `a_id` if it belongs to the active scope.
		require
			id_attached: a_id /= Void
			in_scope: contains (a_id)
		do
			set_focused_item (a_id)
		ensure
			focused: focused_id ~ a_id
		end

	focus_at (a_hit: detachable WIDGET_ID): BOOLEAN
			-- Focus `a_hit` (the result of a mouse hit test, such as
			-- {TUI_APPLICATION}.hit_test) if it is registered in the active scope, and tell
			-- whether the click was consumed. A click on nothing (Void), or on an id of an
			-- outer scope while a modal scope is active, or on an unknown id, changes nothing
			-- and is not consumed. Only the active (innermost) scope counts: ids of every
			-- outer scope are out of reach until their scopes are active again.
			-- Consumed also when `a_hit` is already focused.
		do
			if attached a_hit as l_id and then contains (l_id) then
				set_focused_item (l_id)
				Result := True
			end
		ensure
			consumed_iff_in_scope: Result = (attached a_hit as l_id and then contains (l_id))
			focused: Result implies focused_id ~ a_hit
			unchanged_otherwise: not Result implies focused_id = old focused_id
			same_scope: scope_depth = old scope_depth
		end

	focus_next
			-- Move focus to the next id in the active ring (Tab).
		local
			i: INTEGER
		do
			if not current_ring.is_empty then
				i := focused_index
				if i < 1 then
					set_focused_item (current_ring.first)
				elseif i >= current_ring.count then
					set_focused_item (current_ring.first)
				else
					set_focused_item (current_ring.i_th (i + 1))
				end
			end
		end

	focus_previous
			-- Move focus to the previous id in the active ring (Shift-Tab).
		local
			i: INTEGER
		do
			if not current_ring.is_empty then
				i := focused_index
				if i <= 1 then
					set_focused_item (current_ring.last)
				else
					set_focused_item (current_ring.i_th (i - 1))
				end
			end
		end

	is_focused (a_id: WIDGET_ID): BOOLEAN
			-- Is `a_id` the current focus?
		require
			id_attached: a_id /= Void
		do
			Result := focused_id ~ a_id
		end

feature -- Modal scopes

	push_scope
			-- Push an empty modal focus scope (navigation trapped until `pop_scope`).
		do
			scopes.extend (create {ARRAYED_LIST [WIDGET_ID]}.make (8))
			focused_stack.put (Void)
		ensure
			deeper: scope_depth = old scope_depth + 1
			no_focus: not has_focus
		end

	pop_scope
			-- Pop the top modal scope and restore the previous ring's focus.
		require
			not_root: scope_depth > 1
		do
			scopes.finish
			scopes.remove
			focused_stack.remove
		ensure
			shallower: scope_depth = old scope_depth - 1
		end

	enter_modal (a_ids: ARRAY [WIDGET_ID])
			-- Push a scope and register every id in `a_ids` (first becomes focused).
		require
			ids_attached: a_ids /= Void
			ids_not_empty: a_ids.count > 0
		local
			i: INTEGER
		do
			push_scope
			from
				i := a_ids.lower
			until
				i > a_ids.upper
			loop
				register (a_ids [i])
				i := i + 1
			end
		ensure
			deeper: scope_depth = old scope_depth + 1
			has_focus: has_focus
		end

feature {NONE} -- Implementation

	scopes: ARRAYED_LIST [ARRAYED_LIST [WIDGET_ID]]
			-- Nested focus rings; last is active

	focused_stack: ARRAYED_STACK [detachable WIDGET_ID]
			-- Focused id per scope level (parallel to `scopes`)

	current_ring: ARRAYED_LIST [WIDGET_ID]
			-- Active scope's ordered ids
		do
			Result := scopes.last
		ensure
			ring_attached: Result /= Void
		end

	index_of (a_id: WIDGET_ID): INTEGER
			-- 1-based index of `a_id` in the active ring, or 0.
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > current_ring.count or Result > 0
			loop
				if current_ring.i_th (i) ~ a_id then
					Result := i
				else
					i := i + 1
				end
			end
		end

	focused_index: INTEGER
			-- 1-based index of `focused_id` in the active ring, or 0.
		do
			if attached focused_id as id then
				Result := index_of (id)
			end
		end

	set_focused_item (a_id: detachable WIDGET_ID)
			-- Replace the top of `focused_stack` with `a_id`.
		do
			focused_stack.replace (a_id)
		end

invariant
	scopes_attached: scopes /= Void
	focused_stack_attached: focused_stack /= Void
	parallel_depth: scopes.count = focused_stack.count
	at_least_root: scopes.count >= 1

end
