note
	description: "[
		Text wrapping mode constants and validation.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEXT_WRAP_MODE

feature -- Constants

	none: NATURAL_8 = 0
			-- No wrapping; text exceeding the boundary is clipped.

	character: NATURAL_8 = 1
			-- Wrap at character boundaries.

	word: NATURAL_8 = 2
			-- Wrap at word (whitespace) boundaries where possible.

feature -- Status report

	is_valid (a_mode: NATURAL_8): BOOLEAN
			-- Is `a_mode` a supported wrapping mode?
		do
			Result := a_mode = none or a_mode = character or a_mode = word
		ensure
			instance_free: class
		end

end
