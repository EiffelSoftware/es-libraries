note
	description: "[
			Default icons for Smart Docking library.
			The icons are scaled for the DPI of the monitor of the docking managers (see `update_for_dpi'):
			the icons given are shared and updated in place when the DPI changes.
		]"
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date$"
	revision: "$Revision$"

class
	SD_DEFAULT_ICONS

inherit
	SD_ICONS_SINGLETON
		redefine
			dpi,
			update_for_dpi,
			stick_buffer,
			unstick_buffer,
			maximize_buffer,
			minimize_buffer,
			normal_buffer,
			close_buffer,
			tool_bar_dropdown_buffer,
			tool_bar_indicator_buffer,
			hide_tab_indicator,
			editor_area
		end

create
	make

feature {NONE} -- Initlization

	make
			-- Creation method
		do
			dpi := {EV_MONITOR_DPI_DETECTOR_IMP}.dpi
			if dpi = 0 then
				dpi := 96
			end
			create shared_pixmaps.make (20)
			create shared_buffers.make (30)
		end

feature -- Access

	dpi: NATURAL
			-- <Precursor>

feature -- Element change

	update_for_dpi (a_dpi: NATURAL)
			-- <Precursor>
			-- Update the content of the icons already given.
		do
			if a_dpi /= dpi then
				dpi := a_dpi
				from
					shared_pixmaps.start
				until
					shared_pixmaps.after
				loop
					shared_pixmaps.item_for_iteration.copy (scaled_buffer (source_buffer (shared_pixmaps.key_for_iteration)).to_pixmap)
					shared_pixmaps.forth
				end
				from
					shared_buffers.start
				until
					shared_buffers.after
				loop
					shared_buffers.item_for_iteration.set_with_pixel_buffer (scaled_buffer (source_buffer (shared_buffers.key_for_iteration)))
					shared_buffers.forth
				end
				if attached internal_tool_bar_separator_icon as l_separator then
					l_separator.copy (new_tool_bar_separator_icon)
				end
			end
		end

feature -- Implementation

	unstick: EV_PIXMAP
			-- <Precursor>
		do
			Result := shared_pixmap (unstick_name)
		end

	unstick_buffer: EV_PIXEL_BUFFER
			-- <Precursor>
		do
			Result := shared_buffer (unstick_name)
		end

	stick: 	EV_PIXMAP
			-- <Precursor>
		do
			Result := shared_pixmap (stick_name)
		end

	stick_buffer: EV_PIXEL_BUFFER
			-- <Precursor>
		do
			Result := shared_buffer (stick_name)
		end

	minimize: EV_PIXMAP
			-- <Precursor>
		do
			Result := shared_pixmap (minimize_name)
		end

	minimize_buffer: EV_PIXEL_BUFFER
			-- <Precursor>
		do
			Result := shared_buffer (minimize_name)
		end

	maximize: EV_PIXMAP
			-- <Precursor>
		do
			Result := shared_pixmap (maximize_name)
		end

	maximize_buffer: EV_PIXEL_BUFFER
			-- <Precursor>
		do
			Result := shared_buffer (maximize_name)
		end

	normal: EV_PIXMAP
			-- <Precursor>
		do
			Result := shared_pixmap (normal_name)
		end

	normal_buffer: EV_PIXEL_BUFFER
			-- <Precursor>
		do
			Result := shared_buffer (normal_name)
		end

	close: EV_PIXMAP
			-- <Precursor>
		do
			Result := shared_pixmap (close_name)
		end

	close_buffer: EV_PIXEL_BUFFER
			-- <Precursor>
		do
			Result := shared_buffer (close_name)
		end

	hide_tab_indicator_buffer (a_hide_number: INTEGER): EV_PIXEL_BUFFER
			-- <Precursor>
		local
			l_font: EV_FONT
			l_point: EV_COORDINATE
		do
			if a_hide_number < 10 then
				create Result.make_with_size (scaled_size (18), scaled_size (16))
			elseif a_hide_number < 100 then
				create Result.make_with_size (scaled_size (21), scaled_size (16))
			else
				create Result.make_with_size (scaled_size (24), scaled_size (16))
			end

			Result.draw_pixel_buffer_with_x_y (0, 0, scaled_buffer (icons_10_10.tool_bar_hidden_dropdown_small_icon_buffer))

			create l_font
			l_font.set_height_in_points (7)
			l_font.set_family ({EV_FONT_CONSTANTS}.family_roman)
			l_font := {EV_MONITOR_DPI_DETECTOR_IMP}.font_for_dpi (l_font, dpi)

			if a_hide_number < 10 then
				create l_point.make (Result.width - scaled_size (8), scaled_size (2))
			elseif a_hide_number < 100 then
				create l_point.make (Result.width - scaled_size (12), scaled_size (2))
			else
				create l_point.make (Result.width - scaled_size (16), scaled_size (2))
			end

			Result.draw_text (a_hide_number.out, l_font, l_point)
		end

	hide_tab_indicator (a_hide_number: INTEGER): EV_PIXMAP
			-- <Precursor>
		local
			l_font: EV_FONT
		do
				-- Create the pixmap with its final size, and then draw the indicator icon,
				-- since resizing a pixmap does not keep its content (at least with GTK3).
			if a_hide_number < 10 then
				create Result.make_with_size (scaled_size (18), scaled_size (16))
			elseif a_hide_number < 100 then
				create Result.make_with_size (scaled_size (21), scaled_size (16))
			else
				create Result.make_with_size (scaled_size (24), scaled_size (16))
			end
			Result.set_background_color ((create {EV_STOCK_COLORS}).default_background_color)
			Result.clear
			Result.draw_pixmap (0, 0, scaled_buffer (icons_10_10.tool_bar_hidden_dropdown_small_icon_buffer).to_pixmap)

			create l_font
			l_font.set_height_in_points (7)
			l_font.set_family ({EV_FONT_CONSTANTS}.family_roman)
			Result.set_font ({EV_MONITOR_DPI_DETECTOR_IMP}.font_for_dpi (l_font, dpi))

			if a_hide_number < 10 then
				Result.draw_text_top_left (Result.width - scaled_size (7), scaled_size (2), a_hide_number.out)
			elseif a_hide_number < 100 then
				Result.draw_text_top_left (Result.width - scaled_size (11), scaled_size (2), a_hide_number.out)
			else
				Result.draw_text_top_left (Result.width - scaled_size (15), scaled_size (2), a_hide_number.out)
			end
		end

	tool_bar_indicator: EV_PIXMAP
			-- <Precursor>
		do
			Result := shared_pixmap (tool_bar_indicator_name)
		end

	tool_bar_indicator_buffer: EV_PIXEL_BUFFER
			-- <Precursor>
		do
			Result := shared_buffer (tool_bar_indicator_name)
		end

	tool_bar_separator_icon: EV_PIXMAP
			-- <Precursor>
		do
			if attached internal_tool_bar_separator_icon as l_icon then
				Result := l_icon
			else
				Result := new_tool_bar_separator_icon
				internal_tool_bar_separator_icon := Result
			end
		end

	tool_bar_customize_indicator: EV_PIXMAP
			-- <Precursor>
		do
			Result := shared_pixmap (tool_bar_customize_indicator_name)
		end

	tool_bar_customize_indicator_buffer: EV_PIXEL_BUFFER
			-- <Precursor>
		do
			Result := shared_buffer (tool_bar_customize_indicator_name)
		end

	tool_bar_customize_indicator_horizontal: EV_PIXMAP
			-- <Precursor>
		do
			Result := shared_pixmap (tool_bar_customize_indicator_horizontal_name)
		end

	tool_bar_customize_indicator_horizontal_buffer: EV_PIXEL_BUFFER
			-- <Precursor>
		do
			Result := shared_buffer (tool_bar_customize_indicator_horizontal_name)
		end

	tool_bar_customize_indicator_with_hidden_items_horizontal: EV_PIXMAP
			-- <Precursor>
		do
			Result := shared_pixmap (tool_bar_customize_indicator_with_hidden_items_horizontal_name)
		end

	tool_bar_customize_indicator_with_hidden_items_horizontal_buffer: EV_PIXEL_BUFFER
			-- <Precursor>
		do
			Result := shared_buffer (tool_bar_customize_indicator_with_hidden_items_horizontal_name)
		end

	tool_bar_customize_indicator_with_hidden_items: EV_PIXMAP
			-- <Precursor>
		do
			Result := shared_pixmap (tool_bar_customize_indicator_with_hidden_items_name)
		end

	tool_bar_customize_indicator_with_hidden_items_buffer: EV_PIXEL_BUFFER
			-- <Precursor>
		do
			Result := shared_buffer (tool_bar_customize_indicator_with_hidden_items_name)
		end

	tool_bar_dropdown_buffer: EV_PIXEL_BUFFER
			-- <Precursor>
		do
			Result := shared_buffer (tool_bar_dropdown_name)
		end

	tool_bar_floating_customize: EV_PIXMAP
			-- <Precursor>
		do
			Result := shared_pixmap (tool_bar_floating_customize_name)
		end

	tool_bar_floating_close: EV_PIXMAP
			-- <Precursor>
		do
			Result := shared_pixmap (tool_bar_floating_close_name)
		end

	floating_tool_bar_icon: SD_ICONS_11_7
			-- <Precursor>
		once
			create Result.make
		end

	tool_bar_customize_dialog: EV_PIXMAP
			-- <Precursor>
		once
			Result := (create {EV_STOCK_PIXMAPS}).default_window_icon
		end

	drag_pointer_up: EV_POINTER_STYLE
			-- <Precursor>
		do
			create Result.make_with_pixel_buffer (scaled_buffer (icons_32_32.drag_up_icon_buffer), scaled_size (16), scaled_size (16))
		end

	drag_pointer_down: EV_POINTER_STYLE
			-- <Precursor>
		do
			create Result.make_with_pixel_buffer (scaled_buffer (icons_32_32.drag_down_icon_buffer), scaled_size (16), scaled_size (16))
		end

	drag_pointer_left: EV_POINTER_STYLE
			-- <Precursor>
		do
			create Result.make_with_pixel_buffer (scaled_buffer (icons_32_32.drag_left_icon_buffer), scaled_size (16), scaled_size (16))
		end

	drag_pointer_right: EV_POINTER_STYLE
			-- <Precursor>
		do
			create Result.make_with_pixel_buffer (scaled_buffer (icons_32_32.drag_right_icon_buffer), scaled_size (16), scaled_size (16))
		end

	drag_pointer_center: EV_POINTER_STYLE
			-- <Precursor>
		do
			create Result.make_with_pixel_buffer (scaled_buffer (icons_32_32.drag_center_icon_buffer), scaled_size (16), scaled_size (16))
		end

	drag_pointer_float: EV_POINTER_STYLE
			-- <Precursor>
		do
			create Result.make_with_pixel_buffer (scaled_buffer (icons_32_32.drag_float_icon_buffer), scaled_size (16), scaled_size (16))
		end

feature -- Generated matrix classes

	icons_32_32: SD_ICONS_32_32
			-- 32 * 32 icons.
		once
			create Result.make
		end

	icons_16_16: SD_ICONS_16_16
			-- 16 * 16 icons.
		once
			create Result.make
		end

	icons_8_16: SD_ICONS_8_16
			-- 8 * 16 icons.
		once
			create Result.make
		end

	icons_16_8: SD_ICONS_16_8
			-- 16 * 8 icons.
		once
			create Result.make
		end

	icons_10_10: SD_ICONS_10_10
			-- 10 * 10 icons.
		once
			create Result.make
		end

feature -- Feedback indicators

	arrow_indicator_center: EV_PIXEL_BUFFER
			-- <Precursor>
		do
			Result := shared_buffer (arrow_indicator_center_name)
		end

	arrow_indicator_center_lightening_up: EV_PIXEL_BUFFER
			-- <Precursor>
		do
			Result := shared_buffer (arrow_indicator_center_lightening_up_name)
		end

	arrow_indicator_center_lightening_down: EV_PIXEL_BUFFER
			-- <Precursor>
		do
			Result := shared_buffer (arrow_indicator_center_lightening_down_name)
		end

	arrow_indicator_center_lightening_left: EV_PIXEL_BUFFER
			-- <Precursor>
		do
			Result := shared_buffer (arrow_indicator_center_lightening_left_name)
		end

	arrow_indicator_center_lightening_right: EV_PIXEL_BUFFER
			-- <Precursor>
		do
			Result := shared_buffer (arrow_indicator_center_lightening_right_name)
		end

	arrow_indicator_center_lightening_center: EV_PIXEL_BUFFER
			-- <Precursor>
		do
			Result := shared_buffer (arrow_indicator_center_lightening_center_name)
		end

	arrow_indicator_up: EV_PIXEL_BUFFER
			-- <Precursor>
		do
			Result := shared_buffer (arrow_indicator_up_name)
		end

	arrow_indicator_down: EV_PIXEL_BUFFER
			-- <Precursor>
		do
			Result := shared_buffer (arrow_indicator_down_name)
		end

	arrow_indicator_left: EV_PIXEL_BUFFER
			-- <Precursor>
		do
			Result := shared_buffer (arrow_indicator_left_name)
		end

	arrow_indicator_right: EV_PIXEL_BUFFER
			-- <Precursor>
		do
			Result := shared_buffer (arrow_indicator_right_name)
		end

	arrow_indicator_up_lightening: EV_PIXEL_BUFFER
			-- <Precursor>
		do
			Result := shared_buffer (arrow_indicator_up_lightening_name)
		end

	arrow_indicator_down_lightening: EV_PIXEL_BUFFER
			-- <Precursor>
		do
			Result := shared_buffer (arrow_indicator_down_lightening_name)
		end

	arrow_indicator_left_lightening: EV_PIXEL_BUFFER
			-- <Precursor>
		do
			Result := shared_buffer (arrow_indicator_left_lightening_name)
		end

	arrow_indicator_right_lightening: EV_PIXEL_BUFFER
			-- <Precursor>
		do
			Result := shared_buffer (arrow_indicator_right_lightening_name)
		end

feature -- Editor icons

	close_context_tool_bar: EV_PIXMAP
			-- <Precursor>
		do
			Result := shared_pixmap (close_context_tool_bar_name)
		end

	close_others: EV_PIXMAP
			-- <Precursor>
		do
			create Result
		end

	close_all: EV_PIXMAP
			-- <Precursor>
		do
			Result := shared_pixmap (close_all_name)
		end

	editor_area: EV_PIXEL_BUFFER
			-- <Precursor>
		do
			Result := shared_buffer (editor_area_name)
		end

feature {NONE} -- Implementation: shared icons

	shared_pixmap (a_name: STRING): EV_PIXMAP
			-- Shared pixmap of the icon named `a_name', scaled for `dpi'.
		do
			if attached shared_pixmaps.item (a_name) as l_pixmap then
				Result := l_pixmap
			else
				Result := scaled_buffer (source_buffer (a_name)).to_pixmap
				shared_pixmaps.force (Result, a_name)
			end
		end

	shared_buffer (a_name: STRING): EV_PIXEL_BUFFER
			-- Shared pixel buffer of the icon named `a_name', scaled for `dpi'.
		do
			if attached shared_buffers.item (a_name) as l_buffer then
				Result := l_buffer
			else
				Result := scaled_buffer (source_buffer (a_name))
				shared_buffers.force (Result, a_name)
			end
		end

	shared_pixmaps: STRING_TABLE [EV_PIXMAP]
			-- Pixmaps given by `shared_pixmap', indexed by icon name.

	shared_buffers: STRING_TABLE [EV_PIXEL_BUFFER]
			-- Pixel buffers given by `shared_buffer', indexed by icon name.

	scaled_buffer (a_buffer: EV_PIXEL_BUFFER): EV_PIXEL_BUFFER
			-- `a_buffer', an icon for 96 DPI, scaled for `dpi'.
		do
			if dpi = 96 then
				Result := a_buffer
			else
				Result := a_buffer.stretched (scaled_size (a_buffer.width).max (1), scaled_size (a_buffer.height).max (1))
			end
		end

	source_buffer (a_name: READABLE_STRING_GENERAL): EV_PIXEL_BUFFER
			-- New pixel buffer of the icon named `a_name', for 96 DPI.
		do
			if a_name.same_string (unstick_name) then
				Result := icons_10_10.tool_bar_unpin_icon_buffer
			elseif a_name.same_string (stick_name) then
				Result := icons_10_10.tool_bar_pin_icon_buffer
			elseif a_name.same_string (minimize_name) then
				Result := icons_10_10.tool_bar_minimize_icon_buffer
			elseif a_name.same_string (maximize_name) then
				Result := icons_10_10.tool_bar_maximize_icon_buffer
			elseif a_name.same_string (normal_name) then
				Result := icons_10_10.tool_bar_normalize_icon_buffer
			elseif a_name.same_string (close_name) then
				Result := icons_10_10.tool_bar_close_icon_buffer
			elseif a_name.same_string (tool_bar_indicator_name) then
				Result := icons_10_10.tool_bar_hidden_dropdown_icon_buffer
			elseif a_name.same_string (tool_bar_customize_indicator_name) then
				Result := icons_8_16.tool_bar_customize_indicator_icon_buffer
			elseif a_name.same_string (tool_bar_customize_indicator_with_hidden_items_name) then
				Result := icons_8_16.tool_bar_customize_indicator_hidden_items_icon_buffer
			elseif a_name.same_string (tool_bar_customize_indicator_horizontal_name) then
				Result := icons_16_8.tool_bar_customize_indicator_horizontal_icon_buffer
			elseif a_name.same_string (tool_bar_customize_indicator_with_hidden_items_horizontal_name) then
				Result := icons_16_8.tool_bar_customize_indicator_hidden_items_horizontal_icon_buffer
			elseif a_name.same_string (tool_bar_dropdown_name) then
				Result := icons_8_16.tool_bar_dropdown_icon_buffer
			elseif a_name.same_string (tool_bar_floating_customize_name) then
				Result := floating_tool_bar_icon.icon_drop_down_icon_buffer
			elseif a_name.same_string (tool_bar_floating_close_name) then
				Result := floating_tool_bar_icon.icon_close_icon_buffer
			elseif a_name.same_string (close_context_tool_bar_name) then
				Result := icons_16_16.zone_close_icon_buffer
			elseif a_name.same_string (close_all_name) then
				Result := icons_16_16.zone_close_all_icon_buffer
			elseif a_name.same_string (editor_area_name) then
				Result := icons_16_16.editor_area_icon_buffer
			elseif a_name.same_string (arrow_indicator_center_name) then
				create {SD_CENTER_ICON} Result.make
			elseif a_name.same_string (arrow_indicator_center_lightening_up_name) then
				create {SD_CENTER_UP_LIGHT_ICON} Result.make
			elseif a_name.same_string (arrow_indicator_center_lightening_down_name) then
				create {SD_CENTER_DOWN_LIGHT_ICON} Result.make
			elseif a_name.same_string (arrow_indicator_center_lightening_left_name) then
				create {SD_CENTER_LEFT_ICON} Result.make
			elseif a_name.same_string (arrow_indicator_center_lightening_right_name) then
				create {SD_CENTER_RIGHT_ICON} Result.make
			elseif a_name.same_string (arrow_indicator_center_lightening_center_name) then
				create {SD_CENTER_CENTER_LIGHT_ICON} Result.make
			elseif a_name.same_string (arrow_indicator_up_name) then
				create {SD_UP_ICON} Result.make
			elseif a_name.same_string (arrow_indicator_down_name) then
				create {SD_DOWN_ICON} Result.make
			elseif a_name.same_string (arrow_indicator_left_name) then
				create {SD_LEFT_ICON} Result.make
			elseif a_name.same_string (arrow_indicator_right_name) then
				create {SD_RIGHT_ICON} Result.make
			elseif a_name.same_string (arrow_indicator_up_lightening_name) then
				create {SD_UP_LIGHT_ICON} Result.make
			elseif a_name.same_string (arrow_indicator_down_lightening_name) then
				create {SD_DOWN_LIGHT_ICON} Result.make
			elseif a_name.same_string (arrow_indicator_left_lightening_name) then
				create {SD_LEFT_LIGHT_ICON} Result.make
			else
				check known_icon_name: a_name.same_string (arrow_indicator_right_lightening_name) end
				create {SD_RIGHT_LIGHT_ICON} Result.make
			end
		end

	new_tool_bar_separator_icon: EV_PIXMAP
			-- New transparent icon for tool bar separators, sized for `dpi'.
		local
			l_bitmap: EV_BITMAP
		do
			create Result.make_with_size (scaled_size (16), scaled_size (16))
			create l_bitmap.make_with_size (scaled_size (16), scaled_size (16))
			l_bitmap.fill_rectangle (0, 0, l_bitmap.width, l_bitmap.height)
			Result.set_mask (l_bitmap)
		end

	internal_tool_bar_separator_icon: detachable EV_PIXMAP
			-- Cached `tool_bar_separator_icon'.

feature {NONE} -- Icon names

	unstick_name: STRING = "unstick"
	stick_name: STRING = "stick"
	minimize_name: STRING = "minimize"
	maximize_name: STRING = "maximize"
	normal_name: STRING = "normal"
	close_name: STRING = "close"
	tool_bar_indicator_name: STRING = "tool_bar_indicator"
	tool_bar_customize_indicator_name: STRING = "tool_bar_customize_indicator"
	tool_bar_customize_indicator_with_hidden_items_name: STRING = "tool_bar_customize_indicator_with_hidden_items"
	tool_bar_customize_indicator_horizontal_name: STRING = "tool_bar_customize_indicator_horizontal"
	tool_bar_customize_indicator_with_hidden_items_horizontal_name: STRING = "tool_bar_customize_indicator_with_hidden_items_horizontal"
	tool_bar_dropdown_name: STRING = "tool_bar_dropdown"
	tool_bar_floating_customize_name: STRING = "tool_bar_floating_customize"
	tool_bar_floating_close_name: STRING = "tool_bar_floating_close"
	close_context_tool_bar_name: STRING = "close_context_tool_bar"
	close_all_name: STRING = "close_all"
	editor_area_name: STRING = "editor_area"
	arrow_indicator_center_name: STRING = "arrow_indicator_center"
	arrow_indicator_center_lightening_up_name: STRING = "arrow_indicator_center_lightening_up"
	arrow_indicator_center_lightening_down_name: STRING = "arrow_indicator_center_lightening_down"
	arrow_indicator_center_lightening_left_name: STRING = "arrow_indicator_center_lightening_left"
	arrow_indicator_center_lightening_right_name: STRING = "arrow_indicator_center_lightening_right"
	arrow_indicator_center_lightening_center_name: STRING = "arrow_indicator_center_lightening_center"
	arrow_indicator_up_name: STRING = "arrow_indicator_up"
	arrow_indicator_down_name: STRING = "arrow_indicator_down"
	arrow_indicator_left_name: STRING = "arrow_indicator_left"
	arrow_indicator_right_name: STRING = "arrow_indicator_right"
	arrow_indicator_up_lightening_name: STRING = "arrow_indicator_up_lightening"
	arrow_indicator_down_lightening_name: STRING = "arrow_indicator_down_lightening"
	arrow_indicator_left_lightening_name: STRING = "arrow_indicator_left_lightening"
	arrow_indicator_right_lightening_name: STRING = "arrow_indicator_right_lightening"
			-- Names of the shared icons.

invariant
	dpi_positive: dpi > 0

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
