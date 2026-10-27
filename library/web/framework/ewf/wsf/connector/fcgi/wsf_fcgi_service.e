note
	description: "[
			Service using FastCGI connector launcher.
		]"
	date: "$Date$"
	revision: "$Revision$"

class
	WSF_FCGI_SERVICE [G -> WSF_EXECUTION create make end]

inherit
	WSF_LAUNCHABLE_SERVICE

feature {NONE} -- Initialization

	launch (opts: detachable WSF_SERVICE_LAUNCHER_OPTIONS)
		local
			l_launcher: WSF_FCGI_SERVICE_LAUNCHER [G]
		do
			create l_launcher.make_and_launch (opts)
		end

note
	copyright: "2011-2026, Jocelyn Fiat, Javier Velilla, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"
end
