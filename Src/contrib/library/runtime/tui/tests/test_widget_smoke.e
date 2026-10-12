note
	description: "[
		Smoke tests for the whole widget layer: every widget, with and without a surrounding block,
		is rendered into awkward areas (zero-size, 1x1, touching or hanging off each buffer edge,
		completely outside the buffer). A render must never raise (precondition violations
		included) and must leave the buffer continuation-consistent.
		Widgets are configured with their optional features switched on (titles, padding,
		highlights, labels, legends, wide characters) so that those code paths are exercised too.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_WIDGET_SMOKE

inherit
	EQA_TEST_SET
	BUFFER_TEST_HELPER

feature -- Tests

	test_text_widgets_survive_awkward_areas
			-- Block, Paragraph, Clear, Tabs.
		do
			check_all (<<
				["block", agent render_block (?, ?)],
				["paragraph", agent render_paragraph (?, ?, False)],
				["paragraph+block", agent render_paragraph (?, ?, True)],
				["clear", agent render_clear (?, ?)],
				["tabs", agent render_tabs (?, ?, False)],
				["tabs+block", agent render_tabs (?, ?, True)]
			>>)
		end

	test_stateful_widgets_survive_awkward_areas
			-- List (both directions), Table, Scrollbar (4 orientations).
		do
			check_all (<<
				["list", agent render_list (?, ?, False, {LIST_DIRECTION}.top_to_bottom)],
				["list+block", agent render_list (?, ?, True, {LIST_DIRECTION}.top_to_bottom)],
				["list bottom-to-top", agent render_list (?, ?, True, {LIST_DIRECTION}.bottom_to_top)],
				["table", agent render_table (?, ?, False)],
				["table+block", agent render_table (?, ?, True)],
				["scrollbar right", agent render_scrollbar (?, ?, {SCROLLBAR_ORIENTATION}.vertical_right)],
				["scrollbar left", agent render_scrollbar (?, ?, {SCROLLBAR_ORIENTATION}.vertical_left)],
				["scrollbar bottom", agent render_scrollbar (?, ?, {SCROLLBAR_ORIENTATION}.horizontal_bottom)],
				["scrollbar top", agent render_scrollbar (?, ?, {SCROLLBAR_ORIENTATION}.horizontal_top)]
			>>)
		end

	test_metric_widgets_survive_awkward_areas
			-- Gauge, LineGauge, Sparkline (both directions), BarChart (both directions).
		do
			check_all (<<
				["gauge", agent render_gauge (?, ?, False)],
				["gauge+block", agent render_gauge (?, ?, True)],
				["line gauge", agent render_line_gauge (?, ?, False)],
				["line gauge+block", agent render_line_gauge (?, ?, True)],
				["sparkline", agent render_sparkline (?, ?, False, {SPARKLINE_DIRECTION}.left_to_right)],
				["sparkline+block rtl", agent render_sparkline (?, ?, True, {SPARKLINE_DIRECTION}.right_to_left)],
				["barchart vertical", agent render_barchart (?, ?, False, {BAR_CHART_DIRECTION}.vertical)],
				["barchart vertical+block", agent render_barchart (?, ?, True, {BAR_CHART_DIRECTION}.vertical)],
				["barchart horizontal", agent render_barchart (?, ?, False, {BAR_CHART_DIRECTION}.horizontal)],
				["barchart horizontal+block", agent render_barchart (?, ?, True, {BAR_CHART_DIRECTION}.horizontal)]
			>>)
		end

	test_canvas_widgets_survive_awkward_areas
			-- Canvas (every marker), Chart (every graph type and legend position).
		do
			check_all (<<
				["canvas braille", agent render_canvas (?, ?, False, {CANVAS_MARKER}.braille)],
				["canvas dot+block", agent render_canvas (?, ?, True, {CANVAS_MARKER}.dot)],
				["canvas block", agent render_canvas (?, ?, False, {CANVAS_MARKER}.block)],
				["canvas half block", agent render_canvas (?, ?, False, {CANVAS_MARKER}.half_block)],
				["chart top-right", agent render_chart (?, ?, False, {CHART_LEGEND_POSITION}.top_right)],
				["chart+block top-left", agent render_chart (?, ?, True, {CHART_LEGEND_POSITION}.top_left)],
				["chart bottom-right", agent render_chart (?, ?, False, {CHART_LEGEND_POSITION}.bottom_right)],
				["chart+block bottom-left", agent render_chart (?, ?, True, {CHART_LEGEND_POSITION}.bottom_left)]
			>>)
		end

	test_ecosystem_widgets_survive_awkward_areas
			-- TextInput (plain, masked, placeholder, wide text), Popup, Tree, Calendar.
		do
			check_all (<<
				["text input", agent render_text_input (?, ?, False, False, {STRING_32} "abc %/0x4E16/%/0x754C/ def")],
				["text input+block masked", agent render_text_input (?, ?, True, True, "secret")],
				["text input placeholder", agent render_text_input (?, ?, True, False, "")],
				["popup", agent render_popup (?, ?, False)],
				["popup+block", agent render_popup (?, ?, True)],
				["tree", agent render_tree (?, ?, False)],
				["tree+block", agent render_tree (?, ?, True)],
				["calendar", agent render_calendar (?, ?, False)],
				["calendar+block", agent render_calendar (?, ?, True)]
			>>)
		end

feature {NONE} -- Harness

	Buffer_width: INTEGER = 12
	Buffer_height: INTEGER = 6

	areas: ARRAY [TUPLE [name: STRING; area: RECT]]
			-- Awkward areas on a `Buffer_width` x `Buffer_height` buffer
		once
			Result := <<
				["zero", create {RECT}.make (0, 0, 0, 0)],
				["zero width", create {RECT}.make (0, 0, 0, 4)],
				["zero height", create {RECT}.make (0, 0, 8, 0)],
				["1x1 origin", create {RECT}.make (0, 0, 1, 1)],
				["1x1 bottom-right", create {RECT}.make (11, 5, 1, 1)],
				["2x2", create {RECT}.make (0, 0, 2, 2)],
				["3x1", create {RECT}.make (0, 0, 3, 1)],
				["full", create {RECT}.make (0, 0, 12, 6)],
				["past right", create {RECT}.make (7, 0, 12, 6)],
				["past bottom", create {RECT}.make (0, 3, 12, 6)],
				["past both", create {RECT}.make (9, 4, 10, 10)],
				["at right edge", create {RECT}.make (12, 0, 5, 6)],
				["at bottom edge", create {RECT}.make (0, 6, 12, 3)],
				["far outside", create {RECT}.make (40, 40, 8, 8)]
			>>
		end

	check_all (a_widgets: ARRAY [TUPLE [name: STRING; render: PROCEDURE [RECT, BUFFER]]])
			-- Render each of `a_widgets` into every area; fail listing every problem found.
		local
			l_failures: ARRAYED_LIST [STRING_32]
			l_message: STRING_32
		do
			create l_failures.make (0)
			across a_widgets as w loop
				across areas as a loop
					attempt (w.name, w.render, a.name, a.area, l_failures)
				end
			end
			if not l_failures.is_empty then
				create l_message.make_from_string_general (l_failures.count.out + " failure(s):")
				across l_failures as f loop
					l_message.append ({STRING_32} "%N    ")
					l_message.append (f)
				end
				print (l_message)
				print ("%N")
			end
			assert ("every widget survives every area (see the list above)", l_failures.is_empty)
		end

	attempt (a_widget: STRING; a_render: PROCEDURE [RECT, BUFFER]; a_area_name: STRING; a_area: RECT; a_failures: ARRAYED_LIST [STRING_32])
			-- Render `a_widget` into `a_area` of a fresh buffer; record a raised exception or an
			-- inconsistent buffer in `a_failures`.
		local
			l_buffer: BUFFER
			l_failed: BOOLEAN
			l_entry: STRING_32
		do
			if not l_failed then
				create l_buffer.make (Buffer_width, Buffer_height)
				a_render.call ([a_area, l_buffer])
				if not l_buffer.is_consistent then
					create l_entry.make_from_string_general (a_widget + " @ " + a_area_name + ": inconsistent buffer")
					a_failures.extend (l_entry)
				end
			end
		rescue
			l_failed := True
			create l_entry.make_from_string_general (a_widget + " @ " + a_area_name + ": ")
			if attached (create {EXCEPTION_MANAGER}).last_exception as e then
				if attached e.tag as t then
					l_entry.append_string_general (t)
				end
				if attached e.type_name as l_type and attached e.recipient_name as l_feature then
					l_entry.append_string_general (" in {" + l_type + "}." + l_feature)
				end
			end
			a_failures.extend (l_entry)
			retry
		end

feature {NONE} -- Widget builders

	sample_block: TUI_BLOCK
			-- Block with a background, several titles, padding and merged borders
		do
			create Result.make
			Result.set_style (create {STYLE}.make_bg ({COLOR}.blue))
			Result := Result.with_title ("Main")
				.with_title_top ("Right", {TEXT_ALIGNMENT}.right)
				.with_title_bottom ("Bottom", {TEXT_ALIGNMENT}.center)
				.with_four_sided_padding (create {PADDING}.make (0, 1, 0, 1))
				.with_border_merged (True)
		end

	render_block (a_area: RECT; a_buffer: BUFFER)
		do
			sample_block.render (a_area, a_buffer)
		end

	render_paragraph (a_area: RECT; a_buffer: BUFFER; a_with_block: BOOLEAN)
		local
			p: TUI_PARAGRAPH
		do
			create p.make_raw ({STRING_32} "Hello wide %/0x4E16/%/0x754C/ text that wraps%Nsecond line")
			p.set_wrap_mode ({TEXT_WRAP_MODE}.word, True)
			p.set_scroll (2, 1)
			if a_with_block then
				p.set_block (sample_block)
			end
			p.render (a_area, a_buffer)
		end

	render_clear (a_area: RECT; a_buffer: BUFFER)
		do
			(create {TUI_CLEAR}).render (a_area, a_buffer)
		end

	render_tabs (a_area: RECT; a_buffer: BUFFER; a_with_block: BOOLEAN)
		local
			t: TUI_TABS
		do
			create t.make_from_strings (<<{STRING_32} "One", {STRING_32} "%/0x4E16/%/0x754C/", {STRING_32} "Three">>)
			t.set_padding (" ", " ")
			t.set_divider (" | ")
			t.set_selected (2)
			t.set_highlight_style (create {STYLE}.make_bg ({COLOR}.red))
			if a_with_block then
				t.set_block (sample_block)
			end
			t.render (a_area, a_buffer)
		end

	render_list (a_area: RECT; a_buffer: BUFFER; a_with_block: BOOLEAN; a_direction: INTEGER)
		local
			l: TUI_LIST
			s: LIST_STATE
		do
			create l.make_empty
			l.append_raw_item ("First")
			l.append_raw_item ({STRING_32} "Second%Ntwo lines %/0x4E16/%/0x754C/")
			l.append_raw_item ("Third")
			l.append_raw_item ("Fourth")
			l.append_raw_item ("Fifth")
			l.set_highlight_symbol (">> ")
			l.set_highlight_style (create {STYLE}.make_bg ({COLOR}.green))
			l.set_style (create {STYLE}.make_bg ({COLOR}.black))
			l.set_repeat_highlight_symbol (True)
			l.set_scroll_padding (1)
			l.set_highlight_spacing ({HIGHLIGHT_SPACING}.always)
			l.set_direction (a_direction)
			if a_with_block then
				l.set_block (sample_block)
			end
			create s.make
			s.select_index (4)
			l.render_list (a_area, a_buffer, s)
		end

	render_table (a_area: RECT; a_buffer: BUFFER; a_with_block: BOOLEAN)
		local
			t: TUI_TABLE
			s: TABLE_STATE
		do
			create t.make_empty
			t.set_header (create {TABLE_ROW}.make_raw (<<{STRING_32} "ID", {STRING_32} "Name", {STRING_32} "%/0x4E16/%/0x754C/">>))
			t.append_row (create {TABLE_ROW}.make_raw (<<"1", "alpha", "x">>))
			t.append_row (create {TABLE_ROW}.make_raw (<<"2", "beta", "y">>))
			t.append_row (create {TABLE_ROW}.make_raw (<<"3", "gamma", "z">>))
			t.set_footer (create {TABLE_ROW}.make_raw (<<"T", "total", "3">>))
			t.set_widths (<<{CONSTRAINTS}.fixed (3), {CONSTRAINTS}.flex (1), {CONSTRAINTS}.fixed (4)>>)
			t.set_column_spacing (1)
			t.set_highlight_symbol (">> ")
			t.set_row_highlight_style (create {STYLE}.make_bg ({COLOR}.green))
			t.set_column_highlight_style (create {STYLE}.make_bg ({COLOR}.yellow))
			t.set_cell_highlight_style (create {STYLE}.make_bg ({COLOR}.red))
			if a_with_block then
				t.set_block (sample_block)
			end
			create s.make
			s.select_index (2)
			s.select_column (3)
			t.render_table (a_area, a_buffer, s)
		end

	render_scrollbar (a_area: RECT; a_buffer: BUFFER; a_orientation: NATURAL_8)
		local
			b: TUI_SCROLLBAR
			s: SCROLLBAR_STATE
		do
			create b.make (a_orientation)
			create s.make (20)
			s.set_position (7)
			s.set_viewport_content_length (4)
			b.render_scrollbar (a_area, a_buffer, s)
		end

	render_gauge (a_area: RECT; a_buffer: BUFFER; a_with_block: BOOLEAN)
		local
			g: TUI_GAUGE
		do
			create g.make
			g.set_percent (60)
			g.set_label ({STRING_32} "%/0x9032/%/0x6357/ 60%%")
			g.set_gauge_style (create {STYLE}.make_with_colors ({COLOR}.green, {COLOR}.black))
			if a_with_block then
				g.set_block (sample_block)
			end
			g.render (a_area, a_buffer)
		end

	render_line_gauge (a_area: RECT; a_buffer: BUFFER; a_with_block: BOOLEAN)
		local
			g: TUI_LINE_GAUGE
		do
			create g.make
			g.set_ratio (0.5)
			g.set_label ("Downloading")
			if a_with_block then
				g.set_block (sample_block)
			end
			g.render (a_area, a_buffer)
		end

	render_sparkline (a_area: RECT; a_buffer: BUFFER; a_with_block: BOOLEAN; a_direction: INTEGER)
		local
			s: TUI_SPARKLINE
		do
			create s.make_with_data ({ARRAY [NATURAL_64]} <<1, 5, 2, 8, 0, 3, 9, 4, 7, 6, 2, 1, 5, 8, 3>>)
			s.set_direction (a_direction)
			if a_with_block then
				s.set_block (sample_block)
			end
			s.render (a_area, a_buffer)
		end

	render_barchart (a_area: RECT; a_buffer: BUFFER; a_with_block: BOOLEAN; a_direction: NATURAL_8)
		local
			c: TUI_BARCHART
			g1, g2: BAR_GROUP
		do
			create g1.make_with_bars (<<create {BAR_ITEM}.make ("Alpha", 12), create {BAR_ITEM}.make ("B", 1234)>>)
			g1.set_label ("Group one")
			create g2.make_with_bars (<<create {BAR_ITEM}.make ({STRING_32} "%/0x4E16/%/0x754C/", 40), create {BAR_ITEM}.make ("D", 0)>>)
			g2.set_label ("G2")
			create c.make_with_data (create {ARRAYED_LIST [BAR_ITEM]}.make (0))
			c.set_groups (<<g1, g2>>)
			c.set_group_gap (2)
			c.set_bar_width (2)
			c.set_bar_gap (1)
			c.set_direction (a_direction)
			if a_with_block then
				c.set_block (sample_block)
			end
			c.render (a_area, a_buffer)
		end

	render_canvas (a_area: RECT; a_buffer: BUFFER; a_with_block: BOOLEAN; a_marker: NATURAL_8)
		local
			c: TUI_CANVAS
		do
			create c.make
			c.set_bounds (0.0, 100.0, 0.0, 50.0)
			c.set_marker (a_marker)
			c.add_shape (create {SHAPE_LINE}.make (-50.0, -20.0, 150.0, 80.0, create {STYLE}.make_fg ({COLOR}.red)))
			c.add_shape (create {SHAPE_RECT}.make (10.0, 10.0, 200.0, 30.0, create {STYLE}.make_fg ({COLOR}.green)))
			c.add_shape (create {SHAPE_CIRCLE}.make (90.0, 45.0, 30.0, create {STYLE}.make_fg ({COLOR}.blue)))
			c.add_shape (create {SHAPE_POINTS}.make (<<[0.0, 0.0], [100.0, 50.0], [-5.0, 60.0]>>, create {STYLE}.make_fg ({COLOR}.yellow)))
			c.add_layer (create {CANVAS_LAYER}.make_with_shapes (<<create {SHAPE_LINE}.make (0.0, 50.0, 100.0, 0.0, create {STYLE})>>))
			c.set_painter (agent (p: CANVAS_PAINTER) do p.draw_text (95.0, 48.0, {STRING_32} "Label %/0x4E16/%/0x754C/", create {STYLE}) end)
			if a_with_block then
				c.set_block (sample_block)
			end
			c.render (a_area, a_buffer)
		end

	render_chart (a_area: RECT; a_buffer: BUFFER; a_with_block: BOOLEAN; a_legend: NATURAL_8)
		local
			c: TUI_CHART
			d1, d2, d3: TUI_CHART_DATASET
		do
			create d1.make ("line")
			d1.append_point (0.0, 1.0); d1.append_point (5.0, 9.0); d1.append_point (10.0, 4.0)
			d1.set_graph_type ({CHART_GRAPH_TYPE}.line)
			create d2.make ({STRING_32} "scatter %/0x4E16/%/0x754C/")
			d2.append_point (2.0, 2.0); d2.append_point (12.0, -3.0)
			d2.set_graph_type ({CHART_GRAPH_TYPE}.scatter)
			d2.set_marker ({CANVAS_MARKER}.dot)
			create d3.make ("bars")
			d3.append_point (3.0, 6.0); d3.append_point (7.0, 8.0)
			d3.set_graph_type ({CHART_GRAPH_TYPE}.bar)
			create c.make_with_datasets (<<d1, d2, d3>>)
			c.set_x_bounds (0.0, 10.0)
			c.set_y_bounds (0.0, 10.0)
			c.set_x_labels (<<"0", "5", "10">>)
			c.set_y_labels (<<"0", "5", "10">>)
			c.set_x_title ("Time axis")
			c.set_y_title ("Value")
			c.set_legend (True, a_legend)
			if a_with_block then
				c.set_block (sample_block)
			end
			c.render (a_area, a_buffer)
		end

	render_text_input (a_area: RECT; a_buffer: BUFFER; a_with_block, a_masked: BOOLEAN; a_text: READABLE_STRING_GENERAL)
		local
			t: TUI_TEXT_INPUT
			s: TEXT_INPUT_STATE
		do
			create t.make
			t := t.with_placeholder ({STRING_32} "Type %/0x4E16/%/0x754C/ here")
			if a_masked then
				t := t.with_mask_char ('*')
			end
			if a_with_block then
				t := t.with_block (sample_block)
			end
			create s.make_with_text (a_text)
			s.set_cursor_position (3)
			t.render_stateful (a_area, a_buffer, s)
		end

	render_popup (a_area: RECT; a_buffer: BUFFER; a_with_block: BOOLEAN)
		local
			p: TUI_POPUP
		do
			create p.make_with_widget (create {TUI_PARAGRAPH}.make_raw ({STRING_32} "Popup %/0x4E16/%/0x754C/ body"))
			if a_with_block then
				p := p.with_block (sample_block)
			end
			p.render (a_area, a_buffer)
		end

	render_tree (a_area: RECT; a_buffer: BUFFER; a_with_block: BOOLEAN)
		local
			t: TUI_TREE
			s: TREE_STATE
			l_root, l_child: TREE_NODE
		do
			create l_root.make_with_string ("root", "Root node")
			create l_child.make_with_string ("child", {STRING_32} "Child %/0x4E16/%/0x754C/")
			l_child.add_child (create {TREE_NODE}.make_with_string ("leaf", "Leaf"))
			l_root.add_child (l_child)
			l_root.add_child (create {TREE_NODE}.make_with_string ("other", "Other"))
			create t.make_with_roots (<<l_root, create {TREE_NODE}.make_with_string ("second", "Second root")>>)
			if a_with_block then
				t := t.with_block (sample_block)
			end
			create s.make
			s.expand_node ("root")
			s.expand_node ("child")
			s.select_node ("leaf")
			t.render_stateful (a_area, a_buffer, s)
		end

	render_calendar (a_area: RECT; a_buffer: BUFFER; a_with_block: BOOLEAN)
		local
			c: TUI_CALENDAR
			s: CALENDAR_STATE
		do
			create c.make
			if a_with_block then
				c := c.with_block (sample_block)
			end
			create s.make_with_date (2026, 9, 27)
			c.render_stateful (a_area, a_buffer, s)
		end

end
