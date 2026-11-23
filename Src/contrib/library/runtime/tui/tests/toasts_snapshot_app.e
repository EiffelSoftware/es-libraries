note
	description: "[
		EXAMPLE_TOASTS driven directly, without `run`, on a clock the test sets, so that a
		test can render it into a frame and feed it keys and ticks (P2 W5).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TOASTS_SNAPSHOT_APP

inherit
	EXAMPLE_TOASTS
		redefine
			clock_ms
		end

create
	make_on

feature -- Clock

	clock_ms: INTEGER_64
			-- The test's clock
		do
			Result := fake_now
		end

	fake_now: INTEGER_64
			-- Time set by the test

	set_fake_now (a_ms: INTEGER_64)
			-- Set the clock to `a_ms`.
		require
			forward: a_ms >= fake_now
		do
			fake_now := a_ms
		ensure
			set: fake_now = a_ms
		end

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
