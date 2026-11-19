note
	description: "[
		What a DIRECTORY_SCANNER found (P2 A1, EXAMPLE_ASYNC_SCAN): the counts, the largest
		files and directories, and the directories it could not read.

		Filled by the scanner on the scanning thread, then posted to the main loop, after
		which the scanner never touches it again: so it needs no lock. Paths are relative to
		the scanned root, with "/" between their parts on every platform.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	DIRECTORY_SCAN_RESULT

create
	make

feature {NONE} -- Initialization

	make (a_root_name: READABLE_STRING_GENERAL; a_keep: INTEGER)
			-- An empty result for the root named `a_root_name`, keeping the `a_keep` largest
			-- files and directories.
		require
			keep_positive: a_keep > 0
		do
			create root_name.make_from_string_general (a_root_name)
			keep := a_keep
			create largest_files.make (a_keep + 1)
			create largest_directories.make (a_keep + 1)
			create problems.make (4)
		ensure
			root_name_set: root_name.same_string_general (a_root_name)
			keep_set: keep = a_keep
			empty: directory_count = 0 and file_count = 0 and total_bytes = 0
		end

feature -- Access

	root_name: STRING_32
			-- Name of the scanned directory (its last part)

	keep: INTEGER
			-- How many of the largest files and directories are kept

	directory_count: INTEGER
			-- Directories listed, the root included

	file_count: INTEGER
			-- Plain files counted

	total_bytes: INTEGER_64
			-- Size of the files counted

	largest_files: ARRAYED_LIST [TUPLE [path: STRING_32; bytes: INTEGER_64]]
			-- The `keep` largest files, largest first (equal sizes by path)

	largest_directories: ARRAYED_LIST [TUPLE [path: STRING_32; bytes: INTEGER_64]]
			-- The `keep` largest directories below the root, by the size of the files under
			-- them, largest first (equal sizes by path)

	problems: ARRAYED_LIST [TUPLE [path: STRING_32; reason: STRING_32]]
			-- The first `Max_problems` directories not scanned, with why, in the order met

	problem_count: INTEGER
			-- Directories not scanned (can be more than `problems` holds)

	link_count: INTEGER
			-- Symbolic links met and not followed (nor counted)

	excluded_count: INTEGER
			-- Directories left out by name (EXAMPLE_ASYNC_SCAN leaves out EIFGENs and .git)

	Max_problems: INTEGER = 100
			-- Most problems listed in `problems`

feature {DIRECTORY_SCANNER} -- Element change

	add_file (a_path: READABLE_STRING_32; a_bytes: INTEGER_64)
			-- Count the file `a_path` of `a_bytes` bytes.
		require
			bytes_not_negative: a_bytes >= 0
		do
			file_count := file_count + 1
			total_bytes := total_bytes + a_bytes
			put_largest (largest_files, a_path, a_bytes)
		ensure
			counted: file_count = old file_count + 1
			added: total_bytes = old total_bytes + a_bytes
		end

	add_directory (a_path: READABLE_STRING_32; a_bytes: INTEGER_64)
			-- Count the directory `a_path`, whose files take `a_bytes` bytes ("" is the root,
			-- counted but not ranked).
		require
			bytes_not_negative: a_bytes >= 0
		do
			directory_count := directory_count + 1
			if not a_path.is_empty then
				put_largest (largest_directories, a_path, a_bytes)
			end
		ensure
			counted: directory_count = old directory_count + 1
		end

	add_problem (a_path, a_reason: READABLE_STRING_32)
			-- Record that the directory `a_path` was not scanned, because of `a_reason`.
		do
			problem_count := problem_count + 1
			if problems.count < Max_problems then
				problems.extend ([create {STRING_32}.make_from_string (a_path), create {STRING_32}.make_from_string (a_reason)])
			end
		ensure
			counted: problem_count = old problem_count + 1
		end

	add_link
			-- Count a symbolic link that was not followed.
		do
			link_count := link_count + 1
		ensure
			counted: link_count = old link_count + 1
		end

	add_excluded
			-- Count a directory left out by name.
		do
			excluded_count := excluded_count + 1
		ensure
			counted: excluded_count = old excluded_count + 1
		end

feature {NONE} -- Implementation

	put_largest (a_list: like largest_files; a_path: READABLE_STRING_32; a_bytes: INTEGER_64)
			-- Insert `a_path` of `a_bytes` in `a_list` in its place (largest first, equal sizes
			-- by path), and drop the last entry when there are more than `keep`.
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > a_list.count or else is_before (a_path, a_bytes, a_list [i].path, a_list [i].bytes)
			loop
				i := i + 1
			end
			if i > a_list.count then
				if i <= keep then
					a_list.extend ([create {STRING_32}.make_from_string (a_path), a_bytes])
				end
			else
				a_list.go_i_th (i)
				a_list.put_left ([create {STRING_32}.make_from_string (a_path), a_bytes])
				if a_list.count > keep then
					a_list.finish
					a_list.remove
				end
			end
		ensure
			bounded: a_list.count <= keep
		end

	is_before (a_path: READABLE_STRING_32; a_bytes: INTEGER_64; a_other_path: READABLE_STRING_32; a_other_bytes: INTEGER_64): BOOLEAN
			-- Does `a_path` of `a_bytes` come before `a_other_path` of `a_other_bytes`?
		do
			Result := a_bytes > a_other_bytes or else
				(a_bytes = a_other_bytes and then a_path.as_string_32 < a_other_path.as_string_32)
		end

invariant
	keep_positive: keep > 0
	files_bounded: largest_files.count <= keep
	directories_bounded: largest_directories.count <= keep
	problems_bounded: problems.count <= problem_count.min (Max_problems)
	counts_not_negative: directory_count >= 0 and file_count >= 0 and total_bytes >= 0 and
		link_count >= 0 and excluded_count >= 0

end
