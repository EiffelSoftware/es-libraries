note
	description: "[
		Palette object providing cohesive semantic styles across widgets:
		base, primary, secondary, success, warning, error, info, highlight, selection,
		muted, border, title, and text styles. Includes built-in dark, light, nord, and
		dracula themes.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_THEME

inherit
	ANY
		redefine
			default_create,
			is_equal
		end

create
	default_create,
	make_dark,
	make_light,
	make_nord,
	make_dracula,
	make_custom

feature -- Predefined Theme Instances

	dark: TUI_THEME
			-- Modern dark terminal theme
		once
			create Result.make_dark
		ensure
			instance_free: class
			result_not_void: Result /= Void
		end

	light: TUI_THEME
			-- Clean light terminal theme
		once
			create Result.make_light
		ensure
			instance_free: class
			result_not_void: Result /= Void
		end

	nord: TUI_THEME
			-- Nord-inspired terminal theme
		once
			create Result.make_nord
		ensure
			instance_free: class
			result_not_void: Result /= Void
		end

	dracula: TUI_THEME
			-- Dracula-inspired terminal theme
		once
			create Result.make_dracula
		ensure
			instance_free: class
			result_not_void: Result /= Void
		end

feature {NONE} -- Initialization

	default_create
			-- Initialize with standard dark palette.
		do
			make_dark
		end

	make_dark
			-- Standard modern dark terminal theme.
		do
			create base.make_with_colors ({COLOR}.white, {COLOR}.black)
			create primary.make_fg ({COLOR}.cyan)
			create secondary.make_fg ({COLOR}.blue)
			create success.make_fg ({COLOR}.green)
			create warning.make_fg ({COLOR}.yellow)
			create error.make_fg ({COLOR}.red)
			create info.make_fg ({COLOR}.light_cyan)
			highlight := (create {STYLE}.make_with_colors ({COLOR}.black, {COLOR}.cyan)).with_bold
			selection := (create {STYLE}.make_with_colors ({COLOR}.white, {COLOR}.blue)).with_bold
			create muted.make_fg ({COLOR}.dark_gray)
			create border.make_fg ({COLOR}.dark_gray)
			title := (create {STYLE}.make_fg ({COLOR}.light_cyan)).with_bold
			create text.make_fg ({COLOR}.white)
		end

	make_light
			-- Clean light terminal theme.
		do
			create base.make_with_colors ({COLOR}.black, {COLOR}.white)
			create primary.make_fg ({COLOR}.blue)
			create secondary.make_fg ({COLOR}.dark_gray)
			create success.make_fg ({COLOR}.green)
			create warning.make_fg ({COLOR}.yellow)
			create error.make_fg ({COLOR}.red)
			create info.make_fg ({COLOR}.cyan)
			highlight := (create {STYLE}.make_with_colors ({COLOR}.white, {COLOR}.blue)).with_bold
			selection := (create {STYLE}.make_with_colors ({COLOR}.black, {COLOR}.light_cyan)).with_bold
			create muted.make_fg ({COLOR}.gray)
			create border.make_fg ({COLOR}.gray)
			title := (create {STYLE}.make_fg ({COLOR}.blue)).with_bold
			create text.make_fg ({COLOR}.black)
		end

	make_nord
			-- Nord-inspired palette.
		do
			create base.make_with_colors ({COLOR}.rgb (216, 222, 233), {COLOR}.rgb (46, 52, 64))
			create primary.make_fg ({COLOR}.rgb (136, 192, 208))    -- Frost Frost 2
			create secondary.make_fg ({COLOR}.rgb (129, 161, 193))  -- Frost 3
			create success.make_fg ({COLOR}.rgb (163, 190, 140))    -- Aurora green
			create warning.make_fg ({COLOR}.rgb (235, 203, 139))    -- Aurora yellow
			create error.make_fg ({COLOR}.rgb (191, 97, 106))       -- Aurora red
			create info.make_fg ({COLOR}.rgb (143, 188, 187))       -- Frost 1
			highlight := (create {STYLE}.make_with_colors ({COLOR}.rgb (46, 52, 64), {COLOR}.rgb (136, 192, 208))).with_bold
			selection := (create {STYLE}.make_with_colors ({COLOR}.rgb (236, 239, 244), {COLOR}.rgb (67, 76, 94))).with_bold
			create muted.make_fg ({COLOR}.rgb (76, 86, 106))
			create border.make_fg ({COLOR}.rgb (76, 86, 106))
			title := (create {STYLE}.make_fg ({COLOR}.rgb (136, 192, 208))).with_bold
			create text.make_fg ({COLOR}.rgb (216, 222, 233))
		end

	make_dracula
			-- Dracula-inspired palette.
		do
			create base.make_with_colors ({COLOR}.rgb (248, 248, 242), {COLOR}.rgb (40, 42, 54))
			create primary.make_fg ({COLOR}.rgb (189, 147, 249))   -- Purple
			create secondary.make_fg ({COLOR}.rgb (255, 121, 198)) -- Pink
			create success.make_fg ({COLOR}.rgb (80, 250, 123))    -- Green
			create warning.make_fg ({COLOR}.rgb (241, 250, 140))   -- Yellow
			create error.make_fg ({COLOR}.rgb (255, 85, 85))       -- Red
			create info.make_fg ({COLOR}.rgb (139, 233, 253))      -- Cyan
			highlight := (create {STYLE}.make_with_colors ({COLOR}.rgb (40, 42, 54), {COLOR}.rgb (189, 147, 249))).with_bold
			selection := (create {STYLE}.make_with_colors ({COLOR}.rgb (248, 248, 242), {COLOR}.rgb (68, 71, 90))).with_bold
			create muted.make_fg ({COLOR}.rgb (98, 114, 164))
			create border.make_fg ({COLOR}.rgb (98, 114, 164))
			title := (create {STYLE}.make_fg ({COLOR}.rgb (189, 147, 249))).with_bold
			create text.make_fg ({COLOR}.rgb (248, 248, 242))
		end

	make_custom (
		a_base, a_primary, a_secondary, a_success, a_warning,
		a_error, a_info, a_highlight, a_selection, a_muted,
		a_border, a_title, a_text: STYLE
	)
			-- Initialize custom theme from explicit styles.
		require
			base_not_void: a_base /= Void
			primary_not_void: a_primary /= Void
			secondary_not_void: a_secondary /= Void
			success_not_void: a_success /= Void
			warning_not_void: a_warning /= Void
			error_not_void: a_error /= Void
			info_not_void: a_info /= Void
			highlight_not_void: a_highlight /= Void
			selection_not_void: a_selection /= Void
			muted_not_void: a_muted /= Void
			border_not_void: a_border /= Void
			title_not_void: a_title /= Void
			text_not_void: a_text /= Void
		do
			base := a_base
			primary := a_primary
			secondary := a_secondary
			success := a_success
			warning := a_warning
			error := a_error
			info := a_info
			highlight := a_highlight
			selection := a_selection
			muted := a_muted
			border := a_border
			title := a_title
			text := a_text
		end

feature -- Access: Semantic Styles

	base: STYLE
			-- Base application style

	primary: STYLE
			-- Primary brand / accent style

	secondary: STYLE
			-- Secondary accent style

	success: STYLE
			-- Success / positive indication style

	warning: STYLE
			-- Warning / caution indication style

	error: STYLE
			-- Error / alert indication style

	info: STYLE
			-- Informational indication style

	highlight: STYLE
			-- Highlight / focus style

	selection: STYLE
			-- Active selection style

	muted: STYLE
			-- Subtle / dim style

	border: STYLE
			-- Default container border style

	title: STYLE
			-- Container title style

	text: STYLE
			-- General body text style

feature -- Element Change

	set_base (a_style: STYLE) do base := a_style end
	set_primary (a_style: STYLE) do primary := a_style end
	set_secondary (a_style: STYLE) do secondary := a_style end
	set_success (a_style: STYLE) do success := a_style end
	set_warning (a_style: STYLE) do warning := a_style end
	set_error (a_style: STYLE) do error := a_style end
	set_info (a_style: STYLE) do info := a_style end
	set_highlight (a_style: STYLE) do highlight := a_style end
	set_selection (a_style: STYLE) do selection := a_style end
	set_muted (a_style: STYLE) do muted := a_style end
	set_border (a_style: STYLE) do border := a_style end
	set_title (a_style: STYLE) do title := a_style end
	set_text (a_style: STYLE) do text := a_style end

feature -- Fluent Builders

	with_base (a_style: STYLE): like Current
		do
			Result := twin
			Result.set_base (a_style)
		ensure
			style_set: Result.base = a_style
		end

	with_primary (a_style: STYLE): like Current
		do
			Result := twin
			Result.set_primary (a_style)
		ensure
			style_set: Result.primary = a_style
		end

	with_secondary (a_style: STYLE): like Current
		do
			Result := twin
			Result.set_secondary (a_style)
		ensure
			style_set: Result.secondary = a_style
		end

	with_success (a_style: STYLE): like Current
		do
			Result := twin
			Result.set_success (a_style)
		ensure
			style_set: Result.success = a_style
		end

	with_warning (a_style: STYLE): like Current
		do
			Result := twin
			Result.set_warning (a_style)
		ensure
			style_set: Result.warning = a_style
		end

	with_error (a_style: STYLE): like Current
		do
			Result := twin
			Result.set_error (a_style)
		ensure
			style_set: Result.error = a_style
		end

	with_info (a_style: STYLE): like Current
		do
			Result := twin
			Result.set_info (a_style)
		ensure
			style_set: Result.info = a_style
		end

	with_highlight (a_style: STYLE): like Current
		do
			Result := twin
			Result.set_highlight (a_style)
		ensure
			style_set: Result.highlight = a_style
		end

	with_selection (a_style: STYLE): like Current
		do
			Result := twin
			Result.set_selection (a_style)
		ensure
			style_set: Result.selection = a_style
		end

	with_muted (a_style: STYLE): like Current
		do
			Result := twin
			Result.set_muted (a_style)
		ensure
			style_set: Result.muted = a_style
		end

	with_border (a_style: STYLE): like Current
		do
			Result := twin
			Result.set_border (a_style)
		ensure
			style_set: Result.border = a_style
		end

	with_title (a_style: STYLE): like Current
		do
			Result := twin
			Result.set_title (a_style)
		ensure
			style_set: Result.title = a_style
		end

	with_text (a_style: STYLE): like Current
		do
			Result := twin
			Result.set_text (a_style)
		ensure
			style_set: Result.text = a_style
		end

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Is `a_other` equal to `Current`?
		do
			if a_other = Current then
				Result := True
			elseif standard_is_equal (a_other) then
				Result := True
			else
				Result := base.is_equal (a_other.base)
					and primary.is_equal (a_other.primary)
					and secondary.is_equal (a_other.secondary)
					and success.is_equal (a_other.success)
					and warning.is_equal (a_other.warning)
					and error.is_equal (a_other.error)
					and info.is_equal (a_other.info)
					and highlight.is_equal (a_other.highlight)
					and selection.is_equal (a_other.selection)
					and muted.is_equal (a_other.muted)
					and border.is_equal (a_other.border)
					and title.is_equal (a_other.title)
					and text.is_equal (a_other.text)
			end
		end

invariant
	base_not_void: base /= Void
	primary_not_void: primary /= Void
	secondary_not_void: secondary /= Void
	success_not_void: success /= Void
	warning_not_void: warning /= Void
	error_not_void: error /= Void
	info_not_void: info /= Void
	highlight_not_void: highlight /= Void
	selection_not_void: selection /= Void
	muted_not_void: muted /= Void
	border_not_void: border /= Void
	title_not_void: title /= Void
	text_not_void: text /= Void

end
