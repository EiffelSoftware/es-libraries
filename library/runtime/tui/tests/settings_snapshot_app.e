note
	description: "[
		EXAMPLE_SETTINGS driven directly, without `run`, on a clock and a save path the test
		sets, so that a test can render it into a frame and feed it events (P2 step 7, C3).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	SETTINGS_SNAPSHOT_APP

inherit
	EXAMPLE_SETTINGS
		redefine
			clock_ms,
			save_path
		end

create
	make_on

feature -- Test settings

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

	save_path: STRING_32
			-- Where `s` saves: `test_save_path` once set, else a name in no directory
		do
			if attached test_save_path as l_path then
				Result := l_path
			else
				Result := Precursor
			end
		end

	test_save_path: detachable STRING_32
			-- The save path set by the test

	set_save_path (a_path: READABLE_STRING_GENERAL)
			-- Save to `a_path`.
		do
			create test_save_path.make_from_string_general (a_path)
		ensure
			set: save_path.same_string_general (a_path)
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

	load_theme_file (a_path: READABLE_STRING_GENERAL)
			-- Add the theme file at `a_path`, as the example does with its argument.
		require
			path_not_empty: not a_path.is_empty
		do
			add_theme_file (a_path)
		end

end
