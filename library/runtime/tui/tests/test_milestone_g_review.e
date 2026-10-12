note
	description: "[
		Regression tests for the Milestone G review:
		- builders return copies that do not share element lists with the original
		- a state of the wrong type is a precondition violation through FRAME
		- TUI_TEXT_INPUT edits grapheme clusters, scrolls by display column, keeps its
		  state invariant after deletions, and reports the hardware cursor position
		- TUI_TREE and TUI_CALENDAR stay inside their area; the tree follows the selection
		- COLOR.Gray is ANSI 7 as in Ratatui
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_MILESTONE_G_REVIEW

inherit
	EQA_TEST_SET
	BUFFER_TEST_HELPER

feature -- Builders

	test_builders_do_not_share_lists
			-- Adding to a copy made by a `with_*` builder leaves the original unchanged.
		local
			l_list, l_list2: TUI_LIST
			l_tabs, l_tabs2: TUI_TABS
			l_chart, l_chart2: TUI_BARCHART
			l_ds, l_ds2: TUI_CHART_DATASET
			l_red: STYLE
		do
			create l_red.make_fg ({COLOR}.red)

			create l_list.make_empty
			l_list.append_raw_item ("one")
			l_list2 := l_list.with_style (l_red)
			l_list2.append_raw_item ("two")
			assert ("list original keeps one item", l_list.items.count = 1)
			assert ("list copy has two items", l_list2.items.count = 2)

			create l_tabs.make_from_strings (<<"A">>)
			l_tabs2 := l_tabs.with_style (l_red)
			l_tabs2.append_title (create {TEXT_LINE}.make_raw ("B"))
			assert ("tabs original keeps one title", l_tabs.titles.count = 1)

			create l_chart.make_with_data (<<create {BAR_ITEM}.make ("a", 1)>>)
			l_chart2 := l_chart.with_bar_width (2)
			l_chart2.append_bar (create {BAR_ITEM}.make ("b", 2))
			assert ("barchart original keeps one bar", l_chart.bars.count = 1)
			assert ("barchart copy has two bars", l_chart2.bars.count = 2)

			create l_ds.make ("series")
			l_ds.append_point (0.0, 0.0)
			l_ds2 := l_ds.with_style (l_red)
			l_ds2.append_point (1.0, 1.0)
			assert ("dataset builder returns a copy", l_ds2 /= l_ds)
			assert ("dataset original style unchanged", l_ds.style /= l_red)
			assert ("dataset original keeps one point", l_ds.data.count = 1)
		end

	test_frame_rejects_mismatched_state
			-- Passing the wrong state type through FRAME violates a precondition instead of
			-- silently rendering nothing.
		local
			l_frame: FRAME
			l_list: TUI_LIST
			l_raised, l_retried: BOOLEAN
		do
			if not l_retried then
				create l_frame.make (create {BUFFER}.make (10, 3))
				create l_list.make_empty
				assert ("list accepts its state", l_list.accepts_state (create {LIST_STATE}.make))
				assert ("list rejects a tabs state", not l_list.accepts_state (create {TABS_STATE}.make))
				if preconditions_monitored then
					l_frame.render_stateful_widget (l_list, l_frame.area, create {TABS_STATE}.make)
				else
					-- Finalized build without assertions: the contract is not checked.
					l_raised := True
				end
			end
			assert ("mismatched state raised", l_raised)
		rescue
			if not l_retried then
				l_retried := True
				l_raised := attached (create {EXCEPTION_MANAGER}).last_exception as e and then attached {PRECONDITION_VIOLATION} e
				retry
			end
		end

feature {NONE} -- Assertion monitoring

	preconditions_monitored: BOOLEAN
			-- Are preconditions checked in this build?
		local
			l_retried: BOOLEAN
		do
			if l_retried then
				Result := True
			else
				failing_precondition_probe
			end
		rescue
			if not l_retried then
				l_retried := True
				retry
			end
		end

	failing_precondition_probe
			-- Routine whose precondition never holds.
		require
			never: False
		do
		end

feature -- Text input

	test_text_input_edits_grapheme_clusters
			-- Cursor movement and deletion step over whole clusters.
		local
			s: TEXT_INPUT_STATE
		do
			create s.make_with_text ({STRING_32} "e%/769/x")
			s.move_cursor_home
			s.move_cursor_right
			assert ("right skips the combining mark", s.cursor_position = 2)
			s.move_cursor_left
			assert ("left skips the combining mark", s.cursor_position = 0)
			s.delete_forward
			assert ("delete removes the whole cluster", s.value.same_string ("x"))
			s.move_cursor_end
			s.insert_character ('e')
			s.insert_character ({CHARACTER_32} '%/769/')
			s.delete_backward
			assert ("backspace removes the whole cluster", s.value.same_string ("x"))
			s.set_cursor_position (1)
			assert ("cursor column", s.cursor_column = 1)
		end

	test_text_input_renders_by_display_width
			-- Wide characters take two cells and the cursor highlights the cluster under it.
		local
			t: TUI_TEXT_INPUT
			s: TEXT_INPUT_STATE
			b: BUFFER
		do
			create t.make
			create s.make_with_text ({STRING_32} "a%/0x4E16/b")
			s.set_cursor_position (1)
			create b.make (8, 1)
			t.render_stateful (b.area, b, s)
			assert_buffer_lines ("wide text", b, <<{STRING_32} "a%/0x4E16/b    ">>)
			assert ("cursor on the wide char", b.cell (0, 1).style.is_reversed)
			assert ("char after the cursor not reversed", not b.cell (0, 3).style.is_reversed)
			assert ("hardware cursor", attached t.cursor_screen_position (b.area, s) as p and then p.col = 1 and then p.row = 0)
		end

	test_text_input_scrolls_by_column_and_keeps_invariant
			-- The view scrolls in columns; deleting text pulls it back (no invariant violation).
		local
			t: TUI_TEXT_INPUT
			s: TEXT_INPUT_STATE
			b: BUFFER
		do
			create t.make
			create s.make_with_text ({STRING_32} "%/0x4E16/%/0x754C/%/0x4E16/%/0x754C/")
			create b.make (4, 1)
			t.render_stateful (b.area, b, s)
			assert ("scrolled so that the end cursor fits", s.scroll_offset = 5)
			assert_buffer_lines ("scrolled wide text", b, <<{STRING_32} " %/0x754C/ ">>)
			assert ("cursor at the last column", attached t.cursor_screen_position (b.area, s) as p and then p.col = 3)

			s.delete_backward
			s.delete_backward
			s.delete_backward
			create b.make (4, 1)
			t.render_stateful (b.area, b, s)
			assert ("scroll pulled back", s.scroll_offset = 0)
			assert_buffer_lines ("after deleting", b, <<{STRING_32} "%/0x4E16/  ">>)
			assert ("cursor after the text", b.cell (0, 2).style.is_reversed)
		end

feature -- Tree and calendar

	test_tree_stays_in_area_and_follows_selection
			-- A narrow tree never writes right of its area; the view scrolls to the selection.
		local
			t: TUI_TREE
			s: TREE_STATE
			b: BUFFER
			l_root: TREE_NODE
		do
			create l_root.make_with_string ("root", "Root")
			l_root.add_child (create {TREE_NODE}.make_with_string ("a", "Alpha"))
			l_root.add_child (create {TREE_NODE}.make_with_string ("b", "Beta"))
			l_root.add_child (create {TREE_NODE}.make_with_string ("c", "Gamma"))
			create t.make_with_roots (<<l_root>>)
			create s.make
			s.expand_node ("root")
			s.select_node ("root")

			create b.make (8, 4)
			t.render_stateful (create {RECT}.make (0, 0, 2, 4), b, s)
			assert_buffer_lines ("clipped to two columns", b, <<">>      ", "        ", "        ", "        ">>)

			create b.make (12, 2)
			s.select_node ("c")
			t.render_stateful (b.area, b, s)
			assert ("scrolled to the selection", s.scroll_offset = 2)
			assert_buffer_lines ("selection visible", b, <<"       Beta ", {STRING_32} ">>     Gamma">>)

			t.select_previous (s)
			assert ("previous", attached s.selected_id as l_id and then l_id.same_string ("b"))
			t.select_next (s)
			t.select_next (s)
			assert ("next stops at the last node", attached s.selected_id as l_id and then l_id.same_string ("c"))
			assert ("visible nodes", t.visible_nodes (s).count = 4)
		end

	test_calendar_stays_in_narrow_area
			-- A calendar narrower than its grid is clipped to its area.
		local
			c: TUI_CALENDAR
			s: CALENDAR_STATE
			b: BUFFER
			r: INTEGER
		do
			create c.make
			create s.make_with_date (2026, 9, 27)
			create b.make (20, 8)
			c.render_stateful (create {RECT}.make (0, 0, 10, 8), b, s)
			from r := 0 until r >= 8 loop
				assert ("nothing right of the area on row " + r.out,
					buffer_row_as_string (b, r).substring (11, 20).same_string ("          "))
				r := r + 1
			end
			assert_buffer_lines ("first rows", b, <<"September           ", "Mo Tu We T          ", "    1  2            ">>)
		end

	test_calendar_weekday_before_year_one
			-- Navigating before year 1 keeps a valid weekday (proleptic Gregorian).
		local
			s: CALENDAR_STATE
		do
			create s.make_with_date (1, 1, 1)
			assert ("1 Jan 0001 is a Monday", s.day_of_week (1, 1, 1) = 1)
			assert ("1 Jan 0000 is a Saturday", s.day_of_week (0, 1, 1) = 6)
			assert ("1 Mar -0001 is a Monday", s.day_of_week (-1, 3, 1) = 1)
			s.previous_year
			s.previous_year
			assert ("first weekday stays valid", s.first_weekday_of_month >= 1 and s.first_weekday_of_month <= 7)
		end

feature -- Colors

	test_gray_is_ansi_7
			-- Ratatui `Color::Gray` is ANSI 7 and `DarkGray` ANSI 8.
		do
			assert ("gray", {COLOR}.gray.ansi_code = 7)
			assert ("dark gray", {COLOR}.dark_gray.ansi_code = 8)
		end

end
