note
	description: "Direction for rendering sparkline data."
	author: "EiffelTUI Team"

class
	SPARKLINE_DIRECTION

feature -- Constants

	Left_to_right: INTEGER = 1
			-- The first element is rendered at the left of the sparkline area (default)

	Right_to_left: INTEGER = 2
			-- The first element is rendered at the right of the sparkline area

feature -- Status report

	is_valid (a_dir: INTEGER): BOOLEAN
			-- Is `a_dir` a valid sparkline direction?
		do
			Result := a_dir = Left_to_right or a_dir = Right_to_left
		ensure
			instance_free: class
		end

end
