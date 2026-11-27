note
	description: "Helper class Monitor DPI windows Implementation "
	date: "$Date$"
	revision: "$Revision$"

class
	EV_MONITOR_DPI_DETECTOR_IMP

inherit
	EV_ANY_HANDLER

	EV_MONITOR_DPI_DETECTOR
		redefine
			dpi_of,
			font_dpi,
			font_for_dpi
		end

feature -- Access

	dpi: NATURAL
			-- <Precursor>
			--
			-- DPI of the monitor of the active window of the application, since new
			-- windows and widgets are usually displayed next to it, or else of the
			-- primary monitor.
			-- Use `{EV_POSITIONED}.dpi' to get the DPI of a given window or widget.
			--
			--| The process is per monitor DPI aware (see `{EV_APPLICATION_IMP}.make'):
			--| sizes are in pixels of the monitor on which a window is displayed.
		local
			l_window: POINTER
		do
			l_window := c_active_window
			if l_window.is_default_pointer then
				Result := {WEL_SCALING_EXTERNALS}.primary_monitor_dpi
			else
				Result := {WEL_SCALING_EXTERNALS}.dpi_for_window (l_window)
			end
		ensure then
			is_class: class
		end

	dpi_of (a_positioned: EV_POSITIONED_I): NATURAL
			-- <Precursor>
		do
			if attached {EV_WIDGET_IMP} a_positioned as l_widget and then l_widget.exists then
				Result := {WEL_SCALING_EXTERNALS}.dpi_for_window (l_widget.wel_item)
			else
				Result := dpi
			end
		ensure then
			is_class: class
		end

	font_dpi: NATURAL
			-- <Precursor>
			--| Fonts are realized for the system DPI.
		do
			Result := {WEL_SCALING_EXTERNALS}.system_dpi
		ensure then
			is_class: class
		end

	font_for_dpi (a_font: EV_FONT; a_dpi: NATURAL): EV_FONT
			-- <Precursor>
			--| Fonts are realized for the system DPI: their size in pixels is scaled.
		do
			Result := a_font.twin
			if a_dpi > 0 and then attached {EV_FONT_IMP} Result.implementation as l_font_imp then
				l_font_imp.scale_to_dpi (a_dpi)
			end
		ensure then
			is_class: class
		end

feature {NONE} -- Externals

	c_active_window: POINTER
			-- SDK GetActiveWindow: active window of the calling thread, if any.
		external
			"C inline use <windows.h>"
		alias
			"return (EIF_POINTER) GetActiveWindow ();"
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
