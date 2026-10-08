note
	description: "[
			Box to search libraries (local, iron, available packages, precompiled) or libraries by class name.
			The results can be filtered by category, and the matching can be strict
			(otherwise the searched text is considered as "*text*").

			It is made of 3 parts: `options_widget' (search, mode, sources, categories),
			`results_widget' (the results grid) and `tools_bar_widget' (refresh, packages, status),
			`widget' is the composition of the 3 parts.
		]"
	date: "$Date$"
	revision: "$Revision$"

class
	LIBRARY_SEARCH_BOX

inherit
	CONF_GUI_INTERFACE_CONSTANTS

	EIFFEL_LAYOUT
		export
			{NONE} all
		end

create
	make

convert
	widget: {EV_WIDGET}

feature {NONE} -- Initialization

	make (a_target: CONF_TARGET; a_iron_service: ES_GUI_IRON_SERVICE)
			-- Create search box for target `a_target', using iron service `a_iron_service'.
			-- See `set_parent_window'.
		do
			target := a_target
			iron_service := a_iron_service
			search_mode := search_in_mode
			create on_item_selected_actions
			create on_item_activated_actions
			create filter
			create strict_checkbox.make_with_text (conf_interface_names.dialog_search_library_strict)
			create show_incompatible_checkbox.make_with_text (conf_interface_names.dialog_search_library_show_incompatible)
			create category_checkboxes.make (6)
			create known_categories.make (10)
			create displayed_categories.make (5)
			across
				categories.predefined_categories as ic
			loop
				known_categories [ic] := True
				displayed_categories.extend (ic.to_string_32)
			end
			create category_checkboxes_box
			create category_menu_button
			create provider_checkboxes.make (4)
			create custom_buttons_box
			create tools_buttons_box
			create status_label
			create status_cell
			create status_change_actions
			create sources_box
			create sources_menu_button
			create search_results_box.make (a_target)
			create options_box
			create options_viewport
			create results_box
			create tools_bar
			build_options (options_box)
			build_results (results_box)
			build_tools_bar (tools_bar)

				-- The options are in a viewport, so that they do not constrain the width of the parent window:
				-- the sources and the categories selections become drop down menus when there is not enough space.
			options_viewport.extend (options_box)
			options_viewport.set_minimum_height (options_box.minimum_height)
			options_viewport.resize_actions.extend (agent (ia_x, ia_y, ia_w, ia_h: INTEGER) do update_options_layout end)
		end

	build_options (b: EV_VERTICAL_BOX)
			-- Build the search options into `b':
			-- | Search [..........................................] (x) [ ] Strict |
			-- | Find (*) Libraries ( ) Classes   Sources [x] Local [x] IRON ...  |
			-- | Category [x] Official [x] Contrib ...       [ ] Show incompatible |
		local
			hb: EV_HORIZONTAL_BOX
			lab: EV_LABEL
			l_clear_filter_button: EV_BUTTON
			l_btn: EV_BUTTON
			cb: EV_CHECK_BUTTON
			l_radio: EV_RADIO_BUTTON
		do
			b.set_padding (layout_constants.small_padding_size)

				-- Search
			create hb
			hb.set_padding (layout_constants.small_padding_size)
			b.extend (hb)
			b.disable_item_expand (hb)
			create lab.make_with_text (conf_interface_names.dialog_search_library_search)
			hb.extend (lab)
			hb.disable_item_expand (lab)
			hb.extend (filter)
			filter.set_tooltip (conf_interface_names.dialog_search_library_search_libraries_tooltip)
			filter.change_actions.extend (agent request_update_filter)
			filter.return_actions.extend (agent populate_now)
			filter.key_press_actions.extend (agent on_filter_key_pressed)

			create l_clear_filter_button
			l_clear_filter_button.select_actions.extend (agent filter.remove_text)
			l_clear_filter_button.set_pixmap (conf_pixmaps.general_remove_icon)
			l_clear_filter_button.set_tooltip (names.b_reset)
			hb.extend (l_clear_filter_button)
			hb.disable_item_expand (l_clear_filter_button)

			strict_checkbox.set_tooltip (conf_interface_names.dialog_search_library_strict_tooltip)
			strict_checkbox.select_actions.extend (agent on_strict_changed)
			hb.extend (strict_checkbox)
			hb.disable_item_expand (strict_checkbox)
			update_strict_setting

				-- Find (mode) + Sources
			create hb
			hb.set_padding (layout_constants.small_padding_size)
			b.extend (hb)
			b.disable_item_expand (hb)
			if not search_by_class_manager.providers.is_empty then
				create lab.make_with_text (conf_interface_names.dialog_search_library_find)
				hb.extend (lab)
				hb.disable_item_expand (lab)

				create l_radio.make_with_text (conf_interface_names.dialog_search_library_find_libraries)
				l_radio.set_tooltip (conf_interface_names.dialog_search_library_in_tooltip)
				hb.extend (l_radio)
				hb.disable_item_expand (l_radio)
				l_radio.enable_select
				l_radio.select_actions.extend (agent set_search_mode (search_in_mode))
				libraries_radio := l_radio

				create l_radio.make_with_text (conf_interface_names.dialog_search_library_find_classes)
				l_radio.set_tooltip (conf_interface_names.dialog_search_library_by_class_tooltip)
				hb.extend (l_radio)
				hb.disable_item_expand (l_radio)
				l_radio.select_actions.extend (agent set_search_mode (search_by_class_mode))
				classes_radio := l_radio

				create lab
				lab.set_minimum_width (layout_constants.default_padding_size)
				hb.extend (lab)
				hb.disable_item_expand (lab)
			end
			hb.extend (sources_box)
			hb.disable_item_expand (sources_box)

				-- Compact version: a button with a drop down menu (used when there is not enough space).
			sources_menu_button.set_tooltip (conf_interface_names.dialog_search_library_sources_tooltip)
			sources_menu_button.select_actions.extend (agent show_sources_menu)
			sources_menu_button.hide
			hb.extend (sources_menu_button)
			hb.disable_item_expand (sources_menu_button)
			hb.extend (create {EV_CELL})
			sources_row := hb

			sources_box.set_padding (layout_constants.small_padding_size)
			create lab.make_with_text (conf_interface_names.dialog_search_library_sources)
			sources_box.extend (lab)
			sources_box.disable_item_expand (lab)
			across
				search_in_manager.providers as ic
			loop
				create cb.make_with_text (provider_title (@ ic.key))
				cb.enable_select
				if attached ic.description as d then
					cb.set_tooltip (d)
				end
				sources_box.extend (cb)
				sources_box.disable_item_expand (cb)
				provider_checkboxes.put (cb, @ ic.key)
				cb.select_actions.extend (agent request_update_filter)
				cb.select_actions.extend (agent update_sources_menu_button)
			end
			update_sources_menu_button

				-- Categories
			create hb
			hb.set_padding (layout_constants.small_padding_size)
			b.extend (hb)
			b.disable_item_expand (hb)
			create lab.make_with_text (conf_interface_names.dialog_search_library_category)
			lab.set_tooltip (conf_interface_names.dialog_search_library_category_tooltip)
			hb.extend (lab)
			hb.disable_item_expand (lab)
			category_checkboxes_box.set_padding (layout_constants.small_padding_size)
			build_category_checkboxes
			hb.extend (category_checkboxes_box)
			hb.disable_item_expand (category_checkboxes_box)

				-- Compact version: a button with a drop down menu (used when there is not enough space).
			category_menu_button.set_tooltip (conf_interface_names.dialog_search_library_category_tooltip)
			category_menu_button.select_actions.extend (agent show_category_menu)
			update_category_menu_button
			category_menu_button.hide
			hb.extend (category_menu_button)
			hb.disable_item_expand (category_menu_button)

				-- Selection of the displayed categories.
			create l_btn
			l_btn.set_pixmap (conf_pixmaps.tool_preferences_icon)
			l_btn.set_tooltip (conf_interface_names.dialog_search_library_category_settings_tooltip)
			l_btn.select_actions.extend (agent show_category_settings_dialog)
			hb.extend (l_btn)
			hb.disable_item_expand (l_btn)

			hb.extend (create {EV_CELL})
			category_row := hb

			show_incompatible_checkbox.set_tooltip (conf_interface_names.dialog_search_library_show_incompatible_tooltip)
			show_incompatible_checkbox.select_actions.extend (agent update_results_grid)
			hb.extend (show_incompatible_checkbox)
			hb.disable_item_expand (show_incompatible_checkbox)
		end

feature {NONE} -- Options layout (compact mode)

	update_options_layout
			-- Use the compact sources and categories selections (drop down menus)
			-- if the width of `options_viewport' is too small for the checkboxes.
		local
			w: INTEGER
		do
			w := options_viewport.width
			if w > 0 then
				if attached sources_row as l_row and not is_search_by_class_mode then
					if not is_sources_compact then
						full_sources_width := sources_box.minimum_width
					end
					is_sources_compact := w < l_row.minimum_width - visible_width (sources_box, sources_menu_button) + full_sources_width
					update_sources_visibility
				end
				if attached category_row as l_row then
					if not is_categories_compact then
						full_categories_width := category_checkboxes_box.minimum_width
					end
					set_categories_compact (w < l_row.minimum_width - visible_width (category_checkboxes_box, category_menu_button) + full_categories_width)
				end
				if options_viewport.minimum_height /= options_box.minimum_height then
					options_viewport.set_minimum_height (options_box.minimum_height)
				end
				options_viewport.set_item_size (w.max (options_box.minimum_width), options_box.minimum_height)
			end
		end

	visible_width (a_full, a_compact: EV_WIDGET): INTEGER
			-- Width taken by `a_full' if displayed, otherwise by `a_compact'.
		do
			if a_full.is_show_requested then
				Result := a_full.minimum_width
			else
				Result := a_compact.minimum_width
			end
		end

	is_sources_compact: BOOLEAN
			-- Is the sources selection displayed as a drop down menu?

	is_categories_compact: BOOLEAN
			-- Is the categories selection displayed as a drop down menu?

	full_sources_width: INTEGER
			-- Width required by the sources checkboxes.

	full_categories_width: INTEGER
			-- Width required by the category checkboxes.

	set_categories_compact (b: BOOLEAN)
			-- Display the categories selection as a drop down menu if `b', otherwise as checkboxes.
		do
			if b /= is_categories_compact then
				is_categories_compact := b
				if b then
					category_checkboxes_box.hide
					category_menu_button.show
				else
					category_menu_button.hide
					category_checkboxes_box.show
				end
			end
		end

	update_sources_visibility
			-- Show the sources selection according to the search mode and `is_sources_compact'.
		do
			if is_search_by_class_mode then
				sources_box.hide
				sources_menu_button.hide
			elseif is_sources_compact then
				sources_box.hide
				sources_menu_button.show
			else
				sources_menu_button.hide
				sources_box.show
			end
		end

	source_checkboxes: ARRAYED_LIST [EV_CHECK_BUTTON]
			-- Sources checkboxes (providers, and precompiled if enabled).
		do
			create Result.make (provider_checkboxes.count + 1)
			across
				provider_checkboxes as ic
			loop
				Result.extend (ic)
			end
			if attached precompile_checkbox as cb then
				Result.extend (cb)
			end
		end

	update_sources_menu_button
			-- Update text of `sources_menu_button'.
		local
			nb: INTEGER
			l_checkboxes: like source_checkboxes
		do
			l_checkboxes := source_checkboxes
			across
				l_checkboxes as ic
			loop
				if ic.is_selected then
					nb := nb + 1
				end
			end
			sources_menu_button.set_text (conf_interface_names.dialog_search_library_sources_button (nb, l_checkboxes.count))
		end

	show_sources_menu
			-- Show the sources selection as a drop down menu.
		do
			show_check_menu (source_checkboxes, sources_menu_button)
		end

	show_check_menu (a_checkboxes: ITERABLE [EV_CHECK_BUTTON]; a_button: EV_BUTTON)
			-- Show `a_checkboxes' as a drop down menu below `a_button'.
		local
			m: EV_MENU
			mi: EV_CHECK_MENU_ITEM
		do
			create m
			across
				a_checkboxes as ic
			loop
				create mi.make_with_text (ic.text)
				if ic.is_selected then
					mi.enable_select
				end
				mi.select_actions.extend (agent (ia_cb: EV_CHECK_BUTTON)
						do
							if ia_cb.is_selected then
								ia_cb.disable_select
							else
								ia_cb.enable_select
							end
						end (ic))
				m.extend (mi)
			end
			m.show_at (a_button, 0, a_button.height)
		end

feature {NONE} -- Categories (compact mode)

	update_category_menu_button
			-- Update text of `category_menu_button'.
		local
			nb: INTEGER
		do
			across
				category_checkboxes as ic
			loop
				if ic.is_selected then
					nb := nb + 1
				end
			end
			category_menu_button.set_text (conf_interface_names.dialog_search_library_categories_button (nb, category_checkboxes.count))
		end

	show_category_menu
			-- Show the category selection as a drop down menu.
		do
			show_check_menu (category_checkboxes, category_menu_button)
		end

	build_category_checkboxes
			-- (Re)build the category checkboxes: one per `displayed_categories', and "Other",
			-- keeping the selection state of the existing checkboxes.
		local
			l_states: STRING_TABLE [BOOLEAN]
		do
			create l_states.make (category_checkboxes.count)
			across
				category_checkboxes as ic
			loop
				l_states [@ ic.key] := ic.is_selected
			end
			category_checkboxes_box.wipe_out
			category_checkboxes.wipe_out
			across
				displayed_categories as ic
			loop
				extend_category_checkbox (category_checkboxes_box, ic, search_results_box.category_title (ic), not l_states.has (ic) or else l_states [ic])
			end
			extend_category_checkbox (category_checkboxes_box, other_category, conf_interface_names.dialog_search_library_category_other,
					not l_states.has (other_category) or else l_states [other_category])
		end

	extend_category_checkbox (hb: EV_HORIZONTAL_BOX; a_category: READABLE_STRING_32; a_title: READABLE_STRING_GENERAL; a_selected: BOOLEAN)
			-- Add to `hb' a checkbox for category `a_category' with text `a_title', selected if `a_selected'.
		local
			cb: EV_CHECK_BUTTON
		do
			create cb.make_with_text (a_title)
			if a_selected then
				cb.enable_select
			end
			if a_category = other_category then
				cb.set_tooltip (conf_interface_names.dialog_search_library_category_other_tooltip)
			else
				cb.set_tooltip (conf_interface_names.dialog_search_library_category_tooltip)
			end
			cb.select_actions.extend (agent update_results_grid)
			cb.select_actions.extend (agent update_category_menu_button)
			hb.extend (cb)
			hb.disable_item_expand (cb)
			category_checkboxes.put (cb, a_category)
		end

feature {NONE} -- Categories (selection)

	displayed_categories: ARRAYED_LIST [STRING_32]
			-- Categories displayed as checkboxes (lower case), the others are covered by "Other".

	known_categories: STRING_TABLE [BOOLEAN]
			-- Known categories (lower case): predefined ones, and the ones discovered from the libraries and packages.

	register_categories (a_items: ITERABLE [ES_LIBRARY_PROVIDER_ITEM])
			-- Register the categories of `a_items' as known categories.
		do
			across
				a_items as ic
			loop
				if attached ic.category as c and then not c.is_whitespace then
					known_categories [normalized_category (c)] := True
				end
			end
		end

	normalized_category (c: READABLE_STRING_GENERAL): STRING_32
			-- Category key for `c'.
		do
			create Result.make_from_string_general (c)
			Result.adjust
			Result.to_lower
		end

	sorted_known_categories: ARRAYED_LIST [STRING_32]
			-- Known and displayed categories: the predefined ones first, then the others sorted alphabetically.
		local
			l_others: SORTED_TWO_WAY_LIST [STRING_32]
		do
			create Result.make (known_categories.count)
			across
				categories.predefined_categories as ic
			loop
				Result.extend (ic.to_string_32)
			end
			create l_others.make
			l_others.compare_objects
			across
				known_categories as ic
			loop
				if not across Result as r some r.same_string_general (@ ic.key) end then
					l_others.extend (@ ic.key.to_string_32)
				end
			end
			across
				displayed_categories as ic
			loop
				if not across Result as r some r.same_string (ic) end and not l_others.has (ic) then
					l_others.extend (ic)
				end
			end
			Result.append (l_others)
		end

	set_displayed_categories (a_categories: ITERABLE [READABLE_STRING_GENERAL])
			-- Display the checkboxes of `a_categories' (in the order of `sorted_known_categories').
		local
			l_keys: ARRAYED_LIST [STRING_32]
		do
			create l_keys.make (5)
			l_keys.compare_objects
			across
				a_categories as ic
			loop
				if not ic.is_whitespace then
					l_keys.extend (normalized_category (ic))
					known_categories [l_keys.last] := True
				end
			end
			displayed_categories.wipe_out
			across
				sorted_known_categories as ic
			loop
				if l_keys.has (ic) then
					displayed_categories.extend (ic)
				end
			end
			build_category_checkboxes
			update_category_menu_button
				-- The full width of the checkboxes changed: recompute the layout.
			set_categories_compact (False)
			update_options_layout
		end

	show_category_settings_dialog
			-- Show a dialog to select the categories displayed as checkboxes.
		local
			dlg: EV_DIALOG
			vb: EV_VERTICAL_BOX
			hb: EV_HORIZONTAL_BOX
			lab: EV_LABEL
			lst: EV_CHECKABLE_LIST
			li: EV_LIST_ITEM
			b_ok, b_cancel, b_reset: EV_BUTTON
		do
			create dlg.make_with_title (conf_interface_names.dialog_search_library_category_settings_title)
			dlg.set_icon_pixmap (conf_pixmaps.tool_preferences_icon)
			create vb
			vb.set_padding (layout_constants.default_padding_size)
			vb.set_border_width (layout_constants.default_border_size)

			create lab.make_with_text (conf_interface_names.dialog_search_library_category_settings_description)
			lab.align_text_left
			vb.extend (lab)
			vb.disable_item_expand (lab)

			create lst
			lst.set_minimum_size (300, 200)
			across
				sorted_known_categories as ic
			loop
				create li.make_with_text (search_results_box.category_title (ic))
				li.set_data (ic)
				if search_results_box.category_title (ic).as_lower /~ ic then
					li.set_tooltip (ic)
				end
				lst.extend (li)
				if across displayed_categories as d some d.same_string (ic) end then
					lst.check_item (li)
				end
			end
			vb.extend (lst)

			create hb
			hb.set_padding (layout_constants.default_padding_size)
			create b_reset.make_with_text (conf_interface_names.dialog_search_library_category_settings_reset)
			b_reset.set_tooltip (conf_interface_names.dialog_search_library_category_settings_reset_tooltip)
			b_reset.select_actions.extend (agent (ia_lst: EV_CHECKABLE_LIST)
					do
						across
							ia_lst as ic
						loop
							if attached {READABLE_STRING_32} ic.data as c and then across categories.predefined_categories as p some p.same_string (c) end then
								ia_lst.check_item (ic)
							else
								ia_lst.uncheck_item (ic)
							end
						end
					end (lst))
			layout_constants.set_default_width_for_button (b_reset)
			hb.extend (b_reset)
			hb.disable_item_expand (b_reset)
			hb.extend (create {EV_CELL})
			create b_ok.make_with_text (names.b_ok)
			b_ok.select_actions.extend (agent (ia_dlg: EV_DIALOG; ia_lst: EV_CHECKABLE_LIST)
					local
						l_selection: ARRAYED_LIST [READABLE_STRING_32]
					do
						create l_selection.make (ia_lst.count)
						across
							ia_lst.checked_items as ic
						loop
							if attached {READABLE_STRING_32} ic.data as c then
								l_selection.extend (c)
							end
						end
						ia_dlg.destroy
						set_displayed_categories (l_selection)
						update_results_grid
					end (dlg, lst))
			layout_constants.set_default_width_for_button (b_ok)
			hb.extend (b_ok)
			hb.disable_item_expand (b_ok)
			create b_cancel.make_with_text_and_action (names.b_cancel, agent dlg.destroy)
			layout_constants.set_default_width_for_button (b_cancel)
			hb.extend (b_cancel)
			hb.disable_item_expand (b_cancel)
			vb.extend (hb)
			vb.disable_item_expand (hb)

			dlg.extend (vb)
			dlg.set_default_push_button (b_ok)
			dlg.set_default_cancel_button (b_cancel)
			if attached parent_window as w then
				dlg.show_modal_to_window (w)
			else
				dlg.show
			end
		end

feature {NONE} -- Results

	build_results (b: EV_VERTICAL_BOX)
			-- Build the results grid into `b'.
		do
			b.set_border_width (1)
			b.set_background_color ((create {EV_STOCK_COLORS}).color_3d_shadow)
			search_results_box.set_minimum_size (400, 100)
			search_results_box.on_item_selected_actions.extend (agent (i: ES_LIBRARY_PROVIDER_ITEM)
					do
						on_item_selected_actions.call ([i])
					end)
			search_results_box.on_item_activated_actions.extend (agent (i: ES_LIBRARY_PROVIDER_ITEM)
					do
						on_item_activated_actions.call ([i])
					end)
			b.extend (search_results_box.widget)
		end

	build_tools_bar (hb: EV_HORIZONTAL_BOX)
			-- Build the tools bar into `hb': | custom | (refresh) (config) [Packages...] status |
		local
			l_btn: EV_BUTTON
			b: EV_HORIZONTAL_BOX
		do
			hb.set_padding (layout_constants.small_padding_size)

			custom_buttons_box.set_padding (layout_constants.small_padding_size)
			hb.extend (custom_buttons_box)
			hb.disable_item_expand (custom_buttons_box)

			b := tools_buttons_box
			b.set_padding (layout_constants.small_padding_size)
			hb.extend (b)
			hb.disable_item_expand (b)

			create l_btn
			l_btn.set_pixmap (conf_pixmaps.general_refresh_icon)
			l_btn.select_actions.extend (agent update_index)
			l_btn.set_tooltip (conf_interface_names.dialog_create_refresh_tooltip)
			b.extend (l_btn)
			b.disable_item_expand (l_btn)

			create l_btn
			l_btn.set_pixmap (conf_pixmaps.project_settings_advanced_icon)
			l_btn.select_actions.extend (agent popup_configuration_information)
			l_btn.set_tooltip (conf_interface_names.dialog_display_configuration_tooltip)
			b.extend (l_btn)
			b.disable_item_expand (l_btn)

			create l_btn.make_with_text_and_action (conf_interface_names.dialog_search_library_iron_package_manage_button_label, agent launch_iron_tool)
			l_btn.set_pixmap (conf_pixmaps.library_iron_package_icon)
			l_btn.set_tooltip (conf_interface_names.dialog_search_library_iron_package_manage_button_tooltip)
			b.extend (l_btn)
			b.disable_item_expand (l_btn)

			status_label.align_text_left
			status_cell.extend (status_label)
			hb.extend (status_cell)
		end

feature -- Access

	widget: EV_WIDGET
			-- Widget representing Current box (options, results and tools bar).
			-- Note: do not use with `options_widget', `results_widget' and `tools_bar_widget'.
		local
			b: EV_VERTICAL_BOX
		do
			if attached composite_box as l_box then
				Result := l_box
			else
				create b
				b.set_padding (layout_constants.small_padding_size)
				b.set_border_width (layout_constants.small_border_size)
				b.extend (options_viewport)
				b.disable_item_expand (options_viewport)
				b.extend (results_box)
				b.extend (tools_bar)
				b.disable_item_expand (tools_bar)
				composite_box := b
				Result := b
			end
		end

	options_widget: EV_WIDGET
			-- Search options: search text, mode, sources, categories.
		do
			Result := options_viewport
		end

	results_widget: EV_WIDGET
			-- Results grid.
		do
			Result := results_box
		end

	tools_bar_widget: EV_WIDGET
			-- Tools bar: custom buttons, refresh, configuration, packages, status.
		do
			Result := tools_bar
		end

	target: CONF_TARGET
			-- Target where we add the library.

	custom_buttons_box: EV_HORIZONTAL_BOX
			-- Box, on the left of the tools bar, available for additional buttons.

	tools_buttons_widget: EV_WIDGET
			-- Tools buttons (refresh, configuration, packages), part of `tools_bar_widget'.
			-- See `new_tools_menu' for a compact version.
		do
			Result := tools_buttons_box
		end

	status_widget: EV_LABEL
			-- Status line (number of results, messages), by default part of `tools_bar_widget'.
			-- It can be moved elsewhere, see `restore_status_widget'.
		do
			Result := status_label
		end

	status_text: STRING_32
			-- Text of the status line.
		do
			Result := status_label.text
		end

	new_tools_menu: EV_MENU
			-- New menu with the tools actions (compact version of `tools_buttons_widget').
		local
			mi: EV_MENU_ITEM
		do
			create Result
			create mi.make_with_text_and_action (conf_interface_names.dialog_search_library_reload, agent update_index)
			mi.set_pixmap (conf_pixmaps.general_refresh_icon)
			Result.extend (mi)
			create mi.make_with_text_and_action (conf_interface_names.dialog_search_library_display_configuration, agent popup_configuration_information)
			mi.set_pixmap (conf_pixmaps.project_settings_advanced_icon)
			Result.extend (mi)
			create mi.make_with_text_and_action (conf_interface_names.dialog_search_library_manage_iron_packages, agent launch_iron_tool)
			mi.set_pixmap (conf_pixmaps.library_iron_package_icon)
			Result.extend (mi)
		end

	filter_text: STRING_32
			-- Filter text.
		do
			Result := filter.text
		end

	parent_window: detachable EV_WINDOW
			-- Window containing Current box.

	items_box: EIFFEL_SEARCH_ITEMS_BOX
			-- Results box (also providing queries on items).
		do
			Result := search_results_box
		end

	selected_item: detachable ES_LIBRARY_PROVIDER_ITEM
			-- Selected item, if any.
		do
			Result := search_results_box.selected_item
		end

feature -- Element change

	set_parent_window (w: like parent_window)
			-- Set `parent_window' to `w'.
		do
			parent_window := w
		end

	set_status_message (a_message: READABLE_STRING_GENERAL)
			-- Display `a_message' in the status area.
		do
			status_label.set_text (a_message)
			status_change_actions.call (Void)
		end

	restore_status_widget
			-- Put back `status_widget' into `tools_bar_widget'.
		do
			if status_label.parent /= status_cell then
				if attached status_label.parent as p then
					p.prune (status_label)
				end
				status_cell.extend (status_label)
			end
		ensure
			in_tools_bar: status_widget.parent = status_cell
		end

feature -- Settings

	enable_precompile_option
			-- Add a "Precompiled" source checkbox (unchecked by default) to also search precompiled libraries.
			-- Associated items have the {ES_LIBRARY_CATEGORIES}.precompiled category.
		local
			cb: EV_CHECK_BUTTON
		do
			if precompile_checkbox = Void then
				create cb.make_with_text (conf_interface_names.dialog_search_library_precompiled)
				cb.set_tooltip (conf_interface_names.dialog_search_library_precompiled_tooltip)
				cb.select_actions.extend (agent request_update_filter)
				cb.select_actions.extend (agent update_sources_menu_button)
				sources_box.extend (cb)
				sources_box.disable_item_expand (cb)
				precompile_checkbox := cb
				update_sources_menu_button
				update_options_layout
			end
		end

	settings: STRING_TABLE [READABLE_STRING_32]
			-- Current settings (mode, strict, sources, categories, ...), see `apply_settings'.
		do
			create Result.make (12)
			if is_search_by_class_mode then
				Result ["mode"] := {STRING_32} "classes"
			else
				Result ["mode"] := {STRING_32} "libraries"
			end
			Result ["strict"] := boolean_setting (strict_checkbox.is_selected)
			Result ["show_incompatible"] := boolean_setting (show_incompatible_checkbox.is_selected)
			if attached precompile_checkbox as cb then
				Result ["source.precompiled"] := boolean_setting (cb.is_selected)
			end
			across
				provider_checkboxes as ic
			loop
				Result [{STRING_32} "source." + @ ic.key.to_string_32] := boolean_setting (ic.is_selected)
			end
			across
				category_checkboxes as ic
			loop
				Result [{STRING_32} "category." + @ ic.key.to_string_32] := boolean_setting (ic.is_selected)
			end
			Result ["categories.displayed"] := joined_categories (displayed_categories)
			Result ["categories.known"] := joined_categories (sorted_known_categories)
		end

	joined_categories (a_categories: ITERABLE [READABLE_STRING_32]): STRING_32
			-- `a_categories' separated by a comma.
		do
			create Result.make_empty
			across
				a_categories as ic
			loop
				if not Result.is_empty then
					Result.append_character (',')
				end
				Result.append (ic)
			end
		end

	apply_settings (a_settings: STRING_TABLE [READABLE_STRING_GENERAL])
			-- Apply `a_settings' (see `settings').
		do
			apply_check_setting (strict_checkbox, a_settings ["strict"])
			apply_check_setting (show_incompatible_checkbox, a_settings ["show_incompatible"])
			if attached a_settings ["categories.known"] as l_known then
				across
					l_known.split (',') as ic
				loop
					if not ic.is_whitespace then
						known_categories [normalized_category (ic)] := True
					end
				end
			end
			if attached a_settings ["categories.displayed"] as l_displayed then
				set_displayed_categories (l_displayed.split (','))
			end
			if attached precompile_checkbox as cb then
				apply_check_setting (cb, a_settings ["source.precompiled"])
			end
			across
				provider_checkboxes as ic
			loop
				apply_check_setting (ic, a_settings [{STRING_32} "source." + @ ic.key.to_string_32])
			end
			across
				category_checkboxes as ic
			loop
				apply_check_setting (ic, a_settings [{STRING_32} "category." + @ ic.key.to_string_32])
			end
			if
				attached a_settings ["mode"] as m and then m.same_string ("classes") and then
				attached classes_radio as l_radio
			then
				l_radio.enable_select
			end
			update_strict_setting
		end

feature -- Status report

	is_precompile_search_selected: BOOLEAN
			-- Search also precompiled libraries?
		do
			Result := is_search_in_mode and then
				attached precompile_checkbox as cb and then cb.is_selected
		end

	has_filter_focus: BOOLEAN
			-- Has filter text field the focus?
		do
			Result := filter.has_focus
		end

	is_strict: BOOLEAN
			-- Is matching strict?
		do
			Result := strict_checkbox.is_selected
		end

	is_category_shown (a_category: detachable READABLE_STRING_GENERAL): BOOLEAN
			-- Are items of category `a_category' shown?
		do
			if a_category /= Void and then attached category_checkboxes.item (a_category.as_lower) as cb then
				Result := cb.is_selected
			elseif attached category_checkboxes.item (other_category) as cb then
				Result := cb.is_selected
			else
				Result := True
			end
		end

feature -- Actions

	on_item_selected_actions: ACTION_SEQUENCE [TUPLE [search_item: detachable ES_LIBRARY_PROVIDER_ITEM]]
			-- Actions triggered when a search item is selected.

	on_item_activated_actions: ACTION_SEQUENCE [TUPLE [search_item: ES_LIBRARY_PROVIDER_ITEM]]
			-- Actions triggered when a search item is activated (double click, or Enter key).

	status_change_actions: ACTION_SEQUENCE
			-- Actions triggered when the status text changed.

feature -- Basic operation

	set_focus
			-- Set focus to the results grid.
		do
			search_results_box.set_focus
		end

	set_search_focus
			-- Set focus to the search text field.
		do
			filter.set_focus
		end

	select_row_by_value (v: ANY)
			-- Select row associated with value `v', if any.
		do
			search_results_box.select_row_by_value (v)
		end

	refresh_rows
			-- Refresh the rows of the results grid (for instance after a library is added to the target).
		do
			search_results_box.refresh_rows
		end

	populate
			-- Search items, and update the UI.
		local
			l_style: detachable EV_POINTER_STYLE
			l_win: like parent_window
			retried: BOOLEAN
			popup: detachable EV_POPUP_WINDOW
			bb, vb: EV_VERTICAL_BOX
			lab: EV_LABEL
		do
			repopulate_requested := False
			l_win := parent_window
			if not retried and l_win /= Void and attached lib_manager as l_lib_manager then
				l_style := l_win.pointer_style
				l_win.set_pointer_style ((create {EV_STOCK_PIXMAPS}).busy_cursor)
				create popup.make_with_shadow
				create bb
				bb.set_border_width (1)
				create vb
				bb.extend (vb)
				vb.set_border_width (3 * layout_constants.default_border_size)
				vb.extend (create {EV_LABEL}.make_with_text (conf_interface_names.dialog_create_searching_please_wait_message))

				create lab.make_with_text ("...")
				vb.extend (lab)

				popup.extend (bb)
				popup.set_background_color ((create {EV_STOCK_COLORS}).white)
				popup.propagate_background_color
				bb.set_background_color ((create {EV_STOCK_COLORS}).blue)
				popup.set_position (l_win.x_position + (l_win.width - popup.width) // 2, l_win.y_position + (l_win.height - popup.height) // 2)
				popup.show_relative_to_window (l_win)
				popup.refresh_now

				l_lib_manager.on_provider_execution_begin_actions.extend (agent (ia_prov: ES_LIBRARY_PROVIDER; ia_lab: EV_LABEL)
							do
								ia_lab.set_text ("Process " + ia_prov.identifier + " ...")
								ia_lab.refresh_now
							end (?, lab)
					)
				l_lib_manager.on_provider_execution_end_actions.extend (agent (ia_prov: ES_LIBRARY_PROVIDER; ia_lab: EV_LABEL)
							do
								ia_lab.set_text ("...")
								ia_lab.refresh_now
							end (?, lab)
					)

				last_results := all_search_results (filter_text, provider_ids)
				if attached last_results as l_results then
					register_categories (l_results)
				end
				update_results_grid

				l_lib_manager.on_provider_execution_begin_actions.wipe_out
				l_lib_manager.on_provider_execution_end_actions.wipe_out
			end
			if popup /= Void then
				popup.destroy
			end

			if l_style /= Void and l_win /= Void then
				l_win.set_pointer_style (l_style)
			end
		rescue
			retried := True
			retry
		end

	update_results_grid
			-- Update the results grid with `last_results', filtered by the selected categories,
			-- and by void-safety compatibility (unless incompatible items are shown).
		local
			lst: ARRAYED_LIST [ES_LIBRARY_PROVIDER_ITEM]
			nb_hidden: INTEGER
		do
			if attached last_results as l_results then
				create lst.make (l_results.count)
				across
					l_results as ic
				loop
					if is_category_shown (ic.category) then
						if show_incompatible_checkbox.is_selected or else search_results_box.is_compatible (ic) then
							lst.extend (ic)
						else
							nb_hidden := nb_hidden + 1
						end
					end
				end
			else
				create lst.make (0)
			end
			search_results_box.set_items (lst)
			search_results_box.update_grid
			if search_results_box.selected_item = Void then
					-- Previous selection is not part of the results anymore.
				on_item_selected_actions.call ([Void])
			end
			set_status_message (conf_interface_names.dialog_search_library_results_status (lst.count, nb_hidden))
		end

	notify_iron_packages_changed (a_package: detachable IRON_PACKAGE)
			-- Iron packages changed (installed, removed, ...).
		do
			reset_iron_configuration_libraries (target)
			if not repopulate_requested then
				populate
			end
		end

feature {NONE} -- Search mode

	search_mode: INTEGER

	is_search_in_mode: BOOLEAN
		do
			Result := search_mode = search_in_mode
		end

	is_search_by_class_mode: BOOLEAN
		do
			Result := search_mode = search_by_class_mode
		end

	search_in_mode: INTEGER = 1
	search_by_class_mode: INTEGER = 2

	set_search_mode (m: INTEGER)
			-- Set `search_mode' to `m', and update the UI.
		do
			if search_mode /= m then
				search_mode := m
				if is_search_by_class_mode then
					filter.set_tooltip (conf_interface_names.dialog_search_library_search_classes_tooltip)
				else
					filter.set_tooltip (conf_interface_names.dialog_search_library_search_libraries_tooltip)
				end
				update_sources_visibility
				update_options_layout
				request_update_filter
			end
		end

feature {NONE} -- Update filter

	on_strict_changed
			-- Strict checkbox changed.
		do
			update_strict_setting
			if not filter_text.is_whitespace then
				request_update_filter
			end
		end

	update_strict_setting
			-- Apply `is_strict' to the providers.
		do
			search_in_manager.set_is_strict (is_strict)
			search_by_class_manager.set_is_strict (is_strict)
			precompile_manager.set_is_strict (is_strict)
		end

	on_filter_key_pressed (a_key: EV_KEY)
			-- Key `a_key' pressed in the search text field.
		do
			if a_key.code = {EV_KEY_CONSTANTS}.key_down then
				set_focus
			end
		end

	populate_now
			-- Search immediately.
		do
			cancel_delayed_update_filter
			populate
		end

	update_filter_timeout: detachable EV_TIMEOUT

	request_update_filter
		local
			l_update_filter_timeout: like update_filter_timeout
		do
			cancel_delayed_update_filter
			l_update_filter_timeout := update_filter_timeout
			if l_update_filter_timeout = Void then
				create l_update_filter_timeout
				update_filter_timeout := l_update_filter_timeout
				l_update_filter_timeout.actions.extend_kamikaze (agent delayed_update_filter)
			end
			l_update_filter_timeout.set_interval (400)
		end

	cancel_delayed_update_filter
		do
			if attached update_filter_timeout as l_update_filter_timeout then
				l_update_filter_timeout.destroy
				update_filter_timeout := Void
			end
		end

	delayed_update_filter
		do
			cancel_delayed_update_filter
			if not options_box.is_destroyed then
				populate
			end
		end

	repopulate_requested: BOOLEAN
			-- Any pending request to call `populate'?

feature {NONE} -- Libraries cache.

	update_index
		local
			nb: INTEGER
		do
			if attached lib_manager as m then
				if is_search_in_mode then
					across
						provider_checkboxes as ic
					loop
						if ic.is_selected then
							m.reset_provider (@ ic.key, target)
							nb := nb + 1
						end
					end
				end
				if nb = 0 then
					m.reset_all (target)
				end
			end
			if is_precompile_search_selected then
				precompile_manager.reset_all (target)
			end
			populate
		end

feature {NONE} -- Iron

	iron_service: ES_GUI_IRON_SERVICE

	launch_iron_tool
		local
			dlg: detachable IRON_PACKAGE_TOOL_DIALOG
		do
			dlg := last_launch_iron_tool
			if dlg /= Void and then dlg.is_destroyed then
				dlg := Void
			end
			if dlg = Void then
				create dlg.make (iron_service)
				if attached parent_window as l_win then
					dlg.set_size (l_win.width, l_win.height)
					dlg.set_position (l_win.x_position, l_win.y_position)
				end
					--| Whenever an operation is made on iron packages via the current EiffelStudio's dialog
					--| `notify_iron_packages_changed' will be executed.
				dlg.iron_box.on_iron_packages_changed_actions.extend (agent notify_iron_packages_changed)
				last_launch_iron_tool := dlg
			end
			if attached parent_window as l_win then
				dlg.show_modal_to_window (l_win)
			else
				dlg.show
			end
		end

	last_launch_iron_tool: detachable IRON_PACKAGE_TOOL_DIALOG

feature {NONE} -- Configuration settings for libraries

	popup_configuration_information
			-- Popup information related to library dialog configuration.
		local
			dlg: EV_DIALOG
			p1, p2: PATH
			us1, us2: detachable READABLE_STRING_GENERAL
			vb: EV_VERTICAL_BOX
			hb: EV_HORIZONTAL_BOX
			t: EV_TEXT
			l_close_button: EV_BUTTON
		do
			p1 := eiffel_layout.libraries_config_name
			if eiffel_layout.is_user_files_supported and then attached eiffel_layout.user_priority_file_name (p1, False) as p then
				us1 := p.name
			end
			p2 := eiffel_layout.precompiles_config_name
			if eiffel_layout.is_user_files_supported and then attached eiffel_layout.user_priority_file_name (p2, False) as p then
				us2 := p.name
			end

			create dlg
			dlg.set_title (conf_interface_names.dialog_display_configuration_title)
			create vb
			vb.set_border_width (Layout_constants.Default_border_size)
			vb.set_padding (Layout_constants.Default_padding_size)

			create t.make_with_text (conf_interface_names.dialog_display_configuration_text (p1.name, us1, p2.name, us2, eiffel_layout.is_user_files_supported))
			t.disable_edit
			t.set_background_color ((create {EV_STOCK_COLORS}).white)
			t.set_minimum_size (500, 200)
			vb.extend (t)
			create hb
			create l_close_button.make_with_text (conf_interface_names.general_close)
			l_close_button.select_actions.extend (agent dlg.destroy)
			hb.set_padding (Layout_constants.Default_padding_size)
			dlg.set_icon_pixmap ((create {EV_STOCK_PIXMAPS}).information_pixmap)

			hb.extend (create {EV_CELL})
			hb.extend (l_close_button)
			hb.disable_item_expand (l_close_button)
			hb.extend (create {EV_CELL})
			vb.extend (hb)
			vb.disable_item_expand (hb)
			dlg.extend (vb)

			if attached parent_window as l_win then
				dlg.show_modal_to_window (l_win)
			else
				dlg.show
			end
		end

feature {NONE} -- Access

	lib_manager: detachable ES_LIBRARY_PROVIDER_SERVICE
		do
			if is_search_by_class_mode then
				Result := search_by_class_manager
			elseif is_search_in_mode then
				Result := search_in_manager
			end
		end

	search_in_manager: ES_LIBRARY_PROVIDER_SERVICE
		once
			create Result.make (3)
			Result.register (create {ES_LIBRARY_LOCAL_PROVIDER})
			Result.register (create {ES_LIBRARY_IRON_PROVIDER})
			Result.register (create {ES_LIBRARY_IRON_PACKAGE_PROVIDER}.make (create {ES_IRON_SERVICE}))
		end

	search_by_class_manager: ES_LIBRARY_PROVIDER_SERVICE
		once
			create Result.make (1)
			Result.register (create {ES_LIBRARY_INDEX_PROVIDER})
		end

	precompile_manager: ES_LIBRARY_PROVIDER_SERVICE
			-- Providers of precompiled libraries.
		once
			create Result.make (2)
			Result.register (create {ES_PRECOMPILE_LIBRARY_LOCAL_PROVIDER})
			Result.register (create {ES_PRECOMPILE_LIBRARY_IRON_PROVIDER})
		end

	reset_iron_configuration_libraries (a_target: CONF_TARGET)
		do
			search_in_manager.reset_provider ({ES_LIBRARY_IRON_PROVIDER}.identifier, a_target)
			search_in_manager.reset_provider ({ES_LIBRARY_IRON_PACKAGE_PROVIDER}.identifier, a_target)
		end

	provider_title (a_provider_id: READABLE_STRING_GENERAL): READABLE_STRING_GENERAL
			-- Text to display for provider `a_provider_id'.
		do
			if a_provider_id.same_string ({ES_LIBRARY_LOCAL_PROVIDER}.identifier) then
				Result := conf_interface_names.dialog_search_library_source_local
			elseif a_provider_id.same_string ({ES_LIBRARY_IRON_PROVIDER}.identifier) then
				Result := conf_interface_names.dialog_search_library_source_iron_installed
			elseif a_provider_id.same_string ({ES_LIBRARY_IRON_PACKAGE_PROVIDER}.identifier) then
				Result := conf_interface_names.dialog_search_library_source_iron_available
			elseif a_provider_id.same_string ({ES_LIBRARY_INDEX_PROVIDER}.identifier) then
				Result := conf_interface_names.dialog_search_library_source_class_index
			else
				Result := a_provider_id
			end
		end

	provider_ids: detachable ARRAYED_LIST [READABLE_STRING_GENERAL]
			-- Identifiers of selected providers in "libraries" mode,
			-- Void in "classes" mode (i.e all class providers).
		do
			if is_search_in_mode then
				create Result.make (provider_checkboxes.count)
				across
					provider_checkboxes as ic
				loop
					if ic.is_selected then
						Result.extend (@ ic.key)
					end
				end
			end
		end

	all_search_results (a_filter: detachable READABLE_STRING_32; a_provider_ids: detachable LIST [READABLE_STRING_GENERAL]): LIST [ES_LIBRARY_PROVIDER_ITEM]
			-- Search results for `a_filter' from providers `a_provider_ids' (if attached and empty: none).
		local
			libs: detachable LIST [ES_LIBRARY_PROVIDER_ITEM]
		do
			if
				(a_provider_ids = Void or else not a_provider_ids.is_empty) and then
				attached lib_manager as m
			then
				libs := m.libraries (a_filter, target, a_provider_ids)
			end
			if libs /= Void then
				create {ARRAYED_LIST [ES_LIBRARY_PROVIDER_ITEM]} Result.make (libs.count)
				across
					libs as ic
				loop
					Result.force (ic)
				end
			else
				create {ARRAYED_LIST [ES_LIBRARY_PROVIDER_ITEM]} Result.make (0)
			end
			if is_precompile_search_selected then
				Result.append (precompile_libraries (precompile_manager, a_filter, Void))
			end
			search_in_manager.sort_list (Result)
		end

	precompile_libraries (a_manager: ES_LIBRARY_PROVIDER_SERVICE; a_filter: detachable READABLE_STRING_32; a_provider_ids: detachable LIST [READABLE_STRING_GENERAL]): LIST [ES_LIBRARY_PROVIDER_ITEM]
			-- Precompiled libraries provided by `a_manager' (i.e "precomp_*" systems),
			-- associated items have the {ES_LIBRARY_CATEGORIES}.precompiled category.
		local
			l_precompilation: detachable STRING_32
		do
				-- We store the ISE_PRECOMP environment variable because when editing an ECF, it can
				-- be either .NET or classic so we need to compute the right path.
			l_precompilation := eiffel_layout.get_environment_32 ({EIFFEL_CONSTANTS}.ise_precomp_env)
			eiffel_layout.set_precompile (target.setting_msil_generation, target.setting_msil_clr_version)

				-- Lookup all the ECFs that matches.
			create {ARRAYED_LIST [ES_LIBRARY_PROVIDER_ITEM]} Result.make (0)
			across
				a_manager.libraries (a_filter, target, a_provider_ids) as ic
			loop
				if attached {CONF_SYSTEM_VIEW} ic.value as cfg and then categories.is_precompile_system_name (cfg.system_name) then
					ic.set_category (categories.precompiled)
					Result.force (ic)
				end
			end

				-- Restore ISE_PRECOMP to its previous value.
			if l_precompilation /= Void then
				eiffel_layout.set_environment (l_precompilation, {EIFFEL_CONSTANTS}.ise_precomp_env)
			else
				eiffel_layout.set_environment ("", {EIFFEL_CONSTANTS}.ise_precomp_env)
			end
		end

	last_results: detachable LIST [ES_LIBRARY_PROVIDER_ITEM]
			-- Results of last search, not filtered by category.

	other_category: STRING_32 = "-"
			-- Key used for items without any (known) category.

	categories: ES_LIBRARY_CATEGORIES
			-- Library categories helper.
		once
			create Result
		end

	boolean_setting (b: BOOLEAN): STRING_32
		do
			if b then
				Result := {STRING_32} "true"
			else
				Result := {STRING_32} "false"
			end
		end

	apply_check_setting (cb: EV_CHECK_BUTTON; v: detachable READABLE_STRING_GENERAL)
			-- Apply boolean setting `v' (if any) to `cb'.
		do
			if v /= Void then
				if v.is_case_insensitive_equal ("true") then
					cb.enable_select
				elseif v.is_case_insensitive_equal ("false") then
					cb.disable_select
				end
			end
		end

feature {NONE} -- Widgets

	options_box: EV_VERTICAL_BOX
			-- Search options.

	options_viewport: EV_VIEWPORT
			-- Viewport containing `options_box' (see `update_options_layout').

	results_box: EV_VERTICAL_BOX
			-- Results (with border).

	tools_bar: EV_HORIZONTAL_BOX
			-- Tools bar.

	composite_box: detachable EV_VERTICAL_BOX
			-- Box with all parts, see `widget'.

	filter: EV_TEXT_FIELD
			-- Search text.

	strict_checkbox: EV_CHECK_BUTTON
			-- Strict matching checkbox.

	show_incompatible_checkbox: EV_CHECK_BUTTON
			-- Show incompatible (void-safety) libraries checkbox.

	libraries_radio, classes_radio: detachable EV_RADIO_BUTTON
			-- Search mode radio buttons (if search by class is available).

	sources_box: EV_HORIZONTAL_BOX
			-- Box containing the sources checkboxes.

	sources_menu_button: EV_BUTTON
			-- Compact sources selection (drop down menu).

	sources_row: detachable EV_HORIZONTAL_BOX
			-- Row containing the sources selection.

	precompile_checkbox: detachable EV_CHECK_BUTTON
			-- Optional checkbox to search also precompiled libraries (see `enable_precompile_option').

	provider_checkboxes: STRING_TABLE [EV_CHECK_BUTTON]
			-- Sources checkboxes, indexed by provider identifier.

	category_checkboxes: STRING_TABLE [EV_CHECK_BUTTON]
			-- Checkboxes, indexed by category (see `other_category').

	category_checkboxes_box: EV_HORIZONTAL_BOX
			-- Box containing the category checkboxes.

	category_menu_button: EV_BUTTON
			-- Compact category selection (drop down menu).

	category_row: detachable EV_HORIZONTAL_BOX
			-- Row containing the category selection.

	tools_buttons_box: EV_HORIZONTAL_BOX
			-- Tools buttons (refresh, configuration, packages).

	status_label: EV_LABEL
			-- Status (number of results, messages).

	status_cell: EV_CELL
			-- Place of `status_label' in the tools bar.

	search_results_box: EIFFEL_SEARCH_ITEMS_BOX
			-- Search results box.

invariant
	target_set_in_boxes: search_results_box.target = target

note
	copyright: "Copyright (c) 1984-2026, Eiffel Software"
	license: "GPL version 2 (see http://www.eiffel.com/licensing/gpl.txt)"
	licensing_options: "http://www.eiffel.com/licensing"
	copying: "[
			This file is part of Eiffel Software's Eiffel Development Environment.

			Eiffel Software's Eiffel Development Environment is free
			software; you can redistribute it and/or modify it under
			the terms of the GNU General Public License as published
			by the Free Software Foundation, version 2 of the License
			(available at the URL listed under "license" above).

			Eiffel Software's Eiffel Development Environment is
			distributed in the hope that it will be useful, but
			WITHOUT ANY WARRANTY; without even the implied warranty
			of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
			See the GNU General Public License for more details.

			You should have received a copy of the GNU General Public
			License along with Eiffel Software's Eiffel Development
			Environment; if not, write to the Free Software Foundation,
			Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
		]"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"
end
