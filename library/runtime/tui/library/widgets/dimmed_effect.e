note
	description: "[
		Shadow effect that dims the cells under the shadow (Ratatui `Dimmed`): it adds the
		DIM modifier and halves an RGB background, channel by channel; any other background
		(named, indexed, default or reset) becomes black. The symbols are kept.
		Use it as `create {SHADOW}.make_custom (create {DIMMED_EFFECT})`.
		Continuation cells (the right half of a wide character) are skipped: the terminal
		draws a wide character with the style of its first cell.
		It keeps no state between calls (see CELL_EFFECT).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	DIMMED_EFFECT

inherit
	CELL_EFFECT

feature -- Basic operations

	apply (a_shadow_area, a_base_area: RECT; a_buffer: BUFFER)
			-- Dim the cells of `a_shadow_area` outside `a_base_area`.
		local
			r, c: INTEGER
			l_cell: TERMINAL_CELL
		do
			across visible_regions (a_shadow_area, a_base_area) as l_region loop
				from
					r := l_region.top.to_integer_32
				until
					r >= l_region.bottom.to_integer_32
				loop
					from
						c := l_region.left.to_integer_32
					until
						c >= l_region.right.to_integer_32
					loop
						l_cell := a_buffer.cell (r, c)
						if not l_cell.is_continuation then
							l_cell.set_style (dimmed (l_cell.style))
						end
						c := c + 1
					end
					r := r + 1
				end
			end
		end

feature -- Access

	dimmed (a_style: STYLE): STYLE
			-- `a_style` with DIM added and its background halved (RGB) or black (otherwise)
		require
			style_not_void: a_style /= Void
		local
			l_bg: COLOR
		do
			l_bg := a_style.background
			if l_bg.is_rgb then
				Result := a_style.with_dim.with_background ({COLOR}.rgb (l_bg.r // 2, l_bg.g // 2, l_bg.b // 2))
			else
				Result := a_style.with_dim.with_background ({COLOR}.Black)
			end
		ensure
			instance_free: class
			dim: Result.is_dim
			rgb_halved: a_style.background.is_rgb implies (Result.background.is_rgb
				and Result.background.r = a_style.background.r // 2
				and Result.background.g = a_style.background.g // 2
				and Result.background.b = a_style.background.b // 2)
			black_otherwise: not a_style.background.is_rgb implies Result.background ~ {COLOR}.Black
			foreground_kept: Result.foreground ~ a_style.foreground
		end

end
