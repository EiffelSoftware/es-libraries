note
	description: "Summary description for {POINTER_NATURAL_8_INPUT_STREAM}."
	date: "$Date$"
	revision: "$Revision$"

class
	POINTER_NATURAL_8_INPUT_STREAM

inherit
	NATURAL_8_INPUT_STREAM

create
	make,
	make_empty

feature {NONE} -- Initialization

	make (a_ptr: POINTER)
		do
			name := {STRING_32} "POINTER"
			source := a_ptr
			-- count := a_bytes.count
			start
		end

	make_empty
		do
			make (Default_pointer)
		end

feature -- Access

	name: STRING_32
			-- Name of current stream

feature -- Status report

	-- count: INTEGER

	end_of_input: BOOLEAN
			-- <Precursor>
			-- i.e: index over upper index

	is_open_read: BOOLEAN
			-- Can items be read from input stream?
		do
			Result := True
		end

	valid_index (i: INTEGER): BOOLEAN
		do
			Result := True
		end

feature -- Access

	index: INTEGER
		do
			Result := source_index - 1
		end

	line: INTEGER

	column: INTEGER

	last_byte: NATURAL_8

feature -- Change

	set_name (s: like name)
			-- Set input `name' to `s'.
		do
			name := s
		end

feature -- Basic operation

	item (idx: INTEGER): NATURAL_8
		do
			($Result).memory_copy (source + (idx - 1), 1)
		end

	next
		local
			c: NATURAL_8
		do
			($c).memory_copy (source + (source_index - 1), 1)
			source_index := source_index + 1

			if last_byte = 10 then -- '%N' = 10 = 0xOA
				line := line + 1
				column := 1
			else
				column := column + 1
			end
			last_byte := c
		end

	start
		do
			source_index := 1
			end_of_input := False --source_index > count
			line := 1
			column := 0
		end

	close
		do
		end

feature {NONE} -- Implementation

	source_index: INTEGER

	source: POINTER

feature -- Status report

	debug_output: STRING_32
			-- String that should be displayed in debugger to represent `Current'.
		do
			create Result.make_empty
			Result.append_integer (source_index)
			Result.append_character (' ')
			Result.append_character ('@')
			Result.append (name)
		end

invariant
	source_attached: not source.is_default_pointer

note
	copyright: "Copyright (c) 1984-2014, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"
end
