note
	description:"[
		EiffelVision fontable, mswindows implementation.

		Note: When a heir of this class inherits from a WEL object,
			it needs to rename `font' as `wel_font' and
			`set_font' as `wel_set_font'.
		]"
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date$"
	revision: "$Revision$"

deferred class
	EV_FONTABLE_IMP

inherit
	EV_FONTABLE_I

feature -- Access

	font: EV_FONT
			-- Font of `Current'.
		local
			font_imp: detachable EV_FONT_IMP
			private_font_twin: WEL_FONT
			l_private_wel_font: like private_wel_font
		do
			if attached private_font as l_private_font then
				Result := l_private_font.twin
			else
				create Result
				font_imp ?= Result.implementation
				check font_imp /= Void then end
				l_private_wel_font := private_wel_font
				check l_private_wel_font /= Void then end
				create private_font_twin.make_indirect (l_private_wel_font.log_font)
				font_imp.set_by_wel_font (private_font_twin)
				private_font := Result
				private_wel_font := Void
			end
		end

	internal_font: EV_FONT
			-- Font of `Current' for internal queries.
			-- Faster than calling `font' as we do not need to
			-- create a new EV_FONT every time.
		do
			if attached private_font as l_private_font then
				Result := l_private_font
			else
				Result := font
			end
		end

	internal_font_height: INTEGER
			-- Height required to correctly display font of `Current' in pixels.
		local
			screen_dc: WEL_SCREEN_DC
			extent: WEL_SIZE
		do
			create screen_dc
			screen_dc.get
			screen_dc.select_font (realized_wel_font)
			extent := screen_dc.string_size ("X")
			screen_dc.unselect_font
			screen_dc.quick_release
			Result := extent.height
		ensure
			result_non_negative: Result >= 0
		end

feature -- Status setting

	set_font (ft: EV_FONT)
			-- Make `ft' new font of `Current'.
		do
			private_font := ft
				-- We don't need the WEL private font anymore since it is set by user.
			private_wel_font := Void
			wel_set_font (realized_wel_font)
		end

	set_default_font
			-- Make system to use default font.
		do
			private_wel_font := wel_default_font
			wel_set_font (realized_wel_font)
		end

feature {EV_ANY_I} -- Per monitor DPI

	font_dpi: NATURAL_32
			-- DPI for which the font of `Current' is realized:
			-- the DPI of the monitor on which `Current' is displayed.
		do
			Result := font_dpi_internal
			if Result = 0 then
					-- Widgets are created in a hidden window, for the system DPI.
				Result := {WEL_SCALING_EXTERNALS}.system_dpi
			end
		ensure
			positive: Result > 0
		end

	set_font_dpi (a_dpi: NATURAL_32)
			-- Set `font_dpi' to `a_dpi', the DPI of the monitor on which `Current' is now displayed.
			-- Call `update_font_for_dpi' to realize the font for it.
		require
			a_dpi_positive: a_dpi > 0
		do
			font_dpi_internal := a_dpi
		ensure
			font_dpi_set: font_dpi = a_dpi
		end

	realized_wel_font: WEL_FONT
			-- Font with which `Current' draws its text: `private_font', or else the default font,
			-- realized for `font_dpi'.
			-- `private_font' (realized for its `{EV_FONT_IMP}.realization_dpi', the system DPI by default)
			-- and `private_wel_font' (realized for the system DPI) can be shared by widgets displayed
			-- on monitors with different DPIs: the size of the text of `Current' has to be computed
			-- with `realized_wel_font'.
			--| The fonts for other DPIs are cached (in {EV_FONT_IMP} and {WEL_SHARED_FONTS}),
			--| they are not collected while a control may still use them.
		do
			if attached private_font as l_font and then attached {EV_FONT_IMP} l_font.implementation as l_font_imp then
				Result := l_font_imp.wel_font_for_dpi (font_dpi)
			else
				Result := (create {WEL_SHARED_FONTS}).gui_font_for_dpi (font_dpi)
			end
		ensure
			result_exists: Result /= Void and then Result.exists
		end

	update_font_for_dpi
			-- Realize the font of `Current' for its current DPI, for instance after
			-- it moved to a monitor with a different DPI.
		do
			if attached private_font as l_font then
					-- `set_font' also updates the size of `Current' for the new font.
				set_font (l_font)
			else
				set_default_font
			end
		end

feature {NONE} -- Per monitor DPI

	font_dpi_internal: NATURAL_32
			-- Storage for `font_dpi', 0 for the system DPI.

feature {EV_ANY_I} -- Implementation

	private_font: detachable EV_FONT
			-- font used for implementation
		note
			option: stable
		attribute
		end;

	private_wel_font: detachable WEL_FONT
			-- WEL font used for implementation

feature {NONE} -- Implementation : The wel values, are deferred here, but
			   -- they need to be defined by their heirs.

	wel_default_font: WEL_FONT
			-- Default font of system.
		once
			Result := (create {WEL_SHARED_FONTS}).gui_font
		end

	wel_font: WEL_FONT
			-- The wel_font
		deferred
		end

	wel_set_font (a_font: WEL_FONT)
			-- Make `a_font' the new font of the widget.
		deferred
		end

note
	copyright:	"Copyright (c) 1984-2013, Eiffel Software and others"
	license:	"Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"




end -- class EV_FONTABLE_IMP











