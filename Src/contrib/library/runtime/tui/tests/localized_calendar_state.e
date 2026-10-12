note
	description: "[
		CALENDAR_STATE with a localized (Japanese) month name, whose characters are 2 columns
		wide, for the centring test of review finding U10.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	LOCALIZED_CALENDAR_STATE

inherit
	CALENDAR_STATE
		redefine
			month_name
		end

create
	make

feature -- Access

	month_name: STRING_32
			-- U+4E00 U+6708 (January), whatever the month
		do
			create Result.make (2)
			Result.append_code (0x4E00)
			Result.append_code (0x6708)
		end

end
