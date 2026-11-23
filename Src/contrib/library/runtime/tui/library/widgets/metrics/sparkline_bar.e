note
	description: "[
		One bar of a TUI_SPARKLINE (Ratatui `SparklineBar`): a value, or the absence of a value,
		and an optional style of its own.
		An absent bar (`is_absent`, Ratatui `value: None`) is not the same as a bar of value 0:
		it is drawn with the sparkline's `absent_value_symbol` and `absent_value_style` over the
		whole height, and it does not count for the automatic maximum.
		The bar's `style`, when set, is patched over the sparkline's styles (Ratatui
		`self.style.patch (item.style)`); a Void style leaves them as they are.
		A reference class with `is_equal` and `copy`, not expanded: EiffelStudio 26.09 crashes
		at start when a new expanded class is melted into a frozen workbench build.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	SPARKLINE_BAR

inherit
	ANY
		redefine
			is_equal
		end

create
	make,
	make_absent

feature {NONE} -- Initialization

	make (a_value: NATURAL_64)
			-- Bar of `a_value`, without a style of its own (Ratatui `SparklineBar::from (u64)`).
		do
			value := a_value
			is_absent := False
			style := Void
		ensure
			value_set: value = a_value
			present: not is_absent
			no_style: style = Void
		end

	make_absent
			-- Bar without a value, without a style of its own (Ratatui `SparklineBar::from (None)`).
		do
			value := 0
			is_absent := True
			style := Void
		ensure
			absent: is_absent
			no_style: style = Void
		end

feature -- Access

	value: NATURAL_64
			-- Value of the bar (0 when `is_absent`)

	is_absent: BOOLEAN
			-- Has the bar no value (Ratatui `value: None`)?

	style: detachable STYLE
			-- Style patched over the sparkline's styles for this bar; Void uses them as they are

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Same value or absence, and same style (both Void, or equal)?
		do
			Result := value = a_other.value and is_absent = a_other.is_absent
			if Result then
				if attached style as s then
					Result := attached a_other.style as o and then s.is_equal (o)
				else
					Result := a_other.style = Void
				end
			end
		end

feature -- Element change

	set_value (a_value: NATURAL_64)
			-- Make the bar present with `a_value`.
		do
			value := a_value
			is_absent := False
		ensure
			value_set: value = a_value
			present: not is_absent
			style_kept: style = old style
		end

	set_absent
			-- Make the bar absent.
		do
			value := 0
			is_absent := True
		ensure
			absent: is_absent
			style_kept: style = old style
		end

	set_style (a_style: detachable STYLE)
			-- Set the bar's own style; Void removes it.
		do
			style := a_style
		ensure
			style_set: style = a_style
		end

feature -- Fluent Builders

	with_value (a_value: NATURAL_64): like Current
			-- Copy of the bar, present with `a_value`.
		do
			Result := twin
			Result.set_value (a_value)
		ensure
			value_set: Result.value = a_value
			present: not Result.is_absent
		end

	with_absent: like Current
			-- Copy of the bar, absent.
		do
			Result := twin
			Result.set_absent
		ensure
			absent: Result.is_absent
		end

	with_style (a_style: detachable STYLE): like Current
			-- Copy of the bar with its own `a_style` (Ratatui `SparklineBar::style`); Void removes it.
		do
			Result := twin
			Result.set_style (a_style)
		ensure
			style_set: Result.style = a_style
			value_kept: Result.value = value and Result.is_absent = is_absent
		end

invariant
	absent_is_zero: is_absent implies value = 0

end
