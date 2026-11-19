note
	description: "[
		Window title escape sequences and the sanitizing they need (P2 T2).

		Sequence: OSC 0 with a BEL terminator, `ESC ] 0 ; title BEL`, as crossterm's `SetTitle`
		writes it. OSC 0 sets the icon name and the window title; OSC 2 would set the window
		title alone. OSC 0 was kept because it is what crossterm (and so Ratatui apps) send,
		and because terminals that show a tab or icon name then show the same text as the
		window title instead of a stale one.

		Title stack (XTWINOPS): `CSI 22 ; 0 t` saves the terminal's icon name and window title,
		`CSI 23 ; 0 t` brings them back. Parameter 0 matches OSC 0 (both names). Terminals that
		keep the stack (xterm, VTE-based terminals, kitty, WezTerm: not checked here) show the
		shell's title again after the pop. Terminals without it ignore both, and the
		application's title stays after it ends, as it does for any crossterm application:
		an application cannot read the title back to restore it.

		Sanitizing: a title is text, not escape sequences. C0 controls (U+0000 .. U+001F),
		DEL (U+007F) and C1 controls (U+0080 .. U+009F) are dropped before it is sent. A BEL,
		an `ESC \` or a C1 ST (U+009C) inside would end the OSC early, and the rest of the title
		would be read by the terminal as escape sequences. A STRING_8 title is read as code
		points (Latin-1), as Eiffel's string conversions do; pass other text as STRING_32.
		Encoded as UTF-8 on the way out ({ANSI_TERMINAL_BACKEND}.set_title).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	WINDOW_TITLE

feature -- Sanitizing

	sanitized (a_title: READABLE_STRING_GENERAL): STRING_32
			-- `a_title` without the characters that could end or change the OSC sequence
			-- (`is_dropped_code`: C0 controls, DEL, C1 controls). Everything else is kept, in order.
		require
			title_attached: a_title /= Void
		local
			i: INTEGER
			l_code: NATURAL_32
		do
			create Result.make (a_title.count)
			from
				i := 1
			until
				i > a_title.count
			loop
				l_code := a_title.code (i)
				if not is_dropped_code (l_code) then
					Result.append_code (l_code)
				end
				i := i + 1
			end
		ensure
			instance_free: class
			no_control_left: is_sanitized (Result)
			only_controls_dropped: Result.count = a_title.count - dropped_count (a_title)
		end

	is_sanitized (a_title: READABLE_STRING_GENERAL): BOOLEAN
			-- Does `a_title` contain no character that `sanitized` drops?
		require
			title_attached: a_title /= Void
		do
			Result := dropped_count (a_title) = 0
		ensure
			instance_free: class
			definition: Result = across 1 |..| a_title.count as i all not is_dropped_code (a_title.code (i)) end
		end

	dropped_count (a_title: READABLE_STRING_GENERAL): INTEGER
			-- Number of characters of `a_title` that `sanitized` drops
		require
			title_attached: a_title /= Void
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > a_title.count
			loop
				if is_dropped_code (a_title.code (i)) then
					Result := Result + 1
				end
				i := i + 1
			end
		ensure
			instance_free: class
			in_range: Result >= 0 and Result <= a_title.count
		end

	is_dropped_code (a_code: NATURAL_32): BOOLEAN
			-- Is `a_code` a C0 control (U+0000 .. U+001F), DEL (U+007F) or a C1 control
			-- (U+0080 .. U+009F)?
		do
			Result := a_code < 0x20 or (a_code >= 0x7F and a_code <= 0x9F)
		ensure
			instance_free: class
			definition: Result = (a_code <= 0x1F or (0x7F <= a_code and a_code <= 0x9F))
		end

feature -- Escape sequences

	Set_title_prefix: STRING_8 = "%/27/]0;"
			-- OSC 0: what comes before the UTF-8 title

	Set_title_terminator: STRING_8 = "%/7/"
			-- BEL: what ends the OSC (crossterm's terminator)

	Push_title: STRING_8 = "%/27/[22;0t"
			-- XTWINOPS 22 ; 0: save the icon name and window title on the terminal's stack

	Pop_title: STRING_8 = "%/27/[23;0t"
			-- XTWINOPS 23 ; 0: restore the icon name and window title saved last

end
