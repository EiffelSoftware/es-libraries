note
	description: "[
		Parser of a Server-Sent Events stream: the text received in parts is split into events
		(name and data, the data lines joined by new lines), available in `events'.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	AI_SSE_PARSER

create
	make

feature {NONE} -- Initialization

	make
			-- Parser waiting for the first event.
		do
			create buffer.make (1024)
			create event_name.make_empty
			create event_data.make_empty
			create events.make (4)
		end

feature -- Access

	events: ARRAYED_LIST [TUPLE [name: STRING_8; data: STRING_8]]
			-- Events completed, not yet taken (see `wipe_out_events')

feature -- Basic operations

	feed (s: READABLE_STRING_8)
			-- Process the next part `s' of the stream.
		local
			i, j: INTEGER
			l_line: STRING_8
		do
			buffer.append (s)
			from
				i := 1
				j := buffer.index_of ('%N', i)
			until
				j = 0
			loop
				l_line := buffer.substring (i, j - 1)
				if not l_line.is_empty and then l_line [l_line.count] = '%R' then
					l_line.remove_tail (1)
				end
				process_line (l_line)
				i := j + 1
				j := buffer.index_of ('%N', i)
			end
			buffer.remove_head (i - 1)
		end

	finish
			-- The stream ended: dispatch the last event if not ended by an empty line.
		do
			if not buffer.is_empty then
				process_line (buffer.twin)
				buffer.wipe_out
			end
			process_line ("")
		end

	wipe_out_events
			-- Forget the events taken.
		do
			events.wipe_out
		ensure
			no_events: events.is_empty
		end

feature {NONE} -- Implementation

	buffer: STRING_8
			-- Text received, not yet split into lines

	event_name: STRING_8
			-- Name of the event being read

	event_data: STRING_8
			-- Data of the event being read

	has_data: BOOLEAN
			-- Has the event being read some data?

	process_line (a_line: STRING_8)
			-- Process line `a_line' (without its end).
		local
			i: INTEGER
			l_field, l_value: STRING_8
		do
			if a_line.is_empty then
					-- End of an event.
				if has_data then
					events.extend ([event_name.twin, event_data.twin])
				end
				event_name.wipe_out
				event_data.wipe_out
				has_data := False
			elseif a_line [1] = ':' then
					-- A comment.
			else
				i := a_line.index_of (':', 1)
				if i = 0 then
					l_field := a_line
					create l_value.make_empty
				else
					l_field := a_line.substring (1, i - 1)
					l_value := a_line.substring (i + 1, a_line.count)
					if not l_value.is_empty and then l_value [1] = ' ' then
						l_value.remove_head (1)
					end
				end
				if l_field.same_string ("event") then
					event_name := l_value
				elseif l_field.same_string ("data") then
					if has_data then
						event_data.append_character ('%N')
					end
					event_data.append (l_value)
					has_data := True
				end
			end
		end

note
	copyright: "Copyright (c) 1984-2026, Eiffel Software"
	license: "GPL version 2 (see http://www.eiffel.com/licensing/gpl.txt)"
	licensing_options: "http://www.eiffel.com/licensing"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"

end
