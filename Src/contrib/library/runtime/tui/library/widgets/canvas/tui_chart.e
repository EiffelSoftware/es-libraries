note
	description: "[
		Chart widget plotting 2D line and scatter datasets with labeled X and Y axes
		using TUI_CANVAS and Braille sub-pixel rendering.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_CHART

inherit
	WIDGET
		redefine
			copy,
			is_equal
		end
	BLOCK_CONTAINER
		redefine
			copy,
			is_equal
		end

create
	make,
	make_with_datasets

feature {NONE} -- Initialization

	make
			-- Initialize chart with default [0.0, 1.0] bounds.
		do
			set_block (Void)
			create dataset_store.make (4)
			x_bounds := [0.0, 1.0]
			y_bounds := [0.0, 1.0]
			create axis_style.default_create
			is_legend_visible := False
			legend_position := {CHART_LEGEND_POSITION}.top_right
			legend_hidden_ratio := 0.25
			x_label_alignment := {TEXT_ALIGNMENT}.center
			y_label_alignment := {TEXT_ALIGNMENT}.right
		ensure
			datasets_empty: datasets.is_empty
			x_min_default: x_bounds.min = 0.0
			x_max_default: x_bounds.max = 1.0
			y_min_default: y_bounds.min = 0.0
			y_max_default: y_bounds.max = 1.0
			legend_hidden_by_default: not is_legend_visible
			default_legend_pos: legend_position = {CHART_LEGEND_POSITION}.top_right
			no_block: block = Void
		end

feature -- Duplication

	copy (a_other: like Current)
			-- Re-create datasets and label lists on copy.
		local
			l_x_labels, l_y_labels: ARRAYED_LIST [STRING_32]
		do
			if a_other /= Current then
				standard_copy (a_other)
				datasets_shared := True
				a_other.mark_datasets_shared
				if attached a_other.x_labels as xl then
					create l_x_labels.make (xl.count)
					across xl as s loop
						l_x_labels.extend (s.twin)
					end
					x_labels := l_x_labels
				end
				if attached a_other.y_labels as yl then
					create l_y_labels.make (yl.count)
					across yl as s loop
						l_y_labels.extend (s.twin)
					end
					y_labels := l_y_labels
				end
			end
		end

	is_equal (a_other: like Current): BOOLEAN
			-- Is `a_other` content-equal to `Current`?
		local
			i: INTEGER
		do
			if a_other = Current then
				Result := True
			elseif standard_is_equal (a_other) then
				Result := True
			elseif x_bounds.min = a_other.x_bounds.min
				and x_bounds.max = a_other.x_bounds.max
				and y_bounds.min = a_other.y_bounds.min
				and y_bounds.max = a_other.y_bounds.max
				and is_legend_visible = a_other.is_legend_visible
				and legend_position = a_other.legend_position
				and legend_hidden_ratio = a_other.legend_hidden_ratio
				and x_label_alignment = a_other.x_label_alignment
				and y_label_alignment = a_other.y_label_alignment
				and same_block (a_other)
				and axis_style.is_equal (a_other.axis_style)
				and x_title ~ a_other.x_title
				and y_title ~ a_other.y_title
				and same_labels (x_labels, a_other.x_labels)
				and same_labels (y_labels, a_other.y_labels)
				and dataset_store.count = a_other.dataset_store.count
			then
				Result := True
				from
					i := 1
				until
					i > dataset_store.count or not Result
				loop
					Result := dataset_store [i].is_equal (a_other.dataset_store [i])
					i := i + 1
				end
			end
		end

	make_with_datasets (a_datasets: ITERABLE [TUI_CHART_DATASET])
			-- Initialize chart with `a_datasets`.
		require
			datasets_not_void: a_datasets /= Void
		do
			make
			across
				a_datasets as ds
			loop
				datasets.extend (ds)
			end
		end

feature {TUI_CHART} -- Copy on write

	dataset_store: ARRAYED_LIST [TUI_CHART_DATASET]
			-- Datasets, possibly shared with copies of `Current` (see `datasets_shared`)

	datasets_shared: BOOLEAN
			-- Is `dataset_store` shared with another object?

	mark_datasets_shared
			-- Record that `dataset_store` is now shared with a copy.
		do
			datasets_shared := True
		ensure
			shared: datasets_shared
		end

	own_datasets
			-- Give `Current` its own copy of the datasets if they are shared.
		do
			if datasets_shared then
				dataset_store := copied_datasets (dataset_store)
				datasets_shared := False
			end
		ensure
			not_shared: not datasets_shared
		end

feature {NONE} -- Copy on write

	copied_datasets (a_list: ARRAYED_LIST [TUI_CHART_DATASET]): ARRAYED_LIST [TUI_CHART_DATASET]
			-- Copy of `a_list` holding copies of its elements
		do
			create Result.make (a_list.count)
			across a_list as e loop
				Result.extend (e.twin)
			end
		end

feature -- Access

	datasets: ARRAYED_LIST [TUI_CHART_DATASET]
			-- Datasets plotted on chart (owned by `Current`: content still shared with a copy is copied first)
		do
			own_datasets
			Result := dataset_store
		ensure
			owned: not datasets_shared
		end

	x_bounds: TUPLE [min, max: REAL_64]
			-- X-axis world bounds [min, max].

	y_bounds: TUPLE [min, max: REAL_64]
			-- Y-axis world bounds [min, max].

	x_labels: detachable ARRAYED_LIST [STRING_32]
			-- Optional X-axis labels.

	y_labels: detachable ARRAYED_LIST [STRING_32]
			-- Optional Y-axis labels.

	x_title: detachable STRING_32
			-- Optional X-axis title.

	y_title: detachable STRING_32
			-- Optional Y-axis title.

	x_label_alignment: NATURAL_8
			-- Alignment of X-axis labels ({TEXT_ALIGNMENT}.left, center, right).

	y_label_alignment: NATURAL_8
			-- Alignment of Y-axis labels ({TEXT_ALIGNMENT}.left, center, right).

	is_legend_visible: BOOLEAN
			-- Is dataset legend displayed?

	legend_hidden_ratio: REAL_64
			-- The legend is hidden when it is wider or taller than this fraction of the plot
			-- (Ratatui `hidden_legend_constraints`, default 1/4 of each dimension)

	legend_position: NATURAL_8
			-- Legend placement position ({CHART_LEGEND_POSITION}.top_right, etc.).

	axis_style: STYLE
			-- Style for axes and axis labels.

feature -- Configuration

	append_dataset (a_dataset: TUI_CHART_DATASET)
			-- Append `a_dataset` to chart.
		require
			dataset_not_void: a_dataset /= Void
		do
			datasets.extend (a_dataset)
		ensure
			one_more: datasets.count = old datasets.count + 1
		end

	set_x_bounds (a_min, a_max: REAL_64)
			-- Set X-axis world bounds.
		require
			valid_range: a_min < a_max
		do
			x_bounds := [a_min, a_max]
		ensure
			bounds_set: x_bounds.min = a_min and x_bounds.max = a_max
		end

	set_y_bounds (a_min, a_max: REAL_64)
			-- Set Y-axis world bounds.
		require
			valid_range: a_min < a_max
		do
			y_bounds := [a_min, a_max]
		ensure
			bounds_set: y_bounds.min = a_min and y_bounds.max = a_max
		end

	set_x_labels (a_labels: detachable ITERABLE [READABLE_STRING_GENERAL])
			-- Set X-axis labels.
		local
			l_list: ARRAYED_LIST [STRING_32]
			l_str: STRING_32
		do
			if attached a_labels as lbls then
				create l_list.make (5)
				across
					lbls as l
				loop
					create l_str.make_from_string_general (l)
					l_list.extend (l_str)
				end
				x_labels := l_list
			else
				x_labels := Void
			end
		ensure
			labels_set: attached a_labels implies attached x_labels
		end

	set_y_labels (a_labels: detachable ITERABLE [READABLE_STRING_GENERAL])
			-- Set Y-axis labels.
		local
			l_list: ARRAYED_LIST [STRING_32]
			l_str: STRING_32
		do
			if attached a_labels as lbls then
				create l_list.make (5)
				across
					lbls as l
				loop
					create l_str.make_from_string_general (l)
					l_list.extend (l_str)
				end
				y_labels := l_list
			else
				y_labels := Void
			end
		ensure
			labels_set: attached a_labels implies attached y_labels
		end

	set_x_title (a_title: detachable READABLE_STRING_GENERAL)
			-- Set X-axis title.
		do
			if attached a_title as t then
				create x_title.make_from_string_general (t)
			else
				x_title := Void
			end
		ensure
			title_set: attached a_title implies attached x_title
		end

	set_y_title (a_title: detachable READABLE_STRING_GENERAL)
			-- Set Y-axis title.
		do
			if attached a_title as t then
				create y_title.make_from_string_general (t)
			else
				y_title := Void
			end
		ensure
			title_set: attached a_title implies attached y_title
		end

	set_x_label_alignment (a_align: NATURAL_8)
			-- Set X-axis label alignment.
		require
			valid_align: {TEXT_ALIGNMENT}.is_valid (a_align)
		do
			x_label_alignment := a_align
		ensure
			align_set: x_label_alignment = a_align
		end

	set_y_label_alignment (a_align: NATURAL_8)
			-- Set Y-axis label alignment.
		require
			valid_align: {TEXT_ALIGNMENT}.is_valid (a_align)
		do
			y_label_alignment := a_align
		ensure
			align_set: y_label_alignment = a_align
		end

	set_legend_hidden_ratio (a_ratio: REAL_64)
			-- Hide the legend when it exceeds `a_ratio` of the plot width or height
			-- (1.0: only when it does not fit at all).
		require
			valid_ratio: a_ratio > 0.0 and a_ratio <= 1.0
		do
			legend_hidden_ratio := a_ratio
		ensure
			ratio_set: legend_hidden_ratio = a_ratio
		end

	set_legend (a_visible: BOOLEAN; a_position: NATURAL_8)
			-- Configure legend visibility and position.
		require
			valid_position: {CHART_LEGEND_POSITION}.is_valid (a_position)
		do
			is_legend_visible := a_visible
			legend_position := a_position
		ensure
			visible_set: is_legend_visible = a_visible
			pos_set: legend_position = a_position
		end

	set_axis_style (a_style: STYLE)
			-- Set style for axes and axis labels.
		require
			style_not_void: a_style /= Void
		do
			axis_style := a_style
		ensure
			style_set: axis_style = a_style
		end


feature -- Fluent Builders

	with_x_title (a_title: READABLE_STRING_GENERAL): like Current
			-- Chart with X title `a_title`.
		require
			title_not_void: a_title /= Void
		do
			Result := twin
			Result.set_x_title (a_title)
		end

	with_y_title (a_title: READABLE_STRING_GENERAL): like Current
			-- Chart with Y title `a_title`.
		require
			title_not_void: a_title /= Void
		do
			Result := twin
			Result.set_y_title (a_title)
		end

	with_legend (a_visible: BOOLEAN; a_position: NATURAL_8): like Current
			-- Chart with legend setting.
		require
			valid_position: {CHART_LEGEND_POSITION}.is_valid (a_position)
		do
			Result := twin
			Result.set_legend (a_visible, a_position)
		ensure
			visible_set: Result.is_legend_visible = a_visible
			pos_set: Result.legend_position = a_position
		end

	with_x_label_alignment (a_align: NATURAL_8): like Current
			-- Chart with X label alignment `a_align`.
		require
			valid_align: {TEXT_ALIGNMENT}.is_valid (a_align)
		do
			Result := twin
			Result.set_x_label_alignment (a_align)
		ensure
			align_set: Result.x_label_alignment = a_align
		end

	with_y_label_alignment (a_align: NATURAL_8): like Current
			-- Chart with Y label alignment `a_align`.
		require
			valid_align: {TEXT_ALIGNMENT}.is_valid (a_align)
		do
			Result := twin
			Result.set_y_label_alignment (a_align)
		ensure
			align_set: Result.y_label_alignment = a_align
		end

feature -- Fluent Builders

	with_x_bounds (a_min, a_max: REAL_64): like Current
			-- Chart with X bounds `a_min`..`a_max`.
		require
			valid_range: a_min < a_max
		do
			Result := twin
			Result.set_x_bounds (a_min, a_max)
		ensure
			bounds_set: Result.x_bounds.min = a_min and Result.x_bounds.max = a_max
		end

	with_y_bounds (a_min, a_max: REAL_64): like Current
			-- Chart with Y bounds `a_min`..`a_max`.
		require
			valid_range: a_min < a_max
		do
			Result := twin
			Result.set_y_bounds (a_min, a_max)
		ensure
			bounds_set: Result.y_bounds.min = a_min and Result.y_bounds.max = a_max
		end

	with_axis_style (a_style: STYLE): like Current
			-- Chart with axis style `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_axis_style (a_style)
		ensure
			style_set: Result.axis_style = a_style
		end

	with_x_labels (a_labels: detachable ITERABLE [READABLE_STRING_GENERAL]): like Current
			-- Chart with X-axis labels `a_labels`.
		do
			Result := twin
			Result.set_x_labels (a_labels)
		end

	with_y_labels (a_labels: detachable ITERABLE [READABLE_STRING_GENERAL]): like Current
			-- Chart with Y-axis labels `a_labels`.
		do
			Result := twin
			Result.set_y_labels (a_labels)
		end

	with_dataset (a_dataset: TUI_CHART_DATASET): like Current
			-- Chart with appended `a_dataset`.
		require
			dataset_not_void: a_dataset /= Void
		do
			Result := twin
			Result.append_dataset (a_dataset)
		end

feature -- Rendering

	render (a_area: RECT; a_buffer: BUFFER)
			-- Render chart inside `a_area` into `a_buffer`.
		local
			l_target: RECT
			l_y_axis_w, l_x_axis_h: INTEGER
			l_plot_x, l_plot_y, l_plot_w, l_plot_h: INTEGER
			l_plot_rect: RECT
			l_canvas: TUI_CANVAS
			l_layer: CANVAS_LAYER
			l_lbl_w, l_max_y_w: INTEGER
			l_y_step, r, c: INTEGER
			l_abs_x, l_abs_y, l_lbl_x: INTEGER
			l_lbl: STRING_32
			l_lbl_idx: INTEGER
			l_xt_w, l_xt_row: INTEGER
			l_title_h, l_left, l_right: INTEGER
		do
			if not a_area.is_empty then
				render_block (a_area, a_buffer)
				l_target := inner_area (a_area)

				if not l_target.is_empty and l_target.width > 2 and l_target.height > 2 then
					-- Compute Y-axis label column width
					l_max_y_w := 0
					if attached y_labels as yls and then not yls.is_empty then
						across
							yls as yl
						loop
							l_lbl_w := {UNICODE_WIDTH}.string_width (yl).to_integer_32
							if l_lbl_w > l_max_y_w then
								l_max_y_w := l_lbl_w
							end
						end
					end

					l_y_axis_w := l_max_y_w + 1 -- labels + 1 for vertical axis line '│'
					l_x_axis_h := 1              -- 1 for horizontal axis line '─'
					if attached x_labels as xls and then not xls.is_empty then
						l_x_axis_h := 2          -- 1 for axis line + 1 for labels row
					end
					if attached x_title then
						l_x_axis_h := l_x_axis_h + 1
					end
					-- The y title gets its own row above the plot (top-left, as in Ratatui)
					if attached y_title then
						l_title_h := 1
					end

					-- Ensure plot area is at least 1x1
					if (l_target.width.to_integer_32 - l_y_axis_w) >= 1 and (l_target.height.to_integer_32 - l_x_axis_h - l_title_h) >= 1 then
						l_left := l_target.x.to_integer_32
						l_right := l_target.right.to_integer_32
						l_plot_x := l_left + l_y_axis_w
						l_plot_y := l_target.y.to_integer_32 + l_title_h
						l_plot_w := l_target.width.to_integer_32 - l_y_axis_w
						l_plot_h := l_target.height.to_integer_32 - l_x_axis_h - l_title_h

						create l_plot_rect.make (l_plot_x.to_natural_16, l_plot_y.to_natural_16, l_plot_w.to_natural_16, l_plot_h.to_natural_16)

						-- 1. Render Braille Canvas with Datasets
						create l_canvas.make
						l_canvas.set_bounds (x_bounds.min, x_bounds.max, y_bounds.min, y_bounds.max)
						-- One stacked layer per dataset, drawn with the dataset's marker
						across dataset_store as ds loop
							create l_layer.make_with_painter (agent paint_dataset (ds, ?))
							l_layer.set_marker (ds.marker)
							l_canvas.add_layer (l_layer)
						end
						l_canvas.render (l_plot_rect, a_buffer)

						-- Render Legend inside plot area if enabled
						if is_legend_visible and not dataset_store.is_empty then
							render_legend (l_plot_rect, a_buffer)
						end

						-- 2. Render Y-axis vertical line and labels (with bounds checking)
						l_abs_x := l_target.x.to_integer_32 + l_y_axis_w - 1
						from
							r := 0
						until
							r >= l_plot_h
						loop
							l_abs_y := l_plot_y + r
							if l_abs_y >= 0 and l_abs_y < a_buffer.height and l_abs_x >= 0 and l_abs_x < a_buffer.width then
								a_buffer.put_char (l_abs_y, l_abs_x, (9474).to_character_32, axis_style) -- '│'
							end
							r := r + 1
						end

						-- Render Y-axis title on its own row above the plot
						if attached y_title as yt and l_target.y.to_integer_32 < a_buffer.height then
							a_buffer.set_string_clipped (l_target.y.to_integer_32, l_left, yt, l_left, l_right, axis_style)
						end

						if attached y_labels as yls and then not yls.is_empty then
							l_y_step := (l_plot_h - 1) // (yls.count - 1).max (1)
							from
								l_lbl_idx := 1
							until
								l_lbl_idx > yls.count
							loop
								l_lbl := yls.i_th (l_lbl_idx)
								-- Labels run bottom-up, as in Ratatui: the first one (y minimum) on the last plot row,
								-- the last one (y maximum) on the first plot row
								if l_lbl_idx = 1 then
									l_abs_y := l_plot_y + l_plot_h - 1
								elseif l_lbl_idx = yls.count then
									l_abs_y := l_plot_y
								else
									l_abs_y := l_plot_y + l_plot_h - 1 - (l_lbl_idx - 1) * l_y_step
								end
								l_lbl_w := {UNICODE_WIDTH}.string_width (l_lbl).to_integer_32
								if y_label_alignment = {TEXT_ALIGNMENT}.left then
									l_lbl_x := l_target.x.to_integer_32
								elseif y_label_alignment = {TEXT_ALIGNMENT}.center then
									l_lbl_x := l_target.x.to_integer_32 + ((l_max_y_w - l_lbl_w) // 2).max (0)
								else
									l_lbl_x := l_abs_x - l_lbl_w
								end
								if l_abs_y >= 0 and l_abs_y < a_buffer.height then
									a_buffer.set_string_clipped (l_abs_y, l_lbl_x, l_lbl, l_left, l_abs_x.max (l_left), axis_style)
								end
								l_lbl_idx := l_lbl_idx + 1
							end
						end

						-- 3. Render X-axis horizontal line and bottom-left junction
						l_abs_y := l_plot_y + l_plot_h
						if l_abs_y >= 0 and l_abs_y < a_buffer.height and l_abs_x >= 0 and l_abs_x < a_buffer.width then
							-- Bottom-left corner junction '└' (9492)
							a_buffer.put_char (l_abs_y, l_abs_x, (9492).to_character_32, axis_style)
						end
						from
							c := 0
						until
							c >= l_plot_w
						loop
							if l_abs_y >= 0 and l_abs_y < a_buffer.height and (l_plot_x + c) < a_buffer.width then
								a_buffer.put_char (l_abs_y, l_plot_x + c, (9472).to_character_32, axis_style) -- '─'
							end
							c := c + 1
						end

						-- 4. Render X-axis labels if present
						if attached x_labels as xls and then not xls.is_empty then
							render_x_labels (xls, l_plot_x, l_abs_y + 1, l_plot_w, a_buffer)
						end

						-- 5. Render X-axis title if present
						if attached x_title as xt then
							l_xt_w := {UNICODE_WIDTH}.string_width (xt).to_integer_32
							-- Same condition as the row reserved for the x labels
							l_xt_row := l_abs_y + (if attached x_labels as xls and then not xls.is_empty then 2 else 1 end)
							if l_xt_row >= 0 and l_xt_row < a_buffer.height then
								a_buffer.set_string_clipped (l_xt_row, l_plot_x + ((l_plot_w - l_xt_w) // 2).max (0), xt, l_left, l_right, axis_style)
							end
						end
					end
				end
			end
		end

feature {NONE} -- Internal Painting

	paint_dataset (a_dataset: TUI_CHART_DATASET; a_painter: CANVAS_PAINTER)
			-- Paint `a_dataset` according to its graph type (the layer carries its marker).
		local
			i: INTEGER
			p1, p2: TUPLE [x, y: REAL_64]
			l_base: REAL_64
		do
			a_painter.set_style (a_dataset.style)
			if a_dataset.graph_type = {CHART_GRAPH_TYPE}.bar then
				-- Bars rise from 0 (clamped to the y bounds), as in Ratatui
				l_base := (0.0).max (y_bounds.min).min (y_bounds.max)
				across a_dataset.data as pt loop
					a_painter.draw_line (pt.x, l_base, pt.x, pt.y)
				end
			elseif a_dataset.graph_type = {CHART_GRAPH_TYPE}.line then
				from
					i := 1
				until
					i >= a_dataset.data.count
				loop
					p1 := a_dataset.data.i_th (i)
					p2 := a_dataset.data.i_th (i + 1)
					a_painter.draw_line (p1.x, p1.y, p2.x, p2.y)
					i := i + 1
				end
			else
				across a_dataset.data as pt loop
					a_painter.draw_point (pt.x, pt.y)
				end
			end
		end

	render_legend (a_rect: RECT; a_buffer: BUFFER)
			-- Legend in a bordered box at `legend_position` inside the plot `a_rect`, listing the
			-- dataset names in their styles (as in Ratatui); hidden when it exceeds
			-- `legend_hidden_ratio` of the plot in either dimension.
		local
			l_max_w, l_leg_w, l_leg_h, lx, ly, k: INTEGER
			l_box: RECT
			l_border: TUI_BLOCK
		do
			across dataset_store as d loop
				l_max_w := l_max_w.max ({UNICODE_WIDTH}.string_width (d.name).to_integer_32)
			end
			l_leg_w := l_max_w + 2
			l_leg_h := dataset_store.count + 2
			if l_leg_w <= (a_rect.width.to_integer_32.to_double * legend_hidden_ratio).floor
				and l_leg_h <= (a_rect.height.to_integer_32.to_double * legend_hidden_ratio).floor then
				if legend_position = {CHART_LEGEND_POSITION}.top_left or legend_position = {CHART_LEGEND_POSITION}.bottom_left then
					lx := a_rect.x.to_integer_32
				else
					lx := a_rect.right.to_integer_32 - l_leg_w
				end
				if legend_position = {CHART_LEGEND_POSITION}.top_left or legend_position = {CHART_LEGEND_POSITION}.top_right then
					ly := a_rect.y.to_integer_32
				else
					ly := a_rect.bottom.to_integer_32 - l_leg_h
				end
				create l_box.make (lx.to_natural_16, ly.to_natural_16, l_leg_w.to_natural_16, l_leg_h.to_natural_16)
				(create {TUI_CLEAR}).render (l_box, a_buffer)
				create l_border.make
				l_border.set_border_style (axis_style)
				l_border.render (l_box, a_buffer)
				from
					k := 1
				until
					k > dataset_store.count
				loop
					if ly + k < a_buffer.height then
						a_buffer.set_string_clipped (ly + k, lx + 1, dataset_store.i_th (k).name, lx + 1, lx + l_leg_w - 1, dataset_store.i_th (k).style)
					end
					k := k + 1
				end
			end
		end

	render_x_labels (a_labels: ARRAYED_LIST [STRING_32]; a_start_x, a_row, a_width: INTEGER; a_buffer: BUFFER)
			-- Render X-axis labels spaced across `a_width` with `x_label_alignment`.
		local
			idx, l_x, l_step, l_w: INTEGER
			l_lbl: STRING_32
		do
			if a_labels.count = 1 then
				l_lbl := a_labels.first
				l_w := {UNICODE_WIDTH}.string_width (l_lbl).to_integer_32
				if x_label_alignment = {TEXT_ALIGNMENT}.left then
					l_x := a_start_x
				elseif x_label_alignment = {TEXT_ALIGNMENT}.right then
					l_x := (a_start_x + a_width - l_w).max (a_start_x)
				else
					l_x := a_start_x + ((a_width - l_w) // 2).max (0)
				end
				if a_row >= 0 and a_row < a_buffer.height then
					a_buffer.set_string_clipped (a_row, l_x, l_lbl, a_start_x, a_start_x + a_width, axis_style)
				end
			else
				l_step := (a_width - 1) // (a_labels.count - 1)
				from
					idx := 1
				until
					idx > a_labels.count
				loop
					l_lbl := a_labels.i_th (idx)
					l_w := {UNICODE_WIDTH}.string_width (l_lbl).to_integer_32
					if idx = 1 then
						l_x := a_start_x
					elseif idx = a_labels.count then
						l_x := (a_start_x + a_width - l_w).max (a_start_x)
					else
						l_x := a_start_x + (idx - 1) * l_step - (l_w // 2)
					end
					if a_row >= 0 and a_row < a_buffer.height then
						a_buffer.set_string_clipped (a_row, l_x, l_lbl, a_start_x, a_start_x + a_width, axis_style)
					end
					idx := idx + 1
				end
			end
		end

	same_labels (a_l1, a_l2: detachable ARRAYED_LIST [STRING_32]): BOOLEAN
			-- Are `a_l1` and `a_l2` equal string lists?
		local
			i: INTEGER
		do
			if a_l1 = Void and a_l2 = Void then
				Result := True
			elseif attached a_l1 as l1 and then attached a_l2 as l2 and then l1.count = l2.count then
				Result := True
				from
					i := 1
				until
					i > l1.count or not Result
				loop
					Result := l1 [i].same_string (l2 [i])
					i := i + 1
				end
			end
		end

invariant
	datasets_not_void: dataset_store /= Void
	x_bounds_valid: x_bounds /= Void and then x_bounds.min < x_bounds.max
	y_bounds_valid: y_bounds /= Void and then y_bounds.min < y_bounds.max
	axis_style_not_void: axis_style /= Void
	valid_legend_position: {CHART_LEGEND_POSITION}.is_valid (legend_position)
	valid_x_align: {TEXT_ALIGNMENT}.is_valid (x_label_alignment)
	valid_y_align: {TEXT_ALIGNMENT}.is_valid (y_label_alignment)

end
