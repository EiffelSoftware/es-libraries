note
	description: "[
		How DIFF_ENGINE treats a cell (Ratatui `CellDiffOption`, 0.30.1).
		The option of a cell is set with {BUFFER}.set_diff_option and read as
		{TERMINAL_CELL}.diff_option (and {TERMINAL_CELL}.forced_width for `Forced_width`).

		  * `None`: the cell is written when it looks different from the previous frame.
		  * `Skip`: the cell is never written. Use it for cells that something outside the
		    buffer covers: the text of an OSC 8 sequence held by an earlier cell, an image.
		  * `Always_update`: the cell is written in every frame, even when it looks the same.
		    Use it where another renderer (an image pipeline) may draw over the cell.
		  * `Forced_width`: the cell counts as `forced_width` columns whatever its symbol's
		    width, and the next `forced_width - 1` cells of its row are not written. Use it
		    for a symbol that holds an escape sequence and the text it draws.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	CELL_DIFF_OPTION

feature -- Constants

	None: NATURAL_8 = 0
			-- No option: write the cell when it changes (default)

	Skip: NATURAL_8 = 1
			-- Never write the cell

	Always_update: NATURAL_8 = 2
			-- Write the cell in every frame

	Forced_width: NATURAL_8 = 3
			-- The cell covers {TERMINAL_CELL}.forced_width columns

feature -- Status report

	is_valid (a_option: NATURAL_8): BOOLEAN
			-- Is `a_option` one of the options above?
		do
			Result := a_option <= Forced_width
		ensure
			instance_free: class
			definition: Result = (a_option = None or a_option = Skip or a_option = Always_update or a_option = Forced_width)
		end

	is_valid_width (a_option, a_width: NATURAL_8): BOOLEAN
			-- Is `a_width` a valid forced width for `a_option`: at least 1 for `Forced_width`,
			-- 0 for every other option?
		do
			Result := (a_option = Forced_width) = (a_width > 0)
		ensure
			instance_free: class
		end

end
