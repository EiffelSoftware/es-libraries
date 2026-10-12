note
	description: "[
		Helper class providing PATH-based utilities for test files.
		Test classes can inherit from this to get cross-platform path handling.
	]"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	TEST_PATH_HELPER

inherit
	ANY
		undefine
			default_create
		end

feature -- Path Helpers

	testing_dir_path: PATH
			-- Return PATH for the testing directory.
		local
			pdf_dir: PATH
		once
			create Result.make_current
			Result := Result.canonical_path.absolute_path
			if not Result.name.ends_with ("testing") then
				Result := Result.extended ("testing")
			end
		ensure
			result_not_void: Result /= Void
		end

	test_pdf_path (a_filename: STRING_32): PATH
			-- Return PATH to test PDF file in testing\pdf directory.
		require
			filename_not_empty: a_filename /= Void and then not a_filename.is_empty
		do
			Result := testing_dir_path.extended ("pdf").extended (a_filename)
		ensure
			result_not_void: Result /= Void
		end

	test_other_pdf_path (a_filename: STRING_32): PATH
			-- Return PATH to test PDF file in testing\pdf\other directory.
		require
			filename_not_empty: a_filename /= Void and then not a_filename.is_empty
		do
			Result := testing_dir_path.extended ("pdf").extended ("other").extended (a_filename)
		ensure
			result_not_void: Result /= Void
		end

	has_test_pdf (a_filename: STRING_32): BOOLEAN
			-- Is test PDF file `a_filename` available in testing\pdf directory?
			-- (Large third-party samples are not distributed with the library.)
		require
			filename_not_empty: a_filename /= Void and then not a_filename.is_empty
		do
			Result := (create {RAW_FILE}.make_with_path (test_pdf_path (a_filename))).exists
		end

	has_other_test_pdf (a_filename: STRING_32): BOOLEAN
			-- Is test PDF file `a_filename` available in testing\pdf\other directory?
			-- (Large third-party samples are not distributed with the library.)
		require
			filename_not_empty: a_filename /= Void and then not a_filename.is_empty
		do
			Result := (create {RAW_FILE}.make_with_path (test_other_pdf_path (a_filename))).exists
		end

	test_output_path (a_filename: STRING_32): PATH
			-- Return PATH to test output file in testing\test_output directory.
		require
			filename_not_empty: a_filename /= Void and then not a_filename.is_empty
		do
			Result := testing_dir_path.extended ("test_output").extended (a_filename)
		ensure
			result_not_void: Result /= Void
		end

	ensure_test_output_directory_exists
			-- Create testing\test_output directory if it doesn't exist.
		local
			dir: DIRECTORY
			output_path: PATH
		do
			create output_path.make_current
			output_path := output_path.extended ("test_output")
--			output_path := output_path.extended ("testing").extended ("test_output")
			create dir.make_with_path (output_path)
			if not dir.exists then
				dir.create_dir
			end
		end

end

