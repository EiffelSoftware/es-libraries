note
	description: "[
		A breadcrumb: the path to the current place, one row, "src › widgets › tree".
		Ratatui has no breadcrumb widget (third-party crates and apps draw their own).
		Immediate mode, as TUI_CHECKBOX: the application owns the path and the selected crumb
		and gives them to the widget each frame; there is no state class. The widget reads no
		events.

		    a_frame.render_widget ((create {TUI_BREADCRUMB}.make (path))
		            .with_selected (crumb)
		            .with_hit_ids (crumb_ids),
		        l_area)

		Crumbs: `make` takes plain strings, `make_with_lines` styled TEXT_LINEs (their line
		and span styles are patched over the crumb's style; each line is copied, so changing
		it afterwards does not change the breadcrumb). The last crumb is the current
		place. A crumb has no control character (`is_valid_crumb`); an empty one takes no
		cell.

		Layout: on the top row of the area, the crumbs from the left edge with `separator`
		between them (default " " U+203A " "; BREADCRUMB_SYMBOLS has " > " and " / "). The
		rest of the area is left as it is. When the whole path (`width`) does not fit, the
		middle collapses (decision Q6 of review/p2b_clipboard_dialog_breadcrumb_plan.md):
		  1. the first crumb, U+2026 (`ellipsis`), then the longest run of last crumbs that
		     fits, each with its separator (at least the second crumb is hidden);
		  2. without room for that: the first crumb, U+2026 and the last crumb cut at the right
		     edge per grapheme cluster (with two crumbs, no U+2026: nothing is hidden). Taken
		     only when at least one cluster of the last crumb is drawn;
		  3. with even less room: only the last crumb, cut per grapheme cluster (a wide
		     character that would cross the edge is left out, so a one-column area under a
		     wide first character draws nothing).
		The layout is computed from the area's width; drawing is then cut to the buffer.

		Style: each crumb's `style`, patched by `current_style` for the last crumb (bold by
		default), then by `selected_style` (reversed by default) for crumb `selected`, is
		patched over the crumb's cells; the separators and U+2026 take `separator_style`. When
		the selected crumb is hidden in the collapsed middle (steps 1 and 2), U+2026 takes
		`selected_style` too, so the selection stays visible. In step 3 there is no U+2026:
		a selected crumb other than the last one is then not shown at all, and
		`is_selected_shown` is False; an application that must always show the selection
		gives the breadcrumb more room or shows it elsewhere. Colours left at the default keep
		the cells' own colours. Cells of the row not drawn keep their symbols and styles.

		Layout queries: `crumb_areas` (the cells each crumb was drawn in, Void when hidden or
		empty), `crumb_at` (the crumb drawn in a column, or 0), `visible_crumbs` (an empty
		crumb in its place counts as visible, although it has no area), `ellipsis_area` and
		`is_selected_shown`. They describe exactly what `render` draws in the same area.

		Hit regions: with `hit_ids` (one WIDGET_ID per crumb), FRAME.render_widget registers
		each visible crumb's cells under its id, as a HIT_CONTAINER (as TUI_MENU's entries).
		The separators, U+2026 and hidden crumbs register nothing. Setting new crumbs keeps the
		ids when their number is unchanged, and drops them otherwise.

		Input (the application's part, a recipe): the application keeps `selected` (0 for
		none) and the path. Left / Right (Alt+Left / Alt+Right when another widget has the
		arrows) move the selection, Enter goes to the selected crumb, a click goes to the
		crumb clicked:

		    if attached {KEY_EVENT} a_event as k and then k.is_press then
		        if k.code.is_left then
		            selected := (selected - 1).max (1)
		        elseif k.code.is_right then
		            selected := (selected + 1).min (path.count)
		        elseif k.code.is_enter and selected > 0 then
		            go_to (selected)        -- e.g. cut `path` after crumb `selected`
		        end
		    elseif attached {MOUSE_EVENT} a_event as m and then m.is_down
		        and then m.row = crumb_area.y
		        and then breadcrumb.crumb_at (crumb_area, m.column) > 0
		    then
		        go_to (breadcrumb.crumb_at (crumb_area, m.column))
		    end

		With `hit_ids`, `hit_test (m)` gives the crumb's id instead (EXAMPLE_FILE_TREE does
		this).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_BREADCRUMB

inherit
	WIDGET
		redefine
			default_create,
			copy,
			is_equal
		end

	HIT_CONTAINER
		redefine
			default_create,
			copy,
			is_equal
		end

create
	default_create,
	make,
	make_with_lines

feature {NONE} -- Initialization

	default_create
			-- Breadcrumb without crumbs, the " " U+203A " " separator, nothing selected, a bold
			-- current crumb and a reversed selected crumb.
		do
			create crumb_list.make (4)
			separator := {BREADCRUMB_SYMBOLS}.chevron
			ellipsis := {BREADCRUMB_SYMBOLS}.ellipsis
			create style
			current_style := (create {STYLE}).with_bold
			create separator_style
			selected_style := (create {STYLE}).with_reverse
		ensure then
			no_crumbs: count = 0
			chevron: separator.same_string ({BREADCRUMB_SYMBOLS}.chevron)
			nothing_selected: selected = 0
			no_hit_ids: hit_ids = Void
		end

	make (a_crumbs: ITERABLE [READABLE_STRING_GENERAL])
			-- Breadcrumb of the plain crumbs `a_crumbs`, first to last.
		require
			crumbs_not_void: a_crumbs /= Void
			valid_crumbs: across a_crumbs as c all c /= Void and then is_valid_crumb (c) end
		do
			default_create
			set_crumbs (a_crumbs)
		ensure
			nothing_selected: selected = 0
		end

	make_with_lines (a_crumbs: ITERABLE [TEXT_LINE])
			-- Breadcrumb of the styled crumbs `a_crumbs`, first to last.
		require
			crumbs_not_void: a_crumbs /= Void
			valid_crumbs: across a_crumbs as c all c /= Void and then is_valid_crumb (c.to_plain_string) end
		do
			default_create
			set_crumb_lines (a_crumbs)
		ensure
			nothing_selected: selected = 0
		end

feature -- Access

	count: INTEGER
			-- Number of crumbs
		do
			Result := crumb_list.count
		ensure
			non_negative: Result >= 0
		end

	crumb (i: INTEGER): TEXT_LINE
			-- Crumb `i`, 1 the first; `count` is the current place
		require
			valid_index: i >= 1 and i <= count
		do
			Result := crumb_list.i_th (i)
		ensure
			result_not_void: Result /= Void
		end

	separator: IMMUTABLE_STRING_32
			-- Drawn between two crumbs

	ellipsis: IMMUTABLE_STRING_32
			-- Drawn in place of the collapsed middle crumbs (U+2026)

	style: STYLE
			-- Style patched over every crumb's cells

	current_style: STYLE
			-- Style patched over `style` for the last crumb

	separator_style: STYLE
			-- Style patched over the separators and `ellipsis`

	selected: INTEGER
			-- Crumb drawn with `selected_style`; 0 for none

	selected_style: STYLE
			-- Style patched over crumb `selected` (and over `ellipsis` while it is hidden)

	hit_ids: detachable ARRAY [WIDGET_ID]
			-- One id per crumb (indexed from 1), registered for the visible crumbs; Void for
			-- none

	crumb_style (i: INTEGER): STYLE
			-- Style patched over crumb `i`'s cells: `style`, then `current_style` for the last
			-- crumb, then `selected_style` for crumb `selected`
		require
			valid_index: i >= 1 and i <= count
		do
			Result := style
			if i = count then
				Result := Result.patch (current_style)
			end
			if i = selected then
				Result := Result.patch (selected_style)
			end
		ensure
			result_not_void: Result /= Void
		end

	separator_width: INTEGER
			-- Columns of `separator`
		do
			Result := {UNICODE_WIDTH}.string_width (separator).to_integer_32
		ensure
			non_negative: Result >= 0
		end

	width: INTEGER
			-- Columns the whole path takes, crumbs and separators, when nothing is collapsed
		local
			i: INTEGER
		do
			from i := 1 until i > count loop
				Result := Result + crumb_width (i)
				i := i + 1
			end
			if count > 1 then
				Result := Result + (count - 1) * separator_width
			end
		ensure
			non_negative: Result >= 0
			empty: count = 0 implies Result = 0
		end

feature -- Layout queries

	crumb_areas (a_area: RECT): ARRAY [detachable RECT]
			-- Cells each crumb is drawn in when rendered into `a_area`, indexed from 1: on the
			-- area's top row, cut as drawn; Void for a hidden crumb or one that takes no cell.
			-- The area is not cut to any buffer.
		require
			area_not_void: a_area /= Void
		local
			l_pieces: like layout
		do
			create Result.make_filled (Void, 1, count)
			if not a_area.is_empty then
				l_pieces := layout (a_area.width.to_integer_32)
				across l_pieces as p loop
					if p.index > 0 and p.width > 0 then
						Result [p.index] := piece_rect (a_area, p.offset, p.width)
					end
				end
			end
		ensure
			result_not_void: Result /= Void
			one_per_crumb: Result.count = count and Result.lower = 1
			inside: across Result as r all attached r as l_r implies (a_area.contains_rect (l_r)
				and then l_r.height = 1 and then l_r.y = a_area.y and then not l_r.is_empty) end
		end

	crumb_at (a_area: RECT; a_column: INTEGER): INTEGER
			-- Crumb drawn in column `a_column` when rendered into `a_area`; 0 for none (a
			-- separator, `ellipsis`, a blank or outside the drawn crumbs)
		require
			area_not_void: a_area /= Void
		local
			l_areas: like crumb_areas
			i: INTEGER
		do
			l_areas := crumb_areas (a_area)
			from i := 1 until Result > 0 or i > count loop
				if attached l_areas [i] as r and then a_column >= r.left.to_integer_32
					and then a_column < r.right.to_integer_32 then
					Result := i
				end
				i := i + 1
			end
		ensure
			valid_result: Result >= 0 and Result <= count
		end

	visible_crumbs (a_area: RECT): ARRAY [INTEGER]
			-- Indices of the crumbs shown when rendered into `a_area`, first to last: those
			-- with an area in `crumb_areas`, and the empty crumbs laid out in their place (an
			-- empty crumb takes no cell but is not hidden). A non-empty crumb cut to nothing
			-- is not shown.
		require
			area_not_void: a_area /= Void
		do
			create Result.make_empty
			if not a_area.is_empty then
				across layout (a_area.width.to_integer_32) as p loop
					if p.index > 0 and then (p.width > 0 or crumb_width (p.index) = 0) then
						Result.force (p.index, Result.upper + 1)
					end
				end
			end
		ensure
			result_not_void: Result /= Void
			at_most_all: Result.count <= count
			with_area_shown: across 1 |..| count as i all crumb_areas (a_area) [i] /= Void implies
				across Result as r some r = i end end
		end

	ellipsis_area (a_area: RECT): detachable RECT
			-- Cell of `ellipsis` when rendered into `a_area`; Void when nothing is collapsed
		require
			area_not_void: a_area /= Void
		do
			if not a_area.is_empty then
				across layout (a_area.width.to_integer_32) as p loop
					if p.index = 0 then
						Result := piece_rect (a_area, p.offset, p.width)
					end
				end
			end
		ensure
			inside: attached Result as r implies a_area.contains_rect (r)
		end

	is_collapsed (a_area: RECT): BOOLEAN
			-- Is any crumb hidden when rendered into `a_area`?
		require
			area_not_void: a_area /= Void
		do
			Result := visible_crumbs (a_area).count < count
		end

	is_selected_shown (a_area: RECT): BOOLEAN
			-- Is the selection visible when rendered into `a_area`: nothing selected, the
			-- selected crumb shown, or hidden in the middle with `ellipsis` drawn in its
			-- place? (False in step 3 of the collapse for any crumb but the last.)
		require
			area_not_void: a_area /= Void
		do
			Result := selected = 0
				or else across visible_crumbs (a_area) as v some v = selected end
				or else ellipsis_area (a_area) /= Void
		ensure
			nothing_selected: selected = 0 implies Result
		end

feature -- Status report

	is_empty: BOOLEAN
			-- Are there no crumbs?
		do
			Result := count = 0
		ensure
			definition: Result = (count = 0)
		end

	is_valid_crumb (a_text: READABLE_STRING_GENERAL): BOOLEAN
			-- Can `a_text` be a crumb: no C0 or C1 control character and no DEL, which would move
			-- the cursor or end a sequence instead of drawing? (Empty is allowed.)
		require
			text_not_void: a_text /= Void
		local
			i: INTEGER
			c: NATURAL_32
		do
			Result := True
			from i := 1 until not Result or i > a_text.count loop
				c := a_text.code (i)
				Result := c >= 32 and not (c >= 127 and c <= 159)
				i := i + 1
			end
		ensure
			instance_free: class
		end

	is_valid_separator (a_text: READABLE_STRING_GENERAL): BOOLEAN
			-- Can `a_text` be the separator? The same rule as `is_valid_crumb` (empty allowed).
		require
			text_not_void: a_text /= Void
		do
			Result := is_valid_crumb (a_text)
		ensure
			instance_free: class
		end

	are_valid_hit_ids (a_ids: ARRAY [WIDGET_ID]): BOOLEAN
			-- Can `a_ids` be the hit ids: one per crumb?
		require
			ids_not_void: a_ids /= Void
		do
			Result := a_ids.count = count
		end

feature -- Element change

	set_crumbs (a_crumbs: ITERABLE [READABLE_STRING_GENERAL])
			-- Use the plain crumbs `a_crumbs`, first to last. `selected` is cleared when it is
			-- past the new last crumb; `hit_ids` are kept when the number of crumbs is the same.
		require
			crumbs_not_void: a_crumbs /= Void
			valid_crumbs: across a_crumbs as c all c /= Void and then is_valid_crumb (c) end
		local
			l_old_count: INTEGER
		do
			l_old_count := count
			create crumb_list.make (4)
			across a_crumbs as c loop
				crumb_list.extend (create {TEXT_LINE}.make_raw (c))
			end
			adjust_to_count (l_old_count)
		ensure
			selected_kept: old selected <= count implies selected = old selected
			selected_cleared: old selected > count implies selected = 0
			ids_kept: count = old count implies hit_ids = old hit_ids
			ids_dropped: count /= old count implies hit_ids = Void
		end

	set_crumb_lines (a_crumbs: ITERABLE [TEXT_LINE])
			-- Use copies of the styled crumbs `a_crumbs`, first to last (as `set_crumbs`), so
			-- that changing a line afterwards leaves the breadcrumb as it is.
		require
			crumbs_not_void: a_crumbs /= Void
			valid_crumbs: across a_crumbs as c all c /= Void and then is_valid_crumb (c.to_plain_string) end
		local
			l_old_count: INTEGER
		do
			l_old_count := count
			create crumb_list.make (4)
			across a_crumbs as c loop
				crumb_list.extend (c.twin)
			end
			adjust_to_count (l_old_count)
		ensure
			selected_kept: old selected <= count implies selected = old selected
			selected_cleared: old selected > count implies selected = 0
			ids_kept: count = old count implies hit_ids = old hit_ids
			ids_dropped: count /= old count implies hit_ids = Void
		end

	set_separator (a_separator: READABLE_STRING_GENERAL)
			-- Draw `a_separator` between two crumbs (BREADCRUMB_SYMBOLS has presets).
		require
			separator_not_void: a_separator /= Void
			valid_separator: is_valid_separator (a_separator)
		do
			create separator.make_from_string_general (a_separator)
		ensure
			separator_set: separator.same_string_general (a_separator)
		end

	set_style (a_style: STYLE)
			-- Patch `a_style` over every crumb.
		require
			style_not_void: a_style /= Void
		do
			style := a_style
		ensure
			style_set: style = a_style
		end

	set_current_style (a_style: STYLE)
			-- Patch `a_style` over `style` for the last crumb.
		require
			style_not_void: a_style /= Void
		do
			current_style := a_style
		ensure
			current_style_set: current_style = a_style
		end

	set_separator_style (a_style: STYLE)
			-- Patch `a_style` over the separators and `ellipsis`.
		require
			style_not_void: a_style /= Void
		do
			separator_style := a_style
		ensure
			separator_style_set: separator_style = a_style
		end

	set_selected (i: INTEGER)
			-- Draw crumb `i` with `selected_style`; 0 for none.
		require
			valid_index: i >= 0 and i <= count
		do
			selected := i
		ensure
			selected_set: selected = i
		end

	set_selected_style (a_style: STYLE)
			-- Patch `a_style` over crumb `selected`.
		require
			style_not_void: a_style /= Void
		do
			selected_style := a_style
		ensure
			selected_style_set: selected_style = a_style
		end

	set_hit_ids (a_ids: detachable ARRAY [WIDGET_ID])
			-- Register crumb `i`'s cells under `a_ids [a_ids.lower + i - 1]`; Void for none. The
			-- ids are copied, indexed from 1.
		require
			valid_ids: attached a_ids as l_valid implies are_valid_hit_ids (l_valid)
		local
			l_ids: ARRAY [WIDGET_ID]
			i: INTEGER
		do
			if attached a_ids as l_given then
				create l_ids.make_filled (create {WIDGET_ID}.make (0), 1, l_given.count)
				from i := 1 until i > l_given.count loop
					l_ids [i] := l_given [l_given.lower + i - 1]
					i := i + 1
				end
				hit_ids := l_ids
			else
				hit_ids := Void
			end
		ensure
			none: a_ids = Void implies hit_ids = Void
			set: attached a_ids as l_given implies (attached hit_ids as l_set and then l_set.lower = 1
				and then l_set.count = l_given.count
				and then across 1 |..| l_given.count as k all l_set [k] = l_given [l_given.lower + k - 1] end)
		end

feature -- Fluent Builders

	with_crumbs (a_crumbs: ITERABLE [READABLE_STRING_GENERAL]): like Current
			-- Copy of Current with the plain crumbs `a_crumbs` (as `set_crumbs`).
		require
			crumbs_not_void: a_crumbs /= Void
			valid_crumbs: across a_crumbs as c all c /= Void and then is_valid_crumb (c) end
		do
			Result := twin
			Result.set_crumbs (a_crumbs)
		ensure
			result_not_void: Result /= Void
		end

	with_crumb_lines (a_crumbs: ITERABLE [TEXT_LINE]): like Current
			-- Copy of Current with the styled crumbs `a_crumbs` (as `set_crumb_lines`).
		require
			crumbs_not_void: a_crumbs /= Void
			valid_crumbs: across a_crumbs as c all c /= Void and then is_valid_crumb (c.to_plain_string) end
		do
			Result := twin
			Result.set_crumb_lines (a_crumbs)
		ensure
			result_not_void: Result /= Void
		end

	with_separator (a_separator: READABLE_STRING_GENERAL): like Current
			-- Copy of Current drawing `a_separator` between two crumbs.
		require
			separator_not_void: a_separator /= Void
			valid_separator: is_valid_separator (a_separator)
		do
			Result := twin
			Result.set_separator (a_separator)
		ensure
			result_not_void: Result /= Void
			separator_set: Result.separator.same_string_general (a_separator)
		end

	with_style (a_style: STYLE): like Current
			-- Copy of Current with `style` set to `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_style (a_style)
		ensure
			result_not_void: Result /= Void
			style_set: Result.style = a_style
		end

	with_current_style (a_style: STYLE): like Current
			-- Copy of Current with `current_style` set to `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_current_style (a_style)
		ensure
			result_not_void: Result /= Void
			current_style_set: Result.current_style = a_style
		end

	with_separator_style (a_style: STYLE): like Current
			-- Copy of Current with `separator_style` set to `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_separator_style (a_style)
		ensure
			result_not_void: Result /= Void
			separator_style_set: Result.separator_style = a_style
		end

	with_selected (i: INTEGER): like Current
			-- Copy of Current drawing crumb `i` with `selected_style`; 0 for none.
		require
			valid_index: i >= 0 and i <= count
		do
			Result := twin
			Result.set_selected (i)
		ensure
			result_not_void: Result /= Void
			selected_set: Result.selected = i
		end

	with_selected_style (a_style: STYLE): like Current
			-- Copy of Current with `selected_style` set to `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_selected_style (a_style)
		ensure
			result_not_void: Result /= Void
			selected_style_set: Result.selected_style = a_style
		end

	with_hit_ids (a_ids: detachable ARRAY [WIDGET_ID]): like Current
			-- Copy of Current registering crumb `i`'s cells under the `i`-th id of `a_ids`;
			-- Void for none.
		require
			valid_ids: attached a_ids as l_ids implies are_valid_hit_ids (l_ids)
		do
			Result := twin
			Result.set_hit_ids (a_ids)
		ensure
			result_not_void: Result /= Void
			none: a_ids = Void implies Result.hit_ids = Void
		end

feature -- Duplication

	copy (a_other: like Current)
			-- Copy `a_other`, with its own list of crumbs (each crumb copied) and its own ids,
			-- so that changing a copy made by a `with_*` builder leaves the original unchanged.
			-- The separator is immutable and is shared.
		do
			if a_other /= Current then
				standard_copy (a_other)
				create crumb_list.make (a_other.count.max (1))
				across a_other.crumb_list as c loop
					crumb_list.extend (c.twin)
				end
				if attached a_other.hit_ids as l_ids then
					hit_ids := l_ids.twin
				end
			end
		end

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Same crumbs, separator, selection, styles and hit ids?
		local
			i: INTEGER
		do
			if a_other = Current then
				Result := True
			else
				Result := count = a_other.count
					and selected = a_other.selected
					and separator.same_string (a_other.separator)
					and style.is_equal (a_other.style)
					and current_style.is_equal (a_other.current_style)
					and separator_style.is_equal (a_other.separator_style)
					and selected_style.is_equal (a_other.selected_style)
				from i := 1 until not Result or i > count loop
					Result := crumb (i) ~ a_other.crumb (i)
					i := i + 1
				end
				if Result then
					if attached hit_ids as l_ids and attached a_other.hit_ids as l_other then
						from i := 1 until not Result or i > l_ids.count loop
							Result := l_ids [i] ~ l_other [i]
							i := i + 1
						end
					else
						Result := hit_ids = Void and a_other.hit_ids = Void
					end
				end
			end
		end

feature -- Rendering

	render (a_area: RECT; a_buffer: BUFFER)
			-- Draw the crumbs on the top row of `a_area`, cut to `a_buffer`, collapsing the
			-- middle when the path is wider than the area (see the class note).
		local
			l_clip, l_rect: RECT
			l_row, l_x, l_left, l_right, l_prev_end: INTEGER
			l_first: BOOLEAN
			l_base: STYLE
			l_pieces: like layout
		do
			l_clip := a_area.intersection (a_buffer.area)
			if not l_clip.is_empty and count > 0 then
				l_pieces := layout (a_area.width.to_integer_32)
				l_row := a_area.y.to_integer_32
				l_left := l_clip.left.to_integer_32
				l_right := l_clip.right.to_integer_32
				l_first := True
				across l_pieces as p loop
					if not l_first and separator_width > 0 then
						l_x := a_area.x.to_integer_32 + l_prev_end
						l_base := patched_base (a_buffer, piece_rect (a_area, l_prev_end, separator_width).intersection (l_clip),
							separator_style)
						a_buffer.set_string_clipped (l_row, l_x, separator, l_left, (l_x + separator_width).min (l_right), l_base)
					end
					l_first := False
					l_x := a_area.x.to_integer_32 + p.offset
					l_rect := piece_rect (a_area, p.offset, p.width).intersection (l_clip)
					if p.index = 0 then
						if selected > 1 and selected < count and not shown_in (selected, l_pieces) then
							l_base := patched_base (a_buffer, l_rect, separator_style.patch (selected_style))
						else
							l_base := patched_base (a_buffer, l_rect, separator_style)
						end
						a_buffer.set_string_clipped (l_row, l_x, ellipsis, l_left, (l_x + p.width).min (l_right), l_base)
					elseif p.width > 0 then
						l_base := patched_base (a_buffer, l_rect, crumb_style (p.index))
						a_buffer.set_line_clipped (l_row, l_x, crumb (p.index), l_base, l_left, (l_x + p.width).min (l_right))
					end
					l_prev_end := p.offset + p.width
				end
			end
		end

feature {FRAME} -- Hit testing

	register_child_hits (a_area: RECT; a_frame: FRAME)
			-- Register each visible crumb's cells, cut to the frame, under its id in `hit_ids`.
		local
			l_areas: like crumb_areas
			l_rect: RECT
			i: INTEGER
		do
			if attached hit_ids as l_ids then
				l_areas := crumb_areas (a_area)
				from i := 1 until i > count loop
					if attached l_areas [i] as r then
						l_rect := r.intersection (a_frame.area)
						if not l_rect.is_empty then
							a_frame.register_hit (l_ids [i], l_rect)
						end
					end
					i := i + 1
				end
			end
		end

feature {TUI_BREADCRUMB} -- Implementation

	crumb_list: ARRAYED_LIST [TEXT_LINE]
			-- The crumbs, first to last

feature {NONE} -- Implementation

	crumb_width (i: INTEGER): INTEGER
			-- Columns of crumb `i`
		require
			valid_index: i >= 1 and i <= count
		do
			Result := crumb (i).width.to_integer_32
		ensure
			non_negative: Result >= 0
		end

	layout (a_width: INTEGER): ARRAYED_LIST [TUPLE [index, offset, width: INTEGER]]
			-- What is drawn in an area `a_width` columns wide, left to right: crumb `index` (0
			-- for `ellipsis`) at `offset` columns from the left edge, `width` columns wide
			-- (cut). A separator is drawn between two consecutive pieces, right after the first.
			-- See the class note for the rule.
		local
			n, s, e, i, k, l_best, l_head, l_tail, l_avail, l_cut, l_x: INTEGER
			l_done: BOOLEAN
		do
			n := count
			create Result.make (n + 1)
			if a_width > 0 and n > 0 then
				s := separator_width
				e := {UNICODE_WIDTH}.string_width (ellipsis).to_integer_32
				if width <= a_width then
						-- The whole path
					from i := 1 until i > n loop
						Result.extend ([i, l_x, crumb_width (i)])
						l_x := l_x + crumb_width (i) + s
						i := i + 1
					end
				else
						-- 1. First, ellipsis, the longest run of last crumbs that fits
					if n >= 3 then
						l_head := crumb_width (1) + s + e + s
						l_tail := crumb_width (n)
						if l_head + l_tail <= a_width then
							l_best := n
							from k := n - 1 until k < 3 or l_head + l_tail + s + crumb_width (k) > a_width loop
								l_tail := l_tail + s + crumb_width (k)
								l_best := k
								k := k - 1
							end
							Result.extend ([1, 0, crumb_width (1)])
							Result.extend ([0, crumb_width (1) + s, e])
							l_x := l_head
							from i := l_best until i > n loop
								Result.extend ([i, l_x, crumb_width (i)])
								l_x := l_x + crumb_width (i) + s
								i := i + 1
							end
							l_done := True
						end
					end
						-- 2. First, ellipsis (when something is hidden), the last crumb cut
					if not l_done and n >= 2 then
						l_head := crumb_width (1) + s
						if n >= 3 then
							l_head := l_head + e + s
						end
						l_avail := a_width - l_head
						if l_avail > 0 then
							l_cut := clipped_width (crumb (n), l_avail)
							if l_cut > 0 then
								Result.extend ([1, 0, crumb_width (1)])
								if n >= 3 then
									Result.extend ([0, crumb_width (1) + s, e])
								end
								Result.extend ([n, l_head, l_cut])
								l_done := True
							end
						end
					end
						-- 3. Only the last crumb, cut
					if not l_done then
						Result.extend ([n, 0, clipped_width (crumb (n), a_width)])
					end
				end
			end
		ensure
			result_not_void: Result /= Void
			nothing_without_room: (a_width <= 0 or count = 0) implies Result.is_empty
			last_shown: (a_width > 0 and count > 0) implies Result.last.index = count
			fits: across Result as p all p.offset + p.width <= a_width end
		end

	clipped_width (a_line: TEXT_LINE; a_max: INTEGER): INTEGER
			-- Columns `a_line` takes when cut to `a_max` columns per grapheme cluster, as
			-- BUFFER.set_line_clipped cuts it (a cluster crossing the edge is left out)
		local
			i, l_end, w: INTEGER
			l_text: IMMUTABLE_STRING_32
			l_stop: BOOLEAN
		do
			across a_line.spans as sp until l_stop loop
				l_text := sp.content
				from i := 1 until l_stop or i > l_text.count loop
					l_end := {UNICODE_WIDTH}.grapheme_end (l_text, i)
					if l_end = i then
						w := {UNICODE_WIDTH}.width (l_text.code (i)).to_integer_32
					else
						w := {UNICODE_WIDTH}.grapheme_width (l_text.substring (i, l_end)).to_integer_32
					end
					if Result + w > a_max then
						l_stop := True
					else
						Result := Result + w
					end
					i := l_end + 1
				end
			end
		ensure
			in_range: Result >= 0 and Result <= a_max.max (0)
			at_most_line: Result <= a_line.width.to_integer_32
		end

	piece_rect (a_area: RECT; a_offset, a_width: INTEGER): RECT
			-- The cells `a_offset` .. `a_offset + a_width - 1` of `a_area`'s top row
		require
			area_not_void: a_area /= Void
			offset_non_negative: a_offset >= 0
			width_non_negative: a_width >= 0
		do
			create Result.make ((a_area.x.to_integer_32 + a_offset).min (65535).to_natural_16, a_area.y,
				a_width.min (65535).to_natural_16, 1)
		ensure
			result_not_void: Result /= Void
		end

	patched_base (a_buffer: BUFFER; a_rect: RECT; a_style: STYLE): STYLE
			-- Patch `a_style` over `a_rect` (already cut to the buffer) and give the style of its
			-- first cell, the base the piece is drawn with; `a_style` when `a_rect` is empty
		do
			if a_rect.is_empty then
				Result := a_style
			else
				a_buffer.set_style (a_rect, a_style)
				Result := a_buffer.cell (a_rect.y.to_integer_32, a_rect.x.to_integer_32).style.twin
			end
		ensure
			result_not_void: Result /= Void
		end

	shown_in (i: INTEGER; a_pieces: like layout): BOOLEAN
			-- Is crumb `i` one of `a_pieces`?
		do
			Result := across a_pieces as p some p.index = i end
		end

	adjust_to_count (a_old_count: INTEGER)
			-- After the crumbs changed from `a_old_count`: clear `selected` past the last crumb
			-- and drop `hit_ids` when the number of crumbs changed.
		do
			if selected > count then
				selected := 0
			end
			if count /= a_old_count then
				hit_ids := Void
			end
		ensure
			selected_valid: selected >= 0 and selected <= count
		end

invariant
	crumb_list_not_void: crumb_list /= Void
	valid_crumbs: across crumb_list as c all is_valid_crumb (c.to_plain_string) end
	separator_not_void: separator /= Void
	valid_separator: is_valid_separator (separator)
	ellipsis_not_void: ellipsis /= Void
	style_not_void: style /= Void
	current_style_not_void: current_style /= Void
	separator_style_not_void: separator_style /= Void
	selected_style_not_void: selected_style /= Void
	valid_selected: selected >= 0 and selected <= count
	one_id_per_crumb: attached hit_ids as l_ids implies (l_ids.count = count and l_ids.lower = 1)

end
