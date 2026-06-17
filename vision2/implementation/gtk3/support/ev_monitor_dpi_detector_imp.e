note
	description: "Helper class Monitor DPI gtk3 Implementation "
	date: "$Date$"
	revision: "$Revision$"

class
	EV_MONITOR_DPI_DETECTOR_IMP

inherit
	EV_ANY_HANDLER

	EV_MONITOR_DPI_DETECTOR
		redefine
			scaled_size
		end

feature -- Access

	dpi: NATURAL
			-- <Precursor>
		do
			Result := dpi_cache
		end

	scaled_size (a_size: INTEGER): INTEGER
			-- <Precursor>
		local
			l_dpi: like dpi
		do
			Result := a_size
			l_dpi := dpi
			if l_dpi > 0 then
				Result := (Result * (l_dpi / 96)).rounded
			end
			if attached {EV_APPLICATION_IMP} (create {EV_ENVIRONMENT}).implementation.application_i as l_app_imp then
				Result := (Result * l_app_imp.text_scaling_factor).rounded
			end
		ensure then
			is_class: class
		end

	dpi_cache: NATURAL
		local
			ev: EV_SCREEN_IMP
		once
			create ev.make
			Result := ev.horizontal_resolution.to_natural_32
		ensure
			is_class: class
		end


note
	copyright: "Copyright (c) 1984-2026, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"
end
