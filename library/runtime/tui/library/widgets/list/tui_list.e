note
	description: "[
		Scrollable list widget supporting keyboard selection navigation, highlight styling,
		custom selection markers, and container block integration.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_LIST

inherit
	STATEFUL_WIDGET [LIST_STATE]
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
	make_empty,
	make

feature {NONE} -- Initialization

	default_create
			-- Initialize as an empty list.
		do
			create item_store.make (8)
			create style.default_create
			create highlight_style.default_create
			create highlight_symbol.make_empty
			direction := {LIST_DIRECTION}.top_to_bottom
			highlight_spacing := {HIGHLIGHT_SPACING}.when_selected
			repeat_highlight_symbol := False
			scroll_padding := 0
		ensure then
			items_empty: items.is_empty
		end

	make_empty
			-- Synonym for `default_create`.
		do
			default_create
		end

	make (a_items: ITERABLE [LIST_ITEM])
			-- Initialize with `a_items`.
		require
			items_not_void: a_items /= Void
		do
			make_empty
			across
				a_items as it
			loop
				append_item (it)
			end
		end

feature -- Duplication

	copy (a_other: like Current)
			-- Copy `a_other`. The items are copied on write: both objects share them until
			-- either accesses `items` (or adds an item), which gives it its own copies first.
			-- Rendering never copies, so a chain of `with_*` builders followed by `render` is cheap.
		do
			if a_other /= Current then
				standard_copy (a_other)
				items_shared := True
				a_other.mark_items_shared
			end
		end

	is_equal (a_other: like Current): BOOLEAN
			-- Are all settings the same and the items equal?
		local
			i: INTEGER
		do
			if a_other = Current then
				Result := True
			elseif standard_is_equal (a_other) then
				Result := True
			elseif same_block (a_other)
				and style.is_equal (a_other.style)
				and highlight_style.is_equal (a_other.highlight_style)
				and highlight_symbol.same_string (a_other.highlight_symbol)
				and direction = a_other.direction
				and repeat_highlight_symbol = a_other.repeat_highlight_symbol
				and scroll_padding = a_other.scroll_padding
				and highlight_spacing = a_other.highlight_spacing
				and item_store.count = a_other.item_store.count
			then
				Result := True
				from
					i := 1
				until
					i > item_store.count or not Result
				loop
					Result := item_store [i].is_equal (a_other.item_store [i])
					i := i + 1
				end
			end
		end

feature {TUI_LIST} -- Copy on write

	item_store: ARRAYED_LIST [LIST_ITEM]
			-- Items, possibly shared with copies of `Current` (see `items_shared`)

	items_shared: BOOLEAN
			-- Is `item_store` shared with another list?

	mark_items_shared
			-- Record that `item_store` is now shared with a copy.
		do
			items_shared := True
		ensure
			shared: items_shared
		end

	own_items
			-- Give `Current` its own copies of the items if they are shared.
		local
			l_items: ARRAYED_LIST [LIST_ITEM]
		do
			if items_shared then
				create l_items.make (item_store.count)
				across item_store as it loop
					l_items.extend (it.twin)
				end
				item_store := l_items
				items_shared := False
			end
		ensure
			not_shared: not items_shared
		end

feature -- Access

	items: ARRAYED_LIST [LIST_ITEM]
			-- List items, owned by `Current` (shared items are copied first)
		do
			own_items
			Result := item_store
		ensure
			owned: not items_shared
		end

	style: STYLE
			-- Baseline style applied to normal list items

	highlight_style: STYLE
			-- Style applied to the selected item

	highlight_symbol: STRING_32
			-- Prefix symbol rendered before selected item (e.g. "> ")

	direction: INTEGER
			-- List rendering direction (Top_to_bottom or Bottom_to_top)

	repeat_highlight_symbol: BOOLEAN
			-- Should highlight symbol repeat on subsequent lines of multi-line items?

	scroll_padding: INTEGER
			-- Minimum items to keep visible above/below selection

	highlight_spacing: INTEGER
			-- Spacing strategy for highlight symbol

	count: INTEGER
			-- Total number of items
		do
			Result := item_store.count
		ensure
			correct_count: Result = item_store.count
		end

feature -- Element change

	append_item (a_item: LIST_ITEM)
			-- Add `a_item` to list.
		require
			item_not_void: a_item /= Void
		do
			items.extend (a_item)
		ensure
			item_added: items.count = old items.count + 1
			last_item: items.last = a_item
		end

	append_raw_item (a_text: READABLE_STRING_GENERAL)
			-- Add item from plain string `a_text`.
		require
			text_not_void: a_text /= Void
		local
			l_item: LIST_ITEM
		do
			create l_item.make_raw (a_text)
			append_item (l_item)
		ensure
			item_added: items.count = old items.count + 1
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
			-- Set highlight style for selected item.
		require
			style_not_void: a_style /= Void
		do
			highlight_style := a_style
		ensure
			highlight_style_set: highlight_style = a_style
		end

	set_highlight_symbol (a_symbol: READABLE_STRING_GENERAL)
			-- Set prefix symbol for selected item.
		require
			symbol_not_void: a_symbol /= Void
		do
			create highlight_symbol.make_from_string_general (a_symbol)
		ensure
			symbol_set: highlight_symbol.same_string_general (a_symbol)
		end

	set_direction (a_direction: INTEGER)
			-- Set list rendering direction.
		require
			valid_direction: {LIST_DIRECTION}.is_valid (a_direction)
		do
			direction := a_direction
		ensure
			direction_set: direction = a_direction
		end

	set_repeat_highlight_symbol (a_repeat: BOOLEAN)
			-- Set whether highlight symbol repeats on each line of a multi-line item.
		do
			repeat_highlight_symbol := a_repeat
		ensure
			repeat_set: repeat_highlight_symbol = a_repeat
		end

	set_scroll_padding (a_padding: INTEGER)
			-- Set minimum items to keep visible above/below selection.
		require
			non_negative: a_padding >= 0
		do
			scroll_padding := a_padding
		ensure
			padding_set: scroll_padding = a_padding
		end

	set_highlight_spacing (a_spacing: INTEGER)
			-- Set highlight symbol spacing behavior.
		require
			valid_spacing: {HIGHLIGHT_SPACING}.is_valid (a_spacing)
		do
			highlight_spacing := a_spacing
		ensure
			spacing_set: highlight_spacing = a_spacing
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
			-- Return a copy of Current with highlight style `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_highlight_style (a_style)
		ensure
			highlight_style_set: Result.highlight_style = a_style
			result_not_void: Result /= Void
		end

	with_highlight_symbol (a_symbol: READABLE_STRING_GENERAL): like Current
			-- Return a copy of Current with highlight symbol `a_symbol`.
		require
			symbol_not_void: a_symbol /= Void
		do
			Result := twin
			Result.set_highlight_symbol (a_symbol)
		ensure
			result_not_void: Result /= Void
		end

	with_direction (a_direction: INTEGER): like Current
			-- Return a copy of Current with specified direction.
		require
			valid_direction: {LIST_DIRECTION}.is_valid (a_direction)
		do
			Result := twin
			Result.set_direction (a_direction)
		ensure
			direction_set: Result.direction = a_direction
			result_not_void: Result /= Void
		end

	with_repeat_highlight_symbol (a_repeat: BOOLEAN): like Current
			-- Return a copy of Current with repeated highlight symbol flag.
		do
			Result := twin
			Result.set_repeat_highlight_symbol (a_repeat)
		ensure
			repeat_set: Result.repeat_highlight_symbol = a_repeat
			result_not_void: Result /= Void
		end

	with_scroll_padding (a_padding: INTEGER): like Current
			-- Return a copy of Current with scroll padding.
		require
			non_negative: a_padding >= 0
		do
			Result := twin
			Result.set_scroll_padding (a_padding)
		ensure
			padding_set: Result.scroll_padding = a_padding
			result_not_void: Result /= Void
		end

	with_highlight_spacing (a_spacing: INTEGER): like Current
			-- Return a copy of Current with highlight spacing behavior.
		require
			valid_spacing: {HIGHLIGHT_SPACING}.is_valid (a_spacing)
		do
			Result := twin
			Result.set_highlight_spacing (a_spacing)
		ensure
			spacing_set: Result.highlight_spacing = a_spacing
			result_not_void: Result /= Void
		end

feature -- Rendering

	render (a_area: RECT; a_buffer: BUFFER)
			-- Stateless rendering using a default empty LIST_STATE.
		local
			l_state: LIST_STATE
		do
			create l_state.default_create
			render_stateful (a_area, a_buffer, l_state)
		end

	render_list (a_area: RECT; a_buffer: BUFFER; a_state: LIST_STATE)
			-- Synonym for `render_stateful`.
		require
			area_not_void: a_area /= Void
			buffer_not_void: a_buffer /= Void
			state_not_void: a_state /= Void
		do
			render_stateful (a_area, a_buffer, a_state)
		end

	render_stateful (a_area: RECT; a_buffer: BUFFER; a_state: LIST_STATE)
			-- Render list using mutable `a_state` (its offset is adjusted to keep the selection
			-- visible). The list style fills the area, each item's style and the highlight style
			-- fill the item's rows, and the highlight symbol column follows `highlight_spacing`.
		local
			l_target_area: RECT
			l_indent: INTEGER
			l_heights: ARRAYED_LIST [INTEGER]
			l_item_idx, l_line_idx, l_item_top, l_row, l_cursor, l_x, l_right: INTEGER
			l_item: LIST_ITEM
			l_is_sel, l_done: BOOLEAN
			l_eff_style: STYLE
			l_lines: ARRAYED_LIST [TEXT_LINE]
		do
			if not a_area.is_empty then
				render_block (a_area, a_buffer)
				l_target_area := inner_area (a_area)

				if not l_target_area.is_empty then
					a_buffer.set_style (l_target_area, style)

					create l_heights.make (item_store.count)
					across item_store as it loop
						l_heights.extend (it.content.lines.count.max (1))
					end
					a_state.adjust_viewport_for_rows (l_heights, l_target_area.height.to_integer_32,
						scroll_padding.max (a_state.scroll_padding))

					l_indent := symbol_column_width (a_state)
					l_x := l_target_area.x.to_integer_32
					l_right := l_target_area.right.to_integer_32
					if direction = {LIST_DIRECTION}.top_to_bottom then
						l_cursor := l_target_area.y.to_integer_32
					else
						l_cursor := l_target_area.bottom.to_integer_32
					end

					from
						l_item_idx := a_state.offset
					until
						l_done or l_item_idx > item_store.count
					loop
						l_item := item_store.i_th (l_item_idx)
						l_is_sel := a_state.has_selection and then a_state.selected = l_item_idx
						if l_is_sel then
							l_eff_style := style.patch (l_item.style).patch (highlight_style)
						else
							l_eff_style := style.patch (l_item.style)
						end
						l_lines := l_item.content.lines

						if direction = {LIST_DIRECTION}.top_to_bottom then
							l_item_top := l_cursor
							l_cursor := l_cursor + l_heights.i_th (l_item_idx)
							l_done := l_cursor >= l_target_area.bottom.to_integer_32
						else
							l_cursor := l_cursor - l_heights.i_th (l_item_idx)
							l_item_top := l_cursor
							l_done := l_cursor <= l_target_area.y.to_integer_32
						end

						from
							l_line_idx := 1
						until
							l_line_idx > l_heights.i_th (l_item_idx)
						loop
							l_row := l_item_top + l_line_idx - 1
							if l_row >= l_target_area.y.to_integer_32 and l_row < l_target_area.bottom.to_integer_32
								and l_row < a_buffer.height then
								a_buffer.set_style (row_rect (l_target_area, l_row), l_item.style)
								if l_is_sel then
									a_buffer.set_style (row_rect (l_target_area, l_row), highlight_style)
									if l_indent > 0 and (l_line_idx = 1 or repeat_highlight_symbol) then
										a_buffer.set_string_clipped (l_row, l_x, highlight_symbol, l_x, (l_x + l_indent).min (l_right), l_eff_style)
									end
								end
								if l_line_idx <= l_lines.count then
									render_item_line (l_lines.i_th (l_line_idx), l_row, l_x + l_indent, l_eff_style, l_target_area, a_buffer)
								end
							end
							l_line_idx := l_line_idx + 1
						end
						l_item_idx := l_item_idx + 1
					end
				end
			end
		end

	symbol_column_width (a_state: LIST_STATE): INTEGER
			-- Columns reserved for the highlight symbol: its width with `Always`, and with
			-- `When_selected` while something is selected; 0 with `Never` (Ratatui HighlightSpacing).
		do
			if highlight_spacing = {HIGHLIGHT_SPACING}.always
				or else (highlight_spacing = {HIGHLIGHT_SPACING}.when_selected and a_state.has_selection) then
				Result := {UNICODE_WIDTH}.string_width (highlight_symbol).to_integer_32
			end
		ensure
			never_reserves_nothing: highlight_spacing = {HIGHLIGHT_SPACING}.never implies Result = 0
		end

	row_rect (a_area: RECT; a_row: INTEGER): RECT
			-- The row `a_row` of `a_area`
		require
			row_in_area: a_row >= a_area.y.to_integer_32 and a_row < a_area.bottom.to_integer_32
		do
			create Result.make (a_area.x, a_row.to_natural_16, a_area.width, 1)
		end

feature {NONE} -- Implementation: Item Rendering

	render_item_line (a_line: TEXT_LINE; a_row, a_start_col: INTEGER; a_base_style: STYLE; a_area: RECT; a_buffer: BUFFER)
			-- Paint spans of an item's line clipped to `a_area`.
		do
			a_buffer.set_line_clipped (a_row, a_start_col, a_line, a_base_style,
				a_area.x.to_integer_32, a_area.right.to_integer_32)
		end

invariant
	item_store_not_void: item_store /= Void
	style_not_void: style /= Void
	highlight_style_not_void: highlight_style /= Void
	highlight_symbol_not_void: highlight_symbol /= Void
	valid_direction: {LIST_DIRECTION}.is_valid (direction)
	valid_highlight_spacing: {HIGHLIGHT_SPACING}.is_valid (highlight_spacing)
	non_negative_scroll_padding: scroll_padding >= 0

end

