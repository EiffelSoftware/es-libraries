note
	description: "[
		Walks a directory tree and finds its largest files and directories (P2 A1, the
		blocking work of EXAMPLE_ASYNC_SCAN's worker thread). `base' only.

		  * Cancellation: `scan' asks its `a_go_on' query before each directory, and every
		    `Check_interval' entries inside a large one; once it answers False the walk stops
		    and `is_cancelled' is set. The query is the only way in from another thread.
		  * Progress: `a_progress' gets a new DIRECTORY_SCAN_PROGRESS after a directory is
		    entered, at most once per `a_interval_ms' milliseconds, so a fast walk does not
		    flood the receiver.
		  * Symbolic links are never followed, nor their sizes counted; they are only counted
		    as links, so a link to a parent cannot make the walk loop. On Windows, where
		    FILE_INFO.is_symlink is always False, symbolic links and junctions are found by
		    their reparse tag ({DIRECTORY_SCAN_PLATFORM}.is_link). Any other loop (a bind
		    mount, say) ends at `Max_depth', which is reported as a problem.
		  * Directories named as one of `excluded_names' are left out (counted only).
		  * A directory that cannot be listed (no permission, gone, a path too long) is
		    recorded in the result's `problems' and the walk goes on. Only a root that does
		    not exist, is not a directory or cannot be listed is an error (`has_error').
		    Whether it can be listed is asked first ({DIRECTORY_SCAN_PLATFORM}.can_list):
		    on Windows `base' lists a directory it may not open as an empty one.
		  * Sizes in 64 bits ({DIRECTORY_SCAN_PLATFORM}.file_size): FILE_INFO.size is an
		    INTEGER, wrong for a file of 4 GiB or more.

		The scanner and its result belong to the thread that calls `scan'; the result may be
		handed to another thread once `scan' has returned.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	DIRECTORY_SCANNER

create
	make

feature {NONE} -- Initialization

	make (a_root: READABLE_STRING_GENERAL; a_excluded: ITERABLE [READABLE_STRING_GENERAL]; a_keep: INTEGER)
			-- A scanner of the tree at `a_root`, leaving out directories named as one of
			-- `a_excluded`, keeping the `a_keep` largest files and directories.
		require
			root_not_empty: not a_root.is_empty
			keep_positive: a_keep > 0
		do
			create root.make_from_string (a_root)
			create excluded_names.make (2)
			excluded_names.compare_objects
			across a_excluded as l_name loop
				excluded_names.extend (create {STRING_32}.make_from_string_general (l_name))
			end
			create scan_result.make (root_name (root), a_keep)
			create error_message.make_empty
			create platform
			go_on := agent: BOOLEAN do Result := True end
			progress_action := agent (a_progress: DIRECTORY_SCAN_PROGRESS) do end
			create file_info.make
			file_info.set_is_following_symlinks (False)
		ensure
			not_scanned: not is_scanned
		end

feature -- Access

	root: PATH
			-- The directory to scan

	excluded_names: ARRAYED_LIST [STRING_32]
			-- Names of the directories left out

	scan_result: DIRECTORY_SCAN_RESULT
			-- What `scan` found (complete when `is_scanned` and neither `has_error` nor
			-- `is_cancelled`)

	error_message: STRING_32
			-- Why the root could not be scanned (empty when not `has_error`)

	Max_depth: INTEGER = 64
			-- Deepest directory level scanned below the root; deeper ones are a problem

	Check_interval: INTEGER = 256
			-- Entries of one directory between two looks at the `go_on` query

feature -- Status report

	is_scanned: BOOLEAN
			-- Has `scan` been called?

	is_cancelled: BOOLEAN
			-- Did the `go_on` query stop the scan?

	has_error: BOOLEAN
			-- Could the root not be scanned?
		do
			Result := not error_message.is_empty
		end

feature -- Basic operations

	scan (a_go_on: FUNCTION [BOOLEAN]; a_progress: PROCEDURE [DIRECTORY_SCAN_PROGRESS]; a_interval_ms: INTEGER)
			-- Walk the tree at `root` into `scan_result`, asking `a_go_on` before each
			-- directory and giving `a_progress` a snapshot at most every `a_interval_ms`.
		require
			not_scanned: not is_scanned
			interval_positive: a_interval_ms > 0
		local
			l_info: FILE_INFO
			l_bytes: INTEGER_64
		do
			is_scanned := True
			go_on := a_go_on
			progress_action := a_progress
			progress_interval_ms := a_interval_ms
			last_report_ms := {MONOTONIC_CLOCK}.milliseconds
			create l_info.make
			l_info.update (root.name)
			if not l_info.exists then
				error_message := {STRING_32} "No such directory: " + root.name
			elseif not l_info.is_directory then
				error_message := {STRING_32} "Not a directory: " + root.name
			elseif not go_on.item ([]) then
				is_cancelled := True
			elseif attached listed_entries (root, {STRING_32} "") as l_entries then
				top_total := l_entries.count
				l_bytes := scan_entries (root, {STRING_32} "", l_entries, 0)
			else
				error_message := {STRING_32} "Cannot read directory: " + root.name
			end
		ensure
			scanned: is_scanned
			not_both: not (has_error and is_cancelled)
		end

feature {NONE} -- Walk

	go_on: FUNCTION [BOOLEAN]
			-- May the scan go on? (Given to `scan`.)

	progress_action: PROCEDURE [DIRECTORY_SCAN_PROGRESS]
			-- Receiver of the progress snapshots (given to `scan`)

	progress_interval_ms: INTEGER
			-- Shortest time between two progress snapshots

	last_report_ms: INTEGER_64
			-- When the last snapshot was given (or the scan started)

	top_done, top_total: INTEGER
			-- Root entries done, and in all

	file_info: FILE_INFO
			-- Information on one entry, not following symbolic links

	platform: DIRECTORY_SCAN_PLATFORM
			-- What `file_info` does not tell (links on Windows, listing rights, 64-bit sizes)

	scan_entries (a_path: PATH; a_relative: STRING_32; a_entries: ARRAYED_LIST [PATH]; a_depth: INTEGER): INTEGER_64
			-- Size of the files under the listed directory `a_path` (`a_relative` from the
			-- root, `a_depth` levels below it) with entries `a_entries`; record it.
		require
			depth_in_range: 0 <= a_depth and a_depth <= Max_depth
		local
			l_child: PATH
			l_name, l_relative: STRING_32
			l_bytes: INTEGER_64
			l_seen: INTEGER
		do
			report (a_relative)
			across a_entries as l_entry until is_cancelled loop
				if not (l_entry.is_current_symbol or l_entry.is_parent_symbol or l_entry.is_empty) then
					l_seen := l_seen + 1
					if l_seen \\ Check_interval = 0 and then not go_on.item ([]) then
						is_cancelled := True
					else
						l_child := a_path.extended_path (l_entry)
						create l_name.make_from_string (l_entry.name)
						if a_relative.is_empty then
							l_relative := l_name
						else
							l_relative := a_relative + {STRING_32} "/" + l_name
						end
						file_info.update (l_child.name)
						if not file_info.exists then
								-- Gone since the listing, or a name the platform cannot stat
						elseif platform.is_link (l_child, file_info) then
							scan_result.add_link
						elseif file_info.is_directory then
							if excluded_names.has (l_name) then
								scan_result.add_excluded
							elseif a_depth >= Max_depth then
								scan_result.add_problem (l_relative, {STRING_32} "deeper than " + Max_depth.out + " levels")
							else
								Result := Result + scanned_directory (l_child, l_relative, a_depth + 1)
							end
						elseif file_info.is_plain then
							l_bytes := platform.file_size (l_child, file_info)
							scan_result.add_file (l_relative, l_bytes)
							Result := Result + l_bytes
						end
					end
					if a_depth = 0 and top_done < top_total then
						top_done := top_done + 1
					end
				end
			end
			if not is_cancelled then
				scan_result.add_directory (a_relative, Result)
			end
		ensure
			not_negative: Result >= 0
		end

	scanned_directory (a_path: PATH; a_relative: STRING_32; a_depth: INTEGER): INTEGER_64
			-- Size of the files under the directory `a_path`, scanned unless the scan is
			-- cancelled; a directory that cannot be listed is recorded as a problem.
		require
			depth_in_range: 1 <= a_depth and a_depth <= Max_depth
		do
			if not go_on.item ([]) then
				is_cancelled := True
			elseif attached listed_entries (a_path, a_relative) as l_entries then
				Result := scan_entries (a_path, a_relative, l_entries, a_depth)
			else
				scan_result.add_problem (a_relative, {STRING_32} "cannot be read")
			end
		ensure
			not_negative: Result >= 0
		end

	listed_entries (a_path: PATH; a_relative: STRING_32): detachable ARRAYED_LIST [PATH]
			-- Entries of the directory `a_path`, or Void when it cannot be listed
		local
			l_failed: BOOLEAN
		do
			if not l_failed and then is_listable (a_path, a_relative) then
				Result := (create {DIRECTORY}.make_with_path (a_path)).entries
			end
		rescue
			l_failed := True
			retry
		end

	is_listable (a_path: PATH; a_relative: STRING_32): BOOLEAN
			-- May the directory `a_path` (`a_relative` from the root) be listed by this
			-- process? (A listing that fails all the same is rescued in `listed_entries`.)
		local
			l_info: FILE_INFO
		do
			create l_info.make
			l_info.update (a_path.name)
			Result := l_info.exists and then l_info.is_directory and then platform.can_list (a_path, l_info)
		end

	report (a_relative: STRING_32)
			-- Give `progress_action` a snapshot, in `a_relative`, if `progress_interval_ms`
			-- have passed since the last one.
		local
			l_now: INTEGER_64
		do
			l_now := {MONOTONIC_CLOCK}.milliseconds
			if l_now - last_report_ms >= progress_interval_ms then
				last_report_ms := l_now
				progress_action.call ([create {DIRECTORY_SCAN_PROGRESS}.make (scan_result.directory_count,
					scan_result.file_count, scan_result.total_bytes, a_relative, top_done, top_total, l_now)])
			end
		end

	root_name (a_root: PATH): STRING_32
			-- The last part of `a_root` once made absolute, or the whole name
		do
			if attached a_root.absolute_path.canonical_path.entry as l_entry then
				create Result.make_from_string (l_entry.name)
			else
				create Result.make_from_string (a_root.absolute_path.canonical_path.name)
			end
		end

invariant
	keep_result: scan_result /= Void
	cancelled_only_scanned: is_cancelled implies is_scanned

end
