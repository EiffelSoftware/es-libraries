note
	description: "Tests for input stream input classes."
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_INPUT_STREAMS_8

inherit
	EQA_TEST_SET

feature -- NULL input streams

	test_null_input_stream_basic
			-- Test basic behavior of NULL_INPUT_STREAM.
		local
			s: NULL_INPUT_STREAM
		do
			create s
			assert ("end_of_input", s.end_of_input)
			assert ("is_open_read", s.is_open_read)
			assert ("index_zero", s.index = 0)
			assert ("line_zero", s.line = 0)
			assert ("column_zero", s.column = 0)

				-- Calling start should be no-op.
			s.start

			assert ("still_end_of_input", s.end_of_input)
			assert ("still_index_zero", s.index = 0)
			assert ("still_line_zero", s.line = 0)
			assert ("still_column_zero", s.column = 0)
		end

	test_null_natural_8_input_stream_basic
			-- Test basic behavior of NULL_NATURAL_8_INPUT_STREAM.
		local
			s: NULL_NATURAL_8_INPUT_STREAM
		do
			create s
			assert ("end_of_input", s.end_of_input)
			assert ("is_open_read", s.is_open_read)
			assert ("index_zero", s.index = 0)
			assert ("line_zero", s.line = 0)
			assert ("column_zero", s.column = 0)
			assert ("last_byte_zero", s.last_byte = 0)

				-- Calling start/next should be no-op.
			s.start

			assert ("still_end_of_input", s.end_of_input)
			assert ("still_index_zero", s.index = 0)
			assert ("still_line_zero", s.line = 0)
			assert ("still_column_zero", s.column = 0)
			assert ("still_last_byte_zero", s.last_byte = 0)
		end

feature -- In-memory character stream

	test_string_8_character_8_input_stream_basic
			-- Test reading from STRING_8_CHARACTER_8_INPUT_STREAM.
		local
			s: STRING_8_CHARACTER_8_INPUT_STREAM
		do
			create s.make ("ab%Ncd")

				-- After creation and `start' in make.
			assert ("not_end_of_input", not s.end_of_input)
			assert ("initial_index_zero", s.index = 0)
			assert ("initial_line_one", s.line = 1)
			assert ("initial_column_zero", s.column = 0)

				-- Read 'a'.
			s.next
			assert ("index_after_a", s.index = 1)
			assert ("line_after_a", s.line = 1)
			assert ("column_after_a", s.column = 1)
			assert ("last_char_a", s.last_character = 'a')

				-- Read 'b'.
			s.next
			assert ("index_after_b", s.index = 2)
			assert ("line_after_b", s.line = 1)
			assert ("column_after_b", s.column = 2)
			assert ("last_char_b", s.last_character = 'b')

				-- Read '%N' (newline).
			s.next
			assert ("index_after_newline", s.index = 3)
			assert ("line_after_newline", s.line = 1)
			assert ("column_reset_after_newline", s.column = 3)
			assert ("last_char_newline", s.last_character = '%N')

				-- Read 'c'.
			s.next
			assert ("index_after_c", s.index = 4)
			assert ("line_after_c", s.line = 2)
			assert ("column_after_c", s.column = 1)
			assert ("last_char_c", s.last_character = 'c')

				-- Read 'd'.
			s.next
			assert ("index_after_d", s.index = 5)
			assert ("line_after_d", s.line = 2)
			assert ("column_after_d", s.column = 2)
			assert ("last_char_d", s.last_character = 'd')

				-- Further reads keep end_of_input True and do not change line/column.
			s.next
			assert ("end_of_input_after_extra_read", s.end_of_input)
			assert ("index_after_extra_read", s.index = 5)
			assert ("line_after_extra_read", s.line = 2)
			assert ("column_after_extra_read", s.column = 3)
		end

feature -- In-memory byte stream

	test_byte_array_input_stream_basic
			-- Test reading from BYTE_ARRAY_INPUT_STREAM.
		local
			bytes: ARRAY [NATURAL_8]
			s: BYTE_ARRAY_INPUT_STREAM
		do
				-- 'A', newline, 'B'.
			bytes := <<('A').code.to_natural_8, 10, ('B').code.to_natural_8>>
			create s.make (bytes)

				-- After creation and `start' in make.
			assert ("not_end_of_input", not s.end_of_input)
			assert ("initial_index_zero", s.index = 0)
			assert ("initial_line_one", s.line = 1)
			assert ("initial_column_zero", s.column = 0)

				-- Read 'A'.
			s.next
			assert ("index_after_A", s.index = 1)
			assert ("line_after_A", s.line = 1)
			assert ("column_after_A", s.column = 1)
			assert ("last_byte_A", s.last_byte = ('A').code.to_natural_8)

				-- Read newline.
			s.next
			assert ("index_after_newline", s.index = 2)
			assert ("line_after_newline", s.line = 1)
			assert ("column_reset_after_newline", s.column = 2)
			assert ("last_byte_newline", s.last_byte = 10)

				-- Read 'B'.
			s.next
			assert ("index_after_B", s.index = 3)
			assert ("line_after_B", s.line = 2)
			assert ("column_after_B", s.column = 1)
			assert ("last_byte_B", s.last_byte = ('B').code.to_natural_8)

				-- Extra read: end_of_input should now be True.
			s.next
			assert ("end_of_input_after_extra_read", s.end_of_input)
			assert ("index_after_extra_read", s.index = 3)
			assert ("line_after_extra_read", s.line = 2)
			assert ("column_after_extra_read", s.column = 2)
		end

feature -- File character stream

	test_file_character_8_input_stream_small
			-- Test FILE_CHARACTER_8_INPUT_STREAM on a small file.
		local
			f: RAW_FILE
			s: FILE_CHARACTER_8_INPUT_STREAM
		do
				-- Prepare small file with "ab%Ncd".
			f := new_temporary_file ("bson_stream_char_small_")
			f.put_string ("ab%Ncd")
			f.close

				-- Create stream from file path.
			create s.make_with_path (f.path)

			assert ("not_end_of_input", not s.end_of_input)
			assert ("initial_index_zero", s.index = 0)
			assert ("initial_line_one", s.line = 1)
			assert ("initial_column_zero", s.column = 0)

				-- Read 'a'.
			s.next
			assert ("index_after_a", s.index = 1)
			assert ("line_after_a", s.line = 1)
			assert ("column_after_a", s.column = 1)
			assert ("last_char_a", s.last_character = 'a')

				-- Read 'b'.
			s.next
			assert ("index_after_b", s.index = 2)
			assert ("line_after_b", s.line = 1)
			assert ("column_after_b", s.column = 2)
			assert ("last_char_b", s.last_character = 'b')

				-- Read '%N' (newline).
			s.next
			assert ("index_after_newline", s.index = 3)
			assert ("line_after_newline", s.line = 1)
			assert ("column_reset_after_newline", s.column = 3)
			assert ("last_char_newline", s.last_character = '%N')

				-- Read 'c'.
			s.next
			assert ("index_after_c", s.index = 4)
			assert ("line_after_c", s.line = 2)
			assert ("column_after_c", s.column = 1)
			assert ("last_char_c", s.last_character = 'c')

				-- Read 'd'.
			s.next
			assert ("index_after_d", s.index = 5)
			assert ("line_after_d", s.line = 2)
			assert ("column_after_d", s.column = 2)
			assert ("last_char_d", s.last_character = 'd')

				-- Extra read after end of input.
			s.next
			assert ("end_of_input_after_extra_read", s.end_of_input)
			assert ("index_after_extra_read", s.index = 6)

			s.close
			if f.exists then
				f.delete
			end
		end

	test_file_character_8_input_stream_large
			-- Test FILE_CHARACTER_8_INPUT_STREAM on a large file (> 4 * 4096 bytes).
		local
			f: FILE
			s: FILE_CHARACTER_8_INPUT_STREAM
			count: INTEGER
			txt: STRING_8
		do
				-- Build large content: 4 * 4096 + 100 characters with newlines.
			f := new_file ("bson_stream_char_large_", 4 * 4096 + 100)


				-- Create stream from file path.
			create s.make_with_path (f.path)

				-- Read until end of input, counting characters.
			from
				count := 0
				create txt.make (s.count)
			until
				s.end_of_input
			loop
				s.next
				txt.append_character (s.last_character)
				if not s.end_of_input then
					count := count + 1
				end
			end

				-- We should have read exactly `count' characters.
			assert ("read_full_file", count = s.count)
			assert ("end_of_input_true", s.end_of_input)

			s.close
			if f.exists then
				f.delete
			end
		end

	new_file (a_name: READABLE_STRING_GENERAL; a_size: INTEGER): FILE
			-- File bigger than `a_size`.
		local
			f: RAW_FILE
			i, count: INTEGER
			line: STRING_8
			line_count: INTEGER
		do
			f := new_temporary_file (a_name)
			from
				i := 1
				line := "0123456789abcdefghijklmnopqrstuvwxyz"
				line_count := 0
				count := 0
			until
				count > a_size
			loop
				f.put_string ("#" + line_count.out + ":")
				count := count + 1 + line_count.out.count + 1
				f.put_string (line)
				count := count + line.count
				f.put_new_line
				count := count + 1
				line_count := line_count + 1
			end
			f.close

			Result := f
		end

feature -- File byte stream

	test_file_natural_8_input_stream_small
			-- Test FILE_NATURAL_8_INPUT_STREAM on a small file.
		local
			f: RAW_FILE
			s: FILE_NATURAL_8_INPUT_STREAM
		do
				-- Prepare small file with bytes for "A%N B".
			f := new_temporary_file ("bson_stream_nat8_small_")
			f.put_string ("A%NB")
			f.close

				-- Create stream from file path.
			create s.make_with_path (f.path)

			assert ("not_end_of_input", not s.end_of_input)
			assert ("initial_index_zero", s.index = 0)
			assert ("initial_line_one", s.line = 1)
			assert ("initial_column_zero", s.column = 0)

				-- Read 'A'.
			s.next
			assert ("index_after_A", s.index = 1)
			assert ("line_after_A", s.line = 1)
			assert ("column_after_A", s.column = 1)
			assert ("last_byte_A", s.last_byte = ('A').code.to_natural_8)

				-- Read newline.
			s.next
			assert ("index_after_newline", s.index = 2)
			assert ("line_after_newline", s.line = 1)
			assert ("column_after_newline", s.column = 2)
			assert ("last_byte_newline", s.last_byte = 10)

				-- Read 'B'.
			s.next
			assert ("index_after_B", s.index = 3)
			assert ("line_after_B", s.line = 2)
			assert ("column_after_B", s.column = 1)
			assert ("last_byte_B", s.last_byte = ('B').code.to_natural_8)

				-- Extra read after end of input.
			s.next
			assert ("end_of_input_after_extra_read", s.end_of_input)
			assert ("index_after_extra_read", s.index = 4)

			s.close
			if f.exists then
				f.delete
			end
		end

	test_file_natural_8_input_stream_large
			-- Test FILE_NATURAL_8_INPUT_STREAM on a large file (> 4 * 4096 bytes).
		local
			f: FILE
			s: FILE_NATURAL_8_INPUT_STREAM
			read_count: INTEGER
			txt: STRING_8
		do
			f := new_file ("bson_stream_char_large_", 4 * 4096 + 100)

				-- Create stream from file path.
			create s.make_with_path (f.path)

				-- Read until end of input, counting bytes.
			from
				read_count := 0
				create txt.make (s.count)
			until
				s.end_of_input
			loop
				s.next
				txt.append_code (s.last_byte.to_natural_32)
				if not s.end_of_input then
					read_count := read_count + 1
				end
			end

				-- We should have read exactly `count' bytes.
			assert ("read_full_file", read_count = s.count)
			assert ("end_of_input_true", s.end_of_input)

			s.close
			if f.exists then
				f.delete
			end
		end

feature {NONE} -- Helpers

	new_temporary_file (a_prefix: READABLE_STRING_GENERAL): RAW_FILE
			-- New temporary file, in system temporary directory if available,
			-- otherwise in current directory.
		local
			env: EXECUTION_ENVIRONMENT
		do
			create env
			if attached env.temporary_directory_path as tmp then
				create Result.make_open_temporary_with_prefix (tmp.extended (a_prefix).name)
			else
				create Result.make_open_temporary_with_prefix (a_prefix)
			end
		ensure
			Result_exists: Result.exists
			Result_is_open_write: Result.is_open_write
		end

end

