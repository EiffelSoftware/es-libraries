note
	description: "[
		A menu bar with drop-down menus (P2 W4), drawn from a MENU_STATE. Ratatui has no menu;
		the `tui-menu` crate (`Menu` + `MenuState`) is the model. The state holds the items
		and the open path; the widget holds only the look, and reads no events (the keys and
		the mouse go through the state: see MENU_STATE's note).

		    a_frame.render_widget (body, body_area)          -- everything else first
		    a_frame.render_stateful_widget (create {TUI_MENU}, a_frame.area, menu)   -- last

		Render the menu last: its drop-downs are overlays that cover what was drawn before
		them. (Clicks are safe whatever the order: while the menu is open its hit regions
		are an overlay, see below, so nothing registered after it can be clicked.)

		Layout:
		  * The bar is the top row of the area: each entry is its label with one blank on
		    each side (" File  Edit "), from the left; entries past the right edge are cut or
		    left out. The whole bar row is drawn (blanks between and after the entries).
		    While the menu is open the bar scrolls sideways to show the highlighted entry
		    whole ({MENU_STATE}.bar_offset, set while rendering), with `Scroll_left_symbol` in
		    its first column when entries are scrolled out to the left and
		    `Scroll_right_symbol` in its last column when some label runs past the right edge.
		  * While the state is open, each open level (`{MENU_STATE}.depth` - 1 of them) is a
		    drop-down: TUI_CLEAR, then a TUI_BLOCK with `border_type`, `menu_style` and
		    `shadow`. Its rows: one blank, the label, then (when some item of that drop-down
		    has a shortcut) two blanks and the shortcut right-aligned in the widest shortcut's
		    column, then (when some item has a sub-menu) a blank and `submenu_symbol` on the
		    items that have one, and one blank. A separator is a TUI_DIVIDER row
		    (`separator_line_set`) across the inside of the box.
		  * The drop-downs are overlays placed anywhere in the buffer (the frame), not only in
		    the area, with OVERLAY_PLACEMENT: an entry's drop-down below the entry, starting at
		    its left column; a sub-menu right of its item's row, its top border on that row.
		    With a `shadow`, each box is placed with room for its shadow (the box and its
		    shadow together are what flips, shifts and is cut), so a shadow never falls on
		    the bar entry or the row a drop-down belongs to.
		    *Decided* for the edges: a box flips to the other side when it fits there whole
		    (a sub-menu next to the right edge opens to the left; a bar at the bottom of the
		    screen opens upwards), is shifted back along the edge when it would run past it,
		    and when it fits on neither side it goes where there is more room and is cut (the
		    box stays closed). A box cut short shows a window of its items that scrolls to
		    keep the highlighted one in view ({MENU_STATE}.keep_highlight_visible, called while
		    rendering), with `Scroll_up_symbol` / `Scroll_down_symbol` on its top / bottom
		    border when items are scrolled out above / below. Items scrolled out are neither
		    drawn nor clickable, but the keys reach every one of them.

		Style: `bar_style` is patched over the bar row and `menu_style` over each drop-down
		(the block's style). The highlighted item of each level (the trail of the open path)
		gets `highlight_style` (reversed by default) patched over its row; a disabled entry or
		item gets `disabled_style` (dim by default). Labels are drawn in the style of their
		row's first cell after that, with the label's own styles patched on top.

		Hit regions (FRAME.render_stateful_widget registers them; the menu is a
		HIT_CONTAINER with state): while the state is open, they are an overlay
		(FRAME.begin_overlay .. end_overlay): first a blocker over the whole frame, so clicks
		on the background (under the drop-downs or outside them) hit nothing, as a modal
		TUI_POPUP does; the menu's own regions are not clipped by a modal popup rendered
		before it (the open menu is above it, its focus scope innermost); and every region
		registered after the menu hits nothing. Then `{MENU_STATE}.menu_id` (or a blocker when it
		is Void) under the bar row, each bar entry with a `widget_id`, and for each drop-down
		in turn its box (`menu_id` or a blocker) and its items with a `widget_id` (disabled
		items too: a click on one does nothing). A sub-menu's box hides the items of the
		drop-down under it.

		Geometry queries take the area the bar was given and `a_screen`, the area the
		drop-downs may cover (the buffer's or the frame's area), as rendering does.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_MENU

inherit
	STATEFUL_WIDGET [MENU_STATE]
		redefine
			default_create,
			is_equal
		end

	HIT_CONTAINER
		redefine
			default_create,
			is_equal,
			register_child_hits_with_state
		end

create
	default_create,
	make

feature {NONE} -- Initialization

	default_create
			-- Menu with plain borders, no shadow, plain separators, reversed highlight, dim
			-- disabled items and U+25B8 before sub-menus.
		do
			create bar_style
			create menu_style
			highlight_style := (create {STYLE}).with_reverse
			disabled_style := (create {STYLE}).with_dim
			border_type := {BORDER_TYPE}.plain
			separator_line_set := {DIVIDER_LINE_SET}.plain
			create submenu_symbol.make_from_string_general ({STRING_32} "%/0x25B8/")
		ensure then
			plain_borders: border_type = {BORDER_TYPE}.plain
			no_shadow: shadow = Void
			plain_separators: separator_line_set = {DIVIDER_LINE_SET}.plain
		end

	make
			-- Synonym for `default_create`.
		do
			default_create
		end

feature -- Access

	bar_style: STYLE
			-- Style patched over the bar row

	menu_style: STYLE
			-- Style of each drop-down's box (patched over the cleared box, border included)

	highlight_style: STYLE
			-- Style patched over the highlighted entry and items

	disabled_style: STYLE
			-- Style patched over disabled entries and items

	border_type: NATURAL_8
			-- Border of the drop-downs ({BORDER_TYPE})

	shadow: detachable SHADOW
			-- Shadow of each drop-down, or Void

	separator_line_set: NATURAL_8
			-- Line of a separator row ({DIVIDER_LINE_SET})

	submenu_symbol: IMMUTABLE_STRING_32
			-- Drawn at the end of an item that opens a sub-menu

	Scroll_up_symbol: CHARACTER_32 = '%/0x25B2/'
			-- Drawn on the top border of a drop-down with items scrolled out above

	Scroll_down_symbol: CHARACTER_32 = '%/0x25BC/'
			-- Drawn on the bottom border of a drop-down with items scrolled out below

	Scroll_left_symbol: CHARACTER_32 = '%/0x25C0/'
			-- Drawn in the bar's first column when entries are scrolled out to the left

	Scroll_right_symbol: CHARACTER_32 = '%/0x25B6/'
			-- Drawn in the bar's last column when a label runs past its right edge

feature -- Status report

	is_valid_symbol (a_symbol: READABLE_STRING_GENERAL): BOOLEAN
			-- Can `a_symbol` be the `submenu_symbol`: not empty, no control character?
		do
			Result := not a_symbol.is_empty and {MENU_ITEM}.is_valid_shortcut (a_symbol)
		ensure
			instance_free: class
		end

feature -- Geometry

	bar_area (a_area: RECT): RECT
			-- The bar: the top row of `a_area` (empty for an empty area)
		require
			area_not_void: a_area /= Void
		do
			if a_area.is_empty then
				create Result.make (a_area.x, a_area.y, 0, 0)
			else
				create Result.make (a_area.x, a_area.y, a_area.width, 1)
			end
		ensure
			result_not_void: Result /= Void
			inside: Result.is_empty or else a_area.contains_rect (Result)
		end

	entry_start (a_area: RECT; a_state: MENU_STATE; i: INTEGER): INTEGER
			-- Column where bar entry `i` starts (its leading blank), before any cut, with
			-- `{MENU_STATE}.bar_offset` entries scrolled out to the left (left of the area for
			-- those)
		require
			area_not_void: a_area /= Void
			state_not_void: a_state /= Void
			valid_index: i >= 1 and i <= a_state.count
		do
			if i > a_state.bar_offset then
				Result := a_area.x.to_integer_32 + entries_width (a_state, a_state.bar_offset + 1, i - 1)
			else
				Result := a_area.x.to_integer_32 - entries_width (a_state, i, a_state.bar_offset)
			end
		ensure
			after_the_area_start: i > a_state.bar_offset implies Result >= a_area.x.to_integer_32
			before_it: i <= a_state.bar_offset implies Result < a_area.x.to_integer_32
		end

	entries_width (a_state: MENU_STATE; a_from, a_to: INTEGER): INTEGER
			-- Columns of bar entries `a_from` .. `a_to` (0 when `a_from` > `a_to`)
		require
			state_not_void: a_state /= Void
			valid_from: a_from >= 1
			valid_to: a_to <= a_state.count
		local
			k: INTEGER
		do
			from k := a_from until k > a_to loop
				Result := Result + entry_width (a_state.entry (k))
				k := k + 1
			end
		ensure
			non_negative: Result >= 0
		end

	entry_width (a_entry: MENU_ITEM): INTEGER
			-- Columns of a bar entry: its label and a blank on each side
		require
			entry_not_void: a_entry /= Void
		do
			Result := a_entry.label_width + 2
		ensure
			definition: Result = a_entry.label_width + 2
		end

	entry_anchor (a_area: RECT; a_state: MENU_STATE; i: INTEGER): RECT
			-- Cells of bar entry `i` before the cut to the area (what its drop-down is placed
			-- against)
		require
			area_not_void: a_area /= Void
			state_not_void: a_state /= Void
			valid_index: i >= 1 and i <= a_state.count
		do
			create Result.make (entry_start (a_area, a_state, i).max (0).min (65535).to_natural_16, a_area.y,
				entry_width (a_state.entry (i)).min (65535).to_natural_16, 1)
		ensure
			result_not_void: Result /= Void
		end

	entry_area (a_area: RECT; a_state: MENU_STATE; i: INTEGER): RECT
			-- Cells of bar entry `i` on the bar, cut to it (empty when the entry is past its
			-- right edge or scrolled out to the left)
		require
			area_not_void: a_area /= Void
			state_not_void: a_state /= Void
			valid_index: i >= 1 and i <= a_state.count
		do
			if i <= a_state.bar_offset then
				create Result.make (a_area.x, a_area.y, 0, 0)
			else
				Result := entry_anchor (a_area, a_state, i).intersection (bar_area (a_area))
			end
		ensure
			result_not_void: Result /= Void
			on_the_bar: Result.is_empty or else bar_area (a_area).contains_rect (Result)
		end

	label_column_width (a_parent: MENU_ITEM): INTEGER
			-- Widest label of the sub-menu of `a_parent`
		require
			parent_not_void: a_parent /= Void
		local
			j: INTEGER
		do
			from j := 1 until j > a_parent.count loop
				Result := Result.max (a_parent.child (j).label_width)
				j := j + 1
			end
		ensure
			non_negative: Result >= 0
		end

	shortcut_column_width (a_parent: MENU_ITEM): INTEGER
			-- Widest shortcut of the sub-menu of `a_parent` (0: none has one)
		require
			parent_not_void: a_parent /= Void
		local
			j: INTEGER
		do
			from j := 1 until j > a_parent.count loop
				Result := Result.max (a_parent.child (j).shortcut_width)
				j := j + 1
			end
		ensure
			non_negative: Result >= 0
		end

	has_submenu_column (a_parent: MENU_ITEM): BOOLEAN
			-- Does some item of the sub-menu of `a_parent` open a sub-menu?
		require
			parent_not_void: a_parent /= Void
		local
			j: INTEGER
		do
			from j := 1 until Result or j > a_parent.count loop
				Result := a_parent.child (j).has_submenu
				j := j + 1
			end
		end

	drop_down_width (a_parent: MENU_ITEM): INTEGER
			-- Columns of the drop-down showing the sub-menu of `a_parent`, borders included,
			-- before any cut (see the class note)
		require
			parent_not_void: a_parent /= Void
		do
			Result := 2 + 1 + label_column_width (a_parent) + 1
			if shortcut_column_width (a_parent) > 0 then
				Result := Result + 2 + shortcut_column_width (a_parent)
			end
			if has_submenu_column (a_parent) then
				Result := Result + 1 + {UNICODE_WIDTH}.string_width (submenu_symbol).to_integer_32
			end
		ensure
			at_least_borders_and_blanks: Result >= 4
		end

	drop_down_height (a_parent: MENU_ITEM): INTEGER
			-- Rows of the drop-down showing the sub-menu of `a_parent`: one per item, and the
			-- two borders
		require
			parent_not_void: a_parent /= Void
		do
			Result := a_parent.count + 2
		ensure
			definition: Result = a_parent.count + 2
		end

	drop_down_area (a_area, a_screen: RECT; a_state: MENU_STATE; a_level: INTEGER): RECT
			-- Box of the drop-down showing open level `a_level` (2 .. depth), placed in
			-- `a_screen` (see the class note)
		require
			area_not_void: a_area /= Void
			screen_not_void: a_screen /= Void
			state_not_void: a_state /= Void
			valid_level: a_level >= 2 and a_level <= a_state.depth
		local
			l_parent: MENU_ITEM
			l_anchor, l_box, l_room: RECT
			l_side: NATURAL_8
			l_dx, l_dy, l_width, l_height, l_x, l_y: INTEGER
		do
			l_parent := a_state.parent_at (a_level)
			if a_level = 2 then
				l_anchor := entry_anchor (a_area, a_state, a_state.selected (1))
				l_side := {OVERLAY_PLACEMENT}.below
			else
					-- The row of the highlighted item, scrolled
				l_box := drop_down_area (a_area, a_screen, a_state, a_level - 1)
				create l_anchor.make (l_box.x, (l_box.y.to_integer_32 + a_state.selected (a_level - 1)
					- a_state.offset (a_level - 1)).max (0).min (65535).to_natural_16, l_box.width, 1)
				l_side := {OVERLAY_PLACEMENT}.right
			end
				-- Placed with room for the shadow, then the box is the part its shadow is not
			if attached shadow as l_shadow then
				l_dx := l_shadow.offset_x.abs
				l_dy := l_shadow.offset_y.abs
			end
			l_room := {OVERLAY_PLACEMENT}.placement (l_anchor, (drop_down_width (l_parent) + l_dx).min (65535).to_natural_16,
				(drop_down_height (l_parent) + l_dy).min (65535).to_natural_16, l_side, a_screen)
			l_width := l_room.width.to_integer_32 - l_dx
			l_height := l_room.height.to_integer_32 - l_dy
			if l_width <= 0 or l_height <= 0 then
				create Result.make (l_room.x, l_room.y, 0, 0)
			else
					-- A shadow up or left of its box: the box is the bottom or right part
				l_x := l_room.x.to_integer_32
				l_y := l_room.y.to_integer_32
				if attached shadow as l_shadow and then l_shadow.offset_x < 0 then
					l_x := l_x + l_dx
				end
				if attached shadow as l_shadow and then l_shadow.offset_y < 0 then
					l_y := l_y + l_dy
				end
				create Result.make (l_x.to_natural_16, l_y.to_natural_16, l_width.to_natural_16, l_height.to_natural_16)
			end
		ensure
			result_not_void: Result /= Void
			inside_screen: Result.is_empty or else a_screen.contains_rect (Result)
		end

	item_area (a_area, a_screen: RECT; a_state: MENU_STATE; a_level, j: INTEGER): RECT
			-- Row of item `j` of open level `a_level` inside its drop-down's borders, with the
			-- level's `offset` scrolled out; empty when the item is scrolled out or the box was
			-- cut before its row
		require
			area_not_void: a_area /= Void
			screen_not_void: a_screen /= Void
			state_not_void: a_state /= Void
			valid_level: a_level >= 2 and a_level <= a_state.depth
			valid_index: j >= 1 and j <= a_state.parent_at (a_level).count
		local
			l_box: RECT
			l_row: INTEGER
		do
			l_box := drop_down_area (a_area, a_screen, a_state, a_level)
			l_row := j - a_state.offset (a_level)
			if l_box.width >= 3 and l_row >= 1 and l_row <= l_box.height.to_integer_32 - 2 then
				create Result.make (l_box.x + 1, l_box.y + l_row.to_natural_16, l_box.width - 2, 1)
			else
				create Result.make (l_box.x, l_box.y, 0, 0)
			end
		ensure
			result_not_void: Result /= Void
			inside_the_box: Result.is_empty or else drop_down_area (a_area, a_screen, a_state, a_level).contains_rect (Result)
			scrolled_out_not_shown: j <= a_state.offset (a_level) implies Result.is_empty
		end

	shown_rows (a_area, a_screen: RECT; a_state: MENU_STATE; a_level: INTEGER): INTEGER
			-- Items the drop-down of open level `a_level` has room for (its box less the borders)
		require
			area_not_void: a_area /= Void
			screen_not_void: a_screen /= Void
			state_not_void: a_state /= Void
			valid_level: a_level >= 2 and a_level <= a_state.depth
		local
			l_box: RECT
		do
			l_box := drop_down_area (a_area, a_screen, a_state, a_level)
			if l_box.width >= 3 then
				Result := (l_box.height.to_integer_32 - 2).max (0)
			end
		ensure
			non_negative: Result >= 0
		end

feature -- Element change

	set_bar_style (a_style: STYLE)
			-- Patch `a_style` over the bar row.
		require
			style_not_void: a_style /= Void
		do
			bar_style := a_style
		ensure
			bar_style_set: bar_style = a_style
		end

	set_menu_style (a_style: STYLE)
			-- Give each drop-down's box the style `a_style`.
		require
			style_not_void: a_style /= Void
		do
			menu_style := a_style
		ensure
			menu_style_set: menu_style = a_style
		end

	set_highlight_style (a_style: STYLE)
			-- Patch `a_style` over the highlighted entry and items.
		require
			style_not_void: a_style /= Void
		do
			highlight_style := a_style
		ensure
			highlight_style_set: highlight_style = a_style
		end

	set_disabled_style (a_style: STYLE)
			-- Patch `a_style` over disabled entries and items.
		require
			style_not_void: a_style /= Void
		do
			disabled_style := a_style
		ensure
			disabled_style_set: disabled_style = a_style
		end

	set_border_type (a_type: NATURAL_8)
			-- Draw the drop-downs' borders as `a_type`.
		require
			valid_type: {BORDER_TYPE}.is_valid (a_type)
		do
			border_type := a_type
		ensure
			border_type_set: border_type = a_type
		end

	set_shadow (a_shadow: detachable SHADOW)
			-- Give each drop-down the shadow `a_shadow` (Void: none).
		do
			shadow := a_shadow
		ensure
			shadow_set: shadow = a_shadow
		end

	set_separator_line_set (a_set: NATURAL_8)
			-- Draw separators with the line `a_set`.
		require
			valid_set: {DIVIDER_LINE_SET}.is_valid (a_set)
		do
			separator_line_set := a_set
		ensure
			separator_line_set_set: separator_line_set = a_set
		end

	set_submenu_symbol (a_symbol: READABLE_STRING_GENERAL)
			-- Draw `a_symbol` at the end of items that open a sub-menu.
		require
			symbol_not_void: a_symbol /= Void
			valid_symbol: is_valid_symbol (a_symbol)
		do
			create submenu_symbol.make_from_string_general (a_symbol)
		ensure
			submenu_symbol_set: submenu_symbol.same_string_general (a_symbol)
		end

feature -- Fluent Builders

	with_bar_style (a_style: STYLE): like Current
			-- Copy of Current with `bar_style` `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_bar_style (a_style)
		ensure
			result_not_void: Result /= Void
			bar_style_set: Result.bar_style = a_style
		end

	with_menu_style (a_style: STYLE): like Current
			-- Copy of Current with `menu_style` `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_menu_style (a_style)
		ensure
			result_not_void: Result /= Void
			menu_style_set: Result.menu_style = a_style
		end

	with_highlight_style (a_style: STYLE): like Current
			-- Copy of Current with `highlight_style` `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_highlight_style (a_style)
		ensure
			result_not_void: Result /= Void
			highlight_style_set: Result.highlight_style = a_style
		end

	with_disabled_style (a_style: STYLE): like Current
			-- Copy of Current with `disabled_style` `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_disabled_style (a_style)
		ensure
			result_not_void: Result /= Void
			disabled_style_set: Result.disabled_style = a_style
		end

	with_border_type (a_type: NATURAL_8): like Current
			-- Copy of Current with `border_type` `a_type`.
		require
			valid_type: {BORDER_TYPE}.is_valid (a_type)
		do
			Result := twin
			Result.set_border_type (a_type)
		ensure
			result_not_void: Result /= Void
			border_type_set: Result.border_type = a_type
		end

	with_shadow (a_shadow: detachable SHADOW): like Current
			-- Copy of Current with `shadow` `a_shadow` (Void: none).
		do
			Result := twin
			Result.set_shadow (a_shadow)
		ensure
			result_not_void: Result /= Void
			shadow_set: Result.shadow = a_shadow
		end

	with_separator_line_set (a_set: NATURAL_8): like Current
			-- Copy of Current with `separator_line_set` `a_set`.
		require
			valid_set: {DIVIDER_LINE_SET}.is_valid (a_set)
		do
			Result := twin
			Result.set_separator_line_set (a_set)
		ensure
			result_not_void: Result /= Void
			separator_line_set_set: Result.separator_line_set = a_set
		end

	with_submenu_symbol (a_symbol: READABLE_STRING_GENERAL): like Current
			-- Copy of Current with `submenu_symbol` `a_symbol`.
		require
			symbol_not_void: a_symbol /= Void
			valid_symbol: is_valid_symbol (a_symbol)
		do
			Result := twin
			Result.set_submenu_symbol (a_symbol)
		ensure
			result_not_void: Result /= Void
			submenu_symbol_set: Result.submenu_symbol.same_string_general (a_symbol)
		end

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Same styles, borders, shadow, separator line and sub-menu symbol?
		do
			if a_other = Current then
				Result := True
			else
				Result := bar_style.is_equal (a_other.bar_style)
					and menu_style.is_equal (a_other.menu_style)
					and highlight_style.is_equal (a_other.highlight_style)
					and disabled_style.is_equal (a_other.disabled_style)
					and border_type = a_other.border_type
					and shadow ~ a_other.shadow
					and separator_line_set = a_other.separator_line_set
					and submenu_symbol.same_string (a_other.submenu_symbol)
			end
		end

feature -- Rendering

	render (a_area: RECT; a_buffer: BUFFER)
			-- Render an empty, closed menu: the bar row only.
		do
			render_stateful (a_area, a_buffer, create {MENU_STATE})
		end

	render_stateful (a_area: RECT; a_buffer: BUFFER; a_state: MENU_STATE)
			-- Draw the bar in the top row of `a_area`, then, while `a_state` is open, each open
			-- drop-down over `a_buffer`, scrolled so its highlighted item shows (see the class
			-- note).
		local
			l_bar, l_entry: RECT
			i, k, c, l_row: INTEGER
		do
			if a_state.is_open then
				fit_bar (a_area, a_state)
			end
			l_bar := bar_area (a_area).intersection (a_buffer.area)
			if not l_bar.is_empty then
				a_buffer.set_style (l_bar, bar_style)
				l_row := l_bar.y.to_integer_32
				from c := l_bar.left.to_integer_32 until c >= l_bar.right.to_integer_32 loop
					a_buffer.put_char (l_row, c, ' ', a_buffer.cell (l_row, c).style.twin)
					c := c + 1
				end
				from i := 1 until i > a_state.count loop
					l_entry := entry_area (a_area, a_state, i).intersection (a_buffer.area)
					if not l_entry.is_empty then
						draw_row (a_buffer, l_entry, a_state.entry (i), entry_start (a_area, a_state, i) + 1,
							a_state.is_open and then a_state.selected (1) = i)
					end
					i := i + 1
				end
				draw_bar_marks (a_area, a_buffer, a_state, l_bar)
			end
			from k := 2 until k > a_state.depth loop
				render_drop_down (a_area, a_buffer, a_state, k)
				k := k + 1
			end
		end

feature {FRAME} -- Hit testing

	register_child_hits (a_area: RECT; a_frame: FRAME)
			-- Nothing: without a state there are no entries (as `render` draws none).
		do
		end

	register_child_hits_with_state (a_area: RECT; a_state: detachable WIDGET_STATE; a_frame: FRAME)
			-- Register the menu's regions for `a_state` (see the class note).
		local
			l_screen, l_rect: RECT
			i, j, k: INTEGER
			l_parent: MENU_ITEM
		do
			if attached {MENU_STATE} a_state as s then
				l_screen := a_frame.area
				if s.is_open then
					a_frame.begin_overlay (l_screen)
				end
				register_surface (a_frame, s, bar_area (a_area).intersection (l_screen))
				from i := 1 until i > s.count loop
					if attached s.entry (i).widget_id as l_id then
						l_rect := entry_area (a_area, s, i).intersection (l_screen)
						if not l_rect.is_empty then
							a_frame.register_hit (l_id, l_rect)
						end
					end
					i := i + 1
				end
				from k := 2 until k > s.depth loop
					register_surface (a_frame, s, drop_down_area (a_area, l_screen, s, k))
					l_parent := s.parent_at (k)
					from j := 1 until j > l_parent.count loop
						if attached l_parent.child (j).widget_id as l_id then
							l_rect := item_area (a_area, l_screen, s, k, j)
							if not l_rect.is_empty then
								a_frame.register_hit (l_id, l_rect)
							end
						end
						j := j + 1
					end
					k := k + 1
				end
				if s.is_open then
					a_frame.end_overlay
				end
			end
		end

feature {NONE} -- Implementation

	register_surface (a_frame: FRAME; a_state: MENU_STATE; a_rect: RECT)
			-- Register `a_rect` (the bar row or a drop-down) under `a_state.menu_id`, or as a
			-- blocker without one.
		require
			frame_not_void: a_frame /= Void
			state_not_void: a_state /= Void
			rect_not_void: a_rect /= Void
		do
			if not a_rect.is_empty then
				if attached a_state.menu_id as l_id then
					a_frame.register_hit (l_id, a_rect)
				else
					a_frame.register_blocker (a_rect)
				end
			end
		end

	render_drop_down (a_area: RECT; a_buffer: BUFFER; a_state: MENU_STATE; a_level: INTEGER)
			-- Draw the drop-down of open level `a_level`: cleared box, block, then its rows.
		require
			valid_level: a_level >= 2 and a_level <= a_state.depth
		local
			l_box, l_row: RECT
			l_parent, l_item: MENU_ITEM
			j, l_label_col, l_shortcut_col, l_col: INTEGER
		do
			a_state.keep_highlight_visible (a_level, shown_rows (a_area, a_buffer.area, a_state, a_level))
			l_box := drop_down_area (a_area, a_buffer.area, a_state, a_level)
			if not l_box.is_empty then
				(create {TUI_CLEAR}).render (l_box, a_buffer)
				(create {TUI_BLOCK}.make).with_border_type (border_type).with_style (menu_style)
					.with_shadow (shadow).render (l_box, a_buffer)
				l_parent := a_state.parent_at (a_level)
				draw_scroll_marks (a_buffer, l_box, a_state.offset (a_level),
					shown_rows (a_area, a_buffer.area, a_state, a_level), l_parent.count)
				l_label_col := label_column_width (l_parent)
				l_shortcut_col := shortcut_column_width (l_parent)
				from j := 1 until j > l_parent.count loop
					l_row := item_area (a_area, a_buffer.area, a_state, a_level, j)
					if not l_row.is_empty then
						l_item := l_parent.child (j)
						if l_item.is_separator then
							(create {TUI_DIVIDER}.make).with_line_set (separator_line_set).render (l_row, a_buffer)
						else
							draw_row (a_buffer, l_row, l_item, l_row.x.to_integer_32 + 1, a_state.selected (a_level) = j)
							l_col := l_row.x.to_integer_32 + 1 + l_label_col
							if attached l_item.shortcut_text as l_text then
								a_buffer.set_string_clipped (l_row.y.to_integer_32,
									l_col + 2 + l_shortcut_col - l_item.shortcut_width, l_text,
									l_row.left.to_integer_32, l_row.right.to_integer_32,
									a_buffer.cell (l_row.y.to_integer_32, l_row.x.to_integer_32).style.twin)
							end
							if l_shortcut_col > 0 then
								l_col := l_col + 2 + l_shortcut_col
							end
							if l_item.has_submenu then
								a_buffer.set_string_clipped (l_row.y.to_integer_32, l_col + 1, submenu_symbol,
									l_row.left.to_integer_32, l_row.right.to_integer_32,
									a_buffer.cell (l_row.y.to_integer_32, l_row.x.to_integer_32).style.twin)
							end
						end
					end
					j := j + 1
				end
			end
		end

	fit_bar (a_area: RECT; a_state: MENU_STATE)
			-- Scroll the bar of open `a_state` so its highlighted entry is shown whole (when it
			-- fits at all), with as many entries left of it as fit.
		require
			area_not_void: a_area /= Void
			open: a_state.is_open
		local
			l_selected, l_offset, l_room: INTEGER
		do
			l_selected := a_state.selected (1)
			l_offset := a_state.bar_offset.min (l_selected - 1)
			l_room := a_area.width.to_integer_32
			from until l_offset >= l_selected - 1 or entries_width (a_state, l_offset + 1, l_selected) <= l_room loop
				l_offset := l_offset + 1
			end
			from until l_offset = 0 or entries_width (a_state, l_offset, l_selected) > l_room loop
				l_offset := l_offset - 1
			end
			a_state.scroll_bar (l_offset)
		ensure
			highlighted_not_scrolled_out: a_state.bar_offset < a_state.selected (1)
		end

	draw_bar_marks (a_area: RECT; a_buffer: BUFFER; a_state: MENU_STATE; a_bar: RECT)
			-- Put `Scroll_left_symbol` in the first column of the bar `a_bar` (inside the
			-- buffer) when entries are scrolled out to the left, and `Scroll_right_symbol` in
			-- its last column when the last entry's label runs past the bar's right edge.
		require
			bar_not_empty: not a_bar.is_empty
		local
			l_row, l_end: INTEGER
		do
			l_row := a_bar.y.to_integer_32
			if a_state.bar_offset > 0 and a_bar.left = a_area.left then
				a_buffer.put_char (l_row, a_bar.left.to_integer_32, Scroll_left_symbol,
					a_buffer.cell (l_row, a_bar.left.to_integer_32).style.twin)
			end
			if a_state.count > 0 then
				l_end := entry_start (a_area, a_state, a_state.count) + 1 + a_state.entry (a_state.count).label_width
				if l_end > a_area.right.to_integer_32 and a_bar.right = a_area.right then
					a_buffer.put_char (l_row, a_bar.right.to_integer_32 - 1, Scroll_right_symbol,
						a_buffer.cell (l_row, a_bar.right.to_integer_32 - 1).style.twin)
				end
			end
		end

	draw_scroll_marks (a_buffer: BUFFER; a_box: RECT; a_offset, a_rows, a_count: INTEGER)
			-- Put `Scroll_up_symbol` on the top border of `a_box` when `a_offset` items are
			-- scrolled out above, and `Scroll_down_symbol` on its bottom border when items are
			-- left below the `a_rows` shown, each in its border cell's style, one column in from
			-- the right corner.
		require
			box_not_void: a_box /= Void
		local
			l_col: INTEGER
		do
			if a_box.width >= 3 and a_box.height >= 2 and a_rows > 0 then
				l_col := a_box.right.to_integer_32 - 2
				if a_offset > 0 and then a_buffer.area.contains_point (l_col.to_natural_16, a_box.y) then
					a_buffer.put_char (a_box.y.to_integer_32, l_col, Scroll_up_symbol,
						a_buffer.cell (a_box.y.to_integer_32, l_col).style.twin)
				end
				if a_offset + a_rows < a_count
					and then a_buffer.area.contains_point (l_col.to_natural_16, a_box.bottom - 1)
				then
					a_buffer.put_char (a_box.bottom.to_integer_32 - 1, l_col, Scroll_down_symbol,
						a_buffer.cell (a_box.bottom.to_integer_32 - 1, l_col).style.twin)
				end
			end
		end

	draw_row (a_buffer: BUFFER; a_row: RECT; a_item: MENU_ITEM; a_label_col: INTEGER; a_highlighted: BOOLEAN)
			-- Patch the highlight or disabled style over `a_row` (inside the buffer), then draw
			-- `a_item`'s label from column `a_label_col`, clipped to `a_row`.
		require
			row_not_empty: not a_row.is_empty
			row_in_buffer: a_buffer.area.contains_rect (a_row)
		local
			l_base: STYLE
		do
			if a_highlighted then
				a_buffer.set_style (a_row, highlight_style)
			elseif not a_item.is_selectable then
				a_buffer.set_style (a_row, disabled_style)
			end
			l_base := a_buffer.cell (a_row.y.to_integer_32, a_row.x.to_integer_32).style.twin
			a_buffer.set_line_clipped (a_row.y.to_integer_32, a_label_col, a_item.label_line, l_base,
				a_row.left.to_integer_32, a_row.right.to_integer_32)
		end

invariant
	bar_style_not_void: bar_style /= Void
	menu_style_not_void: menu_style /= Void
	highlight_style_not_void: highlight_style /= Void
	disabled_style_not_void: disabled_style /= Void
	valid_border_type: {BORDER_TYPE}.is_valid (border_type)
	valid_separator_line_set: {DIVIDER_LINE_SET}.is_valid (separator_line_set)
	valid_submenu_symbol: is_valid_symbol (submenu_symbol)

end
