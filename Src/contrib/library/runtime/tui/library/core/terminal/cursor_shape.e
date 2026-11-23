note
	description: "[
		Shape of the terminal's hardware cursor, as DECSCUSR (`CSI n SP q`) sets it.
		The seven shapes are crossterm's `SetCursorStyle` variants, with the same codes:
		0 the user's default shape, 1/2 a blinking/steady block, 3/4 a blinking/steady
		underline, 5/6 a blinking/steady bar.
		A FRAME asks for one with `{FRAME}.set_cursor_shape`; TERMINAL writes it when it
		changes and writes the default again when the terminal is restored.
		Not expanded (expanded classes crash the workbench melt in this project): use the
		shared constants below or `make`, and compare with `~`.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	CURSOR_SHAPE

inherit
	ANY
		redefine
			is_equal,
			out
		end

create
	make

feature {NONE} -- Initialization

	make (a_code: NATURAL_8)
			-- Initialize with DECSCUSR code `a_code` (0 .. 6).
		require
			valid_code: is_valid_code (a_code)
		do
			code := a_code
		ensure
			code_set: code = a_code
		end

feature -- Access

	code: NATURAL_8
			-- DECSCUSR parameter: the `n` of `CSI n SP q`

feature -- Status report

	is_default: BOOLEAN
			-- Is this the user's default shape (code 0)?
		do
			Result := code = 0
		ensure
			definition: Result = (code = 0)
		end

	is_blinking: BOOLEAN
			-- Does this shape blink (codes 1, 3, 5)? False for the default shape, whose
			-- blinking is the terminal's choice.
		do
			Result := code \\ 2 = 1
		ensure
			definition: Result = (code = 1 or code = 3 or code = 5)
		end

	is_block: BOOLEAN
			-- Is this a block shape (codes 1, 2)?
		do
			Result := code = 1 or code = 2
		end

	is_underline: BOOLEAN
			-- Is this an underline shape (codes 3, 4)?
		do
			Result := code = 3 or code = 4
		end

	is_bar: BOOLEAN
			-- Is this a bar shape (codes 5, 6)?
		do
			Result := code = 5 or code = 6
		end

	is_valid_code (a_code: NATURAL_8): BOOLEAN
			-- Is `a_code` a DECSCUSR shape code (0 .. 6)?
		do
			Result := a_code <= 6
		ensure
			instance_free: class
		end

feature -- Named shapes (Class features)

	Default_user: CURSOR_SHAPE
			-- The user's default shape (crossterm `DefaultUserShape`, code 0)
		once
			create Result.make (0)
		ensure
			instance_free: class
			is_default: Result.is_default
		end

	Blinking_block: CURSOR_SHAPE
			-- Blinking block (crossterm `BlinkingBlock`, code 1)
		once
			create Result.make (1)
		ensure
			instance_free: class
			code_1: Result.code = 1
		end

	Steady_block: CURSOR_SHAPE
			-- Steady block (crossterm `SteadyBlock`, code 2)
		once
			create Result.make (2)
		ensure
			instance_free: class
			code_2: Result.code = 2
		end

	Blinking_underline: CURSOR_SHAPE
			-- Blinking underline (crossterm `BlinkingUnderScore`, code 3)
		once
			create Result.make (3)
		ensure
			instance_free: class
			code_3: Result.code = 3
		end

	Steady_underline: CURSOR_SHAPE
			-- Steady underline (crossterm `SteadyUnderScore`, code 4)
		once
			create Result.make (4)
		ensure
			instance_free: class
			code_4: Result.code = 4
		end

	Blinking_bar: CURSOR_SHAPE
			-- Blinking bar (crossterm `BlinkingBar`, code 5)
		once
			create Result.make (5)
		ensure
			instance_free: class
			code_5: Result.code = 5
		end

	Steady_bar: CURSOR_SHAPE
			-- Steady bar (crossterm `SteadyBar`, code 6), the usual shape for text entry
		once
			create Result.make (6)
		ensure
			instance_free: class
			code_6: Result.code = 6
		end

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Is `a_other` the same shape?
		do
			Result := code = a_other.code
		ensure then
			same_code: Result = (code = a_other.code)
		end

feature -- Output

	out: STRING_8
			-- crossterm's name for the shape, such as "SteadyBar"
		do
			inspect code
			when 1 then
				Result := "BlinkingBlock"
			when 2 then
				Result := "SteadyBlock"
			when 3 then
				Result := "BlinkingUnderScore"
			when 4 then
				Result := "SteadyUnderScore"
			when 5 then
				Result := "BlinkingBar"
			when 6 then
				Result := "SteadyBar"
			else
				Result := "DefaultUserShape"
			end
		end

invariant
	valid_code: is_valid_code (code)
	one_kind: is_default or is_block or is_underline or is_bar

end
