note
	description: "[
		Viewport arithmetic shared by LIST_STATE and TABLE_STATE: which item comes first in a
		viewport of a given number of rows, when items take one or more rows each, the selection
		must stay visible and up to `padding` items around it should stay visible too
		(Ratatui `List::get_items_bounds` / `Table::visible_rows` with
		`apply_scroll_padding_to_selected_index`), and the saturating selection steps of
		`scroll_down_by` / `scroll_up_by`. All features are class features; indexes are 1-based.

		Item heights come as a list (`adjusted_offset`) or as a function of the index
		(`adjusted_offset_by`), so a caller with many items need not build a list of them every
		frame. Either way the work does not depend on the number of items: the offset is found
		by walking back from the last item that must show, and a walk stops once the items read
		fill the viewport, so at most `a_visible_rows` heights are read per walk.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	ROW_VIEWPORT

feature -- Measurement

	rows_between (a_heights: ARRAYED_LIST [INTEGER]; a_from, a_to: INTEGER): INTEGER
			-- Rows taken by items `a_from` .. `a_to` of `a_heights` (0 when `a_from` > `a_to`)
		require
			valid_range: a_from >= 1 and a_to <= a_heights.count
		local
			i: INTEGER
		do
			from
				i := a_from
			until
				i > a_to
			loop
				Result := Result + a_heights.i_th (i)
				i := i + 1
			end
		ensure
			instance_free: class
		end

	rows_between_by (a_height: FUNCTION [INTEGER, INTEGER]; a_from, a_to, a_cap: INTEGER): INTEGER
			-- Rows taken by items `a_from` .. `a_to`, item `i` taking `a_height (i)` rows (at least 1),
			-- counted only up to `a_cap`: the result is exact when it is at most `a_cap`, and
			-- `a_cap` + 1 when the items take more. Reads at most `a_cap` + 1 heights.
		require
			height_not_void: a_height /= Void
			valid_from: a_from >= 1
			valid_cap: a_cap >= 0 and a_cap < {INTEGER}.max_value
		local
			i, l_h: INTEGER
		do
			from
				i := a_from
			until
				i > a_to or Result > a_cap
			loop
				l_h := a_height.item ([i]).max (1)
				if l_h > a_cap - Result then
					Result := a_cap + 1
				else
					Result := Result + l_h
				end
				i := i + 1
			end
		ensure
			instance_free: class
			capped: Result <= a_cap + 1
		end

	fitting_padding (a_heights: ARRAYED_LIST [INTEGER]; a_selected, a_visible_rows, a_padding: INTEGER): INTEGER
			-- The largest padding, at most `a_padding`, for which item `a_selected` and the
			-- items up to that many places before and after it fit in `a_visible_rows` rows
			-- (0 when even one neighbour on each side does not fit)
		require
			valid_selected: a_selected >= 1 and a_selected <= a_heights.count
			non_negative_padding: a_padding >= 0
			non_negative_rows: a_visible_rows >= 0 and a_visible_rows < {INTEGER}.max_value
		do
			Result := fitting_padding_by (a_heights.count, agent a_heights.i_th, a_selected, a_visible_rows, a_padding)
		ensure
			instance_free: class
			bounded: Result >= 0 and Result <= a_padding
		end

	fitting_padding_by (a_count: INTEGER; a_height: FUNCTION [INTEGER, INTEGER]; a_selected, a_visible_rows, a_padding: INTEGER): INTEGER
			-- `fitting_padding` for `a_count` items, item `i` taking `a_height (i)` rows (at least 1).
			-- A window with more than `a_visible_rows` items cannot fit, so no padding above
			-- `a_visible_rows` is tried when the list is longer than that.
		require
			height_not_void: a_height /= Void
			valid_selected: a_selected >= 1 and a_selected <= a_count
			non_negative_padding: a_padding >= 0
			non_negative_rows: a_visible_rows >= 0 and a_visible_rows < {INTEGER}.max_value
		do
			Result := a_padding.min (a_count)
			if Result > a_visible_rows and a_count - 1 >= a_visible_rows then
				Result := a_visible_rows
			end
			from
			until
				Result = 0 or else
					rows_between_by (a_height, (a_selected - Result).max (1), (a_selected + Result).min (a_count), a_visible_rows) <= a_visible_rows
			loop
				Result := Result - 1
			end
		ensure
			instance_free: class
			bounded: Result >= 0 and Result <= a_padding
		end

	first_fitting_start (a_height: FUNCTION [INTEGER, INTEGER]; a_last, a_visible_rows: INTEGER): INTEGER
			-- Smallest `k` in 1 .. `a_last` for which items `k` .. `a_last` (item `i` taking
			-- `a_height (i)` rows, at least 1) fit in `a_visible_rows` rows; `a_last` + 1 when item
			-- `a_last` alone does not fit. Walks back from `a_last`: reads at most
			-- `a_visible_rows` + 1 heights.
		require
			height_not_void: a_height /= Void
			valid_last: a_last >= 1
			non_negative_rows: a_visible_rows >= 0
		local
			k, l_sum, l_h: INTEGER
		do
			Result := a_last + 1
			from
				k := a_last
			until
				k < 1 or l_sum > a_visible_rows
			loop
				l_h := a_height.item ([k]).max (1)
				if l_h > a_visible_rows - l_sum then
					l_sum := a_visible_rows + 1
				else
					l_sum := l_sum + l_h
					Result := k
					k := k - 1
				end
			end
		ensure
			instance_free: class
			in_range: Result >= 1 and Result <= a_last + 1
		end

	adjusted_offset (a_heights: ARRAYED_LIST [INTEGER]; a_offset, a_selected, a_visible_rows, a_padding: INTEGER;
			a_fill_end: BOOLEAN): INTEGER
			-- First item to show in `a_visible_rows` rows, for items of `a_heights` rows each,
			-- starting from `a_offset`, with item `a_selected` selected (0: none; past the end:
			-- the last item). The selection is fully visible when it fits, with up to `a_padding`
			-- items before and after it (`fitting_padding`); the offset moves as little as that
			-- needs. With `a_fill_end`, the offset then moves back while the items from the one
			-- before it to the end still fit, so no rows stay blank at the end when earlier items
			-- could fill them (TUI_LIST); without it an offset near the end is kept (Ratatui).
		require
			positive_rows: a_visible_rows > 0 and a_visible_rows < {INTEGER}.max_value
			non_negative_selected: a_selected >= 0
			non_negative_padding: a_padding >= 0
			positive_heights: across a_heights as h all h >= 1 end
		do
			Result := adjusted_offset_by (a_heights.count, agent a_heights.i_th, a_offset, a_selected,
				a_visible_rows, a_padding, a_fill_end)
		ensure
			instance_free: class
			at_least_one: Result >= 1
			in_list: a_heights.count > 0 implies Result <= a_heights.count
			empty_list_at_start: a_heights.count = 0 implies Result = 1
			selection_not_above: (a_selected > 0 and a_heights.count > 0) implies Result <= a_selected.min (a_heights.count)
		end

	adjusted_offset_by (a_count: INTEGER; a_height: FUNCTION [INTEGER, INTEGER]; a_offset, a_selected, a_visible_rows,
			a_padding: INTEGER; a_fill_end: BOOLEAN): INTEGER
			-- `adjusted_offset` for `a_count` items, item `i` taking `a_height (i)` rows (at least 1).
			-- Reads only the heights around the selection and, with `a_fill_end`, near the end.
		require
			height_not_void: a_height /= Void
			non_negative_count: a_count >= 0
			positive_rows: a_visible_rows > 0 and a_visible_rows < {INTEGER}.max_value
			non_negative_selected: a_selected >= 0
			non_negative_padding: a_padding >= 0
		local
			s, l_pad, l_first, l_last: INTEGER
		do
			if a_count = 0 then
				Result := 1
			else
				Result := a_offset.max (1).min (a_count)
				if a_selected > 0 then
					s := a_selected.min (a_count)
					l_pad := fitting_padding_by (a_count, a_height, s, a_visible_rows, a_padding)
					l_first := (s - l_pad).max (1)
					l_last := (s + l_pad).min (a_count)
					if Result > l_first then
						Result := l_first
					end
						-- Move down as little as needed for items `Result` .. `l_last` to fit, but
						-- not past the selection: the smallest start that fits, at least `Result`.
					Result := Result.max (first_fitting_start (a_height, l_last, a_visible_rows)).min (s)
				end
				if a_fill_end then
						-- Move back while the items from the one before to the end still fit
					Result := Result.min (first_fitting_start (a_height, a_count, a_visible_rows))
				end
			end
		ensure
			instance_free: class
			at_least_one: Result >= 1
			in_list: a_count > 0 implies Result <= a_count
			empty_list_at_start: a_count = 0 implies Result = 1
			selection_not_above: (a_selected > 0 and a_count > 0) implies Result <= a_selected.min (a_count)
		end

feature -- Selection steps

	index_down_by (a_index, a_amount, a_count: INTEGER): INTEGER
			-- `a_index` moved down by `a_amount` places in `a_count` items, saturating at the
			-- last one; an `a_index` of 0 (nothing selected) starts from item 1 and one past the
			-- end starts from the last item (Ratatui `scroll_down_by`).
		require
			non_negative_index: a_index >= 0
			non_negative_amount: a_amount >= 0
			positive_count: a_count > 0
		local
			l_from: INTEGER
		do
			l_from := a_index.max (1).min (a_count)
			if a_amount >= a_count - l_from then
				Result := a_count
			else
				Result := l_from + a_amount
			end
		ensure
			instance_free: class
			in_range: Result >= 1 and Result <= a_count
		end

	index_up_by (a_index, a_amount, a_count: INTEGER): INTEGER
			-- `a_index` moved up by `a_amount` places in `a_count` items, saturating at the
			-- first one; an `a_index` of 0 (nothing selected) starts from item 1 and one past the
			-- end starts from the last item (Ratatui `scroll_up_by`).
		require
			non_negative_index: a_index >= 0
			non_negative_amount: a_amount >= 0
			positive_count: a_count > 0
		local
			l_from: INTEGER
		do
			l_from := a_index.max (1).min (a_count)
			if a_amount >= l_from - 1 then
				Result := 1
			else
				Result := l_from - a_amount
			end
		ensure
			instance_free: class
			in_range: Result >= 1 and Result <= a_count
		end

end
