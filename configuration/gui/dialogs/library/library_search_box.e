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
			create category_checkboxes_box
			create category_menu_button
			create provider_checkboxes.make (4)
			create custom_buttons_box
			create status_label
			create sources_box
			create search_results_box.make (a_target)
			create options_box
			create results_box
			create tools_bar
			build_options (options_box)
			build_results (results_box)
			build_tools_bar (tools_bar)
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
			hb.extend (create {EV_CELL})

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
			end

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
			across
				categories.categories as ic
			loop
				extend_category_checkbox (category_checkboxes_box, ic, search_results_box.category_title (ic))
			end
			extend_category_checkbox (category_checkboxes_box, other_category, conf_interface_names.dialog_search_library_category_other)
			hb.extend (category_checkboxes_box)
			hb.disable_item_expand (category_checkboxes_box)

				-- Compact version: a button with a drop down menu (used when there is not enough space).
			category_menu_button.set_tooltip (conf_interface_names.dialog_search_library_category_tooltip)
			category_menu_button.select_actions.extend (agent show_category_menu)
			update_category_menu_button
			category_menu_button.hide
			hb.extend (category_menu_button)
			hb.disable_item_expand (category_menu_button)

			hb.extend (create {EV_CELL})
			category_row := hb

			show_incompatible_checkbox.set_tooltip (conf_interface_names.dialog_search_library_show_incompatible_tooltip)
			show_incompatible_checkbox.select_actions.extend (agent update_results_grid)
			hb.extend (show_incompatible_checkbox)
			hb.disable_item_expand (show_incompatible_checkbox)

			b.resize_actions.extend (agent (ia_x, ia_y, ia_w, ia_h: INTEGER) do update_category_compactness (ia_w) end)
		end

feature {NONE} -- Categories (compact mode)

	update_category_compactness (a_width: INTEGER)
			-- Use the compact category selection (drop down menu), if `a_width' is too small for the category checkboxes.
		local
			l_required: INTEGER
		do
			if category_checkboxes_box.is_show_requested then
				full_category_row_width := category_checkboxes_box.minimum_width
			end
			if full_category_row_width > 0 and attached category_row as l_row then
				l_required := full_category_row_width + show_incompatible_checkbox.minimum_width
					+ category_menu_button.minimum_width + 6 * layout_constants.small_padding_size
				if attached l_row.first as l_label then
					l_required := l_required + l_label.minimum_width
				end
				if a_width < l_required then
					if category_checkboxes_box.is_show_requested then
						category_checkboxes_box.hide
						category_menu_button.show
					end
				elseif not category_checkboxes_box.is_show_requested then
					category_menu_button.hide
					category_checkboxes_box.show
				end
			end
		end

	full_category_row_width: INTEGER
			-- Width required by the category checkboxes.

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
		local
			m: EV_MENU
			mi: EV_CHECK_MENU_ITEM
		do
			create m
			across
				category_checkboxes as ic
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
			m.show_at (category_menu_button, 0, category_menu_button.height)
		end

	extend_category_checkbox (hb: EV_HORIZONTAL_BOX; a_category: READABLE_STRING_32; a_title: READABLE_STRING_GENERAL)
			-- Add to `hb' a checkbox for category `a_category' with text `a_title'.
		local
			cb: EV_CHECK_BUTTON
		do
			create cb.make_with_text (a_title)
			cb.enable_select
			cb.set_tooltip (conf_interface_names.dialog_search_library_category_tooltip)
			cb.select_actions.extend (agent update_results_grid)
			cb.select_actions.extend (agent update_category_menu_button)
			hb.extend (cb)
			hb.disable_item_expand (cb)
			category_checkboxes.put (cb, a_category)
		end

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
		do
			hb.set_padding (layout_constants.small_padding_size)

			custom_buttons_box.set_padding (layout_constants.small_padding_size)
			hb.extend (custom_buttons_box)
			hb.disable_item_expand (custom_buttons_box)

			create l_btn
			l_btn.set_pixmap (conf_pixmaps.general_refresh_icon)
			l_btn.select_actions.extend (agent update_index)
			l_btn.set_tooltip (conf_interface_names.dialog_create_refresh_tooltip)
			hb.extend (l_btn)
			hb.disable_item_expand (l_btn)

			create l_btn
			l_btn.set_pixmap (conf_pixmaps.project_settings_advanced_icon)
			l_btn.select_actions.extend (agent popup_configuration_information)
			l_btn.set_tooltip (conf_interface_names.dialog_display_configuration_tooltip)
			hb.extend (l_btn)
			hb.disable_item_expand (l_btn)

			create l_btn.make_with_text_and_action (conf_interface_names.dialog_search_library_iron_package_manage_button_label, agent launch_iron_tool)
			l_btn.set_pixmap (conf_pixmaps.library_iron_package_icon)
			l_btn.set_tooltip (conf_interface_names.dialog_search_library_iron_package_manage_button_tooltip)
			hb.extend (l_btn)
			hb.disable_item_expand (l_btn)

			status_label.align_text_left
			hb.extend (status_label)
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
				b.extend (options_box)
				b.disable_item_expand (options_box)
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
			Result := options_box
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
				sources_box.extend (cb)
				sources_box.disable_item_expand (cb)
				precompile_checkbox := cb
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
		end

	apply_settings (a_settings: STRING_TABLE [READABLE_STRING_GENERAL])
			-- Apply `a_settings' (see `settings').
		do
			apply_check_setting (strict_checkbox, a_settings ["strict"])
			apply_check_setting (show_incompatible_checkbox, a_settings ["show_incompatible"])
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
					sources_box.hide
					filter.set_tooltip (conf_interface_names.dialog_search_library_search_classes_tooltip)
				else
					sources_box.show
					filter.set_tooltip (conf_interface_names.dialog_search_library_search_libraries_tooltip)
				end
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

	status_label: EV_LABEL
			-- Status (number of results, messages).

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
