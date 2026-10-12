note
	description: "[
		Horizontal tab bar widget rendering clickable/selectable tab headers separated by dividers,
		with active tab highlighting and container block integration.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_TABS

inherit
	STATEFUL_WIDGET [TABS_STATE]
		redefine
			default_create,
			copy,
			is_equal
		end
	BLOCK_CONTAINER
		redefine
			default_create,
			copy,
			is_equal
		end

create
	default_create,
	make,
	make_from_strings

feature {NONE} -- Initialization

	default_create
			-- Initialize with empty tabs.
		do
			create titles.make (4)
			create style.default_create
			create highlight_style.default_create
			create divider.make_from_string_general (" | ")
			create padding_left.make_empty
			create padding_right.make_empty
			selected := 1
		ensure then
			titles_empty: titles.is_empty
			selected_first: selected = 1
		end

	make (a_titles: ITERABLE [TEXT_LINE])
			-- Initialize with `a_titles`.
		require
			titles_not_void: a_titles /= Void
		do
			default_create
			across
				a_titles as t
			loop
				append_title (t)
			end
		end

	make_from_strings (a_titles: ITERABLE [READABLE_STRING_GENERAL])
			-- Initialize with tab titles from plain strings.
		require
			titles_not_void: a_titles /= Void
		do
			default_create
			across
				a_titles as s
			loop
				append_raw_title (s)
			end
		end

feature -- Duplication

	copy (a_other: like Current)
			-- Copy `a_other` with its own copies of the titles, so that changing or adding a
			-- title on a copy made by a `with_*` builder leaves the original unchanged.
		do
			if a_other /= Current then
				standard_copy (a_other)
				create titles.make (a_other.titles.count)
				across a_other.titles as t loop
					titles.extend (t.twin)
				end
			end
		end

	is_equal (a_other: like Current): BOOLEAN
			-- Are all settings the same and the titles equal?
		local
			l_other: like Current
		do
			if a_other = Current then
				Result := True
			elseif titles.count = a_other.titles.count
				and then across titles as t all t.is_equal (a_other.titles [@t.cursor_index]) end
			then
				l_other := a_other.standard_twin
				l_other.share_titles (titles)
				Result := standard_is_equal (l_other)
			end
		end

feature {TUI_TABS} -- Duplication

	share_titles (a_titles: like titles)
			-- Use `a_titles` as the list of titles (for `is_equal`).
		do
			titles := a_titles
		end

feature -- Access

	titles: ARRAYED_LIST [TEXT_LINE]
			-- Ordered sequence of tab header lines

	style: STYLE
			-- Baseline style for normal tabs

	highlight_style: STYLE
			-- Style applied to the selected active tab

	divider: STRING_32
			-- Separator string rendered between adjacent tabs

	padding_left: STRING_32
			-- Padding string rendered before each tab title

	padding_right: STRING_32
			-- Padding string rendered after each tab title

	selected: INTEGER
			-- 1-based index of active tab for stateless rendering

	count: INTEGER
			-- Number of tabs
		do
			Result := titles.count
		ensure
			correct_count: Result = titles.count
		end

feature -- Element change

	append_title (a_title: TEXT_LINE)
			-- Add `a_title` to tabs.
		require
			title_not_void: a_title /= Void
		do
			titles.extend (a_title)
		ensure
			title_added: titles.count = old titles.count + 1
			last_title: titles.last = a_title
		end

	append_raw_title (a_text: READABLE_STRING_GENERAL)
			-- Add a plain string tab title.
		require
			text_not_void: a_text /= Void
		local
			l_line: TEXT_LINE
		do
			create l_line.make_raw (a_text)
			append_title (l_line)
		ensure
			title_added: titles.count = old titles.count + 1
		end

	set_style (a_style: STYLE)
			-- Set baseline style.
		require
			style_not_void: a_style /= Void
		do
			style := a_style
		ensure
			style_set: style = a_style
		end

	set_highlight_style (a_style: STYLE)
			-- Set active tab highlight style.
		require
			style_not_void: a_style /= Void
		do
			highlight_style := a_style
		ensure
			highlight_style_set: highlight_style = a_style
		end

	set_divider (a_divider: READABLE_STRING_GENERAL)
			-- Set separator between tabs.
		require
			divider_not_void: a_divider /= Void
		do
			create divider.make_from_string_general (a_divider)
		ensure
			divider_set: divider.same_string_general (a_divider)
		end

	set_padding (a_left, a_right: READABLE_STRING_GENERAL)
			-- Set padding before and after each tab title.
		require
			left_not_void: a_left /= Void
			right_not_void: a_right /= Void
		do
			create padding_left.make_from_string_general (a_left)
			create padding_right.make_from_string_general (a_right)
		ensure
			left_set: padding_left.same_string_general (a_left)
			right_set: padding_right.same_string_general (a_right)
		end

	set_selected (a_index: INTEGER)
			-- Set default selected tab.
		require
			positive_index: a_index >= 1
		do
			selected := a_index
		ensure
			selected_set: selected = a_index
		end

feature -- Fluent Builders

	with_style (a_style: STYLE): like Current
			-- Return a copy of Current with baseline style `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_style (a_style)
		ensure
			style_set: Result.style = a_style
			result_not_void: Result /= Void
		end

	with_highlight_style (a_style: STYLE): like Current
			-- Return a copy of Current with active tab highlight style `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_highlight_style (a_style)
		ensure
			highlight_style_set: Result.highlight_style = a_style
			result_not_void: Result /= Void
		end

	with_divider (a_divider: READABLE_STRING_GENERAL): like Current
			-- Return a copy of Current with specified divider string.
		require
			divider_not_void: a_divider /= Void
		do
			Result := twin
			Result.set_divider (a_divider)
		ensure
			result_not_void: Result /= Void
		end

	with_padding (a_left, a_right: READABLE_STRING_GENERAL): like Current
			-- Return a copy of Current with specified title padding strings.
		require
			left_not_void: a_left /= Void
			right_not_void: a_right /= Void
		do
			Result := twin
			Result.set_padding (a_left, a_right)
		ensure
			result_not_void: Result /= Void
		end

	with_selected (a_index: INTEGER): like Current
			-- Return a copy of Current with specified default selected index.
		require
			positive_index: a_index >= 1
		do
			Result := twin
			Result.set_selected (a_index)
		ensure
			selected_set: Result.selected = a_index
			result_not_void: Result /= Void
		end

feature -- Rendering

	render (a_area: RECT; a_buffer: BUFFER)
			-- Stateless rendering using `selected`.
		do
			render_tabs (a_area, a_buffer, selected)
		end

	render_stateful (a_area: RECT; a_buffer: BUFFER; a_state: TABS_STATE)
			-- Render with tab selection state `a_state`.
		do
			render_tabs (a_area, a_buffer, a_state.selected)
		end

	render_tabs (a_area: RECT; a_buffer: BUFFER; a_selected_index: INTEGER)
			-- Render tabs bar inside `a_area` on `a_buffer`.
		require
			area_not_void: a_area /= Void
			buffer_not_void: a_buffer /= Void
		local
			l_target_area: RECT
			l_row, l_col, l_right_bound: INTEGER
			l_div_w, l_pad_l_w, l_pad_r_w: NATURAL_16
			i: INTEGER
			l_title: TEXT_LINE
			l_is_sel: BOOLEAN
			l_eff_style, l_pad_style: STYLE
		do
			if not a_area.is_empty then
				render_block (a_area, a_buffer)
				l_target_area := inner_area (a_area)

				-- The bar is drawn on the first row of the area, when that row is inside the buffer
				if not l_target_area.is_empty and l_target_area.y.to_integer_32 < a_buffer.height then
					l_row := l_target_area.y.to_integer_32
					l_col := l_target_area.x.to_integer_32
					l_right_bound := (l_target_area.right.to_integer_32).min (a_buffer.width)
					l_div_w := {UNICODE_WIDTH}.string_width (divider)
					l_pad_l_w := {UNICODE_WIDTH}.string_width (padding_left)
					l_pad_r_w := {UNICODE_WIDTH}.string_width (padding_right)

					from
						i := 1
					until
						i > titles.count or l_col >= l_right_bound
					loop
						l_title := titles.i_th (i)
						l_is_sel := (i = a_selected_index)

						-- Divider between tabs (clipped to right bound)
						if i > 1 and not divider.is_empty and l_col < l_right_bound then
							a_buffer.set_string_clipped (l_row, l_col, divider, l_target_area.x.to_integer_32, l_right_bound, style)
							l_col := l_col + l_div_w.to_integer_32
						end

						if l_col < l_right_bound then
							-- Padding takes the tab's own style; only the title is highlighted (as in Ratatui)
							l_pad_style := style.patch (l_title.style)
							if l_is_sel then
								l_eff_style := l_pad_style.patch (highlight_style)
							else
								l_eff_style := l_pad_style
							end

							-- Left padding
							if not padding_left.is_empty and l_col < l_right_bound then
								a_buffer.set_string_clipped (l_row, l_col, padding_left, l_target_area.x.to_integer_32, l_right_bound, l_pad_style)
								l_col := l_col + l_pad_l_w.to_integer_32
							end

							-- Tab title
							if l_col < l_right_bound then
								render_tab_line (l_title, l_row, l_col, l_eff_style, l_target_area, a_buffer)
								l_col := l_col + l_title.width.to_integer_32
							end

							-- Right padding
							if not padding_right.is_empty and l_col < l_right_bound then
								a_buffer.set_string_clipped (l_row, l_col, padding_right, l_target_area.x.to_integer_32, l_right_bound, l_pad_style)
								l_col := l_col + l_pad_r_w.to_integer_32
							end
						end
						i := i + 1
					end
				end
			end
		end

feature {NONE} -- Implementation: Tab Line Rendering

	render_tab_line (a_line: TEXT_LINE; a_row, a_start_col: INTEGER; a_base_style: STYLE; a_area: RECT; a_buffer: BUFFER)
			-- Paint spans of a single tab line.
		do
			a_buffer.set_line_clipped (a_row, a_start_col, a_line, a_base_style,
				a_area.x.to_integer_32, a_area.right.to_integer_32)
		end

invariant
	titles_not_void: titles /= Void
	style_not_void: style /= Void
	highlight_style_not_void: highlight_style /= Void
	divider_not_void: divider /= Void
	padding_left_not_void: padding_left /= Void
	padding_right_not_void: padding_right /= Void
	selected_positive: selected >= 1

end
