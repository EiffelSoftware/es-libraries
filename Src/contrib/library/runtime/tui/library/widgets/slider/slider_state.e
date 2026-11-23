note
	description: "[
		Mutable state for TUI_SLIDER: a value in [`minimum`, `maximum`] that moves by `step`.
		Ratatui has no slider (third-party crates draw their own); this is EiffelTUI's own.

		Values are INTEGER_64. A fractional slider is an integer one with a scale chosen by the
		application: 0.0 .. 1.0 by 0.05 is 0 .. 100 by 5, shown with a label format agent
		(TUI_SLIDER.with_label_format). Integers keep the snapping exact, where REAL_64 steps
		would drift.

		Valid values: `minimum` + k * `step` for k >= 0, up to `maximum`, and `maximum` itself
		even when the range is not a whole number of steps (0 .. 10 by 3: 0, 3, 6, 9, 10).
		`set_value` clamps to the range, then snaps to the nearest valid value; a tie goes to
		the larger one. `increase` and `decrease` move to the next valid value either way.

		Every distance is computed as a NATURAL_64 offset from `minimum`, so the whole
		INTEGER_64 range (`maximum` - `minimum` up to 2^64 - 1) works without overflow, and
		`thumb_cell` / `set_from_position` scale through `scaled_rounded`, which is exact for
		every NATURAL_64 (as {TUI_SPARKLINE}.scaled_ticks).

		Mouse: `set_from_position (a_cell, a_track_length)` maps a cell of a track to a value,
		and `thumb_cell (a_track_length)` maps the value back to the thumb's cell. The track's
		geometry stays with the widget (TUI_SLIDER.track_area, `track_cell`), as
		{TEXT_AREA_STATE}.scroll_to_row keeps the text area's layout out of its state.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	SLIDER_STATE

inherit
	WIDGET_STATE
		redefine
			default_create
		end

create
	default_create,
	make

feature {NONE} -- Initialization

	default_create
			-- 0 .. 100 by 1, at 0.
		do
			maximum := 100
			step := 1
		ensure then
			minimum_zero: minimum = 0
			maximum_hundred: maximum = 100
			step_one: step = 1
			at_minimum: value = 0
		end

	make (a_minimum, a_maximum, a_step: INTEGER_64)
			-- `a_minimum` .. `a_maximum` by `a_step`, at `a_minimum`.
		require
			ordered: a_minimum <= a_maximum
			positive_step: a_step > 0
		do
			minimum := a_minimum
			maximum := a_maximum
			step := a_step
			value := a_minimum
		ensure
			minimum_set: minimum = a_minimum
			maximum_set: maximum = a_maximum
			step_set: step = a_step
			at_minimum: value = a_minimum
		end

feature -- Access

	minimum: INTEGER_64
			-- Smallest value

	maximum: INTEGER_64
			-- Largest value

	step: INTEGER_64
			-- Distance between two valid values

	value: INTEGER_64
			-- Current value

	page_steps: INTEGER = 10
			-- Steps taken by `increase_page` and `decrease_page`

	span: NATURAL_64
			-- `maximum` - `minimum`, exact for the whole INTEGER_64 range
		do
			Result := offset_of (maximum)
		end

	thumb_cell (a_track_length: INTEGER): INTEGER
			-- 0-based cell of the thumb on a track of `a_track_length` cells, counted from the
			-- `minimum` end: (`value` - `minimum`) / (`maximum` - `minimum`) * (`a_track_length` - 1),
			-- rounded half away from zero. 0 when `minimum` = `maximum`.
		require
			positive_length: a_track_length > 0
		do
			if span > 0 and a_track_length > 1 then
				Result := scaled_rounded (offset_of (value), (a_track_length - 1).to_natural_64, span).to_integer_32
			end
		ensure
			in_track: Result >= 0 and Result < a_track_length
			empty_range_at_start: span = 0 implies Result = 0
			minimum_at_start: value = minimum implies Result = 0
			maximum_at_end: (value = maximum and span > 0) implies Result = a_track_length - 1
		end

feature -- Status report

	is_valid_value (a_value: INTEGER_64): BOOLEAN
			-- Is `a_value` in the range and on a step (or `maximum`)?
		do
			Result := minimum <= a_value and a_value <= maximum
				and then (a_value = maximum or else offset_of (a_value) \\ step.to_natural_64 = 0)
		end

	is_at_minimum: BOOLEAN
			-- Is `value` `minimum`?
		do
			Result := value = minimum
		end

	is_at_maximum: BOOLEAN
			-- Is `value` `maximum`?
		do
			Result := value = maximum
		end

feature -- Element change

	set_value (a_value: INTEGER_64)
			-- Set `value` to `a_value` clamped to the range and snapped to the nearest valid
			-- value (a tie goes to the larger one).
		do
			value := snapped (a_value)
		ensure
			valid: is_valid_value (value)
			kept: is_valid_value (a_value) implies value = a_value
			clamped_low: a_value <= minimum implies value = minimum
			clamped_high: a_value >= maximum implies value = maximum
		end

	set_range (a_minimum, a_maximum: INTEGER_64)
			-- Use `a_minimum` .. `a_maximum`; `value` is clamped and snapped again.
		require
			ordered: a_minimum <= a_maximum
		local
			l_old: INTEGER_64
		do
			l_old := value
			minimum := a_minimum
			maximum := a_maximum
			value := snapped (l_old)
		ensure
			minimum_set: minimum = a_minimum
			maximum_set: maximum = a_maximum
			valid: is_valid_value (value)
		end

	set_step (a_step: INTEGER_64)
			-- Move by `a_step`; `value` is snapped again.
		require
			positive_step: a_step > 0
		do
			step := a_step
			value := snapped (value)
		ensure
			step_set: step = a_step
			valid: is_valid_value (value)
		end

	set_to_minimum
			-- Set `value` to `minimum`.
		do
			value := minimum
		ensure
			at_minimum: value = minimum
		end

	set_to_maximum
			-- Set `value` to `maximum`.
		do
			value := maximum
		ensure
			at_maximum: value = maximum
		end

	increase
			-- Move `value` to the next valid value up, if any.
		local
			d, l_lo, l_step, l_span: NATURAL_64
		do
			d := offset_of (value)
			l_span := span
			if d < l_span then
				l_step := step.to_natural_64
				l_lo := d - d \\ l_step
				if l_span - l_lo <= l_step then
					d := l_span
				else
					d := l_lo + l_step
				end
				value := value_at (d)
			end
		ensure
			up: old value < maximum implies value > old value
			at_top: old value = maximum implies value = maximum
			at_most_one_step: value - old value <= step or else value = maximum
			valid: is_valid_value (value)
		end

	decrease
			-- Move `value` to the next valid value down, if any.
		local
			d, r: NATURAL_64
		do
			d := offset_of (value)
			if d > 0 then
				r := d \\ step.to_natural_64
				if r /= 0 then
					d := d - r
				else
					d := d - step.to_natural_64
				end
				value := value_at (d)
			end
		ensure
			down: old value > minimum implies value < old value
			at_bottom: old value = minimum implies value = minimum
			valid: is_valid_value (value)
		end

	increase_page
			-- `increase` `page_steps` times (stops at `maximum`).
		local
			i: INTEGER
		do
			from i := 1 until i > page_steps or value = maximum loop
				increase
				i := i + 1
			end
		ensure
			up: old value < maximum implies value > old value
			valid: is_valid_value (value)
		end

	decrease_page
			-- `decrease` `page_steps` times (stops at `minimum`).
		local
			i: INTEGER
		do
			from i := 1 until i > page_steps or value = minimum loop
				decrease
				i := i + 1
			end
		ensure
			down: old value > minimum implies value < old value
			valid: is_valid_value (value)
		end

feature -- Mouse

	set_from_position (a_cell, a_track_length: INTEGER)
			-- Set `value` from cell `a_cell` of a track of `a_track_length` cells, counted from
			-- the `minimum` end: `minimum` + `a_cell` / (`a_track_length` - 1) * (`maximum` - `minimum`),
			-- rounded half away from zero, then snapped as `set_value`. A cell before the track
			-- gives `minimum` and one after it `maximum`, so a drag past either end stops there.
			-- A one-cell track has no scale and leaves `value` as it is.
		require
			positive_length: a_track_length > 0
		local
			l_cell: INTEGER
		do
			if a_track_length > 1 then
				l_cell := a_cell.max (0).min (a_track_length - 1)
				value := snapped_offset (scaled_rounded (l_cell.to_natural_64, span, (a_track_length - 1).to_natural_64))
			end
		ensure
			valid: is_valid_value (value)
			one_cell_unchanged: a_track_length = 1 implies value = old value
			first_cell: (a_track_length > 1 and a_cell <= 0) implies value = minimum
			last_cell: (a_track_length > 1 and a_cell >= a_track_length - 1) implies value = maximum
		end

feature -- Scaling

	scaled_rounded (a_value, a_factor, a_divisor: NATURAL_64): NATURAL_64
			-- `a_value` * `a_factor` / `a_divisor`, rounded half up (half away from zero), for
			-- `a_value` <= `a_divisor`. Exact for every NATURAL_64: the product is not formed when
			-- it would overflow (long multiplication modulo `a_divisor`, as
			-- {TUI_SPARKLINE}.scaled_ticks).
		require
			positive_divisor: a_divisor > 0
			value_in_range: a_value <= a_divisor
		local
			i: INTEGER
			q, r: NATURAL_64
		do
			if a_value = a_divisor then
				q := a_factor
			elseif a_factor = 0 or else a_value <= {NATURAL_64}.max_value // a_factor then
				q := (a_value * a_factor) // a_divisor
				r := (a_value * a_factor) \\ a_divisor
			else
					-- After each step, `a_value` * (the bits of `a_factor` so far) = q * `a_divisor` + r,
					-- with r < `a_divisor` (here `a_value` < `a_divisor`, so q never overflows)
				from
					i := 63
				until
					i < 0
				loop
					q := q + q
					if r >= a_divisor - r then
						r := r - (a_divisor - r)
						q := q + 1
					else
						r := r + r
					end
					if a_factor.bit_test (i) then
						if r >= a_divisor - a_value then
							r := r - (a_divisor - a_value)
							q := q + 1
						else
							r := r + a_value
						end
					end
					i := i - 1
				end
			end
			if r > 0 and then r >= a_divisor - r then
				q := q + 1
			end
			Result := q
		ensure
			instance_free: class
			bounded: Result <= a_factor
			full: a_value = a_divisor implies Result = a_factor
			zero: a_value = 0 implies Result = 0
		end

feature {NONE} -- Implementation

	offset_of (a_value: INTEGER_64): NATURAL_64
			-- `a_value` - `minimum` as a NATURAL_64 (exact for `a_value` >= `minimum`: the
			-- difference of the two bit patterns modulo 2^64)
		do
			Result := a_value.as_natural_64 - minimum.as_natural_64
		end

	value_at (a_offset: NATURAL_64): INTEGER_64
			-- `minimum` + `a_offset`, for `a_offset` <= `span`
		do
			Result := (minimum.as_natural_64 + a_offset).as_integer_64
		end

	snapped (a_value: INTEGER_64): INTEGER_64
			-- `a_value` clamped to the range and snapped to the nearest valid value
		do
			if a_value <= minimum then
				Result := minimum
			elseif a_value >= maximum then
				Result := maximum
			else
				Result := snapped_offset (offset_of (a_value))
			end
		end

	snapped_offset (a_offset: NATURAL_64): INTEGER_64
			-- Valid value nearest to `minimum` + `a_offset` (`a_offset` <= `span`); a tie goes
			-- to the larger one
		local
			r, l_step, l_lo, l_hi, l_span: NATURAL_64
		do
			l_step := step.to_natural_64
			l_span := span
			r := a_offset \\ l_step
			if r = 0 then
				Result := value_at (a_offset)
			else
				l_lo := a_offset - r
				if l_span - l_lo <= l_step then
					l_hi := l_span
				else
					l_hi := l_lo + l_step
				end
				if l_hi - a_offset <= r then
					Result := value_at (l_hi)
				else
					Result := value_at (l_lo)
				end
			end
		end

invariant
	ordered: minimum <= maximum
	positive_step: step > 0
	value_in_range: minimum <= value and value <= maximum
	value_on_step: is_valid_value (value)

end
