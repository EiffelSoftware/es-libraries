note
	description: "[
		Data item model for EXAMPLE_TODO_LIST, representing a task with status,
		title, and extended information.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TODO_ITEM

create
	make

feature {NONE} -- Initialization

	make (a_done: BOOLEAN; a_title, a_info: READABLE_STRING_GENERAL)
			-- Initialize item with `a_done` status, `a_title` and `a_info`.
		require
			title_not_void: a_title /= Void
			info_not_void: a_info /= Void
		do
			is_done := a_done
			create title.make_from_string_general (a_title)
			create info.make_from_string_general (a_info)
		ensure
			done_set: is_done = a_done
		end

feature -- Access

	is_done: BOOLEAN
			-- Has this task been completed?

	title: STRING_32
			-- Short task summary

	info: STRING_32
			-- Extended description or notes

feature -- Status Setting

	toggle
			-- Invert completion status.
		do
			is_done := not is_done
		ensure
			toggled: is_done = not old is_done
		end

	set_done (a_val: BOOLEAN)
			-- Explicitly set completion status to `a_val`.
		do
			is_done := a_val
		ensure
			done_set: is_done = a_val
		end

end
