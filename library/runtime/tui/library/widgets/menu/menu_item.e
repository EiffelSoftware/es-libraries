note
	description: "[
		One entry of a menu (P2 W4): a menu bar entry, a drop-down item, a separator or a
		sub-menu. Ratatui has no menu (the `tui-menu` crate's `MenuItem` is the model).

		    create {MENU_ITEM}.make ("Open").with_shortcut ("Ctrl+O").with_id (id_open)
		    create {MENU_ITEM}.make_separator
		    create {MENU_ITEM}.make_submenu ("Recent", <<recent_1, recent_2>>)
		    (create {MENU_ITEM}.make ("Redo")).with_enabled (False)

		  * `label`: the text drawn; `shortcut_text`: drawn right-aligned after it, only text
		    (the application binds the key itself).
		  * `widget_id`: what the application receives when the item is chosen
		    ({MENU_STATE}.chosen), and the id its row registers in the frame's hit map. An item
		    without an id can be chosen with the keys but is not clickable.
		  * `is_enabled`: a disabled item is drawn dimmed and is skipped by the keys; a click
		    on it does nothing. A separator is never selectable either.
		  * Sub-menu: `make_submenu` / `with_submenu`; the children are reached by index
		    (`child`, `count`).

		Immutable: an item has no public setters, and every `with_*` builder returns a new
		item, so a MENU_STATE's open path can never be made invalid behind its back by
		changing an item it holds (its invariant). Build a changed menu and give it to
		{MENU_STATE}.set_items.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	MENU_ITEM

inherit
	ANY
		redefine
			is_equal
		end

create
	make,
	make_with_line,
	make_submenu,
	make_separator

feature {NONE} -- Initialization

	make (a_label: READABLE_STRING_GENERAL)
			-- Enabled item labelled with the plain text `a_label`, no shortcut, no id.
		require
			label_not_void: a_label /= Void
		do
			make_with_line (create {TEXT_LINE}.make_raw (a_label))
		ensure
			enabled: is_enabled
			not_separator: not is_separator
			no_submenu: count = 0
			label_set: label.to_plain_string.same_string_general (a_label)
		end

	make_with_line (a_label: TEXT_LINE)
			-- Enabled item with the styled label `a_label` (a copy is kept).
		require
			label_not_void: a_label /= Void
		do
			label_line := a_label.twin
			is_enabled := True
			create children.make (0)
		ensure
			enabled: is_enabled
			not_separator: not is_separator
			no_submenu: count = 0
			label_set: label ~ a_label
		end

	make_submenu (a_label: READABLE_STRING_GENERAL; a_items: ITERABLE [MENU_ITEM])
			-- Enabled item labelled `a_label` opening the sub-menu `a_items`.
		require
			label_not_void: a_label /= Void
			items_not_void: a_items /= Void
		do
			make (a_label)
			set_children (a_items)
		ensure
			enabled: is_enabled
			not_separator: not is_separator
		end

	make_separator
			-- A separator row: no label, no id, never selectable.
		do
			create label_line.make_empty
			create children.make (0)
			is_separator := True
			is_enabled := True
		ensure
			separator: is_separator
			not_selectable: not is_selectable
			empty_label: label.is_empty
		end

feature -- Access

	label: TEXT_LINE
			-- A new copy of the text drawn for the item (changing it does not change the item)
		do
			Result := label_line.twin
		ensure
			copy: Result ~ label_line and Result /= label_line
		end

	shortcut_text: detachable IMMUTABLE_STRING_32
			-- Text drawn right-aligned after the label (not bound to a key), or Void

	widget_id: detachable WIDGET_ID
			-- Id received when the item is chosen and registered for its row, or Void

	count: INTEGER
			-- Number of items in the sub-menu (0: no sub-menu)
		do
			Result := children.count
		ensure
			non_negative: Result >= 0
		end

	child (i: INTEGER): MENU_ITEM
			-- `i`-th item of the sub-menu
		require
			valid_index: i >= 1 and i <= count
		do
			Result := children.i_th (i)
		end

	submenu: ARRAYED_LIST [MENU_ITEM]
			-- A new list of the sub-menu's items (empty without a sub-menu)
		do
			create Result.make (children.count)
			Result.append (children)
		ensure
			same_count: Result.count = count
		end

	label_width: INTEGER
			-- Columns of `label`
		do
			Result := label_line.width.to_integer_32
		ensure
			non_negative: Result >= 0
		end

	shortcut_width: INTEGER
			-- Columns of `shortcut_text` (0 without one)
		do
			if attached shortcut_text as l_text then
				Result := {UNICODE_WIDTH}.string_width (l_text).to_integer_32
			end
		ensure
			non_negative: Result >= 0
		end

feature -- Status report

	is_enabled: BOOLEAN
			-- Can the item be selected and chosen (when not a separator)?

	is_separator: BOOLEAN
			-- Is the item a separator row?

	has_submenu: BOOLEAN
			-- Does the item open a sub-menu?
		do
			Result := count > 0
		ensure
			definition: Result = (count > 0)
		end

	is_selectable: BOOLEAN
			-- Can the keys or the mouse highlight the item: enabled and not a separator?
		do
			Result := is_enabled and not is_separator
		ensure
			definition: Result = (is_enabled and not is_separator)
		end

	is_valid_shortcut (a_text: READABLE_STRING_GENERAL): BOOLEAN
			-- Can `a_text` be a shortcut text: no C0 or C1 control character and no DEL?
		local
			i: INTEGER
			c: NATURAL_32
		do
			Result := True
			from i := 1 until not Result or i > a_text.count loop
				c := a_text.code (i)
				Result := c >= 32 and not (c >= 127 and c <= 159)
				i := i + 1
			end
		ensure
			instance_free: class
		end

feature -- Sub-menu navigation

	first_selectable: INTEGER
			-- Index of the first selectable item of the sub-menu, 0 if none
		do
			Result := next_selectable (0)
		ensure
			none_or_selectable: Result = 0 or else child (Result).is_selectable
		end

	last_selectable: INTEGER
			-- Index of the last selectable item of the sub-menu, 0 if none
		do
			Result := previous_selectable (0)
		ensure
			none_or_selectable: Result = 0 or else child (Result).is_selectable
		end

	next_selectable (i: INTEGER): INTEGER
			-- Index of the first selectable item after `i`, wrapping round to the start; `i`
			-- itself when it is the only one; 0 when none is selectable. `i` = 0 starts before
			-- the first item.
		require
			valid_index: i >= 0 and i <= count
		local
			k, n: INTEGER
		do
			from
				n := 1
			until
				Result > 0 or n > count
			loop
				k := ((i - 1 + n) \\ count) + 1
				if children.i_th (k).is_selectable then
					Result := k
				end
				n := n + 1
			end
		ensure
			none_or_selectable: Result = 0 or else child (Result).is_selectable
			none_only_without_selectable: Result = 0 implies across children as c all not c.is_selectable end
		end

	previous_selectable (i: INTEGER): INTEGER
			-- Index of the first selectable item before `i`, wrapping round to the end; `i`
			-- itself when it is the only one; 0 when none is selectable. `i` = 0 starts after
			-- the last item.
		require
			valid_index: i >= 0 and i <= count
		local
			k, n, l_from: INTEGER
		do
			if i = 0 then
				l_from := count + 1
			else
				l_from := i
			end
			from
				n := 1
			until
				Result > 0 or n > count
			loop
				k := ((l_from - 1 - n) \\ count + count) \\ count + 1
				if children.i_th (k).is_selectable then
					Result := k
				end
				n := n + 1
			end
		ensure
			none_or_selectable: Result = 0 or else child (Result).is_selectable
			none_only_without_selectable: Result = 0 implies across children as c all not c.is_selectable end
		end

	index_of_id (a_id: WIDGET_ID): INTEGER
			-- Index of the first item of the sub-menu whose `widget_id` is `a_id`, 0 if none
		require
			id_not_void: a_id /= Void
		local
			i: INTEGER
		do
			from i := 1 until Result > 0 or i > count loop
				if children.i_th (i).widget_id ~ a_id then
					Result := i
				end
				i := i + 1
			end
		ensure
			none_or_match: Result = 0 or else child (Result).widget_id ~ a_id
		end

	has_id (a_id: WIDGET_ID): BOOLEAN
			-- Is `a_id` the `widget_id` of an item of the sub-menu, at any depth?
		require
			id_not_void: a_id /= Void
		do
			Result := across children as c some c.widget_id ~ a_id or else c.has_id (a_id) end
		end

feature -- Fluent Builders

	with_label (a_text: READABLE_STRING_GENERAL): like Current
			-- Copy of Current labelled with the plain text `a_text`.
		require
			text_not_void: a_text /= Void
			not_separator: not is_separator
		do
			Result := twin
			Result.set_label (create {TEXT_LINE}.make_raw (a_text))
		ensure
			result_not_void: Result /= Void
			label_set: Result.label.to_plain_string.same_string_general (a_text)
		end

	with_label_line (a_label: TEXT_LINE): like Current
			-- Copy of Current with the styled label `a_label` (a copy is kept).
		require
			label_not_void: a_label /= Void
			not_separator: not is_separator
		do
			Result := twin
			Result.set_label (a_label.twin)
		ensure
			result_not_void: Result /= Void
			label_set: Result.label ~ a_label
		end

	with_shortcut (a_text: detachable READABLE_STRING_GENERAL): like Current
			-- Copy of Current showing the shortcut text `a_text` (Void: none).
		require
			not_separator: not is_separator
			valid_text: attached a_text as t implies is_valid_shortcut (t)
		do
			Result := twin
			if attached a_text as t then
				Result.set_shortcut_text (create {IMMUTABLE_STRING_32}.make_from_string_general (t))
			else
				Result.set_shortcut_text (Void)
			end
		ensure
			result_not_void: Result /= Void
			shortcut_set: attached a_text as t implies (attached Result.shortcut_text as r and then r.same_string_general (t))
			no_shortcut: a_text = Void implies Result.shortcut_text = Void
		end

	with_id (a_id: detachable WIDGET_ID): like Current
			-- Copy of Current with `widget_id` `a_id` (Void: none).
		require
			not_separator: not is_separator
		do
			Result := twin
			Result.set_widget_id (a_id)
		ensure
			result_not_void: Result /= Void
			id_set: Result.widget_id = a_id
		end

	with_enabled (a_enabled: BOOLEAN): like Current
			-- Copy of Current enabled (True) or disabled.
		do
			Result := twin
			Result.set_enabled (a_enabled)
		ensure
			result_not_void: Result /= Void
			enabled_set: Result.is_enabled = a_enabled
		end

	with_submenu (a_items: ITERABLE [MENU_ITEM]): like Current
			-- Copy of Current opening the sub-menu `a_items` (empty: no sub-menu).
		require
			items_not_void: a_items /= Void
			not_separator: not is_separator
		do
			Result := twin
			Result.set_children (a_items)
		ensure
			result_not_void: Result /= Void
		end

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Same label, shortcut, id, flags and sub-menu (compared item by item)?
		local
			i: INTEGER
		do
			if a_other = Current then
				Result := True
			else
				Result := is_enabled = a_other.is_enabled
					and is_separator = a_other.is_separator
					and label_line ~ a_other.label_line
					and widget_id ~ a_other.widget_id
					and count = a_other.count
				if Result then
					if attached shortcut_text as s then
						Result := attached a_other.shortcut_text as o and then s.same_string (o)
					else
						Result := a_other.shortcut_text = Void
					end
				end
				from i := 1 until not Result or i > count loop
					Result := child (i) ~ a_other.child (i)
					i := i + 1
				end
			end
		end

feature {MENU_ITEM} -- Element change (builders only: items are immutable)

	set_label (a_label: TEXT_LINE)
			-- Set `label` to `a_label`.
		require
			label_not_void: a_label /= Void
		do
			label_line := a_label
		ensure
			label_set: label_line = a_label
		end

	set_shortcut_text (a_text: detachable IMMUTABLE_STRING_32)
			-- Set `shortcut_text` to `a_text`.
		do
			shortcut_text := a_text
		ensure
			shortcut_set: shortcut_text = a_text
		end

	set_widget_id (a_id: detachable WIDGET_ID)
			-- Set `widget_id` to `a_id`.
		do
			widget_id := a_id
		ensure
			id_set: widget_id = a_id
		end

	set_enabled (a_enabled: BOOLEAN)
			-- Set `is_enabled` to `a_enabled`.
		do
			is_enabled := a_enabled
		ensure
			enabled_set: is_enabled = a_enabled
		end

	set_children (a_items: ITERABLE [MENU_ITEM])
			-- Make `a_items` the sub-menu, in a list of its own.
		require
			items_not_void: a_items /= Void
		do
			create children.make (4)
			across a_items as c loop
				children.extend (c)
			end
		end

feature {MENU_ITEM, TUI_MENU} -- Implementation

	label_line: TEXT_LINE
			-- Text drawn for the item, held by no other object

feature {MENU_ITEM} -- Implementation

	children: ARRAYED_LIST [MENU_ITEM]
			-- Items of the sub-menu, in a list no other object holds

invariant
	label_line_not_void: label_line /= Void
	children_not_void: children /= Void
	separator_is_bare: is_separator implies (label_line.is_empty and count = 0 and widget_id = Void and shortcut_text = Void)
	valid_shortcut: attached shortcut_text as s implies is_valid_shortcut (s)

end
