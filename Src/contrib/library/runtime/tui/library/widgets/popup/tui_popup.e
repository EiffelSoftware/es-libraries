note
	description: "[
		Modal popup / dialog container widget with background clearing,
		enclosing container block, and rectangle layout helpers.
		A popup is non-modal until `begin_modal` (or `begin_modal_with`) opens a focus
		scope for it. While that scope is open, the popup is modal for the keyboard (Tab
		stays in the scope) and for the mouse: rendered through a FRAME, it registers a
		blocker over the whole frame (see HIT_BLOCKER), so clicks on what was rendered
		before it (the background, inside or outside the popup) hit nothing, while the
		dialog's controls registered after it stay reachable; anything registered after it
		is clipped to the popup's area, so background controls rendered later (out of
		order) cannot be clicked through the dialog. Both follow the one scope, so
		they cannot disagree: `end_modal` (or popping the scope) ends both.
		Keep the popup object (or a `with_*` copy of it) across frames while it is open,
		since the modal state lives in it.
		Rendered through a FRAME, the popup also registers the hit region of its
		`inner_widget` when that is a HIT_TARGET with a `hit_id` (see HIT_CONTAINER).

		Shadow: `with_shadow` / `set_shadow` give the popup's block a SHADOW (a borderless
		block is made when there is none). The shadow is drawn outside the popup's area
		and is not cleared by `clear_background`, so it falls on the background. It
		registers no hit region of its own, which may not be what one expects:
		  * a non-modal popup: a click on the shadow hits the background control under it,
		    as if the shadow were not there;
		  * a modal popup: the click hits nothing, like any other click on the background
		    (the blocker covers the whole frame), and a control rendered after the popup is
		    clipped to the popup's area, so it cannot be clicked on the shadow either.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_POPUP

inherit
	BLOCK_CONTAINER
		redefine
			default_create
		end
	HIT_BLOCKER
		redefine
			default_create
		end
	HIT_CONTAINER
		redefine
			default_create
		end

create
	default_create,
	make,
	make_with_widget

feature {NONE} -- Initialization

	default_create
			-- Initialize a non-modal popup with clear_background enabled.
		do
			clear_background := True
		ensure then
			clears_background_by_default: clear_background
			not_modal: not is_modal_open
		end

	make
			-- Synonym for `default_create`.
		do
			default_create
		end

	make_with_widget (a_widget: WIDGET)
			-- Initialize with `a_widget` as inner content.
		require
			widget_not_void: a_widget /= Void
		do
			default_create
			inner_widget := a_widget
		ensure
			inner_widget_set: inner_widget = a_widget
		end

feature -- Access

	inner_widget: detachable WIDGET
			-- Widget rendered inside popup's inner area

	clear_background: BOOLEAN
			-- Whether cells behind the popup are cleared before rendering

	modal_focus: detachable FOCUS_MANAGER
			-- Focus manager in which `begin_modal` opened this popup's scope, until `end_modal`

	modal_depth: INTEGER
			-- `scope_depth` of `modal_focus` just after `begin_modal`; 0 when not modal

	shadow: detachable SHADOW
			-- Shadow of the block, if any
		do
			if attached block as b then
				Result := b.shadow
			end
		ensure
			no_block_no_shadow: block = Void implies Result = Void
		end

feature -- Status report

	is_modal_open: BOOLEAN
			-- Is the focus scope opened by `begin_modal` still open?
		do
			Result := attached modal_focus as l_focus and then l_focus.scope_depth >= modal_depth
		ensure
			definition: Result = (attached modal_focus as l_focus and then l_focus.scope_depth >= modal_depth)
		end

	blocks_hits: BOOLEAN
			-- Does rendering Current through a FRAME block hits on what was rendered before it?
			-- Exactly while the popup is modal.
		do
			Result := is_modal_open
		ensure then
			modal_only: Result = is_modal_open
		end

feature -- Geometry Helpers

	centered_rect (a_percent_x, a_percent_y: NATURAL_16; a_area: RECT): RECT
			-- Calculate a centered rectangle inside `a_area` with percentage dimensions `a_percent_x` and `a_percent_y`.
		require
			area_not_void: a_area /= Void
			valid_percent_x: a_percent_x <= 100
			valid_percent_y: a_percent_y <= 100
		local
			l_w, l_h, l_x, l_y: NATURAL_16
		do
			l_w := ((a_area.width.to_natural_32 * a_percent_x.to_natural_32) // 100).to_natural_16
			l_h := ((a_area.height.to_natural_32 * a_percent_y.to_natural_32) // 100).to_natural_16
			l_x := a_area.x + ((a_area.width - l_w) // 2)
			l_y := a_area.y + ((a_area.height - l_h) // 2)
			create Result.make (l_x, l_y, l_w, l_h)
		ensure
			result_not_void: Result /= Void
		end

	fixed_rect (a_width, a_height: NATURAL_16; a_area: RECT): RECT
			-- Calculate a centered rectangle of fixed dimensions `a_width` and `a_height` inside `a_area`.
			-- Clamped to `a_area` dimensions if larger.
		require
			area_not_void: a_area /= Void
		local
			l_w, l_h, l_x, l_y: NATURAL_16
		do
			l_w := a_width.min (a_area.width)
			l_h := a_height.min (a_area.height)
			l_x := a_area.x + ((a_area.width - l_w) // 2)
			l_y := a_area.y + ((a_area.height - l_h) // 2)
			create Result.make (l_x, l_y, l_w, l_h)
		ensure
			result_not_void: Result /= Void
		end

feature -- Element Change

	set_inner_widget (a_widget: detachable WIDGET)
			-- Set inner content widget.
		do
			inner_widget := a_widget
		ensure
			inner_widget_set: inner_widget = a_widget
		end

	set_clear_background (a_val: BOOLEAN)
			-- Set whether background is cleared before rendering.
		do
			clear_background := a_val
		ensure
			clear_background_set: clear_background = a_val
		end

	set_shadow (a_shadow: detachable SHADOW)
			-- Give the block shadow `a_shadow` (Void: none). The block is replaced by a copy
			-- with that shadow, so a block shared with other widgets (`with_block` shares it)
			-- is not changed. Without a block, a borderless one is made.
		local
			l_block: TUI_BLOCK
		do
			if attached block as b then
				l_block := b
			else
				create l_block.make
				l_block.set_borders ({BORDERS}.none)
			end
			set_block (l_block.with_shadow (a_shadow))
		ensure
			shadow_set: shadow = a_shadow
			borders_kept: attached old block as b implies (attached block as nb and then nb.borders = b.borders)
		end

feature -- Fluent Builders

	with_inner_widget (a_widget: detachable WIDGET): like Current
			-- Return a copy of Current with `inner_widget` set.
		do
			Result := twin
			Result.set_inner_widget (a_widget)
		ensure
			result_not_void: Result /= Void
			inner_widget_set: Result.inner_widget = a_widget
		end

	with_shadow (a_shadow: detachable SHADOW): like Current
			-- Return a copy of Current whose block has shadow `a_shadow` (Void: none).
		do
			Result := twin
			Result.set_shadow (a_shadow)
		ensure
			result_not_void: Result /= Void
			shadow_set: Result.shadow = a_shadow
			unchanged: shadow = old shadow
		end

	with_clear_background (a_val: BOOLEAN): like Current
			-- Return a copy of Current with `clear_background` set.
		do
			Result := twin
			Result.set_clear_background (a_val)
		ensure
			result_not_void: Result /= Void
			clear_background_set: Result.clear_background = a_val
		end

feature -- Modal focus trap

	begin_modal (a_focus: FOCUS_MANAGER)
			-- Push a modal focus scope on `a_focus` for this popup: Tab navigation stays
			-- inside the dialog, and rendering the popup blocks clicks on the background.
		require
			focus_attached: a_focus /= Void
			not_open: not is_modal_open
		do
			a_focus.push_scope
			modal_focus := a_focus
			modal_depth := a_focus.scope_depth
		ensure
			scoped: a_focus.scope_depth = old a_focus.scope_depth + 1
			open: is_modal_open
			blocking: blocks_hits
			focus_kept: modal_focus = a_focus
		end

	end_modal (a_focus: FOCUS_MANAGER)
			-- Pop the modal focus scope opened by `begin_modal`; the popup stops blocking clicks.
		require
			focus_attached: a_focus /= Void
			open: is_modal_open
			same_focus: modal_focus = a_focus
			innermost: a_focus.scope_depth = modal_depth
		do
			a_focus.pop_scope
			modal_focus := Void
			modal_depth := 0
		ensure
			restored: a_focus.scope_depth = old a_focus.scope_depth - 1
			closed: not is_modal_open
			not_blocking: not blocks_hits
		end

	begin_modal_with (a_focus: FOCUS_MANAGER; a_ids: ARRAY [WIDGET_ID])
			-- `begin_modal`, then register `a_ids` in the new scope (first becomes focused).
		require
			focus_attached: a_focus /= Void
			not_open: not is_modal_open
			ids_attached: a_ids /= Void
			ids_not_empty: a_ids.count > 0
		do
			a_focus.enter_modal (a_ids)
			modal_focus := a_focus
			modal_depth := a_focus.scope_depth
		ensure
			scoped: a_focus.scope_depth = old a_focus.scope_depth + 1
			has_focus: a_focus.has_focus
			open: is_modal_open
			blocking: blocks_hits
			focus_kept: modal_focus = a_focus
		end

feature -- Rendering

	render (a_area: RECT; a_buffer: BUFFER)
			-- Render popup dialog within `a_area` on `a_buffer`.
		local
			l_clear: TUI_CLEAR
			l_inner: RECT
		do
			if not a_area.is_empty then
				if clear_background then
					create l_clear
					l_clear.render (a_area, a_buffer)
				end
				render_block (a_area, a_buffer)
				if attached inner_widget as l_w then
					l_inner := inner_area (a_area)
					if not l_inner.is_empty then
						l_w.render (l_inner, a_buffer)
					end
				end
			end
		end

feature {FRAME} -- Hit testing

	register_child_hits (a_area: RECT; a_frame: FRAME)
			-- Register the hit regions of `inner_widget`, rendered into `inner_area (a_area)`
			-- (as `render` does).
		local
			l_inner: RECT
		do
			if not a_area.is_empty and then attached inner_widget as l_w then
				l_inner := inner_area (a_area)
				if not l_inner.is_empty then
					a_frame.register_rendered (l_w, l_inner)
				end
			end
		end

invariant
	modal_state_consistent: (modal_focus = Void) = (modal_depth = 0)
	modal_scope_nested: modal_focus /= Void implies modal_depth > 1

end
