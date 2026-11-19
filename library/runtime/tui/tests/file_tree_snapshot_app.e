note
	description: "[
		EXAMPLE_FILE_TREE driven directly, without `run`, so that a test can render it into a
		frame and feed it events (P2b R2). `click_at` maps a cell of a rendered frame to its
		hit region as `hit_test` does for the frame on screen.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	FILE_TREE_SNAPSHOT_APP

inherit
	EXAMPLE_FILE_TREE

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

	click_at (a_frame: FRAME; a_column, a_row: NATURAL_16)
			-- A click on cell (`a_column`, `a_row`) of `a_frame`, as rendered last.
		require
			frame_attached: a_frame /= Void
		do
			click (a_frame.hit_map.hit (a_column, a_row))
		end

	selected_id: STRING_32
			-- Id of the selected node ("" when none)
		do
			if attached tree_state.selected_id as l_id then
				Result := l_id
			else
				create Result.make_empty
			end
		end

end
