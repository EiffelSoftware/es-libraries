note
	description: "[
			Eiffel Vision web browser. GTK2 implementation.
			No supported web engine is available with GTK2: a label is displayed instead,
			and `is_browser_usable` is False.
		]"
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date$"
	revision: "$Revision$"

class
	EV_WEB_BROWSER_IMP

inherit
	EV_UNAVAILABLE_WEB_BROWSER_I
		redefine
			interface
		end

	EV_PRIMITIVE_IMP
		redefine
			interface,
			make
		end

create
	make

feature {NONE} -- Initialization

	make
			-- <Precursor>
		local
			l_label: EV_GTK_C_STRING
		do
				-- Make sure that gtk backend is initialized first.
			app_implementation.do_nothing
			create l_label.set_with_eiffel_string ("No web engine is available with GTK2.")
			set_c_object ({GTK}.gtk_label_new (l_label.item))
			Precursor {EV_PRIMITIVE_IMP}
		end

	old_make (an_interface: attached like interface)
			-- <Precursor>
		do
			assign_interface (an_interface)
		end

feature {EV_ANY, EV_ANY_I} -- Implementation

	interface: detachable EV_WEB_BROWSER note option: stable attribute end
			-- <Precursor>

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
