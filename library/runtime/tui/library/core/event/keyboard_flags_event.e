note
	description: "[
		Kitty keyboard protocol flags reply `ESC [ ? flags u`, sent by a terminal that
		speaks the protocol in answer to the query `ESC [ ? u` (see
		{ANSI_TERMINAL_BACKEND}.query_keyboard_enhancement). `flags` is the bit set
		in effect: 1 disambiguate escape codes, 2 report event types, 4 report alternate
		keys, 8 report all keys as escape codes, 16 report associated text.
		Outside a query it reaches `process` like any event; applications ignore it.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	KEYBOARD_FLAGS_EVENT

inherit
	EVENT
		redefine
			is_keyboard_flags
		end

create
	make

feature {NONE} -- Initialization

	make (a_flags: NATURAL_8)
			-- Initialize reply reporting `a_flags`.
		do
			flags := a_flags
		ensure
			flags_set: flags = a_flags
		end

feature -- Access

	flags: NATURAL_8
			-- Enhancement flags the terminal reports as in effect

feature -- Status report

	is_keyboard_flags: BOOLEAN = True

end
