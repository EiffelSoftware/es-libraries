note
	description: "[
		Mutable state for TUI_CALENDAR tracking selected year, month, and day,
		with calendar navigation commands and Gregorian date math.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	CALENDAR_STATE

inherit
	WIDGET_STATE
		redefine
			default_create
		end

create
	default_create,
	make,
	make_with_date

feature {NONE} -- Initialization

	default_create
			-- Initialize to 2026-01-01.
		do
			year := 2026
			month := 1
			selected_day := 1
		ensure then
			default_year: year = 2026
			default_month: month = 1
			default_day: selected_day = 1
		end

	make
			-- Synonym for `default_create`.
		do
			default_create
		end

	make_with_date (a_year, a_month, a_day: INTEGER)
			-- Initialize with specific date.
		require
			month_valid: a_month >= 1 and a_month <= 12
			day_valid: a_day >= 1 and a_day <= days_in_month (a_year, a_month)
		do
			year := a_year
			month := a_month
			selected_day := a_day
		ensure
			year_set: year = a_year
			month_set: month = a_month
			day_set: selected_day = a_day
		end

feature -- Access

	year: INTEGER
			-- Currently displayed year

	month: INTEGER
			-- Currently displayed month (1..12)

	selected_day: INTEGER
			-- Selected day of the month (1..days_in_month)

feature -- Query & Calculations

	is_leap_year (a_year: INTEGER): BOOLEAN
			-- Is `a_year` a Gregorian leap year?
		do
			Result := (a_year \\ 4 = 0 and a_year \\ 100 /= 0) or (a_year \\ 400 = 0)
		ensure
			instance_free: class
		end

	days_in_month (a_year, a_month: INTEGER): INTEGER
			-- Number of days in month `a_month` for year `a_year`.
		require
			valid_month: a_month >= 1 and a_month <= 12
		do
			inspect a_month
			when 1, 3, 5, 7, 8, 10, 12 then
				Result := 31
			when 4, 6, 9, 11 then
				Result := 30
			when 2 then
				if is_leap_year (a_year) then
					Result := 29
				else
					Result := 28
				end
			end
		ensure
			instance_free: class
			valid_days: Result >= 28 and Result <= 31
		end

	days_in_current_month: INTEGER
			-- Number of days in current month.
		do
			Result := days_in_month (year, month)
		ensure
			valid_days: Result = days_in_month (year, month)
		end

	first_weekday_of_month: INTEGER
			-- 1-based day of week for the 1st of `year`/`month`.
			-- 1 = Monday, 2 = Tuesday, ..., 7 = Sunday.
		do
			Result := day_of_week (year, month, 1)
		ensure
			valid_weekday: Result >= 1 and Result <= 7
		end

	day_of_week (a_year, a_month, a_day: INTEGER): INTEGER
			-- Day of week using Tomohiko Sakamoto algorithm.
			-- Returns 1 for Monday, ..., 7 for Sunday.
		require
			valid_month: a_month >= 1 and a_month <= 12
			valid_day: a_day >= 1 and a_day <= days_in_month (a_year, a_month)
		local
			y, m, l_dow: INTEGER
			l_t: ARRAY [INTEGER]
		do
			l_t := <<0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4>>
			y := a_year
			m := a_month
			if m < 3 then
				y := y - 1
			end
			-- Floor division and a non-negative remainder keep the formula valid for years <= 0
			-- (proleptic Gregorian calendar, year 0 = 1 BC), which `previous_year` can reach.
			l_dow := ((y + floor_div (y, 4) - floor_div (y, 100) + floor_div (y, 400) + l_t.item (m) + a_day) \\ 7 + 7) \\ 7
			-- 0 is Sunday in Sakamoto formula; convert to 1=Monday..7=Sunday
			if l_dow = 0 then
				Result := 7
			else
				Result := l_dow
			end
		ensure
			valid_weekday: Result >= 1 and Result <= 7
		end

	month_name: STRING_32
			-- English name of current month.
		do
			inspect month
			when 1 then Result := "January"
			when 2 then Result := "February"
			when 3 then Result := "March"
			when 4 then Result := "April"
			when 5 then Result := "May"
			when 6 then Result := "June"
			when 7 then Result := "July"
			when 8 then Result := "August"
			when 9 then Result := "September"
			when 10 then Result := "October"
			when 11 then Result := "November"
			when 12 then Result := "December"
			else
				Result := "Unknown"
			end
		ensure
			result_not_void: Result /= Void
		end

feature -- Element Change & Navigation

	set_date (a_year, a_month, a_day: INTEGER)
			-- Set calendar date.
		require
			valid_month: a_month >= 1 and a_month <= 12
			valid_day: a_day >= 1 and a_day <= days_in_month (a_year, a_month)
		do
			year := a_year
			month := a_month
			selected_day := a_day
		ensure
			year_set: year = a_year
			month_set: month = a_month
			day_set: selected_day = a_day
		end

	select_day (a_day: INTEGER)
			-- Select day in current month.
		require
			valid_day: a_day >= 1 and a_day <= days_in_current_month
		do
			selected_day := a_day
		ensure
			day_set: selected_day = a_day
		end

	next_day
			-- Advance selected day by 1, rolling over month/year if necessary.
		do
			if selected_day < days_in_current_month then
				selected_day := selected_day + 1
			else
				next_month
				selected_day := 1
			end
		end

	previous_day
			-- Retreat selected day by 1, rolling over month/year if necessary.
		do
			if selected_day > 1 then
				selected_day := selected_day - 1
			else
				previous_month
				selected_day := days_in_current_month
			end
		end

	next_week
			-- Advance selected day by 7 days.
		do
			if selected_day + 7 <= days_in_current_month then
				selected_day := selected_day + 7
			else
				selected_day := (selected_day + 7) - days_in_current_month
				next_month
				selected_day := selected_day.min (days_in_current_month)
			end
		end

	previous_week
			-- Retreat selected day by 7 days.
		local
			l_prev_days: INTEGER
		do
			if selected_day > 7 then
				selected_day := selected_day - 7
			else
				previous_month
				l_prev_days := days_in_current_month
				selected_day := l_prev_days - (7 - selected_day)
				selected_day := selected_day.max (1).min (l_prev_days)
			end
		end

	next_month
			-- Advance to next month.
		do
			if month < 12 then
				month := month + 1
			else
				month := 1
				year := year + 1
			end
			selected_day := selected_day.min (days_in_current_month)
		end

	previous_month
			-- Retreat to previous month.
		do
			if month > 1 then
				month := month - 1
			else
				month := 12
				year := year - 1
			end
			selected_day := selected_day.min (days_in_current_month)
		end

	next_year
			-- Advance to next year.
		do
			year := year + 1
			selected_day := selected_day.min (days_in_current_month)
		end

	previous_year
			-- Retreat to previous year.
		do
			year := year - 1
			selected_day := selected_day.min (days_in_current_month)
		end

feature {NONE} -- Implementation

	floor_div (a, b: INTEGER): INTEGER
			-- `a` divided by `b`, rounded towards minus infinity
		require
			positive_divisor: b > 0
		do
			if a >= 0 then
				Result := a // b
			else
				Result := -((-a + b - 1) // b)
			end
		ensure
			floor: Result * b <= a and a < (Result + 1) * b
		end

invariant
	valid_month: month >= 1 and month <= 12
	valid_day: selected_day >= 1 and selected_day <= days_in_current_month

end
