note
	description: "[
		How far a DIRECTORY_SCANNER has got: a snapshot made by the scanning thread and
		posted to the main loop (P2 A1, EXAMPLE_ASYNC_SCAN). Immutable once made, so the two
		threads can share it without a lock.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	DIRECTORY_SCAN_PROGRESS

create
	make

feature {NONE} -- Initialization

	make (a_directories, a_files: INTEGER; a_bytes: INTEGER_64; a_current: READABLE_STRING_GENERAL;
			a_top_done, a_top_total: INTEGER; a_time_ms: INTEGER_64)
			-- Progress after `a_directories` directories and `a_files` files of `a_bytes` bytes,
			-- in the directory `a_current` (relative to the root), with `a_top_done` of the
			-- root's `a_top_total` entries done, made at `a_time_ms` (MONOTONIC_CLOCK).
		require
			counts_not_negative: a_directories >= 0 and a_files >= 0 and a_bytes >= 0
			valid_top: 0 <= a_top_done and a_top_done <= a_top_total
		do
			directory_count := a_directories
			file_count := a_files
			total_bytes := a_bytes
			create current_path.make_from_string_general (a_current)
			top_done := a_top_done
			top_total := a_top_total
			time_ms := a_time_ms
		ensure
			directories_set: directory_count = a_directories
			files_set: file_count = a_files
			bytes_set: total_bytes = a_bytes
			current_set: current_path.same_string_general (a_current)
			top_set: top_done = a_top_done and top_total = a_top_total
			time_set: time_ms = a_time_ms
		end

feature -- Access

	directory_count: INTEGER
			-- Directories listed so far

	file_count: INTEGER
			-- Files counted so far

	total_bytes: INTEGER_64
			-- Size of the files counted so far

	current_path: STRING_32
			-- The directory being scanned, relative to the root ("" for the root itself)

	top_done: INTEGER
			-- Entries of the root directory done

	top_total: INTEGER
			-- Entries of the root directory (0 until it is listed)

	time_ms: INTEGER_64
			-- When the snapshot was made (MONOTONIC_CLOCK milliseconds)

	ratio: REAL_64
			-- Share of the root's entries done (0 while the root is not listed)
		do
			if top_total > 0 then
				Result := top_done / top_total
			end
		ensure
			in_range: 0.0 <= Result and Result <= 1.0
		end

invariant
	counts_not_negative: directory_count >= 0 and file_count >= 0 and total_bytes >= 0
	valid_top: 0 <= top_done and top_done <= top_total

end
