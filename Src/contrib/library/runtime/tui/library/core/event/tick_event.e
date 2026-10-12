note
	description: "[
		Timer tick pulse event for frame rendering and periodic updates.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TICK_EVENT

inherit
	EVENT
		redefine
			is_tick
		end

create
	default_create

feature -- Status report

	is_tick: BOOLEAN = True

end
