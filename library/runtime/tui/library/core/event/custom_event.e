note
	description: "[
		Application-defined event with an optional payload.
		Worker threads post these via {TUI_APPLICATION}.post_event so the main
		loop can wake and process typed results without polling shared state.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	CUSTOM_EVENT

inherit
	EVENT
		redefine
			is_custom
		end

create
	make,
	make_with_payload

feature {NONE} -- Initialization

	make
			-- Initialize with no payload.
		do
			payload := Void
		ensure
			no_payload: payload = Void
		end

	make_with_payload (a_payload: detachable ANY)
			-- Initialize carrying `a_payload`.
		do
			payload := a_payload
		ensure
			payload_set: payload = a_payload
		end

feature -- Access

	payload: detachable ANY
			-- Application-defined result or token carried by this event

feature -- Status report

	is_custom: BOOLEAN = True

end
