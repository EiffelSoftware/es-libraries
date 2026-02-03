note
	description: "Markdown list item."

class
	MD_LIST_ITEM

inherit
	MD_BOX [MD_BLOCK]
		redefine
			process
		end

create
	make

feature -- Initialization

	make
			-- Create an empty list item.
		do
			initialize
			is_task := False
			task_checked := False
		ensure
			is_empty: count = 0
			not_task: not is_task
		end

feature -- Access

	is_task: BOOLEAN
			-- Is this a task list item?

	task_checked: BOOLEAN
			-- Is the task checked? (only meaningful if `is_task` is True)

feature -- Element change

	set_task (a_checked: BOOLEAN)
			-- Mark this as a task list item, checked if `a_checked` is True.
		do
			is_task := True
			task_checked := a_checked
		ensure
			is_task: is_task
			task_checked_set: task_checked = a_checked
		end

feature -- Visitor

	process (a_visitor: MD_VISITOR)
			-- Process `Current` using `a_visitor`.
		do
			a_visitor.visit_list_item (Current)
		end

end

