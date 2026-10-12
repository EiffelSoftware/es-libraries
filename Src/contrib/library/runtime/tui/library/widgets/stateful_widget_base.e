note
	description: "[
		Non-generic base class for stateful widgets, allowing polymorphic dispatch
		from FRAME.render_stateful_widget. The state type cannot be checked at compile time
		on this path, so a mismatch is a precondition violation (`accepts_state`), never a
		silent no-op.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	STATEFUL_WIDGET_BASE

inherit
	WIDGET

feature -- Status report

	accepts_state (a_state: WIDGET_STATE): BOOLEAN
			-- Is `a_state` of the state type this widget renders with?
		require
			state_not_void: a_state /= Void
		deferred
		end

feature {FRAME, STATEFUL_WIDGET} -- Rendering bridge

	render_stateful_base (a_area: RECT; a_buffer: BUFFER; a_state: WIDGET_STATE)
			-- Bridge routine for polymorphic stateful rendering.
		require
			area_not_void: a_area /= Void
			buffer_not_void: a_buffer /= Void
			state_not_void: a_state /= Void
			state_type_matches: accepts_state (a_state)
		deferred
		end

end
