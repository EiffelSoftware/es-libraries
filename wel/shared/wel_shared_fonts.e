note
	description: "Shared reference to predefined font object."
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date$"
	revision: "$Revision$"

class
	WEL_SHARED_FONTS

feature -- Access

	gui_font: WEL_FONT
			-- Default screen (WEL) font.
		do
			Result := message_font
		ensure
			Result_exists: Result /= Void and then Result.exists
		end

	system_font: WEL_FONT
			-- Default system font.
		do
			Result := message_font
		ensure
			font_created: Result /= Void and then Result.exists
		end

	message_font: WEL_FONT
			-- Font used in message boxes
		local
			system_parameter_info: WEL_SYSTEM_PARAMETERS_INFO
			non_client_metrics: WEL_NON_CLIENT_METRICS
			loc_font: detachable WEL_FONT
		do
			loc_font := message_font_cell.item
			if loc_font = Void then
				create system_parameter_info
				non_client_metrics := system_parameter_info.get_non_client_metrics
				create loc_font.make_indirect (non_client_metrics.message_font)
				message_font_cell.put (loc_font)
			end
			Result := loc_font
		ensure
			Result_exists: Result /= Void and then Result.exists
		end

	menu_font: WEL_FONT
			-- Font used in menus
		local
			system_parameter_info: WEL_SYSTEM_PARAMETERS_INFO
			non_client_metrics: WEL_NON_CLIENT_METRICS
			loc_font: detachable WEL_FONT
		do
			loc_font := menu_font_cell.item
			if loc_font = Void then
				create system_parameter_info
				non_client_metrics := system_parameter_info.get_non_client_metrics
				create loc_font.make_indirect (non_client_metrics.menu_font)
				menu_font_cell.put (loc_font)
			end
			Result := loc_font
		ensure
			Result_exists: Result /= Void and then Result.exists
		end

	status_font: WEL_FONT
			-- Font used in status bars
		local
			system_parameter_info: WEL_SYSTEM_PARAMETERS_INFO
			non_client_metrics: WEL_NON_CLIENT_METRICS
			loc_font: detachable WEL_FONT
		do
			loc_font := status_font_cell.item
			if loc_font = Void then
				create system_parameter_info
				non_client_metrics := system_parameter_info.get_non_client_metrics
				create loc_font.make_indirect (non_client_metrics.status_font)
				status_font_cell.put (loc_font)
			end
			Result := loc_font
		ensure
			Result_exists: Result /= Void and then Result.exists
		end

	caption_font: WEL_FONT
			-- Caption font
		local
			system_parameter_info: WEL_SYSTEM_PARAMETERS_INFO
			non_client_metrics: WEL_NON_CLIENT_METRICS
			loc_font: detachable WEL_FONT
		do
			loc_font := caption_font_cell.item
			if loc_font = Void then
				create system_parameter_info
				non_client_metrics := system_parameter_info.get_non_client_metrics
				create loc_font.make_indirect (non_client_metrics.caption_font)
				caption_font_cell.put (loc_font)
			end
			Result := loc_font
		ensure
			Result_exists: Result /= Void and then Result.exists
		end

	small_caption_font: WEL_FONT
			-- Small caption font
		local
			system_parameter_info: WEL_SYSTEM_PARAMETERS_INFO
			non_client_metrics: WEL_NON_CLIENT_METRICS
			loc_font: detachable WEL_FONT
		do
			loc_font := small_caption_font_cell.item
			if loc_font = Void then
				create system_parameter_info
				non_client_metrics := system_parameter_info.get_non_client_metrics
				create loc_font.make_indirect (non_client_metrics.small_caption_font)
				small_caption_font_cell.put (loc_font)
			end
			Result := loc_font
		ensure
			Result_exists: Result /= Void and then Result.exists
		end

feature -- Access: per monitor DPI

	gui_font_for_dpi (a_dpi: NATURAL_32): WEL_FONT
			-- `gui_font` for a window displayed with `a_dpi` DPI.
		do
			Result := font_for_dpi (gui_font, gui_font_dpi_cache, a_dpi)
		ensure
			Result_exists: Result /= Void and then Result.exists
		end

	menu_font_for_dpi (a_dpi: NATURAL_32): WEL_FONT
			-- `menu_font` for a menu displayed with `a_dpi` DPI.
		do
			Result := font_for_dpi (menu_font, menu_font_dpi_cache, a_dpi)
		ensure
			Result_exists: Result /= Void and then Result.exists
		end

	scaled_font (a_font: WEL_FONT; a_dpi: NATURAL_32): WEL_FONT
			-- New font similar to `a_font`, which is realized for the system DPI,
			-- but realized for `a_dpi` DPI.
		require
			a_font_exists: a_font /= Void and then a_font.exists
			a_dpi_positive: a_dpi > 0
		do
			Result := rescaled_font (a_font, {WEL_SCALING_EXTERNALS}.system_dpi, a_dpi)
		ensure
			Result_exists: Result /= Void and then Result.exists
		end

	rescaled_font (a_font: WEL_FONT; a_font_dpi, a_dpi: NATURAL_32): WEL_FONT
			-- New font similar to `a_font`, which is realized for `a_font_dpi`,
			-- but realized for `a_dpi` DPI.
		require
			a_font_exists: a_font /= Void and then a_font.exists
			a_font_dpi_positive: a_font_dpi > 0
			a_dpi_positive: a_dpi > 0
		do
			create Result.make_indirect (rescaled_log_font (a_font.log_font, a_font_dpi, a_dpi))
		ensure
			Result_exists: Result /= Void and then Result.exists
		end

	rescaled_log_font (a_log_font: WEL_LOG_FONT; a_font_dpi, a_dpi: NATURAL_32): WEL_LOG_FONT
			-- `a_log_font`, describing a font for `a_font_dpi`, updated to describe it for `a_dpi`.
		require
			a_log_font_attached: a_log_font /= Void
			a_font_dpi_positive: a_font_dpi > 0
		do
			Result := a_log_font
			Result.set_height ({WEL_SCALING_EXTERNALS}.rescaled_for_dpi (Result.height, a_font_dpi, a_dpi))
			Result.set_width ({WEL_SCALING_EXTERNALS}.rescaled_for_dpi (Result.width, a_font_dpi, a_dpi))
		ensure
			same_object: Result = a_log_font
		end

feature {NONE} -- Implementation: per monitor DPI

	font_for_dpi (a_font: WEL_FONT; a_cache: HASH_TABLE [WEL_FONT, NATURAL_32]; a_dpi: NATURAL_32): WEL_FONT
			-- `a_font` realized for `a_dpi`, using and updating `a_cache`.
		require
			a_font_exists: a_font /= Void and then a_font.exists
		do
			if a_dpi = 0 or else a_dpi = {WEL_SCALING_EXTERNALS}.system_dpi then
				Result := a_font
			elseif attached a_cache.item (a_dpi) as l_font then
				Result := l_font
			else
				Result := scaled_font (a_font, a_dpi)
				a_cache.force (Result, a_dpi)
			end
		end

	gui_font_dpi_cache: HASH_TABLE [WEL_FONT, NATURAL_32]
			-- `gui_font` realized for DPIs other than the system DPI.
		once
			create Result.make (2)
		end

	menu_font_dpi_cache: HASH_TABLE [WEL_FONT, NATURAL_32]
			-- `menu_font` realized for DPIs other than the system DPI.
		once
			create Result.make (2)
		end

feature {WEL_COMPOSITE_WINDOW}

	message_font_cell: CELL [detachable WEL_FONT]
			-- Container for `message_font'
		once
			create Result.put (Void)
		end

	menu_font_cell: CELL [detachable WEL_FONT]
			-- Container for `menu_font'
		once
			create Result.put (Void)
		end

	status_font_cell: CELL [detachable WEL_FONT]
			-- Container for `status_font'
		once
			create Result.put (Void)
		end

	caption_font_cell: CELL [detachable WEL_FONT]
			-- Container for `caption_font'
		once
			create Result.put (Void)
		end

	small_caption_font_cell: CELL [detachable WEL_FONT]
			-- Container for `small_caption_font'
		once
			create Result.put (Void)
		end

note
	copyright:	"Copyright (c) 1984-2006, Eiffel Software and others"
	license:	"Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			 Eiffel Software
			 356 Storke Road, Goleta, CA 93117 USA
			 Telephone 805-685-1006, Fax 805-685-6869
			 Website http://www.eiffel.com
			 Customer support http://support.eiffel.com
		]"




end -- class WEL_SHARED_FONTS

