note
	description: "[
		Frame output without a second pass (review finding M2):
		- ANSI_SERIALIZER builds every frame in one buffer, kept from frame to frame
		- it hands the frame to the backend with the cursor position it ends at, and
		  ANSI_TERMINAL_BACKEND takes that position instead of decoding and scanning the frame
		- the position is in the buffer's columns, so it is right after a ZWJ sequence too
		  (scanning counted one width per code point)
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_FRAME_OUTPUT

inherit
	EQA_TEST_SET

feature -- Frame buffer

	test_frame_buffer_reused
			-- Consecutive frames are built in the same string, which keeps its capacity.
		local
			l_serializer: ANSI_SERIALIZER
			l_first: STRING_8
			l_capacity: INTEGER
			l_backend: ANSI_TERMINAL_BACKEND
			l_sink: STRING_32
		do
			create l_serializer
			create l_sink.make (256)
			create l_backend.make_with_driver_and_sink (create {FAKE_CONSOLE_DRIVER}, l_sink)
			l_serializer.render_spans ((create {DIFF_ENGINE}).diff (blank (40, 3), text_buffer (40, 3, "a long first frame of text")), l_backend)
			l_first := l_serializer.frame
			l_capacity := l_first.capacity
			l_sink.wipe_out
			l_serializer.render_spans ((create {DIFF_ENGINE}).diff (blank (40, 3), text_buffer (40, 3, "x")), l_backend)
			assert ("same string", l_serializer.frame = l_first)
			assert ("capacity kept", l_serializer.frame.capacity >= l_capacity)
			assert ("holds only the second frame", l_sink.same_string_general (l_serializer.frame) and not l_sink.has_substring ("long"))
		end

feature -- Cursor position

	test_cursor_after_frame
			-- After a frame the backend's cursor is just after the last cell written, with the offset.
		local
			l_backend: ANSI_TERMINAL_BACKEND
		do
			l_backend := new_backend;
			(create {ANSI_SERIALIZER}).render_spans_with_offset ((create {DIFF_ENGINE}).diff (blank (10, 3), text_at (10, 3, 2, 1, "abc")),
				l_backend, 4, 1)
			assert ("row with offset", l_backend.cursor_row = 3)
			assert ("column after c", l_backend.cursor_column = 8)
		end

	test_cursor_after_zwj_sequence
			-- A frame ending with a ZWJ family leaves the cursor 2 columns after it, as in the
			-- buffer; scanning the frame counted 2 + 0 + 2.
		local
			l_backend: ANSI_TERMINAL_BACKEND
		do
			l_backend := new_backend;
			(create {ANSI_SERIALIZER}).render_spans ((create {DIFF_ENGINE}).diff (blank (10, 1),
				text_buffer (10, 1, {STRING_32} "ab%/0x1F468/%/0x200D/%/0x1F469/")), l_backend)
			assert ("column 4", l_backend.cursor_column = 4)
		end

	test_cursor_at_right_edge
			-- A frame ending in the last column leaves the cursor on it (the terminal's pending wrap).
		local
			l_backend: ANSI_TERMINAL_BACKEND
		do
			l_backend := new_backend;
			(create {ANSI_SERIALIZER}).render_spans ((create {DIFF_ENGINE}).diff (blank (80, 1), text_at (80, 1, 0, 77, "xyz")), l_backend)
			assert ("last column", l_backend.cursor_column = 79)
		end

	test_empty_frame_keeps_cursor
			-- A frame with nothing to draw does not move the tracked cursor.
		local
			l_backend: ANSI_TERMINAL_BACKEND
		do
			l_backend := new_backend;
			l_backend.move_cursor (5, 7)
			(create {ANSI_SERIALIZER}).render_spans ((create {DIFF_ENGINE}).diff (blank (10, 3), blank (10, 3)), l_backend)
			assert ("unchanged", l_backend.cursor_row = 5 and l_backend.cursor_column = 7)
		end

	test_put_frame_does_not_scan
			-- `put_frame` writes the bytes as they are and takes the given position: text in the
			-- frame does not move the tracked cursor, which shows it is not scanned.
		local
			l_backend: ANSI_TERMINAL_BACKEND
			l_sink: STRING_32
		do
			create l_sink.make (64)
			create l_backend.make_with_driver_and_sink (create {FAKE_CONSOLE_DRIVER}, l_sink)
			l_backend.put_frame ("hello%/27/[3;3Hworld", [1, 2])
			assert ("bytes written", l_sink.same_string ("hello%/27/[3;3Hworld"))
			assert ("given position", l_backend.cursor_row = 1 and l_backend.cursor_column = 2)
			l_backend.put_frame ("more", Void)
			assert ("Void keeps the position", l_backend.cursor_row = 1 and l_backend.cursor_column = 2)
		end

	test_put_string_still_tracks
			-- Plain `put_string` output is still scanned for the cursor.
		local
			l_backend: ANSI_TERMINAL_BACKEND
		do
			l_backend := new_backend;
			l_backend.put_string ("%/27/[2;4Hab")
			assert ("moved and advanced", l_backend.cursor_row = 1 and l_backend.cursor_column = 5)
		end

feature {NONE} -- Helpers

	new_backend: ANSI_TERMINAL_BACKEND
			-- ANSI backend on a fake 80x24 console, output captured
		do
			create Result.make_with_driver_and_sink (create {FAKE_CONSOLE_DRIVER}, create {STRING_32}.make (64))
		end

	blank (a_width, a_height: INTEGER): BUFFER
			-- Blank buffer
		do
			create Result.make (a_width, a_height)
		end

	text_buffer (a_width, a_height: INTEGER; a_text: READABLE_STRING_GENERAL): BUFFER
			-- Buffer with `a_text` at the top left
		do
			Result := text_at (a_width, a_height, 0, 0, a_text)
		end

	text_at (a_width, a_height, a_row, a_col: INTEGER; a_text: READABLE_STRING_GENERAL): BUFFER
			-- Buffer with `a_text` at (`a_row`, `a_col`)
		do
			create Result.make (a_width, a_height)
			Result.put_string (a_row, a_col, a_text, create {STYLE})
		end

end
