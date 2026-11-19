note
	description: "[
		P2b item R1, the TUI_BREADCRUMB widget (review/p2b_clipboard_dialog_breadcrumb_plan.md).
		Ratatui has no breadcrumb widget, so these are EiffelTUI's own row-exact buffer
		snapshots: a path that fits; the middle collapse of decision Q6 at chosen widths, and
		at every width from the full length down to 1 against a plain-string model of the rule
		(with `crumb_areas`, `crumb_at`, `visible_crumbs` and `ellipsis_area` checked against
		what is drawn); wide characters and combining marks; the separator presets; the styles
		of the current, selected and separator cells; the hit regions registered through FRAME
		for the visible crumbs only; one crumb and no crumbs; the `with_*` builders.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_BREADCRUMB

inherit
	BUFFER_TEST_HELPER

feature -- Layout

	test_breadcrumb_path_that_fits
			-- The whole path from the left edge, " " U+203A " " between crumbs; the rest of the
			-- row and the other rows keep what they had; `width` is crumbs plus separators.
		local
			l_bc: TUI_BREADCRUMB
			l_buf: BUFFER
		do
			create l_bc.make (<<"home", "user", "tui">>)
			assert ("count", l_bc.count = 3)
			assert ("width", l_bc.width = 4 + 4 + 3 + 2 * 3)
			create l_buf.make (20, 2)
			l_buf.put_string (0, 0, "####################", create {STYLE})
			l_buf.put_string (1, 0, "####################", create {STYLE})
			l_bc.render (create {RECT}.make (1, 0, 18, 2), l_buf)
			assert_buffer_lines ("fits", l_buf, <<{STRING_32} "#home %/0x203A/ user %/0x203A/ tui##", "####################">>)
			assert ("consistent", l_buf.is_consistent)
			assert ("not collapsed", not l_bc.is_collapsed (create {RECT}.make (1, 0, 18, 2)))
			assert ("no ellipsis", l_bc.ellipsis_area (create {RECT}.make (1, 0, 18, 2)) = Void)
			assert ("all visible", l_bc.visible_crumbs (create {RECT}.make (1, 0, 18, 2)).count = 3)
				-- Exactly as wide as the path
			check_row ("exact", l_bc.with_separator (" > "), 17, "home > user > tui")
		end

	test_breadcrumb_collapses_middle
			-- "home > user > projects > eiffel > tui" is 37 wide. Narrower: the first crumb,
			-- U+2026, the longest run of last crumbs that fits; then the first crumb, U+2026 and
			-- the last crumb cut; then the last crumb cut alone, down to one cell.
		local
			l_bc: TUI_BREADCRUMB
			e: STRING_32
		do
			e := {STRING_32} "%/0x2026/"
			l_bc := (create {TUI_BREADCRUMB}.make (<<"home", "user", "projects", "eiffel", "tui">>)).with_separator (" > ")
			assert ("full width", l_bc.width = 37)
			check_row ("37", l_bc, 37, "home > user > projects > eiffel > tui")
			check_row ("36", l_bc, 36, {STRING_32} "home > " + e + " > projects > eiffel > tui  ")
			check_row ("34", l_bc, 34, {STRING_32} "home > " + e + " > projects > eiffel > tui")
			check_row ("33", l_bc, 33, {STRING_32} "home > " + e + " > eiffel > tui          ")
			check_row ("23", l_bc, 23, {STRING_32} "home > " + e + " > eiffel > tui")
			check_row ("22", l_bc, 22, {STRING_32} "home > " + e + " > tui        ")
			check_row ("14", l_bc, 14, {STRING_32} "home > " + e + " > tui")
			check_row ("13", l_bc, 13, {STRING_32} "home > " + e + " > tu")
			check_row ("12", l_bc, 12, {STRING_32} "home > " + e + " > t")
			check_row ("11", l_bc, 11, "tui        ")
			check_row ("3", l_bc, 3, "tui")
			check_row ("2", l_bc, 2, "tu")
			check_row ("1", l_bc, 1, "t")
			assert ("ellipsis at 7", attached l_bc.ellipsis_area (create {RECT}.make (0, 0, 22, 1)) as r
				and then r ~ create {RECT}.make (7, 0, 1, 1))
			assert ("collapsed", l_bc.is_collapsed (create {RECT}.make (0, 0, 22, 1)))
			assert ("visible 22", same_indices (l_bc.visible_crumbs (create {RECT}.make (0, 0, 22, 1)), <<1, 5>>))
			assert ("visible 33", same_indices (l_bc.visible_crumbs (create {RECT}.make (0, 0, 33, 1)), <<1, 4, 5>>))
			assert ("visible 11", same_indices (l_bc.visible_crumbs (create {RECT}.make (0, 0, 11, 1)), <<5>>))
				-- Two crumbs: nothing in the middle, so no U+2026 when the last one is cut
			l_bc := (create {TUI_BREADCRUMB}.make (<<"home", "documents">>)).with_separator (" > ")
			check_row ("two fit", l_bc, 16, "home > documents")
			check_row ("two cut", l_bc, 10, "home > doc")
			check_row ("two only last", l_bc, 7, "documen")
			assert ("two no ellipsis", l_bc.ellipsis_area (create {RECT}.make (0, 0, 10, 1)) = Void)
		end

	test_breadcrumb_every_width
			-- For several paths and both separator kinds, at every width from the full length
			-- down to 1: the row is what the plain-string model of the rule gives, the cells
			-- right of it are untouched, and `crumb_areas` / `crumb_at` / `visible_crumbs` /
			-- `ellipsis_area` agree with the model and with the drawn row.
		do
			check_every_width ("five", <<"home", "user", "projects", "eiffel", "tui">>, " > ")
			check_every_width ("five slash", <<"home", "user", "projects", "eiffel", "tui">>, " / ")
			check_every_width ("chevron", <<"src", "library", "widgets", "breadcrumb">>, {STRING_32} " %/0x203A/ ")
			check_every_width ("long root", <<"a_very_long_root_name", "b", "c", "d">>, " > ")
			check_every_width ("long last", <<"r", "x", "a_very_long_current_place">>, " > ")
			check_every_width ("two", <<"home", "documents">>, " > ")
			check_every_width ("three", <<"a", "bb", "ccc">>, " > ")
			check_every_width ("one", <<"single">>, " > ")
			check_every_width ("no blanks", <<"aa", "bb", "cc", "dd", "ee", "ff">>, "/")
			check_every_width ("empty separator", <<"aa", "bb", "cc", "dd">>, "")
		end

	test_breadcrumb_wide_and_combining
			-- A wide character takes two cells; a base and its combining mark one cell. The last
			-- crumb is cut per grapheme cluster: a wide character crossing the edge is left out,
			-- and the cut is taken only when at least one cluster is drawn.
		local
			l_bc: TUI_BREADCRUMB
			w, e, c: STRING_32
		do
			w := {STRING_32} "%/0x4E16/%/0x754C/"
			e := {STRING_32} "%/0x2026/"
			c := {STRING_32} "cafe%/0x301/"
			l_bc := (create {TUI_BREADCRUMB}.make (<<{STRING_32} "src", w, c>>)).with_separator (" / ")
			assert ("wide width", l_bc.width = 3 + 3 + 4 + 3 + 4)
			check_row ("whole", l_bc, 17, {STRING_32} "src / %/0x4E16/%/0x754C/ / " + c)
			check_row ("16", l_bc, 16, {STRING_32} "src / " + e + " / " + c + "  ")
			check_row ("13", l_bc, 13, {STRING_32} "src / " + e + " / caf")
			check_row ("11", l_bc, 11, {STRING_32} "src / " + e + " / c")
			check_row ("10", l_bc, 10, c + "      ")
			check_row ("4", l_bc, 4, c)
			check_row ("1", l_bc, 1, "c")
			check_areas ("combining cut", l_bc, 4, <<0, 0, 4>>, <<0, 0, 0>>)
				-- A wide last crumb
			l_bc := (create {TUI_BREADCRUMB}.make (<<{STRING_32} "a", {STRING_32} "b", w>>)).with_separator (" / ")
			check_row ("wide fits", l_bc, 12, {STRING_32} "a / b / " + w)
			check_row ("wide cut", l_bc, 11, {STRING_32} "a / " + e + " / %/0x4E16/ ")
			check_areas ("wide cut areas", l_bc, 11, <<1, 0, 2>>, <<0, 0, 8>>)
			check_row ("wide crosses the edge", l_bc, 9, w + "     ")
			check_row ("wide in 3", l_bc, 3, {STRING_32} "%/0x4E16/ ")
			check_row ("nothing in 1", l_bc, 1, " ")
			assert ("nothing visible in 1", l_bc.visible_crumbs (create {RECT}.make (0, 0, 1, 1)).is_empty)
			assert ("no crumb at 0", l_bc.crumb_at (create {RECT}.make (0, 0, 1, 1), 0) = 0)
				-- Wide characters in a middle crumb shown with the tail
			l_bc := (create {TUI_BREADCRUMB}.make (<<{STRING_32} "r", {STRING_32} "x", {STRING_32} "y", w, {STRING_32} "z">>)).with_separator (" > ")
			assert ("wide middle width", l_bc.width = 20)
			check_row ("wide middle", l_bc, 16, {STRING_32} "r > " + e + " > " + w + " > z")
			assert ("wide crumb area", attached l_bc.crumb_areas (create {RECT}.make (0, 0, 16, 1)) [4] as r
				and then r ~ create {RECT}.make (8, 0, 4, 1))
			assert ("wide crumb at its last cell", l_bc.crumb_at (create {RECT}.make (0, 0, 16, 1), 11) = 4)
		end

	test_breadcrumb_separator_presets
			-- The default " " U+203A " " and the ASCII " > " and " / " presets, each three
			-- columns; any separator without control characters.
		local
			l_bc: TUI_BREADCRUMB
		do
			create l_bc.make (<<"a", "b">>)
			assert ("default chevron", l_bc.separator.same_string ({BREADCRUMB_SYMBOLS}.chevron))
			check_row ("chevron", l_bc, 5, {STRING_32} "a %/0x203A/ b")
			check_row ("arrow", l_bc.with_separator ({BREADCRUMB_SYMBOLS}.arrow), 5, "a > b")
			check_row ("slash", l_bc.with_separator ({BREADCRUMB_SYMBOLS}.slash), 5, "a / b")
			check_row ("own", l_bc.with_separator ("::"), 4, "a::b")
			check_row ("none", l_bc.with_separator (""), 2, "ab")
			assert ("ellipsis one column", {UNICODE_WIDTH}.string_width ({BREADCRUMB_SYMBOLS}.ellipsis) = 1)
			assert ("separator width", l_bc.separator_width = 3)
			assert ("valid separator", {TUI_BREADCRUMB}.is_valid_separator (" > "))
			assert ("control separator", not {TUI_BREADCRUMB}.is_valid_separator ("%T"))
			assert ("C1 crumb", not {TUI_BREADCRUMB}.is_valid_crumb ({STRING_32} "a%/0x9B/"))
			assert ("empty crumb valid", {TUI_BREADCRUMB}.is_valid_crumb (""))
				-- Presets are new strings each time
			assert ("fresh preset", {BREADCRUMB_SYMBOLS}.chevron /= {BREADCRUMB_SYMBOLS}.chevron)
		end

	test_breadcrumb_styles
			-- Crumbs take `style`; the last one `current_style` too (bold by default); crumb
			-- `selected` `selected_style` too (reversed by default); separators and U+2026
			-- `separator_style`. Styles are patched over the cells' own; the cells not drawn
			-- keep theirs. A selected crumb hidden in the middle reverses U+2026 instead.
		local
			l_bc: TUI_BREADCRUMB
			l_buf: BUFFER
			l_red, l_blue, l_bg: STYLE
		do
			create l_red.make_fg ({COLOR}.Red)
			create l_blue.make_fg ({COLOR}.Blue)
			create l_bg.make_bg ({COLOR}.Green)
			l_bc := (create {TUI_BREADCRUMB}.make (<<"a", "bb", "c">>)).with_separator (" > ")
				-- Defaults: "a > bb > c"
			create l_buf.make (12, 1)
			l_bc.render (create {RECT}.make (0, 0, 12, 1), l_buf)
			assert_buffer_lines ("defaults", l_buf, <<"a > bb > c  ">>)
			assert_cell_style ("first plain", l_buf, 0, 0, create {STYLE})
			assert_cell_style ("separator plain", l_buf, 0, 2, create {STYLE})
			assert_cell_style ("middle plain", l_buf, 0, 4, create {STYLE})
			assert_cell_style ("current bold", l_buf, 0, 9, (create {STYLE}).with_bold)
			assert_cell_style ("after the path", l_buf, 0, 10, create {STYLE})
				-- Own styles, patched over a background
			create l_buf.make (12, 1)
			l_buf.set_style (l_buf.area, l_bg)
			l_bc.with_style (l_red).with_separator_style (l_blue).with_selected (2).render (create {RECT}.make (0, 0, 12, 1), l_buf)
			assert_cell_style ("crumb red", l_buf, 0, 0, create {STYLE}.make_with_colors ({COLOR}.Red, {COLOR}.Green))
			assert_cell_style ("separator blank blue", l_buf, 0, 1, create {STYLE}.make_with_colors ({COLOR}.Blue, {COLOR}.Green))
			assert_cell_style ("separator blue", l_buf, 0, 2, create {STYLE}.make_with_colors ({COLOR}.Blue, {COLOR}.Green))
			assert_cell_style ("selected reversed", l_buf, 0, 4,
				(create {STYLE}.make_with_colors ({COLOR}.Red, {COLOR}.Green)).with_reverse)
			assert_cell_style ("selected second cell", l_buf, 0, 5,
				(create {STYLE}.make_with_colors ({COLOR}.Red, {COLOR}.Green)).with_reverse)
			assert_cell_style ("current red bold", l_buf, 0, 9,
				(create {STYLE}.make_with_colors ({COLOR}.Red, {COLOR}.Green)).with_bold)
			assert_cell_style ("background kept", l_buf, 0, 11, l_bg)
				-- The current crumb selected: bold and reversed
			create l_buf.make (12, 1)
			l_bc.with_selected (3).render (create {RECT}.make (0, 0, 12, 1), l_buf)
			assert_cell_style ("current selected", l_buf, 0, 9, (create {STYLE}).with_bold.with_reverse)
			assert_cell_style ("middle not selected", l_buf, 0, 4, create {STYLE})
				-- Own current and selected styles
			create l_buf.make (12, 1)
			l_bc.with_current_style (l_blue).with_selected_style (l_red).with_selected (1).render (create {RECT}.make (0, 0, 12, 1), l_buf)
			assert_cell_style ("own selected", l_buf, 0, 0, l_red)
			assert_cell_style ("own current", l_buf, 0, 9, l_blue)
				-- A styled crumb line is patched over the crumb's style
			create l_buf.make (6, 1)
			(create {TUI_BREADCRUMB}.make_with_lines (<<create {TEXT_LINE}.make_styled ("x", l_bg), create {TEXT_LINE}.make_raw ("y")>>))
				.with_separator ("/").with_style (l_red).render (create {RECT}.make (0, 0, 6, 1), l_buf)
			assert_buffer_lines ("lines", l_buf, <<"x/y   ">>)
			assert_cell_style ("line style over crumb style", l_buf, 0, 0, create {STYLE}.make_with_colors ({COLOR}.Red, {COLOR}.Green))
				-- The selected crumb hidden: U+2026 shows it. "root > ... > z" in 12
			l_bc := (create {TUI_BREADCRUMB}.make (<<"root", "x", "y", "z">>)).with_separator (" > ")
			create l_buf.make (12, 1)
			l_bc.with_separator_style (l_blue).with_selected (2).render (create {RECT}.make (0, 0, 12, 1), l_buf)
			assert_buffer_lines ("hidden selected", l_buf, <<{STRING_32} "root > %/0x2026/ > z">>)
			assert_cell_style ("ellipsis selected", l_buf, 0, 7, l_blue.with_reverse)
			assert_cell_style ("separator not selected", l_buf, 0, 5, l_blue)
			create l_buf.make (12, 1)
			l_bc.with_separator_style (l_blue).with_selected (4).render (create {RECT}.make (0, 0, 12, 1), l_buf)
			assert_cell_style ("ellipsis plain when visible selected", l_buf, 0, 7, l_blue)
			assert_cell_style ("last selected", l_buf, 0, 11, (create {STYLE}).with_bold.with_reverse)
			assert ("crumb style", l_bc.with_selected (4).crumb_style (4).is_equal ((create {STYLE}).with_bold.with_reverse))
		end

feature -- Hits

	test_breadcrumb_registers_visible_crumbs
			-- With `hit_ids`, FRAME.render_widget registers each visible crumb's cells under its
			-- id; the separators, U+2026 and hidden crumbs register nothing; without ids,
			-- nothing. Regions are cut to the frame.
		local
			l_frame: FRAME
			l_bc: TUI_BREADCRUMB
			l_ids, l_sub: ARRAY [WIDGET_ID]
			i: INTEGER
		do
			l_ids := <<create {WIDGET_ID}.make (11), create {WIDGET_ID}.make (12), create {WIDGET_ID}.make (13),
				create {WIDGET_ID}.make (14), create {WIDGET_ID}.make (15)>>
			l_bc := (create {TUI_BREADCRUMB}.make (<<"home", "user", "projects", "eiffel", "tui">>)).with_separator (" > ")
				-- No ids
			create l_frame.make (create {BUFFER}.make (40, 3))
			l_frame.render_widget (l_bc, create {RECT}.make (2, 1, 23, 1))
			assert ("no ids, no region", l_frame.hit_map.is_empty)
				-- "home > ... > eiffel > tui" at column 2: home 2..5, ... 9, eiffel 13..18, tui 22..24
			create l_frame.make (create {BUFFER}.make (40, 3))
			l_frame.render_widget (l_bc.with_hit_ids (l_ids), create {RECT}.make (2, 1, 23, 2))
			assert ("three regions", l_frame.hit_map.count = 3)
			assert ("home", attached l_frame.hit_map.hit (2, 1) as id and then id ~ l_ids [1])
			assert ("home end", attached l_frame.hit_map.hit (5, 1) as id and then id ~ l_ids [1])
			assert ("separator", l_frame.hit_map.hit (6, 1) = Void)
			assert ("ellipsis", l_frame.hit_map.hit (9, 1) = Void)
			assert ("eiffel", attached l_frame.hit_map.hit (13, 1) as id and then id ~ l_ids [4])
			assert ("eiffel end", attached l_frame.hit_map.hit (18, 1) as id and then id ~ l_ids [4])
			assert ("tui", attached l_frame.hit_map.hit (24, 1) as id and then id ~ l_ids [5])
			assert ("after", l_frame.hit_map.hit (25, 1) = Void)
			assert ("second row", l_frame.hit_map.hit (2, 2) = Void)
			from i := 0 until i >= 40 loop
				if attached l_frame.hit_map.hit (i.to_natural_16, 1) as id then
					assert ("no hidden id " + i.out, not (id ~ l_ids [2]) and not (id ~ l_ids [3]))
					assert ("crumb_at agrees " + i.out,
						l_ids [l_bc.crumb_at (create {RECT}.make (2, 1, 23, 2), i)] ~ id)
				else
					assert ("no crumb " + i.out, l_bc.crumb_at (create {RECT}.make (2, 1, 23, 2), i) = 0)
				end
				i := i + 1
			end
				-- An area past the frame: the region of "tui" cut at the frame's edge
			create l_frame.make (create {BUFFER}.make (24, 1))
			l_frame.render_widget (l_bc.with_hit_ids (l_ids), create {RECT}.make (2, 0, 23, 1))
			assert ("cut tui", attached l_frame.hit_map.hit (23, 0) as id and then id ~ l_ids [5])
			assert ("cut count", l_frame.hit_map.count = 3)
			assert_buffer_lines ("cut row", l_frame.buffer, <<{STRING_32} "  home > %/0x2026/ > eiffel > tu">>)
				-- Ids given from index 0 are taken in order
			create l_frame.make (create {BUFFER}.make (40, 1))
			l_sub := l_ids.subarray (1, 2)
			l_sub.rebase (0)
			l_frame.render_widget ((create {TUI_BREADCRUMB}.make (<<"a", "b">>)).with_hit_ids (l_sub), create {RECT}.make (0, 0, 10, 1))
			assert ("rebased first", attached l_frame.hit_map.hit (0, 0) as id and then id ~ l_ids [1])
			assert ("rebased second", attached l_frame.hit_map.hit (4, 0) as id and then id ~ l_ids [2])
		end

	test_breadcrumb_one_and_no_crumbs
			-- One crumb: drawn bold, cut when narrower, never an U+2026. No crumbs: nothing
			-- drawn, no areas, no regions.
		local
			l_bc: TUI_BREADCRUMB
			l_buf: BUFFER
			l_frame: FRAME
		do
			create l_bc.make (<<"home">>)
			check_row ("one", l_bc, 6, "home  ")
			check_row ("one cut", l_bc, 2, "ho")
			assert ("one ellipsis", l_bc.ellipsis_area (create {RECT}.make (0, 0, 2, 1)) = Void)
			create l_buf.make (6, 1)
			l_bc.render (create {RECT}.make (0, 0, 6, 1), l_buf)
			assert_cell_style ("one bold", l_buf, 0, 0, (create {STYLE}).with_bold)
				-- No crumbs
			create l_bc
			assert ("empty", l_bc.is_empty and l_bc.width = 0)
			create l_buf.make (6, 1)
			l_buf.put_string (0, 0, "######", create {STYLE})
			l_bc.render (create {RECT}.make (0, 0, 6, 1), l_buf)
			assert_buffer_lines ("nothing drawn", l_buf, <<"######">>)
			assert ("no areas", l_bc.crumb_areas (create {RECT}.make (0, 0, 6, 1)).is_empty)
			assert ("no crumb", l_bc.crumb_at (create {RECT}.make (0, 0, 6, 1), 0) = 0)
			assert ("none visible", l_bc.visible_crumbs (create {RECT}.make (0, 0, 6, 1)).is_empty)
			create l_frame.make (create {BUFFER}.make (6, 1))
			l_frame.render_widget (l_bc.with_hit_ids (create {ARRAY [WIDGET_ID]}.make_empty), create {RECT}.make (0, 0, 6, 1))
			assert ("no regions", l_frame.hit_map.is_empty)
				-- Empty areas draw nothing
			create l_bc.make (<<"a", "b">>)
			create l_buf.make (6, 1)
			l_bc.render (create {RECT}.make (0, 0, 0, 1), l_buf)
			l_bc.render (create {RECT}.make (0, 0, 6, 0), l_buf)
			assert_buffer_lines ("empty areas", l_buf, <<"      ">>)
			assert ("empty area no areas", l_bc.visible_crumbs (create {RECT}.make (0, 0, 6, 0)).is_empty)
		end

	test_breadcrumb_builders_equality_and_copy
			-- Defaults; each `with_*` sets its attribute on a copy and leaves the original;
			-- `is_equal` compares every attribute; a copy has its own crumbs; new crumbs keep
			-- the ids when their number is the same and drop them otherwise, and clear a
			-- selection past the last crumb.
		local
			l_a, l_b: TUI_BREADCRUMB
			l_red: STYLE
			l_ids: ARRAY [WIDGET_ID]
		do
			create l_a.make (<<"a", "b", "c">>)
			assert ("nothing selected", l_a.selected = 0)
			assert ("default style", l_a.style.is_equal (create {STYLE}))
			assert ("bold current", l_a.current_style.is_equal ((create {STYLE}).with_bold))
			assert ("plain separator style", l_a.separator_style.is_equal (create {STYLE}))
			assert ("reversed selected", l_a.selected_style.is_equal ((create {STYLE}).with_reverse))
			assert ("no ids", l_a.hit_ids = Void)
			assert ("crumb", l_a.crumb (2).to_plain_string.same_string_general ("b"))
			assert ("equal", l_a ~ create {TUI_BREADCRUMB}.make (<<{STRING_32} "a", {STRING_32} "b", {STRING_32} "c">>))

			create l_red.make_fg ({COLOR}.Red)
			l_ids := <<create {WIDGET_ID}.make (1), create {WIDGET_ID}.make (2), create {WIDGET_ID}.make (3)>>
			assert ("selected", l_a.with_selected (2).selected = 2 and not (l_a ~ l_a.with_selected (2)))
			assert ("style", l_a.with_style (l_red).style = l_red and not (l_a ~ l_a.with_style (l_red)))
			assert ("current style", l_a.with_current_style (l_red).current_style = l_red and not (l_a ~ l_a.with_current_style (l_red)))
			assert ("separator style", l_a.with_separator_style (l_red).separator_style = l_red
				and not (l_a ~ l_a.with_separator_style (l_red)))
			assert ("selected style", l_a.with_selected_style (l_red).selected_style = l_red
				and not (l_a ~ l_a.with_selected_style (l_red)))
			assert ("separator", not (l_a ~ l_a.with_separator ("/")))
			assert ("ids", attached l_a.with_hit_ids (l_ids).hit_ids as h and then h [3] = l_ids [3]
				and not (l_a ~ l_a.with_hit_ids (l_ids)))
			assert ("equal ids", l_a.with_hit_ids (l_ids) ~ l_a.with_hit_ids (<<create {WIDGET_ID}.make (1),
				create {WIDGET_ID}.make (2), create {WIDGET_ID}.make (3)>>))
			assert ("crumbs", not (l_a ~ l_a.with_crumbs (<<"a", "b", "d">>)))
			assert ("original kept", l_a ~ create {TUI_BREADCRUMB}.make (<<"a", "b", "c">>))
				-- New crumbs: ids and selection
			l_b := l_a.with_hit_ids (l_ids).with_selected (3)
			assert ("same count keeps ids", l_b.with_crumbs (<<"x", "y", "z">>).hit_ids /= Void)
			assert ("same count keeps selection", l_b.with_crumbs (<<"x", "y", "z">>).selected = 3)
			assert ("other count drops ids", l_b.with_crumbs (<<"x", "y">>).hit_ids = Void)
			assert ("selection past the end cleared", l_b.with_crumbs (<<"x", "y">>).selected = 0)
			assert ("selection kept", l_a.with_selected (1).with_crumbs (<<"x">>).selected = 1)
			assert ("lines", l_a.with_crumb_lines (<<create {TEXT_LINE}.make_raw ("q")>>).count = 1)
				-- A copy has its own crumbs and ids
			l_b := l_a.with_hit_ids (l_ids)
			l_b.with_selected (1).crumb (1).append_text ("z", create {STYLE})
			assert ("copy has its own crumbs", l_b.crumb (1).to_plain_string.same_string_general ("a"))
			l_ids [1] := create {WIDGET_ID}.make (99)
			assert ("ids copied", attached l_b.hit_ids as h and then h [1] ~ create {WIDGET_ID}.make (1))
		end

	test_breadcrumb_review_fixes
			-- Review fixes after R2: styled crumbs are copied when given; an empty crumb in its
			-- place is visible (not collapsed); `is_selected_shown` is False only for a crumb
			-- hidden without U+2026 (step 3).
		local
			l_bc: TUI_BREADCRUMB
			l_line: TEXT_LINE
			l_path: ARRAY [STRING_32]
		do
				-- Lines are copied by `make_with_lines` and `with_crumb_lines`
			create l_line.make_raw ("src")
			create l_bc.make_with_lines (<<l_line>>)
			l_line.append_text ("x", create {STYLE})
			assert ("make_with_lines copies", l_bc.crumb (1).to_plain_string.same_string_general ("src"))
			create l_line.make_raw ("lib")
			l_bc := l_bc.with_crumb_lines (<<l_line>>)
			l_line.append_text ("x", create {STYLE})
			assert ("with_crumb_lines copies", l_bc.crumb (1).to_plain_string.same_string_general ("lib"))
				-- An empty crumb in a path that fits
			create l_bc.make (<<"a", "", "c">>)
			assert ("empty middle width", l_bc.width = 8)
			assert ("empty not hidden", same_indices (l_bc.visible_crumbs (create {RECT}.make (0, 0, 20, 1)), <<1, 2, 3>>))
			assert ("not collapsed", not l_bc.is_collapsed (create {RECT}.make (0, 0, 20, 1)))
			assert ("empty has no area", l_bc.crumb_areas (create {RECT}.make (0, 0, 20, 1)) [2] = Void)
			assert ("empty last shown", same_indices ((create {TUI_BREADCRUMB}.make (<<"a", "">>)).visible_crumbs (
				create {RECT}.make (0, 0, 20, 1)), <<1, 2>>))
				-- The selection shown or not (the 37-column path of `test_breadcrumb_collapses_middle`)
			l_path := <<{STRING_32} "home", {STRING_32} "user", {STRING_32} "projects", {STRING_32} "eiffel", {STRING_32} "tui">>
			l_bc := (create {TUI_BREADCRUMB}.make (l_path)).with_separator (" > ")
			assert ("none selected", l_bc.is_selected_shown (create {RECT}.make (0, 0, 11, 1)))
			assert ("first in step 1", l_bc.with_selected (1).is_selected_shown (create {RECT}.make (0, 0, 22, 1)))
			assert ("middle under the ellipsis", l_bc.with_selected (3).is_selected_shown (create {RECT}.make (0, 0, 22, 1)))
			assert ("last in step 3", l_bc.with_selected (5).is_selected_shown (create {RECT}.make (0, 0, 11, 1)))
			assert ("first hidden in step 3", not l_bc.with_selected (1).is_selected_shown (create {RECT}.make (0, 0, 11, 1)))
			assert ("middle hidden in step 3", not l_bc.with_selected (3).is_selected_shown (create {RECT}.make (0, 0, 11, 1)))
			assert ("whole path", l_bc.with_selected (2).is_selected_shown (create {RECT}.make (0, 0, 37, 1)))
		end

feature {NONE} -- Implementation

	check_row (a_tag: STRING; a_bc: TUI_BREADCRUMB; a_width: INTEGER; a_expected: READABLE_STRING_GENERAL)
			-- `a_bc` rendered into an area `a_width` columns wide at column 1 of a fresh 1-row
			-- buffer three columns wider gives " " + `a_expected` + "  " (blanks where nothing
			-- is drawn are the untouched cells of the fresh row).
		local
			l_buf: BUFFER
			l_row: STRING_32
		do
			create l_buf.make (a_width + 3, 1)
			a_bc.render (create {RECT}.make (1, 0, a_width.to_natural_16, 1), l_buf)
			l_row := buffer_row_as_string (l_buf, 0)
			assert (a_tag + ": " + printable (l_row) + " /= " + printable (a_expected),
				l_row.same_string_general ({STRING_32} " " + a_expected.to_string_32 + {STRING_32} "  "))
			assert (a_tag + " consistent", l_buf.is_consistent)
		end

	check_areas (a_tag: STRING; a_bc: TUI_BREADCRUMB; a_width: INTEGER; a_widths, a_offsets: ARRAY [INTEGER])
			-- In an area `a_width` wide at column 0, crumb `i` has an area `a_widths [i]` wide at
			-- `a_offsets [i]` (width 0: Void).
		local
			l_areas: ARRAY [detachable RECT]
			i: INTEGER
		do
			l_areas := a_bc.crumb_areas (create {RECT}.make (0, 0, a_width.to_natural_16, 1))
			from i := 1 until i > a_bc.count loop
				if a_widths [i] = 0 then
					assert (a_tag + " hidden " + i.out, l_areas [i] = Void)
				else
					assert (a_tag + " area " + i.out, attached l_areas [i] as r and then
						r ~ create {RECT}.make (a_offsets [i].to_natural_16, 0, a_widths [i].to_natural_16, 1))
				end
				i := i + 1
			end
		end

	check_every_width (a_tag: STRING; a_crumbs: ARRAY [READABLE_STRING_GENERAL]; a_separator: READABLE_STRING_GENERAL)
			-- At every width from the full length + 2 down to 1, `a_crumbs` joined by
			-- `a_separator` (every character one column) render as `model_row` says, and the
			-- layout queries agree with the model and with the drawn row.
		local
			l_bc: TUI_BREADCRUMB
			l_buf: BUFFER
			l_area: RECT
			l_model: like model
			l_areas: ARRAY [detachable RECT]
			l_visible: ARRAY [INTEGER]
			l_row: STRING_32
			w, i, c, l_hidden, l_drawn: INTEGER
			l_tag: STRING
		do
			l_bc := (create {TUI_BREADCRUMB}.make (a_crumbs)).with_separator (a_separator)
			from w := l_bc.width + 2 until w < 1 loop
				l_tag := a_tag + " at " + w.out
				l_model := model (a_crumbs, a_separator, w)
				create l_buf.make (w + 3, 1)
				l_buf.put_string (0, 0, create {STRING_32}.make_filled ({CHARACTER_32} '#', w + 3), create {STYLE})
				create l_area.make (1, 0, w.to_natural_16, 1)
				l_bc.render (l_area, l_buf)
				l_row := buffer_row_as_string (l_buf, 0)
					-- The row: the model's text, the cells it does not reach untouched
				assert (l_tag + " row: " + printable (l_row) + " /= " + printable (l_model.text),
					l_row.same_string_general ({STRING_32} "#" + l_model.text + create {STRING_32}.make_filled ({CHARACTER_32} '#', w + 2 - l_model.text.count)))
				assert (l_tag + " fits", l_model.text.count <= w)
				assert (l_tag + " consistent", l_buf.is_consistent)
					-- The rule: the last crumb is always drawn; anything hidden means U+2026
					-- with the first crumb, or the last crumb alone
				l_visible := l_bc.visible_crumbs (l_area)
				assert (l_tag + " last drawn", l_visible.count > 0 and then l_visible [l_visible.upper] = a_crumbs.count)
				if l_visible.count < a_crumbs.count and l_visible.count > 1 then
					assert (l_tag + " first kept", l_visible [l_visible.lower] = 1)
					assert (l_tag + " tail contiguous", l_visible [l_visible.lower + 1] = a_crumbs.count - l_visible.count + 2)
				end
				if l_visible.count = a_crumbs.count and l_bc.width > w then
						-- All shown although the path does not fit: one or two crumbs, the last one cut
					assert (l_tag + " whole path only when it fits", a_crumbs.count <= 2
						and then attached l_bc.crumb_areas (l_area) [a_crumbs.count] as r and then r.width.to_integer_32 < a_crumbs [a_crumbs.count].count)
				end
					-- Areas: as in the model, and each one holds its crumb as drawn
				l_areas := l_bc.crumb_areas (l_area)
				l_hidden := 0
				from i := 1 until i > a_crumbs.count loop
					if l_model.offsets [i] < 0 then
						assert (l_tag + " hidden " + i.out, l_areas [i] = Void)
						l_hidden := l_hidden + 1
					else
						assert (l_tag + " area " + i.out, attached l_areas [i] as r and then
							r ~ create {RECT}.make ((1 + l_model.offsets [i]).to_natural_16, 0, l_model.widths [i].to_natural_16, 1))
						if attached l_areas [i] as r then
							assert (l_tag + " drawn crumb " + i.out, l_row.substring (r.x.to_integer_32 + 1, r.right.to_integer_32)
								.same_string_general (a_crumbs [i].substring (1, r.width.to_integer_32)))
						end
					end
					i := i + 1
				end
				assert (l_tag + " visible count", l_visible.count = a_crumbs.count - l_hidden)
				if l_hidden > 0 and l_visible.count > 1 and a_crumbs.count > 2 then
					assert (l_tag + " ellipsis", attached l_bc.ellipsis_area (l_area) as r and then
						r.x.to_integer_32 = 1 + a_crumbs [1].count + a_separator.count and then r.width = 1
						and then l_row.item (r.x.to_integer_32 + 1) = {CHARACTER_32} '%/0x2026/')
				else
					assert (l_tag + " no ellipsis", l_bc.ellipsis_area (l_area) = Void)
				end
					-- `crumb_at` at every column, the buffer's edge cells included
				l_drawn := 0
				from c := -1 until c > w + 3 loop
					i := l_bc.crumb_at (l_area, c)
					if i > 0 then
						l_drawn := l_drawn + 1
						assert (l_tag + " crumb_at " + c.out, attached l_areas [i] as r and then
							c >= r.x.to_integer_32 and then c < r.right.to_integer_32)
					else
						assert (l_tag + " nothing at " + c.out, across l_areas as r all
							attached r as l_r implies (c < l_r.x.to_integer_32 or c >= l_r.right.to_integer_32) end)
					end
					c := c + 1
				end
				assert (l_tag + " crumb cells", l_drawn = sum (l_model.widths))
				w := w - 1
			end
		end

	model (a_crumbs: ARRAY [READABLE_STRING_GENERAL]; a_separator: READABLE_STRING_GENERAL; a_width: INTEGER):
			TUPLE [text: STRING_32; offsets, widths: ARRAY [INTEGER]]
			-- The rule of decision Q6 on plain strings of one-column characters: the row drawn
			-- in `a_width` columns, and each crumb's offset (-1: hidden) and drawn width
		local
			n, k, i: INTEGER
			l_text, l_sep, l_ellipsis, l_candidate: STRING_32
			l_offsets, l_widths: ARRAY [INTEGER]
			l_done: BOOLEAN
		do
			n := a_crumbs.count
			l_sep := a_separator.to_string_32
			l_ellipsis := {STRING_32} "%/0x2026/"
			create l_offsets.make_filled (-1, 1, n)
			create l_widths.make_filled (0, 1, n)
			create l_text.make_empty
				-- The whole path
			from i := 1 until i > n loop
				if i > 1 then l_text.append (l_sep) end
				l_offsets [i] := l_text.count
				l_widths [i] := a_crumbs [i].count
				l_text.append_string_general (a_crumbs [i])
				i := i + 1
			end
			l_done := l_text.count <= a_width
				-- First, ellipsis, the longest tail (smallest k) that fits
			from k := 3 until l_done or k > n loop
				l_candidate := a_crumbs [1].to_string_32 + l_sep + l_ellipsis
				from i := k until i > n loop
					l_candidate.append (l_sep)
					l_candidate.append_string_general (a_crumbs [i])
					i := i + 1
				end
				if l_candidate.count <= a_width then
					l_text := l_candidate
					l_offsets.fill_with (-1)
					l_widths.fill_with (0)
					l_offsets [1] := 0
					l_widths [1] := a_crumbs [1].count
					l_candidate := a_crumbs [1].to_string_32 + l_sep + l_ellipsis
					from i := k until i > n loop
						l_candidate.append (l_sep)
						l_offsets [i] := l_candidate.count
						l_widths [i] := a_crumbs [i].count
						l_candidate.append_string_general (a_crumbs [i])
						i := i + 1
					end
					l_done := True
				end
				k := k + 1
			end
				-- First, ellipsis (if anything is hidden), the last crumb cut
			if not l_done and n >= 2 then
				l_candidate := a_crumbs [1].to_string_32 + l_sep
				if n >= 3 then
					l_candidate.append (l_ellipsis)
					l_candidate.append (l_sep)
				end
				if a_width - l_candidate.count >= 1 then
					l_offsets.fill_with (-1)
					l_widths.fill_with (0)
					l_offsets [1] := 0
					l_widths [1] := a_crumbs [1].count
					l_offsets [n] := l_candidate.count
					l_widths [n] := a_width - l_candidate.count
					l_candidate.append_string_general (a_crumbs [n].substring (1, a_width - l_candidate.count))
					l_text := l_candidate
					l_done := True
				end
			end
				-- The last crumb alone, cut
			if not l_done then
				l_offsets.fill_with (-1)
				l_widths.fill_with (0)
				l_offsets [n] := 0
				l_widths [n] := a_crumbs [n].count.min (a_width)
				l_text := a_crumbs [n].substring (1, l_widths [n]).to_string_32
			end
			Result := [l_text, l_offsets, l_widths]
		end

	sum (a_values: ARRAY [INTEGER]): INTEGER
			-- Sum of `a_values`
		do
			across a_values as v loop
				Result := Result + v
			end
		end

	same_indices (a_actual: ARRAY [INTEGER]; a_expected: ARRAY [INTEGER]): BOOLEAN
			-- Same indices in the same order?
		local
			i: INTEGER
		do
			Result := a_actual.count = a_expected.count
			from i := 0 until not Result or i >= a_actual.count loop
				Result := a_actual [a_actual.lower + i] = a_expected [a_expected.lower + i]
				i := i + 1
			end
		end

end
