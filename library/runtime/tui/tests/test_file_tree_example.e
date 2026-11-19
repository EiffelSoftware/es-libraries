note
	description: "[
		EXAMPLE_FILE_TREE (P2b R2): TUI_TREE with a TUI_BREADCRUMB of the selected node's path.
		Row-exact snapshots of the start and after each kind of navigation: the breadcrumb
		follows the tree's selection; a click on a crumb selects that ancestor and collapses it
		and the folders below it; Backspace goes to the parent; Alt+Left / Alt+Right move the
		breadcrumb's selection and Enter goes there; a narrow frame collapses the path's middle
		to U+2026. A scripted run through the real event loop on a fixed viewport checks the
		same through the parser and `hit_test` (SGR clicks, CSI 1;3D, CR, DEL).

		Expected rows are written with `row`: '>' in a breadcrumb row is U+203A only where
		`crumb_row` builds it; `boxed` puts a tree row between U+2502 borders.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_FILE_TREE_EXAMPLE

inherit
	BUFFER_TEST_HELPER

feature -- Tests

	test_file_tree_example_snapshot
			-- The 60 x 16 screen at the start, row-exact: the path of "tui_tree.e" on the top
			-- row, the tree with "library/widgets/tree" open below it, the help line. Each crumb
			-- and each tree row shown is a hit region; separators are not.
		local
			l_app: FILE_TREE_SNAPSHOT_APP
			l_buf: BUFFER
			l_frame: FRAME
		do
			l_app := new_snapshot_app
			create l_buf.make (60, 16)
			create l_frame.make (l_buf)
			l_app.render_now (l_frame)
			assert_buffer_lines ("start", l_buf, <<
				crumb_row (<<"eiffeltui", "library", "widgets", "tree", "tui_tree.e">>, 60),
				top_row (60),
				boxed ("   v eiffeltui", 60),
				boxed ("     > docs", 60),
				boxed ("     > examples", 60),
				boxed ("     v library", 60),
				boxed ("       > core", 60),
				boxed ("       v widgets", 60),
				boxed ("         > breadcrumb", 60),
				boxed ("         v tree", 60),
				boxed (">>           tui_tree.e", 60),
				boxed ("             tree_state.e", 60),
				boxed ("             tree_node.e", 60),
				boxed ("     > tests", 60),
				bottom_row (60),
				padded ("Arrows: tree  Bksp: up  Alt+arrows, Enter: crumb  q: quit", 60)>>)
			assert ("buffer consistent", l_buf.is_consistent)
			assert ("five crumbs", l_app.crumbs.count = 5)
			assert ("no crumb selected", l_app.crumb_selected = 0)
			assert_cell_style ("crumb style", l_buf, 0, 1, create {STYLE}.make_fg ({COLOR}.Bright_cyan))
			assert_cell_style ("current crumb bold", l_buf, 0, 40, (create {STYLE}.make_fg ({COLOR}.Bright_cyan)).with_bold)
				-- Hit regions: crumb i is 100 + i, tree row j is 1000 + j
			assert ("root crumb hit", attached l_frame.hit_map.hit (1, 0) as id and then id.value = 101)
			assert ("separator misses", l_frame.hit_map.hit (11, 0) = Void)
			assert ("library crumb hit", attached l_frame.hit_map.hit (19, 0) as id and then id.value = 102)
			assert ("last crumb hit", attached l_frame.hit_map.hit (49, 0) as id and then id.value = 105)
			assert ("right of the path misses", l_frame.hit_map.hit (50, 0) = Void)
			assert ("first tree row hit", attached l_frame.hit_map.hit (1, 2) as id and then id.value = 1001)
			assert ("last tree row hit", attached l_frame.hit_map.hit (58, 13) as id and then id.value = 1012)
			assert ("border misses", l_frame.hit_map.hit (0, 5) = Void)
		end

	test_file_tree_breadcrumb_follows_tree
			-- Up / Down, Left / Right, Space and a click on a tree row change the selection, and
			-- the breadcrumb shows the new selection's path at once.
		local
			l_app: FILE_TREE_SNAPSHOT_APP
			l_buf: BUFFER
			l_frame: FRAME
		do
			l_app := new_snapshot_app
			l_app.process_now (special ({KEY_CODE}.Down))
			assert ("tree_state.e", l_app.selected_id.same_string ("eiffeltui/library/widgets/tree/tree_state.e"))
			l_buf := rendered (l_app, 60, 16)
			assert_rows ("down", l_buf, 0, <<crumb_row (<<"eiffeltui", "library", "widgets", "tree", "tree_state.e">>, 60)>>)
				-- Left on a file goes to its folder; Left again collapses it
			l_app.process_now (special ({KEY_CODE}.Left))
			l_app.process_now (special ({KEY_CODE}.Left))
			assert ("tree selected", l_app.selected_id.same_string ("eiffeltui/library/widgets/tree"))
			assert ("tree collapsed", not l_app.tree_state.is_expanded ("eiffeltui/library/widgets/tree"))
			l_buf := rendered (l_app, 60, 16)
			assert_rows ("left", l_buf, 0, <<crumb_row (<<"eiffeltui", "library", "widgets", "tree">>, 60)>>)
			assert_rows ("left tree", l_buf, 8, <<
				boxed ("         > breadcrumb", 60),
				boxed (">>       > tree", 60),
				boxed ("     > tests", 60)>>)
				-- Up to "breadcrumb", Right expands it, Right again enters it
			l_app.process_now (special ({KEY_CODE}.Up))
			l_app.process_now (special ({KEY_CODE}.Right))
			l_app.process_now (special ({KEY_CODE}.Right))
			assert ("first child", l_app.selected_id.same_string ("eiffeltui/library/widgets/breadcrumb/tui_breadcrumb.e"))
			create l_buf.make (60, 16)
			create l_frame.make (l_buf)
			l_app.render_now (l_frame)
				-- That path is 61 columns, more than the 58 of the crumb area: "library" is hidden
			assert_rows ("right", l_buf, 0, <<padded (" eiffeltui %/0x203A/ %/0x2026/ %/0x203A/ widgets %/0x203A/ breadcrumb %/0x203A/ tui_breadcrumb.e", 60)>>)
			assert ("five crumbs", l_app.crumbs.count = 5)
				-- A click on the "docs" row (row 3) selects it; a second click expands it
			l_app.click_at (l_frame, 10, 3)
			assert ("docs", l_app.selected_id.same_string ("eiffeltui/docs"))
			assert ("docs still closed", not l_app.tree_state.is_expanded ("eiffeltui/docs"))
			l_buf := rendered (l_app, 60, 16)
			assert_rows ("click row", l_buf, 0, <<crumb_row (<<"eiffeltui", "docs">>, 60)>>)
			create l_frame.make (l_buf)
			l_app.render_now (l_frame)
			l_app.click_at (l_frame, 10, 3)
			assert ("docs opened", l_app.tree_state.is_expanded ("eiffeltui/docs"))
				-- Space closes it again; End goes to the last row
			l_app.process_now (create {KEY_EVENT}.make_char (' '))
			assert ("docs closed", not l_app.tree_state.is_expanded ("eiffeltui/docs"))
			l_app.process_now (special ({KEY_CODE}.End_key))
			assert ("README", l_app.selected_id.same_string ("eiffeltui/README.md"))
			l_buf := rendered (l_app, 60, 16)
			assert_rows ("end", l_buf, 0, <<crumb_row (<<"eiffeltui", "README.md">>, 60)>>)
		end

	test_file_tree_crumb_click_and_backspace
			-- A click on the "library" crumb selects it and collapses it and the folders below
			-- it (re-expanding "library" shows "widgets" closed); a click on a separator does
			-- nothing; Backspace goes to the parent (collapsing it); at the root it does nothing.
		local
			l_app: FILE_TREE_SNAPSHOT_APP
			l_buf: BUFFER
			l_frame: FRAME
		do
			l_app := new_snapshot_app
			create l_buf.make (60, 16)
			create l_frame.make (l_buf)
			l_app.render_now (l_frame)
			l_app.click_at (l_frame, 11, 0)
			assert ("separator: unchanged", l_app.selected_id.same_string ("eiffeltui/library/widgets/tree/tui_tree.e"))
			l_app.click_at (l_frame, 15, 0)
			assert ("library selected", l_app.selected_id.same_string ("eiffeltui/library"))
			assert ("library collapsed", not l_app.tree_state.is_expanded ("eiffeltui/library"))
			assert ("widgets collapsed", not l_app.tree_state.is_expanded ("eiffeltui/library/widgets"))
			assert ("tree collapsed", not l_app.tree_state.is_expanded ("eiffeltui/library/widgets/tree"))
			assert ("root still open", l_app.tree_state.is_expanded ("eiffeltui"))
			l_buf := rendered (l_app, 60, 16)
			assert_buffer_lines ("library", l_buf, <<
				crumb_row (<<"eiffeltui", "library">>, 60),
				top_row (60),
				boxed ("   v eiffeltui", 60),
				boxed ("     > docs", 60),
				boxed ("     > examples", 60),
				boxed (">>   > library", 60),
				boxed ("     > tests", 60),
				boxed ("       eiffeltui.ecf", 60),
				boxed ("       README.md", 60),
				boxed ("", 60)>>)
			l_app.process_now (special ({KEY_CODE}.Right))
			l_buf := rendered (l_app, 60, 16)
			assert_rows ("library reopened", l_buf, 5, <<
				boxed (">>   v library", 60),
				boxed ("       > core", 60),
				boxed ("       > widgets", 60)>>)
				-- Backspace: to the root, collapsed
			l_app.process_now (special ({KEY_CODE}.Backspace))
			assert ("root selected", l_app.selected_id.same_string ("eiffeltui"))
			assert ("root collapsed", not l_app.tree_state.is_expanded ("eiffeltui"))
			assert ("library collapsed again", not l_app.tree_state.is_expanded ("eiffeltui/library"))
			l_buf := rendered (l_app, 60, 16)
			assert_rows ("root", l_buf, 0, <<
				crumb_row (<<"eiffeltui">>, 60),
				top_row (60),
				boxed (">> > eiffeltui", 60),
				boxed ("", 60)>>)
			l_app.process_now (special ({KEY_CODE}.Backspace))
			assert ("root: unchanged", l_app.selected_id.same_string ("eiffeltui") and l_app.crumbs.count = 1)
		end

	test_file_tree_alt_arrows_and_enter
			-- Alt+Left starts at the parent crumb and stops at the first; Alt+Right stops at the
			-- last; the selected crumb is drawn reversed; Enter goes there. A tree move clears
			-- the breadcrumb's selection.
		local
			l_app: FILE_TREE_SNAPSHOT_APP
			l_buf: BUFFER
			l_crumb: STYLE
			i: INTEGER
		do
			l_crumb := create {STYLE}.make_fg ({COLOR}.Bright_cyan)
			l_app := new_snapshot_app
			l_app.process_now (alt ({KEY_CODE}.Left))
			assert ("parent crumb", l_app.crumb_selected = 4)
			l_app.process_now (alt ({KEY_CODE}.Left))
			assert ("widgets crumb", l_app.crumb_selected = 3)
			l_buf := rendered (l_app, 60, 16)
				-- "widgets" is at columns 23..29
			assert_cell_style ("widgets reversed", l_buf, 0, 23, l_crumb.with_reverse)
			assert_cell_style ("widgets end reversed", l_buf, 0, 29, l_crumb.with_reverse)
			assert_cell_style ("library plain", l_buf, 0, 19, l_crumb)
			assert_cell_style ("current not reversed", l_buf, 0, 40, l_crumb.with_bold)
			assert ("selection unchanged", l_app.selected_id.same_string ("eiffeltui/library/widgets/tree/tui_tree.e"))
			from i := 1 until i > 6 loop
				l_app.process_now (alt ({KEY_CODE}.Right))
				i := i + 1
			end
			assert ("stops at the last", l_app.crumb_selected = 5)
			from i := 1 until i > 6 loop
				l_app.process_now (alt ({KEY_CODE}.Left))
				i := i + 1
			end
			assert ("stops at the first", l_app.crumb_selected = 1)
			l_app.process_now (alt ({KEY_CODE}.Right))
			l_app.process_now (alt ({KEY_CODE}.Right))
			l_app.process_now (special ({KEY_CODE}.Enter))
			assert ("widgets selected", l_app.selected_id.same_string ("eiffeltui/library/widgets"))
			assert ("widgets collapsed", not l_app.tree_state.is_expanded ("eiffeltui/library/widgets"))
			assert ("library still open", l_app.tree_state.is_expanded ("eiffeltui/library"))
			assert ("crumb selection cleared", l_app.crumb_selected = 0)
			l_buf := rendered (l_app, 60, 16)
			assert_rows ("widgets", l_buf, 0, <<crumb_row (<<"eiffeltui", "library", "widgets">>, 60)>>)
			assert_rows ("widgets tree", l_buf, 5, <<
				boxed ("     v library", 60),
				boxed ("       > core", 60),
				boxed (">>     > widgets", 60),
				boxed ("     > tests", 60)>>)
			assert_cell_style ("no crumb reversed", l_buf, 0, 1, l_crumb)
				-- Enter without a selected crumb toggles the folder; a tree move clears a selection
			l_app.process_now (special ({KEY_CODE}.Enter))
			assert ("widgets opened", l_app.tree_state.is_expanded ("eiffeltui/library/widgets"))
			l_app.process_now (alt ({KEY_CODE}.Left))
			assert ("library crumb", l_app.crumb_selected = 2)
			l_app.process_now (special ({KEY_CODE}.Down))
			assert ("cleared by a move", l_app.crumb_selected = 0)
		end

	test_file_tree_narrow_frame
			-- At 30 columns the path collapses to "eiffeltui > ... > tui_tree.e" (the crumb area
			-- is 28 wide); at 20 the last crumb is cut. U+2026 is no region, and a click on the
			-- first crumb still goes to the root.
		local
			l_app: FILE_TREE_SNAPSHOT_APP
			l_buf: BUFFER
			l_frame: FRAME
		do
			l_app := new_snapshot_app
			create l_buf.make (30, 16)
			create l_frame.make (l_buf)
			l_app.render_now (l_frame)
			assert_rows ("30", l_buf, 0, <<
				padded (" eiffeltui %/0x203A/ %/0x2026/ %/0x203A/ tui_tree.e", 30),
				top_row (30),
				boxed ("   v eiffeltui", 30)>>)
			assert_rows ("30 selected", l_buf, 10, <<boxed (">>           tui_tree.e", 30)>>)
			assert ("ellipsis misses", l_frame.hit_map.hit (13, 0) = Void)
			assert ("last crumb hit", attached l_frame.hit_map.hit (17, 0) as id and then id.value = 105)
			assert ("first crumb hit", attached l_frame.hit_map.hit (9, 0) as id and then id.value = 101)
			l_buf := rendered (l_app, 20, 16)
			assert_rows ("20", l_buf, 0, <<padded (" eiffeltui %/0x203A/ %/0x2026/ %/0x203A/ tu", 20)>>)
				-- A click on the first crumb at 30 columns
			create l_buf.make (30, 16)
			create l_frame.make (l_buf)
			l_app.render_now (l_frame)
			l_app.click_at (l_frame, 3, 0)
			assert ("root", l_app.selected_id.same_string ("eiffeltui"))
			assert ("root collapsed", not l_app.tree_state.is_expanded ("eiffeltui"))
			l_buf := rendered (l_app, 30, 16)
			assert_rows ("root at 30", l_buf, 0, <<padded (" eiffeltui", 30)>>)
		end

	test_file_tree_example_scripted
			-- The real event loop on a fixed 60 x 16 viewport at screen (10, 3): a click on the
			-- "library" crumb, a click on the "docs" row and a second one (opens it), Down to
			-- "guide.md", Alt+Left (CSI 1;3D) to the "docs" crumb, Enter (CR) goes there and
			-- closes it, Down to "examples", Right twice (opens it, enters "tier1"), Backspace
			-- (DEL) goes back to "examples" and closes it, q quits. Only the root stays open,
			-- which needs the crumb click to have closed "library". A right click on the root
			-- crumb comes first and must do nothing: had it gone to the root, the root would be
			-- closed and the "library" crumb would not exist.
		local
			l_app: FILE_TREE_SNAPSHOT_APP
		do
			l_app := new_scripted_app (
				right_press_release (3, 0) +	-- right button on the root crumb: nothing
				press_release (15, 0) +		-- "library" crumb
				press_release (10, 3) +		-- "docs" row
				press_release (10, 3) +		-- again: opens it
				Esc + "[B" +				-- Down: guide.md
				Esc + "[1;3D" +				-- Alt+Left: the "docs" crumb
				"%R" +						-- Enter
				Esc + "[B" +				-- Down: examples
				Esc + "[C" + Esc + "[C" +	-- Right, Right: tier1
				"%/127/" +					-- Backspace
				"q",
				create {VIEWPORT}.make_fixed (create {RECT}.make (10, 3, 60, 16)))
			l_app.run
			assert ("stopped", not l_app.is_running)
			assert ("examples selected", l_app.selected_id.same_string ("eiffeltui/examples"))
			assert ("only the root open", l_app.tree_state.expanded_count = 1 and l_app.tree_state.is_expanded ("eiffeltui"))
			assert ("no crumb selected", l_app.crumb_selected = 0)
		end

feature {NONE} -- Helpers

	new_snapshot_app: FILE_TREE_SNAPSHOT_APP
			-- The example on a fake console, not running.
		local
			l_backend: ANSI_TERMINAL_BACKEND
		do
			create l_backend.make_with_driver_and_sink (create {FAKE_CONSOLE_DRIVER}, create {STRING_32}.make_empty)
			create Result.make_on (create {TERMINAL [ANSI_TERMINAL_BACKEND]}.make_with_viewport (l_backend, create {VIEWPORT}.make_fullscreen))
		end

	new_scripted_app (a_input: READABLE_STRING_8; a_viewport: VIEWPORT): FILE_TREE_SNAPSHOT_APP
			-- The example on a fake console replaying `a_input`, output captured.
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_sink: STRING_32
			l_backend: ANSI_TERMINAL_BACKEND
		do
			create l_driver
			l_driver.script (a_input)
			create l_sink.make_empty
			l_driver.watch_sink (l_sink)
			create l_backend.make_with_driver_and_sink (l_driver, l_sink)
			create Result.make_on (create {TERMINAL [ANSI_TERMINAL_BACKEND]}.make_with_viewport (l_backend, a_viewport))
			Result.event_thread.set_poll_interval (5)
		end

	rendered (a_app: FILE_TREE_SNAPSHOT_APP; a_width, a_height: INTEGER): BUFFER
			-- A new `a_width` x `a_height` buffer with `a_app` rendered into it
		do
			create Result.make (a_width, a_height)
			a_app.render_now (create {FRAME}.make (Result))
		end

	press_release (a_column, a_row: INTEGER): STRING_8
			-- SGR press and release of the left button at frame (`a_column`, `a_row`) of a
			-- viewport at screen (10, 3)
		do
			Result := Esc + "[<0;" + (a_column + 11).out + ";" + (a_row + 4).out + "M"
				+ Esc + "[<0;" + (a_column + 11).out + ";" + (a_row + 4).out + "m"
		end

	right_press_release (a_column, a_row: INTEGER): STRING_8
			-- SGR press and release of the right button at frame (`a_column`, `a_row`) of a
			-- viewport at screen (10, 3)
		do
			Result := Esc + "[<2;" + (a_column + 11).out + ";" + (a_row + 4).out + "M"
				+ Esc + "[<2;" + (a_column + 11).out + ";" + (a_row + 4).out + "m"
		end

	special (a_code: KEY_CODE): KEY_EVENT
			-- Press of `a_code`
		do
			create Result.make_special (a_code)
		end

	alt (a_code: KEY_CODE): KEY_EVENT
			-- Press of Alt+`a_code`
		do
			create Result.make (a_code, create {MODIFIERS}.make_with_bits (4))		-- 4: Alt
		end

	crumb_row (a_crumbs: ARRAY [STRING_32]; a_width: INTEGER): STRING_32
			-- The top row: a blank, `a_crumbs` joined by " U+203A ", blanks to `a_width`
		local
			i: INTEGER
		do
			create Result.make_from_string (" ")
			from i := a_crumbs.lower until i > a_crumbs.upper loop
				if i > a_crumbs.lower then
					Result.append ({STRING_32} " %/0x203A/ ")
				end
				Result.append (a_crumbs [i])
				i := i + 1
			end
			Result := padded (Result, a_width)
		end

	top_row (a_width: INTEGER): STRING_32
			-- The tree box's top border with its title
		do
			Result := {STRING_32} "%/0x256D/ Project " + repeated ('%/0x2500/', a_width - 11) + {STRING_32} "%/0x256E/"
		end

	bottom_row (a_width: INTEGER): STRING_32
			-- The tree box's bottom border
		do
			Result := {STRING_32} "%/0x2570/" + repeated ('%/0x2500/', a_width - 2) + {STRING_32} "%/0x256F/"
		end

	boxed (a_inner: READABLE_STRING_GENERAL; a_width: INTEGER): STRING_32
			-- `a_inner` padded to the box's inner width, between U+2502 borders
		do
			Result := {STRING_32} "%/0x2502/" + padded (a_inner, a_width - 2) + {STRING_32} "%/0x2502/"
		end

	padded (a_text: READABLE_STRING_GENERAL; a_width: INTEGER): STRING_32
			-- `a_text` with blanks up to `a_width` characters
		require
			fits: a_text.count <= a_width
		do
			create Result.make_from_string_general (a_text)
			Result.append (create {STRING_32}.make_filled (' ', a_width - a_text.count))
		end

	repeated (a_char: CHARACTER_32; a_count: INTEGER): STRING_32
			-- `a_count` times `a_char`
		do
			create Result.make_filled (a_char, a_count)
		end

	assert_rows (a_tag: STRING; a_buf: BUFFER; a_first: INTEGER; a_lines: ARRAY [STRING_32])
			-- Rows `a_first` ... of `a_buf` are `a_lines`.
		local
			i: INTEGER
		do
			from i := a_lines.lower until i > a_lines.upper loop
				assert (a_tag + " row " + (a_first + i - a_lines.lower).out + ": got %""
						+ {UTF_CONVERTER}.string_32_to_utf_8_string_8 (buffer_row_as_string (a_buf, a_first + i - a_lines.lower)) + "%"",
					buffer_row_as_string (a_buf, a_first + i - a_lines.lower).same_string (a_lines [i]))
				i := i + 1
			end
		end

	Esc: STRING_8 = "%/27/"
			-- ESC, for scripted input

end
