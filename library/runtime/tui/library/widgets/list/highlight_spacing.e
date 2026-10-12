note
	description: "Spacing behavior for list highlight symbol."
	author: "EiffelTUI Team"

class
	HIGHLIGHT_SPACING

feature -- Constants

	When_selected: INTEGER = 1
			-- Reserve space for highlight symbol only when an item is selected (default)

	Always: INTEGER = 2
			-- Always reserve space for highlight symbol even when no item is selected

	Never: INTEGER = 3
			-- Never reserve space for highlight symbol

feature -- Status report

	is_valid (a_spacing: INTEGER): BOOLEAN
			-- Is `a_spacing` a valid highlight spacing?
		do
			Result := a_spacing = When_selected or a_spacing = Always or a_spacing = Never
		ensure
			instance_free: class
		end

end
