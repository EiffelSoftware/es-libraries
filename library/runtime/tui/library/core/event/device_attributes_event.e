note
	description: "[
		Primary device attributes (DA1) reply `ESC [ ? p1 ; p2 ; ... c`, sent in answer to
		`ESC [ c`. Every VT-compatible terminal answers it, so {ANSI_TERMINAL_BACKEND}
		.query_keyboard_enhancement sends it after the Kitty flags query as a fence: a
		DA1 reply with no flags reply before it means the terminal lacks the protocol.
		`parameters` are the reply's numbers in order (a parameter that is empty or not a
		decimal number is 0). Outside a query it reaches `process` like any event;
		applications ignore it.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	DEVICE_ATTRIBUTES_EVENT

inherit
	EVENT
		redefine
			is_device_attributes
		end

create
	make

feature {NONE} -- Initialization

	make (a_parameters: like parameters)
			-- Initialize reply with `a_parameters`.
		require
			parameters_attached: a_parameters /= Void
		do
			parameters := a_parameters
		ensure
			parameters_set: parameters = a_parameters
		end

feature -- Access

	parameters: ARRAYED_LIST [INTEGER]
			-- Numbers of the reply, in order (first: the conformance level, e.g. 62)

feature -- Status report

	is_device_attributes: BOOLEAN = True

invariant
	parameters_attached: parameters /= Void
	non_negative: across parameters as p all p >= 0 end

end
