note
	description: "[
		Terminal focus gained or lost event.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	FOCUS_EVENT

inherit
	EVENT
		redefine
			is_focus
		end

create
	make_gained,
	make_lost

feature {NONE} -- Initialization

	make_gained
			-- Initialize as focus gained event.
		do
			has_focus := True
		ensure
			has_focus: has_focus
		end

	make_lost
			-- Initialize as focus lost event.
		do
			has_focus := False
		ensure
			lost_focus: not has_focus
		end

feature -- Access

	has_focus: BOOLEAN
			-- Did terminal gain focus (True) or lose focus (False)?

feature -- Status report

	is_focus: BOOLEAN = True

end
