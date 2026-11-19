note
	description: "[
		P2 item W4, TUI_MENU + MENU_STATE + MENU_ITEM, and OVERLAY_PLACEMENT (shared with W6)
		(review/p2_terminal_widgets_plan.md). Ratatui has no menu (the `tui-menu` crate is the
		model), so these are EiffelTUI's own tests: the state's navigation (separators and
		disabled items skipped, also at both ends and when all are disabled; sub-menus entered
		and left; `set_items` while open), the placement's four sides, flips, shifts and cuts;
		row-exact buffer snapshots (closed bar, open drop-down, a sub-menu flipped at the
		right edge, a drop-down at the bottom edge opening upwards or cut, aligned shortcuts,
		wide characters); the hit regions and clicks, through the real event loop on a fixed
		viewport too; the focus scope trapping Tab; and EXAMPLE_MENU_BAR.

		Expected rows are written with `glyphs`: '{' U+250C, '}' U+2510, '`' U+2514,
		'^' U+2518, '-' U+2500, '|' U+2502, '@' U+25B8 (the sub-menu symbol), '#' U+2591,
		'=' U+25B2 and '~' U+25BC (the scroll marks).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_MENU

inherit
	BUFFER_TEST_HELPER

feature -- State

	test_menu_state_skips_separators_and_disabled
			-- `move_down` / `move_up` skip separators and disabled items and wrap round; a
			-- drop-down whose selectable item is at neither end; one with nothing selectable
			-- (shown, nothing highlighted, nothing to activate); disabled bar entries skipped
			-- by `open` and `move_right` / `move_left`; no selectable entry: `open` does nothing.
		local
			s: MENU_STATE
		do
			s := sample_state
			s.open
			assert_path ("open", s, <<1, 1>>)
			s.move_down
			assert_path ("down to Open", s, <<1, 2>>)
			s.move_down
			assert_path ("separator skipped", s, <<1, 4>>)
			s.move_down
			assert_path ("disabled and separator skipped", s, <<1, 7>>)
			s.move_down
			assert_path ("wraps to the first", s, <<1, 1>>)
			s.move_up
			assert_path ("wraps to the last", s, <<1, 7>>)
			s.move_up
			assert_path ("up skips", s, <<1, 4>>)
				-- Only the middle item is selectable: both ends are skipped
			create s.make (<<(create {MENU_ITEM}.make_submenu ("Odd", <<create {MENU_ITEM}.make_separator,
				(create {MENU_ITEM}.make ("X")).with_enabled (False), create {MENU_ITEM}.make ("B"),
				(create {MENU_ITEM}.make ("Y")).with_enabled (False), create {MENU_ITEM}.make_separator>>))>>)
			s.open
			assert_path ("first selectable in the middle", s, <<1, 3>>)
			s.move_down
			assert_path ("down stays on the only one", s, <<1, 3>>)
			s.move_up
			assert_path ("up stays on the only one", s, <<1, 3>>)
			assert ("first and last", s.entry (1).first_selectable = 3 and s.entry (1).last_selectable = 3)
				-- Nothing selectable: shown with nothing highlighted
			create s.make (<<(create {MENU_ITEM}.make_submenu ("None", <<create {MENU_ITEM}.make_separator,
				(create {MENU_ITEM}.make ("A")).with_enabled (False)>>))>>)
			s.open
			assert_path ("all disabled: shown, none highlighted", s, <<1, 0>>)
			assert ("nothing highlighted", s.highlighted_item = Void)
			s.move_down
			s.move_up
			assert_path ("moves do nothing", s, <<1, 0>>)
			s.activate
			assert_path ("activate does nothing", s, <<1, 0>>)
			assert ("nothing chosen", s.chosen_item = Void)
				-- Disabled bar entries
			create s.make (<<(create {MENU_ITEM}.make_submenu ("A", <<create {MENU_ITEM}.make ("a")>>)).with_enabled (False),
				create {MENU_ITEM}.make_submenu ("B", <<create {MENU_ITEM}.make ("b")>>),
				(create {MENU_ITEM}.make_submenu ("C", <<create {MENU_ITEM}.make ("c")>>)).with_enabled (False),
				create {MENU_ITEM}.make_submenu ("D", <<create {MENU_ITEM}.make ("d")>>)>>)
			s.open
			assert_path ("open skips a disabled first entry", s, <<2, 1>>)
			s.move_right
			assert_path ("right skips a disabled entry", s, <<4, 1>>)
			s.move_right
			assert_path ("right wraps past a disabled first entry", s, <<2, 1>>)
			s.move_left
			assert_path ("left wraps", s, <<4, 1>>)
			assert ("Alt+letter skips disabled", s.entry_with_initial ('c') = 0 and s.entry_with_initial ('D') = 4
				and s.entry_with_initial ('z') = 0)
			create s.make (<<(create {MENU_ITEM}.make ("Off")).with_enabled (False), create {MENU_ITEM}.make_separator>>)
			s.open
			assert ("no selectable entry: stays closed", not s.is_open)
		end

	test_menu_state_submenus
			-- Into and out of a sub-menu with Right / Left, Enter and Esc; Right on a leaf goes
			-- to the next entry with its drop-down open; on the bar alone (after Esc) Left / Right
			-- keep the drop-down closed and Down / Up / Enter open it.
		local
			s: MENU_STATE
		do
			s := sample_state
			s.open
			s.move_down
			s.move_down
			assert_path ("on Recent", s, <<1, 4>>)
			s.move_right
			assert_path ("into the sub-menu", s, <<1, 4, 1>>)
			assert ("a.txt highlighted", attached s.highlighted_item as h and then h.label.to_plain_string.same_string ("a.txt"))
			s.move_down
			assert_path ("down in the sub-menu", s, <<1, 4, 2>>)
			s.move_left
			assert_path ("left leaves it", s, <<1, 4>>)
			s.activate
			assert_path ("Enter opens it", s, <<1, 4, 1>>)
			s.close_level
			assert_path ("Esc closes the sub-menu", s, <<1, 4>>)
			s.close_level
			assert_path ("Esc closes the drop-down", s, <<1>>)
			assert ("bar still open", s.is_open and not s.is_dropped_down)
			s.close_level
			assert ("Esc on the bar closes", not s.is_open)
				-- Right on a leaf: the next entry, dropped down
			s.open
			s.move_right
			assert_path ("next entry", s, <<2, 1>>)
			s.move_right
			assert_path ("third entry", s, <<3, 1>>)
			s.move_right
			assert_path ("wraps", s, <<1, 1>>)
			s.move_left
			assert_path ("left wraps", s, <<3, 1>>)
				-- The bar alone
			s.close_level
			assert_path ("bar alone", s, <<3>>)
			s.move_left
			assert_path ("left on the bar stays closed", s, <<2>>)
			s.move_down
			assert_path ("down opens at the first", s, <<2, 1>>)
			s.close_level
			s.move_up
			assert_path ("up opens at the last", s, <<2, 6>>)
			s.close_level
			s.activate
			assert_path ("Enter opens", s, <<2, 1>>)
			s.open_entry (3)
			assert_path ("open_entry", s, <<3, 1>>)
		end

	test_menu_state_activate_and_chosen
			-- Enter on a leaf chooses it (`chosen_item`, `chosen`) and closes the menu;
			-- `clear_chosen`; a leaf without an id; a bar entry without a sub-menu.
		local
			s: MENU_STATE
		do
			s := sample_state
			s.open
			s.activate
			assert ("New chosen", attached s.chosen as c and then c.value = 11)
			assert ("closed", not s.is_open)
			s.clear_chosen
			assert ("cleared", s.chosen = Void and s.chosen_item = Void)
			create s.make (<<create {MENU_ITEM}.make_submenu ("X", <<create {MENU_ITEM}.make ("No id")>>),
				(create {MENU_ITEM}.make ("Go")).with_id (create {WIDGET_ID}.make (40))>>)
			s.open
			s.activate
			assert ("item without an id chosen", attached s.chosen_item as c and then c.label.to_plain_string.same_string ("No id"))
			assert ("no id", s.chosen = Void)
			s.open_entry (2)
			assert_path ("leaf entry on the bar", s, <<2>>)
			s.activate
			assert ("bar leaf chosen", attached s.chosen as c and then c.value = 40 and not s.is_open)
		end

	test_menu_state_set_items_while_open
			-- `set_items` while a sub-menu is open closes the menu, pops its focus scope and
			-- keeps the last chosen item; the new items can be opened.
		local
			s: MENU_STATE
			f: FOCUS_MANAGER
		do
			create f.make
			s := sample_state
			s.set_focus_manager (f)
			s.open
			s.activate
			assert ("chosen first", attached s.chosen as c and then c.value = 11)
			s.open
			s.move_down
			s.move_down
			s.move_right
			assert_path ("deep", s, <<1, 4, 1>>)
			assert ("scope pushed", f.scope_depth = 2)
			s.set_items (<<create {MENU_ITEM}.make_submenu ("Only", <<create {MENU_ITEM}.make ("one")>>)>>)
			assert ("closed", not s.is_open and s.path.is_empty)
			assert ("scope popped", f.scope_depth = 1 and s.scope_depth = 0)
			assert ("chosen kept", attached s.chosen as c and then c.value = 11)
			assert ("new items", s.count = 1 and s.entry (1).label.to_plain_string.same_string ("Only"))
			s.open
			assert_path ("new items open", s, <<1, 1>>)
			assert ("scope pushed again", f.scope_depth = 2)
			s.close
			assert ("and popped", f.scope_depth = 1)
		end

	test_menu_state_clicks
			-- `click` and `handles` (see MENU_STATE's note).
		local
			s: MENU_STATE
		do
			s := sample_state
			assert ("closed: nothing handled", not s.handles (Void) and not s.handles (id (11)) and not s.handles (id (99)))
			assert ("closed: bar entry handled", s.handles (id (1)))
			s.click (Void)
			assert ("closed: click on nothing", not s.is_open)
			s.click (id (1))
			assert_path ("entry opens, nothing highlighted", s, <<1, 0>>)
			assert ("open: everything handled", s.handles (Void) and s.handles (id (99)))
			s.click (id (1))
			assert ("same entry closes", not s.is_open)
			s.click (id (2))
			assert_path ("Edit", s, <<2, 0>>)
			s.click (id (1))
			assert_path ("switch to File", s, <<1, 0>>)
			s.click (id (131))
			assert ("an item not shown counts as outside", not s.is_open)
			s.click (id (1))
			s.click (id (13))
			assert_path ("sub-menu opened", s, <<1, 4, 0>>)
			s.click (id (12))
			assert ("Open chosen from the parent level", attached s.chosen as c and then c.value = 12 and not s.is_open)
			s.click (id (1))
			s.click (id (13))
			s.click (id (132))
			assert ("sub-menu leaf chosen", attached s.chosen as c and then c.value = 132 and not s.is_open)
			s.click (id (1))
			s.click (id (14))
			assert_path ("disabled item does nothing", s, <<1, 0>>)
			s.set_menu_id (id (50))
			s.click (id (50))
			assert_path ("menu surface does nothing", s, <<1, 0>>)
			assert ("menu id handled", s.handles (id (50)))
			s.click (id (99))
			assert ("other id closes", not s.is_open)
			assert ("closed: menu id handled", s.handles (id (50)))
			s.click (id (1))
			s.click (Void)
			assert ("nothing closes", not s.is_open)
				-- A bar entry without a sub-menu is chosen at once
			create s.make (<<(create {MENU_ITEM}.make ("Go")).with_id (id (40))>>)
			s.click (id (40))
			assert ("bar leaf chosen", attached s.chosen as c and then c.value = 40 and not s.is_open)
		end

	test_menu_item_builders_and_equality
			-- MENU_ITEM is immutable: builders return new items; equality; separators; the
			-- selectable search; preconditions of the item, the state and the widget.
		local
			a, b: MENU_ITEM
			s: MENU_STATE
			m: TUI_MENU
		do
			create a.make ("Open")
			b := a.with_shortcut ("Ctrl+O").with_id (id (12))
			assert ("original unchanged", a.shortcut_text = Void and a.widget_id = Void)
			assert ("builder set", attached b.shortcut_text as t and then t.same_string ("Ctrl+O") and b.widget_id ~ id (12))
			assert ("not equal", not a.is_equal (b))
			assert ("equal", b.is_equal (a.with_shortcut ("Ctrl+O").with_id (id (12))))
			assert ("disabled", not a.with_enabled (False).is_selectable and a.is_selectable)
			assert ("separator", (create {MENU_ITEM}.make_separator).is_separator and not (create {MENU_ITEM}.make_separator).is_selectable)
			a := create {MENU_ITEM}.make_submenu ("Sub", <<create {MENU_ITEM}.make ("x"), create {MENU_ITEM}.make ("y")>>)
			assert ("sub-menu", a.has_submenu and a.count = 2 and a.child (2).label.to_plain_string.same_string ("y"))
			assert ("submenu is a copy", a.submenu.count = 2)
			a.submenu.wipe_out
			assert ("copy changes nothing", a.count = 2)
			assert ("deep equality", a ~ create {MENU_ITEM}.make_submenu ("Sub", <<create {MENU_ITEM}.make ("x"), create {MENU_ITEM}.make ("y")>>))
			assert ("deep inequality", not (a ~ create {MENU_ITEM}.make_submenu ("Sub", <<create {MENU_ITEM}.make ("x"),
				(create {MENU_ITEM}.make ("y")).with_enabled (False)>>)))
			assert ("next / previous", a.next_selectable (2) = 1 and a.previous_selectable (1) = 2 and a.next_selectable (0) = 1
				and a.previous_selectable (0) = 2)
			assert ("has id deep", sample_state.root.has_id (id (132)) and not sample_state.root.has_id (id (77)))
				-- Preconditions
			assert ("separator takes no id", raises (agent (create {MENU_ITEM}.make_separator).with_id (id (1))))
			assert ("separator takes no sub-menu", raises (agent (create {MENU_ITEM}.make_separator).with_submenu (<<create {MENU_ITEM}.make ("x")>>)))
			assert ("control in a shortcut", raises (agent (create {MENU_ITEM}.make ("x")).with_shortcut ("Ctrl%/27/[")))
			s := sample_state
			assert ("disabled entry cannot be opened", raises (agent (create {MENU_STATE}.make (<<(create {MENU_ITEM}.make ("x")).with_enabled (False)>>)).open_entry (1)))
			s.open
			assert ("no builder while open", raises (agent s.with_menu_id (id (5))))
			assert ("no focus manager while open", raises (agent s.set_focus_manager (create {FOCUS_MANAGER}.make)))
			assert ("valid paths", s.is_valid_path (create {ARRAYED_LIST [INTEGER]}.make_from_array (<<1, 4, 0>>))
				and not s.is_valid_path (create {ARRAYED_LIST [INTEGER]}.make_from_array (<<1, 5>>))
				and not s.is_valid_path (create {ARRAYED_LIST [INTEGER]}.make_from_array (<<1, 3>>))
				and not s.is_valid_path (create {ARRAYED_LIST [INTEGER]}.make_from_array (<<1, 1, 1>>))
				and not s.is_valid_path (create {ARRAYED_LIST [INTEGER]}.make_from_array (<<0>>))
				and not s.is_valid_path (create {ARRAYED_LIST [INTEGER]}.make_from_array (<<1, 0, 1>>)))
				-- Widget
			create m
			assert ("defaults", m.highlight_style.is_reversed and m.disabled_style.is_dim and m.shadow = Void
				and m.submenu_symbol.same_string ({STRING_32} "%/0x25B8/"))
			assert ("symbol one column", {UNICODE_WIDTH}.string_width (m.submenu_symbol) = 1)
			assert ("builder copies", m.with_border_type ({BORDER_TYPE}.double).border_type = {BORDER_TYPE}.double
				and m.border_type = {BORDER_TYPE}.plain)
			assert ("widget equality", m ~ create {TUI_MENU} and not (m ~ m.with_submenu_symbol (">")))
			assert ("empty symbol refused", raises (agent m.set_submenu_symbol ("")))
			assert ("bad line set refused", raises (agent m.set_separator_line_set (0)))
		end

feature -- Placement

	test_overlay_placement
			-- OVERLAY_PLACEMENT: the four sides; each flip; the shift along the edge; the cut
			-- when neither side fits (the side with more room, the preferred side on a tie);
			-- longer than the bounds; no room; empty bounds; an anchor outside the bounds.
		local
			b: RECT
		do
			create b.make (0, 0, 20, 10)
			assert_rect ("below", place (2, 1, 4, 6, 3, {OVERLAY_PLACEMENT}.below, b), 2, 2, 6, 3)
			assert_rect ("above", place (2, 8, 4, 6, 3, {OVERLAY_PLACEMENT}.above, b), 2, 5, 6, 3)
			assert_rect ("right", place (2, 2, 4, 5, 3, {OVERLAY_PLACEMENT}.right, b), 6, 2, 5, 3)
			assert_rect ("left", place (10, 2, 4, 5, 3, {OVERLAY_PLACEMENT}.left, b), 5, 2, 5, 3)
				-- Flips
			assert_rect ("below flips above", place (2, 8, 4, 6, 3, {OVERLAY_PLACEMENT}.below, b), 2, 5, 6, 3)
			assert ("side above", {OVERLAY_PLACEMENT}.placed_side (create {RECT}.make (2, 8, 4, 1), 6, 3, {OVERLAY_PLACEMENT}.below, b)
				= {OVERLAY_PLACEMENT}.above)
			assert_rect ("above flips below", place (2, 1, 4, 6, 3, {OVERLAY_PLACEMENT}.above, b), 2, 2, 6, 3)
			assert_rect ("right flips left", place (14, 2, 4, 5, 3, {OVERLAY_PLACEMENT}.right, b), 9, 2, 5, 3)
			assert_rect ("left flips right", place (2, 2, 4, 5, 3, {OVERLAY_PLACEMENT}.left, b), 6, 2, 5, 3)
				-- Shifts along the edge
			assert_rect ("shifted left", place (17, 1, 2, 6, 3, {OVERLAY_PLACEMENT}.below, b), 14, 2, 6, 3)
			assert_rect ("shifted up", place (2, 8, 4, 5, 4, {OVERLAY_PLACEMENT}.right, b), 6, 6, 5, 4)
				-- Cuts
			assert_rect ("more room below: cut there", place (0, 4, 4, 6, 8, {OVERLAY_PLACEMENT}.above, b), 0, 5, 6, 5)
			create b.make (0, 0, 20, 9)
			assert_rect ("tie: preferred below", place (0, 4, 4, 6, 8, {OVERLAY_PLACEMENT}.below, b), 0, 5, 6, 4)
			assert_rect ("tie: preferred above", place (0, 4, 4, 6, 8, {OVERLAY_PLACEMENT}.above, b), 0, 0, 6, 4)
			create b.make (0, 0, 20, 10)
			assert_rect ("tie: right cut", place (8, 2, 4, 10, 3, {OVERLAY_PLACEMENT}.right, b), 12, 2, 8, 3)
			assert_rect ("wider than the bounds", place (5, 1, 4, 30, 3, {OVERLAY_PLACEMENT}.below, b), 0, 2, 20, 3)
			assert ("no room", place (0, 0, 20, 4, 3, {OVERLAY_PLACEMENT}.below, create {RECT}.make (0, 0, 20, 1)).is_empty)
			assert ("empty bounds", place (2, 1, 4, 6, 3, {OVERLAY_PLACEMENT}.below, create {RECT}.make (0, 0, 0, 0)).is_empty)
			assert_rect ("anchor outside", place (30, 3, 2, 6, 3, {OVERLAY_PLACEMENT}.below, b), 14, 4, 6, 3)
			assert_rect ("offset bounds", place (12, 5, 4, 6, 3, {OVERLAY_PLACEMENT}.below, create {RECT}.make (10, 4, 10, 4)), 12, 6, 6, 2)
			assert ("sides", {OVERLAY_PLACEMENT}.opposite ({OVERLAY_PLACEMENT}.left) = {OVERLAY_PLACEMENT}.right
				and not {OVERLAY_PLACEMENT}.is_valid_side (0) and not {OVERLAY_PLACEMENT}.is_valid_side (5))
		end

feature -- Snapshots

	test_menu_closed_bar
			-- The closed bar: " File  Edit  Help " then blanks over the whole top row, in
			-- `bar_style`; nothing below; a bar narrower than its entries cuts them.
		local
			l_buf: BUFFER
			l_style: STYLE
		do
			create l_buf.make (24, 2)
			l_buf.put_string (0, 0, "xxxxxxxxxxxxxxxxxxxxxxxx", create {STYLE})
			l_buf.put_string (1, 0, "yyyy", create {STYLE})
			l_style := create {STYLE}.make_bg ({COLOR}.blue)
			(create {TUI_MENU}).with_bar_style (l_style).render_stateful (l_buf.area, l_buf, sample_state)
			assert_buffer_lines ("closed", l_buf, <<" File  Edit  Help       ", "yyyy                    ">>)
			assert_cell_style ("bar style", l_buf, 0, 23, l_style)
			assert_cell_style ("entry in bar style", l_buf, 0, 2, l_style)
			assert_cell_style ("below untouched", l_buf, 1, 0, create {STYLE})
				-- Cut at the area's right edge
			create l_buf.make (24, 1)
			(create {TUI_MENU}).render_stateful (create {RECT}.make (0, 0, 9, 1), l_buf, sample_state)
			assert_buffer_lines ("cut, with the more-entries mark", l_buf, <<{STRING_32} " File  E%/0x25B6/               ">>)
				-- Stateless render: an empty bar
			create l_buf.make (6, 1)
			(create {TUI_MENU}).render (l_buf.area, l_buf)
			assert_buffer_lines ("empty", l_buf, <<"      ">>)
		end

	test_menu_open_drop_down
			-- F10 on File: the drop-down below the entry, separators as rules, the disabled
			-- Save dim, the highlighted New reversed (and the entry), shortcuts right-aligned in
			-- one column, the sub-menu symbol on Recent; a shadow when asked for.
		local
			l_buf: BUFFER
			s: MENU_STATE
		do
			s := sample_state
			s.open
			create l_buf.make (30, 11)
			(create {TUI_MENU}).render_stateful (l_buf.area, l_buf, s)
			assert_buffer_lines ("File open", l_buf, file_menu_rows)
			assert ("consistent", l_buf.is_consistent)
			assert_cell_style ("entry highlighted", l_buf, 0, 0, (create {STYLE}).with_reverse)
			assert_cell_style ("entry end highlighted", l_buf, 0, 5, (create {STYLE}).with_reverse)
			assert_cell_style ("next entry not", l_buf, 0, 6, create {STYLE})
			assert_cell_style ("New highlighted", l_buf, 2, 1, (create {STYLE}).with_reverse)
			assert_cell_style ("its shortcut too", l_buf, 2, 16, (create {STYLE}).with_reverse)
			assert_cell_style ("to the border", l_buf, 2, 19, (create {STYLE}).with_reverse)
			assert_cell_style ("border not", l_buf, 2, 20, create {STYLE})
			assert_cell_style ("Save dim", l_buf, 6, 3, (create {STYLE}).with_dim)
			assert_cell_style ("Open plain", l_buf, 3, 3, create {STYLE})
				-- Down twice: Recent highlighted; styles of the menu
			s.move_down
			s.move_down
			create l_buf.make (30, 11)
			(create {TUI_MENU}).with_menu_style (create {STYLE}.make_bg ({COLOR}.blue))
				.with_shadow (create {SHADOW}.make_light_shade).render_stateful (l_buf.area, l_buf, s)
			assert_cell_style ("menu style on the border", l_buf, 1, 0, create {STYLE}.make_bg ({COLOR}.blue))
			assert_cell_style ("Recent highlighted over the menu style", l_buf, 5, 2,
				(create {STYLE}.make_bg ({COLOR}.blue)).patch ((create {STYLE}).with_reverse))
			assert_cell_style ("New not highlighted", l_buf, 2, 2, create {STYLE}.make_bg ({COLOR}.blue))
			assert_cell_symbol ("shadow right", l_buf, 2, 21, {STRING_32} "%/0x2591/")
			assert_cell_symbol ("shadow below", l_buf, 10, 1, {STRING_32} "%/0x2591/")
			assert_cell_symbol ("no shadow on the corner's row", l_buf, 1, 21, " ")
		end

	test_menu_submenu_flips_at_right_edge
			-- Recent's sub-menu opens to the right of its row, its top border on that row; with
			-- the File drop-down against the right edge it flips to the left.
		local
			l_buf: BUFFER
			s: MENU_STATE
		do
			s := sample_state
			s.open
			s.move_down
			s.move_down
			s.move_right
			create l_buf.make (30, 11)
			(create {TUI_MENU}).render_stateful (l_buf.area, l_buf, s)
			assert_buffer_lines ("sub-menu right", l_buf, <<
				" File  Edit  Help             ",
				glyphs ("{-------------------}         "),
				glyphs ("| New      Ctrl+N   |         "),
				glyphs ("| Open...  Ctrl+O   |         "),
				glyphs ("|-------------------|         "),
				glyphs ("| Recent          @ |{-------}"),
				glyphs ("| Save     Ctrl+S   || a.txt |"),
				glyphs ("|-------------------|| b.txt |"),
				glyphs ("| Quit     Ctrl+Q   |`-------^"),
				glyphs ("`-------------------^         "),
				"                              ">>)
			assert_cell_style ("a.txt highlighted", l_buf, 6, 22, (create {STYLE}).with_reverse)
			assert_cell_style ("Recent stays highlighted", l_buf, 5, 2, (create {STYLE}).with_reverse)
				-- The bar starts at column 9: the drop-down ends on the right edge
			create l_buf.make (30, 11)
			(create {TUI_MENU}).render_stateful (create {RECT}.make (9, 0, 21, 1), l_buf, s)
			assert_buffer_lines ("sub-menu flipped left", l_buf, <<
				"          File  Edit  Help    ",
				glyphs ("         {-------------------}"),
				glyphs ("         | New      Ctrl+N   |"),
				glyphs ("         | Open...  Ctrl+O   |"),
				glyphs ("         |-------------------|"),
				glyphs ("{-------}| Recent          @ |"),
				glyphs ("| a.txt || Save     Ctrl+S   |"),
				glyphs ("| b.txt ||-------------------|"),
				glyphs ("`-------^| Quit     Ctrl+Q   |"),
				glyphs ("         `-------------------^"),
				"                              ">>)
			assert ("consistent", l_buf.is_consistent)
		end

	test_menu_drop_down_at_bottom_edge
			-- *Decided*: a bar at the bottom of the screen opens its drop-down upwards (it fits
			-- whole above); a drop-down that fits on neither side is cut to the rows below, a
			-- closed box whose last items are left out.
		local
			l_buf: BUFFER
			s: MENU_STATE
			l_frame: FRAME
		do
			s := sample_state
			s.open
			create l_buf.make (30, 12)
			(create {TUI_MENU}).render_stateful (create {RECT}.make (0, 11, 30, 1), l_buf, s)
			assert_buffer_lines ("upwards", l_buf, <<
				"                              ",
				"                              ",
				glyphs ("{-------------------}         "),
				glyphs ("| New      Ctrl+N   |         "),
				glyphs ("| Open...  Ctrl+O   |         "),
				glyphs ("|-------------------|         "),
				glyphs ("| Recent          @ |         "),
				glyphs ("| Save     Ctrl+S   |         "),
				glyphs ("|-------------------|         "),
				glyphs ("| Quit     Ctrl+Q   |         "),
				glyphs ("`-------------------^         "),
				" File  Edit  Help             ">>)
				-- A 6-row screen: 5 rows below the bar, none above
			create l_buf.make (30, 6)
			create l_frame.make (l_buf)
			l_frame.render_stateful_widget (create {TUI_MENU}, l_buf.area, s)
			assert_buffer_lines ("cut", l_buf, <<
				" File  Edit  Help             ",
				glyphs ("{-------------------}         "),
				glyphs ("| New      Ctrl+N   |         "),
				glyphs ("| Open...  Ctrl+O   |         "),
				glyphs ("|-------------------|         "),
				glyphs ("`------------------~^         ")>>)
			assert ("New clickable", attached l_frame.hit_map.hit (3, 2) as h and then h ~ id (11))
			assert ("Recent cut: not clickable", l_frame.hit_map.hit (3, 5) = Void)
		end

	test_menu_shortcuts_and_wide_labels
			-- Wide characters in the bar, in labels and in shortcuts: the shortcut column is
			-- right-aligned on the widest shortcut; a wide character crossing the bar's edge is
			-- left out.
		local
			l_buf: BUFFER
			s: MENU_STATE
		do
			create s.make (<<create {MENU_ITEM}.make_submenu ({STRING_32} "%/0x6587/%/0x4EF6/", <<
				(create {MENU_ITEM}.make ({STRING_32} "%/0x65B0/%/0x5EFA/")).with_shortcut ("Ctrl+N"),
				(create {MENU_ITEM}.make ("Open")).with_shortcut ({STRING_32} "%/0x5BBD/")>>),
				create {MENU_ITEM}.make_submenu ({STRING_32} "%/0x5BBD/%/0x5B57/", <<create {MENU_ITEM}.make ("x")>>)>>)
			s.open
			create l_buf.make (20, 5)
			(create {TUI_MENU}).render_stateful (l_buf.area, l_buf, s)
			assert_buffer_lines ("wide", l_buf, <<
				{STRING_32} " %/0x6587/%/0x4EF6/  %/0x5BBD/%/0x5B57/         ",
				glyphs ("{--------------}    "),
				glyphs ("| ") + {STRING_32} "%/0x65B0/%/0x5EFA/  Ctrl+N " + glyphs ("|    "),
				glyphs ("| Open      ") + {STRING_32} "%/0x5BBD/ " + glyphs ("|    "),
				glyphs ("`--------------^    ")>>)
			assert ("consistent", l_buf.is_consistent)
				-- Cut at 10 columns: the second entry's second character crosses the edge
			create l_buf.make (10, 1)
			(create {TUI_MENU}).render_stateful (l_buf.area, l_buf, create {MENU_STATE}.make (s.items))
			assert_buffer_lines ("cut wide", l_buf, <<{STRING_32} " %/0x6587/%/0x4EF6/  %/0x5BBD/%/0x25B6/">>)
			assert ("cut consistent", l_buf.is_consistent)
		end

feature -- Hit regions and clicks

	test_menu_registers_hit_regions
			-- Closed: the bar entries (and `menu_id` under the bar), the background still
			-- reachable. Open: a blocker over the whole frame, so the background hits nothing
			-- inside and outside the drop-down; items hit their ids (a disabled one too);
			-- borders, separators and the bar's blanks hit `menu_id`, or nothing without one;
			-- an open sub-menu's items.
		local
			l_frame: FRAME
			s: MENU_STATE
		do
			s := sample_state
			l_frame := new_frame_with_background
			l_frame.render_stateful_widget (create {TUI_MENU}, l_frame.area, s)
			assert ("closed: File", attached l_frame.hit_map.hit (2, 0) as h and then h ~ id (1))
			assert ("closed: Help", attached l_frame.hit_map.hit (17, 0) as h and then h ~ id (3))
			assert ("closed: background", attached l_frame.hit_map.hit (3, 4) as h and then h ~ id (90))
			assert ("closed: bar blank hits nothing", l_frame.hit_map.hit (20, 0) = Void)
				-- Open, no menu id
			s.open
			l_frame := new_frame_with_background
			l_frame.render_stateful_widget (create {TUI_MENU}, l_frame.area, s)
			assert ("New", attached l_frame.hit_map.hit (3, 2) as h and then h ~ id (11))
			assert ("New's last cell", attached l_frame.hit_map.hit (19, 2) as h and then h ~ id (11))
			assert ("disabled Save registered", attached l_frame.hit_map.hit (3, 6) as h and then h ~ id (14))
			assert ("separator blocks", l_frame.hit_map.hit (3, 4) = Void)
			assert ("border blocks", l_frame.hit_map.hit (0, 2) = Void)
			assert ("outside blocked", l_frame.hit_map.hit (25, 10) = Void)
			assert ("Edit entry", attached l_frame.hit_map.hit (8, 0) as h and then h ~ id (2))
				-- With a menu id
			s.set_menu_id (id (50))
			l_frame := new_frame_with_background
			l_frame.render_stateful_widget (create {TUI_MENU}, l_frame.area, s)
			assert ("separator: menu", attached l_frame.hit_map.hit (3, 4) as h and then h ~ id (50))
			assert ("border: menu", attached l_frame.hit_map.hit (20, 9) as h and then h ~ id (50))
			assert ("bar blank: menu", attached l_frame.hit_map.hit (25, 0) as h and then h ~ id (50))
			assert ("outside still blocked", l_frame.hit_map.hit (25, 10) = Void)
				-- The sub-menu
			s.move_down
			s.move_down
			s.move_right
			l_frame := new_frame_with_background
			l_frame.render_stateful_widget (create {TUI_MENU}, l_frame.area, s)
			assert ("a.txt", attached l_frame.hit_map.hit (22, 6) as h and then h ~ id (131))
			assert ("b.txt", attached l_frame.hit_map.hit (27, 7) as h and then h ~ id (132))
			assert ("sub-menu border", attached l_frame.hit_map.hit (21, 5) as h and then h ~ id (50))
			assert ("parent still clickable", attached l_frame.hit_map.hit (3, 2) as h and then h ~ id (11))
				-- The immediate-mode path registers nothing
			l_frame := new_frame_with_background
			l_frame.render_widget (create {TUI_MENU}, l_frame.area)
			assert ("stateless: background", attached l_frame.hit_map.hit (2, 0) as h and then h ~ id (90))
		end

	test_menu_clicks_fixed_viewport
			-- The real event loop on a fixed viewport at screen (10, 3), one click per frame
			-- (posted by the draw hook once the previous one was handled, so each click is
			-- tested against the frame that shows the previous click's result): a click on the
			-- background "Back" box hits it; a click on File opens it; a click on Back, now
			-- under the drop-down's separator, is blocked and closes the menu; a click on "Out",
			-- outside the drop-down, is blocked too; a click on New chooses it; Back is
			-- reachable again; a click at the frame position on screen is outside the viewport.
		local
			l_app: TEST_TUI_APP_IMPL
		do
			create click_state.make (sample_items)
			click_log.wipe_out
			click_next := 1
			click_handled := 0
			click_frames := 0
			click_points := <<[13, 7], [12, 3], [13, 7], [12, 3], [33, 13], [12, 3], [13, 5], [13, 7], [2, 0], [33, 13]>>
			l_app := new_app (create {VIEWPORT}.make_fixed (create {RECT}.make (10, 3, 30, 11)))
			l_app.set_draw_hook (agent draw_click_frame (?, l_app))
			l_app.set_mouse_hook (agent on_click (?, l_app))
			l_app.run
			assert ("frames capped", click_frames < Click_frame_cap)
			assert_log (<<"bg 90", "menu 1 2", "menu void 0", "menu 1 2", "menu void 0", "menu 1 2",
				"menu 11 0 chosen 11", "bg 90", "bg void", "bg 91">>)
		end

feature -- Focus

	test_menu_focus_scope_traps_tab
			-- With a focus manager, the menu's scope is open exactly while the menu is: Tab
			-- (`focus_next`) reaches nothing, a click's `focus_at` on a background id is refused,
			-- and the background's focus comes back on every closing path (Esc, Enter, a click
			-- outside, `set_items`).
		local
			s: MENU_STATE
			f: FOCUS_MANAGER
		do
			create f.make
			f.register (id (90))
			f.register (id (91))
			s := sample_state
			s.set_focus_manager (f)
			assert ("background focused", f.is_focused (id (90)))
			s.open
			assert ("scope pushed", f.scope_depth = 2 and s.scope_depth = 2 and not f.has_focus)
			f.focus_next
			f.focus_next
			assert ("Tab trapped", not f.has_focus)
			assert ("background refused", not f.focus_at (id (91)))
			s.move_down
			s.close_level
			assert ("still open on the bar", s.is_open and f.scope_depth = 2)
			s.close_level
			assert ("Esc pops", f.scope_depth = 1 and f.is_focused (id (90)))
			f.focus_next
			assert ("Tab works again", f.is_focused (id (91)))
			s.open
			s.activate
			assert ("Enter pops", f.scope_depth = 1 and f.is_focused (id (91)))
			s.click (id (1))
			assert ("a click opens with a scope", f.scope_depth = 2)
			s.click (Void)
			assert ("a click outside pops", f.scope_depth = 1 and f.is_focused (id (91)))
			s.open_entry (2)
			s.set_items (sample_items)
			assert ("set_items pops", f.scope_depth = 1)
			s.open
			s.move_right
			s.move_left
			assert ("one scope however far it moves", f.scope_depth = 2)
			f.push_scope
			assert ("not innermost", not s.is_scope_innermost)
			assert ("closing refused", raises (agent s.close))
			f.pop_scope
			s.close
			assert ("closed", f.scope_depth = 1)
		end

	test_menu_copy_does_not_take_the_scope
			-- A copy of an open state with a focus scope keeps the path but not the scope:
			-- closing the copy pops nothing, closing the original pops the scope; a copy of
			-- a closed state keeps its focus manager.
		local
			s, c: MENU_STATE
			f: FOCUS_MANAGER
		do
			create f.make
			f.register (id (90))
			s := sample_state
			c := s.twin
			assert ("no manager yet", c.focus_manager = Void)
			s.set_focus_manager (f)
			c := s.twin
			assert ("closed copy keeps the manager too", c.focus_manager = f and c.scope_depth = 0)
			s.open
			s.move_down
			c := s.twin
			assert ("same path", c.path ~ s.path and c.is_open)
			assert ("no scope taken", c.scope_depth = 0 and c.focus_manager = Void)
			c.close
			assert ("closing the copy pops nothing", f.scope_depth = 2 and s.is_scope_innermost)
			s.close
			assert ("the original pops", f.scope_depth = 1 and f.is_focused (id (90)))
			c.set_focus_manager (f)
			c.open
			assert ("the copy can own a scope of its own", f.scope_depth = 2 and c.scope_depth = 2)
			c.close
			assert ("and pop it", f.scope_depth = 1)
		end

feature -- Scrolling and overlay

	test_menu_cut_drop_down_scrolls
			-- A drop-down cut by the screen's edge scrolls to keep the highlighted item shown,
			-- with a mark on the top / bottom border when items are scrolled out above / below;
			-- items scrolled out are not clickable, the keys reach every item, and a sub-menu
			-- opens next to its scrolled row.
		local
			l_frame: FRAME
			s: MENU_STATE
		do
			s := sample_state
			s.open
				-- Down twice: Recent, the 4th item, in a box that shows 3
			s.move_down
			s.move_down
			l_frame := render_on_six_rows (s)
			assert_buffer_lines ("scrolled to Recent", l_frame.buffer, <<
				" File  Edit  Help             ",
				glyphs ("{------------------=}         "),
				glyphs ("| Open...  Ctrl+O   |         "),
				glyphs ("|-------------------|         "),
				glyphs ("| Recent          @ |         "),
				glyphs ("`------------------~^         ")>>)
			assert ("offset", s.offset (2) = 1)
			assert_cell_style ("Recent highlighted", l_frame.buffer, 4, 2, (create {STYLE}).with_reverse)
			assert ("New scrolled out: not clickable", l_frame.hit_map.hit (3, 1) = Void)
			assert ("Open clickable", attached l_frame.hit_map.hit (3, 2) as h and then h ~ id (12))
			assert ("Recent clickable", attached l_frame.hit_map.hit (3, 4) as h and then h ~ id (13))
				-- Its sub-menu opens next to the scrolled row, shifted up to fit
			s.move_right
			l_frame := render_on_six_rows (s)
			assert ("a.txt", attached l_frame.hit_map.hit (22, 3) as h and then h ~ id (131))
			assert ("b.txt", attached l_frame.hit_map.hit (22, 4) as h and then h ~ id (132))
			s.move_left
				-- Down: Save is disabled, so Quit, the last item: no mark below
			s.move_down
			l_frame := render_on_six_rows (s)
			assert_buffer_lines ("scrolled to Quit", l_frame.buffer, <<
				" File  Edit  Help             ",
				glyphs ("{------------------=}         "),
				glyphs ("| Save     Ctrl+S   |         "),
				glyphs ("|-------------------|         "),
				glyphs ("| Quit     Ctrl+Q   |         "),
				glyphs ("`-------------------^         ")>>)
			assert ("Quit clickable", attached l_frame.hit_map.hit (3, 4) as h and then h ~ id (15))
			s.activate
			assert ("Quit chosen", attached s.chosen as c and then c ~ id (15))
				-- Down from the last item wraps to New: back at the top, no mark above
			s.open
			s.move_up
			l_frame := render_on_six_rows (s)
			assert ("at Quit", s.offset (2) = 4)
			s.move_down
			l_frame := render_on_six_rows (s)
			assert_buffer_lines ("back at the top", l_frame.buffer, <<
				" File  Edit  Help             ",
				glyphs ("{-------------------}         "),
				glyphs ("| New      Ctrl+N   |         "),
				glyphs ("| Open...  Ctrl+O   |         "),
				glyphs ("|-------------------|         "),
				glyphs ("`------------------~^         ")>>)
			assert ("consistent", l_frame.buffer.is_consistent)
		end

	test_menu_hits_safe_in_any_order
			-- While open, the menu's regions are an overlay: a modal registered before it does
			-- not clip them, and a region registered after it hits nothing. Closed, the bar is
			-- clipped by the modal like any background control.
		local
			l_frame: FRAME
			s: MENU_STATE
		do
			s := sample_state
			s.open
			l_frame := new_frame_with_background
			l_frame.hit_map.register_modal (l_frame.area, create {RECT}.make (0, 0, 5, 1))
			l_frame.render_stateful_widget (create {TUI_MENU}, l_frame.area, s)
			assert ("overlay closed", not l_frame.hit_map.is_overlay_open)
			assert ("New not clipped by the modal", attached l_frame.hit_map.hit (3, 2) as h and then h ~ id (11))
			assert ("Help entry not clipped", attached l_frame.hit_map.hit (17, 0) as h and then h ~ id (3))
			l_frame.register_hit (id (91), l_frame.area)
			assert ("registered after: unreachable in the menu", attached l_frame.hit_map.hit (3, 2) as h and then h ~ id (11))
			assert ("registered after: unreachable outside", l_frame.hit_map.hit (25, 10) = Void)
				-- Rendered after the background, a background control rendered after the menu
				-- cannot be clicked through it
			l_frame := new_frame_with_background
			l_frame.render_stateful_widget (create {TUI_MENU}, l_frame.area, s)
			l_frame.render_widget ((create {TUI_CHECKBOX}.make ("Late")).with_hit_id (id (92)), create {RECT}.make (2, 2, 8, 1))
			assert ("late control under New", attached l_frame.hit_map.hit (3, 2) as h and then h ~ id (11))
				-- Closed: the bar is background to the modal
			s.close
			l_frame := new_frame_with_background
			l_frame.hit_map.register_modal (l_frame.area, create {RECT}.make (0, 0, 5, 1))
			l_frame.render_stateful_widget (create {TUI_MENU}, l_frame.area, s)
			assert ("closed: File inside the dialog", attached l_frame.hit_map.hit (2, 0) as h and then h ~ id (1))
			assert ("closed: Help clipped", l_frame.hit_map.hit (17, 0) = Void)
		end

	test_menu_bar_scrolls_sideways
			-- On a bar too narrow for its entries, the last column shows a mark while some
			-- label runs past the edge; the keys reach an entry past the edge and the bar
			-- scrolls to show it whole (a mark in the first column), its drop-down below it;
			-- entries scrolled out are not clickable; going back left scrolls back.
		local
			l_frame: FRAME
			s: MENU_STATE
		do
			s := sample_state
			l_frame := render_on (s, 12, 4)
			assert_buffer_lines ("closed", l_frame.buffer, <<{STRING_32} " File  Edit%/0x25B6/",
				"            ", "            ", "            ">>)
			s.open
			s.move_right
			s.move_right
			l_frame := render_on (s, 12, 4)
			assert ("scrolled by one", s.bar_offset = 1)
			assert_buffer_lines ("Help shown", l_frame.buffer, <<
				{STRING_32} "%/0x25C0/Edit  Help ",
				glyphs ("   {-------}"),
				glyphs ("   | About |"),
				glyphs ("   `-------^")>>)
			assert_cell_style ("Help highlighted", l_frame.buffer, 0, 7, (create {STYLE}).with_reverse)
			assert ("About clickable", attached l_frame.hit_map.hit (5, 2) as h and then h ~ id (31))
			assert ("Help clickable", attached l_frame.hit_map.hit (8, 0) as h and then h ~ id (3))
			assert ("Edit where File was", attached l_frame.hit_map.hit (2, 0) as h and then h ~ id (2))
				-- Left: Edit fits with File, so the bar scrolls back
			s.move_left
			l_frame := render_on (s, 12, 4)
			assert ("scrolled back", s.bar_offset = 0)
			assert_buffer_line ("bar", l_frame.buffer, 0, {STRING_32} " File  Edit%/0x25B6/")
				-- Alt+H from closed: scrolled to Help too
			s.close
			s.open_entry (3)
			l_frame := render_on (s, 12, 4)
			assert ("Alt+letter scrolls", s.bar_offset = 1)
			s.close
			assert ("closed: no scroll", s.bar_offset = 0)
		end

	test_menu_shadow_has_room
			-- With a shadow, each box is placed with room for it: a sub-menu flipped to the
			-- left keeps its shadow off its parent's border, and a drop-down opening upwards
			-- keeps it off the bar.
		local
			l_buf: BUFFER
			s: MENU_STATE
			l_menu: TUI_MENU
		do
			l_menu := (create {TUI_MENU}).with_shadow (create {SHADOW}.make_light_shade)
			s := sample_state
			s.open
			s.move_down
			s.move_down
			s.move_right
				-- File's drop-down shifted one column left for its shadow, Recent's sub-menu flipped
			create l_buf.make (32, 11)
			l_menu.render_stateful (create {RECT}.make (11, 0, 21, 1), l_buf, s)
			assert_cell_symbol ("drop-down shifted for its shadow", l_buf, 1, 10, glyphs ("{"))
			assert_cell_symbol ("its shadow inside the buffer", l_buf, 2, 31, {STRING_32} "%/0x2591/")
			assert_cell_symbol ("sub-menu on the left", l_buf, 5, 0, glyphs ("{"))
			assert_cell_symbol ("sub-menu's shadow", l_buf, 6, 9, {STRING_32} "%/0x2591/")
			assert_cell_symbol ("parent's border kept", l_buf, 6, 10, glyphs ("|"))
			assert_cell_style ("parent's border not shaded", l_buf, 6, 10, create {STYLE})
				-- Upwards from a bar on the last row: the shadow stays above the bar
			s.close
			s.open
			create l_buf.make (30, 12)
			l_menu.render_stateful (create {RECT}.make (0, 11, 30, 1), l_buf, s)
			assert_buffer_line ("bar untouched", l_buf, 11, {STRING_32} " File  Edit  Help             ")
			assert_cell_symbol ("box above", l_buf, 1, 0, glyphs ("{"))
			assert_cell_symbol ("shadow on the row above the bar", l_buf, 10, 1, {STRING_32} "%/0x2591/")
			assert ("consistent", l_buf.is_consistent)
		end

	test_menu_item_label_is_a_copy
			-- `label` gives a copy: changing it does not change the item.
		local
			l_item: MENU_ITEM
			l_label: TEXT_LINE
		do
			l_item := create {MENU_ITEM}.make ("Open")
			l_label := l_item.label
			assert ("equal copy", l_label ~ l_item.label and l_label /= l_item.label)
			l_label.append_text ("ed", create {STYLE})
			assert ("item unchanged", l_item.label.to_plain_string.same_string ("Open") and l_item.label_width = 4)
		end

	render_on (a_state: MENU_STATE; a_width, a_height: INTEGER): FRAME
			-- A `a_width` x `a_height` frame with `a_state`'s menu rendered (and its regions
			-- registered)
		do
			create Result.make (create {BUFFER}.make (a_width, a_height))
			Result.render_stateful_widget (create {TUI_MENU}, Result.area, a_state)
		end

	render_on_six_rows (a_state: MENU_STATE): FRAME
			-- A 30 x 6 frame with `a_state`'s menu rendered (and its regions registered)
		do
			create Result.make (create {BUFFER}.make (30, 6))
			Result.render_stateful_widget (create {TUI_MENU}, Result.area, a_state)
		end

feature -- Example

	test_menu_bar_example
			-- EXAMPLE_MENU_BAR on a 40 x 12 frame: the bar over the panel; Tab moves the
			-- panel's focus; F10 opens File (drawn over the panel, with its shadow) and Tab is
			-- trapped; Down, Down, Right opens Recent; Enter chooses notes.txt, closes the menu
			-- and gives the focus back; Alt+V then Enter toggles "Wrap lines".
		local
			l_app: MENU_BAR_SNAPSHOT_APP
			l_buf: BUFFER
			l_backend: ANSI_TERMINAL_BACKEND
			l_rule: STRING_32
		do
			create l_backend.make_with_driver_and_sink (create {FAKE_CONSOLE_DRIVER}, create {STRING_32}.make_empty)
			create l_app.make_on (create {TERMINAL [ANSI_TERMINAL_BACKEND]}.make_with_viewport (l_backend, create {VIEWPORT}.make_fullscreen))
			create l_buf.make (40, 12)
			l_app.render_now (create {FRAME}.make (l_buf))
			assert_buffer_lines ("start", l_buf, <<
				" File  Edit  View  Help                 ",
				{STRING_32} "%/0x256D/ Editor " + repeated ('%/0x2500/', 30) + {STRING_32} "%/0x256E/",
				glyphs ("|                                      |"),
				glyphs ("|[x] Wrap lines                        |"),
				glyphs ("|[ ] Show line numbers                 |"),
				glyphs ("|                                      |"),
				glyphs ("|Last command: (none)                  |")>>)
			assert ("wrap focused", l_app.is_focused_id (1))
			l_app.process_now (create {KEY_EVENT}.make_special ({KEY_CODE}.Tab))
			assert ("Tab moves the panel's focus", l_app.is_focused_id (2))
			l_app.process_now (create {KEY_EVENT}.make_special (create {KEY_CODE}.make_function (10)))
			assert ("F10 opens", l_app.menu.is_open and not l_app.has_focus)
			l_app.process_now (create {KEY_EVENT}.make_special ({KEY_CODE}.Tab))
			assert ("Tab trapped", not l_app.has_focus and l_app.menu.is_open)
			create l_buf.make (40, 12)
			l_app.render_now (create {FRAME}.make (l_buf))
			l_rule := repeated ('%/0x2500/', 38)
			assert_buffer_lines ("File open", l_buf, <<
				" File  Edit  View  Help                 ",
				glyphs ("{-------------------}") + l_rule.substring (21, 38) + {STRING_32} "%/0x256E/",
				glyphs ("| New      Ctrl+N   |#                 |"),
				glyphs ("| Open...  Ctrl+O   |#                 |")>>)
			assert_buffer_line ("shadow row", l_buf, 10, glyphs ("|#####################                 |"))
			l_app.process_now (create {KEY_EVENT}.make_special ({KEY_CODE}.Down))
			l_app.process_now (create {KEY_EVENT}.make_special ({KEY_CODE}.Down))
			l_app.process_now (create {KEY_EVENT}.make_special ({KEY_CODE}.Right))
			create l_buf.make (40, 12)
			l_app.render_now (create {FRAME}.make (l_buf))
			assert_buffer_line ("Recent opened", l_buf, 5, glyphs ("| Recent          @ |{-----------}     |"))
			assert_buffer_line ("its first item", l_buf, 6, glyphs ("| Save     Ctrl+S   || notes.txt |#    |"))
			l_app.process_now (create {KEY_EVENT}.make_special ({KEY_CODE}.Enter))
			assert ("closed", not l_app.menu.is_open)
			assert ("focus back", l_app.is_focused_id (2))
			assert ("command", l_app.last_command.same_string ("notes.txt"))
			l_app.process_now (create {KEY_EVENT}.make (create {KEY_CODE}.make_char ('v'), create {MODIFIERS}.make_with_bits (4)))
			assert ("Alt+V opens View", l_app.menu.is_open and l_app.menu.selected (1) = 3)
			l_app.process_now (create {KEY_EVENT}.make_special ({KEY_CODE}.Enter))
			create l_buf.make (40, 12)
			l_app.render_now (create {FRAME}.make (l_buf))
			assert_buffer_line ("wrap off", l_buf, 3, glyphs ("|[ ] Wrap lines                        |"))
			assert_buffer_line ("status", l_buf, 6, glyphs ("|Last command: Wrap lines              |"))
			assert ("consistent", l_buf.is_consistent)
		end

	test_menu_bar_quit_asks_first
			-- P2b U3: File > Quit in EXAMPLE_MENU_BAR opens the "Quit?" confirmation, the first
			-- dialog opened from a menu item: the menu's focus scope is popped before the
			-- dialog's is pushed. Esc answers No and keeps running (the panel's focus comes
			-- back); Quit again, then y, stops.
		local
			l_app: MENU_BAR_SNAPSHOT_APP
			l_buf: BUFFER
			l_frame: FRAME
			l_backend: ANSI_TERMINAL_BACKEND
		do
			create l_backend.make_with_driver_and_sink (create {FAKE_CONSOLE_DRIVER}, create {STRING_32}.make_empty)
			create l_app.make_on (create {TERMINAL [ANSI_TERMINAL_BACKEND]}.make_with_viewport (l_backend, create {VIEWPORT}.make_fullscreen))
			assert ("one scope at start", l_app.scope_depth = 1)
				-- F10 opens File at New; Up wraps round to Quit; Enter chooses it
			l_app.process_now (create {KEY_EVENT}.make_special (create {KEY_CODE}.make_function (10)))
			l_app.process_now (create {KEY_EVENT}.make_special ({KEY_CODE}.Up))
			assert ("menu open, its scope pushed", l_app.menu.is_open and l_app.scope_depth = 2)
			l_app.process_now (create {KEY_EVENT}.make_special ({KEY_CODE}.Enter))
			assert ("menu closed", not l_app.menu.is_open)
			assert ("dialog open", l_app.quit_dialog.is_open)
			assert ("menu scope popped, dialog scope pushed", l_app.scope_depth = 2 and l_app.quit_dialog.has_scope
				and l_app.quit_dialog.is_scope_innermost)
			assert ("No focused", l_app.is_focused_widget (l_app.quit_dialog.button_id (2)))
			assert ("still running", l_app.stop_count = 0)
			create l_buf.make (40, 12)
			create l_frame.make (l_buf)
			l_app.render_now (l_frame)
				-- The box fits "[ Yes ]  [ No ]" (15) + 4 = 19 wide, 1 message row + 4 = 5 high,
				-- centred at ((40 - 19) // 2, (12 - 5) // 2) = (10, 3), over the panel
			assert_buffer_line ("dialog top", l_buf, 3, {STRING_32} "%/0x2502/[x] Wrap %/0x250C/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/ Quit %/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2510/          %/0x2502/")
			assert_buffer_line ("dialog message", l_buf, 4, {STRING_32} "%/0x2502/[ ] Show %/0x2502/      Quit?      %/0x2502/          %/0x2502/")
			assert_buffer_line ("dialog blank", l_buf, 5, {STRING_32} "%/0x2502/         %/0x2502/                 %/0x2502/          %/0x2502/")
			assert_buffer_line ("dialog buttons", l_buf, 6, {STRING_32} "%/0x2502/Last comm%/0x2502/ [ Yes ]  [ No ] %/0x2502/          %/0x2502/")
			assert_buffer_line ("dialog bottom", l_buf, 7, {STRING_32} "%/0x2502/         %/0x2514/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2500/%/0x2518/          %/0x2502/")
			assert ("checkbox behind blocked", l_frame.hit_map.hit (5, 3) = Void)
			assert ("bar behind blocked", l_frame.hit_map.hit (2, 0) = Void)
			assert ("Yes clickable", attached l_frame.hit_map.hit (14, 6) as h and then h ~ l_app.quit_dialog.button_id (1))
			assert ("No clickable", attached l_frame.hit_map.hit (23, 6) as h and then h ~ l_app.quit_dialog.button_id (2))
				-- Tab and the panel's keys stay in the dialog
			l_app.process_now (create {KEY_EVENT}.make_special ({KEY_CODE}.Tab))
			assert ("Tab moves to Yes", l_app.is_focused_widget (l_app.quit_dialog.button_id (1)))
			l_app.process_now (create {KEY_EVENT}.make_special ({KEY_CODE}.Tab))
			assert ("Tab stays in the dialog", l_app.is_focused_widget (l_app.quit_dialog.button_id (2)))
			l_app.process_now (create {KEY_EVENT}.make_char ('q'))
			assert ("q swallowed", l_app.quit_dialog.is_open and l_app.stop_count = 0)
				-- Esc: No, keeps running
			l_app.process_now (create {KEY_EVENT}.make_special ({KEY_CODE}.Escape))
			assert ("Esc closes", not l_app.quit_dialog.is_open and l_app.quit_dialog.answer = 2)
			assert ("Esc keeps running", l_app.stop_count = 0)
			assert ("scope popped", l_app.scope_depth = 1)
			assert ("panel focus back", l_app.is_focused_id (1))
			assert ("command", l_app.last_command.same_string ("Quit: no"))
			create l_buf.make (40, 12)
			l_app.render_now (create {FRAME}.make (l_buf))
			assert_buffer_line ("dialog gone", l_buf, 3, glyphs ("|[x] Wrap lines                        |"))
				-- Quit again, then y: stops
			l_app.process_now (create {KEY_EVENT}.make_special (create {KEY_CODE}.make_function (10)))
			l_app.process_now (create {KEY_EVENT}.make_special ({KEY_CODE}.Up))
			l_app.process_now (create {KEY_EVENT}.make_special ({KEY_CODE}.Enter))
			assert ("asks again", l_app.quit_dialog.is_open and not l_app.menu.is_open)
			l_app.process_now (create {KEY_EVENT}.make_char ('y'))
			assert ("y answers Yes", not l_app.quit_dialog.is_open and l_app.quit_dialog.answer = 1)
			assert ("y stops", l_app.stop_count = 1)
			assert ("scope popped again", l_app.scope_depth = 1)
		end

	test_menu_bar_q_asks_too
			-- With the menu closed, q and Esc in the panel open the same "Quit?" confirmation
			-- as File > Quit instead of stopping at once: n keeps running, Esc then y stops.
		local
			l_app: MENU_BAR_SNAPSHOT_APP
			l_backend: ANSI_TERMINAL_BACKEND
		do
			create l_backend.make_with_driver_and_sink (create {FAKE_CONSOLE_DRIVER}, create {STRING_32}.make_empty)
			create l_app.make_on (create {TERMINAL [ANSI_TERMINAL_BACKEND]}.make_with_viewport (l_backend, create {VIEWPORT}.make_fullscreen))
			l_app.process_now (create {KEY_EVENT}.make_char ('q'))
			assert ("q asks", l_app.quit_dialog.is_open and l_app.stop_count = 0 and l_app.scope_depth = 2)
			l_app.process_now (create {KEY_EVENT}.make_char ('n'))
			assert ("n keeps running", not l_app.quit_dialog.is_open and l_app.stop_count = 0 and l_app.scope_depth = 1)
			l_app.process_now (create {KEY_EVENT}.make_special ({KEY_CODE}.Escape))
			assert ("Esc asks", l_app.quit_dialog.is_open and l_app.stop_count = 0)
			l_app.process_now (create {KEY_EVENT}.make_char ('y'))
			assert ("y stops", not l_app.quit_dialog.is_open and l_app.stop_count = 1)
		end

feature {NONE} -- Click support

	click_state: MENU_STATE
			-- The menu of `test_menu_clicks_fixed_viewport`
		attribute
			create Result
		end

	click_points: ARRAY [TUPLE [col, row: INTEGER]]
			-- Screen positions of the presses, in order
		attribute
			Result := <<>>
		end

	click_next: INTEGER
			-- Index in `click_points` of the next press to post

	click_handled: INTEGER
			-- Presses handled so far

	click_frames: INTEGER
			-- Frames drawn so far

	Click_frame_cap: INTEGER = 2000
			-- Frames after which the test stops instead of hanging

	click_log: ARRAYED_LIST [STRING]
			-- What each press did
		attribute
			create Result.make (12)
			Result.compare_objects
		end

	draw_click_frame (a_frame: FRAME; a_app: TEST_TUI_APP_IMPL)
			-- Background boxes, then the menu; post the next press once the previous one was
			-- handled, and stop after the last one.
		local
			l_box: TUI_CHECKBOX
		do
			create l_box.make ("Back")
			a_frame.render_widget (l_box.with_hit_id (id (90)), create {RECT}.make (2, 4, l_box.width.to_natural_16, 1))
			create l_box.make ("Out")
			a_frame.render_widget (l_box.with_hit_id (id (91)), create {RECT}.make (22, 10, l_box.width.to_natural_16, 1))
			a_frame.render_stateful_widget (create {TUI_MENU}, a_frame.area, click_state)
			click_frames := click_frames + 1
			if click_frames >= Click_frame_cap then
				a_app.stop
			elseif click_handled = click_next - 1 then
				if click_next <= click_points.count then
					a_app.post_event (create {MOUSE_EVENT}.make ({MOUSE_EVENT}.Kind_down, {MOUSE_EVENT}.Button_left,
						click_points [click_next].col.to_natural_16, click_points [click_next].row.to_natural_16,
						create {MODIFIERS}))
					click_next := click_next + 1
				else
					a_app.stop
				end
			end
		end

	on_click (m: MOUSE_EVENT; a_app: TEST_TUI_APP_IMPL)
			-- MENU_STATE's mouse recipe; log the result.
		local
			l_hit: detachable WIDGET_ID
			l_entry: STRING
		do
			if m.is_down then
				l_hit := a_app.hit_test (m)
				if click_state.handles (l_hit) then
					click_state.click (l_hit)
					l_entry := "menu " + id_text (l_hit) + " " + click_state.depth.out
					if attached click_state.chosen as c then
						l_entry.append (" chosen " + c.out)
						click_state.clear_chosen
					end
				else
					l_entry := "bg " + id_text (l_hit)
				end
				click_log.extend (l_entry)
				click_handled := click_handled + 1
			end
		end

	id_text (a_id: detachable WIDGET_ID): STRING
			-- "void" or the id's value
		do
			if attached a_id as l_id then
				Result := l_id.out
			else
				Result := "void"
			end
		end

	assert_log (a_expected: ARRAY [STRING])
			-- `click_log` is exactly `a_expected`, in order.
		local
			i: INTEGER
		do
			assert ("log has " + a_expected.count.out + " entries, not " + click_log.count.out,
				click_log.count = a_expected.count)
			from i := 1 until i > a_expected.count or i > click_log.count loop
				assert ("entry " + i.out + " is " + a_expected [i] + ", not " + click_log [i], click_log [i] ~ a_expected [i])
				i := i + 1
			end
		end

feature {NONE} -- Helpers

	sample_items: ARRAY [MENU_ITEM]
			-- File (1): New (11), Open... (12), separator, Recent (13: a.txt 131, b.txt 132),
			-- Save (14, disabled), separator, Quit (15); Edit (2): Undo (21), Redo (22,
			-- disabled), separator, Cut (23), Copy (24), Paste (25); Help (3): About (31)
		do
			Result := <<
				(create {MENU_ITEM}.make_submenu ("File", <<
					(create {MENU_ITEM}.make ("New")).with_shortcut ("Ctrl+N").with_id (id (11)),
					(create {MENU_ITEM}.make ("Open...")).with_shortcut ("Ctrl+O").with_id (id (12)),
					create {MENU_ITEM}.make_separator,
					(create {MENU_ITEM}.make_submenu ("Recent", <<(create {MENU_ITEM}.make ("a.txt")).with_id (id (131)),
						(create {MENU_ITEM}.make ("b.txt")).with_id (id (132))>>)).with_id (id (13)),
					(create {MENU_ITEM}.make ("Save")).with_shortcut ("Ctrl+S").with_enabled (False).with_id (id (14)),
					create {MENU_ITEM}.make_separator,
					(create {MENU_ITEM}.make ("Quit")).with_shortcut ("Ctrl+Q").with_id (id (15))>>)).with_id (id (1)),
				(create {MENU_ITEM}.make_submenu ("Edit", <<
					(create {MENU_ITEM}.make ("Undo")).with_shortcut ("Ctrl+Z").with_id (id (21)),
					(create {MENU_ITEM}.make ("Redo")).with_enabled (False).with_id (id (22)),
					create {MENU_ITEM}.make_separator,
					(create {MENU_ITEM}.make ("Cut")).with_id (id (23)),
					(create {MENU_ITEM}.make ("Copy")).with_id (id (24)),
					(create {MENU_ITEM}.make ("Paste")).with_id (id (25))>>)).with_id (id (2)),
				(create {MENU_ITEM}.make_submenu ("Help", <<(create {MENU_ITEM}.make ("About")).with_id (id (31))>>)).with_id (id (3))
			>>
		end

	sample_state: MENU_STATE
			-- A closed state on `sample_items`
		do
			create Result.make (sample_items)
		end

	file_menu_rows: ARRAY [READABLE_STRING_GENERAL]
			-- Rows of a 30 x 11 buffer with File open at New
		do
			Result := <<
				" File  Edit  Help             ",
				glyphs ("{-------------------}         "),
				glyphs ("| New      Ctrl+N   |         "),
				glyphs ("| Open...  Ctrl+O   |         "),
				glyphs ("|-------------------|         "),
				glyphs ("| Recent          @ |         "),
				glyphs ("| Save     Ctrl+S   |         "),
				glyphs ("|-------------------|         "),
				glyphs ("| Quit     Ctrl+Q   |         "),
				glyphs ("`-------------------^         "),
				"                              ">>
		end

	new_frame_with_background: FRAME
			-- A 30 x 11 frame whose whole area is registered under id 90
		do
			create Result.make (create {BUFFER}.make (30, 11))
			Result.register_hit (id (90), Result.area)
		end

	place (a_x, a_y, a_w, a_width, a_height: INTEGER; a_side: NATURAL_8; a_bounds: RECT): RECT
			-- Placement of a `a_width` x `a_height` box next to a one-row anchor at (`a_x`, `a_y`),
			-- `a_w` wide
		do
			Result := {OVERLAY_PLACEMENT}.placement (create {RECT}.make (a_x.to_natural_16, a_y.to_natural_16, a_w.to_natural_16, 1),
				a_width.to_natural_16, a_height.to_natural_16, a_side, a_bounds)
		end

	assert_rect (a_tag: STRING; a_rect: RECT; a_x, a_y, a_w, a_h: INTEGER)
			-- `a_rect` is (`a_x`, `a_y`, `a_w`, `a_h`).
		do
			assert (a_tag + ": " + a_rect.out, a_rect.x = a_x and a_rect.y = a_y and a_rect.width = a_w and a_rect.height = a_h)
		end

	assert_path (a_tag: STRING; a_state: MENU_STATE; a_expected: ARRAY [INTEGER])
			-- The open path of `a_state` is `a_expected`.
		local
			l_text: STRING
		do
			create l_text.make_empty
			across a_state.path as p loop
				l_text.append (p.out + " ")
			end
			assert (a_tag + " (path " + l_text + ")", a_state.path.count = a_expected.count
				and then across 1 |..| a_expected.count as i all a_state.path [i] = a_expected [i] end)
		end

	assert_buffer_line (a_tag: STRING; a_buf: BUFFER; a_row: INTEGER; a_expected: STRING_32)
			-- Row `a_row` of `a_buf` is `a_expected`.
		do
			assert (a_tag + ": [" + {UTF_CONVERTER}.string_32_to_utf_8_string_8 (buffer_row_as_string (a_buf, a_row)) + "]",
				buffer_row_as_string (a_buf, a_row).same_string (a_expected))
		end

	id (a_value: INTEGER): WIDGET_ID
			-- A new id of `a_value`
		do
			create Result.make (a_value)
		end

	raises (a_action: ROUTINE): BOOLEAN
			-- Does `a_action` raise an exception?
		local
			l_tried: BOOLEAN
		do
			if not l_tried then
				a_action.call
			end
		rescue
			l_tried := True
			Result := True
			retry
		end

	glyphs (a_pattern: STRING_8): STRING_32
			-- `a_pattern` with '{' U+250C, '}' U+2510, '`' U+2514, '^' U+2518, '-' U+2500, '|'
			-- U+2502, '@' U+25B8, '#' U+2591, '=' U+25B2 and '~' U+25BC; other characters as
			-- they are.
		local
			i: INTEGER
		do
			create Result.make (a_pattern.count)
			from i := 1 until i > a_pattern.count loop
				inspect a_pattern [i]
				when '{' then Result.append_character ((0x250C).to_character_32)
				when '}' then Result.append_character ((0x2510).to_character_32)
				when '`' then Result.append_character ((0x2514).to_character_32)
				when '^' then Result.append_character ((0x2518).to_character_32)
				when '-' then Result.append_character ((0x2500).to_character_32)
				when '|' then Result.append_character ((0x2502).to_character_32)
				when '@' then Result.append_character ((0x25B8).to_character_32)
				when '#' then Result.append_character ((0x2591).to_character_32)
				when '=' then Result.append_character ((0x25B2).to_character_32)
				when '~' then Result.append_character ((0x25BC).to_character_32)
				else Result.append_character (a_pattern [i].to_character_32)
				end
				i := i + 1
			end
		end

	repeated (a_char: CHARACTER_32; a_count: INTEGER): STRING_32
			-- `a_char` `a_count` times
		do
			create Result.make_filled (a_char, a_count)
		end

	new_app (a_viewport: VIEWPORT): TEST_TUI_APP_IMPL
			-- Application on a fake console with no scripted input, output captured.
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_sink: STRING_32
			l_backend: ANSI_TERMINAL_BACKEND
		do
			create l_driver
			create l_sink.make_empty
			l_driver.watch_sink (l_sink)
			create l_backend.make_with_driver_and_sink (l_driver, l_sink)
			create Result.make_with_terminal (create {TERMINAL [ANSI_TERMINAL_BACKEND]}.make_with_viewport (l_backend, a_viewport))
			Result.event_thread.set_poll_interval (5)
		end

end
