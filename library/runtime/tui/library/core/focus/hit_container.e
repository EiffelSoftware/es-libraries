note
	description: "[
		Mixin for widgets that render other widgets inside their own area (such as TUI_POPUP
		with its `inner_widget`). FRAME.render_widget and FRAME.render_stateful_widget call
		`register_child_hits` after registering the container's own regions, so a HIT_TARGET
		child with a `hit_id` is clickable even though the container drew it straight into
		the buffer. Children are registered after the container, so they sit above it and
		above any blocker it registers.
		A stateful container (TUI_MENU, whose bar entries and drop-downs come from its
		MENU_STATE) redefines `register_child_hits_with_state`, which
		FRAME.render_stateful_widget calls with the state the widget was rendered with.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	HIT_CONTAINER

feature {FRAME} -- Hit testing

	register_child_hits (a_area: RECT; a_frame: FRAME)
			-- Register on `a_frame` the hit regions of the widgets Current rendered when it was
			-- rendered into `a_area`: call {FRAME}.register_rendered for each child with the
			-- area that child was rendered into.
		require
			area_attached: a_area /= Void
			frame_attached: a_frame /= Void
		deferred
		end

	register_child_hits_with_state (a_area: RECT; a_state: detachable WIDGET_STATE; a_frame: FRAME)
			-- As `register_child_hits`, for Current rendered into `a_area` with `a_state` (Void
			-- for an immediate-mode render). By default the state is not needed.
		require
			area_attached: a_area /= Void
			frame_attached: a_frame /= Void
		do
			register_child_hits (a_area, a_frame)
		end

end
