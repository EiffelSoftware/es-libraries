note
	description: "[
		Custom shadow effect for TEST_BLOCK_SHADOW: writes '+' into every visible shadow cell,
		as the `PlusFilter` of Ratatui's shadow.rs test `custom_filter_is_applied`.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	PLUS_TEST_EFFECT

inherit
	CELL_EFFECT

feature -- Basic operations

	apply (a_shadow_area, a_base_area: RECT; a_buffer: BUFFER)
			-- Put '+' in the cells of `a_shadow_area` outside `a_base_area`.
		local
			r, c: INTEGER
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
						put_shadow_symbol (a_buffer, r, c, '+')
						c := c + 1
					end
					r := r + 1
				end
			end
		end

end
