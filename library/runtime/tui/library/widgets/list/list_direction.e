note
	description: "Direction for rendering list items."
	author: "EiffelTUI Team"

class
	LIST_DIRECTION

feature -- Constants

	Top_to_bottom: INTEGER = 1
			-- Render from top of area downwards (default)

	Bottom_to_top: INTEGER = 2
			-- Render from bottom of area upwards

feature -- Status report

	is_valid (a_dir: INTEGER): BOOLEAN
			-- Is `a_dir` a valid list direction?
		do
			Result := a_dir = Top_to_bottom or a_dir = Bottom_to_top
		ensure
			instance_free: class
		end

end
