note
	description: "[
		Tier 5 Advanced Example: Async GitHub PR Fetcher (Ratatui 1-to-1).
		Demonstrates non-blocking background data fetching with animated Braille spinner,
		loading states, responsive table navigation, and on-demand refresh.

		A WORKER_THREAD simulates network latency, then posts a CUSTOM_EVENT via
		{TUI_APPLICATION}.post_event so the main loop applies the result without
		polling shared counters. No real HTTP/TLS dependency.

		Worker lifecycle (P2 B2): each fetch has a generation number. A refresh starts a
		new generation, and a quit cancels them all; the worker reads both, behind
		`fetch_mutex', between short sleeps, and stops early without posting. A result
		posted by an older fetch is dropped in `process'. The workers are kept and joined
		(with a timeout) in `stop_background_work', so `run' returns only once they have ended.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	EXAMPLE_ASYNC_GITHUB

inherit
	TUI_APPLICATION
		redefine
			make,
			stop_background_work
		end

create
	make,
	make_batch

feature {NONE} -- Initialization

	make
			-- Initialize and launch Async GitHub example.
		local
			l_args: ARGUMENTS_32
			i: INTEGER
		do
			init_state
			Precursor
				-- The worker's agent targets Current, so start it only once
				-- TUI_APPLICATION is initialized (and `post_event` has a queue).
			trigger_fetch
			set_tick_rate (50) -- 20 FPS
			create l_args
			auto_exit_frames := -1
			from i := 1 until i > l_args.argument_count loop
				if l_args.argument (i).is_equal ("-batch") then
					auto_exit_frames := 3
				end
				i := i + 1
			end
			frame_counter := 0
			run
		end

	make_batch (a_frames: INTEGER)
			-- Initialize and run for `a_frames` frames in batch mode.
		do
			init_state_loaded
			make_with_viewport (create {VIEWPORT}.make_fullscreen)
			set_tick_rate (50)
			auto_exit_frames := a_frames
			frame_counter := 0
			run
		end

feature {NONE} -- State

	auto_exit_frames: INTEGER
	frame_counter: INTEGER

	is_loading: BOOLEAN
	spinner_index: INTEGER

	Fetch_payload: STRING_8 = "prs_loaded"
			-- Token of the CUSTOM_EVENT payload posted by the fetch worker, with the fetch's
			-- generation (see `new_fetch_result`)

	pull_requests: ARRAYED_LIST [TUPLE [id, title, author, status, updated: STRING_8]]
	table_state: TABLE_STATE

feature {NONE} -- Setup

	init_state
			-- Setup the empty table; `make` starts the fetch.
		do
			create table_state.make
			create pull_requests.make (10)
			init_fetching
		end

	init_state_loaded
			-- Setup with data already present (batch mode).
		do
			create table_state.make
			create pull_requests.make (10)
			init_fetching
			simulate_load_complete
		end

	init_fetching
			-- No fetch yet, and no worker.
		do
			create fetch_mutex.make
			create fetch_workers.make (2)
			fetch_generation := 0
			is_fetch_cancelled := False
		end

feature {NONE} -- Fetching (P2 B2)

	fetch_generation: INTEGER
			-- Number of the latest fetch; a result tagged with another number is stale.
			-- Written by the main thread only, under `fetch_mutex` (workers read it)

	is_fetch_cancelled: BOOLEAN
			-- Have all fetches been cancelled (the application is quitting)?
			-- Written by the main thread only, under `fetch_mutex` (workers read it)

	fetch_mutex: MUTEX
			-- Guards `fetch_generation` and `is_fetch_cancelled`, shared with the workers

	fetch_workers: ARRAYED_LIST [WORKER_THREAD]
			-- Fetch workers that may still be running (main thread only)

	fetch_latency_ms: INTEGER
			-- Simulated network latency of one fetch (a test redefines it)
		do
			Result := 500
		ensure
			positive: Result > 0
		end

	Fetch_poll_ms: INTEGER = 10
			-- Sleep between two looks at `is_fetch_wanted`: how soon a worker stops once
			-- its fetch is stale or cancelled

	Worker_join_timeout_ms: NATURAL_64 = 500
			-- Longest wait for each worker in `stop_background_work`

	trigger_fetch
			-- Start a new fetch on a background worker thread. A fetch still running
			-- becomes stale: its worker stops without posting, and a result it already
			-- posted is dropped by `process`.
		local
			l_worker: WORKER_THREAD
			l_generation: INTEGER
		do
			forget_ended_workers
			fetch_mutex.lock
			fetch_generation := fetch_generation + 1
			l_generation := fetch_generation
			is_fetch_cancelled := False
			fetch_mutex.unlock
			is_loading := True
			spinner_index := 1
			create l_worker.make (agent fetch_worker_body (l_generation))
			fetch_workers.extend (l_worker)
			l_worker.launch
		ensure
			new_generation: fetch_generation = old fetch_generation + 1
			loading: is_loading
			worker_kept: fetch_workers.count >= 1
		end

	fetch_worker_body (a_generation: INTEGER)
			-- Simulate network latency, then wake the main loop with a CUSTOM_EVENT tagged
			-- with `a_generation`. Runs on the worker thread: stops early, without posting,
			-- once the fetch is stale or cancelled.
		local
			l_waited: INTEGER
		do
			from
			until
				l_waited >= fetch_latency_ms or not is_fetch_wanted (a_generation)
			loop
				(create {EXECUTION_ENVIRONMENT}).sleep (Fetch_poll_ms * 1_000_000)
				l_waited := l_waited + Fetch_poll_ms
			end
			if is_fetch_wanted (a_generation) then
				post_event (new_fetch_result (a_generation))
			end
		end

	is_fetch_wanted (a_generation: INTEGER): BOOLEAN
			-- Is fetch `a_generation` the latest, and not cancelled? (Thread-safe.)
		do
			fetch_mutex.lock
			Result := a_generation = fetch_generation and not is_fetch_cancelled
			fetch_mutex.unlock
		end

	new_fetch_result (a_generation: INTEGER): CUSTOM_EVENT
			-- Event carrying the result of fetch `a_generation`
		do
			create Result.make_with_payload ([Fetch_payload, a_generation])
		ensure
			tagged: attached {TUPLE [token: STRING_8; generation: INTEGER]} Result.payload as r
				and then r.generation = a_generation
		end

	forget_ended_workers
			-- Remove the workers that have ended from `fetch_workers`.
		do
			from
				fetch_workers.start
			until
				fetch_workers.after
			loop
				if fetch_workers.item.join_with_timeout (0) then
					fetch_workers.remove
				else
					fetch_workers.forth
				end
			end
		end

	worker_join_timed_out: BOOLEAN
			-- Did the last `stop_background_work` leave a worker running, because it did not
			-- end within `Worker_join_timeout_ms`? (It stays in `fetch_workers`.)

	stop_background_work
			-- Cancel every fetch and join its worker (at most `Worker_join_timeout_ms` each),
			-- so that `run` returns only once they have ended.
		local
			l_joined: BOOLEAN
		do
			fetch_mutex.lock
			is_fetch_cancelled := True
			fetch_mutex.unlock
			l_joined := True
			across fetch_workers as w loop
				l_joined := w.join_with_timeout (Worker_join_timeout_ms) and l_joined
			end
			worker_join_timed_out := not l_joined
			forget_ended_workers
		ensure then
			cancelled: is_fetch_cancelled
			joined_unless_timed_out: not worker_join_timed_out implies fetch_workers.is_empty
		end

feature {NONE} -- Data

	simulate_load_complete
			-- Populate PR dataset upon async completion.
		do
			pull_requests.wipe_out
			pull_requests.extend (["#1048", "feat(widgets): implement Braille canvas marker shaders", "jvelilla", "OPEN", "10m ago"])
			pull_requests.extend (["#1047", "fix(terminal): handle Windows Terminal mouse drag clamp", "eiffel-guru", "MERGED", "1h ago"])
			pull_requests.extend (["#1046", "refactor(diff): optimize UTF-32 cluster memory sharing", "bmeyer", "MERGED", "3h ago"])
			pull_requests.extend (["#1045", "docs(examples): complete Tier 5 Ratatui parity suite", "antigravity", "OPEN", "5h ago"])
			pull_requests.extend (["#1044", "test(autotest): add fuzz tests for layout flex constraints", "ci-bot", "MERGED", "1d ago"])
			pull_requests.extend (["#1043", "perf(buffer): zero-allocation string clipping cache", "perf-wizard", "MERGED", "2d ago"])
			pull_requests.extend (["#1042", "style(cqs): enforce strict query immutability contracts", "ada-team", "MERGED", "3d ago"])
			is_loading := False
			table_state.select_first
		end

feature {NONE} -- Application Hooks

	render (a_frame: FRAME)
			-- Render async pull request interface.
		local
			l_v_layout: LAYOUT
			l_v_chunks: ARRAY [RECT]
			l_title_area, l_body_area, l_foot_area: RECT
			l_title_para, l_spin_para, l_foot_para: TUI_PARAGRAPH
			l_title_style, l_spin_style, l_hdr_style: STYLE
			l_spin_sym: STRING_32
			l_table: TUI_TABLE
			l_header_row, l_row: TABLE_ROW
			l_rows: ARRAYED_LIST [TABLE_ROW]
			l_block: TUI_BLOCK
			l_b_style, l_row_style, l_sel_style: STYLE
			i: INTEGER
		do
			if auto_exit_frames > 0 then
				frame_counter := frame_counter + 1
				if frame_counter >= auto_exit_frames then
					stop
				end
			end

			-- Layout: Title (2), Body (fill), Footer (2)
			create l_v_layout.make_vertical (<<
				{CONSTRAINTS}.fixed (2),
				{CONSTRAINTS}.flex (1),
				{CONSTRAINTS}.fixed (2)
			>>)
			l_v_chunks := l_v_layout.split (a_frame.area)
			l_title_area := l_v_chunks [1]
			l_body_area := l_v_chunks [2]
			l_foot_area := l_v_chunks [3]

			-- 1. Title
			create l_title_style.make_fg ({COLOR}.Bright_cyan)
			l_title_style := l_title_style.with_bold
			create l_title_para.make (create {TEXT}.make_styled ("EiffelTUI Async GitHub Pull Request Monitor", l_title_style))
			l_title_para := l_title_para.with_alignment ({TEXT_ALIGNMENT}.center)
			a_frame.render_widget (l_title_para, l_title_area)

			-- 2. Body: Spinner or Table
			if is_loading then
				-- Animated Braille spinner
				l_spin_sym := spinner_char (spinner_index)
				create l_spin_style.make_fg ({COLOR}.Bright_yellow)
				l_spin_style := l_spin_style.with_bold

				create l_spin_para.make (create {TEXT}.make_styled (l_spin_sym + " Fetching repository pull requests in background thread...", l_spin_style))
				l_spin_para := l_spin_para.with_alignment ({TEXT_ALIGNMENT}.center)
				a_frame.render_widget (l_spin_para, l_body_area)
			else
				-- Table Block
				create l_b_style.make_fg ({COLOR}.Bright_blue)
				create l_block.make
				l_block := l_block.with_borders ({BORDERS}.all_borders).
					with_border_type ({BORDER_TYPE}.rounded).
					with_border_style (l_b_style).
					with_title (" Pull Requests: jvelilla/tui (7) ")

				-- Header
				create l_hdr_style.make_fg ({COLOR}.Bright_yellow)
				l_hdr_style := l_hdr_style.with_bold
				create l_header_row.make_raw (<<"PR #", "Title", "Author", "Status", "Updated">>)
				l_header_row := l_header_row.with_style (l_hdr_style)

				-- Rows
				create l_rows.make (pull_requests.count)
				create l_row_style.make_fg ({COLOR}.White)
				from i := 1 until i > pull_requests.count loop
					create l_row.make_raw (<<
						pull_requests [i].id,
						pull_requests [i].title,
						pull_requests [i].author,
						pull_requests [i].status,
						pull_requests [i].updated
					>>)
					l_row := l_row.with_style (l_row_style)
					l_rows.extend (l_row)
					i := i + 1
				end

				create l_sel_style.make_with_colors ({COLOR}.Bright_white, {COLOR}.Blue)
				l_sel_style := l_sel_style.with_bold

				create l_table.make (
					l_rows,
					<<
						{CONSTRAINTS}.fixed (8),
						{CONSTRAINTS}.flex (1),
						{CONSTRAINTS}.fixed (16),
						{CONSTRAINTS}.fixed (10),
						{CONSTRAINTS}.fixed (12)
					>>
				)
				l_table := l_table.with_header (l_header_row).
					with_row_highlight_style (l_sel_style).
					with_block (l_block)

				a_frame.render_stateful_widget (l_table, l_body_area, table_state)
			end

			-- 3. Footer
			create l_foot_para.make (create {TEXT}.make_styled ("Controls: [j/k or Up/Down] Select  |  [r] Refresh  |  [q] Quit", create {STYLE}.make_fg ({COLOR}.Dark_gray)))
			l_foot_para := l_foot_para.with_alignment ({TEXT_ALIGNMENT}.center)
			a_frame.render_widget (l_foot_para, l_foot_area)
		end

	spinner_char (a_idx: INTEGER): STRING_32
			-- Braille spinner glyphs: ⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏
		local
			l_s: STRING_32
		do
			create l_s.make_filled ('%U', 1)
			inspect a_idx
			when 1 then l_s.put_code (10251, 1) -- ⠋
			when 2 then l_s.put_code (10265, 1) -- ⠙
			when 3 then l_s.put_code (10269, 1) -- ⠹
			when 4 then l_s.put_code (10296, 1) -- ⠸
			when 5 then l_s.put_code (10292, 1) -- ⠼
			when 6 then l_s.put_code (10294, 1) -- ⠴
			when 7 then l_s.put_code (10278, 1) -- ⠦
			when 8 then l_s.put_code (10279, 1) -- ⠧
			when 9 then l_s.put_code (10247, 1) -- ⠇
			when 10 then l_s.put_code (10255, 1) -- ⠏
			else l_s.put_code (10251, 1)
			end
			Result := l_s
		end

	process (a_event: EVENT)
			-- Process navigation, refresh, custom fetch results, and quit keys.
		do
			if a_event.is_tick then
				if is_loading then
					spinner_index := (spinner_index \\ 10) + 1
				end
			elseif attached {CUSTOM_EVENT} a_event as c then
				if attached {TUPLE [token: STRING_8; generation: INTEGER]} c.payload as r
					and then r.token.same_string (Fetch_payload)
					and then r.generation = fetch_generation
				then
					-- Only the latest fetch's result: an older one is stale and dropped.
					-- `fetch_generation` needs no lock here: only this thread writes it
					simulate_load_complete
				end
			elseif attached {KEY_EVENT} a_event as k then
				if k.is_press then
					if k.code.is_escape or else (k.code.is_char and then (k.code.character = 'q' or k.code.character = 'Q')) then
						stop
					elseif k.code.is_char and then (k.code.character = 'r' or k.code.character = 'R') then
						trigger_fetch
					elseif not is_loading then
						if k.code.is_down or else (k.code.is_char and then k.code.character = 'j') then
							table_state.select_next (pull_requests.count)
						elseif k.code.is_up or else (k.code.is_char and then k.code.character = 'k') then
							table_state.select_previous (pull_requests.count)
						end
					end
				end
			end
		end

end
