note
	description: "GTK 3 implementation of SD_HOT_ZONE_FACTORY_FACTORY."
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date$"
	revision: "$Revision$"

class
	SD_HOT_ZONE_FACTORY_FACTORY_IMP

inherit
	SD_HOT_ZONE_FACTORY_FACTORY

feature -- Hot zone factory

	hot_zone_factory (m: SD_DOCKER_MEDIATOR): SD_HOT_ZONE_ABSTRACT_FACTORY
			-- <Precursor>
			--| The indicator style, with the arrows and the translucent area, needs
			--| windows whose transparent parts show the screen, hence a compositing
			--| manager. Without one they would come up as opaque rectangles, so the
			--| outline style, drawn on the screen itself, is used instead. Setting
			--| SD_FEEDBACK_STYLE to "outline" forces it.
		do
			if is_transparency_supported then
				create {SD_HOT_ZONE_TRIANGLE_FACTORY} Result.make (m)
			else
				create {SD_HOT_ZONE_OLD_FACTORY} Result.make (m)
			end
		end

feature {NONE} -- Implementation

	is_transparency_supported: BOOLEAN
			-- Can windows with transparent parts be shown?
		local
			l_screen: POINTER
		do
			if
				attached {EXECUTION_ENVIRONMENT}.item ("SD_FEEDBACK_STYLE") as l_style and then
				l_style.is_case_insensitive_equal_general ("outline")
			then
				Result := False
			else
				l_screen := {GDK}.gdk_screen_get_default
				Result :=
					not l_screen.is_default_pointer and then
					not {GDK}.gdk_screen_get_rgba_visual (l_screen).is_default_pointer and then
					{GDK}.gdk_screen_is_composited (l_screen)
			end
		end

note
	library:	"SmartDocking: Library of reusable components for Eiffel."
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
