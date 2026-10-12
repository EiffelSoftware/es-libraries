note
	description: "[
		Tests for Milestone G follow-up enhancements:
		- is_equal reliability across TUI_BLOCK, TUI_TABLE, TUI_CANVAS, TUI_CHART, and BLOCK_CONTAINER
		- Element isolation in copied lists, tables, and paragraphs
		- Tree auto-reselection of deepest visible ancestor when parent is collapsed
		- Calendar configurable first day of week and per-date styles
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_MILESTONE_G_FOLLOWUPS

inherit
	EQA_TEST_SET
	BUFFER_TEST_HELPER

feature -- is_equal Tests

	test_is_equal_differentiates_titles_and_borders
			-- TUI_BLOCK and BLOCK_CONTAINER differentiate titles, borders, and merging.
		local
			l_b1, l_b2: TUI_BLOCK
			l_p1, l_p2: TUI_PARAGRAPH
			l_title1, l_title2: BLOCK_TITLE
		do
			create l_b1.make
			create l_b2.make
			assert ("empty blocks equal", l_b1.is_equal (l_b2))

			-- Different title text
			create l_title1.make_raw ("Title A", {BLOCK_TITLE}.position_top, {TEXT_ALIGNMENT}.left)
			create l_title2.make_raw ("Title B", {BLOCK_TITLE}.position_top, {TEXT_ALIGNMENT}.left)
			l_b1.add_title (l_title1)
			assert ("block with title /= empty block", not l_b1.is_equal (l_b2))

			l_b2.add_title (l_title2)
			assert ("blocks with different title texts /= ", not l_b1.is_equal (l_b2))

			l_b2.clear_titles
			l_b2.add_title (create {BLOCK_TITLE}.make_raw ("Title A", {BLOCK_TITLE}.position_top, {TEXT_ALIGNMENT}.left))
			assert ("blocks with matching titles are equal", l_b1.is_equal (l_b2))

			-- Different is_border_merged
			l_b1.set_border_merged (True)
			assert ("different border_merged /=", not l_b1.is_equal (l_b2))
			l_b2.set_border_merged (True)
			assert ("matching border_merged equal", l_b1.is_equal (l_b2))

			-- Different border sets
			l_b1.set_border_set (create {BORDER_SET}.make_double)
			assert ("different border sets /=", not l_b1.is_equal (l_b2))
			l_b2.set_border_set (create {BORDER_SET}.make_double)
			assert ("matching border sets equal", l_b1.is_equal (l_b2))

			-- BLOCK_CONTAINER (TUI_PARAGRAPH)
			create l_p1.make_raw ("Content")
			create l_p2.make_raw ("Content")
			assert ("paragraphs equal", l_p1.is_equal (l_p2))

			l_p1.set_block (l_b1)
			assert ("paragraph with block /= paragraph without", not l_p1.is_equal (l_p2))
			l_p2.set_block (l_b2)
			assert ("paragraphs with matching blocks are equal", l_p1.is_equal (l_p2))
		end

	test_is_equal_table_and_canvas_and_chart
			-- TUI_TABLE, TUI_CANVAS, and TUI_CHART compare contents, not just list lengths.
		local
			l_tbl1, l_tbl2: TUI_TABLE
			l_row1, l_row2: TABLE_ROW
			l_cv1, l_cv2: TUI_CANVAS
			l_line1, l_line2: SHAPE_LINE
			l_ch1, l_ch2: TUI_CHART
			l_ds1, l_ds2: TUI_CHART_DATASET
			l_def_style: STYLE
		do
			create l_def_style.default_create

			-- Table comparison
			create l_tbl1.make_empty
			create l_tbl2.make_empty
			create l_row1.make_raw (<<"Row 1">>)
			create l_row2.make_raw (<<"Row 2">>)
			l_tbl1.append_row (l_row1)
			l_tbl2.append_row (l_row2)
			assert ("same count but different row contents /=", not l_tbl1.is_equal (l_tbl2))

			l_tbl2.rows.wipe_out
			l_tbl2.append_row (create {TABLE_ROW}.make_raw (<<"Row 1">>))
			assert ("matching table rows are equal", l_tbl1.is_equal (l_tbl2))

			-- Canvas comparison
			create l_cv1.make
			create l_cv2.make
			create l_line1.make (0.0, 0.0, 5.0, 5.0, l_def_style)
			create l_line2.make (0.0, 0.0, 1.0, 1.0, l_def_style)
			l_cv1.add_shape (l_line1)
			l_cv2.add_shape (l_line2)
			assert ("same shape count but different lines /=", not l_cv1.is_equal (l_cv2))

			l_cv2.shapes.wipe_out
			l_cv2.add_shape (create {SHAPE_LINE}.make (0.0, 0.0, 5.0, 5.0, l_def_style))
			assert ("matching canvas shapes are equal", l_cv1.is_equal (l_cv2))

			-- Chart comparison
			create l_ch1.make
			create l_ch2.make
			create l_ds1.make ("s1")
			l_ds1.append_point (1.0, 2.0)
			create l_ds2.make ("s1")
			l_ds2.append_point (3.0, 4.0)
			l_ch1.append_dataset (l_ds1)
			l_ch2.append_dataset (l_ds2)
			assert ("same dataset count but different points /=", not l_ch1.is_equal (l_ch2))

			l_ch2.datasets.wipe_out
			create l_ds2.make ("s1")
			l_ds2.append_point (1.0, 2.0)
			l_ch2.append_dataset (l_ds2)
			assert ("matching chart datasets are equal", l_ch1.is_equal (l_ch2))
		end

feature -- Element Isolation Tests

	test_copied_list_and_table_elements_isolated
			-- Mutating elements in copied lists, tables, and paragraphs does not affect the original.
			-- (Spans are immutable, so the copied line's text is replaced.)
		local
			l_list1, l_list2: TUI_LIST
			l_tbl1, l_tbl2: TUI_TABLE
			l_p1, l_p2: TUI_PARAGRAPH
		do
			-- TUI_LIST isolation
			create l_list1.make_empty
			l_list1.append_raw_item ("original item")
			l_list2 := l_list1.twin
			l_list2.items.first.content.lines.first.wipe_out
			l_list2.items.first.content.lines.first.append_span (create {TEXT_SPAN}.make_raw ("modified item"))
			assert ("original list item content unchanged", l_list1.items.first.content.to_plain_string.is_equal ("original item"))
			assert ("copied list item content updated", l_list2.items.first.content.to_plain_string.is_equal ("modified item"))

			-- TUI_TABLE isolation
			create l_tbl1.make_empty
			l_tbl1.append_row (create {TABLE_ROW}.make_raw (<<"original cell">>))
			l_tbl2 := l_tbl1.twin
			l_tbl2.rows.first.cells.first.content.lines.first.wipe_out
			l_tbl2.rows.first.cells.first.content.lines.first.append_span (create {TEXT_SPAN}.make_raw ("modified cell"))
			assert ("original table cell unchanged", l_tbl1.rows.first.cells.first.content.to_plain_string.is_equal ("original cell"))
			assert ("copied table cell updated", l_tbl2.rows.first.cells.first.content.to_plain_string.is_equal ("modified cell"))

			-- TUI_PARAGRAPH isolation
			create l_p1.make_raw ("original text")
			l_p2 := l_p1.twin
			l_p2.text.lines.first.wipe_out
			l_p2.text.lines.first.append_span (create {TEXT_SPAN}.make_raw ("modified text"))
			assert ("original paragraph text unchanged", l_p1.text.to_plain_string.is_equal ("original text"))
			assert ("copied paragraph text updated", l_p2.text.to_plain_string.is_equal ("modified text"))
		end

	test_copied_tabs_bars_and_tree_roots_isolated
			-- Tabs titles, bar items and tree roots are copied too, not shared.
		local
			l_tabs, l_tabs2: TUI_TABS
			l_chart, l_chart2: TUI_BARCHART
			l_tree, l_tree2: TUI_TREE
			l_node: TREE_NODE
		do
			create l_tabs.make_from_strings (<<"One">>)
			l_tabs2 := l_tabs.with_style (create {STYLE}.make_fg ({COLOR}.red))
			assert ("tabs copy equal", l_tabs2.titles.first ~ l_tabs.titles.first)
			l_tabs2.titles.first.append_span (create {TEXT_SPAN}.make_raw ("!"))
			assert ("original tab title unchanged", l_tabs.titles.first.width = 3)

			create l_chart.make_with_data (<<create {BAR_ITEM}.make ("a", 1)>>)
			l_chart2 := l_chart.with_bar_width (2)
			l_chart2.groups.first.bars.first.set_value (99)
			l_chart2.groups.first.bars.first.label.append ("x")
			assert ("original bar value unchanged", l_chart.bars.first.value = 1)
			assert ("original bar label unchanged", l_chart.bars.first.label.same_string ("a"))

			create l_node.make_with_string ("root", "Root")
			create l_tree.make
			l_tree2 := l_tree.with_root (l_node)
			l_node.add_child (create {TREE_NODE}.make_with_string ("late", "Added later"))
			assert ("tree keeps its own copy of the root", l_tree2.roots.first.children.is_empty)
		end

	test_block_title_copies_keep_mirroring
			-- A mirrored top title is drawn once after copying; an explicit `with_title`
			-- equal to another title is still drawn.
		local
			b: TUI_BLOCK
			l_buf: BUFFER
			l_row: STRING_32
		do
			create b.make
			b := b.with_title_top ("Main", {TEXT_ALIGNMENT}.center).with_style (create {STYLE}.make_bg ({COLOR}.blue))
			create l_buf.make (20, 3)
			b.render (l_buf.area, l_buf)
			l_row := buffer_row_as_string (l_buf, 0)
			assert ("mirrored title drawn once", l_row.occurrences ('M') = 1)

			create b.make
			b := b.with_title ("Main").with_title_top ("Main", {TEXT_ALIGNMENT}.right)
			create l_buf.make (20, 3)
			b.render (l_buf.area, l_buf)
			l_row := buffer_row_as_string (l_buf, 0)
			assert ("both equal titles drawn", l_row.occurrences ('M') = 2)
		end

	test_calendar_is_equal_compares_date_styles
			-- Calendars differing only in per-date styles are not equal.
		local
			c1, c2: TUI_CALENDAR
		do
			create c1.make
			c2 := c1.with_date_style (2026, 9, 27, create {STYLE}.make_fg ({COLOR}.red))
			assert ("different date styles", not c1.is_equal (c2))
			assert ("copy equal", c2.is_equal (c2.twin))
			assert ("same date style equal", c2.is_equal (c1.with_date_style (2026, 9, 27, create {STYLE}.make_fg ({COLOR}.red))))
		end

	test_copy_on_write_keeps_copies_independent
			-- Builders share content until one side accesses it; each side then works on its own
			-- copy, and a rendered copy shows the shared content.
		local
			l, l2: TUI_LIST
			p, p2: TUI_PARAGRAPH
			t, t2: TUI_TREE
			ch, ch2: TUI_CHART
			ds: TUI_CHART_DATASET
			cv, cv2: TUI_CANVAS
			tb, tb2: TUI_TABLE
			b: BUFFER
			s: LIST_STATE
		do
			create l.make_empty
			l.append_raw_item ("one")
			l.append_raw_item ("two")
			l2 := l.with_style (create {STYLE}.make_fg ({COLOR}.red)).with_highlight_symbol (">")
			create b.make (6, 2)
			create s.make
			l2.render_stateful (b.area, b, s)
			assert_buffer_lines ("copy renders the shared items", b, <<"one   ", "two   ">>)
			l2.items.first.content.lines.first.append_span (create {TEXT_SPAN}.make_raw ("!"))
			l.append_raw_item ("three")
			assert ("original item unchanged", l.items.first.content.lines.first.width = 3)
			assert ("copy count unchanged", l2.count = 2)
			assert ("original count", l.count = 3)

			create p.make_raw ("text")
			p2 := p.with_alignment ({TEXT_ALIGNMENT}.center)
			p2.text.lines.first.append_span (create {TEXT_SPAN}.make_raw ("!"))
			assert ("paragraph original unchanged", p.text.lines.first.width = 4)

			create t.make_with_roots (<<create {TREE_NODE}.make_with_string ("r", "Root")>>)
			t2 := t.with_indent_size (4)
			t2.roots.first.add_child (create {TREE_NODE}.make_with_string ("c", "Child"))
			assert ("tree original unchanged", t.roots.first.children.is_empty)

			create ds.make ("d")
			ds.append_point (0.0, 0.0)
			create ch.make_with_datasets (<<ds>>)
			ch2 := ch.with_block (create {TUI_BLOCK}.make)
			ch2.datasets.first.append_point (1.0, 1.0)
			assert ("chart original unchanged", ch.datasets.first.data.count = 1)

			create cv.make
			cv.add_shape (create {SHAPE_LINE}.make (0.0, 0.0, 1.0, 1.0, create {STYLE}))
			cv2 := cv.with_block (create {TUI_BLOCK}.make)
			cv2.add_shape (create {SHAPE_LINE}.make (0.0, 1.0, 1.0, 0.0, create {STYLE}))
			cv.add_layer (create {CANVAS_LAYER}.make)
			assert ("canvas original shapes", cv.shapes.count = 1)
			assert ("canvas copy layers", cv2.layers.is_empty)

			create tb.make_empty
			tb.append_row (create {TABLE_ROW}.make_raw (<<"a">>))
			tb2 := tb.with_column_spacing (2)
			tb2.rows.first.cells.first.content.lines.first.append_span (create {TEXT_SPAN}.make_raw ("!"))
			assert ("table original unchanged", tb.rows.first.cells.first.content.lines.first.width = 1)
			assert ("equal after copy", tb.is_equal (tb.twin))
		end

	test_tree_state_collapse_uses_recorded_path
			-- TREE_STATE.collapse_node alone moves a hidden selection to the collapsed node,
			-- once TUI_TREE has recorded the selected node's ancestors.
		local
			t: TUI_TREE
			s: TREE_STATE
			l_root, l_a: TREE_NODE
			b: BUFFER
		do
			create l_root.make_with_string ("root", "Root")
			create l_a.make_with_string ("a", "A")
			l_a.add_child (create {TREE_NODE}.make_with_string ("leaf", "Leaf"))
			l_root.add_child (l_a)
			create t.make_with_roots (<<l_root>>)
			create s.make
			s.expand_node ("root")
			s.expand_node ("a")
			assert ("expanded set", s.is_expanded ("a") and s.expanded_count = 2 and s.expanded_ids.count = 2)
			s.select_node ("leaf")
			create b.make (10, 4)
			t.render_stateful (b.area, b, s)
			assert ("path recorded", s.selected_ancestor_ids.count = 2)
			s.collapse_node ("a")
			assert ("selection moved to the collapsed node", attached s.selected_id as l_id and then l_id.same_string ("a"))
			assert ("path shortened", s.selected_ancestor_ids.count = 1)
			s.collapse_node ("root")
			assert ("selection moved to root", attached s.selected_id as l_id and then l_id.same_string ("root"))

			-- Navigation records the path too
			create s.make
			s.expand_node ("root")
			t.select_next (s)
			t.select_next (s)
			assert ("at a", attached s.selected_id as l_id and then l_id.same_string ("a"))
			s.collapse_node ("root")
			assert ("back to root", attached s.selected_id as l_id and then l_id.same_string ("root"))
		end

	test_calendar_shows_surrounding_days
			-- With `show_surrounding`, the first and last week show the adjacent months' days.
		local
			c: TUI_CALENDAR
			s: CALENDAR_STATE
			b: BUFFER
			l_dim: STYLE
		do
			create l_dim.make_fg ({COLOR}.dark_gray)
			create c.make
			c := c.with_show_month_header (False).with_show_weekday_header (False).with_show_surrounding (l_dim)
			-- September 2026 starts on a Tuesday and ends on a Wednesday (Monday first)
			create s.make_with_date (2026, 9, 10)
			create b.make (20, 5)
			c.render_stateful (b.area, b, s)
			assert_buffer_lines ("grid with surrounding days", b, <<
				"31  1  2  3  4  5  6",
				" 7  8  9 10 11 12 13",
				"14 15 16 17 18 19 20",
				"21 22 23 24 25 26 27",
				"28 29 30  1  2  3  4">>)
			assert ("previous month day dimmed", b.cell (0, 1).style.foreground.is_equal ({COLOR}.dark_gray))
			assert ("next month day dimmed", b.cell (4, 19).style.foreground.is_equal ({COLOR}.dark_gray))
			assert ("current month day not dimmed", not b.cell (1, 1).style.foreground.is_equal ({COLOR}.dark_gray))
			assert ("differs from the hidden version", not c.is_equal (c.with_show_surrounding (Void)))
		end

	test_calendar_rejects_impossible_date_style
			-- A date style for 31 February violates the precondition.
		local
			c: TUI_CALENDAR
			l_raised, l_retried: BOOLEAN
		do
			if not l_retried then
				create c.make
				c.set_date_style (2024, 2, 29, create {STYLE})
				if preconditions_monitored then
					c.set_date_style (2026, 2, 29, create {STYLE})
				else
					l_raised := True
				end
			end
			assert ("impossible date rejected", l_raised)
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

feature -- Tree Selection on Collapse Tests

	test_tree_collapse_reselects_visible_ancestor
			-- When a parent node is collapsed, any hidden descendant selection falls back to the parent.
		local
			l_tree: TUI_TREE
			l_root, l_child, l_grandchild: TREE_NODE
			l_state: TREE_STATE
			l_buf: BUFFER
			l_area: RECT
		do
			create l_root.make_with_string ("root", "Root Node")
			create l_child.make_with_string ("child", "Child Node")
			create l_grandchild.make_with_string ("leaf", "Grandchild Leaf")
			l_child.add_child (l_grandchild)
			l_root.add_child (l_child)

			create l_tree.make
			l_tree.add_root (l_root)
			create l_state.make

			-- Expand root and child, select grandchild
			l_state.expand_node ("root")
			l_state.expand_node ("child")
			l_state.select_node ("leaf")
			assert ("leaf is initially selected", attached l_state.selected_id as s and then s.is_equal ("leaf"))

			-- Collapse child via tree.collapse_node
			l_tree.collapse_node (l_state, "child")
			assert ("selection fell back to visible ancestor child", attached l_state.selected_id as s2 and then s2.is_equal ("child"))

			-- Re-expand child and select leaf again
			l_state.expand_node ("child")
			l_state.select_node ("leaf")

			-- Collapse root: selection should fall back to root
			l_tree.collapse_node (l_state, "root")
			assert ("selection fell back to visible ancestor root", attached l_state.selected_id as s3 and then s3.is_equal ("root"))

			-- Render check: verify rendering with stateful method does not highlight hidden node
			create l_buf.make (20, 5)
			create l_area.make (0, 0, 20, 5)
			l_tree.render_stateful (l_area, l_buf, l_state)
			assert ("root is visible on row 0", buffer_row_as_string (l_buf, 0).has_substring ("Root Node"))
		end

feature -- Calendar First Day and Styling Tests

	test_calendar_custom_first_day_and_date_styles
			-- TUI_CALENDAR supports configurable first_day_of_week and per-date styles.
		local
			l_cal: TUI_CALENDAR
			l_state: CALENDAR_STATE
			l_buf: BUFFER
			l_area: RECT
			l_style: STYLE
			l_hdr: STRING_32
		do
			create l_cal.make
			-- Default first day is Monday (1)
			assert ("default first day is Monday", l_cal.first_day_of_week = 1)
			assert ("default header starts with Mo", l_cal.weekday_header_string.starts_with ("Mo"))

			-- Set Sunday as first day of week (7)
			l_cal := l_cal.with_first_day_of_week (7)
			assert ("first day is Sunday", l_cal.first_day_of_week = 7)
			l_hdr := l_cal.weekday_header_string
			assert ("custom header starts with Su", l_hdr.starts_with ("Su"))
			assert ("custom header contains all 7 days", l_hdr.is_equal ("Su Mo Tu We Th Fr Sa"))

			-- Custom date styles: September 2026 (Sep 1 is Tuesday)
			-- Sep 15 style
			create l_style.make_fg ({COLOR}.green)
			l_cal := l_cal.with_date_style (2026, 9, 15, l_style)

			create l_state.make_with_date (2026, 9, 1)
			create l_buf.make (24, 9)
			create l_area.make (0, 0, 24, 9)
			l_cal.render_stateful (l_area, l_buf, l_state)

			-- Verify custom date style returned by custom_date_style query
			assert ("custom style present for Sep 15", attached l_cal.custom_date_style (2026, 9, 15) as cs and then cs.foreground ~ {COLOR}.green)
			assert ("no custom style for Sep 16", l_cal.custom_date_style (2026, 9, 16) = Void)
		end

end
