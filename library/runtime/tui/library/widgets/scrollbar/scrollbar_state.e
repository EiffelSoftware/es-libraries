note
	description: "[
		Mutable state for TUI_SCROLLBAR tracking total content length,
		current position (0-based), and optional viewport content length.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	SCROLLBAR_STATE

inherit
	WIDGET_STATE
		redefine
			default_create
		end

create
	default_create,
	make

feature {NONE} -- Initialization

	default_create
			-- Initialize with zero content length and position at 0.
		do
			content_length := 0
			position := 0
			viewport_content_length := 0
		ensure then
			content_length_zero: content_length = 0
			position_zero: position = 0
			viewport_length_zero: viewport_content_length = 0
		end

	make (a_content_length: INTEGER)
			-- Initialize with `a_content_length`.
		require
			non_negative_length: a_content_length >= 0
		do
			default_create
			content_length := a_content_length
		ensure
			content_length_set: content_length = a_content_length
			position_zero: position = 0
		end

feature -- Access

	content_length: INTEGER
			-- Total number of scrollable items

	position: INTEGER
			-- Current scroll offset position (0-based)

	viewport_content_length: INTEGER
			-- Length of content in current viewport (0 = use track size)

feature -- Element change

	set_content_length (a_length: INTEGER)
			-- Set total content length.
		require
			non_negative: a_length >= 0
		do
			content_length := a_length
			if content_length > 0 and position >= content_length then
				position := content_length - 1
			end
		ensure
			content_length_set: content_length = a_length
		end

	set_position (a_position: INTEGER)
			-- Set 0-based scroll position.
		require
			non_negative: a_position >= 0
		do
			if content_length > 0 then
				position := a_position.min (content_length - 1)
			else
				position := 0
			end
		ensure
			position_set: content_length > 0 implies position <= content_length - 1
		end

	set_viewport_content_length (a_length: INTEGER)
			-- Set viewport content length.
		require
			non_negative: a_length >= 0
		do
			viewport_content_length := a_length
		ensure
			viewport_set: viewport_content_length = a_length
		end

feature -- Navigation

	next
			-- Advance position by 1, clamping at `content_length - 1`.
		do
			if content_length > 0 and position < content_length - 1 then
				position := position + 1
			end
		ensure
			clamped: content_length > 0 implies position <= content_length - 1
		end

	prev
			-- Decrement position by 1, clamping at 0.
		do
			if position > 0 then
				position := position - 1
			end
		ensure
			clamped: position >= 0
		end

	first
			-- Move position to beginning (0).
		do
			position := 0
		ensure
			at_start: position = 0
		end

	last
			-- Move position to end (`content_length - 1`).
		do
			if content_length > 0 then
				position := content_length - 1
			else
				position := 0
			end
		ensure
			at_end: content_length > 0 implies position = content_length - 1
		end

feature -- Fluent Builders

	with_position (a_pos: INTEGER): like Current
			-- Scrollbar state with position `a_pos`.
		require
			non_negative: a_pos >= 0
		do
			Result := twin
			Result.set_position (a_pos)
		ensure
			result_is_copy: Result /= Current
		end

	with_content_length (a_len: INTEGER): like Current
			-- Scrollbar state with content length `a_len`.
		require
			non_negative: a_len >= 0
		do
			Result := twin
			Result.set_content_length (a_len)
		ensure
			result_is_copy: Result /= Current
		end

	with_viewport_content_length (a_len: INTEGER): like Current
			-- Scrollbar state with viewport length `a_len`.
		require
			non_negative: a_len >= 0
		do
			Result := twin
			Result.set_viewport_content_length (a_len)
		ensure
			result_is_copy: Result /= Current
		end

invariant
	content_length_non_negative: content_length >= 0
	position_non_negative: position >= 0
	viewport_length_non_negative: viewport_content_length >= 0

end
