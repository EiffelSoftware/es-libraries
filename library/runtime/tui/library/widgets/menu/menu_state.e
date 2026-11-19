note
	description: "[
		State of a TUI_MENU (P2 W4): the menu's items and which of them are open. Modelled on
		the `tui-menu` crate's `MenuState` (Ratatui has no menu). The application keeps one
		MENU_STATE and handles the keys and the mouse through it, as it does a LIST_STATE.

		Items: `set_items` gives the bar entries (MENU_ITEMs, each with an optional sub-menu
		shown as a drop-down); they are kept as the children of `root`. Items are immutable,
		so the open path stays valid until the next `set_items`, which closes the menu.

		The open path (`path`, one index per level): level 1 is the bar, level k > 1 the
		sub-menu of the item highlighted at level k - 1. `path` [k] is the item highlighted at
		level k; the last level may have 0 (a drop-down shown with nothing highlighted, as
		after a click, or when it has nothing selectable). So:
		  * closed: `path` is empty (`is_open` is False);
		  * [2]: the bar is active with entry 2 highlighted, no drop-down (after Esc);
		  * [2, 0]: entry 2's drop-down shown, nothing highlighted;
		  * [2, 3, 1]: item 3 of that drop-down opened its sub-menu, whose item 1 is highlighted.
		Every level before the last highlights a selectable item with a sub-menu (invariant
		`valid_path`).

		Scrolling: each drop-down level has an `offset`, the number of its items scrolled out
		above the top of its box. A drop-down cut by the screen's edge shows only some of its
		items; TUI_MENU, while rendering, scrolls it (`keep_highlight_visible`) so the
		highlighted item is always shown, as TUI_LIST does with LIST_STATE's offset. So the
		keys never move onto an item the user cannot see. A level starts at offset 0 when it
		opens. The bar scrolls the same way, sideways: its offset (`bar_offset`, kept while
		the menu moves from entry to entry, 0 when closed) is the number of entries scrolled
		out to the left, so an entry past the right edge is scrolled into view when the keys
		(Right, Left, Alt+letter) reach it (`scroll_bar`, called by TUI_MENU).

		Keys (the application's part; the state reads no events):

		    if k.code.is_function and then k.code.function_number = 10 then
		        if menu.is_open then menu.close else menu.open end
		    elseif k.modifiers.is_alt and then k.code.is_char
		        and then menu.entry_with_initial (k.code.character) > 0
		    then
		        menu.open_entry (menu.entry_with_initial (k.code.character))
		    elseif menu.is_open then
		        if k.code.is_down then menu.move_down
		        elseif k.code.is_up then menu.move_up
		        elseif k.code.is_right then menu.move_right
		        elseif k.code.is_left then menu.move_left
		        elseif k.code.is_enter then menu.activate
		        elseif k.code.is_escape then menu.close_level
		        end
		        -- any other key, Tab included, is swallowed while the menu is open
		    end
		    if attached menu.chosen as id then run_command (id); menu.clear_chosen end

		  * `move_down` / `move_up` go to the next / previous selectable item, skipping
		    separators and disabled items and wrapping round at the ends; on the bar they open
		    the entry's drop-down.
		  * `move_right` opens the highlighted item's sub-menu, or else goes to the next bar
		    entry (with its drop-down open if one was open); `move_left` leaves a sub-menu, or
		    else goes to the previous bar entry.
		  * `activate` (Enter) opens a sub-menu, or chooses a leaf: `chosen_item` / `chosen`
		    are set and the menu closes.
		  * `close_level` (Esc) closes the innermost level; on the bar it closes the menu.

		Mouse: a TUI_MENU registers each bar entry and each shown item with a `widget_id` in
		the frame's hit map, `menu_id` (when set) under the bar row and the drop-downs, and,
		while the menu is open, a blocker over the whole frame first, so a click outside the
		menu hits nothing. Ask `handles` first, then give the hit to `click`:

		    if m.is_down then
		        hit := hit_test (m)
		        if menu.handles (hit) then menu.click (hit) else ... the background ... end
		    end

		`click` on a bar entry opens its drop-down (or closes it when it is the open one), on
		an item with a sub-menu opens the sub-menu, on a leaf chooses it, on a disabled item or
		on `menu_id` does nothing, and anywhere else closes the menu. Only the items shown are
		looked up; ids should be unique in the menu (the first one shown counts).

		Focus: after `set_focus_manager (focus)`, the state pushes a focus scope on `focus`
		whenever the menu opens and pops it whenever it closes (by a key, a click, `activate`,
		`close` or `set_items`), so the scope is open exactly while the menu is: Tab cannot
		reach the controls behind an open menu, `focus_at` refuses their ids, and their focus
		comes back when it closes. (*Decided*: this replaces TUI_POPUP's `begin_modal` /
		`end_modal` pair; the open/closed state lives here, not in the immediate-mode widget,
		and no closing path can forget to pop.) The scope must be the innermost one whenever
		the menu closes (`is_scope_innermost`).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	MENU_STATE

inherit
	WIDGET_STATE
		redefine
			default_create,
			copy,
			is_equal
		end

create
	default_create,
	make

feature {NONE} -- Initialization

	default_create
			-- Closed state with no items.
		do
			create root.make_submenu ("", create {ARRAYED_LIST [MENU_ITEM]}.make (0))
			create open_path.make (4)
			create open_offsets.make (4)
		ensure then
			closed: not is_open
			no_items: count = 0
			nothing_chosen: chosen_item = Void
		end

	make (a_items: ITERABLE [MENU_ITEM])
			-- Closed state with the bar entries `a_items`.
		require
			items_not_void: a_items /= Void
		do
			default_create
			set_items (a_items)
		ensure
			closed: not is_open
		end

feature -- Access

	root: MENU_ITEM
			-- Unlabelled item whose sub-menu is the bar

	count: INTEGER
			-- Number of bar entries
		do
			Result := root.count
		ensure
			definition: Result = root.count
		end

	entry (i: INTEGER): MENU_ITEM
			-- `i`-th bar entry
		require
			valid_index: i >= 1 and i <= count
		do
			Result := root.child (i)
		end

	items: ARRAYED_LIST [MENU_ITEM]
			-- A new list of the bar entries
		do
			Result := root.submenu
		ensure
			same_count: Result.count = count
		end

	path: ARRAYED_LIST [INTEGER]
			-- A new list holding the open path (see the class note); empty when closed
		do
			create Result.make (open_path.count)
			Result.append (open_path)
		ensure
			same_depth: Result.count = depth
		end

	depth: INTEGER
			-- Number of open levels: 0 closed, 1 the bar only, k the bar and k - 1 drop-downs
		do
			Result := open_path.count
		ensure
			non_negative: Result >= 0
		end

	selected (a_level: INTEGER): INTEGER
			-- Index highlighted at `a_level` (0: none, only possible at the last level)
		require
			valid_level: a_level >= 1 and a_level <= depth
		do
			Result := open_path.i_th (a_level)
		end

	offset (a_level: INTEGER): INTEGER
			-- Items of the drop-down at `a_level` scrolled out above the top of its box; for
			-- the bar (level 1), entries scrolled out to the left
		require
			valid_level: a_level >= 1 and a_level <= depth
		do
			Result := open_offsets.i_th (a_level)
		ensure
			non_negative: Result >= 0
		end

	bar_offset: INTEGER
			-- Bar entries scrolled out to the left (0 when closed)
		do
			if depth > 0 then
				Result := open_offsets.first
			end
		ensure
			non_negative: Result >= 0
			zero_when_closed: not is_open implies Result = 0
		end

	parent_at (a_level: INTEGER): MENU_ITEM
			-- Item whose sub-menu is shown at `a_level`: `root` for the bar (level 1), else the
			-- item highlighted at `a_level` - 1
		require
			valid_level: a_level >= 1 and a_level <= depth.max (1)
		local
			k: INTEGER
		do
			Result := root
			from k := 1 until k >= a_level loop
				Result := Result.child (open_path.i_th (k))
				k := k + 1
			end
		ensure
			has_items_below_bar: a_level > 1 implies Result.has_submenu
		end

	highlighted_item: detachable MENU_ITEM
			-- Item highlighted at the last open level, or Void (closed, or nothing highlighted)
		do
			if depth > 0 and then open_path.last > 0 then
				Result := parent_at (depth).child (open_path.last)
			end
		ensure
			void_when_closed: not is_open implies Result = Void
		end

	chosen_item: detachable MENU_ITEM
			-- Item last chosen by `activate` or `click`, until `clear_chosen`

	chosen: detachable WIDGET_ID
			-- `widget_id` of `chosen_item` (Void when none was chosen or it has no id)
		do
			if attached chosen_item as l_item then
				Result := l_item.widget_id
			end
		ensure
			definition: Result = (if attached chosen_item as c then c.widget_id else Void end)
		end

	menu_id: detachable WIDGET_ID
			-- Id a TUI_MENU registers under the bar row and the drop-downs (below the items),
			-- so a click on the menu's border, a separator or the bar's blank is not "outside";
			-- Void for none

	focus_manager: detachable FOCUS_MANAGER
			-- Focus manager in which a scope is pushed while the menu is open, or Void

	scope_depth: INTEGER
			-- `scope_depth` of `focus_manager` just after the menu's scope was pushed; 0 when
			-- no scope is pushed

feature -- Status report

	is_open: BOOLEAN
			-- Is the menu active (the bar highlighted, perhaps with drop-downs)?
		do
			Result := depth > 0
		ensure
			definition: Result = (depth > 0)
		end

	is_dropped_down: BOOLEAN
			-- Is at least one drop-down shown?
		do
			Result := depth > 1
		ensure
			definition: Result = (depth > 1)
		end

	is_scope_innermost: BOOLEAN
			-- Can the menu close now: no scope pushed, or the menu's scope is still the
			-- innermost scope of `focus_manager`?
		do
			Result := scope_depth = 0 or else (attached focus_manager as f and then f.scope_depth = scope_depth)
		end

	has_valid_offsets: BOOLEAN
			-- Is there one offset per open level, each below the number of items (or bar
			-- entries) of its level?
		local
			k: INTEGER
		do
			Result := open_offsets.count = open_path.count
			from k := 1 until not Result or k > open_offsets.count loop
				Result := open_offsets.i_th (k) >= 0 and open_offsets.i_th (k) < parent_at (k).count
				k := k + 1
			end
		end

	is_valid_path (a_path: ARRAYED_LIST [INTEGER]): BOOLEAN
			-- Is `a_path` an open path for the current items (see the class note)?
		require
			path_not_void: a_path /= Void
		local
			k: INTEGER
			l_parent, l_item: MENU_ITEM
		do
			Result := True
			l_parent := root
			from k := 1 until not Result or k > a_path.count loop
				if a_path.i_th (k) = 0 then
					Result := k = a_path.count and k > 1
				elseif a_path.i_th (k) < 0 or a_path.i_th (k) > l_parent.count then
					Result := False
				else
					l_item := l_parent.child (a_path.i_th (k))
					Result := l_item.is_selectable and (k < a_path.count implies l_item.has_submenu)
					l_parent := l_item
				end
				k := k + 1
			end
		end

	entry_with_initial (a_char: CHARACTER_32): INTEGER
			-- Index of the first selectable bar entry whose label starts with `a_char` (case is
			-- ignored, leading blanks skipped), 0 if none: for Alt+letter
		local
			i: INTEGER
			l_text: STRING_32
		do
			from i := 1 until Result > 0 or i > count loop
				l_text := entry (i).label.to_plain_string
				l_text.left_adjust
				if entry (i).is_selectable and then not l_text.is_empty
					and then l_text [1].as_lower = a_char.as_lower
				then
					Result := i
				end
				i := i + 1
			end
		ensure
			none_or_selectable: Result = 0 or else entry (Result).is_selectable
		end

	handles (a_hit: detachable WIDGET_ID): BOOLEAN
			-- Does `click` act on a click that hit `a_hit`: the menu is open (a click anywhere
			-- is the menu's), or `a_hit` is `menu_id` or a bar entry's id?
		do
			Result := is_open or else (attached a_hit as l_id and then (l_id ~ menu_id or root.index_of_id (l_id) > 0))
		ensure
			open_takes_all: is_open implies Result
		end

	shown_level_of (a_id: WIDGET_ID): INTEGER
			-- First level, from the bar inwards, whose shown items include one with `widget_id`
			-- `a_id`; 0 if none
		require
			id_not_void: a_id /= Void
		local
			k: INTEGER
		do
			from k := 1 until Result > 0 or k > depth.max (1) loop
				if parent_at (k).index_of_id (a_id) > 0 then
					Result := k
				end
				k := k + 1
			end
		ensure
			in_range: Result >= 0 and Result <= depth.max (1)
		end

feature -- Element change

	set_items (a_items: ITERABLE [MENU_ITEM])
			-- Make `a_items` the bar entries and close the menu (popping its focus scope).
			-- `chosen_item` is kept.
		require
			items_not_void: a_items /= Void
			scope_innermost: is_scope_innermost
		do
			close
			create root.make_submenu ("", a_items)
		ensure
			closed: not is_open
			chosen_kept: chosen_item = old chosen_item
		end

	set_menu_id (a_id: detachable WIDGET_ID)
			-- Register the bar row and the drop-downs under `a_id` (Void: not at all).
		do
			menu_id := a_id
		ensure
			menu_id_set: menu_id = a_id
		end

	set_focus_manager (a_focus: detachable FOCUS_MANAGER)
			-- Push a scope on `a_focus` while the menu is open (Void: no scope).
		require
			closed: not is_open
		do
			focus_manager := a_focus
		ensure
			focus_manager_set: focus_manager = a_focus
		end

	clear_chosen
			-- Forget `chosen_item`.
		do
			chosen_item := Void
		ensure
			cleared: chosen_item = Void and chosen = Void
		end

	keep_highlight_visible (a_level: INTEGER; a_rows: INTEGER)
			-- Scroll the drop-down at `a_level`, whose box shows `a_rows` items, so that its
			-- highlighted item (if any) is one of them, and no blank is left below its last
			-- item. TUI_MENU calls this while rendering.
		require
			drop_down_level: a_level >= 2 and a_level <= depth
			non_negative_rows: a_rows >= 0
		local
			l_offset, l_selected: INTEGER
		do
			if a_rows > 0 then
				l_offset := open_offsets.i_th (a_level)
				l_selected := open_path.i_th (a_level)
				if l_selected > 0 then
					if l_selected <= l_offset then
						l_offset := l_selected - 1
					elseif l_selected > l_offset + a_rows then
						l_offset := l_selected - a_rows
					end
				end
				l_offset := l_offset.min ((parent_at (a_level).count - a_rows).max (0))
				open_offsets.put_i_th (l_offset, a_level)
			end
		ensure
			path_kept: path ~ old path
			highlight_shown: (a_rows > 0 and selected (a_level) > 0) implies
				(selected (a_level) > offset (a_level) and selected (a_level) <= offset (a_level) + a_rows)
			no_blank_tail: a_rows > 0 implies offset (a_level) <= (parent_at (a_level).count - a_rows).max (0)
		end

	scroll_bar (a_offset: INTEGER)
			-- Scroll `a_offset` bar entries out to the left. TUI_MENU calls this while rendering,
			-- so the highlighted entry is shown.
		require
			open: is_open
			valid_offset: a_offset >= 0 and a_offset < count
		do
			open_offsets.put_i_th (a_offset, 1)
		ensure
			scrolled: bar_offset = a_offset
			path_kept: path ~ old path
		end

feature -- Fluent Builders

	with_menu_id (a_id: detachable WIDGET_ID): like Current
			-- Copy of Current with `menu_id` `a_id` (for setting up: a closed state only, so
			-- that no two states own one focus scope).
		require
			closed: not is_open
		do
			Result := twin
			Result.set_menu_id (a_id)
		ensure
			result_not_void: Result /= Void
			menu_id_set: Result.menu_id = a_id
		end

feature -- Navigation

	open
			-- Highlight the first selectable bar entry and open its drop-down with its first
			-- selectable item highlighted (F10). Nothing happens when no entry is selectable.
		local
			i: INTEGER
		do
			i := root.first_selectable
			if i > 0 then
				open_entry (i)
			end
		ensure
			opened: root.first_selectable > 0 implies (is_open and selected (1) = root.first_selectable)
			closed_without_entries: root.first_selectable = 0 implies depth = old depth
		end

	open_entry (i: INTEGER)
			-- Highlight bar entry `i` and open its drop-down (if it has one) with its first
			-- selectable item highlighted (Alt+letter). Pushes the focus scope if the menu
			-- was closed.
		require
			valid_index: i >= 1 and i <= count
			selectable: entry (i).is_selectable
		do
			go_to_entry (i, True, True)
		ensure
			open: is_open
			entry_highlighted: selected (1) = i
			dropped_down: entry (i).has_submenu implies (depth = 2 and selected (2) = entry (i).first_selectable)
		end

	close
			-- Close every level (pops the focus scope).
		require
			scope_innermost: is_scope_innermost
		do
			clear_path
			end_scope
		ensure
			closed: not is_open
			no_scope: scope_depth = 0
		end

	close_level
			-- Close the innermost level (Esc): a sub-menu, then the drop-down, then the bar.
		require
			scope_innermost: is_scope_innermost
		do
			if depth <= 1 then
				close
			else
				pop_level
			end
		ensure
			one_level_less: old depth > 0 implies depth = old depth - 1
		end

	move_down
			-- Highlight the next selectable item of the innermost drop-down (wrapping round);
			-- on the bar, open the entry's drop-down at its first selectable item.
		do
			if depth = 1 then
				if attached highlighted_item as l_entry and then l_entry.has_submenu then
					push_level (l_entry.first_selectable)
				end
			elseif depth > 1 then
				open_path.put_i_th (parent_at (depth).next_selectable (open_path.last), depth)
			end
		ensure
			same_open_state: is_open = old is_open
		end

	move_up
			-- Highlight the previous selectable item of the innermost drop-down (wrapping
			-- round); on the bar, open the entry's drop-down at its last selectable item.
		do
			if depth = 1 then
				if attached highlighted_item as l_entry and then l_entry.has_submenu then
					push_level (l_entry.last_selectable)
				end
			elseif depth > 1 then
				open_path.put_i_th (parent_at (depth).previous_selectable (open_path.last), depth)
			end
		ensure
			same_open_state: is_open = old is_open
		end

	move_right
			-- Open the highlighted item's sub-menu; else highlight the next selectable bar entry
			-- (wrapping round), with its drop-down open if a drop-down was open.
		do
			if depth > 1 and then attached highlighted_item as l_item and then l_item.has_submenu then
				push_level (l_item.first_selectable)
			elseif depth > 0 then
				go_to_entry (root.next_selectable (open_path.first), depth > 1, True)
			end
		ensure
			same_open_state: is_open = old is_open
		end

	move_left
			-- Leave the innermost sub-menu; else highlight the previous selectable bar entry
			-- (wrapping round), with its drop-down open if a drop-down was open.
		do
			if depth > 2 then
				pop_level
			elseif depth > 0 then
				go_to_entry (root.previous_selectable (open_path.first), depth > 1, True)
			end
		ensure
			same_open_state: is_open = old is_open
		end

	activate
			-- Enter: open the highlighted item's sub-menu (or the bar entry's drop-down), or
			-- choose the highlighted leaf (`chosen_item`) and close the menu.
		require
			scope_innermost: is_scope_innermost
		do
			if attached highlighted_item as l_item then
				if l_item.has_submenu then
					push_level (l_item.first_selectable)
				else
					choose (l_item)
				end
			end
		ensure
			chose_leaf: (attached old highlighted_item as h and then not h.has_submenu)
				implies (chosen_item = old highlighted_item and not is_open)
			opened_submenu: (attached old highlighted_item as h and then h.has_submenu) implies depth = old depth + 1
		end

	click (a_hit: detachable WIDGET_ID)
			-- Act on a click that hit `a_hit` (see the class note): a bar entry opens or closes
			-- its drop-down, an item with a sub-menu opens it, a leaf is chosen, a disabled item
			-- and `menu_id` do nothing, anything else closes the menu.
		require
			scope_innermost: is_scope_innermost
		local
			l_level, i: INTEGER
			l_item: MENU_ITEM
		do
			if attached a_hit as l_id and then l_id ~ menu_id then
					-- The menu's own surface: nothing
			elseif attached a_hit as l_id and then shown_level_of (l_id) > 0 then
				l_level := shown_level_of (l_id)
				i := parent_at (l_level).index_of_id (l_id)
				l_item := parent_at (l_level).child (i)
				if l_item.is_selectable then
					if l_level = 1 then
						if is_dropped_down and then open_path.first = i then
							close
						elseif l_item.has_submenu then
							go_to_entry (i, True, False)
						else
							choose (l_item)
						end
					else
						from until depth <= l_level loop
							pop_level
						end
						open_path.put_i_th (i, l_level)
						if l_item.has_submenu then
							push_level (0)
						else
							choose (l_item)
						end
					end
				end
			elseif is_open then
				close
			end
		end

feature -- Duplication

	copy (a_other: like Current)
			-- Copy `a_other`, with an open path and offsets of its own. The focus scope stays
			-- with `a_other`: when `a_other` has one pushed, the copy has no focus manager (it
			-- would pop a scope it does not own); give it one with `set_focus_manager` once
			-- it is closed.
		do
			if a_other /= Current then
				standard_copy (a_other)
				open_path := a_other.open_path.twin
				open_offsets := a_other.open_offsets.twin
				if scope_depth > 0 then
					focus_manager := Void
					scope_depth := 0
				end
			end
		ensure then
			same_path: path ~ a_other.path
			scope_not_taken: (a_other /= Current and a_other.scope_depth > 0) implies (scope_depth = 0 and focus_manager = Void)
		end

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Same items, open path, offsets, menu id and chosen item? The focus manager and
			-- its scope are not part of the value (a copy does not take the scope, `copy`).
		do
			if a_other = Current then
				Result := True
			else
				Result := root ~ a_other.root
					and open_path ~ a_other.open_path
					and open_offsets ~ a_other.open_offsets
					and menu_id ~ a_other.menu_id
					and chosen_item = a_other.chosen_item
			end
		end

feature {MENU_STATE} -- Implementation

	open_path: ARRAYED_LIST [INTEGER]
			-- The open path (see the class note)

	open_offsets: ARRAYED_LIST [INTEGER]
			-- `offset` of each open level

feature {NONE} -- Implementation

	go_to_entry (i: INTEGER; a_drop_down, a_highlight_first: BOOLEAN)
			-- Highlight bar entry `i` (0: none selectable, nothing changes), with its drop-down
			-- open when `a_drop_down` and it has one, its first selectable item highlighted when
			-- `a_highlight_first` (else none). Pushes the focus scope if the menu was closed.
		require
			valid_index: i >= 0 and i <= count
			selectable: i > 0 implies entry (i).is_selectable
		local
			l_bar: INTEGER
		do
			if i > 0 then
				l_bar := bar_offset
				begin_scope
				clear_path
				push_level (i)
				open_offsets.put_i_th (l_bar, 1)
				if a_drop_down and entry (i).has_submenu then
					if a_highlight_first then
						push_level (entry (i).first_selectable)
					else
						push_level (0)
					end
				end
			end
		ensure
			entry_highlighted: i > 0 implies (is_open and selected (1) = i)
			bar_scroll_kept: i > 0 implies bar_offset = old bar_offset
		end

	push_level (i: INTEGER)
			-- Open one more level with item `i` highlighted, scrolled to the top.
		do
			open_path.extend (i)
			open_offsets.extend (0)
		ensure
			one_more: depth = old depth + 1
			highlighted: open_path.last = i
			at_top: open_offsets.last = 0
		end

	pop_level
			-- Close the innermost level.
		require
			open: depth > 0
		do
			open_path.finish
			open_path.remove
			open_offsets.finish
			open_offsets.remove
		ensure
			one_less: depth = old depth - 1
		end

	clear_path
			-- Close every level (the focus scope is left as it is).
		do
			open_path.wipe_out
			open_offsets.wipe_out
		ensure
			closed: depth = 0
		end

	choose (a_item: MENU_ITEM)
			-- Make `a_item` the `chosen_item` and close the menu.
		require
			item_not_void: a_item /= Void
			scope_innermost: is_scope_innermost
		do
			chosen_item := a_item
			close
		ensure
			chosen: chosen_item = a_item
			closed: not is_open
		end

	begin_scope
			-- Push a scope on `focus_manager` when the menu is closed and has one.
		do
			if not is_open and scope_depth = 0 and then attached focus_manager as f then
				f.push_scope
				scope_depth := f.scope_depth
			end
		end

	end_scope
			-- Pop the scope pushed by `begin_scope`, if any.
		require
			scope_innermost: is_scope_innermost
		do
			if scope_depth > 0 and then attached focus_manager as f then
				f.pop_scope
			end
			scope_depth := 0
		ensure
			no_scope: scope_depth = 0
		end

invariant
	root_not_void: root /= Void
	open_path_not_void: open_path /= Void
	valid_path: is_valid_path (open_path)
	open_offsets_not_void: open_offsets /= Void
	valid_offsets: has_valid_offsets
	scope_only_while_open: scope_depth > 0 implies (is_open and focus_manager /= Void)
	scope_while_open: (is_open and focus_manager /= Void) implies scope_depth > 1

end
