note
	description: "[
		TUI_THEME (review/p2_terminal_widgets_plan.md): B1, the presets are not shared.
		Theme load and save (C3) are tested in TEST_THEME_FILE.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_THEME

inherit
	EQA_TEST_SET

feature -- Presets (B1)

	test_presets_are_not_shared
			-- P2 B1: changing a preset changes no later caller's preset. Each of `dark`,
			-- `light`, `nord` and `dracula` is changed through `set_primary`, and the next call
			-- still equals a theme made with the creation procedure. Two calls give two objects.
		local
			l_red: STYLE
		do
			create l_red.make_fg ({COLOR}.Red)
			{TUI_THEME}.dark.set_primary (l_red)
			assert ("dark kept", {TUI_THEME}.dark.is_equal (create {TUI_THEME}.make_dark))
			{TUI_THEME}.light.set_primary (l_red)
			assert ("light kept", {TUI_THEME}.light.is_equal (create {TUI_THEME}.make_light))
			{TUI_THEME}.nord.set_primary (l_red)
			assert ("nord kept", {TUI_THEME}.nord.is_equal (create {TUI_THEME}.make_nord))
			{TUI_THEME}.dracula.set_primary (l_red)
			assert ("dracula kept", {TUI_THEME}.dracula.is_equal (create {TUI_THEME}.make_dracula))
			assert ("dark fresh", {TUI_THEME}.dark /= {TUI_THEME}.dark)
			assert ("nord fresh", {TUI_THEME}.nord /= {TUI_THEME}.nord)
		end

	test_presets_differ
			-- The four presets are four different palettes, and `default_create` is the dark one.
		do
			assert ("dark is not light", not {TUI_THEME}.dark.is_equal ({TUI_THEME}.light))
			assert ("nord is not dracula", not {TUI_THEME}.nord.is_equal ({TUI_THEME}.dracula))
			assert ("dark is not nord", not {TUI_THEME}.dark.is_equal ({TUI_THEME}.nord))
			assert ("default is dark", (create {TUI_THEME}).is_equal ({TUI_THEME}.dark))
		end

	test_preset_foregrounds_show_on_the_background
			-- In every preset, no style meant for text or lines (primary, secondary, success,
			-- warning, error, info, muted, border, title, text) has the colour of `base`'s
			-- background as its foreground, so nothing drawn with them is invisible. The light
			-- preset's `muted` and `border` were `gray`, which is `white` (ANSI 7), its
			-- background (found in EXAMPLE_FORM_CONTROLS: line numbers and section rules did
			-- not show).
		do
			check_visible ("dark", {TUI_THEME}.dark)
			check_visible ("light", {TUI_THEME}.light)
			check_visible ("nord", {TUI_THEME}.nord)
			check_visible ("dracula", {TUI_THEME}.dracula)
			assert ("light muted is dark gray", {TUI_THEME}.light.muted.foreground.same_rendering ({COLOR}.Dark_gray))
			assert ("light border is dark gray", {TUI_THEME}.light.border.foreground.same_rendering ({COLOR}.Dark_gray))
		end

feature {NONE} -- Helpers

	check_visible (a_name: STRING; a_theme: TUI_THEME)
			-- Each foreground style of `a_theme` differs from its background.
		local
			l_bg: COLOR
		do
			l_bg := a_theme.base.background
			across <<["primary", a_theme.primary], ["secondary", a_theme.secondary], ["success", a_theme.success],
					["warning", a_theme.warning], ["error", a_theme.error], ["info", a_theme.info],
					["muted", a_theme.muted], ["border", a_theme.border], ["title", a_theme.title],
					["text", a_theme.text]>> as l_entry
			loop
				if attached {STRING} l_entry [1] as l_role and attached {STYLE} l_entry [2] as l_style then
					assert (a_name + " " + l_role + " shows on the background",
						not l_style.foreground.same_rendering (l_bg))
				end
			end
		end

end
