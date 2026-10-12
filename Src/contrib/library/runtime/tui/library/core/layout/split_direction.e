note
	description: "[
		Orientation direction along which a layout splits its parent area.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	SPLIT_DIRECTION

inherit
	ANY
		redefine
			default_create,
			is_equal,
			out
		end

create
	default_create,
	make_horizontal,
	make_vertical

feature {NONE} -- Initialization

	default_create
			-- Initialize as vertical split by default.
		do
			is_horizontal := False
		ensure then
			default_is_vertical: is_vertical
		end

	make_horizontal
			-- Initialize as horizontal split (children laid out left to right).
		do
			is_horizontal := True
		ensure
			horizontal_set: is_horizontal
		end

	make_vertical
			-- Initialize as vertical split (children laid out top to bottom).
		do
			is_horizontal := False
		ensure
			vertical_set: is_vertical
		end

feature -- Status report

	is_horizontal: BOOLEAN
			-- Is split direction horizontal (columns)?

	is_vertical: BOOLEAN
			-- Is split direction vertical (rows)?
		do
			Result := not is_horizontal
		end

feature -- Named Constants (Class features)

	Horizontal: SPLIT_DIRECTION
			-- Standard horizontal split direction
		once
			create Result.make_horizontal
		ensure
			instance_free: class
			is_horizontal: Result.is_horizontal
		end

	Vertical: SPLIT_DIRECTION
			-- Standard vertical split direction
		once
			create Result.make_vertical
		ensure
			instance_free: class
			is_vertical: Result.is_vertical
		end

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Is `Current` equal to `a_other`?
		do
			Result := is_horizontal = a_other.is_horizontal
		end

feature -- Output

	out: STRING_8
			-- String representation
		do
			if is_horizontal then
				Result := "Horizontal"
			else
				Result := "Vertical"
			end
		end

end
