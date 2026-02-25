note
	description: "Summary description for {BYTE_ARRAY_INPUT_STREAM}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	BYTE_ARRAY_INPUT_STREAM

inherit
	NATURAL_8_INPUT_STREAM

create
	make,
	make_empty

feature {NONE} -- Initialization

	make (a_bytes: ARRAY [NATURAL_8])
		do
			name := {STRING_32} "BYTES"
			source := a_bytes
			count := a_bytes.count
			start
		end

	make_empty
		do
			make (<<{NATURAL_8} 0>>)
		end

feature -- Access

	name: STRING_32
			-- Name of current stream

feature -- Status report

	count: INTEGER

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
			Result := source.valid_index (i)
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

	next
		local
			c: NATURAL_8
--			ch: CHARACTER_8
		do
			if source_index > count then
				end_of_input := True
				column := column + 1
			else
				c := source [source_index]
				source_index := source_index + 1

--				ch := c.to_character_8

				if last_byte = 10 then -- '%N' = 10 = 0xOA
					line := line + 1
					column := 1
				else
					column := column + 1
				end
				last_byte := c
			end
		end

	start
		do
			source_index := 1
			end_of_input := source_index > count
			line := 1
			column := 0
		end

	close
		do
		end

feature {NONE} -- Implementation

	source_index: INTEGER

	source: ARRAY [NATURAL_8]

feature -- Status report

	debug_output: STRING_32
			-- String that should be displayed in debugger to represent `Current'.
		do
			create Result.make_empty
			Result.append_integer (source_index)
			Result.append_character ('/')
			Result.append_integer (source.count)
			Result.append_character (' ')
			Result.append_character ('@')
			Result.append (name)
		end

invariant
	source_attached: source /= Void

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
