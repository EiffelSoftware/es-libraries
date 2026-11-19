note
	description: "[
		DIRECTORY_SCANNER for which a directory named "locked" cannot be listed, on every
		platform and whoever runs the tests (P2 A1). The real case, a directory without
		permissions, applies only on POSIX and not as root; TEST_ASYNC_SCAN checks it there.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	LOCKED_DIRECTORY_SCANNER

inherit
	DIRECTORY_SCANNER
		redefine
			is_listable
		end

create
	make

feature {NONE} -- Walk

	is_listable (a_path: PATH; a_relative: STRING_32): BOOLEAN
			-- As the scanner, except for a directory named "locked"
		do
			Result := Precursor (a_path, a_relative) and not
				(a_relative.same_string ({STRING_32} "locked") or a_relative.ends_with ({STRING_32} "/locked"))
		end

end
