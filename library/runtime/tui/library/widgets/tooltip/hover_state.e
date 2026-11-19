note
	description: "[
		Which control the mouse pointer rests on, and whether its tooltip is due (P2 W6).
		The application feeds it and asks it; it never reads a clock or the mouse itself:
		  * on each mouse move (and drag), `hover (hit_test (event))`: the control under the
		    pointer, or Void;
		  * on each TICK_EVENT, `tick`;
		  * on a press or a key, `dismiss`, as a desktop tooltip goes away when clicked.
		The tooltip is due (`is_shown`) once the pointer has rested on the same control for
		`delay_ticks` ticks: moving to another control starts the count again, moving within
		the same one does not, and leaving every control (Void) hides it. With the default
		tick rate of TUI_APPLICATION (50 ms) the default delay of 10 ticks is half a second.
		After `dismiss` the tooltip stays hidden until the pointer moves to another control.
		With a `tooltip_id` (the TUI_TOOLTIP's `hit_id`), moving the pointer onto the tooltip
		itself changes nothing: the hover stays on the control it describes.

		Moves arrive only with motion reporting on ({TUI_APPLICATION}.set_mouse_motion).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	HOVER_STATE

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
			-- Nothing hovered; a delay of `Default_delay_ticks`.
		do
			delay_ticks := Default_delay_ticks
		ensure then
			nothing_hovered: hovered = Void
			default_delay: delay_ticks = Default_delay_ticks
		end

	make (a_delay_ticks: INTEGER)
			-- Nothing hovered; a delay of `a_delay_ticks`.
		require
			non_negative: a_delay_ticks >= 0
		do
			delay_ticks := a_delay_ticks
		ensure
			nothing_hovered: hovered = Void
			delay_set: delay_ticks = a_delay_ticks
		end

feature -- Access

	hovered: detachable WIDGET_ID
			-- Control under the pointer at the last `hover`, or Void

	delay_ticks: INTEGER
			-- Ticks the pointer must rest on a control before its tooltip is shown

	rested_ticks: INTEGER
			-- Ticks since the pointer came to `hovered`, counted up to `delay_ticks`

	shown_id: detachable WIDGET_ID
			-- Control whose tooltip is due, or Void
		do
			if is_shown then
				Result := hovered
			end
		ensure
			definition: Result = (if is_shown then hovered else Void end)
		end

	tooltip_id: detachable WIDGET_ID
			-- Id the tooltip's box is registered under, or Void

	Default_delay_ticks: INTEGER = 10
			-- `delay_ticks` of a new state

feature -- Status report

	is_shown: BOOLEAN
			-- Is the tooltip of `hovered` due: something hovered, rested on for
			-- `delay_ticks`, and not dismissed?
		do
			Result := hovered /= Void and not is_dismissed and rested_ticks >= delay_ticks
		ensure
			definition: Result = (hovered /= Void and not is_dismissed and rested_ticks >= delay_ticks)
		end

	is_dismissed: BOOLEAN
			-- Was the tooltip dismissed since the pointer came to `hovered`?

	is_tooltip (a_id: detachable WIDGET_ID): BOOLEAN
			-- Is `a_id` the tooltip's own box (`tooltip_id`)?
		do
			Result := a_id /= Void and then a_id ~ tooltip_id
		ensure
			never_void: a_id = Void implies not Result
		end

feature -- Element change

	hover (a_id: detachable WIDGET_ID)
			-- The pointer is on the control `a_id` (Void: on none). A different control
			-- starts the count again; the same one, or the tooltip (`tooltip_id`), changes
			-- nothing.
		do
			if not is_tooltip (a_id) and not (a_id ~ hovered) then
				hovered := a_id
				rested_ticks := 0
				is_dismissed := False
			end
		ensure
			hovered_set: not is_tooltip (a_id) implies hovered ~ a_id
			on_tooltip_kept: is_tooltip (a_id) implies (hovered = old hovered and rested_ticks = old rested_ticks
				and is_dismissed = old is_dismissed)
			same_kept: (a_id ~ old hovered) implies (rested_ticks = old rested_ticks and is_dismissed = old is_dismissed)
			restarted: (not is_tooltip (a_id) and not (a_id ~ old hovered)) implies (rested_ticks = 0 and not is_dismissed)
		end

	set_tooltip_id (a_id: detachable WIDGET_ID)
			-- Treat `a_id` as the tooltip's own box (Void: none).
		do
			tooltip_id := a_id
		ensure
			tooltip_id_set: tooltip_id = a_id
		end

	tick
			-- One tick passed with the pointer where it is.
		do
			if hovered /= Void and rested_ticks < delay_ticks then
				rested_ticks := rested_ticks + 1
			end
		ensure
			counted: (old hovered /= Void and old rested_ticks < delay_ticks) implies rested_ticks = old rested_ticks + 1
			capped: rested_ticks <= delay_ticks
		end

	dismiss
			-- Hide the tooltip until the pointer moves to another control.
		do
			is_dismissed := True
		ensure
			dismissed: is_dismissed
			hidden: not is_shown
		end

	set_delay_ticks (a_ticks: INTEGER)
			-- Show a tooltip after the pointer rested `a_ticks` ticks on its control.
		require
			non_negative: a_ticks >= 0
		do
			delay_ticks := a_ticks
			rested_ticks := rested_ticks.min (a_ticks)
		ensure
			delay_set: delay_ticks = a_ticks
		end

feature -- Fluent Builders

	with_tooltip_id (a_id: detachable WIDGET_ID): like Current
			-- Copy of Current treating `a_id` as the tooltip's own box.
		do
			Result := twin
			Result.set_tooltip_id (a_id)
		ensure
			result_not_void: Result /= Void
			tooltip_id_set: Result.tooltip_id = a_id
		end

	with_delay_ticks (a_ticks: INTEGER): like Current
			-- Copy of Current with a delay of `a_ticks` ticks.
		require
			non_negative: a_ticks >= 0
		do
			Result := twin
			Result.set_delay_ticks (a_ticks)
		ensure
			result_not_void: Result /= Void
			delay_set: Result.delay_ticks = a_ticks
		end

invariant
	non_negative_delay: delay_ticks >= 0
	rested_in_range: rested_ticks >= 0 and rested_ticks <= delay_ticks
	nothing_rested_without_hover: hovered = Void implies rested_ticks = 0

end
