note
	description: "[
		EXAMPLE_INPUT_FORM driven directly, without `run`, so that a test can render it
		on a VIRTUAL_TERMINAL and feed it events (review p0_interaction_review.md, T1).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	INPUT_FORM_SNAPSHOT_APP

inherit
	EXAMPLE_INPUT_FORM

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

end
