note
	description: "[
			Parameters used by CMS_HOOK_EXPORT subscribers.
		]"
	date: "$Date$"
	revision: "$Revision$"

class
	CMS_EXPORT_CONTEXT

inherit
	CMS_HOOK_CONTEXT_WITH_LOG
		rename
			make as make_context
		end

create
	make

feature {NONE} -- Initialization

	make (a_location: PATH)
		do
			location := a_location
			make_context
		end

feature -- Access

	location: PATH
			-- Location of export folder.		

invariant

note
	copyright: "2011-2024, Jocelyn Fiat, Javier Velilla, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
end
