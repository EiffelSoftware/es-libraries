note
	description: "Spacing behavior for the highlight symbol column of TUI_LIST and TUI_TABLE (Ratatui HighlightSpacing)."
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

	should_add (a_spacing: INTEGER; a_has_selection: BOOLEAN): BOOLEAN
			-- Is the highlight symbol column reserved under `a_spacing`, when something is
			-- selected (`a_has_selection`) or not? (Ratatui `HighlightSpacing::should_add`)
		require
			valid_spacing: is_valid (a_spacing)
		do
			Result := a_spacing = Always or else (a_spacing = When_selected and a_has_selection)
		ensure
			instance_free: class
			always: a_spacing = Always implies Result
			never: a_spacing = Never implies not Result
			when_selected: a_spacing = When_selected implies Result = a_has_selection
		end

end
