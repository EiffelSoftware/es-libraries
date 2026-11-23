note
	description: "[
		State of a TUI_DIALOG (P2b U2): the buttons, which of them is focused, whether the
		dialog is open, and the answer. Ratatui has no dialog; applications draw one as a
		popup with a button row. The application keeps one DIALOG_STATE per dialog, as it does
		a MENU_STATE, and gives it the keys and the clicks while it is open.

		Buttons: 1 to 4 labels (`make`), each with a WIDGET_ID made by the state
		(`button_id`). The ids have negative values, taken from a counter shared by every
		DIALOG_STATE of the thread, so they never equal one another; give the application's
		own controls non-negative ids, or choose the buttons' ids with `set_button_ids`.
		`open` requires that no button id is already in the focus manager's active scope
		(`are_ids_free`), so a clash with an application control fails at once. Factories:
		  * `make_alert`: OK; default and cancel 1;
		  * `make_confirm`: Yes / No; default and cancel 2 ("No" is the safe answer);
		  * `make_ok_cancel`: OK / Cancel; default 1, cancel 2.
		`default_button` is focused when the dialog opens; `cancel_button` is the answer of Esc
		(0: Esc does nothing).

		Opening and answering:
		  * `open` focuses the default button and sets `answer` to 0. After
		    `set_focus_manager (focus)` it also pushes a modal focus scope holding the button
		    ids, through `begin_modal_with` on `popup`, the TUI_POPUP the state keeps: Tab
		    cannot reach the controls behind the dialog, and TUI_DIALOG, rendering that popup,
		    blocks clicks on everything rendered before it.
		  * `answer_with (i)` closes the dialog, sets `answer` to `i`, pops the scope (the
		    background's focus comes back) and then calls `answered_action` with `i`, once,
		    when the state is consistent again (the TOAST_QUEUE `expired_action` rule): the
		    action may `open` this dialog again, or open another one.
		  * `cancel` is `answer_with (cancel_button)`; it does nothing when that is 0.
		Every closing path goes through `answer_with`, so the scope is popped exactly once;
		`answer_count` counts the answers.

		Focus: while the scope is open, `focused_button` is the button the focus manager has
		focused, so moving the focus with FOCUS_MANAGER (`focus_next`, `focus_at`) and with
		`handle_key` / `focus_button` gives the same button: the one drawn focused and the one
		Enter answers with.

		Keys and mouse (the application's part; the state reads no events by itself):

		    if dialog.is_open then
		        if attached {KEY_EVENT} a_event as k then
		            l_used := dialog.handle_key (k)
		        elseif attached {MOUSE_EVENT} a_event as m and then m.is_down then
		            if dialog.handles (hit_test (m)) then dialog.click (hit_test (m)) end
		        end
		    else
		        ... the background ...
		    end

		  * `handle_key` takes Tab / Right (next button) and Shift+Tab / Left (previous),
		    wrapping round; Enter or Space (answer with the focused button); Esc (`cancel`, not
		    used when `cancel_button` is 0); and a letter without Ctrl or Alt that starts
		    exactly one label (case ignored): "y" / "n" for Yes / No. Two labels starting with
		    the same letter give that letter no shortcut. It returns False for every other key
		    and while the dialog is closed.
		  * `handles` is True while the dialog is open: a click anywhere is the dialog's (the
		    background is blocked). `click` answers with the button whose id was hit, and does
		    nothing for any other hit.

		The scope must be the innermost one of the focus manager whenever the dialog closes
		(`is_scope_innermost`), as for MENU_STATE.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	DIALOG_STATE

inherit
	WIDGET_STATE
		redefine
			default_create,
			copy,
			is_equal
		end

create
	default_create,
	make,
	make_alert,
	make_confirm,
	make_ok_cancel

feature {NONE} -- Initialization

	default_create
			-- Closed alert: one "OK" button, default and cancel.
		do
			make_alert
		ensure then
			one_button: button_count = 1
			closed: not is_open
		end

	make (a_labels: ARRAY [READABLE_STRING_GENERAL]; a_default, a_cancel: INTEGER)
			-- Closed dialog with buttons labelled `a_labels`, in order, `a_default` focused when
			-- it opens and `a_cancel` the answer of Esc (0: none).
		require
			labels_not_void: a_labels /= Void
			one_to_four: a_labels.count >= 1 and a_labels.count <= Max_buttons
			valid_labels: across a_labels as l all l /= Void and then is_valid_label (l) end
			valid_default: a_default >= 1 and a_default <= a_labels.count
			valid_cancel: a_cancel >= 0 and a_cancel <= a_labels.count
		do
			create labels.make (a_labels.count)
			create ids.make (a_labels.count)
			across a_labels as l loop
				labels.extend (create {IMMUTABLE_STRING_32}.make_from_string_general (l))
				ids.extend (new_id)
			end
			default_button := a_default
			cancel_button := a_cancel
			last_focused_button := a_default
			create popup.make
			is_open := False
			answer := 0
		ensure
			count_set: button_count = a_labels.count
			labels_set: across 1 |..| a_labels.count as i all button (i).same_string_general (a_labels [a_labels.lower + i - 1]) end
			default_set: default_button = a_default
			cancel_set: cancel_button = a_cancel
			focused_default: focused_button = a_default
			closed: not is_open
			no_answer: answer = 0
			no_focus_manager: focus_manager = Void
		end

	make_alert
			-- Closed dialog with one "OK" button, default and cancel.
		do
			make ({ARRAY [READABLE_STRING_GENERAL]} <<"OK">>, 1, 1)
		ensure
			one_button: button_count = 1
			ok: button (1).same_string_general ("OK")
			default_ok: default_button = 1
			cancel_ok: cancel_button = 1
		end

	make_confirm
			-- Closed dialog with "Yes" and "No"; "No" is the default and the answer of Esc.
		do
			make ({ARRAY [READABLE_STRING_GENERAL]} <<"Yes", "No">>, 2, 2)
		ensure
			two_buttons: button_count = 2
			yes: button (1).same_string_general ("Yes")
			no: button (2).same_string_general ("No")
			default_no: default_button = 2
			cancel_no: cancel_button = 2
		end

	make_ok_cancel
			-- Closed dialog with "OK" and "Cancel"; "OK" is the default, "Cancel" the answer of
			-- Esc.
		do
			make ({ARRAY [READABLE_STRING_GENERAL]} <<"OK", "Cancel">>, 1, 2)
		ensure
			two_buttons: button_count = 2
			ok: button (1).same_string_general ("OK")
			cancel: button (2).same_string_general ("Cancel")
			default_ok: default_button = 1
			cancel_cancel: cancel_button = 2
		end

feature -- Access

	button_count: INTEGER
			-- Number of buttons (1 to `Max_buttons`)
		do
			Result := labels.count
		ensure
			definition: Result = labels.count
		end

	button (i: INTEGER): IMMUTABLE_STRING_32
			-- Label of button `i`
		require
			valid_index: i >= 1 and i <= button_count
		do
			Result := labels.i_th (i)
		ensure
			result_not_void: Result /= Void
		end

	buttons: ARRAYED_LIST [IMMUTABLE_STRING_32]
			-- A new list of the labels, in order
		do
			create Result.make (labels.count)
			Result.append (labels)
		ensure
			same_count: Result.count = button_count
		end

	button_id (i: INTEGER): WIDGET_ID
			-- Hit and focus id of button `i`: made by the state (a negative value), or given by
			-- `set_button_ids`
		require
			valid_index: i >= 1 and i <= button_count
		do
			Result := ids.i_th (i)
		ensure
			result_not_void: Result /= Void
		end

	button_ids: ARRAY [WIDGET_ID]
			-- A new array of the button ids, in button order
		local
			i: INTEGER
		do
			create Result.make_filled (ids.first, 1, ids.count)
			from i := 1 until i > ids.count loop
				Result [i] := ids.i_th (i)
				i := i + 1
			end
		ensure
			same_count: Result.count = button_count
		end

	index_of_id (a_id: detachable WIDGET_ID): INTEGER
			-- Index of the button whose id is `a_id`, 0 if none
		local
			i: INTEGER
		do
			if attached a_id as l_id then
				from i := 1 until Result > 0 or i > ids.count loop
					if ids.i_th (i) ~ l_id then
						Result := i
					end
					i := i + 1
				end
			end
		ensure
			in_range: Result >= 0 and Result <= button_count
			found: Result > 0 implies button_id (Result) ~ a_id
		end

	button_with_initial (a_char: CHARACTER_32): INTEGER
			-- Index of the only button whose label starts with `a_char` (case ignored, leading
			-- blanks skipped); 0 when no label or more than one starts with it
		local
			i, l_found: INTEGER
			l_text: STRING_32
		do
			from i := 1 until i > labels.count loop
				l_text := labels.i_th (i).to_string_32
				l_text.left_adjust
				if not l_text.is_empty and then l_text [1].as_lower = a_char.as_lower then
					l_found := l_found + 1
					Result := i
				end
				i := i + 1
			end
			if l_found /= 1 then
				Result := 0
			end
		ensure
			in_range: Result >= 0 and Result <= button_count
		end

	default_button: INTEGER
			-- Button focused when the dialog opens

	cancel_button: INTEGER
			-- Answer of Esc (`cancel`); 0: Esc does nothing

	focused_button: INTEGER
			-- Button Enter and Space answer with. While the dialog's focus scope is open, the
			-- focus manager decides: when its focused id is one of the buttons (moved by
			-- `focus_button` or by the application's own FOCUS_MANAGER calls), that button.
		local
			i: INTEGER
		do
			Result := last_focused_button
			if has_scope and then attached popup.modal_focus as f then
				i := index_of_id (f.focused_id)
				if i > 0 then
					Result := i
				end
			end
		ensure
			in_range: Result >= 1 and Result <= button_count
			follows_focus_manager: (has_scope and then attached popup.modal_focus as f
				and then index_of_id (f.focused_id) > 0) implies Result = index_of_id (f.focused_id)
		end

	answer_count: INTEGER
			-- Number of times the dialog was answered (`answer_with`) since it was made

	answer: INTEGER
			-- Button the dialog was last answered with; 0 until then and while open

	focus_manager: detachable FOCUS_MANAGER
			-- Focus manager in which `open` pushes the dialog's scope, or Void

	popup: TUI_POPUP
			-- Popup whose modal scope `open` begins and `answer_with` ends; TUI_DIALOG
			-- registers it, so it blocks the background while that scope is open

	answered_action: detachable PROCEDURE [INTEGER]
			-- Called with the answer each time the dialog is answered, if set

	Max_buttons: INTEGER = 4
			-- Most buttons a dialog has

feature -- Status report

	is_open: BOOLEAN
			-- Is the dialog shown and waiting for an answer?

	is_answered: BOOLEAN
			-- Was the dialog answered since it last opened?
		do
			Result := answer > 0
		ensure
			definition: Result = (answer > 0)
		end

	has_scope: BOOLEAN
			-- Is the modal focus scope opened by `open` still open?
		do
			Result := popup.is_modal_open
		ensure
			definition: Result = popup.is_modal_open
		end

	is_scope_innermost: BOOLEAN
			-- Can the dialog close now: no scope open, or the dialog's scope is still the
			-- innermost scope of its focus manager?
		do
			Result := not has_scope or else (attached popup.modal_focus as f and then f.scope_depth = popup.modal_depth)
		end

	handles (a_hit: detachable WIDGET_ID): BOOLEAN
			-- Is a click that hit `a_hit` the dialog's? Any click while the dialog is open.
		do
			Result := is_open
		ensure
			definition: Result = is_open
		end

	are_valid_ids (a_ids: ARRAY [WIDGET_ID]): BOOLEAN
			-- Can `a_ids` be the button ids: one per button, none Void, no two equal?
		require
			ids_not_void: a_ids /= Void
		local
			i, j: INTEGER
		do
			Result := a_ids.count = button_count
			from i := a_ids.lower until not Result or i > a_ids.upper loop
				Result := a_ids [i] /= Void
				from j := i + 1 until not Result or j > a_ids.upper loop
					Result := not (a_ids [i] ~ a_ids [j])
					j := j + 1
				end
				i := i + 1
			end
		end

	are_ids_free (a_focus: FOCUS_MANAGER): BOOLEAN
			-- Is no button id already registered in the active scope of `a_focus` (where an
			-- application control with the same value would be confused with a button)?
		require
			focus_not_void: a_focus /= Void
		do
			Result := across ids as l_id all not a_focus.contains (l_id) end
		end

	is_valid_label (a_label: READABLE_STRING_GENERAL): BOOLEAN
			-- Can `a_label` be a button label: not empty, and no C0 or C1 control character or
			-- DEL ({TUI_BUTTON}.is_valid_bracket)?
		require
			label_not_void: a_label /= Void
		do
			Result := not a_label.is_empty and then {TUI_BUTTON}.is_valid_bracket (a_label)
		ensure
			instance_free: class
		end

feature -- Element change

	set_focus_manager (a_focus: detachable FOCUS_MANAGER)
			-- Push the dialog's scope on `a_focus` while it is open (Void: no scope).
		require
			closed: not is_open
		do
			focus_manager := a_focus
		ensure
			focus_manager_set: focus_manager = a_focus
		end

	set_answered_action (a_action: like answered_action)
			-- Call `a_action` with the answer each time the dialog is answered (Void: nothing).
		do
			answered_action := a_action
		ensure
			answered_action_set: answered_action = a_action
		end

	set_default_button (i: INTEGER)
			-- Focus button `i` when the dialog opens.
		require
			valid_index: i >= 1 and i <= button_count
		do
			default_button := i
		ensure
			default_set: default_button = i
		end

	set_cancel_button (i: INTEGER)
			-- Make button `i` the answer of Esc (0: Esc does nothing).
		require
			valid_index: i >= 0 and i <= button_count
		do
			cancel_button := i
		ensure
			cancel_set: cancel_button = i
		end

	set_button_ids (a_ids: ARRAY [WIDGET_ID])
			-- Use `a_ids`, in button order, as the hit and focus ids of the buttons instead of
			-- the ones the state made (for an application that numbers all its controls).
		require
			closed: not is_open
			ids_not_void: a_ids /= Void
			valid_ids: are_valid_ids (a_ids)
		do
			create ids.make (a_ids.count)
			across a_ids as l_id loop
				ids.extend (l_id)
			end
		ensure
			ids_set: across 1 |..| button_count as i all button_id (i) ~ a_ids [a_ids.lower + i - 1] end
		end

feature -- Fluent Builders

	with_button_ids (a_ids: ARRAY [WIDGET_ID]): like Current
			-- Copy of Current using `a_ids` as the button ids, for setting up.
		require
			closed: not is_open
			ids_not_void: a_ids /= Void
			valid_ids: are_valid_ids (a_ids)
		do
			Result := twin
			Result.set_button_ids (a_ids)
		ensure
			result_not_void: Result /= Void
			ids_set: across 1 |..| button_count as i all Result.button_id (i) ~ a_ids [a_ids.lower + i - 1] end
		end

	with_default_button (i: INTEGER): like Current
			-- Copy of Current focusing button `i` when it opens (for setting up: a closed state
			-- only, so that no two states own one focus scope).
		require
			closed: not is_open
			valid_index: i >= 1 and i <= button_count
		do
			Result := twin
			Result.set_default_button (i)
		ensure
			result_not_void: Result /= Void
			default_set: Result.default_button = i
		end

	with_cancel_button (i: INTEGER): like Current
			-- Copy of Current answering Esc with button `i` (0: none), for setting up.
		require
			closed: not is_open
			valid_index: i >= 0 and i <= button_count
		do
			Result := twin
			Result.set_cancel_button (i)
		ensure
			result_not_void: Result /= Void
			cancel_set: Result.cancel_button = i
		end

feature -- Opening and closing

	open
			-- Show the dialog with `default_button` focused and no answer; with a focus manager,
			-- push the dialog's modal scope holding the button ids (see the class note).
		require
			closed: not is_open
			ids_free: attached focus_manager as l_focus implies are_ids_free (l_focus)
		do
			answer := 0
			last_focused_button := default_button
			if attached focus_manager as f then
				popup.begin_modal_with (f, button_ids)
				f.set_focus (button_id (default_button))
			end
			is_open := True
		ensure
			open: is_open
			no_answer: answer = 0
			default_focused: focused_button = default_button
			scoped: focus_manager /= Void implies has_scope
			focus_on_default: attached focus_manager as f implies f.is_focused (button_id (default_button))
		end

	answer_with (i: INTEGER)
			-- Close the dialog with the answer `i`: pop its scope, then call `answered_action`
			-- with `i` (which may open a dialog again).
		require
			open: is_open
			valid_index: i >= 1 and i <= button_count
			scope_innermost: is_scope_innermost
		do
			close_with (i)
			answer_count := answer_count + 1
			if attached answered_action as l_action then
				l_action.call ([i])
			end
		ensure
			counted: answer_count > old answer_count
			answered: answered_action = Void implies (answer = i and not is_open)
			scope_popped: answered_action = Void implies not has_scope
		end

	cancel
			-- Answer with `cancel_button` (Esc); nothing when it is 0.
		require
			open: is_open
			scope_innermost: is_scope_innermost
		do
			if cancel_button > 0 then
				answer_with (cancel_button)
			end
		ensure
			counted: old cancel_button > 0 implies answer_count > old answer_count
			cancelled: (old cancel_button > 0 and answered_action = Void) implies (answer = cancel_button and not is_open)
			kept_open: old cancel_button = 0 implies (is_open and answer_count = old answer_count)
		end

feature -- Navigation

	focus_button (i: INTEGER)
			-- Focus button `i` (in the focus manager too, while the dialog's scope is innermost).
		require
			valid_index: i >= 1 and i <= button_count
		do
			last_focused_button := i
			if has_scope and then attached popup.modal_focus as f and then f.contains (button_id (i)) then
				f.set_focus (button_id (i))
			end
		ensure
			focused: focused_button = i
		end

	focus_next
			-- Focus the next button, wrapping round from the last to the first.
		do
			focus_button (focused_button \\ button_count + 1)
		ensure
			next: focused_button = old focused_button \\ button_count + 1
		end

	focus_previous
			-- Focus the previous button, wrapping round from the first to the last.
		do
			if focused_button = 1 then
				focus_button (button_count)
			else
				focus_button (focused_button - 1)
			end
		ensure
			previous: focused_button = (if old focused_button = 1 then button_count else old focused_button - 1 end)
		end

feature -- Input

	handle_key (a_key: KEY_EVENT): BOOLEAN
			-- Act on `a_key` if the dialog uses it (see the class note); False for any other key
			-- and while the dialog is closed.
		require
			key_not_void: a_key /= Void
			scope_innermost: is_scope_innermost
		local
			i: INTEGER
			l_plain: BOOLEAN
		do
			if is_open and a_key.is_press then
				l_plain := not a_key.modifiers.is_control and not a_key.modifiers.is_alt
				if a_key.code.is_back_tab or (a_key.code.is_tab and a_key.modifiers.is_shift) or a_key.code.is_left then
					focus_previous
					Result := True
				elseif a_key.code.is_tab or a_key.code.is_right then
					focus_next
					Result := True
				elseif a_key.code.is_enter or (l_plain and a_key.code.is_char and then a_key.code.character = ' ') then
					Result := True
					answer_with (focused_button)
				elseif a_key.code.is_escape then
					if cancel_button > 0 then
						Result := True
						cancel
					end
				elseif l_plain and a_key.code.is_char then
					i := button_with_initial (a_key.code.character)
					if i > 0 then
						Result := True
						focus_button (i)
						answer_with (i)
					end
				end
			end
		ensure
			closed_ignores: not old is_open implies not Result
		end

	click (a_hit: detachable WIDGET_ID)
			-- Answer with the button whose id is `a_hit`; nothing for any other hit, or while
			-- closed.
		require
			scope_innermost: is_scope_innermost
		local
			i: INTEGER
		do
			if is_open then
				i := index_of_id (a_hit)
				if i > 0 then
					focus_button (i)
					answer_with (i)
				end
			end
		ensure
			counted: (old is_open and old index_of_id (a_hit) > 0) implies answer_count > old answer_count
			answered: (old is_open and old index_of_id (a_hit) > 0 and answered_action = Void)
				implies (answer = old index_of_id (a_hit) and not is_open)
			missed: (old index_of_id (a_hit) = 0) implies (is_open = old is_open and answer_count = old answer_count)
		end

feature -- Duplication

	copy (a_other: like Current)
			-- Copy `a_other`, with lists and a popup of its own. The focus scope stays with
			-- `a_other`: when `a_other` has one open, the copy has no focus manager (it would pop
			-- a scope it does not own). The button ids are the same values.
		do
			if a_other /= Current then
				standard_copy (a_other)
				labels := a_other.labels.twin
				ids := a_other.ids.twin
				create popup.make
				if a_other.has_scope then
					focus_manager := Void
				end
			end
		ensure then
			no_scope: not has_scope
		end

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Same labels, ids, default, cancel and focused buttons, open state and answer? The
			-- focus manager, its scope and the action are not part of the value.
		local
			i: INTEGER
		do
			if a_other = Current then
				Result := True
			else
				Result := button_count = a_other.button_count
					and default_button = a_other.default_button
					and cancel_button = a_other.cancel_button
					and focused_button = a_other.focused_button
					and is_open = a_other.is_open
					and answer = a_other.answer
				from i := 1 until not Result or i > button_count loop
					Result := button (i).same_string (a_other.button (i)) and button_id (i) ~ a_other.button_id (i)
					i := i + 1
				end
			end
		end

feature {DIALOG_STATE} -- Implementation

	labels: ARRAYED_LIST [IMMUTABLE_STRING_32]
			-- Button labels, in order

	ids: ARRAYED_LIST [WIDGET_ID]
			-- Button ids, parallel to `labels`

feature {NONE} -- Implementation

	last_focused_button: INTEGER
			-- Button last focused through the state (`open`, `focus_button`); `focused_button`
			-- while no focus scope decides

	close_with (i: INTEGER)
			-- Close the dialog with the answer `i` and pop its scope, without calling
			-- `answered_action`: the state `answer_with` hands to the action.
		require
			open: is_open
			valid_index: i >= 1 and i <= button_count
			scope_innermost: is_scope_innermost
		do
				-- Keep the focus manager's choice once its scope is gone
			last_focused_button := focused_button
			is_open := False
			answer := i
			if has_scope and then attached popup.modal_focus as f then
				popup.end_modal (f)
			else
					-- No scope, or one popped behind the state's back: start afresh
				create popup.make
			end
		ensure
			closed: not is_open
			answered: answer = i
			scope_popped: not has_scope
		end

	new_id: WIDGET_ID
			-- A fresh id, below every id made before in this thread
		do
			Id_counter.put (Id_counter.item - 1)
			create Result.make (Id_counter.item)
		ensure
			negative: Result.value < 0
		end

	Id_counter: CELL [INTEGER]
			-- Value of the last id made by any DIALOG_STATE of this thread
		once
			create Result.put (0)
		end

invariant
	labels_not_void: labels /= Void
	ids_not_void: ids /= Void
	popup_not_void: popup /= Void
	one_to_four: button_count >= 1 and button_count <= Max_buttons
	one_id_per_button: ids.count = labels.count
	valid_labels: across labels as l all is_valid_label (l) end
	valid_default: default_button >= 1 and default_button <= button_count
	valid_cancel: cancel_button >= 0 and cancel_button <= button_count
	valid_last_focused: last_focused_button >= 1 and last_focused_button <= button_count
	valid_focused: focused_button >= 1 and focused_button <= button_count
	valid_answer: answer >= 0 and answer <= button_count
	no_answer_while_open: is_open implies answer = 0
	scope_only_while_open: has_scope implies is_open
	scope_in_focus_manager: has_scope implies popup.modal_focus = focus_manager

end
