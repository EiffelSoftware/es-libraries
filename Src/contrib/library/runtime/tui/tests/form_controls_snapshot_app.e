note
	description: "[
		EXAMPLE_FORM_CONTROLS driven directly, without `run`, so that a test can render it into
		a frame and feed it events (P2 W1-W3 review, defect #3).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	FORM_CONTROLS_SNAPSHOT_APP

inherit
	EXAMPLE_FORM_CONTROLS

create
	make_on

feature -- Direct driving

	render_now (a_frame: FRAME)
			-- Render the example into `a_frame`.
		require
			frame_attached: a_frame /= Void
		do
			render (a_frame)
		end

	process_now (a_event: EVENT)
			-- Process `a_event` as the example does.
		require
			event_attached: a_event /= Void
		do
			process (a_event)
		end

	is_focused_id (a_value: INTEGER): BOOLEAN
			-- Is the control whose id has `a_value` (1 .. 7, in Tab order) focused?
		do
			Result := attached focus_manager.focused_id as l_id and then l_id.value = a_value
		end

end
