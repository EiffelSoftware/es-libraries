note
	description: "Summary description for {NATURAL_8_INPUT_STREAM}."
	date: "$Date$"
	revision: "$Revision$"

deferred class
	NATURAL_8_INPUT_STREAM

inherit
	INPUT_STREAM

feature -- Access

	last_byte: NATURAL_8
			-- Last read byte
		deferred
		end

note
	copyright: "Copyright (c) 1984-2012, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"
end
