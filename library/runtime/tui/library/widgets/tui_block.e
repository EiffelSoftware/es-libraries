note
	description: "[
		A container widget providing styled borders, decorative corners (plain, rounded,
		double, thick), aligned titles, and interior padding calculations.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_BLOCK

inherit
	WIDGET
		redefine
			default_create,
			copy,
			is_equal
		end

create
	default_create,
	make

feature {NONE} -- Initialization

	default_create
			-- Initialize block with default styling and all borders.
		do
			borders := {BORDERS}.all_borders
			border_type := {BORDER_TYPE}.plain
			create border_style.default_create
			create style.default_create
			create padding.default_create
			create four_sided_padding.default_create
			create titles.make (2)
			title_alignment := {TEXT_ALIGNMENT}.left
		ensure then
			borders_all: borders = {BORDERS}.all_borders
			plain_type: border_type = {BORDER_TYPE}.plain
			titles_empty: titles.is_empty
		end

	make
			-- Synonym for `default_create`.
		do
			default_create
		end

feature -- Access

	borders: NATURAL_8
			-- Bitmask of visible border edges (top, right, bottom, left)

	border_type: NATURAL_8
			-- Box drawing corner and edge style

	border_set: detachable BORDER_SET
			-- Optional per-side custom border characters

	border_style: STYLE
			-- Style applied specifically to border glyphs

	style: STYLE
			-- Baseline style applied to block interior and background

	title: detachable TEXT_LINE
			-- Optional primary title line rendered along the top border

	title_alignment: NATURAL_8
			-- Alignment of primary title on top border

	titles: ARRAYED_LIST [BLOCK_TITLE]
			-- Multiple titles rendered on top and bottom borders

	padding: MARGIN
			-- Interior padding inside the borders (symmetric)

	four_sided_padding: PADDING
			-- Four-sided interior padding (top, right, bottom, left)

feature -- Element change

	set_borders (a_borders: NATURAL_8)
			-- Set visible border edges.
		require
			valid_borders: {BORDERS}.is_valid (a_borders)
		do
			borders := a_borders
		ensure
			borders_set: borders = a_borders
		end

	set_border_type (a_type: NATURAL_8)
			-- Set border corner and line drawing glyph type.
		require
			valid_type: {BORDER_TYPE}.is_valid (a_type)
		do
			border_type := a_type
		ensure
			type_set: border_type = a_type
		end

	set_border_style (a_style: STYLE)
			-- Set border styling.
		require
			style_not_void: a_style /= Void
		do
			border_style := a_style
		ensure
			border_style_set: border_style = a_style
		end

	set_style (a_style: STYLE)
			-- Set container baseline style.
		require
			style_not_void: a_style /= Void
		do
			style := a_style
		ensure
			style_set: style = a_style
		end

	set_title (a_title: detachable TEXT_LINE)
			-- Set or clear the title.
		do
			title := a_title
		ensure
			title_set: title = a_title
		end

	set_title_string (a_text: READABLE_STRING_GENERAL)
			-- Set title from a plain string.
		require
			text_not_void: a_text /= Void
		local
			l_line: TEXT_LINE
		do
			create l_line.make_raw (a_text)
			title := l_line
		ensure
			title_attached: title /= Void
		end

	set_title_alignment (a_align: NATURAL_8)
			-- Set title alignment.
		require
			valid_align: {TEXT_ALIGNMENT}.is_valid (a_align)
		do
			title_alignment := a_align
		ensure
			title_alignment_set: title_alignment = a_align
		end

	set_padding (a_padding: MARGIN)
			-- Set interior padding.
		require
			padding_not_void: a_padding /= Void
		do
			padding := a_padding
		ensure
			padding_set: padding = a_padding
		end

	set_four_sided_padding (a_padding: PADDING)
			-- Set four-sided interior padding.
		require
			padding_not_void: a_padding /= Void
		do
			four_sided_padding := a_padding
		ensure
			four_sided_padding_set: four_sided_padding = a_padding
		end

	set_border_set (a_set: detachable BORDER_SET)
			-- Set custom border glyph set.
		do
			border_set := a_set
		ensure
			border_set_set: border_set = a_set
		end

	add_title (a_title: BLOCK_TITLE)
			-- Add `a_title` to block.
		require
			title_not_void: a_title /= Void
		do
			titles.extend (a_title)
			if a_title.position = {BLOCK_TITLE}.position_top and title = Void then
				title := a_title.content
				title_alignment := a_title.alignment
			end
		ensure
			one_more: titles.count = old titles.count + 1
			last_title: titles.last = a_title
		end

	clear_titles
			-- Remove all titles and reset legacy `title`.
		do
			titles.wipe_out
			title := Void
		ensure
			titles_empty: titles.is_empty
			title_void: title = Void
		end

feature -- Duplication

	copy (a_other: like Current)
			-- Copy `a_other` to `Current`.
			-- `title` stays the same object as the content of the title it mirrors (see
			-- `add_title`), so that the mirrored title is still drawn only once.
		local
			l_titles: ARRAYED_LIST [BLOCK_TITLE]
			l_copy: BLOCK_TITLE
			l_mirrored: BOOLEAN
		do
			if a_other /= Current then
				standard_copy (a_other)
				if attached a_other.border_set as bs then
					border_set := bs.twin
				end
				create l_titles.make (a_other.titles.count)
				across a_other.titles as bt loop
					l_copy := bt.twin
					l_titles.extend (l_copy)
					if not l_mirrored and then a_other.title = bt.content then
						title := l_copy.content
						l_mirrored := True
					end
				end
				titles := l_titles
				if not l_mirrored and then attached a_other.title as t then
					title := t.twin
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
			elseif borders = a_other.borders
				and border_type = a_other.border_type
				and border_set ~ a_other.border_set
				and border_style.is_equal (a_other.border_style)
				and style.is_equal (a_other.style)
				and is_border_merged = a_other.is_border_merged
				and padding.is_equal (a_other.padding)
				and four_sided_padding.is_equal (a_other.four_sided_padding)
				and title_alignment = a_other.title_alignment
				and title ~ a_other.title
				and titles.count = a_other.titles.count
			then
				Result := True
				from
					i := 1
				until
					i > titles.count or not Result
				loop
					Result := titles [i].is_equal (a_other.titles [i])
					i := i + 1
				end
			end
		end

feature -- Fluent Builders

	with_borders (a_borders: NATURAL_8): like Current
			-- Return a copy of Current with updated borders.
		require
			valid_borders: {BORDERS}.is_valid (a_borders)
		do
			Result := twin
			Result.set_borders (a_borders)
		ensure
			borders_set: Result.borders = a_borders
			result_not_void: Result /= Void
		end

	with_border_type (a_type: NATURAL_8): like Current
			-- Return a copy of Current with updated border type.
		require
			valid_type: {BORDER_TYPE}.is_valid (a_type)
		do
			Result := twin
			Result.set_border_type (a_type)
		ensure
			type_set: Result.border_type = a_type
			result_not_void: Result /= Void
		end

	with_border_set (a_set: BORDER_SET): like Current
			-- Return a copy of Current with custom border set `a_set`.
		require
			set_not_void: a_set /= Void
		do
			Result := twin
			Result.set_border_set (a_set)
		ensure
			result_not_void: Result /= Void
			border_set_set: Result.border_set = a_set
		end

	with_border_style (a_style: STYLE): like Current
			-- Return a copy of Current with updated border style.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_border_style (a_style)
		ensure
			border_style_set: Result.border_style = a_style
			result_not_void: Result /= Void
		end

	with_style (a_style: STYLE): like Current
			-- Return a copy of Current with updated general style.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_style (a_style)
		ensure
			style_set: Result.style = a_style
			result_not_void: Result /= Void
		end

	with_title (a_text: READABLE_STRING_GENERAL): like Current
			-- Return a copy of Current with plain text title.
		require
			text_not_void: a_text /= Void
		do
			Result := twin
			Result.set_title_string (a_text)
		ensure
			title_attached: Result.title /= Void
			result_not_void: Result /= Void
		end

	with_title_top (a_text: READABLE_STRING_GENERAL; a_align: NATURAL_8): like Current
			-- Return a copy of Current with top title `a_text` aligned with `a_align`.
		require
			text_not_void: a_text /= Void
			valid_align: {TEXT_ALIGNMENT}.is_valid (a_align)
		do
			Result := twin
			Result.add_title (create {BLOCK_TITLE}.make_raw (a_text, {BLOCK_TITLE}.position_top, a_align))
		ensure
			result_not_void: Result /= Void
		end

	with_title_bottom (a_text: READABLE_STRING_GENERAL; a_align: NATURAL_8): like Current
			-- Return a copy of Current with bottom title `a_text` aligned with `a_align`.
		require
			text_not_void: a_text /= Void
			valid_align: {TEXT_ALIGNMENT}.is_valid (a_align)
		do
			Result := twin
			Result.add_title (create {BLOCK_TITLE}.make_raw (a_text, {BLOCK_TITLE}.position_bottom, a_align))
		ensure
			result_not_void: Result /= Void
		end

	with_block_title (a_title: BLOCK_TITLE): like Current
			-- Return a copy of Current with added `a_title`.
		require
			title_not_void: a_title /= Void
		do
			Result := twin
			Result.add_title (a_title)
		ensure
			result_not_void: Result /= Void
		end

	with_title_line (a_line: TEXT_LINE): like Current
			-- Return a copy of Current with styled title line.
		require
			line_not_void: a_line /= Void
		do
			Result := twin
			Result.set_title (a_line)
		ensure
			title_attached: Result.title = a_line
			result_not_void: Result /= Void
		end

	with_title_alignment (a_align: NATURAL_8): like Current
			-- Return a copy of Current with updated title alignment.
		require
			valid_align: {TEXT_ALIGNMENT}.is_valid (a_align)
		do
			Result := twin
			Result.set_title_alignment (a_align)
		ensure
			title_alignment_set: Result.title_alignment = a_align
			result_not_void: Result /= Void
		end

	with_padding (a_padding: MARGIN): like Current
			-- Return a copy of Current with updated interior padding.
		require
			padding_not_void: a_padding /= Void
		do
			Result := twin
			Result.set_padding (a_padding)
		ensure
			padding_set: Result.padding = a_padding
			result_not_void: Result /= Void
		end

	with_four_sided_padding (a_padding: PADDING): like Current
			-- Return a copy of Current with four-sided interior padding.
		require
			padding_not_void: a_padding /= Void
		do
			Result := twin
			Result.set_four_sided_padding (a_padding)
		ensure
			result_not_void: Result /= Void
			padding_set: Result.four_sided_padding = a_padding
		end

	with_border_merged (a_merged: BOOLEAN): like Current
			-- Return a copy of Current with border collision merging enabled or disabled.
		do
			Result := twin
			Result.set_border_merged (a_merged)
		ensure
			border_merged_set: Result.is_border_merged = a_merged
			result_not_void: Result /= Void
		end

	set_border_merged (a_merged: BOOLEAN)
			-- Set whether borders merge with existing box characters in the buffer.
		do
			is_border_merged := a_merged
		ensure
			border_merged_set: is_border_merged = a_merged
		end

	is_border_merged: BOOLEAN
			-- Should borders merge with existing box characters in the buffer?

feature -- Geometry

	inner (a_area: RECT): RECT
			-- Usable interior rectangle inside borders and padding.
		require
			area_not_void: a_area /= Void
		local
			l_x, l_y, l_w, l_h: NATURAL_16
			l_pad_l, l_pad_r, l_pad_t, l_pad_b: NATURAL_16
		do
			l_x := a_area.x
			l_y := a_area.y
			l_w := a_area.width
			l_h := a_area.height

			if {BORDERS}.has_left (borders) then
				if l_w > 0 then
					l_x := l_x + 1
					l_w := l_w - 1
				end
			end

			if {BORDERS}.has_top (borders) then
				if l_h > 0 then
					l_y := l_y + 1
					l_h := l_h - 1
				end
			end

			if {BORDERS}.has_right (borders) then
				if l_w > 0 then
					l_w := l_w - 1
				end
			end

			if {BORDERS}.has_bottom (borders) then
				if l_h > 0 then
					l_h := l_h - 1
				end
			end

			-- Apply horizontal padding
			l_pad_l := padding.horizontal + four_sided_padding.left
			l_pad_r := padding.horizontal + four_sided_padding.right
			if l_w > (l_pad_l + l_pad_r) then
				l_x := l_x + l_pad_l
				l_w := l_w - (l_pad_l + l_pad_r)
			else
				l_w := 0
			end

			-- Apply vertical padding
			l_pad_t := padding.vertical + four_sided_padding.top
			l_pad_b := padding.vertical + four_sided_padding.bottom
			if l_h > (l_pad_t + l_pad_b) then
				l_y := l_y + l_pad_t
				l_h := l_h - (l_pad_t + l_pad_b)
			else
				l_h := 0
			end

			create Result.make (l_x, l_y, l_w, l_h)
		ensure
			result_not_void: Result /= Void
			contained_in_area: a_area.contains_rect (Result)
		end

feature -- Rendering

	render (a_area: RECT; a_buffer: BUFFER)
			-- Draw borders, background, and titles on `a_buffer`.
		local
			l_x, l_y, l_w, l_h: INTEGER
			r, c: INTEGER
			l_tl, l_tr, l_bl, l_br, l_hz_top, l_hz_bot, l_vt_left, l_vt_right: CHARACTER_32
			l_b_top, l_b_bottom, l_b_left, l_b_right: BOOLEAN
			l_border_style: STYLE
		do
			if not a_area.is_empty then
				l_x := a_area.x.to_integer_32
				l_y := a_area.y.to_integer_32
				l_w := a_area.width.to_integer_32
				l_h := a_area.height.to_integer_32

				-- Check boundaries against buffer
				if l_x < a_buffer.width and l_y < a_buffer.height then
					-- 1. Paint background style over the whole area (patching, clipped to the buffer)
					a_buffer.set_style (a_area, style)
					-- Borders use the block style patched by the border style (as in Ratatui)
					l_border_style := style.patch (border_style)

					l_b_top := {BORDERS}.has_top (borders)
					l_b_bottom := {BORDERS}.has_bottom (borders)
					l_b_left := {BORDERS}.has_left (borders)
					l_b_right := {BORDERS}.has_right (borders)

					if attached border_set as bs then
						l_tl := bs.top_left
						l_tr := bs.top_right
						l_bl := bs.bottom_left
						l_br := bs.bottom_right
						l_hz_top := bs.top
						l_hz_bot := bs.bottom
						l_vt_left := bs.left
						l_vt_right := bs.right
					else
						l_tl := {BORDER_TYPE}.top_left (border_type)
						l_tr := {BORDER_TYPE}.top_right (border_type)
						l_bl := {BORDER_TYPE}.bottom_left (border_type)
						l_br := {BORDER_TYPE}.bottom_right (border_type)
						l_hz_top := {BORDER_TYPE}.horizontal (border_type)
						l_hz_bot := l_hz_top
						l_vt_left := {BORDER_TYPE}.vertical (border_type)
						l_vt_right := l_vt_left
					end

					-- Top border
					if l_b_top and l_y < a_buffer.height then
						from
							c := l_x
						until
							c >= l_x + l_w or c >= a_buffer.width
						loop
							if c = l_x and l_b_left then
								put_or_merge_border (a_buffer, l_y, c, l_tl, l_border_style)
							elseif c = l_x + l_w - 1 and l_b_right then
								put_or_merge_border (a_buffer, l_y, c, l_tr, l_border_style)
							else
								put_or_merge_border (a_buffer, l_y, c, l_hz_top, l_border_style)
							end
							c := c + 1
						end
					end

					-- Bottom border
					if l_b_bottom and (l_y + l_h - 1) < a_buffer.height and l_h > 1 then
						from
							c := l_x
						until
							c >= l_x + l_w or c >= a_buffer.width
						loop
							if c = l_x and l_b_left then
								put_or_merge_border (a_buffer, l_y + l_h - 1, c, l_bl, l_border_style)
							elseif c = l_x + l_w - 1 and l_b_right then
								put_or_merge_border (a_buffer, l_y + l_h - 1, c, l_br, l_border_style)
							else
								put_or_merge_border (a_buffer, l_y + l_h - 1, c, l_hz_bot, l_border_style)
							end
							c := c + 1
						end
					end

					-- Left and Right vertical edges
					from
						r := l_y + (if l_b_top then 1 else 0 end)
					until
						r >= l_y + l_h - (if l_b_bottom then 1 else 0 end) or r >= a_buffer.height
					loop
						if l_b_left and l_x < a_buffer.width then
							put_or_merge_border (a_buffer, r, l_x, l_vt_left, l_border_style)
						end
						if l_b_right and (l_x + l_w - 1) < a_buffer.width then
							put_or_merge_border (a_buffer, r, l_x + l_w - 1, l_vt_right, l_border_style)
						end
						r := r + 1
					end

					-- Titles on the top and bottom borders
					if l_b_top and l_w > 2 then
						render_title_row ({BLOCK_TITLE}.position_top, l_x, l_y, l_w, a_buffer)
					end
					if l_b_bottom and l_h > 1 and l_w > 2 then
						render_title_row ({BLOCK_TITLE}.position_bottom, l_x, l_y + l_h - 1, l_w, a_buffer)
					end
				end
			end
		end

	render_merged (a_area: RECT; a_buffer: BUFFER)
			-- Render borders using BORDER_COLLISION_SOLVER to merge with intersecting borders in `a_buffer`.
		local
			l_old: BOOLEAN
		do
			l_old := is_border_merged
			is_border_merged := True
			render (a_area, a_buffer)
			is_border_merged := l_old
		ensure
			merge_setting_restored: is_border_merged = old is_border_merged
		rescue
			-- Restore the setting, then let the exception propagate
			is_border_merged := l_old
		end

feature {NONE} -- Implementation: Border Merging

	put_or_merge_border (a_buffer: BUFFER; a_row, a_col: INTEGER; a_char: CHARACTER_32; a_style: STYLE)
			-- Draw or merge `a_char` at (`a_row`, `a_col`).
		do
			if is_border_merged then
				Collision_solver.merge_into_buffer (a_buffer, a_row, a_col, a_char, a_style)
			else
				a_buffer.put_char (a_row, a_col, a_char, a_style)
			end
		end

	Collision_solver: BORDER_COLLISION_SOLVER
			-- Shared collision solver for border fusion
		once
			create Result
		ensure
			instance_free: class
		end

feature {NONE} -- Implementation: Title Rendering

	render_title_row (a_position: NATURAL_8; a_x, a_y, a_w: INTEGER; a_buffer: BUFFER)
			-- Titles at `a_position` on the border row `a_y`, between the corners of the block
			-- starting at `a_x` with width `a_w`. As in Ratatui, titles sharing an alignment are
			-- placed one after another with one space between them: the left group from the
			-- left corner, the right group up to the right corner, the centre group centred.
			-- The `title` of `set_title` / `with_title` is a top title with `title_alignment`.
			-- Everything is clipped between the corners and to the buffer.
		local
			l_groups: ARRAY [ARRAYED_LIST [TEXT_LINE]]
			l_left, l_right, l_total, l_start: INTEGER
			g: INTEGER
		do
			if a_w > 2 and a_y >= 0 and a_y < a_buffer.height then
				l_groups := <<create {ARRAYED_LIST [TEXT_LINE]}.make (1), create {ARRAYED_LIST [TEXT_LINE]}.make (1),
					create {ARRAYED_LIST [TEXT_LINE]}.make (1)>>
				-- `add_title` mirrors the first top title into `title`: draw that one only once
				if a_position = {BLOCK_TITLE}.position_top and attached title as al_title
					and then not across titles as t some t.content = al_title end then
					l_groups [group_index (title_alignment)].extend (al_title)
				end
				across titles as t loop
					if t.position = a_position then
						l_groups [group_index (t.alignment)].extend (t.content)
					end
				end
				l_left := a_x + 1
				l_right := a_x + a_w - 1
				from
					g := 1
				until
					g > 3
				loop
					if not l_groups [g].is_empty then
						l_total := l_groups [g].count - 1
						across l_groups [g] as t loop
							l_total := l_total + t.width.to_integer_32
						end
						inspect g
						when 1 then
							l_start := l_left
						when 2 then
							l_start := l_left + ((l_right - l_left - l_total) // 2).max (0)
						else
							l_start := (l_right - l_total).max (l_left)
						end
						across l_groups [g] as t loop
							a_buffer.set_line_clipped (a_y, l_start, t, style, l_left, l_right)
							l_start := l_start + t.width.to_integer_32 + 1
						end
					end
					g := g + 1
				end
			end
		end

	group_index (a_alignment: NATURAL_8): INTEGER
			-- 1 for left, 2 for centre, 3 for right alignment
		do
			if a_alignment = {TEXT_ALIGNMENT}.center then
				Result := 2
			elseif a_alignment = {TEXT_ALIGNMENT}.right then
				Result := 3
			else
				Result := 1
			end
		end

invariant
	valid_borders: {BORDERS}.is_valid (borders)
	valid_type: {BORDER_TYPE}.is_valid (border_type)
	valid_title_alignment: {TEXT_ALIGNMENT}.is_valid (title_alignment)
	border_style_not_void: border_style /= Void
	style_not_void: style /= Void
	padding_not_void: padding /= Void
	four_sided_padding_not_void: four_sided_padding /= Void
	titles_not_void: titles /= Void
end
