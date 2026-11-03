note
	description: "Helper class to detect the Monitor DPI"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	EV_MONITOR_DPI_DETECTOR

feature --Access

	dpi: NATURAL
			-- Return the dots per inch (dpi) of the monitor
			-- DPI sizes 96, 120, 144, 192, etc.
		deferred
		ensure
			instance_free: class
		end

	dpi_of (a_positioned: EV_POSITIONED_I): NATURAL
			-- Dots per inch (dpi) of the monitor on which `a_positioned' is displayed.
			--| By default, the `dpi' of the display, for platforms where it does not
			--| depend on the monitor.
		do
			Result := dpi
		ensure
			instance_free: class
		end

	font_dpi: NATURAL
			-- DPI for which the size in pixels of fonts is given by default:
			-- `font_for_dpi' only changes the size of a font for another DPI.
		do
			Result := dpi
		ensure
			instance_free: class
		end

	font_for_dpi (a_font: EV_FONT; a_dpi: NATURAL): EV_FONT
			-- New font like `a_font', with the size it has to have on a monitor with `a_dpi' dpi.
			-- Use it to draw text, and to compute the size of text, in a widget displayed with
			-- `a_dpi' (see `{EV_POSITIONED}.dpi' and `{EV_WIDGET}.dpi_changed_actions').
			--| By default, a copy of `a_font', for platforms where the size of fonts in pixels
			--| does not depend on the monitor.
		do
			Result := a_font.twin
		ensure
			instance_free: class
			result_attached: Result /= Void
			new_font: Result /= a_font
		end

	scaled_size (a_size: INTEGER): INTEGER
			-- Scaled size of `a_size`.
		local
			l_dpi: like dpi
		do
			Result := a_size
			l_dpi := dpi
			if l_dpi > 0 then
				Result := (Result * (dpi / 96)).rounded
			end
		ensure
			instance_free: class
		end
note
	copyright: "Copyright (c) 1984-2019, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"
end
