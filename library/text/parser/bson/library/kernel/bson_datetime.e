note
	description: "[
		BSON_DATETIME represents a UTC datetime in BSON.
		
		In BSON, datetime is serialized as:
		int64 - UTC milliseconds since the Unix epoch (Jan 1, 1970)
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	BSON_DATETIME

inherit
	BSON_VALUE
		redefine
			is_datetime
		end

	BSON_CONSTANTS
		undefine
			is_equal
		end

create
	make,
	make_from_date_time,
	make_now

feature {NONE} -- Initialization

	make (a_milliseconds: INTEGER_64)
			-- Initialize with milliseconds since Unix epoch.
		do
			milliseconds := a_milliseconds
		ensure
			milliseconds_set: milliseconds = a_milliseconds
		end

	make_from_date_time (a_date_time: DATE_TIME)
			-- Initialize from DATE_TIME.
		require
			a_date_time_not_void: a_date_time /= Void
		local
			l_epoch: DATE_TIME
			l_duration: DATE_TIME_DURATION
		do
			create l_epoch.make_from_epoch (0)
			l_duration := a_date_time.definite_duration (l_epoch)
			milliseconds := l_duration.seconds_count * 1000
		end

	make_now
			-- Initialize with current UTC time.
		local
			l_now: DATE_TIME
		do
			create l_now.make_now_utc
			make_from_date_time (l_now)
		end

feature -- Status report

	is_datetime: BOOLEAN = True
			-- <Precursor>

feature -- Access

	bson_type: INTEGER_8
			-- <Precursor>
		do
			Result := bson_type_datetime
		end

	milliseconds: INTEGER_64
			-- Milliseconds since Unix epoch.

	seconds: INTEGER_64
			-- Seconds since Unix epoch.
		do
			Result := milliseconds // 1000
		end

feature -- Conversion

	to_date_time: DATE_TIME
			-- Convert to DATE_TIME.
		local
			l_seconds: INTEGER_64
		do
			l_seconds := seconds
			create Result.make_from_epoch (l_seconds.to_integer_32)
		ensure
			result_not_void: Result /= Void
		end

feature -- Visitor pattern

	accept (a_visitor: BSON_VISITOR)
			-- Accept `a_visitor'.
		do
			a_visitor.visit_bson_datetime (Current)
		end

feature -- Report

	hash_code: INTEGER
			-- Hash code value.
		do
			Result := milliseconds.hash_code
		end

feature -- Status report

	debug_output: STRING
			-- String that should be displayed in debugger.
		do
			Result := "DateTime(" + milliseconds.out + "ms)"
		end

note
	copyright: "2026, Jocelyn Fiat and Eiffel Software"
	license: "MIT License"
end
