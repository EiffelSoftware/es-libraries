note
	description: "[
		Mutable state tracking active tab index (1-based) for TUI_TABS.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TABS_STATE

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
			-- Initialize with first tab selected.
		do
			selected := 1
		ensure then
			first_selected: selected = 1
		end

	make
			-- Synonym for `default_create`.
		do
			default_create
		end

feature -- Access

	selected: INTEGER
			-- 1-based index of the currently active tab

feature -- Element change

	select_index (a_index: INTEGER)
			-- Set selected tab index.
		require
			positive_index: a_index >= 1
		do
			selected := a_index
		ensure
			selected_set: selected = a_index
		end

feature -- Navigation

	select_next (a_total_count: INTEGER)
			-- Advance to next tab, wrapping around to 1 if reaching `a_total_count`.
		require
			positive_count: a_total_count > 0
		do
			if selected >= a_total_count then
				selected := 1
			else
				selected := selected + 1
			end
		ensure
			valid_selection: selected >= 1 and selected <= a_total_count
		end

	select_previous (a_total_count: INTEGER)
			-- Move to previous tab, wrapping around to `a_total_count` if at 1.
		require
			positive_count: a_total_count > 0
		do
			if selected <= 1 then
				selected := a_total_count
			else
				selected := selected - 1
			end
		ensure
			valid_selection: selected >= 1 and selected <= a_total_count
		end

invariant
	selected_positive: selected >= 1

end
