note
	description: "Helper class Monitor DPI gtk3 Implementation "
	date: "$Date$"
	revision: "$Revision$"

class
	EV_MONITOR_DPI_DETECTOR_IMP

inherit
	EV_ANY_HANDLER

	EV_MONITOR_DPI_DETECTOR

feature -- Access

	dpi: NATURAL
			-- <Precursor>
			--
			-- Logical resolution of the display (see `{EV_SCREEN_IMP}.logical_resolution'):
			-- 96 unless the user enlarged the text, whatever the GDK scale factor.
			--
			--| Everything this is used to compute -- `scaled_size', the icon size an
			--| application picks -- ends up as a logical size, which GTK multiplies by
			--| its scale factor when it renders. Reporting the device resolution here
			--| (288 on a 3x display) scaled all of it twice: EiffelStudio loaded its
			--| 32x32 icons and GTK showed them at 96x96 device pixels.
			--|
			--| Not cached: the text scaling can change at run time.
		do
			Result := screen_detector.logical_resolution.to_natural_32
		ensure then
			is_class: class
		end

feature {NONE} -- Implementation

	screen_detector: EV_SCREEN_IMP
			-- Reusable screen object used to query the display resolution.
			--| The object is created once because `{EV_SCREEN_IMP}.make' needs the
			--| application to exist; the resolution it reports is re-read on every call.
		once
			create Result.make
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
