note
	description: "[
		Mixin for widgets that hide, from mouse hit-testing, everything rendered before them
		(a modal popup). When `blocks_hits` holds, FRAME.render_widget and
		FRAME.render_stateful_widget register a modal right after rendering the widget
		(see {HIT_MAP}.register_modal): a blocker over the whole frame area, so regions
		registered earlier in the frame (the background) hit nothing, inside or outside the
		widget's own area; and a clip to the widget's area for regions registered later, so
		the dialog's own controls stay reachable while a background control rendered after
		the dialog by mistake does not.
		`blocks_hits` is a query, not a setting: a descendant derives it from its own state,
		such as TUI_POPUP from whether its modal focus scope is open, so mouse blocking and
		keyboard trapping cannot disagree.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	HIT_BLOCKER

feature -- Status report

	blocks_hits: BOOLEAN
			-- Does rendering Current through a FRAME block hits on what was registered before it?
		deferred
		end

end
