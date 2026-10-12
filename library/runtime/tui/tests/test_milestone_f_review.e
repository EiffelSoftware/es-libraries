note
	description: "[
		Regression tests for the Milestone F review (2026-09-27). Each test failed on the code
		as first delivered for Milestone F (crashes are covered by TEST_WIDGET_SMOKE):
		- List: HIGHLIGHT_SPACING.Never still drew the symbol; scrolling counted items instead of
		  rows (multi-line items hid the selection); scroll padding left blank rows at the end
		- BarChart horizontal: a bar at the maximum never showed its value
		- Block: the `with_title` title disappeared once another title was added
		- Chart: non-Braille scatter markers were converted to cells twice and vanished;
		  the y title overwrote the first y label; y labels ran top-down
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_MILESTONE_F_REVIEW

inherit
	EQA_TEST_SET
	BUFFER_TEST_HELPER

feature -- List

	test_list_highlight_spacing
			-- Never: no symbol and no indent; When_selected: indent only while something is selected;
			-- Always: indent for every item.
		local
			l_buf: BUFFER
			l_list: TUI_LIST
			l_state: LIST_STATE
		do
			l_list := two_item_list
			l_list.set_highlight_spacing ({HIGHLIGHT_SPACING}.never)
			create l_state.make
			l_state.select_index (1)
			create l_buf.make (8, 2)
			l_list.render_list (l_buf.area, l_buf, l_state)
			assert_buffer_lines ("never", l_buf, <<"A       ", "B       ">>)

			l_list := two_item_list
			l_list.set_highlight_spacing ({HIGHLIGHT_SPACING}.when_selected)
			create l_state.make
			create l_buf.make (8, 2)
			l_list.render_list (l_buf.area, l_buf, l_state)
			assert_buffer_lines ("when selected, nothing selected", l_buf, <<"A       ", "B       ">>)
			l_state.select_index (2)
			create l_buf.make (8, 2)
			l_list.render_list (l_buf.area, l_buf, l_state)
			assert_buffer_lines ("when selected, item 2 selected", l_buf, <<"  A     ", "> B     ">>)

			l_list := two_item_list
			l_list.set_highlight_spacing ({HIGHLIGHT_SPACING}.always)
			create l_state.make
			create l_buf.make (8, 2)
			l_list.render_list (l_buf.area, l_buf, l_state)
			assert_buffer_lines ("always", l_buf, <<"  A     ", "  B     ">>)
		end

	test_list_scrolls_by_rows
			-- With multi-line items the viewport is measured in rows, so the selection stays visible.
		local
			l_buf: BUFFER
			l_list: TUI_LIST
			l_state: LIST_STATE
		do
			create l_list.make_empty
			l_list.append_raw_item ("I1a%NI1b")
			l_list.append_raw_item ("I2a%NI2b")
			l_list.append_raw_item ("I3a%NI3b")
			create l_state.make
			l_state.select_index (3)
			create l_buf.make (4, 4)
			l_list.render_list (l_buf.area, l_buf, l_state)
			assert_buffer_lines ("items 2 and 3 shown", l_buf, <<"I2a ", "I2b ", "I3a ", "I3b ">>)
		end

	test_list_scroll_padding_leaves_no_blank_rows
			-- Near the end of the list the padding does not push items off and leave blank rows.
		local
			l_buf: BUFFER
			l_list: TUI_LIST
			l_state: LIST_STATE
			i: INTEGER
		do
			create l_list.make_empty
			from i := 1 until i > 5 loop
				l_list.append_raw_item ("I" + i.out)
				i := i + 1
			end
			create l_state.make
			l_state.set_scroll_padding (1)
			l_state.select_index (5)
			create l_buf.make (3, 3)
			l_list.render_list (l_buf.area, l_buf, l_state)
			assert_buffer_lines ("last three items", l_buf, <<"I3 ", "I4 ", "I5 ">>)

			l_state.select_index (3)
			l_list.render_list (l_buf.area, l_buf, l_state)
			assert ("padding keeps a neighbour above", l_state.offset = 2)
		end

feature -- BarChart

	test_horizontal_bar_value_at_maximum
			-- A bar filling its row shows its value over the start of the bar.
		local
			l_buf: BUFFER
			l_chart: TUI_BARCHART
		do
			create l_buf.make (10, 1)
			create l_chart.make_with_data (<<create {BAR_ITEM}.make ("A", 50)>>)
			l_chart.set_direction ({BAR_CHART_DIRECTION}.horizontal)
			l_chart.render (l_buf.area, l_buf)
			assert_buffer_lines ("value inside the full bar", l_buf, <<{STRING_32} "A 50%/0x2588/%/0x2588/%/0x2588/%/0x2588/%/0x2588/%/0x2588/">>)
		end

feature -- Block

	test_block_title_kept_with_other_titles
			-- `with_title` and `with_title_bottom` are both drawn.
		local
			l_buf: BUFFER
			l_block: TUI_BLOCK
		do
			create l_buf.make (12, 3)
			create l_block.make
			l_block := l_block.with_title ("Top").with_title_bottom ("Bot", {TEXT_ALIGNMENT}.right)
			l_block.render (l_buf.area, l_buf)
			assert ("top title", l_buf.line (0).has_substring ({STRING_32} "Top"))
			assert ("bottom title", l_buf.line (2).has_substring ({STRING_32} "Bot"))
		end

feature -- Chart

	test_chart_dot_marker_is_drawn
			-- A scatter point with a non-Braille marker is drawn at its data position.
		local
			l_buf: BUFFER
			l_chart: TUI_CHART
			l_data: TUI_CHART_DATASET
			l_found_col: INTEGER
			r, c: INTEGER
		do
			create l_buf.make (21, 11)
			create l_data.make ("pts")
			l_data.append_point (5.0, 5.0)
			l_data.set_graph_type ({CHART_GRAPH_TYPE}.scatter)
			l_data.set_marker ({CANVAS_MARKER}.dot)
			create l_chart.make_with_datasets (<<l_data>>)
			l_chart.set_x_bounds (0.0, 10.0)
			l_chart.set_y_bounds (0.0, 10.0)
			l_chart.render (l_buf.area, l_buf)
			l_found_col := -1
			from r := 0 until r >= l_buf.height loop
				from c := 0 until c >= l_buf.width loop
					if l_buf.cell (r, c).symbol.count = 1 and then l_buf.cell (r, c).symbol.item (1) = l_data.marker_char then
						l_found_col := c
					end
					c := c + 1
				end
				r := r + 1
			end
			assert ("marker drawn", l_found_col >= 0)
			assert ("marker near the middle of the plot", l_found_col >= 9 and l_found_col <= 12)
		end

	test_chart_y_title_and_label_order
			-- The y title has its own row; y labels run from the y minimum at the bottom up.
		local
			l_buf: BUFFER
			l_chart: TUI_CHART
			l_data: TUI_CHART_DATASET
		do
			create l_buf.make (20, 8)
			create l_data.make ("s")
			l_data.append_point (1.0, 1.0)
			create l_chart.make_with_datasets (<<l_data>>)
			l_chart.set_x_bounds (0.0, 10.0)
			l_chart.set_y_bounds (0.0, 20.0)
			l_chart.set_y_labels (<<"0", "10", "20">>)
			l_chart.set_y_title ("Value")
			l_chart.render (l_buf.area, l_buf)
			assert ("y title intact", l_buf.line (0).starts_with ({STRING_32} "Value"))
			assert ("top label is the maximum", l_buf.line (1).starts_with ({STRING_32} "20"))
			assert ("bottom label is the minimum", l_buf.line (6).starts_with ({STRING_32} " 0"))
		end

feature {NONE} -- Helpers

	two_item_list: TUI_LIST
			-- List "A", "B" with highlight symbol "> "
		do
			create Result.make_empty
			Result.append_raw_item ("A")
			Result.append_raw_item ("B")
			Result.set_highlight_symbol ("> ")
		end

end
