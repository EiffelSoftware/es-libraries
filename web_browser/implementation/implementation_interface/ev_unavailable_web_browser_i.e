note
	description: "[
			Eiffel Vision web browser.
			Implementation interface for the platforms without supported web engine:
			`is_browser_usable` is False, so the other features are never called.
		]"
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date$"
	revision: "$Revision$"

deferred class
	EV_UNAVAILABLE_WEB_BROWSER_I

inherit
	EV_WEB_BROWSER_I

feature -- Status report

	is_browser_usable: BOOLEAN = False
			-- <Precursor>

	is_loading: BOOLEAN
			-- <Precursor>
		do
		end

	can_go_back: BOOLEAN
			-- <Precursor>
		do
		end

	can_go_forth: BOOLEAN
			-- <Precursor>
		do
		end

feature -- Access

	uri: detachable READABLE_STRING_32
			-- <Precursor>
		do
		end

	title: detachable READABLE_STRING_32
			-- <Precursor>
		do
		end

	zoom_level: REAL_64
			-- <Precursor>
		do
		end

feature -- Element change

	set_zoom_level (a_zoom_level: REAL_64)
			-- <Precursor>
		do
		end

	set_user_agent (a_user_agent: READABLE_STRING_GENERAL)
			-- <Precursor>
		do
		end

	set_developer_tools_enabled (b: BOOLEAN)
			-- <Precursor>
		do
		end

feature -- Basic operations

	load_uri (a_uri: READABLE_STRING_GENERAL)
			-- <Precursor>
		do
		end

	load_html (a_html: READABLE_STRING_GENERAL; a_base_uri: detachable READABLE_STRING_GENERAL)
			-- <Precursor>
		do
		end

	back
			-- <Precursor>
		do
		end

	forth
			-- <Precursor>
		do
		end

	refresh
			-- <Precursor>
		do
		end

	stop
			-- <Precursor>
		do
		end

feature -- Scripting

	execute_script (a_script: READABLE_STRING_GENERAL)
			-- <Precursor>
		do
		end

	add_document_start_script (a_script: READABLE_STRING_GENERAL)
			-- <Precursor>
		do
		end

note
	copyright:	"Copyright (c) 1984-2026, Eiffel Software and others"
	license:	"Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"

end
