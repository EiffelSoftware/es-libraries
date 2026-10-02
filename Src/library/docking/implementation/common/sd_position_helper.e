note
	description: "Helper to set dialog positions."
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date$"
	revision: "$Revision$"

class
	SD_POSITION_HELPER

create
	make

feature {NONE}  -- Initlization

	make
			-- Creation method
		do
			create internal_shared
		end

feature -- Command

	set_dialog_position (a_dialog: EV_POSITIONABLE; a_prefer_x, a_prefer_y: INTEGER; a_base_height: INTEGER)
			-- Set dialog position base on screen size.
			-- `a_base_height' means the height to minus with y position when impossible showing `a_dialog' at bottom.
		require
			a_dialog_not_void: a_dialog /= Void
		local
			l_screen: EV_SCREEN
			l_rect: EV_RECTANGLE
		do
			create l_screen
				-- Position against the work area of the monitor holding the anchor point,
				-- not against the bounding box of the whole virtual screen. That bounding
				-- box covers gaps that are on no monitor at all whenever the screens differ
				-- in size or alignment, and it includes the space taken by desktop panels.
			l_rect := l_screen.working_area_from_position (a_prefer_x, a_prefer_y)
			if l_rect.has_x_y (a_dialog.width + a_prefer_x, a_dialog.height + a_prefer_y + a_base_height) then
				-- If enough space set position base on left top corner.
				a_dialog.set_position (a_prefer_x, a_prefer_y + a_base_height)
			elseif l_rect.has_x_y (l_rect.right, a_prefer_y + a_dialog.height + a_base_height) then
				-- If enough space set position base on right top corner.
				a_dialog.set_position (l_rect.right - a_dialog.width, a_prefer_y + a_base_height)
			elseif l_rect.has_x_y (a_prefer_x + a_dialog.width, a_prefer_y - a_dialog.height) then
				-- If enough space set position base on left bottom corner.
				a_dialog.set_position (a_prefer_x, a_prefer_y - a_dialog.height)
			elseif l_rect.has_x_y (l_rect.right - a_dialog.width, a_prefer_y - a_dialog.height) then
				-- If enough space set positon base on right bottom corner.
				a_dialog.set_position (l_rect.right - a_dialog.width, a_prefer_y - a_dialog.height)
			else
					-- None of the four corners fits, which happens as soon as the dialog is
					-- larger than the monitor work area. Clamp it into view instead of failing
					-- an assertion and leaving the dialog wherever it happened to be.
				set_position_clamped (a_dialog, a_prefer_x, a_prefer_y + a_base_height, l_rect)
			end
		end

	set_tool_bar_hidden_dialog_position (a_dialog: EV_POSITIONABLE; a_prefer_x, a_prefer_y: INTEGER; a_indicator_width: INTEGER)
			-- Set dialog position for SD_TOOL_BAR_HIDDEN_ITEM_DIALOG.
		require
			not_void: a_dialog /= Void
		local
			l_screen: EV_SCREEN
			l_rect: EV_RECTANGLE
		do
			create l_screen
				-- Position against the work area of the monitor holding the anchor point,
				-- not against the bounding box of the whole virtual screen. That bounding
				-- box covers gaps that are on no monitor at all whenever the screens differ
				-- in size or alignment, and it includes the space taken by desktop panels.
			l_rect := l_screen.working_area_from_position (a_prefer_x, a_prefer_y)
			if l_rect.has_x_y (a_prefer_x - a_dialog.width + a_indicator_width, a_prefer_y + a_dialog.height + internal_shared.tool_bar_size) then
				-- If enough space set position base on right top corner.
				a_dialog.set_position (a_prefer_x - a_dialog.width + a_indicator_width, a_prefer_y + internal_shared.tool_bar_size)
			elseif l_rect.has_x_y (a_dialog.width + a_prefer_x, a_dialog.height + a_prefer_y + internal_shared.tool_bar_size) then
				-- If enough space set position base on left top corner.
				a_dialog.set_position (a_prefer_x, a_prefer_y + internal_shared.tool_bar_size)
			elseif l_rect.has_x_y (a_prefer_x - a_dialog.width + a_indicator_width, a_prefer_y - a_dialog.height) then
				-- If enough space set positon base on right bottom corner.
				a_dialog.set_position (a_prefer_x - a_dialog.width + a_indicator_width, a_prefer_y - a_dialog.height)
			elseif l_rect.has_x_y (a_prefer_x + a_dialog.width, a_prefer_y - a_dialog.height) then
				-- If enough space set position base on left bottom corner.
				a_dialog.set_position (a_prefer_x, a_prefer_y - a_dialog.height)
			else
				-- There's not suitable position.
				a_dialog.set_position (a_prefer_x - a_dialog.width + a_indicator_width, a_prefer_y + internal_shared.tool_bar_size)
			end
		end

	set_tool_bar_hidden_dialog_vertical_position (a_dialog: EV_POSITIONABLE; a_prefer_x, a_prefer_y: INTEGER; a_indicator_width: INTEGER)
			-- Set dialog position for SD_TOOL_BAR_HIDDEN_ITEM_DIALOG.
		require
			not_void: a_dialog /= Void
		local
			l_screen: EV_SCREEN
			l_rect: EV_RECTANGLE
		do
			create l_screen
				-- Position against the work area of the monitor holding the anchor point,
				-- not against the bounding box of the whole virtual screen. That bounding
				-- box covers gaps that are on no monitor at all whenever the screens differ
				-- in size or alignment, and it includes the space taken by desktop panels.
			l_rect := l_screen.working_area_from_position (a_prefer_x, a_prefer_y)
			if l_rect.has_x_y (a_prefer_x - a_dialog.width + internal_shared.tool_bar_size, a_prefer_y + a_dialog.height + a_indicator_width) then
				-- If enough space set position base on right top corner.
				a_dialog.set_position (a_prefer_x - a_dialog.width + internal_shared.tool_bar_size, a_prefer_y + a_indicator_width)
			elseif l_rect.has_x_y (a_dialog.width + a_prefer_x, a_dialog.height + a_prefer_y + a_indicator_width) then
				-- If enough space set position base on left top corner.
				a_dialog.set_position (a_prefer_x, a_prefer_y + a_indicator_width)
			elseif l_rect.has_x_y (a_prefer_x - a_dialog.width + internal_shared.tool_bar_size, a_prefer_y - a_dialog.height) then
				-- If enough space set positon base on right bottom corner.
				a_dialog.set_position (a_prefer_x - a_dialog.width + internal_shared.tool_bar_size, a_prefer_y - a_dialog.height)
			elseif l_rect.has_x_y (a_prefer_x + a_dialog.width, a_prefer_y - a_dialog.height) then
				-- If enough space set position base on left bottom corner.
				a_dialog.set_position (a_prefer_x, a_prefer_y - a_dialog.height)
			else
				-- There's not suitable position.
				a_dialog.set_position (a_prefer_x - a_dialog.width + internal_shared.tool_bar_size, a_prefer_y + a_indicator_width)
			end
		end

	set_tool_bar_floating_dialog_position (a_dialog: EV_POSITIONABLE; a_prefer_x, a_prefer_y: INTEGER; a_indicator_width: INTEGER; a_height: INTEGER)
			-- Set dialog position for SD_TOOL_BAR_HIDDEN_ITEM_DIALOG which is called by SD_FLOATING_TOOL_BAR_ZONE.
		require
			not_void: a_dialog /= Void
		local
			l_screen: EV_SCREEN
			l_rect: EV_RECTANGLE
		do
			create l_screen
				-- Position against the work area of the monitor holding the anchor point,
				-- not against the bounding box of the whole virtual screen. That bounding
				-- box covers gaps that are on no monitor at all whenever the screens differ
				-- in size or alignment, and it includes the space taken by desktop panels.
			l_rect := l_screen.working_area_from_position (a_prefer_x, a_prefer_y)
			if l_rect.has_x_y (a_prefer_x - a_dialog.width + a_indicator_width, a_prefer_y + a_dialog.height + a_height) then
				-- If enough space set position base on right top corner.
				a_dialog.set_position (a_prefer_x - a_dialog.width + a_indicator_width, a_prefer_y + a_height)
			elseif l_rect.has_x_y (a_dialog.width + a_prefer_x, a_dialog.height + a_prefer_y + a_height) then
				-- If enough space set position base on left top corner.
				a_dialog.set_position (a_prefer_x, a_prefer_y + a_height)
			elseif l_rect.has_x_y (a_prefer_x - a_dialog.width + a_indicator_width, a_prefer_y - a_dialog.height) then
				-- If enough space set positon base on right bottom corner.
				a_dialog.set_position (a_prefer_x - a_dialog.width + a_indicator_width, a_prefer_y - a_dialog.height)
			elseif l_rect.has_x_y (a_prefer_x + a_dialog.width, a_prefer_y - a_dialog.height) then
				-- If enough space set position base on left bottom corner.
				a_dialog.set_position (a_prefer_x, a_prefer_y - a_dialog.height)
			else
					-- None of the four corners fits, which happens as soon as the dialog is
					-- larger than the monitor work area. Clamp it into view instead of failing
					-- an assertion and leaving the dialog wherever it happened to be.
				set_position_clamped (a_dialog, a_prefer_x, a_prefer_y + a_height, l_rect)
			end
		end

feature {NONE}  -- Implementation

	set_position_clamped (a_dialog: EV_POSITIONABLE; a_x, a_y: INTEGER; a_area: EV_RECTANGLE)
			-- Position `a_dialog' at (`a_x', `a_y'), pulled back inside `a_area' when it
			-- would otherwise hang over an edge.
		require
			a_dialog_not_void: a_dialog /= Void
			a_area_not_void: a_area /= Void
		do
			a_dialog.set_position (
				a_x.min (a_area.right - a_dialog.width).max (a_area.left),
				a_y.min (a_area.bottom - a_dialog.height).max (a_area.top))
		end

	internal_shared: SD_SHARED;
			-- All singletons.
note
	library:	"SmartDocking: Library of reusable components for Eiffel."
	copyright:	"Copyright (c) 1984-2012, Eiffel Software and others"
	license:	"Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"






end
