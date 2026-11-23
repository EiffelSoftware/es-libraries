note
	description: "[
		Drawing context passed to rendering agents during a single terminal draw pass.
		Provides access to the frame buffer, screen area, and widget rendering helpers.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	FRAME

create
	make

feature {NONE} -- Initialization

	make (a_buffer: BUFFER)
			-- Initialize frame bound to `a_buffer` with an empty hit map.
		require
			buffer_not_void: a_buffer /= Void
		do
			buffer := a_buffer
			create hit_map.make
			cursor_shape := {CURSOR_SHAPE}.Default_user
		ensure
			buffer_set: buffer = a_buffer
			hit_map_empty: hit_map.is_empty
			default_cursor_shape: cursor_shape.is_default
		end

feature -- Access

	buffer: BUFFER
			-- Backing frame buffer for this frame

	hit_map: HIT_MAP
			-- Per-frame mouse hit registrations (cleared for each new FRAME)

	area: RECT
			-- Entire available drawing area for this frame
		do
			create Result.make (0, 0, buffer.width.to_natural_16, buffer.height.to_natural_16)
		ensure
			result_not_void: Result /= Void
			correct_width: Result.width = buffer.width.to_natural_16
			correct_height: Result.height = buffer.height.to_natural_16
		end

feature -- Hit testing

	register_hit (a_id: WIDGET_ID; a_area: RECT)
			-- Register interactive `a_id` covering `a_area` for mouse hit-testing. After a
			-- modal widget was rendered, only the part of `a_area` inside its dialog area is
			-- registered (see {HIT_MAP}.effective_area).
		require
			id_attached: a_id /= Void
			area_attached: a_area /= Void
		do
			hit_map.register (a_id, a_area)
		ensure
			one_more: hit_map.count = old hit_map.count + 1
			topmost: not hit_map.effective_area (a_area).is_empty
				implies hit_map.hit (hit_map.effective_area (a_area).x, hit_map.effective_area (a_area).y) ~ a_id
		end

	register_blocker (a_area: RECT)
			-- Make clicks in `a_area` hit nothing, unless something registered later covers
			-- them (see {HIT_MAP}.register_blocker). A widget that is a {HIT_BLOCKER} with
			-- `blocks_hits` (such as a modal TUI_POPUP) goes further when rendered: it blocks
			-- `area` and clips later regions to its own area (see `register_rendered`).
		require
			area_attached: a_area /= Void
		do
			hit_map.register_blocker (a_area)
		ensure
			one_more: hit_map.count = old hit_map.count + 1
			hides_below: not a_area.is_empty implies hit_map.hit (a_area.x, a_area.y) = Void
		end

	begin_overlay (a_blocked: RECT)
			-- Block `a_blocked` and register the regions that follow unclipped until
			-- `end_overlay`, after which nothing registered can be clicked (see
			-- {HIT_MAP}.begin_overlay). An open TUI_MENU does this.
		require
			blocked_attached: a_blocked /= Void
			no_overlay_open: not hit_map.is_overlay_open
		do
			hit_map.begin_overlay (a_blocked)
		ensure
			open: hit_map.is_overlay_open
		end

	end_overlay
			-- Close the overlay opened by `begin_overlay`.
		require
			overlay_open: hit_map.is_overlay_open
		do
			hit_map.end_overlay
		ensure
			closed: not hit_map.is_overlay_open
		end

	register_rendered (a_widget: WIDGET; a_area: RECT)
			-- Register the hit regions of `a_widget`, rendered into `a_area`, in this order:
			-- if it is a HIT_BLOCKER with `blocks_hits`, a modal over the whole `area` with
			-- `a_area` as dialog ({HIT_MAP}.register_modal): everything registered before it
			-- (the background) hits nothing, and everything registered after it is clipped to
			-- `a_area`; then, if it is a HIT_TARGET with a `hit_id`, its `hit_area` in `a_area`
			-- (all of `a_area` unless the widget says otherwise) under that id; then, if it is a
			-- HIT_CONTAINER, the regions of the widgets it rendered inside `a_area`.
			-- `render_widget` calls this; a container calls it for each child from
			-- {HIT_CONTAINER}.register_child_hits.
		require
			widget_attached: a_widget /= Void
			area_attached: a_area /= Void
		do
			register_rendered_with_state (a_widget, a_area, Void)
		ensure
			blocked: (attached {HIT_BLOCKER} a_widget as l_blocker and then l_blocker.blocks_hits)
				implies (hit_map.count > old hit_map.count and hit_map.modal_area = a_area)
			targeted: (attached {HIT_TARGET} a_widget as l_target and then attached l_target.hit_id as l_id
				and then not attached {HIT_CONTAINER} a_widget
				and then not hit_map.effective_area (l_target.hit_area (a_area, Void)).is_empty)
				implies hit_map.hit (hit_map.effective_area (l_target.hit_area (a_area, Void)).x,
					hit_map.effective_area (l_target.hit_area (a_area, Void)).y) ~ l_id
		end

	register_rendered_with_state (a_widget: WIDGET; a_area: RECT; a_state: detachable WIDGET_STATE)
			-- As `register_rendered`, for `a_widget` rendered into `a_area` with `a_state` (Void
			-- for an immediate-mode widget), which a HIT_TARGET's `hit_area` and a
			-- HIT_CONTAINER's `register_child_hits_with_state` may depend on.
			-- `render_stateful_widget` calls this.
		require
			widget_attached: a_widget /= Void
			area_attached: a_area /= Void
		do
			if attached {HIT_BLOCKER} a_widget as l_blocker and then l_blocker.blocks_hits then
				hit_map.register_modal (area, a_area)
			end
			if attached {HIT_TARGET} a_widget as l_target and then attached l_target.hit_id as l_id then
				hit_map.register (l_id, l_target.hit_area (a_area, a_state))
			end
			if attached {HIT_CONTAINER} a_widget as l_container then
				l_container.register_child_hits_with_state (a_area, a_state, Current)
			end
		ensure
			blocked: (attached {HIT_BLOCKER} a_widget as l_blocker and then l_blocker.blocks_hits)
				implies (hit_map.count > old hit_map.count and hit_map.modal_area = a_area)
			targeted: (attached {HIT_TARGET} a_widget as l_target and then attached l_target.hit_id as l_id
				and then not attached {HIT_CONTAINER} a_widget
				and then not hit_map.effective_area (l_target.hit_area (a_area, a_state)).is_empty)
				implies hit_map.hit (hit_map.effective_area (l_target.hit_area (a_area, a_state)).x,
					hit_map.effective_area (l_target.hit_area (a_area, a_state)).y) ~ l_id
		end

feature -- Rendering

	render_widget (a_widget: WIDGET; a_area: RECT)
			-- Render immediate-mode `a_widget` into `a_area` on this frame, then register
			-- its hit regions (see `register_rendered`).
		require
			widget_not_void: a_widget /= Void
			area_not_void: a_area /= Void
		do
			a_widget.render (a_area, buffer)
			register_rendered (a_widget, a_area)
		end

	render_stateful_widget (a_widget: STATEFUL_WIDGET_BASE; a_area: RECT; a_state: WIDGET_STATE)
			-- Render `a_widget` using mutable state `a_state` into `a_area` on this frame,
			-- then register its hit regions (see `register_rendered`).
		require
			widget_not_void: a_widget /= Void
			area_not_void: a_area /= Void
			state_not_void: a_state /= Void
			state_type_matches: a_widget.accepts_state (a_state)
		do
			a_widget.render_stateful_base (a_area, buffer, a_state)
			register_rendered_with_state (a_widget, a_area, a_state)
		end

feature -- Cursor Management

	cursor_position: detachable TUPLE [col, row: INTEGER]
			-- Desired hardware cursor position, or Void if cursor should not be explicitly positioned.

	is_cursor_visible: BOOLEAN
			-- Should the hardware cursor be visible after rendering?

	cursor_shape: CURSOR_SHAPE
			-- Hardware cursor shape this frame asks for. Per frame, like the position: a
			-- frame that does not set it asks for {CURSOR_SHAPE}.Default_user, and TERMINAL
			-- writes the default again.

	set_cursor_position (a_col, a_row: INTEGER)
			-- Set hardware cursor position to (`a_col`, `a_row`) and make it visible.
		require
			valid_col: a_col >= 0 and a_col < buffer.width
			valid_row: a_row >= 0 and a_row < buffer.height
		do
			cursor_position := [a_col, a_row]
			is_cursor_visible := True
		ensure
			cursor_position_attached: cursor_position /= Void
			cursor_visible: is_cursor_visible = True
		end

	set_cursor_shape (a_shape: CURSOR_SHAPE)
			-- Ask for the hardware cursor shape `a_shape` (DECSCUSR) for this frame.
		require
			shape_attached: a_shape /= Void
		do
			cursor_shape := a_shape
		ensure
			cursor_shape_set: cursor_shape = a_shape
		end

	show_cursor
			-- Make hardware cursor visible.
		do
			is_cursor_visible := True
		ensure
			cursor_visible: is_cursor_visible = True
		end

	hide_cursor
			-- Hide hardware cursor.
		do
			is_cursor_visible := False
			cursor_position := Void
		ensure
			cursor_hidden: is_cursor_visible = False
			cursor_cleared: cursor_position = Void
		end

invariant
	buffer_not_void: buffer /= Void
	hit_map_attached: hit_map /= Void
	cursor_shape_attached: cursor_shape /= Void

end
