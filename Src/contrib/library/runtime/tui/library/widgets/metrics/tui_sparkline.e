note
	description: "[
		Inline data trend chart widget rendering 8-level vertical Unicode bar characters
		(' ', '▂', '▃', '▄', '▅', '▆', '▇', '█') over one or more rows.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TUI_SPARKLINE

inherit
	WIDGET
		redefine
			default_create,
			copy,
			is_equal
		end
	BLOCK_CONTAINER
		redefine
			default_create,
			copy,
			is_equal
		end

create
	default_create,
	make,
	make_with_data

feature {NONE} -- Initialization

	default_create
			-- Initialize as an empty sparkline.
		do
			create data.make (16)
			max_value := 0
			direction := {SPARKLINE_DIRECTION}.Left_to_right
			create style.default_create
			create bar_style.default_create
		ensure then
			data_empty: data.is_empty
			auto_max: max_value = 0
			direction_ltr: not is_right_to_left
			no_block: block = Void
		end

	make
			-- Synonym for `default_create`.
		do
			default_create
		end

	make_with_data (a_data: ITERABLE [NATURAL_64])
			-- Initialize with `a_data`.
		require
			data_not_void: a_data /= Void
		do
			default_create
			set_data (a_data)
		end

feature -- Duplication

	copy (a_other: like Current)
			-- Re-create data points on copy.
		do
			if a_other /= Current then
				standard_copy (a_other)
				data := a_other.data.twin
			end
		end

	is_equal (a_other: like Current): BOOLEAN
			-- Is `a_other` content-equal to `Current`?
		local
			i: INTEGER
		do
			if a_other = Current then
				Result := True
			elseif standard_is_equal (a_other) then
				Result := True
			elseif max_value = a_other.max_value
				and direction = a_other.direction
				and same_block (a_other)
				and style.is_equal (a_other.style)
				and bar_style.is_equal (a_other.bar_style)
				and data.count = a_other.data.count
			then
				Result := True
				from
					i := 1
				until
					i > data.count or not Result
				loop
					Result := data [i] = a_other.data [i]
					i := i + 1
				end
			end
		end

feature -- Access

	data: ARRAYED_LIST [NATURAL_64]
			-- Sequence of numerical data points

	max_value: NATURAL_64
			-- Explicit maximum value for scale calculation (0 = auto-compute from data)

	direction: INTEGER
			-- Render direction ({SPARKLINE_DIRECTION}.Left_to_right or Right_to_left)

	is_right_to_left: BOOLEAN
			-- Render sparkline from right to left?
		do
			Result := direction = {SPARKLINE_DIRECTION}.Right_to_left
		end

	style: STYLE
			-- Base style

	bar_style: STYLE
			-- Style applied to trend bar characters

feature -- Element change

	set_data (a_data: ITERABLE [NATURAL_64])
			-- Replace dataset with `a_data`.
		require
			data_not_void: a_data /= Void
		do
			data.wipe_out
			across
				a_data as d
			loop
				data.extend (d)
			end
		end

	append_value (a_val: NATURAL_64)
			-- Add a single point `a_val` to dataset.
		do
			data.extend (a_val)
		ensure
			value_added: data.count = old data.count + 1
			last_value: data.last = a_val
		end

	set_max_value (a_max: NATURAL_64)
			-- Set explicit scaling maximum.
		do
			max_value := a_max
		ensure
			max_value_set: max_value = a_max
		end

	set_direction (a_direction: INTEGER)
			-- Set render direction.
		require
			valid_direction: {SPARKLINE_DIRECTION}.is_valid (a_direction)
		do
			direction := a_direction
		ensure
			direction_set: direction = a_direction
		end

	set_right_to_left (a_rtl: BOOLEAN)
			-- Set render direction.
		do
			if a_rtl then
				direction := {SPARKLINE_DIRECTION}.Right_to_left
			else
				direction := {SPARKLINE_DIRECTION}.Left_to_right
			end
		ensure
			direction_set: is_right_to_left = a_rtl
		end

	set_style (a_style: STYLE)
			-- Set base style.
		require
			style_not_void: a_style /= Void
		do
			style := a_style
		ensure
			style_set: style = a_style
		end

	set_bar_style (a_style: STYLE)
			-- Set bar style.
		require
			style_not_void: a_style /= Void
		do
			bar_style := a_style
		ensure
			bar_style_set: bar_style = a_style
		end

feature -- Fluent Builders

	with_data (a_data: ITERABLE [NATURAL_64]): like Current
			-- Sparkline with `a_data`.
		require
			data_not_void: a_data /= Void
		do
			Result := twin
			Result.set_data (a_data)
		end

	with_max_value (a_max: NATURAL_64): like Current
			-- Sparkline with explicit `a_max`.
		do
			Result := twin
			Result.set_max_value (a_max)
		ensure
			max_value_set: Result.max_value = a_max
		end

	with_direction (a_direction: INTEGER): like Current
			-- Sparkline with render direction.
		require
			valid_direction: {SPARKLINE_DIRECTION}.is_valid (a_direction)
		do
			Result := twin
			Result.set_direction (a_direction)
		ensure
			direction_set: Result.direction = a_direction
		end

	with_style (a_style: STYLE): like Current
			-- Sparkline with base `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_style (a_style)
		ensure
			style_set: Result.style = a_style
		end

	with_bar_style (a_style: STYLE): like Current
			-- Sparkline with `a_style`.
		require
			style_not_void: a_style /= Void
		do
			Result := twin
			Result.set_bar_style (a_style)
		ensure
			bar_style_set: Result.bar_style = a_style
		end

feature -- Rendering

	render (a_area: RECT; a_buffer: BUFFER)
			-- Render sparkline into `a_buffer` within `a_area`.
		local
			l_target: RECT
			l_eff_max: NATURAL_64
			l_avail_cols, l_avail_rows: INTEGER
			l_total_sublevels: NATURAL_64
			l_data_idx: INTEGER
			l_val, l_sublevel: NATURAL_64
			l_rem_level: NATURAL_64
			c, r, l_abs_x, l_abs_y: INTEGER
			l_char: CHARACTER_32
			l_style: STYLE
		do
			if not a_area.is_empty then
				render_block (a_area, a_buffer)
				l_target := inner_area (a_area)

				if not l_target.is_empty and l_target.width > 0 and l_target.height > 0 then
					l_avail_cols := l_target.width.to_integer_32
					l_avail_rows := l_target.height.to_integer_32

					-- Determine effective max value
					if max_value > 0 then
						l_eff_max := max_value
					else
						l_eff_max := 0
						across
							data as d
						loop
							if d > l_eff_max then
								l_eff_max := d
							end
						end
						if l_eff_max = 0 then
							l_eff_max := 1
						end
					end

					l_total_sublevels := (l_avail_rows * 8).to_natural_64

					from
						c := 0
					until
						c >= l_avail_cols or (l_target.x.to_integer_32 + c) >= a_buffer.width
					loop
						l_abs_x := l_target.x.to_integer_32 + c

						-- Determine data index for this column
						if direction = {SPARKLINE_DIRECTION}.Right_to_left then
							l_data_idx := l_avail_cols - c
						else
							l_data_idx := c + 1
						end

						if l_data_idx >= 1 and l_data_idx <= data.count then
							l_val := data.i_th (l_data_idx)
							l_sublevel := ((l_val * l_total_sublevels) // l_eff_max).min (l_total_sublevels)
						else
							l_sublevel := 0
						end

						-- Render rows from bottom (r = 0) up to top (r = l_avail_rows - 1)
						l_rem_level := l_sublevel
						from
							r := 0
						until
							r >= l_avail_rows
						loop
							l_abs_y := l_target.bottom.to_integer_32 - 1 - r

							if l_abs_y >= 0 and l_abs_y < a_buffer.height then
								if l_rem_level >= 8 then
									l_char := (9608).to_character_32 -- Full block '█'
									l_style := bar_style
									l_rem_level := l_rem_level - 8
								elseif l_rem_level > 0 then
									l_char := (9600 + l_rem_level.to_integer_32).to_character_32 -- ' '..'▇'
									l_style := bar_style
									l_rem_level := 0
								else
									l_char := ' '
									l_style := style
								end

								a_buffer.put_char (l_abs_y, l_abs_x, l_char, l_style)
							end
							r := r + 1
						end

						c := c + 1
					end
				end
			end
		end

invariant
	data_not_void: data /= Void
	style_not_void: style /= Void
	bar_style_not_void: bar_style /= Void
	valid_direction: {SPARKLINE_DIRECTION}.is_valid (direction)

end
