note
	description: "[
		Tier 5 Custom Widget: 3D Beveled Button Widget.
		Demonstrates creating an immediate-mode WIDGET subclass with custom themes,
		highlight/shadow edge beveling, centered labels, and state transitions.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	BUTTON_WIDGET

inherit
	WIDGET

create
	make

feature {NONE} -- Initialization

	make (a_label: READABLE_STRING_GENERAL)
			-- Initialize button with `a_label` in normal state with default theme.
		do
			label := a_label.as_string_32
			state := State_normal
			text_color := {COLOR}.Bright_white
			bg_color := create {COLOR}.make_rgb (48, 72, 144)
			highlight_color := create {COLOR}.make_rgb (64, 96, 192)
			shadow_color := create {COLOR}.make_rgb (32, 48, 96)
		ensure
			label_set: label.same_string_general (a_label)
			default_state: state = State_normal
		end

feature -- Access

	label: STRING_32
			-- Button text label

	state: INTEGER
			-- Button interaction state

	text_color: COLOR
			-- Foreground text color

	bg_color: COLOR
			-- Button body color

	highlight_color: COLOR
			-- Top/left bevel highlight color

	shadow_color: COLOR
			-- Bottom/right bevel shadow color

feature -- State Constants

	State_normal: INTEGER = 1
			-- Inactive button

	State_selected: INTEGER = 2
			-- Keyboard focused button

	State_active: INTEGER = 3
			-- Pressed button

feature -- Configuration Builders

	with_state (a_state: INTEGER): BUTTON_WIDGET
			-- Return clone with state set to `a_state`.
		require
			valid_state: a_state = State_normal or a_state = State_selected or a_state = State_active
		do
			create Result.make (label)
			Result.set_colors (text_color, bg_color, highlight_color, shadow_color)
			Result.set_state_internal (a_state)
		ensure
			state_set: Result.state = a_state
		end

	with_colors (a_text, a_bg, a_highlight, a_shadow: COLOR): BUTTON_WIDGET
			-- Return clone with custom theme colors.
		do
			create Result.make (label)
			Result.set_colors (a_text, a_bg, a_highlight, a_shadow)
			Result.set_state_internal (state)
		end

feature {BUTTON_WIDGET} -- Internal Setters

	set_state_internal (a_state: INTEGER)
			-- Internal mutation for builder.
		do
			state := a_state
		end

	set_colors (a_text, a_bg, a_highlight, a_shadow: COLOR)
			-- Internal mutation for builder.
		do
			text_color := a_text
			bg_color := a_bg
			highlight_color := a_highlight
			shadow_color := a_shadow
		end

feature -- Rendering

	render (a_area: RECT; a_buffer: BUFFER)
			-- Render beveled button into `a_buffer`.
		local
			l_body_style, l_hi_style, l_sh_style: STYLE
			l_cur_bg, l_cur_fg, l_cur_hi, l_cur_sh: COLOR
			l_top_bar, l_bot_bar: STRING_32
			l_lbl_x, l_lbl_y, l_lbl_w, i: INTEGER
		do
			if not a_area.is_empty then
				-- Color scheme depending on state
				inspect state
				when State_selected then
					l_cur_bg := highlight_color
					l_cur_fg := text_color
					l_cur_hi := highlight_color
					l_cur_sh := shadow_color
				when State_active then
					l_cur_bg := bg_color
					l_cur_fg := text_color
					l_cur_hi := shadow_color
					l_cur_sh := highlight_color
				else -- State_normal
					l_cur_bg := bg_color
					l_cur_fg := text_color
					l_cur_hi := highlight_color
					l_cur_sh := shadow_color
				end

				create l_body_style.make_with_colors (l_cur_fg, l_cur_bg)
				create l_hi_style.make_with_colors (l_cur_hi, l_cur_bg)
				create l_sh_style.make_with_colors (l_cur_sh, l_cur_bg)

				-- Fill entire area
				a_buffer.set_style (a_area, l_body_style)

				-- Top bevel line if height > 2
				if a_area.height > 2 then
					create l_top_bar.make_filled ('%U', a_area.width.to_integer_32)
					from i := 1 until i > a_area.width.to_integer_32 loop
						l_top_bar.put_code (9620, i) -- '▔' (Overline U+2594)
						i := i + 1
					end
					a_buffer.put_string (a_area.y.to_integer_32, a_area.x.to_integer_32, l_top_bar, l_hi_style)
				end

				-- Bottom bevel line if height > 1
				if a_area.height > 1 then
					create l_bot_bar.make_filled ('%U', a_area.width.to_integer_32)
					from i := 1 until i > a_area.width.to_integer_32 loop
						l_bot_bar.put_code (9601, i) -- ' ' (Lower 1/8 block U+2581)
						i := i + 1
					end
					a_buffer.put_string ((a_area.y + a_area.height - 1).to_integer_32, a_area.x.to_integer_32, l_bot_bar, l_sh_style)
				end

				-- Centered label
				l_lbl_w := label.count
				l_lbl_x := a_area.x.to_integer_32 + ((a_area.width.to_integer_32 - l_lbl_w).max (0) // 2)
				l_lbl_y := a_area.y.to_integer_32 + ((a_area.height.to_integer_32 - 1).max (0) // 2)

				a_buffer.set_stringn (l_lbl_y, l_lbl_x, label, a_area.width.to_integer_32, l_body_style)
			end
		end

end
