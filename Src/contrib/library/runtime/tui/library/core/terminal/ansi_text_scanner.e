note
	description: "[
		Incremental scanner of terminal output: separates printable text from escape sequences
		so that backends can track the cursor the way the terminal will move it.

		Recognized: CSI sequences (`ESC [ ... final`), of which cursor positioning
		(`ESC [ row ; col H` / `f`, with omitted parameters defaulting to 1) is reported;
		OSC strings (`ESC ] ... BEL` or `ESC ] ... ESC \`); and two-character escapes (`ESC x`).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	ANSI_TEXT_SCANNER

create
	make

feature {NONE} -- Initialization

	make
			-- Start in text state.
		do
			create parameters.make (16)
			state := State_text
			last_kind := Kind_text
		ensure
			in_text: not is_in_sequence
		end

feature -- Access

	last_kind: INTEGER
			-- Classification of the code point last passed to `feed`

	last_row, last_column: INTEGER
			-- 0-based cursor position requested by the last `Kind_cursor_position` sequence

	Kind_text: INTEGER = 1
			-- A code point that the terminal prints or interprets as text control (LF, CR, ...)

	Kind_sequence: INTEGER = 2
			-- Part of an escape sequence with no cursor effect tracked here

	Kind_cursor_position: INTEGER = 3
			-- Final byte of a cursor position sequence; see `last_row`, `last_column`

feature -- Status report

	is_in_sequence: BOOLEAN
			-- Is an escape sequence in progress?
		do
			Result := state /= State_text
		end

feature -- Basic operations

	feed (a_code: NATURAL_32)
			-- Classify code point `a_code` into `last_kind`.
		do
			last_kind := Kind_sequence
			inspect state
			when State_text then
				if a_code = 27 then
					state := State_escape
				else
					last_kind := Kind_text
				end
			when State_escape then
				if a_code = 91 then -- '['
					parameters.wipe_out
					state := State_csi
				elseif a_code = 93 then -- ']'
					state := State_osc
				else
					state := State_text
				end
			when State_csi then
				if a_code >= 64 and a_code <= 126 then
					if a_code = 72 or a_code = 102 then -- 'H' or 'f'
						parse_position
						last_kind := Kind_cursor_position
					end
					state := State_text
				elseif parameters.count < Max_parameters then
					parameters.append_code (a_code)
				end
			when State_osc then
				if a_code = 7 then
					state := State_text
				elseif a_code = 27 then
					state := State_osc_escape
				end
			when State_osc_escape then
				if a_code = 92 then -- '\' completes ST
					state := State_text
				else
					state := State_osc
				end
			end
		end

feature {NONE} -- Implementation

	state: INTEGER
			-- Current scanner state

	parameters: STRING_8
			-- Parameter bytes of the CSI sequence in progress

	parse_position
			-- Set `last_row`, `last_column` from `parameters` ("r;c", "r", ";c" or "").
		local
			l_semi: INTEGER
			l_row, l_col: STRING_8
		do
			l_semi := parameters.index_of (';', 1)
			if l_semi > 0 then
				l_row := parameters.substring (1, l_semi - 1)
				l_col := parameters.substring (l_semi + 1, parameters.count)
			else
				l_row := parameters
				l_col := ""
			end
			last_row := number_or_one (l_row) - 1
			last_column := number_or_one (l_col) - 1
		ensure
			non_negative: last_row >= 0 and last_column >= 0
		end

	number_or_one (a_text: STRING_8): INTEGER
			-- Value of `a_text`, or 1 when it is empty, zero or not a number (VT default).
		do
			if a_text.is_integer then
				Result := a_text.to_integer
			end
			if Result < 1 then
				Result := 1
			end
		ensure
			positive: Result >= 1
		end

	State_text: INTEGER = 0
	State_escape: INTEGER = 1
	State_csi: INTEGER = 2
	State_osc: INTEGER = 3
	State_osc_escape: INTEGER = 4

	Max_parameters: INTEGER = 32
			-- Longest CSI parameter string kept

invariant
	valid_kind: last_kind >= Kind_text and last_kind <= Kind_cursor_position

end
