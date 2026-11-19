note
	description: "[
		Mutable state for TUI_LIST, tracking item selection (1-based index)
		and scroll offset within the viewport.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	LIST_STATE

inherit
	WIDGET_STATE
		redefine
			default_create
		end

create
	default_create,
	make

feature {NONE} -- Initialization

	default_create
			-- Initialize list state with no selection and offset at 1.
		do
			has_selection := False
			selected := 0
			offset := 1
		ensure then
			no_selection: not has_selection
			zero_selected: selected = 0
			offset_at_start: offset = 1
		end

	make
			-- Synonym for `default_create`.
		do
			default_create
		end

feature -- Access

	has_selection: BOOLEAN
			-- Is any item currently selected?

	selected: INTEGER
			-- 1-based index of the currently selected item, or 0 if none

	offset: INTEGER
			-- 1-based index of the first item visible in the viewport

	scroll_padding: INTEGER
			-- Minimum items to keep visible above/below selection when scrolling

feature -- Element change

	set_scroll_padding (a_padding: INTEGER)
			-- Set scroll padding.
		require
			non_negative: a_padding >= 0
		do
			scroll_padding := a_padding
		ensure
			padding_set: scroll_padding = a_padding
		end

	with_scroll_padding (a_padding: INTEGER): like Current
			-- Fluent builder for scroll padding.
		require
			non_negative: a_padding >= 0
		do
			Result := twin
			Result.set_scroll_padding (a_padding)
		ensure
			result_is_copy: Result /= Current
			padding_set: Result.scroll_padding = a_padding
		end

	select_index (a_index: INTEGER)
			-- Select item at 1-based `a_index`.
		require
			positive_index: a_index > 0
		do
			has_selection := True
			selected := a_index
		ensure
			has_selection: has_selection
			selected_set: selected = a_index
		end

	unselect
			-- Deselect current selection.
		do
			has_selection := False
			selected := 0
		ensure
			no_selection: not has_selection
			selected_zero: selected = 0
		end

	set_offset (a_offset: INTEGER)
			-- Set viewport scroll offset.
		require
			positive_offset: a_offset >= 1
		do
			offset := a_offset
		ensure
			offset_set: offset = a_offset
		end

feature -- Navigation

	select_next (a_total_count: INTEGER)
			-- Move selection down to the next item, clamping at `a_total_count`.
		do
			if a_total_count > 0 then
				if not has_selection then
					select_index (1)
				elseif selected < a_total_count then
					selected := selected + 1
				end
			end
		ensure
			selection_valid: has_selection implies (selected >= 1 and selected <= a_total_count)
		end

	select_previous (a_total_count: INTEGER)
			-- Move selection up to the previous item, clamping at 1.
		do
			if a_total_count > 0 then
				if not has_selection then
					select_index (a_total_count)
				elseif selected > 1 then
					selected := selected - 1
				end
			end
		ensure
			selection_valid: has_selection implies (selected >= 1 and selected <= a_total_count)
		end

	select_first
			-- Select the first item.
		do
			select_index (1)
		ensure
			selected_first: selected = 1
		end

	select_last (a_total_count: INTEGER)
			-- Select the last item.
		require
			positive_count: a_total_count > 0
		do
			select_index (a_total_count)
		ensure
			selected_last: selected = a_total_count
		end

feature -- Viewport Scrolling

	adjust_viewport (a_visible_height: INTEGER; a_total_count: INTEGER)
			-- Automatically adjust `offset` so that `selected` is within the visible window,
			-- respecting `scroll_padding`.
		require
			positive_height: a_visible_height > 0 and a_visible_height < {INTEGER}.max_value
		do
			adjust_viewport_with_padding (a_visible_height, a_total_count, scroll_padding)
		ensure
			offset_valid: offset >= 1
		end

	adjust_viewport_with_padding (a_visible_height: INTEGER; a_total_count: INTEGER; a_padding: INTEGER)
			-- Automatically adjust `offset` with specific padding, for one-row items (no list of
			-- heights is built: see `{ROW_VIEWPORT}.adjusted_offset_by`).
		require
			positive_height: a_visible_height > 0 and a_visible_height < {INTEGER}.max_value
			non_negative_padding: a_padding >= 0
		do
			offset := {ROW_VIEWPORT}.adjusted_offset_by (a_total_count.max (0), agent (i: INTEGER): INTEGER do Result := 1 end,
				offset, selected, a_visible_height, a_padding, True)
		ensure
			offset_valid: offset >= 1
		end

	adjust_viewport_for_rows (a_heights: ARRAYED_LIST [INTEGER]; a_visible_rows: INTEGER; a_padding: INTEGER)
			-- Adjust `offset` for items of `a_heights` rows each shown in `a_visible_rows` rows:
			-- the selection is fully visible with up to `a_padding` items around it (the padding is
			-- reduced when the selection block would not fit), and no rows are left blank at the
			-- end of the list when earlier items could fill them (see `{ROW_VIEWPORT}.adjusted_offset`).
		require
			positive_rows: a_visible_rows > 0 and a_visible_rows < {INTEGER}.max_value
			non_negative_padding: a_padding >= 0
			positive_heights: across a_heights as h all h >= 1 end
		do
			offset := {ROW_VIEWPORT}.adjusted_offset (a_heights, offset, selected, a_visible_rows, a_padding, True)
		ensure
			offset_valid: offset >= 1
			offset_in_list: a_heights.count > 0 implies offset <= a_heights.count
		end

feature -- Scrolling

	scroll_down_by (a_amount: INTEGER; a_total_count: INTEGER)
			-- Move the selection down by `a_amount` items, saturating at `a_total_count`; with
			-- nothing selected, start from item 1 (Ratatui `ListState::scroll_down_by`).
			-- Nothing happens when the list is empty.
		require
			non_negative_amount: a_amount >= 0
		do
			if a_total_count > 0 then
				select_index ({ROW_VIEWPORT}.index_down_by (selected, a_amount, a_total_count))
			end
		ensure
			selected_when_not_empty: a_total_count > 0 implies has_selection
			selection_valid: a_total_count > 0 implies (selected >= 1 and selected <= a_total_count)
			unchanged_when_empty: a_total_count <= 0 implies (selected = old selected and has_selection = old has_selection)
		end

	scroll_up_by (a_amount: INTEGER; a_total_count: INTEGER)
			-- Move the selection up by `a_amount` items, saturating at item 1; with nothing
			-- selected, select item 1 (Ratatui `ListState::scroll_up_by`).
			-- Nothing happens when the list is empty.
		require
			non_negative_amount: a_amount >= 0
		do
			if a_total_count > 0 then
				select_index ({ROW_VIEWPORT}.index_up_by (selected, a_amount, a_total_count))
			end
		ensure
			selected_when_not_empty: a_total_count > 0 implies has_selection
			selection_valid: a_total_count > 0 implies (selected >= 1 and selected <= a_total_count)
			unchanged_when_empty: a_total_count <= 0 implies (selected = old selected and has_selection = old has_selection)
		end

invariant
	valid_selection_state: has_selection implies selected >= 1
	offset_positive: offset >= 1

end
