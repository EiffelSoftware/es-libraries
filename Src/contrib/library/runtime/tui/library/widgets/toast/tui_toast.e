note
	description: "[
		Draws the visible toasts of a TOAST_QUEUE stacked at one edge of its area: a corner, or
		centred on the top or the bottom edge (TOAST_POSITION). Ratatui has no toast widget;
		apps draw one as a `Clear` and a `Block` over the rest, which is what this widget
		draws for each toast.

		    l_toasts.push ("Saved settings.toml", {TOAST_LEVEL}.success, 3000)
		    ...
		    frame.render_stateful_widget ((create {TUI_TOAST}).with_theme (l_theme), frame.area, l_toasts)

		Render it last: like a popup, each toast is drawn over what is under it.

		Each toast is a box: the cells under it are cleared first (TUI_CLEAR, as TUI_POPUP
		clears its area), then a TUI_BLOCK with `border_type`, `style` patched over the box and
		the border in the toast level's style (`level_style`), then the text inside it.
		  * Width: the text is word-wrapped (TEXT_LAYOUT, leading and trailing blanks of each
		    wrapped row trimmed) to the box's inside, at most `max_width` - 2 columns, and at
		    most the area's width - 2, so a toast wider than the area is wrapped to the
		    area's width. A word longer than the inside is broken between grapheme clusters.
		    The box is as wide as its widest wrapped row + 2.
		  * Height: one row per wrapped row + 2.
		  * Text style: the cell's style inside the box (the cleared cell patched by `style`),
		    patched by the TEXT's, the line's and the span's styles, as BUFFER draws a line.
		    Each row is aligned in the inside by its own alignment, else the TEXT's
		    (left by default), as TUI_PARAGRAPH aligns a line.
		  * Stacking: the first visible toast (the oldest) is next to the edge of `position`;
		    newer ones stack away from it, with no gap, so a toast does not move when a newer
		    one arrives. A top position stacks downwards, a bottom one upwards.
		  * Cut: a toast that does not fit whole in the rows left is cut to them (its last
		    rows left out, the box closed at the cut), and no later toast is drawn; with fewer
		    than 3 rows left nothing more is drawn. An area narrower than 3 columns draws no
		    toast. The queue is not changed: a toast not drawn is still visible for the queue,
		    and its clock runs.
		  * Buffer: the layout is made on the area; what falls outside the buffer is not
		    drawn (TUI_BLOCK closes a box cut by the buffer's edge, and the text is clipped
		    to the inside of that closed box).

		Hit regions (FRAME.render_stateful_widget registers them; the widget is a
		HIT_CONTAINER with state): each box drawn is registered, so a click on a toast does
		not reach what is under it. With `hit_id_base` > 0 a box is registered under the id
		`hit_id_base` + the toast's `id`, so the application dismisses the toast clicked,
		whatever expired since the frame was drawn:

		    if attached hit_test (m) as l_hit and then toasts.has_id (l_hit.value - Toast_ids) then
		        toasts.dismiss_id (l_hit.value - Toast_ids)
		    end

		With `hit_id_base` = 0 (the default) a box is a blocker: it hits nothing. Pick a base
		above every other id of the application: toast ids keep growing. `toast_areas` gives
		the boxes too.

		The stateless `render` draws nothing: there is no queue.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_TOAST

inherit
	STATEFUL_WIDGET [TOAST_QUEUE]
		redefine
			default_create,
			is_equal
		end

	HIT_CONTAINER
		redefine
			default_create,
			is_equal,
			register_child_hits_with_state
		end

create
	default_create,
	make

feature {NONE} -- Initialization

	default_create
			-- Toasts at the top right, at most `Default_max_width` columns wide, plain borders
			-- in cyan (info), green (success), yellow (warning) and red (error).
		do
			position := {TOAST_POSITION}.top_right
			max_width := Default_max_width
			border_type := {BORDER_TYPE}.plain
			create style
			create info_style.make_fg ({COLOR}.cyan)
			create success_style.make_fg ({COLOR}.green)
			create warning_style.make_fg ({COLOR}.yellow)
			create error_style.make_fg ({COLOR}.red)
		ensure then
			top_right: position = {TOAST_POSITION}.top_right
			default_width: max_width = Default_max_width
			plain: border_type = {BORDER_TYPE}.plain
		end

	make
			-- Synonym for `default_create`.
		do
			default_create
		end

feature -- Access

	position: NATURAL_8
			-- Edge the toasts stack from (TOAST_POSITION)

	max_width: NATURAL_16
			-- Widest box, borders included

	border_type: NATURAL_8
			-- Box corners and edges (BORDER_TYPE)

	style: STYLE
			-- Style patched over each box

	info_style: STYLE
			-- Border style of an info toast

	success_style: STYLE
			-- Border style of a success toast

	warning_style: STYLE
			-- Border style of a warning toast

	error_style: STYLE
			-- Border style of an error toast

	level_style (a_level: NATURAL_8): STYLE
			-- Border style of a toast at `a_level`
		require
			valid_level: {TOAST_LEVEL}.is_valid (a_level)
		do
			inspect a_level
			when {TOAST_LEVEL}.success then
				Result := success_style
			when {TOAST_LEVEL}.warning then
				Result := warning_style
			when {TOAST_LEVEL}.error then
				Result := error_style
			else
				Result := info_style
			end
		ensure
			result_not_void: Result /= Void
		end

	hit_id_base: INTEGER
			-- Base of the ids the boxes are registered under (base + the toast's `id`); 0:
			-- the boxes are blockers

	Default_max_width: NATURAL_16 = 40
			-- `max_width` of a new widget

	Minimum_width: NATURAL_16 = 3
			-- Narrowest box: two borders and one column of text

feature -- Geometry

	toast_areas (a_area: RECT; a_queue: TOAST_QUEUE): ARRAYED_LIST [RECT]
			-- Boxes of the toasts of `a_queue` drawn in `a_area`, in queue order (the first is
			-- the oldest, next to the edge); fewer than `a_queue.visible_count` when the area
			-- has no room for the others (see the class note).
		require
			area_not_void: a_area /= Void
			queue_not_void: a_queue /= Void
		local
			l_layout: like layout
		do
			l_layout := layout (a_area, a_queue)
			create Result.make (l_layout.count)
			across l_layout as e loop
				Result.extend (e.box)
			end
		ensure
			result_not_void: Result /= Void
			at_most_visible: Result.count <= a_queue.visible_count
			inside_area: across Result as b all a_area.contains_rect (b) end
			not_too_wide: across Result as b all b.width <= max_width end
			at_least_minimum: across Result as b all b.width >= Minimum_width and b.height >= Minimum_width end
		end

feature -- Element change

	set_position (a_position: NATURAL_8)
			-- Stack the toasts from `a_position`.
		require
			valid_position: {TOAST_POSITION}.is_valid (a_position)
		do
			position := a_position
		ensure
			position_set: position = a_position
		end

	set_max_width (a_width: NATURAL_16)
			-- Make no box wider than `a_width` columns, borders included.
		require
			room_for_text: a_width >= Minimum_width
		do
			max_width := a_width
		ensure
			max_width_set: max_width = a_width
		end

	set_border_type (a_type: NATURAL_8)
			-- Draw the boxes with `a_type` corners and edges.
		require
			valid_type: {BORDER_TYPE}.is_valid (a_type)
		do
			border_type := a_type
		ensure
			border_type_set: border_type = a_type
		end

	set_style (a_style: STYLE)
			-- Patch `a_style` over each box.
		require
			style_not_void: a_style /= Void
		do
			style := a_style
		ensure
			style_set: style = a_style
		end

	set_level_style (a_level: NATURAL_8; a_style: STYLE)
			-- Draw the border of toasts at `a_level` in `a_style`.
		require
			valid_level: {TOAST_LEVEL}.is_valid (a_level)
			style_not_void: a_style /= Void
		do
			inspect a_level
			when {TOAST_LEVEL}.success then
				success_style := a_style
			when {TOAST_LEVEL}.warning then
				warning_style := a_style
			when {TOAST_LEVEL}.error then
				error_style := a_style
			else
				info_style := a_style
			end
		ensure
			level_style_set: level_style (a_level) = a_style
		end

	set_hit_id_base (a_base: INTEGER)
			-- Register each box under `a_base` + its toast's `id` (0: as a blocker).
		require
			non_negative: a_base >= 0
		do
			hit_id_base := a_base
		ensure
			hit_id_base_set: hit_id_base = a_base
		end

	set_theme (a_theme: TUI_THEME)
			-- Take the box style from `a_theme.base` and the level styles from its `info`,
			-- `success`, `warning` and `error` styles.
		require
			theme_not_void: a_theme /= Void
		do
			style := a_theme.base
			info_style := a_theme.info
			success_style := a_theme.success
			warning_style := a_theme.warning
			error_style := a_theme.error
		ensure
			style_set: style = a_theme.base
			info_set: info_style = a_theme.info
			success_set: success_style = a_theme.success
			warning_set: warning_style = a_theme.warning
			error_set: error_style = a_theme.error
		end

feature -- Fluent Builders

	with_position (a_position: NATURAL_8): like Current
			-- Copy of Current stacking the toasts from `a_position`.
		require
			valid_position: {TOAST_POSITION}.is_valid (a_position)
		do
			Result := twin
			Result.set_position (a_position)
		ensure
			result_not_void: Result /= Void
			position_set: Result.position = a_position
		end

	with_max_width (a_width: NATURAL_16): like Current
			-- Copy of Current with no box wider than `a_width` columns.
		require
			room_for_text: a_width >= Minimum_width
		do
			Result := twin
			Result.set_max_width (a_width)
		ensure
			result_not_void: Result /= Void
			max_width_set: Result.max_width = a_width
		end

	with_border_type (a_type: NATURAL_8): like Current
			-- Copy of Current drawing the boxes with `a_type`.
		require
			valid_type: {BORDER_TYPE}.is_valid (a_type)
		do
			Result := twin
			Result.set_border_type (a_type)
		ensure
			result_not_void: Result /= Void
			border_type_set: Result.border_type = a_type
		end

	with_style (a_style: STYLE): like Current
			-- Copy of Current patching `a_style` over each box.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_style (a_style)
		ensure
			result_not_void: Result /= Void
			style_set: Result.style = a_style
		end

	with_level_style (a_level: NATURAL_8; a_style: STYLE): like Current
			-- Copy of Current drawing the border of toasts at `a_level` in `a_style`.
		require
			valid_level: {TOAST_LEVEL}.is_valid (a_level)
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_level_style (a_level, a_style)
		ensure
			result_not_void: Result /= Void
			level_style_set: Result.level_style (a_level) = a_style
		end

	with_hit_id_base (a_base: INTEGER): like Current
			-- Copy of Current registering each box under `a_base` + its toast's `id`.
		require
			non_negative: a_base >= 0
		do
			Result := twin
			Result.set_hit_id_base (a_base)
		ensure
			result_not_void: Result /= Void
			hit_id_base_set: Result.hit_id_base = a_base
		end

	with_theme (a_theme: TUI_THEME): like Current
			-- Copy of Current with its styles from `a_theme` (see `set_theme`).
		require
			theme_not_void: a_theme /= Void
		do
			Result := twin
			Result.set_theme (a_theme)
		ensure
			result_not_void: Result /= Void
			style_set: Result.style = a_theme.base
			error_set: Result.error_style = a_theme.error
		end

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Same position, width, border type and styles?
		do
			if a_other = Current then
				Result := True
			else
				Result := position = a_other.position
					and max_width = a_other.max_width
					and hit_id_base = a_other.hit_id_base
					and border_type = a_other.border_type
					and style.is_equal (a_other.style)
					and info_style.is_equal (a_other.info_style)
					and success_style.is_equal (a_other.success_style)
					and warning_style.is_equal (a_other.warning_style)
					and error_style.is_equal (a_other.error_style)
			end
		end

feature -- Rendering

	render (a_area: RECT; a_buffer: BUFFER)
			-- Draw nothing: without a queue there is no toast.
		do
		end

	render_stateful (a_area: RECT; a_buffer: BUFFER; a_queue: TOAST_QUEUE)
			-- Draw the visible toasts of `a_queue` stacked in `a_area` (see the class note).
		local
			l_block: TUI_BLOCK
			l_inside: RECT
			l_row, l_col, l_inside_width: INTEGER
			l_base: STYLE
		do
			across layout (a_area, a_queue) as e loop
				(create {TUI_CLEAR}).render (e.box, a_buffer)
				l_block := (create {TUI_BLOCK}.make).with_border_type (border_type).with_style (style)
					.with_border_style (level_style (e.toast.level))
				l_block.render (e.box, a_buffer)
					-- The inside of the box TUI_BLOCK closed at the buffer's edge
				l_inside := e.box.intersection (a_buffer.area).inner (1, 1)
				if not l_inside.is_empty then
					l_inside_width := e.box.width.to_integer_32 - 2
					l_row := e.box.y.to_integer_32 + 1
					across e.lines as l loop
						if l_row >= l_inside.top.to_integer_32 and l_row < l_inside.bottom.to_integer_32 then
								-- Aligned in the whole inside, before the buffer's cut
							l_col := e.box.x.to_integer_32 + 1 + {TEXT_LAYOUT}.aligned_offset (l.width,
								l_inside_width.max (0).to_natural_16, l.resolved_alignment (e.toast.text.alignment)).to_integer_32
							l_base := a_buffer.cell (l_row, l_inside.left.to_integer_32).style.patch (e.toast.text.style)
							a_buffer.set_line_clipped (l_row, l_col, l, l_base,
								l_inside.left.to_integer_32, l_inside.right.to_integer_32)
						end
						l_row := l_row + 1
					end
				end
			end
		end

feature {FRAME} -- Hit testing

	register_child_hits (a_area: RECT; a_frame: FRAME)
			-- Nothing: without a queue there are no toasts (as `render` draws none).
		do
		end

	register_child_hits_with_state (a_area: RECT; a_state: detachable WIDGET_STATE; a_frame: FRAME)
			-- Register each box drawn for the queue `a_state`, under `hit_id_base` + its
			-- toast's `id`, or as a blocker when `hit_id_base` is 0 (see the class note).
		local
			l_box: RECT
		do
			if attached {TOAST_QUEUE} a_state as q then
				across layout (a_area, q) as e loop
					l_box := e.box.intersection (a_frame.area)
					if not l_box.is_empty then
						if hit_id_base > 0 then
							a_frame.register_hit (create {WIDGET_ID}.make (hit_id_base + e.toast.id), l_box)
						else
							a_frame.register_blocker (l_box)
						end
					end
				end
			end
		end

feature {NONE} -- Implementation

	layout (a_area: RECT; a_queue: TOAST_QUEUE): ARRAYED_LIST [TUPLE [box: RECT; lines: ARRAYED_LIST [TEXT_LINE]; toast: TOAST]]
			-- Box and wrapped rows of each visible toast of `a_queue` drawn in `a_area`, in
			-- queue order; the rows of a cut box are its first ones.
		require
			area_not_void: a_area /= Void
			queue_not_void: a_queue /= Void
		local
			i, l_limit, l_inside, l_width, l_height, l_used, l_left, l_x, l_y: INTEGER
			l_lines: ARRAYED_LIST [TEXT_LINE]
			l_toast: TOAST
			l_stop: BOOLEAN
		do
			create Result.make (a_queue.visible_count)
			l_limit := max_width.min (a_area.width).to_integer_32
			if l_limit >= Minimum_width.to_integer_32 then
				l_inside := l_limit - 2
				from
					i := 1
				until
					l_stop or i > a_queue.visible_count
				loop
					l_left := a_area.height.to_integer_32 - l_used
					if l_left < Minimum_width.to_integer_32 then
						l_stop := True
					else
						l_toast := a_queue.item (i)
						l_lines := {TEXT_LAYOUT}.wrap_text (l_toast.text, l_inside.to_natural_16, {TEXT_WRAP_MODE}.word, True)
						l_width := 1
						across l_lines as l loop
							l_width := l_width.max (l.width.to_integer_32)
						end
						l_width := (l_width + 2).min (l_limit)
						l_height := l_lines.count + 2
						if l_height > l_left then
							l_height := l_left
							l_stop := True
							from until l_lines.count <= l_height - 2 loop
								l_lines.finish
								l_lines.remove
							end
						end
						if {TOAST_POSITION}.is_left (position) then
							l_x := a_area.x.to_integer_32
						elseif {TOAST_POSITION}.is_right (position) then
							l_x := a_area.x.to_integer_32 + a_area.width.to_integer_32 - l_width
						else
							l_x := a_area.x.to_integer_32 + (a_area.width.to_integer_32 - l_width) // 2
						end
						if {TOAST_POSITION}.is_top (position) then
							l_y := a_area.y.to_integer_32 + l_used
						else
							l_y := a_area.y.to_integer_32 + a_area.height.to_integer_32 - l_used - l_height
						end
						Result.extend ([create {RECT}.make (l_x.to_natural_16, l_y.to_natural_16,
							l_width.to_natural_16, l_height.to_natural_16), l_lines, l_toast])
						l_used := l_used + l_height
					end
					i := i + 1
				end
			end
		ensure
			result_not_void: Result /= Void
			at_most_visible: Result.count <= a_queue.visible_count
		end

invariant
	valid_position: {TOAST_POSITION}.is_valid (position)
	valid_border_type: {BORDER_TYPE}.is_valid (border_type)
	room_for_text: max_width >= Minimum_width
	non_negative_hit_id_base: hit_id_base >= 0
	style_not_void: style /= Void
	info_style_not_void: info_style /= Void
	success_style_not_void: success_style /= Void
	warning_style_not_void: warning_style /= Void
	error_style_not_void: error_style /= Void

end
