note
	description: "[
		Levels of a TOAST: `info`, `success`, `warning` and `error`. TUI_TOAST draws each
		level's border in its own style (`TUI_TOAST.level_style`), taken from a TUI_THEME's
		`info`, `success`, `warning` and `error` styles by `TUI_TOAST.with_theme`.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TOAST_LEVEL

feature -- Constants

	info: NATURAL_8 = 1
			-- Something happened; nothing to do.

	success: NATURAL_8 = 2
			-- An action completed.

	warning: NATURAL_8 = 3
			-- Something may need attention.

	error: NATURAL_8 = 4
			-- An action failed.

feature -- Status report

	is_valid (a_level: NATURAL_8): BOOLEAN
			-- Is `a_level` a valid toast level?
		do
			Result := a_level >= info and a_level <= error
		ensure
			instance_free: class
			definition: Result = (a_level = info or a_level = success or a_level = warning or a_level = error)
		end

end
