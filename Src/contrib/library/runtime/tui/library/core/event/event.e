note
	description: "[
		Deferred base class for all asynchronous user, terminal, and system events.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	EVENT

feature -- Status report

	is_key: BOOLEAN
			-- Is this a keyboard event?
		do
			Result := False
		end

	is_mouse: BOOLEAN
			-- Is this a mouse event?
		do
			Result := False
		end

	is_resize: BOOLEAN
			-- Is this a terminal window resize event?
		do
			Result := False
		end

	is_tick: BOOLEAN
			-- Is this a periodic timer tick event?
		do
			Result := False
		end

	is_paste: BOOLEAN
			-- Is this a bracketed paste event?
		do
			Result := False
		end

	is_focus: BOOLEAN
			-- Is this a focus gained/lost event?
		do
			Result := False
		end

	is_cursor_position: BOOLEAN
			-- Is this a cursor position report (answer to DSR `ESC [ 6 n`)?
		do
			Result := False
		end

end
