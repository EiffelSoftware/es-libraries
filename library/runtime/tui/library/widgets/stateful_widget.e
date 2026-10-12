note
	description: "[
		Generic base interface for stateful widgets whose rendering depends on and updates
		external mutable widget state `S` (e.g. selection, scroll offsets).
		Compile-time type safety ensures widgets only receive their corresponding state type.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	STATEFUL_WIDGET [S -> WIDGET_STATE]

inherit
	STATEFUL_WIDGET_BASE

feature -- Rendering

	render_stateful (a_area: RECT; a_buffer: BUFFER; a_state: S)
			-- Render widget with mutable state `a_state` within `a_area` on `a_buffer`.
		require
			area_not_void: a_area /= Void
			buffer_not_void: a_buffer /= Void
			state_not_void: a_state /= Void
		deferred
		end

feature -- Status report

	accepts_state (a_state: WIDGET_STATE): BOOLEAN
			-- Is `a_state` an `S`?
		do
			Result := attached {S} a_state
		end

feature {FRAME, STATEFUL_WIDGET} -- Bridge

	render_stateful_base (a_area: RECT; a_buffer: BUFFER; a_state: WIDGET_STATE)
			-- Bridge polymorphic state to generic `render_stateful`.
		do
			if attached {S} a_state as l_s then
				render_stateful (a_area, a_buffer, l_s)
			end
		end

end
