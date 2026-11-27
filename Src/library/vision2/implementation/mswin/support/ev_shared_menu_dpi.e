note
	description: "[
			DPI for which owner-drawn menu items are measured and drawn.

			Owner-drawn menu items are measured and drawn in pixels: they have to use
			the menu font for the DPI of the monitor on which the menu is displayed.
		]"
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date$"
	revision: "$Revision$"

class
	EV_SHARED_MENU_DPI

feature {NONE} -- Access

	menu_dpi: NATURAL_32
			-- DPI of the menu being measured or drawn, 0 if unknown (the system DPI is then used).
		do
			Result := menu_dpi_cell.item
		end

	realized_menu_font: WEL_FONT
			-- Font of the menu being measured or drawn, for `menu_dpi'.
		do
			Result := (create {WEL_SHARED_FONTS}).menu_font_for_dpi (menu_dpi)
		ensure
			result_exists: Result /= Void and then Result.exists
		end

feature {NONE} -- Element change

	set_menu_dpi (a_dpi: NATURAL_32)
			-- Set `menu_dpi' to `a_dpi' before measuring or drawing the items of a menu.
		do
			menu_dpi_cell.put (a_dpi)
		ensure
			menu_dpi_set: menu_dpi = a_dpi
		end

feature {NONE} -- Implementation

	menu_dpi_cell: CELL [NATURAL_32]
			-- Storage for `menu_dpi'.
		once
			create Result.put (0)
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
