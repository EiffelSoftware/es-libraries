note
	description: "[
		Tier 5 Advanced Example: Async Directory Scan (P2 A1; the plan's Q2 form).
		Real blocking work on a worker thread: a DIRECTORY_SCANNER walks a directory tree
		(the repository by default, a path argument otherwise) and finds its largest files
		and directories, while the main loop keeps drawing and reading keys.

		  * Progress: the worker posts a DIRECTORY_SCAN_PROGRESS at most every
		    `Progress_interval_ms' (directories, files, bytes, the current directory and the
		    root's entries done, shown by a TUI_GAUGE and a spinner), then one result or one
		    error, each a CUSTOM_EVENT through `post_event'.
		  * Cancel: Esc cancels the scan. The worker reads a shared flag, behind `scan_mutex',
		    between directories (and every few hundred entries of a large one) and stops,
		    posting nothing; a running thread is never stopped from outside.
		  * Generations: each scan has a number; r starts a new one, and an event from an
		    older scan (or a cancelled one) is dropped in `process'.
		  * Exit: quitting cancels every scan and joins the workers with a timeout, in
		    `stop_background_work' (P2 B2), so `run' returns once they have ended.
		  * Errors: a directory that cannot be read is counted, listed under the tables and
		    reported in a warning toast; a root that does not exist (or is not a directory)
		    gives the error state and an error toast.
		  * Not followed: symbolic links (counted). Left out by name: EIFGENs and .git (the
		    compiler's output is most of a working copy), unless `-all' is given.

		Arguments: `[-batch] [-all] [PATH]'. `-batch' scans, draws the result and quits
		(after `batch_limit_ms' at most, cancelling the scan), then prints a summary line. Any other
		argument starting with "-" prints `Usage' and exits with status 2, before `run'.
		Keys: r scans again, Esc cancels a running scan (else quits), q quits.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	EXAMPLE_ASYNC_SCAN

inherit
	TUI_APPLICATION
		redefine
			make,
			stop_background_work
		end

create
	make,
	make_on

feature {NONE} -- Initialization

	make
			-- Initialize and launch the scan example, with the arguments described above.
		local
			l_args: ARGUMENTS_32
			i: INTEGER
			l_root, l_bad: detachable STRING_32
			l_batch, l_all: BOOLEAN
		do
			create l_args
			from i := 1 until i > l_args.argument_count or l_bad /= Void loop
				if l_args.argument (i).same_string ("-batch") then
					l_batch := True
				elseif l_args.argument (i).same_string ("-all") then
					l_all := True
				elseif l_args.argument (i).starts_with ("-") then
					l_bad := {STRING_32} "unknown option '" + l_args.argument (i) + "'"
				elseif l_root /= Void then
					l_bad := {STRING_32} "only one directory can be scanned"
				elseif not l_args.argument (i).is_empty then
					l_root := l_args.argument (i)
				end
				i := i + 1
			end
			if attached l_root as r then
				init_scan_state (r)
			else
				init_scan_state (default_root)
			end
			Precursor
			if attached l_bad as l_message then
				io.error.put_string_32 ({STRING_32} "example_async_scan: " + l_message + "%N" + Usage + "%N")
				(create {EXCEPTIONS}).die (2)
			else
				if l_all then
					set_excluded_names (<<>>)
				end
				if l_batch then
					set_batch
				end
				set_tick_rate (50)
					-- The worker's agent targets Current: start it once TUI_APPLICATION is
					-- initialized (and `post_event` has a queue)
				start_scan
				run
				if l_batch then
					io.put_string_32 (summary + "%N")
				end
			end
		end

	Usage: STRING_32 = "[
		Usage: example_async_scan [-batch] [-all] [DIRECTORY]
		  DIRECTORY  the tree to scan (default: the repository, or the current directory)
		  -all       also scan directories named EIFGENs and .git
		  -batch     scan, draw the result, quit and print a summary
	]"
			-- What `make` prints for a bad argument

	make_on (a_terminal: TERMINAL [ANSI_TERMINAL_BACKEND]; a_root: READABLE_STRING_GENERAL)
			-- Initialize on `a_terminal` to scan `a_root`, without scanning or running (for tests).
		require
			terminal_attached: a_terminal /= Void
			root_not_empty: not a_root.is_empty
		do
			init_scan_state (a_root)
			make_with_terminal (a_terminal)
			set_tick_rate (50)
		ensure
			not_running: not is_running
			not_scanning: scan_generation = 0
		end

feature {NONE} -- Setup

	init_scan_state (a_root: READABLE_STRING_GENERAL)
			-- No scan yet, and no worker; `a_root` is the tree to scan.
		require
			root_not_empty: not a_root.is_empty
		do
			create scan_root.make_from_string_general (a_root)
			root_display_name := file_name (scan_root)
			create excluded_names.make_from_array (Default_excluded_names)
			create scan_mutex.make
			create scan_workers.make (2)
			create error_text.make_empty
			create directory_table_state.make
			create file_table_state.make
			create toasts.make_at (clock_ms)
			auto_exit_frames := -1
		end

	set_excluded_names (a_names: ARRAY [STRING_32])
			-- Leave out directories named as one of `a_names` from the next scans.
		do
			create excluded_names.make_from_array (a_names)
		end

	set_batch
			-- Quit once the first scan has ended, or `batch_limit_ms` from now.
		do
			is_batch := True
			batch_deadline_ms := {MONOTONIC_CLOCK}.milliseconds + batch_limit_ms
		ensure
			batch: is_batch
		end

	default_root: STRING_32
			-- The repository: the nearest of the current directory and its parents that holds
			-- eiffeltui.ecf, else the current directory
		local
			l_dir, l_parent: PATH
			i: INTEGER
			l_found: BOOLEAN
		do
			l_dir := (create {EXECUTION_ENVIRONMENT}).current_working_path.absolute_path.canonical_path
			Result := l_dir.name
			from i := 1 until l_found or i > 8 loop
				if (create {RAW_FILE}.make_with_path (l_dir.extended ("eiffeltui.ecf"))).exists then
					Result := l_dir.name
					l_found := True
				else
					l_parent := l_dir.parent
					if l_parent.same_as (l_dir) then
						i := 8
					end
					l_dir := l_parent
				end
				i := i + 1
			end
		ensure
			not_empty: not Result.is_empty
		end

feature -- Access

	scan_root: STRING_32
			-- The tree to scan

	root_display_name: STRING_32
			-- Last part of `scan_root`, for the title

	excluded_names: ARRAYED_LIST [STRING_32]
			-- Directories left out by name (EIFGENs and .git unless `-all`)

	scan_state: INTEGER
			-- `State_idle`, `State_scanning`, `State_done`, `State_cancelled` or `State_failed`

	progress: detachable DIRECTORY_SCAN_PROGRESS
			-- Last progress of the running scan

	last_result: detachable DIRECTORY_SCAN_RESULT
			-- Result of the last scan that ended

	error_text: STRING_32
			-- Why the last scan failed (empty unless `State_failed`)

	stale_events_dropped: INTEGER
			-- Scan events dropped by `process` because they came from an older or cancelled scan

	toasts: TOAST_QUEUE
			-- Error and warning toasts

	clock_ms: INTEGER_64
			-- The application's clock, for the toasts (a test redefines it)
		do
			Result := {MONOTONIC_CLOCK}.milliseconds
		end

	summary: STRING_32
			-- One line about the last scan (printed after a `-batch` run)
		do
			Result := {STRING_32} "example_async_scan: " + scan_root + ": "
			inspect scan_state
			when State_done then
				if attached last_result as r then
					Result.append (counts_text (r.directory_count, r.file_count, r.total_bytes))
					if r.problem_count > 0 then
						Result.append ({STRING_32} "; " + r.problem_count.out + " not read")
					end
					if not r.largest_files.is_empty then
						Result.append ({STRING_32} "; largest file " + r.largest_files.first.path +
							" (" + size_text (r.largest_files.first.bytes) + ")")
					end
				end
			when State_failed then
				Result.append ({STRING_32} "error: " + error_text)
			when State_cancelled then
				Result.append ({STRING_32} "cancelled")
			else
				Result.append ({STRING_32} "not finished")
			end
		end

	State_idle: INTEGER = 0
	State_scanning: INTEGER = 1
	State_done: INTEGER = 2
	State_cancelled: INTEGER = 3
	State_failed: INTEGER = 4
			-- Values of `scan_state`

	Default_excluded_names: ARRAY [STRING_32]
			-- Directories left out unless `-all`: the compiler's output and git's store
		once
			Result := <<{STRING_32} "EIFGENs", {STRING_32} ".git">>
		end

	batch_limit_ms: INTEGER_64
			-- Longest `-batch` run (a test redefines it)
		do
			Result := 60_000
		ensure
			positive: Result > 0
		end

	Kept_count: INTEGER = 10
			-- Largest files and directories kept

	Progress_interval_ms: INTEGER = 50
			-- Shortest time between two progress events of one scan

feature {NONE} -- State

	is_batch: BOOLEAN
			-- Quit once the first scan has ended?

	batch_deadline_ms: INTEGER_64
			-- When a `-batch` run quits, whatever the scan does ({MONOTONIC_CLOCK})

	auto_exit_frames: INTEGER
			-- Quit after this many frames (-1: never)

	frame_counter: INTEGER
			-- Frames drawn

	spinner_index: INTEGER
			-- Spinner glyph shown while scanning (1 .. 10)

	directory_table_state, file_table_state: TABLE_STATE
			-- States of the two tables (no selection)

feature {NONE} -- Scanning (P2 A1, on the B2 pattern)

	scan_generation: INTEGER
			-- Number of the latest scan; an event tagged with another number is stale.
			-- Written by the main thread only, under `scan_mutex` (workers read it)

	is_scan_cancelled: BOOLEAN
			-- Has the latest scan been cancelled (Esc, or the application is quitting)?
			-- Written by the main thread only, under `scan_mutex` (workers read it)

	scan_mutex: MUTEX
			-- Guards `scan_generation` and `is_scan_cancelled`, shared with the workers

	scan_workers: ARRAYED_LIST [WORKER_THREAD]
			-- Scan workers that may still be running (main thread only)

	Worker_join_timeout_ms: NATURAL_64 = 500
			-- Longest wait for each worker in `stop_background_work`

	Progress_token: STRING_8 = "scan_progress"
	Result_token: STRING_8 = "scan_result"
	Error_token: STRING_8 = "scan_error"
			-- Tokens of the CUSTOM_EVENT payloads posted by a scan worker, with the scan's
			-- generation and the data (see `new_scan_event`)

	start_scan
			-- Start a new scan of `scan_root` on a background worker thread. A scan still
			-- running becomes stale: its worker stops without posting, and an event it
			-- already posted is dropped by `process`.
		local
			l_worker: WORKER_THREAD
			l_generation: INTEGER
			l_excluded: ARRAYED_LIST [STRING_32]
		do
			forget_ended_workers
			scan_mutex.lock
			scan_generation := scan_generation + 1
			l_generation := scan_generation
			is_scan_cancelled := False
			scan_mutex.unlock
			scan_state := State_scanning
			progress := Void
			last_result := Void
			error_text.wipe_out
			spinner_index := 1
				-- The worker gets its own copies: nothing it reads is changed by this thread
			create l_excluded.make (excluded_names.count)
			across excluded_names as l_name loop
				l_excluded.extend (l_name.twin)
			end
			create l_worker.make (agent scan_worker_body (l_generation, scan_root.twin, l_excluded))
			scan_workers.extend (l_worker)
			l_worker.launch
		ensure
			new_generation: scan_generation = old scan_generation + 1
			scanning: scan_state = State_scanning
			worker_kept: scan_workers.count >= 1
		end

	cancel_scan
			-- Cancel the running scan: its worker stops at its next look at the flag and
			-- posts nothing.
		require
			scanning: scan_state = State_scanning
		do
			scan_mutex.lock
			is_scan_cancelled := True
			scan_mutex.unlock
			scan_state := State_cancelled
		ensure
			cancelled: is_scan_cancelled and scan_state = State_cancelled
		end

	scan_worker_body (a_generation: INTEGER; a_root: STRING_32; a_excluded: ARRAYED_LIST [STRING_32])
			-- Scan `a_root`, leaving out `a_excluded`, and post the progress, then the result or
			-- the error, each tagged with `a_generation`. Runs on the worker thread: stops,
			-- without posting, once the scan is stale or cancelled. An unexpected exception is
			-- posted as an error.
		local
			l_scanner: DIRECTORY_SCANNER
			l_failed: BOOLEAN
		do
			if not l_failed then
				l_scanner := new_scanner (a_root, a_excluded)
				l_scanner.scan (agent may_go_on (a_generation), agent post_progress (a_generation, ?), Progress_interval_ms)
				if l_scanner.has_error then
					if is_scan_wanted (a_generation) then
						post_event (new_scan_event (Error_token, a_generation, l_scanner.error_message))
					end
				elseif not l_scanner.is_cancelled and then is_scan_wanted (a_generation) then
					before_posting_result (a_generation)
					post_event (new_scan_event (Result_token, a_generation, l_scanner.scan_result))
				end
			elseif is_scan_wanted (a_generation) then
				post_event (new_scan_event (Error_token, a_generation, {STRING_32} "The scan stopped on an unexpected error"))
			end
		rescue
			if not l_failed then
				l_failed := True
				retry
			end
		end

	new_scanner (a_root: STRING_32; a_excluded: ARRAYED_LIST [STRING_32]): DIRECTORY_SCANNER
			-- A scanner of `a_root` leaving out `a_excluded` (called on the worker thread; a test
			-- redefines it)
		do
			create Result.make (a_root, a_excluded, Kept_count)
		end

	may_go_on (a_generation: INTEGER): BOOLEAN
			-- May scan `a_generation` go on? The scanner asks between directories, on the
			-- worker thread.
		do
			at_scan_step (a_generation)
			Result := is_scan_wanted (a_generation)
		end

	post_progress (a_generation: INTEGER; a_progress: DIRECTORY_SCAN_PROGRESS)
			-- Post `a_progress` of scan `a_generation`, unless it is stale or cancelled (worker
			-- thread).
		do
			if is_scan_wanted (a_generation) then
				post_event (new_scan_event (Progress_token, a_generation, a_progress))
			end
		end

	is_scan_wanted (a_generation: INTEGER): BOOLEAN
			-- Is scan `a_generation` the latest, and not cancelled? (Thread-safe.)
		do
			scan_mutex.lock
			Result := a_generation = scan_generation and not is_scan_cancelled
			scan_mutex.unlock
		end

	new_scan_event (a_token: STRING_8; a_generation: INTEGER; a_data: ANY): CUSTOM_EVENT
			-- Event carrying `a_data` of kind `a_token` for scan `a_generation`
		do
			create Result.make_with_payload ([a_token, a_generation, a_data])
		ensure
			tagged: attached {TUPLE [token: STRING_8; generation: INTEGER; data: ANY]} Result.payload as r
				and then r.generation = a_generation
		end

	at_scan_step (a_generation: INTEGER)
			-- Called by the worker of scan `a_generation` before it asks whether to go on.
			-- Nothing here; a test redefines it to hold the worker back.
		do
		end

	before_posting_result (a_generation: INTEGER)
			-- Called by the worker of scan `a_generation` after it has checked that its
			-- result is wanted, just before posting it. Nothing here; a test redefines it to
			-- hold the worker back while the scan becomes stale.
		do
		end

	forget_ended_workers
			-- Remove the workers that have ended from `scan_workers`.
		do
			from
				scan_workers.start
			until
				scan_workers.after
			loop
				if scan_workers.item.join_with_timeout (0) then
					scan_workers.remove
				else
					scan_workers.forth
				end
			end
		end

	worker_join_timed_out: BOOLEAN
			-- Did the last `stop_background_work` leave a worker running, because it did not
			-- end within `Worker_join_timeout_ms`? (It stays in `scan_workers`.)

	stop_background_work
			-- Cancel every scan and join its worker (at most `Worker_join_timeout_ms` each), so
			-- that `run` returns only once they have ended.
		local
			l_joined: BOOLEAN
		do
			scan_mutex.lock
			is_scan_cancelled := True
			scan_mutex.unlock
			l_joined := True
			across scan_workers as w loop
				l_joined := w.join_with_timeout (Worker_join_timeout_ms) and l_joined
			end
			worker_join_timed_out := not l_joined
			forget_ended_workers
		ensure then
			cancelled: is_scan_cancelled
			joined_unless_timed_out: not worker_join_timed_out implies scan_workers.is_empty
		end

feature {NONE} -- Application Hooks

	process (a_event: EVENT)
			-- Ticks turn the spinner and expire toasts; scan events update the state; r scans
			-- again, Esc cancels (or quits when nothing runs), q quits.
		do
			if a_event.is_tick then
				if scan_state = State_scanning then
					spinner_index := spinner_index \\ 10 + 1
				end
				toasts.expire (clock_ms.max (toasts.now_ms))
			elseif attached {CUSTOM_EVENT} a_event as c then
				process_scan_event (c)
			elseif attached {KEY_EVENT} a_event as k and then k.is_press then
				if k.code.is_escape then
					if scan_state = State_scanning then
						cancel_scan
					else
						stop
					end
				elseif k.code.is_char then
					inspect k.code.character
					when 'q', 'Q' then
						stop
					when 'r', 'R' then
						start_scan
					else
					end
				end
			end
		end

	process_scan_event (a_event: CUSTOM_EVENT)
			-- Apply a worker's event if it belongs to the running scan; drop it otherwise.
			-- `scan_generation` and `is_scan_cancelled` need no lock here: only this thread
			-- writes them.
		do
			if attached {TUPLE [token: STRING_8; generation: INTEGER; data: ANY]} a_event.payload as p then
				if p.generation /= scan_generation or is_scan_cancelled or scan_state /= State_scanning then
						-- From an older scan, or a cancelled one: stale
					stale_events_dropped := stale_events_dropped + 1
				elseif p.token.same_string (Progress_token) and then attached {DIRECTORY_SCAN_PROGRESS} p.data as l_progress then
					progress := l_progress
				elseif p.token.same_string (Result_token) and then attached {DIRECTORY_SCAN_RESULT} p.data as l_result then
					last_result := l_result
					scan_state := State_done
					if l_result.problem_count = 1 then
						toasts.push ({STRING_32} "1 directory could not be read", {TOAST_LEVEL}.warning, 5000)
					elseif l_result.problem_count > 1 then
						toasts.push (l_result.problem_count.out + " directories could not be read", {TOAST_LEVEL}.warning, 5000)
					end
				elseif p.token.same_string (Error_token) and then attached {READABLE_STRING_32} p.data as l_message then
					error_text := l_message.as_string_32.twin
					scan_state := State_failed
					toasts.push (error_text, {TOAST_LEVEL}.error, 8000)
				end
			end
		end

	render (a_frame: FRAME)
			-- Title, status, gauge (while scanning) or notes, the two tables, the directories
			-- not read, the keys; the toasts over the tables.
		local
			l_area, l_body: RECT
			l_width, l_height, l_problem_rows, l_body_height, l_half: INTEGER
			l_title_style: STYLE
		do
			if auto_exit_frames > 0 then
				frame_counter := frame_counter + 1
				if frame_counter >= auto_exit_frames then
					stop
				end
			end
			if is_batch and then (scan_state /= State_scanning or {MONOTONIC_CLOCK}.milliseconds >= batch_deadline_ms) then
				stop
			end
			l_area := a_frame.area
			l_width := l_area.width.to_integer_32
			l_height := l_area.height.to_integer_32
			if l_height >= 5 then
				create l_title_style.make_fg ({COLOR}.Bright_cyan)
				a_frame.render_widget ((create {TUI_PARAGRAPH}.make (create {TEXT}.make_styled ({STRING_32} "Disk usage of " + root_display_name,
					l_title_style.with_bold))).with_alignment ({TEXT_ALIGNMENT}.center), part (l_area, 0, 0, l_width, 1))
				a_frame.render_widget (create {TUI_PARAGRAPH}.make (create {TEXT}.make_raw (status_text)), part (l_area, 0, 1, l_width, 1))
				render_gauge_or_notes (a_frame, part (l_area, 0, 2, l_width, 1))

				if attached last_result as r and then r.problem_count > 0 then
					l_problem_rows := r.problems.count.min (Problem_rows) + 2
				end
				l_body_height := (l_height - 4 - l_problem_rows).max (0)
				l_body := part (l_area, 0, 3, l_width, l_body_height)
				if attached last_result as r then
					l_half := l_width // 2
					render_table (a_frame, " Largest directories ", "Directory", r.largest_directories,
						part (l_body, 0, 0, l_half, l_body_height), directory_table_state)
					render_table (a_frame, " Largest files ", "File", r.largest_files,
						part (l_body, l_half, 0, l_width - l_half, l_body_height), file_table_state)
					if l_problem_rows > 0 then
						render_problems (a_frame, r, part (l_area, 0, 3 + l_body_height, l_width, l_problem_rows))
					end
				else
					a_frame.render_widget ((create {TUI_PARAGRAPH}.make (create {TEXT}.make_styled (body_text, create {STYLE}.make_fg ({COLOR}.Dark_gray))))
						.with_alignment ({TEXT_ALIGNMENT}.center), part (l_body, 0, l_body_height // 2, l_width, 1))
				end
				a_frame.render_widget (create {TUI_PARAGRAPH}.make (create {TEXT}.make_styled (
					"r: scan again  Esc: cancel  q: quit", create {STYLE}.make_fg ({COLOR}.Dark_gray))), part (l_area, 0, l_height - 1, l_width, 1))
				a_frame.render_stateful_widget ((create {TUI_TOAST}).with_position ({TOAST_POSITION}.bottom_right).with_max_width (36), l_body, toasts)
			end
		end

feature {NONE} -- Drawing

	Problem_rows: INTEGER = 3
			-- Most directories listed under the tables

	status_text: STRING_32
			-- The status line
		do
			inspect scan_state
			when State_scanning then
				Result := spinner_char (spinner_index) + {STRING_32} " Scanning: "
				if attached progress as p then
					Result.append (counts_text (p.directory_count, p.file_count, p.total_bytes))
				else
					Result.append ({STRING_32} "starting")
				end
			when State_done then
				if attached last_result as r then
					Result := {STRING_32} "Scanned " + counts_text (r.directory_count, r.file_count, r.total_bytes)
				else
					create Result.make_empty
				end
			when State_cancelled then
				Result := {STRING_32} "Scan cancelled"
			when State_failed then
				Result := {STRING_32} "Error: " + error_text
			else
				Result := {STRING_32} "No scan yet"
			end
		end

	body_text: STRING_32
			-- What the body shows when there is no result
		do
			inspect scan_state
			when State_scanning then
				if attached progress as p and then not p.current_path.is_empty then
					Result := {STRING_32} "In " + p.current_path
				else
					Result := {STRING_32} "Scanning " + root_display_name + " on a worker thread..."
				end
			when State_cancelled then
				Result := {STRING_32} "Cancelled: press r to scan again"
			when State_failed then
				Result := {STRING_32} "Nothing scanned: press r to try again"
			else
				Result := {STRING_32} "Press r to scan"
			end
		end

	render_gauge_or_notes (a_frame: FRAME; a_area: RECT)
			-- While scanning, a gauge of the root's entries done; after a scan, what was left
			-- out.
		local
			l_gauge: TUI_GAUGE
			l_text: STRING_32
			i: INTEGER
		do
			if scan_state = State_scanning then
				create l_gauge.make
				l_gauge := l_gauge.with_gauge_style (create {STYLE}.make_fg ({COLOR}.Green))
				if attached progress as p and then p.top_total > 0 then
					l_gauge := l_gauge.with_ratio (p.ratio).with_label (p.top_done.out + " / " + p.top_total.out + " entries")
				else
					l_gauge := l_gauge.with_ratio (0.0).with_label ("listing")
				end
				a_frame.render_widget (l_gauge, a_area)
			elseif scan_state = State_done and then attached last_result as r then
				l_text := {STRING_32} "Links not followed: " + r.link_count.out + "  Left out: " + r.excluded_count.out
				if not excluded_names.is_empty then
					l_text.append ({STRING_32} " (")
					from i := 1 until i > excluded_names.count loop
						if i > 1 then
							l_text.append ({STRING_32} ", ")
						end
						l_text.append (excluded_names [i])
						i := i + 1
					end
					l_text.append ({STRING_32} ")")
				end
				a_frame.render_widget (create {TUI_PARAGRAPH}.make (create {TEXT}.make_styled (l_text, create {STYLE}.make_fg ({COLOR}.Dark_gray))), a_area)
			end
		end

	render_table (a_frame: FRAME; a_title, a_column: STRING_32; a_entries: LIST [TUPLE [path: STRING_32; bytes: INTEGER_64]]; a_area: RECT; a_state: TABLE_STATE)
			-- A table titled `a_title` of `a_entries`: size (right-aligned) and path.
		local
			l_rows: ARRAYED_LIST [TABLE_ROW]
			l_header: TABLE_ROW
			l_block: TUI_BLOCK
			l_header_style: STYLE
		do
			create l_rows.make (a_entries.count)
			across a_entries as e loop
				l_rows.extend (create {TABLE_ROW}.make (<<
					(create {TABLE_CELL}.make_raw (size_text (e.bytes))).with_alignment ({TEXT_ALIGNMENT}.right),
					create {TABLE_CELL}.make_raw (e.path)>>))
			end
			create l_header_style.make_fg ({COLOR}.Bright_yellow)
			create l_header.make (<<
				(create {TABLE_CELL}.make_raw ("Size")).with_alignment ({TEXT_ALIGNMENT}.right),
				create {TABLE_CELL}.make_raw (a_column)>>)
			l_header := l_header.with_style (l_header_style.with_bold)
			create l_block.make
			l_block := l_block.with_borders ({BORDERS}.all_borders).with_border_style (create {STYLE}.make_fg ({COLOR}.Bright_blue)).with_title (a_title)
			a_frame.render_stateful_widget ((create {TUI_TABLE}.make (l_rows, << {CONSTRAINTS}.fixed (9), {CONSTRAINTS}.flex (1) >>))
				.with_header (l_header).with_block (l_block), a_area, a_state)
		end

	render_problems (a_frame: FRAME; a_result: DIRECTORY_SCAN_RESULT; a_area: RECT)
			-- The first directories not scanned, with why, in a box.
		local
			l_lines: ARRAYED_LIST [TEXT_LINE]
			l_block: TUI_BLOCK
			i, l_shown: INTEGER
		do
			l_shown := a_result.problems.count.min (Problem_rows)
			create l_lines.make (l_shown)
			from i := 1 until i > l_shown loop
				if i = l_shown and a_result.problem_count > l_shown then
					l_lines.extend (create {TEXT_LINE}.make_raw ({STRING_32} "... and " + (a_result.problem_count - l_shown + 1).out + " more"))
				else
					l_lines.extend (create {TEXT_LINE}.make_raw (a_result.problems [i].path + {STRING_32} ": " + a_result.problems [i].reason))
				end
				i := i + 1
			end
			create l_block.make
			l_block := l_block.with_borders ({BORDERS}.all_borders).with_border_style (create {STYLE}.make_fg ({COLOR}.Yellow))
				.with_title ({STRING_32} " Not read (" + a_result.problem_count.out + ") ")
			a_frame.render_widget ((create {TUI_PARAGRAPH}.make (create {TEXT}.make (l_lines))).with_block (l_block), a_area)
		end

	counts_text (a_directories, a_files: INTEGER; a_bytes: INTEGER_64): STRING_32
			-- "5 directories, 6 files, 13.1 KiB"
		do
			Result := a_directories.out.to_string_32 + plural (" director", a_directories, "y", "ies") + {STRING_32} ", " +
				a_files.out.to_string_32 + plural (" file", a_files, "", "s") + {STRING_32} ", " + size_text (a_bytes)
		end

	plural (a_stem: STRING_32; a_count: INTEGER; a_one, a_many: STRING_32): STRING_32
			-- `a_stem` with `a_one` when `a_count` is 1, else with `a_many`
		do
			if a_count = 1 then
				Result := a_stem + a_one
			else
				Result := a_stem + a_many
			end
		end

	spinner_char (a_index: INTEGER): STRING_32
			-- Braille spinner glyph `a_index` (1 .. 10), as EXAMPLE_ASYNC_GITHUB's
		do
			create Result.make_filled ((0x280B).to_character_32, 1)
			inspect a_index
			when 2 then Result.put_code (10265, 1)
			when 3 then Result.put_code (10269, 1)
			when 4 then Result.put_code (10296, 1)
			when 5 then Result.put_code (10292, 1)
			when 6 then Result.put_code (10294, 1)
			when 7 then Result.put_code (10278, 1)
			when 8 then Result.put_code (10279, 1)
			when 9 then Result.put_code (10247, 1)
			when 10 then Result.put_code (10255, 1)
			else
			end
		end

feature -- Formatting

	size_text (a_bytes: INTEGER_64): STRING_32
			-- `a_bytes` for people: "700 B", "4.9 KiB", "1.2 MiB" (binary units, one decimal,
			-- rounded half up)
		require
			not_negative: a_bytes >= 0
		local
			l_unit: INTEGER_64
			l_whole, l_tenths: INTEGER_64
			l_names: ARRAY [STRING_32]
			i: INTEGER
		do
			if a_bytes < 1024 then
				Result := a_bytes.out.to_string_32 + {STRING_32} " B"
			else
				l_names := <<{STRING_32} "KiB", {STRING_32} "MiB", {STRING_32} "GiB", {STRING_32} "TiB", {STRING_32} "PiB">>
				from
					l_unit := 1024
					i := 1
				until
					i = l_names.count or else a_bytes // l_unit < 1024
				loop
					l_unit := l_unit * 1024
					i := i + 1
				end
				l_whole := a_bytes // l_unit
				l_tenths := ((a_bytes \\ l_unit) * 10 + l_unit // 2) // l_unit
				if l_tenths = 10 then
					l_whole := l_whole + 1
					l_tenths := 0
				end
				if l_whole = 1024 and i < l_names.count then
						-- Rounded up to the next unit: 1048575 bytes is "1.0 MiB", not "1024.0 KiB"
					l_whole := 1
					i := i + 1
				end
				Result := l_whole.out.to_string_32 + {STRING_32} "." + l_tenths.out.to_string_32 + {STRING_32} " " + l_names [i]
			end
		end

feature {NONE} -- Implementation

	file_name (a_path: READABLE_STRING_GENERAL): STRING_32
			-- The last part of `a_path` once made absolute, or the whole path
		local
			l_path: PATH
		do
			l_path := (create {PATH}.make_from_string (a_path)).absolute_path.canonical_path
			if attached l_path.entry as l_entry then
				Result := l_entry.name
			else
				Result := l_path.name
			end
		end

	part (a_parent: RECT; a_dx, a_dy, a_width, a_height: INTEGER): RECT
			-- The rectangle `a_width` x `a_height` at (`a_dx`, `a_dy`) inside `a_parent`, cut to it
		do
			if a_dx < 0 or a_dy < 0 or a_dx >= a_parent.width.to_integer_32 or a_dy >= a_parent.height.to_integer_32
				or a_width <= 0 or a_height <= 0
			then
				create Result.make (a_parent.x, a_parent.y, 0, 0)
			else
				create Result.make (a_parent.x + a_dx.to_natural_16, a_parent.y + a_dy.to_natural_16,
					a_width.min (a_parent.width.to_integer_32 - a_dx).to_natural_16,
					a_height.min (a_parent.height.to_integer_32 - a_dy).to_natural_16)
			end
		ensure
			inside: Result.is_empty or else a_parent.contains_rect (Result)
		end

invariant
	valid_state: State_idle <= scan_state and scan_state <= State_failed
	failed_has_message: scan_state = State_failed implies not error_text.is_empty

end
