note
	description: "Dialog to show hidden tool bar items."
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date$"
	revision: "$Revision$"

class
	SD_TOOL_BAR_HIDDEN_ITEM_DIALOG

inherit
	EV_POPUP_WINDOW
		export
			{ANY} show
		end

	EV_SHARED_APPLICATION
		export
			{NONE} all
		undefine
			default_create, copy
		end

	SD_ACCESS
		undefine
			default_create,
			is_equal,
			copy
		end

create
	make,
	make_for_menu

feature {NONE}  -- Initlization

	make (a_hidden_items: ARRAYED_LIST [SD_TOOL_BAR_ITEM]; a_tool_bar: SD_TOOL_BAR_ZONE)
			-- Creation method
		require
			not_void: a_hidden_items /= Void
			not_void: a_tool_bar /= Void
		do
			parent_tool_bar := a_tool_bar
			create internal_vertical_box
			create internal_shared
			create internal_horizontal_box
			create internal_tool_bar.make (create {SD_TOOL_BAR}.make)

			make_with_shadow
			disable_user_resize
			disable_border

			internal_vertical_box.set_border_width (internal_shared.border_width)
			internal_vertical_box.set_background_color (internal_shared.border_color)

			extend (internal_vertical_box)

			init_grouping (a_hidden_items)
			init_hidden_items (a_hidden_items)
			init_customize_label
			init_close
			internal_tool_bar.compute_minimum_size

			-- If we don't call this, the height will be 2 pixels less on Windows
			set_height (item.minimum_height)
		ensure
			set: parent_tool_bar = a_tool_bar
		end

	make_for_menu (a_tool_bar: SD_TOOL_BAR_ZONE)
			-- Creation method for right-click menu
		require
			not_void: a_tool_bar /= Void
		do
			make (create {ARRAYED_LIST [SD_TOOL_BAR_ITEM]}.make (1), a_tool_bar)
		end

	init_grouping (a_hidden_items: ARRAYED_LIST [SD_TOOL_BAR_ITEM])
			-- Grouping hidden items
		local
			l_divider: SD_TOOL_BAR_HIDDEN_GROUP_DIVIDER
		do
			if a_hidden_items.count > 0 then
				create l_divider.make (a_hidden_items)
				l_divider.set_max_width_allowed ({SD_SHARED}.Tool_bar_hidden_item_dialog_max_width)
				l_divider.grouped_items
			end
		end

	init_hidden_items (a_hidden_items: ARRAYED_LIST [SD_TOOL_BAR_ITEM])
			-- Add hidden items to Current
		do
			internal_vertical_box.extend (internal_horizontal_box)

			from
				a_hidden_items.start
				internal_horizontal_box.extend (internal_tool_bar)
			until
				a_hidden_items.after
			loop
				if attached {SD_TOOL_BAR_SEPARATOR} a_hidden_items.item then
						-- Ignore
				else
					if
						attached {SD_TOOL_BAR_WIDGET_ITEM} a_hidden_items.item as l_widget_item and then
						attached l_widget_item.widget as w and then
						attached w.parent as l_parent
					then
						l_parent.prune (w)
					end
					internal_tool_bar.extend (a_hidden_items.item)
				end
				a_hidden_items.forth
			end
		end

	init_customize_label
			-- Add customize label
		local
			l_separator: SD_TOOL_BAR_SEPARATOR
			l_button: SD_TOOL_BAR_BUTTON
		do
			if internal_tool_bar.items.count > 0 then
				create l_separator.make
				l_separator.set_wrap (True)
				internal_tool_bar.extend (l_separator)
			end

			create l_button.make
			l_button.set_text (internal_shared.interface_names.customize)
			l_button.select_actions.extend (agent on_customize)
			internal_tool_bar.extend (l_button)
		end

	init_close
			-- Initialization close events
			--| Do not close on `focus_out_actions': under some window managers (e.g. XQuartz)
			--| the popup gets the focus when mapped and loses it at once to the window the
			--| user just clicked in, so Current vanished immediately.
			--| Close on a pointer press outside Current, or on Escape, instead.
		local
			agt_ptr_press: like application_pointer_press_agent
			agt_key_press: like application_key_press_agent
		do

			agt_ptr_press := agent on_application_pointer_press
			agt_key_press := agent on_application_key_press

			application_pointer_press_agent := agt_ptr_press
			application_key_press_agent := agt_key_press

			ev_application.pointer_button_press_actions.extend (agt_ptr_press)
			ev_application.key_press_actions.extend (agt_key_press)
		end

feature {SD_TOOL_BAR_MANAGER} -- Command

	on_customize
			-- Handle customize actions
		local
			l_dialog: SD_TOOL_BAR_CUSTOMIZE_DIALOG
			l_parent_window: EV_WINDOW
			l_docking_manager: detachable SD_DOCKING_MANAGER
			l_assit: SD_TOOL_BAR_ZONE_ASSISTANT
		do
				-- Focus out no longer closes Current, so close it before the modal customize dialog shows up.
			close
			if attached parent_tool_bar.customize_dialog as l_dialog_2 and then not l_dialog_2.is_destroyed then
				l_dialog_2.set_focus
			else
				create l_dialog.make
				parent_tool_bar.set_customize_dialog (l_dialog)

				prepare_size (l_dialog, parent_tool_bar.assistant.last_state)

				if attached parent_tool_bar.floating_tool_bar as b then
					l_parent_window := b
				else
					l_parent_window := parent_tool_bar.docking_manager.main_window
				end
				if attached parent_tool_bar.content as c then
					l_dialog.customize_toolbar (l_parent_window, True, True, c.items)
				end
				parent_tool_bar.set_customize_dialog (Void)
				parent_tool_bar.assistant.last_state.set_cutomize_dialog_size (l_dialog.w_width, l_dialog.w_height)
				if l_dialog.valid_data then
					l_assit := parent_tool_bar.assistant
					l_assit.save_items_layout (l_dialog.final_toolbar)

					if
						attached parent_tool_bar.content as c and then
						c.is_docking and then
						parent_tool_bar.is_vertical
					then
						l_docking_manager := parent_tool_bar.docking_manager
						l_docking_manager.command.lock_update (Void, True)

						l_assit.open_items_layout
						if not parent_tool_bar.is_floating then
							parent_tool_bar.extend_one_item (parent_tool_bar.tail_indicator)
						end

						parent_tool_bar.change_direction (False)
						l_docking_manager.command.resize (True)
						l_docking_manager.command.unlock_update
					else
						l_assit.open_items_layout
						if not parent_tool_bar.is_floating then
							parent_tool_bar.extend_one_item (parent_tool_bar.tail_indicator)
						end
					end

					parent_tool_bar.compute_minmum_size
				end
			end
		end

feature {NONE} -- Implementation

	prepare_size (a_dialog: EV_DIALOG; a_state: SD_TOOL_BAR_ZONE_STATE)
			-- Try to use last customize dialog width and height
		require
			not_void: a_dialog /= Void
			not_void: a_state /= Void
		local
			l_width, l_height: INTEGER
		do
			l_width := a_state.customize_dialog_width
			if l_width <= 0 then
				l_width := internal_shared.Tool_bar_customize_dialog_default_width
			end
			l_height := a_state.customize_dialog_height
			if l_height <= 0 then
				l_height := internal_shared.Tool_bar_customize_dialog_default_height
			end
			a_dialog.set_size (l_width, l_height)
		end

	save_items_layout (a_items: ARRAYED_LIST [SD_TOOL_BAR_ITEM])
			-- Save `a_tool_bar' items layout to it's data
		require
			not_void: a_items /= Void
		local
			l_data: ARRAYED_LIST [TUPLE [READABLE_STRING_GENERAL, BOOLEAN]]
		do
			from
				create l_data.make (a_items.count)
				a_items.start
			until
				a_items.after
			loop
				l_data.extend ([a_items.item.name, a_items.item.is_displayed])
				a_items.forth
			end
			parent_tool_bar.assistant.last_state.set_items_layout (l_data)
		ensure
			saved: parent_tool_bar.assistant.last_state.items_layout /= Void
		end

	parent_tool_bar: SD_TOOL_BAR_ZONE
			-- Tool bar which Current belong to

	internal_tool_bar: SD_WIDGET_TOOL_BAR
			-- Tool bar contain all hidden items and "Customize" label

	on_application_pointer_press (a_widget: EV_WIDGET; a_button, a_screen_x, a_screen_y: INTEGER)
			-- Close Current when the pointer is pressed outside of it.
		do
			if is_destroyed then
				remove_application_actions
			elseif
				is_displayed and then
				not (a_screen_x >= screen_x and a_screen_x < screen_x + width and
					a_screen_y >= screen_y and a_screen_y < screen_y + height)
			then
				close
			end
		end

	on_application_key_press (a_widget: EV_WIDGET; a_key: EV_KEY)
			-- Close Current on Escape.
		do
			if is_destroyed then
				remove_application_actions
			elseif a_key.code = {EV_KEY_CONSTANTS}.key_escape then
				close
			end
		end

	close
			-- Destroy Current (once idle), and stop listening to application events.
		do
			if not is_closing then
				is_closing := True
				remove_application_actions
				if not is_destroyed then
					-- FIXIT: can't destroy directly?
					ev_application.do_once_on_idle (agent destroy)
					parent_tool_bar.docking_manager.command.resize (True)
				end
			end
		end

	remove_application_actions
			-- Remove the agents registered on `ev_application' by `init_close'.
		do
			if attached application_pointer_press_agent as agt then
				ev_application.pointer_button_press_actions.prune_all (agt)
			end
			if attached application_key_press_agent as agt then
				ev_application.key_press_actions.prune_all (agt)
			end
		end

	is_closing: BOOLEAN
			-- Has `close' been called?

	application_pointer_press_agent: detachable PROCEDURE [EV_WIDGET, INTEGER, INTEGER, INTEGER]
			-- Agent for `on_application_pointer_press'.

	application_key_press_agent: detachable PROCEDURE [EV_WIDGET, EV_KEY]
			-- Agent for `on_application_key_press'.

	internal_vertical_box: EV_VERTICAL_BOX
			-- Top level vertical box

	internal_horizontal_box: EV_HORIZONTAL_BOX
			-- Box which in `internal_vertical_box'.

	internal_shared: SD_SHARED
			-- All singletons

invariant
	parent_tool_bar_not_void: parent_tool_bar /= Void

note
	library:	"SmartDocking: Library of reusable components for Eiffel."
	copyright:	"Copyright (c) 1984-2026, Eiffel Software and others"
	license:	"Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"

end
