note
	description: "[
		TERMINAL whose diff engine tests can inspect (review finding M3).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	INSPECTABLE_TERMINAL

inherit
	TERMINAL [VIRTUAL_TERMINAL]
		export
			{ANY} diff_engine
		end

create
	make

end
