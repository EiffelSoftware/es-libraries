note
	description: "[
		Kinds of a TUI_DIALOG: `info`, `warning`, `error` and `question`. TUI_DIALOG draws the
		box's border in the kind's style (`TUI_DIALOG.kind_style`), taken from a TUI_THEME's
		`info`, `warning`, `error` and `primary` styles by `TUI_DIALOG.with_theme`, as
		TUI_TOAST does with a TOAST_LEVEL.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	DIALOG_KIND

feature -- Constants

	info: NATURAL_8 = 1
			-- Something to know; the default kind.

	warning: NATURAL_8 = 2
			-- Something may need attention.

	error: NATURAL_8 = 3
			-- Something failed.

	question: NATURAL_8 = 4
			-- The user is asked to choose.

feature -- Status report

	is_valid (a_kind: NATURAL_8): BOOLEAN
			-- Is `a_kind` a valid dialog kind?
		do
			Result := a_kind >= info and a_kind <= question
		ensure
			instance_free: class
			definition: Result = (a_kind = info or a_kind = warning or a_kind = error or a_kind = question)
		end

end
