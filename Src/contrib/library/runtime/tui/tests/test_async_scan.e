note
	description: "[
		P2 item A1 (review/p2_terminal_widgets_plan.md): EXAMPLE_ASYNC_SCAN, a directory scan
		on a worker thread. DIRECTORY_SCANNER on a tree of known sizes; the example run in
		batch mode to a row-exact snapshot; progress at most every 50 ms; Esc cancels; a
		refresh drops the older scan's result; quitting joins the worker within its timeout,
		or gives up after it.

		Trees: each test makes its own under the directory named by TEMP, TMP or TMPDIR
		(else the current directory), named eiffeltui_a1_*, and deletes it. A directory
		named "locked" is unreadable through LOCKED_DIRECTORY_SCANNER on every platform. The
		real case is checked on POSIX (mode 000) when the tests do not run as root (root may
		read it anyway, as in the Docker image), and on Windows (listing denied with
		`icacls'); the links and a 5 GiB sparse file only where they can be made (`ln -s',
		`truncate' on POSIX; `mklink /J', `fsutil' on Windows).

		Waits: every wait is bounded (`Wait_limit_ms'), and a held worker leaves its gate
		after ASYNC_SCAN_TEST_APP.Gate_limit_ms at the latest, so no test can hang.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_ASYNC_SCAN

inherit
	BUFFER_TEST_HELPER

feature -- Scanner

	test_scanner_finds_largest
			-- The tree's counts and its three largest files and directories (equal sizes by
			-- path); "locked" is listed as not read, EIFGENs is left out.
		local
			l_root: STRING_32
			l_scanner: DIRECTORY_SCANNER
			r: DIRECTORY_SCAN_RESULT
		do
			l_root := new_tree ("scanner")
			create {LOCKED_DIRECTORY_SCANNER} l_scanner.make (l_root, Excluded, 3)
			l_scanner.scan (agent: BOOLEAN do Result := True end, agent (p: DIRECTORY_SCAN_PROGRESS) do end, 50)
			r := l_scanner.scan_result
			assert ("scanned", l_scanner.is_scanned and not l_scanner.has_error and not l_scanner.is_cancelled)
			assert ("root name", r.root_name.same_string ("eiffeltui_a1_scanner"))
			assert ("directories " + r.directory_count.out, r.directory_count = 5)
			assert ("files " + r.file_count.out, r.file_count = 7)
			assert ("bytes " + r.total_bytes.out, r.total_bytes = 14148)
			assert ("EIFGENs left out", r.excluded_count = 1)
			assert ("no links", r.link_count = 0)
			assert ("locked not read", r.problem_count = 1 and r.problems.count = 1 and then
				(r.problems [1].path.same_string ("locked") and r.problems [1].reason.same_string ("cannot be read")))
			assert_largest ("files", r.largest_files, <<["big.bin", 5000], ["src/main.e", 3000], ["src/deep/core.e", 2048]>>)
			assert_largest ("directories", r.largest_directories, <<["src", 5748], ["docs", 2200], ["src/deep", 2048]>>)
				-- Keeping ten: the two 700-byte files by path, the empty directory last
			create {LOCKED_DIRECTORY_SCANNER} l_scanner.make (l_root, Excluded, 10)
			l_scanner.scan (agent: BOOLEAN do Result := True end, agent (p: DIRECTORY_SCAN_PROGRESS) do end, 50)
			assert_largest ("all files", l_scanner.scan_result.largest_files, <<["big.bin", 5000], ["src/main.e", 3000],
				["src/deep/core.e", 2048], ["docs/guide.md", 1500], ["notes.txt", 1200], ["docs/todo.txt", 700], ["src/util.e", 700]>>)
			assert_largest ("all directories", l_scanner.scan_result.largest_directories,
				<<["src", 5748], ["docs", 2200], ["src/deep", 2048], ["empty", 0]>>)
				-- Nothing left out: EIFGENs is scanned and is the largest directory
			create {LOCKED_DIRECTORY_SCANNER} l_scanner.make (l_root, create {ARRAY [STRING]}.make_empty, 1)
			l_scanner.scan (agent: BOOLEAN do Result := True end, agent (p: DIRECTORY_SCAN_PROGRESS) do end, 50)
			assert ("EIFGENs scanned", l_scanner.scan_result.excluded_count = 0 and l_scanner.scan_result.file_count = 8)
			assert_largest ("EIFGENs largest", l_scanner.scan_result.largest_directories, <<["EIFGENs", 9999]>>)
			remove_tree (l_root)
		end

	test_scanner_cancel_and_errors
			-- The `go_on` query stops the walk; a missing root and a file as the root are
			-- errors, not exceptions.
		local
			l_root: STRING_32
			l_scanner: DIRECTORY_SCANNER
			l_calls: CELL [INTEGER]
		do
			l_root := new_tree ("cancel")
			create l_calls.put (0)
			create l_scanner.make (l_root, Excluded, 3)
			l_scanner.scan (agent (a_calls: CELL [INTEGER]): BOOLEAN
					do
						a_calls.put (a_calls.item + 1)
						Result := a_calls.item <= 2
					end (l_calls),
				agent (p: DIRECTORY_SCAN_PROGRESS) do end, 50)
			assert ("cancelled", l_scanner.is_cancelled and not l_scanner.has_error)
			assert ("asked three times", l_calls.item = 3)
			assert ("stopped early", l_scanner.scan_result.directory_count < 5)
				-- Cancelled before the root
			create l_scanner.make (l_root, Excluded, 3)
			l_scanner.scan (agent: BOOLEAN do Result := False end, agent (p: DIRECTORY_SCAN_PROGRESS) do end, 50)
			assert ("cancelled at once", l_scanner.is_cancelled and l_scanner.scan_result.directory_count = 0)
				-- Errors
			create l_scanner.make (l_root + {STRING_32} "/no_such_directory", Excluded, 3)
			l_scanner.scan (agent: BOOLEAN do Result := True end, agent (p: DIRECTORY_SCAN_PROGRESS) do end, 50)
			assert ("missing: error", l_scanner.has_error and not l_scanner.is_cancelled)
			assert ("missing: message", l_scanner.error_message.has_substring ("No such directory"))
			create l_scanner.make (l_root + {STRING_32} "/big.bin", Excluded, 3)
			l_scanner.scan (agent: BOOLEAN do Result := True end, agent (p: DIRECTORY_SCAN_PROGRESS) do end, 50)
			assert ("file: error", l_scanner.has_error and l_scanner.error_message.has_substring ("Not a directory"))
			remove_tree (l_root)
		end

	test_unreadable_directory_posix
			-- A directory with mode 000 is listed as not read, and the walk goes on. Only on
			-- POSIX, and only when the process cannot read it anyway (not as root).
		local
			l_root: STRING_32
			l_scanner: DIRECTORY_SCANNER
			l_dir: RAW_FILE
			l_info: FILE_INFO
		do
			if not {PLATFORM}.is_windows then
				l_root := new_tree ("unreadable")
				create l_dir.make_with_name (l_root + {STRING_32} "/locked")
				l_dir.change_mode (0c000)
				create l_info.make
				l_info.update (l_dir.path.name)
				if not l_info.is_readable then
					create l_scanner.make (l_root, Excluded, 3)
					l_scanner.scan (agent: BOOLEAN do Result := True end, agent (p: DIRECTORY_SCAN_PROGRESS) do end, 50)
					assert ("not fatal", not l_scanner.has_error and not l_scanner.is_cancelled)
					assert ("listed", l_scanner.scan_result.problem_count = 1 and then
						l_scanner.scan_result.problems [1].path.same_string ("locked"))
					assert ("the rest counted", l_scanner.scan_result.file_count = 7 and l_scanner.scan_result.total_bytes = 14148)
				end
				l_dir.change_mode (0c755)
				remove_tree (l_root)
			end
		end

	test_unreadable_directory_windows
			-- A directory whose listing is denied to this user (`icacls /deny`) is listed as
			-- not read, and the walk goes on: `base` alone would list it as an empty
			-- directory. Only on Windows, and only if the right can be denied.
		local
			l_root, l_locked: STRING_32
			l_scanner: DIRECTORY_SCANNER
			l_denied, l_restored: BOOLEAN
		do
			if {PLATFORM}.is_windows then
				l_root := new_tree ("denied")
				l_locked := windows_name (l_root + {STRING_32} "/locked")
				l_denied := system ({STRING_32} "icacls %"" + l_locked + "%" /deny %"%%USERNAME%%:(RD)%" >NUL")
				if l_denied then
					create l_scanner.make (l_root, Excluded, 3)
					l_scanner.scan (agent: BOOLEAN do Result := True end, agent (p: DIRECTORY_SCAN_PROGRESS) do end, 50)
						-- Give the right back before any assertion, so that the tree can be deleted
					l_restored := system ({STRING_32} "icacls %"" + l_locked + "%" /remove:d %"%%USERNAME%%%" >NUL")
					assert ("right restored", l_restored)
					assert ("not fatal", not l_scanner.has_error and not l_scanner.is_cancelled)
					assert ("listed " + l_scanner.scan_result.problem_count.out, l_scanner.scan_result.problem_count = 1 and then
						(l_scanner.scan_result.problems [1].path.same_string ("locked") and
						l_scanner.scan_result.problems [1].reason.same_string ("cannot be read")))
					assert ("the rest counted", l_scanner.scan_result.file_count = 7 and l_scanner.scan_result.total_bytes = 14148)
				end
				remove_tree (l_root)
			end
		end

	test_size_above_4_gib
			-- A 5 GiB sparse file is counted as 5 GiB, not as its size modulo 2^32 (1 GiB),
			-- which is what FILE_INFO.size gives. Skipped where the file cannot be made.
		local
			l_root, l_file: STRING_32
			l_scanner: DIRECTORY_SCANNER
			l_made: BOOLEAN
		do
			l_root := new_empty_tree ("large")
			l_file := l_root + {STRING_32} "/sparse.bin"
			if {PLATFORM}.is_windows then
				l_file := windows_name (l_file)
				l_made := system ({STRING_32} "type NUL >%"" + l_file + "%" && fsutil sparse setflag %"" + l_file +
					"%" >NUL && fsutil file seteof %"" + l_file + "%" 5368709120 >NUL")
			else
				l_made := system ({STRING_32} "truncate -s 5368709120 '" + l_file + "'")
			end
			if l_made then
				create l_scanner.make (l_root, Excluded, 3)
				l_scanner.scan (agent: BOOLEAN do Result := True end, agent (p: DIRECTORY_SCAN_PROGRESS) do end, 50)
				assert ("one file", l_scanner.scan_result.file_count = 1)
				assert ("5 GiB: " + l_scanner.scan_result.total_bytes.out, l_scanner.scan_result.total_bytes = 5368709120)
				assert ("largest", l_scanner.scan_result.largest_files.first.bytes = 5368709120)
			end
			remove_tree (l_root)
		end

	test_links_not_followed
			-- A link to the root (a loop) and a link to a file are counted as links, not
			-- followed: the counts are those of the tree without them. With `ln -s` on POSIX,
			-- a junction (`mklink /J`) on Windows; skipped where the link cannot be made.
		local
			l_root: STRING_32
			l_scanner: DIRECTORY_SCANNER
			l_loop: STRING_32
			l_made: BOOLEAN
		do
			l_root := new_tree ("links")
			l_loop := l_root + {STRING_32} "/src/loop"
			if {PLATFORM}.is_windows then
				l_made := system ({STRING_32} "mklink /J %"" + windows_name (l_loop) + "%" %"" + windows_name (l_root) + "%" >NUL")
			else
				l_made := system ({STRING_32} "ln -s .. '" + l_loop + "'") and
					system ({STRING_32} "ln -s ../big.bin '" + l_root + "/docs/big_link'")
			end
			if l_made then
				create {LOCKED_DIRECTORY_SCANNER} l_scanner.make (l_root, Excluded, 3)
				l_scanner.scan (agent: BOOLEAN do Result := True end, agent (p: DIRECTORY_SCAN_PROGRESS) do end, 50)
				assert ("not fatal", not l_scanner.has_error and not l_scanner.is_cancelled)
				if {PLATFORM}.is_windows then
					assert ("one link " + l_scanner.scan_result.link_count.out, l_scanner.scan_result.link_count = 1)
				else
					assert ("two links " + l_scanner.scan_result.link_count.out, l_scanner.scan_result.link_count = 2)
				end
				assert ("not followed: directories " + l_scanner.scan_result.directory_count.out, l_scanner.scan_result.directory_count = 5)
				assert ("not followed: files " + l_scanner.scan_result.file_count.out, l_scanner.scan_result.file_count = 7)
				assert ("not followed: bytes", l_scanner.scan_result.total_bytes = 14148)
				assert ("only locked not read", l_scanner.scan_result.problem_count = 1)
			end
			if {PLATFORM}.is_windows then
					-- Remove the junction itself first: deleting the tree must not go through it
				l_made := system ({STRING_32} "rmdir %"" + windows_name (l_loop) + "%" 2>NUL")
			end
			remove_tree (l_root)
		end

	test_size_text
			-- Sizes for people: bytes below 1 KiB, then one decimal, rounded half up, moving
			-- to the next unit when rounding reaches 1024.
		local
			l_app: ASYNC_SCAN_TEST_APP
		do
			l_app := new_app ("unused")
			assert ("0", l_app.size_text (0).same_string ("0 B"))
			assert ("1023", l_app.size_text (1023).same_string ("1023 B"))
			assert ("1024", l_app.size_text (1024).same_string ("1.0 KiB"))
			assert ("1075", l_app.size_text (1075).same_string ("1.0 KiB"))
			assert ("1076", l_app.size_text (1076).same_string ("1.1 KiB"))
			assert ("5000", l_app.size_text (5000).same_string ("4.9 KiB"))
			assert ("1048575", l_app.size_text (1048575).same_string ("1.0 MiB"))
			assert ("1.5 GiB", l_app.size_text (1610612736).same_string ("1.5 GiB"))
			assert ("2 TiB", l_app.size_text (2199023255552).same_string ("2.0 TiB"))
		end

feature -- Example

	test_batch_scan_snapshot
			-- The example in batch mode on the test tree: `run` returns once the result is
			-- drawn; the final 72 x 20 frame, row-exact, with the two tables, the directory not
			-- read and its warning toast.
		local
			l_root: STRING_32
			l_app: ASYNC_SCAN_TEST_APP
			l_buf: BUFFER
		do
			l_root := new_tree ("batch")
			l_app := new_app (l_root)
			l_app.set_simulates_locked (True)
			l_app.set_batch_now
			l_app.start_scan_now
			l_app.run
			assert ("done", l_app.scan_state = l_app.State_done)
			assert ("worker joined", l_app.running_worker_count = 0 and not l_app.is_worker_join_timed_out)
			assert ("nothing dropped", l_app.stale_events_dropped = 0)
			assert ("warning toast", l_app.toasts.count = 1 and then l_app.toasts.item (1).level = {TOAST_LEVEL}.warning)
			create l_buf.make (72, 20)
			l_app.render_now (create {FRAME}.make (l_buf))
			assert_buffer_lines ("batch", l_buf, batch_rows)
			assert_cell_style ("header", l_buf, 4, 5, (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold)
			assert ("consistent", l_buf.is_consistent)
			remove_tree (l_root)
		end

	test_missing_path_is_error
			-- A root that does not exist: the error state, its message on the status line and
			-- in an error toast; nothing scanned.
		local
			l_root: STRING_32
			l_app: ASYNC_SCAN_TEST_APP
			l_buf: BUFFER
		do
			l_root := temp_directory + {STRING_32} "/eiffeltui_a1_no_such_directory"
			l_app := new_app (l_root)
			l_app.set_batch_now
			l_app.start_scan_now
			l_app.run
			assert ("failed", l_app.scan_state = l_app.State_failed and l_app.last_result = Void)
			assert ("message", l_app.error_text.has_substring ("No such directory") and l_app.error_text.has_substring ("eiffeltui_a1_no_such_directory"))
			assert ("error toast", l_app.toasts.count = 1 and then l_app.toasts.item (1).level = {TOAST_LEVEL}.error)
			create l_buf.make (72, 20)
			l_app.render_now (create {FRAME}.make (l_buf))
			assert ("status line", buffer_row_as_string (l_buf, 1).starts_with ("Error: No such directory: "))
			assert ("body", buffer_row_as_string (l_buf, 11).has_substring ("Nothing scanned: press r to try again"))
			assert ("worker joined", l_app.running_worker_count = 0)
		end

	test_progress_at_most_every_50_ms
			-- A slow scan (31 directories, at least 4 ms each) posts progress events at least
			-- 50 ms apart, then its result; the progress is shown while scanning.
		local
			l_root: STRING_32
			l_app: ASYNC_SCAN_TEST_APP
			l_events: ARRAYED_LIST [EVENT]
			l_progress_count, l_result_count: INTEGER
			l_last_time: INTEGER_64
			l_spaced: BOOLEAN
			i: INTEGER
		do
			l_root := new_empty_tree ("progress")
			from i := 1 until i > 30 loop
				make_directory (l_root + {STRING_32} "/d" + i.out)
				i := i + 1
			end
			l_app := new_app (l_root)
			l_app.set_step_delay (4)
			l_app.start_scan_now
			assert ("worker ended", wait_until (agent finished_at_least (l_app, 1)))
			l_events := l_app.taken_events
			l_spaced := True
			l_last_time := {INTEGER_64}.min_value
			across l_events as e loop
				if attached {CUSTOM_EVENT} e as c and then attached {TUPLE [token: STRING_8; generation: INTEGER; data: ANY]} c.payload as p then
					assert ("generation 1", p.generation = 1)
					if attached {DIRECTORY_SCAN_PROGRESS} p.data as l_progress then
						assert ("progress before the result", l_result_count = 0)
						l_progress_count := l_progress_count + 1
						if l_last_time /= {INTEGER_64}.min_value and then l_progress.time_ms - l_last_time < 50 then
							l_spaced := False
						end
						l_last_time := l_progress.time_ms
						l_app.process_now (c)
						assert ("progress shown", l_app.progress = l_progress and l_app.scan_state = l_app.State_scanning)
					elseif attached {DIRECTORY_SCAN_RESULT} p.data then
						l_result_count := l_result_count + 1
						l_app.process_now (c)
					end
				end
			end
			assert ("some progress", l_progress_count >= 1)
			assert ("at least 50 ms apart", l_spaced)
			assert ("one result", l_result_count = 1)
			assert ("done", l_app.scan_state = l_app.State_done and then attached l_app.last_result as r and then r.directory_count = 31)
			l_app.stop_background_work_now
			remove_tree (l_root)
		end

	test_cancel_during_scan
			-- Esc while the worker is held at a step: the scan is cancelled at once, the worker
			-- stops at its next look and posts no result; r then scans again to the end.
		local
			l_root: STRING_32
			l_app: ASYNC_SCAN_TEST_APP
		do
			l_root := new_tree ("cancel_app")
			l_app := new_app (l_root)
			l_app.hold_at_step (1, False)
			l_app.start_scan_now
			assert ("held", wait_until (agent l_app.is_held))
			l_app.process_now (create {KEY_EVENT}.make_special ({KEY_CODE}.Escape))
			assert ("cancelled", l_app.scan_state = l_app.State_cancelled and l_app.is_cancelled_now)
			assert ("worker stopped", wait_until (agent finished_at_least (l_app, 1)))
			assert ("no result posted", not has_scan_data (l_app.taken_events, 1, {DIRECTORY_SCAN_RESULT}))
			assert ("nothing shown", l_app.last_result = Void)
				-- Esc again, with nothing running, would quit; r scans again instead (with no
				-- LOCKED_DIRECTORY_SCANNER here, so "locked" is read: 8 files)
			l_app.process_now (create {KEY_EVENT}.make_char ('r'))
			assert ("second scan", l_app.generation = 2 and l_app.scan_state = l_app.State_scanning and not l_app.is_cancelled_now)
			assert ("second worker ended", wait_until (agent finished_at_least (l_app, 2)))
			across l_app.taken_events as e loop
				l_app.process_now (e)
			end
			assert ("done", l_app.scan_state = l_app.State_done and then attached l_app.last_result as r and then r.file_count = 8)
			l_app.stop_background_work_now
			assert ("joined", l_app.running_worker_count = 0 and not l_app.is_worker_join_timed_out)
			remove_tree (l_root)
		end

	test_refresh_drops_old_result
			-- The first scan's worker is held after it has checked that its result is wanted;
			-- r starts a second scan, which ends; the first worker is then released and posts
			-- its result, now stale. Processed before the second scan's events, as if it came
			-- first, it is dropped and the second scan goes on; then the second result is shown.
		local
			l_root: STRING_32
			l_app: ASYNC_SCAN_TEST_APP
			l_events: ARRAYED_LIST [EVENT]
			l_first, l_second: detachable DIRECTORY_SCAN_RESULT
			l_first_event: detachable CUSTOM_EVENT
		do
			l_root := new_tree ("refresh")
			l_app := new_app (l_root)
			l_app.hold_before_result (1)
			l_app.start_scan_now
			assert ("first held", wait_until (agent l_app.is_held))
			l_app.process_now (create {KEY_EVENT}.make_char ('r'))
			assert ("second scan", l_app.generation = 2)
			assert ("second worker ended", wait_until (agent finished_at_least (l_app, 1)))
			l_app.release
			assert ("first worker ended", wait_until (agent finished_at_least (l_app, 2)))
			l_events := l_app.taken_events
			across l_events as e loop
				if attached {CUSTOM_EVENT} e as c and then attached {TUPLE [token: STRING_8; generation: INTEGER; data: ANY]} c.payload as p
					and then attached {DIRECTORY_SCAN_RESULT} p.data as r
				then
					if p.generation = 1 then
						l_first := r
						l_first_event := c
					elseif p.generation = 2 then
						l_second := r
					end
				end
			end
			assert ("stale result posted", l_first /= Void)
			assert ("latest result posted", l_second /= Void)
				-- The stale result first, as when it arrives while the second scan still runs:
				-- dropped, the second scan goes on
			if attached l_first_event as l_stale then
				l_app.process_now (l_stale)
				l_events.prune_all (l_stale)
			end
			assert ("stale result dropped", l_app.stale_events_dropped = 1)
			assert ("still scanning", l_app.scan_state = l_app.State_scanning and l_app.last_result = Void)
			across l_events as e loop
				l_app.process_now (e)
			end
			assert ("latest result shown", l_app.scan_state = l_app.State_done and l_app.last_result = l_second)
			l_app.stop_background_work_now
			assert ("joined", l_app.running_worker_count = 0 and not l_app.is_worker_join_timed_out)
			remove_tree (l_root)
		end

	test_batch_gives_up_after_limit
			-- A batch run whose scan does not end (the worker held) quits after its time
			-- limit: the scan is cancelled and its worker joined; the summary says so.
		local
			l_root: STRING_32
			l_app: ASYNC_SCAN_TEST_APP
			l_start, l_elapsed: INTEGER_64
		do
			l_root := new_tree ("batch_limit")
			l_app := new_app (l_root)
			l_app.hold_at_step (1, False)
			l_app.set_batch_limit_ms (200)
			l_start := {MONOTONIC_CLOCK}.milliseconds
			l_app.set_batch_now
			l_app.start_scan_now
			l_app.run
			l_elapsed := {MONOTONIC_CLOCK}.milliseconds - l_start
			assert ("waited the limit: " + l_elapsed.out + " ms", l_elapsed >= 200)
			assert ("returned in " + l_elapsed.out + " ms", l_elapsed < Wait_limit_ms)
			assert ("not finished", l_app.scan_state = l_app.State_scanning and l_app.last_result = Void)
			assert ("summary", l_app.summary.ends_with ("not finished"))
			assert ("worker joined", l_app.finished_count = 1 and l_app.running_worker_count = 0 and not l_app.is_worker_join_timed_out)
			remove_tree (l_root)
		end

	test_quit_during_scan_joins_worker
			-- Quit while the worker is held at a step: `stop_background_work` cancels it, the
			-- worker sees the flag and ends, and the join returns before its timeout.
		local
			l_root: STRING_32
			l_app: ASYNC_SCAN_TEST_APP
			l_start, l_elapsed: INTEGER_64
		do
			l_root := new_tree ("quit")
			l_app := new_app (l_root)
			l_app.hold_at_step (1, False)
			l_app.start_scan_now
			assert ("held", wait_until (agent l_app.is_held))
			l_app.stop_after_frames (1)
			l_start := {MONOTONIC_CLOCK}.milliseconds
			l_app.run
			l_elapsed := {MONOTONIC_CLOCK}.milliseconds - l_start
			assert ("worker ended before run returned", l_app.finished_count = 1)
			assert ("joined within the timeout", not l_app.is_worker_join_timed_out and l_app.running_worker_count = 0)
			assert ("returned in " + l_elapsed.out + " ms", l_elapsed < Wait_limit_ms)
			assert ("no result", not has_scan_data (l_app.taken_events, 1, {DIRECTORY_SCAN_RESULT}) and l_app.last_result = Void)
			remove_tree (l_root)
		end

	test_quit_gives_up_after_join_timeout
			-- Quit while the worker is held and does not look at the flag: `run` returns after
			-- the 500 ms join timeout with the worker recorded as still running. Released, it
			-- then stops without posting a result.
		local
			l_root: STRING_32
			l_app: ASYNC_SCAN_TEST_APP
			l_start, l_elapsed: INTEGER_64
		do
			l_root := new_tree ("timeout")
			l_app := new_app (l_root)
			l_app.hold_at_step (1, True)
			l_app.start_scan_now
			assert ("held", wait_until (agent l_app.is_held))
			l_app.stop_after_frames (1)
			l_start := {MONOTONIC_CLOCK}.milliseconds
			l_app.run
			l_elapsed := {MONOTONIC_CLOCK}.milliseconds - l_start
			assert ("timed out", l_app.is_worker_join_timed_out)
			assert ("worker kept", l_app.finished_count = 0 and l_app.running_worker_count = 1)
			assert ("waited the timeout: " + l_elapsed.out + " ms", l_elapsed >= 450)
			assert ("returned in " + l_elapsed.out + " ms", l_elapsed < Wait_limit_ms)
			l_app.release
			assert ("worker ended once released", wait_until (agent finished_at_least (l_app, 1)))
			assert ("no result", not has_scan_data (l_app.taken_events, 1, {DIRECTORY_SCAN_RESULT}))
			assert ("forgotten", l_app.running_worker_count = 0)
			remove_tree (l_root)
		end

feature {NONE} -- Snapshot rows

	batch_rows: ARRAY [READABLE_STRING_GENERAL]
			-- EXAMPLE_ASYNC_SCAN after the scan of the test tree, 72 x 20
		local
			l_rows: ARRAYED_LIST [STRING_32]
			i: INTEGER
		do
			create l_rows.make (20)
			l_rows.extend (padded (spaces (20) + "Disk usage of eiffeltui_a1_batch", 72))
			l_rows.extend (padded ("Scanned 5 directories, 7 files, 13.8 KiB", 72))
			l_rows.extend (padded ("Links not followed: 0  Left out: 1 (EIFGENs, .git)", 72))
			l_rows.extend (box_top (" Largest directories ", 36) + box_top (" Largest files ", 36))
			l_rows.extend (box_row ("     Size Directory", 36) + box_row ("     Size File", 36))
			l_rows.extend (box_row ("  5.6 KiB src", 36) + box_row ("  4.9 KiB big.bin", 36))
			l_rows.extend (box_row ("  2.1 KiB docs", 36) + box_row ("  2.9 KiB src/main.e", 36))
			l_rows.extend (box_row ("  2.0 KiB src/deep", 36) + box_row ("  2.0 KiB src/deep/core.e", 36))
			l_rows.extend (box_row ("      0 B empty", 36) + box_row ("  1.5 KiB docs/guide.md", 36))
			l_rows.extend (box_row ("", 36) + box_row ("  1.2 KiB notes.txt", 36))
			l_rows.extend (box_row ("", 36) + box_row ("    700 B docs/todo.txt", 36))
			l_rows.extend (box_row ("", 36) + box_row ("    700 B src/util.e", 36))
			l_rows.extend (box_row ("", 36) + box_row ("", 36))
				-- The warning toast at the bottom right of the tables
			l_rows.extend (box_row ("", 36) + "|    " + box_top ("", 31))
			l_rows.extend (box_row ("", 36) + "|    " + box_row ("1 directory could not be read", 31))
			l_rows.extend (box_bottom (36) + "!----" + box_bottom (31))
			l_rows.extend (box_top (" Not read (1) ", 72))
			l_rows.extend (box_row ("locked: cannot be read", 72))
			l_rows.extend (box_bottom (72))
			l_rows.extend (padded ("r: scan again  Esc: cancel  q: quit", 72))
			create Result.make_filled ({STRING_32} "", 1, l_rows.count)
			from i := 1 until i > l_rows.count loop
				Result [i] := glyphs (l_rows [i])
				i := i + 1
			end
		end

	box_top (a_title: STRING_32; a_width: INTEGER): STRING_32
			-- The top of a box `a_width` wide titled `a_title`
		do
			Result := {STRING_32} "<" + a_title + dashes (a_width - 2 - a_title.count) + {STRING_32} ">"
		end

	box_row (a_content: STRING_32; a_width: INTEGER): STRING_32
			-- A row of a box `a_width` wide holding `a_content`
		do
			Result := {STRING_32} "|" + padded (a_content, a_width - 2) + {STRING_32} "|"
		end

	box_bottom (a_width: INTEGER): STRING_32
			-- The bottom of a box `a_width` wide
		do
			Result := {STRING_32} "!" + dashes (a_width - 2) + {STRING_32} "?"
		end

	dashes (a_count: INTEGER): STRING_32
			-- `a_count` dashes
		do
			create Result.make_filled ('-', a_count)
		end

	spaces (a_count: INTEGER): STRING_32
			-- `a_count` blanks
		do
			create Result.make_filled (' ', a_count)
		end

	padded (a_text: STRING_32; a_width: INTEGER): STRING_32
			-- `a_text` followed by blanks up to `a_width`
		do
			Result := a_text + spaces ((a_width - a_text.count).max (0))
		end

	glyphs (a_pattern: STRING_32): STRING_32
			-- `a_pattern` with '-' U+2500, '|' U+2502, '<' U+250C, '>' U+2510, '!' U+2514 and
			-- '?' U+2518 (a plain box); other characters as they are
		local
			i: INTEGER
		do
			create Result.make (a_pattern.count)
			from i := 1 until i > a_pattern.count loop
				inspect a_pattern [i]
				when '-' then Result.append_character ((0x2500).to_character_32)
				when '|' then Result.append_character ((0x2502).to_character_32)
				when '<' then Result.append_character ((0x250C).to_character_32)
				when '>' then Result.append_character ((0x2510).to_character_32)
				when '!' then Result.append_character ((0x2514).to_character_32)
				when '?' then Result.append_character ((0x2518).to_character_32)
				else Result.append_character (a_pattern [i])
				end
				i := i + 1
			end
		end

feature {NONE} -- Helpers

	Excluded: ARRAY [STRING]
			-- The names EXAMPLE_ASYNC_SCAN leaves out
		once
			Result := <<"EIFGENs", ".git">>
		end

	Wait_limit_ms: INTEGER = 10_000
			-- Longest wait for a worker in these tests

	new_app (a_root: READABLE_STRING_GENERAL): ASYNC_SCAN_TEST_APP
			-- The example on an ANSI backend whose driver reads nothing, to scan `a_root`.
		local
			l_driver: FAKE_CONSOLE_DRIVER
			l_sink: STRING_32
			l_backend: ANSI_TERMINAL_BACKEND
		do
			create l_driver
			create l_sink.make_empty
			l_driver.watch_sink (l_sink)
			create l_backend.make_with_driver_and_sink (l_driver, l_sink)
			create Result.make_on_tree (create {TERMINAL [ANSI_TERMINAL_BACKEND]}.make (l_backend), a_root)
			Result.event_thread.set_poll_interval (5)
		end

	finished_at_least (a_app: ASYNC_SCAN_TEST_APP; a_count: INTEGER): BOOLEAN
			-- Have `a_count` of `a_app`'s workers ended?
		do
			Result := a_app.finished_count >= a_count
		end

	wait_until (a_condition: FUNCTION [BOOLEAN]): BOOLEAN
			-- Did `a_condition` hold within `Wait_limit_ms`? (Looks every 2 ms.)
		local
			l_deadline: INTEGER_64
		do
			from
				l_deadline := {MONOTONIC_CLOCK}.milliseconds + Wait_limit_ms
				Result := a_condition.item ([])
			until
				Result or {MONOTONIC_CLOCK}.milliseconds > l_deadline
			loop
				(create {EXECUTION_ENVIRONMENT}).sleep (2_000_000)
				Result := a_condition.item ([])
			end
		end

	has_scan_data (a_events: LIST [EVENT]; a_generation: INTEGER; a_type: TYPE [detachable ANY]): BOOLEAN
			-- Is there, among `a_events`, a scan event of `a_generation` whose data is of `a_type`?
		do
			across a_events as e loop
				if attached {CUSTOM_EVENT} e as c and then attached {TUPLE [token: STRING_8; generation: INTEGER; data: ANY]} c.payload as p
					and then p.generation = a_generation and then p.data.generating_type.conforms_to (a_type)
				then
					Result := True
				end
			end
		end

	assert_largest (a_tag: STRING; a_list: LIST [TUPLE [path: STRING_32; bytes: INTEGER_64]]; a_expected: ARRAY [TUPLE [path: STRING; bytes: INTEGER]])
			-- `a_list` holds `a_expected`, in order.
		local
			i: INTEGER
		do
			assert (a_tag + ": count " + a_list.count.out, a_list.count = a_expected.count)
			from i := 1 until i > a_list.count.min (a_expected.count) loop
				assert (a_tag + ": " + i.out + " " + a_list [i].path.out + " " + a_list [i].bytes.out,
					a_list [i].path.same_string_general (a_expected [i].path) and a_list [i].bytes = a_expected [i].bytes)
				i := i + 1
			end
		end

feature {NONE} -- Trees

	new_tree (a_name: STRING): STRING_32
			-- A new tree eiffeltui_a1_`a_name` in `temp_directory`, of known sizes:
			--   big.bin 5000, notes.txt 1200, src/main.e 3000, src/util.e 700,
			--   src/deep/core.e 2048, docs/guide.md 1500, docs/todo.txt 700, empty/,
			--   locked/secret.txt 100 (unreadable for LOCKED_DIRECTORY_SCANNER),
			--   EIFGENs/huge.bin 9999 (left out by name).
			-- Scanned with "locked" unreadable and EIFGENs left out: 5 directories, 7 files,
			-- 14148 bytes.
		do
			Result := new_empty_tree (a_name)
			put_file (Result + {STRING_32} "/big.bin", 5000)
			put_file (Result + {STRING_32} "/notes.txt", 1200)
			make_directory (Result + {STRING_32} "/src")
			put_file (Result + {STRING_32} "/src/main.e", 3000)
			put_file (Result + {STRING_32} "/src/util.e", 700)
			make_directory (Result + {STRING_32} "/src/deep")
			put_file (Result + {STRING_32} "/src/deep/core.e", 2048)
			make_directory (Result + {STRING_32} "/docs")
			put_file (Result + {STRING_32} "/docs/guide.md", 1500)
			put_file (Result + {STRING_32} "/docs/todo.txt", 700)
			make_directory (Result + {STRING_32} "/empty")
			make_directory (Result + {STRING_32} "/locked")
			put_file (Result + {STRING_32} "/locked/secret.txt", 100)
			make_directory (Result + {STRING_32} "/EIFGENs")
			put_file (Result + {STRING_32} "/EIFGENs/huge.bin", 9999)
		end

	new_empty_tree (a_name: STRING): STRING_32
			-- A new, empty directory eiffeltui_a1_`a_name` in `temp_directory` (an older one,
			-- left by a failed run, is deleted first)
		do
			Result := temp_directory + {STRING_32} "/eiffeltui_a1_" + a_name
			remove_tree (Result)
			make_directory (Result)
		end

	temp_directory: STRING_32
			-- TEMP, TMP or TMPDIR, else "."
		local
			l_env: EXECUTION_ENVIRONMENT
		do
			create l_env
			if attached l_env.item ("TEMP") as l_dir and then not l_dir.is_empty then
				Result := l_dir
			elseif attached l_env.item ("TMP") as l_dir and then not l_dir.is_empty then
				Result := l_dir
			elseif attached l_env.item ("TMPDIR") as l_dir and then not l_dir.is_empty then
				Result := l_dir
			else
				Result := "."
			end
		end

	make_directory (a_path: STRING_32)
			-- Create the directory `a_path`.
		local
			l_dir: DIRECTORY
		do
			create l_dir.make (a_path)
			if not l_dir.exists then
				l_dir.create_dir
			end
		end

	put_file (a_path: STRING_32; a_size: INTEGER)
			-- Write a file of `a_size` bytes at `a_path`.
		local
			l_file: RAW_FILE
		do
			create l_file.make_with_name (a_path)
			l_file.open_write
			l_file.put_string (create {STRING_8}.make_filled ('x', a_size))
			l_file.close
		end

	remove_tree (a_path: STRING_32)
			-- Delete the tree at `a_path`, if there is one (links are deleted, not followed).
		local
			l_dir: DIRECTORY
		do
			create l_dir.make (a_path)
			if l_dir.exists then
				l_dir.recursive_delete
			end
		end

	system (a_command: STRING_32): BOOLEAN
			-- Run `a_command` in the shell; did it succeed?
		local
			l_env: EXECUTION_ENVIRONMENT
		do
			create l_env
			l_env.system (a_command)
			Result := l_env.return_code = 0
		end

	windows_name (a_path: STRING_32): STRING_32
			-- `a_path` with '\' between its parts
		do
			Result := a_path.twin
			Result.replace_substring_all ({STRING_32} "/", {STRING_32} "\")
		end

end
